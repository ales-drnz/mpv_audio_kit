// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Test-only libmpv interposer. Forwards the exact client-API subset
// mpv_audio_kit binds (see lib/src/mpv_bindings.dart) to the real libmpv,
// inserting a configurable sleep in front of the synchronous property /
// command entry points. The libmpv client API is synchronous: every
// set/get/command queues on the core's dispatch and waits for the playloop
// to serve it, so while the playloop is busy (e.g. CoreAudio waking a
// Bluetooth/AirPlay device for seconds during AO init) every one of these
// calls blocks its calling thread for just as long. The sleep models that
// stall deterministically, letting host tests prove which isolate pays it.
//
// Built at test runtime by test/_helpers/slow_core_shim.dart; never shipped.

#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static void *real_lib;
static int get_delay_us; // sleep before mpv_get_property / _string
static int set_delay_us; // sleep before sync set-property / command calls

static void *(*real_mpv_create)(void);
static int (*real_mpv_initialize)(void *);
static void (*real_mpv_terminate_destroy)(void *);
static void (*real_mpv_wakeup)(void *);
static int (*real_mpv_set_option_string)(void *, const char *, const char *);
static int (*real_mpv_set_property_string)(void *, const char *, const char *);
static char *(*real_mpv_get_property_string)(void *, const char *);
static int (*real_mpv_get_property)(void *, const char *, int, void *);
static int (*real_mpv_set_property)(void *, const char *, int, void *);
static int (*real_mpv_command)(void *, const char **);
static int (*real_mpv_command_string)(void *, const char *);
static void *(*real_mpv_wait_event)(void *, double);
static int (*real_mpv_observe_property)(void *, uint64_t, const char *, int);
static void (*real_mpv_free)(void *);
static void (*real_mpv_free_node_contents)(void *);
static const char *(*real_mpv_error_string)(int);
static int (*real_mpv_request_log_messages)(void *, const char *);
static int (*real_mpv_hook_add)(void *, uint64_t, const char *, int);
static int (*real_mpv_hook_continue)(void *, uint64_t);
// Async entry points return as soon as the request is queued — no delay:
// they are the calls a stalled playloop CANNOT block, which is the very
// property the tests exercise.
static int (*real_mpv_set_property_async)(void *, uint64_t, const char *, int,
                                          void *);
static int (*real_mpv_get_property_async)(void *, uint64_t, const char *, int);
static int (*real_mpv_command_async)(void *, uint64_t, const char **);

