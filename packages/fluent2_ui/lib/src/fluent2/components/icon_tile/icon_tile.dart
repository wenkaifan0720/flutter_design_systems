import 'package:flutter/widgets.dart';

import '../../internal/well.dart';
import '../../theme.dart';
import '../avatar/avatar.dart';

/// The hue an icon tile or a category wears: the [brand], [neutral], or
/// one of Fluent's thirty named hues (the colourful avatar's), each its
/// `palette<Name>Background2` fill under its `palette<Name>Foreground2`
/// glyph, a pair that holds 4.5:1 in light and dark. The brand is
/// `brandBackground2` under `brandForeground2`; neutral Fluent's grey
/// (laid over the ground it stands on) under `neutralForeground3`.
enum Fluent2Hue {
  /// The brand colour.
  brand,

  /// The neutral grey.
  neutral,

  /// Fluent's shared `darkRed`.
  darkRed,

  /// Fluent's shared `cranberry`.
  cranberry,

  /// Fluent's shared `red`.
  red,

  /// Fluent's shared `pumpkin`.
  pumpkin,

  /// Fluent's shared `peach`.
  peach,

  /// Fluent's shared `marigold`.
  marigold,

  /// Fluent's shared `gold`.
  gold,

  /// Fluent's shared `brass`.
  brass,

  /// Fluent's shared `brown`.
  brown,

  /// Fluent's shared `forest`.
  forest,

  /// Fluent's shared `seafoam`.
  seafoam,

  /// Fluent's shared `darkGreen`.
  darkGreen,

  /// Fluent's shared `lightTeal`.
  lightTeal,

  /// Fluent's shared `teal`.
  teal,

  /// Fluent's shared `steel`.
  steel,

  /// Fluent's shared `blue`.
  blue,

  /// Fluent's shared `royalBlue`.
  royalBlue,

  /// Fluent's shared `cornflower`.
  cornflower,

  /// Fluent's shared `navy`.
  navy,

  /// Fluent's shared `lavender`.
  lavender,

  /// Fluent's shared `purple`.
  purple,

  /// Fluent's shared `grape`.
  grape,

  /// Fluent's shared `lilac`.
  lilac,

  /// Fluent's shared `pink`.
  pink,

  /// Fluent's shared `magenta`.
  magenta,

  /// Fluent's shared `plum`.
  plum,

  /// Fluent's shared `beige`.
  beige,

  /// Fluent's shared `mink`.
  mink,

  /// Fluent's shared `platinum`.
  platinum,

  /// Fluent's shared `anchor`.
  anchor;

  /// This hue's fill and ink in [t].
  (Color fill, Color ink) of(Fluent2ThemeData t) {
    final s = t.sharedColors;
    return switch (this) {
      // The brand tint a shade deeper where the page would swallow it.
      brand => (fluent2BrandWell(t), t.colors.brandForeground2),
      // Fluent's grey laid over the ground, so a neutral tile shows on the
      // tinted page as on a card.
      neutral => (fluent2Well(t), t.colors.neutralForeground3),
      darkRed => (s.paletteDarkRedBackground2, s.paletteDarkRedForeground2),
      cranberry => (
        s.paletteCranberryBackground2,
        s.paletteCranberryForeground2,
      ),
      red => (s.paletteRedBackground2, s.paletteRedForeground2),
      pumpkin => (s.palettePumpkinBackground2, s.palettePumpkinForeground2),
      peach => (s.palettePeachBackground2, s.palettePeachForeground2),
      marigold => (s.paletteMarigoldBackground2, s.paletteMarigoldForeground2),
      gold => (s.paletteGoldBackground2, s.paletteGoldForeground2),
      brass => (s.paletteBrassBackground2, s.paletteBrassForeground2),
      brown => (s.paletteBrownBackground2, s.paletteBrownForeground2),
      forest => (s.paletteForestBackground2, s.paletteForestForeground2),
      seafoam => (s.paletteSeafoamBackground2, s.paletteSeafoamForeground2),
      darkGreen => (
        s.paletteDarkGreenBackground2,
        s.paletteDarkGreenForeground2,
      ),
      lightTeal => (
        s.paletteLightTealBackground2,
        s.paletteLightTealForeground2,
      ),
      teal => (s.paletteTealBackground2, s.paletteTealForeground2),
      steel => (s.paletteSteelBackground2, s.paletteSteelForeground2),
      blue => (s.paletteBlueBackground2, s.paletteBlueForeground2),
      royalBlue => (
        s.paletteRoyalBlueBackground2,
        s.paletteRoyalBlueForeground2,
      ),
      cornflower => (
        s.paletteCornflowerBackground2,
        s.paletteCornflowerForeground2,
      ),
      navy => (s.paletteNavyBackground2, s.paletteNavyForeground2),
      lavender => (s.paletteLavenderBackground2, s.paletteLavenderForeground2),
      purple => (s.palettePurpleBackground2, s.palettePurpleForeground2),
      grape => (s.paletteGrapeBackground2, s.paletteGrapeForeground2),
      lilac => (s.paletteLilacBackground2, s.paletteLilacForeground2),
      pink => (s.palettePinkBackground2, s.palettePinkForeground2),
      magenta => (s.paletteMagentaBackground2, s.paletteMagentaForeground2),
      plum => (s.palettePlumBackground2, s.palettePlumForeground2),
      beige => (s.paletteBeigeBackground2, s.paletteBeigeForeground2),
      mink => (s.paletteMinkBackground2, s.paletteMinkForeground2),
      platinum => (s.palettePlatinumBackground2, s.palettePlatinumForeground2),
      anchor => (s.paletteAnchorBackground2, s.paletteAnchorForeground2),
    };
  }
}

