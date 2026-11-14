// Fluent 2's chrome metrics: the sizes of its bars, panes, sheets and parts,
// read from Fluent 2's React styles (@fluentui/react-* 9.x, the
// `use*Styles.styles` files) where Fluent's web draws the part, and from
// Fluent 2's mobile guidance where only a phone has it (the tab bar, the
// top bar, the bottom sheet's handle). A constant Fluent 2 derives says so.

/// The bars, panes and parts of Fluent 2's chrome, in logical pixels.
abstract final class Fluent2ChromeMetrics {
  // --- the page ---------------------------------------------------------------

  /// The page gutter: 16 on a phone, 24 on the desktop.
  static const double gutter = 16;

  /// The page gutter on the desktop.
  static const double gutterWide = 24;

  /// The room under a page's last part: 24 on a phone, 40 on the desktop.
  static const double pageBottom = 24;

  /// The room under a desktop page's last part.
  static const double pageBottomWide = 40;

  /// The widest a desktop page's column runs (DERIVED: a reading measure
  /// for a single column of cards and forms).
  static const double pageMaxWidth = 1120;

  // --- the top bar ------------------------------------------------------------

  /// A phone top bar: 56 tall (Fluent 2 Android's app bar), its parts 4 in
  /// from the gutter's edge (the back's 40 hit box carries its own room),
  /// 8 between its controls.
  static const double barHeight = 56;

  /// The room between a phone top bar's controls.
  static const double barGap = 8;

  /// A bar's command: Fluent's medium icon-only subtle button, 32 square
  /// with its glyph 20, standing in a 40 hit box on a phone.
  static const double barControl = 40;

  /// The desktop bar: 28 over its words and 16 under them, in the page.
  static const double barTopWide = 28;

  /// The room under the desktop bar's words.
  static const double barBottomWide = 16;

  /// The caption over a desktop title, 4 above it.
  static const double captionGap = 4;

  /// The crumb over a desktop detail's title: its glyph 16, 4 from its
  /// word; the title 4 under it.
  static const double crumbGlyph = 16;

  /// The room between the crumb's glyph and its word, and under the crumb.
  static const double crumbGap = 4;

  // --- the tab bar ------------------------------------------------------------

  /// The phone tab bar: 56 over the device inset, its glyph 24 (Fluent's
  /// mobile tab bar), 2 over its word, the bar's top a hairline.
  static const double tabBarHeight = 56;

  /// A phone tab's glyph size.
  static const double tabGlyph = 24;

  /// The room between a phone tab's glyph and its word.
  static const double tabGap = 2;

  /// The least room each side of a phone tab's word, within its tab: the
  /// end tabs' words stand at least this far from the screen's edges.
  static const double tabLabelSide = 8;

  /// The selected tab's mark: a pill 4 tall and 16 wide (DERIVED from
  /// Fluent's nav indicator, 4 by 20, laid along the bar's top edge).
  static const double tabMarkHeight = 3;

  /// The selected tab's mark, its width.
  static const double tabMarkWidth = 20;

  /// The shell's act on a phone: Fluent 2 mobile's floating action button,
  /// 56 across with its glyph 24, 16 from the screen's end and over the
  /// tab bar; with a word it is a pill 48 tall (the extended button).
  static const double fab = 56;

  /// The height of the floating action button with a word (the extended pill).
  static const double fabExtended = 48;

  /// The floating action button's glyph size.
  static const double fabGlyph = 24;

  /// The floating action button's room from the screen's end.
  static const double fabInset = 16;

  /// What docks over the tab bar stands 8 over it.
  static const double accessoryGap = 8;

  // --- the nav pane -----------------------------------------------------------

  /// The desktop nav pane (`NavDrawer`): 260 wide, collapsed to a 48 rail
  /// by its hamburger; its items 40 tall (10 over and under a 20 line),
  /// 10 in at their start and 8 at their end, their glyph 20 and 16
  /// before the word, 4 corners; the selection indicator 4 by 20 at 16
  /// before the item's start, in the brand.
  static const double paneWidth = 260;

  /// The nav pane's width collapsed to a rail.
  static const double paneRail = 48;

  /// The room round the nav pane's items.
  static const double paneInset = 4;

  /// A nav pane item's height.
  static const double paneItem = 40;

  /// The room at a nav pane item's start.
  static const double paneItemStart = 10;

  /// The room at a nav pane item's end.
  static const double paneItemEnd = 8;

  /// The room between a nav pane item's glyph and its word.
  static const double paneItemGap = 16;

  /// The nav pane's selection indicator, its width.
  static const double paneIndicatorWidth = 4;

