// A date field shows its day in Gloss's one format with the year
// (GlossFormat.mediumDate: the day, its month short, the year), not the
// day's name in full.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

void main() {
  testWidgets('a date field shows the medium date with its year', (t) async {
    final day = DateTime(2026, 11, 26);
    late String medium, localeMedium, full;
    await t.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF0E7652),
        builder: (context, _) => GlossTheme(
          data: GlossThemeData.preset('jade', Brightness.light),
          child: Builder(
            builder: (context) {
              medium = GlossFormat.mediumDate(context, day);
              final words = RawWidgetsLocalizations.of(context);
              localeMedium = words.formatMediumDate(day);
              full = words.formatFullDate(day);
              return Center(
                child: SizedBox(
                  width: 320,
                  child: GlossDatePicker(
                    labelText: 'Started',
                    value: day,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    onChanged: (_) {},
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    // The locale's medium date: "Nov 26, 2026" in English, with the year.
    expect(medium, localeMedium);
    expect(medium, contains('2026'));
    expect(medium, isNot(full));
    expect(find.text(medium), findsOneWidget);
    expect(find.text(full), findsNothing);
  });
}
