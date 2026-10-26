/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.InputStream
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.notNull
import org.mockito.ArgumentMatchers.same
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`

/**
 * The `mpv_audio_kit/artwork` channel: what it reads of a cover URI and
 * what it refuses, against stand-ins of the ContentResolver.
 */
class ArtworkChannelTest {

    private val png = byteArrayOf(0x89.toByte(), 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A) +
        ByteArray(200_000) { it.toByte() }

    /** A compiled XML drawable, what an adaptive icon resource holds. */
    private val xml = byteArrayOf(0x03, 0x00, 0x08, 0x00) + ByteArray(100)

    /** The answer [call] gets from a channel over [source]. */
    private fun answer(
        source: (String) -> ArtworkChannel.Source,
        call: MethodCall = MethodCall(
            "readArtwork",
            mapOf("uri" to "content://media/external/audio/albumart/1", "maxBytes" to 300_000),
        ),
    ): Pair<String, Any?> {
        var got: Pair<String, Any?>? = null
        ArtworkChannel(source).onMethodCall(call, object : MethodChannel.Result {
            override fun success(result: Any?) { got = "success" to result }
            override fun error(code: String, message: String?, details: Any?) {
                got = "error" to code
            }
            override fun notImplemented() { got = "notImplemented" to null }
        })
        return got!!
    }

    private fun serving(type: String?, bytes: ByteArray?): (String) -> ArtworkChannel.Source = {
        ArtworkChannel.Source(type) { bytes?.let { ByteArrayInputStream(it) } }
    }

    @Test
    fun `the channel handles its calls on a queue of its own`() {
        val messenger = mock(BinaryMessenger::class.java)
        val queue = mock(BinaryMessenger.TaskQueue::class.java)
        `when`(messenger.makeBackgroundTaskQueue()).thenReturn(queue)

        ArtworkChannel { error("no call reaches the resolver here") }.attach(messenger)

        verify(messenger).setMessageHandler(eq("mpv_audio_kit/artwork"), notNull(), same(queue))
    }

    @Test
    fun `an image is answered with its bytes and the type the provider gives`() {
        val (kind, value) = answer(serving("image/png", png))
        assertEquals("success", kind)
        val map = value as Map<*, *>
        assertContentEquals(png, map["bytes"] as ByteArray)
        assertEquals("image/png", map["mimeType"])
    }

    @Test
    fun `an image whose provider names no type or a generic one is read`() {
        for (type in listOf(null, "application/octet-stream")) {
            val (kind, value) = answer(serving(type, png))
            assertEquals("success", kind, "$type")
            assertContentEquals(png, (value as Map<*, *>)["bytes"] as ByteArray, "$type")
        }
    }

    @Test
    fun `a song, a video or text is refused before it is read`() {
        for (type in listOf("audio/mpeg", "video/mp4", "text/plain")) {
            var opened = false
            val (kind, value) = answer({
                ArtworkChannel.Source(type) { opened = true; ByteArrayInputStream(png) }
            })
            assertEquals("success" to null, kind to value, type)
            assertTrue(!opened, type)
        }
    }

    @Test
    fun `a compiled XML drawable, nothing or a refusal gives no cover`() {
        assertEquals("success" to null, answer(serving(null, xml)))
        assertEquals("success" to null, answer(serving("image/png", null)))
        assertEquals("success" to null, answer(serving("image/png", ByteArray(0))))
        assertEquals(
            "error" to "ERROR",
            answer({ throw SecurityException("no permission") }),
        )
        assertEquals("error" to "INVALID", answer(serving("image/png", png), MethodCall("readArtwork", mapOf("uri" to "x"))))
        assertEquals("notImplemented" to null, answer(serving("image/png", png), MethodCall("other", null)))
    }

    @Test
    fun `readArtwork returns the whole image up to the limit and gives up past it`() {
        assertContentEquals(png, ArtworkChannel.readArtwork(ByteArrayInputStream(png), png.size))
        assertNull(ArtworkChannel.readArtwork(ByteArrayInputStream(png), png.size - 1))
    }

    @Test
    fun `readArtwork stops at the first bytes of what is no image`() {
        var read = 0
        val endless = object : InputStream() {
            override fun read(): Int { read++; return 0x41 }
            override fun read(b: ByteArray, off: Int, len: Int): Int {
                b.fill(0x41, off, off + 16)
                read += 16
                return 16
            }
        }
        assertNull(ArtworkChannel.readArtwork(endless, 20 * 1024 * 1024))
        assertTrue(read < 1024, "read $read bytes")
    }

    @Test
    fun `isImage knows the formats Android decodes`() {
        fun b(vararg v: Int) = ByteArray(v.size) { v[it].toByte() }
        fun s(t: String) = t.toByteArray(Charsets.US_ASCII)
        assertTrue(ArtworkChannel.isImage(b(0x89, 0x50, 0x4E, 0x47, 0x0D)))
        assertTrue(ArtworkChannel.isImage(b(0xFF, 0xD8, 0xFF, 0xE0)))
        assertTrue(ArtworkChannel.isImage(s("GIF89a")))
        assertTrue(ArtworkChannel.isImage(s("RIFF") + b(0, 0, 0, 0) + s("WEBP")))
        assertTrue(ArtworkChannel.isImage(s("BM") + b(0, 0)))
        assertTrue(ArtworkChannel.isImage(b(0, 0, 0, 0x18) + s("ftypheic")))
        assertTrue(ArtworkChannel.isImage(b(0, 0, 0, 0x1C) + s("ftypavif")))
        assertTrue(!ArtworkChannel.isImage(b(0, 0, 0, 0x18) + s("ftypmp42")))
        assertTrue(!ArtworkChannel.isImage(xml))
        assertTrue(!ArtworkChannel.isImage(s("ID3")))
    }
}