  /// The nav pane's selection indicator, its height.
  static const double paneIndicatorHeight = 20;

  /// The pane's head: the hamburger (a 40 square subtle button) and the
  /// app's name, 48 tall; the content layer's top-start corner 8, the
  /// layer standing 0 from the pane and 0 from the window's top.
  static const double paneHead = 48;

  /// The content layer's top-start corner beside the nav pane.
  static const double layerRadius = 8;

  // --- sheets and dialogs -----------------------------------------------------

  /// A phone's bottom sheet: its top corners 8, its handle 36 by 4 at 8
  /// under its top, its parts 16 in; it stands at most 90% of the screen.
  static const double sheetRadius = 8;

  /// A bottom sheet's handle, its width.
  static const double handleWidth = 36;

  /// A bottom sheet's handle, its height.
  static const double handleHeight = 4;

  /// The room over a bottom sheet's handle.
  static const double handleTop = 8;

  /// The room at a bottom sheet's sides.
  static const double sheetSide = 16;

  /// The room at a bottom sheet's top.
  static const double sheetTop = 8;

  /// The room at a bottom sheet's foot.
  static const double sheetBottom = 16;

  /// The most of the screen's height a bottom sheet takes.
  static const double sheetMaxFraction = 0.9;

  /// A sheet's head: at least 48 tall; its body 8 under it, its foot 16
  /// under that.
  static const double sheetHead = 48;

  /// The room between a sheet's head and its body.
  static const double sheetBodyGap = 8;

  /// The room between a sheet's body and its foot.
  static const double sheetFootGap = 16;

  /// The desktop dialog (`DialogSurface`): at most 600 wide, 24 round its
  /// parts, its corners 8, 48 from the window's edges at most; its title
  /// 8 over the body, its actions 24 under it, 8 apart.
  static const double dialogWidth = 600;

  /// The room round a dialog's parts.
  static const double dialogPadding = 24;

  /// The most room a dialog keeps from the window's edges.
  static const double dialogMargin = 48;

  /// The room between a dialog's title and its body.
  static const double dialogGap = 8;

  /// The room over a dialog's actions.
  static const double dialogActionsGap = 24;

  /// The desktop drawer (`OverlayDrawer`, size medium): 592 wide at the
  /// window's end, 24 round its header and body.
  static const double drawerWidth = 592;

  /// The room round a desktop drawer's header and body.
  static const double drawerPadding = 24;

  // --- toasts and menus -------------------------------------------------------

  /// A toast (`Toast`): 12 round its parts, 292 wide on the desktop (the
  /// phone's gutter to gutter), its corners 4, 16 above what stands at the
  /// foot; its glyph 16, 8 before its title.
  static const double toastPadding = 12;

  /// A toast's width on the desktop.
  static const double toastWidth = 292;

  /// The room under a toast, over what stands at the foot.
  static const double toastGap = 16;

  /// A toast's glyph size.
  static const double toastGlyph = 16;

  /// A menu (`MenuPopover`): 4 round its items, at least 138 and at most
  /// 300 wide, its corners 4; an item (`MenuItem`) at least 32 tall, 6
  /// round its parts, 4 between them (its glyph 20), its words and its
  /// secondary words each 2 in from their sides (`content`'s padding). On
  /// a phone an item stands at least 44 tall (the touch floor).
  static const double menuPadding = 4;

  /// The narrowest a menu stands.
  static const double menuMinWidth = 138;

  /// The widest a menu stands.
  static const double menuMaxWidth = 300;

  /// A menu item's least height under a pointer.
  static const double menuItem = 32;

  /// A menu item's least height under a finger.
  static const double menuItemTouch = 44;

  /// The room round a menu item's parts.
  static const double menuItemPadding = 6;

  /// The room between a menu item's parts.
  static const double menuItemGap = 4;

  /// The room at either side of a menu item's words.
  static const double menuItemWordsInset = 2;

  // --- states -----------------------------------------------------------------

  /// A state's glyph (48) 16 over its title, the words 4 under the title,
  /// the act 20 under the words; at most 360 wide.
  static const double stateGlyph = 48;

  /// The room between a state's glyph and its title.
  static const double stateGap = 16;

  /// The widest a state's words run.
  static const double stateWidth = 360;

  // --- the focus ring ---------------------------------------------------------

  /// Fluent's focus indicator: a 2 stroke in `strokeFocus2` on the
  /// control's own edge with a 1 stroke of `strokeFocus1` inside it.
  static const double focusOuter = 2;

  /// The focus indicator's inner stroke.
  static const double focusInner = 1;

  /// A hairline: Fluent's `strokeWidthThin`.
  static const double hairline = 1;
}
