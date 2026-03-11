#!/usr/bin/env bash
# =============================================================================
# build_libmpv_macos.sh
#
# Compiles mpv 0.41.0 with all dependencies linked statically.
#
# === OUTPUT FORMATS AND LOCATIONS ===
# Target Dir:  macos/libs/
# Output File: libmpv.dylib (Dynamic Library with @rpath install name)
#
# === SYSTEM & HARDWARE SPECS ===
# Target OS:   macOS (Deployment target 11.0+)
# Target Arch: arm64 (Apple Silicon) and/or x86_64 (Intel), optionally Universal Binary
# Compiler:    Xcode Toolchain (Apple Clang)
#
# Usage:
#   chmod +x scripts/build_libmpv_macos.sh
#   ./scripts/build_libmpv_macos.sh
#
# Options (environment variables):
#   ARCH=arm64|x86_64|universal   (default: current machine's arch)
#   MPV_VERSION=0.41.0            (default: 0.41.0)
#   JOBS=N                        (default: number of cores)
#   SKIP_DOWNLOAD=1               (skips download if sources already exist)
#   KEEP_BUILD=1                  (does not delete BUILD_DIR at the end)
#
# Requirements (installed by this script if missing via Homebrew):
#   meson, ninja, nasm, cmake, pkg-config, python3, autoconf, automake, libtool
# =============================================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
OUTPUT_DIR="$ROOT/macos/libs"

MPV_VERSION="${MPV_VERSION:-0.41.0}"
JOBS="${JOBS:-$(sysctl -n hw.logicalcpu)}"
HOST_ARCH="$(uname -m)"  # arm64 or x86_64
ARCH="${ARCH:-$HOST_ARCH}"

# Dependency versions
FFMPEG_VERSION="7.1.1"
LIBEXPAT_VERSION="2.7.1"
ZLIB_VERSION="1.3.1"
BZIP2_VERSION="1.0.8"
XZ_VERSION="5.6.4"
FRIBIDI_VERSION="1.0.16"
FREETYPE_VERSION="2.13.3"
HARFBUZZ_VERSION="10.4.0"
LIBPNG_VERSION="1.6.47"
FONTCONFIG_VERSION="2.15.0"
LIBASS_VERSION="0.17.3"
LIBPLACEBO_VERSION="7.349.0"
RUBBERBAND_VERSION="3.3.0"
LIBARCHIVE_VERSION="3.7.7"
MUJS_VERSION="1.3.6"
LUAJIT_COMMIT="v2.1"
SPEEX_DSP_VERSION="1.2.1"
SAMPLERATE_VERSION="0.2.2"

# ── Build directory ──────────────────────────────────────────────────────────
BUILD_DIR="${BUILD_DIR:-$ROOT/build-macos}"
PREFIX_BASE="$BUILD_DIR/prefix"

# For universal build, we'll use two separate prefixes then merge them
if [[ "$ARCH" == "universal" ]]; then
  PREFIX_ARM="$PREFIX_BASE/arm64"
  PREFIX_X86="$PREFIX_BASE/x86_64"
  PREFIX="$PREFIX_ARM"  # default for the main phase
else
  PREFIX="$PREFIX_BASE/$ARCH"
fi

