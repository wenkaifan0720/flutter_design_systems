// Frosted's chrome metrics: the sizes of its bars, slabs, sheets and parts as
// the source stylesheet sets them (a phone 390 wide, the sidebar from 1024),
// and the few the system derives where the source draws no instance. Each
// derived constant says so.

import 'package:flutter/widgets.dart' show Color, EdgeInsets, Size;

/// The bars, bands and parts of Frosted's chrome, in points.
abstract final class FrostedChromeMetrics {
  /// The lit hairline round a pane of light glass: white at 85%.
  static const Color litEdge = Color(0xD9FFFFFF);

  /// The page gutter on a phone (`.main { padding: 0 16px 20px }`) and on
  /// the desktop (`0 32px 40px`).
  static const double gutter = 16;

  /// See [gutter].
  static const double gutterWide = 32;

  /// The page's foot: 20 under its last tile on a phone, 40 on the desktop.
  static const double pageBottom = 20;

  /// See [pageBottom].
  static const double pageBottomWide = 40;

  /// Tiles in a column stand 10 apart on a phone, 16 on the desktop
  /// (`--gap`).
  static const double columnGap = 10;

  /// See [columnGap].
  static const double columnGapWide = 16;

  // --- top bars ---------------------------------------------------------------

  /// A phone top bar (`.top`): 10 over and under its parts, its two sides
  /// 12 apart, the controls at its end 8 apart; it is at least as tall as
  /// its 40 controls.
  static const double barInset = 10;

  /// See [barInset].
  static const double barGap = 12;

  /// See [barInset].
  static const double barEndGap = 8;

  /// See [barInset].
  static const double barControl = 40;

  /// The desktop bar: 32 over its words and 8 under them, in the page.
  static const double barTopWide = 32;

  /// See [barTopWide].
  static const double barBottomWide = 8;

  /// The caption over a title: 2 above it on a phone, 6 on the desktop.
  static const double captionGap = 2;

  /// See [captionGap].
  static const double captionGapWide = 6;

  /// The frost behind a phone bar (`.top::before`): a blur of 20 under the
  /// canvas at half strength, running 16 past the bar's foot and fading out
  /// over its last 40%.
  static const double topFrostBlur = 20;

  /// See [topFrostBlur].
  static const double topFrostReach = 16;

  /// See [topFrostBlur].
  static const double topFrostSolid = 0.6;

  /// A phone detail bar: its back and a balancing space 40 wide either side
  /// of the centred kind of record.
  static const double detailColumn = 40;

  /// The desktop crumb over a detail's title: its chevron 14, pulled 3
  /// into the gutter, 2 from its word; the title 6 under it.
  static const double crumbGlyph = 14;

  /// See [crumbGlyph].
  static const double crumbGap = 2;

  /// See [crumbGlyph].
  static const double crumbPull = 3;

  /// See [crumbGlyph].
  static const double crumbTitleGap = 6;

  /// A round button (`.icon-btn`, `.back`): 40 across with its glyph 18; a
  /// small one 32 with 16.
  static const double roundButton = 40;

  /// See [roundButton].
  static const double roundButtonSmall = 32;

  /// See [roundButton].
  static const double roundGlyph = 18;

  /// See [roundButton].
  static const double roundGlyphSmall = 16;

  /// The bell's unread dot: 7 across, 9 from the top and 10 from the right,
  /// in a ring of 2.
  static const double bellDot = 7;

  /// See [bellDot].
  static const double bellDotTop = 9;

  /// See [bellDot].
  static const double bellDotRight = 10;

  /// See [bellDot].
  static const double bellDotRing = 2;

  /// An avatar: a bar's (40, its letters 14), the sidebar foot's and a
  /// row's (36, 13), a person's pearl (52, 16) and the profile's (80, 28).
  static const double avatar = 40;

  /// See [avatar].
  static const double avatarSmall = 36;

  /// See [avatar].
  static const double avatarLarge = 52;

  /// See [avatar].
  static const double avatarProfile = 80;

  /// See [avatar].
  static const double avatarType = 14;

  /// See [avatar].
  static const double avatarTypeSmall = 13;

  /// See [avatar].
  static const double avatarTypeLarge = 16;

  /// See [avatar].
  static const double avatarTypeProfile = 28;

  // --- the phone tab bar ----------------------------------------------------

  /// The tab bar (`.tabbar`): the slab 12 in from the sides and 12 over the
  /// foot (or the system's inset where that is more: DERIVED, the source
  /// draws no inset), the page fading into the canvas over the 104 above
  /// the foot (nothing at its top, 88% at 48%, the canvas at 80%).
  static const double tabBarSide = 12;

  /// See [tabBarSide].
  static const double tabBarBottom = 12;

  /// See [tabBarSide].
  static const double tabBarFade = 104;

  /// See [tabBarSide].
  static const double tabBarFadeMid = 0.48;

  /// See [tabBarSide].
  static const double tabBarFadeLow = 0.8;

  /// See [tabBarSide].
  static const double tabBarFadeMidAlpha = 0.88;

  /// The slab (`.tabbar-in`): 64 tall, corners 22, 4 inside at its ends,
  /// frosted (a blur of 24, saturated 1.4).
  static const double slabHeight = 64;

  /// How long the selection's pill takes to slide to a new choice (a tab, a
  /// segment).
  static const Duration selectionSlide = Duration(milliseconds: 280);

  /// How far inside its tab's cell the selection's pill stands.
  static const double selectionInset = 4;

  /// See [slabHeight].
  static const double slabInset = 4;

  /// See [slabHeight].
  static const double slabRadius = 22;

  /// See [slabHeight].
  static const double slabBlur = 24;

  /// See [slabHeight].
  static const double slabSaturation = 1.4;

  /// A tab: its glyph (20) 4 over its word.
  static const double tabGlyph = 20;

  /// See [tabGlyph].
  static const double tabGap = 4;

  /// The Move pill in the slab's middle (`.move-btn`): 40 tall, 11 in at
  /// its start and 13 at its end, its glyph 16 and 5 from its word, 6 of
  /// room either side; shown, a white ring of 2 and an ink ring 1.5 past it.
  static const double movePill = 40;

  /// See [movePill].
  static const double movePillInsetStart = 11;

  /// See [movePill].
  static const double movePillInsetEnd = 13;

  /// See [movePill].
  static const double movePillGap = 5;

  /// See [movePill].
  static const double movePillGlyph = 16;

  /// See [movePill].
  static const double movePillRoom = 6;

  /// See [movePill].
  static const double movePillRingInner = 2;

  /// See [movePill].
  static const double movePillRingOuter = 3.5;

  /// DERIVED: an accessory stands 8 over the slab.
  static const double accessoryGap = 8;

  /// DERIVED: a page fades into the canvas over the 32 above its footer's
  /// band (the source's acts stand in the page; it pins none).
  static const double footerFade = 32;

  /// The frost behind a tile of glass: a blur of 24, the colour behind it
  /// saturated 1.3.
  static const double frostBlur = 24;

  /// See [frostBlur].
  static const double frostSaturation = 1.3;

  // --- the desktop sidebar ----------------------------------------------------

  /// The sidebar (`.side`): 240 wide, 28 above its wordmark, 20 at its
  /// start, 16 at its end and 24 at its foot, its parts 24 apart.
  static const double sideWidth = 240;

  /// See [sideWidth].
  static const double sideTop = 28;

  /// See [sideWidth].
  static const double sideStart = 20;

  /// See [sideWidth].
  static const double sideEnd = 16;

  /// See [sideWidth].
  static const double sideBottom = 24;

  /// See [sideWidth].
  static const double sideGap = 24;

  /// The wordmark (`.brand`): 40 tall, its mark (28 across, corners 9, its
  /// glyph 18) 10 before its word, standing on the links' keyline: where a
  /// link's glyph's ink starts, 17 in ([navLinkInset], the pill's 1 edge
  /// and the glyph's own 2 side bearing; the source's 4 gave the sidebar a
  /// second leading edge, design6 P).
  static const double brandHeight = 40;

  /// See [brandHeight].
  static const double brandInset = navLinkInset + 3;

  /// See [brandHeight].
  static const double brandGap = 10;

  /// See [brandHeight].
  static const double brandMark = 28;

