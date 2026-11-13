import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

DesignCarouselControls? _controls;

// The bare reference painter: the slide's name, previous and next under it.
Widget _carousel({
  bool loop = false,
  Duration? autoplayInterval,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) => harness(
  _view(loop: loop, autoplayInterval: autoplayInterval),
  textDirection: direction,
  reduceMotion: reduceMotion,
);

Widget _view({bool loop = false, Duration? autoplayInterval}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: 300,
    height: 300,
    child: DesignCarousel(
      itemCount: 3,
      loop: loop,
      autoplayInterval: autoplayInterval,
      itemBuilder: (context, i) => Center(child: Text('slide $i')),
      layoutBuilder: (context, viewport, controls) {
        _controls = controls;
        return Column(
          children: [
            Expanded(child: viewport),
            Row(
              children: [
                DesignPressable(
                  onPressed: controls.previous,
                  semanticLabel: 'Previous',
                  minimumSize: const Size(44, 44),
                  builder: (context, states, _) => const Text('<'),
                ),
                DesignPressable(
                  onPressed: controls.next,
                  semanticLabel: 'Next',
                  minimumSize: const Size(44, 44),
                  builder: (context, states, _) => const Text('>'),
                ),
              ],
            ),
          ],
        );
      },
    ),
  ),
);

void main() {
  behaviourContract(
    'DesignCarousel',
    // Under Reduce Motion it is asked to play: it must not.
    build: (c) => Builder(
      builder: (context) => _view(
        autoplayInterval: MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 300)
            : null,
      ),
    ),
    node: () => find.bySemanticsLabel('Carousel'),
    semantics: isSemantics(label: 'Carousel', isFocusable: true),
    noDisabledState:
        'slides always turn; a look shows one slide alone, or none',
    keyboard: (p) async {
      await p.tabInto();
      p.tester.takeAnnouncements();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_controls!.page, 1);
      expect(
        p.tester.takeAnnouncements().map((a) => a.message),
        contains('Slide 2 of 3'),
        reason: 'a turn the reader made is told',
      );
      await p.key(LogicalKeyboardKey.end);
      expect(_controls!.page, 2);
      await p.key(LogicalKeyboardKey.home);
      expect(_controls!.page, 0);
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_controls!.page, 0, reason: 'it does not loop');
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_controls!.page, 1, reason: 'left is on, right to left');
    },
    motion: (p) async {
      await p.tester.pump(const Duration(seconds: 2));
      expect(_controls!.page, 0, reason: 'no autoplay');
      await p.tester.tap(find.text('>'));
      await p.tester.pump();
      await p.tester.pump();
      expect(_controls!.page, 1, reason: 'a turn jumps');
    },
  );

  testWidgets('next and previous turn it; the ends stop it unless it loops', (
    tester,
  ) async {
    await tester.pumpWidget(_carousel());
    expect(_controls!.previous, isNull);
    await tester.tap(find.text('>'));
    await tester.pumpAndSettle();
    expect(_controls!.page, 1);
    _controls!.goToPage(2);
    await tester.pumpAndSettle();
    expect(_controls!.next, isNull);
    expect(find.text('slide 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_carousel(loop: true));
    await tester.tap(find.text('<'));
    await tester.pumpAndSettle();
    expect(_controls!.page, 2, reason: 'wrapped');
  });

  testWidgets('one that loops goes round, never back across the others: '
      'next on the last turns on to the first, a swipe past it does too, '
      'and a dot goes the nearer way', (tester) async {
    await tester.pumpWidget(_carousel(loop: true));
    final position = _controls!.position;
    final seen = <double>[];
    position.addListener(() => seen.add(position.value));
    double left(String text) => tester.getRect(find.text(text)).center.dx;

    // Back from the first: the last comes in from the left.
    await tester.tap(find.text('<'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    expect(find.text('slide 1'), findsNothing, reason: 'no rewind');
    expect(left('slide 2'), lessThan(left('slide 0')));
    expect(position.value, inExclusiveRange(2, 3));
    await tester.pumpAndSettle();
    expect(_controls!.page, 2);
    expect(position.value, 2);

    // On from the last: the first comes in from the right.
    await tester.tap(find.text('>'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    expect(find.text('slide 1'), findsNothing, reason: 'no rewind');
    expect(left('slide 0'), greaterThan(left('slide 2')));
    expect(position.value, inExclusiveRange(2, 3));
    await tester.pumpAndSettle();
    expect(_controls!.page, 0);

    // A swipe past the first goes round to the last.
    await tester.drag(find.byType(PageView), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(_controls!.page, 2);
    expect(find.text('slide 2'), findsOneWidget);

    // A dot from the last to the first goes on one, not back two.
    _controls!.goToPage(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    expect(find.text('slide 1'), findsNothing);
    await tester.pumpAndSettle();
    expect(_controls!.page, 0);
    expect(seen, everyElement(inInclusiveRange(0, 3)));
  });

  testWidgets('the position follows a turn frame by frame', (tester) async {
    await tester.pumpWidget(_carousel());
    final position = _controls!.position;
    expect(position.value, 0);
    await tester.tap(find.text('>'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    expect(position.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(position.value, 1);
    // And a finger's drag, part way.
    final drag = await tester.startGesture(const Offset(150, 150));
    await drag.moveBy(const Offset(-40, 0));
    await drag.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(position.value, inExclusiveRange(1, 2));
    await drag.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a tab stop: the arrows turn it, mirrored right to left', (
    tester,
  ) async {
    await tester.pumpWidget(_carousel(direction: TextDirection.rtl));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(_controls!.page, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(_controls!.page, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_controls!.page, 1);
  });

  testWidgets('autoplay turns it, pauses under a pointer, and can be '
      'paused', (tester) async {
    await tester.pumpWidget(
      _carousel(autoplayInterval: const Duration(seconds: 3)),
    );
    expect(_controls!.playing, isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(_controls!.page, 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(150, 150));
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(_controls!.page, 1, reason: 'paused while hovered');
    await mouse.moveTo(const Offset(700, 500));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(_controls!.page, 2);

    _controls!.togglePlay!();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(_controls!.page, 2);
    expect(_controls!.playing, isFalse);
  });

  testWidgets('the slides are cut square at the viewport\'s edge unless the '
      'look says otherwise', (tester) async {
    Clip cut() => tester.widget<Viewport>(find.byType(Viewport)).clipBehavior;
    await tester.pumpWidget(_carousel());
    expect(cut(), Clip.hardEdge);
    await tester.pumpWidget(
      harness(
        DesignCarousel(
          itemCount: 2,
          clipBehavior: Clip.none,
          itemBuilder: (context, i) => Text('slide $i'),
        ),
      ),
    );
    expect(cut(), Clip.none);
  });

  testWidgets('Reduce Motion: no autoplay, and a turn jumps', (tester) async {
    await tester.pumpWidget(
      _carousel(
        autoplayInterval: const Duration(seconds: 1),
        reduceMotion: true,
      ),
    );
    expect(_controls!.playing, isFalse);
    await tester.pump(const Duration(seconds: 5));
    expect(_controls!.page, 0);
    await tester.tap(find.text('>'));
    await tester.pump();
    await tester.pump();
    expect(_controls!.page, 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a screen reader hears the carousel and each slide\'s place', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_carousel());
    expect(find.bySemanticsLabel('Carousel'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Slide 1 of 3')), findsOneWidget);
    semantics.dispose();
  });
}
