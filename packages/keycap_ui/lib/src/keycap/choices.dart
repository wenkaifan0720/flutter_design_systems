/// Keycap's choices are latching keys. A checkbox is a small key that
/// latches down with a tick printed on it; a radio a round one with a dot;
/// a switch a small key sliding along a slot cut into the case; a segmented
/// button and a tab bar a row of keys, the chosen one latched.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'cap.dart';
import 'internal/group_radio.dart';
import 'internal/row_toggle.dart';
import 'internal/spring_value.dart';
import 'lists.dart';
import 'theme.dart';

/// A checkbox: a small key that latches down when checked, a tick printed
/// on it (a bar when [tristate] and mixed).
///
/// ```dart
/// KeycapCheckbox(value: images, onChanged: (v) => setState(() => images = v!))
/// ```
class KeycapCheckbox extends StatelessWidget {
  /// A checkbox.
  const KeycapCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(tristate || value != null);

  /// Checked, unchecked, or (with [tristate]) null for mixed.
  final bool? value;

  /// Called with the next value; null turns the checkbox off.
  final ValueChanged<bool?>? onChanged;

  /// Whether null (mixed) is one of its values.
  final bool tristate;

  /// What it checks, for a screen reader.
  final String? semanticLabel;

  /// The key's focus node.
  final FocusNode? focusNode;

  /// Whether the key takes focus when it first appears.
  final bool autofocus;

  /// Overrides for the key, over [KeycapThemeData.toggleStyle].
  final KeycapStyle? style;

  /// The key's side.
  static const double size = 24;

