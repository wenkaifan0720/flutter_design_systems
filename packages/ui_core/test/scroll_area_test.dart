import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _thumbKey = ValueKey('thumb');
DesignScrollThumb? _last;

// The bare reference painter: a grey bar, gone when hidden; a line when the
// keyboard is on the area.
Widget _area(
  ScrollController c, {
  DesignScrollbarVisibility visibility = DesignScrollbarVisibility.auto,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) => harness(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 300,
      height: 400,
      child: DesignScrollArea(
        controller: c,
        visibility: visibility,
        semanticLabel: 'Terms',
        thumbBuilder: (context, thumb) {
          _last = thumb;
          return Opacity(
            key: _thumbKey,
            opacity: thumb.visible ? 1 : 0,
            child: const ColoredBox(color: Color(0xFF808080)),
          );
        },
        frameBuilder: (context, focused, area) => Container(
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              color: focused
                  ? const Color(0xFF0000FF)
                  : const Color(0x00000000),
            ),
          ),
          child: area,
        ),
        child: ListView.builder(
          controller: c,
          itemCount: 40,
          itemExtent: 50,
          itemBuilder: (context, i) => Text('line $i'),
        ),
      ),
    ),
  ),
  textDirection: direction,
  reduceMotion: reduceMotion,
);

void main() {
  final areaController = ScrollController();
  tearDownAll(areaController.dispose);
  behaviourContract(
    'DesignScrollArea',
    build: (c) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 300,
        height: 400,
        child: DesignScrollArea(
          controller: areaController,
          semanticLabel: 'Terms',
          visibility: DesignScrollbarVisibility.always,
          thumbBuilder: (context, thumb) =>
              const ColoredBox(key: _thumbKey, color: Color(0xFF808080)),
          child: ListView.builder(
            controller: areaController,
            itemCount: 40,
            itemExtent: 50,
            itemBuilder: (context, i) => Text('line $i'),
          ),
        ),
      ),
    ),
    node: () => find.bySemanticsLabel('Terms'),
    // A named tab stop; the bar is the pointer's (no tap of its own).
    semantics: isSemantics(
      label: 'Terms',
      isFocusable: true,
      hasTapAction: false,
    ),
    noDisabledState: 'a scroll area has no disabled state',
    keyboard: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(areaController.offset, greaterThan(0), reason: 'Down scrolls');
      await p.key(LogicalKeyboardKey.end);
      expect(
        areaController.offset,
        areaController.position.maxScrollExtent,
        reason: 'End goes to the end',
      );
      await p.key(LogicalKeyboardKey.home);
      expect(areaController.offset, 0, reason: 'Home to the start');
    },
    rtl: (p) async {
      expect(
        p.tester.getCenter(find.byKey(_thumbKey)).dx,
        lessThan(150),
        reason: 'right to left, the bar is on the left',
      );
    },
    motion: (p) async {
      await p.tabInto();
      await p.tester.sendKeyEvent(LogicalKeyboardKey.end);
      await p.tester.pump();
    },
  );

  testWidgets('the thumb sizes to the view and follows the scroll; it hides '
      'a while after scrolling stops', (tester) async {
    final c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(_area(c));
    await tester.pump();
    expect(_last!.thumbExtent, 80, reason: '400 of 2000 px is a fifth');
    expect(_last!.visible, isFalse);
    expect(tester.getRect(find.byKey(_thumbKey)).right, 300);

    await tester.drag(find.text('line 0'), const Offset(0, -800));
    await tester.pump();
    expect(_last!.visible, isTrue);
    expect(c.offset, greaterThan(0));
    expect(_last!.thumbOffset, closeTo(320 * c.offset / 1600, 0.1));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1300));
    expect(_last!.visible, isFalse);
  });

  testWidgets('dragging the thumb scrolls in proportion; a press on the '
      'track pages toward it', (tester) async {
    final c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _area(c, visibility: DesignScrollbarVisibility.always),
    );
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_thumbKey)),
    );
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(_last!.states, contains(WidgetState.pressed));
    await gesture.up();
    await tester.pump();
    // 80 px of a 320 px run is a quarter of 1600 px (give or take the slop).
    expect(c.offset, inInclusiveRange(380, 520));
    final before = c.offset;
    await tester.tapAt(const Offset(294, 390));
    await tester.pumpAndSettle();
    expect(c.offset, closeTo(before + 320, 0.1));
  });

  testWidgets('a tab stop: the keys scroll, and the frame shows the focus; '
      'Reduce Motion jumps', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(_area(c, reduceMotion: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final frame = tester.widget<Container>(find.byType(Container).first);
    expect(
      (frame.foregroundDecoration! as BoxDecoration).border!.top.color,
      const Color(0xFF0000FF),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(c.offset, 48, reason: 'jumped, no animation');
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(c.offset, 48 + 320);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(c.offset, 1600);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(c.offset, 0);
  });

  testWidgets('right to left: the bar is on the left; a hover shows it', (
    tester,
  ) async {
    final c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(_area(c, direction: TextDirection.rtl));
    await tester.pump();
    expect(tester.getRect(find.byKey(_thumbKey)).left, 0);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(400, 300));
    await mouse.moveTo(const Offset(5, 200));
    await tester.pump();
    expect(_last!.visible, isTrue);
    expect(_last!.states, contains(WidgetState.hovered));
  });

  testWidgets('the bar is the pointer\'s: a screen reader hears the named '
      'area scroll, with no tap of the bar\'s', (tester) async {
    final semantics = tester.ensureSemantics();
    final c = ScrollController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _area(c, visibility: DesignScrollbarVisibility.always),
    );
    await tester.pump();
    final area = tester.getSemantics(find.bySemanticsLabel('Terms'));
    expect(
      area.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
      reason: 'the track\'s page press is the pointer\'s',
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
