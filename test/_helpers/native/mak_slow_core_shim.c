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
static atomic_int freeze_park;       // flag reads of eof-reached, pause and
                                     // keep-open-parked return 1
static atomic_int pause_zero_once;   // the next flag read of pause returns 0,
                                     // and the keep-open-parked read after it
static atomic_int park_zero_pending; // that keep-open-parked read is due
static atomic_int pause_zero_reads;  // reads pause_zero_once answered
static atomic_int stall_park_read_us; // sleep after the next pause read of 1
static atomic_int park_reads_stalled; // reads stall_park_read_us held
static atomic_int destroy_delay_us;  // sleep before mpv_terminate_destroy
static atomic_int hook_adds_entered;
static atomic_int hook_adds_inflight;
static atomic_int inflight_at_destroy; // most hook_adds running at a destroy
static atomic_int late_hook_adds;      // hook_adds on an already freed handle
static atomic_int destroys;
static atomic_int destroys_done;           // destroys that returned
static atomic_int destroys_done_at_create; // destroys_done at the last create
static atomic_int hooks_pending_at_destroy;
static atomic_int watched_gets;
static char watched_get[64];

// Synchronous node reads of this property answer a node the client cannot
// decode (mak_shim_break_node_get): a byte array of SIZE_MAX bytes. Empty
// means none. The fake node never reaches the real mpv_free_node_contents.
static char broken_get[64];
static atomic_int broken_gets;
struct shim_byte_array {
  void *data;
  size_t size;
};
struct shim_node {
  union {
    void *ptr;
    int64_t i;
    double d;
  } u;
  int format;
};
static char broken_byte;
static struct shim_byte_array broken_ba = {&broken_byte, (size_t)-1};
static atomic_int replies_held;

// One reply held back in mpv_wait_event (mak_shim_hold_reply): the request
// it answers, matched by name, then by its reply id and event.
static char hold_name[64];
static int hold_us;
static int hold_state; // 0 off, 1 waiting for the request, 2 for its reply
static int hold_event; // the reply's event id: 3 get, 4 set, 5 command
static uint64_t hold_ud;

// One request deferred (mak_shim_defer_request): the async set or command
// naming defer_name, after defer_skip of them went through, is kept here
// instead of reaching mpv, and mpv_wait_event sends it as it was asked,
// with the same reply id, on its first call once it has handed the pump an
// event of type defer_after since the knob was set. The pump makes that
// call only after it sent the reads that event takes, so the reads land
// ahead of the reply. With defer_park the event is not enough: the pump
// must also have read the keep-open park after it (a synchronous
// `keep-open-parked` answering 1), which mpv can reach a few playloop
// turns after the restart of a seek to the end.
#define DEFER_MAX_ARGS 16
// A request kept off mpv: its kind (SET_REPLY or COMMAND_REPLY, as below),
// handle, reply id and arguments (a set: name, value), owned by the slot.
struct kept_request {
  int kind;
  void *handle;
  uint64_t ud;
  char *args[DEFER_MAX_ARGS + 1];
};
static char defer_name[64];
static int defer_after;
static int defer_skip;
static int defer_state; // 0 off, 1 waiting for the request, 2 for the event,
                        // 3 to be sent
static int defer_seen;  // the event went to the pump since the knob was set
static int defer_park;  // the pump must also read the park after the event
static int defer_ready; // what defer_park asks for has happened
static struct kept_request deferred;
static atomic_int deferred_sent;

// One request held (mak_shim_hold_request): the next async set or command
// naming hold_req_name is kept here, and sent just ahead of the next
// request of that name, which then goes on as it would have.
static char hold_req_name[64];
static int hold_req_state; // 0 off, 1 waiting for the request, 2 holding it
static struct kept_request held_request;
static atomic_int held_requests_sent;

// Async loadfile commands whose URL holds this text are refused
// (mak_shim_refuse_loadfile); empty means none.
static char refuse_marker[64];
static atomic_int loadfiles_refused;

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

// Moves the request in [slot] to [out], which then owns its arguments,
// and empties the slot. Called under the lock. A request whose handle was
// destroyed meanwhile is dropped: nobody waits for its reply.
static int take_request(struct kept_request *slot, struct kept_request *out) {
  *out = *slot;
  memset(slot, 0, sizeof *slot);
  if (!out->args[0]) return 0;
  if (is_destroyed(out->handle)) {
    for (int i = 0; out->args[i]; i++) free(out->args[i]);
    return 0;
  }
  return 1;
}

