/// Terminal's theme: the palette and its roles, the face and the cell grid,
/// the weight of the box lines, every part's style and the motion, as one
/// immutable [TermThemeData] under a [TermTheme].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
// One line, so a tool that copies this file into an app and reads its
// imports a line at a time keeps it whole.
// dart format off
import 'package:material_ui/material_ui.dart' show ColorScheme, DefaultMaterialLocalizations, MaterialLocalizations, MaterialTapTargetSize, NoSplash, PageTransitionsTheme, TextSelectionThemeData, TextTheme, Theme, VisualDensity;
// dart format on
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'components/route.dart';
import 'fonts.dart';
import 'grid.dart';
import 'palette.dart';
import 'style.dart';

/// One of the sixteen ANSI slots of a [TermPalette]: which one is the
/// accent ([TermThemeData.from]'s `accentSlot`).
enum TermAnsi {
  /// ANSI 0.
  black,

  /// ANSI 1.
  red,

  /// ANSI 2.
  green,

  /// ANSI 3.
  yellow,

  /// ANSI 4.
  blue,

  /// ANSI 5.
  magenta,

  /// ANSI 6.
  cyan,

  /// ANSI 7.
  white,

  /// ANSI 8.
  brightBlack,

  /// ANSI 9.
  brightRed,

  /// ANSI 10.
  brightGreen,

  /// ANSI 11.
  brightYellow,

  /// ANSI 12.
  brightBlue,

  /// ANSI 13.
  brightMagenta,

  /// ANSI 14.
  brightCyan,

  /// ANSI 15.
  brightWhite;

  /// This slot's colour in [palette].
  Color of(TermPalette palette) => switch (this) {
    black => palette.black,
    red => palette.red,
    green => palette.green,
    yellow => palette.yellow,
    blue => palette.blue,
    magenta => palette.magenta,
    cyan => palette.cyan,
    white => palette.white,
    brightBlack => palette.brightBlack,
    brightRed => palette.brightRed,
    brightGreen => palette.brightGreen,
    brightYellow => palette.brightYellow,
    brightBlue => palette.brightBlue,
    brightMagenta => palette.brightMagenta,
    brightCyan => palette.brightCyan,
    brightWhite => palette.brightWhite,
  };
}

/// The weight of the box lines: box drawing's two, light (`─ │ ┌`) and
/// heavy (`━ ┃ ┏`). A width between them would read as a web border.
enum TermStroke {
  /// Light lines, one logical pixel at the normal size: Terminal's own.
  light(1),

  /// Heavy lines, two logical pixels at the normal size.
  heavy(2);

  const TermStroke(this.width);

  /// The line's width at the normal text size, in logical pixels.
  final double width;
}

/// The contrast ratio of [a] against [b], 1 to 21, as WCAG reckons it.
double termContrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [color] stepped lighter (on a dark [on]) or darker (on a light one) in
/// its own hue until it reads at [ratio] on [on]: a brand colour made fit
/// to be Terminal's accent.
///
/// ```dart
/// final accent = termReadable(const Color(0xFF0A7D4F), on: TermPalette.night.background);
/// ```
Color termReadable(Color color, {required Color on, double ratio = 4.5}) {
  if (termContrast(color, on) >= ratio) return color;
  final toward = on.computeLuminance() < 0.18
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF000000);
  for (var t = 0.02; t <= 1.0; t += 0.02) {
    final c = Color.lerp(color, toward, t)!;
    if (termContrast(c, on) >= ratio) return c;
  }
  return toward;
}

/// How Terminal looks: a [palette] and the roles drawn from it, the [face]
/// and the cell [grid], the [stroke] every box line is drawn at, and a
/// style for each part.
///
/// [TermThemeData.dark] (the night palette, Terminal's default) and
/// [TermThemeData.light] (paper) are its presets; [TermThemeData.from] takes
/// any [TermPalette], which ANSI slot is the accent or a brand colour for
/// it, a face and a stroke, and holds the palette's contrast. Read the
/// theme in force with [TermTheme.of].
///
/// A part's style sits in two layers, as Material's buttons do: the theme's
/// slot for that part ([buttonStyle], [paneStyle], ...) restyles every one
/// of them, and the part's own `style:` restyles one. Both read only colour
/// and weight ([TermStyle]): the grid, the brackets and the box lines are
/// the look.
///
/// ```dart
/// final theme = TermThemeData.from(
///   TermPalette.night,
///   accent: const Color(0xFF34C77B),
/// ).copyWith(
///   filledButtonStyle: TermStyle(
///     textStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
///   ),
/// );
/// ```
@immutable
class TermThemeData with Diagnosticable {
  /// A theme with every role given; the part styles are optional.
  const TermThemeData.raw({
    required this.brightness,
    required this.palette,
    required this.background,
    required this.surface,
    required this.foreground,
    required this.dim,
    required this.rule,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    TermGrid grid = const TermGrid(),
    this.face = TermFace.jetBrainsMono,
    this.stroke = TermStroke.light,
    this.buttonStyle,
    this.filledButtonStyle,
    this.destructiveButtonStyle,
    this.iconButtonStyle,
    this.linkStyle,
    this.toggleGroupStyle,
    this.splitButtonStyle,
    this.chipStyle,
    this.tagStyle,
    this.badgeStyle,
    this.keyStyle,
    this.textFieldStyle,
    this.selectStyle,
    this.checkboxStyle,
    this.radioStyle,
    this.switchStyle,
    this.sliderStyle,
    this.ratingStyle,
    this.otpFieldStyle,
    this.calendarStyle,
    this.colorPickerStyle,
    this.topBarStyle,
    this.tabBarStyle,
    this.navigationBarStyle,
    this.sideBarStyle,
    this.statusLineStyle,
    this.breadcrumbStyle,
    this.paginationStyle,
    this.stepsStyle,
    this.menuBarStyle,
    this.paneStyle,
    this.listTileStyle,
    this.sectionHeaderStyle,
    this.disclosureStyle,
    this.tableStyle,
    this.treeStyle,
    this.timelineStyle,
    this.avatarStyle,
    this.dividerStyle,
    this.scrollbarStyle,
    this.splitViewStyle,
    this.descriptionListStyle,
    this.emptyStateStyle,
    this.mediaStyle,
    this.menuStyle,
    this.dialogStyle,
    this.sheetStyle,
    this.popoverStyle,
    this.tooltipStyle,
    this.toastStyle,
    this.bannerStyle,
    this.progressStyle,
    this.spinnerStyle,
    this.meterStyle,
    this.skeletonStyle,
    this.chartStyle,
  }) : _grid = grid; // ignore: prefer_initializing_formals, the public name is grid, which reads the face too

