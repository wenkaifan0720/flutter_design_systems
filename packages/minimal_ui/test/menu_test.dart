import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/scrolling_host.dart';

void main() {
  group('MinimalMenu', () {
    List<MinimalMenuItem> items(List<String> log) => [
      MinimalMenuItem(
        'Edit',
        shortcut: const SingleActivator(LogicalKeyboardKey.keyE),
        onPressed: () => log.add('edit'),
      ),
      MinimalMenuItem('Duplicate', onPressed: () => log.add('duplicate')),
      const MinimalMenuItem('Move to…'),
      MinimalMenuItem(
        'Delete',
        isDestructiveAction: true,
        startsGroup: true,
        onPressed: () => log.add('delete'),
      ),
    ];

    testWidgets('a tap opens it; an item runs once the menu has closed', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalMenu(
            semanticLabel: 'Habit actions',
            items: items(log),
            child: const Text('More'),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('E'), findsOneWidget);
      await tester.tap(find.text('Move to…'));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(log, ['delete']);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('a tap outside and Escape close it with nothing run', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalMenu(
            semanticLabel: 'Habit actions',
            items: items(log),
            child: const Text('More'),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(780, 580));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('the arrow keys walk the items and Enter runs one', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalMenu(
            semanticLabel: 'Habit actions',
            items: items(log),
            child: const Text('More'),
          ),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(log, ['duplicate']);
    });

    testWidgets('long press opens the context menu; a tap does not', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        scrollingHost(
          MinimalMenu(
            semanticLabel: 'Row actions',
            trigger: MinimalMenuTrigger.longPress,
            items: items([]),
            child: GestureDetector(
              onTap: () => taps += 1,
              child: const Text('Morning run'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Morning run'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(find.text('Edit'), findsNothing);
      await tester.longPress(find.text('Morning run'));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('a menu with no items is a disabled control', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(
          const MinimalMenu(
            semanticLabel: 'No actions',
            items: [],
            child: Text('More'),
          ),
        ),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('No actions')),
      );
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      handle.dispose();
    });
  });

  group('menu placement and triggers', () {
    Widget bottomHost(Widget child) => MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: MinimalThemeData.preset('standard', Brightness.light),
        dark: MinimalThemeData.preset('standard', Brightness.dark),
        brightness: Brightness.light,
        child: navigator!,
      ),
      home: Scaffold(
        body: Align(alignment: Alignment.bottomLeft, child: child),
      ),
    );

    testWidgets('near the bottom the card opens above its control', (
      tester,
    ) async {
      await tester.pumpWidget(
        bottomHost(
          MinimalMenu.button(
            LucideIcons.ellipsis,
            semanticLabel: 'Habit actions',
            items: [
              for (final label in const ['Edit', 'Duplicate', 'Archive'])
                MinimalMenuItem(label, onPressed: () {}),
            ],
          ),
        ),
      );
      final anchor = tester.getRect(find.bySemanticsLabel('Habit actions'));
      await tester.tap(find.bySemanticsLabel('Habit actions'));
      await tester.pumpAndSettle();
      final card = tester.getRect(
        find
            .ancestor(of: find.text('Edit'), matching: find.byType(ClipRRect))
            .first,
      );
      expect(card.bottom, lessThanOrEqualTo(anchor.top));
    });

    testWidgets('the pill trigger prints its choice and opens the menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        scrollingHost(
          MinimalMenu.button(
            LucideIcons.arrowDownUp,
            text: 'Sort: Streak',
            semanticLabel: 'Sort habits',
            items: [MinimalMenuItem('Name', onPressed: () {})],
          ),
        ),
      );
      await tester.tap(find.text('Sort: Streak'));
      await tester.pumpAndSettle();
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('Shift+F10 opens a long-press menu from the keyboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        scrollingHost(
          MinimalMenu(
            semanticLabel: 'Row actions',
            trigger: MinimalMenuTrigger.longPress,
            items: [MinimalMenuItem('Edit', onPressed: () {})],
            child: const Text('Morning run'),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets(
      'the card reads the theme of its caller under a bare navigator',
      (tester) async {
        final t = MinimalThemeData.preset('ember', Brightness.dark);
        await tester.pumpWidget(
          MaterialApp(
            home: MinimalHost(
              light: MinimalThemeData.preset('ember', Brightness.light),
              dark: t,
              brightness: Brightness.dark,
              child: Center(
                child: MinimalMenu(
                  semanticLabel: 'Habit actions',
                  items: [MinimalMenuItem('Edit', onPressed: () {})],
                  child: const Text('More'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('More'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final card = tester.widget<Container>(
          find
              .ancestor(of: find.text('Edit'), matching: find.byType(Container))
              .last,
        );
        expect((card.decoration! as BoxDecoration).color, t.card);
      },
    );
  });
}
