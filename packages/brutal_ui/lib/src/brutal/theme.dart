/// Brutal's theme: its colours, its type, its one rule and one shadow, its
/// density, and the [BrutalTheme] every app installs once in its `builder:`.
library;

import 'package:flutter/foundation.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'app.dart' show brutalPageTransitions;
import 'fonts.dart';

/// How one part of Brutal looks, as Material's `ButtonStyle` is: every slot a
/// `WidgetStateProperty`, read from a part's `style:` first, then from its
/// component theme on [BrutalThemeData], then from the look's own default.
///
/// ```dart
/// final wide = BrutalStyle(padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)));
/// ```
typedef BrutalStyle = RawStyle;

/// How tight Brutal's controls stand: [RawDensity.standard] (a 48 px
/// control), [RawDensity.comfortable] (44) or [RawDensity.compact] (40).
/// A control's tap target stays at the floor for the input whatever the
/// density.
typedef BrutalDensity = RawDensity;

/// The look's measures: one rule and one shadow, the same on every part.
///
/// The rule's weight and the shadow's reach are the two a theme may move
/// ([BrutalThemeData.borderWidth], [BrutalThemeData.shadowOffset]), within
/// the bounds here, where every value is still one heavy rule and one hard
/// shadow. The rest are not settings: square boxes are what Brutal is.
abstract final class BrutalMetrics {
  /// The width of every rule by default: a control's border, a cell's
  /// divider, a table's grid line. [BrutalThemeData.borderWidth] is the one
  /// parts read.
  static const double borderWidth = 2;

  /// The lightest rule a theme may draw: lighter is a hairline, not Brutal.
  static const double minBorderWidth = 2;

  /// The heaviest rule a theme may draw: heavier crowds a 40 px control.
  static const double maxBorderWidth = 4;

  /// How far the hard shadow stands from its face by default, down and
  /// toward the end side (right in left-to-right text), and how far a press
  /// moves the face. [BrutalThemeData.shadowOffset] is the one parts read.
  static const double shadowOffset = 4;

  /// The shortest shadow a theme may cast: shorter stops reading as one.
  static const double minShadowOffset = 2;

  /// The longest shadow a theme may cast: longer pulls a face off its row.
  static const double maxShadowOffset = 8;

  /// The inset of a focus bar in a cell with shared dividers.
  static const double focusGap = 2;

  /// The thickness of a focus bar.
  static const double focusWidth = 2;

  /// A control's height at [RawDensity.standard], before density.
  static const double controlHeight = 48;

  /// The widest a form, a dialog or a reading column stands.
  static const double readingWidth = 560;
}

/// Brutal's spacing, on a 4 px grid ([RawSpacingScope] declares it).
abstract final class BrutalSpacing {
  /// The grid every gap, inset and offset stands on.
  static const double grid = 4;

  /// Inside a control: an icon and its words.
  static const double tight = 4;

  /// Between a label and its field, between lines of one item.
  static const double small = 8;

  /// Inside a cell: the room round a tag, a short gap in a row.
  static const double medium = 12;

  /// A block's and a row's inset, and the page margin on a phone.
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

/// Brutal's motion: springs only, all critically damped, so nothing
/// overshoots or bounces. Run them through `RawMotionPolicy`, which honours
/// Reduce Motion.
abstract final class BrutalMotion {
  /// Every spring's damping ratio: 1, so a face stops dead where it goes.
  static const double dampingRatio = 1;

  /// A press and its release: the face sliding into its shadow and back.
  static const double pressStiffness = 3000;

  /// A fill, a rule or a word changing colour.
  static const double colorStiffness = 1200;

  /// A thumb, an indicator or a check moving across its control.
  static const double moveStiffness = 900;

  /// A dialog, a sheet, a menu or a toast arriving or leaving.
  static const double overlayStiffness = 700;
}

/// Brutal's colours, by role.
///
/// [ink] draws every rule, every shadow and every word, and fills a chosen
/// thing; [paper] is the page. One [signal] marks the main action. The four
/// block colours ([lime], [blue], [pink], [violet]) are spent one per screen
/// on its lead block, to say which part of an app it is; words on them are
/// [onBlock].
@immutable
class BrutalColors with Diagnosticable {
  /// Colours given one by one; [BrutalColors.light] and [BrutalColors.dark]
  /// are the look's own.
  const BrutalColors({
    required this.brightness,
    required this.paper,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.disabled,
    required this.signal,
    required this.onSignal,
    required this.danger,
    required this.onDanger,
    required this.lime,
    required this.blue,
    required this.pink,
    required this.violet,
    required this.onBlock,
    required this.scrim,
  });

  /// The look by day: a white page, black rules and shadows.
  const BrutalColors.light()
    : brightness = Brightness.light,
      paper = const Color(0xFFFFFFFF),
      surface = const Color(0xFFFFFFFF),
      ink = const Color(0xFF000000),
      inkMuted = const Color(0xFF4D4D4D),
      disabled = const Color(0xFF737373),
      signal = const Color(0xFFFF6A13),
      onSignal = const Color(0xFF000000),
      danger = const Color(0xFFD7000F),
      onDanger = const Color(0xFFFFFFFF),
      lime = const Color(0xFFB8F229),
      blue = const Color(0xFF5C8DFF),
      pink = const Color(0xFFFF85C8),
      violet = const Color(0xFFA68BFF),
      onBlock = const Color(0xFF000000),
      scrim = const Color(0x80000000);

  /// The look by night: a near-black page, white rules and shadows, and the
  /// blocks still saturated, with black words on them.
  const BrutalColors.dark()
    : brightness = Brightness.dark,
      paper = const Color(0xFF121212),
      surface = const Color(0xFF1E1E1E),
      ink = const Color(0xFFF2F2F2),
      inkMuted = const Color(0xFFB3B3B3),
      disabled = const Color(0xFF888888),
      signal = const Color(0xFFFF7A2E),
      onSignal = const Color(0xFF000000),
      danger = const Color(0xFFFF5A5F),
      onDanger = const Color(0xFF000000),
      lime = const Color(0xFFB8F229),
      blue = const Color(0xFF6E9BFF),
      pink = const Color(0xFFFF85C8),
      violet = const Color(0xFFAE96FF),
      onBlock = const Color(0xFF000000),
      scrim = const Color(0xB3000000);

  /// Whether these are colours by day or by night.
  final Brightness brightness;

  /// The page.
  final Color paper;

  /// A face: a button's, a field's, a block's without a colour. By night a
  /// step lighter than [paper].
  final Color surface;

  /// Rules, shadows, words, and the fill of a chosen thing.
  final Color ink;

  /// Supporting words: a row's second line, a field's help.
  final Color inkMuted;

  /// The rule and words of a control that is off.
  final Color disabled;

  /// The main action's face.
  final Color signal;

  /// Words and icons on [signal].
  final Color onSignal;

  /// A destructive action's colour, and an error's.
  final Color danger;

  /// Words and icons on [danger].
  final Color onDanger;

  /// A block colour: lime.
  final Color lime;

  /// A block colour: blue.
  final Color blue;

  /// A block colour: pink.
  final Color pink;

  /// A block colour: violet.
  final Color violet;

  /// Words and icons on a block colour.
  final Color onBlock;

  /// What a dialog or a sheet lays over the page.
  final Color scrim;

  /// The words on [fill]: [paper] on [ink], [onSignal] on [signal], and so
  /// on; [ink] on anything else.
  Color onColor(Color fill) {
    if (fill == ink) return paper;
    if (fill == signal) return onSignal;
    if (fill == danger) return onDanger;
    if (fill == lime || fill == blue || fill == pink || fill == violet) {
      return onBlock;
    }
    return wordsOn(fill);
  }

  /// Black or white, whichever reads better on [fill]: the words an
  /// off-palette fill takes.
  static Color wordsOn(Color fill) =>
      RawPalette.contrastRatio(const Color(0xFF000000), fill) >=
          RawPalette.contrastRatio(const Color(0xFFFFFFFF), fill)
      ? const Color(0xFF000000)
      : const Color(0xFFFFFFFF);

  /// A copy with the given colours replaced.
  BrutalColors copyWith({
    Brightness? brightness,
    Color? paper,
    Color? surface,
    Color? ink,
    Color? inkMuted,
    Color? disabled,
    Color? signal,
    Color? onSignal,
    Color? danger,
    Color? onDanger,
    Color? lime,
    Color? blue,
    Color? pink,
    Color? violet,
    Color? onBlock,
    Color? scrim,
  }) => BrutalColors(
    brightness: brightness ?? this.brightness,
    paper: paper ?? this.paper,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    disabled: disabled ?? this.disabled,
    signal: signal ?? this.signal,
    onSignal: onSignal ?? this.onSignal,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    lime: lime ?? this.lime,
    blue: blue ?? this.blue,
    pink: pink ?? this.pink,
    violet: violet ?? this.violet,
    onBlock: onBlock ?? this.onBlock,
    scrim: scrim ?? this.scrim,
  );