  /// The roles drawn from [palette] for [brightness]: the accent is the
  /// ANSI [accentSlot] (cyan by default) or a brand [accent], with the words
  /// on it picked for contrast; success green, danger red, warning yellow,
  /// info blue; dim words are bright black; a frame's line is a step
  /// between dim and the background, still 3:1 on it, as an edge must be.
  ///
  /// The accent must read at 4.5:1 on the background, the palette's own
  /// rule: a debug build asserts it (take [termReadable] of a brand colour
  /// that falls short).
  factory TermThemeData.from(
    TermPalette palette, {
    Brightness brightness = Brightness.dark,
    TermAnsi accentSlot = TermAnsi.cyan,
    Color? accent,
    TermGrid grid = const TermGrid(),
    TermFace face = TermFace.jetBrainsMono,
    TermStroke stroke = TermStroke.light,
  }) {
    final dark = brightness == Brightness.dark;
    final bg = palette.background;
    final ink = accent ?? accentSlot.of(palette);
    assert(
      termContrast(ink, bg) >= 4.5,
      "Terminal's accent reads at 4.5:1 or more on the background (the "
      "palette's rule): ${_hex(ink)} is "
      '${termContrast(ink, bg).toStringAsFixed(2)}:1 on ${_hex(bg)}. Take '
      'termReadable(${_hex(ink)}, on: ${_hex(bg)}).',
    );
    // The words on the accent: the palette's ground or its ink, whichever
    // reads better.
    final onAccent =
        termContrast(bg, ink) >= termContrast(palette.foreground, ink)
        ? bg
        : palette.foreground;
    assert(
      termContrast(onAccent, ink) >= 4.5,
      'Words on the accent read at 4.5:1 or more: on ${_hex(ink)} neither '
      "the palette's ground nor its ink does. Take a darker or lighter "
      'accent.',
    );
    final Color surface;
    final Color rule;
    if (palette == TermPalette.night) {
      surface = const Color(0xFF171A1F);
      rule = const Color(0xFF626A76);
    } else if (palette == TermPalette.paper) {
      surface = const Color(0xFFEDE9DF);
      rule = const Color(0xFF8A8476);
    } else {
      // Another palette: the surface a step off the ground toward the
      // words, the rule a step toward the dim words, raised to 3:1.
      surface = Color.lerp(bg, palette.foreground, dark ? 0.05 : 0.06)!;
      rule = termReadable(
        Color.lerp(bg, palette.brightBlack, 0.7)!,
        on: bg,
        ratio: 3,
      );
    }
    return TermThemeData.raw(
      brightness: brightness,
      palette: palette,
      background: bg,
      surface: surface,
      foreground: palette.foreground,
      dim: palette.brightBlack,
      rule: rule,
      accent: ink,
      onAccent: onAccent,
      success: palette.green,
      danger: palette.red,
      warning: palette.yellow,
      info: palette.blue,
      grid: grid,
      face: face,
      stroke: stroke,
    );
  }

  /// The night palette: Terminal's default.
  factory TermThemeData.dark({
    TermAnsi accentSlot = TermAnsi.cyan,
    Color? accent,
    TermGrid grid = const TermGrid(),
    TermFace face = TermFace.jetBrainsMono,
    TermStroke stroke = TermStroke.light,
  }) => TermThemeData.from(
    TermPalette.night,
    accentSlot: accentSlot,
    accent: accent,
    grid: grid,
    face: face,
    stroke: stroke,
  );

  /// The paper palette: ink on a warm light ground.
  factory TermThemeData.light({
    TermAnsi accentSlot = TermAnsi.cyan,
    Color? accent,
    TermGrid grid = const TermGrid(),
    TermFace face = TermFace.jetBrainsMono,
    TermStroke stroke = TermStroke.light,
  }) => TermThemeData.from(
    TermPalette.paper,
    brightness: Brightness.light,
    accentSlot: accentSlot,
    accent: accent,
    grid: grid,
    face: face,
    stroke: stroke,
  );

  /// One ink on one ground, as a monochrome terminal draws: the accent and
  /// every tone are the words' own ink, so a state reads from its shape
  /// alone (a doubled line, filled brackets, inverse video, a glyph), never
  /// from a hue.
  factory TermThemeData.monochrome({
    Brightness brightness = Brightness.dark,
    TermGrid grid = const TermGrid(),
    TermFace face = TermFace.jetBrainsMono,
  }) {
    final base = TermThemeData.from(
      brightness == Brightness.dark ? TermPalette.night : TermPalette.paper,
      brightness: brightness,
      grid: grid,
      face: face,
    );
    final ink = base.foreground;
    return base.copyWith(
      accent: ink,
      onAccent: base.background,
      success: ink,
      danger: ink,
      warning: ink,
      info: ink,
    );
  }

  /// The preset for [brightness]: [TermThemeData.light] or
  /// [TermThemeData.dark].
  factory TermThemeData.of(Brightness brightness) =>
      brightness == Brightness.dark
      ? TermThemeData.dark()
      : TermThemeData.light();

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// Whether this is a dark or a light theme.
  final Brightness brightness;

  /// The sixteen colours the roles are drawn from, for an app's own words
  /// (a log's levels, a diff's lines).
  final TermPalette palette;

  /// The screen.
  final Color background;

  /// What floats over the screen: a dialog, a menu, the palette, a toast,
  /// and a field whose list is up.
  final Color surface;

  /// The words.
  final Color foreground;

  /// Secondary words: a time, a count, a hint.
  final Color dim;

  /// The box lines of a frame, a rule and a bracket at rest.
  final Color rule;

  /// Focus, the one primary action, the caret, links and what is live.
  final Color accent;

  /// Words on an [accent] fill.
  final Color onAccent;

  /// Passed, done, on.
  final Color success;

  /// Failed, destructive, an error.
  final Color danger;

  /// Running, waiting, a warning.
  final Color warning;

  /// Information and a neutral highlight.
  final Color info;

  final TermGrid _grid;

  /// The cell grid at the reader's normal text size, its cell as wide as
  /// the [face]'s advance; [TermTheme] grows it with their text scale
  /// ([TermGridContext.termGrid]).
  TermGrid get grid => _grid.forFace(face);

  /// The monospace face every word is set in, with its advance.
  final TermFace face;

  /// The weight of the box lines: light or heavy.
  final TermStroke stroke;

  /// The width of a single box line, in logical pixels at the normal text
  /// size ([stroke]'s); a double line is two of them.
  double get strokeWidth => stroke.width;

  // Part styles: each part's `style:` sits over its slot here, state by
  // state (TermStyleOf). A null slot is the look's own.

