// A time picker's wheels are named in the reader's language: ui_core's
// RawWidgetsLocalizations gives the hour and minute words, so German hears
// "Stunde" and Arabic "ساعة", where the wheels once said "Hour" and "Minute"
// in English in every locale.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Locale locale) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('de'), Locale('ar')],
  localizationsDelegates: const [RawWidgetsLocalizations.delegate],
  builder: (context, _) => BrutalTheme(
    data: BrutalThemeData.light(),
    child: Align(
      alignment: Alignment.topLeft,
      child: BrutalTimePicker(
        value: const BrutalTime(hour: 19, minute: 30),
        onChanged: (_) {},
      ),
    ),
  ),
);

void main() {
  for (final (locale, hour, minute) in const [
    (Locale('en'), 'Hour', 'Minute'),
    (Locale('de'), 'Stunde', 'Minute'),
    (Locale('ar'), 'ساعة', 'دقيقة'),
  ]) {
    testWidgets('${locale.languageCode}: the wheels are named $hour and '
        '$minute', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(locale));
      await tester.pumpAndSettle();
      for (final (name, value) in [(hour, '19'), (minute, '30')]) {
        final node = tester.getSemantics(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(name)}')),
        );
        expect(node.label, startsWith(name));
        expect(node.value, contains(value), reason: name);
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.increase),
          isTrue,
          reason: name,
        );
      }
      if (locale.languageCode != 'en') {
        expect(find.bySemanticsLabel(RegExp('Hour')), findsNothing);
      }
      semantics.dispose();
    });
  }
}
