// RawAdaptiveShell.branches moving between destinations: a transition the
// look supplies (a short fade through by default), both branches painted
// only while it runs, each keeping its state, the hidden one's tickers off
// after it, reduced motion at once, and focus in the branch going out moving
// to the one coming in. Sampled every frame, nothing jumps past the
// transition's rate.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const List<RawNavigationDestination> _destinations = [
  RawNavigationDestination(label: 'Home', icon: IconData(0xe318)),
  RawNavigationDestination(label: 'Mail', icon: IconData(0xe158)),
  RawNavigationDestination(label: 'Settings', icon: IconData(0xe57f)),
];

const Duration _frame = Duration(milliseconds: 16);
const Duration _duration = Duration(milliseconds: 250);

Key _pageKey(int i) => ValueKey('page $i');

class _Page extends StatefulWidget {
  const _Page(this.index, {this.focusNode});

  final int index;
  final FocusNode? focusNode;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Column(
    key: _pageKey(widget.index),
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('page ${widget.index} count $count'),
      RawButton(
        focusNode: widget.focusNode,
        semanticLabel: 'add ${widget.index}',
        onPressed: () => setState(() => count++),
        builder: (context, states, _) => const SizedBox(width: 120, height: 48),
      ),
    ],
  );
}

class _Host extends StatefulWidget {
  const _Host({
    this.transitionBuilder,
    this.transitionDuration,
    this.navigatorKeys,
    this.focusNodes,
  });

  final RawBranchTransitionBuilder? transitionBuilder;
  final Duration? transitionDuration;
  final List<GlobalKey<NavigatorState>>? navigatorKeys;
  final List<FocusNode>? focusNodes;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int selected = 0;

  void select(int i) => setState(() => selected = i);

  @override
  Widget build(BuildContext context) {
    final branches = <WidgetBuilder>[
      for (var i = 0; i < _destinations.length; i++)
        (context) => _Page(i, focusNode: widget.focusNodes?[i]),
    ];
    Widget destination(
      BuildContext context,
      RawNavigationDestination destination,
      RawDestinationDetails details,
    ) => SizedBox(width: 80, height: 40, child: Text(destination.label));
    Widget navigation(BuildContext context, RawNavigationDetails details) =>
        Column(children: details.destinations);
    if (widget.transitionBuilder == null && widget.transitionDuration == null) {
      return RawAdaptiveShell.branches(
        mode: RawNavigationMode.rail,
        destinations: _destinations,
        selectedIndex: selected,
        onDestinationSelected: select,
        destinationBuilder: destination,
        navigationBuilder: navigation,
        navigatorKeys: widget.navigatorKeys,
        branches: branches,
      );
    }
    return RawAdaptiveShell.branches(
      mode: RawNavigationMode.rail,
      destinations: _destinations,
      selectedIndex: selected,
      onDestinationSelected: select,
      destinationBuilder: destination,
      navigationBuilder: navigation,
      navigatorKeys: widget.navigatorKeys,
      transitionBuilder: widget.transitionBuilder,
      transitionDuration: widget.transitionDuration ?? _duration,
      branches: branches,
    );
  }
}

// How much of page [i] is painted: the opacities over it, 0 offstage or not
// built.
double _opacity(WidgetTester tester, int i) {
  final finder = find.byKey(_pageKey(i), skipOffstage: false);
  if (finder.evaluate().isEmpty) return 0;
  RenderObject? r = tester.renderObject(finder);
  var o = 1.0;
  while (r != null) {
    if (r is RenderOffstage && r.offstage) return 0;
    if (r is RenderAnimatedOpacity) o *= r.opacity.value;
    if (r is RenderOpacity) o *= r.opacity;
    r = r.parent;
  }
  return o;
}

// Page [i]'s painted width (its scale).
double _width(WidgetTester tester, int i) {
  final finder = find.byKey(_pageKey(i), skipOffstage: false);
  if (finder.evaluate().isEmpty) return 0;
  return tester.getRect(finder).width;
}

