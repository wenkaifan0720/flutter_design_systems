/// Clay's theme: its clay colours and inks, its type, its spacing, its
/// corners and depths, its motion, its density, the part themes, and the
/// [ClayTheme] every app installs once in its `builder:`.
library;

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/platform_words.dart';
import 'page_transitions.dart';

/// How one part of Clay looks, as Material's `ButtonStyle` is: every slot a
/// `WidgetStateProperty`, read from a part's `style:` first, then from its
/// part theme on [ClayThemeData], then from the look's own default.
///
/// A part reads `fill` as its clay's colour (its light, shade and shadow are
/// drawn from it), `foreground` as its words and glyphs, `shape` as its
/// outline, and `padding`, `minimumSize`, `textStyle` and `iconSize` as
/// Material's buttons do. Clay has no strokes, so `side` and `edge` are not
/// read.
///
/// ```dart
/// const ClayStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)))
/// ```
typedef ClayStyle = DesignStyle;

/// How tight Clay's controls stand: [DesignDensity.standard] (a 48 px
/// control), [DesignDensity.comfortable] (44) or [DesignDensity.compact] (40).
/// The default adapts: compact on a desktop, standard on touch. A control's
/// tap target stays at the floor for the input whatever the density.
typedef ClayDensity = DesignDensity;

/// Clay's constants: its heights and breakpoints. They are not settings.
abstract final class ClayMetrics {
  /// A control's height at [DesignDensity.standard], before density.
  static const double controlHeight = 48;

  /// Where a field's words start inside it, from its edge; its label, help,
  /// error and count stand on the same line, above and under it.
  static const double fieldInset = ClaySpacing.regular;

  /// A list row's least height, before density.
  static const double rowHeight = 56;

  /// The widest a column of reading or of a form stands.
  static const double readingWidth = 640;

  /// From this width the bottom bar gives way to the rail.
  static const double railBreakpoint = 600;

  /// From this width the rail gives way to the sidebar.
  static const double sidebarBreakpoint = 1024;

  /// The rail's width.
  static const double railWidth = 96;

  /// The sidebar's width.
  static const double sidebarWidth = 264;
}

/// Clay's corners: generous and continuous (a rounded superellipse, so a
/// corner flows into its side with no visible join). Each part takes the
/// step that fits its size; round things (a radio, a switch's ball, a chip)
/// are stadiums and circles.
abstract final class ClayRadius {
  /// A small part: a checkbox, a tag.
  static const double small = 9;

  /// A control: a button, a field, a select.
  static const double control = 16;

  /// A group of rows, a card, a menu.
  static const double large = 24;

  /// A dialog, a sheet, a floating dock.
  static const double extraLarge = 32;

  /// [radius] for a part [height] high, never more than half of it.
  static double fit(double radius, double height) =>
      math.min(radius, height / 2);
}

/// Clay's spacing, on a 4 px grid.
abstract final class ClaySpacing {
  /// The grid every space stands on.
  static const double grid = 4;

  /// 2: half a step of the grid, for an optical nudge (a line's words set
  /// under a figure, a hairline's room), never for a gap between parts.
  static const double hairline = 2;

  /// 4.
  static const double tight = 4;

  /// 8.
  static const double small = 8;

  /// 12.
  static const double medium = 12;

  /// 16.
  static const double regular = 16;

  /// 20.
  static const double roomy = 20;

  /// 24.
  static const double large = 24;

  /// 32.
  static const double extraLarge = 32;

  /// 48.
  static const double huge = 48;

  /// The page's margin at [width]: 16 on a phone, 24 on a tablet, 32 on a
  /// desk.
  static double pageMargin(double width) => width >= 1024
      ? extraLarge
      : width >= 600
      ? large
      : regular;
}

/// Clay's motion tokens: springs, each a damping ratio and a stiffness, run
/// through ui_core's `DesignMotionPolicy` (so Reduce Motion critically damps
/// them). Calm: nothing bounces; a press is short.
abstract final class ClayMotion {
  /// A press squashing in and coming back.
  static const double pressDamping = 1;

  /// A press squashing in and coming back.
  static const double pressStiffness = 1100;

  /// A part rising on hover or focus.
  static const double liftDamping = 1;

  /// A part rising on hover or focus.
  static const double liftStiffness = 700;

  /// A thumb or a selection sliding to its place.
  static const double slideDamping = 0.92;

  /// A thumb or a selection sliding to its place.
  static const double slideStiffness = 560;

  /// A colour changing (a check filling, a well lighting).
  static const double colorStiffness = 900;

  /// A dialog, sheet or menu inflating into place.
  static const double panelDamping = 0.95;

  /// A dialog, sheet or menu inflating into place.
  static const double panelStiffness = 480;
}

/// A pastel a part can be moulded in (a habit's colour, a card's), each
/// designed by day and by night.
enum ClayTint {
  /// Warm apricot.
  peach,

  /// Soft yellow.
  butter,

  /// Fresh green.
  mint,

  /// Clear blue.
  sky,

  /// Pale violet.
  lilac,

  /// Dusty pink.
  rose,
}

/// Clay's colours: the pale ground, the neutral clay most parts are made of,
/// the wells pressed into the ground, the inks, the one accent and its
/// danger twin, and six pastels. Every word colour meets 4.5:1 on what it
/// sits on, by day and by night.
@immutable
class ClayColors with Diagnosticable {
  /// Colours given one by one.
  const ClayColors({
    required this.brightness,
    required this.ground,
    required this.groundShade,
    required this.clay,
    required this.clayShade,
    required this.well,
    required this.ink,
    required this.inkSecondary,
    required this.inkDisabled,
    required this.accent,
    required this.onAccent,
    required this.accentInk,
    required this.danger,
    required this.onDanger,
    required this.dangerInk,
    required this.success,
    required this.focus,
    required this.inverse,
    required this.onInverse,
    required this.scrim,
    required this.light,
    required this.tints,
  });

  /// Clay by day: white clay on a pale lilac ground, a coral accent.
  const ClayColors.light()
    : brightness = Brightness.light,
      ground = const Color(0xFFECEAF6),
      groundShade = const Color(0xFF6B5FA8),
      clay = const Color(0xFFFBFAFF),
      clayShade = const Color(0xFF7A6EB8),
      well = const Color(0xFFE1DEF0),
      ink = const Color(0xFF2A2440),
      inkSecondary = const Color(0xFF5E5878),
      inkDisabled = const Color(0xFF9D99B2),
      accent = const Color(0xFFFF7A5C),
      onAccent = const Color(0xFF2B1630),
      accentInk = const Color(0xFFB53A1C),
      danger = const Color(0xFFF2617A),
      onDanger = const Color(0xFF2B0E16),
      dangerInk = const Color(0xFFB4213C),
      success = const Color(0xFF2E7D5B),
      focus = const Color(0xFFB53A1C),
      inverse = const Color(0xFF2E2848),
      onInverse = const Color(0xFFF6F4FF),
      scrim = const Color(0x592A2440),
      light = const Color(0xFFFFFFFF),
      tints = const {
        ClayTint.peach: Color(0xFFFFD9C6),
        ClayTint.butter: Color(0xFFFFE9A6),
        ClayTint.mint: Color(0xFFC8EFD9),
        ClayTint.sky: Color(0xFFCFE3FF),
        ClayTint.lilac: Color(0xFFE2D8FF),
        ClayTint.rose: Color(0xFFFFD4E1),
      };

