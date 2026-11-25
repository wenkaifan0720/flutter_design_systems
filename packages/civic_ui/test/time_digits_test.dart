// The wheel picker's hours and minutes in the gallery and the inventory are written in the app's digits, as
// Material's time picker writes them with formatHour and formatMinute: Arabic's ٠٩ and ٣٠, Persian's ۹ and ۳۰, on
// a phone and a desktop, in either direction, whatever the device's clock. English reads as before (09, 30). The
// hour stays left of the minutes in every language, as Material's time picker keeps them.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/demos/dates.dart';
import '../example/lib/kit_gallery/gallery_words.dart';
import '../example/lib/kit_gallery/kit.dart';

// The wheel's hour 9 and minute 30, as each language writes them on its 24-hour clock.
const _expected = {'ar': ('٠٩', '٣٠'), 'fa': ('۹', '۳۰'), 'en': ('09', '30')};

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required String language,
  double width = 390,
  bool h24 = false,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      localizationsDelegates: galleryDelegates,
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      builder: (context, child) {
        Widget page = CivicTheme(
          data: kitTheme(Brightness.light),
          child: child ?? const SizedBox.shrink(),
        );
        if (direction != null) {
          page = Directionality(textDirection: direction, child: page);
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
          child: page,
        );
      },
      home: home,
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

// The words the wheel draws.
List<String> _wheel(WidgetTester tester) => [
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.descendant(
      of: find.byType(CivicWheelPicker),
      matching: find.byType(RichText),
    ),
  ))
    p.text.toPlainText(),
];

Widget _inventoryWheel() => Padding(
  padding: const EdgeInsets.all(CivicSpacing.s20),
  child: Align(
    alignment: AlignmentDirectional.topStart,
    child: Builder(
      builder: civicInventory.entries
          .firstWhere((e) => e.row == 'WheelPicker')
          .builder!,
    ),
  ),
);

void main() {
  for (final language in ['ar', 'fa']) {
    for (final width in [390.0, 1440.0]) {
      for (final h24 in [false, true]) {
        for (final direction in TextDirection.values) {
          testWidgets(
            "the inventory's wheel picker writes ${language == 'ar' ? 'Arabic' : 'Persian'} digits at "
            "${width.round()}, device clock ${h24 ? '24' : '12'} hours, ${direction.name}",
            (tester) async {
              await _pump(
                tester,
                _inventoryWheel(),
                language: language,
                width: width,
                h24: h24,
                direction: direction,
              );
              final (hour, minute) = _expected[language]!;
              final shown = _wheel(tester);
              expect(shown, containsAll([hour, minute]));
              expect(shown.where((s) => s.contains(RegExp('[0-9]'))), isEmpty);
            },
          );
        }
      }
    }
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      "the inventory's wheel picker in English reads as before at ${width.round()}",
      (tester) async {
        await _pump(tester, _inventoryWheel(), language: 'en', width: width);
        expect(_wheel(tester), containsAll(['08', '09', '10', '15', '30']));
      },
    );

    // The gallery's own app: right to left is its Arabic edition.
    for (final direction in TextDirection.values) {
      testWidgets(
        "the gallery's wheel picker at ${width.round()}, ${direction.name}",
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            Directionality(
              textDirection: direction,
              child: kitApp(
                brightness: Brightness.light,
                direction: direction,
                home: kitDatesDemo(Brightness.light),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          await tester.scrollUntilVisible(
            find.byType(CivicWheelPicker),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 500));
          final (hour, minute) =
              _expected[direction == TextDirection.rtl ? 'ar' : 'en']!;
          final shown = _wheel(tester);
          expect(shown, containsAll([hour, minute]));
          if (direction == TextDirection.rtl) {
            expect(shown.where((s) => s.contains(RegExp('[0-9]'))), isEmpty);
          }
        },
      );
    }
  }

  // The hour's column left of the minutes', in Arabic right to left as in English.
  Rect at(WidgetTester tester, String words) => tester.getRect(
    find
        .descendant(
          of: find.byType(CivicWheelPicker),
          matching: find.text(words),
        )
        .first,
  );
  for (final width in [390.0, 1440.0]) {
    for (final (language, direction) in [
      ('ar', TextDirection.rtl),
      ('en', TextDirection.ltr),
    ]) {
      testWidgets(
        "the inventory's wheel picker keeps its hour left of its minutes in $language, ${direction.name}, at "
        '${width.round()}',
        (tester) async {
          await _pump(
            tester,
            _inventoryWheel(),
            language: language,
            width: width,
            direction: direction,
          );
          final (hour, minute) = _expected[language]!;
          expect(at(tester, hour).right, lessThan(at(tester, minute).left));
        },
      );
      testWidgets(
        "the gallery's wheel picker keeps its hour left of its minutes in $language, ${direction.name}, at "
        '${width.round()}',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            Directionality(
              textDirection: direction,
              child: kitApp(
                brightness: Brightness.light,
                direction: direction,
                home: kitDatesDemo(Brightness.light),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          await tester.scrollUntilVisible(
            find.byType(CivicWheelPicker),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pump(const Duration(milliseconds: 500));
          final (hour, minute) = _expected[language]!;
          expect(at(tester, hour).right, lessThan(at(tester, minute).left));
          // A turn of the minutes' column (the right one) moves the minutes and leaves the hour: the gallery keeps
          // its selection hour first whichever way the columns run.
          await tester.drag(
            find
                .descendant(
                  of: find.byType(CivicWheelPicker),
                  matching: find.text(minute),
                )
                .first,
            const Offset(0, -60),
          );
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byType(CivicWheelPicker),
              matching: find.text(hour),
            ),
            findsWidgets,
          );
        },
      );
    }
  }
}
