// The look's rule on a part's outline, held where every part reads its style: plaster is moulded, so no corner is
// sharper than the look's least, and an outline is one of the look's own borders, whose relief, insets and press the
// parts know how to draw. A foreign border (Material's rounded rectangle, a bevel) draws flat UI in plaster's colours.
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../shapes.dart';
import '../styled.dart';
import '../theme.dart';

/// [NeumorphicStyleOf] for a part at [states], its outline held to the look's rule in debug builds: a
/// [NeumorphicRoundedBorder] at least [NeumorphicRadii.least] round, a [NeumorphicStadiumBorder], a
/// [NeumorphicCircleBorder] or a bank's [NeumorphicCellBorder].
NeumorphicStyleOf neumorphicStyleOf(
  List<NeumorphicStyle?> layers,
  Set<WidgetState> states,
) {
  final look = NeumorphicStyleOf(layers, states);
  assert(
    neumorphicMoulded(look.shape),
    'Neumorphism moulds plaster with no sharp corner, round its own borders only: a style\'s shape is a '
    'NeumorphicRoundedBorder at least NeumorphicRadii.least (${NeumorphicRadii.least}) round, a '
    'NeumorphicStadiumBorder or a NeumorphicCircleBorder, not ${look.shape}.',
  );
  return look;
}

/// Whether [shape] is one the look moulds (null leaves the part's own).
bool neumorphicMoulded(OutlinedBorder? shape) => switch (shape) {
  null || NeumorphicCellBorder() => true,
  NeumorphicRoundedBorder(:final radius) => radius >= NeumorphicRadii.least,
  NeumorphicBorder() => true,
  _ => false,
};
