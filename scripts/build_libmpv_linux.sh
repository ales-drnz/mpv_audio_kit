#!/usr/bin/env bash
# =============================================================================
# build_libmpv_linux.sh
#
# Compiles mpv 0.41.0 with all dependencies linked statically.
#
# === OUTPUT FORMATS AND LOCATIONS ===
# Target Dir:  linux/libs/
# Output File: libmpv.so.2 (Shared Library dynamically linked only to glibc)
#
# === SYSTEM & HARDWARE SPECS ===
# Target OS:   Linux (Tested on Ubuntu/Debian, Fedora, Arch)
# Target Arch: x86_64 or aarch64 (Depends on host machine architecture)
# Compiler:    GNU GCC / Clang
#
# Usage (from project root, on a Linux x86_64 machine):
#   chmod +x scripts/build_libmpv_linux.sh
#   ./scripts/build_libmpv_linux.sh
#
# Options:
#   ARCH=x86_64|aarch64    (default: machine's arch)
#   MPV_VERSION=0.41.0
#   JOBS=N
#   SKIP_DOWNLOAD=1
#   KEEP_BUILD=1
#
# Requirements (automatically installed on Debian/Ubuntu):
#   build-essential, cmake, ninja-build, nasm, meson, python3, pkg-config,
#   autoconf, automake, libtool, git, curl, libva-dev, libvdpau-dev,
#   libasound2-dev, libpulse-dev
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
OUTPUT_DIR="$ROOT/linux/libs"

MPV_VERSION="${MPV_VERSION:-0.41.0}"
JOBS="${JOBS:-$(nproc)}"
ARCH="${ARCH:-$(uname -m)}"

# Dependency versions
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
LIBBLURAY_VERSION="1.3.4"
MUJS_VERSION="1.3.6"
LUAJIT_COMMIT="v2.1"
ZIMG_VERSION="3.0.5"
JPEG_TURBO_VERSION="3.1.0"
SPEEX_DSP_VERSION="1.2.1"
LIBPLACEBO_VERSION="7.349.0"
MBEDTLS_VERSION="3.6.0"
VULKAN_HEADERS_VERSION="1.4.309"
SHADERC_VERSION="2024.3"
GLSLANG_VERSION="15.1.0"
SPIRV_TOOLS_VERSION="2024.4"
SPIRV_CROSS_VERSION="vulkan-sdk-1.4.309.0"
SPIRV_HEADERS_VERSION="vulkan-sdk-1.4.309.0"

