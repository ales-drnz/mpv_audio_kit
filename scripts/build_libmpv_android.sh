#!/usr/bin/env bash
# =============================================================================
# build_libmpv_android.sh
#
# Compiles mpv 0.41.0 as a shared library for Android.
# Output: android/src/main/jniLibs/{abi}/libmpv.so
#         Supported ABIs: arm64-v8a, armeabi-v7a, x86_64, x86
#
# Usage (from project root):
#   chmod +x scripts/build_libmpv_android.sh
#   ./scripts/build_libmpv_android.sh
#
# Options (environment variables):
#   ANDROID_NDK_ROOT=/path/to/ndk   (if not in PATH; we download NDK r27 if absent)
#   ANDROID_API=21                   (default: 21 — minSdkVersion)
#   MPV_VERSION=0.41.0              (default: 0.41.0)
#   ABIS="arm64-v8a armeabi-v7a x86_64 x86"  (default: all 4)
#   JOBS=N
#   SKIP_DOWNLOAD=1
#   KEEP_BUILD=1
#
# Requirements: cmake, ninja, nasm, python3, git, curl
#            On macOS also: iconv (from system), clang (Xcode CLT)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
OUTPUT_BASE="$ROOT/android/src/main/jniLibs"

MPV_VERSION="${MPV_VERSION:-0.41.0}"
ANDROID_API="${ANDROID_API:-21}"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 4)}"
ABIS="${ABIS:-arm64-v8a armeabi-v7a x86_64 x86}"

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
MUJS_VERSION="1.3.6"
LUAJIT_COMMIT="v2.1"
ZIMG_VERSION="3.0.5"
SPEEX_DSP_VERSION="1.2.1"
MBEDTLS_VERSION="3.6.0"
LIBPLACEBO_VERSION="6.338.2"
LIBICONV_VERSION="1.18"

NDK_VERSION="r27c"
BUILD_DIR="${BUILD_DIR:-$ROOT/build-android}"
PREFIX_BASE="$BUILD_DIR/prefix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}▶ $*${NC}" >&2; }
ok()   { echo -e "${GREEN}✓ $*${NC}" >&2; }
warn() { echo -e "${YELLOW}⚠ $*${NC}" >&2; }
fail() { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }

# ── NDK setup ─────────────────────────────────────────────────────────────────
find_or_download_ndk() {
  # 1. Environment variable
  if [[ -n "${ANDROID_NDK_ROOT:-}" && -d "$ANDROID_NDK_ROOT" ]]; then
    ok "NDK found: $ANDROID_NDK_ROOT"
    return
  fi
  # 2. Common locations
  local candidates=(
    "$HOME/Library/Android/sdk/ndk/${NDK_VERSION}"
    "$HOME/Android/Sdk/ndk/${NDK_VERSION}"
    "/usr/local/lib/android/sdk/ndk/${NDK_VERSION}"
    "$HOME/Library/Android/sdk/ndk-bundle"
    "${TMPDIR:-/tmp}/mpv_android_build/ndk/android-ndk-${NDK_VERSION}"
  )
  for c in "${candidates[@]}"; do
    if [[ -d "$c" ]]; then
      export ANDROID_NDK_ROOT="$c"
      ok "NDK found: $ANDROID_NDK_ROOT"
      return
    fi
  done
  # 3. Download NDK
  warn "Android NDK not found. Downloading NDK ${NDK_VERSION}..."
  local ndk_dir="$BUILD_DIR/ndk"
  mkdir -p "$ndk_dir"
  local host_tag
  if [[ "$(uname)" == "Darwin" ]]; then
    host_tag="darwin"
  else
    host_tag="linux"
  fi
  local url="https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-${host_tag}.zip"
  curl -fsSL --retry 3 -o "$ndk_dir/ndk.zip" "$url" || fail "NDK download failed"
  unzip -q "$ndk_dir/ndk.zip" -d "$ndk_dir"
  export ANDROID_NDK_ROOT="$(ls -d "$ndk_dir/android-ndk-${NDK_VERSION}" 2>/dev/null | head -1)"
  [[ -d "$ANDROID_NDK_ROOT" ]] || fail "NDK non trovato dopo l'estrazione"
  ok "NDK installato: $ANDROID_NDK_ROOT"
}

