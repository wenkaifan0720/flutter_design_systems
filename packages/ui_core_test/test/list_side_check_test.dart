// DesignListSideCheck: a list opens below its field while below holds it.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');
const _names = [
  'Maya Reed',
  'Sam Okafor',
  'Noor Haddad',
  'Inez Park',
  'Leo Silva',
];

// A form's Assignee 330 px over a phone's foot: more room above, room for
// the list below.
Widget _page(Widget field) => harness(
  Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.only(top: 844 - 48 - 330, left: 16),
      child: SizedBox(width: 320, child: field),
    ),
  ),
);

Widget _row(BuildContext context, String name) =>
    SizedBox(height: 44, child: Text(name));

// A combobox whose list opens in [direction], else as the combobox's
// default has it.
Widget _combobox({OptionsViewOpenDirection? direction}) {
  Widget field(BuildContext context, RawComboboxField field) => plainField(
    key: _fieldKey,
    controller: field.controller,
    focusNode: field.focusNode,
    onSubmitted: field.submit,
    width: 320,
  );
  Widget row(BuildContext context, String option, Set<WidgetState> states) =>
      _row(context, option);
  if (direction == null) {
    return RawCombobox<String>(
      options: _names,
      fieldBuilder: field,
      optionBuilder: row,
    );
  }
  return RawCombobox<String>(
    options: _names,
    optionsViewOpenDirection: direction,
    fieldBuilder: field,
    optionBuilder: row,
  );
}

Future<DesignAlignmentReport> _open(WidgetTester tester, Widget field) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_page(field));
  await tester.tap(find.byKey(_fieldKey));
  await tester.pumpAndSettle();
  return const DesignListSideCheck(look: 'Test')
      .check(tester.element(find.byType(WidgetsApp)));
}

void main() {
  testWidgets('a list on the side with most space, above with room below, '
      'is reported', (tester) async {
    final report = await _open(
      tester,
      _combobox(direction: OptionsViewOpenDirection.mostSpace),
    );
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(
        startsWith('a list over a text field at 16, 246 opens above it '),
        endsWith(
          ' px free below, room for 200 px of its 220 px: it opens below '
          'while below holds it',
        ),
      ),
    );
  });

  testWidgets('a combobox as it is built opens below and passes', (
    tester,
  ) async {
    final report = await _open(tester, _combobox());
    expect(report.problems, isEmpty);
  });

  testWidgets('a select\'s popover with a short list that fits below passes', (
    tester,
  ) async {
    final report = await _open(
      tester,
      RawPopover(
        anchorBuilder: (context, anchor) => RawButton(
          onPressed: anchor.toggle,
          builder: (context, states, _) =>
              const SizedBox(key: _fieldKey, height: 44, child: Text('Sort')),
        ),
        overlayBuilder: (context, info) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (final n in _names.take(3)) _row(context, n)],
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a list asked above is not reported', (tester) async {
    final report = await _open(
      tester,
      _combobox(direction: OptionsViewOpenDirection.up),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a list above with too little room below passes', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 844 - 48 - 90, left: 16),
            child: SizedBox(width: 320, child: _combobox()),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    expect(
      const DesignListSideCheck(look: 'Test')
          .check(tester.element(find.byType(WidgetsApp)))
          .problems,
      isEmpty,
    );
  });

  // A popover from a field whose foot stands [below] px over the screen's
  // foot, its surface [extent] px high.
  Future<(DesignAlignmentReport, Rect, Rect)> openAt(
    WidgetTester tester, {
    required double below,
    required double extent,
    required RawPopoverPlacement placement,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(top: 844 - below - 44, left: 16),
            child: RawPopover(
              placement: placement,
              anchorBuilder: (context, anchor) => RawButton(
                onPressed: anchor.toggle,
                builder: (context, states, _) => const SizedBox(
                  key: _fieldKey,
                  width: 320,
                  height: 44,
                  child: Text('Due'),
                ),
              ),
              overlayBuilder: (context, info) => SizedBox(
                key: const ValueKey('surface'),
                width: 300,
                height: math.min(extent, info.maxSize.height),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.pumpAndSettle();
    return (
      const DesignListSideCheck(look: 'Test')
          .check(tester.element(find.byType(WidgetsApp))),
      tester.getRect(find.byKey(_fieldKey)),
      tester.getRect(find.byKey(const ValueKey('surface'))),
    );
  }

  testWidgets("a month that fits whole only above opens there and passes, "
      'though below holds 200 px of it (RawPopoverFit.whole)', (tester) async {
    final (report, field, month) = await openAt(
      tester,
      below: 250,
      extent: 300,
      placement: const RawPopoverPlacement(fit: RawPopoverFit.whole),
    );
    expect(month.bottom, lessThanOrEqualTo(field.top), reason: 'above');
    expect(month.height, 300, reason: 'whole');
    expect(report.problems, isEmpty);
  });

  testWidgets('a month that fits whole below opens there and passes', (
    tester,
  ) async {
    final (report, field, month) = await openAt(
      tester,
      below: 340,
      extent: 300,
      placement: const RawPopoverPlacement(fit: RawPopoverFit.whole),
    );
    expect(month.top, greaterThanOrEqualTo(field.bottom), reason: 'below');
    expect(report.problems, isEmpty);
  });

  testWidgets("a list that asks for 300 px below opens above where below "
      'holds 250, and passes (its preferredExtent)', (tester) async {
    final (report, field, list) = await openAt(
      tester,
      below: 250,
      extent: 360,
      placement: const RawPopoverPlacement(preferredExtent: 300),
    );
    expect(list.bottom, lessThanOrEqualTo(field.top), reason: 'above');
    expect(report.problems, isEmpty);
  });
}
