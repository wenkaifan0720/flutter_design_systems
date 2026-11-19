// A time picker speaks the reader's language: a screen reader names its
// drums in ui_core's words for the hour, the minute and the half of the day
// ("Stunde", "Minute", "Tageshälfte" in German; "ساعة", "دقيقة", "ص/م" in
// Arabic), the half of the day reads as the reader writes it, and the drums'
// figures and a time's text are in the reader's digits (Arabic-Indic in
// Arabic), as Material's time picker sets its hours.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

Future<BuildContext> _show(
  WidgetTester tester,
  Locale locale,
  Widget child,
) async {
  late BuildContext inner;
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          child: Directionality(
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Builder(
              builder: (context) {
                inner = context;
                return Align(alignment: Alignment.topCenter, child: child);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return inner;
}

void main() {
  for (final (locale, hour, minute, half, morning, evening, figures) in [
    (
      const Locale('ar'),
      'ساعة',
      'دقيقة',
      'ص/م',
      '٩:٠٥ ص',
      '٦:٣٠ م',
      ('٦', '٣٠'),
    ),
    (
      const Locale('de'),
      'Stunde',
      'Minute',
      'Tageshälfte',
      '9:05 AM',
      '6:30 PM',
      ('6', '30'),
    ),
    (
      const Locale('en'),
      'Hour',
      'Minute',
      'AM/PM',
      '9:05 AM',
      '6:30 PM',
      ('6', '30'),
    ),
  ]) {
    testWidgets('in ${locale.languageCode} a screen reader names the drums '
        '$hour, $minute and $half', (tester) async {
      final semantics = tester.ensureSemantics();
      await _show(
        tester,
        locale,
        GlossTimePicker(
          value: const GlossTime(hour: 18, minute: 30),
          semanticLabel: 'Reminder',
          onChanged: (_) {},
        ),
      );
      expect(find.bySemanticsLabel(hour), findsOneWidget);
      expect(find.bySemanticsLabel(minute), findsOneWidget);
      expect(find.bySemanticsLabel(half), findsOneWidget);
      expect(find.text(evening.split(' ').last), findsWidgets);
      // The drums' figures, in the reader's digits.
      expect(find.text(figures.$1), findsWidgets);
      expect(find.text(figures.$2), findsWidgets);
      if (locale.languageCode != 'en') {
        expect(
          find.bySemanticsLabel(RegExp(r'^(Hour|AM or PM)$')),
          findsNothing,
        );
      }
      semantics.dispose();
    });

    testWidgets('in ${locale.languageCode} a time reads $morning and '
        '$evening', (tester) async {
      final context = await _show(tester, locale, const SizedBox());
      expect(const GlossTime(hour: 9, minute: 5).format(context), morning);
      expect(const GlossTime(hour: 18, minute: 30).format(context), evening);
    });
  }
}
