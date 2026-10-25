/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import androidx.media3.common.Player
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

/**
 * Unit tests for the play intent the session publishes. While a transient
 * focus loss holds the player paused with the resume armed, the session
 * keeps `playWhenReady` with a suppression reason, so Media3 keeps its
 * service in the foreground until the call ends (F172).
 */
class PublishedIntentTest {

    private val none = Player.PLAYBACK_SUPPRESSION_REASON_NONE
    private val focusLoss = Player.PLAYBACK_SUPPRESSION_REASON_TRANSIENT_AUDIO_FOCUS_LOSS

    @Test
    fun `a paused player with the resume armed is suppressed, not paused`() {
        assertEquals(PublishedIntent(true, focusLoss), PublishedIntent.of(playing = false, resumeArmed = true))
    }

    @Test
    fun `a playing player is published playing`() {
        assertEquals(PublishedIntent(true, none), PublishedIntent.of(playing = true, resumeArmed = false))
    }

    @Test
    fun `a paused player without the latch is published paused`() {
        assertEquals(PublishedIntent(false, none), PublishedIntent.of(playing = false, resumeArmed = false))
    }

    @Test
    fun `between the loss and Dart's pause the player is still playing`() {
        // The latch is armed before the pause it asked for reaches Dart.
        assertEquals(PublishedIntent(true, none), PublishedIntent.of(playing = true, resumeArmed = true))
    }
}
