/// A single choice among a few visible options: radios.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/controls.dart';
import '../internal/press_feedback.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../shapes.dart';
import '../theme.dart';
import 'pressable.dart';

/// One option of a [MinimalRadioGroup]: the [value] it stands for, its
/// [label], and a quiet [subtitle] under it.
@immutable
class MinimalRadioOption<T> {
  /// An option of a [MinimalRadioGroup].
  const MinimalRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.secondary,
    this.enabled = true,
  });

  /// The value it stands for.
  final T value;

  /// What it says.
  final String label;

  /// A line under the label.
  final String? subtitle;

  /// What shows after the label, as `RadioListTile.secondary` does: a
  /// palette's swatches, say. It only shows; a screen reader hears the
  /// label.
  final Widget? secondary;

  /// False greys this option alone.
  final bool enabled;
}

/// Minimal's radio: a 16 px circle on the control edge that takes the
/// accent rim and a dot when it is the choice. Round by meaning in every
/// corner family, so it never reads as a checkbox. Its press wash and its
/// focus ring are circles too, the ring concentric outside the edge.
///
/// Stand radios in a [MinimalRadioGroup], which lays out their labels and
/// walks them with the arrow keys; this alone is for a row that draws its
/// own words. Such rows make one group in Flutter's [RadioGroup], with
/// ui_core's [RadioGroupKeyboardFix] round them: each row a `RawRadio` that
/// draws [MinimalRadio.mark] as its mark. A null [onPressed] turns the radio
/// off, as `Radio(onChanged: null)` does: it dims, takes no press and a
/// screen reader hears it disabled. [style] dresses one radio, `components.radio` every one,
/// resolved with [WidgetState.selected] when chosen: fill, foreground (the
/// dot), edge or side, overlay and shape.
///
/// ```dart
/// MinimalRadio(selected: plan == 'pro', semanticLabel: 'Pro', onPressed: () => setPlan('pro'))
/// ```
class MinimalRadio extends StatelessWidget {
  /// A radio showing whether it is [selected].
  const MinimalRadio({
    super.key,
    required this.selected,
    required this.onPressed,
    this.semanticLabel,
    this.size = 16,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _mark = null;

  /// The radio's circle alone, for a row that is the control: a `RawRadio`
  /// row draws it as its mark, and the row takes the press, the focus and
  /// what a screen reader hears. `enabled: false` paints the mark of a row
  /// that is off, dimmed as an off radio is.
  ///
  /// ```dart
  /// MinimalRadio.mark(selected: value == plan)
  /// ```
  const MinimalRadio.mark({
    super.key,
    required this.selected,
    bool enabled = true,
    this.size = 16,
    this.style,
  }) : onPressed = null,
       semanticLabel = null,
       focusNode = null,
       autofocus = false,
       _mark = enabled;

  /// Whether this is the choice.
  final bool selected;

  /// Choose this option; null turns the radio off.
  final VoidCallback? onPressed;

  /// What a screen reader hears for it.
  final String? semanticLabel;

  /// The circle's diameter.
  final double size;

  /// This radio's style, over `components.radio`.
  final MinimalStyle? style;

  /// Its focus; null keeps its own.
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  // Null for the control; for a mark, whether its row is on.
  final bool? _mark;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final layers = <MinimalStyle?>[style, t.components.radio];
    final duration = context.minimalStill ? Duration.zero : MinimalMotion.fast;
    final own = MinimalStyleOf(layers, const {}).shape ?? const CircleBorder();
    Widget mark(Set<WidgetState> states) {
      final so = MinimalStyleOf(layers, states);
      final shape = so.shape ?? const CircleBorder();
      final dot = size * 0.4;
      return AnimatedContainer(
        duration: duration,
        curve: MinimalMotion.out,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: minimalFrame(
          shape,
          fill: so.fill ?? t.card,
          side: so.rim(selected ? t.primary : t.input, t.rim),
        ),
        child: AnimatedScale(
          // The dot arrives by size alone, no bounce.
          scale: selected ? 1 : 0,
          duration: duration,
          curve: MinimalMotion.out,
          child: Container(
            width: dot,
            height: dot,
            decoration: ShapeDecoration(
              color: so.foreground ?? t.primary,
              shape: MinimalShapes.inset(shape, (size - dot) / 2),
            ),
          ),
        ),
      );
    }

    final press = onPressed;
    final radio = MinimalPressable(
      onPressed: press == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              press();
            },
      // A mark leaves the press, the focus and the reading to its row.
      enabled: _mark ?? press != null,
      shape: own,
      // A bare mark stands on its start keyline, its target growing
      // toward the end (a list row's trailing slot says the end).
      tapAlignment:
          MinimalTapAlignment.maybeOf(context) ??
          AlignmentDirectional.centerStart,

      style: MinimalStyleOf(layers, const {}).press,
      semanticLabel: semanticLabel,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) =>
          mark({...states, if (selected) WidgetState.selected}),
    );
    return _mark == null ? radio : ExcludeSemantics(child: radio);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('selected', selected))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(DoubleProperty('size', size, defaultValue: 16))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// A single choice among a few options, all in view — a plan, a delivery
