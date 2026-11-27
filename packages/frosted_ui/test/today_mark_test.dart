// Today is one mark in every view, by day and by night: a hairline ring in the quiet ink round the day's figure, in
// the calendar, the range picker and the date picker's dialog alike, never a disc of glass; and when today is the day
// chosen (a range's end too) the ring stands just inside the ink disc in the disc's words made quiet, so today still
// reads and stays the quiet mark it is beside the chosen day.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

const _stage = ValueKey('stage');
const _ratio = 3.0;
const _size = Size(390, 844);
final _today = DateTime(2026, 11, 18);

double _apart(Color a, Color b) =>
    [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()].reduce(math.max);

typedef _Read = Color Function(double x, double y);

Future<_Read> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final width = (_size.width * _ratio).round();
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (double x, double y) {
    final i = ((y * _ratio).floor() * width + (x * _ratio).floor()) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

Future<void> _pump(WidgetTester tester, bool dark, Widget home) async {
  tester.view.devicePixelRatio = _ratio;
  tester.view.physicalSize = _size * _ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(
        brightness: dark ? Brightness.dark : Brightness.light,
        child: RepaintBoundary(key: _stage, child: page!),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _onPage(Widget child) => Align(
  alignment: Alignment.topCenter,
  child: Padding(padding: const EdgeInsets.all(16), child: child),
);

typedef _View = ({
  String name,
  Widget Function(bool onChosen) build,
  bool opens,
});

final _views = <_View>[
  (
    name: 'calendar',
    opens: false,
    build: (onChosen) => _onPage(
      FrostedCalendar(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        value: onChosen ? _today : DateTime(2026, 11, 20),
        currentDate: _today,
        onChanged: (_) {},
      ),
    ),
  ),
  (
    name: 'range picker',
    opens: false,
    build: (onChosen) => _onPage(
      FrostedDateRangePicker(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        months: 1,
        value: onChosen
            ? RawDateRange(_today, DateTime(2026, 11, 21))
            : RawDateRange(DateTime(2026, 11, 19), DateTime(2026, 11, 21)),
        currentDate: _today,
        onChanged: (_) {},
      ),
    ),
  ),
  (
    name: 'date picker',
    opens: true,
    build: (onChosen) => Center(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => showFrostedDatePicker(
            context,
            initialDate: onChosen ? _today : DateTime(2026, 11, 20),
            first: DateTime(2026),
            last: DateTime(2027),
            currentDate: _today,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
];

void main() {
  for (final view in _views) {
    for (final dark in [false, true]) {
      final when = dark ? 'by night' : 'by day';
      testWidgets('${view.name} $when: today beside the chosen day is the '
          'quiet hairline ring, no disc', (tester) async {
        await _pump(tester, dark, view.build(false));
        if (view.opens) {
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
        }
        final t = tester.element(find.text('18').last).frostedTheme;
        final face = tester.getRect(
          find
              .ancestor(
                of: find.text('18').last,
                matching: find.byType(FrostedFace),
              )
              .first,
        );
        final at = await _shot(tester);
        final x = face.center.dx;
        final ground = at(x, face.top - 2);
        final ring = at(x, face.top + .5);
        final inside = at(x, face.top + 4.5);
        final quiet = Color.alphaBlend(t.colorScheme.textSecondary, ground);
        expect(
          _apart(ring, quiet),
          lessThanOrEqualTo(4 / 255),
          reason: 'the ring at $ring is not the quiet ink $quiet',
        );
        expect(
          _apart(inside, ground),
          lessThanOrEqualTo(3 / 255),
          reason: 'inside the ring $inside is not the ground $ground',
        );
      });

      testWidgets('${view.name} $when: today on the chosen day keeps its '
          'ring, inside the ink disc', (tester) async {
        await _pump(tester, dark, view.build(true));
        if (view.opens) {
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
        }
        final t = tester.element(find.text('18').last).frostedTheme;
        final face = tester.getRect(
          find
              .ancestor(
                of: find.text('18').last,
                matching: find.byType(FrostedFace),
              )
              .first,
        );
        final at = await _shot(tester);
        final x = face.center.dx;
        final disc = at(x, face.top + 1.5);
        final ring = at(x, face.top + 3.5);
        final within = at(x, face.top + 5.5);
        // The disc's words made quiet, half-way to the disc, as today's
        // hairline is quiet beside the chosen day: never a bright bullseye.
        final quiet = Color.alphaBlend(
          t.colorScheme.onButton.withValues(alpha: .5),
          disc,
        );
        expect(
          _apart(ring, quiet),
          lessThanOrEqualTo(8 / 255),
          reason: 'the ring at $ring is not the disc\'s quiet words $quiet',
        );
        expect(_apart(ring, t.colorScheme.onButton), greaterThanOrEqualTo(.3));
        expect(_apart(ring, disc), greaterThanOrEqualTo(.3));
        expect(_apart(ring, within), greaterThanOrEqualTo(.3));
      });
    }
  }
}
