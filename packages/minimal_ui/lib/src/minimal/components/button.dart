import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// A [MinimalButton]'s variant, as shadcn's: the primary fill for the one
/// thing to act on, a bordered neutral for everything beside it, bare ink
/// for the quiet action, the destructive fill for the one that deletes.
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

/// Minimal's only button — every action a page offers is one of these, in
/// one of four variants and three sizes: a compact control in the theme's
/// [MinimalThemeData.control] type with 8 px corners, never taller than it
/// needs to be. The hit area pads
/// out to 44 whatever it paints.
///
/// [style] dresses one button and the variant's component theme
/// (`components.primaryButton`, `secondaryButton`, `ghostButton`,
/// `destructiveButton`) every one; they read every slot: fill, foreground,
/// edge or side, overlay, shape (else `shapes.small`), padding,
/// minimumSize, textStyle and iconSize. `density` moves its height and side
/// padding; `t.rim` is its rim.
///
/// `busy: true` is an action under way: a small spinner in the label's ink
/// takes the glyph's seat at the leading edge, and the button takes no
/// presses while its face keeps its full strength, so it reads as busy, not
/// disabled. Its [label] says what is happening (`Creating…`).
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

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final themed = switch (variant) {
      MinimalButtonVariant.primary => t.components.primaryButton,
      MinimalButtonVariant.secondary => t.components.secondaryButton,
      MinimalButtonVariant.ghost => t.components.ghostButton,
      MinimalButtonVariant.destructive => t.components.destructiveButton,
    };
    final layers = <MinimalStyle?>[style, themed];

    final (bg, fg, borderColor) = switch (variant) {
      MinimalButtonVariant.primary => (t.primary, t.primaryForeground, null),
      MinimalButtonVariant.secondary => (t.card, t.foreground, t.border),
      MinimalButtonVariant.ghost => (null, t.foreground, null),
      MinimalButtonVariant.destructive => (
        t.destructive,
        t.destructiveForeground,
        null,
      ),
    };

    final (height, hPad, iconSize, type) = switch (size) {
      MinimalButtonSize.small => (
        MinimalChromeMetrics.controlSm,
        MinimalChromeMetrics.buttonPadSm,
        MinimalIconSize.i14,
        t.control,
      ),
      MinimalButtonSize.medium => (
        MinimalChromeMetrics.control,
        MinimalSpacing.s12,
        MinimalIconSize.i16,
        t.control,
      ),
      MinimalButtonSize.large => (
        MinimalChromeMetrics.controlLg,
        MinimalSpacing.s16,
        MinimalIconSize.i16,
        t.body.medium,
      ),
    };

    final lead = leading;
    final rest = MinimalStyleOf(layers, const {});

    Widget face(BuildContext context, Set<WidgetState> states) {
      final so = MinimalStyleOf(layers, states);
      final least = so.minimumSize;
      // The face lerps to each state (Minimal's short plain fade).
      return MinimalFace(
        ink: so.foreground ?? fg,
        constraints: BoxConstraints(
          minWidth: least?.width ?? 0,
          minHeight:
              least?.height ??
              minimalGrownHeight(context, t.density.height(height)),
        ),
        width: expand ? double.infinity : null,
        // The label's line (16) and its padding stay under the smallest
        // height (24: a small button at compact density) with a rim or
        // without, so every variant takes the density's height and a row
        // of them shares one; a larger text scale still grows it.
        padding:
            so.padding ??
            t.density.padding(
              EdgeInsets.symmetric(horizontal: hPad, vertical: 2),
            ),
        decoration: minimalFrame(
          so.shape ?? t.shapes.small,
          fill: so.fill ?? bg,
          side: so.rim(borderColor, t.rim),
        ),
        builder: (context, ink) => _face(so, ink ?? fg, lead, iconSize, type),
      );
    }

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
            shape: t.shapes.small,
            face: rest.fill ?? bg,
            ink: rest.foreground ?? fg,
            builder: face,
          );
    // Filling its column on a phone; from the compact width up an expanded
    // button stops at a control's measure, and any other keeps the width of
    // its words whatever stretches it (design6 P (a)).
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
}

/// A busy button's spinner: a quarter arc in [ink] on a faint ring of it,
/// [size] square like the glyph it stands in for, turning once a second. It
/// stands at rest while [MinimalMotionContext.minimalStill] holds (tests,
/// goldens, reduced motion).
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.minimalStill) {
      _turn
        ..stop()
        ..value = 0;
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
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: RotationTransition(
      turns: _turn,
      child: CustomPaint(painter: _BusyPainter(widget.ink)),
    ),
  );
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
