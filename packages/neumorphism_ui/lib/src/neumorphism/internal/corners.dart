// An app's per-part corners: a style's `corners` over a part's own outline. Each corner given takes its step, held to
// the look's bands (`NeumorphicThemeData.shapeLimits`, perCorner: a square corner goes to the least) and drawn at the
// theme's scale; the corners left out keep the part's own. Start and end follow the reading
// direction, resolved here, so every painter that reads the outline draws the same corners. A style's `shape` wins.
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../shapes.dart';
import '../styled.dart';
import '../theme.dart';

/// A style layer that keeps a part's own corners whatever its style and its theme give: set over an object's style,
/// whose geometry is the part (a switch's slot, a slider's track).
const NeumorphicStyle neumorphicOwnCorners = NeumorphicStyle(
  corners: WidgetStatePropertyAll(RawCorners()),
);

/// The outline a part draws: [look]'s shape when it gives one; else [own], the part's own, with the corners [look]
/// gives. A piece of a strip (a segment, a row of a card) takes only the corners on the strip's ends: the start ones
/// where it [starts] the strip, the end ones where it [ends] it, the top ones where it is at the strip's [top] and the
/// bottom ones at its [bottom]; the others keep the piece's own.
OutlinedBorder neumorphicCut(
  BuildContext context,
  NeumorphicStyleOf look,
  OutlinedBorder own, {
  bool starts = true,
  bool ends = true,
  bool top = true,
  bool bottom = true,
}) =>
    look.shape ??
    neumorphicCornered(
      context,
      own,
      look.corners,
      starts: starts,
      ends: ends,
      top: top,
      bottom: bottom,
    );

/// [own] with the corners in [corners] (see [neumorphicCut]). A circle stays a circle (a radio, a round key, a dial:
/// their round is the part), a bank's cell follows its bank, and an outline whose corners are already its own
/// ([NeumorphicRoundedBorder.borderRadius]) is kept.
OutlinedBorder neumorphicCornered(
  BuildContext context,
  OutlinedBorder own,
  RawCorners? corners, {
  bool starts = true,
  bool ends = true,
  bool top = true,
  bool bottom = true,
}) {
  if (corners == null) return own;
  final given = RawCorners(
    topStart: starts && top ? corners.topStart : null,
    topEnd: ends && top ? corners.topEnd : null,
    bottomStart: starts && bottom ? corners.bottomStart : null,
    bottomEnd: ends && bottom ? corners.bottomEnd : null,
  );
  if (given.isEmpty) return own;
  final t = NeumorphicTheme.of(context);
  final RawCorner step;
  final double at;
  switch (own) {
    case NeumorphicRoundedBorder(:final radius, borderRadius: null):
      step = _stepOf(t.shapes, radius);
      at = radius;
    case NeumorphicStadiumBorder(:final maxRadius):
      step = RawCorner.full;
      at = maxRadius;
    default:
      return own;
  }
  final held = NeumorphicThemeData.shapeLimits.clampCorners(
    given,
    base: RawCorners.all(step),
    look: 'Neumorphism',
  );
  final scale = t.shapeScheme.corners;
  // A corner at the part's own step keeps the part's own radius (a chip's, a well's), so only the corners given move.
  Radius r(RawCorner? k) => Radius.circular(
    k == null || k == step
        ? at
        : k == RawCorner.full
        ? scale.fullMaxRadius ?? at
        : scale.radius(k),
  );
  final ts = r(held.topStart),
      te = r(held.topEnd),
      bs = r(held.bottomStart),
      be = r(held.bottomEnd);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return NeumorphicRoundedBorder(
    side: own.side,
    radius: at,
    borderRadius: BorderRadius.only(
      topLeft: rtl ? te : ts,
      topRight: rtl ? ts : te,
      bottomLeft: rtl ? be : bs,
      bottomRight: rtl ? bs : be,
    ),
  );
}

// The step a part's own [radius] stands at: the scale's step it equals (a chip's and a well's move with the control's),
// else the nearest.
RawCorner _stepOf(NeumorphicShapes s, double radius) {
  final steps = <(double, RawCorner)>[
    (s.control, RawCorner.medium),
    (s.chip, RawCorner.medium),
    (s.well, RawCorner.medium),
    (s.cap, RawCorner.small),
    (s.slab, RawCorner.large),
    (s.least, RawCorner.extraSmall),
  ];
  for (final (r, step) in steps) {
    if (r == radius) return step;
  }
  var best = steps.first;
  for (final x in steps) {
    if ((x.$1 - radius).abs() < (best.$1 - radius).abs()) best = x;
  }
  return best.$2;
}
