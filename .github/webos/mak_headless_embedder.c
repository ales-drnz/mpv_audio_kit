// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// mak_headless_embedder: runs a flutter-webos app without its window. It
// sits in the app's directory in place of the runner and drives the app's
// own engine (lib/libflutter_engine.so) through Flutter's embedder API,
// with the software renderer and no display: the app's AOT code
// (lib/libapp.so), its assets and its plugins' libraries are the ones the
// TV runs. Every platform message gets an empty answer, as on a TV without
// the plugin's native side. The Dart log goes to stdout; the program exits
// 0 once a line has "MAK_WEBOS_RESULT PASS", 1 on "MAK_WEBOS_RESULT FAIL"
// or after the timeout (argv[1], seconds, default 120).
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "embedder.h"

static FlutterEngine engine;
static volatile int result = -1;

static void on_log(const char *tag, const char *message, void *user_data) {
  (void)tag; (void)user_data;
  printf("%s\n", message);
  fflush(stdout);
  if (strstr(message, "MAK_WEBOS_RESULT PASS")) result = 0;
  else if (strstr(message, "MAK_WEBOS_RESULT FAIL")) result = 1;
}

static bool on_present(void *user_data, const void *allocation,
                       size_t row_bytes, size_t height) {
  (void)user_data; (void)allocation; (void)row_bytes; (void)height;
  return true;
}

static void on_platform_message(const FlutterPlatformMessage *message,
                                void *user_data) {
  (void)user_data;
  if (message->response_handle)
    FlutterEngineSendPlatformMessageResponse(engine, message->response_handle, NULL, 0);
}

int main(int argc, char **argv) {
  int timeout = argc > 1 ? atoi(argv[1]) : 120;
  char exe[PATH_MAX], dir[PATH_MAX], assets[PATH_MAX], icu[PATH_MAX], app[PATH_MAX];
  ssize_t n = readlink("/proc/self/exe", exe, sizeof exe - 1);
  if (n <= 0) { perror("readlink"); return 2; }
  exe[n] = 0;
  snprintf(dir, sizeof dir, "%s", dirname(exe));
  snprintf(assets, sizeof assets, "%s/data/flutter_assets", dir);
  snprintf(icu, sizeof icu, "%s/data/icudtl.dat", dir);
  snprintf(app, sizeof app, "%s/lib/libapp.so", dir);

  FlutterEngineAOTDataSource source = {
    .type = kFlutterEngineAOTDataSourceTypeElfPath,
    .elf_path = app,
  };
  FlutterEngineAOTData aot = NULL;
  if (FlutterEngineCreateAOTData(&source, &aot) != kSuccess) {
    fprintf(stderr, "MAK_WEBOS_RESULT FAIL no AOT data in %s\n", app);
    return 1;
  }

  FlutterRendererConfig renderer = {0};
  renderer.type = kSoftware;
  renderer.software.struct_size = sizeof(FlutterSoftwareRendererConfig);
  renderer.software.surface_present_callback = on_present;

  FlutterProjectArgs args = {0};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = assets;
  args.icu_data_path = icu;
  args.platform_message_callback = on_platform_message;
  args.aot_data = aot;
  args.log_message_callback = on_log;

  FlutterEngineResult r = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &renderer, &args, NULL, &engine);
  if (r != kSuccess) {
    fprintf(stderr, "MAK_WEBOS_RESULT FAIL FlutterEngineRun: %d\n", r);
    return 1;
  }
  FlutterWindowMetricsEvent metrics = {0};
  metrics.struct_size = sizeof(FlutterWindowMetricsEvent);
  metrics.width = 1280;
  metrics.height = 720;
  metrics.pixel_ratio = 1.0;
  FlutterEngineSendWindowMetricsEvent(engine, &metrics);

  struct timespec tick = {0, 100 * 1000 * 1000};
  for (int i = 0; i < timeout * 10 && result < 0; i++) nanosleep(&tick, NULL);
  if (result < 0) printf("MAK_WEBOS_RESULT FAIL no result in %d s\n", timeout);
  fflush(stdout);
  // The engine's threads may still hold libmpv: the process ends here.
  _exit(result == 0 ? 0 : 1);
}
