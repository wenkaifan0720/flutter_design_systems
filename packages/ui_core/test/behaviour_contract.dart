// A behaviour's contract, stated once and checked in every reading: what a
// screen reader gets from its node, what changes when it is disabled or
// wrong, what the keyboard does, and that it holds right to left, at twice
// the text size and under Reduce Motion. A behaviour's test file calls
// [behaviourContract] with a few lines; this file turns them into one test
// per facet, so a change that drops an action, a flag or a key fails by name.
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'behaviour_harness.dart';

/// The switches one reading builds the behaviour with.
class ContractCase {
  /// A reading: [enabled] and [error] as the behaviour takes them.
  const ContractCase({this.enabled = true, this.error = false});

  /// Whether the behaviour takes input.
  final bool enabled;

  /// Whether it is drawn and announced as wrong.
  final bool error;
}

/// What a contract's scripts hold: the tester, the behaviour's node and the
/// part of the tree that is the behaviour.
class ContractProbe {
  /// A probe of [node] (and of [root], the behaviour's subtree).
  ContractProbe(this.tester, this.node, this.root);

  /// The tester.
  final WidgetTester tester;

  /// The behaviour's own semantics node.
  final Finder node;

  /// The behaviour's subtree, for where focus is.
  final Finder root;

  /// The node now ([semanticsOf]).
  SemanticsNode get semantics => semanticsOf(tester, node);

  /// The node's data now.
  SemanticsData get data => semantics.getSemanticsData();

  /// Presses [key] (with Shift when [shift]) and settles.
  Future<void> key(LogicalKeyboardKey key, {bool shift = false}) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
  }

  /// Presses Tab (Shift+Tab when [back]).
  Future<void> tab({bool back = false}) =>
      key(LogicalKeyboardKey.tab, shift: back);

  /// Whether the primary focus is in [within] (the behaviour's subtree when
  /// null).
  bool focusIn([Finder? within]) {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    final roots = (within ?? root).evaluate().toSet();
    if (roots.contains(focused)) return true;
    var inside = false;
    focused.visitAncestorElements((e) {
      if (roots.contains(e)) {
        inside = true;
        return false;
      }
      return true;
    });
    return inside;
  }

  /// Whether the node itself has the focus (its semantics says so).
  bool get focused => data.flagsCollection.isFocused == Tristate.isTrue;

  /// Tabs until the node has the focus (or, given [within], until focus is
  /// in that subtree), at most [limit] times; fails when it never gets there.
  Future<void> tabInto([Finder? within, int limit = 12]) async {
    bool there() => within == null ? focused : focusIn(within);
    for (var i = 0; i < limit && !there(); i++) {
      await tab();
    }
    expect(there(), isTrue, reason: 'Tab reaches it');
  }
}

/// The semantics node [finder]'s widget makes: its render object's own,
/// or the first one down a chain of single children (an EditableText's
/// node sits below its top render object); else the node it merges into
/// above.
SemanticsNode semanticsOf(WidgetTester tester, Finder finder) {
  RenderObject? render = finder.evaluate().single.renderObject;
  while (render != null) {
    final own = render.debugSemantics;
    if (own != null) return own;
    final children = <RenderObject>[];
    render.visitChildren(children.add);
    render = children.length == 1 ? children.single : null;
  }
  return tester.getSemantics(finder);
}

