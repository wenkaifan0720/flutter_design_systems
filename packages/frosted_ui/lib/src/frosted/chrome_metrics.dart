// Frosted's chrome metrics: the sizes of its bars, slabs, sheets and parts as
// the source stylesheet sets them (a phone 390 wide, the sidebar from 1024),
// and the few the system derives where the source draws no instance. Each
// derived constant says so.

import 'package:flutter/widgets.dart' show Color, EdgeInsets, Size;

/// The bars, bands and parts of Frosted's chrome, in points.
abstract final class FrostedChromeMetrics {
  /// The lit hairline round a pane of light glass: white at 85%.
  static const Color litEdge = Color(0xD9FFFFFF);

  /// The page gutter on a phone.
  static const double gutter = 16;

  /// The page gutter on the desktop (`0 32px 40px`).
  static const double gutterWide = 32;

  /// The room under a page's last tile on a phone.
  static const double pageBottom = 20;

  /// The room under a page's last tile on the desktop.
  static const double pageBottomWide = 40;

  /// The gap between tiles in a column on a phone.
  static const double columnGap = 10;

  /// The gap between tiles in a column on the desktop.
  static const double columnGapWide = 16;

  // --- top bars ---------------------------------------------------------------

  /// The room over and under a phone top bar's parts.
  static const double barInset = 10;

  /// The gap between a phone top bar's two sides.
  static const double barGap = 12;

  /// The gap between the controls at a phone top bar's end.
  static const double barEndGap = 8;

  /// A phone top bar's control, the least height of the bar.
  static const double barControl = 40;

  /// The room over the desktop bar's words, in the page.
  static const double barTopWide = 32;

  /// The room under the desktop bar's words.
  static const double barBottomWide = 8;

  /// The gap between a caption and the title under it on a phone.
  static const double captionGap = 2;

  /// The gap between a caption and the title under it on the desktop.
  static const double captionGapWide = 6;

  /// The blur of the frost behind a phone bar, under the canvas at half
  /// strength.
  static const double topFrostBlur = 20;

  /// How far the frost behind a phone bar runs past the bar's foot.
  static const double topFrostReach = 16;

  /// Where the frost behind a phone bar starts to fade: it fades out over its
  /// last 40%.
  static const double topFrostSolid = 0.6;

  /// A phone detail bar: its back and a balancing space 40 wide either side
  /// of the centred kind of record.
  static const double detailColumn = 40;

  /// The chevron of the desktop crumb over a detail's title.
  static const double crumbGlyph = 14;

  /// The gap between the desktop crumb's chevron and its word.
  static const double crumbGap = 2;

  /// How far the desktop crumb is pulled into the gutter.
  static const double crumbPull = 3;

  /// The gap between the desktop crumb and the title under it.
  static const double crumbTitleGap = 6;

  /// A round button across.
  static const double roundButton = 40;

  /// A small round button across.
  static const double roundButtonSmall = 32;

  /// A round button's glyph.
  static const double roundGlyph = 18;

  /// A small round button's glyph.
  static const double roundGlyphSmall = 16;

  /// The bell's unread dot across.
  static const double bellDot = 7;

  /// The bell's unread dot from the bell's top.
  static const double bellDotTop = 9;

  /// The bell's unread dot from the bell's right.
  static const double bellDotRight = 10;

  /// The ring round the bell's unread dot.
  static const double bellDotRing = 2;

  /// A bar's avatar across.
  static const double avatar = 40;

  /// The sidebar foot's and a row's avatar across.
  static const double avatarSmall = 36;

  /// A person's pearl avatar across.
  static const double avatarLarge = 52;

  /// The profile's avatar across.
  static const double avatarProfile = 80;

  /// The letters of a bar's avatar.
  static const double avatarType = 14;

  /// The letters of the sidebar foot's and a row's avatar.
  static const double avatarTypeSmall = 13;

  /// The letters of a person's pearl avatar.
  static const double avatarTypeLarge = 16;

  /// The letters of the profile's avatar.
  static const double avatarTypeProfile = 28;

  // --- the phone tab bar ----------------------------------------------------

  /// The tab bar's slab in from the screen's sides, on the page's gutter; a
  /// floating action bar stands on it too.
  static const double tabBarSide = gutter;

  /// The tab bar's slab over the foot, or the system's inset where that is
  /// more.
  static const double tabBarBottom = 12;

  /// A tab's share of the slab from a tablet's width
  /// ([FrostedBreakpoints.medium]), where the slab hugs its tabs in the
  /// middle of the foot.
  static const double tabBarTabMedium = 120;

  /// The narrowest the slab stands there under an accessory.
  static const double tabBarAccessoryMedium = 480;

  /// The band above the foot over which the page fades into the canvas under
  /// the tab bar.
  static const double tabBarFade = 104;

  /// Where the fade under the tab bar takes [tabBarFadeMidAlpha] of the canvas.
  static const double tabBarFadeMid = 0.48;

  /// Where the fade under the tab bar reaches the whole canvas.
  static const double tabBarFadeLow = 0.8;

  /// How much of the canvas the fade under the tab bar takes at
  /// [tabBarFadeMid].
  static const double tabBarFadeMidAlpha = 0.88;

  /// The slab's height.
  static const double slabHeight = 64;

  /// How long the selection's pill takes to slide to a new choice (a tab, a
  /// segment).
  static const Duration selectionSlide = Duration(milliseconds: 280);

  /// How far inside the slab's edge the chosen tab's plate stands, the same
  /// on every side, so its corners run concentric with the slab's (22 less
  /// the edge's 1 and these 4: 17).
  static const double selectionInset = 4;

  /// The slab's own room at its ends: none, so a plate at either end stands
  /// [selectionInset] from the slab's side as from its top.
  static const double slabInset = 0;

  /// The slab's corners.
  static const double slabRadius = 22;

  /// A footer's slab (FrostedFootSlab, where a page's footer floats): its
  /// acts this far inside its edge, so a row of buttons (44) stands it as
  /// tall as the tab bar's slab ([slabHeight]).
  static const double footSlabInset = 10;

  /// The blur of the slab's frost.
  static const double slabBlur = 24;

  /// The saturation of the colour behind the slab's frost.
  static const double slabSaturation = 1.4;

  /// A tab's glyph.
  static const double tabGlyph = 20;

  /// The gap between a tab's glyph and its word.
  static const double tabGap = 4;

  /// The Move pill's height, in the slab's middle.
  static const double movePill = 40;

  /// The Move pill's room at its start.
  static const double movePillInsetStart = 12;

  /// The Move pill's room at its end.
  static const double movePillInsetEnd = 12;

  /// The gap between the Move pill's glyph and its word.
  static const double movePillGap = 4;

  /// The Move pill's glyph.
  static const double movePillGlyph = 16;

  /// The room either side of the Move pill.
  static const double movePillRoom = 6;

  /// The white ring round the Move pill when it shows.
  static const double movePillRingInner = 2;

  /// The reach of the ink ring past the Move pill's white ring.
  static const double movePillRingOuter = 3.5;

  /// An accessory stands 8 over the slab.
  static const double accessoryGap = 8;

  /// Drawn by nothing since 0.8.1: a footer stands on the bar's glass with
  /// the page passing under it, and no fade covers the page.
  @Deprecated(
    'No longer drawn: the footer stands on glass, with no fade over the page. '
    'Removed in 0.9.0.',
  )
  static const double footerFade = 32;

  /// The blur of the frost behind a tile of glass.
  static const double frostBlur = 24;

  /// The saturation of the colour behind a tile of glass.
  static const double frostSaturation = 1.3;

  // --- the desktop sidebar ----------------------------------------------------

