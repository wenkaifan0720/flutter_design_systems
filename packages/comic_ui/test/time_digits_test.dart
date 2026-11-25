// A time picker writes its hours and minutes in the app's digits, as Material's does with formatHour and
// formatMinute (Arabic's ٩ and ٠٥, Persian's ۹ and ۰۵), on either clock, at a phone's and a desktop's width, in
// either direction. A pager too narrow for its numbers says where it stands in the app's words and digits, as
// Material's pageRowsInfoTitle does. English reads as before. The hour stays left of the minutes in every language,
// as Material's time picker keeps them; AM or PM keeps its place on the reading side.
import 'package:comic_ui/comic_host.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _ascii = '0123456789';
const _digits = {'ar': '٠١٢٣٤٥٦٧٨٩', 'fa': '۰۱۲۳۴۵۶۷۸۹', 'en': _ascii};

// [ascii] in [language]'s digits.
String _in(String language, String ascii) => String.fromCharCodes(
  ascii.runes.map((r) {
    final i = _ascii.indexOf(String.fromCharCode(r));
    return i < 0 ? r : _digits[language]!.runes.elementAt(i);
  }),
);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required String language,
  double width = 390,
  bool h24 = false,
  TextDirection? direction,
}) async {
  await tester.runAsync(comicLoadFonts);
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: Locale(language),
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fa')],
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => builder(context),
      ),
      builder: (context, navigator) {
        Widget child = navigator!;
        if (direction != null) {
          child = Directionality(textDirection: direction, child: child);
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: h24),
          child: ComicHost(
            light: ComicThemeData.offset(),
            dark: ComicThemeData.offset(Brightness.dark),
            brightness: Brightness.light,
            child: child,
          ),
        );
      },
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(16), child: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Every line of words on screen, menus included.
List<String> _shown(WidgetTester tester) => [
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>())
    p.text.toPlainText(),
];

void main() {
  for (final language in ['ar', 'fa']) {
    for (final width in [390.0, 1440.0]) {
      for (final h24 in [false, true]) {
        for (final direction in TextDirection.values) {
          testWidgets(
            'a ComicTimePicker writes its figures in ${language == 'ar' ? 'Arabic' : 'Persian'} digits at ${width.round()}, '
            '${h24 ? '24' : '12'} hours, ${direction.name}',
            (tester) async {
              var time = const ComicTime(21, 5);
              await _pump(
                tester,
                StatefulBuilder(
                  builder: (context, setState) => ComicTimePicker(
                    value: time,
                    minuteStep: 5,
                    onChanged: (next) => setState(() => time = next),
                  ),
                ),
                language: language,
                width: width,
                h24: h24,
                direction: direction,
              );
              final hour = _in(language, h24 ? '21' : '9');
              final minute = _in(language, '05');
              expect(find.text(hour), findsOneWidget);
              expect(find.text(minute), findsOneWidget);
              expect(
                _shown(tester).where((s) => s.contains(RegExp('[0-9]'))),
                isEmpty,
              );

              // Each list, opened, writes every figure in the app's digits.
              await tester.tap(find.text(hour));
              await tester.pumpAndSettle();
              for (final h in h24 ? ['0', '13', '23'] : ['12', '1', '11']) {
                expect(find.text(_in(language, h)), findsWidgets);
              }
              expect(
                _shown(tester).where((s) => s.contains(RegExp('[0-9]'))),
                isEmpty,
              );
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await tester.pumpAndSettle();

              await tester.tap(find.text(minute));
              await tester.pumpAndSettle();
              for (final m in ['00', '30', '55']) {
                expect(find.text(_in(language, m)), findsWidgets);
              }
              expect(
                _shown(tester).where((s) => s.contains(RegExp('[0-9]'))),
                isEmpty,
              );
              // A choice in the app's digits is the same minute.
              await tester.tap(find.text(_in(language, '30')).last);
              await tester.pumpAndSettle();
              expect(time, const ComicTime(21, 30));
            },
          );
        }
      }
    }
  }

  for (final width in [390.0, 1440.0]) {
    for (final h24 in [false, true]) {
      testWidgets(
        'a ComicTimePicker in English reads as before at ${width.round()}, ${h24 ? '24' : '12'} hours',
        (tester) async {
          await _pump(
            tester,
            ComicTimePicker(
              value: const ComicTime(21, 5),
              minuteStep: 5,
              onChanged: (_) {},
            ),
            language: 'en',
            width: width,
            h24: h24,
          );
          expect(find.text(h24 ? '21' : '9'), findsOneWidget);
          expect(find.text('05'), findsOneWidget);
          await tester.tap(find.text(h24 ? '21' : '9'));
          await tester.pumpAndSettle();
          for (final h in h24 ? ['0', '9', '13', '23'] : ['12', '1', '11']) {
            expect(find.text(h), findsWidgets);
          }
          expect(find.text('09'), findsNothing);
        },
      );
    }
  }

  for (final (language, words) in [
    ('ar', '٦ من ١٢'),
    ('fa', '۶ از ۱۲'),
    ('en', 'Page 6 of 12'),
  ]) {
    testWidgets('a ComicPagination too narrow for its numbers says "$words"', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 240,
          child: ComicPagination(pageCount: 12, page: 5, onPageChanged: (_) {}),
        ),
        language: language,
      );
      expect(find.text(words), findsOneWidget);
    });
  }

  for (final width in [390.0, 1440.0]) {
    for (final h24 in [false, true]) {
      for (final (language, direction) in [
        ('ar', TextDirection.rtl),
        ('en', TextDirection.ltr),
      ]) {
        testWidgets(
          'a ComicTimePicker keeps its hour left of its minutes in $language, ${direction.name}, at ${width.round()}, '
          '${h24 ? '24' : '12'} hours',
          (tester) async {
            await _pump(
              tester,
              ComicTimePicker(
                value: const ComicTime(21, 5),
                minuteStep: 5,
                onChanged: (_) {},
              ),
              language: language,
              width: width,
              h24: h24,
              direction: direction,
            );
            Rect at(String words) => tester.getRect(
              find
                  .ancestor(
                    of: find.text(words),
                    matching: find.byType(ComicSelect<int>),
                  )
                  .first,
            );
            final hour = at(_in(language, h24 ? '21' : '9'));
            final minute = at(_in(language, '05'));
            expect(hour.right, lessThanOrEqualTo(minute.left));
            if (!h24) {
              final period = at(language == 'ar' ? 'م' : 'PM');
              if (direction == TextDirection.rtl) {
                expect(period.right, lessThanOrEqualTo(hour.left));
              } else {
                expect(period.left, greaterThanOrEqualTo(minute.right));
              }
            }
          },
        );
      }
    }
  }
}
