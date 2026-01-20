#!/bin/bash
set -e

# rtorrent XML-RPC Build Script
# Usage: ./build.sh [architecture] [rtorrent-version]
# Example: ./build.sh x86_64 v0.9.8

ARCH=${1:-x86_64}
VERSION=${2:-v0.9.8}
XMLRPC_VERSION="1.51.08"

echo "========================================="
echo "Building rtorrent with XML-RPC support"
echo "Architecture: $ARCH"
echo "Version: $VERSION"
echo "========================================="

# Determine Docker platform and host
case $ARCH in
  x86_64)
    DOCKER_ARCH="amd64"
    HOST="x86_64-linux-gnu"
    ;;
  aarch64)
    DOCKER_ARCH="arm64v8"
    HOST="aarch64-linux-gnu"
    ;;
  armv7l)
    DOCKER_ARCH="arm32v7"
    HOST="arm-linux-gnueabihf"
    ;;
  *)
    echo "Error: Unsupported architecture: $ARCH"
    echo "Supported: x86_64, aarch64, armv7l"
    exit 1
    ;;
esac

# Create build directory
BUILD_DIR="$(pwd)/build-$ARCH"
mkdir -p "$BUILD_DIR"

echo ""
echo "Starting Docker build..."
echo ""

docker run --rm \
  --platform linux/$DOCKER_ARCH \
  -v "$BUILD_DIR:/output" \
  -w /tmp/build \
  ${DOCKER_ARCH}/ubuntu:22.04 \
  bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive
    
    echo '==> Installing build dependencies...'
    apt-get update -qq
    apt-get install -y -qq \
      build-essential \
      autoconf \
      automake \
      libtool \
      pkg-config \
      libncurses-dev \
      libcurl4-openssl-dev \
      libssl-dev \
      zlib1g-dev \
      wget \
      ca-certificates
    
    mkdir -p /tmp/build
    cd /tmp/build
    
    echo ''
    echo '==> Building xmlrpc-c ${XMLRPC_VERSION}...'
    wget -q https://sourceforge.net/projects/xmlrpc-c/files/Xmlrpc-c%20Super%20Stable/${XMLRPC_VERSION}/xmlrpc-c-${XMLRPC_VERSION}.tgz
    tar xzf xmlrpc-c-${XMLRPC_VERSION}.tgz
    cd xmlrpc-c-${XMLRPC_VERSION}
    ./configure --prefix=/usr/local \
      --disable-wininet-client \
      --disable-curl-client \
      --disable-libwww-client \
      --disable-cplusplus \
      > /dev/null
    make -j\$(nproc) > /dev/null
    make install > /dev/null
    cd ..
    echo '✓ xmlrpc-c built successfully'
    
    echo ''
    echo '==> Building libtorrent ${VERSION}...'
    wget -q https://github.com/rakshasa/libtorrent/archive/${VERSION}.tar.gz -O libtorrent.tar.gz
    tar xzf libtorrent.tar.gz
    cd libtorrent-*
    ./autogen.sh > /dev/null
    ./configure --prefix=/usr/local \
      --with-posix-fallocate \
      --enable-static \
      --disable-shared \
      > /dev/null
    make -j\$(nproc) > /dev/null
    make install > /dev/null
    cd ..
    echo '✓ libtorrent built successfully'
    
    echo ''
    echo '==> Building rtorrent ${VERSION}...'
    wget -q https://github.com/rakshasa/rtorrent/archive/${VERSION}.tar.gz -O rtorrent.tar.gz
    tar xzf rtorrent.tar.gz
    cd rtorrent-*
    ./autogen.sh > /dev/null
    ./configure --prefix=/usr/local \
      --with-xmlrpc-c \
      --enable-static \
      LDFLAGS='-static-libgcc -static-libstdc++' \
      > /dev/null
    make -j\$(nproc) > /dev/null
    echo '✓ rtorrent built successfully'
    
    echo ''
    echo '==> Stripping binary...'
    strip src/rtorrent
    
    echo '==> Copying to output...'
    cp src/rtorrent /output/rtorrent-${ARCH}
    
    echo ''
    echo '==> Verifying binary...'
    /output/rtorrent-${ARCH} --help > /dev/null 2>&1 || true
    
    if ldd /output/rtorrent-${ARCH} 2>&1 | grep -q 'not a dynamic executable'; then
      echo '✓ Static binary created successfully'
    else
      echo '⚠ Warning: Binary may have dynamic dependencies'
      ldd /output/rtorrent-${ARCH} || true
    fi
  "

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo ""
echo "Binary location: $BUILD_DIR/rtorrent-$ARCH"
echo ""
echo "Creating archive..."
tar czf "rtorrent-${VERSION}-${ARCH}.tar.gz" -C "$BUILD_DIR" "rtorrent-${ARCH}"
sha256sum "rtorrent-${VERSION}-${ARCH}.tar.gz" > "rtorrent-${VERSION}-${ARCH}.tar.gz.sha256"

echo ""
echo "Files created:"
echo "  - rtorrent-${VERSION}-${ARCH}.tar.gz"
echo "  - rtorrent-${VERSION}-${ARCH}.tar.gz.sha256"
echo ""
echo "To install:"
echo "  tar xzf rtorrent-${VERSION}-${ARCH}.tar.gz"
echo "  sudo mv rtorrent-${ARCH} /usr/local/bin/rtorrent"
echo "  sudo chmod +x /usr/local/bin/rtorrent"
echo ""
