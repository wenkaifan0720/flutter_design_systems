import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, child) =>
      RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: child!),
  home: Center(child: child),
);

void main() {
  testWidgets('a sheet\'s heading is its own node: a button label in the '
      'body keeps its own name', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          height: 400,
          child: RetroDesktopBottomSheet(
            title: '12 comments',
            onClose: () {},
            actions: [
              // A kit's signed-out composer: a plain annotation, no container.
              Semantics(
                button: true,
                label: 'Sign in to comment',
                onTap: () {},
                child: const SizedBox(width: 200, height: 48),
              ),
            ],
            child: const Text('Where was this filmed?'),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('12 comments'), findsWidgets);
    expect(find.bySemanticsLabel('Sign in to comment'), findsOneWidget);
    semantics.dispose();
  });

  for (final (scale, room) in [(1.0, 560.0), (2.5, 320.0)]) {
    testWidgets('a sheet keeps its footer pinned while the body has room, and '
        'scrolls as one where it would not, text ×$scale', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: RetroDesktopTheme(
              data: RetroDesktopThemeData.classic(),
              child: child!,
            ),
          ),
          home: Center(
            child: SizedBox(
              width: 360,
              height: room,
              child: RetroDesktopBottomSheet(
                title: 'New piece',
                inPlace: true,
                onClose: () {},
                actions: [
                  RetroDesktopButton(
                    'Save piece',
                    isDefaultAction: true,
                    onPressed: () {},
                  ),
                  RetroDesktopButton(
                    'Discard',
                    isDefaultAction: true,
                    onPressed: () {},
                  ),
                ],
                child: Column(
                  children: [
                    for (var i = 0; i < 12; i++) Text('Field $i'),
                    Semantics(
                      container: true,
                      header: true,
                      child: const Text('Options'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final window = tester.getSize(find.byType(Scrollable).first).height;
      // Whichever way, the body's window is never a slit.
      expect(window, greaterThanOrEqualTo(room / 3));
      bool inScroll(String text) => find
          .ancestor(of: find.text(text), matching: find.byType(Scrollable))
          .evaluate()
          .isNotEmpty;
      if (scale == 1.0) {
        expect(inScroll('New piece'), isFalse, reason: 'the heading is pinned');
        expect(inScroll('Save piece'), isFalse, reason: 'the footer is pinned');
      } else {
        expect(inScroll('New piece'), isTrue, reason: 'all of it scrolls');
        // The footer is reached by scrolling, and the body's header with it.
        await tester.scrollUntilVisible(find.text('Save piece'), 100);
        expect(inScroll('Save piece'), isTrue);
        expect(find.bySemanticsLabel('Options'), findsOneWidget);
      }
      semantics.dispose();
    });
  }

  testWidgets('a list sheet keeps its footer pinned, crowded or not', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2.5)),
          child: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: child!,
          ),
        ),
        home: Center(
          child: SizedBox(
            width: 360,
            height: 320,
            child: RetroDesktopBottomSheet(
              title: 'Comments',
              inPlace: true,
              onClose: () {},
              actions: [
                RetroDesktopButton(
                  'Post',
                  isDefaultAction: true,
                  onPressed: () {},
                ),
              ],
              slivers: [
                SliverList.list(
                  children: [for (var i = 0; i < 30; i++) Text('Comment $i')],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The composer is where the hand is: never scrolled away with the list.
    expect(find.text('Post'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('Post'), matching: find.byType(Scrollable)),
      findsNothing,
    );
  });

  for (final width in [200.0, 400.0]) {
    testWidgets(
      'an in-place sheet in a scrolling page takes its content height, $width',
      (tester) async {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: width,
              child: SingleChildScrollView(
                child: RetroDesktopBottomSheet(
                  title: 'Crop',
                  inPlace: true,
                  onClose: () {},
                  actions: [
                    RetroDesktopButton(
                      'Done',
                      isDefaultAction: true,
                      onPressed: () {},
                    ),
                  ],
                  child: const SizedBox(height: 120, child: Text('Picture')),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Picture'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        final sheet = tester.getSize(find.byType(RetroDesktopBottomSheet));
        expect(sheet.height, lessThan(600));
      },
    );
  }

  testWidgets('a selected menu uses one filled selection', (tester) async {
    await tester.pumpWidget(
      _host(
        RetroDesktopMenu<String>(
          items: const [
            RetroDesktopMenuItem('local', 'This computer', selected: true),
          ],
          onSelected: (_) {},
        ),
      ),
    );
    final theme = RetroDesktopTheme.of(
      tester.element(find.text('This computer')),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is ShapeDecoration &&
            (widget.decoration as ShapeDecoration).color ==
                theme.colors.highlight,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(RetroDesktopGlyphs.check), findsNothing);
    expect(find.text('✓'), findsNothing);
  });
  testWidgets('the dialog heading supplies one route name', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const RetroDesktopDialog(
          title: 'Confirm identity',
          message: 'Continue after confirming your identity.',
        ),
      ),
    );
    final heading = find.semantics.byPredicate(
      (node) =>
          node.label == 'Confirm identity' &&
          node.getSemanticsData().flagsCollection.isHeader,
    );
    expect(heading, findsOne);
    expect(
      heading.evaluate().single.getSemanticsData().flagsCollection.namesRoute,
      isTrue,
    );
    expect(
      find.semantics.byPredicate(
        (node) =>
            node.label == 'Confirm identity' &&
            node.getSemanticsData().flagsCollection.namesRoute,
      ),
      findsOne,
    );
    semantics.dispose();
  }, variant: TargetPlatformVariant.all());

  for (final inPlace in [false, true]) {
    testWidgets('narrow sheet keeps its action reachable, inPlace=$inPlace', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(120, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var confirmed = 0;
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(120, 600),
              textScaler: TextScaler.linear(1.3),
            ),
            child: SizedBox(
              width: 120,
              height: 340,
              child: RetroDesktopBottomSheet(
                title: 'Choose a destination',
                onClose: () {},
                inPlace: inPlace,
                controller: controller,
                slivers: [
                  SliverList.list(
                    children: List.generate(
                      20,
                      (i) => SizedBox(height: 40, child: Text('Line $i')),
                    ),
                  ),
                ],
                actions: [
                  RetroDesktopButton('Confirm', onPressed: () => confirmed++),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(controller.position.maxScrollExtent, greaterThan(0));
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      expect(confirmed, 1);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.all());
  }

  testWidgets(
    'in-place sheet keeps footer outside the controlled scroll body',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: Center(
              child: SizedBox(
                width: 320,
                height: 360,
                child: RetroDesktopBottomSheet(
                  title: 'Details',
                  inPlace: true,
                  controller: controller,
                  slivers: [
                    SliverList.list(
                      children: List.generate(
                        30,
                        (i) => SizedBox(height: 40, child: Text('Line $i')),
                      ),
                    ),
                  ],
                  actions: [RetroDesktopButton('Confirm', onPressed: () {})],
                ),
              ),
            ),
          ),
        ),
      );
      final footer = tester.getTopLeft(find.text('Confirm'));
      expect(controller.hasClients, isTrue);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(tester.getTopLeft(find.text('Confirm')), footer);
      expect(find.text('Close'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final sheet in [false, true]) {
    testWidgets(
      '${sheet ? 'sheet' : 'dialog'} captures theme and restores focus after Escape',
      (tester) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        String? seen;
        await tester.pumpWidget(
          _host(
            RetroDesktopTheme(
              data: RetroDesktopThemeData.berry(),
              child: Builder(
                builder: (context) => RetroDesktopPressable(
                  label: 'Open',
                  focusNode: focus,
                  onPressed: () {
                    Widget body(BuildContext raised) {
                      seen = RetroDesktopTheme.of(raised).id;
                      return sheet
                          ? const RetroDesktopBottomSheet(
                              title: 'Details',
                              child: Text('Content'),
                            )
                          : const RetroDesktopDialog(
                              title: 'Details',
                              message: 'Content',
                            );
                    }

                    if (sheet) {
                      showRetroDesktopBottomSheet<void>(context, builder: body);
                    } else {
                      showRetroDesktopDialog<void>(context, builder: body);
                    }
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(seen, 'berry');
        expect(find.text('Details'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Details'), findsNothing);
        expect(focus.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('dialog result and nondismissible barrier', (tester) async {
    bool? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => RetroDesktopButton(
            'Open',
            wide: true,
            onPressed: () async {
              result = await showRetroDesktopDialog<bool>(
                context,
                barrierDismissible: false,
                builder: (context) => RetroDesktopDialog(
                  title: 'Confirm',
                  actions: [
                    RetroDesktopButton(
                      'Yes',
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('menu arrows skip disabled items and return the selected value', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => RetroDesktopButton(
            'Open',
            wide: true,
            onPressed: () async {
              result = await showRetroDesktopMenu<String>(
                context,
                anchor: const Rect.fromLTWH(20, 20, 100, 40),
                items: const [
                  RetroDesktopMenuItem('first', 'First'),
                  RetroDesktopMenuItem(
                    'disabled',
                    'Unavailable',
                    enabled: false,
                  ),
                  RetroDesktopMenuItem('last', 'Last'),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // Opened by a click, no row is lit: the first arrow lights the first row,
    // the next steps over the unavailable one.
    Color? fillOf(String label) =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .ancestor(
                            of: find.text(label),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as ShapeDecoration)
            .color;
    final lit = RetroDesktopTheme.of(tester.element(find.text('First')))
        .colors
        .highlight;
    expect(fillOf('First'), isNot(lit));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(fillOf('First'), lit);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result, 'last');
    expect(find.text('Unavailable'), findsNothing);
  });

  testWidgets(
    'tooltip leaves focus in place and Escape dismisses exactly once',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      late RetroDesktopRaised handle;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => RetroDesktopPressable(
              label: 'Open',
              focusNode: focus,
              onPressed: () {
                handle = showRetroDesktopTooltip(
                  context,
                  message: 'Help',
                  anchor: const Rect.fromLTWH(20, 100, 100, 40),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(find.text('Help'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      handle.dismiss();
      await handle.closed;
      expect(find.text('Help'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'notices replace and dispose their timers and focus without leftovers',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              context = c;
              return const Text('Page');
            },
          ),
        ),
      );
      final first = showRetroDesktopSnackBar(
        context,
        'First',
        duration: const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      final second = showRetroDesktopSnackBar(
        context,
        'Second',
        duration: const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      await first.closed;
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await second.closed;
      expect(find.text('Second'), findsNothing);
      showRetroDesktopSnackBar(context, 'Dispose');
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all-disabled menus can still be dismissed with Escape', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => RetroDesktopButton(
            'Open',
            wide: true,
            onPressed: () => showRetroDesktopMenu<String>(
              context,
              anchor: const Rect.fromLTWH(0, 0, 100, 40),
              items: const [
                RetroDesktopMenuItem('one', 'Unavailable', enabled: false),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Escape closes only the top raised layer', (tester) async {
    late BuildContext dialogContext;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => RetroDesktopButton(
            'Open',
            wide: true,
            onPressed: () => showRetroDesktopDialog<void>(
              context,
              builder: (context) {
                dialogContext = context;
                return const RetroDesktopDialog(title: 'Dialog');
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final tooltip = showRetroDesktopTooltip(
      dialogContext,
      message: 'Topmost help',
      anchor: const Rect.fromLTWH(50, 50, 100, 40),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tooltip.closed;
    expect(find.text('Topmost help'), findsNothing);
    expect(find.text('Dialog'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final platform in TargetPlatform.values) {
    for (final kind in ['dialog', 'sheet', 'menu', 'tooltip', 'snack']) {
      testWidgets('$kind carries local preferences on $platform', (
        tester,
      ) async {
        late BuildContext source;
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true,
                    accessibleNavigation: true,
                    boldText: true,
                    highContrast: true,
                    // The raised surface must still use the real overlay's geometry.
                    size: const Size(100, 100),
                  ),
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(
                      platform: platform,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Localizations.override(
                        context: context,
                        locale: const Locale('en', 'GB'),
                        child: RetroDesktopTheme(
                          data: RetroDesktopThemeData.berry().copyWith(
                            motion: const RetroDesktopMotion(
                              raise: Duration(seconds: 1),
                              leave: Duration(seconds: 1),
                              move: Duration(seconds: 1),
                            ),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Builder(
                              builder: (context) {
                                source = context;
                                return const Text('Page');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        expect(Directionality.of(source), TextDirection.rtl);
        RetroDesktopRaised? handle;
        late Finder face;
        switch (kind) {
          case 'dialog':
            showRetroDesktopDialog<void>(
              source,
              builder: (_) => const RetroDesktopDialog(title: 'Raised'),
            );
            face = find.byType(RetroDesktopDialog);
          case 'sheet':
            showRetroDesktopBottomSheet<void>(
              source,
              builder: (_) => const RetroDesktopBottomSheet(
                title: 'Raised',
                child: Text('Content'),
              ),
            );
            face = find.byType(RetroDesktopBottomSheet);
          case 'menu':
            showRetroDesktopMenu<int>(
              source,
              anchor: const Rect.fromLTWH(40, 80, 100, 40),
              items: const [RetroDesktopMenuItem(1, 'Raised')],
            );
            face = find.byType(RetroDesktopMenu<int>);
          case 'tooltip':
            handle = showRetroDesktopTooltip(
              source,
              message: 'Raised',
              anchor: const Rect.fromLTWH(40, 80, 100, 40),
            );
            face = find.byType(RetroDesktopTooltipFace);
          case 'snack':
            handle = showRetroDesktopSnackBar(
              source,
              'Raised',
              actionLabel: 'Undo',
              onAction: () {},
              duration: const Duration(milliseconds: 100),
            );
            face = find.byType(RetroDesktopSnackBar);
        }
        await tester.pumpAndSettle();
        final context = tester.element(face);
        final media = MediaQuery.of(context);
        expect(media.textScaler.scale(10), 20);
        expect(media.disableAnimations, isTrue);
        expect(media.accessibleNavigation, isTrue);
        expect(media.boldText, isTrue);
        expect(media.highContrast, isTrue);
        expect(media.size, const Size(800, 600));
        expect(Directionality.of(context), TextDirection.rtl);
        expect(Localizations.localeOf(context), const Locale('en', 'GB'));
        expect(ScrollConfiguration.of(context).getPlatform(context), platform);
        expect(RetroDesktopTheme.of(context).id, 'berry');
        expect(RetroDesktopMotion.of(context).move, Duration.zero);
        expect(find.byType(GlowingOverscrollIndicator), findsNothing);
        expect(find.byType(StretchingOverscrollIndicator), findsNothing);
        if (kind == 'snack') {
          await tester.pump(const Duration(seconds: 1));
          expect(
            face,
            findsOneWidget,
            reason: 'A locally accessible action must not expire.',
          );
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        if (handle != null) await handle.closed;
        expect(face, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tooltip stays inside safe areas and above the keyboard', (
    tester,
  ) async {
    late BuildContext source;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.fromLTRB(30, 50, 20, 10),
            viewInsets: const EdgeInsets.only(bottom: 200),
          ),
          child: RetroDesktopTheme(
            data: RetroDesktopThemeData.classic(),
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) {
            source = context;
            return const Text('Page');
          },
        ),
      ),
    );
    for (final anchor in [
      const Rect.fromLTWH(0, 0, 5, 5),
      const Rect.fromLTWH(790, 590, 5, 5),
    ]) {
      final handle = showRetroDesktopTooltip(
        source,
        message: 'Help',
        anchor: anchor,
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(RetroDesktopTooltipFace));
      expect(rect.left, greaterThanOrEqualTo(30));
      expect(rect.top, greaterThanOrEqualTo(50));
      expect(rect.right, lessThanOrEqualTo(780));
      expect(rect.bottom, lessThanOrEqualTo(390));
      handle.dismiss();
      await tester.pumpAndSettle();
      await handle.closed;
    }
    expect(tester.takeException(), isNull);
  });
}