mkdir -p "$BUILD_DIR/src" "$OUTPUT_DIR"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $*${NC}" >&2; }
ok()   { echo -e "${GREEN}✓ $*${NC}" >&2; }
warn() { echo -e "${YELLOW}⚠ $*${NC}" >&2; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

# ── Check requirements ───────────────────────────────────────────────────────
check_tools() {
  log "Checking necessary tools..."
  local missing=()
  for tool in meson ninja nasm cmake pkg-config python3 autoconf automake libtool git; do
    command -v "$tool" &>/dev/null || missing+=("$tool")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Missing tools: ${missing[*]}"
    if command -v brew &>/dev/null; then
      log "Installing with Homebrew..."
      brew install "${missing[@]}" 2>/dev/null || true
    else
      fail "Homebrew not found. Install manually: ${missing[*]}"
    fi
  fi
  ok "All tools present"
}

# ── Download helper ──────────────────────────────────────────────────────────
download() {
  local url="$1" dest="$2"
  if [[ "${SKIP_DOWNLOAD:-0}" == "1" && -f "$dest" ]]; then
    ok "Skip download: $(basename "$dest")"
    return
  fi
  log "Download: $(basename "$dest")"
  curl -fsSL --retry 3 -o "$dest" "$url" || fail "Download fallito: $url"
}

download_git() {
  local url="$1" dest="$2" tag="${3:-}"
  if [[ "${SKIP_DOWNLOAD:-0}" == "1" && -d "$dest/.git" ]]; then
    ok "Skip git clone: $(basename "$dest")"
    return
  fi
  log "Git clone: $(basename "$dest")"
  if [[ -n "$tag" ]]; then
    git clone --depth=1 --branch "$tag" "$url" "$dest" 2>/dev/null \
      || { rm -rf "$dest"; git clone --depth=1 "$url" "$dest"; }
  else
    git clone --depth=1 "$url" "$dest"
  fi
}

# ── Extract archive helper ───────────────────────────────────────────────────
extract() {
  local archive="$1" dest_parent="$2"
  local name
  name="$(basename "$archive" | sed 's/\.tar\..*//' | sed 's/\.tgz//')"
  if [[ -d "$dest_parent/$name" ]]; then
    ok "Already extracted: $name"
    echo "$dest_parent/$name"
    return
  fi
  log "Extracting: $name"
  tar -xf "$archive" -C "$dest_parent"
  echo "$dest_parent/$name"
}

# ── CFLAGS/LDFLAGS base per architettura ────────────────────────────────────
arch_flags() {
  local arch="$1"
  local macos_min="11.0"
  local sdk
  sdk="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || echo "")"
  local sdk_flags=""
  [[ -n "$sdk" ]] && sdk_flags="-isysroot $sdk"

  echo "-arch $arch -mmacosx-version-min=$macos_min $sdk_flags"
}

build_for_arch() {
  local arch="$1"
  local prefix="$PREFIX_BASE/$arch"
  mkdir -p "$prefix"
  export PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$prefix/lib64/pkgconfig"
  export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig:$prefix/lib64/pkgconfig"
  
  local cflags
  cflags="$(arch_flags "$arch") -O2"
  local ldflags
  ldflags="$(arch_flags "$arch")"

  export CFLAGS="$cflags"
  export CXXFLAGS="$cflags"
  export LDFLAGS="$ldflags"
  export CC="clang"
  export CXX="clang++"

  # ── zlib ──────────────────────────────────────────────────────────────────
  build_zlib "$arch" "$prefix"

  # ── bzip2 ─────────────────────────────────────────────────────────────────
  build_bzip2 "$arch" "$prefix"

  # ── xz/liblzma ────────────────────────────────────────────────────────────
  build_xz "$arch" "$prefix"
build_libpng() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libpng.a" ]] && { ok "libpng già compilato ($arch)"; return; }
  log "Build libpng $LIBPNG_VERSION ($arch)..."
  local src="$BUILD_DIR/src/libpng-$LIBPNG_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="$(arch_flags "$arch") -O2" \
  LDFLAGS="$(arch_flags "$arch")" \
  ./configure --prefix="$prefix" \
    --enable-static --disable-shared \
    --with-zlib-prefix="$prefix"
  make -j"$JOBS"
  make install
  popd >/dev/null
  ok "libpng ($arch) ✓"
}

build_freetype() {
  local arch="$1" prefix="$2"
  # Prima passata: senza harfbuzz (bootstrap)
  [[ -f "$prefix/lib/libfreetype.a" ]] && { ok "freetype già compilato ($arch)"; return; }
  log "Build freetype $FREETYPE_VERSION ($arch) [round 1 — senza harfbuzz]..."
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE_VERSION}/freetype-${FREETYPE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/freetype-r1-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_HARFBUZZ=ON \
    -DFT_DISABLE_BZIP2=OFF \
    -DFT_REQUIRE_ZLIB=ON \
    -DFT_REQUIRE_PNG=ON \
    -DZLIB_ROOT="$prefix" \
    -DPNG_ROOT="$prefix" \
    -GNinja
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null
  ok "freetype round1 ($arch) ✓"
}

build_fribidi() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libfribidi.a" ]] && { ok "fribidi già compilato ($arch)"; return; }
  log "Build fribidi $FRIBIDI_VERSION ($arch)..."
  local src="$BUILD_DIR/src/fribidi-$FRIBIDI_VERSION.tar.gz"
  download "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz" "$src"
  # fribidi usa .tar.xz, rinominiamo per l'estrazione
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fribidi-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=static \
    -Ddocs=false \
    -Dtests=false \
    $(write_meson_cross "$arch" "$prefix")
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null
  ok "fribidi ($arch) ✓"
}