  /// The sidebar's width.
  static const double sideWidth = 240;

  /// The room above the sidebar's wordmark.
  static const double sideTop = 28;

  /// The sidebar's room at its start.
  static const double sideStart = 20;

  /// The sidebar's room at its end.
  static const double sideEnd = 16;

  /// The sidebar's room at its foot.
  static const double sideBottom = 24;

  /// The gap between the sidebar's parts.
  static const double sideGap = 24;

  /// The wordmark's height.
  static const double brandHeight = 40;

  /// The wordmark's mark on the links' keyline: where a link's glyph's ink
  /// starts ([navLinkInset], the pill's 1 edge and the glyph's own 2 side
  /// bearing).
  static const double brandInset = navLinkInset + 3;

  /// The gap between the wordmark's mark and its word.
  static const double brandGap = 10;

  /// The wordmark's mark across.
  static const double brandMark = 28;

  /// The corners of the wordmark's mark.
  static const double brandMarkRadius = 9;

  /// The glyph in the wordmark's mark.
  static const double brandMarkGlyph = 18;

  /// The height of the sidebar's main act, across the sidebar.
  static const double sideAct = 40;

  /// The gap between the sidebar's main act's glyph and its word.
  static const double sideActGap = 8;

  /// The sidebar's main act's glyph.
  static const double sideActGlyph = 18;

  /// A nav link's height.
  static const double navLink = 40;

  /// A nav link's room at its sides.
  static const double navLinkInset = 14;

  /// The gap between a nav link's glyph and its word.
  static const double navLinkGap = 12;

  /// A nav link's glyph.
  static const double navGlyph = 18;

  /// The gap between nav links.
  static const double navGap = 2;

  /// The sidebar foot's room at its start, its avatar on the links' keyline
  /// (where the links' glyph ink starts).
  static const double footInsetStart = navLinkInset + 2;

  /// The sidebar foot's room at its end.
  static const double footInsetEnd = 8;

  /// The sidebar foot's room over and under its parts.
  static const double footInsetVertical = 8;

  /// The gap between the sidebar foot's avatar and the name.
  static const double footGap = 12;

  /// The gap between the sidebar foot's name and the quiet line under it.
  static const double footLineGap = 4;

  // --- buttons ------------------------------------------------------------------

  /// A button's height.
  static const double buttonHeight = 44;

  /// A button's room at its sides.
  static const double buttonInset = 20;

  /// The gap between a button's glyph and its word.
  static const double buttonGap = 8;

  /// A button's glyph.
  static const double buttonGlyph = 18;

  /// A small button's height.
  static const double buttonSmallHeight = 32;

  /// A small button's room at its sides.
  static const double buttonSmallInset = 14;

  /// The gap between a small button's glyph and its word.
  static const double buttonSmallGap = 6;

  /// A small button's glyph.
  static const double buttonSmallGlyph = 14;

  /// A small button's word.
  static const double buttonSmallWord = 12;

  /// A wide button's height, across its line.
  static const double buttonWideHeight = 48;

  /// A wide button's word.
  static const double buttonWideWord = 16;

  /// The share of the page's ink a glass button on another glass (a sheet,
  /// a dialog, a card) is shaded by in a light theme: the capsule parts from
  /// the glass it stands on, whatever that glass shows.
  static const double glassStepDay = .07;

  /// An empty opening's step by day (an unchosen radio, an unchecked box, a
  /// switch turned off): the ink at 16% over its well, so the opening
  /// reads on a pale canvas.
  static const double openingStepDay = .16;

  /// A disabled empty opening's step by day: the ink at 8% over paint, then
  /// drawn at [disabledOpacity] as every part that takes no input, so it
  /// stands fainter than a live empty opening and the live one reads first.
  static const double openingStepOffDay = .08;

  /// [glassStepDay] in a dark theme, the ink being light.
  static const double glassStepNight = .12;

  /// What cannot be used is drawn at this share, once: a control alone, or a row that is off as one thing, its
  /// words and its control together, the control inside it then at full
  /// strength.
  static const double disabledOpacity = 0.45;

  // --- money --------------------------------------------------------------------

  /// The desktop's giant figure.
  static const double moneyGiant = 96;

  /// The display figure.
  static const double moneyDisplay = 64;

  /// The figure.
  static const double moneyFigure = 40;

  /// The small figure.
  static const double moneyFigureSmall = 28;

  /// The hung `$` and stepped-down cents against the desktop's giant figure.
  static const double moneyCentsGiant = 40;

  /// The hung `$` and stepped-down cents against the display figure.
  static const double moneyCentsDisplay = 28;

  /// The hung `$` and stepped-down cents against the figure.
  static const double moneyCentsFigure = 16;

  /// The hung `$` and stepped-down cents against the small figure.
  static const double moneyCentsFigureSmall = 16;

  /// How far the hung `$` and cents ride down from the giant figure's cap line,
  /// in ems.
  static const double moneyDropGiant = 0.12;

  /// How far the hung `$` and cents ride down from the display figure's cap
  /// line, in ems.
  static const double moneyDropDisplay = 0.1;

  /// How far the hung `$` and cents ride down from the figure's cap line, in
  /// ems.
  static const double moneyDropFigure = 0.14;

  /// How far the hung `$` and cents ride down from the small figure's cap line,
  /// in ems.
  static const double moneyDropFigureSmall = 0.06;

  /// The room the hung `$` keeps before the dollars, in ems.
  static const double moneyCurrencyGap = 0.05;

  /// The room the stepped-down cents keep after the dollars, in ems.
  static const double moneyCentsGap = 0.03;

  /// The gap between the home figure and its head.
  static const double heroFigureTop = 14;

  /// The gap between the home figure and its change line.
  static const double heroFigureBottom = 10;

  /// The gap between a figure and the quiet comparison under it ("of $2,700").
  static const double figureOfGap = 8;

  // --- the light ------------------------------------------------------------------

  /// The field of washes of light over the top of every page on a phone.
  static const double lightField = 560;

  /// The field of washes of light over the top of every page on the desktop.
  static const double lightFieldWide = 640;

  /// The blur of each disc of light on a phone.
  static const double lightBlur = 56;

  /// The blur of each disc of light on the desktop.
  static const double lightBlurWide = 72;

  // --- sheets, menus, toasts -----------------------------------------------

  /// The room above a phone sheet's grabber.
  static const double sheetTop = 8;

  /// A phone sheet's room at its sides.
  static const double sheetSide = 16;

  /// The room under a phone sheet's last part.
  static const double sheetBottom = 24;

  /// The gap between a phone sheet's parts.
  static const double sheetGap = 12;

  /// The most of the screen a phone sheet takes.
  static const double sheetMaxFraction = 0.88;

  /// A desktop dialog's width.
  static const double sheetWideWidth = 440;

  /// A desktop dialog's corners.
  static const double sheetWideRadius = 20;

  /// How far short of the window's height a desktop dialog stops at most.
  static const double sheetWideMargin = 64;

  /// The room above a desktop dialog's head.
  static const double sheetWideTop = 20;

  /// A desktop dialog's room at its sides.
  static const double sheetWideSide = 24;

  /// A desktop dialog's room at its foot.
  static const double sheetWideBottom = 24;

  /// A side sheet's width ([FrostedSheet.showSide]): the screen less 56
  /// at most, as ui_core leaves the scrim showing.
  static const double sideSheetWidth = 360;

  /// The grabber's width.
  static const double grabberWidth = 36;

  /// The grabber's height.
  static const double grabberHeight = 4;

  /// The gap between the grabber and the head.
  static const double grabberGap = 12;

  /// The least height of a sheet's head.
  static const double sheetHead = 40;

