#!/usr/bin/env bash
# =============================================================================
# build_libmpv_windows.sh
#
# Cross-compiles mpv 0.41.0 for Windows x86_64 from Linux.
#
# === OUTPUT FORMATS AND LOCATIONS ===
# Target Dir:  windows/libs/ (binaries) and windows/include/ (headers)
# Output File: libmpv-2.dll (Dynamic Link Library), libmpv.dll.a (Import Library for linking)
#
# === SYSTEM & HARDWARE SPECS ===
# Target OS:   Windows (Windows 10+ recommended, cross-compiled via MinGW-w64 on Linux)
# Target Arch: x86_64 (64-bit Windows environments)
# Compiler:    MinGW-w64 x86_64-w64-mingw32-gcc
#
# Usage (from project root):
#   chmod +x scripts/build_libmpv_windows.sh
#   ./scripts/build_libmpv_windows.sh
#
# Options (environment variables):
#   MPV_VERSION=0.41.0    (default: 0.41.0)
#   JOBS=N                (default: number of cores)
#   KEEP_BUILD=1          (does not delete BUILD_DIR at the end)
#
# Requirements (via Linux Ubuntu 22.04+):
#   sudo apt install mingw-w64 mingw-w64-tools nasm cmake ninja-build \
#     meson python3 python3-pip autoconf automake libtool git curl pkg-config
# =============================================================================

set -euo pipefail

# ── Versions ──────────────────────────────────────────────────────────────────
MPV_VERSION="${MPV_VERSION:-0.41.0}"
FFMPEG_VERSION="${FFMPEG_VERSION:-7.1.1}"
LIBASS_VERSION="${LIBASS_VERSION:-0.17.3}"
FREETYPE_VERSION="${FREETYPE_VERSION:-2.13.3}"
FRIBIDI_VERSION="${FRIBIDI_VERSION:-1.0.15}"
HARFBUZZ_VERSION="${HARFBUZZ_VERSION:-10.1.0}"
FONTCONFIG_VERSION="${FONTCONFIG_VERSION:-2.15.0}"
LIBPNG_VERSION="${LIBPNG_VERSION:-1.6.43}"
ZLIB_VERSION="${ZLIB_VERSION:-1.3.1}"
BZIP2_VERSION="${BZIP2_VERSION:-1.0.8}"
XZ_VERSION="${XZ_VERSION:-5.6.2}"
EXPAT_VERSION="${EXPAT_VERSION:-2.6.4}"
LIBICONV_VERSION="${LIBICONV_VERSION:-1.17}"
SPEEXDSP_VERSION="${SPEEXDSP_VERSION:-1.2.1}"
LIBPLACEBO_VERSION="${LIBPLACEBO_VERSION:-v6.338.2}"
RUBBERBAND_VERSION="${RUBBERBAND_VERSION:-3.3.0}"
UCHARDET_VERSION="${UCHARDET_VERSION:-0.0.8}"
LCMS2_VERSION="${LCMS2_VERSION:-2.16}"
LIBARCHIVE_VERSION="${LIBARCHIVE_VERSION:-3.7.7}"
LIBBLURAY_VERSION="${LIBBLURAY_VERSION:-1.3.4}"
MUJS_VERSION="${MUJS_VERSION:-1.3.6}"
LUAJIT_COMMIT="${LUAJIT_COMMIT:-v2.1}"
ZIMG_VERSION="${ZIMG_VERSION:-3.0.5}"
MBEDTLS_VERSION="${MBEDTLS_VERSION:-3.6.0}"

JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
KEEP_BUILD="${KEEP_BUILD:-0}"

# ── Toolchain MinGW ───────────────────────────────────────────────────────────
TRIPLE="x86_64-w64-mingw32"
CROSS_CC="${TRIPLE}-gcc"
CROSS_CXX="${TRIPLE}-g++"
CROSS_AR="${TRIPLE}-ar"
CROSS_RANLIB="${TRIPLE}-ranlib"
CROSS_STRIP="${TRIPLE}-strip"
CROSS_NM="${TRIPLE}-nm"
CROSS_DLLTOOL="${TRIPLE}-dlltool"
CROSS_WINDRES="${TRIPLE}-windres"

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
BUILD_DIR="${BUILD_DIR:-$ROOT/build-windows}"
DIST="$BUILD_DIR/dist"
SRC="$BUILD_DIR/src"
DEST="$ROOT/windows/libs"
HEADERS_DEST="$ROOT/windows/include"