build_harfbuzz() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libharfbuzz.a" ]] && { ok "harfbuzz già compilato ($arch)"; return; }
  log "Build harfbuzz $HARFBUZZ_VERSION ($arch)..."
  local src="$BUILD_DIR/src/harfbuzz-$HARFBUZZ_VERSION.tar.gz"
  download "https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VERSION}/harfbuzz-${HARFBUZZ_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/harfbuzz-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=static \
    -Dfreetype=enabled \
    -Dglib=disabled \
    -Dgobject=disabled \
    -Dicu=disabled \
    -Dtests=disabled \
    -Ddocs=disabled \
    $(write_meson_cross "$arch" "$prefix")
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null
  ok "harfbuzz ($arch) ✓"
}

build_freetype_round2() {
  local arch="$1" prefix="$2"
  # Seconda passata con harfbuzz abilitato
  local sentinel="$prefix/lib/freetype_harfbuzz_done_$arch"
  [[ -f "$sentinel" ]] && { ok "freetype round2 già compilato ($arch)"; return; }
  log "Build freetype $FREETYPE_VERSION ($arch) [round 2 — con harfbuzz]..."
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  # rimuovi la build precedente
  rm -rf "$BUILD_DIR/build/freetype-r1-$arch"
  local bdir="$BUILD_DIR/build/freetype-r2-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_HARFBUZZ=OFF \
    -DFT_REQUIRE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON \
    -DFT_REQUIRE_PNG=ON \
    -DZLIB_ROOT="$prefix" \
    -DPNG_ROOT="$prefix" \
    -DHarfBuzz_DIR="$prefix/lib/cmake/harfbuzz" \
    -GNinja
  ninja -j"$JOBS"
  ninja install
  touch "$sentinel"
  popd >/dev/null
  ok "freetype round2 ($arch) ✓"
}

build_fontconfig() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libfontconfig.a" ]] && { ok "fontconfig già compilato ($arch)"; return; }
  log "Build fontconfig $FONTCONFIG_VERSION ($arch)..."
  local src="$BUILD_DIR/src/fontconfig-$FONTCONFIG_VERSION.tar.xz"
  download "https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fontconfig-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=static \
    -Dtests=disabled \
    -Dtools=disabled \
    -Ddoc=disabled \
    $(write_meson_cross "$arch" "$prefix")
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null
  ok "fontconfig ($arch) ✓"
}

build_libass() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libass.a" ]] && { ok "libass già compilato ($arch)"; return; }
  log "Build libass $LIBASS_VERSION ($arch)..."
  local src="$BUILD_DIR/src/libass-$LIBASS_VERSION.tar.gz"
  download "https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="$(arch_flags "$arch") -O2" \
  LDFLAGS="$(arch_flags "$arch") -L$prefix/lib" \
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  ./configure --prefix="$prefix" \
    --enable-static --disable-shared \
    --disable-require-system-font-provider \
    --with-pic                            \
    --enable-asm
  make -j"$JOBS"
  make install
  popd >/dev/null
  ok "libass ($arch) ✓"
}

