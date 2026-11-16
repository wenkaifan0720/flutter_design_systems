/// Tab and Shift+Tab in the example: [KitFocusActions].
library;

import 'package:flutter/widgets.dart';

/// Tab and Shift+Tab under [child] show the control they reach, and reach
/// the sections a page has not built yet.
///
/// Flutter's Tab only scrolls forward (the control it reaches is kept in
/// view at the end; Shift+Tab's at the start), so Tab from the rail or the
/// app bar into a page scrolled past its top left the focus above the
/// window. And a reference page builds its sections as they scroll into
/// view, so Tab went from the last control built to the rail, never
/// reaching the ones below the window.
///
/// The example's app stands under one, and so does each reference page:
/// a page's preview is an app of its own, whose Tab is its own.
class KitFocusActions extends StatelessWidget {
  /// Tab and Shift+Tab as above, under [child].
  const KitFocusActions({required this.child, super.key});

  /// The tree they move through.
  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      NextFocusIntent: _RevealingNextFocus(),
      PreviousFocusIntent: _RevealingPreviousFocus(),
    },
    child: child,
  );
}

/// Scrolls the focused control into view from whichever side it sits.
void _revealFocus() {
  final context = primaryFocus?.context;
  if (context == null) return;
  // The end, then the start: a control taller than the window shows its
  // start.
  Scrollable.ensureVisible(
    context,
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
  );
  Scrollable.ensureVisible(
    context,
    alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
  );
}

/// The outermost vertical scroll view around [context]: its page's.
ScrollableState? _pageScroll(BuildContext? context) {
  ScrollableState? page;
  var scrollable = context == null ? null : Scrollable.maybeOf(context);
  while (scrollable != null) {
    if (axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical) {
      page = scrollable;
    }
    scrollable = Scrollable.maybeOf(scrollable.context);
  }
  return page;
}

/// Whether [context] stands in [page].
bool _within(BuildContext? context, ScrollableState page) {
  var scrollable = context == null ? null : Scrollable.maybeOf(context);
  while (scrollable != null) {
    if (identical(scrollable, page)) return true;
    scrollable = Scrollable.maybeOf(scrollable.context);
  }
  return false;
}

/// Moves the focus on from [from] ([forward]) or back, then shows the
/// control it reaches. When the focus would leave a page with more to show
/// that way, the page scrolls on most of a window and the move is tried
/// again from [from], until the page has no more.
bool _traverse(FocusNode from, {required bool forward}) {
  final page = _pageScroll(from.context);
  final moved = forward ? from.nextFocus() : from.previousFocus();
  // The move lands in a microtask: land it now, to see where it went.
  FocusManager.instance.applyFocusChangesIfNeeded();
  if (page != null && page.mounted && !_within(primaryFocus?.context, page)) {
    final position = page.position;
    final more = forward ? position.extentAfter : position.extentBefore;
    if (more > 0) {
      from.requestFocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      final step = position.viewportDimension * .8;
      position.jumpTo(
        (position.pixels + (forward ? step : -step)).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (from.hasPrimaryFocus) _traverse(from, forward: forward);
      });
      return true;
    }
  }
  if (moved) _revealFocus();
  return moved;
}

/// Tab, through [_traverse].
class _RevealingNextFocus extends NextFocusAction {
  @override
  bool invoke(NextFocusIntent intent) =>
      _traverse(primaryFocus!, forward: true);
}

/// Shift+Tab, through [_traverse].
class _RevealingPreviousFocus extends PreviousFocusAction {
  @override
  bool invoke(PreviousFocusIntent intent) =>
      _traverse(primaryFocus!, forward: false);
}
