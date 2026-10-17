/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

/**
 * Unit tests for the notification seek bar's scrub freeze, on the plain
 * JVM. Mirrors the Apple scrub scenarios of `test/media_session/darwin`.
 */
class ScrubFreezeTest {

    @Test
    fun `a scrub pins the bar and the landed push releases it`() {
        val f = ScrubFreeze()
        f.start(60_000)
        assertEquals(60_000L, f.targetMs, "the bar pins at the drop target")

        f.onPlayback(60_400)
        assertNull(f.targetMs, "a push within 1 s of the target releases the bar")
    }

    @Test
    fun `a stale push during the seek keeps the bar pinned`() {
        val f = ScrubFreeze()
        f.start(60_000)

        // A loop or rate change pushes while the seek is in flight, still at 30 s.
        f.onPlayback(30_000)
        assertEquals(60_000L, f.targetMs, "a stale push must not snap the bar back")

        f.onPlayback(60_000)
        assertNull(f.targetMs)
    }

    @Test
    fun `clear releases the bar`() {
        val f = ScrubFreeze()
        f.start(60_000)
        f.clear()
        assertNull(f.targetMs)
    }
}
