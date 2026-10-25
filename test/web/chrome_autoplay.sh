#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# Chrome as `flutter test` launches it, with no autoplay policy: the page's
# AudioContext runs as after a user gesture, which a browser test cannot
# make. For the web audio tests (see web_audio_test.dart):
#
#   CHROME_EXECUTABLE=test/web/chrome_autoplay.sh MAK_CHROME=<chrome> ...
exec "${MAK_CHROME:?the Chrome to run}" --autoplay-policy=no-user-gesture-required "$@"
