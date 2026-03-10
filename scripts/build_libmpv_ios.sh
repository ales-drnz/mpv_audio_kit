#!/usr/bin/env bash
# =============================================================================
# build_libmpv_ios.sh
#
# Compiles mpv 0.41.0 as a STATIC library for iOS.
# Output: ios/Frameworks/libmpv.xcframework  (device arm64 + simulator arm64/x86_64)
#
# Usage (from project root):
#   chmod +x scripts/build_libmpv_ios.sh
#   ./scripts/build_libmpv_ios.sh
#
# Options (environment variables):
#   MPV_VERSION=0.41.0    (default: 0.41.0)
#   JOBS=N                (default: number of cores)
#   SKIP_DOWNLOAD=1       (skips download if sources already exist)
#   KEEP_BUILD=1          (does not delete BUILD_DIR)
#
# Note: iOS does not allow third-party dylibs → everything is static .a
#       Same dependency versions as build_libmpv_macos.sh.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
OUTPUT_DIR="$ROOT/ios/Frameworks"

MPV_VERSION="${MPV_VERSION:-0.41.0}"
JOBS="${JOBS:-$(sysctl -n hw.logicalcpu)}"

# Dependency versions (same as macOS script)
FFMPEG_VERSION="7.1.1"
LIBASS_VERSION="0.17.3"
FRIBIDI_VERSION="1.0.16"
FREETYPE_VERSION="2.13.3"
HARFBUZZ_VERSION="10.4.0"
FONTCONFIG_VERSION="2.15.0"
LIBEXPAT_VERSION="2.7.1"
LIBPNG_VERSION="1.6.47"
ZLIB_VERSION="1.3.1"
BZIP2_VERSION="1.0.8"
XZ_VERSION="5.6.4"
RUBBERBAND_VERSION="3.3.0"
UCHARDET_VERSION="0.0.8"
LCMS2_VERSION="2.17"
LIBARCHIVE_VERSION="3.7.7"
MUJS_VERSION="1.3.6"
LUAJIT_COMMIT="v2.1"
ZIMG_VERSION="3.0.5"
SPEEX_DSP_VERSION="1.2.1"
LIBPLACEBO_VERSION="6.338.2"

BUILD_DIR="${BUILD_DIR:-$ROOT/build-ios}"
PREFIX_BASE="$BUILD_DIR/prefix"

