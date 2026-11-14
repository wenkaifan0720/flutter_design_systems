/// Minimal's chrome geometry and motion, in one place: the bars, the
/// rows, the controls, the sheet card and the transitions, as the build spec
/// (docs/architecture/design-systems-bench-tactile.md §6) and its reference
/// mockups state them.
///
/// This is the system's GRAMMAR — positions, sizes, bands and timings.
/// Colour, type faces and the corner language of ordinary surfaces are the
/// theme's. Nothing here is a token a theme may override; the components
/// that draw chrome read these, and pages never need to.
abstract final class MinimalChromeMetrics {
  // ── Page ──

  /// The screen gutter: the side inset of a page's type and of every bar.
  static const double gutter = 18;

  /// The largest text scale a Minimal surface lays out at. [MinimalHost]
  /// clamps the ambient scaler here: a 44 px row holds its 14 px label at
  /// 1.3× on two lines' worth of leading, and nothing past it.
  static const double maxTextScale = 1.3;

  /// Width of the keyboard focus ring every focusable control draws, outside
  /// its own edge.
  static const double focusRing = 2;

  // ── Top bar ──

  /// The top bar's band, its 1 px bottom hairline included.
  static const double barHeight = 52;

  /// The bar's leading inset (the title's edge) and its trailing inset (the
  /// last action's edge): both the page's gutter, so the bar's first and
  /// last edges stand on the body's keylines.
  static const double barInsetStart = gutter;

  /// The bar's trailing inset, to the last action's bordered edge.
  static const double barInsetEnd = gutter;

  /// A bar icon button: a 32 px bordered square.
  static const double barControl = 32;

  /// Air between two bar actions.
  static const double barActionGap = 6;

  /// Air between the title and its mono meta, and between the back button
  /// and a pushed page's breadcrumb.
  static const double barTitleGap = 8;

  /// Air between a pushed page's back button and its breadcrumb.
  static const double barCrumbGap = 8;

  /// The root title's size (the face and weight are the theme's h2).
  static const double barTitle = 17;

  /// A sheet's header band inside the card: tall enough that the close
  /// keeps its whole 44 px touch target.
  static const double sheetBar = 44;

  /// The sheet header's context pill: its side padding and its corners.
  static const double sheetPillPad = 7;

  /// The sheet header's context pill's corner radius.
  static const double pillRadius = 6;

  // ── Tab bar ──

  /// The docked tab bar's band above the bottom safe area, its 1 px top
  /// hairline included.
  static const double tabHeight = 56;

  /// A tab's glyph over its label.
  static const double tabIcon = 20;

  /// A tab label's size: 11, the least any words a person reads take.
  static const double tabLabel = 11;

  /// Air between a tab's glyph and its label.
  static const double tabLabelGap = 3;

  /// A tab label's line height, as a multiple of [tabLabel].
  static const double tabLabelLeading = 1.2;

  /// The shell action's square, and the width of the trailing slot it
  /// stands centred in.
  static const double tabAction = 36;

  /// The width of the trailing slot the shell action stands centred in.
  static const double tabActionSlot = 64;

  /// The shell's accessory strip above the bar, its top hairline included.
  static const double accessoryHeight = 44;

  // ── Rows and controls ──

  /// A list row, and the dense register's.
  static const double row = 44;

  /// A list row in the dense register.
  static const double rowCompact = 36;

  /// Control heights: a button or an input at md, sm and lg.
  static const double control = 32;

  /// A small button's or input's height.
  static const double controlSm = 28;

  /// A large button's or input's height.
  static const double controlLg = 40;

  /// A button's side padding at sm (md takes 12, lg 16 off the spacing
  /// scale).
  static const double buttonPadSm = 10;

  /// Air between a control's glyph and its label: a button, a pill.
  static const double iconGap = 6;

  /// Air between a row's glyph, its words and its accessories: a list row,
  /// a picker or a form row.
  static const double rowIconGap = 10;

  /// A boxed field's side inset: an input's, a search field's.
  static const double fieldInset = 10;

  // ── Pills ──

  /// A 28 px property or filter pill's corners — a step rounder than the
  /// sheet's context pill ([pillRadius]).
  static const double propertyPillRadius = 7;

  /// A filter pill's side padding around its label and count.
  static const double filterPad = 10;

  // ── Action bar ──

  /// The floating action bar card's vertical padding around a 40 px
  /// action.
  static const double actionBarPad = 10;

  /// The text scale past which the action bar stacks its summary over the
  /// action instead of squeezing both onto one line.
  static const double actionBarStackScale = 1.2;

  // ── Sheet ──

  /// The modal card's inset from the screen's sides and bottom edge.
  static const double sheetInset = 10;

  /// The card's own padding around its header, content and footer.
  static const double sheetPad = 14;

  /// The least space a raised card leaves above itself.
  static const double sheetTopGap = 24;

  // ── Floating and transient chrome ──

  /// The allowance a page-owned `floating:` slot reserves above the bottom
  /// safe area: a 40 px control on 12 px of air, with air above it.
  static const double floatingAllowance = 64;

  /// How far a floating control and a toast stand above whatever holds the
  /// bottom edge.
  static const double floatingGap = 12;

  /// A toast's message padding above and below, and its action's.
  static const double toastPad = 10;

  /// A toast action's padding above and below its label.
  static const double toastActionPad = 6;

  // ── Render states ──

  /// The widest a render state's message runs before it wraps.
  static const double stateMeasure = 280;

  // ── Motion ──

  /// A push: the incoming page fades in while travelling [pushSlide] from
  /// the trailing side; the page beneath does not move.
  static const Duration push = Duration(milliseconds: 160);

  /// A pop: the page leaving fades out the way it came.
  static const Duration pop = Duration(milliseconds: 120);

  /// How far a pushed page travels as it fades in.
  static const double pushSlide = 8;

  /// A peer replacement: a plain cross-fade.
  static const Duration fadeIn = Duration(milliseconds: 120);

  /// A peer replacement's outgoing fade.
  static const Duration fadeOut = Duration(milliseconds: 100);

  /// A sheet rising with its scrim, and leaving.
  static const Duration sheetIn = Duration(milliseconds: 180);

  /// A sheet leaving with its scrim.
  static const Duration sheetOut = Duration(milliseconds: 120);

  /// The tab bar yielding to pushed depth.
  static const Duration barExit = Duration(milliseconds: 120);

  /// A stepper held down: the pause before it repeats, and the repeat.
  static const Duration holdDelay = Duration(milliseconds: 400);

  /// A held stepper's repeat, once it starts repeating.
  static const Duration holdRepeat = Duration(milliseconds: 90);

  /// How long a toast stands, without and with its one action.
  static const Duration toast = Duration(milliseconds: 2400);

  /// How long a toast with an action stands: long enough to reach it.
  static const Duration toastWithAction = Duration(milliseconds: 4200);
}
