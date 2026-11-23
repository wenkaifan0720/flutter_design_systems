// Brutal on each platform, as an app on a router meets it (Admit's go_router
// shell pops the same way). iOS: Brutal's push, not Cupertino's, and a
// pushed page goes back on the edge swipe (ui_core's swipe back round the
// push), Brutal's own page or a MaterialPageRoute under brutalPageTransitions.
// Android: system back closes what stands over a page first (a dialog, a
// sheet, a menu, a select's or a combobox's list, a popover, a date picker),
// and only then goes back a page.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialPageRoute, PageTransitionsTheme, ThemeData;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Two pages on a router, as go_router lays them: the first opens the second.
class _Pages extends RouterDelegate<Object>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
  _Pages(this.second);

  final Widget second;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool open = false;

  void push() {
    open = true;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: [
      BrutalPage<void>(
        key: const ValueKey('first'),
        child: BrutalScreen(
          body: Align(
            alignment: Alignment.topLeft,
            child: BrutalButton('Open the event', onPressed: push),
          ),
        ),
      ),
      if (open)
        BrutalPage<void>(
          key: const ValueKey('second'),
          child: BrutalScreen(
            topBar: const BrutalAppBar(title: 'Event'),
            body: Align(alignment: Alignment.topLeft, child: second),
          ),
        ),
    ],
    onDidRemovePage: (page) {
      if (page.key == const ValueKey('second')) {
        open = false;
        notifyListeners();
      }
    },
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

Future<_Pages> _pumpPages(WidgetTester tester, Widget second) async {
  final pages = _Pages(second);
  addTearDown(pages.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerDelegate: pages,
      builder: (context, child) =>
          BrutalHost(brightness: Brightness.light, child: child!),
    ),
  );
  await tester.tap(find.text('Open the event'));
  await tester.pumpAndSettle();
  expect(find.text('Event'), findsOneWidget);
  return pages;
}

// System back, as Android sends it.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

final _android = TargetPlatformVariant.only(TargetPlatform.android);