// Copies the request named by [args] into [slot]. Called under the lock.
static void keep_request(struct kept_request *slot, void *h, int kind,
                         uint64_t ud, const char **args) {
  int n = 0;
  while (args[n] && n < DEFER_MAX_ARGS) {
    slot->args[n] = strdup(args[n]);
    n++;
  }
  slot->args[n] = NULL;
  slot->kind = kind;
  slot->handle = h;
  slot->ud = ud;
}

// Sends a request taken off its slot to mpv as it was asked, with the same
// reply id, and frees it. Off the lock, which note_request takes: a held
// reply matches the request as any other.
static void send_request(struct kept_request *r);

void mak_shim_set(const char *knob, int value) {
  if (strcmp(knob, "hook_add_delay_us") == 0) {
    atomic_store(&hook_add_delay_us, value);
  } else if (strcmp(knob, "hide_eof") == 0) {
    atomic_store(&hide_eof, value);
  } else if (strcmp(knob, "freeze_park") == 0) {
    atomic_store(&freeze_park, value);
  } else if (strcmp(knob, "pause_zero_once") == 0) {
    atomic_store(&pause_zero_once, value);
  } else if (strcmp(knob, "stall_park_read_us") == 0) {
    atomic_store(&stall_park_read_us, value);
  } else if (strcmp(knob, "destroy_delay_us") == 0) {
    atomic_store(&destroy_delay_us, value);
  } else {
    fprintf(stderr, "mak_slow_core_shim: unknown knob %s\n", knob);
    abort();
  }
}

// The mpv-version the synchronous reads answer, in place of the real one
// (mak_shim_fake_version). Empty means the real one. Written into the
// string the real libmpv returned, so mpv_free frees it as usual: a fake
// longer than the real version is cut to its length.
static char fake_version[64];

static void apply_fake_version(const char *n, char *version) {
  pthread_mutex_lock(&mu);
  if (version && fake_version[0] && strcmp(n, "mpv-version") == 0) {
    size_t room = strlen(version);
    size_t len = strlen(fake_version);
    memcpy(version, fake_version, len < room ? len : room);
    version[len < room ? len : room] = 0;
  }
  pthread_mutex_unlock(&mu);
}

void mak_shim_fake_version(const char *version) {
  pthread_mutex_lock(&mu);
  snprintf(fake_version, sizeof fake_version, "%s", version);
  pthread_mutex_unlock(&mu);
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
  if (strcmp(name, "destroys_done_at_create") == 0) {
    return destroys_done_at_create;
  }
  if (strcmp(name, "hooks_pending_at_destroy") == 0) {
    return hooks_pending_at_destroy;
  }
  if (strcmp(name, "watched_gets") == 0) return watched_gets;
  if (strcmp(name, "pause_zero_reads") == 0) return pause_zero_reads;
  if (strcmp(name, "park_reads_stalled") == 0) return park_reads_stalled;
  if (strcmp(name, "broken_gets") == 0) return broken_gets;
  if (strcmp(name, "replies_held") == 0) return replies_held;
  if (strcmp(name, "loadfiles_refused") == 0) return loadfiles_refused;
  if (strcmp(name, "deferred_sent") == 0) return deferred_sent;
  if (strcmp(name, "held_requests_sent") == 0) return held_requests_sent;
  fprintf(stderr, "mak_slow_core_shim: unknown counter %s\n", name);
  abort();
}

// Zeroes the counters and the knobs; the stalls and the handles stay.
void mak_shim_reset(void) {
  pthread_mutex_lock(&mu);
  atomic_store(&hook_add_delay_us, 0);
  atomic_store(&hide_eof, 0);
  atomic_store(&freeze_park, 0);
  atomic_store(&pause_zero_once, 0);
  atomic_store(&park_zero_pending, 0);
  atomic_store(&pause_zero_reads, 0);
  atomic_store(&stall_park_read_us, 0);
  atomic_store(&park_reads_stalled, 0);
  atomic_store(&destroy_delay_us, 0);
  atomic_store(&hook_adds_entered, 0);
  atomic_store(&inflight_at_destroy, 0);
  atomic_store(&late_hook_adds, 0);
  atomic_store(&destroys, 0);
  atomic_store(&destroys_done, 0);
  atomic_store(&destroys_done_at_create, 0);
  atomic_store(&hooks_pending_at_destroy, 0);
  atomic_store(&watched_gets, 0);
  watched_get[0] = 0;
  fake_version[0] = 0;
  atomic_store(&broken_gets, 0);
  broken_get[0] = 0;
  atomic_store(&replies_held, 0);
  hold_state = 0;
  refuse_marker[0] = 0;
  atomic_store(&loadfiles_refused, 0);
  // A request still kept goes to mpv now: the call that made it waits for
  // its reply, and a player disposed after the reset waits for the call.
  struct kept_request still_deferred, still_held;
  int send_d = take_request(&deferred, &still_deferred);
  int send_h = take_request(&held_request, &still_held);
  defer_state = 0;
  hold_req_state = 0;
  hold_req_name[0] = 0;
  atomic_store(&deferred_sent, 0);
  atomic_store(&held_requests_sent, 0);
  pthread_mutex_unlock(&mu);
  if (send_d) send_request(&still_deferred);
  if (send_h) send_request(&still_held);
}