build_libplacebo() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libplacebo.a" ]] && { ok "libplacebo già compilato ($arch)"; return; }
  log "Build libplacebo $LIBPLACEBO_VERSION ($arch)..."
  local gitdir="$BUILD_DIR/src/libplacebo-git"
  download_git "https://code.videolan.org/videolan/libplacebo.git" "$gitdir" "v$LIBPLACEBO_VERSION"
  # Inizializza i submoduli (glad ecc.)
  git -C "$gitdir" submodule update --init --recursive
  # Fix compatibilità Python 3.14: ElementTree.__init__ ora vuole Element, non ElementTree
  sed -i '' \
    's/VkXML(ET\.parse(xmlfile))/VkXML(ET.parse(xmlfile).getroot())/g' \
    "$gitdir/src/vulkan/utils_gen.py"
  local bdir="$BUILD_DIR/build/libplacebo-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  meson setup "$gitdir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=static \
    -Dvulkan=disabled \
    -Dshaderc=disabled \
    -Dglslang=disabled \
    -Dopengl=disabled \
    -Dd3d11=disabled \
    -Ddemos=false \
    -Dtests=false \
    $(write_meson_cross "$arch" "$prefix")
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null
  ok "libplacebo ($arch) ✓"
}
  # ── libexpat ──────────────────────────────────────────────────────────────
  build_expat "$arch" "$prefix"

  # ── libpng ────────────────────────────────────────────────────────────────
  build_libpng "$arch" "$prefix"

  # ── freetype2 (dipende da libpng, zlib) ───────────────────────────────────
  build_freetype "$arch" "$prefix"

  # ── fribidi ───────────────────────────────────────────────────────────────
  build_fribidi "$arch" "$prefix"

  # ── harfbuzz ──────────────────────────────────────────────────────────────
  build_harfbuzz "$arch" "$prefix"

  # ── freetype2 round 2 (con harfbuzz) ─────────────────────────────────────
  build_freetype_round2 "$arch" "$prefix"

  # ── fontconfig ────────────────────────────────────────────────────────────
  build_fontconfig "$arch" "$prefix"

  # ── libass ────────────────────────────────────────────────────────────────
  build_libass "$arch" "$prefix"

  # ── libplacebo ────────────────────────────────────────────────────────────
  build_libplacebo "$arch" "$prefix"

  # ── speexdsp ──────────────────────────────────────────────────────────────
  build_speexdsp "$arch" "$prefix"

  # ── rubberband ────────────────────────────────────────────────────────────
  build_rubberband "$arch" "$prefix"

  # ── libarchive ────────────────────────────────────────────────────────────
  build_libarchive "$arch" "$prefix"

  # ── mujs ──────────────────────────────────────────────────────────────────
  build_mujs "$arch" "$prefix"

  # ── luajit ────────────────────────────────────────────────────────────────
  build_luajit "$arch" "$prefix"

  # ── ffmpeg (tutto statico) ────────────────────────────────────────────────
  build_ffmpeg "$arch" "$prefix"

  # ── mpv ───────────────────────────────────────────────────────────────────
  build_mpv "$arch" "$prefix"
}

# =============================================================================
# Funzioni di build singole librerie
# =============================================================================

build_zlib() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libz.a" ]] && { ok "zlib già compilato ($arch)"; return; }
  log "Build zlib $ZLIB_VERSION ($arch)..."
  local src="$BUILD_DIR/src/zlib-$ZLIB_VERSION.tar.gz"
  download "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="$(arch_flags "$arch") -O2" \
    ./configure --prefix="$prefix" --static
  make -j"$JOBS"
  make install
  popd >/dev/null
  ok "zlib ($arch) ✓"
}

build_bzip2() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libbz2.a" ]] && { ok "bzip2 già compilato ($arch)"; return; }
  log "Build bzip2 $BZIP2_VERSION ($arch)..."
  local src="$BUILD_DIR/src/bzip2-$BZIP2_VERSION.tar.gz"
  download "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make -j"$JOBS" \
    CC="clang" \
    CFLAGS="$(arch_flags "$arch") -O2 -D_FILE_OFFSET_BITS=64" \
    AR="ar" RANLIB="ranlib" \
    libbz2.a
  install -m 644 libbz2.a "$prefix/lib/"
  install -m 644 bzlib.h  "$prefix/include/"
  popd >/dev/null
  ok "bzip2 ($arch) ✓"
}

build_xz() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/liblzma.a" ]] && { ok "xz già compilato ($arch)"; return; }
  log "Build xz $XZ_VERSION ($arch)..."
  local src="$BUILD_DIR/src/xz-$XZ_VERSION.tar.gz"
  download "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="$(arch_flags "$arch") -O2" \
  ./configure --prefix="$prefix" \
    --enable-static --disable-shared \
    --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo \
    --disable-scripts --disable-doc
  make -j"$JOBS"
  make install
  popd >/dev/null
  ok "xz/liblzma ($arch) ✓"
}

