import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/face.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// The container for grouped content: the surface inside a 1 px hairline on
/// the theme's card radius, and never a shadow — Minimal separates what
/// sits on the page with rules, not elevation.
///
/// `flat: true` is the quiet panel: the same hairline around the
/// [MinimalThemeData.muted] fill, for a strip of figures or an aside that
/// should read as a well rather than a sheet of paper. `selected: true`
/// draws the hairline in the ink, [MinimalThemeData.foreground], on the same
/// face, no tint (the picked plan, the current workspace). With [onPressed]
/// the whole card is one
/// control with the system's press wash and focus ring.
///
/// Rows, row groups and gutter sections inside a card read it
/// ([MinimalCard.rowInsetOf]) and stand their text at [inset] from the card's
/// edge whatever the card's own padding: in a padless card they pad
/// themselves, in a padded one they take no side padding of their own.
/// Never a wrapper around a page's main list; a short settings-style group
/// of rows stands in a card through `MinimalListSection(inset: true)`.
///
/// [style] dresses one card, `components.card` every one, resolved with
/// [WidgetState.selected] when chosen: fill, edge or side, overlay, shape
/// (else `shapes.medium`) and padding (under [padding]). `t.rim`
/// is its rim.
///
/// ```dart
/// MinimalCard(child: summary)
/// ```
class MinimalCard extends StatelessWidget {
  /// A card around [child].
  const MinimalCard({
    super.key,
    required this.child,
    this.padding,
    this.onPressed,
    this.flat = false,
    this.selected,
    this.semanticLabel,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// A card's own padding, and the side inset of the rows standing in it:
  /// the sheet card's measure, so a card and a sheet read as one family.
  static const double inset = MinimalChromeMetrics.sheetPad;

  /// Its content.
  final Widget child;

  /// The room inside the rim; null takes the style's, else [inset] all
  /// round.
  final EdgeInsetsGeometry? padding;

  /// This card's style, over `components.card`.
  final MinimalStyle? style;

  /// Makes the whole card one control. Null is a static card.
  final VoidCallback? onPressed;

  /// The quiet panel: [MinimalThemeData.muted] inside the hairline.
  final bool flat;

  /// Whether this card is the chosen option of a set: true draws its
  /// hairline in the ink and announces selected, false announces
  /// an unselected option, null (the default) is a card that is not one of
  /// a set.
  final bool? selected;

  /// What a screen reader announces for a tappable card whose content says
  /// nothing in words.
  final String? semanticLabel;

  /// Whether [context] stands inside a [MinimalCard].
  static bool contains(BuildContext context) => _scope(context) != null;

  /// The side padding a row standing in the card around [context] takes so
  /// its text sits at [inset] from the card's edge: [inset] in a padless
  /// card, nothing in a card already padded by [inset]. Null outside a
  /// card.
  static EdgeInsets? rowInsetOf(BuildContext context) {
    final padding = _scope(context)?.padding;
    if (padding == null) return null;
    return EdgeInsets.only(
      left: math.max(0, inset - padding.left),
      right: math.max(0, inset - padding.right),
    );
  }

  /// The fill of the card around [context] — what a ring or a cut-out
  /// standing in the card paints to read as the card's own ground. Null
  /// outside a card.
  static Color? groundOf(BuildContext context) => _scope(context)?.fill;

  static _MinimalCardScope? _scope(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MinimalCardScope>();

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final chosen = selected ?? false;
    final layers = <MinimalStyle?>[style, t.components.card];
    final so = MinimalStyleOf(layers, minimalStates(selected: chosen));
    final shape = so.shape ?? t.shapes.medium;
    final padding =
        (this.padding ?? so.padding)?.resolve(
          Directionality.maybeOf(context),
        ) ??
        const EdgeInsets.all(inset);
    final fill = so.fill ?? (flat ? t.muted : t.card);
    // One keyline region: what stands in the card starts and ends on its
    // padding's lines (ui_core's keyline check reads it).
    final box = DesignKeylineRegion(
      label: 'MinimalCard',
      child: _box(padding, shape, fill, so, chosen, t),
    );
    if (onPressed == null) {
      return selected == null
          ? box
          : Semantics(container: true, selected: selected, child: box);
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      shape: shape,
      style: so.press,
      semanticLabel: semanticLabel,
      selected: selected,
      child: box,
    );
  }

  Widget _box(
    EdgeInsets padding,
    OutlinedBorder shape,
    Color fill,
    MinimalStyleOf so,
    bool chosen,
    MinimalThemeData t,
  ) {
    // The rim lerps to ink as the card is chosen (Minimal's short fade).
    final side = so.rim(chosen ? t.foreground : t.border, t.rim);
    return MinimalFace(
      // The rim's width is kept clear inside, as a border under the content
      // would keep it.
      padding: padding + EdgeInsets.all(side.strokeInset),
      decoration: minimalFrame(shape, fill: fill),
      // The rim is drawn over what stands inside: a row's opaque fill at a
      // corner would otherwise cover the inner half of the rim's arc, and
      // the corner read notched.
      foregroundDecoration: minimalFrame(shape, side: side),
      // The rows inside run to the hairline, so the card clips them to its
      // corners (a pressed row's wash, a selected row's tint).
      clipBehavior: Clip.antiAlias,
      builder: (context, _) => _MinimalCardScope(
        padding: padding,
        fill: fill,
        child: MinimalGroundFill(fill: fill, child: child),
      ),
    );
  }
}

/// Marks the subtree of a [MinimalCard] for [MinimalCard.contains], with the
/// card's padding and fill.
class _MinimalCardScope extends InheritedWidget {
  const _MinimalCardScope({
    required this.padding,
    required this.fill,
    required super.child,
  });

  final EdgeInsets padding;
  final Color fill;

  @override
  bool updateShouldNotify(_MinimalCardScope oldWidget) =>
      padding != oldWidget.padding || fill != oldWidget.fill;
}
