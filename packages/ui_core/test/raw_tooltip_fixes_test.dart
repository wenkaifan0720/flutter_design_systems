import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _tip = ValueKey('tip');

void main() {
  group('RawTooltipFocusFix', () {
    late FocusNode before;
    late FocusNode save;
    late FocusNode after;

    setUp(() {
      before = FocusNode(debugLabel: 'before');
      save = FocusNode(debugLabel: 'save');
      after = FocusNode(debugLabel: 'after');
    });

    tearDown(() {
      before.dispose();
      save.dispose();
      after.dispose();
    });

    Widget focusable(FocusNode node, String label) => GestureDetector(
      onTap: node.requestFocus,
      child: Focus(
        focusNode: node,
        child: SizedBox(width: 80, height: 40, child: Text(label)),
      ),
    );

    Widget app({bool fix = true}) {
      final control = focusable(save, 'Save');
      return harness(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              focusable(before, 'Before'),
              RawTooltip(
                semanticsTooltip: 'Save the report',
                tooltipBuilder: (context, animation) =>
                    const Text('Save the report', key: _tip),
                child: fix ? RawTooltipFocusFix(child: control) : control,
              ),
              focusable(after, 'After'),
            ],
          ),
        ),
      );
    }

    Future<void> tab(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    testWidgets('the keys\' focus shows the tip at once; the focus leaving '
        'hides it', (tester) async {
      await tester.pumpWidget(app());
      before.requestFocus();
      await tester.pump();
      await tab(tester);
      expect(save.hasPrimaryFocus, isTrue);
      expect(find.byKey(_tip), findsOneWidget);
      await tab(tester);
      expect(after.hasPrimaryFocus, isTrue);
      expect(find.byKey(_tip), findsNothing);
    });

    testWidgets('without it, Flutter\'s RawTooltip shows nothing on the '
        'keys\' focus', (tester) async {
      await tester.pumpWidget(app(fix: false));
      before.requestFocus();
      await tester.pump();
      await tab(tester);
      expect(save.hasPrimaryFocus, isTrue);
      expect(find.byKey(_tip), findsNothing);
    });

    testWidgets('a tap\'s focus shows nothing', (tester) async {
      await tester.pumpWidget(app());
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(save.hasPrimaryFocus, isTrue);
      expect(find.byKey(_tip), findsNothing);
    });

    testWidgets('Escape hides the tip the focus showed, and the focus stays', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      before.requestFocus();
      await tester.pump();
      await tab(tester);
      expect(find.byKey(_tip), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(_tip), findsNothing);
      expect(save.hasPrimaryFocus, isTrue);
    });

    testWidgets('a tip a pointer holds up stays when the focus leaves', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('Save')));
      await tester.pumpAndSettle();
      expect(find.byKey(_tip), findsOneWidget);
      before.requestFocus();
      await tester.pump();
      await tab(tester);
      await tab(tester);
      expect(after.hasPrimaryFocus, isTrue);
      expect(find.byKey(_tip), findsOneWidget);
    });

    // Two tipped controls side by side: Save, then Share, each tip below its
    // own control, clear of the other.
    Widget pair() {
      Widget tipped(FocusNode node, String label, String tip) => RawTooltip(
        semanticsTooltip: tip,
        tooltipBuilder: (context, animation) => Text(tip, key: ValueKey(tip)),
        child: RawTooltipFocusFix(child: focusable(node, label)),
      );
      return harness(
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 160,
            children: [
              focusable(before, 'Before'),
              tipped(save, 'Save', 'Save the report'),
              tipped(after, 'Share', 'Share the report'),
            ],
          ),
        ),
      );
    }

    testWidgets('a Tab from one tipped control to the next shows the next '
        'one\'s tip, and hides the first\'s', (tester) async {
      await tester.pumpWidget(pair());
      before.requestFocus();
      await tester.pump();
      await tab(tester);
      expect(save.hasPrimaryFocus, isTrue);
      expect(find.byKey(const ValueKey('Save the report')), findsOneWidget);
      await tab(tester);
      expect(after.hasPrimaryFocus, isTrue);
      expect(find.byKey(const ValueKey('Share the report')), findsOneWidget);
      expect(find.byKey(const ValueKey('Save the report')), findsNothing);
      // And back, with Shift-Tab.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tab(tester);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(save.hasPrimaryFocus, isTrue);
      expect(find.byKey(const ValueKey('Save the report')), findsOneWidget);
      expect(find.byKey(const ValueKey('Share the report')), findsNothing);
    });

    testWidgets('with a pointer resting on the next tipped control, a Tab '
        'onto it from the first still shows its tip', (tester) async {
      await tester.pumpWidget(pair());
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('Share')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('Share the report')), findsOneWidget);
      before.requestFocus();
      await tester.pump();
      await tab(tester);
      expect(save.hasPrimaryFocus, isTrue);
      expect(find.byKey(const ValueKey('Save the report')), findsOneWidget);
      // Save's tip goes as the focus leaves it, and RawTooltip hides every tip
      // with it, the one the pointer holds up too; Share's shows again for
      // the focus it took.
      await tab(tester);
      expect(after.hasPrimaryFocus, isTrue);
      expect(find.byKey(const ValueKey('Share the report')), findsOneWidget);
      expect(find.byKey(const ValueKey('Save the report')), findsNothing);
    });
  });

  group('RawTooltipPlacement', () {
    Widget app(
      Alignment where, {
      RawPopoverPlacement placement = RawTooltipPlacement.defaultPlacement,
      TextDirection textDirection = TextDirection.ltr,
    }) => harness(
      Align(
        alignment: where,
        child: RawTooltipPlacement(
          placement: placement,
          builder: (context, positionDelegate) => RawTooltip(
            semanticsTooltip: 'Save the report',
            positionDelegate: positionDelegate,
            triggerMode: TooltipTriggerMode.tap,
            tooltipBuilder: (context, animation) => SizedBox(
              key: _tip,
              width: 120,
              height: 24,
              child: Text('${RawTooltipPlacement.sideOf(context)?.name}'),
            ),
            child: const SizedBox(width: 80, height: 40, child: Text('Save')),
          ),
        ),
      ),
      textDirection: textDirection,
    );

    Future<void> show(WidgetTester tester) async {
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    testWidgets('above the control, centred, 4 px from it, and the tip is '
        'told so', (tester) async {
      await tester.pumpWidget(app(Alignment.center));
      await show(tester);
      final control = tester.getRect(find.text('Save'));
      final tip = tester.getRect(find.byKey(_tip));
      expect(tip.bottom, control.top - 4);
      expect(tip.center.dx, control.center.dx);
      expect(find.text('above'), findsOneWidget);
    });

    testWidgets('below where there is no room above, and the tip is told so', (
      tester,
    ) async {
      await tester.pumpWidget(app(Alignment.topCenter));
      await show(tester);
      final control = tester.getRect(find.text('Save'));
      final tip = tester.getRect(find.byKey(_tip));
      expect(tip.top, control.bottom + 4);
      expect(find.text('below'), findsOneWidget);
    });

    testWidgets('kept 8 px clear of the screen\'s edge', (tester) async {
      await tester.pumpWidget(app(Alignment.centerLeft));
      await show(tester);
      expect(tester.getRect(find.byKey(_tip)).left, 8);
    });

    testWidgets('a side of its own: the control\'s end, which is its left '
        'right to left', (tester) async {
      const end = RawPopoverPlacement(
        side: RawPopoverSide.end,
        align: RawPopoverAlign.center,
        matchAnchorWidth: false,
      );
      await tester.pumpWidget(
        app(Alignment.center, placement: end, textDirection: TextDirection.rtl),
      );
      await show(tester);
      final control = tester.getRect(find.text('Save'));
      final tip = tester.getRect(find.byKey(_tip));
      expect(tip.right, lessThanOrEqualTo(control.left));
      expect(find.text('end'), findsOneWidget);
    });

    testWidgets('the tip is told nothing outside a RawTooltipPlacement', (
      tester,
    ) async {
      RawPopoverSide? side = RawPopoverSide.below;
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) {
              side = RawTooltipPlacement.sideOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(side, isNull);
    });
  });
}
