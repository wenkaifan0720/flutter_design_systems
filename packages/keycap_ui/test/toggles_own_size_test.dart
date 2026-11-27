// A switch, a checkbox and a radio keep their own size in any parent, as Material's do: under a field in a stretching
// column (the README's form) each stands at the column's start, and a switch's key slides to its own slot's end.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

Future<void> _form(
  WidgetTester tester, {
  required Size size,
  required TextDirection direction,
  required bool on,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: KeycapHost(brightness: Brightness.light, child: page!),
      ),
      home: KeycapScreen(
        maxWidth: 560,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KeycapTextField(labelText: 'Title'),
            KeycapField(
              labelText: 'Favourite',
              child: KeycapSwitch(value: on, onChanged: (_) {}),
            ),
            KeycapField(
              labelText: 'Finished',
              child: KeycapCheckbox(value: on, onChanged: (_) {}),
            ),
            KeycapField(
              labelText: 'Shelf',
              child: KeycapRadio<int>(
                value: 1,
                groupValue: on ? 1 : null,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

// The part a finger and an eye find: the control's tap target.
Rect _target(WidgetTester tester, Finder control) => tester.getRect(
  find.descendant(of: control, matching: find.byType(TapTargetPadding)).first,
);

void main() {
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    for (final direction in TextDirection.values) {
      final when = '${size.width.toInt()} ${direction.name}';

      testWidgets(
        '$when: a switch, a checkbox and a radio keep their own width under a stretching field',
        (tester) async {
          await _form(tester, size: size, direction: direction, on: true);
          final column = tester.getRect(find.byType(KeycapTextField));
          for (final control in [
            find.byType(KeycapSwitch),
            find.byType(KeycapCheckbox),
            find.byType(KeycapRadio<int>),
          ]) {
            final r = _target(tester, control);
            expect(
              r.width,
              lessThan(80),
              reason: '$control is ${r.width} wide',
            );
            if (direction == TextDirection.ltr) {
              expect(r.left, closeTo(column.left, 0.5), reason: '$control');
            } else {
              expect(r.right, closeTo(column.right, 0.5), reason: '$control');
            }
          }
        },
      );

      testWidgets("$when: a switch's key slides to its slot's end", (
        tester,
      ) async {
        await _form(tester, size: size, direction: direction, on: true);
        final well = tester.getRect(
          find.descendant(
            of: find.byType(KeycapSwitch),
            matching: find.byType(KeycapWell),
          ),
        );
        expect(well.size, const Size(KeycapSwitch.width, KeycapSwitch.height));
        final key = tester.getRect(
          find.descendant(
            of: find.byType(KeycapSwitch),
            matching: find.byType(AnimatedKeycapCap),
          ),
        );
        if (direction == TextDirection.ltr) {
          expect(key.right, closeTo(well.right - 2, 0.5));
        } else {
          expect(key.left, closeTo(well.left + 2, 0.5));
        }
      });
    }
  }

  testWidgets('a tap beside a switch in a wide field leaves it alone', (
    tester,
  ) async {
    var flips = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, page) =>
            KeycapHost(brightness: Brightness.light, child: page!),
        home: KeycapScreen(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeycapField(
                labelText: 'Favourite',
                child: KeycapSwitch(value: false, onChanged: (_) => flips++),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final field = tester.getRect(find.byType(KeycapField));
    await tester.tapAt(Offset(field.right - 20, field.bottom - 14));
    await tester.pump(const Duration(seconds: 1));
    expect(flips, 0);
    await tester.tapAt(tester.getCenter(find.byType(KeycapWell)));
    await tester.pump(const Duration(seconds: 1));
    expect(flips, 1);
  });

  testWidgets(
    'a switch, a checkbox and a radio keep their own width in a loose column too',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, page) =>
              KeycapHost(brightness: Brightness.light, child: page!),
          home: KeycapScreen(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeycapSwitch(value: true, onChanged: (_) {}),
                KeycapCheckbox(value: true, onChanged: (_) {}),
                KeycapRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      for (final control in [
        find.byType(KeycapSwitch),
        find.byType(KeycapCheckbox),
        find.byType(KeycapRadio<int>),
      ]) {
        expect(tester.getSize(control).width, lessThan(80), reason: '$control');
      }
    },
  );
}
