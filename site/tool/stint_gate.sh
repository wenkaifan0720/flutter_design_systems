#!/usr/bin/env bash
# Stint's checks: run them before building or reviewing a change to Stint.
#
#   bash site/tool/stint_gate.sh [edition_dir ...]
#
# 1. Strict analysis of the Stint editions and the site examples.
# 2. Every Stint test suite: stint_core and each edition, which runs the shared Today check in English and Arabic,
#    then every edition's places in Japanese and German at phone and desktop width, and every edition in each
#    accent the Stint page offers, by day and night, and every edition's words whole and notices in their pane
#    (site/examples/test).
# Then build the site and run site/tool/stint_click_test.mjs (see site/study/README.md).
set -euo pipefail

site=$(cd "$(dirname "$0")/.." && pwd)
cd "$site"
flutter pub get

echo '== Strict analysis'
flutter analyze --fatal-infos --no-pub study examples

if [[ $# -gt 0 ]]; then
  editions=("$@")
else
  editions=(stint_core)
  for dir in study/*_ui; do editions+=("$(basename "$dir")"); done
fi
failed=()
for edition in "${editions[@]}"; do
  echo "== Tests: $edition"
  if ! (cd "study/$edition" && flutter test --no-pub); then failed+=("$edition"); fi
done
if [[ $# -eq 0 ]]; then
  echo '== Tests: every edition in Japanese and German, in every accent, its words whole and its notices placed'
  if ! (cd examples && flutter test --no-pub test/stint_languages_test.dart test/stint_accent_test.dart test/stint_fit_test.dart); then failed+=(languages/accents/fit); fi
fi
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Failed suites: ${failed[*]}"
  exit 1
fi
echo "Stint checks passed: ${#editions[@]} suites"
