import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/keys_shown.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../field/field.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';

/// How a radio group lays out, Fluent's RadioGroup `layout`: [vertical]
/// one radio a line, [horizontal] side by side (wrapping on a narrow
/// window), [horizontalStacked] side by side with each label under its
/// circle.
enum Fluent2RadioLayout {
  /// One radio under another.
  vertical,

  /// Side by side, each label after its radio.
  horizontal,

  /// Side by side, each label under its radio.
  horizontalStacked,
}

class _RadioScope extends InheritedWidget {
  const _RadioScope({
    super.key,
    required this.chosen,
    required this.enabled,
    required this.stacked,
    required super.child,
  });

  final bool chosen;
  final bool enabled;
  final bool stacked;

  static _RadioScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_RadioScope>();
    assert(scope != null, 'a Fluent2Radio stands in a Fluent2RadioGroup');
    return scope!;
  }

  @override
  bool updateShouldNotify(_RadioScope old) =>
      chosen != old.chosen || enabled != old.enabled || stacked != old.stacked;
}

/// One choice of a [Fluent2RadioGroup], Fluent's Radio: the 16 circle 8 in
/// from its edges, its [label] 4 after it in body1 (under it in a
/// stacked group). Unchosen, the accessible stroke with the label in the
/// third ink; chosen, the brand stroke round the brand dot (10) with the
/// label in the first. [enabled] false draws this one inert.
///
/// [style] restyles the circle over `Fluent2ThemeData.radioTheme`, in its
/// states (selected while chosen, hovered, pressed, disabled): `edge` or
/// `side` (the ring), `foreground` (the dot), `fill` (inside the ring),
/// `shape` (else a circle),
/// `minimumSize` (the ring's side) and `textStyle` (the label's).
///
/// ```dart
/// Fluent2Radio('weekly', 'Weekly digest')
/// ```
class Fluent2Radio<T> extends StatelessWidget {
  /// A radio for [value], labelled [label].
  const Fluent2Radio(
    this.value,
    this.label, {
    this.secondary,
    this.enabled = true,
    this.style,
    super.key,
  });

  /// What choosing it sets the group's value to.
  final T value;

  /// Its words.
  final String label;

  /// What shows after its words, as `RadioListTile.secondary` does: a
  /// palette's swatches, say. It only shows; a screen reader hears [label].
  final Widget? secondary;

  /// False draws it inert in the disabled inks.
  final bool enabled;

  /// This radio's own look, slot by slot, over the radio theme.
  final Fluent2Style? style;

  @override
  Widget build(BuildContext context) {
    final scope = _RadioScope.of(context);
    final chosen = scope.chosen;
    return MergeSemantics(
      child: TapTargetPadding(
        minSize: Fluent2Layout.tapFloorOf(context),
        // On the start keyline by its drawn face, the target growing
        // toward the end.
        alignment: AlignmentDirectional.centerStart,
        child: _RadioPress<T>(
          value: value,
          enabled: scope.enabled,
          label: label,
          builder: (context, states) => Fluent2PressFace(
            states: states,
            ring: scope.stacked,
            child: _face(
              context,
              states,
              chosen: chosen,
              stacked: scope.stacked,
            ),
          ),
        ),
      ),
    );
  }