# Slices to build: device (arm64) + simulator (arm64 + x86_64)
SLICES=("iphoneos:arm64" "iphonesimulator:arm64" "iphonesimulator:x86_64")
IOS_MIN="13.0"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $*${NC}" >&2; }
ok()   { echo -e "${GREEN}✓ $*${NC}" >&2; }
warn() { echo -e "${YELLOW}⚠ $*${NC}" >&2; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

# ── Check requirements ────────────────────────────────────────────────────────
check_tools() {
  log "Checking tools..."
  local missing=()
  for t in meson ninja nasm cmake pkg-config python3 autoconf automake libtool git xcodebuild; do
    command -v "$t" &>/dev/null || missing+=("$t")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    command -v brew &>/dev/null || fail "Homebrew required to install: ${missing[*]}"
    brew install "${missing[@]}" 2>/dev/null || true
  fi
  ok "Tools OK"
}

# ── Download helpers ─────────────────────────────────────────────────────────
download() {
  local url="$1" dest="$2"
  [[ "${SKIP_DOWNLOAD:-0}" == "1" && -f "$dest" ]] && { ok "Skip: $(basename "$dest")"; return; }
  log "Download: $(basename "$dest")"
  curl -fsSL --retry 3 -o "$dest" "$url" || fail "Download failed: $url"
}

download_git() {
  local url="$1" dest="$2" tag="${3:-}"
  [[ "${SKIP_DOWNLOAD:-0}" == "1" && -d "$dest/.git" ]] && { ok "Skip git: $(basename "$dest")"; return; }
  log "Git clone: $(basename "$dest")"
  if [[ -n "$tag" ]]; then
    git clone --depth=1 --branch "$tag" "$url" "$dest" 2>/dev/null \
      || { rm -rf "$dest"; git clone --depth=1 "$url" "$dest"; }
  else
    git clone --depth=1 "$url" "$dest"
  fi
}

extract() {
  local archive="$1" dest_parent="$2"
  local name; name="$(basename "$archive" | sed 's/\.tar\..*//' | sed 's/\.tgz//')"
  [[ -d "$dest_parent/$name" ]] && { echo "$dest_parent/$name"; return; }
  log "Extracting: $name"
  tar -xf "$archive" -C "$dest_parent"
  echo "$dest_parent/$name"
}

# ── SDK helpers ──────────────────────────────────────────────────────────────
sdk_path() { xcrun --sdk "$1" --show-sdk-path; }

cflags_for() {
  local sdk="$1" arch="$2"
  local sysroot; sysroot="$(sdk_path "$sdk")"
  if [[ "$sdk" == "iphoneos" ]]; then
    echo "-arch $arch -miphoneos-version-min=$IOS_MIN -isysroot $sysroot"
  else
    echo "-arch $arch -mios-simulator-version-min=$IOS_MIN -isysroot $sysroot"
  fi
}

# ── Cross-file meson per iOS ─────────────────────────────────────────────────
write_ios_cross() {
  local sdk="$1" arch="$2"
  local sysroot; sysroot="$(sdk_path "$sdk")"
  local file="$BUILD_DIR/meson_cross_${sdk}_${arch}.ini"
  local min_flag
  if [[ "$sdk" == "iphoneos" ]]; then
    min_flag="-miphoneos-version-min=$IOS_MIN"
  else
    min_flag="-mios-simulator-version-min=$IOS_MIN"
  fi
  local cpu_family="aarch64"
  [[ "$arch" == "x86_64" ]] && cpu_family="x86_64"
  cat > "$file" << EOF
[binaries]
c = 'clang'
cpp = 'clang++'
objc = 'clang'
objcpp = 'clang++'
ar = 'ar'
strip = 'strip'
pkg-config = 'pkg-config'

[built-in options]
c_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']
cpp_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']
objc_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']
objcpp_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']
c_link_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']
cpp_link_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']
objc_link_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']
objcpp_link_args = ['-arch', '$arch', '$min_flag', '-isysroot', '$sysroot']

[host_machine]
system = 'ios'
cpu_family = '${cpu_family/x86_64/x86}'
cpu = '$arch'
endian = 'little'

[build_machine]
system = 'darwin'
cpu_family = 'aarch64'
cpu = 'arm64'
endian = 'little'
EOF
  echo "$file"
}

# ── Native-file meson (build machine compilers) ─────────────────────────────
write_native_file() {
  local file="$BUILD_DIR/meson_native.ini"
  [[ -f "$file" ]] && { echo "$file"; return; }
  cat > "$file" << 'EOF'
[binaries]
c = 'clang'
cpp = 'clang++'
objc = 'clang'
objcpp = 'clang++'
ar = 'ar'
strip = 'strip'
pkg-config = 'pkg-config'
EOF
  echo "$file"
}

# ── meson_setup wrapper (unsets SDKROOT so native sanity check passes) ───────
meson_setup() {
  # SDKROOT pointing at the iOS SDK causes meson's build-machine sanity check
  # to fail (dyld thinks the native binary is a simulator program).
  # The cross-file already carries -isysroot, so SDKROOT is not needed here.
  (
    unset SDKROOT
    meson setup "$@"
  )
}

# =============================================================================
# Build per una singola slice (sdk:arch)
# =============================================================================
build_slice() {
  local sdk="$1" arch="$2"
  local prefix="$PREFIX_BASE/${sdk}_${arch}"
  mkdir -p "$prefix"
  export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"
  export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig"

  mkdir -p "$prefix/lib/pkgconfig"
  cat > "$prefix/lib/pkgconfig/iconv.pc" << EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: iconv
Description: Character encoding conversion library
Version: 1.11
Libs: -liconv
Cflags: -I\${includedir}
EOF

  local cf; cf="$(cflags_for "$sdk" "$arch")"
  export CFLAGS="$cf -O2"
  export CXXFLAGS="$cf -O2"
  export LDFLAGS="$cf"
  export CC="clang"
  export CXX="clang++"

  local sysroot; sysroot="$(sdk_path "$sdk")"
  # Note: Do NOT export SDKROOT here.  The -isysroot flag in CFLAGS / cross-file
  # is sufficient for cross-compilation, and exporting SDKROOT causes dyld to
  # reject native (build-machine) binaries during meson/ninja code-generation.

  log "═══ Slice: $sdk / $arch ═══"

  # Ordine: base → font → audio → core
  slice_zlib       "$sdk" "$arch" "$prefix" "$cf"
  slice_bzip2      "$sdk" "$arch" "$prefix" "$cf"
  slice_xz         "$sdk" "$arch" "$prefix" "$cf"
  slice_expat      "$sdk" "$arch" "$prefix" "$cf"
  slice_libpng     "$sdk" "$arch" "$prefix" "$cf"
  slice_freetype   "$sdk" "$arch" "$prefix" "$cf"
  slice_fribidi    "$sdk" "$arch" "$prefix" "$cf"
  slice_harfbuzz   "$sdk" "$arch" "$prefix" "$cf"
  slice_freetype2  "$sdk" "$arch" "$prefix" "$cf"
  slice_fontconfig "$sdk" "$arch" "$prefix" "$cf"
  slice_libass     "$sdk" "$arch" "$prefix" "$cf"
  slice_speexdsp   "$sdk" "$arch" "$prefix" "$cf"
  slice_rubberband "$sdk" "$arch" "$prefix" "$cf"
  slice_uchardet   "$sdk" "$arch" "$prefix" "$cf"
  slice_libarchive "$sdk" "$arch" "$prefix" "$cf"
  slice_mujs       "$sdk" "$arch" "$prefix" "$cf"
#  slice_luajit     "$sdk" "$arch" "$prefix" "$cf"
  slice_ffmpeg     "$sdk" "$arch" "$prefix" "$cf" "$sysroot"
  slice_mpv        "$sdk" "$arch" "$prefix" "$cf"
}

# ── Macro helper: cmake statico ──────────────────────────────────────────────
cmake_static() {
  local sdk="$1" arch="$2" prefix="$3" srcdir="$4"; shift 4
  local bdir="$BUILD_DIR/build/$(basename "$srcdir")-${sdk}-${arch}"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$srcdir" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_SYSROOT="$(sdk_path "$sdk")" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN" \
    -DCMAKE_SYSTEM_NAME="iOS" \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    "$@" \
    -GNinja
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null
}

# ── Singole librerie (pattern: check sentinel → build) ───────────────────────

slice_zlib() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libz.a" ]] && return
  log "zlib ($sdk/$arch)..."
  local src="$BUILD_DIR/src/zlib-$ZLIB_VERSION.tar.gz"
  download "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  CFLAGS="$cf -O2" ./configure --prefix="$prefix" --static
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "zlib ($sdk/$arch) ✓"
}

