// The face of a control: the box it paints, inside the room its tap target
// lays out round it (ui_core's DesignTapTarget, or the band a compact face of
// several controls stands in). A test that measures what a control draws
// measures this; one that measures its layout measures the control.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// The face of the first tap target, or tap band, at or under [control]; for
/// a control that lays out its own band round its face (a segmented
/// control's track), the first box it decorates.
Rect faceOf(WidgetTester tester, Finder control) {
  final rooms = find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (w) =>
          w is DesignTapTarget || w.runtimeType.toString() == 'MinimalTapBand',
    ),
    matchRoot: true,
  );
  if (rooms.evaluate().isEmpty) {
    return tester.getRect(
      find.descendant(of: control, matching: find.byType(DecoratedBox)).first,
    );
  }
  final room = rooms.first;
  RenderBox? face;
  tester
      .renderObject<RenderBox>(room)
      .visitChildren((c) => face = c as RenderBox);
  return face!.localToGlobal(Offset.zero) & face!.size;
}