  /// The gap between a sheet's title and its close.
  static const double sheetHeadGap = 12;

  /// The gap between a sheet's head and its body.
  static const double sheetBodyGap = 12;

  /// The gap between a sheet's body and its foot.
  static const double sheetFootGap = 12;

  /// A sheet's acts under its body: 16, the form body's gap they stand in.
  static const double sheetFormFootGap = 16;

  /// The rise of a sheet.
  static const Duration sheetIn = Duration(milliseconds: 320);

  /// The fall of a sheet.
  static const Duration sheetOut = Duration(milliseconds: 220);

  /// An option's least height, a hairline between two.
  static const double option = 52;

  /// An option's room over and under its parts.
  static const double optionInset = 6;

  /// An option's room at its end.
  static const double optionInsetEnd = 4;

  /// The gap between an option's parts.
  static const double optionGap = 12;

  /// The disc of an option's check.
  static const double optionCheck = 24;

  /// The glyph of an option's check.
  static const double optionCheckGlyph = 14;

  /// A menu's width.
  static const double menuWidth = 288;

  /// A menu's room inside.
  static const double menuInset = 6;

  /// A menu's corners.
  static const double menuRadius = 16;

  /// The gap between a menu and its anchor.
  static const double menuGap = 8;

  /// A select's list under its field: close enough that its rounded corner
  /// covers the helper words below the field rather than framing them.
  static const double listGap = 4;

  /// The gap between a menu's items.
  static const double menuItemsGap = 2;

  /// The room above a menu's head.
  static const double menuHeadTop = 8;

  /// A menu's head's room at its sides.
  static const double menuHeadSide = 10;

  /// The room under a menu's head.
  static const double menuHeadBottom = 6;

  /// A menu item's height.
  static const double menuItem = 40;

  /// A menu item's room at its sides.
  static const double menuItemInset = 10;

  /// A menu item's corners.
  static const double menuItemRadius = 10;

  /// The gap between a menu item's columns.
  static const double menuItemGap = 10;

  /// A menu item's check.
  static const double menuItemGlyph = 16;

  /// A toast's least height.
  static const double toastHeight = 52;

  /// A toast's room inside.
  static const double toastInset = 8;

  /// A toast's room at its start.
  static const double toastInsetStart = 12;

  /// A toast's corners.
  static const double toastRadius = 16;

  /// The gap between a toast's parts.
  static const double toastGap = 12;

  /// A toast's mark across.
  static const double toastMark = 28;

  /// The glyph of a toast's mark.
  static const double toastMarkGlyph = 16;

  /// A toast's act's height.
  static const double toastAct = 36;

  /// A toast's act's room at its sides.
  static const double toastActInset = 14;

  /// A toast in from the screen's sides.
  static const double toastSide = 16;

  /// A toast over the tab bar (88 from the foot), a route's footer or the
  /// screen's safe inset.
  static const double toastOverBar = 12;

  /// A toast on the desktop from the window's right and foot.
  static const double toastWideEdge = 32;

  /// A toast's width on the desktop.
  static const double toastWideWidth = 380;

  /// How far a toast rises as it comes in.
  static const double toastRise = 16;

  /// How long a toast stays.
  static const Duration toastDwell = Duration(milliseconds: 3200);

  /// How long a toast with an act stays.
  static const Duration toastDwellAction = Duration(milliseconds: 5600);

  // --- marks ---------------------------------------------------------------------

  /// A monogram or a token across.
  static const double mark = 36;

  /// A monogram's or a token's corners.
  static const double markRadius = 11;

  /// A monogram's or a token's glyph.
  static const double markGlyph = 18;

  /// A monogram's letters.
  static const double markType = 13;

  /// A large monogram or token across.
  static const double markLarge = 56;

  /// A large monogram's or token's corners.
  static const double markLargeRadius = 17;

  /// A large monogram's or token's glyph.
  static const double markLargeGlyph = 24;

  /// A large monogram's letters.
  static const double markLargeType = 20;

  /// A ticket's monogram or a browse card's token across.
  static const double markSmall = 32;

  /// A ticket's monogram's corners.
  static const double markSmallRadius = 10;

  /// A browse card's token's glyph.
  static const double markSmallGlyph = 16;

  /// A ticket's monogram's letters.
  static const double markSmallType = 12;

  /// The ink mark across.
  static const double inkMark = 28;

  /// The ink mark's corners.
  static const double inkMarkRadius = 9;

  /// The ink mark's glyph.
  static const double inkMarkGlyph = 18;

  /// A date block's size.
  static const Size dateBlock = Size(40, 44);

  /// A date block's corners.
  static const double dateBlockRadius = 11;

  /// The gap between a date block's month and the day under it.
  static const double dateGap = 4;

  /// A chip's height.
  static const double chipHeight = 24;

  /// A chip's room at its sides.
  static const double chipInset = 10;

  /// The gap between a chip's glyph and its word.
  static const double chipGap = 4;

  /// A chip's glyph.
  static const double chipGlyph = 14;

  /// The height of a glass pill on the card.
  static const double glassPillHeight = 24;

  /// A glass pill's room at its sides.
  static const double glassPillInset = 10;

  /// A glass pill's glyph.
  static const double glassPillGlyph = 14;

  /// The blur behind a glass pill.
  static const double glassPillBlur = 8;

  /// The segmented control's room inside; the strip stays 32 tall, as iOS's
  /// does.
  static const double segmentsInset = 2;

  /// The gap between the segmented control's segments.
  static const double segmentsGap = 2;

  /// A segment's height.
  static const double segmentHeight = 28;

  /// A segment's least width.
  static const double segmentMinWidth = 36;

  /// A segment's room at its sides.
  static const double segmentInset = 10;

  /// A segment's height where the control fills a field's line, its word 14.
  static const double segmentFillHeight = 38;

  /// A swatch across.
  static const double swatch = 8;

  /// A visit's dot across.
  static const double visitDot = 10;

  /// The unread dot across.
  static const double unreadDot = 8;

  /// How far the unread dot is cut clear of what it stands on.
  static const double unreadDotRing = 2;

  // --- structure -------------------------------------------------------------------

  /// A tile's room inside on a phone.
  static const double tileInset = 16;

  /// A tile's room inside on the desktop.
  static const double tileInsetWide = 20;

  /// The least height of a tile's head.
  static const double tileHead = 24;

  /// The gap between a tile's head and its body.
  static const double tileHeadGap = 12;

  /// The gap between a tile head's two sides.
  static const double tileHeadRowGap = 12;

  /// The room over a section head's words.
  static const double sectionHeadTop = 10;

  /// A section head's room at its sides.
  static const double sectionHeadInset = 2;

  /// The room a list tile keeps over and under its rows.
  static const double listInset = 8;

  /// The room under the rows of a list with its own head on the desktop; it
  /// keeps the tile's inset over them.
  static const double listBottomWide = 12;

  /// A row's least height.
  static const double row = 52;

  /// A row's room over and under its parts.
  static const double rowInset = 6;

  /// The gap between a row's parts.
  static const double rowGap = 12;

  /// The gap between a row's lines.
  static const double rowLineGap = 1;

  /// The gap between the lines of a row's end column.
  static const double rowEndGap = 4;

  /// The glyph of a row's pending mark.
  static const double rowPendingGlyph = 12;

  /// The gap between a pending mark's glyph and its word.
  static const double rowPendingGap = 4;

  /// A list's account column's width on the desktop.
  static const double rowAccountWide = 148;

  /// The glyph in a list's account column.
  static const double rowAccountGlyph = 16;

  /// The gap between the account column's glyph and its word.
  static const double rowAccountGap = 8;