  /// Between [a] and [b] at [t].
  static BrutalColors lerp(BrutalColors a, BrutalColors b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return BrutalColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      paper: c(a.paper, b.paper),
      surface: c(a.surface, b.surface),
      ink: c(a.ink, b.ink),
      inkMuted: c(a.inkMuted, b.inkMuted),
      disabled: c(a.disabled, b.disabled),
      signal: c(a.signal, b.signal),
      onSignal: c(a.onSignal, b.onSignal),
      danger: c(a.danger, b.danger),
      onDanger: c(a.onDanger, b.onDanger),
      lime: c(a.lime, b.lime),
      blue: c(a.blue, b.blue),
      pink: c(a.pink, b.pink),
      violet: c(a.violet, b.violet),
      onBlock: c(a.onBlock, b.onBlock),
      scrim: c(a.scrim, b.scrim),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BrutalColors &&
      other.brightness == brightness &&
      other.paper == paper &&
      other.surface == surface &&
      other.ink == ink &&
      other.inkMuted == inkMuted &&
      other.disabled == disabled &&
      other.signal == signal &&
      other.onSignal == onSignal &&
      other.danger == danger &&
      other.onDanger == onDanger &&
      other.lime == lime &&
      other.blue == blue &&
      other.pink == pink &&
      other.violet == violet &&
      other.onBlock == onBlock &&
      other.scrim == scrim;

  @override
  int get hashCode => Object.hash(
    brightness,
    paper,
    surface,
    ink,
    inkMuted,
    disabled,
    signal,
    onSignal,
    danger,
    onDanger,
    lime,
    blue,
    pink,
    violet,
    onBlock,
    scrim,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(ColorProperty('paper', paper))
      ..add(ColorProperty('surface', surface))
      ..add(ColorProperty('ink', ink))
      ..add(ColorProperty('inkMuted', inkMuted))
      ..add(ColorProperty('disabled', disabled))
      ..add(ColorProperty('signal', signal))
      ..add(ColorProperty('onSignal', onSignal))
      ..add(ColorProperty('danger', danger))
      ..add(ColorProperty('onDanger', onDanger))
      ..add(ColorProperty('lime', lime))
      ..add(ColorProperty('blue', blue))
      ..add(ColorProperty('pink', pink))
      ..add(ColorProperty('violet', violet))
      ..add(ColorProperty('onBlock', onBlock))
      ..add(ColorProperty('scrim', scrim));
  }
}

/// The face Brutal sets every word in. Space Grotesk by default; any heavy
/// grotesk with a 700 weight still reads as Brutal (a serif, a script or a
/// rounded face does not, and is the app's call to own).
///
/// [capHeightFactor] is the face's capital height over its size (its OS/2
/// cap height over its units per em): what a label is centred by.
///
/// ```dart
/// BrutalThemeData.from(signal: const Color(0xFF0A7D4F), typeface: const BrutalTypeface(family: 'Archivo', capHeightFactor: 0.72))
/// ```
@immutable
class BrutalTypeface with Diagnosticable {
  /// A face registered as [family] (from [package] when a package bundles
  /// it).
  const BrutalTypeface({
    required this.family,
    this.package,
    this.capHeightFactor = 0.7,
    this.fallback = const [],
  }) : assert(
         capHeightFactor > 0.5 && capHeightFactor < 0.85,
         'A grotesk\'s capitals stand 0.5 to 0.85 of its size.',
       );

  /// The look's own face: Space Grotesk, bundled.
  static const BrutalTypeface spaceGrotesk = BrutalTypeface(
    family: brutalFontFamily,
    package: brutalFontPackage,
    capHeightFactor: brutalCapHeightFactor,
  );

  /// The family name the face is registered under.
  final String family;

  /// The package that bundles it, or null when the app does.
  final String? package;

  /// The face's capitals as a fraction of its size.
  final double capHeightFactor;

  /// Faces to fall back on for a glyph it lacks, by the names they are
  /// registered under: an app's own as it names them, a package's as
  /// `packages/<package>/<family>`. They are not read as faces of
  /// [package].
  final List<String> fallback;

  @override
  bool operator ==(Object other) =>
      other is BrutalTypeface &&
      other.family == family &&
      other.package == package &&
      other.capHeightFactor == capHeightFactor &&
      listEquals(other.fallback, fallback);

  @override
  int get hashCode =>
      Object.hash(family, package, capHeightFactor, Object.hashAll(fallback));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('family', family))
      ..add(StringProperty('package', package, defaultValue: null))
      ..add(DoubleProperty('capHeightFactor', capHeightFactor))
      ..add(IterableProperty<String>('fallback', fallback, ifEmpty: '[]'));
  }
}

/// Where the hard shadow stands from its face in [direction], [by] px: down,
/// and right in left-to-right text, left in right-to-left.
Offset brutalTravelOffset(
  TextDirection direction, [
  double by = BrutalMetrics.shadowOffset,
]) => Offset(direction == TextDirection.rtl ? -by : by, by);

/// Brutal's type: one grotesk, seven styles. A screen uses at most four.
@immutable
class BrutalTextTheme with Diagnosticable {
  /// Styles given one by one; [BrutalTextTheme.from] builds the look's own.
  const BrutalTextTheme({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.secondary,
    required this.caption,
  });

  /// The look's styles in [typeface], coloured for [colors].
  factory BrutalTextTheme.from(
    BrutalColors colors, {
    BrutalTypeface typeface = BrutalTypeface.spaceGrotesk,
  }) {
    TextStyle face(
      double size,
      double height,
      FontWeight weight, {
      double tracking = 0,
      Color? color,
    }) => TextStyle(
      fontFamily: _familyOf(typeface),
      fontFamilyFallback: typeface.fallback.isEmpty ? null : typeface.fallback,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: tracking,
      color: color ?? colors.ink,
      leadingDistribution: TextLeadingDistribution.even,
      decoration: TextDecoration.none,
    );
    return BrutalTextTheme(
      display: face(40, 44, FontWeight.w700, tracking: -1.2),
      headline: face(28, 32, FontWeight.w700, tracking: -0.6),
      title: face(20, 24, FontWeight.w700, tracking: -0.2),
      body: face(16, 24, FontWeight.w400),
      label: face(16, 20, FontWeight.w600),
      secondary: face(14, 20, FontWeight.w400, color: colors.inkMuted),
      caption: face(12, 16, FontWeight.w700, tracking: 0.8),
    );
  }

  /// A lead block's figure or headline: 40 px, bold, tight.
  final TextStyle display;

  /// A screen's title: 28 px, bold.
  final TextStyle headline;

  /// A block's, a dialog's or a group's title: 20 px, bold.
  final TextStyle title;

  /// What people read: 16 px.
  final TextStyle body;

  /// A control's words and a row's title: 16 px, semibold.
  final TextStyle label;

  /// Supporting words: 14 px, in the muted ink.
  final TextStyle secondary;

  /// Capitals over a group or on a tag: 12 px, bold, tracked. Parts set it
  /// in capitals.
  final TextStyle caption;

