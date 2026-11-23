// A date field's calendar opens clear of the whole field, its label too:
// above a field low on the window it stood over the label (8 above the
// typed date), where Material's menus open clear of their field.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

void main() {
  setUpAll(loadScreenFonts);

  final pickers = <String, (String, Widget)>{
    'date': (
      'When do you want the permit to start?',
      CivicDatePicker(
        labelText: 'When do you want the permit to start?',
        helperText: 'For example, 27 3 2027',
        value: DateTime(2026, 11, 24),
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        onChanged: (_) {},
      ),
    ),
    'date range': (
      'When will your visitor stay?',
      CivicDateRangePicker(
        labelText: 'When will your visitor stay?',
        value: RawDateRange(DateTime(2026, 12, 28), DateTime(2026, 12, 30)),
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        onChanged: (_) {},
      ),
    ),
  };
  for (final MapEntry(key: kind, value: (label, picker)) in pickers.entries) {
    for (final width in [390.0, 1440.0]) {
      for (final low in [false, true]) {
        for (final direction in TextDirection.values) {
          testWidgets(
            'a $kind field ${low ? 'low' : 'high'} at ${width.round()}, '
            '${direction.name}: its calendar clears the field and the label',
            (tester) async {
              final height = width < 600 ? 844.0 : 900.0;
              tester.view.physicalSize = Size(width, height);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                kitApp(
                  brightness: Brightness.light,
                  direction: direction,
                  home: Align(
                    // A low field stands on the window's foot.
                    alignment: low
                        ? AlignmentDirectional.bottomStart
                        : AlignmentDirectional.topStart,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        24,
                        0,
                        24,
                      ),
                      child: SizedBox(
                        width: width < 600 ? 358 : 640,
                        child: picker,
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final words = tester.getRect(find.text(label));
              final controls =
                  [
                    ...find.byType(CivicWell).evaluate(),
                    ...find.byType(CivicButton).evaluate(),
                  ].map(
                    (e) =>
                        tester.getRect(find.byElementPredicate((x) => x == e)),
                  );
              final foot = controls
                  .map((r) => r.bottom)
                  .reduce((a, b) => a > b ? a : b);
              await tester.tap(find.byType(CivicButton));
              await tester.pumpAndSettle();
              final panel = tester.getRect(
                find
                    .ancestor(
                      of: find.byType(CivicCalendar),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              );
              if (panel.center.dy < words.top) {
                expect(
                  panel.bottom,
                  lessThanOrEqualTo(words.top),
                  reason: 'over the label: $panel, label $words',
                );
              } else {
                expect(panel.top, greaterThanOrEqualTo(foot));
              }
            },
          );
        }
      }
    }
  }
}
