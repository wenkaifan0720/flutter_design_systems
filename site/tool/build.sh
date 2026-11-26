#!/usr/bin/env bash
# Builds the documentation site into build/site/: the static pages and the Flutter web app behind every preview and
# Stint. Serve the result with site/tool/serve.py.
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root/site"
flutter pub get
mkdir -p "$root/build/site"
stage=$(mktemp -d "$root/build/.component-docs.XXXXXX")
trap 'rm -rf "${stage:?}"' EXIT
dart tool/generate.dart "$stage/docs"

cd examples
flutter build web --release --no-pub --no-wasm-dry-run --no-web-resources-cdn \
  --output="$stage/docs/examples"
dart "$root/site/tool/prepare_fonts.dart" "$stage/docs/examples/assets"

dest="$root/build/site/docs"
if [[ -d "$dest" ]]; then mv "$dest" "$stage/previous"; fi
if ! mv "$stage/docs" "$dest"; then
  if [[ -d "$stage/previous" ]]; then mv "$stage/previous" "$dest"; fi
  exit 1
fi
cp "$dest/404.html" "$stage/404.html"
mv "$stage/404.html" "$root/build/site/404.html"
