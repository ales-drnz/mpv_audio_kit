// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

/// Typed filters that register and pass mpv's 1-in 1-out gate but cannot
/// start from their bare name or from one numeric option: each needs a
/// channel layout, a model file, an expression or another option set
/// first. The bare-name and param-corner runtime tests skip them;
/// registry_coverage checks only that they are compiled in, and the
/// generated runtime coverage test starts them with their required
/// options.
const kFiltersNeedingParams = {
  'aeval', // expression(s)
  'ametadata', // mode + key
  'arnndn', // model file
  'asegment', // timestamps or counts
  'asendcmd', // commands or filename
  'asidedata', // side data type
  'astreamselect', // mapping definition
  'channelmap', // output layout / map
  'chorus', // delays/decays/speeds/depths
  'headphone', // HRTF mapping
  'pan', // channel layout + definitions
};
