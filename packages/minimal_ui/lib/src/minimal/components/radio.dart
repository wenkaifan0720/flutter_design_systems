/// A single choice among a few visible options: radios.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/controls.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
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

  /// {@macro minimal.autofocus}
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
      // A bare mark stands on its start keyline, its target growing
      // toward the end (a list row's trailing slot says the end).
      tapAlignment:
          MinimalTapAlignment.maybeOf(context) ??
          AlignmentDirectional.centerStart,

      style: MinimalStyleOf(layers, const {}).press,
      semanticLabel: label,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) =>
          mark({...states, if (selected) WidgetState.selected}),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('selected', selected))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
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
/// option's words chooses it. From the keyboard the group is one Tab stop,
/// as Flutter's `RadioGroup` is: Tab lands on the choice (the first option
/// while there is none) and leaves the group next. The arrow keys choose the
/// next or the previous option, skipping disabled ones and wrapping at the
/// ends: Down and Right the next, Up and Left the previous (Left the next in
/// a right-to-left layout). Space chooses the focused option. More than five
/// or six options, or long ones, belong in a `MinimalSelect`.
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
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    child: _RadioKeys<T>(group: this),
  );

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
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A [MinimalRadioGroup]'s options and its keys: one focus node an option,
/// one Tab stop for the group, and the arrows choosing.
class _RadioKeys<T> extends StatefulWidget {
  const _RadioKeys({required this.group});

  final MinimalRadioGroup<T> group;

  @override
  State<_RadioKeys<T>> createState() => _RadioKeysState<T>();
}

class _RadioKeysState<T> extends State<_RadioKeys<T>> {
  final List<FocusNode> _nodes = [];

  List<MinimalRadioOption<T>> get _options => widget.group.options;

  void _fit() {
    while (_nodes.length < _options.length) {
      _nodes.add(FocusNode(debugLabel: 'radio ${_nodes.length}'));
    }
    while (_nodes.length > _options.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _fit();
  }

  @override
  void didUpdateWidget(_RadioKeys<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fit();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// The option Tab lands on: the choice, else the first that takes focus.
  FocusNode? get _stop {
    final options = _options;
    final chosen = options.indexWhere(
      (o) => o.enabled && o.value == widget.group.value,
    );
    if (chosen >= 0) return _nodes[chosen];
    final first = options.indexWhere((o) => o.enabled);
    return first < 0 ? null : _nodes[first];
  }

  /// Chooses and focuses the next enabled option after the focused one
  /// ([forward]) or the one before it, round from the last to the first.
  void _step(bool forward) {
    final change = widget.group.onChanged;
    final at = _nodes.indexWhere((n) => n.hasFocus);
    if (change == null || at < 0) return;
    final open = [
      for (var i = 0; i < _options.length; i++)
        if (_options[i].enabled) i,
    ];
    final here = open.indexOf(at);
    if (open.length < 2 || here < 0) return;
    final next = open[(here + (forward ? 1 : -1) + open.length) % open.length];
    change(_options[next].value);
    _nodes[next].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final group = widget.group;
    final vertical = group.direction == Axis.vertical;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Options that carry a description run taller than an option's least
    // height; space between them keeps each description with its own
    // label rather than halfway to the next.
    final described = _options.any((o) => o.description != null);
    final change = group.onChanged;
    final rows = <Widget>[
      for (final (i, option) in _options.indexed)
        _Option<T>(
          option: option,
          selected: option.value == group.value,
          onPressed: change == null || !option.enabled
              ? null
              : () => change(option.value),
          disabled: !option.enabled,
          style: group.style,
          focusNode: _nodes[i],
        ),
    ];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(true),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(false),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(!rtl),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(rtl),
      },
      child: FocusTraversalGroup(
        policy: _OneStop(_nodes, _stop),
        child: vertical
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
              ),
      ),
    );
  }
}

/// Reading order with one of a group's [options] in it: its [stop], and the
/// focused one (which traversal moves on from).
class _OneStop extends ReadingOrderTraversalPolicy {
  _OneStop(this.options, this.stop);

  final List<FocusNode> options;
  final FocusNode? stop;

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final skip = {
      for (final node in options)
        if (node != stop && node != currentNode) node,
    };
    return super.sortDescendants(
      descendants.where((node) => !skip.contains(node)),
      currentNode,
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
    required this.focusNode,
  });

  final MinimalRadioOption<T> option;
  final bool selected;
  final VoidCallback? onPressed;
  final bool disabled;
  final MinimalStyle? style;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final description = option.description;
    final press = onPressed;
    // The whole option is the control, as a radio list tile is: a tap, the
    // click cursor and the press wash anywhere on its mark or its words,
    // one node for a screen reader that reads its label and description.
    // It stands at least the tap floor (44 for a finger), its words
    // centred in it, so a column of options is a column of targets.
    final option_ = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: math.max(
          t.density.height(MinimalLayout.minHitTarget - MinimalSpacing.s8),
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
              padding: const EdgeInsets.only(top: _markDrop),
              child: ExcludeSemantics(
                child: MinimalRadio(selected: selected, style: style),
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
          ],
        ),
      ),
    );
    if (press == null && !disabled) {
      // A choice shown, not offered: still a radio to a screen reader.
      return Semantics(
        container: true,
        checked: selected,
        inMutuallyExclusiveGroup: true,
        child: option_,
      );
    }
    return MinimalPressable(
      onPressed: press == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              press();
            },
      enabled: !disabled,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      focusNode: focusNode,
      // The wash and the ring stand clear of the mark and the words.
      outset: const EdgeInsetsDirectional.symmetric(
        horizontal: MinimalSpacing.s8,
      ),
      child: option_,
    );
  }

  /// How far the circle stands below the option's top: its centre on the
  /// label's first line (a 20 px line, a 16 px circle, 2 px of leading
  /// over the cap height).
  static const double _markDrop = 3;
}
