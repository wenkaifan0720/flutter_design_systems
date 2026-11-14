import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../theme.dart';

/// How a [FrostedWordmark] sets the name: beside its [mark] (the ink tile
/// with the glyph lit by the spectrum, as the source's `.brand` stands
/// it), as [type] alone in the wordmark face, or on a [badge] of the ink.
enum FrostedWordmarkForm {
  /// The name beside its mark.
  mark,

  /// The name alone.
  type,

  /// The name on a badge of the ink.
  badge,
}

/// The app's name as its mark: lower case in the wordmark type, with its
/// form's company. The sidebar heads itself with it, and a nav root's head
/// takes it where its title would stand ([FrostedPageHeader.wordmark]). It
/// shrinks to the room it is given rather than overflowing. Read aloud as
/// the name alone. One to a page; the page's title still says where it is.
///
/// ```dart
/// FrostedWordmark('Harbor')
/// ```
///
/// ```dart
/// FrostedWordmark('Northlight', glyph: FrostedGlyphs.sparkles)
/// ```
class FrostedWordmark extends StatelessWidget {
  /// Creates a [FrostedWordmark].
  const FrostedWordmark(
    this.name, {
    this.form = FrostedWordmarkForm.mark,
    this.glyph = FrostedGlyphs.triangle,
    super.key,
  });

  /// The app's name, set in lower case.
  final String name;

  /// How it sets the name.
  final FrostedWordmarkForm form;

  /// The glyph on the mark, from the Lucide set (the source's own is a
  /// prism).
  final IconData glyph;

  @override
  Widget build(BuildContext context) => Directionality(
    // Figures, codes and marks read left to right in any language.
    textDirection: TextDirection.ltr,
    child: Builder(builder: _ltrBuild),
  );

  Widget _ltrBuild(BuildContext context) {
    final t = context.frostedTheme;
    final word = name.toLowerCase();
    final Widget mark = switch (form) {
      FrostedWordmarkForm.mark => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.brandGap,
        children: [
          FrostedMark(glyph: glyph),
          Flexible(
            child: Text(
              word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.wordmark,
            ),
          ),
        ],
      ),
      FrostedWordmarkForm.type => Text(
        word,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.textTheme.wordmark,
      ),
      FrostedWordmarkForm.badge => FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(FrostedCorners.rFull),
        gradients: [t.colorScheme.buttonFill],
        sheen: t.colorScheme.buttonSheen,
        shadows: t.shadows.button,
        padding: const EdgeInsets.symmetric(
          horizontal: FrostedSpacing.s14,
          vertical: FrostedSpacing.s6,
        ),
        child: Text(
          word,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.wordmark.at(20).c(t.colorScheme.onButton),
        ),
      ),
    };
    return Semantics(label: name, excludeSemantics: true, child: mark);
  }
}

/// The ink mark (`.mark`): a tile 28 across with its corners at 9 on the
/// ink, a light along its top, its [glyph] 18 lit by the spectrum. The
/// wordmark's company; a sign-in's or an about page's mark on its own.
///
/// ```dart
/// FrostedMark(glyph: FrostedGlyphs.triangle)
/// ```
class FrostedMark extends StatelessWidget {
  /// Creates a [FrostedMark].
  const FrostedMark({
    this.glyph = FrostedGlyphs.triangle,
    this.size = FrostedChromeMetrics.inkMark,
    super.key,
  });

  /// The glyph lit on the tile.
  final IconData glyph;

  /// The tile's side; its corner and glyph scale with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final k = size / FrostedChromeMetrics.inkMark;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(FrostedChromeMetrics.inkMarkRadius * k),
          gradients: [t.colorScheme.buttonFill],
          sheen: t.colorScheme.buttonSheen,
          child: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  t.pearl.rimGradient.createShader(bounds),
              child: Icon(
                glyph,
                size: FrostedChromeMetrics.inkMarkGlyph * k,
                color: t.colorScheme.onButton,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
