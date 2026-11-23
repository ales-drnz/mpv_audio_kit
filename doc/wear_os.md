Wear OS watches run the Android build of the package: the same libmpv for arm64-v8a and armeabi-v7a, the `audiotrack` output and the media session. The Android minimum of the package, Android 7 (API 24), is below every Wear OS version (Wear OS 3 is API 30). What a watch needs on top belongs to the app: its manifest, the audio output it plays to, and its screens.

## The manifest

A Wear OS app declares the watch, and whether it works without a phone:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.type.watch" />

    <application ...>
        <meta-data
            android:name="com.google.android.wearable.standalone"
            android:value="true" />
    </application>
</manifest>
```

Google Play asks for 64-bit code in every Wear OS app: the package ships arm64-v8a, and armeabi-v7a for the older watches.

## The output

Google's rules for media on a watch: play only to a suitable output, a Bluetooth headset or speaker, never to the watch's own speaker; pause when that output goes away; and when none is connected, open the output switcher or the Bluetooth settings instead of showing an error.

The package does not apply them. Its media session reflects the player and does not play the audio, so the suppression Media3 gives a player of its own (`setSuppressPlaybackOnUnsuitableOutput`) does not reach it, and libmpv plays to whatever output Android routes to, the speaker included. The app checks the outputs before it plays, with `AudioManager.getDevices(GET_DEVICES_OUTPUTS)` through a platform channel of its own, and pauses from an `AudioDeviceCallback` when the headset is removed:

```dart
// Called by the app's own AudioDeviceCallback channel.
Future<void> onHeadsetRemoved() => player.pause();
```

## While it plays

A long playback shows an ongoing activity on the watch face, as Google's quality rules ask: the app ties one (`androidx.wear:wear-ongoing`) to the notification of the media session.

```dart
await player.setMediaSession(const MediaSession());
```

Storage and battery are small on a watch. The disk cache does not persist (see [Network and cache](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Network%20and%20cache-topic.html)), so for listening away from the phone the app downloads the files and plays them from disk. The spectrum, the taps and the analyses decode or compute on top of playback: leave them off unless a screen shows them.

## Status

Experimental: the package's CI does not run on a Wear OS emulator yet, and no watch has played it. The Android build it runs is the one the CI plays on phones from Android 7 and on the Android TV emulator.
