# Metrics

The numbers the CI ratchet holds. The job Quality runs

    dart pub get -C tool/metrics
    dart tool/metrics/bin/metrics.dart

from the root of the package, and fails when a number is worse than the
baseline. A change that makes one worse on purpose writes the baseline again
in the same commit with `--write`, so the review sees it.

What it reads:

- **LOC**: the lines of the `.dart` files of `lib` that hold code, blank
  lines and lines of comment alone left out. `lib/src/generated` and
  `lib/src/internals/libmpv_licenses.dart` are left out. lib may grow: a
  growth past 300 lines only warns, and the commit says why.
- **Tests per lib**: the lines of code of `test` (`test/generated` left
  out) per line of lib, in thousandths. It must not go down.
- **Complexity** of each function of the same files: 1, plus one for each
  `if`, `for`, `while`, `do`, `case`, `catch`, `?:`, `&&`, `||` and `??`.
  `?.` and `??=` count nothing. Also counted: the `if` and `for` of a
  collection, each case of a switch expression, and the `||` and `&&` of a
  pattern. A closure or a local function counts apart, named after its
  function with `#1` or `>name`, and so does the initializer of a field
  or top-level variable that branches. The baseline keeps every
  function over 10 by name: one that grows, or a new one over 10, fails.
  The counts over 15 and over 10 must not grow.
- **`_PlayerBase`**: its fields (static ones left out), the ones not final,
  and its abstract members (a getter and its setter count as two).
- **API** (`api_surface.txt`): each public declaration that
  `lib/mpv_audio_kit.dart` exports, and each public member, as written.
  Any change fails, an addition too.
- **Struct layout** (`struct_layout.txt`): the fields of the `Struct` and
  `Union` classes of `mpv_bindings.dart`, and the wasm32 table of
  `web_layout.dart`. Any change fails.

The numbers are this tool's own: another script that counts the same
things can give others. Compare a version only with this tool.
