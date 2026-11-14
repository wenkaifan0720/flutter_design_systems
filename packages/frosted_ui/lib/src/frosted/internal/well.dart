import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'css_shadow.dart';
import 'dim.dart';
import 'face.dart';
import 'styled.dart';

// The field parts every text control stands on: its label, its help or
// error line and its well. Plumbing of the components.

/// A field's label, silent to a screen reader (the control names itself)
/// (`.field-l { font: 500 12px/1.3 var(--font-t);
/// color: var(--ink-2) }`).
class FrostedFieldLabel extends StatelessWidget {
  /// A label saying [text].
  const FrostedFieldLabel(this.text, {super.key});

  /// The label's words.
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    child: Text(
      text,
      style: context.frostedTheme.textTheme.labelSmall.line(15.6),
    ),
  );
}

/// A field's help line (`.field-h { font: 400 12px/1.3 var(--font-t);
/// color: var(--ink-3) }`).
class FrostedFieldHint extends StatelessWidget {
  /// A help line saying [text], or what is wrong when [error].
  const FrostedFieldHint(this.text, {this.error = false, super.key});

  /// The line's words.
  final String text;

  /// Whether it says what is wrong: the over ink, announced as it appears.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final line = Text(
      text,
      style: error
          ? t.textTheme.bodySmall.line(15.6).c(t.colorScheme.over)
          : t.textTheme.bodySmall.line(15.6),
    );
    return error ? Semantics(liveRegion: true, child: line) : line;
  }
}

/// A well as `.inp`, `.amount-in` and `.pick-r` stand on it: the white at
/// .82 with its hairline ring inside. The source draws no focus style; the
/// ring takes the accent (Opal's ink) while the field holds focus; the
/// strong border (ink at 14%) barely showed on the well (DERIVED).
class FrostedWell extends StatelessWidget {
  /// A well round [child].
  const FrostedWell({
    required this.child,
    this.radius,
    this.layers,
    this.focused = false,
    this.error = false,
    this.enabled = true,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// The well's corner; null for [FrostedCorners.small].
  final double? radius;

  /// The field's style layers; null for the text field theme's.
  final FrostedStyleLayers? layers;

  /// Whether the field holds focus: the ring takes the accent.
  final bool focused;

  /// Whether the field is wrong: the ring takes the over ink.
  final bool error;

  /// Whether the field takes input; a disabled well fades to half.
  final bool enabled;

  /// The room inside the well.
  final EdgeInsets padding;

  /// What the well holds.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final s = (layers ?? FrostedStyleLayers(null, t.components.textField)).at({
      if (focused) WidgetState.focused,
      if (error) WidgetState.error,
      if (!enabled) WidgetState.disabled,
    });
    final knob = FrostedCorners.small;
    final cut =
        s.shape ??
        (radius != null || knob is RoundedRectangleBorder ? null : knob);
    final corner = radius ?? FrostedCorners.r12;
    final side = s.side;
    // .inp { background: rgba(255,255,255,.82);
    //   box-shadow: inset 0 0 0 1px rgba(21,21,45,.08) }
    // A field is recessed glass: a step darker than what holds it, shaded
    // along its top inside edge.
    // By day the well wears one even lit rim all round: holding focus it
    // brightens and glows, and when wrong the rim warms toward the over hue
    // over the over tint; never a dark line. By night its edge is the night
    // glass's rim (the accent while it holds focus, the over ink when wrong).
    final day = !t.isDark;
    final well = FrostedFace(
      material: s.fill == null ? FrostedMaterial.well : FrostedMaterial.paint,
      radius: BorderRadius.circular(
        FrostedStyleLayers.radiusOf(cut, 0, corner),
      ),
      shape: cut,
      color:
          s.fill ??
          (day && error
              ? t.colorScheme.overTint
              : day && focused
              ? t.glass.plane.withValues(alpha: .6)
              : null),
      wash: s.overlay,
      edge: side?.color,
      edges: side == null
          ? const EdgeInsets.all(FrostedChromeMetrics.outline)
          : EdgeInsets.all(side.width),
      ring: side != null
          ? null
          : error
          ? (day
                ? Color.lerp(
                    FrostedChromeMetrics.litEdge,
                    t.colorScheme.over,
                    .55,
                  )
                : t.colorScheme.over)
          : s.edge ??
                // Holding focus the edge takes the ring's ink by day (a lit
                // edge brightening on a pale backdrop read as no change)
                // and the accent by night.
                (focused
                    ? (day ? t.colorScheme.ringOuter : t.colorScheme.accent)
                    : day
                    ? FrostedChromeMetrics.litEdge
                    : t.controlEdge),
      // By night a focused well also wears a ring of the focus ink 2 past
      // its edge: its accent edge alone read as barely brighter than the
      // light edge every well has by night (self-review round 2).
      shadows: !focused || error
          ? const <BoxShadow>[]
          : day
          ? frostedFocusGlow
          : [
              frostedShadow(
                color: t.colorScheme.ringOuter,
                spread: FrostedChromeMetrics.focusRingWidth,
              ),
            ],
      padding: s.padding?.resolve(Directionality.of(context)) ?? padding,
      child: child,
    );
    return FrostedFade(opacity: enabled ? 1 : .5, child: s.least(well));
  }
}
