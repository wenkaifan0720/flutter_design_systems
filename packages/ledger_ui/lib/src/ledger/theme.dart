import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'density.dart';
import 'fonts.dart';

import 'internal/narrow.dart';
import 'internal/themes/frost.g.dart';
import 'internal/themes/gallery.g.dart';
import 'internal/themes/paper.g.dart';
import 'internal/themes/signal.g.dart';
import 'tokens.dart';

export 'tokens.dart';

/// Design tokens and theme assembly: the only styling vocabulary a Ledger
/// page may use.
///
/// Fixed scales (spacing, corners, icon size, motion) are compile-time
/// consts. Theme-dependent tokens (colour, shadow, type, the shape roles)
/// live on [LedgerThemeData], a plain value the app mounts once through
/// `LedgerHost` as a [LedgerTheme] (an `InheritedTheme`) and every
/// widget reads via `context.ledgerTheme`. Pages never write raw numbers, hex
/// colours or TextStyles; everything routes through this file's names.
///
/// The theme instances come from [LedgerThemeData.preset]: `quire`, the look
/// as the Keel / Ledger pilot's stylesheet sets it (its custom properties
/// and literal colours, written in `_Source` at the end of this file under
/// their own names, with the role mapping and the judgment calls in its
/// header; its dark appearance is DESIGNED, in `_Night`), and four of
/// Cody's catalog themes (`cody/themes/<id>/tokens.json`, ThemeTokens v2
/// records whose light and dark are both designed, baked by
/// `scripts/baked-themes.ts` into `internal/themes/`) dressed in the same
/// roles through [LedgerThemeData.fromTokens]: `terracotta` (paper), `indigo`
/// (signal), `verdigris` (frost) and `carbon` (gallery). Nothing else
/// constructs a [LedgerThemeData].

/// The spacing scale: the steps the source pads and gaps by. The page
/// gutter is 24 on a phone and 56 on the desktop; a section stands 48 under
/// the one before it (56 on the desktop, 28 under the masthead); a row pads
/// 14 above and below.
abstract final class LedgerSpacing {
  /// 2: a link's chevron from its words.
  static const double s2 = 2;

  /// 4: the tightest gap between a glyph and its words.
  static const double s4 = 4;

  /// 6: a title under its meta, a tab's glyph over its label.
  static const double s6 = 6;

  /// 8: what follows a head, a sheet's body under its head.
  static const double s8 = 8;

  /// 10: a button's glyph from its words.
  static const double s10 = 10;

  /// 12: two acts side by side, the parts of a toast.
  static const double s12 = 12;

  /// 14: a row's padding above and below.
  static const double s14 = 14;

  /// 16: the padding of a slip's side room.
  static const double s16 = 16;

  /// 20: over a sheet's acts, the side bar's side padding.
  static const double s20 = 20;

  /// 24: the page gutter on a phone.
  static const double s24 = 24;

  /// 28: the first section under the masthead.
  static const double s28 = 28;

  /// 32: a desktop dialog's padding.
  static const double s32 = 32;

  /// 36: under the masthead on the desktop.
  static const double s36 = 36;

  /// 40: under a tab's last section, between an overview's sections.
  static const double s40 = 40;

  /// 48: a section under the one before, on a phone.
  static const double s48 = 48;

  /// 56: the page gutter and the section gap on the desktop.
  static const double s56 = 56;

  /// 72: under the last section on the desktop.
  static const double s72 = 72;
}

/// Corner radii: the scale behind the shape roles of [LedgerThemeData]. The
/// source's language is paper at 6 (a memo slip, a sheet, a menu, a toast,
/// a date tab), plastic at 12 to 16 (a card face) and round for everything
/// held in the hand (buttons, chips, pills, the tab's disc).
abstract final class LedgerCorners {
  /// Paper: a memo slip, a sheet, a menu, a toast, a date tab.
  static const double r6 = 6;

  /// 12: plastic, a card face's smaller corner.
  static const double r12 = 12;

  /// 16: plastic, a card face.
  static const double r16 = 16;

  /// Round: what the hand holds (buttons, chips, pills, the tab's disc).
  static const double rFull = 999;
}

/// Glyph sizes: a section link's chevron (14), a crumb's, a toast's and a
/// quiet button's (15), a menu's check and the sidebar's chevron (16), a
/// button's, a nav link's and a ringed button's (18), the body glyph (20)
/// and a tab's (22).
abstract final class LedgerIconSize {
  /// A section link's chevron.
  static const double i14 = 14;

  /// A crumb's, a toast's and a small button's glyph.
  static const double i15 = 15;

  /// A menu's check and the side bar's chevron.
  static const double i16 = 16;

  /// A button's, a nav link's and a ringed button's glyph.
  static const double i18 = 18;

  /// The body glyph.
  static const double i20 = 20;

  /// A tab's glyph.
  static const double i22 = 22;
}

/// Motion: durations and curves. DERIVED: the source is static pages and
/// moves nothing but its overlays' open and close. Where the platform asks
/// for reduced motion (`MediaQuery.disableAnimations`, which a test sets
/// through its binding's accessibility features), every change lands at
/// once ([of]).
abstract final class LedgerMotion {
  /// 120 ms: the quick step.
  static const Duration fast = Duration(milliseconds: 120);

  /// 200 ms: the ordinary step; an overlay's fall.
  static const Duration base = Duration(milliseconds: 200);

  /// 320 ms: an overlay's rise.
  static const Duration slow = Duration(milliseconds: 320);

  /// The curve of what arrives (ease out, cubic).
  static const Curve out = Curves.easeOutCubic;

  /// [step] where a change may move here, none at all where the platform
  /// asks for reduced motion: a change then lands at once.
  static Duration of(BuildContext context, [Duration step = fast]) =>
      isReduced(context) ? Duration.zero : step;

  /// Whether the platform asks for reduced motion above [context].
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// The paddings Ledger's parts use, on the spacing scale.
abstract final class LedgerInsets {
  /// A page's room round its content on a phone: the 24 gutter at its
  /// sides, 40 under its last section (48 on a pushed page, which has no
  /// tab bar under it).
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    LedgerSpacing.s24,
    0,
    LedgerSpacing.s24,
    LedgerSpacing.s40,
  );

  /// A pushed page's room on a phone: as [screen], 48 under.
  static const EdgeInsets screenPushed = EdgeInsets.fromLTRB(
    LedgerSpacing.s24,
    0,
    LedgerSpacing.s24,
    LedgerSpacing.s48,
  );

  /// A page's room on the desktop: 40 above, the 56 gutter at its sides,
  /// 72 under.
  static const EdgeInsets screenWide = EdgeInsets.fromLTRB(
    LedgerSpacing.s56,
    LedgerSpacing.s40,
    LedgerSpacing.s56,
    LedgerSpacing.s72,
  );
}

/// A fixed spacer of one [LedgerSpacing] step.
class LedgerGap extends StatelessWidget {
  /// A gap of [size], in both axes.
  const LedgerGap(this.size, {super.key});

  /// The gap's extent, a [LedgerSpacing] step.
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

/// Responsive layout invariants shared by Ledger apps.
abstract final class LedgerLayout {
  /// The width from which the app is the desktop one, as the source switches
  /// at 1024: the sidebar replaces the tab bar and the top bar, the gutter
  /// grows to 56, the figures grow, a sheet becomes a centred dialog and a
  /// detail's way back a crumb over its title.
  static const double wide = 1024;

  /// The touch-target floor.
  static const double minHitTarget = 44;

  /// The window width from which a form's short entries (a select, a sum)
  /// stand at their own measure instead of across their column: the
  /// rail's 600.
  static const double measuredFrom = 600;

  /// The most a select, a sum's field, a stepper or a block act stands
  /// across from [measuredFrom] (unless its words need more):
  /// a blank sized to what goes in it, as a paper form's is, never the
  /// column or the page. A form gives it a cell of its grid (a half or a
  /// third of its column) and it stands at the start of the cell, up to
  /// this.
  static const double fieldMeasure = 320;

  /// [field] at its measure from [measuredFrom] (at the start of its slot,
  /// at most [fieldMeasure] across); across its column under it.
  static Widget measured(BuildContext context, Widget field) =>
      MediaQuery.sizeOf(context).width < measuredFrom
      ? field
      : Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: fieldMeasure),
            child: field,
          ),
        );

  /// Whether a control keeps to its own width here: from [measuredFrom],
  /// outside a narrow preview. A button, a row of buttons and a stepper do
  /// (at the start of their slot, at most [fieldMeasure] across unless their
  /// words need more), so a wide column never draws one as a banner; under
  /// it they span their column, as a phone's block act does, and so do a
  /// sheet's and a dialog's acts at any width (the card is their measure).
  static bool keepsMeasure(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= measuredFrom &&
      !LedgerNarrowScope.isIn(context) &&
      !LedgerCardActsScope.isIn(context);

  /// [control] at the start of its slot, at most [most] across, when
  /// [keepsMeasure]; as given under it. A slot narrower than [most] (a
  /// dialog's half) still holds it across.
  static Widget atMeasure(
    BuildContext context,
    Widget control, {
    double most = fieldMeasure,
  }) => keepsMeasure(context)
      ? Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: most),
            child: control,
          ),
        )
      : control;

  /// Whether the window is the desktop one.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide &&
      !LedgerNarrowScope.isIn(context);

  /// The page gutter at [context]: 24 on a phone, 56 on the desktop.
  static double gutter(BuildContext context) =>
      isWide(context) ? LedgerSpacing.s56 : LedgerSpacing.s24;
}

/// How an amount or a figure is inked, as the source tells money apart:
/// [plain] in the page ink, [moneyIn] green, [over] vermilion (spent past a
/// budget, and only then) and [move] the quiet ink of money moved between
/// the owner's own accounts.
enum LedgerTone {
  /// In the page ink.
  plain,

  /// Green: money received.
  moneyIn,

  /// Vermilion: spent past a budget, and only then.
  over,

  /// The quiet ink: money moved between the owner's own accounts.
  move,
}

/// The design tokens: every colour role, shadow, type slot and shape role a
/// Ledger widget draws with, for one preset in one appearance.
@immutable
final class LedgerThemeData with Diagnosticable {
  /// Every role given; [LedgerThemeData.light], [LedgerThemeData.dark],
  /// [LedgerThemeData.preset] and [LedgerThemeData.from] build one for you.
  const LedgerThemeData({
    required this.id,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.success,
    required this.onSuccess,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.onDanger,
    required this.dangerSubtle,
    required this.overlay,
    required this.accentText,
    required this.hairline,
    required this.textFaint,
    required this.headRule,
    required this.accentRule,
    required this.moneyIn,
    required this.moneyInCents,
    required this.over,
    required this.overCents,
    required this.move,
    required this.moveCents,
    required this.pace,
    required this.seal,
    required this.sealOver,
    required this.sealInk,
    required this.hatchInk,
    required this.hatchGreen,
    required this.hatchPale,
    required this.topBarFill,
    required this.tabBarFill,
    required this.sideBarFill,
    required this.selectedFill,
    required this.selectedRing,
    required this.discRing,
    required this.dotRing,
    required this.avatar,
    required this.onAvatar,
    required this.toast,
    required this.onToast,
    required this.onToastAction,
    required this.toastRing,
    required this.menuSelected,
    required this.paperShadow,
    required this.sheetShadow,
    required this.dialogShadow,
    required this.menuShadow,
    required this.toastShadow,
    required this.primaryShadow,
    required this.discShadow,
    required this.figure,
    required this.figureMedium,
    required this.figureSmall,
    required this.title,
    required this.barTitle,
    required this.sheetTitle,
    required this.wordmark,
    required this.body,
    required this.rowTitle,
    required this.bodySmall,
    required this.label,
    required this.meta,
    required this.amount,
    required this.tab,
    required this.button,
    required this.buttonSmall,
    required this.navLink,
    required this.link,
    required this.pill,
    required this.tag,
    required this.toastText,
    required this.toastAction,
    required this.monogram,
    required this.initials,
    required this.footnote,
    required this.search,
    required this.cardRadius,
    required this.controlRadius,
    required this.smallRadius,
    required this.sheetRadius,
    this.density = LedgerDensity.standard,
  });

