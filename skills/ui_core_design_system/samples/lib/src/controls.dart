import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'face.dart';
import 'theme.dart';

/// A box that is ticked or not ([value]), or partly when [tristate] and
/// [value] is null. A null [onChanged] disables it.
///
/// ```dart
/// LookCheckbox(value: true, onChanged: (value) {}, label: 'Email me')
/// ```
class LookCheckbox extends StatelessWidget {
  /// A checkbox showing [value].
  const LookCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.label,
  }) : assert(tristate || value != null);

  /// Whether it is ticked; null is partly, when [tristate].
  final bool? value;

  /// Called with the next value; null disables the box.
  final ValueChanged<bool?>? onChanged;

  /// Whether null is a value of its own.
  final bool tristate;

  /// The words beside the box, part of its tap target and its name.
  final String? label;

  bool? get _next => switch (value) {
    false => true,
    true => tristate ? null : false,
    null => false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final c = theme.colors;
    final change = onChanged;
    return TapTargetPadding(
      alignment: AlignmentDirectional.centerStart,
      child: RawButton(
        onPressed: change == null ? null : () => change(_next),
        // A checkbox is a checkbox to a screen reader, never also a button.
        checked: value ?? false,
        mixed: value == null,
        builder: (context, states, _) {
          final on = value != false;
          final focused = states.contains(WidgetState.focused);
          final off = states.contains(WidgetState.disabled);
          final box = AnimatedLookSurface(
            face: LookFace(
              fill: on ? (off ? c.mutedInk : c.accent) : c.surface,
              rule: focused ? c.ink : (on ? c.accent : c.rule),
              ruleWidth: focused ? 2 : 1,
              foreground: c.onAccent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme.radius / 2),
            ),
            child: SizedBox.square(
              dimension: 20,
              child: CustomPaint(painter: _Tick(value, c.onAccent)),
            ),
          );
          if (label == null) return box;
          return MetaData(
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                box,
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label!,
                    style: theme.body.copyWith(color: off ? c.mutedInk : c.ink),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<bool?>>.has('onChanged', onChanged))
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'));
  }
}

class _Tick extends CustomPainter {
  _Tick(this.value, this.color);

  final bool? value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (value == false) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (value == null) {
      canvas.drawLine(
        Offset(size.width * .28, size.height / 2),
        Offset(size.width * .72, size.height / 2),
        paint,
      );
      return;
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .26, size.height * .52)
        ..lineTo(size.width * .43, size.height * .69)
        ..lineTo(size.width * .75, size.height * .33),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Tick old) => old.value != value || old.color != color;
}

/// An on or off switch. A null [onChanged] disables it.
///
/// ```dart
/// LookSwitch(value: true, onChanged: (value) {}, semanticLabel: 'Wi-Fi')
/// ```
class LookSwitch extends StatelessWidget {
  /// A switch showing [value].
  const LookSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  /// Whether it is on.
  final bool value;

