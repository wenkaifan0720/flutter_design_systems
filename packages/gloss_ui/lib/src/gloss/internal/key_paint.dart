/// How Gloss paints a key with words (a gel or a pearl key) from its
/// states: for [GlossButton] and for a part whose own pressable holds a key
/// (a dialog's actions).
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../fonts.dart';
import '../surface.dart';
import '../theme.dart';

/// A key's kind: pearl, jade gel, or letterpressed words.
enum GlossKeyKind {
  /// A pearl key.
  pearl,

  /// The jade gel key.
  gel,

  /// Words alone.
  text,
}

/// The part theme over a key of [kind] in [theme].
GlossStyle? glossKeyTheme(GlossThemeData theme, GlossKeyKind kind) =>
    switch (kind) {
      GlossKeyKind.pearl => theme.buttonStyle,
      GlossKeyKind.gel => theme.filledButtonStyle,
      GlossKeyKind.text => theme.textButtonStyle,
    };

/// The face of a key of [kind] in [states]: gel (ruby when [destructive])
/// or pearl, [style] over its part theme.
GlossFace glossKeyFace(
  GlossThemeData theme,
  Set<WidgetState> states, {
  required GlossKeyKind kind,
  bool destructive = false,
  GlossStyle? style,
}) {
  final c = theme.colors;
  final layered = DesignStyleOf([style, glossKeyTheme(theme, kind)], states);
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  final focus = glossFocusOf(c, focused: states.contains(WidgetState.focused));
  if (disabled) {
    // Clouded, not lit: a gel key off keeps a faint cast of its gel, so
    // it still reads as the screen's action and apart from a pearl key.
    final rest = GlossFace.pearl(c);
    final clouded = kind == GlossKeyKind.gel
        ? GlossFace.lerp(
            rest,
            destructive ? GlossFace.ruby(c) : GlossFace.gel(c),
            0.2,
          )
        : rest;
    // By night a key off sinks halfway to the page, so it reads as off
    // beside a lit pearl and its clouded words still read on it.
    final night = c.brightness == Brightness.dark;
    Color dim(Color v) => night ? Color.lerp(v, c.page, 0.5)! : v;
    return clouded.copyWith(
      top: dim(clouded.top),
      middle: dim(clouded.middle),
      bottom: dim(clouded.bottom),
      foreground: layered.foreground ?? c.inkDisabled,
      edge: rest.edge,
      lens: night ? 0 : 0.25,
      lift: 0.3,
      glow: const Color(0x00000000),
    );
  }
  var face = switch (kind) {
    GlossKeyKind.gel => destructive ? GlossFace.ruby(c) : GlossFace.gel(c),
    _ => GlossFace.pearl(
      c,
    ).copyWith(foreground: destructive ? c.danger : c.ink),
  };
  final fill = layered.fill;
  if (fill != null) face = face.glazed(fill);
  final edge = layered.edge ?? layered.side?.color;
  return face.copyWith(
    foreground: layered.foreground,
    edge: edge,
    travel: pressed ? 1 : 0,
    focus: focus,
  );
}

/// A pearl or gel key of [kind] reading [label] (after [icon]), painted in
/// [states]; the pressable round it is the caller's.
Widget glossKeyPaint(
  BuildContext context,
  Set<WidgetState> states, {
  required GlossKeyKind kind,
  required String label,
  Widget? icon,
  bool destructive = false,
  GlossStyle? style,
}) {
  final theme = GlossTheme.of(context);
  final layered = DesignStyleOf([style, glossKeyTheme(theme, kind)], states);
  final face = glossKeyFace(
    theme,
    states,
    kind: kind,
    destructive: destructive,
    style: style,
  );
  final padding =
      layered.padding(Directionality.of(context)) ??
      EdgeInsets.symmetric(horizontal: 22 + theme.density.paddingDelta);
  final minimum = layered.minimumSize ?? Size(0, theme.controlHeight);
  // At large text sizes a key's words take a second line and the key
  // grows round them, rather than losing their end.
  final large = MediaQuery.textScalerOf(context).scale(10) >= 15;
  final gel =
      kind == GlossKeyKind.gel && !states.contains(WidgetState.disabled);
  // The words take the face's own colour as it moves (white on gel),
  // read from the surface they stand on.
  final words = Builder(
    builder: (context) => DefaultTextStyle.merge(
      style: theme.textTheme.label
          .copyWith(
            color: DefaultTextStyle.of(context).style.color,
            shadows: gel
                ? [
                    Shadow(
                      color: face.edge.withValues(alpha: 0.45),
                      offset: const Offset(0, -1),
                    ),
                  ]
                : null,
          )
          .merge(layered.textStyle),
      maxLines: large ? 2 : 1,
      textAlign: TextAlign.center,
      // Two lines are as wide as the longer, so the glyph stays
      // beside the words, not at the key's far end.
      textWidthBasis: TextWidthBasis.longestLine,
      overflow: TextOverflow.ellipsis,
      child: DesignCapCenter(
        capHeightFactor: glossCapHeightFactor,
        child: Text(label),
      ),
    ),
  );
  return DesignTapTarget(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimum.width,
        minHeight: minimum.height,
      ),
      child: AnimatedGlossSurface(
        face: face.copyWith(radius: _radius(layered)),
        child: Padding(
          padding: large
              ? padding +
                    const EdgeInsets.symmetric(vertical: GlossSpacing.small)
              : padding,
          // As tall as its words need (with the floor above): left
          // open, it would stretch to fill a bar's whole height.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(size: layered.iconSize ?? 20),
                    child: icon,
                  ),
                  const SizedBox(width: GlossSpacing.small),
                ],
                Flexible(child: words),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

double? _radius(DesignStyleOf layered) {
  final shape = layered.shape;
  if (shape is RoundedRectangleBorder) {
    final r = shape.borderRadius;
    if (r is BorderRadius) return r.topLeft.x;
  }
  return null;
}