  /// A copy with the given styles replaced.
  BrutalTextTheme copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? secondary,
    TextStyle? caption,
  }) => BrutalTextTheme(
    display: display ?? this.display,
    headline: headline ?? this.headline,
    title: title ?? this.title,
    body: body ?? this.body,
    label: label ?? this.label,
    secondary: secondary ?? this.secondary,
    caption: caption ?? this.caption,
  );

  /// These styles with the colours [from] gave them moved to [to]'s: ink
  /// to ink, muted to muted; a colour of the app's own stays.
  BrutalTextTheme recoloured(BrutalColors from, BrutalColors to) {
    if (identical(from, to) || from == to) return this;
    TextStyle r(TextStyle s) => s.color == from.ink
        ? s.copyWith(color: to.ink)
        : s.color == from.inkMuted
        ? s.copyWith(color: to.inkMuted)
        : s;
    return copyWith(
      display: r(display),
      headline: r(headline),
      title: r(title),
      body: r(body),
      label: r(label),
      secondary: r(secondary),
      caption: r(caption),
    );
  }

  /// These styles in [typeface], their sizes, weights and colours kept; these
  /// styles as they are when they are in it already (its family and its
  /// fallbacks).
  BrutalTextTheme inFace(BrutalTypeface typeface) {
    TextStyle f(TextStyle s) => TextStyle(
      inherit: s.inherit,
      color: s.color,
      fontSize: s.fontSize,
      fontWeight: s.fontWeight,
      fontStyle: s.fontStyle,
      letterSpacing: s.letterSpacing,
      wordSpacing: s.wordSpacing,
      height: s.height,
      leadingDistribution: s.leadingDistribution,
      decoration: s.decoration,
      fontFeatures: s.fontFeatures,
      fontVariations: s.fontVariations,
      fontFamily: _familyOf(typeface),
      fontFamilyFallback: typeface.fallback.isEmpty ? null : typeface.fallback,
    );
    final set = f(body);
    if (body.fontFamily == set.fontFamily &&
        listEquals(body.fontFamilyFallback, set.fontFamilyFallback)) {
      return this;
    }
    return copyWith(
      display: f(display),
      headline: f(headline),
      title: f(title),
      body: f(body),
      label: f(label),
      secondary: f(secondary),
      caption: f(caption),
    );
  }

  /// Between [a] and [b] at [t].
  static BrutalTextTheme lerp(BrutalTextTheme a, BrutalTextTheme b, double t) {
    if (identical(a, b)) return a;
    TextStyle s(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return BrutalTextTheme(
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
      other is BrutalTextTheme &&
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

/// Everything Brutal draws from: its colours, its type and face, its density,
/// the weight of its one rule and the reach of its one shadow, and the styles
/// that set one kind of part app-wide. Immutable, as `ThemeData` is.
///
/// Every part reads its `style:` first, then its slot here, then the look's
/// own default; a style reaches only what keeps the look (colours, room,
/// size, words and glyph size), never a corner, a rule's width or a shadow's
/// blur.
///
/// ```dart
/// BrutalThemeData.from(signal: const Color(0xFF0A7D4F)).copyWith(filledButtonStyle: const BrutalStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32))))
/// ```
@immutable
class BrutalThemeData with Diagnosticable {
  /// A theme from its parts; [BrutalThemeData.light] and
  /// [BrutalThemeData.dark] are the look's own.
  ///
  /// [borderWidth] stands from 2 to 4 px and [shadowOffset] from 2 to 8: one
  /// heavy rule and one hard shadow at every value. Outside those a debug
  /// build stops with the rule's name; a release build clamps.
  BrutalThemeData({
    required this.colors,
    BrutalTextTheme? textTheme,
    this.typeface = BrutalTypeface.spaceGrotesk,
    BrutalDensity? density,
    double borderWidth = BrutalMetrics.borderWidth,
    double shadowOffset = BrutalMetrics.shadowOffset,
    this.filledButtonStyle,
    this.framedButtonStyle,
    this.textButtonStyle,
    this.destructiveButtonStyle,
    this.iconButtonStyle,
    this.floatingButtonStyle,
    this.buttonGroupStyle,
    this.toggleGroupStyle,
    this.linkStyle,
    this.kbdStyle,
    this.blockStyle,
    this.tagStyle,
    this.chartStyle,
    this.checkboxStyle,
    this.radioStyle,
    this.switchStyle,
    this.segmentedButtonStyle,
    this.stepperStyle,
    this.dataTableStyle,
    this.scrollAreaStyle,
    this.splitViewStyle,
    this.carouselStyle,
    this.reorderableListStyle,
    this.swipeRowStyle,
    this.pullToRefreshStyle,
    this.treeStyle,
    this.disclosureStyle,
    this.descriptionListStyle,
    this.timelineStyle,
    this.avatarStyle,
    this.badgeStyle,
    this.mediaStyle,
    this.skeletonStyle,
    this.meterStyle,
    this.textFieldStyle,
    this.fieldLabelStyle,
    this.fieldMessageStyle,
    this.noticeStyle,
    this.stateViewStyle,
    this.spinnerStyle,
    this.progressBarStyle,
    this.toastStyle,
    this.sectionHeaderStyle,
    this.listGroupStyle,
    this.ruleStyle,
    this.listTileStyle,
    this.menuStyle,
    this.appBarStyle,
    this.navigationBarStyle,
    this.navigationRailStyle,
    this.sideNavigationStyle,
    this.tabBarStyle,
    this.dialogStyle,
    this.bottomSheetStyle,
    this.sideSheetStyle,
    this.actionSheetStyle,
    this.calendarStyle,
    this.wheelPickerStyle,
    this.colorPickerStyle,
    this.popoverStyle,
    this.tooltipStyle,
    this.sliderStyle,
    this.chipStyle,
    this.ratingStyle,
    this.fileDropStyle,
    this.breadcrumbStyle,
    this.paginationStyle,
    this.stepProgressStyle,
    this.pageDotsStyle,
    this.menuBarStyle,
    this.commandPaletteStyle,
  }) : assert(
         borderWidth >= BrutalMetrics.minBorderWidth &&
             borderWidth <= BrutalMetrics.maxBorderWidth,
         'Brutal draws one heavy rule: borderWidth stands from '
         '${BrutalMetrics.minBorderWidth} to ${BrutalMetrics.maxBorderWidth} '
         'px, not $borderWidth.',
       ),
       assert(
         shadowOffset >= BrutalMetrics.minShadowOffset &&
             shadowOffset <= BrutalMetrics.maxShadowOffset,
         'Brutal casts one hard shadow: shadowOffset stands from '
         '${BrutalMetrics.minShadowOffset} to ${BrutalMetrics.maxShadowOffset} '
         'px, not $shadowOffset.',
       ),
       borderWidth = borderWidth.clamp(
         BrutalMetrics.minBorderWidth,
         BrutalMetrics.maxBorderWidth,
       ),
       shadowOffset = shadowOffset.clamp(
         BrutalMetrics.minShadowOffset,
         BrutalMetrics.maxShadowOffset,
       ),
       textTheme =
           textTheme ?? BrutalTextTheme.from(colors, typeface: typeface),
       density = density ?? BrutalDensity.adaptivePlatformDensity;

  /// The look by day.
  factory BrutalThemeData.light({
    BrutalDensity? density,
    BrutalTypeface typeface = BrutalTypeface.spaceGrotesk,
  }) => BrutalThemeData(
    colors: const BrutalColors.light(),
    density: density,
    typeface: typeface,
  );

  /// The look by night.
  factory BrutalThemeData.dark({
    BrutalDensity? density,
    BrutalTypeface typeface = BrutalTypeface.spaceGrotesk,
  }) => BrutalThemeData(
    colors: const BrutalColors.dark(),
    density: density,
    typeface: typeface,
  );

  /// The look in [brightness]: [BrutalThemeData.light] or
  /// [BrutalThemeData.dark].
  factory BrutalThemeData.raw(
    Brightness brightness, {
    BrutalDensity? density,
    BrutalTypeface typeface = BrutalTypeface.spaceGrotesk,
  }) => brightness == Brightness.dark
      ? BrutalThemeData.dark(density: density, typeface: typeface)
      : BrutalThemeData.light(density: density, typeface: typeface);

  /// Brutal in an app's own colours and face: its main action's [signal],
  /// any block colours it names, and its [typeface]. The rules, shadows,
  /// page and words stay the look's.
  ///
  /// The signal stays the main action's fill as given, its words black or
  /// white, whichever holds 4.5:1 on it (ui_core's [RawPalette.accentFill]
  /// by [RawAccentRule.named]). A flat bright face under black words is the
  /// style's core, so a gold or a pastel keeps its colour, where Material's
  /// scheme would darken it under white words.
  ///
  /// [lime] is the lead block's colour: a screen's one block, a chosen row,
  /// a success, a span's days. Unnamed, it takes the signal's hue at the
  /// look's own lime's tone and chroma, its black words held at 4.5:1, so a
  /// screen's main action and its lead block are one family. [blue], [pink]
  /// and [violet] stay the look's own unless named: they are also a chart's
  /// series and the avatars' colours, which need four hues told apart. A
  /// named block wins; blocks carry black words whatever the mode, so a
  /// named one must hold them at 4.5:1, and a darker one stops a debug build
  /// with the rule's name.
  ///
  /// ```dart
  /// final theme = BrutalThemeData.from(signal: const Color(0xFF00C2A8), blue: const Color(0xFF3D7BFF));
  /// ```
  factory BrutalThemeData.from({
    required Color signal,
    Color? lime,
    Color? blue,
    Color? pink,
    Color? violet,
    BrutalTypeface typeface = BrutalTypeface.spaceGrotesk,
    Brightness brightness = Brightness.light,
    BrutalDensity? density,
  }) {
    final base = brightness == Brightness.dark
        ? const BrutalColors.dark()
        : const BrutalColors.light();
    final main = RawPalette.accentFill(
      signal,
      brightness: brightness,
      rule: RawAccentRule.named,
      darkInk: base.onBlock,
    );
    for (final (name, block) in [
      ('lime', lime),
      ('blue', blue),
      ('pink', pink),
      ('violet', violet),
    ]) {
      assert(
        block == null || RawPalette.contrastRatio(base.onBlock, block) >= 4.5,
        'Brutal\'s blocks carry black words at 4.5:1: $name $block reads '
        'them at ${RawPalette.contrastRatio(base.onBlock, block).toStringAsFixed(2)}:1. '
        'Give a lighter colour.',
      );
    }
    return BrutalThemeData(
      colors: base.copyWith(
        signal: main.fill,
        onSignal: main.ink,
        lime: lime ?? _leadFrom(signal, base),
        blue: blue,
        pink: pink,
        violet: violet,
      ),
      typeface: typeface,
      density: density,
    );
  }

  // The lead block for [signal]: its hue at [base]'s lime's tone and chroma,
  // under black words at 4.5:1.
  static Color _leadFrom(Color signal, BrutalColors base) {
    final own = RawHct.fromColor(base.lime);
    final lead = RawHct.fromColor(signal)
        .withTone(own.tone)
        .withChroma(own.chroma)
        .toColor();
    return RawPalette.readableTone(lead, on: [base.onBlock]);
  }

  /// The names of the look's six palettes, the first its default:
  /// [preset] takes one.
  ///
  /// * `raw`: the look's own, a signal orange and a lime lead on a white
  ///   page.
  /// * `poster`: bright primaries on a white page, a yellow signal and a
  ///   green lead, cobalt, hot pink and violet blocks.
  /// * `zine`: soft colours on newsprint, a coral signal and a peach lead,
  ///   sky, bubblegum and lilac blocks on a cream page; by night a warm
  ///   near-black.
  /// * `riso`: risograph inks on a white page, a fluorescent pink signal
  ///   and a yellow lead.
  /// * `blueprint`: cool and technical, a cobalt signal, a periwinkle lead
  ///   and a sky block on a pale blue page; by night a navy-black.
  /// * `acid`: loud, an acid green signal and an electric cyan lead, hot
  ///   pink and violet blocks; by night on black.
  ///
  /// Each holds the look's words: black on every block and on the signal,
  /// the page's words at 4.5:1, by day and by night. [BrutalThemeData.from]
  /// takes any brand colour.
  static const List<String> presets = [
    'raw',
    'poster',
    'zine',
    'riso',
    'blueprint',
    'acid',
  ];

  /// The six presets as ui_core's [RawNamedPalette]s, for an app's palette
  /// picker: each one's id is its preset's (one of [presets]), its
  /// swatches its signal, its lead block and its page, by day and by night.
  /// [BrutalThemeData.preset] with the id gives its theme, and [BrutalHost]
  /// takes one as its `palette`.
  ///
  /// ```dart
  /// BrutalThemeData.preset(BrutalThemeData.palettes[2].id, Brightness.dark)
  /// ```
  static const List<RawNamedPalette> palettes = [
    RawNamedPalette(
      id: 'raw',
      label: 'Raw',
      swatches: [Color(0xFFFF6A13), Color(0xFFB8F229), Color(0xFFFFFFFF)],
      darkSwatches: [Color(0xFFFF7A2E), Color(0xFFB8F229), Color(0xFF121212)],
    ),
    RawNamedPalette(
      id: 'poster',
      label: 'Poster',
      swatches: [Color(0xFFFFD000), Color(0xFF2ED573), Color(0xFFFFFFFF)],
      darkSwatches: [Color(0xFFFFD60A), Color(0xFF3DDC7A), Color(0xFF121212)],
    ),
    RawNamedPalette(
      id: 'zine',
      label: 'Zine',
      swatches: [Color(0xFFFF7A59), Color(0xFFFFC2A1), Color(0xFFF4EFE3)],
      darkSwatches: [Color(0xFFFF8C6E), Color(0xFFFFC7A8), Color(0xFF17140F)],
    ),
    RawNamedPalette(
      id: 'riso',
      label: 'Riso',
      swatches: [Color(0xFFFF48B0), Color(0xFFFFE600), Color(0xFFFFFFFF)],
      darkSwatches: [Color(0xFFFF5CB9), Color(0xFFFFE81F), Color(0xFF141312)],
    ),
    RawNamedPalette(
      id: 'blueprint',
      label: 'Blueprint',
      swatches: [Color(0xFF4F7BFF), Color(0xFF8AA4FF), Color(0xFFE9F0FF)],
      darkSwatches: [Color(0xFF6B8FFF), Color(0xFF93ABFF), Color(0xFF0E1424)],
    ),
    RawNamedPalette(
      id: 'acid',
      label: 'Acid',
      swatches: [Color(0xFFB4FF2B), Color(0xFF3DE7FF), Color(0xFFFFFFFF)],
      darkSwatches: [Color(0xFFB4FF2B), Color(0xFF3DE7FF), Color(0xFF0D0D0D)],
    ),
  ];

  /// The preset named [id] (one of [presets]) in [brightness].
  factory BrutalThemeData.preset(
    String id,
    Brightness brightness, {
    BrutalDensity? density,
    BrutalTypeface typeface = BrutalTypeface.spaceGrotesk,
  }) {
    assert(presets.contains(id), 'Brutal has no preset "$id": $presets');
    final day = brightness == Brightness.light;
    final colors = switch (id) {
      'poster' => day ? _posterDay : _posterNight,
      'zine' => day ? _zineDay : _zineNight,
      'riso' => day ? _risoDay : _risoNight,
      'blueprint' => day ? _blueprintDay : _blueprintNight,
      'acid' => day ? _acidDay : _acidNight,
      _ => null,
    };
    if (colors == null) {
      return BrutalThemeData.raw(
        brightness,
        density: density,
        typeface: typeface,
      );
    }
    return BrutalThemeData(
      colors: colors,
      density: density,
      typeface: typeface,
    );
  }

  static const BrutalColors _posterDay = BrutalColors(
    brightness: Brightness.light,
    paper: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF000000),
    inkMuted: Color(0xFF4D4D4D),
    disabled: Color(0xFF737373),
    signal: Color(0xFFFFD000),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFD7000F),
    onDanger: Color(0xFFFFFFFF),
    lime: Color(0xFF2ED573),
    blue: Color(0xFF4F7BFF),
    pink: Color(0xFFFF4F9A),
    violet: Color(0xFF9B7BFF),
    onBlock: Color(0xFF000000),
    scrim: Color(0x80000000),
  );

  static const BrutalColors _posterNight = BrutalColors(
    brightness: Brightness.dark,
    paper: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    ink: Color(0xFFF2F2F2),
    inkMuted: Color(0xFFB3B3B3),
    disabled: Color(0xFF888888),
    signal: Color(0xFFFFD60A),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFFF5A5F),
    onDanger: Color(0xFF000000),
    lime: Color(0xFF3DDC7A),
    blue: Color(0xFF6B8FFF),
    pink: Color(0xFFFF63A8),
    violet: Color(0xFFAA8FFF),
    onBlock: Color(0xFF000000),
    scrim: Color(0xB3000000),
  );

  static const BrutalColors _zineDay = BrutalColors(
    brightness: Brightness.light,
    paper: Color(0xFFF4EFE3),
    surface: Color(0xFFFFFCF4),
    ink: Color(0xFF000000),
    inkMuted: Color(0xFF4F4A42),
    disabled: Color(0xFF706A62),
    signal: Color(0xFFFF7A59),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFD7000F),
    onDanger: Color(0xFFFFFFFF),
    lime: Color(0xFFFFC2A1),
    blue: Color(0xFF8DB4FF),
    pink: Color(0xFFFFA0D2),
    violet: Color(0xFFC1A6FF),
    onBlock: Color(0xFF000000),
    scrim: Color(0x80000000),
  );

  static const BrutalColors _zineNight = BrutalColors(
    brightness: Brightness.dark,
    paper: Color(0xFF17140F),
    surface: Color(0xFF231F18),
    ink: Color(0xFFF4EFE3),
    inkMuted: Color(0xFFBDB5A6),
    disabled: Color(0xFF8E877C),
    signal: Color(0xFFFF8C6E),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFFF5A5F),
    onDanger: Color(0xFF000000),
    lime: Color(0xFFFFC7A8),
    blue: Color(0xFF97BBFF),
    pink: Color(0xFFFFA8D6),
    violet: Color(0xFFC8AEFF),
    onBlock: Color(0xFF000000),
    scrim: Color(0xB3000000),
  );

  static const BrutalColors _risoDay = BrutalColors(
    brightness: Brightness.light,
    paper: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF000000),
    inkMuted: Color(0xFF4D4A45),
    disabled: Color(0xFF74716B),
    signal: Color(0xFFFF48B0),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFD7000F),
    onDanger: Color(0xFFFFFFFF),
    lime: Color(0xFFFFE600),
    blue: Color(0xFF5C8DFF),
    pink: Color(0xFFFF9BD2),
    violet: Color(0xFFA68BFF),
    onBlock: Color(0xFF000000),
    scrim: Color(0x80000000),
  );

  static const BrutalColors _risoNight = BrutalColors(
    brightness: Brightness.dark,
    paper: Color(0xFF141312),
    surface: Color(0xFF201E1C),
    ink: Color(0xFFF5F2EC),
    inkMuted: Color(0xFFB7B2AA),
    disabled: Color(0xFF8A867F),
    signal: Color(0xFFFF5CB9),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFFF5A5F),
    onDanger: Color(0xFF000000),
    lime: Color(0xFFFFE81F),
    blue: Color(0xFF6E9BFF),
    pink: Color(0xFFFFA3D6),
    violet: Color(0xFFAE96FF),
    onBlock: Color(0xFF000000),
    scrim: Color(0xB3000000),
  );

  static const BrutalColors _blueprintDay = BrutalColors(
    brightness: Brightness.light,
    paper: Color(0xFFE9F0FF),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF000000),
    inkMuted: Color(0xFF474D5C),
    disabled: Color(0xFF656B7B),
    signal: Color(0xFF4F7BFF),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFD7000F),
    onDanger: Color(0xFFFFFFFF),
    lime: Color(0xFF8AA4FF),
    blue: Color(0xFF6CC6FF),
    pink: Color(0xFFFF85C8),
    violet: Color(0xFFA68BFF),
    onBlock: Color(0xFF000000),
    scrim: Color(0x80000000),
  );

  static const BrutalColors _blueprintNight = BrutalColors(
    brightness: Brightness.dark,
    paper: Color(0xFF0E1424),
    surface: Color(0xFF182036),
    ink: Color(0xFFEAF0FF),
    inkMuted: Color(0xFFAEB8D0),
    disabled: Color(0xFF838DA6),
    signal: Color(0xFF6B8FFF),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFFF5A5F),
    onDanger: Color(0xFF000000),
    lime: Color(0xFF93ABFF),
    blue: Color(0xFF79CDFF),
    pink: Color(0xFFFF8FCC),
    violet: Color(0xFFAE96FF),
    onBlock: Color(0xFF000000),
    scrim: Color(0xB3000000),
  );

  static const BrutalColors _acidDay = BrutalColors(
    brightness: Brightness.light,
    paper: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF000000),
    inkMuted: Color(0xFF4D4D4D),
    disabled: Color(0xFF737373),
    signal: Color(0xFFB4FF2B),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFD7000F),
    onDanger: Color(0xFFFFFFFF),
    lime: Color(0xFF3DE7FF),
    blue: Color(0xFF6E8BFF),
    pink: Color(0xFFFF5CC8),
    violet: Color(0xFFA27BFF),
    onBlock: Color(0xFF000000),
    scrim: Color(0x80000000),
  );

  static const BrutalColors _acidNight = BrutalColors(
    brightness: Brightness.dark,
    paper: Color(0xFF0D0D0D),
    surface: Color(0xFF1A1A1A),
    ink: Color(0xFFF2F2F2),
    inkMuted: Color(0xFFB3B3B3),
    disabled: Color(0xFF888888),
    signal: Color(0xFFB4FF2B),
    onSignal: Color(0xFF000000),
    danger: Color(0xFFFF5A5F),
    onDanger: Color(0xFF000000),
    lime: Color(0xFF3DE7FF),
    blue: Color(0xFF7A97FF),
    pink: Color(0xFFFF6CCE),
    violet: Color(0xFFAE8CFF),
    onBlock: Color(0xFF000000),
    scrim: Color(0xB3000000),
  );

  /// The colours.
  final BrutalColors colors;

  /// The type, set in [typeface].
  final BrutalTextTheme textTheme;

  /// The face every word is set in, and the Material theme Brutal installs
  /// under its parts: Space Grotesk unless an app gives its own heavy
  /// grotesk.
  final BrutalTypeface typeface;

  /// How tight the controls stand. By default the platform's: compact under
  /// a pointer (macOS, Windows, Linux), standard on touch.
  final BrutalDensity density;

  /// The width of every rule: a control's border, a cell's divider, a
  /// table's grid line. 2 to 4 px; 2 by default.
  final double borderWidth;

  /// How far the hard shadow stands from its face, down and toward the end
  /// side, and so how far a press moves the face. 2 to 8 px; 4 by default.
  final double shadowOffset;

  /// The style app-wide of [BrutalButton.filled] and a filled [BrutalSplitButton]: a screen's main action, under each one's own `style:`.
  final BrutalStyle? filledButtonStyle;

  /// The style app-wide of the ordinary [BrutalButton] and [BrutalSplitButton], under each one's own `style:`.
  final BrutalStyle? framedButtonStyle;

  /// The style app-wide of [BrutalButton.text], under each one's own `style:`.
  final BrutalStyle? textButtonStyle;

  /// The style app-wide of any [BrutalButton] with `isDestructiveAction`, over its kind's style, under each one's own `style:`.
  final BrutalStyle? destructiveButtonStyle;

  /// The style app-wide of [BrutalIconButton] and [BrutalAppBarAction], under each one's own `style:`.
  final BrutalStyle? iconButtonStyle;

  /// The style app-wide of [BrutalFloatingButton], under each one's own `style:`.
  final BrutalStyle? floatingButtonStyle;

  /// The style app-wide of [BrutalButtonGroup], under each one's own `style:`.
  final BrutalStyle? buttonGroupStyle;

  /// The style app-wide of [BrutalToggleGroup], under each one's own `style:`.
  final BrutalStyle? toggleGroupStyle;

  /// The style app-wide of [BrutalLink], under each one's own `style:`.
  final BrutalStyle? linkStyle;

  /// The style app-wide of [BrutalKbd], under each one's own `style:`.
  final BrutalStyle? kbdStyle;

  /// The style app-wide of [BrutalBlock], under each one's own `style:`.
  final BrutalStyle? blockStyle;

  /// The style app-wide of [BrutalTag], under each one's own `style:`.
  final BrutalStyle? tagStyle;

  /// The style app-wide of [BrutalLineChart], [BrutalAreaChart], [BrutalBarChart], [BrutalPieChart] and [BrutalSparkline], under each one's own `style:`.
  final BrutalStyle? chartStyle;

  /// The style app-wide of [BrutalCheckbox], under each one's own `style:`.
  final BrutalStyle? checkboxStyle;

  /// The style app-wide of [BrutalRadio], under each one's own `style:`.
  final BrutalStyle? radioStyle;

  /// The style app-wide of [BrutalSwitch], under each one's own `style:`.
  final BrutalStyle? switchStyle;

  /// The style app-wide of [BrutalSegmentedButton], under each one's own `style:`.
  final BrutalStyle? segmentedButtonStyle;

  /// The style app-wide of [BrutalStepper], under each one's own `style:`.
  final BrutalStyle? stepperStyle;

  /// The style app-wide of [BrutalDataTable] and [BrutalTable], under each one's own `style:`.
  final BrutalStyle? dataTableStyle;

  /// The style app-wide of [BrutalScrollArea], under each one's own `style:`.
  final BrutalStyle? scrollAreaStyle;

  /// The style app-wide of [BrutalSplitView], under each one's own `style:`.
  final BrutalStyle? splitViewStyle;

  /// The style app-wide of [BrutalCarousel], under each one's own `style:`.
  final BrutalStyle? carouselStyle;

  /// The style app-wide of [BrutalReorderableList], under each one's own `style:`.
  final BrutalStyle? reorderableListStyle;

  /// The style app-wide of [BrutalSwipeRow], under each one's own `style:`.
  final BrutalStyle? swipeRowStyle;

  /// The style app-wide of [BrutalPullToRefresh], under each one's own `style:`.
  final BrutalStyle? pullToRefreshStyle;

  /// The style app-wide of [BrutalTree], under each one's own `style:`.
  final BrutalStyle? treeStyle;

  /// The style app-wide of [BrutalDisclosure] and [BrutalDisclosureGroup], under each one's own `style:`.
  final BrutalStyle? disclosureStyle;

  /// The style app-wide of [BrutalDescriptionList], under each one's own `style:`.
  final BrutalStyle? descriptionListStyle;

  /// The style app-wide of [BrutalTimeline], under each one's own `style:`.
  final BrutalStyle? timelineStyle;

  /// The style app-wide of [BrutalAvatar] and [BrutalAvatarGroup], under each one's own `style:`.
  final BrutalStyle? avatarStyle;

  /// The style app-wide of [BrutalBadge], under each one's own `style:`.
  final BrutalStyle? badgeStyle;

  /// The style app-wide of [BrutalMedia], under each one's own `style:`.
  final BrutalStyle? mediaStyle;

  /// The style app-wide of [BrutalSkeleton], under each one's own `style:`.
  final BrutalStyle? skeletonStyle;

  /// The style app-wide of [BrutalMeter], under each one's own `style:`.
  final BrutalStyle? meterStyle;

  /// The style app-wide of every field's box: [BrutalTextField], [BrutalSearchField], [BrutalPasswordField], [BrutalInputGroup], [BrutalCodeField], [BrutalCombobox], [BrutalTagInput], [BrutalSelect] and [BrutalFieldButton], under each one's own `style:`.
  final BrutalStyle? textFieldStyle;

  /// The style app-wide of [BrutalFieldLabel], the words over every field, under each one's own `style:`.
  final BrutalStyle? fieldLabelStyle;

  /// The style app-wide of [BrutalFieldMessage], the help or the failure under every field, under each one's own `style:`.
  final BrutalStyle? fieldMessageStyle;

  /// The style app-wide of [BrutalNotice], under each one's own `style:`.
  final BrutalStyle? noticeStyle;

  /// The style app-wide of [BrutalStateView], under each one's own `style:`.
  final BrutalStyle? stateViewStyle;

  /// The style app-wide of [BrutalSpinner], under each one's own `style:`.
  final BrutalStyle? spinnerStyle;

  /// The style app-wide of [BrutalProgressBar], under each one's own `style:`.
  final BrutalStyle? progressBarStyle;

  /// The style app-wide of the toasts [BrutalToaster] shows, under each one's own `style:`.
  final BrutalStyle? toastStyle;

  /// The style app-wide of [BrutalSectionHeader], under each one's own `style:`.
  final BrutalStyle? sectionHeaderStyle;

  /// The style app-wide of [BrutalListGroup], under each one's own `style:`.
  final BrutalStyle? listGroupStyle;

  /// The style app-wide of [BrutalRule], under each one's own `style:`.
  final BrutalStyle? ruleStyle;

  /// The style app-wide of [BrutalListTile], under each one's own `style:`.
  final BrutalStyle? listTileStyle;

  /// The style app-wide of every menu: [BrutalMenu], [BrutalMenuPanel] and [BrutalMenuRow], and the menus a select, a combobox, a split button and a menu bar open, under each one's own `style:`.
  final BrutalStyle? menuStyle;

  /// The style app-wide of [BrutalAppBar], under each one's own `style:`.
  final BrutalStyle? appBarStyle;

  /// The style app-wide of [BrutalNavigationBar], under each one's own `style:`.
  final BrutalStyle? navigationBarStyle;

  /// The style app-wide of [BrutalNavigationRail], under each one's own `style:`.
  final BrutalStyle? navigationRailStyle;

  /// The style app-wide of [BrutalSideNavigation], under each one's own `style:`.
  final BrutalStyle? sideNavigationStyle;

  /// The style app-wide of [BrutalTabBar], under each one's own `style:`.
  final BrutalStyle? tabBarStyle;

  /// The style app-wide of [BrutalDialog], under each one's own `style:`.
  final BrutalStyle? dialogStyle;

  /// The style app-wide of the panel [showBrutalBottomSheet] opens, under each one's own `style:`.
  final BrutalStyle? bottomSheetStyle;

  /// The style app-wide of the panel [showBrutalSideSheet] opens, under each one's own `style:`.
  final BrutalStyle? sideSheetStyle;

  /// The style app-wide of the rows [showBrutalActionSheet] opens, under each one's own `style:`.
  final BrutalStyle? actionSheetStyle;

  /// The style app-wide of [BrutalCalendar], [BrutalDatePicker] and [BrutalDateRangePicker], under each one's own `style:`.
  final BrutalStyle? calendarStyle;

  /// The style app-wide of [BrutalWheelPicker] and [BrutalTimePicker], under each one's own `style:`.
  final BrutalStyle? wheelPickerStyle;

  /// The style app-wide of [BrutalColorPicker], under each one's own `style:`.
  final BrutalStyle? colorPickerStyle;

  /// The style app-wide of [BrutalPopover] and [BrutalHoverCard], under each one's own `style:`.
  final BrutalStyle? popoverStyle;

  /// The style app-wide of [BrutalTooltip], under each one's own `style:`.
  final BrutalStyle? tooltipStyle;

  /// The style app-wide of [BrutalSlider] and [BrutalRangeSlider], under each one's own `style:`.
  final BrutalStyle? sliderStyle;

  /// The style app-wide of [BrutalChip], under each one's own `style:`.
  final BrutalStyle? chipStyle;

  /// The style app-wide of [BrutalRating], under each one's own `style:`.
  final BrutalStyle? ratingStyle;

  /// The style app-wide of [BrutalFileDrop], under each one's own `style:`.
  final BrutalStyle? fileDropStyle;

  /// The style app-wide of [BrutalBreadcrumb], under each one's own `style:`.
  final BrutalStyle? breadcrumbStyle;

  /// The style app-wide of [BrutalPagination], under each one's own `style:`.
  final BrutalStyle? paginationStyle;

  /// The style app-wide of [BrutalStepProgress], under each one's own `style:`.
  final BrutalStyle? stepProgressStyle;

  /// The style app-wide of [BrutalPageDots], under each one's own `style:`.
  final BrutalStyle? pageDotsStyle;

  /// The style app-wide of [BrutalMenuBar], under each one's own `style:`.
  final BrutalStyle? menuBarStyle;

  /// The style app-wide of [BrutalCommandPalette], under each one's own `style:`.
  final BrutalStyle? commandPaletteStyle;

  /// Whether this is the look by day or by night.
  Brightness get brightness => colors.brightness;

  /// The height every control that can share a line takes at [density]:
  /// 48 standard, 44 comfortable, 40 compact.
  double get controlHeight => BrutalMetrics.controlHeight + density.heightDelta;

  /// The face's capitals as a fraction of its size: what a label is centred
  /// by.
  double get capHeightFactor => typeface.capHeightFactor;

  /// Where the hard shadow stands from its face in [direction]: down, and
  /// toward the end side.
  Offset shadowIn(TextDirection direction) =>
      brutalTravelOffset(direction, shadowOffset);

  /// A copy with the given fields replaced. New [colors] recolour the type
  /// (a custom [textTheme] keeps its own sizes and weights); a new
  /// [typeface] sets the type in it.
  BrutalThemeData copyWith({
    BrutalColors? colors,
    BrutalTextTheme? textTheme,
    BrutalTypeface? typeface,
    BrutalDensity? density,
    double? borderWidth,
    double? shadowOffset,
    BrutalStyle? filledButtonStyle,
    BrutalStyle? framedButtonStyle,
    BrutalStyle? textButtonStyle,
    BrutalStyle? destructiveButtonStyle,
    BrutalStyle? iconButtonStyle,
    BrutalStyle? floatingButtonStyle,
    BrutalStyle? buttonGroupStyle,
    BrutalStyle? toggleGroupStyle,
    BrutalStyle? linkStyle,
    BrutalStyle? kbdStyle,
    BrutalStyle? blockStyle,
    BrutalStyle? tagStyle,
    BrutalStyle? chartStyle,
    BrutalStyle? checkboxStyle,
    BrutalStyle? radioStyle,
    BrutalStyle? switchStyle,
    BrutalStyle? segmentedButtonStyle,
    BrutalStyle? stepperStyle,
    BrutalStyle? dataTableStyle,
    BrutalStyle? scrollAreaStyle,
    BrutalStyle? splitViewStyle,
    BrutalStyle? carouselStyle,
    BrutalStyle? reorderableListStyle,
    BrutalStyle? swipeRowStyle,
    BrutalStyle? pullToRefreshStyle,
    BrutalStyle? treeStyle,
    BrutalStyle? disclosureStyle,
    BrutalStyle? descriptionListStyle,
    BrutalStyle? timelineStyle,
    BrutalStyle? avatarStyle,
    BrutalStyle? badgeStyle,
    BrutalStyle? mediaStyle,
    BrutalStyle? skeletonStyle,
    BrutalStyle? meterStyle,
    BrutalStyle? textFieldStyle,
    BrutalStyle? fieldLabelStyle,
    BrutalStyle? fieldMessageStyle,
    BrutalStyle? noticeStyle,
    BrutalStyle? stateViewStyle,
    BrutalStyle? spinnerStyle,
    BrutalStyle? progressBarStyle,
    BrutalStyle? toastStyle,
    BrutalStyle? sectionHeaderStyle,
    BrutalStyle? listGroupStyle,
    BrutalStyle? ruleStyle,
    BrutalStyle? listTileStyle,
    BrutalStyle? menuStyle,
    BrutalStyle? appBarStyle,
    BrutalStyle? navigationBarStyle,
    BrutalStyle? navigationRailStyle,
    BrutalStyle? sideNavigationStyle,
    BrutalStyle? tabBarStyle,
    BrutalStyle? dialogStyle,
    BrutalStyle? bottomSheetStyle,
    BrutalStyle? sideSheetStyle,
    BrutalStyle? actionSheetStyle,
    BrutalStyle? calendarStyle,
    BrutalStyle? wheelPickerStyle,
    BrutalStyle? colorPickerStyle,
    BrutalStyle? popoverStyle,
    BrutalStyle? tooltipStyle,
    BrutalStyle? sliderStyle,
    BrutalStyle? chipStyle,
    BrutalStyle? ratingStyle,
    BrutalStyle? fileDropStyle,
    BrutalStyle? breadcrumbStyle,
    BrutalStyle? paginationStyle,
    BrutalStyle? stepProgressStyle,
    BrutalStyle? pageDotsStyle,
    BrutalStyle? menuBarStyle,
    BrutalStyle? commandPaletteStyle,
  }) => BrutalThemeData(
    colors: colors ?? this.colors,
    textTheme:
        textTheme ??
        _restyled(
          this.textTheme.recoloured(this.colors, colors ?? this.colors),
          typeface,
        ),
    typeface: typeface ?? this.typeface,
    density: density ?? this.density,
    borderWidth: borderWidth ?? this.borderWidth,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    filledButtonStyle: filledButtonStyle ?? this.filledButtonStyle,
    framedButtonStyle: framedButtonStyle ?? this.framedButtonStyle,
    textButtonStyle: textButtonStyle ?? this.textButtonStyle,
    destructiveButtonStyle:
        destructiveButtonStyle ?? this.destructiveButtonStyle,
    iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
    floatingButtonStyle: floatingButtonStyle ?? this.floatingButtonStyle,
    buttonGroupStyle: buttonGroupStyle ?? this.buttonGroupStyle,
    toggleGroupStyle: toggleGroupStyle ?? this.toggleGroupStyle,
    linkStyle: linkStyle ?? this.linkStyle,
    kbdStyle: kbdStyle ?? this.kbdStyle,
    blockStyle: blockStyle ?? this.blockStyle,
    tagStyle: tagStyle ?? this.tagStyle,
    chartStyle: chartStyle ?? this.chartStyle,
    checkboxStyle: checkboxStyle ?? this.checkboxStyle,
    radioStyle: radioStyle ?? this.radioStyle,
    switchStyle: switchStyle ?? this.switchStyle,
    segmentedButtonStyle: segmentedButtonStyle ?? this.segmentedButtonStyle,
    stepperStyle: stepperStyle ?? this.stepperStyle,
    dataTableStyle: dataTableStyle ?? this.dataTableStyle,
    scrollAreaStyle: scrollAreaStyle ?? this.scrollAreaStyle,
    splitViewStyle: splitViewStyle ?? this.splitViewStyle,
    carouselStyle: carouselStyle ?? this.carouselStyle,
    reorderableListStyle: reorderableListStyle ?? this.reorderableListStyle,
    swipeRowStyle: swipeRowStyle ?? this.swipeRowStyle,
    pullToRefreshStyle: pullToRefreshStyle ?? this.pullToRefreshStyle,
    treeStyle: treeStyle ?? this.treeStyle,
    disclosureStyle: disclosureStyle ?? this.disclosureStyle,
    descriptionListStyle: descriptionListStyle ?? this.descriptionListStyle,
    timelineStyle: timelineStyle ?? this.timelineStyle,
    avatarStyle: avatarStyle ?? this.avatarStyle,
    badgeStyle: badgeStyle ?? this.badgeStyle,
    mediaStyle: mediaStyle ?? this.mediaStyle,
    skeletonStyle: skeletonStyle ?? this.skeletonStyle,
    meterStyle: meterStyle ?? this.meterStyle,
    textFieldStyle: textFieldStyle ?? this.textFieldStyle,
    fieldLabelStyle: fieldLabelStyle ?? this.fieldLabelStyle,
    fieldMessageStyle: fieldMessageStyle ?? this.fieldMessageStyle,
    noticeStyle: noticeStyle ?? this.noticeStyle,
    stateViewStyle: stateViewStyle ?? this.stateViewStyle,
    spinnerStyle: spinnerStyle ?? this.spinnerStyle,
    progressBarStyle: progressBarStyle ?? this.progressBarStyle,
    toastStyle: toastStyle ?? this.toastStyle,
    sectionHeaderStyle: sectionHeaderStyle ?? this.sectionHeaderStyle,
    listGroupStyle: listGroupStyle ?? this.listGroupStyle,
    ruleStyle: ruleStyle ?? this.ruleStyle,
    listTileStyle: listTileStyle ?? this.listTileStyle,
    menuStyle: menuStyle ?? this.menuStyle,
    appBarStyle: appBarStyle ?? this.appBarStyle,
    navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
    navigationRailStyle: navigationRailStyle ?? this.navigationRailStyle,
    sideNavigationStyle: sideNavigationStyle ?? this.sideNavigationStyle,
    tabBarStyle: tabBarStyle ?? this.tabBarStyle,
    dialogStyle: dialogStyle ?? this.dialogStyle,
    bottomSheetStyle: bottomSheetStyle ?? this.bottomSheetStyle,
    sideSheetStyle: sideSheetStyle ?? this.sideSheetStyle,
    actionSheetStyle: actionSheetStyle ?? this.actionSheetStyle,
    calendarStyle: calendarStyle ?? this.calendarStyle,
    wheelPickerStyle: wheelPickerStyle ?? this.wheelPickerStyle,
    colorPickerStyle: colorPickerStyle ?? this.colorPickerStyle,
    popoverStyle: popoverStyle ?? this.popoverStyle,
    tooltipStyle: tooltipStyle ?? this.tooltipStyle,
    sliderStyle: sliderStyle ?? this.sliderStyle,
    chipStyle: chipStyle ?? this.chipStyle,
    ratingStyle: ratingStyle ?? this.ratingStyle,
    fileDropStyle: fileDropStyle ?? this.fileDropStyle,
    breadcrumbStyle: breadcrumbStyle ?? this.breadcrumbStyle,
    paginationStyle: paginationStyle ?? this.paginationStyle,
    stepProgressStyle: stepProgressStyle ?? this.stepProgressStyle,
    pageDotsStyle: pageDotsStyle ?? this.pageDotsStyle,
    menuBarStyle: menuBarStyle ?? this.menuBarStyle,
    commandPaletteStyle: commandPaletteStyle ?? this.commandPaletteStyle,
  );

  static BrutalTextTheme _restyled(
    BrutalTextTheme type,
    BrutalTypeface? typeface,
  ) => typeface == null ? type : type.inFace(typeface);

  /// Between [a] and [b] at [t], for [AnimatedBrutalTheme].
  static BrutalThemeData lerp(BrutalThemeData a, BrutalThemeData b, double t) {
    if (identical(a, b)) return a;
    double between(double x, double y) => x + (y - x) * t;
    return BrutalThemeData(
      colors: BrutalColors.lerp(a.colors, b.colors, t),
      textTheme: BrutalTextTheme.lerp(a.textTheme, b.textTheme, t),
      typeface: t < 0.5 ? a.typeface : b.typeface,
      density: BrutalDensity.lerp(a.density, b.density, t),
      borderWidth: between(a.borderWidth, b.borderWidth),
      shadowOffset: between(a.shadowOffset, b.shadowOffset),
      filledButtonStyle: RawStyle.lerp(
        a.filledButtonStyle,
        b.filledButtonStyle,
        t,
      ),
      framedButtonStyle: RawStyle.lerp(
        a.framedButtonStyle,
        b.framedButtonStyle,
        t,
      ),
      textButtonStyle: RawStyle.lerp(a.textButtonStyle, b.textButtonStyle, t),
      destructiveButtonStyle: RawStyle.lerp(
        a.destructiveButtonStyle,
        b.destructiveButtonStyle,
        t,
      ),
      iconButtonStyle: RawStyle.lerp(a.iconButtonStyle, b.iconButtonStyle, t),
      floatingButtonStyle: RawStyle.lerp(
        a.floatingButtonStyle,
        b.floatingButtonStyle,
        t,
      ),
      buttonGroupStyle: RawStyle.lerp(
        a.buttonGroupStyle,
        b.buttonGroupStyle,
        t,
      ),
      toggleGroupStyle: RawStyle.lerp(
        a.toggleGroupStyle,
        b.toggleGroupStyle,
        t,
      ),
      linkStyle: RawStyle.lerp(a.linkStyle, b.linkStyle, t),
      kbdStyle: RawStyle.lerp(a.kbdStyle, b.kbdStyle, t),
      blockStyle: RawStyle.lerp(a.blockStyle, b.blockStyle, t),
      tagStyle: RawStyle.lerp(a.tagStyle, b.tagStyle, t),
      chartStyle: RawStyle.lerp(a.chartStyle, b.chartStyle, t),
      checkboxStyle: RawStyle.lerp(a.checkboxStyle, b.checkboxStyle, t),
      radioStyle: RawStyle.lerp(a.radioStyle, b.radioStyle, t),
      switchStyle: RawStyle.lerp(a.switchStyle, b.switchStyle, t),
      segmentedButtonStyle: RawStyle.lerp(
        a.segmentedButtonStyle,
        b.segmentedButtonStyle,
        t,
      ),
      stepperStyle: RawStyle.lerp(a.stepperStyle, b.stepperStyle, t),
      dataTableStyle: RawStyle.lerp(a.dataTableStyle, b.dataTableStyle, t),
      scrollAreaStyle: RawStyle.lerp(a.scrollAreaStyle, b.scrollAreaStyle, t),
      splitViewStyle: RawStyle.lerp(a.splitViewStyle, b.splitViewStyle, t),
      carouselStyle: RawStyle.lerp(a.carouselStyle, b.carouselStyle, t),
      reorderableListStyle: RawStyle.lerp(
        a.reorderableListStyle,
        b.reorderableListStyle,
        t,
      ),
      swipeRowStyle: RawStyle.lerp(a.swipeRowStyle, b.swipeRowStyle, t),
      pullToRefreshStyle: RawStyle.lerp(
        a.pullToRefreshStyle,
        b.pullToRefreshStyle,
        t,
      ),
      treeStyle: RawStyle.lerp(a.treeStyle, b.treeStyle, t),
      disclosureStyle: RawStyle.lerp(a.disclosureStyle, b.disclosureStyle, t),
      descriptionListStyle: RawStyle.lerp(
        a.descriptionListStyle,
        b.descriptionListStyle,
        t,
      ),
      timelineStyle: RawStyle.lerp(a.timelineStyle, b.timelineStyle, t),
      avatarStyle: RawStyle.lerp(a.avatarStyle, b.avatarStyle, t),
      badgeStyle: RawStyle.lerp(a.badgeStyle, b.badgeStyle, t),
      mediaStyle: RawStyle.lerp(a.mediaStyle, b.mediaStyle, t),
      skeletonStyle: RawStyle.lerp(a.skeletonStyle, b.skeletonStyle, t),
      meterStyle: RawStyle.lerp(a.meterStyle, b.meterStyle, t),
      textFieldStyle: RawStyle.lerp(a.textFieldStyle, b.textFieldStyle, t),
      fieldLabelStyle: RawStyle.lerp(a.fieldLabelStyle, b.fieldLabelStyle, t),
      fieldMessageStyle: RawStyle.lerp(
        a.fieldMessageStyle,
        b.fieldMessageStyle,
        t,
      ),
      noticeStyle: RawStyle.lerp(a.noticeStyle, b.noticeStyle, t),
      stateViewStyle: RawStyle.lerp(a.stateViewStyle, b.stateViewStyle, t),
      spinnerStyle: RawStyle.lerp(a.spinnerStyle, b.spinnerStyle, t),
      progressBarStyle: RawStyle.lerp(
        a.progressBarStyle,
        b.progressBarStyle,
        t,
      ),
      toastStyle: RawStyle.lerp(a.toastStyle, b.toastStyle, t),
      sectionHeaderStyle: RawStyle.lerp(
        a.sectionHeaderStyle,
        b.sectionHeaderStyle,
        t,
      ),
      listGroupStyle: RawStyle.lerp(a.listGroupStyle, b.listGroupStyle, t),
      ruleStyle: RawStyle.lerp(a.ruleStyle, b.ruleStyle, t),
      listTileStyle: RawStyle.lerp(a.listTileStyle, b.listTileStyle, t),
      menuStyle: RawStyle.lerp(a.menuStyle, b.menuStyle, t),
      appBarStyle: RawStyle.lerp(a.appBarStyle, b.appBarStyle, t),
      navigationBarStyle: RawStyle.lerp(
        a.navigationBarStyle,
        b.navigationBarStyle,
        t,
      ),
      navigationRailStyle: RawStyle.lerp(
        a.navigationRailStyle,
        b.navigationRailStyle,
        t,
      ),
      sideNavigationStyle: RawStyle.lerp(
        a.sideNavigationStyle,
        b.sideNavigationStyle,
        t,
      ),
      tabBarStyle: RawStyle.lerp(a.tabBarStyle, b.tabBarStyle, t),
      dialogStyle: RawStyle.lerp(a.dialogStyle, b.dialogStyle, t),
      bottomSheetStyle: RawStyle.lerp(
        a.bottomSheetStyle,
        b.bottomSheetStyle,
        t,
      ),
      sideSheetStyle: RawStyle.lerp(a.sideSheetStyle, b.sideSheetStyle, t),
      actionSheetStyle: RawStyle.lerp(
        a.actionSheetStyle,
        b.actionSheetStyle,
        t,
      ),
      calendarStyle: RawStyle.lerp(a.calendarStyle, b.calendarStyle, t),
      wheelPickerStyle: RawStyle.lerp(
        a.wheelPickerStyle,
        b.wheelPickerStyle,
        t,
      ),
      colorPickerStyle: RawStyle.lerp(
        a.colorPickerStyle,
        b.colorPickerStyle,
        t,
      ),
      popoverStyle: RawStyle.lerp(a.popoverStyle, b.popoverStyle, t),
      tooltipStyle: RawStyle.lerp(a.tooltipStyle, b.tooltipStyle, t),
      sliderStyle: RawStyle.lerp(a.sliderStyle, b.sliderStyle, t),
      chipStyle: RawStyle.lerp(a.chipStyle, b.chipStyle, t),
      ratingStyle: RawStyle.lerp(a.ratingStyle, b.ratingStyle, t),
      fileDropStyle: RawStyle.lerp(a.fileDropStyle, b.fileDropStyle, t),
      breadcrumbStyle: RawStyle.lerp(a.breadcrumbStyle, b.breadcrumbStyle, t),
      paginationStyle: RawStyle.lerp(a.paginationStyle, b.paginationStyle, t),
      stepProgressStyle: RawStyle.lerp(
        a.stepProgressStyle,
        b.stepProgressStyle,
        t,
      ),
      pageDotsStyle: RawStyle.lerp(a.pageDotsStyle, b.pageDotsStyle, t),
      menuBarStyle: RawStyle.lerp(a.menuBarStyle, b.menuBarStyle, t),
      commandPaletteStyle: RawStyle.lerp(
        a.commandPaletteStyle,
        b.commandPaletteStyle,
        t,
      ),
    );
  }

  /// Every part style by name.
  List<(String, BrutalStyle?)> get _partStyles => [
    ('filledButtonStyle', filledButtonStyle),
    ('framedButtonStyle', framedButtonStyle),
    ('textButtonStyle', textButtonStyle),
    ('destructiveButtonStyle', destructiveButtonStyle),
    ('iconButtonStyle', iconButtonStyle),
    ('floatingButtonStyle', floatingButtonStyle),
    ('buttonGroupStyle', buttonGroupStyle),
    ('toggleGroupStyle', toggleGroupStyle),
    ('linkStyle', linkStyle),
    ('kbdStyle', kbdStyle),
    ('blockStyle', blockStyle),
    ('tagStyle', tagStyle),
    ('chartStyle', chartStyle),
    ('checkboxStyle', checkboxStyle),
    ('radioStyle', radioStyle),
    ('switchStyle', switchStyle),
    ('segmentedButtonStyle', segmentedButtonStyle),
    ('stepperStyle', stepperStyle),
    ('dataTableStyle', dataTableStyle),
    ('scrollAreaStyle', scrollAreaStyle),
    ('splitViewStyle', splitViewStyle),
    ('carouselStyle', carouselStyle),
    ('reorderableListStyle', reorderableListStyle),
    ('swipeRowStyle', swipeRowStyle),
    ('pullToRefreshStyle', pullToRefreshStyle),
    ('treeStyle', treeStyle),
    ('disclosureStyle', disclosureStyle),
    ('descriptionListStyle', descriptionListStyle),
    ('timelineStyle', timelineStyle),
    ('avatarStyle', avatarStyle),
    ('badgeStyle', badgeStyle),
    ('mediaStyle', mediaStyle),
    ('skeletonStyle', skeletonStyle),
    ('meterStyle', meterStyle),
    ('textFieldStyle', textFieldStyle),
    ('fieldLabelStyle', fieldLabelStyle),
    ('fieldMessageStyle', fieldMessageStyle),
    ('noticeStyle', noticeStyle),
    ('stateViewStyle', stateViewStyle),
    ('spinnerStyle', spinnerStyle),
    ('progressBarStyle', progressBarStyle),
    ('toastStyle', toastStyle),
    ('sectionHeaderStyle', sectionHeaderStyle),
    ('listGroupStyle', listGroupStyle),
    ('ruleStyle', ruleStyle),
    ('listTileStyle', listTileStyle),
    ('menuStyle', menuStyle),
    ('appBarStyle', appBarStyle),
    ('navigationBarStyle', navigationBarStyle),
    ('navigationRailStyle', navigationRailStyle),
    ('sideNavigationStyle', sideNavigationStyle),
    ('tabBarStyle', tabBarStyle),
    ('dialogStyle', dialogStyle),
    ('bottomSheetStyle', bottomSheetStyle),
    ('sideSheetStyle', sideSheetStyle),
    ('actionSheetStyle', actionSheetStyle),
    ('calendarStyle', calendarStyle),
    ('wheelPickerStyle', wheelPickerStyle),
    ('colorPickerStyle', colorPickerStyle),
    ('popoverStyle', popoverStyle),
    ('tooltipStyle', tooltipStyle),
    ('sliderStyle', sliderStyle),
    ('chipStyle', chipStyle),
    ('ratingStyle', ratingStyle),
    ('fileDropStyle', fileDropStyle),
    ('breadcrumbStyle', breadcrumbStyle),
    ('paginationStyle', paginationStyle),
    ('stepProgressStyle', stepProgressStyle),
    ('pageDotsStyle', pageDotsStyle),
    ('menuBarStyle', menuBarStyle),
    ('commandPaletteStyle', commandPaletteStyle),
  ];

  @override
  bool operator ==(Object other) =>
      other is BrutalThemeData &&
      other.colors == colors &&
      other.textTheme == textTheme &&
      other.typeface == typeface &&
      other.density == density &&
      other.borderWidth == borderWidth &&
      other.shadowOffset == shadowOffset &&
      listEquals(
        [for (final (_, s) in other._partStyles) s],
        [for (final (_, s) in _partStyles) s],
      );

  @override
  int get hashCode => Object.hash(
    colors,
    textTheme,
    typeface,
    density,
    borderWidth,
    shadowOffset,
    Object.hashAll([for (final (_, s) in _partStyles) s]),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<BrutalColors>('colors', colors))
      ..add(DiagnosticsProperty<BrutalTextTheme>('textTheme', textTheme))
      ..add(DiagnosticsProperty<BrutalTypeface>('typeface', typeface))
      ..add(DiagnosticsProperty<BrutalDensity>('density', density))
      ..add(DoubleProperty('borderWidth', borderWidth))
      ..add(DoubleProperty('shadowOffset', shadowOffset))
      ..add(DoubleProperty('controlHeight', controlHeight));
    for (final (name, style) in _partStyles) {
      properties.add(
        DiagnosticsProperty<BrutalStyle>(name, style, defaultValue: null),
      );
    }
  }
}

