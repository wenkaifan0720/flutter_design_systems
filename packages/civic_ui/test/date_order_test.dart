// ignore_for_file: deprecated_member_use_from_same_package, the context-free forms stay until 1.0.0.
// A typed date's order is the app's locale's, as ui_core's localizations
// give it (RawWidgetsLocalizations.dateFieldPattern): month first in
// American English. An app that writes every date one way gives its own
// localizations, a delegate listed first, and the date picker, its example
// and its parts follow them. CivicFormat.date writes the month in words,
// "27 March 2026", the same in every locale.
import 'package:civic_ui/civic_parts.dart' show CivicDateSegment;
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// An app's dates, day first.
class _DayFirst extends DefaultRawWidgetsLocalizations {
  const _DayFirst();

  @override
  String get dateFieldPattern => 'dd/MM/y';
}

class _DayFirstDelegate extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _DayFirstDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const _DayFirst());

  @override
  bool shouldReload(_DayFirstDelegate old) => false;
}

Future<(List<String>, String)> _picker(
  WidgetTester tester, {
  required Locale locale,
  List<LocalizationsDelegate<Object>> delegates = const [],
}) async {
  late String example;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: [
        ...delegates,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, child) => CivicHost(child: child!),
      home: Builder(
        builder: (context) {
          example = CivicDatePicker.exampleOf(context, DateTime(2026, 3, 27));
          return CivicDatePicker(
            labelText: 'When do you want the permit to start?',
            value: null,
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            onChanged: (_) {},
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  final parts = [
    for (final s in tester.widgetList<CivicDateSegment>(
      find.byType(CivicDateSegment),
    ))
      s.details.type.name,
  ];
  return (parts, example);
}

void main() {
  testWidgets('American English types the month first', (tester) async {
    final (parts, example) = await _picker(
      tester,
      locale: const Locale('en', 'US'),
    );
    expect(parts, ['month', 'day', 'year']);
    expect(example, '3/27/2026');
  });

  testWidgets("an app's own localizations put the day first", (tester) async {
    final (parts, example) = await _picker(
      tester,
      locale: const Locale('en', 'GB'),
      delegates: const [_DayFirstDelegate()],
    );
    expect(parts, ['day', 'month', 'year']);
    expect(example, '27/3/2026');
  });

  test('CivicFormat writes the month in words, day first, in any locale', () {
    expect(CivicFormat.date(DateTime(2026, 3, 27)), '27 March 2026');
  });
}
