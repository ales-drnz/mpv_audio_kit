/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for which Flutter engine owns the process-wide media session
 * and its command sink. An app can run more engines (workmanager tasks,
 * add-to-app): one that detaches must not take down the session another
 * one enabled.
 */
class EngineOwnershipTest {

    private val main = Any()
    private val background = Any()

    @Test
    fun `the detach of another engine keeps the session and the sink`() {
        val o = EngineOwnership()
        o.onListen(main)
        o.onEnable(main)

        // A background task's engine comes and goes while main plays.
        assertEquals(EngineOwnership.Teardown(sink = false, session = false), o.onDetach(background))
        assertTrue(o.mayDisable(main), "main still owns the session")
        assertFalse(o.mayDisable(background))
    }

    @Test
    fun `the detach of the owner tears down its session and its sink`() {
        val o = EngineOwnership()
        o.onListen(main)
        o.onEnable(main)

        assertEquals(EngineOwnership.Teardown(sink = true, session = true), o.onDetach(main))
    }

    @Test
    fun `a disable from another engine leaves the session on`() {
        val o = EngineOwnership()
        o.onEnable(main)
        assertFalse(o.mayDisable(background), "only the owner turns the session off")
        assertTrue(o.mayDisable(main))

        o.onDisabled()
        assertTrue(o.mayDisable(background), "with nobody owning it a disable is a no-op anyway")
    }

    @Test
    fun `the cancel of another engine keeps the sink`() {
        val o = EngineOwnership()
        o.onListen(main)
        assertFalse(o.onCancel(background), "the sink belongs to main")
        assertTrue(o.onCancel(main))
    }

    @Test
    fun `the same engine disables after a hot restart`() {
        // A Hot Restart keeps the engine: the new VM's disable comes from it.
        val o = EngineOwnership()
        o.onListen(main)
        o.onEnable(main)
        assertTrue(o.mayDisable(main))
    }
}
