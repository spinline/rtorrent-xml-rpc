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
if [ -f autogen.sh ]; then
  chmod +x autogen.sh
  ./autogen.sh || true
fi

if [ -f configure ]; then
  chmod +x configure
  ./configure || true
fi

make -j"$(nproc || echo 2)" || true

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
