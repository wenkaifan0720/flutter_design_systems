// The look on each platform. On iOS a page keeps the edge swipe back round the look's own
// page change (ui_core's swipe back): the page follows the finger with the one under it showing, whether the app pushes
// it under the theme's transitions or the router pushes a NeumorphicPage. Android's system back closes what stands
// over a page (a menu, a side sheet, a bottom sheet, a dialog, a select's open list, a popover) before it pops the
// page. A desktop's pointer meets a hand on what it can press, a text bar on words and an
// arrow elsewhere, and its controls stand at a pointer's density.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

Widget _app(TargetPlatform platform, Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    platform: platform,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: neumorphicPageTransitions,
    ),
  ),
  builder: (context, child) => NeumorphicTheme(
    data: NeumorphicThemeData.preset(
      'porcelain',
      Brightness.light,
    ).atWidth(MediaQuery.sizeOf(context).width),
    child: child!,
  ),
  home: home,
);

class _First extends StatelessWidget {
  const _First();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: NeumorphicButton(
        'Open',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Center(child: Text('Second'))),
          ),
        ),
      ),
    ),
  );
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _open(WidgetTester tester, TargetPlatform platform) async {
  await _phone(tester);
  await tester.pumpWidget(_app(platform, const _First()));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  expect(find.text('Second'), findsOneWidget);
  expect(find.text('Open'), findsNothing);
}

/// A drag from the left edge by [dx] in [steps] moves, [each] apart.
Future<void> _swipe(
  WidgetTester tester,
  double dx, {
  int steps = 6,
  Duration each = const Duration(milliseconds: 16),
}) async {
  final finger = await tester.startGesture(const Offset(6, 420));
  for (var i = 0; i < steps; i++) {
    await finger.moveBy(Offset(dx / steps, 0));
    await tester.pump(each);
  }
  await finger.up();
  await tester.pumpAndSettle();
}

Animation<double> _shown(WidgetTester tester, String text) =>
    ModalRoute.of(tester.element(find.text(text)))!.animation!;

