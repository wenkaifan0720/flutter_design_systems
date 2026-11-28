/// What a first app on Expressive found (an adopter's second round): a
/// docked calendar clear of its own field and closed by a pick, a slider's
/// value bubble inside the window, an expanded control as wide as the
/// column's fields, every palette's secondary roles in its seed's family,
/// and a radio row's highlight inside its column.
library;

import 'package:material_ui/material_ui.dart' show HSVColor, MaterialApp;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';

final _theme = ExpressiveThemeData.preset('baseline', Brightness.light);

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: ExpressiveHost(
        theme: _theme,
        brightness: Brightness.light,
        child: Directionality(textDirection: direction, child: child),
      ),
    );

void _window(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('the docked date picker', () {
    for (final (window, tops) in const [
      (Size(390, 844), [16.0, 380.0, 700.0]),
      (Size(1440, 900), [16.0, 420.0, 780.0]),
    ]) {
      for (final top in tops) {
        testWidgets('raises its calendar clear of its field: '
            '${window.width.round()} wide, the field at ${top.round()}', (
          tester,
        ) async {
          _window(tester, window);
          await tester.pumpWidget(
            _app(
              Stack(
                children: [
                  Positioned(
                    top: top,
                    left: 16,
                    width: 358,
                    child: ExpressiveDockedDatePicker(
                      value: DateTime(2026, 11, 20),
                      currentDate: DateTime(2026, 11, 27),
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          );
          await tester.tap(find.byType(ExpressiveIconButton));
          await tester.pumpAndSettle();
          final field = tester.getRect(find.byType(ExpressiveTextField));
          final calendar = tester.getRect(find.byType(ExpressiveDatePicker));
          expect(
            calendar.top >= field.bottom - 0.5 ||
                calendar.bottom <= field.top + 0.5,
            isTrue,
            reason: 'the calendar $calendar over its field $field',
          );
          expect(calendar.top, greaterThanOrEqualTo(0));
          expect(calendar.bottom, lessThanOrEqualTo(window.height));
          expect(tester.takeException(), isNull);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.byType(ExpressiveDatePicker), findsNothing);
        });
      }
    }

    testWidgets('closes once a day is picked, the field showing it', (
      tester,
    ) async {
      _window(tester, const Size(390, 844));
      DateTime? picked;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 358,
                child: ExpressiveDockedDatePicker(
                  value: picked ?? DateTime(2026, 11, 20),
                  currentDate: DateTime(2026, 11, 27),
                  onChanged: (day) => setState(() => picked = day),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ExpressiveIconButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(ExpressiveDatePicker),
              matching: find.text('12'),
            )
            .hitTestable()
            .first,
      );
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 11, 12));
      expect(find.byType(ExpressiveDatePicker), findsNothing);
      expect(find.text('12 Nov 2026'), findsOneWidget);
    });
  });

  for (final direction in TextDirection.values) {
    testWidgets("a slider's value bubble stays inside a phone's window at the "
        'end of its track (${direction.name})', (tester) async {
      _window(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ExpressiveSlider(
                value: 1.4,
                min: .8,
                max: 1.4,
                valueLabel: (v) => '${(v * 100).round()}%',
                onChanged: (_) {},
              ),
            ),
          ),
          direction: direction,
        ),
      );
      final track = tester.getRect(find.byType(ExpressiveSlider));
      final gesture = await tester.startGesture(
        Offset(
          direction == TextDirection.ltr ? track.right - 2 : track.left + 2,
          track.center.dy,
        ),
      );
      await tester.pumpAndSettle();
      final bubble = tester.getRect(
        find
            .ancestor(
              of: find.text('140%'),
              matching: find.byType(ExpressiveSurface),
            )
            .first,
      );
      expect(bubble.left, greaterThanOrEqualTo(0));
      expect(bubble.right, lessThanOrEqualTo(390));
      await gesture.up();
      await tester.pumpAndSettle();
    });
  }

  testWidgets("an expanded button and a segmented button take a desk's column "
      'as its fields do', (tester) async {
    _window(tester, const Size(1440, 900));
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 640,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                const ExpressiveTextField(labelText: 'Title'),
                ExpressiveSegmentedButton<int>(
                  expand: true,
                  segments: const [
                    ExpressiveButtonSegment(0, 'Want'),
                    ExpressiveButtonSegment(1, 'Reading'),
                    ExpressiveButtonSegment(2, 'Read'),
                  ],
                  value: 0,
                  onChanged: (_) {},
                ),
                ExpressiveFilledButton('Save', expand: true, onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    final field = tester.getRect(find.byType(ExpressiveTextField));
    expect(field.width, 640);
    // What is drawn: the button's container, the segments' outer edges.
    final button = tester.getRect(
      find
          .descendant(
            of: find.byType(ExpressiveFilledButton),
            matching: find.byType(ExpressiveSurface),
          )
          .first,
    );
    final segments = find.descendant(
      of: find.byType(ExpressiveSegmentedButton<int>),
      matching: find.byType(ExpressivePressable),
    );
    expect([button.left, button.right], [field.left, field.right]);
    expect(
      [
        tester.getRect(segments.first).left,
        tester.getRect(segments.last).right,
      ],
      [field.left, field.right],
    );
  });

  test("every palette keeps its secondary roles in its seed's family", () {
    double hue(Color c) => HSVColor.fromColor(c).hue;
    double saturation(Color c) => HSVColor.fromColor(c).saturation;
    for (final id in ExpressiveThemeData.palettes.map((p) => p.id)) {
      for (final brightness in Brightness.values) {
        final c = ExpressiveThemeData.preset(id, brightness).colors;
        for (final role in [c.secondary, c.secondaryContainer]) {
          if (saturation(role) < .12 || saturation(c.primary) < .12) continue;
          final apart = (hue(role) - hue(c.primary)).abs() % 360;
          expect(
            apart > 180 ? 360 - apart : apart,
            lessThan(45),
            reason: '$id ${brightness.name}: $role beside ${c.primary}',
          );
        }
      }
    }
  });

  testWidgets("a radio row with no space of its own keeps its highlight in its "
      'column, its mark on the edge', (tester) async {
    _window(tester, const Size(1440, 900));
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            key: const Key('column'),
            width: 640,
            child: ExpressiveRadioRow(
              label: 'Grove',
              selected: false,
              contentPadding: EdgeInsets.zero,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    final column = tester.getRect(find.byKey(const Key('column')));
    final highlight = tester.getRect(
      find
          .descendant(
            of: find.byType(ExpressiveRadioRow),
            matching: find.byType(ExpressiveSurface),
          )
          .first,
    );
    expect(highlight.left, greaterThanOrEqualTo(column.left));
    expect(highlight.right, lessThanOrEqualTo(column.right));
    final mark = tester.getRect(find.byType(ExpressiveRadio));
    final inset = _theme.density
        .padding(const EdgeInsets.all(RadioButtonBehavior.padding))
        .left;
    expect(mark.left + inset, closeTo(column.left, .5));
  });
}
