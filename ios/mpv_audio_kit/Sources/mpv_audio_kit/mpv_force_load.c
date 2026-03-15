/**
 * mpv_force_load.c
 *
 * Forces the linker to include all mpv symbols from libmpv.xcframework
 * when the library is linked statically and accessed via dart:ffi +
 * DynamicLibrary.process().
 *
 * WHY THIS IS NEEDED
 * ──────────────────
 * On iOS, libmpv is a static archive (.a). The linker removes any object
 * files that have no symbols referenced by native (Swift/ObjC) code — a
 * process called "dead code stripping". Since the Dart side calls mpv
 * through DynamicLibrary.process() (dlsym at runtime), the linker has no
 * static evidence that those symbols are needed, and strips them.
 *
 * Taking the address of mpv_create() in an __attribute__((used)) function
 * is the standard solution documented by Flutter for static FFI libraries:
 * https://docs.flutter.dev/platform-integration/ios/c-interop
 *
 * ALTERNATIVES CONSIDERED
 * ───────────────────────
 * • -force_load $(path)/libmpv.a  — path is xcframework-variant-dependent,
 *   fragile and hard to maintain in a podspec.
 * • -all_load                     — loads ALL archives, risks duplicate symbols.
 * • DynamicLibrary.executable()   — same issue; strips still apply.
 *
 * NOTE ON cfstr_get_cstr
 * ──────────────────────
 * In earlier builds this file also contained a stub for cfstr_get_cstr,
 * a helper defined in mpv's osdep/utils-mac.c that was not compiled for iOS
 * because mpv's meson.build only included it under the 'cocoa' feature.
 *
 * The ROOT-CAUSE fix is now in build_libmpv_ios.sh: a Python patch moves
 * osdep/utils-mac.c out of the cocoa-conditional block and compiles it
 * whenever host_machine.system() == 'darwin' OR 'ios'. After rebuilding
 * the xcframework the stub here is no longer needed; the symbol comes
 * directly from libmpv.a.
 */

// Forward-declare mpv's public entry point (no headers needed).
extern void *mpv_create(void);

// This function is never called at runtime. The compiler/linker cannot
// remove it because of __attribute__((used)), which in turn forces the
// entire libmpv.a archive (including all transitively referenced objects)
// to be included in the final executable.
__attribute__((used))
static void *_mpv_audio_kit_force_link_symbols(void) {
  return (void *)&mpv_create;
}
