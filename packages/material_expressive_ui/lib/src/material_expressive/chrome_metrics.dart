/// The geometry Expressive's chrome stands on — the navigation bar, the
/// floating action button, the modal sheet and the screen's margin — named
/// once, so the shell, the sheet and (from wave 2) the screen and the toast
/// agree on it.
library;

import 'internal/tokens/tokens.g.dart';
import 'spacing.dart';

/// Expressive's chrome geometry, in logical pixels (dp).
abstract final class ExpressiveChromeMetrics {
  // Every value is a reference to the generated tokens (pinned Compose
  // material3 1.5.0-alpha29): a token from the jar (internal/tokens/), a
  // spacing step (spec/spacing.json) or a value Compose sets in component
  // code (behavior.yaml). Nothing here types a dp but the one window
  // breakpoint, which no Compose material3 source states (below);
  // test/tokens_test.dart holds the two corner radii to the shape keys
  // their tokens name.

  /// The flexible navigation bar's height above the system inset
  /// (`NavigationBarTokens.ContainerHeight`, which `ShortNavigationBar`
  /// takes as its height).
  static const double navBarHeight = NavigationBarTokens.containerHeight;

  /// A navigation item's icon (`NavigationBarVerticalItemTokens.IconSize`).
  static const double navIconSize = NavigationBarVerticalItemTokens.iconSize;

  /// The selected navigation item's indicator width
  /// (`NavigationBarVerticalItemTokens.ActiveIndicatorWidth`).
  static const double navIndicatorWidth =
      NavigationBarVerticalItemTokens.activeIndicatorWidth;

  /// The selected navigation item's indicator height
  /// (`NavigationBarVerticalItemTokens.ActiveIndicatorHeight`).
  static const double navIndicatorHeight =
      NavigationBarVerticalItemTokens.activeIndicatorHeight;

  /// The collapsed navigation rail's width
  /// (`NavigationRailCollapsedTokens.ContainerWidth`).
  static const double railWidth = NavigationRailCollapsedTokens.containerWidth;

  /// The narrowest window the shell stands the navigation rail in instead
  /// of the bar (CONTRACT §4.2: "rail ≥ 600dp"): Material's medium window
  /// class, androidx.window `WindowSizeClass.WIDTH_DP_MEDIUM_LOWER_BOUND`
  /// (m3.material.io, "Window size classes"). The material3 jar states no
  /// breakpoint, so it is typed here, cited.
  static const double railMinWindowWidth = 600;

  /// The narrowest window the shell stands the rail expanded in, labels
  /// beside the icons: Material's large window class (1200dp,
  /// m3.material.io, "Window size classes": "expanded navigation rail" for
  /// large and extra-large windows). Below it the rail stays collapsed, so
  /// an expanded window (840 to 1200dp) keeps its room for two panes.
  static const double expandedRailMinWindowWidth = 1200;

  /// The floating action button's side (`FabBaselineTokens.ContainerHeight`,
  /// `ContainerWidth`).
  static const double fabSize = FabBaselineTokens.containerHeight;

  /// The floating action button's corner: `FabBaselineTokens.ContainerShape`
  /// is `ShapeKeyTokens.CornerLarge`, whose corner is
  /// `ShapeTokens.CornerValueLarge`.
  static const double fabCornerRadius = ShapeTokens.cornerValueLarge;

  /// The floating action button's gap to the screen's end edge and to the
  /// bar below it (`Scaffold.kt` `FabSpacing`; behavior.yaml).
  static const double fabMargin = ScaffoldBehavior.fabSpacing;

  /// What the floating action button takes above the bar on a phone: its
  /// side and its gap to the bar ([fabSize] + [fabMargin]), part of the
  /// shell's allowance.
  static const double fabClearance = fabSize + fabMargin;

  /// The screen's side margin on a compact window (16dp, `space200`).
  static const double margin = ExpressiveSpacing.s16;

  /// A modal bottom sheet's top corners:
  /// `SheetBottomTokens.DockedContainerShape` is
  /// `ShapeKeyTokens.CornerExtraLargeTop`, whose top corners are
  /// `ShapeTokens.CornerValueExtraLarge`.
  static const double sheetCornerRadius = ShapeTokens.cornerValueExtraLarge;

  /// The drag handle's width (`SheetBottomTokens.DockedDragHandleWidth`).
  static const double sheetHandleWidth =
      SheetBottomTokens.dockedDragHandleWidth;

  /// The drag handle's height (`SheetBottomTokens.DockedDragHandleHeight`).
  static const double sheetHandleHeight =
      SheetBottomTokens.dockedDragHandleHeight;

  /// The space above and below the drag handle (`SheetDefaults.kt`
  /// `DragHandleVerticalPadding`; behavior.yaml).
  static const double sheetHandlePadding =
      SheetDefaultsBehavior.dragHandleVerticalPadding;

  /// A modal sheet at its first (partial) detent, as a share of the screen's
  /// height (`BottomSheet.kt`'s partially expanded anchor; behavior.yaml).
  static const double sheetPartialHeightFraction =
      BottomSheetBehavior.partialHeightFraction;

  /// The scrim's opacity over the page (`ScrimTokens.ContainerOpacity`).
  static const double scrimOpacity = ScrimTokens.containerOpacity;
}
