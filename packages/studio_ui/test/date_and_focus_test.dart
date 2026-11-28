// A date field's popover lines up with its field in one frame, up to a
// month's comfortable width from the field's leading edge, and its chosen day
// reads in its lit slot. The checkbox, the date field and a calendar day show
// keyboard focus as light on their own edge, kept inside the part.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

final _frame = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1688);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: StudioHost(brightness: brightness, child: app!),
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          // The part on the panel metal it stands on, so the capture holds
          // what is round it.
          child: RepaintBoundary(
            key: _frame,
            child: Builder(
              builder: (context) => ColoredBox(
                color: StudioTheme.of(context).colors.panel,
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
}

double _channel(int v) {
  final c = v / 255;
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) * 1.0;
}

double _luminance(int r, int g, int b) =>
    0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b);

double _ratio(double a, double b) =>
    (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);

double _contrast(Color a, Color b) => _ratio(
  a.computeLuminance(),
  Color.alphaBlend(b, const Color(0xFFFFFFFF)).computeLuminance(),
);

void _expectFittedLight(
  WidgetTester tester,
  Finder face,
  Uint8List before,
  Uint8List after,
) {
  final frame = find.byKey(_frame);
  final bounds = tester
      .getRect(face)
      .shift(-tester.getTopLeft(frame))
      .inflate(1);
  final width = (tester.getSize(frame).width * 2).round();
  var lit = 0, outside = 0;
  for (var i = 0; i + 3 < before.length; i += 4) {
    final a = _luminance(before[i], before[i + 1], before[i + 2]);
    final b = _luminance(after[i], after[i + 1], after[i + 2]);
    if (_ratio(a, b) < 1.025) continue;
    final point = Offset(
      ((i ~/ 4) % width + 0.5) / 2,
      ((i ~/ 4) ~/ width + 0.5) / 2,
    );
    if (bounds.contains(point)) {
      lit++;
    } else {
      outside++;
    }
  }
  expect(lit, greaterThan(0));
  expect(outside, 0, reason: 'Keyboard light escaped the fitted face');
}

void _traditionalFocus() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

StudioDatePicker _date({ValueChanged<DateTime?>? onChanged}) =>
    StudioDatePicker(
      value: DateTime(2026, 11, 9),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      currentDate: DateTime(2026, 11, 12),
      onChanged: onChanged ?? (_) {},
    );

bool _framed(WidgetTester tester) => tester
    .widgetList<StudioSurface>(
      find.descendant(
        of: find.byType(StudioCalendar),
        matching: find.byType(StudioSurface),
      ),
    )
    .any((s) => s.face.radius == StudioThemeData.light().radiusBank);

