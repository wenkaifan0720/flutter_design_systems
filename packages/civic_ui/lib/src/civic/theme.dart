/// Civic's theme: its colours, its two type ramps, its spacing, motion and
/// tap floors, and the widget that puts them in scope.
library;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/platform_words.dart';

/// How a part of Civic looks: Civic's name for ui_core's [DesignStyle], ten
/// slots that each resolve for the part's states, as Material's
/// `ButtonStyle` does. A part reads its `style:` first, then its component
/// theme on [CivicThemeData], then Civic's own default.
///
/// ```dart
/// CivicButton(
///   style: CivicStyle(
///     padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)),
///   ),
///   onPressed: () {},
///   child: const Text('Continue'),
/// )
/// ```
typedef CivicStyle = DesignStyle;

/// What a status, a tag or a notice says about its subject: Civic's tones.
enum CivicTone {
  /// Nothing to report: not started, closed, a draft.
  neutral,

  /// Something is happening: in progress, received, under review.
  info,

  /// Done and well: completed, approved, paid.
  success,

  /// Look at this: action needed, due soon, expiring.
  warning,

  /// Something went wrong: rejected, overdue, failed.
  error,
}

/// Civic's spacing steps, on its 4 pt grid ([DesignSpacingScope] declares
/// it): tight inside a group, loose between groups.
abstract final class CivicSpacing {
  /// 4 pt: between a label's two lines of words, inside a tag.
  static const double s4 = 4;

  /// 8 pt: a label to its hint, a hint to its field.
  static const double s8 = 8;

  /// 12 pt: between the rows of a list of choices.
  static const double s12 = 12;

  /// 16 pt: inside a band; between paragraphs.
  static const double s16 = 16;

  /// 20 pt: the phone's page margin.
  static const double s20 = 20;

  /// 24 pt: between the fields of a form.
  static const double s24 = 24;

  /// 32 pt: before an action; the tablet's page margin.
  static const double s32 = 32;

  /// 40 pt: the desktop's page margin.
  static const double s40 = 40;

  /// 48 pt: between the sections of a page.
  static const double s48 = 48;

  /// 64 pt: before the end of a page.
  static const double s64 = 64;
}

/// Civic's page geometry: its window sizes, page margins and reading width.
abstract final class CivicLayout {
  /// Below this width a page is a phone's: one column, the navigation bar.
  static const double medium = 600;

  /// From this width a page is a desktop's: the side navigation and an aside.
  static const double expanded = 1024;

  /// Whether a window [width] wide shows a service as an app: narrower than
  /// [expanded] (a phone, a tablet held upright). An app's pages carry their
  /// way back and their place in their own top bar, the places along the
  /// bottom, their lists as rows on cards, and the page's action kept in
  /// reach at its foot. From [expanded] a service is its site: the
  /// masthead, the side navigation and the centred frame.
  static bool isApp(double width) => width < expanded;

  /// The longest measure of words and fields: about 70 characters of body
  /// text, the column a question, a form or an answers summary stands in.
  static const double readingWidth = 640;

  /// The widest a page's content grows, centred in a wider window.
  static const double maxContentWidth = 1200;

  /// The width of the side navigation from [medium] up.
  static const double sideNavigationWidth = 240;

  /// How far the side navigation's places stand from its start; a top bar
  /// over it starts its words there too.
  static const double sideNavigationInset = CivicSpacing.s20;

  /// The frame a page with no side navigation stands in, centred in a
  /// wider window: its top bar's words and its column start where it
  /// starts, as a public service's pages do.
  static const double pageWidth = 960;

  /// The most a page's heading grows with the reader's text size: half as
  /// large again, so its longest word still fits a phone's column (a
  /// heading already sets two and more times the body's size).
  static const double headingScaleMost = 1.5;

  /// The inset from a window [width] wide's start (and end) to the centred
  /// [pageWidth] frame, never less than the page's margin.
  static double frameInset(double width) {
    final margin = marginFor(width);
    final centred = (width - pageWidth) / 2;
    return centred > margin ? centred : margin;
  }

  /// Where a [CivicScaffold]'s side navigation stands from a window [width]
  /// wide's start: its places start where the centred frame starts, under
  /// the top bar's words, as a page with no side navigation starts its
  /// column; so the bar's words stand still from page to page.
  static double navigationOffset(double width) =>
      frameInset(width) - sideNavigationInset;

  /// The page margin for a window [width] wide: 20, 32 from [medium], 40
  /// from [expanded].
  static double marginFor(double width) => width >= expanded
      ? CivicSpacing.s40
      : width >= medium
      ? CivicSpacing.s32
      : CivicSpacing.s20;
}

/// One of Civic's springs: a damping ratio and a stiffness, as ui_core's
/// `designSpring` takes them.
typedef CivicSpring = ({double dampingRatio, double stiffness});

/// Civic's motion: critically damped springs, so nothing bounces or
/// lingers, at three speeds.
abstract final class CivicMotion {
  /// A press sinking and rising: quick.
  static const CivicSpring press = (dampingRatio: 1, stiffness: 1600);

  /// A keyboard focus arriving: all but at once (a frame in it stands
  /// between, a tenth of a second in it is there), so the yellow is seen
  /// whole, never a muddy half-way.
  static const CivicSpring focus = (dampingRatio: 1, stiffness: 6000);

  /// A control changing state (a check, a thumb, a selection bar).
  static const CivicSpring state = (dampingRatio: 1, stiffness: 900);

  /// A panel, a dialog or a menu opening or closing.
  static const CivicSpring panel = (dampingRatio: 1, stiffness: 500);
}

/// Civic's type: the steps every part and page takes its words from.
///
/// Civic has two ramps, as public-service pages set type: a phone's
/// ([CivicThemeData.compactText]) and the wider window's
/// ([CivicThemeData.text]); [CivicTheme.textOf] picks by the window's width.
@immutable
final class CivicTextTheme with Diagnosticable {
  /// A ramp from its steps.
  const CivicTextTheme({
    required this.headingXL,
    required this.headingL,
    required this.headingM,
    required this.headingS,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.caption,
    required this.button,
    required this.code,
    this.capHeight = atkinsonCapHeight,
  });

  /// Civic's ramp in [ink] with [secondary] for the quiet steps; [wide] for
  /// windows from [CivicLayout.medium] up.
  ///
  /// [fontFamily] sets the face (from [fontPackage] when a package bundles
  /// it): Atkinson Hyperlegible Next when null. Any face that tells its
  /// letters apart keeps the look (a hyperlegible-class face, or one for a
  /// script Atkinson lacks); give its [capHeight] so words sit in the
  /// middle of a box. Codes keep Atkinson Hyperlegible Mono.
  factory CivicTextTheme.standard({
    required Color ink,
    required Color secondary,
    bool wide = false,
    String? fontFamily,
    String? fontPackage,
    double capHeight = atkinsonCapHeight,
  }) {
    TextStyle face(double size, double height, FontWeight weight, Color c) =>
        TextStyle(
          inherit: false,
          fontFamily: fontFamily ?? 'AtkinsonNext',
          package: fontFamily == null ? civicFontPackage : fontPackage,
          fontFamilyFallback: const ['NotoSansArabic'],
          fontSize: size,
          height: height,
          fontWeight: weight,
          color: c,
          leadingDistribution: TextLeadingDistribution.even,
          textBaseline: TextBaseline.alphabetic,
          decoration: TextDecoration.none,
        );
    const bold = FontWeight.w700;
    const regular = FontWeight.w400;
    return CivicTextTheme(
      headingXL: face(wide ? 44 : 32, wide ? 1.12 : 1.16, bold, ink),
      headingL: face(wide ? 34 : 27, 1.18, bold, ink),
      headingM: face(wide ? 24 : 21, 1.25, bold, ink),
      headingS: face(wide ? 19 : 18, 1.32, bold, ink),
      body: face(wide ? 19 : 18, 1.45, regular, ink),
      bodySmall: face(16, 1.4, regular, secondary),
      label: face(wide ? 19 : 18, 1.32, bold, ink),
      caption: face(wide ? 19 : 17, 1.3, regular, secondary),
      button: face(wide ? 19 : 18, 1.2, bold, ink),
      capHeight: capHeight,
      code: TextStyle(
        inherit: false,
        fontFamily: 'AtkinsonMono',
        package: civicFontPackage,
        fontSize: wide ? 22 : 20,
        height: 1.3,
        fontWeight: bold,
        color: ink,
        letterSpacing: 1,
        leadingDistribution: TextLeadingDistribution.even,
        textBaseline: TextBaseline.alphabetic,
        decoration: TextDecoration.none,
      ),
    );
  }

