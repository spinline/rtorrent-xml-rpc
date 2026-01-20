# rtorrent xml-rpc — CI multi-arch build

This repository contains GitHub Actions workflow and a build helper to compile `rtorrent` for multiple CPU architectures and publish the artifacts on a GitHub Release.

How it works
- Push a tag like `v1.2.3` to trigger the workflow defined in `.github/workflows/build.yml`.
- The workflow builds for `amd64`, `arm64`, and `armv7` using QEMU emulation inside Debian containers.
- Artifacts are packaged and attached to the GitHub Release created for the tag.

Notes
- The CI installs build dependencies via `apt` inside the container — you may need to adjust package names if your project requires other libs.
- If a build fails on a specific arch, inspect the Actions log and update `build/build-release.sh` or the workflow accordingly.

Trigger
- Create and push a tag: `git tag vX.Y.Z && git push origin --tags`
