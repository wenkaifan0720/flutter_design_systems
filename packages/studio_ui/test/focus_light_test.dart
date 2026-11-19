// Every focusable Studio part shows keyboard focus as lit gear does: its
// own edge lights amber, hugging the part with no gap, and a soft glow
// spills round it. Over at least a 2 px perimeter of the part the focused
// pixels read at 3:1 or more against the same pixels unfocused, by day and
// by night.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:studio_ui/studio_ui.dart';

final _frame = GlobalKey();

Future<void> _show(
  WidgetTester tester,
  Widget child,
  Brightness brightness,
) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1688);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          StudioHost(brightness: brightness, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
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

void _none() {}

// The focused part's outline (relative to the frame) and its perimeter.
typedef _Shape = (Rect, double);

_Shape _faceShape(WidgetTester tester, Offset origin) {
  final face = find.descendant(
    of: find.byKey(_frame),
    matching: find.byWidgetPredicate(
      (w) =>
          (w is AnimatedStudioSurface && w.face.focus.a > 0) ||
          (w is StudioSurface && w.face.focus.a > 0),
    ),
  );
  expect(face, findsAtLeastNWidgets(1), reason: 'nothing lit its edge');
  final rect = tester.getRect(face.first).shift(-origin);
  final radius = switch (tester.widget(face.first)) {
    final AnimatedStudioSurface w => w.face.radius,
    final StudioSurface w => w.face.radius,
    _ => 0.0,
  };
  final corner = math.min(radius, rect.shortestSide / 2);
  return (rect, 2 * (rect.width + rect.height) - (8 - 2 * math.pi) * corner);
}

void main() {
  setUpAll(studioLoadFonts);

  final parts = <String, (Widget, _Shape Function(WidgetTester, Offset))>{
    'key': (const StudioButton('Save', onPressed: _none), _faceShape),
    'lit key': (
      const StudioButton.lit('Publish', onPressed: _none),
      _faceShape,
    ),
    'icon key': (
      const StudioIconButton(
        icon: Icon(LucideIcons.heart),
        tooltip: 'Save',
        onPressed: _none,
      ),
      _faceShape,
    ),
    'transport key': (
      const StudioTransportKey(
        icon: Icon(LucideIcons.play),
        tooltip: 'Play',
        onPressed: _none,
      ),
      _faceShape,
    ),
    'floating key': (
      const StudioFloatingKey(
        icon: Icon(LucideIcons.mic),
        tooltip: 'Record',
        onPressed: _none,
      ),
      _faceShape,
    ),
    'switch': (
      StudioSwitch(value: true, semanticLabel: 'Auto', onChanged: (_) {}),
      (tester, origin) {
        // The switch paints its slot itself: the slot is its painted box.
        final slot = tester
            .getRect(
              find
                  .descendant(
                    of: find.byType(StudioSwitch),
                    matching: find.byWidgetPredicate(
                      (w) => w is CustomPaint && w.painter != null,
                    ),
                  )
                  .last,
            )
            .shift(-origin);
        final corner = math.min(StudioRadii.small + 1, slot.shortestSide / 2);
        return (
          slot,
          2 * (slot.width + slot.height) - (8 - 2 * math.pi) * corner,
        );
      },
    ),
    'chip': (
      StudioChip(label: 'Interviews', selected: true, onSelected: (_) {}),
      _faceShape,
    ),
    'selector': (
      StudioSegmentedButton<int>(
        semanticLabel: 'Speed',
        segments: const [
          StudioSegment(value: 0, label: '1×'),
          StudioSegment(value: 1, label: '1.5×'),
          StudioSegment(value: 2, label: '2×'),
        ],
        value: 0,
        onChanged: (_) {},
      ),
      _faceShape,
    ),
    'text field': (
      SizedBox(
        width: 300,
        child: StudioTextField(label: 'Title', onChanged: (_) {}),
      ),
      _faceShape,
    ),
    'search field': (
      SizedBox(width: 300, child: StudioSearchField(onChanged: (_) {})),
      _faceShape,
    ),
    'input group': (
      SizedBox(
        width: 300,
        child: StudioInputGroup(
          label: 'Feed address',
          leading: const Text('https://'),
          onChanged: (_) {},
        ),
      ),
      _faceShape,
    ),
    // Its entry: with no tags, Tab lands there first.
    'tag input': (
      SizedBox(
        width: 300,
        child: StudioTagInput<String>(
          label: 'Guests',
          values: const [],
          onChanged: (_) {},
          labelOf: (v) => v,
        ),
      ),
      _faceShape,
    ),
    'select': (
      SizedBox(
        width: 300,
        child: StudioSelect<String>(
          label: 'Quality',
          value: 'High',
          items: const [
            StudioSelectItem(value: 'High', label: 'High'),
            StudioSelectItem(value: 'Low', label: 'Low'),
          ],
          onChanged: (_) {},
        ),
      ),
      _faceShape,
    ),
    'tab': (
      StudioTabBar(
        tabs: const ['Episodes', 'About'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      (tester, origin) {
        // A tab has no face: its legend's plate stands round its words, its
        // lit edge reaching a little beyond them.
        final words = tester.getRect(find.text('Episodes')).shift(-origin);
        const w = StudioMetrics.focusWidth;
        final plate = Rect.fromLTRB(
          words.left - StudioSpacing.tight + w,
          words.top - StudioSpacing.hair + w,
          words.right + StudioSpacing.tight - w,
          words.bottom + StudioSpacing.hair - w,
        );
        final corner = math.max(0.0, StudioRadii.small - w);
        return (
          plate,
          2 * (plate.width + plate.height) - (8 - 2 * math.pi) * corner,
        );
      },
    ),
    'knob': (
      StudioKnob(value: 0.5, semanticLabel: 'Monitor', onChanged: (_) {}),
      (tester, origin) {
        final box = tester.getRect(find.byType(StudioKnob)).shift(-origin);
        // The knob's body, inside its ticks.
        final r = box.shortestSide / 2 - 6;
        return (
          Rect.fromCircle(center: box.center, radius: r),
          2 * math.pi * r,
        );
      },
    ),
  };
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: (part, shape)) in parts.entries) {
      testWidgets('a focused $name lights its own edge by ${brightness.name}', (
        tester,
      ) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await _show(tester, part, brightness);
        final (before, width) = await _pixels(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final (after, _) = await _pixels(tester);
        final origin = tester.getTopLeft(find.byKey(_frame));
        final (rect, perimeter) = shape(tester, origin);
        // The light hugs the part: the 3:1 pixels lie within its lit edge,
        // in device pixels at 2x (four to a logical pixel).
        final edge = rect.inflate(StudioMetrics.focusWidth + 0.5);
        var lit = 0;
        for (var i = 0; i + 3 < before.length; i += 4) {
          final x = (i ~/ 4) % width / 2, y = (i ~/ 4) ~/ width / 2;
          if (!edge.contains(Offset(x, y))) continue;
          if (_ratio(_luminance(before, i), _luminance(after, i)) >= 3) lit++;
        }
        expect(lit, greaterThanOrEqualTo(2 * perimeter * 4));
      });
    }
  }

  // A window lights its edge however it got the focus: a press or a touch
  // gives it the typing, as Tab does.
  for (final brightness in Brightness.values) {
    testWidgets('a pressed text field lights its edge by ${brightness.name}', (
      tester,
    ) async {
      await _show(
        tester,
        SizedBox(
          width: 300,
          child: StudioTextField(label: 'Title', onChanged: (_) {}),
        ),
        brightness,
      );
      final (before, width) = await _pixels(tester);
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final (after, _) = await _pixels(tester);
      final origin = tester.getTopLeft(find.byKey(_frame));
      final (rect, perimeter) = _faceShape(tester, origin);
      final edge = rect.inflate(StudioMetrics.focusWidth + 0.5);
      final inner = rect.deflate(StudioMetrics.focusWidth + 2);
      var lit = 0;
      for (var i = 0; i + 3 < before.length; i += 4) {
        final at = Offset((i ~/ 4) % width / 2, (i ~/ 4) ~/ width / 2);
        // Outside the caret's reach: the band round the window's edge.
        if (!edge.contains(at) || inner.contains(at)) continue;
        if (_ratio(_luminance(before, i), _luminance(after, i)) >= 3) lit++;
      }
      expect(lit, greaterThanOrEqualTo(2 * perimeter * 4));
    });
  }
}
