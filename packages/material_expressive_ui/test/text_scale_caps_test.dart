/// The parts that cap their text where Material's do, read whole at 1x, 2x
/// and 3x text: a bar's and a rail's destinations at 1.3x (NavigationBar),
/// a date picker's header at 1.6x (1.4x while a date is typed) and its
/// weekday letters at 2x (the day picker). Past those, at 300% text, a bar
/// cut its count and broke its words ("Toda/y"), the drawer dropped its
/// selected label, the header cut the chosen date ("18 S…") and the
/// weekday letters lost their lower edge.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

const _scales = <double>[1, 2, 3];

Future<void> _pump(
  WidgetTester tester,
  double scale,
  Widget child, {
  double width = 390,
}) async {
  const height = 844.0;
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ExpressiveHost(
      theme: _theme,
      brightness: Brightness.light,
      child: ExpressiveTheme(
        data: _theme,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              textScaler: TextScaler.linear(scale),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// [text] drawn whole at [scale] capped at [cap]: on one line as wide as its
/// words, nothing cut, and inside [within] where given.
void _whole(
  WidgetTester tester,
  Finder text, {
  required double scale,
  required double cap,
  Finder? within,
}) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final said = paragraph.text.toPlainText();
  expect(
    paragraph.textScaler.scale(10),
    moreOrLessEquals(10 * math.min(scale, cap)),
    reason: '"$said" at ${scale}x text takes ${math.min(scale, cap)}x',
  );
  expect(paragraph.didExceedMaxLines, isFalse, reason: '"$said" is not cut');
  expect(
    paragraph.size.width,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5),
    reason: '"$said" is on one line, no word broken',
  );
  expect(
    paragraph.size.height,
    greaterThanOrEqualTo(
      paragraph.getMinIntrinsicHeight(paragraph.size.width) - 0.5,
    ),
    reason: '"$said" keeps its lower edge',
  );
  if (within != null) {
    final box = tester.getRect(within).inflate(0.5);
    final rect = tester.getRect(text);
    expect(
      box.contains(rect.topLeft) && box.contains(rect.bottomRight),
      isTrue,
      reason: '"$said" ($rect) stands inside $box',
    );
  }
}

/// Each word of [paragraph] stands on one line: no word is broken.
void _wordsWhole(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  for (final word in RegExp(r'\S+').allMatches(text)) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: word.start, extentOffset: word.end),
    );
    expect(
      boxes.map((box) => box.top.round()).toSet(),
      hasLength(lessThanOrEqualTo(1)),
      reason: '"${word[0]}" of "$text" is not broken',
    );
  }
}

/// A month whose name is one word wider than a date picker's label at 2x.
class _LongMonth extends DefaultRawWidgetsLocalizations {
  const _LongMonth();

  static const month = 'Septemberseptember';

  @override
  String formatMonthYear(DateTime date) => '$month ${date.year}';
}

class _LongMonthDelegate
    extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _LongMonthDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const _LongMonth());

  @override
  bool shouldReload(_LongMonthDelegate old) => false;
}

const _barItems = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.home, 'Today'),
  ExpressiveNavItem(
    ExpressiveSymbols.inbox,
    'Inbox',
    badge: ExpressiveBadge(label: '8', semanticLabel: '8 new'),
  ),
  ExpressiveNavItem(ExpressiveSymbols.event, 'Tasks'),
  ExpressiveNavItem(ExpressiveSymbols.settings, 'Settings'),
];

const _drawerItems = <ExpressiveNavItem>[
  ExpressiveNavItem(ExpressiveSymbols.inbox, 'Inbox'),
  ExpressiveNavItem(
    ExpressiveSymbols.chat,
    'Chats',
    badge: ExpressiveBadge(label: '12', semanticLabel: '12 unread chats'),
  ),
  ExpressiveNavItem(ExpressiveSymbols.group, 'Rooms'),
];

Finder _headline() => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_HeaderHeadline',
  ),
  matching: find.byType(Text),
);

