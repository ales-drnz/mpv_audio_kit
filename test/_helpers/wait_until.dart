// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The wait on a condition, in place of a fixed delay. A file of its own,
// so the unit tests take it without the libmpv helpers.

import 'dart:async';

import 'package:test/test.dart' show fail;

/// Polls [condition] every [interval] until it holds, and fails the test
/// with [reason] when it still does not after [timeout]. Use it in place
/// of a fixed delay before asserting a state that mpv reaches
/// asynchronously: it returns as soon as the state lands, and waits
/// longer under a loaded suite instead of flaking.
Future<void> waitUntil(
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 20),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'condition not met within $timeout');
    }
    await Future<void>.delayed(interval);
  }
}
