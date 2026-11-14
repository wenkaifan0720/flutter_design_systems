import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A number that MOVES: the screen's one live quantity — a streak, a total,
/// a count kept today — rolls to its new value instead of swapping glyphs.
///
/// Minimal's roll is an odometer's: only the characters that changed
/// move, each sliding out and its successor in (upward when the value grew,
/// downward when it fell) inside its own clipped slot, in
/// [MinimalMotion.base] (120 ms, a control's budget, not a page push's) with
/// no overshoot. Characters are aligned from the end, so units stay put
/// while a new leading digit rolls in. The characters keep their printed
/// order, left to right, in either reading direction: a figure reads the
/// same in every language. It reads best in a mono style (every figure the
/// same width), which is why [style] defaults to [MinimalThemeData.figure].
///
/// It is a ONE-SHOT per value change, never a loop, and it lands on exactly
/// the value it was given; under `MediaQuery.disableAnimations` it swaps.
/// [format] renders the value (`12d`, `€1,284`); it announces as printed.
///
/// ```dart
/// MinimalCounter(streak, style: t.giant, format: (v) => '${v}d')
/// ```
class MinimalCounter extends StatefulWidget {
  /// [value] in mono figures.
  const MinimalCounter(this.value, {super.key, this.style, this.format});

  /// The count.
  final int value;

  /// The type the number prints in; null takes [MinimalThemeData.figure].
  final TextStyle? style;

  /// How the value is rendered; plain digits when omitted.
  final String Function(int)? format;

  @override
  State<MinimalCounter> createState() => _MinimalCounterState();
}

class _MinimalCounterState extends State<MinimalCounter> {
  /// Which way the last change rolled: up when the value grew.
  bool _up = true;

  @override
  void didUpdateWidget(MinimalCounter old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) _up = widget.value > old.value;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final style = widget.style ?? t.figure;
    final text = (widget.format ?? _plain)(widget.value);
    final instant = context.minimalStill;
    final chars = text.characters.toList();
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          // One slot per character: a right-to-left row would print
          // `12d` as `d21`. The figure stands at the start edge all the same.
          child: Row(
            textDirection: TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              for (var i = 0; i < chars.length; i++)
                _Slot(
                  // Keyed from the end, so a slot keeps its place value.
                  key: ValueKey<int>(chars.length - i),
                  char: chars[i],
                  up: _up,
                  style: style,
                  duration: instant ? Duration.zero : MinimalMotion.base,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _plain(int value) => '$value';

/// One character's clipped window: when its character changes, the old one
/// leaves and the new one arrives from the other edge.
class _Slot extends StatefulWidget {
  const _Slot({
    super.key,
    required this.char,
    required this.up,
    required this.style,
    required this.duration,
  });

  final String char;
  final bool up;
  final TextStyle style;
  final Duration duration;

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: widget.duration,
    // Settled: a slot that first appears with the widget does not roll in.
    value: 1,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _roll,
    curve: MinimalMotion.out,
  );

  /// The character rolling out, until the roll lands.
  String? _previous;

  /// Which roll is running: a value that changes mid-roll starts a new one,
  /// and the cancelled roll's completion must not clear the new one's
  /// outgoing character.
  int _generation = 0;

  @override
  void didUpdateWidget(_Slot old) {
    super.didUpdateWidget(old);
    _roll.duration = widget.duration;
    if (widget.char != old.char) {
      if (widget.duration == Duration.zero) {
        _previous = null;
        _roll.value = 1;
        return;
      }
      _previous = old.char;
      final generation = ++_generation;
      _roll.forward(from: 0).whenCompleteOrCancel(() {
        if (mounted && generation == _generation) {
          setState(() => _previous = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previous;
    final glyph = Text(widget.char, style: widget.style, maxLines: 1);
    if (previous == null) return glyph;
    final sign = widget.up ? 1.0 : -1.0;
    final curve = _curve;
    return ClipRect(
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            FractionalTranslation(
              translation: Offset(0, -sign * curve.value),
              child: Text(previous, style: widget.style, maxLines: 1),
            ),
            FractionalTranslation(
              translation: Offset(0, sign * (1 - curve.value)),
              child: glyph,
            ),
          ],
        ),
      ),
    );
  }
}