/// Installs Brutal below it: the theme every part reads, the default words
/// and icons, the 4 px grid, and the tap floors (40 for a finger, 24 for a
/// pointer). Put it once in any app's `builder:`, under `MaterialApp`,
/// `CupertinoApp` or `WidgetsApp`.
///
/// ```dart
/// MaterialApp(builder: (context, child) => BrutalTheme(data: BrutalThemeData.raw(MediaQuery.platformBrightnessOf(context)), child: child!), home: const HomePage())
/// ```
class BrutalTheme extends StatelessWidget {
  /// Brutal in [data] for [child].
  const BrutalTheme({super.key, required this.data, required this.child});

  /// The theme.
  final BrutalThemeData data;

  /// What wears it.
  final Widget child;

  /// The tap floors every Brutal control stands at: 40 by 40 for a finger,
  /// 24 by 24 for a pointer ([BrutalChromeMetrics.touchTarget] and
  /// [BrutalChromeMetrics.pointerTarget]).
  static const RawTapTargets tapTargets = RawTapTargets.fallback;

  static final BrutalThemeData _fallback = BrutalThemeData.light();

  /// The theme above [context], or the look by day when there is none, as
  /// `Theme.of` falls back to its default.
  static BrutalThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallback;

  /// The theme above [context], or null.
  static BrutalThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedBrutalTheme>()
      ?.theme
      .data;

