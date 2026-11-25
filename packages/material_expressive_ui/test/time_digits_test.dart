/// A time picker writes its figures in the app's digits, as Material's
/// `formatHour` and `formatMinute` write a time picker's: in Arabic 21:05
/// shows ٠٩ and ٠٥ on its selectors, its fields and its wheels (٢١ on the
/// 24-hour clock), its dial reads ١٢, ١ … ١١ and ٠, ٥ … ٥٥, and a field takes
/// ٠٧ and 07 typed alike. Persian writes ۰۹ and ۰۵. The date picker's year
/// grid writes ٢٠٢٩ (Material's `formatYear`), and a preview's status bar
/// its clock (٧:٣١). English keeps 09, 05, 12 … 11 and 2029.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

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

/// Every text on screen: a label's, a rich text's and a field's.
Set<String> _shown(WidgetTester tester) => <String>{
  for (final widget in tester.allWidgets)
    if (widget is Text)
      widget.data ?? widget.textSpan!.toPlainText()
    else if (widget is RichText)
      widget.text.toPlainText()
    else if (widget is EditableText)
      widget.controller.text,
};

/// [figures] show in [language]'s digits, and none in Western digits unless
/// that is the language's.
void _expectFigures(
  WidgetTester tester,
  String language,
  List<String> figures,
) {
  final shown = _shown(tester);
  for (final figure in figures) {
    expect(shown, contains(_in(language, figure)), reason: figure);
    if (language != 'en') {
      expect(
        shown,
        isNot(contains(figure)),
        reason: '$figure in Western digits',
      );
    }
  }
}

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

Future<void> _pump(WidgetTester tester, _Case c, Widget home) async {
  tester.view.physicalSize = Size(c.width, c.width < 600 ? 844 : 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final locale = Locale(c.language);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xff000000),
      locale: locale,
      supportedLocales: <Locale>[locale],
      localizationsDelegates: const <LocalizationsDelegate<Object?>>[
        RawWidgetsLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(alwaysUse24HourFormat: c.twentyFour),
        child: Directionality(
          textDirection: c.direction,
          child: ExpressiveHost(
            theme: _theme,
            brightness: Brightness.light,
            child: child!,
          ),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens a time picker at 21:05 on [mode]'s face.
Future<void> _openTime(
  WidgetTester tester,
  _Case c,
  ExpressiveTimePickerMode mode,
) async {
  await _pump(
    tester,
    c,
    Center(
      child: Builder(
        builder: (context) => ExpressiveTextButton(
          'Time',
          onPressed: () => showExpressiveTimePicker(
            context: context,
            initialHour: 21,
            initialMinute: 5,
            initialMode: mode,
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Time'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(expressiveLoadFonts);

  group('a time picker writes the app\'s digits', () {
    for (final c in _cases) {
      final hour = c.twentyFour ? '21' : '09';
      testWidgets('on its selectors and its dial, ${_name(c)}', (tester) async {
        await _openTime(tester, c, ExpressiveTimePickerMode.dial);
        _expectFigures(tester, c.language, <String>[hour, '05']);
        _expectFigures(
          tester,
          c.language,
          c.twentyFour
              ? <String>['0', '1', '11', '13', '23']
              : <String>['12', '1', '11'],
        );
        await tester.tap(find.text(_in(c.language, '05')));
        await tester.pumpAndSettle();
        _expectFigures(tester, c.language, <String>['0', '5', '30', '55']);
      });

      testWidgets('in its fields, and takes both digit sets, ${_name(c)}', (
        tester,
      ) async {
        ({int hour, int minute})? result;
        await _pump(
          tester,
          c,
          Center(
            child: Builder(
              builder: (context) => ExpressiveTextButton(
                'Time',
                onPressed: () async => result = await showExpressiveTimePicker(
                  context: context,
                  initialHour: 21,
                  initialMinute: 5,
                  initialMode: ExpressiveTimePickerMode.input,
                  confirmLabel: 'OK',
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Time'));
        await tester.pumpAndSettle();
        _expectFigures(tester, c.language, <String>[hour, '05']);
        final fields = find.byType(EditableText);
        await tester.enterText(fields.first, _in(c.language, '07'));
        await tester.pumpAndSettle();
        await tester.enterText(fields.last, '42');
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(result, (hour: c.twentyFour ? 7 : 19, minute: 42));
      });

      testWidgets('on its wheels, ${_name(c)}', (tester) async {
        await _openTime(tester, c, ExpressiveTimePickerMode.scroll);
        _expectFigures(tester, c.language, <String>[hour, '05', '06']);
      });

      testWidgets('on the date picker\'s year grid, ${_name(c)}', (
        tester,
      ) async {
        await _pump(
          tester,
          c,
          Center(
            child: Builder(
              builder: (context) => ExpressiveTextButton(
                'Due',
                onPressed: () => showExpressiveDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 11, 20),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030, 12, 31),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Due'));
        await tester.pumpAndSettle();
        final words = RawWidgetsLocalizations.of(
          tester.element(find.byType(ExpressiveTextButton).first),
        );
        await tester.tap(find.text(words.formatMonthYear(DateTime(2026, 11))));
        await tester.pumpAndSettle();
        _expectFigures(tester, c.language, <String>['2021', '2029']);
      });

      testWidgets('on a preview\'s status bar, ${_name(c)}', (tester) async {
        await _pump(
          tester,
          c,
          ExpressivePreview(
            clock: DateTime(2026, 11, 24, 19, 31),
            child: const SizedBox.expand(),
          ),
        );
        // Persian's clock is the 24-hour one; Arabic's and English's the
        // 12-hour one.
        _expectFigures(tester, c.language, <String>[
          c.language == 'fa' ? '19:31' : '7:31',
        ]);
      });
    }
  });
}