// From now on, synchronous MPV_FORMAT_NODE reads of [name] answer a byte
// array the client cannot decode, in place of the real value.
void mak_shim_break_node_get(const char *name) {
  pthread_mutex_lock(&mu);
  snprintf(broken_get, sizeof broken_get, "%s", name);
  pthread_mutex_unlock(&mu);
}

// Refuses every async `loadfile` whose URL holds [marker] before it reaches
// mpv, with the error a full reply queue gives (MPV_ERROR_EVENT_QUEUE_FULL,
// which mpv_command_async returns when the client has 1000 replies due).
void mak_shim_refuse_loadfile(const char *marker) {
  pthread_mutex_lock(&mu);
  snprintf(refuse_marker, sizeof refuse_marker, "%s", marker);
  pthread_mutex_unlock(&mu);
}

static int refused(const char **args) {
  if (!args[0] || strcmp(args[0], "loadfile") != 0 || !args[1]) return 0;
  pthread_mutex_lock(&mu);
  int hit = refuse_marker[0] && strstr(args[1], refuse_marker) != NULL;
  pthread_mutex_unlock(&mu);
  return hit;
}

// Holds the reply to the next async request naming [name] (a command's
// first argument, or the property of a get or a set) for [us] in
// mpv_wait_event, as a core that answers late: the request runs, only its
// reply waits, and every event behind it with it.
void mak_shim_hold_reply(const char *name, int us) {
  pthread_mutex_lock(&mu);
  snprintf(hold_name, sizeof hold_name, "%s", name);
  hold_us = us;
  hold_state = 1;
  pthread_mutex_unlock(&mu);
}

// Defers the async set or command naming [name] (a command's first
// argument, or the property of a set) that comes after [skip] of them: it
// reaches mpv only once mpv_wait_event has handed the pump an event of id
// [after_event], from this call on, and the pump asked for the next one.
// With [park], only once the pump has also read the keep-open park after
// that event. Counted in `deferred_sent` once sent.
// A request an earlier call still defers goes to mpv now, as at a reset.
void mak_shim_defer_request(const char *name, int after_event, int skip,
                            int park) {
  struct kept_request still;
  pthread_mutex_lock(&mu);
  int send = take_request(&deferred, &still);
  snprintf(defer_name, sizeof defer_name, "%s", name);
  defer_after = after_event;
  defer_skip = skip;
  defer_state = 1;
  defer_seen = 0;
  defer_park = park;
  defer_ready = 0;
  pthread_mutex_unlock(&mu);
  if (send) send_request(&still);
}

// Holds the next async set or command naming [name] (a command's first
// argument, or the property of a set) off mpv until the next request of
// that name comes: it is sent then, just ahead of that one, which goes on
// as it would have (a deferRequest still applies to it). Counted in
// `held_requests_sent` once sent. A request an earlier call still holds
// goes to mpv now, as at a reset.
void mak_shim_hold_request(const char *name) {
  struct kept_request still;
  pthread_mutex_lock(&mu);
  int send = take_request(&held_request, &still);
  snprintf(hold_req_name, sizeof hold_req_name, "%s", name);
  hold_req_state = 1;
  pthread_mutex_unlock(&mu);
  if (send) send_request(&still);
}

// Holds the request named by [args] when it is the one to hold, or sends
// the held one when [args] names it again. Returns whether it held it; the
// caller then reports it queued.
static int hold_request(void *h, int kind, uint64_t ud, const char **args) {
  if (!args[0]) return 0;
  struct kept_request release;
  int send = 0, kept = 0;
  pthread_mutex_lock(&mu);
  if (hold_req_state && strcmp(args[0], hold_req_name) == 0) {
    if (hold_req_state == 1) {
      keep_request(&held_request, h, kind, ud, args);
      hold_req_state = 2;
      kept = 1;
    } else {
      send = take_request(&held_request, &release);
      hold_req_state = 0;
    }
  }
  pthread_mutex_unlock(&mu);
  if (send) {
    send_request(&release);
    atomic_fetch_add(&held_requests_sent, 1);
  }
  return kept;
}