  /// See [brandHeight].
  static const double brandMarkRadius = 9;

  /// See [brandHeight].
  static const double brandMarkGlyph = 18;

  /// The sidebar's main act (`.btn-move`): 40 tall across the sidebar, its
  /// glyph 18 and 8 from its word.
  static const double sideAct = 40;

  /// See [sideAct].
  static const double sideActGap = 8;

  /// See [sideAct].
  static const double sideActGlyph = 18;

  /// A nav link (`.nav`): 40 tall, 14 in, its glyph 18 and 12 from its
  /// word; links 2 apart.
  static const double navLink = 40;

  /// See [navLink].
  static const double navLinkInset = 14;

  /// See [navLink].
  static const double navLinkGap = 12;

  /// See [navLink].
  static const double navGlyph = 18;

  /// See [navLink].
  static const double navGap = 2;

  /// The sidebar foot (`.side-me`): 8 inside, its avatar on the links'
  /// keyline at its start (16 in and its edge's 1, where the links' glyph
  /// ink starts; the source's 6 was a third leading edge), 12 from the
  /// name, the name's line 3 over the quiet one.
  static const double footInsetStart = navLinkInset + 2;

  /// See [footInsetStart].
  static const double footInsetEnd = 8;

  /// See [footInsetStart].
  static const double footInsetVertical = 8;

  /// See [footInsetStart].
  static const double footGap = 12;

  /// See [footInsetStart].
  static const double footLineGap = 3;

  // --- buttons ------------------------------------------------------------------

  /// A button (`.btn`): 44 tall, 20 in, its glyph (18) 8 from its word; a
  /// small one 32 tall, 14 in, its word 12 and its glyph 14, 6 apart; a
  /// wide one 48 tall across its line, its word 16.
  static const double buttonHeight = 44;

  /// See [buttonHeight].
  static const double buttonInset = 20;

  /// See [buttonHeight].
  static const double buttonGap = 8;

  /// See [buttonHeight].
  static const double buttonGlyph = 18;

  /// See [buttonHeight].
  static const double buttonSmallHeight = 32;

  /// See [buttonHeight].
  static const double buttonSmallInset = 14;

  /// See [buttonHeight].
  static const double buttonSmallGap = 6;

  /// See [buttonHeight].
  static const double buttonSmallGlyph = 14;

  /// See [buttonHeight].
  static const double buttonSmallWord = 12;

  /// See [buttonHeight].
  static const double buttonWideHeight = 48;

  /// See [buttonHeight].
  static const double buttonWideWord = 16;

  /// The share of the page's ink a glass button on another glass (a sheet,
  /// a dialog, a card) is shaded by in a light theme: the capsule parts from
  /// the glass it stands on, whatever that glass shows.
  static const double glassStepDay = .07;

  /// [glassStepDay] in a dark theme, the ink being light.
  static const double glassStepNight = .12;

  /// What cannot be used is drawn at this share, once (the source's
  /// `.set-row--off`): a control alone, or a row that is off as one thing,
  /// its words and its control together, the control inside it then at full
  /// strength.
  static const double disabledOpacity = 0.45;

  // --- money --------------------------------------------------------------------

  /// A hung `$` and stepped-down cents against the figure: 28 on a 64, 16 on
  /// a 40 and a 28, 40 on the desktop's 96; each rides the cap line, 0.1 em
  /// down on the 64 (0.14 on the 40, 0.06 on the 28, 0.12 on the 96); the
  /// `$` keeps 0.05 em before the dollars, the cents 0.03 em after.
  static const double moneyGiant = 96;

  /// See [moneyGiant].
  static const double moneyDisplay = 64;

  /// See [moneyGiant].
  static const double moneyFigure = 40;

  /// See [moneyGiant].
  static const double moneyFigureSmall = 28;

  /// See [moneyGiant].
  static const double moneyCentsGiant = 40;

  /// See [moneyGiant].
  static const double moneyCentsDisplay = 28;

  /// See [moneyGiant].
  static const double moneyCentsFigure = 16;

  /// See [moneyGiant].
  static const double moneyCentsFigureSmall = 16;

  /// See [moneyGiant].
  static const double moneyDropGiant = 0.12;

  /// See [moneyGiant].
  static const double moneyDropDisplay = 0.1;

  /// See [moneyGiant].
  static const double moneyDropFigure = 0.14;

  /// See [moneyGiant].
  static const double moneyDropFigureSmall = 0.06;

  /// See [moneyGiant].
  static const double moneyCurrencyGap = 0.05;

  /// See [moneyGiant].
  static const double moneyCentsGap = 0.03;

  /// The home figure: 14 under its head and 10 over its change line; the
  /// quiet comparison ("of $2,700") 8 under a figure.
  static const double heroFigureTop = 14;

  /// See [heroFigureTop].
  static const double heroFigureBottom = 10;

  /// See [heroFigureTop].
  static const double figureOfGap = 8;

  // --- the light ------------------------------------------------------------------

  /// The washes of light over the top of every page (`.aurora`): the field
  /// 560 tall on a phone (640 on the desktop), each disc blurred 56 (72).
  static const double lightField = 560;

  /// See [lightField].
  static const double lightFieldWide = 640;

  /// See [lightField].
  static const double lightBlur = 56;

  /// See [lightField].
  static const double lightBlurWide = 72;

  // --- sheets, menus, toasts -----------------------------------------------

  /// A phone sheet (`.sheet`): 8 above its grabber, 16 at its sides, 24
  /// under its last part, its parts 12 apart, at most 88% of the screen.
  static const double sheetTop = 8;

  /// See [sheetTop].
  static const double sheetSide = 16;

  /// See [sheetTop].
  static const double sheetBottom = 24;

  /// See [sheetTop].
  static const double sheetGap = 12;

  /// See [sheetTop].
  static const double sheetMaxFraction = 0.88;

  /// A desktop dialog: 440 wide, corners 20, 64 short of the window's
  /// height at most, 20 above its head, 24 at its sides and foot.
  static const double sheetWideWidth = 440;

  /// See [sheetWideWidth].
  static const double sheetWideRadius = 20;

  /// See [sheetWideWidth].
  static const double sheetWideMargin = 64;

  /// See [sheetWideWidth].
  static const double sheetWideTop = 20;

  /// See [sheetWideWidth].
  static const double sheetWideSide = 24;

  /// See [sheetWideWidth].
  static const double sheetWideBottom = 24;

  /// A side sheet's width ([FrostedSheet.showSide]): the screen less 56
  /// at most, as ui_core leaves the scrim showing.
  static const double sideSheetWidth = 360;

  /// The grabber: 36 by 4, 12 over the head.
  static const double grabberWidth = 36;

  /// See [grabberWidth].
  static const double grabberHeight = 4;

  /// See [grabberWidth].
  static const double grabberGap = 12;

  /// A sheet's head: at least 40 tall, its title 12 from its close; its body
  /// 12 under the head, its foot 12 under the body.
  static const double sheetHead = 40;

  /// See [sheetHead].
  static const double sheetHeadGap = 12;

  /// See [sheetHead].
  static const double sheetBodyGap = 12;

  /// See [sheetHead].
  static const double sheetFootGap = 12;

  /// A sheet's acts under its body: 16, the form body's gap they stand in
  /// (`.sheet-b--form { gap: 16px }`).
  static const double sheetFormFootGap = 16;

  /// DERIVED: the rise and the fall of a sheet.
  static const Duration sheetIn = Duration(milliseconds: 320);

  /// See [sheetIn].
  static const Duration sheetOut = Duration(milliseconds: 220);

  /// An option (`.opt`): at least 52 tall, 6 over and under, 4 in at its
  /// end, its parts 12 apart, a hairline between two; its check a 24 disc
  /// with a 14 glyph.
  static const double option = 52;

  /// See [option].
  static const double optionInset = 6;

  /// See [option].
  static const double optionInsetEnd = 4;

  /// See [option].
  static const double optionGap = 12;

  /// See [option].
  static const double optionCheck = 24;

  /// See [option].
  static const double optionCheckGlyph = 14;

  /// A menu (`.menu`): 288 wide, 6 inside, corners 16, 8 under its anchor,
  /// its items 2 apart; its head 8 above, 10 at its sides, 6 under; an
  /// item 40 tall, 10 in, corners 10, its columns 10 apart, its check 16.
  static const double menuWidth = 288;

