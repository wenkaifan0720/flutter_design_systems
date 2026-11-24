import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

class _Doc {
  const _Doc(this.name, this.size);
  final String name;
  final int size;
}

Widget _app(RetroDesktopAppearance appearance, Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => RetroDesktopHost(
    brightness: Brightness.light,
    light: RetroDesktopThemeData.classic().copyWith(appearance: appearance),
    child: child!,
  ),
  home: Center(child: SizedBox(width: 360, child: home)),
);

/// The one part that shows the keyboard focus.
Finder get _focused => find.byWidgetPredicate(
  (widget) => widget is RetroDesktopHighlight && widget.focused,
);

/// Tabs until the focus shows on the part holding [words], as a reader at a keyboard reaches it.
Future<void> _tabTo(WidgetTester tester, String words) async {
  for (var i = 0; i < 8; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (find
        .descendant(of: _focused, matching: find.text(words))
        .evaluate()
        .isNotEmpty) {
      return;
    }
  }
  fail('Tab never reached "$words"');
}

/// A key after the pointer, so the focus shows, as it does for a reader at a keyboard.
Future<void> _showFocus(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

void _expectRingInWordsColour(WidgetTester tester) {
  expect(_focused, findsOneWidget);
  final colors = RetroDesktopTheme.of(tester.element(_focused)).colors;
  expect(
    tester.widget<RetroDesktopHighlight>(_focused).insideColor,
    colors.onHighlight,
  );
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in RetroDesktopAppearance.values) {
    testWidgets(
      'a focused chosen day in a ${appearance.name} date picker rings in its number\'s colour',
      (tester) async {
        await tester.pumpWidget(_app(appearance, const Text('Trip')));
        unawaited(
          showRetroDesktopDatePicker(
            tester.element(find.text('Trip')),
            value: DateTime(2026, 3, 12),
            today: DateTime(2026, 3, 2),
          ),
        );
        await tester.pumpAndSettle();
        await _showFocus(tester);
        _expectRingInWordsColour(tester);
      },
    );

    testWidgets(
      'a focused chosen day in a ${appearance.name} calendar rings in its number\'s colour',
      (tester) async {
        await tester.pumpWidget(
          _app(
            appearance,
            RetroDesktopCalendar(
              firstDate: DateTime(2026),
              lastDate: DateTime(2026, 12, 31),
              value: DateTime(2026, 3, 12),
              onChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _tabTo(tester, '12');
        _expectRingInWordsColour(tester);
      },
    );

    testWidgets(
      'a focused chosen row in a ${appearance.name} tree rings in its words\' colour',
      (tester) async {
        final tree = RawTreeController<String>(
          roots: const ['System'],
          expanded: const ['System'],
          childrenOf: (node) =>
              node == 'System' ? const ['Fonts', 'Sounds'] : const [],
        );
        addTearDown(tree.dispose);
        tree.select('Fonts');
        await tester.pumpWidget(
          _app(
            appearance,
            RetroDesktopTreeView<String>(
              label: 'Folders',
              controller: tree,
              labelOf: (node) => node,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _tabTo(tester, 'Fonts');
        _expectRingInWordsColour(tester);
      },
    );

    testWidgets(
      'a focused chosen row in a ${appearance.name} data table rings in its words\' colour',
      (tester) async {
        final table = RawDataTableController<_Doc>(
          rows: const [_Doc('Budget', 12), _Doc('Letters', 48)],
          columns: [
            RawDataColumn<_Doc>(
              id: 'name',
              label: 'Name',
              sortKey: (doc) => doc.name,
            ),
            RawDataColumn<_Doc>(
              id: 'size',
              label: 'Size',
              numeric: true,
              sortKey: (doc) => doc.size,
            ),
          ],
        );
        addTearDown(table.dispose);
        await tester.pumpWidget(
          _app(
            appearance,
            RetroDesktopDataTable<_Doc>(
              controller: table,
              cellText: (doc, column) =>
                  column.id == 'name' ? doc.name : '${doc.size} KB',
            ),
          ),
        );
        table.selectAll();
        await tester.pumpAndSettle();
        await _tabTo(tester, 'Budget');
        _expectRingInWordsColour(tester);
      },
    );
  }
}
