// A press anywhere in a radio's box chooses it, as the published radios
// did: a LedgerRadio's row, a segmented control's chip and a pill of a
// toggle group of one choice, the gap between a radio's ring and its words
// too. RawRadio's own detector takes a press only where the face paints.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

/// Presses each of [radios] (a group's RawRadios, saying [values] in turn)
/// at its start, its middle, its end, its top and its bottom, each time from
/// another choice, and expects the press to choose it.
Future<void> _pressEverywhere<V>(
  WidgetTester t,
  Finder radios,
  ValueNotifier<V> choice,
  List<V> values,
) async {
  expect(radios, findsNWidgets(values.length));
  for (final (i, value) in values.indexed) {
    final box = t.getRect(radios.at(i));
    for (final at in [
      box.centerLeft + const Offset(2, 0),
      box.center,
      box.centerRight - const Offset(2, 0),
      box.topCenter + const Offset(0, 2),
      box.bottomCenter - const Offset(0, 2),
    ]) {
      choice.value = values[(i + 1) % values.length];
      await t.pumpAndSettle();
      await t.tapAt(at);
      await t.pumpAndSettle();
      expect(choice.value, value, reason: '$value pressed at $at in $box');
    }
  }
}

Finder _radiosOf(Finder group) => find.descendant(
  of: group,
  matching: find.byWidgetPredicate((w) => w is RawRadio),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a press anywhere in a radio\'s box chooses it, '
        '${direction.name}', (t) async {
      const often = ['Weekly', 'Monthly', 'Yearly'];
      const range = ['1M', '3M', '1Y'];
      const span = ['Week', 'Month', 'Quarter'];
      final how = ValueNotifier('Weekly');
      final when = ValueNotifier('1M');
      final pill = ValueNotifier('Week');
      addTearDown(how.dispose);
      addTearDown(when.dispose);
      addTearDown(pill.dispose);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, app) => LedgerHost(child: app!),
          home: Scaffold(
            body: Directionality(
              textDirection: direction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder(
                    valueListenable: how,
                    builder: (context, value, _) => RadioGroup<String>(
                      key: const ValueKey('radios'),
                      groupValue: value,
                      onChanged: (v) => how.value = v!,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final o in often)
                            LedgerRadio<String>(value: o, label: o),
                        ],
                      ),
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: when,
                    builder: (context, value, _) =>
                        LedgerSegmentedControl<String>(
                          options: range,
                          value: value,
                          onChanged: (v) => when.value = v,
                        ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: pill,
                    builder: (context, value, _) => LedgerToggleGroup<String>(
                      semanticLabel: 'Range',
                      options: span,
                      labelOf: (v) => v,
                      selected: {value},
                      onSelectionChanged: (next) => pill.value = next.single,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await _pressEverywhere(
        t,
        _radiosOf(find.byKey(const ValueKey('radios'))),
        how,
        often,
      );
      await _pressEverywhere(
        t,
        _radiosOf(find.byType(LedgerSegmentedControl<String>)),
        when,
        range,
      );
      await _pressEverywhere(
        t,
        _radiosOf(find.byType(LedgerToggleGroup<String>)),
        pill,
        span,
      );
    });
  }
}
