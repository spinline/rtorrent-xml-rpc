# Deployment Guide

This guide will help you push your rtorrent-xml-rpc repository to GitHub and trigger the first build.

## Step 1: Push to GitHub

Your local repository is ready at:
```
/Users/bilal/.gemini/antigravity/scratch/rtorrent-xml-rpc
```

Push it to your GitHub repository:

```bash
cd /Users/bilal/.gemini/antigravity/scratch/rtorrent-xml-rpc

# Add your GitHub repository as remote
git remote add origin https://github.com/spinline/rtorrent-xml-rpc.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Step 2: Trigger First Build

You have two options to trigger a build:

### Option A: Manual Trigger (Recommended for First Test)

1. Go to: https://github.com/spinline/rtorrent-xml-rpc/actions
2. Click on "Build rtorrent with XML-RPC" workflow
3. Click "Run workflow" button
4. Select branch: `main`
5. Enter rtorrent version: `v0.9.8` (or latest from https://github.com/rakshasa/rtorrent/releases)
6. Click "Run workflow"

### Option B: Create a Tag

```bash
# Create and push a tag
git tag v0.9.8
git push origin v0.9.8
```

This will automatically trigger the workflow and create a release.

## Step 3: Monitor Build Progress

1. Go to: https://github.com/spinline/rtorrent-xml-rpc/actions
2. Click on the running workflow
3. Monitor the build progress for each architecture:
   - x86_64 (amd64)
   - aarch64 (arm64)
   - armv7l (arm32)

Build time: ~15-30 minutes per architecture (runs in parallel)

## Step 4: Verify Release

Once the build completes:

1. Go to: https://github.com/spinline/rtorrent-xml-rpc/releases
2. You should see a new release with:
   - `rtorrent-v0.9.8-x86_64.tar.gz`
   - `rtorrent-v0.9.8-x86_64.tar.gz.sha256`
   - `rtorrent-v0.9.8-aarch64.tar.gz`
   - `rtorrent-v0.9.8-aarch64.tar.gz.sha256`
   - `rtorrent-v0.9.8-armv7l.tar.gz`
   - `rtorrent-v0.9.8-armv7l.tar.gz.sha256`

## Step 5: Test a Binary

Download and test one of the binaries:

```bash
# Download for your architecture
wget https://github.com/spinline/rtorrent-xml-rpc/releases/download/v0.9.8/rtorrent-v0.9.8-x86_64.tar.gz

# Verify checksum
wget https://github.com/spinline/rtorrent-xml-rpc/releases/download/v0.9.8/rtorrent-v0.9.8-x86_64.tar.gz.sha256
sha256sum -c rtorrent-v0.9.8-x86_64.tar.gz.sha256

# Extract
tar xzf rtorrent-v0.9.8-x86_64.tar.gz

# Test
./rtorrent-x86_64 --help
```

## Updating to New rtorrent Versions

When a new rtorrent version is released:

```bash
# Create a new tag matching the upstream version
git tag v0.9.9
git push origin v0.9.9
```

The workflow will automatically build and release the new version.

## Troubleshooting

### Build Fails

1. Check the Actions logs for detailed error messages
2. Common issues:
   - Upstream version doesn't exist
   - Network issues downloading dependencies
   - Compilation errors (usually fixed in newer rtorrent versions)

### Binary Doesn't Work

1. Check if it's a static binary:
   ```bash
   ldd rtorrent-x86_64
   # Should say "not a dynamic executable"
   ```

2. Verify XML-RPC support:
   ```bash
   strings rtorrent-x86_64 | grep -i xmlrpc
   # Should show xmlrpc-related strings
   ```

## Local Testing

Before pushing to GitHub, you can test the build locally:

```bash
cd /Users/bilal/.gemini/antigravity/scratch/rtorrent-xml-rpc

# Build for your architecture
./scripts/build.sh x86_64 v0.9.8

# Test the binary
./build-x86_64/rtorrent-x86_64 --help
```

Note: Local builds require Docker to be installed and running.

## Next Steps

1. ✅ Push repository to GitHub
2. ✅ Trigger first build
3. ✅ Verify release is created
4. ✅ Test a binary
5. 🎉 Share with the community!

## Support

If you encounter issues:
- Check [GitHub Actions logs](https://github.com/spinline/rtorrent-xml-rpc/actions)
- Review [rtorrent documentation](https://github.com/rakshasa/rtorrent/wiki)
- Open an issue at https://github.com/spinline/rtorrent-xml-rpc/issues
