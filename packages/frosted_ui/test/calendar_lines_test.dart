// A calendar's parts line up with its days, at 390 and 1440, by day and by night, left to right and right to left.
// Each month's title stands over its own grid's centre: a two-month range picker's titles once leaned toward the
// gutter by half an arrow, the arrow the month did not have. A range's band runs on at a row break to the row's edge,
// square, as Material's range band does, with the ink discs as its only round ends: a round cap at a row break made one
// range read as two, and an end day at its row's end had no stub. The date picker's arrows stand on the centres of
// the two last columns.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

const _stage = ValueKey('stage');
const _ratio = 2.0;
const _height = 900.0;
final _today = DateTime(2026, 11, 18);

double _apart(Color a, Color b) =>
    [(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()].reduce(math.max);

typedef _Read = Color Function(double x, double y);

Future<_Read> _shot(WidgetTester tester, double width) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  final w = (width * _ratio).round();
  final px = (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _ratio);
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (double x, double y) {
    final i = ((y * _ratio).floor() * w + (x * _ratio).floor()) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required TextDirection direction,
  bool dark = false,
  required Widget home,
}) async {
  tester.view.devicePixelRatio = _ratio;
  tester.view.physicalSize = Size(width, _height) * _ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // The stage takes the host's ground in, so a band reads as it shows.
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: RepaintBoundary(
          key: _stage,
          child: FrostedHost(
            brightness: dark ? Brightness.dark : Brightness.light,
            child: page!,
          ),
        ),
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

const _weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

// Each month's weekday centres, by its title: the first month's in the
// tree comes first.
List<List<double>> _columns(WidgetTester tester) {
  final months = find.text('Su').evaluate().length;
  return [
    for (var m = 0; m < months; m++)
      [for (final d in _weekdays) tester.getCenter(find.text(d).at(m)).dx],
  ];
}

// Each range's first and last day, and a day between them whose end edge
// meets the next day's inside one row: the band itself.
const _ranges = <String, (int, int, int)>{
  // From a Friday to a Tuesday: a row break between the Saturday and the
  // Sunday, both days between the ends.
  'across a row break': (20, 24, 22),
  // From a Saturday, the row's end: its half runs off to the row's edge.
  'from the row end': (21, 24, 22),
  // To a Sunday, the row's start: its half runs in from the row's edge.
  'to the row start': (19, 22, 20),
};

void main() {
  for (final direction in TextDirection.values) {
    for (final (name, build) in <(String, Widget Function())>[
      (
        'range picker',
        () => FrostedDateRangePicker(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
          currentDate: _today,
          onChanged: (_) {},
        ),
      ),
      (
        'calendar',
        () => FrostedCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          months: 2,
          value: DateTime(2026, 11, 20),
          currentDate: _today,
          onChanged: (_) {},
        ),
      ),
    ]) {
      for (final width in const [390.0, 1440.0]) {
        testWidgets('${direction.name}, $width: a $name month\'s title stands '
            'over its own grid\'s centre', (tester) async {
          await _pump(
            tester,
            width: width,
            direction: direction,
            home: _onPage(build()),
          );
          final titles = [
            'November 2026',
            'December 2026',
          ].where((t) => find.text(t).evaluate().isNotEmpty).toList();
          final columns = _columns(tester);
          expect(titles, hasLength(columns.length));
          if (width == 1440 && name == 'range picker') {
            expect(columns, hasLength(2), reason: 'two months at 1440');
          }
          for (final (m, title) in titles.indexed) {
            final grid = (columns[m].first + columns[m].last) / 2;
            final words = tester.getCenter(find.text(title)).dx;
            expect(
              (words - grid).abs(),
              lessThanOrEqualTo(.5),
              reason: '$title at $words, its grid centred at $grid',
            );
          }
        });
      }
    }
  }

  for (final direction in TextDirection.values) {
    for (final dark in [false, true]) {
      for (final width in const [390.0, 1440.0]) {
        for (final MapEntry(key: name, value: (from, to, inside))
            in _ranges.entries) {
          final when = dark ? 'night' : 'day';
          testWidgets('${direction.name}, $when, $width: a range $name runs '
              'to the row\'s edge, square', (tester) async {
            await _pump(
              tester,
              width: width,
              direction: direction,
              dark: dark,
              home: _onPage(
                FrostedDateRangePicker(
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                  value: RawDateRange(
                    DateTime(2026, 11, from),
                    DateTime(2026, 11, to),
                  ),
                  currentDate: DateTime(2026, 11, 2),
                  onChanged: (_) {},
                ),
              ),
            );
            final cols = _columns(tester).first;
            // The pitch from one column to the next, in reading order.
            final pitch = cols[1] - cols[0];
            Rect face(int day) => tester.getRect(
              find
                  .ancestor(
                    of: find.text('$day').first,
                    matching: find.byType(FrostedFace),
                  )
                  .first,
            );
            final at = await _shot(tester, width);
            // Inside a cell, one pixel from its edge on the reading
            // direction's [end] side or its start side.
            double edge(int day, {required bool end}) {
              final c = face(day).center.dx;
              final e = c + (end ? pitch / 2 : -pitch / 2);
              return e - (end ? 1 : -1) * pitch.sign;
            }

            // The band itself, between two days well inside it.
            final mid = face(inside);
            final band = at(edge(inside, end: true), mid.top + 2);
            final ground = at(edge(inside, end: true), mid.top - 3);
            expect(_apart(band, ground), greaterThan(4 / 255), reason: 'band');
            void banded(int day, {required bool end, required String why}) {
              final f = face(day);
              for (final y in [f.top + 2, f.center.dy, f.bottom - 2]) {
                final got = at(edge(day, end: end), y);
                expect(
                  _apart(got, band),
                  lessThanOrEqualTo(3 / 255),
                  reason: '$why: $got at the edge of $day, the band $band',
                );
              }
            }

            // Sunday the 22nd starts a row; Saturday the 21st ends one.
            if (from <= 21 && to >= 22) {
              banded(21, end: true, why: 'to the row end');
              banded(22, end: false, why: 'from the row start');
            }
          });
        }
      }
    }
  }

  // A desk under a pointer (44 targets), a phone under a finger (48).
  for (final direction in TextDirection.values) {
    for (final (width, platform) in const [
      (1440.0, TargetPlatform.macOS),
      (390.0, TargetPlatform.android),
    ]) {
      testWidgets('${direction.name}, $width, ${platform.name}: the date '
          'picker\'s arrows stand on the last two columns\' centres where a '
          'column holds their targets', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          await _pump(
            tester,
            width: width,
            direction: direction,
            home: Center(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showFrostedDatePicker(
                    context,
                    initialDate: DateTime(2026, 11, 20),
                    first: DateTime(2026),
                    last: DateTime(2027),
                    currentDate: _today,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          Finder arrow(IconData g) =>
              find.byWidgetPredicate((w) => w is Icon && w.icon == g);
          final target = FrostedBreakpoints.hitTargetOf(
            tester.element(find.text('Fr')),
          );
          // Each arrow keeps its whole touch target.
          for (final g in [FrostedGlyphs.chevronLeft, FrostedGlyphs.forward]) {
            final hit = tester.getRect(
              find
                  .ancestor(
                    of: arrow(g),
                    matching: find.byType(FrostedPressable),
                  )
                  .first,
            );
            expect(hit.width, greaterThanOrEqualTo(target), reason: 'width');
            expect(hit.height, greaterThanOrEqualTo(target), reason: 'height');
          }
          final back = tester.getCenter(arrow(FrostedGlyphs.chevronLeft)).dx;
          final on = tester.getCenter(arrow(FrostedGlyphs.forward)).dx;
          final fr = tester.getCenter(find.text('Fr')).dx;
          final sa = tester.getCenter(find.text('Sa')).dx;
          if ((sa - fr).abs() >= target) {
            expect(
              (back - fr).abs(),
              lessThanOrEqualTo(.5),
              reason: 'back at $back, Fr at $fr',
            );
            expect(
              (on - sa).abs(),
              lessThanOrEqualTo(.5),
              reason: 'on at $on, Sa at $sa',
            );
          } else {
            // Columns narrower than a target: side by side at the end.
            expect((on - back).abs(), closeTo(target, .5), reason: 'apart');
          }
          if (platform == TargetPlatform.macOS) {
            expect((sa - fr).abs(), greaterThanOrEqualTo(target));
          }
          Navigator.of(tester.element(find.text('Fr'))).pop();
          await tester.pumpAndSettle();
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
