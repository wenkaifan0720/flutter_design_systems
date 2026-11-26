// Filters and chips that wrap stand their faces the look's gap apart, run beside run and run under run, their targets
// reaching into the room between (ui_core's RawChipGroup): never the gap and each target's slack on top of it, which
// read as two groups. Faces stand further apart only as far as their targets need (the floor less the face).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _gap = 6.0;

Widget _app(Widget group) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      LedgerHost(brightness: Brightness.light, child: child!),
  home: Material(
    type: MaterialType.transparency,
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 260, child: group),
      ),
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

/// The faces in [group], each a pressable's box, in reading order.
List<Rect> _faces(WidgetTester t, Finder group) => [
  for (final e
      in find
          .descendant(of: group, matching: find.byType(LedgerPressable))
          .evaluate())
    t.getRect(find.byElementPredicate((x) => identical(x, e))),
];

/// The room from each run's lowest face foot to the next run's highest face head.
List<double> _underGaps(List<Rect> faces) {
  final runs = <List<Rect>>[];
  for (final f in faces) {
    if (runs.isEmpty || f.top > runs.last.first.bottom) {
      runs.add([f]);
    } else {
      runs.last.add(f);
    }
  }
  return [
    for (var i = 1; i < runs.length; i++)
      runs[i].map((f) => f.top).reduce(math.min) -
          runs[i - 1].map((f) => f.bottom).reduce(math.max),
  ];
}

void _expectTight(WidgetTester t, Finder group) {
  final faces = _faces(t, group);
  final floor = RawTapTargets.of(t.element(group)).floorOn().height;
  final face = faces.map((f) => f.height).reduce(math.max);
  final under = _underGaps(faces);
  expect(under, isNotEmpty, reason: 'the group wraps');
  for (final g in under) {
    expect(g, lessThanOrEqualTo(math.max(_gap, floor - face) + .5));
  }
}

void main() {
  testWidgets(
    'filters that wrap stand their runs the gap apart, face to face',
    (t) async {
      _phone(t);
      await t.pumpWidget(
        _app(
          LedgerFilters<String>(
            label: 'Direction',
            options: const [
              'All',
              'Money in',
              'Money out',
              'Transfers',
              'Refunds',
              'Fees',
            ],
            value: 'All',
            onChanged: (_) {},
          ),
        ),
      );
      await t.pumpAndSettle();
      _expectTight(t, find.byType(LedgerFilters<String>));
    },
  );

  testWidgets(
    'a row of chips that wraps stands its runs the gap apart, face to face',
    (t) async {
      _phone(t);
      await t.pumpWidget(
        _app(
          LedgerChipRow(
            label: 'Categories',
            children: [
              for (final c in const [
                'Groceries',
                'Rent',
                'Transit',
                'Utilities',
                'Dining',
                'Travel',
              ])
                LedgerChip(c, onTap: () {}),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      _expectTight(t, find.byType(LedgerChipRow));
    },
  );
}
