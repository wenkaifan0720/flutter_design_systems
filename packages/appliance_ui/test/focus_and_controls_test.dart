// Keyboard focus lights a part's own rim from inside: nothing is drawn round
// the part, and the focused pixels read at 3:1 or more against the same
// pixels unfocused over at least a 2 px perimeter, by day and by night. The
// stepper's keys and window are one height with room for its figures at any
// text size; a selector's lamps stand beside their words; a switch's slot is
// lit when on.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show Icons, MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _frame = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1688);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: ApplianceHost(brightness: brightness, child: app!),
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          // The part on the panel it stands on, so the capture holds what
          // is round it.
          child: RepaintBoundary(
            key: _frame,
            child: Builder(
              builder: (context) => ColoredBox(
                color: ApplianceTheme.of(context).colors.face,
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

Future<(Uint8List, int)> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_frame),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (data!.buffer.asUint8List(), image.width);
    } finally {
      image.dispose();
    }
  }))!;
}

double _channel(int v) {
  final c = v / 255;
  return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) * 1.0;
}

double _luminance(Uint8List p, int i) =>
    0.2126 * _channel(p[i]) +
    0.7152 * _channel(p[i + 1]) +
    0.0722 * _channel(p[i + 2]);

double _ratio(double a, double b) =>
    (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);

void _traditionalFocus() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

// The surface showing focus, and its face's focus light.
Finder _focusedFace() => find.descendant(
  of: find.byKey(_frame),
  matching: find.byWidgetPredicate(
    (w) =>
        (w is AnimatedApplianceSurface && w.face.focus.a > 0) ||
        (w is ApplianceSurface && w.face.focus.a > 0),
  ),
);

