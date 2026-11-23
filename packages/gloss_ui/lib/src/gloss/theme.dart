/// Gloss's theme: its glazes and inks, its type, its spacing, its depths and
/// corners, its motion, its density, the part themes, and the [GlossTheme]
/// every app installs once in its `builder:`.
library;

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/platform_words.dart';
import 'page_transitions.dart';

/// How one part of Gloss looks, as Material's `ButtonStyle` is: every slot a
/// `WidgetStateProperty`, read from a part's `style:` first, then from its
/// part theme on [GlossThemeData], then from the look's own default.
///
/// A part reads `fill` as its glaze's middle colour, `foreground` as its
/// words and glyphs, `edge` as the rim round its glaze, `shape` as its
/// outline, `padding`, `minimumSize`, `textStyle` and `iconSize` as Material's
/// buttons do.
///
/// ```dart
/// final roomy = GlossStyle(padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)));
/// ```
typedef GlossStyle = DesignStyle;

/// How tight Gloss's controls stand: [DesignDensity.standard] (a 48 px
/// control), [DesignDensity.comfortable] (44) or [DesignDensity.compact] (40).
/// The default adapts: compact on a desktop, standard on touch. A control's
/// tap target stays at the floor for the input whatever the density.
typedef GlossDensity = DesignDensity;

/// The look's constants: its corners, its depths and its light. They are not
/// settings: one light from the top and parts moulded at these radii are what
/// Gloss is.
abstract final class GlossMetrics {
  /// A control's height at [DesignDensity.standard], before density.
  static const double controlHeight = 48;

  /// A list row's least height at [DesignDensity.standard].
  static const double rowHeight = 52;

  /// The corner of a field, a select and the small wells inside a panel.
  static const double fieldRadius = 12;

  /// The corner of a well holding a group of rows.
  static const double wellRadius = 16;

  /// The corner of a card (an object's tile).
  static const double cardRadius = 18;

  /// The corner of a dialog and a sheet's top.
  static const double panelRadius = 24;

  /// The corner of a checkbox's socket.
  static const double socketRadius = 7;

  /// How far a key sinks when pressed home.
  static const double keyTravel = 1.5;

  /// How much of a raised part's height its specular lens covers, from the
  /// top: it ends above the capitals of a centred label at every size, so a
  /// label never sits on the shine.
  static const double lensFraction = 0.34;

  /// The reflected light fits within the part.
  @Deprecated('Glaze reflections are painted within the part.')
  static const double focusGap = 0;

  /// The legacy focus-band width. Glaze reflections follow the surface.
  @Deprecated('Glaze reflections follow the surface.')
  static const double focusWidth = 0;

  /// The space needed outside a focused part.
  static const double focusReach = 0;

  /// The room a bead, a fill, a picture or a ring keeps from the rim round
  /// it: enough for the rim's light and shade to show between them.
  static const double rimRoom = 2;

  /// A sunken frame's rim (a carousel's, a picture's, a colour area's, the
  /// menu bar's strip): what the frame shows of itself round what it holds.
  static const double frameRim = 3;

  /// The seam between two halves of one moulding (a split key's): a key's
  /// travel wide, so the halves read as one part with a cut in it.
  static const double seam = 1.5;

  /// Between a line of words and the line under it that belongs to it (a
  /// term and its value, a title and its message): a breath, not a gap.
  static const double lineGap = 2;

  /// A rim's hairline: how far a fill stands in from the socket it fills.
  static const double hairline = 1;

  /// The widest a form, a dialog's words or a reading column stands.
  static const double readingWidth = 640;

  /// Where the navigation turns from the bottom bar to the rail.
  static const double railBreakpoint = 600;

  /// Where the navigation turns from the rail to the sidebar.
  static const double sidebarBreakpoint = 1024;
}

/// Gloss's spacing, on a 4 px grid ([DesignSpacingScope] declares it).
abstract final class GlossSpacing {
  /// The grid every gap, inset and offset stands on.
  static const double grid = 4;

  /// Inside a control: an icon and its words.
  static const double tight = 4;

  /// Between a label and its field, between lines of one item.
  static const double small = 8;

  /// A short gap in a row; a key's room round its words, vertically.
  static const double medium = 12;

  /// A row's inset in its well, and the page margin on a phone.
  static const double regular = 16;

  /// Between groups, and the page margin on a tablet.
  static const double large = 24;

  /// Between sections, and the page margin on a desktop.
  static const double extraLarge = 32;

  /// Above a page's first heading on a wide screen.
  static const double huge = 48;

  /// The page margin for a window [width] wide: 16 on a phone, 24 on a
  /// tablet, 32 on a desktop.
  static double pageMargin(double width) => width >= 1024
      ? extraLarge
      : width >= 600
      ? large
      : regular;
}

/// Gloss's motion: springs, run through `DesignMotionPolicy`, which honours
/// Reduce Motion. Moulded parts settle: a key returns with a small give, a
/// bead snaps through and settles, a panel rises and stops.
abstract final class GlossMotion {
  /// A key's press and return: a little give on the way back.
  static const double pressDamping = 0.78;

  /// A key's press and return.
  static const double pressStiffness = 1400;

  /// A bead or a thumb snapping to its new place.
  static const double snapDamping = 0.72;

  /// A bead or a thumb snapping to its new place.
  static const double snapStiffness = 700;

  /// A glaze, a light or a word changing colour: no overshoot.
  static const double colorStiffness = 1100;

  /// A dialog, a sheet, a menu or a toast arriving or leaving.
  static const double panelDamping = 0.9;

  /// A dialog, a sheet, a menu or a toast arriving or leaving.
  static const double panelStiffness = 520;
}

/// Gloss's colours, by role: the glazes its parts are moulded in, and the
/// inks on them.
///
/// The page is [page] porcelain; chrome bars run [barTop] to [barBottom];
/// wells are [well]; neutral parts are pearl ([pearlTop] to [pearlBottom]);
/// the one action and what is on are jade ([jadeTop], [jade], [jadeBottom]),
/// with [onJade] words. [ink] and [inkSecondary] are the words.
@immutable
class GlossColors with Diagnosticable {
  /// Colours given one by one; [GlossColors.light] and [GlossColors.dark] are
  /// the look's own.
  const GlossColors({
    required this.brightness,
    required this.page,
    required this.barTop,
    required this.barMiddle,
    required this.barBottom,
    required this.barEdge,
    required this.well,
    required this.wellShade,
    required this.hairline,
    required this.lip,
    required this.pearlTop,
    required this.pearlBottom,
    required this.pearlEdge,
    required this.jadeTop,
    required this.jade,
    required this.jadeBottom,
    required this.jadeEdge,
    required this.jadeGlow,
    required this.onJade,
    required this.jadeInk,
    required this.ink,
    required this.inkSecondary,
    required this.inkDisabled,
    required this.danger,
    required this.dangerTop,
    required this.dangerFill,
    required this.dangerBottom,
    required this.dangerEdge,
    required this.onDanger,
    required this.focus,
    required this.shadow,
    required this.scrim,
    required this.letterpress,
  });

