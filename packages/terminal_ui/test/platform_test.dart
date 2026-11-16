// The platforms' own ways back. iOS: a swipe from the screen's start edge
// takes a page back under Terminal's own screen change (ui_core's
// DesignSwipeBackPageTransitionsBuilder round it: a page transition of
// one's own drops the platform's), a short slow one doesn't. Android: the
// system's back takes a page back, and first closes what a press opened on
// it (a menu, a select's list, a popover, a combobox's list, a dialog, a
// sheet).
// Keys: written for a pointer and a keyboard, left out under touch.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

Widget _app(WidgetBuilder second, {bool termRoute = false}) => MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: termPageTransitions,
    ),
  ),
  builder: (context, child) =>
      TermTheme(data: TermThemeData.dark(), child: child!),
  home: Builder(
    builder: (context) => Center(
      child: TermButton(
        label: 'next',
        onPressed: () => Navigator.of(context).push(
          termRoute
              ? TermPageRoute<void>(builder: second)
              : MaterialPageRoute<void>(builder: second),
        ),
      ),
    ),
  ),
);

Widget _page(BuildContext context) => const Center(child: Text('second page'));

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('next'));
  await tester.pumpAndSettle();
  expect(find.text('second page'), findsOneWidget);
}

bool _onSecond() => find.text('second page').evaluate().isNotEmpty;

