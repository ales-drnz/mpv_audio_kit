# Browser tests

The web backend (`lib/src/backend/web`) runs here against libmpv built as
WebAssembly, in Chrome. Every file is `@TestOn('browser')`, so a plain
`flutter test` on the VM skips them.

## Layout

```
test/web/
├── README.md                this file
├── fetch_module.sh          copies a web module into module/
├── module/                  the module the tests load (not in git)
├── with_net_server.sh       flutter test with net_server.dart beside it
├── net_server.dart          the HTTP server of the network cases
├── chrome_autoplay.sh       Chrome without the autoplay policy
├── web_module_helper.dart   loads the module, gives fixture URLs
├── parity_trace.txt         the native order of events, for web_parity_test
├── web_compile_test.dart    compiles with every web compiler, DDC included
└── web_*_test.dart          the suites, under dart2wasm only
```

## The module

The tests load `libmpv.mjs`, `libmpv.wasm` and `mak_webaudio_processor.js`
from `module/`. They come from the `libmpv_web.zip` of a libmpv release
(libmpv-r20 on) or of a libmpv-scripts Build, or from a local web build.
Without them the suites fail: they do not skip.

```
# The three files of a directory: a local build, or web/ once
# scripts/update_libmpv.sh has installed the release's.
test/web/fetch_module.sh <directory>

# A zip checked against its manifest first, as CI does.
scripts/web_module.py <manifest.json> <libmpv_web.zip> test/web/module
```

## Running them

```
export CHROME_EXECUTABLE=<google-chrome or chrome-headless-shell>
dart analyze lib test

# 1. The suites, the page's sound held by the autoplay policy.
test/web/with_net_server.sh --platform chrome --wasm \
  --cross-origin-isolation test/web

# 2. The sound running, as after a user gesture.
MAK_CHROME="$CHROME_EXECUTABLE" CHROME_EXECUTABLE="$PWD/test/web/chrome_autoplay.sh" \
  test/web/with_net_server.sh --platform chrome --wasm \
  --cross-origin-isolation --dart-define=MAK_WEB_AUTOPLAY=true \
  test/web/web_audio_test.dart

# 3. The package through DDC.
flutter test --platform chrome test/web/web_compile_test.dart
```

- libmpv runs on threads, which need a cross-origin isolated page.
  flutter test serves the page with COOP and COEP only with `--wasm`
  (dart2wasm and the skwasm renderer). DDC cannot isolate it, so only
  `web_compile_test` runs there.
- A compile error in a browser test leaves flutter test waiting on the
  page instead of failing. `dart analyze` reports it first.
- The network cases need the server of `with_net_server.sh`, whose URL
  reaches them as `MAK_WEB_NET`. They skip without it.
- `web_audio_test` has a group for each of the first two runs and skips
  the other one. The second run plays sound in real time: on a desktop,
  send it to a null output (`PULSE_SINK`).

## On CI

The Test (Web) job of `.github/workflows/ci.yml` runs on `ubuntu-24.04`:

1. `scripts/ci/web_module.sh` installs the module of the libmpv the other
   jobs bundle: the libmpv-scripts run's when `LIBMPV_SCRIPTS_RUN` is set
   (from the libmpv-release artifact, through the `dir` output of
   `.github/actions/libmpv-from-run`), the pinned release's otherwise.
   `scripts/web_module.py` checks it against the manifest: the SHA-256 of
   the zip and of each file, and the ABI.
2. A libmpv before r20 has no web module. The job then runs no tests and
   says so in a notice and in the job summary.
   `test/packaging/web_module_test.dart` fails on a pin from r20 on
   whose manifest lacks the module. From r20 on, a module the job cannot
   get fails it.
3. `dart analyze lib test`, then the three runs above with the runner's
   `google-chrome`, its sound going into a PulseAudio null sink.
4. On a failure the output of each run and of the analyzer goes up as
   the `web-test-logs` artifact.

`test/ci/web_module_test.sh` tests `web_module.sh` in the Analyze job.