  /// The look by day: a cool porcelain page, white wells, pearl and jade.
  const GlossColors.light()
    : brightness = Brightness.light,
      page = const Color(0xFFE6E9ED),
      barTop = const Color(0xFFF1F3F5),
      barMiddle = const Color(0xFFEBEEF1),
      barBottom = const Color(0xFFE3E7EB),
      barEdge = const Color(0xFFAAB4BE),
      well = const Color(0xFFE0E4E9),
      wellShade = const Color(0x40142A3C),
      // Dark enough to read as a cut in a light well's floor, the light
      // caught under it.
      hairline = const Color(0xFFD3D9DF),
      lip = const Color(0xF2FFFFFF),
      pearlTop = const Color(0xFFFFFFFF),
      pearlBottom = const Color(0xFFDDE3E9),
      pearlEdge = const Color(0x57283C50),
      jadeTop = const Color(0xFF1C9A72),
      jade = const Color(0xFF0E7652),
      jadeBottom = const Color(0xFF075B3E),
      jadeEdge = const Color(0xFF054B33),
      jadeGlow = const Color(0x8070F0C3),
      onJade = const Color(0xFFFFFFFF),
      jadeInk = const Color(0xFF0A6A48),
      ink = const Color(0xFF1F2830),
      inkSecondary = const Color(0xFF505B66),
      inkDisabled = const Color(0xFF8C96A0),
      danger = const Color(0xFFB4232D),
      dangerTop = const Color(0xFFCF4A52),
      dangerFill = const Color(0xFFAA2C35),
      dangerBottom = const Color(0xFF8A1E27),
      dangerEdge = const Color(0xFF6F1720),
      onDanger = const Color(0xFFFFFFFF),
      focus = const Color(0xFF0C7A54),
      shadow = const Color(0xFF14283C),
      // A dimming, not a grey wash: a deep cool shade over the porcelain.
      scrim = const Color(0x6610181F),
      letterpress = const Color(0xE6FFFFFF);

  /// The same objects in low light: a graphite glaze, deeper wells, dark
  /// pearl; the jade keeps its colour.
  const GlossColors.dark()
    : brightness = Brightness.dark,
      page = const Color(0xFF1B1E22),
      barTop = const Color(0xFF2D3238),
      barMiddle = const Color(0xFF262A2F),
      barBottom = const Color(0xFF202428),
      barEdge = const Color(0xFF0B0D0F),
      well = const Color(0xFF14171A),
      wellShade = const Color(0x99000000),
      hairline = const Color(0xFF343A40),
      // Enough light on a socket's lower rim that an empty one (a box not
      // ticked, a dot not current) still reads in the dark.
      lip = const Color(0x1FFFFFFF),
      // A moonlit pearl, not grey plastic and never bronze: cool slate from
      // its crown to its foot, on the page's own cool cast; its rim a soft
      // shadow rather than an outline.
      pearlTop = const Color(0xFF636B74),
      pearlBottom = const Color(0xFF454B53),
      pearlEdge = const Color(0x80000000),
      jadeTop = const Color(0xFF1FA077),
      jade = const Color(0xFF0F7A55),
      jadeBottom = const Color(0xFF085E40),
      jadeEdge = const Color(0xFF02301F),
      jadeGlow = const Color(0x7360E0B0),
      onJade = const Color(0xFFFFFFFF),
      jadeInk = const Color(0xFF52CDA0),
      ink = const Color(0xFFE6EAEE),
      inkSecondary = const Color(0xFFA6AFB8),
      inkDisabled = const Color(0xFF6C747D),
      danger = const Color(0xFFFF7D84),
      dangerTop = const Color(0xFFCF4A52),
      dangerFill = const Color(0xFFAA2C35),
      dangerBottom = const Color(0xFF8A1E27),
      dangerEdge = const Color(0xFF3E0A10),
      onDanger = const Color(0xFFFFFFFF),
      focus = const Color(0xFF4FD3A2),
      shadow = const Color(0xFF000000),
      scrim = const Color(0x8C000000),
      letterpress = const Color(0xB3000000);

  /// Light or dark.
  final Brightness brightness;

  /// The porcelain page: level, smooth, the ground everything sits on.
  final Color page;

  /// A chrome bar's glaze at its top edge.
  final Color barTop;

  /// A chrome bar's glaze at its middle.
  final Color barMiddle;

  /// A chrome bar's glaze at its foot.
  final Color barBottom;

  /// The line under a chrome bar where it meets the page.
  final Color barEdge;

  /// A well's floor: where rows, fields and readings sit.
  final Color well;

  /// The shade a well's rim casts on its floor, from the light above.
  final Color wellShade;

  /// The engraved line between a well's rows.
  final Color hairline;

  /// The light caught along a sunken part's lower rim, and under an engraved
  /// line.
  final Color lip;

  /// A pearl part's glaze at its top.
  final Color pearlTop;

  /// A pearl part's glaze at its foot.
  final Color pearlBottom;

  /// The rim round a pearl part.
  final Color pearlEdge;

  /// The jade gel at its top.
  final Color jadeTop;

  /// The jade gel at its middle, where a label sits: words on it are
  /// [onJade], at 4.5:1 or more.
  final Color jade;

  /// The jade gel at its foot.
  final Color jadeBottom;

  /// The rim round a jade part.
  final Color jadeEdge;

  /// The light inside the jade gel, glowing up from its foot.
  final Color jadeGlow;

  /// Words and glyphs on jade.
  final Color onJade;

  /// Jade as words and glyphs on a well or the page: a chosen row's glyph, a
  /// link, a current place.
  final Color jadeInk;

  /// Words.
  final Color ink;

  /// Supporting words: a row's second line, a value, a caption.
  final Color inkSecondary;

  /// Words and glyphs of a part that is off.
  final Color inkDisabled;

  /// Words of what destroys or is wrong.
  final Color danger;

  /// The ruby gel of a destructive confirm, at its top.
  final Color dangerTop;

  /// The ruby gel at its middle, where its label sits.
  final Color dangerFill;

  /// The ruby gel at its foot.
  final Color dangerBottom;

  /// The rim round the ruby gel.
  final Color dangerEdge;

  /// Words on the ruby gel.
  final Color onDanger;