# ── Mappa ABI → target triple ─────────────────────────────────────────────────
abi_to_triple() {
  case "$1" in
    arm64-v8a)   echo "aarch64-linux-android" ;;
    armeabi-v7a) echo "armv7a-linux-androideabi" ;;
    x86_64)      echo "x86_64-linux-android" ;;
    x86)         echo "i686-linux-android" ;;
    *) fail "ABI sconosciuta: $1" ;;
  esac
}

abi_to_arch() {
  case "$1" in
    arm64-v8a)   echo "aarch64" ;;
    armeabi-v7a) echo "arm" ;;
    x86_64)      echo "x86_64" ;;
    x86)         echo "x86" ;;
  esac
}

abi_to_cpu_family() {
  case "$1" in
    arm64-v8a)   echo "aarch64" ;;
    armeabi-v7a) echo "arm" ;;
    x86_64)      echo "x86_64" ;;
    x86)         echo "x86" ;;
  esac
}

# ── Toolchain paths ────────────────────────────────────────────────────────────
ndk_toolchain() {
  local host_tag
  if [[ "$(uname)" == "Darwin" ]]; then
    host_tag="darwin-x86_64"
  else
    host_tag="linux-x86_64"
  fi
  echo "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$host_tag"
}

ndk_cc() {
  local abi="$1"
  local triple; triple="$(abi_to_triple "$abi")"
  local tc; tc="$(ndk_toolchain)"
  # armeabi-v7a usa armv7a ma il binario clang ha il prefisso armv7a
  echo "$tc/bin/${triple}${ANDROID_API}-clang"
}

ndk_cxx() {
  local abi="$1"; echo "$(ndk_cc "$abi")++"
}

ndk_ar() {
  local tc; tc="$(ndk_toolchain)"
  echo "$tc/bin/llvm-ar"
}

ndk_ranlib() {
  local tc; tc="$(ndk_toolchain)"
  echo "$tc/bin/llvm-ranlib"
}

ndk_strip() {
  local tc; tc="$(ndk_toolchain)"
  echo "$tc/bin/llvm-strip"
}

# ── Download helpers ───────────────────────────────────────────────────────────
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
  log "Estrazione: $name"
  tar -xf "$archive" -C "$dest_parent"
  echo "$dest_parent/$name"
}

# ── Meson cross-file per Android ──────────────────────────────────────────────
write_android_cross() {
  local abi="$1"
  local prefix="$2"
  local file="$BUILD_DIR/meson_cross_android_${abi}.ini"
  local triple; triple="$(abi_to_triple "$abi")"
  local cpu_family; cpu_family="$(abi_to_cpu_family "$abi")"
  local arch; arch="$(abi_to_arch "$abi")"
  local cc; cc="$(ndk_cc "$abi")"
  local cxx; cxx="$(ndk_cxx "$abi")"
  local ar; ar="$(ndk_ar)"
  local strip; strip="$(ndk_strip)"
  cat > "$file" << EOF
[binaries]
c = '$cc'
cpp = '$cxx'
ar = '$ar'
strip = '$strip'
pkg-config = 'pkg-config'

[built-in options]
c_args = ['-I${prefix}/include']
cpp_args = ['-I${prefix}/include']
c_link_args = ['-L${prefix}/lib']
cpp_link_args = ['-L${prefix}/lib']

[host_machine]
system = 'android'
cpu_family = '${cpu_family}'
cpu = '${arch}'
endian = 'little'
EOF
  echo "$file"
}

# ── cmake toolchain file per Android ──────────────────────────────────────────
cmake_android_flags() {
  local abi="$1"
  local prefix="$PREFIX_BASE/$abi"
  echo "-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake \
    -DANDROID_ABI=$abi \
    -DANDROID_PLATFORM=android-$ANDROID_API \
    -DANDROID_STL=c++_static \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_DEFAULT_CMP0074=NEW \
    -DCMAKE_FIND_ROOT_PATH=$prefix"
}