  Widget _face(
    BuildContext context,
    Set<WidgetState> states, {
    required bool chosen,
    required bool stacked,
  }) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final layers = [style, t.radioTheme];
    final press = states.press;
    final off = press == Fluent2Press.disabled;
    final stroke = chosen
        ? press.pick(
            c.compoundBrandStroke,
            c.compoundBrandStrokeHover,
            c.compoundBrandStrokePressed,
            fluent2Step(t, c.neutralStrokeDisabled),
          )
        : press.pick(
            c.neutralStrokeAccessible,
            c.neutralStrokeAccessibleHover,
            c.neutralStrokeAccessiblePressed,
            fluent2Step(t, c.neutralStrokeDisabled),
          );
    final dot = press.pick(
      c.compoundBrandForeground1,
      c.compoundBrandForeground1Hover,
      c.compoundBrandForeground1Pressed,
      c.neutralForegroundDisabled,
    );
    final ink = off
        ? c.neutralForegroundDisabled
        : chosen
        ? c.neutralForeground1
        : press.pick(
            c.neutralForeground3,
            c.neutralForeground2,
            c.neutralForeground1,
          );
    return fluent2EasedInks([stroke, dot, ink], (context, inks) {
      final [stroke, dot, ink] = inks;
      final look = Fluent2StyleOf(layers, states);
      final ring =
          look.side ??
          BorderSide(color: look.edge ?? stroke, width: Fluent2Stroke.thin);
      final outline = look.shape;
      final side = look.minimumSize?.shortestSide ?? 16.0;
      final fill = look.fill;
      final mark = look.foreground ?? dot;
      // The dot: the disc scaled to .625, in the ring's outline.
      final inner = side * .625;
      final circle = Padding(
        padding: const EdgeInsets.all(Fluent2Spacing.s),
        child: Container(
          width: side,
          height: side,
          alignment: Alignment.center,
          decoration: outline == null
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(color: ring.color, width: ring.width),
                )
              : ShapeDecoration(
                  color: fill,
                  shape: outline.copyWith(side: ring),
                ),
          // The dot grows from the middle as the radio is chosen
          // and shrinks away as another is (durationNormal,
          // decelerating; at once under Reduce Motion).
          child: AnimatedScale(
            scale: chosen ? 1 : 0,
            duration: Fluent2Motion.on(context)
                ? Fluent2Motion.normal
                : Duration.zero,
            curve: Fluent2Motion.decelerateMid,
            child: Container(
              width: inner,
              height: inner,
              decoration: outline == null
                  ? BoxDecoration(shape: BoxShape.circle, color: mark)
                  : ShapeDecoration(color: mark, shape: outline),
            ),
          ),
        ),
      );
      final type = t.body1.merge(look.textStyle);
      if (stacked) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circle,
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Fluent2Spacing.s,
                0,
                Fluent2Spacing.s,
                Fluent2Spacing.s,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: type.c(ink),
              ),
            ),
            if (secondary case final secondary?)
              Padding(
                padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
                child: ExcludeSemantics(child: secondary),
              ),
          ],
        );
      }
      // The circle's ink on the keyline, its room hanging outside.
      return Fluent2HangRoom(
        focused: states.focused,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            fluent2OnFirstLine(context, type, circle),
            Flexible(
              child: Padding(
                // 4 after the circle, 8 at the end; the 20 line drawn
                // 2 into the circle's room above and under.
                padding: const EdgeInsetsDirectional.fromSTEB(
                  Fluent2Spacing.xs,
                  Fluent2Spacing.sNudge,
                  Fluent2Spacing.s,
                  Fluent2Spacing.sNudge,
                ),
                child: Text(label, style: type.c(ink)),
              ),
            ),
            if (secondary case final secondary?)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: Fluent2Spacing.s,
                ),
                // Centred on the words' first line, as the circle is.
                child: fluent2OnFirstLine(
                  context,
                  type,
                  SizedBox(
                    height: side + 2 * Fluent2Spacing.s,
                    child: Center(
                      widthFactor: 1,
                      child: ExcludeSemantics(child: secondary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(StringProperty('label', label))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(
        DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
      );
  }
}

/// A group of [Fluent2Radio] options with one selected [value].
///
/// The group is Flutter's [RadioGroup], each option a `RawRadio`, with
/// ui_core's [RadioGroupKeyboardFix] round them. Tab enters on the selected
/// radio if it is enabled, or the first enabled radio in reading order.
/// Arrow keys move focus and selection together, skipping disabled options
/// and wrapping at either end, Left and Right swapped right to left. The group uses
/// [label] or its enclosing field's label. A null [onChanged] disables it.
///
/// ```dart
/// Fluent2RadioGroup<String>(label: 'Digest', value: digest, onChanged: (v) => setState(() => digest = v), options: const [Fluent2Radio('daily', 'Daily'), Fluent2Radio('weekly', 'Weekly')])
/// ```
class Fluent2RadioGroup<T> extends StatefulWidget {
  /// A group of [options], one chosen.
  const Fluent2RadioGroup({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.layout = Fluent2RadioLayout.vertical,
    super.key,
  });

  /// The radios, in order.
  final List<Fluent2Radio<T>> options;

  /// The chosen radio's value; null chooses none.
  final T? value;

  /// Called with the value of the radio chosen; null puts the group out of use.
  final ValueChanged<T>? onChanged;

  /// The group's label, drawn over it (a [Fluent2Label]) and spoken as
  /// its name; null shows none, and a [Fluent2FormField] round it draws its
  /// own.
  final String? label;

  /// Fluent's `layout`: the radios under one another or side by side.
  final Fluent2RadioLayout layout;

  @override
  State<Fluent2RadioGroup<T>> createState() => _Fluent2RadioGroupState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Fluent2Radio<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>?>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        EnumProperty<Fluent2RadioLayout>(
          'layout',
          layout,
          defaultValue: Fluent2RadioLayout.vertical,
        ),
      );
  }
}

