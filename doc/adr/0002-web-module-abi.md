---
status: accepted
date: 2026-11-04
---

# The web module states an ABI and its struct layout

## Context and problem statement

On the web the package drives libmpv compiled to WebAssembly
(`libmpv.mjs`, `libmpv.wasm` and `mak_webaudio_processor.js` of
libmpv-scripts). It calls the exports by name and decodes the client API
structs out of the module's memory at fixed offsets. A module of another
build can export other functions or lay the structs out otherwise, and a
wrong offset reads garbage instead of failing. How does the package know a
module is one it can drive?

## Decision drivers

* A wrong module fails at load, with a message that names the fix, never
  later with wrong values.
* The check costs nothing per event.
* The rules can be tested on the VM.

## Considered options

* Trust the module the app serves.
* An ABI number the module exports (`mak_web_abi_version()`), checked at
  load.
* An ABI number and the table of sizes and offsets of the structs
  (`mak_web_layout()`), both checked at load.

## Decision outcome

Chosen option: the ABI number and the layout table. `MAK_WEB_ABI` of
libmpv-scripts changes with any change of the exports, the structs, the
wakeup bridge or `Module.makWebAudio`; the package names the one it drives
(`webModuleAbi`). Before any other call `MpvModule` checks the number, then
the table against the one the decoders read (`web_layout.dart`), and throws
a `StateError` that names the release to use. scripts/update_libmpv.sh
refuses a release whose manifest names another ABI.

### Consequences

* Good, because a stale module in `web/`, or one of another release, fails
  at load.
* Good, because the layout rules are plain Dart, tested on the VM
  (test/backend/web_layout_test.dart).
* Bad, because a change of a struct needs a new ABI and a release of both
  repositories together.
* Neutral, because the module must also be of the pinned release (record
  0003): the ABI alone lets two releases with the same structs through.
