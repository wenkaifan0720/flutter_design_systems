// A context menu at the pointer: a right click and a long press open it
// where they happened, Shift+F10 and the Menu key at the focused widget, a
// screen reader's "Show menu" at the region; the innermost region wins; on
// the web the browser's own menu is shut while it is wanted.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/browser_menu.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _regionKey = ValueKey('region');
const _surfaceKey = ValueKey('surface');
const _rowKey = ValueKey('row');

final List<String> _ran = [];
final Map<String, Set<WidgetState>> _states = {};

List<RawMenuEntry> _entries() => [
  RawMenuEntry(label: 'Copy', onPressed: () => _ran.add('copy')),
  RawMenuEntry(
    label: 'Share',
    children: [RawMenuEntry(label: 'Mail', onPressed: () => _ran.add('mail'))],
  ),
  const RawMenuEntry.divider(),
  RawMenuEntry(label: 'Delete', onPressed: () => _ran.add('delete')),
];

// The reference painter: a region 300 by 200, a file's tile, with a
// focusable name in it whose words the region's node reads.
Widget _menu({
  List<RawMenuEntry>? entries,
  MenuController? controller,
  ValueChanged<bool>? onOpenChanged,
  bool enableFeedback = true,
  String label = 'outer',
  Widget? inside,
}) => RawContextMenu(
  menuChildren: entries ?? _entries(),
  controller: controller,
  onOpenChanged: onOpenChanged,
  enableFeedback: enableFeedback,
  semanticLabel: 'Actions',
  itemBuilder: (context, entry, level, states) {
    _states[entry.label] = states;
    return SizedBox(width: 160, height: 44, child: Text(entry.label));
  },
  dividerBuilder: (context) => const SizedBox(height: 9),
  surfaceBuilder: (context, info, items) => ColoredBox(
    key: label == 'outer' ? _surfaceKey : ValueKey('$label surface'),
    color: const Color(0xFFEEEEEE),
    child: Column(mainAxisSize: MainAxisSize.min, children: items),
  ),
  child: SizedBox(
    key: label == 'outer' ? _regionKey : ValueKey(label),
    width: 300,
    height: 200,
    child:
        inside ??
        const Align(
          alignment: AlignmentDirectional.topStart,
          child: Focus(
            key: _rowKey,
            child: SizedBox(width: 120, height: 44, child: Text('Report.pdf')),
          ),
        ),
  ),
);

// What a screen reader finds on the region: "Show menu" as an action of its
// own, and as what a long press does (the hint override, which semantics
// carries as a custom action of the long press).
const _showMenu = [
  CustomSemanticsAction(label: 'Show menu'),
  CustomSemanticsAction.overridingAction(
    hint: 'Show menu',
    action: SemanticsAction.longPress,
  ),
];

