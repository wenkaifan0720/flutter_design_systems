/// What a terminal says while it works and when it is done: the braille
/// spinner, the block progress bar, the blinking caret and the toast.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../primitives/box.dart';
import '../primitives/spring.dart';
import '../style.dart';
import '../theme.dart';
import 'button.dart';
import 'key_hint.dart';
import 'pane.dart';

/// What a message means, each with its glyph so it reads without colour:
/// `i`, `✓`, `!`, `✗`.
enum TermTone {
  /// Plain news, dim `·`.
  neutral,

  /// Worth knowing, `i` in the info ink.
  info,

  /// Done and well, `✓` in green.
  success,

  /// Look at it, `!` in yellow.
  warning,

  /// Failed, `✗` in red.
  error;

  /// The glyph written before the words.
  String get glyph => switch (this) {
    neutral => '·',
    info => 'i',
    success => '✓',
    warning => '!',
    error => '✗',
  };

  /// The tone's ink in [theme].
  Color colorIn(TermThemeData theme) => switch (this) {
    neutral => theme.dim,
    info => theme.info,
    success => theme.success,
    warning => theme.warning,
    error => theme.danger,
  };
}

/// A braille spinner, one cell: `⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏`, a frame every 80 ms, painted
/// rather than drawn from the font so every platform shows the same dots.
/// It holds still under Reduce Motion. A screen reader hears
/// [semanticLabel] (the localized "loading" when null), never the dots.
///
/// ```dart
/// const TermSpinner()
/// ```
class TermSpinner extends StatelessWidget {
  /// A spinner.
  const TermSpinner({super.key, this.color, this.semanticLabel, this.style});

  /// Overrides, over the theme's [TermThemeData.spinnerStyle]:
  /// `foreground` (the dots), under [color].
  final TermStyle? style;

  /// The dots' ink; null: the accent.
  final Color? color;

