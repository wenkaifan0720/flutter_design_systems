/// The parts that cap their text where Material's do, read whole at 1x, 2x
/// and 3x text: a bar's and a rail's destinations at 1.3x (NavigationBar),
/// a date picker's header at 1.6x (1.4x while a date is typed) and its
/// weekday letters at 2x (the day picker). Past those, at 300% text, a bar
/// cut its count and broke its words ("Toda/y"), the drawer dropped its
/// selected label, the header cut the chosen date ("18 S…") and the
/// weekday letters lost their lower edge.
library;

import 'dart:math' as math;

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
      light: _theme,
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
  }
}
