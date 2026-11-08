// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// PlayerState in groups (0.7.0): every field of 0.6 lives in exactly one
// group, its flat getter is deprecated and reads it there, copyWith sets a
// flat field in its group and leaves the other groups as they were, and the
// snapshot prints as before.

// The flat fields are read here on purpose, to check where they point.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// The fields added in the groups after 0.6, with no flat getter.
const _groupOnly = {'durationEstimated'};

/// The fields of each group, from its library, those of 0.6 only.
Map<String, List<String>> _groupFields() {
  final out = <String, List<String>>{};
  for (final f in Directory('lib/src/player/state').listSync()) {
    final text = File(f.path).readAsStringSync();
    final attr = RegExp(r'\[PlayerState\.(\w+)\]').firstMatch(text)![1]!;
    out[attr] = [
      for (final m in RegExp(
        r'^  final [^;]+? (\w+);$',
        multiLine: true,
      ).allMatches(text))
        if (!_groupOnly.contains(m[1]!)) m[1]!,
    ];
  }
  return out;
}

void main() {
  test('the 96 fields of 0.6 are in six groups, each in one', () {
    final groups = _groupFields();
    expect(groups.keys.toSet(), {
      'playback',
      'network',
      'file',
      'output',
      'settings',
      'versions',
    });
    final all = [for (final g in groups.values) ...g];
    expect(all.length, 96);
    expect(all.toSet().length, 96);
  });

  test('each flat getter is deprecated and reads its own group', () {
    final generated = File(
      'lib/src/generated/player_state_data.dart',
    ).readAsStringSync();
    final getters = {
      for (final m in RegExp(
        // The type may hold spaces (Map<String, String>), and a long
        // getter wraps after =>.
        r"@Deprecated\('Use (\w+)\.(\w+);[^)]*\)\n\s+[^\n]+? get (\w+) =>"
        r'\s*_self\.(\w+)\.(\w+);',
      ).allMatches(generated))
        m[3]!: (m[1]!, m[2]!, m[4]!, m[5]!),
    };
    final groups = _groupFields();
    expect(getters.length, 96);
    for (final MapEntry(key: group, value: fields) in groups.entries) {
      for (final f in fields) {
        expect(getters[f], (group, f, group, f), reason: f);
      }
    }
  });

  test('a flat getter gives the value of its group', () {
    const s = PlayerState(
      playback: PlaybackState(position: Duration(seconds: 3)),
      network: NetworkState(buffering: true),
      file: FileState(mediaTitle: 'Song'),
      output: OutputState(currentAo: 'pipewire'),
      settings: PlayerSettings(volume: 42),
      versions: LibraryVersions(mpvVersion: 'mpv 0.41.0'),
    );
    expect(s.position, const Duration(seconds: 3));
    expect(s.buffering, isTrue);
    expect(s.mediaTitle, 'Song');
    expect(s.currentAo, 'pipewire');
    expect(s.volume, 42);
    expect(s.mpvVersion, 'mpv 0.41.0');
  });

  test('copyWith of a flat field changes its group only', () {
    const s = PlayerState();
    final next = s.copyWith(position: const Duration(seconds: 5));
    expect(next.playback.position, const Duration(seconds: 5));
    expect(identical(next.network, s.network), isTrue);
    expect(identical(next.file, s.file), isTrue);
    expect(identical(next.output, s.output), isTrue);
    expect(identical(next.settings, s.settings), isTrue);
    expect(identical(next.versions, s.versions), isTrue);
    expect(identical(s.copyWith().playback, s.playback), isTrue);
  });

  test('a flat field wins over its group given whole', () {
    final next = const PlayerState().copyWith(
      settings: const PlayerSettings(volume: 10, mute: true),
      volume: 70,
    );
    expect(next.settings.volume, 70);
    expect(next.settings.mute, isTrue);
  });

  test('a nullable flat field clears with null', () {
    final s = const PlayerState().copyWith(readError: true);
    expect(s.network.readError, isTrue);
    expect(s.copyWith(readError: null).network.readError, isNull);
    expect(s.copyWith().network.readError, isTrue);
  });

  test('== and hashCode go through the groups', () {
    final a = const PlayerState().copyWith(volume: 55, mediaTitle: 'x');
    const b = PlayerState(
      settings: PlayerSettings(volume: 55),
      file: FileState(mediaTitle: 'x'),
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == a.copyWith(volume: 56), isFalse);
  });

  test('toString prints the snapshot as in 0.6', () {
    final s = const PlayerState().copyWith(
      playing: true,
      position: const Duration(seconds: 1),
      volume: 80,
      mediaTitle: 'Song',
    );
    expect(
      s.toString(),
      'PlayerState(playing: true, playWhenReady: false, position: '
      '0:00:01.000000, duration: 0:00:00.000000, volume: 80.0, '
      'mediaTitle: Song)',
    );
  });
}
