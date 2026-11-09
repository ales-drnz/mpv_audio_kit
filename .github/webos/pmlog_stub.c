// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// libPmLogLib.so.3 for the headless run: webOS's system logger, whose real
// library pulls libpbnjson, yajl and an old libgmp the NDK does not have.
// The engine uses two of its functions; each message goes to stdout.
#include <stdarg.h>
#include <stdio.h>
#include <stddef.h>

typedef struct { int enabledLevel; int flags; } PmLogContextInfo;
typedef const PmLogContextInfo *PmLogContext;

static const PmLogContextInfo context = {6, 0};  // up to Info

PmLogContext PmLogGetContextInline(const char *name) {
  (void)name;
  return &context;
}

int _PmLogMsgKV(PmLogContext ctx, int level, unsigned int flags,
                const char *msgid, size_t kv_count, const char *keywords,
                const char *formats, const char *fmt, ...) {
  (void)ctx; (void)flags; (void)kv_count; (void)keywords; (void)formats;
  va_list ap;
  va_start(ap, fmt);
  printf("[pmlog %d %s] ", level, msgid ? msgid : "");
  vprintf(fmt, ap);
  printf("\n");
  fflush(stdout);
  va_end(ap);
  return 0;
}
