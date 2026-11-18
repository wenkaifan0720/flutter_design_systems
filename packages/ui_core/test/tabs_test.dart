import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart'
    show DragStartBehavior, PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const List<String> _labels = ['Inbox', 'Sent', 'Drafts'];
final Map<int, DesignTabDetails> _seen = {};
DesignTabIndicatorDetails? _indicator;

DesignTabController _controller({
  int length = 3,
  int initialIndex = 0,
  double dampingRatio = 1,
}) => DesignTabController(
  length: length,
  initialIndex: initialIndex,
  vsync: const TestVSync(),
  dampingRatio: dampingRatio,
);

// The bare reference painter: a bar 300 wide of 48-high tabs, labelled; a
// black indicator; the pages under it (beside it, the tabs vertical).
Widget _tabs(
  DesignTabController controller, {
  List<String> labels = _labels,
  Set<int> disabled = const {},
  bool isScrollable = false,
  Axis direction = Axis.horizontal,
  bool selectionFollowsFocus = true,
  double? tabWidth,
  ScrollPhysics? physics,
  bool indicator = true,
}) {
  final bar = DesignTabBar(
    key: const ValueKey('bar'),
    controller: controller,
    tabs: [
      for (var i = 0; i < labels.length; i++)
        DesignTab(label: labels[i], enabled: !disabled.contains(i)),
    ],
    isScrollable: isScrollable,
    direction: direction,
    selectionFollowsFocus: selectionFollowsFocus,
    semanticLabel: 'Mail',
    tabBuilder: (context, tab, details) {
      _seen[details.index] = details;
      return SizedBox(
        key: ValueKey('tab ${tab.label}'),
        width: tabWidth,
        height: 48,
        child: Center(child: Text(tab.label)),
      );
    },
    indicatorBuilder: indicator
        ? (context, details) {
            _indicator = details;
            return const ColoredBox(
              key: ValueKey('indicator'),
              color: Color(0xFF000000),
            );
          }
        : null,
  );
  final view = DesignTabView(
    controller: controller,
    physics: physics,
    children: [for (final l in labels) Center(child: Text('$l page'))],
  );
  return Align(
    alignment: AlignmentDirectional.topStart,
    child: SizedBox(
      width: 300,
      height: 400,
      child: Flex(
        direction: direction == Axis.horizontal
            ? Axis.vertical
            : Axis.horizontal,
        children: [
          bar,
          Expanded(child: view),
          // Somewhere for Tab to go after the bar.
          const Focus(child: SizedBox.square(dimension: 1)),
        ],
      ),
    ),
  );
}

Widget _owned(Widget Function(DesignTabController controller) build) =>
    Owned<DesignTabController>(
      create: _controller,
      builder: (context, controller) => build(controller),
    );