  /// A page's question or its one title.
  final TextStyle headingXL;

  /// A page's title where it is not the question; a confirmation's title.
  final TextStyle headingL;

  /// A section of a page.
  final TextStyle headingM;

  /// A group inside a section; a row's title.
  final TextStyle headingS;

  /// What people read.
  final TextStyle body;

  /// What supports it: a row's second line, small print.
  final TextStyle bodySmall;

  /// Bold words that name what follows: a key in an answers summary, an
  /// error message, the answer chosen in an open list. A field's own label
  /// is in [body]'s weight, so the question over it reads first.
  final TextStyle label;

  /// A hint, a step count over a heading.
  final TextStyle caption;

  /// A button's words.
  final TextStyle button;

  /// A reference number or a code: every character told apart.
  final TextStyle code;

  /// The face's capitals as a share of its size, which centres words in a
  /// box (`DesignCapCenter`).
  final double capHeight;

  /// Atkinson Hyperlegible Next's [capHeight].
  static const double atkinsonCapHeight = 0.668;

  /// This ramp with the given steps changed.
  CivicTextTheme copyWith({
    TextStyle? headingXL,
    TextStyle? headingL,
    TextStyle? headingM,
    TextStyle? headingS,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? button,
    TextStyle? code,
    double? capHeight,
  }) => CivicTextTheme(
    headingXL: headingXL ?? this.headingXL,
    headingL: headingL ?? this.headingL,
    headingM: headingM ?? this.headingM,
    headingS: headingS ?? this.headingS,
    body: body ?? this.body,
    bodySmall: bodySmall ?? this.bodySmall,
    label: label ?? this.label,
    caption: caption ?? this.caption,
    button: button ?? this.button,
    code: code ?? this.code,
    capHeight: capHeight ?? this.capHeight,
  );

  /// Between [a] and [b], step by step.
  static CivicTextTheme lerp(CivicTextTheme a, CivicTextTheme b, double t) {
    if (identical(a, b)) return a;
    TextStyle s(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return CivicTextTheme(
      headingXL: s(a.headingXL, b.headingXL),
      headingL: s(a.headingL, b.headingL),
      headingM: s(a.headingM, b.headingM),
      headingS: s(a.headingS, b.headingS),
      body: s(a.body, b.body),
      bodySmall: s(a.bodySmall, b.bodySmall),
      label: s(a.label, b.label),
      caption: s(a.caption, b.caption),
      button: s(a.button, b.button),
      code: s(a.code, b.code),
      capHeight: a.capHeight + (b.capHeight - a.capHeight) * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CivicTextTheme &&
      other.headingXL == headingXL &&
      other.headingL == headingL &&
      other.headingM == headingM &&
      other.headingS == headingS &&
      other.body == body &&
      other.bodySmall == bodySmall &&
      other.label == label &&
      other.caption == caption &&
      other.button == button &&
      other.code == code &&
      other.capHeight == capHeight;

  @override
  int get hashCode => Object.hash(
    headingXL,
    headingL,
    headingM,
    headingS,
    body,
    bodySmall,
    label,
    caption,
    button,
    code,
    capHeight,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final (name, style) in [
      ('headingXL', headingXL),
      ('headingL', headingL),
      ('headingM', headingM),
      ('headingS', headingS),
      ('body', body),
      ('bodySmall', bodySmall),
      ('label', label),
      ('caption', caption),
      ('button', button),
      ('code', code),
    ]) {
      properties.add(DiagnosticsProperty<TextStyle>(name, style));
    }
    properties.add(DoubleProperty('capHeight', capHeight));
  }
}

/// Civic's design tokens, as Flutter's `ThemeData`: immutable, with
/// [copyWith], [lerp] and value equality, and presets as named factories.
///
/// ```dart
/// final theme = CivicThemeData.light();
/// final mine = CivicThemeData.from(
///   brightness: Brightness.light,
///   action: const Color(0xFF00594C),
/// );
/// ```
@immutable
final class CivicThemeData with Diagnosticable {
  /// A theme from every token. Most apps take [CivicThemeData.light],
  /// [CivicThemeData.dark] or [CivicThemeData.from].
  const CivicThemeData({
    required this.brightness,
    required this.ground,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.action,
    required this.onAction,
    required this.actionEdge,
    required this.secondaryFill,
    required this.onSecondary,
    required this.secondaryEdge,
    required this.danger,
    required this.onDanger,
    required this.dangerEdge,
    required this.success,
    required this.onSuccess,
    required this.border,
    required this.rule,
    required this.focus,
    required this.onFocus,
    required this.disabledFill,
    required this.tones,
    required this.text,
    required this.compactText,
    this.tapTargets = const DesignTapTargets(
      touch: Size.square(48),
      pointer: Size.square(24),
    ),
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
    this.startButtonStyle,
    this.destructiveButtonStyle,
    this.iconButtonStyle,
    this.linkStyle,
    this.textFieldStyle,
    this.searchButtonStyle,
    this.selectStyle,
    this.checkboxStyle,
    this.radioStyle,
    this.switchStyle,
    this.tabStyle,
    this.navigationStyle,
    this.topBarStyle,
    this.paginationStyle,
    this.listRowStyle,
    this.tagStyle,
    this.detailsStyle,
    this.tableStyle,
    this.summaryListStyle,
    this.timelineStyle,
    this.insetStyle,
    this.panelStyle,
    this.bannerStyle,
    this.errorSummaryStyle,
    this.dialogStyle,
    this.toastStyle,
    this.toggleStyle,
    this.chipStyle,
    this.sliderStyle,
    this.ratingStyle,
    this.calendarStyle,
    this.wheelPickerStyle,
    this.colorPickerStyle,
    this.kbdStyle,
    this.menuStyle,
    this.popoverStyle,
    this.tooltipStyle,
    this.sheetStyle,
    this.commandPaletteStyle,
    this.cardStyle,
    this.accordionStyle,
    this.stepIndicatorStyle,
    this.pageDotsStyle,
    this.carouselStyle,
    this.scrollAreaStyle,
    this.splitViewStyle,
    this.reorderableListStyle,
    this.swipeActionsStyle,
    this.treeStyle,
    this.avatarStyle,
    this.badgeStyle,
    this.imageStyle,
    this.keyFigureStyle,
    this.spinnerStyle,
    this.progressBarStyle,
    this.skeletonStyle,
    this.meterStyle,
    this.chartStyle,
    this.pieChartStyle,
    this.pullToRefreshStyle,
    this.actionBarStyle,
  });

  /// Whether [targets] keep Civic's floors: 48 by 48 for a finger, 24 by 24
  /// for a pointer. [copyWith] and [CivicTheme] assert it.
  static bool floorsHold(DesignTapTargets targets) =>
      targets.touch.width >= 48 &&
      targets.touch.height >= 48 &&
      targets.pointer.width >= 24 &&
      targets.pointer.height >= 24;

  static const String _floorsMessage =
      "Civic's tap floors are 48 by 48 for a finger and 24 by 24 for a "
      'pointer: a target can grow, never shrink below them.';

  /// Civic by day: white cards on a cool blue-grey ground, ink words, one
  /// blue for action.
  factory CivicThemeData.light() =>
      CivicThemeData.from(brightness: Brightness.light);

  /// Civic by night, designed: slate cards on a deeper ground, light words,
  /// a light-blue action carrying dark words.
  factory CivicThemeData.dark() =>
      CivicThemeData.from(brightness: Brightness.dark);

  /// The preset named [id] ([presets]) by [brightness].
  factory CivicThemeData.preset(String id, Brightness brightness) {
    assert(presets.contains(id), 'Civic has no preset $id');
    return CivicThemeData.from(brightness: brightness);
  }

  /// Civic's presets, by id; the first is the default.
  static const List<String> presets = ['civic'];

  /// Civic from an app's own colours: [action] for buttons and links,
  /// [danger] for errors, [success] for what went well, [focus] for the
  /// focus plate; and its own face ([fontFamily], see
  /// [CivicTextTheme.standard]).
  ///
  /// Civic's words reach 7:1 against the page, so each of [action],
  /// [danger] and [success] is taken as a seed: one that falls short is
  /// darkened by day and lightened by night, keeping its hue, until it
  /// reaches 7:1 (#0A7D4F becomes about #086640 by day and #0FB673 by
  /// night). The words on a button's face are picked to reach 4.5:1 (they
  /// are large and bold). [focus] must carry ink words at 7:1: a debug
  /// assert names a plate that cannot.
  factory CivicThemeData.from({
    required Brightness brightness,
    Color? action,
    Color? danger,
    Color? success,
    Color? focus,
    String? fontFamily,
    String? fontPackage,
    double capHeight = CivicTextTheme.atkinsonCapHeight,
  }) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF1F3F5) : const Color(0xFF0C1116);
    final secondary = dark ? const Color(0xFFB8C0C7) : const Color(0xFF474F57);
    final page = dark ? const Color(0xFF151B20) : const Color(0xFFFFFFFF);
    // The ground pages stand on: a cool blue-grey by day, the deepest slate
    // by night; cards, fields and lists stand on it in the page's colour.
    final ground = dark ? const Color(0xFF0B0F12) : const Color(0xFFECF0F4);
    // Words stand on both: they are measured on the one they read worse on.
    final read = dark ? page : ground;
    final act = _wordsOn(
      read,
      action ?? (dark ? const Color(0xFF7DB8F2) : const Color(0xFF0F4C81)),
      dark,
    );
    final onAct = _onColor(act);
    final err = _wordsOn(
      read,
      danger ?? (dark ? const Color(0xFFFF9A8F) : const Color(0xFFA8180C)),
      dark,
    );
    final ok = _wordsOn(
      read,
      success ?? (dark ? const Color(0xFF7FD6A2) : const Color(0xFF0B6136)),
      dark,
    );
    const onPlate = Color(0xFF0C1116);
    final plate = focus ?? const Color(0xFFFFD21F);
    assert(
      [act, err, ok].every(
        (c) => contrastRatio(c, page) >= 7 && contrastRatio(c, ground) >= 7,
      ),
      "Civic's words reach 7:1 against the page and its ground.",
    );
    assert(
      contrastRatio(plate, onPlate) >= 7,
      "Civic's focus plate carries ink words at 7:1: "
      '$plate reaches ${contrastRatio(plate, onPlate).toStringAsFixed(2)}:1 '
      'with ink. Take a lighter, warmer plate.',
    );
    // A secondary button's face: the action's own tint, no stroke round it.
    final tint = Color.alphaBlend(
      act.withValues(alpha: dark ? 0.2 : 0.13),
      page,
    );
    return CivicThemeData(
      brightness: brightness,
      ground: ground,
      background: page,
      surface: dark ? const Color(0xFF1E262C) : const Color(0xFFF0F2F4),
      textPrimary: ink,
      textSecondary: secondary,
      textDisabled: dark ? const Color(0xFF7D868E) : const Color(0xFF6B7178),
      action: act,
      onAction: onAct,
      actionEdge: _edgeOf(act, dark),
      // The secondary button: a face of the action's tint with its words in
      // the action colour, on a deeper tint's edge: a button by its shape,
      // its seat and its edge, as the primary is, quieter than it, and never
      // a box drawn round words (no stroke) nor a link (it has a face).
      secondaryFill: tint,
      onSecondary: act,
      secondaryEdge: Color.alphaBlend(
        act.withValues(alpha: dark ? 0.45 : 0.4),
        page,
      ),
      danger: err,
      onDanger: _onColor(err),
      dangerEdge: _edgeOf(err, dark),
      success: ok,
      onSuccess: _onColor(ok),
      border: dark ? const Color(0xFFC9D0D6) : const Color(0xFF0C1116),
      rule: dark ? const Color(0xFF3F484F) : const Color(0xFFB4B8BC),
      focus: plate,
      onFocus: onPlate,
      disabledFill: dark ? const Color(0xFF222A30) : const Color(0xFFE3E5E7),
      tones: dark ? _darkTones : _lightTones,
      text: CivicTextTheme.standard(
        ink: ink,
        secondary: secondary,
        wide: true,
        fontFamily: fontFamily,
        fontPackage: fontPackage,
        capHeight: capHeight,
      ),
      compactText: CivicTextTheme.standard(
        ink: ink,
        secondary: secondary,
        fontFamily: fontFamily,
        fontPackage: fontPackage,
        capHeight: capHeight,
      ),
    );
  }

