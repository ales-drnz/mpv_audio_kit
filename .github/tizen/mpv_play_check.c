// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// mpv_play_check <libmpv> <file>: plays <file> through ao_tizen with the
// libmpv the kit bundles on Tizen, run on the TV emulator with sdb shell
// (no package to install, so no certificate). Passes when playback-time
// goes past 2 s with current-ao tizen; prints MAK_TIZEN_NATIVE PASS or FAIL.
// The client API is taken with dlsym, so the check needs no mpv header.
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef void *(*create_fn)(void);
typedef int (*init_fn)(void *);
typedef int (*set_option_fn)(void *, const char *, const char *);
typedef int (*command_fn)(void *, const char **);
typedef char *(*get_string_fn)(void *, const char *);
typedef void (*free_fn)(void *);
typedef void (*destroy_fn)(void *);

int main(int argc, char **argv)
{
    if (argc < 3) {
        fprintf(stderr, "usage: %s <libmpv> <file>\n", argv[0]);
        return 2;
    }
    void *lib = dlopen(argv[1], RTLD_NOW);
    if (!lib) {
        printf("MAK_TIZEN_NATIVE FAIL dlopen: %s\n", dlerror());
        return 1;
    }
    create_fn create = (create_fn)dlsym(lib, "mpv_create");
    init_fn initialize = (init_fn)dlsym(lib, "mpv_initialize");
    set_option_fn set_option = (set_option_fn)dlsym(lib, "mpv_set_option_string");
    command_fn command = (command_fn)dlsym(lib, "mpv_command");
    get_string_fn get = (get_string_fn)dlsym(lib, "mpv_get_property_string");
    free_fn mpv_free = (free_fn)dlsym(lib, "mpv_free");
    destroy_fn destroy = (destroy_fn)dlsym(lib, "mpv_terminate_destroy");
    if (!create || !initialize || !set_option || !command || !get || !mpv_free || !destroy) {
        printf("MAK_TIZEN_NATIVE FAIL missing client API symbols\n");
        return 1;
    }
    void *mpv = create();
    set_option(mpv, "config", "no");
    set_option(mpv, "terminal", "yes");
    set_option(mpv, "msg-level", "all=warn,ao=v");
    set_option(mpv, "video", "no");
    set_option(mpv, "ao", "tizen");
    if (initialize(mpv) < 0) {
        printf("MAK_TIZEN_NATIVE FAIL mpv_initialize\n");
        return 1;
    }
    const char *load[] = {"loadfile", argv[2], NULL};
    command(mpv, load);

    double t = 0;
    char *ao = NULL, *params = NULL;
    for (int i = 0; i < 150 && t <= 2.0; i++) {
        usleep(200 * 1000);
        char *s = get(mpv, "playback-time");
        if (s) {
            t = atof(s);
            mpv_free(s);
        }
    }
    ao = get(mpv, "current-ao");
    params = get(mpv, "audio-out-params");
    int ok = t > 2.0 && ao && !strcmp(ao, "tizen");
    printf("MAK_TIZEN_NATIVE %s playback-time=%.2f current-ao=%s audio-out-params=%s\n",
           ok ? "PASS" : "FAIL", t, ao ? ao : "-", params ? params : "-");
    fflush(stdout);
    if (ao)
        mpv_free(ao);
    if (params)
        mpv_free(params);
    destroy(mpv);
    return ok ? 0 : 1;
}
