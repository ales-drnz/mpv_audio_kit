Run the same player in the browser, with libmpv built as WebAssembly. Effects, taps, waveform, loudness, hooks, playlists and live PCM work as on the other platforms.

## Serving the page

libmpv runs on threads, so the page must be cross-origin isolated. Every response needs these two headers:

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

| Where | How |
| :--- | :--- |
| `flutter run` | `flutter run -d chrome --wasm --cross-origin-isolation` |
| A host that reads a `_headers` file, such as Netlify or Cloudflare Pages | A `web/_headers` file with the two headers under `/*` |
| GitHub Pages | A service worker that adds them, such as coi-serviceworker. [mpv_studio](https://github.com/ales-drnz/mpv_studio) shows the setup in its `web/` folder. The app also needs a `web/flutter_bootstrap.js` that calls `_flutter.loader.load()` without `serviceWorkerSettings`. Otherwise Flutter's own worker replaces the one that adds the headers. |

With `credentialless` it needs Chrome or Edge 96 or Firefox 119 or later. With `require-corp` it needs Chrome or Edge 92, Firefox 79 or Safari 15.2 or later.

Safari accepts only `require-corp` for the second header. Each image or font from another origin then needs a `Cross-Origin-Resource-Policy` header.

Check the page before you create a player:

```dart
final reason = MpvAudioKit.unsupportedReason;
if (reason != null) {
  showError('This browser cannot play audio here: $reason');
}
```

`unsupportedReason` is `null` when the page can run libmpv. Otherwise a new `Player` fails with a `PlayerInitException` that gives the same reason.

## Sound and autoplay

The browser holds a page's sound until the user clicks, taps or presses a key. A `play()` called from that gesture starts it.

```dart
StreamBuilder<bool>(
  stream: MpvAudioKit.needsUserGestureStream,
  initialData: MpvAudioKit.needsUserGesture,
  builder: (context, snapshot) => snapshot.data!
      ? const Text('Tap anywhere to start the sound')
      : const SizedBox.shrink(),
);
```

## Files the user picks

`Media.fromBlob` plays a browser `File` or `Blob`, from a file input, a drop or a picked folder.

```dart
final input = web.HTMLInputElement()
  ..type = 'file'
  ..accept = 'audio/*'
  ..multiple = true;
input.onchange = (web.Event _) {
  final files = input.files!;
  player.openAll([
    for (var i = 0; i < files.length; i++) Media.fromBlob(files.item(i)!),
  ]);
}.toJS;
input.click();
```

Each entry gets the file name as its title. Files on a share the system has mounted play too.

## Network

The browser fetches every `http` and `https` request, so its rules apply.

- A server on another origin must send `Access-Control-Allow-Origin`. For one that does not, put a proxy on your origin and point a source resolver at it.
- Seeking needs a server that answers range requests. A server on another origin must also expose `Content-Range` through CORS, with `Access-Control-Expose-Headers: Content-Range`. Without it the browser hides the header, and the player cannot seek or resume there.
- An `https` page cannot open `http://` URLs, local servers included. Only `localhost` can.
- Headers the browser forbids, such as `Cookie`, `Referer` and `Host`, are not sent.
- For ICY titles from a radio on another origin, pass `streamLavfOptions: {'icy_cross_origin': '1'}` on its `Media`. The server must accept the `Icy-MetaData` header and expose `icy-metaint` through CORS.
- TLS, cookies and proxies are the browser's. The player's TLS, cookie and proxy settings have no effect.
- `smb2://` is not available. Mount the share in the system and let the user pick its files.

## Memory

All the players of a page run in one module, with one memory. It starts at 32 MiB and grows up to 512 MiB, or 256 MiB on an iPhone or an iPad, where WebKit gives a page less. It never shrinks while the page is open. When an allocation fails past that limit, the module stops and every player of the page with it.

The demuxer cache of each player takes the most of it. On the web it starts at 64 MiB ahead and 16 MiB behind, in place of 150 MiB and 50 MiB. Lower it with `setDemuxer` for several players or long network files:

```dart
await player.setDemuxer(
  const DemuxerSettings(maxBytes: 32 * 1024 * 1024, maxBackBytes: 0),
);
```

Test on a real iPhone or iPad. A desktop browser, even one that imitates a phone, does not have the memory limits of iOS.

## What differs

| Feature | In the browser |
| :--- | :--- |
| System volume | The gain of the player's output |
| Output devices | One, the page's output |
| Sample rate | One for the page: `setAudioSampleRate` sets it for every player. A rate the browser refuses throws `StateError` |
| `file://` and `content://` | Not available. The user picks files instead. |
| OS media session | The browser's media controls, through `navigator.mediaSession` |
| Hot restart | Destroys the players of the previous run and keeps the loaded module |
