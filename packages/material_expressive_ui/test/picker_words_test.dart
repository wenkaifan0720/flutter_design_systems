/// The pickers' words in the app's language. [ExpressiveLocalizations.delegate]
/// loads English for every locale and ui_core says no picker titles, so an
/// Arabic app's date picker said "Select date" over its Arabic days. Where
/// the look's words are its English ones, the words Material's pickers say
/// too are the app's `MaterialLocalizations`' (an app in another language
/// lists `GlobalMaterialLocalizations.delegates`), as Material's own pickers
/// read them (an app that gives none has the theme's: material_ui's in its
/// language); an app's own words still win, and over Material's English the
/// look keeps its own.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// An app's Material words in Arabic, as its localizations give them.
class _ArabicMaterial extends DefaultMaterialLocalizations {
  const _ArabicMaterial();

  @override
  String get datePickerHelpText => 'اختيار التاريخ';
  @override
  String get dateRangePickerHelpText => 'اختيار النطاق';
  @override
  String get dateRangeStartLabel => 'تاريخ البدء';
  @override
  String get dateRangeEndLabel => 'تاريخ الانتهاء';
  @override
  String get unspecifiedDate => 'التاريخ';
  @override
  String get inputDateModeButtonLabel => 'التبديل إلى الإدخال';
  @override
  String get calendarModeButtonLabel => 'التبديل إلى التقويم';
  @override
  String get selectYearSemanticsLabel => 'اختيار العام';
  @override
  String get dateOutOfRangeLabel => 'خارج النطاق.';
  @override
  String get invalidDateRangeLabel => 'نطاق غير صالح.';
  @override
  String get timePickerDialHelpText => 'اختيار الوقت';
  @override
  String get timePickerInputHelpText => 'إدخال الوقت';
  @override
  String get timePickerHourModeAnnouncement => 'اختيار الساعات';
  @override
  String get timePickerMinuteModeAnnouncement => 'اختيار الدقائق';
  @override
  String get inputTimeModeButtonLabel => 'التبديل إلى وضع إدخال النص';
  @override
  String get dialModeButtonLabel => 'التبديل إلى وضع القرص';
}

class _Gives<T> extends LocalizationsDelegate<T> {
  const _Gives(this.words);

  final T words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture(words);

  @override
  bool shouldReload(_Gives<T> old) => false;
}

/// Each word of the look's that Material's pickers say too, with Material's.
final _pairs =
    <
      (
        String,
        String Function(ExpressiveLocalizations words),
        String Function(MaterialLocalizations words),
      )
    >[
      ('selectDate', (w) => w.selectDate, (m) => m.datePickerHelpText),
      ('selectDates', (w) => w.selectDates, (m) => m.dateRangePickerHelpText),
      ('enterDates', (w) => w.enterDates, (m) => m.dateRangePickerHelpText),
      ('startDate', (w) => w.startDate, (m) => m.dateRangeStartLabel),
      ('endDate', (w) => w.endDate, (m) => m.dateRangeEndLabel),
      ('date', (w) => w.date, (m) => m.unspecifiedDate),
      ('toDateInput', (w) => w.toDateInput, (m) => m.inputDateModeButtonLabel),
      ('toCalendar', (w) => w.toCalendar, (m) => m.calendarModeButtonLabel),
      ('toYears', (w) => w.toYears, (m) => m.selectYearSemanticsLabel),
      ('dateNotAllowed', (w) => w.dateNotAllowed, (m) => m.dateOutOfRangeLabel),
      (
        'endBeforeStart',
        (w) => w.endBeforeStart,
        (m) => m.invalidDateRangeLabel,
      ),
      ('selectTime', (w) => w.selectTime, (m) => m.timePickerDialHelpText),
      ('enterTime', (w) => w.enterTime, (m) => m.timePickerInputHelpText),
      (
        'selectHour',
        (w) => w.selectHour,
        (m) => m.timePickerHourModeAnnouncement,
      ),
      (
        'selectMinute',
        (w) => w.selectMinute,
        (m) => m.timePickerMinuteModeAnnouncement,
      ),
      ('toKeyboard', (w) => w.toKeyboard, (m) => m.inputTimeModeButtonLabel),
      ('toDial', (w) => w.toDial, (m) => m.dialModeButtonLabel),
    ];

/// The words a picker reads in a [locale] app with [delegates]; [body] under
/// them.
Future<ExpressiveLocalizations> _words(
  WidgetTester tester,
  Locale locale,
  List<LocalizationsDelegate<Object?>> delegates, {
  Widget Function(BuildContext context)? body,
}) async {
  late ExpressiveLocalizations words;
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xff000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: delegates,
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => ExpressiveHost(
        theme: _theme,
        brightness: Brightness.light,
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          words = ExpressiveLocalizations.of(context);
          return body?.call(context) ?? const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return words;
}

void main() {
  setUpAll(expressiveLoadFonts);

  testWidgets("an Arabic app's pickers say its Material words, and its date "
      "picker's title is Arabic", (tester) async {
    const arabic = _ArabicMaterial();
    final words = await _words(
      tester,
      const Locale('ar'),
      const [
        ExpressiveLocalizations.delegate,
        _Gives<MaterialLocalizations>(arabic),
      ],
      body: (context) => Center(
        child: ExpressiveFilledButton(
          'Open',
          onPressed: () => showExpressiveDatePicker(
            context: context,
            initialDate: DateTime(2026, 11, 20),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
          ),
        ),
      ),
    );
    for (final (name, look, material) in _pairs) {
      expect(look(words), material(arabic), reason: name);
    }
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text(arabic.datePickerHelpText), findsOneWidget);
    expect(find.text(ExpressiveLocalizations.english.selectDate), findsNothing);
  });

  testWidgets("over Material's English the look keeps its own words", (
    tester,
  ) async {
    final words = await _words(tester, const Locale('en'), const [
      ExpressiveLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
    ]);
    for (final (name, look, _) in _pairs) {
      expect(look(words), look(ExpressiveLocalizations.english), reason: name);
    }
    // Where Material says it otherwise in English, still the look's.
    expect(words.selectDates, 'Select dates');
    expect(words.toDateInput, 'Type a date');
  });

  testWidgets("an app's own words win over its Material words", (tester) async {
    final words = await _words(tester, const Locale('ar'), const [
      _Gives<ExpressiveLocalizations>(
        ExpressiveLocalizations(selectDate: 'اختر يوماً'),
      ),
      _Gives<MaterialLocalizations>(_ArabicMaterial()),
    ]);
    expect(words.selectDate, 'اختر يوماً');
    // The rest of an app's own set is its own, English where it gives none.
    expect(words.selectDates, ExpressiveLocalizations.english.selectDates);
  });

  testWidgets("an app that gives no Material words has the theme's: the "
      'look says them where they are not English', (tester) async {
    late MaterialLocalizations material;
    final words = await _words(
      tester,
      const Locale('ar'),
      const [ExpressiveLocalizations.delegate],
      body: (context) {
        material = MaterialLocalizations.of(context);
        return const SizedBox();
      },
    );
    const english = DefaultMaterialLocalizations();
    for (final (name, look, word) in _pairs) {
      expect(
        look(words),
        word(material) == word(english)
            ? look(ExpressiveLocalizations.english)
            : word(material),
        reason: name,
      );
    }
  });
}