// Keeps the request named by [args] (NULL-terminated; for a set, the
// property and its string value) when it is the one to defer. Returns
// whether it did; the caller then reports it queued.
static int defer(void *h, int kind, uint64_t ud, const char **args) {
  int kept = 0;
  pthread_mutex_lock(&mu);
  if (defer_state == 1 && args[0] && strcmp(args[0], defer_name) == 0) {
    if (defer_skip > 0) {
      defer_skip--;
    } else {
      keep_request(&deferred, h, kind, ud, args);
      defer_state = defer_ready ? 3 : 2;
      kept = 1;
    }
  }
  int due = kept && defer_state == 3;
  pthread_mutex_unlock(&mu);
  // The pump may be waiting for an event: woken, it sends the request.
  if (due) real_mpv_wakeup(h);
  return kept;
}

// Called before the request is queued, so its reply cannot come first.
static void note_request(int event, uint64_t ud, const char *name) {
  pthread_mutex_lock(&mu);
  if (hold_state == 1 && name && strcmp(name, hold_name) == 0) {
    hold_event = event;
    hold_ud = ud;
    hold_state = 2;
  }
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
  atomic_store(&destroys_done_at_create, atomic_load(&destroys_done));
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
  // A request still kept for this handle goes to mpv before it is gone.
  struct kept_request still_deferred = {0}, still_held = {0};
  int send_d = 0, send_h = 0;
  if (deferred.args[0] && deferred.handle == h) {
    send_d = take_request(&deferred, &still_deferred);
    defer_state = 0;
  }
  if (held_request.args[0] && held_request.handle == h) {
    send_h = take_request(&held_request, &still_held);
    hold_req_state = 0;
  }
  pthread_mutex_unlock(&mu);
  if (send_d) send_request(&still_deferred);
  if (send_h) send_request(&still_held);
  pthread_mutex_lock(&mu);
  if (n_destroyed < MAX_TRACKED) destroyed[n_destroyed++] = h;
  atomic_fetch_add(&destroys, 1);
  pthread_mutex_unlock(&mu);
  // A destroy as slow as mp_destroy closing a busy audio output, or
  // joining a core that still serves requests.
  stall(atomic_load(&destroy_delay_us));
  real_mpv_terminate_destroy(h);
  atomic_fetch_add(&destroys_done, 1);
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
  char *value = real_mpv_get_property_string(h, n);
  apply_fake_version(n, value);
  return value;
}

