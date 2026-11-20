import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/well.dart';
import '../../internal/styled.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../forms/forms.dart' show FrostedSelectOption;
import '../marks/marks.dart' show FrostedCheckbox;
import '../pressable/pressable.dart';
import '../progress/progress.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';

/// One choice of a [FrostedRadioGroup]: its [value], its [label], a quiet
/// [note] under it, and whether it can be chosen ([enabled]). Built by the
/// group it stands in.
///
/// ```dart
/// FrostedRadioGroup<String>(label: 'Plan', value: plan, onChanged: setPlan, options: const [FrostedRadio('free', 'Free'), FrostedRadio('pro', 'Pro', note: 'Billed yearly')])
/// ```
class FrostedRadio<T> extends StatelessWidget {
  /// A choice of [value], named [label].
  const FrostedRadio(
    this.value,
    this.label, {
    this.note,
    this.enabled = true,
    this.style,
    super.key,
  });

  /// What choosing it sets.
  final T value;

  /// Its words.
  final String label;

  /// A line under the words.
  final String? note;

  /// Whether it can be chosen.
  final bool enabled;

  /// This choice's own style, over `FrostedThemeData.components.radio`:
  /// the mark's fill (selected when chosen), the dot's colour
  /// (foreground), the ring's colour or whole side, the mark's shape and
  /// the words' style, each per state.
  ///
  /// ```dart
  /// FrostedRadio(
  ///   'card',
  ///   'Card',
  ///   style: const FrostedStyle(
  ///     edge: WidgetStatePropertyAll(Color(0xFF5B5BD6)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final slot = _RadioSlot.of<T>(context);
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final on = slot.chosen;
    const d = 22.0;
    final layers = FrostedStyleLayers(style, t.components.radio);
    Widget draw(Set<WidgetState> states) {
      final s = layers.at(states);
      final shape = s.shape;
      final fill = s.fill;
      final side = s.side;
      // The opening is a small bead of glass in a field's language: a well a
      // step deeper than the glass it stands on, shaded along its top inside
      // edge, its rim the lit hairline by day and the night glass's rim by
      // night, never a dark line. Chosen, the bead takes a little more frost
      // and a dot is printed at its centre in the words' ink. The keyboard's
      // focus lights its rim, and by day it rises.
      final mark = SizedBox.square(
        dimension: d,
        child: FrostedFace(
          material: fill == null ? FrostedMaterial.well : FrostedMaterial.paint,
          radius: BorderRadius.circular(
            FrostedStyleLayers.radiusOf(shape, d, d / 2),
          ),
          shape: shape,
          color: fill,
          wash: on ? t.glass.wash : null,
          edge: side?.color,
          edges: side == null
              ? const EdgeInsets.all(FrostedChromeMetrics.outline)
              : EdgeInsets.all(side.width),
          ring: side != null
              ? null
              : s.edge ?? frostedLitEdge(t, t.controlEdge),
          child: Center(
            child: AnimatedScale(
              scale: on ? 1 : 0,
              duration: motion.fast,
              curve: motion.curve,
              child: SizedBox.square(
                dimension: 10,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    color: s.foreground ?? t.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Widget row = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: FrostedBreakpoints.hitTargetOf(context),
        ),
        child: Row(
          spacing: FrostedSpacing.s12,
          children: [
            mark,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FrostedSpacing.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    frostedCapCentred(
                      Text(
                        label,
                        style: t.textTheme.titleMedium.merge(s.textStyle),
                      ),
                    ),
                    if (note case final note?)
                      Text(note, style: t.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      row = FrostedDim(off: !enabled, child: row);
      return row;
    }

    return FrostedPressable(
      focusNode: slot.node,
      onPressed: slot.select,
      label: label,
      value: note,
      role: FrostedPressRole.control,
      checked: on,
      inMutuallyExclusiveGroup: true,
      radius: FrostedCorners.r12,
      builder: (context, states, _) => draw(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(StringProperty('label', label))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

// What ui_core's DesignRadioGroup hands one FrostedRadio: the focus node the
// group registers for it, the press that chooses it (null while it cannot be
// chosen) and whether it is the chosen one.
class _RadioSlot<T> extends InheritedWidget {
  const _RadioSlot({
    required this.node,
    required this.select,
    required this.chosen,
    required super.child,
  });

  final FocusNode node;
  final VoidCallback? select;
  final bool chosen;

  static _RadioSlot<T> of<T>(BuildContext context) {
    final slot = context.dependOnInheritedWidgetOfExactType<_RadioSlot<T>>();
    assert(slot != null, 'A FrostedRadio stands in a FrostedRadioGroup.');
    return slot!;
  }

  @override
  bool updateShouldNotify(_RadioSlot<T> old) =>
      old.node != node || old.select != select || old.chosen != chosen;
}

/// One choice of several, all in view: [options] down the column, each a
/// round bead of glass before its words (the chosen one's a little clearer,
/// a dot printed at its centre), the whole row its target. The page owns
/// [value]; a null [onChanged] leaves them inert. A screen reader hears
/// [label] over a group of radio buttons, each checked or not. ui_core's
/// [DesignRadioGroup] is the behaviour: one Tab stop, on the chosen option
/// (else the first that can be chosen), and the four arrows choose as they
/// move, in reading order, wrapping and passing over a disabled option.
///
/// ```dart
/// FrostedRadioGroup<String>(label: 'Delivery', value: speed, onChanged: (v) => setState(() => speed = v), options: const [FrostedRadio('standard', 'Standard', note: '3 to 5 days'), FrostedRadio('express', 'Express', note: 'Tomorrow')])
/// ```
class FrostedRadioGroup<T> extends StatelessWidget {
  /// The [options], [value] chosen.
  const FrostedRadioGroup({
    required this.options,
    required this.label,
    this.value,
    this.onChanged,
    this.error,
    super.key,
  });

  /// The choices, in order.
  final List<FrostedRadio<T>> options;

  /// The chosen value; null when none is.
  final T? value;

  /// Called with the value chosen.
  final ValueChanged<T>? onChanged;

  /// The group's name, printed over it and spoken.
  final String label;

  /// What is wrong with the choice, under it in the over ink.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final byValue = {for (final option in options) option.value: option};
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: DesignRadioGroup<T>(
        options: [for (final option in options) option.value],
        value: value,
        onChanged: onChanged,
        isEnabled: (v) => byValue[v]!.enabled,
        itemBuilder: (context, v, node, select) => _RadioSlot<T>(
          node: node,
          select: select,
          chosen: v == value,
          child: byValue[v]!,
        ),
        layoutBuilder: (context, items) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(
                label,
                style: t.textTheme.labelMedium.c(t.colorScheme.textSecondary),
              ),
            ),
            const SizedBox(height: FrostedSpacing.s4),
            ...items,
            if (error case final error?)
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: t.textTheme.bodySmall.c(t.colorScheme.over),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedRadio<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label))
      ..add(StringProperty('error', error, defaultValue: null));
  }
}

/// A chip: a short choice, filter, act or entry on the 32 glass capsule in
/// its hairline (the filter chips'), its [icon] before its [label]; while
/// [selected], the ink act with its word in white. With [onDeleted] it
/// carries a close at its end, its own target, read as [deleteLabel] (the
/// localized "Remove" and the label by default). Without [onPressed] it
/// states; with it, it acts (and with [selected], toggles). Its target is
/// 44, 48 under a finger.
///
/// ```dart
/// FrostedChip('Vegetarian', selected: veg, onPressed: () => setState(() => veg = !veg))
/// ```
///
/// ```dart
/// FrostedChip('ines@park.studio', icon: FrostedGlyphs.email, onDeleted: () => remove(email))
/// ```
class FrostedChip extends StatelessWidget {
  /// A chip saying [label].
  const FrostedChip(
    this.label, {
    this.onPressed,
    this.selected,
    this.onDeleted,
    this.deleteLabel,
    this.icon,
    this.isEnabled = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Its words.
  final String label;

  /// What a press does; null for a chip that only states.
  final VoidCallback? onPressed;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// Whether it stands chosen; null for a chip that is not a choice.
  final bool? selected;

  /// Removes it; null draws no close.
  final VoidCallback? onDeleted;

  /// The close's spoken name.
  final String? deleteLabel;

  /// A glyph before the words.
  final IconData? icon;

  /// Whether it takes presses.
  final bool isEnabled;

  /// This chip's own style, over `FrostedThemeData.components.chip`: its
  /// fill, foreground, edge or side (drawn in place of the hairline ring),
  /// overlay, shape, padding, minimum size, text style and icon size, each
  /// per state (selected while [selected] is true).
  ///
  /// ```dart
  /// FrostedChip(
  ///   'Vegetarian',
  ///   selected: veg,
  ///   onPressed: toggle,
  ///   style: const FrostedStyle(
  ///     shape: WidgetStatePropertyAll(
  ///       RoundedRectangleBorder(
  ///         borderRadius: BorderRadius.all(Radius.circular(8)),
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final on = selected ?? false;
    final close = onDeleted;
    final words = FrostedLocalizations.of(context);
    final layers = FrostedStyleLayers(style, t.components.chip);
    // Large text grows the pill by its words' extra line, as a button's: at
    // 200% the words would fill a 32 pill to its rim.
    final h = frostedGrownHeight(
      context,
      t.density.height(FrostedChromeMetrics.filterChip),
      t.textTheme.labelSmall,
    );
    Widget draw(Set<WidgetState> states) {
      final s = layers.at(states);
      final cut = s.cut(FrostedCorners.full);
      final ink = s.foreground ?? t.colorScheme.textPrimary;
      // Chosen, the glass stays glass: a check printed where its glyph
      // stands and a little more frost, never a fill of ink.
      final lead = on ? FrostedGlyphs.check : icon;
      final fill = s.fill;
      final side = s.side;
      final (edge, edges) = side == null
          ? (s.edge, const EdgeInsets.all(FrostedStrokes.regular))
          : s.edgeOf(null, FrostedStrokes.regular);
      final inset = t.density.padding(
        EdgeInsetsDirectional.only(
          start: FrostedChromeMetrics.filterChipInset + (lead == null ? 2 : 0),
          end: close == null ? FrostedChromeMetrics.filterChipInset + 2 : 4,
        ).resolve(Directionality.of(context)),
      );
      Widget face = AnimatedSwitcher(
        duration: motion.fast,
        child: SizedBox(
          key: ValueKey(on),
          height: h,
          child: FrostedFace(
            material: FrostedMaterial.pane,
            radius: BorderRadius.circular(
              FrostedStyleLayers.radiusOf(cut, h, h / 2),
            ),
            shape: cut,
            color: fill,
            wash: s.overlay ?? (on ? t.glass.wash : null),
            edge: edge,
            edges: edges,
            ring: edge != null ? null : frostedLitEdge(t, t.colorScheme.border),
            padding: s.padding?.resolve(Directionality.of(context)) ?? inset,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedSpacing.s4,
              children: [
                if (lead case final lead?)
                  Icon(lead, size: s.iconSize ?? 14, color: ink),
                frostedCapCentred(
                  Text(
                    label,
                    maxLines: 1,
                    style: s.words(
                      on
                          ? t.textTheme.labelSmall.semibold.c(ink)
                          : t.textTheme.labelSmall.c(ink),
                    ),
                  ),
                ),
                // Its node spans the lane the chip stands in, as its tap
                // does.
                if (close != null)
                  FrostedLaneKey(
                    child: FrostedPressable(
                      onPressed: isEnabled ? close : null,
                      label: deleteLabel ?? '${words.remove} $label',
                      radius: 12,
                      child: SizedBox.square(
                        dimension: 24,
                        child: Icon(
                          FrostedGlyphs.close,
                          size: s.iconSize ?? 14,
                          color: ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      // The check takes room as it comes in: the pill eases to its width.
      // Under Reduce Motion the width cuts (an AnimatedSize of no duration
      // would ask for a second layout from inside its own).
      if (motion.fast > Duration.zero) {
        face = AnimatedSize(
          duration: motion.fast,
          curve: motion.curve,
          alignment: AlignmentDirectional.centerStart,
          child: face,
        );
      }
      face = s.least(face);
      face = FrostedDim(off: !isEnabled, child: face);
      return face;
    }

    if (onPressed == null) {
      final chip = Semantics(
        label: label,
        selected: selected,
        explicitChildNodes: close != null,
        excludeSemantics: close == null,
        child: draw({
          if (!isEnabled) WidgetState.disabled,
          if (on) WidgetState.selected,
        }),
      );
      // Its remove key answers over the touch target's height. A chip turned
      // off (a choice that cannot be made now, as in a group that takes no
      // change) stands in the target a live one does, so turning it off
      // moves nothing round it; a tag that was never a control keeps its
      // own size.
      if (close != null) return FrostedTargetLane(child: chip);
      return isEnabled ? chip : FrostedHitSlop(child: chip);
    }
    final cut = layers.cut(FrostedCorners.full);
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: isEnabled ? onPressed : null,
      label: label,
      selected: selected,
      excludeChild: close == null,
      radius: FrostedStyleLayers.radiusOf(cut, h, h / 2),
      shape: cut,
      builder: (context, states, _) => draw(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onDeleted', onDeleted))
      ..add(StringProperty('deleteLabel', deleteLabel, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        FlagProperty(
          'isEnabled',
          value: isEnabled,
          ifFalse: 'isEnabled: false',
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

/// A score out of [max] stars: each star drawn in the signature band when
/// it is reached (half a star with [allowHalf]), a ring of the strong
/// hairline when it is not. With [onChanged] a press or a drag along the
/// row sets it (a pointer resting over it shows what a press would set),
/// the arrow keys step it, Home or 0 clears it, End fills it and a digit
/// sets that many; without, it only states. Read aloud as [label] and
/// "3 of 5". ui_core's [DesignRating] is the behaviour.
///
/// ```dart
/// FrostedRating(value: stars, label: 'Your rating', onChanged: (v) => setState(() => stars = v))
/// ```
///
/// ```dart
/// FrostedRating(value: 4.5, label: 'Average', allowHalf: true, size: 16)
/// ```
class FrostedRating extends StatelessWidget {
  /// [value] stars of [max].
  const FrostedRating({
    required this.value,
    required this.label,
    this.onChanged,
    this.max = 5,
    this.allowHalf = false,
    this.size = 28,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(value >= 0 && value <= max);

  /// The score.
  final double value;

  /// What a screen reader calls it.
  final String label;

  /// Called with the score set; null leaves it stating.
  final ValueChanged<double>? onChanged;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// How many stars.
  final int max;

  /// Whether a score may end in half a star.
  final bool allowHalf;

  /// A star's size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final live = onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    String spoken(double v) =>
        words.rating(v == v.roundToDouble() ? v.round() : v, max);
    Widget rating(FocusNode? node) => DesignRating(
      value: value,
      onChanged: onChanged,
      readOnly: !live,
      itemCount: max,
      allowHalf: allowHalf,
      focusNode: node,
      autofocus: autofocus,
      semanticLabel: label,
      semanticFormatterCallback: spoken,
      itemBuilder: (context, item) => CustomPaint(
        size: Size.square(size),
        painter: _StarPainter(
          fill: item.fill,
          band: t.hues.iris.band,
          // An empty star is glass in a field's language: its body a well's
          // step deeper (its raised tone), its rim the
          // lit hairline by day and the night glass's rim by night.
          body: t.materials.well.raised,
          ring: frostedLitEdge(t, t.controlEdge),
          rtl: rtl,
        ),
      ),
      layoutBuilder: (context, items) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: size * .2,
        children: items,
      ),
    );
    if (!live) return rating(null);
    return _KeyRing(
      focusNode: focusNode,
      radius: FrostedSpacing.s6,
      builder: (node) => ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: FrostedBreakpoints.hitTargetOf(context),
        ),
        // At the line's start, as the read-only stars stand, when the page
        // stretches it; as tall as the touch target, never the page.
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: rating(node),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(StringProperty('label', label))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(IntProperty('max', max, defaultValue: 5))
      ..add(FlagProperty('allowHalf', value: allowHalf, ifTrue: 'allowHalf'))
      ..add(DoubleProperty('size', size, defaultValue: 28));
  }
}

/// The focus ring round [builder]'s control while the keyboard, not a
/// pointer, holds [focusNode] (its own when null).
class _KeyRing extends StatefulWidget {
  const _KeyRing({
    required this.focusNode,
    required this.radius,
    required this.builder,
  });

  final FocusNode? focusNode;
  final double radius;
  final Widget Function(FocusNode node) builder;

  @override
  State<_KeyRing> createState() => _KeyRingState();
}

class _KeyRingState extends State<_KeyRing> {
  FocusNode? _own;

  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  bool get _keyboard =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _node.addListener(_changed);
    FocusManager.instance.addHighlightModeListener(_moded);
  }

  void _moded(FocusHighlightMode _) => _changed();

  @override
  void didUpdateWidget(_KeyRing old) {
    super.didUpdateWidget(old);
    final was = old.focusNode ?? _own;
    if (!identical(was, _node)) {
      was?.removeListener(_changed);
      _node.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_changed);
    FocusManager.instance.removeHighlightModeListener(_moded);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FrostedFocusRing(
    shown: _node.hasFocus && _keyboard,
    radius: widget.radius,
    child: widget.builder(_node),
  );
}

class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.fill,
    required this.band,
    required this.body,
    required this.ring,
    required this.rtl,
  });

  /// How much of the star is reached, 0 to 1.
  final double fill;
  final Gradient band;

  /// The empty star's body and its rim.
  final Color body;
  final Color ring;
  final bool rtl;

  static Path _star(Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    final inner = outer * .48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _star(size);
    final rect = Offset.zero & size;
    if (fill < 1) {
      canvas.drawPath(path, Paint()..color = body);
      canvas.drawPath(
        path,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (fill <= 0) return;
    canvas.save();
    final w = size.width * fill;
    canvas.clipRect(
      rtl
          ? Rect.fromLTWH(size.width - w, 0, w, size.height)
          : Rect.fromLTWH(0, 0, w, size.height),
    );
    canvas.drawPath(path, Paint()..shader = band.createShader(rect));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.fill != fill ||
      old.band != band ||
      old.body != body ||
      old.ring != ring ||
      old.rtl != rtl;
}

/// A file of a [FrostedFileUpload]: its [name], its size in [bytes], how
/// far its upload has gone ([progress], null once done), and what went
/// wrong ([error]).
@immutable
class FrostedUploadFile {
  /// A file named [name].
  const FrostedUploadFile(this.name, {this.bytes, this.progress, this.error});

  /// Its name.
  final String name;

  /// Its size.
  final int? bytes;

  /// How far it has gone up, 0 to 1; null when it is up.
  final double? progress;

  /// What went wrong with it.
  final String? error;

  /// Its size as a person reads it: 820 KB, 2.4 MB.
  String? get size {
    final b = bytes;
    if (b == null) return null;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).round()} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) =>
      other is FrostedUploadFile &&
      other.name == name &&
      other.bytes == bytes &&
      other.progress == progress &&
      other.error == error;

  @override
  int get hashCode => Object.hash(name, bytes, progress, error);
}

/// Where files are given: a glass well with the upload glyph, the glass
/// Choose a file and the invitation to drop one, then the [files] given so
/// far, each its name and size with its upload's progress and a remove. The
/// package picks no files itself: [onPressed] opens the app's picker, and an
/// app that takes drops sets [dragging] while one is over it (the well's
/// rim brightens and glows by day, takes the accent by night, as a field
/// holding focus does; with an [error] it warms to the over hue). Read
/// aloud as [label].
///
/// ```dart
/// FrostedFileUpload(label: 'Attachments', hint: 'PDF or images, up to 10 MB', onPressed: pick, files: files, onRemoved: (f) => setState(() => files.remove(f)))
/// ```
class FrostedFileUpload extends StatelessWidget {
  /// A place for files, called [label].
  const FrostedFileUpload({
    required this.label,
    this.onPressed,
    this.files = const [],
    this.onRemoved,
    this.hint,
    this.dragging = false,
    this.error,
    super.key,
  });

  /// What the files are for, printed over the well and spoken.
  final String label;

  /// Opens the app's file picker; null makes it inert.
  final VoidCallback? onPressed;

  /// The files given so far.
  final List<FrostedUploadFile> files;

  /// Removes a file; null draws no remove.
  final ValueChanged<FrostedUploadFile>? onRemoved;

  /// What it takes ("PDF or images, up to 10 MB").
  final String? hint;

  /// Whether a dragged file is over it.
  final bool dragging;

  /// What is wrong, under it in the over ink.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final well = FrostedWell(
      radius: FrostedCorners.r18,
      focused: dragging,
      error: error != null,
      child: Padding(
        padding: const EdgeInsets.all(FrostedSpacing.s20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedSpacing.s10,
            children: [
              Icon(
                FrostedGlyphs.upload,
                size: 24,
                color: t.colorScheme.textSecondary,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: FrostedSpacing.s8,
                runSpacing: FrostedSpacing.s6,
                children: [
                  FrostedButton.glass(
                    words.chooseFile,
                    size: FrostedButtonSize.small,
                    onPressed: onPressed,
                  ),
                  Text(words.dropFile, style: t.textTheme.bodySmall),
                ],
              ),
              if (hint case final hint?)
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedSpacing.s8,
        children: [
          ExcludeSemantics(
            child: Text(
              label,
              style: t.textTheme.labelMedium.c(t.colorScheme.textSecondary),
            ),
          ),
          well,
          for (final file in files)
            _FileRow(
              file: file,
              onRemoved: onRemoved == null ? null : () => onRemoved!(file),
            ),
          if (error case final error?)
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: t.textTheme.bodySmall.c(t.colorScheme.over),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        IterableProperty<FrostedUploadFile>(
          'files',
          files,
          defaultValue: const [],
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<FrostedUploadFile>>.has(
          'onRemoved',
          onRemoved,
        ),
      )
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(FlagProperty('dragging', value: dragging, ifTrue: 'dragging'))
      ..add(StringProperty('error', error, defaultValue: null));
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemoved});

  final FrostedUploadFile file;
  final VoidCallback? onRemoved;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final progress = file.progress;
    return FrostedFace(
      material: FrostedMaterial.pane,
      radius: BorderRadius.circular(FrostedCorners.r12),
      ring: frostedLitEdge(t, t.colorScheme.border),
      padding: const EdgeInsetsDirectional.fromSTEB(
        14,
        10,
        6,
        10,
      ).resolve(Directionality.of(context)),
      child: Row(
        spacing: FrostedSpacing.s10,
        children: [
          Icon(FrostedGlyphs.file, size: 18, color: t.colorScheme.textTertiary),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedSpacing.s4,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleMedium,
                ),
                if (file.error case final error?)
                  Text(
                    error,
                    style: t.textTheme.bodySmall.c(t.colorScheme.over),
                  )
                else if (progress != null)
                  FrostedLinearProgressIndicator(
                    value: progress,
                    label: file.name,
                    minHeight: 4,
                  )
                else if (file.size case final size?)
                  Text(size, style: t.textTheme.bodySmall),
              ],
            ),
          ),
          if (onRemoved case final remove?)
            FrostedPressable(
              onPressed: remove,
              label: '${words.remove} ${file.name}',
              radius: 14,
              child: SizedBox.square(
                dimension: 28,
                child: Icon(
                  FrostedGlyphs.close,
                  size: 16,
                  color: t.colorScheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check row and choices
// ---------------------------------------------------------------------------

/// A checkbox with its words as one row (Material's `CheckboxListTile`):
/// the [label] in the body over a quiet [note], the check at the row's end,
/// at least 52 tall; a press anywhere on the row turns it. Read aloud as
/// one checkbox named [label]. [tristate] lets it go round through mixed
/// (a null [value]); a null [onChanged] leaves it faded and inert.
///
/// ```dart
/// FrostedCheckRow(label: 'Email me a receipt', note: 'Sent to the address on file', value: receipt, onChanged: (v) => setState(() => receipt = v ?? false))
/// ```
class FrostedCheckRow extends StatelessWidget {
  /// A row named [label], checked by [value].
  const FrostedCheckRow({
    required this.label,
    required this.value,
    this.note,
    this.onChanged,
    this.enabled = true,
    this.tristate = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(tristate || value != null, 'Only a tristate check is mixed.');

  /// The row's words.
  final String label;

  /// A quiet line under them.
  final String? note;

  /// Whether it is checked; null is mixed.
  final bool? value;

  /// Hands over the next state; null leaves the row inert.
  final ValueChanged<bool?>? onChanged;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// Whether a row that can change may change now: false paints it disabled.
  final bool enabled;

  /// Whether a press goes round through mixed.
  final bool tristate;

  bool? get _next => switch (value) {
    false => true,
    true => tristate ? null : false,
    null => tristate ? false : true,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final change = enabled ? onChanged : null;
    final words = note;
    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s6),
        child: Row(
          spacing: FrostedSpacing.s12,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedSpacing.s2,
                children: [
                  Text(label, style: t.textTheme.titleMedium),
                  if (words != null) Text(words, style: t.textTheme.bodyMedium),
                ],
              ),
            ),
            // The check is the row's picture: the row is the control.
            ExcludeFocus(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: FrostedCheckbox(
                    value: value,
                    label: label,
                    tristate: tristate,
                    onChanged: change == null ? null : (_) {},
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    row = FrostedDim(off: !enabled, child: row);
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: change == null ? null : () => change(_next),
      label: words == null ? label : '$label, $words',
      role: FrostedPressRole.control,
      checked: value ?? false,
      excludeChild: true,
      radius: FrostedCorners.r10,
      child: row,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<bool?>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'));
  }
}

/// One value of a few, as a run of chips (tiles of Material's
/// `ChoiceChip`): each option a [FrostedChip], the chosen one lit, wrapping
/// onto a new line when the row runs out, 8 apart. A screen reader hears a
/// group named [label] of buttons, the chosen one selected. A null
/// [onChanged] leaves them inert; a disabled option stands faded.
///
/// ```dart
/// FrostedChoices<String>(label: 'Size', options: const [FrostedSelectOption('s', 'Small'), FrostedSelectOption('m', 'Medium'), FrostedSelectOption('l', 'Large')], value: size, onChanged: (v) => setState(() => size = v))
/// ```
class FrostedChoices<T> extends StatelessWidget {
  /// Chips over [options], [value] lit.
  const FrostedChoices({
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    super.key,
  });

  /// The choices, in reading order.
  final List<FrostedSelectOption<T>> options;

  /// The chosen value; null lights none.
  final T? value;

  /// Hands over the value pressed.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls the group.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: FocusTraversalGroup(
        child: Wrap(
          spacing: FrostedSpacing.s8,
          runSpacing: FrostedSpacing.s8,
          children: [
            for (final o in options)
              FrostedChip(
                o.label,
                selected: o.value == value,
                isEnabled: o.enabled && change != null,
                onPressed: change == null ? null : () => change(o.value),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedSelectOption<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}
