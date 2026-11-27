// Keyboard focus lights the lamp, legend or inner bezel a part already has,
// and the light stays inside its housing, by day and by night; a part whose
// lamp is already lit lights its bezel as well, and so does a switch or a
// chip, on or off, whose lamp shows only that it is on; a text key
// lights a plate clear of its words. A stepper's keys and window stay one
// height at any text size and step within their bounds, and a selector's
// lamps stand beside their words.
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

bool _changed(Uint8List a, Uint8List b, int i) =>
    (a[i] - b[i]).abs() >= 4 ||
    (a[i + 1] - b[i + 1]).abs() >= 4 ||
    (a[i + 2] - b[i + 2]).abs() >= 4;

// The contrast between pixel [i] of [a] and of [b], as WCAG reads two colours.
double _contrast(Uint8List a, Uint8List b, int i) {
  double luminance(Uint8List p) {
    double channel(int v) {
      final c = v / 255;
      return c <= 0.04045
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4) * 1.0;
    }

    return 0.2126 * channel(p[i]) +
        0.7152 * channel(p[i + 1]) +
        0.0722 * channel(p[i + 2]);
  }

  final x = luminance(a), y = luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

// How many of 24 sectors round [edge]'s centre hold a pixel of its rim (the
// band 4 points inside its edge) that reads at 1.5:1 or more between [before]
// and [after]: 24 when the light runs all the way round.
int _litSectors(Uint8List before, Uint8List after, int width, Rect edge) {
  final inner = edge.deflate(4);
  final sectors = <int>{};
  for (var i = 0; i + 3 < before.length; i += 4) {
    final at = Offset(
      ((i ~/ 4) % width + 0.5) / 2,
      ((i ~/ 4) ~/ width + 0.5) / 2,
    );
    if (!edge.inflate(1).contains(at) || inner.contains(at)) continue;
    if (_contrast(before, after, i) < 1.5) continue;
    final turn = ((at - edge.center).direction + math.pi) / (2 * math.pi);
    sectors.add((turn * 24).floor() % 24);
  }
  return sectors.length;
}

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
    'radio': RadioGroup<int>(
      groupValue: 1,
      onChanged: (_) {},
      child: const ApplianceRadio<int>(value: 1),
    ),
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
      value: const RawTimeOfDay(hour: 9, minute: 30),
      onChanged: (_) {},
    ),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: part) in parts.entries) {
      testWidgets(
        'a focused $name lights its fitted control by ${brightness.name}',
        (tester) async {
          _traditionalFocus();
          await _show(tester, part, brightness: brightness);
          final (before, width) = await _pixels(tester);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          final (after, _) = await _pixels(tester);
          final origin = tester.getTopLeft(find.byKey(_frame));
          final faces = _focusedFace();
          final lamps = find.byType(ApplianceLamp);
          final bounds = switch (name) {
            // A lamp already lit: the lamp brightens and the part's own
            // bezel lights.
            'switch, on' || 'chip' || 'radio' || 'selector' => [
              for (final el in lamps.evaluate())
                tester.getRect(find.byWidget(el.widget)),
              for (final el in faces.evaluate())
                tester.getRect(find.byWidget(el.widget)),
            ],
            _ => [
              tester.getRect(
                faces.evaluate().isEmpty ? find.byWidget(part) : faces.first,
              ),
            ],
          };
          var lit = 0, outside = 0;
          for (var i = 0; i < before.length; i += 4) {
            if (!_changed(before, after, i)) continue;
            final at =
                origin +
                Offset(
                  ((i ~/ 4) % width + 0.5) / 2,
                  ((i ~/ 4) ~/ width + 0.5) / 2,
                );
            if (bounds.any((rect) => rect.inflate(1).contains(at))) {
              lit++;
            } else {
              outside++;
            }
          }
          expect(lit, greaterThan(0), reason: 'The fitted light remained dark');
          expect(outside, 0, reason: 'The light escaped its housing');
        },
      );
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
          if (!_changed(before, after, i)) continue;
          if (text.contains(at)) onWords++;
          if (plate.inflate(1).contains(at)) lit++;
        }
        expect(onWords, 0, reason: 'the light crossed the words');
        expect(lit, greaterThan(0));
      });
    }
  }

  // A part whose lamp is already lit cannot show focus by brightening it, so
  // its bezel lights from inside: all the way round, some of the bezel's
  // pixels read at 1.5:1 or more against the same pixels at rest, and
  // nothing changes outside the part.
  final lit = <String, Widget>{
    'chosen selector position': SizedBox(
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
    'chosen radio': RadioGroup<int>(
      groupValue: 1,
      onChanged: (_) {},
      child: const ApplianceRadio<int>(value: 1),
    ),
    'chosen preset in a group': ApplianceRadioGroup<String>(
      options: const ['standard', 'next'],
      value: 'next',
      labelOf: (o) => o == 'next' ? 'Next day' : 'Standard',
      onChanged: (_) {},
    ),
    'switch, on': ApplianceSwitch(value: true, onChanged: (_) {}),
    'switch, off': ApplianceSwitch(value: false, onChanged: (_) {}),
    'selected chip': ApplianceChip(
      'Planning',
      selected: true,
      onSelected: (_) {},
    ),
    'chip, not selected': ApplianceChip('On offer', onSelected: (_) {}),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: part) in lit.entries) {
      testWidgets('a focused $name lights its bezel by ${brightness.name}', (
        tester,
      ) async {
        _traditionalFocus();
        await _show(tester, part, brightness: brightness);
        final (before, width) = await _pixels(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final (after, _) = await _pixels(tester);
        final origin = tester.getTopLeft(find.byKey(_frame));
        final face = tester.getRect(_focusedFace().first).shift(-origin);
        expect(
          _litSectors(before, after, width, face),
          24,
          reason: 'The bezel did not light all the way round',
        );
        var outside = 0;
        for (var i = 0; i + 3 < before.length; i += 4) {
          final at = Offset(
            ((i ~/ 4) % width + 0.5) / 2,
            ((i ~/ 4) ~/ width + 0.5) / 2,
          );
          if (!face.inflate(1).contains(at) && _changed(before, after, i)) {
            outside++;
          }
        }
        expect(outside, 0, reason: 'The light escaped the part');
      });
    }
  }

  // Beside a neighbour that is on or selected, each switch and chip in turn
  // takes the focus: its bezel lights all the way round, and no lamp in the
  // row changes, so focus is never read as on or selected.
  final rows = <String, Widget>{
    'switches': Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ApplianceSwitch(value: true, onChanged: (_) {}),
        const SizedBox(height: ApplianceSpacing.small),
        ApplianceSwitch(value: false, onChanged: (_) {}),
      ],
    ),
    'chips': Wrap(
      spacing: ApplianceSpacing.small,
      children: [
        ApplianceChip('Planning', selected: true, onSelected: (_) {}),
        ApplianceChip('On offer', onSelected: (_) {}),
        ApplianceChip('In stock', onSelected: (_) {}),
      ],
    ),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: row) in rows.entries) {
      testWidgets('focus on a row of $name leaves the lamps to mean on by '
          '${brightness.name}', (tester) async {
        _traditionalFocus();
        await _show(tester, row, brightness: brightness);
        final (rest, width) = await _pixels(tester);
        final origin = tester.getTopLeft(find.byKey(_frame));
        final lamps = [
          for (final lamp in find.byType(ApplianceLamp).evaluate())
            (lamp.renderObject! as RenderBox).localToGlobal(Offset.zero) &
                (lamp.renderObject! as RenderBox).size,
        ];
        final parts = name == 'chips' ? 3 : 2;
        expect(lamps, hasLength(parts));
        for (var part = 0; part < parts; part++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          final (focused, _) = await _pixels(tester);
          for (var i = 0; i + 3 < rest.length; i += 4) {
            final at =
                origin +
                Offset(
                  ((i ~/ 4) % width + 0.5) / 2,
                  ((i ~/ 4) ~/ width + 0.5) / 2,
                );
            if (!lamps.any((lamp) => lamp.inflate(1).contains(at))) continue;
            expect(
              _changed(rest, focused, i),
              isFalse,
              reason: 'Focus on $name $part changed a lamp',
            );
          }
          final face = tester.getRect(_focusedFace().first).shift(-origin);
          expect(
            _litSectors(rest, focused, width, face),
            24,
            reason: 'The bezel of $name $part did not light all the way round',
          );
        }
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
      final light = applianceFocusLight(
        c.focus,
        c.signal,
        bottom: Color.lerp(c.signal, c.signalBottom, 0.5),
        ink: c.onSignal,
      );
      expect(
        light.r,
        greaterThan(light.b),
        reason: 'The signal emits warm light',
      );
      expect(light.computeLuminance(), greaterThan(c.focus.computeLuminance()));
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'a menu command depresses only during a held press in ${brightness.name}',
      (tester) async {
        Future<void> show(Set<WidgetState> states) => _show(
          tester,
          SizedBox(
            width: 210,
            child: ApplianceMenuRow(label: 'Reorder', states: states),
          ),
          brightness: brightness,
        );
        double depth() => tester
            .widget<AnimatedApplianceSurface>(
              find.byType(AnimatedApplianceSurface),
            )
            .face
            .lift;
        await show({});
        final (idle, _) = await _pixels(tester);
        for (final state in [WidgetState.hovered, WidgetState.focused]) {
          await show({state});
          final (lit, _) = await _pixels(tester);
          expect(lit, isNot(orderedEquals(idle)), reason: state.name);
          expect(depth(), 0);
        }
        await show({WidgetState.pressed});
        expect(depth(), lessThan(0));
      },
    );
  }
}
