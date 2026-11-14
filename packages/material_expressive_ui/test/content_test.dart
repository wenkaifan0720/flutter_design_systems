/// Content: the text role over the 30 styles (emphasized display and
/// headline asserting a hero), the icon's fill and sizes, the counter (Cody
/// v2's counter tests, ported onto ExpressiveCounter) and the stat, the
/// rating, the chart and the message bubble.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// [child] in Expressive's host, started in a column as a page starts it.
Widget _kit(Widget child) => MaterialApp(
  home: ExpressiveHost(
    light: _theme,
    brightness: Brightness.light,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[child],
      ),
    ),
  ),
);

/// The counter needs a style, and the style lives on the theme.
class _CounterProbe extends StatelessWidget {
  const _CounterProbe({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => ExpressiveCounter(
    value,
    style: context.expressiveTheme.type.displaySmall,
  );
}

/// The counter as a dial paints it: a bounded box, centred, with a centred
/// caption beneath.
class _DialCounterProbe extends StatelessWidget {
  const _DialCounterProbe({required this.value, required this.width});

  final int value;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey<String>('dial'),
    width: width,
    height: 180,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ExpressiveCounter(
            value,
            style: context.expressiveTheme.type.displayMedium,
          ),
          const Text('mL consumed'),
        ],
      ),
    ),
  );
}