  /// See [menuWidth].
  static const double menuInset = 6;

  /// See [menuWidth].
  static const double menuRadius = 16;

  /// See [menuWidth].
  static const double menuGap = 8;

  /// A select's list under its field: close enough that its rounded corner
  /// covers the helper words below the field rather than framing them.
  static const double listGap = 4;

  /// See [menuWidth].
  static const double menuItemsGap = 2;

  /// See [menuWidth].
  static const double menuHeadTop = 8;

  /// See [menuWidth].
  static const double menuHeadSide = 10;

  /// See [menuWidth].
  static const double menuHeadBottom = 6;

  /// See [menuWidth].
  static const double menuItem = 40;

  /// See [menuWidth].
  static const double menuItemInset = 10;

  /// See [menuWidth].
  static const double menuItemRadius = 10;

  /// See [menuWidth].
  static const double menuItemGap = 10;

  /// See [menuWidth].
  static const double menuItemGlyph = 16;

  /// A toast (`.toast`): at least 52 tall, 8 inside (12 at its start),
  /// corners 16, its parts 12 apart; its mark 28 with a 16 glyph; its act
  /// 36 tall, 14 in.
  static const double toastHeight = 52;

  /// See [toastHeight].
  static const double toastInset = 8;

  /// See [toastHeight].
  static const double toastInsetStart = 12;

  /// See [toastHeight].
  static const double toastRadius = 16;

  /// See [toastHeight].
  static const double toastGap = 12;

  /// See [toastHeight].
  static const double toastMark = 28;

  /// See [toastHeight].
  static const double toastMarkGlyph = 16;

  /// See [toastHeight].
  static const double toastAct = 36;

  /// See [toastHeight].
  static const double toastActInset = 14;

  /// Where a toast stands: 16 over the screen's foot and in from its sides;
  /// over the tab bar 12 above the slab (88 from the foot); on the desktop
  /// 32 from the window's right and foot, 380 wide.
  static const double toastBottom = 16;

  /// See [toastBottom].
  static const double toastSide = 16;

  /// See [toastBottom].
  static const double toastOverBar = 12;

  /// See [toastBottom].
  static const double toastWideEdge = 32;

  /// See [toastBottom].
  static const double toastWideWidth = 380;

  /// DERIVED: a toast rises 16 as it comes in, and stays 3.2 seconds (5.6
  /// with an act).
  static const double toastRise = 16;

  /// See [toastRise].
  static const Duration toastDwell = Duration(milliseconds: 3200);

  /// See [toastRise].
  static const Duration toastDwellAction = Duration(milliseconds: 5600);

  // --- marks ---------------------------------------------------------------------

  /// A monogram or a token (`.mono`, `.tok`): 36 across, corners 11, its
  /// glyph 18 and its letters 13; a large one 56 across, corners 17, its
  /// glyph 24 and its letters 20; a ticket's 32 with corners 10 and letters
  /// 12; a browse card's token 32 with a 16 glyph.
  static const double mark = 36;

  /// See [mark].
  static const double markRadius = 11;

  /// See [mark].
  static const double markGlyph = 18;

  /// See [mark].
  static const double markType = 13;

  /// See [mark].
  static const double markLarge = 56;

  /// See [mark].
  static const double markLargeRadius = 17;

  /// See [mark].
  static const double markLargeGlyph = 24;

  /// See [mark].
  static const double markLargeType = 20;

  /// See [mark].
  static const double markSmall = 32;

  /// See [mark].
  static const double markSmallRadius = 10;

  /// See [mark].
  static const double markSmallGlyph = 16;

  /// See [mark].
  static const double markSmallType = 12;

  /// The ink mark (`.mark`): 28 across, corners 9, its glyph 18.
  static const double inkMark = 28;

  /// See [inkMark].
  static const double inkMarkRadius = 9;

  /// See [inkMark].
  static const double inkMarkGlyph = 18;

  /// A date block (`.date`): 40 by 44, corners 11, its day 3 under its
  /// month.
  static const Size dateBlock = Size(40, 44);

  /// See [dateBlock].
  static const double dateBlockRadius = 11;

  /// See [dateBlock].
  static const double dateGap = 3;

  /// A chip (`.chip`): 24 tall, 10 in, its glyph 14 and 4 from its word.
  static const double chipHeight = 24;

  /// See [chipHeight].
  static const double chipInset = 10;

  /// See [chipHeight].
  static const double chipGap = 4;

  /// See [chipHeight].
  static const double chipGlyph = 14;

  /// A glass pill on the card (`.glass`): 24 tall, 10 in, its glyph 14,
  /// blurred 8.
  static const double glassPillHeight = 24;

  /// See [glassPillHeight].
  static const double glassPillInset = 10;

  /// See [glassPillHeight].
  static const double glassPillGlyph = 14;

  /// See [glassPillHeight].
  static const double glassPillBlur = 8;

  /// The segmented control (`.seg-ctl`): 3 inside, its segments 2 apart,
  /// each 26 tall, at least 36 wide and 10 in; filling a field's line, 36
  /// tall with a 14 word.
  static const double segmentsInset = 3;

  /// See [segmentsInset].
  static const double segmentsGap = 2;

  /// See [segmentsInset].
  static const double segmentHeight = 26;

  /// See [segmentsInset].
  static const double segmentMinWidth = 36;

  /// See [segmentsInset].
  static const double segmentInset = 10;

  /// See [segmentsInset].
  static const double segmentFillHeight = 36;

  /// A swatch (`.sw`): 8 across; a visit's dot 10.
  static const double swatch = 8;

  /// See [swatch].
  static const double visitDot = 10;

  /// The unread dot: 8 across, cut clear of what it stands on by 2.
  static const double unreadDot = 8;

  /// See [unreadDot].
  static const double unreadDotRing = 2;

  // --- structure -------------------------------------------------------------------

  /// A tile (`.tile`): 16 inside on a phone, 20 on the desktop; its head
  /// at least 24 tall and 12 over the body, its two sides 12 apart; a
  /// section head (`.sec-h`) 10 over its words and 2 in.
  static const double tileInset = 16;

  /// See [tileInset].
  static const double tileInsetWide = 20;

  /// See [tileInset].
  static const double tileHead = 24;

  /// See [tileInset].
  static const double tileHeadGap = 12;

  /// See [tileInset].
  static const double tileHeadRowGap = 12;

  /// See [tileInset].
  static const double sectionHeadTop = 10;

  /// See [tileInset].
  static const double sectionHeadInset = 2;

  /// A list tile keeps 8 over and under its rows; a list with its own head
  /// keeps the tile's inset over them and 12 under on the desktop.
  static const double listInset = 8;

  /// See [listInset].
  static const double listBottomWide = 12;

  /// A row (`.row`): at least 52 tall, 6 over and under, its parts 12
  /// apart, its lines 1 apart (the end column's 3); a pending mark's glyph
  /// 12 and 3 from its word.
  static const double row = 52;

  /// See [row].
  static const double rowInset = 6;

  /// See [row].
  static const double rowGap = 12;

  /// See [row].
  static const double rowLineGap = 1;

  /// See [row].
  static const double rowEndGap = 3;

  /// See [row].
  static const double rowPendingGlyph = 12;

  /// See [row].
  static const double rowPendingGap = 3;

  /// On the desktop a list's account column is 148 wide, its glyph 16 and
  /// 8 from its word, and a row's amount at least 96 wide.
  static const double rowAccountWide = 148;

  /// See [rowAccountWide].
  static const double rowAccountGlyph = 16;

  /// See [rowAccountWide].
  static const double rowAccountGap = 8;

  /// See [rowAccountWide].
  static const double rowAmountWide = 96;

  /// A day's head in a list: 14 over it (2 when it leads), 4 under.
  static const double dayTop = 14;

  /// See [dayTop].
  static const double dayTopFirst = 2;

  /// See [dayTop].
  static const double dayBottom = 4;

  /// A month divider in a list: 10 over its hairline, 16 under it.
  static const double monthDividerTop = 10;

  /// See [monthDividerTop].
  static const double monthDividerBottom = 16;

  /// A marked row (`.rows--mark .this`): 10 past the rows either side,
  /// corners 12.
  static const double rowMarkBleed = 10;

