# rtorrent with XML-RPC Support

[![Build rtorrent with XML-RPC](https://github.com/spinline/rtorrent-xml-rpc/actions/workflows/build-release.yml/badge.svg)](https://github.com/spinline/rtorrent-xml-rpc/actions/workflows/build-release.yml)
[![GitHub release](https://img.shields.io/github/v/release/spinline/rtorrent-xml-rpc)](https://github.com/spinline/rtorrent-xml-rpc/releases/latest)

Pre-compiled [rtorrent](https://github.com/rakshasa/rtorrent) binaries with **XML-RPC support** enabled for multiple architectures.

## 🎯 Why This Repository?

The official [rakshasa/rtorrent](https://github.com/rakshasa/rtorrent) repository doesn't provide pre-built binaries with XML-RPC support. This repository automatically builds rtorrent with XML-RPC enabled, making it easy to use with web interfaces like [ruTorrent](https://github.com/Novik/ruTorrent) and [Flood](https://github.com/jesec/flood).

## 📦 Supported Architectures

| Architecture | Description | Use Case |
|-------------|-------------|----------|
| **x86_64** (amd64) | 64-bit Intel/AMD | Desktop, Servers |
| **aarch64** (arm64) | 64-bit ARM | ARM servers, Raspberry Pi 4/5, Apple Silicon |
| **armv7l** | 32-bit ARM | Raspberry Pi 3 and older models |

## 🚀 Quick Start

### 1. Download

Visit the [Releases](https://github.com/spinline/rtorrent-xml-rpc/releases/latest) page and download the appropriate binary for your architecture.

Or use `wget`:

```bash
# For x86_64
wget https://github.com/spinline/rtorrent-xml-rpc/releases/latest/download/rtorrent-v0.9.8-x86_64.tar.gz

# For aarch64
wget https://github.com/spinline/rtorrent-xml-rpc/releases/latest/download/rtorrent-v0.9.8-aarch64.tar.gz

# For armv7l
wget https://github.com/spinline/rtorrent-xml-rpc/releases/latest/download/rtorrent-v0.9.8-armv7l.tar.gz
```

### 2. Install

```bash
# Extract the archive
tar xzf rtorrent-v0.9.8-<arch>.tar.gz

# Move to system path
sudo mv rtorrent-<arch> /usr/local/bin/rtorrent
sudo chmod +x /usr/local/bin/rtorrent

# Verify installation
rtorrent --help
```

### 3. Verify Checksum (Optional but Recommended)

```bash
# Download checksum file
wget https://github.com/spinline/rtorrent-xml-rpc/releases/latest/download/rtorrent-v0.9.8-<arch>.tar.gz.sha256

# Verify
sha256sum -c rtorrent-v0.9.8-<arch>.tar.gz.sha256
```

## 🔧 Configuration

To enable XML-RPC in your rtorrent configuration (`~/.rtorrent.rc`):

```bash
# SCGI socket for XML-RPC
network.scgi.open_local = /tmp/rtorrent.sock
schedule2 = chmod,0,0,"execute2=chmod,\"g+w,o=\",/tmp/rtorrent.sock"

# Or use TCP port
# network.scgi.open_port = 127.0.0.1:5000
```

## 🌐 Web Interfaces

These binaries work with popular rtorrent web interfaces:

- **[ruTorrent](https://github.com/Novik/ruTorrent)** - Classic PHP-based web UI
- **[Flood](https://github.com/jesec/flood)** - Modern React-based web UI
- **[rTorrent-PS](https://github.com/pyroscope/rtorrent-ps)** - Enhanced rtorrent

## 🏗️ Build Information

All binaries are:
- ✅ Compiled with **XML-RPC support** (`--with-xmlrpc-c`)
- ✅ Statically linked for maximum portability
- ✅ Built using GitHub Actions for transparency
- ✅ Based on official rtorrent releases

### Dependencies Included

- **xmlrpc-c** 1.51.08 - XML-RPC library
- **libtorrent** - Matching version with rtorrent
- **OpenSSL** - SSL/TLS support
- **ncurses** - Terminal UI

## 📋 Requirements

Minimal runtime dependencies (most systems already have these):

```bash
# Debian/Ubuntu
sudo apt-get install libncurses6 libcurl4

# RHEL/CentOS/Fedora
sudo yum install ncurses-libs libcurl

# Arch Linux
sudo pacman -S ncurses curl
```

## 🔄 Update Process

This repository tracks official rtorrent releases. When a new version is released:

1. A new tag is created matching the upstream version
2. GitHub Actions automatically builds binaries for all architectures
3. A new release is published with all binaries

## 🛠️ Building Locally

If you want to build rtorrent yourself:

```bash
git clone https://github.com/spinline/rtorrent-xml-rpc.git
cd rtorrent-xml-rpc

# Trigger workflow manually or use the build script
./scripts/build.sh x86_64
```

## 📝 License

rtorrent is licensed under the **GNU GPL v2**. See the [upstream repository](https://github.com/rakshasa/rtorrent) for details.

This repository only provides automated builds and does not modify the rtorrent source code.

## 🙏 Credits

- **[rakshasa](https://github.com/rakshasa)** - Original rtorrent author
- **[rtorrent community](https://github.com/rakshasa/rtorrent/graphs/contributors)** - All contributors

## 🔗 Links

- **Upstream**: [rakshasa/rtorrent](https://github.com/rakshasa/rtorrent)
- **Wiki**: [rtorrent Wiki](https://github.com/rakshasa/rtorrent/wiki)
- **Issues**: [Report issues](https://github.com/spinline/rtorrent-xml-rpc/issues)

## ⭐ Support

If you find this useful, please star the repository and consider supporting the original rtorrent development:

- [Paypal](https://paypal.me/jarisundellno)
- [Patreon](https://www.patreon.com/rtorrent)

---

**Note**: These are unofficial builds. For official releases, visit [rakshasa/rtorrent](https://github.com/rakshasa/rtorrent).
