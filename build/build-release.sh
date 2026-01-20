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
# Default RPC implementation (jsonrpc or xmlrpc)
RPC_IMPL="${RPC_IMPL:-jsonrpc}"
# Cross-compile host detection (set before building libtorrent)
HOST=""
if [ "${ARCH}" = "mips" ]; then
  if command -v mips-linux-gnu-gcc >/dev/null 2>&1; then
    echo "Setting up MIPS cross-compile environment"
    export CC=mips-linux-gnu-gcc
    export CXX=mips-linux-gnu-g++
    export AR=mips-linux-gnu-ar
    export RANLIB=mips-linux-gnu-ranlib
    HOST="--host=mips-linux-gnu"
  else
    echo "MIPS cross-compiler not found; will attempt native build (may fail)" >&2
  fi
fi
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
    echo "Running libtorrent configure with host='${HOST:-native}'"
    # When cross-compiling, avoid running test programs by predefining common ac_cv_* vars.
    if [ -n "${HOST}" ]; then
      : "Using cross-compile safe configure variables"
      : "You can override via LIBTORRENT_ACVARS env var"
      LIBTORRENT_ACVARS="${LIBTORRENT_ACVARS:-ac_cv_func_malloc_0_nonnull=yes ac_cv_file__dev_zero=yes ac_cv_func_posix_memalign=yes ac_cv_func_realloc_0_nonnull=yes}"
      env ${LIBTORRENT_ACVARS} ./configure --prefix=/usr/local ${HOST} || {
        echo "libtorrent configure failed; dumping config.log for diagnosis:" >&2
        [ -f config.log ] && sed -n '1,200p' config.log >&2 || true
        return 1
      }
    else
      ./configure --prefix=/usr/local ${HOST:-}
    fi
  fi
  make -j"$(nproc || echo 2)"
  make install
  ldconfig

  # Locate any libtorrent .pc files and add their directories to PKG_CONFIG_PATH
    pc_dirs=$(find /usr/local /usr -type f -path '*/pkgconfig/*' -name 'libtorrent*.pc' -printf '%h\n' 2>/dev/null | sort -u | tr '\n' ':' | sed 's/:$//') || true
  if [ -n "${pc_dirs}" ]; then
    export PKG_CONFIG_PATH="${pc_dirs}:${PKG_CONFIG_PATH:-}"
  else
    # add common locations to help pkg-config lookup
    export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/lib/*-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}"
  fi
  # Force use of host pkg-config so configure checks find the just-installed libtorrent
  if command -v pkg-config >/dev/null 2>&1; then
    export PKG_CONFIG="$(command -v pkg-config)"
  fi
  popd
fi

# Verify libtorrent is discoverable via pkg-config; if not, show diagnostics
if ! ${PKG_CONFIG:-pkg-config} --exists libtorrent 2>/dev/null; then
  echo "ERROR: pkg-config cannot find libtorrent after building/installing it." >&2
  echo "PKG_CONFIG=${PKG_CONFIG:-$(command -v pkg-config 2>/dev/null || echo 'none')}" >&2
  echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-}" >&2
  echo "Listing /usr/local/lib/pkgconfig:" >&2
  ls -la /usr/local/lib/pkgconfig || true
  echo "Looking for libtorrent .pc files:" >&2
  find /usr/local/lib/pkgconfig -maxdepth 1 -type f -name '*libtorrent*.pc' -print -exec sed -n '1,200p' {} \; || true
  echo "pkg-config --list-all | grep libtorrent:" >&2
  ${PKG_CONFIG:-pkg-config} --list-all 2>/dev/null | grep libtorrent || true
  exit 1
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
  CFG_FLAGS=""
  if [ "${RPC_IMPL}" = "jsonrpc" ]; then
    CFG_FLAGS="${CFG_FLAGS} --enable-jsonrpc"
  fi
  # When cross-compiling for MIPS, ncurses target headers/libs are often unavailable;
  # disable ncurses UI to avoid missing target curses headers.
  if [ "${ARCH}" = "mips" ]; then
    CFG_FLAGS="${CFG_FLAGS} --disable-ncurses"
  fi

  # Determine build triplet for --build
  BUILD_TRIPLET="$(gcc -dumpmachine 2>/dev/null || echo x86_64-linux-gnu)"

  echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-} PKG_CONFIG=${PKG_CONFIG:-$(command -v pkg-config 2>/dev/null || echo '')}"
  echo "Configuring rtorrent: host=${HOST:-native} build=${BUILD_TRIPLET} flags='${CFG_FLAGS}'"

  if [ -n "${HOST}" ]; then
    # Provide common ac_cv_* overrides to avoid running test programs while cross-compiling.
    RTORRENT_ACVARS="${RTORRENT_ACVARS:-ac_cv_file__dev_zero=yes ac_cv_func_malloc_0_nonnull=yes ac_cv_func_posix_memalign=yes ac_cv_func_realloc_0_nonnull=yes}"
    echo "Using RTORRENT_ACVARS: ${RTORRENT_ACVARS}"
    env ${RTORRENT_ACVARS} ./configure --host=${HOST#--host=} --build=${BUILD_TRIPLET} ${CFG_FLAGS} || {
      echo "rtorrent configure failed; dumping config.log for diagnosis:" >&2
      [ -f config.log ] && sed -n '1,200p' config.log >&2 || true
      exit 1
    }
  else
    ./configure ${HOST:-} ${CFG_FLAGS} || exit 1
  fi
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
