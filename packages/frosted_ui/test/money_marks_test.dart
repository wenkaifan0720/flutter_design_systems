// Frosted's figures and marks, one test each, at the Keel pilot's own
// values: the money (the display figure, an amount in a column, figures in
// a line, a percentage, a stat and its arrangements, the rolling counter)
// and the marks (monogram, token, date block, a transaction's mark, chip,
// swatch, a person and a row of people, the completion check).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pumps [child] across a phone's page (or a window of [size]), 20 in from
/// each side, under the Frosted host; nothing may throw.
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  String preset = 'opal',
  double textScale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) => FrostedHost(
        light: FrostedThemeData.preset(preset, Brightness.light),
        dark: FrostedThemeData.preset(preset, Brightness.dark),
        brightness: brightness,
        child: page!,
      ),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    ),
  );
  expect(t.takeException(), isNull);
}

/// The node a screen reader lands on for [label].
SemanticsNode _node(WidgetTester t, String label) =>
    t.getSemantics(find.bySemanticsLabel(label));

/// The theme in force at the first widget of [type].
FrostedThemeData _theme(WidgetTester t, Type type) =>
    t.element(find.byType(type).first).frostedTheme;

/// The style of the one Text printing [text].
TextStyle _style(WidgetTester t, String text) =>
    t.widget<Text>(find.text(text)).style!;

/// The rich text under the [i]th widget of [type].
RichText _rich(WidgetTester t, Type type, int i) => t.widget<RichText>(
  find
      .descendant(of: find.byType(type).at(i), matching: find.byType(RichText))
      .first,
);

/// The span a Text.rich was given (Text.rich wraps it in the line's default
/// style): an amount's or a percentage's own.
TextSpan _span(WidgetTester t, Type type, int i) =>
    (_rich(t, type, i).text as TextSpan).children!.single as TextSpan;

/// A controlled value's owner: hands [builder] the value and a setter, and
/// records what the setter was given in [seen].
class _Owner<T> extends StatefulWidget {
  const _Owner(this.initial, this.builder, {this.seen});

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;
  final List<T>? seen;

  @override
  State<_Owner<T>> createState() => _OwnerState<T>();
}

class _OwnerState<T> extends State<_Owner<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(_value, (v) {
    widget.seen?.add(v);
    setState(() => _value = v);
  });
}

