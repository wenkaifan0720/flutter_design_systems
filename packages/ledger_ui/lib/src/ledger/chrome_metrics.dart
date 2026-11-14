/// The measures Ledger's chrome and figures are drawn at, each the value the
/// Keel / Ledger pilot's stylesheet sets (its rule named beside it). A
/// measure the source holds no instance of says DERIVED.
///
/// Components read these; pages never do (a page's spacing is
/// [LedgerSpacing]'s, its type the theme's).
library;

import 'theme.dart';

/// The chrome's measures, by the part that draws them.
abstract final class LedgerChromeMetrics {
  // ---- the page ------------------------------------------------------------

  /// `--pad`: the page gutter, 24 on a phone and 56 from 1024.
  static const double gutter = 24;

  /// The page gutter from 1024.
  static const double gutterWide = 56;

  /// `.main`: the room under the last section, 40 under a tab's page, 48
  /// under a pushed page (`.is-detail`), 72 on the desktop; 40 over the
  /// desktop's masthead.
  static const double pageFoot = 40;

  /// The room under a pushed page's last section.
  static const double pageFootPushed = 48;

  /// The room under the last section on the desktop.
  static const double pageFootWide = 72;

  /// The room over the desktop's masthead.
  static const double pageTopWide = 40;

  /// `.cell` and `.cell-first`: a section 48 under the one before (56 on
  /// the desktop), the first 28 under the masthead.
  static const double sectionGap = 48;

  /// A section's distance under the one before on the desktop.
  static const double sectionGapWide = 56;

  /// The first section's distance under the masthead.
  static const double firstSectionGap = 28;

  /// A footer band's room: 16 over its acts, 24 under them. DERIVED (the
  /// source stands its acts in the page).
  static const double footerTop = 16;

  /// A footer band's room under its acts.
  static const double footerFoot = 24;

  // ---- the masthead ----------------------------------------------------------

  /// `.masthead`: 24 over it on a phone; on the desktop 36 under it, its
  /// title and its tools 24 apart at their feet.
  static const double mastTop = 24;

  /// The room under the masthead on the desktop.
  static const double mastFootWide = 36;

  /// The distance between the masthead's title and its tools, at their feet.
  static const double mastToolsGap = 24;

  /// `.greeting, .title-l`: the title 6 under the meta (8 on the desktop,
  /// where it sets at 40).
  static const double titleGap = 6;

  /// The title's distance under the meta on the desktop.
  static const double titleGapWide = 8;

  /// The masthead title's size on the desktop.
  static const double titleWide = 40;

  /// The desktop's crumb stands in the eyebrow's line (DERIVED, one page
  /// frame: the source set it over the meta, 6 above it and 10 over the
  /// title, so a pushed page's title stood 8 under a tab's); a meta with it
  /// follows on that line, 6 past a faint dot.
  static const double crumbToMeta = 6;

  /// `.crumb`: its chevron 15, 4 from its words, hung 4 into the gutter.
  static const double crumbGlyph = 15;

  /// The crumb's chevron's distance from its words.
  static const double crumbGap = 4;

  /// How far the crumb hangs into the gutter.
  static const double crumbHang = 4;

  /// `.masthead .tools` 12 apart; `.masthead .search` 264 by 40, its words
  /// 14; the phone's `.tools` 4 apart.
  static const double deskToolsGap = 12;

  /// The desktop masthead's search width.
  static const double deskSearchWidth = 264;

  /// The desktop masthead's search height.
  static const double deskSearchHeight = 40;

  /// The desktop masthead's search words' size.
  static const double deskSearchText = 14;

  /// The phone's masthead tools' distance apart.
  static const double toolsGap = 4;

  /// `.search`: 46 tall on a page, padded 16, its glyph 18 and 10 from its
  /// words.
  static const double searchHeight = 46;

  /// A page's search field's side padding.
  static const double searchPad = 16;

  /// A page's search field's glyph size.
  static const double searchGlyph = 18;

  /// A page's search field's glyph distance from its words.
  static const double searchGap = 10;

