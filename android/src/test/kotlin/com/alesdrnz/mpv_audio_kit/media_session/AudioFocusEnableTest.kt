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
 * The audio focus of an enable that comes with no disable before it (a
 * Hot Restart during a call whose disable never arrived, 8433f46). The
 * session then releases the controller it had and makes a new one
 * ([MediaSessionManager] `enable`), so the new player does not start on
 * its own when the call ends.
 *
 * `MediaSessionManager` itself needs a Looper and a Context, which a JVM
 * test has not: these are the two halves it leans on, the release of the
 * old controller and the state a new one starts from. That `enable` calls
 * them is only seen on a device.
 */
class AudioFocusEnableTest {

    private class FakePort : FocusPort {
        var requests = 0
        var abandons = 0
        var noisy = false
        override fun requestFocus(): Int {
            requests++
            return AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
        override fun abandonFocus() {
            abandons++
        }
        override fun listenNoisy(on: Boolean) {
            noisy = on
        }
    }

    private val port = FakePort()
    private val emitted = mutableListOf<String?>()
    private var armedChanges = 0

    private fun controller() = AudioFocusController(
        port = port,
        policy = { "pauseAndResume" },
        emit = { emitted.add(it["type"] as String?) },
        onResumeArmedChanged = { armedChanges++ },
    )

    /** Playing, then a call: paused by the controller, the resume armed. */
    private fun inCall(c: AudioFocusController) {
        c.onPlayback(playing = true, appPauses = 3)
        c.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        c.onPlayback(playing = false, appPauses = 3)
        assertTrue(c.resumeArmed)
        emitted.clear()
    }

    @Test
    fun `the release of the old controller drops the latch, the focus and the receiver`() {
        val old = controller()
        inCall(old)
        assertTrue(port.noisy.not(), "paused: no receiver")
        val changes = armedChanges
        old.release()
        assertFalse(old.resumeArmed)
        assertEquals(changes + 1, armedChanges, "the session is told the latch went")
        assertEquals(1, port.abandons)
        assertFalse(port.noisy)
        // The end of the call, should the old listener still hear it.
        old.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(emptyList<String?>(), emitted, "the old player is gone: nothing plays")
    }

    @Test
    fun `the controller of the new session does not play at the end of the old call`() {
        val old = controller()
        inCall(old)
        old.release()
        // The enable: a new controller, and the playback of the new player,
        // paused, with the count of pauses of its own.
        val fresh = controller()
        fresh.onPlayback(playing = false, appPauses = 0)
        assertFalse(fresh.resumeArmed)
        fresh.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(emptyList<String?>(), emitted)
    }

    @Test
    fun `a play after the release asks for the focus again`() {
        val c = controller()
        inCall(c)
        c.release()
        val before = port.requests
        c.onPlayback(playing = true, appPauses = 3)
        assertEquals(before + 1, port.requests, "the focus was abandoned")
        assertTrue(port.noisy)
        assertEquals(emptyList<String?>(), emitted, "granted: nothing to pause")
    }

    @Test
    fun `a new controller asks for the focus when its player plays at the enable`() {
        val old = controller()
        old.onPlayback(playing = true, appPauses = 0)
        old.release()
        val fresh = controller()
        val before = port.requests
        fresh.onPlayback(playing = true, appPauses = 0)
        assertEquals(before + 1, port.requests)
        // And a call from here on pauses and resumes as in any session.
        fresh.onFocusChange(AudioManager.AUDIOFOCUS_LOSS_TRANSIENT)
        fresh.onPlayback(playing = false, appPauses = 0)
        fresh.onFocusChange(AudioManager.AUDIOFOCUS_GAIN)
        assertEquals(listOf<String?>("pause", "play"), emitted)
    }
}