  /// The preset this theme is (`quire`, `terracotta`).
  final String id;

  /// Whether this is the day book or the night book.
  final Brightness brightness;

  // ---- the catalog's roles ------------------------------------------------

  /// The canvas: the page's paper.
  final Color background;

  /// Raised paper: a memo slip, a sheet, a menu, a field, the current nav
  /// link.
  final Color surface;

  /// Sunken paper: the sidebar's column, a pill's quiet ground, a pressed
  /// row.
  final Color surfaceAlt;

  /// The inverse ground: the toast and the ink button.
  final Color surfaceInverse;

  /// The rule: a ringed button's ring, a field's edge, the tab bar's top.
  final Color border;

  /// The strong rule: a secondary button's ring.
  final Color borderStrong;

  /// The first ink: words, figures, the head rule.
  final Color textPrimary;

  /// The second ink: a key, a crumb, a section's quiet words.
  final Color textSecondary;

  /// The third ink: meta lines, sub lines, an amount's cents, idle tabs.
  final Color textTertiary;

  /// Words on [surfaceInverse].
  final Color textInverse;

  /// The one green: the primary act, the current tab's tick and glyph, a
  /// section's link, the pace line and the seal.
  final Color accent;

  /// Words and glyphs on [accent].
  final Color onAccent;

  /// The green's wash: a green pill's ground, a money-in monogram's fill.
  final Color accentSubtle;

  /// Money in.
  final Color success;

  /// Words on [success].
  final Color onSuccess;

  /// Money in's wash.
  final Color successSubtle;

  /// The source's caution, an ink pill (a goal behind): no amber in Ledger.
  final Color warning;

  /// The caution pill's wash.
  final Color warningSubtle;

  /// Vermilion: over budget, and nothing else.
  final Color danger;

  /// Words on [danger].
  final Color onDanger;

  /// Vermilion's wash.
  final Color dangerSubtle;

  /// The scrim under a sheet or a dialog.
  final Color overlay;

  /// Green words: a section's link, a footnote's mark.
  final Color accentText;

  // ---- Ledger's own roles --------------------------------------------------

  /// The hairline between rows and under the top bar.
  final Color hairline;

  /// The faint ink: dot leaders, a tag's ring, a dashed move glyph, the
  /// grip, a quiet chevron.
  final Color textFaint;

  /// The ink rule over a section's head, under a sheet's head and in a
  /// statement's double rule.
  final Color headRule;

  /// The green rule: the desktop's margin column and a money-in monogram's
  /// ring.
  final Color accentRule;

  /// Money in, and its cents.
  final Color moneyIn;

  /// Money in's cents.
  final Color moneyInCents;

  /// Over budget, and its cents.
  final Color over;

  /// Over budget's cents.
  final Color overCents;

  /// A move between the owner's own accounts, and its cents.
  final Color move;

  /// A move's cents.
  final Color moveCents;

  /// The pace line on a spending chart.
  final Color pace;

  /// The seal's three inks: green, over, and the ink of a blank page.
  final Color seal;

  /// The over seal's ink.
  final Color sealOver;

  /// The blank page's seal ink.
  final Color sealInk;

  /// The three hatches the source tells parts apart by (it gives the
  /// categories glyphs, never hues): close ink, open green and pale ink.
  final Color hatchInk;

  /// The open green hatch.
  final Color hatchGreen;

  /// The pale ink hatch.
  final Color hatchPale;

  /// The phone's top bar: the page's paper, opaque.
  final Color topBarFill;

  /// The phone's tab bar: the raised paper, opaque.
  final Color tabBarFill;

  /// The desktop sidebar's column.
  final Color sideBarFill;

  /// The current nav link's paper.
  final Color selectedFill;

  /// The ring round the current nav link.
  final Color selectedRing;

  /// The paper ring round the tab bar's Move disc.
  final Color discRing;

  /// The ring round the bell's dot.
  final Color dotRing;

  /// The avatar's ground.
  final Color avatar;

  /// The avatar's initials.
  final Color onAvatar;

  /// The toast's ground.
  final Color toast;

  /// The toast's words.
  final Color onToast;

  /// The toast's act.
  final Color onToastAction;

  /// The ring round the toast's glyph.
  final Color toastRing;

  /// The chosen item's ground in a menu.
  final Color menuSelected;

  /// A memo slip's shadow: a 1 px edge, a contact shade and a soft drop.
  final List<BoxShadow> paperShadow;

  /// A phone sheet's shadow, cast up the page.
  final List<BoxShadow> sheetShadow;

  /// A desktop dialog's shadow.
  final List<BoxShadow> dialogShadow;

  /// A menu's shadow.
  final List<BoxShadow> menuShadow;

  /// A toast's shadow.
  final List<BoxShadow> toastShadow;

  /// The primary act's green drop.
  final List<BoxShadow> primaryShadow;

  /// The tab bar's Move disc's green drop.
  final List<BoxShadow> discShadow;

  // ---- type ---------------------------------------------------------------

  /// The engraved figure: a page's one amount (88 on a phone).
  final TextStyle figure;

  /// A section's figure (44).
  final TextStyle figureMedium;

  /// A small figure in a row of facts (28 on 30).
  final TextStyle figureSmall;

  /// A page's title and the greeting (30 on 33).
  final TextStyle title;

  /// A page's first heading, as generated pages name it: the [title] style.
  TextStyle get h1 => title;

  /// The kind of record a phone detail's bar names (24).
  final TextStyle barTitle;

  /// A sheet's title (28 on 30).
  final TextStyle sheetTitle;

  /// The wordmark (28).
  final TextStyle wordmark;

  /// Running copy (15 on 21.75).
  final TextStyle body;

  /// A row's title (15 on 20, medium).
  final TextStyle rowTitle;

  /// A sub line and secondary copy (13 on 18).
  final TextStyle bodySmall;

  /// The caps rubric of a section's head (11 on 16, semibold, tracked.
  /// 14em). Set its words in capitals.
  final TextStyle label;

  /// The mono meta line: dates, notes, counts (11 on 16, tracked .04em).
  /// Set its words in capitals.
  final TextStyle meta;

  /// The ledger amount (14 on 20, mono medium, tracked −.02em).
  final TextStyle amount;

  /// A tab's name (11 on 12, medium).
  final TextStyle tab;

  /// A button's words (15, semibold).
  final TextStyle button;

  /// A quiet button's words (13, medium).
  final TextStyle buttonSmall;

  /// A sidebar link (14.5, medium).
  final TextStyle navLink;

  /// A section's mono link (11 on 16, medium, tracked .04em). Capitals.
  final TextStyle link;

  /// A pill's mono words (12, medium).
  final TextStyle pill;

  /// A tag's mono capitals (11 on 12, medium, tracked .06em).
  final TextStyle tag;

  /// A toast's words (15 on 20, medium) and its mono act (12, tracked .06em,
  /// capitals).
  final TextStyle toastText;

  /// A toast's mono act (12, tracked .06em, capitals).
  final TextStyle toastAction;

  /// A monogram's italic serif (16, tracked .03em).
  final TextStyle monogram;

  /// The avatar's italic initials (15, tracked .04em).
  final TextStyle initials;

  /// A footnote's mono mark (11 on 12, medium).
  final TextStyle footnote;

  /// A search field's words (15).
  final TextStyle search;

  // ---- shape --------------------------------------------------------------

  /// Paper: a memo slip, a menu, a toast.
  final double cardRadius;

  /// What the hand holds: buttons, chips, pills (round).
  final double controlRadius;

  /// A date tab, a small paper part.
  final double smallRadius;

  /// A sheet and a dialog.
  final double sheetRadius;

  // ---- density ------------------------------------------------------------

  /// How tightly controls and rows are set ([LedgerDensity]). The
  /// constructor's default is [LedgerDensity.standard]; [LedgerThemeData.light]
  /// and [LedgerThemeData.dark] default to the platform's
  /// ([LedgerDensity.adaptivePlatformDensity]).
  final LedgerDensity density;

  /// The bundled faces: Inter Tight for every word of the interface,
  /// Instrument Serif (regular and italic) for figures, titles and
  /// monograms, and Plex Mono for amounts, dates and numbers.
  static const String face = 'InterTight';

  /// The serif's family: figures, titles and monograms.
  static const String serifFace = 'InstrumentSerif';

  /// The mono's family: amounts, dates and numbers.
  static const String monoFace = 'PlexMono';

  /// Every preset, the source's first.
  static const List<String> presets = [
    'quire',
    'terracotta',
    'indigo',
    'verdigris',
    'carbon',
  ];

  /// The preset [id] in [brightness]: `quire` (the source, light as drawn
  /// and dark DESIGNED in `_Night`), or one of Cody's themes baked:
  /// `terracotta` (paper), `indigo` (signal), `verdigris` (frost) or
  /// `carbon` (gallery). Throws an
  /// [ArgumentError] for any other id. The same preset is the same value.
  static LedgerThemeData preset(String id, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (id) {
      'quire' => dark ? _ledgerDark : _ledgerLight,
      'terracotta' => dark ? _terracottaDark : _terracottaLight,
      'indigo' => dark ? _indigoDark : _indigoLight,
      'verdigris' => dark ? _verdigrisDark : _verdigrisLight,
      'carbon' => dark ? _carbonDark : _carbonLight,
      _ => throw ArgumentError.value(id, 'id', 'not a Ledger preset'),
    };
  }

  static final LedgerThemeData _ledgerLight = _quire(Brightness.light);
  static final LedgerThemeData _ledgerDark = _quire(Brightness.dark);
  static final LedgerThemeData _terracottaLight = LedgerThemeData.fromTokens(
    'terracotta',
    paperTokens,
    Brightness.light,
  );
  static final LedgerThemeData _terracottaDark = LedgerThemeData.fromTokens(
    'terracotta',
    paperTokens,
    Brightness.dark,
  );
  static final LedgerThemeData _indigoLight = LedgerThemeData.fromTokens(
    'indigo',
    signalTokens,
    Brightness.light,
  );
  static final LedgerThemeData _indigoDark = LedgerThemeData.fromTokens(
    'indigo',
    signalTokens,
    Brightness.dark,
  );
  static final LedgerThemeData _verdigrisLight = LedgerThemeData.fromTokens(
    'verdigris',
    frostTokens,
    Brightness.light,
  );
  static final LedgerThemeData _verdigrisDark = LedgerThemeData.fromTokens(
    'verdigris',
    frostTokens,
    Brightness.dark,
  );
  static final LedgerThemeData _carbonLight = LedgerThemeData.fromTokens(
    'carbon',
    galleryTokens,
    Brightness.light,
  );
  static final LedgerThemeData _carbonDark = LedgerThemeData.fromTokens(
    'carbon',
    galleryTokens,
    Brightness.dark,
  );

  // GENERATED-BEGIN from the fields above.

