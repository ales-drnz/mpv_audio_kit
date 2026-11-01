// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The license texts of the bundled libmpv: scripts/update_libmpv.sh takes
// them from the release's licenses.zip (one <target>/ directory each, as
// write_manifest.sh of libmpv-scripts packs them), each text once, into
// lib/src/internals/libmpv_licenses.dart, which MpvAudioKit registers with
// Flutter's LicenseRegistry, and the web target's into
// web/THIRD_PARTY_LICENSES.txt. Before libmpv-r20 the file holds none.

import 'dart:convert';
import 'dart:io';

import 'package:mpv_audio_kit/src/internals/libmpv_licenses.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:test/test.dart';

import '../_helpers/release_gate.dart' show releaseNumber;
import '../_helpers/update_libmpv_fixture.dart';

const _lgpl = 'GNU LESSER GENERAL PUBLIC LICENSE\n\n  Version 3\n';
const _openssl = 'Apache License 2.0 "OpenSSL" \$HOME \\n © ünïcode\n';

/// Two targets with the same FFmpeg text, as write_licenses lays them out.
const _licenses = {
  'android/README.txt': 'libmpv r99 for android: LGPL-3.0-or-later\n',
  'android/ffmpeg/COPYING.LGPLv3': _lgpl,
  'android/mpv/LICENSE.LGPL': 'mpv LGPL\n',
  'android/someday/COPYING': 'a component this package does not name\n',
  'web/README.txt': 'libmpv r99 for web: LGPL-3.0-or-later\n',
  'web/ffmpeg/COPYING.LGPLv3': _lgpl,
  'web/openssl/LICENSE.txt': _openssl,
  'web/libmpv-scripts/LICENSE': 'BSD 3-Clause License\n',
};

/// libmpvLicenses of the libmpv_licenses.dart in [package], read by the
/// Dart VM: the packages and the text of each entry.
Future<List<(List<String>, String)>> _entries(Directory package) async {
  final script = File('${package.path}/lib/src/internals/print_licenses.dart')
    ..writeAsStringSync(
      "import 'dart:convert';\n"
      "import 'libmpv_licenses.dart';\n"
      'void main() => print(jsonEncode([\n'
      '  libmpvLicensesRelease,\n'
      '  for (final (p, t) in libmpvLicenses) [p, t],\n'
      ']));\n',
    );
  // The dart of the SDK on PATH, which update_libmpv.sh formats with too.
  final run = await Process.run('dart', [
    script.path,
  ], runInShell: Platform.isWindows);
  expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
  final decoded = jsonDecode(run.stdout as String) as List<Object?>;
  expect(decoded.first, 'r99');
  return [
    for (final e in decoded.skip(1).cast<List<Object?>>())
      ((e[0] as List<Object?>).cast<String>(), e[1] as String),
  ];
}

void main() {
  final root = Directory.current.path;

  test('the committed texts are none before libmpv-r20, else those of '
      'libmpvRelease', () {
    if (libmpvLicensesRelease.isEmpty) {
      expect(libmpvLicenses, isEmpty);
      expect(
        releaseNumber(libmpvRelease)!,
        lessThan(20),
        reason:
            'libmpv-$libmpvRelease is pinned without its license texts: '
            'run scripts/update_libmpv.sh $libmpvRelease',
      );
    } else {
      expect(libmpvLicensesRelease, libmpvRelease);
      expect(libmpvLicenses, isNotEmpty);
    }
  });

  test('git ignores web/THIRD_PARTY_LICENSES.txt, the package keeps it', () {
    final ignored = Process.runSync('git', [
      'check-ignore',
      'web/THIRD_PARTY_LICENSES.txt',
    ], workingDirectory: root);
    expect((ignored.stdout as String).trim(), 'web/THIRD_PARTY_LICENSES.txt');
    final pubignore = File('$root/.pubignore').readAsLinesSync();
    expect(pubignore, isNot(contains('/lib/')));
    expect(pubignore.where((l) => l.contains('THIRD_PARTY')), isEmpty);
  });

  group('update_libmpv.sh', () {
    late Directory package;

    setUp(() => package = packageCopy(root));
    tearDown(() => package.deleteSync(recursive: true));

    String read(String path) =>
        File('${package.path}/$path').readAsStringSync();

    test('writes each text of licenses.zip once, under its package', () async {
      final run = await updateLibmpv(
        package,
        await release(root, licenses: _licenses),
      );
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      final entries = await _entries(package);
      expect(
        [for (final (p, t) in entries) (p.join(','), t)],
        [
          ('libmpv', 'libmpv r99 for android: LGPL-3.0-or-later\n'),
          ('libmpv', 'libmpv r99 for web: LGPL-3.0-or-later\n'),
          ('FFmpeg', _lgpl),
          ('libmpv-scripts', 'BSD 3-Clause License\n'),
          ('mpv', 'mpv LGPL\n'),
          ('OpenSSL', _openssl),
          ('someday', 'a component this package does not name\n'),
        ],
      );
      // The web target's texts beside the module, joined.
      final web = read('web/THIRD_PARTY_LICENSES.txt');
      expect(web, startsWith('libmpv r99 for web: LGPL-3.0-or-later\n'));
      expect(web, contains('==== ffmpeg/COPYING.LGPLv3 ====\n\n$_lgpl'));
      expect(web, contains('==== openssl/LICENSE.txt ====\n\n$_openssl'));
      expect(web, isNot(contains('android')));
    });

    test('takes the web target\'s THIRD_PARTY_LICENSES.txt as it is, and '
        'keeps it out of the registered texts', () async {
      final run = await updateLibmpv(
        package,
        await release(
          root,
          licenses: {
            ..._licenses,
            'web/THIRD_PARTY_LICENSES.txt': 'all the web texts\n',
          },
        ),
      );
      expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
      expect(read('web/THIRD_PARTY_LICENSES.txt'), 'all the web texts\n');
      final entries = await _entries(package);
      expect(entries.map((e) => e.$2), isNot(contains('all the web texts\n')));
    });

    final refusals = <String, (Future<File> Function(), String)>{
      'a release without licenses.zip': (
        () => release(root, edit: (m) => m.remove('licenses')),
        'libmpv-r99 has no license texts',
      ),
      'a licenses.zip that is not the one of the manifest': (
        () => release(
          root,
          edit: (m) =>
              (m['licenses'] as Map<String, dynamic>)['sha256'] = '0' * 64,
        ),
        'is not the ${'0' * 64} of the manifest',
      ),
      'a target without README.txt': (
        () => release(
          root,
          licenses: {..._licenses}..remove('android/README.txt'),
        ),
        'android/ has no README.txt',
      ),
      'a release without texts for the web module': (
        () => release(
          root,
          licenses: {
            for (final e in _licenses.entries)
              if (!e.key.startsWith('web/')) e.key: e.value,
          },
        ),
        'has no web/ texts',
      ),
    };
    for (final MapEntry(key: what, value: (make, reason)) in refusals.entries) {
      test('refuses $what and writes nothing', () async {
        final before = read('lib/src/internals/libmpv_licenses.dart');
        final run = await updateLibmpv(package, await make());
        expect(run.exitCode, isNot(0), reason: '${run.stdout}');
        expect(run.stderr, contains(reason));
        expect(read('lib/src/internals/libmpv_licenses.dart'), before);
        expect(Directory('${package.path}/web').existsSync(), isFalse);
      });
    }
  });
}
