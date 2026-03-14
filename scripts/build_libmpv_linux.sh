#!/usr/bin/env bash
# =============================================================================
# build_libmpv_linux.sh
#
# Compiles mpv 0.41.0 as libmpv.so for Linux x86_64 / aarch64,
# with all dependencies statically linked (only glibc remains dynamic).
#
# === OUTPUT ===
# release_builds/libmpv_linux-<arch>.so
#
# === SYSTEM ===
# Target OS:   Linux (Ubuntu 22.04+ / Debian 12+ / Fedora 39+ / Arch)
# Target Arch: x86_64 or aarch64 (auto-detected from host)
# Compiler:    GNU GCC
#
# Usage (from project root, on a Linux machine):
#   chmod +x scripts/build_libmpv_linux.sh
#   ./scripts/build_libmpv_linux.sh
#
# Options (env vars):
#   ARCH=x86_64|aarch64     (default: auto from uname -m)
#   MPV_VERSION=0.41.0      (default: 0.41.0)
#   JOBS=N                  (default: nproc)
#   SKIP_DOWNLOAD=1         (reuse cached tarballs)
#   KEEP_BUILD=1            (don't delete build dir after success)
#
# Requirements (auto-installed on Debian/Ubuntu):
#   build-essential, cmake, ninja-build, nasm, meson, python3,
#   pkg-config, autoconf, automake, libtool, git, curl,
#   libva-dev, libvdpau-dev, libasound2-dev, libpulse-dev, libx11-dev
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."

MPV_VERSION="${MPV_VERSION:-0.41.0}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"
ARCH="${ARCH:-x86_64}" # Default to x86_64, can be overridden by env var

# ── Dependency versions ────────────────────────────────────────────────────────
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
SPEEX_DSP_VERSION="1.2.1"
LIBPLACEBO_VERSION="7.349.0"
MBEDTLS_VERSION="3.6.0"

BUILD_DIR="${BUILD_DIR:-$ROOT/build-linux-$ARCH}"
PREFIX="$BUILD_DIR/prefix"