  /// A copy of this theme with the given fields replaced.
  LedgerThemeData copyWith({
    String? id,
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceInverse,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? accent,
    Color? onAccent,
    Color? accentSubtle,
    Color? success,
    Color? onSuccess,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? danger,
    Color? onDanger,
    Color? dangerSubtle,
    Color? overlay,
    Color? accentText,
    Color? hairline,
    Color? textFaint,
    Color? headRule,
    Color? accentRule,
    Color? moneyIn,
    Color? moneyInCents,
    Color? over,
    Color? overCents,
    Color? move,
    Color? moveCents,
    Color? pace,
    Color? seal,
    Color? sealOver,
    Color? sealInk,
    Color? hatchInk,
    Color? hatchGreen,
    Color? hatchPale,
    Color? topBarFill,
    Color? tabBarFill,
    Color? sideBarFill,
    Color? selectedFill,
    Color? selectedRing,
    Color? discRing,
    Color? dotRing,
    Color? avatar,
    Color? onAvatar,
    Color? toast,
    Color? onToast,
    Color? onToastAction,
    Color? toastRing,
    Color? menuSelected,
    List<BoxShadow>? paperShadow,
    List<BoxShadow>? sheetShadow,
    List<BoxShadow>? dialogShadow,
    List<BoxShadow>? menuShadow,
    List<BoxShadow>? toastShadow,
    List<BoxShadow>? primaryShadow,
    List<BoxShadow>? discShadow,
    TextStyle? figure,
    TextStyle? figureMedium,
    TextStyle? figureSmall,
    TextStyle? title,
    TextStyle? barTitle,
    TextStyle? sheetTitle,
    TextStyle? wordmark,
    TextStyle? body,
    TextStyle? rowTitle,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? meta,
    TextStyle? amount,
    TextStyle? tab,
    TextStyle? button,
    TextStyle? buttonSmall,
    TextStyle? navLink,
    TextStyle? link,
    TextStyle? pill,
    TextStyle? tag,
    TextStyle? toastText,
    TextStyle? toastAction,
    TextStyle? monogram,
    TextStyle? initials,
    TextStyle? footnote,
    TextStyle? search,
    double? cardRadius,
    double? controlRadius,
    double? smallRadius,
    double? sheetRadius,
    LedgerDensity? density,
  }) => LedgerThemeData(
    id: id ?? this.id,
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    surfaceInverse: surfaceInverse ?? this.surfaceInverse,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textInverse: textInverse ?? this.textInverse,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentSubtle: accentSubtle ?? this.accentSubtle,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successSubtle: successSubtle ?? this.successSubtle,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerSubtle: dangerSubtle ?? this.dangerSubtle,
    overlay: overlay ?? this.overlay,
    accentText: accentText ?? this.accentText,
    hairline: hairline ?? this.hairline,
    textFaint: textFaint ?? this.textFaint,
    headRule: headRule ?? this.headRule,
    accentRule: accentRule ?? this.accentRule,
    moneyIn: moneyIn ?? this.moneyIn,
    moneyInCents: moneyInCents ?? this.moneyInCents,
    over: over ?? this.over,
    overCents: overCents ?? this.overCents,
    move: move ?? this.move,
    moveCents: moveCents ?? this.moveCents,
    pace: pace ?? this.pace,
    seal: seal ?? this.seal,
    sealOver: sealOver ?? this.sealOver,
    sealInk: sealInk ?? this.sealInk,
    hatchInk: hatchInk ?? this.hatchInk,
    hatchGreen: hatchGreen ?? this.hatchGreen,
    hatchPale: hatchPale ?? this.hatchPale,
    topBarFill: topBarFill ?? this.topBarFill,
    tabBarFill: tabBarFill ?? this.tabBarFill,
    sideBarFill: sideBarFill ?? this.sideBarFill,
    selectedFill: selectedFill ?? this.selectedFill,
    selectedRing: selectedRing ?? this.selectedRing,
    discRing: discRing ?? this.discRing,
    dotRing: dotRing ?? this.dotRing,
    avatar: avatar ?? this.avatar,
    onAvatar: onAvatar ?? this.onAvatar,
    toast: toast ?? this.toast,
    onToast: onToast ?? this.onToast,
    onToastAction: onToastAction ?? this.onToastAction,
    toastRing: toastRing ?? this.toastRing,
    menuSelected: menuSelected ?? this.menuSelected,
    paperShadow: paperShadow ?? this.paperShadow,
    sheetShadow: sheetShadow ?? this.sheetShadow,
    dialogShadow: dialogShadow ?? this.dialogShadow,
    menuShadow: menuShadow ?? this.menuShadow,
    toastShadow: toastShadow ?? this.toastShadow,
    primaryShadow: primaryShadow ?? this.primaryShadow,
    discShadow: discShadow ?? this.discShadow,
    figure: figure ?? this.figure,
    figureMedium: figureMedium ?? this.figureMedium,
    figureSmall: figureSmall ?? this.figureSmall,
    title: title ?? this.title,
    barTitle: barTitle ?? this.barTitle,
    sheetTitle: sheetTitle ?? this.sheetTitle,
    wordmark: wordmark ?? this.wordmark,
    body: body ?? this.body,
    rowTitle: rowTitle ?? this.rowTitle,
    bodySmall: bodySmall ?? this.bodySmall,
    label: label ?? this.label,
    meta: meta ?? this.meta,
    amount: amount ?? this.amount,
    tab: tab ?? this.tab,
    button: button ?? this.button,
    buttonSmall: buttonSmall ?? this.buttonSmall,
    navLink: navLink ?? this.navLink,
    link: link ?? this.link,
    pill: pill ?? this.pill,
    tag: tag ?? this.tag,
    toastText: toastText ?? this.toastText,
    toastAction: toastAction ?? this.toastAction,
    monogram: monogram ?? this.monogram,
    initials: initials ?? this.initials,
    footnote: footnote ?? this.footnote,
    search: search ?? this.search,
    cardRadius: cardRadius ?? this.cardRadius,
    controlRadius: controlRadius ?? this.controlRadius,
    smallRadius: smallRadius ?? this.smallRadius,
    sheetRadius: sheetRadius ?? this.sheetRadius,
    density: density ?? this.density,
  );

