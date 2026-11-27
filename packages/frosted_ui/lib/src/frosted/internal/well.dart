import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../components/pressable/pressable.dart' show FrostedFocusRing;
import '../glyphs.dart';
import '../theme.dart';
import 'dim.dart';
import 'face.dart';
import 'styled.dart';

// The field parts every text control stands on: its label, its help or
// error line and its well. Plumbing of the components.

/// A field's label, silent to a screen reader (the control names itself):
/// 12 point medium in the secondary ink.
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

/// A field's help line: 12 point regular in the third ink.
class FrostedFieldHint extends StatelessWidget {
  /// A help line saying [text], or what is wrong when [error].
  const FrostedFieldHint(this.text, {this.error = false, super.key});

  /// The line's words.
  final String text;

  /// Whether it says what is wrong: led by the danger mark in the over ink,
  /// announced as it appears.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    if (error) {
      return Semantics(
        liveRegion: true,
        child: FrostedErrorWords(child: Text(text)),
      );
    }
    return Text(text, style: t.textTheme.bodySmall.line(15.6));
  }
}

/// What is wrong with a field or a choice: [child]'s words in the over ink,
/// led by the danger mark, so an error reads as one by its mark as well as
/// its colour. The mark is silent and grows with the text. Plumbing of the
/// components.
class FrostedErrorWords extends StatelessWidget {
  /// [child] as an error.
  const FrostedErrorWords({required this.child, super.key});

  /// The words.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final style = t.textTheme.bodySmall.line(15.6).c(t.colorScheme.over);
    final scaler = MediaQuery.textScalerOf(context);
    final line = scaler.scale(style.fontSize!) * style.height!;
    return DefaultTextStyle.merge(
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedSpacing.s4,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              height: line,
              child: Center(
                child: Icon(
                  FrostedGlyphs.danger,
                  size: scaler.scale(13),
                  color: t.colorScheme.over,
                ),
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// The line under a field (its help, or what is wrong) as it comes, changes
/// and goes: the room it takes eases open or shut as its words fade, so
/// what stands below the field slides rather than jumps. [gap] stands over
/// the words and comes and goes with them. A line of another key or type
/// (help to error) crosses; the same line with new words changes in place.
/// Under Reduce Motion, or with [eased] false, it cuts. Plumbing of the
/// components.
class FrostedHintSlot extends StatelessWidget {
  /// The line [child] (null for none) under a gap of [gap].
  const FrostedHintSlot({
    required this.child,
    this.gap = 0,
    this.eased = true,
    super.key,
  });

  /// The line, or null for none.
  final Widget? child;

  /// The room over the line, which goes with it.
  final double gap;

  /// Whether the line eases in and out; false cuts (a list opening over
  /// it).
  final bool eased;

  @override
  Widget build(BuildContext context) {
    final motion = FrostedMotion.of(context);
    final line = child;
    final Widget current = line == null
        ? const SizedBox.shrink(key: ValueKey<Type>(FrostedHintSlot))
        : Padding(
            key: line.key ?? ValueKey<Type>(line.runtimeType),
            padding: EdgeInsets.only(top: gap),
            child: line,
          );
    if (!eased) return current;
    return AnimatedSwitcher(
      duration: motion.base,
      switchInCurve: motion.curve,
      switchOutCurve: motion.curve,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: AlignmentDirectional.topStart,
        child: FadeTransition(opacity: animation, child: child),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      child: current,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('gap', gap, defaultValue: 0.0))
      ..add(FlagProperty('eased', value: eased, ifFalse: 'cuts'));
  }
}

/// A field's label in the label's ink, turning to the danger's while the
/// field is wrong and back as it is put right, easing across
/// ([FrostedMotion.fast]). Plumbing of the components.
class FrostedLabelInk extends StatelessWidget {
  /// [child] in the label's ink, or the danger's while [error].
  const FrostedLabelInk({required this.error, required this.child, super.key});

  /// Whether the field is wrong.
  final bool error;

  /// The label.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final style = t.textTheme.labelSmall.line(15.6);
    final rest = style.color ?? t.colorScheme.textSecondary;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: error ? 1 : 0),
      duration: motion.fast,
      curve: motion.curve,
      builder: (context, wrong, child) => DefaultTextStyle.merge(
        style: style.c(Color.lerp(rest, t.colorScheme.over, wrong)!),
        child: child!,
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('error', value: error, ifTrue: 'error'));
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
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.fieldLabelGap,
        children: [
          // A wrong field's label takes its message's danger ink.
          if (parts.label case final label?)
            FrostedLabelInk(error: parts.error != null, child: label),
          parts.control,
        ],
      ),
      // The help or the error eases in under the field; a list open over
      // it hides it at once.
      FrostedHintSlot(
        gap: FrostedChromeMetrics.fieldLabelGap,
        eased: hint,
        child: words == null || !hint
            ? null
            : KeyedSubtree(
                key: ValueKey<bool>(parts.error != null),
                child: (hintBuilder ?? (w) => w)(
                  parts.error != null
                      ? FrostedErrorWords(child: words)
                      : DefaultTextStyle.merge(
                          style: t.textTheme.bodySmall.line(15.6),
                          child: words,
                        ),
                ),
              ),
      ),
    ],
  );
}

/// The recessed glass a field stands in (a text entry, an amount, a
/// picker's row): a step darker than what holds it, with a thin neutral rim. Focus clears
/// its frost ([FrostedFocusRing]); a wrong field's glass takes the danger's
/// tint, its rim kept the glass's, the field shows the danger's mark at its
/// end, and its label and message take the danger's ink, the message saying
/// what is wrong ([FrostedErrorWords]).
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

  /// Whether the field is wrong: the glass takes the danger's tint (unless
  /// its style's error layer sets an overlay) and keeps its rim.
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
    // by night its edge is the night glass's rim. Wrong, the glass takes the
    // danger's tint and the rim stays the glass's. Holding focus, its frost clears as every part's does
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
      wash: s.overlay ?? (error ? t.colorScheme.overTint : null),
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