  bool? get _next => switch (value) {
    false => true,
    true => tristate ? null : false,
    null => false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return RawButton(
      onPressed: onChanged == null ? null : () => onChanged!(_next),
      focusNode: focusNode,
      autofocus: autofocus,
      button: false,
      checked: value ?? false,
      mixed: value == null,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) => TapTargetPadding(
        child: KeycapToggleKey(
          states: states,
          latched: value != false,
          style: style,
          shape: KeycapToggleShape.square,
          legend: (color, t) => CustomPaint(
            size: const Size.square(14),
            painter: _TickPainter(t, color, mixed: value == null),
          ),
          theme: theme,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// The shapes of a [KeycapToggleKey].
enum KeycapToggleShape {
  /// A checkbox's small square key.
  square,

  /// A radio's round key.
  round,
}

/// A small latching key: a checkbox's or a radio's, public for a part of
/// your own that latches. Up and alpha when off; latched part way down in
/// the modifier plastic when on, its [legend] fading in on it.
///
/// ```dart
/// KeycapToggleKey(theme: theme, states: states, latched: on, shape: KeycapToggleShape.round, legend: (color, t) => dot)
/// ```
class KeycapToggleKey extends StatelessWidget {
  /// A small latching key.
  const KeycapToggleKey({
    super.key,
    required this.theme,
    required this.states,
    required this.latched,
    required this.shape,
    required this.legend,
    this.style,
  });

  /// The theme it is drawn in.
  final KeycapThemeData theme;

  /// Its pressable's states.
  final Set<WidgetState> states;

  /// Whether it is latched down (on).
  final bool latched;

  /// Square or round.
  final KeycapToggleShape shape;

  /// The legend, in [Color] and faded in by the double (0 off, 1 on).
  final Widget Function(Color color, double t) legend;

  /// Overrides for the key, over [KeycapThemeData.toggleStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final layered = DesignStyleOf([style, theme.toggleStyle], states);
    const side = KeycapCheckbox.size;
    var face = keycapKeyFace(
      theme,
      KeycapKind.alpha,
      states,
      latched: latched,
      radius: shape == KeycapToggleShape.round
          ? side / 2
          : KeycapMetrics.smallKeyRadius,
    );
    face = layered.on(face);
    return SizedBox.square(
      dimension: side,
      child: AnimatedKeycapCap(
        face: face,
        walls: KeycapMetrics.walls(side),
        child: Center(
          child: KeycapSpringValue(
            value: latched ? 1 : 0,
            spring: KeycapMotion.colour,
            spatial: false,
            builder: (context, t, _) => legend(face.legend, t.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.t, this.color, {required this.mixed});

  final double t;
  final Color color;
  final bool mixed;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    if (mixed) {
      canvas.drawLine(Offset(w * 0.2, h / 2), Offset(w * 0.8, h / 2), paint);
      return;
    }
    // The tick draws itself in as it fades: short stroke, then long.
    final path = Path()
      ..moveTo(w * 0.14, h * 0.52)
      ..lineTo(w * 0.40, h * 0.76)
      ..lineTo(w * 0.86, h * 0.26);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.t != t || old.color != color || old.mixed != mixed;
}

/// A radio: a round key that latches down, a dot printed on it, when its
/// [value] is the group's. Most screens want [KeycapRadioGroup].
///
/// ```dart
/// KeycapRadio<String>(value: 'md', groupValue: format, onChanged: setFormat, semanticLabel: 'Markdown')
/// ```
class KeycapRadio<T> extends StatelessWidget {
  /// A radio for [value].
  const KeycapRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.style,
  });

  /// What this radio chooses.
  final T value;

  /// What the group has chosen.
  final T? groupValue;

  /// Called with [value] when it is chosen; null turns it off.
  final ValueChanged<T>? onChanged;

  /// What it chooses, for a screen reader.
  final String? semanticLabel;

  /// The key's focus node.
  final FocusNode? focusNode;

  /// Overrides for the key, over [KeycapThemeData.toggleStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final chosen = value == groupValue;
    return RawButton(
      onPressed: onChanged == null ? null : () => onChanged!(value),
      focusNode: focusNode,
      button: false,
      checked: chosen,
      inMutuallyExclusiveGroup: true,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) => TapTargetPadding(
        child: KeycapToggleKey(
          theme: theme,
          states: states,
          latched: chosen,
          style: style,
          shape: KeycapToggleShape.round,
          legend: (color, t) => _Dot(color: color, t: t),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(DiagnosticsProperty<T>('groupValue', groupValue));
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 8,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: color.a * t),
      ),
    ),
  );
}

/// A group of radios, each a round key with its words beside it. Tab
/// reaches the group once, at its choice (or its first open option); the
/// arrows choose the next or the previous, wrap, pass over options that are
/// off and run the other way right to left. A screen reader hears each row
/// as a radio named by its words. Built on Flutter's `RadioGroup`, each row
/// a `RawRadio`, with ui_core's `RadioGroupKeyboardFix` inside.
///
/// ```dart
/// KeycapRadioGroup<String>(options: const ['A4', 'Letter'], value: paper, labelOf: (p) => p, onChanged: setPaper)
/// ```
class KeycapRadioGroup<T> extends StatelessWidget {
  /// A group over [options].
  const KeycapRadioGroup({
    super.key,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
    this.isEnabled,
    this.direction = Axis.vertical,
    this.semanticLabel,
    this.style,
  });

  /// The choices.
  final List<T> options;

  /// The chosen one.
  final T? value;

  /// A choice's words.
  final String Function(T value) labelOf;

  /// Called with a new choice; null turns the group off.
  final ValueChanged<T>? onChanged;

  /// Whether a choice can be chosen.
  final bool Function(T value)? isEnabled;

  /// A column of choices, or a row that wraps.
  final Axis direction;

  /// The group's name, for a screen reader.
  final String? semanticLabel;

  /// Overrides for the keys, over [KeycapThemeData.toggleStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final change = onChanged;
    final rows = [
      // Each row is one radio named by its words: the key and the words take
      // the press together.
      for (final option in options)
        KeycapGroupRadio<T>(
          key: ObjectKey(option),
          value: option,
          enabled: change != null && (isEnabled?.call(option) ?? true),
          label: labelOf(option),
          builder: (context, states) {
            final off = states.contains(WidgetState.disabled);
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.controlHeight),
              child: Row(
                mainAxisSize: direction == Axis.vertical
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  KeycapToggleKey(
                    theme: theme,
                    states: states,
                    latched: states.contains(WidgetState.selected),
                    style: style,
                    shape: KeycapToggleShape.round,
                    legend: (color, t) => _Dot(color: color, t: t),
                  ),
                  const SizedBox(width: KeycapSpacing.medium),
                  Flexible(
                    child: DesignCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: Text(
                        labelOf(option),
                        style: theme.textTheme.body.copyWith(
                          color: off ? c.inkDisabled : c.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    ];
    return KeycapGroupRadios<T>(
      value: value,
      onChanged: (choice) {
        if (choice != null) change?.call(choice);
      },
      semanticLabel: semanticLabel,
      child: direction == Axis.vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            )
          : Wrap(spacing: KeycapSpacing.large, children: rows),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// A switch: a small 1.25u key, its sculpt showing, in a slot cut into the
/// case. On, the key slides to the slot's end and the slot's floor darkens
/// to the modifier plastic, as a lit key's housing does.
///
/// ```dart
/// KeycapSwitch(value: spellcheck, onChanged: (v) => setState(() => spellcheck = v), semanticLabel: 'Check spelling')
/// ```
class KeycapSwitch extends StatelessWidget {
  /// A switch.
  const KeycapSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// On or off.
  final bool value;

  /// Called with the new value; null turns the switch off.
  final ValueChanged<bool>? onChanged;

  /// What it switches, for a screen reader.
  final String? semanticLabel;

  /// The switch's focus node.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Overrides, over [KeycapThemeData.toggleStyle]: [DesignStyle.fill]
  /// the key's plastic, [DesignStyle.edge] the slot's edge.
  final KeycapStyle? style;

  /// The slot's width.
  static const double width = 56;

  /// The slot's height.
  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    return RawButton(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      focusNode: focusNode,
      autofocus: autofocus,
      button: false,
      toggled: value,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.toggleStyle], states);
        final off = states.contains(WidgetState.disabled);
        final focused = states.contains(WidgetState.focused);
        final light = c.brightness == Brightness.light;
        // On: the slot's floor turns the modifier's plastic, dark enough to
        // hold 3:1 against the well's floor beside it.
        final onFloor = light
            ? Color.lerp(c.modifier.front, c.ink, 0.32)!
            : Color.lerp(c.modifier.top, c.ink, 0.35)!;
        var key = keycapKeyFace(
          theme,
          KeycapKind.alpha,
          states.difference({WidgetState.focused}),
          radius: KeycapMetrics.smallKeyRadius,
        );
        key = layered.on(key);
        const inset = 2.0;
        const keySide = height - inset * 2;
        // A 1.25u key: a quarter wider than it is deep.
        const keyWidth = keySide * 1.25;
        return TapTargetPadding(
          child: SizedBox(
            width: width,
            height: height,
            child: KeycapSpringValue(
              value: value ? 1 : 0,
              spring: KeycapMotion.latch,
              builder: (context, t, _) {
                final p = t.clamp(0.0, 1.0);
                final floor = Color.lerp(c.well, onFloor, p)!;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: KeycapWell(
                        radius: BorderRadius.circular(
                          KeycapMetrics.smallKeyRadius + inset,
                        ),
                        floor: off ? Color.lerp(floor, c.ground, 0.5) : floor,
                        rim: focused ? c.focus : null,
                        clip: false,
                      ),
                    ),
                    PositionedDirectional(
                      top: inset,
                      start: inset + (width - keyWidth - inset * 2) * t,
                      child: SizedBox(
                        width: keyWidth,
                        height: keySide,
                        child: AnimatedKeycapCap(
                          face: key,
                          walls: KeycapMetrics.walls(keySide),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off'))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

/// One key in a [KeycapSegmentedButton] or a [KeycapTabBar].
///
/// ```dart
/// const KeycapSegment(value: 'all', label: 'All notes')
/// ```
@immutable
class KeycapSegment<T> {
  /// A segment.
  const KeycapSegment({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  /// What choosing it gives.
  final T value;

  /// Its legend.
  final String label;

  /// A glyph before the legend.
  final Widget? icon;

  /// What a screen reader says, when [label] is not enough.
  final String? semanticLabel;
}

/// A row of keys a keyboard's pitch apart; the chosen one ([selected])
/// latched down in the modifier plastic, its legend going down with it.
/// One choice by default, as Material's `SegmentedButton`; several with
/// [multiSelectionEnabled]. With one choice the keys are radios of one
/// group: Tab reaches the row once, at its choice, and the arrows choose
/// the next or the previous key and wrap. Below 600 wide the keys share the
/// row's width; from 600 each hugs its legend. A legend never cuts short:
/// when the keys' legends (long words, large text) don't fit the row, the
/// keys reflow onto more rows, each whole.
///
/// ```dart
/// KeycapSegmentedButton<String>(segments: sorts, selected: {sort}, onSelectionChanged: (s) => setSort(s.first))
/// ```
class KeycapSegmentedButton<T> extends StatelessWidget {
  /// A row of keys.
  const KeycapSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.expand,
    this.semanticLabel,
    this.style,
  }) : assert(segments.length >= 2);

  /// The keys.
  final List<KeycapSegment<T>> segments;

  /// What is chosen.
  final Set<T> selected;

  /// Called with the new choice; null turns the row off.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether several keys can be latched at once.
  final bool multiSelectionEnabled;

  /// Whether every key can be let up.
  final bool emptySelectionAllowed;

  /// Whether the keys share the row's width; by the screen's width when
  /// null (below 600 they do).
  final bool? expand;

  /// The row's name, for a screen reader.
  final String? semanticLabel;

  /// Overrides for the keys, over [KeycapThemeData.keyRowStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final wide = expand ?? MediaQuery.sizeOf(context).width < 600;
    String labelOf(T v) {
      final s = segments.firstWhere((s) => s.value == v);
      return s.semanticLabel ?? s.label;
    }

    Widget keyFor(T v, Set<WidgetState> states) => KeycapRowKey(
      theme: theme,
      states: states,
      latched: states.contains(WidgetState.selected),
      segment: segments.firstWhere((s) => s.value == v),
      style: style,
    );

    Widget layout(BuildContext context, List<Widget> keys) => LayoutBuilder(
      builder: (context, box) {
        final need = [
          for (final s in segments) _rowKeyWidth(context, theme, s, style),
        ];
        final gaps = KeycapMetrics.keyGap * (keys.length - 1);
        final fits =
            !box.maxWidth.isFinite ||
            (wide
                ? need.reduce(math.max) * keys.length + gaps <= box.maxWidth
                : need.fold(0.0, (a, b) => a + b) + gaps <= box.maxWidth);
        if (!fits) {
          return Wrap(
            spacing: KeycapMetrics.keyGap,
            runSpacing: KeycapMetrics.keyGap,
            children: keys,
          );
        }
        return Row(
          mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (final (i, k) in keys.indexed) ...[
              if (i > 0) const SizedBox(width: KeycapMetrics.keyGap),
              wide ? Expanded(child: k) : k,
            ],
          ],
        );
      },
    );
    final options = [for (final s in segments) s.value];
    if (multiSelectionEnabled) {
      return RawSegmentedButton<T>(
        options: options,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
        multiSelectionEnabled: true,
        emptySelectionAllowed: emptySelectionAllowed,
        labelOf: labelOf,
        semanticLabel: semanticLabel,
        direction: Axis.horizontal,
        minimumSize: Size.zero,
        layoutBuilder: layout,
        itemBuilder: (context, v, states) => keyFor(v, states),
      );
    }
    // One choice: the keys are radios of one group, as Flutter's RadioGroup
    // makes them (one Tab stop, the arrows choose).
    final change = onSelectionChanged;
    final chosen = selected.isEmpty ? null : selected.first;
    return KeycapGroupRadios<T>(
      value: chosen,
      onChanged: (v) {
        if (v != null) {
          change?.call({v});
        } else if (emptySelectionAllowed) {
          change?.call(<T>{});
        }
      },
      semanticLabel: semanticLabel,
      child: Builder(
        builder: (context) => layout(context, [
          for (final v in options)
            KeycapGroupRadio<T>(
              key: ObjectKey(v),
              value: v,
              enabled: change != null,
              // The chosen key lets up when the row may be left empty.
              toggleable: emptySelectionAllowed,
              label: labelOf(v),
              builder: (context, states) => keyFor(v, states),
            ),
        ]),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('selected', selected))
      ..add(IntProperty('segments', segments.length));
  }
}

/// One key of a row (a segmented button's, a tab bar's), public for a row
/// of your own.
///
/// ```dart
/// KeycapRowKey(theme: theme, states: states, latched: chosen, segment: segment)
/// ```
class KeycapRowKey extends StatelessWidget {
  /// A key in a row.
  const KeycapRowKey({
    super.key,
    required this.theme,
    required this.states,
    required this.latched,
    required this.segment,
    this.style,
  });

  /// The theme it is drawn in.
  final KeycapThemeData theme;

  /// Its pressable's states.
  final Set<WidgetState> states;

  /// Whether it is latched (chosen).
  final bool latched;

  /// Its legend.
  final KeycapSegment<Object?> segment;

  /// Overrides, over [KeycapThemeData.keyRowStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final layered = DesignStyleOf(
      [style, theme.keyRowStyle],
      {...states, if (latched) WidgetState.selected},
    );
    final height = KeycapMetrics.grown(
      context,
      layered.minimumSize?.height ?? theme.controlHeight - 4,
      theme.textTheme.label,
    );
    var face = keycapKeyFace(theme, KeycapKind.alpha, states, latched: latched);
    face = layered.on(face);
    final words = theme.textTheme.label
        .merge(layered.textStyle)
        .copyWith(
          color: face.legend,
          fontWeight: latched ? FontWeight.w600 : FontWeight.w500,
        );
    return TapTargetPadding(
      child: SizedBox(
        height: height,
        child: AnimatedKeycapCap(
          face: face,
          walls: KeycapMetrics.walls(height),
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(horizontal: KeycapSpacing.regular),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (segment.icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(size: 18, color: face.legend),
                    child: segment.icon!,
                  ),
                  const SizedBox(width: KeycapSpacing.small),
                ],
                Flexible(
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(
                      segment.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: words,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// The width a key in a row needs to print its legend whole: its words at
// the window's text size, as bold as when latched, its glyph, its padding
// and its side walls at their widest.
double _rowKeyWidth(
  BuildContext context,
  KeycapThemeData theme,
  KeycapSegment<Object?> segment,
  KeycapStyle? style,
) {
  final layered = DesignStyleOf([style, theme.keyRowStyle], <WidgetState>{});
  final direction = Directionality.of(context);
  final pad =
      layered.padding(direction) ??
      const EdgeInsets.symmetric(horizontal: KeycapSpacing.regular);
  final words = TextPainter(
    text: TextSpan(
      text: segment.label,
      style: theme.textTheme.label
          .merge(layered.textStyle)
          .copyWith(fontWeight: FontWeight.w600),
    ),
    textDirection: direction,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = words.width.ceilToDouble();
  words.dispose();
  return width +
      pad.horizontal +
      2 * KeycapMetrics.walls(double.infinity).side +
      (segment.icon != null ? 18 + KeycapSpacing.small : 0);
}

/// A tab bar: a row of keys, the current tab's latched. Below 600 wide the
/// keys share the row; from 600 (or when a legend would not fit its share)
/// each hugs its legend and the row scrolls. The arrows move
/// between tabs and choose as they go. Built on ui_core's `RawTabBar`.
///
/// ```dart
/// KeycapTabBar<String>(tabs: const [KeycapSegment(value: 'notes', label: 'Notes'), KeycapSegment(value: 'tags', label: 'Tags')], value: tab, onChanged: setTab)
/// ```
class KeycapTabBar<T> extends StatelessWidget {
  /// A tab bar.
  const KeycapTabBar({
    super.key,
    required this.tabs,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.style,
  }) : assert(tabs.length >= 2);

  /// The tabs.
  final List<KeycapSegment<T>> tabs;

  /// The current tab's value.
  final T value;

  /// Called with the tab chosen.
  final ValueChanged<T>? onChanged;

  /// The bar's name, for a screen reader.
  final String? semanticLabel;

  /// Overrides for the keys, over [KeycapThemeData.keyRowStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final index = tabs.indexWhere((t) => t.value == value);
    return _TabStrip<T>(
      tabs: tabs,
      index: index < 0 ? 0 : index,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      style: style,
      hug: MediaQuery.sizeOf(context).width >= 600,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('tabs', tabs.length));
  }
}

class _TabStrip<T> extends StatefulWidget {
  const _TabStrip({
    required this.tabs,
    required this.index,
    required this.onChanged,
    required this.semanticLabel,
    required this.style,
    required this.hug,
  });

  final List<KeycapSegment<T>> tabs;
  final int index;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;
  final KeycapStyle? style;
  final bool hug;

  @override
  State<_TabStrip<T>> createState() => _TabStripState<T>();
}

class _TabStripState<T> extends State<_TabStrip<T>>
    with TickerProviderStateMixin {
  late RawTabController _controller = _make();

  RawTabController _make() => RawTabController(
    length: widget.tabs.length,
    initialIndex: widget.index,
    vsync: this,
    dampingRatio: KeycapMotion.latch.dampingRatio,
    stiffness: KeycapMotion.latch.stiffness,
  )..addListener(_chosen);

  void _chosen() {
    final i = _controller.index;
    if (i != widget.index) widget.onChanged?.call(widget.tabs[i].value);
  }

  @override
  void didUpdateWidget(_TabStrip<T> old) {
    super.didUpdateWidget(old);
    if (widget.tabs.length != _controller.length) {
      final was = _controller..removeListener(_chosen);
      _controller = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => was.dispose());
    } else if (widget.index != _controller.index) {
      _controller.animateTo(widget.index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hug) return _strip(context, true);
    // Sharing the row cuts no legend short: past its share, each hugs.
    return LayoutBuilder(
      builder: (context, box) {
        final theme = KeycapTheme.of(context);
        final share =
            (box.maxWidth - KeycapMetrics.keyGap * (widget.tabs.length - 1)) /
            widget.tabs.length;
        final fits = widget.tabs.every(
          (s) => _rowKeyWidth(context, theme, s, widget.style) <= share,
        );
        return _strip(context, !fits);
      },
    );
  }

  Widget _strip(BuildContext context, bool hug) {
    final theme = KeycapTheme.of(context);
    final bar = RawTabBar(
      controller: _controller,
      semanticLabel: widget.semanticLabel,
      isScrollable: hug,
      tabs: [
        for (final s in widget.tabs)
          RawTab(
            label: s.semanticLabel ?? s.label,
            enabled: widget.onChanged != null,
          ),
      ],
      tabBuilder: (context, tab, details) => Padding(
        padding: EdgeInsetsDirectional.only(
          start: details.index == 0 ? 0 : KeycapMetrics.keyGap / 2,
          end: details.index == details.count - 1
              ? 0
              : KeycapMetrics.keyGap / 2,
        ),
        child: KeycapRowKey(
          theme: theme,
          states: details.states,
          latched: details.index == _controller.index,
          segment: widget.tabs[details.index],
          style: widget.style,
        ),
      ),
    );
    if (!hug) return bar;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: bar,
    );
  }
}

/// A row that is a switch: its [title] (and [subtitle]) and a
/// [KeycapSwitch] at its end, the whole row taking the press, as Material's
/// `SwitchListTile`. A screen reader hears one switch named by the row, and
/// the row it outlines is the row a finger reaches.
///
/// ```dart
/// KeycapSwitchListTile(title: 'Check spelling', value: spellcheck, onChanged: (v) => setState(() => spellcheck = v))
/// ```
class KeycapSwitchListTile extends StatelessWidget {
  /// A switch row reading [title].
  const KeycapSwitchListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.maxSubtitleLines = 1,
  });

  /// The row's words: the switch's name.
  final String title;

  /// A supporting line.
  final String? subtitle;

  /// A glyph at its start.
  final Widget? leading;

  /// Whether it is on.
  final bool value;

  /// Called with the new value; null turns the row off.
  final ValueChanged<bool>? onChanged;

  /// How many lines the [subtitle] may take.
  final int maxSubtitleLines;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return MergeSemantics(
      child: Semantics(
        toggled: value,
        child: KeycapRowToggle(
          value: value,
          child: KeycapListTile(
            title: title,
            subtitle: subtitle,
            leading: leading,
            maxSubtitleLines: maxSubtitleLines,
            showChevron: false,
            enabled: change != null,
            onTap: change == null ? null : () => change(!value),
            trailing: ExcludeSemantics(
              child: KeycapSwitch(value: value, onChanged: change),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off'));
  }
}