  /// The theme [t] of the way from [a] to [b], as `ThemeData.lerp` blends
  /// two Material themes: colours, type and shadows blend, and the [id] and
  /// [brightness] switch half-way. [AnimatedLedgerTheme] animates through it.
  static LedgerThemeData lerp(LedgerThemeData a, LedgerThemeData b, double t) {
    if (identical(a, b)) return a;
    return LedgerThemeData(
      id: t < 0.5 ? a.id : b.id,
      brightness: t < 0.5 ? a.brightness : b.brightness,
      background: Color.lerp(a.background, b.background, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceAlt: Color.lerp(a.surfaceAlt, b.surfaceAlt, t)!,
      surfaceInverse: Color.lerp(a.surfaceInverse, b.surfaceInverse, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      borderStrong: Color.lerp(a.borderStrong, b.borderStrong, t)!,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      textTertiary: Color.lerp(a.textTertiary, b.textTertiary, t)!,
      textInverse: Color.lerp(a.textInverse, b.textInverse, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
      accentSubtle: Color.lerp(a.accentSubtle, b.accentSubtle, t)!,
      success: Color.lerp(a.success, b.success, t)!,
      onSuccess: Color.lerp(a.onSuccess, b.onSuccess, t)!,
      successSubtle: Color.lerp(a.successSubtle, b.successSubtle, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      warningSubtle: Color.lerp(a.warningSubtle, b.warningSubtle, t)!,
      danger: Color.lerp(a.danger, b.danger, t)!,
      onDanger: Color.lerp(a.onDanger, b.onDanger, t)!,
      dangerSubtle: Color.lerp(a.dangerSubtle, b.dangerSubtle, t)!,
      overlay: Color.lerp(a.overlay, b.overlay, t)!,
      accentText: Color.lerp(a.accentText, b.accentText, t)!,
      hairline: Color.lerp(a.hairline, b.hairline, t)!,
      textFaint: Color.lerp(a.textFaint, b.textFaint, t)!,
      headRule: Color.lerp(a.headRule, b.headRule, t)!,
      accentRule: Color.lerp(a.accentRule, b.accentRule, t)!,
      moneyIn: Color.lerp(a.moneyIn, b.moneyIn, t)!,
      moneyInCents: Color.lerp(a.moneyInCents, b.moneyInCents, t)!,
      over: Color.lerp(a.over, b.over, t)!,
      overCents: Color.lerp(a.overCents, b.overCents, t)!,
      move: Color.lerp(a.move, b.move, t)!,
      moveCents: Color.lerp(a.moveCents, b.moveCents, t)!,
      pace: Color.lerp(a.pace, b.pace, t)!,
      seal: Color.lerp(a.seal, b.seal, t)!,
      sealOver: Color.lerp(a.sealOver, b.sealOver, t)!,
      sealInk: Color.lerp(a.sealInk, b.sealInk, t)!,
      hatchInk: Color.lerp(a.hatchInk, b.hatchInk, t)!,
      hatchGreen: Color.lerp(a.hatchGreen, b.hatchGreen, t)!,
      hatchPale: Color.lerp(a.hatchPale, b.hatchPale, t)!,
      topBarFill: Color.lerp(a.topBarFill, b.topBarFill, t)!,
      tabBarFill: Color.lerp(a.tabBarFill, b.tabBarFill, t)!,
      sideBarFill: Color.lerp(a.sideBarFill, b.sideBarFill, t)!,
      selectedFill: Color.lerp(a.selectedFill, b.selectedFill, t)!,
      selectedRing: Color.lerp(a.selectedRing, b.selectedRing, t)!,
      discRing: Color.lerp(a.discRing, b.discRing, t)!,
      dotRing: Color.lerp(a.dotRing, b.dotRing, t)!,
      avatar: Color.lerp(a.avatar, b.avatar, t)!,
      onAvatar: Color.lerp(a.onAvatar, b.onAvatar, t)!,
      toast: Color.lerp(a.toast, b.toast, t)!,
      onToast: Color.lerp(a.onToast, b.onToast, t)!,
      onToastAction: Color.lerp(a.onToastAction, b.onToastAction, t)!,
      toastRing: Color.lerp(a.toastRing, b.toastRing, t)!,
      menuSelected: Color.lerp(a.menuSelected, b.menuSelected, t)!,
      paperShadow: BoxShadow.lerpList(a.paperShadow, b.paperShadow, t)!,
      sheetShadow: BoxShadow.lerpList(a.sheetShadow, b.sheetShadow, t)!,
      dialogShadow: BoxShadow.lerpList(a.dialogShadow, b.dialogShadow, t)!,
      menuShadow: BoxShadow.lerpList(a.menuShadow, b.menuShadow, t)!,
      toastShadow: BoxShadow.lerpList(a.toastShadow, b.toastShadow, t)!,
      primaryShadow: BoxShadow.lerpList(a.primaryShadow, b.primaryShadow, t)!,
      discShadow: BoxShadow.lerpList(a.discShadow, b.discShadow, t)!,
      figure: TextStyle.lerp(a.figure, b.figure, t)!,
      figureMedium: TextStyle.lerp(a.figureMedium, b.figureMedium, t)!,
      figureSmall: TextStyle.lerp(a.figureSmall, b.figureSmall, t)!,
      title: TextStyle.lerp(a.title, b.title, t)!,
      barTitle: TextStyle.lerp(a.barTitle, b.barTitle, t)!,
      sheetTitle: TextStyle.lerp(a.sheetTitle, b.sheetTitle, t)!,
      wordmark: TextStyle.lerp(a.wordmark, b.wordmark, t)!,
      body: TextStyle.lerp(a.body, b.body, t)!,
      rowTitle: TextStyle.lerp(a.rowTitle, b.rowTitle, t)!,
      bodySmall: TextStyle.lerp(a.bodySmall, b.bodySmall, t)!,
      label: TextStyle.lerp(a.label, b.label, t)!,
      meta: TextStyle.lerp(a.meta, b.meta, t)!,
      amount: TextStyle.lerp(a.amount, b.amount, t)!,
      tab: TextStyle.lerp(a.tab, b.tab, t)!,
      button: TextStyle.lerp(a.button, b.button, t)!,
      buttonSmall: TextStyle.lerp(a.buttonSmall, b.buttonSmall, t)!,
      navLink: TextStyle.lerp(a.navLink, b.navLink, t)!,
      link: TextStyle.lerp(a.link, b.link, t)!,
      pill: TextStyle.lerp(a.pill, b.pill, t)!,
      tag: TextStyle.lerp(a.tag, b.tag, t)!,
      toastText: TextStyle.lerp(a.toastText, b.toastText, t)!,
      toastAction: TextStyle.lerp(a.toastAction, b.toastAction, t)!,
      monogram: TextStyle.lerp(a.monogram, b.monogram, t)!,
      initials: TextStyle.lerp(a.initials, b.initials, t)!,
      footnote: TextStyle.lerp(a.footnote, b.footnote, t)!,
      search: TextStyle.lerp(a.search, b.search, t)!,
      cardRadius: lerpDouble(a.cardRadius, b.cardRadius, t)!,
      controlRadius: lerpDouble(a.controlRadius, b.controlRadius, t)!,
      smallRadius: lerpDouble(a.smallRadius, b.smallRadius, t)!,
      sheetRadius: lerpDouble(a.sheetRadius, b.sheetRadius, t)!,
      density: t < 0.5 ? a.density : b.density,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerThemeData &&
          other.id == id &&
          other.brightness == brightness &&
          other.background == background &&
          other.surface == surface &&
          other.surfaceAlt == surfaceAlt &&
          other.surfaceInverse == surfaceInverse &&
          other.border == border &&
          other.borderStrong == borderStrong &&
          other.textPrimary == textPrimary &&
          other.textSecondary == textSecondary &&
          other.textTertiary == textTertiary &&
          other.textInverse == textInverse &&
          other.accent == accent &&
          other.onAccent == onAccent &&
          other.accentSubtle == accentSubtle &&
          other.success == success &&
          other.onSuccess == onSuccess &&
          other.successSubtle == successSubtle &&
          other.warning == warning &&
          other.warningSubtle == warningSubtle &&
          other.danger == danger &&
          other.onDanger == onDanger &&
          other.dangerSubtle == dangerSubtle &&
          other.overlay == overlay &&
          other.accentText == accentText &&
          other.hairline == hairline &&
          other.textFaint == textFaint &&
          other.headRule == headRule &&
          other.accentRule == accentRule &&
          other.moneyIn == moneyIn &&
          other.moneyInCents == moneyInCents &&
          other.over == over &&
          other.overCents == overCents &&
          other.move == move &&
          other.moveCents == moveCents &&
          other.pace == pace &&
          other.seal == seal &&
          other.sealOver == sealOver &&
          other.sealInk == sealInk &&
          other.hatchInk == hatchInk &&
          other.hatchGreen == hatchGreen &&
          other.hatchPale == hatchPale &&
          other.topBarFill == topBarFill &&
          other.tabBarFill == tabBarFill &&
          other.sideBarFill == sideBarFill &&
          other.selectedFill == selectedFill &&
          other.selectedRing == selectedRing &&
          other.discRing == discRing &&
          other.dotRing == dotRing &&
          other.avatar == avatar &&
          other.onAvatar == onAvatar &&
          other.toast == toast &&
          other.onToast == onToast &&
          other.onToastAction == onToastAction &&
          other.toastRing == toastRing &&
          other.menuSelected == menuSelected &&
          listEquals(other.paperShadow, paperShadow) &&
          listEquals(other.sheetShadow, sheetShadow) &&
          listEquals(other.dialogShadow, dialogShadow) &&
          listEquals(other.menuShadow, menuShadow) &&
          listEquals(other.toastShadow, toastShadow) &&
          listEquals(other.primaryShadow, primaryShadow) &&
          listEquals(other.discShadow, discShadow) &&
          other.figure == figure &&
          other.figureMedium == figureMedium &&
          other.figureSmall == figureSmall &&
          other.title == title &&
          other.barTitle == barTitle &&
          other.sheetTitle == sheetTitle &&
          other.wordmark == wordmark &&
          other.body == body &&
          other.rowTitle == rowTitle &&
          other.bodySmall == bodySmall &&
          other.label == label &&
          other.meta == meta &&
          other.amount == amount &&
          other.tab == tab &&
          other.button == button &&
          other.buttonSmall == buttonSmall &&
          other.navLink == navLink &&
          other.link == link &&
          other.pill == pill &&
          other.tag == tag &&
          other.toastText == toastText &&
          other.toastAction == toastAction &&
          other.monogram == monogram &&
          other.initials == initials &&
          other.footnote == footnote &&
          other.search == search &&
          other.cardRadius == cardRadius &&
          other.controlRadius == controlRadius &&
          other.smallRadius == smallRadius &&
          other.sheetRadius == sheetRadius &&
          other.density == density;

  @override
  int get hashCode => Object.hashAll([
    id,
    brightness,
    background,
    surface,
    surfaceAlt,
    surfaceInverse,
    border,
    borderStrong,
    textPrimary,
    textSecondary,
    textTertiary,
    textInverse,
    accent,
    onAccent,
    accentSubtle,
    success,
    onSuccess,
    successSubtle,
    warning,
    warningSubtle,
    danger,
    onDanger,
    dangerSubtle,
    overlay,
    accentText,
    hairline,
    textFaint,
    headRule,
    accentRule,
    moneyIn,
    moneyInCents,
    over,
    overCents,
    move,
    moveCents,
    pace,
    seal,
    sealOver,
    sealInk,
    hatchInk,
    hatchGreen,
    hatchPale,
    topBarFill,
    tabBarFill,
    sideBarFill,
    selectedFill,
    selectedRing,
    discRing,
    dotRing,
    avatar,
    onAvatar,
    toast,
    onToast,
    onToastAction,
    toastRing,
    menuSelected,
    Object.hashAll(paperShadow),
    Object.hashAll(sheetShadow),
    Object.hashAll(dialogShadow),
    Object.hashAll(menuShadow),
    Object.hashAll(toastShadow),
    Object.hashAll(primaryShadow),
    Object.hashAll(discShadow),
    figure,
    figureMedium,
    figureSmall,
    title,
    barTitle,
    sheetTitle,
    wordmark,
    body,
    rowTitle,
    bodySmall,
    label,
    meta,
    amount,
    tab,
    button,
    buttonSmall,
    navLink,
    link,
    pill,
    tag,
    toastText,
    toastAction,
    monogram,
    initials,
    footnote,
    search,
    cardRadius,
    controlRadius,
    smallRadius,
    sheetRadius,
    density,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(ColorProperty('background', background))
      ..add(ColorProperty('surface', surface))
      ..add(ColorProperty('surfaceAlt', surfaceAlt))
      ..add(ColorProperty('surfaceInverse', surfaceInverse))
      ..add(ColorProperty('border', border))
      ..add(ColorProperty('borderStrong', borderStrong))
      ..add(ColorProperty('textPrimary', textPrimary))
      ..add(ColorProperty('textSecondary', textSecondary))
      ..add(ColorProperty('textTertiary', textTertiary))
      ..add(ColorProperty('textInverse', textInverse))
      ..add(ColorProperty('accent', accent))
      ..add(ColorProperty('onAccent', onAccent))
      ..add(ColorProperty('accentSubtle', accentSubtle))
      ..add(ColorProperty('success', success))
      ..add(ColorProperty('onSuccess', onSuccess))
      ..add(ColorProperty('successSubtle', successSubtle))
      ..add(ColorProperty('warning', warning))
      ..add(ColorProperty('warningSubtle', warningSubtle))
      ..add(ColorProperty('danger', danger))
      ..add(ColorProperty('onDanger', onDanger))
      ..add(ColorProperty('dangerSubtle', dangerSubtle))
      ..add(ColorProperty('overlay', overlay))
      ..add(ColorProperty('accentText', accentText))
      ..add(ColorProperty('hairline', hairline))
      ..add(ColorProperty('textFaint', textFaint))
      ..add(ColorProperty('headRule', headRule))
      ..add(ColorProperty('accentRule', accentRule))
      ..add(ColorProperty('moneyIn', moneyIn))
      ..add(ColorProperty('moneyInCents', moneyInCents))
      ..add(ColorProperty('over', over))
      ..add(ColorProperty('overCents', overCents))
      ..add(ColorProperty('move', move))
      ..add(ColorProperty('moveCents', moveCents))
      ..add(ColorProperty('pace', pace))
      ..add(ColorProperty('seal', seal))
      ..add(ColorProperty('sealOver', sealOver))
      ..add(ColorProperty('sealInk', sealInk))
      ..add(ColorProperty('hatchInk', hatchInk))
      ..add(ColorProperty('hatchGreen', hatchGreen))
      ..add(ColorProperty('hatchPale', hatchPale))
      ..add(ColorProperty('topBarFill', topBarFill))
      ..add(ColorProperty('tabBarFill', tabBarFill))
      ..add(ColorProperty('sideBarFill', sideBarFill))
      ..add(ColorProperty('selectedFill', selectedFill))
      ..add(ColorProperty('selectedRing', selectedRing))
      ..add(ColorProperty('discRing', discRing))
      ..add(ColorProperty('dotRing', dotRing))
      ..add(ColorProperty('avatar', avatar))
      ..add(ColorProperty('onAvatar', onAvatar))
      ..add(ColorProperty('toast', toast))
      ..add(ColorProperty('onToast', onToast))
      ..add(ColorProperty('onToastAction', onToastAction))
      ..add(ColorProperty('toastRing', toastRing))
      ..add(ColorProperty('menuSelected', menuSelected))
      ..add(IterableProperty<BoxShadow>('paperShadow', paperShadow))
      ..add(IterableProperty<BoxShadow>('sheetShadow', sheetShadow))
      ..add(IterableProperty<BoxShadow>('dialogShadow', dialogShadow))
      ..add(IterableProperty<BoxShadow>('menuShadow', menuShadow))
      ..add(IterableProperty<BoxShadow>('toastShadow', toastShadow))
      ..add(IterableProperty<BoxShadow>('primaryShadow', primaryShadow))
      ..add(IterableProperty<BoxShadow>('discShadow', discShadow))
      ..add(DiagnosticsProperty<TextStyle>('figure', figure))
      ..add(DiagnosticsProperty<TextStyle>('figureMedium', figureMedium))
      ..add(DiagnosticsProperty<TextStyle>('figureSmall', figureSmall))
      ..add(DiagnosticsProperty<TextStyle>('title', title))
      ..add(DiagnosticsProperty<TextStyle>('barTitle', barTitle))
      ..add(DiagnosticsProperty<TextStyle>('sheetTitle', sheetTitle))
      ..add(DiagnosticsProperty<TextStyle>('wordmark', wordmark))
      ..add(DiagnosticsProperty<TextStyle>('body', body))
      ..add(DiagnosticsProperty<TextStyle>('rowTitle', rowTitle))
      ..add(DiagnosticsProperty<TextStyle>('bodySmall', bodySmall))
      ..add(DiagnosticsProperty<TextStyle>('label', label))
      ..add(DiagnosticsProperty<TextStyle>('meta', meta))
      ..add(DiagnosticsProperty<TextStyle>('amount', amount))
      ..add(DiagnosticsProperty<TextStyle>('tab', tab))
      ..add(DiagnosticsProperty<TextStyle>('button', button))
      ..add(DiagnosticsProperty<TextStyle>('buttonSmall', buttonSmall))
      ..add(DiagnosticsProperty<TextStyle>('navLink', navLink))
      ..add(DiagnosticsProperty<TextStyle>('link', link))
      ..add(DiagnosticsProperty<TextStyle>('pill', pill))
      ..add(DiagnosticsProperty<TextStyle>('tag', tag))
      ..add(DiagnosticsProperty<TextStyle>('toastText', toastText))
      ..add(DiagnosticsProperty<TextStyle>('toastAction', toastAction))
      ..add(DiagnosticsProperty<TextStyle>('monogram', monogram))
      ..add(DiagnosticsProperty<TextStyle>('initials', initials))
      ..add(DiagnosticsProperty<TextStyle>('footnote', footnote))
      ..add(DiagnosticsProperty<TextStyle>('search', search))
      ..add(DoubleProperty('cardRadius', cardRadius))
      ..add(DoubleProperty('controlRadius', controlRadius))
      ..add(DoubleProperty('smallRadius', smallRadius))
      ..add(DoubleProperty('sheetRadius', sheetRadius))
      ..add(DiagnosticsProperty<LedgerDensity>('density', density));
  }

  // GENERATED-END

  /// Whether this is a dark appearance.
  bool get isDark => brightness == Brightness.dark;

  /// How an ink pressed into the paper (a seal's engraving, its words and
  /// its wash) lays over what is under it: multiplied into a light paper,
  /// as the source sets it, and screened onto a dark one, where a multiply
  /// would sink the ink into the night paper.
  BlendMode get pressBlend => isDark ? BlendMode.screen : BlendMode.multiply;

  /// The ink of an amount or a figure in [tone], and of its cents.
  ({Color ink, Color cents}) inks(LedgerTone tone) => switch (tone) {
    LedgerTone.plain => (ink: textPrimary, cents: textTertiary),
    LedgerTone.moneyIn => (ink: moneyIn, cents: moneyInCents),
    LedgerTone.over => (ink: over, cents: overCents),
    LedgerTone.move => (ink: move, cents: moveCents),
  };

  /// The source's type scale: each slot's face, size, line, weight and
  /// tracking (in em), and the catalog slot a token set sizes it by.
  static const _scale = (
    figure: _Slot(_Face.serif, 88, 88 * .84, 400, -.012, _Anchor.giant),
    figureMedium: _Slot(_Face.serif, 44, 44 * .84, 400, -.012, _Anchor.display),
    figureSmall: _Slot(_Face.serif, 28, 30, 400, -.012, _Anchor.h1),
    title: _Slot(_Face.serif, 30, 33, 400, -.005, _Anchor.h1),
    barTitle: _Slot(_Face.serif, 24, 24, 400, -.005, _Anchor.h2),
    sheetTitle: _Slot(_Face.serif, 28, 30, 400, -.005, _Anchor.h1),
    wordmark: _Slot(_Face.serif, 28, 28, 400, -.01, _Anchor.h1),
    body: _Slot(_Face.sans, 15, 15 * 1.45, 400, 0, _Anchor.body),
    rowTitle: _Slot(_Face.sans, 15, 20, 500, 0, _Anchor.body),
    bodySmall: _Slot(_Face.sans, 13, 18, 400, 0, _Anchor.bodySmall),
    label: _Slot(_Face.sans, 11, 16, 600, .14, _Anchor.label),
    meta: _Slot(_Face.mono, 11, 16, 400, .04, _Anchor.mono),
    amount: _Slot(_Face.mono, 14, 20, 500, -.02, _Anchor.mono),
    tab: _Slot(_Face.sans, 11, 12, 500, 0, _Anchor.label),
    button: _Slot(_Face.sans, 15, 15, 600, 0, _Anchor.body),
    buttonSmall: _Slot(_Face.sans, 13, 13, 500, 0, _Anchor.bodySmall),
    navLink: _Slot(_Face.sans, 14.5, 14.5, 500, 0, _Anchor.body),
    link: _Slot(_Face.mono, 11, 16, 500, .04, _Anchor.mono),
    pill: _Slot(_Face.mono, 12, 12, 500, -.01, _Anchor.mono),
    tag: _Slot(_Face.mono, 11, 12, 500, .06, _Anchor.mono),
    toastText: _Slot(_Face.sans, 15, 20, 500, 0, _Anchor.body),
    toastAction: _Slot(_Face.mono, 12, 36, 500, .06, _Anchor.mono),
    monogram: _Slot(_Face.italic, 16, 16, 400, .03, _Anchor.body),
    initials: _Slot(_Face.italic, 15, 15, 400, .04, _Anchor.body),
    footnote: _Slot(_Face.mono, 11, 12, 500, 0, _Anchor.mono),
    search: _Slot(_Face.sans, 15, 15, 400, 0, _Anchor.body),
  );

  /// The size the source gives each catalog slot's place in its scale: what
  /// a token set's slot is measured against when it sizes a Ledger slot.
  static double _sourceSize(_Anchor anchor) => switch (anchor) {
    _Anchor.giant => _scale.figure.size,
    _Anchor.display => _scale.figureMedium.size,
    _Anchor.h1 => _scale.title.size,
    _Anchor.h2 => _scale.barTitle.size,
    _Anchor.body => _scale.body.size,
    _Anchor.bodySmall => _scale.bodySmall.size,
    _Anchor.label => _scale.label.size,
    _Anchor.mono => _scale.amount.size,
  };

  /// [slot] as a TextStyle in [color], its size scaled by [factor]
  /// (the line keeps its multiple, the tracking its em).
  static TextStyle _type(_Slot slot, Color color, [double factor = 1]) {
    final size = slot.size * factor;
    return TextStyle(
      fontFamily: switch (slot.face) {
        _Face.sans => face,
        _Face.serif || _Face.italic => serifFace,
        _Face.mono => monoFace,
      },
      package: ledgerFontPackage,
      fontStyle: slot.face == _Face.italic ? FontStyle.italic : null,
      fontSize: size,
      fontWeight: FontWeight(slot.weight),
      height: slot.line / slot.size,
      letterSpacing: slot.trackingEm * size,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
    );
  }

  /// The book by day: warm paper, the ink and the green seal, as the Keel /
  /// Ledger pilot's stylesheet sets them. [density] defaults to the
  /// platform's.
  ///
  /// ```dart
  /// LedgerTheme(data: LedgerThemeData.light(), child: page)
  /// ```
  factory LedgerThemeData.light({LedgerDensity? density}) => _withDensity(
    _ledgerLight,
    density ?? LedgerDensity.adaptivePlatformDensity,
  );

  /// The same book by lamplight: a warm umber paper, cream ink and a jade
  /// seal, designed rather than inverted. [density] defaults to the
  /// platform's.
  factory LedgerThemeData.dark({LedgerDensity? density}) => _withDensity(
    _ledgerDark,
    density ?? LedgerDensity.adaptivePlatformDensity,
  );

  /// A Ledger theme in an app's own colours: its [paper] (the page), its
  /// [ink] (words and rules) and its [accent] (the one act, money in and the
  /// seal), with [over] for amounts past a limit (the source's vermilion by
  /// default). The raised and sunken papers, the second, third and faint
  /// inks, the rules and the washes follow from them as the source's do from
  /// its own, and every ink that sets words is eased toward [ink] until it
  /// reads 4.5:1 on every paper. [brightness] says which side of the paper
  /// the colours are: a dark paper with a light ink is a night book.
  ///
  /// ```dart
  /// LedgerThemeData.from(
  ///   paper: const Color(0xFFF4F1EA),
  ///   ink: const Color(0xFF1B2433),
  ///   accent: const Color(0xFF2B4C9B),
  /// )
  /// ```
  factory LedgerThemeData.from({
    required Color paper,
    required Color ink,
    required Color accent,
    Color? over,
    Brightness? brightness,
    LedgerDensity? density,
  }) {
    final b =
        brightness ??
        (paper.computeLuminance() < ink.computeLuminance()
            ? Brightness.dark
            : Brightness.light);
    final dark = b == Brightness.dark;
    final base = dark ? _nightInks : _dayInks;
    final hi = Color.lerp(paper, dark ? ink : const Color(0xFFFFFFFF), .06)!;
    final lo = Color.lerp(paper, dark ? const Color(0xFF000000) : ink, .05)!;
    final grounds = [paper, hi, lo];
    Color words(Color c) => _reach(c, ink, grounds, 4.5);
    final red = words(over ?? base.red);
    final green = words(accent);
    final onGreen = contrast(paper, green) >= contrast(ink, green) ? hi : ink;
    final inks = (
      paper: paper,
      paperHi: hi,
      paperLo: lo,
      ink: ink,
      ink2: words(Color.lerp(ink, paper, .35)!),
      ink3: words(Color.lerp(ink, paper, .5)!),
      ink4: Color.lerp(ink, paper, .62)!,
      rule: ink.withValues(alpha: base.rule.a),
      rule2: ink.withValues(alpha: base.rule2.a),
      green: green,
      greenWash: Color.lerp(paper, accent, .16)!,
      greenRule: accent.withValues(alpha: base.greenRule.a),
      red: red,
      redWash: Color.lerp(paper, red, .16)!,
      onGreen: onGreen,
      onRed: contrast(paper, red) >= contrast(ink, red) ? hi : ink,
      scrim: base.scrim,
      toastFill: dark ? Color.lerp(paper, ink, .1)! : ink,
      toastInk: dark ? ink : hi,
      toastAction: dark
          ? green
          : _reach(Color.lerp(accent, hi, .7)!, hi, [ink], 4.5),
      toastRing: dark
          ? ink.withValues(alpha: base.toastRing.a)
          : hi.withValues(alpha: base.toastRing.a),
      actShadow: base.actShadow,
      discShadow: base.discShadow,
    );
    return _build(
      'custom',
      b,
      inks,
    ).copyWith(density: density ?? LedgerDensity.adaptivePlatformDensity);
  }

  static LedgerThemeData _withDensity(LedgerThemeData t, LedgerDensity d) =>
      t.density == d ? t : t.copyWith(density: d);

  /// The source's day inks, from `_Source`.
  static final _Inks _dayInks = (
    paper: _Source.paper,
    paperHi: _Source.paperHi,
    paperLo: _Source.paperLo,
    ink: _Source.ink,
    ink2: _Source.ink2,
    ink3: _Source.ink3,
    ink4: _Source.ink4,
    rule: _Source.rule,
    rule2: _Source.rule2,
    green: _Source.green,
    greenWash: _Source.greenWash,
    greenRule: _Source.greenRule,
    red: _Source.red,
    redWash: _Source.redWash,
    onGreen: _Source.paperHi,
    onRed: _Source.paperHi,
    scrim: _Source.scrim,
    toastFill: _Source.ink,
    toastInk: _Source.paperHi,
    toastAction: _Source.toastAction,
    toastRing: _Source.toastRing,
    actShadow: _Source.primaryShadow,
    discShadow: _Source.discShadow,
  );

  /// The designed night inks, from `_Night`.
  static final _Inks _nightInks = (
    paper: _Night.paper,
    paperHi: _Night.paperHi,
    paperLo: _Night.paperLo,
    ink: _Night.ink,
    ink2: _Night.ink2,
    ink3: _Night.ink3,
    ink4: _Night.ink4,
    rule: _Night.rule,
    rule2: _Night.rule2,
    green: _Night.green,
    greenWash: _Night.greenWash,
    greenRule: _Night.greenRule,
    red: _Night.red,
    redWash: _Night.redWash,
    onGreen: _Night.onSeal,
    onRed: _Night.onSeal,
    scrim: _Night.scrim,
    // The toast: at night a raised slip of the paper, so the page's one
    // bright face stays the act.
    toastFill: _Night.slip,
    toastInk: _Night.ink,
    toastAction: _Night.green,
    toastRing: _Night.slipRing,
    actShadow: _Night.actShadow,
    discShadow: _Night.discShadow,
  );

  static LedgerThemeData _quire(Brightness brightness) => _build(
    'quire',
    brightness,
    brightness == Brightness.dark ? _nightInks : _dayInks,
  );

  /// The whole theme from one set of inks: the source's roles, rules and
  /// type, in [i].
  static LedgerThemeData _build(String id, Brightness brightness, _Inks i) {
    final dark = brightness == Brightness.dark;
    const black = Color(0xFF000000);
    final background = i.paper;
    final surface = i.paperHi;
    final surfaceAlt = i.paperLo;
    final ink = i.ink;
    final ink2 = i.ink2;
    final ink3 = i.ink3;
    final ink4 = i.ink4;
    final rule = i.rule;
    final rule2 = i.rule2;
    final green = i.green;
    final greenWords = green;
    final red = i.red;
    final onGreen = i.onGreen;
    final greenWash = i.greenWash;
    final redWash = i.redWash;
    final inverse = i.ink;
    final onInverse = dark ? i.paper : i.paperHi;
    final toastFill = i.toastFill;
    final toastInk = i.toastInk;
    final toastActionInk = i.toastAction;
    // Shadows keep their geometry; on the night paper they fall in black,
    // twice as deep.
    Color shade(Color c) =>
        dark ? black.withValues(alpha: (c.a * 2).clamp(0, 1).toDouble()) : c;
    List<BoxShadow> shadows(List<BoxShadow> layers) => [
      for (final s in layers)
        BoxShadow(
          color: shade(s.color),
          offset: s.offset,
          blurRadius: s.blurRadius,
          spreadRadius: s.spreadRadius,
        ),
    ];
    final paperShadow = shadows(_Source.paperShadow);
    // The vermilion as words: eased toward the ink until it reads 4.5:1 on
    // every paper it is written on, its wash too (the raw --red is 4.2:1 on
    // the day paper). Its fills, rings and seals keep the raw one.
    final overWords = _reach(red, ink, [
      background,
      surface,
      surfaceAlt,
      redWash,
    ], 4.5);
    return LedgerThemeData(
      id: id,
      brightness: brightness,
      background: background,
      surface: surface,
      surfaceAlt: surfaceAlt,
      surfaceInverse: inverse,
      border: rule,
      borderStrong: ink,
      textPrimary: ink,
      textSecondary: ink2,
      textTertiary: ink3,
      textInverse: onInverse,
      accent: green,
      onAccent: onGreen,
      accentSubtle: greenWash,
      success: greenWords,
      onSuccess: onGreen,
      successSubtle: greenWash,
      warning: ink2,
      warningSubtle: surfaceAlt,
      danger: red,
      onDanger: i.onRed,
      dangerSubtle: redWash,
      overlay: i.scrim,
      accentText: greenWords,
      hairline: rule2,
      textFaint: ink4,
      headRule: ink,
      accentRule: i.greenRule,
      moneyIn: greenWords,
      moneyInCents: greenWords.withValues(alpha: _Source.centsVeil),
      over: overWords,
      overCents: overWords.withValues(alpha: _Source.centsVeil),
      move: ink3,
      moveCents: ink4,
      pace: green,
      seal: green,
      sealOver: red,
      sealInk: ink2,
      hatchInk: ink.withValues(alpha: _Source.hatchStrong),
      hatchGreen: green.withValues(alpha: _Source.hatchStrong),
      hatchPale: ink.withValues(alpha: _Source.hatchPale),
      topBarFill: background.withValues(alpha: _Source.topBarFill.a),
      tabBarFill: surface.withValues(alpha: _Source.tabBarFill.a),
      sideBarFill: surfaceAlt,
      selectedFill: surface,
      selectedRing: rule2,
      discRing: surface,
      dotRing: background,
      avatar: ink,
      onAvatar: background,
      toast: toastFill,
      onToast: toastInk,
      onToastAction: toastActionInk,
      toastRing: i.toastRing,
      menuSelected: background,
      paperShadow: paperShadow,
      sheetShadow: shadows(_Source.sheetShadow),
      dialogShadow: shadows(_Source.dialogShadow),
      menuShadow: shadows(_Source.menuShadow),
      toastShadow: shadows(_Source.toastShadow),
      primaryShadow: i.actShadow,
      discShadow: i.discShadow,
      figure: _type(_scale.figure, ink),
      figureMedium: _type(_scale.figureMedium, ink),
      figureSmall: _type(_scale.figureSmall, ink),
      title: _type(_scale.title, ink),
      barTitle: _type(_scale.barTitle, ink),
      sheetTitle: _type(_scale.sheetTitle, ink),
      wordmark: _type(_scale.wordmark, ink),
      body: _type(_scale.body, ink),
      rowTitle: _type(_scale.rowTitle, ink),
      bodySmall: _type(_scale.bodySmall, ink3),
      label: _type(_scale.label, ink),
      meta: _type(_scale.meta, ink3),
      amount: _type(_scale.amount, ink),
      tab: _type(_scale.tab, ink3),
      button: _type(_scale.button, ink),
      buttonSmall: _type(_scale.buttonSmall, ink),
      navLink: _type(_scale.navLink, ink2),
      link: _type(_scale.link, greenWords),
      pill: _type(_scale.pill, ink2),
      tag: _type(_scale.tag, ink2),
      toastText: _type(_scale.toastText, toastInk),
      toastAction: _type(_scale.toastAction, toastActionInk),
      monogram: _type(_scale.monogram, ink),
      initials: _type(_scale.initials, background),
      footnote: _type(_scale.footnote, greenWords),
      search: _type(_scale.search, ink3),
      cardRadius: _Source.rSheet,
      controlRadius: LedgerCorners.rFull,
      smallRadius: _Source.rSheet,
      sheetRadius: _Source.rSheet,
    );
  }

  /// A catalog theme dressed in Ledger's roles: the token set's colours,
  /// shadows, sizes and shape, Ledger's faces, weights, leading and
  /// tracking (the bundled faces carry only the source's weights). Ledger's
  /// own roles follow from the token roles by the rules below; a quiet ink
  /// that sets words, and the accent's words, are eased toward the next ink
  /// until they read (4.5:1) on every paper. Both appearances are the
  /// record's own; at night the toast follows the designed night (`_Night`):
  /// a raised slip of the paper with the page's ink, not a bright inverse
  /// slab, so the act stays the one bright face. The accent is one ink, a
  /// word on the paper and a ground under `onAccent`: where `onAccent`
  /// cannot read 4.5:1 on the eased accent words, the act wears those words'
  /// colour, with the page or its ink (whichever reads better) as its words.
  /// A record's translucent surface is laid on its page: Ledger's papers are
  /// opaque.
  factory LedgerThemeData.fromTokens(
    String id,
    LedgerTokens tokens,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final c = dark ? tokens.dark : tokens.light;
    // Ledger's papers are opaque: a record's frosted surface is laid on its
    // page, so a sheet or a dialog over the scrim stays the paper it is on
    // the page (frost's white at 78% would read grey there).
    final paper = Color.alphaBlend(c.surface, c.background);
    final grounds = [c.background, paper, c.surfaceAlt];
    double factor(_Slot slot) =>
        (switch (slot.anchor) {
          _Anchor.giant => tokens.giant.size,
          _Anchor.display => tokens.display.size,
          _Anchor.h1 => tokens.h1.size,
          _Anchor.h2 => tokens.h2.size,
          _Anchor.body => tokens.body.size,
          _Anchor.bodySmall => tokens.bodySmall.size,
          _Anchor.label => tokens.label.size,
          _Anchor.mono => tokens.mono.size,
        }) /
        _sourceSize(slot.anchor);
    TextStyle type(_Slot slot, Color color) => _type(slot, color, factor(slot));
    final ink3 = _reach(c.textTertiary, c.textSecondary, grounds, 4.5);
    final moneyIn = _reach(c.success, c.textPrimary, grounds, 4.5);
    final over = _reach(c.danger, c.textPrimary, [
      ...grounds,
      c.dangerSubtle,
    ], 4.5);
    final hairline = c.textPrimary.withValues(alpha: _Source.rule2.a);
    final accentText = _reach(c.accentText, c.textPrimary, grounds, 4.5);
    // The accent is one ink: words on the paper and, under `onAccent`, a
    // ground (a brand panel, the act stamped on it). Where the record's
    // `onAccent` cannot read 4.5:1 on the eased words (a deep blue lifted to
    // read on a navy night), the act takes the words' colour and whichever
    // of the page and its ink reads better on it as its own words.
    final heldAct = contrast(c.onAccent, accentText) >= 4.5;
    final accent = heldAct ? c.accent : accentText;
    final onAccent = heldAct
        ? c.onAccent
        : contrast(c.background, accentText) >=
              contrast(c.textPrimary, accentText)
        ? c.background
        : c.textPrimary;
    const white = Color(0xFFFFFFFF);
    final toastFill = dark
        ? Color.lerp(c.surfaceAlt, white, 0.04)!
        : c.surfaceInverse;
    final toastInk = dark ? c.textPrimary : c.textInverse;
    final toastAction = _reach(accent, toastInk, [toastFill], 4.5);
    List<BoxShadow> shadows(List<LedgerTokenShadow> layers) => [
      for (final s in layers) s.shadow,
    ];
    return LedgerThemeData(
      id: id,
      brightness: brightness,
      background: c.background,
      surface: paper,
      surfaceAlt: c.surfaceAlt,
      surfaceInverse: c.surfaceInverse,
      border: c.border,
      borderStrong: c.borderStrong,
      textPrimary: c.textPrimary,
      textSecondary: c.textSecondary,
      textTertiary: ink3,
      textInverse: c.textInverse,
      accent: accent,
      onAccent: onAccent,
      accentSubtle: c.accentSubtle,
      success: c.success,
      onSuccess: c.onSuccess,
      successSubtle: c.successSubtle,
      warning: c.warning,
      warningSubtle: c.warningSubtle,
      danger: c.danger,
      onDanger: c.onDanger,
      dangerSubtle: c.dangerSubtle,
      overlay: c.overlay,
      accentText: accentText,
      hairline: hairline,
      textFaint: c.textTertiary,
      headRule: c.textPrimary,
      accentRule: accent.withValues(alpha: _Source.greenRule.a),
      moneyIn: moneyIn,
      moneyInCents: moneyIn.withValues(alpha: _Source.centsVeil),
      over: over,
      overCents: over.withValues(alpha: _Source.centsVeil),
      move: ink3,
      moveCents: c.textTertiary,
      pace: accent,
      seal: accent,
      sealOver: over,
      sealInk: c.textSecondary,
      hatchInk: c.textPrimary.withValues(alpha: _Source.hatchStrong),
      hatchGreen: accent.withValues(alpha: _Source.hatchStrong),
      hatchPale: c.textPrimary.withValues(alpha: _Source.hatchPale),
      topBarFill: c.background.withValues(alpha: _Source.topBarFill.a),
      tabBarFill: paper.withValues(alpha: _Source.tabBarFill.a),
      sideBarFill: c.surfaceAlt,
      selectedFill: paper,
      selectedRing: hairline,
      discRing: paper,
      dotRing: c.background,
      avatar: c.textPrimary,
      onAvatar: c.background,
      toast: toastFill,
      onToast: toastInk,
      onToastAction: toastAction,
      toastRing: dark
          ? c.textPrimary.withValues(alpha: _Night.slipRing.a)
          : c.textInverse.withValues(alpha: _Source.toastRing.a),
      menuSelected: c.background,
      paperShadow: shadows(c.shadowSm),
      sheetShadow: shadows(c.shadowLg),
      dialogShadow: shadows(c.shadowLg),
      menuShadow: shadows(c.shadowMd),
      toastShadow: shadows(c.shadowMd),
      primaryShadow: shadows(c.shadowSm),
      discShadow: shadows(c.shadowMd),
      figure: type(_scale.figure, c.textPrimary),
      figureMedium: type(_scale.figureMedium, c.textPrimary),
      figureSmall: type(_scale.figureSmall, c.textPrimary),
      title: type(_scale.title, c.textPrimary),
      barTitle: type(_scale.barTitle, c.textPrimary),
      sheetTitle: type(_scale.sheetTitle, c.textPrimary),
      wordmark: type(_scale.wordmark, c.textPrimary),
      body: type(_scale.body, c.textPrimary),
      rowTitle: type(_scale.rowTitle, c.textPrimary),
      bodySmall: type(_scale.bodySmall, ink3),
      label: type(_scale.label, c.textPrimary),
      meta: type(_scale.meta, ink3),
      amount: type(_scale.amount, c.textPrimary),
      tab: type(_scale.tab, ink3),
      button: type(_scale.button, c.textPrimary),
      buttonSmall: type(_scale.buttonSmall, c.textPrimary),
      navLink: type(_scale.navLink, c.textSecondary),
      link: type(_scale.link, accentText),
      pill: type(_scale.pill, c.textSecondary),
      tag: type(_scale.tag, c.textSecondary),
      toastText: type(_scale.toastText, toastInk),
      toastAction: type(_scale.toastAction, toastAction),
      monogram: type(_scale.monogram, c.textPrimary),
      initials: type(_scale.initials, c.background),
      footnote: type(_scale.footnote, accentText),
      search: type(_scale.search, ink3),
      cardRadius: tokens.shape.cardRadius,
      controlRadius: tokens.shape.controlRadius,
      smallRadius: tokens.shape.smallRadius,
      sheetRadius: tokens.shape.sheetRadius,
    );
  }

  /// [ink] eased toward [toward] in twentieths until it reads at [min] on
  /// every one of [grounds] (or [toward] itself).
  static Color _reach(
    Color ink,
    Color toward,
    List<Color> grounds,
    double min,
  ) {
    for (var i = 0; i <= 20; i++) {
      final c = Color.lerp(ink, toward, i / 20)!;
      if (grounds.every((g) => contrast(c, g) >= min)) return c;
    }
    return toward;
  }

  /// The WCAG contrast ratio of [ink] on [ground], 1..21, as it is seen: a
  /// translucent ink is laid over the ground first. [ground] is opaque.
  static double contrast(Color ink, Color ground) {
    final seen = Color.alphaBlend(ink, ground);
    final la = seen.computeLuminance();
    final lb = ground.computeLuminance();
    return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
  }
}

enum _Face { sans, serif, italic, mono }

/// The catalog type slot a token set sizes a Ledger slot by.
enum _Anchor { giant, display, h1, h2, body, bodySmall, label, mono }

/// One set of inks a Ledger theme is built from: the papers, the inks, the
/// rules, the seal's green and the vermilion, and the toast's.
typedef _Inks = ({
  Color paper,
  Color paperHi,
  Color paperLo,
  Color ink,
  Color ink2,
  Color ink3,
  Color ink4,
  Color rule,
  Color rule2,
  Color green,
  Color greenWash,
  Color greenRule,
  Color red,
  Color redWash,
  Color onGreen,
  Color onRed,
  Color scrim,
  Color toastFill,
  Color toastInk,
  Color toastAction,
  Color toastRing,
  List<BoxShadow> actShadow,
  List<BoxShadow> discShadow,
});

/// One step of the source's type scale.
final class _Slot {
  const _Slot(
    this.face,
    this.size,
    this.line,
    this.weight,
    this.trackingEm,
    this.anchor,
  );

  final _Face face;
  final double size;
  final double line;
  final int weight;
  final double trackingEm;
  final _Anchor anchor;
}

class _LedgerScope extends InheritedTheme {
  const _LedgerScope({
    required this.data,
    required this.dark,
    required super.child,
  });

  final LedgerThemeData data;
  final LedgerThemeData? dark;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _LedgerScope(data: data, dark: dark, child: child);

  @override
  bool updateShouldNotify(_LedgerScope oldWidget) =>
      data != oldWidget.data || dark != oldWidget.dark;
}

/// Puts Ledger in scope for everything under it, as Material's `Theme`
/// does. It is the whole install: put one in any app's `builder:`, under a
/// `MaterialApp`, a `CupertinoApp` or a `WidgetsApp` alike. Under it,
/// Flutter's own text field wears Ledger's caret, selection and handles with
/// no ink, and every text has Ledger's body style to fall back on. Another
/// one restyles a part of the tree. An `InheritedTheme`, so what a route or
/// an overlay captures keeps the Ledger it was raised in.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => LedgerTheme(
///     data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
///         ? LedgerThemeData.dark()
///         : LedgerThemeData.light(),
///     child: child!,
///   ),
///   home: const AccountsPage(),
/// )
/// ```
class LedgerTheme extends StatelessWidget {
  /// Scopes [data] over [child].
  const LedgerTheme({
    super.key,
    required this.data,
    required this.child,
    this.dark,
  });

  /// The theme for what is under it.
  final LedgerThemeData data;

  /// The theme a part drawn over a photograph or a dark band wears whatever
  /// the appearance: the app's dark theme. Null takes [data].
  final LedgerThemeData? dark;

  /// What it styles.
  final Widget child;

  /// The theme in scope at [context]. Throws when there is none.
  /// `context.ledgerTheme` is the same.
  static LedgerThemeData of(BuildContext context) {
    final found = maybeOf(context);
    if (found == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No LedgerTheme in scope.'),
        ErrorHint(
          "Put a LedgerTheme in the app's builder, or above this widget.",
        ),
      ]);
    }
    return found;
  }

  /// The theme in scope at [context], or null.
  static LedgerThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LedgerScope>()?.data;

  /// The dark theme in scope at [context]: [dark], or the theme itself when
  /// none was given.
  static LedgerThemeData darkOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LedgerScope>();
    if (scope == null) return of(context);
    return scope.dark ?? scope.data;
  }

  @override
  Widget build(BuildContext context) {
    Widget under = child;
    // Ledger's text field and sheet ask for the words of the Material
    // library Ledger is built on. An app with none (a CupertinoApp, a
    // WidgetsApp, an app on another Material library, whose words are
    // another type) gets the English ones; an app that has them keeps its
    // own. A Localizations sets the direction from its locale: the app's own
    // direction (a right-to-left switch) is kept.
    if (Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null) {
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    return _LedgerScope(
      data: data,
      dark: dark,
      child: Theme(
        data: _bridges[data] ??= _materialUnder(data),
        child: IconTheme.merge(
          data: IconThemeData(color: data.textPrimary, size: 20),
          // Ledger's own text default: it replaces WidgetsApp's error style
          // for any text outside a part that sets its own.
          child: DefaultTextStyle(style: data.body, child: under),
        ),
      ),
    );
  }

  static final Expando<ThemeData> _bridges = Expando<ThemeData>('ledger');

  /// What Flutter's own widgets under Ledger read (a text field's caret,
  /// selection and handles, a route's ground), in Ledger's colours, with no
  /// ink, splash or highlight, and Material's density pinned to standard so
  /// a desktop never shrinks a part a second time ([LedgerDensity] is the
  /// look's one density). Private: an app never sees a Material type in
  /// Ledger's API, and no Ledger part reads a token from it.
  static ThemeData _materialUnder(LedgerThemeData t) => ThemeData(
    useMaterial3: true,
    brightness: t.brightness,
    fontFamily: t.body.fontFamily,
    scaffoldBackgroundColor: t.background,
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
      selectionColor: t.accent.withValues(alpha: 0.24),
      selectionHandleColor: t.accent,
    ),
    colorScheme: ColorScheme(
      brightness: t.brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      secondary: t.surfaceInverse,
      onSecondary: t.textInverse,
      // Material writes its error words in it: the vermilion as words.
      error: t.over,
      onError: t.onDanger,
      surface: t.background,
      onSurface: t.textPrimary,
      outline: t.borderStrong,
      outlineVariant: t.border,
    ),
    dividerTheme: DividerThemeData(color: t.hairline, thickness: 1),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<LedgerThemeData>('data', data))
      ..add(
        DiagnosticsProperty<LedgerThemeData>('dark', dark, defaultValue: null),
      );
  }
}

/// Animates to a new [data] over [duration] (200 ms, Material's
/// `AnimatedTheme` default), as `AnimatedTheme` does: colours, type and
/// shadows blend through [LedgerThemeData.lerp].
///
/// ```dart
/// AnimatedLedgerTheme(
///   data: night ? LedgerThemeData.dark() : LedgerThemeData.light(),
///   child: page,
/// )
/// ```
class AnimatedLedgerTheme extends ImplicitlyAnimatedWidget {
  /// Animates [child]'s theme to [data].
  const AnimatedLedgerTheme({
    super.key,
    required this.data,
    required this.child,
    this.dark,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final LedgerThemeData data;

  /// [LedgerTheme.dark], passed through as it is.
  final LedgerThemeData? dark;

  /// What it styles.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedLedgerTheme> createState() =>
      _AnimatedLedgerThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LedgerThemeData>('data', data));
  }
}

class _AnimatedLedgerThemeState
    extends AnimatedWidgetBaseState<AnimatedLedgerTheme> {
  LedgerThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => LedgerThemeDataTween(begin: value as LedgerThemeData),
    ) as LedgerThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) => LedgerTheme(
    data: _data!.evaluate(animation),
    dark: widget.dark,
    child: widget.child,
  );
}

/// A tween between two Ledger themes, through [LedgerThemeData.lerp].
class LedgerThemeDataTween extends Tween<LedgerThemeData> {
  /// From [begin] to [end].
  LedgerThemeDataTween({super.begin, super.end});