void main() {
  group('iOS', () {
    final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

    testWidgets('a BrutalPage is pushed in Brutal\'s way and goes back on the '
        'edge swipe', (tester) async {
      await _pumpPages(tester, const Text('Doors at eight'));
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.dragFrom(const Offset(4, 400), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Event'), findsNothing);
      expect(find.text('Open the event'), findsOneWidget);
    }, variant: ios);

    testWidgets('a MaterialPageRoute under brutalPageTransitions goes back on '
        'the edge swipe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: brutalPageTransitions,
            ),
          ),
          builder: (context, child) =>
              BrutalHost(brightness: Brightness.light, child: child!),
          home: Builder(
            builder: (context) => Align(
              alignment: Alignment.topLeft,
              child: BrutalButton(
                'Open the event',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BrutalScreen(
                      topBar: BrutalAppBar(title: 'Event'),
                      body: Text('Doors at eight'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open the event'));
      await tester.pumpAndSettle();
      expect(find.text('Event'), findsOneWidget);
      await tester.dragFrom(const Offset(4, 400), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Event'), findsNothing);
    }, variant: ios);
  });

  group('Android back', () {
    testWidgets('goes back a page', (tester) async {
      await _pumpPages(tester, const Text('Doors at eight'));
      await _back(tester);
      expect(find.text('Event'), findsNothing);
      expect(find.text('Open the event'), findsOneWidget);
    }, variant: _android);

    testWidgets('closes a dialog first', (tester) async {
      await _pumpPages(
        tester,
        Builder(
          builder: (context) => BrutalButton(
            'Refund',
            onPressed: () => showBrutalDialog<void>(
              context: context,
              builder: (_) => const BrutalDialog(
                title: 'Refund the tickets?',
                content: Text('The money goes back to the card.'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Refund'));
      await tester.pumpAndSettle();
      expect(find.text('Refund the tickets?'), findsOneWidget);
      await _back(tester);
      expect(find.text('Refund the tickets?'), findsNothing);
      expect(find.text('Event'), findsOneWidget);
    }, variant: _android);

    testWidgets('closes a sheet first', (tester) async {
      await _pumpPages(
        tester,
        Builder(
          builder: (context) => BrutalButton(
            'Seats',
            onPressed: () => showBrutalBottomSheet<void>(
              context: context,
              title: 'Pick seats',
              builder: (_) => const Text('Row F'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Seats'));
      await tester.pumpAndSettle();
      expect(find.text('Row F'), findsOneWidget);
      await _back(tester);
      expect(find.text('Row F'), findsNothing);
      expect(find.text('Event'), findsOneWidget);
    }, variant: _android);

    testWidgets('closes a menu first', (tester) async {
      await _pumpPages(
        tester,
        BrutalMenu(
          items: [
            BrutalMenuItem(label: 'Share', onPressed: () {}),
            BrutalMenuItem(label: 'Save', onPressed: () {}),
          ],
          builder: (context, toggle, open) =>
              BrutalButton('More', onPressed: toggle),
        ),
      );
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      await _back(tester);
      expect(find.text('Share'), findsNothing);
      expect(find.text('Event'), findsOneWidget);
      await _back(tester);
      expect(find.text('Event'), findsNothing);
    }, variant: _android);

    testWidgets("closes a select's list first", (tester) async {
      await _pumpPages(
        tester,
        SizedBox(
          width: 320,
          child: BrutalSelect<String>(
            labelText: 'Section',
            value: 'Stalls',
            items: const [
              BrutalSelectItem(value: 'Stalls', label: 'Stalls'),
              BrutalSelectItem(value: 'Circle', label: 'Circle'),
            ],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Stalls'));
      await tester.pumpAndSettle();
      expect(find.text('Circle'), findsOneWidget);
      await _back(tester);
      expect(find.text('Circle'), findsNothing);
      expect(find.text('Event'), findsOneWidget);
    }, variant: _android);

    testWidgets("closes a combobox's list first, the keyboard staying in "
        'its entry', (tester) async {
      await _pumpPages(
        tester,
        SizedBox(
          width: 320,
          child: BrutalCombobox<String>(
            labelText: 'Venue',
            options: const ['Hall 4', 'Gallery Nine', 'The Yard'],
            value: 'Hall 4',
            displayStringForOption: (v) => v,
            onSelected: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.text('The Yard'), findsOneWidget);
      await _back(tester);
      expect(find.text('The Yard'), findsNothing);
      expect(find.text('Event'), findsOneWidget);
      final entry = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      expect(entry.hasPrimaryFocus, isTrue);
    }, variant: _android);

    testWidgets("closes a date picker's calendar first", (tester) async {
      await _pumpPages(
        tester,
        SizedBox(
          width: 320,
          child: BrutalDatePicker(
            labelText: 'Night',
            value: null,
            onChanged: (_) {},
            firstDate: DateTime(2026, 11),
            lastDate: DateTime(2026, 12, 31),
            currentDate: DateTime(2026, 11, 15),
          ),
        ),
      );
      await tester.tap(find.text('Choose a date'));
      await tester.pumpAndSettle();
      expect(find.text('20'), findsOneWidget);
      await _back(tester);
      expect(find.text('20'), findsNothing);
      expect(find.text('Event'), findsOneWidget);
    }, variant: _android);

    testWidgets('closes a popover first', (tester) async {
      await _pumpPages(
        tester,
        BrutalPopover(
          builder: (context, toggle, open) =>
              BrutalButton('Share', onPressed: toggle),
          content: (context, close) => const Text('Copy the link'),
        ),
      );
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text('Copy the link'), findsOneWidget);
      await _back(tester);
      expect(find.text('Copy the link'), findsNothing);
      expect(find.text('Event'), findsOneWidget);
    }, variant: _android);
  });
}