  /// The least width of a row's amount on the desktop.
  static const double rowAmountWide = 96;

  /// The room over a day's head in a list.
  static const double dayTop = 14;

  /// The room over a day's head that leads its list.
  static const double dayTopFirst = 2;

  /// The room under a day's head in a list.
  static const double dayBottom = 4;

  /// The room over a month divider's hairline in a list.
  static const double monthDividerTop = 10;

  /// The room under a month divider's hairline in a list.
  static const double monthDividerBottom = 16;

  /// How far a marked row's mark runs past the rows either side.
  static const double rowMarkBleed = 10;

  /// The corners of a marked row's mark.
  static const double rowMarkRadius = 12;

  /// The least height of a key and its value's line.
  static const double keyValue = 52;

  /// A key and value line's room over and under.
  static const double keyValueInset = 8;

  /// The gap between a key and value line's two sides.
  static const double keyValueGap = 12;

  /// The gap between a value's parts.
  static const double keyValuePartsGap = 8;

  /// The gap between a value's two lines.
  static const double keyValueLineGap = 2;

  /// A key and value line's chevron.
  static const double keyValueGlyph = 16;

  /// The gap between keys and values set as a grid on the desktop.
  static const double keyValueGridGap = 16;

  /// A grid key and value's room over and under.
  static const double keyValueGridInset = 12;

  /// The gap between a grid key's label and its value.
  static const double keyValueGridLineGap = 4;

  /// Where a grid key's chevron stands from its top: on the value's line.
  static const double keyValueGridChevronTop = 35;

  /// How many keys and values stand to a row in the grid.
  static const int keyValueGridColumns = 3;

  /// A stat's room over and under on a phone, under a figure.
  static const double statInset = 10;

  /// The gap between a stat's two sides on a phone.
  static const double statGap = 12;

  /// The gap either side of the hairline between stats in a line on the
  /// desktop.
  static const double statGapWide = 24;

  /// The gap between a stat's word and its figure under it on the desktop.
  static const double statLineGapWide = 6;

  /// The room under the stats' line on the desktop.
  static const double statsBottomWide = 4;

  /// The gap between a record's hero's parts.
  static const double recordGap = 16;

  /// The gap between a record's hero's mark and its words.
  static const double recordMarkGap = 12;

  /// The gap between a record's hero's figure and its comparison.
  static const double recordFigureGap = 10;

  /// The gap between a record's hero's chips.
  static const double recordChipsGap = 8;

  /// How far a record's hero's chips are pulled up toward its words.
  static const double recordChipsPull = 6;

  /// The room over a transaction's hero's mark.
  static const double transactionTop = 28;

  /// The room under a transaction's hero's last line.
  static const double transactionBottom = 24;

  /// The gap between a transaction's hero's parts.
  static const double transactionGap = 6;

  /// The room over a transaction's hero's figure.
  static const double transactionFigureTop = 14;

  /// The room under a transaction's hero's figure.
  static const double transactionFigureBottom = 12;

  /// The gap under a transaction's hero's mark.
  static const double transactionMarkGap = 8;

  /// The gap between a transaction's hero's facts.
  static const double transactionMetaGap = 8;

  /// The room over a review's hero.
  static const double reviewTop = 24;

  /// The room under a review's hero.
  static const double reviewBottom = 24;

  /// The gap between a review's hero's parts.
  static const double reviewGap = 8;

  /// The room over a review's hero's figure.
  static const double reviewFigureTop = 8;

  /// The room under a review's hero's figure.
  static const double reviewFigureBottom = 4;

  /// The rim of light along a hero's top: 1 tall, nothing at 4%, its stops
  /// at 18, 38, 56 and 76%, nothing at 96%.
  static const double heroRim = 1;

  /// A notification's room over and under.
  static const double noteInset = 12;

  /// The gap between a notification's parts.
  static const double noteGap = 12;

  /// A notification's glyph.
  static const double noteGlyph = 16;

  /// The gap between a notification's words and its when.
  static const double noteWhenGap = 4;

  /// The gap between the newest notification's parts.
  static const double noteNewGap = 14;

  /// The gap between the newest notification's head's dot and its word.
  static const double noteNewHeadGap = 8;

  /// The gap between the newest notification's title's lines.
  static const double noteNewLineGap = 6;

  /// The room over the profile's avatar.
  static const double profileTop = 28;

  /// The gap between the profile's avatar and the name.
  static const double profileAvatarGap = 8;

  /// The gap between the profile hero's lines.
  static const double profileGap = 6;

  /// The room over the profile's facts.
  static const double profileFactsGap = 10;

  /// The corners of a ticket on the rent band.
  static const double ticketRadius = 10;

  /// A ticket's room inside.
  static const double ticketInset = 8;

  /// A ticket's room at its end.
  static const double ticketInsetEnd = 12;

  /// The gap between a ticket's parts.
  static const double ticketGap = 10;

  /// The gap between a ticket's lines.
  static const double ticketLineGap = 2;

  /// A due line's height.
  static const double dueLine = 8;

  /// A due line's bead across.
  static const double dueBead = 8;

  /// How far in a due line's beads stand.
  static const double dueInset = 4;

  /// The gap between a due line's words.
  static const double dueLabelGap = 8;

  // --- meters and the prism ---------------------------------------------------------

  /// The prism track's height.
  static const double frostedTrack = 40;

  /// The prism track's height on the desktop's spending.
  static const double frostedTrackWide = 56;

  /// A small prism track's height.
  static const double frostedTrackSmall = 16;

  /// The least height of a prism track.
  static const double frostedTrackLeast = 10;

  /// The gap between the prism track's bands.
  static const double frostedGap = 1;

  /// The pace tick's width.
  static const double paceTick = 1.5;

  /// How far the pace tick reaches over and under the track.
  static const double paceReach = 6;

  /// How far the pace tick reaches over and under a small track.
  static const double paceReachSmall = 5;

  /// The ring round the pace tick.
  static const double paceRing = 1.5;

  /// The gap between the prism track and its scale.
  static const double frostedScaleGap = 10;

  /// The least height of the prism track's scale.
  static const double frostedScaleHeight = 16;

  /// The gap between the pace's word and the tick.
  static const double paceLabelGap = 8;

  /// How far in a band's words stand.
  static const double frostedLabelInset = 10;

  /// How far in a band's words stand at the track's ends.
  static const double frostedLabelInsetEnd = 16;

  /// The gap between a band's words.
  static const double frostedLabelGap = 4;

  /// A bar's height.
  static const double bar = 6;

  /// A thin bar's height.
  static const double barThin = 4;

  /// A tube's height.
  static const double tube = 8;

  /// A large tube's height.
  static const double tubeLarge = 12;

  /// A tube's tick's width.
  static const double tubeTick = 1.5;

  /// A tube's tick's height.
  static const double tubeTickHeight = 20;

  /// A tube's tick's height in a comparison.
  static const double tubeTickHeightCompare = 16;

  /// An over bar's height.
  static const double overBar = 6;

  /// A large over bar's height.
  static const double overBarLarge = 10;

  /// The gap between an over bar's two parts.
  static const double overBarGap = 2;

  /// An over bar's scale's height.
  static const double overBarScale = 14;

  /// The gap between an over bar and its scale.
  static const double overBarScaleGap = 8;

  /// The height of a meter on a pane's floor.
  static const double meter = 4;

  /// The height of a meter on a small pane's floor.
  static const double meterSmall = 3;

  /// The gap between a meter's parts.
  static const double meterGap = 1;

  /// The card's utilisation bar's width.
  static const double utilWidth = 180;

  /// The card's utilisation bar's height.
  static const double utilHeight = 4;