  /// The tint used when a glazed part catches the light.
  final Color focus;

  /// The colour of every drop shadow (its strength is the part's).
  final Color shadow;

  /// The page behind a dialog or a sheet.
  final Color scrim;

  /// The letterpress line: light under pressed words by day, dark over them
  /// by night.
  final Color letterpress;

  /// Whether pressed words carry their line below (day) or above (night).
  bool get letterpressBelow => brightness == Brightness.light;

  /// A copy with the given colours replaced.
  GlossColors copyWith({
    Brightness? brightness,
    Color? page,
    Color? barTop,
    Color? barMiddle,
    Color? barBottom,
    Color? barEdge,
    Color? well,
    Color? wellShade,
    Color? hairline,
    Color? lip,
    Color? pearlTop,
    Color? pearlBottom,
    Color? pearlEdge,
    Color? jadeTop,
    Color? jade,
    Color? jadeBottom,
    Color? jadeEdge,
    Color? jadeGlow,
    Color? onJade,
    Color? jadeInk,
    Color? ink,
    Color? inkSecondary,
    Color? inkDisabled,
    Color? danger,
    Color? dangerTop,
    Color? dangerFill,
    Color? dangerBottom,
    Color? dangerEdge,
    Color? onDanger,
    Color? focus,
    Color? shadow,
    Color? scrim,
    Color? letterpress,
  }) => GlossColors(
    brightness: brightness ?? this.brightness,
    page: page ?? this.page,
    barTop: barTop ?? this.barTop,
    barMiddle: barMiddle ?? this.barMiddle,
    barBottom: barBottom ?? this.barBottom,
    barEdge: barEdge ?? this.barEdge,
    well: well ?? this.well,
    wellShade: wellShade ?? this.wellShade,
    hairline: hairline ?? this.hairline,
    lip: lip ?? this.lip,
    pearlTop: pearlTop ?? this.pearlTop,
    pearlBottom: pearlBottom ?? this.pearlBottom,
    pearlEdge: pearlEdge ?? this.pearlEdge,
    jadeTop: jadeTop ?? this.jadeTop,
    jade: jade ?? this.jade,
    jadeBottom: jadeBottom ?? this.jadeBottom,
    jadeEdge: jadeEdge ?? this.jadeEdge,
    jadeGlow: jadeGlow ?? this.jadeGlow,
    onJade: onJade ?? this.onJade,
    jadeInk: jadeInk ?? this.jadeInk,
    ink: ink ?? this.ink,
    inkSecondary: inkSecondary ?? this.inkSecondary,
    inkDisabled: inkDisabled ?? this.inkDisabled,
    danger: danger ?? this.danger,
    dangerTop: dangerTop ?? this.dangerTop,
    dangerFill: dangerFill ?? this.dangerFill,
    dangerBottom: dangerBottom ?? this.dangerBottom,
    dangerEdge: dangerEdge ?? this.dangerEdge,
    onDanger: onDanger ?? this.onDanger,
    focus: focus ?? this.focus,
    shadow: shadow ?? this.shadow,
    scrim: scrim ?? this.scrim,
    letterpress: letterpress ?? this.letterpress,
  );

  List<Color> get _all => [
    page,
    barTop,
    barMiddle,
    barBottom,
    barEdge,
    well,
    wellShade,
    hairline,
    lip,
    pearlTop,
    pearlBottom,
    pearlEdge,
    jadeTop,
    jade,
    jadeBottom,
    jadeEdge,
    jadeGlow,
    onJade,
    jadeInk,
    ink,
    inkSecondary,
    inkDisabled,
    danger,
    dangerTop,
    dangerFill,
    dangerBottom,
    dangerEdge,
    onDanger,
    focus,
    shadow,
    scrim,
    letterpress,
  ];

  static const List<String> _names = [
    'page',
    'barTop',
    'barMiddle',
    'barBottom',
    'barEdge',
    'well',
    'wellShade',
    'hairline',
    'lip',
    'pearlTop',
    'pearlBottom',
    'pearlEdge',
    'jadeTop',
    'jade',
    'jadeBottom',
    'jadeEdge',
    'jadeGlow',
    'onJade',
    'jadeInk',
    'ink',
    'inkSecondary',
    'inkDisabled',
    'danger',
    'dangerTop',
    'dangerFill',
    'dangerBottom',
    'dangerEdge',
    'onDanger',
    'focus',
    'shadow',
    'scrim',
    'letterpress',
  ];

  /// Between [a] and [b] at [t].
  static GlossColors lerp(GlossColors a, GlossColors b, double t) {
    if (identical(a, b)) return a;
    final x = a._all;
    final y = b._all;
    Color c(int i) => Color.lerp(x[i], y[i], t)!;
    return GlossColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      page: c(0),
      barTop: c(1),
      barMiddle: c(2),
      barBottom: c(3),
      barEdge: c(4),
      well: c(5),
      wellShade: c(6),
      hairline: c(7),
      lip: c(8),
      pearlTop: c(9),
      pearlBottom: c(10),
      pearlEdge: c(11),
      jadeTop: c(12),
      jade: c(13),
      jadeBottom: c(14),
      jadeEdge: c(15),
      jadeGlow: c(16),
      onJade: c(17),
      jadeInk: c(18),
      ink: c(19),
      inkSecondary: c(20),
      inkDisabled: c(21),
      danger: c(22),
      dangerTop: c(23),
      dangerFill: c(24),
      dangerBottom: c(25),
      dangerEdge: c(26),
      onDanger: c(27),
      focus: c(28),
      shadow: c(29),
      scrim: c(30),
      letterpress: c(31),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlossColors &&
      other.brightness == brightness &&
      listEquals(other._all, _all);

  @override
  int get hashCode => Object.hash(brightness, Object.hashAll(_all));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    final all = _all;
    for (var i = 0; i < all.length; i++) {
      properties.add(ColorProperty(_names[i], all[i]));
    }
  }
}

/// The `wght` axis of Gloss's variable face set to [weight]: pass it with
/// every `fontWeight` a style changes, so the face draws that weight.
///
/// ```dart
/// style.copyWith(fontWeight: FontWeight.w700, fontVariations: glossWeightAxis(FontWeight.w700))
/// ```
List<FontVariation> glossWeightAxis(FontWeight weight) => [
  FontVariation.weight(weight.value.toDouble()),
];

/// Gloss's type: one face, Plus Jakarta Sans, in seven roles. A screen uses
/// four at most.
@immutable
class GlossTextTheme with Diagnosticable {
  /// Styles given one by one; [GlossTextTheme.from] is the look's own.
  const GlossTextTheme({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.secondary,
    required this.caption,
  });

