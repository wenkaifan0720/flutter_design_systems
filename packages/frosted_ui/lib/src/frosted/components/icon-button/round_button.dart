import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/cut.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';

/// How large a [FrostedIconButton] stands: [regular] is the 40 point disc
/// of a top bar (back, the bell, its glyph 18), [small] the 32 point one of
/// a sheet's head (close, its glyph 16), a search's clear and a month's
/// steps, [large] the 48 point one of a stepper.
enum FrostedIconButtonSize {
  /// The 40 disc of a top bar, its glyph 18.
  regular(FrostedChromeMetrics.roundButton, FrostedChromeMetrics.roundGlyph),

  /// The 32 disc of a sheet's head, its glyph 16.
  small(
    FrostedChromeMetrics.roundButtonSmall,
    FrostedChromeMetrics.roundGlyphSmall,
  ),

  /// The 48 disc of a stepper.
  large(FrostedChromeMetrics.stepper, FrostedChromeMetrics.roundGlyph);

  const FrostedIconButtonSize(this.diameter, this.glyph);

  /// How wide the disc is.
  final double diameter;

  /// The glyph's size.
  final double glyph;
}

/// A round button of the brighter glass wearing one glyph in the ink, its rim
/// of light along the top and its hairline edge: back, close, the bell. A
/// screen reader hears it as a button named [semanticLabel]; a null [onPressed] draws
/// it at the disabled share and inert. A toggle (bold, a favourite) says
/// whether it is on through [selected]: on, the disc stays glass, a little
/// clearer, with a dot printed under its glyph; null is a plain act. It lays
/// out at its disc and takes taps over the platform's touch target round it.
///
/// ```dart
/// FrostedIconButton(FrostedGlyphs.chevronLeft, semanticLabel: 'Back to Home', onPressed: () => Navigator.of(context).maybePop())
/// ```
class FrostedIconButton extends StatelessWidget {
  /// Creates a [FrostedIconButton].
  const FrostedIconButton(
    this.icon, {
    required this.semanticLabel,
    this.onPressed,
    this.selected,
    this.size = FrostedIconButtonSize.regular,
    this.badge = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The glyph, from the Lucide set the system draws with.
  final IconData icon;

  /// What a screen reader says.
  final String semanticLabel;

  /// What a press does; null draws the button inert.
  final VoidCallback? onPressed;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// Whether a toggle is on; null for a plain act.
  final bool? selected;

  /// How large the disc stands.
  final FrostedIconButtonSize size;

  /// Whether the dot of something unread stands at its top right (the bell
  /// with unread notifications).
  final bool badge;

  /// This icon button's own style, over
  /// `FrostedThemeData.components.iconButton`: its fill, foreground (the
  /// glyph), edge colour or a whole side (drawn inside the disc in place of
  /// the hairline ring outside it), overlay, shape, minimum size and icon
  /// size, each per state (selected while [selected] is true).
  ///
  /// ```dart
  /// FrostedIconButton(
  ///   FrostedGlyphs.bell,
  ///   semanticLabel: 'Notifications',
  ///   onPressed: open,
  ///   style: const FrostedStyle(
  ///     shape: WidgetStatePropertyAll(
  ///       RoundedRectangleBorder(
  ///         borderRadius: BorderRadius.all(Radius.circular(12)),
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final d = size.diameter;
    final layers = FrostedStyleLayers(
      style,
      t.components.iconButton,
      const <WidgetState>{},
      t,
    );
    final cut = layers.cut(FrostedCorners.full);
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      // A toggle button: a button, selected while on, as Flutter's
      // `IconButton(isSelected:)` says it.
      selected: selected,
      radius: FrostedStyleLayers.radiusOf(cut, d, d / 2),
      shape: cut,
      builder: (context, states, _) => frostedIconButtonFace(
        context,
        icon,
        states: states,
        enabled: onPressed != null,
        size: size,
        selected: selected,
        badge: badge,
        style: style,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null))
      ..add(
        EnumProperty<FrostedIconButtonSize>(
          'size',
          size,
          defaultValue: FrostedIconButtonSize.regular,
        ),
      )
      ..add(FlagProperty('badge', value: badge, ifTrue: 'badge'))
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

/// An icon button's disc as [FrostedIconButton] draws it in [states], with
/// no press of its own: for a part whose behaviour presses it (a number
/// field's steps). A [diameter] draws the disc at that size instead of
/// [size]'s, the glyph keeping [size]'s. Kept back from the package's barrel.
Widget frostedIconButtonFace(
  BuildContext context,
  IconData icon, {
  required Set<WidgetState> states,
  required bool enabled,
  FrostedIconButtonSize size = FrostedIconButtonSize.regular,
  double? diameter,
  bool? selected,
  bool badge = false,
  FrostedStyle? style,
}) {
  final t = context.frostedTheme;
  final d = diameter ?? size.diameter;
  final layers = FrostedStyleLayers(
    style,
    t.components.iconButton,
    const <WidgetState>{},
    t,
  );
  final s = layers.at(states);
  final on = selected ?? false;
  final cut = s.cut(FrostedCorners.full);
  final fill = s.fill;
  final side = s.side;
  final (edge, edges) = side == null
      ? (null, EdgeInsets.zero)
      : s.edgeOf(null, FrostedStrokes.regular);
  Widget disc = SizedBox.square(
    dimension: d,
    // A disc of glass; on, it stays glass, a little clearer, with a dot
    // printed under its glyph, never a fill of ink.
    child: FrostedFace(
      material: FrostedMaterial.pane,
      radius: BorderRadius.circular(d / 2),
      shape: cut,
      color: fill,
      wash: s.overlay ?? (on ? t.glass.wash : null),
      edge: edge,
      edges: edges,
      sheen: t.glass.rim,
      // The disc is its box: its edge a ring inside it, never one
      // outside that stands it a pixel wider than the buttons beside it.
      ring: side == null ? (s.edge ?? t.glass.edge) : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _cutForDot(
            badge,
            Directionality.of(context) == TextDirection.rtl,
            d,
            s.iconSize ?? size.glyph,
            Icon(
              icon,
              size: s.iconSize ?? size.glyph,
              color: s.foreground ?? t.colorScheme.textPrimary,
            ),
          ),
          // On: a 5 dot in the glyph's ink, centred in the room under it.
          Positioned(
            bottom: ((d - (s.iconSize ?? size.glyph)) / 2 - 5) / 2,
            child: FrostedFade(
              opacity: on ? 1 : 0,
              child: SizedBox.square(
                dimension: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.foreground ?? t.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  disc = s.least(disc);
  if (badge) {
    disc = Stack(
      clipBehavior: Clip.none,
      children: [
        disc,
        const PositionedDirectional(
          top: FrostedChromeMetrics.bellDotTop,
          end: FrostedChromeMetrics.bellDotRight,
          child: FrostedBadgeDot(),
        ),
      ],
    );
  }
  disc = FrostedDim(off: !enabled, child: disc);
  return disc;
}

/// The glyph of a round [diameter] across, its [glyph] box centred, cut clear
/// of the bell's dot (top 9, 10 in from the end: the right, or the left when
/// [rtl]) by the dot's ring when [badge].
Widget _cutForDot(
  bool badge,
  bool rtl,
  double diameter,
  double glyph,
  Widget icon,
) {
  if (!badge) return icon;
  const r = FrostedChromeMetrics.bellDot / 2;
  final inset = (diameter - glyph) / 2;
  // The dot's centre in the glyph's box.
  final fromLeft = diameter - FrostedChromeMetrics.bellDotRight - r - inset;
  final centre = Offset(
    rtl ? glyph - fromLeft : fromLeft,
    FrostedChromeMetrics.bellDotTop + r - inset,
  );
  return ClipPath(
    clipper: FrostedCutClipper(
      (_) => Path()
        ..addOval(
          Rect.fromCircle(
            center: centre,
            radius: r + FrostedChromeMetrics.bellDotRing,
          ),
        ),
      centre,
    ),
    child: icon,
  );
}

/// The dot of something unread: 7 across in the coral; the bell's unread mark.
/// Whatever it stands over is cut clear of it by 2 (a gap is cut, never
/// painted), as the bell's glyph is.
///
/// ```dart
/// FrostedBadgeDot()
/// ```
class FrostedBadgeDot extends StatelessWidget {
  /// Creates a [FrostedBadgeDot].
  const FrostedBadgeDot({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: FrostedChromeMetrics.bellDot,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.colorScheme.unreadDot,
          ),
        ),
      ),
    );
  }
}
