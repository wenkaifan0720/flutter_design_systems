// A page change in this look, on every platform: a route the app pushes fades up with a 16 px step from the reading end
// over the look's travel, the page under it still, and a pop runs it back over the look's leave. No platform's own
// slide or zoom: a page never flies in from the screen's edge. Reduce Motion cuts it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

const _second = Key('second');

Future<NavigatorState> _app(
  WidgetTester tester, {
  bool still = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      // The look above the app's navigator, as NeumorphicHost puts it: the routes the app pushes are under it.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: Directionality(
          textDirection: direction,
          child: NeumorphicTheme(
            data: NeumorphicThemeData.porcelain(),
            child: child!,
          ),
        ),
      ),
      home: const Text('first'),
    ),
  );
  return navigator.currentState!;
}

double _left(WidgetTester tester) => tester.getTopLeft(find.byKey(_second)).dx;

double _opacity(WidgetTester tester) {
  final fades = find.ancestor(
    of: find.byKey(_second),
    matching: find.byType(FadeTransition),
  );
  var o = 1.0;
  for (final e in fades.evaluate()) {
    o *= (e.widget as FadeTransition).opacity.value;
  }
  return o;
}

/// A pushed route stands offstage for its first frame, while the HeroController measures it: its first frame on stage
/// is the next, still at 0 ms.
Future<void> _onStage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

Route<void> _route() => MaterialPageRoute<void>(
  builder: (context) => const SizedBox.expand(key: _second),
);

void main() {
  test(
    'the theme and the const map give the page change for every platform',
    () {
      for (final builders in [
        NeumorphicThemeData.porcelain().pageTransitionBuilders,
        neumorphicPageTransitions,
      ]) {
        for (final platform in TargetPlatform.values) {
          expect(builders[platform], isNotNull, reason: '$platform');
          expect(
            builders[platform]!.transitionDuration,
            const NeumorphicMotion().travel,
          );
          expect(
            builders[platform]!.reverseTransitionDuration,
            const NeumorphicMotion().leave,
          );
        }
      }
    },
  );

  testWidgets('an app that lists the builders, its theme below its navigator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: neumorphicPageTransitions,
          ),
        ),
        home: NeumorphicTheme(
          data: NeumorphicThemeData.porcelain(),
          child: const Text('first'),
        ),
      ),
    );
    navigator.currentState!.push(_route());
    await _onStage(tester);
    expect(_left(tester), inInclusiveRange(15, 16.01));
    await tester.pumpAndSettle();
    expect(_left(tester), 0);
  });

  // On every platform: macOS, Windows, Linux and the web (which reads the host's) never fall back to the default.
  testWidgets(
    'a pushed page steps 16 px and fades up; a pop runs it back',
    variant: TargetPlatformVariant.all(),
    (tester) async {
      final navigator = await _app(tester);
      navigator.push(_route());
      await _onStage(tester);
      final lefts = <double>[], opacities = <double>[];
      for (var ms = 0; ms <= 280; ms += 40) {
        lefts.add(_left(tester));
        opacities.add(_opacity(tester));
        // The page under it never moves (it goes offstage once the change ends, at 280).
        if (ms < 280) expect(tester.getTopLeft(find.text('first')).dx, 0);
        await tester.pump(const Duration(milliseconds: 40));
      }
      // From the reading end, a step, never the screen's edge; still at the end.
      expect(lefts.first, inInclusiveRange(15, 16.01));
      for (var i = 1; i < lefts.length; i++) {
        expect(lefts[i], lessThanOrEqualTo(lefts[i - 1]));
        expect(opacities[i], greaterThanOrEqualTo(opacities[i - 1]));
      }
      await tester.pumpAndSettle();
      expect(_left(tester), 0);
      expect(_opacity(tester), 1);
      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(_left(tester), inExclusiveRange(0, 16));
      expect(_opacity(tester), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 61));
      await tester.pump();
      expect(find.byKey(_second), findsNothing);
    },
  );

  testWidgets('a router\'s NeumorphicPage changes the same way', (
    tester,
  ) async {
    final navigator = await _app(tester);
    navigator.push(
      const NeumorphicPage<void>(child: SizedBox.expand(key: _second))
          .createRoute(navigator.context),
    );
    await _onStage(tester);
    expect(_left(tester), inInclusiveRange(15, 16.01));
    expect(_opacity(tester), lessThan(.05));
    await tester.pump(const NeumorphicMotion().travel);
    await tester.pump();
    expect(_left(tester), 0);
    expect(_opacity(tester), 1);
  });

  testWidgets('right to left, the step comes from the left', (tester) async {
    final navigator = await _app(tester, direction: TextDirection.rtl);
    navigator.push(_route());
    await _onStage(tester);
    expect(_left(tester), inInclusiveRange(-16.01, -15));
    await tester.pumpAndSettle();
    expect(_left(tester), 0);
  });

  testWidgets('under Reduce Motion the page is in place at once', (
    tester,
  ) async {
    final navigator = await _app(tester, still: true);
    navigator.push(_route());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(_left(tester), 0);
    expect(_opacity(tester), 1);
  });
}
