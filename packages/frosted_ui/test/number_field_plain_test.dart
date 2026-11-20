// A number field shows a plain number: no currency sign unless it is money, its unit after the figure and read with
// it, and each key out of use at its bound (a count of people reads "2", never "$2").
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

class _People extends StatefulWidget {
  const _People({required this.log});

  final List<int> log;

  @override
  State<_People> createState() => _PeopleState();
}

class _PeopleState extends State<_People> {
  var _people = 2;

  @override
  Widget build(BuildContext context) => FrostedNumberField(
    label: 'Guests',
    value: _people,
    min: 2,
    max: 3,
    step: 1,
    unit: (n) => n == 1 ? 'person' : 'people',
    onChanged: (v) {
      widget.log.add(v);
      setState(() => _people = v);
    },
  );
}

Future<void> _pump(WidgetTester tester, Widget field) async {
  tester.view.physicalSize = const Size(390, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(child: page!),
      home: Material(
        type: MaterialType.transparency,
        child: Padding(padding: const EdgeInsets.all(16), child: field),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _key(IconData glyph) => find.byIcon(glyph);

void main() {
  testWidgets('a count shows its figure and unit, no currency sign, and its '
      'keys stop at its bounds', (tester) async {
    final semantics = tester.ensureSemantics();
    final log = <int>[];
    await _pump(tester, _People(log: log));
    expect(find.text(r'$'), findsNothing, reason: 'a count is no amount');
    expect(find.text('people'), findsOneWidget);
    final values = [
      for (final node
          in find.semantics.byAction(SemanticsAction.increase).evaluate())
        node.value,
    ];
    expect(values, [
      '2 people',
    ], reason: 'the stepping node reads the unit with the figure');
    // At its floor the minus does nothing; the plus steps to the ceiling, where it stops.
    await tester.tap(_key(FrostedGlyphs.remove));
    await tester.pumpAndSettle();
    expect(log, isEmpty, reason: 'the minus is out of use at the floor');
    await tester.tap(_key(FrostedGlyphs.add));
    await tester.pumpAndSettle();
    await tester.tap(_key(FrostedGlyphs.add));
    await tester.pumpAndSettle();
    expect(log, [3], reason: 'the plus is out of use at the ceiling');
    semantics.dispose();
  });

  testWidgets('money shows the currency sign before the figure', (
    tester,
  ) async {
    await _pump(
      tester,
      FrostedNumberField(
        label: 'the budget',
        value: 250,
        money: true,
        onChanged: (_) {},
      ),
    );
    expect(find.text(r'$'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('at ${scale}x text, ${direction.name}: the rounds stand '
          'level with the well between them, minus at the start', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                textDirection: direction,
                child: FrostedHost(brightness: Brightness.light, child: page!),
              ),
            ),
            home: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FrostedNumberField(
                    value: 2700,
                    label: 'the budget',
                    money: true,
                    max: 99999,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final faces = [
          for (final e
              in find
                  .descendant(
                    of: find.byType(FrostedNumberField),
                    matching: find.byType(FrostedFace),
                  )
                  .evaluate())
            tester.getRect(find.byElementPredicate((x) => x == e)),
        ]..sort((a, b) => a.left.compareTo(b.left));
        expect(faces, hasLength(3));
        final [first, well, last] = faces;
        for (final round in [first, last]) {
          // As tall as the well; at 2x on a phone, as large as leaves the
          // well its three figures, centred on it.
          if (scale == 1) {
            expect(round.height, moreOrLessEquals(well.height, epsilon: 1));
          } else {
            expect(round.height, inInclusiveRange(48, well.height + 1));
          }
          expect(round.width, moreOrLessEquals(round.height, epsilon: 0.01));
          expect(round.center.dy, moreOrLessEquals(well.center.dy, epsilon: 1));
        }
        expect(well.height, scale == 1 ? 64 : greaterThan(64));
        final minus = tester.getCenter(
          find.descendant(
            of: find.byType(FrostedNumberField),
            matching: find.byIcon(FrostedGlyphs.remove),
          ),
        );
        final start = direction == TextDirection.ltr ? first : last;
        expect(start.contains(minus), isTrue, reason: 'minus at the start');
      });
    }
  }
}