# =============================================================================
# Build per singola ABI
# =============================================================================
build_abi() {
  local abi="$1"
  local prefix="$PREFIX_BASE/$abi"
  mkdir -p "$prefix/include" "$prefix/lib/pkgconfig"

  export PKG_CONFIG_PATH="$prefix/lib/pkgconfig"
  export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig"
  # Do NOT export PKG_CONFIG_SYSROOT_DIR, it breaks paths prepending the sysroot to local prefixes.

  local cc; cc="$(ndk_cc "$abi")"
  local cxx; cxx="$(ndk_cxx "$abi")"
  export CC="$cc"
  export CXX="$cxx"
  export AR="$(ndk_ar)"
  export RANLIB="$(ndk_ranlib)"
  export STRIP="$(ndk_strip)"
  export CFLAGS="-O2 -fPIC"
  export CXXFLAGS="-O2 -fPIC"
  export LDFLAGS=""

  log "═══ ABI: $abi ═══"

  android_zlib       "$abi" "$prefix"
  android_bzip2      "$abi" "$prefix"
  android_xz         "$abi" "$prefix"
  android_speexdsp   "$abi" "$prefix"
  android_rubberband "$abi" "$prefix"
  android_libarchive "$abi" "$prefix"
  android_mujs       "$abi" "$prefix"
  android_luajit     "$abi" "$prefix"
  android_mbedtls    "$abi" "$prefix"
  android_ffmpeg     "$abi" "$prefix"
  android_libplacebo "$abi" "$prefix"
  android_mpv        "$abi" "$prefix"

  # Copia libmpv.so nella directory jniLibs
  local out_dir="$OUTPUT_BASE/$abi"
  mkdir -p "$out_dir"
  cp "$prefix/lib/libmpv.so" "$out_dir/libmpv.so"
  "$(ndk_strip)" --strip-unneeded "$out_dir/libmpv.so" 2>/dev/null || true
  ok "Output: $out_dir/libmpv.so"
}

# ── Librerie per Android ──────────────────────────────────────────────────────

android_zlib() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libz.a" ]] && return
  local src="$BUILD_DIR/src/zlib-$ZLIB_VERSION.tar.gz"
  download "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CC="$(ndk_cc "$abi")" \
  CFLAGS="-O2 -fPIC" \
  ./configure --prefix="$prefix" --static
  make -j"$JOBS" AR="$(ndk_ar)" ARFLAGS="rc" RANLIB="$(ndk_ranlib)"; make install
  popd >/dev/null
  ok "zlib ($abi) ✓"
}

android_iconv() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libiconv.a" ]] && return
  local src="$BUILD_DIR/src/libiconv-$LIBICONV_VERSION.tar.gz"
  download "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make distclean 2>/dev/null || true
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" --enable-static --disable-shared
  make -j"$JOBS"; make install

  mkdir -p "$prefix/lib/pkgconfig"
  printf "prefix=%s\nexec_prefix=\${prefix}\nlibdir=\${exec_prefix}/lib\nincludedir=\${prefix}/include\n\nName: iconv\nDescription: Character set conversion library\nVersion: %s\nLibs: -L\${libdir} -liconv\nCflags: -I\${includedir}\n" "$prefix" "$LIBICONV_VERSION" > "$prefix/lib/pkgconfig/iconv.pc"
  cp "$prefix/lib/pkgconfig/iconv.pc" "$prefix/lib/pkgconfig/libiconv.pc"

  popd >/dev/null
  ok "iconv ($abi) ✓"
}

android_bzip2() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libbz2.a" ]] && return
  local src="$BUILD_DIR/src/bzip2-$BZIP2_VERSION.tar.gz"
  download "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  make -j"$JOBS" \
    CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" \
    CFLAGS="-O2 -fPIC -D_FILE_OFFSET_BITS=64" libbz2.a
  install -m 644 libbz2.a "$prefix/lib/"
  install -m 644 bzlib.h  "$prefix/include/"
  popd >/dev/null
  ok "bzip2 ($abi) ✓"
}

android_xz() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/liblzma.a" ]] && return
  local src="$BUILD_DIR/src/xz-$XZ_VERSION.tar.gz"
  download "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" \
  CFLAGS="-O2 -fPIC" \
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" \
    --enable-static --disable-shared \
    --disable-xz --disable-xzdec --disable-lzmadec \
    --disable-lzmainfo --disable-scripts --disable-doc
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "xz ($abi) ✓"
}

