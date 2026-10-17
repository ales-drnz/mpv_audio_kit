/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import kotlin.math.abs

/**
 * The scrub freeze of the notification seek bar, kept free of Android
 * instance APIs so it runs on the plain JVM (see `ScrubFreezeTest`).
 *
 * A scrub from the OS slider pins the bar at the drop target ([targetMs])
 * while Dart seeks: [MpvControllerPlayer] publishes the target instead of
 * the playback position and stops extrapolating. The playback push that
 * lands within [LAND_TOLERANCE_MS] of the target releases it, so a stale
 * push mid-seek does not snap the bar back to the old position.
 *
 * A seek can also land far from the target: dropped at the end of a track
 * it runs into the next one, and a failed seek lands nowhere. A new track
 * releases the bar ([onTrack]), and so does a backstop [BACKSTOP_MS] after
 * the scrub ([expire]), as on Apple.
 *
 * Main thread only, like [MediaSessionManager]; [targetMs] is `@Volatile`
 * for the same reason as the manager's snapshots.
 */
internal class ScrubFreeze {

    /** The drop target the bar is pinned at, or `null` when it follows playback. */
    @Volatile var targetMs: Long? = null
        private set

    // Bumped by every scrub and clear, so the backstop of an older scrub
    // finds itself superseded.
    private var generation = 0

    // The track the pinned scrub was made on (see [onTrack]).
    private var scrubTrack: Any? = null

    /** A scrub from the OS slider on [track]: pin the bar at [positionMs].
     *  Returns the generation its backstop passes to [expire]. */
    fun start(positionMs: Long, track: Any?): Int {
        targetMs = positionMs
        scrubTrack = track
        return ++generation
    }

    /** The backstop of the scrub of [generation]: releases the bar if that
     *  scrub is still pinned. Returns whether it did. */
    fun expire(generation: Int): Boolean {
        if (generation != this.generation || targetMs == null) return false
        targetMs = null
        return true
    }

    /** New metadata on [track]: a scrub made on another track is stale.
     *  Returns whether it released the bar. */
    fun onTrack(track: Any?): Boolean {
        if (targetMs == null || track == scrubTrack) return false
        targetMs = null
        generation++
        return true
    }

    /** A playback push from Dart: release the bar once the landed position
     *  confirms the target. */
    fun onPlayback(positionMs: Long) {
        val target = targetMs ?: return
        if (abs(positionMs - target) <= LAND_TOLERANCE_MS) targetMs = null
    }

    /** Session enabled or disabled: nothing is in flight any more. */
    fun clear() {
        targetMs = null
        generation++
    }

    companion object {
        /** How close the landed position must be to the target. */
        const val LAND_TOLERANCE_MS = 1000L

        /** How long a scrub may stay pinned without landing. */
        const val BACKSTOP_MS = 2000L
    }
}
