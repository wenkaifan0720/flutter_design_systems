// A date picker outlines the app's today when it is given one (as Material's currentDate), never the device's date
// beside it: one day outlined, the chosen one lit.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

/// The day numbers drawn outlined (today's mark) in the calendar.
List<String> _outlined(WidgetTester tester) => [
  for (final box in tester.widgetList<DecoratedBox>(
    find.descendant(
      of: find.byType(RetroDesktopDatePicker),
      matching: find.byType(DecoratedBox),
    ),
  ))
    if (box.decoration case ShapeDecoration(shape: final OutlinedBorder shape)
        when shape.side != BorderSide.none)
      for (final text in tester.widgetList<Text>(
        find.descendant(of: find.byWidget(box), matching: find.byType(Text)),
      ))
        text.data ?? '',
];

void main() {
  testWidgets('the picker outlines the today it is given', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A today far from the device's date, in a month the device's today is not in.
    await tester.pumpWidget(
      retroDesktopApp(
        Center(
          child: RetroDesktopDatePicker(
            value: DateTime(2031, 3, 18),
            today: DateTime(2031, 3, 20),
            onChanged: (_) {},
          ),
        ),
        width: 1440,
      ),
    );
    await tester.pump();
    expect(_outlined(tester), ['20']);
  });

  testWidgets('the date dialog takes a today and opens on it', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      retroDesktopApp(
        Builder(
          builder: (context) => Center(
            child: RetroDesktopButton(
              'Due',
              onPressed: () => showRetroDesktopDatePicker(
                context,
                today: DateTime(2031, 3, 20),
              ),
            ),
          ),
        ),
        width: 1440,
      ),
    );
    await tester.tap(find.text('Due'));
    await tester.pumpAndSettle();
    expect(find.textContaining('2031'), findsWidgets);
    // Chosen and today are the same day here: lit, not also outlined.
    expect(_outlined(tester), isEmpty);
  });
}
