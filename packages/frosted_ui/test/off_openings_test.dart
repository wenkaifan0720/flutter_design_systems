// An empty opening (an unchosen radio, an unchecked box, a switch turned
// off) reads on the page's canvas by day in every palette: its well a step
// deeper, at 1.2:1 or more against the canvas round it, with no ring added.
// One that takes no input stands back toward the canvas, fainter than a live
// one, by day and by night, and still shows.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, Material, MaterialType;

double _luminance(List<int> c) {
  double channel(int v) {
    final s = v / 255;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c[0]) +
      0.7152 * channel(c[1]) +
      0.0722 * channel(c[2]);
}

double _contrast(List<int> a, List<int> b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void _ignore(Object? _) {}

void main() {
  for (final palette in FrostedThemeData.palettes) {
    testWidgets('an empty opening reads on ${palette.id}\'s canvas by day', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const shot = ValueKey('shot');
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => RepaintBoundary(
            key: shot,
            child: FrostedHost(
              palette: palette,
              brightness: Brightness.light,
              child: app!,
            ),
          ),
          home: const Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FrostedRadioGroup<String>(
                    labelText: 'Pay with',
                    value: 'card',
                    onChanged: _ignore,
                    options: [
                      FrostedRadio('card', 'Card'),
                      FrostedRadio('cash', 'Cash'),
                    ],
                  ),
                  FrostedSwitch(
                    key: ValueKey('switch'),
                    value: false,
                    onChanged: _ignore,
                    semanticLabel: 'Face ID',
                  ),
                  FrostedCheckbox(
                    key: ValueKey('check'),
                    value: false,
                    onChanged: _ignore,
                    semanticLabel: 'Walk',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(shot),
      );
      final image = await tester.runAsync(() async {
        final i = await boundary.toImage();
        final bytes = (await i.toByteData())!;
        final width = i.width;
        i.dispose();
        return (bytes, width);
      });
      final (ByteData bytes, int width) = image!;
      List<int> at(Offset p) {
        final i = 4 * (p.dy.round() * width + p.dx.round());
        return [
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        ];
      }

      // The unchosen radio's bead, 22 round, 12 before its words.
      final cash = tester.getRect(find.text('Cash'));
      final bead = Offset(cash.left - 12 - 11, cash.center.dy);
      final track = tester.getRect(find.byKey(const ValueKey('switch')));
      final check = tester.getRect(
        find
            .descendant(
              of: find.byKey(const ValueKey('check')),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      for (final (name, inside, outside) in [
        ('radio', bead, bead - const Offset(16, 0)),
        (
          'switch',
          Offset(track.right - 10, track.center.dy),
          Offset(track.right + 6, track.center.dy),
        ),
        ('checkbox', check.center, check.centerLeft - const Offset(6, 0)),
      ]) {
        expect(
          _contrast(at(inside), at(outside)),
          greaterThanOrEqualTo(1.2),
          reason: '${palette.id}: an empty $name against the canvas',
        );
      }
    });
  }

  // The opening's most present pixel along its middle row against the canvas
  // beside it: its fill or its rim, whichever stands out more.
  Future<Map<String, double>> presence(
    WidgetTester tester,
    RawNamedPalette palette,
    Brightness brightness,
  ) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const shot = ValueKey('shot');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => RepaintBoundary(
          key: shot,
          child: FrostedHost(
            palette: palette,
            brightness: brightness,
            child: Stack(
              fit: StackFit.expand,
              children: [const FrostedBackdropView(), app!],
            ),
          ),
        ),
        home: const Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FrostedRadioGroup<String>(
                  labelText: 'Delivery',
                  value: 'none',
                  onChanged: _ignore,
                  options: [
                    FrostedRadio('a', 'Live'),
                    FrostedRadio('b', 'Off', enabled: false),
                  ],
                ),
                Row(
                  spacing: 24,
                  children: [
                    FrostedCheckbox(
                      key: ValueKey('check live'),
                      value: false,
                      onChanged: _ignore,
                      semanticLabel: 'Live',
                    ),
                    FrostedCheckbox(
                      key: ValueKey('check off'),
                      value: false,
                      onChanged: null,
                      semanticLabel: 'Off',
                    ),
                  ],
                ),
                Row(
                  spacing: 24,
                  children: [
                    FrostedSwitch(
                      key: ValueKey('switch live'),
                      value: false,
                      onChanged: _ignore,
                      semanticLabel: 'Live',
                    ),
                    FrostedSwitch(
                      key: ValueKey('switch off'),
                      value: false,
                      onChanged: null,
                      semanticLabel: 'Off',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(shot),
    );
    final image = await tester.runAsync(() async {
      final i = await boundary.toImage();
      final bytes = (await i.toByteData())!;
      final width = i.width;
      i.dispose();
      return (bytes, width);
    });
    final (ByteData bytes, int width) = image!;
    List<int> at(Offset p) {
      final i = 4 * (p.dy.round() * width + p.dx.round());
      return [bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2)];
    }

    double most(double from, double to, double y, Offset outside) {
      final ground = at(outside);
      var top = 1.0;
      for (var x = from; x <= to; x++) {
        top = math.max(top, _contrast(at(Offset(x, y)), ground));
      }
      return top;
    }

    Rect inner(String key) => tester.getRect(
      find
          .descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    final result = <String, double>{};
    for (final (name, words) in [
      ('radio live', 'Live'),
      ('radio off', 'Off'),
    ]) {
      final text = tester.getRect(find.text(words));
      final x = text.left - 12 - 11;
      result[name] = most(
        x - 10,
        x + 10,
        text.center.dy,
        Offset(x - 16, text.center.dy),
      );
    }
    for (final name in ['check live', 'check off']) {
      final r = inner(name);
      result[name] = most(
        r.left + 1,
        r.right - 1,
        r.center.dy,
        r.centerLeft - const Offset(6, 0),
      );
    }
    for (final name in ['switch live', 'switch off']) {
      // The room the knob leaves, off: from the track's middle to its end.
      final r = inner(name);
      result[name] = most(
        r.center.dx + 2,
        r.right - 1,
        r.center.dy,
        r.centerRight + const Offset(6, 0),
      );
    }
    return result;
  }

  for (final palette in FrostedThemeData.palettes) {
    for (final brightness in Brightness.values) {
      final when = brightness == Brightness.light ? 'day' : 'night';
      testWidgets(
        'an empty opening that takes no input stands back on ${palette.id} by $when',
        (tester) async {
          final p = await presence(tester, palette, brightness);
          for (final part in ['radio', 'check', 'switch']) {
            final live = p['$part live']!, off = p['$part off']!;
            expect(
              off,
              lessThan(live),
              reason:
                  '${palette.id} by $when: a disabled empty $part '
                  '(${off.toStringAsFixed(2)}:1) against a live one '
                  '(${live.toStringAsFixed(2)}:1)',
            );
            expect(
              off,
              greaterThan(1.02),
              reason: '${palette.id} by $when: a disabled empty $part shows',
            );
          }
        },
      );
    }
  }

  // By day on the page's canvas: a disabled empty opening's step from the
  // canvas is at most a third of a live one's (Material's disabled control
  // stands at 38%), and it still shows.
  for (final palette in FrostedThemeData.palettes) {
    testWidgets('a disabled empty opening stands at a third of a live one on '
        '${palette.id}\'s canvas by day', (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const shot = ValueKey('shot');
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => RepaintBoundary(
            key: shot,
            child: FrostedHost(
              palette: palette,
              brightness: Brightness.light,
              child: app!,
            ),
          ),
          home: const Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FrostedRadioGroup<String>(
                    labelText: 'Delivery',
                    value: 'none',
                    onChanged: _ignore,
                    options: [
                      FrostedRadio('a', 'Live'),
                      FrostedRadio('b', 'Off', enabled: false),
                    ],
                  ),
                  Row(
                    spacing: 24,
                    children: [
                      FrostedCheckbox(
                        key: ValueKey('check live'),
                        value: false,
                        onChanged: _ignore,
                        semanticLabel: 'Live',
                      ),
                      FrostedCheckbox(
                        key: ValueKey('check off'),
                        value: false,
                        onChanged: null,
                        semanticLabel: 'Off',
                      ),
                    ],
                  ),
                  Row(
                    spacing: 24,
                    children: [
                      FrostedSwitch(
                        key: ValueKey('switch live'),
                        value: false,
                        onChanged: _ignore,
                        semanticLabel: 'Live',
                      ),
                      FrostedSwitch(
                        key: ValueKey('switch off'),
                        value: false,
                        onChanged: null,
                        semanticLabel: 'Off',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(shot),
      );
      final image = await tester.runAsync(() async {
        final i = await boundary.toImage();
        final bytes = (await i.toByteData())!;
        final width = i.width;
        i.dispose();
        return (bytes, width);
      });
      final (ByteData bytes, int width) = image!;
      List<int> at(Offset p) {
        final i = 4 * (p.dy.round() * width + p.dx.round());
        return [
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        ];
      }

      Rect inner(String key) => tester.getRect(
        find
            .descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      double step(String part, String state) {
        switch (part) {
          case 'radio':
            final text = tester.getRect(
              find.text(state == 'live' ? 'Live' : 'Off'),
            );
            final bead = Offset(text.left - 12 - 11, text.center.dy);
            return _contrast(at(bead), at(bead - const Offset(16, 0)));
          case 'check':
            final r = inner('check $state');
            return _contrast(
              at(r.center),
              at(r.centerLeft - const Offset(6, 0)),
            );
          default:
            final r = inner('switch $state');
            return _contrast(
              at(Offset(r.right - 10, r.center.dy)),
              at(r.centerRight + const Offset(6, 0)),
            );
        }
      }

      for (final part in ['radio', 'check', 'switch']) {
        final live = step(part, 'live'), off = step(part, 'off');
        expect(
          off - 1,
          lessThanOrEqualTo(.35 * (live - 1)),
          reason:
              '${palette.id}: a disabled empty $part '
              '(${off.toStringAsFixed(2)}:1) against a live one '
              '(${live.toStringAsFixed(2)}:1)',
        );
        expect(
          off,
          greaterThanOrEqualTo(1.03),
          reason: '${palette.id}: a disabled empty $part shows',
        );
      }
    });
  }
}