// The system's back, as Android sends it.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.navigation.name,
    SystemChannels.navigation.codec.encodeMethodCall(
      const MethodCall('popRoute'),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  group('iOS', () {
    final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

    for (final termRoute in [false, true]) {
      final what = termRoute ? 'TermPageRoute' : 'MaterialPageRoute';
      testWidgets('a swipe from the start edge takes a $what back', (
        tester,
      ) async {
        await tester.pumpWidget(_app(_page, termRoute: termRoute));
        await _next(tester);
        // Past half way, slowly (no fling), as ui_core's swipe takes it.
        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        final finger = await tester.startGesture(const Offset(4, 300));
        for (var i = 0; i < 10; i++) {
          await finger.moveBy(Offset(width * .06, 0));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await finger.up();
        await tester.pumpAndSettle();
        expect(_onSecond(), isFalse);
        expect(find.text('next'), findsOneWidget);
      }, variant: ios);
    }

    testWidgets('a short slow swipe leaves the page', (tester) async {
      await tester.pumpWidget(_app(_page));
      await _next(tester);
      await tester.timedDragFrom(
        const Offset(4, 300),
        const Offset(80, 0),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(_onSecond(), isTrue);
    }, variant: ios);

    testWidgets('a swipe that starts off the edge leaves the page', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_page));
      await _next(tester);
      await tester.dragFrom(const Offset(200, 300), const Offset(400, 0));
      await tester.pumpAndSettle();
      expect(_onSecond(), isTrue);
    }, variant: ios);
  });

  // Keys are written where a keyboard reaches the app, and left out under
  // touch, where there are none to press.
  group('keys', () {
    // The sheet's bottom line is painted into its frame.
    String? sheetFooter(WidgetTester tester) => tester
        .widget<TermPane>(
          find.descendant(
            of: find.byType(TermSheet),
            matching: find.byType(TermPane),
          ),
        )
        .footer;

    Widget keyed() => MaterialApp(
      builder: (context, child) =>
          TermTheme(data: TermThemeData.dark(), child: child!),
      home: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TermButton(
            label: 'save',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              control: true,
            ),
            onPressed: () {},
          ),
          const TermKey('^K'),
          const SizedBox(
            width: 400,
            child: TermStatusLine(
              mode: 'RUNS',
              keys: [(keys: 'M-1', label: 'go')],
            ),
          ),
          const SizedBox(
            width: 400,
            child: TermSheet(title: 'sheet', child: Text('words')),
          ),
        ],
      ),
    );

    testWidgets('are written for a pointer', (tester) async {
      await tester.pumpWidget(keyed());
      expect(find.text('^S'), findsOneWidget);
      expect(find.text('^K'), findsOneWidget);
      expect(find.text('M-1'), findsOneWidget);
      expect(sheetFooter(tester), 'esc close');
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('are left out under touch', (tester) async {
      await tester.pumpWidget(keyed());
      expect(find.text('save'), findsOneWidget);
      expect(find.text('^S'), findsNothing);
      expect(find.text('^K'), findsNothing);
      expect(find.text('M-1'), findsNothing);
      expect(sheetFooter(tester), isNull);
    }, variant: TargetPlatformVariant.mobile());
  });

  group('Android back', () {
    final android = TargetPlatformVariant.only(TargetPlatform.android);

    testWidgets('takes a page back', (tester) async {
      await tester.pumpWidget(_app(_page, termRoute: true));
      await _next(tester);
      await _back(tester);
      expect(_onSecond(), isFalse);
    }, variant: android);

    // Each opens something on the second page by a press; back closes it
    // and leaves the page, and the next back takes the page.
    final opened =
        <
          String,
          (
            Widget Function(BuildContext) page,
            Future<void> Function(WidgetTester) open,
            bool Function() isOpen,
          )
        >{
          'a menu': (
            (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('second page'),
                  TermMenu(
                    anchorBuilder: (context, anchor) =>
                        TermButton(label: 'more', onPressed: anchor.toggle),
                    items: [TermMenuItem(label: 'rerun', onPressed: () {})],
                  ),
                ],
              ),
            ),
            (tester) => tester.tap(find.text('more')),
            () => find.text('rerun').evaluate().isNotEmpty,
          ),
          "a select's list": (
            (context) => Center(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('second page'),
                    TermSelect<String>(
                      labelText: 'env',
                      value: 'staging',
                      items: const [
                        TermSelectItem(value: 'staging', label: 'staging'),
                        TermSelectItem(
                          value: 'production',
                          label: 'production',
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
            (tester) => tester.tap(find.text('staging')),
            () => find.text('production').evaluate().isNotEmpty,
          ),
          'a popover': (
            (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('second page'),
                  TermPopover(
                    title: 'about',
                    anchorBuilder: (context, anchor) =>
                        TermButton(label: 'info', onPressed: anchor.toggle),
                    builder: (context) => const Text('popover words'),
                  ),
                ],
              ),
            ),
            (tester) => tester.tap(find.text('info')),
            () => find.text('popover words').evaluate().isNotEmpty,
          ),
          "a combobox's list": (
            (context) => Center(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('second page'),
                    TermCombobox<String>(
                      labelText: 'branch',
                      options: const ['main', 'release'],
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ),
            (tester) => tester.tap(find.byType(EditableText)),
            () => find.text('release').evaluate().isNotEmpty,
          ),
          'a dialog': (
            (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('second page'),
                  TermButton(
                    label: 'ask',
                    onPressed: () => showTermDialog<void>(
                      context: context,
                      builder: (context) => const TermDialog(
                        title: 'dialog title',
                        content: Text('dialog words'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            (tester) => tester.tap(find.text('ask')),
            () => find.text('dialog words').evaluate().isNotEmpty,
          ),
          'a sheet': (
            (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('second page'),
                  TermButton(
                    label: 'sheet',
                    onPressed: () => showTermSheet<void>(
                      context: context,
                      builder: (context) => const Text('sheet words'),
                    ),
                  ),
                ],
              ),
            ),
            (tester) => tester.tap(find.text('sheet')),
            () => find.text('sheet words').evaluate().isNotEmpty,
          ),
        };

    for (final MapEntry(key: name, value: (page, open, isOpen))
        in opened.entries) {
      testWidgets('closes $name first, then takes the page', (tester) async {
        await tester.pumpWidget(_app(page, termRoute: true));
        await _next(tester);
        await open(tester);
        await tester.pumpAndSettle();
        expect(isOpen(), isTrue, reason: '$name opened');
        await _back(tester);
        expect(isOpen(), isFalse, reason: 'back closed $name');
        expect(_onSecond(), isTrue, reason: 'and left the page');
        await _back(tester);
        expect(_onSecond(), isFalse, reason: 'the next back took the page');
      }, variant: android);
    }
  });
}
