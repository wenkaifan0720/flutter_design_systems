/// A toggle button reads as Flutter's `IconButton(isSelected:)` reads: a
/// button that is selected or not, never a switch.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Matcher _toggleButton(String label, {required bool selected}) => isSemantics(
  label: label,
  isButton: true,
  hasSelectedState: true,
  isSelected: selected,
  hasToggledState: false,
  hasCheckedState: false,
  hasEnabledState: true,
  isEnabled: true,
  hasTapAction: true,
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) =>
          FrostedHost(brightness: Brightness.light, child: page!),
      home: Material(child: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('FrostedIconButton reads as IconButton(isSelected:)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            isSelected: true,
            onPressed: () {},
            icon: const Icon(Icons.star, semanticLabel: 'Flutter'),
          ),
          for (final on in [true, false])
            FrostedIconButton(
              FrostedGlyphs.share,
              semanticLabel: on ? 'Shared' : 'Not shared',
              selected: on,
              onPressed: () {},
            ),
        ],
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Flutter')),
      _toggleButton('Flutter', selected: true),
      reason: "Flutter's own toggle button, the reading to match",
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Shared')),
      _toggleButton('Shared', selected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Not shared')),
      _toggleButton('Not shared', selected: false),
    );
    handle.dispose();
  });

  testWidgets('a week strip day reads as a button, selected while kept', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      FrostedWeekStrip(
        start: DateTime(2026, 10, 26),
        days: const [
          FrostedDayStatus.complete,
          FrostedDayStatus.complete,
          FrostedDayStatus.missed,
          FrostedDayStatus.complete,
          FrostedDayStatus.current,
          FrostedDayStatus.upcoming,
          FrostedDayStatus.upcoming,
        ],
        onChanged: (_) {},
      ),
    );
    SemanticsNode day(String name) =>
        tester.getSemantics(find.bySemanticsLabel(RegExp('^$name ')));
    final monday = day('Monday');
    expect(
      monday,
      _toggleButton(monday.label, selected: true),
      reason: 'a kept day',
    );
    final wednesday = day('Wednesday');
    expect(
      wednesday,
      _toggleButton(wednesday.label, selected: false),
      reason: 'a missed day',
    );
    handle.dispose();
  });
}
