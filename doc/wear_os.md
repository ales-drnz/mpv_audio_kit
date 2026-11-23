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

With the media session on, the package pauses when the Bluetooth output goes away, as for headphones unplugged on a phone. The rest belongs to the app. The media session reflects the player and does not play the audio, so the suppression Media3 gives a player of its own (`setSuppressPlaybackOnUnsuitableOutput`) does not reach it, and libmpv plays to whatever output Android routes to, the speaker included. Before it plays, the app checks the outputs with `AudioManager.getDevices(GET_DEVICES_OUTPUTS)` through a platform channel of its own, and opens the output switcher when none is suitable.

## While it plays

Google's quality rules ask a long playback to show an ongoing activity on the watch face (`androidx.wear:wear-ongoing`). The package does not add one to the notification of its media session, which the app cannot reach: an app that wants it posts a notification of its own with the ongoing activity.

Storage and battery are small on a watch. The disk cache does not persist (see [Network and cache](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Network%20and%20cache-topic.html)), so for listening away from the phone the app downloads the files and plays them from disk. The spectrum, the taps and the analyses decode or compute on top of playback: leave them off unless a screen shows them.

## Tests

The package's CI runs its Android integration tests on the Wear OS emulator of API 34, with a round screen and the emulated audio device as the output: playback, pauses, the media session, the media keys and the recovery of a dead audio track.
