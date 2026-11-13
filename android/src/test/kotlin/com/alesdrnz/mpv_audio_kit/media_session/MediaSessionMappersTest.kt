/*
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.alesdrnz.mpv_audio_kit.media_session

import android.util.SparseBooleanArray
import androidx.media3.common.Player
import androidx.media3.session.CommandButton
import java.util.TreeMap
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.MockedConstruction
import org.mockito.Mockito
import org.mockito.stubbing.Answer

/**
 * [MediaSessionMappers] between the wire names of Dart and the Media3
 * types: the loop mode and the repeat mode, the commands the session
 * advertises for a set of `MediaAction` names, and the buttons of the
 * notification. The names are the ones Dart sends (`MediaAction.name`,
 * pinned on its side in test/media_session/media_action_wire_names_test.dart):
 * one renamed on either side would silently drop its command.
 *
 * `Player.Commands` keeps its flags in an `android.util.SparseBooleanArray`,
 * which a JVM test has only as a stub that throws. One stands in for it
 * here, over a sorted map, with the calls `FlagSet` makes (media3-common
 * 1.10.1); any other call fails the test, so a Media3 that reads its flags
 * another way is noticed.
 */
class MediaSessionMappersTest {

    private lateinit var arrays: MockedConstruction<SparseBooleanArray>

    @BeforeEach
    fun fakeSparseArrays() {
        arrays = Mockito.mockConstruction(
            SparseBooleanArray::class.java,
            { _ ->
                val flags = TreeMap<Int, Boolean>()
                Mockito.withSettings().defaultAnswer(
                    Answer<Any?> { call ->
                        val a = call.arguments
                        when (call.method.name) {
                            "append", "put" -> flags.put(a[0] as Int, a[1] as Boolean).let { null }
                            "delete" -> flags.remove(a[0] as Int).let { null }
                            "get" -> flags[a[0] as Int] ?: false
                            "size" -> flags.size
                            "keyAt" -> flags.keys.elementAt(a[0] as Int)
                            "valueAt" -> flags.values.elementAt(a[0] as Int)
                            else -> throw UnsupportedOperationException(
                                "SparseBooleanArray.${call.method.name} has no stand-in in this test",
                            )
                        }
                    },
                )
            },
            { _, _ -> },
        )
    }

    @AfterEach
    fun realSparseArrays() = arrays.close()

    /** The commands of [actions], as the set of their constants. */
    private fun commands(vararg actions: String, seekable: Boolean = true): Set<Int> {
        val c = MediaSessionMappers.buildCommands(linkedSetOf(*actions), seekable)
        return (0 until c.size()).map { c.get(it) }.toSet()
    }

    /** What every session advertises: the reads, and the release Media3
     *  needs to tear its listeners down. */
    private val always = setOf(
        Player.COMMAND_GET_CURRENT_MEDIA_ITEM,
        Player.COMMAND_GET_TIMELINE,
        Player.COMMAND_GET_METADATA,
        Player.COMMAND_RELEASE,
    )

    /** The commands each wire name of `MediaAction` adds, seekable. */
    private val added = mapOf(
        "play" to setOf(Player.COMMAND_PLAY_PAUSE),
        "pause" to setOf(Player.COMMAND_PLAY_PAUSE),
        "playPause" to setOf(Player.COMMAND_PLAY_PAUSE),
        "stop" to setOf(Player.COMMAND_STOP),
        "next" to setOf(Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM, Player.COMMAND_SEEK_TO_NEXT),
        "previous" to
            setOf(Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM, Player.COMMAND_SEEK_TO_PREVIOUS),
        "seek" to
            setOf(
                Player.COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM,
                Player.COMMAND_SEEK_TO_DEFAULT_POSITION,
            ),
        "fastForward" to setOf(Player.COMMAND_SEEK_FORWARD),
        "rewind" to setOf(Player.COMMAND_SEEK_BACK),
        "setRepeatMode" to setOf(Player.COMMAND_SET_REPEAT_MODE),
        "setShuffle" to setOf(Player.COMMAND_SET_SHUFFLE_MODE),
        "setPlaybackRate" to setOf(Player.COMMAND_SET_SPEED_AND_PITCH),
        // A session command, not a player command (LIKE_ACTION).
        "like" to emptySet(),
    )

    @Test
    fun `the loop names map to the repeat modes and back`() {
        val modes = mapOf(
            "off" to Player.REPEAT_MODE_OFF,
            "file" to Player.REPEAT_MODE_ONE,
            "playlist" to Player.REPEAT_MODE_ALL,
        )
        for ((loop, mode) in modes) {
            assertEquals(mode, MediaSessionMappers.loopToRepeatMode(loop), loop)
            assertEquals(loop, MediaSessionMappers.repeatModeToLoop(mode), loop)
        }
        assertEquals(3, modes.values.toSet().size, "three modes, none shared")
    }

    @Test
    fun `an unknown loop name or repeat mode is off`() {
        assertEquals(Player.REPEAT_MODE_OFF, MediaSessionMappers.loopToRepeatMode("one"))
        assertEquals(Player.REPEAT_MODE_OFF, MediaSessionMappers.loopToRepeatMode(""))
        assertEquals("off", MediaSessionMappers.repeatModeToLoop(-1))
        assertEquals("off", MediaSessionMappers.repeatModeToLoop(99))
    }

    @Test
    fun `no action advertises the reads and the release alone`() {
        assertEquals(always, commands())
        assertEquals(always, commands(seekable = false))
    }

