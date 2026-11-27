// A date field's calendar panel opens clear of its field and its label, as
// Material's menus open clear of their field: above a field low on a wide
// window it stood over the label. From a field narrower than a month it
// stands at the field's width, edge to edge with it, where it stood about 7
// past each side; from a wider field it starts at the field's start. Below
// 600 wide the calendar rises in a sheet instead (date_picker_sheet_test).
// GlossScaffold is deprecated (GlossAppShell replaces it); tested until 0.7.0 removes it.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _shot = GlobalKey();

Widget _app({
  required Brightness brightness,
  required Widget home,
  TextDirection direction = TextDirection.ltr,
  double text = 1,
}) => RepaintBoundary(
  key: _shot,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, navigator) => Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: GlossHost(
          theme: GlossThemeData.light(),
          darkTheme: GlossThemeData.dark(),
          brightness: brightness,
          child: GlossToaster(child: navigator!),
        ),
      ),
    ),
    home: home,
  ),
);

void main() {
  final pickers = <String, Widget>{
    'date': GlossDatePicker(
      labelText: 'Cook on',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'date range': GlossDateRangePicker(
      labelText: 'Cook on',
      value: GlossDateRange(
        start: DateTime(2026, 11, 20),
        end: DateTime(2026, 11, 24),
      ),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
  };
  for (final MapEntry(key: kind, value: picker) in pickers.entries) {
    for (final width in [640.0, 1440.0]) {
      for (final low in [false, true]) {
        for (final direction in TextDirection.values) {
          testWidgets(
            'a $kind field ${low ? 'low' : 'high'} at ${width.round()}, '
            '${direction.name}: its calendar clears the field and the label',
            (tester) async {
              final height = width < 1000 ? 844.0 : 900.0;
              tester.view.physicalSize = Size(width, height);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              final column = width < 1000 ? 358.0 : 640.0;
              await tester.pumpWidget(
                _app(
                  brightness: Brightness.light,
                  direction: direction,
                  home: GlossScaffold(
                    body: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: 16,
                          top: low ? height - 190 : 24,
                        ),
                        child: SizedBox(width: column, child: picker),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final field = tester.getRect(find.byWidget(picker));
              final label = tester.getRect(find.text('Cook on'));
              await tester.tapAt(field.bottomCenter - const Offset(0, 16));
              await tester.pumpAndSettle();
              final panel = tester.getRect(
                find
                    .ancestor(
                      of: find.byType(GlossCalendar),
                      matching: find.byType(GlossSurface),
                    )
                    .first,
              );
              if (panel.center.dy < field.center.dy) {
                expect(
                  panel.bottom,
                  lessThanOrEqualTo(label.top),
                  reason: 'over the label: $panel, label $label',
                );
              } else {
                expect(panel.top, greaterThanOrEqualTo(field.bottom));
              }
              final rtl = direction == TextDirection.rtl;
              // It starts where the field starts.
              expect(
                rtl ? panel.right : panel.left,
                moreOrLessEquals(rtl ? field.right : field.left, epsilon: .5),
                reason: 'panel $panel, field $field',
              );
              if (width < 1000) {
                // From a field narrower than a month, edge to edge with it.
                expect(
                  rtl ? panel.left : panel.right,
                  moreOrLessEquals(rtl ? field.left : field.right, epsilon: .5),
                  reason: 'panel $panel, field $field',
                );
              }
            },
          );
        }
      }
    }
  }
}
