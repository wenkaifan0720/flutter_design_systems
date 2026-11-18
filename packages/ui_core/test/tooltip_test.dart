// A tooltip: shown after a pointer rests, at once on the keyboard's focus,
// after a long press with its haptic; hoverable, dismissible with Escape
// (which then goes no further) and persistent (WCAG 1.4.13); one at a time
// with a warm-up; a screen reader hears it on the control.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _childKey = ValueKey('child');
const _tipKey = ValueKey('tip');

late DesignOverlayInfo _info;

// The reference painter: a 44 px button and a 140 by 32 tip.
Widget _tooltip({
  String message = 'Save the report',
  String label = 'Save',
  Key childKey = _childKey,
  Key tipKey = _tipKey,
  TooltipTriggerMode triggerMode = TooltipTriggerMode.longPress,
  bool enableFeedback = true,
  bool excludeFromSemantics = false,
  bool enabled = true,
  Widget? child,
}) => DesignTooltip(
  message: message,
  triggerMode: triggerMode,
  enableFeedback: enableFeedback,
  excludeFromSemantics: excludeFromSemantics,
  tooltipBuilder: (context, info) {
    _info = info;
    return FadeTransition(
      opacity: info.animation.drive(Tween(begin: 0, end: 1)),
      child: SizedBox(
        key: tipKey,
        width: 140,
        height: 32,
        child: Text(message),
      ),
    );
  },
  child:
      child ??
      DesignPressable(
        key: childKey,
        onPressed: enabled ? () {} : null,
        minimumSize: const Size(44, 44),
        semanticLabel: label,
        excludeSemantics: true,
        builder: (context, states, _) => plainFace(label),
      ),
);

bool _shown(WidgetTester tester, [Key key = _tipKey]) =>
    find.byKey(key).evaluate().isNotEmpty;

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: Offset.zero);
  await tester.pump();
  return mouse;
}

DesignHaptics _recording(List<String> log) =>
    DesignHaptics(longPress: () => log.add('longPress'));

