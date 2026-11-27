// A time picker writes its times in the app's digits, as Material's time
// picker writes formatHour and formatMinute: in Arabic Fluent2TimePicker's
// field and list say ٩:٣٠ م (٢١:٣٠ on the 24-hour clock) and
// showFluent2TimePicker's wheels ٢١ and ٠٥; Persian writes ۹:۳۰ and ۰۵.
// English keeps 9:30 PM, 21:30, 21 and 05.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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

Future<void> _pump(WidgetTester t, _Case c, Widget home) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(c.width, c.width < 600 ? 844 : 900);
  addTearDown(t.view.reset);
  final locale = Locale(c.language);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: <Locale>[locale],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        Fluent2Localizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: c.twentyFour),
        child: Directionality(
          textDirection: c.direction,
          child: Fluent2Host(child: child!),
        ),
      ),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, _, _) => home,
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

void main() {
  group('a time picker writes the app\'s digits', () {
    for (final c in _cases) {
      testWidgets('in Fluent2TimePicker\'s field and list, ${_name(c)}', (
        t,
      ) async {
        await _pump(
          t,
          c,
          Center(
            child: SizedBox(
              width: 280,
              child: Fluent2TimePicker(
                value: const Fluent2Time(21, 30),
                onChanged: (_) {},
              ),
            ),
          ),
        );
        _expectFigures(t, c.language, <String>[
          c.twentyFour ? '21:30' : '9:30',
        ]);
        if (c.language == 'en') {
          expect(_shown(t), contains(c.twentyFour ? '21:30' : '9:30 PM'));
        }
        await t.tap(find.byType(Fluent2TimePicker));
        await t.pumpAndSettle();
        _expectFigures(t, c.language, <String>[
          c.twentyFour ? '21:30' : '9:30',
          c.twentyFour ? '22:00' : '10:00',
        ]);
      });

      testWidgets('with the hour wheel left of the minutes, ${_name(c)}', (
        t,
      ) async {
        await _pump(
          t,
          c,
          Center(
            child: Builder(
              builder: (context) => Fluent2Button(
                'Time',
                onPressed: () => showFluent2TimePicker(
                  context,
                  value: const Fluent2Time(21, 5),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Time'));
        await t.pumpAndSettle();
        // The wheels in build order: the hour's, then the minutes'.
        final wheels = find.byType(Fluent2WheelPicker<int>);
        expect(wheels, findsNWidgets(2));
        expect(
          t.getCenter(wheels.at(0)).dx,
          lessThan(t.getCenter(wheels.at(1)).dx),
          reason:
              'the hour wheel stands left of the minutes in ${c.direction.name}',
        );
      });

      testWidgets('on showFluent2TimePicker\'s wheels, ${_name(c)}', (t) async {
        await _pump(
          t,
          c,
          Center(
            child: Builder(
              builder: (context) => Fluent2Button(
                'Time',
                onPressed: () => showFluent2TimePicker(
                  context,
                  value: const Fluent2Time(21, 5),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Time'));
        await t.pumpAndSettle();
        _expectFigures(t, c.language, <String>['21', '05', '06']);
        if (c.language == 'en') {
          expect(_shown(t), containsAll(<String>['21', '05']));
        }
      });
    }
  });
}
