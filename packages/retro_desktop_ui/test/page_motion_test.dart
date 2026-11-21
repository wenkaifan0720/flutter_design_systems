// Pages change in place: a page pushed with RetroDesktopPageRoute, or a Material page route under the look's theme,
// stands in its place in the first frame and pops the same way, on every platform; nothing travels across the screen
// (the platform's own slid in from the side or zoomed). With a travel set it fades, still in its place. A raised
// window that closes as the tree it stood in goes tells nobody mid-frame. And a menu comes and goes at once.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Future<void> _app(
  WidgetTester tester,
  double width, {
  RetroDesktopThemeData? look,
  Widget home = const _Page('Documents'),
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final data = look ?? RetroDesktopThemeData.classic();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => RetroDesktopTheme(data: data, child: child!),
      home: home,
    ),
  );
}

class _Page extends StatelessWidget {
  const _Page(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xffffffff),
    child: Align(
      alignment: Alignment.topLeft,
      child: Text(name, key: ValueKey(name)),
    ),
  );
}

Rect _at(WidgetTester tester, String name) =>
    tester.getRect(find.byKey(ValueKey(name)));

NavigatorState _navigator(WidgetTester tester, String on) =>
    Navigator.of(tester.element(find.byKey(ValueKey(on))));

// Pushes [route] over Documents and pops it: in its place in the first frame, and nothing left to move after it.
Future<void> _inPlace(WidgetTester tester, Route<void> route) async {
  final home = _at(tester, 'Documents');
  unawaited(_navigator(tester, 'Documents').push(route));
  await tester.pump();
  expect(
    _at(tester, 'Project notes').topLeft,
    home.topLeft,
    reason: 'the page stands in its place in the first frame',
  );
  await tester.pump(const Duration(milliseconds: 16));
  expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nothing moves');
  expect(find.byKey(const ValueKey('Documents')), findsNothing);
  _navigator(tester, 'Project notes').pop();
  await tester.pump();
  expect(_at(tester, 'Documents'), home, reason: 'back in its place at once');
  await tester.pump(const Duration(milliseconds: 16));
  expect(find.byKey(const ValueKey('Project notes')), findsNothing);
  expect(tester.binding.hasScheduledFrame, isFalse);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('a RetroDesktopPageRoute stands in place at once and pops '
        'the same way, ${width.toInt()}', (tester) async {
      await _app(tester, width);
      await _inPlace(
        tester,
        RetroDesktopPageRoute<void>(
          builder: (context) => const _Page('Project notes'),
        ),
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('a MaterialPageRoute under the look stands in place at once, '
        '${width.toInt()}', (tester) async {
      await _app(tester, width);
      await _inPlace(
        tester,
        MaterialPageRoute<void>(
          builder: (context) => const _Page('Project notes'),
        ),
      );
    }, variant: TargetPlatformVariant.all());
  }

  test('the look gives its page change for every platform, in place and at '
      'once', () {
    const builders = retroDesktopPageTransitions;
    expect(builders.keys.toSet(), TargetPlatform.values.toSet());
    for (final b in builders.values) {
      expect(b.transitionDuration, Duration.zero);
      expect(b.reverseTransitionDuration, Duration.zero);
    }
  });

  testWidgets('an app given the theme\'s page change changes in place without '
      'the look above its navigator', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: retroDesktopPageTransitions,
          ),
        ),
        home: const _Page('Documents'),
      ),
    );
    await _inPlace(
      tester,
      MaterialPageRoute<void>(
        builder: (context) => const _Page('Project notes'),
      ),
    );
  }, variant: TargetPlatformVariant.all());

  testWidgets('with a travel set, a page fades in its place; Reduce Motion '
      'makes it instant', (tester) async {
    final look = RetroDesktopThemeData.classic().copyWith(
      // ignore: deprecated_member_use_from_same_package
      motion: const RetroDesktopMotion(
        travel: Duration(milliseconds: 200),
        leave: Duration(milliseconds: 200),
      ),
    );
    await _app(tester, 1440, look: look);
    final home = _at(tester, 'Documents');
    unawaited(
      _navigator(tester, 'Documents').push(
        RetroDesktopPageRoute<void>(
          builder: (context) => const _Page('Project notes'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('Project notes')),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    expect(_at(tester, 'Project notes').topLeft, home.topLeft);
    await tester.pumpAndSettle();
    _navigator(tester, 'Project notes').pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('Project notes')), findsNothing);

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    await _inPlace(
      tester,
      RetroDesktopPageRoute<void>(
        builder: (context) => const _Page('Project notes'),
      ),
    );
  });

  // iOS's Reduce Motion reaches dart:ui's accessibility features alone, not MediaQuery.disableAnimations (Flutter 3.47
  // sets only the first on iOS): the look reads both through ui_core 0.2.1's designReduceMotionOf.
  testWidgets('iOS\'s Reduce Motion alone stills the look\'s motion: a page '
      'set to fade stands in place, every timing is zero', (tester) async {
    const timed = RetroDesktopMotion(
      press: Duration(milliseconds: 50),
      state: Duration(milliseconds: 100),
      move: Duration(milliseconds: 150),
      raise: Duration(milliseconds: 120),
      travel: Duration(milliseconds: 200),
      leave: Duration(milliseconds: 200),
    );
    final look = RetroDesktopThemeData.classic().copyWith(
      // ignore: deprecated_member_use_from_same_package
      motion: timed,
    );
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _app(tester, 1440, look: look);
    final context = tester.element(find.byKey(const ValueKey('Documents')));
    expect(
      MediaQuery.disableAnimationsOf(context),
      isFalse,
      reason: 'only iOS\'s flag is set',
    );
    final motion = RetroDesktopMotion.of(context);
    for (final d in [
      motion.press,
      motion.state,
      motion.move,
      motion.raise,
      motion.travel,
      motion.leave,
    ]) {
      expect(d, Duration.zero);
    }
    expect(
      RetroDesktopMotion.durationOf(context, const Duration(milliseconds: 300)),
      Duration.zero,
    );
    await _inPlace(
      tester,
      RetroDesktopPageRoute<void>(
        builder: (context) => const _Page('Project notes'),
      ),
    );

    // The flag cleared, the theme's timings come back to the same context.
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    await tester.pump();
    final moving = RetroDesktopMotion.of(
      tester.element(find.byKey(const ValueKey('Documents'))),
    );
    expect(moving.travel, timed.travel);
    expect(moving.state, timed.state);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a raised window open as the tree it stood in goes tells '
      'nobody mid-frame', (tester) async {
    await _app(
      tester,
      390,
      home: const RetroDesktopWindow(
        title: 'Documents',
        child: _Page('Documents'),
      ),
    );
    unawaited(
      showRetroDesktopBottomSheet<void>(
        tester.element(find.byKey(const ValueKey('Documents'))),
        builder: (context) => const RetroDesktopBottomSheet(
          title: 'Order',
          child: Text('Two copies, bound'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Two copies, bound'), findsOne);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  // ui_core keeps a closing menu until its presence spring settles, about a quarter second; faded on it, a menu came
  // in and went over that time.
  testWidgets('a menu stands whole in its first frame and is gone in the '
      'first frame after its item is chosen; with a raise and a leave set it '
      'fades', (tester) async {
    var chosen = 0;
    final bar = Align(
      alignment: Alignment.topLeft,
      child: RetroDesktopMenuBar(
        menus: [
          RawMenuEntry(
            label: 'File',
            children: [RawMenuEntry(label: 'Find…', onPressed: () => chosen++)],
          ),
        ],
      ),
    );
    double opacity() => find
        .ancestor(of: find.text('Find…'), matching: find.byType(FadeTransition))
        .evaluate()
        .map((e) => (e.widget as FadeTransition).opacity.value)
        .fold(1.0, (a, b) => a * b);

    await _app(tester, 1440, home: bar);
    await tester.tap(find.text('File'));
    await tester.pump();
    expect(find.text('Find…'), findsOne);
    expect(opacity(), 1, reason: 'whole in its first frame');
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Find…'), findsAny);
    await tester.tap(find.text('Find…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(chosen, 1);
    expect(
      find.text('Find…'),
      findsOne,
      reason: 'ui_core keeps the panel while its spring runs out',
    );
    expect(opacity(), 0, reason: 'gone from the first frame after the choice');
    expect(find.text('Find…').hitTestable(), findsNothing);
    expect(find.semantics.byLabel('Find…'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Find…'), findsNothing);

    // An app's own motion: the panel fades in and out on ui_core's spring.
    final look = RetroDesktopThemeData.classic().copyWith(
      // ignore: deprecated_member_use_from_same_package
      motion: const RetroDesktopMotion(
        raise: Duration(milliseconds: 150),
        leave: Duration(milliseconds: 150),
      ),
    );
    await _app(tester, 1440, look: look, home: bar);
    await tester.tap(find.text('File'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacity(), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    await tester.tap(find.text('Find…'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Find…'), findsOne);
    expect(opacity(), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.text('Find…'), findsNothing);
  });
}