void main() {
  setUpAll(studioLoadFonts);

  for (final direction in TextDirection.values) {
    for (final width in [326.0, 240.0]) {
      testWidgets(
        'a date popover lines up with its $width px field in ${direction.name}',
        (tester) async {
          await _show(
            tester,
            SizedBox(width: width, child: _date()),
            direction: direction,
          );
          final field = tester.getRect(find.byType(StudioDatePicker));
          await tester.tap(find.byType(StudioDatePicker));
          await tester.pumpAndSettle();
          final panel = tester.getRect(find.byType(StudioListBezel));
          expect(panel.top, greaterThan(field.bottom));
          final rtl = direction == TextDirection.rtl;
          // A month needs 304 px: under a narrower field the popover keeps
          // that width from the field's leading edge.
          if (width >= 304) {
            expect(panel.left, moreOrLessEquals(field.left, epsilon: 0.5));
            expect(panel.right, moreOrLessEquals(field.right, epsilon: 0.5));
          } else {
            expect(panel.width, moreOrLessEquals(304, epsilon: 0.5));
            expect(
              rtl ? panel.right : panel.left,
              moreOrLessEquals(rtl ? field.right : field.left, epsilon: 0.5),
            );
          }
          // One frame: the bezel is the month's glass.
          expect(_framed(tester), isFalse);
        },
      );
    }
  }

  testWidgets('a calendar of its own keeps its glass frame', (tester) async {
    await _show(
      tester,
      SizedBox(
        width: 328,
        child: StudioCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          currentDate: DateTime(2026, 11, 12),
          selectedDate: DateTime(2026, 11, 9),
          onDateChanged: (_) {},
        ),
      ),
    );
    expect(_framed(tester), isTrue);
  });

  for (final direction in TextDirection.values) {
    testWidgets('a wide date field keeps a month\'s comfortable width from '
        'its leading edge in ${direction.name}', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(1440 * 2, 1688);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => Directionality(
            textDirection: direction,
            child: StudioHost(brightness: Brightness.light, child: app!),
          ),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 720, child: _date()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(StudioDatePicker));
      await tester.tap(find.byType(StudioDatePicker));
      await tester.pumpAndSettle();
      final panel = tester.getRect(find.byType(StudioListBezel));
      // About 400 px: seven days at a key's widest slot, so the week scans.
      expect(panel.width, inInclusiveRange(380, 450));
      final rtl = direction == TextDirection.rtl;
      expect(
        rtl ? panel.right : panel.left,
        moreOrLessEquals(rtl ? field.right : field.left, epsilon: 0.5),
      );
      final slot = tester.getRect(
        find
            .ancestor(
              of: find.text('9'),
              matching: find.byType(AnimatedStudioSurface),
            )
            .first,
      );
      expect(slot.width, lessThan(slot.height * 1.5));
    });
  }

  testWidgets('a date field as wide as a comfortable month matches it', (
    tester,
  ) async {
    await _show(tester, SizedBox(width: 358, child: _date()));
    final field = tester.getRect(find.byType(StudioDatePicker));
    await tester.tap(find.byType(StudioDatePicker));
    await tester.pumpAndSettle();
    final panel = tester.getRect(find.byType(StudioListBezel));
    expect(panel.left, moreOrLessEquals(field.left, epsilon: 0.5));
    expect(panel.right, moreOrLessEquals(field.right, epsilon: 0.5));
  });

  for (final brightness in Brightness.values) {
    testWidgets('the chosen day reads in its lit slot by ${brightness.name}', (
      tester,
    ) async {
      await _show(
        tester,
        SizedBox(
          width: 328,
          child: StudioCalendar.range(
            firstDate: DateTime(2026, 11),
            lastDate: DateTime(2026, 11, 30),
            currentDate: DateTime(2026, 11, 2),
            selectedRange: StudioDateRange(
              start: DateTime(2026, 11, 9),
              end: DateTime(2026, 11, 13),
            ),
            onRangeChanged: (_) {},
          ),
        ),
        brightness: brightness,
      );
      Color ink(String day) => tester
          .renderObject<RenderParagraph>(find.text(day))
          .text
          .style!
          .color!;
      for (final end in ['9', '13']) {
        final face = tester
            .widget<AnimatedStudioSurface>(
              find
                  .ancestor(
                    of: find.text(end),
                    matching: find.byType(AnimatedStudioSurface),
                  )
                  .first,
            )
            .face;
        expect(face.presence, 1, reason: end);
        expect(_contrast(ink(end), face.fill), greaterThanOrEqualTo(4.5));
        expect(_contrast(ink(end), face.fillLow), greaterThanOrEqualTo(4.5));
      }
      final c = StudioTheme.of(tester.element(find.byType(StudioCalendar)))
          .colors;
      final band = Color.lerp(c.displayLow, c.shadow, 0.05)!;
      expect(_contrast(ink('11'), band), greaterThanOrEqualTo(4.5));
    });
  }

  final parts = <String, Widget Function(FocusNode node)>{
    'checkbox': (node) =>
        StudioCheckbox(value: false, onChanged: (_) {}, focusNode: node),
    'checked checkbox': (node) =>
        StudioCheckbox(value: true, onChanged: (_) {}, focusNode: node),
    // Tab reaches the field's window, its first stop.
    'date field': (_) => SizedBox(width: 326, child: _date()),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: part) in parts.entries) {
      testWidgets('a focused $name lights its own edge by ${brightness.name}', (
        tester,
      ) async {
        _traditionalFocus();
        final node = FocusNode();
        addTearDown(node.dispose);
        await _show(tester, part(node), brightness: brightness);
        final before = await _pixels(tester);
        if (name == 'date field') {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        } else {
          node.requestFocus();
        }
        await tester.pumpAndSettle();
        final after = await _pixels(tester);
        final face = find
            .descendant(
              of: find.byKey(_frame),
              matching: find.byType(AnimatedStudioSurface),
            )
            .first;
        // No ring drawn apart from the part.
        expect(tester.widget<AnimatedStudioSurface>(face).face.focus.a, 0);
        _expectFittedLight(tester, face, before, after);
      });
    }
    testWidgets('a focused calendar day lights its own edge by '
        '${brightness.name}', (tester) async {
      _traditionalFocus();
      Widget month(bool focus) => SizedBox(
        key: ValueKey(focus),
        width: 328,
        child: StudioCalendar(
          firstDate: DateTime(2026, 11),
          lastDate: DateTime(2026, 11, 30),
          currentDate: DateTime(2026, 11, 2),
          selectedDate: DateTime(2026, 11, 9),
          autofocus: focus,
          onDateChanged: (_) {},
        ),
      );
      await _show(tester, month(false), brightness: brightness);
      final before = await _pixels(tester);
      await _show(tester, month(true), brightness: brightness);
      final after = await _pixels(tester);
      final slot = find
          .ancestor(
            of: find.text('9'),
            matching: find.byType(AnimatedStudioSurface),
          )
          .first;
      expect(tester.widget<AnimatedStudioSurface>(slot).face.focus.a, 0);
      _expectFittedLight(tester, slot, before, after);
    });
  }
}