  static const Map<CivicTone, (Color, Color)> _lightTones = {
    CivicTone.neutral: (Color(0xFFE8EAEC), Color(0xFF2E3338)),
    CivicTone.info: (Color(0xFFDCE9F6), Color(0xFF0B3B66)),
    CivicTone.success: (Color(0xFFD9EFE2), Color(0xFF0A4D2A)),
    CivicTone.warning: (Color(0xFFFFF1B8), Color(0xFF5C4300)),
    CivicTone.error: (Color(0xFFF7DCD8), Color(0xFF7A1209)),
  };

  static const Map<CivicTone, (Color, Color)> _darkTones = {
    CivicTone.neutral: (Color(0xFF2A3238), Color(0xFFE1E5E8)),
    CivicTone.info: (Color(0xFF15324E), Color(0xFFBFDDFF)),
    CivicTone.success: (Color(0xFF123A26), Color(0xFFB4EBC9)),
    CivicTone.warning: (Color(0xFF3D3104), Color(0xFFFFE58A)),
    CivicTone.error: (Color(0xFF4A1612), Color(0xFFFFC7C0)),
  };

  /// The words on a face of [c]: white or the deep ink, whichever reads
  /// better; a button's words are large and bold, so 4.5:1 is AAA for them.
  static Color _onColor(Color c) {
    const white = Color(0xFFFFFFFF);
    const deep = Color(0xFF0A1A2B);
    final on = contrastRatio(c, white) >= contrastRatio(c, deep) ? white : deep;
    assert(
      contrastRatio(c, on) >= 4.5,
      'Words on $c reach only ${contrastRatio(c, on).toStringAsFixed(2)}:1.',
    );
    return on;
  }

  /// [seed], or the nearest tone of its hue that reads at 7:1 on [page]:
  /// darker by day, lighter by night.
  static Color _wordsOn(Color page, Color seed, bool dark) {
    if (contrastRatio(seed, page) >= 7) return seed;
    final hsl = HSLColor.fromColor(seed);
    // The tone runs from the seed's lightness toward black by day, white
    // by night; the first that reaches 7:1 is the one nearest the seed.
    var near = hsl.lightness;
    var far = dark ? 1.0 : 0.0;
    for (var i = 0; i < 24; i++) {
      final mid = (near + far) / 2;
      if (contrastRatio(hsl.withLightness(mid).toColor(), page) >= 7) {
        far = mid;
      } else {
        near = mid;
      }
    }
    // The channels round to 8 bits: a step on where that fell just short.
    var tone = hsl.withLightness(far).toColor();
    while (contrastRatio(tone, page) < 7 && far > 0 && far < 1) {
      far = (far + (dark ? 0.004 : -0.004)).clamp(0.0, 1.0);
      tone = hsl.withLightness(far).toColor();
    }
    return tone.withValues(alpha: seed.a);
  }

  /// WCAG's contrast ratio between [a] and [b], 1 to 21.
  static double contrastRatio(Color a, Color b) {
    final x = a.computeLuminance();
    final y = b.computeLuminance();
    return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
  }

  /// The solid edge under a button of [c]: darker by day, deeper by night.
  static Color _edgeOf(Color c, bool dark) {
    final hsl = HSLColor.fromColor(c);
    // By night a light face stands on a deep, quieter edge: darker than the
    // face and less saturated, never a brighter line under it, yet 3:1
    // against the night page, so the base still reads.
    return hsl
        .withLightness((hsl.lightness * (dark ? 0.55 : 0.68)).clamp(0, 1))
        .withSaturation((hsl.saturation * (dark ? 0.7 : 1)).clamp(0, 1))
        .toColor();
  }

  /// Light or dark.
  final Brightness brightness;

  /// The ground pages stand on, behind their cards: a cool blue-grey by
  /// day, the deepest slate by night.
  final Color ground;

  /// The hairline between the rows of a card: the [rule], halfway to the
  /// card's face, so rows read as one card and never as boxes.
  Color get hairline => Color.lerp(rule, background, 0.5)!;

  /// A card's, a field's, a list's and a dialog's face, on the [ground].
  final Color background;

  /// The band a part sinks into: a pressed row, a hint's well, the inset.
  final Color surface;

  /// Words people read, and every field's and box's ink.
  final Color textPrimary;

  /// Hints, captions and second lines, still at 7:1 on the page.
  final Color textSecondary;

  /// Words of a part that cannot be used now.
  final Color textDisabled;

  /// The one colour for action: buttons and links.
  final Color action;

  /// Words on [action].
  final Color onAction;

  /// The solid edge under an action button, which a press sinks onto.
  final Color actionEdge;

  /// A secondary button's face.
  final Color secondaryFill;

  /// Words on [secondaryFill].
  final Color onSecondary;

  /// The solid edge under a secondary button.
  final Color secondaryEdge;