  /// The look's type in [colors]' inks, set in [fontFamily] (from
  /// [fontPackage]) when given: a brand's face, or one for a script Plus
  /// Jakarta Sans does not carry.
  factory GlossTextTheme.from(
    GlossColors colors, {
    String? fontFamily,
    String? fontPackage,
  }) {
    final family = fontFamily ?? glossFontFamily;
    final package = fontFamily == null ? glossFontPackage : fontPackage;
    TextStyle face(
      double size,
      double height,
      FontWeight weight, {
      double tracking = 0,
      Color? color,
    }) => TextStyle(
      inherit: false,
      fontFamily: family,
      package: package,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: tracking,
      fontVariations: glossWeightAxis(weight),
      color: color ?? colors.ink,
      leadingDistribution: TextLeadingDistribution.even,
      decoration: TextDecoration.none,
      textBaseline: TextBaseline.alphabetic,
    );
    return GlossTextTheme(
      display: face(32, 40, FontWeight.w700, tracking: -0.6),
      headline: face(24, 32, FontWeight.w700, tracking: -0.3),
      title: face(18, 24, FontWeight.w600, tracking: -0.1),
      body: face(16, 24, FontWeight.w400),
      label: face(16, 20, FontWeight.w600),
      secondary: face(14, 20, FontWeight.w400, color: colors.inkSecondary),
      caption: face(13, 16, FontWeight.w600, tracking: 0.2),
    );
  }

  /// The one big thing on a screen: a recipe's name on its page.
  final TextStyle display;

  /// A page's object, a section's lead.
  final TextStyle headline;

  /// Bars, dialogs, cards' names.
  final TextStyle title;

  /// Reading: steps, notes, a row's words.
  final TextStyle body;

  /// Controls' words: keys, tabs, rows' names.
  final TextStyle label;

  /// Supporting lines: a row's second line, a value, help under a field.
  final TextStyle secondary;

  /// Section heads letterpressed on the page, tags, small counts.
  final TextStyle caption;

  /// A copy with the given styles replaced.
  GlossTextTheme copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? secondary,
    TextStyle? caption,
  }) => GlossTextTheme(
    display: display ?? this.display,
    headline: headline ?? this.headline,
    title: title ?? this.title,
    body: body ?? this.body,
    label: label ?? this.label,
    secondary: secondary ?? this.secondary,
    caption: caption ?? this.caption,
  );

  /// Between [a] and [b] at [t].
  static GlossTextTheme lerp(GlossTextTheme a, GlossTextTheme b, double t) {
    if (identical(a, b)) return a;
    TextStyle s(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return GlossTextTheme(
      display: s(a.display, b.display),
      headline: s(a.headline, b.headline),
      title: s(a.title, b.title),
      body: s(a.body, b.body),
      label: s(a.label, b.label),
      secondary: s(a.secondary, b.secondary),
      caption: s(a.caption, b.caption),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlossTextTheme &&
      other.display == display &&
      other.headline == headline &&
      other.title == title &&
      other.body == body &&
      other.label == label &&
      other.secondary == secondary &&
      other.caption == caption;

  @override
  int get hashCode =>
      Object.hash(display, headline, title, body, label, secondary, caption);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final (name, style) in [
      ('display', display),
      ('headline', headline),
      ('title', title),
      ('body', body),
      ('label', label),
      ('secondary', secondary),
      ('caption', caption),
    ]) {
      properties.add(DiagnosticsProperty<TextStyle>(name, style));
    }
  }
}

/// Everything Gloss's parts read: [colors], [textTheme], [density], and one
/// part theme ([GlossStyle]) per part, each applied under a part's own
/// `style:`.
@immutable
class GlossThemeData with Diagnosticable {
  /// A theme of [colors] (and [textTheme], set from them when null) at
  /// [density] (the platform's when null: compact on a desktop).
  GlossThemeData({
    required this.colors,
    GlossTextTheme? textTheme,
    GlossDensity? density,
    this.buttonStyle,
    this.filledButtonStyle,
    this.textButtonStyle,
    this.iconButtonStyle,
    this.textFieldStyle,
    this.selectStyle,
    this.checkboxStyle,
    this.radioStyle,
    this.switchStyle,
    this.segmentedButtonStyle,
    this.sliderStyle,
    this.stepperStyle,
    this.chipStyle,
    this.listTileStyle,
    this.cardStyle,
    this.tabBarStyle,
    this.navigationStyle,
    this.dialogStyle,
    this.toastStyle,
    this.buttonGroupStyle,
    this.toggleGroupStyle,
    this.splitButtonStyle,
    this.linkStyle,
    this.kbdStyle,
    this.searchFieldStyle,
    this.otpFieldStyle,
    this.comboboxStyle,
    this.tagInputStyle,
    this.menuStyle,
    this.popoverStyle,
    this.tooltipStyle,
    this.breadcrumbStyle,
    this.paginationStyle,
    this.stepProgressStyle,
    this.pageDotsStyle,
    this.menuBarStyle,
    this.commandPaletteStyle,
    this.disclosureStyle,
    this.tableStyle,
    this.avatarStyle,
    this.badgeStyle,
    this.tagStyle,
    this.meterStyle,
    this.bannerStyle,
    this.progressStyle,
    this.chartStyle,
    this.calendarStyle,
    this.dataTableStyle,
    this.scrollAreaStyle,
    this.splitViewStyle,
    this.treeStyle,
  }) : textTheme = textTheme ?? GlossTextTheme.from(colors),
       density = density ?? GlossDensity.adaptivePlatformDensity;

  /// The jade preset by day.
  factory GlossThemeData.light({GlossDensity? density}) =>
      GlossThemeData(colors: const GlossColors.light(), density: density);

  /// The jade preset by night.
  factory GlossThemeData.dark({GlossDensity? density}) =>
      GlossThemeData(colors: const GlossColors.dark(), density: density);

  /// The jade preset, the look's own, by [brightness].
  factory GlossThemeData.jade(Brightness brightness, {GlossDensity? density}) =>
      brightness == Brightness.dark
      ? GlossThemeData.dark(density: density)
      : GlossThemeData.light(density: density);

