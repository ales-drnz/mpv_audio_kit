Android TV, Fire TV and Google TV run the Android build of the package: the same libmpv for arm64-v8a, armeabi-v7a and x86_64, the `audiotrack` output and the media session. What a TV needs on top belongs to the app: its manifest, its banner and the focus of its widgets.

## The manifest

A TV launcher lists only the apps with a leanback entry and a banner. One APK can serve phones and TVs when neither the touchscreen nor leanback is required:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-feature android:name="android.hardware.touchscreen" android:required="false" />
    <uses-feature android:name="android.software.leanback" android:required="false" />

    <application android:banner="@drawable/tv_banner" ...>
        <activity android:name=".MainActivity" ...>
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

The banner is a 320 by 180 image. An app for TVs only sets `android.software.leanback` to `required="true"`.

## The remote

The media keys of the remote (play, pause, play-pause, next and previous) reach the player through the media session, as those of a headset do on a phone. Turn it on to get them:

```dart
await player.setMediaSession(const MediaSession());
```

The package's CI plays these keys on the Android TV emulator of API 36 and on phones from Android 7.

The arrows and the select key move the focus of the app's widgets: Flutter handles them, not the player.

## Passthrough

A TV box passes AC3, E-AC3 and DTS untouched to the TV or receiver over HDMI. `MpvAudioKit.passthroughCodecs()` tells which ones the sink accepts:

```dart
await player.setAudioSpdif(await MpvAudioKit.passthroughCodecs());
```

TrueHD and DTS-HD are not among them: `audiotrack` sends passthrough as IEC61937 stereo, which cannot carry them. See [Output](https://pub.dev/documentation/mpv_audio_kit/latest/topics/Output-topic.html) for what passthrough turns off.
