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
 * Main thread only, like [MediaSessionManager]; [targetMs] is `@Volatile`
 * for the same reason as the manager's snapshots.
 */
internal class ScrubFreeze {

    /** The drop target the bar is pinned at, or `null` when it follows playback. */
    @Volatile var targetMs: Long? = null
        private set

    /** A scrub from the OS slider: pin the bar at [positionMs]. */
    fun start(positionMs: Long) {
        targetMs = positionMs
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
    }

    companion object {
        /** How close the landed position must be to the target. */
        const val LAND_TOLERANCE_MS = 1000L
    }
}
