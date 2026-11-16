// Fluent 2's page motion (Fluent2PageTransitionsBuilder), which its theme sets for every platform, on iOS inside
// ui_core's swipe back (DesignSwipeBackPageTransitionsBuilder): a page pushed in comes over the page it leaves, which holds still, rising from transparent as it travels at
// most 20 from the reading end (up from below for a full-screen dialog) and settling in 250 ms; popped, it runs back
// in 200 ms; with reduced motion asked for, each way is a cut. Nothing flies in from a window's width away, on a blank
// ground, with the page it left already gone.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

const _ground = Color(0xFFFFFFFF);

class _Page extends StatelessWidget {
  const _Page(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: ValueKey<String>(name),
    child: ColoredBox(
      color: _ground,
      child: SizedBox.expand(child: Center(child: Text(name))),
    ),
  );
}

Future<NavigatorState> _app(
  WidgetTester t, {
  TextDirection direction = TextDirection.ltr,
  bool reduced = false,
}) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: Directionality(
          textDirection: direction,
          child: Fluent2Theme(
            data: Fluent2ThemeData.lapis(),
            child: navigator!,
          ),
        ),
      ),
      home: const _Page('List'),
    ),
  );
  return t.state<NavigatorState>(find.byType(Navigator));
}

Offset _at(WidgetTester t, String name) =>
    t.getTopLeft(find.byKey(ValueKey<String>(name)));

double _opacity(WidgetTester t, String name) {
  var opacity = 1.0;
  for (final fade in t.widgetList<FadeTransition>(
    find.ancestor(
      of: find.byKey(ValueKey<String>(name)),
      matching: find.byType(FadeTransition),
    ),
  )) {
    opacity *= fade.opacity.value;
  }
  for (final o in t.widgetList<Opacity>(
    find.ancestor(
      of: find.byKey(ValueKey<String>(name), skipOffstage: false),
      matching: find.byType(Opacity),
    ),
  )) {
    opacity *= o.opacity;
  }
  return opacity;
}

/// Pumps to the first frame a pushed page shows: Flutter's hero controller
/// keeps a page pushed over a page offstage for the push's very first frame,
/// to measure its heroes.
Future<void> _firstShown(WidgetTester t) async {
  await t.pump();
  await t.pump();
}

// Fluent 2's push, on iOS with ui_core's swipe back round it.
Matcher _fluent2(TargetPlatform platform) => platform == TargetPlatform.iOS
    ? isA<DesignSwipeBackPageTransitionsBuilder>().having(
        (b) => b.builder,
        'builder',
        isA<Fluent2PageTransitionsBuilder>(),
      )
    : isA<Fluent2PageTransitionsBuilder>();

Route<void> _detail({bool fullscreenDialog = false}) => MaterialPageRoute<void>(
  fullscreenDialog: fullscreenDialog,
  builder: (context) => const _Page('Detail'),
);