build_expat() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libexpat.a" ]] && { ok "expat già compilato ($arch)"; return; }
  log "Build expat $LIBEXPAT_VERSION ($arch)..."
  local src="$BUILD_DIR/src/expat-$LIBEXPAT_VERSION.tar.gz"
  download "https://github.com/libexpat/libexpat/releases/download/R_$(echo "$LIBEXPAT_VERSION" | tr . _)/expat-${LIBEXPAT_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="$(arch_flags "$arch") -O2" \
  ./configure --prefix="$prefix" \
    --enable-static --disable-shared \
    --without-docbook --without-examples --without-tests
  make -j"$JOBS"
  make install
  popd >/dev/null
  ok "expat ($arch) ✓"
}









build_speexdsp() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libspeexdsp.a" ]] && { ok "speexdsp già compilato ($arch)"; return; }
  log "Build speexdsp $SPEEX_DSP_VERSION ($arch)..."
  local src="$BUILD_DIR/src/speexdsp-$SPEEX_DSP_VERSION.tar.gz"
  download "https://downloads.xiph.org/releases/speex/speexdsp-${SPEEX_DSP_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="$(arch_flags "$arch") -O2" \
  ./configure --prefix="$prefix" \
    --enable-static --disable-shared
  make -j"$JOBS"
  make install
  popd >/dev/null
  ok "speexdsp ($arch) ✓"
}

build_rubberband() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/librubberband.a" ]] && { ok "rubberband già compilato ($arch)"; return; }
  log "Build rubberband $RUBBERBAND_VERSION ($arch)..."
  local src="$BUILD_DIR/src/rubberband-$RUBBERBAND_VERSION.tar.bz2"
  download "https://breakfastquay.com/files/releases/rubberband-${RUBBERBAND_VERSION}.tar.bz2" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/rubberband-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  meson setup "$dir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=static \
    -Dfft=builtin \
    -Dresampler=speex \
    -Dladspa=disabled \
    -Dvamp=disabled \
    -Djni=disabled \
    $(write_meson_cross "$arch" "$prefix")
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null
  ok "rubberband ($arch) ✓"
}



build_libarchive() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libarchive.a" ]] && { ok "libarchive già compilato ($arch)"; return; }
  log "Build libarchive $LIBARCHIVE_VERSION ($arch)..."
  local src="$BUILD_DIR/src/libarchive-$LIBARCHIVE_VERSION.tar.gz"
  download "https://github.com/libarchive/libarchive/releases/download/v${LIBARCHIVE_VERSION}/libarchive-${LIBARCHIVE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CFLAGS="$(arch_flags "$arch") -O2 -I$prefix/include" \
  LDFLAGS="$(arch_flags "$arch") -L$prefix/lib" \
  ./configure --prefix="$prefix" \
    --enable-static --disable-shared \
    --with-zlib \
    --with-bz2lib \
    --with-liblzma \
    --without-nettle \
    --without-openssl \
    --without-xml2 \
    --without-expat
  make -j"$JOBS"
  make install
  popd >/dev/null
  # Su macOS iconv è in libc e non ha un .pc — creiamone uno stub
  # per soddisfare la dipendenza dichiarata in libarchive.pc
  if [[ ! -f "$prefix/lib/pkgconfig/iconv.pc" ]]; then
    cat > "$prefix/lib/pkgconfig/iconv.pc" <<'EOF'
Name: iconv
Description: iconv (system libc)
Version: 2.0
Libs:
Cflags:
EOF
  fi
  ok "libarchive ($arch) ✓"
}


build_mujs() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libmujs.a" ]] && { ok "mujs già compilato ($arch)"; return; }
  log "Build mujs $MUJS_VERSION ($arch)..."
  local gitdir="$BUILD_DIR/src/mujs-git"
  if [[ ! -d "$gitdir/.git" ]]; then
    download_git "https://github.com/ccxvii/mujs.git" "$gitdir" "$MUJS_VERSION"
  fi
  pushd "$gitdir" >/dev/null
  make -j"$JOBS" \
    CC="clang" \
    CFLAGS="$(arch_flags "$arch") -O2" \
    AR="ar" RANLIB="ranlib" \
    prefix="$prefix" \
    install-static
  popd >/dev/null
  ok "mujs ($arch) ✓"
}

