// A field's own open list (a select's, a combobox's, a multi-select's) stands clear of the field, and while it is up the
// field rests: the risen field's shadow never lands on the panel, the open list showing where the keys are. Once the
// list shuts, a field that keeps the keys rises again.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/field_list.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart'
    show NeumorphicPanel;

import 'support.dart';

const _rooms = ['Bedroom', 'Kitchen', 'Study'];

final _fields = <String, Widget Function()>{
  'a select': () => NeumorphicSelect<String>(
    labelText: 'Room',
    value: 'Bedroom',
    options: [for (final r in _rooms) NeumorphicMenuItem(r, r)],
    onChanged: (_) {},
  ),
  'a combobox': () => NeumorphicCombobox<String>(
    labelText: 'Room',
    hintText: 'Type a room',
    options: _rooms,
    onSelected: (_) {},
  ),
  'a multi-select': () => NeumorphicMultiSelect<String>(
    labelText: 'Rooms',
    values: const ['Bedroom'],
    options: _rooms,
    onChanged: (_) {},
  ),
};

/// The field's face: a select's tap face, a typed field's box.
Rect _face(WidgetTester tester, String name) => name == 'a select'
    ? tester.getRect(
        find.byWidgetPredicate(
          (w) => w is NeumorphicTap && (w.label ?? '').startsWith('Room,'),
        ),
      )
    : tester.getRect(find.byType(NeumorphicFieldBox).first);

/// The open list's panel: the look's menu for a select, a panel for a typed field's list.
Finder _panel(String name) => name == 'a select'
    ? find.byType(NeumorphicMenu<String>)
    : find.byType(NeumorphicPanel);

/// Whether the field shows the keys' focus: its well deepened (a select's too: a field never rises).
bool _risen(WidgetTester tester, String name) =>
    find.byType(CustomPaint).evaluate().where((e) {
      final painter = (e.widget as CustomPaint).painter;
      return painter.runtimeType.toString() == '_CastPainter' &&
          ((painter as dynamic).focus as double) > 0;
    }).isNotEmpty;

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final dark in [false, true]) {
    final mode = dark ? 'night' : 'day';
    for (final MapEntry(key: name, value: build) in _fields.entries) {
      for (final up in [false, true]) {
        final where = up ? 'opening above it' : 'opening below it';
        testWidgets('$name: its list stands clear of it, $where, and the field '
            'rests while the list is up, $mode', (tester) async {
          tester.view.physicalSize = const Size(1440, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final previous = FocusManager.instance.highlightStrategy;
          FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.alwaysTraditional;
          addTearDown(() => FocusManager.instance.highlightStrategy = previous);
          await tester.pumpWidget(
            neumorphicApp(
              Align(
                alignment: up ? Alignment.bottomCenter : Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: SizedBox(width: 320, child: build()),
                ),
              ),
              width: 1440,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          final before = _panel(name).evaluate().toSet();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          if (name == 'a select') {
            expect(_risen(tester, name), isTrue, reason: 'focused, shut');
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          } else {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          }
          await tester.pumpAndSettle();
          final panels = _panel(name)
              .evaluate()
              .where((e) => !before.contains(e))
              .toList();
          expect(panels, hasLength(1), reason: 'the list is open');
          final panel = tester.getRect(
            find.byElementPredicate((e) => identical(e, panels.single)),
          );
          final face = _face(tester, name);
          final gap = up ? face.top - panel.bottom : panel.top - face.bottom;
          expect(
            gap,
            greaterThanOrEqualTo(neumorphicFieldListGap - .5),
            reason: 'face $face, panel $panel',
          );
          expect(_risen(tester, name), isFalse, reason: 'its list is up');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(
            _panel(name).evaluate().where((e) => !before.contains(e)),
            isEmpty,
            reason: 'the list is shut',
          );
          expect(_risen(tester, name), isTrue, reason: 'shut, the keys on it');
        });
      }
    }
  }
}