  // ---- the top bar (phone) -----------------------------------------------------

  /// `.topbar`: 60 tall, the page's paper (the source's frost laid opaque), a hairline
  /// under it; its faces on the page's 24 gutter at both sides, a detail's
  /// too (the source pads 16 at its end and on a detail, which set the
  /// avatar and the way back 8 off the page's column).
  static const double topBarHeight = 60;

  /// The top bar's side padding, on the page's gutter.
  static const double topBarSide = 24;

  /// `.topbar-slot`: the empty 36 that balances a detail's back.
  static const double topBarSlot = 36;

  /// `.brand`: the mark 24, 10 from the word; the sidebar's word at 30.
  static const double brandMark = 24;

  /// The brand mark's distance from the word.
  static const double brandGap = 10;

  /// The side bar's wordmark size.
  static const double wordmarkWide = 30;

  /// `.icon-btn`: 40 round, its glyph 20; `.back` and `.ring-btn` 36 with a
  /// rule round them, their glyph 18.
  static const double iconButton = 40;

  /// An icon button's glyph size.
  static const double iconGlyph = 20;

  /// A ringed button's diameter (the back and the outlined icon button).
  static const double ringButton = 36;

  /// A ringed button's glyph size.
  static const double ringGlyph = 18;

  /// `.icon-btn .dot`: 9 across, 8 from the top and 9 from the end, ringed
  /// 2 in the paper.
  static const double dot = 9;

  /// An icon button's dot's distance from its top.
  static const double dotTop = 8;

  /// An icon button's dot's distance from its end.
  static const double dotEnd = 9;

  /// The paper ring round an icon button's dot.
  static const double dotRing = 2;

  /// `.avatar`: 36 round.
  static const double avatar = 36;

  // ---- the tab bar (phone) -------------------------------------------------------

  /// `.tabbar`: 84 tall, padded 8 at its sides and 22 under its tabs (over
  /// the home indicator), the raised paper (the source's frost laid opaque), a rule over it.
  static const double tabBarHeight = 84;

  /// The tab bar's side padding.
  static const double tabBarSide = 8;

  /// The tab bar's room under its tabs, over the home indicator.
  static const double tabBarFoot = 22;

  /// `.tab`: glyph 22, its parts 6 apart; the tick 4 across, drawn 2 up
  /// into the gap above it.
  static const double tabGlyph = 22;

  /// The distance between a tab's glyph and its label.
  static const double tabGap = 6;

  /// The current tab's tick, across.
  static const double tick = 4;

  /// How far the tick is drawn up into the gap above it.
  static const double tickLift = 2;

  /// `.tab-move .move`: the 52 green disc, ringed 5 in the raised paper,
  /// standing 2 into the gap under it.
  static const double disc = 52;

  /// The raised-paper ring round the act's disc.
  static const double discRing = 5;

  /// How far the act's disc stands into the gap under it.
  static const double discSink = 2;

  /// An accessory the shell stands over the tab bar rides 8 over it.
  /// DERIVED (the source has none).
  static const double accessoryGap = 8;

  // ---- the sidebar (desktop) -----------------------------------------------------

  /// `.app`: the sidebar's column 248 wide, a rule down its end.
  static const double sideWidth = 248;

  /// `.sidebar`: padded 30 over, 20 at its sides and foot, its parts 28
  /// apart. Its faces (the act, the chosen row, the rule) stand on its
  /// column; the mark, the nav glyphs and the avatar on one inner keyline,
  /// the nav's 12 inside it (the source pads the brand and the profile 8,
  /// so the mark, the glyphs and the avatar stood on three lines).
  static const double sideTop = 30;

  /// The side bar's padding at its sides and foot.
  static const double sidePad = 20;

  /// The distance between the side bar's parts.
  static const double sideGap = 28;

  /// The inset of the side bar's brand, on the nav's inner keyline.
  static const double sideBrandInset = navPad;

  /// `.btn-move`: 44 tall, its words 14, its glyph 18 and 10 from its
  /// words; when current, a 3 ring of the sidebar's paper and a 1 green ring
  /// past it.
  static const double sideAct = 44;

