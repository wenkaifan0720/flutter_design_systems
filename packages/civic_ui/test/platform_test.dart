// Civic and Brindlemere on each platform's own terms. iOS: a swipe from the
// screen's leading edge pops a page, past half way, with the page following
// the finger, while a push still plays Civic's own change (nothing travels).
// Android: the system back pops an inner page to the one before, and closes
// a dialog over a page before it pops the page; on a place of the
// navigation it leaves the app to the system. Desktop: the keyboard alone
// reaches a page's every control in reading order, and every pressable
// shows the pointing hand.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';
import 'dart:convert';

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/permits/permits.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : civicFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _open(
  WidgetTester tester,
  PermitsPage page, {
  double width = 390,
  double height = 844,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(PermitsApp(initialPage: page));
  await tester.pumpAndSettle();
}

/// The system's back, as Android sends it; whether the app took it.
Future<bool> _systemBack(WidgetTester tester) async {
  final taken = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return taken;
}

/// The words a focused control shows, from its focus's subtree.
String _wordsOf(BuildContext context) {
  final words = StringBuffer();
  void visit(Element element) {
    final widget = element.widget;
    if (widget is RichText) words.write(widget.text.toPlainText());
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return words.toString();
}

final _android = TargetPlatformVariant.only(TargetPlatform.android);
final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

/// A Material app on Civic's page change, as the README sets it up, its
/// first page reading "First".
Future<NavigatorState> _plain(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: civicPageTransitions,
        ),
      ),
      builder: (context, child) =>
          CivicTheme(data: CivicThemeData.light(), child: child!),
      home: const Center(child: Text('First')),
    ),
  );
  return navigator.currentState!;
}

void main() {
  setUpAll(_loadFonts);

  group('iOS', () {
    testWidgets("a swipe from the leading edge pops a CivicPageRoute, the page "
        "following the finger, and a short one settles back", (tester) async {
      final navigator = await _plain(tester);
      unawaited(
        navigator.push(
          CivicPageRoute<void>(
            builder: (context) => const Center(child: Text('Second')),
          ),
        ),
      );
      // The push is Civic's own: the words fade in where they stand.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      final resting = tester.getTopLeft(find.text('Second'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Second')), resting);

      // A short drag settles back.
      await tester.dragFrom(const Offset(4, 400), const Offset(60, 0));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('First'), findsNothing);

      // A long one: the page follows the finger, then pops.
      final finger = await tester.startGesture(const Offset(4, 400));
      await finger.moveBy(const Offset(20, 0));
      await finger.moveBy(const Offset(120, 0));
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('Second')).dx,
        greaterThan(resting.dx + 80),
      );
      expect(
        find.text('First'),
        findsOneWidget,
        reason: 'the page under shows',
      );
      await finger.moveBy(const Offset(120, 0));
      await finger.up();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.text('First'), findsOneWidget);
    }, variant: _iOS);

    testWidgets(
      "a page Flutter's MaterialPageRoute pushes takes the same swipe, from "
      "civicPageTransitions",
      (tester) async {
        final navigator = await _plain(tester);
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(
              builder: (context) => const Center(child: Text('Second')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.dragFrom(const Offset(4, 400), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.text('Second'), findsNothing);
        expect(find.text('First'), findsOneWidget);
      },
      variant: _iOS,
    );

    testWidgets(
      "a swipe from the leading edge pops Brindlemere's inner pages, and a "
      "place of the navigation takes none",
      (tester) async {
        await _open(tester, PermitsPage.vehicle);
        await tester.dragFrom(const Offset(4, 400), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(find.text('Your permit application'), findsOneWidget);
        await tester.dragFrom(const Offset(4, 400), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(
          find.text('Apply for a resident parking permit'),
          findsOneWidget,
        );
        await tester.dragFrom(const Offset(4, 400), const Offset(300, 0));
        await tester.pumpAndSettle();
        expect(
          find.text('Apply for a resident parking permit'),
          findsOneWidget,
        );
      },
      variant: _iOS,
    );
  });

  group('Android', () {
    testWidgets(
      'the system back pops each inner page to the one before, then leaves '
      'a place of the navigation to the system',
      (tester) async {
        await _open(tester, PermitsPage.vehicle);
        expect(
          find.text('What kind of vehicle is the permit for?'),
          findsOneWidget,
        );
        expect(await _systemBack(tester), isTrue);
        expect(find.text('Your permit application'), findsOneWidget);
        expect(await _systemBack(tester), isTrue);
        expect(
          find.text('Apply for a resident parking permit'),
          findsOneWidget,
        );
        expect(
          await _systemBack(tester),
          isFalse,
          reason: "a place of the navigation is the app's first page",
        );
      },
      variant: _android,
    );

    testWidgets("the bar's back control pops as the system back does", (
      tester,
    ) async {
      await _open(tester, PermitsPage.application);
      final back = find.descendant(
        of: find.byType(CivicTopBar),
        matching: find.byType(CivicIconButton),
      );
      expect(back, findsOneWidget);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('Your applications'), findsWidgets);
      expect(back, findsNothing, reason: 'a place of the navigation');
    }, variant: _android);

    testWidgets('the system back closes a dialog before the page under it', (
      tester,
    ) async {
      await _open(tester, PermitsPage.application);
      await tester.ensureVisible(find.text('Withdraw application'));
      await tester.tap(find.text('Withdraw application'));
      await tester.pumpAndSettle();
      expect(find.text('Withdraw this application?'), findsOneWidget);
      expect(await _systemBack(tester), isTrue);
      expect(find.text('Withdraw this application?'), findsNothing);
      expect(find.text('Resident permit, Zone B'), findsWidgets);
    }, variant: _android);

    testWidgets('after a change from the answers, Continue goes back to them', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _open(tester, PermitsPage.check);
      final change = find.bySemanticsLabel('Change Vehicle');
      await tester.ensureVisible(change);
      await tester.tap(change);
      await tester.pumpAndSettle();
      expect(
        find.text('What kind of vehicle is the permit for?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Check your answers before sending your application'),
        findsOneWidget,
      );
      // And its back goes on to the details, as before the change.
      expect(await _systemBack(tester), isTrue);
      expect(find.text('Your details'), findsOneWidget);
      semantics.dispose();
    }, variant: _android);
  });

  group('desktop', () {
    testWidgets(
      'Tab alone reaches every control of the start page, in reading order',
      (tester) async {
        await _open(tester, PermitsPage.start, width: 1440, height: 900);
        final reached = <String>[];
        for (var i = 0; i < 20; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final context = FocusManager.instance.primaryFocus?.context;
          if (context == null) continue;
          reached.add(_wordsOf(context));
        }
        int at(String words) => reached.indexWhere((w) => w.contains(words));
        expect(at('Skip to main content'), 0, reason: '$reached');
        expect(at('Start now'), greaterThan(0), reason: '$reached');
        expect(at('Find your permit zone'), greaterThan(at('Start now')));
      },
      variant: TargetPlatformVariant.desktop(),
    );

    testWidgets('every pressable shows the pointing hand', (tester) async {
      await _open(tester, PermitsPage.start, width: 1440, height: 900);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      for (final words in [
        'Start now',
        'Find your permit zone',
        'Applications',
        'Settings',
        'Brindlemere parking permits',
      ]) {
        await mouse.moveTo(tester.getCenter(find.text(words).first));
        await tester.pump();
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.click,
          reason: words,
        );
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });
}
