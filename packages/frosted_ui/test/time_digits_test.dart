// A time picker writes its times in the app's digits, as Material's time
// picker writes formatHour and formatMinute: in Arabic FrostedTimePicker's
// wheels say ٩ (٢١ on the 24-hour clock) and ٠٥, and FrostedTime.format
// writes ٩:٠٥ even with an app's own words for the halves of the day;
// Persian writes ۹ and ۰۵. English keeps 9, 21, 05 and 9:05 PM. The hour
// wheel stands left of the minutes in a right-to-left app too.
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

final RegExp _western = RegExp('[0-9]');

/// Each language's zero: its other nine digits follow it.
const Map<String, int> _zero = <String, int>{
  'en': 0x30,
  'ar': 0x0660,
  'fa': 0x06F0,
};

/// [ascii] in [language]'s digits.
String _in(String language, String ascii) => String.fromCharCodes(
  ascii.codeUnits.map(
    (c) => c >= 0x30 && c <= 0x39 ? _zero[language]! + c - 0x30 : c,
  ),
);

/// Material's words in English for any language: the Frosted parts read
/// only the scrim's label from them.
class _AnyMaterial extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyMaterial();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_AnyMaterial old) => false;
}

/// Cupertino's words in English for any language, as MaterialApp asks.
class _AnyCupertino extends LocalizationsDelegate<CupertinoLocalizations> {
  const _AnyCupertino();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_AnyCupertino old) => false;
}

/// An app's own Frosted words: its halves of the day.
class _OwnHalves extends FrostedLocalizationsEn {
  const _OwnHalves();

  @override
  String get am => 'morning';

  @override
  String get pm => 'evening';
}

class _OwnHalvesDelegate extends LocalizationsDelegate<FrostedLocalizations> {
  const _OwnHalvesDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FrostedLocalizations> load(Locale locale) =>
      SynchronousFuture<FrostedLocalizations>(const _OwnHalves());

  @override
  bool shouldReload(_OwnHalvesDelegate old) => false;
}

/// Every text drawn on the page.
List<String> _shown(WidgetTester t) => <String>[
  for (final e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
];

typedef _Case = ({
  String language,
  double width,
  TextDirection direction,
  bool twentyFour,
});

String _name(_Case c) =>
    '${c.language} at ${c.width.round()}, ${c.direction.name}, '
    '${c.twentyFour ? '24' : '12'}-hour';

final List<_Case> _cases = <_Case>[
  for (final language in <String>['ar', 'fa'])
    for (final width in <double>[390, 1440])
      for (final direction in TextDirection.values)
        for (final twentyFour in <bool>[false, true])
          (
            language: language,
            width: width,
            direction: direction,
            twentyFour: twentyFour,
          ),
  for (final width in <double>[390, 1440])
    for (final twentyFour in <bool>[false, true])
      (
        language: 'en',
        width: width,
        direction: TextDirection.ltr,
        twentyFour: twentyFour,
      ),
];

Future<void> _pump(
  WidgetTester t,
  _Case c,
  Widget home, {
  bool ownWords = false,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(c.width, 900);
  addTearDown(t.view.reset);
  final locale = Locale(c.language);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: <Locale>[locale],
      localizationsDelegates: [
        RawWidgetsLocalizations.delegate,
        if (ownWords)
          const _OwnHalvesDelegate()
        else
          FrostedLocalizations.delegate,
        const _AnyMaterial(),
        const _AnyCupertino(),
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: c.twentyFour),
        child: Directionality(
          textDirection: c.direction,
          child: FrostedHost(child: page!),
        ),
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(16), child: home),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// [figures] show, in [language]'s digits; in Arabic and Persian no
/// Western digit shows anywhere.
void _expectFigures(WidgetTester t, String language, List<String> figures) {
  final shown = _shown(t);
  for (final figure in figures) {
    expect(
      shown.any((s) => s.contains(_in(language, figure))),
      isTrue,
      reason: '${_in(language, figure)} in $shown',
    );
  }
  if (language != 'en') {
    expect(shown.where(_western.hasMatch), isEmpty, reason: '$shown');
  }
}

/// The centre of the first text that reads [text] exactly.
Offset _at(WidgetTester t, String text) => t.getCenter(
  find
      .byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == text)
      .first,
);

void main() {
  group('a time picker writes the app\'s digits', () {
    for (final c in _cases) {
      testWidgets('on FrostedTimePicker\'s wheels, ${_name(c)}', (t) async {
        await _pump(
          t,
          c,
          FrostedTimePicker(
            value: const FrostedTime(hour: 21, minute: 5),
            onChanged: (_) {},
          ),
        );
        final hour = c.twentyFour ? '21' : '9';
        _expectFigures(t, c.language, <String>[hour, '05', '06']);
        // Hour, then minutes, left to right in either direction.
        expect(
          _at(t, _in(c.language, hour)).dx,
          lessThan(_at(t, _in(c.language, '05')).dx),
        );
      });

      for (final own in <bool>[false, true]) {
        testWidgets(
          'in FrostedTime.format${own ? ' with the app\'s own '
                    'words' : ''}, ${_name(c)}',
          (t) async {
            await _pump(
              t,
              c,
              Builder(
                builder: (context) => Text(
                  const FrostedTime(hour: 21, minute: 5).format(context),
                ),
              ),
              ownWords: own,
            );
            // The installed words in another language are ui_core's own
            // formatTimeOfDay, on that language's clock (Persian's is 24
            // hours); the app's own words keep the clock the app asked for.
            _expectFigures(t, c.language, <String>[
              if (own || c.language == 'en' || c.twentyFour)
                c.twentyFour ? '21:05' : '9:05'
              else
                ':05',
            ]);
            if (c.language == 'en') {
              expect(
                _shown(t),
                contains(
                  c.twentyFour
                      ? '21:05'
                      : own
                      ? '9:05 evening'
                      : '9:05 PM',
                ),
              );
            }
          },
        );
      }
    }
  });
}
