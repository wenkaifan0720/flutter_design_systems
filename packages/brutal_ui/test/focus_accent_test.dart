// Keyboard focus marks a control's lower edge with the look's accent, the
// signal hue (darkened where the ground needs it), on every field as on a
// text field: a date field, a select, an input group, a code field, a tag
// input, a link, a file drop and a calendar's keyed day marked it in ink
// (or paper), and on an open date field the ink bar read as another kind of
// mark than the combobox's orange; on the calendar a paper bar under the
// keyed day read as today's underline.
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _k = ValueKey('control');

// The accent's pixels: the signal hue's orange, at any of the lightnesses
// the focus ink takes on a light or a dark ground.
Future<int> _accent(WidgetTester tester) async {
  final boundary = tester.renderObject(find.byKey(_k)) as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final n = image.width * image.height;
  image.dispose();
  var count = 0;
  for (var i = 0; i < n; i++) {
    final r = bytes.getUint8(i * 4);
    final g = bytes.getUint8(i * 4 + 1);
    final b = bytes.getUint8(i * 4 + 2);
    if (r > 120 && r - g > 70 && g > b && b < 90) count++;
  }
  return count;
}

void main() {
  final controls = <String, Widget Function()>{
    'a text field': () => const BrutalTextField(labelText: 'Name'),
    'a date field': () => BrutalDatePicker(
      labelText: 'Date',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'a select': () => BrutalSelect<String>(
      labelText: 'Venue',
      value: 'Hall 1',
      items: const [
        BrutalSelectItem(value: 'Hall 1', label: 'Hall 1'),
        BrutalSelectItem(value: 'Hall 2', label: 'Hall 2'),
      ],
      onChanged: (_) {},
    ),
    'an input group': () =>
        const BrutalInputGroup(labelText: 'Price', before: 'EUR'),
    'a code field': () => BrutalCodeField(length: 4, onCompleted: (_) {}),
    'a tag input': () => BrutalTagInput<String>(
      labelText: 'Kinds',
      values: const [],
      options: const ['Jazz', 'Folk'],
      displayStringForOption: (v) => v,
      onChanged: (_) {},
    ),
    'a link': () => BrutalLink('Read more', onPressed: () {}),
    'a file drop': () => BrutalFileDrop(labelText: 'Poster', onChoose: () {}),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: control) in controls.entries) {
      testWidgets('$name (${brightness.name}): focus marks it in the accent', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(600, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF000000),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, animation, secondary) => builder(context),
            ),
            builder: (context, navigator) => BrutalTheme(
              data: brightness == Brightness.light
                  ? BrutalThemeData.light()
                  : BrutalThemeData.dark(),
              child: navigator!,
            ),
            home: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                // The page holds the keyboard; Tab takes it to the control.
                child: FocusScope(
                  autofocus: true,
                  child: RepaintBoundary(
                    key: _k,
                    child: SizedBox(width: 360, child: control()),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(await _accent(tester), 0, reason: 'no accent before focus');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(await _accent(tester), greaterThan(60));
      });
    }

    testWidgets("a calendar's keyed day (${brightness.name}) is marked in the "
        'accent, not as today is', (tester) async {
      tester.view.physicalSize = const Size(600, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, _) => BrutalTheme(
            data: brightness == Brightness.light
                ? BrutalThemeData.light()
                : BrutalThemeData.dark(),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: RepaintBoundary(
                  key: _k,
                  child: SizedBox(
                    width: 358,
                    child: BrutalCalendar(
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2027, 12, 31),
                      selectedDate: DateTime(2026, 11, 20),
                      currentDate: DateTime(2026, 11, 22),
                      autofocus: true,
                      onDateChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The keys move the keyboard's day: the chosen day, then the next.
      for (final key in [
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(await _accent(tester), greaterThan(30), reason: '$key');
      }
    });
  }
}
