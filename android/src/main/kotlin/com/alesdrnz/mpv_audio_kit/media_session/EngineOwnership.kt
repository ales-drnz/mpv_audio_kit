/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

/**
 * Which Flutter engine owns the process-wide media session and the command
 * sink, kept free of Android types so it runs on the plain JVM (see
 * `EngineOwnershipTest`). An engine is any token unique to it (the plugin
 * instance attached to it).
 *
 * An app can run more engines than the one that plays: a workmanager task
 * builds one per task and destroys it at the end, add-to-app keeps several.
 * The session belongs to the engine that enabled it, and the sink to the
 * one that listened last: another engine's detach, cancel or disable leaves
 * them alone. A Hot Restart keeps the engine, so the disable its new VM
 * sends is the owner's.
 */
internal class EngineOwnership {

    /** What an engine's detach tears down. */
    data class Teardown(val sink: Boolean, val session: Boolean)

    private var sinkOwner: Any? = null
    private var sessionOwner: Any? = null

    /** [engine] listened: the sink is now its. */
    fun onListen(engine: Any) {
        sinkOwner = engine
    }

    /** [engine] cancelled. Returns whether the sink was its and goes. */
    fun onCancel(engine: Any): Boolean {
        if (sinkOwner !== engine) return false
        sinkOwner = null
        return true
    }

    /** [engine] enabled the session: it owns it from now on. */
    fun onEnable(engine: Any) {
        sessionOwner = engine
    }

    /** Whether a disable from [engine] turns the session off: the owner's
     *  does, and any does while nobody owns it (a no-op then). */
    fun mayDisable(engine: Any): Boolean = sessionOwner == null || sessionOwner === engine

    /** The session went off. */
    fun onDisabled() {
        sessionOwner = null
    }

    /** [engine] detached: what of the sink and the session was its. */
    fun onDetach(engine: Any): Teardown {
        val t = Teardown(sink = sinkOwner === engine, session = sessionOwner === engine)
        if (t.sink) sinkOwner = null
        if (t.session) sessionOwner = null
        return t
    }
}