android_expat() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libexpat.a" ]] && return
  local src="$BUILD_DIR/src/expat-$LIBEXPAT_VERSION.tar.gz"
  download "https://github.com/libexpat/libexpat/releases/download/R_$(echo "$LIBEXPAT_VERSION" | tr . _)/expat-${LIBEXPAT_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" CFLAGS="-O2 -fPIC" \
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" \
    --enable-static --disable-shared --without-docbook --without-examples --without-tests
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "expat ($abi) ✓"
}

android_libpng() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libpng.a" ]] && return
  local src="$BUILD_DIR/src/libpng-$LIBPNG_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/libpng/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" \
  CFLAGS="-O2 -fPIC" CPPFLAGS="-I$prefix/include" LDFLAGS="-L$prefix/lib" \
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" \
    --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libpng ($abi) ✓"
}

android_freetype() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libfreetype.a" ]] && return
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/freetype/freetype2/${FREETYPE_VERSION}/freetype-${FREETYPE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/freetype-r1-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    $(cmake_android_flags "$abi") \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON \
    -DZLIB_INCLUDE_DIR="$prefix/include" -DZLIB_LIBRARY="$prefix/lib/libz.a" \
    -DPNG_PNG_INCLUDE_DIR="$prefix/include" -DPNG_LIBRARY="$prefix/lib/libpng.a" \
    -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "freetype r1 ($abi) ✓"
}

android_fribidi() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libfribidi.a" ]] && return
  local src="$BUILD_DIR/src/fribidi-$FRIBIDI_VERSION.tar.gz"
  download "https://github.com/fribidi/fribidi/releases/download/v${FRIBIDI_VERSION}/fribidi-${FRIBIDI_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fribidi-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Ddocs=false -Dtests=false --cross-file="$(write_android_cross "$abi" "$prefix")"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "fribidi ($abi) ✓"
}

android_harfbuzz() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libharfbuzz.a" ]] && return
  local src="$BUILD_DIR/src/harfbuzz-$HARFBUZZ_VERSION.tar.gz"
  download "https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VERSION}/harfbuzz-${HARFBUZZ_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/harfbuzz-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dfreetype=enabled -Dglib=disabled -Dgobject=disabled -Dicu=disabled \
    -Dtests=disabled -Ddocs=disabled --cross-file="$(write_android_cross "$abi" "$prefix")"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "harfbuzz ($abi) ✓"
}

android_freetype2() {
  local abi="$1" prefix="$2"
  local sentinel="$prefix/.ft_r2_$abi"
  [[ -f "$sentinel" ]] && return
  local src="$BUILD_DIR/src/freetype-$FREETYPE_VERSION.tar.gz"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  rm -rf "$BUILD_DIR/build/freetype-r1-android-$abi"
  local bdir="$BUILD_DIR/build/freetype-r2-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    $(cmake_android_flags "$abi") \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DBUILD_SHARED_LIBS=OFF \
    -DFT_DISABLE_HARFBUZZ=OFF -DFT_REQUIRE_HARFBUZZ=ON \
    -DFT_REQUIRE_ZLIB=ON -DFT_REQUIRE_PNG=ON \
    -DZLIB_INCLUDE_DIR="$prefix/include" -DZLIB_LIBRARY="$prefix/lib/libz.a" \
    -DPNG_PNG_INCLUDE_DIR="$prefix/include" -DPNG_LIBRARY="$prefix/lib/libpng.a" \
    -DHarfBuzz_DIR="$prefix/lib/cmake/harfbuzz" \
    -GNinja
  ninja -j"$JOBS"; ninja install
  touch "$sentinel"
  popd >/dev/null
  ok "freetype r2 ($abi) ✓"
}

android_fontconfig() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libfontconfig.a" ]] && return
  local src="$BUILD_DIR/src/fontconfig-$FONTCONFIG_VERSION.tar.xz"
  download "https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/fontconfig-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dtests=disabled -Dtools=disabled -Ddoc=disabled \
    --cross-file="$(write_android_cross "$abi" "$prefix")"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "fontconfig ($abi) ✓"
}