/// speed, a theme: a column (or a row) of [MinimalRadio]s, each followed by
/// its label in the body type and a quiet description. A tap anywhere on an
/// option's words chooses it. The group is Flutter's [RadioGroup], each
/// option a `RawRadio`, with ui_core's [RadioGroupKeyboardFix] round them:
/// Tab lands on the choice (the first option while there is none, or while
/// the choice is disabled) and leaves the group next. The arrow keys choose
/// the next or the previous option, skipping disabled ones and wrapping at
/// the ends: Down and Right the next, Up and Left the previous (Left the next
/// in a right-to-left layout). Space chooses the focused option. More than
/// five or six options, or long ones, belong in a `MinimalSelect`.
///
/// [style] dresses every radio of the group, over `components.radio`.
///
/// ```dart
/// MinimalRadioGroup<String>(value: plan, onChanged: setPlan, options: const [MinimalRadioOption(value: 'free', label: 'Free'), MinimalRadioOption(value: 'pro', label: 'Pro')])
/// ```
class MinimalRadioGroup<T> extends StatelessWidget {
  /// Radios for [options], one chosen.
  const MinimalRadioGroup({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
    this.direction = Axis.vertical,
    this.semanticLabel,
    this.style,
    this.focusNode,
  });

  /// The options, top to bottom.
  final List<MinimalRadioOption<T>> options;

  /// The option chosen now; null while none is.
  final T? value;

  /// Null shows the choice without letting it change.
  final ValueChanged<T>? onChanged;

  /// Options in a column (the default) or along a row.
  final Axis direction;

  /// The group's name, for a screen reader.
  ///
  /// Leave it null inside a [MinimalFormField]: the field's label names the
  /// control, and a second name would be read twice.
  final String? semanticLabel;

  /// Every radio's style, over `components.radio`.
  final MinimalStyle? style;

