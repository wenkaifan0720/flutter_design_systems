/// Page transitions on every platform, without a router: an
/// [ExpressivePage] on a plain `Navigator` pushes with fade-forwards
/// everywhere but iOS (the web on a Mac reads macOS: a page never flies in
/// across the window), and the host's theme names the same push for an
/// app's own page routes on every platform, so none falls back to Flutter's
/// default. Each frame is held to AOSP's activity transition (android-37.2
/// `activity_{open,close}_{enter,exit}.xml`), as page_test.dart holds a
/// go_router stack.
library;

import 'dart:async' show unawaited;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

/// AOSP: `android:fromXDelta="96dp"`, `android:duration="450"`.
const double _travel = 96;
const int _clockMs = 450;

/// AOSP `activity_open_enter`: alpha 0 → 1 over 83 ms after 50 ms.
const Interval _openFade = Interval(50 / 450, 133 / 450);

/// AOSP `@interpolator/fast_out_extra_slow_in`.
const Curve _travelCurve = Curves.easeInOutCubicEmphasized;

/// A desktop window, where a full-width slide would cross 1440dp.
const Size _screen = Size(1440, 900);

const ValueKey<String> _rootKey = ValueKey<String>('page:root');
const ValueKey<String> _detailKey = ValueKey<String>('page:detail');

double _opacityOver(WidgetTester tester, Finder page) => tester
    .widget<Opacity>(
      find.ancestor(of: page, matching: find.byType(Opacity)).first,
    )
    .opacity;

/// A root and, once pushed, a detail: two [ExpressivePage]s on a plain
/// [Navigator], the detail removed again when it pops.
class _Stack extends StatefulWidget {
  const _Stack();

  @override
  State<_Stack> createState() => _StackState();
}

class _StackState extends State<_Stack> {
  bool _pushed = false;

  void push() => setState(() => _pushed = true);

  @override
  Widget build(BuildContext context) => Navigator(
    pages: <Page<void>>[
      const ExpressivePage<void>(
        key: ValueKey<String>('root'),
        child: SizedBox.expand(key: _rootKey),
      ),
      if (_pushed)
        const ExpressivePage<void>(
          key: ValueKey<String>('detail'),
          child: SizedBox.expand(key: _detailKey),
        ),
    ],
    onDidRemovePage: (page) {
      if (page.key == const ValueKey<String>('detail')) {
        setState(() => _pushed = false);
      }
    },
  );
}

