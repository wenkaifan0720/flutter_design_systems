/// The generated tokens: w1-tokens' test, with `internal/tokens/` (from
/// tools/expressive_tokens) and the chrome metrics that read it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/src/material_expressive/chrome_metrics.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/tokens.g.dart';

/// A corner's length, when it is one.
double? _dp(CornerToken corner) => switch (corner) {
  CornerDp(:final dp) => dp,
  CornerPercent() => null,
};

void main() {
  group('keys', () {
    test('every enum has the jar\'s members', () {
      expect(ExpressiveColorRole.values, hasLength(48));
      expect(ExpressiveShapeKey.values, hasLength(15));
      expect(ExpressiveTypeKey.values, hasLength(30));
      expect(ExpressiveMotionKey.values, hasLength(6));
      expect(ExpressiveElevationLevel.values.map((level) => level.dp), <double>[
        0,
        1,
        3,
        6,
        8,
        12,
      ]);
    });

    test('every shape key and type key resolves', () {
      for (final key in ExpressiveShapeKey.values) {
        expect(ShapeTokens.of(key), isA<CornersToken>());
      }
      for (final key in ExpressiveTypeKey.values) {
        expect(TypographyTokens.of(key).fontSize, greaterThan(0));
      }
      expect(
        _dp(ShapeTokens.of(ExpressiveShapeKey.cornerLarge).topStart),
        ShapeTokens.cornerValueLarge,
      );
    });
  });

  group('the chrome stands on the tokens', () {
    test('the FAB\'s corner is its shape key\'s', () {
      expect(FabBaselineTokens.containerShape, ExpressiveShapeKey.cornerLarge);
      final corners = ShapeTokens.of(FabBaselineTokens.containerShape);
      for (final corner in <CornerToken>[
        corners.topStart,
        corners.topEnd,
        corners.bottomEnd,
        corners.bottomStart,
      ]) {
        expect(_dp(corner), ExpressiveChromeMetrics.fabCornerRadius);
      }
    });

    test('the sheet\'s top corners are its shape key\'s', () {
      expect(
        SheetBottomTokens.dockedContainerShape,
        ExpressiveShapeKey.cornerExtraLargeTop,
      );
      final corners = ShapeTokens.of(SheetBottomTokens.dockedContainerShape);
      expect(_dp(corners.topStart), ExpressiveChromeMetrics.sheetCornerRadius);
      expect(_dp(corners.topEnd), ExpressiveChromeMetrics.sheetCornerRadius);
      expect(_dp(corners.bottomEnd), 0);
      expect(_dp(corners.bottomStart), 0);
    });

    test('the metrics are the pinned Compose values', () {
      expect(ExpressiveChromeMetrics.navBarHeight, 64);
      expect(ExpressiveChromeMetrics.navIconSize, 24);
      expect(ExpressiveChromeMetrics.navIndicatorWidth, 56);
      expect(ExpressiveChromeMetrics.navIndicatorHeight, 32);
      expect(ExpressiveChromeMetrics.fabSize, 56);
      expect(ExpressiveChromeMetrics.fabCornerRadius, 16);
      expect(ExpressiveChromeMetrics.fabMargin, 16);
      expect(ExpressiveChromeMetrics.margin, 16);
      expect(ExpressiveChromeMetrics.sheetCornerRadius, 28);
      expect(ExpressiveChromeMetrics.sheetHandleWidth, 32);
      expect(ExpressiveChromeMetrics.sheetHandleHeight, 4);
      expect(ExpressiveChromeMetrics.sheetHandlePadding, 22);
      expect(ExpressiveChromeMetrics.sheetPartialHeightFraction, 0.5);
      expect(ExpressiveChromeMetrics.scrimOpacity, 0.32);
    });
  });

  group('reviewed decisions', () {
    test('Compose\'s code wins where it overrides a token', () {
      // overrides.yaml: xsmall-button-padding, xsmall-button-icon-spacing,
      // text-button-content-color, fab-large-icon-size.
      expect(ButtonXSmallTokens.leadingSpace, 12);
      expect(ButtonXSmallTokens.trailingSpace, 12);
      expect(ButtonXSmallTokens.iconLabelSpace, 4);
      expect(TextButtonTokens.labelColor, ExpressiveColorRole.primary);
      expect(
        FabLargeTokens.iconSize,
        FloatingActionButtonBehavior.largeIconSize,
      );
      expect(ToggleButtonBehavior.pressedShape, 6);
    });

    test('the standard scheme keeps Compose\'s critically damped springs', () {
      final fast = StandardMotionTokens.of(ExpressiveMotionKey.fastSpatial);
      expect(fast.dampingRatio, 0.9);
      expect(fast.stiffness, 1400);
      final expressive = ExpressiveMotionTokens.of(
        ExpressiveMotionKey.fastSpatial,
      );
      expect(expressive.dampingRatio, 0.6);
      expect(expressive.stiffness, 800);
    });

    test('the DB fills what the jar lacks', () {
      expect(ConnectedButtonGroupXSmallTokens.containerHeight, 32);
      expect(ConnectedButtonGroupXLargeTokens.containerHeight, 136);
      expect(
        FabMediumTokens.containerShape,
        ExpressiveShapeKey.cornerLargeIncreased,
      );
    });
  });
}