slice_bzip2() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libbz2.a" ]] && return
  log "bzip2 ($sdk/$arch)..."
  local src="$BUILD_DIR/src/bzip2-$BZIP2_VERSION.tar.gz"
  download "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make clean 2>/dev/null || true
  make -j"$JOBS" CC="clang" CFLAGS="$cf -O2 -D_FILE_OFFSET_BITS=64" AR="ar" RANLIB="ranlib" libbz2.a
  install -m 644 libbz2.a "$prefix/lib/"
  install -m 644 bzlib.h  "$prefix/include/"
  popd >/dev/null
  ok "bzip2 ($sdk/$arch) ✓"
}

slice_xz() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/liblzma.a" ]] && return
  log "xz ($sdk/$arch)..."
  local src="$BUILD_DIR/src/xz-$XZ_VERSION.tar.gz"
  download "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  CFLAGS="$cf -O2" ./configure --prefix="$prefix" --host="$host" --enable-static --disable-shared \
    --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-scripts --disable-doc
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "xz ($sdk/$arch) ✓"
}

slice_expat() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libexpat.a" ]] && return
  log "expat ($sdk/$arch)..."
  local src="$BUILD_DIR/src/expat-$LIBEXPAT_VERSION.tar.gz"
  download "https://github.com/libexpat/libexpat/releases/download/R_$(echo "$LIBEXPAT_VERSION" | tr . _)/expat-${LIBEXPAT_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  CFLAGS="$cf -O2" ./configure --prefix="$prefix" --host="$host" --enable-static --disable-shared --without-docbook --without-examples --without-tests
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "expat ($sdk/$arch) ✓"
}

slice_libpng() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libpng.a" ]] && return
  log "libpng ($sdk/$arch)..."
  local src="$BUILD_DIR/src/libpng-$LIBPNG_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  CFLAGS="$cf -O2" LDFLAGS="$cf" ./configure --prefix="$prefix" --host="$host" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libpng ($sdk/$arch) ✓"
}

slice_freetype() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libfreetype.a" ]] && return 0
  log "freetype r1 ($sdk/$arch)..."
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE_VERSION}/freetype-${FREETYPE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  cmake_static "$sdk" "$arch" "$prefix" "$dir" \
    -DFT_DISABLE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON \
    -DFT_REQUIRE_PNG=ON \
    -DZLIB_LIBRARY="$prefix/lib/libz.a" \
    -DZLIB_INCLUDE_DIR="$prefix/include" \
    -DPNG_LIBRARY="$prefix/lib/libpng.a" \
    -DPNG_PNG_INCLUDE_DIR="$prefix/include" \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW
  ok "freetype r1 ($sdk/$arch) ✓"
}

slice_fribidi() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libfribidi.a" ]] && return
  log "fribidi ($sdk/$arch)..."
  local src="$BUILD_DIR/src/fribidi-$FRIBIDI_VERSION.tar.gz"
  download "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fribidi-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson_setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Ddocs=false -Dtests=false \
    --cross-file="$(write_ios_cross "$sdk" "$arch")" \
    --native-file="$(write_native_file)"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "fribidi ($sdk/$arch) ✓"
}

slice_harfbuzz() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libharfbuzz.a" ]] && return
  log "harfbuzz ($sdk/$arch)..."
  local src="$BUILD_DIR/src/harfbuzz-$HARFBUZZ_VERSION.tar.gz"
  download "https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VERSION}/harfbuzz-${HARFBUZZ_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/harfbuzz-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson_setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dfreetype=enabled -Dglib=disabled -Dgobject=disabled -Dicu=disabled \
    -Dtests=disabled -Ddocs=disabled \
    --cross-file="$(write_ios_cross "$sdk" "$arch")" \
    --native-file="$(write_native_file)"
  ninja -j"$JOBS"; ninja install
  mkdir -p "$prefix/lib/cmake/harfbuzz"
  cat > "$prefix/lib/cmake/harfbuzz/harfbuzz-config-version.cmake" << EOF
set(PACKAGE_VERSION "10.4.0")
if (PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
  set(PACKAGE_VERSION_COMPATIBLE FALSE)
else ()
  set(PACKAGE_VERSION_COMPATIBLE TRUE)
  if (PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)
    set(PACKAGE_VERSION_EXACT TRUE)
  endif ()
endif ()
EOF
  popd >/dev/null
  ok "harfbuzz ($sdk/$arch) ✓"
}