  /// The style of [TermButton] (bracketed), under each one's own `style:`. Reads fill (the press), foreground, edge (the brackets), textStyle.
  final TermStyle? buttonStyle;

  /// The style of [TermButton.filled], the screen's primary action, under each one's own `style:`. Reads fill, foreground, edge, textStyle.
  final TermStyle? filledButtonStyle;

  /// The style of either button with `isDestructiveAction`, over its kind's slot, under each one's own `style:`. Reads fill, foreground, edge, textStyle.
  final TermStyle? destructiveButtonStyle;

  /// The style of [TermIconButton], and the steppers of a [TermNumberField], under each one's own `style:`. Reads fill, foreground, edge, textStyle.
  final TermStyle? iconButtonStyle;

  /// The style of [TermLink], under each one's own `style:`. Reads fill (focus and press), foreground.
  final TermStyle? linkStyle;

  /// The style of [TermToggleGroup], under each one's own `style:`. Reads fill (the chosen cells), foreground, edge (the brackets).
  final TermStyle? toggleGroupStyle;

  /// The style of [TermSplitButton]'s two halves, under each one's own `style:`. Reads fill, foreground, edge, textStyle.
  final TermStyle? splitButtonStyle;

  /// The style of [TermChip], under each one's own `style:`. Reads fill (chosen), foreground, edge (the round brackets).
  final TermStyle? chipStyle;

  /// The style of [TermTag], and a [TermTagInput]'s tags, under each one's own `style:`. Reads fill (the ground), foreground.
  final TermStyle? tagStyle;

  /// The style of [TermBadge], under each one's own `style:`. Reads fill (the block), foreground.
  final TermStyle? badgeStyle;

  /// The style of [TermKey], under each one's own `style:`. Reads foreground, edge.
  final TermStyle? keyStyle;

  /// The style of [TermTextField], the fields of [TermPasswordField], [TermCombobox], [TermTagInput] and [TermTimeField], and [TermFileField]'s frame, under each one's own `style:`. Reads edge (the frame), foreground (the words typed), textStyle.
  final TermStyle? textFieldStyle;

  /// The style of [TermSelect], and the fields of [TermDatePicker] and [TermDateRangePicker], under each one's own `style:`. Reads edge, foreground, textStyle.
  final TermStyle? selectStyle;

  /// The style of [TermCheckbox], under each one's own `style:`. Reads fill (the mark), foreground (the label), edge (the brackets).
  final TermStyle? checkboxStyle;

  /// The style of [TermRadio], under each one's own `style:`. Reads fill, foreground, edge.
  final TermStyle? radioStyle;

  /// The style of [TermSwitch], under each one's own `style:`. Reads fill (the on side), foreground, edge.
  final TermStyle? switchStyle;

  /// The style of [TermSlider] and [TermRangeSlider], under each one's own `style:`. Reads fill (the heavy part), foreground (the block), edge (the rule).
  final TermStyle? sliderStyle;

  /// The style of [TermRating], under each one's own `style:`. Reads fill (the marks given), foreground (the marks left), edge (the focus brackets).
  final TermStyle? ratingStyle;

  /// The style of [TermOtpField], under each one's own `style:`. Reads foreground (the characters), edge (the brackets).
  final TermStyle? otpFieldStyle;

  /// The style of [TermCalendar], and the calendars of the date pickers, under each one's own `style:`. Reads fill (a chosen day), foreground (the days), edge (the keyboard's day).
  final TermStyle? calendarStyle;

  /// The style of [TermColorPicker], under each one's own `style:`. Reads edge (the frames and the ring), foreground (the hex).
  final TermStyle? colorPickerStyle;

  /// The style of [TermTopBar], under each one's own `style:`. Reads fill (the ground), foreground (the title), edge (the rule under it).
  final TermStyle? topBarStyle;

  /// The style of [TermTabBar], under each one's own `style:`. Reads fill (the current tab), foreground, edge.
  final TermStyle? tabBarStyle;

  /// The style of [TermNavigationBar], under each one's own `style:`. Reads fill (the current item), foreground, edge (the rule over it).
  final TermStyle? navigationBarStyle;

  /// The style of [TermSideBar] and [TermNavigationRail], under each one's own `style:`. Reads fill (the current item), foreground, edge (the rule beside it).
  final TermStyle? sideBarStyle;

  /// The style of [TermStatusLine], under each one's own `style:`. Reads fill (the ground), foreground.
  final TermStyle? statusLineStyle;

  /// The style of [TermBreadcrumb], under each one's own `style:`. Reads foreground (the path), edge (the separators).
  final TermStyle? breadcrumbStyle;

  /// The style of [TermPagination] and [TermPageDots], under each one's own `style:`. Reads fill (the current page), foreground.
  final TermStyle? paginationStyle;

  /// The style of [TermSteps], under each one's own `style:`. Reads fill (the current step's mark), foreground, edge (the rule between).
  final TermStyle? stepsStyle;

  /// The style of [TermMenuBar]'s titles, under each one's own `style:`. Reads fill (an open title), foreground.
  final TermStyle? menuBarStyle;

  /// The style of [TermPane], and every part drawn in one, under each one's own `style:`. Reads fill (the ground), foreground (the title), edge (the box lines).
  final TermStyle? paneStyle;

  /// The style of [TermListTile], and [TermReorderableList]'s rows, under each one's own `style:`. Reads fill (selected, pressed), foreground, edge.
  final TermStyle? listTileStyle;

  /// The style of [TermSectionHeader], under each one's own `style:`. Reads foreground, edge (the rule).
  final TermStyle? sectionHeaderStyle;

  /// The style of [TermDisclosure], under each one's own `style:`. Reads foreground (the title), edge (the marker).
  final TermStyle? disclosureStyle;

  /// The style of [TermTable] and [TermDataTable], under each one's own `style:`. Reads fill (a selected row), foreground, edge (the rules).
  final TermStyle? tableStyle;

  /// The style of [TermTree], under each one's own `style:`. Reads fill (the keyboard's row), foreground, edge (the guides).
  final TermStyle? treeStyle;

  /// The style of [TermTimeline], under each one's own `style:`. Reads foreground, edge (the line and its marks).
  final TermStyle? timelineStyle;

  /// The style of [TermAvatar] and [TermAvatarGroup], under each one's own `style:`. Reads fill (the block), foreground (the initials).
  final TermStyle? avatarStyle;

  /// The style of [TermDivider], under each one's own `style:`. Reads edge (the rule), foreground (its label).
  final TermStyle? dividerStyle;