  /// See [rowMarkBleed].
  static const double rowMarkRadius = 12;

  /// A key and its value (`.kv-r`): a line at least 52 tall, 8 over and
  /// under, its two sides 12 apart, a value's parts 8 apart, its two lines
  /// 2 apart; its chevron 16. As a grid on the desktop: three to a row 16
  /// apart, each 12 over and under, its label 4 over its value, the chevron
  /// on the value's line.
  static const double keyValue = 52;

  /// See [keyValue].
  static const double keyValueInset = 8;

  /// See [keyValue].
  static const double keyValueGap = 12;

  /// See [keyValue].
  static const double keyValuePartsGap = 8;

  /// See [keyValue].
  static const double keyValueLineGap = 2;

  /// See [keyValue].
  static const double keyValueGlyph = 16;

  /// See [keyValue].
  static const double keyValueGridGap = 16;

  /// See [keyValue].
  static const double keyValueGridInset = 12;

  /// See [keyValue].
  static const double keyValueGridLineGap = 4;

  /// See [keyValue].
  static const double keyValueGridChevronTop = 35;

  /// See [keyValue].
  static const int keyValueGridColumns = 3;

  /// The stats under a figure (`.stat`): each 10 over and under on a
  /// phone, its two sides 12 apart; on the desktop in a line, 24 apart
  /// either side of a hairline, each its figure 6 under its word.
  static const double statInset = 10;

  /// See [statInset].
  static const double statGap = 12;

  /// See [statInset].
  static const double statGapWide = 24;

  /// See [statInset].
  static const double statLineGapWide = 6;

  /// See [statInset].
  static const double statsBottomWide = 4;

  /// A record's hero (`.rec-hero`): its parts 16 apart, its mark 12 from
  /// its words, the figure 10 over its comparison; a transaction's hero 28
  /// over its mark and 24 under its last line, its parts 6 apart, the
  /// figure 14 over and 12 under; a review's 24 over and under, 8 apart.
  static const double recordGap = 16;

  /// See [recordGap].
  static const double recordMarkGap = 12;

  /// See [recordGap].
  static const double recordFigureGap = 10;

  /// See [recordGap].
  static const double recordChipsGap = 8;

  /// See [recordGap].
  static const double recordChipsPull = 6;

  /// See [recordGap].
  static const double transactionTop = 28;

  /// See [recordGap].
  static const double transactionBottom = 24;

  /// See [recordGap].
  static const double transactionGap = 6;

  /// See [recordGap].
  static const double transactionFigureTop = 14;

  /// See [recordGap].
  static const double transactionFigureBottom = 12;

  /// See [recordGap].
  static const double transactionMarkGap = 8;

  /// See [recordGap].
  static const double transactionMetaGap = 8;

  /// See [recordGap].
  static const double reviewTop = 24;

  /// See [recordGap].
  static const double reviewBottom = 24;

  /// See [recordGap].
  static const double reviewGap = 8;

  /// See [recordGap].
  static const double reviewFigureTop = 8;

  /// See [recordGap].
  static const double reviewFigureBottom = 4;

  /// The rim of light along a hero's top: 1 tall, nothing at 4%, its stops
  /// at 18, 38, 56 and 76%, nothing at 96%.
  static const double heroRim = 1;

  /// A notification (`.note-r`): 12 over and under, its parts 12 apart,
  /// its glyph 16, its when 4 under its words (5 with their own 1 apart);
  /// the newest (`.note-new`):
  /// its parts 14 apart, its head's dot 8 from its word, its title's lines
  /// 6 apart.
  static const double noteInset = 12;

  /// See [noteInset].
  static const double noteGap = 12;

  /// See [noteInset].
  static const double noteGlyph = 16;

  /// See [noteInset].
  static const double noteWhenGap = 4;

  /// See [noteInset].
  static const double noteNewGap = 14;

  /// See [noteInset].
  static const double noteNewHeadGap = 8;

  /// See [noteInset].
  static const double noteNewLineGap = 6;

  /// The profile's hero (`.me-hero`): 28 over its avatar, the avatar 8
  /// over the name, its lines 6 apart, its facts 10 under.
  static const double profileTop = 28;

  /// See [profileTop].
  static const double profileAvatarGap = 8;

  /// See [profileTop].
  static const double profileGap = 6;

  /// See [profileTop].
  static const double profileFactsGap = 10;

  /// A ticket on the rent band (`.ticket`): corners 10, 8 inside (12 at its
  /// end), its parts 10 apart, its lines 2 apart.
  static const double ticketRadius = 10;

  /// See [ticketRadius].
  static const double ticketInset = 8;

  /// See [ticketRadius].
  static const double ticketInsetEnd = 12;

  /// See [ticketRadius].
  static const double ticketGap = 10;

  /// See [ticketRadius].
  static const double ticketLineGap = 2;

  /// A due line (`.due-line`): 8 tall, its beads 8 across and 4 in, its
  /// words 8 apart.
  static const double dueLine = 8;

  /// See [dueLine].
  static const double dueBead = 8;

  /// See [dueLine].
  static const double dueInset = 4;

  /// See [dueLine].
  static const double dueLabelGap = 8;

  // --- meters and the prism ---------------------------------------------------------

  /// The prism track (`.prism-track`): 40 tall (56 on the desktop's
  /// spending), 16 small, 10 at its least; its bands 1 apart, the pace
  /// tick 1.5 wide reaching 6 over and under (5 on a small track) in a
  /// ring of 1.5; its scale 10 under, at least 16 tall, the pace's word 8
  /// before the tick; a band's words 10 in (16 at the track's ends), 3
  /// apart.
  static const double frostedTrack = 40;

  /// See [frostedTrack].
  static const double frostedTrackWide = 56;

  /// See [frostedTrack].
  static const double frostedTrackSmall = 16;

  /// See [frostedTrack].
  static const double frostedTrackLeast = 10;

  /// See [frostedTrack].
  static const double frostedGap = 1;

  /// See [frostedTrack].
  static const double paceTick = 1.5;

  /// See [frostedTrack].
  static const double paceReach = 6;

  /// See [frostedTrack].
  static const double paceReachSmall = 5;

  /// See [frostedTrack].
  static const double paceRing = 1.5;

  /// See [frostedTrack].
  static const double frostedScaleGap = 10;

  /// See [frostedTrack].
  static const double frostedScaleHeight = 16;

  /// See [frostedTrack].
  static const double paceLabelGap = 8;

  /// See [frostedTrack].
  static const double frostedLabelInset = 10;

  /// See [frostedTrack].
  static const double frostedLabelInsetEnd = 16;

  /// See [frostedTrack].
  static const double frostedLabelGap = 3;

  /// A bar (`.bar`): 6 tall, 4 thin; a tube (`.tube`): 8 tall, 12 large,
  /// its tick 1.5 wide and 20 tall (16 in a comparison); an over bar
  /// (`.overbar`): 6 tall, 10 large, its two parts 2 apart, its scale 14
  /// tall 8 under; a meter on a pane's floor 4 tall (3 on a small pane),
  /// its parts 1 apart.
  static const double bar = 6;

  /// See [bar].
  static const double barThin = 4;

  /// See [bar].
  static const double tube = 8;

  /// See [bar].
  static const double tubeLarge = 12;

  /// See [bar].
  static const double tubeTick = 1.5;

  /// See [bar].
  static const double tubeTickHeight = 20;

  /// See [bar].
  static const double tubeTickHeightCompare = 16;

  /// See [bar].
  static const double overBar = 6;

  /// See [bar].
  static const double overBarLarge = 10;

  /// See [bar].
  static const double overBarGap = 2;

  /// See [bar].
  static const double overBarScale = 14;

  /// See [bar].
  static const double overBarScaleGap = 8;

  /// See [bar].
  static const double meter = 4;

  /// See [bar].
  static const double meterSmall = 3;

  /// See [bar].
  static const double meterGap = 1;

  /// The card's utilisation bar: 180 wide, 4 tall.
  static const double utilWidth = 180;

  /// See [utilWidth].
  static const double utilHeight = 4;

  /// The legend (`.legend`): two columns 16 apart, its entries 12 apart,
  /// each its swatch 8 from its words, its lines 4 apart; three across on
  /// the goals.
  static const double legendColumnGap = 16;