  /// Clay by night: the same clay in low light, deep and saturated, darker
  /// shades and no glow.
  const ClayColors.dark()
    : brightness = Brightness.dark,
      ground = const Color(0xFF17142A),
      groundShade = const Color(0xFF05030D),
      clay = const Color(0xFF29243F),
      clayShade = const Color(0xFF0B0818),
      well = const Color(0xFF100E1F),
      ink = const Color(0xFFF3F0FF),
      inkSecondary = const Color(0xFFB9B3D6),
      inkDisabled = const Color(0xFF6E6889),
      accent = const Color(0xFFF2785A),
      onAccent = const Color(0xFF240F14),
      accentInk = const Color(0xFFFF9C82),
      danger = const Color(0xFFE85C76),
      onDanger = const Color(0xFF22080F),
      dangerInk = const Color(0xFFFF8FA3),
      success = const Color(0xFF7FD8AE),
      focus = const Color(0xFFFF9C82),
      inverse = const Color(0xFFEDEAFB),
      onInverse = const Color(0xFF221D36),
      scrim = const Color(0x99050310),
      light = const Color(0xFFFFFFFF),
      tints = const {
        ClayTint.peach: Color(0xFF8E4A33),
        ClayTint.butter: Color(0xFF7A6118),
        ClayTint.mint: Color(0xFF22654F),
        ClayTint.sky: Color(0xFF2B4F86),
        ClayTint.lilac: Color(0xFF4D3E8C),
        ClayTint.rose: Color(0xFF833552),
      };

  /// Day or night.
  final Brightness brightness;

  /// The pale ground every part floats above, and the page's colour.
  final Color ground;

  /// The hue of a shadow cast on the ground by neutral clay: never grey.
  final Color groundShade;

  /// The neutral clay most parts are made of (groups, keys, menus).
  final Color clay;

  /// The neutral clay's shade: its inner shade and its drop shadow.
  final Color clayShade;

  /// A well pressed into the ground (fields, grooves, tracks).
  final Color well;

  /// Words and glyphs.
  final Color ink;

  /// Secondary words: subtitles, help, captions.
  final Color inkSecondary;

  /// Words and glyphs of a part turned off.
  final Color inkDisabled;

  /// The one confident accent: the primary key, what is on or chosen.
  final Color accent;

  /// Words and glyphs on [accent].
  final Color onAccent;

  /// The accent as words on the ground or on clay (a link, a text key).
  final Color accentInk;

  /// The clay of an action that destroys.
  final Color danger;

  /// Words and glyphs on [danger].
  final Color onDanger;

  /// Danger as words on the ground or on clay.
  final Color dangerInk;

  /// A done or healthy state's words and glyphs.
  final Color success;

  /// The rim a focused part takes, at 3:1 or more against the clay and the
  /// wells it sits in.
  final Color focus;

  /// A toast's clay: the ink's colour, for a message that floats over
  /// everything.
  final Color inverse;

  /// Words on [inverse].
  final Color onInverse;

  /// What dims the page under a dialog or a sheet.
  final Color scrim;

  /// The light a volume catches inside its top-leading edge.
  final Color light;

  /// The pastels, by [ClayTint].
  final Map<ClayTint, Color> tints;

  /// The pastel [tint].
  Color tint(ClayTint tint) => tints[tint]!;

  /// The clay a part rises in when it is chosen out of a groove or a list of
  /// places (a segment, a tab, a rail's or a sidebar's place): the clay
  /// itself by day; by night lifted toward the light, so it reads beside the
  /// clay and the ground (2:1 from night clay).
  Color get risen =>
      brightness == Brightness.dark ? Color.lerp(clay, ink, 0.20)! : clay;

  /// A ball rolled along a groove (a switch's, a slider's): white clay by
  /// day; by night a pale lilac clay, so it stands 3:1 from its groove,
  /// off or on, as the day's white ball does (dark clay on a dark groove
  /// all but vanished, and lay darker than an off track).
  Color get knob =>
      brightness == Brightness.dark ? Color.lerp(clay, ink, 0.85)! : clay;

  /// A disabled [knob]: halfway back to the clay, still seen on its groove.
  Color get knobDisabled => Color.lerp(clay, knob, 0.5)!;

  /// The groove of a control that is off (a switch's track, an unchecked
  /// box's rim, an empty cup's): a quiet grey of the ink, deep enough by day
  /// and pale enough by night to stand 3:1 from the clay around it, and
  /// without hue, so off never reads as a second colour of on.
  Color get track =>
      Color.lerp(well, ink, brightness == Brightness.dark ? 0.45 : 0.44)!;

  /// The groove of a control turned off: a ghost of [track], still there
  /// to be seen on the ground, by day and by night.
  Color get trackOff => Color.lerp(well, track, 0.3)!;

  /// Words and glyphs that read on [fill]: [ink] or the ground's opposite,
  /// whichever stands further from it.
  Color onColor(Color fill) {
    final dark = brightness == Brightness.dark ? onInverse : ink;
    final pale = brightness == Brightness.dark ? ink : onInverse;
    return _contrast(dark, fill) >= _contrast(pale, fill) ? dark : pale;
  }

  /// The shade [fill] casts and is shaded by: its own hue, deeper and richer.
  /// Neutral clay takes [clayShade]; the shade is never grey.
  Color shadeOf(Color fill) {
    if (fill == clay) return clayShade;
    if (fill == well || fill == ground) return groundShade;
    final hsl = HSLColor.fromColor(fill);
    if (hsl.saturation < 0.12) {
      return HSLColor.fromColor(clayShade)
          .withLightness(
            brightness == Brightness.dark
                ? 0.04
                : (hsl.lightness * 0.5).clamp(0.2, 0.5),
          )
          .toColor();
    }
    if (brightness == Brightness.dark) {
      return hsl
          .withLightness((hsl.lightness * 0.28).clamp(0.02, 0.12))
          .withSaturation(math.min(1, hsl.saturation + 0.1))
          .toColor();
    }
    return hsl
        .withLightness((hsl.lightness * 0.62).clamp(0.22, 0.56))
        .withSaturation(math.min(1, hsl.saturation * 0.9 + 0.18))
        .toColor();
  }

