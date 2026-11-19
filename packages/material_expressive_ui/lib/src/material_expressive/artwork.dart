/// Colour schemes derived from artwork.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color.dart';
import 'internal/color/baked_colors.dart';
import 'theme.dart';

/// A picture’s light and dark colour roles at a given contrast.
///
/// [source] is the colour used to build the schemes. [fallback] identifies a scheme built from the app’s seed.
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

  /// The identifier of the source image.
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

/// Looks up a picture’s colour scheme for the active app theme.
///
/// Use [retint] to apply the scheme to a page headed by that picture.
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

  /// The artwork colours for [slot] at [theme]’s brightness and contrast.
  ///
  /// Returns null for an unregistered theme. Throws [ArgumentError] for an unknown slot or [StateError] when its contrast is unavailable.
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