    @Test
    fun `each action adds its commands and no other`() {
        for ((action, expected) in added) {
            assertEquals(always + expected, commands(action), action)
        }
    }

    @Test
    fun `an unknown action adds nothing`() {
        assertEquals(always, commands("Play", "seekTo", "", "skip"))
    }

    @Test
    fun `seek is advertised only while the entry is seekable`() {
        assertEquals(always, commands("seek", seekable = false))
        // Nothing else depends on it.
        for ((action, expected) in added - "seek") {
            assertEquals(always + expected, commands(action, seekable = false), action)
        }
    }

    @Test
    fun `any two actions advertise the commands of both`() {
        for ((a, ofA) in added) {
            for ((b, ofB) in added) {
                assertEquals(always + ofA + ofB, commands(a, b), "$a and $b")
            }
        }
    }

    @Test
    fun `every action at once advertises every command of the table`() {
        val all = commands(*added.keys.toTypedArray())
        assertEquals(always + added.values.flatten(), all)
        // Both forms of next and previous: the media keys call seekToNext(),
        // which SimpleBasePlayer drops without COMMAND_SEEK_TO_NEXT.
        assertEquals(
            true,
            all.containsAll(
                listOf(
                    Player.COMMAND_SEEK_TO_NEXT,
                    Player.COMMAND_SEEK_TO_NEXT_MEDIA_ITEM,
                    Player.COMMAND_SEEK_TO_PREVIOUS,
                    Player.COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM,
                ),
            ),
        )
    }

    // ── The buttons of the notification ─────────────────────────────────
    //
    // Not the heart (`like`): its SessionCommand takes `Bundle.EMPTY`,
    // which is null in the android.jar of a JVM test. The integration
    // tests on the emulator have it.

    private fun buttons(
        vararg actions: String,
        loop: String = "off",
        shuffle: Boolean = false,
    ): List<CommandButton> = MediaSessionMappers.buildMediaButtonPreferences(
        MediaSessionManager.ConfigSnapshot(
            actions = linkedSetOf(*actions),
            interruptionPolicy = "pauseAndResume",
            fastForwardIntervalMs = 15_000,
            rewindIntervalMs = 15_000,
            isFavorite = false,
        ),
        MediaSessionManager.PlaybackSnapshot.EMPTY.copy(loop = loop, shuffle = shuffle),
    )

    @Test
    fun `the actions the notification draws by itself get no button`() {
        assertEquals(
            emptyList<CommandButton>(),
            buttons("play", "pause", "playPause", "stop", "next", "previous", "seek", "setPlaybackRate"),
        )
    }

    @Test
    fun `the buttons come in the order of the actions`() {
        // The order is the priority: the first ones take the visible slots.
        val order = listOf("rewind", "setShuffle", "fastForward", "setRepeatMode")
        val icons = mapOf(
            "rewind" to CommandButton.ICON_REWIND,
            "setShuffle" to CommandButton.ICON_SHUFFLE_OFF,
            "fastForward" to CommandButton.ICON_FAST_FORWARD,
            "setRepeatMode" to CommandButton.ICON_REPEAT_OFF,
        )
        for (actions in listOf(order, order.reversed())) {
            // With actions of no button between them.
            val mixed = actions.flatMap { listOf(it, "play", "next") }
            assertEquals(
                actions.map { icons[it] },
                buttons(*mixed.toTypedArray()).map { it.icon },
            )
        }
    }

    @Test
    fun `rewind and fast forward ride on the player commands the session advertises`() {
        val (rewind, forward) = buttons("rewind", "fastForward")
        assertEquals(Player.COMMAND_SEEK_BACK, rewind.playerCommand)
        assertEquals(Player.COMMAND_SEEK_FORWARD, forward.playerCommand)
        assertEquals(true, commands("rewind", "fastForward").containsAll(
            listOf(rewind.playerCommand, forward.playerCommand),
        ))
    }

    @Test
    fun `the repeat button shows the mode and asks for the next, off to all to one`() {
        val shown = mapOf(
            "off" to CommandButton.ICON_REPEAT_OFF,
            "playlist" to CommandButton.ICON_REPEAT_ALL,
            "file" to CommandButton.ICON_REPEAT_ONE,
        )
        var loop = "off"
        val visited = mutableListOf<String>()
        repeat(3) {
            val button = buttons("setRepeatMode", loop = loop).single()
            assertEquals(shown[loop], button.icon, loop)
            assertEquals(Player.COMMAND_SET_REPEAT_MODE, button.playerCommand)
            visited.add(loop)
            // What a press sends back to Dart.
            loop = MediaSessionMappers.repeatModeToLoop(button.parameter as Int)
        }
        assertEquals(listOf("off", "playlist", "file"), visited)
        assertEquals("off", loop, "the third press is back at off")
        // An unknown loop name is drawn as off.
        assertEquals(CommandButton.ICON_REPEAT_OFF, buttons("setRepeatMode", loop = "?").single().icon)
    }

    @Test
    fun `the shuffle button shows the state and asks for the other`() {
        val off = buttons("setShuffle", shuffle = false).single()
        assertEquals(CommandButton.ICON_SHUFFLE_OFF, off.icon)
        assertEquals(true, off.parameter)
        val on = buttons("setShuffle", shuffle = true).single()
        assertEquals(CommandButton.ICON_SHUFFLE_ON, on.icon)
        assertEquals(false, on.parameter)
        assertEquals(Player.COMMAND_SET_SHUFFLE_MODE, on.playerCommand)
    }
}