void main() {
  // Roboto Flex's own widths: the test font's square glyphs fit no date.
  setUpAll(expressiveLoadFonts);

  for (final scale in _scales) {
    testWidgets('a bar\'s labels and count read whole at ${scale}x text', (
      tester,
    ) async {
      await _pump(
        tester,
        scale,
        Align(
          alignment: Alignment.bottomCenter,
          child: ExpressiveNavigationBar(
            destinations: _barItems,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      );
      final bar = find.byType(ExpressiveNavigationBar);
      for (final item in _barItems) {
        _whole(
          tester,
          find.text(item.label),
          scale: scale,
          cap: ExpressiveNavigationBar.maxTextScale,
          within: bar,
        );
      }
      _whole(
        tester,
        find.text('8'),
        scale: scale,
        cap: ExpressiveNavigationBar.maxTextScale,
        within: bar,
      );
    });

    testWidgets('a drawer\'s selected label and its count read whole at '
        '${scale}x text', (tester) async {
      await _pump(
        tester,
        scale,
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpressiveNavigationDrawer(
              destinations: _drawerItems,
              selectedIndex: 1,
              onDestinationSelected: (_) {},
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      );
      final drawer = find.byType(ExpressiveNavigationDrawer);
      for (final item in _drawerItems) {
        _whole(
          tester,
          find.text(item.label),
          scale: scale,
          cap: ExpressiveNavigationBar.maxTextScale,
          within: drawer,
        );
      }
      _whole(
        tester,
        find.text('12'),
        scale: scale,
        cap: ExpressiveNavigationBar.maxTextScale,
        within: drawer,
      );
      // The selected destination's label and count stand side by side.
      expect(
        tester.getRect(find.text('Chats')).right,
        lessThanOrEqualTo(tester.getRect(find.text('12')).left),
      );
    });

    testWidgets('a rail\'s labels read whole at ${scale}x text', (
      tester,
    ) async {
      await _pump(
        tester,
        scale,
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExpressiveNavigationRail(
              destinations: _barItems,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
        width: 1440,
      );
      for (final item in _barItems) {
        _whole(
          tester,
          find.text(item.label),
          scale: scale,
          cap: ExpressiveNavigationBar.maxTextScale,
        );
      }
    });

    for (final typing in [false, true]) {
      testWidgets('a date picker\'s header${typing ? ' while typing' : ''} '
          'and weekday letters read whole at ${scale}x text', (tester) async {
        await _pump(
          tester,
          scale,
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ExpressiveDatePicker(
              selected: typing ? null : DateTime(2026, 9, 18),
              currentDate: DateTime(2026, 9, 12),
              initialMonth: DateTime(2026, 9),
              initialMode: typing
                  ? ExpressiveDatePickerMode.input
                  : ExpressiveDatePickerMode.picker,
              onChanged: (_) {},
            ),
          ),
        );
        final header = typing ? 1.4 : 1.6;
        _whole(tester, _headline(), scale: scale, cap: header);
        _whole(
          tester,
          find.text(
            ExpressiveLocalizations.of(tester.element(_headline())).selectDate,
          ),
          scale: scale,
          cap: header,
        );
        if (typing) return;
        // The month at most 2x, as Material's, whole and in whole words: it
        // broke mid-word ("Septemb/er 2026") at 3x.
        final month = tester.renderObject<RenderParagraph>(
          find.text('September 2026'),
        );
        expect(
          month.textScaler.scale(10),
          moreOrLessEquals(10 * math.min(scale, 2)),
        );
        expect(month.didExceedMaxLines, isFalse, reason: 'the month is whole');
        _wordsWhole(month);
        // The letters stand in their 48dp row, their lower edges in it.
        for (final letter in ['S', 'M', 'W', 'F']) {
          final text = find.text(letter).first;
          _whole(tester, text, scale: scale, cap: 2);
          final row = find.ancestor(of: text, matching: find.byType(SizedBox));
          final rect = tester.getRect(text);
          expect(
            rect.bottom,
            lessThanOrEqualTo(tester.getRect(row.first).bottom + 0.5),
            reason: '$letter keeps its lower edge at ${scale}x text',
          );
        }
      });
    }

    if (scale == 3) {
      testWidgets('a month whose name is wider than its line ends with an '
          'ellipsis on one line at 3x text, never broken mid-word', (
        tester,
      ) async {
        await _pump(
          tester,
          scale,
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              _LongMonthDelegate(),
            ],
            child: SingleChildScrollView(
              child: ExpressiveDatePicker(
                currentDate: DateTime(2026, 9, 12),
                initialMonth: DateTime(2026, 9),
                onChanged: (_) {},
              ),
            ),
          ),
        );
        final month = tester.renderObject<RenderParagraph>(
          find.text('${_LongMonth.month} 2026'),
        );
        // The case: the month's name alone is wider than the label's line.
        final word = TextPainter(
          text: TextSpan(text: _LongMonth.month, style: month.text.style),
          textDirection: TextDirection.ltr,
          textScaler: month.textScaler,
        )..layout();
        addTearDown(word.dispose);
        expect(word.width, greaterThan(month.constraints.maxWidth));
        expect(month.maxLines, 1);
        expect(month.didExceedMaxLines, isTrue, reason: 'it ends with "…"');
        final lines = month.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: month.text.toPlainText().length,
          ),
        );
        expect(lines.map((box) => box.top.round()).toSet(), hasLength(1));
      });
    }

    testWidgets('a range picker\'s calendar takes at most Material\'s range '
        'scale, its month under the weekday letters, at ${scale}x text', (
      tester,
    ) async {
      await _pump(
        tester,
        scale,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ExpressiveDateRangePicker(
            start: DateTime(2026, 9, 14),
            end: DateTime(2026, 9, 19),
            currentDate: DateTime(2026, 9, 12),
            initialMonth: DateTime(2026, 9),
            onChanged: (_, _) {},
          ),
        ),
      );
      const cap = 1.3;
      final month = find.text('September 2026');
      _whole(tester, month, scale: scale, cap: cap);
      final letters = find.text('M').first;
      _whole(tester, letters, scale: scale, cap: cap);
      // September opens the list, whole, just under the letters: its
      // subhead in view, no row of it cut under them.
      expect(
        tester.getRect(month).top,
        greaterThanOrEqualTo(tester.getRect(letters).bottom),
      );
      expect(
        tester.getRect(find.text('1').first).top,
        greaterThan(tester.getRect(month).bottom),
      );
    });
  }
}