  /// What a screen reader hears.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return Semantics(
      label: semanticLabel ?? RawWidgetsLocalizations.of(context).loadingLabel,
      child: ExcludeSemantics(
        child: TermStepper(
          period: TermMotion.spinnerFrame,
          builder: (context, step) => CustomPaint(
            size: Size(grid.cellWidth, grid.lineHeight),
            painter: TermBraillePainter(
              grid: grid,
              bits: termSpinnerFrames[step % termSpinnerFrames.length],
              color:
                  color ??
                  TermStyleOf([
                    style,
                    theme.spinnerStyle,
                  ], const {}).foreground ??
                  theme.accent,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      StringProperty('semanticLabel', semanticLabel, defaultValue: null),
    );
  }
}

/// A progress bar of block glyphs, [cols] cells wide, filled in eighths of
/// a cell (`█▉▊▋▌▍▎▏`), with the percentage after it. [value] null is a
/// three-cell block that steps back and forth. A screen reader hears the
/// percentage as its value.
///
/// ```dart
/// const TermProgressBar(value: 0.42, cols: 20)
/// ```
class TermProgressBar extends StatelessWidget {
  /// A bar at [value].
  const TermProgressBar({
    super.key,
    required this.value,
    this.cols = 20,
    this.showPercent = true,
    this.color,
    this.semanticLabel,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.progressStyle]: `fill` (the
  /// blocks, under [color]) and `edge` (the dots of the cells left).
  final TermStyle? style;

  /// 0 to 1, or null while the amount is unknown.
  final double? value;

  /// Preferred track width in cells. The track shortens to leave the percentage visible.
  final int cols;

  /// Whether the percentage is written after it.
  final bool showPercent;

  /// The bar's ink; null: the accent.
  final Color? color;

  /// What a screen reader calls it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final direction = Directionality.of(context);
    final own = TermStyleOf([style, theme.progressStyle], const {});
    final ink = color ?? own.fill ?? theme.accent;
    final track = own.edge ?? theme.rule;
    final v = value;
    final percent = v == null ? null : '${(v.clamp(0, 1) * 100).round()}%';
    return Semantics(
      label: semanticLabel,
      value: percent,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final withPercent = showPercent && percent != null;
            final available = constraints.maxWidth.isFinite
                ? grid.colsIn(constraints.maxWidth)
                : cols + 5;
            final count = (available - (withPercent ? 5 : 0)).clamp(0, cols);
            if (count == 0 && withPercent) {
              return Text(percent, style: theme.dimStyle);
            }
            final Widget bar;
            if (v == null) {
              bar = TermStepper(
                period: TermMotion.spinnerFrame * 1.5,
                builder: (context, step) {
                  final span = count - 3;
                  final at = span <= 0
                      ? 0
                      : (step % (span * 2) < span
                            ? step % span
                            : span - step % span);
                  return CustomPaint(
                    size: Size(grid.cols(count), grid.lineHeight),
                    painter: _Bounce(
                      grid: grid,
                      at: at,
                      color: ink,
                      track: track,
                      direction: direction,
                    ),
                  );
                },
              );
            } else {
              bar = TermSpring(
                target: v.clamp(0, 1).toDouble(),
                token: TermMotion.move,
                spatial: true,
                builder: (context, t, _) => CustomPaint(
                  size: Size(grid.cols(count), grid.lineHeight),
                  painter: TermBlocksPainter(
                    grid: grid,
                    value: t.clamp(0, 1),
                    color: ink,
                    track: track,
                    textDirection: direction,
                  ),
                ),
              );
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                bar,
                if (withPercent) ...[
                  SizedBox(width: grid.cellWidth),
                  SizedBox(
                    width: grid.cols(4),
                    child: Text(
                      percent,
                      style: theme.dimStyle,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(IntProperty('cols', cols));
  }
}

class _Bounce extends CustomPainter {
  const _Bounce({
    required this.grid,
    required this.at,
    required this.color,
    required this.track,
    required this.direction,
  });

  final TermGrid grid;
  final int at;
  final Color color;
  final Color track;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final h = grid.fontSize;
    final top = (size.height - h) / 2;
    // A dot in every cell the blocks are not in, as the bar draws its rest.
    final cells = (size.width / cw + 1e-6).floor();
    final blockWidth = grid.cols(cells.clamp(0, 3));
    final dot = Paint()..color = track;
    final radius = grid.fontSize / 15 * 1.5;
    for (var i = 0; i < cells; i++) {
      if (i >= at && i < at + 3) continue;
      final cx = cw * i + cw / 2;
      canvas.drawCircle(
        Offset(
          direction == TextDirection.rtl ? size.width - cx : cx,
          size.height / 2,
        ),
        radius,
        dot,
      );
    }
    var x = at * cw;
    if (direction == TextDirection.rtl) x = size.width - x - blockWidth;
    canvas.drawRect(
      Rect.fromLTWH(x, top, blockWidth, h),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Bounce old) =>
      old.at != at ||
      old.color != color ||
      old.track != track ||
      old.direction != direction;
}

/// The block caret, a cell wide, blinking at the terminal's half-second:
/// after a prompt that waits for input. It stays lit under Reduce Motion.
/// A screen reader skips it.
///
/// ```dart
/// const TermCaret()
/// ```
class TermCaret extends StatelessWidget {
  /// A blinking block.
  const TermCaret({super.key, this.color});

  /// The block's ink; null: the accent.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return ExcludeSemantics(
      child: TermStepper(
        period: TermMotion.caretHalfPeriod,
        builder: (context, step) => SizedBox(
          width: grid.cellWidth,
          height: grid.lineHeight,
          child: Center(
            child: Container(
              width: grid.cellWidth,
              height: grid.fontSize * 1.25,
              color: step.isEven ? (color ?? theme.accent) : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hosts Terminal's toasts over [child]: put it in the app's builder, above
/// the navigator, and show one with [TermToaster.show].
///
/// A toast is a raised pane over the foot of the screen: the tone's glyph,
/// the message, the action as a bracketed button, and `esc` to dismiss
/// (F6 moves the keyboard's focus to it and back). It rises a line as it
/// enters.
///
/// ```dart
/// TermToaster.show(
///   context,
///   message: 'deployed atlas-api to staging',
///   tone: TermTone.success,
/// );
/// ```
class TermToaster extends StatelessWidget {
  /// Toasts over [child].
  const TermToaster({super.key, required this.child});

  /// The app.
  final Widget child;

  /// Shows a toast reading [message] in [tone], with an action when
  /// [actionLabel] and [onAction] are given.
  static RawToastController show(
    BuildContext context, {
    required String message,
    String? title,
    TermTone tone = TermTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration = const Duration(seconds: 4),
  }) => RawToaster.of(context).show(
    RawToast(
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      data: tone,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return RawToaster(
      padding: EdgeInsets.fromLTRB(
        grid.cellWidth,
        grid.lineHeight,
        grid.cellWidth,
        grid.lineHeight,
      ),
      constraints: BoxConstraints(maxWidth: grid.cols(64)),
      toastBuilder: (context, details) => TermToast(details: details),
      child: child,
    );
  }
}

/// One toast's face, as [TermToaster] paints it from [details].
class TermToast extends StatelessWidget {
  /// The face of [details]' toast.
  const TermToast({super.key, required this.details, this.style});

  /// Overrides, over the theme's [TermThemeData.toastStyle]: `fill` (the
  /// ground), `foreground` (the title) and `edge` (the box lines).
  final TermStyle? style;

  /// What the toaster says about the toast.
  final RawToastDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final toast = details.toast;
    final tone = toast.data is TermTone
        ? toast.data! as TermTone
        : TermTone.neutral;
    return AnimatedBuilder(
      animation: details.animation,
      builder: (context, child) {
        // Up where it stays, fading in and out; it never travels.
        final t = details.animation.value;
        return Opacity(opacity: t.clamp(0.0, 1.0), child: child);
      },
      child: TermPane(
        title: toast.title,
        footer: termKeysShown(context) ? 'esc' : null,
        raised: true,
        focused: details.focused,
        style: TermStyle.layered([style, theme.toastStyle]),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Text(
                tone.glyph,
                style: theme.boldStyle.copyWith(color: tone.colorIn(theme)),
              ),
            ),
            SizedBox(width: grid.cellWidth),
            Expanded(child: Text(toast.message)),
            if (details.runAction != null && toast.actionLabel != null) ...[
              SizedBox(width: grid.cellWidth),
              TermButton(
                label: toast.actionLabel!,
                onPressed: details.runAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