void main() {
  for (final platform in TargetPlatform.values) {
    testWidgets('the theme sets the page motion on ${platform.name}', (
      t,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final navigator = await _app(t);
        final theme = Theme.of(navigator.context);
        expect(theme.platform, platform);
        expect(
          theme.pageTransitionsTheme.builders[platform],
          _fluent2(platform),
        );
        final route = _detail() as PageRoute<void>;
        unawaited(navigator.push(route));
        await t.pump();
        expect(route.transitionDuration, Fluent2Motion.gentle);
        expect(route.reverseTransitionDuration, Fluent2Motion.normal);
        await t.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('a push comes in from the reading end over a page that holds '
        'still, ${direction.name}', (t) async {
      final navigator = await _app(t, direction: direction);
      final end = direction == TextDirection.ltr ? 1.0 : -1.0;
      final route = _detail() as ModalRoute<void>;
      unawaited(navigator.push(route));
      await _firstShown(t);
      // The first frame it shows: transparent, 20 to the end side.
      expect(_at(t, 'Detail'), const Offset(20, 0) * end);
      expect(_opacity(t, 'Detail'), 0);
      expect(_at(t, 'List'), Offset.zero);
      var last = 20.0;
      var lastOpacity = 0.0;
      for (var ms = 25; ms <= 250; ms += 25) {
        await t.pump(const Duration(milliseconds: 25));
        final travel = _at(t, 'Detail').dx * end;
        final opacity = _opacity(t, 'Detail');
        expect(travel, inInclusiveRange(0, last), reason: 'at $ms ms');
        expect(opacity, greaterThanOrEqualTo(lastOpacity), reason: '$ms ms');
        expect(_at(t, 'Detail').dy, 0);
        // The page it leaves stands in its place, drawn, under it.
        if (ms < 250) {
          expect(find.byKey(const ValueKey('List')), findsOneWidget);
          expect(_at(t, 'List'), Offset.zero);
          expect(_opacity(t, 'List'), 1);
        }
        (last, lastOpacity) = (travel, opacity);
      }
      expect(_at(t, 'Detail'), Offset.zero);
      expect(_opacity(t, 'Detail'), 1);
      expect(route.animation!.value, 1, reason: 'in place at 250');
    });

    testWidgets('a pop runs it back in 200, ${direction.name}', (t) async {
      final navigator = await _app(t, direction: direction);
      final end = direction == TextDirection.ltr ? 1.0 : -1.0;
      unawaited(navigator.push(_detail()));
      await t.pumpAndSettle();
      final route = ModalRoute.of(
        t.element(find.byKey(const ValueKey('Detail'))),
      )!;
      navigator.pop();
      await t.pump();
      var last = 0.0;
      var lastOpacity = 1.0;
      for (var ms = 25; ms < 200; ms += 25) {
        await t.pump(const Duration(milliseconds: 25));
        final travel = _at(t, 'Detail').dx * end;
        final opacity = _opacity(t, 'Detail');
        expect(travel, inInclusiveRange(last, 20), reason: 'at $ms ms');
        expect(opacity, lessThanOrEqualTo(lastOpacity), reason: 'at $ms ms');
        expect(_at(t, 'List'), Offset.zero);
        (last, lastOpacity) = (travel, opacity);
      }
      await t.pump(const Duration(milliseconds: 25));
      expect(route.animation!.value, 0, reason: 'gone at 200');
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('Detail')), findsNothing);
      expect(_at(t, 'List'), Offset.zero);
    });
  }

  testWidgets('a full-screen dialog rises 20 from below', (t) async {
    final navigator = await _app(t);
    unawaited(navigator.push(_detail(fullscreenDialog: true)));
    await _firstShown(t);
    expect(_at(t, 'Detail'), const Offset(0, 20));
    await t.pump(const Duration(milliseconds: 100));
    expect(_at(t, 'Detail').dx, 0);
    expect(_at(t, 'Detail').dy, inExclusiveRange(0, 20));
    await t.pumpAndSettle();
    expect(_at(t, 'Detail'), Offset.zero);
  });

  test('the map covers every platform, the theme\'s own', () {
    const builders = fluent2PageTransitions;
    expect(builders.keys.toSet(), TargetPlatform.values.toSet());
    for (final platform in TargetPlatform.values) {
      expect(builders[platform], _fluent2(platform));
    }
  });

  testWidgets('an app\'s own theme given the map moves its routes the '
      'same way', (t) async {
    t.view.physicalSize = const Size(1440, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: fluent2PageTransitions,
          ),
        ),
        home: const _Page('List'),
      ),
    );
    final navigator = t.state<NavigatorState>(find.byType(Navigator));
    final route = _detail() as PageRoute<void>;
    unawaited(navigator.push(route));
    await _firstShown(t);
    expect(_at(t, 'Detail'), const Offset(20, 0));
    expect(_at(t, 'List'), Offset.zero);
    expect(route.transitionDuration, Fluent2Motion.gentle);
    await t.pump(Fluent2Motion.gentle);
    expect(_at(t, 'Detail'), Offset.zero);
  });

  testWidgets('a Fluent2Page moves the same way', (t) async {
    final pages = ValueNotifier<List<Page<void>>>([
      const Fluent2Page<void>(key: ValueKey('list'), child: _Page('List')),
    ]);
    addTearDown(pages.dispose);
    await t.pumpWidget(
      MaterialApp(
        builder: (context, _) => Fluent2Theme(
          data: Fluent2ThemeData.lapis(),
          child: ValueListenableBuilder(
            valueListenable: pages,
            builder: (context, list, _) =>
                Navigator(pages: list, onDidRemovePage: (_) {}),
          ),
        ),
      ),
    );
    pages.value = [
      ...pages.value,
      const Fluent2Page<void>(key: ValueKey('detail'), child: _Page('Detail')),
    ];
    await t.pump();
    await t.pump();
    expect(_at(t, 'Detail').dx, 20);
    expect(_at(t, 'List'), Offset.zero);
    await t.pump(Fluent2Motion.gentle);
    expect(_at(t, 'Detail'), Offset.zero);
  });

  testWidgets('with reduced motion asked for, each way is a cut', (t) async {
    final navigator = await _app(t, reduced: true);
    unawaited(navigator.push(_detail()));
    await _firstShown(t);
    expect(_at(t, 'Detail'), Offset.zero);
    expect(_opacity(t, 'Detail'), 1);
    await t.pumpAndSettle();
    navigator.pop();
    await t.pump();
    expect(_opacity(t, 'Detail'), 0);
    expect(_at(t, 'Detail'), Offset.zero);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('Detail')), findsNothing);
  });
}
