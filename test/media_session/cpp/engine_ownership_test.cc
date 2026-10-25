// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// The table of the multi engine rule against native_common/engine_ownership.h,
// the header the Windows and Linux plugins share. The same cases run for
// Android (EngineOwnershipTest.kt) and Apple (test/media_session/darwin).
// Built and run by test/media_session/cpp/run.sh, in the Linux CI job.

#include <cstdio>

#include "engine_ownership.h"

namespace {

using mpv_audio_kit::EngineOwnership;

int failures = 0;

#define CHECK(cond)                                                  \
  do {                                                               \
    if (!(cond)) {                                                   \
      std::printf("  FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond); \
      ++failures;                                                    \
    }                                                                \
  } while (0)

struct Sink {
  const char* name;
};

// Two engines, as their plugins would be, and the sink each listens on.
int engine_a = 1;
int engine_b = 2;
const void* const A = &engine_a;
const void* const B = &engine_b;
Sink a_sink{"A"};
Sink b_sink{"B"};
Sink a_restarted_sink{"A after a Hot Restart"};

using Ownership = EngineOwnership<Sink*>;

void Run(const char* name, void (*body)()) {
  const int before = failures;
  body();
  std::printf("%s %s\n", failures == before ? "ok  " : "FAIL", name);
}

void FirstEnableOwns() {
  Ownership o;
  CHECK(o.TryEnable(A));
  CHECK(o.MayUpdate(A));
  CHECK(o.MayDisable(A));
}

void SecondEnableRefused() {
  Ownership o;
  o.TryEnable(A);
  CHECK(!o.TryEnable(B));
  CHECK(o.MayUpdate(A));
  CHECK(o.MayDisable(A));
}

void OtherUpdatesIgnored() {
  Ownership o;
  o.TryEnable(A);
  o.TryEnable(B);
  CHECK(!o.MayUpdate(B));
}

void OtherDisableIgnored() {
  Ownership o;
  o.TryEnable(A);
  CHECK(!o.MayDisable(B));
  CHECK(o.MayUpdate(A));
}

void OtherDetachChangesNothing() {
  Ownership o;
  o.OnListen(A, &a_sink);
  o.TryEnable(A);
  o.OnListen(B, &b_sink);
  CHECK(!o.OnDetach(B));
  CHECK(o.MayUpdate(A));
  CHECK(o.CommandSink() == &a_sink);
}

void OwnerDetachTurnsTheSessionOff() {
  Ownership o;
  o.OnListen(A, &a_sink);
  o.TryEnable(A);
  CHECK(o.OnDetach(A));
  CHECK(!o.MayUpdate(A));
  CHECK(o.CommandSink() == nullptr);
}

void FreeAfterTheOwnerDetachOrDisable() {
  Ownership detached;
  detached.TryEnable(A);
  detached.OnDetach(A);
  CHECK(detached.TryEnable(B));

  Ownership disabled;
  disabled.TryEnable(A);
  CHECK(disabled.MayDisable(A));
  disabled.OnDisabled();
  CHECK(disabled.TryEnable(B));
  CHECK(disabled.MayUpdate(B));
}

void CommandsGoToTheOwnersSink() {
  Ownership o;
  o.OnListen(A, &a_sink);
  o.TryEnable(A);
  // The second engine's Dart listens before it sends its enable.
  o.OnListen(B, &b_sink);
  o.TryEnable(B);
  CHECK(o.CommandSink() == &a_sink);
  o.OnCancel(B);
  CHECK(o.CommandSink() == &a_sink);
  o.OnCancel(A);
  CHECK(o.CommandSink() == nullptr);
}

void HotRestartKeepsTheEngine() {
  Ownership o;
  o.OnListen(A, &a_sink);
  CHECK(o.TryEnable(A));
  // The new VM of the same engine listens and enables again.
  o.OnListen(A, &a_restarted_sink);
  CHECK(o.TryEnable(A));
  CHECK(o.CommandSink() == &a_restarted_sink);
  CHECK(o.MayDisable(A));
}

}  // namespace

int main() {
  Run("1 A enables and owns the session", FirstEnableOwns);
  Run("2 B's enable is refused while A owns it", SecondEnableRefused);
  Run("3 B's updates are ignored", OtherUpdatesIgnored);
  Run("4 B's disable is ignored", OtherDisableIgnored);
  Run("5 B's detach changes nothing", OtherDetachChangesNothing);
  Run("6 A's detach turns the session and its commands off",
      OwnerDetachTurnsTheSessionOff);
  Run("7 after A's detach or disable B's enable is accepted",
      FreeAfterTheOwnerDetachOrDisable);
  Run("8 an OS command goes to the owner's sink, B listened after",
      CommandsGoToTheOwnersSink);
  Run("9 a Hot Restart of A keeps the session with A", HotRestartKeepsTheEngine);
  std::printf("%s\n", failures == 0 ? "all cases passed"
                                    : "some cases failed");
  return failures == 0 ? 0 : 1;
}
