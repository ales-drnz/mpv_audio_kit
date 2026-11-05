/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.media.AudioManager
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The resume of a call through [AudioFocusController], with the calls the
 * session makes: [AudioFocusController.onPlayback] for each playback push
 * of Dart, [AudioFocusController.onFocusChange] for the system. A fake
 * [FocusPort] stands for the AudioManager.
 *
 * During a call Dart is already paused. A pause of the app then changes
 * nothing in the push but the count of the app's pauses, and a stop reads
 * as an inactive player: that count is what disarms the resume.
 */
class AudioFocusControllerTest {

    private class FakePort : FocusPort {
        var requests = 0
        override fun requestFocus(): Int {
            requests++
            return AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
        override fun abandonFocus() {}
        override fun listenNoisy(on: Boolean) {}
    }

    private val emitted = mutableListOf<String?>()

    private fun controller(policy: String = "pauseAndResume") =
        AudioFocusController(
            port = FakePort(),
            policy = { policy },
            emit = { emitted.add(it["type"] as String?) },
        )

    /** Playing, then a call: the controller pauses and Dart answers with a
     *  push of its paused state, the count of the app's pauses unchanged. */
    private fun inCall(c: AudioFocusController) {
        c.onPlayback(playing = true, appPauses = 0)
        c.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        assertEquals(listOf<String?>("pause"), emitted)
        c.onPlayback(playing = false, appPauses = 0)
        emitted.clear()
    }

    @Test
    fun `the end of a call resumes after the pause of the kit`() {
        val c = controller()
        inCall(c)
        assertTrue(c.resumeArmed, "the pause the kit made keeps the resume")
        c.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(listOf<String?>("play"), emitted)
    }

    @Test
    fun `a pause of the app during a call disarms the resume`() {
        val c = controller()
        inCall(c)
        // player.pause() while paused: the push carries the new count only.
        c.onPlayback(playing = false, appPauses = 1)
        assertFalse(c.resumeArmed)
        c.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(emptyList<String?>(), emitted, "the end of the call must not play")
    }

    @Test
    fun `a stop of the app during a call disarms the resume`() {
        val c = controller()
        inCall(c)
        // player.stop(): an inactive player, and the count.
        c.onPlayback(playing = false, appPauses = 1)
        c.onPlayback(playing = false, appPauses = 1)
        c.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(emptyList<String?>(), emitted)
    }

    @Test
    fun `the count the session starts with disarms nothing`() {
        // Dart counted pauses before the session was enabled.
        val c = controller()
        c.onPlayback(playing = true, appPauses = 7)
        c.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        c.onPlayback(playing = false, appPauses = 7)
        emitted.clear()
        c.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(listOf<String?>("play"), emitted)
    }

    @Test
    fun `a pause of the app before the call keeps the end of the call silent`() {
        val c = controller()
        c.onPlayback(playing = true, appPauses = 0)
        c.onPlayback(playing = false, appPauses = 1)
        c.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        c.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(listOf<String?>("pause"), emitted)
    }

    @Test
    fun `a pause of a controller during a call still disarms`() {
        val c = controller()
        inCall(c)
        c.disarm()
        c.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(emptyList<String?>(), emitted)
    }
}
