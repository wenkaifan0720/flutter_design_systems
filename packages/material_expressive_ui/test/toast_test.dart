/// Toasts: Compose's `Snackbar` (the legacy one-row and new-line layouts,
/// its tokens) and `SnackbarHost` (the queue, timeouts, the fade-and-scale
/// springs, placement above the shell).
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/snackbar_tokens.g.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

Widget host(
  WidgetBuilder builder, {
  TextDirection direction = TextDirection.ltr,
  double allowance = 0,
  double textScale = 1,
}) => MaterialApp(
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(
      textDirection: direction,
      child: ExpressiveHost(
        theme: bloom,
        brightness: Brightness.light,
        child: app!,
      ),
    ),
  ),
  home: Column(
    children: <Widget>[
      Expanded(
        child: Builder(
          builder: (context) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 400, child: builder(context)),
          ),
        ),
      ),
      // A bar [allowance] tall along the foot, marked as the shell marks
      // its own.
      RawToasterKeepClear(child: SizedBox(height: allowance)),
    ],
  ),
);

Finder get surface => find.byType(ExpressiveSurface).first;

Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

/// The button whose label is [label]: its touch-target box.
Finder button(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(ExpressivePressable),
);

double baselineOf(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout(maxWidth: paragraph.size.width);
  final baseline = painter.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  painter.dispose();
  return tester.getTopLeft(find.text(text)).dy + baseline;
}