  /// The side bar act's words' size.
  static const double sideActText = 14;

  /// The gap between the current side bar act and its green ring.
  static const double sideActRingGap = 3;

  /// The green ring round the current side bar act.
  static const double sideActRing = 1;

  /// `.nav`: links 2 apart, each 40 tall, padded 12, its glyph 18 and 12
  /// from its words.
  static const double navGap = 2;

  /// A side bar link's height.
  static const double navLink = 40;

  /// A side bar link's padding.
  static const double navPad = 12;

  /// A side bar link's glyph size.
  static const double navGlyph = 18;

  /// A side bar link's glyph distance from its words.
  static const double navGlyphGap = 12;

  /// `.side-profile`: padded 16 over (on the side bar's inner keyline at
  /// its sides), a rule over it, its parts 12 apart, its chevron 16.
  static const double profileTop = 16;

  /// The side bar profile's side padding, on the nav's inner keyline.
  static const double profileSide = navPad;

  /// The distance between the side bar profile's parts.
  static const double profileGap = 12;

  /// The side bar profile's chevron size.
  static const double profileChevron = 16;

  // ---- sheets --------------------------------------------------------------------

  /// `.modal-sheet` on a phone: at most 90% of the window, padded 24 at its
  /// sides and 32 under.
  static const double sheetMaxShare = 0.9;

  /// A phone sheet's room under its content.
  static const double sheetFoot = 32;

  /// `.modal-sheet` on the desktop: a dialog 480 wide (440 for a dialog of
  /// acts), at most 84% of the window, padded 32 at its sides and under.
  static const double dialogWidth = 480;

  /// The desktop dialog's width for a dialog of acts.
  static const double dialogNarrow = 440;

  /// The largest share of the window the desktop dialog stands.
  static const double dialogMaxShare = 0.84;

  /// The desktop dialog's padding at its sides and under.
  static const double dialogPad = 32;

  /// `.grip`: 36 by 4, 8 under the sheet's top (none on the desktop).
  static const double gripWidth = 36;

  /// The sheet grip's height.
  static const double gripHeight = 4;

  /// The sheet grip's distance under the sheet's top.
  static const double gripTop = 8;

  /// `.sheet-head`: 14 over its title (26 on the desktop), 12 under, an ink
  /// rule under it; its title and close 12 apart; `.sheet-x` hung 6 into
  /// the gutter.
  static const double sheetHeadTop = 14;

  /// The room over the sheet head's title on the desktop.
  static const double sheetHeadTopWide = 26;

  /// The room under the sheet head's title.
  static const double sheetHeadFoot = 12;

  /// The distance between the sheet head's title and its close.
  static const double sheetHeadGap = 12;

  /// How far the sheet's close hangs into the gutter.
  static const double sheetCloseHang = 6;

  /// `.sheet-body` 8 under the head; `.sheet-foot` 20 over the acts.
  static const double sheetBodyTop = 8;

  /// The room over a sheet's acts.
  static const double sheetFootTop = 20;

  // ---- the toast -------------------------------------------------------------------

  /// `.toast`: 16 from the window's sides and 24 over its foot (96 over a
  /// tab's page, clearing the tab bar); on the desktop 32 from the end and
  /// the foot, 380 wide.
  static const double toastSide = 16;

  /// The toast's distance over the window's foot.
  static const double toastFoot = 24;

  /// The toast's distance over a tab's page's foot, clearing the tab bar.
  static const double toastOverBar = 96;

  /// The toast's distance from the window's end and foot on the desktop.
  static const double toastEdgeWide = 32;

  /// The toast's width on the desktop.
  static const double toastWidth = 380;

  /// `.toast`: at least 56 tall, padded 10 (14 at its start), its parts 12
  /// apart; `.toast-ic` 28 round, its glyph 15; `.toast-act` 36 tall, padded
  /// 14.
  static const double toastMinHeight = 56;

  /// The toast's padding.
  static const double toastPad = 10;

  /// The toast's padding at its start.
  static const double toastStart = 14;

