// ApplianceFormat.date writes a day as the date picker does, year and all,
// so a page and its fields share one date format.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

void main() {
  testWidgets('a page writes a day as its date field does', (tester) async {
    final day = DateTime(2026, 11, 23);
    late String written;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ApplianceHost(brightness: Brightness.light, child: app!),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              written = ApplianceFormat.date(context, day);
              return ApplianceDatePicker(
                labelText: 'Delivery',
                value: day,
                onChanged: (_) {},
                firstDate: DateTime(2026),
                lastDate: DateTime(2027, 12, 31),
              );
            },
          ),
        ),
      ),
    );
    expect(written, contains('2026'));
    expect(written, contains('23'));
    expect(find.text(written), findsOneWidget);
  });
}