mkdir -p "$SRC" "$DIST/lib" "$DIST/include" "$DEST" "$HEADERS_DEST"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $*${NC}" >&2; }
ok()   { echo -e "${GREEN}✓ $*${NC}" >&2; }
warn() { echo -e "${YELLOW}⚠ $*${NC}" >&2; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

LOG_FILE="$BUILD_DIR/build.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log "=== Building libmpv for Windows x86_64 (cross-compiled from Linux) — $(date) ==="
echo "MPV: $MPV_VERSION | FFmpeg: $FFMPEG_VERSION | Jobs: $JOBS"
echo "Build directory: $BUILD_DIR"

# ── Check toolchain ───────────────────────────────────────────────────────────
MISSING=()
for tool in "$CROSS_CC" "$CROSS_CXX" "$CROSS_AR" "$CROSS_WINDRES" \
            nasm ninja meson cmake python3 autoreconf curl git; do
  command -v "$tool" &>/dev/null || MISSING+=("$tool")
done
if [[ ${#MISSING[@]} -gt 0 ]]; then
  fail "Missing toolchain: ${MISSING[*]}"
fi

# ── Toolchain file CMake ──────────────────────────────────────────────────────
TOOLCHAIN_FILE="$BUILD_DIR/mingw64.cmake"
cat > "$TOOLCHAIN_FILE" << EOF
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(TRIPLE "${TRIPLE}")
set(CMAKE_C_COMPILER   ${CROSS_CC})
set(CMAKE_CXX_COMPILER ${CROSS_CXX})
set(CMAKE_AR           ${CROSS_AR})
set(CMAKE_RANLIB       ${CROSS_RANLIB})
set(CMAKE_RC_COMPILER  ${TRIPLE}-windres)
set(CMAKE_FIND_ROOT_PATH "${DIST}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF

# ── Meson cross-file ──────────────────────────────────────────────────────────
CROSS_FILE="$BUILD_DIR/mingw64.meson"
cat > "$CROSS_FILE" << EOF
[binaries]
c = '${CROSS_CC}'
cpp = '${CROSS_CXX}'
ar = '${CROSS_AR}'
strip = '${CROSS_STRIP}'
nm = '${CROSS_NM}'
dlltool = '${CROSS_DLLTOOL}'
pkgconfig = 'pkg-config'
windres = '${CROSS_WINDRES}'
cmake = 'cmake'

[host_machine]
system = 'windows'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'

[properties]
needs_exe_wrapper = true
sys_root = '/usr/x86_64-w64-mingw32'

[built-in options]
c_link_args = ['-L/usr/x86_64-w64-mingw32/lib']
cpp_link_args = ['-L/usr/x86_64-w64-mingw32/lib']
EOF

# ── pkg-config wrapper ────────────────────────────────────────────────────────
# Use triple-pkg-config if available, otherwise a wrapper
PKG_CONFIG_BIN=$(command -v "${TRIPLE}-pkg-config" || echo "pkg-config")
PKGCFG_WRAPPER="$BUILD_DIR/pkg-config-cross"
cat > "$PKGCFG_WRAPPER" << EOF
#!/usr/bin/env bash
export PKG_CONFIG_LIBDIR="${DIST}/lib/pkgconfig:${DIST}/share/pkgconfig"
export PKG_CONFIG_PATH="\$PKG_CONFIG_LIBDIR"
export PKG_CONFIG_SYSROOT_DIR=""
exec ${PKG_CONFIG_BIN} "\$@"
EOF
chmod +x "$PKGCFG_WRAPPER"

export PKG_CONFIG="$PKGCFG_WRAPPER"
export PKG_CONFIG_PATH="$DIST/lib/pkgconfig:$DIST/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$PKG_CONFIG_PATH"

# Common flags
WIN_FLAGS="-D_WIN32_WINNT=0x0A00 -DWINVER=0x0A00"
CFLAGS_COMMON="-O2 -pipe $WIN_FLAGS -I$DIST/include"
CXXFLAGS_COMMON="-O2 -pipe $WIN_FLAGS -I$DIST/include"
CPPFLAGS_COMMON="-I$DIST/include"
LDFLAGS_COMMON="-L$DIST/lib -static-libgcc"

AUTOCONF_COMMON=(
  --host="$TRIPLE"
  --prefix="$DIST"
  --enable-static
  --disable-shared
)

# ── Helpers ───────────────────────────────────────────────────────────────────
fetch() {
  local name="$1" url="$2"
  local archive="$SRC/$(basename "$url")"
  if [[ ! -f "$archive" ]]; then
    echo "→ Downloading $name..." >&2
    local success=0
    for i in {1..3}; do
      if curl -fsSL "$url" -o "$archive"; then
        success=1
        break
      else
        echo "  Retrying $name download ($i/3)..." >&2
        rm -f "$archive"
        sleep 5
      fi
    done
    [[ $success -eq 1 ]] || { echo "✗ Failed to download $name after 3 attempts" >&2; exit 1; }
  fi
  echo "$archive"
}

download_git() {
  local url="$1" dest="$2" tag="${3:-}"
  if [[ ! -d "$dest/.git" ]]; then
    echo "→ Cloning $dest..." >&2
    if [[ -n "$tag" ]]; then
      git clone --depth=1 --branch "$tag" "$url" "$dest" 2>/dev/null \
        || { rm -rf "$dest"; git clone --depth=1 "$url" "$dest"; }
    else
      git clone --depth=1 "$url" "$dest"
    fi
  fi
}

cmake_win() {
  cmake -S "$1" -B "$2" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DCMAKE_INSTALL_PREFIX="$DIST" \
    -DCMAKE_BUILD_TYPE=Release \
    "${@:3}"
}

# ════════════════════════════════════════════════════════════════════════════════
# Dependencies
# ════════════════════════════════════════════════════════════════════════════════

# ── zlib ──────────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libz.a" ]]; then
  log "Building zlib $ZLIB_VERSION..."
  Z=$(fetch zlib "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz")
  tar -xf "$Z" -C "$SRC"
  pushd "$SRC/zlib-$ZLIB_VERSION"
    CHOST="$TRIPLE" CC="$CROSS_CC" AR="$CROSS_AR" RANLIB="$CROSS_RANLIB" \
      ./configure --prefix="$DIST" --static
    make -j"$JOBS" install
  popd
  ok "zlib ✓"
fi

# ── bzip2 ─────────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libbz2.a" ]]; then
  echo "--- bzip2 $BZIP2_VERSION ---"
  BZ=$(fetch bzip2 "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz")
  tar -xf "$BZ" -C "$SRC"
  pushd "$SRC/bzip2-$BZIP2_VERSION"
    make CC="$CROSS_CC" AR="$CROSS_AR" RANLIB="$CROSS_RANLIB" \
         CFLAGS="$CFLAGS_COMMON" -j"$JOBS" libbz2.a
    install -m644 libbz2.a "$DIST/lib/"
    install -m644 bzlib.h  "$DIST/include/"
    # pkg-config
    cat > "$DIST/lib/pkgconfig/bzip2.pc" << PCF
prefix=${DIST}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: bzip2
Version: 1.0.8
Libs: -L\${libdir} -lbz2
Cflags: -I\${includedir}
PCF
  popd
fi

# ── xz (liblzma) ──────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/liblzma.a" ]]; then
  echo "--- xz $XZ_VERSION ---"
  XZ=$(fetch xz "https://tukaani.org/xz/xz-${XZ_VERSION}.tar.gz")
  tar -xf "$XZ" -C "$SRC"
  pushd "$SRC/xz-$XZ_VERSION"
    CFLAGS="$CFLAGS_COMMON" ./configure "${AUTOCONF_COMMON[@]}" \
      --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo \
      --disable-scripts --disable-doc
    make -j"$JOBS" install
  popd
fi

# ── libiconv ──────────────────────────────────────────────────────────────────
# Windows does not have native iconv; fontconfig needs it
if [[ ! -f "$DIST/lib/libiconv.a" ]]; then
  echo "--- libiconv $LIBICONV_VERSION ---"
  IC=$(fetch libiconv "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz")
  tar -xf "$IC" -C "$SRC"
  pushd "$SRC/libiconv-$LIBICONV_VERSION"
    CFLAGS="$CFLAGS_COMMON" ./configure "${AUTOCONF_COMMON[@]}" \
      --enable-extra-encodings --disable-nls
    make -j"$JOBS" install
  popd
fi

# ── expat ─────────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libexpat.a" ]]; then
  echo "--- expat $EXPAT_VERSION ---"
  EV="${EXPAT_VERSION//./_}"
  EX=$(fetch expat "https://github.com/libexpat/libexpat/releases/download/R_${EV}/expat-${EXPAT_VERSION}.tar.bz2")
  tar -xf "$EX" -C "$SRC"
  pushd "$SRC/expat-$EXPAT_VERSION"
    CFLAGS="$CFLAGS_COMMON" ./configure "${AUTOCONF_COMMON[@]}" --without-xmlwf
    make -j"$JOBS" install
  popd
fi

# ── libpng ────────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libpng.a" ]]; then
  echo "--- libpng $LIBPNG_VERSION ---"
  PN=$(fetch libpng "https://downloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.xz")
  tar -xf "$PN" -C "$SRC"
  pushd "$SRC/libpng-$LIBPNG_VERSION"
    CFLAGS="$CFLAGS_COMMON" CPPFLAGS="$CPPFLAGS_COMMON" LDFLAGS="$LDFLAGS_COMMON" \
      ./configure "${AUTOCONF_COMMON[@]}"
    make -j"$JOBS" install
  popd
fi

# ── freetype (first pass — without harfbuzz) ─────────────────────────────────
if [[ ! -f "$DIST/lib/libfreetype.a" ]]; then
  echo "--- freetype $FREETYPE_VERSION (first pass) ---"
  FT=$(fetch freetype "https://downloads.sourceforge.net/freetype/freetype-${FREETYPE_VERSION}.tar.xz")
  tar -xf "$FT" -C "$SRC"
  pushd "$SRC/freetype-$FREETYPE_VERSION"
    CFLAGS="$CFLAGS_COMMON" CPPFLAGS="$CPPFLAGS_COMMON" LDFLAGS="$LDFLAGS_COMMON" \
      PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
      ./configure "${AUTOCONF_COMMON[@]}" \
        --with-zlib=yes --with-png=yes --with-harfbuzz=no --with-brotli=no
    make -j"$JOBS" install
  popd
fi

# ── fribidi ───────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libfribidi.a" ]]; then
  echo "--- fribidi $FRIBIDI_VERSION ---"
  FB=$(fetch fribidi "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz")
  tar -xf "$FB" -C "$SRC"
  pushd "$SRC/fribidi-$FRIBIDI_VERSION"
    CFLAGS="$CFLAGS_COMMON" ./configure "${AUTOCONF_COMMON[@]}" \
      --disable-debug --disable-deprecated
    make -j"$JOBS" install
  popd
fi

# ── harfbuzz ──────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libharfbuzz.a" ]]; then
  echo "--- harfbuzz $HARFBUZZ_VERSION ---"
  HB=$(fetch harfbuzz "https://github.com/harfbuzz/harfbuzz/archive/refs/tags/${HARFBUZZ_VERSION}.tar.gz")
  tar -xf "$HB" -C "$SRC"
  pushd "$SRC/harfbuzz-$HARFBUZZ_VERSION"
    meson setup build \
      --cross-file "$CROSS_FILE" \
      --prefix="$DIST" --libdir=lib \
      --buildtype=release --default-library=static \
      -Dtests=disabled -Ddocs=disabled -Dglib=disabled \
      -Dc_args="$CFLAGS_COMMON" -Dcpp_args="$CXXFLAGS_COMMON"
    ninja -C build install
  popd
fi

# ── freetype (second pass — with harfbuzz) ──────────────────────────────────
echo "--- freetype $FREETYPE_VERSION (second pass) ---"
pushd "$SRC/freetype-$FREETYPE_VERSION"
  make clean || true
  CFLAGS="$CFLAGS_COMMON" CPPFLAGS="$CPPFLAGS_COMMON" LDFLAGS="$LDFLAGS_COMMON" \
    PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
    ./configure "${AUTOCONF_COMMON[@]}" \
      --with-zlib=yes --with-png=yes --with-harfbuzz=yes --with-brotli=no
  make -j"$JOBS" install
popd

# ── fontconfig ────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libfontconfig.a" ]]; then
  echo "--- fontconfig $FONTCONFIG_VERSION ---"
  FC=$(fetch fontconfig "https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.xz")
  tar -xf "$FC" -C "$SRC"
  pushd "$SRC/fontconfig-$FONTCONFIG_VERSION"
    CFLAGS="$CFLAGS_COMMON" LDFLAGS="$LDFLAGS_COMMON" \
      ./configure "${AUTOCONF_COMMON[@]}" \
        --disable-docs --disable-nls --disable-libxml2 --enable-libiconv \
        --with-arch=x86_64
    make -j"$JOBS" install
  popd
fi

# ── speexdsp ──────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libspeexdsp.a" ]]; then
  echo "--- speexdsp $SPEEXDSP_VERSION ---"
  SP=$(fetch speexdsp "https://github.com/xiph/speexdsp/archive/refs/tags/SpeexDSP-${SPEEXDSP_VERSION}.tar.gz")
  tar -xf "$SP" -C "$SRC"
  pushd "$SRC/speexdsp-SpeexDSP-$SPEEXDSP_VERSION"
    ./autogen.sh
    CFLAGS="$CFLAGS_COMMON" ./configure "${AUTOCONF_COMMON[@]}"
    make -j"$JOBS" install
  popd
fi

# ── rubberband ────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/librubberband.a" ]]; then
  echo "--- rubberband $RUBBERBAND_VERSION ---"
  RB=$(fetch rubberband "https://breakfastquay.com/files/releases/rubberband-${RUBBERBAND_VERSION}.tar.bz2")
  tar -xf "$RB" -C "$SRC"
  pushd "$SRC/rubberband-$RUBBERBAND_VERSION"
    meson setup build \
      --cross-file "$CROSS_FILE" \
      --prefix="$DIST" --libdir=lib \
      --buildtype=release --default-library=static \
      -Dfft=builtin -Dresampler=builtin
    ninja -C build install
  popd
fi

# ── libplacebo ────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libplacebo.a" ]]; then
  echo "--- libplacebo $LIBPLACEBO_VERSION ---"
  LP_DIR="$SRC/libplacebo-git"
  download_git "https://code.videolan.org/videolan/libplacebo.git" "$LP_DIR" "v6.338.2"
  git -C "$LP_DIR" submodule update --init --recursive
  pushd "$LP_DIR"
    meson setup build \
      --cross-file "$CROSS_FILE" \
      --prefix="$DIST" --libdir=lib \
      --buildtype=release --default-library=static \
      -Dvulkan=disabled -Dshaderc=disabled -Dglslang=disabled -Dopengl=disabled \
      -Dd3d11=disabled -Ddemos=false -Dtests=false
    ninja -C build install
  popd
fi

# ── libass ────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libass.a" ]]; then
  echo "--- libass $LIBASS_VERSION ---"
  LA=$(fetch libass "https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.gz")
  tar -xf "$LA" -C "$SRC"
  pushd "$SRC/libass-$LIBASS_VERSION"
    CFLAGS="$CFLAGS_COMMON" ./configure "${AUTOCONF_COMMON[@]}" \
      --disable-require-system-font-provider
    make -j"$JOBS" install
  popd
fi


# ── libarchive ────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libarchive.a" ]]; then
  echo "--- libarchive $LIBARCHIVE_VERSION ---"
  LA=$(fetch libarchive "https://github.com/libarchive/libarchive/releases/download/v${LIBARCHIVE_VERSION}/libarchive-${LIBARCHIVE_VERSION}.tar.gz")
  tar -xf "$LA" -C "$SRC"
  pushd "$SRC/libarchive-$LIBARCHIVE_VERSION"
    CFLAGS="$CFLAGS_COMMON" ./configure "${AUTOCONF_COMMON[@]}" \
      --without-xml2 --without-expat --without-openssl --without-nettle \
      --disable-bsdtar --disable-bsdcpio --disable-bsdcat
    make -j"$JOBS" install
  popd
fi


# ── mujs ──────────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libmujs.a" ]]; then
  echo "--- mujs $MUJS_VERSION ---"
  # Use GitHub mirror as mujs.com is often down
  MJ=$(fetch mujs "https://github.com/ccxvii/mujs/archive/refs/tags/${MUJS_VERSION}.tar.gz")
  tar -xf "$MJ" -C "$SRC"
  pushd "$SRC/mujs-$MUJS_VERSION"
    make CC="$CROSS_CC" AR="$CROSS_AR" RANLIB="$CROSS_RANLIB" \
         CFLAGS="$CFLAGS_COMMON" prefix="$DIST" -j"$JOBS" build/release/libmujs.a
    install -m644 build/release/libmujs.a "$DIST/lib/"
    install -m644 mujs.h "$DIST/include/"
    # pkg-config for mujs
    cat > "$DIST/lib/pkgconfig/mujs.pc" << PCF
prefix=${DIST}
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: mujs
Version: ${MUJS_VERSION}
Libs: -L\${libdir} -lmujs
Cflags: -I\${includedir}
PCF
  popd
fi

# ── LuaJIT ────────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libluajit-5.1.a" ]]; then
  echo "--- LuaJIT $LUAJIT_COMMIT ---"
  LJ_DIR="$SRC/LuaJIT-$LUAJIT_COMMIT"
  if [[ ! -d "$LJ_DIR" ]]; then
    git clone --depth=1 --branch "$LUAJIT_COMMIT" \
      https://github.com/LuaJIT/LuaJIT.git "$LJ_DIR"
  fi
  pushd "$LJ_DIR"
    # Remove x86-specific flags that break on ARM64 hosts (Apple Silicon)
    # LuaJIT sometimes leaks target flags to host tools.
    sed -i 's/-malign-double//g' src/Makefile
    
    LUAJIT_OPTS=(
      CROSS="$TRIPLE-"
      TARGET_SYS=Windows
      HOST_CC="gcc"
      HOST_CFLAGS="-O2"
      BUILDMODE=static
      PREFIX="$DIST"
    )
    # We must run make and make install with the same variables
    # to avoid triggering a native rebuild during installation.
    make clean || true
    make -j"$JOBS" "${LUAJIT_OPTS[@]}"
    
    # Hack: LuaJIT's 'install' target often looks for 'luajit' even on Windows
    # when cross-compiling. Create a copy to satisfy it.
    cp src/luajit.exe src/luajit || true
    
    make install "${LUAJIT_OPTS[@]}"
  popd
fi

# ── mbedtls ───────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libmbedtls.a" ]]; then
  echo "--- mbedtls $MBEDTLS_VERSION ---"
  MB=$(fetch mbedtls "https://github.com/Mbed-TLS/mbedtls/releases/download/v${MBEDTLS_VERSION}/mbedtls-${MBEDTLS_VERSION}.tar.bz2")
  tar -xf "$MB" -C "$SRC"
  mkdir -p "$SRC/mbedtls-$MBEDTLS_VERSION/build"
  cmake_win "$SRC/mbedtls-$MBEDTLS_VERSION" "$SRC/mbedtls-$MBEDTLS_VERSION/build" \
    -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF \
    -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DUSE_STATIC_MBEDTLS_LIBRARY=ON
  cmake --build "$SRC/mbedtls-$MBEDTLS_VERSION/build" -j"$JOBS" --target install
fi

# ── FFmpeg ────────────────────────────────────────────────────────────────────
if [[ ! -f "$DIST/lib/libavcodec.a" ]]; then
  echo "--- FFmpeg $FFMPEG_VERSION ---"
  FF=$(fetch ffmpeg "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz")
  tar -xf "$FF" -C "$SRC"
  pushd "$SRC/ffmpeg-$FFMPEG_VERSION"
    ./configure \
      --prefix="$DIST" \
      --arch=x86_64 \
      --target-os=mingw32 \
      --cross-prefix="${TRIPLE}-" \
      --pkg-config="$PKG_CONFIG" \
      --enable-static --disable-shared \
      --disable-programs --disable-doc --disable-debug \
      --enable-avcodec --enable-avfilter --enable-avformat \
      --enable-avutil --enable-avdevice --enable-swresample --enable-swscale \
      --enable-zlib --enable-bzlib --enable-lzma \
      --enable-network --enable-version3 \
      --disable-sdl2 --disable-outdevs \
      --extra-cflags="-I$DIST/include $WIN_FLAGS" \
      --extra-cxxflags="-I$DIST/include $WIN_FLAGS" \
      --extra-ldflags="-L$DIST/lib -static-libgcc"
    make -j"$JOBS" install
  popd
fi

# ── pathcch import library ────────────────────────────────────────────────────
# mpv on Windows uses __imp_PathCchXxx symbols (DLL import style). MinGW
# doesn't ship libpathcch.a, so we generate an import library stub via dlltool.
if [[ ! -f "$DIST/lib/libpathcch.a" ]]; then
  echo "--- pathcch import library ---"
  cat > "$DIST/lib/pathcch.def" << 'DEFEOF'
LIBRARY pathcch
EXPORTS
  PathCchCanonicalizeEx
  PathCchRemoveFileSpec
  PathAllocCombine
  PathCchAppend
  PathCchCombineEx
DEFEOF
  x86_64-w64-mingw32-dlltool \
    -d "$DIST/lib/pathcch.def" \
    -l "$DIST/lib/libpathcch.a" \
    -k
fi

# ── mpv ───────────────────────────────────────────────────────────────────────
echo "--- mpv $MPV_VERSION ---"
MPV_ARCHIVE=$(fetch mpv "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz")
tar -xf "$MPV_ARCHIVE" -C "$SRC"

pushd "$SRC/mpv-$MPV_VERSION"
  python3 -c "
import sys, re
with open('meson.build', 'r') as f: content = f.read()
# Make libplacebo optional (may not be in our dist)
content = re.sub(
    r\"libplacebo = dependency\('libplacebo',\s*version: '[^']*',\n\s*default_options: \['default_library=static', 'demos=false'\]\)\",
    \"libplacebo = dependency('libplacebo', version: '>=6.338.2', required: false)\",
    content
)
# Make libass optional (fallback if not found)
content = content.replace(\"libass = dependency('libass', version: '>= 0.12.2')\", \"libass = dependency('libass', version: '>= 0.12.2', required: false)\")
# Make pathcch optional for MinGW cross-compile (not in MinGW sysroot)
content = re.sub(
    r\"cc\.find_library\('pathcch'[^)]*\)\",
    \"cc.find_library('pathcch', required: false)\",
    content
)
# Make ALL cc.find_library() calls optional for MinGW cross-compile
# These Windows system libs exist in the sysroot but meson can't find them.
# We pass them explicitly via c_link_args / cpp_link_args.
content = re.sub(
    r\"cc\.find_library\('([^']+)'(?!\s*,\s*required)\s*\)\",
    r\"cc.find_library('\1', required: false)\",
    content
)
with open('meson.build', 'w') as f: f.write(content)
"

  # Patch timer-win32.c: define CREATE_WAITABLE_TIMER_HIGH_RESOLUTION if missing
  # (older MinGW-w64 doesn't define it even with _WIN32_WINNT=0x0A00)
  sed -i '1s|^|#ifndef CREATE_WAITABLE_TIMER_HIGH_RESOLUTION\n#define CREATE_WAITABLE_TIMER_HIGH_RESOLUTION 0x00000002\n#endif\n|' osdep/timer-win32.c

  # Patch w32_register.c: define FTA_Show and FTA_OpenIsSafe if missing (shellapi constants)
  sed -i '1s|^|#ifndef FTA_Show\n#define FTA_Show 0x00000002\n#endif\n#ifndef FTA_OpenIsSafe\n#define FTA_OpenIsSafe 0x00001000\n#endif\n|' osdep/w32_register.c

  # Create a pathcch stub for MinGW (pathcch.dll is not available in MinGW sysroot)
  # Implements needed APIs using shlwapi equivalents
  cat > osdep/pathcch_stub.c << 'STUBEOF'
/* pathcch stub for MinGW cross-compile — implements missing pathcch APIs via shlwapi */
#include <windows.h>
#include <shlwapi.h>
#define S_OK   0L
#define E_FAIL ((HRESULT)0x80004005L)
typedef long HRESULT;
__declspec(dllexport)
HRESULT PathCchCanonicalizeEx(wchar_t *pszPathOut, size_t cchPathOut,
                               const wchar_t *pszPathIn, unsigned long dwFlags) {
    if (!PathCanonicalizeW(pszPathOut, pszPathIn)) return E_FAIL;
    return S_OK;
}
__declspec(dllexport)
HRESULT PathCchRemoveFileSpec(wchar_t *pszPath, size_t cchPath) {
    PathRemoveFileSpecW(pszPath);
    return S_OK;
}
__declspec(dllexport)
HRESULT PathAllocCombine(const wchar_t *pszPathIn, const wchar_t *pszMore,
                          unsigned long dwFlags, wchar_t **ppszPathOut) {
    wchar_t buf[32768];
    if (!PathCombineW(buf, pszPathIn, pszMore)) return E_FAIL;
    size_t len = wcslen(buf) + 1;
    *ppszPathOut = (wchar_t*)LocalAlloc(LMEM_FIXED, len * sizeof(wchar_t));
    if (!*ppszPathOut) return E_FAIL;
    wmemcpy(*ppszPathOut, buf, len);
    return S_OK;
}
STUBEOF
  # Compile the stub and add it to the build sources list via meson's custom_target or by injecting object
  x86_64-w64-mingw32-gcc -c osdep/pathcch_stub.c \
    -I"$DIST/include" -D_WIN32_WINNT=0x0A00 -DWINVER=0x0A00 \
    -o osdep/pathcch_stub.c.obj
  # Inject the stub object into the meson build by adding it to extra_objects or link_args
  # We do this by passing it as a link argument since meson will pass it to the linker

  # Clean previous build dir to force full reconfiguration with updated cross-file
  rm -rf build
  meson setup build \
    --cross-file "$CROSS_FILE" \
    --prefix="$DIST" --libdir=lib \
    --buildtype=release \
    --default-library=shared \
    -Dlibmpv=true \
    -Dcplayer=false \
    -Dtests=false \
    -Dmanpage-build=disabled \
    -Dvulkan=disabled \
    -Dgl=disabled \
    -Dgl-win32=disabled \
    -Dgl-dxinterop=disabled \
    -Dd3d11=disabled \
    -Dd3d-hwaccel=disabled \
    -Dd3d9-hwaccel=disabled \
    -Ddirect3d=disabled \
    -Degl=disabled \
    -Degl-angle=disabled \
    -Degl-angle-lib=disabled \
    -Degl-angle-win32=disabled \
    -Dplain-gl=disabled \
    -Djpeg=disabled \
    -Dlua=disabled \
    -Dlibarchive=disabled \
    -Dlibbluray=disabled \
    -Duchardet=disabled \
    -Drubberband=enabled \
    -Dlcms2=disabled \
    -Dzimg=disabled \
    -Dwasapi=enabled \
    -Dc_args="-I$DIST/include $WIN_FLAGS" \
    -Dcpp_args="-I$DIST/include $WIN_FLAGS" \
    -Dc_link_args="-L$DIST/lib -L/usr/x86_64-w64-mingw32/lib -static-libgcc -static-libstdc++ -lstdc++ -lexpat -lpathcch -lavrt -ldwmapi -lgdi32 -limm32 -lntdll -lole32 -luser32 -lwinmm -lshlwapi -lshell32 -lsetupapi -lcfgmgr32 -lversion -lshcore" \
    -Dcpp_link_args="-L$DIST/lib -L/usr/x86_64-w64-mingw32/lib -static-libgcc -static-libstdc++ -lexpat -lpathcch -lavrt -ldwmapi -lgdi32 -limm32 -lntdll -lole32 -luser32 -lwinmm -lshlwapi -lshell32 -lsetupapi -lcfgmgr32 -lversion -lshcore"
  
  ninja -C build install
popd
ok "mpv ✓"

# ── Finalize ──────────────────────────────────────────────────────────────────
release_dir="$ROOT/release_builds"
mkdir -p "$release_dir"
cp "$DIST/bin/libmpv-2.dll" "$release_dir/libmpv_windows-x86_64.dll"

log "=== Build libmpv for Windows COMPLETED! ==="
log "Artifacts in: $release_dir/libmpv_windows-x86_64.dll"