android_libass() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libass.a" ]] && return
  local src="$BUILD_DIR/src/libass-$LIBASS_VERSION.tar.gz"
  download "https://github.com/libass/libass/releases/download/${LIBASS_VERSION}/libass-${LIBASS_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" \
  CFLAGS="-O2 -fPIC" LDFLAGS="-L$prefix/lib" PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" \
    --enable-static --disable-shared \
    --disable-require-system-font-provider --with-pic
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "libass ($abi) ✓"
}

android_speexdsp() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libspeexdsp.a" ]] && return
  local src="$BUILD_DIR/src/speexdsp-$SPEEX_DSP_VERSION.tar.gz"
  download "https://downloads.xiph.org/releases/speex/speexdsp-${SPEEX_DSP_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" CFLAGS="-O2 -fPIC" \
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "speexdsp ($abi) ✓"
}

android_rubberband() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/librubberband.a" ]] && return
  local src="$BUILD_DIR/src/rubberband-$RUBBERBAND_VERSION.tar.bz2"
  download "https://breakfastquay.com/files/releases/rubberband-${RUBBERBAND_VERSION}.tar.bz2" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/rubberband-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" meson setup "$dir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dfft=builtin -Dresampler=speex \
    -Dladspa=disabled -Dvamp=disabled -Djni=disabled \
    --cross-file="$(write_android_cross "$abi" "$prefix")"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "rubberband ($abi) ✓"
}

android_uchardet() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libuchardet.a" ]] && return
  local src="$BUILD_DIR/src/uchardet-$UCHARDET_VERSION.tar.gz"
  download "https://www.freedesktop.org/software/uchardet/releases/uchardet-${UCHARDET_VERSION}.tar.xz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/uchardet-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    $(cmake_android_flags "$abi") \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DBUILD_STATIC=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_BINARY=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "uchardet ($abi) ✓"
}

android_lcms2() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/liblcms2.a" ]] && return
  local src="$BUILD_DIR/src/lcms2-$LCMS2_VERSION.tar.gz"
  download "https://downloads.sourceforge.net/project/lcms/lcms/${LCMS2_VERSION}/lcms2-${LCMS2_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  pushd "$dir" >/dev/null
  CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" CFLAGS="-O2 -fPIC" \
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "lcms2 ($abi) ✓"
}

android_libarchive() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libarchive.a" ]] && return
  local src="$BUILD_DIR/src/libarchive-$LIBARCHIVE_VERSION.tar.gz"
  download "https://github.com/libarchive/libarchive/releases/download/v${LIBARCHIVE_VERSION}/libarchive-${LIBARCHIVE_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/libarchive-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    $(cmake_android_flags "$abi") \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_TEST=OFF -DENABLE_TAR=OFF -DENABLE_CPIO=OFF -DENABLE_CAT=OFF \
    -DENABLE_BZip2=ON -DENABLE_LIBXML2=OFF -DENABLE_EXPAT=OFF -DENABLE_PCREPOSIX=OFF -DENABLE_PCRE2POSIX=OFF \
    -DENABLE_ICONV=OFF \
    -DZLIB_INCLUDE_DIR="$prefix/include" -DZLIB_LIBRARY="$prefix/lib/libz.a" \
    -DBZIP2_INCLUDE_DIR="$prefix/include" -DBZIP2_LIBRARIES="$prefix/lib/libbz2.a" \
    -DLIBLZMA_INCLUDE_DIR="$prefix/include" -DLIBLZMA_LIBRARY="$prefix/lib/liblzma.a" \
    -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "libarchive ($abi) ✓"
}

android_mujs() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libmujs.a" ]] && return
  local gitdir="$BUILD_DIR/src/mujs-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://github.com/ccxvii/mujs.git" "$gitdir" "$MUJS_VERSION"
  pushd "$gitdir" >/dev/null
  make clean 2>/dev/null || true
  make -j"$JOBS" \
    CC="$(ndk_cc "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" \
    CFLAGS="-O2 -fPIC" HAVE_READLINE=no prefix="$prefix" install-static
  popd >/dev/null
  ok "mujs ($abi) ✓"
}