slice_freetype2() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  local sentinel="$prefix/.ft_round2_${sdk}_${arch}"
  [[ -f "$sentinel" ]] && return 0

  # Ensure harfbuzz-config-version.cmake exists
  mkdir -p "$prefix/lib/cmake/harfbuzz"
  if [[ ! -f "$prefix/lib/cmake/harfbuzz/harfbuzz-config-version.cmake" ]]; then
    cat > "$prefix/lib/cmake/harfbuzz/harfbuzz-config-version.cmake" << EOF
set(PACKAGE_VERSION "10.4.0")
if (PACKAGE_VERSION VERSION_LESS PACKAGE_FIND_VERSION)
  set(PACKAGE_VERSION_COMPATIBLE FALSE)
else ()
  set(PACKAGE_VERSION_COMPATIBLE TRUE)
  if (PACKAGE_VERSION VERSION_EQUAL PACKAGE_FIND_VERSION)
    set(PACKAGE_VERSION_EXACT TRUE)
  endif ()
endif ()
EOF
  fi

  log "freetype r2 ($sdk/$arch)..."
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  rm -rf "$BUILD_DIR/build/freetype-${sdk}-${arch}"
  local bdir="$BUILD_DIR/build/freetype-r2-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_SYSROOT="$(sdk_path "$sdk")" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN" \
    -DCMAKE_SYSTEM_NAME="iOS" \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_HARFBUZZ=OFF -DFT_REQUIRE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON \
    -DZLIB_LIBRARY="$prefix/lib/libz.a" -DZLIB_INCLUDE_DIR="$prefix/include" \
    -DPNG_LIBRARY="$prefix/lib/libpng.a" -DPNG_PNG_INCLUDE_DIR="$prefix/include" \
    -DHarfBuzz_INCLUDE_DIR="$prefix/include/harfbuzz" \
    -DHarfBuzz_LIBRARY="$prefix/lib/libharfbuzz.a" \
    -DHarfBuzz_FOUND=ON \
    -DHarfBuzz_VERSION="10.4.0" \
    -DPC_HarfBuzz_VERSION="10.4.0" \
    -DPC_HarfBuzz_FOUND=1 \
    -DCMAKE_PREFIX_PATH="$prefix" -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -GNinja
  ninja -j"$JOBS"; ninja install
  touch "$sentinel"
  popd >/dev/null
  ok "freetype r2 ($sdk/$arch) ✓"
}

slice_fontconfig() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libfontconfig.a" ]] && return
  log "fontconfig ($sdk/$arch)..."
  local src="$BUILD_DIR/src/fontconfig-$FONTCONFIG_VERSION.tar.xz"
  download "https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fontconfig-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson_setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dtests=disabled -Dtools=disabled -Ddoc=disabled \
    --cross-file="$(write_ios_cross "$sdk" "$arch")" \
    --native-file="$(write_native_file)"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "fontconfig ($sdk/$arch) ✓"
}

slice_libass() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libass.a" ]] && return
  log "libass ($sdk/$arch)..."
  local src="$BUILD_DIR/src/libass-$LIBASS_VERSION.tar.gz"
  download "https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  CFLAGS="$cf -O2" LDFLAGS="$cf -L$prefix/lib" PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  ./configure --prefix="$prefix" --host="$host" --enable-static --disable-shared \
    --disable-require-system-font-provider --with-pic --enable-asm
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libass ($sdk/$arch) ✓"
}

slice_speexdsp() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libspeexdsp.a" ]] && return
  log "speexdsp ($sdk/$arch)..."
  local src="$BUILD_DIR/src/speexdsp-$SPEEX_DSP_VERSION.tar.gz"
  download "https://downloads.xiph.org/releases/speex/speexdsp-${SPEEX_DSP_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  CFLAGS="$cf -O2" ./configure --prefix="$prefix" --host="$host" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "speexdsp ($sdk/$arch) ✓"
}

slice_rubberband() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/librubberband.a" ]] && return
  log "rubberband ($sdk/$arch)..."
  local src="$BUILD_DIR/src/rubberband-$RUBBERBAND_VERSION.tar.bz2"
  download "https://breakfastquay.com/files/releases/rubberband-${RUBBERBAND_VERSION}.tar.bz2" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/rubberband-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson_setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dfft=builtin -Dresampler=speex \
    -Dladspa=disabled -Dvamp=disabled -Djni=disabled \
    --cross-file="$(write_ios_cross "$sdk" "$arch")" \
    --native-file="$(write_native_file)"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "rubberband ($sdk/$arch) ✓"
}

slice_uchardet() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libuchardet.a" ]] && return
  log "uchardet ($sdk/$arch)..."
  local src="$BUILD_DIR/src/uchardet-$UCHARDET_VERSION.tar.gz"
  download "https://www.freedesktop.org/software/uchardet/releases/uchardet-${UCHARDET_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  cmake_static "$sdk" "$arch" "$prefix" "$dir" \
    -DBUILD_STATIC=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_BINARY=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  ok "uchardet ($sdk/$arch) ✓"
}

slice_lcms2() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/liblcms2.a" ]] && return
  log "lcms2 ($sdk/$arch)..."
  local src="$BUILD_DIR/src/lcms2-$LCMS2_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/lcms/lcms/${LCMS2_VERSION}/lcms2-${LCMS2_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  CFLAGS="$cf -O2" ./configure --prefix="$prefix" --host="$host" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "lcms2 ($sdk/$arch) ✓"
}

