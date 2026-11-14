// Two of the classes from the user's review of the gate builds (design6 P, added 11-11 noon), read from the drawn
// pixels at each density the look ships:
// - Width on a wide layout ("some dropdown spans the entire width"): from 600 up, no select, button, stepper or bank of
//   segments stretches to a wide column; each takes its own width, at most 320. On a phone they span their column.
// - A chosen or pressed fill covers its whole cell ("the highlight doesnt fill the entire tab"): the state reaches the
//   cell's edges, top and bottom, and the seams it shares with a neighbour.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

void _tap() {}
void _drop(Object? _) {}

const _densities = {
  'standard': NeumorphicDensity.standard,
  'comfortable': NeumorphicDensity.comfortable,
  'compact': NeumorphicDensity.compact,
};

const _shot = Key('shot');

Widget _host(NeumorphicDensity density, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => NeumorphicHost(
    light: NeumorphicThemeData.porcelain().copyWith(density: density),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: RepaintBoundary(key: _shot, child: child),
  ),
);

Future<({int w, int h, ByteData px})> _pixels(
  WidgetTester tester,
  double ratio,
) async {
  final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shot));
  final shot = await tester.runAsync(() async {
    final image = await box.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final out = (w: image.width, h: image.height, px: data!);
    image.dispose();
    return out;
  });
  return shot!;
}

int _diff(ByteData a, ByteData b, int i) {
  var most = 0;
  for (var k = 0; k < 3; k++) {
    final d = (a.getUint8(i + k) - b.getUint8(i + k)).abs();
    if (d > most) most = d;
  }
  return most;
}

/// The drawn extent of the row through [y]: the first and last pixel unlike the page's ground, its relief included.
(int, int) _extent(({int w, int h, ByteData px}) s, int y) {
  final ground = (y * s.w + 2) * 4;
  var first = -1, last = -1;
  for (var x = 0; x < s.w; x++) {
    final i = (y * s.w + x) * 4;
    if (_ground(s.px, ground, i) > 6) {
      if (first < 0) first = x;
      last = x;
    }
  }
  return (first, last);
}

int _ground(ByteData px, int g, int i) {
  var most = 0;
  for (var k = 0; k < 3; k++) {
    final d = (px.getUint8(i + k) - px.getUint8(g + k)).abs();
    if (d > most) most = d;
  }
  return most;
}

/// The choice controls and buttons a form or a settings page puts on a line of its own.
final Map<String, Widget> _controls = {
  'select': NeumorphicSelect<String>(
    label: 'Density',
    value: 'standard',
    options: const [
      NeumorphicMenuItem('standard', 'Standard'),
      NeumorphicMenuItem('comfortable', 'Comfortable'),
      NeumorphicMenuItem('compact', 'Compact'),
    ],
    onChanged: _drop,
  ),
  'select field': const NeumorphicSelectField(
    value: 'Every day',
    onPressed: _tap,
  ),
  'segmented control': NeumorphicSegmentedButton<int>(
    label: 'Period',
    value: 0,
    segments: const [
      NeumorphicButtonSegment(0, 'Day'),
      NeumorphicButtonSegment(1, 'Week'),
      NeumorphicButtonSegment(2, 'Month'),
    ],
    onChanged: _drop,
  ),
  'toggle group': NeumorphicToggleGroup<String>(
    label: 'Text',
    items: const [
      NeumorphicButtonSegment('b', 'Bold'),
      NeumorphicButtonSegment('i', 'Italic'),
    ],
    selected: const {'b'},
    onChanged: _drop,
  ),
  'latches': NeumorphicLatchGroup(
    options: const [NeumorphicLatch('Day'), NeumorphicLatch('Week')],
    value: 'Day',
    onChanged: _drop,
  ),
  'button group': NeumorphicButtonGroup(
    label: 'Week',
    items: [
      NeumorphicButtonGroupItem('Previous', onPressed: _tap),
      NeumorphicButtonGroupItem('Next', onPressed: _tap),
    ],
  ),
  'wide button': const NeumorphicButton(
    'Continue',
    wide: true,
    onPressed: _tap,
  ),
  'wide act button': const NeumorphicButton.filled(
    'Pay',
    wide: true,
    onPressed: _tap,
  ),
  'wide quiet button': const NeumorphicButton.text(
    'Customize',
    wide: true,
    onPressed: _tap,
  ),
  'number field': NeumorphicNumberField(
    value: '2',
    unit: 'people',
    onDecrease: _tap,
    onIncrease: _tap,
  ),
};

