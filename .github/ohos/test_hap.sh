#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be
# found in the LICENSE file.

# test_hap.sh <work dir> <libmpv dir> <audio>: builds a Flutter-OH app with
# the kit that plays <audio> as an asset, signs its HAP with the OpenHarmony
# debug keys and prints the path of the signed HAP. Installed on the Oniro
# emulator (hdc install, aa start -a EntryAbility -b dev.mak.makohos), it
# writes MAK_OHOS_RESULT PASS or FAIL to hilog.
#
# <libmpv dir> holds libmpv_ohos-<arch>.so (the libmpv user define, until a
# release pins them). The work dir must have what setup.sh puts there:
#   flutter/        Flutter-OH (gitcode CPF-Flutter/flutter_flutter,
#                   oh-3.41.9-release) with a local tag 3.41.9, so its version
#                   resolves in a shallow clone
#   cmdtools/command-line-tools/   HarmonyOS command-line tools 5.1.0.840
#                   (hvigor, ohpm), from repo.huaweicloud.com/harmonyos/ohpm
#   ohsdk/26/       the OpenHarmony 7.0 SDK (ets, js, previewer, native,
#                   toolchains) with metaVersion 3.0.0 and no platformVersion
#                   in each oh-uni-package.json: hvigor 5.18 finds no
#                   component of API 26 otherwise
#   sdk-lib/        toolchains/lib of that SDK (hap-sign-tool.jar,
#                   OpenHarmony.p12, the profile template and certificate)
#
# What the template of flutter create needs for the Oniro emulator
# (OpenHarmony 7.0, not HarmonyOS): runtimeOS OpenHarmony in both
# build-profile.json5, compileSdkVersion 26 (the embedding of Flutter-OH uses
# autoFillManager.AutoFillType, missing in API 18), deviceTypes default (no
# phone on OpenHarmony), and Impeller off: on the emulator the engine's Vulkan
# start crashes (SIGSEGV in vkGetInstanceProcAddr). flutter build hap writes
# enable_impeller true into the rawfile buildinfo.json5 and has no flag for
# it, so the unsigned HAP is edited before signing.
set -euo pipefail

work="$(cd "${1:?usage: test_hap.sh <work dir> <libmpv dir> <audio>}" && pwd)"
libmpv="$(cd "${2:?}" && pwd)"
audio="$(cd "$(dirname "${3:?}")" && pwd)/$(basename "$3")"
asset="$(basename "$audio")"
kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
arch="${OHOS_TARGET_PLATFORM:-ohos-x64}"

ct="$work/cmdtools/command-line-tools"
export OHOS_BASE_SDK_HOME="$work/ohsdk"
export PATH="$work/flutter/bin:$ct/bin:$ct/ohpm/bin:$ct/hvigor/bin:$PATH"
app="$work/makohos"

rm -rf "$app"
(cd "$work" && flutter create --platforms ohos --org dev.mak --project-name makohos makohos >/dev/null) || true
mkdir -p "$app/assets" "$app/libmpv"
cp "$audio" "$app/assets/$asset"
cp "$libmpv"/libmpv_ohos-*.so "$app/libmpv/"
rm -rf "$app/test"

python3 -I - "$app" "$kit" "$asset" <<'PY'
import json, re, sys
app, kit, asset = sys.argv[1], sys.argv[2], sys.argv[3]
p = f'{app}/pubspec.yaml'
s = open(p).read()
s = s.replace('dependencies:\n', f'dependencies:\n  mpv_audio_kit:\n    path: {kit}\n', 1)
s = re.sub(r'(\nflutter:\n)', r'\1  assets:\n    - assets/' + asset + r'\n', s, count=1)
s += '\nhooks:\n  user_defines:\n    mpv_audio_kit:\n      libmpv: libmpv\n'
open(p, 'w').write(s)
p = f'{app}/ohos/build-profile.json5'
s = open(p).read()
s = re.sub(r'"compatibleSdkVersion": "[^"]*",', '"compatibleSdkVersion": 18,', s)
s = re.sub(r'"targetSdkVersion": "[^"]*",', '"compileSdkVersion": 26,', s)
s = s.replace('"runtimeOS": "HarmonyOS",', '"runtimeOS": "OpenHarmony",')
s = s.replace('"signingConfig": "default",', '')
open(p, 'w').write(s)
p = f'{app}/ohos/entry/build-profile.json5'
s = open(p).read().replace('"runtimeOS": "HarmonyOS"', '"runtimeOS": "OpenHarmony"')
open(p, 'w').write(s)
p = f'{app}/ohos/entry/src/main/module.json5'
s = re.sub(r'"deviceTypes":\s*\[[^\]]*\]', '"deviceTypes": ["default"]', open(p).read())
# What an app that plays in the background declares (doc/ohos.md): the
# permission of the continuous task and its mode on the ability.
s = s.replace('"abilities": [\n      {', '"abilities": [\n      {\n        "backgroundModes": ["audioPlayback"],', 1)
if '"requestPermissions": [' in s:
    s = s.replace('"requestPermissions": [', '"requestPermissions": [\n      {"name": "ohos.permission.KEEP_BACKGROUND_RUNNING"},', 1)
