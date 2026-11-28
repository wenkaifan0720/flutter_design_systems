import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'density.dart';
import 'fonts.dart';
import 'internal/narrow.dart';
import 'internal/platform_words.dart';
import 'internal/themes/frost.g.dart';
import 'internal/themes/gallery.g.dart';
import 'internal/themes/paper.g.dart';
import 'internal/themes/signal.g.dart';
import 'page_motion.dart';
import 'style.dart';
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
/// The theme instances come from [LedgerThemeData.preset]: `quire`, Ledger's
/// own paper and ink (its colours written in `_Source` at the end of this
/// file under the stylesheet names they came from, with the role mapping and
/// the choices behind it in its header; its dark appearance, the same book
/// by lamplight, in `_Night`), and four token themes (ThemeTokens v2 records
/// whose light and dark are both designed, held in `internal/themes/`)
/// whose colours dress the same roles on Ledger's own type and corners
/// through `_fromTokens`: `terracotta` (paper), `indigo` (signal),
/// `verdigris` (frost) and `carbon` (gallery). An app's own colours come
/// through [LedgerThemeData.from].
///
/// The comments here and in the parts call Ledger's source stylesheet "the
/// source". A value it holds no instance of is marked and a role it
/// fills only by a choice (one ink standing for two roles).

/// The spacing scale: the steps Ledger pads and gaps by. The page
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

/// Motion: durations and curves. Where the reader asks for
/// reduced motion (Android's Remove animations, the web's
/// prefers-reduced-motion or iOS's Reduce Motion: ui_core's
/// `rawReduceMotionOf`), every change lands at once ([of]).
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

  /// Whether the reader asks for reduced motion above [context], on any
  /// platform. [context] builds again when the answer changes; iOS's change
  /// comes as a build, never as `didChangeDependencies`, so a State reads it
  /// in `build` or as it acts.
  static bool isReduced(BuildContext context) => rawReduceMotionOf(context);
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size));
  }

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

/// Responsive layout invariants shared by Ledger apps.
abstract final class LedgerLayout {
  /// The width from which the app is the desktop one, as Ledger switches
  /// at 1024: the sidebar replaces the tab bar and the top bar, the gutter
  /// grows to 56, the figures grow, a sheet becomes a centred dialog and a
  /// detail's way back a crumb over its title.
  static const double wide = 1024;

  /// A hairline rule's width: the one point Ledger draws every rule at,
  /// and the paper a knockout keeps round its words so no rule touches them.
  static const double hairline = 1;

  /// The window width from which a control (a stepper, a block act) stands
  /// at its own measure instead of across its column: the rail's 600.
  static const double measuredFrom = 600;

  /// The most a stepper or a block act stands across from [measuredFrom]
  /// (unless its words need more): sized to what it holds, never the column
  /// or the page. A form's fields don't keep to it: they take the form's
  /// column ([formMeasure]).
  static const double fieldMeasure = 320;

  /// The widest a form's column stands ([LedgerScreen.form]'s; a sheet's
  /// 640): every field in it, words, a select, a sum, a date, takes the
  /// column's width, one width for all, as the lines of a paper form run
  /// to one margin.
  static const double formMeasure = 640;

  /// [form] at the form's measure: across its slot up to [formMeasure], at
  /// the start of it.
  static Widget formColumn(Widget form) => Align(
    alignment: AlignmentDirectional.topStart,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: formMeasure),
      child: form,
    ),
  );

  /// A bottom sheet's widest (Material's 640): on a tablet it stands as a
  /// card centred over the page, never stretched across it.
  static const double sheetMeasure = 640;

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