  /// See [legendColumnGap].
  static const double legendRowGap = 12;

  /// See [legendColumnGap].
  static const double legendSwatchGap = 8;

  /// See [legendColumnGap].
  static const double legendLineGap = 4;

  /// A key under a chart (`.key`): its line 16 by 2, 8 from its word, keys
  /// 16 apart (12 in a chart's head).
  static const Size keyLine = Size(16, 2);

  /// See [keyLine].
  static const double keyGap = 8;

  /// See [keyLine].
  static const double keysGap = 16;

  /// See [keyLine].
  static const double keysGapHead = 12;

  /// A merchant line (`.merch`): 6 over and under, its columns 12 apart,
  /// its bar 6 under; on the desktop a card 16 inside with corners 12, its
  /// rows 12 apart, four across.
  static const double merchantInset = 6;

  /// See [merchantInset].
  static const double merchantGap = 12;

  /// See [merchantInset].
  static const double merchantBarGap = 6;

  /// See [merchantInset].
  static const double merchantCardInset = 16;

  /// See [merchantInset].
  static const double merchantCardGap = 12;

  /// A share's line under a figure (`.part`): 8 apart, its parts 10 apart,
  /// 14 under the figure; a share's word 8 before the next.
  static const double partsGap = 8;

  /// See [partsGap].
  static const double partGap = 10;

  /// See [partsGap].
  static const double partsTop = 14;

  /// See [partsGap].
  static const double partShareGap = 8;

  // --- the mosaic ---------------------------------------------------------------

  /// The spend mosaic (`.mosaic`): 540 tall on a phone, its panes 6 apart,
  /// each 10 inside (12 on the desktop) with its parts 6 apart, its floor's
  /// parts 8 apart; a small pane 8 inside (10 by 12 on the desktop) with
  /// its parts 2 apart; a group's basis 24; the tile round it 8 inside,
  /// its head 8 in (12 on the desktop), at least 32 tall (36).
  static const double mosaicHeight = 540;

  /// See [mosaicHeight].
  static const double mosaicHeightWide = 520;

  /// See [mosaicHeight].
  static const double mosaicGap = 6;

  /// See [mosaicHeight].
  static const double paneInset = 10;

  /// See [mosaicHeight].
  static const double paneInsetWide = 12;

  /// See [mosaicHeight].
  static const double paneGap = 6;

  /// See [mosaicHeight].
  static const double paneFloorGap = 8;

  /// See [mosaicHeight].
  static const double paneSmallInset = 8;

