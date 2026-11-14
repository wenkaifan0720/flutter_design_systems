/// The loading family: the loading indicator's 48dp container and colours
/// from the generated tokens (plain and contained), the indeterminate
/// cycle running, the determinate value's semantics; and pull-to-refresh
/// — Compose's threshold after the drag multiplier, a short pull that
/// springs back, a refresh that holds the indicator until it completes,
/// and [ExpressivePullToRefreshState.show].
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/loading_indicator_tokens.g.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(data: const MediaQueryData(), child: child),
  ),
);

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  group('loading indicator', () {
    testWidgets('a 48dp container; contained paints primaryContainer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const Center(child: ExpressiveLoadingIndicator())),
      );
      expect(
        tester.getSize(find.byType(ExpressiveLoadingIndicator)),
        const Size(
          LoadingIndicatorTokens.containerWidth,
          LoadingIndicatorTokens.containerHeight,
        ),
      );
      expect(find.byType(DecoratedBox), findsNothing);

      await tester.pumpWidget(
        _app(const Center(child: ExpressiveLoadingIndicator(contained: true))),
      );
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ExpressiveLoadingIndicator),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (box.decoration as ShapeDecoration).color,
        _theme.colors.primaryContainer,
      );
    });

    testWidgets('the indeterminate cycle runs through all seven shapes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const Center(child: ExpressiveLoadingIndicator(contained: true))),
      );
      // Seven morphs of 650ms: one whole cycle and more.
      await _frames(
        tester,
        LoadingIndicatorBehavior.indeterminateShapes.length *
                LoadingIndicatorBehavior.morphInterval ~/
                16 +
            10,
      );
      expect(tester.takeException(), isNull);
      expect(tester.binding.hasScheduledFrame, isTrue);
    });

    testWidgets('determinate: a value, no frames scheduled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const Center(
            child: ExpressiveLoadingIndicator(
              progress: 0.5,
              semanticLabel: 'Sync',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sync')),
        matchesSemantics(label: 'Sync', value: '50%'),
      );
      handle.dispose();
    });

    testWidgets('Reduce Motion still cycles, critically damped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: ExpressiveLoadingIndicator()),
          ),
        ),
      );
      await _frames(tester, 120);
      expect(tester.takeException(), isNull);
    });
  });

  group('pull to refresh', () {
    late Completer<void> refresh;
    late int refreshes;

    Widget list() => _app(
      ExpressiveRefreshIndicator(
        onRefresh: () {
          refreshes += 1;
          refresh = Completer<void>();
          return refresh.future;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          children: <Widget>[
            for (var i = 0; i < 30; i++)
              SizedBox(height: 48, child: Text('Row $i')),
          ],
        ),
      ),
    );

    setUp(() => refreshes = 0);

    testWidgets('a pull past the threshold refreshes until done', (
      tester,
    ) async {
      await tester.pumpWidget(list());
      // The indicator travels half the drag: a 200dp pull is past the
      // 80dp threshold.
      final threshold =
          PullToRefreshBehavior.positionalThreshold /
          PullToRefreshBehavior.dragMultiplier;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Row 2')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(0, (threshold + 40) / 10));
        await tester.pump();
      }
      expect(find.byType(ExpressiveLoadingIndicator), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(refreshes, 1);
      await _frames(tester, 30);
      // Held at the threshold, cycling, while the refresh runs.
      expect(find.byType(ExpressiveLoadingIndicator), findsWidgets);
      expect(
        tester
            .state<ExpressivePullToRefreshState>(
              find.byType(ExpressiveRefreshIndicator),
            )
            .refreshing,
        isTrue,
      );
      refresh.complete();
      await _frames(tester, 60);
      expect(
        tester
            .state<ExpressivePullToRefreshState>(
              find.byType(ExpressiveRefreshIndicator),
            )
            .refreshing,
        isFalse,
      );
      expect(find.byType(ExpressiveLoadingIndicator), findsNothing);
    });

    testWidgets('a short pull springs back without refreshing', (tester) async {
      await tester.pumpWidget(list());
      await tester.drag(find.text('Row 2'), const Offset(0, 60));
      await tester.pump();
      await _frames(tester, 60);
      expect(refreshes, 0);
      expect(find.byType(ExpressiveLoadingIndicator), findsNothing);
    });

    testWidgets('show() refreshes as a pull does', (tester) async {
      await tester.pumpWidget(list());
      unawaited(
        tester
            .state<ExpressivePullToRefreshState>(
              find.byType(ExpressiveRefreshIndicator),
            )
            .show(),
      );
      await tester.pump();
      expect(refreshes, 1);
      await _frames(tester, 30);
      expect(find.byType(ExpressiveLoadingIndicator), findsWidgets);
      refresh.complete();
      await _frames(tester, 60);
      expect(find.byType(ExpressiveLoadingIndicator), findsNothing);
    });
  });
}
