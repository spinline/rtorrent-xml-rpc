#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <arch>" >&2
  exit 2
fi
ARCH="$1"
BUILD_DIR="build-${ARCH}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

echo "Building for arch=${ARCH}"

# Run autotools if present
SRC_ROOT="$(pwd)"
# If no build system or binary present in the repo, clone upstream rtorrent
if [ -f autogen.sh ] || [ -f configure ] || [ -f src/rtorrent ]; then
  SRC_TO_BUILD="${SRC_ROOT}"
else
  echo "No rtorrent source detected in repo; cloning https://github.com/rakshasa/rtorrent.git"
  rm -rf "${SRC_ROOT}/rtorrent-src"
  git clone --depth 1 https://github.com/rakshasa/rtorrent.git "${SRC_ROOT}/rtorrent-src"
  SRC_TO_BUILD="${SRC_ROOT}/rtorrent-src"
fi

# Ensure libtorrent (rakshasa) is available via pkg-config; build/install it if missing
if ! command -v pkg-config >/dev/null 2>&1 || ! pkg-config --exists libtorrent; then
  echo "libtorrent pkg-config not found; cloning and building https://github.com/rakshasa/libtorrent.git"
  rm -rf "${SRC_ROOT}/libtorrent-src"
  git clone --depth 1 https://github.com/rakshasa/libtorrent.git "${SRC_ROOT}/libtorrent-src"
  pushd "${SRC_ROOT}/libtorrent-src"
  if [ -f autogen.sh ]; then
    chmod +x autogen.sh
    ./autogen.sh || true
  else
    autoreconf -i || true
  fi
  if [ -f configure ]; then
    chmod +x configure
    ./configure --prefix=/usr/local || true
  fi
  make -j"$(nproc || echo 2)" || true
  make install || true
  ldconfig || true
  export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
  popd
fi

pushd "${SRC_TO_BUILD}"

# Run autotools if present
if [ -f autogen.sh ]; then
  chmod +x autogen.sh
  ./autogen.sh || true
elif [ -f configure.ac ] || [ -f configure.in ]; then
  autoreconf -i || true
fi

if [ -f configure ]; then
  chmod +x configure
  ./configure || true
fi

make -j"$(nproc || echo 2)" || true

popd

# locate binary
BIN=""
if [ -f src/rtorrent ]; then
  BIN=src/rtorrent
elif [ -f rtorrent ]; then
  BIN=rtorrent
else
  BIN=$(find . -maxdepth 3 -type f -name rtorrent | head -n1 || true)
fi

if [ -z "${BIN}" ]; then
  echo "Error: rtorrent binary not found after build" >&2
  exit 1
fi

cp "${BIN}" "${BUILD_DIR}/rtorrent"
strip "${BUILD_DIR}/rtorrent" || true

tar -czf "rtorrent-${ARCH}.tar.gz" -C "${BUILD_DIR}" rtorrent
echo "Created rtorrent-${ARCH}.tar.gz"