Future<void> _mountStack(WidgetTester tester) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ExpressiveHost(child: app!),
      home: const _Stack(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'an ExpressivePage on a plain navigator pushes with fade-forwards, held '
    'to AOSP at 0/25/50/100 %, and pops by the reverse',
    (tester) async {
      await _mountStack(tester);
      tester.state<_StackState>(find.byType(_Stack)).push();
      await tester.pump();
      final route = ModalRoute.of(tester.element(find.byKey(_detailKey)))!;
      expect(route.transitionDuration, ExpressivePage.fadeForwardsDuration);
      for (final t in <double>[0, 0.25, 0.5, 1]) {
        if (t > 0) {
          final previous = t == 0.25 ? 0 : (t == 0.5 ? 0.25 : 0.5);
          await tester.pump(
            Duration(microseconds: ((t - previous) * _clockMs * 1000).round()),
          );
        }
        final eased = _travelCurve.transform(t);
        final detail = tester.getRect(find.byKey(_detailKey));
        expect(
          detail.left,
          moreOrLessEquals(_travel * (1 - eased)),
          reason: '$t',
        );
        expect(detail.size, _screen);
        expect(
          _opacityOver(tester, find.byKey(_detailKey)),
          moreOrLessEquals(_openFade.transform(t)),
          reason: '$t',
        );
        if (t < 1) {
          final root = tester.getRect(find.byKey(_rootKey));
          expect(root.left, moreOrLessEquals(-_travel * eased), reason: '$t');
        }
      }
      await tester.pumpAndSettle();

      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: _clockMs ~/ 2));
      final back = _travelCurve.flipped.transform(0.5);
      expect(
        tester.getRect(find.byKey(_detailKey)).left,
        moreOrLessEquals(_travel * (1 - back)),
      );
      expect(
        tester.getRect(find.byKey(_rootKey)).left,
        moreOrLessEquals(-_travel * back),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_detailKey), findsNothing);
      expect(tester.getRect(find.byKey(_rootKey)), Offset.zero & _screen);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.all(
      excluding: <TargetPlatform>{TargetPlatform.iOS},
    ),
  );

  testWidgets(
    'iOS: an ExpressivePage still slides in from the trailing edge, on the '
    'Cupertino clock',
    (tester) async {
      await _mountStack(tester);
      tester.state<_StackState>(find.byType(_Stack)).push();
      await tester.pump();
      final route = ModalRoute.of(tester.element(find.byKey(_detailKey)))!;
      expect(route.transitionDuration, ExpressivePage.cupertinoDuration);
      expect(tester.getRect(find.byKey(_detailKey)).left, _screen.width);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_detailKey)), Offset.zero & _screen);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    "the host's theme names a push for every platform, the look's own "
    'where Flutter would fall back to its default',
    (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ExpressiveHost(child: app!),
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final builders = theme.pageTransitionsTheme.builders;
      expect(builders.keys.toSet(), TargetPlatform.values.toSet());
      expect(
        builders[TargetPlatform.iOS],
        isA<CupertinoPageTransitionsBuilder>(),
      );
      expect(
        builders[TargetPlatform.android],
        isA<PredictiveBackPageTransitionsBuilder>(),
      );
      for (final platform in <TargetPlatform>[
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          builders[platform],
          isA<ExpressivePageTransitionsBuilder>(),
          reason: '$platform',
        );
      }
      expect(
        const ExpressivePageTransitionsBuilder().transitionDuration,
        ExpressivePage.fadeForwardsDuration,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "an app's own MaterialPageRoute pushes and pops as an ExpressivePage "
    'does, held to AOSP at 0/25/50/100 %',
    (tester) async {
      tester.view.physicalSize = _screen;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, app) => ExpressiveHost(child: app!),
          home: const SizedBox.expand(key: _rootKey),
        ),
      );
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const SizedBox.expand(key: _detailKey),
          ),
        ),
      );
      // The app's HeroController stands a pushed page off stage for its first
      // frame: the frame the page appears in is the push's 0 %.
      while (find.byKey(_detailKey).evaluate().isEmpty) {
        await tester.pump();
      }
      final route = ModalRoute.of(tester.element(find.byKey(_detailKey)))!;
      expect(route.transitionDuration, ExpressivePage.fadeForwardsDuration);
      for (final t in <double>[0, 0.25, 0.5, 1]) {
        if (t > 0) {
          final previous = t == 0.25 ? 0 : (t == 0.5 ? 0.25 : 0.5);
          await tester.pump(
            Duration(microseconds: ((t - previous) * _clockMs * 1000).round()),
          );
        }
        final eased = _travelCurve.transform(t);
        final detail = tester.getRect(find.byKey(_detailKey));
        expect(
          detail.left,
          moreOrLessEquals(_travel * (1 - eased)),
          reason: '$t',
        );
        expect(detail.size, _screen);
        expect(
          _opacityOver(tester, find.byKey(_detailKey)),
          moreOrLessEquals(_openFade.transform(t)),
          reason: '$t',
        );
        if (t < 1) {
          // The page beneath travels 96dp the other way, never further.
          final root = tester.getRect(find.byKey(_rootKey));
          expect(root.left, moreOrLessEquals(-_travel * eased), reason: '$t');
        }
      }
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_detailKey)), Offset.zero & _screen);

      // The pop is the push reversed: half way, the page stands 96dp less
      // the eased half from home, the page beneath on its way back.
      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: _clockMs ~/ 2));
      final back = _travelCurve.flipped.transform(0.5);
      expect(
        tester.getRect(find.byKey(_detailKey)).left,
        moreOrLessEquals(_travel * (1 - back)),
      );
      expect(
        tester.getRect(find.byKey(_rootKey)).left,
        moreOrLessEquals(-_travel * back),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_detailKey), findsNothing);
      expect(tester.getRect(find.byKey(_rootKey)), Offset.zero & _screen);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    }),
  );
}
