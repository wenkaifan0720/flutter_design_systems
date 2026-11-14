// The rows of a grouped list are cells of its card (polish round 3, §2): a row's face is the band of the card it stands
// on, a breath inside the card's rim, from its rule down to the next row's. Its focus lift and its press are that band,
// so they go round the whole row and not its words. The corners a row shares with the card's corners are the card's
// corners moved in, around the same centres; the corners it shares with a neighbour are a control's.
import 'package:flutter/widgets.dart';

import '../frames.dart';
import '../shapes.dart';
import '../theme.dart' show NeumorphicRadii;

/// Where a grouped list's row stands in its card: whether it is the first thing in the card and whether it is the last,
/// and how far below it the next row starts.
class NeumorphicGroupRowScope extends InheritedWidget {
  /// Publishes a row's place to [child].
  const NeumorphicGroupRowScope({
    super.key,
    required this.top,
    required this.bottom,
    this.gap = 0,
    required super.child,
  });

  /// Whether nothing stands between the row and the card's top.
  final bool top;

  /// Whether nothing stands between the row and the card's bottom.
  final bool bottom;

  /// The space between this row and the next, where the next row's rule starts: the row's face runs down to it.
  final double gap;

  /// How far a row's card runs past a side the row shares with a neighbour: far enough that its corners never reach
  /// the row, so that side's corners are square.
  static const double far = 4096;

  /// How far inside the card's rim a row's band stands.
  static const double breath = 6;

  /// The face of a row standing in [context]: its outline, a cell of its card, and how far that face runs past the
  /// row's own box, side by side. Null outside a grouped list.
  static ({NeumorphicCellBorder border, EdgeInsets outset})? cellOf(
    BuildContext context,
  ) {
    final place = context
        .dependOnInheritedWidgetOfExactType<NeumorphicGroupRowScope>();
    if (place == null) return null;
    final holder = neumorphicHolder(context);
    if (holder == null) return null;
    final p = holder.padding, rim = holder.rim;
    // The band stands a breath inside the card's rim, round the card's own centres, so the card keeps its whole rim:
    // out to the rim, a chosen or pressed row ran through the card's side walls, a bite out of the card. Where the
    // card's padding is less than that, the band is narrower than the row's box.
    final inset = rim + breath;
    double out(double padding) => padding - inset;
    return (
      // Inside the card's rim, as a bank's cell sits inside the bank's: the card's outline moved in.
      border: NeumorphicCellBorder(
        bank: holder.border,
        reach: EdgeInsets.fromLTRB(
          inset,
          place.top ? inset : far,
          inset,
          place.bottom ? inset : far,
        ),
        // The card's outline moved in by the whole inset, round its own centres: near-concentric corners.
        frame: inset,
        // Where a row meets its neighbour it rounds as a control does: at the least round a chosen band across a card
        // read as a square bar laid over it.
        joins: NeumorphicRadii.control,
      ),
      outset: EdgeInsets.fromLTRB(
        out(p.left),
        place.top ? out(p.top) : 0,
        out(p.right),
        place.bottom ? out(p.bottom) : place.gap,
      ),
    );
  }

  @override
  bool updateShouldNotify(NeumorphicGroupRowScope old) =>
      old.top != top || old.bottom != bottom || old.gap != gap;
}