  /// The style of [TermScrollArea]'s bar, under each one's own `style:`. Reads fill (the thumb), edge (the track).
  final TermStyle? scrollbarStyle;

  /// The style of [TermSplitView]'s divider, under each one's own `style:`. Reads edge (the rule), fill (the grip while held).
  final TermStyle? splitViewStyle;

  /// The style of [TermDescriptionList], under each one's own `style:`. Reads foreground (the values), edge (the leaders).
  final TermStyle? descriptionListStyle;

  /// The style of [TermEmptyState] and [TermStatusView], under each one's own `style:`. Reads foreground (the title), edge (the glyph).
  final TermStyle? emptyStateStyle;

  /// The style of [TermMedia], under each one's own `style:`. Reads fill (the shade before it loads), edge (the frame), foreground (the alt text).
  final TermStyle? mediaStyle;

  /// The style of every menu's rows: [TermSelect]'s, [TermSplitButton]'s, [TermCombobox]'s, [TermMenu]'s, [TermMenuBar]'s, [TermActionSheet]'s and [TermCommandPalette]'s, under each one's own `style:`. Reads fill (the lit row), foreground.
  final TermStyle? menuStyle;

  /// The style of [TermDialog] and [TermConfirmDialog], under each one's own `style:`. Reads fill (the ground), foreground (the title), edge (the box lines).
  final TermStyle? dialogStyle;

  /// The style of [TermSheet], [TermSideSheet] and [TermActionSheet], under each one's own `style:`. Reads fill, foreground, edge.
  final TermStyle? sheetStyle;

  /// The style of [TermPopover] and [TermHoverCard], under each one's own `style:`. Reads fill, foreground, edge.
  final TermStyle? popoverStyle;

  /// The style of [TermTooltip], under each one's own `style:`. Reads fill (the ground), foreground.
  final TermStyle? tooltipStyle;

  /// The style of [TermToast], under each one's own `style:`. Reads fill, foreground, edge.
  final TermStyle? toastStyle;

  /// The style of [TermBanner], under each one's own `style:`. Reads fill (the ground), edge (the bar).
  final TermStyle? bannerStyle;

  /// The style of [TermProgressBar], under each one's own `style:`. Reads fill (the blocks), edge (the dots left).
  final TermStyle? progressStyle;

  /// The style of [TermSpinner], and [TermPullToRefresh]'s line, under each one's own `style:`. Reads foreground (the dots).
  final TermStyle? spinnerStyle;

  /// The style of [TermMeter], under each one's own `style:`. Reads fill (the blocks, over the tone), edge (the dots left).
  final TermStyle? meterStyle;

  /// The style of [TermSkeleton], under each one's own `style:`. Reads fill (the shade).
  final TermStyle? skeletonStyle;

  /// The style of [TermSparkline], [TermBarChart], [TermLineChart] and [TermAreaChart], under each one's own `style:`. Reads foreground (the marks), edge (the axes).
  final TermStyle? chartStyle;

  /// The base words: the [face], the size and the line of the grid, in
  /// [foreground]. Every style in Terminal is this one, changed only in
  /// weight and colour; [displayStyle] alone doubles it.
  TextStyle get textStyle => TextStyle(
    fontFamily: face.family,
    fontFamilyFallback: face.fallback,
    package: face.package,
    fontSize: grid.fontSize,
    height: grid.heightFactor,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: foreground,
    decoration: TextDecoration.none,
  );

  /// Bold words: titles, names, what a row is.
  TextStyle get boldStyle => textStyle.copyWith(fontWeight: FontWeight.w700);

  /// Dim words: secondary lines, times and counts.
  TextStyle get dimStyle => textStyle.copyWith(color: dim);

  /// A double-size line, as a VT100 draws one (DECDHL): twice as wide and
  /// twice as tall, so it still takes whole cells. For the one figure or
  /// title a screen leads with.
  TextStyle get displayStyle => textStyle.copyWith(
    fontSize: grid.fontSize * 2,
    fontWeight: FontWeight.w700,
  );

