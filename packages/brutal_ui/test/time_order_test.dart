// A time picker's wheels keep hours before minutes, left to right, in
// either direction, as Material's time picker keeps them and as the time
// reads in a line of text ("٠٩:٠٥"): in Arabic, right to left, the hour's
// wheel stands left of the minutes', at a phone's width and a desktop's.
// And a pager whose gap would hide one page shows that page instead.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required TextDirection direction,
  required Widget child,
  Locale locale = const Locale('ar'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, _) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: BrutalThemeData.light(),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _x(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text).last).dx;

/// The pager's cells in order: each cell's words once (a cell draws them
/// twice, its face and the face it presses to).
List<String> _cells(WidgetTester tester) {
  final cells = <String>[];
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>()) {
    final s = p.text.toPlainText();
    // Pages and gaps; the arrows are icons.
    if (!s.contains(RegExp('[0-9٠-٩…]'))) continue;
    if (cells.isEmpty || cells.last != s) cells.add(s);
  }
  return cells;
}

Widget get _picker => BrutalTimePicker(
  value: const BrutalTime(hour: 9, minute: 5),
  onChanged: (_) {},
);

void main() {
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('ar, ${size.width.toInt()} wide, right to left: the hour '
        'wheel stands left of the minutes', (tester) async {
      await _pump(
        tester,
        size: size,
        direction: TextDirection.rtl,
        child: _picker,
      );
      expect(_x(tester, '٠٩'), lessThan(_x(tester, '٠٥')));
    });
  }

  testWidgets('en, left to right: hours before minutes, as before', (
    tester,
  ) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      direction: TextDirection.ltr,
      locale: const Locale('en'),
      child: _picker,
    );
    expect(_x(tester, '09'), lessThan(_x(tester, '05')));
  });

  // Page 3 of 12 on a phone: 1 2 3 … 12, not 1 … 3 … 12.
  for (final (lang, direction, cells) in const [
    ('ar', TextDirection.rtl, ['١', '٢', '٣', '…', '١٢']),
    ('en', TextDirection.ltr, ['1', '2', '3', '…', '12']),
  ]) {
    testWidgets('$lang, a phone: a gap of one page shows that page', (
      tester,
    ) async {
      await _pump(
        tester,
        size: const Size(390, 844),
        direction: direction,
        locale: Locale(lang),
        child: BrutalPagination(page: 3, pageCount: 12, onPageChanged: (_) {}),
      );
      expect(_cells(tester), cells);
    });
  }

  testWidgets('a gap of more than one page keeps its ellipsis', (tester) async {
    await _pump(
      tester,
      size: const Size(390, 844),
      direction: TextDirection.ltr,
      locale: const Locale('en'),
      child: BrutalPagination(page: 6, pageCount: 12, onPageChanged: (_) {}),
    );
    expect(_cells(tester), ['1', '…', '6', '…', '12']);
  });
}