/// A glyph on a square of one of Fluent's named hues, the icon tile set
/// at the start of a list row or a card to say what
/// kind of thing it is (a folder, a meeting, a plan): [icon] in the
/// [hue]'s ink on its fill, [size] across (24 to 48; 40 by default) with
/// the square avatar's corners and the glyph a step smaller (16 at 24 and
/// 28, 20 at 32 and 36, 24 at 40 and 44, 28 at 48). Derived: Fluent has no
/// icon tile; it is the square avatar with a glyph. Read as an image named
/// [label]; with no label it is silent, its row saying what it is.
///
/// ```dart
/// Fluent2IconTile(Fluent2Icons.folder, hue: Fluent2Hue.cornflower, label: 'Folder')
/// ```
class Fluent2IconTile extends StatelessWidget {
  /// A tile showing [icon] on [hue]'s tint.
  const Fluent2IconTile(
    this.icon, {
    this.hue = Fluent2Hue.brand,
    this.size = 40,
    this.label,
    super.key,
  });

  /// The glyph on the tile.
  final IconData icon;

  /// The tile's colour.
  final Fluent2Hue hue;

  /// Its side, 24 to 48.
  final double size;

  /// What a screen reader hears; null is silent.
  final String? label;

  /// The glyph at a tile's [size].
  static double glyphOf(double size) => size >= 48
      ? 28
      : size >= 40
      ? 24
      : size >= 32
      ? 20
      : 16;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final (fill, ink) = hue.of(t);
    final tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Fluent2Avatar.squareRadius(size)),
      ),
      child: Icon(icon, size: glyphOf(size), color: ink),
    );
    final name = label;
    if (name == null) return ExcludeSemantics(child: tile);
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: tile,
    );
  }
}

/// A day set as a block, the date an agenda's rows and event cards lead
/// with: the short weekday over the day's number in title3 over the short
/// month, in caption1, on Fluent's grey with 4 corners; [emphasis]
/// (today, the day picked) wears the brand's tint (`brandBackground2`
/// under `brandForeground2`). [compact] drops the weekday. Derived:
/// composed from Fluent's type ramp and tints. Read as the whole date,
/// "Monday, November 3".
///
/// ```dart
/// Fluent2DateBlock(date: DateTime(2026, 11, 3), emphasis: true)
/// ```
class Fluent2DateBlock extends StatelessWidget {
  /// A block showing [date]'s month and day.
  const Fluent2DateBlock({
    required this.date,
    this.emphasis = false,
    this.compact = false,
    super.key,
  });

  /// The date shown.
  final DateTime date;

  /// Wear the brand's tint.
  final bool emphasis;

  /// Leave the weekday out.
  final bool compact;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// The weekday's English name, Monday to Sunday.
  static String weekdayOf(DateTime d) => _weekdays[d.weekday - 1];

  /// The month's English name.
  static String monthOf(DateTime d) => _months[d.month - 1];

  /// [date] said whole: "Monday, November 3".
  static String spoken(DateTime date) =>
      '${weekdayOf(date)}, ${monthOf(date)} ${date.day}';

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final fill = emphasis ? fluent2BrandWell(t) : fluent2Well(t);
    final ink = emphasis ? t.colors.brandForeground2 : t.textSecondary;
    final figure = emphasis ? t.colors.brandForeground2 : t.textPrimary;
    return Semantics(
      label: spoken(date),
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: Fluent2Spacing.s,
          vertical: Fluent2Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(Fluent2Radius.medium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact)
              Text(
                weekdayOf(date).substring(0, 3),
                maxLines: 1,
                style: t.caption1.c(ink),
              ),
            Text('${date.day}', maxLines: 1, style: t.title3.tabular.c(figure)),
            Text(
              monthOf(date).substring(0, 3),
              maxLines: 1,
              style: t.caption1.c(ink),
            ),
          ],
        ),
      ),
    );
  }
}
