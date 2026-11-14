// Frosted's small controls keep their drawn size in layout and still give a
// screen reader, and Flutter's tap-target guidelines, the whole touch target:
// the node spans 48 under a finger round a 40 bell, a 24 check and a switch,
// and a press in that margin reaches the control.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

void main() {
  testWidgets('the bell, a check and a switch meet the tap-target guidelines '
      'at their own size', (t) async {
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 32,
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
    expect(t.getSize(find.byType(FrostedBell)), const Size.square(40));
    expect(t.getSize(find.byType(FrostedCheckbox)), const Size.square(24));
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    final bell = t.getRect(find.byType(FrostedBell));
    await t.tapAt(bell.centerRight + const Offset(3, 0));
    await t.pump();
    expect(rung, 1);
    final check = t.getRect(find.byType(FrostedCheckbox));
    await t.tapAt(check.centerLeft - const Offset(10, 0));
    await t.pump();
    expect(checks, [true]);
    semantics.dispose();
  });
}