  /// See [mosaicHeight].
  static const EdgeInsets paneSmallInsetWide = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 12,
  );

  /// See [mosaicHeight].
  static const double paneSmallGap = 2;

  /// See [mosaicHeight].
  static const double mosaicBasis = 24;

  /// See [mosaicHeight].
  static const double mosaicTileInset = 8;

  /// See [mosaicHeight].
  static const double mosaicHeadInset = 8;

  /// See [mosaicHeight].
  static const double mosaicHeadInsetWide = 12;

  /// See [mosaicHeight].
  static const double mosaicHead = 32;

  /// See [mosaicHeight].
  static const double mosaicHeadWide = 36;

  /// The rent band's middle: its parts 12 apart; on the desktop its ticket
  /// 340 wide.
  static const double rentGap = 12;

  /// See [rentGap].
  static const double rentTicketWide = 340;

  // --- the card ----------------------------------------------------------------

  /// The pearl credit card: 1.586 as wide as tall, corners 16 (18 on the
  /// desktop, turned 4 degrees), 18 inside (20), its rim 1, frosted 16; its
  /// glow 24 under its top, 28 in and 8 over its foot (44, 60 and 16 on the
  /// desktop), blurred 36 (44); its brand 20 with its mark 8 before it;
  /// its middle's lines 8 apart; its number tracked 0.04 em; its orbits 380
  /// across, 120 past its right edge and 140 over its top. On the desktop
  /// the card stands 16 over, 28 in and 4 under in its stage (12, 8 and 8
  /// on the Cards page, 300 wide).
  static const double cardAspect = 1.586;

  /// See [cardAspect].
  static const double cardRadius = 16;

  /// See [cardAspect].
  static const double cardRadiusWide = 18;

  /// See [cardAspect].
  static const double cardTurnWide = -4;

  /// See [cardAspect].
  static const double cardInset = 18;

  /// See [cardAspect].
  static const double cardInsetWide = 20;

  /// See [cardAspect].
  static const double cardFrostBlur = 16;

  /// See [cardAspect].
  static const EdgeInsets cardGlow = EdgeInsets.fromLTRB(28, 24, 28, 8);

  /// See [cardAspect].
  static const EdgeInsets cardGlowWide = EdgeInsets.fromLTRB(60, 44, 60, 16);

  /// See [cardAspect].
  static const double cardGlowBlur = 36;

  /// See [cardAspect].
  static const double cardGlowBlurWide = 44;

  /// See [cardAspect].
  static const double cardBrandType = 20;

  /// See [cardAspect].
  static const double cardBrandGap = 8;

  /// See [cardAspect].
  static const double cardMidGap = 8;

  /// See [cardAspect].
  static const double cardNumberTracking = 0.04;

  /// See [cardAspect].
  static const double cardOrbits = 380;

  /// See [cardAspect].
  static const double cardOrbitsRight = -120;

  /// See [cardAspect].
  static const double cardOrbitsTop = -140;

  /// See [cardAspect].
  static const EdgeInsets cardStageWide = EdgeInsets.fromLTRB(28, 16, 28, 4);

  /// See [cardAspect].
  static const EdgeInsets cardStageCards = EdgeInsets.fromLTRB(8, 12, 8, 8);

  /// See [cardAspect].
  static const double cardStageWidth = 300;

  /// A debit card's small face (`.dcard`): 92 by 58, corners 9, 8 inside,
  /// its mark 18 with corners 6 and a 12 glyph; 14 from its words.
  static const Size debitCard = Size(92, 58);

  /// See [debitCard].
  static const double debitCardRadius = 9;

  /// See [debitCard].
  static const double debitCardInset = 8;

  /// See [debitCard].
  static const double debitCardMark = 18;

  /// See [debitCard].
  static const double debitCardMarkRadius = 6;

  /// See [debitCard].
  static const double debitCardMarkGlyph = 12;

  /// See [debitCard].
  static const double debitCardGap = 14;

  /// The card's figures (`.cfigs`): three across in shares of 0.8, 1.2
  /// and 1, 12 either side of a hairline, each its lines 4 apart; on the
  /// desktop lines 10 over and under, 12 apart.
  static const double cardFigureGap = 12;

  /// See [cardFigureGap].
  static const double cardFigureLineGap = 4;

  /// See [cardFigureGap].
  static const double cardFigureInsetWide = 10;

  /// The card's limit (`.lim`): 4 over and 2 under its bar, its scale 8
  /// under.
  static const double limitTop = 4;

  /// See [limitTop].
  static const double limitBottom = 2;

  /// See [limitTop].
  static const double limitScaleGap = 8;

  /// The frost over a frozen card: blurred 5, its glyph on a 48 round (the
  /// glyph 24), 8 over its word; the banner's mark 36 with an 18 glyph, 12
  /// from its words, 14 over and under and 16 in; the dialog's mark 56
  /// with a 24 glyph.
  static const double frostBlur5 = 5;

  /// See [frostBlur5].
  static const double frostMark = 48;

  /// See [frostBlur5].
  static const double frostMarkGlyph = 24;

  /// See [frostBlur5].
  static const double frostGap = 8;

  /// See [frostBlur5].
  static const double bannerMark = 36;

  /// See [frostBlur5].
  static const double bannerMarkGlyph = 18;

  /// See [frostBlur5].
  static const double bannerGap = 12;

  /// See [frostBlur5].
  static const EdgeInsets bannerInset = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 16,
  );

  /// See [frostBlur5].
  static const double freezeMark = 56;

  /// See [frostBlur5].
  static const double freezeMarkGlyph = 24;

  /// The statement line (`.stl`): 12 tall, 2 over (collapsing into a
  /// head's 12 above it) and 6 in, its rule 1 at 5.5, its beads 12 across;
  /// its words 42 tall, 10 over and under, their lines 4 apart.
  static const double statementLine = 12;

  /// See [statementLine].
  static const double statementLineTop = 2;

  /// See [statementLine].
  static const double statementLineInset = 6;

  /// See [statementLine].
  static const double statementRuleTop = 5.5;

  /// See [statementLine].
  static const double statementBead = 12;

  /// See [statementLine].
  static const double statementLabels = 42;

  /// See [statementLine].
  static const double statementLabelsGap = 10;

  /// See [statementLine].
  static const double statementLabelLineGap = 4;

  /// The card number's well (`.cnum`): corners 14, 14 by 16 inside, its
  /// lines 8 apart; its three facts in shares of 1, 1 and 1.6, 12 apart, 4
  /// in, each its lines 6 apart.
  static const double numberRadius = 14;

  /// See [numberRadius].
  static const EdgeInsets numberInset = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 16,
  );

  /// See [numberRadius].
  static const double numberGap = 8;

  /// See [numberRadius].
  static const double numberFactsGap = 12;

  /// See [numberRadius].
  static const double numberFactsInset = 4;

  /// See [numberRadius].
  static const double numberFactLineGap = 6;

  // --- home pieces ----------------------------------------------------------------

  /// The quick actions (`.qa`): four across, 4 apart, 14 over and under
  /// and 8 in; each its round 44 (its glyph 18) 8 over its word.
  static const double actionGap = 4;

  /// See [actionGap].
  static const EdgeInsets actionsInset = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 8,
  );

  /// See [actionGap].
  static const double actionRound = 44;

  /// See [actionGap].
  static const double actionGlyph = 18;

  /// See [actionGap].
  static const double actionWordGap = 8;

  /// A way to move money (`.mv-act`): corners 14, 10 inside (16 on the
  /// desktop), its round 32 (40) with a 16 (18) glyph, 10 (14) from its
  /// words, its lines 2 (4) apart; two across 8 apart (16).
  static const double moveActRadius = 14;

  /// See [moveActRadius].
  static const double moveActInset = 10;

  /// See [moveActRadius].
  static const double moveActInsetWide = 16;

  /// See [moveActRadius].
  static const double moveActRound = 32;

  /// See [moveActRadius].
  static const double moveActRoundWide = 40;

  /// See [moveActRadius].
  static const double moveActGlyph = 16;

  /// See [moveActRadius].
  static const double moveActGlyphWide = 18;

  /// See [moveActRadius].
  static const double moveActGap = 10;

  /// See [moveActRadius].
  static const double moveActGapWide = 14;

  /// See [moveActRadius].
  static const double moveActLineGap = 2;

  /// See [moveActRadius].
  static const double moveActLineGapWide = 4;

  /// See [moveActRadius].
  static const double moveActsGap = 8;

  /// An account card (`.acct`): 14 inside (18 by 20 on the desktop), its
  /// parts 10 apart, its note 6 under; two across on a phone, four on the
  /// desktop.
  static const double accountInset = 14;

  /// See [accountInset].
  static const EdgeInsets accountInsetWide = EdgeInsets.symmetric(
    vertical: 18,
    horizontal: 20,
  );

  /// See [accountInset].
  static const double accountGap = 10;

  /// See [accountInset].
  static const double accountNoteGap = 6;

  /// A goal (`.goal`): 10 over and under, its parts 10 apart, its head's
  /// parts 12 apart; a goal card (`.goal-card`): its columns 12 apart and
  /// its rows 10 (14 on the desktop), its figure's parts 8 apart, its bar
  /// 12 from its share (at least 40 wide); a ghost card 16 inside with
  /// corners 14; the new-goal tile's plus 36 with corners 11 and an 18
  /// glyph, its glyph 16, its parts 12 apart (16 on the desktop).
  static const double goalInset = 10;

  /// See [goalInset].
  static const double goalGap = 10;

  /// See [goalInset].
  static const double goalHeadGap = 12;

  /// See [goalInset].
  static const double goalCardColumnGap = 12;

  /// See [goalInset].
  static const double goalCardRowGap = 10;

  /// See [goalInset].
  static const double goalCardRowGapWide = 14;

  /// See [goalInset].
  static const double goalCardFigureGap = 8;

  /// See [goalInset].
  static const double goalCardBarGap = 12;

  /// See [goalInset].
  static const double goalCardShare = 40;

  /// See [goalInset].
  static const double ghostInset = 16;

  /// See [goalInset].
  static const double ghostRadius = 14;

  /// See [goalInset].
  static const double newGoalPlus = 36;

  /// See [goalInset].
  static const double newGoalPlusRadius = 11;

  /// See [goalInset].
  static const double newGoalPlusGlyph = 18;

  /// See [goalInset].
  static const double newGoalGlyph = 16;

  /// See [goalInset].
  static const double newGoalGap = 12;

  /// See [goalInset].
  static const double newGoalGapWide = 16;

  /// A nudge (`.nudge`): corners 14, 10 inside (12 at its start), its mark
  /// 28 with a 16 glyph, 12 from its words.
  static const double nudgeRadius = 14;

  /// See [nudgeRadius].
  static const EdgeInsets nudgeInset = EdgeInsets.fromLTRB(12, 10, 10, 10);

  /// See [nudgeRadius].
  static const double nudgeMark = 28;

  /// See [nudgeRadius].
  static const double nudgeMarkGlyph = 16;

  /// See [nudgeRadius].
  static const double nudgeGap = 12;

  /// Quick amounts (`.qamt`): three across 8 apart, each corners 12, 10 by
  /// 6 inside, its lines 4 apart.
  static const double quickAmountsGap = 8;

  /// See [quickAmountsGap].
  static const double quickAmountRadius = 12;

  /// See [quickAmountsGap].
  static const EdgeInsets quickAmountInset = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 6,
  );

  /// See [quickAmountsGap].
  static const double quickAmountGap = 4;

  /// A suggestion (`.suggest`): corners 14, 12 inside, its mark 36 (corners
  /// 11, an 18 glyph) 12 from its words.
  static const double suggestRadius = 14;

  /// See [suggestRadius].
  static const double suggestInset = 12;

  /// See [suggestRadius].
  static const double suggestMark = 36;

  /// See [suggestRadius].
  static const double suggestMarkRadius = 11;

  /// See [suggestRadius].
  static const double suggestMarkGlyph = 18;

  /// See [suggestRadius].
  static const double suggestGap = 12;

  /// A browse card (`.browse-c`): corners 12, 10 inside, its token 10 from
  /// its words; two across 8 apart.
  static const double browseRadius = 12;

  /// See [browseRadius].
  static const double browseInset = 10;

  /// See [browseRadius].
  static const double browseGap = 10;

  /// See [browseRadius].
  static const double browseCardsGap = 8;

  /// The month switch (`.switch`): 3 inside, its parts 4 apart, its arrows
  /// 32 round with a 16 glyph, its month 32 tall with a 14 chevron 4 from
  /// its word, 8 in on the desktop; the earlier month's word 4 in.
  static const double monthSwitchInset = 3;

  /// See [monthSwitchInset].
  static const double monthSwitchGap = 4;

  /// See [monthSwitchInset].
  static const double monthArrow = 32;

  /// See [monthSwitchInset].
  static const double monthArrowGlyph = 16;

  /// See [monthSwitchInset].
  static const double monthHeight = 32;

  /// See [monthSwitchInset].
  static const double monthGlyph = 14;

  /// See [monthSwitchInset].
  static const double monthGap = 4;

  /// See [monthSwitchInset].
  static const double monthInsetWide = 8;

  /// See [monthSwitchInset].
  static const double monthPrevInset = 4;

  /// The spending head (`.month-h`): its lines 8 apart, 16 over the track;
  /// its foot 14 over and 16 under, its parts 8 apart; the desktop's
  /// spending grid: its columns 48 apart and its rows 24.
  static const double monthHeadGap = 8;

  /// See [monthHeadGap].
  static const double monthHeadBottom = 16;

  /// See [monthHeadGap].
  static const double monthFootTop = 14;

  /// See [monthHeadGap].
  static const double monthFootBottom = 16;

  /// See [monthHeadGap].
  static const double monthFootGap = 8;

  /// See [monthHeadGap].
  static const double spentColumnGap = 48;

  /// See [monthHeadGap].
  static const double spentRowGap = 24;

  /// An insight (`.insight`): its parts 12 apart, its kind's glyph 16 and
  /// 6 from its word; the visits 6 apart.
  static const double insightGap = 12;

  /// See [insightGap].
  static const double insightKindGlyph = 16;

  /// See [insightGap].
  static const double insightKindGap = 6;

  /// See [insightGap].
  static const double visitsGap = 6;

  /// Money in against out (`.flow`): its parts 14 apart, its two figures 16
  /// apart, each its lines 8 apart, its scale 8 under, its note's two
  /// sides 12 apart; an account's split 14 apart, each line's parts 8
  /// apart, its head's 10.
  static const double flowGap = 14;

  /// See [flowGap].
  static const double flowFiguresGap = 16;

  /// See [flowGap].
  static const double flowFigureGap = 8;

  /// See [flowGap].
  static const double flowScaleGap = 8;

  /// See [flowGap].
  static const double flowNoteGap = 12;

  /// See [flowGap].
  static const double splitGap = 14;

  /// See [flowGap].
  static const double splitLineGap = 8;

  /// See [flowGap].
  static const double splitHeadGap = 10;

  // --- charts ---------------------------------------------------------------------

  /// A chart (`.chart`): 16 under what is above it; its month labels 8
  /// under it, their row 40 short at the end (48 on the desktop, 36 and 40
  /// with a gap); a y label's words 12 and the end labels' row 16 tall;
  /// a mark's note 6 in and 5 over or under a mark (10 at a line's end,
  /// 8 beside a step); a bar's value 6 over it.
  static const double chartTop = 16;

  /// See [chartTop].
  static const double chartLabelsGap = 8;

  /// See [chartTop].
  static const double chartLabelsEnd = 40;

  /// See [chartTop].
  static const double chartLabelsEndWide = 48;

  /// See [chartTop].
  static const double chartLabelsEndGap = 36;

  /// See [chartTop].
  static const double chartLabelsEndGapWide = 40;

  /// See [chartTop].
  static const double chartLabels = 16;

  /// See [chartTop].
  static const double chartNoteInset = 6;

  /// See [chartTop].
  static const double chartNoteGap = 5;

  /// See [chartTop].
  static const double chartNoteEndGap = 10;

  /// See [chartTop].
  static const double chartNoteStepInset = 8;

  /// See [chartTop].
  static const double chartBarValueGap = 6;

  /// A transaction's strip of days (`.strip`): 40 tall, its rule 1 at 4
  /// from its foot, its ticks 5 tall, its dots 8 (this one 10, ringed 2.5)
  /// standing 9 up and 3 apart; its labels 14 tall 6 under.
  static const double strip = 40;

  /// See [strip].
  static const double stripRuleBottom = 4;

  /// See [strip].
  static const double stripTick = 5;

  /// See [strip].
  static const double stripDot = 8;

  /// See [strip].
  static const double stripDotThis = 10;

  /// See [strip].
  static const double stripDotRing = 2.5;

  /// See [strip].
  static const double stripDotBottom = 9;

  /// See [strip].
  static const double stripDotGap = 3;

  /// See [strip].
  static const double stripLabels = 14;

  /// See [strip].
  static const double stripLabelsGap = 6;

  /// The figures in a line (`.figs`): 24 apart, each its lines 6 apart.
  static const double figuresGap = 24;

  /// See [figuresGap].
  static const double figureLineGap = 6;

  /// The route of a move (`.route`): its parts 12 apart, 8 over the words,
  /// each line's parts 6 apart, its beams 36 by 2 with corners 2, its glyph
  /// 16; the done art 200 across, 12 up and 4 down, its check 72 (a 32
  /// glyph) in a ring of 6.
  static const double routeGap = 12;

  /// See [routeGap].
  static const double routeBottom = 8;

  /// See [routeGap].
  static const double routeLineGap = 6;

  /// See [routeGap].
  static const Size routeBeam = Size(36, 2);

  /// See [routeGap].
  static const double routeGlyph = 16;

  /// See [routeGap].
  static const double doneArt = 200;

  /// See [routeGap].
  static const double doneArtPullTop = 12;

  /// See [routeGap].
  static const double doneArtPullBottom = 4;

  /// See [routeGap].
  static const double doneCheck = 72;

  /// See [routeGap].
  static const double doneCheckGlyph = 32;

  /// See [routeGap].
  static const double doneCheckRing = 6;

  /// A change (`.chg`): its parts 10 apart, 4 over and 14 under (14 over
  /// the next), its head's parts 12 apart, its values 3 apart.
  static const double changeGap = 10;

  /// See [changeGap].
  static const double changeTop = 4;

  /// See [changeGap].
  static const double changeBottom = 14;

  /// See [changeGap].
  static const double changeHeadGap = 12;

  /// See [changeGap].
  static const double changeValueGap = 3;

  // --- controls ----------------------------------------------------------------------

  /// The search field (`.search`): 44 tall, 16 in, its glyph 18 and 10
  /// from its words; typed, its clear a 28 round (a 14 glyph) pulled 6 into
  /// the end.
  static const double search = 44;

  /// See [search].
  static const double searchInset = 16;

  /// See [search].
  static const double searchGap = 10;

  /// See [search].
  static const double searchGlyph = 18;

  /// See [search].
  static const double searchClear = 28;

  /// See [search].
  static const double searchClearGlyph = 14;

  /// See [search].
  static const double searchClearPull = 6;

  /// Filter chips (`.fchip`): 32 tall, 10 in, 4 apart.
  static const double filterChip = 32;

  /// See [filterChip].
  static const double filterChipInset = 10;

  /// See [filterChip].
  static const double filterChipGap = 4;

  /// A field (`.field`): its label 8 over the well; the well (`.inp`) 48
  /// tall, 14 in, corners 12; two fields in a line 12 apart; a form's
  /// fields 16 apart (its tile's head 16 over them).
  static const double fieldLabelGap = 8;

  /// See [fieldLabelGap].
  static const double field = 48;

  /// See [fieldLabelGap].
  static const double fieldInset = 14;

  /// See [fieldLabelGap].
  static const double fieldRadius = 12;

  /// See [fieldLabelGap].
  static const double fieldsGap = 12;

  /// See [fieldLabelGap].
  static const double formGap = 16;

  /// An amount well (`.amount-in`): 64 tall, 12 over and 16 in, corners 14,
  /// its `$` 16 and 6 down, 2 from the figure (40 tall); the small one 48
  /// tall, 14 in, corners 12.
  static const double amountWell = 64;

  /// See [amountWell].
  static const double amountWellTop = 12;

  /// See [amountWell].
  static const double amountWellInset = 16;

  /// See [amountWell].
  static const double amountWellRadius = 14;

  /// See [amountWell].
  static const double amountWellCurrency = 16;

  /// See [amountWell].
  static const double amountWellCurrencyDrop = 6;

  /// See [amountWell].
  static const double amountWellGap = 2;

  /// See [amountWell].
  static const double amountWellFigure = 40;

  /// See [amountWell].
  static const double amountWellSmall = 48;

  /// See [amountWell].
  static const double amountWellSmallInset = 14;

  /// See [amountWell].
  static const double amountWellSmallRadius = 12;

  /// A picker (`.pick-r`): at least 60 tall, 10 inside (14 at its end),
  /// corners 14, its parts 12 apart, its chevron 16.
  static const double picker = 60;

  /// See [picker].
  static const EdgeInsets pickerInset = EdgeInsets.fromLTRB(10, 10, 14, 10);

  /// See [picker].
  static const double pickerRadius = 14;

  /// See [picker].
  static const double pickerGap = 12;

  /// See [picker].
  static const double pickerGlyph = 16;

  /// The swap between two pickers (`.swap`): a 32 round (a 16 glyph) on a
  /// 12 line, pulled 14 into both.
  static const double swap = 32;

  /// See [swap].
  static const double swapGlyph = 16;

  /// See [swap].
  static const double swapLine = 12;

  /// See [swap].
  static const double swapPull = 14;

  /// An icon picker's wells (`.ico`): six to a row 8 apart, 44 tall with
  /// corners 12, the glyph 18.
  static const double iconWell = 44;

  /// See [iconWell].
  static const double iconWellRadius = 12;

  /// See [iconWell].
  static const double iconWellGap = 8;

  /// See [iconWell].
  static const double iconWellGlyph = 18;

  /// See [iconWell].
  static const int iconWellsPerRow = 6;

  /// The stepper (`.stepper`): its round buttons 48 across and 12 from the
  /// well, its note pulled 8 up under it.
  static const double stepper = 48;

  /// See [stepper].
  static const double stepperGap = 12;

  /// See [stepper].
  static const double stepperNotePull = 8;

  /// A settings row (`.set-row`): at least 52 tall, 8 over and under, its
  /// parts 12 apart, its lines 2 apart, its chevron 16; its tile's head 4
  /// over the rows; an off row at 0.45.
  static const double settingRow = 52;

  /// See [settingRow].
  static const double settingInset = 8;

  /// See [settingRow].
  static const double settingGap = 12;

  /// See [settingRow].
  static const double settingLineGap = 2;

  /// See [settingRow].
  static const double settingGlyph = 16;

  /// See [settingRow].
  static const double settingsHeadGap = 4;

  /// A settings row that is off: [disabledOpacity], the one share.
  static const double settingOffOpacity = disabledOpacity;

  /// The toggle (`.tgl`): a 44 by 26 track, its knob 22, 2 inside it; off
  /// to use at [disabledOpacity], as every part is.
  static const double toggleWidth = 44;

  /// See [toggleWidth].
  static const double toggleHeight = 26;

  /// See [toggleWidth].
  static const double toggleInset = 2;

  /// See [toggleWidth].
  static const double toggleKnob = 22;

  /// A toggle that is off to use: [disabledOpacity], the one share.
  static const double toggleDisabledOpacity = disabledOpacity;

  /// People (`.people`): 8 apart, each its pearl 8 over its name; one not
  /// chosen, its pearl at 0.55 (its name keeps its ink); chosen, a white ring
  /// of 2 and an ink ring 1.5 past it.
  static const double peopleGap = 8;

  /// See [peopleGap].
  static const double personGap = 8;

  /// See [peopleGap].
  static const double personDimOpacity = 0.55;

  /// See [peopleGap].
  static const double personRingInner = 2;

  /// See [peopleGap].
  static const double personRingOuter = 3.5;

  // --- states --------------------------------------------------------------------

  /// An empty state (`.empty`): 24 over and under, 20 at its sides, its
  /// parts 10 apart, its art 220 by 120 with 6 more under it, its words at
  /// most 300 wide with 10 more under them; on the desktop 40 over, 32 at
  /// its sides and 44 under, 12 apart, its art 330 by 180 with 8 under,
  /// its words 420 wide.
  static const EdgeInsets emptyInset = EdgeInsets.fromLTRB(20, 24, 20, 24);

  /// See [emptyInset].
  static const EdgeInsets emptyInsetWide = EdgeInsets.fromLTRB(32, 40, 32, 44);

  /// See [emptyInset].
  static const double emptyGap = 10;

  /// See [emptyInset].
  static const double emptyGapWide = 12;

  /// See [emptyInset].
  static const Size emptyArt = Size(220, 120);

  /// See [emptyInset].
  static const Size emptyArtWide = Size(330, 180);

  /// See [emptyInset].
  static const double emptyArtGap = 6;

  /// See [emptyInset].
  static const double emptyArtGapWide = 8;

  /// See [emptyInset].
  static const double emptyWordsWidth = 300;

  /// See [emptyInset].
  static const double emptyWordsWidthWide = 420;

  /// See [emptyInset].
  static const double emptyWordsGap = 10;

  /// DERIVED: the loading state's ring (40 across, a stroke of 2) and the
  /// error state's mark (56 across, its glyph 24).
  static const double loadingRing = 40;

  /// See [loadingRing].
  static const double loadingStroke = 2;

  /// See [loadingRing].
  static const double stateMark = 56;

  /// See [loadingRing].
  static const double stateMarkGlyph = 24;

  // --- the shared vocabulary's parts ---------------------------------------------
  //
  // The sizes of the parts every look carries beside the source's own (a
  // check, a slider, tabs, a form's rows, a composer, a dialog, an action
  // bar, a swipe, a week, a stack of avatars); each is DERIVED from the
  // source's language of 4 point steps, its hairlines and its pills.

  /// The completion check: a disc 24 across (the option's) with its ring
  /// 1.5 wide and its tick 14.
  static const double check = 24;

  /// See [check].
  static const double checkRing = 1.5;

  /// See [check].
  static const double checkGlyph = 14;

  /// The slider: a track 6 tall (the bar's) under a knob 22 across (the
  /// toggle's), 44 tall to be reached, a bead of a stepped one 4 across.
  static const double sliderTrack = 6;

  /// See [sliderTrack].
  static const double sliderThumb = 22;

  /// See [sliderTrack].
  static const double sliderHeight = 44;

  /// See [sliderTrack].
  static const double sliderBead = 4;

  /// A tab in a line of tabs: 40 tall, 14 in at each side of its word (the
  /// nav link's), the chosen one on the lit pill.
  static const double tabHeight = 40;

  /// See [tabHeight].
  static const double tabInset = 14;

  /// A form's row: the settings row (52, 8 over and under, 12 apart); its
  /// leading glyph on a 32 round; groups of rows 10 apart.
  static const double formRow = 52;

  /// See [formRow].
  static const double formRowInset = 8;

  /// See [formRow].
  static const double formRowGap = 12;

  /// See [formRow].
  static const double formLeading = 32;

  /// See [formRow].
  static const double rowGroupGap = 10;

  /// The action bar: 16 in at the sides, 12 over its act, its summary
  /// stacking over the act under 320 wide or once the text is scaled to
  /// 1.2 (the host stops the scale at 1.3).
  static const double actionBarSide = 16;

  /// See [actionBarSide].
  static const double actionBarTop = 12;

  /// See [actionBarSide].
  static const double actionBarGap = 12;

  /// See [actionBarSide].
  static const double actionBarStackWidth = 320;

  /// See [actionBarSide].
  static const double actionBarStackScale = 1.2;

  /// The composer: a line 48 tall (the well's) with 4 round its parts, its
  /// text 10 over and under.
  static const double composer = 48;

  /// See [composer].
  static const double composerInset = 4;

  /// See [composer].
  static const double composerText = 10;

  /// The dialog on a phone: at most 320 wide, 24 from the screen's edge,
  /// its words 24 under its head and its acts 20 under its words (the
  /// sheet's own insets round them).
  static const double dialogWidth = 320;

  /// See [dialogWidth].
  static const double dialogEdge = 24;

  /// See [dialogWidth].
  static const double dialogWordsGap = 24;

  /// See [dialogWidth].
  static const double dialogActsGap = 20;

  /// The counter rolls to a new value over 700 milliseconds.
  static const Duration counterRoll = Duration(milliseconds: 700);

  /// A stack of avatars: each 32 across in a ring of the canvas 2 wide, the
  /// next covering 28% of the last.
  static const double avatarStack = 32;

  /// See [avatarStack].
  static const double avatarStackRing = 2;

  /// See [avatarStack].
  static const double avatarStackOverlap = 0.28;

  /// The swipe: each action's block 84 wide with the 8 gap before it, a
  /// drag past 65% of the row's width doing the first action.
  static const double swipeBlock = 84;

  /// See [swipeBlock].
  static const double swipeGap = 8;

  /// See [swipeBlock].
  static const double swipeFull = 0.65;

  /// A day of the week strip: a bead 36 across (the mark's).
  static const double weekBead = 36;

  /// A lead's header room: a cover running up under a header keeps 56
  /// clear under the status bar for it.
  static const double heroHeaderRoom = 56;

  /// A page head: at least 40 tall (the bar's control).
  static const double headMinHeight = 40;

  // --- focus ---------------------------------------------------------------------

  /// DERIVED: the keyboard focus ring, 2 wide (the theme's heavy stroke), 2
  /// off the control, in the ink; the gap between is filled with the page's
  /// ground, so the ring reads on a face filled in the ink too.
  static const double focusRingGap = 2;

  /// See [focusRingGap].
  static const double focusRingWidth = 2;

  /// The one outline width.
  static const double outline = 1;
}
