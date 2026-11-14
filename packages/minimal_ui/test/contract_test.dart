import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The contract emitters' behaviour: the screen's insets, the action bar,
/// the render states, the route motion switches, the field owner's swaps,
/// and the small components' edge cases.

MinimalThemeData get _light =>
    MinimalThemeData.preset('standard', Brightness.light);

Widget _app(Widget home, {MediaQueryData? media}) => MaterialApp(
  builder: (context, navigator) {
    final host = MinimalHost(
      light: _light,
      dark: MinimalThemeData.preset('standard', Brightness.dark),
      brightness: Brightness.light,
      child: navigator!,
    );
    return media == null ? host : MediaQuery(data: media, child: host);
  },
  home: home,
);

void _ignore(int _) {}

Widget _page(Widget child) => _app(
  Scaffold(
    body: Padding(padding: const EdgeInsets.all(18), child: child),
  ),
);

void main() {
  group('MinimalScaffold insets', () {
    const device = MediaQueryData(
      size: Size(390, 844),
      padding: EdgeInsets.only(top: 47, bottom: 34),
      viewPadding: EdgeInsets.only(top: 47, bottom: 34),
    );

    testWidgets('a footer docks over the device inset, the body clear of it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const MinimalScaffold(footer: Text('Footer'), body: Text('Body')),
          media: device,
        ),
      );
      final screen = tester.getSize(find.byType(Scaffold));
      final footer = tester.getRect(find.text('Footer'));
      // The footer's own 12 px band, then the home indicator's 34.
      expect(screen.height - footer.bottom, closeTo(12 + 34, 0.01));
      // The body's scroll padding reserves no device inset: the footer did.
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        (scroll.padding! as EdgeInsets).bottom,
        MinimalInsets.screen.bottom,
      );
    });

    testWidgets('a floating control reserves its allowance over the inset', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const MinimalScaffold(
            floating: SizedBox(width: 40, height: 40, child: Text('Fab')),
            body: Text('Body'),
          ),
          media: device,
        ),
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(
        (scroll.padding! as EdgeInsets).bottom,
        MinimalInsets.screen.bottom +
            34 +
            MinimalChromeMetrics.floatingAllowance,
      );
      final fab = tester.getRect(find.text('Fab'));
      final screen = tester.getSize(find.byType(Scaffold));
      expect(
        screen.height - fab.bottom,
        closeTo(34 + MinimalChromeMetrics.floatingGap, 0.01),
      );
      expect(screen.width - fab.right, MinimalChromeMetrics.gutter);
    });

    testWidgets('a nav root may not own the bottom edge', (tester) async {
      await tester.pumpWidget(
        _app(
          const MinimalShellInsets(
            allowance: 90,
            child: MinimalScaffold(footer: Text('Footer'), body: Text('Body')),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('a full-bleed body runs behind the bar and reads its height', (
      tester,
    ) async {
      late EdgeInsets seen;
      await tester.pumpWidget(
        _app(
          MinimalScaffold(
            fullBleed: true,
            scroll: false,
            topBar: const MinimalAppBar(title: 'Canvas'),
            body: Builder(
              builder: (context) {
                seen = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
          media: device,
        ),
      );
      expect(seen.top, 47 + MinimalChromeMetrics.barHeight);
      expect(tester.getTopLeft(find.byType(SizedBox).last).dy, 0);
    });
  });

  group('MinimalActionBar', () {
    testWidgets('runs its action, and announces busy without firing', (
      tester,
    ) async {
      var logged = 0;
      Widget bar({required bool busy}) => _page(
        MinimalActionBar(
          summary: '3/5',
          detail: 'Two to go',
          label: 'Log all',
          busy: busy,
          busyLabel: 'Logging…',
          onPressed: () => logged += 1,
        ),
      );
      await tester.pumpWidget(bar(busy: false));
      await tester.tap(find.text('Log all'));
      expect(logged, 1);

      final handle = tester.ensureSemantics();
      await tester.pumpWidget(bar(busy: true));
      expect(find.text('Logging…'), findsOneWidget);
      await tester.tap(find.text('Logging…'), warnIfMissed: false);
      expect(logged, 1);
      final live = find.semantics.byPredicate(
        (node) => node.flagsCollection.isLiveRegion,
      );
      expect(live, findsWidgets);
      handle.dispose();
    });

    testWidgets('stacks the summary over the action at a large text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: MediaQuery.withClampedTextScaling(
              minScaleFactor: 1.3,
              maxScaleFactor: 1.3,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: MinimalActionBar(
                  summary: '€1,284',
                  label: 'Close day',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final summary = tester.getRect(find.text('€1,284'));
      final action = tester.getRect(find.text('Close day'));
      expect(action.top, greaterThan(summary.bottom));
    });

    testWidgets('stacks under its narrow width too', (tester) async {
      await tester.pumpWidget(
        _page(
          SizedBox(
            width: MinimalActionBar.stackBelow - 20,
            child: MinimalActionBar(
              summary: '21:30',
              label: 'Create',
              onPressed: () {},
            ),
          ),
        ),
      );
      final summary = tester.getRect(find.text('21:30'));
      final action = tester.getRect(find.text('Create'));
      expect(action.top, greaterThan(summary.bottom));
    });
  });

  group('render states', () {
    testWidgets('error and empty run their one action and announce', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var retried = 0;
      var added = 0;
      await tester.pumpWidget(
        _page(
          Column(
            children: [
              SizedBox(
                height: 240,
                child: MinimalErrorState(
                  title: 'Could not sync',
                  message: 'Check your connection.',
                  onRetry: () => retried += 1,
                ),
              ),
              SizedBox(
                height: 240,
                child: MinimalEmptyState(
                  icon: LucideIcons.inbox,
                  title: 'No habits yet',
                  actionLabel: 'New habit',
                  onAction: () => added += 1,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.tap(find.text('New habit'));
      expect((retried, added), (1, 1));
      final live = find.semantics.byPredicate(
        (node) => node.flagsCollection.isLiveRegion,
      );
      expect(live, findsAtLeast(2));
      handle.dispose();
    });

    testWidgets('loading turns while motion runs and announces its message', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Widget loading() => _page(
        const SizedBox(
          height: 200,
          child: MinimalLoadingState(message: 'Loading habits'),
        ),
      );
      double turns() => tester
          .widget<RotationTransition>(
            find.descendant(
              of: find.byType(MinimalLoadingState),
              matching: find.byType(RotationTransition),
            ),
          )
          .turns
          .value;
      await tester.pumpWidget(loading());
      expect(find.semantics.byLabel(RegExp('Loading habits')), findsOne);
      expect(turns(), 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(turns(), closeTo(0.25, 0.01));
      // Under the kill-switch nothing repeats: the frame settles at once,
      // on the glyph at rest.
      MinimalMotion.animate = false;
      addTearDown(() => MinimalMotion.animate = true);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(loading());
      expect(await tester.pumpAndSettle(), 1);
      expect(turns(), 0);
      handle.dispose();
    });

    testWidgets('a loading or error page stands in the middle of the glass', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      MinimalMotion.animate = false;
      addTearDown(() => MinimalMotion.animate = true);
      final pages = <String, Widget>{
        'Loading': const MinimalLoadingState(),
        'Could not sync': MinimalErrorState(
          title: 'Could not sync',
          onRetry: () {},
        ),
      };
      for (final MapEntry(key: title, value: body) in pages.entries) {
        await tester.pumpWidget(
          _app(
            MinimalScaffold(
              topBar: const MinimalAppBar(title: 'Habits'),
              body: body,
            ),
          ),
        );
        expect(tester.getCenter(find.text(title)).dy, greaterThan(844 * 0.4));
      }
    });
  });

  group('motion switches', () {
    tearDown(() => MinimalMotion.animate = true);

    test('the route registers collapse with the kill-switch', () {
      MinimalMotion.animate = false;
      const push = MinimalPageTransitions();
      expect(push.transitionDuration, Duration.zero);
      expect(push.reverseTransitionDuration, Duration.zero);
      final fade = MinimalFadeRoute<void>(builder: (_) => const SizedBox());
      expect(fade.transitionDuration, Duration.zero);
      expect(fade.reverseTransitionDuration, Duration.zero);
      expect(MinimalBottomSheet.motion, AnimationStyle.noAnimation);
      MinimalMotion.animate = true;
      expect(push.transitionDuration, MinimalChromeMetrics.push);
      expect(fade.transitionDuration, MinimalChromeMetrics.fadeIn);
    });

    testWidgets('the platform\'s reduce-motion setting stills them too', (
      tester,
    ) async {
      late bool still;
      late AnimationStyle sheet;
      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                still = context.minimalStill;
                sheet = MinimalBottomSheet.motionOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(still, isTrue);
      expect(sheet, AnimationStyle.noAnimation);
    });

    testWidgets('a fade route replaces the page in place and pops back', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => MinimalScaffold(
              body: MinimalButton(
                'Inbox',
                onPressed: () => Navigator.of(context).push(
                  MinimalFadeRoute<void>(
                    builder: (_) =>
                        const MinimalScaffold(body: Text('Inbox page')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Inbox'));
      await tester.pump();
      await tester.pump(MinimalChromeMetrics.fadeIn ~/ 2);
      // Mid-fade the page is where it lands: no slide.
      final mid = tester.getTopLeft(find.text('Inbox page'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Inbox page')), mid);
      Navigator.of(tester.element(find.text('Inbox page'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Inbox page'), findsNothing);
    });

    testWidgets('the bar derives its exit: none on a root, a back that pops '
        'on a pushed page', (tester) async {
      Widget? rootExit;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              rootExit = MinimalAppBar.autoLeading(context);
              return MinimalScaffold(
                topBar: const MinimalAppBar(title: 'Habits'),
                body: MinimalButton(
                  'Open',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MinimalScaffold(
                        topBar: MinimalAppBar(parent: 'Habits', title: 'Run'),
                        body: Text('Run page'),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      expect(rootExit, isNull);
      expect(find.bySemanticsLabel('Back'), findsNothing);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Run page'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Run page'), findsNothing);
    });
  });

  group('field ownership', () {
    testWidgets('a controller swapped in and out keeps the text and listens', (
      tester,
    ) async {
      final external = TextEditingController(text: 'External');
      addTearDown(external.dispose);
      Widget field(TextEditingController? c) =>
          _page(MinimalTextField(label: 'Name', controller: c));

      await tester.pumpWidget(field(null));
      await tester.enterText(find.byType(EditableText), 'Owned');
      await tester.pumpWidget(field(external));
      expect(find.text('External'), findsOneWidget);
      // The field still rebuilds on the new controller's edits.
      external.text = 'Edited';
      await tester.pump();
      expect(find.text('Edited'), findsOneWidget);
      // Back to owning one: it carries what the caller's held.
      await tester.pumpWidget(field(null));
      expect(find.text('Edited'), findsOneWidget);
    });

    testWidgets('a focus node swapped in takes the field\'s focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      Widget field(FocusNode? f) =>
          _page(MinimalSearchField(hint: 'Search', focusNode: f));
      await tester.pumpWidget(field(null));
      await tester.pumpWidget(field(node));
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });

    testWidgets('a tap anywhere on an input row focuses its field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(const MinimalInputRow(label: 'Name', hint: 'Stretch')),
      );
      final row = tester.getRect(find.byType(MinimalInputRow));
      expect(row.height, greaterThanOrEqualTo(MinimalLayout.minHitTarget));
      // On the label, and in the row's padding under the field.
      for (final point in [
        row.centerLeft + const Offset(8, 0),
        row.bottomRight - const Offset(20, 3),
      ]) {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tester.tapAt(point);
        await tester.pump();
        final editable = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        expect(editable.widget.focusNode.hasFocus, isTrue, reason: '$point');
      }
    });
  });

  group('small components', () {
    testWidgets('an empty breadcrumb prints nothing', (tester) async {
      await tester.pumpWidget(_page(const MinimalBreadcrumb(crumbs: [])));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(MinimalBreadcrumb)), Size.zero);
    });

    testWidgets('a counter changed mid-roll rolls on to the new value', (
      tester,
    ) async {
      Widget counter(int v) => _page(MinimalCounter(v));
      await tester.pumpWidget(counter(2));
      await tester.pumpWidget(counter(3));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(counter(4));
      await tester.pump(const Duration(milliseconds: 11));
      // The cancelled 2→3 roll must not snap the 3→4 roll to its end.
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('3'), findsNothing);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('a long sheet scope ellipsizes instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          const MinimalBottomSheet(
            title: 'New habit',
            subtitle: 'The evening routine team, north studio, second floor',
            child: SizedBox(height: 40),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('New habit'), findsOneWidget);
    });

    testWidgets('a stacked sheet footer keeps the accessory at the start', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          SizedBox(
            width: 300,
            child: MinimalBottomSheet(
              title: 'New habit',
              accessory: const Text('Create another habit after this one'),
              leading: const MinimalSheetAction('Cancel'),
              trailing: const MinimalSheetAction(
                'Create habit',
                isDefaultAction: true,
              ),
              child: const SizedBox(height: 20),
            ),
          ),
        ),
      );
      final card = tester.getRect(find.byType(MinimalBottomSheet));
      final accessory = tester.getRect(
        find.text('Create another habit after this one'),
      );
      final create = tester.getRect(find.text('Create habit'));
      expect(create.top, greaterThan(accessory.bottom));
      expect(accessory.left - card.left, lessThan(30));
      expect(card.right - create.right, lessThan(40));
    });

    testWidgets('a glyph-only tab still says what it is', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _page(
          const MinimalNavigationBar(
            items: [
              MinimalNavItem(LucideIcons.calendarCheck, 'Today'),
              MinimalNavItem.iconOnly(
                LucideIcons.search,
                semanticLabel: 'Search',
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: _ignore,
          ),
        ),
      );
      expect(find.semantics.byLabel('Search'), findsOne);
      handle.dispose();
    });

    testWidgets('only the sorted column prints a direction', (tester) async {
      Widget table(int? sort) => _page(
        MinimalTable(
          columns: const [
            MinimalColumn('#', width: 40, mono: true, sortable: true),
            MinimalColumn('Customer'),
            MinimalColumn('Due', width: 56, numeric: true, sortable: true),
          ],
          sortColumn: sort,
          onSort: (_, _) {},
          rows: const [
            MinimalTableRow([
              MinimalCell('1047'),
              MinimalCell('Hanna Berg'),
              MinimalCell('09:30'),
            ]),
          ],
        ),
      );
      await tester.pumpWidget(table(null));
      expect(find.byType(MinimalIcon), findsNothing);
      await tester.pumpWidget(table(2));
      final glyphs = tester.widgetList<MinimalIcon>(find.byType(MinimalIcon));
      expect(glyphs.map((g) => g.icon), [LucideIcons.arrowUp]);
    });

    testWidgets('one toast stands at a time, above the keyboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: MinimalScaffold(
              body: Builder(
                builder: (context) => MinimalButton(
                  'Go',
                  onPressed: () {
                    showMinimalSnackBar(context, 'First');
                    showMinimalSnackBar(context, 'Second');
                  },
                ),
              ),
            ),
          ),
          media: const MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      final screen = tester.getSize(find.byType(MaterialApp));
      expect(
        screen.height - tester.getRect(find.text('Second')).bottom,
        greaterThan(300),
      );
      await tester.pump(MinimalChromeMetrics.toast);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('a toast card renders on its own, its action live', (
      tester,
    ) async {
      var undone = 0;
      await tester.pumpWidget(
        _page(
          MinimalSnackBar(
            'Habit archived',
            icon: LucideIcons.archive,
            actionLabel: 'Undo',
            onAction: () => undone += 1,
          ),
        ),
      );
      await tester.tap(find.text('Undo'));
      expect(undone, 1);
      final undo = tester.widget<Text>(find.text('Undo'));
      expect(undo.style?.color, _light.primaryInk);
    });
  });
}
