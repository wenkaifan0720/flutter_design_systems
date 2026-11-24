// Focus shown as a browser's :focus-visible shows it: a surface a pointer
// opened takes the focus where it always has, but paints none until a key
// is pressed; one the keys opened paints it at once.
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// Every face's last states, by its words.
final Map<String, Set<WidgetState>> _states = {};

bool _painted(String label) =>
    _states[label]?.contains(WidgetState.focused) ?? false;

bool _focusedOn(String label) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  var found = false;
  void look(Element e) {
    if (found) return;
    final w = e.widget;
    if (w is Text && w.data == label) found = true;
    e.visitChildElements(look);
  }

  look(focused as Element);
  return found;
}

Widget _face(String label, Set<WidgetState> states) {
  _states[label] = states;
  return SizedBox(
    key: ValueKey(label),
    width: 120,
    height: 44,
    child: Center(child: Text(label)),
  );
}

RawButton _button(
  String label, {
  VoidCallback? onPressed,
  bool autofocus = false,
}) => RawButton(
  semanticLabel: label,
  excludeSemantics: true,
  autofocus: autofocus,
  onPressed: onPressed ?? () {},
  builder: (context, states, _) => _face(label, states),
);

int _cancelled = 0;

RawModalDialogRoute<void> _dialog() => RawModalDialogRoute<void>(
  isAlert: true,
  semanticLabel: 'Discard changes',
  builder: (context, details) => RawAlertDialog(
    title: 'Discard changes?',
    actions: [
      RawDialogAction(
        label: 'Keep editing',
        onPressed: () {
          _cancelled++;
          Navigator.of(context).pop();
        },
      ),
      RawDialogAction(
        label: 'Discard',
        isDestructiveAction: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
    actionBuilder: (context, action, details) =>
        _face(action.label, details.states),
    frameBuilder: (context, details, child) => Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

RawBottomSheetRoute<void> _sheet() => RawBottomSheetRoute<void>(
  semanticLabel: 'Filters',
  builder: (context, details) => Container(
    color: const Color(0xFFFFFFFF),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [_button('Apply', autofocus: true), _button('Reset')],
    ),
  ),
);

// A page with an opener that pushes [route], and a control before it.
Widget _page(Route<void> Function() route) => harness(
  Builder(
    builder: (context) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _button('Before'),
        _button('Open', onPressed: () => Navigator.of(context).push(route())),
      ],
    ),
  ),
);

// A popover from an opener, its first control taking the focus as it opens.
Widget _popover({Widget? content}) => harness(
  Center(
    child: RawPopover(
      semanticLabel: 'Options',
      anchorBuilder: (context, anchor) =>
          _button('Open', onPressed: anchor.toggle),
      overlayBuilder: (context, info) => Container(
        color: const Color(0xFFFFFFFF),
        child:
            content ??
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [_button('First'), _button('Second')],
            ),
      ),
    ),
  ),
);

Future<void> _click(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey(label)), kind: PointerDeviceKind.mouse);
  await tester.pumpAndSettle();
}

