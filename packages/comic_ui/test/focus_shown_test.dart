// A part of Comic's own on a FocusableActionDetector shows its focus as a browser's :focus-visible does: after a key,
// not after a press of a mouse, which on the web focuses what it clicks (the slider's knob, the page dots).
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

bool _shown(WidgetTester tester, Finder part) => tester
    .state(part)
    .toDiagnosticsNode()
    .getProperties()
    .any((p) => p.name == 'focusShown' && p.value == true);

Future<void> _pump(WidgetTester tester, Widget part) async {
  await tester.pumpWidget(
    comicApp(
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [part]),
      ),
      width: 390,
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  testWidgets(
    'a slider the keys reached hides its ring when a mouse presses it, and a key shows it again',
    (tester) async {
      var value = .4;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => ComicSlider(
            label: 'Volume',
            value: value,
            onChanged: (v) => set(() => value = v),
          ),
        ),
      );
      final slider = find.byType(ComicSlider);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_shown(tester, slider), isTrue);
      await tester.tap(slider, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_shown(tester, slider), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_shown(tester, slider), isTrue);
    },
  );

  testWidgets(
    'page dots the keys reached hide their ring when a mouse presses them',
    (tester) async {
      var page = 0;
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, set) => ComicPageDots(
            pageCount: 4,
            selectedIndex: page,
            semanticLabel: 'Pages',
            onPageChanged: (i) => set(() => page = i),
          ),
        ),
      );
      final dots = find.descendant(
        of: find.byType(ComicPageDots),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ChoosingDots',
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_shown(tester, dots), isTrue);
      await tester.tap(dots, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_shown(tester, dots), isFalse);
    },
  );

  // A mouse that connects and moves before any key or press (an iPad's trackpad, a mouse on Android) leaves the
  // focus to show on the next Tab.
  Future<void> mouseFirst(WidgetTester tester, Finder over) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(over));
    await tester.pumpAndSettle();
    await mouse.moveTo(const Offset(1, 1));
    await tester.pumpAndSettle();
  }

  testWidgets('after a mouse moved over it, Tab shows a slider\'s ring', (
    tester,
  ) async {
    var value = .4;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, set) => ComicSlider(
          label: 'Volume',
          value: value,
          onChanged: (v) => set(() => value = v),
        ),
      ),
    );
    final slider = find.byType(ComicSlider);
    await mouseFirst(tester, slider);
    expect(_shown(tester, slider), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_shown(tester, slider), isTrue);
  });

  testWidgets('after a mouse moved over them, Tab shows page dots\' ring', (
    tester,
  ) async {
    var page = 0;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, set) => ComicPageDots(
          pageCount: 4,
          selectedIndex: page,
          semanticLabel: 'Pages',
          onPageChanged: (i) => set(() => page = i),
        ),
      ),
    );
    final dots = find.descendant(
      of: find.byType(ComicPageDots),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_ChoosingDots',
      ),
    );
    await mouseFirst(tester, dots);
    expect(_shown(tester, dots), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_shown(tester, dots), isTrue);
  });
}
