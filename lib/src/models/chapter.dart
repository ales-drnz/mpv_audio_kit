// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter.freezed.dart';

/// A chapter entry in the current track's `chapter-list`.
///
/// Audiobook / podcast files often carry chapter markers that mpv
/// surfaces via the `chapter-list` property. Subscribe via
/// [PlayerStream.chapters] for the live list; observe
/// [PlayerStream.currentChapter] for the active index, or jump with
/// [Player.setChapter].
@freezed
abstract class Chapter with _$Chapter {
  const factory Chapter({
    /// Start time of the chapter from the file origin.
    required Duration time,

    /// Optional human-readable title. mpv leaves this null when the
    /// container provides no chapter name.
    String? title,
  }) = _Chapter;
}