#define RESOLVE(name)                                                        \
  do {                                                                       \
    real_##name = dlsym(real_lib, #name);                                    \
    if (!real_##name) {                                                      \
      fprintf(stderr, "mak_slow_core_shim: missing symbol %s\n", #name);     \
      abort();                                                               \
    }                                                                        \
  } while (0)

// Called once from the test (via FFI on the shim's own handle) BEFORE any
// Player is created. dlopen of the same shim path in other isolates maps
// the same image, so this configuration is process-wide.
void mak_shim_configure(const char *real_path, int get_us, int set_us) {
  if (!real_lib) {
    real_lib = dlopen(real_path, RTLD_NOW | RTLD_LOCAL);
    if (!real_lib) {
      fprintf(stderr, "mak_slow_core_shim: dlopen(%s) failed: %s\n",
              real_path, dlerror());
      abort();
    }
    RESOLVE(mpv_create);
    RESOLVE(mpv_initialize);
    RESOLVE(mpv_terminate_destroy);
    RESOLVE(mpv_wakeup);
    RESOLVE(mpv_set_option_string);
    RESOLVE(mpv_set_property_string);
    RESOLVE(mpv_get_property_string);
    RESOLVE(mpv_get_property);
    RESOLVE(mpv_set_property);
    RESOLVE(mpv_command);
    RESOLVE(mpv_command_string);
    RESOLVE(mpv_wait_event);
    RESOLVE(mpv_observe_property);
    RESOLVE(mpv_free);
    RESOLVE(mpv_free_node_contents);
    RESOLVE(mpv_error_string);
    RESOLVE(mpv_request_log_messages);
    RESOLVE(mpv_hook_add);
    RESOLVE(mpv_hook_continue);
    RESOLVE(mpv_set_property_async);
    RESOLVE(mpv_get_property_async);
    RESOLVE(mpv_command_async);
  }
  get_delay_us = get_us;
  set_delay_us = set_us;
}

// Probes for the teardown and end-of-content tests, read and set through
// mak_shim_counter / mak_shim_set. All process-wide, like the stalls.
static atomic_int hook_add_delay_us; // sleep before mpv_hook_add
static atomic_int hide_eof;          // flag reads of eof-reached return 0
static atomic_int hook_adds_entered;
static atomic_int hook_adds_inflight;
static atomic_int inflight_at_destroy; // most hook_adds running at a destroy
static atomic_int late_hook_adds;      // hook_adds on an already freed handle
static atomic_int destroys;
static atomic_int hooks_pending_at_destroy;
static atomic_int watched_gets;
static char watched_get[64];

// Guards the handle and hook bookkeeping below. mpv_hook_add holds it
// across the real call, so a destroy cannot free the handle under it.
static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;
#define MAX_TRACKED 64
static void *destroyed[MAX_TRACKED];
static int n_destroyed;
static struct {
  void *h;
  uint64_t id;
} pending_hooks[MAX_TRACKED];
static int n_pending_hooks;

static int is_destroyed(void *h) {
  for (int i = 0; i < n_destroyed; i++) {
    if (destroyed[i] == h) return 1;
  }
  return 0;
}

static void forget_hook(void *h, uint64_t id) {
  for (int i = 0; i < n_pending_hooks; i++) {
    if (pending_hooks[i].h == h && pending_hooks[i].id == id) {
      pending_hooks[i] = pending_hooks[--n_pending_hooks];
      return;
    }
  }
}

void mak_shim_set(const char *knob, int value) {
  if (strcmp(knob, "hook_add_delay_us") == 0) {
    atomic_store(&hook_add_delay_us, value);
  } else if (strcmp(knob, "hide_eof") == 0) {
    atomic_store(&hide_eof, value);
  } else {
    fprintf(stderr, "mak_slow_core_shim: unknown knob %s\n", knob);
    abort();
  }
}

// Counts the synchronous reads of [name] from now on (one name at a time).
void mak_shim_watch_get(const char *name) {
  pthread_mutex_lock(&mu);
  snprintf(watched_get, sizeof watched_get, "%s", name);
  atomic_store(&watched_gets, 0);
  pthread_mutex_unlock(&mu);
}

int mak_shim_counter(const char *name) {
  if (strcmp(name, "hook_adds_entered") == 0) return hook_adds_entered;
  if (strcmp(name, "hook_adds_inflight") == 0) return hook_adds_inflight;
  if (strcmp(name, "inflight_at_destroy") == 0) return inflight_at_destroy;
  if (strcmp(name, "late_hook_adds") == 0) return late_hook_adds;
  if (strcmp(name, "destroys") == 0) return destroys;
  if (strcmp(name, "hooks_pending_at_destroy") == 0) {
    return hooks_pending_at_destroy;
  }
  if (strcmp(name, "watched_gets") == 0) return watched_gets;
  fprintf(stderr, "mak_slow_core_shim: unknown counter %s\n", name);
  abort();
}

// Zeroes the counters and the knobs; the stalls and the handles stay.
void mak_shim_reset(void) {
  pthread_mutex_lock(&mu);
  atomic_store(&hook_add_delay_us, 0);
  atomic_store(&hide_eof, 0);
  atomic_store(&hook_adds_entered, 0);
  atomic_store(&inflight_at_destroy, 0);
  atomic_store(&late_hook_adds, 0);
  atomic_store(&destroys, 0);
  atomic_store(&hooks_pending_at_destroy, 0);
  atomic_store(&watched_gets, 0);
  watched_get[0] = 0;
  pthread_mutex_unlock(&mu);
}

static void count_get(const char *name) {
  if (watched_get[0] && strcmp(name, watched_get) == 0) {
    atomic_fetch_add(&watched_gets, 1);
  }
}

// Sleeps the whole [us]: a signal (the Dart VM profiler sends SIGPROF)
// cuts a plain usleep short, so the rest is slept again.
static void stall(int us) {
  if (us <= 0) return;
  struct timespec left = {us / 1000000, (long)(us % 1000000) * 1000};
  while (nanosleep(&left, &left) != 0 && errno == EINTR) {
  }
}

// Optional read tracing (MAK_SHIM_TRACE=1 in the environment): logs every
// stalled property read with its calling thread, letting a failing test
// attribute a main-isolate gap to the exact read.
static void trace_get(const char *fn, const char *name) {
  static int trace = -1;
  if (trace < 0) {
    const char *e = getenv("MAK_SHIM_TRACE");
    trace = (e && *e == '1') ? 1 : 0;
  }
  if (trace) {
    fprintf(stderr, "[shim] %s(%s) thread=%p\n", fn, name,
            (void *)pthread_self());
  }
}

void *mpv_create(void) {
  void *h = real_mpv_create();
  // A new handle can reuse a freed one's address.
  pthread_mutex_lock(&mu);
  for (int i = 0; i < n_destroyed; i++) {
    if (destroyed[i] == h) destroyed[i] = destroyed[--n_destroyed];
  }
  pthread_mutex_unlock(&mu);
  return h;
}
int mpv_initialize(void *h) { return real_mpv_initialize(h); }
// Records what a destroy leaves behind: hook_adds still running and hooks
// mpv fired that nobody continued. The latter are continued here, so a
// test that catches one fails instead of hanging in the real destroy.
void mpv_terminate_destroy(void *h) {
  int inflight = atomic_load(&hook_adds_inflight);
  if (inflight > atomic_load(&inflight_at_destroy)) {
    atomic_store(&inflight_at_destroy, inflight);
  }
  pthread_mutex_lock(&mu);
  for (int i = 0; i < n_pending_hooks;) {
    if (pending_hooks[i].h == h) {
      atomic_fetch_add(&hooks_pending_at_destroy, 1);
      real_mpv_hook_continue(h, pending_hooks[i].id);
      pending_hooks[i] = pending_hooks[--n_pending_hooks];
    } else {
      i++;
    }
  }
  if (n_destroyed < MAX_TRACKED) destroyed[n_destroyed++] = h;
  atomic_fetch_add(&destroys, 1);
  pthread_mutex_unlock(&mu);
  real_mpv_terminate_destroy(h);
}
void mpv_wakeup(void *h) { real_mpv_wakeup(h); }

int mpv_set_option_string(void *h, const char *n, const char *v) {
  return real_mpv_set_option_string(h, n, v);
}

int mpv_set_property_string(void *h, const char *n, const char *v) {
  stall(set_delay_us);
  return real_mpv_set_property_string(h, n, v);
}

char *mpv_get_property_string(void *h, const char *n) {
  trace_get("mpv_get_property_string", n);
  count_get(n);
  stall(get_delay_us);
  return real_mpv_get_property_string(h, n);
}

int mpv_get_property(void *h, const char *n, int fmt, void *out) {
  trace_get("mpv_get_property", n);
  count_get(n);
  stall(get_delay_us);
  int rc = real_mpv_get_property(h, n, fmt, out);
  // MPV_FORMAT_FLAG is 3.
  if (rc >= 0 && fmt == 3 && atomic_load(&hide_eof) &&
      strcmp(n, "eof-reached") == 0) {
    *(int *)out = 0;
  }
  return rc;
}

int mpv_set_property(void *h, const char *n, int fmt, void *data) {
  stall(set_delay_us);
  return real_mpv_set_property(h, n, fmt, data);
}

int mpv_command(void *h, const char **args) {
  stall(set_delay_us);
  return real_mpv_command(h, args);
}

int mpv_command_string(void *h, const char *args) {
  stall(set_delay_us);
  return real_mpv_command_string(h, args);
}

struct shim_event {
  int event_id;
  int error;
  uint64_t reply_userdata;
  void *data;
};
struct shim_event_hook {
  const char *name;
  uint64_t id;
};

void *mpv_wait_event(void *h, double timeout) {
  struct shim_event *ev = real_mpv_wait_event(h, timeout);
  // MPV_EVENT_HOOK is 25: remember the id until it is continued.
  if (ev && ev->event_id == 25 && ev->data) {
    pthread_mutex_lock(&mu);
    if (n_pending_hooks < MAX_TRACKED) {
      pending_hooks[n_pending_hooks].h = h;
      pending_hooks[n_pending_hooks].id =
          ((struct shim_event_hook *)ev->data)->id;
      n_pending_hooks++;
    }
    pthread_mutex_unlock(&mu);
  }
  return ev;
}

int mpv_observe_property(void *h, uint64_t ud, const char *n, int fmt) {
  return real_mpv_observe_property(h, ud, n, fmt);
}

void mpv_free(void *p) { real_mpv_free(p); }
void mpv_free_node_contents(void *p) { real_mpv_free_node_contents(p); }
const char *mpv_error_string(int e) { return real_mpv_error_string(e); }

int mpv_request_log_messages(void *h, const char *level) {
  return real_mpv_request_log_messages(h, level);
}

int mpv_hook_add(void *h, uint64_t ud, const char *n, int priority) {
  atomic_fetch_add(&hook_adds_entered, 1);
  atomic_fetch_add(&hook_adds_inflight, 1);
  stall(atomic_load(&hook_add_delay_us));
  pthread_mutex_lock(&mu);
  int rc;
  if (is_destroyed(h)) {
    // The real call would read freed memory: count it instead.
    atomic_fetch_add(&late_hook_adds, 1);
    rc = -1;
  } else {
    rc = real_mpv_hook_add(h, ud, n, priority);
  }
  pthread_mutex_unlock(&mu);
  atomic_fetch_sub(&hook_adds_inflight, 1);
  return rc;
}

int mpv_hook_continue(void *h, uint64_t id) {
  pthread_mutex_lock(&mu);
  forget_hook(h, id);
  pthread_mutex_unlock(&mu);
  return real_mpv_hook_continue(h, id);
}

int mpv_set_property_async(void *h, uint64_t ud, const char *n, int fmt,
                           void *data) {
  return real_mpv_set_property_async(h, ud, n, fmt, data);
}

int mpv_get_property_async(void *h, uint64_t ud, const char *n, int fmt) {
  return real_mpv_get_property_async(h, ud, n, fmt);
}

int mpv_command_async(void *h, uint64_t ud, const char **args) {
  return real_mpv_command_async(h, ud, args);
}
