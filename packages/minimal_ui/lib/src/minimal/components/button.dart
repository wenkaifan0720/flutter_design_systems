import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawCorner;

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/button_paint.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// The visual treatment of a [MinimalButton].
enum MinimalButtonVariant {
  /// The primary fill: the one thing to act on.
  primary,

  /// The bordered neutral: everything beside it.
  secondary,

  /// Bare ink: the quiet action.
  ghost,

  /// The destructive fill: an action that deletes or cannot be undone.
  destructive,
}

/// A [MinimalButton]'s height: 28, 32 (the default) or 40.
enum MinimalButtonSize {
  /// 28 px.
  small,

  /// 32 px, the default.
  medium,

  /// 40 px.
  large,
}

/// An action button with an optional icon or leading widget.
///
/// Choose [variant] for the action's role and [size] for its height. Touch
/// targets are at least the tap floor in force (40 px at a finger, 24 at a
/// pointer). [style] overrides the variant's component theme.
///
/// Set [busy] while work is in progress. The button shows a spinner and
/// ignores further presses. Supply a [label] that describes the operation.
///
/// ```dart
/// MinimalButton('Create habit', onPressed: create)
/// ```
class MinimalButton extends StatelessWidget {
  /// A button saying [label].
  const MinimalButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = MinimalButtonVariant.primary,
    this.size = MinimalButtonSize.medium,
    this.icon,
    this.leading,
    this.expand = false,
    this.busy = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         icon == null || leading == null,
         'a button leads with an icon or a leading widget, not both',
       );

  /// What it says.
  final String label;

  /// Its press; null disables it.
  final VoidCallback? onPressed;

  /// Its register: primary, secondary, ghost or danger.
  final MinimalButtonVariant variant;

  /// Its size: sm, md or lg.
  final MinimalButtonSize size;

  /// A glyph before the label.
  final IconData? icon;

  /// A widget before the label, for the one thing an icon cannot say (a key
  /// cap, a count).
  final Widget? leading;

  /// Fill the available width (a sheet's sole action, a sticky footer).
  final bool expand;

  /// Whether its action is under way: a spinner leads the label, and the
  /// button takes no presses without dimming.
  final bool busy;

  /// This button's style, over its variant's component theme.
  final MinimalStyle? style;

  /// {@template minimal.focusNode}
  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template minimal.autofocus}
  /// Whether it takes keyboard focus when it first appears.
  /// {@endtemplate}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final paint = MinimalButtonPaint.of(
      context,
      tone: switch (variant) {
        MinimalButtonVariant.primary => MinimalButtonTone.primary,
        MinimalButtonVariant.secondary => MinimalButtonTone.secondary,
        MinimalButtonVariant.ghost => MinimalButtonTone.ghost,
        MinimalButtonVariant.destructive => MinimalButtonTone.destructive,
      },
      scale: switch (size) {
        MinimalButtonSize.small => MinimalButtonScale.small,
        MinimalButtonSize.medium => MinimalButtonScale.medium,
        MinimalButtonSize.large => MinimalButtonScale.large,
      },
      style: style,
    );
    final rest = onPressed == null && !busy
        ? MinimalStyleOf(paint.layers, const {WidgetState.disabled})
        : paint.rest;
    final (bg, fg) = paint.colors(rest);
    final lead = leading;

    Widget face(BuildContext context, Set<WidgetState> states) => paint.face(
      context,
      states,
      expand: expand,
      content: (so, ink) => _face(so, ink, lead, paint.iconSize, paint.type),
    );

    // Busy, the face keeps its resting strength (no dimming: busy is not
    // disabled) and takes no presses; a screen reader hears an unavailable
    // button saying what is under way.
    final Widget button = busy
        ? Semantics(
            container: true,
            button: true,
            enabled: false,
            liveRegion: true,
            child: Builder(builder: (context) => face(context, const {})),
          )
        : MinimalPressable(
            focusNode: focusNode,
            autofocus: autofocus,
            onPressed: onPressed,
            // A button with no action IS disabled — MinimalPressable does not
            // infer that, so the register is stated here.
            enabled: onPressed != null,
            style: rest.press,
            shape: rest.outline(t, RawCorner.small),
            face: bg,
            ink: fg,
            builder: face,
          );
    // Filling its column on a phone; from the compact width up an expanded
    // button stops at a control's measure, and any other keeps the width of
    // its words whatever stretches it.
    return expand
        ? MinimalLayout.capControl(context, button)
        : MinimalLayout.holdWidth(context, button);
  }

  Widget _face(
    MinimalStyleOf so,
    Color fg,
    Widget? lead,
    double iconSize,
    TextStyle type,
  ) => Row(
    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Busy, the spinner takes the glyph's seat, in the label's ink.
      if (busy) ...[
        _BusyMark(size: so.iconSize ?? iconSize, ink: fg),
        const MinimalGap(MinimalChromeMetrics.iconGap),
      ] else if (icon != null) ...[
        MinimalIcon(icon!, size: so.iconSize ?? iconSize, color: fg),
        const MinimalGap(MinimalChromeMetrics.iconGap),
      ] else if (lead != null) ...[
        lead,
        const MinimalGap(MinimalChromeMetrics.iconGap),
      ],
      // An action's meaning is primary content: two lines are cheaper
      // than an ambiguous ellipsis, and the min-height lets the control
      // grow without shrinking its hit target.
      Flexible(
        child: minimalCapLabel(
          Text(
            label,
            style: so.text(type, fg),
            maxLines: 2,
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ],
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        EnumProperty<MinimalButtonVariant>(
          'variant',
          variant,
          defaultValue: MinimalButtonVariant.primary,
        ),
      )
      ..add(
        EnumProperty<MinimalButtonSize>(
          'size',
          size,
          defaultValue: MinimalButtonSize.medium,
        ),
      )
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(FlagProperty('expand', value: expand, ifTrue: 'expand'))
      ..add(FlagProperty('busy', value: busy, ifTrue: 'busy'))
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

/// A busy button's icon-sized spinner. It stays still under reduced motion.
class _BusyMark extends StatefulWidget {
  const _BusyMark({required this.size, required this.ink});

  final double size;
  final Color ink;

  @override
  State<_BusyMark> createState() => _BusyMarkState();
}

class _BusyMarkState extends State<_BusyMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  // Run from build: iOS's Reduce Motion arrives as a build, not as a
  // change of dependencies.
  void _run() {
    if (context.minimalStill) {
      if (_turn.isAnimating || _turn.value != 0) {
        _turn
          ..stop()
          ..value = 0;
      }
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _run();
    return SizedBox.square(
      dimension: widget.size,
      child: RotationTransition(
        turns: _turn,
        child: CustomPaint(painter: _BusyPainter(widget.ink)),
      ),
    );
  }
}

class _BusyPainter extends CustomPainter {
  const _BusyPainter(this.ink);

  final Color ink;

  /// The ring's stroke, a glyph's.
  static const double _stroke = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    // Inset like a glyph's drawing inside its box.
    final rect = (Offset.zero & size).deflate(_stroke / 2 + 1);
    Paint line(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      line(ink.withValues(alpha: 0.3)),
    );
    canvas.drawArc(rect, -math.pi / 2, math.pi / 2, false, line(ink));
  }

  @override
  bool shouldRepaint(_BusyPainter old) => old.ink != ink;
}