BUILD_DIR="${BUILD_DIR:-$ROOT/build-linux}"
PREFIX="$BUILD_DIR/prefix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $*${NC}" >&2; }
ok()   { echo -e "${GREEN}✓ $*${NC}" >&2; }
warn() { echo -e "${YELLOW}⚠ $*${NC}" >&2; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

# ── System check ─────────────────────────────────────────────────────────────
check_tools() {
  [[ "$(uname)" != "Linux" ]] && fail "This script must be run on Linux"
  log "Installing build dependencies..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y \
      build-essential cmake ninja-build nasm python3 python3-pip \
      pkg-config autoconf automake libtool git curl \
      libva-dev libvdpau-dev \
      libasound2-dev libpulse-dev \
      libx11-dev libxext-dev libxrandr-dev libxinerama-dev \
      zlib1g-dev 2>/dev/null || true
    pip3 install meson --quiet 2>/dev/null || sudo pip3 install meson --quiet 2>/dev/null || true
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y \
      gcc gcc-c++ cmake ninja-build nasm python3 python3-pip \
      pkg-config autoconf automake libtool git curl \
      libva-devel libvdpau-devel \
      alsa-lib-devel pulseaudio-libs-devel \
      libX11-devel libXext-devel libXrandr-devel \
      zlib-devel 2>/dev/null || true
    pip3 install meson --quiet 2>/dev/null || true
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --needed --noconfirm \
      base-devel cmake ninja nasm python python-pip \
      pkg-config autoconf automake libtool git curl \
      libva libvdpau alsa-lib libpulse \
      libx11 libxext libxrandr 2>/dev/null || true
    pip3 install meson --quiet 2>/dev/null || true
  fi

  local missing=()
  for t in meson ninja nasm cmake pkg-config python3 git curl; do
    command -v "$t" &>/dev/null || missing+=("$t")
  done
  [[ ${#missing[@]} -gt 0 ]] && fail "Missing tools: ${missing[*]}"
  ok "Tools OK"
}

# ── Download helpers ─────────────────────────────────────────────────────────
download() {
  local url="$1" dest="$2"
  [[ "${SKIP_DOWNLOAD:-0}" == "1" && -f "$dest" ]] && { ok "Skip: $(basename "$dest")"; return; }
  log "Download: $(basename "$dest")"
  curl -fsSL --retry 3 -o "$dest" "$url" || fail "Download fallito: $url"
}

download_git() {
  local url="$1" dest="$2" tag="${3:-}"
  [[ "${SKIP_DOWNLOAD:-0}" == "1" && -d "$dest/.git" ]] && { ok "Skip git: $(basename "$dest")"; return; }
  log "Git clone: $(basename "$dest")"
  rm -rf "$dest"
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

# ── Meson cross-file (only if necessary) ──────────────────────────────────────
write_meson_native() {
  local file="$BUILD_DIR/meson_native.ini"
  touch "$file"
  echo "$file"
}

# =============================================================================
# Library builds
# =============================================================================
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig"
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig"
export CFLAGS="-O2 -fPIC"
export CXXFLAGS="-O2 -fPIC"
export LDFLAGS="-L$PREFIX/lib"

build_zlib() {
  [[ -f "$PREFIX/lib/libz.a" ]] && return
  local src="$BUILD_DIR/src/zlib-$ZLIB_VERSION.tar.gz"
  download "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  ./configure --prefix="$PREFIX" --static
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "zlib ✓"
}

build_bzip2() {
  [[ -f "$PREFIX/lib/libbz2.a" ]] && return
  local src="$BUILD_DIR/src/bzip2-$BZIP2_VERSION.tar.gz"
  download "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make -j"$JOBS" CFLAGS="-O2 -fPIC -D_FILE_OFFSET_BITS=64" libbz2.a
  install -m 644 libbz2.a "$PREFIX/lib/"
  install -m 644 bzlib.h  "$PREFIX/include/"
  popd >/dev/null
  ok "bzip2 ✓"
}

build_xz() {
  [[ -f "$PREFIX/lib/liblzma.a" ]] && return
  local src="$BUILD_DIR/src/xz-$XZ_VERSION.tar.gz"
  download "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  ./configure --prefix="$PREFIX" --enable-static --disable-shared \
    --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-scripts --disable-doc
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "xz ✓"
}

build_expat() {
  [[ -f "$PREFIX/lib/libexpat.a" ]] && return
  local src="$BUILD_DIR/src/expat-$LIBEXPAT_VERSION.tar.gz"
  download "https://github.com/libexpat/libexpat/releases/download/R_$(echo "$LIBEXPAT_VERSION" | tr . _)/expat-${LIBEXPAT_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  ./configure --prefix="$PREFIX" --enable-static --disable-shared --without-docbook --without-examples --without-tests
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "expat ✓"
}

build_libpng() {
  [[ -f "$PREFIX/lib/libpng.a" ]] && return
  local src="$BUILD_DIR/src/libpng-$LIBPNG_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  ./configure --prefix="$PREFIX" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libpng ✓"
}

build_freetype() {
  [[ -f "$PREFIX/lib/libfreetype.a" ]] && return
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE_VERSION}/freetype-${FREETYPE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/freetype-r1"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF -DFT_DISABLE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON -DZLIB_INCLUDE_DIR="$PREFIX/include" -DZLIB_LIBRARY="$PREFIX/lib/libz.a" -DPNG_PNG_INCLUDE_DIR="$PREFIX/include" -DPNG_LIBRARY="$PREFIX/lib/libpng.a" -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "freetype r1 ✓"
}

build_fribidi() {
  [[ -f "$PREFIX/lib/libfribidi.a" ]] && return
  local src="$BUILD_DIR/src/fribidi-$FRIBIDI_VERSION.tar.gz"
  download "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fribidi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" --prefix="$PREFIX" --buildtype=release --default-library=static -Ddocs=false -Dtests=false
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "fribidi ✓"
}

build_harfbuzz() {
  [[ -f "$PREFIX/lib/libharfbuzz.a" ]] && return
  local src="$BUILD_DIR/src/harfbuzz-$HARFBUZZ_VERSION.tar.gz"
  download "https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VERSION}/harfbuzz-${HARFBUZZ_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/harfbuzz"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Dfreetype=enabled -Dglib=disabled -Dgobject=disabled -Dicu=disabled -Dtests=disabled -Ddocs=disabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "harfbuzz ✓"
}

build_freetype_round2() {
  [[ -f "$PREFIX/.ft_round2" ]] && return
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  rm -rf "$BUILD_DIR/build/freetype-r1"
  local bdir="$BUILD_DIR/build/freetype-r2"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_HARFBUZZ=OFF -DFT_REQUIRE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON \
    -DZLIB_INCLUDE_DIR="$PREFIX/include" -DZLIB_LIBRARY="$PREFIX/lib/libz.a" \
    -DPNG_PNG_INCLUDE_DIR="$PREFIX/include" -DPNG_LIBRARY="$PREFIX/lib/libpng.a" \
    -DHarfBuzz_DIR="$PREFIX/lib/cmake/harfbuzz" -GNinja
  ninja -j"$JOBS"; ninja install
  touch "$PREFIX/.ft_round2"
  popd >/dev/null
  ok "freetype r2 ✓"
}

build_fontconfig() {
  [[ -f "$PREFIX/lib/libfontconfig.a" ]] && return
  local src="$BUILD_DIR/src/fontconfig-$FONTCONFIG_VERSION.tar.xz"
  download "https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fontconfig"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Dtests=disabled -Dtools=disabled -Ddoc=disabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "fontconfig ✓"
}

build_libass() {
  [[ -f "$PREFIX/lib/libass.a" ]] && return
  local src="$BUILD_DIR/src/libass-$LIBASS_VERSION.tar.gz"
  download "https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  ./configure --prefix="$PREFIX" --enable-static --disable-shared \
    --disable-require-system-font-provider --with-pic --enable-asm
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libass ✓"
}

build_jpeg_turbo() {
  [[ -f "$PREFIX/lib/libjpeg.a" ]] && return
  local src="$BUILD_DIR/src/libjpeg-turbo-$JPEG_TURBO_VERSION.tar.gz"
  download "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${JPEG_TURBO_VERSION}/libjpeg-turbo-${JPEG_TURBO_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/jpeg-turbo"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_STATIC=ON -DENABLE_SHARED=OFF -DWITH_TURBOJPEG=OFF -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "jpeg-turbo ✓"
}

build_speexdsp() {
  [[ -f "$PREFIX/lib/libspeexdsp.a" ]] && return
  local src="$BUILD_DIR/src/speexdsp-$SPEEX_DSP_VERSION.tar.gz"
  download "https://downloads.xiph.org/releases/speex/speexdsp-${SPEEX_DSP_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  ./configure --prefix="$PREFIX" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "speexdsp ✓"
}

build_rubberband() {
  [[ -f "$PREFIX/lib/librubberband.a" ]] && return
  local src="$BUILD_DIR/src/rubberband-$RUBBERBAND_VERSION.tar.bz2"
  download "https://breakfastquay.com/files/releases/rubberband-${RUBBERBAND_VERSION}.tar.bz2" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/rubberband"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Dfft=builtin -Dresampler=speex -Dladspa=disabled -Dvamp=disabled -Djni=disabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "rubberband ✓"
}

build_uchardet() {
  [[ -f "$PREFIX/lib/libuchardet.a" ]] && return
  local src="$BUILD_DIR/src/uchardet-$UCHARDET_VERSION.tar.gz"
  download "https://www.freedesktop.org/software/uchardet/releases/uchardet-${UCHARDET_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/uchardet"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_STATIC=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_BINARY=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "uchardet ✓"
}

build_lcms2() {
  [[ -f "$PREFIX/lib/liblcms2.a" ]] && return
  local src="$BUILD_DIR/src/lcms2-$LCMS2_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/lcms/lcms/${LCMS2_VERSION}/lcms2-${LCMS2_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  ./configure --prefix="$PREFIX" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "lcms2 ✓"
}

build_libarchive() {
  [[ -f "$PREFIX/lib/libarchive.a" ]] && return
  local src="$BUILD_DIR/src/libarchive-$LIBARCHIVE_VERSION.tar.gz"
  download "https://github.com/libarchive/libarchive/releases/download/v${LIBARCHIVE_VERSION}/libarchive-${LIBARCHIVE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="-O2 -fPIC -I$PREFIX/include" LDFLAGS="-L$PREFIX/lib" \
  ./configure --prefix="$PREFIX" --enable-static --disable-shared \
    --with-zlib --with-bz2lib --with-liblzma --without-nettle --without-openssl --without-xml2 --without-expat
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libarchive ✓"
}

build_libbluray() {
  [[ -f "$PREFIX/lib/libbluray.a" ]] && return
  local src="$BUILD_DIR/src/libbluray-$LIBBLURAY_VERSION.tar.bz2"
  download "https://download.videolan.org/pub/videolan/libbluray/${LIBBLURAY_VERSION}/libbluray-${LIBBLURAY_VERSION}.tar.bz2" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  [[ ! -f configure ]] && autoreconf -fiv
  ./configure --prefix="$PREFIX" --enable-static --disable-shared \
    --disable-examples --disable-bdjava-jar --disable-udf --without-libxml2 --without-fontconfig
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libbluray ✓"
}

build_mujs() {
  [[ -f "$PREFIX/lib/libmujs.a" ]] && return
  local gitdir="$BUILD_DIR/src/mujs-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://github.com/ccxvii/mujs.git" "$gitdir" "$MUJS_VERSION"
  pushd "$gitdir" >/dev/null
  make clean 2>/dev/null || true
  make -j"$JOBS" CFLAGS="-O2 -fPIC" prefix="$PREFIX" install-static
  popd >/dev/null
  ok "mujs ✓"
}

build_luajit() {
  [[ -f "$PREFIX/lib/libluajit-5.1.a" ]] && return
  local gitdir="$BUILD_DIR/src/luajit-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://github.com/LuaJIT/LuaJIT.git" "$gitdir" "$LUAJIT_COMMIT"
  pushd "$gitdir" >/dev/null
  make clean 2>/dev/null || true
  make -j"$JOBS" CFLAGS="-O2 -fPIC" PREFIX="$PREFIX" install
  popd >/dev/null
  ok "luajit ✓"
}

build_zimg() {
  [[ -f "$PREFIX/lib/libzimg.a" ]] && return
  local src="$BUILD_DIR/src/zimg-$ZIMG_VERSION.tar.gz"
  download "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-${ZIMG_VERSION}.tar.gz" "$src"
  extract "$src" "$BUILD_DIR/src" >/dev/null
  local dir; dir="$(ls -d "$BUILD_DIR/src/zimg-"* 2>/dev/null | tail -1)"
  pushd "$dir" >/dev/null
  [[ ! -f configure ]] && autoreconf -fiv
  CFLAGS="-O2 -fPIC" CXXFLAGS="-O2 -fPIC" \
  ./configure --prefix="$PREFIX" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "zimg ✓"
}

build_spirv_headers() {
  [[ -d "$PREFIX/include/spirv" ]] && return
  local gitdir="$BUILD_DIR/src/spirv-headers-git"
  download_git "https://github.com/KhronosGroup/SPIRV-Headers.git" "$gitdir" "$SPIRV_HEADERS_VERSION"
  local bdir="$BUILD_DIR/build/spirv-headers"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$gitdir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -GNinja
  ninja install
  popd >/dev/null
  ok "SPIRV-Headers ✓"
}

build_spirv_tools() {
  [[ -f "$PREFIX/lib/libSPIRV-Tools.a" ]] && return
  local gitdir="$BUILD_DIR/src/spirv-tools-git"
  download_git "https://github.com/KhronosGroup/SPIRV-Tools.git" "$gitdir" "$SPIRV_TOOLS_VERSION"
  local bdir="$BUILD_DIR/build/spirv-tools"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$gitdir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF -DSPIRV_SKIP_TESTS=ON -DSPIRV_SKIP_EXECUTABLES=ON \
    -DSPIRV-Headers_SOURCE_DIR="$BUILD_DIR/src/spirv-headers-git" -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "SPIRV-Tools ✓"
}

build_spirv_cross() {
  [[ -f "$PREFIX/lib/libspirv-cross-core.a" ]] && return
  local gitdir="$BUILD_DIR/src/spirv-cross-git"
  download_git "https://github.com/KhronosGroup/SPIRV-Cross.git" "$gitdir" "$SPIRV_CROSS_VERSION"
  local bdir="$BUILD_DIR/build/spirv-cross"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$gitdir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DSPIRV_CROSS_SHARED=OFF -DSPIRV_CROSS_STATIC=ON -DSPIRV_CROSS_CLI=OFF \
    -DSPIRV_CROSS_ENABLE_TESTS=OFF -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "SPIRV-Cross ✓"
}

build_glslang() {
  [[ -f "$PREFIX/lib/libglslang.a" ]] && return
  local gitdir="$BUILD_DIR/src/glslang-git"
  download_git "https://github.com/KhronosGroup/glslang.git" "$gitdir" "$GLSLANG_VERSION"
  local bdir="$BUILD_DIR/build/glslang"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$gitdir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF -DENABLE_CTEST=OFF \
    -DSPIRV_HEADERS_INCLUDE_DIR="$PREFIX/include" -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "glslang ✓"
}

build_shaderc() {
  [[ -f "$PREFIX/lib/libshaderc_combined.a" ]] && return
  local gitdir="$BUILD_DIR/src/shaderc-git"
  download_git "https://github.com/google/shaderc.git" "$gitdir" "v$SHADERC_VERSION"
  rm -rf "$gitdir/third_party/glslang" "$gitdir/third_party/spirv-tools" "$gitdir/third_party/spirv-headers"
  ln -sf "$BUILD_DIR/src/glslang-git"       "$gitdir/third_party/glslang"
  ln -sf "$BUILD_DIR/src/spirv-tools-git"   "$gitdir/third_party/spirv-tools"
  ln -sf "$BUILD_DIR/src/spirv-headers-git" "$gitdir/third_party/spirv-headers"
  local bdir="$BUILD_DIR/build/shaderc"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$gitdir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DSHADERC_SKIP_TESTS=ON -DSHADERC_SKIP_EXAMPLES=ON -DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
    -DBUILD_SHARED_LIBS=OFF -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "shaderc ✓"
}

build_vulkan_headers() {
  [[ -f "$PREFIX/include/vulkan/vulkan.h" ]] && return
  local gitdir="$BUILD_DIR/src/vulkan-headers-git"
  download_git "https://github.com/KhronosGroup/Vulkan-Headers.git" "$gitdir" "v$VULKAN_HEADERS_VERSION"
  local bdir="$BUILD_DIR/build/vulkan-headers"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$gitdir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -GNinja
  ninja install
  popd >/dev/null
  ok "Vulkan-Headers ✓"
}

build_libplacebo() {
  [[ -f "$PREFIX/lib/libplacebo.a" ]] && return
  local gitdir="$BUILD_DIR/src/libplacebo-git"
  download_git "https://code.videolan.org/videolan/libplacebo.git" "$gitdir" "v$LIBPLACEBO_VERSION"
  local bdir="$BUILD_DIR/build/libplacebo"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$gitdir" --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Dvulkan=enabled -Dshaderc=enabled -Dglslang=enabled \
    -Dvulkan-registry="$PREFIX/share/vulkan/registry/vk.xml" \
    -Ddemos=false -Dtests=false
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "libplacebo ✓"
}

build_mbedtls() {
  [[ -f "$PREFIX/lib/libmbedtls.a" ]] && return
  local src="$BUILD_DIR/src/mbedtls-$MBEDTLS_VERSION.tar.bz2"
  download "https://github.com/Mbed-TLS/mbedtls/releases/download/v${MBEDTLS_VERSION}/mbedtls-${MBEDTLS_VERSION}.tar.bz2" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/mbedtls"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF \
    -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DUSE_STATIC_MBEDTLS_LIBRARY=ON \
    -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "mbedtls ✓"
}

build_ffmpeg() {
  [[ -f "$PREFIX/lib/libavcodec.a" ]] && return
  log "Building ffmpeg $FFMPEG_VERSION..."
  local src="$BUILD_DIR/src/ffmpeg-$FFMPEG_VERSION.tar.gz"
  download "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/ffmpeg"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig" \
  "$dir/configure" \
    --prefix="$PREFIX" \
    --enable-static --disable-shared \
    --disable-programs --disable-doc --disable-debug \
    --enable-pthreads \
    --enable-avcodec --enable-avfilter --enable-avformat \
    --enable-avutil --enable-avdevice --enable-swresample --enable-swscale \
    --enable-protocols --enable-demuxers --enable-decoders --enable-filters \
    --disable-outdevs \
    --enable-zlib --enable-bzlib --enable-lzma \
    --enable-iconv \
    --enable-network --enable-mbedtls --enable-version3 --disable-openssl \
    --disable-sdl2
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "ffmpeg ✓"
}

build_mpv() {
  [[ -f "$PREFIX/lib/libmpv.so" ]] && return
  log "Building mpv $MPV_VERSION..."
  local src="$BUILD_DIR/src/mpv-$MPV_VERSION.tar.gz"
  download "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/mpv"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  python3 -c "
import sys, re
with open('../../src/mpv-$MPV_VERSION/meson.build', 'r') as f: content = f.read()
content = re.sub(
    r\"libplacebo = dependency\('libplacebo',\s*version: '[^']*',\n\s*default_options: \['default_library=static', 'demos=false'\]\)\",
    \"libplacebo = dependency('libplacebo', version: '>=6.338.2', required: false)\",
    content
)
content = content.replace(\"libass = dependency('libass', version: '>= 0.12.2')\", \"libass = dependency('libass', version: '>= 0.12.2', required: false)\")
with open('../../src/mpv-$MPV_VERSION/meson.build', 'w') as f: f.write(content)
"
  PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig" \
  meson setup "$dir" \
    --prefix="$PREFIX" \
    --buildtype=release \
    --default-library=shared \
    -Dlibmpv=true \
    -Dcplayer=false \
    -Dbuild-date=false \
    -Dtests=false \
    -Dmanpage-build=disabled \
    -Dhtml-build=disabled \
    -Dffmpeg=enabled \
    -Dvulkan=disabled \
    -Dgl=disabled \
    -Dsdl2=disabled \
    -Dlua=luajit \
    -Djavascript=enabled \
    -Drubberband=enabled \
    -Duchardet=disabled \
    -Dlcms2=disabled \
    -Dlibarchive=enabled \
    -Dlibbluray=disabled \
    -Dzimg=disabled \
    -Dalsa=enabled \
    -Dpulse=enabled \
    -Dx11=disabled \
    -Dwayland=disabled \
    -Ddrm=disabled \
    -Dplain-gl=disabled \
    -Degl-drm=disabled \
    -Degl-wayland=disabled \
    -Degl-x11=disabled \
    -Dcocoa=disabled \
    -Davfoundation=disabled \
    -Dcoreaudio=disabled \
    -Daudiounit=disabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "mpv ✓"
}

# ── Finalization ──────────────────────────────────────────────────────────────
finalize() {
  mkdir -p "$OUTPUT_DIR"
  local src="$PREFIX/lib/libmpv.so"
  [[ ! -f "$src" ]] && src="$(ls "$PREFIX/lib/libmpv.so."* 2>/dev/null | tail -1)"
  [[ ! -f "$src" ]] && fail "libmpv.so not found in $PREFIX/lib/"

  cp "$src" "$OUTPUT_DIR/libmpv.so.2"
  # Create symlink libmpv.so → libmpv.so.2
  ln -sf "libmpv.so.2" "$OUTPUT_DIR/libmpv.so"
  ok "Output: $OUTPUT_DIR/libmpv.so.2"

  log "Checking external dependencies..."
  local external
  external="$(ldd "$OUTPUT_DIR/libmpv.so.2" | grep -v 'linux-vdso\|libc\|libm\|libdl\|libpthread\|librt\|ld-linux\|libresolv' | grep '=> /' || true)"
  if [[ -n "$external" ]]; then
    warn "External dependencies found (expected: OK on Linux):"
    echo "$external"
  else
    ok "Minimal dependencies (glibc only)"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║   build_libmpv_linux.sh — mpv $MPV_VERSION for Linux x86_64    ║"
  echo "╚══════════════════════════════════════════════════════════════╝"

  check_tools
  mkdir -p "$BUILD_DIR/src" "$BUILD_DIR/build" "$PREFIX/include" "$PREFIX/lib"

  build_zlib; build_bzip2; build_xz; build_expat; build_libpng
  build_freetype; build_fribidi; build_harfbuzz; build_freetype_round2; build_fontconfig
  build_libass; build_speexdsp; build_rubberband
  build_libarchive
  build_mujs; build_luajit
  build_mbedtls; build_ffmpeg; build_libplacebo; build_mpv

  finalize

  [[ "${KEEP_BUILD:-0}" != "1" ]] && rm -rf "$BUILD_DIR" && ok "BUILD_DIR removed"

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  Linux build complete!                                       ║"
  echo "║  Output: linux/libs/libmpv.so.2                             ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
}

main "$@"