  /// Called with the next value; null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// What a screen reader calls it, when no label beside it names it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final c = theme.colors;
    final change = onChanged;
    return TapTargetPadding(
      child: RawButton(
        onPressed: change == null ? null : () => change(!value),
        // A switch says toggled, which drops the button role.
        toggled: value,
        semanticLabel: semanticLabel,
        builder: (context, states, _) {
          final focused = states.contains(WidgetState.focused);
          return AnimatedLookSurface(
            face: LookFace(
              fill: value ? c.accent : c.surface,
              rule: focused ? c.ink : (value ? c.accent : c.rule),
              ruleWidth: focused ? 2 : 1,
              foreground: value ? c.onAccent : c.mutedInk,
            ),
            shape: const StadiumBorder(),
            child: SizedBox(
              width: 40,
              height: 24,
              child: LookSpringBuilder(
                value: value ? 1 : 0,
                builder: (context, travel, thumb) => Align(
                  alignment: AlignmentDirectional.lerp(
                    AlignmentDirectional.centerStart,
                    AlignmentDirectional.centerEnd,
                    travel,
                  )!,
                  child: thumb,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Builder(
                    builder: (context) => DecoratedBox(
                      decoration: ShapeDecoration(
                        color: DefaultTextStyle.of(context).style.color,
                        shape: const CircleBorder(),
                      ),
                      child: const SizedBox.square(dimension: 16),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off'))
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged));
  }
}

/// One choice of a [LookRadioGroup].
@immutable
class LookRadioOption<T> {
  /// A choice standing for [value], saying [label].
  const LookRadioOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  /// What choosing it chooses.
  final T value;

  /// What it says.
  final String label;

  /// Whether it can be chosen.
  final bool enabled;
}

/// A set of choices of which one is chosen: Flutter's [RadioGroup], a
/// [RawRadio] per choice drawn in the look's hand, and ui_core's
/// [RadioGroupKeyboardFix] round them, so Tab, the arrows, right-to-left
/// rows and a chosen choice turned off answer as Flutter's own fixes make
/// them.
///
/// ```dart
/// LookRadioGroup<String>(
///   value: 'day',
///   onChanged: (value) {},
///   options: const [
///     LookRadioOption(value: 'day', label: 'Day'),
///     LookRadioOption(value: 'week', label: 'Week'),
///   ],
/// )
/// ```
class LookRadioGroup<T> extends StatelessWidget {
  /// A group choosing [value] among [options].
  const LookRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  /// The chosen value, or null for none yet.
  final T? value;

  /// Called with the value chosen; null shows the choice without offering
  /// it.
  final ValueChanged<T>? onChanged;

  /// The choices, in reading order.
  final List<LookRadioOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return RadioGroup<T>(
      groupValue: value,
      onChanged: (next) {
        if (change == null || next == null || next == value) return;
        // The look's haptic for a choice, from the table an app can swap.
        RawHaptics.of(context).selectionChanged?.call();
        change(next);
      },
      child: RadioGroupKeyboardFix<T>(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final option in options)
              _LookRadio<T>(
                key: ValueKey<T>(option.value),
                option: option,
                enabled: change != null && option.enabled,
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
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged));
  }
}

class _LookRadio<T> extends StatefulWidget {
  const _LookRadio({super.key, required this.option, required this.enabled});

  final LookRadioOption<T> option;
  final bool enabled;

  @override
  State<_LookRadio<T>> createState() => _LookRadioState<T>();
}

class _LookRadioState<T> extends State<_LookRadio<T>> {
  // RawRadio takes a node of its own; the radio owns it and disposes it.
  final FocusNode _node = FocusNode(debugLabel: 'LookRadio');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
    final c = theme.colors;
    return TapTargetPadding(
      alignment: AlignmentDirectional.centerStart,
      // One node: the radio and its words.
      child: MergeSemantics(
        child: RawRadio<T>(
          value: widget.option.value,
          mouseCursor: WidgetStateMouseCursor.clickable,
          toggleable: false,
          focusNode: _node,
          autofocus: false,
          groupRegistry: RadioGroup.maybeOf<T>(context),
          enabled: widget.enabled,
          builder: (context, radio) {
            final states = radio.states;
            final chosen = radio.value ?? false;
            final focused = states.contains(WidgetState.focused);
            final off = states.contains(WidgetState.disabled);
            // The whole choice takes the press, the gap between the mark
            // and the words too: the box a tap reaches is the box a screen
            // reader outlines.
            return MetaData(
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedLookSurface(
                    face: LookFace(
                      fill: c.surface,
                      rule: focused ? c.ink : (chosen ? c.accent : c.rule),
                      ruleWidth: focused || chosen ? 2 : 1,
                      foreground: off ? c.mutedInk : c.accent,
                    ),
                    shape: const CircleBorder(),
                    child: SizedBox.square(
                      dimension: 20,
                      child: Center(
                        child: LookSpringBuilder(
                          value: chosen ? 1 : 0,
                          builder: (context, scale, dot) =>
                              Transform.scale(scale: scale, child: dot),
                          child: Builder(
                            builder: (context) => DecoratedBox(
                              decoration: ShapeDecoration(
                                color: DefaultTextStyle.of(context).style.color,
                                shape: const CircleBorder(),
                              ),
                              child: const SizedBox.square(dimension: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.option.label,
                    style: theme.body.copyWith(color: off ? c.mutedInk : c.ink),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// What a [LookDrawnChoice] draws: the page's own picture of the choice,
/// chosen or not, in its [states].
typedef LookChoiceDrawing = Widget Function(
  BuildContext context,
  bool chosen,
  Set<WidgetState> states,
);

/// One choice of a [LookDrawnChoices].
@immutable
class LookDrawnChoice<T> {
  /// A choice standing for [value], drawn by [drawing] and named [label].
  const LookDrawnChoice({
    required this.value,
    required this.label,
    required this.drawing,
  });

  /// What choosing it chooses.
  final T value;

  /// What a screen reader calls it.
  final String label;

  /// Its picture, chosen or not.
  final LookChoiceDrawing drawing;
}

/// Choices a page draws itself (a converted page's own picture of each
/// choice) with a radio group's behaviour, the look's [LookRadioGroup]
/// without its mark: Flutter's [RadioGroup], a [RawRadio] per drawing and
/// [RadioGroupKeyboardFix] round them. Tab stops once, the arrows choose
/// and wrap (right to left too), and each choice is read as a radio.
class LookDrawnChoices<T> extends StatelessWidget {
  /// A row choosing [value] among [choices].
  const LookDrawnChoices({
    super.key,
    required this.value,
    required this.onChanged,
    required this.choices,
  });

  /// The chosen value.
  final T value;

  /// Called with the value chosen.
  final ValueChanged<T> onChanged;

  /// The choices, in reading order.
  final List<LookDrawnChoice<T>> choices;

  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: (next) {
      if (next != null && next != value) onChanged(next);
    },
    child: RadioGroupKeyboardFix<T>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in choices)
            _DrawnChoice<T>(key: ValueKey<T>(choice.value), choice: choice),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
  }
}

class _DrawnChoice<T> extends StatefulWidget {
  const _DrawnChoice({super.key, required this.choice});

  final LookDrawnChoice<T> choice;

  @override
  State<_DrawnChoice<T>> createState() => _DrawnChoiceState<T>();
}

class _DrawnChoiceState<T> extends State<_DrawnChoice<T>> {
  final FocusNode _node = FocusNode(debugLabel: 'LookDrawnChoice');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TapTargetPadding(
    // One node: the radio, named for its choice.
    child: MergeSemantics(
      child: Semantics(
        label: widget.choice.label,
        child: RawRadio<T>(
          value: widget.choice.value,
          mouseCursor: WidgetStateMouseCursor.clickable,
          toggleable: false,
          focusNode: _node,
          autofocus: false,
          groupRegistry: RadioGroup.maybeOf<T>(context),
          enabled: true,
          // The page's drawing on a box hit all over: a press between its
          // painted parts still chooses it. The label names it; the drawing's
          // own words are not read.
          builder: (context, radio) => MetaData(
            behavior: HitTestBehavior.opaque,
            child: ExcludeSemantics(
              child: widget.choice.drawing(
                context,
                radio.value ?? false,
                radio.states,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
