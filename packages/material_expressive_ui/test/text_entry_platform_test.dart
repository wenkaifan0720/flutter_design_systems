// Text entry on a desktop platform (design6 I3; the user, 11-10, on a served
// demo: "the hint text is not aligned correctly vertically"). Material's
// InputDecorator adds ThemeData.visualDensity to a field, and Flutter's
// default for it is compact on macOS, Windows and Linux. Tests run as
// Android, so nothing saw it. Here every text-entry part is pumped as Android
// and as macOS at each of the look's densities: its hint stands where its
// typed text does, within half a pixel, that line on the box's middle (by its
// capitals, which row_alignment_test reads), and the part is the same size,
// its text in the same place, on both platforms.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

/// One text-entry part: [build] it empty (its hint showing) or holding
/// text; [box] is the container its line is centred in, or null when the
/// line is not centred (a floating label above it, several lines).
typedef _Part = ({
  String name,
  Widget Function(bool typed) build,
  Finder? box,
  String? hint,
});

Finder _private(String type) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == type);

/// The editable line a part shows (its first, for the time input's hour).
final Finder _line = _private('_Editable');

TextEditingController _text(bool typed, String text) =>
    TextEditingController(text: typed ? text : '');

final List<_Part> _parts = [
  for (final kind in ExpressiveTextFieldKind.values) ...[
    (
      name: 'text field ${kind.name}',
      build: (typed) => ExpressiveTextField(
        kind: kind,
        controller: _text(typed, 'Kirk Creek'),
        hintText: 'Campground',
      ),
      box: find.byType(ExpressiveTextField),
      hint: 'Campground',
    ),
    (
      name: 'text field ${kind.name}, labelled',
      build: (typed) => ExpressiveTextField(
        kind: kind,
        controller: _text(typed, 'Kirk Creek'),
        label: 'Where you stay',
        hintText: 'Campground',
      ),
      box: null,
      hint: null,
    ),
    (
      name: 'password ${kind.name}',
      build: (typed) => ExpressivePasswordField(
        kind: kind,
        controller: _text(typed, 'trailhead'),
        hintText: 'Password',
      ),
      box: find.byType(ExpressivePasswordField),
      hint: 'Password',
    ),
    (
      name: 'select ${kind.name}',
      build: (typed) => ExpressiveSelect<String>(
        kind: kind,
        value: typed ? 'camp' : null,
        hintText: 'Choose a stay',
        options: const [
          ExpressiveSelectOption('camp', 'Kirk Creek'),
          ExpressiveSelectOption('lodge', 'Big Sur Lodge'),
        ],
        onChanged: (_) {},
      ),
      box: find.byType(ExpressiveSelect<String>),
      hint: 'Choose a stay',
    ),
    (
      name: 'text area ${kind.name}',
      build: (typed) => ExpressiveTextArea(
        kind: kind,
        controller: _text(typed, 'Bring the stove.'),
        label: 'Notes',
      ),
      box: null,
      hint: null,
    ),
  ],
  (
    name: 'search field',
    build: (typed) => ExpressiveSearchField(
      controller: _text(typed, 'packing'),
      hintText: 'Search shared items',
    ),
    box: find.byType(ExpressiveSearchField),
    hint: 'Search shared items',
  ),
  (
    name: 'input group',
    build: (typed) => ExpressiveInputGroup(
      controller: _text(typed, 'bigsur.example'),
      hintText: 'example.com',
      leading: [ExpressiveInputGroup.text('https://')],
    ),
    box: find.byType(ExpressiveInputGroup),
    hint: 'example.com',
  ),
  (
    name: 'docked date',
    build: (typed) => ExpressiveDockedDatePicker(
      label: 'Leave',
      value: typed ? DateTime(2026, 12, 11) : null,
      onChanged: (_) {},
    ),
    box: null,
    hint: null,
  ),
  // The multi-select's and the command palette's fields hold what is typed
  // only while typing: both pumps show the empty line.
  (
    name: 'multi-select',
    build: (_) => ExpressiveMultiSelect<String>(
      hintText: 'Add topics',
      options: const [
        ExpressiveSelectOption('hikes', 'Hikes'),
        ExpressiveSelectOption('food', 'Food'),
      ],
      values: const [],
      onChanged: (_) {},
    ),
    box: find.byType(ExpressiveMultiSelect<String>),
    hint: 'Add topics',
  ),
  (
    name: 'time input',
    build: (typed) => ExpressiveTimeInput(
      controller: ExpressiveTimePickerController(hour: 7, minute: 30),
    ),
    box: _private('_TimeInputPlate'),
    hint: null,
  ),
];