  /// This theme with the given fields changed.
  TermThemeData copyWith({
    Brightness? brightness,
    TermPalette? palette,
    Color? background,
    Color? surface,
    Color? foreground,
    Color? dim,
    Color? rule,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    TermGrid? grid,
    TermFace? face,
    TermStroke? stroke,
    TermStyle? buttonStyle,
    TermStyle? filledButtonStyle,
    TermStyle? destructiveButtonStyle,
    TermStyle? iconButtonStyle,
    TermStyle? linkStyle,
    TermStyle? toggleGroupStyle,
    TermStyle? splitButtonStyle,
    TermStyle? chipStyle,
    TermStyle? tagStyle,
    TermStyle? badgeStyle,
    TermStyle? keyStyle,
    TermStyle? textFieldStyle,
    TermStyle? selectStyle,
    TermStyle? checkboxStyle,
    TermStyle? radioStyle,
    TermStyle? switchStyle,
    TermStyle? sliderStyle,
    TermStyle? ratingStyle,
    TermStyle? otpFieldStyle,
    TermStyle? calendarStyle,
    TermStyle? colorPickerStyle,
    TermStyle? topBarStyle,
    TermStyle? tabBarStyle,
    TermStyle? navigationBarStyle,
    TermStyle? sideBarStyle,
    TermStyle? statusLineStyle,
    TermStyle? breadcrumbStyle,
    TermStyle? paginationStyle,
    TermStyle? stepsStyle,
    TermStyle? menuBarStyle,
    TermStyle? paneStyle,
    TermStyle? listTileStyle,
    TermStyle? sectionHeaderStyle,
    TermStyle? disclosureStyle,
    TermStyle? tableStyle,
    TermStyle? treeStyle,
    TermStyle? timelineStyle,
    TermStyle? avatarStyle,
    TermStyle? dividerStyle,
    TermStyle? scrollbarStyle,
    TermStyle? splitViewStyle,
    TermStyle? descriptionListStyle,
    TermStyle? emptyStateStyle,
    TermStyle? mediaStyle,
    TermStyle? menuStyle,
    TermStyle? dialogStyle,
    TermStyle? sheetStyle,
    TermStyle? popoverStyle,
    TermStyle? tooltipStyle,
    TermStyle? toastStyle,
    TermStyle? bannerStyle,
    TermStyle? progressStyle,
    TermStyle? spinnerStyle,
    TermStyle? meterStyle,
    TermStyle? skeletonStyle,
    TermStyle? chartStyle,
  }) => TermThemeData.raw(
    brightness: brightness ?? this.brightness,
    palette: palette ?? this.palette,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    foreground: foreground ?? this.foreground,
    dim: dim ?? this.dim,
    rule: rule ?? this.rule,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    success: success ?? this.success,
    danger: danger ?? this.danger,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    grid: grid ?? _grid,
    face: face ?? this.face,
    stroke: stroke ?? this.stroke,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    filledButtonStyle: filledButtonStyle ?? this.filledButtonStyle,
    destructiveButtonStyle:
        destructiveButtonStyle ?? this.destructiveButtonStyle,
    iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
    linkStyle: linkStyle ?? this.linkStyle,
    toggleGroupStyle: toggleGroupStyle ?? this.toggleGroupStyle,
    splitButtonStyle: splitButtonStyle ?? this.splitButtonStyle,
    chipStyle: chipStyle ?? this.chipStyle,
    tagStyle: tagStyle ?? this.tagStyle,
    badgeStyle: badgeStyle ?? this.badgeStyle,
    keyStyle: keyStyle ?? this.keyStyle,
    textFieldStyle: textFieldStyle ?? this.textFieldStyle,
    selectStyle: selectStyle ?? this.selectStyle,
    checkboxStyle: checkboxStyle ?? this.checkboxStyle,
    radioStyle: radioStyle ?? this.radioStyle,
    switchStyle: switchStyle ?? this.switchStyle,
    sliderStyle: sliderStyle ?? this.sliderStyle,
    ratingStyle: ratingStyle ?? this.ratingStyle,
    otpFieldStyle: otpFieldStyle ?? this.otpFieldStyle,
    calendarStyle: calendarStyle ?? this.calendarStyle,
    colorPickerStyle: colorPickerStyle ?? this.colorPickerStyle,
    topBarStyle: topBarStyle ?? this.topBarStyle,
    tabBarStyle: tabBarStyle ?? this.tabBarStyle,
    navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
    sideBarStyle: sideBarStyle ?? this.sideBarStyle,
    statusLineStyle: statusLineStyle ?? this.statusLineStyle,
    breadcrumbStyle: breadcrumbStyle ?? this.breadcrumbStyle,
    paginationStyle: paginationStyle ?? this.paginationStyle,
    stepsStyle: stepsStyle ?? this.stepsStyle,
    menuBarStyle: menuBarStyle ?? this.menuBarStyle,
    paneStyle: paneStyle ?? this.paneStyle,
    listTileStyle: listTileStyle ?? this.listTileStyle,
    sectionHeaderStyle: sectionHeaderStyle ?? this.sectionHeaderStyle,
    disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    tableStyle: tableStyle ?? this.tableStyle,
    treeStyle: treeStyle ?? this.treeStyle,
    timelineStyle: timelineStyle ?? this.timelineStyle,
    avatarStyle: avatarStyle ?? this.avatarStyle,
    dividerStyle: dividerStyle ?? this.dividerStyle,
    scrollbarStyle: scrollbarStyle ?? this.scrollbarStyle,
    splitViewStyle: splitViewStyle ?? this.splitViewStyle,
    descriptionListStyle: descriptionListStyle ?? this.descriptionListStyle,
    emptyStateStyle: emptyStateStyle ?? this.emptyStateStyle,
    mediaStyle: mediaStyle ?? this.mediaStyle,
    menuStyle: menuStyle ?? this.menuStyle,
    dialogStyle: dialogStyle ?? this.dialogStyle,
    sheetStyle: sheetStyle ?? this.sheetStyle,
    popoverStyle: popoverStyle ?? this.popoverStyle,
    tooltipStyle: tooltipStyle ?? this.tooltipStyle,
    toastStyle: toastStyle ?? this.toastStyle,
    bannerStyle: bannerStyle ?? this.bannerStyle,
    progressStyle: progressStyle ?? this.progressStyle,
    spinnerStyle: spinnerStyle ?? this.spinnerStyle,
    meterStyle: meterStyle ?? this.meterStyle,
    skeletonStyle: skeletonStyle ?? this.skeletonStyle,
    chartStyle: chartStyle ?? this.chartStyle,
  );