void main() {
  // As on an iPhone: the look's theme bridges its own Material theme, and reads the platform as a device has it.
  group('iOS', () {
    testWidgets('an edge swipe pops a page, the page following the finger', (
      tester,
    ) async {
      await _open(tester, TargetPlatform.iOS);
      final finger = await tester.startGesture(const Offset(6, 420));
      for (var i = 0; i < 5; i++) {
        await finger.moveBy(const Offset(30, 0));
        await tester.pump(const Duration(milliseconds: 100));
      }
      // 150 of 390 across: the page stands 150 in, under the finger, and is shown three fifths.
      final page = find.ancestor(
        of: find.text('Second'),
        matching: find.byType(Scaffold),
      );
      expect(tester.getTopLeft(page).dx, moreOrLessEquals(150, epsilon: 1));
      expect(
        _shown(tester, 'Second').value,
        moreOrLessEquals(1 - 150 / 390, epsilon: .01),
      );
      expect(find.text('Open'), findsOneWidget, reason: 'the page under shows');
      await finger.moveBy(const Offset(120, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await finger.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      // The navigator holds no gesture after it.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.userGestureInProgress, isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a short slow swipe lets the page come back', (tester) async {
      await _open(tester, TargetPlatform.iOS);
      await _swipe(tester, 90, each: const Duration(milliseconds: 120));
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(_shown(tester, 'Second').value, 1);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a quick flick from the edge pops it', (tester) async {
      await _open(tester, TargetPlatform.iOS);
      await tester.flingFrom(const Offset(6, 420), const Offset(120, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a swipe that starts off the edge leaves the page', (
      tester,
    ) async {
      await _open(tester, TargetPlatform.iOS);
      final finger = await tester.startGesture(const Offset(80, 420));
      await finger.moveBy(const Offset(250, 0));
      await tester.pump();
      await finger.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('a router\'s NeumorphicPage pops on the edge swipe', (
      tester,
    ) async {
      await _phone(tester);
      final pages = <Page<void>>[
        const NeumorphicPage(key: ValueKey('a'), child: Text('Rooms')),
        const NeumorphicPage(key: ValueKey('b'), child: Text('Kitchen')),
      ];
      await tester.pumpWidget(
        _app(
          TargetPlatform.iOS,
          StatefulBuilder(
            builder: (context, setState) => Navigator(
              pages: List.of(pages),
              onDidRemovePage: (page) => setState(() => pages.remove(page)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kitchen'), findsOneWidget);
      await _swipe(tester, 300);
      expect(find.text('Kitchen'), findsNothing);
      expect(find.text('Rooms'), findsOneWidget);
      expect(pages, hasLength(1));
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  testWidgets('on Android the same edge drag leaves the page: back is the '
      'system\'s', (tester) async {
    await _open(tester, TargetPlatform.android);
    await _swipe(tester, 300);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('Android\'s back closes a menu, a side sheet, a bottom sheet, '
      'a dialog, a select\'s list and a popover before it pops the page', (
    tester,
  ) async {
    await _phone(tester);
    late BuildContext page;
    await tester.pumpWidget(
      _app(
        TargetPlatform.android,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: NeumorphicButton(
                'Open',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      page = context;
                      return Scaffold(
                        body: Center(
                          child: SizedBox(
                            width: 300,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Second'),
                                NeumorphicSelect<String>(
                                  labelText: 'Country',
                                  value: 'Austria',
                                  options: const [
                                    NeumorphicMenuItem('Austria', 'Austria'),
                                    NeumorphicMenuItem('Belgium', 'Belgium'),
                                  ],
                                  onChanged: (_) {},
                                ),
                                NeumorphicPopover(
                                  semanticLabel: 'Opening hours',
                                  trigger: (context, toggle) =>
                                      NeumorphicButton(
                                        'Hours',
                                        onPressed: toggle,
                                      ),
                                  content: const Text('Nine to six'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final opens = <String, VoidCallback>{
      'Copy': () => showNeumorphicMenu<String>(
        page,
        anchor: const Rect.fromLTWH(40, 100, 120, 40),
        items: const [NeumorphicMenuItem('copy', 'Copy')],
      ),
      'Side filters': () => showNeumorphicSheet<void>(
        page,
        builder: (context, close) => NeumorphicSheet(
          title: 'Side filters',
          onClose: close,
          child: const SizedBox(height: 80),
        ),
      ),
      'Foot filters': () => showNeumorphicBottomSheet<void>(
        page,
        builder: (context) => const NeumorphicBottomSheet(
          title: 'Foot filters',
          child: SizedBox(height: 80),
        ),
      ),
      'Keep this?': () => showNeumorphicDialog<void>(
        page,
        builder: (context) => const NeumorphicDialog(title: 'Keep this?'),
      ),
    };
    // ui_core's own surfaces on the page: a select's open list and a popover. Each back closes the one open.
    final opensOnPage = <String, Future<void> Function()>{
      'Belgium': () => tester.tap(find.byType(NeumorphicSelect<String>)),
      'Nine to six': () => tester.tap(find.text('Hours')),
    };
    for (final MapEntry(key: shown, value: open) in opens.entries) {
      open();
      await tester.pumpAndSettle();
      expect(find.text(shown), findsOneWidget, reason: shown);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(shown), findsNothing, reason: '$shown closes first');
      expect(find.text('Second'), findsOneWidget, reason: shown);
    }
    for (final MapEntry(key: shown, value: open) in opensOnPage.entries) {
      await open();
      await tester.pumpAndSettle();
      expect(find.text(shown), findsOneWidget, reason: shown);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(shown), findsNothing, reason: '$shown closes first');
      expect(find.text('Second'), findsOneWidget, reason: shown);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  group('desktop', () {
    testWidgets('a hand on what presses, a text bar on words, an arrow '
        'elsewhere', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          defaultTargetPlatform,
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphicButton('Save', onPressed: () {}),
                    const SizedBox(height: 24),
                    const NeumorphicButton('Out of use', onPressed: null),
                    const SizedBox(height: 24),
                    const NeumorphicTextField(hintText: 'A name'),
                    const SizedBox(height: 24),
                    const Text('Words'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      await mouse.addPointer(location: const Offset(4, 4));
      addTearDown(mouse.removePointer);
      Future<MouseCursor?> over(Finder target) async {
        await mouse.moveTo(tester.getCenter(target));
        await tester.pump();
        return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
      }

      expect(await over(find.text('Save')), SystemMouseCursors.click);
      expect(
        await over(find.text('Out of use')),
        isNot(SystemMouseCursors.click),
      );
      expect(await over(find.byType(EditableText)), SystemMouseCursors.text);
      expect(await over(find.text('Words')), SystemMouseCursors.basic);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a pointer\'s platforms stand controls 8 shorter than a '
        'finger\'s', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final heights = <TargetPlatform, double>{};
      for (final platform in TargetPlatform.values) {
        if (platform == TargetPlatform.fuchsia) continue;
        debugDefaultTargetPlatformOverride = platform;
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          _app(
            platform,
            Scaffold(
              body: Center(child: NeumorphicButton('Save', onPressed: () {})),
            ),
          ),
        );
        await tester.pumpAndSettle();
        heights[platform] = NeumorphicTheme.of(
          tester.element(find.text('Save')),
        ).density.height(40);
      }
      debugDefaultTargetPlatformOverride = null;
      for (final desk in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        for (final hand in [TargetPlatform.iOS, TargetPlatform.android]) {
          expect(heights[hand]! - heights[desk]!, 8, reason: '$desk $hand');
        }
      }
    });

    testWidgets('the keyboard reaches every control in order and presses it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final pressed = <String>[];
      var on = false;
      await tester.pumpWidget(
        _app(
          defaultTargetPlatform,
          Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphicButton(
                      'One',
                      onPressed: () => pressed.add('One'),
                    ),
                    NeumorphicSwitch(
                      value: on,
                      semanticLabel: 'Lights',
                      onChanged: (v) => setState(() => on = v),
                    ),
                    NeumorphicButton(
                      'Two',
                      onPressed: () => pressed.add('Two'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> key(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }

      await key(LogicalKeyboardKey.tab);
      await key(LogicalKeyboardKey.enter);
      await key(LogicalKeyboardKey.tab);
      await key(LogicalKeyboardKey.space);
      await key(LogicalKeyboardKey.tab);
      await key(LogicalKeyboardKey.space);
      expect(pressed, ['One', 'Two']);
      expect(on, isTrue);
    }, variant: TargetPlatformVariant.desktop());
  });
}
