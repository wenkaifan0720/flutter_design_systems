// Ledger's parts stand on the tap floor in force: ui_core's (a finger's 40) unless an app declares its own with a
// RawTapTargetScope, which every part follows, those that drew a fixed 44 or 48 before 0.7.0 too.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _declared = 52.0;

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: Material(
    type: MaterialType.transparency,
    child: RawTapTargetScope(
      targets: const RawTapTargets(touch: Size.square(_declared)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    ),
  ),
);

void _phone(WidgetTester t) {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(390, 844);
  addTearDown(t.view.reset);
}

void main() {
  testWidgets("a slider's touch strip is the declared floor tall", (t) async {
    _phone(t);
    await t.pumpWidget(
      _app(
        LedgerSlider(label: 'Budget', value: 40, max: 100, onChanged: (_) {}),
      ),
    );
    final strip = find.descendant(
      of: find.byType(LedgerSlider),
      matching: find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == double.infinity && w.height != null,
      ),
    );
    expect(t.getSize(strip.first).height, _declared);
  });

  testWidgets("a field stepper's rings each take the declared floor's width", (
    t,
  ) async {
    _phone(t);
    await t.pumpWidget(
      _app(
        LedgerStepper(
          size: LedgerStepperSize.field,
          labelText: 'Estimate (minutes)',
          value: 45,
          min: 5,
          max: 480,
          step: 5,
          format: (minutes) => '$minutes minutes',
          onChanged: (_) {},
        ),
      ),
    );
    final rings = find.descendant(
      of: find.byType(LedgerStepper),
      matching: find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == _declared,
      ),
    );
    expect(rings, findsNWidgets(2));
  });

  testWidgets("a pagination's gap mark is half the declared floor wide", (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1440, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _app(LedgerPagination(page: 5, pageCount: 9, onChanged: (_) {})),
    );
    final gap = find.ancestor(
      of: find.text('…'),
      matching: find.byType(SizedBox),
    );
    expect(t.getSize(gap.first).width, _declared / 2);
  });
}
