#!/usr/bin/env bash
# Scores a candidate look's gates (rubric.md, G1 to G10) on a copy of it.
#
#   evals/score.sh path/to/<name>_ui
#
# The candidate's example/lib/inventory.dart must define
# `final DesignInventory inventory` and
# `Widget lookHost(BuildContext context, Widget child, Brightness brightness)`.
# Needs Flutter 3.47 or later on PATH.
set -u

evals="$(cd "$(dirname "$0")" && pwd)"
src="$(cd "$1" && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/score.XXXXXX")"
cp -R "$src" "$work/"
pkg="$work/$(basename "$src")"
ex="$pkg/example"
log="$work/log"
mkdir -p "$log"
failed=0

gate() { # id, PASS|FAIL|REVIEW, what
  printf '%-4s %-6s %s\n' "$1" "$2" "$3"
  [ "$2" = FAIL ] && failed=$((failed + 1))
}

flutter pub get --directory "$pkg" >"$log/get.txt" 2>&1
flutter pub get --directory "$ex" >>"$log/get.txt" 2>&1

# G1: formatted, and the analyzer clean on the package and its example.
if dart format --output=none --set-exit-if-changed "$pkg" >"$log/format.txt" 2>&1 &&
  dart analyze --fatal-infos "$pkg" "$ex" >"$log/analyze.txt" 2>&1; then
  gate G1 PASS "formatted, analyzer clean"
else
  gate G1 FAIL "see $log/format.txt and $log/analyze.txt"
fi

# G2: its own tests, leak-tracked.
if ! grep -q "LeakTesting.enable" "$pkg/test/flutter_test_config.dart" 2>/dev/null; then
  gate G2 FAIL "test/flutter_test_config.dart does not enable LeakTesting"
elif (cd "$pkg" && flutter test --exclude-tags goldens) >"$log/test.txt" 2>&1; then
  gate G2 PASS "tests green, leak tracking on"
else
  gate G2 FAIL "see $log/test.txt"
fi

# G3 to G5: the inventory and the sweep, from the example.
if [ ! -f "$ex/lib/inventory.dart" ]; then
  gate G3 FAIL "example/lib/inventory.dart is missing"
  gate G4 FAIL "example/lib/inventory.dart is missing"
  gate G5 FAIL "example/lib/inventory.dart is missing"
else
  example="$(sed -n 's/^name: *//p' "$ex/pubspec.yaml" | head -1)"
  (cd "$ex" && flutter pub add 'dev:ui_core_test:^0.3.0') >>"$log/get.txt" 2>&1
  (cd "$ex" && flutter pub add 'dev:flutter_test:{"sdk":"flutter"}') >>"$log/get.txt" 2>&1
  cp "$evals/sweep.dart" "$ex/test/score_sweep.dart" 2>/dev/null ||
    { mkdir -p "$ex/test" && cp "$evals/sweep.dart" "$ex/test/score_sweep.dart"; }
  cat >"$ex/test/score_test.dart" <<EOF
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/inventory.dart';
import 'package:$example/inventory.dart';

import 'score_sweep.dart';

void main() {
  test('G3', () => inventory.verify());
  test('G4', () {
    final present = {
      for (final e in inventory.entries)
        if (e.isPresent) e.row,
    };
    expect([
      for (final r in DesignInventoryRow.all)
        if (r.refs == 'MCS' && !present.contains(r.id)) r.id,
    ], isEmpty);
  });
  testWidgets('G5', (tester) async {
    final found = await sweepInventory(
      tester,
      inventory: inventory,
      host: lookHost,
    );
    expect(found, isEmpty, reason: found.join('\n'));
  });
  testWidgets('shoot', (tester) async {
    await shootInventory(
      tester,
      inventory: inventory,
      host: lookHost,
      outDir: Platform.environment['SHOOT_DIR']!,
    );
  });
}
EOF
  for g in G3 G4 G5; do
    if (cd "$ex" && flutter test test/score_test.dart --plain-name "$g") >"$log/$g.txt" 2>&1; then
      gate "$g" PASS "see rubric.md"
    else
      gate "$g" FAIL "see $log/$g.txt"
    fi
  done
  # The review pictures (not a gate): the gallery and each part under focus.
  if (cd "$ex" && SHOOT_DIR="$work/shots" flutter test test/score_test.dart --plain-name shoot) >"$log/shoot.txt" 2>&1; then
    gate R REVIEW "pictures in $work/shots"
  else
    gate R REVIEW "shooting failed: see $log/shoot.txt"
  fi
fi

# G6: behaviour from ui_core, not hand-rolled.
fad="$(grep -rln "FocusableActionDetector" "$pkg/lib" | wc -l | tr -d ' ')"
taps="$(grep -rln "onTap:" "$pkg/lib" | xargs grep -l "GestureDetector(" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$fad" != 0 ]; then
  gate G6 FAIL "$fad file(s) in lib use FocusableActionDetector"
elif [ "$taps" != 0 ]; then
  gate G6 REVIEW "$taps file(s) in lib have a GestureDetector with onTap: each must not be a part's only press"
else
  gate G6 PASS "no hand-rolled presses"
fi

# G7: re-exports ui_core with a show list only.
if grep -nE "^export 'package:ui_core/ui_core.dart';" "$pkg"/lib/*.dart >/dev/null; then
  gate G7 FAIL "the library re-exports all of ui_core"
else
  gate G7 PASS "ui_core re-exported with a show list, or not at all"
fi

# G8: dartdoc.
dart doc --dry-run "$pkg" >"$log/doc.txt" 2>&1
if grep -q "Found 0 warnings and 0 errors" "$log/doc.txt"; then
  gate G8 PASS "dartdoc clean"
else
  gate G8 FAIL "$(grep -E "Found [0-9]+ warnings" "$log/doc.txt" || echo "see $log/doc.txt")"
fi

# G9: publishable. A brief gives no repository, so the one warning about a
# missing homepage or repository is allowed; an invented URL is worse.
dart pub publish --dry-run --directory "$pkg" >"$log/publish.txt" 2>&1
if grep -q "has 0 warnings" "$log/publish.txt"; then
  gate G9 PASS "publish dry-run clean"
elif grep -q "has 1 warning" "$log/publish.txt" &&
  grep -q '"homepage" or "repository"' "$log/publish.txt"; then
  gate G9 PASS "publish dry-run clean but for the repository, not given"
else
  gate G9 FAIL "see $log/publish.txt"
fi

# G10: production grade.
hits="$(grep -rIniwE "todo|fixme|hack|wip|self-review|round [0-9]+" "$pkg/lib" "$pkg/test" "$ex/lib" 2>/dev/null | grep -v "score_" | wc -l | tr -d ' ')"
if [ "$hits" = 0 ]; then
  gate G10 PASS "no working notes"
else
  gate G10 FAIL "$hits line(s) of working notes in lib, test or example/lib"
fi

echo "$failed gate(s) failed; logs in $log"
[ "$failed" = 0 ]