  /// The distance between the toast's parts.
  static const double toastGap = 12;

  /// The toast's round mark's diameter.
  static const double toastMark = 28;

  /// The glyph in the toast's mark.
  static const double toastGlyph = 15;

  /// The toast act's height.
  static const double toastAct = 36;

  /// The toast act's padding.
  static const double toastActPad = 14;

  /// How long a toast stays: 3.2 s, 5.6 s with an act to reach for; it
  /// rises 12 as it comes. DERIVED (the source's toast stays until closed).
  static const Duration toastDwell = Duration(milliseconds: 3200);

  /// How long a toast with an act stays.
  static const Duration toastDwellAction = Duration(milliseconds: 5600);

  /// How far a toast rises as it comes.
  static const double toastRise = 12;

  // ---- buttons ---------------------------------------------------------------------

  /// No control's face shorter than this at any density: a button's, an
  /// icon button's, a sign-in's, the desk search's.
  static const double densityFloor = 28;

  /// `.btn`: 48 tall, padded 22, its glyph 18 and 10 from its words.
  static const double button = 48;

  /// A button's side padding.
  static const double buttonPad = 22;

  /// A button's glyph size.
  static const double buttonGlyph = 18;

  /// A button's glyph distance from its words.
  static const double buttonGap = 10;

  /// `.btn-quiet`: 32 tall, padded 13, its glyph 15 and 6 from its words.
  static const double quietButton = 32;

  /// A small button's side padding.
  static const double quietPad = 13;

  /// A small button's glyph size.
  static const double quietGlyph = 15;

  /// A small button's glyph distance from its words.
  static const double quietGap = 6;

  /// `.btn-row`: two acts side by side 12 apart.
  static const double buttonRowGap = 12;

  /// `.btn[disabled]`: opacity .38.
  static const double disabledOpacity = .38;

  // ---- sections --------------------------------------------------------------------

  /// `.head`: 11 under its ink rule, its rubric and note 16 apart; the
  /// first thing after it 8 under.
  static const double headTop = 11;

  /// The distance between a head's rubric and its note.
  static const double headGap = 16;

  /// The first thing after a head stands this far under it.
  static const double headAfter = 8;

  /// `.head-link`: its chevron 14, 2 from its words, its ink ending on the
  /// column's end (the pilot hung its box 3 past it).
  static const double linkGlyph = 14;

  /// A head link's chevron distance from its words.
  static const double linkGap = 2;

  // ---- figures -------------------------------------------------------------------

  /// `.fig .cur, .fig .ct`: the `$` and the cents at .34 of the figure.
  static const double currencyShare = .34;

  /// `.fig .cur`: margin .07em over and .08em after (of its own size).
  static const double currencyDrop = .07;

  /// The space after the figure's currency sign, of its own size.
  static const double currencyGap = .08;

  /// `.fig .ct`: margin .07em over and .1em before, padded .07em under its
  /// 1 px rule.
  static const double centsDrop = .07;

  /// The space before the figure's cents, of their own size.
  static const double centsGap = .1;

  /// The padding under the figure's cents, over their rule, of their own size.
  static const double centsUnder = .07;

  /// The rule under the figure's cents.
  static const double centsRule = 1;

  /// The figure's sizes on the desktop (`.fig` is 88 on a phone, `.fig-m`
  /// 44): a page's head 152 (`.hero .fig`, `.spent-top .fig`), a
  /// transaction's receipt 120 (`.receipt .fig`), a card's balance 72
  /// (`.card-sum .fig`), a section's 56 (`.fig-m`).
  static const double heroFigureWide = 152;

  /// A transaction receipt's figure on the desktop.
  static const double receiptFigureWide = 120;

  /// A card's balance figure on the desktop.
  static const double cardFigureWide = 72;

  /// A section's figure on the desktop.
  static const double sectionFigureWide = 56;

  /// A review's amount (`.amount-ro .fig`): 56 on a phone, 72 on the
  /// desktop.
  static const double entryFigure = 56;

  /// A review's amount on the desktop.
  static const double entryFigureWide = 72;

