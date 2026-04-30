// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Emitted by [PlayerStream.hook] when mpv fires a registered hook.
///
/// The consumer **must** call [Player.continueHook] with [id] exactly once,
/// even if processing fails — otherwise mpv will stall indefinitely.
///
/// Example:
/// ```dart
/// player.registerHook('on_load');
/// player.stream.hook.listen((event) async {
///   if (event.name == 'on_load') {
///     final url = await player.getRawProperty('stream-open-filename') ?? '';
///     if (url.startsWith('my-scheme://')) {
///       await player.setRawProperty(
///         'stream-open-filename',
///         await resolve(url),
///       );
///     }
///   }
///   player.continueHook(event.id); // always call, even on error
/// });
/// ```
class MpvHookEvent {
  /// Opaque identifier required by [Player.continueHook].
  final int id;

  /// The hook name, e.g. `"on_load"` or `"on_load_fail"`.
  final String name;

  const MpvHookEvent(this.id, this.name);

  @override
  String toString() => 'MpvHookEvent(name: $name, id: $id)';
}
