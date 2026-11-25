import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'css_shadow.dart';
import 'face.dart';

/// How Frosted says "chosen" (the chosen chip, segment, tab, sidebar link):
/// the glass under the choice is thicker and brighter than the glass it
/// stands on, raised off it. By day it is a near-white platter, by night
/// the night glass lit a few steps; its light runs along its top edge, its
/// own glass edge holds it (the lit hairline by day, the night glass's rim
/// by night), and a soft lift stands under it. By day it draws no dark
/// outline: the look raises the glass instead of drawing round it.
/// Plumbing of the components.
class FrostedChosenPlate extends StatelessWidget {
  /// Creates a [FrostedChosenPlate].
  const FrostedChosenPlate({
    required this.radius,
    this.shape,
    this.padding = EdgeInsets.zero,
    this.child,
    this.painted = false,
    super.key,
  });

  /// Paint the plate, blurring nothing: on a solid band (the tab bar on
  /// the media ground), where no glass passes under it.
  final bool painted;

  /// The plate's corners.
  final BorderRadius radius;

  /// The plate's outline when a style cuts it to one.
  final OutlinedBorder? shape;

  /// The room inside the plate round its child.
  final EdgeInsets padding;

  /// What stands on the plate (the chosen link's glyph and word); null for
  /// a plate that slides under its cells.
  final Widget? child;

  /// The plate's fill: by day white at nearly its whole strength, by night
  /// white at a sixth, over the strip's own glass.
  static Color fillOf(FrostedThemeData t) =>
      t.isDark ? const Color(0x29FFFFFF) : t.glass.plane.withValues(alpha: .94);

  static final Expando<Color> _ink = Expando();

  /// The words on the plate: the page's ink where it reads 4.5:1 on the
  /// plate (and its top light) over the glass or straight on the page, at
  /// the canvas and under each wash at its peak, else the nearest tone of it
  /// that does (`RawPalette.readableTone`). By
  /// night the plate's white lifts the glass under a wash: in the ink, a
  /// chosen tab read 4.1-4.4:1 in copper and glacier.
  static Color inkOf(FrostedThemeData t) => _ink[t] ??= () {
    final page = t.colorScheme.background.withValues(alpha: 1);
    return RawPalette.readableTone(
      t.colorScheme.textPrimary,
      on: [
        for (final under in [
          page,
          ...t.lights.peaksOver(page, night: t.isDark),
        ])
          for (final plate in [
            Color.alphaBlend(fillOf(t), Color.alphaBlend(t.glass.fill, under)),
            Color.alphaBlend(fillOf(t), under),
          ]) ...[plate, Color.alphaBlend(lightOf(t), plate)],
      ],
    );
  }();

  /// The light along the plate's top edge: whiter than the plate by day,
  /// a third of white by night.
  static Color lightOf(FrostedThemeData t) =>
      t.isDark ? const Color(0x52FFFFFF) : const Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return FrostedFace(
      material: painted ? FrostedMaterial.paint : FrostedMaterial.pane,
      radius: radius,
      shape: shape,
      color: fillOf(t),
      sheen: lightOf(t),
      // By night the plate keeps the night glass's rim.
      ring: t.isDark ? t.controlEdge : null,
      padding: padding,
      shadows: shadowsOf(t),
      child: child,
    );
  }

  /// What holds the plate off the glass under it: its own faint glass edge,
  /// the raised step's shadow and a soft lift, thicker glass standing a
  /// little further off.
  /// By day the lift is broad and faint, so the plate's foot never reads as
  /// a dark line on the glass it stands in.
  static List<BoxShadow> shadowsOf(FrostedThemeData t) => [
    frostedShadow(color: t.glass.edge, spread: FrostedStrokes.regular),
    if (t.isDark) ...t.shadows.raised,
    BoxShadow(
      color: t.isDark ? const Color(0x47000000) : const Color(0x0E2A2464),
      offset: const Offset(0, 4),
      blurRadius: t.isDark ? 12 : 16,
      spreadRadius: -4,
    ),
  ];
}
