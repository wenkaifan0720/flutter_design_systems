// Figures show whole at any text size, as Material's do: a time picker's
// hours and minutes (which grow up to 2x, as Material's time picker's do)
// and a stepper's number are never cut by their window, and no key over,
// under or beside them covers them; a calendar's days (up to 2x, as
// Material's) are whole in their keys and its weekdays clear of each other;
// a date field holds its date whole. At 1x, 2x and 3x text, on a phone and
// a wide screen.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  required double width,
  required double scale,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, 1200 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: ApplianceHost(brightness: Brightness.light, child: app!),
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

// The figure [text]'s painted words: whole within its own box, and its box
// within the window face that holds it (or, with [ink], its figures' ink,
// from their tops to their baseline, within the face: a key may draw a
// line's leading past its edge, never a figure).
Rect _figure(WidgetTester tester, String text, {bool ink = false}) {
  final found = find.text(text);
  expect(found, findsOneWidget, reason: text);
  final paragraph = tester.renderObject<RenderParagraph>(found);
  expect(paragraph.didExceedMaxLines, isFalse, reason: '$text wrapped');
  final words = paragraph.getMaxIntrinsicWidth(double.infinity);
  expect(
    paragraph.size.width,
    greaterThanOrEqualTo(words - 0.5),
    reason: '$text is cut across',
  );
  expect(
    paragraph.size.height,
    greaterThanOrEqualTo(paragraph.getMinIntrinsicHeight(words) - 0.5),
    reason: '$text is cut top or bottom',
  );
  final rect = tester.getRect(found);
  final face = find
      .ancestor(
        of: found,
        matching: find.byWidgetPredicate(
          (w) => w is AnimatedApplianceSurface || w is ApplianceSurface,
        ),
      )
      .first;
  final window = tester.getRect(face);
  var shown = rect;
  if (ink) {
    final baseline = paragraph.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final style = tester.widget<Text>(found).style!;
    final scaler = MediaQuery.textScalerOf(tester.element(found));
    final cap =
        scaler.scale(style.fontSize!) *
        ApplianceTheme.of(tester.element(found)).capHeightFactor;
    shown = Rect.fromPoints(
      paragraph.localToGlobal(Offset(0, baseline - cap)),
      paragraph.localToGlobal(Offset(paragraph.size.width, baseline)),
    );
  }
  expect(
    window.inflate(0.5).contains(shown.topLeft) &&
        window.inflate(0.5).contains(shown.bottomRight),
    isTrue,
    reason: '$text ($shown) leaves its window ($window)',
  );
  return rect;
}

RawCalendarController _calendar(WidgetTester tester) {
  final controller = RawCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027),
    selectedDate: DateTime(2026, 11, 18),
    currentDate: DateTime(2026, 11, 18),
  );
  addTearDown(controller.dispose);
  return controller;
}

// Each key's visible face.
List<Rect> _keys(WidgetTester tester, Finder glyphs) => [
  for (final glyph in glyphs.evaluate())
    tester.getRect(
      find
          .ancestor(
            of: find.byElementPredicate((e) => e == glyph),
            matching: find.byType(AnimatedApplianceSurface),
          )
          .first,
    ),
];

void main() {
  setUpAll(applianceLoadFonts);

  for (final width in [390.0, 1440.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      for (final twentyFour in [true, false]) {
        testWidgets('a ${twentyFour ? '24' : '12'}-hour time picker shows its '
            'figures whole and clear of its keys at $width, ${scale}x', (
          tester,
        ) async {
          await _show(
            tester,
            ApplianceTimePicker(
              value: const ApplianceTime(9, 30),
              twentyFourHour: twentyFour,
              onChanged: (_) {},
            ),
            width: width,
            scale: scale,
          );
          final figures = [
            _figure(tester, twentyFour ? '09' : '9'),
            _figure(tester, '30'),
          ];
          final keys = _keys(
            tester,
            find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is ApplianceChevronPainter,
            ),
          );
          expect(keys, hasLength(4));
          if (!twentyFour) {
            _figure(tester, 'AM');
            _figure(tester, 'PM');
          }
          for (final figure in figures) {
            for (final key in keys) {
              expect(
                key.overlaps(figure.deflate(0.5)),
                isFalse,
                reason: 'a key ($key) covers a figure ($figure)',
              );
            }
          }
        });
      }

      testWidgets('a calendar shows its days whole and its weekdays apart '
          'at $width, ${scale}x', (tester) async {
        await _show(
          tester,
          SizedBox(
            width: 358,
            child: ApplianceCalendar(controller: _calendar(tester)),
          ),
          width: width,
          scale: scale,
        );
        for (final day in ['8', '18', '28']) {
          _figure(tester, day, ink: true);
        }
        final weekdays = [
          for (final e
              in find
                  .descendant(
                    of: find.byType(ApplianceCalendar),
                    matching: find.byType(Text),
                  )
                  .evaluate()
                  .take(9))
            if ((e.widget as Text).data case final String t
                when t.length <= 3 && int.tryParse(t) == null)
              tester.getRect(find.byElementPredicate((x) => x == e)),
        ];
        expect(weekdays, hasLength(7));
        for (var i = 1; i < weekdays.length; i++) {
          expect(
            weekdays[i].overlaps(weekdays[i - 1].deflate(0.5)),
            isFalse,
            reason: 'two weekdays run into each other',
          );
        }
      });

      testWidgets('a date field holds its date whole at $width, ${scale}x', (
        tester,
      ) async {
        await _show(
          tester,
          SizedBox(
            width: 358,
            child: ApplianceDatePicker(
              label: 'Due date',
              value: DateTime(2026, 11, 20),
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              onChanged: (_) {},
            ),
          ),
          width: width,
          scale: scale,
        );
        final words = find.text('Nov 20, 2026');
        final paragraph = tester.renderObject<RenderParagraph>(words);
        expect(paragraph.didExceedMaxLines, isFalse);
        final face = tester.getRect(
          find
              .ancestor(
                of: words,
                matching: find.byType(AnimatedApplianceSurface),
              )
              .first,
        );
        final box = tester.getRect(words);
        expect(
          face.contains(box.topLeft) && face.contains(box.bottomRight),
          isTrue,
          reason: 'the date ($box) leaves its field ($face)',
        );
      });

      testWidgets('a stepper shows its number whole and clear of its keys at '
          '$width, ${scale}x', (tester) async {
        await _show(
          tester,
          ApplianceStepper(
            value: 120,
            min: 5,
            max: 480,
            step: 15,
            semanticLabel: 'Estimate',
            onChanged: (_) {},
          ),
          width: width,
          scale: scale,
        );
        final figure = _figure(tester, '120');
        final keys = [
          for (final key
              in find
                  .descendant(
                    of: find.byType(ApplianceStepper),
                    matching: find.byType(AnimatedApplianceSurface),
                  )
                  .evaluate())
            tester.getRect(find.byElementPredicate((e) => e == key)),
        ];
        expect(keys, hasLength(2));
        for (final key in keys) {
          expect(key.overlaps(figure.deflate(0.5)), isFalse);
        }
      });
    }
  }
}