ScrollPosition _pages(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(DesignTabView),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

bool _focusedOn(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.byKey(ValueKey('tab $label')))
        .getSemanticsData()
        .flagsCollection
        .isFocused ==
    Tristate.isTrue;

void main() {
  setUp(() {
    _seen.clear();
    _indicator = null;
  });

  behaviourContract(
    'DesignTabBar',
    build: (c) => _owned(
      (controller) =>
          _tabs(controller, disabled: c.enabled ? const {} : const {0, 1, 2}),
    ),
    node: () => find.byKey(const ValueKey('tab Inbox')),
    semantics: isSemantics(
      label: 'Inbox\nTab 1 of 3',
      isSelected: true,
      isFocusable: true,
      hasTapAction: true,
    ),
    role: SemanticsRole.tab,
    disabled: isSemantics(
      label: 'Inbox\nTab 1 of 3',
      isSelected: true,
      hasEnabledState: true,
      isEnabled: false,
    ),
    root: () => find.byKey(const ValueKey('bar')),
    keyboard: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_focusedOn(p.tester, 'Sent'), isTrue);
      expect(find.text('Sent page'), findsOneWidget, reason: 'chosen too');
      await p.key(LogicalKeyboardKey.end);
      expect(_focusedOn(p.tester, 'Drafts'), isTrue);
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_focusedOn(p.tester, 'Inbox'), isTrue, reason: 'it wraps');
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_focusedOn(p.tester, 'Drafts'), isTrue);
      await p.key(LogicalKeyboardKey.home);
      expect(_focusedOn(p.tester, 'Inbox'), isTrue);
      await p.key(LogicalKeyboardKey.arrowRight);
      await p.tab();
      expect(p.focusIn(), isFalse, reason: 'one tab stop');
      await p.tab(back: true);
      expect(_focusedOn(p.tester, 'Sent'), isTrue, reason: 'on the selected');
    },
    rtl: (p) async {
      expect(
        _rect(p.tester, 'tab Inbox').left,
        greaterThan(_rect(p.tester, 'tab Sent').left),
        reason: 'the first tab at the right',
      );
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_focusedOn(p.tester, 'Sent'), isTrue, reason: 'left is on');
    },
    motion: (p) async {
      await p.tester.tap(find.text('Drafts'));
      await p.tester.pump();
    },
  );

  testWidgets('a page swiped moves the selection with the finger, the '
      'indicator between the tabs; let go, it settles on the page', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller)));
    expect(_indicator!.rect, _rect(tester, 'tab Inbox'));
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Inbox'));
    final gesture = await tester.startGesture(const Offset(250, 200));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    // 200 of 300, past the slop: two thirds of the way.
    expect(controller.index, 0);
    expect(controller.offset, moreOrLessEquals(2 / 3, epsilon: .01));
    expect(controller.animation.value, moreOrLessEquals(2 / 3, epsilon: .01));
    expect(
      _rect(tester, 'indicator').left,
      moreOrLessEquals(200 / 3, epsilon: 1),
    );
    expect(_seen[0]!.selection, moreOrLessEquals(1 / 3, epsilon: .01));
    expect(_seen[1]!.selection, moreOrLessEquals(2 / 3, epsilon: .01));
    expect(_seen[2]!.selection, 0);
    expect(_seen[0]!.states, contains(WidgetState.selected));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(controller.previousIndex, 0);
    expect(controller.offset, 0);
    expect(find.text('Sent page'), findsOneWidget);
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Sent'));
    expect(_seen[1]!.states, contains(WidgetState.selected));
    expect(_seen[1]!.selection, 1);
  });

  testWidgets('a tab chosen springs the pages and the indicator together', (
    tester,
  ) async {
    final controller = _controller(dampingRatio: .3);
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller)));
    await tester.tap(find.text('Drafts'));
    await tester.pump();
    expect(controller.index, 2);
    expect(controller.indexIsChanging, isTrue);
    var most = 0.0;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final at = controller.animation.value;
      if (at > most) most = at;
      expect(
        _pages(tester).pixels,
        moreOrLessEquals(at.clamp(0, 2) * 300, epsilon: .5),
        reason: 'the pages on the same spring, held at the last',
      );
      expect(
        _rect(tester, 'indicator').left,
        moreOrLessEquals(at * 100, epsilon: .5),
      );
    }
    expect(most, greaterThan(2.05), reason: 'an underdamped token runs on');
    await tester.pumpAndSettle();
    expect(controller.indexIsChanging, isFalse);
    expect(controller.animation.value, 2);
    expect(find.text('Drafts page'), findsOneWidget);
    expect(find.text('Inbox page'), findsNothing, reason: 'off screen: gone');
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Drafts'));
  });

  testWidgets('under Reduce Motion a change runs critically damped', (
    tester,
  ) async {
    final controller = _controller(dampingRatio: .3);
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller), reduceMotion: true));
    controller.animateTo(2);
    var most = 0.0;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (controller.animation.value > most) most = controller.animation.value;
    }
    expect(most, lessThanOrEqualTo(2));
    await tester.pumpAndSettle();
    expect(find.text('Drafts page'), findsOneWidget);
  });

  testWidgets('a finger on the pages mid-change takes them from the spring', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller)));
    controller.animateTo(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(controller.indexIsChanging, isTrue);
    final at = controller.animation.value;
    final gesture = await tester.startGesture(const Offset(150, 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.indexIsChanging, isFalse, reason: 'held');
    expect(controller.animation.value, moreOrLessEquals(at, epsilon: .2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.animation.value, controller.index.toDouble());
    expect(find.text('${_labels[controller.index]} page'), findsOneWidget);
  });

  testWidgets('the index set jumps the pages and the indicator', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller)));
    controller.index = 2;
    await tester.pump();
    expect(find.text('Drafts page'), findsOneWidget);
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Drafts'));
    expect(tester.hasRunningAnimations, isFalse);
    controller.index = 2;
    expect(controller.previousIndex, 0, reason: 'the same: nothing');
  });

  testWidgets('without selectionFollowsFocus the arrows move focus alone; '
      'Enter or Space chooses', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(_tabs(controller, selectionFollowsFocus: false)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Inbox'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Sent'), isTrue);
    expect(controller.index, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(controller.index, 2);
  });

  testWidgets('a disabled tab is skipped, and the stop leaves a disabled '
      'selected tab', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller, disabled: const {1})));
    await tester.tap(find.text('Sent'));
    await tester.pumpAndSettle();
    expect(controller.index, 0, reason: 'a disabled tab takes no tap');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Drafts'), isTrue);
    expect(controller.index, 2);

    controller.index = 0;
    await tester.pumpWidget(harness(_tabs(controller, disabled: const {0})));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Sent'), isTrue, reason: 'the first enabled');
    // A key the bar does not take passes on.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(_focusedOn(tester, 'Sent'), isTrue);
  });

  testWidgets('a scrolling bar keeps the selected and the focused tab wholly '
      'in view', (tester) async {
    const labels = ['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven'];
    final controller = _controller(length: labels.length);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(
        _tabs(controller, labels: labels, isScrollable: true, tabWidth: 120),
      ),
    );
    expect(_rect(tester, 'tab One').width, 120, reason: 'its own width');
    controller.animateTo(4);
    await tester.pumpAndSettle();
    final five = _rect(tester, 'tab Five');
    expect(five.left, greaterThanOrEqualTo(0));
    expect(five.right, lessThanOrEqualTo(300));
    expect(five.right, moreOrLessEquals(300, epsilon: .5), reason: 'least');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(
      _rect(tester, 'tab Seven').right,
      moreOrLessEquals(300, epsilon: .5),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(_rect(tester, 'tab One').left, moreOrLessEquals(0, epsilon: .5));
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab One'));
  });

  testWidgets('vertical tabs: Up and Down, stacked at their own heights', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(_tabs(controller, direction: Axis.vertical, tabWidth: 100)),
    );
    final inbox = _rect(tester, 'tab Inbox');
    expect(_rect(tester, 'tab Sent').top, inbox.bottom);
    expect(inbox.width, 100);
    expect(_indicator!.direction, Axis.vertical);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Sent'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(controller.index, 0);
  });

  testWidgets('a screen reader hears a tab bar of tabs, each controlling its '
      'page, the page a tab panel', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller)));
    final bar = tester.getSemantics(find.bySemanticsLabel('Mail'));
    expect(bar.role, SemanticsRole.tabBar);
    final tabs = <SemanticsNode>[];
    bar.visitChildren((n) {
      tabs.add(n);
      return true;
    });
    final data = [for (final t in tabs) t.getSemanticsData()];
    expect([for (final d in data) d.role], everyElement(SemanticsRole.tab));
    expect(
      [for (final d in data) d.label],
      ['Inbox\nTab 1 of 3', 'Sent\nTab 2 of 3', 'Drafts\nTab 3 of 3'],
    );
    final page = tester.getSemantics(find.text('Inbox page'));
    SemanticsNode? panel = page;
    while (panel != null && panel.role != SemanticsRole.tabPanel) {
      panel = panel.parent;
    }
    expect(panel, isNotNull);
    expect(data.first.controlsNodes, {panel!.identifier});
    expect(find.text('Sent page'), findsNothing, reason: 'off screen');
    semantics.dispose();
  });

  testWidgets('right to left, a swipe toward the end leads on', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(_tabs(controller), textDirection: TextDirection.rtl),
    );
    await tester.timedDrag(
      find.text('Inbox page'),
      const Offset(200, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Sent'));
    expect(
      _rect(tester, 'tab Sent').left - _rect(tester, 'tab Drafts').left,
      100,
    );
  });

  testWidgets('NeverScrollableScrollPhysics stops swiping', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(_tabs(controller, physics: const NeverScrollableScrollPhysics())),
    );
    await tester.fling(find.text('Inbox page'), const Offset(-200, 0), 2000);
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    await tester.tap(find.text('Sent'));
    await tester.pumpAndSettle();
    expect(find.text('Sent page'), findsOneWidget, reason: 'the bar still');
  });

  testWidgets('a new controller takes over bar and pages', (tester) async {
    final first = _controller();
    final second = _controller(initialIndex: 2);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(harness(_tabs(first)));
    await tester.pumpWidget(harness(_tabs(second)));
    await tester.pumpAndSettle();
    expect(find.text('Drafts page'), findsOneWidget);
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Drafts'));
    first.index = 1;
    await tester.pumpAndSettle();
    expect(find.text('Drafts page'), findsOneWidget, reason: 'let go');
  });

  // A bar whose tabs take their words' size (8 round them): a row (or
  // column) of words that reports overflowing its tab.
  Widget grown(
    DesignTabController controller, {
    required List<String> labels,
    required Axis direction,
    required bool isScrollable,
    bool bold = false,
  }) => Align(
    alignment: AlignmentDirectional.topStart,
    child: SizedBox(
      width: 300,
      child: DesignTabBar(
        controller: controller,
        tabs: [for (final l in labels) DesignTab(label: l)],
        direction: direction,
        isScrollable: isScrollable,
        tabBuilder: (context, tab, details) => Padding(
          key: ValueKey('tab ${details.index}'),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    key: ValueKey('words ${details.index}'),
                    // [bold]: the chosen tab's words set bold, and wider
                    // (the test font's bold is no wider).
                    style: bold && details.states.contains(WidgetState.selected)
                        ? const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        indicatorBuilder: (context, details) {
          _indicator = details;
          return const ColoredBox(color: Color(0xFF000000));
        },
      ),
    ),
  );

  for (final direction in Axis.values) {
    for (final isScrollable in [false, true]) {
      testWidgets('a tab whose words grow where it stands lays the bar out '
          'again: text ×1 to ×2, then renamed ($direction, '
          '${isScrollable ? 'scrolling' : 'filled'})', (tester) async {
        final controller = _controller();
        addTearDown(controller.dispose);
        Future<void> pump(List<String> labels, double scale) async {
          await tester.pumpWidget(
            harness(
              grown(
                controller,
                labels: labels,
                direction: direction,
                isScrollable: isScrollable,
              ),
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'no overflow');
          for (var i = 0; i < labels.length; i++) {
            final words = tester.getSize(find.byKey(ValueKey('words $i')));
            final tab = tester.getSize(find.byKey(ValueKey('tab $i')));
            // Each tab holds its words and its padding, along the bar
            // (unless it shares a row) and across it.
            if (direction == Axis.vertical) {
              expect(tab.height, words.height + 16, reason: labels[i]);
              expect(tab.width, greaterThanOrEqualTo(words.width + 16));
            } else {
              expect(tab.height, greaterThanOrEqualTo(words.height + 16));
              if (isScrollable) {
                expect(tab.width, words.width + 16, reason: labels[i]);
              }
            }
          }
          expect(_indicator!.rect, _indicator!.tabRect);
          expect(
            _indicator!.rect,
            tester
                .getRect(find.byKey(const ValueKey('tab 0')))
                .shift(-tester.getTopLeft(find.byType(DesignTabBar))),
          );
        }

        await pump(const ['In', 'Out', 'All'], 1);
        final small = tester.getSize(find.byType(DesignTabBar));
        final first = tester.getSize(find.byKey(const ValueKey('tab 0')));
        await pump(const ['In', 'Out', 'All'], 2);
        expect(
          tester.getSize(find.byType(DesignTabBar)).height,
          greaterThan(small.height),
        );
        await pump(const ['In', 'Out', 'All'], 1);
        expect(tester.getSize(find.byType(DesignTabBar)), small);
        // Renamed, longer: in a scrolling row the tab grows along it.
        await pump(const ['Inbox', 'Out', 'All'], 1);
        if (isScrollable && direction == Axis.horizontal) {
          expect(
            tester.getSize(find.byKey(const ValueKey('tab 0'))).width,
            greaterThan(first.width),
          );
        }
        await pump(const ['In', 'Out', 'All'], 1);
        expect(tester.getSize(find.byType(DesignTabBar)), small);
      });
    }
  }

  for (final direction in Axis.values) {
    testWidgets('a chosen tab whose words turn bold and grow lays the bar '
        'out again, chosen by an arrow key or a tap ($direction)', (
      tester,
    ) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        harness(
          grown(
            controller,
            labels: const ['Document', 'History', 'All'],
            direction: direction,
            isScrollable: true,
            bold: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      Size words(int i) => tester.getSize(find.byKey(ValueKey('words $i')));
      final plain = words(1).width;
      void holds(int chosen) {
        expect(controller.index, chosen);
        expect(tester.takeException(), isNull, reason: 'no words cut');
        for (var i = 0; i < 3; i++) {
          final tab = tester.getSize(find.byKey(ValueKey('tab $i')));
          final reason = 'tab $i, tab $chosen chosen';
          if (direction == Axis.horizontal) {
            expect(tab.width, words(i).width + 16, reason: reason);
          } else {
            expect(tab.width, greaterThanOrEqualTo(words(i).width + 16));
          }
        }
        expect(
          _indicator!.rect.size,
          tester.getSize(find.byKey(ValueKey('tab $chosen'))),
        );
      }

      holds(0);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(
        direction == Axis.horizontal
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowDown,
      );
      await tester.pumpAndSettle();
      expect(words(1).width, greaterThan(plain), reason: 'bold, wider');
      holds(1);
      await tester.tap(find.byKey(const ValueKey('tab 2')));
      await tester.pumpAndSettle();
      holds(2);
      await tester.tap(find.byKey(const ValueKey('tab 1')));
      await tester.pumpAndSettle();
      holds(1);
    });
  }

  // A tab whose face (32 square) stands in a 48 touch target.
  Widget targeted(
    DesignTabController controller, {
    required Axis direction,
    DecorationPosition indicatorPosition = DecorationPosition.background,
  }) => Align(
    alignment: AlignmentDirectional.topStart,
    child: DesignTabBar(
      controller: controller,
      tabs: [for (final l in _labels) DesignTab(label: l)],
      direction: direction,
      isScrollable: true,
      indicatorPosition: indicatorPosition,
      tabBuilder: (context, tab, details) => DesignTapTarget(
        key: ValueKey('target ${tab.label}'),
        minSize: const Size.square(48),
        child: ColoredBox(
          key: ValueKey('face ${tab.label}'),
          color: const Color(0xFFFFFFFF),
          child: const SizedBox.square(dimension: 32),
        ),
      ),
      indicatorBuilder: (context, details) {
        _indicator = details;
        return const ColoredBox(
          key: ValueKey('indicator'),
          color: Color(0xFF000000),
        );
      },
    ),
  );

  testWidgets('a tab whose touch target stands larger than its face: the '
      'target is the hit area, the face keeps its own size along the bar, '
      'and the indicator keeps to the face', (tester) async {
    final controller = _controller(initialIndex: 1);
    addTearDown(controller.dispose);
    for (final direction in Axis.values) {
      await tester.pumpWidget(
        harness(targeted(controller, direction: direction)),
      );
      await tester.pumpAndSettle();
      final bar = tester.getTopLeft(find.byType(DesignTabBar));
      final face = _rect(tester, 'face Sent');
      final target = _rect(tester, 'target Sent');
      expect(target.size, const Size.square(48), reason: '$direction');
      expect(face.size, const Size.square(32), reason: '$direction');
      expect(face.center, target.center);
      expect(_indicator!.rect, face.shift(-bar));
      expect(_indicator!.tabRect, target.shift(-bar));
      expect(_rect(tester, 'indicator'), face);
      // A tap on the target's edge, off the face, chooses it.
      await tester.tapAt(target.topLeft + const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(controller.index, 1);
      await tester.tapAt(
        _rect(tester, 'target Drafts').topLeft + const Offset(2, 2),
      );
      await tester.pumpAndSettle();
      expect(controller.index, 2);
      expect(_rect(tester, 'indicator'), _rect(tester, 'face Drafts'));
      controller.index = 1;
      await tester.pumpAndSettle();
    }
  });

  testWidgets("the indicator has the selected tab's states: hovered, "
      'pressed, focused', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller)));
    await tester.pumpAndSettle();
    expect(_indicator!.states, {WidgetState.selected});
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_focusedOn(tester, 'Inbox'), isTrue);
    expect(_indicator!.states, {WidgetState.selected, WidgetState.focused});
    // Chosen, the next tab's states are the indicator's.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(_indicator!.states, {WidgetState.selected, WidgetState.focused});
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pumpAndSettle();
    expect(_indicator!.states, {WidgetState.selected});
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    // Another tab hovered: not the indicator's.
    await mouse.moveTo(_rect(tester, 'tab Inbox').center);
    await tester.pump();
    expect(_indicator!.states, {WidgetState.selected});
    await mouse.moveTo(_rect(tester, 'tab Sent').center);
    await tester.pump();
    expect(_indicator!.states, {WidgetState.selected, WidgetState.hovered});
    await mouse.down(_rect(tester, 'tab Sent').center);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_indicator!.states, contains(WidgetState.pressed));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(_indicator!.states, isNot(contains(WidgetState.pressed)));
    await mouse.moveTo(const Offset(-10, -10));
    await tester.pump();
    expect(_indicator!.states, isNot(contains(WidgetState.hovered)));
  });

  testWidgets('the indicator is painted under the tabs, or over them', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    RenderBox strip() => tester.renderObject<RenderBox>(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_TabStrip'),
    );
    const face = Color(0xFFFFFFFF);
    const indicator = Color(0xFF000000);
    await tester.pumpWidget(
      harness(targeted(controller, direction: Axis.horizontal)),
    );
    expect(
      strip(),
      paints
        ..rect(color: indicator)
        ..rect(color: face)
        ..rect(color: face)
        ..rect(color: face),
    );
    await tester.pumpWidget(
      harness(
        targeted(
          controller,
          direction: Axis.horizontal,
          indicatorPosition: DecorationPosition.foreground,
        ),
      ),
    );
    expect(
      strip(),
      paints
        ..rect(color: face)
        ..rect(color: face)
        ..rect(color: face)
        ..rect(color: indicator),
    );
    // It takes no hits either way.
    await tester.tap(find.byKey(const ValueKey('face Inbox')));
    await tester.pumpAndSettle();
    expect(controller.index, 0);
  });

  testWidgets('a bar with no indicator, measured for its intrinsic height', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: IntrinsicHeight(
            child: SizedBox(
              width: 300,
              child: DesignTabBar(
                controller: controller,
                tabs: [for (final l in _labels) DesignTab(label: l)],
                tabBuilder: (context, tab, details) =>
                    SizedBox(height: 48, child: Text(tab.label)),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DesignTabBar)), const Size(300, 48));
    expect(find.byKey(const ValueKey('indicator')), findsNothing);
  });

  testWidgets('a bar rebuilt another way lays out again; it measures dry and '
      'by its intrinsics', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(_tabs(controller, tabWidth: 90)));
    final strip = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_TabStrip',
    );
    RenderBox render() => tester.renderObject<RenderBox>(strip);
    for (final direction in Axis.values) {
      final box = render();
      final along = direction == Axis.horizontal;
      // The dry size is the size laid out.
      expect(
        box.getDryLayout(BoxConstraints.loose(box.size)),
        along ? box.size : isNotNull,
      );
      expect(box.getMinIntrinsicWidth(48), greaterThan(0));
      expect(box.getMaxIntrinsicWidth(48), greaterThan(0));
      expect(box.getMinIntrinsicHeight(300), greaterThan(0));
      expect(box.getMaxIntrinsicHeight(300), greaterThan(0));
      await tester.pumpWidget(
        harness(
          _tabs(
            controller,
            direction: Axis.vertical,
            isScrollable: true,
            indicator: false,
            tabWidth: 90,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
    }
    expect(render().size.width, 90);
    expect(find.byKey(const ValueKey('indicator')), findsNothing);
    // Fewer tabs, from a new controller.
    final two = _controller(length: 2);
    addTearDown(two.dispose);
    await tester.pumpWidget(
      harness(_tabs(two, labels: const ['Inbox', 'Sent'], tabWidth: 90)),
    );
    expect(_rect(tester, 'tab Sent').width, 150);
    expect(_rect(tester, 'indicator'), _rect(tester, 'tab Inbox'));
  });

  test('its parts describe themselves', () {
    final controller = _controller();
    addTearDown(controller.dispose);
    final bar = DesignTabBar(
      controller: controller,
      tabs: const [DesignTab(label: 'Inbox')],
      tabBuilder: (context, tab, details) => const SizedBox(),
      isScrollable: true,
      direction: Axis.vertical,
      selectionFollowsFocus: false,
      semanticLabel: 'Mail',
      indicatorPosition: DecorationPosition.foreground,
    ).toDiagnosticsNode().toStringDeep();
    for (final s in [
      'tabs: [Inbox]',
      'has tabBuilder',
      'isScrollable',
      'direction: vertical',
      'selectionFollowsFocus: false',
      'semanticLabel: "Mail"',
      'indicatorPosition: foreground',
    ]) {
      expect(bar, contains(s));
    }
    final view = DesignTabView(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
      children: const [SizedBox()],
    ).toDiagnosticsNode().toStringDeep();
    expect(view, contains('physics: NeverScrollableScrollPhysics'));
    expect(view, contains('dragStartBehavior: down'));
    const details = DesignTabIndicatorDetails(
      rect: Rect.zero,
      direction: Axis.horizontal,
    );
    expect(
      details,
      const DesignTabIndicatorDetails(
        rect: Rect.zero,
        direction: Axis.horizontal,
      ),
    );
    expect(
      details.hashCode,
      const DesignTabIndicatorDetails(
        rect: Rect.zero,
        direction: Axis.horizontal,
      ).hashCode,
    );
    expect(details.tabRect, Rect.zero, reason: 'the face, unless given');
    expect(details.states, isEmpty);
    const hovered = DesignTabIndicatorDetails(
      rect: Rect.zero,
      tabRect: Rect.fromLTWH(0, 0, 48, 48),
      direction: Axis.horizontal,
      states: {WidgetState.selected, WidgetState.hovered},
    );
    const same = DesignTabIndicatorDetails(
      rect: Rect.zero,
      tabRect: Rect.fromLTWH(0, 0, 48, 48),
      direction: Axis.horizontal,
      states: {WidgetState.hovered, WidgetState.selected},
    );
    expect(hovered, same);
    expect(hovered.hashCode, same.hashCode);
    expect(hovered, isNot(details));
    expect(
      hovered,
      isNot(
        const DesignTabIndicatorDetails(
          rect: Rect.zero,
          tabRect: Rect.fromLTWH(0, 0, 48, 48),
          direction: Axis.horizontal,
          states: {WidgetState.selected},
        ),
      ),
    );
  });

  // The route × size × direction × text scale matrix.
  for (final direction in Axis.values) {
    for (final isScrollable in [false, true]) {
      for (final textDirection in TextDirection.values) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('at rest the indicator is the selected tab: $direction, '
              '${isScrollable ? 'scrolling' : 'filled'}, $textDirection, '
              'text ×$scale', (tester) async {
            final controller = _controller(initialIndex: 1);
            addTearDown(controller.dispose);
            await tester.pumpWidget(
              harness(
                _tabs(
                  controller,
                  direction: direction,
                  isScrollable: isScrollable,
                  tabWidth: 90,
                ),
                textDirection: textDirection,
                textScale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(_rect(tester, 'indicator'), _rect(tester, 'tab Sent'));
            controller.animateTo(2);
            await tester.pumpAndSettle();
            expect(_rect(tester, 'indicator'), _rect(tester, 'tab Drafts'));
            expect(find.text('Drafts page'), findsOneWidget);
          }, tags: 'sweep');
        }
      }
    }
  }
}