void main() {
  group('Cody v2 counter tests, on ExpressiveCounter', () {
    testWidgets('the counter runs to the new value and settles on it exactly', (
      tester,
    ) async {
      await tester.pumpWidget(_kit(const _CounterProbe(value: 8)));
      await tester.pumpAndSettle();
      expect(find.text('8'), findsOneWidget);

      await tester.pumpWidget(_kit(const _CounterProbe(value: 1042)));
      // Mid-run it is somewhere between the two, and it is NOT the answer.
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('1042'), findsNothing);

      // One shot: pumpAndSettle terminates and the last frame is the value.
      await tester.pumpAndSettle();
      expect(find.text('1042'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'the counter hugs its digits: centred in a dial, started in a start '
      'column, scaled only when they would overflow',
      (tester) async {
        await tester.pumpWidget(
          _kit(const _DialCounterProbe(value: 1020, width: 340)),
        );
        await tester.pumpAndSettle();
        final dial = tester.getRect(find.byKey(const ValueKey<String>('dial')));
        expect(
          tester.getCenter(find.text('1020')).dx,
          closeTo(dial.center.dx, 1),
        );
        expect(
          tester.getCenter(find.text('mL consumed')).dx,
          closeTo(dial.center.dx, 1),
        );
        expect(
          tester.getSize(find.byType(ExpressiveCounter)),
          tester.getSize(find.text('1020')),
        );

        await tester.pumpWidget(_kit(const _CounterProbe(value: 8)));
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.text('8')).dx,
          tester.getTopLeft(find.byType(ExpressiveCounter)).dx,
        );

        await tester.pumpWidget(
          _kit(const _DialCounterProbe(value: 1000000000, width: 60)),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(ExpressiveCounter)).width,
          lessThanOrEqualTo(60),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a formatted counter stays formatted the whole run', (
      tester,
    ) async {
      String money(num v) => '£${v.toStringAsFixed(2)}';
      Widget probe(double value) => Builder(
        builder: (context) => ExpressiveCounter(
          value,
          fractionDigits: 2,
          format: money,
          style: context.expressiveTheme.type.titleLarge,
        ),
      );
      await tester.pumpWidget(_kit(probe(4.5)));
      await tester.pumpWidget(_kit(probe(12.25)));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final shown = tester.widget<Text>(find.byType(Text)).data!;
        expect(shown, matches(RegExp(r'^£\d+\.\d\d$')));
      }
      await tester.pumpAndSettle();
      expect(find.text('£12.25'), findsOneWidget);
    });
  });

  group('ExpressiveText', () {
    test('maps role, size and emphasis onto the 30 keys', () {
      final keys = <Object>{
        for (final role in ExpressiveTextRole.values)
          for (final size in ExpressiveTextSize.values)
            for (final emphasized in <bool>[false, true])
              expressiveTypeKeyOf(role, size, emphasized: emphasized),
      };
      expect(keys, hasLength(30));
      expect(
        const ExpressiveText.title(
          'x',
          size: ExpressiveTextSize.small,
        ).typeKey.name,
        'titleSmall',
      );
      expect(
        const ExpressiveText.label('x', emphasized: true).typeKey.name,
        'labelMediumEmphasized',
      );
    });

    testWidgets('sets the style in the ambient content colour; titles are '
        'headings', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(
          const Column(
            children: <Widget>[
              ExpressiveText.title('Tide tables'),
              ExpressiveText.body('Low water at 7:10'),
            ],
          ),
        ),
      );
      final title = tester.widget<Text>(find.text('Tide tables'));
      expect(title.style!.fontSize, _theme.type.titleMedium.fontSize);
      expect(title.style!.color, _theme.colors.onSurface);
      expect(
        tester.getSemantics(find.text('Tide tables')).flagsCollection.isHeader,
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.text('Low water at 7:10'))
            .flagsCollection
            .isHeader,
        isFalse,
      );
      semantics.dispose();
    });

    testWidgets('emphasized display and headline are hero moments; '
        'emphasized title is not', (tester) async {
      await tester.pumpWidget(
        _kit(const ExpressiveText.title('Unread', emphasized: true)),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _kit(
          const SizedBox(
            width: 300,
            height: 200,
            child: ExpressiveText.headline('Big week', emphasized: true),
          ),
        ),
      );
      expect(
        '${tester.takeException()}',
        contains('outside an ExpressiveHeroMoment'),
      );
      await tester.pumpWidget(
        _kit(
          const ExpressiveHeroMoment(
            child: ExpressiveText.display('318', emphasized: true),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ExpressiveIcon', () {
    testWidgets('sizes from the icon-button tokens; fill springs to 1', (
      tester,
    ) async {
      Widget icon(bool selected) => _kit(
        ExpressiveIcon(
          ExpressiveSymbols.favorite,
          selected: selected,
          size: ExpressiveIconSize.large.dimension,
          opticalSize: ExpressiveIconSize.large.dimension,
        ),
      );
      await tester.pumpWidget(icon(false));
      expect(tester.getSize(find.byType(Icon)), const Size.square(32));
      expect(tester.widget<Icon>(find.byType(Icon)).fill, 0);
      await tester.pumpWidget(icon(true));
      await tester.pump(const Duration(milliseconds: 16));
      final mid = tester.widget<Icon>(find.byType(Icon)).fill!;
      expect(mid, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(tester.widget<Icon>(find.byType(Icon)).fill, 1);
      expect(tester.widget<Icon>(find.byType(Icon)).opticalSize, 32);
      expect(
        [for (final s in ExpressiveIconSize.values) s.dimension],
        <double>[20, 24, 32, 40],
      );
    });
  });

  group('ExpressiveStat', () {
    testWidgets('announces label, value and change as one node', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(
          const ExpressiveStat(
            label: 'Pages this week',
            value: 42,
            supporting: '+6 on last week',
            trend: ExpressiveTrend.up,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Pages this week, 42, +6 on last week'),
        findsOneWidget,
      );
      expect(find.byIcon(ExpressiveSymbols.trendingUp), findsOneWidget);
      final value = tester.widget<Text>(find.text('42'));
      expect(value.style!.fontSize, _theme.type.headlineMedium.fontSize);
      semantics.dispose();
    });

    testWidgets('an emphasized headline stat asserts a hero', (tester) async {
      await tester.pumpWidget(
        _kit(
          const SizedBox(
            width: 300,
            height: 200,
            child: ExpressiveStat(label: 'x', value: 1, emphasized: true),
          ),
        ),
      );
      expect(
        '${tester.takeException()}',
        contains('outside an ExpressiveHeroMoment'),
      );
      await tester.pumpWidget(
        _kit(
          const ExpressiveStat(
            label: 'x',
            value: 1,
            emphasized: true,
            size: ExpressiveStatSize.small,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ExpressiveRating', () {
    testWidgets('read-only: filled, half and empty stars, one image', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_kit(const ExpressiveRating(value: 3.5)));
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons, hasLength(5));
      expect(
        [for (final i in icons) i.icon],
        <IconData>[
          ExpressiveSymbols.star,
          ExpressiveSymbols.star,
          ExpressiveSymbols.star,
          ExpressiveSymbols.starHalf,
          ExpressiveSymbols.star,
        ],
      );
      expect([for (final i in icons) i.fill], <double>[1, 1, 1, 1, 0]);
      expect(icons.first.color, _theme.colors.primary);
      expect(icons.last.color, _theme.colors.onSurfaceVariant);
      expect(find.bySemanticsLabel('Rated 3.5 of 5'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('input: each star rates, with a 48dp touch target', (
      tester,
    ) async {
      int? rated;
      await tester.pumpWidget(
        _kit(ExpressiveRating(value: 1, onChanged: (v) => rated = v)),
      );
      final stars = find.byType(ExpressivePressable);
      expect(stars, findsNWidgets(5));
      expect(tester.getSize(stars.first).height, greaterThanOrEqualTo(48));
      await tester.tap(stars.at(3));
      expect(rated, 4);
      expect(find.bySemanticsLabel('Rate 4 of 5'), findsOneWidget);
    });
  });

  group('ExpressiveChart', () {
    const week = <ExpressiveChartPoint>[
      ExpressiveChartPoint('M', 20),
      ExpressiveChartPoint('T', 40),
      ExpressiveChartPoint('W', 10),
    ];

    testWidgets('lays out its plot and labels, and is one image', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(
          const SizedBox(
            width: 300,
            child: ExpressiveChart.bar(points: week, highlight: 1),
          ),
        ),
      );
      expect(tester.getSize(find.byType(CustomPaint).last).width, 300);
      expect(find.text('T'), findsOneWidget);
      expect(find.bySemanticsLabel('M 20, T 40, W 10'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('new values spring to their heights and settle', (
      tester,
    ) async {
      Widget chart(List<ExpressiveChartPoint> points) => _kit(
        SizedBox(width: 300, child: ExpressiveChart.line(points: points)),
      );
      await tester.pumpWidget(chart(week));
      await tester.pumpWidget(
        chart(const <ExpressiveChartPoint>[
          ExpressiveChartPoint('M', 40),
          ExpressiveChartPoint('T', 10),
          ExpressiveChartPoint('W', 30),
        ]),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('ExpressiveMessageBubble', () {
    test('tightens the sender-side corners it shares with its run', () {
      final round = _theme.shapes
          .corner(ExpressiveCorner.largeIncreased)
          .topStart;
      final tight = _theme.shapes.corner(ExpressiveCorner.extraSmall).topStart;
      final out = const ExpressiveMessageBubble(
        text: 'x',
        side: ExpressiveMessageSide.outgoing,
        position: ExpressiveMessagePosition.middle,
      ).shapeIn(_theme.shapes);
      expect(
        [out.topStart, out.bottomStart, out.topEnd, out.bottomEnd],
        [round, round, tight, tight],
      );
      final first = const ExpressiveMessageBubble(
        text: 'x',
        side: ExpressiveMessageSide.incoming,
        position: ExpressiveMessagePosition.first,
      ).shapeIn(_theme.shapes);
      expect(
        [first.topStart, first.bottomStart, first.topEnd, first.bottomEnd],
        [round, tight, round, round],
      );
    });

    testWidgets('outgoing sits at the end on primary, at most 4/5 wide, and '
        'announces sender, text, time and status', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(
          const SizedBox(
            width: 400,
            child: ExpressiveMessageBubble(
              text: 'Boots, not sandals this time, the rocks are sharp',
              side: ExpressiveMessageSide.outgoing,
              timestamp: '6:04',
              status: ExpressiveMessageStatus.read,
            ),
          ),
        ),
      );
      final bubble = find.byType(ExpressiveSurface).first;
      final rect = tester.getRect(bubble);
      expect(rect.width, lessThanOrEqualTo(320));
      expect(rect.right, closeTo(400, 0.01));
      final surface = tester.widget<ExpressiveSurface>(bubble);
      expect(surface.color, _theme.colors.primary);
      expect(find.text('6:04'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'You, Boots, not sandals this time, the rocks are sharp, 6:04, Read',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('incoming names its author on the first of a run only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _kit(
          const SizedBox(
            width: 400,
            child: Column(
              children: <Widget>[
                ExpressiveMessageBubble(
                  text: 'Tide pools?',
                  side: ExpressiveMessageSide.incoming,
                  position: ExpressiveMessagePosition.first,
                  author: 'Noor',
                ),
                ExpressiveMessageBubble(
                  text: 'Low tide at 7:10',
                  side: ExpressiveMessageSide.incoming,
                  position: ExpressiveMessagePosition.last,
                  author: 'Noor',
                  timestamp: '6:02',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Noor'), findsOneWidget);
      expect(find.text('6:02'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Tide pools?')).dx, lessThan(40));
    });
  });
}