/// How an amount or a figure is inked, as Ledger tells money apart:
/// [plain] in the page ink, [moneyIn] green, [over] vermilion (spent past a
/// budget, and only then) and [move] the quiet ink of money moved between
/// the owner's own accounts.
///
/// The tones say what the money did, so a theme keeps each tied to its
/// source: `LedgerThemeData.moneyIn` is the accent's green, `over` the
/// over colour's vermilion and `move` the third ink. `LedgerThemeData.from`
/// and the presets derive them so. Given apart in `copyWith`, they break the
/// meaning: a `moneyIn` that is not the accent no longer matches the act
/// that brought the money, and a red one reads income as overspending.
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
  LedgerThemeData({
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
    RawShapeScheme? shapeScheme,
    this.density = LedgerDensity.standard,
    this.components = const LedgerComponentThemes(),
  }) : shapeScheme = shapeLimits.clamp(
         shapeScheme ?? defaultShapeScheme,
         look: 'Ledger',
       );

  /// The preset this theme is (`quire`, `terracotta`).
  final String id;

  /// Whether this is the day book or the night book.
  final Brightness brightness;

  // ---- the shared roles ---------------------------------------------------

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

  /// The strong rule: a secondary button's ring, and a radio's and a
  /// checkbox's empty ring, at 3:1 on every paper.
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

  /// The caution: an ink pill (a goal behind), never an amber. Where a
  /// palette inks money in as its ink (Carbon), the caution is the second
  /// ink, so the two read apart.
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

  /// Money in ([LedgerTone.moneyIn]): the [accent]'s green as it reads in
  /// words. It means money received, so it stays the accent's ink: change
  /// both together (`LedgerThemeData.from` does). Never red: a red `moneyIn`
  /// reads income as overspending.
  final Color moneyIn;

  /// Money in's cents: [moneyIn] veiled.
  final Color moneyInCents;

  /// Over budget ([LedgerTone.over]): the over colour (`LedgerThemeData
  /// .from`'s `over`, the [danger] vermilion) as it reads in words, for
  /// spending past a limit and nothing else. It is the book's one red, so
  /// an ordinary spend stays in the page ink.
  final Color over;

  /// Over budget's cents: [over] veiled.
  final Color overCents;

  /// A move between the owner's own accounts ([LedgerTone.move]): the third
  /// ink, quiet, since nothing was earned or spent. Keep it an ink, neither
  /// the green nor the red.
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

  /// The three hatches Ledger tells parts apart by (it gives the
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

  /// A drop under the primary act (`LedgerButton.filled` and a filled
  /// `LedgerSplitButton`). Empty in every Ledger theme: a filled act is ink
  /// printed on the page, and ink casts no shadow. Give one only for an app
  /// whose acts stand above the page.
  final List<BoxShadow> primaryShadow;

  /// A drop under the tab bar's Move disc. Empty in every Ledger theme: the
  /// disc is the green printed on the page, as a filled act is, and ink
  /// casts no shadow. Give one only for an app whose disc stands above the
  /// page.
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

  /// The shapes an app can change, held to [shapeLimits]: Ledger's corner
  /// steps. A bar's ends take extra small; a date tab, a tooltip, a popover
  /// and a key cap small; a slip, a menu and a toast medium; a sheet and a
  /// dialog large; extra large is an app's, for the roundest paper it
  /// wants. What the hand holds (a button, a chip, a field, a search) is
  /// full: round at any height, or at most the scale's fullMaxRadius when an
  /// app gives one. Ledger's rules are ink to be read and its paper lies
  /// flat, so it opens no stroke and no depth.
  ///
  /// | Shape | Ledger's | Band | Why |
  /// |---|---|---|---|
  /// | extra small | 3 | 2–5 | a bar's ends, softened, never a pill |
  /// | small | 6 | 2–10 | a paper cut; rounder, a plastic chip |
  /// | medium | 6 | 2–12 | a slip; past 12 it reads as a plastic card |
  /// | large | 6 | 4–16 | a leaf of paper, never a pill |
  /// | extra large | 12 | 8–16 | an app's roundest paper |
  /// | full | round | any cap | what the hand holds |
  ///
  /// An app's own corners for one part (a slip's ticket cut, say) go on the
  /// part's style as `corners`, each corner a step of this scale.
  ///
  /// ```dart
  /// LedgerThemeData.light(shapeScheme: LedgerThemeData.defaultShapeScheme.copyWith(corners: LedgerThemeData.defaultShapeScheme.corners.copyWith(medium: 10)))
  /// ```
  final RawShapeScheme shapeScheme;

  /// Ledger's own shapes: corners of 3, 6, 6, 6 and 12, round, controls
  /// round at any height; no stroke, no depth.
  static const RawShapeScheme defaultShapeScheme = RawShapeScheme(
    corners: RawCornerScale(
      extraSmall: 3,
      small: 6,
      medium: 6,
      large: 6,
      extraLarge: 12,
    ),
  );

  /// The bands Ledger holds a [shapeScheme] to, so that every end still
  /// reads as paper and ink (the table on [shapeScheme]). Corners stay
  /// round; a part's own corners ([RawCorners] on its style) take any step,
  /// each corner its own, as a slip's dog-ear or a ticket's cut is still
  /// paper.
  static const RawShapeLimits shapeLimits = RawShapeLimits(
    extraSmall: RawBand(2, 5),
    small: RawBand(2, 10),
    medium: RawBand(2, 12),
    large: RawBand(4, 16),
    extraLarge: RawBand(8, 16),
    cornerFreedom: RawCornerFreedom.perCorner,
  );

  // ---- density ------------------------------------------------------------

  /// How tightly controls and rows are set ([LedgerDensity]). The
  /// constructor's default is [LedgerDensity.standard]; [LedgerThemeData.light]
  /// and [LedgerThemeData.dark] default to the platform's
  /// ([LedgerDensity.adaptivePlatformDensity]).
  final LedgerDensity density;

  // ---- component themes ---------------------------------------------------

  /// How each part looks across the app, over the book's own drawing: one
  /// [LedgerStyle] per part, each null until set ([LedgerComponentThemes]).
  /// A part's own `style:` goes over its theme here.
  final LedgerComponentThemes components;

  /// The bundled faces: Inter Tight for every word of the interface,
  /// Instrument Serif (regular and italic) for figures, titles and
  /// monograms, and Plex Mono for amounts, dates and numbers.
  static const String face = 'InterTight';

  /// The serif's family: figures, titles and monograms.
  static const String serifFace = 'InstrumentSerif';

  /// The mono's family: amounts, dates and numbers.
  static const String monoFace = 'PlexMono';

  /// Ledger's six palettes, for an app's palette picker; the first, Quire,
  /// is the default. Each is one of [preset]'s books, its swatches the
  /// seal's colour and the paper, by day and by lamplight: Quire's green on
  /// warm paper, Terracotta's brick, Indigo's blue, Verdigris's teal,
  /// Carbon's black on white and Prussian's blue on an account book's buff.
  ///
  /// ```dart
  /// LedgerHost(
  ///   palette: LedgerThemeData.palettes.firstWhere((p) => p.id == paletteId),
  ///   child: app,
  /// )
  /// ```
  static const List<RawNamedPalette> palettes = [
    RawNamedPalette(
      id: 'quire',
      label: 'Quire',
      swatches: [Color(0xFF1E5A44), Color(0xFFF2EDE3)],
      darkSwatches: [Color(0xFF6FAA8C), Color(0xFF1A1815)],
    ),
    RawNamedPalette(
      id: 'terracotta',
      label: 'Terracotta',
      swatches: [Color(0xFFA63F1F), Color(0xFFFBF7F0)],
      darkSwatches: [Color(0xFFE08A57), Color(0xFF17120F)],
    ),
    RawNamedPalette(
      id: 'indigo',
      label: 'Indigo',
      swatches: [Color(0xFF3A3FD8), Color(0xFFF4F6FA)],
      darkSwatches: [Color(0xFF5984FF), Color(0xFF10141C)],
    ),
    RawNamedPalette(
      id: 'verdigris',
      label: 'Verdigris',
      swatches: [Color(0xFF0B7D8C), Color(0xFFF3F7F9)],
      darkSwatches: [Color(0xFF3FB6C6), Color(0xFF0F1A1F)],
    ),
    RawNamedPalette(
      id: 'carbon',
      label: 'Carbon',
      swatches: [Color(0xFF111111), Color(0xFFFFFFFF)],
      darkSwatches: [Color(0xFFF2F2F2), Color(0xFF141414)],
    ),
    RawNamedPalette(
      id: 'prussian',
      label: 'Prussian',
      swatches: [Color(0xFF1F4E86), Color(0xFFECE2C8)],
      darkSwatches: [Color(0xFF6791CD), Color(0xFF0F1E33)],
    ),
  ];

  /// The theme of [palette] in [brightness]: one of [palettes] is that
  /// preset; an app's own is [LedgerThemeData.from] its swatches, the first
  /// the accent and the second, when it has one, the paper (by day from
  /// [RawNamedPalette.swatches], by night from
  /// [RawNamedPalette.darkSwatches]).
  factory LedgerThemeData.fromPalette(
    RawNamedPalette palette,
    Brightness brightness,
  ) {
    if (palettes.any((p) => p.id == palette.id && p == palette)) {
      return preset(palette.id, brightness);
    }
    final day = palette.swatches, night = palette.darkSwatches;
    final quire = preset(palettes.first.id, Brightness.light);
    return LedgerThemeData.from(
      paper: day.length > 1 ? day[1] : quire.background,
      ink: quire.textPrimary,
      accent: day.first,
      brightness: brightness,
      nightAccent: night.isEmpty ? null : night.first,
      nightPaper: night.length > 1 ? night[1] : null,
    );
  }

  /// The preset [id] (a [palettes] id) in [brightness]: `quire` (Ledger's
  /// own paper and ink, by day and by lamplight), `terracotta`, `indigo`,
  /// `verdigris`, `carbon` or `prussian` (Prussian blue on an account
  /// book's buff paper, in a navy ink). A preset changes the colours only:
  /// each keeps Ledger's type, spacing and corners, so a page stands still
  /// as the reader changes palette. By day terracotta, indigo and verdigris
  /// write in their accent's hue, as prussian does. Throws an
  /// [ArgumentError] for any other id. The same preset is the same value.
  static LedgerThemeData preset(String id, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (id) {
      'quire' => dark ? _ledgerDark : _ledgerLight,
      'terracotta' => dark ? _terracottaDark : _terracottaLight,
      'indigo' => dark ? _indigoDark : _indigoLight,
      'verdigris' => dark ? _verdigrisDark : _verdigrisLight,
      'carbon' => dark ? _carbonDark : _carbonLight,
      'prussian' => dark ? _prussianDark : _prussianLight,
      _ => throw ArgumentError.value(id, 'id', 'not a Ledger preset'),
    };
  }

  static final LedgerThemeData _ledgerLight = _quire(Brightness.light);
  static final LedgerThemeData _ledgerDark = _quire(Brightness.dark);
  static final LedgerThemeData _terracottaLight = LedgerThemeData._fromTokens(
    'terracotta',
    _inkedByDay(paperTokens),
    Brightness.light,
  );
  static final LedgerThemeData _terracottaDark = LedgerThemeData._fromTokens(
    'terracotta',
    _inkedByDay(paperTokens),
    Brightness.dark,
  );
  static final LedgerThemeData _indigoLight = LedgerThemeData._fromTokens(
    'indigo',
    _inkedByDay(signalTokens),
    Brightness.light,
  );
  static final LedgerThemeData _indigoDark = LedgerThemeData._fromTokens(
    'indigo',
    _inkedByDay(signalTokens),
    Brightness.dark,
  );
  static final LedgerThemeData _verdigrisLight = LedgerThemeData._fromTokens(
    'verdigris',
    _inkedByDay(frostTokens),
    Brightness.light,
  );
  static final LedgerThemeData _verdigrisDark = LedgerThemeData._fromTokens(
    'verdigris',
    _inkedByDay(frostTokens),
    Brightness.dark,
  );
  static final LedgerThemeData _carbonLight = LedgerThemeData._fromTokens(
    'carbon',
    galleryTokens,
    Brightness.light,
  );
  static final LedgerThemeData _carbonDark = LedgerThemeData._fromTokens(
    'carbon',
    galleryTokens,
    Brightness.dark,
  );

  // How far apart two inks read: their tones and their chromas along their
  // hues, in HCT, as one straight line.
  static double _inksApart(Color a, Color b) {
    final x = RawHct.fromColor(a), y = RawHct.fromColor(b);
    double along(RawHct h, double Function(num) f) =>
        h.chroma * f(h.hue * math.pi / 180);
    final dt = x.tone - y.tone;
    final da = along(x, math.cos) - along(y, math.cos);
    final db = along(x, math.sin) - along(y, math.sin);
    return math.sqrt(dt * dt + da * da + db * db);
  }

  /// A token theme by day in its own inks, as prussian's navy is its seal's:
  /// the record's three inks keep their tones and take its accent's hue and a
  /// share of its colour, at least enough to read as the hue (the third ink
  /// half that), so a preset reads by its words as well as by its paper. By
  /// lamplight the record's own inks.
  static LedgerTokens _inkedByDay(LedgerTokens t) {
    final c = t.light, hue = RawHct.fromColor(c.accent);
    final share = math.max(hue.chroma * .45, 24.0);
    Color ink(Color word, double chroma) =>
        hue.withChroma(chroma).withTone(RawHct.fromColor(word).tone).toColor();
    return LedgerTokens(
      light: LedgerTokenColors(
        background: c.background,
        surface: c.surface,
        surfaceAlt: c.surfaceAlt,
        surfaceInverse: c.surfaceInverse,
        border: c.border,
        borderStrong: c.borderStrong,
        textPrimary: ink(c.textPrimary, share),
        textSecondary: ink(c.textSecondary, share),
        textTertiary: ink(c.textTertiary, share / 2),
        textInverse: c.textInverse,
        accent: c.accent,
        onAccent: c.onAccent,
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
        accentText: c.accentText,
        emphasis: c.emphasis,
        onEmphasis: c.onEmphasis,
        shadowSm: c.shadowSm,
        shadowMd: c.shadowMd,
        shadowLg: c.shadowLg,
      ),
      dark: t.dark,
      giant: t.giant,
      hero: t.hero,
      display: t.display,
      h1: t.h1,
      h2: t.h2,
      h3: t.h3,
      bodyLarge: t.bodyLarge,
      body: t.body,
      bodySmall: t.bodySmall,
      caption: t.caption,
      label: t.label,
      mono: t.mono,
      shape: t.shape,
    );
  }

  static final LedgerThemeData _prussianLight = _prussian(Brightness.light);
  static final LedgerThemeData _prussianDark = _prussian(Brightness.dark);

  /// Prussian blue on an account book's buff paper, in a navy ink, by day;
  /// by lamplight a deep Prussian paper under the buff.
  static LedgerThemeData _prussian(Brightness brightness) => _fromColors(
    'prussian',
    paper: const Color(0xFFECE2C8),
    ink: const Color(0xFF182640),
    accent: const Color(0xFF1F4E86),
    nightPaper: const Color(0xFF0F1E33),
    nightInk: const Color(0xFFECE2C8),
    brightness: brightness,
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
    RawShapeScheme? shapeScheme,
    LedgerDensity? density,
    LedgerComponentThemes? components,
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
    shapeScheme: shapeScheme ?? this.shapeScheme,
    density: density ?? this.density,
    components: components ?? this.components,
  );

  /// The theme [t] of the way from [a] to [b], as `ThemeData.lerp` blends
  /// two Material themes: colours, type and shadows blend, and the [id] and
  /// [brightness] switch half-way. [AnimatedLedgerTheme] animates through it.
  /// Its ends are [a] and [b] themselves: a text style blended all the way
  /// is not always equal to its end (a bundled face's fallbacks).
  static LedgerThemeData lerp(LedgerThemeData a, LedgerThemeData b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
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
      shapeScheme: RawShapeScheme.lerp(a.shapeScheme, b.shapeScheme, t),
      density: t < 0.5 ? a.density : b.density,
      components: LedgerComponentThemes.lerp(a.components, b.components, t),
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
          other.shapeScheme == shapeScheme &&
          other.density == density &&
          other.components == components;

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
    shapeScheme,
    density,
    components,
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
      ..add(DiagnosticsProperty<RawShapeScheme>('shapeScheme', shapeScheme))
      ..add(DiagnosticsProperty<LedgerDensity>('density', density))
      ..add(
        DiagnosticsProperty<LedgerComponentThemes>('components', components),
      );
  }

  // GENERATED-END

  /// Whether this is a dark appearance.
  bool get isDark => brightness == Brightness.dark;

  /// How an ink pressed into the paper (a seal's engraving, its words and
  /// its wash) lays over what is under it: multiplied into a light paper,
  /// as Ledger sets it, and screened onto a dark one, where a multiply
  /// would sink the ink into the night paper.
  BlendMode get pressBlend => isDark ? BlendMode.screen : BlendMode.multiply;

  /// The ink of an amount or a figure in [tone], and of its cents.
  ({Color ink, Color cents}) inks(LedgerTone tone) => switch (tone) {
    LedgerTone.plain => (ink: textPrimary, cents: textTertiary),
    LedgerTone.moneyIn => (ink: moneyIn, cents: moneyInCents),
    LedgerTone.over => (ink: over, cents: overCents),
    LedgerTone.move => (ink: move, cents: moveCents),
  };

  /// Ledger's type scale: each slot's face, size, line, weight and
  /// tracking (in em), and the token slot a token set sizes it by.
  static const _scale = (
    figure: _Slot(_Face.serif, 88, 88 * .84, 400, -.012),
    figureMedium: _Slot(_Face.serif, 44, 44 * .84, 400, -.012),
    figureSmall: _Slot(_Face.serif, 28, 30, 400, -.012),
    title: _Slot(_Face.serif, 30, 33, 400, -.005),
    barTitle: _Slot(_Face.serif, 24, 24, 400, -.005),
    sheetTitle: _Slot(_Face.serif, 28, 30, 400, -.005),
    wordmark: _Slot(_Face.serif, 28, 28, 400, -.01),
    body: _Slot(_Face.sans, 15, 15 * 1.45, 400, 0),
    rowTitle: _Slot(_Face.sans, 15, 20, 500, 0),
    bodySmall: _Slot(_Face.sans, 13, 18, 400, 0),
    label: _Slot(_Face.sans, 11, 16, 600, .14),
    meta: _Slot(_Face.mono, 11, 16, 400, .04),
    amount: _Slot(_Face.mono, 14, 20, 500, -.02),
    tab: _Slot(_Face.sans, 11, 12, 500, 0),
    button: _Slot(_Face.sans, 15, 15, 600, 0),
    buttonSmall: _Slot(_Face.sans, 13, 13, 500, 0),
    navLink: _Slot(_Face.sans, 14.5, 14.5, 500, 0),
    link: _Slot(_Face.mono, 11, 16, 500, .04),
    pill: _Slot(_Face.mono, 12, 12, 500, -.01),
    tag: _Slot(_Face.mono, 11, 12, 500, .06),
    toastText: _Slot(_Face.sans, 15, 20, 500, 0),
    toastAction: _Slot(_Face.mono, 12, 36, 500, .06),
    monogram: _Slot(_Face.italic, 16, 16, 400, .03),
    initials: _Slot(_Face.italic, 15, 15, 400, .04),
    footnote: _Slot(_Face.mono, 11, 12, 500, 0),
    search: _Slot(_Face.sans, 15, 15, 400, 0),
  );

  /// The size Ledger gives each token slot's place in its scale: what
  /// a token set's slot is measured against when it sizes a Ledger slot.

  /// [slot] as a TextStyle in [color] (the line a multiple of its size,
  /// the tracking in em).
  static TextStyle _type(_Slot slot, Color color) {
    final size = slot.size;
    return TextStyle(
      fontFamily: switch (slot.face) {
        _Face.sans => face,
        _Face.serif || _Face.italic => serifFace,
        _Face.mono => monoFace,
      },
      package: ledgerFontPackage,
      // Instrument Serif has no ±, arrows, fractions, ≈ ≤ ≥ or ₹ ₩ ₽: Inter
      // Tight, which has them all, sets them in a figure or a title, not
      // whatever face the platform falls back to (none at all under a test).
      fontFamilyFallback: switch (slot.face) {
        _Face.serif || _Face.italic => const [face],
        _Face.sans || _Face.mono => null,
      },
      fontStyle: slot.face == _Face.italic ? FontStyle.italic : null,
      fontSize: size,
      fontWeight: FontWeight(slot.weight),
      height: slot.line / slot.size,
      letterSpacing: slot.trackingEm * size,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
    );
  }

  /// The book by day: warm paper, the ink and the green seal. [density]
  /// defaults to the
  /// platform's.
  ///
  /// ```dart
  /// LedgerTheme(data: LedgerThemeData.light(), child: page)
  /// ```
  factory LedgerThemeData.light({
    LedgerDensity? density,
    RawShapeScheme? shapeScheme,
  }) => _withDensity(
    _ledgerLight,
    density ?? LedgerDensity.adaptivePlatformDensity,
  )._shaped(shapeScheme);

  /// The same book by lamplight: a warm umber paper, cream ink and a jade
  /// seal, designed rather than inverted. [density] defaults to the
  /// platform's.
  factory LedgerThemeData.dark({
    LedgerDensity? density,
    RawShapeScheme? shapeScheme,
  }) => _withDensity(
    _ledgerDark,
    density ?? LedgerDensity.adaptivePlatformDensity,
  )._shaped(shapeScheme);

  // This theme with an app's [scheme], when it gives one.
  LedgerThemeData _shaped(RawShapeScheme? scheme) =>
      scheme == null ? this : copyWith(shapeScheme: scheme);

  /// A Ledger theme in an app's own colours: its [paper] (the page), its
  /// [ink] (words and rules) and its [accent] (the one act, money in and the
  /// seal), with [over] for amounts past a limit (Ledger's vermilion by
  /// default). The raised and sunken papers, the second, third and faint
  /// inks, the rules and the washes follow from them as Ledger's do from
  /// its own, and every ink that sets words takes the nearest tone of its
  /// hue that reads 4.5:1 on every paper ([RawPalette.readableTone]).
  ///
  /// A light paper with a dark ink is a day book, a dark paper with a light
  /// ink a night book; [brightness] (the book's own side by default) says
  /// which side to build. Asked for the other side, the same book turns: a
  /// day book's night takes a deep tone of the paper's hue for its paper (a
  /// cream page goes to a warm charcoal), the paper's own light tone for its
  /// ink and the accent at the nearest tone that reads on them;
  /// [nightPaper], [nightInk] and [nightAccent] replace any of the three. A
  /// night book's day takes a light tone of its paper's hue and a deep tone
  /// of its ink's.
  ///
  /// ```dart
  /// LedgerThemeData.from(
  ///   paper: const Color(0xFFF4F1EA),
  ///   ink: const Color(0xFF1B2433),
  ///   accent: const Color(0xFF2B4C9B),
  ///   brightness: Brightness.dark,
  /// )
  /// ```
  factory LedgerThemeData.from({
    required Color paper,
    required Color ink,
    required Color accent,
    Color? over,
    Brightness? brightness,
    Color? nightPaper,
    Color? nightInk,
    Color? nightAccent,
    LedgerDensity? density,
    RawShapeScheme? shapeScheme,
  }) =>
      _fromColors(
        'custom',
        paper: paper,
        ink: ink,
        accent: accent,
        over: over,
        brightness: brightness,
        nightPaper: nightPaper,
        nightInk: nightInk,
        nightAccent: nightAccent,
      ).copyWith(
        density: density ?? LedgerDensity.adaptivePlatformDensity,
        shapeScheme: shapeScheme,
      );

  /// [LedgerThemeData.from]'s theme, named [id].
  static LedgerThemeData _fromColors(
    String id, {
    required Color paper,
    required Color ink,
    required Color accent,
    Color? over,
    Brightness? brightness,
    Color? nightPaper,
    Color? nightInk,
    Color? nightAccent,
  }) {
    final night = paper.computeLuminance() < ink.computeLuminance();
    final b = brightness ?? (night ? Brightness.dark : Brightness.light);
    final dark = b == Brightness.dark;
    if (dark && !night) {
      // A day book by lamplight: the night of the same paper.
      final tones = RawNeutralTones.of(paper);
      paper = nightPaper ?? tones.tone(_nightPaperTone);
      ink = nightInk ?? tones.tone(_nightInkTone);
      accent = nightAccent ?? accent;
    } else if (!dark && night) {
      // A night book by day.
      paper = RawNeutralTones.of(paper).tone(_dayPaperTone);
      ink = RawNeutralTones.of(ink).tone(_dayInkTone);
    }
    // An ink that doesn't stand off its paper (a slate ink on a black paper)
    // takes the book's own ink tone in its hue.
    if (RawPalette.contrastRatio(ink, paper) < _inkRatio) {
      ink = RawNeutralTones.of(ink).tone(dark ? _nightInkTone : _dayInkTone);
    }
    final base = dark ? _nightInks : _dayInks;
    // The raised paper: by day half way to white, as the quire's paper-hi
    // stands off its paper; by lamplight a step toward the ink.
    final hi = dark
        ? Color.lerp(paper, ink, .06)!
        : Color.lerp(paper, const Color(0xFFFFFFFF), .5)!;
    final lo = Color.lerp(paper, dark ? const Color(0xFF000000) : ink, .05)!;
    final grounds = [paper, hi, lo];
    Color words(Color c) => RawPalette.readableTone(c, on: grounds);
    // The paper or the ink, whichever reads better on [fill].
    Color on(Color fill) =>
        RawPalette.contrastRatio(paper, fill) >=
            RawPalette.contrastRatio(ink, fill)
        ? hi
        : ink;
    final red = words(over ?? base.red);
    final green = words(accent);
    final inks = (
      paper: paper,
      paperHi: hi,
      paperLo: lo,
      ink: ink,
      // The second ink a quarter of the way to the paper, the third half
      // way, as Ledger's stand: the second stays the darker by day.
      ink2: words(Color.lerp(ink, paper, .25)!),
      ink3: words(Color.lerp(ink, paper, .5)!),
      ink4: Color.lerp(ink, paper, .62)!,
      rule: ink.withValues(alpha: base.rule.a),
      rule2: ink.withValues(alpha: base.rule2.a),
      green: green,
      greenWash: Color.lerp(paper, accent, .16)!,
      greenRule: accent.withValues(alpha: base.greenRule.a),
      red: red,
      redWash: Color.lerp(paper, red, .16)!,
      onGreen: on(green),
      onRed: on(red),
      scrim: base.scrim,
      toastFill: dark ? Color.lerp(paper, ink, .1)! : ink,
      toastInk: dark ? ink : hi,
      toastAction: dark
          ? RawPalette.readableTone(green, on: [Color.lerp(paper, ink, .1)!])
          : RawPalette.readableTone(Color.lerp(accent, hi, .7)!, on: [ink]),
      toastRing: dark
          ? ink.withValues(alpha: base.toastRing.a)
          : hi.withValues(alpha: base.toastRing.a),
    );
    return _build(id, b, inks);
  }

  // The tones a book turned to its other side takes, as Ledger's day
  // and night papers and inks stand (CIE L*, 0 black to 100 white).
  static const double _nightPaperTone = 9;
  // The least the ink stands off its paper: WCAG's enhanced 7:1, so the
  // second and third inks have room to step toward the paper.
  static const double _inkRatio = 7;
  static const double _nightInkTone = 92;
  static const double _dayPaperTone = 94;
  static const double _dayInkTone = 9;

  static LedgerThemeData _withDensity(LedgerThemeData t, LedgerDensity d) =>
      t.density == d ? t : t.copyWith(density: d);

  /// Ledger's day inks, from `_Source`.
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
  );

  static LedgerThemeData _quire(Brightness brightness) => _build(
    'quire',
    brightness,
    brightness == Brightness.dark ? _nightInks : _dayInks,
  );

  /// The whole theme from one set of inks: Ledger's roles, rules and
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
    // The vermilion as words: the nearest tone of it that reads 4.5:1 on
    // every paper it is written on, its wash too (the raw --red is 4.2:1 on
    // the day paper). Its fills, rings and seals keep the raw one.
    final overWords = RawPalette.readableTone(
      red,
      on: [background, surface, surfaceAlt, redWash],
    );
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
      primaryShadow: const [],
      discShadow: const [],
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
    );
  }

  /// A token theme dressed in Ledger's roles: the token set's colours and
  /// shadows on Ledger's type, corners and density, so a palette changes
  /// colour only and switching one moves nothing on the page. Ledger's
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
  factory LedgerThemeData._fromTokens(
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
    TextStyle type(_Slot slot, Color color) => _type(slot, color);
    final ink3 = RawPalette.readableTone(c.textTertiary, on: grounds);
    final moneyIn = RawPalette.readableTone(c.success, on: grounds);
    final over = RawPalette.readableTone(
      c.danger,
      on: [...grounds, c.dangerSubtle],
    );
    final hairline = c.textPrimary.withValues(alpha: _Source.rule2.a);
    final accentText = RawPalette.readableTone(c.accentText, on: grounds);
    // A goal behind wears the record's caution; where the record inks its
    // caution as it inks money in (Carbon's black for both), the caution
    // takes the second ink, so the two read apart.
    final caution = _inksApart(c.warning, c.success) < 24
        ? c.textSecondary
        : c.warning;
    // The accent is one ink: words on the paper and, under `onAccent`, a
    // ground (a brand panel, the act stamped on it). Where the record's
    // `onAccent` cannot read 4.5:1 on the eased words (a deep blue lifted to
    // read on a navy night), the act takes the words' colour and whichever
    // of the page and its ink reads better on it as its own words.
    final heldAct = RawPalette.contrastRatio(c.onAccent, accentText) >= 4.5;
    final accent = heldAct ? c.accent : accentText;
    final onAccent = heldAct
        ? c.onAccent
        : RawPalette.contrastRatio(c.background, accentText) >=
              RawPalette.contrastRatio(c.textPrimary, accentText)
        ? c.background
        : c.textPrimary;
    const white = Color(0xFFFFFFFF);
    final toastFill = dark
        ? Color.lerp(c.surfaceAlt, white, 0.04)!
        : c.surfaceInverse;
    final toastInk = dark ? c.textPrimary : c.textInverse;
    final toastAction = RawPalette.readableTone(accent, on: [toastFill]);
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
      // A radio's and a checkbox's empty ring: a control's edge, at 3:1 on
      // every paper (a record's quiet rule is a hairline).
      borderStrong: RawPalette.readableTone(
        Color.alphaBlend(c.borderStrong, paper),
        on: grounds,
        ratio: 3,
      ),
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
      warning: caution,
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
      primaryShadow: const [],
      discShadow: const [],
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
    );
  }
}

