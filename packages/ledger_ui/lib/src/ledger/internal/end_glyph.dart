import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A Lucide glyph at the end of a line with its ink, not its box, on the
/// line's end. Lucide draws on a 24 grid inside a margin, so a 16 chevron's
/// box runs 5.3 past its ink, and a row ending in one would end short of the
/// rule and the switch above it. Laid out at its box; painted moved toward
/// the end by the glyph's margin (its tap box, the row, is unchanged).
/// In a right-to-left page a left or right chevron or arrow turns the other
/// way ([ledgerDirectional]). Plumbing of the parts.
class LedgerEndGlyph extends StatelessWidget {
  /// The glyph [icon] at a line's end.
  const LedgerEndGlyph(
    this.icon, {
    required this.size,
    required this.color,
    super.key,
  });

  /// The Lucide glyph.
  final IconData icon;

  /// The glyph's size.
  final double size;

  /// The glyph's colour.
  final Color color;

  /// The empty part of the 24 grid after [icon]'s ink, its stroke's half
  /// counted as ink; 0 for a glyph not listed.
  static double marginOf(IconData icon) => _margins[icon] ?? 0;

  static final Map<IconData, double> _margins = {
    LucideIcons.chevronRight: 8,
    LucideIcons.chevronLeft: 8,
    LucideIcons.chevronDown: 5,
    LucideIcons.chevronUp: 5,
    LucideIcons.check: 3,
    LucideIcons.x: 5,
    LucideIcons.arrowRight: 4,
  };

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shift = size * marginOf(icon) / 24;
    return Transform.translate(
      offset: Offset(rtl ? -shift : shift, 0),
      child: Icon(ledgerDirectional(context, icon), size: size, color: color),
    );
  }
}

/// [icon] as it points at [context]: a left or right chevron or arrow turns
/// the other way in a right-to-left page, so a disclosure points to the
/// reading end and a back to its start. Any other glyph is drawn as it is.
IconData ledgerDirectional(BuildContext context, IconData icon) =>
    Directionality.of(context) == TextDirection.rtl
    ? (_mirrored[icon] ?? icon)
    : icon;

/// [icon] drawn at [size] in [color] as it points at [context]: a chevron or
/// an arrow turns ([ledgerDirectional]), and a glyph with a heading of its
/// own (send's paper plane) is drawn mirrored in a right-to-left page, so it
/// flies to the reading end as Continue's arrow points there.
Widget ledgerGlyph(
  BuildContext context,
  IconData icon, {
  double? size,
  Color? color,
}) {
  final drawn = Icon(
    ledgerDirectional(context, icon),
    size: size,
    color: color,
  );
  return Directionality.of(context) == TextDirection.rtl &&
          _headed.contains(icon)
      ? Transform.flip(flipX: true, child: drawn)
      : drawn;
}

final Set<IconData> _headed = {LucideIcons.send};

final Map<IconData, IconData> _mirrored = {
  LucideIcons.chevronRight: LucideIcons.chevronLeft,
  LucideIcons.chevronLeft: LucideIcons.chevronRight,
  LucideIcons.arrowRight: LucideIcons.arrowLeft,
  LucideIcons.arrowLeft: LucideIcons.arrowRight,
  LucideIcons.chevronsRight: LucideIcons.chevronsLeft,
  LucideIcons.chevronsLeft: LucideIcons.chevronsRight,
};