void main() {
  group('snackbar', () {
    testWidgets('one line centres in 48dp, action on the baseline', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => ExpressiveSnackBar(
            'Draft saved',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
      );
      final box = rectOf(tester, surface);
      expect(box.width, 400);
      expect(box.height, SnackbarTokens.singleLineContainerHeight);
      final paint = tester.widget<ExpressiveSurface>(surface);
      expect(paint.color, bloom.colors.inverseSurface);
      expect(paint.shadowElevation, ExpressiveElevationLevel.level3);
      expect(
        (paint.shape as ExpressiveCornerBorder).radiiOn(box).topLeft.x,
        bloom.shapes.of(SnackbarTokens.containerShape).radiiOn(box).topLeft.x,
      );
      final message = tester.getRect(find.text('Draft saved'));
      expect(message.left - box.left, SnackbarBehavior.horizontalSpacing);
      expect(message.center.dy, closeTo(box.center.dy, 0.01));
      final style = tester.widget<Text>(find.text('Draft saved')).style!;
      expect(style.fontSize, bloom.type.bodyMedium.fontSize);
      expect(style.color, bloom.colors.inverseOnSurface);
      // The action: a text button in inversePrimary, 8dp from the end,
      // its label on the message's baseline.
      final action = tester.getRect(button('Undo'));
      expect(
        box.right - action.right,
        SnackbarBehavior.horizontalSpacingButtonSide,
      );
      expect(
        baselineOf(tester, 'Undo'),
        closeTo(baselineOf(tester, 'Draft saved'), 0.01),
      );
      final label = tester
          .renderObject<RenderParagraph>(find.text('Undo'))
          .text
          .style!;
      expect(label.color, bloom.colors.inversePrimary);
    });

    testWidgets('the action has TextButton metrics: 12dp sides, 58dp least', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => ExpressiveSnackBar(
            'Your reading list is up to date',
            actionLabel: 'Open reading list',
            onAction: () {},
          ),
        ),
      );
      final text = tester.getRect(find.text('Open reading list'));
      final action = tester.getRect(button('Open reading list'));
      // The 40dp container is the touch floor; 12dp padding each side.
      expect(action.height, 40);
      expect(text.left - action.left, closeTo(12, 0.01));
      expect(action.right - text.right, closeTo(12, 0.01));
      await tester.pumpWidget(
        host(
          (context) =>
              ExpressiveSnackBar('Saved', actionLabel: 'OK', onAction: () {}),
        ),
      );
      expect(tester.getRect(button('OK')).width, ButtonBehavior.minWidth);
    });

    testWidgets('a close button takes the end, the action before it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => ExpressiveSnackBar(
            'Back online',
            actionLabel: 'Refresh',
            onAction: () {},
            withDismissAction: true,
            onDismiss: () {},
          ),
        ),
      );
      final box = rectOf(tester, surface);
      final close = tester.getRect(find.byType(ExpressiveIconButton));
      expect(close.right, box.right);
      expect(close.size, const Size(40, 40)); // the touch floor
      expect(close.center.dy, closeTo(box.center.dy, 0.01));
      final action = tester.getRect(button('Refresh'));
      expect(action.right, close.left);
      final glyph = tester.widget<Icon>(find.byType(Icon).last);
      expect(glyph.icon, ExpressiveSymbols.close);
      expect(
        find.bySemanticsLabel(ExpressiveLocalizations.english.toastDismiss),
        findsOneWidget,
      );
    });

    testWidgets('more lines: first baseline 30dp down, at least 68dp', (
      tester,
    ) async {
      const message =
          'Evening Run was shared with Priya, Tomás and two others who '
          'can now add their own runs';
      await tester.pumpWidget(
        host(
          (context) =>
              ExpressiveSnackBar(message, actionLabel: 'View', onAction: () {}),
        ),
      );
      final box = rectOf(tester, surface);
      expect(
        box.height,
        greaterThanOrEqualTo(SnackbarTokens.twoLinesContainerHeight),
      );
      expect(
        baselineOf(tester, message) - box.top,
        closeTo(SnackbarBehavior.heightToFirstLine, 0.01),
      );
      final action = tester.getRect(button('View'));
      expect(action.center.dy, closeTo(box.center.dy, 0.01));
      final text = tester.getRect(find.text(message));
      expect(text.right, lessThanOrEqualTo(action.left));
    });

    testWidgets('the action on its own line sits under the text, at the end', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => ExpressiveSnackBar(
            'Two of your notes changed on another device',
            actionLabel: 'Review changes',
            onAction: () {},
            actionOnNewLine: true,
          ),
        ),
      );
      final box = rectOf(tester, surface);
      final text = tester.getRect(
        find.text('Two of your notes changed on another device'),
      );
      final action = tester.getRect(button('Review changes'));
      expect(
        baselineOf(tester, 'Two of your notes changed on another device') -
            box.top,
        closeTo(SnackbarBehavior.heightToFirstLine, 0.01),
      );
      expect(action.top, greaterThanOrEqualTo(text.bottom));
      expect(
        box.right - action.right,
        SnackbarBehavior.horizontalSpacingButtonSide,
      );
      expect(box.bottom - action.bottom, SnackbarBehavior.separateButtonExtraY);
    });

    testWidgets('grows no wider than 600dp of content', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ExpressiveHost(
            theme: bloom,
            brightness: Brightness.light,
            child: app!,
          ),
          home: const Center(child: ExpressiveSnackBar('Draft saved')),
        ),
      );
      expect(
        rectOf(tester, surface).width,
        SnackbarBehavior.horizontalSpacing +
            SnackbarBehavior.containerMaxWidth +
            SnackbarBehavior.horizontalSpacingButtonSide,
      );
    });

    testWidgets('mirrors right to left', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => ExpressiveSnackBar(
            'Draft saved',
            actionLabel: 'Undo',
            onAction: () {},
          ),
          direction: TextDirection.rtl,
        ),
      );
      final box = rectOf(tester, surface);
      final message = tester.getRect(find.text('Draft saved'));
      expect(box.right - message.right, SnackbarBehavior.horizontalSpacing);
      final action = tester.getRect(button('Undo'));
      expect(
        action.left - box.left,
        SnackbarBehavior.horizontalSpacingButtonSide,
      );
    });

    testWidgets('holds a larger text scale', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => ExpressiveSnackBar(
            'Your weekly summary is ready to read',
            actionLabel: 'Open',
            onAction: () {},
            withDismissAction: true,
            onDismiss: () {},
          ),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final box = rectOf(tester, surface);
      final text = tester.getRect(
        find.text('Your weekly summary is ready to read'),
      );
      expect(text.top, greaterThanOrEqualTo(box.top));
      expect(text.bottom, lessThanOrEqualTo(box.bottom));
    });

    testWidgets('one line of large text keeps its padding', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => const ExpressiveSnackBar('Draft saved'),
          textScale: 2,
        ),
      );
      final box = rectOf(tester, surface);
      final text = tester.getRect(find.text('Draft saved'));
      expect(text.top - box.top, greaterThanOrEqualTo(6 - 0.01));
      expect(box.bottom - text.bottom, greaterThanOrEqualTo(6 - 0.01));
    });

    for (final direction in TextDirection.values) {
      testWidgets('stretched past 600dp, the action keeps to the end '
          '(${direction.name})', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: ExpressiveHost(
                theme: bloom,
                brightness: Brightness.light,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 760,
                    child: ExpressiveSnackBar(
                      'Photo moved to the archive',
                      actionLabel: 'Undo',
                      onAction: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final box = rectOf(tester, surface);
        // The test's window is 800 wide.
        expect(box.width, 760);
        final action = tester.getRect(button('Undo'));
        final end = direction == TextDirection.ltr
            ? box.right - action.right
            : action.left - box.left;
        // As at 400dp: the button side's 8dp from the container's end.
        expect(end, SnackbarBehavior.horizontalSpacingButtonSide);
      });
    }
  });

  group('host', () {
    testWidgets('a toast showing when its tree goes leaves no timer behind', (
      tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }),
      );
      showExpressiveSnackBar(page, 'Note archived', actionLabel: 'Undo');
      await tester.pump();
      expect(find.text('Note archived'), findsOneWidget);
      // The whole app goes while the toast's timeout is still running; the
      // test binding fails on any timer left pending.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(find.text('Note archived'), findsNothing);
    });

    testWidgets('shows above the shell, fades and scales in, times out', (
      tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }, allowance: 150),
      );
      showExpressiveSnackBar(page, 'Draft saved');
      await tester.pump();
      await tester.pump();
      final entering = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byType(ExpressiveSnackBar),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(entering.opacity, lessThan(1));
      await tester.pumpAndSettle();
      // The icon is accepted and not drawn.
      expect(find.byIcon(ExpressiveSymbols.check), findsNothing);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final box = rectOf(tester, surface);
      expect(
        box.bottom,
        closeTo(screen.height - 150 - SnackbarBehavior.margin, 0.01),
      );
      // Centred, at most 600dp of content wide.
      expect(box.center.dx, closeTo(screen.width / 2, 0.01));
      expect(
        box.width,
        SnackbarBehavior.horizontalSpacing +
            SnackbarBehavior.containerMaxWidth +
            SnackbarBehavior.horizontalSpacingButtonSide,
      );
      await tester.pump(ExpressiveSnackBarDuration.short.timeout!);
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveSnackBar), findsNothing);
    });

    testWidgets('stands above a pushed screen\'s docked footer', (
      tester,
    ) async {
      final footer = GlobalKey();
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ExpressiveHost(
            theme: bloom,
            brightness: Brightness.light,
            child: app!,
          ),
          home: const SizedBox.shrink(),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) {
              page = context;
              return ExpressiveScaffold(
                title: 'Show',
                body: const SizedBox(),
                footer: SizedBox(key: footer, height: 64),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      showExpressiveSnackBar(page, 'Following');
      await tester.pumpAndSettle();
      // Pushed, the page reserves no shell allowance; its footer is what
      // the toast must clear.
      final band = rectOf(tester, find.byKey(footer));
      final toast = find
          .descendant(
            of: find.byType(ExpressiveSnackBar),
            matching: find.byType(ExpressiveSurface),
          )
          .first;
      expect(
        rectOf(tester, toast).bottom,
        closeTo(
          band.top - ExpressiveSpacing.s8 - SnackbarBehavior.margin,
          0.01,
        ),
      );
      hideCurrentExpressiveSnackBar(page);
      await tester.pumpAndSettle();
    });

    testWidgets('queues: one at a time, in order', (tester) async {
      late BuildContext page;
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }),
      );
      showExpressiveSnackBar(page, 'Uploading 3 photos');
      showExpressiveSnackBar(page, 'Upload finished');
      await tester.pumpAndSettle();
      expect(find.text('Uploading 3 photos'), findsOneWidget);
      expect(find.text('Upload finished'), findsNothing);
      await tester.pump(ExpressiveSnackBarDuration.short.timeout!);
      // The first leaves, then the second enters, as Material's
      // ScaffoldMessenger hands one to the next.
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Uploading 3 photos'), findsOneWidget);
      expect(find.text('Upload finished'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Uploading 3 photos'), findsNothing);
      expect(find.text('Upload finished'), findsOneWidget);
      await tester.pump(ExpressiveSnackBarDuration.short.timeout!);
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveSnackBar), findsNothing);
    });

    testWidgets('the action runs and dismisses', (tester) async {
      late BuildContext page;
      var undone = 0;
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }),
      );
      showExpressiveSnackBar(
        page,
        'Photo moved to the archive',
        actionLabel: 'Undo',
        onAction: () => undone++,
      );
      await tester.pumpAndSettle();
      expect(find.text('Photo moved to the archive'), findsOneWidget);
      await tester.tap(button('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(find.byType(ExpressiveSnackBar), findsNothing);
    });

    // Allow two bounded pumps for an action toast to finish its timer and
    // exit animation.
    testWidgets('an action toast is gone within the walkthrough drain', (
      tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }),
      );
      showExpressiveSnackBar(
        page,
        'List deleted',
        actionLabel: 'Undo',
        onAction: () {},
      );
      await tester.pump();
      expect(find.text('List deleted'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 2500));
      // The timeout has fired: the toast is leaving on its springs, and
      // teardown finds no Timer pending.
      expect(find.byType(ExpressiveSnackBar), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveSnackBar), findsNothing);
    });

    testWidgets('indefinite waits for its close button', (tester) async {
      late BuildContext page;
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }),
      );
      showExpressiveSnackBar(
        page,
        'Sync paused',
        withDismissAction: true,
        duration: ExpressiveSnackBarDuration.indefinite,
      );
      await tester.pumpAndSettle();
      await tester.pump(ExpressiveSnackBarDuration.long.timeout! * 2);
      await tester.pumpAndSettle();
      expect(find.text('Sync paused'), findsOneWidget);
      final semantics = tester.getSemantics(
        find
            .ancestor(
              of: find.byType(ExpressiveSnackBar),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.liveRegion == true,
              ),
            )
            .first,
      );
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.dismiss),
        isTrue,
      );
      await tester.tap(find.byType(ExpressiveIconButton));
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveSnackBar), findsNothing);
    });

    testWidgets('dismissCurrent moves the queue on', (tester) async {
      late BuildContext page;
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }),
      );
      showExpressiveSnackBar(
        page,
        'First',
        duration: ExpressiveSnackBarDuration.indefinite,
      );
      showExpressiveSnackBar(page, 'Second');
      await tester.pumpAndSettle();
      hideCurrentExpressiveSnackBar(page);
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      await tester.pump(ExpressiveSnackBarDuration.short.timeout!);
      await tester.pumpAndSettle();
    });

    testWidgets("stands above a shell's bar and action", (tester) async {
      // A phone: the shell's bar (from 600dp it is a rail).
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ExpressiveHost(
            theme: bloom,
            brightness: Brightness.light,
            child: app!,
          ),
          home: ExpressiveShellScaffold(
            tabs: const <NavTab>[
              NavTab(
                icon: ExpressiveSymbols.home,
                label: 'Home',
                location: '/',
              ),
              NavTab(
                icon: ExpressiveSymbols.person,
                label: 'You',
                location: '/you',
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            action: ExpressiveShellAction(
              icon: ExpressiveSymbols.add,
              onPressed: (_) {},
            ),
            body: Builder(
              builder: (context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      showExpressiveSnackBar(page, 'Draft saved');
      await tester.pumpAndSettle();
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      // The action rides 16dp over the bar: the snackbar stands above both,
      // where 0.4.1 put it from the shell's allowance.
      expect(
        rectOf(
          tester,
          find
              .descendant(
                of: find.byType(ExpressiveSnackBar),
                matching: find.byType(ExpressiveSurface),
              )
              .first,
        ).bottom,
        closeTo(
          screen.height -
              ExpressiveShellInsets.allowance(systemInset: 0, action: true) -
              SnackbarBehavior.margin,
          0.01,
        ),
      );
      hideCurrentExpressiveSnackBar(page);
      await tester.pumpAndSettle();
    });

    testWidgets('stands above the keyboard', (tester) async {
      late BuildContext page;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        host((context) {
          page = context;
          return const SizedBox.shrink();
        }, allowance: 80),
      );
      showExpressiveSnackBar(page, 'Draft saved');
      await tester.pumpAndSettle();
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      // The keyboard covers the bar: the snackbar stands on the keyboard.
      expect(
        rectOf(tester, surface).bottom,
        closeTo(
          screen.height -
              300 / tester.view.devicePixelRatio -
              SnackbarBehavior.margin,
          0.01,
        ),
      );
      hideCurrentExpressiveSnackBar(page);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'one with an action stays while a screen reader runs; one without '
      'times out',
      (tester) async {
        late BuildContext page;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(accessibleNavigation: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pumpWidget(
          host((context) {
            page = context;
            return const SizedBox.shrink();
          }),
        );
        showExpressiveSnackBar(page, 'Note archived');
        showExpressiveSnackBar(
          page,
          'List deleted',
          actionLabel: 'Undo',
          onAction: () {},
        );
        await tester.pumpAndSettle();
        await tester.pump(ExpressiveSnackBarDuration.short.timeout!);
        await tester.pumpAndSettle();
        expect(find.text('Note archived'), findsNothing);
        expect(find.text('List deleted'), findsOneWidget);
        // As Material's ScaffoldMessenger holds a snackbar with an action.
        await tester.pump(ExpressiveSnackBarDuration.long.timeout! * 2);
        await tester.pumpAndSettle();
        expect(find.text('List deleted'), findsOneWidget);
        hideCurrentExpressiveSnackBar(page);
        await tester.pumpAndSettle();
        expect(find.byType(ExpressiveSnackBar), findsNothing);
      },
    );

    testWidgets('with no ExpressiveHost, says how to mount one', (
      tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              page = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        () => showExpressiveSnackBar(page, 'Draft saved'),
        throwsA(
          isA<FlutterError>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('found no ExpressiveHost'),
              contains(
                'MaterialApp(builder: (context, child) => '
                'ExpressiveHost(child: child!))',
              ),
            ),
          ),
        ),
      );
    });

    testWidgets("a screen's footer holds it up only while the screen shows", (
      tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ExpressiveHost(
            theme: bloom,
            brightness: Brightness.light,
            child: app!,
          ),
          home: const ExpressiveScaffold(
            title: 'Library',
            body: SizedBox(),
            footer: SizedBox(height: 64),
          ),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) {
              page = context;
              return const ExpressiveScaffold(
                title: 'Details',
                body: SizedBox(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      showExpressiveSnackBar(page, 'Following');
      await tester.pumpAndSettle();
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      // The page over the footer docks nothing: the snackbar stands at
      // the foot (ui_core 0.5.1 lets a covered route's part go).
      expect(
        rectOf(
          tester,
          find
              .descendant(
                of: find.byType(ExpressiveSnackBar),
                matching: find.byType(ExpressiveSurface),
              )
              .first,
        ).bottom,
        closeTo(screen.height - SnackbarBehavior.margin, 0.01),
      );
      hideCurrentExpressiveSnackBar(page);
      await tester.pumpAndSettle();
    });
  });
}
