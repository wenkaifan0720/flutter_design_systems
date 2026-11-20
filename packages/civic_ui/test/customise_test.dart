// What an app can change and what it cannot: a brand colour is held to 7:1
// on the ground and on a card by day and by night, keeping its hue; a focus plate that
// cannot carry ink words and a tap floor under 48 are refused; a part's
// own style wins over its theme slot, which wins over the look; the face
// reaches Flutter's own widgets under Civic.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

double _hue(Color c) => HSLColor.fromColor(c).hue;

void main() {
  group('the brand factory', () {
    const green = Color(0xFF0A7D4F);

    test('holds an action colour to 7:1 by day, darker, its hue kept', () {
      final t = CivicThemeData.from(
        brightness: Brightness.light,
        action: green,
      );
      // By day the ground is the darker of the two the words stand on.
      final ratio = CivicThemeData.contrastRatio(t.action, t.ground);
      expect(ratio, greaterThanOrEqualTo(7));
      expect(ratio, lessThan(7.4), reason: 'darkened no further than needed');
      expect(
        CivicThemeData.contrastRatio(t.action, t.background),
        greaterThanOrEqualTo(7),
      );
      expect(_hue(t.action), closeTo(_hue(green), 2));
      expect(
        HSLColor.fromColor(t.action).lightness,
        lessThan(HSLColor.fromColor(green).lightness),
      );
    });

    test('lightens it by night', () {
      final t = CivicThemeData.from(brightness: Brightness.dark, action: green);
      expect(
        CivicThemeData.contrastRatio(t.action, t.background),
        greaterThanOrEqualTo(7),
      );
      expect(_hue(t.action), closeTo(_hue(green), 2));
      expect(
        HSLColor.fromColor(t.action).lightness,
        greaterThan(HSLColor.fromColor(green).lightness),
      );
    });

    test('holds danger and success the same way', () {
      for (final b in Brightness.values) {
        final t = CivicThemeData.from(
          brightness: b,
          danger: const Color(0xFFFF4D4D),
          success: const Color(0xFF33CC66),
        );
        for (final c in [t.danger, t.success]) {
          expect(
            CivicThemeData.contrastRatio(c, t.background),
            greaterThanOrEqualTo(7),
          );
        }
      }
    });

    test("keeps a button's words at 4.5:1 on any action colour", () {
      for (final seed in const [
        Color(0xFF0A7D4F),
        Color(0xFF6A1B9A),
        Color(0xFFE65100),
        Color(0xFF00838F),
      ]) {
        for (final b in Brightness.values) {
          final t = CivicThemeData.from(brightness: b, action: seed);
          expect(
            CivicThemeData.contrastRatio(t.onAction, t.action),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });

    test('the focus plate carries the same dark ink by day and night', () {
      for (final focus in const [null, Color(0xFFFFB84D), Color(0xFFFFE066)]) {
        for (final brightness in Brightness.values) {
          final theme = CivicThemeData.from(
            brightness: brightness,
            focus: focus,
          );
          expect(theme.focusBar, const Color(0xFF0C1116));
          expect(theme.focusBar, theme.onFocus);
          expect(
            CivicThemeData.contrastRatio(theme.focusBar, theme.focus),
            greaterThanOrEqualTo(7),
          );
          const ink = Color(0xFF101820);
          expect(theme.copyWith(onFocus: ink).focusBar, ink);
        }
      }
    });

    test('refuses a focus plate that cannot carry ink words', () {
      expect(
        () => CivicThemeData.from(
          brightness: Brightness.light,
          focus: const Color(0xFF1F5FBF),
        ),
        throwsAssertionError,
      );
      // A lighter, warmer plate is fine.
      CivicThemeData.from(
        brightness: Brightness.light,
        focus: const Color(0xFFFFB84D),
      );
    });

    test('refuses a tap floor under 48 for a finger or 24 for a pointer', () {
      final t = CivicThemeData.light();
      expect(
        () => t.copyWith(
          tapTargets: const DesignTapTargets(touch: Size.square(40)),
        ),
        throwsAssertionError,
      );
      expect(
        () => t.copyWith(
          tapTargets: const DesignTapTargets(
            touch: Size.square(48),
            pointer: Size.square(20),
          ),
        ),
        throwsAssertionError,
      );
      // A floor can rise.
      t.copyWith(
        tapTargets: const DesignTapTargets(
          touch: Size.square(56),
          pointer: Size.square(32),
        ),
      );
    });

    test('sets the face for the ramp, keeping figures in code', () {
      final t = CivicThemeData.from(
        brightness: Brightness.light,
        fontFamily: 'Serif',
      );
      expect(t.text.body.fontFamily, 'Serif');
      expect(t.compactText.headingXL.fontFamily, 'Serif');
      expect(t.text.code.fontFamily, isNot('Serif'));
    });
  });

  group('the two layers', () {
    Future<Color?> tagInk(
      WidgetTester tester, {
      CivicStyle? style,
      CivicStyle? slot,
    }) async {
      final base = CivicThemeData.light();
      await tester.pumpWidget(
        MaterialApp(
          home: CivicTheme(
            data: base.copyWith(tagStyle: slot),
            child: Center(
              child: CivicTag(label: 'Sent', style: style),
            ),
          ),
        ),
      );
      final text = tester.widget<RichText>(
        find.descendant(
          of: find.byType(CivicTag),
          matching: find.byType(RichText),
        ),
      );
      return text.text.style?.color;
    }

    testWidgets("a part's style wins over its slot, the slot over the look", (
      tester,
    ) async {
      const mine = Color(0xFF123456);
      const theirs = Color(0xFF654321);
      final look = await tagInk(tester);
      expect(look, isNot(anyOf(mine, theirs)));
      expect(
        await tagInk(
          tester,
          slot: const CivicStyle(foreground: WidgetStatePropertyAll(theirs)),
        ),
        theirs,
      );
      expect(
        await tagInk(
          tester,
          slot: const CivicStyle(foreground: WidgetStatePropertyAll(theirs)),
          style: const CivicStyle(foreground: WidgetStatePropertyAll(mine)),
        ),
        mine,
      );
    });

    // Each of 0.3's inputs reads its own slot the same way: the slot over
    // the look, the part's style over the slot.
    for (final (name, slot, part)
        in <
          (
            String,
            CivicThemeData Function(CivicThemeData, CivicStyle),
            Widget Function(CivicStyle?),
          )
        >[
          (
            'a chip',
            (t, s) => t.copyWith(chipStyle: s),
            (s) => CivicChip(
              label: 'Open now',
              selected: true,
              onSelected: (_) {},
              style: s,
            ),
          ),
          (
            'a toggle group',
            (t, s) => t.copyWith(toggleStyle: s),
            (s) => CivicToggleGroup<String>(
              segments: const [CivicSegment(value: 'a', label: 'Drafts')],
              selected: const {'a'},
              onSelectionChanged: (_) {},
              style: s,
            ),
          ),
          (
            'a key',
            (t, s) => t.copyWith(kbdStyle: s),
            (s) => CivicKbd('Enter', style: s),
          ),
          (
            'a slider',
            (t, s) => t.copyWith(sliderStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicSlider(value: 0.5, onChanged: (_) {}, style: s),
            ),
          ),
          (
            'a rating',
            (t, s) => t.copyWith(ratingStyle: s),
            (s) => CivicRating(value: 3, onChanged: (_) {}, style: s),
          ),
          (
            'a wheel picker',
            (t, s) => t.copyWith(wheelPickerStyle: s),
            (s) => CivicWheelPicker(
              columns: (_) => [
                DesignWheelColumn(itemCount: 12, itemLabel: (i) => '$i'),
              ],
              selection: const [3],
              onChanged: (_) {},
              style: s,
            ),
          ),
          (
            'a card',
            (t, s) => t.copyWith(cardStyle: s),
            (s) => CivicCard(title: 'Permit', style: s, child: const Text('B')),
          ),
          (
            'a step indicator',
            (t, s) => t.copyWith(stepIndicatorStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicStepIndicator(
                steps: const ['One', 'Two'],
                current: 1,
                style: s,
              ),
            ),
          ),
          (
            'page marks',
            (t, s) => t.copyWith(pageDotsStyle: s),
            (s) => CivicPageDots(count: 3, index: 1, style: s),
          ),
          (
            'a carousel',
            (t, s) => t.copyWith(carouselStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicCarousel(
                semanticLabel: 'Zones',
                height: 80,
                itemCount: 2,
                itemBuilder: (_, i) => Text('$i'),
                style: s,
              ),
            ),
          ),
          (
            'a scroll area',
            (t, s) => t.copyWith(scrollAreaStyle: s),
            (s) =>
                SizedBox(width: 200, height: 100, child: _Scrolled(style: s)),
          ),
          (
            'a split view',
            (t, s) => t.copyWith(splitViewStyle: s),
            // Side by side, where its divider shows: 600 and more.
            (s) => SizedBox(
              width: 640,
              height: 100,
              child: CivicSplitView(
                first: const SizedBox(),
                second: const SizedBox(),
                style: s,
              ),
            ),
          ),
          (
            'a reorderable list',
            (t, s) => t.copyWith(reorderableListStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicReorderableList<String>(
                items: const ['A', 'B'],
                labelOf: (d) => d,
                onReorder: (_, _) {},
                style: s,
              ),
            ),
          ),
          (
            'a swipe row',
            (t, s) => t.copyWith(swipeActionsStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicSwipeActions(
                menuLabel: 'Actions',
                inSight: false,
                initiallyOpen: true,
                endActions: [
                  CivicSwipeAction(label: 'Archive', onPressed: () {}),
                ],
                style: s,
                child: const CivicListRow(title: Text('Permit')),
              ),
            ),
          ),
          (
            'a tree',
            (t, s) => t.copyWith(treeStyle: s),
            (s) => SizedBox(width: 300, child: _Tree(style: s)),
          ),
          (
            'an avatar',
            (t, s) => t.copyWith(avatarStyle: s),
            (s) => CivicAvatar(name: 'Ana Ruiz', style: s),
          ),
          (
            'a badge',
            (t, s) => t.copyWith(badgeStyle: s),
            (s) => CivicBadge(count: 3, noun: 'update', style: s),
          ),
          (
            'a picture',
            (t, s) => t.copyWith(imageStyle: s),
            (s) => SizedBox(
              width: 200,
              child: CivicImage(image: null, description: 'Map', style: s),
            ),
          ),
        ]) {
      testWidgets('$name: its style over its slot, its slot over the look', (
        tester,
      ) async {
        const theirs = CivicStyle(
          fill: WidgetStatePropertyAll(Color(0xFF654321)),
        );
        const mine = CivicStyle(
          fill: WidgetStatePropertyAll(Color(0xFF123456)),
        );
        final base = CivicThemeData.light();
        const stage = ValueKey('stage');
        Future<List<int>> picture(
          CivicThemeData data,
          CivicStyle? style,
        ) async {
          await tester.pumpWidget(
            MaterialApp(
              home: CivicTheme(
                data: data,
                child: Center(
                  child: RepaintBoundary(key: stage, child: part(style)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(stage),
          );
          return (await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData();
            image.dispose();
            return bytes!.buffer.asUint8List().toList();
          }))!;
        }

        final look = await picture(base, null);
        final bySlot = await picture(slot(base, theirs), null);
        final byStyle = await picture(slot(base, theirs), mine);
        final styleAlone = await picture(base, mine);
        expect(bySlot, isNot(look), reason: 'the slot changes the look');
        expect(byStyle, isNot(bySlot), reason: 'the style wins over the slot');
        expect(byStyle, styleAlone, reason: 'nothing of the slot is left');
      });
    }

    testWidgets('a button kind reads its own slot', (tester) async {
      final base = CivicThemeData.light();
      const pad = EdgeInsets.symmetric(horizontal: 80);
      Future<double> width(Widget button, CivicThemeData data) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CivicTheme(
              data: data,
              child: Center(child: button),
            ),
          ),
        );
        return tester.getSize(find.byType(CivicButton)).width;
      }

      Widget primary() => CivicButton(
        onPressed: () {},
        expand: false,
        child: const Text('Continue'),
      );
      Widget secondary() => CivicButton.secondary(
        onPressed: () {},
        expand: false,
        child: const Text('Continue'),
      );
      final wider = base.copyWith(
        primaryButtonStyle: const CivicStyle(
          padding: WidgetStatePropertyAll(pad),
        ),
      );
      expect(
        await width(primary(), wider),
        greaterThan(await width(primary(), base)),
      );
      expect(await width(secondary(), wider), await width(secondary(), base));
    });

    testWidgets('an icon button never stands under 48', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CivicTheme(
            data: CivicThemeData.light(),
            child: Center(
              child: CivicIconButton(
                onPressed: () {},
                semanticLabel: 'Close',
                style: const CivicStyle(
                  minimumSize: WidgetStatePropertyAll(Size.square(24)),
                ),
                icon: Icons.close,
              ),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(CivicIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets("the face reaches Flutter's own widgets under Civic", (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CivicTheme(
            data: CivicThemeData.from(
              brightness: Brightness.light,
              fontFamily: 'Serif',
            ),
            child: Builder(
              builder: (context) => Text(
                Theme.of(context).textTheme.bodyMedium?.fontFamily ?? '',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Serif'), findsOneWidget);
    });
  });

  // What opens over the page reads its slot as the inputs do: open, its
  // panel stands in the slot's fill, and the part's own style over it.
  group('the words read their slots', () {
    for (final (name, slot, part)
        in <
          (
            String,
            CivicThemeData Function(CivicThemeData, CivicStyle),
            Widget Function(CivicStyle?),
          )
        >[
          (
            'an accordion',
            (t, s) => t.copyWith(accordionStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicAccordion(
                sections: const [
                  CivicAccordionSection(title: 'Costs', child: Text('€60')),
                ],
                style: s,
              ),
            ),
          ),
          (
            'a key figure',
            (t, s) => t.copyWith(keyFigureStyle: s),
            (s) => CivicKeyFigure(label: 'Issued', value: '1,240', style: s),
          ),
        ]) {
      testWidgets('$name: its style over its slot, its slot over the look', (
        tester,
      ) async {
        const theirs = Color(0xFF654321);
        const mine = Color(0xFF123456);
        Finder inked(Color c) => find.byWidgetPredicate(
          (w) => w is RichText && w.text.style?.color == c,
        );
        final base = CivicThemeData.light();
        Future<void> show(CivicThemeData data, CivicStyle? style) async {
          await tester.pumpWidget(_page(part(style), data));
          await tester.pumpAndSettle();
        }

        const slotted = CivicStyle(foreground: WidgetStatePropertyAll(theirs));
        const own = CivicStyle(foreground: WidgetStatePropertyAll(mine));
        await show(base, null);
        expect(inked(theirs), findsNothing);
        await show(slot(base, slotted), null);
        expect(inked(theirs), findsWidgets, reason: 'the slot is read');
        await show(slot(base, slotted), own);
        expect(inked(mine), findsWidgets, reason: 'the style wins');
        expect(inked(theirs), findsNothing);
      });
    }
  });

  group('the overlays read their slots', () {
    const theirs = Color(0xFF654321);
    const mine = Color(0xFF123456);
    Finder filled(Color c) => find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == c,
    );
    const fill = CivicStyle(fill: WidgetStatePropertyAll(theirs));
    const own = CivicStyle(fill: WidgetStatePropertyAll(mine));

    for (final (name, slot, open)
        in <
          (
            String,
            CivicThemeData Function(CivicThemeData),
            Future<void> Function(WidgetTester, CivicThemeData, CivicStyle?),
          )
        >[
          (
            'a menu',
            (t) => t.copyWith(menuStyle: fill),
            (tester, data, style) async {
              final controller = MenuController();
              await tester.pumpWidget(
                _page(
                  CivicMenu<String>(
                    controller: controller,
                    style: style,
                    items: const [CivicMenuItem(value: 'a', label: 'Print')],
                    onSelected: (_) {},
                    builder: (context, anchor) => CivicButton.secondary(
                      onPressed: anchor.toggle,
                      child: const Text('Actions'),
                    ),
                  ),
                  data,
                ),
              );
              controller.open();
            },
          ),
          (
            'a popover',
            (t) => t.copyWith(popoverStyle: fill),
            (tester, data, style) async {
              final controller = MenuController();
              await tester.pumpWidget(
                _page(
                  CivicPopover(
                    controller: controller,
                    style: style,
                    content: const Text('More'),
                    builder: (context, anchor) => CivicLink(
                      onPressed: anchor.toggle,
                      child: const Text('Who counts?'),
                    ),
                  ),
                  data,
                ),
              );
              controller.open();
            },
          ),
          (
            'a bottom sheet',
            (t) => t.copyWith(sheetStyle: fill),
            (tester, data, style) async {
              await tester.pumpWidget(_page(const Text('Page'), data));
              showCivicBottomSheet<void>(
                context: tester.element(find.text('Page')),
                style: style,
                title: 'Filters',
                builder: (_) => const Text('Status'),
              ).ignore();
            },
          ),
        ]) {
      testWidgets('$name: its style over its slot, its slot over the look', (
        tester,
      ) async {
        final base = CivicThemeData.light();
        Future<void> show(CivicThemeData data, CivicStyle? style) async {
          await open(tester, data, style);
          await tester.pumpAndSettle();
        }

        await show(slot(base), null);
        expect(filled(theirs), findsWidgets, reason: 'the slot is read');
        await tester.pumpWidget(const SizedBox());
        await show(slot(base), own);
        expect(filled(mine), findsWidgets, reason: 'the style wins');
        expect(filled(theirs), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  // The waits, the charts and the action bar read their slots as the
  // inputs do. Each stands still (Reduce Motion), so its picture holds.
  group('the waits and the charts read their slots', () {
    CivicStyle fill(Color c) => CivicStyle(fill: WidgetStatePropertyAll(c));
    CivicStyle ink(Color c) =>
        CivicStyle(foreground: WidgetStatePropertyAll(c));
    CivicStyle edge(Color c) => CivicStyle(edge: WidgetStatePropertyAll(c));
    for (final (name, slot, part, style)
        in <
          (
            String,
            CivicThemeData Function(CivicThemeData, CivicStyle),
            Widget Function(CivicStyle?),
            CivicStyle Function(Color),
          )
        >[
          (
            'a spinner',
            (t, s) => t.copyWith(spinnerStyle: s),
            (s) => CivicSpinner(style: s),
            ink,
          ),
          (
            'a progress bar',
            (t, s) => t.copyWith(progressBarStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicProgressBar(label: 'Uploading', value: 0.4, style: s),
            ),
            fill,
          ),
          (
            'a meter',
            (t, s) => t.copyWith(meterStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicMeter(label: 'Days', value: 3, max: 5, style: s),
            ),
            fill,
          ),
          (
            'a skeleton',
            (t, s) => t.copyWith(skeletonStyle: s),
            (s) => SizedBox(
              width: 300,
              child: CivicSkeleton(style: s, child: const CivicSkeletonText()),
            ),
            fill,
          ),
          (
            'a line chart',
            (t, s) => t.copyWith(chartStyle: s),
            (s) => SizedBox(
              width: 400,
              child: CivicLineChart(
                title: 'Issued',
                labels: const ['Jan', 'Feb'],
                series: const [
                  CivicChartSeries('Resident', [1, 2]),
                ],
                style: s,
              ),
            ),
            edge,
          ),
          (
            'a sparkline',
            (t, s) => t.copyWith(chartStyle: s),
            (s) => CivicSparkline(
              label: 'This week',
              values: const [1, 3, 2],
              style: s,
            ),
            ink,
          ),
          (
            'a pie chart',
            (t, s) => t.copyWith(pieChartStyle: s),
            (s) => SizedBox(
              width: 600,
              child: CivicPieChart(
                title: 'Kinds',
                slices: const [CivicPieSlice('A', 1), CivicPieSlice('B', 2)],
                style: s,
              ),
            ),
            ink,
          ),
          (
            'an action bar',
            (t, s) => t.copyWith(actionBarStyle: s),
            (s) => SizedBox(
              width: 400,
              child: CivicActionBar(count: 2, actions: const [], style: s),
            ),
            fill,
          ),
        ]) {
      testWidgets('$name: its style over its slot, its slot over the look', (
        tester,
      ) async {
        final theirs = style(const Color(0xFF654321));
        final mine = style(const Color(0xFF123456));
        final base = CivicThemeData.light();
        const stage = ValueKey('stage');
        Future<List<int>> picture(CivicThemeData data, CivicStyle? s) async {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: app!,
              ),
              home: CivicTheme(
                data: data,
                child: Center(
                  child: RepaintBoundary(key: stage, child: part(s)),
                ),
              ),
            ),
          );
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(stage),
          );
          return (await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData();
            image.dispose();
            return bytes!.buffer.asUint8List().toList();
          }))!;
        }

        final look = await picture(base, null);
        final bySlot = await picture(slot(base, theirs), null);
        final byStyle = await picture(slot(base, theirs), mine);
        final styleAlone = await picture(base, mine);
        expect(bySlot, isNot(look), reason: 'the slot changes the look');
        expect(byStyle, isNot(bySlot), reason: 'the style wins over the slot');
        expect(byStyle, styleAlone, reason: 'nothing of the slot is left');
      });
    }

    testWidgets('pull to refresh: its band reads its slot', (tester) async {
      const theirs = Color(0xFF654321);
      final key = GlobalKey<CivicPullToRefreshState>();
      await tester.pumpWidget(
        MaterialApp(
          home: CivicTheme(
            data: CivicThemeData.light().copyWith(
              pullToRefreshStyle: fill(theirs),
            ),
            child: SizedBox(
              height: 300,
              child: CivicPullToRefresh(
                key: key,
                onRefresh: () =>
                    Future<void>.delayed(const Duration(seconds: 1)),
                child: ListView(children: const [Text('Rows')]),
              ),
            ),
          ),
        ),
      );
      final refreshed = key.currentState!.refresh();
      // The band opens from the first frame after the refresh starts.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration?)?.color == theirs,
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await refreshed;
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}

/// [part] on a page in [data].
Widget _page(Widget part, CivicThemeData data) => MaterialApp(
  home: CivicTheme(
    data: data,
    child: Center(child: part),
  ),
);

/// A scroll area with more than it shows, owning its controller.
class _Scrolled extends StatefulWidget {
  const _Scrolled({this.style});

  final CivicStyle? style;

  @override
  State<_Scrolled> createState() => _ScrolledState();
}

class _ScrolledState extends State<_Scrolled> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicScrollArea(
    controller: _scroll,
    style: widget.style,
    child: SingleChildScrollView(
      controller: _scroll,
      child: const SizedBox(height: 600),
    ),
  );
}

/// A tree of two rows, owning its controller.
class _Tree extends StatefulWidget {
  const _Tree({this.style});

  final CivicStyle? style;

  @override
  State<_Tree> createState() => _TreeState();
}

class _TreeState extends State<_Tree> {
  final _tree = DesignTreeController<String>(
    roots: const ['Parking', 'Bins'],
    childrenOf: (_) => const [],
  );

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicTree<String>(
    controller: _tree,
    labelOf: (s) => s,
    style: widget.style,
  );
}
