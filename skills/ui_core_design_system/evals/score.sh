#!/usr/bin/env bash
# Scores a candidate app's gates (rubric.md, G1 to G6) on a copy of it, and
# draws the review pictures.
#
#   evals/score.sh path/to/<app> [out dir]
#
# The candidate's lib/screens.dart must define
# `final Map<String, WidgetBuilder> screens` and
# `Widget designHost(BuildContext context, Widget child, Brightness brightness)`.
# Needs Flutter 3.47 or later on PATH.
set -u

evals="$(cd "$(dirname "$0")" && pwd)"
src="$(cd "$1" && pwd)"
work="${2:-$(mktemp -d "${TMPDIR:-/tmp}/score.XXXXXX")}"
mkdir -p "$work"
rsync -a --exclude .dart_tool --exclude build "$src/" "$work/app/"
app="$work/app"
log="$work/log"
mkdir -p "$log"
failed=0

gate() { # id, PASS|FAIL|REVIEW, what
  printf '%-4s %-6s %s\n' "$1" "$2" "$3"
  [ "$2" = FAIL ] && failed=$((failed + 1))
}

name="$(sed -n 's/^name: *//p' "$app/pubspec.yaml" | head -1)"
(cd "$app" && flutter pub get) >"$log/get.txt" 2>&1

# G1: formatted, and the analyzer clean (each run, so both are reported).
dart format --output=none --set-exit-if-changed "$app/lib" "$app/test" >"$log/format.txt" 2>&1
formatted=$?
(cd "$app" && dart analyze --fatal-infos) >"$log/analyze.txt" 2>&1
analyzed=$?
if [ "$formatted" = 0 ] && [ "$analyzed" = 0 ]; then
  gate G1 PASS "formatted, analyzer clean"
else
  gate G1 FAIL "format exit $formatted ($log/format.txt), analyze exit $analyzed ($log/analyze.txt)"
fi

# G2: its own tests, leak-tracked.
if ! grep -q "LeakTesting.enable" "$app/test/flutter_test_config.dart" 2>/dev/null; then
  gate G2 FAIL "test/flutter_test_config.dart does not enable LeakTesting"
elif (cd "$app" && flutter test) >"$log/test.txt" 2>&1; then
  gate G2 PASS "tests green, leak tracking on"
else
  gate G2 FAIL "see $log/test.txt"
fi

# G3: every screen under every condition, through ui_core_test's checks.
if [ ! -f "$app/lib/screens.dart" ]; then
  gate G3 FAIL "lib/screens.dart is missing"
else
  (cd "$app" && flutter pub add 'dev:ui_core_test:^0.4.0' 'dev:flutter_test:{"sdk":"flutter"}') >>"$log/get.txt" 2>&1
  mkdir -p "$app/test/score"
  cp "$evals/sweep.dart" "$app/test/score/sweep.dart"
  cat >"$app/test/score/score_test.dart" <<EOF
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:$name/screens.dart';

import 'sweep.dart';

void main() {
  testWidgets('G3', (tester) async {
    final found = await sweepScreens(
      tester,
      screens: screens,
      host: designHost,
      name: '$name',
    );
    expect(found, isEmpty, reason: found.join('\n'));
  });
  testWidgets('shoot', (tester) async {
    await shootScreens(
      tester,
      screens: screens,
      host: designHost,
      outDir: Platform.environment['SHOOT_DIR']!,
    );
  });
}
EOF
  if (cd "$app" && flutter test test/score/score_test.dart --plain-name G3) >"$log/G3.txt" 2>&1; then
    gate G3 PASS "every screen holds"
  else
    gate G3 FAIL "$(grep -c '^ *[A-Za-z].*: ' "$log/G3.txt") line(s); see $log/G3.txt"
  fi
  # The review pictures (not a gate).
  mkdir -p "$work/shots"
  if (cd "$app" && SHOOT_DIR="$work/shots" flutter test test/score/score_test.dart --plain-name shoot) >"$log/shoot.txt" 2>&1; then
    gate R REVIEW "pictures in $work/shots"
  else
    gate R REVIEW "shooting failed: see $log/shoot.txt"
  fi
fi

# G4: behaviour from ui_core: no Material parts, nothing hand-rolled.
parts='ElevatedButton|TextButton|OutlinedButton|FilledButton|IconButton|FloatingActionButton|Checkbox|Switch|Radio|Slider|showDialog|showModalBottomSheet|showDatePicker|MaterialPageRoute|AlertDialog|SimpleDialog|Scaffold|AppBar|ListTile|DropdownButton|DropdownMenu|PopupMenuButton|SnackBar|Tooltip|Chip|TabBar|NavigationBar|Card|InkWell|FocusableActionDetector'
grep -rnE "(^|[^.A-Za-z0-9_])($parts)(<[^(]*>)?\(" "$app/lib" | grep -vE ':[0-9]+: *//' >"$log/G4.txt"
material="$(wc -l <"$log/G4.txt" | tr -d ' ')"
taps="$(grep -rln "onTap:" "$app/lib" | xargs grep -l "GestureDetector(" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$material" != 0 ]; then
  gate G4 FAIL "$material Material part(s) or hand-rolled focus in lib: see $log/G4.txt"
elif [ "$taps" != 0 ]; then
  gate G4 REVIEW "$taps file(s) in lib have a GestureDetector with onTap: each must not be a part's only press"
else
  gate G4 PASS "behaviour from ui_core"
fi

# G5: the screens hold no paint of their own.
find "$app/lib" -name '*.dart' -not -path "$app/lib/design/*" -print0 |
  xargs -0 grep -nE "(^|[^.A-Za-z0-9_])(Color|BoxDecoration|ShapeDecoration|TextStyle|BorderSide|GestureDetector|InkWell)\(|Colors\." |
  grep -vE ':[0-9]+: *//' >"$log/G5.txt"
paint="$(wc -l <"$log/G5.txt" | tr -d ' ')"
if [ "$paint" = 0 ]; then
  gate G5 PASS "screens paint nothing of their own"
else
  gate G5 FAIL "$paint line(s) of paint outside lib/design: see $log/G5.txt"
fi

# G6: production grade.
hits="$(grep -rIniwE "todo|fixme|hack|wip|round [0-9]+" "$app/lib" "$app/test" 2>/dev/null | grep -v "test/score/" | wc -l | tr -d ' ')"
if [ "$hits" = 0 ]; then
  gate G6 PASS "no working notes"
else
  gate G6 FAIL "$hits line(s) of working notes in lib or test"
fi

echo "$failed gate(s) failed; logs in $log"
[ "$failed" = 0 ]
