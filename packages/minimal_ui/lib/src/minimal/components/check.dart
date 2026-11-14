import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// Minimal's checkbox: a 16 px square with small corners that fills with
/// the accent and a drawn tick when [value] is true — a checklist item, an
/// agreement, a row picked for a bulk action. (A task's status glyph — the
/// dashed ring, the half, the filled check — is `MinimalStatusIcon`'s job.)
///
/// It is not [MinimalSwitch]: a switch applies a setting the moment it moves;
/// a check records a choice or a fact. The fill and the tick cross in
/// [MinimalMotion.fast] with no bounce and no scale.
///
/// A null [onChanged] disables it, as Flutter's `Checkbox`: it dims and
/// swallows taps. A tick that is a picture rather than a control (a row
/// that is itself the control, a finished line's tick) is a
/// [MinimalCheckMark]. Give a check that stands without words a [label].
/// The hit area pads out to 44.
///
/// [style] dresses one check, `components.checkbox` every one, resolved
/// with [WidgetState.selected] when ticked: fill, foreground (the tick),
/// edge or side, overlay and shape (else `shapes.mark`, scaled with
/// [size]). `t.rim` is its edge.
///
/// ```dart
/// MinimalCheckbox(value: done, label: 'Meditate', onChanged: (v) => setState(() => done = v))
/// ```
class MinimalCheckbox extends StatelessWidget {
  /// A checkbox showing [value].
  const MinimalCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 16,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether it is checked.
  final bool value;

  /// Reports the new value; null disables the check.
  final ValueChanged<bool>? onChanged;

  /// The square's side; 16 in rows and forms, 20 for a lone agreement.
  final double size;

  /// What is being checked, announced (never printed).
  final String? label;

  /// This check's style, over `components.checkbox`.
  final MinimalStyle? style;

  /// Its focus node, for a caller that moves focus to it (the first
  /// agreement still to tick); null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final onChanged = this.onChanged;
    final layers = <MinimalStyle?>[style, t.components.checkbox];
    return MinimalPressable(
      onPressed: onChanged == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged(!value);
            },
      enabled: onChanged != null,
      shape: _ownShape(t, size),
      style: MinimalStyleOf(layers, const {}).press,
      semanticLabel: label,
      checked: value,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) => _CheckFace(
        value: value,
        size: size,
        layers: layers,
        states: {...states, if (value) WidgetState.selected},
      ),
    );
  }
}

/// A checkbox's square and tick as a picture, not a control: a row that is
/// itself the control (a picker's option, a bulk-select row) shows its
/// state with one, and so does a finished line's tick. It renders at full
/// ink, takes no press and no focus, and lets taps through to what holds
/// it; [label] announces it. It wears `components.checkbox` as
/// [MinimalCheckbox] does, so the two read as one part.
///
/// ```dart
/// MinimalCheckMark(value: picked)
/// ```
class MinimalCheckMark extends StatelessWidget {
  /// A check mark showing [value].
  const MinimalCheckMark({
    super.key,
    required this.value,
    this.size = 16,
    this.label,
    this.style,
  });

  /// Whether it is ticked.
  final bool value;

  /// The square's side.
  final double size;

  /// What it marks, announced (never printed).
  final String? label;

  /// This mark's style, over `components.checkbox`.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Semantics(
      checked: value,
      label: label,
      child: _CheckFace(
        value: value,
        size: size,
        layers: [style, t.components.checkbox],
        states: {if (value) WidgetState.selected},
      ),
    );
  }
}

/// The square's own outline: `shapes.mark`, scaled with its side.
OutlinedBorder _ownShape(MinimalThemeData t, double size) =>
    minimalScaled(t.shapes.mark, size / 16);

/// The square and its tick for [states]; the fill and the tick cross in
/// [MinimalMotion.fast].
class _CheckFace extends StatelessWidget {
  const _CheckFace({
    required this.value,
    required this.size,
    required this.layers,
    required this.states,
  });

  final bool value;
  final double size;
  final List<MinimalStyle?> layers;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final duration = context.minimalStill ? Duration.zero : MinimalMotion.fast;
    final so = MinimalStyleOf(layers, states);
    return AnimatedContainer(
      duration: duration,
      curve: MinimalMotion.out,
      width: size,
      height: size,
      decoration: minimalFrame(
        so.shape ?? _ownShape(t, size),
        fill: so.fill ?? (value ? t.primary : t.card),
        // The edge keeps its width in both states so the square never
        // changes size as it fills. Idle, it is the control edge (3:1 on
        // every ground), never a hairline an empty box would vanish into.
        side: so.rim(value ? t.primary : t.input, t.rim),
      ),
      child: AnimatedOpacity(
        opacity: value ? 1 : 0,
        duration: duration,
        curve: MinimalMotion.out,
        child: CustomPaint(
          painter: _TickPainter(
            so.foreground ?? t.primaryForeground,
            t.iconStroke,
          ),
          size: Size.square(size),
        ),
      ),
    );
  }
}

/// The tick, drawn rather than borrowed so its corner lands where the square
/// needs it at any [MinimalCheckbox.size], stroked at the theme's icon weight.
class _TickPainter extends CustomPainter {
  const _TickPainter(this.color, this.stroke);

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.26, h * 0.52)
      ..lineTo(w * 0.43, h * 0.68)
      ..lineTo(w * 0.75, h * 0.34);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        // Lucide's 1.75 stroke is drawn on a 24 grid; a 16 px square wants
        // it at about that weight, so it scales with the side.
        ..strokeWidth = stroke * w / 14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) =>
      old.color != color || old.stroke != stroke;
}
