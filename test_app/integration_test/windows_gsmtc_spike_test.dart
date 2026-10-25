// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Spike: whether a hosted Windows runner shows the app's session to
// GlobalSystemMediaTransportControlsSessionManager, the API the Windows
// media flyout reads, and whether TryPauseAsync from there pauses the
// player. Windows PowerShell 5.1 reads it, since PowerShell 7 has no WinRT
// projection. CI runs it with continue-on-error in the Build Windows job:
// its log says what the runner sees. windows_smtc_test is the check that
// does not depend on it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';

const _script = r'''
param([string]$Title)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
  $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
  $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1
function Await($Operation, [Type]$Type) {
  $task = $asTask.MakeGenericMethod($Type).Invoke($null, @($Operation))
  if (-not $task.Wait(10000)) { throw 'timed out' }
  $task.Result
}
$null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager,Windows.Media.Control,ContentType=WindowsRuntime]
$manager = Await ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager])
$sessions = $manager.GetSessions()
"sessions $($sessions.Count)"
foreach ($s in $sessions) {
  $p = Await ($s.TryGetMediaPropertiesAsync()) ([Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties])
  "session $($s.SourceAppUserModelId)|$($p.Title)|$($p.Artist)|$($s.GetPlaybackInfo().PlaybackStatus)"
  if ($p.Title -eq $Title) { "paused $(Await ($s.TryPauseAsync()) ([bool]))" }
}
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  testWidgets('GSMTC lists the session and TryPauseAsync pauses the player', (
    _,
  ) async {
    final player = Player(
      configuration: const PlayerConfiguration(logLevel: LogLevel.off),
    );
    addTearDown(() async {
      await player.setMediaSession(null);
      await player.dispose();
    });
    await player.setRawProperty('ao', 'null');
    final tagged = await materializeFixture('tagged.m4a');
    await player.setMediaSession(const MediaSession(appName: 'MakSpike'));
    await player.open(Media(tagged), play: true);
    await player.stream.playing
        .firstWhere((p) => p)
        .timeout(const Duration(seconds: 10));
    // The cover and tags settle through the channel.
    await Future<void>.delayed(const Duration(seconds: 1));

    final script = File('${Directory.systemTemp.path}/mak_gsmtc_spike.ps1');
    await script.writeAsString(_script);
    final paused = player.stream.playWhenReady.firstWhere(
      (p) => !p,
      orElse: () => true,
    );
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      script.path,
      '-Title',
      'Tagged Title',
    ]);
    // ignore: avoid_print
    print('[gsmtc] exit ${result.exitCode}\n${result.stdout}${result.stderr}');
    expect(result.exitCode, 0);
    expect('${result.stdout}', contains('|Tagged Title|Tagged Artist|'));
    expect('${result.stdout}', contains('paused True'));
    await paused.timeout(const Duration(seconds: 5));
  }, skip: !Platform.isWindows);
}
