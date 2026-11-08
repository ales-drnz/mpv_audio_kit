# Contributing

How the package is built, tested and released, for anyone who works on it.
The libmpv binaries come from [libmpv-scripts](https://github.com/ales-drnz/libmpv-scripts),
which has its own guide for the native patches (`doc/developing.md` there).

## The layout

- `lib/`: the package. `lib/mpv_audio_kit.dart` exports the public API;
  everything else is under `lib/src/`. `lib/src/generated/` comes from
  `tool/codegen` and is never edited by hand.
- `hook/build.dart`: the build hook. It downloads the libmpv of the pinned
  release for the target and checks its SHA-256 against the `_sha256`
  table. pub.dev takes nothing else in `hook/` but `build.dart` and
  `link.dart`.
- `android/`, `ios/`, `macos/`, `tvos/`, `windows/`, `linux/`: the plugin's
  platform code (media session, audio focus, passthrough).
- `test/`: unit tests in the folders named after `lib/src/`, and the runtime
  tests, which load libmpv, in `test/runtime/` and `test/runtime_extended/`.
  Shared helpers are in `test/_helpers/`.
- `test_app/`: the app of the integration tests on Android, iOS and the
  desktops, run by CI and by libmpv-scripts' check of the kit.
- `tool/`: code generation, the metrics ratchet, the diagrams of the README.
- `doc/`: the guides published as dartdoc topics, and `doc/adr/`, the
  decision records.

## Running the tests

```bash
flutter pub get
flutter analyze
flutter test -x network
```

The unit tests need no libmpv. The runtime tests load the libmpv the hook
installs, the one of the pin in `lib/src/internals/libmpv_release.dart`. To
try a libmpv of your own, point the hook at it in your local `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    mpv_audio_kit:
      libmpv: /path/to/libmpv.so
```

Never commit that entry. On a Linux with a libmpv of its own in `/usr/lib`,
the tests that expect a missing libmpv skip. `flutter test` and
`flutter analyze` can rewrite `analysis_options.yaml` and
`test_app/pubspec.lock`: put them back before a commit.

On Linux the runtime tests need a sound server or a null sink: CI starts
PulseAudio with one (`.github/workflows/ci.yml`, job Test (Linux)).

## What CI checks

`.github/workflows/ci.yml` runs on the pushes to `main` and `release/*`, on
pull requests, and by hand on any branch
(`gh workflow run CI --ref <branch>`):

- **Analyze**: `dart format`, `flutter analyze`, a publish dry run and the
  drift of the generated code, on the declared floor of Flutter and on the
  current stable.
- **Quality**: the metrics ratchet (`tool/metrics`, see its README), the red
  and green of each fix commit (`scripts/ci/check_trailers.sh` and
  `scripts/ci/verify_red.sh`) and the API against the version on pub.dev.
- **Test** on Linux, macOS and the web, and a build of the example on
  each platform.

The ratchet fails when a number gets worse: the lines of lib, the lines of
test per line of lib, the complexity of a function, the fields of the
player, and any change of the public API (`tool/metrics/api_surface.txt`).
A change that makes one worse on purpose writes the baseline again with
`dart tool/metrics/bin/metrics.dart --write` in the same commit, and says
why.

## Commits

- A fix starts with a test that fails. The commit of the fix (subject
  `fix:` or `fix(scope):`) has a `Red:` paragraph naming the test and how it
  failed, and a `Green:` paragraph with the runs where it passed, three
  times. `verify_red.sh` runs the unit tests a `Red:` names on the parent
  commit and fails when one passes there.
- Other subjects: `feat:`, `refactor:`, `test:`, `docs:`, `ci:`, `build:`,
  `chore:`.
- The CHANGELOG and the comments use short plain sentences, without dashes
  as punctuation and without a slash for "or".

## Branches and releases

Work goes to `wip/<version>-<topic>` branches. A release gathers them in
`release/<version>` once CI is green and the change has had a review, and
`release/<version>` goes to `main` when the release is published. Pull
requests are for outside contributors.

A release of the package with a new libmpv:

1. libmpv-scripts builds the binaries on its `release/rN` branch and
   publishes `libmpv-rN` (see its guide).
2. `scripts/update_libmpv.sh rN` writes the release into
   `lib/src/internals/libmpv_release.dart`, the SHA-256 of each asset into
   `hook/build.dart` and `tvos/Package.swift`, the web module into `web/`
   and the license texts into `lib/src/internals/libmpv_licenses.dart`.
   Before `libmpv-rN` is published it takes the `manifest.json` of the
   Build's `libmpv-release` artifact as a second argument.
3. `scripts/bump_version.sh`, after setting `LIB_VERSION` at its top,
   writes the version into every platform file.
4. The CHANGELOG gets the version and date in its title.
5. On `main`: the commit of the release closes its issues with
   `closes #N`, the tag is `vX.Y.Z`, and `flutter pub publish` runs from a
   checkout where `scripts/update_libmpv.sh rN` has run, so `web/` holds the
   module.
