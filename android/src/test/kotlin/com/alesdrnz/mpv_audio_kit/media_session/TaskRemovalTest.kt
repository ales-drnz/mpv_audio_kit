/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for what a swipe of the app from the recent apps does to the
 * media service. With an engine the app keeps alive the players go on, so
 * the service must stay while they play, also while a file still loads.
 */
class TaskRemovalTest {

    private fun runsDefault(playWhenReady: Boolean, mediaItemCount: Int): Boolean {
        var ran = false
        TaskRemoval.onTaskRemoved(playWhenReady, mediaItemCount) { ran = true }
        return ran
    }

    @Test
    fun `a playing session keeps the service`() {
        assertFalse(runsDefault(playWhenReady = true, mediaItemCount = 3))
    }

    @Test
    fun `a file still loading is not paused`() {
        // Media3 alone checks isPlaying, which is false while loading, and
        // would pause the player and stop the service.
        assertFalse(runsDefault(playWhenReady = true, mediaItemCount = 1))
    }

    @Test
    fun `a paused session gets the default teardown`() {
        assertTrue(runsDefault(playWhenReady = false, mediaItemCount = 3))
    }

    @Test
    fun `an empty session gets the default teardown`() {
        assertTrue(runsDefault(playWhenReady = true, mediaItemCount = 0))
        assertTrue(runsDefault(playWhenReady = false, mediaItemCount = 0))
    }
}