  /// A copy with the given colours changed.
  ClayColors copyWith({
    Brightness? brightness,
    Color? ground,
    Color? groundShade,
    Color? clay,
    Color? clayShade,
    Color? well,
    Color? ink,
    Color? inkSecondary,
    Color? inkDisabled,
    Color? accent,
    Color? onAccent,
    Color? accentInk,
    Color? danger,
    Color? onDanger,
    Color? dangerInk,
    Color? success,
    Color? focus,
    Color? inverse,
    Color? onInverse,
    Color? scrim,
    Color? light,
    Map<ClayTint, Color>? tints,
  }) => ClayColors(
    brightness: brightness ?? this.brightness,
    ground: ground ?? this.ground,
    groundShade: groundShade ?? this.groundShade,
    clay: clay ?? this.clay,
    clayShade: clayShade ?? this.clayShade,
    well: well ?? this.well,
    ink: ink ?? this.ink,
    inkSecondary: inkSecondary ?? this.inkSecondary,
    inkDisabled: inkDisabled ?? this.inkDisabled,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentInk: accentInk ?? this.accentInk,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerInk: dangerInk ?? this.dangerInk,
    success: success ?? this.success,
    focus: focus ?? this.focus,
    inverse: inverse ?? this.inverse,
    onInverse: onInverse ?? this.onInverse,
    scrim: scrim ?? this.scrim,
    light: light ?? this.light,
    tints: tints ?? this.tints,
  );

  List<Color> get _all => [
    ground,
    groundShade,
    clay,
    clayShade,
    well,
    ink,
    inkSecondary,
    inkDisabled,
    accent,
    onAccent,
    accentInk,
    danger,
    onDanger,
    dangerInk,
    success,
    focus,
    inverse,
    onInverse,
    scrim,
    light,
  ];

  static const List<String> _names = [
    'ground',
    'groundShade',
    'clay',
    'clayShade',
    'well',
    'ink',
    'inkSecondary',
    'inkDisabled',
    'accent',
    'onAccent',
    'accentInk',
    'danger',
    'onDanger',
    'dangerInk',
    'success',
    'focus',
    'inverse',
    'onInverse',
    'scrim',
    'light',
  ];

  /// Between [a] and [b].
  static ClayColors lerp(ClayColors a, ClayColors b, double t) {
    if (identical(a, b)) return a;
    Color l(Color x, Color y) => Color.lerp(x, y, t)!;
    return ClayColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      ground: l(a.ground, b.ground),
      groundShade: l(a.groundShade, b.groundShade),
      clay: l(a.clay, b.clay),
      clayShade: l(a.clayShade, b.clayShade),
      well: l(a.well, b.well),
      ink: l(a.ink, b.ink),
      inkSecondary: l(a.inkSecondary, b.inkSecondary),
      inkDisabled: l(a.inkDisabled, b.inkDisabled),
      accent: l(a.accent, b.accent),
      onAccent: l(a.onAccent, b.onAccent),
      accentInk: l(a.accentInk, b.accentInk),
      danger: l(a.danger, b.danger),
      onDanger: l(a.onDanger, b.onDanger),
      dangerInk: l(a.dangerInk, b.dangerInk),
      success: l(a.success, b.success),
      focus: l(a.focus, b.focus),
      inverse: l(a.inverse, b.inverse),
      onInverse: l(a.onInverse, b.onInverse),
      scrim: l(a.scrim, b.scrim),
      light: l(a.light, b.light),
      tints: {
        for (final tint in ClayTint.values)
          tint: l(a.tints[tint]!, b.tints[tint]!),
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClayColors &&
      other.brightness == brightness &&
      listEquals(other._all, _all) &&
      mapEquals(other.tints, tints);

  @override
  int get hashCode => Object.hash(
    brightness,
    Object.hashAll(_all),
    Object.hashAll(tints.values),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    for (final (i, c) in _all.indexed) {
      properties.add(ColorProperty(_names[i], c));
    }
  }
}

/// The contrast ratio between [a] and [b] (WCAG), 1 to 21.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The contrast ratio between two colours, as WCAG measures it (1 to 21).
///
/// ```dart
/// clayContrast(const Color(0xFF2A2440), const Color(0xFFFF7A5C))
/// ```
double clayContrast(Color a, Color b) => _contrast(a, b);

/// Clay's type: one face (Rubik by default) in seven styles, with even
/// leading so a one-line label centres in its box.
@immutable
class ClayTextTheme with Diagnosticable {
  /// Styles given one by one.
  const ClayTextTheme({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.secondary,
    required this.caption,
  });

  /// Clay's ramp in [family] (the bundled Rubik when null), inked [ink] and
  /// [secondaryInk].
  factory ClayTextTheme.of({
    required Color ink,
    required Color secondaryInk,
    String? family,
    String? package,
  }) {
    final face = family ?? clayFontFamily;
    final from = family == null ? clayFontPackage : package;
    TextStyle s(double size, double height, FontWeight weight, Color colour) =>
        TextStyle(
          fontFamily: face,
          package: from,
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          fontVariations: clayWeight(weight),
          color: colour,
          leadingDistribution: TextLeadingDistribution.even,
          decoration: TextDecoration.none,
        );
    return ClayTextTheme(
      display: s(32, 40, FontWeight.w700, ink),
      headline: s(24, 30, FontWeight.w600, ink),
      title: s(18, 24, FontWeight.w600, ink),
      body: s(16, 24, FontWeight.w400, ink),
      label: s(16, 20, FontWeight.w500, ink),
      secondary: s(14, 20, FontWeight.w400, secondaryInk),
      caption: s(12, 16, FontWeight.w500, secondaryInk),
    );
  }

  /// A screen's one big figure or a page's hero title: 32.
  final TextStyle display;

  /// A page title: 24.
  final TextStyle headline;

  /// A card's or a dialog's title, a row's strong words: 18.
  final TextStyle title;

  /// Reading text: 16.
  final TextStyle body;

  /// A control's words (a key, a tab, a field's value): 16.
  final TextStyle label;

  /// Supporting words: a row's subtitle, help under a field: 14.
  final TextStyle secondary;

  /// Small words a person still reads: a section's name, a count: 12.
  final TextStyle caption;

  /// A copy with the given styles changed.
  ClayTextTheme copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? secondary,
    TextStyle? caption,
  }) => ClayTextTheme(
    display: display ?? this.display,
    headline: headline ?? this.headline,
    title: title ?? this.title,
    body: body ?? this.body,
    label: label ?? this.label,
    secondary: secondary ?? this.secondary,
    caption: caption ?? this.caption,
  );

  List<TextStyle> get _all => [
    display,
    headline,
    title,
    body,
    label,
    secondary,
    caption,
  ];