  /// The theme [t] of the way from [a] to [b]: colours blend, the grid
  /// moves, the brightness, the face and the stroke change half way, the
  /// part styles blend slot by slot.
  static TermThemeData lerp(TermThemeData a, TermThemeData b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    TermStyle? s(TermStyle? x, TermStyle? y) => TermStyle.lerp(x, y, t);
    return TermThemeData.raw(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      palette: TermPalette.lerp(a.palette, b.palette, t),
      background: c(a.background, b.background),
      surface: c(a.surface, b.surface),
      foreground: c(a.foreground, b.foreground),
      dim: c(a.dim, b.dim),
      rule: c(a.rule, b.rule),
      accent: c(a.accent, b.accent),
      onAccent: c(a.onAccent, b.onAccent),
      success: c(a.success, b.success),
      danger: c(a.danger, b.danger),
      warning: c(a.warning, b.warning),
      info: c(a.info, b.info),
      grid: TermGrid.lerp(a._grid, b._grid, t),
      face: t < 0.5 ? a.face : b.face,
      stroke: t < 0.5 ? a.stroke : b.stroke,
      buttonStyle: s(a.buttonStyle, b.buttonStyle),
      filledButtonStyle: s(a.filledButtonStyle, b.filledButtonStyle),
      destructiveButtonStyle: s(
        a.destructiveButtonStyle,
        b.destructiveButtonStyle,
      ),
      iconButtonStyle: s(a.iconButtonStyle, b.iconButtonStyle),
      linkStyle: s(a.linkStyle, b.linkStyle),
      toggleGroupStyle: s(a.toggleGroupStyle, b.toggleGroupStyle),
      splitButtonStyle: s(a.splitButtonStyle, b.splitButtonStyle),
      chipStyle: s(a.chipStyle, b.chipStyle),
      tagStyle: s(a.tagStyle, b.tagStyle),
      badgeStyle: s(a.badgeStyle, b.badgeStyle),
      keyStyle: s(a.keyStyle, b.keyStyle),
      textFieldStyle: s(a.textFieldStyle, b.textFieldStyle),
      selectStyle: s(a.selectStyle, b.selectStyle),
      checkboxStyle: s(a.checkboxStyle, b.checkboxStyle),
      radioStyle: s(a.radioStyle, b.radioStyle),
      switchStyle: s(a.switchStyle, b.switchStyle),
      sliderStyle: s(a.sliderStyle, b.sliderStyle),
      ratingStyle: s(a.ratingStyle, b.ratingStyle),
      otpFieldStyle: s(a.otpFieldStyle, b.otpFieldStyle),
      calendarStyle: s(a.calendarStyle, b.calendarStyle),
      colorPickerStyle: s(a.colorPickerStyle, b.colorPickerStyle),
      topBarStyle: s(a.topBarStyle, b.topBarStyle),
      tabBarStyle: s(a.tabBarStyle, b.tabBarStyle),
      navigationBarStyle: s(a.navigationBarStyle, b.navigationBarStyle),
      sideBarStyle: s(a.sideBarStyle, b.sideBarStyle),
      statusLineStyle: s(a.statusLineStyle, b.statusLineStyle),
      breadcrumbStyle: s(a.breadcrumbStyle, b.breadcrumbStyle),
      paginationStyle: s(a.paginationStyle, b.paginationStyle),
      stepsStyle: s(a.stepsStyle, b.stepsStyle),
      menuBarStyle: s(a.menuBarStyle, b.menuBarStyle),
      paneStyle: s(a.paneStyle, b.paneStyle),
      listTileStyle: s(a.listTileStyle, b.listTileStyle),
      sectionHeaderStyle: s(a.sectionHeaderStyle, b.sectionHeaderStyle),
      disclosureStyle: s(a.disclosureStyle, b.disclosureStyle),
      tableStyle: s(a.tableStyle, b.tableStyle),
      treeStyle: s(a.treeStyle, b.treeStyle),
      timelineStyle: s(a.timelineStyle, b.timelineStyle),
      avatarStyle: s(a.avatarStyle, b.avatarStyle),
      dividerStyle: s(a.dividerStyle, b.dividerStyle),
      scrollbarStyle: s(a.scrollbarStyle, b.scrollbarStyle),
      splitViewStyle: s(a.splitViewStyle, b.splitViewStyle),
      descriptionListStyle: s(a.descriptionListStyle, b.descriptionListStyle),
      emptyStateStyle: s(a.emptyStateStyle, b.emptyStateStyle),
      mediaStyle: s(a.mediaStyle, b.mediaStyle),
      menuStyle: s(a.menuStyle, b.menuStyle),
      dialogStyle: s(a.dialogStyle, b.dialogStyle),
      sheetStyle: s(a.sheetStyle, b.sheetStyle),
      popoverStyle: s(a.popoverStyle, b.popoverStyle),
      tooltipStyle: s(a.tooltipStyle, b.tooltipStyle),
      toastStyle: s(a.toastStyle, b.toastStyle),
      bannerStyle: s(a.bannerStyle, b.bannerStyle),
      progressStyle: s(a.progressStyle, b.progressStyle),
      spinnerStyle: s(a.spinnerStyle, b.spinnerStyle),
      meterStyle: s(a.meterStyle, b.meterStyle),
      skeletonStyle: s(a.skeletonStyle, b.skeletonStyle),
      chartStyle: s(a.chartStyle, b.chartStyle),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TermThemeData &&
      other.brightness == brightness &&
      other.palette == palette &&
      other.background == background &&
      other.surface == surface &&
      other.foreground == foreground &&
      other.dim == dim &&
      other.rule == rule &&
      other.accent == accent &&
      other.onAccent == onAccent &&
      other.success == success &&
      other.danger == danger &&
      other.warning == warning &&
      other.info == info &&
      other._grid == _grid &&
      other.face == face &&
      other.stroke == stroke &&
      other.buttonStyle == buttonStyle &&
      other.filledButtonStyle == filledButtonStyle &&
      other.destructiveButtonStyle == destructiveButtonStyle &&
      other.iconButtonStyle == iconButtonStyle &&
      other.linkStyle == linkStyle &&
      other.toggleGroupStyle == toggleGroupStyle &&
      other.splitButtonStyle == splitButtonStyle &&
      other.chipStyle == chipStyle &&
      other.tagStyle == tagStyle &&
      other.badgeStyle == badgeStyle &&
      other.keyStyle == keyStyle &&
      other.textFieldStyle == textFieldStyle &&
      other.selectStyle == selectStyle &&
      other.checkboxStyle == checkboxStyle &&
      other.radioStyle == radioStyle &&
      other.switchStyle == switchStyle &&
      other.sliderStyle == sliderStyle &&
      other.ratingStyle == ratingStyle &&
      other.otpFieldStyle == otpFieldStyle &&
      other.calendarStyle == calendarStyle &&
      other.colorPickerStyle == colorPickerStyle &&
      other.topBarStyle == topBarStyle &&
      other.tabBarStyle == tabBarStyle &&
      other.navigationBarStyle == navigationBarStyle &&
      other.sideBarStyle == sideBarStyle &&
      other.statusLineStyle == statusLineStyle &&
      other.breadcrumbStyle == breadcrumbStyle &&
      other.paginationStyle == paginationStyle &&
      other.stepsStyle == stepsStyle &&
      other.menuBarStyle == menuBarStyle &&
      other.paneStyle == paneStyle &&
      other.listTileStyle == listTileStyle &&
      other.sectionHeaderStyle == sectionHeaderStyle &&
      other.disclosureStyle == disclosureStyle &&
      other.tableStyle == tableStyle &&
      other.treeStyle == treeStyle &&
      other.timelineStyle == timelineStyle &&
      other.avatarStyle == avatarStyle &&
      other.dividerStyle == dividerStyle &&
      other.scrollbarStyle == scrollbarStyle &&
      other.splitViewStyle == splitViewStyle &&
      other.descriptionListStyle == descriptionListStyle &&
      other.emptyStateStyle == emptyStateStyle &&
      other.mediaStyle == mediaStyle &&
      other.menuStyle == menuStyle &&
      other.dialogStyle == dialogStyle &&
      other.sheetStyle == sheetStyle &&
      other.popoverStyle == popoverStyle &&
      other.tooltipStyle == tooltipStyle &&
      other.toastStyle == toastStyle &&
      other.bannerStyle == bannerStyle &&
      other.progressStyle == progressStyle &&
      other.spinnerStyle == spinnerStyle &&
      other.meterStyle == meterStyle &&
      other.skeletonStyle == skeletonStyle &&
      other.chartStyle == chartStyle;

  @override
  int get hashCode => Object.hashAll([
    brightness,
    palette,
    background,
    surface,
    foreground,
    dim,
    rule,
    accent,
    onAccent,
    success,
    danger,
    warning,
    info,
    _grid,
    face,
    stroke,
    buttonStyle,
    filledButtonStyle,
    destructiveButtonStyle,
    iconButtonStyle,
    linkStyle,
    toggleGroupStyle,
    splitButtonStyle,
    chipStyle,
    tagStyle,
    badgeStyle,
    keyStyle,
    textFieldStyle,
    selectStyle,
    checkboxStyle,
    radioStyle,
    switchStyle,
    sliderStyle,
    ratingStyle,
    otpFieldStyle,
    calendarStyle,
    colorPickerStyle,
    topBarStyle,
    tabBarStyle,
    navigationBarStyle,
    sideBarStyle,
    statusLineStyle,
    breadcrumbStyle,
    paginationStyle,
    stepsStyle,
    menuBarStyle,
    paneStyle,
    listTileStyle,
    sectionHeaderStyle,
    disclosureStyle,
    tableStyle,
    treeStyle,
    timelineStyle,
    avatarStyle,
    dividerStyle,
    scrollbarStyle,
    splitViewStyle,
    descriptionListStyle,
    emptyStateStyle,
    mediaStyle,
    menuStyle,
    dialogStyle,
    sheetStyle,
    popoverStyle,
    tooltipStyle,
    toastStyle,
    bannerStyle,
    progressStyle,
    spinnerStyle,
    meterStyle,
    skeletonStyle,
    chartStyle,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(DiagnosticsProperty<TermPalette>('palette', palette))
      ..add(ColorProperty('background', background))
      ..add(ColorProperty('surface', surface))
      ..add(ColorProperty('foreground', foreground))
      ..add(ColorProperty('dim', dim))
      ..add(ColorProperty('rule', rule))
      ..add(ColorProperty('accent', accent))
      ..add(ColorProperty('onAccent', onAccent))
      ..add(ColorProperty('success', success))
      ..add(ColorProperty('danger', danger))
      ..add(ColorProperty('warning', warning))
      ..add(ColorProperty('info', info))
      ..add(DiagnosticsProperty<TermGrid>('grid', grid))
      ..add(
        DiagnosticsProperty<TermFace>(
          'face',
          face,
          defaultValue: TermFace.jetBrainsMono,
        ),
      )
      ..add(
        EnumProperty<TermStroke>(
          'stroke',
          stroke,
          defaultValue: TermStroke.light,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'buttonStyle',
          buttonStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'filledButtonStyle',
          filledButtonStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'destructiveButtonStyle',
          destructiveButtonStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'iconButtonStyle',
          iconButtonStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'linkStyle',
          linkStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'toggleGroupStyle',
          toggleGroupStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'splitButtonStyle',
          splitButtonStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'chipStyle',
          chipStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'tagStyle',
          tagStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'badgeStyle',
          badgeStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'keyStyle',
          keyStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'textFieldStyle',
          textFieldStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'selectStyle',
          selectStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'checkboxStyle',
          checkboxStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'radioStyle',
          radioStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'switchStyle',
          switchStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'sliderStyle',
          sliderStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'ratingStyle',
          ratingStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'otpFieldStyle',
          otpFieldStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'calendarStyle',
          calendarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'colorPickerStyle',
          colorPickerStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'topBarStyle',
          topBarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'tabBarStyle',
          tabBarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'navigationBarStyle',
          navigationBarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'sideBarStyle',
          sideBarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'statusLineStyle',
          statusLineStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'breadcrumbStyle',
          breadcrumbStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'paginationStyle',
          paginationStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'stepsStyle',
          stepsStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'menuBarStyle',
          menuBarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'paneStyle',
          paneStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'listTileStyle',
          listTileStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'sectionHeaderStyle',
          sectionHeaderStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'disclosureStyle',
          disclosureStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'tableStyle',
          tableStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'treeStyle',
          treeStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'timelineStyle',
          timelineStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'avatarStyle',
          avatarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'dividerStyle',
          dividerStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'scrollbarStyle',
          scrollbarStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'splitViewStyle',
          splitViewStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'descriptionListStyle',
          descriptionListStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'emptyStateStyle',
          emptyStateStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'mediaStyle',
          mediaStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'menuStyle',
          menuStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'dialogStyle',
          dialogStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'sheetStyle',
          sheetStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'popoverStyle',
          popoverStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'tooltipStyle',
          tooltipStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'toastStyle',
          toastStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'bannerStyle',
          bannerStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'progressStyle',
          progressStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'spinnerStyle',
          spinnerStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'meterStyle',
          meterStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'skeletonStyle',
          skeletonStyle,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<TermStyle>(
          'chartStyle',
          chartStyle,
          defaultValue: null,
        ),
      );
  }
}

/// Terminal's motion: springs for what eases (a press, a frame doubling as
/// it takes focus, a switch's thumb), steps for what ticks (the caret's
/// blink, the spinner's frames), and for structure, no travel at all: a
/// screen changes in a cut or a very short fade, and a menu opens where it
/// stays, under its field.
abstract final class TermMotion {
  /// A press filling in and letting go: quick, no bounce.
  static const ({double dampingRatio, double stiffness}) press = (
    dampingRatio: 1,
    stiffness: 1600,
  );

  /// A frame's line doubling as it takes focus, a thumb or an indicator
  /// moving between cells: a short glide that settles without a bounce.
  static const ({double dampingRatio, double stiffness}) move = (
    dampingRatio: 0.9,
    stiffness: 700,
  );

  /// A menu opening under its field: a short reveal from its top line, the
  /// menu already where it stays; no bounce.
  static const ({double dampingRatio, double stiffness}) reveal = (
    dampingRatio: 1,
    stiffness: 1600,
  );

  /// A screen, a dialog or a toast coming up: a very short fade in place.
  static const Duration screen = Duration(milliseconds: 120);

  /// A dialog, a sheet or a side sheet coming up and going, on ui_core's
  /// route spring: critically damped, it settles in about [screen]'s 120 ms
  /// (to within `rawSpringTolerance`), a very short fade in place.
  static const ({double dampingRatio, double stiffness}) surface = (
    dampingRatio: 1,
    stiffness: 5900,
  );

  /// Half the caret's blink: on for this long, then off for as long, as a
  /// terminal's cursor does.
  static const Duration caretHalfPeriod = Duration(milliseconds: 530);

  /// One frame of the braille spinner.
  static const Duration spinnerFrame = Duration(milliseconds: 80);
}

class _TermScope extends InheritedTheme {
  const _TermScope({required this.data, required super.child});

  final TermThemeData data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _TermScope(data: data, child: child);

  @override
  bool updateShouldNotify(_TermScope oldWidget) => oldWidget.data != data;
}

/// Puts Terminal's look over [child]: its theme, the grid grown by the
/// reader's text scale, its tap floors (two lines for a finger, one for a
/// pointer), its words' default style, and the Material theme under its
/// text fields pinned so no platform density moves them.
///
/// Put it in an app's `builder:`, so routes and overlays stand inside it.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) =>
///       TermTheme(data: TermThemeData.dark(), child: child!),
///   home: const Home(),
/// )
/// ```
class TermTheme extends StatelessWidget {
  /// Terminal's look, [data], over [child].
  const TermTheme({super.key, required this.data, required this.child});

  /// The theme.
  final TermThemeData data;

  /// What wears it.
  final Widget child;

  static final TermThemeData _fallbackDark = TermThemeData.dark();

  /// The theme in force at [context]; Terminal's dark preset when no
  /// [TermTheme] is above, as `Theme.of` gives Material's default.
  static TermThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallbackDark;

  /// The theme in force at [context], or null when no [TermTheme] is above.
  static TermThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TermScope>()?.data;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final base = data.grid.fontSize;
    // The reader's text scale at the one size Terminal sets, applied to
    // everything below as one factor, so a word, its cell and its line
    // grow together and the lattice holds.
    final factor = media == null ? 1.0 : media.textScaler.scale(base) / base;
    final dark = data.brightness == Brightness.dark;
    final words = data.textStyle;
    // The app's own Material theme, changed only where Terminal must be:
    // its colours, its words on the grid, no ink, Terminal's screen change.
    // Its other component themes stand.
    final ambient = Theme.of(context);
    final material = ambient.copyWith(
      brightness: data.brightness,
      colorScheme: (dark ? const ColorScheme.dark() : const ColorScheme.light())
          .copyWith(
            primary: data.accent,
            onPrimary: data.onAccent,
            secondary: data.accent,
            onSecondary: data.onAccent,
            error: data.danger,
            onError: data.background,
            surface: data.background,
            onSurface: data.foreground,
          ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: NoSplash.splashFactory,
      hoverColor: const Color(0x00000000),
      focusColor: const Color(0x00000000),
      highlightColor: const Color(0x00000000),
      splashColor: const Color(0x00000000),
      scaffoldBackgroundColor: data.background,
      // A route pushed from under it changes screens as a terminal does: a
      // cut, then the new screen faded up in place.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: termPageTransitions,
      ),
      canvasColor: data.background,
      // Every Material text slot is the grid's words, so a Material surface
      // inside (a text field's, a route's) keeps the face and the cell.
      textTheme: TextTheme(
        displayLarge: words,
        displayMedium: words,
        displaySmall: words,
        headlineLarge: words,
        headlineMedium: words,
        headlineSmall: words,
        titleLarge: words,
        titleMedium: words,
        titleSmall: words,
        bodyLarge: words,
        bodyMedium: words,
        bodySmall: words,
        labelLarge: words,
        labelMedium: words,
        labelSmall: words,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: data.accent,
        selectionColor: data.accent.withValues(alpha: 0.35),
        selectionHandleColor: data.accent,
      ),
    );
    Widget under = child;
    // The text field underneath is Material's: under an app that gives no
    // Material words (a WidgetsApp, or Material from another library), it
    // takes English ones.
    if (Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null) {
      // Localizations sets the direction from the locale; the direction
      // the app gave (an explicit Directionality) stands under it again.
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    Widget result = _TermScope(
      data: data,
      child: Theme(
        data: material,
        child: RawTapTargetScope(
          targets: RawTapTargets(
            touch: Size.square(data.grid.lines(2)),
            pointer: Size.square(data.grid.lines(1)),
          ),
          child: RawSpacingScope(
            spacing: const RawSpacing(grid: 3),
            child: DefaultTextStyle(
              style: data.textStyle,
              child: DefaultSelectionStyle(
                cursorColor: data.accent,
                selectionColor: data.accent.withValues(alpha: 0.35),
                child: under,
              ),
            ),
          ),
        ),
      ),
    );
    if (media != null && factor != 1) {
      result = MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(factor)),
        child: result,
      );
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TermThemeData>('data', data));
  }
}

/// A [TermTheme] that blends to a new [data] over [duration] (a preset
/// switch, light to dark), as Material's `AnimatedTheme` does. The face and
/// the stroke change half way; under Reduce Motion it cuts.
///
/// ```dart
/// AnimatedTermTheme(
///   data: dark ? TermThemeData.dark() : TermThemeData.light(),
///   child: child,
/// )
/// ```
class AnimatedTermTheme extends ImplicitlyAnimatedWidget {
  /// [data] over [child], blended from the last one.
  const AnimatedTermTheme({
    super.key,
    required this.data,
    required this.child,
    super.duration = const Duration(milliseconds: 200),
    super.curve = Curves.linear,
    super.onEnd,
  });

  /// The theme it blends to.
  final TermThemeData data;

  /// What wears it.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedTermTheme> createState() =>
      _AnimatedTermThemeState();
}

class _AnimatedTermThemeState
    extends AnimatedWidgetBaseState<AnimatedTermTheme> {
  _TermThemeTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => _TermThemeTween(begin: value as TermThemeData),
    ) as _TermThemeTween?;
  }