void main() {
  group('a pointer', () {
    testWidgets('resting on the control shows it after the hover delay; on '
        'the tip it stays; off both it goes after the dismiss delay', (
      tester,
    ) async {
      await tester.pumpWidget(harness(Center(child: _tooltip())));
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(_childKey)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(_shown(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(_shown(tester), isTrue);
      // Hoverable: onto the tip, across the gap.
      await mouse.moveTo(tester.getCenter(find.byKey(_tipKey)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_shown(tester), isTrue);
      // Off both.
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_shown(tester), isTrue);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
      await tester.pump(DesignTooltip.warmUpDuration);
    });

    testWidgets('one shows at a time; the next shows at once while one '
        'shows and for the warm-up after; then it waits again', (tester) async {
      await tester.pumpWidget(
        harness(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tooltip(label: 'A', childKey: const ValueKey('a')),
                const SizedBox(width: 20),
                _tooltip(
                  label: 'B',
                  message: 'Bold',
                  childKey: const ValueKey('b'),
                  tipKey: const ValueKey('b tip'),
                ),
              ],
            ),
          ),
        ),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(_shown(tester), isTrue);
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('b'))));
      await tester.pumpAndSettle();
      expect(_shown(tester, const ValueKey('b tip')), isTrue);
      expect(_shown(tester), isFalse, reason: 'one at a time');
      // Off (it goes after the dismiss delay), then back within the
      // warm-up: at once.
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 150));
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('a'))));
      await tester.pump();
      expect(_shown(tester), isTrue);
      await tester.pumpAndSettle();
      expect(_shown(tester, const ValueKey('b tip')), isFalse);
      // Off, and past the warm-up: the delay again.
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      await mouse.moveTo(tester.getCenter(find.byKey(const ValueKey('b'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_shown(tester, const ValueKey('b tip')), isFalse);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(_shown(tester, const ValueKey('b tip')), isTrue);
      expect(DesignTooltip.dismissAll(), isTrue);
      await tester.pumpAndSettle();
      expect(DesignTooltip.dismissAll(), isFalse);
      await tester.pump(DesignTooltip.warmUpDuration);
    });

    testWidgets('a tap elsewhere hides it, and it stays hidden until the '
        'pointer leaves and comes back', (tester) async {
      await tester.pumpWidget(harness(Center(child: _tooltip())));
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(_childKey)));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(_shown(tester), isFalse);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(_childKey)));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(_shown(tester), isTrue);
      DesignTooltip.dismissAll();
      await tester.pumpAndSettle();
      await tester.pump(DesignTooltip.warmUpDuration);
    });
  });

  group('Escape', () {
    testWidgets('hides it and goes no further; with none shown it goes on', (
      tester,
    ) async {
      final page = <String>[];
      await tester.pumpWidget(
        harness(
          Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => page.add('dismiss'),
              ),
            },
            child: Focus(autofocus: true, child: Center(child: _tooltip())),
          ),
        ),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(_childKey)));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
      expect(page, isEmpty, reason: 'it hid one: it goes no further');
      expect(
        FocusManager.instance.primaryFocus,
        focused,
        reason: 'the focus did not move',
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        _shown(tester),
        isFalse,
        reason: 'it stays hidden, the pointer still on the control',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(page, ['dismiss']);
      await tester.pump(DesignTooltip.warmUpDuration);
    });
  });

  group('the keyboard\'s focus', () {
    testWidgets('shows it at once, and hides it as the focus leaves', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tooltip(),
                Focus(child: plainFace('after')),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_shown(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
      await tester.pump(DesignTooltip.warmUpDuration);
    });

    testWidgets('a tap\'s focus shows nothing', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(harness(Center(child: _tooltip())));
      Focus.of(tester.element(find.text('Save'))).requestFocus();
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
    });
  });

  group('a finger', () {
    testWidgets('a long press shows it with the haptic; it stays the touch '
        'delay after the finger lifts', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        harness(
          DesignHapticsScope(
            haptics: _recording(log),
            child: Center(child: _tooltip()),
          ),
        ),
      );
      await tester.longPress(find.byKey(_childKey));
      await tester.pump();
      expect(_shown(tester), isTrue);
      expect(log, ['longPress']);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(_shown(tester), isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
      await tester.pump(DesignTooltip.warmUpDuration);
    });

    testWidgets('no haptic when enableFeedback is false', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        harness(
          DesignHapticsScope(
            haptics: _recording(log),
            child: Center(child: _tooltip(enableFeedback: false)),
          ),
        ),
      );
      await tester.longPress(find.byKey(_childKey));
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(DesignTooltip.warmUpDuration);
    });

    testWidgets('in tap mode a tap shows it; in manual mode nothing a finger '
        'does', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        harness(
          Center(
            child: _tooltip(
              triggerMode: TooltipTriggerMode.tap,
              child: const SizedBox(
                key: _childKey,
                width: 44,
                height: 44,
                child: Text('i'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(_childKey));
      await tester.pump();
      expect(_shown(tester), isTrue);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
      await tester.pump(DesignTooltip.warmUpDuration);
      await tester.pumpWidget(
        harness(
          Center(
            child: _tooltip(
              triggerMode: TooltipTriggerMode.manual,
              child: GestureDetector(
                key: _childKey,
                behavior: HitTestBehavior.opaque,
                onLongPress: () => pressed++,
                child: const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        ),
      );
      await tester.longPress(find.byKey(_childKey));
      await tester.pumpAndSettle();
      expect(_shown(tester), isFalse);
      expect(pressed, 1, reason: 'the child\'s own long press');
    });
  });

  testWidgets('a disabled control shows its tip to a pointer', (tester) async {
    await tester.pumpWidget(harness(Center(child: _tooltip(enabled: false))));
    final mouse = await _mouse(tester);
    await mouse.moveTo(tester.getCenter(find.byKey(_childKey)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(_shown(tester), isTrue);
    DesignTooltip.dismissAll();
    await tester.pumpAndSettle();
  });

  testWidgets('a route pushed over its control hides it', (tester) async {
    await tester.pumpWidget(harness(Center(child: _tooltip())));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_shown(tester), isTrue);
    Navigator.of(tester.element(find.byKey(_childKey)))
        .push(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => const SizedBox.expand(),
          ),
        )
        .ignore();
    await tester.pumpAndSettle();
    expect(_shown(tester), isFalse);
    await tester.pump(DesignTooltip.warmUpDuration);
  });

  group('where the tip goes', () {
    testWidgets('above the control, centred; below it at the screen\'s top; '
        'its placed rectangle is the tip\'s', (tester) async {
      await tester.pumpWidget(harness(Center(child: _tooltip())));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final child = tester.getRect(find.byKey(_childKey));
      final tip = tester.getRect(find.byKey(_tipKey));
      expect(_info.side, DesignOverlaySide.above);
      expect(tip.bottom, child.top - 4);
      expect(tip.center.dx, child.center.dx);
      expect(_info.surfaceRect.value, tip);
      DesignTooltip.dismissAll();
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        harness(Align(alignment: Alignment.topCenter, child: _tooltip())),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_info.side, DesignOverlaySide.below);
      await tester.pump(DesignTooltip.warmUpDuration);
    });
  });

  group('a screen reader', () {
    testWidgets('hears the message as the control\'s tooltip, one node, and '
        'never the tip\'s words', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness(Center(child: _tooltip())));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        semanticsOf(tester, find.byType(DesignTooltip)),
        isSemantics(label: 'Save', tooltip: 'Save the report', isButton: true),
      );
      // The tip shows, and its words are no node's label: only the
      // control's tooltip carries them.
      expect(find.text('Save the report'), findsOneWidget);
      expect(
        find.semantics.byPredicate(
          (node) => node.label.contains('Save the report'),
        ),
        findsNothing,
      );
      semantics.dispose();
      await tester.pump(DesignTooltip.warmUpDuration);
    });

    testWidgets('excludeFromSemantics leaves the message out; an empty one '
        'is no tooltip at all, and the control keeps its state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final node = FocusNode(debugLabel: 'kept');
      addTearDown(node.dispose);
      Widget app(String message, {bool exclude = false}) => harness(
        Center(
          child: _tooltip(
            message: message,
            excludeFromSemantics: exclude,
            child: Focus(
              key: _childKey,
              focusNode: node,
              child: const SizedBox(width: 44, height: 44, child: Text('S')),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app('Save', exclude: true));
      expect(
        tester.getSemantics(find.byKey(_childKey)).getSemanticsData().tooltip,
        isEmpty,
      );
      await tester.pumpWidget(app('Save'));
      expect(
        tester.getSemantics(find.byKey(_childKey)).getSemanticsData().tooltip,
        'Save',
      );
      node.requestFocus();
      await tester.pump();
      await tester.pumpWidget(app(''));
      expect(node.hasFocus, isTrue, reason: 'the child kept its state');
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(_childKey)));
      await tester.pump(const Duration(seconds: 1));
      expect(_shown(tester), isFalse);
      semantics.dispose();
    });
  });

  testWidgets('its properties', (tester) async {
    final properties = DiagnosticPropertiesBuilder();
    _tooltip(triggerMode: TooltipTriggerMode.tap)
        .debugFillProperties(properties);
    final text = properties.properties.map((p) => p.toString()).join('\n');
    expect(text, contains('message: "Save the report"'));
    expect(text, contains('triggerMode: tap'));
  });

  behaviourContract(
    'DesignTooltip',
    build: (c) => Center(child: _tooltip(enabled: c.enabled)),
    // The control and its message, merged.
    node: () => find.byType(DesignTooltip),
    semantics: isSemantics(
      label: 'Save',
      tooltip: 'Save the report',
      isButton: true,
      hasTapAction: true,
      isFocusable: true,
    ),
    // Its control's: the message stays, the focus passes it by.
    disabled: isSemantics(
      label: 'Save',
      tooltip: 'Save the report',
      isButton: true,
      hasEnabledState: true,
      isEnabled: false,
    ),
    keyboard: (p) async {
      await p.tabInto();
      expect(_shown(p.tester), isTrue, reason: 'at once on the focus');
      await p.key(LogicalKeyboardKey.escape);
      expect(_shown(p.tester), isFalse);
      expect(p.focused, isTrue, reason: 'Escape leaves the focus');
      FocusManager.instance.primaryFocus!.unfocus();
      await p.tester.pumpAndSettle();
      await p.tabInto();
      expect(_shown(p.tester), isTrue, reason: 'the focus back shows it');
      DesignTooltip.dismissAll();
      await p.tester.pump(DesignTooltip.warmUpDuration);
    },
    rtl: (p) async {
      await p.tabInto();
      expect(
        p.tester.getCenter(find.byKey(_tipKey)).dx,
        p.tester.getCenter(p.node).dx,
      );
      DesignTooltip.dismissAll();
      await p.tester.pumpAndSettle();
      await p.tester.pump(DesignTooltip.warmUpDuration);
    },
    motion: (p) async {
      await p.tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await p.tester.pump();
    },
  );
}
