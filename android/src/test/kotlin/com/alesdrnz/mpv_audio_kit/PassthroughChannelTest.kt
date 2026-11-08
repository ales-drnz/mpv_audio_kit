/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.assertEquals
import org.junit.jupiter.api.Test

/**
 * The `mpv_audio_kit/passthrough` channel: the codecs it reports for the
 * encodings the output takes, against stand-ins of AudioTrack and of the
 * HDMI plug broadcast.
 */
class PassthroughChannelTest {

    /** An output on API [sdk] that plays [direct] directly, plugged with [plugged]. */
    private class FakeProbe(
        override val sdk: Int,
        private val direct: Set<Int> = emptySet(),
        private val plugged: IntArray? = null,
    ) : PassthroughChannel.Probe {
        val asked = mutableListOf<Int>()
        override fun direct(encoding: Int): Boolean {
            asked += encoding
            return encoding in direct
        }
        override fun plugged(): IntArray? = plugged
    }

    /** The answer [method] gets from a channel over [probe]. */
    private fun answer(probe: PassthroughChannel.Probe, method: String = "codecs"): Pair<String, Any?> {
        var got: Pair<String, Any?>? = null
        PassthroughChannel(probe).onMethodCall(MethodCall(method, null), object : MethodChannel.Result {
            override fun success(result: Any?) { got = "success" to result }
            override fun error(code: String, message: String?, details: Any?) {
                got = "error" to code
            }
            override fun notImplemented() { got = "notImplemented" to null }
        })
        return got!!
    }

    @Test
    fun `API 29 and later asks AudioTrack for each codec`() {
        val probe = FakeProbe(sdk = 33, direct = setOf(AC3, E_AC3, PCM_FLOAT))
        assertEquals("success" to listOf("ac3", "eac3"), answer(probe))
        assertEquals(listOf(AC3, E_AC3, E_AC3_JOC, DTS), probe.asked)
    }

    @Test
    fun `E-AC3 with Atmos (JOC) counts as E-AC3`() {
        assertEquals("success" to listOf("eac3"), answer(FakeProbe(sdk = 30, direct = setOf(E_AC3_JOC))))
    }

    @Test
    fun `TrueHD and DTS-HD stay out, the track is IEC61937 stereo`() {
        val probe = FakeProbe(sdk = 34, direct = setOf(DTS, DTS_HD, TRUEHD))
        assertEquals("success" to listOf("dts"), answer(probe))
    }

    @Test
    fun `before API 29 the HDMI plug broadcast gives the encodings`() {
        val probe = FakeProbe(sdk = 28, direct = setOf(AC3), plugged = intArrayOf(PCM_16, AC3, DTS, TRUEHD))
        assertEquals("success" to listOf("ac3", "dts"), answer(probe))
        assertEquals(emptyList(), probe.asked)
    }

    @Test
    fun `before API 29 nothing plugged is no passthrough`() {
        assertEquals("success" to emptyList<String>(), answer(FakeProbe(sdk = 24)))
    }

    @Test
    fun `an output that plays nothing directly has no passthrough`() {
        assertEquals("success" to emptyList<String>(), answer(FakeProbe(sdk = 35)))
    }

    @Test
    fun `another method is not implemented`() {
        assertEquals("notImplemented" to null, answer(FakeProbe(sdk = 33), "other"))
    }

    private companion object {
        // android.media.AudioFormat.ENCODING_*
        const val PCM_16 = 2
        const val PCM_FLOAT = 4
        const val AC3 = 5
        const val E_AC3 = 6
        const val DTS = 7
        const val DTS_HD = 8
        const val TRUEHD = 14
        const val E_AC3_JOC = 18
    }
}