  /// Errors: their words, their rule, a destructive button's face.
  final Color danger;

  /// Words on [danger].
  final Color onDanger;

  /// The solid edge under a destructive button.
  final Color dangerEdge;

  /// What went well: a confirmation panel, a success notice's rule.
  final Color success;

  /// Words on [success].
  final Color onSuccess;

  /// A field's and a box's 2 pt edge.
  final Color border;

  /// A hairline between rows and sections.
  final Color rule;

  /// The focus plate: what floods a focused part.
  final Color focus;

  /// The dark ink used for words on the focus plate.
  final Color onFocus;

  /// The bar beneath the focus plate uses the same ink in both themes.
  Color get focusBar => onFocus;

  /// A part's face when it cannot be used.
  final Color disabledFill;

  /// Each tone's ground and words, for tags and statuses.
  final Map<CivicTone, (Color, Color)> tones;

  /// The type ramp from [CivicLayout.medium] up.
  final CivicTextTheme text;

  /// The type ramp of a phone.
  final CivicTextTheme compactText;

  /// A page's heading on a phone's ramp: what a page that has only the
  /// theme writes (`Text(title, style: t.h1)`). One that knows its window
  /// reads `context.civicText.headingXL`, which grows from 600 wide.
  TextStyle get h1 => compactText.headingXL;

  /// Body words on a phone's ramp, as [h1] is the heading;
  /// `context.civicText.body` follows the window.
  TextStyle get body => compactText.body;

  /// The floors a tap reaches: 48 for a finger, 24 for a pointer. They can
  /// rise, never fall (an assert holds them): a large target is the look.
  final DesignTapTargets tapTargets;

  /// [CivicButton]'s component theme: the page's one action.
  final CivicStyle? primaryButtonStyle;

  /// [CivicButton.secondary]'s component theme, and the file upload's button's.
  final CivicStyle? secondaryButtonStyle;

  /// [CivicButton.start]'s component theme.
  final CivicStyle? startButtonStyle;

  /// The component theme of a [CivicButton] with `isDestructiveAction`.
  final CivicStyle? destructiveButtonStyle;

  /// [CivicIconButton]'s component theme.
  final CivicStyle? iconButtonStyle;

  /// [CivicLink]'s and [CivicBackLink]'s component theme, and the links of
  /// [CivicBreadcrumbs].
  final CivicStyle? linkStyle;

  /// [CivicTextField]'s component theme, and the boxes of [CivicDateInput],
  /// [CivicPasswordField], [CivicSearchField] and [CivicCombobox].
  final CivicStyle? textFieldStyle;

  /// [CivicSearchField]'s search button's component theme.
  final CivicStyle? searchButtonStyle;

  /// [CivicSelect]'s component theme.
  final CivicStyle? selectStyle;

  /// [CivicCheckbox]'s component theme.
  final CivicStyle? checkboxStyle;

  /// [CivicRadio]'s component theme.
  final CivicStyle? radioStyle;

  /// [CivicSwitch]'s component theme.
  final CivicStyle? switchStyle;

  /// [CivicTabBar]'s component theme.
  final CivicStyle? tabStyle;

  /// [CivicNavigationBar]'s and [CivicSideNavigation]'s component theme.
  final CivicStyle? navigationStyle;

  /// [CivicTopBar]'s component theme.
  final CivicStyle? topBarStyle;

  /// [CivicPagination]'s page numbers' component theme.
  final CivicStyle? paginationStyle;

  /// [CivicListRow]'s component theme.
  final CivicStyle? listRowStyle;

  /// [CivicTag]'s component theme.
  final CivicStyle? tagStyle;

  /// [CivicDetails]'s component theme.
  final CivicStyle? detailsStyle;

  /// [CivicTable]'s component theme.
  final CivicStyle? tableStyle;

  /// [CivicSummaryList]'s and [CivicSummaryCard]'s component theme.
  final CivicStyle? summaryListStyle;

  /// [CivicTimeline]'s component theme.
  final CivicStyle? timelineStyle;

  /// [CivicInset]'s and [CivicWarning]'s component theme.
  final CivicStyle? insetStyle;

  /// [CivicConfirmationPanel]'s component theme.
  final CivicStyle? panelStyle;

  /// [CivicNotificationBanner]'s component theme.
  final CivicStyle? bannerStyle;

  /// [CivicErrorSummary]'s component theme.
  final CivicStyle? errorSummaryStyle;

  /// [CivicDialog]'s component theme.
  final CivicStyle? dialogStyle;

  /// The toast's component theme ([CivicToast]).
  final CivicStyle? toastStyle;

  /// [CivicToggleGroup]'s and [CivicSegmentedControl]'s component theme.
  final CivicStyle? toggleStyle;

  /// [CivicChip]'s component theme.
  final CivicStyle? chipStyle;

  /// [CivicSlider]'s and [CivicRangeSlider]'s component theme.
  final CivicStyle? sliderStyle;

  /// [CivicRating]'s component theme.
  final CivicStyle? ratingStyle;

  /// [CivicCalendar]'s component theme, and the calendar a [CivicDatePicker] or a [CivicDateRangePicker] opens.
  final CivicStyle? calendarStyle;

  /// [CivicWheelPicker]'s component theme.
  final CivicStyle? wheelPickerStyle;

  /// [CivicColorPicker]'s component theme.
  final CivicStyle? colorPickerStyle;

  /// [CivicKbd]'s component theme.
  final CivicStyle? kbdStyle;

  /// [CivicMenu]'s and [CivicSplitButton]'s menu: its panel and rows.
  final CivicStyle? menuStyle;

  /// [CivicPopover]'s component theme.
  final CivicStyle? popoverStyle;

  /// [CivicTooltip]'s component theme.
  final CivicStyle? tooltipStyle;

  /// The sheets' component theme: [showCivicBottomSheet], [showCivicSideSheet] and [showCivicActionSheet].
  final CivicStyle? sheetStyle;

  /// [showCivicCommandPalette]'s component theme.
  final CivicStyle? commandPaletteStyle;

  /// [CivicCard]'s component theme.
  final CivicStyle? cardStyle;

  /// [CivicAccordion]'s component theme.
  final CivicStyle? accordionStyle;

  /// [CivicStepIndicator]'s component theme.
  final CivicStyle? stepIndicatorStyle;

  /// [CivicPageDots]'s component theme.
  final CivicStyle? pageDotsStyle;

  /// [CivicCarousel]'s component theme.
  final CivicStyle? carouselStyle;

  /// [CivicScrollArea]'s component theme.
  final CivicStyle? scrollAreaStyle;

  /// [CivicSplitView]'s component theme.
  final CivicStyle? splitViewStyle;

  /// [CivicReorderableList]'s component theme.
  final CivicStyle? reorderableListStyle;

  /// [CivicSwipeActions]'s component theme.
  final CivicStyle? swipeActionsStyle;

  /// [CivicTree]'s component theme.
  final CivicStyle? treeStyle;

  /// [CivicAvatar] and [CivicAvatarGroup]'s component theme.
  final CivicStyle? avatarStyle;

  /// [CivicBadge]'s component theme.
  final CivicStyle? badgeStyle;

  /// [CivicImage]'s component theme.
  final CivicStyle? imageStyle;

  /// [CivicKeyFigure]'s component theme.
  final CivicStyle? keyFigureStyle;

  /// [CivicSpinner]'s component theme.
  final CivicStyle? spinnerStyle;

  /// [CivicProgressBar]'s component theme.
  final CivicStyle? progressBarStyle;

  /// [CivicSkeleton]'s component theme.
  final CivicStyle? skeletonStyle;

  /// [CivicMeter]'s component theme.
  final CivicStyle? meterStyle;

  /// [CivicLineChart], [CivicBarChart], [CivicAreaChart] and [CivicSparkline]'s component theme.
  final CivicStyle? chartStyle;

  /// [CivicPieChart]'s component theme.
  final CivicStyle? pieChartStyle;

  /// [CivicPullToRefresh]'s component theme.
  final CivicStyle? pullToRefreshStyle;

  /// [CivicActionBar]'s component theme.
  final CivicStyle? actionBarStyle;

  /// Whether this is the night theme.
  bool get isDark => brightness == Brightness.dark;

  /// [tone]'s ground and words.
  (Color, Color) toneOf(CivicTone tone) => tones[tone]!;

