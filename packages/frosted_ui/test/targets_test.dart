// Frosted's small controls stand in their touch targets, as Material pads
// its own (ui_core's TapTargetPadding): a 40 bell, a 24 check and a 44 × 26
// switch each lay out at 48 under a finger, the face at its own size in the
// middle, so the box a screen reader outlines, the area a tap reaches and
// the layout are one; a press in the margin reaches the control, and
// ui_core's tap check and Flutter's tap-target guidelines both pass.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

void main() {
  testWidgets('the bell, a check and a switch stand in their touch targets, '
      'their faces at their own size', (t) async {
    final semantics = t.ensureSemantics();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var rung = 0;
    final checks = <bool?>[];
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? page) =>
            FrostedHost(brightness: Brightness.light, child: page!),
        home: Center(
          key: const Key('page'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FrostedBell(unread: 1, onPressed: () => rung++),
              FrostedCheckbox(
                value: false,
                label: 'Stretch',
                onChanged: checks.add,
              ),
              FrostedSwitch(value: false, label: 'Alerts', onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    const target = Size.square(FrostedBreakpoints.touchHitTarget);
    expect(t.getSize(find.byType(FrostedBell)), target);
    expect(t.getSize(find.byType(FrostedCheckbox)), target);
    expect(t.getSize(find.byType(FrostedSwitch)), target);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    final report = const DesignTapTargetCheck(look: 'Frosted')
        .check(t.element(find.byKey(const Key('page'))));
    expect(report.problems, isEmpty);
    // Edge to edge, a press 2 inside a target's edge reaches that control
    // and never the one beside it.
    final bell = t.getRect(find.byType(FrostedBell));
    await t.tapAt(bell.centerRight - const Offset(2, 0));
    await t.pump();
    expect(rung, 1);
    expect(checks, isEmpty);
    final check = t.getRect(find.byType(FrostedCheckbox));
    await t.tapAt(check.centerLeft + const Offset(2, 0));
    await t.pump();
    expect(checks, [true]);
    expect(rung, 1);
    semantics.dispose();
  });
  // ui_core reads the field's words on a tag input's entry, on one node
  // round the entry's box: that box is its lane, a touch target tall, and
  // the entry names nothing itself, so the field's name is read once.
  testWidgets("a multi-select's entry beside its tags is one node a touch "
      'target tall, its field named once', (t) async {
    final semantics = t.ensureSemantics();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? page) =>
            FrostedHost(brightness: Brightness.light, child: page!),
        home: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FrostedMultiSelect<String>(
              labelText: 'Tags',
              options: const ['Design', 'Research', 'Review'],
              values: const ['Design', 'Review'],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    final entry = t.getSemantics(find.byType(EditableText));
    expect(entry.getSemanticsData().label, 'Tags');
    expect(entry.rect.height, FrostedBreakpoints.touchHitTarget);
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });
}