# ── Logging ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $*${NC}" >&2; }
ok()   { echo -e "${GREEN}✓ $*${NC}" >&2; }
warn() { echo -e "${YELLOW}⚠ $*${NC}" >&2; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

# ── System check & dependency install ─────────────────────────────────────────
check_tools() {
  [[ "$(uname)" != "Linux" ]] && fail "This script must be run on Linux"
  log "Installing build dependencies..."
  # In Docker we run as root — no sudo needed. On a host system sudo is used automatically.
  local SUDO=""; command -v sudo &>/dev/null && SUDO="sudo"
  if command -v apt-get &>/dev/null; then
    $SUDO apt-get update -qq
    $SUDO apt-get install -y \
      build-essential cmake ninja-build nasm python3 python3-pip \
      pkg-config autoconf automake libtool git curl gperf \
      libva-dev libvdpau-dev \
      libasound2-dev libpulse-dev \
      libx11-dev libxext-dev libxrandr-dev libxinerama-dev \
      zlib1g-dev 2>/dev/null || true
    pip3 install meson --quiet 2>/dev/null || \
      $SUDO pip3 install meson --quiet 2>/dev/null || true
  elif command -v dnf &>/dev/null; then
    $SUDO dnf install -y \
      gcc gcc-c++ cmake ninja-build nasm python3 python3-pip \
      pkg-config autoconf automake libtool git curl gperf \
      libva-devel libvdpau-devel \
      alsa-lib-devel pulseaudio-libs-devel \
      libX11-devel libXext-devel libXrandr-devel \
      zlib-devel 2>/dev/null || true
    pip3 install meson --quiet 2>/dev/null || true
  elif command -v pacman &>/dev/null; then
    $SUDO pacman -S --needed --noconfirm \
      base-devel cmake ninja nasm python python-pip \
      pkg-config autoconf automake libtool git curl gperf \
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

# ── Download helpers ───────────────────────────────────────────────────────────
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

# =============================================================================
# Build environment
# =============================================================================
# On Debian/Ubuntu, meson installs .pc files into the multiarch dir
# (e.g. lib/aarch64-linux-gnu/pkgconfig on arm64, lib/x86_64-linux-gnu/pkgconfig on x86_64).
# We must include it in PKG_CONFIG_PATH so that autoconf-based builds (libass, etc.)
# can resolve pkg-config dependencies like harfbuzz installed by meson.
MULTIARCH="$(gcc -print-multiarch 2>/dev/null || dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo "")"
MULTIARCH_PKG=""
[[ -n "$MULTIARCH" ]] && MULTIARCH_PKG=":$PREFIX/lib/$MULTIARCH/pkgconfig"

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig${MULTIARCH_PKG}"
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig${MULTIARCH_PKG}"
export CFLAGS="-O2 -fPIC"
export CXXFLAGS="-O2 -fPIC"
export LDFLAGS="-L$PREFIX/lib"

# =============================================================================
# Library builds
# =============================================================================

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
    --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo \
    --disable-scripts --disable-doc
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
  ./configure --prefix="$PREFIX" --enable-static --disable-shared \
    --without-docbook --without-examples --without-tests
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
  [[ -f "$PREFIX/lib/libfreetype.a" && ! -f "$PREFIX/.ft_round2" ]] && return
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE_VERSION}/freetype-${FREETYPE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"

  # Round 1: without HarfBuzz
  if [[ ! -f "$PREFIX/lib/libfreetype.a" ]]; then
    local bdir="$BUILD_DIR/build/freetype-r1"; mkdir -p "$bdir"
    pushd "$bdir" >/dev/null
    cmake "$dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF -DFT_DISABLE_HARFBUZZ=ON \
      -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON \
      -DFT_DISABLE_BROTLI=ON -DFT_DISABLE_BZIP2=ON \
      -DZLIB_INCLUDE_DIR="$PREFIX/include" -DZLIB_LIBRARY="$PREFIX/lib/libz.a" \
      -DPNG_PNG_INCLUDE_DIR="$PREFIX/include" -DPNG_LIBRARY="$PREFIX/lib/libpng.a" -GNinja
    ninja -j"$JOBS"; ninja install
    popd >/dev/null
    ok "freetype r1 ✓"
  fi
}

build_fribidi() {
  [[ -f "$PREFIX/lib/libfribidi.a" ]] && return
  local src="$BUILD_DIR/src/fribidi-$FRIBIDI_VERSION.tar.gz"
  download "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fribidi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Ddocs=false -Dtests=false
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
    -Dfreetype=enabled -Dglib=disabled -Dgobject=disabled -Dicu=disabled \
    -Dtests=disabled -Ddocs=disabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "harfbuzz ✓"
}

build_freetype_round2() {
  [[ -f "$PREFIX/.ft_round2" ]] && return
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  # Round 2: with HarfBuzz (for libass subpixel hinting)
  local bdir="$BUILD_DIR/build/freetype-r2"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_HARFBUZZ=OFF -DFT_REQUIRE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON \
    -DFT_DISABLE_BROTLI=ON -DFT_DISABLE_BZIP2=ON \
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
  # Disable EVERYTHING related to X11 to keep it portable
  meson setup "$dir" --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Dtests=disabled \
    -Dtools=disabled \
    -Ddoc=disabled \
    -Dcache-build=disabled
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

build_libplacebo() {
  # Build WITHOUT Vulkan — same as macOS and Android builds.
  # libplacebo is still useful for signal processing / filters even without GPU.
  [[ -f "$PREFIX/lib/libplacebo.a" ]] && return
  local gitdir="$BUILD_DIR/src/libplacebo-git"
  download_git "https://code.videolan.org/videolan/libplacebo.git" "$gitdir" "v$LIBPLACEBO_VERSION"
  # Init submodules (glad, etc.)
  git -C "$gitdir" submodule update --init --recursive
  local bdir="$BUILD_DIR/build/libplacebo"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig" \
  meson setup "$gitdir" --prefix="$PREFIX" --buildtype=release --default-library=static \
    -Dvulkan=disabled \
    -Dshaderc=disabled \
    -Dglslang=disabled \
    -Dopengl=disabled \
    -Dd3d11=disabled \
    -Ddemos=false \
    -Dtests=false
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
  # NOTE: No --enable-gpl here (we don't need rubberband via FFmpeg — mpv links it directly)
  # NOTE: mbedtls is safe on Linux (no GPL conflict unlike Windows cross-compile)
  # Extra aggressive disabling of anything that pulls system libs like X11 or VDPAU
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
    --enable-network --enable-mbedtls --enable-version3 \
    --disable-openssl \
    --disable-sdl2 \
    --disable-xlib \
    --disable-vaapi \
    --disable-vdpau \
    --disable-libxcb \
    --disable-libxcb-shm \
    --disable-libxcb-xfixes \
    --disable-libxcb-shape
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

  # ── Patch meson.build ──────────────────────────────────────────────────────
  python3 -c "
import re
with open('$dir/meson.build', 'r') as f: content = f.read()

# Make libplacebo optional (version string may differ from the one mpv expects)
content = re.sub(
    r\"libplacebo = dependency\('libplacebo',\s*version: '[^']*',\n\s*default_options: \['default_library=static', 'demos=false'\]\)\",
    \"libplacebo = dependency('libplacebo', version: '>=6.338.2', required: false)\",
    content
)
# Make libass optional as a safety net
content = content.replace(
    \"libass = dependency('libass', version: '>= 0.12.2')\",
    \"libass = dependency('libass', version: '>= 0.12.2', required: false)\"
)

with open('$dir/meson.build', 'w') as f: f.write(content)
"

  pushd "$bdir" >/dev/null
  # ── Check valid meson options for mpv 0.41.0 ──────────────────────────────
  # Validated options list (tested against mpv 0.41.0 meson.options):
  #   - lua=disabled  (not 'luajit' — that syntax is invalid in 0.41.0)
  #   - javascript=disabled (mujs not needed for audio-only library)
  #   - alsa=enabled, pulse=enabled for Linux audio
  #   - pipewire=auto (auto-detect PipeWire if present)
  #   - No cocoa/avfoundation/coreaudio/audiounit (macOS only)
  # mpv 0.41.0 validated options (cross-checked with macOS and Android builds):
  #   - No sdl2 (removed from mpv meson options in 0.41.0)
  #   - No egl (handled via egl-drm/wayland/x11 sub-options)
  #   - No gl-cocoa / gl-x11 (macOS/Linux specific, use gl-win32 for Windows)
  #   - No vaapi-x11 (use vaapi=disabled)
  #   - libarchive=disabled (iconv dep issues on some distros; not needed for audio)
  PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig${MULTIARCH_PKG}" \
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
    -Dvulkan=disabled \
    -Dgl=disabled \
    -Dplain-gl=disabled \
    -Degl-drm=disabled \
    -Degl-wayland=disabled \
    -Degl-x11=disabled \
    -Ddrm=disabled \
    -Dwayland=disabled \
    -Dx11=disabled \
    -Dvdpau=disabled \
    -Dvaapi=disabled \
    -Dlua=disabled \
    -Djavascript=disabled \
    -Drubberband=enabled \
    -Duchardet=disabled \
    -Dlcms2=disabled \
    -Dlibarchive=disabled \
    -Dlibbluray=disabled \
    -Dzimg=disabled \
    -Djpeg=disabled \
    -Dalsa=auto \
    -Dpulse=auto \
    -Dpipewire=auto \
    -Djack=disabled \
    -Dopenal=disabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "mpv ✓"
}

finalize() {
  local release_dir="$ROOT/release_builds"
  mkdir -p "$release_dir"

  log "Locating libmpv.so..."
  
  # libmpv.so might be in lib/ or lib/$MULTIARCH (e.g. lib/aarch64-linux-gnu/)
  local lib_paths=(
    "$PREFIX/lib"
    "$PREFIX/lib64"
    "$PREFIX/lib/$MULTIARCH"
  )
  
  local src=""
  for lp in "${lib_paths[@]}"; do
    if [[ -d "$lp" ]]; then
      # Try to find the versioned .so
      local found; found="$(ls "$lp"/libmpv.so.* 2>/dev/null | sort -V | tail -1 || true)"
      if [[ -z "$found" ]]; then
        found="$(ls "$lp"/libmpv.so 2>/dev/null || true)"
      fi
      
      if [[ -n "$found" && -f "$found" ]]; then
        src="$found"
        break
      fi
    fi
  done

  [[ -z "$src" ]] && fail "libmpv.so not found in any expected prefix/lib path."
  
  log "Found libmpv: $src"
  cp -P "$src" "$release_dir/libmpv_linux-$ARCH.so"
  # If it was a symlink, also copy the target
  if [[ -L "$src" ]]; then
    local target; target="$(readlink -f "$src")"
    cp "$target" "$release_dir/libmpv_linux-$ARCH.so"
  fi

  ok "Output: $release_dir/libmpv_linux-$ARCH.so"

  log "Checking external dependencies..."
  local external
  external="$(ldd "$release_dir/libmpv_linux-$ARCH.so" \
    | grep -v 'linux-vdso\|libc\|libm\|libdl\|libpthread\|librt\|ld-linux\|libresolv\|libgcc_s' \
    | grep '=>' || true)"
  if [[ -n "$external" ]]; then
    warn "External runtime dependencies (expected on Linux):"
    echo "$external"
  else
    ok "Minimal dependencies (glibc only)"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║  build_libmpv_linux.sh — mpv $MPV_VERSION for Linux ($ARCH)      ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
  echo ""

  check_tools
  mkdir -p "$BUILD_DIR/src" "$BUILD_DIR/build" "$PREFIX/include" "$PREFIX/lib"

  # ── Core compression / text libs ──
  build_zlib
  build_bzip2
  build_xz
  build_expat
  build_libpng

  # ── Font rendering stack ──
  build_freetype        # r1: without HarfBuzz
  build_fribidi
  build_harfbuzz
  build_freetype_round2 # r2: with HarfBuzz
  build_fontconfig
  build_libass

  # ── Audio processing ──
  build_speexdsp        # resampler used by rubberband
  build_rubberband      # pitch shifting / time-stretch

  # ── libplacebo (without Vulkan, same as macOS/Android) ──
  build_libplacebo

  # ── TLS + codec engine ──
  build_mbedtls
  build_ffmpeg

  # ── mpv itself ──
  build_mpv

  finalize

  [[ "${KEEP_BUILD:-0}" != "1" ]] && rm -rf "$BUILD_DIR" && ok "BUILD_DIR removed"

  echo ""
  echo "╔══════════════════════════════════════════════════════════════════╗"
  echo "║  ✓ Linux build complete!                                         ║"
  echo "║  Output: release_builds/libmpv_linux-$ARCH.so                   ║"
  echo "╚══════════════════════════════════════════════════════════════════╝"
}

main "$@"