  @override
  LedgerThemeData lerp(double t) => LedgerThemeData.lerp(begin!, end!, t);
}

/// The accessor every Ledger widget reads its tokens through.
extension LedgerThemeContext on BuildContext {
  /// The app's design tokens: `context.ledgerTheme.accent`, ...
  LedgerThemeData get ledgerTheme => LedgerTheme.of(this);
}

/// Scale-step adjustments that stay on the scale.
extension LedgerTextStyle on TextStyle {
  /// Recolour a scale step: `t.body.colored(t.textSecondary)`.
  TextStyle colored(Color color) => copyWith(color: color);

  /// The medium cut (500).
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// The semibold cut (600).
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  /// The italic of the serif (a name in a greeting, a word of a title).
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  /// Set on a line [px] tall: `t.bodySmall.line(20)`.
  TextStyle line(double px) => copyWith(height: px / fontSize!);

  /// Sized [px], its tracking kept in em: `t.figure.sized(152)`.
  TextStyle sized(double px) => copyWith(
    fontSize: px,
    letterSpacing: (letterSpacing ?? 0) / fontSize! * px,
  );

  /// Tracked [em] of its size: `t.meta.tracked(0.08)`.
  TextStyle tracked(double em) => copyWith(letterSpacing: em * fontSize!);
}

/// The values the `quire` preset is written in: the source stylesheet's
/// custom properties, each under its own name (`--ink-2` is
/// `_Source.ink2`), and the literal colours its rules set.
///
/// ## Role mapping
///
/// The stylesheet names its palette by what each colour is (`--paper`,
/// `--ink-2`, `--green-wash`), so each role takes the property of the rule
/// that plays it (driftwood-authoring §3):
///
/// - The papers: `background` = `--paper` (the canvas), `surface` =
///   `--paper-hi` (raised: a slip, a sheet, a menu, the current nav link),
///   `surfaceAlt` = `--paper-lo` (sunken: the sidebar, an ink pill).
/// - The inks: `textPrimary` = `--ink`, `textSecondary` = `--ink-2`,
///   `textTertiary` = `--ink-3` (4.6:1 on the paper, so it sets the meta
///   lines' words), `textFaint` = `--ink-4` (2.2:1: leaders, rings and
///   chevrons only, never words).
/// - The rules: `border` = `--rule` (14% ink), `hairline` = `--rule-2` (8%);
///   both stay translucent as the source sets them. `headRule` and
///   `borderStrong` = `--ink`: JUDGMENT, the source's strong rule is the
///   ink itself (a section's head, a sheet's head, the double rule, the
///   secondary button's ring), so the catalog's strong border is the ink.
/// - The green: `accent` = `success` = `accentText` = `moneyIn` = `pace` =
///   `seal` = `--green`. JUDGMENT: one green for the accent and for money
///   in, as the source spends it on both and draws no other. `onAccent` =
///   `--paper-hi` (the primary button's words). The wash
///   (`accentSubtle`, `successSubtle`) = `--green-wash`; `accentRule` =
///   `--green-rule`.
/// - Vermilion: `danger` = `over` = `sealOver` = `--red`, which the source
///   spends only on over budget; `dangerSubtle` = `--red-wash`.
/// - `warning` = `--ink-2` on `warningSubtle` = `--paper-lo`: JUDGMENT, the
///   source has no amber; its one caution (a goal behind) is the ink pill.
/// - Cents: an amount's cents take its ink at 72% when green or vermilion
///   (`.amt.in .c`, `.amt.over .c`), `--ink-3` when plain and `--ink-4` on
///   a move; `move` = `--ink-3` (`.amt.move`).
/// - The hatches: JUDGMENT, the source gives its categories glyphs, never
///   hues, and tells parts of a whole apart by three hatches (`stack_bar`):
///   close ink and open green at 85%, pale ink at 35%. They are the
///   category roles.
/// - The chrome's literals: the top bar `--paper` and the tab bar
///   `--paper-hi`, opaque (the source frosts them at 82% and 84% under a
///   blur; Ledger lays no glass), the scrim rgba(20, 26, 31, .44), the toast's act
///   `#BFD8C9` and its glyph's ring rgba(249, 246, 240, .4). The sidebar is
///   `--paper-lo`, the current link `--paper-hi` ringed in `--rule-2`, the
///   Move disc ringed in `--paper-hi`, the bell's dot ringed in `--paper`,
///   the avatar `--ink` with `--paper` initials, a menu's chosen item
///   `--paper`.
/// - Shadows: the rules' box-shadows (`--shadow-sheet`, the phone sheet's,
///   the dialog's, the menu's, the toast's, the primary act's and the Move
///   disc's drop), as Flutter draws CSS's blur ([_css]).
///
/// Type: the slots are the source's sizes, lines, weights and tracking
/// (`_scale`). The source sets no `tnum`: the serif figures keep their own
/// numerals, and the mono amounts are of one width by their face.
///
/// Dark is DESIGNED, in `_Night`: the source has no dark appearance, and
/// its night is the same book kept by lamplight rather than the ink and the
/// paper swapped. The tests hold every appearance to the contrast bars.
abstract final class _Source {
  static const Color paper = Color(0xFFF2EDE3);
  static const Color paperHi = Color(0xFFF9F6F0);
  static const Color paperLo = Color(0xFFEAE4D8);
  static const Color ink = Color(0xFF141A1F);
  static const Color ink2 = Color(0xFF4A5055);
  static const Color ink3 = Color(0xFF686B6D);
  static const Color ink4 = Color(0xFFA9A69F);

