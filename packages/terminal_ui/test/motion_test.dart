// Structure never travels: every pane a change brings is, from the first
// frame it shows in, where it stays. A select's menu opens under its field,
// a tab change and a screen change move no box, and a dialog and a toast
// come up in place; only their opacity eases.
import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/overview.dart';
import '../example/lib/kit_gallery/slipway.dart';

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Every pane on screen, by its element, with its rect on screen.
Map<Element, Rect> _panes() => {
  for (final element in find.byType(TermPane).evaluate())
    if (element.renderObject case final RenderBox box when box.hasSize)
      element: box.localToGlobal(Offset.zero) & box.size,
};

/// Pumps the frame a change starts in, then [frames] more 16 ms apart, and
/// returns every pane's rect in each.
Future<List<Map<Element, Rect>>> _frames(
  WidgetTester tester, {
  int frames = 30,
}) async {
  await tester.pump();
  final seen = [_panes()];
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    seen.add(_panes());
  }
  return seen;
}

/// Every pane in [seen] sits, in each frame it shows in, at the rect it
/// settles at.
void _expectNoTravel(List<Map<Element, Rect>> seen) {
  final last = seen.last;
  expect(last, isNotEmpty);
  for (var i = 0; i < seen.length; i++) {
    for (final MapEntry(key: element, value: rect) in seen[i].entries) {
      final end = last[element];
      if (end == null) continue;
      expect(
        rect,
        end,
        reason:
            'frame $i: ${element.widget.toStringShort()} at $rect '
            'settles at $end',
      );
    }
  }
}

/// The panes in [seen]'s last frame that [before] did not have.
Map<Element, Rect> _new(
  Map<Element, Rect> before,
  List<Map<Element, Rect>> seen,
) => {
  for (final MapEntry(:key, :value) in seen.last.entries)
    if (!before.containsKey(key)) key: value,
};

/// The rect of [element] in the first frame of [seen] it shows in.
Rect _first(List<Map<Element, Rect>> seen, Element element) =>
    seen.firstWhere((frame) => frame.containsKey(element))[element]!;

/// What carries a page in from elsewhere, round [of]: a slide, a zoom, a
/// turn, a picture of it moved about. One at rest carries nothing: iOS's
/// swipe back (`ui_core`'s, round Terminal's change) holds the page in a
/// slide that stays still until a finger drags it.
bool _carries(Widget w) => switch (w) {
  SlideTransition(:final position) => position.value != Offset.zero,
  FractionalTranslation(:final translation) => translation != Offset.zero,
  ScaleTransition(:final scale) => scale.value != 1,
  RotationTransition(:final turns) => turns.value != 0,
  SnapshotWidget() => true,
  _ => false,
};

List<Type> _flying(Finder of) => [
  for (final element
      in find
          .ancestor(of: of, matching: find.byWidgetPredicate(_carries))
          .evaluate())
    element.widget.runtimeType,
];

Widget _host(Widget home) => MaterialApp(
  builder: (context, child) => TermTheme(
    data: TermThemeData.dark(),
    child: TermToaster(child: child!),
  ),
  home: home,
);

