import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

final MinimalThemeData _light = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

// The host stands above the Navigator, as an app mounts it.
Widget _host(
  Widget child, {
  bool disableAnimations = false,
  MinimalThemeData? theme,
}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: theme ?? _light,
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: navigator!,
    ),
  ),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 390, child: child),
    ),
  ),
);

/// The ruled column a divided row group lays its rows out in.
final Finder _ruled = find
    .descendant(
      of: find.byType(MinimalListSection),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_RuledColumn',
      ),
    )
    .first;

/// Paints exactly [count] hairline rules (static rows paint no rects of
/// their own, so every rect the column draws is a rule).
Matcher _rules(int count) => paintsExactlyCountTimes(#drawRect, count);

/// A child that keeps a count in its State.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps += 1),
    child: SizedBox(height: 44, child: Text('taps $taps')),
  );
}

void main() {
  group('MinimalCard', () {
    testWidgets('a static card is not a control', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const MinimalCard(child: Text('Summary'))));
      expect(find.byType(MinimalPressable), findsNothing);
      expect(
        tester.getSemantics(find.text('Summary')),
        isNot(matchesSemantics(isButton: true)),
      );
      handle.dispose();
    });

    testWidgets('a tappable card taps, and a selected one says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalCard(
            selected: true,
            onPressed: () => taps += 1,
            child: const Text('Evening'),
          ),
        ),
      );
      await tester.tap(find.text('Evening'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Evening')),
        matchesSemantics(
          label: 'Evening',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a card activates from the keyboard', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalCard(onPressed: () => taps += 1, child: const Text('Plan')),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('flat is the surfaceAlt panel, plain is the surface', (
      tester,
    ) async {
      Color fill() {
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MinimalCard),
                matching: find.byType(Container),
              )
              .first,
        );
        return (box.decoration! as BoxDecoration).color!;
      }

      await tester.pumpWidget(_host(const MinimalCard(child: Text('a'))));
      expect(fill(), _light.card);
      await tester.pumpWidget(
        _host(const MinimalCard(flat: true, child: Text('a'))),
      );
      await tester.pumpAndSettle();
      expect(fill(), _light.muted);
    });

    testWidgets('an unselected option of a set announces it', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          MinimalCard(
            selected: false,
            onPressed: () {},
            child: const Text('Morning'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Morning')),
        matchesSemantics(
          label: 'Morning',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a lone row in a padded card stands at the card inset', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MinimalCard(child: MinimalListTile(title: 'Meditate'))),
      );
      // The card's hairline and its 14 px padding; the row adds none.
      expect(
        tester.getTopLeft(find.text('Meditate')).dx -
            tester.getTopLeft(find.byType(MinimalCard)).dx,
        _light.hairline + MinimalCard.inset,
      );
    });
  });

  group('MinimalSection', () {
    testWidgets('prints its title upper-cased as a header, with the count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalSection(
            title: 'Last 12 weeks',
            count: '71 / 84',
            child: SizedBox(height: 20),
          ),
        ),
      );
      expect(find.text('LAST 12 WEEKS'), findsOneWidget);
      expect(find.text('71 / 84'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('LAST 12 WEEKS')),
        // One header node: the label and its count read together.
        matchesSemantics(label: 'LAST 12 WEEKS\n71 / 84', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('its action taps, and with no callback it is disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MinimalSection(
                title: 'Activity',
                actionLabel: 'View all',
                onAction: () => taps += 1,
                child: const SizedBox(),
              ),
              const MinimalSection(
                title: 'Notes',
                actionLabel: 'Export',
                child: SizedBox(),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('View all'));
      await tester.tap(find.text('Export'), warnIfMissed: false);
      expect(taps, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Export')),
        matchesSemantics(
          label: 'Export',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('its header is the group header band, 14 above and 6 below', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              MinimalSection(title: 'Morning', child: SizedBox()),
              MinimalSection(title: 'Evening', gutter: true, child: SizedBox()),
              MinimalCard(
                padding: EdgeInsets.zero,
                child: MinimalSection(
                  title: 'Night',
                  gutter: true,
                  child: SizedBox(),
                ),
              ),
            ],
          ),
        ),
      );
      EdgeInsets band(String label) => tester
          .widget<MinimalSectionHeader>(
            find.byWidgetPredicate(
              (w) => w is MinimalSectionHeader && w.label == label,
            ),
          )
          .padding
          .resolve(TextDirection.ltr);
      expect(band('Morning'), const EdgeInsets.fromLTRB(0, 14, 0, 6));
      expect(
        band('Evening'),
        const EdgeInsets.fromLTRB(
          MinimalChromeMetrics.gutter,
          14,
          MinimalChromeMetrics.gutter,
          6,
        ),
      );
      expect(
        band('Night'),
        const EdgeInsets.fromLTRB(MinimalCard.inset, 14, MinimalCard.inset, 6),
      );
    });
  });

  group('MinimalListTile', () {
    testWidgets('is 44 tall, 36 dense, and taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MinimalListTile(
                key: const Key('row'),
                title: 'Drink water',
                meta: '10d',
                chevron: true,
                onTap: () => taps += 1,
              ),
              const MinimalListTile(
                key: Key('dense'),
                title: 'Hanna Berg',
                dense: true,
              ),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('row'))).height, 44);
      expect(tester.getSize(find.byKey(const Key('dense'))).height, 36);
      expect(find.text('10d'), findsOneWidget);
      await tester.tap(find.text('Drink water'));
      expect(taps, 1);
    });

    testWidgets('a disabled row swallows taps and says it is disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          MinimalListTile(
            title: 'Water the plants',
            enabled: false,
            onTap: () => taps += 1,
          ),
        ),
      );
      await tester.tap(find.text('Water the plants'), warnIfMissed: false);
      expect(taps, 0);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Water the plants')),
        matchesSemantics(
          label: 'Water the plants',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('selected is announced, tappable or not', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              MinimalListTile(
                title: 'Morning run',
                selected: true,
                onTap: () {},
              ),
              const MinimalListTile(title: 'Journal', selected: true),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Morning run')),
        matchesSemantics(
          label: 'Morning run',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Journal')),
        matchesSemantics(
          label: 'Journal',
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a row activates from the keyboard', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(MinimalListTile(title: 'Meditate', onTap: () => taps += 1)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('keyboard focus draws the ring inside the row', (tester) async {
      await tester.pumpWidget(
        _host(MinimalListTile(title: 'Meditate', onTap: () {})),
      );
      Iterable<Container> ringed() => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MinimalListTile),
              matching: find.byType(Container),
            ),
          )
          .where(
            (c) =>
                (c.foregroundDecoration as BoxDecoration?)?.border ==
                Border.all(
                  color: _light.ring,
                  width: MinimalChromeMetrics.focusRing,
                ),
          );
      expect(ringed(), isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringed(), hasLength(1));
    });

    testWidgets('a long title ellipsizes instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MinimalListTile(
            title: 'A habit with a name far longer than any row could hold',
            subtitle: 'And a caption that is also far too long to fit here',
            trailing: const MinimalTag('Late', tone: MinimalTone.warning),
            meta: '09:30',
            chevron: true,
            onTap: () {},
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('MinimalListSection', () {
    testWidgets('on the page: gutter rows, a rule between them, the last '
        'row bare', (tester) async {
      await tester.pumpWidget(
        _host(
          const MinimalListSection(
            children: [
              MinimalListTile(title: 'Meditate'),
              MinimalListTile(title: 'Journal'),
            ],
          ),
        ),
      );
      // Under the last row the rule would divide nothing: the space that
      // follows the list closes it.
      expect(tester.renderObject(_ruled), _rules(1));
      expect(
        tester.getTopLeft(find.text('Meditate')).dx -
            tester.getTopLeft(find.byType(MinimalListSection)).dx,
        MinimalChromeMetrics.gutter,
      );
    });

    testWidgets('in a card: the card inset and rules between rows only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MinimalListSection(
            inset: true,
            children: [
              MinimalListTile(title: 'Meditate'),
              MinimalListTile(title: 'Journal'),
            ],
          ),
        ),
      );
      expect(find.byType(MinimalCard), findsOneWidget);
      expect(tester.renderObject(_ruled), _rules(1));
      // The card's hairline, then its inset.
      expect(
        tester.getTopLeft(find.text('Meditate')).dx -
            tester.getTopLeft(find.byType(MinimalListSection)).dx,
        _light.hairline + MinimalCard.inset,
      );
    });

    testWidgets('gutter: false leaves the rows at the edge', (tester) async {
      await tester.pumpWidget(
        _host(
          const MinimalListSection(
            gutter: false,
            children: [MinimalListTile(title: 'Meditate')],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Meditate')).dx,
        tester.getTopLeft(find.byType(MinimalListSection)).dx,
      );
    });

    testWidgets('a group placed in a padless card by hand reads the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MinimalCard(
            padding: EdgeInsets.zero,
            child: MinimalListSection(
              children: [
                MinimalListTile(title: 'Meditate'),
                MinimalListTile(title: 'Journal'),
                MinimalListTile(title: 'Read 20 pages'),
              ],
            ),
          ),
        ),
      );
      expect(tester.renderObject(_ruled), _rules(2));
    });

    testWidgets('a hidden trailing reveal leaves no rule on the card edge', (
      tester,
    ) async {
      Widget group(bool third) => _host(
        MinimalListSection(
          inset: true,
          children: [
            const MinimalListTile(title: 'Meditate'),
            const MinimalListTile(title: 'Journal'),
            MinimalReveal(
              visible: third,
              child: const MinimalListTile(title: 'Read 20 pages'),
            ),
          ],
        ),
      );
      await tester.pumpWidget(group(true));
      expect(tester.renderObject(_ruled), _rules(2));
      await tester.pumpWidget(group(false));
      await tester.pumpAndSettle();
      // Only the rule between the two rows still showing; Journal, the
      // last one showing, is closed by the card's own edge.
      expect(tester.renderObject(_ruled), _rules(1));
    });

    testWidgets('a folded reveal on the page draws no rule of its own', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MinimalListSection(
            children: [
              MinimalListTile(title: 'Meditate'),
              MinimalReveal(
                visible: false,
                child: MinimalListTile(title: 'Journal'),
              ),
              MinimalListTile(title: 'Read 20 pages'),
            ],
          ),
        ),
      );
      // Only Meditate's: the folded row draws none, the last is bare.
      expect(tester.renderObject(_ruled), _rules(1));
    });
  });

  testWidgets('MinimalMetaRow keeps one line, ellipsizing only its middle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 220,
          child: MinimalMetaRow(
            leading: Text('1047'),
            middle: Text(
              'Studio North asked to move their standing order to Tuesdays',
            ),
            trailing: Text('09:30'),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('1047'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    final middle = tester.getSize(find.textContaining('Studio North'));
    expect(middle.height, lessThan(24));
  });

  group('MinimalTag', () {
    testWidgets('is 20 tall in its tone ink', (tester) async {
      await tester.pumpWidget(
        _host(
          const Align(
            child: MinimalTag('Overdue', tone: MinimalTone.destructive),
          ),
        ),
      );
      expect(tester.getSize(find.byType(MinimalTag)).height, MinimalTag.height);
      final text = tester.widget<Text>(find.text('Overdue'));
      expect(
        text.style!.color,
        _light.tone(MinimalTone.destructive).foreground,
      );
    });
  });

  group('MinimalAvatar', () {
    test('initials and tone are deterministic', () {
      expect(MinimalAvatar.initialsOf('Hanna Berg'), 'HB');
      expect(MinimalAvatar.initialsOf('  mara   quintero  x'), 'MQ');
      expect(MinimalAvatar.initialsOf('Oskar'), 'O');
      expect(
        MinimalAvatar.colorsOf('Hanna Berg', _light),
        MinimalAvatar.colorsOf('Hanna Berg', _light),
      );
    });

    test('a face is a neutral shade, never the accent or a status', () {
      const names = [
        'Hanna Berg',
        'Oskar Lind',
        'Ines Duarte',
        'Tom Alves',
        'Liv Sande',
        'Mara Quintero',
        'Jonas Weber',
        'Café Morgen',
      ];
      for (final id in MinimalThemeData.presets) {
        for (final b in Brightness.values) {
          final t = MinimalThemeData.preset(id, b);
          final status = [
            for (final tone in [MinimalTone.success, MinimalTone.warning]) ...[
              t.tone(tone).foreground,
              t.tone(tone).background,
            ],
            t.destructive,
            t.destructiveSubtle,
          ];
          // A face's tint is the muted fill's, never more.
          double chroma(Color c) =>
              [c.r, c.g, c.b].reduce(math.max) -
              [c.r, c.g, c.b].reduce(math.min);
          for (final name in names) {
            final c = MinimalAvatar.colorsOf(name, t);
            expect(status, isNot(contains(c.fill)), reason: '$id $b $name');
            expect(status, isNot(contains(c.ink)), reason: '$id $b $name');
            expect(c.fill, isNot(t.primary), reason: '$id $b $name');
            expect(
              chroma(c.fill),
              lessThanOrEqualTo(chroma(t.muted) + 1e-6),
              reason: '$id $b $name',
            );
            expect(c.ink, t.foreground, reason: '$id $b $name');
            // The initials read on their disc.
            final lf = c.fill.computeLuminance();
            final li = c.ink.computeLuminance();
            final ratio = (math.max(lf, li) + 0.05) / (math.min(lf, li) + 0.05);
            expect(ratio, greaterThanOrEqualTo(4.5), reason: '$id $b $name');
          }
          // A stack of three people shows three faces.
          final stack = {
            for (final name in ['Hanna Berg', 'Oskar Lind', 'Ines Duarte'])
              MinimalAvatar.colorsOf(name, t).fill,
          };
          expect(stack, hasLength(3), reason: '$id $b');
        }
      }
    });

    testWidgets('draws initials at its size and announces the name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const Align(child: MinimalAvatar('Hanna Berg', size: 32))),
      );
      expect(find.text('HB'), findsOneWidget);
      expect(tester.getSize(find.byType(MinimalAvatar)), const Size(32, 32));
      expect(
        tester.getSemantics(find.byType(MinimalAvatar)),
        matchesSemantics(label: 'Hanna Berg', isImage: true),
      );
      handle.dispose();
    });

    testWidgets('an unresolved media slot falls back to the initials', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Align(child: MinimalAvatar('Mara Quintero', media: 'x'))),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(MinimalMediaImage), findsOneWidget);
      expect(find.text('MQ'), findsOneWidget);
    });

    testWidgets('a stack folds the rest into +N and speaks every name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Align(
            child: MinimalAvatarGroup([
              'Hanna Berg',
              'Oskar Lind',
              'Ines Duarte',
              'Tom Alves',
              'Liv Sande',
            ], max: 3),
          ),
        ),
      );
      expect(find.text('+2'), findsOneWidget);
      expect(find.byType(MinimalAvatar), findsNWidgets(3));
      expect(
        tester.getSemantics(find.byType(MinimalAvatarGroup)),
        matchesSemantics(
          label: 'Hanna Berg, Oskar Lind, Ines Duarte and 2 more',
          isImage: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a stack rings its faces in the ground it stands on', (
      tester,
    ) async {
      Iterable<Color?> rings() => tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(MinimalAvatarGroup),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.shape == BoxShape.circle && d.border == null)
          .map((d) => d.color);
      const stack = MinimalAvatarGroup(['Hanna Berg', 'Oskar Lind']);
      await tester.pumpWidget(_host(const Align(child: stack)));
      expect(rings(), [_light.background, _light.background]);
      await tester.pumpWidget(
        _host(const Align(child: MinimalCard(child: stack))),
      );
      expect(rings(), [_light.card, _light.card]);
    });
  });

  testWidgets('MinimalIconTile is the size it is given', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinimalIconTile(Icons.settings, key: Key('a')),
            MinimalIconTile(Icons.settings, size: 40, key: Key('b')),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('a'))), const Size(28, 28));
    expect(tester.getSize(find.byKey(const Key('b'))), const Size(40, 40));
  });

  group('MinimalMedia', () {
    testWidgets('a placeholder fills the width and is silent by default', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalMedia(
            MinimalPlaceholderImage(MinimalMediaKind.food, 2),
            height: 120,
          ),
        ),
      );
      expect(tester.getSize(find.byType(MinimalMedia)), const Size(390, 120));
      expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
      handle.dispose();
    });

    testWidgets('an unresolved slot paints the placeholder, labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const MinimalMedia.media(
            'hero-bakery',
            height: 160,
            semanticLabel: 'The bakery counter',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel('The bakery counter')),
        matchesSemantics(label: 'The bakery counter', isImage: true),
      );
      handle.dispose();
    });

    testWidgets('placeholders are flat quiet fills, no gradient and no hue', (
      tester,
    ) async {
      for (final id in MinimalThemeData.presets) {
        for (final b in Brightness.values) {
          final t = MinimalThemeData.preset(id, b);
          await tester.pumpWidget(
            _host(
              Wrap(
                children: [
                  for (final kind in MinimalMediaKind.values)
                    for (var i = 0; i < 3; i++)
                      MinimalMedia(
                        MinimalPlaceholderImage(kind, i),
                        width: 44,
                        height: 44,
                      ),
                ],
              ),
              theme: t,
            ),
          );
          // The host eases from the last preset's colours to this one's.
          await tester.pumpAndSettle();
          final fills = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(MinimalMedia),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .map((d) => d.decoration)
              .whereType<BoxDecoration>()
              .where((d) => d.gradient != null || d.color != null)
              .toList();
          expect(fills, isNotEmpty, reason: '$id $b');
          for (final d in fills) {
            expect(d.gradient, isNull, reason: '$id $b');
          }
          final colors = fills.map((d) => d.color!).toSet();
          // A step lighter or darker by index, between the quiet fill and
          // the well, and never more than those.
          expect(colors.length, inInclusiveRange(2, 3), reason: '$id $b');
          for (final c in colors) {
            expect(
              c == t.muted ||
                  c == t.sunken ||
                  c == Color.lerp(t.muted, t.sunken, 0.5),
              isTrue,
              reason: '$id $b $c',
            );
          }
        }
      }
    });
  });

  group('MinimalReveal', () {
    Widget reveal(bool visible, {bool disable = false}) => _host(
      Column(
        children: [
          MinimalReveal(
            visible: visible,
            child: const SizedBox(height: 44, child: Text('Note')),
          ),
          const Text('Below'),
        ],
      ),
      disableAnimations: disable,
    );

    testWidgets('grows in and folds away over 120 ms', (tester) async {
      await tester.pumpWidget(reveal(false));
      expect(find.text('Note'), findsNothing);
      final below = tester.getTopLeft(find.text('Below')).dy;

      await tester.pumpWidget(reveal(true));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getTopLeft(find.text('Below')).dy;
      expect(mid, greaterThan(below));
      expect(mid, lessThan(below + 44));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Below')).dy, below + 44);

      await tester.pumpWidget(reveal(false));
      await tester.pump(const Duration(milliseconds: 60));
      // Leaving: still painted, but out of the page's hit testing.
      expect(find.text('Note'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Note'),
          matching: find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring,
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.text('Note'), findsNothing);
      expect(tester.getTopLeft(find.text('Below')).dy, below);
    });

    testWidgets('clips only while it moves, so a focus ring survives', (
      tester,
    ) async {
      Widget page(bool visible) => _host(
        Column(
          children: [
            MinimalReveal(
              visible: visible,
              child: MinimalButton('Save', onPressed: () {}),
            ),
          ],
        ),
      );
      Clip clip() => tester
          .renderObject<RenderClipRect>(
            find.descendant(
              of: find.byType(MinimalReveal),
              matching: find.byType(ClipRect),
            ),
          )
          .clipBehavior;
      await tester.pumpWidget(page(true));
      expect(clip(), Clip.none);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      // The button's ring stands outside its edge, and nothing cuts it.
      final ring = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(MinimalButton),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((c) => c.foregroundDecoration)
          .nonNulls
          .where(
            (d) => d.toDiagnosticsNode().getProperties().any(
              (p) => p.name == 'ring' && p.value is Color,
            ),
          );
      expect(ring, isNotEmpty);
      expect(clip(), Clip.none);
      await tester.pumpWidget(page(false));
      await tester.pump(const Duration(milliseconds: 60));
      expect(clip(), Clip.hardEdge);
      await tester.pumpAndSettle();
    });

    testWidgets('a child keeps its state when the reveal turns back', (
      tester,
    ) async {
      Widget page(bool visible) => _host(
        Column(
          children: [MinimalReveal(visible: visible, child: const _Counter())],
        ),
      );
      await tester.pumpWidget(page(true));
      await tester.tap(find.text('taps 0'));
      await tester.pump();
      final state = tester.state<_CounterState>(find.byType(_Counter));
      await tester.pumpWidget(page(false));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.state<_CounterState>(find.byType(_Counter)), same(state));
      await tester.pumpWidget(page(true));
      await tester.pumpAndSettle();
      expect(tester.state<_CounterState>(find.byType(_Counter)), same(state));
      expect(find.text('taps 1'), findsOneWidget);
    });

    testWidgets('switches at once with MinimalMotion.animate off', (
      tester,
    ) async {
      MinimalMotion.animate = false;
      addTearDown(() => MinimalMotion.animate = true);
      await tester.pumpWidget(reveal(true));
      await tester.pumpWidget(reveal(false));
      await tester.pump();
      expect(find.text('Note'), findsNothing);
    });

    testWidgets('switches at once when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(reveal(true, disable: true));
      await tester.pumpWidget(reveal(false, disable: true));
      await tester.pump();
      expect(find.text('Note'), findsNothing);
    });
  });
}
