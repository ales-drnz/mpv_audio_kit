package com.alesdrnz.mpv_audio_kit_test_app

import android.app.ActivityManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // A second engine for android_engine_exit_test: it runs a Dart
    // entrypoint of the test app, which plays, and the test destroys it
    // while it does, as Android destroys an engine whose process stays.
    private var secondary: FlutterEngine? = null

    // The "call" of android_focus_foreground_test: a GAIN_TRANSIENT focus
    // request of this process, which the kit's media session loses to.
    private var callFocus: AudioFocusRequest? = null
    private val callListener = AudioManager.OnAudioFocusChangeListener { }

    // The emulator jobs read these from logcat: on API 34 the activity was
    // once recreated under a running test, which then hung.
    override fun onCreate(savedInstanceState: Bundle?) {
        Log.i("mak_test", "MainActivity onCreate, restored=${savedInstanceState != null}")
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mpv_audio_kit_test_app/engine")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        secondary?.destroy()
                        val engine = FlutterEngine(applicationContext)
                        engine.dartExecutor.executeDartEntrypoint(
                            DartExecutor.DartEntrypoint(
                                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                                call.argument<String>("library")!!,
                                call.argument<String>("function")!!,
                            ),
                        )
                        secondary = engine
                        result.success(null)
                    }
                    "destroy" -> {
                        secondary?.destroy()
                        secondary = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mpv_audio_kit_test_app/focus")
            .setMethodCallHandler { call, result ->
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                when (call.method) {
                    "requestTransient" -> result.success(requestCallFocus(audio))
                    "abandon" -> {
                        abandonCallFocus(audio)
                        result.success(null)
                    }
                    // Whether the kit's media session service runs in the
                    // foreground, or null when it does not run.
                    "serviceForeground" -> {
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        @Suppress("DEPRECATION")
                        val service = am.getRunningServices(Int.MAX_VALUE).firstOrNull {
                            it.service.className.endsWith(".MpvMediaSessionService")
                        }
                        result.success(service?.foreground)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestCallFocus(audio: AudioManager): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .setOnAudioFocusChangeListener(callListener)
                .build()
            callFocus = request
            return audio.requestAudioFocus(request)
        }
        @Suppress("DEPRECATION")
        return audio.requestAudioFocus(
            callListener,
            AudioManager.STREAM_VOICE_CALL,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
        )
    }

    private fun abandonCallFocus(audio: AudioManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            callFocus?.let { audio.abandonAudioFocusRequest(it) }
            callFocus = null
        } else {
            @Suppress("DEPRECATION")
            audio.abandonAudioFocus(callListener)
        }
    }

    override fun onDestroy() {
        Log.i(
            "mak_test",
            "MainActivity onDestroy, changing=0x" +
                Integer.toHexString(changingConfigurations) + " finishing=$isFinishing",
        )
        secondary?.destroy()
        secondary = null
        super.onDestroy()
    }
}
