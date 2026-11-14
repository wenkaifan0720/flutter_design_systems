import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final _light = MinimalThemeData.preset('standard', Brightness.light);
final _dark = MinimalThemeData.preset('standard', Brightness.dark);

Widget _app(Widget child, {double width = 390}) => MaterialApp(
  builder: (context, child) => MinimalHost(
    light: _light,
    dark: _dark,
    brightness: Brightness.light,
    child: child!,
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// [child] under a larger text scale.
Widget _scaled(Widget child, [double scale = 1.3]) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child,
  ),
);

void main() {
  group('MinimalHitTarget', () {
    testWidgets('hands a 28 px strip its 44 px targets', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The column holds the margin: only the strip hugs the pill.
              const SizedBox(height: 40),
              MinimalHitTarget(
                line: 28,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MinimalPressable(
                      onPressed: () => taps++,
                      semanticLabel: 'Pill',
                      child: const SizedBox(width: 60, height: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
      final pill = tester.getRect(find.bySemanticsLabel('Pill'));
      await tester.tapAt(pill.topCenter - const Offset(0, 7));
      await tester.tapAt(pill.bottomCenter + const Offset(0, 7));
      expect(taps, 2);
    });

    testWidgets('without it, a hugging strip cuts the margin off', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              SizedBox(
                height: 28,
                child: MinimalPressable(
                  onPressed: () => taps++,
                  semanticLabel: 'Pill',
                  child: const SizedBox(width: 60, height: 28),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
      final pill = tester.getRect(find.bySemanticsLabel('Pill'));
      await tester.tapAt(pill.topCenter - const Offset(0, 7));
      expect(taps, 0);
    });
  });

  group('MinimalListTile', () {
    testWidgets('a leading control keeps its whole 44 px target', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          MinimalListSection(
            children: [
              MinimalListTile(
                title: 'Drink water',
                leading: MinimalStatusIcon(
                  MinimalTaskStatus.todo,
                  semanticLabel: 'Drink water status',
                  onPressed: () => taps++,
                ),
                meta: '10d',
              ),
            ],
          ),
        ),
      );
      final glyph = tester.getCenter(
        find.bySemanticsLabel('Drink water status'),
      );
      // 19 px from the glyph's centre, left, up and down: inside a 44 px
      // square, outside the 20 px content line and inside the gutter.
      await tester.tapAt(glyph - const Offset(19, 0));
      await tester.tapAt(glyph - const Offset(0, 19));
      await tester.tapAt(glyph + const Offset(0, 19));
      expect(taps, 3);
    });

    testWidgets('below prints a widget line; metaWidth fixes the figure', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MinimalListSection(
            children: [
              for (final meta in ['4d', '12d'])
                MinimalListTile(
                  key: ValueKey(meta),
                  title: 'Row $meta',
                  below: const Text('HAB-12'),
                  trailing: const SizedBox(key: Key('dots'), width: 40),
                  meta: meta,
                  metaWidth: 30,
                  metaLabel: '$meta streak',
                ),
            ],
          ),
        ),
      );
      expect(find.text('HAB-12'), findsNWidgets(2));
      final dots = find.byKey(const Key('dots'));
      expect(tester.getTopLeft(dots.first).dx, tester.getTopLeft(dots.last).dx);
      expect(find.bySemanticsLabel('4d streak'), findsOneWidget);
    });

    testWidgets('a tappable row draws its focus ring inside its edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MinimalListSection(
            children: [MinimalListTile(title: 'Meditate', onTap: () {})],
          ),
        ),
      );
      final pressable = tester.widget<MinimalPressable>(
        find.byType(MinimalPressable),
      );
      expect(pressable.focusInside, isTrue);
    });
  });

  group('MinimalPressable semantics', () {
    testWidgets('toggled and focusable land on the control node', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Row(
            children: [
              MinimalIconButton(
                LucideIcons.star,
                label: 'Favourite',
                selected: true,
                onPressed: () {},
              ),
              MinimalPressable(
                onPressed: () {},
                focusable: false,
                semanticLabel: 'Segment',
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Favourite')),
        matchesSemantics(
          label: 'Favourite',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasToggledState: true,
          isToggled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Segment')),
        matchesSemantics(
          label: 'Segment',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('MinimalSwitch labelled', () {
    testWidgets('a tap on the words flips it', (tester) async {
      var on = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.centerLeft,
              child: MinimalSwitch(
                value: on,
                label: 'Create another',
                showLabel: true,
                onChanged: (v) => setState(() => on = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Create another'));
      await tester.pump();
      expect(on, isTrue);
    });
  });

  group('MinimalPropertyPill items', () {
    testWidgets('opens its own anchored menu', (tester) async {
      String group = 'Evening';
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => MinimalPropertyBar(
              pills: [
                MinimalPropertyPill(
                  icon: LucideIcons.folder,
                  label: group,
                  name: 'Group',
                  hasValue: true,
                  items: [
                    for (final g in const ['Morning', 'Evening'])
                      MinimalMenuItem(
                        g,
                        selected: g == group,
                        onPressed: () => setState(() => group = g),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Evening'));
      await tester.pumpAndSettle();
      final pill = tester.getRect(find.bySemanticsLabel('Group, Evening'));
      final morning = tester.getRect(find.text('Morning'));
      expect(morning.top, greaterThan(pill.bottom));
      await tester.tap(find.text('Morning'));
      await tester.pumpAndSettle();
      expect(group, 'Morning');
    });
  });

  group('MinimalMenu', () {
    testWidgets('prints a shortcut as key caps', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => MinimalMenu(
              label: 'Actions',
              items: [
                MinimalMenuItem('Copy ID', shortcut: '⌘ C', onPressed: () {}),
              ],
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(MinimalKbd), findsNWidgets(2));
      expect(
        find.bySemanticsLabel(RegExp('Shortcut Command C')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the text pill carries a disclosure chevron', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalMenu.button(
            LucideIcons.calendarDays,
            text: 'Today',
            label: 'Date range',
            items: [MinimalMenuItem('Today', onPressed: () {})],
          ),
        ),
      );
      final icons = tester.widgetList<MinimalIcon>(find.byType(MinimalIcon));
      expect(icons.length, 2);
    });
  });

  group('MinimalPriorityIcon', () {
    testWidgets('announces the priority', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const Row(
            children: [
              MinimalPriorityIcon(MinimalPriority.high),
              MinimalPriorityIcon(MinimalPriority.none),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('High priority'), findsOneWidget);
      expect(find.bySemanticsLabel('No priority'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MinimalTable', () {
    testWidgets('a badge column grows with the text scale', (tester) async {
      await tester.pumpWidget(
        _app(
          _scaled(
            const MinimalTable(
              columns: [
                MinimalColumn('Name'),
                MinimalColumn('Status', width: 84, alignEnd: true),
              ],
              rows: [
                MinimalTableRow([
                  MinimalCell('Hanna'),
                  MinimalCell.badge('Ready', tone: MinimalTone.success),
                ]),
              ],
            ),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Ready'),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pinned sortable header takes taps above its band', (
      tester,
    ) async {
      final sorted = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MinimalHost(
            light: _light,
            dark: _dark,
            brightness: Brightness.light,
            child: child!,
          ),
          home: MinimalScaffold(
            padding: EdgeInsets.zero,
            scroll: false,
            body: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
                MinimalTable.sliver(
                  columns: const [
                    MinimalColumn('#', width: 54, mono: true, sortable: true),
                    MinimalColumn('Customer'),
                  ],
                  onSort: (column, _) => sorted.add(column),
                  rows: const [
                    MinimalTableRow([
                      MinimalCell('1047'),
                      MinimalCell('Hanna'),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      final header = tester.getRect(find.bySemanticsLabel('#, sort'));
      await tester.tapAt(header.topCenter - const Offset(0, 5));
      expect(sorted, [0]);
    });
  });

  group('MinimalBottomSheet footer', () {
    testWidgets('the actions drop under a long accessory', (tester) async {
      await tester.pumpWidget(
        _app(
          const MinimalBottomSheet(
            title: 'New habit',
            leading: MinimalSheetAction('Cancel'),
            trailing: MinimalSheetAction('Create habit', isDefaultAction: true),
            accessory: MinimalSwitch(
              value: false,
              label: 'Create another habit after this one',
              showLabel: true,
            ),
            child: SizedBox(height: 40),
          ),
          width: 300,
        ),
      );
      expect(tester.takeException(), isNull);
      final accessory = tester.getRect(
        find.text('Create another habit after this one'),
      );
      final create = tester.getRect(find.text('Create habit'));
      expect(create.top, greaterThan(accessory.bottom));
    });
  });

  group('MinimalBottomSheet header', () {
    testWidgets('a lone title names the sheet; after a pill it is a crumb', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              MinimalBottomSheet(title: 'Filters', child: SizedBox(height: 8)),
              MinimalBottomSheet(
                title: 'New habit',
                subtitle: 'Habits',
                child: SizedBox(height: 8),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final lone = tester.widget<Text>(find.text('Filters')).style;
      expect(lone?.color, _light.h3.color);
      expect(lone?.fontWeight, _light.h3.fontWeight);
      expect(lone?.fontSize, _light.h3.fontSize);
      final crumb = tester.widget<Text>(find.text('New habit')).style;
      expect(crumb?.color, _light.mutedForeground);
      expect(crumb?.fontSize, _light.bodySmall.fontSize);
    });
  });

  group('MinimalPreview under', () {
    testWidgets('a sheet stands over the page it was raised from', (
      tester,
    ) async {
      await tester.pumpWidget(
        MinimalPreview(
          light: _light,
          dark: _dark,
          brightness: Brightness.light,
          presentation: MinimalPresentation.sheet,
          tabs: const [
            MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
            MinimalNavItem(LucideIcons.settings, 'Settings'),
          ],
          under: const MinimalScaffold(
            topBar: MinimalAppBar(title: 'Habit list'),
            body: SizedBox.shrink(),
          ),
          child: const MinimalScaffold(
            topBar: MinimalAppBar(title: 'New habit', subtitle: 'Habits'),
            body: SizedBox(height: 80),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Habit list'), findsOneWidget);
      expect(find.text('New habit'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('MinimalAppBar titleTrailing', () {
    testWidgets('stands a control beside a root title', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalAppBar(
            title: 'Orders',
            titleTrailing: MinimalMenu.button(
              LucideIcons.calendarDays,
              text: 'Today',
              label: 'Date range',
              items: [MinimalMenuItem('Today', onPressed: () {})],
            ),
          ),
        ),
      );
      final title = tester.getRect(find.text('Orders'));
      final range = tester.getRect(find.text('Today'));
      expect(range.left, greaterThan(title.right));
    });
  });
}
