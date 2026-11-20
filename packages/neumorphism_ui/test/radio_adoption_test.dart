// NeumorphicRadioGroup keeps ui_core's keyboard contract for a radio group in both text directions: one Tab stop on the
// chosen option (or the first enabled one), arrows that choose as they move, wrap at the ends and skip an option out of
// use, Left advancing in right-to-left text, and a second Tab leaving the group. The gallery's selectable rooms, rows of
// a data table, read as checkable rows rather than buttons.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart';

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  for (final direction in TextDirection.values) {
    // C chosen, nothing chosen, and the disabled B chosen.
    for (final initial in <String?>['C', null, 'B']) {
      testWidgets('radio group ${direction.name}, chosen $initial', (
        tester,
      ) async {
        final before = FocusNode();
        addTearDown(before.dispose);
        String? chosen = initial;
        final controls = StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(focusNode: before, child: const Text('Before')),
              SizedBox(
                width: 310,
                key: const ValueKey('radios'),
                child: NeumorphicRadioGroup<String>(
                  label: 'Plan',
                  options: const [
                    NeumorphicRadio('A', 'A'),
                    NeumorphicRadio('B', 'B', enabled: false),
                    NeumorphicRadio('C', 'C'),
                    NeumorphicRadio('D', 'D'),
                  ],
                  value: chosen,
                  onChanged: (next) => setState(() => chosen = next),
                ),
              ),
              const Focus(child: Text('After')),
            ],
          ),
        );
        await tester.pumpWidget(neumorphicApp(controls, direction: direction));
        await tester.pumpAndSettle();
        (await const DesignRadioGroupCheck(look: 'Neumorphism').check(
          tester.element(find.byKey(const ValueKey('radios'))),
          before: before,
          sendKeyEvent: tester.sendKeyEvent,
          pump: tester.pump,
        )).verify();
      });
    }
  }

  testWidgets('the selectable rooms read as checkable rows, not buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 6000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp(initialPage: 'collections'));
      await settle(tester);
      // The table's first page; the tree of rooms below it names some of the same rooms.
      final table = find.byWidgetPredicate((w) => w is NeumorphicDataTable);
      for (final room in ['Attic', 'Bedroom', 'Cellar', 'Hall', 'Kitchen']) {
        final row = find.descendant(
          of: table,
          matching: find.bySemanticsLabel(RegExp('^$room\n')),
        );
        expect(row, findsOneWidget, reason: room);
        expect(
          tester.getSemantics(row),
          isSemantics(
            hasCheckedState: true,
            isButton: false,
            hasTapAction: true,
          ),
          reason: room,
        );
      }
    } finally {
      semantics.dispose();
    }
  });
}