/// Banks whose chosen cell is [chosen], or with [chosen] pressed.
final Map<String, Widget Function(int chosen)> _banks = {
  'segmented control': (chosen) => NeumorphicSegmentedButton<int>(
    label: 'Period',
    value: chosen,
    segments: const [
      NeumorphicButtonSegment(0, 'Day'),
      NeumorphicButtonSegment(1, 'Week'),
      NeumorphicButtonSegment(2, 'Month'),
    ],
    onChanged: _drop,
  ),
  'toggle group': (chosen) => NeumorphicToggleGroup<int>(
    label: 'Text',
    items: const [
      NeumorphicButtonSegment(0, 'Bold'),
      NeumorphicButtonSegment(1, 'Italic'),
      NeumorphicButtonSegment(2, 'Under'),
    ],
    selected: {chosen},
    onChanged: _drop,
  ),
  'latches': (chosen) => NeumorphicLatchGroup(
    options: const [
      NeumorphicLatch('Day'),
      NeumorphicLatch('Week'),
      NeumorphicLatch('Month'),
    ],
    value: ['Day', 'Week', 'Month'][chosen],
    onChanged: _drop,
  ),
  'tab bar': (chosen) => NeumorphicTabBar(
    tabs: const ['Day', 'Week', 'Month'],
    selectedIndex: chosen,
    onChanged: _drop,
  ),
};

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final MapEntry(key: density, value: d) in _densities.entries) {
    for (final MapEntry(key: name, value: control) in _controls.entries) {
      testWidgets('$name keeps to its own width on a desk, $density', (
        tester,
      ) async {
        final faults = <String>[];
        for (final window in [1440.0, 390.0]) {
          tester.view.physicalSize = Size(window, 400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          // A wide column on a desk, the page's column on a phone.
          final column = window > 600 ? 640.0 : window - 32;
          await tester.pumpWidget(
            _host(
              d,
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: column,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KeyedSubtree(key: const Key('c'), child: control),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final shot = await _pixels(tester, 1);
          // The face's middle: the line through the control's lowest 48, below any label it carries.
          final rect = tester.getRect(find.byKey(const Key('c')));
          final y = (rect.bottom - 24).round();
          final (first, last) = _extent(shot, y);
          final drawn = last - first + 1;
          if (window > 600 && drawn > 320 + 2 * 20) {
            faults.add(
              'at $window it is drawn $drawn wide in a $column column',
            );
          }
          // A quiet button draws no face, and a number field is its keys and figure: neither spans.
          if (window < 600 &&
              name != 'number field' &&
              name != 'wide quiet button' &&
              drawn < column - 2) {
            faults.add(
              'at $window it is drawn $drawn wide in a $column column',
            );
          }
        }
        expect(faults, isEmpty, reason: faults.join('\n'));
      }, tags: ['goldens']);
    }

    for (final MapEntry(key: name, value: build) in _banks.entries) {
      testWidgets('$name: the chosen cell is pressed in to its edges, $density', (
        tester,
      ) async {
        const ratio = 2.0;
        tester.view.physicalSize = const Size(420, 200) * ratio;
        tester.view.devicePixelRatio = ratio;
        addTearDown(tester.view.reset);
        Future<({int w, int h, ByteData px})> at(int chosen) async {
          await tester.pumpWidget(
            _host(
              d,
              Padding(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 360, child: build(chosen)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          return _pixels(tester, ratio);
        }

        final other = await at(2);
        final chosen = await at(0);
        // The bank as it paints its face, in three equal cells on one row; the first is the chosen one.
        final bank = tester.getRect(
          find
              .byWidgetPredicate(
                (w) =>
                    w is CustomPaint &&
                    w.painter.runtimeType.toString() == '_BankFace',
              )
              .first,
        );
        final cell = Rect.fromLTWH(
          bank.left,
          bank.top,
          bank.width / 3,
          bank.height,
        );
        final faults = <String>[];
        bool changed(int x, int y) {
          final i = (y * chosen.w + x) * 4;
          return _diff(chosen.px, other.px, i) > 3;
        }

        // Within three points of the cell's top and bottom, across its middle; within three of the seam it shares.
        final x0 = ((cell.left + cell.width * .3) * ratio).round();
        final x1 = ((cell.right - cell.width * .3) * ratio).round();
        for (final (edge, ys) in [
          ('top', [for (var y = cell.top + 1; y < cell.top + 3; y += .5) y]),
          (
            'bottom',
            [for (var y = cell.bottom - 3; y < cell.bottom - 1; y += .5) y],
          ),
        ]) {
          var reached = 0, columns = 0;
          for (var x = x0; x < x1; x++) {
            columns++;
            if (ys.any((y) => changed(x, (y * ratio).round()))) reached++;
          }
          if (reached < columns * .9) {
            faults.add(
              'the chosen state reaches $reached of $columns columns at the cell\'s $edge',
            );
          }
        }
        final y0 = ((cell.top + cell.height * .3) * ratio).round();
        final y1 = ((cell.bottom - cell.height * .3) * ratio).round();
        var reached = 0, rows = 0;
        for (var y = y0; y < y1; y++) {
          rows++;
          if ([for (var x = cell.right - 3; x < cell.right - 1; x += .5) x]
              .any((x) => changed((x * ratio).round(), y))) {
            reached++;
          }
        }
        if (reached < rows * .9) {
          faults.add(
            'the chosen state reaches $reached of $rows rows at the seam',
          );
        }
        expect(faults, isEmpty, reason: faults.join('\n'));
      }, tags: ['goldens']);
    }

    testWidgets('a chosen list row is filled to its edges, $density', (
      tester,
    ) async {
      const ratio = 2.0;
      tester.view.physicalSize = const Size(420, 300) * ratio;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      Future<({int w, int h, ByteData px})> at(bool chosen) async {
        await tester.pumpWidget(
          _host(
            d,
            Padding(
              padding: const EdgeInsets.all(24),
              child: NeumorphicListSection(
                children: [
                  const NeumorphicListTile(
                    title: 'Floor lamp',
                    subtitle: 'Living room',
                    isFirst: true,
                    onPressed: _tap,
                  ),
                  NeumorphicListTile(
                    key: const Key('row'),
                    title: 'Pendants',
                    subtitle: 'Kitchen',
                    selected: chosen,
                    onPressed: _tap,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return _pixels(tester, ratio);
      }

      final idle = await at(false);
      final chosen = await at(true);
      final row = tester.getRect(find.byKey(const Key('row')));
      var reached = 0, columns = 0;
      for (
        var x = (row.left + row.width * .2) * ratio;
        x < (row.right - row.width * .2) * ratio;
        x++
      ) {
        columns++;
        final top = ((row.top + 2) * ratio).round();
        final bottom = ((row.bottom - 2) * ratio).round();
        final a = (top * chosen.w + x.round()) * 4;
        final b = (bottom * chosen.w + x.round()) * 4;
        if (_diff(chosen.px, idle.px, a) > 3 &&
            _diff(chosen.px, idle.px, b) > 3) {
          reached++;
        }
      }
      expect(
        reached,
        greaterThanOrEqualTo(columns * .9),
        reason:
            'the chosen fill reaches the row\'s top and bottom in $reached of $columns columns',
      );
    }, tags: ['goldens']);
  }
}