  @override
  Widget build(BuildContext context) {
    final colors = data.colors;
    // The Material parts Brutal draws with inside (an editable's selection,
    // its handles) take the look's colours and stand at the look's own
    // density, never the platform's.
    final bridge = _bridges[data] ??= _materialUnder(colors, data.typeface);
    // The Theme stands over the app's navigator when BrutalTheme is in the
    // app's builder, so its routes change pages by this theme: Brutal's,
    // unless the app's own theme chose another.
    final outer = Theme.of(context).pageTransitionsTheme;
    final material =
        outer == const PageTransitionsTheme() ||
            outer == bridge.pageTransitionsTheme
        ? bridge
        : bridge.copyWith(pageTransitionsTheme: outer);
    Widget under = _InheritedBrutalTheme(
      theme: this,
      child: Theme(
        data: material,
        child: RawSpacingScope(
          // Brutal keeps ui_core's 4 px grid.
          spacing: RawSpacing.fallback,
          child: RawTapTargetScope(
            targets: tapTargets,
            child: DefaultSelectionStyle(
              cursorColor: colors.ink,
              selectionColor: colors.signal.withValues(alpha: 0.4),
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
    // Brutal's text field asks for the words of the Material library Brutal
    // is built on, and its menu on iOS for Cupertino's. An app with none of
    // either (a WidgetsApp, or an app whose words are another library's type,
    // as flutter_localizations' are) gets Brutal's own, never a throw; an app
    // that has them keeps its own. A Localizations sets the direction from its
    // locale: the app's own direction is kept.
    final missing = Localizations.maybeLocaleOf(context) == null
        ? const <LocalizationsDelegate<Object?>>[]
        : <LocalizationsDelegate<Object?>>[
            if (Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                ) ==
                null)
              const _MaterialWords(),
            if (Localizations.of<CupertinoLocalizations>(
                  context,
                  CupertinoLocalizations,
                ) ==
                null)
              const _CupertinoWords(),
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

  static final Expando<ThemeData> _bridges = Expando('BrutalTheme bridges');

  static ThemeData _materialUnder(
    BrutalColors colors,
    BrutalTypeface typeface,
  ) => ThemeData(
    brightness: colors.brightness,
    fontFamily: _familyOf(typeface),
    fontFamilyFallback: typeface.fallback.isEmpty ? null : typeface.fallback,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: brutalPageTransitions,
    ),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x00000000),
    splashColor: const Color(0x00000000),
    hoverColor: const Color(0x00000000),
    focusColor: const Color(0x00000000),
    scaffoldBackgroundColor: colors.paper,
    canvasColor: colors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.signal,
      brightness: colors.brightness,
      primary: colors.ink,
      onPrimary: colors.paper,
      surface: colors.paper,
      onSurface: colors.ink,
      error: colors.danger,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.ink,
      selectionColor: colors.signal.withValues(alpha: 0.4),
      selectionHandleColor: colors.ink,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BrutalThemeData>('data', data));
  }
}

class _InheritedBrutalTheme extends InheritedTheme {
  const _InheritedBrutalTheme({required this.theme, required super.child});

  final BrutalTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      BrutalTheme(data: theme.data, child: child);

  @override
  bool updateShouldNotify(_InheritedBrutalTheme old) =>
      theme.data != old.theme.data;
}

/// [BrutalTheme] that moves to a new [data] smoothly (day to night, one
/// density to another), as `AnimatedTheme` does; at once under Reduce
/// Motion.
///
/// ```dart
/// AnimatedBrutalTheme(data: night ? BrutalThemeData.dark() : BrutalThemeData.light(), child: page)
/// ```
class AnimatedBrutalTheme extends ImplicitlyAnimatedWidget {
  /// Animates to [data] whenever it changes.
  const AnimatedBrutalTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve = Curves.easeOut,
    super.duration = const Duration(milliseconds: 160),
    super.onEnd,
  });

  /// The theme to arrive at.
  final BrutalThemeData data;

  /// What wears it.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedBrutalTheme> createState() =>
      _AnimatedBrutalThemeState();
}

class _AnimatedBrutalThemeState
    extends AnimatedWidgetBaseState<AnimatedBrutalTheme> {
  _BrutalThemeTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => _BrutalThemeTween(begin: value as BrutalThemeData),
    ) as _BrutalThemeTween?;
  }

  @override
  Widget build(BuildContext context) => BrutalTheme(
    data: rawReduceMotionOf(context) ? widget.data : _data!.evaluate(animation),
    child: widget.child,
  );
}

class _BrutalThemeTween extends Tween<BrutalThemeData> {
  _BrutalThemeTween({super.begin});

  @override
  BrutalThemeData lerp(double t) => BrutalThemeData.lerp(begin!, end!, t);
}

/// Reads Brutal's theme from a [BuildContext].
extension BrutalThemeContext on BuildContext {
  /// [BrutalTheme.of] this context.
  BrutalThemeData get brutalTheme => BrutalTheme.of(this);
}

// The words of the Material and Cupertino libraries Brutal is built on, which
// BrutalTheme gives its parts (a text field's menu, its spoken hints) when the
// app gives none of those libraries' own: English in any locale.
class _MaterialWords extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_MaterialWords old) => false;
}

// Cupertino's, which a text field's menu on iOS reads.
class _CupertinoWords extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_CupertinoWords old) => false;
}

/// [typeface]'s family as it is registered: a package's face under
/// `packages/<package>/`. Styles take it as the family alone, with no
/// `package:`, which would read the typeface's fallbacks as faces of the same
/// package too, and an app's face behind the bundled one would never draw.
String _familyOf(BrutalTypeface typeface) => typeface.package == null
    ? typeface.family
    : 'packages/${typeface.package}/${typeface.family}';
