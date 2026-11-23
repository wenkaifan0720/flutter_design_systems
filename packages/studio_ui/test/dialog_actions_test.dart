// A dialog's actions stand in one row while their labels fit, and stack
// full width at one height, the main action first, when they do not; ui_core
// reads them so too on phones from 320 to 390.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void _none() {}

Future<Map<String, Rect>> _show(
  WidgetTester tester, {
  required double width,
  required TextDirection direction,
  required double scale,
  required List<String> labels,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, 1800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: StudioHost(brightness: Brightness.light, child: app!),
        ),
      ),
      home: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StudioDialog(
            title: 'Unsaved changes',
            content: const Text('Save your changes before leaving this task?'),
            actions: [
              for (final (i, label) in labels.indexed)
                i == 0 && labels.length > 2
                    ? StudioButton.text(label, onPressed: _none)
                    : i == labels.length - 1
                    ? StudioButton.lit(label, onPressed: _none)
                    : StudioButton(label, onPressed: _none),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return {
    for (final label in labels)
      label: tester.getRect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(StudioButton),
        ),
      ),
  };
}

void main() {
  setUpAll(studioLoadFonts);

  const three = ['Cancel', 'Discard', 'Save changes'];
  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('three actions at $width in ${direction.name} at '
            '${scale}x stand in one row or one even stack', (tester) async {
          final keys = await _show(
            tester,
            width: width,
            direction: direction,
            scale: scale,
            labels: three,
          );
          final rects = [for (final l in three) keys[l]!];
          final row = rects.every((r) => (r.top - rects.first.top).abs() < 0.5);
          for (final r in rects) {
            expect(
              r.height,
              moreOrLessEquals(rects.first.height, epsilon: 0.5),
            );
          }
          if (row) {
            // In reading order, the main action at the trailing edge.
            final xs = [for (final r in rects) r.center.dx];
            if (direction == TextDirection.ltr) {
              expect(xs, orderedEquals([...xs]..sort()));
            } else {
              expect(xs.reversed, orderedEquals([...xs]..sort()));
            }
          } else {
            // Full width, one size, the main action first and Cancel last.
            for (final r in rects) {
              expect(r.left, moreOrLessEquals(rects.first.left, epsilon: 0.5));
              expect(
                r.width,
                moreOrLessEquals(rects.first.width, epsilon: 0.5),
              );
            }
            expect(keys['Save changes']!.top, lessThan(keys['Discard']!.top));
            expect(keys['Discard']!.top, lessThan(keys['Cancel']!.top));
          }
          // A phone at 1x cannot fit three labels in a row; a wide screen can.
          if (scale == 1) expect(row, width > 600);
        });
      }
    }
  }

  testWidgets('two short actions share a phone\'s row equally', (tester) async {
    final keys = await _show(
      tester,
      width: 390,
      direction: TextDirection.ltr,
      scale: 1,
      labels: ['Keep', 'Discard'],
    );
    expect(keys['Keep']!.top, moreOrLessEquals(keys['Discard']!.top));
    expect(keys['Keep']!.width, moreOrLessEquals(keys['Discard']!.width));
    expect(keys['Keep']!.right, lessThan(keys['Discard']!.left));
  });

  // ui_core_test's DesignDialogActionsCheck on phones from 320 to 390, at
  // their text size and twice it.
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets("at $width, text at ${scale}x, the actions pass ui_core's "
          'dialog actions check', (tester) async {
        await _show(
          tester,
          width: width,
          direction: TextDirection.ltr,
          scale: scale,
          labels: three,
        );
        final report = const DesignDialogActionsCheck(
          look: 'studio',
          actions: three,
        ).check(tester.element(find.byType(StudioDialog)));
        expect(report.problems, isEmpty);
      });
    }
  }
}
