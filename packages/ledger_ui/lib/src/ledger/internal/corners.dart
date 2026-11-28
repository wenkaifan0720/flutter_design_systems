/// The corners a shaped part of Ledger draws, as a box's radius.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'styled.dart';

/// [step] on every corner of [t]'s scale, as a box's radius: a part that
/// takes no style of its own (a grabber, an option's paper). [RawCorner.full]
/// is round at any height, at most the scale's `fullMaxRadius` when it gives
/// one.
///
/// ```dart
/// ledgerStep(context.ledgerTheme, RawCorner.medium)
/// ```
BorderRadius ledgerStep(LedgerThemeData t, RawCorner step) {
  final scale = t.shapeScheme.corners;
  return BorderRadius.all(
    step == RawCorner.full
        ? Radius.circular(scale.fullMaxRadius ?? _round)
        : _radius(scale, step),
  );
}

/// The corners of a part whose own corners take [step], as a box's radius:
/// its style's `shape` when it gives one (that outline's corners, drawn as
/// given), else its style's `corners` over [step] on every corner, held to
/// [LedgerThemeData.shapeLimits], on [t]'s scale. Start and end follow the
/// text direction. An app's corners reach the start corners only with
/// [start], the end ones only with [end] and the bottom ones only with
/// [bottom]: a face joined to another at one side (a split button's halves,
/// a sheet's foot on the screen's edge) keeps its joined corners its own.
///
/// ```dart
/// ledgerRadius(t, LedgerStyleOf([style, t.components.slip], states), RawCorner.medium)
/// ```
BorderRadiusGeometry ledgerRadius(
  LedgerThemeData t,
  RawStyleOf so,
  RawCorner step, {
  bool start = true,
  bool end = true,
  bool bottom = true,
}) => ledgerRadiusOf(
  t,
  so,
  RawCorners.all(step),
  start: start,
  end: end,
  bottom: bottom,
);

/// As [ledgerRadius], for a part whose own corners are [base] (a receipt's
/// top two, say).
BorderRadiusGeometry ledgerRadiusOf(
  LedgerThemeData t,
  RawStyleOf so,
  RawCorners base, {
  bool start = true,
  bool end = true,
  bool bottom = true,
}) {
  final shape = so.shape;
  if (shape != null) return ledgerCorners(shape) ?? BorderRadius.zero;
  final given = so.corners;
  final held = LedgerThemeData.shapeLimits.clampCorners(
    given == null || (start && end && bottom)
        ? given
        : RawCorners(
            topStart: start ? given.topStart : null,
            bottomStart: start && bottom ? given.bottomStart : null,
            topEnd: end ? given.topEnd : null,
            bottomEnd: end && bottom ? given.bottomEnd : null,
          ),
    base: base,
    look: 'Ledger',
  );
  final steps = [
    held.topStart ?? RawCorner.none,
    held.topEnd ?? RawCorner.none,
    held.bottomStart ?? RawCorner.none,
    held.bottomEnd ?? RawCorner.none,
  ];
  if (steps.toSet().length == 1) return ledgerStep(t, steps.first);
  final scale = t.shapeScheme.corners;
  // A box's corner knows no size: a round corner beside ones that aren't
  // reaches half a finger's 40 dp (the scale's fullMaxRadius when it gives
  // one), half the height of a control at its floor.
  Radius at(RawCorner step) => step == RawCorner.full
      ? Radius.circular(scale.fullMaxRadius ?? _beside)
      : _radius(scale, step);
  return BorderRadiusDirectional.only(
    topStart: at(steps[0]),
    topEnd: at(steps[1]),
    bottomStart: at(steps[2]),
    bottomEnd: at(steps[3]),
  );
}

/// [radius] in [direction] less [by] on every corner, never below 0: the
/// face [by] inside another, its corners concentric with the outer's (a
/// field's inner well, a split button's halves inside its rule).
///
/// ```dart
/// ledgerInset(BorderRadius.circular(999), 3, TextDirection.ltr)
/// ```
BorderRadius ledgerInset(
  BorderRadiusGeometry radius,
  double by,
  TextDirection direction,
) {
  final r = radius.resolve(direction);
  Radius less(Radius c) =>
      Radius.elliptical(math.max(0, c.x - by), math.max(0, c.y - by));
  return BorderRadius.only(
    topLeft: less(r.topLeft),
    topRight: less(r.topRight),
    bottomLeft: less(r.bottomLeft),
    bottomRight: less(r.bottomRight),
  );
}

// A step's radius, square for none (full is the callers').
Radius _radius(RawCornerScale scale, RawCorner step) => switch (step) {
  RawCorner.none || RawCorner.full => Radius.zero,
  _ => Radius.circular(scale.radius(step)),
};

// Larger than any face's half height: every corner round.
const double _round = 999;

// Half the 40 dp a finger's target stands.
const double _beside = 20;