int mpv_get_property(void *h, const char *n, int fmt, void *out) {
  trace_get("mpv_get_property", n);
  count_get(n);
  stall(get_delay_us);
  // MPV_FORMAT_NODE is 6, MPV_FORMAT_BYTE_ARRAY 9.
  pthread_mutex_lock(&mu);
  int broken = fmt == 6 && broken_get[0] && strcmp(n, broken_get) == 0;
  pthread_mutex_unlock(&mu);
  if (broken) {
    struct shim_node *node = out;
    node->u.ptr = &broken_ba;
    node->format = 9;
    atomic_fetch_add(&broken_gets, 1);
    return 0;
  }
  int rc = real_mpv_get_property(h, n, fmt, out);
  // MPV_FORMAT_STRING is 1.
  if (rc >= 0 && fmt == 1) apply_fake_version(n, *(char **)out);
  // MPV_FORMAT_FLAG is 3.
  if (rc >= 0 && fmt == 3 && atomic_load(&hide_eof) &&
      strcmp(n, "eof-reached") == 0) {
    *(int *)out = 0;
  }
  if (rc >= 0 && fmt == 3 && atomic_load(&freeze_park) &&
      (strcmp(n, "eof-reached") == 0 || strcmp(n, "pause") == 0 ||
       strcmp(n, "keep-open-parked") == 0)) {
    *(int *)out = 1;
  }
  if (rc >= 0 && fmt == 3 && strcmp(n, "pause") == 0 &&
      atomic_exchange(&pause_zero_once, 0)) {
    *(int *)out = 0;
    atomic_fetch_add(&pause_zero_reads, 1);
    // An unpause leaves the park: keep-open-parked reads 0 with it.
    atomic_store(&park_zero_pending, 1);
  }
  if (rc >= 0 && fmt == 3 && strcmp(n, "keep-open-parked") == 0 &&
      atomic_exchange(&park_zero_pending, 0)) {
    *(int *)out = 0;
  }
  // The read of a park, which the event isolate makes only at the end,
  // answers late: the read is done, the pump is not.
  if (rc >= 0 && fmt == 3 && strcmp(n, "pause") == 0 && *(int *)out == 1) {
    int us = atomic_exchange(&stall_park_read_us, 0);
    if (us > 0) {
      atomic_fetch_add(&park_reads_stalled, 1);
      stall(us);
    }
  }
  // The pump read the park after the event a deferred request waits for:
  // its next mpv_wait_event sends the request.
  if (rc >= 0 && fmt == 3 && strcmp(n, "keep-open-parked") == 0 &&
      *(int *)out == 1) {
    pthread_mutex_lock(&mu);
    if (defer_park && defer_seen && (defer_state == 1 || defer_state == 2)) {
      defer_ready = 1;
      if (defer_state == 2) defer_state = 3;
    }
    pthread_mutex_unlock(&mu);
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

// Sends the deferred request once its event went to the pump.
static void send_deferred(void);

void *mpv_wait_event(void *h, double timeout) {
  send_deferred();
  struct shim_event *ev = real_mpv_wait_event(h, timeout);
  if (ev) {
    pthread_mutex_lock(&mu);
    if ((defer_state == 1 || defer_state == 2) &&
        ev->event_id == defer_after) {
      defer_seen = 1;
      if (!defer_park) {
        defer_ready = 1;
        if (defer_state == 2) defer_state = 3;
      }
    }
    pthread_mutex_unlock(&mu);
  }
  if (ev) {
    int held = 0;
    pthread_mutex_lock(&mu);
    if (hold_state == 2 && ev->event_id == hold_event &&
        ev->reply_userdata == hold_ud) {
      hold_state = 0;
      held = hold_us;
    }
    pthread_mutex_unlock(&mu);
    if (held) {
      atomic_fetch_add(&replies_held, 1);
      stall(held);
    }
  }
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
void mpv_free_node_contents(void *p) {
  struct shim_node *node = p;
  if (node->format == 9 && node->u.ptr == &broken_ba) {
    node->format = 0;
    return;
  }
  real_mpv_free_node_contents(p);
}
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

// MPV_EVENT_GET_PROPERTY_REPLY, _SET_PROPERTY_REPLY and _COMMAND_REPLY.
#define GET_REPLY 3
#define SET_REPLY 4
#define COMMAND_REPLY 5

// MPV_FORMAT_STRING is 1: the format the client writes properties in.
#define FORMAT_STRING 1

int mpv_set_property_async(void *h, uint64_t ud, const char *n, int fmt,
                           void *data) {
  if (fmt == FORMAT_STRING) {
    const char *args[] = {n, *(const char **)data, NULL};
    if (hold_request(h, SET_REPLY, ud, args)) return 0;
    if (defer(h, SET_REPLY, ud, args)) return 0;
  }
  note_request(SET_REPLY, ud, n);
  return real_mpv_set_property_async(h, ud, n, fmt, data);
}

int mpv_get_property_async(void *h, uint64_t ud, const char *n, int fmt) {
  note_request(GET_REPLY, ud, n);
  return real_mpv_get_property_async(h, ud, n, fmt);
}

int mpv_command_async(void *h, uint64_t ud, const char **args) {
  if (refused(args)) {
    atomic_fetch_add(&loadfiles_refused, 1);
    return -1; // MPV_ERROR_EVENT_QUEUE_FULL
  }
  if (hold_request(h, COMMAND_REPLY, ud, args)) return 0;
  if (defer(h, COMMAND_REPLY, ud, args)) return 0;
  note_request(COMMAND_REPLY, ud, args[0]);
  return real_mpv_command_async(h, ud, args);
}

static void send_request(struct kept_request *r) {
  if (r->kind == SET_REPLY) {
    const char *value = r->args[1];
    note_request(SET_REPLY, r->ud, r->args[0]);
    real_mpv_set_property_async(r->handle, r->ud, r->args[0], FORMAT_STRING,
                                &value);
  } else {
    note_request(COMMAND_REPLY, r->ud, r->args[0]);
    real_mpv_command_async(r->handle, r->ud, (const char **)r->args);
  }
  for (int i = 0; r->args[i]; i++) free(r->args[i]);
}

// The request is taken off its slot under the lock: a reset or a new
// deferRequest on another thread finds the slot empty, and frees nothing
// this sends.
static void send_deferred(void) {
  struct kept_request r;
  pthread_mutex_lock(&mu);
  if (defer_state != 3) {
    pthread_mutex_unlock(&mu);
    return;
  }
  defer_state = 0;
  int send = take_request(&deferred, &r);
  pthread_mutex_unlock(&mu);
  if (!send) return;
  send_request(&r);
  atomic_fetch_add(&deferred_sent, 1);
}
