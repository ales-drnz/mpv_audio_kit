/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import androidx.media3.common.C
import androidx.media3.common.Player
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for the notification seek bar's scrub freeze, on the plain
 * JVM. Mirrors the Apple scrub scenarios of `test/media_session/darwin`.
 */
class ScrubFreezeTest {

    @Test
    fun `a scrub pins the bar and the landed push releases it`() {
        val f = ScrubFreeze()
        f.start(60_000, TRACK_A)
        assertEquals(60_000L, f.targetMs, "the bar pins at the drop target")

        f.onPlayback(60_400)
        assertNull(f.targetMs, "a push within 1 s of the target releases the bar")
    }

    @Test
    fun `a stale push during the seek keeps the bar pinned`() {
        val f = ScrubFreeze()
        f.start(60_000, TRACK_A)

        // A loop or rate change pushes while the seek is in flight, still at 30 s.
        f.onPlayback(30_000)
        assertEquals(60_000L, f.targetMs, "a stale push must not snap the bar back")

        f.onPlayback(60_000)
        assertNull(f.targetMs)
    }

    @Test
    fun `the backstop releases a scrub that never lands`() {
        // A drop at the end of the track: mpv clamps the seek to the end,
        // or the seek fails, and no push ever lands near the target.
        val f = ScrubFreeze()
        val generation = f.start(245_000, TRACK_A)
        f.onPlayback(200_000)
        assertEquals(245_000L, f.targetMs, "precondition: no push confirmed the target")

        assertTrue(f.expire(generation), "the backstop must release the bar")
        assertNull(f.targetMs)
    }

    @Test
    fun `the backstop of an older scrub leaves a newer one pinned`() {
        val f = ScrubFreeze()
        val first = f.start(60_000, TRACK_A)
        val second = f.start(90_000, TRACK_A)

        assertFalse(f.expire(first), "a superseded backstop is a no-op")
        assertEquals(90_000L, f.targetMs)
        assertTrue(f.expire(second))
        assertNull(f.targetMs)
    }

    @Test
    fun `a new track releases the bar`() {
        // The drop at the end of track A ran into track B, whose positions
        // start near 0 and never land on the target.
        val f = ScrubFreeze()
        f.start(245_000, TRACK_A)
        f.onPlayback(400)
        assertEquals(245_000L, f.targetMs, "precondition: far from the target")

        assertTrue(f.onTrack(TRACK_B), "the target belongs to the previous track")
        assertNull(f.targetMs)
    }

    @Test
    fun `new metadata of the same track keeps the bar pinned`() {
        // A cover downloaded late, or a config push, during the seek.
        val f = ScrubFreeze()
        f.start(60_000, TRACK_A)
        assertFalse(f.onTrack(TRACK_A))
        assertEquals(60_000L, f.targetMs)
    }

    @Test
    fun `clear releases the bar`() {
        val f = ScrubFreeze()
        f.start(60_000, TRACK_A)
        f.clear()
        assertNull(f.targetMs)
    }

    // ── Absolute seeks from Media3 ──────────────────────────────────────

    @Test
    fun `the play button at the end goes to 0 without pinning the bar`() {
        // Media3 answers Play on an ended item with seekToDefaultPosition()
        // then play(): the seek carries C.TIME_UNSET.
        val seek = ScrubFreeze.absoluteSeek(
            Player.COMMAND_SEEK_TO_DEFAULT_POSITION, C.TIME_UNSET,
        )
        assertEquals(ScrubFreeze.Seek(positionMs = 0, pin = false), seek)
    }

    @Test
    fun `a seek to an item with no position goes to 0 without pinning the bar`() {
        val seek = ScrubFreeze.absoluteSeek(Player.COMMAND_SEEK_TO_MEDIA_ITEM, C.TIME_UNSET)
        assertEquals(ScrubFreeze.Seek(positionMs = 0, pin = false), seek)
    }

    @Test
    fun `a scrub pins the bar at its position, never below 0`() {
        assertEquals(
            ScrubFreeze.Seek(positionMs = 60_000, pin = true),
            ScrubFreeze.absoluteSeek(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM, 60_000),
        )
        assertEquals(
            ScrubFreeze.Seek(positionMs = 0, pin = true),
            ScrubFreeze.absoluteSeek(Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM, -500),
        )
    }

    private companion object {
        val TRACK_A = Pair("Track A", 245_000L)
        val TRACK_B = Pair("Track B", 180_000L)
    }
}
