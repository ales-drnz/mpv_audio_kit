/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.media.AudioManager
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for the pure audio-interruption mapping — the substance of
 * the Android interruption handling, exercised without an emulator (the
 * `AUDIOFOCUS_*` values are compile-time int constants). Asserts the
 * per-policy reaction table that mirrors the iOS `AVAudioSession` behaviour.
 */
class InterruptionLogicTest {

    // ── Permanent focus loss (another media app takes over) ─────────────

    @Test
    fun `permanent loss pauses and abandons under pauseAndResume`() {
        val r = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS, "pauseAndResume", resumeArmed = false,
        )
        assertEquals(InterruptionLogic.PAUSE, r.command)
        assertFalse(r.resumeOnFocusGain, "permanent loss must not arm auto-resume")
        assertTrue(r.abandonFocus, "permanent loss must drop focus")
    }

    @Test
    fun `permanent loss pauses and abandons under pauseOnly`() {
        val r = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS, "pauseOnly", resumeArmed = false,
        )
        assertEquals(InterruptionLogic.PAUSE, r.command)
        assertFalse(r.resumeOnFocusGain)
        assertTrue(r.abandonFocus)
    }

    @Test
    fun `permanent loss is a no-op under keepPlaying`() {
        val r = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS, "keepPlaying", resumeArmed = false,
        )
        assertNull(r.command, "keepPlaying never pauses")
        assertFalse(r.abandonFocus)
    }

    // ── Transient focus loss (phone call, alarm) ────────────────────────

    @Test
    fun `transient loss pauses and arms resume under pauseAndResume`() {
        val r = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, "pauseAndResume", resumeArmed = false,
        )
        assertEquals(InterruptionLogic.PAUSE, r.command)
        assertTrue(r.resumeOnFocusGain, "pauseAndResume arms auto-resume on a transient loss")
        assertFalse(r.abandonFocus, "transient loss keeps the focus request")
    }

    @Test
    fun `transient loss pauses without arming resume under pauseOnly`() {
        val r = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, "pauseOnly", resumeArmed = false,
        )
        assertEquals(InterruptionLogic.PAUSE, r.command)
        assertFalse(r.resumeOnFocusGain, "pauseOnly never auto-resumes")
        assertFalse(r.abandonFocus)
    }

    @Test
    fun `transient loss is a no-op under keepPlaying`() {
        val r = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, "keepPlaying", resumeArmed = false,
        )
        assertNull(r.command)
        assertFalse(r.resumeOnFocusGain)
    }

    // ── Focus regain ────────────────────────────────────────────────────

    @Test
    fun `gain resumes only when auto-resume was armed`() {
        val armed = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_GAIN, "pauseAndResume", resumeArmed = true,
        )
        assertEquals(InterruptionLogic.PLAY, armed.command)
        assertFalse(armed.resumeOnFocusGain, "the latch clears after resuming")

        val notArmed = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_GAIN, "pauseAndResume", resumeArmed = false,
        )
        assertNull(notArmed.command, "no resume if we didn't auto-pause")
    }

    // ── Ducking (nav prompts) ───────────────────────────────────────────

    @Test
    fun `can-duck keeps playing and preserves the resume latch`() {
        val r = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK, "pauseAndResume", resumeArmed = true,
        )
        assertNull(r.command, "the system auto-ducks; we never pause for a duck request")
        assertTrue(r.resumeOnFocusGain, "an unrelated duck must not clear a pending resume")
    }

    // ── Focus request result (playback-start gate) ──────────────────────

    @Test
    fun `granted focus request proceeds with no command`() {
        for (policy in listOf("pauseAndResume", "pauseOnly", "keepPlaying")) {
            val r = InterruptionLogic.onFocusRequestResult(
                AudioManager.AUDIOFOCUS_REQUEST_GRANTED, policy,
            )
            assertNull(r.command, "granted focus needs no transport change (policy=$policy)")
            assertFalse(r.resumeOnFocusGain, "policy=$policy")
        }
    }

    @Test
    fun `failed focus request pauses under pause policies`() {
        for (policy in listOf("pauseAndResume", "pauseOnly")) {
            val r = InterruptionLogic.onFocusRequestResult(
                AudioManager.AUDIOFOCUS_REQUEST_FAILED, policy,
            )
            assertEquals(InterruptionLogic.PAUSE, r.command,
                "must not barge over a non-duckable holder (policy=$policy)")
            assertFalse(r.resumeOnFocusGain, "a hard failure does not arm resume (policy=$policy)")
        }
    }

    @Test
    fun `failed focus request is a no-op under keepPlaying`() {
        val r = InterruptionLogic.onFocusRequestResult(
            AudioManager.AUDIOFOCUS_REQUEST_FAILED, "keepPlaying",
        )
        assertNull(r.command, "keepPlaying opts out of focus gating")
    }

    @Test
    fun `delayed focus request pauses and arms resume only for pauseAndResume`() {
        val par = InterruptionLogic.onFocusRequestResult(
            AudioManager.AUDIOFOCUS_REQUEST_DELAYED, "pauseAndResume",
        )
        assertEquals(InterruptionLogic.PAUSE, par.command)
        assertTrue(par.resumeOnFocusGain, "a deferred grant resumes on the later GAIN")

        val only = InterruptionLogic.onFocusRequestResult(
            AudioManager.AUDIOFOCUS_REQUEST_DELAYED, "pauseOnly",
        )
        assertEquals(InterruptionLogic.PAUSE, only.command)
        assertFalse(only.resumeOnFocusGain, "pauseOnly never auto-resumes")
    }

    // ── Becoming noisy (headphones unplugged) ───────────────────────────

    @Test
    fun `becoming noisy pauses and clears an armed resume`() {
        // A call paused playback and armed the resume, then the headphones
        // come out during the call. The unplug reaction takes no policy (it
        // is the same under all three), so one sequence covers them.
        val loss = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, "pauseAndResume", resumeArmed = false,
        )
        assertTrue(loss.resumeOnFocusGain, "precondition: the call armed the resume")

        val noisy = InterruptionLogic.onBecomingNoisy()
        assertEquals(InterruptionLogic.PAUSE, noisy.command)
        assertFalse(noisy.resumeOnFocusGain, "an unplug must clear the armed resume")

        val gain = InterruptionLogic.onFocusChange(
            AudioManager.AUDIOFOCUS_GAIN, "pauseAndResume",
            resumeArmed = noisy.resumeOnFocusGain,
        )
        assertNull(gain.command, "the end of the call must not restart into the speaker")
    }
}