build_luajit() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libluajit-5.1.a" ]] && { ok "luajit già compilato ($arch)"; return; }
  log "Build LuaJIT $LUAJIT_COMMIT ($arch)..."
  local gitdir="$BUILD_DIR/src/luajit-git"
  if [[ ! -d "$gitdir/.git" ]]; then
    download_git "https://github.com/LuaJIT/LuaJIT.git" "$gitdir" "$LUAJIT_COMMIT"
  fi
  pushd "$gitdir" >/dev/null
  make clean 2>/dev/null || true
  if [[ "$arch" == "arm64" ]]; then
    make -j"$JOBS" \
      MACOSX_DEPLOYMENT_TARGET="11.0" \
      PREFIX="$prefix" \
      STATIC_CC="clang -arch arm64" \
      DYNAMIC_CC="clang -arch arm64 -fPIC" \
      TARGET_LD="clang -arch arm64" \
      install
  else
    make -j"$JOBS" \
      MACOSX_DEPLOYMENT_TARGET="11.0" \
      PREFIX="$prefix" \
      STATIC_CC="clang -arch x86_64" \
      DYNAMIC_CC="clang -arch x86_64 -fPIC" \
      TARGET_LD="clang -arch x86_64" \
      install
  fi
  popd >/dev/null
  # Rimuovi la dylib di LuaJIT: vogliamo che mpv linki solo la .a statica
  rm -f "$prefix/lib/libluajit-5.1.2.dylib" "$prefix/lib/libluajit-5.1.dylib" \
        "$prefix/lib/libluajit-5.1.2.dylib"
  # LuaJIT installa libluajit-5.1.a ma mpv cerca libluajit.a o tramite pkg-config
  ok "luajit ($arch) ✓"
}









build_ffmpeg() {
  local arch="$1" prefix="$2"
  [[ -f "$prefix/lib/libavcodec.a" ]] && { ok "ffmpeg già compilato ($arch)"; return; }
  log "Build ffmpeg $FFMPEG_VERSION ($arch)..."
  local src="$BUILD_DIR/src/ffmpeg-$FFMPEG_VERSION.tar.gz"
  download "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/ffmpeg-$arch"
  mkdir -p "$bdir"
  pushd "$bdir" >/dev/null

  local sdk
  sdk="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || echo "")"
  local extra_cflags="-arch $arch -mmacosx-version-min=11.0 -O2"
  local extra_ldflags="-arch $arch -mmacosx-version-min=11.0"
  [[ -n "$sdk" ]] && { extra_cflags+=" -isysroot $sdk"; extra_ldflags+=" -isysroot $sdk"; }

  local cross_prefix=""
  if [[ "$arch" == "x86_64" && "$HOST_ARCH" == "arm64" ]]; then
    cross_prefix="x86_64-apple-macos11-"
  fi

  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  "$dir/configure" \
    --prefix="$prefix" \
    --enable-static \
    --disable-shared \
    --disable-programs \
    --disable-doc \
    --disable-debug \
    --enable-cross-compile \
    --arch="$arch" \
    --target-os=darwin \
    --cc="clang" \
    --cxx="clang++" \
    --extra-cflags="$extra_cflags" \
    --extra-ldflags="$extra_ldflags" \
    --enable-optimizations \
    --enable-pthreads \
    --enable-avcodec \
    --enable-avfilter \
    --enable-avformat \
    --enable-avutil \
    --enable-avdevice \
    --enable-swresample \
    --enable-swscale \
    --enable-protocols \
    --enable-demuxers \
    --enable-decoders \
    --enable-filters \
    --disable-outdevs \
    --enable-indev=avfoundation \
    --enable-zlib \
    --enable-bzlib \
    --enable-lzma \
    --enable-iconv \
    --enable-network \
    --enable-securetransport \
    --disable-openssl \
    --disable-libdrm \
    --disable-vaapi \
    --disable-vdpau \
    --disable-libpulse \
    --disable-sdl2 \
    --disable-xlib
  make -j"$JOBS"
  make install
  popd >/dev/null
  ok "ffmpeg ($arch) ✓"
}

