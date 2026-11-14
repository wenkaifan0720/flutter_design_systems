import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../components/pressable/pressable.dart';
import '../glyphs.dart';
import '../theme.dart';
import 'face.dart';
import 'styled.dart';
import 'dim.dart';

/// The look's floating panel, as a menu stands (`.menu`): the menu fill,
/// its hairline ring and soft drop, corners at [FrostedCorners.medium],
/// 6 in. Every part ui_core raises over the page (a popover, a hover
/// card, a combobox's list, a split button's or a menubar's menu, the
/// command palette) stands on it, so they read as one family with
/// [FrostedMenu]. Plumbing of the components.
class FrostedPanel extends StatelessWidget {
  /// A panel round [child], [width] wide (null: as wide as [child]).
  const FrostedPanel({
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(FrostedChromeMetrics.menuInset),
    this.presence,
    super.key,
  });

  /// What the panel holds.
  final Widget child;

  /// The panel's width; null sizes it to [child].
  final double? width;

  /// The room inside the face.
  final EdgeInsets padding;

  /// ui_core's 0→1 spring as the panel opens: it grows from 96% with it,
  /// frosted from its first frame; null stands it whole.
  final Animation<double>? presence;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final s = FrostedStyleLayers(null, t.components.menu);
    final (cut, corner) = s.surface(
      FrostedCorners.medium,
      FrostedStyleLayers.stockMedium,
      FrostedChromeMetrics.menuRadius,
    );
    // A menu floats: the thick glass.
    final face = FrostedFace(
      material: FrostedMaterial.slab,
      radius: BorderRadius.circular(corner),
      shape: cut,
      color: s.fill,
      shadows: [
        ...t.shadows.menu,
        BoxShadow(
          color: s.edge ?? t.glass.menuEdge,
          spreadRadius: FrostedStrokes.regular,
        ),
      ],
      clipChild: true,
      padding: s.padding?.resolve(Directionality.of(context)) ?? padding,
      child: child,
    );
    final sized = width == null ? face : SizedBox(width: width, child: face);
    final grow = presence;
    if (grow == null) return sized;
    return AnimatedBuilder(
      animation: grow,
      child: sized,
      // Glass is never faded from above: under an Opacity its blur reads an
      // empty layer and draws a grey plate until the fade ends. It grows in
      // frosted from its first frame instead; closed (0) it is not drawn.
      builder: (context, child) {
        final v = grow.value;
        if (v <= 0) return const SizedBox.shrink();
        return Transform.scale(
          scale: .96 + .04 * v.clamp(0.0, 1.2),
          child: child,
        );
      },
    );
  }
}

/// A row of a [FrostedPanel] painted for its [states] (`.menu-i`): 40 tall,
/// 10 in, corners 10; the check's column 16 wide when [checkable], then the
/// [label] in the link type, then [trailing]. The keyboard's highlight
/// (`focused`), a hover and a press lay the wash under it; the chosen row
/// (`selected`) takes the check and the ink, semibold. A disabled row
/// fades. Plumbing of the components.
class FrostedPanelRow extends StatelessWidget {
  /// A row saying [label] in [states].
  const FrostedPanelRow({
    required this.label,
    required this.states,
    this.leading,
    this.trailing,
    this.checkable = true,
    this.height = FrostedChromeMetrics.menuItem,
    super.key,
  });

  /// The row's words.
  final String label;

  /// The row's states, from ui_core.
  final Set<WidgetState> states;

  /// A glyph or swatch in the check's column, while the row is not chosen.
  final Widget? leading;

  /// A note or shortcut at the row's end.
  final Widget? trailing;

  /// Whether the row keeps the check's column.
  final bool checkable;

  /// The row's height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final chosen = states.contains(WidgetState.selected);
    final lit =
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);
    final off = states.contains(WidgetState.disabled);
    final row = SizedBox(
      height: height,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(FrostedChromeMetrics.menuItemRadius),
        color: lit || chosen ? t.glass.wash : null,
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedChromeMetrics.menuItemInset,
        ),
        child: Row(
          spacing: FrostedChromeMetrics.menuItemGap,
          children: [
            if (checkable || leading != null)
              SizedBox(
                width: FrostedChromeMetrics.menuItemGlyph,
                child: chosen && checkable
                    ? Icon(
                        FrostedGlyphs.check,
                        size: FrostedChromeMetrics.menuItemGlyph,
                        color: t.colorScheme.textPrimary,
                      )
                    : leading,
              ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: chosen
                    ? t.textTheme.link.semibold.c(t.colorScheme.textPrimary)
                    : t.textTheme.link.c(
                        lit
                            ? t.colorScheme.textPrimary
                            : t.colorScheme.textSecondary,
                      ),
              ),
            ),
            if (trailing case final trailing?)
              DefaultTextStyle.merge(
                style: t.textTheme.labelMedium.c(t.colorScheme.textTertiary),
                child: trailing,
              ),
          ],
        ),
      ),
    );
    return FrostedDim(off: off, child: row);
  }
}

/// [child] ringed while [states] say the keyboard holds it: ui_core puts
/// `focused` in the set only when focus came by the keyboard.
Widget frostedRingFor(
  Set<WidgetState> states,
  Widget child, {
  double radius = 0,
  OutlinedBorder? shape,
}) => FrostedFocusRing(
  shown: states.contains(WidgetState.focused),
  radius: radius,
  shape: shape,
  child: child,
);
