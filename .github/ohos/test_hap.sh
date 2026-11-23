#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be
# found in the LICENSE file.

# test_hap.sh <work dir> <libmpv dir> <wav>: builds a Flutter-OH app with
# the kit that plays <wav> as an asset, signs its HAP with the OpenHarmony
# debug keys and prints the path of the signed HAP. Installed on the Oniro
# emulator (hdc install, aa start -a EntryAbility -b dev.mak.makohos), it
# writes MAK_OHOS_RESULT PASS or FAIL to hilog.
#
# <libmpv dir> holds libmpv_ohos-<arch>.so (the libmpv user define, until a
# release pins them). The work dir must have, as the spike of 22-11-2026 set
# them up:
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

work="$(cd "${1:?usage: test_hap.sh <work dir> <libmpv dir> <wav>}" && pwd)"
libmpv="$(cd "${2:?}" && pwd)"
wav="$(cd "$(dirname "${3:?}")" && pwd)/$(basename "$3")"
kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
arch="${OHOS_TARGET_PLATFORM:-ohos-x64}"

ct="$work/cmdtools/command-line-tools"
export OHOS_BASE_SDK_HOME="$work/ohsdk"
export PATH="$work/flutter/bin:$ct/bin:$ct/ohpm/bin:$ct/hvigor/bin:$PATH"
app="$work/makohos"

rm -rf "$app"
(cd "$work" && flutter create --platforms ohos --org dev.mak --project-name makohos makohos >/dev/null) || true
mkdir -p "$app/assets" "$app/libmpv"
cp "$wav" "$app/assets/tone.wav"
cp "$libmpv"/libmpv_ohos-*.so "$app/libmpv/"
rm -rf "$app/test"

python3 -I - "$app" "$kit" <<'PY'
import json, re, sys
app, kit = sys.argv[1], sys.argv[2]
p = f'{app}/pubspec.yaml'
s = open(p).read()
s = s.replace('dependencies:\n', f'dependencies:\n  mpv_audio_kit:\n    path: {kit}\n', 1)
s = re.sub(r'(\nflutter:\n)', r'\1  assets:\n    - assets/tone.wav\n', s, count=1)
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
open(p, 'w').write(s)
PY

cat > "$app/lib/main.dart" <<'DART'
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ColoredBox(color: Color(0xFF000000)));
  try {
    MpvAudioKit.ensureInitialized();
    print('MAK_OHOS_LIB os=${Platform.operatingSystem}');
    final player = Player();
    await player.ready;
    await player.open(Media('asset://assets/tone.wav'));
    await player.play();
    final at = await player.stream.position
        .firstWhere((p) => p > const Duration(seconds: 2))
        .timeout(const Duration(seconds: 90));
    final driver = player.state.output.currentAo;
    final ok = driver == 'ohaudio' && player.state.playback.playing;
    print('MAK_OHOS_RESULT ${ok ? 'PASS' : 'FAIL'} ao=$driver '
        'position=$at params=${player.state.output.audioOutParams}');
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