  /// The gap between the legend's two columns; the goals' legend stands three
  /// across.
  static const double legendColumnGap = 16;

  /// The gap between the legend's entries.
  static const double legendRowGap = 12;

  /// The gap between a legend entry's swatch and its words.
  static const double legendSwatchGap = 8;

  /// The gap between a legend entry's lines.
  static const double legendLineGap = 4;

  /// The size of a chart key's line.
  static const Size keyLine = Size(16, 2);

  /// The gap between a chart key's line and its word.
  static const double keyGap = 8;

  /// The gap between keys under a chart.
  static const double keysGap = 16;

  /// The gap between keys in a chart's head.
  static const double keysGapHead = 12;

  /// A merchant line's room over and under.
  static const double merchantInset = 6;

  /// The gap between a merchant line's columns.
  static const double merchantGap = 12;

  /// The gap between a merchant line and its bar.
  static const double merchantBarGap = 6;

  /// A merchant card's room inside on the desktop, where four stand across.
  static const double merchantCardInset = 16;

  /// The gap between a merchant card's rows.
  static const double merchantCardGap = 12;

  /// The gap between the shares in a line under a figure.
  static const double partsGap = 8;

  /// The gap between a share's parts.
  static const double partGap = 10;

  /// The room between a figure and the shares' line under it.
  static const double partsTop = 14;

  /// The gap between a share's word and the next.
  static const double partShareGap = 8;

  // --- the mosaic ---------------------------------------------------------------

  /// The spend mosaic's height on a phone.
  static const double mosaicHeight = 540;

  /// The spend mosaic's height on the desktop.
  static const double mosaicHeightWide = 520;

  /// The gap between the spend mosaic's panes.
  static const double mosaicGap = 6;

  /// A pane's room inside on a phone.
  static const double paneInset = 10;

  /// A pane's room inside on the desktop.
  static const double paneInsetWide = 12;

  /// The gap between a pane's parts.
  static const double paneGap = 6;

  /// The gap between the parts on a pane's floor.
  static const double paneFloorGap = 8;

  /// A small pane's room inside on a phone.
  static const double paneSmallInset = 8;

