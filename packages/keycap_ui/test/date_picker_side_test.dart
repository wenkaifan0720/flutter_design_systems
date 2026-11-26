// A date field from 600 wide opens its month below while below holds the
// whole month, and above only when below can't: the month never shrinks to
// scroll where one side holds it whole. (Below 600 it opens in a sheet:
// date_picker_sheet_test.)
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      builder: (context, app) =>
          KeycapHost(brightness: brightness, child: app!),
      home: home,
    );

void main() {
  final pickers = <String, Widget Function()>{
    'date': () => KeycapDatePicker(
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'date range': () => KeycapDateRangePicker(
      value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
  };

  Widget at(double above, Widget picker) => _app(
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: above),
          picker,
        ],
      ),
    ),
  );

  // A wide screen keeps the field to a key's width at the start of its
  // column, so the taps land near its start.
  // The month's panel and its gap from the field, opened from the top of the
  // screen, where below holds it with room to spare.
  Future<(double, double)> measure(WidgetTester tester, Widget picker) async {
    await tester.pumpWidget(at(24, picker));
    final field = tester.getRect(find.byWidget(picker));
    await tester.tapAt(field.bottomLeft + const Offset(48, -16));
    await tester.pumpAndSettle();
    final panel = tester.getRect(_panel());
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    return (panel.height, panel.top - field.bottom);
  }

  // A tablet standing up, where a field under the middle can still have the
  // month's room below it.
  const screens = [Size(744, 1133)];
  for (final MapEntry(key: kind, value: build) in pickers.entries) {
    for (final screen in screens) {
      for (final share in [0.25, 0.35, 0.45, 0.5, 0.55, 0.6, 0.7]) {
        final above = (screen.height * share).roundToDouble();
        testWidgets('a $kind field ${above.round()} down a '
            '${screen.width.round()} × ${screen.height.round()} screen opens '
            'its month whole, below while below holds it', (tester) async {
          tester.view.physicalSize = screen;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final picker = build();
          final (whole, gap) = await measure(tester, picker);
          await tester.pumpWidget(at(above, picker));
          await tester.pumpAndSettle();
          final field = tester.getRect(find.byWidget(picker));
          await tester.tapAt(field.bottomLeft + const Offset(48, -16));
          await tester.pumpAndSettle();
          final panel = tester.getRect(_panel());
          final belowHolds = field.bottom + gap + whole <= screen.height - 8;
          expect(
            panel.height,
            moreOrLessEquals(whole, epsilon: 0.5),
            reason: 'the month shrank to ${panel.height} of its $whole px',
          );
          if (belowHolds) {
            expect(
              panel.top,
              greaterThan(field.bottom - 1),
              reason: 'below holds the month whole, but it opened above',
            );
          } else {
            expect(panel.bottom, lessThan(field.top + 1));
          }
        });
      }
    }
  }
}

/// The panel the month floats in.
Finder _panel() => find
    .ancestor(
      of: find.byType(KeycapCalendar),
      matching: find.byType(KeycapMenuPanel),
    )
    .first;