  /// `.hero .fig`: 26 under what stands over it on a phone, 30 on the
  /// desktop.
  static const double heroFigureTop = 26;

  /// The hero figure's distance under what stands over it on the desktop.
  static const double heroFigureTopWide = 30;

  /// `.double`: two ink rules 4 apart outside to outside; `.total` 14 under
  /// them, its amount 15 bold.
  static const double doubleRule = 4;

  /// A total's distance under its double rule.
  static const double totalTop = 14;

  /// A total's amount size.
  static const double totalAmount = 15;

  /// `.leader`: at least 16 long, 3 tall, 8 from its ends; dots 5 apart,
  /// each centred 1.5 in, solid to .85 and gone by 1.15.
  static const double leaderMin = 16;

  /// The dot leader's height.
  static const double leaderHeight = 3;

  /// The dot leader's distance from the words at its ends.
  static const double leaderInset = 8;

  /// The distance between the dot leader's dots.
  static const double leaderPitch = 5;

  /// Where each leader dot is centred in its pitch.
  static const double leaderCentre = 1.5;

  /// The radius to which a leader dot is solid.
  static const double leaderDot = .85;

  /// The radius by which a leader dot has faded out.
  static const double leaderFade = 1.15;

  // ---- states --------------------------------------------------------------------

  /// `.empty`: the blank ledger page, padded 26 over, 20 at its end, 24
  /// under and 34 at its start (clear of its double margin rule at 18 and
  /// 22); a ruled line every 32.
  static const double emptyTop = 26;

  /// The blank ledger page's padding at its end.
  static const double emptyEnd = 20;

  /// The blank ledger page's padding under its content.
  static const double emptyFoot = 24;

  /// The blank ledger page's padding at its start, clear of its margin rules.
  static const double emptyStart = 34;

  /// The blank ledger page's first margin rule, from its start.
  static const double emptyMarginRule = 18;

  /// The blank ledger page's second margin rule, from its start.
  static const double emptyMarginRule2 = 22;

  /// The distance between the blank ledger page's ruled lines.
  static const double emptyLines = 32;

  /// `.empty-t` 18 under the seal, set 32 on 34; `.empty-s` 10 under it, 15
  /// on 22; the act 22 under that.
  static const double emptyTitleTop = 18;

  /// An empty state's title size.
  static const double emptyTitle = 32;

  /// An empty state's title line height.
  static const double emptyTitleLine = 34;

  /// An empty state's body distance under its title.
  static const double emptyBodyTop = 10;

  /// An empty state's body line height.
  static const double emptyBodyLine = 22;

  /// An empty state's act distance under its body.
  static const double emptyActTop = 22;

  /// `.seal`: 112 round, pressed 7° off square (6° the other way over, 5°
  /// in ink); its words 7.5 on 10 tracked .2em, 19 on 17 italic, 8.5 on 10
  /// mono; the over and ink seals' middle line 24 on 20 and 24 on 21.
  static const double seal = 112;

  /// The seal's turn off square, in degrees.
  static const double sealTurn = -7;

  /// The over seal's turn off square, in degrees.
  static const double sealTurnOver = 6;

  /// The ink seal's turn off square, in degrees.
  static const double sealTurnInk = -5;

  /// A kit's waiting ring: DERIVED (the source draws no wait).
  static const double loadingRing = 28;

  /// A kit's waiting ring's stroke.
  static const double loadingStroke = 1.5;

  /// Focus: the accountant's double rule in the ink under the control, each
  /// of its two lines this thick. DERIVED (the source draws the browser's
  /// own).
  static const double focusRing = 1.5;

  /// The gap between the focus double rule's two lines; the rule stands
  /// twice this under its control.
  static const double focusGap = 2;

  /// How far a pressed face sinks into the paper, like a stamp.
  static const double pressSink = 1;

  /// The loading leader's length: its dots draw in across it, one by one.
  static const double loadingLeader = 96;

  /// The 44 floor a target is grown to when its drawing is smaller.
  static const double minHit = LedgerLayout.minHitTarget;
}
