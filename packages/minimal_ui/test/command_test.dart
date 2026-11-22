import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/page_host.dart';

List<MinimalCommandItem> _actions(List<String> ran) => [
  MinimalCommandItem(
    'New habit',
    icon: LucideIcons.plus,
    group: 'Habits',
    shortcut: 'N',
    keywords: const ['create'],
    onSelected: () => ran.add('New habit'),
  ),
  const MinimalCommandItem('Export as CSV', group: 'Habits'),
  MinimalCommandItem(
    'Mark Morning run done',
    group: 'Habits',
    detail: 'HAB-4',
    onSelected: () => ran.add('Mark Morning run done'),
  ),
  MinimalCommandItem(
    'Go to Today',
    group: 'Navigate',
    shortcut: 'G T',
    onSelected: () => ran.add('Go to Today'),
  ),
];

void main() {
  group('MinimalCommand', () {
    testWidgets('typing filters; nothing matching shows the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(MinimalCommand(actions: _actions([]), autofocus: false)),
      );
      // Unfocused at first, the palette takes focus from its second frame.
      await tester.pump();
      await tester.pump();
      expect(find.text('HABITS'), findsOneWidget);
      expect(find.text('NAVIGATE'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'create');
      await tester.pump();
      expect(find.bySemanticsLabel('New habit, N'), findsOneWidget);
      expect(find.text('Go to Today'), findsNothing);
      await tester.enterText(find.byType(TextField), 'invoice');
      await tester.pump();
      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('at text scale 1.3 a result row grows with its words; a '
        'group opens on more air than lies between rows', (tester) async {
      await tester.pumpWidget(
        pageApp(
          scaled(MinimalCommand(actions: _actions([]), autofocus: false)),
        ),
      );
      await tester.pump();
      await tester.pump();
      final t = MinimalThemeData.preset('standard', Brightness.light);
      Rect row(Finder words) => tester.getRect(
        find.ancestor(of: words, matching: find.byType(Container)).first,
      );
      expect(
        row(find.text('Go to Today')).height,
        greaterThan(t.rowHeightCompact),
      );
      final above = row(find.textContaining('Mark Morning run done'));
      expect(
        tester.getRect(find.text('NAVIGATE')).top - above.bottom,
        moreOrLessEquals(MinimalSpacing.s16, epsilon: 0.5),
      );
    });

    testWidgets('arrows move past disabled actions; Enter runs', (
      tester,
    ) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        pageApp(
          MinimalCommand(
            actions: _actions([]),
            onSelected: (a) => chosen.add(a.label),
          ),
        ),
      );
      await tester.pump();
      void highlighted(String label) => expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isSelected: true),
      );
      highlighted('New habit, N');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      // Export has no handler: the highlight skips it.
      highlighted('Mark Morning run done');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Export as CSV')),
        isSemantics(isEnabled: false),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      highlighted('New habit, N');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      highlighted('Go to Today, G T');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, ['Go to Today']);
      await tester.tap(find.text('Export as CSV'), warnIfMissed: false);
      expect(chosen, ['Go to Today']);
    });

    testWidgets('show runs the chosen action after the card closes', (
      tester,
    ) async {
      final ran = <String>[];
      MinimalCommandItem? result;
      await tester.pumpWidget(
        pageApp(
          Builder(
            builder: (context) => MinimalButton(
              'Open',
              onPressed: () async => result = await MinimalCommand.show(
                context,
                subtitle: 'Habits',
                actions: _actions(ran),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // The subtitle stands as a pill over the field.
      expect(find.text('Habits'), findsOneWidget);
      // The route is named Commands, and so is its list of results.
      expect(find.bySemanticsLabel('Commands'), findsNWidgets(2));
      await tester.tap(find.text('Go to Today'));
      await tester.pumpAndSettle();
      expect(find.text('Go to Today'), findsNothing);
      expect(ran, ['Go to Today']);
      expect(result?.label, 'Go to Today');
    });

    testWidgets('the shown palette stands its field as far from the top as '
        'from the sides', (tester) async {
      await tester.pumpWidget(
        pageApp(
          Builder(
            builder: (context) => MinimalButton(
              'Open',
              onPressed: () =>
                  MinimalCommand.show(context, actions: _actions(<String>[])),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      bool framed(Widget w, {required bool shadowed}) {
        if (w is! DecoratedBox) return false;
        final d = w.decoration;
        return d is BoxDecoration &&
            d.border != null &&
            (d.boxShadow != null) == shadowed;
      }

      // The card wears the large shadow; the field's box is the nearest
      // rim round its hint.
      final card = find.byWidgetPredicate((w) => framed(w, shadowed: true));
      final box = find
          .ancestor(
            of: find.text('Type a command or search'),
            matching: find.byWidgetPredicate((w) => framed(w, shadowed: false)),
          )
          .first;
      final outer = tester.getRect(card.first);
      final field = tester.getRect(box);
      expect(field.top - outer.top, moreOrLessEquals(field.left - outer.left));
    });

    testWidgets('a shortcut is announced by its keys\' names', (tester) async {
      await tester.pumpWidget(
        pageApp(
          MinimalCommand(
            autofocus: false,
            actions: [
              MinimalCommandItem(
                'Open commands',
                shortcut: '⌘ ⇧ K',
                onSelected: () {},
              ),
            ],
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Open commands, Command Shift K'),
        findsOneWidget,
      );
    });

    testWidgets('a pointer moves the highlight; a rebuild keeps it', (
      tester,
    ) async {
      late StateSetter rebuild;
      await tester.pumpWidget(
        pageApp(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              // A fresh list on every build, as a page often builds it.
              return MinimalCommand(actions: _actions([]));
            },
          ),
        ),
      );
      await tester.pump();
      void highlighted(String label) => expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isSelected: true),
      );
      highlighted('New habit, N');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Go to Today')));
      await tester.pump();
      highlighted('Go to Today, G T');
      await mouse.moveTo(Offset.zero);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      highlighted('Mark Morning run done');
      rebuild(() {});
      await tester.pump();
      highlighted('Mark Morning run done');
    });
  });
}
