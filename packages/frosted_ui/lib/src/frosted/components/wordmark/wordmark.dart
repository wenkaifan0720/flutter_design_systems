import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawCorner;

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../theme.dart';

/// How a [FrostedWordmark] sets the name: beside its [mark] (the ink tile with
/// the glyph lit by the spectrum), as [type]
/// alone in the wordmark face, or on a [badge] of the ink.
enum FrostedWordmarkForm {
  /// The name beside its mark.
  mark,

  /// The name alone.
  type,

  /// The name on a badge of the ink.
  badge,
}

/// The app's name as its mark: in the wordmark type as it is given, with
/// its form's company: the ink mark, or the app's own [logo] in its place. The sidebar heads itself with it, and a nav root's head
/// takes it where its title would stand (`FrostedPageHeader.wordmark`). It
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
///
/// ```dart
/// FrostedWordmark('Shelf', logo: FlutterLogo())
/// ```
class FrostedWordmark extends StatelessWidget {
  /// Creates a [FrostedWordmark].
  const FrostedWordmark(
    this.name, {
    this.form = FrostedWordmarkForm.mark,
    this.glyph = FrostedGlyphs.triangle,
    this.logo,
    super.key,
  });

  /// The app's name, drawn as it is given.
  final String name;

  /// How it sets the name.
  final FrostedWordmarkForm form;

  /// The glyph on the mark, from the Lucide set.
  final IconData glyph;

  /// The app's own logo, standing in the mark's place in a 28 square (its
  /// words beside it); null draws the ink mark with [glyph]. Decoration:
  /// the wordmark is read as [name].
  final Widget? logo;

  @override
  Widget build(BuildContext context) => Align(
    // The lockup stands at the start of a slot wider than it, in either
    // direction.
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    heightFactor: 1,
    child: Directionality(
      // Figures, codes and marks read left to right in any language.
      textDirection: TextDirection.ltr,
      child: Builder(builder: _ltrBuild),
    ),
  );

  Widget _ltrBuild(BuildContext context) {
    final t = context.frostedTheme;
    final word = name;
    final Widget mark = switch (form) {
      FrostedWordmarkForm.mark => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.brandGap,
        children: [
          if (logo case final logo?)
            SizedBox.square(
              dimension: FrostedChromeMetrics.inkMark,
              child: logo,
            )
          else
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(
        EnumProperty<FrostedWordmarkForm>(
          'form',
          form,
          defaultValue: FrostedWordmarkForm.mark,
        ),
      )
      ..add(
        DiagnosticsProperty<IconData>(
          'glyph',
          glyph,
          defaultValue: FrostedGlyphs.triangle,
        ),
      )
      ..add(DiagnosticsProperty<Widget>('logo', logo, defaultValue: null));
  }
}

/// The ink mark: a tile 28 across with its corners at 9 on the ink, a light
/// along its top, its [glyph] 18 lit by the spectrum. The wordmark's company; a
/// sign-in's or an about page's mark on its own.
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
          radius: BorderRadius.circular(
            t.corner(RawCorner.small, FrostedChromeMetrics.inkMarkRadius) * k,
          ),
          gradients: [t.colorScheme.buttonFill],
          sheen: t.colorScheme.buttonSheen,
          child: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              // The look's five spectrum hues, corner to corner (the
              // pearl card's rim is neutral; the mark keeps its colour).
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: t.glass.spectrumStops,
                stops: const [0, 0.35, 0.6, 0.82, 1],
              ).createShader(bounds),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<IconData>(
          'glyph',
          glyph,
          defaultValue: FrostedGlyphs.triangle,
        ),
      )
      ..add(
        DoubleProperty(
          'size',
          size,
          defaultValue: FrostedChromeMetrics.inkMark,
        ),
      );
  }
}