android_luajit() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libluajit-5.1.a" ]] && return
  local gitdir="$BUILD_DIR/src/luajit-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://github.com/LuaJIT/LuaJIT.git" "$gitdir" "$LUAJIT_COMMIT"
  pushd "$gitdir" >/dev/null
  make clean 2>/dev/null || true
  local triple; triple="$(abi_to_triple "$abi")"
  make -j"$JOBS" \
    HOST_CC="clang" \
    CROSS="${triple}-" \
    STATIC_CC="$(ndk_cc "$abi")" \
    DYNAMIC_CC="$(ndk_cc "$abi") -fPIC" \
    TARGET_LD="$(ndk_cc "$abi")" \
    TARGET_AR="$(ndk_ar) rcus" \
    TARGET_STRIP="$(ndk_strip)" \
    TARGET_SYS=Linux \
    PREFIX="$prefix" \
    install
  rm -f "$prefix/lib/libluajit"*.so*
  popd >/dev/null
  ok "luajit ($abi) ✓"
}

android_zimg() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libzimg.a" ]] && return
  local src="$BUILD_DIR/src/zimg-$ZIMG_VERSION.tar.gz"
  download "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-${ZIMG_VERSION}.tar.gz" "$src"
  extract "$src" "$BUILD_DIR/src" >/dev/null
  local dir; dir="$(ls -d "$BUILD_DIR/src/zimg-"* 2>/dev/null | tail -1)"
  pushd "$dir" >/dev/null
  [[ ! -f configure ]] && autoreconf -fiv 2>/dev/null || true
  CC="$(ndk_cc "$abi")" CXX="$(ndk_cxx "$abi")" AR="$(ndk_ar)" RANLIB="$(ndk_ranlib)" \
  CFLAGS="-O2 -fPIC" CXXFLAGS="-O2 -fPIC" \
  ./configure --prefix="$prefix" --host="$(abi_to_triple "$abi")" --enable-static --disable-shared
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "zimg ($abi) ✓"
}

android_mbedtls() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libmbedtls.a" ]] && return
  local src="$BUILD_DIR/src/mbedtls-$MBEDTLS_VERSION.tar.bz2"
  download "https://github.com/Mbed-TLS/mbedtls/releases/download/v${MBEDTLS_VERSION}/mbedtls-${MBEDTLS_VERSION}.tar.bz2" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/mbedtls-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  cmake "$dir" \
    $(cmake_android_flags "$abi") \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF \
    -DUSE_SHARED_MBEDTLS_LIBRARY=OFF -DUSE_STATIC_MBEDTLS_LIBRARY=ON \
    -GNinja
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "mbedtls ($abi) ✓"
}

android_ffmpeg() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libavcodec.a" ]] && return
  log "ffmpeg ($abi)..."
  local src="$BUILD_DIR/src/ffmpeg-$FFMPEG_VERSION.tar.gz"
  download "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/ffmpeg-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null

  local triple; triple="$(abi_to_triple "$abi")"
  local arch; arch="$(abi_to_arch "$abi")"
  local tc; tc="$(ndk_toolchain)"
  local cc; cc="$(ndk_cc "$abi")"

  # Flags per armeabi-v7a: NEON
  local extra_cflags="-O2 -fPIC"
  [[ "$abi" == "armeabi-v7a" ]] && extra_cflags+=" -mfpu=neon -mfloat-abi=softfp"

  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  "$dir/configure" \
    --prefix="$prefix" \
    --enable-static --disable-shared \
    --disable-programs --disable-doc --disable-debug \
    --enable-cross-compile \
    --arch="$arch" \
    --target-os=android \
    --cc="$cc" --cxx="$(ndk_cxx "$abi")" \
    --ar="$(ndk_ar)" --ranlib="$(ndk_ranlib)" \
    --strip="$(ndk_strip)" \
    --extra-cflags="$extra_cflags -I$prefix/include" \
    --extra-ldflags="-L$prefix/lib" \
    --enable-avcodec --enable-avfilter --enable-avformat \
    --enable-avutil --enable-avdevice --enable-swresample --enable-swscale \
    --enable-protocols --enable-demuxers --enable-decoders --enable-filters \
    --disable-outdevs \
    --enable-zlib --enable-bzlib --enable-lzma \
    --enable-network --enable-mbedtls --disable-openssl --enable-version3 \
    --disable-vaapi --disable-vdpau \
    --disable-sdl2 --disable-xlib --disable-libdrm \
    --disable-v4l2-m2m
  make -j"$JOBS"; make install
  popd >/dev/null
  ok "ffmpeg ($abi) ✓"
}