Future<void> _openByKeys(WidgetTester tester, {int tabs = 2}) async {
  for (var i = 0; i < tabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  }
  expect(_focusedOn('Open'), isTrue);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

// The desktop's highlight mode, where a mouse leaves the keyboard's.
final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

void main() {
  setUp(() {
    _states.clear();
    _cancelled = 0;
  });

  group('a dialog', () {
    testWidgets(
      'a click opens it on its safe action unpainted; Enter still presses '
      'it',
      (tester) async {
        await tester.pumpWidget(_page(_dialog));
        await _click(tester, 'Open');
        expect(_focusedOn('Keep editing'), isTrue, reason: 'focus as before');
        expect(_painted('Keep editing'), isFalse, reason: 'no ring yet');
        expect(_painted('Discard'), isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_cancelled, 1, reason: 'Enter presses the safe action');
      },
      variant: _desktop,
    );

    testWidgets(
      'after a click, the next key paints the focus where it is; Tab moves '
      'it painted',
      (tester) async {
        await tester.pumpWidget(_page(_dialog));
        await _click(tester, 'Open');
        expect(_painted('Keep editing'), isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.shift);
        await tester.pump();
        expect(_painted('Keep editing'), isTrue, reason: 'a key shows it');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusedOn('Discard'), isTrue);
        expect(_painted('Discard'), isTrue);
        expect(_painted('Keep editing'), isFalse);
      },
      variant: _desktop,
    );

    testWidgets('opened by the keys, it paints its safe action at once; Escape '
        'closes it', (tester) async {
      await tester.pumpWidget(_page(_dialog));
      await _openByKeys(tester);
      expect(_focusedOn('Keep editing'), isTrue);
      expect(_painted('Keep editing'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(_focusedOn('Open'), isTrue, reason: 'given back');
      expect(_painted('Open'), isTrue, reason: 'the keys closed it');
    }, variant: _desktop);

    testWidgets(
      'a click on an opener the keys had focused still opens it unpainted',
      (tester) async {
        await tester.pumpWidget(_page(_dialog));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_painted('Open'), isTrue);
        await _click(tester, 'Open');
        expect(_focusedOn('Keep editing'), isTrue);
        expect(_painted('Keep editing'), isFalse);
      },
      variant: _desktop,
    );

    testWidgets(
      'closed by a click, it gives the focus back to its opener unpainted',
      (tester) async {
        await tester.pumpWidget(_page(_dialog));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await _click(tester, 'Open');
        await _click(tester, 'Keep editing');
        expect(find.text('Discard changes?'), findsNothing);
        expect(_focusedOn('Open'), isTrue, reason: 'given back');
        expect(_painted('Open'), isFalse);
      },
      variant: _desktop,
    );

    testWidgets('a touch opens it unpainted, as before', (tester) async {
      await tester.pumpWidget(_page(_dialog));
      await tester.tap(find.byKey(const ValueKey('Open')));
      await tester.pumpAndSettle();
      expect(_focusedOn('Keep editing'), isTrue);
      expect(_painted('Keep editing'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_painted('Discard'), isTrue, reason: 'a key shows the focus');
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets(
      'a semantics tap (a click on the web with semantics on) opens it '
      'unpainted',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_page(_dialog));
        // Focus shown before: the keys moved last.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final node = tester.getSemantics(find.bySemanticsLabel('Open'));
        tester.binding.platformDispatcher.onSemanticsActionEvent!(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            viewId: tester.view.viewId,
            nodeId: node.id,
          ),
        );
        await tester.pumpAndSettle();
        expect(_focusedOn('Keep editing'), isTrue);
        expect(_painted('Keep editing'), isFalse);
        semantics.dispose();
      },
      variant: _desktop,
    );
  });

  group('a sheet', () {
    testWidgets(
      'a click opens it on its first control unpainted; a key paints it',
      (tester) async {
        await tester.pumpWidget(_page(_sheet));
        await _click(tester, 'Open');
        expect(_focusedOn('Apply'), isTrue);
        expect(_painted('Apply'), isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusedOn('Reset'), isTrue);
        expect(_painted('Reset'), isTrue);
      },
      variant: _desktop,
    );

    testWidgets('opened by the keys, it paints its focus at once', (
      tester,
    ) async {
      await tester.pumpWidget(_page(_sheet));
      await _openByKeys(tester);
      expect(_focusedOn('Apply'), isTrue);
      expect(_painted('Apply'), isTrue);
    }, variant: _desktop);
  });

  group('a popover', () {
    testWidgets(
      'a click opens it on its first control unpainted; a key paints it',
      (tester) async {
        await tester.pumpWidget(_popover());
        await _click(tester, 'Open');
        expect(_focusedOn('First'), isTrue);
        expect(_painted('First'), isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusedOn('Second'), isTrue);
        expect(_painted('Second'), isTrue);
      },
      variant: _desktop,
    );

    testWidgets('opened by the keys, it paints its focus at once', (
      tester,
    ) async {
      await tester.pumpWidget(_popover());
      await _openByKeys(tester, tabs: 1);
      expect(_focusedOn('First'), isTrue);
      expect(_painted('First'), isTrue);
    }, variant: _desktop);

    testWidgets(
      "a calendar in it lights no keyboard's day after a click, and lights "
      'it on the first arrow',
      (tester) async {
        final days = <DateTime, Set<WidgetState>>{};
        final controller = RawCalendarController(
          firstDate: DateTime(2025),
          lastDate: DateTime(2027, 12, 31),
          initialMonth: DateTime(2026, 1),
          currentDate: DateTime(2026, 1, 15),
        );
        addTearDown(controller.dispose);
        bool lit(int day) =>
            days[DateTime(2026, 1, day)]?.contains(WidgetState.focused) ??
            false;
        final calendar = SizedBox(
          width: 320,
          child: RawCalendarDatePicker(
            controller: controller,
            autofocus: true,
            dayBuilder: (context, day, states) {
              if (day.inMonth) days[day.date] = states;
              return SizedBox(
                height: 40,
                child: Center(child: Text('${day.date.day}')),
              );
            },
          ),
        );
        await tester.pumpWidget(_popover(content: calendar));
        await _click(tester, 'Open');
        expect(controller.focusedDay, DateTime(2026, 1, 1));
        expect(lit(1), isFalse, reason: 'no day lit after a click');
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(lit(2), isTrue, reason: 'the arrow lights the day it moved to');

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        days.clear();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          lit(2),
          isTrue,
          reason: 'opened by the keys, the day is lit at once',
        );
      },
      variant: _desktop,
    );
  });

  testWidgets(
    'a press of the mouse hides the focus where it is until the next key',
    (tester) async {
      await tester.pumpWidget(_page(_dialog));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_painted('Before'), isTrue);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.down(const Offset(5, 5));
      await mouse.up();
      await tester.pump();
      expect(_focusedOn('Before'), isTrue, reason: 'nothing took the focus');
      expect(_painted('Before'), isFalse);
      // A shortcut's modifier is not the keys taking over.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.pump();
      expect(_painted('Before'), isFalse);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(_painted('Before'), isTrue);
      await mouse.removePointer();
    },
    variant: _desktop,
  );

  testWidgets(
    "a calendar a touch left focused lights its day on the first arrow: the "
    'highlight mode the key switches is heard',
    (tester) async {
      final days = <DateTime, Set<WidgetState>>{};
      final controller = RawCalendarController(
        firstDate: DateTime(2025),
        lastDate: DateTime(2027, 12, 31),
        initialMonth: DateTime(2026, 1),
        currentDate: DateTime(2026, 1, 15),
      );
      addTearDown(controller.dispose);
      bool lit(int day) =>
          days[DateTime(2026, 1, day)]?.contains(WidgetState.focused) ?? false;
      await tester.pumpWidget(
        harness(
          Center(
            child: SizedBox(
              width: 320,
              child: RawCalendarDatePicker(
                controller: controller,
                autofocus: true,
                dayBuilder: (context, day, states) {
                  if (day.inMonth) days[day.date] = states;
                  return SizedBox(
                    height: 40,
                    child: Center(child: Text('${day.date.day}')),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
      expect(controller.focusedDay, DateTime(2026, 1, 1));
      expect(lit(1), isFalse, reason: 'no day lit after a touch');
      // The calendar keeps the focus; the arrow moves its day.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(controller.focusedDay, DateTime(2026, 1, 2));
      expect(lit(2), isTrue, reason: 'the arrow lights the day it moved to');
    },
    variant: _desktop,
  );

  testWidgets(
    'an app that keeps the traditional highlight mode shows focus whatever '
    'the input',
    (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await tester.pumpWidget(_page(_dialog));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_painted('Before'), isTrue);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.down(const Offset(5, 5));
      await mouse.up();
      await tester.pump();
      expect(_painted('Before'), isTrue, reason: 'a press hides nothing');
      await mouse.removePointer();
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('Before'))),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(_painted('Before'), isTrue, reason: 'held, it shows its focus');
      await finger.up();
      await tester.pumpAndSettle();
      await _click(tester, 'Open');
      expect(_focusedOn('Keep editing'), isTrue);
      expect(_painted('Keep editing'), isTrue, reason: 'a click opened it');
    },
    variant: _desktop,
  );
}
