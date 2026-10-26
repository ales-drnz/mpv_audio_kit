/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit

import io.flutter.plugin.common.BinaryMessenger
import java.io.ByteArrayInputStream
import kotlin.test.assertContentEquals
import kotlin.test.assertNull
import org.junit.jupiter.api.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.isNull
import org.mockito.ArgumentMatchers.notNull
import org.mockito.ArgumentMatchers.same
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`

/**
 * The wiring of the `mpv_audio_kit` channel. openFileDescriptor blocks until
 * the provider has the file, which for a cloud provider means a download:
 * on the main thread that is an ANR. The ANR itself needs a device; here the
 * channel must run its calls on a background task queue of the messenger.
 */
class FileDescriptorChannelTest {

    @Test
    fun `the channel handles its calls on a background task queue`() {
        val messenger = mock(BinaryMessenger::class.java)
        val queue = mock(BinaryMessenger.TaskQueue::class.java)
        `when`(messenger.makeBackgroundTaskQueue()).thenReturn(queue)

        FileDescriptorChannel { error("no call reaches the resolver here") }.attach(messenger)

        verify(messenger).setMessageHandler(eq("mpv_audio_kit"), notNull(), same(queue))
        // The two-argument form is the main thread.
        verify(messenger, never()).setMessageHandler(eq("mpv_audio_kit"), any())
    }

    @Test
    fun `detach removes the handler from the same queue`() {
        val messenger = mock(BinaryMessenger::class.java)
        val queue = mock(BinaryMessenger.TaskQueue::class.java)
        `when`(messenger.makeBackgroundTaskQueue()).thenReturn(queue)
        val channel = FileDescriptorChannel { error("no call reaches the resolver here") }

        channel.attach(messenger)
        channel.detach()

        verify(messenger).setMessageHandler(eq("mpv_audio_kit"), isNull(), same(queue))
    }

    @Test
    fun `readArtwork returns the whole image up to the limit`() {
        val image = ByteArray(200_000) { it.toByte() }
        assertContentEquals(
            image,
            FileDescriptorChannel.readArtwork(ByteArrayInputStream(image), 200_000),
        )
    }

    @Test
    fun `readArtwork gives up on an image past the limit or an empty one`() {
        val image = ByteArray(200_001)
        assertNull(FileDescriptorChannel.readArtwork(ByteArrayInputStream(image), 200_000))
        assertNull(FileDescriptorChannel.readArtwork(ByteArrayInputStream(ByteArray(0)), 200_000))
    }
}
