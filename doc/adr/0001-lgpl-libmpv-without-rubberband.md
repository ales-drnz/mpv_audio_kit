---
status: accepted
date: 2026-11-04
---

# The bundled libmpv is LGPL, without Rubber Band

## Context and problem statement

The package is BSD-3-Clause and bundles libmpv, built by libmpv-scripts
from mpv, FFmpeg and the libraries they link. An app that ships the package
ships that libmpv. Under which license does it come, and which libraries
can it link?

## Decision drivers

* An app keeps its own license, closed apps included.
* Pitch and tempo work without extra setup.
* The users of an app can replace libmpv and get its source.

## Considered options

* LGPL, version 3 or later, without the GPL libraries (Rubber Band among
  them).
* GPL, with Rubber Band.
* Both, the GPL one by default.

## Decision outcome

Chosen option: LGPL without the GPL libraries, because it is the only one
that lets every app keep its own license. Pitch and tempo come from
`setPitch`, `setRate`, `AtempoEffect` and `AsetrateEffect`. libmpv-scripts
keeps a GPL option (`LIBMPV_GPL=1`) for an app that wants Rubber Band and
takes the GPL; the app bundles that build itself.

### Consequences

* Good, because an app of any license can ship the package.
* Good, because `showLicensePage` lists the texts of the bundled libmpv
  with nothing to set up, and each release has a `licenses.zip`.
* Bad, because `lavfi-rubberband` is missing from the default build: its
  pitch shift sounds better than the one of `asetrate` and `atempo`.
* Neutral, because an app must still meet the LGPL: name libmpv, ship the
  texts, let users replace it. LICENSES.md says how.

## More information

LICENSES.md, and the license options of libmpv-scripts. Whether the LGPL
version 3 can be met on iOS is a legal question this record leaves out.
