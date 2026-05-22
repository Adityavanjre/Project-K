Vendored binaries
=================

This folder holds pre-bundled binaries that the packaging script will include
without requiring any network access during packaging.

Required for packaging:
- yt-dlp (macOS arm64) at: vendor/bin/yt-dlp

How to prepare:
- Download the macOS Apple Silicon build of yt-dlp and save it as:
  vendor/bin/yt-dlp
- Make it executable:
  chmod +x vendor/bin/yt-dlp
- Test locally:
  ./vendor/bin/yt-dlp --version

During packaging, the script will copy this binary into the app at:
dist/local-app/bin/yt-dlp and verify it runs.
