import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/styled.dart';
import '../shapes.dart';
import '../theme.dart';
import 'pressable.dart';

/// Minimal's on/off switch for a preference: a compact 32 × 18 track with
/// a 14 px thumb, the accent when on and the strong hairline when off. It
/// sits in a row's trailing slot beside the words that name it; give a
/// standalone switch a [label] so a screen reader can say what it turns on.
///
/// Tap or Enter/Space flips it, and a short horizontal drag throws the
/// thumb. The thumb travels in [MinimalMotion.fast] with no overshoot, and in
/// no time at all under `MediaQuery.disableAnimations`. A null [onChanged]
/// is a disabled switch: dimmed, and it swallows taps. The hit area pads out
/// to 44.
///
/// `showLabel: true` is the labelled register for a switch that stands on
/// its own (a sheet footer's `Create another`): the [label] prints after
/// the track in the small body register's quiet ink, and the switch and
/// the words are one control — a tap on either flips it.
///
/// [style] dresses one switch, `components.switchTheme` every one, resolved
/// with [WidgetState.selected] when on: fill (the track), foreground (the
/// thumb), edge or side (the track's rim), overlay and shape (the track;
/// the thumb takes the same outline 2 px inside it). The track is a capsule
/// whatever `shapes` says: a switch is round by meaning.
///
/// ```dart
/// MinimalSwitch(value: remind, label: 'Reminders', onChanged: (v) => setState(() => remind = v))
/// ```
class MinimalSwitch extends StatefulWidget {
  /// A switch showing [value].
  const MinimalSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.showLabel = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : assert(!showLabel || label != null, 'showLabel prints the label');

  /// Whether it is on.
  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// What the switch turns on: announced, and printed beside the track
  /// with [showLabel].
  final String? label;

  /// Print [label] after the track, the switch and the words one control.
  final bool showLabel;

  /// This switch's style, over `components.switchTheme`.
  final MinimalStyle? style;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  State<MinimalSwitch> createState() => _MinimalSwitchState();
}

// The track and thumb, per the mockup's mini switch grown to the lead's
// 32 × 18: 2 px of track shows around the thumb.
const double _trackWidth = 32;
const double _trackHeight = 18;
const double _inset = 2;
const double _thumb = _trackHeight - 2 * _inset;
const double _travel = _trackWidth - _thumb - 2 * _inset;

class _MinimalSwitchState extends State<MinimalSwitch> {
  /// The thumb's position (0 off, 1 on) while a drag holds it.
  double? _drag;

  void _commit(bool value) {
    setState(() => _drag = null);
    final onChanged = widget.onChanged;
    if (onChanged != null && value != widget.value) {
      HapticFeedback.selectionClick();
      onChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final instant = context.minimalStill;
    final duration = instant ? Duration.zero : MinimalMotion.fast;
    final fraction = _drag ?? (widget.value ? 1.0 : 0.0);
    final on = fraction >= 0.5;
    // In light the thumb is always the paper — the mock's white knob, which
    // holds 3:1 on every light accent and on the off track (ember's ink
    // onAccent would read as a hole in the track). In dark a white thumb
    // would glare and fail 3:1 on the pale accents, so on it is the accent's
    // dark ink; off, a ground-dark knob would read as a hole punched in the
    // grey track, so it takes the light ink.
    final thumb = t.isLightAppearance
        ? t.card
        : (on ? t.primaryForeground : t.foreground);
    final layers = <MinimalStyle?>[widget.style, t.components.switchTheme];
    // The track is a capsule by role (square under a square scale); the
    // thumb sits concentric inside it.
    final track = MinimalStyleOf(layers, const {}).shape ?? t.shapes.pill;

    return MinimalPressable(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onPressed: enabled ? () => _commit(!widget.value) : null,
      enabled: enabled,
      shape: widget.showLabel ? t.shapes.mark : track,
      style: MinimalStyleOf(layers, const {}).press,
      semanticLabel: widget.label,
      // On the pressable's own node: one control that is a button AND
      // announces its on/off state.
      toggled: widget.value,
      builder: (context, states) => _labelled(
        t,
        GestureDetector(
          // The pressable owns the tap and its semantics; this only throws
          // the thumb.
          excludeFromSemantics: true,
          onHorizontalDragStart: enabled
              ? (_) => setState(() => _drag = widget.value ? 1 : 0)
              : null,
          onHorizontalDragUpdate: enabled
              ? (d) => setState(
                  () => _drag =
                      ((_drag ?? fraction) +
                              (rtl ? -1 : 1) * d.delta.dx / _travel)
                          .clamp(0.0, 1.0),
                )
              : null,
          onHorizontalDragEnd: enabled
              ? (_) => _commit((_drag ?? fraction) >= 0.5)
              : null,
          onHorizontalDragCancel: () => setState(() => _drag = null),
          child: AnimatedContainer(
            duration: duration,
            curve: MinimalMotion.out,
            width: _trackWidth,
            height: _trackHeight,
            padding: const EdgeInsets.all(_inset),
            decoration: _track(t, layers, states, fraction, track),
            child: AnimatedAlign(
              // A dragged thumb follows the finger exactly.
              duration: _drag == null ? duration : Duration.zero,
              curve: MinimalMotion.out,
              alignment: Alignment((rtl ? -1 : 1) * (fraction * 2 - 1), 0),
              child: AnimatedContainer(
                duration: duration,
                curve: MinimalMotion.out,
                width: _thumb,
                height: _thumb,
                decoration: _knob(
                  MinimalStyleOf(layers, _at(states, on)),
                  thumb,
                  track,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [states] with the switch's own on or off in place of the pressable's.
  static Set<WidgetState> _at(Set<WidgetState> states, bool on) => {
    ...states.where((s) => s != WidgetState.selected),
    if (on) WidgetState.selected,
  };

  /// The track: off, the control edge (3:1 off every ground, so a switch
  /// that is off still reads as a switch); on, the accent; between them
  /// while a drag holds the thumb.
  static Decoration _track(
    MinimalThemeData t,
    List<MinimalStyle?> layers,
    Set<WidgetState> states,
    double fraction,
    OutlinedBorder track,
  ) {
    final off = MinimalStyleOf(layers, _at(states, false));
    final on = MinimalStyleOf(layers, _at(states, true));
    final now = fraction >= 0.5 ? on : off;
    final fill = Color.lerp(
      off.fill ?? t.input,
      on.fill ?? t.primary,
      fraction,
    );
    return minimalFrame(
      now.shape ?? track,
      fill: fill,
      side: now.rim(null, t.rim),
    );
  }

  /// The thumb: the track's outline [_inset] inside it, so the two stay
  /// concentric (a disc in a capsule, a square in a square track).
  static Decoration _knob(MinimalStyleOf so, Color own, OutlinedBorder track) {
    final shape = MinimalShapes.inset(so.shape ?? track, _inset);
    return minimalFrame(
      shape is StadiumBorder ? const CircleBorder() : shape,
      fill: so.foreground ?? own,
    );
  }

  /// The track alone, or in the labelled register the words after it.
  Widget _labelled(MinimalThemeData t, Widget track) {
    final label = widget.label;
    if (!widget.showLabel || label == null) return track;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        track,
        const MinimalGap(MinimalSpacing.s8),
        Flexible(
          // The words by their capitals, on the track's middle.
          child: ExcludeSemantics(
            child: minimalCapLabel(
              Text(
                label,
                style: t.bodySmall.c(t.mutedForeground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
