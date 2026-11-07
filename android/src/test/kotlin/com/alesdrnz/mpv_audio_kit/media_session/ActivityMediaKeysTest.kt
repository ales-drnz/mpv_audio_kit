/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import kotlin.test.assertEquals
import kotlin.test.assertNull
import org.junit.jupiter.api.Test

/**
 * Which session the media controller of each activity in front points at,
 * so the window hands the media keys of a remote to it (`ActivityMediaKeys`).
 */
class ActivityMediaKeysTest {

    /** An activity whose media controller points at [token]. */
    private class FakeWindow(var token: String? = null) : ActivityMediaKeys.Window<String> {
        override fun current(): String? = token
        override fun set(token: String?) {
            this.token = token
        }
    }

    @Test
    fun `an activity that comes after the session points at it`() {
        val keys = ActivityMediaKeys<String>()
        keys.onSession("kit")
        val window = FakeWindow()
        keys.attach("engine", window)
        assertEquals("kit", window.token)
    }

    @Test
    fun `a session that comes after the activity is pointed at`() {
        val keys = ActivityMediaKeys<String>()
        val window = FakeWindow()
        keys.attach("engine", window)
        assertNull(window.token)
        keys.onSession("kit")
        assertEquals("kit", window.token)
    }

    @Test
    fun `the end of the session clears the controller`() {
        val keys = ActivityMediaKeys<String>()
        val window = FakeWindow()
        keys.attach("engine", window)
        keys.onSession("kit")
        keys.onSession(null)
        assertNull(window.token)
    }

    @Test
    fun `an activity that leaves drops the controller it got`() {
        val keys = ActivityMediaKeys<String>()
        keys.onSession("kit")
        val window = FakeWindow()
        keys.attach("engine", window)
        keys.detach("engine")
        assertNull(window.token)
    }

    @Test
    fun `the app's own controller stays`() {
        val keys = ActivityMediaKeys<String>()
        val window = FakeWindow("app")
        keys.attach("engine", window)
        keys.onSession("kit")
        assertEquals("app", window.token)
        keys.onSession(null)
        keys.detach("engine")
        assertEquals("app", window.token)
    }

    @Test
    fun `every engine's activity points at the one session`() {
        val keys = ActivityMediaKeys<String>()
        val ui = FakeWindow()
        val other = FakeWindow()
        keys.attach("ui", ui)
        keys.attach("other", other)
        keys.onSession("kit")
        assertEquals("kit", ui.token)
        assertEquals("kit", other.token)
        keys.onSession("kit2")
        assertEquals("kit2", ui.token)
    }
}
