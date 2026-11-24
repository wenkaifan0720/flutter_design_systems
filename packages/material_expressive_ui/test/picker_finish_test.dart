/// The date picker's and the calendar's finish, measured from their rects.
/// At 390 the date dialog's header divider stopped 3dp short of its edges (a
/// margin round the picker); under compact density (a desktop's) the month
/// stood 4dp before the title and the headline; on a calendar wider than
/// seven 48dp columns its arrows stood off the last two; and the calendar
/// headed its columns "Su Mo" where the picker heads them "S M".
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

Future<void> _app(
  WidgetTester tester,
  Size size,
  Widget Function(BuildContext context) home, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: ExpressiveHost(brightness: Brightness.light, child: child!),
      ),
      home: Builder(builder: home),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openPicker(
  WidgetTester tester,
  Size size, {
  TextDirection direction = TextDirection.ltr,
}) async {
  await _app(
    tester,
    size,
    direction: direction,
    (context) => Center(
      child: ExpressiveFilledButton(
        'Open',
        onPressed: () => showExpressiveDatePicker(
          context: context,
          initialDate: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          currentDate: DateTime(2026, 11, 18),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// The centres of the two month arrows, in their order on the screen.
List<double> _arrows(WidgetTester tester, Finder within) => [
  for (final e
      in find
          .descendant(of: within, matching: find.byType(ExpressiveIconButton))
          .evaluate())
    tester.getCenter(find.byWidget(e.widget)).dx,
]..sort();

void main() {
  setUpAll(expressiveLoadFonts);

  testWidgets("at 390 the date dialog's header divider runs edge to edge", (
    tester,
  ) async {
    await _openPicker(tester, const Size(390, 844));
    final dialog = tester.getRect(find.byType(ExpressiveDatePickerDialog));
    final divider = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_Divider',
    );
    expect(divider, findsOneWidget);
    final line = tester.getRect(divider);
    expect(line.left, moreOrLessEquals(dialog.left));
    expect(line.right, moreOrLessEquals(dialog.right));
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      "the picker header's title, headline and month stand on one start "
      'line at every density (${direction.name})',
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
      (tester) async {
        for (final width in [390.0, 1440.0]) {
          await _openPicker(tester, Size(width, 900), direction: direction);
          double start(String text) {
            final r = tester.getRect(find.text(text));
            return direction == TextDirection.ltr ? r.left : r.right;
          }

          final title = start('Select date');
          expect(
            start('20 Nov 2026'),
            moreOrLessEquals(title),
            reason: '$width',
          );
          expect(
            start('November 2026'),
            moreOrLessEquals(title),
            reason: '$width',
          );
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }

  for (final direction in TextDirection.values) {
    for (final width in [336.0, 400.0, 480.0]) {
      testWidgets(
        "a ${width.round()}dp calendar's arrows stand on its last two "
        'columns (${direction.name})',
        (tester) async {
          await _app(
            tester,
            const Size(1440, 900),
            direction: direction,
            (context) => Center(
              child: SizedBox(
                width: width,
                child: ExpressiveCalendar(
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                  value: DateTime(2026, 11, 20),
                  firstDayOfWeek: DateTime.sunday,
                  onChanged: (_) {},
                ),
              ),
            ),
          );
          // November 2026 starts on a Sunday: the 6th and 7th are the week's
          // last two columns.
          final columns = [
            tester.getCenter(find.text('6')).dx,
            tester.getCenter(find.text('7')).dx,
          ]..sort();
          final arrows = _arrows(tester, find.byType(ExpressiveCalendar));
          expect(arrows, hasLength(2));
          for (var i = 0; i < 2; i++) {
            expect(arrows[i], moreOrLessEquals(columns[i]), reason: '$i');
          }
        },
      );
    }
  }

  testWidgets("the 360dp picker's arrows stand on its last two columns", (
    tester,
  ) async {
    await _openPicker(tester, const Size(1440, 900));
    final columns = [
      tester.getCenter(find.text('6')).dx,
      tester.getCenter(find.text('7')).dx,
    ];
    final picker = find.byType(ExpressiveDatePicker);
    final arrows = _arrows(tester, picker)
      ..removeWhere((x) => x < tester.getRect(picker).center.dx);
    // The headline's mode toggle stands at the end too, above the arrows.
    expect(arrows, containsAll(columns));
  });

  testWidgets('the calendar heads its columns with the picker\'s letters, '
      "M3's narrow S M T W T F S", (tester) async {
    List<String> letters(Finder within) {
      final row = <(double, String)>[
        for (final e
            in find
                .descendant(of: within, matching: find.byType(Text))
                .evaluate())
          if ((e.widget as Text).data case final String s?
              when s.length <= 2 && int.tryParse(s) == null)
            (tester.getCenter(find.byWidget(e.widget)).dx, s),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      return [for (final (_, s) in row) s];
    }

    await _app(
      tester,
      const Size(1440, 900),
      (context) => Center(
        child: SizedBox(
          width: 400,
          child: ExpressiveCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            value: DateTime(2026, 11, 20),
            firstDayOfWeek: DateTime.sunday,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final calendar = letters(find.byType(ExpressiveCalendar));
    expect(calendar, ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
    await tester.pumpWidget(const SizedBox());
    await _openPicker(tester, const Size(1440, 900));
    expect(letters(find.byType(ExpressiveDatePicker)), calendar);
  });
}
