/// The splash (components/splash.dart): the mark on each ground, the
/// indicator running while the app restores (a loop a test pumps through
/// but never settles), the live region while restoring and nothing after,
/// the handoff into the first screen's anchor ending with the overlay gone
/// (also when the restore ends before the first frame), and the cross-fade
/// with no anchor or under Reduce Motion.
library;

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
      data: MediaQueryData(
        size: const Size(400, 800),
        disableAnimations: reduceMotion,
      ),
      child: child,
    ),
  ),
);

const Key _target = ValueKey<String>('target');

/// The first screen: a FAB-sized anchor at the bottom end, or nothing to
/// land on.
Widget _screen({bool anchor = true}) => Align(
  alignment: Alignment.bottomRight,
  child: anchor
      ? ExpressiveSplashScreenAnchor(
          corner: ExpressiveCorner.large,
          color: _theme.colors.primaryContainer,
          child: const SizedBox.square(key: _target, dimension: 56),
        )
      : const SizedBox.square(key: _target, dimension: 56),
);

Widget _splash({
  required bool restoring,
  bool anchor = true,
  bool reduceMotion = false,
  ExpressiveSplashScreenMark mark = const ExpressiveSplashScreenMark(
    wordmark: 'Fixture',
  ),
}) => _app(
  ExpressiveSplashScreen(
    restoring: restoring,
    restoringLabel: 'Restoring your session',
    mark: mark,
    child: restoring ? const SizedBox.expand() : _screen(anchor: anchor),
  ),
  reduceMotion: reduceMotion,
);

final Finder _overlay = find.byKey(ExpressiveSplashScreen.overlayKey);

/// Whether the morph is being painted.
final Finder _morph = find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_HandoffPainter',
);

/// The opacity the anchor's widget is drawn at.
double _targetOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(of: find.byKey(_target), matching: find.byType(Opacity))
          .first,
    )
    .opacity;

void main() {
  group('the mark', () {
    testWidgets('stands on the surface in primary, or full-bleed primary in '
        'onPrimary', (tester) async {
      for (final (ground, fill, ink)
          in <(ExpressiveSplashScreenGround, Color, Color)>[
            (
              ExpressiveSplashScreenGround.surface,
              _theme.colors.surface,
              _theme.colors.primary,
            ),
            (
              ExpressiveSplashScreenGround.primary,
              _theme.colors.primary,
              _theme.colors.onPrimary,
            ),
          ]) {
        await tester.pumpWidget(
          _app(ExpressiveSplashScreenMark(wordmark: 'Fixture', ground: ground)),
        );
        expect(
          tester
              .widget<ColoredBox>(
                find
                    .descendant(
                      of: find.byType(ExpressiveSplashScreenMark),
                      matching: find.byType(ColoredBox),
                    )
                    .first,
              )
              .color,
          fill,
        );
        final shape = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(ExpressiveSplashScreenSource),
            matching: find.byType(DecoratedBox),
          ),
        );
        final decoration = shape.decoration as ShapeDecoration;
        expect(decoration.color, ink);
        expect(
          decoration.shape,
          const ExpressiveMaterialShapeBorder(
            ExpressiveMaterialShape.cookie9Sided,
          ),
        );
        expect(find.text('Fixture'), findsOneWidget);
      }
    });

    testWidgets('a custom mark draws itself and hears the restoring state', (
      tester,
    ) async {
      final heard = <bool>[];
      Widget mark(bool restoring) => _app(
        ExpressiveSplashScreenMark.custom(
          restoring: restoring,
          builder: (context, restoring) {
            heard.add(restoring);
            return const SizedBox.square(dimension: 40);
          },
        ),
      );
      await tester.pumpWidget(mark(true));
      await tester.pumpWidget(mark(false));
      expect(heard, <bool>[true, false]);
      expect(find.byType(ExpressiveLoadingIndicator), findsNothing);
    });

    testWidgets('while restoring a shape mark runs the loading indicator: a '
        'loop a test pumps through but never settles', (tester) async {
      await tester.pumpWidget(_splash(restoring: true));
      expect(find.byType(ExpressiveLoadingIndicator), findsOneWidget);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(_overlay, findsOneWidget);
    });

    testWidgets('announces the restore as a live region, and nothing once '
        'handed off', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_splash(restoring: true));
      expect(
        tester.getSemantics(_overlay),
        isSemantics(label: 'Restoring your session', isLiveRegion: true),
      );
      await tester.pumpWidget(_splash(restoring: false));
      await tester.pump();
      expect(find.bySemanticsLabel('Restoring your session'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Restoring your session'), findsNothing);
      semantics.dispose();
    });
  });

  group('the handoff', () {
    testWidgets('morphs the mark into the anchor, which fades in, then the '
        'overlay unmounts', (tester) async {
      await tester.pumpWidget(_splash(restoring: true));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(_splash(restoring: false));
      await tester.pump();
      expect(_morph, findsOneWidget);
      expect(_targetOpacity(tester), 0);
      // The morph lands before the anchor's own widget shows.
      await tester.pump(const Duration(milliseconds: 100));
      expect(_targetOpacity(tester), 0);
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
      expect(_morph, findsNothing);
      expect(_targetOpacity(tester), 1);
    });

    testWidgets('a restore done before the first frame still hands off', (
      tester,
    ) async {
      await tester.pumpWidget(_splash(restoring: false));
      expect(_overlay, findsOneWidget);
      await tester.pump();
      expect(_morph, findsOneWidget);
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
    });

    testWidgets('no anchor within a few frames: the overlay cross-fades', (
      tester,
    ) async {
      await tester.pumpWidget(_splash(restoring: true, anchor: false));
      await tester.pumpWidget(_splash(restoring: false, anchor: false));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(_morph, findsNothing);
      }
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
    });

    testWidgets('a custom mark with no source cross-fades', (tester) async {
      final mark = ExpressiveSplashScreenMark.custom(
        builder: (context, restoring) => const SizedBox.square(dimension: 40),
      );
      await tester.pumpWidget(_splash(restoring: false, mark: mark));
      await tester.pump();
      expect(_morph, findsNothing);
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
    });

    testWidgets('a custom mark hands off from its source', (tester) async {
      final mark = ExpressiveSplashScreenMark.custom(
        builder: (context, restoring) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox.square(dimension: 24),
            ExpressiveSplashScreenSource(
              corner: ExpressiveCorner.extraLarge,
              color: _theme.colors.tertiaryContainer,
              child: const SizedBox.square(dimension: 64),
            ),
          ],
        ),
      );
      await tester.pumpWidget(_splash(restoring: false, mark: mark));
      await tester.pump();
      expect(_morph, findsOneWidget);
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
    });

    testWidgets('under Reduce Motion the overlay cross-fades and the anchor '
        'never hides', (tester) async {
      await tester.pumpWidget(_splash(restoring: true, reduceMotion: true));
      await tester.pumpWidget(_splash(restoring: false, reduceMotion: true));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(_morph, findsNothing);
        expect(_targetOpacity(tester), 1);
      }
      await tester.pumpAndSettle();
      expect(_overlay, findsNothing);
    });

    testWidgets('outside a splash an anchor is only its child', (tester) async {
      await tester.pumpWidget(_app(_screen()));
      expect(_targetOpacity(tester), 1);
    });
  });
}