  /// This theme with the given tokens changed.
  CivicThemeData copyWith({
    Brightness? brightness,
    Color? ground,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? action,
    Color? onAction,
    Color? actionEdge,
    Color? secondaryFill,
    Color? onSecondary,
    Color? secondaryEdge,
    Color? danger,
    Color? onDanger,
    Color? dangerEdge,
    Color? success,
    Color? onSuccess,
    Color? border,
    Color? rule,
    Color? focus,
    Color? onFocus,
    Color? disabledFill,
    Map<CivicTone, (Color, Color)>? tones,
    CivicTextTheme? text,
    CivicTextTheme? compactText,
    DesignTapTargets? tapTargets,
    CivicStyle? primaryButtonStyle,
    CivicStyle? secondaryButtonStyle,
    CivicStyle? startButtonStyle,
    CivicStyle? destructiveButtonStyle,
    CivicStyle? iconButtonStyle,
    CivicStyle? linkStyle,
    CivicStyle? textFieldStyle,
    CivicStyle? searchButtonStyle,
    CivicStyle? selectStyle,
    CivicStyle? checkboxStyle,
    CivicStyle? radioStyle,
    CivicStyle? switchStyle,
    CivicStyle? tabStyle,
    CivicStyle? navigationStyle,
    CivicStyle? topBarStyle,
    CivicStyle? paginationStyle,
    CivicStyle? listRowStyle,
    CivicStyle? tagStyle,
    CivicStyle? detailsStyle,
    CivicStyle? tableStyle,
    CivicStyle? summaryListStyle,
    CivicStyle? timelineStyle,
    CivicStyle? insetStyle,
    CivicStyle? panelStyle,
    CivicStyle? bannerStyle,
    CivicStyle? errorSummaryStyle,
    CivicStyle? dialogStyle,
    CivicStyle? toastStyle,
    CivicStyle? toggleStyle,
    CivicStyle? chipStyle,
    CivicStyle? sliderStyle,
    CivicStyle? ratingStyle,
    CivicStyle? calendarStyle,
    CivicStyle? wheelPickerStyle,
    CivicStyle? colorPickerStyle,
    CivicStyle? kbdStyle,
    CivicStyle? menuStyle,
    CivicStyle? popoverStyle,
    CivicStyle? tooltipStyle,
    CivicStyle? sheetStyle,
    CivicStyle? commandPaletteStyle,
    CivicStyle? cardStyle,
    CivicStyle? accordionStyle,
    CivicStyle? stepIndicatorStyle,
    CivicStyle? pageDotsStyle,
    CivicStyle? carouselStyle,
    CivicStyle? scrollAreaStyle,
    CivicStyle? splitViewStyle,
    CivicStyle? reorderableListStyle,
    CivicStyle? swipeActionsStyle,
    CivicStyle? treeStyle,
    CivicStyle? avatarStyle,
    CivicStyle? badgeStyle,
    CivicStyle? imageStyle,
    CivicStyle? keyFigureStyle,
    CivicStyle? spinnerStyle,
    CivicStyle? progressBarStyle,
    CivicStyle? skeletonStyle,
    CivicStyle? meterStyle,
    CivicStyle? chartStyle,
    CivicStyle? pieChartStyle,
    CivicStyle? pullToRefreshStyle,
    CivicStyle? actionBarStyle,
  }) {
    assert(tapTargets == null || floorsHold(tapTargets), _floorsMessage);
    return CivicThemeData(
      brightness: brightness ?? this.brightness,
      ground: ground ?? this.ground,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      action: action ?? this.action,
      onAction: onAction ?? this.onAction,
      actionEdge: actionEdge ?? this.actionEdge,
      secondaryFill: secondaryFill ?? this.secondaryFill,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryEdge: secondaryEdge ?? this.secondaryEdge,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerEdge: dangerEdge ?? this.dangerEdge,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      border: border ?? this.border,
      rule: rule ?? this.rule,
      focus: focus ?? this.focus,
      onFocus: onFocus ?? this.onFocus,
      disabledFill: disabledFill ?? this.disabledFill,
      tones: tones ?? this.tones,
      text: text ?? this.text,
      compactText: compactText ?? this.compactText,
      tapTargets: tapTargets ?? this.tapTargets,
      primaryButtonStyle: primaryButtonStyle ?? this.primaryButtonStyle,
      secondaryButtonStyle: secondaryButtonStyle ?? this.secondaryButtonStyle,
      startButtonStyle: startButtonStyle ?? this.startButtonStyle,
      destructiveButtonStyle:
          destructiveButtonStyle ?? this.destructiveButtonStyle,
      iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
      linkStyle: linkStyle ?? this.linkStyle,
      textFieldStyle: textFieldStyle ?? this.textFieldStyle,
      searchButtonStyle: searchButtonStyle ?? this.searchButtonStyle,
      selectStyle: selectStyle ?? this.selectStyle,
      checkboxStyle: checkboxStyle ?? this.checkboxStyle,
      radioStyle: radioStyle ?? this.radioStyle,
      switchStyle: switchStyle ?? this.switchStyle,
      tabStyle: tabStyle ?? this.tabStyle,
      navigationStyle: navigationStyle ?? this.navigationStyle,
      topBarStyle: topBarStyle ?? this.topBarStyle,
      paginationStyle: paginationStyle ?? this.paginationStyle,
      listRowStyle: listRowStyle ?? this.listRowStyle,
      tagStyle: tagStyle ?? this.tagStyle,
      detailsStyle: detailsStyle ?? this.detailsStyle,
      tableStyle: tableStyle ?? this.tableStyle,
      summaryListStyle: summaryListStyle ?? this.summaryListStyle,
      timelineStyle: timelineStyle ?? this.timelineStyle,
      insetStyle: insetStyle ?? this.insetStyle,
      panelStyle: panelStyle ?? this.panelStyle,
      bannerStyle: bannerStyle ?? this.bannerStyle,
      errorSummaryStyle: errorSummaryStyle ?? this.errorSummaryStyle,
      dialogStyle: dialogStyle ?? this.dialogStyle,
      toastStyle: toastStyle ?? this.toastStyle,
      toggleStyle: toggleStyle ?? this.toggleStyle,
      chipStyle: chipStyle ?? this.chipStyle,
      sliderStyle: sliderStyle ?? this.sliderStyle,
      ratingStyle: ratingStyle ?? this.ratingStyle,
      calendarStyle: calendarStyle ?? this.calendarStyle,
      wheelPickerStyle: wheelPickerStyle ?? this.wheelPickerStyle,
      colorPickerStyle: colorPickerStyle ?? this.colorPickerStyle,
      kbdStyle: kbdStyle ?? this.kbdStyle,
      menuStyle: menuStyle ?? this.menuStyle,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      tooltipStyle: tooltipStyle ?? this.tooltipStyle,
      sheetStyle: sheetStyle ?? this.sheetStyle,
      commandPaletteStyle: commandPaletteStyle ?? this.commandPaletteStyle,
      cardStyle: cardStyle ?? this.cardStyle,
      accordionStyle: accordionStyle ?? this.accordionStyle,
      stepIndicatorStyle: stepIndicatorStyle ?? this.stepIndicatorStyle,
      pageDotsStyle: pageDotsStyle ?? this.pageDotsStyle,
      carouselStyle: carouselStyle ?? this.carouselStyle,
      scrollAreaStyle: scrollAreaStyle ?? this.scrollAreaStyle,
      splitViewStyle: splitViewStyle ?? this.splitViewStyle,
      reorderableListStyle: reorderableListStyle ?? this.reorderableListStyle,
      swipeActionsStyle: swipeActionsStyle ?? this.swipeActionsStyle,
      treeStyle: treeStyle ?? this.treeStyle,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      badgeStyle: badgeStyle ?? this.badgeStyle,
      imageStyle: imageStyle ?? this.imageStyle,
      keyFigureStyle: keyFigureStyle ?? this.keyFigureStyle,
      spinnerStyle: spinnerStyle ?? this.spinnerStyle,
      progressBarStyle: progressBarStyle ?? this.progressBarStyle,
      skeletonStyle: skeletonStyle ?? this.skeletonStyle,
      meterStyle: meterStyle ?? this.meterStyle,
      chartStyle: chartStyle ?? this.chartStyle,
      pieChartStyle: pieChartStyle ?? this.pieChartStyle,
      pullToRefreshStyle: pullToRefreshStyle ?? this.pullToRefreshStyle,
      actionBarStyle: actionBarStyle ?? this.actionBarStyle,
    );
  }