slice_libarchive() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libarchive.a" ]] && return
  log "libarchive ($sdk/$arch)..."
  local src="$BUILD_DIR/src/libarchive-$LIBARCHIVE_VERSION.tar.gz"
  download "https://github.com/libarchive/libarchive/releases/download/v${LIBARCHIVE_VERSION}/libarchive-${LIBARCHIVE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  CFLAGS="$cf -O2 -I$prefix/include" LDFLAGS="$cf -L$prefix/lib" ./configure --prefix="$prefix" --host="$host" \
    --enable-static --disable-shared \
    --with-zlib --with-bz2lib --with-liblzma \
    --without-nettle --without-openssl --without-xml2 --without-expat \
    --disable-bsdtar --disable-bsdcpio --disable-bsdcat --disable-bsdunzip
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libarchive ($sdk/$arch) ✓"
}

slice_mujs() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libmujs.a" ]] && return
  log "mujs ($sdk/$arch)..."
  local gitdir="$BUILD_DIR/src/mujs-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://github.com/ccxvii/mujs.git" "$gitdir" "$MUJS_VERSION"
  pushd "$gitdir" >/dev/null
  make clean 2>/dev/null || true
  make -j"$JOBS" CC="clang" CFLAGS="$cf -O2" AR="ar" RANLIB="ranlib" \
    prefix="$prefix" HAVE_READLINE=no release
  make prefix="$prefix" HAVE_READLINE=no install-static
  popd >/dev/null
  ok "mujs ($sdk/$arch) ✓"
}

slice_luajit() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libluajit-5.1.a" ]] && return
  log "luajit ($sdk/$arch)..."
  local gitdir="$BUILD_DIR/src/luajit-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://github.com/LuaJIT/LuaJIT.git" "$gitdir" "$LUAJIT_COMMIT"
  pushd "$gitdir" >/dev/null
  make clean 2>/dev/null || true
  local sysroot; sysroot="$(sdk_path "$sdk")"
  local min_flag
  [[ "$sdk" == "iphoneos" ]] && min_flag="-miphoneos-version-min=$IOS_MIN" \
                              || min_flag="-mios-simulator-version-min=$IOS_MIN"
  # Serially build host tools first to allow signing
  make -C src host/minilua CC="clang" HOST_CC="clang" TARGET_SYS=iOS \
    CFLAGS="-arch $arch $min_flag -isysroot $sysroot -DLUAJIT_ENABLE_GC64"
  codesign -s - src/host/minilua 2>/dev/null || true
  
  make -j"$JOBS" \
    CC="clang" HOST_CC="clang" \
    TARGET_SYS=iOS \
    TARGET_FLAGS="-arch $arch $min_flag -isysroot $sysroot" \
    CFLAGS="-arch $arch $min_flag -isysroot $sysroot -DLUAJIT_ENABLE_GC64" \
    LDFLAGS="-arch $arch $min_flag -isysroot $sysroot" \
    PREFIX="$prefix" \
    install
  popd >/dev/null
  ok "luajit ($sdk/$arch) ✓"
}

slice_zimg() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libzimg.a" ]] && return
  log "zimg ($sdk/$arch)..."
  local src="$BUILD_DIR/src/zimg-$ZIMG_VERSION.tar.gz"
  download "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-${ZIMG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  # zimg might extract to a directory with a different name (e.g. zimg-release-3.0.5)
  if [[ ! -d "$dir" ]]; then
    dir="$(ls -d "$BUILD_DIR/src/zimg-"* 2>/dev/null | grep -v "\.tar" | tail -1)"
  fi
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || make clean 2>/dev/null || true
  local host="aarch64-apple-darwin"
  [[ "$arch" == "x86_64" ]] && host="x86_64-apple-darwin"

  [[ ! -f configure ]] && autoreconf -fiv
  CFLAGS="$cf -O2" CXXFLAGS="$cf -O2" \
  ./configure --prefix="$prefix" --host="$host" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "zimg ($sdk/$arch) ✓"
}

slice_libplacebo() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libplacebo.a" ]] && return 0
  log "libplacebo ($sdk/$arch)..."
  local gitdir="$BUILD_DIR/src/libplacebo-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://code.videolan.org/videolan/libplacebo.git" "$gitdir" "v$LIBPLACEBO_VERSION"
  git -C "$gitdir" submodule update --init --recursive
  local bdir="$BUILD_DIR/build/libplacebo-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  meson_setup "$gitdir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dvulkan=disabled -Dshaderc=disabled -Dglslang=disabled -Dopengl=disabled \
    -Dd3d11=disabled -Ddemos=false -Dtests=false \
    --cross-file="$(write_ios_cross "$sdk" "$arch")" \
    --native-file="$(write_native_file)"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "libplacebo ($sdk/$arch) ✓"
}