  /// A brand's Gloss: the gel moulded in [gel] (its middle, where words sit,
  /// darkened until white words on it reach 4.5:1), and the porcelain and
  /// pearl tinted toward [finish] when given. Corners, the light and the
  /// depths stay the look's.
  ///
  /// ```dart
  /// final plum = GlossThemeData.from(gel: const Color(0xFF7A3E8E));
  /// ```
  factory GlossThemeData.from({
    required Color gel,
    Color? finish,
    Brightness brightness = Brightness.light,
    GlossDensity? density,
  }) {
    final base = brightness == Brightness.dark
        ? const GlossColors.dark()
        : const GlossColors.light();
    final hsl = HSLColor.fromColor(gel);
    var middle = hsl;
    while (_contrast(middle.toColor(), const Color(0xFFFFFFFF)) < 4.6 &&
        middle.lightness > 0.05) {
      middle = middle.withLightness(middle.lightness - 0.02);
    }
    Color shade(double by) =>
        middle.withLightness((middle.lightness + by).clamp(0.0, 1.0)).toColor();
    final ground = base.well;
    var ink = brightness == Brightness.dark
        ? hsl.withLightness(math.max(hsl.lightness, 0.62))
        : middle;
    while (_contrast(ink.toColor(), ground) < 4.6 &&
        ink.lightness > 0.04 &&
        ink.lightness < 0.96) {
      ink = ink.withLightness(
        ink.lightness + (brightness == Brightness.dark ? 0.02 : -0.02),
      );
    }
    Color tint(Color c) => finish == null
        ? c
        : Color.lerp(c, finish, 0.08)!.withValues(alpha: c.a);
    // Keep the brand tint distinct from its page in either brightness.
    var focus = brightness == Brightness.dark
        ? hsl.withLightness(0.62)
        : middle.withLightness(math.min(0.4, middle.lightness + 0.06));
    while (_contrast(focus.toColor(), tint(base.page)) < 4 &&
        focus.lightness > 0.04 &&
        focus.lightness < 0.96) {
      focus = focus.withLightness(
        focus.lightness + (brightness == Brightness.dark ? 0.02 : -0.02),
      );
    }
    return GlossThemeData(
      colors: base.copyWith(
        jadeTop: shade(0.09),
        jade: middle.toColor(),
        jadeBottom: shade(-0.07),
        jadeEdge: shade(-0.13),
        jadeGlow: hsl
            .withLightness(0.72)
            .withSaturation(math.min(1, hsl.saturation + 0.1))
            .toColor()
            .withValues(alpha: 0.5),
        jadeInk: ink.toColor(),
        focus: focus.toColor(),
        page: tint(base.page),
        barTop: tint(base.barTop),
        barMiddle: tint(base.barMiddle),
        barBottom: tint(base.barBottom),
        pearlTop: tint(base.pearlTop),
        pearlBottom: tint(base.pearlBottom),
      ),
      density: density,
    );
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// The presets a gallery offers, by id; each is designed by day and night.
  static const List<String> presets = ['jade'];

  /// The preset [id] by [brightness].
  factory GlossThemeData.preset(
    String id,
    Brightness brightness, {
    GlossDensity? density,
  }) {
    assert(presets.contains(id), 'Gloss has no preset "$id": $presets');
    return GlossThemeData.jade(brightness, density: density);
  }

  /// The glazes and inks.
  final GlossColors colors;

  /// The type.
  final GlossTextTheme textTheme;

  /// How tight the controls stand.
  final GlossDensity density;

  /// The pearl key's part theme ([GlossButton]).
  final GlossStyle? buttonStyle;

  /// The gel key's part theme ([GlossButton.filled]).
  final GlossStyle? filledButtonStyle;

  /// The letterpressed words' part theme ([GlossButton.text]).
  final GlossStyle? textButtonStyle;

  /// The bead's part theme (`GlossIconButton`).
  final GlossStyle? iconButtonStyle;

  /// The field's part theme (`GlossTextField`).
  final GlossStyle? textFieldStyle;

  /// The select's part theme (`GlossSelect`).
  final GlossStyle? selectStyle;

  /// The checkbox's part theme (`GlossCheckbox`).
  final GlossStyle? checkboxStyle;

  /// The radio's part theme (`GlossRadio`).
  final GlossStyle? radioStyle;

  /// The switch's part theme (`GlossSwitch`).
  final GlossStyle? switchStyle;

  /// The segmented control's part theme (`GlossSegmentedButton`).
  final GlossStyle? segmentedButtonStyle;

  /// The slider's part theme (`GlossSlider`).
  final GlossStyle? sliderStyle;

  /// The stepper's part theme (`GlossStepper`).
  final GlossStyle? stepperStyle;

  /// The chip's part theme (`GlossChip`).
  final GlossStyle? chipStyle;

  /// The list row's part theme (`GlossListTile`).
  final GlossStyle? listTileStyle;

  /// The card's part theme (`GlossCard`).
  final GlossStyle? cardStyle;

  /// The tab bar's part theme (`GlossTabBar`).
  final GlossStyle? tabBarStyle;

  /// The navigation's part theme (bar, rail and sidebar).
  final GlossStyle? navigationStyle;

  /// The dialog's and the sheet's part theme.
  final GlossStyle? dialogStyle;

  /// The toast's part theme.
  final GlossStyle? toastStyle;

  /// The button group's part theme (its keys).
  final GlossStyle? buttonGroupStyle;

  /// The toggle group's part theme (its toggles).
  final GlossStyle? toggleGroupStyle;

  /// The split key's part theme (both halves).
  final GlossStyle? splitButtonStyle;

  /// The link's part theme.
  final GlossStyle? linkStyle;

  /// The keycap's part theme.
  final GlossStyle? kbdStyle;

  /// The search field's part theme.
  final GlossStyle? searchFieldStyle;

  /// The one-time code's part theme (each socket).
  final GlossStyle? otpFieldStyle;

  /// The combobox field's part theme.
  final GlossStyle? comboboxStyle;

  /// The tag input's part theme (its well).
  final GlossStyle? tagInputStyle;

  /// The menu rows' part theme (menus, the menubar, the split key's list).
  final GlossStyle? menuStyle;

  /// The popover's and hover card's part theme (the panel).
  final GlossStyle? popoverStyle;

  /// The tooltip's part theme (the capsule).
  final GlossStyle? tooltipStyle;

  /// The breadcrumb's part theme (its links).
  final GlossStyle? breadcrumbStyle;

  /// The pagination's part theme (its keys).
  final GlossStyle? paginationStyle;

  /// The step progress's part theme (fill: the gel).
  final GlossStyle? stepProgressStyle;

  /// The page dots' part theme (fill: the gel).
  final GlossStyle? pageDotsStyle;

  /// The menubar's part theme (the strip and its top items).
  final GlossStyle? menuBarStyle;

  /// The command palette's part theme (its panel).
  final GlossStyle? commandPaletteStyle;

  /// The disclosure's part theme (its title row).
  final GlossStyle? disclosureStyle;

  /// The table's part theme (fill: the card).
  final GlossStyle? tableStyle;

  /// The avatar's part theme (fill: the bead).
  final GlossStyle? avatarStyle;

  /// The badge's part theme (fill: the gel).
  final GlossStyle? badgeStyle;

  /// The tag's part theme (fill: the glaze).
  final GlossStyle? tagStyle;

  /// The meter's part theme (fill: the gel).
  final GlossStyle? meterStyle;

  /// The banner's part theme (fill: the plate).
  final GlossStyle? bannerStyle;

  /// The progress bar's part theme (fill: the gel).
  final GlossStyle? progressStyle;

  /// The charts' part theme (fill: the tray).
  final GlossStyle? chartStyle;

  /// The calendar's part theme (its days; fill: the chosen bead).
  final GlossStyle? calendarStyle;

  /// The data table: fill glazes the card and a chosen row; foreground its words.
  final GlossStyle? dataTableStyle;

  /// The scroll area: fill glazes the thumb bead.
  final GlossStyle? scrollAreaStyle;

  /// The split view: fill glazes the grip.
  final GlossStyle? splitViewStyle;

  /// The tree: fill glazes a chosen row; foreground its words.
  final GlossStyle? treeStyle;

  /// Light or dark.
  Brightness get brightness => colors.brightness;

  /// A control's height at this [density].
  double get controlHeight => density.height(GlossMetrics.controlHeight);

  /// A list row's least height at this [density].
  double get rowHeight => density.height(GlossMetrics.rowHeight);

  /// A copy with the given fields replaced. New [colors] reset the text
  /// theme's inks unless a [textTheme] is given too.
  GlossThemeData copyWith({
    GlossColors? colors,
    GlossTextTheme? textTheme,
    GlossDensity? density,
    GlossStyle? buttonStyle,
    GlossStyle? filledButtonStyle,
    GlossStyle? textButtonStyle,
    GlossStyle? iconButtonStyle,
    GlossStyle? textFieldStyle,
    GlossStyle? selectStyle,
    GlossStyle? checkboxStyle,
    GlossStyle? radioStyle,
    GlossStyle? switchStyle,
    GlossStyle? segmentedButtonStyle,
    GlossStyle? sliderStyle,
    GlossStyle? stepperStyle,
    GlossStyle? chipStyle,
    GlossStyle? listTileStyle,
    GlossStyle? cardStyle,
    GlossStyle? tabBarStyle,
    GlossStyle? navigationStyle,
    GlossStyle? dialogStyle,
    GlossStyle? toastStyle,
    GlossStyle? buttonGroupStyle,
    GlossStyle? toggleGroupStyle,
    GlossStyle? splitButtonStyle,
    GlossStyle? linkStyle,
    GlossStyle? kbdStyle,
    GlossStyle? searchFieldStyle,
    GlossStyle? otpFieldStyle,
    GlossStyle? comboboxStyle,
    GlossStyle? tagInputStyle,
    GlossStyle? menuStyle,
    GlossStyle? popoverStyle,
    GlossStyle? tooltipStyle,
    GlossStyle? breadcrumbStyle,
    GlossStyle? paginationStyle,
    GlossStyle? stepProgressStyle,
    GlossStyle? pageDotsStyle,
    GlossStyle? menuBarStyle,
    GlossStyle? commandPaletteStyle,
    GlossStyle? disclosureStyle,
    GlossStyle? tableStyle,
    GlossStyle? avatarStyle,
    GlossStyle? badgeStyle,
    GlossStyle? tagStyle,
    GlossStyle? meterStyle,
    GlossStyle? bannerStyle,
    GlossStyle? progressStyle,
    GlossStyle? chartStyle,
    GlossStyle? calendarStyle,
    GlossStyle? dataTableStyle,
    GlossStyle? scrollAreaStyle,
    GlossStyle? splitViewStyle,
    GlossStyle? treeStyle,
  }) => GlossThemeData(
    colors: colors ?? this.colors,
    textTheme:
        textTheme ??
        (colors == null ? this.textTheme : GlossTextTheme.from(colors)),
    density: density ?? this.density,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    filledButtonStyle: filledButtonStyle ?? this.filledButtonStyle,
    textButtonStyle: textButtonStyle ?? this.textButtonStyle,
    iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
    textFieldStyle: textFieldStyle ?? this.textFieldStyle,
    selectStyle: selectStyle ?? this.selectStyle,
    checkboxStyle: checkboxStyle ?? this.checkboxStyle,
    radioStyle: radioStyle ?? this.radioStyle,
    switchStyle: switchStyle ?? this.switchStyle,
    segmentedButtonStyle: segmentedButtonStyle ?? this.segmentedButtonStyle,
    sliderStyle: sliderStyle ?? this.sliderStyle,
    stepperStyle: stepperStyle ?? this.stepperStyle,
    chipStyle: chipStyle ?? this.chipStyle,
    listTileStyle: listTileStyle ?? this.listTileStyle,
    cardStyle: cardStyle ?? this.cardStyle,
    tabBarStyle: tabBarStyle ?? this.tabBarStyle,
    navigationStyle: navigationStyle ?? this.navigationStyle,
    dialogStyle: dialogStyle ?? this.dialogStyle,
    toastStyle: toastStyle ?? this.toastStyle,
    buttonGroupStyle: buttonGroupStyle ?? this.buttonGroupStyle,
    toggleGroupStyle: toggleGroupStyle ?? this.toggleGroupStyle,
    splitButtonStyle: splitButtonStyle ?? this.splitButtonStyle,
    linkStyle: linkStyle ?? this.linkStyle,
    kbdStyle: kbdStyle ?? this.kbdStyle,
    searchFieldStyle: searchFieldStyle ?? this.searchFieldStyle,
    otpFieldStyle: otpFieldStyle ?? this.otpFieldStyle,
    comboboxStyle: comboboxStyle ?? this.comboboxStyle,
    tagInputStyle: tagInputStyle ?? this.tagInputStyle,
    menuStyle: menuStyle ?? this.menuStyle,
    popoverStyle: popoverStyle ?? this.popoverStyle,
    tooltipStyle: tooltipStyle ?? this.tooltipStyle,
    breadcrumbStyle: breadcrumbStyle ?? this.breadcrumbStyle,
    paginationStyle: paginationStyle ?? this.paginationStyle,
    stepProgressStyle: stepProgressStyle ?? this.stepProgressStyle,
    pageDotsStyle: pageDotsStyle ?? this.pageDotsStyle,
    menuBarStyle: menuBarStyle ?? this.menuBarStyle,
    commandPaletteStyle: commandPaletteStyle ?? this.commandPaletteStyle,
    disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    tableStyle: tableStyle ?? this.tableStyle,
    avatarStyle: avatarStyle ?? this.avatarStyle,
    badgeStyle: badgeStyle ?? this.badgeStyle,
    tagStyle: tagStyle ?? this.tagStyle,
    meterStyle: meterStyle ?? this.meterStyle,
    bannerStyle: bannerStyle ?? this.bannerStyle,
    progressStyle: progressStyle ?? this.progressStyle,
    chartStyle: chartStyle ?? this.chartStyle,
    calendarStyle: calendarStyle ?? this.calendarStyle,
    dataTableStyle: dataTableStyle ?? this.dataTableStyle,
    scrollAreaStyle: scrollAreaStyle ?? this.scrollAreaStyle,
    splitViewStyle: splitViewStyle ?? this.splitViewStyle,
    treeStyle: treeStyle ?? this.treeStyle,
  );

  List<GlossStyle?> get _styles => [
    buttonStyle,
    filledButtonStyle,
    textButtonStyle,
    iconButtonStyle,
    textFieldStyle,
    selectStyle,
    checkboxStyle,
    radioStyle,
    switchStyle,
    segmentedButtonStyle,
    sliderStyle,
    stepperStyle,
    chipStyle,
    listTileStyle,
    cardStyle,
    tabBarStyle,
    navigationStyle,
    dialogStyle,
    toastStyle,
    buttonGroupStyle,
    toggleGroupStyle,
    splitButtonStyle,
    linkStyle,
    kbdStyle,
    searchFieldStyle,
    otpFieldStyle,
    comboboxStyle,
    tagInputStyle,
    menuStyle,
    popoverStyle,
    tooltipStyle,
    breadcrumbStyle,
    paginationStyle,
    stepProgressStyle,
    pageDotsStyle,
    menuBarStyle,
    commandPaletteStyle,
    disclosureStyle,
    tableStyle,
    avatarStyle,
    badgeStyle,
    tagStyle,
    meterStyle,
    bannerStyle,
    progressStyle,
    chartStyle,
    calendarStyle,
    dataTableStyle,
    scrollAreaStyle,
    splitViewStyle,
    treeStyle,
  ];

  static const List<String> _styleNames = [
    'buttonStyle',
    'filledButtonStyle',
    'textButtonStyle',
    'iconButtonStyle',
    'textFieldStyle',
    'selectStyle',
    'checkboxStyle',
    'radioStyle',
    'switchStyle',
    'segmentedButtonStyle',
    'sliderStyle',
    'stepperStyle',
    'chipStyle',
    'listTileStyle',
    'cardStyle',
    'tabBarStyle',
    'navigationStyle',
    'dialogStyle',
    'toastStyle',
    'buttonGroupStyle',
    'toggleGroupStyle',
    'splitButtonStyle',
    'linkStyle',
    'kbdStyle',
    'searchFieldStyle',
    'otpFieldStyle',
    'comboboxStyle',
    'tagInputStyle',
    'menuStyle',
    'popoverStyle',
    'tooltipStyle',
    'breadcrumbStyle',
    'paginationStyle',
    'stepProgressStyle',
    'pageDotsStyle',
    'menuBarStyle',
    'commandPaletteStyle',
    'disclosureStyle',
    'tableStyle',
    'avatarStyle',
    'badgeStyle',
    'tagStyle',
    'meterStyle',
    'bannerStyle',
    'progressStyle',
    'chartStyle',
    'calendarStyle',
    'dataTableStyle',
    'scrollAreaStyle',
    'splitViewStyle',
    'treeStyle',
  ];

  /// Between [a] and [b] at [t]. Part themes switch half way.
  static GlossThemeData lerp(GlossThemeData a, GlossThemeData b, double t) {
    if (identical(a, b)) return a;
    final s = t < 0.5 ? a : b;
    return GlossThemeData(
      colors: GlossColors.lerp(a.colors, b.colors, t),
      textTheme: GlossTextTheme.lerp(a.textTheme, b.textTheme, t),
      density: GlossDensity.lerp(a.density, b.density, t),
      buttonStyle: s.buttonStyle,
      filledButtonStyle: s.filledButtonStyle,
      textButtonStyle: s.textButtonStyle,
      iconButtonStyle: s.iconButtonStyle,
      textFieldStyle: s.textFieldStyle,
      selectStyle: s.selectStyle,
      checkboxStyle: s.checkboxStyle,
      radioStyle: s.radioStyle,
      switchStyle: s.switchStyle,
      segmentedButtonStyle: s.segmentedButtonStyle,
      sliderStyle: s.sliderStyle,
      stepperStyle: s.stepperStyle,
      chipStyle: s.chipStyle,
      listTileStyle: s.listTileStyle,
      cardStyle: s.cardStyle,
      tabBarStyle: s.tabBarStyle,
      navigationStyle: s.navigationStyle,
      dialogStyle: s.dialogStyle,
      toastStyle: s.toastStyle,
      buttonGroupStyle: s.buttonGroupStyle,
      toggleGroupStyle: s.toggleGroupStyle,
      splitButtonStyle: s.splitButtonStyle,
      linkStyle: s.linkStyle,
      kbdStyle: s.kbdStyle,
      searchFieldStyle: s.searchFieldStyle,
      otpFieldStyle: s.otpFieldStyle,
      comboboxStyle: s.comboboxStyle,
      tagInputStyle: s.tagInputStyle,
      menuStyle: s.menuStyle,
      popoverStyle: s.popoverStyle,
      tooltipStyle: s.tooltipStyle,
      breadcrumbStyle: s.breadcrumbStyle,
      paginationStyle: s.paginationStyle,
      stepProgressStyle: s.stepProgressStyle,
      pageDotsStyle: s.pageDotsStyle,
      menuBarStyle: s.menuBarStyle,
      commandPaletteStyle: s.commandPaletteStyle,
      disclosureStyle: s.disclosureStyle,
      tableStyle: s.tableStyle,
      avatarStyle: s.avatarStyle,
      badgeStyle: s.badgeStyle,
      tagStyle: s.tagStyle,
      meterStyle: s.meterStyle,
      bannerStyle: s.bannerStyle,
      progressStyle: s.progressStyle,
      chartStyle: s.chartStyle,
      calendarStyle: s.calendarStyle,
      dataTableStyle: s.dataTableStyle,
      scrollAreaStyle: s.scrollAreaStyle,
      splitViewStyle: s.splitViewStyle,
      treeStyle: s.treeStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlossThemeData &&
      other.colors == colors &&
      other.textTheme == textTheme &&
      other.density == density &&
      listEquals(other._styles, _styles);

  @override
  int get hashCode =>
      Object.hash(colors, textTheme, density, Object.hashAll(_styles));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<GlossColors>('colors', colors))
      ..add(DiagnosticsProperty<GlossTextTheme>('textTheme', textTheme))
      ..add(DiagnosticsProperty<GlossDensity>('density', density))
      ..add(DoubleProperty('controlHeight', controlHeight));
    final styles = _styles;
    for (var i = 0; i < styles.length; i++) {
      properties.add(
        DiagnosticsProperty<GlossStyle>(
          _styleNames[i],
          styles[i],
          defaultValue: null,
        ),
      );
    }
  }
}

/// Gloss, installed: its theme, its tap floors, its spacing grid and its
/// words for everything below. Put it once in an app's `builder:`, above the
/// navigator, with a `GlossToaster` inside it.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: glossPageTransitions)), builder: (context, child) => GlossTheme(data: GlossThemeData.jade(Brightness.light), child: GlossToaster(child: child!)), home: const Placeholder())
/// ```
class GlossTheme extends StatelessWidget {
  /// [data] for [child] and everything below it.
  const GlossTheme({super.key, required this.data, required this.child});