  /// rgba(20, 26, 31, .14) and .08.
  static const Color rule = Color.fromRGBO(20, 26, 31, .14);
  static const Color rule2 = Color.fromRGBO(20, 26, 31, .08);
  static const Color green = Color(0xFF1E5A44);
  static const Color greenWash = Color(0xFFDEE7DD);

  /// rgba(30, 90, 68, .35).
  static const Color greenRule = Color.fromRGBO(30, 90, 68, .35);
  static const Color red = Color(0xFFC9402A);
  static const Color redWash = Color(0xFFF6DFD6);

  /// `--r-sheet`.
  static const double rSheet = 6;

  /// `.amt.in .c` and `.amt.over .c`: opacity .72.
  static const double centsVeil = .72;

  /// `stack_bar`'s stroke opacities: .85 for ink and green, .35 pale.
  static const double hatchStrong = .85;
  static const double hatchPale = .35;

  /// `.topbar` and `.tabbar` backgrounds, laid opaque: the source's 82% and
  /// 84% under a blur are frosted glass, and a page scrolled under them
  /// smears through (no glass, no glow).
  static const Color topBarFill = Color.fromRGBO(242, 237, 227, 1);
  static const Color tabBarFill = Color.fromRGBO(249, 246, 240, 1);

  /// `.scrim`.
  static const Color scrim = Color.fromRGBO(20, 26, 31, .44);

