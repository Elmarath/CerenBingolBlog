#!/usr/bin/env bash
# Builds the site on Netlify (or anywhere without Flutter installed):
# downloads the pinned Flutter release, then makes the production web build.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.29.3}"
FLUTTER_DIR="${FLUTTER_DIR:-$HOME/flutter-$FLUTTER_VERSION}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter pub get
dart run tool/content.dart check
dart run tool/content.dart bundle
# No offline service worker: visitors always get the newest posts.
flutter build web --release --pwa-strategy=none
