import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A setting that takes effect at once: its [labelText] and [helperText]
/// at the start, the switch at the end, the whole row the target. The
/// switch is a squared track inside the ink edge with a square knob: off,
/// the ink knob at the start carries a cross; on, the track fills with the
/// action colour and the knob, at the end, carries a tick, so the state
/// reads without the colour.
///
/// Use a [CivicCheckbox] for an answer a page sends later: a switch acts
/// now.
///
/// Reads [CivicStyle]'s fill (the track on) and foreground: its `style:`,
/// then [CivicThemeData.switchStyle]. Its size, its ink edge and the focus
/// ring are the look's.
///
/// ```dart
/// CivicSwitch(
///   value: largerText,
///   onChanged: (value) => setState(() => largerText = value),
///   labelText: 'Larger text',
///   helperText: 'Makes the words on every page bigger.',
/// )
/// ```
class CivicSwitch extends StatelessWidget {
  /// A switch.
  const CivicSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Whether it is on.
  final bool value;

  /// Called with the new value on a press; null disables it.
  final ValueChanged<bool>? onChanged;

  /// The setting's name; null stands the switch alone (name it with a
  /// `Semantics` label).
  final String? labelText;

  /// What it does, under the name.
  final String? helperText;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for this switch's look.
  final CivicStyle? style;

  /// The track's size.
  static const Size trackSize = Size(60, 36);

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final change = onChanged;
    final label = labelText;
    final helper = helperText;
    return RawButton(
      onPressed: change == null ? null : () => change(!value),
      focusNode: focusNode,
      autofocus: autofocus,
      toggled: value,
      button: false,
      semanticLabel: label,
      semanticHint: helper,
      excludeSemantics: true,
      mouseCursor: change == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      builder: (context, states, _) {
        final so = DesignStyleOf([style, t.switchStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final focused = states.contains(WidgetState.focused);
        final ink =
            so.foreground ?? (disabled ? t.textDisabled : t.textPrimary);
        final track = CivicSpringValue(
          value: focused ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) => CivicSpringValue(
            value: value ? 1 : 0,
            spring: CivicMotion.state,
            builder: (context, on, _) => CustomPaint(
              size: trackSize,
              painter: CivicWellPainter(
                fill: civicPointerFill(
                  Color.lerp(
                    disabled ? t.disabledFill : t.background,
                    disabled ? t.rule : (so.fill ?? t.action),
                    on.clamp(0, 1),
                  )!,
                  Color.lerp(t.textPrimary, t.onAction, on.clamp(0, 1))!,
                  states,
                ),
                edgeColor: disabled
                    ? t.rule
                    : Color.lerp(
                        t.border,
                        so.fill ?? t.action,
                        on.clamp(0, 1),
                      )!,
                focus: focus,
                focusColor: t.focus,
                focusEdgeColor: t.border,
              ),
              foregroundPainter: _KnobPainter(
                on: on,
                knob: Color.lerp(
                  disabled ? t.textDisabled : t.textPrimary,
                  disabled ? t.disabledFill : t.onAction,
                  on.clamp(0, 1),
                )!,
                tick: disabled ? t.rule : (so.fill ?? t.action),
                cross: disabled ? t.disabledFill : t.background,
                direction: Directionality.of(context),
              ),
            ),
          ),
        );
        if (label == null) return track;
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CivicMetrics.controlHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s8),
            child: Row(
              spacing: CivicSpacing.s16,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: text.body.copyWith(color: ink)),
                      if (helper != null)
                        Padding(
                          padding: const EdgeInsets.only(top: CivicSpacing.s4),
                          child: Text(helper, style: text.caption),
                        ),
                    ],
                  ),
                ),
                track,
              ],
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
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter({
    required this.on,
    required this.knob,
    required this.tick,
    required this.cross,
    required this.direction,
  });

  final double on;
  final Color knob;
  final Color tick;
  final Color cross;
  final TextDirection direction;

  static const double _inset = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.height - 2 * _inset;
    final travel = size.width - 2 * _inset - side;
    final along = travel * on;
    final x = direction == TextDirection.rtl
        ? size.width - _inset - side - along
        : _inset + along;
    final r = Rect.fromLTWH(x, _inset, side, side);
    canvas.drawRect(r, Paint()..color = knob);
    final a = ((on - 0.5) * 2).clamp(0.0, 1.0);
    if (a > 0) {
      final c = r.center;
      final path = Path()
        ..moveTo(c.dx - 6, c.dy)
        ..lineTo(c.dx - 2, c.dy + 4)
        ..lineTo(c.dx + 6, c.dy - 5);
      canvas.drawPath(
        path,
        Paint()
          ..color = tick.withValues(alpha: tick.a * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.square,
      );
    }
    final b = ((0.5 - on) * 2).clamp(0.0, 1.0);
    if (b > 0) {
      final c = r.center;
      const arm = 4.5;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - arm, c.dy - arm)
          ..lineTo(c.dx + arm, c.dy + arm)
          ..moveTo(c.dx + arm, c.dy - arm)
          ..lineTo(c.dx - arm, c.dy + arm),
        Paint()
          ..color = cross.withValues(alpha: cross.a * b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      old.on != on ||
      old.knob != knob ||
      old.tick != tick ||
      old.cross != cross ||
      old.direction != direction;
}