  /// The theme.
  final GlossThemeData data;

  /// What the theme is for.
  final Widget child;

  /// Gloss's tap floors: 44 by 44 for a finger, 24 by 24 for a pointer, as
  /// ui_core's defaults.
  static const DesignTapTargets tapTargets = DesignTapTargets.fallback;

  static final GlossThemeData _fallback = GlossThemeData.light();

  /// The theme above [context], or the jade preset by day when there is none.
  static GlossThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallback;

  /// The theme above [context], or null.
  static GlossThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedGlossTheme>()
      ?.theme
      .data;

  @override
  Widget build(BuildContext context) {
    final colors = data.colors;
    // The Material parts Gloss draws with inside (an editable's selection,
    // its handles) take the look's colours and stand at the look's own
    // density, never the platform's; a push plays Gloss's own motion.
    final base = _bridges[data] ??= _materialUnder(data);
    // An app's own choice of page transitions stays; Flutter's default
    // becomes Gloss's.
    final host = Theme.of(context).pageTransitionsTheme;
    final material = host == const PageTransitionsTheme()
        ? base
        : base.copyWith(pageTransitionsTheme: host);
    Widget under = _InheritedGlossTheme(
      theme: this,
      child: Theme(
        data: material,
        child: DesignSpacingScope(
          // Gloss keeps ui_core's 4 px grid.
          spacing: DesignSpacing.fallback,
          child: DesignTapTargetScope(
            targets: tapTargets,
            child: DefaultSelectionStyle(
              cursorColor: colors.jadeInk,
              selectionColor: colors.jadeTop.withValues(alpha: 0.32),
              child: IconTheme(
                data: IconThemeData(color: colors.ink, size: 20),
                child: DefaultTextStyle(
                  style: data.textTheme.body,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Gloss's text field asks for the words of the Material library it is
    // built on, and its menu on iOS for Cupertino's. An app with neither gets
    // Gloss's own (English), never a throw; an app that has them keeps its
    // own. A Localizations sets the direction from its locale, so the app's
    // own direction is kept.
    final missing = Localizations.maybeLocaleOf(context) == null
        ? const <LocalizationsDelegate<Object?>>[]
        : <LocalizationsDelegate<Object?>>[
            if (Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                ) ==
                null)
              glossMaterialWords,
            if (Localizations.of<CupertinoLocalizations>(
                  context,
                  CupertinoLocalizations,
                ) ==
                null)
              glossCupertinoWords,
          ];
    if (missing.isNotEmpty) {
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: missing,
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    return under;
  }

  static final Expando<ThemeData> _bridges = Expando('GlossTheme bridges');

  static ThemeData _materialUnder(GlossThemeData data) {
    final colors = data.colors;
    return ThemeData(
      brightness: colors.brightness,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      splashColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      focusColor: const Color(0x00000000),
      scaffoldBackgroundColor: colors.page,
      canvasColor: colors.page,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: glossPageTransitions,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.jade,
        brightness: colors.brightness,
        primary: colors.jadeInk,
        onPrimary: colors.onJade,
        surface: colors.page,
        onSurface: colors.ink,
        error: colors.danger,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.jadeInk,
        selectionColor: colors.jadeTop.withValues(alpha: 0.32),
        selectionHandleColor: colors.jadeInk,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GlossThemeData>('data', data));
  }
}

class _InheritedGlossTheme extends InheritedTheme {
  const _InheritedGlossTheme({required this.theme, required super.child});

  final GlossTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      GlossTheme(data: theme.data, child: child);

  @override
  bool updateShouldNotify(_InheritedGlossTheme old) =>
      theme.data != old.theme.data;
}

/// [GlossTheme] that moves to each new [data] over [duration], as
/// `AnimatedTheme` does: day to night, one gel to another. Under Reduce
/// Motion it changes at once.
class AnimatedGlossTheme extends ImplicitlyAnimatedWidget {
  /// [child] under a theme that moves to [data].
  const AnimatedGlossTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve = Curves.easeOut,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final GlossThemeData data;

  /// What the theme is for.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedGlossTheme> createState() =>
      _AnimatedGlossThemeState();
}

class _AnimatedGlossThemeState
    extends AnimatedWidgetBaseState<AnimatedGlossTheme> {
  _GlossThemeTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => _GlossThemeTween(begin: value as GlossThemeData),
    ) as _GlossThemeTween?;
  }

  @override
  Widget build(BuildContext context) => GlossTheme(
    data: MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? widget.data
        : _data!.evaluate(animation),
    child: widget.child,
  );
}

class _GlossThemeTween extends Tween<GlossThemeData> {
  _GlossThemeTween({super.begin});

  @override
  GlossThemeData lerp(double t) => GlossThemeData.lerp(begin!, end!, t);
}

/// `context.glossTheme`: the [GlossThemeData] above.
extension GlossThemeContext on BuildContext {
  /// The [GlossThemeData] above this context ([GlossTheme.of]).
  GlossThemeData get glossTheme => GlossTheme.of(this);
}

/// Gloss's page change on every platform, for an app's own `ThemeData`:
/// `PageTransitionsTheme(builders: glossPageTransitions)`. On iOS the swipe
/// from the screen's edge still pops a page, round Gloss's own push.
const Map<TargetPlatform, PageTransitionsBuilder> glossPageTransitions = {
  TargetPlatform.android: GlossPageTransitionsBuilder(),
  TargetPlatform.fuchsia: GlossPageTransitionsBuilder(),
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    GlossPageTransitionsBuilder(),
  ),
  TargetPlatform.linux: GlossPageTransitionsBuilder(),
  TargetPlatform.macOS: GlossPageTransitionsBuilder(),
  TargetPlatform.windows: GlossPageTransitionsBuilder(),
};