  /// `.toast-act` and `.toast-ic`'s border.
  static const Color toastAction = Color(0xFFBFD8C9);
  static const Color toastRing = Color.fromRGBO(249, 246, 240, .4);

  /// `--shadow-sheet`: 0 0 0 1px rgba(20, 26, 31, .07), 0 1px 1px
  /// rgba(20, 26, 31, .04), 0 18px 36px -18px rgba(20, 26, 31, .22).
  static final List<BoxShadow> paperShadow = [
    _css(0, 0, 1, const Color.fromRGBO(20, 26, 31, .07)),
    _css(1, 1, 0, const Color.fromRGBO(20, 26, 31, .04)),
    _css(18, 36, -18, const Color.fromRGBO(20, 26, 31, .22)),
  ];

  /// `.modal-sheet`: 0 -1px 0 rgba(20, 26, 31, .08), 0 -24px 48px -24px
  /// rgba(20, 26, 31, .4).
  static final List<BoxShadow> sheetShadow = [
    _css(-1, 0, 0, const Color.fromRGBO(20, 26, 31, .08)),
    _css(-24, 48, -24, const Color.fromRGBO(20, 26, 31, .4)),
  ];

  /// The desktop `.modal-sheet`: 0 0 0 1px rgba(20, 26, 31, .08), 0 40px
  /// 80px -24px rgba(20, 26, 31, .5).
  static final List<BoxShadow> dialogShadow = [
    _css(0, 0, 1, const Color.fromRGBO(20, 26, 31, .08)),
    _css(40, 80, -24, const Color.fromRGBO(20, 26, 31, .5)),
  ];

