/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertSame
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Unit tests for which Flutter engine owns the process-wide media session
 * and where its commands go. An app can run more engines (workmanager
 * tasks, add-to-app): the first to enable owns the session until it
 * disables or detaches, and the others change nothing. The same table
 * runs for Apple, Windows and Linux.
 */
class EngineOwnershipTest {

    private val main = Any()
    private val background = Any()
    private val mainSink = "main sink"
    private val backgroundSink = "background sink"

    @Test
    fun `the second engine's enable is refused while the first owns the session`() {
        val o = EngineOwnership<String>()
        assertTrue(o.tryEnable(main))

        assertFalse(o.tryEnable(background), "main owns the session")
        assertTrue(o.mayUpdate(main), "the refusal leaves main the owner")
    }

    @Test
    fun `the updates of an engine that does not own the session are ignored`() {
        val o = EngineOwnership<String>()
        o.tryEnable(main)
        o.tryEnable(background)

        assertFalse(o.mayUpdate(background))
        assertTrue(o.mayUpdate(main))
    }

    @Test
    fun `a command goes to the owner's sink, not to the engine that listened last`() {
        val o = EngineOwnership<String>()
        o.onListen(main, mainSink)
        o.tryEnable(main)
        // The second engine's Dart listens before it sends its enable.
        o.onListen(background, backgroundSink)
        o.tryEnable(background)

        assertSame(mainSink, o.commandSink())
    }

    @Test
    fun `the detach of another engine keeps the session and the sink`() {
        val o = EngineOwnership<String>()
        o.onListen(main, mainSink)
        o.tryEnable(main)

        // A background task's engine comes and goes while main plays.
        o.onListen(background, backgroundSink)
        assertFalse(o.onDetach(background))
        assertSame(mainSink, o.commandSink())
        assertTrue(o.mayDisable(main), "main still owns the session")
        assertFalse(o.mayDisable(background))
    }

    @Test
    fun `the detach of the owner tears down its session and its sink`() {
        val o = EngineOwnership<String>()
        o.onListen(main, mainSink)
        o.tryEnable(main)

        assertTrue(o.onDetach(main))
        assertNull(o.commandSink())
    }

    @Test
    fun `a disable from another engine leaves the session on`() {
        val o = EngineOwnership<String>()
        o.tryEnable(main)
        assertFalse(o.mayDisable(background), "only the owner turns the session off")
        assertTrue(o.mayDisable(main))

        o.onDisabled()
        assertTrue(o.mayDisable(background), "with nobody owning it a disable is a no-op anyway")
    }

    @Test
    fun `the cancel of another engine keeps the sink`() {
        val o = EngineOwnership<String>()
        o.onListen(main, mainSink)
        o.tryEnable(main)

        o.onCancel(background)
        assertSame(mainSink, o.commandSink(), "the sink belongs to main")
        o.onCancel(main)
        assertNull(o.commandSink())
    }

    @Test
    fun `another engine enables once the owner disabled or detached`() {
        val o = EngineOwnership<String>()
        o.tryEnable(main)
        o.onDisabled()
        assertTrue(o.tryEnable(background), "free after the owner's disable")

        assertTrue(o.onDetach(background))
        assertTrue(o.tryEnable(main), "free after the owner's detach")
    }

    @Test
    fun `the same engine enables and disables after a hot restart`() {
        // A Hot Restart keeps the engine: the new VM's calls come from it.
        val o = EngineOwnership<String>()
        o.onListen(main, mainSink)
        assertTrue(o.tryEnable(main))
        assertTrue(o.tryEnable(main))
        assertTrue(o.mayDisable(main))
    }
}
