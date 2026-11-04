---
status: accepted
date: 2026-11-04
---

# Each version runs on the libmpv of its pin only

## Context and problem statement

Each version of the package pins one release of libmpv-scripts
(`libmpvRelease`), which the build hook bundles. An app can also bundle its
own libmpv or pass one by path. Up to 0.6.1 the package ran on older
releases too: it read which patches were there and kept a branch for each
missing one, and a libmpv of another release played with a warning on
`internalLog`. Each branch was code to keep and test, and a warning nobody
reads hid features that were missing. Which libmpv does a version run on?

## Decision drivers

* Each published version updates libmpv, and runs on the code of that
  release: no code for an older one is carried along.
* A libmpv the package cannot drive fails at start, not later with
  features missing.
* An app that builds its own libmpv (a GPL build with Rubber Band) can
  still do so.

## Considered options

* Any release from a minimum on, with a branch for each missing patch.
* The pinned release only, checked at start.

## Decision outcome

Chosen option: the pinned release only. At start the player reads
`mpv-version`, natively before it reads any event and on the web after the
ABI and layout checks of record 0002, and a version that does not end with
`+rN` of the pin fails the start with a `PlayerInitException` that names
the release found and the one needed (`libmpvMismatch`). The struct layout
and the properties of the patches are those of the pin, with no branch for
another release. A test fails when lib names a release other than the pin.

### Consequences

* Good, because the decoders, the init and the docs hold one layout and one
  set of patches.
* Good, because a stale build cache or a wrong custom libmpv fails at once,
  with the fix in the message.
* Bad, because a custom libmpv must be rebuilt from libmpv-scripts at the
  new pin with each version of the package.
* Neutral, because the change was Breaking in 0.6.2: MIGRATION.md has it.
