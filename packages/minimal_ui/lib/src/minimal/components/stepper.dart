import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/field.dart';
import '../internal/styled.dart';
import '../internal/text_entry.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'pressable.dart';

/// Bounded integer adjustment — guests, servings, pages, sets: a compact
/// bordered 32 px control of − · value · +, the value in mono with tabular
/// figures so the box never changes width as it counts. The parent owns the
/// value.
///
/// Hold a button to repeat. A button whose way is blocked by [min] or [max]
/// disables itself; a null [onChanged] dims the whole control. Each button
/// is a focus stop that Enter or Space presses, and announces the value with
/// its action (`Increase Guests`, `3`). [format] prints the figure (`3×`,
/// `1.5`) and [unit] names what it counts (`pages`): the figure stays in
/// mono and the word after it prints in Geist, the way a field's suffix
/// does, and a screen reader hears both (`20 pages`). Never put the word in
/// [format] — it would print in mono. The value slot keeps one steady
/// width, room for three figures and a short unit, so steppers stacked in a
/// form line up, with a unit or without; only a wider value in range grows
/// it. The hit area pads out to 44 whatever the control paints.
///
/// ```dart
/// MinimalNumberField(value: pages, min: 5, max: 50, step: 5, unit: 'pages', label: 'Pages', onChanged: setPages)
/// ```
class MinimalNumberField extends StatefulWidget {
  /// A number set with minus and plus.
  const MinimalNumberField({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.onChanged,
    this.label,
    this.format,
    this.unit,
  }) : assert(min <= max),
       assert(value >= min && value <= max),
       assert(step > 0);

  /// The number it shows.
  final int value;

  /// The least it goes to.
  final int min;

  /// The most it goes to.
  final int max;

  /// How much a press changes it.
  final int step;

  /// Null disables the stepper.
  final ValueChanged<int>? onChanged;

  /// What is being counted, for the buttons' announcements.
  final String? label;

  /// How the figure prints; plain digits when omitted. Figures and symbols
  /// only (`3×`): a word goes in [unit].
  final String Function(int)? format;

  /// The word after the figure (`pages`, `min`, `glasses`), printed in the
  /// body face and announced with the value.
  final String? unit;

  @override
  State<MinimalNumberField> createState() => _MinimalNumberFieldState();
}

class _MinimalNumberFieldState extends State<MinimalNumberField> {
  Timer? _timer;

  /// The value a hold has reached, ahead of the parent's rebuild.
  int? _repeated;

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _repeated = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MinimalNumberField old) {
    super.didUpdateWidget(old);
    if (widget.onChanged == null ||
        widget.min != old.min ||
        widget.max != old.max) {
      _stop();
    }
  }

  void _change(int direction) {
    final onChanged = widget.onChanged;
    if (onChanged == null) return _stop();
    final from = _repeated ?? widget.value;
    final next = (from + direction * widget.step).clamp(widget.min, widget.max);
    if (next == from) return _stop();
    _repeated = next;
    HapticFeedback.selectionClick();
    onChanged(next);
  }

  void _tap(int direction) {
    _stop();
    _change(direction);
    _repeated = null;
  }

  void _hold(int direction) {
    _stop();
    _repeated = widget.value;
    _change(direction);
    _timer = Timer(MinimalChromeMetrics.holdDelay, () {
      _timer = Timer.periodic(
        MinimalChromeMetrics.holdRepeat,
        (_) => _change(direction),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final format = widget.format ?? (int v) => '$v';
    final unit = widget.unit;
    final style = t.monoValue;
    // The unit word is Geist at the value's size, quieter than the figure.
    final unitStyle = t.body.copyWith(
      fontSize: style.fontSize,
      height: style.height,
      color: t.mutedForeground,
    );
    String spoken(int v) => unit == null ? format(v) : '${format(v)} $unit';
    TextSpan printed(String figure) => TextSpan(
      children: [
        TextSpan(text: figure, style: style.c(t.foreground)),
        if (unit != null) TextSpan(text: ' $unit', style: unitStyle),
      ],
    );
    // The box is sized by the widest printed value in range, so it holds
    // still while the digits change.
    final widest = [
      format(widget.min),
      format(widget.max),
    ].reduce((a, b) => a.length >= b.length ? a : b);
    // Under it, one steady slot for every stepper (scaled with the type),
    // so a column of them lines up whatever each one counts.
    final steady =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 13) *
        MinimalControlMetrics.stepperValueEm;
    // The standard control at the theme's density, like the fields beside
    // it. Larger type grows the box, and the buttons' height with it, rather
    // than clipping the figure.
    final rest = t.density.height(MinimalChromeMetrics.control);
    final side = math.max(
      rest,
      minimalLineHeight(context, style) + 2 * MinimalSpacing.s4,
    );
    final inner = rest - 2 * t.hairline;
    final tall = side - 2 * t.hairline;

    final live = widget.onChanged != null;

    Widget button(int direction) {
      final enabled =
          live &&
          (direction < 0
              ? widget.value > widget.min
              : widget.value < widget.max);
      final words = MinimalLocalizations.of(context);
      final name = widget.label ?? words.quantity;
      final action = direction < 0
          ? words.decrease(name)
          : words.increase(name);
      final glyph = SizedBox(
        width: inner,
        height: tall,
        child: MinimalIcon(
          direction < 0 ? LucideIcons.minus : LucideIcons.plus,
          size: MinimalIconSize.i16,
          color: t.foreground,
        ),
      );
      // A stepper with no onChanged dims as a whole below, so its buttons
      // are announced disabled without dimming a second time.
      if (!live) {
        return Semantics(
          container: true,
          button: true,
          enabled: false,
          label: action,
          value: spoken(widget.value),
          child: glyph,
        );
      }
      return MinimalPressable(
        onPressed: enabled ? () => _tap(direction) : null,
        enabled: enabled,
        shape: MinimalShapes.inset(t.shapes.small, t.hairline),
        semanticLabel: action,
        child: Semantics(
          value: spoken(widget.value),
          child: GestureDetector(
            excludeFromSemantics: true,
            onLongPressStart: enabled ? (_) => _hold(direction) : null,
            onLongPressEnd: (_) => _stop(),
            onLongPressCancel: _stop,
            child: glyph,
          ),
        ),
      );
    }

    final rule = Container(width: t.hairline, color: t.border);
    final control = Container(
      height: side,
      decoration: minimalFrame(
        t.shapes.small,
        fill: t.card,
        side: BorderSide(color: t.border, width: t.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(-1),
          rule,
          // The buttons carry the value for a screen reader.
          ExcludeSemantics(
            child: Padding(
              padding: MinimalInsets.horizontal8,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: steady),
                // The figure by its capitals, level with the labels of the
                // controls beside it (the widest value under it shares its
                // line, so both move as one).
                child: minimalCapLabel(
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0,
                        child: Text.rich(printed(widest), maxLines: 1),
                      ),
                      Text.rich(printed(format(widget.value)), maxLines: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          rule,
          button(1),
        ],
      ),
    );
    return MinimalHitTarget(
      child: live ? control : Opacity(opacity: 0.45, child: control),
    );
  }
}
