/// Counted words take their plural form. A count Expressive speaks (a time
/// picker's hours and minutes, a code field's length, a step indicator's
/// steps) goes to [ExpressiveLocalizations] as a number, so English says
/// "1 minute" and "2 minutes", and a language with more forms (Arabic's six:
/// one, two, few, many, other, zero) words each count its own way through
/// the app's delegate.
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

Widget _host(Widget child, {Locale? locale}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => ExpressiveHost(
    light: ExpressiveThemeData.preset('bloom', Brightness.light),
    brightness: Brightness.light,
    child: app!,
  ),
  home: Builder(
    builder: (context) {
      final page = SingleChildScrollView(child: Center(child: child));
      if (locale == null) return page;
      return Localizations.override(
        context: context,
        locale: locale,
        delegates: const <LocalizationsDelegate<Object?>>[
          _Arabic(),
          DesignLocalizations.delegate,
        ],
        child: Directionality(textDirection: TextDirection.rtl, child: page),
      );
    },
  ),
);

/// Arabic's counted noun: the word alone for 1, the dual alone for 2, then
/// the number with the plural (3 to 10) or the singular (11 to 99, and 0).
String _arabicCount(
  int n, {
  required String one,
  required String two,
  required String few,
  required String many,
}) => switch (n % 100) {
  _ when n == 1 => one,
  _ when n == 2 => two,
  final rest when rest >= 3 && rest <= 10 => '$n $few',
  _ => '$n $many',
};

String _arabicMinutes(int n) => _arabicCount(
  n,
  one: 'دقيقة واحدة',
  two: 'دقيقتان',
  few: 'دقائق',
  many: 'دقيقة',
);

String _arabicHours(int n) => _arabicCount(
  n,
  one: 'ساعة واحدة',
  two: 'ساعتان',
  few: 'ساعات',
  many: 'ساعة',
);

class _Arabic extends LocalizationsDelegate<ExpressiveLocalizations> {
  const _Arabic();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ar';

  @override
  Future<ExpressiveLocalizations> load(Locale locale) =>
      SynchronousFuture<ExpressiveLocalizations>(
        const ExpressiveLocalizations(
          hours: _arabicHours,
          minutes: _arabicMinutes,
        ),
      );

  @override
  bool shouldReload(_Arabic old) => false;
}

/// A 24-hour picker at [hour]:[minute], its selectors' spoken names.
Future<void> _picker(
  WidgetTester tester,
  int hour,
  int minute, {
  Locale? locale,
}) async {
  final time = ExpressiveTimePickerController(
    hour: hour,
    minute: minute,
    is24Hour: true,
  );
  addTearDown(time.dispose);
  await tester.pumpWidget(
    _host(
      ExpressiveTimePicker(
        controller: time,
        layout: ExpressiveTimePickerLayout.vertical,
      ),
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

/// Some node's label holds [words] as a whole count (not the tail of a
/// longer number: "1 hour" is not in "21 hours").
Finder _says(String words) => find.bySemanticsLabel(
  RegExp('(^|[^0-9])${RegExp.escape(words)}(\$|[^\\p{L}])', unicode: true),
);

void main() {
  test('English counts: one and other', () {
    const en = ExpressiveLocalizations.english;
    expect([en.minutes(1), en.minutes(2)], ['1 minute', '2 minutes']);
    expect([en.hours(1), en.hours(2)], ['1 hour', '2 hours']);
    expect(
      [en.codeInput(1), en.codeInput(6)],
      ['Code, 1 character', 'Code, 6 characters'],
    );
    expect(
      [en.allStepsDone(1), en.allStepsDone(4)],
      ['The step is done', 'All 4 steps done'],
    );
  });

  testWidgets('a time picker speaks 1 hour and 1 minute, 2 hours and 2 '
      'minutes', (tester) async {
    final semantics = tester.ensureSemantics();
    await _picker(tester, 1, 1);
    expect(_says('1 hour'), findsWidgets);
    expect(_says('1 minute'), findsWidgets);
    expect(_says('1 hours'), findsNothing);
    expect(_says('1 minutes'), findsNothing);
    await _picker(tester, 2, 2);
    expect(_says('2 hours'), findsWidgets);
    expect(_says('2 minutes'), findsWidgets);
    semantics.dispose();
  });

  testWidgets("in Arabic the picker's counts take Arabic's forms: one, two, "
      'few and many', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final n in <int>[1, 2, 3, 11]) {
      await _picker(tester, n, n, locale: const Locale('ar'));
      expect(_says(_arabicMinutes(n)), findsWidgets, reason: 'minute $n');
      expect(_says(_arabicHours(n)), findsWidgets, reason: 'hour $n');
    }
    expect(_arabicMinutes(1), 'دقيقة واحدة');
    expect(_arabicMinutes(2), 'دقيقتان');
    expect(_arabicMinutes(3), '3 دقائق');
    expect(_arabicMinutes(11), '11 دقيقة');
    semantics.dispose();
  });
}