slice_ffmpeg() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4" sysroot="$5"
  [[ -f "$prefix/lib/libavcodec.a" ]] && return
  log "ffmpeg ($sdk/$arch)..."
  local src="$BUILD_DIR/src/ffmpeg-$FFMPEG_VERSION.tar.gz"
  download "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/ffmpeg-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null

  local min_flag target_os
  if [[ "$sdk" == "iphoneos" ]]; then
    min_flag="-miphoneos-version-min=$IOS_MIN"
    target_os="ios"
  else
    min_flag="-mios-simulator-version-min=$IOS_MIN"
    target_os="ios_simulator"
  fi

  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  "$dir/configure" \
    --prefix="$prefix" \
    --enable-static --disable-shared \
    --disable-programs --disable-doc --disable-debug \
    --enable-cross-compile \
    --arch="$arch" \
    --target-os=darwin \
    --cc="clang" --cxx="clang++" \
    --extra-cflags="-arch $arch $min_flag -isysroot $sysroot -O2" \
    --extra-ldflags="-arch $arch $min_flag -isysroot $sysroot" \
    --enable-avcodec --enable-avfilter --enable-avformat \
    --enable-avutil --enable-avdevice --enable-swresample --enable-swscale \
    --enable-protocols --enable-demuxers --enable-decoders --enable-filters \
    --disable-outdevs \
    --enable-libfreetype --enable-libass \
    --enable-zlib --enable-bzlib --enable-lzma --enable-iconv \
    --enable-network --enable-securetransport --disable-openssl \
    --disable-videotoolbox \
    --disable-vaapi --disable-vdpau \
    --disable-sdl2 --disable-xlib --disable-libdrm
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "ffmpeg ($sdk/$arch) ✓"
}