/// Where a pumped part stands: its size, its hint's and its line's
/// vertical centres, and its box's.
typedef _Measure = ({
  Size size,
  double? hint,
  double line,
  double lineHeight,
  double? box,
});

_Measure _measure(WidgetTester tester, _Part part, bool typed) {
  final root = find.byKey(const ValueKey('part'));
  final line = find.descendant(of: root, matching: _line).first;
  final hint = part.hint == null || typed
      ? null
      : find.descendant(of: root, matching: find.text(part.hint!));
  return (
    size: tester.getSize(root),
    hint: hint == null || hint.evaluate().isEmpty
        ? null
        : tester.getRect(hint.first).center.dy,
    line: tester.getRect(line).center.dy,
    lineHeight: tester.getRect(line).height,
    box: part.box == null
        ? null
        : tester
              .getRect(find.descendant(of: root, matching: part.box!).first)
              .center
              .dy,
  );
}

void main() {
  for (final (label, density) in [
    ('standard', ExpressiveDensity.standard),
    ('comfortable', ExpressiveDensity.comfortable),
    ('compact', ExpressiveDensity.compact),
  ]) {
    for (final part in _parts) {
      testWidgets('${part.name} at $label density: the line on '
          "the box's centre, the same on macOS as on Android", (tester) async {
        final theme = ExpressiveThemeData.preset(
          'baseline',
          Brightness.light,
        ).copyWith(density: density);
        final measured = <TargetPlatform, List<_Measure>>{};
        try {
          for (final platform in [
            TargetPlatform.android,
            TargetPlatform.macOS,
          ]) {
            debugDefaultTargetPlatformOverride = platform;
            for (final typed in [false, true]) {
              await tester.pumpWidget(
                MaterialApp(
                  key: ValueKey('$platform/$typed'),
                  home: ExpressiveHost(
                    light: theme,
                    brightness: Brightness.light,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: SizedBox(
                        width: 360,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            KeyedSubtree(
                              key: const ValueKey('part'),
                              child: part.build(typed),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              (measured[platform] ??= []).add(_measure(tester, part, typed));
            }
          }
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        final failures = <String>[];
        for (final MapEntry(key: platform, value: states) in measured.entries) {
          for (final (i, m) in states.indexed) {
            final what = '${platform.name}, ${i == 0 ? 'empty' : 'typed'}';
            // The line is drawn by its capitals on the box's middle
            // (DesignCapCenter; row_alignment_test's DesignTextEntryCheck
            // reads the capitals): its line box sits off the middle by the
            // typeface's ascent and descent, a few pixels at most, and the
            // hint stands where the typed line does.
            if (m.box case final box?) {
              if (m.hint case final hint?
                  when (hint - states[1].line).abs() > .5) {
                failures.add(
                  '$what: the hint at $hint, the typed line at '
                  '${states[1].line}',
                );
              }
              // A few pixels for body text; a time input's display digits
              // carry a larger offset, a tenth of their line.
              final slack = m.lineHeight * .1 > 3 ? m.lineHeight * .1 : 3.0;
              if (i == 1 && (m.line - box).abs() > slack) {
                failures.add('$what: the text at ${m.line}, the box at $box');
              }
            }
          }
        }
        final android = measured[TargetPlatform.android]!;
        final macOS = measured[TargetPlatform.macOS]!;
        for (var i = 0; i < 2; i++) {
          if (macOS[i].size != android[i].size) {
            failures.add('macOS ${macOS[i].size}, Android ${android[i].size}');
          }
          if ((macOS[i].line - android[i].line).abs() > .5) {
            failures.add(
              'the line at ${macOS[i].line} on macOS, '
              '${android[i].line} on Android',
            );
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  }
}
