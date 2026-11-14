/// Expressive's icons: the Material Symbols Rounded glyphs the system
/// wears (Apache-2.0, subset, the FILL axis for selection; CONTRACT §2
/// "Icons", §9.3). No other icon font, and never a Google product mark
/// (§6). Owner: w1-type. The `icon` role's component lives with the content
/// family; this file is the glyph set and the fill.
///
/// - [ExpressiveSymbols]: one `IconData` per bundled glyph, generated
///   (`internal/icons/symbols.g.dart`) from the subset's codepoints by
///   `tools/expressive_tokens/fonts/` — `symbols.txt` lists the glyphs: the
///   ones Expressive's components draw and a documented everyday-app set.
/// - [ExpressiveSymbolsFont]: the font the glyphs are drawn in and the fill of
///   each state.
/// - [ExpressiveIcon]: a glyph as Compose's `Icon` draws it, whose FILL
///   follows a selected state on the theme's fast effects spring, never a
///   duration.
library;

import 'package:flutter/widgets.dart';

import 'motion.dart';

export 'internal/icons/symbols.g.dart' show ExpressiveSymbols;

/// The bundled Material Symbols Rounded font and its FILL axis.
abstract final class ExpressiveSymbolsFont {
  /// The subset's family (the module's pubspec); every [ExpressiveSymbols]
  /// glyph names it.
  static const String family = 'MaterialSymbolsRounded';

  /// The FILL of a glyph at rest: the outlined form.
  static const double outlined = 0;

  /// The FILL of a selected glyph: the filled form.
  static const double filled = 1;
}

/// A Material Symbols glyph ([ExpressiveSymbols]) as Compose's `Icon`
/// draws it: [size] (the ambient `IconTheme`'s when null), tinted [color]
/// (the ambient content colour when null), filled when [selected] — the
/// FILL springs on the fast effects spring of the motion in force
/// ([ExpressiveMotion.of]: `MotionSchemeKeyTokens.FastEffects`). [weight],
/// [grade] and [opticalSize] set the font's other variable axes; the
/// sizes of [ExpressiveIconSize] are Material Symbols' optical sizes.
/// Decorative (silent) unless [semanticLabel] is given.
///
/// At rest the glyph takes the ambient `IconTheme`'s fill (outlined when it
/// sets none), so a subtree can draw its glyphs solid the way Compose
/// draws `Icons.Filled.*`: a media transport's play, pause and skip, under
/// `IconTheme.merge(data: IconThemeData(fill: ExpressiveSymbolsFont.filled))`.
/// Selected, it is always filled.
///
/// ```dart
/// ExpressiveIcon(
///   ExpressiveSymbols.favorite,
///   selected: liked,
///   semanticLabel: 'Liked',
/// )
/// ```
class ExpressiveIcon extends StatefulWidget {
  /// An icon showing the glyph [icon], filled when [selected].
  const ExpressiveIcon(
    this.icon, {
    this.selected = false,
    this.size,
    this.color,
    this.weight,
    this.grade,
    this.opticalSize,
    this.semanticLabel,
    super.key,
  });

  /// The glyph: one of [ExpressiveSymbols].
  final IconData icon;

  /// Whether the glyph is drawn filled.
  final bool selected;

  /// The glyph's size; the ambient `IconTheme`'s when null.
  final double? size;

  /// The glyph's colour; the ambient `IconTheme`'s when null.
  final Color? color;

  /// The stroke weight axis (`wght`, 100–700); the ambient `IconTheme`'s
  /// when null.
  final double? weight;

  /// The grade axis (`GRAD`, −25–200); the ambient `IconTheme`'s when null.
  final double? grade;

  /// The optical size axis (`opsz`, 20–48); the ambient `IconTheme`'s when
  /// null.
  final double? opticalSize;

  /// What a screen reader says; nothing when null.
  final String? semanticLabel;

  @override
  State<ExpressiveIcon> createState() => _ExpressiveIconState();
}

class _ExpressiveIconState extends State<ExpressiveIcon>
    with SingleTickerProviderStateMixin {
  /// How selected the glyph is: 0 at rest, 1 selected.
  late final AnimationController _selection = AnimationController.unbounded(
    vsync: this,
    value: widget.selected ? 1 : 0,
  );

  @override
  void didUpdateWidget(ExpressiveIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    _selection.springTo(
      widget.selected ? 1 : 0,
      ExpressiveMotion.of(context).effects(ExpressiveMotionSpeed.fast),
    );
  }

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rest = IconTheme.of(context).fill ?? ExpressiveSymbolsFont.outlined;
    return AnimatedBuilder(
      animation: _selection,
      builder: (context, _) {
        final fill =
            rest + (ExpressiveSymbolsFont.filled - rest) * _selection.value;
        return Icon(
          widget.icon,
          fill: fill.clamp(
            ExpressiveSymbolsFont.outlined,
            ExpressiveSymbolsFont.filled,
          ),
          size: widget.size,
          color: widget.color,
          weight: widget.weight,
          grade: widget.grade,
          opticalSize: widget.opticalSize,
          semanticLabel: widget.semanticLabel,
        );
      },
    );
  }
}