// A look's fade through, Material's: the branch going out fades over the
// first 35%, then the one coming in fades in as it grows from 92%.
final Animatable<double> _fadeIn = CurveTween(
  curve: const Interval(0.35, 1, curve: Curves.easeOut),
);
final Animatable<double> _growIn = Tween<double>(
  begin: 0.92,
  end: 1,
).chain(_fadeIn);
final Animatable<double> _fadeOut = Tween<double>(
  begin: 1,
  end: 0,
).chain(CurveTween(curve: const Interval(0, 0.35, curve: Curves.easeIn)));

Widget _fadeThrough(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => FadeTransition(
  opacity: animation.drive(_fadeIn),
  child: ScaleTransition(
    scale: animation.drive(_growIn),
    child: FadeTransition(
      opacity: secondaryAnimation.drive(_fadeOut),
      child: child,
    ),
  ),
);

// A look's slide: the branch coming in slides from the end, the one going out
// stays where it is, uncovered at first.
Widget _slide(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => AnimatedBuilder(
  animation: animation,
  builder: (context, child) => FractionalTranslation(
    translation: Offset(1 - animation.value, 0),
    child: child,
  ),
  child: child,
);

typedef _Sample = ({List<double> opacity, List<double> width});

Future<List<_Sample>> _frames(WidgetTester tester, {int count = 30}) async {
  final out = <_Sample>[];
  for (var f = 0; f < count; f++) {
    out.add((
      opacity: [for (var i = 0; i < 3; i++) _opacity(tester, i)],
      width: [for (var i = 0; i < 3; i++) _width(tester, i)],
    ));
    await tester.pump(_frame);
  }
  return out;
}

// The most any page's opacity, or its width as a share of the whole, moves
// in one frame.
({double opacity, double width}) _largestStep(List<_Sample> frames) {
  var opacity = 0.0, width = 0.0;
  for (var f = 1; f < frames.length; f++) {
    for (var i = 0; i < 3; i++) {
      final a = frames[f - 1], b = frames[f];
      opacity = [
        opacity,
        (b.opacity[i] - a.opacity[i]).abs(),
      ].reduce((x, y) => x > y ? x : y);
      if (a.width[i] > 0 && b.width[i] > 0 && a.opacity[i] + b.opacity[i] > 0) {
        final step = (b.width[i] - a.width[i]).abs() / b.width[i];
        width = step > width ? step : width;
      }
    }
  }
  return (opacity: opacity, width: width);
}

// The transition's rate: a whole change over its duration, a frame's share,
// at most 5 times as fast where a phase's curve is steepest (the fade
// through moves each fade in a part of it, eased).
final double _rate = 5 * _frame.inMicroseconds / _duration.inMicroseconds;

void main() {
  testWidgets(
    'with no transition of the look, a change of destination switches at '
    "once, as Material's NavigationBar over an IndexedStack does",
    (tester) async {
      await tester.pumpWidget(harness(const _Host()));
      await tester.tap(find.text('Mail'));
      await tester.pump();
      expect(_opacity(tester, 0), 0);
      expect(_opacity(tester, 1), 1);
      expect(_width(tester, 1), _width(tester, 0));
    },
  );

  testWidgets(
    "a look's fade through: both painted only while it runs, no frame past "
    'its rate',
    (tester) async {
      await tester.pumpWidget(
        harness(const _Host(transitionBuilder: _fadeThrough)),
      );
      expect(_opacity(tester, 0), 1);
      final width = _width(tester, 0);
      await tester.tap(find.text('Mail'));
      await tester.pump();
      final frames = await _frames(tester);
      bool between(double o) => o > 0 && o < 1;
      final painted = frames.where((s) => s.opacity[0] > 0 || s.opacity[1] < 1);
      expect(painted.length, greaterThanOrEqualTo(10), reason: 'it runs');
      expect(frames.where((s) => between(s.opacity[0])), isNotEmpty);
      expect(frames.where((s) => between(s.opacity[1])), isNotEmpty);
      final step = _largestStep(frames);
      expect(step.opacity, lessThanOrEqualTo(_rate));
      expect(step.width, lessThanOrEqualTo(_rate * 0.08));
      await tester.pumpAndSettle();
      expect(_opacity(tester, 0), 0, reason: 'hidden after');
      expect(_opacity(tester, 1), 1);
      expect(_width(tester, 1), width, reason: 'at its full size');
    },
  );

  testWidgets(
    'back to where it came from halfway carries on from the frame on screen',
    (tester) async {
      await tester.pumpWidget(
        harness(const _Host(transitionBuilder: _fadeThrough)),
      );
      await tester.tap(find.text('Mail'));
      await tester.pump();
      final first = await _frames(tester, count: 6);
      tester.state<_HostState>(find.byType(_Host)).select(0);
      await tester.pump();
      final back = await _frames(tester);
      final step = _largestStep([...first, ...back]);
      expect(step.opacity, lessThanOrEqualTo(_rate));
      expect(step.width, lessThanOrEqualTo(_rate * 0.08));
      await tester.pumpAndSettle();
      expect(_opacity(tester, 0), 1);
      expect(_opacity(tester, 1), 0);
    },
  );

  testWidgets('another destination halfway: the first two go out, the third '
      'comes in, no frame past its rate', (tester) async {
    await tester.pumpWidget(
      harness(const _Host(transitionBuilder: _fadeThrough)),
    );
    await tester.tap(find.text('Mail'));
    await tester.pump();
    final first = await _frames(tester, count: 6);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    final next = await _frames(tester);
    final step = _largestStep([...first, ...next]);
    expect(step.opacity, lessThanOrEqualTo(_rate));
    await tester.pumpAndSettle();
    expect([for (var i = 0; i < 3; i++) _opacity(tester, i)], [0, 0, 1]);
  });

  testWidgets(
    'the branch going out takes no pointer and no screen reader; each '
    'keeps its state, its tickers off once hidden',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          const _Host(transitionBuilder: _slide, transitionDuration: _duration),
        ),
      );
      await tester.tap(find.bySemanticsLabel('add 0'));
      await tester.pump();
      expect(find.text('page 0 count 1'), findsOneWidget);
      final at = tester.getCenter(find.bySemanticsLabel('add 0'));
      tester.state<_HostState>(find.byType(_Host)).select(2);
      await tester.pump();
      await tester.pump(_frame);
      final page0 = tester.element(find.byKey(_pageKey(0)));
      expect(_opacity(tester, 0), greaterThan(0), reason: 'still painted');
      expect(
        [
          for (final e in find.byType(_Page, skipOffstage: false).evaluate())
            (e.widget as _Page).index,
        ].last,
        2,
        reason: 'the one coming in is painted over the one going out',
      );
      expect(TickerMode.valuesOf(page0).enabled, isTrue);
      expect(find.semantics.byLabel('add 0'), findsNothing);
      await tester.tapAt(at);
      await tester.pumpAndSettle();
      expect(
        find.text('page 0 count 1', skipOffstage: false),
        findsOneWidget,
        reason: 'the tap did not reach it',
      );
      expect(TickerMode.valuesOf(page0).enabled, isFalse);
      tester.state<_HostState>(find.byType(_Host)).select(0);
      await tester.pumpAndSettle();
      expect(find.text('page 0 count 1'), findsOneWidget, reason: 'kept');
      semantics.dispose();
    },
  );

  for (final how in ['Remove animations', "iOS's Reduce Motion"]) {
    testWidgets('reduced motion ($how) switches at once', (tester) async {
      if (how != 'Remove animations') iosReduceMotion(tester);
      await tester.pumpWidget(
        harness(
          const _Host(transitionBuilder: _fadeThrough),
          reduceMotion: how == 'Remove animations',
        ),
      );
      await tester.tap(find.text('Mail'));
      await tester.pump();
      expect(_opacity(tester, 0), 0);
      expect(_opacity(tester, 1), 1);
    });
  }

  testWidgets('a zero duration switches at once', (tester) async {
    await tester.pumpWidget(
      harness(
        const _Host(
          transitionBuilder: _fadeThrough,
          transitionDuration: Duration.zero,
        ),
      ),
    );
    await tester.tap(find.text('Mail'));
    await tester.pump();
    expect(_opacity(tester, 0), 0);
    expect(_opacity(tester, 1), 1);
  });

  testWidgets("a look's transition is handed each branch's coming in and "
      'going out', (tester) async {
    // Each branch's own pair, by its coming in.
    final seen = <Animation<double>, List<(double, double)>>{};
    await tester.pumpWidget(
      harness(
        _Host(
          transitionDuration: const Duration(milliseconds: 100),
          transitionBuilder: (context, animation, secondaryAnimation, child) =>
              AnimatedBuilder(
                animation: Listenable.merge([animation, secondaryAnimation]),
                builder: (context, child) {
                  seen.putIfAbsent(animation, () => []).add((
                    animation.value,
                    secondaryAnimation.value,
                  ));
                  return child!;
                },
                child: child,
              ),
        ),
      ),
    );
    expect(seen.length, 1);
    final home = seen.keys.single;
    expect(seen[home]!.last, (1.0, 0.0), reason: 'at rest: in, not going out');
    await tester.tap(find.text('Mail'));
    await tester.pump();
    for (var f = 0; f < 10; f++) {
      await tester.pump(_frame);
    }
    await tester.pumpAndSettle();
    final mail = seen.keys.singleWhere((a) => a != home);
    final into = seen[mail]!, outOf = seen[home]!;
    expect(into.first.$1, lessThan(0.5));
    expect(into.last, (1.0, 0.0));
    final ins = [for (final s in into) s.$1];
    expect(ins, orderedEquals([...ins]..sort()), reason: 'it only comes in');
    expect(outOf.any((s) => s.$2 > 0 && s.$2 < 1), isTrue);
    expect(outOf.last, (0.0, 0.0), reason: 'hidden: ready to come in again');
  });

  for (final transition in <RawBranchTransitionBuilder?>[null, _fadeThrough]) {
    final how = transition == null ? 'at once' : 'in a fade through';
    testWidgets(
      'focus in the branch going out moves to the one coming in, and comes '
      'back where it was, $how',
      (tester) async {
        final keys = [for (var i = 0; i < 3; i++) GlobalKey<NavigatorState>()];
        final nodes = [for (var i = 0; i < 3; i++) FocusNode()];
        addTearDown(() {
          for (final n in nodes) {
            n.dispose();
          }
        });
        await tester.pumpWidget(
          harness(
            _Host(
              navigatorKeys: keys,
              focusNodes: nodes,
              transitionBuilder: transition,
            ),
          ),
        );
        nodes[0].requestFocus();
        await tester.pump();
        tester.state<_HostState>(find.byType(_Host)).select(1);
        await tester.pumpAndSettle();
        expect(nodes[0].hasFocus, isFalse);
        expect(keys[1].currentState!.focusNode.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(nodes[1].hasFocus, isTrue, reason: "Tab goes on in the page");
        tester.state<_HostState>(find.byType(_Host)).select(0);
        await tester.pumpAndSettle();
        expect(nodes[0].hasFocus, isTrue, reason: 'where it was');
      },
    );

    testWidgets('focus on the navigation stays there, a branch shown for the '
        'first time too, $how', (tester) async {
      final keys = [for (var i = 0; i < 3; i++) GlobalKey<NavigatorState>()];
      await tester.pumpWidget(
        harness(_Host(navigatorKeys: keys, transitionBuilder: transition)),
      );
      Focus.of(tester.element(find.text('Home'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_opacity(tester, 1), 1);
      expect(
        Focus.of(tester.element(find.text('Mail'))).hasPrimaryFocus,
        isTrue,
      );
      expect(keys[1].currentState!.focusNode.hasFocus, isFalse);
    });
  }
}
