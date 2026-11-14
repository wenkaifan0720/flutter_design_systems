import 'dart:io';
import 'dart:ui' show SemanticsAction, SemanticsRole, Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';
import 'styled_controls_test.dart' show mount, pixel;

void main() {
  setUpAll(loadNeumorphicFonts);
  final styled = <String, Widget Function(NeumorphicStyle?)>{
    'view tabs': (style) => NeumorphicTabBar(
      tabs: const ['Home', 'Week'],
      style: style,
      onChanged: (_) {},
    ),
    'navigation bar': (style) => NeumorphicNavigationBar(
      style: style,
      items: const [
        NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
        NeumorphicNavItem(label: 'Week', icon: NeumorphicGlyphs.calendar),
      ],
      onDestinationSelected: (_) {},
    ),
    'navigation drawer': (style) => NeumorphicNavigationDrawer(
      style: style,
      items: const [
        NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
        NeumorphicNavItem(label: 'Week', icon: NeumorphicGlyphs.calendar),
      ],
      onDestinationSelected: (_) {},
    ),
  };
  for (final entry in styled.entries) {
    testWidgets('${entry.key} resolves destination state and local style', (
      tester,
    ) async {
      final theme = NeumorphicThemeData.porcelain().copyWith(
        segmentedButtonTheme: NeumorphicStyle(
          fill: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.pressed) ? Colors.blue : Colors.red,
          ),
          overlay: const WidgetStatePropertyAll(Colors.transparent),
        ),
      );
      await mount(tester, entry.value(null), theme);
      expect(await pixel(tester), Colors.red.toARGB32());
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Home')),
      );
      await tester.pumpAndSettle();
      expect(await pixel(tester), Colors.blue.toARGB32());
      await gesture.up();
      await tester.pumpAndSettle();
      expect(await pixel(tester), Colors.red.toARGB32());
      await mount(
        tester,
        entry.value(
          const NeumorphicStyle(fill: WidgetStatePropertyAll(Colors.green)),
        ),
        theme,
      );
      expect(await pixel(tester), Colors.green.toARGB32());
    });
  }
  testWidgets(
    'a tab keeps its role, label, selected state and action together',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          neumorphicApp(
            NeumorphicTabBar(
              tabs: const ['Overview', 'Activity'],
              selectedIndex: 1,
              onChanged: (_) {},
            ),
          ),
        );
        final data = tester
            .getSemantics(find.bySemanticsLabel('Activity'))
            .getSemanticsData();
        expect(data.role, SemanticsRole.tab);
        expect(data.flagsCollection.isSelected, Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      } finally {
        semantics.dispose();
      }
    },
  );
  test('only the catalog shell adapter imports the router', () {
    final library = Directory('lib/src/neumorphism');
    final files = library.listSync(recursive: true).whereType<File>();
    // Extraction rewrites this root to lib/src and leaves the router adapter out.
    final packaged = library.path.startsWith('lib/src/');
    expect(
      files
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                f.readAsStringSync().contains('package:go_router/'),
          )
          .map((f) => f.uri.pathSegments.last),
      packaged ? <String>[] : ['shell.dart'],
    );
    expect(
      File('lib/src/neumorphism/chrome.dart').readAsStringSync(),
      isNot(contains("design_kit/routing.dart")),
    );
  });
  for (final direction in TextDirection.values) {
    testWidgets(
      'view tabs rove, wrap and retain one Tab stop in ${direction.name}',
      (tester) async {
        var selected = 0;
        await tester.pumpWidget(
          neumorphicApp(
            StatefulBuilder(
              builder: (context, setState) => NeumorphicTabBar(
                tabs: const ['Overview', 'Activity', 'Details'],
                selectedIndex: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
            direction: direction,
          ),
        );
        tester
            .widgetList<NeumorphicTap>(find.byType(NeumorphicTap))
            .first
            .focusNode!
            .requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await tester.pumpAndSettle();
        expect(selected, 1);
        expect(
          tester
              .widgetList<NeumorphicTap>(find.byType(NeumorphicTap))
              .where((w) => !w.focusNode!.skipTraversal)
              .length,
          1,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pumpAndSettle();
        expect(selected, 2);
        await tester.sendKeyEvent(
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await tester.pumpAndSettle();
        expect(selected, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('drawer destination callbacks and short large-text layout', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      neumorphicApp(
        Center(
          child: SizedBox(
            height: 180,
            width: 280,
            child: NeumorphicNavigationDrawer(
              items: const [
                NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
                NeumorphicNavItem(
                  label: 'Activity',
                  icon: NeumorphicGlyphs.check,
                ),
              ],
              header: const Text(longLine),
              footer: const Text(longLine),
              onDestinationSelected: (v) => selected = v,
            ),
          ),
        ),
        textScale: 2,
      ),
    );
    await tester.ensureVisible(find.text('Activity'));
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('page marks announce and activate their positions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var selected = 0;
      await tester.pumpWidget(
        neumorphicApp(
          NeumorphicPageDots(
            count: 4,
            selectedIndex: 0,
            label: 'Tour',
            onChanged: (v) => selected = v,
          ),
        ),
      );
      final last = find.bySemanticsLabel('Tour, 4 of 4');
      expect(last, findsOneWidget);
      await tester.tap(last);
      expect(selected, 3);
    } finally {
      semantics.dispose();
    }
  });
  for (final direction in TextDirection.values) {
    testWidgets(
      'compact page marks adjust by pointer and arrows ${direction.name}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final selected = <int>[];
          await tester.pumpWidget(
            neumorphicApp(
              NeumorphicPageDots(
                count: 3,
                selectedIndex: 1,
                label: 'Tour',
                individualTargets: false,
                onChanged: selected.add,
              ),
              direction: direction,
            ),
          );
          final target = find.bySemanticsLabel('Tour');
          final rect = tester.getRect(target);
          expect(rect.width, inInclusiveRange(48, 64));
          expect(rect.height, greaterThanOrEqualTo(48));
          final before = Offset(
            direction == TextDirection.ltr ? rect.left + 2 : rect.right - 2,
            rect.center.dy,
          );
          final after = Offset(
            rect.left + rect.right - before.dx,
            rect.center.dy,
          );
          await tester.tapAt(after);
          await tester.tapAt(before);
          expect(selected, [2, 0]);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          await tester.sendKeyEvent(
            direction == TextDirection.ltr
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft,
          );
          expect(selected, [2, 0, 2]);
          final data = tester.getSemantics(target).getSemanticsData();
          expect(data.value, '2 of 3');
          expect(data.hasAction(SemanticsAction.increase), isTrue);
          expect(data.hasAction(SemanticsAction.decrease), isTrue);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
  testWidgets('page routes update their child and honor reduced motion', (
    tester,
  ) async {
    var label = 'First';
    late StateSetter update;
    await tester.pumpWidget(
      neumorphicApp(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Navigator(
                pages: [
                  NeumorphicPage<void>(
                    key: const ValueKey('page'),
                    child: Text(label),
                  ),
                ],
                onDidRemovePage: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.text('First')))!;
    expect(route.transitionDuration, Duration.zero);
    update(() => label = 'Second');
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First'), findsNothing);
  });
  check(
    'view tabs with long text',
    () => NeumorphicTabBar(
      tabs: const [longLine, long, 'Details'],
      onChanged: (_) {},
    ),
  );
  check(
    'long run of page dots',
    () => NeumorphicPageDots(
      count: 20,
      selectedIndex: 5,
      label: 'Pages',
      onChanged: (_) {},
    ),
  );
  check(
    'many steps in a narrow column',
    () => const NeumorphicStepProgress(
      count: 120,
      currentStep: 80,
      name: longLine,
    ),
  );
}
