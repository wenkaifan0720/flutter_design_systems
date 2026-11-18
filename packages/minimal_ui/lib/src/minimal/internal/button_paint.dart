// What a MinimalButton paints, for a tone, a scale and a style: its face
// for a set of states. MinimalButton presses it through its pressable; a
// part whose buttons ui_core presses (a dialog's actions) paints the same
// face and lays the pressable's wash and ring over it. Not exported. It
// names no type of button.dart's, so a copy of the button (renaming its
// variant and size) still paints through it.
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../theme.dart';
import 'controls.dart';
import 'face.dart';
import 'styled.dart';

/// A button's fill, as `MinimalButtonVariant` names them: the primary
/// fill, the bordered neutral, bare ink, the destructive fill.
enum MinimalButtonTone {
  /// The primary fill.
  primary,

  /// The bordered neutral.
  secondary,

  /// Bare ink.
  ghost,

  /// The destructive fill.
  destructive,
}

/// A button's height, as `MinimalButtonSize` names them: 28, 32 or 40 px.
enum MinimalButtonScale {
  /// 28 px.
  small,

  /// 32 px.
  medium,

  /// 40 px.
  large,
}

/// A `MinimalButton`'s paint for [tone], [scale] and [style], at the theme
/// in force where it is made.
class MinimalButtonPaint {
  /// The paint of a button of [tone] and [scale], [style] over the tone's
  /// component theme.
  factory MinimalButtonPaint.of(
    BuildContext context, {
    MinimalButtonTone tone = MinimalButtonTone.primary,
    MinimalButtonScale scale = MinimalButtonScale.medium,
    MinimalStyle? style,
  }) {
    final t = context.minimalTheme;
    final themed = switch (tone) {
      MinimalButtonTone.primary => t.components.primaryButton,
      MinimalButtonTone.secondary => t.components.secondaryButton,
      MinimalButtonTone.ghost => t.components.ghostButton,
      MinimalButtonTone.destructive => t.components.destructiveButton,
    };
    final (bg, fg, border) = switch (tone) {
      MinimalButtonTone.primary => (t.primary, t.primaryForeground, null),
      MinimalButtonTone.secondary => (t.card, t.foreground, t.border),
      MinimalButtonTone.ghost => (null, t.foreground, null),
      MinimalButtonTone.destructive => (
        t.destructive,
        t.destructiveForeground,
        null,
      ),
    };
    final (height, hPad, iconSize, type) = switch (scale) {
      MinimalButtonScale.small => (
        MinimalChromeMetrics.controlSm,
        MinimalChromeMetrics.buttonPadSm,
        MinimalIconSize.i14,
        t.control,
      ),
      MinimalButtonScale.medium => (
        MinimalChromeMetrics.control,
        MinimalSpacing.s12,
        MinimalIconSize.i16,
        t.control,
      ),
      MinimalButtonScale.large => (
        MinimalChromeMetrics.controlLg,
        MinimalSpacing.s16,
        MinimalIconSize.i16,
        t.body.medium,
      ),
    };
    return MinimalButtonPaint._(
      t: t,
      layers: [style, themed],
      bg: bg,
      fg: fg,
      border: border,
      height: height,
      hPad: hPad,
      iconSize: iconSize,
      type: type,
    );
  }

  MinimalButtonPaint._({
    required this.t,
    required this.layers,
    required this.bg,
    required this.fg,
    required this.border,
    required this.height,
    required this.hPad,
    required this.iconSize,
    required this.type,
  });

  /// The theme it was made at.
  final MinimalThemeData t;

  /// The style layers, the caller's over the variant's.
  final List<MinimalStyle?> layers;

  /// The variant's fill; null for a bare (ghost) button.
  final Color? bg;

  /// The variant's ink.
  final Color fg;

  /// The variant's rim colour; null for none.
  final Color? border;

  /// The size's height, before density and text size.
  final double height;

  /// The size's side padding.
  final double hPad;

  /// The size's glyph.
  final double iconSize;

  /// The size's type.
  final TextStyle type;

  /// The style at rest, as a pressable reads it.
  MinimalStyleOf get rest => MinimalStyleOf(layers, const {});

  /// The face for [states], its [content] drawn in the ink of the moment;
  /// [expand] fills the width.
  Widget face(
    BuildContext context,
    Set<WidgetState> states, {
    required Widget Function(MinimalStyleOf so, Color ink) content,
    bool expand = false,
    Decoration? foregroundDecoration,
  }) {
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
          so.paddingIn(context) ??
          t.density.padding(
            EdgeInsets.symmetric(horizontal: hPad, vertical: MinimalSpacing.s2),
          ),
      decoration: minimalFrame(
        so.shape ?? t.shapes.small,
        fill: so.fill ?? bg,
        side: so.rim(border, t.rim),
      ),
      foregroundDecoration: foregroundDecoration,
      builder: (context, ink) => content(so, ink ?? fg),
    );
  }
}