  /// The focus of the chosen option, or of the first enabled one while none
  /// is chosen, for a caller that moves focus to the group: a `RawFormField`
  /// round it, which a failed submit focuses; null keeps the options' own.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final chosen = options.indexWhere((o) => o.value == value && o.enabled);
    final focused = chosen >= 0 ? chosen : options.indexWhere((o) => o.enabled);
    // Options that carry a description run taller than an option's least
    // height; space between them keeps each description with its own
    // label rather than halfway to the next.
    final described = options.any((o) => o.subtitle != null);
    final onChanged = this.onChanged;
    Widget layout(List<Widget> rows) => direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: described ? MinimalSpacing.s12 : 0,
            children: rows,
          )
        // Along a row the group is as wide as its options, on the start
        // edge, as a segmented control keeps to its segments.
        : Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: Wrap(
              spacing: MinimalSpacing.s20,
              runSpacing: t.density.height(MinimalSpacing.s4),
              children: rows,
            ),
          );
    return Semantics(
      container: true,
      label: semanticLabel,
      child: RadioGroup<T>(
        groupValue: value,
        // RadioGroup takes no null: a group that takes no choice gives a
        // no-op, and its options show the choice without offering it.
        onChanged: (next) {
          if (onChanged == null || next == null || next == value) return;
          HapticFeedback.selectionClick();
          onChanged(next);
        },
        child: RadioGroupKeyboardFix<T>(
          child: layout([
            for (final (i, option) in options.indexed)
              _Option<T>(
                key: ValueKey<T>(option.value),
                focusNode: i == focused ? focusNode : null,
                option: option,
                selected: option.value == value,
                offered: onChanged != null,
                disabled: !option.enabled,
                style: style,
              ),
          ]),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalRadioOption<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(
        EnumProperty<Axis>('direction', direction, defaultValue: Axis.vertical),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      );
  }
}

class _Option<T> extends StatefulWidget {
  const _Option({
    super.key,
    this.focusNode,
    required this.option,
    required this.selected,
    required this.offered,
    required this.disabled,
    required this.style,
  });

  final FocusNode? focusNode;
  final MinimalRadioOption<T> option;
  final bool selected;
  final bool offered;
  final bool disabled;
  final MinimalStyle? style;

  @override
  State<_Option<T>> createState() => _OptionState<T>();

  /// How far the circle stands below the option's top: its centre on the
  /// label's first line (a 20 px line, a 16 px circle, 2 px of leading
  /// over the cap height).
  static const double _markDrop = 3;
}

class _OptionState<T> extends State<_Option<T>> {
  final FocusNode _node = FocusNode();
  // A pointer can hover even when touch was the last input: the option's
  // states say so whatever Flutter's highlight mode, as a pressable's do.
  bool _hover = false;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final option = widget.option;
    final selected = widget.selected;
    final disabled = widget.disabled;
    final style = widget.style;
    final t = context.minimalTheme;
    final description = option.subtitle;
    // The whole option is the control, as a radio list tile is: a tap, the
    // click cursor and the press wash anywhere on its mark or its words,
    // one node for a screen reader that reads its label and description.
    // It stands at least the tap floor (40 for a finger), its words
    // centred in it, so a column of options is a column of targets.
    final option_ = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: math.max(
          t.density.height(MinimalChromeMetrics.row - MinimalSpacing.s8),
          minimalTapFloor(context),
        ),
      ),
      // In a column the option spans it (the column stretches it); along a
      // row it is as wide as its words, so the options stand side by side.
      child: Align(
        widthFactor: 1,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              // The circle's centre on the label's first line.
              padding: const EdgeInsets.only(top: _Option._markDrop),
              child: ExcludeSemantics(
                child: MinimalRadio.mark(selected: selected, style: style),
              ),
            ),
            // The checkbox rows' gap: a form's words start on one edge, 28 in.
            const MinimalGap(MinimalSpacing.s12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label, style: t.body.c(t.foreground)),
                  if (description != null)
                    Text(description, style: t.bodySmall.c(t.mutedForeground)),
                ],
              ),
            ),
            if (option.secondary case final secondary?) ...[
              const MinimalGap(MinimalSpacing.s8),
              // Centred on the label's first line, as the circle is.
              SizedBox(
                height: (_Option._markDrop + 8) * 2,
                child: Center(
                  widthFactor: 1,
                  child: ExcludeSemantics(child: secondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (!widget.offered && !disabled) {
      // A choice shown, not offered: still a radio to a screen reader.
      return Semantics(
        container: true,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        child: option_,
      );
    }
    final enabled = widget.offered && !disabled;
    // The target is the outermost layer, as a pressable's: the area a tap
    // reaches is the box a screen reader outlines.
    return minimalInlineNode(
      context,
      TapTargetPadding(
        alignment:
            MinimalTapAlignment.maybeOf(context) ?? AlignmentDirectional.center,
        child: Semantics(
          enabled: enabled,
          // One node: the radio, its label and its description.
          child: MergeSemantics(
            child: RawRadio<T>(
              value: option.value,
              mouseCursor: WidgetStateMouseCursor.clickable,
              toggleable: false,
              focusNode: widget.focusNode ?? _node,
              autofocus: false,
              groupRegistry: RadioGroup.maybeOf<T>(context),
              enabled: enabled,
              builder: (context, radio) {
                final pressed = enabled && radio.downPosition != null;
                final focused =
                    enabled && radio.states.contains(WidgetState.focused);
                return MouseRegion(
                  onEnter: (_) => setState(() => _hover = true),
                  onExit: (_) => setState(() => _hover = false),
                  // The whole option takes the press, its gaps too.
                  child: MetaData(
                    behavior: HitTestBehavior.opaque,
                    child: MinimalPressFeedback(
                      states: minimalStates(
                        enabled: enabled,
                        pressed: pressed,
                        hovered: enabled && _hover,
                        focused: focused,
                        selected: selected,
                      ),
                      enabled: enabled,
                      pressed: pressed,
                      focused: focused,
                      // The wash and the ring stand clear of the mark and the
                      // words.
                      outset: const EdgeInsetsDirectional.symmetric(
                        horizontal: MinimalSpacing.s8,
                      ),
                      child: option_,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
