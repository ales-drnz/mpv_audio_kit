/*
 * This file includes implementations derived from media_kit (https://github.com/media-kit/media-kit).
 * Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
 * All rights reserved.
 * Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
 */
package com.example.mpv_audio_kit

import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** MpvAudioKitPlugin */
class MpvAudioKitPlugin :
    FlutterPlugin,
    MethodCallHandler {

    companion object {
        init {
            // Loading libmpv.so via System.loadLibrary() ensures that the JVM
            // invokes libmpv's JNI_OnLoad, registering the JavaVM pointer internally.
            // Without this, dart:ffi loads it via dlopen() which skips JNI_OnLoad,
            // causing the AudioTrack audio output driver to fail with
            // "No Java virtual machine has been registered".
            System.loadLibrary("mpv")
        }
    }
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val openFds = mutableMapOf<String, ParcelFileDescriptor>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mpv_audio_kit")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "openFileDescriptor" -> {
                val uriStr = call.argument<String>("uri")
                if (uriStr != null) {
                    try {
                        val uri = Uri.parse(uriStr)
                        val pfd = context.contentResolver.openFileDescriptor(uri, "r")
                        if (pfd != null) {
                            val fd = pfd.detachFd() // Gets raw integer FD and detaches ownership.
                            // We do not save to openFds since detachFd moves ownership native/libmpv (but mpv_audio_kit cleans up the Media reference later?).
                            // Wait, no. If we detachFd(), Java no longer closes it automatically. mpv does.
                            result.success(fd)
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID", "uri is null", null)
                }
            }
            "closeFileDescriptor" -> {
                // Not needed if we use detachFd() and assume libmpv or OS cleans up.
                // But just in case, we can provide a no-op or actual close if we didn't detach.
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