  /// Between [a] and [b].
  static ClayTextTheme lerp(ClayTextTheme a, ClayTextTheme b, double t) {
    if (identical(a, b)) return a;
    TextStyle l(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return ClayTextTheme(
      display: l(a.display, b.display),
      headline: l(a.headline, b.headline),
      title: l(a.title, b.title),
      body: l(a.body, b.body),
      label: l(a.label, b.label),
      secondary: l(a.secondary, b.secondary),
      caption: l(a.caption, b.caption),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClayTextTheme && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const names = [
      'display',
      'headline',
      'title',
      'body',
      'label',
      'secondary',
      'caption',
    ];
    for (final (i, s) in _all.indexed) {
      properties.add(DiagnosticsProperty<TextStyle>(names[i], s));
    }
  }
}

/// Everything Clay's parts read: [colors], [textTheme], [density], and one
/// part theme per part, each a [ClayStyle] that every one of that part
/// reads under its own `style:`.
@immutable
class ClayThemeData with Diagnosticable {
  /// A theme of [colors] (Clay by day when null), its words in [textTheme]
  /// (Clay's ramp in Rubik when null), at [density] (the platform's when
  /// null: compact on a desktop).
  ClayThemeData({
    ClayColors? colors,
    ClayTextTheme? textTheme,
    ClayDensity? density,
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
    this.chipStyle,
    this.listTileStyle,
    this.groupStyle,
    this.cardStyle,
    this.sectionHeaderStyle,
    this.tabBarStyle,
    this.topBarStyle,
    this.navigationBarStyle,
    this.navigationRailStyle,
    this.sidebarStyle,
    this.dialogStyle,
    this.sheetStyle,
    this.menuStyle,
    this.toastStyle,
    this.progressStyle,
    this.buttonGroupStyle,
    this.toggleGroupStyle,
    this.splitButtonStyle,
    this.linkStyle,
    this.kbdStyle,
    this.searchFieldStyle,
    this.inputGroupStyle,
    this.otpFieldStyle,
    this.numberFieldStyle,
    this.comboboxStyle,
    this.tagInputStyle,
    this.sliderStyle,
    this.ratingStyle,
    this.fileDropStyle,
    this.calendarStyle,
    this.timeFieldStyle,
    this.breadcrumbStyle,
    this.paginationStyle,
    this.stepProgressStyle,
    this.pageDotsStyle,
    this.menuBarStyle,
    this.commandPaletteStyle,
    this.popoverStyle,
    this.tooltipStyle,
    this.dataTableStyle,
    this.scrollAreaStyle,
    this.splitViewStyle,
    this.treeStyle,
    this.iconTileStyle,
    this.disclosureStyle,
    this.tableStyle,
    this.timelineStyle,
    this.avatarStyle,
    this.badgeStyle,
    this.tagStyle,
    this.meterStyle,
    this.bannerStyle,
    this.stateViewStyle,
    this.lineChartStyle,
    this.areaChartStyle,
    this.barChartStyle,
    this.pieChartStyle,
    this.sparklineStyle,
    this.datePickerStyle,
    this.dateRangePickerStyle,
    this.wheelPickerStyle,
    this.timePickerStyle,
    this.colorPickerStyle,
    this.carouselStyle,
    this.reorderableListStyle,
    this.swipeRowStyle,
    this.pullToRefreshStyle,
    this.descriptionListStyle,
    this.avatarGroupStyle,
    this.mediaStyle,
    this.skeletonStyle,
    this.formFieldStyle,
    this.spinnerStyle,
    this.grooveStyle,
    this.scaffoldStyle,
    this.contextMenuStyle,
    this.fieldLabelStyle,
    this.fieldMessageStyle,
  }) : colors = colors ?? const ClayColors.light(),
       textTheme =
           textTheme ??
           ClayTextTheme.of(
             ink: (colors ?? const ClayColors.light()).ink,
             secondaryInk: (colors ?? const ClayColors.light()).inkSecondary,
           ),
       density = density ?? ClayDensity.adaptivePlatformDensity;

  /// Clay by day.
  factory ClayThemeData.light({ClayDensity? density}) =>
      ClayThemeData(colors: const ClayColors.light(), density: density);

  /// Clay by night.
  factory ClayThemeData.dark({ClayDensity? density}) =>
      ClayThemeData(colors: const ClayColors.dark(), density: density);

  /// The clay preset at [brightness].
  factory ClayThemeData.clay(Brightness brightness, {ClayDensity? density}) =>
      brightness == Brightness.dark
      ? ClayThemeData.dark(density: density)
      : ClayThemeData.light(density: density);

  /// Clay in a brand's own [accent], at [brightness], with the brand's
  /// [fontFamily] when given. The accent keeps its hue; its words are the
  /// ink or the light that reads on it at 4.5:1, its text ink is darkened (by
  /// day) or lightened (by night) until it reads at 4.5:1 on the ground and on
  /// clay, and the focus rim follows it at 3:1.
  ///
  /// ```dart
  /// ClayThemeData.from(accent: const Color(0xFF4F7BF7), brightness: Brightness.light)
  /// ```
  factory ClayThemeData.from({
    required Color accent,
    Brightness brightness = Brightness.light,
    String? fontFamily,
    String? fontPackage,
    ClayDensity? density,
  }) {
    final base = brightness == Brightness.dark
        ? const ClayColors.dark()
        : const ClayColors.light();
    final onAccent = base.onColor(accent);
    var ink = HSLColor.fromColor(accent);
    double readOn(Color c) =>
        math.min(_contrast(c, base.ground), _contrast(c, base.clay));
    for (var i = 0; i < 40 && readOn(ink.toColor()) < 4.5; i++) {
      ink = ink.withLightness(
        (ink.lightness + (brightness == Brightness.dark ? 0.02 : -0.02)).clamp(
          0.0,
          1.0,
        ),
      );
    }
    var focus = HSLColor.fromColor(ink.toColor());
    double rimOn(Color c) =>
        math.min(_contrast(c, base.well), _contrast(c, base.clay));
    for (var i = 0; i < 40 && rimOn(focus.toColor()) < 3; i++) {
      focus = focus.withLightness(
        (focus.lightness + (brightness == Brightness.dark ? 0.02 : -0.02))
            .clamp(0.0, 1.0),
      );
    }
    final colors = base.copyWith(
      accent: accent,
      onAccent: onAccent,
      accentInk: ink.toColor(),
      focus: focus.toColor(),
    );
    return ClayThemeData(
      colors: colors,
      textTheme: ClayTextTheme.of(
        ink: colors.ink,
        secondaryInk: colors.inkSecondary,
        family: fontFamily,
        package: fontPackage,
      ),
      density: density,
    );
  }

  /// The presets' names, the first the default.
  static const List<String> presets = ['clay'];

  /// The preset named [name] at [brightness].
  factory ClayThemeData.preset(
    String name,
    Brightness brightness, {
    ClayDensity? density,
  }) {
    assert(presets.contains(name), 'Clay has no preset named $name.');
    return ClayThemeData.clay(brightness, density: density);
  }

  /// The colours.
  final ClayColors colors;

  /// The type.
  final ClayTextTheme textTheme;

  /// How tight controls stand.
  final ClayDensity density;

  /// Every `ClayButton`'s style.
  final ClayStyle? buttonStyle;

  /// Every `ClayButton.filled`'s style.
  final ClayStyle? filledButtonStyle;

  /// Every `ClayButton.text`'s style.
  final ClayStyle? textButtonStyle;

  /// Every `ClayIconButton`'s style.
  final ClayStyle? iconButtonStyle;

  /// Every `ClayTextField`'s style.
  final ClayStyle? textFieldStyle;

  /// Every `ClaySelect`'s style.
  final ClayStyle? selectStyle;

  /// Every `ClayCheckbox`'s style.
  final ClayStyle? checkboxStyle;

  /// Every `ClayRadio`'s style.
  final ClayStyle? radioStyle;

  /// Every `ClaySwitch`'s style.
  final ClayStyle? switchStyle;

  /// Every `ClaySegmentedButton`'s style.
  final ClayStyle? segmentedButtonStyle;

  /// Every `ClayChip`'s style.
  final ClayStyle? chipStyle;

  /// Every `ClayListTile`'s style.
  final ClayStyle? listTileStyle;

  /// Every `ClayGroup`'s style.
  final ClayStyle? groupStyle;

  /// Every `ClayCard`'s style.
  final ClayStyle? cardStyle;

  /// Every `ClaySectionHeader`'s style.
  final ClayStyle? sectionHeaderStyle;

  /// Every `ClayTabBar`'s style.
  final ClayStyle? tabBarStyle;

  /// Every `ClayTopBar`'s style.
  final ClayStyle? topBarStyle;

  /// Every `ClayNavigationBar`'s style.
  final ClayStyle? navigationBarStyle;

  /// Every `ClayNavigationRail`'s style.
  final ClayStyle? navigationRailStyle;

  /// Every `ClaySidebar`'s style.
  final ClayStyle? sidebarStyle;

  /// Every `ClayDialog`'s style.
  final ClayStyle? dialogStyle;

  /// Every bottom sheet's style.
  final ClayStyle? sheetStyle;

  /// Every menu's and open list's style.
  final ClayStyle? menuStyle;

  /// Every toast's style.
  final ClayStyle? toastStyle;

  /// Every progress ring's and bar's style.
  final ClayStyle? progressStyle;

  /// Every button group's style.
  final ClayStyle? buttonGroupStyle;

  /// Every toggle group's style.
  final ClayStyle? toggleGroupStyle;

  /// Every split key's style.
  final ClayStyle? splitButtonStyle;

  /// Every link's style.
  final ClayStyle? linkStyle;

  /// Every keycap's style.
  final ClayStyle? kbdStyle;

  /// Every search field's style.
  final ClayStyle? searchFieldStyle;

  /// Every input group's style.
  final ClayStyle? inputGroupStyle;

  /// Every one-time code's cups' style.
  final ClayStyle? otpFieldStyle;

  /// Every number field's style.
  final ClayStyle? numberFieldStyle;

  /// Every combobox's style.
  final ClayStyle? comboboxStyle;

  /// Every tag input's style.
  final ClayStyle? tagInputStyle;

  /// Every slider's style: fill the run, foreground the ball.
  final ClayStyle? sliderStyle;

  /// Every rating's style: fill the stars given.
  final ClayStyle? ratingStyle;

  /// Every file tray's style.
  final ClayStyle? fileDropStyle;

  /// Every calendar's style: fill the chosen day's ball.
  final ClayStyle? calendarStyle;

  /// Every time field's style.
  final ClayStyle? timeFieldStyle;

  /// Every breadcrumb's style: foreground the current place.
  final ClayStyle? breadcrumbStyle;

  /// Every pagination's style: fill the current page.
  final ClayStyle? paginationStyle;

  /// Every step bar's style: fill the steps done.
  final ClayStyle? stepProgressStyle;

  /// Every set of page dots' style: fill the current dot.
  final ClayStyle? pageDotsStyle;

  /// Every menu bar's style: fill the slab.
  final ClayStyle? menuBarStyle;

  /// Every command palette's style.
  final ClayStyle? commandPaletteStyle;

  /// Every popover's and hover card's style.
  final ClayStyle? popoverStyle;

  /// Every tooltip's style: fill the slab.
  final ClayStyle? tooltipStyle;

  /// Every data table's style: fill the card; under selected, a chosen row's dent.
  final ClayStyle? dataTableStyle;

  /// Every scroll area's style: fill the thumb.
  final ClayStyle? scrollAreaStyle;

  /// Every split view's style: fill the grip.
  final ClayStyle? splitViewStyle;

  /// Every tree's style: fill the chosen row's dent.
  final ClayStyle? treeStyle;

  /// Every icon tile's style.
  final ClayStyle? iconTileStyle;

  /// Every disclosure's style.
  final ClayStyle? disclosureStyle;

  /// Every plain table's style.
  final ClayStyle? tableStyle;

  /// Every timeline's style.
  final ClayStyle? timelineStyle;

  /// Every avatar's style.
  final ClayStyle? avatarStyle;

  /// Every count badge's style.
  final ClayStyle? badgeStyle;

  /// Every tag's style.
  final ClayStyle? tagStyle;

  /// Every meter's style.
  final ClayStyle? meterStyle;

  /// Every banner's style.
  final ClayStyle? bannerStyle;

  /// Every state view's style.
  final ClayStyle? stateViewStyle;

  /// Every line chart's style.
  final ClayStyle? lineChartStyle;

  /// Every area chart's style.
  final ClayStyle? areaChartStyle;

  /// Every bar chart's style.
  final ClayStyle? barChartStyle;

  /// Every pie chart's style.
  final ClayStyle? pieChartStyle;

  /// Every sparkline's style.
  final ClayStyle? sparklineStyle;

  /// Every date field's style.
  final ClayStyle? datePickerStyle;

  /// Every date-range field's style.
  final ClayStyle? dateRangePickerStyle;

  /// Every wheel's style.
  final ClayStyle? wheelPickerStyle;

  /// Every time picker's style.
  final ClayStyle? timePickerStyle;

  /// Every colour picker's style.
  final ClayStyle? colorPickerStyle;

  /// Every carousel's style.
  final ClayStyle? carouselStyle;

  /// Every reorderable list's style.
  final ClayStyle? reorderableListStyle;

  /// Every swipe row's style.
  final ClayStyle? swipeRowStyle;

  /// Every pull-to-refresh's style.
  final ClayStyle? pullToRefreshStyle;

  /// Every description list's style.
  final ClayStyle? descriptionListStyle;

  /// Every avatar group's style.
  final ClayStyle? avatarGroupStyle;

  /// Every media frame's style.
  final ClayStyle? mediaStyle;

  /// Every skeleton's style.
  final ClayStyle? skeletonStyle;

  /// Every form field's style.
  final ClayStyle? formFieldStyle;

  /// Every spinner's style.
  final ClayStyle? spinnerStyle;

  /// Every groove's style.
  final ClayStyle? grooveStyle;

  /// Every scaffold's style.
  final ClayStyle? scaffoldStyle;

  /// Every context menu's style.
  final ClayStyle? contextMenuStyle;

  /// Every field label's style.
  final ClayStyle? fieldLabelStyle;

  /// Every field message's style.
  final ClayStyle? fieldMessageStyle;

  /// Day or night.
  Brightness get brightness => colors.brightness;

  /// A control's height at this [density].
  double get controlHeight => density.height(ClayMetrics.controlHeight);

  /// A list row's least height at this [density].
  double get rowHeight => density.height(ClayMetrics.rowHeight);

  /// A copy with the given fields changed.
  ClayThemeData copyWith({
    ClayColors? colors,
    ClayTextTheme? textTheme,
    ClayDensity? density,
    ClayStyle? buttonStyle,
    ClayStyle? filledButtonStyle,
    ClayStyle? textButtonStyle,
    ClayStyle? iconButtonStyle,
    ClayStyle? textFieldStyle,
    ClayStyle? selectStyle,
    ClayStyle? checkboxStyle,
    ClayStyle? radioStyle,
    ClayStyle? switchStyle,
    ClayStyle? segmentedButtonStyle,
    ClayStyle? chipStyle,
    ClayStyle? listTileStyle,
    ClayStyle? groupStyle,
    ClayStyle? cardStyle,
    ClayStyle? sectionHeaderStyle,
    ClayStyle? tabBarStyle,
    ClayStyle? topBarStyle,
    ClayStyle? navigationBarStyle,
    ClayStyle? navigationRailStyle,
    ClayStyle? sidebarStyle,
    ClayStyle? dialogStyle,
    ClayStyle? sheetStyle,
    ClayStyle? menuStyle,
    ClayStyle? toastStyle,
    ClayStyle? progressStyle,
    ClayStyle? buttonGroupStyle,
    ClayStyle? toggleGroupStyle,
    ClayStyle? splitButtonStyle,
    ClayStyle? linkStyle,
    ClayStyle? kbdStyle,
    ClayStyle? searchFieldStyle,
    ClayStyle? inputGroupStyle,
    ClayStyle? otpFieldStyle,
    ClayStyle? numberFieldStyle,
    ClayStyle? comboboxStyle,
    ClayStyle? tagInputStyle,
    ClayStyle? sliderStyle,
    ClayStyle? ratingStyle,
    ClayStyle? fileDropStyle,
    ClayStyle? calendarStyle,
    ClayStyle? timeFieldStyle,
    ClayStyle? breadcrumbStyle,
    ClayStyle? paginationStyle,
    ClayStyle? stepProgressStyle,
    ClayStyle? pageDotsStyle,
    ClayStyle? menuBarStyle,
    ClayStyle? commandPaletteStyle,
    ClayStyle? popoverStyle,
    ClayStyle? tooltipStyle,
    ClayStyle? dataTableStyle,
    ClayStyle? scrollAreaStyle,
    ClayStyle? splitViewStyle,
    ClayStyle? treeStyle,
    ClayStyle? iconTileStyle,
    ClayStyle? disclosureStyle,
    ClayStyle? tableStyle,
    ClayStyle? timelineStyle,
    ClayStyle? avatarStyle,
    ClayStyle? badgeStyle,
    ClayStyle? tagStyle,
    ClayStyle? meterStyle,
    ClayStyle? bannerStyle,
    ClayStyle? stateViewStyle,
    ClayStyle? lineChartStyle,
    ClayStyle? areaChartStyle,
    ClayStyle? barChartStyle,
    ClayStyle? pieChartStyle,
    ClayStyle? sparklineStyle,
    ClayStyle? datePickerStyle,
    ClayStyle? dateRangePickerStyle,
    ClayStyle? wheelPickerStyle,
    ClayStyle? timePickerStyle,
    ClayStyle? colorPickerStyle,
    ClayStyle? carouselStyle,
    ClayStyle? reorderableListStyle,
    ClayStyle? swipeRowStyle,
    ClayStyle? pullToRefreshStyle,
    ClayStyle? descriptionListStyle,
    ClayStyle? avatarGroupStyle,
    ClayStyle? mediaStyle,
    ClayStyle? skeletonStyle,
    ClayStyle? formFieldStyle,
    ClayStyle? spinnerStyle,
    ClayStyle? grooveStyle,
    ClayStyle? scaffoldStyle,
    ClayStyle? contextMenuStyle,
    ClayStyle? fieldLabelStyle,
    ClayStyle? fieldMessageStyle,
  }) => ClayThemeData(
    colors: colors ?? this.colors,
    textTheme: textTheme ?? this.textTheme,
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
    chipStyle: chipStyle ?? this.chipStyle,
    listTileStyle: listTileStyle ?? this.listTileStyle,
    groupStyle: groupStyle ?? this.groupStyle,
    cardStyle: cardStyle ?? this.cardStyle,
    sectionHeaderStyle: sectionHeaderStyle ?? this.sectionHeaderStyle,
    tabBarStyle: tabBarStyle ?? this.tabBarStyle,
    topBarStyle: topBarStyle ?? this.topBarStyle,
    navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
    navigationRailStyle: navigationRailStyle ?? this.navigationRailStyle,
    sidebarStyle: sidebarStyle ?? this.sidebarStyle,
    dialogStyle: dialogStyle ?? this.dialogStyle,
    sheetStyle: sheetStyle ?? this.sheetStyle,
    menuStyle: menuStyle ?? this.menuStyle,
    toastStyle: toastStyle ?? this.toastStyle,
    progressStyle: progressStyle ?? this.progressStyle,
    buttonGroupStyle: buttonGroupStyle ?? this.buttonGroupStyle,
    toggleGroupStyle: toggleGroupStyle ?? this.toggleGroupStyle,
    splitButtonStyle: splitButtonStyle ?? this.splitButtonStyle,
    linkStyle: linkStyle ?? this.linkStyle,
    kbdStyle: kbdStyle ?? this.kbdStyle,
    searchFieldStyle: searchFieldStyle ?? this.searchFieldStyle,
    inputGroupStyle: inputGroupStyle ?? this.inputGroupStyle,
    otpFieldStyle: otpFieldStyle ?? this.otpFieldStyle,
    numberFieldStyle: numberFieldStyle ?? this.numberFieldStyle,
    comboboxStyle: comboboxStyle ?? this.comboboxStyle,
    tagInputStyle: tagInputStyle ?? this.tagInputStyle,
    sliderStyle: sliderStyle ?? this.sliderStyle,
    ratingStyle: ratingStyle ?? this.ratingStyle,
    fileDropStyle: fileDropStyle ?? this.fileDropStyle,
    calendarStyle: calendarStyle ?? this.calendarStyle,
    timeFieldStyle: timeFieldStyle ?? this.timeFieldStyle,
    breadcrumbStyle: breadcrumbStyle ?? this.breadcrumbStyle,
    paginationStyle: paginationStyle ?? this.paginationStyle,
    stepProgressStyle: stepProgressStyle ?? this.stepProgressStyle,
    pageDotsStyle: pageDotsStyle ?? this.pageDotsStyle,
    menuBarStyle: menuBarStyle ?? this.menuBarStyle,
    commandPaletteStyle: commandPaletteStyle ?? this.commandPaletteStyle,
    popoverStyle: popoverStyle ?? this.popoverStyle,
    tooltipStyle: tooltipStyle ?? this.tooltipStyle,
    dataTableStyle: dataTableStyle ?? this.dataTableStyle,
    scrollAreaStyle: scrollAreaStyle ?? this.scrollAreaStyle,
    splitViewStyle: splitViewStyle ?? this.splitViewStyle,
    treeStyle: treeStyle ?? this.treeStyle,
    iconTileStyle: iconTileStyle ?? this.iconTileStyle,
    disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    tableStyle: tableStyle ?? this.tableStyle,
    timelineStyle: timelineStyle ?? this.timelineStyle,
    avatarStyle: avatarStyle ?? this.avatarStyle,
    badgeStyle: badgeStyle ?? this.badgeStyle,
    tagStyle: tagStyle ?? this.tagStyle,
    meterStyle: meterStyle ?? this.meterStyle,
    bannerStyle: bannerStyle ?? this.bannerStyle,
    stateViewStyle: stateViewStyle ?? this.stateViewStyle,
    lineChartStyle: lineChartStyle ?? this.lineChartStyle,
    areaChartStyle: areaChartStyle ?? this.areaChartStyle,
    barChartStyle: barChartStyle ?? this.barChartStyle,
    pieChartStyle: pieChartStyle ?? this.pieChartStyle,
    sparklineStyle: sparklineStyle ?? this.sparklineStyle,
    datePickerStyle: datePickerStyle ?? this.datePickerStyle,
    dateRangePickerStyle: dateRangePickerStyle ?? this.dateRangePickerStyle,
    wheelPickerStyle: wheelPickerStyle ?? this.wheelPickerStyle,
    timePickerStyle: timePickerStyle ?? this.timePickerStyle,
    colorPickerStyle: colorPickerStyle ?? this.colorPickerStyle,
    carouselStyle: carouselStyle ?? this.carouselStyle,
    reorderableListStyle: reorderableListStyle ?? this.reorderableListStyle,
    swipeRowStyle: swipeRowStyle ?? this.swipeRowStyle,
    pullToRefreshStyle: pullToRefreshStyle ?? this.pullToRefreshStyle,
    descriptionListStyle: descriptionListStyle ?? this.descriptionListStyle,
    avatarGroupStyle: avatarGroupStyle ?? this.avatarGroupStyle,
    mediaStyle: mediaStyle ?? this.mediaStyle,
    skeletonStyle: skeletonStyle ?? this.skeletonStyle,
    formFieldStyle: formFieldStyle ?? this.formFieldStyle,
    spinnerStyle: spinnerStyle ?? this.spinnerStyle,
    grooveStyle: grooveStyle ?? this.grooveStyle,
    scaffoldStyle: scaffoldStyle ?? this.scaffoldStyle,
    contextMenuStyle: contextMenuStyle ?? this.contextMenuStyle,
    fieldLabelStyle: fieldLabelStyle ?? this.fieldLabelStyle,
    fieldMessageStyle: fieldMessageStyle ?? this.fieldMessageStyle,
  );

  List<ClayStyle?> get _styles => [
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
    chipStyle,
    listTileStyle,
    groupStyle,
    cardStyle,
    sectionHeaderStyle,
    tabBarStyle,
    topBarStyle,
    navigationBarStyle,
    navigationRailStyle,
    sidebarStyle,
    dialogStyle,
    sheetStyle,
    menuStyle,
    toastStyle,
    progressStyle,
    buttonGroupStyle,
    toggleGroupStyle,
    splitButtonStyle,
    linkStyle,
    kbdStyle,
    searchFieldStyle,
    inputGroupStyle,
    otpFieldStyle,
    numberFieldStyle,
    comboboxStyle,
    tagInputStyle,
    sliderStyle,
    ratingStyle,
    fileDropStyle,
    calendarStyle,
    timeFieldStyle,
    breadcrumbStyle,
    paginationStyle,
    stepProgressStyle,
    pageDotsStyle,
    menuBarStyle,
    commandPaletteStyle,
    popoverStyle,
    tooltipStyle,
    dataTableStyle,
    scrollAreaStyle,
    splitViewStyle,
    treeStyle,
    iconTileStyle,
    disclosureStyle,
    tableStyle,
    timelineStyle,
    avatarStyle,
    badgeStyle,
    tagStyle,
    meterStyle,
    bannerStyle,
    stateViewStyle,
    lineChartStyle,
    areaChartStyle,
    barChartStyle,
    pieChartStyle,
    sparklineStyle,
    datePickerStyle,
    dateRangePickerStyle,
    wheelPickerStyle,
    timePickerStyle,
    colorPickerStyle,
    carouselStyle,
    reorderableListStyle,
    swipeRowStyle,
    pullToRefreshStyle,
    descriptionListStyle,
    avatarGroupStyle,
    mediaStyle,
    skeletonStyle,
    formFieldStyle,
    spinnerStyle,
    grooveStyle,
    scaffoldStyle,
    contextMenuStyle,
    fieldLabelStyle,
    fieldMessageStyle,
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
    'chipStyle',
    'listTileStyle',
    'groupStyle',
    'cardStyle',
    'sectionHeaderStyle',
    'tabBarStyle',
    'topBarStyle',
    'navigationBarStyle',
    'navigationRailStyle',
    'sidebarStyle',
    'dialogStyle',
    'sheetStyle',
    'menuStyle',
    'toastStyle',
    'progressStyle',
    'buttonGroupStyle',
    'toggleGroupStyle',
    'splitButtonStyle',
    'linkStyle',
    'kbdStyle',
    'searchFieldStyle',
    'inputGroupStyle',
    'otpFieldStyle',
    'numberFieldStyle',
    'comboboxStyle',
    'tagInputStyle',
    'sliderStyle',
    'ratingStyle',
    'fileDropStyle',
    'calendarStyle',
    'timeFieldStyle',
    'breadcrumbStyle',
    'paginationStyle',
    'stepProgressStyle',
    'pageDotsStyle',
    'menuBarStyle',
    'commandPaletteStyle',
    'popoverStyle',
    'tooltipStyle',
    'dataTableStyle',
    'scrollAreaStyle',
    'splitViewStyle',
    'treeStyle',
    'iconTileStyle',
    'disclosureStyle',
    'tableStyle',
    'timelineStyle',
    'avatarStyle',
    'badgeStyle',
    'tagStyle',
    'meterStyle',
    'bannerStyle',
    'stateViewStyle',
    'lineChartStyle',
    'areaChartStyle',
    'barChartStyle',
    'pieChartStyle',
    'sparklineStyle',
    'datePickerStyle',
    'dateRangePickerStyle',
    'wheelPickerStyle',
    'timePickerStyle',
    'colorPickerStyle',
    'carouselStyle',
    'reorderableListStyle',
    'swipeRowStyle',
    'pullToRefreshStyle',
    'descriptionListStyle',
    'avatarGroupStyle',
    'mediaStyle',
    'skeletonStyle',
    'formFieldStyle',
    'spinnerStyle',
    'grooveStyle',
    'scaffoldStyle',
    'contextMenuStyle',
    'fieldLabelStyle',
    'fieldMessageStyle',
  ];

  /// Between [a] and [b]: colours, type and density move; a part's style
  /// changes at the middle.
  static ClayThemeData lerp(ClayThemeData a, ClayThemeData b, double t) {
    if (identical(a, b)) return a;
    final s = t < 0.5 ? a : b;
    return s.copyWith(
      colors: ClayColors.lerp(a.colors, b.colors, t),
      textTheme: ClayTextTheme.lerp(a.textTheme, b.textTheme, t),
      density: ClayDensity.lerp(a.density, b.density, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ClayThemeData &&
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
      ..add(DiagnosticsProperty<ClayColors>('colors', colors))
      ..add(DiagnosticsProperty<ClayTextTheme>('textTheme', textTheme))
      ..add(DiagnosticsProperty<ClayDensity>('density', density));
    for (final (i, s) in _styles.indexed) {
      properties.add(
        DiagnosticsProperty<ClayStyle>(_styleNames[i], s, defaultValue: null),
      );
    }
  }
}

/// Clay's theme for [child] and everything below: its colours, type,
/// density, tap floors, spacing grid, the Material theme its parts draw with
/// inside (no ink, no splash, the look's own selection), and the words for
/// everything below. Put it once in an app's `builder:`, above the
/// navigator, with a `ClayToaster` inside it.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: clayPageTransitions)), builder: (context, child) => ClayTheme(data: ClayThemeData.clay(Brightness.light), child: ClayToaster(child: child!)), home: const Placeholder())
/// ```
class ClayTheme extends StatelessWidget {
  /// [data] for [child] and everything below it.
  const ClayTheme({super.key, required this.data, required this.child});

  /// The theme.
  final ClayThemeData data;

  /// What the theme is for.
  final Widget child;

  /// Clay's tap floors: 44 by 44 for a finger, 24 by 24 for a pointer, as
  /// ui_core's defaults.
  static const DesignTapTargets tapTargets = DesignTapTargets.fallback;

  static final ClayThemeData _fallback = ClayThemeData.light();

  /// The theme above [context], or Clay by day when there is none.
  static ClayThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallback;

  /// The theme above [context], or null.
  static ClayThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedClayTheme>()
      ?.theme
      .data;

  @override
  Widget build(BuildContext context) {
    final colors = data.colors;
    final base = _bridges[data] ??= _materialUnder(data);
    // An app's own choice of page transitions stays; Flutter's default
    // becomes Clay's.
    final host = Theme.of(context).pageTransitionsTheme;
    final material = host == const PageTransitionsTheme()
        ? base
        : base.copyWith(pageTransitionsTheme: host);
    Widget under = _InheritedClayTheme(
      theme: this,
      child: Theme(
        data: material,
        child: DesignSpacingScope(
          // Clay keeps ui_core's 4 px grid.
          spacing: DesignSpacing.fallback,
          child: DesignTapTargetScope(
            targets: tapTargets,
            child: DefaultSelectionStyle(
              cursorColor: colors.accentInk,
              selectionColor: colors.accent.withValues(alpha: 0.32),
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
    // Clay's text field asks for the words of the Material library it is
    // built on, and its menu on iOS for Cupertino's. An app with neither gets
    // Clay's own (English), never a throw; an app that has them keeps its
    // own.
    final missing = Localizations.maybeLocaleOf(context) == null
        ? const <LocalizationsDelegate<Object?>>[]
        : <LocalizationsDelegate<Object?>>[
            if (Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                ) ==
                null)
              clayMaterialWords,
            if (Localizations.of<CupertinoLocalizations>(
                  context,
                  CupertinoLocalizations,
                ) ==
                null)
              clayCupertinoWords,
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

  static final Expando<ThemeData> _bridges = Expando('ClayTheme bridges');

  static ThemeData _materialUnder(ClayThemeData data) {
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
      scaffoldBackgroundColor: colors.ground,
      canvasColor: colors.ground,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: clayPageTransitions,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: colors.brightness,
        primary: colors.accentInk,
        onPrimary: colors.onAccent,
        surface: colors.ground,
        onSurface: colors.ink,
        error: colors.dangerInk,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accentInk,
        selectionColor: colors.accent.withValues(alpha: 0.32),
        selectionHandleColor: colors.accentInk,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClayThemeData>('data', data));
  }
}

class _InheritedClayTheme extends InheritedTheme {
  const _InheritedClayTheme({required this.theme, required super.child});

  final ClayTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      ClayTheme(data: theme.data, child: child);

  @override
  bool updateShouldNotify(_InheritedClayTheme old) =>
      theme.data != old.theme.data;
}

/// [ClayTheme] that moves to each new [data] over [duration], as
/// `AnimatedTheme` does: day to night, one accent to another. Under Reduce
/// Motion it changes at once.
class AnimatedClayTheme extends ImplicitlyAnimatedWidget {
  /// [child] under a theme that moves to [data].
  const AnimatedClayTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve = Curves.easeOut,
    super.duration = const Duration(milliseconds: 220),
    super.onEnd,
  });

  /// The theme to arrive at.
  final ClayThemeData data;

  /// What the theme is for.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedClayTheme> createState() =>
      _AnimatedClayThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClayThemeData>('data', data));
  }
}

class _AnimatedClayThemeState
    extends AnimatedWidgetBaseState<AnimatedClayTheme> {
  _ClayThemeTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => _ClayThemeTween(begin: value as ClayThemeData),
    ) as _ClayThemeTween?;
  }

  @override
  Widget build(BuildContext context) => ClayTheme(
    data: MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? widget.data
        : _data!.evaluate(animation),
    child: widget.child,
  );
}

class _ClayThemeTween extends Tween<ClayThemeData> {
  _ClayThemeTween({super.begin});

  @override
  ClayThemeData lerp(double t) => ClayThemeData.lerp(begin!, end!, t);
}

/// `context.clayTheme`: the [ClayThemeData] above.
extension ClayThemeContext on BuildContext {
  /// The [ClayThemeData] above this context ([ClayTheme.of]).
  ClayThemeData get clayTheme => ClayTheme.of(this);
}

/// Clay's page change on every platform, for an app's own `ThemeData`:
/// `PageTransitionsTheme(builders: clayPageTransitions)`. On iOS the swipe
/// from the screen's edge still pops a page, round Clay's own push.
const Map<TargetPlatform, PageTransitionsBuilder> clayPageTransitions = {
  TargetPlatform.android: ClayPageTransitionsBuilder(),
  TargetPlatform.fuchsia: ClayPageTransitionsBuilder(),
  TargetPlatform.iOS: SwipeBackPageTransitionsBuilder(
    ClayPageTransitionsBuilder(),
  ),
  TargetPlatform.linux: ClayPageTransitionsBuilder(),
  TargetPlatform.macOS: ClayPageTransitionsBuilder(),
  TargetPlatform.windows: ClayPageTransitionsBuilder(),
};