  /// A small pane's room inside on the desktop.
  static const EdgeInsets paneSmallInsetWide = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 12,
  );

  /// The gap between a small pane's parts.
  static const double paneSmallGap = 2;

  /// A group's basis in the spend mosaic.
  static const double mosaicBasis = 24;

  /// The room inside the tile round the spend mosaic.
  static const double mosaicTileInset = 8;

  /// How far in the spend mosaic's head stands on a phone.
  static const double mosaicHeadInset = 8;

  /// How far in the spend mosaic's head stands on the desktop.
  static const double mosaicHeadInsetWide = 12;

  /// The least height of the spend mosaic's head on a phone.
  static const double mosaicHead = 32;

  /// The least height of the spend mosaic's head on the desktop.
  static const double mosaicHeadWide = 36;

  /// The gap between the parts of the rent band's middle.
  static const double rentGap = 12;

  /// The rent band's ticket's width on the desktop.
  static const double rentTicketWide = 340;

  // --- the card ----------------------------------------------------------------

  /// How many times as wide as tall the pearl credit card stands.
  static const double cardAspect = 1.586;

  /// The pearl credit card's corners on a phone.
  static const double cardRadius = 16;

  /// The pearl credit card's corners on the desktop.
  static const double cardRadiusWide = 18;

  /// How far the pearl credit card is turned on the desktop, in degrees.
  static const double cardTurnWide = -4;

  /// The pearl credit card's room inside on a phone.
  static const double cardInset = 18;

  /// The pearl credit card's room inside on the desktop.
  static const double cardInsetWide = 20;

  /// The blur of the pearl credit card's frost.
  static const double cardFrostBlur = 16;

  /// Where the glow under the pearl credit card stands on a phone: under its
  /// top, in from its sides and over its foot.
  static const EdgeInsets cardGlow = EdgeInsets.fromLTRB(28, 24, 28, 8);

  /// Where the glow under the pearl credit card stands on the desktop.
  static const EdgeInsets cardGlowWide = EdgeInsets.fromLTRB(60, 44, 60, 16);

  /// The blur of the pearl credit card's glow on a phone.
  static const double cardGlowBlur = 36;

  /// The blur of the pearl credit card's glow on the desktop.
  static const double cardGlowBlurWide = 44;

  /// The pearl credit card's brand.
  static const double cardBrandType = 20;

  /// The gap between the pearl credit card's mark and its brand.
  static const double cardBrandGap = 8;

  /// The gap between the lines of the pearl credit card's middle.
  static const double cardMidGap = 8;

  /// The tracking of the pearl credit card's number, in ems.
  static const double cardNumberTracking = 0.04;

  /// The pearl credit card's orbits across.
  static const double cardOrbits = 380;

  /// Where the pearl credit card's orbits stand from its right edge (past it).
  static const double cardOrbitsRight = -120;

  /// Where the pearl credit card's orbits stand from its top (over it).
  static const double cardOrbitsTop = -140;

  /// The pearl credit card's room in its stage on the desktop.
  static const EdgeInsets cardStageWide = EdgeInsets.fromLTRB(28, 16, 28, 4);

  /// The pearl credit card's room in its stage on the Cards page.
  static const EdgeInsets cardStageCards = EdgeInsets.fromLTRB(8, 12, 8, 8);

  /// The pearl credit card's width on the Cards page.
  static const double cardStageWidth = 300;

  /// The size of a debit card's small face.
  static const Size debitCard = Size(92, 58);

  /// The corners of a debit card's small face.
  static const double debitCardRadius = 9;

  /// The room inside a debit card's small face.
  static const double debitCardInset = 8;

  /// The mark on a debit card's small face across.
  static const double debitCardMark = 18;

  /// The corners of the mark on a debit card's small face.
  static const double debitCardMarkRadius = 6;

  /// The glyph of the mark on a debit card's small face.
  static const double debitCardMarkGlyph = 12;

  /// The gap between a debit card's small face and its words.
  static const double debitCardGap = 14;

  /// The gap either side of the hairline between the card's three figures.
  static const double cardFigureGap = 12;

  /// The gap between a card figure's lines.
  static const double cardFigureLineGap = 4;

  /// The room over and under the card's figures' lines on the desktop.
  static const double cardFigureInsetWide = 10;

  /// The room over the card's limit bar.
  static const double limitTop = 4;

  /// The room under the card's limit bar.
  static const double limitBottom = 2;

  /// The gap between the card's limit bar and its scale.
  static const double limitScaleGap = 8;

  /// The blur of the frost over a frozen card.
  static const double frostBlur5 = 5;

  /// The round a frozen card's glyph stands on, across.
  static const double frostMark = 48;

  /// A frozen card's glyph.
  static const double frostMarkGlyph = 24;

  /// The gap between a frozen card's glyph and its word.
  static const double frostGap = 8;

  /// The frozen banner's mark across.
  static const double bannerMark = 36;

  /// The frozen banner's mark's glyph.
  static const double bannerMarkGlyph = 18;

  /// The gap between the frozen banner's mark and its words.
  static const double bannerGap = 12;

  /// The frozen banner's room inside.
  static const EdgeInsets bannerInset = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 16,
  );

  /// The freeze dialog's mark across.
  static const double freezeMark = 56;

  /// The freeze dialog's mark's glyph.
  static const double freezeMarkGlyph = 24;

  /// The statement line's height.
  static const double statementLine = 12;

  /// The room over the statement line, collapsing into a head's room above it.
  static const double statementLineTop = 2;

  /// How far in the statement line stands.
  static const double statementLineInset = 6;

  /// Where the statement line's rule stands from its top.
  static const double statementRuleTop = 5.5;

  /// A statement line's bead across.
  static const double statementBead = 12;

  /// The height of the statement line's words.
  static const double statementLabels = 42;

  /// The room over and under the statement line's words.
  static const double statementLabelsGap = 10;

  /// The gap between the statement line's words' lines.
  static const double statementLabelLineGap = 4;

  /// The corners of the card number's well.
  static const double numberRadius = 14;

  /// The room inside the card number's well.
  static const EdgeInsets numberInset = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 16,
  );

  /// The gap between the card number's well's lines.
  static const double numberGap = 8;

  /// The gap between the card number's three facts.
  static const double numberFactsGap = 12;

  /// How far in the card number's facts stand.
  static const double numberFactsInset = 4;

  /// The gap between a card number fact's lines.
  static const double numberFactLineGap = 6;

  // --- home pieces ----------------------------------------------------------------

  /// The gap between the quick actions.
  static const double actionGap = 4;

  /// The quick actions' room.
  static const EdgeInsets actionsInset = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: 8,
  );

  /// A quick action's disc across.
  static const double actionRound = 44;

  /// A quick action's glyph.
  static const double actionGlyph = 18;

  /// The gap between a quick action's disc and its word.
  static const double actionWordGap = 8;

  /// The corners of a way to move money.
  static const double moveActRadius = 14;

  /// A way to move money's room inside on a phone.
  static const double moveActInset = 10;

  /// A way to move money's room inside on the desktop.
  static const double moveActInsetWide = 16;

  /// A way to move money's disc across on a phone.
  static const double moveActRound = 32;

  /// A way to move money's disc across on the desktop.
  static const double moveActRoundWide = 40;

  /// A way to move money's glyph on a phone.
  static const double moveActGlyph = 16;

  /// A way to move money's glyph on the desktop.
  static const double moveActGlyphWide = 18;

  /// The gap between a way to move money's disc and its words on a phone.
  static const double moveActGap = 10;

  /// The gap between a way to move money's disc and its words on the desktop.
  static const double moveActGapWide = 14;

  /// The gap between a way to move money's lines on a phone.
  static const double moveActLineGap = 2;

  /// The gap between a way to move money's lines on the desktop.
  static const double moveActLineGapWide = 4;

  /// The gap between the ways to move money, two across.
  static const double moveActsGap = 8;

  /// An account card's room inside on a phone, where two stand across.
  static const double accountInset = 14;

  /// An account card's room inside on the desktop, where four stand across.
  static const EdgeInsets accountInsetWide = EdgeInsets.symmetric(
    vertical: 18,
    horizontal: 20,
  );

  /// The gap between an account card's parts.
  static const double accountGap = 10;

  /// The gap between an account card and its note.
  static const double accountNoteGap = 6;

  /// A goal's room over and under.
  static const double goalInset = 10;

  /// The gap between a goal's parts.
  static const double goalGap = 10;

  /// The gap between a goal's head's parts.
  static const double goalHeadGap = 12;

  /// The gap between a goal card's columns.
  static const double goalCardColumnGap = 12;

  /// The gap between a goal card's rows on a phone.
  static const double goalCardRowGap = 10;

  /// The gap between a goal card's rows on the desktop.
  static const double goalCardRowGapWide = 14;

  /// The gap between a goal card's figure's parts.
  static const double goalCardFigureGap = 8;

  /// The gap between a goal card's bar and its share.
  static const double goalCardBarGap = 12;

  /// The least width of a goal card's share.
  static const double goalCardShare = 40;

  /// A ghost card's room inside.
  static const double ghostInset = 16;

  /// A ghost card's corners.
  static const double ghostRadius = 14;

  /// The new-goal tile's plus across.
  static const double newGoalPlus = 36;

  /// The corners of the new-goal tile's plus.
  static const double newGoalPlusRadius = 11;

  /// The glyph of the new-goal tile's plus.
  static const double newGoalPlusGlyph = 18;

  /// The new-goal tile's glyph.
  static const double newGoalGlyph = 16;

  /// The gap between the new-goal tile's parts on a phone.
  static const double newGoalGap = 12;

  /// The gap between the new-goal tile's parts on the desktop.
  static const double newGoalGapWide = 16;

  /// A nudge's corners.
  static const double nudgeRadius = 14;

  /// A nudge's room inside.
  static const EdgeInsets nudgeInset = EdgeInsets.fromLTRB(12, 10, 10, 10);

  /// A nudge's mark across.
  static const double nudgeMark = 28;

  /// A nudge's mark's glyph.
  static const double nudgeMarkGlyph = 16;

  /// The gap between a nudge's mark and its words.
  static const double nudgeGap = 12;

  /// The gap between the quick amounts, three across.
  static const double quickAmountsGap = 8;

  /// A quick amount's corners.
  static const double quickAmountRadius = 12;

  /// A quick amount's room inside.
  static const EdgeInsets quickAmountInset = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 6,
  );

  /// The gap between a quick amount's lines.
  static const double quickAmountGap = 4;

  /// A suggestion's corners.
  static const double suggestRadius = 14;

  /// A suggestion's room inside.
  static const double suggestInset = 12;

  /// A suggestion's mark across.
  static const double suggestMark = 36;

  /// A suggestion's mark's corners.
  static const double suggestMarkRadius = 11;

  /// A suggestion's mark's glyph.
  static const double suggestMarkGlyph = 18;

  /// The gap between a suggestion's mark and its words.
  static const double suggestGap = 12;

  /// A browse card's corners.
  static const double browseRadius = 12;

  /// A browse card's room inside.
  static const double browseInset = 10;

  /// The gap between a browse card's token and its words.
  static const double browseGap = 10;

  /// The gap between browse cards, two across.
  static const double browseCardsGap = 8;

  /// The month switch's room inside.
  static const double monthSwitchInset = 2;

  /// The gap between the month switch's parts.
  static const double monthSwitchGap = 4;

  /// The month switch's arrow's round across.
  static const double monthArrow = 32;

  /// The month switch's arrow's glyph.
  static const double monthArrowGlyph = 16;

  /// The month switch's month's height.
  static const double monthHeight = 32;

  /// The chevron beside the month switch's month.
  static const double monthGlyph = 14;

  /// The gap between the month switch's chevron and its word.
  static const double monthGap = 4;

  /// How far in the month switch's month stands on the desktop.
  static const double monthInsetWide = 8;

  /// How far in the earlier month's word stands.
  static const double monthPrevInset = 4;

  /// The gap between the spending head's lines.
  static const double monthHeadGap = 8;

  /// The gap between the spending head and the track.
  static const double monthHeadBottom = 16;

  /// The room over the spending foot.
  static const double monthFootTop = 14;

  /// The room under the spending foot.
  static const double monthFootBottom = 16;

  /// The gap between the spending foot's parts.
  static const double monthFootGap = 8;

  /// The gap between the columns of the desktop's spending grid.
  static const double spentColumnGap = 48;

  /// The gap between the rows of the desktop's spending grid.
  static const double spentRowGap = 24;

  /// The gap between an insight's parts.
  static const double insightGap = 12;

  /// The glyph of an insight's kind.
  static const double insightKindGlyph = 16;

  /// The gap between an insight kind's glyph and its word.
  static const double insightKindGap = 6;

  /// The gap between an insight's visits.
  static const double visitsGap = 6;

  /// The gap between the parts of money in against out.
  static const double flowGap = 14;

  /// The gap between the two figures of money in against out.
  static const double flowFiguresGap = 16;

  /// The gap between a flow figure's lines.
  static const double flowFigureGap = 8;

  /// The gap between money in against out and its scale.
  static const double flowScaleGap = 8;

  /// The gap between the two sides of the flow's note.
  static const double flowNoteGap = 12;

  /// The gap between an account's split lines.
  static const double splitGap = 14;

  /// The gap between the parts of an account's split line.
  static const double splitLineGap = 8;

  /// The gap between the parts of an account split's head.
  static const double splitHeadGap = 10;

  // --- charts ---------------------------------------------------------------------

  /// The room between a chart and what is above it.
  static const double chartTop = 16;

  /// The gap between a chart and its month labels.
  static const double chartLabelsGap = 8;

  /// How far short of a chart's end its month labels' row stops on a phone.
  static const double chartLabelsEnd = 40;

  /// How far short of a chart's end its month labels' row stops on the desktop.
  static const double chartLabelsEndWide = 48;

  /// How far short of a chart's end its month labels' row stops with a gap, on
  /// a phone.
  static const double chartLabelsEndGap = 36;

  /// How far short of a chart's end its month labels' row stops with a gap, on
  /// the desktop.
  static const double chartLabelsEndGapWide = 40;

  /// The height of a chart's end labels' row; a y label's words are 12.
  static const double chartLabels = 16;

  /// How far in a mark's note stands.
  static const double chartNoteInset = 6;

  /// The gap between a mark's note and the mark over or under it.
  static const double chartNoteGap = 4;

  /// The gap between a mark's note and the mark at a line's end.
  static const double chartNoteEndGap = 10;

  /// The gap between a mark's note and a step it stands beside.
  static const double chartNoteStepInset = 8;

  /// The gap between a bar and its value over it.
  static const double chartBarValueGap = 6;

  /// A transaction's strip of days' height.
  static const double strip = 40;

  /// Where the strip's rule stands from its foot.
  static const double stripRuleBottom = 4;

  /// The strip's ticks' height.
  static const double stripTick = 5;

  /// A strip dot across.
  static const double stripDot = 8;

  /// This transaction's strip dot across.
  static const double stripDotThis = 10;

  /// The ring round this transaction's strip dot.
  static const double stripDotRing = 2.5;

  /// How far up the strip's dots stand.
  static const double stripDotBottom = 9;

  /// The gap between the strip's dots.
  static const double stripDotGap = 4;

  /// The strip's labels' height.
  static const double stripLabels = 14;

  /// The gap between the strip and its labels.
  static const double stripLabelsGap = 6;

  /// The gap between the figures in a line.
  static const double figuresGap = 24;

  /// The gap between a figure's lines in a line of figures.
  static const double figureLineGap = 6;

  /// The gap between the parts of a move's route.
  static const double routeGap = 12;

  /// The gap between a move's route and its words.
  static const double routeBottom = 8;

  /// The gap between the parts of a route's line.
  static const double routeLineGap = 6;

  /// The size of a route's beam, its corners 2.
  static const Size routeBeam = Size(36, 2);

  /// A route's glyph.
  static const double routeGlyph = 16;

  /// The done art across.
  static const double doneArt = 200;

  /// How far the done art is pulled up.
  static const double doneArtPullTop = 12;

  /// How far the done art is pulled down.
  static const double doneArtPullBottom = 4;

  /// The done art's check across.
  static const double doneCheck = 72;

  /// The done art's check's glyph.
  static const double doneCheckGlyph = 32;

  /// The ring round the done art's check.
  static const double doneCheckRing = 6;

  /// The gap between a change's parts.
  static const double changeGap = 10;

  /// The room over a change.
  static const double changeTop = 4;

  /// The room under a change, the next standing over it.
  static const double changeBottom = 14;

  /// The gap between a change's head's parts.
  static const double changeHeadGap = 12;

  /// The gap between a change's values.
  static const double changeValueGap = 4;

  // --- controls ----------------------------------------------------------------------

  /// The search field's height.
  static const double search = 44;

  /// The search field's room at its sides.
  static const double searchInset = 16;

  /// The gap between the search field's glyph and its words.
  static const double searchGap = 10;

  /// The search field's glyph.
  static const double searchGlyph = 18;

  /// The round across of the search field's clear, shown once there is text.
  static const double searchClear = 28;

  /// The search field's clear's glyph.
  static const double searchClearGlyph = 14;

  /// How far the search field's clear is pulled into its end.
  static const double searchClearPull = 6;

  /// A filter chip's height.
  static const double filterChip = 32;

  /// A filter chip's room at its sides.
  static const double filterChipInset = 10;

  /// The gap between filter chips.
  static const double filterChipGap = 4;

  /// A goal card's "of" words stand 1 over the figure's foot: their 16.8
  /// line sits a pixel lower than the figure's, so the lift sets the two on
  /// one baseline. Optical.
  static const double goalCardFigureNudge = 1;

  /// A timeline's dot stands 7 down its entry: its middle on the middle of
  /// the entry's first line (a 20 line less a dot of 6, halved).
  static const double timelineDotTop = 7;

  /// A count badge's words stand 4 in from its ends: "9+" in an 18-tall
  /// badge keeps a round-ended pill with its words centred. Optical.
  static const double badgeInset = 4;

  /// The colour picker's knob wears a 3-wide rim of the glass's plane, as
  /// Frosted's swatch ring does.
  static const double colorKnobRim = 3;

  /// A month's row in the date picker: 44 tall, so six rows (a month that
  /// spans them) and a short month keep one card height.
  static const double pickerDayRow = 44;

  /// How far past a scrolling row's line its viewport stands (a tab strip,
  /// the filter chips, a page's own list): the chosen plate's lift (4 down,
  /// a blur of 12, spread -4) fades out about 15 under the plate, and a focus
  /// ring stands 4 out, so a row scrolled within its line clips only what
  /// scrolls away, never a shadow, a glow or a ring.
  static const double stripReach = 16;

  /// The gap between a field's label and its well.
  static const double fieldLabelGap = 8;

  /// A field's well's height.
  static const double field = 48;

  /// A field's well's room at its sides.
  static const double fieldInset = 14;

  /// A field's well's corners.
  static const double fieldRadius = 12;

  /// The gap between two fields in a line.
  static const double fieldsGap = 12;

  /// The gap between a form's fields, its tile's head standing as far over
  /// them.
  static const double formGap = 16;

  /// An amount well's height.
  static const double amountWell = 64;

  /// The room over an amount well's figure.
  static const double amountWellTop = 12;

  /// An amount well's room at its sides.
  static const double amountWellInset = 16;

  /// An amount well's corners.
  static const double amountWellRadius = 14;

  /// An amount well's `$`.
  static const double amountWellCurrency = 16;

  /// How far an amount well's `$` stands down.
  static const double amountWellCurrencyDrop = 6;

  /// The gap between an amount well's `$` and its figure.
  static const double amountWellGap = 2;

  /// An amount well's figure's height.
  static const double amountWellFigure = 40;

  /// A small amount well's height.
  static const double amountWellSmall = 48;

  /// A small amount well's room at its sides.
  static const double amountWellSmallInset = 14;

  /// A small amount well's corners.
  static const double amountWellSmallRadius = 12;

  /// A picker's least height.
  static const double picker = 60;

  /// A picker's room inside.
  static const EdgeInsets pickerInset = EdgeInsets.fromLTRB(10, 10, 14, 10);

  /// A picker's corners.
  static const double pickerRadius = 14;

  /// The gap between a picker's parts.
  static const double pickerGap = 12;

  /// A picker's chevron.
  static const double pickerGlyph = 16;

  /// The round across of the swap between two pickers.
  static const double swap = 32;

  /// The swap's glyph.
  static const double swapGlyph = 16;

  /// The line the swap stands on.
  static const double swapLine = 12;

  /// How far the swap is pulled into both pickers.
  static const double swapPull = 14;

  /// An icon picker's well's height.
  static const double iconWell = 44;

  /// An icon picker's well's corners.
  static const double iconWellRadius = 12;

  /// The gap between an icon picker's wells.
  static const double iconWellGap = 8;

  /// The glyph in an icon picker's well.
  static const double iconWellGlyph = 18;

  /// How many wells stand to an icon picker's row.
  static const int iconWellsPerRow = 6;

  /// The stepper's round buttons across.
  static const double stepper = 48;

  /// The gap between the stepper's buttons and the well.
  static const double stepperGap = 12;

  /// How far the stepper's note is pulled up under it.
  static const double stepperNotePull = 8;

  /// A settings row's least height; an off row stands at 0.45.
  static const double settingRow = 52;

  /// A settings row's room over and under.
  static const double settingInset = 8;

  /// The gap between a settings row's parts.
  static const double settingGap = 12;

  /// The gap between a settings row's lines.
  static const double settingLineGap = 2;

  /// A settings row's chevron.
  static const double settingGlyph = 16;

  /// The gap between a settings tile's head and its rows.
  static const double settingsHeadGap = 4;

  /// A settings row that is off: [disabledOpacity], the one share.
  static const double settingOffOpacity = disabledOpacity;

  /// The toggle's track's width; off to use it stands at [disabledOpacity], as
  /// every part does.
  static const double toggleWidth = 44;

  /// The toggle's track's height.
  static const double toggleHeight = 26;

  /// The room between the toggle's knob and its track.
  static const double toggleInset = 2;

  /// The toggle's knob across.
  static const double toggleKnob = 22;

  /// A toggle that is off to use: [disabledOpacity], the one share.
  static const double toggleDisabledOpacity = disabledOpacity;

  /// The gap between people.
  static const double peopleGap = 8;

  /// The gap between a person's pearl and the name.
  static const double personGap = 8;

  /// The opacity of a pearl not chosen; its name keeps its ink.
  static const double personDimOpacity = 0.55;

  /// The white ring round a chosen person's pearl.
  static const double personRingInner = 2;

  /// The reach of the ink ring past a chosen person's white ring.
  static const double personRingOuter = 3.5;

  // --- states --------------------------------------------------------------------

  /// An empty state's room on a phone.
  static const EdgeInsets emptyInset = EdgeInsets.fromLTRB(20, 24, 20, 24);

  /// An empty state's room on the desktop.
  static const EdgeInsets emptyInsetWide = EdgeInsets.fromLTRB(32, 40, 32, 44);

  /// The gap between an empty state's parts on a phone.
  static const double emptyGap = 10;

  /// The gap between an empty state's parts on the desktop.
  static const double emptyGapWide = 12;

  /// The size of an empty state's art on a phone.
  static const Size emptyArt = Size(220, 120);

  /// The size of an empty state's art on the desktop.
  static const Size emptyArtWide = Size(330, 180);

  /// The room under an empty state's art on a phone.
  static const double emptyArtGap = 6;

  /// The room under an empty state's art on the desktop.
  static const double emptyArtGapWide = 8;

  /// The widest an empty state's words stand on a phone.
  static const double emptyWordsWidth = 300;

  /// The widest an empty state's words stand on the desktop.
  static const double emptyWordsWidthWide = 420;

  /// The room under an empty state's words.
  static const double emptyWordsGap = 10;

  /// The loading state's ring across.
  static const double loadingRing = 40;

  /// The loading state's ring's stroke.
  static const double loadingStroke = 2;

  /// The error state's mark across.
  static const double stateMark = 56;

  /// The error state's mark's glyph.
  static const double stateMarkGlyph = 24;

  // --- the shared vocabulary's parts ---------------------------------------------
  //
  // The sizes of the parts every look carries beside the source's own (a
  // check, a slider, tabs, a form's rows, a composer, a dialog, an action
  // bar, a swipe, a week, a stack of avatars); each is DERIVED from the
  // source's language of 4 point steps, its hairlines and its pills.

  /// The completion check's disc across, the option's.
  static const double check = 24;

  /// The completion check's ring's width.
  static const double checkRing = 1.5;

  /// The completion check's tick.
  static const double checkGlyph = 14;

  /// The slider's track's height, the bar's.
  static const double sliderTrack = 6;

  /// The slider's knob across, the toggle's.
  static const double sliderThumb = 22;

  /// The slider's height to be reached.
  static const double sliderHeight = 44;

  /// A stepped slider's bead across.
  static const double sliderBead = 4;

  /// A tab's height in a line of tabs, the chosen one on the lit pill.
  static const double tabHeight = 40;

  /// A tab's room at each side of its word, the nav link's.
  static const double tabInset = 14;

  /// A form row's least height, the settings row's.
  static const double formRow = 52;

  /// A form row's room over and under.
  static const double formRowInset = 8;

  /// The gap between a form row's parts.
  static const double formRowGap = 12;

  /// A form row's control under its words, when large text leaves it no
  /// room beside them: as far below them as a field stands below its label.
  static const double formRowUnder = 8;

  /// The round a form row's leading glyph stands on, across.
  static const double formLeading = 32;

  /// The gap between groups of rows.
  static const double rowGroupGap = 10;

  /// The action bar's room at its sides.
  static const double actionBarSide = 16;

  /// The room over the action bar's act.
  static const double actionBarTop = 12;

  /// The gap between the action bar's summary and its act.
  static const double actionBarGap = 12;

  /// The width under which the action bar's summary stacks over its act.
  static const double actionBarStackWidth = 320;

  /// The text scale from which the action bar's summary stacks over its act;
  /// the host stops the scale at 1.3.
  static const double actionBarStackScale = 1.2;

  /// The composer's line height, the well's.
  static const double composer = 48;

  /// The room round the composer's parts.
  static const double composerInset = 4;

  /// The room over and under the composer's text.
  static const double composerText = 10;

  /// The widest the dialog stands on a phone.
  static const double dialogWidth = 320;

  /// The dialog's least room from the screen's edge.
  static const double dialogEdge = 24;

  /// The gap between the dialog's head and its words, the sheet's own insets
  /// round them.
  static const double dialogWordsGap = 24;

  /// The gap between the dialog's words and its acts.
  static const double dialogActsGap = 20;

  /// The counter rolls to a new value over 700 milliseconds.
  static const Duration counterRoll = Duration(milliseconds: 700);

  /// An avatar across in a stack of avatars.
  static const double avatarStack = 32;

  /// The ring of the canvas round each avatar in a stack.
  static const double avatarStackRing = 2;

  /// How much of the last avatar in a stack the next one covers.
  static const double avatarStackOverlap = 0.28;

  /// A swipe action's block's width.
  static const double swipeBlock = 84;

  /// The gap before a swipe action's block.
  static const double swipeGap = 8;

  /// The share of the row's width a drag goes past to do the first swipe
  /// action.
  static const double swipeFull = 0.65;

  /// A day of the week strip: a bead 36 across (the mark's).
  static const double weekBead = 36;

  /// A lead's header room: a cover running up under a header keeps 56
  /// clear under the status bar for it.
  static const double heroHeaderRoom = 56;

  /// A page head: at least 40 tall (the bar's control).
  static const double headMinHeight = 40;

  // --- focus ---------------------------------------------------------------------

  /// The gap between the keyboard focus ring and the control, filled with the
  /// page's ground so the ring reads on a face filled in the ink too.
  static const double focusRingGap = 2;

  /// The keyboard focus ring's width (the theme's heavy stroke), in the ink.
  static const double focusRingWidth = 2;

  /// The one outline width.
  static const double outline = 1;
}