class _Fluent2RadioGroupState<T> extends State<Fluent2RadioGroup<T>> {
  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final change = widget.onChanged;
    final items = [
      for (final option in widget.options)
        _RadioScope(
          key: ValueKey<T>(option.value),
          chosen: option.value == widget.value,
          enabled: change != null && option.enabled,
          stacked: layout == Fluent2RadioLayout.horizontalStacked,
          child: option,
        ),
    ];
    final group = Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.label ?? Fluent2FieldScope.maybeOf(context)?.label,
      child: RadioGroup<T>(
        groupValue: widget.value,
        // RadioGroup takes no null: a group out of use gives a no-op, and
        // turns each radio off.
        onChanged: (value) {
          if (change == null || value == null || value == widget.value) return;
          change(value);
        },
        child: RadioGroupKeyboardFix<T>(
          child: switch (layout) {
            Fluent2RadioLayout.vertical => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items,
            ),
            _ => Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              children: items,
            ),
          },
        ),
      ),
    );
    final words = widget.label;
    if (words == null) return group;
    // The label is drawn over the group as a field's is (2 over it, 4
    // under), and said once, as the group's name.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: Fluent2Spacing.xxs,
            bottom: Fluent2Spacing.xxs * 2,
          ),
          child: ExcludeSemantics(child: Fluent2Label(words)),
        ),
        group,
      ],
    );
  }
}

/// A radio of the group round it, on Flutter's `RawRadio`: its states for
/// [builder], the keys' focus shown after a key only, as a press shows it.
class _RadioPress<T> extends StatefulWidget {
  const _RadioPress({
    required this.value,
    required this.enabled,
    required this.label,
    required this.builder,
  });

  final T value;
  final bool enabled;
  final String label;
  final Widget Function(BuildContext context, Set<WidgetState> states) builder;

  @override
  State<_RadioPress<T>> createState() => _RadioPressState<T>();
}

class _RadioPressState<T> extends State<_RadioPress<T>> {
  final FocusNode _node = FocusNode();
  // A pointer can hover even when touch was the last input, as over a
  // pressable.
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    Fluent2KeysShown.addListener(_changed);
  }

  @override
  void dispose() {
    Fluent2KeysShown.removeListener(_changed);
    _node.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final registry = RadioGroup.maybeOf<T>(context);
    final enabled = widget.enabled && registry != null;
    return RawRadio<T>(
      value: widget.value,
      mouseCursor: WidgetStateMouseCursor.clickable,
      toggleable: false,
      focusNode: _node,
      autofocus: false,
      groupRegistry: registry,
      enabled: enabled,
      builder: (context, radio) => Semantics(
        label: widget.label,
        child: ExcludeSemantics(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            // The whole radio takes the press, its gaps too.
            child: MetaData(
              behavior: HitTestBehavior.opaque,
              child: widget.builder(context, {
                for (final state in radio.states)
                  if (state != WidgetState.hovered &&
                      (state != WidgetState.focused || Fluent2KeysShown.shown))
                    state,
                if (enabled && _hover) WidgetState.hovered,
                if (enabled && radio.downPosition != null) WidgetState.pressed,
              }),
            ),
          ),
        ),
      ),
    );
  }
}