build_mpv() {
  local arch="$1" prefix="$2"
  local out_dylib="$prefix/lib/libmpv.dylib"
  [[ -f "$out_dylib" ]] && { ok "mpv already compiled ($arch)"; return; }
  log "Building mpv $MPV_VERSION ($arch)..."
  local src="$BUILD_DIR/src/mpv-$MPV_VERSION.tar.gz"
  download "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"

  # Patch meson.build: compile osdep/utils-mac.c unconditionally on Darwin.
  # In upstream mpv it is only compiled under "if features['cocoa']", but we
  # disable Cocoa (to avoid the swift.h dependency). Without this file the
  # symbols cfstr_from_cstr / cfstr_get_cstr are left undefined in the dylib
  # and the CoreAudio AO crashes with SIGSEGV on the first call.
  cat > "$BUILD_DIR/_mpv_utils_mac_patch.py" << 'PYEOF'
import sys, re
fn = sys.argv[1]
with open(fn) as f:
    content = f.read()
# Remove 'osdep/utils-mac.c' from the cocoa-conditional block
content = re.sub(r"^\s+'osdep/utils-mac\.c',\n", "", content, flags=re.MULTILINE)
# Insert it unconditionally (Darwin only) just before the cocoa dependency
marker = "cocoa = dependency('appleframeworks'"
patch = (
    "# Always compile on Darwin: provides cfstr_from_cstr / cfstr_get_cstr\n"
    "# (needed by ao_coreaudio even when the Cocoa UI is disabled)\n"
    "if darwin\n"
    "    sources += files('osdep/utils-mac.c')\n"
    "endif\n\n"
)
content = content.replace(marker, patch + marker, 1)

with open(fn, 'w') as f:
    f.write(content)
print("Patched meson.build: osdep/utils-mac.c now compiled unconditionally on Darwin")
PYEOF
  python3 "$BUILD_DIR/_mpv_utils_mac_patch.py" "$dir/meson.build"

  local bdir="$BUILD_DIR/build/mpv-$arch"
  mkdir -p "$bdir"

  # Cross-file meson per l'architettura
  local cross_file_flag
  cross_file_flag="$(write_meson_cross "$arch" "$prefix")"

  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  meson setup "$dir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=shared \
    $cross_file_flag \
    -Dlibmpv=true \
    -Dcplayer=false \
    -Dbuild-date=false \
    -Dtests=false \
    -Dswift-build=disabled \
    -Dlua=luajit \
    -Djavascript=enabled \
    -Drubberband=enabled \
    -Duchardet=disabled \
    -Dlibarchive=enabled \
    -Dlibbluray=disabled \
    -Dvideotoolbox-pl=disabled \
    -Dzimg=disabled \
    -Dvulkan=disabled \
    -Dgl=disabled \
    -Dplain-gl=disabled \
    -Dcocoa=disabled \
    -Dmacos-cocoa-cb=disabled \
    -Davfoundation=enabled \
    -Dcoreaudio=enabled \
    -Daudiounit=disabled
  ninja -j"$JOBS"
  ninja install
  popd >/dev/null

  ok "mpv ($arch) ✓"
}

# ── Helper: generate meson cross-file ─────────────────────────────────────────
write_meson_cross() {
  local arch="$1" prefix="${2:-$PREFIX}"
  local file="$BUILD_DIR/meson_cross_${arch}.ini"
  local sdk pkgcfg
  sdk="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || echo "")"
  pkgcfg="$(command -v pkg-config)"

  local sdk_arg=""
  [[ -n "$sdk" ]] && sdk_arg=", '-isysroot', '${sdk}'"

  if [[ "$arch" == "$HOST_ARCH" ]]; then
    # Native build: uses --native-file (meson does not enter cross mode)
    # pkg_config_libdir is necessary because meson doesn't use PKG_CONFIG_PATH in cross mode
    cat > "$file" << EOF
[binaries]
c         = 'clang'
cpp       = 'clang++'
ar        = 'ar'
strip     = 'strip'
pkg-config = '${pkgcfg}'

[built-in options]
c_args   = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]
cpp_args = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]
c_link_args   = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]
cpp_link_args = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]

[properties]
pkg_config_libdir = ['${prefix}/lib/pkgconfig', '${prefix}/lib64/pkgconfig']
EOF
    echo "--native-file=${file}"
  else
    # Cross-compilation (es. x86_64 su arm64 o viceversa)
    local cpu_family="${arch/x86_64/x86}"
    cat > "$file" << EOF
