// A calendar writes its days in the app's digits, as Material's day picker
// does: in Arabic the 20th reads ٢٠, as its year and the app's other
// figures do, not 20.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Locale locale) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: const [RawWidgetsLocalizations.delegate],
  builder: (context, _) => BrutalTheme(
    data: BrutalThemeData.light(),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 358,
        child: BrutalCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          selectedDate: DateTime(2026, 11, 20),
          onDateChanged: (_) {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('in Arabic the days are Arabic-Indic', (tester) async {
    await tester.pumpWidget(_app(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
  });

  testWidgets('in English the days are Western', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);
  });
}