android_libplacebo() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libplacebo.a" ]] && return 0
  log "libplacebo ($abi)..."
  local gitdir="$BUILD_DIR/src/libplacebo-git"
  [[ -d "$gitdir/.git" ]] || download_git "https://code.videolan.org/videolan/libplacebo.git" "$gitdir" "v$LIBPLACEBO_VERSION"
  git -C "$gitdir" submodule update --init --recursive
  local bdir="$BUILD_DIR/build/libplacebo-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  meson setup "$gitdir" \
    --prefix="$prefix" --buildtype=release --default-library=static \
    -Dvulkan=disabled -Dshaderc=disabled -Dglslang=disabled -Dopengl=disabled \
    -Dd3d11=disabled -Ddemos=false -Dtests=false \
    --cross-file="$(write_android_cross "$abi" "$prefix")"
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "libplacebo ($abi) ✓"
}

android_mpv() {
  local abi="$1" prefix="$2"
  [[ -f "$prefix/lib/libmpv.so" ]] && return
  log "mpv $MPV_VERSION ($abi) [shared]..."
  local src="$BUILD_DIR/src/mpv-$MPV_VERSION.tar.gz"
  download "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz" "$src"
  local dir; dir="$(extract "$src" "$BUILD_DIR/src")"
  local bdir="$BUILD_DIR/build/mpv-android-$abi"; mkdir -p "$bdir"
  pushd "$bdir" >/dev/null
  python3 -c "
import sys, re
with open('../../../src/mpv-$MPV_VERSION/meson.build', 'r') as f: content = f.read()
content = re.sub(
    r\"libplacebo = dependency\('libplacebo',\s*version: '[^']*',\n\s*default_options: \['default_library=static', 'demos=false'\]\)\",
    \"libplacebo = dependency('libplacebo', version: '>=6.338.2', required: false)\",
    content
)
content = content.replace(\"libass = dependency('libass', version: '>= 0.12.2')\", \"libass = dependency('libass', version: '>= 0.12.2', required: false)\")
with open('../../../src/mpv-$MPV_VERSION/meson.build', 'w') as f: f.write(content)
"
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" \
  meson setup "$dir" \
    --prefix="$prefix" \
    --buildtype=release \
    --default-library=shared \
    --cross-file="$(write_android_cross "$abi" "$prefix")" \
    -Dlibmpv=true \
    -Dcplayer=false \
    -Dbuild-date=false \
    -Dtests=false \
    -Dmanpage-build=disabled \
    -Dhtml-build=disabled \
    -Dlua=luajit \
    -Djavascript=enabled \
    -Drubberband=enabled \
    -Duchardet=disabled \
    -Dlcms2=disabled \
    -Dlibarchive=enabled \
    -Dzimg=disabled \
    -Dcocoa=disabled \
    -Davfoundation=disabled \
    -Dcoreaudio=disabled \
    -Daudiounit=disabled \
    -Dopenal=disabled \
    -Dgl=disabled \
    -Dplain-gl=disabled \
    -Dx11=disabled \
    -Dwayland=disabled \
    -Dandroid-media-ndk=enabled
  ninja -j"$JOBS"; ninja install
  popd >/dev/null
  ok "mpv shared ($abi) ✓"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║   build_libmpv_android.sh — mpv $MPV_VERSION for Android       ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo "  ABI: $ABIS"
  echo "  API: $ANDROID_API"
  echo ""

  for t in cmake ninja python3 git curl; do
    command -v "$t" &>/dev/null || fail "$t not found"
  done

  find_or_download_ndk
  mkdir -p "$BUILD_DIR/src" "$BUILD_DIR/build"

  for abi in $ABIS; do
    build_abi "$abi"
  done

  [[ "${KEEP_BUILD:-0}" != "1" ]] && rm -rf "$BUILD_DIR" && ok "BUILD_DIR removed"

  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  Android build complete!                                     ║"
  echo "║  Output: android/src/main/jniLibs/{abi}/libmpv.so           ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
}

main "$@"