/// One of everything, as a page would set it.
Widget _everything(BuildContext context) {
  final th = context.frostedTheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const FrostedAmount(-84.25),
      const FrostedAmount(3412.5),
      const FrostedAmount(6248.30, signed: false),
      const FrostedAmount(0),
      const FrostedAmount(-12.4, size: FrostedAmountSize.extraSmall),
      const FrostedMoney(48210.66),
      const FrostedMoney(1326.44, size: FrostedMoneySize.regular),
      const FrostedMoney(
        -1326.44,
        size: FrostedMoneySize.regular,
        unsigned: true,
        flow: FrostedMoneyFlow.outflow,
      ),
      const FrostedMoney(2700, cents: false, size: FrostedMoneySize.small),
      const FrostedMoney(6825, sign: true, size: FrostedMoneySize.small),
      const FrostedCounter(1200, size: FrostedMoneySize.regular),
      const FrostedStats(
        children: [
          FrostedFigure(3214.09, caption: 'Spent'),
          FrostedFigure(285.91, caption: 'Left'),
        ],
      ),
      const FrostedStats(
        variant: FrostedStatVariant.cells,
        children: [
          FrostedFigure(1326.44, caption: 'Due', note: 'Nov 12'),
          FrostedFigure(2673.56, caption: 'Available'),
          FrostedFigure(4000, caption: 'Limit', cents: false),
        ],
      ),
      const FrostedPercent(115),
      const FrostedPercent(71, size: FrostedPercentSize.small),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FrostedMonogram('Blue Fern Café', hue: th.hues.coral),
          FrostedIconMark(LucideIcons.wallet, hue: th.hues.cyan),
          const FrostedIconMark(LucideIcons.repeat, quiet: true),
          FrostedDateBlock(
            DateTime(2026, 11, 1),
            soon: true,
            hue: th.hues.periwinkle,
          ),
          const FrostedTransactionMark.move(),
          const FrostedTag('On track', tone: FrostedTone.success),
          const FrostedTag('Credit', variant: FrostedTagVariant.glass),
          FrostedSwatch(th.hues.orchid),
          const FrostedCheckbox(value: true, label: 'Done'),
        ],
      ),
      const FrostedPeople(
        children: [
          FrostedPerson('Jonah Reyes', selected: true),
          FrostedPerson('Priya Anand', note: '\$42.10', dimmed: true),
        ],
      ),
    ],
  );
}

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  group('money', () {
    testWidgets('each amount is read aloud as one, in every preset and mode', (
      t,
    ) async {
      for (final preset in FrostedThemeData.presets) {
        for (final brightness in Brightness.values) {
          await _pump(
            t,
            Builder(builder: _everything),
            preset: preset,
            brightness: brightness,
          );
          for (final label in [
            '−\$84.25',
            '+\$3,412.50',
            '\$6,248.30',
            '\$0.00',
            '−\$12.40',
            '\$48,210.66',
            '\$1,326.44',
            '\$2,700',
            '+\$6,825.00',
            '\$1,200.00',
            '115%',
            '71%',
          ]) {
            expect(
              find.bySemanticsLabel(label),
              findsAtLeastNWidgets(1),
              reason: '$label in $preset ${brightness.name}',
            );
          }
          // A figure reads its caption then its amount (and its note).
          expect(
            find.bySemanticsLabel(RegExp(r'^Spent\s+\$3,214\.09$')),
            findsOneWidget,
          );
          expect(
            find.bySemanticsLabel(RegExp(r'^Due\s+\$1,326\.44\s+Nov 12$')),
            findsOneWidget,
          );
        }
      }
      // Narrow and large: nothing overflows.
      await _pump(
        t,
        Builder(builder: _everything),
        size: const Size(320, 900),
        textScale: 1.3,
      );
    });

    testWidgets('FrostedMoney sets its \$ and cents at the cents size, dropped and quiet; '
        'money in all green; unsigned drops the minus', (t) async {
      await _pump(
        t,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FrostedMoney(8.66),
            FrostedMoney(6825, sign: true, size: FrostedMoneySize.small),
            FrostedMoney(
              -1326.44,
              size: FrostedMoneySize.regular,
              unsigned: true,
            ),
            FrostedMoney(2700, cents: false, size: FrostedMoneySize.regular),
          ],
        ),
      );
      final th = _theme(t, FrostedMoney);
      // The display figure: 64 dollars, 28 for the `$` and the cents in the
      // quiet ink, both dropped 0.1 em of 28 from the top.
      final whole = _style(t, '8');
      expect(whole.fontSize, 64);
      expect(whole.color, th.colorScheme.textPrimary);
      expect(whole.fontWeight, FontWeight.w500);
      expect(whole.letterSpacing, closeTo(-0.035 * 64, 0.001));
      final cents = _style(t, '.66');
      expect(cents.fontSize, 28);
      expect(cents.color, th.colorScheme.textTertiary);
      expect(cents.height, 1);
      final dollarsTop = t.getTopLeft(find.text('8')).dy;
      expect(
        t.getTopLeft(find.text('.66')).dy - dollarsTop,
        closeTo(2.8, 0.01),
      );
      expect(
        t.getTopLeft(find.text('\$').first).dy - dollarsTop,
        closeTo(2.8, 0.01),
      );
      // 0.05 em of 28 between the `$` and the dollars, 0.03 em before the
      // cents.
      expect(
        t.getTopLeft(find.text('8')).dx -
            t.getTopRight(find.text('\$').first).dx,
        closeTo(1.4, 0.01),
      );
      expect(
        t.getTopLeft(find.text('.66')).dx - t.getTopRight(find.text('8')).dx,
        closeTo(0.84, 0.01),
      );
      // Money in: the dollars, its `+$` and cents all the green.
      expect(_style(t, '6,825').color, th.colorScheme.moneyIn);
      expect(_style(t, '+\$').color, th.colorScheme.moneyIn);
      // Unsigned: no minus before the card's balance.
      expect(find.text('−\$'), findsNothing);
      expect(find.text('1,326'), findsOneWidget);
      expect(find.bySemanticsLabel('\$1,326.44'), findsOneWidget);
      // Whole dollars: the `$` and the dollars, no cents.
      expect(find.text('2,700'), findsOneWidget);
      expect(_style(t, '2,700').fontSize, 40);
      expect(
        find.descendant(
          of: find.byType(FrostedMoney).last,
          matching: find.byType(Text),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets(
      'the giant figure stands 64 on a phone and 96 on the desktop, and one '
      'wider than its room shrinks',
      (t) async {
        double size() => _style(t, '48,210').fontSize!;
        await _pump(
          t,
          const FrostedMoney(48210.66, size: FrostedMoneySize.extraLarge),
        );
        expect(size(), 64);
        await _pump(
          t,
          const FrostedMoney(48210.66, size: FrostedMoneySize.extraLarge),
          size: const Size(1440, 900),
        );
        expect(size(), 96);
        // A ten-figure balance in a 200 room is scaled down to fit it.
        await _pump(
          t,
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(width: 200, child: FrostedMoney(1234567890.12)),
          ),
        );
        expect(
          t.getSize(find.byType(FrostedMoney)).width,
          lessThanOrEqualTo(200),
        );
      },
    );

    testWidgets(
      'FrostedAmount inks money in green throughout, money out in the page ink '
      "with quiet cents, a day head's net in the quieter ink",
      (t) async {
        await _pump(
          t,
          const Column(
            children: [
              FrostedAmount(3412.5),
              FrostedAmount(-84.25),
              FrostedAmount(-12.4, size: FrostedAmountSize.extraSmall),
              FrostedAmount(
                1159.82,
                size: FrostedAmountSize.large,
                signed: false,
              ),
            ],
          ),
        );
        final th = _theme(t, FrostedAmount);
        (Color?, Color?) inks(int i) {
          final own = _span(t, FrostedAmount, i);
          final cents = own.children!.last as TextSpan;
          return (own.style!.color, cents.style!.color);
        }

        expect(inks(0), (th.colorScheme.moneyIn, th.colorScheme.moneyIn));
        expect(inks(1), (
          th.colorScheme.textPrimary,
          th.colorScheme.textTertiary,
        ));
        expect(inks(2), (
          th.colorScheme.textSecondary,
          th.colorScheme.textSecondary,
        ));
        expect(inks(3).$2, th.colorScheme.textTertiary);
        // The default size is 16 in the display face, tabular, -.005em, at
        // the line's end; a day head's net 12 in the text face.
        final own = _span(t, FrostedAmount, 0).style!;
        expect(own.fontSize, 16);
        expect(own.fontFamily, FrostedThemeData.face);
        expect(own.letterSpacing, closeTo(-0.08, 0.001));
        expect(own.fontFeatures, contains(const FontFeature.tabularFigures()));
        // Figures set left to right, so the line's end (left to right here)
        // is taken as the right.
        expect(_rich(t, FrostedAmount, 0).textAlign, TextAlign.right);
        final micro = _span(t, FrostedAmount, 2).style!;
        expect(micro.fontSize, 12);
        expect(micro.fontFamily, FrostedThemeData.textFace);
        expect(find.bySemanticsLabel('−\$12.40'), findsOneWidget);
        // On `.amt`'s 1.2 line: 19.2 at 16, 16.8 at 14 (the engine lays
        // either on a whole pixel).
        expect(own.fontSize! * own.height!, closeTo(19.2, 0.01));
        await _pump(
          t,
          const FrostedAmount(84.25, size: FrostedAmountSize.small),
        );
        final small = _span(t, FrostedAmount, 0).style!;
        expect(small.fontSize, 14);
        expect(small.fontSize! * small.height!, closeTo(16.8, 0.01));
      },
    );

    testWidgets(
      "FrostedNumberText takes the line's size and colour in the display face, "
      'tabular; FrostedPercent sets its small % after proportional figures',
      (t) async {
        await _pump(
          t,
          Builder(
            builder: (context) {
              final th = context.frostedTheme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: th.textTheme.bodyMedium,
                    child: const Row(
                      children: [
                        Text('of '),
                        FrostedNumberText('4,000'),
                        Text(' limit'),
                      ],
                    ),
                  ),
                  const FrostedPercent(115),
                  const FrostedPercent(71, size: FrostedPercentSize.small),
                ],
              );
            },
          ),
        );
        final th = _theme(t, FrostedNumberText);
        final num = _style(t, '4,000');
        expect(num.fontSize, th.textTheme.bodyMedium.fontSize);
        expect(num.color, th.textTheme.bodyMedium.color);
        expect(num.fontFamily, FrostedThemeData.face);
        expect(num.fontWeight, FontWeight.w500);
        expect(num.fontFeatures, contains(const FontFeature.tabularFigures()));
        // The percentage: 20 in the secondary ink, its % 12 in the quiet ink.
        final root = _span(t, FrostedPercent, 0);
        expect(root.style!.fontSize, 20);
        expect(root.style!.color, th.colorScheme.textSecondary);
        final sign = root.children!.last as TextSpan;
        expect(sign.text, '%');
        expect(sign.style!.fontSize, 12);
        expect(sign.style!.color, th.colorScheme.textTertiary);
        // Proportional figures (`.pct` sets no tabular-nums), at both sizes.
        expect(root.style!.fontFeatures, isEmpty);
        expect(_node(t, '115%'), isSemantics(label: '115%'));
        // The small one: 16, the page ink, at least 40 wide, right-aligned.
        final small = _span(t, FrostedPercent, 1);
        expect(small.style!.fontSize, 16);
        expect(small.style!.color, th.colorScheme.textPrimary);
        expect(small.style!.fontFeatures, isEmpty);
        expect(_rich(t, FrostedPercent, 1).textAlign, TextAlign.end);
        expect(
          t.getSize(find.byType(FrostedPercent).last).width,
          greaterThanOrEqualTo(40),
        );
      },
    );

    testWidgets(
      'FrostedFigure stands its caption over its figure, a note under; inflow '
      'in the green with its plus; a value replaces the amount',
      (t) async {
        await _pump(
          t,
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrostedFigure(1326.44, caption: 'Due', note: 'Nov 12'),
              FrostedFigure(6825, caption: 'In', flow: FrostedMoneyFlow.inflow),
              FrostedFigure(0, caption: 'Visits', value: Text('13')),
            ],
          ),
        );
        final th = _theme(t, FrostedFigure);
        final caption = t.getRect(find.text('Due'));
        final figure = t.getRect(find.byType(FrostedAmount).first);
        expect(figure.top - caption.bottom, FrostedChromeMetrics.figureLineGap);
        expect(caption.left, figure.left);
        expect(
          t.getRect(find.text('Nov 12')).top - figure.bottom,
          FrostedChromeMetrics.figureLineGap,
        );
        expect(_style(t, 'Due').color, th.textTheme.labelMedium.color);
        expect(
          find.bySemanticsLabel(RegExp(r'^In\s+\+\$6,825\.00$')),
          findsOneWidget,
        );
        expect(_span(t, FrostedAmount, 1).style!.color, th.colorScheme.moneyIn);
        expect(find.text('13'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'^Visits\s+13$')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'\$0\.00')), findsNothing);
      },
    );

    testWidgets(
      'FrostedStats lines: on a phone each caption at the start and its figure '
      'at the end, a hairline over every line; on the desktop columns with '
      'a 28 figure over its caption, as the markup orders them',
      (t) async {
        const stats = FrostedStats(
          children: [
            FrostedFigure(3214.09, caption: 'Spent'),
            FrostedFigure(285.91, caption: 'Left'),
            FrostedFigure(3102.6, caption: 'September'),
          ],
        );
        await _pump(t, stats);
        final spent = t.getRect(find.text('Spent'));
        final figure = t.getRect(find.byType(FrostedAmount).first);
        expect(spent.left, 20);
        expect(figure.right, 370);
        // 10 over and under each line, a hairline over each (.stats and
        // .stat + .stat both rule a top border).
        expect(
          t.getRect(find.byType(FrostedStats)).height,
          closeTo(
            3 * (figure.height + 2 * FrostedChromeMetrics.statInset) + 3,
            0.01,
          ),
        );
        expect(_span(t, FrostedAmount, 0).style!.fontSize, 20);
        expect(_style(t, 'Spent').fontSize, 14);

        await _pump(
          t,
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: stats,
          ),
          size: const Size(1440, 900),
        );
        final wideSpent = t.getRect(find.text('Spent'));
        final wideFigure = t.getRect(find.byType(FrostedAmount).first);
        // `.stat { flex-direction: column }`: the `.stat-v` first.
        expect(
          wideSpent.top - wideFigure.bottom,
          FrostedChromeMetrics.statLineGapWide,
        );
        expect(wideFigure.left, wideSpent.left);
        expect(_span(t, FrostedAmount, 0).style!.fontSize, 28);
        expect(_style(t, 'Spent').fontSize, 12);
        // 24 of margin and 24 past the hairline before the second.
        final left = t.getRect(find.text('Left'));
        expect(
          left.left - wideFigure.right,
          closeTo(2 * FrostedChromeMetrics.statGapWide, 0.01),
        );
        // Nothing under the captions (`.stats--cat`; the spending hero's 4 is
        // its own).
        expect(
          t.getRect(find.byType(FrostedStats)).bottom,
          closeTo(wideSpent.bottom, 0.01),
        );
      },
    );

    testWidgets(
      'FrostedStats cells: three across at .8, 1.2 and 1 of the width on a '
      'phone, rows with the label beside the figure on the desktop; columns '
      'stand 24 apart',
      (t) async {
        const cells = FrostedStats(
          variant: FrostedStatVariant.cells,
          children: [
            FrostedFigure(1326.44, caption: 'Due', note: 'Nov 12'),
            FrostedFigure(2673.56, caption: 'Available'),
            FrostedFigure(4000, caption: 'Limit', cents: false),
          ],
        );
        await _pump(t, cells);
        final cellsRect = t.getRect(find.byType(FrostedStats));
        final due = t.getRect(find.text('Due'));
        final available = t.getRect(find.text('Available'));
        final limit = t.getRect(find.text('Limit'));
        final width = cellsRect.width;
        expect(due.left, cellsRect.left);
        // The second starts 24 past the first cell's 0.8 share (12 of margin,
        // the hairline, 12 of padding).
        expect(
          available.left - cellsRect.left,
          closeTo(width * 0.8 / 3 + 24, 0.01),
        );
        expect(limit.left - cellsRect.left, closeTo(width * 2 / 3 + 24, 0.01));
        expect(t.getRect(find.text('Nov 12')).top, greaterThan(due.bottom));

        await _pump(t, cells, size: const Size(1440, 900));
        final wideDue = t.getRect(find.text('Due'));
        final wideFigure = t.getRect(find.byType(FrostedAmount).first);
        final wideNote = t.getRect(find.text('Nov 12'));
        expect(wideDue.left, 20);
        expect(wideFigure.right, closeTo(1440 - 20, 0.01));
        expect(wideNote.right, closeTo(wideFigure.right, 0.01));
        expect(wideNote.top, greaterThanOrEqualTo(wideFigure.bottom));
        expect(
          t.getRect(find.text('Available')).top,
          greaterThan(wideNote.bottom),
        );
        expect(_style(t, 'Due').fontSize, 14);

        await _pump(
          t,
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostedStats(
              variant: FrostedStatVariant.columns,
              children: [
                FrostedFigure(84.25, caption: 'in October'),
                FrostedFigure(6.48, caption: 'a visit'),
              ],
            ),
          ),
        );
        final a = t.getRect(find.byType(FrostedFigure).first);
        final b = t.getRect(find.byType(FrostedFigure).last);
        expect(b.left - a.right, FrostedChromeMetrics.figuresGap);
      },
    );

    testWidgets('FrostedCounter rolls to a new value and says only where it '
        'lands', (t) async {
      // Motion on: this test watches it move.
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await _pump(
        t,
        _Owner<num>(
          1200,
          (v, set) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FrostedCounter(v, size: FrostedMoneySize.regular),
              FrostedButton('More', onPressed: () => set(1500)),
            ],
          ),
        ),
      );
      expect(find.text('1,200'), findsOneWidget);
      expect(_node(t, '\$1,200.00'), isSemantics(label: '\$1,200.00'));
      await t.tap(find.text('More'));
      await t.pump();
      await t.pump(FrostedMotion.look.slow ~/ 2);
      final midway = t.widget<Text>(find.textContaining(',').first).data!;
      expect(midway, isNot('1,200'));
      expect(midway, isNot('1,500'));
      expect(find.bySemanticsLabel('\$1,500.00'), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.text('1,500'), findsOneWidget);
      expect(find.text('1,200'), findsNothing);
    });
  });

  group('marks', () {
    testWidgets(
      "FrostedMonogram is an image of the merchant's initials in its hue's ink "
      'on its small solid; without a hue the wash and the tertiary ink; 32, '
      '36 and 56 across',
      (t) async {
        await _pump(
          t,
          Builder(
            builder: (context) {
              final th = context.frostedTheme;
              return Row(
                children: [
                  FrostedMonogram('Blue Fern Café', hue: th.hues.coral),
                  const FrostedMonogram('Jonah Reyes'),
                  FrostedMonogram(
                    'Linden Court Apartments',
                    hue: th.hues.periwinkle,
                    size: FrostedMarkSize.small,
                  ),
                  FrostedMonogram(
                    'Cinema Lumen',
                    hue: th.hues.lemon,
                    size: FrostedMarkSize.large,
                    label: 'Cinema Lumen, Fun',
                  ),
                ],
              );
            },
          ),
        );
        final th = _theme(t, FrostedMonogram);
        expect(find.text('BF'), findsOneWidget);
        expect(
          _node(t, 'Blue Fern Café'),
          isSemantics(label: 'Blue Fern Café', isImage: true),
        );
        expect(_style(t, 'BF').color, th.hues.coral.ink);
        expect(_style(t, 'BF').fontSize, 13);
        expect(_style(t, 'BF').fontWeight, FontWeight.w600);
        expect(_style(t, 'JR').color, th.colorScheme.textTertiary);
        expect(
          t.getSize(find.byType(FrostedMonogram).at(0)),
          const Size.square(36),
        );
        expect(
          t.getSize(find.byType(FrostedMonogram).at(2)),
          const Size.square(32),
        );
        expect(_style(t, 'LC').fontSize, 12);
        expect(
          t.getSize(find.byType(FrostedMonogram).at(3)),
          const Size.square(56),
        );
        expect(_style(t, 'CL').fontSize, 20);
        expect(_node(t, 'Cinema Lumen, Fun'), isSemantics(isImage: true));
        // The letters sit in the middle of the squircle, centred by their
        // capitals (frostedCapCentred): across exactly, and their line box
        // at most 1.5 off the middle down it.
        final letters = t.getCenter(find.text('BF'));
        final middle = t.getCenter(find.byType(FrostedMonogram).first);
        expect(letters.dx, moreOrLessEquals(middle.dx, epsilon: 0.01));
        expect((letters.dy - middle.dy).abs(), lessThanOrEqualTo(1.5));
      },
    );

    testWidgets('FrostedIconMark speaks only when it is named; quiet is the wash with a 16 '
        'glyph in the tertiary ink', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) {
            final th = context.frostedTheme;
            return Row(
              children: [
                FrostedIconMark(
                  LucideIcons.wallet,
                  hue: th.hues.cyan,
                  label: 'Everyday',
                ),
                const FrostedIconMark(LucideIcons.house),
                const FrostedIconMark(LucideIcons.repeat, quiet: true),
                FrostedIconMark(
                  LucideIcons.plane,
                  hue: th.hues.sunset,
                  size: FrostedMarkSize.large,
                ),
              ],
            );
          },
        ),
      );
      final th = _theme(t, FrostedIconMark);
      expect(
        _node(t, 'Everyday'),
        isSemantics(label: 'Everyday', isImage: true),
      );
      expect(
        t.renderObject(find.byIcon(LucideIcons.house)).debugSemantics,
        isNull,
      );
      Icon icon(IconData data) => t.widget<Icon>(find.byIcon(data));
      expect(icon(LucideIcons.wallet).color, th.hues.cyan.ink);
      expect(icon(LucideIcons.wallet).size, 18);
      expect(icon(LucideIcons.house).color, th.colorScheme.textTertiary);
      expect(icon(LucideIcons.repeat).size, 16);
      expect(icon(LucideIcons.repeat).color, th.colorScheme.textTertiary);
      expect(icon(LucideIcons.plane).size, 24);
      expect(
        t.getSize(find.byType(FrostedIconMark).last),
        const Size.square(56),
      );
    });

    testWidgets(
      'FrostedDateBlock prints the month over the day on a 40 by 44 block, '
      'read as a date; soon takes its hue',
      (t) async {
        await _pump(
          t,
          Builder(
            builder: (context) => Row(
              children: [
                FrostedDateBlock(DateTime(2026, 11, 12)),
                FrostedDateBlock(
                  DateTime(2026, 11, 1),
                  soon: true,
                  hue: context.frostedTheme.hues.periwinkle,
                ),
              ],
            ),
          ),
        );
        final th = _theme(t, FrostedDateBlock);
        expect(find.text('Nov'), findsNWidgets(2));
        expect(find.text('12'), findsOneWidget);
        expect(_node(t, 'Nov 12'), isSemantics(label: 'Nov 12', isImage: true));
        expect(_node(t, 'Nov 1'), isSemantics(isImage: true));
        expect(
          t.getSize(find.byType(FrostedDateBlock).first),
          const Size(40, 44),
        );
        final month = t.getRect(find.text('Nov').first);
        final day = t.getRect(find.text('12'));
        expect(day.top - month.bottom, FrostedChromeMetrics.dateGap);
        expect(_style(t, '12').fontSize, 16);
        expect(_style(t, '12').color, th.colorScheme.textPrimary);
        expect(_style(t, '1').color, th.hues.periwinkle.ink);
        expect(
          t.widget<Text>(find.text('Nov').last).style!.color,
          th.hues.periwinkle.ink.withValues(alpha: 0.75),
        );
      },
    );

    testWidgets("FrostedTransactionMark draws each kind of record's mark", (
      t,
    ) async {
      await _pump(
        t,
        Builder(
          builder: (context) => Row(
            children: [
              FrostedTransactionMark.purchase(
                'Blue Fern Café',
                hue: context.frostedTheme.hues.coral,
              ),
              const FrostedTransactionMark.income('Northwind Studio'),
              const FrostedTransactionMark.move(),
              const FrostedTransactionMark.payment(),
            ],
          ),
        ),
      );
      final th = _theme(t, FrostedTransactionMark);
      expect(find.text('BF'), findsOneWidget);
      expect(find.text('NS'), findsOneWidget);
      expect(_style(t, 'NS').color, th.hues.emerald.ink);
      expect(find.byIcon(LucideIcons.arrowLeftRight), findsOneWidget);
      expect(find.byIcon(LucideIcons.creditCard), findsOneWidget);
      for (final name in [
        'Blue Fern Café',
        'Northwind Studio',
        'Move',
        'Card payment',
      ]) {
        expect(
          _node(t, name),
          isSemantics(label: name, isImage: true),
          reason: name,
        );
      }
    });

    testWidgets(
      'FrostedTag prints its words as written in its tone, 24 tall; figures '
      "inside it a size up; the glass pill keeps the card's inks",
      (t) async {
        await _pump(
          t,
          const Wrap(
            children: [
              FrostedTag('Pending'),
              FrostedTag(
                'On track',
                icon: LucideIcons.check,
                tone: FrostedTone.success,
              ),
              FrostedTag('Behind', tone: FrostedTone.warning),
              FrostedTag('Over', tone: FrostedTone.danger),
              FrostedTag(
                'Frozen',
                icon: LucideIcons.snowflake,
                tone: FrostedTone.info,
              ),
              FrostedTag('results', figure: '13'),
              FrostedTag('Credit', variant: FrostedTagVariant.glass),
            ],
          ),
        );
        final th = _theme(t, FrostedTag);
        expect(find.text('On track'), findsOneWidget);
        expect(_node(t, 'On track'), isSemantics(label: 'On track'));
        expect(_node(t, 'results 13'), isSemantics(label: 'results 13'));
        expect(t.getSize(find.byType(FrostedTag).first).height, 24);
        expect(_style(t, 'Pending').color, th.colorScheme.textSecondary);
        expect(_style(t, 'Pending').fontSize, 12);
        expect(_style(t, 'On track').color, th.colorScheme.moneyIn);
        expect(_style(t, 'Behind').color, th.colorScheme.warning);
        expect(_style(t, 'Over').color, th.colorScheme.over);
        expect(_style(t, 'Frozen').color, th.colorScheme.cold);
        expect(t.widget<Icon>(find.byIcon(LucideIcons.snowflake)).size, 14);
        expect(_style(t, '13').fontSize, 14);
        expect(_style(t, '13').fontFamily, FrostedThemeData.face);
        expect(_style(t, 'Credit').color, th.pearl.textSecondary);
        // The glyph sits 4 before the words.
        expect(
          t.getRect(find.text('On track')).left -
              t.getRect(find.byIcon(LucideIcons.check)).right,
          closeTo(FrostedChromeMetrics.chipGap, 0.01),
        );
      },
    );

    testWidgets('FrostedTag leads its words with figures, or sets a dot '
        'between two, each 4 apart, read aloud in order', (t) async {
      // Words the test font (a glyph as wide as its size) fits on 350.
      await _pump(
        t,
        const Wrap(
          children: [
            FrostedTag(
              'interest',
              lead: '+\$73.42',
              icon: LucideIcons.arrowUpRight,
              tone: FrostedTone.success,
            ),
            FrostedTag('·', lead: '\$1,259.82', figure: '0.53%'),
          ],
        ),
      );
      expect(
        _node(t, '+\$73.42 interest'),
        isSemantics(label: '+\$73.42 interest'),
      );
      expect(
        _node(t, '\$1,259.82 · 0.53%'),
        isSemantics(label: '\$1,259.82 · 0.53%'),
      );
      expect(_style(t, '+\$73.42').fontSize, 14);
      expect(_style(t, '+\$73.42').fontFamily, FrostedThemeData.face);
      expect(_style(t, 'interest').fontSize, 12);
      final glyph = t.getRect(find.byIcon(LucideIcons.arrowUpRight));
      final lead = t.getRect(find.text('+\$73.42'));
      final words = t.getRect(find.text('interest'));
      expect(
        lead.left - glyph.right,
        closeTo(FrostedChromeMetrics.chipGap, 0.01),
      );
      expect(
        words.left - lead.right,
        closeTo(FrostedChromeMetrics.chipGap, 0.01),
      );
      final dot = t.getRect(find.text('·'));
      expect(
        dot.left - t.getRect(find.text('\$1,259.82')).right,
        closeTo(FrostedChromeMetrics.chipGap, 0.01),
      );
      expect(
        t.getRect(find.text('0.53%')).left - dot.right,
        closeTo(FrostedChromeMetrics.chipGap, 0.01),
      );
    });

    testWidgets('FrostedSwatch is an 8 round of decoration', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) => Row(
            children: [
              FrostedSwatch(context.frostedTheme.hues.orchid),
              FrostedSwatch(context.frostedTheme.hues.orchid, part: true),
            ],
          ),
        ),
      );
      expect(t.getSize(find.byType(FrostedSwatch).first), const Size.square(8));
      expect(
        t.renderObject(find.byType(FrostedSwatch).first).debugSemantics,
        isNull,
      );
      BoxDecoration deco(int i) =>
          t
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(FrostedSwatch).at(i),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(deco(0).shape, BoxShape.circle);
      expect(deco(0).gradient, isNotNull);
      expect(deco(0).border, isNull);
      expect(deco(1).gradient, isNull);
      expect(deco(1).border, isNotNull);
    });

    testWidgets(
      'FrostedPerson toggles its choice; without a callback it only says it; '
      'FrostedPeople shares the width',
      (t) async {
        bool? chosen;
        await _pump(
          t,
          FrostedPeople(
            children: [
              FrostedPerson(
                'Jonah Reyes',
                selected: true,
                onChanged: (v) => chosen = v,
              ),
              FrostedPerson(
                'Priya Anand',
                note: '\$42.10',
                onChanged: (v) => chosen = v,
              ),
              const FrostedPerson('Sam Okoro', dimmed: true),
              const FrostedPerson('Ines Park'),
            ],
          ),
        );
        final th = _theme(t, FrostedPerson);
        expect(find.text('Jonah'), findsOneWidget);
        expect(find.text('JR'), findsOneWidget);
        expect(
          _node(t, 'Jonah Reyes'),
          isSemantics(
            label: 'Jonah Reyes',
            isButton: true,
            isSelected: true,
            hasTapAction: true,
          ),
        );
        expect(_style(t, 'Jonah').color, th.colorScheme.textPrimary);
        expect(_style(t, 'Jonah').fontWeight, FontWeight.w600);
        expect(_style(t, 'Priya').color, th.colorScheme.textSecondary);
        await t.tap(find.text('Jonah'));
        expect(chosen, isFalse);
        await t.tap(find.text('Priya'));
        expect(chosen, isTrue);
        expect(
          _node(t, 'Priya Anand, \$42.10'),
          isSemantics(isSelected: false, hasTapAction: true),
        );
        expect(_node(t, 'Sam Okoro'), isSemantics(hasTapAction: false));
        expect(
          t
              .widget<Opacity>(
                find
                    .descendant(
                      of: find.byType(FrostedPerson).at(2),
                      matching: find.byType(Opacity),
                    )
                    .first,
              )
              .opacity,
          FrostedChromeMetrics.personDimOpacity,
        );
        // Only the pearl steps back: the name keeps its ink (law 8).
        expect(
          find
              .ancestor(of: find.text('Sam'), matching: find.byType(Opacity))
              .evaluate()
              .every((e) => (e.widget as Opacity).opacity == 1),
          isTrue,
        );
        // Each person takes a quarter of the row, 8 apart; the pearl is 52.
        final widths = [
          for (var i = 0; i < 4; i++)
            t.getSize(find.byType(FrostedPerson).at(i)).width,
        ];
        expect(widths.toSet().length, 1);
        expect(widths.first, closeTo((350 - 3 * 8) / 4, 0.01));
        expect(
          t.getSize(find.byType(FrostedAvatar).first),
          const Size.square(52),
        );
      },
    );

    testWidgets(
      'FrostedButtonRow halves its line as `.btn-row` does, a word longer than '
      "its half's inset room eating into it, centred and whole; columns 2 "
      "keeps a lone act's half at the line's start",
      (t) async {
        Widget act(String word) =>
            FrostedButton.glass(word, icon: LucideIcons.flag, onPressed: () {});
        await _pump(
          t,
          FrostedButtonRow(children: [act('Split'), act('Report it')]),
        );
        const half = (350 - 10) / 2;
        final buttons = find.byType(FrostedButton);
        expect(t.getSize(buttons.first).width, half);
        expect(t.getSize(buttons.last).width, half);
        final pill = t.getRect(buttons.last);
        final word = t.getRect(find.text('Report it'));
        final glyph = t.getRect(find.byIcon(LucideIcons.flag).last);
        expect(glyph.left - pill.left, lessThan(20));
        expect(glyph.left - pill.left, closeTo(pill.right - word.right, 0.01));
        final para = t.renderObject<RenderBox>(find.text('Report it'));
        expect(
          para.size.width,
          closeTo(para.getMaxIntrinsicWidth(double.infinity), 0.01),
        );
        await _pump(
          t,
          FrostedButtonRow(columns: 2, children: [act('Report it')]),
        );
        expect(t.getRect(find.byType(FrostedButton)).left, 20);
        expect(t.getSize(find.byType(FrostedButton)).width, half);
      },
    );

    testWidgets(
      "FrostedProfileHero stands the pearl 28 under its top, the name 14 under "
      "the pearl (its 8 and the hero's gap 6), the meta 6 under the name",
      (t) async {
        await _pump(
          t,
          const FrostedProfileHero(
            initials: 'MH',
            name: 'Maren Holt',
            meta: 'Member since March 2023',
          ),
        );
        final hero = t.getRect(find.byType(FrostedProfileHero));
        final pearl = t.getRect(find.byType(FrostedAvatar));
        final name = t.getRect(find.text('Maren Holt'));
        final meta = t.getRect(find.text('Member since March 2023'));
        expect(pearl.top - hero.top, FrostedChromeMetrics.profileTop);
        expect(name.top - pearl.bottom, 14);
        expect(meta.top - name.bottom, FrostedChromeMetrics.profileGap);
      },
    );

    testWidgets('FrostedCheckbox flips on a press and reads its state; read only it reports '
        'and takes none', (t) async {
      final seen = <bool>[];
      await _pump(
        t,
        Column(
          children: [
            _Owner<bool>(
              false,
              (done, set) => FrostedCheckbox(
                value: done,
                label: 'Stretch',
                onChanged: (v) => set(v!),
              ),
              seen: seen,
            ),
            const FrostedCheckbox(value: true, label: 'Drink water'),
          ],
        ),
      );
      expect(
        _node(t, 'Stretch'),
        isSemantics(isChecked: false, hasTapAction: true),
      );
      expect(
        t.getSize(find.byType(FrostedCheckbox).first),
        const Size.square(24),
      );
      await t.tap(find.byType(FrostedCheckbox).first);
      await t.pump();
      expect(seen, [true]);
      expect(_node(t, 'Stretch'), isSemantics(isChecked: true));
      await t.tap(find.byType(FrostedCheckbox).first);
      await t.pump();
      expect(seen, [true, false]);
      expect(
        _node(t, 'Drink water'),
        isSemantics(isChecked: true, hasTapAction: false),
      );
      expect(find.byIcon(LucideIcons.check), findsNWidgets(2));
      // The round answers a 44 target round it.
      final centre = t.getCenter(find.byType(FrostedCheckbox).first);
      await t.tapAt(centre + const Offset(20, 0));
      await t.pump();
      expect(seen, [true, false, true]);
    });

    testWidgets('FrostedCheckbox is mixed at null, goes round with tristate, '
        'and says when it is wrong', (t) async {
      final seen = <bool?>[];
      final some = <bool?>[];
      await _pump(
        t,
        Column(
          children: [
            _Owner<bool?>(
              null,
              (v, set) => FrostedCheckbox(
                value: v,
                tristate: true,
                label: 'All bills',
                onChanged: set,
              ),
              seen: seen,
            ),
            FrostedCheckbox(
              value: null,
              label: 'Some',
              tristate: true,
              onChanged: some.add,
            ),
            const FrostedCheckbox(value: false, label: 'Terms', error: true),
          ],
        ),
      );
      expect(
        _node(t, 'All bills'),
        isSemantics(isChecked: false, isCheckStateMixed: true),
      );
      expect(find.byIcon(FrostedGlyphs.remove), findsNWidgets(2));
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byType(FrostedCheckbox).first);
        await t.pump();
      }
      expect(seen, [false, true, null]);
      // Mixed goes to clear, as Material's tristate Checkbox does; a box
      // that is never mixed takes no tristate (the constructor asserts it).
      await t.tap(find.byType(FrostedCheckbox).at(1));
      await t.pump();
      expect(some, [false]);
      expect(
        _node(t, 'Terms').getSemanticsData().validationResult,
        SemanticsValidationResult.invalid,
      );
    });
  });
}
