/// The outline a shaped part of Expressive draws: its style's `shape`, or
/// its own outline with an app's `corners` over it.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../shape.dart';
import '../theme.dart';

/// The outline of a part whose own outline is [own] for [states]: [style]'s
/// `shape` when it gives one (drawn as given), else [own] with [style]'s
/// `corners` over it ([expressiveCornersOver]).
///
/// ```dart
/// expressiveOutline(context.expressiveTheme, const ExpressiveComponentThemeData(), const {}, context.expressiveTheme.shapes.medium)
/// ```
OutlinedBorder expressiveOutline(
  ExpressiveThemeData t,
  ExpressiveComponentThemeData style,
  Set<WidgetState> states,
  OutlinedBorder own, {
  ExpressiveOuterCorners reach = ExpressiveOuterCorners.all,
}) =>
    style.shape?.resolve(states) ??
    expressiveCornersOver(t, style.corners?.resolve(states), own, reach: reach);

/// [own] with [given] over it: each corner [given] names, on the corners
/// [reach] allows, held to [ExpressiveThemeData.shapeLimits] and drawn at
/// that step of [t]'s scale; every other corner keeps [own]'s, so a press
/// or selection morph still runs on it. Start and end follow the text
/// direction. An outline with no corners of its own to replace (a library
/// shape, a circle) stays as it is.
///
/// ```dart
/// expressiveCornersOver(context.expressiveTheme, const RawCorners(bottomStart: RawCorner.none, bottomEnd: RawCorner.none), context.expressiveTheme.shapes.medium)
/// ```
OutlinedBorder expressiveCornersOver(
  ExpressiveThemeData t,
  RawCorners? given,
  OutlinedBorder own, {
  ExpressiveOuterCorners reach = ExpressiveOuterCorners.all,
}) {
  final reached = reach.of(given);
  if (reached == null || reached.isEmpty) return own;
  final base = switch (own) {
    ExpressiveCornerBorder() => own,
    StadiumBorder(:final side) => ExpressiveCornerBorder.all(
      const ExpressiveCornerSize.fraction(.5),
      side: side,
    ),
    _ => null,
  };
  if (base == null) return own;
  final held = ExpressiveThemeData.shapeLimits.clampCorners(
    reached,
    base: const RawCorners(),
    look: 'Expressive',
  );
  ExpressiveCornerSize at(RawCorner? step, ExpressiveCornerSize kept) =>
      step == null ? kept : t.shapes.corner(_step(step)).topStart;
  return ExpressiveCornerBorder(
    side: base.side,
    topStart: at(held.topStart, base.topStart),
    topEnd: at(held.topEnd, base.topEnd),
    bottomEnd: at(held.bottomEnd, base.bottomEnd),
    bottomStart: at(held.bottomStart, base.bottomStart),
  );
}

ExpressiveCorner _step(RawCorner step) => switch (step) {
  RawCorner.none => ExpressiveCorner.none,
  RawCorner.extraSmall => ExpressiveCorner.extraSmall,
  RawCorner.small => ExpressiveCorner.small,
  RawCorner.medium => ExpressiveCorner.medium,
  RawCorner.large => ExpressiveCorner.large,
  RawCorner.extraLarge => ExpressiveCorner.extraLarge,
  RawCorner.full => ExpressiveCorner.full,
};