/// Every label, value, hint and tooltip in the tree, for words that must
/// stay out of it.
List<String> semanticsWords() {
  final words = <String>[];
  void visit(SemanticsNode node) {
    final d = node.getSemanticsData();
    words.addAll(
      [d.label, d.value, d.hint, d.tooltip].where((w) => w.isNotEmpty),
    );
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final root = semanticsOwner().rootSemanticsNode;
  if (root != null) visit(root);
  return words;
}

/// The labels of every live region in the tree.
List<String> liveRegionWords() {
  final words = <String>[];
  void visit(SemanticsNode node) {
    final d = node.getSemanticsData();
    if (d.flagsCollection.isLiveRegion) words.add(d.label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final root = semanticsOwner().rootSemanticsNode;
  if (root != null) visit(root);
  return words;
}

void _expectHidden(List<String> hidden) {
  if (hidden.isEmpty) return;
  final words = semanticsWords();
  for (final word in hidden) {
    expect(
      words.where((w) => w.contains(word)),
      isEmpty,
      reason: '"$word" is decoration: a screen reader never hears it',
    );
  }
}

const Duration _settle = Duration(milliseconds: 1000);

/// Makes a controller with [create], builds [builder] with it and disposes
/// it with the tree: a contract's build owns what it makes.
class Owned<T extends ChangeNotifier> extends StatefulWidget {
  /// Owns what [create] makes.
  const Owned({super.key, required this.create, required this.builder});

  /// Makes the controller, once.
  final T Function() create;

  /// Builds with it.
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<Owned<T>> createState() => _OwnedState<T>();
}

class _OwnedState<T extends ChangeNotifier> extends State<Owned<T>> {
  late final T _value = widget.create();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

/// States [name]'s contract; each facet becomes its own test.
///
/// - [build] makes the behaviour, with its reference painter, for a
///   [ContractCase]; the harness supplies direction, text size and motion.
/// - [open] brings it to where its node stands (shows a toast, pushes a
///   sheet), after each build.
/// - [node] finds the behaviour's own semantics node, and [semantics]
///   (an [isSemantics] matcher) is what it says when enabled and right:
///   role, label, value, actions, live region. It must hold in every
///   reading: left to right and right to left, at text scale 1 and 2.
/// - [role] is the node's [SemanticsRole] where Flutter's own widgets give
///   one (a radio group, a menu, a table).
/// - [disabled] is the node when `enabled: false`; the behaviour then also
///   takes no focus. Leave it null only for a behaviour with no disabled
///   state, and say why in [noDisabledState].
/// - [error] is the node when `error: true`; [errorWords], what it says is
///   wrong, are announced when the error appears (an announcement, or a
///   live region).
/// - [hidden] are words of the reference painter's decoration that never
///   reach the tree.
/// - [keyboard] and [rtl] are scripts, left to right and right to left.
/// - [motion] starts what moves (opens, shows, slides); under Reduce Motion
///   it must settle within a second and nothing may run on (no autoplay,
///   no endless spinner).
/// - [targets] checks every tap target in the tree is at least 44 by 44
///   (Flutter's iOS guideline, the kit's minimum) at both text sizes.
/// - [root] is the behaviour's subtree: disabled, focus stays out of all of
///   it (the node alone when null).
void behaviourContract(
  String name, {
  required Widget Function(ContractCase c) build,
  Future<void> Function(WidgetTester tester)? open,
  required Finder Function() node,
  required Matcher semantics,
  SemanticsRole? role,
  Matcher? disabled,
  String? noDisabledState,
  Matcher? error,
  String? errorWords,
  List<String> hidden = const [],
  Future<void> Function(ContractProbe p)? keyboard,
  Future<void> Function(ContractProbe p)? rtl,
  Future<void> Function(ContractProbe p)? motion,
  bool targets = true,
  Finder Function()? root,
}) {
  assert(
    (disabled == null) != (noDisabledState == null),
    'state the disabled node, or why there is none',
  );
  // Finders are made inside a test: a semantics finder reads the binding.

  Future<ContractProbe> pump(
    WidgetTester tester, {
    ContractCase c = const ContractCase(),
    TextDirection textDirection = TextDirection.ltr,
    double textScale = 1,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      harness(
        Builder(builder: (context) => build(c)),
        textDirection: textDirection,
        textScale: textScale,
        reduceMotion: reduceMotion,
      ),
    );
    await tester.pumpAndSettle();
    if (open != null) {
      await open(tester);
      await tester.pumpAndSettle();
    }
    final n = node();
    expect(n, findsOneWidget, reason: 'the contract finds its node');
    return ContractProbe(tester, n, root?.call() ?? n);
  }

  group('$name contract', () {
    testWidgets('semantics: the node', (tester) async {
      final p = await pump(tester);
      expect(p.semantics, semantics);
      if (role != null) expect(p.data.role, role, reason: 'its role');
      _expectHidden(hidden);
    });

    if (disabled != null) {
      testWidgets('disabled: the node, and no focus', (tester) async {
        final p = await pump(tester, c: const ContractCase(enabled: false));
        expect(p.semantics, disabled);
        _expectHidden(hidden);
        for (var i = 0; i < 12; i++) {
          await p.tab();
          expect(p.focused, isFalse, reason: 'Tab passes it by');
          if (root != null) {
            expect(p.focusIn(), isFalse, reason: 'and all of it');
          }
        }
      });
    }

    if (error != null) {
      testWidgets('error: the node says it is wrong, told as it appears', (
        tester,
      ) async {
        await pump(tester);
        tester.takeAnnouncements();
        final p = await pump(tester, c: const ContractCase(error: true));
        expect(p.semantics, error);
        if (errorWords != null) {
          final said = tester.takeAnnouncements().map((a) => a.message);
          expect(
            said.any((m) => m.contains(errorWords)) ||
                liveRegionWords().any((w) => w.contains(errorWords)),
            isTrue,
            reason:
                '"$errorWords" is announced as it appears (an announcement '
                'where the platform takes them, else a live region)',
          );
        }
      });
    }

    if (keyboard != null) {
      testWidgets('keyboard', (tester) async {
        await keyboard(await pump(tester));
      });
    }

    testWidgets('right to left', (tester) async {
      final p = await pump(tester, textDirection: TextDirection.rtl);
      expect(p.semantics, semantics);
      await rtl?.call(p);
    });

    testWidgets('text scale 2', (tester) async {
      final p = await pump(tester, textScale: 2);
      expect(tester.takeException(), isNull, reason: 'nothing overflows');
      expect(p.semantics, semantics);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      if (targets) {
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      }
    });

    if (targets) {
      testWidgets('tap targets', (tester) async {
        await pump(tester);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });
    }

    if (motion != null) {
      testWidgets('Reduce Motion: it settles and nothing runs on', (
        tester,
      ) async {
        final p = await pump(tester, reduceMotion: true);
        await motion(p);
        // Spatial springs run critically damped (DesignMotionPolicy): they arrive
        // without overshoot on the token's timescale, well inside a second.
        // "Still moving" is a frame asked for: an open overlay keeps a frame
        // callback for its deferred layout (OverlayPortal) that asks for none.
        var waited = Duration.zero;
        const frame = Duration(milliseconds: 16);
        while (tester.binding.hasScheduledFrame && waited < _settle) {
          await tester.pump(frame);
          waited += frame;
        }
        expect(
          tester.binding.hasScheduledFrame,
          isFalse,
          reason:
              'under Reduce Motion it is still within '
              '${_settle.inMilliseconds} ms',
        );
      });
    }
  });
}
