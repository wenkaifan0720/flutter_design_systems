/// A single choice among a few visible options: radios.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/styled.dart';
import '../shapes.dart';
import '../theme.dart';
import 'pressable.dart';

/// One option of a [MinimalRadioGroup]: the [value] it stands for, its
/// [label], and a quiet [description] under it.
@immutable
class MinimalRadioOption<T> {
  /// An option of a [MinimalRadioGroup].
  const MinimalRadioOption({
    required this.value,
    required this.label,
    this.description,
    this.enabled = true,
  });

  /// The value it stands for.
  final T value;

  /// What it says.
  final String label;

  /// A line under the label.
  final String? description;

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
/// own words. [style] dresses one radio, `components.radio` every one,
/// resolved with [WidgetState.selected] when chosen: fill, foreground (the
/// dot), edge or side, overlay and shape.
///
/// ```dart
/// MinimalRadio(selected: plan == 'pro', label: 'Pro', onPressed: () => setPlan('pro'))
/// ```
class MinimalRadio extends StatelessWidget {
  /// A radio showing whether it is [selected].
  const MinimalRadio({
    super.key,
    required this.selected,
    this.onPressed,
    this.label,
    this.enabled = true,
    this.size = 16,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether this is the choice.
  final bool selected;

  /// Choose this option; null makes it a mark, not a control.
  final VoidCallback? onPressed;

  /// What a screen reader hears for it.
  final String? label;

  /// False dims it and swallows taps.
  final bool enabled;

  /// The circle's diameter.
  final double size;

  /// This radio's style, over `components.radio`.
  final MinimalStyle? style;

  /// Its focus; null keeps its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

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
    return MinimalPressable(
      onPressed: press == null || !enabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              press();
            },
      enabled: enabled,
      shape: own,
      style: MinimalStyleOf(layers, const {}).press,
      semanticLabel: label,
      checked: selected,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) =>
          mark({...states, if (selected) WidgetState.selected}),
    );
  }
}

/// A single choice among a few options, all in view — a plan, a delivery
/// speed, a theme: a column (or a row) of [MinimalRadio]s, each followed by
/// its label in the body type and a quiet description. A tap anywhere on an
/// option's words chooses it; the arrow keys walk the options and Space
/// chooses. More than five or six options, or long ones, belong in a
/// `MinimalSelect`.
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
    this.label,
    this.style,
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
  final String? label;

  /// Every radio's style, over `components.radio`.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final vertical = direction == Axis.vertical;
    // Options that carry a description run taller than an option's least
    // height; space between them keeps each description with its own
    // label rather than halfway to the next.
    final described = options.any((o) => o.description != null);
    final change = onChanged;
    final rows = <Widget>[
      for (final option in options)
        _Option<T>(
          option: option,
          selected: option.value == value,
          onPressed: change == null || !option.enabled
              ? null
              : () => change(option.value),
          disabled: !option.enabled,
          style: style,
        ),
    ];
    return Semantics(
      container: true,
      label: label,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowRight): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft): PreviousFocusIntent(),
        },
        child: FocusTraversalGroup(
          child: vertical
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: described ? MinimalSpacing.s12 : 0,
                  children: rows,
                )
              : Wrap(
                  spacing: MinimalSpacing.s20,
                  runSpacing: t.density.height(MinimalSpacing.s4),
                  children: rows,
                ),
        ),
      ),
    );
  }
}

class _Option<T> extends StatelessWidget {
  const _Option({
    required this.option,
    required this.selected,
    required this.onPressed,
    required this.disabled,
    required this.style,
  });

  final MinimalRadioOption<T> option;
  final bool selected;
  final VoidCallback? onPressed;
  final bool disabled;
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final description = option.description;
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(option.label, style: t.body.c(t.foreground)),
        if (description != null)
          Text(description, style: t.bodySmall.c(t.mutedForeground)),
      ],
    );
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: t.density.height(MinimalLayout.minHitTarget - 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // The circle's centre on the label's first line.
                padding: const EdgeInsets.only(top: 3),
                child: MinimalRadio(
                  selected: selected,
                  onPressed: onPressed,
                  // The option dims as a whole; the radio stays undimmed
                  // inside it so the two do not compound.
                  enabled: true,
                  label: option.label,
                  style: style,
                ),
              ),
              const MinimalGap(MinimalSpacing.s8 + 2),
              Flexible(child: ExcludeSemantics(child: words)),
            ],
          ),
        ),
      ),
    );
  }
}
