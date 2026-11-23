import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../components/pressable/pressable.dart' show FrostedFocusRing;
import '../theme.dart';
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

/// A field laid out from ui_core's [RawInputDecorator]: its [parts]' label
/// over its control and its error, else its help, under it, as
/// [FrostedFieldLabel] and [FrostedFieldHint] draw them. The decorator reads
/// the words on the control's node; what is drawn of them stays out of the
/// tree. [hint] false leaves the help and error undrawn (a list open over
/// them). Plumbing of the components.
Widget frostedFieldColumn(
  BuildContext context,
  RawInputDecoratorDetails parts, {
  bool hint = true,
  Widget Function(Widget hint)? hintBuilder,
}) {
  final t = context.frostedTheme;
  final words = parts.error ?? parts.helper;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: FrostedChromeMetrics.fieldLabelGap,
    children: [
      if (parts.label case final label?)
        DefaultTextStyle.merge(
          style: t.textTheme.labelSmall.line(15.6),
          child: label,
        ),
      parts.control,
      if (words != null && hint)
        (hintBuilder ?? (w) => w)(
          DefaultTextStyle.merge(
            style: parts.error != null
                ? t.textTheme.bodySmall.line(15.6).c(t.colorScheme.over)
                : t.textTheme.bodySmall.line(15.6),
            child: words,
          ),
        ),
    ],
  );
}

/// The recessed glass a field stands in (`.inp`, `.amount-in`, `.pick-r`):
/// a step darker than what holds it, with a thin neutral rim. Focus clears
/// its frost ([FrostedFocusRing]); a wrong field keeps the same rim and says
/// what is wrong in its message ([FrostedFieldHint]) in the over ink.
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

  /// Whether the field holds focus: its frost clears.
  final bool focused;

  /// Whether the field is wrong. Its style's error layer applies; the well
  /// itself keeps its neutral rim, as the message carries the warning.
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
    const knob = FrostedCorners.small;
    final cut =
        s.shape ??
        (radius != null || knob is RoundedRectangleBorder ? null : knob);
    final corner = radius ?? FrostedCorners.r12;
    final side = s.side;
    // .inp { background: rgba(255,255,255,.82);
    //   box-shadow: inset 0 0 0 1px rgba(21,21,45,.08) }
    // A field is recessed glass: a step darker than what holds it, shaded
    // along its top inside edge.
    // By day the well wears one even lit rim all round, never a dark line;
    // by night its edge is the night glass's rim. Wrong or not, the rim stays
    // neutral. Holding focus, its frost clears as every part's does
    // (FrostedFocusRing: more of the colour behind, its rim a little
    // brighter).
    final day = !t.isDark;
    final well = FrostedFace(
      material: s.fill == null ? FrostedMaterial.well : FrostedMaterial.paint,
      radius: BorderRadius.circular(
        FrostedStyleLayers.radiusOf(cut, 0, corner),
      ),
      shape: cut,
      color: s.fill,
      wash: s.overlay,
      edge: side?.color,
      edges: side == null
          ? const EdgeInsets.all(FrostedChromeMetrics.outline)
          : EdgeInsets.all(side.width),
      ring: side != null
          ? null
          : s.edge ?? (day ? FrostedChromeMetrics.litEdge : t.controlEdge),
      padding: s.padding?.resolve(Directionality.of(context)) ?? padding,
      child: child,
    );
    // Holding focus, the frost clears: no colour and no line; under a
    // resting pointer, a little.
    final lit = _WellRing(
      focused: focused,
      enabled: enabled,
      radius: FrostedStyleLayers.radiusOf(cut, 0, corner),
      shape: cut,
      child: well,
    );
    return FrostedFade(opacity: enabled ? 1 : .5, child: s.least(lit));
  }
}

/// A well's clearing: full while it holds focus, a little under a resting
/// pointer while it takes input.
class _WellRing extends StatefulWidget {
  const _WellRing({
    required this.focused,
    required this.enabled,
    required this.radius,
    required this.shape,
    required this.child,
  });

  final bool focused;
  final bool enabled;
  final double radius;
  final OutlinedBorder? shape;
  final Widget child;

  @override
  State<_WellRing> createState() => _WellRingState();
}

class _WellRingState extends State<_WellRing> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: FrostedFocusRing(
      shown: widget.focused,
      hovered: _hovered && widget.enabled,
      radius: widget.radius,
      shape: widget.shape,
      child: widget.child,
    ),
  );
}
