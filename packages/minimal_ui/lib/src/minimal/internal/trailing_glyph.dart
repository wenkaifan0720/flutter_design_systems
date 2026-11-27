import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme.dart';

/// The empty share of Lucide's chevron box past its ink's end edge: on the
/// 24-unit grid it is drawn on, the stroke ends at 16.
const double minimalChevronBearing = 8 / 24;

/// The same for Lucide's cross (a close): its stroke ends at 19.
const double minimalCrossBearing = 5 / 24;

/// The same for Lucide's up-down chevrons (a menu select's): their strokes
/// end at 18.
const double minimalUpDownBearing = 6 / 24;

/// A row's trailing chevron, its ink (not its box) ending on the row's
/// trailing keyline, where a switch's or a count's edge stands: the forward
/// chevron of a row that opens a page, or the up-down pair of a row that
/// opens a menu. Only the paint moves: the row lays out the glyph's box as
/// before.
class MinimalTrailingChevron extends StatelessWidget {
  /// The chevron at [size] in [color].
  const MinimalTrailingChevron({
    super.key,
    required this.color,
    this.size = MinimalIconSize.i16,
    this.upDown = false,
  });

  /// The glyph's ink.
  final Color color;

  /// The glyph's box.
  final double size;

  /// Whether it is the up-down pair (a row that opens a menu) rather than
  /// the forward chevron.
  final bool upDown;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final hang = size * (upDown ? minimalUpDownBearing : minimalChevronBearing);
    return Transform.translate(
      offset: Offset(rtl ? -hang : hang, 0),
      child: MinimalIcon(
        upDown ? LucideIcons.chevronsUpDown : LucideIcons.chevronRightDir,
        size: size,
        color: color,
      ),
    );
  }
}