enum _Face { sans, serif, italic, mono }

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
});

/// One step of Ledger's type scale.
final class _Slot {
  const _Slot(this.face, this.size, this.line, this.weight, this.trackingEm);

  final _Face face;
  final double size;
  final double line;
  final int weight;
  final double trackingEm;
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
    this.darkData,
  });

  /// The theme for what is under it.
  final LedgerThemeData data;

  /// The theme a part drawn over a photograph or a dark band wears whatever
  /// the appearance: the app's dark theme. Null takes [data].
  final LedgerThemeData? darkData;

  /// What it styles.
  final Widget child;

  /// The theme in scope at [context]; with none, the quire preset in the
  /// platform's brightness ([LedgerThemeData.light] or
  /// [LedgerThemeData.dark]), as Material's `Theme.of` falls back to its
  /// own. `context.ledgerTheme` is the same.
  static LedgerThemeData of(BuildContext context) =>
      maybeOf(context) ??
      switch (MediaQuery.maybePlatformBrightnessOf(context)) {
        Brightness.dark => _darkDefault,
        _ => _lightDefault,
      };

  static final LedgerThemeData _lightDefault = LedgerThemeData.light();
  static final LedgerThemeData _darkDefault = LedgerThemeData.dark();

  /// The theme in scope at [context], or null.
  static LedgerThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LedgerScope>()?.data;

  /// The dark theme in scope at [context]: [darkData], or the theme itself when
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
    // library Ledger is built on, and a field's menu on iOS for Cupertino's.
    // An app with none of either (a CupertinoApp, a WidgetsApp, or an app
    // whose words are another library's type, as flutter_localizations' are)
    // gets Ledger's own (internal/platform_words.dart), never a throw; an app
    // that has them keeps its own. A Localizations sets the direction from its locale: the
    // app's own direction (a right-to-left switch) is kept.
    final missing = Localizations.maybeLocaleOf(context) == null
        ? const <LocalizationsDelegate<Object?>>[]
        : <LocalizationsDelegate<Object?>>[
            if (Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                ) ==
                null)
              ledgerMaterialWords,
            if (Localizations.of<CupertinoLocalizations>(
                  context,
                  CupertinoLocalizations,
                ) ==
                null)
              ledgerCupertinoWords,
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
    // ui_core's tap floors (40 by 40 for a finger), unless the app declares
    // its own above.
    if (RawTapTargets.maybeOf(context) == null) {
      under = RawTapTargetScope(targets: RawTapTargets.fallback, child: under);
    }
    return _LedgerScope(
      data: data,
      dark: darkData,
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
  /// selection and handles, a route's ground and its page motion), in
  /// Ledger's colours and motion, with no ink, splash or highlight, and
  /// Material's density pinned to standard so a desktop never shrinks a part
  /// a second time ([LedgerDensity] is the look's one density). Private: an
  /// app never sees a Material type in Ledger's API, and no Ledger part reads
  /// a token from it.
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
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: ledgerPageTransitions,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<LedgerThemeData>('data', data))
      ..add(
        DiagnosticsProperty<LedgerThemeData>(
          'darkData',
          darkData,
          defaultValue: null,
        ),
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
    this.darkData,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final LedgerThemeData data;

  /// [LedgerTheme.darkData], passed through as it is.
  final LedgerThemeData? darkData;

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
    darkData: widget.darkData,
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

/// The `quire` preset's values: its papers (the page, the raised paper, the
/// sunken one), its four inks, its two rules, its green and its vermilion,
/// and the literal colours of its chrome. Each role takes the colour that
/// plays it: the raised paper for a slip, a sheet and a menu; the ink for a
/// section's head and the strong border; one green for the accent and for
/// money in; the vermilion only for over budget; the ink pill, never an
/// amber, for its one caution. Its categories are told apart by glyphs and
/// by three hatches, never by hues. The top bar and the tab bar are opaque
/// paper, and the primary act and the Move disc cast no shadow: both are
/// green printed on the page.
///
/// Dark is designed in `_Night`: the same book kept by lamplight rather than
/// the ink and the paper swapped. The tests hold every appearance to the
/// contrast bars.
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

  /// `.amt.in .c` and `.amt.over .c`: opacity .72.
  static const double centsVeil = .72;

  /// `stack_bar`'s stroke opacities: .85 for ink and green, .35 pale.
  static const double hatchStrong = .85;
  static const double hatchPale = .35;

  /// The top bar's and the tab bar's paper, opaque: a page scrolled under
  /// them stays out of sight (no glass, no glow).
  static const Color topBarFill = Color.fromRGBO(242, 237, 227, 1);
  static const Color tabBarFill = Color.fromRGBO(249, 246, 240, 1);

  /// The scrim under a sheet.
  static const Color scrim = Color.fromRGBO(20, 26, 31, .44);

  /// A toast's act and its glyph's ring.
  static const Color toastAction = Color(0xFFBFD8C9);
  static const Color toastRing = Color.fromRGBO(249, 246, 240, .4);

  /// `--shadow-sheet`: 0 0 0 1px rgba(20, 26, 31, .07), 0 1px 1px
  /// rgba(20, 26, 31, .04), 0 18px 36px -18px rgba(20, 26, 31, .22).
  static final List<BoxShadow> paperShadow = [
    _css(0, 0, 1, const Color.fromRGBO(20, 26, 31, .07)),
    _css(1, 1, 0, const Color.fromRGBO(20, 26, 31, .04)),
    _css(18, 36, -18, const Color.fromRGBO(20, 26, 31, .22)),
  ];

  /// A phone sheet's shadow: a hairline over its top and a soft fall above
  /// it.
  static final List<BoxShadow> sheetShadow = [
    _css(-1, 0, 0, const Color.fromRGBO(20, 26, 31, .08)),
    _css(-24, 48, -24, const Color.fromRGBO(20, 26, 31, .4)),
  ];

  /// A desktop dialog's shadow: a hairline round it and a deep soft fall
  /// under it.
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

/// The designed dark appearance of `quire`: the same book of records kept by
/// lamplight. Written from Ledger's principles rather than inverted:
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

  /// The night ink at Ledger's rule alphas (14%, 8%).
  static const Color rule = Color.fromRGBO(238, 232, 220, .14);
  static const Color rule2 = Color.fromRGBO(238, 232, 220, .08);
  static const Color green = Color(0xFF6FAA8C);
  static const Color greenWash = Color(0xFF282F28);

  /// The jade at Ledger's green rule alpha (35%).
  static const Color greenRule = Color.fromRGBO(111, 170, 140, .35);
  static const Color red = Color(0xFFE57F68);
  static const Color redWash = Color(0xFF3A2822);

  /// The words on the jade and the vermilion: the deepest paper.
  static const Color onSeal = Color(0xFF13120F);
  static const Color scrim = Color.fromRGBO(0, 0, 0, .56);

  /// The toast's raised slip and its ring.
  static const Color slip = Color(0xFF2E2B26);
  static const Color slipRing = Color.fromRGBO(238, 232, 220, .16);
}
