// A chosen chip, segment, switch, toggle key or AM/PM key out of use keeps
// its lamp lit, in the disabled print, as a radio does: the lamp says
// chosen, the print says out of use. A part out of use that is not chosen
// keeps its lamp out. By day and by night.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appliance_ui/appliance_ui.dart';

Future<void> _show(
  WidgetTester tester,
  Widget part,
  Brightness brightness,
) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFEE6A26),
      builder: (context, _) => ApplianceHost(
        brightness: brightness,
        child: Center(child: part),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<ApplianceLamp> _lamps(WidgetTester tester) =>
    tester.widgetList<ApplianceLamp>(find.byType(ApplianceLamp)).toList();

Color _disabledPrint(WidgetTester tester) =>
    ApplianceTheme.of(tester.element(find.byType(ApplianceLamp).first))
        .colors
        .printDisabled;

void main() {
  for (final brightness in Brightness.values) {
    final time = brightness == Brightness.light ? 'by day' : 'by night';

    testWidgets('a selected chip with no onSelected keeps its lamp lit in '
        'the disabled print, $time', (tester) async {
      await _show(
        tester,
        const ApplianceChip('Vegan', selected: true),
        brightness,
      );
      final lamp = _lamps(tester).single;
      expect(lamp.lit, isTrue);
      expect(lamp.color, _disabledPrint(tester));

      await _show(
        tester,
        ApplianceChip('Vegan', enabled: false, onSelected: (_) {}),
        brightness,
      );
      expect(_lamps(tester).single.lit, isFalse);
    });

    testWidgets('a segmented button with no onChanged keeps its chosen '
        "segment's lamp lit in the disabled print, $time", (tester) async {
      await _show(
        tester,
        ApplianceSegmentedButton<String>(
          segments: const [
            ApplianceSegment(value: 'grid', label: 'Grid'),
            ApplianceSegment(value: 'list', label: 'List'),
          ],
          value: 'grid',
          onChanged: null,
        ),
        brightness,
      );
      final [grid, list] = _lamps(tester);
      expect(grid.lit, isTrue);
      expect(grid.color, _disabledPrint(tester));
      expect(list.lit, isFalse);
    });

    testWidgets('an on switch with no onChanged keeps its lamp lit in the '
        'disabled print, $time', (tester) async {
      await _show(
        tester,
        const ApplianceSwitch(
          value: true,
          onChanged: null,
          semanticLabel: 'Order updates',
        ),
        brightness,
      );
      final lamp = _lamps(tester).single;
      expect(lamp.lit, isTrue);
      expect(lamp.color, _disabledPrint(tester));

      await _show(
        tester,
        const ApplianceSwitch(
          value: false,
          onChanged: null,
          semanticLabel: 'Order updates',
        ),
        brightness,
      );
      expect(_lamps(tester).single.lit, isFalse);
    });

    testWidgets('a toggle group with no onSelectionChanged keeps the lamp '
        'of its key down lit in the disabled print, $time', (tester) async {
      await _show(
        tester,
        const ApplianceToggleGroup<String>(
          options: [
            ApplianceToggleOption(value: 'b', label: 'Bold'),
            ApplianceToggleOption(value: 'i', label: 'Italic'),
          ],
          selected: {'i'},
          onSelectionChanged: null,
        ),
        brightness,
      );
      final [bold, italic] = _lamps(tester);
      expect(italic.lit, isTrue);
      expect(italic.color, _disabledPrint(tester));
      expect(bold.lit, isFalse);
    });

    testWidgets("a time picker with no onChanged keeps its chosen AM/PM key's "
        'lamp lit in the disabled print, $time', (tester) async {
      await _show(
        tester,
        const ApplianceTimePicker(
          value: ApplianceTime(9, 30),
          onChanged: null,
          twentyFourHour: false,
        ),
        brightness,
      );
      final [morning, afternoon] = _lamps(tester);
      expect(morning.lit, isTrue);
      expect(morning.color, _disabledPrint(tester));
      expect(afternoon.lit, isFalse);
    });
  }
}