void main() {
  testWidgets("an inline select's menu opens under its brackets", (
    tester,
  ) async {
    _size(tester, const Size(768, 1024));
    await tester.pumpWidget(
      slipwayApp(Brightness.dark, place: SlipwayPlace.settings),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final before = _panes();
    final value = tester.getRect(find.text('staging').first);
    final cell = tester.element(find.text('staging').first).termGrid.cellWidth;
    final field = tester.getRect(
      find.ancestor(
        of: find.text('staging').first,
        matching: find.byWidgetPredicate((w) => w is TermSelect),
      ),
    );

    await tester.tap(find.text('staging').first);
    final seen = await _frames(tester);
    final menus = _new(before, seen);
    expect(menus, hasLength(1));
    final menu = menus.keys.single;
    final first = _first(seen, menu);
    // Its first frame is already at its anchor: under the field, starting
    // at the brackets the value sits in (a cell or so before its words).
    expect(first.top, field.bottom);
    expect(first.left, lessThanOrEqualTo(value.left));
    expect(first.left, greaterThanOrEqualTo(value.left - 2 * cell));
    expect(first.right, lessThanOrEqualTo(field.right));
    _expectNoTravel(seen);
  });

  testWidgets("a framed select's menu opens under it on a phone", (
    tester,
  ) async {
    _size(tester, const Size(390, 844));
    await tester.pumpWidget(
      slipwayApp(Brightness.dark, place: SlipwayPlace.deploy),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final before = _panes();
    final field = tester.getRect(
      find.ancestor(
        of: find.text('staging').first,
        matching: find.byWidgetPredicate((w) => w is TermSelect),
      ),
    );

    await tester.tap(find.text('staging').first);
    final seen = await _frames(tester);
    final menu = _new(before, seen).keys.single;
    final first = _first(seen, menu);
    expect(first.left, field.left);
    // As wide as the field, its frame on the field's.
    expect(first.width, moreOrLessEquals(field.width, epsilon: 0.01));
    expect(
      first.top == field.bottom || first.bottom == field.top,
      isTrue,
      reason: 'the menu at $first touches the field at $field',
    );
    _expectNoTravel(seen);
  });

  testWidgets('a tab change moves no box', (tester) async {
    _size(tester, const Size(768, 1024));
    await tester.pumpWidget(slipwayApp(Brightness.dark));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('runs').first);
    _expectNoTravel(await _frames(tester));
  });

  testWidgets('a screen pushed from the overview comes up in place', (
    tester,
  ) async {
    _size(tester, const Size(1440, 900));
    await tester.pumpWidget(overviewApp(Brightness.dark));
    await tester.pump(const Duration(milliseconds: 500));
    final before = _panes();
    await tester.tap(find.text('new deploy').first);
    final seen = await _frames(tester);
    expect(_new(before, seen), isNotEmpty);
    _expectNoTravel(seen);
  });

  // The example is an app on Flutter's own Material: the Overview opens
  // slipway with Flutter's MaterialPageRoute, which reads the app's
  // ThemeData (termPageTransitions there), not the theme
  // TermTheme sets on material_ui. The example's own test checks that theme
  // and the slide an app without it gets; this one keeps the push in place
  // wherever the package's tests run.
  testWidgets("the example's MaterialPageRoute changes screens in place on "
      'every platform', (tester) async {
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      try {
        for (final size in const [Size(390, 844), Size(1440, 900)]) {
          final why = '${platform.name} at ${size.width.round()}';
          _size(tester, size);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(overviewApp(Brightness.dark));
          await tester.pump(const Duration(milliseconds: 500));
          final open = find.text('new deploy').first;
          await tester.ensureVisible(open);
          await tester.pump();
          await tester.tap(open);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));
          final shell = find.byType(SlipwayShell);
          expect(shell, findsOneWidget, reason: why);
          expect(_flying(shell), isEmpty, reason: why);
          expect(_flying(find.byType(OverviewPage)), isEmpty, reason: why);
          final mid = tester.getRect(shell);
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.getRect(shell), mid, reason: why);
        }
      } finally {
        // Unset whatever happens: the binding checks it before tear-downs.
        debugDefaultTargetPlatformOverride = null;
      }
    }
  });

  testWidgets('a dialog and a toast come up in place', (tester) async {
    _size(tester, const Size(768, 1024));
    late BuildContext page;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showTermDialog<void>(
        context: page,
        builder: (_) =>
            const TermDialog(title: 'delete project', content: Text('sure?')),
      ),
    );
    _expectNoTravel(await _frames(tester));

    Navigator.of(page).pop();
    await tester.pumpAndSettle();
    TermToaster.show(page, message: 'deployed');
    _expectNoTravel(await _frames(tester));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a side sheet and an action sheet come up in place', (
    tester,
  ) async {
    _size(tester, const Size(1440, 900));
    late BuildContext page;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showTermSideSheet<void>(
        context: page,
        builder: (_) => const TermSideSheet(
          title: 'run #1482',
          child: Text('fix the cache key'),
        ),
      ),
    );
    _expectNoTravel(await _frames(tester));
    Navigator.of(page).pop();
    await tester.pumpAndSettle();

    _size(tester, const Size(390, 844));
    await tester.pump();
    unawaited(
      showTermActionSheet<int>(
        context: page,
        title: 'run #1482',
        actions: const [
          TermSheetAction(label: 'rerun', value: 1),
          TermSheetAction(label: 'cancel the run', value: 2),
        ],
      ),
    );
    _expectNoTravel(await _frames(tester));
    Navigator.of(page).pop();
    await tester.pumpAndSettle();
  });

  for (final row in const ['Popover', 'Menu', 'MenuBar']) {
    testWidgets('a ${row.toLowerCase()} opens at its anchor', (tester) async {
      _size(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Builder(builder: termInventory.entryFor(row)!.builder!),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final before = _panes();
      await tester.tap(find.byType(DesignPressable).first);
      final seen = await _frames(tester);
      expect(_new(before, seen), isNotEmpty, reason: '$row opened nothing');
      _expectNoTravel(seen);
      expect(tester.takeException(), isNull);
    });
  }

  for (final row in const ['Disclosure', 'TreeView']) {
    testWidgets('a ${row.toLowerCase()} opens inside its own lines', (
      tester,
    ) async {
      _size(tester, const Size(390, 844));
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: Builder(builder: termInventory.entryFor(row)!.builder!),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      // Close what is open, then open it again, looking at every frame.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(DesignPressable).first);
        await tester.pump();
        for (var f = 0; f < 30; f++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull, reason: '$row frame $f');
        }
      }
    });
  }
}
