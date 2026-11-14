import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          Fluent2Host(brightness: brightness, child: page!),
      home: Builder(
        builder: (context) => ColoredBox(
          color: context.fluent2Theme.background,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );

/// The feedback, status and data group: badges and tags, the message bar,
/// progress and skeletons, the tooltip and the popovers, stats and tiles,
/// the week strip and the charts.
void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  final themes = [
    for (final id in Fluent2ThemeData.presets)
      for (final b in Brightness.values) Fluent2ThemeData.preset(id, b),
  ];
  String name(Fluent2ThemeData t) => '${t.id} ${t.brightness.name}';

  group('contrast', () {
    // Each ink over the ground it stands on (a translucent fill laid on
    // the grounds a page has), at Fluent's floors: words 4.5, glyphs and
    // marks 3.
    List<(String, Color, Color, double)> pairs(Fluent2ThemeData t) {
      final grounds = <String, Color>{
        'surface': t.surface,
        'ground': t.background,
        'card': t.colors.neutralCardBackground,
      };
      Color on(Color fill, Color ground) => Color.alphaBlend(fill, ground);
      return [
        for (final g in grounds.entries) ...[
          for (final a in Fluent2BadgeAppearance.values)
            for (final color in Fluent2BadgeColor.values)
              () {
                final f = Fluent2BadgeFace.of(t, a, color);
                return (
                  'badge ${a.name} ${color.name} on ${g.key}',
                  f.ink,
                  on(f.fill, g.value),
                  4.5,
                );
              }(),
          for (final s in Fluent2TaskStatus.values)
            (
              'status ${s.name} glyph on ${g.key}',
              Fluent2StatusGlyph.glyphOf(t, s).$2,
              g.value,
              3.0,
            ),
          for (final a in Fluent2TagAppearance.values)
            for (final selected in [false, true])
              for (final p in [
                Fluent2Press.rest,
                Fluent2Press.hover,
                Fluent2Press.pressed,
              ]) ...[
                () {
                  final f = Fluent2TagFace.of(t, a, p, selected: selected);
                  return (
                    'tag ${a.name}${selected ? ' selected' : ''} ${p.name} '
                        'on ${g.key}',
                    f.ink,
                    on(f.fill, g.value),
                    4.5,
                  );
                }(),
                () {
                  final f = Fluent2TagFace.of(t, a, p, selected: selected);
                  return (
                    'tag glyph ${a.name}${selected ? ' selected' : ''} '
                        '${p.name} on ${g.key}',
                    f.glyph,
                    on(f.fill, g.value),
                    3.0,
                  );
                }(),
              ],
          for (final i in Fluent2MessageIntent.values) ...[
            (
              'message ${i.name} words on its tint on ${g.key}',
              t.textPrimary,
              on(t.tone(i.tone).tint, g.value),
              4.5,
            ),
            (
              'message ${i.name} glyph on its tint on ${g.key}',
              t.tone(i.tone).ink,
              on(t.tone(i.tone).tint, g.value),
              3.0,
            ),
          ],
          for (final hue in Fluent2ChartHue.values)
            ('chart ${hue.name} on ${g.key}', hue.of(t), g.value, 3.0),
        ],
        for (final g in grounds.entries) ...[
          for (final color in Fluent2ProgressColor.values)
            (
              'progress ${color.name} on its track on ${g.key}',
              fluent2ProgressFill(t, color),
              on(fluent2ProgressTrack(t), g.value),
              3.0,
            ),
          // A tile's glyph is read at 3:1; the brand and named hues hold
          // their words' 4.5.
          for (final hue in Fluent2Hue.values)
            (
              'icon tile ${hue.name} on ${g.key}',
              hue.of(t).$2,
              on(hue.of(t).$1, g.value),
              hue == Fluent2Hue.neutral ? 3.0 : 4.5,
            ),
        ],
        for (final a in Fluent2FlyoutAppearance.values)
          (
            'flyout ${a.name} words',
            fluent2FlyoutFace(t, a).$2,
            fluent2FlyoutFace(t, a).$1,
            4.5,
          ),
        (
          'tooltip words',
          t.colors.neutralForeground1,
          t.colors.neutralBackground1,
          4.5,
        ),
        (
          'inverted tooltip words',
          t.colors.neutralForegroundStaticInverted,
          t.colors.neutralBackgroundStatic,
          4.5,
        ),
        for (final ink in [
          t.colors.brandForegroundOnLight,
          t.colors.brandForegroundOnLightHover,
          t.colors.brandForegroundOnLightPressed,
        ])
          (
            'teaching primary words on its fill',
            ink,
            t.colors.neutralForegroundOnBrand,
            4.5,
          ),
        (
          'teaching secondary edge on the brand',
          t.colors.neutralForegroundOnBrand,
          t.colors.brandBackground,
          3.0,
        ),
        for (final card in [
          t.colors.neutralCardBackground,
          t.colors.neutralCardBackgroundHover,
          t.colors.neutralCardBackgroundPressed,
        ]) ...[
          ('stat label on its card', t.textSecondary, card, 4.5),
          ('stat caption on its card', t.textTertiary, card, 4.5),
          ('stat figure on its card', t.textPrimary, card, 4.5),
        ],
        ('date block words', t.textSecondary, t.colors.neutralBackground3, 4.5),
        (
          'today date block words',
          t.colors.brandForeground2,
          t.colors.brandBackground2,
          4.5,
        ),
        for (final fill in [
          t.colors.brandBackground,
          t.colors.brandBackgroundHover,
          t.colors.brandBackgroundPressed,
        ])
          ('picked day number', t.colors.neutralForegroundOnBrand, fill, 4.5),
        for (final g in [t.surface, t.background])
          ('today day number', t.accentText, g, 4.5),
      ];
    }

    test('every preset and mode holds the floors', () {
      final failures = <String>[];
      for (final t in themes) {
        for (final (label, ink, ground, floor) in pairs(t)) {
          final ratio = Fluent2ThemeData.contrast(ink, ground);
          if (ratio < floor) {
            failures.add(
              '${name(t)}: $label ${ratio.toStringAsFixed(2)} < $floor',
            );
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('the categorical hues keep their fixed order', () {
      expect(Fluent2ChartHue.categorical, [
        Fluent2ChartHue.cornflower,
        Fluent2ChartHue.pumpkin,
        Fluent2ChartHue.magenta,
        Fluent2ChartHue.forest,
        Fluent2ChartHue.lavender,
      ]);
    });
  });

  group('badges', () {
    testWidgets('a badge shows and says its words', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Row(
            children: [
              Fluent2LabelBadge(label: 'Draft', icon: Fluent2Icons.edit),
              Fluent2LabelBadge(
                size: Fluent2BadgeSize.tiny,
                semanticLabel: 'New',
              ),
            ],
          ),
        ),
      );
      expect(find.text('Draft'), findsOneWidget);
      expect(find.bySemanticsLabel('Draft'), findsOneWidget);
      expect(find.bySemanticsLabel('New'), findsOneWidget);
      expect(
        tester.getSize(find.byType(Fluent2LabelBadge).last),
        const Size(6, 6),
      );
      semantics.dispose();
    });

    testWidgets('a counter badge overflows, hides at zero, dots', (
      tester,
    ) async {
      expect(Fluent2Badge.textOf(120, 99), '99+');
      expect(Fluent2Badge.textOf(7, 99), '7');
      await tester.pumpWidget(
        _host(
          const Row(
            children: [Fluent2Badge(120), Fluent2Badge(0), Fluent2Badge.dot()],
          ),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.bySemanticsLabel('New'), findsOneWidget);
    });

    testWidgets('a status glyph says its state', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              Fluent2StatusGlyph(
                Fluent2TaskStatus.done,
                label: 'Book the room',
              ),
              Fluent2StatusGlyph(Fluent2TaskStatus.blocked),
            ],
          ),
        ),
      );
      expect(find.text('Book the room'), findsOneWidget);
      expect(find.bySemanticsLabel('Book the room'), findsOneWidget);
      expect(find.byType(Icon), findsNWidgets(2));
    });
  });

  group('tags', () {
    testWidgets('a dismissible tag removes itself; a disabled one is inert', (
      tester,
    ) async {
      var removed = 0;
      await tester.pumpWidget(
        _host(
          Row(
            children: [
              Fluent2Tag('Design', onDeleted: () => removed++),
              Fluent2Tag('Legacy', enabled: false, onDeleted: () => removed++),
              const Fluent2Tag('Mara Okafor', avatar: 'Mara Okafor'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Design'));
      await tester.tap(find.text('Legacy'), warnIfMissed: false);
      expect(removed, 1);
      expect(find.bySemanticsLabel('Design, remove'), findsOneWidget);
      expect(find.text('MO'), findsOneWidget);
    });

    testWidgets('an interaction tag toggles and dismisses apart', (
      tester,
    ) async {
      var taps = 0;
      var dismissed = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Fluent2InteractionTag(
            'Shared with me',
            selected: true,
            onPressed: () => taps++,
            onDeleted: () => dismissed++,
          ),
        ),
      );
      await tester.tap(find.text('Shared with me'));
      expect(taps, 1);
      await tester.tap(find.bySemanticsLabel('Remove Shared with me'));
      expect(dismissed, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Shared with me')),
        isSemantics(isSelected: true, isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('a tag group picks one, or several', (tester) async {
      Set<String>? one;
      Set<String>? many;
      const items = [
        Fluent2TagItem('docs', 'Documents'),
        Fluent2TagItem('sheets', 'Spreadsheets'),
      ];
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              Fluent2TagGroup<String>(
                items: items,
                selected: const {'docs'},
                onSelectionChanged: (v) => one = v,
              ),
              Fluent2TagGroup<String>(
                items: items,
                multiple: true,
                selected: const {'docs'},
                onSelectionChanged: (v) => many = v,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Spreadsheets').first);
      expect(one, {'sheets'});
      await tester.tap(find.text('Spreadsheets').last);
      expect(many, {'docs', 'sheets'});
    });
  });

  group('message bar', () {
    testWidgets('says its intent, runs its action and dismisses', (
      tester,
    ) async {
      var joined = 0;
      var dismissed = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Fluent2MessageBar(
            title: 'Invited',
            body: 'Priya Raman invited you to Design.',
            intent: Fluent2MessageIntent.success,
            actions: [Fluent2Button('Join', onPressed: () => joined++)],
            onDismiss: () => dismissed++,
          ),
        ),
      );
      expect(find.textContaining('Priya Raman invited you'), findsOneWidget);
      await tester.tap(find.text('Join'));
      await tester.tap(find.bySemanticsLabel('Dismiss'));
      expect((joined, dismissed), (1, 1));
      expect(
        find.semantics.byPredicate((n) => n.flagsCollection.isLiveRegion),
        findsWidgets,
      );
      semantics.dispose();
    });
  });

  group('progress', () {
    testWidgets('a bar says its percentage; without a value it is busy', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              Fluent2ProgressBar(value: 6.2, max: 10, label: 'Team storage'),
              Fluent2ProgressBar(label: 'Preparing'),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Team storage')),
        isSemantics(value: '62%'),
      );
      expect(find.bySemanticsLabel('Preparing'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a segment bar names its parts', (tester) async {
      await tester.pumpWidget(
        _host(
          const Fluent2SegmentBar(
            label: 'Storage',
            total: 10,
            segments: [
              Fluent2SegmentBarPart('Documents', 3.2, valueText: '3.2 GB'),
              Fluent2SegmentBarPart('Images', 2.4, valueText: '2.4 GB'),
            ],
          ),
        ),
      );
      expect(find.textContaining('Documents 3.2 GB'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Storage.*Documents')), findsOne);
    });

    testWidgets('a skeleton is one busy node, its shapes silent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Fluent2Skeleton(
            label: 'Loading files',
            child: Row(
              children: [
                Fluent2SkeletonItem(
                  shape: Fluent2SkeletonShape.circle,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(child: Fluent2SkeletonItem()),
              ],
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Loading files'), findsOneWidget);
      expect(
        tester.getSize(find.byType(Fluent2SkeletonItem).first),
        const Size(32, 32),
      );
    });
  });

  group('tooltip and popovers', () {
    testWidgets('a tooltip shows under the pointer and names its control', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Center(
            child: Fluent2Tooltip(
              message: 'Share the file',
              withArrow: true,
              child: Fluent2IconButton(
                Fluent2Icons.share,
                label: 'Share',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Share the file'), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(Fluent2IconButton)));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('Share the file'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('Share the file'), findsNothing);
      semantics.dispose();
    });

    testWidgets('a bubble draws in place, with or without its arrow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const Fluent2TooltipBubble(message: 'Share'),
              Fluent2TooltipBubble(
                message: 'Copy link',
                appearance: Fluent2TooltipAppearance.inverted,
                placement: Fluent2ArrowPlacement()..offset = 24,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Share'), findsOneWidget);
      expect(
        tester.getSize(find.byType(Fluent2TooltipBubble).last).height -
            tester.getSize(find.byType(Fluent2TooltipBubble).first).height,
        Fluent2TooltipBubble.arrow * 2,
      );
    });

    testWidgets('a flyout opens at its control and goes on a tap outside', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Fluent2Button(
              'Who can see this',
              onPressed: () => Fluent2Flyout.show<void>(
                context,
                label: 'Access',
                builder: (context) => const Text('Everyone in Design'),
              ),
            ),
          ),
        ),
      );
      expect(const Fluent2Flyout(child: Text('x')).appearance, isNotNull);
      await tester.tap(find.text('Who can see this'));
      await tester.pumpAndSettle();
      expect(find.text('Everyone in Design'), findsOneWidget);
      await tester.tapAt(const Offset(790, 590));
      await tester.pumpAndSettle();
      expect(find.text('Everyone in Design'), findsNothing);
      await tester.tap(find.text('Who can see this'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Everyone in Design'), findsNothing);
    });

    testWidgets('a teaching popover completes with its act', (tester) async {
      bool? result = false;
      var primary = 0;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => Fluent2Button(
              'New channel',
              onPressed: () async {
                result = await Fluent2TeachingPopover.show(
                  context,
                  title: 'Channels keep work together',
                  body: 'Start one for each project.',
                  primaryLabel: 'Next',
                  secondaryLabel: 'Back',
                  onPrimaryPressed: () => primary++,
                  step: 2,
                  steps: 3,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('New channel'));
      await tester.pumpAndSettle();
      expect(find.text('Channels keep work together'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);
      // A tap outside leaves it open.
      await tester.tapAt(const Offset(790, 590));
      await tester.pumpAndSettle();
      expect(find.text('Channels keep work together'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(primary, 1);
      expect(find.text('Channels keep work together'), findsNothing);
    });

    testWidgets('a teaching popover drawn in place dismisses', (tester) async {
      var dismissed = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Fluent2TeachingPopover(
            title: 'Pin your files',
            body: 'Pinned files stay at the top.',
            onPrimaryPressed: () {},
            onDismiss: () => dismissed++,
            arrowAt: 40,
          ),
        ),
      );
      expect(find.text('Got it'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Dismiss'));
      expect(dismissed, 1);
      semantics.dispose();
    });
  });

  group('stats and tiles', () {
    testWidgets('a stat reads as one and opens what it counts', (tester) async {
      var opened = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const Fluent2Stat(
                label: 'Files shared',
                value: '1,284',
                delta: Fluent2StatDelta('+12%'),
                caption: 'vs last week',
                trend: [3, 5, 4, 7],
              ),
              Fluent2Stat(
                label: 'Storage used',
                value: '9.4',
                unit: 'GB',
                onPressed: () => opened++,
              ),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Files shared, 1,284, +12%, vs last week'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Storage used, 9.4 GB'));
      expect(opened, 1);
      expect(const Fluent2StatDelta('-3 h', up: false).isGood, isFalse);
      semantics.dispose();
    });

    testWidgets('a metadata line reads its items in order', (tester) async {
      await tester.pumpWidget(
        _host(
          const Fluent2MetaLine(
            items: [
              Fluent2MetaItem('Kai Tanaka', icon: Fluent2Icons.person),
              Fluent2MetaItem('Edited 2h ago', keepOnPhone: true),
            ],
          ),
        ),
      );
      expect(find.text('·'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Kai Tanaka, Edited 2h ago'),
        findsOneWidget,
      );
    });

    testWidgets('a counter lands on its value at once with motion off', (
      tester,
    ) async {
      expect(Fluent2Counter.grouped(1234567), '1,234,567');
      expect(Fluent2Counter.grouped(-1200), '-1,200');
      await tester.pumpWidget(_host(const Fluent2Counter(value: 12, from: 0)));
      await tester.pump();
      expect(find.text('12'), findsOneWidget);
      await tester.pumpWidget(_host(const Fluent2Counter(value: 1284)));
      await tester.pump();
      expect(find.text('1,284'), findsOneWidget);
    });

    testWidgets('an icon tile is an image when named, silent when not', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Row(
            children: [
              Fluent2IconTile(Fluent2Icons.folder, label: 'Folder'),
              Fluent2IconTile(
                Fluent2Icons.mail,
                hue: Fluent2Hue.teal,
                size: 24,
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Folder'), findsOneWidget);
      expect(
        tester.getSize(find.byType(Fluent2IconTile).first),
        const Size(40, 40),
      );
      expect(Fluent2IconTile.glyphOf(48), 28);
      expect(Fluent2IconTile.glyphOf(24), 16);
    });

    testWidgets('a date block sets and says the date', (tester) async {
      await tester.pumpWidget(
        _host(Fluent2DateBlock(date: DateTime(2026, 11, 3), emphasis: true)),
      );
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Nov'), findsOneWidget);
      expect(find.bySemanticsLabel('Tuesday, November 3'), findsOneWidget);
    });
  });

  group('week strip', () {
    test('a week starts on its first weekday', () {
      final week = Fluent2WeekStrip.weekOf(DateTime(2026, 11, 3));
      expect(week.first, DateTime(2026, 11, 2));
      expect(week.last, DateTime(2026, 11, 8));
      final sunday = Fluent2WeekStrip.weekOf(
        DateTime(2026, 11, 3),
        firstDayOfWeek: DateTime.sunday,
      );
      expect(sunday.first, DateTime(2026, 11, 1));
      expect(
        Fluent2WeekStrip.weekOf(DateTime(2026, 12, 31)).last,
        DateTime(2027, 1, 3),
      );
    });

    testWidgets('picks a day; without onChanged it is inert', (tester) async {
      DateTime? picked;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              Fluent2WeekStrip(
                value: DateTime(2026, 11, 3),
                today: DateTime(2026, 11, 3),
                hasEvents: (d) => d.day == 5,
                onChanged: (d) => picked = d,
              ),
              Fluent2WeekStrip(value: DateTime(2026, 12, 9)),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Tuesday, November 3, today'),
        ),
        isSemantics(isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Thursday, November 5')),
        isSemantics(value: 'Has events'),
      );
      await tester.tap(find.text('5'));
      expect(picked, DateTime(2026, 11, 5));
      picked = null;
      await tester.tap(find.text('10'), warnIfMissed: false);
      expect(picked, isNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Thursday, December 10')),
        isSemantics(isEnabled: false, hasEnabledState: true),
      );
      semantics.dispose();
    });
  });

  group('charts', () {
    testWidgets('a sparkline says where it starts and ends', (tester) async {
      await tester.pumpWidget(
        _host(
          const Fluent2Sparkline(
            values: [3, 5, 4, 9],
            label: 'Files shared',
            area: true,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Files shared, from 3 to 9'), findsOne);
    });

    testWidgets('a bar chart reads every bar and picks one', (tester) async {
      int? picked;
      final semantics = tester.ensureSemantics();
      const bars = [
        Fluent2Bar('Mon', 3, valueText: '3 h'),
        Fluent2Bar('Tue', 5, valueText: '5 h'),
        Fluent2Bar('Wed', 6.5, valueText: '6.5 h'),
      ];
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const Fluent2BarChart(label: 'Hours', highlight: 1, bars: bars),
              Fluent2BarChart(
                label: 'Pick',
                highlight: 2,
                bars: bars,
                onHighlight: (i) => picked = i,
              ),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Hours, Mon 3 h, Tue 5 h, Wed 6.5 h'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tue').last);
      expect(picked, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Wed').last),
        isSemantics(isSelected: true, value: '6.5 h'),
      );
      semantics.dispose();
    });
  });

  group('layout', () {
    for (final width in [390.0, 1280.0]) {
      testWidgets('nothing overflows at $width wide and text scale 1.3', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900) * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final b in Brightness.values) {
          await tester.pumpWidget(
            _host(
              brightness: b,
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Fluent2MessageBar(
                      title: 'Storage almost full',
                      body: 'Northwind has used 9.4 GB of its 10 GB.',
                      intent: Fluent2MessageIntent.warning,
                      actions: [
                        Fluent2Button('Add storage', onPressed: () {}),
                        Fluent2Button('Review files', onPressed: () {}),
                      ],
                      onDismiss: () {},
                    ),
                    const Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: Fluent2Stat(
                            label: 'Files shared this week',
                            value: '1,284',
                            delta: Fluent2StatDelta('+12% vs last week'),
                            trend: [3, 4, 6],
                          ),
                        ),
                        Expanded(
                          child: Fluent2Stat(
                            label: 'Meeting hours',
                            value: '18.5',
                            unit: 'h',
                            caption: 'Across 6 channels and 14 meetings',
                          ),
                        ),
                      ],
                    ),
                    Fluent2WeekStrip(
                      value: DateTime(2026, 11, 3),
                      today: DateTime(2026, 11, 3),
                      onChanged: (_) {},
                    ),
                    const Fluent2BarChart(
                      label: 'Hours',
                      highlight: 2,
                      bars: [
                        Fluent2Bar('Monday', 3, valueText: '3 hours'),
                        Fluent2Bar('Tuesday', 5, valueText: '5 hours'),
                        Fluent2Bar('Wednesday', 6.5, valueText: '6.5 hours'),
                        Fluent2Bar('Thursday', 2, valueText: '2 hours'),
                        Fluent2Bar('Friday', 4, valueText: '4 hours'),
                        Fluent2Bar('Saturday', 0, valueText: '0 hours'),
                        Fluent2Bar('Sunday', 1, valueText: '1 hour'),
                      ],
                    ),
                    const Fluent2SegmentBar(
                      label: 'Storage',
                      segments: [
                        Fluent2SegmentBarPart(
                          'Documents',
                          3.2,
                          valueText: '3.2 GB',
                        ),
                        Fluent2SegmentBarPart(
                          'Images',
                          2.4,
                          valueText: '2.4 GB',
                        ),
                        Fluent2SegmentBarPart(
                          'Recordings',
                          1.1,
                          valueText: '1.1 GB',
                        ),
                      ],
                    ),
                    Fluent2TagGroup<int>(
                      items: [
                        for (var i = 0; i < 6; i++)
                          Fluent2TagItem(i, 'Shared with me $i'),
                      ],
                      selected: const {0},
                      onSelectionChanged: (_) {},
                    ),
                    const Fluent2MetaLine(
                      items: [
                        Fluent2MetaItem(
                          'Tomas Lindqvist in the Design channel',
                        ),
                        Fluent2MetaItem('Edited 2h ago', keepOnPhone: true),
                        Fluent2MetaItem('14 comments', keepOnPhone: true),
                      ],
                    ),
                    Row(
                      children: [
                        Fluent2DateBlock(date: DateTime(2026, 11, 3)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Fluent2StatusGlyph(
                            Fluent2TaskStatus.inProgress,
                            label: 'Review the Q4 deck with Priya and Noor',
                          ),
                        ),
                      ],
                    ),
                    Fluent2TeachingPopover(
                      title: 'Channels keep work together',
                      body: 'Start one for each project; files stay in it.',
                      secondaryLabel: 'Back',
                      primaryLabel: 'Next',
                      step: 2,
                      steps: 3,
                      onPrimaryPressed: () {},
                      onDismiss: () {},
                    ),
                    const Fluent2ProgressBar(
                      value: 0.4,
                      label: 'Uploading Launch plan final final.docx',
                      hint: '3 of 5 files, about a minute left',
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
        }
      });
    }
  });
}