else:
    s = s.replace('"abilities": [', '"requestPermissions": [{"name": "ohos.permission.KEEP_BACKGROUND_RUNNING"}],\n    "abilities": [', 1)
open(p, 'w').write(s)
PY

sed "s/@ASSET@/$asset/" > "$app/lib/main.dart" <<'DART'
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

// Plays the asset: MAK_OHOS_RESULT says it plays through ohaudio. Then it
// turns the media session on and, for 5 s, takes note of the commands the
// system sends it: MAK_OHOS_SESSION. ohos-emulator.yml reads the session
// the system holds (hidumper) and what its System UI shows.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ColoredBox(color: Color(0xFF000000)));
  try {
    MpvAudioKit.ensureInitialized();
    print('MAK_OHOS_LIB os=${Platform.operatingSystem}');
    final player = Player();
    await player.ready;
    await player.setLoop(Loop.file);
    await player.open(Media('asset://assets/@ASSET@'));
    await player.play();
    final at = await player.stream.position
        .firstWhere((p) => p > const Duration(seconds: 2))
        .timeout(const Duration(seconds: 90));
    final driver = player.state.output.currentAo;
    final ok = driver == 'ohaudio' && player.state.playback.playing;
    print('MAK_OHOS_RESULT ${ok ? 'PASS' : 'FAIL'} ao=$driver '
        'position=$at params=${player.state.output.audioOutParams}');
    final commands = <String>[];
    final sub = player.stream.mediaSessionCommands
        .listen((c) => commands.add(c.runtimeType.toString()));
    await player.setMediaSession(
      const MediaSession(title: 'mpv_audio_kit on OHOS', artist: 'makohos'),
    );
    await Future<void>.delayed(const Duration(seconds: 5));
    print('MAK_OHOS_SESSION commands=$commands '
        'playing=${player.state.playback.playing}');
    await sub.cancel();
    await player.setMediaSession(null);
    await player.dispose();
  } catch (e, s) {
    print('MAK_OHOS_RESULT FAIL $e\n$s');
  }
}
DART

(cd "$app" && flutter pub get >/dev/null && flutter build hap --debug --target-platform "$arch") >&2 || true
unsigned="$app/ohos/entry/build/default/outputs/default/entry-default-unsigned.hap"
[[ -f "$unsigned" ]] || { echo "test_hap.sh: no unsigned HAP" >&2; exit 1; }

# Impeller off in the HAP itself.
sign="$work/sign"
rm -rf "$sign"
mkdir -p "$sign/ed/resources/rawfile"
cp "$unsigned" "$sign/app.hap"
(cd "$sign/ed" && unzip -o -q ../app.hap resources/rawfile/buildinfo.json5 &&
  sed -i 's/"true"/"false"/' resources/rawfile/buildinfo.json5 &&
  zip -q -0 ../app.hap resources/rawfile/buildinfo.json5)

# The debug profile of OpenHarmony, as oniro-app-builder's
# generateSigningConfigs.ts writes it: the release template with the bundle
# name and the leaf of the profile certificate chain.
lib="$work/sdk-lib"
python3 -I - "$lib" "$sign/profile.json" <<'PY'
import json, sys
lib, out = sys.argv[1], sys.argv[2]
t = json.load(open(f'{lib}/UnsgnedReleasedProfileTemplate.json'))
chain = open(f'{lib}/OpenHarmonyProfileRelease.pem').read().split('-----END CERTIFICATE-----')
t['bundle-info']['bundle-name'] = 'dev.mak.makohos'
t['bundle-info']['distribution-certificate'] = chain[2].strip() + '\n-----END CERTIFICATE-----\n'
t['bundle-info']['apl'] = 'normal'
t['bundle-info']['app-feature'] = 'hos_normal_app'
json.dump(t, open(out, 'w'), indent=2)
PY
alias_='openharmony application profile release'
java -jar "$lib/hap-sign-tool.jar" sign-profile -keyAlias "$alias_" -signAlg SHA256withECDSA \
  -mode localSign -profileCertFile "$lib/OpenHarmonyProfileRelease.pem" -inFile "$sign/profile.json" \
  -keystoreFile "$lib/OpenHarmony.p12" -outFile "$sign/profile.p7b" -keyPwd 123456 -keystorePwd 123456 >&2
java -jar "$lib/hap-sign-tool.jar" sign-app -keyAlias "$alias_" -signAlg SHA256withECDSA \
  -mode localSign -appCertFile "$lib/OpenHarmonyProfileRelease.pem" -profileFile "$sign/profile.p7b" \
  -inFile "$sign/app.hap" -keystoreFile "$lib/OpenHarmony.p12" -outFile "$sign/makohos-signed.hap" \
  -keyPwd 123456 -keystorePwd 123456 >&2
echo "$sign/makohos-signed.hap"
