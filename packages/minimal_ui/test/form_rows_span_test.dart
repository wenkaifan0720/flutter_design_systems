// A form's rows end on one edge: a select, a date and a time row span their
// column at every width, as a text field and every other form row do, so on a
// laptop they never stop half way beside full-width fields.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _app(Widget child, {required double width}) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  for (final (view, column) in [(1440.0, 640.0), (390.0, 358.0)]) {
    testWidgets('at $view, select, date and time rows span a $column column', (
      tester,
    ) async {
      tester.view.physicalSize = Size(view, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          MinimalFormSection(
            title: 'Task',
            children: [
              MinimalSelect<String>(
                labelText: 'Priority',
                value: 'high',
                options: const [
                  MinimalSelectOption('low', 'Low'),
                  MinimalSelectOption('high', 'High'),
                ],
                onChanged: (_) {},
              ),
              MinimalDatePicker(
                labelText: 'Due date',
                value: DateTime(2026, 11, 20),
                mode: MinimalDatePickerMode.date,
                onChanged: (_) {},
              ),
              MinimalTimePicker(
                labelText: 'Reminder time',
                value: DateTime(2026, 11, 20, 9, 30),
                onChanged: (_) {},
              ),
            ],
          ),
          width: column,
        ),
      );
      await tester.pumpAndSettle();
      for (final row in [
        find.byType(MinimalSelect<String>),
        find.byType(MinimalDatePicker).first,
        find.byType(MinimalTimePicker),
      ]) {
        expect(tester.getSize(row).width, column, reason: '$row');
      }
    });
  }
}
