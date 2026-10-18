package com.alesdrnz.mpv_audio_kit_test_app

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
    }

    override fun onDestroy() {
        secondary?.destroy()
        secondary = null
        super.onDestroy()
    }
}