Widget _app(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    harness(
      Align(alignment: Alignment.topLeft, child: child),
      textDirection: direction,
    );

Rect _surface(WidgetTester tester) => tester.getRect(find.byKey(_surfaceKey));

// The region's own semantics node: the nearest Semantics above its child.
Finder _regionNode() => find
    .ancestor(of: find.byKey(_regionKey), matching: find.byType(Semantics))
    .first;

const _rows = ['Copy', 'Share', 'Delete'];

List<String> _lit() => [
  for (final l in _rows)
    if ((_states[l]?.contains(WidgetState.hovered) ?? false) ||
        (_states[l]?.contains(WidgetState.focused) ?? false))
      l,
];

bool _keysOn(WidgetTester tester, String label) =>
    Focus.maybeOf(tester.element(find.text(label)))?.hasPrimaryFocus ?? false;

Future<void> _rightClick(WidgetTester tester, Offset at) async {
  final mouse = await tester.startGesture(
    at,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await mouse.up();
  await tester.pumpAndSettle();
  await mouse.removePointer();
}

Future<void> _shiftF10(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(LogicalKeyboardKey.f10);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.pumpAndSettle();
}

DesignHaptics _recording(List<String> log) =>
    DesignHaptics(longPress: () => log.add('longPress'));

void main() {
  setUp(() {
    _ran.clear();
    _states.clear();
  });

  group('a right click', () {
    testWidgets('opens it at the pointer, no row lit; Down lights the first; '
        'a command closes it and runs', (tester) async {
      await tester.pumpWidget(_app(_menu()));
      await _rightClick(tester, const Offset(100, 150));
      expect(find.byKey(_surfaceKey), findsOneWidget);
      expect(_surface(tester).topLeft, const Offset(100, 152));
      expect(_lit(), isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_keysOn(tester, 'Copy'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_ran, ['copy']);
      expect(find.byKey(_surfaceKey), findsNothing);
    });

    testWidgets('elsewhere while it is open moves it there; a left click in '
        'the region closes it', (tester) async {
      await tester.pumpWidget(_app(_menu()));
      await _rightClick(tester, const Offset(100, 150));
      await _rightClick(tester, const Offset(20, 60));
      expect(_surface(tester).topLeft, const Offset(20, 62));
      await tester.tapAt(const Offset(250, 20), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsNothing);
    });

    testWidgets('gives the focus back where it was, not to the region\'s '
        'first control', (tester) async {
      final field = FocusNode(debugLabel: 'elsewhere');
      addTearDown(field.dispose);
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menu(),
              Focus(focusNode: field, child: const Text('elsewhere')),
            ],
          ),
        ),
      );
      field.requestFocus();
      await tester.pump();
      await _rightClick(tester, const Offset(200, 150));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('near the screen\'s end and bottom it turns across the point', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(Align(alignment: Alignment.bottomRight, child: _menu())),
      );
      await _rightClick(tester, const Offset(780, 580));
      final surface = _surface(tester);
      expect(surface.right, 780);
      expect(surface.bottom, 578);
    });

    testWidgets('in a region inside another, opens the inner one alone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _menu(
            inside: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: 100,
                height: 80,
                child: _menu(
                  label: 'inner',
                  entries: [
                    RawMenuEntry(
                      label: 'Rename',
                      onPressed: () => _ran.add('rename'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await _rightClick(tester, const Offset(250, 170));
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await _rightClick(tester, const Offset(40, 150));
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Rename'), findsNothing);
    });
  });

  group('a long press', () {
    testWidgets('of a finger opens it there, with the long press\'s haptic', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _app(DesignHapticsScope(haptics: _recording(log), child: _menu())),
      );
      await tester.longPressAt(const Offset(150, 100));
      await tester.pumpAndSettle();
      expect(_surface(tester).topLeft, const Offset(150, 102));
      expect(log, ['longPress']);
      expect(_lit(), isEmpty);
    });

    testWidgets('plays no haptic when enableFeedback is false', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        _app(
          DesignHapticsScope(
            haptics: _recording(log),
            child: _menu(enableFeedback: false),
          ),
        ),
      );
      await tester.longPressAt(const Offset(150, 100));
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      expect(log, isEmpty);
    });

    testWidgets('of a mouse opens nothing', (tester) async {
      await tester.pumpWidget(_app(_menu()));
      await tester.longPressAt(
        const Offset(150, 100),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsNothing);
    });
  });

  group('the keys', () {
    for (final direction in TextDirection.values) {
      testWidgets('Shift+F10 opens it at the focused widget\'s leading bottom '
          'corner, its first row lit (${direction.name})', (tester) async {
        await tester.pumpWidget(
          _app(
            Padding(padding: const EdgeInsets.all(40), child: _menu()),
            direction: direction,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await _shiftF10(tester);
        final row = tester.getRect(find.byKey(_rowKey));
        final surface = _surface(tester);
        expect(surface.top, row.bottom + 2);
        if (direction == TextDirection.ltr) {
          expect(surface.left, row.left);
        } else {
          expect(surface.right, row.right);
        }
        expect(_keysOn(tester, 'Copy'), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          Focus.of(tester.element(find.text('Report.pdf'))).hasPrimaryFocus,
          isTrue,
          reason: 'back on the name',
        );
      });
    }

    testWidgets('the Menu key opens it too; F10 alone, or with Ctrl, does '
        'not', (tester) async {
      await tester.pumpWidget(_app(_menu()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      // Typed letters and submenus are the menubar's.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_keysOn(tester, 'Mail'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_ran, ['mail']);
    });
  });

  group('a screen reader', () {
    testWidgets('finds "Show menu" among the region\'s actions, and a long '
        'press that says so; either opens it on its first row', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(_menu()));
      final node = tester.getSemantics(find.byKey(_regionKey));
      expect(
        node,
        isSemantics(
          label: 'Report.pdf',
          hasLongPressAction: true,
          customActions: _showMenu,
        ),
      );
      expect(node.hintOverrides?.onLongPressHint, 'Show menu');
      tester.semantics.longPress(
        find.semantics.byPredicate((n) => n.id == node.id),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      expect(_keysOn(tester, 'Copy'), isTrue);
      expect(_surface(tester).topLeft, const Offset(150, 102));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      final id = CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Show menu'),
      );
      node.owner!.performAction(node.id, SemanticsAction.customAction, id);
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      semantics.dispose();
    });
  });

  group('no rows', () {
    testWidgets('nothing opens it, and a screen reader finds no action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = MenuController();
      await tester.pumpWidget(_app(_menu(entries: const [])));
      expect(
        tester.getSemantics(find.byKey(_regionKey)),
        isSemantics(hasLongPressAction: false, customActions: const []),
      );
      await _rightClick(tester, const Offset(100, 100));
      await tester.longPressAt(const Offset(100, 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsNothing);
      // Emptied while open: it closes.
      await tester.pumpWidget(_app(_menu(controller: controller)));
      controller.open(position: const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsOneWidget);
      await tester.pumpWidget(
        _app(_menu(controller: controller, entries: const [])),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_surfaceKey), findsNothing);
      semantics.dispose();
    });
  });

  testWidgets('a controller opens it at a point from outside; it says when '
      'it opens and closes', (tester) async {
    final controller = MenuController();
    final told = <bool>[];
    await tester.pumpWidget(
      _app(_menu(controller: controller, onOpenChanged: told.add)),
    );
    controller.open(position: const Offset(40, 30));
    await tester.pumpAndSettle();
    expect(_surface(tester).topLeft, const Offset(40, 32));
    controller.close();
    await tester.pumpAndSettle();
    expect(told, [true, false]);
  });

  group('the browser\'s own menu, on the web', () {
    late List<String> calls;
    late bool appEnabled;
    setUp(() {
      calls = [];
      appEnabled = true;
      DesignBrowserMenu.onWeb = true;
      DesignBrowserMenu.disable = () async {
        calls.add('off');
        appEnabled = false;
      };
      DesignBrowserMenu.enable = () async {
        calls.add('on');
        appEnabled = true;
      };
      DesignBrowserMenu.enabled = () => appEnabled;
      addTearDown(() {
        DesignBrowserMenu.onWeb = kIsWeb;
        DesignBrowserMenu.disable = BrowserContextMenu.disableContextMenu;
        DesignBrowserMenu.enable = BrowserContextMenu.enableContextMenu;
        DesignBrowserMenu.enabled = () => BrowserContextMenu.enabled;
      });
    });

    testWidgets('is shut while a pointer is over the region or its menu is '
        'open, and comes back after', (tester) async {
      await tester.pumpWidget(_app(_menu()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(700, 500));
      await mouse.moveTo(const Offset(100, 100));
      await tester.pump();
      expect(calls, ['off']);
      await mouse.down(const Offset(100, 100));
      await mouse.up();
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(calls, ['off', 'on']);
      await _rightClick(tester, const Offset(100, 100));
      await mouse.moveTo(const Offset(700, 400));
      await tester.pump();
      expect(calls, ['off', 'on', 'off'], reason: 'its menu is open');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(calls, ['off', 'on', 'off', 'on']);
      expect(DesignBrowserMenu.holds, 0);
    });

    testWidgets('two regions hold it as one; an app that shut it keeps it '
        'shut', (tester) async {
      await tester.pumpWidget(
        _app(
          _menu(
            inside: Align(
              alignment: Alignment.bottomRight,
              child: SizedBox(width: 100, height: 80, child: _menu(label: 'b')),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(700, 500));
      await mouse.moveTo(const Offset(250, 170));
      await tester.pump();
      expect(DesignBrowserMenu.holds, 2);
      expect(calls, ['off']);
      await mouse.moveTo(const Offset(20, 20));
      await tester.pump();
      expect(calls, ['off']);
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(calls, ['off', 'on']);
      // The app shut it itself: the regions leave it be.
      appEnabled = false;
      await mouse.moveTo(const Offset(20, 20));
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(calls, ['off', 'on']);
      expect(appEnabled, isFalse);
    });

    testWidgets('a region gone lets go of it', (tester) async {
      await tester.pumpWidget(_app(_menu()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: const Offset(100, 100));
      await tester.pump();
      expect(calls, ['off']);
      await tester.pumpWidget(_app(const SizedBox()));
      expect(calls, ['off', 'on']);
      expect(DesignBrowserMenu.holds, 0);
    });
  });

  testWidgets('its properties', (tester) async {
    final properties = DiagnosticPropertiesBuilder();
    _menu().debugFillProperties(properties);
    final names = properties.properties.map((p) => p.name).toSet();
    expect(
      names,
      containsAll([
        'menuChildren',
        'itemBuilder',
        'surfaceBuilder',
        'highlightFollowsPointer',
        'enableFeedback',
        'useRootOverlay',
        'dampingRatio',
        'stiffness',
      ]),
    );
  });

  behaviourContract(
    'RawContextMenu',
    // Disabled: no rows, over a row that is disabled too (the region itself
    // never takes the focus; its row does).
    build: (c) => Align(
      alignment: Alignment.topLeft,
      child: _menu(
        entries: c.enabled ? null : const [],
        inside: c.enabled
            ? null
            : const Align(
                alignment: AlignmentDirectional.topStart,
                child: Focus(
                  key: _rowKey,
                  canRequestFocus: false,
                  child: SizedBox(
                    width: 120,
                    height: 44,
                    child: Text('Report.pdf'),
                  ),
                ),
              ),
      ),
    ),
    node: _regionNode,
    semantics: isSemantics(
      label: 'Report.pdf',
      hasLongPressAction: true,
      customActions: _showMenu,
    ),
    disabled: isSemantics(
      label: 'Report.pdf',
      hasLongPressAction: false,
      customActions: const [],
    ),
    root: () => find.byKey(_surfaceKey),
    keyboard: (p) async {
      await p.tabInto(find.byKey(_rowKey));
      await p.key(LogicalKeyboardKey.contextMenu);
      expect(_keysOn(p.tester, 'Copy'), isTrue);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(_keysOn(p.tester, 'Share'), isTrue);
      await p.key(LogicalKeyboardKey.end);
      expect(_keysOn(p.tester, 'Delete'), isTrue);
      await p.key(LogicalKeyboardKey.escape);
      expect(find.byKey(_surfaceKey), findsNothing);
      expect(p.focusIn(find.byKey(_rowKey)), isTrue);
    },
    rtl: (p) async {
      await _rightClick(p.tester, const Offset(200, 100));
      expect(_surface(p.tester).topRight, const Offset(200, 102));
    },
    motion: (p) async {
      await _rightClick(p.tester, const Offset(100, 100));
      await p.tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await p.tester.pump();
    },
  );
}