  /// Between [a] and [b]: colours and type blend, the rest snaps at the
  /// middle.
  static CivicThemeData lerp(CivicThemeData a, CivicThemeData b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    final tones = {
      for (final tone in CivicTone.values)
        tone: (
          c(a.toneOf(tone).$1, b.toneOf(tone).$1),
          c(a.toneOf(tone).$2, b.toneOf(tone).$2),
        ),
    };
    return CivicThemeData(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      ground: c(a.ground, b.ground),
      background: c(a.background, b.background),
      surface: c(a.surface, b.surface),
      textPrimary: c(a.textPrimary, b.textPrimary),
      textSecondary: c(a.textSecondary, b.textSecondary),
      textDisabled: c(a.textDisabled, b.textDisabled),
      action: c(a.action, b.action),
      onAction: c(a.onAction, b.onAction),
      actionEdge: c(a.actionEdge, b.actionEdge),
      secondaryFill: c(a.secondaryFill, b.secondaryFill),
      onSecondary: c(a.onSecondary, b.onSecondary),
      secondaryEdge: c(a.secondaryEdge, b.secondaryEdge),
      danger: c(a.danger, b.danger),
      onDanger: c(a.onDanger, b.onDanger),
      dangerEdge: c(a.dangerEdge, b.dangerEdge),
      success: c(a.success, b.success),
      onSuccess: c(a.onSuccess, b.onSuccess),
      border: c(a.border, b.border),
      rule: c(a.rule, b.rule),
      focus: c(a.focus, b.focus),
      onFocus: c(a.onFocus, b.onFocus),
      disabledFill: c(a.disabledFill, b.disabledFill),
      tones: tones,
      text: CivicTextTheme.lerp(a.text, b.text, t),
      compactText: CivicTextTheme.lerp(a.compactText, b.compactText, t),
      tapTargets: t < 0.5 ? a.tapTargets : b.tapTargets,
      primaryButtonStyle: DesignStyle.lerp(
        a.primaryButtonStyle,
        b.primaryButtonStyle,
        t,
      ),
      secondaryButtonStyle: DesignStyle.lerp(
        a.secondaryButtonStyle,
        b.secondaryButtonStyle,
        t,
      ),
      startButtonStyle: DesignStyle.lerp(
        a.startButtonStyle,
        b.startButtonStyle,
        t,
      ),
      destructiveButtonStyle: DesignStyle.lerp(
        a.destructiveButtonStyle,
        b.destructiveButtonStyle,
        t,
      ),
      iconButtonStyle: DesignStyle.lerp(
        a.iconButtonStyle,
        b.iconButtonStyle,
        t,
      ),
      linkStyle: DesignStyle.lerp(a.linkStyle, b.linkStyle, t),
      textFieldStyle: DesignStyle.lerp(a.textFieldStyle, b.textFieldStyle, t),
      searchButtonStyle: DesignStyle.lerp(
        a.searchButtonStyle,
        b.searchButtonStyle,
        t,
      ),
      selectStyle: DesignStyle.lerp(a.selectStyle, b.selectStyle, t),
      checkboxStyle: DesignStyle.lerp(a.checkboxStyle, b.checkboxStyle, t),
      radioStyle: DesignStyle.lerp(a.radioStyle, b.radioStyle, t),
      switchStyle: DesignStyle.lerp(a.switchStyle, b.switchStyle, t),
      tabStyle: DesignStyle.lerp(a.tabStyle, b.tabStyle, t),
      navigationStyle: DesignStyle.lerp(
        a.navigationStyle,
        b.navigationStyle,
        t,
      ),
      topBarStyle: DesignStyle.lerp(a.topBarStyle, b.topBarStyle, t),
      paginationStyle: DesignStyle.lerp(
        a.paginationStyle,
        b.paginationStyle,
        t,
      ),
      listRowStyle: DesignStyle.lerp(a.listRowStyle, b.listRowStyle, t),
      tagStyle: DesignStyle.lerp(a.tagStyle, b.tagStyle, t),
      detailsStyle: DesignStyle.lerp(a.detailsStyle, b.detailsStyle, t),
      tableStyle: DesignStyle.lerp(a.tableStyle, b.tableStyle, t),
      summaryListStyle: DesignStyle.lerp(
        a.summaryListStyle,
        b.summaryListStyle,
        t,
      ),
      timelineStyle: DesignStyle.lerp(a.timelineStyle, b.timelineStyle, t),
      insetStyle: DesignStyle.lerp(a.insetStyle, b.insetStyle, t),
      panelStyle: DesignStyle.lerp(a.panelStyle, b.panelStyle, t),
      bannerStyle: DesignStyle.lerp(a.bannerStyle, b.bannerStyle, t),
      errorSummaryStyle: DesignStyle.lerp(
        a.errorSummaryStyle,
        b.errorSummaryStyle,
        t,
      ),
      dialogStyle: DesignStyle.lerp(a.dialogStyle, b.dialogStyle, t),
      toastStyle: DesignStyle.lerp(a.toastStyle, b.toastStyle, t),
      toggleStyle: DesignStyle.lerp(a.toggleStyle, b.toggleStyle, t),
      chipStyle: DesignStyle.lerp(a.chipStyle, b.chipStyle, t),
      sliderStyle: DesignStyle.lerp(a.sliderStyle, b.sliderStyle, t),
      ratingStyle: DesignStyle.lerp(a.ratingStyle, b.ratingStyle, t),
      calendarStyle: DesignStyle.lerp(a.calendarStyle, b.calendarStyle, t),
      wheelPickerStyle: DesignStyle.lerp(
        a.wheelPickerStyle,
        b.wheelPickerStyle,
        t,
      ),
      colorPickerStyle: DesignStyle.lerp(
        a.colorPickerStyle,
        b.colorPickerStyle,
        t,
      ),
      kbdStyle: DesignStyle.lerp(a.kbdStyle, b.kbdStyle, t),
      menuStyle: DesignStyle.lerp(a.menuStyle, b.menuStyle, t),
      popoverStyle: DesignStyle.lerp(a.popoverStyle, b.popoverStyle, t),
      tooltipStyle: DesignStyle.lerp(a.tooltipStyle, b.tooltipStyle, t),
      sheetStyle: DesignStyle.lerp(a.sheetStyle, b.sheetStyle, t),
      commandPaletteStyle: DesignStyle.lerp(
        a.commandPaletteStyle,
        b.commandPaletteStyle,
        t,
      ),
      cardStyle: DesignStyle.lerp(a.cardStyle, b.cardStyle, t),
      accordionStyle: DesignStyle.lerp(a.accordionStyle, b.accordionStyle, t),
      stepIndicatorStyle: DesignStyle.lerp(
        a.stepIndicatorStyle,
        b.stepIndicatorStyle,
        t,
      ),
      pageDotsStyle: DesignStyle.lerp(a.pageDotsStyle, b.pageDotsStyle, t),
      carouselStyle: DesignStyle.lerp(a.carouselStyle, b.carouselStyle, t),
      scrollAreaStyle: DesignStyle.lerp(
        a.scrollAreaStyle,
        b.scrollAreaStyle,
        t,
      ),
      splitViewStyle: DesignStyle.lerp(a.splitViewStyle, b.splitViewStyle, t),
      reorderableListStyle: DesignStyle.lerp(
        a.reorderableListStyle,
        b.reorderableListStyle,
        t,
      ),
      swipeActionsStyle: DesignStyle.lerp(
        a.swipeActionsStyle,
        b.swipeActionsStyle,
        t,
      ),
      treeStyle: DesignStyle.lerp(a.treeStyle, b.treeStyle, t),
      avatarStyle: DesignStyle.lerp(a.avatarStyle, b.avatarStyle, t),
      badgeStyle: DesignStyle.lerp(a.badgeStyle, b.badgeStyle, t),
      imageStyle: DesignStyle.lerp(a.imageStyle, b.imageStyle, t),
      keyFigureStyle: DesignStyle.lerp(a.keyFigureStyle, b.keyFigureStyle, t),
      spinnerStyle: DesignStyle.lerp(a.spinnerStyle, b.spinnerStyle, t),
      progressBarStyle: DesignStyle.lerp(
        a.progressBarStyle,
        b.progressBarStyle,
        t,
      ),
      skeletonStyle: DesignStyle.lerp(a.skeletonStyle, b.skeletonStyle, t),
      meterStyle: DesignStyle.lerp(a.meterStyle, b.meterStyle, t),
      chartStyle: DesignStyle.lerp(a.chartStyle, b.chartStyle, t),
      pieChartStyle: DesignStyle.lerp(a.pieChartStyle, b.pieChartStyle, t),
      pullToRefreshStyle: DesignStyle.lerp(
        a.pullToRefreshStyle,
        b.pullToRefreshStyle,
        t,
      ),
      actionBarStyle: DesignStyle.lerp(a.actionBarStyle, b.actionBarStyle, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CivicThemeData &&
      other.brightness == brightness &&
      other.ground == ground &&
      other.background == background &&
      other.surface == surface &&
      other.textPrimary == textPrimary &&
      other.textSecondary == textSecondary &&
      other.textDisabled == textDisabled &&
      other.action == action &&
      other.onAction == onAction &&
      other.actionEdge == actionEdge &&
      other.secondaryFill == secondaryFill &&
      other.onSecondary == onSecondary &&
      other.secondaryEdge == secondaryEdge &&
      other.danger == danger &&
      other.onDanger == onDanger &&
      other.dangerEdge == dangerEdge &&
      other.success == success &&
      other.onSuccess == onSuccess &&
      other.border == border &&
      other.rule == rule &&
      other.focus == focus &&
      other.onFocus == onFocus &&
      other.disabledFill == disabledFill &&
      mapEquals(other.tones, tones) &&
      other.text == text &&
      other.compactText == compactText &&
      other.tapTargets == tapTargets &&
      other.primaryButtonStyle == primaryButtonStyle &&
      other.secondaryButtonStyle == secondaryButtonStyle &&
      other.startButtonStyle == startButtonStyle &&
      other.destructiveButtonStyle == destructiveButtonStyle &&
      other.iconButtonStyle == iconButtonStyle &&
      other.linkStyle == linkStyle &&
      other.textFieldStyle == textFieldStyle &&
      other.searchButtonStyle == searchButtonStyle &&
      other.selectStyle == selectStyle &&
      other.checkboxStyle == checkboxStyle &&
      other.radioStyle == radioStyle &&
      other.switchStyle == switchStyle &&
      other.tabStyle == tabStyle &&
      other.navigationStyle == navigationStyle &&
      other.topBarStyle == topBarStyle &&
      other.paginationStyle == paginationStyle &&
      other.listRowStyle == listRowStyle &&
      other.tagStyle == tagStyle &&
      other.detailsStyle == detailsStyle &&
      other.tableStyle == tableStyle &&
      other.summaryListStyle == summaryListStyle &&
      other.timelineStyle == timelineStyle &&
      other.insetStyle == insetStyle &&
      other.panelStyle == panelStyle &&
      other.bannerStyle == bannerStyle &&
      other.errorSummaryStyle == errorSummaryStyle &&
      other.dialogStyle == dialogStyle &&
      other.toastStyle == toastStyle &&
      other.toggleStyle == toggleStyle &&
      other.chipStyle == chipStyle &&
      other.sliderStyle == sliderStyle &&
      other.ratingStyle == ratingStyle &&
      other.calendarStyle == calendarStyle &&
      other.wheelPickerStyle == wheelPickerStyle &&
      other.colorPickerStyle == colorPickerStyle &&
      other.kbdStyle == kbdStyle &&
      other.menuStyle == menuStyle &&
      other.popoverStyle == popoverStyle &&
      other.tooltipStyle == tooltipStyle &&
      other.sheetStyle == sheetStyle &&
      other.commandPaletteStyle == commandPaletteStyle &&
      other.cardStyle == cardStyle &&
      other.accordionStyle == accordionStyle &&
      other.stepIndicatorStyle == stepIndicatorStyle &&
      other.pageDotsStyle == pageDotsStyle &&
      other.carouselStyle == carouselStyle &&
      other.scrollAreaStyle == scrollAreaStyle &&
      other.splitViewStyle == splitViewStyle &&
      other.reorderableListStyle == reorderableListStyle &&
      other.swipeActionsStyle == swipeActionsStyle &&
      other.treeStyle == treeStyle &&
      other.avatarStyle == avatarStyle &&
      other.badgeStyle == badgeStyle &&
      other.imageStyle == imageStyle &&
      other.keyFigureStyle == keyFigureStyle &&
      other.spinnerStyle == spinnerStyle &&
      other.progressBarStyle == progressBarStyle &&
      other.skeletonStyle == skeletonStyle &&
      other.meterStyle == meterStyle &&
      other.chartStyle == chartStyle &&
      other.pieChartStyle == pieChartStyle &&
      other.pullToRefreshStyle == pullToRefreshStyle &&
      other.actionBarStyle == actionBarStyle;

  @override
  int get hashCode => Object.hashAll([
    brightness,
    ground,
    background,
    surface,
    textPrimary,
    textSecondary,
    textDisabled,
    action,
    onAction,
    actionEdge,
    secondaryFill,
    onSecondary,
    secondaryEdge,
    danger,
    onDanger,
    dangerEdge,
    success,
    onSuccess,
    border,
    rule,
    focus,
    onFocus,
    disabledFill,
    Object.hashAll(tones.entries.map((e) => Object.hash(e.key, e.value))),
    text,
    compactText,
    tapTargets,
    primaryButtonStyle,
    secondaryButtonStyle,
    startButtonStyle,
    destructiveButtonStyle,
    iconButtonStyle,
    linkStyle,
    textFieldStyle,
    searchButtonStyle,
    selectStyle,
    checkboxStyle,
    radioStyle,
    switchStyle,
    tabStyle,
    navigationStyle,
    topBarStyle,
    paginationStyle,
    listRowStyle,
    tagStyle,
    detailsStyle,
    tableStyle,
    summaryListStyle,
    timelineStyle,
    insetStyle,
    panelStyle,
    bannerStyle,
    errorSummaryStyle,
    dialogStyle,
    toastStyle,
    toggleStyle,
    chipStyle,
    sliderStyle,
    ratingStyle,
    calendarStyle,
    wheelPickerStyle,
    colorPickerStyle,
    kbdStyle,
    menuStyle,
    popoverStyle,
    tooltipStyle,
    sheetStyle,
    commandPaletteStyle,
    cardStyle,
    accordionStyle,
    stepIndicatorStyle,
    pageDotsStyle,
    carouselStyle,
    scrollAreaStyle,
    splitViewStyle,
    reorderableListStyle,
    swipeActionsStyle,
    treeStyle,
    avatarStyle,
    badgeStyle,
    imageStyle,
    keyFigureStyle,
    spinnerStyle,
    progressBarStyle,
    skeletonStyle,
    meterStyle,
    chartStyle,
    pieChartStyle,
    pullToRefreshStyle,
    actionBarStyle,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    for (final (name, color) in [
      ('ground', ground),
      ('background', background),
      ('surface', surface),
      ('textPrimary', textPrimary),
      ('textSecondary', textSecondary),
      ('textDisabled', textDisabled),
      ('action', action),
      ('onAction', onAction),
      ('actionEdge', actionEdge),
      ('secondaryFill', secondaryFill),
      ('onSecondary', onSecondary),
      ('secondaryEdge', secondaryEdge),
      ('danger', danger),
      ('onDanger', onDanger),
      ('dangerEdge', dangerEdge),
      ('success', success),
      ('onSuccess', onSuccess),
      ('border', border),
      ('rule', rule),
      ('focus', focus),
      ('onFocus', onFocus),
      ('disabledFill', disabledFill),
    ]) {
      properties.add(ColorProperty(name, color));
    }
    properties
      ..add(DiagnosticsProperty<CivicTextTheme>('text', text))
      ..add(DiagnosticsProperty<CivicTextTheme>('compactText', compactText))
      ..add(DiagnosticsProperty<DesignTapTargets>('tapTargets', tapTargets));
    for (final (name, style) in [
      ('primaryButtonStyle', primaryButtonStyle),
      ('secondaryButtonStyle', secondaryButtonStyle),
      ('startButtonStyle', startButtonStyle),
      ('destructiveButtonStyle', destructiveButtonStyle),
      ('iconButtonStyle', iconButtonStyle),
      ('linkStyle', linkStyle),
      ('textFieldStyle', textFieldStyle),
      ('searchButtonStyle', searchButtonStyle),
      ('selectStyle', selectStyle),
      ('checkboxStyle', checkboxStyle),
      ('radioStyle', radioStyle),
      ('switchStyle', switchStyle),
      ('tabStyle', tabStyle),
      ('navigationStyle', navigationStyle),
      ('topBarStyle', topBarStyle),
      ('paginationStyle', paginationStyle),
      ('listRowStyle', listRowStyle),
      ('tagStyle', tagStyle),
      ('detailsStyle', detailsStyle),
      ('tableStyle', tableStyle),
      ('summaryListStyle', summaryListStyle),
      ('timelineStyle', timelineStyle),
      ('insetStyle', insetStyle),
      ('panelStyle', panelStyle),
      ('bannerStyle', bannerStyle),
      ('errorSummaryStyle', errorSummaryStyle),
      ('dialogStyle', dialogStyle),
      ('toastStyle', toastStyle),
      ('toggleStyle', toggleStyle),
      ('chipStyle', chipStyle),
      ('sliderStyle', sliderStyle),
      ('ratingStyle', ratingStyle),
      ('calendarStyle', calendarStyle),
      ('wheelPickerStyle', wheelPickerStyle),
      ('colorPickerStyle', colorPickerStyle),
      ('kbdStyle', kbdStyle),
      ('menuStyle', menuStyle),
      ('popoverStyle', popoverStyle),
      ('tooltipStyle', tooltipStyle),
      ('sheetStyle', sheetStyle),
      ('commandPaletteStyle', commandPaletteStyle),
      ('cardStyle', cardStyle),
      ('accordionStyle', accordionStyle),
      ('stepIndicatorStyle', stepIndicatorStyle),
      ('pageDotsStyle', pageDotsStyle),
      ('carouselStyle', carouselStyle),
      ('scrollAreaStyle', scrollAreaStyle),
      ('splitViewStyle', splitViewStyle),
      ('reorderableListStyle', reorderableListStyle),
      ('swipeActionsStyle', swipeActionsStyle),
      ('treeStyle', treeStyle),
      ('avatarStyle', avatarStyle),
      ('badgeStyle', badgeStyle),
      ('imageStyle', imageStyle),
      ('keyFigureStyle', keyFigureStyle),
      ('spinnerStyle', spinnerStyle),
      ('progressBarStyle', progressBarStyle),
      ('skeletonStyle', skeletonStyle),
      ('meterStyle', meterStyle),
      ('chartStyle', chartStyle),
      ('pieChartStyle', pieChartStyle),
      ('pullToRefreshStyle', pullToRefreshStyle),
      ('actionBarStyle', actionBarStyle),
    ]) {
      properties.add(
        DiagnosticsProperty<CivicStyle>(name, style, defaultValue: null),
      );
    }
  }
}

class _CivicScope extends InheritedTheme {
  const _CivicScope({required this.data, required super.child});

  final CivicThemeData data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _CivicScope(data: data, child: child);

  @override
  bool updateShouldNotify(_CivicScope oldWidget) => data != oldWidget.data;
}

/// Puts Civic in scope for everything under it, as Material's `Theme` does.
/// It is the whole install: put one in any app's `builder:`, under a
/// `MaterialApp`, a `CupertinoApp` or a `WidgetsApp` alike. Under it, every
/// text has Civic's body style to fall back on, Flutter's own text field
/// wears Civic's caret and selection with no ink, taps reach 48 by 48 for a
/// finger and 24 by 24 for a pointer, and spacing stands on a 4 pt grid.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => CivicTheme(
///     data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
///         ? CivicThemeData.dark()
///         : CivicThemeData.light(),
///     child: child!,
///   ),
///   home: const ApplyPage(),
/// )
/// ```
class CivicTheme extends StatelessWidget {
  /// Scopes [data] over [child].
  const CivicTheme({super.key, required this.data, required this.child});

  /// The theme for what is under it.
  final CivicThemeData data;

  /// What it styles.
  final Widget child;

  /// The theme in scope at [context]; with none, Civic in the platform's
  /// brightness, as Material's `Theme.of` falls back to its own.
  /// `context.civicTheme` is the same.
  static CivicThemeData of(BuildContext context) =>
      maybeOf(context) ??
      switch (MediaQuery.maybePlatformBrightnessOf(context)) {
        Brightness.dark => _darkDefault,
        _ => _lightDefault,
      };

  static final CivicThemeData _lightDefault = CivicThemeData.light();
  static final CivicThemeData _darkDefault = CivicThemeData.dark();

  /// The theme in scope at [context], or null.
  static CivicThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CivicScope>()?.data;

  /// The type ramp for [context]'s window: the phone's below
  /// [CivicLayout.medium], the wider window's from there.
  static CivicTextTheme textOf(BuildContext context) {
    final theme = of(context);
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1024;
    return width < CivicLayout.medium ? theme.compactText : theme.text;
  }

  @override
  Widget build(BuildContext context) {
    Widget under = child;
    // Civic's text field asks for the words of the Material library it is
    // built on, and a field's menu on iOS for Cupertino's. An app with none
    // gets Civic's own (internal/platform_words.dart), never a throw; an app
    // that has them keeps its own. The app's own direction is kept.
    final missing = Localizations.maybeLocaleOf(context) == null
        ? const <LocalizationsDelegate<Object?>>[]
        : <LocalizationsDelegate<Object?>>[
            if (Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                ) ==
                null)
              civicMaterialWords,
            if (Localizations.of<CupertinoLocalizations>(
                  context,
                  CupertinoLocalizations,
                ) ==
                null)
              civicCupertinoWords,
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
    assert(
      CivicThemeData.floorsHold(data.tapTargets),
      CivicThemeData._floorsMessage,
    );
    final text = textOf(context);
    // The app's page change, from the Material theme round Civic (an app
    // puts civicPageTransitions there): the theme Civic puts under its parts
    // is the one a MaterialPageRoute under them reads.
    final transitions = Theme.of(context).pageTransitionsTheme;
    var bridge = _bridges[data];
    if (bridge == null || bridge.pageTransitionsTheme != transitions) {
      bridge = _bridges[data] = _materialUnder(data)
          .copyWith(pageTransitionsTheme: transitions);
    }
    return _CivicScope(
      data: data,
      child: DesignTapTargetScope(
        targets: data.tapTargets,
        child: DesignSpacingScope(
          spacing: DesignSpacing.fallback,
          child: Theme(
            data: bridge,
            child: IconTheme.merge(
              data: IconThemeData(color: data.textPrimary, size: 24),
              child: DefaultTextStyle(style: text.body, child: under),
            ),
          ),
        ),
      ),
    );
  }

  static final Expando<ThemeData> _bridges = Expando<ThemeData>('civic');

  /// What Flutter's own widgets under Civic read (a text field's caret and
  /// selection, a route's ground), in Civic's colours, with no ink, splash or
  /// highlight, and Material's density pinned to standard (a route's page
  /// change is the app's own, put in by [build]). Private: no Material type
  /// is in Civic's API, and no Civic part reads a token from it.
  static ThemeData _materialUnder(CivicThemeData t) => ThemeData(
    useMaterial3: true,
    brightness: t.brightness,
    fontFamily: t.text.body.fontFamily,
    scaffoldBackgroundColor: t.ground,
    canvasColor: t.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x00000000),
    hoverColor: const Color(0x00000000),
    splashColor: const Color(0x00000000),
    focusColor: const Color(0x00000000),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.textPrimary,
      selectionColor: t.action.withValues(alpha: 0.28),
      selectionHandleColor: t.action,
    ),
    colorScheme: ColorScheme(
      brightness: t.brightness,
      primary: t.action,
      onPrimary: t.onAction,
      secondary: t.textPrimary,
      onSecondary: t.background,
      error: t.danger,
      onError: t.onDanger,
      surface: t.background,
      onSurface: t.textPrimary,
      outline: t.border,
      outlineVariant: t.rule,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CivicThemeData>('data', data));
  }
}

/// Animates to a new [data] over [duration], as `AnimatedTheme` does:
/// colours and type blend through [CivicThemeData.lerp].
///
/// ```dart
/// AnimatedCivicTheme(
///   data: night ? CivicThemeData.dark() : CivicThemeData.light(),
///   child: page,
/// )
/// ```
class AnimatedCivicTheme extends ImplicitlyAnimatedWidget {
  /// Animates [child]'s theme to [data].
  const AnimatedCivicTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final CivicThemeData data;

  /// What it styles.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedCivicTheme> createState() =>
      _AnimatedCivicThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CivicThemeData>('data', data));
  }
}

class _AnimatedCivicThemeState
    extends AnimatedWidgetBaseState<AnimatedCivicTheme> {
  CivicThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => CivicThemeDataTween(begin: value as CivicThemeData),
    ) as CivicThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) =>
      CivicTheme(data: _data!.evaluate(animation), child: widget.child);
}

/// A tween between two Civic themes, through [CivicThemeData.lerp].
class CivicThemeDataTween extends Tween<CivicThemeData> {
  /// From [begin] to [end].
  CivicThemeDataTween({super.begin, super.end});

  @override
  CivicThemeData lerp(double t) => CivicThemeData.lerp(begin!, end!, t);
}

/// The accessors every Civic part reads its tokens through.
extension CivicThemeContext on BuildContext {
  /// The theme in scope: `context.civicTheme.action`, ...
  CivicThemeData get civicTheme => CivicTheme.of(this);

  /// The type ramp for this window: `context.civicText.body`, ...
  CivicTextTheme get civicText => CivicTheme.textOf(this);
}
