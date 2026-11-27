// Fluent 2 on each platform: on iOS the edge back-swipe pops a page pushed with the look's page motion (Material's
// page route under an app theme carrying fluent2PageTransitions, and a Fluent2Page), which plays Fluent's push with
// ui_core's swipe back round it; on Android the system back closes what stands over a page (a
// menu, a dialog, a sheet, a select's open list) before it pops the page; on the desktop a pointer over a pressable
// shows the hand; from 640 wide (a tablet, a narrow window) the shell's navigation is the nav pane folded to its rail,
// not a phone's tab bar, and a select opens its list as a popover on the field, its rows still a finger's height.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

class _Page extends StatelessWidget {
  const _Page(this.name, {this.child});

  final String name;
  final Widget? child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFFFFFFF),
    child: SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(name), ?child],
      ),
    ),
  );
}

Future<NavigatorState> _app(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // As the README sets an app up: Fluent 2's push for its own routes.
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: fluent2PageTransitions,
        ),
      ),
      builder: (context, navigator) =>
          Fluent2Host(brightness: Brightness.light, child: navigator!),
      home: const _Page('List'),
    ),
  );
  await t.pumpAndSettle();
  return t.state<NavigatorState>(find.byType(Navigator).first);
}

/// Pushes the page 'Detail' holding [child] and lets it settle.
Future<void> _detail(
  WidgetTester t,
  NavigatorState navigator, {
  Widget? child,
}) async {
  unawaited(
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => _Page('Detail', child: child)),
    ),
  );
  await t.pumpAndSettle();
  expect(find.text('Detail'), findsOneWidget);
  expect(find.text('List'), findsNothing);
}

/// A drag from the window's start edge most of the way across, as a thumb
/// swipes back.
Future<void> _swipeBack(WidgetTester t, double width) async {
  await t.timedDragFrom(
    const Offset(4, 400),
    Offset(width * 0.7, 0),
    const Duration(milliseconds: 300),
  );
  await t.pumpAndSettle();
}

/// The system back (Android's button or gesture), as the platform sends it.
Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

const _options = [
  Fluent2Option('equipment', 'Equipment'),
  Fluent2Option('access', 'Access'),
];