slice_mpv() {
  local sdk="$1" arch="$2" prefix="$3" cf="$4"
  [[ -f "$prefix/lib/libmpv.a" ]] && return
  log "mpv $MPV_VERSION ($sdk/$arch) [static]..."
  local src="$BUILD_DIR/src/mpv-$MPV_VERSION.tar.gz"
  download "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  # Patch meson.build and TOOLS for iOS
  # Patch meson.build and TOOLS for iOS
  grep -q "host_machine.system() == 'ios'" "$dir/meson.build" || \
    sed -i '' "s/host_machine.system() == 'darwin'/host_machine.system() == 'darwin' or host_machine.system() == 'ios'/g" "$dir/meson.build"
  
  grep -q "'$sdk'" "$dir/TOOLS/macos-sdk-version.py" || \
    sed -i '' "s/'macosx'/'$sdk'/g" "$dir/TOOLS/macos-sdk-version.py"

  # Patch ao_avfoundation for iOS (guard macOS-only property)
  grep -q "\/\/\[p->renderer setAudioOutputDeviceUniqueID:" "$dir/audio/out/ao_avfoundation.m" || \
    sed -i '' 's/\[p->renderer setAudioOutputDeviceUniqueID:/\/\/\[p->renderer setAudioOutputDeviceUniqueID:/g' "$dir/audio/out/ao_avfoundation.m"

  # Patch meson.build to remove ao_coreaudio_properties.c on iOS (it's macOS only HAL stuff)
  sed -i '' "s/sources += files('audio\/out\/ao_coreaudio_properties.c')/# sources += files('audio\/out\/ao_coreaudio_properties.c')/g" "$dir/meson.build"

  # Patch ao.h for iOS missing types (central hack for Darwin audio components)
  grep -q "TARGET_OS_IPHONE" "$dir/audio/out/ao.h" || \
    sed -i '' '/#define MPLAYER_AUDIO_OUT_H/a \
#include <TargetConditionals.h>\
#if TARGET_OS_IPHONE\
#include <stdint.h>\
typedef uint32_t AudioObjectID;\
typedef uint32_t AudioDeviceID;\
typedef uint32_t AudioStreamID;\
typedef uint32_t AudioObjectPropertyScope;\
typedef uint32_t AudioObjectPropertySelector;\
typedef struct { AudioObjectPropertySelector mSelector; AudioObjectPropertyScope mScope; uint32_t mElement; } AudioObjectPropertyAddress;\
#define kAudioObjectPropertyElementMain 0\
#define kAudioObjectPropertyElementWildcard 0xFFFFFFFFu\
#define kAudioObjectPropertyScopeGlobal 0x676c6f62\
#define kAudioDevicePropertyScopeOutput 0x6f757470\
#define kAudioDevicePropertyScopeInput 0x696e7074\
#define kAudioObjectSystemObject 1\
#define kAudioHardwarePropertyDefaultOutputDevice 0x646f7574\
#define kAudioDevicePropertyStreamConfiguration 0x736c6179\
#define kAudioDevicePropertyPreferredChannelLayout 0x706c6179\
#define kAudioDevicePropertyPreferredChannelsForStereo 0x64636832\
#define kAudioDevicePropertyLatency 0x6c746e63\
#define kAudioDevicePropertySafetyOffset 0x7366746f\
#define kAudioDevicePropertyBufferFrameSize 0x6673697a\
#define kAudioDevicePropertyNominalSampleRate 0x6e737274\
#define kAudioDevicePropertyStreamFormat 0x73666d74\
#define kAudioStreamPropertyPhysicalFormat 0x70666f72\
static inline int AudioObjectGetPropertyData(uint32_t a, const void *b, uint32_t c, const void *d, uint32_t *e, void *f) { return -1; }\
static inline int AudioObjectGetPropertyDataSize(uint32_t a, const void *b, uint32_t c, const void *d, uint32_t *e) { return -1; }\
static inline int AudioObjectIsPropertySettable(uint32_t a, const void *b, void *c) { return 0; }\
static inline int AudioObjectAddPropertyListener(uint32_t a, const void *b, void *c, void *d) { return -1; }\
static inline int AudioObjectRemovePropertyListener(uint32_t a, const void *b, void *c, void *d) { return -1; }\
#endif' "$dir/audio/out/ao.h"

  # Patch ao_coreaudio_utils.c for iOS:
  # Replace the entire file with an #if !TARGET_OS_IPHONE guard, providing
  # iOS-safe stub implementations only.  All CoreAudio HAL API (kAudioHardware*,
  # kAudioDevice*, AudioObjectHasProperty, AudioConvertHostTimeToNanos, etc.)
  # is macOS-only and must not be compiled on iphoneos / iphonesimulator.
  python3 - "$dir/audio/out/ao_coreaudio_utils.c" <<'PYEOF'
import sys
with open(sys.argv[1], 'r') as f:
    src = f.read()

if 'TARGET_OS_IPHONE_COREAUDIO_UTILS_V2_PATCHED' in src:
    print('Already patched v2, skipping')
    sys.exit(0)

# Find end of license block (first blank line after the */ closing the comment)
license_end = src.find('*/\n')
if license_end == -1:
    license_end = 0
else:
    license_end += 3  # skip past the newline

# Walk forward to find first non-blank line (the real code starts)
code_start = license_end
while code_start < len(src) and src[code_start] == '\n':
    code_start += 1

ios_stubs = '''
/* ============================================================
 * iOS stubs for ao_coreaudio_utils.c
 * All CoreAudio HAL APIs are macOS-only; we provide minimal
 * no-op or mach_time-based implementations for iOS.
 * ============================================================ */
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE

#include <mach/mach_time.h>
#include <stdbool.h>
#include <stdint.h>
#include "audio/out/ao_coreaudio_utils.h"
#include "common/msg.h"

bool check_ca_st(struct ao *ao, int level, OSStatus code, const char *message) {
    return code == noErr;
}
void ca_get_device_list(struct ao *ao, struct ao_device_list *list) {}
bool ca_formatid_is_compressed(uint32_t formatid) { return false; }
void ca_fill_asbd(struct ao *ao, AudioStreamBasicDescription *asbd) {}
void ca_print_asbd(struct ao *ao, const char *d, const AudioStreamBasicDescription *a) {}
bool ca_asbd_equals(const AudioStreamBasicDescription *a, const AudioStreamBasicDescription *b) { return false; }
int  ca_asbd_to_mp_format(const AudioStreamBasicDescription *asbd) { return 0; }
bool ca_asbd_is_better(AudioStreamBasicDescription *req,
                       AudioStreamBasicDescription *old,
                       AudioStreamBasicDescription *new) { return false; }
int64_t ca_frames_to_ns(struct ao *ao, uint32_t frames) { return 0; }

int64_t ca_get_latency(const AudioTimeStamp *ts) {
    static mach_timebase_info_data_t timebase;
    if (timebase.denom == 0) mach_timebase_info(&timebase);
    uint64_t out = ts->mHostTime;
    uint64_t now = mach_absolute_time();
    if (now > out) return 0;
    return (out - now) * timebase.numer / timebase.denom;
}

#endif /* TARGET_OS_IPHONE */
'''

new_src = (
    src[:code_start] +
    '#if !TARGET_OS_IPHONE\n' +
    src[code_start:] +
    '\n#endif /* !TARGET_OS_IPHONE */\n' +
    ios_stubs +
    '\n#define TARGET_OS_IPHONE_COREAUDIO_UTILS_V2_PATCHED 1\n'
)

with open(sys.argv[1], 'w') as f:
    f.write(new_src)
print('ao_coreaudio_utils.c patched for iOS (v2, full file guard + stubs)')
PYEOF

  # Patch meson.build: compile osdep/utils-mac.c unconditionally on Apple
  # platforms (darwin OR ios). Upstream only compiles it under the cocoa
  # feature, but we disable cocoa. Without this, cfstr_get_cstr / cfstr_from_cstr
  # are undefined — same fix that build_libmpv_macos.sh applies for macOS.
  python3 - "$dir/meson.build" << 'PYEOF2'
import sys, re
fn = sys.argv[1]
with open(fn) as f:
    content = f.read()
if 'utils-mac-ios-patched' in content:
    print('meson.build: utils-mac patch already applied, skipping')
    sys.exit(0)
# Remove 'osdep/utils-mac.c' from wherever it currently lives (cocoa block)
content = re.sub(r"^\s+'osdep/utils-mac\.c',\n", "", content, flags=re.MULTILINE)
# Insert unconditionally for darwin and ios, just before cocoa dependency
marker = "cocoa = dependency('appleframeworks'"
patch = (
    "# Always compile on Apple platforms: provides cfstr_from_cstr / cfstr_get_cstr\n"
    "# (needed by ao_avfoundation even when Cocoa UI is disabled)\n"
    "if darwin or host_machine.system() == 'ios'\n"
    "    sources += files('osdep/utils-mac.c')\n"
    "endif\n"
    "# utils-mac-ios-patched\n\n"
)
content = content.replace(marker, patch + marker, 1)
with open(fn, 'w') as f:
    f.write(content)
print('meson.build: osdep/utils-mac.c now compiled for darwin + ios')
PYEOF2

  local bdir="$BUILD_DIR/build/mpv-${sdk}-${arch}"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  meson_setup "$dir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=static \
    --cross-file="$(write_ios_cross "$sdk" "$arch")" \
    --native-file="$(write_native_file)" \
    -Dlibmpv=true \
    -Dcplayer=false \
    -Dbuild-date=false \
    -Dtests=false \
    -Dmanpage-build=disabled \
    -Dhtml-build=disabled \
    -Dswift-build=disabled \
    -Dvulkan=disabled \
    -Dlua=disabled \
    -Djavascript=enabled \
    -Drubberband=enabled \
    -Duchardet=enabled \
    -Dlcms2=disabled \
    -Dlibarchive=enabled \
    -Dzimg=disabled \
    -Dcocoa=disabled \
    -Dvideo-osd=disabled \
    -Davfoundation=enabled \
    -Dcoreaudio=disabled \
    -Daudiounit=disabled \
    -Dios-gl=disabled \
    -Dvideotoolbox-gl=disabled \
    -Dvideotoolbox-pl=disabled \
    -Dopenal=disabled \
    -Dgl=disabled \
    -Dplain-gl=disabled \
    -Dx11=disabled \
    -Dwayland=disabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "mpv static ($sdk/$arch) ✓"
}

