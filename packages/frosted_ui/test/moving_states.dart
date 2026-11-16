// The moments between a look's states, held still so a test can capture
// them and check them: a press held halfway, a hover, a keyboard focus, a
// sheet halfway open, a carousel halfway through a swipe. A look is judged
// in these as much as at rest: a press that flashes a square ink before its
// round face fills, a focus ring cut by its row, a sheet whose shadow
// shows past its corners on the way up. Copy this file into your package's
// test/ folder beside world_checks.dart; it needs only flutter_test.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a test does at each moment: capture the screen (a golden), run a
/// check over it. [moment] names it in words, for a file name or a message:
/// `press held halfway`, `hover`, `focus`, `sheet halfway open`, `swipe
/// halfway`.
typedef MovingStateLook = Future<void> Function(String moment);

/// Presses [target] and holds it [halfway] into its press (half the look's
/// press move: its pressed fill, its sink, its ink spreading), runs [look],
/// then lets go and lets the release finish. A press inside a scroll view
/// shows only after a tap's 100 ms wait, which is added.
Future<void> atPressHalfway(
  WidgetTester tester,
  Finder target,
  MovingStateLook look, {
  Duration halfway = const Duration(milliseconds: 75),
}) async {
  final press = await tester.startGesture(tester.getCenter(target));
  // Down, then the tap's wait inside a scroll view, then half the move.
  await tester.pump();
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await tester.pump(kPressTimeout);
  }
  await tester.pump(halfway);
  await look('press held halfway');
  // Moved off before lifting, so the hold is not a tap that acts.
  await press.cancel();
  await _settle(tester);
}

/// Moves a mouse over [target], lets its hover move [halfway] and runs
/// [look], then lets it finish and runs [look] again, then moves the mouse
/// away and lets the hover go.
Future<void> atHover(
  WidgetTester tester,
  Finder target,
  MovingStateLook look, {
  Duration halfway = const Duration(milliseconds: 75),
}) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(target));
  await tester.pump();
  await tester.pump(halfway);
  await look('hover halfway');
  await _settle(tester);
  await look('hover');
  await mouse.moveTo(Offset.zero);
  await mouse.removePointer();
  await _settle(tester);
}

/// Moves the keyboard's focus to [target] with the Tab key, as a keyboard
/// user does (so the focus shows its highlight), runs [look] halfway into
/// the focus's move and once it rests, then moves the focus off. Fails when
/// [maxTabs] presses never reach it: a control the keyboard cannot reach.
Future<void> atFocus(
  WidgetTester tester,
  Finder target,
  MovingStateLook look, {
  Duration halfway = const Duration(milliseconds: 75),
  int maxTabs = 64,
}) async {
  final element = tester.element(target);
  bool focused() {
    final at = FocusManager.instance.primaryFocus?.context;
    if (at == null) return false;
    if (identical(at, element)) return true;
    var within = false;
    at.visitAncestorElements((e) {
      within = identical(e, element);
      return !within;
    });
    if (within) return true;
    // Or the focus is a part of the target: a field's editable.
    var holds = false;
    element.visitChildElements((c) => holds = holds || _holds(c, at));
    return holds;
  }

  // The Tab key moves the focus within a scope that has it: an app's
  // route's, focused when it is pushed.
  final scope = FocusScope.of(element);
  if (!scope.hasFocus) {
    scope.requestFocus();
    await tester.pump();
  }
  var tabs = 0;
  while (!focused()) {
    expect(
      tabs,
      lessThan(maxTabs),
      reason: 'the Tab key reaches ${target.describeMatch(Plurality.one)}',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    tabs++;
  }
  await tester.pump(halfway);
  await look('focus halfway');
  await _settle(tester);
  await look('focus');
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester);
}

// Lets what moves come to rest: frames until none is asked for, or two
// seconds, so a page with a spinner that never stops still moves on. The
// first frame always runs: a focus change lands in a microtask, before it
// asks for one.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 120 && tester.binding.hasScheduledFrame; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

bool _holds(Element e, BuildContext at) {
  if (identical(e, at)) return true;
  var found = false;
  e.visitChildElements((c) => found = found || _holds(c, at));
  return found;
}

/// Opens a sheet with [open] (a tap on what opens it, or a call to the
/// look's show function, not awaited: its future ends when the sheet
/// closes), holds it [halfway] up its way in, runs [look], then lets it
/// finish opening. [halfway] is half the sheet's own move: its route's
/// transition, or its own controller's duration.
Future<void> atSheetHalfway(
  WidgetTester tester,
  void Function() open,
  MovingStateLook look, {
  Duration halfway = const Duration(milliseconds: 150),
}) async {
  open();
  // The route is pushed on this frame and starts to move on the next.
  await tester.pump();
  await tester.pump(halfway);
  await look('sheet halfway open');
  await _settle(tester);
}

/// Drags [carousel] half its own width towards its next item (towards its
/// start under right to left), holds it there, runs [look], then lets go
/// and lets it settle.
Future<void> atSwipeHalfway(
  WidgetTester tester,
  Finder carousel,
  MovingStateLook look, {
  double share = .5,
  Axis axis = Axis.horizontal,
}) async {
  final rect = tester.getRect(carousel);
  final rtl =
      Directionality.maybeOf(tester.element(carousel)) == TextDirection.rtl;
  final distance = (axis == Axis.horizontal ? rect.width : rect.height) * share;
  final step = axis == Axis.horizontal
      ? Offset(rtl ? distance : -distance, 0)
      : Offset(0, -distance);
  final drag = await tester.startGesture(rect.center);
  // In steps past the drag's slop, as a finger moves.
  for (var i = 1; i <= 8; i++) {
    await drag.moveBy(step / 8);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await look('swipe halfway');
  await drag.up();
  await _settle(tester);
}