void main() {
  testWidgets('iOS: the edge back-swipe pops a page Material pushed under '
      "the look's theme", (t) async {
    final navigator = await _app(t, const Size(390, 844));
    await _detail(t, navigator);
    expect(
      find.ancestor(
        of: find.text('Detail'),
        matching: find.byType(Fluent2PageTransition),
      ),
      findsOneWidget,
      reason: "Fluent 2's push, not the Cupertino slide",
    );
    await _swipeBack(t, 390);
    expect(find.text('Detail'), findsNothing);
    expect(find.text('List'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS: the edge back-swipe pops a Fluent2Page', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final pages = ValueNotifier<List<Page<void>>>([
      const Fluent2Page<void>(key: ValueKey('list'), child: _Page('List')),
      const Fluent2Page<void>(key: ValueKey('detail'), child: _Page('Detail')),
    ]);
    addTearDown(pages.dispose);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, _) => Fluent2Host(
          brightness: Brightness.light,
          child: ValueListenableBuilder(
            valueListenable: pages,
            builder: (context, list, _) => Navigator(
              pages: list,
              onDidRemovePage: (page) => pages.value = [
                for (final p in pages.value)
                  if (p != page) p,
              ],
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
    await _swipeBack(t, 390);
    expect(find.text('Detail'), findsNothing);
    expect(find.text('List'), findsOneWidget);
    expect(pages.value, hasLength(1));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  group('Android: the system back closes what stands over a page first', () {
    Future<void> check(
      WidgetTester t,
      Size size,
      Future<void> Function(BuildContext page) open,
      Finder raised, {
      Widget? child,
    }) async {
      final navigator = await _app(t, size);
      await _detail(t, navigator, child: child);
      await open(t.element(find.text('Detail')));
      await t.pumpAndSettle();
      expect(raised, findsWidgets, reason: 'it stands over the page');
      await _back(t);
      expect(raised, findsNothing, reason: 'the back closes it');
      expect(find.text('Detail'), findsOneWidget, reason: 'the page stays');
      await _back(t);
      expect(find.text('Detail'), findsNothing, reason: 'then the page pops');
      expect(find.text('List'), findsOneWidget);
    }

    testWidgets('a menu', (t) async {
      await check(
        t,
        const Size(390, 844),
        (page) async => unawaited(
          Fluent2Menu.show<String>(
            page,
            items: const [Fluent2MenuItem('rename', 'Rename')],
          ),
        ),
        find.text('Rename'),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a dialog', (t) async {
      await check(
        t,
        const Size(390, 844),
        (page) async => unawaited(
          Fluent2Dialog.show<void>(
            page,
            (_) => Fluent2Dialog(
              title: 'Delete Q3 plan.docx?',
              actions: [Fluent2Button('Cancel', onPressed: () {})],
            ),
          ),
        ),
        find.text('Delete Q3 plan.docx?'),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('a sheet', (t) async {
      await check(
        t,
        const Size(390, 844),
        (page) async => unawaited(
          Fluent2Sheet.show<void>(
            page,
            title: 'Move to',
            builder: (_) => const [Text('Research')],
          ),
        ),
        find.text('Research'),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    for (final (form, size) in const [
      ("a phone's sheet", Size(390, 844)),
      ("a large window's popover", Size(1280, 800)),
    ]) {
      testWidgets("a select's open list, $form", (t) async {
        await check(
          t,
          size,
          (page) async {
            await t.tap(find.text('Equipment'));
          },
          find.text('Access'),
          child: SizedBox(
            width: 320,
            child: Fluent2Select<String>(
              semanticLabel: 'Type',
              value: 'equipment',
              options: _options,
              onChanged: (_) {},
            ),
          ),
        );
      }, variant: TargetPlatformVariant.only(TargetPlatform.android));
    }

    testWidgets("a combobox's open list", (t) async {
      await check(
        t,
        const Size(390, 844),
        (page) async {
          await t.tap(find.byType(EditableText));
        },
        find.text('Access'),
        child: SizedBox(
          width: 320,
          child: Fluent2Combobox<String>(
            semanticLabel: 'Type',
            value: 'equipment',
            options: _options,
            onChanged: (_) {},
          ),
        ),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });

  testWidgets("a tablet: a raised sheet stands no wider than the desktop's "
      'dialog, centred over the foot', (t) async {
    final navigator = await _app(t, const Size(768, 1024));
    await _detail(t, navigator);
    unawaited(
      Fluent2Sheet.show<void>(
        t.element(find.text('Detail')),
        title: 'Move to',
        builder: (_) => const [Text('Research')],
      ),
    );
    await t.pumpAndSettle();
    final sheet = t.getRect(find.byType(Fluent2SheetShell));
    expect(sheet.width, Fluent2ChromeMetrics.dialogWidth);
    expect(sheet.center.dx, 384);
    expect(sheet.bottom, 1024);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a tablet: a select opens its list as a popover on the field, '
      "its rows a finger's height", (t) async {
    final navigator = await _app(t, const Size(768, 1024));
    await _detail(
      t,
      navigator,
      child: SizedBox(
        width: 320,
        child: Fluent2Select<String>(
          semanticLabel: 'Type',
          value: 'equipment',
          options: _options,
          onChanged: (_) {},
        ),
      ),
    );
    final field = t.getRect(find.byType(Fluent2Select<String>));
    await t.tap(find.text('Equipment'));
    await t.pumpAndSettle();
    expect(find.byType(Fluent2SheetShell), findsNothing, reason: 'no sheet');
    final row = t.getRect(find.text('Access'));
    expect(row.left, greaterThan(field.left), reason: 'on the field');
    expect(row.left, lessThan(field.left + 48), reason: 'on the field');
    expect(row.top, greaterThan(field.bottom - 1), reason: 'under the field');
    // One row to the next: a finger's row (the floor, 40) and the list's 2
    // between.
    final first = t.getRect(
      find.descendant(
        of: find.byType(Scrollable),
        matching: find.text('Equipment'),
      ),
    );
    expect(
      row.center.dy - first.center.dy,
      greaterThanOrEqualTo(RawTapTargets.fallback.touch.height),
      reason: "a finger's row",
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('desktop: a pointer over a pressable shows the hand', (t) async {
    final navigator = await _app(t, const Size(1280, 800));
    await _detail(t, navigator, child: Fluent2Button('Save', onPressed: () {}));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: t.getCenter(find.text('Save')));
    await t.pump();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
  }, variant: TargetPlatformVariant.desktop());
}
