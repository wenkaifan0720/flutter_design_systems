/// An app's artwork colours: [ExpressiveArtwork], the slot-to-scheme
/// table `tools/expressive_tokens` bakes from the pictures an app marks,
/// and [ExpressiveArtworkScheme], one picture's scheme. Part of the host
/// layer: a generated app reads them from `lib/app/artwork.g.dart`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color.dart';
import 'internal/color/baked_colors.dart';
import 'theme.dart';

/// One picture's content colour, baked: the scheme a page wears when the
/// picture heads it, as Jetcaster's Now Playing and show pages recolour
/// from the cover.
///
/// `tools/expressive_tokens` bakes one per slot an app's `media.json` marks
/// `scheme`, at each contrast the app's themes wear: the picture's source
/// colour (material-color-utilities' quantizer and score, falling back to
/// the app's seed, never Google Blue), then a vibrant 2025 scheme, light
/// and dark. An app reads them through its generated [ExpressiveArtwork].
@immutable
class ExpressiveArtworkScheme {
  /// An artwork scheme of the given record.
  const ExpressiveArtworkScheme({
    required this.slot,
    required this.image,
    required this.source,
    required this.fallback,
    required this.contrast,
    required this.light,
    required this.dark,
  });

  /// The media slot whose picture this is.
  final String slot;

  /// The picture: its media_corpus id.
  final String image;

  /// The source colour the scheme was baked from, ARGB.
  final int source;

  /// Whether the picture had no colour fit for a theme, so [source] is the
  /// app's seed.
  final bool fallback;

  /// The contrast level the scheme was baked at: 0, 0.5 or 1.
  final double contrast;

  /// Every colour role in light, by [ExpressiveColorRole] name, as ARGB.
  final Map<String, int> light;

  /// Every colour role in dark. Baked, never an inversion of [light].
  final Map<String, int> dark;

  /// The scheme in [brightness]. Throws a [StateError] unless it carries
  /// exactly the [ExpressiveColorRole]s.
  ExpressiveColorScheme colors(Brightness brightness) =>
      expressiveColorsFromArgb(
        brightness == Brightness.dark ? dark : light,
        'The artwork scheme of "$slot"',
      );
}

/// An app's artwork: the slot-to-scheme table `tools/expressive_tokens`
/// generates (`lib/app/artwork.g.dart`, `appArtwork`).
///
/// A page a picture heads mounts [retint] of its theme on an
/// [ExpressiveTheme] around itself, and cross-fades between schemes
/// with [ExpressiveColorScheme.lerp] on the theme's spring. Only colour
/// changes: type, shape, motion and the expression budget stay the
/// theme's.
@immutable
class ExpressiveArtwork {
  /// Artwork of the given [themes] and [schemes].
  const ExpressiveArtwork({required this.themes, required this.schemes});

  /// Each of the app's own themes' contrast, by theme id.
  final Map<String, double> themes;

  /// Every slot's scheme, at each contrast in [themes].
  final List<ExpressiveArtworkScheme> schemes;

  /// Every slot that has a scheme.
  Set<String> get slots => {for (final scheme in schemes) scheme.slot};

  /// [slot]'s scheme for [theme]: at the contrast of the app theme [theme]
  /// is, in its brightness. Null when [theme] is none of the app's own
  /// themes (a system preset, as the gate's robustness look wears), which
  /// a picture never retints. Throws an [ArgumentError] for a slot with no
  /// scheme, and a [StateError] when the slot was not baked at that
  /// theme's contrast.
  ExpressiveColorScheme? colorsFor(String slot, ExpressiveThemeData theme) {
    if (!slots.contains(slot)) {
      throw ArgumentError.value(
        slot,
        'slot',
        'No artwork scheme; the app has ${slots.isEmpty ? 'none' : slots.join(', ')}',
      );
    }
    final contrast = themes[theme.id];
    if (contrast == null) return null;
    for (final scheme in schemes) {
      if (scheme.slot == slot && scheme.contrast == contrast) {
        return scheme.colors(theme.brightness);
      }
    }
    throw StateError(
      'The artwork scheme of "$slot" was not baked at contrast $contrast.',
    );
  }

  /// [theme] with its colours replaced by [slot]'s picture's
  /// ([colorsFor]); [theme] itself when it is none of the app's own.
  ExpressiveThemeData retint(ExpressiveThemeData theme, String slot) {
    final colors = colorsFor(slot, theme);
    return colors == null ? theme : theme.copyWith(colors: colors);
  }
}