[binaries]
c         = 'clang'
cpp       = 'clang++'
ar        = 'ar'
strip     = 'strip'
pkg-config = '${pkgcfg}'

[built-in options]
c_args   = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]
cpp_args = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]
c_link_args   = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]
cpp_link_args = ['-arch', '${arch}', '-mmacosx-version-min=11.0'${sdk_arg}]

[properties]
pkg_config_libdir = ['${prefix}/lib/pkgconfig', '${prefix}/lib64/pkgconfig']

[host_machine]
system     = 'darwin'
cpu_family = '${cpu_family}'
cpu        = '${arch}'
endian     = 'little'
EOF
    echo "--cross-file=${file}"
  fi
}

# ── Lipo: join arm64 + x86_64 into universal binary ──────────────────────────
make_universal() {
  local arm_dylib="$PREFIX_BASE/arm64/lib/libmpv.dylib"
  local x86_dylib="$PREFIX_BASE/x86_64/lib/libmpv.dylib"
  local out="$OUTPUT_DIR/libmpv.dylib"

  [[ ! -f "$arm_dylib" ]] && fail "arm64 libmpv.dylib not found: $arm_dylib"
  [[ ! -f "$x86_dylib" ]] && fail "x86_64 libmpv.dylib not found: $x86_dylib"

  log "Creating universal binary (lipo)..."
  rm -f "$out"
  lipo -create "$arm_dylib" "$x86_dylib" -output "$out"
  install_name_tool -id "@rpath/libmpv.dylib" "$out" 2>/dev/null
  codesign -s - --force "$out" 2>/dev/null
  ok "Universal binary: $out"
}

# ── Finalization: copy + fix install name + codesign ──────────────────────────
finalize() {
  local arch="$1"
  local src="$PREFIX_BASE/$arch/lib/libmpv.dylib"
  local out="$OUTPUT_DIR/libmpv.dylib"
  [[ ! -f "$src" ]] && fail "libmpv.dylib not found: $src"
  rm -f "$out"
  cp "$src" "$out"
  install_name_tool -id "@rpath/libmpv.dylib" "$out" 2>/dev/null
  codesign -s - --force "$out" 2>/dev/null
  ok "Output: $out"
}

verify_output() {
  local out="$OUTPUT_DIR/libmpv.dylib"
  log "Verifying external dependencies..."
  local external
  external="$(otool -L "$out" | grep '/opt/homebrew\|/usr/local' || true)"
  if [[ -n "$external" ]]; then
    warn "Warning: found Homebrew dependencies in the final binary:"
    echo "$external"
    warn "The dylib might not work on machines without Homebrew installed."
  else
    ok "No Homebrew dependencies — the dylib is fully self-sufficient"
  fi
  log "System dependencies (expected):"
  otool -L "$out" | grep -v "opt/homebrew\|/usr/local\|$out:" | head -20
  local size
  size="$(du -sh "$out" | cut -f1)"
  ok "Size: $size  →  $out"
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║      build_libmpv_macos.sh — static mpv $MPV_VERSION            ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "  ARCH  : $ARCH"
  echo "  JOBS  : $JOBS"
  echo "  OUTPUT: $OUTPUT_DIR"
  echo "  BUILD : $BUILD_DIR"
  echo ""

  check_tools

  case "$ARCH" in
    universal)
      log "Universal build: arm64 + x86_64"
      build_for_arch "arm64"
      build_for_arch "x86_64"
      make_universal
      ;;
    arm64|x86_64)
      build_for_arch "$ARCH"
      finalize "$ARCH"
      ;;
    *)
      fail "Unsupported architecture: $ARCH (use arm64, x86_64, or universal)"
      ;;
  esac

  verify_output

  if [[ "${KEEP_BUILD:-0}" != "1" ]]; then
    log "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    ok "BUILD_DIR removed"
  fi

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  Build completed successfully!                               ║"
  echo "║                                                              ║"
  echo "║  Next steps:                                                 ║"
  echo "║  1. Commit macos/libs/libmpv.dylib                         ║"
  echo "║  2. Re-enable app-sandbox in Release.entitlements            ║"
  echo "║  3. Run: cd example && flutter run -d macos                 ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""
}

main "$@"