  @override
  Widget build(BuildContext context) {
    final still = RawMotionPolicy.of(context).reduceMotion;
    return TermTheme(
      data: still ? widget.data : _data!.evaluate(animation),
      child: widget.child,
    );
  }
}

class _TermThemeTween extends Tween<TermThemeData> {
  _TermThemeTween({super.begin});

  @override
  TermThemeData lerp(double t) => TermThemeData.lerp(begin!, end!, t);
}

/// The theme and the grid at a [BuildContext].
extension TermGridContext on BuildContext {
  /// The theme in force ([TermTheme.of]).
  TermThemeData get termTheme => TermTheme.of(this);

  /// The cell grid in force: the theme's, grown by the reader's text scale.
  TermGrid get termGrid => TermGrid.of(this, TermTheme.of(this).grid);

  /// The motion policy in force (Reduce Motion critically damps every
  /// spring and stops what blinks).
  RawMotionPolicy get termMotion => RawMotionPolicy.of(this);
}

/// Lays [child] out [cols] cells wide and [lines] lines tall on the grid in
/// force; either left null takes the child's own size.
///
/// ```dart
/// const TermCells(cols: 20, lines: 1, child: Text('ready'));
/// ```
class TermCells extends StatelessWidget {
  /// A box of whole cells round [child].
  const TermCells({super.key, this.cols, this.lines, this.child});

  /// The width in cells, or null for the child's.
  final num? cols;

  /// The height in lines, or null for the child's.
  final num? lines;

  /// What stands in the cells.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return SizedBox(
      width: cols == null ? null : grid.cols(cols!),
      height: lines == null ? null : grid.lines(lines!),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<num>('cols', cols, defaultValue: null))
      ..add(DiagnosticsProperty<num>('lines', lines, defaultValue: null));
  }
}