void main() {
  setUpAll(applianceLoadFonts);

  final parts = <String, Widget>{
    'key': ApplianceButton('Save', onPressed: () {}),
    'signal key': ApplianceButton.filled('Add entry', onPressed: () {}),
    'checkbox': ApplianceCheckbox(value: false, onChanged: (_) {}),
    'switch, on': ApplianceSwitch(value: true, onChanged: (_) {}),
    'chip': ApplianceChip('Planning', selected: true, onSelected: (_) {}),
    'selector': SizedBox(
      width: 320,
      child: ApplianceSegmentedButton<int>(
        segments: const [
          ApplianceSegment(value: 0, label: 'Low'),
          ApplianceSegment(value: 1, label: 'Normal'),
          ApplianceSegment(value: 2, label: 'High'),
        ],
        value: 2,
        onChanged: (_) {},
      ),
    ),
    'field': const SizedBox(width: 300, child: ApplianceTextField()),
    'stepper': ApplianceStepper(value: 45, min: 5, max: 480, onChanged: (_) {}),
    'time picker': ApplianceTimePicker(
      value: const ApplianceTime(9, 30),
      onChanged: (_) {},
    ),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: part) in parts.entries) {
      testWidgets('a focused $name lights its own rim by ${brightness.name}', (
        tester,
      ) async {
        _traditionalFocus();
        await _show(tester, part, brightness: brightness);
        final (before, width) = await _pixels(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final (after, _) = await _pixels(tester);
        final face = _focusedFace();
        expect(face, findsAtLeastNWidgets(1), reason: 'nothing took focus');
        final origin = tester.getTopLeft(find.byKey(_frame));
        final rect = tester.getRect(face.first).shift(-origin);
        // Inside the part, the lit rim: 3:1 over a 2 px perimeter, in
        // device pixels at 2x (four to a logical pixel). Outside it,
        // nothing changes.
        var lit = 0, outside = 0;
        for (var i = 0; i + 3 < before.length; i += 4) {
          final x = (i ~/ 4) % width / 2, y = (i ~/ 4) ~/ width / 2;
          final r = _ratio(_luminance(before, i), _luminance(after, i));
          if (rect.inflate(1).contains(Offset(x, y))) {
            if (r >= 3) lit++;
          } else if (r >= 1.2) {
            outside++;
          }
        }
        // The perimeter of the part's own shape: its corners rounded.
        final shape = switch (tester.widget(face.first)) {
          final AnimatedApplianceSurface w => w.face,
          final ApplianceSurface w => w.face,
          _ => throw StateError('no face'),
        };
        final corner = shape.circle
            ? rect.shortestSide / 2
            : math.min(shape.radius.topLeft.x, rect.shortestSide / 2);
        final perimeter =
            2 * (rect.width + rect.height) - (8 - 2 * math.pi) * corner;
        expect(lit, greaterThanOrEqualTo(2 * perimeter * 4));
        expect(outside, 0, reason: 'focus drew round the part');
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('a stepper\'s keys and window are one height at ${scale}x', (
      tester,
    ) async {
      await _show(
        tester,
        ApplianceStepper(value: 480, min: 5, max: 480, onChanged: (_) {}),
        textScale: scale,
      );
      final figure = tester.getRect(find.text('480'));
      final window = tester.getRect(
        find
            .ancestor(
              of: find.text('480'),
              matching: find.byType(ApplianceSurface),
            )
            .first,
      );
      final keys = tester
          .widgetList<AnimatedApplianceSurface>(
            find.descendant(
              of: find.byType(ApplianceStepper),
              matching: find.byType(AnimatedApplianceSurface),
            ),
          )
          .map((w) => tester.getRect(find.byWidget(w)))
          .toList();
      expect(keys, hasLength(2));
      for (final key in keys) {
        expect(key.height, moreOrLessEquals(window.height, epsilon: 0.5));
        expect(key.top, moreOrLessEquals(window.top, epsilon: 0.5));
      }
      // The figures have room either side, and are not cut.
      expect(figure.left - window.left, greaterThanOrEqualTo(8));
      expect(window.right - figure.right, greaterThanOrEqualTo(8));
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    for (final (name, part, words) in [
      (
        'text button',
        ApplianceButton.text('Delivery and returns', onPressed: () {}),
        'Delivery and returns',
      ),
      ('link', ApplianceLink('Terms', onPressed: () {}), 'Terms'),
    ]) {
      testWidgets('a focused $name lights a plate clear of its words by '
          '${brightness.name}', (tester) async {
        _traditionalFocus();
        await _show(tester, part, brightness: brightness);
        final (before, width) = await _pixels(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final (after, _) = await _pixels(tester);
        final origin = tester.getTopLeft(find.byKey(_frame));
        final box = tester.getRect(_focusedFace().first).shift(-origin);
        final text = tester.getRect(find.text(words)).shift(-origin);
        const reach = ApplianceSpacing.tight + ApplianceMetrics.focusWidth;
        final plate = box.inflate(reach);
        var lit = 0, onWords = 0;
        for (var i = 0; i + 3 < before.length; i += 4) {
          final x = (i ~/ 4) % width / 2, y = (i ~/ 4) ~/ width / 2;
          final at = Offset(x, y);
          final r = _ratio(_luminance(before, i), _luminance(after, i));
          if (r < 3) continue;
          if (text.contains(at)) onWords++;
          if (plate.inflate(1).contains(at)) lit++;
        }
        final corner = math.min(
          ApplianceMetrics.smallKeyRadius + reach,
          plate.shortestSide / 2,
        );
        final perimeter =
            2 * (plate.width + plate.height) - (8 - 2 * math.pi) * corner;
        expect(onWords, 0, reason: 'the light crossed the words');
        expect(lit, greaterThanOrEqualTo(2 * perimeter * 4));
      });
    }
  }

  testWidgets('a stepper moves by its step and stops at its bounds', (
    tester,
  ) async {
    var value = 45;
    Future<void> show() => _show(
      tester,
      ApplianceStepper(
        value: value,
        min: 5,
        max: 480,
        step: 15,
        semanticLabel: 'Estimate',
        onChanged: (v) => value = v,
      ),
    );
    final decrease = find.bySemanticsLabel('Decrease Estimate');
    final increase = find.bySemanticsLabel('Increase Estimate');
    await show();
    await tester.tap(increase);
    expect(value, 60);
    await show();
    await tester.tap(decrease);
    await show();
    await tester.tap(decrease);
    expect(value, 30);
    // A step past a bound stops at the bound, and that key goes dark.
    value = 10;
    await show();
    await tester.tap(decrease);
    expect(value, 5);
    await show();
    expect(tester.getSemantics(decrease), isSemantics(isEnabled: false));
    await tester.tap(decrease, warnIfMissed: false);
    expect(value, 5);
    value = 470;
    await show();
    await tester.tap(increase);
    expect(value, 480);
    await show();
    expect(tester.getSemantics(increase), isSemantics(isEnabled: false));
    await tester.tap(increase, warnIfMissed: false);
    expect(value, 480);
  });

  testWidgets('a selector\'s lamps stand beside their words', (tester) async {
    await _show(
      tester,
      SizedBox(
        width: 360,
        child: ApplianceSegmentedButton<int>(
          segments: const [
            ApplianceSegment(value: 0, label: 'Low'),
            ApplianceSegment(value: 1, label: 'Normal'),
            ApplianceSegment(value: 2, label: 'High'),
          ],
          value: 2,
          onChanged: (_) {},
        ),
      ),
    );
    final lamps = find.descendant(
      of: find.byType(ApplianceSegmentedButton<int>),
      matching: find.byType(ApplianceLamp),
    );
    expect(lamps, findsNWidgets(3));
    for (final (i, word) in ['Low', 'Normal', 'High'].indexed) {
      final lamp = tester.getRect(lamps.at(i));
      final text = tester.getRect(find.text(word));
      expect(text.left - lamp.right, inInclusiveRange(4, 12), reason: word);
      expect(
        lamp.center.dy,
        moreOrLessEquals(text.center.dy, epsilon: 2),
        reason: word,
      );
      expect(tester.widget<ApplianceLamp>(lamps.at(i)).lit, i == 2);
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets('a phone\'s selector with glyphs keeps one row at 1x in '
        '${direction.name}', (tester) async {
      await _show(
        tester,
        Directionality(
          textDirection: direction,
          child: SizedBox(
            width: 326,
            child: ApplianceSegmentedButton<int>(
              segments: const [
                ApplianceSegment(
                  value: 0,
                  label: 'Light',
                  icon: Icon(Icons.light_mode),
                ),
                ApplianceSegment(
                  value: 1,
                  label: 'Dark',
                  icon: Icon(Icons.dark_mode),
                ),
                ApplianceSegment(
                  value: 2,
                  label: 'System',
                  icon: Icon(Icons.computer),
                ),
              ],
              value: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final lamps = find.byType(ApplianceLamp);
      final icons = find.byType(Icon);
      final rtl = direction == TextDirection.rtl;
      for (final (i, word) in ['Light', 'Dark', 'System'].indexed) {
        final lamp = tester.getRect(lamps.at(i));
        final icon = tester.getRect(icons.at(i));
        final text = tester.getRect(find.text(word));
        // One row: lamp, glyph, words, centred on one line.
        expect(icon.center.dy, moreOrLessEquals(text.center.dy, epsilon: 2));
        expect(lamp.center.dy, moreOrLessEquals(text.center.dy, epsilon: 2));
        if (rtl) {
          expect(lamp.left, greaterThan(icon.right), reason: word);
          expect(icon.left, greaterThan(text.right), reason: word);
        } else {
          expect(lamp.right, lessThan(icon.left), reason: word);
          expect(icon.right, lessThan(text.left), reason: word);
        }
      }
    });
  }

  testWidgets('a stacked selector keeps each lamp over its words at 2x', (
    tester,
  ) async {
    await _show(
      tester,
      SizedBox(
        width: 326,
        child: ApplianceSegmentedButton<int>(
          segments: const [
            ApplianceSegment(
              value: 0,
              label: 'Light',
              icon: Icon(Icons.light_mode),
            ),
            ApplianceSegment(
              value: 1,
              label: 'Dark',
              icon: Icon(Icons.dark_mode),
            ),
            ApplianceSegment(
              value: 2,
              label: 'System',
              icon: Icon(Icons.computer),
            ),
          ],
          value: 0,
          onChanged: (_) {},
        ),
      ),
      textScale: 2,
    );
    final lamps = find.descendant(
      of: find.byType(ApplianceSegmentedButton<int>),
      matching: find.byType(ApplianceLamp),
    );
    expect(lamps, findsNWidgets(3));
    for (final (i, word) in ['Light', 'Dark', 'System'].indexed) {
      final lamp = tester.getRect(lamps.at(i));
      final text = tester.getRect(find.text(word));
      expect(lamp.bottom, lessThanOrEqualTo(text.top), reason: word);
      expect(text.top - lamp.bottom, lessThanOrEqualTo(12), reason: word);
      expect(tester.widget<ApplianceLamp>(lamps.at(i)).lit, i == 0);
      expect(
        tester.renderObject<RenderParagraph>(find.text(word)).size.height,
        lessThan(2 * 20 * 1.5),
        reason: '$word wrapped',
      );
    }
  });

  for (final brightness in Brightness.values) {
    testWidgets('a switch\'s slot is lit when on by ${brightness.name}', (
      tester,
    ) async {
      Color slot(bool on) => tester
          .widget<AnimatedApplianceSurface>(
            find
                .descendant(
                  of: find.byType(ApplianceSwitch),
                  matching: find.byType(AnimatedApplianceSurface),
                )
                .first,
          )
          .face
          .top;
      await _show(
        tester,
        ApplianceSwitch(value: false, onChanged: (_) {}),
        brightness: brightness,
      );
      final off = slot(false);
      await _show(
        tester,
        ApplianceSwitch(value: true, onChanged: (_) {}),
        brightness: brightness,
      );
      final c = ApplianceTheme.of(tester.element(find.byType(ApplianceSwitch)))
          .colors;
      expect(slot(true).toARGB32(), c.signal.toARGB32());
      expect(off.toARGB32(), c.trough.toARGB32());
      // Focused, the lit slot's rim keeps the switch's edge on the panel:
      // the legend's ink by day, white by night.
      final rim = applianceFocusLight(
        c.focus,
        c.signal,
        bottom: Color.lerp(c.signal, c.signalBottom, 0.5),
        ink: c.onSignal,
      );
      expect(applianceContrast(rim, c.face), greaterThanOrEqualTo(3));
      expect(applianceContrast(rim, c.signal), greaterThanOrEqualTo(3));
    });
  }
}
