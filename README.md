# rtorrent JSON-RPC — CI multi-arch build

This repository contains a GitHub Actions workflow and a build helper to compile `rtorrent` configured for JSON-RPC (instead of XML-RPC) for multiple CPU architectures and publish artifacts on a GitHub Release.

How it works
- Push a tag like `v1.2.3` to trigger the workflow defined in `.github/workflows/build.yml`.
- The workflow builds for `amd64`, `arm64`, `armv7`, and `mips` using QEMU emulation inside Ubuntu containers.
- Artifacts are packaged and attached to the GitHub Release created for the tag.

Notes
- The CI installs JSON-RPC development packages (`libjsoncpp-dev` and `libjsonrpccpp-dev`) inside the container. If you need a different JSON-RPC implementation, update the workflow accordingly.
- If a build fails on a specific arch, inspect the Actions log and update `build/build-release.sh` or the workflow accordingly.

Trigger
- Create and push a tag: `git tag vX.Y.Z && git push origin --tags`
