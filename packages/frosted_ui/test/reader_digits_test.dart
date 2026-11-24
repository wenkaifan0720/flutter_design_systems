// A month's days and its year are painted in the reader's digits, as they are read, in a calendar and a date picker: in Arabic the 18th shows ١٨, its
// name already saying "١٨ نوفمبر" (not 18 under a name of ١٨), and the head says "نوفمبر ٢٠٢٦", also when the app gives
// Frosted words of its own. In English the same days show 18.
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

/// An app's own Frosted words in Arabic: its month names, the rest Frosted's English.
class _ArabicFrostedWords extends FrostedLocalizationsEn {
  const _ArabicFrostedWords();

  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', //
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  String monthName(int month) => _months[month - 1];
}

class _ArabicFrostedWordsDelegate
    extends LocalizationsDelegate<FrostedLocalizations> {
  const _ArabicFrostedWordsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<FrostedLocalizations> load(Locale locale) =>
      SynchronousFuture<FrostedLocalizations>(const _ArabicFrostedWords());

  @override
  bool shouldReload(_ArabicFrostedWordsDelegate old) => false;
}

Future<void> _pump(
  WidgetTester tester,
  Locale locale, {
  bool ownWords = false,
  bool picker = false,
}) async {
  tester.view.physicalSize = const Size(390, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      localizationsDelegates: [
        RawWidgetsLocalizations.delegate,
        if (ownWords) const _ArabicFrostedWordsDelegate(),
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: FrostedHost(brightness: Brightness.light, child: child!),
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Center(
          child: SizedBox(
            width: 358,
            child: picker
                ? FrostedDatePicker(
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027),
                    value: DateTime(2026, 11, 20),
                    currentDate: DateTime(2026, 11, 18),
                    onChanged: (_) {},
                  )
                : FrostedCalendar(
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027),
                    value: DateTime(2026, 11, 20),
                    currentDate: DateTime(2026, 11, 18),
                    onChanged: (_) {},
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('in Arabic the days show Arabic digits', (tester) async {
    await _pump(tester, const Locale('ar'));
    expect(find.text('١٨'), findsOneWidget);
    expect(find.text('٢٠'), findsOneWidget, reason: 'the chosen day too');
    expect(find.text('18'), findsNothing);
  });

  testWidgets('in Arabic the head writes its year in Arabic digits', (
    tester,
  ) async {
    await _pump(tester, const Locale('ar'));
    expect(find.textContaining('٢٠٢٦'), findsOneWidget);
    expect(find.textContaining('2026'), findsNothing);
  });

  testWidgets(
    'with the app\'s own Frosted words in Arabic, the head writes its year in Arabic digits',
    (tester) async {
      await _pump(tester, const Locale('ar'), ownWords: true);
      expect(find.text('نوفمبر ٢٠٢٦'), findsOneWidget);
      expect(find.textContaining('2026'), findsNothing);
    },
  );

  testWidgets('a date picker\'s days show Arabic digits in Arabic', (
    tester,
  ) async {
    await _pump(tester, const Locale('ar'), picker: true);
    expect(find.text('١٨'), findsOneWidget);
    expect(find.text('٢٠'), findsOneWidget, reason: 'the chosen day too');
    expect(find.text('18'), findsNothing);
  });

  testWidgets(
    'a date picker\'s days show Arabic digits under the app\'s own Frosted words',
    (tester) async {
      await _pump(tester, const Locale('ar'), ownWords: true, picker: true);
      expect(find.text('١٨'), findsOneWidget);
      expect(find.text('نوفمبر ٢٠٢٦'), findsOneWidget);
      expect(find.text('18'), findsNothing);
    },
  );

  testWidgets('a date picker\'s days show Western digits in English', (
    tester,
  ) async {
    await _pump(tester, const Locale('en'), picker: true);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('١٨'), findsNothing);
  });

  testWidgets('in English the days show Western digits', (tester) async {
    await _pump(tester, const Locale('en'));
    expect(find.text('18'), findsOneWidget);
    expect(find.text('١٨'), findsNothing);
  });
}
