import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

// A look's own face: a rounded plate its painter draws, marked as a face.
class _Plate extends CustomPainter {
  const _Plate(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
    Paint()..color = const Color(0xFF3355AA),
  );

  @override
  bool shouldRepaint(_Plate old) => old.radius != radius;
}

const _card = BoxDecoration(color: Color(0xFFEEEEEE));

// A phone's page: three cards [margin] in, and a tab bar floating at its
// foot [barSide] in, holding a chosen tab's plate [plateTop] from the
// bar's top and bottom and [plateSide] from its side.
Widget _page({
  double margin = 16,
  double barSide = 16,
  double plateTop = 4,
  double plateSide = 4,
  double barRadius = 22,
  double plateRadius = 18,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Stack(
    key: const Key('page'),
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(margin, 48, margin, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            for (final title in ['Coffee', 'Rent', 'Books'])
              DecoratedBox(
                decoration: _card,
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(title, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
          ],
        ),
      ),
      Positioned(
        left: barSide,
        right: barSide,
        bottom: 24,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(barRadius),
          child: DecoratedBox(
            decoration: _card,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: plateSide,
                  vertical: plateTop,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(plateRadius),
                        ),
                        child: const Center(child: Text('Activity')),
                      ),
                    ),
                    const Expanded(child: Center(child: Text('Settings'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);

Future<DesignAlignmentReport> _check(
  WidgetTester tester,
  Widget page, {
  bool failOnGaps = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(page);
  return DesignSpacingCheck(look: 'Test', failOnGaps: failOnGaps).check(
    tester.element(find.byKey(const Key('page'))),
    runAsync: tester.runAsync,
  );
}

void main() {
  testWidgets('a page whose bar and plate keep its spacing passes', (
    tester,
  ) async {
    final report = await _check(tester, _page());
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('a tab bar off the page margin is named', (tester) async {
    final report = await _check(tester, _page(barSide: 12));
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(
        contains('the bar'),
        contains('starts 12 pt in from the screen\'s left'),
        contains('the page\'s margin is 16 pt'),
      ),
    );
  });

  testWidgets('a plate set in unevenly, its corners not concentric, is named', (
    tester,
  ) async {
    final report = await _check(tester, _page(plateSide: 8, plateRadius: 14));
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(
        contains('holding "Activity"'),
        contains('4 pt from its top but 8 pt from its left'),
        contains('a shape in a shape keeps one inset all round'),
        contains('14 pt round in a 22 pt corner 4 pt out'),
        contains('concentric, it is 18 pt'),
      ),
    );
  });

  testWidgets("a painted plate's corners are read from its pixels", (
    tester,
  ) async {
    Widget bar(double plateRadius) => Directionality(
      key: const Key('page'),
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          child: SizedBox(
            width: 300,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ColoredBox(
                color: const Color(0xFFEEEEEE),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: DesignKeylineFace(
                          child: CustomPaint(
                            painter: _Plate(plateRadius),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final round = await _check(tester, bar(18));
    expect(round.problems, isEmpty);
    final tight = await _check(tester, bar(10));
    expect(
      tight.problems.single,
      allOf(contains('in a 22 pt corner 4 pt out'), contains('it is 18 pt')),
    );
  });

  testWidgets('repeated items unevenly apart are named', (tester) async {
    Widget chip(String label) => DecoratedBox(
      decoration: _card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label),
      ),
    );
    Widget row() => Directionality(
      key: const Key('page'),
      textDirection: TextDirection.ltr,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chip('All'),
            const SizedBox(width: 8),
            chip('Food'),
            const SizedBox(width: 8),
            chip('Rent'),
            const SizedBox(width: 12),
            chip('Pay'),
          ],
        ),
      ),
    );
    final named = allOf(
      contains('the 4 items in a row'),
      contains('8 pt, 8 pt and 12 pt apart'),
    );
    // An advisory by default: reported, never failing.
    final advised = await _check(tester, row());
    expect(advised.problems, isEmpty);
    expect(advised.advisories.single, named);
    expect(advised.verify, returnsNormally);
    final failed = await _check(tester, row(), failOnGaps: true);
    expect(failed.problems.single, named);
    expect(failed.advisories, isEmpty);
  });

  testWidgets('a spacer or an empty cell parts a run of items', (tester) async {
    Widget chip(String label) => DecoratedBox(
      decoration: _card,
      child: SizedBox(width: 40, height: 32, child: Center(child: Text(label))),
    );
    final report = await _check(
      tester,
      Directionality(
        key: const Key('page'),
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 360,
            child: Row(
              children: [
                chip('1'),
                const SizedBox(width: 8),
                chip('2'),
                const SizedBox(width: 8),
                chip('3'),
                const SizedBox(width: 40),
                chip('5'),
                const Spacer(),
                chip('Go'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets("a month's title over its even weeks passes", (tester) async {
    Widget band(double height) => DecoratedBox(
      decoration: _card,
      child: SizedBox(width: 280, height: height),
    );
    final report = await _check(
      tester,
      Directionality(
        key: const Key('page'),
        textDirection: TextDirection.ltr,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              band(32),
              const SizedBox(height: 4),
              band(16),
              const SizedBox(height: 12),
              band(40),
              const SizedBox(height: 8),
              band(40),
              const SizedBox(height: 8),
              band(40),
            ],
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('lines of words stacked in a column are set by type', (
    tester,
  ) async {
    final report = await _check(
      tester,
      const Directionality(
        key: Key('page'),
        textDirection: TextDirection.ltr,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('DUE', style: TextStyle(fontSize: 11)),
              SizedBox(height: 2),
              Text('12 Aug', style: TextStyle(fontSize: 17)),
              SizedBox(height: 6),
              Text('in 3 days', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('a card the page scrolls is no floating bar', (tester) async {
    final report = await _check(
      tester,
      Directionality(
        key: const Key('page'),
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (final title in ['Coffee', 'Rent', 'Books', 'Gym'])
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: DecoratedBox(
                    decoration: _card,
                    child: SizedBox(height: 180, child: Text(title)),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: DecoratedBox(
                  decoration: _card,
                  child: SizedBox(height: 64, child: Text('Totals')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('a panel at the foot of a SingleChildScrollView page scrolls '
      'with it: no floating bar, whatever its inset', (tester) async {
    // Four cards and a panel overflow the 844 pt screen by 4 pt: the
    // panel's foot is 20 pt above the screen's, where a bar would stand.
    final report = await _check(
      tester,
      Directionality(
        key: const Key('page'),
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final title in ['Coffee', 'Rent', 'Books', 'Gym'])
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: DecoratedBox(
                    decoration: _card,
                    child: SizedBox(height: 178, child: Text(title)),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: DecoratedBox(
                  decoration: _card,
                  child: SizedBox(height: 64, child: Text('On file')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final panel = find.ancestor(
      of: find.text('On file'),
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getRect(panel.first).bottom, 824);
    expect(report.problems, isEmpty);
    expect(report.advisories, isEmpty);
  });

  testWidgets('a look on a 2 pt grid declares it: its sources are read on '
      'it, from any screen under its theme', (tester) async {
    const sources = {
      'lib/src/metrics.dart': '''
class Metrics {
  static const double inset = 6;
  static const double gutter = 10;
  static const double gap = 14;
  static const double margin = 22;
}
''',
    };
    expect(
      const DesignSpacingCheck(look: 'Retro').literals(sources).problems.single,
      contains('4 off the 4-pt grid'),
      reason: 'with no grid declared, 4',
    );
    await tester.pumpWidget(
      const DesignSpacingScope(
        spacing: DesignSpacing(grid: 2),
        child: SizedBox(key: Key('screen')),
      ),
    );
    final screen = tester.element(find.byKey(const Key('screen')));
    expect(
      const DesignSpacingCheck(look: 'Retro')
          .literals(sources, context: screen)
          .problems,
      isEmpty,
      reason: 'all on the 2 pt grid',
    );
    expect(
      const DesignSpacingCheck(
        look: 'Retro',
        grid: 4,
      ).literals(sources, context: screen).problems.single,
      contains('4 off the 4-pt grid'),
      reason: "the check's own grid wins",
    );
  });

  testWidgets('DesignSpacing.of reads the nearest scope, else 4', (
    tester,
  ) async {
    late DesignSpacing outside;
    late DesignSpacing inside;
    await tester.pumpWidget(
      Column(
        children: [
          Builder(
            builder: (context) {
              outside = DesignSpacing.of(context);
              return const SizedBox();
            },
          ),
          DesignSpacingScope(
            spacing: const DesignSpacing(grid: 2),
            child: Builder(
              builder: (context) {
                inside = DesignSpacing.of(context);
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
    expect(outside, DesignSpacing.fallback);
    expect(outside.grid, 4);
    expect(inside, const DesignSpacing(grid: 2));
    expect(inside.copyWith(grid: 8).grid, 8);
    expect(inside.hashCode, const DesignSpacing(grid: 2).hashCode);
    expect(inside.toString(), contains('grid: 2.0'));
  });

  test('spacing written as numbers and off the grid is named', () {
    final report = const DesignSpacingCheck(look: 'Test').literals({
      'lib/src/bar.dart': '''
class Metrics {
  static const double gutter = 16;
  static const double tabBarSide = 12;
  static const double plateInset = 6;
}
Widget bar() => Padding(
  padding: const EdgeInsets.symmetric(horizontal: Metrics.gutter),
  child: Column(spacing: 10, children: [
    SizedBox(height: 8),
    Padding(padding: EdgeInsets.all(Metrics.plateInset)),
  ]),
);
''',
      'lib/src/clean.dart': '''
Widget clean() => Padding(padding: const EdgeInsets.all(Metrics.gutter));
Widget grown(double grown) => Padding(padding: EdgeInsets.only(top: grown / 2));
''',
    });
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(
        startsWith('bar.dart writes 2 spacings as numbers, not tokens'),
        contains('10 pt at line 8'),
        contains('8 pt at line 9'),
        contains('2 off the 4-pt grid'),
        contains('6 pt, a token, at line 4'),
        contains('10 pt at line 8'),
      ),
    );
  });
}