  /// `.menu`: 0 0 0 1px rgba(20, 26, 31, .1), 0 2px 4px rgba(20, 26, 31,.
  /// 06), 0 24px 48px -16px rgba(20, 26, 31, .36).
  static final List<BoxShadow> menuShadow = [
    _css(0, 0, 1, const Color.fromRGBO(20, 26, 31, .1)),
    _css(2, 4, 0, const Color.fromRGBO(20, 26, 31, .06)),
    _css(24, 48, -16, const Color.fromRGBO(20, 26, 31, .36)),
  ];

  /// `.toast`: 0 18px 36px -14px rgba(20, 26, 31, .55).
  static final List<BoxShadow> toastShadow = [
    _css(18, 36, -14, const Color.fromRGBO(20, 26, 31, .55)),
  ];

  /// `.btn-primary`: 0 10px 20px -12px rgba(30, 90, 68, .7).
  static final List<BoxShadow> primaryShadow = [
    _css(10, 20, -12, const Color.fromRGBO(30, 90, 68, .7)),
  ];

  /// `.tab-move .move`'s drop: 0 10px 22px -8px rgba(30, 90, 68, .55) (its
  /// 5 px ring is `discRing`, drawn by the disc).
  static final List<BoxShadow> discShadow = [
    _css(10, 22, -8, const Color.fromRGBO(30, 90, 68, .55)),
  ];

  /// A CSS box-shadow `0 [y] [blur] [spread] [color]` as Flutter draws it:
  /// CSS blurs to a standard deviation of half the blur radius, Flutter's
  /// radius maps to `0.57735 r + 0.5`.
  static BoxShadow _css(double y, double blur, double spread, Color color) =>
      BoxShadow(
        offset: Offset(0, y),
        blurRadius: blur <= 0 ? 0 : (blur / 2 - 0.5) / 0.57735,
        spreadRadius: spread,
        color: color,
      );
}

/// The DESIGNED dark appearance of `quire`: the same book of records kept by
/// lamplight. Written from the source's principles rather than inverted:
///
/// - the papers stay paper: a warm umber night (#1A1815), the raised slip a
///   step lighter (#22201C), the sunken paper a step deeper (#13120F), so
///   the warmth of the day's cream survives (the old derived dark stood on
///   the ink's cool blue-black);
/// - the inks are the day's cream turned to ink, warm and on the day's
///   ladder: the ink 14:1 on the paper, the second 8:1, the third 5.8:1 (it
///   sets the meta lines' words), the faint 2.6:1 (leaders, rings and
///   chevrons only, as by day);
/// - the rules keep the day's alphas (14%, 8%) in the night ink;
/// - the green seal is a jade (#6FAA8C) that reads 6:1 as a word and a mark
///   on every paper and carries the night paper's ink on the primary act
///   (7:1), one green for the act, the seal and money in, as by day; the
///   vermilion is lifted to #E57F68 the same way; their washes are their hue
///   16% over the paper;
/// - the toast is a raised slip of the paper (#2E2B26) ringed in the ink at
///   16%, with the ink's words and the jade's act, so the act stays the
///   page's one bright face; the avatar keeps the day's relation (the ink's
///   disc, the paper's initials);
/// - shadows fall in black at twice the day's alpha, and the act's and the
///   Move disc's green drops become black drops at the same geometry.
abstract final class _Night {
  static const Color paper = Color(0xFF1A1815);
  static const Color paperHi = Color(0xFF22201C);
  static const Color paperLo = Color(0xFF13120F);
  static const Color ink = Color(0xFFEEE8DC);
  static const Color ink2 = Color(0xFFB7B0A3);
  static const Color ink3 = Color(0xFF9A9386);
  static const Color ink4 = Color(0xFF5F5A51);

  /// The night ink at the source's rule alphas (14%, 8%).
  static const Color rule = Color.fromRGBO(238, 232, 220, .14);
  static const Color rule2 = Color.fromRGBO(238, 232, 220, .08);
  static const Color green = Color(0xFF6FAA8C);
  static const Color greenWash = Color(0xFF282F28);

  /// The jade at the source's green rule alpha (35%).
  static const Color greenRule = Color.fromRGBO(111, 170, 140, .35);
  static const Color red = Color(0xFFE57F68);
  static const Color redWash = Color(0xFF3A2822);

  /// The words on the jade and the vermilion: the deepest paper.
  static const Color onSeal = Color(0xFF13120F);
  static const Color scrim = Color.fromRGBO(0, 0, 0, .56);

  /// The toast's raised slip and its ring.
  static const Color slip = Color(0xFF2E2B26);
  static const Color slipRing = Color.fromRGBO(238, 232, 220, .16);

  /// The act's and the Move disc's drops, in black at the source's geometry.
  static final List<BoxShadow> actShadow = [
    _Source._css(10, 20, -12, const Color.fromRGBO(0, 0, 0, .6)),
  ];
  static final List<BoxShadow> discShadow = [
    _Source._css(10, 22, -8, const Color.fromRGBO(0, 0, 0, .55)),
  ];
}
