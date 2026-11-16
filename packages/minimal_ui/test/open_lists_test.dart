// An open list says its choice as Minimal says one (the README's "Choice"):
// the chosen option's words in the full ink at medium weight, with its
// check, and the other options muted, so it reads at a glance and not only
// by a small check. The row a pointer or the keyboard is on takes the muted
// fill: a place, never a second choice, and never the selection's tint. In
// the select's menu and its sheet, the combobox's list, and a choice group.
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

const _options = [
  MinimalSelectOption('daily', 'Every day'),
  MinimalSelectOption('weekdays', 'Weekdays'),
  MinimalSelectOption('weekends', 'Weekends'),
];

Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: brightness,
    child: navigator!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(18), child: child),
  ),
);

/// The style of the last [words] on screen (the open list's, over the
/// field's own value).
TextStyle _style(WidgetTester tester, String words) =>
    tester.widget<Text>(find.text(words).last).style!;

/// The fill of the open list's row that says [words].
Color? _fill(WidgetTester tester, String words) {
  final row = find.ancestor(
    of: find.text(words).last,
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.decoration != null,
    ),
  );
  final decoration = tester.widget<Container>(row.first).decoration;
  return switch (decoration) {
    BoxDecoration(:final color) => color,
    ShapeDecoration(:final color) => color,
    _ => null,
  };
}

void _expectChoice(
  WidgetTester tester,
  MinimalThemeData t,
  String chosen,
  List<String> others,
  String why,
) {
  expect(_style(tester, chosen).color, t.foreground, reason: '$why: chosen');
  expect(
    _style(tester, chosen).fontWeight,
    FontWeight.w500,
    reason: '$why: chosen',
  );
  for (final other in others) {
    expect(
      _style(tester, other).color,
      t.mutedForeground,
      reason: '$why: $other',
    );
    expect(
      _style(tester, other).fontWeight,
      isNot(FontWeight.w500),
      reason: '$why: $other',
    );
  }
}

void main() {
  for (final brightness in Brightness.values) {
    final t = MinimalThemeData.preset('standard', brightness);
    final at = brightness.name;

    testWidgets('$at: the select\'s menu says its choice in ink and weight', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalSelect(
            label: 'Repeats',
            value: 'weekdays',
            options: _options,
            onChanged: (_) {},
          ),
          brightness,
        ),
      );
      await tester.tap(find.text('Weekdays'));
      await tester.pumpAndSettle();
      _expectChoice(tester, t, 'Weekdays', ['Every day', 'Weekends'], 'menu');
    });

    testWidgets('$at: the select\'s sheet says its choice in ink and weight', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalSelect(
            label: 'Repeats',
            value: 'weekdays',
            options: _options,
            presentation: MinimalSelectPresentation.sheet,
            onChanged: (_) {},
          ),
          brightness,
        ),
      );
      await tester.tap(find.text('Weekdays'));
      await tester.pumpAndSettle();
      _expectChoice(tester, t, 'Weekdays', ['Every day', 'Weekends'], 'sheet');
    });

    testWidgets('$at: the combobox says its choice, and the pointer\'s and '
        'the keyboard\'s row take the muted fill', (tester) async {
      await tester.pumpWidget(
        _host(
          MinimalCombobox<String>(
            label: 'City',
            options: const ['Lisbon', 'London', 'Lyon'],
            value: 'London',
            onSelected: (_) {},
          ),
          brightness,
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      // Every option, the chosen one among them.
      await tester.enterText(find.byType(EditableText), '');
      await tester.pumpAndSettle();
      _expectChoice(tester, t, 'London', ['Lisbon', 'Lyon'], 'combobox');
      // The pointer's row: the muted fill, its words still muted.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Lyon').last));
      await tester.pumpAndSettle();
      expect(_fill(tester, 'Lyon'), t.muted, reason: 'the pointer\'s row');
      expect(_fill(tester, 'Lyon'), isNot(t.selection));
      expect(_style(tester, 'Lyon').color, t.mutedForeground);
      // The chosen row keeps no fill: its words say it.
      expect(_fill(tester, 'London'), isNull);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      // The keyboard's row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final filled = [
        for (final city in const ['Lisbon', 'London', 'Lyon'])
          if (_fill(tester, city) != null) city,
      ];
      expect(filled, hasLength(1), reason: 'one row the keyboard is on');
      expect(_fill(tester, filled.single), t.muted);
    });

    testWidgets('$at: a choice group mutes all but its chosen row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalSelectionGroup(
            children: [
              for (final option in _options)
                MinimalChoiceRow(
                  title: option.label,
                  selected: option.value == 'weekends',
                  onPressed: () {},
                ),
            ],
          ),
          brightness,
        ),
      );
      _expectChoice(tester, t, 'Weekends', ['Every day', 'Weekdays'], 'group');
      // With nothing chosen, every option keeps the full ink.
      await tester.pumpWidget(
        _host(
          MinimalSelectionGroup(
            children: [
              for (final option in _options)
                MinimalChoiceRow(
                  title: option.label,
                  selected: false,
                  onPressed: () {},
                ),
            ],
          ),
          brightness,
        ),
      );
      for (final option in _options) {
        expect(_style(tester, option.label).color, t.foreground);
      }
    });
  }
}
