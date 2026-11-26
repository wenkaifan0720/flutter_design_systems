// Appliance's parts drawn at a finger's size take ui_core's touch floor, 40
// by 40, on every input (was Appliance's own 48 under a finger, and a
// slider's cap 44): a slider's cap, a reorderable row's grip and a sheet's
// grip. An app's RawTapTargetScope round its pages raises the floor there. A
// tag input's tags and a breadcrumb's places lay out in RawChipGroup; a run
// of tags is the field's row, never under the floor.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _floor48 = RawTapTargets(touch: Size.square(48));

Future<void> _show(
  WidgetTester tester,
  Widget part, {
  RawTapTargets? targets,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Appliance's theme declares the look's floors; an app raises them under
  // it, round its pages.
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Builder(
        builder: (context) {
          final body = Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(24), child: part),
          );
          return targets == null
              ? body
              : RawTapTargetScope(targets: targets, child: body);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);
  final floor = RawTapTargets.fallback.touch;

  for (final (name, targets, side) in [
    ('the touch floor', null, floor.width),
    ("an app's floor of 48", _floor48, 48.0),
  ]) {
    testWidgets(
      "a slider's cap takes $name, on every input",
      (tester) async {
        await _show(
          tester,
          SizedBox(
            width: 300,
            child: ApplianceSlider(value: 0.4, onChanged: (_) {}),
          ),
          targets: targets,
        );
        expect(tester.getSize(find.byType(RawValueHandle)).width, side);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );

    testWidgets("a reorderable row's grip takes $name", (tester) async {
      await _show(
        tester,
        SizedBox(
          width: 340,
          height: 300,
          child: ApplianceReorderableList<String>(
            items: const ['Kettle', 'Toaster'],
            labelOf: (item) => item,
            title: (item) => item,
            onReorder: (_, _) {},
          ),
        ),
        targets: targets,
      );
      final grip = find.byWidgetPredicate(
        (w) => w is MouseRegion && w.cursor == SystemMouseCursors.grab,
      );
      expect(tester.getSize(grip.first), Size(side, side));
    });

    testWidgets("a run of tags is the field's row, at least $name", (
      tester,
    ) async {
      await _show(
        tester,
        SizedBox(
          width: 340,
          child: ApplianceTagInput<String>(
            values: const ['Tea'],
            onChanged: (_) {},
          ),
        ),
        targets: targets,
      );
      final run = find
          .ancestor(of: find.text('Tea'), matching: find.byType(SizedBox))
          .first;
      final row = ApplianceMetrics.controlHeight - 2 * ApplianceSpacing.nudge;
      expect(tester.getSize(run).height, side > row ? side : row);
    });
  }

  testWidgets("a sheet's grip takes the touch floor", (tester) async {
    await _show(
      tester,
      Builder(
        builder: (context) => ApplianceButton(
          'Move',
          onPressed: () => showApplianceSheet<void>(
            context: context,
            builder: (context) => const ApplianceSheet(
              title: 'Move to a room',
              child: Text('Kitchen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    final grip = find.descendant(
      of: find.byType(RawBottomSheetDragHandle),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(grip.first), floor);
  });

  testWidgets("a tag input's tags lay out in a chip group", (tester) async {
    await _show(
      tester,
      SizedBox(
        width: 340,
        child: ApplianceTagInput<String>(
          labelText: 'Rooms',
          values: const ['Kitchen', 'Hall', 'Garage'],
          options: const ['Kitchen', 'Hall', 'Garage'],
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(ApplianceTagInput<String>),
        matching: find.byType(RawChipGroup),
      ),
      findsOneWidget,
    );
  });

  testWidgets("a breadcrumb's places lay out in a chip group", (tester) async {
    await _show(
      tester,
      width: 1024,
      ApplianceBreadcrumb(
        crumbs: [
          ApplianceCrumb('Home', onPressed: () {}),
          ApplianceCrumb('Kitchen', onPressed: () {}),
          const ApplianceCrumb('Kettles'),
        ],
      ),
    );
    expect(
      find.descendant(
        of: find.byType(ApplianceBreadcrumb),
        matching: find.byType(RawChipGroup),
      ),
      findsOneWidget,
    );
  });
}