# =============================================================================
# Assemble xcframework from slices
# =============================================================================
assemble_xcframework() {
  log "Assembling xcframework..."
  local xcfw="$OUTPUT_DIR/libmpv.xcframework"
  rm -rf "$xcfw"
  mkdir -p "$OUTPUT_DIR"

  # Helper: merge all .a files in a prefix into a single combined lib
  merge_all_libs() {
    local prefix_lib="$1" output="$2"
    log "Merging static libs from $prefix_lib..."
    # Exclude libpng16.a (duplicate of libpng.a) and harfbuzz-subset (unused)
    local libs=()
    for a in "$prefix_lib"/*.a; do
      local name; name="$(basename "$a")"
      [[ "$name" == "libpng16.a" || "$name" == "libharfbuzz-subset.a" ]] && continue
      libs+=("$a")
    done
    libtool -static -o "$output" "${libs[@]}"
    ok "Merged ${#libs[@]} libraries -> $(basename "$output")"
  }

  # Merge per-slice
  local device_combined="$BUILD_DIR/libmpv_device.a"
  local sim_arm64_combined="$BUILD_DIR/libmpv_sim_arm64.a"
  local sim_x86_combined="$BUILD_DIR/libmpv_sim_x86_64.a"

  merge_all_libs "$PREFIX_BASE/iphoneos_arm64/lib"        "$device_combined"
  merge_all_libs "$PREFIX_BASE/iphonesimulator_arm64/lib"  "$sim_arm64_combined"
  merge_all_libs "$PREFIX_BASE/iphonesimulator_x86_64/lib" "$sim_x86_combined"

  # Simulator universal (arm64 + x86_64)
  local sim_universal="$BUILD_DIR/libmpv_simulator.a"
  log "lipo simulator (arm64 + x86_64)..."
  lipo -create "$sim_arm64_combined" "$sim_x86_combined" -output "$sim_universal"

  # Copy headers
  local headers_src="$PREFIX_BASE/iphoneos_arm64/include/mpv"
  local device_dir="$BUILD_DIR/xcfw_device"
  local sim_dir="$BUILD_DIR/xcfw_sim"
  mkdir -p "$device_dir/Headers" "$sim_dir/Headers"
  cp "$device_combined" "$device_dir/libmpv.a"
  cp "$sim_universal"   "$sim_dir/libmpv.a"
  cp -r "$headers_src"/* "$device_dir/Headers/" 2>/dev/null || true
  cp -r "$headers_src"/* "$sim_dir/Headers/"   2>/dev/null || true

  xcodebuild -create-xcframework \
    -library "$device_dir/libmpv.a"  -headers "$device_dir/Headers" \
    -library "$sim_dir/libmpv.a"     -headers "$sim_dir/Headers" \
    -output "$xcfw"

  codesign -s - --force --deep "$xcfw" 2>/dev/null || true
  ok "xcframework: $xcfw"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║   build_libmpv_ios.sh — mpv $MPV_VERSION (static xcframework)  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  check_tools
  mkdir -p "$BUILD_DIR/src" "$BUILD_DIR/build"

  for slice in "${SLICES[@]}"; do
    local sdk="${slice%%:*}"
    local arch="${slice##*:}"
    build_slice "$sdk" "$arch"
  done

  assemble_xcframework

  [[ "${KEEP_BUILD:-0}" != "1" ]] && rm -rf "$BUILD_DIR" && ok "BUILD_DIR removed"

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  iOS build complete!                                         ║"
  echo "║  Output: ios/Frameworks/libmpv.xcframework                  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
}

main "$@"
