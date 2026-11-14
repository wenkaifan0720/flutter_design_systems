/// The feedback family: the screen states (Cody v2's loading, error and
/// empty state tests from foundation_test.dart, ported), the banner's
/// tones and actions, and the skeleton's shapes, its absence from
/// semantics and its stillness under Reduce Motion.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child, {bool reduceMotion = false}) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: child,
    ),
  ),
);

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  group('screen states (Cody v2 foundation_test.dart)', () {
    // Cody: 'foundation enforces its closed resource and accessibility
    // floor' mounts InitialGenLoadingState, InitialGenEmptyState and
    // InitialGenErrorState in a screen under the host and expects no
    // exception; its states.dart announces loading and error.
    testWidgets('the loading, empty and error states render under the host, '
        'loading and error announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const ExpressiveLoadingState(),
                const ExpressiveEmptyState(
                  icon: ExpressiveSymbols.inbox,
                  title: 'Nothing here',
                ),
                const ExpressiveErrorState(title: 'Could not load'),
              ],
            ),
          ),
        ),
      );
      await _frames(tester, 10);
      expect(tester.takeException(), isNull);
      expect(find.text('Loading'), findsOneWidget);
      expect(find.byType(ExpressiveLoadingIndicator), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Could not load'), findsOneWidget);
      // No action without a callback.
      expect(find.bySubtype<ExpressiveButton>(), findsNothing);

      bool live(String text) {
        SemanticsNode? node = tester.getSemantics(find.text(text));
        while (node != null) {
          if (node.flagsCollection.isLiveRegion) return true;
          node = node.parent;
        }
        return false;
      }

      expect(live('Loading'), isTrue);
      expect(live('Could not load'), isTrue);
      expect(live('Nothing here'), isFalse);
      handle.dispose();
    });

    testWidgets('the error state retries; the empty state acts', (
      tester,
    ) async {
      var retried = 0;
      var acted = 0;
      await tester.pumpWidget(
        _app(
          Column(
            children: <Widget>[
              Expanded(
                child: ExpressiveErrorState(
                  title: 'Could not load',
                  message: 'Check your connection',
                  onRetry: () => retried += 1,
                ),
              ),
              Expanded(
                child: ExpressiveEmptyState(
                  icon: ExpressiveSymbols.inbox,
                  title: 'Nothing here yet',
                  body: 'Add your first plant',
                  actionLabel: 'Add one',
                  onAction: () => acted += 1,
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Check your connection'), findsOneWidget);
      expect(find.text('Add your first plant'), findsOneWidget);
      await tester.tap(
        find.ancestor(
          of: find.text('Try again'),
          matching: find.bySubtype<ExpressiveButton>(),
        ),
      );
      await tester.tap(
        find.ancestor(
          of: find.text('Add one'),
          matching: find.bySubtype<ExpressiveButton>(),
        ),
      );
      await tester.pumpAndSettle();
      expect(retried, 1);
      expect(acted, 1);
    });

    testWidgets('a wrapped state balances its lines: no word alone', (
      tester,
    ) async {
      const body =
          'Take your first reading and it will show here, with the '
          'category it falls in.';
      await tester.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 320,
              child: ExpressiveEmptyState(
                icon: ExpressiveSymbols.favorite,
                title: 'No readings yet',
                body: body,
              ),
            ),
          ),
        ),
      );
      await _frames(tester, 10);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(body));
      final lines = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: body.length),
      );
      final widest = lines.map((l) => l.right - l.left).reduce(math.max);
      expect(lines.length, greaterThan(1));
      expect(lines.last.right - lines.last.left, greaterThan(widest * 0.6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an error state under a mark leaves its glyph out', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const ExpressiveErrorState(title: 'Could not load', icon: null)),
      );
      await _frames(tester, 10);
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.byType(ExpressiveIcon), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a custom loading message and retry label', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: <Widget>[
              const Expanded(
                child: ExpressiveLoadingState(message: 'Loading plants'),
              ),
              Expanded(
                child: ExpressiveErrorState(
                  title: 'Offline',
                  retryLabel: 'Reconnect',
                  onRetry: () {},
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Loading plants'), findsOneWidget);
      expect(find.text('Reconnect'), findsOneWidget);
    });
  });

  group('banner', () {
    testWidgets('each tone paints its container; actions are text buttons', (
      tester,
    ) async {
      var tapped = 0;
      final colors = _theme.colors;
      const tones = <ExpressiveTone>[
        ExpressiveTone.neutral,
        ExpressiveTone.primary,
        ExpressiveTone.error,
      ];
      final expected = <Color>[
        colors.surfaceContainerHighest,
        colors.secondaryContainer,
        colors.errorContainer,
      ];
      for (var i = 0; i < tones.length; i++) {
        await tester.pumpWidget(
          _app(
            Center(
              child: SizedBox(
                width: 360,
                child: ExpressiveBanner(
                  icon: ExpressiveSymbols.wifi,
                  title: 'You are offline',
                  message: 'Changes sync when you reconnect.',
                  tone: tones[i],
                  actions: <ExpressiveBannerAction>[
                    ExpressiveBannerAction(
                      'Retry',
                      onPressed: () => tapped += 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final box = tester.widget<ExpressiveSurface>(
          find
              .descendant(
                of: find.byType(ExpressiveBanner),
                matching: find.byType(ExpressiveSurface),
              )
              .first,
        );
        expect(box.color, expected[i]);
        await tester.tap(
          find.ancestor(
            of: find.text('Retry'),
            matching: find.bySubtype<ExpressiveButton>(),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(tapped, tones.length);
      expect(find.bySubtype<ExpressiveButton>(), findsOneWidget);
    });
  });

  group('skeleton', () {
    testWidgets('block, circle and text lines; none reach semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExpressiveSkeleton.circle(size: 40),
                  ExpressiveSkeleton(height: 120),
                  ExpressiveSkeleton.text(lines: 3),
                ],
              ),
            ),
          ),
        ),
      );
      final skeletons = find.byType(ExpressiveSkeleton);
      expect(tester.getSize(skeletons.at(0)), const Size(40, 40));
      expect(tester.getSize(skeletons.at(1)), const Size(300, 120));
      // Three lines of body medium (20dp each).
      expect(
        tester.getSize(skeletons.at(2)).height,
        closeTo(
          3 * _theme.type.bodyMedium.fontSize! * _theme.type.bodyMedium.height!,
          0.01,
        ),
      );
      expect(
        tester.getSemantics(find.byType(Column).first),
        matchesSemantics(),
      );
      handle.dispose();
    });

    testWidgets('it pulses, and holds still under Reduce Motion', (
      tester,
    ) async {
      double opacity() => tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byType(ExpressiveSkeleton),
              matching: find.byType(FadeTransition),
            ),
          )
          .opacity
          .value;

      await tester.pumpWidget(
        _app(const Center(child: ExpressiveSkeleton(width: 100, height: 20))),
      );
      await _frames(tester, 30);
      expect(opacity(), lessThan(1));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(
        _app(
          const Center(child: ExpressiveSkeleton(width: 100, height: 20)),
          reduceMotion: true,
        ),
      );
      await _frames(tester, 5);
      expect(opacity(), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
