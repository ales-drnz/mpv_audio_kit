// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../types/enums/interruption_policy.dart';

/// What an outside pause of the web session's `<audio>` element does
/// under [MediaSession.interruptionPolicy], as an interruption on iOS and
/// Android: the command to send, or none.
@internal
final class OutsidePauseFollower {
  /// The policy of the session, by its name.
  InterruptionPolicy policy = InterruptionPolicy.pauseAndResume;

  // Paused by an outside pause, to play again when it ends.
  bool _paused = false;

  /// The command for an outside change of the element: `'pause'` when it
  /// stopped while the player played ([playing]), `'play'` when it plays
  /// again after a pause this sent, under [InterruptionPolicy.pauseAndResume].
  String? onOutside({required bool elementPlaying, required bool playing}) {
    if (policy == InterruptionPolicy.keepPlaying) {
      _paused = false;
      return null;
    }
    if (!elementPlaying) {
      if (!playing) return null;
      _paused = policy == InterruptionPolicy.pauseAndResume;
      return 'pause';
    }
    if (!_paused) return null;
    _paused = false;
    return 'play';
  }

  /// Forgets a pause this sent: the session ended, or the user played or
  /// paused the player since.
  void reset() => _paused = false;

  /// [policy] from its name in the session's config, the default for an
  /// unknown one.
  static InterruptionPolicy policyOf(Object? name) =>
      InterruptionPolicy.values.firstWhere(
        (p) => p.name == name,
        orElse: () => InterruptionPolicy.pauseAndResume,
      );
}
