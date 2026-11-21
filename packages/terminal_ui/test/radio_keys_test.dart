// A single choice answers the keys as Flutter's RadioGroup does: one Tab
// stop, on the chosen radio (the first that can be chosen when none is,
// and when the chosen one is turned off); the arrows move and choose, round
// the ends, past a radio turned off, Left going on right to left. TermRadio
// siblings get it from Flutter's RadioGroup at the owner of their choice,
// with ui_core's RadioGroupKeyboardFix inside it; each radio keeps the node
// its caller gave it. Every single choice in the gallery is checked with
// ui_core_test's DesignRadioGroupCheck: its radios, its segments.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignRadioGroupCheck;

// The example's pages are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'faces.dart';

const _options = ['A', 'B', 'C', 'D'];

/// TermRadio siblings for [_options], B turned off, grouped at their owner
/// with the caller's [nodes], between a focusable before and one after: in
/// a column, or in a row with [axis].
Widget _group({
  required TextDirection direction,
  required FocusNode before,
  required Map<String, FocusNode> nodes,
  required String? initial,
  Axis axis = Axis.vertical,
  ValueChanged<String>? onChosen,
}) {
  var chosen = initial;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TermTheme(
      data: TermThemeData.dark(),
      child: Directionality(
        textDirection: direction,
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Focus(focusNode: before, child: const Text('before')),
              RadioGroup<String>(
                key: const ValueKey('radios'),
                groupValue: chosen,
                onChanged: (v) {
                  setState(() => chosen = v);
                  onChosen?.call(v!);
                },
                child: RadioGroupKeyboardFix<String>(
                  child: Flex(
                    direction: axis,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final v in _options)
                        TermRadio<String>(
                          key: ValueKey(v),
                          value: v,
                          label: v,
                          enabled: v != 'B',
                          focusNode: nodes[v],
                        ),
                    ],
                  ),
                ),
              ),
              const Focus(child: Text('after')),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _checkGroup(WidgetTester t, FocusNode before) async =>
    (await const DesignRadioGroupCheck(look: 'Terminal').check(
      t.element(find.byKey(const ValueKey('radios'))),
      before: before,
      sendKeyEvent: t.sendKeyEvent,
      pump: t.pump,
    )).verify();

/// The box of the radio or segment standing for [value]: Flutter's
/// RawRadio, under its face.
Rect _boxOf(WidgetTester t, String value) => t.getRect(
  find.byWidgetPredicate((w) => w is RawRadio<String> && w.value == value),
);

/// Presses each of [values] at its box's start, middle, end, top and bottom,
/// each time from another choice, and expects the press to choose it.
/// RawRadio's own detector takes a press only where the face paints; a
/// Terminal radio or segment takes it anywhere in its box, the cells between
/// its brackets and its words too, as the published ones did.
Future<void> _pressEverywhere(
  WidgetTester t,
  String? Function() chosen,
  List<String> values,
) async {
  for (final (i, value) in values.indexed) {
    final other = values[(i + 1) % values.length];
    final box = _boxOf(t, value);
    for (final at in [
      box.centerLeft + const Offset(2, 0),
      box.center,
      box.centerRight - const Offset(2, 0),
      box.topCenter + const Offset(0, 2),
      box.bottomCenter - const Offset(0, 2),
    ]) {
      await t.tapAt(_boxOf(t, other).center);
      await t.pumpAndSettle();
      expect(chosen(), other);
      await t.tapAt(at);
      await t.pumpAndSettle();
      expect(chosen(), value, reason: '$value pressed at $at in $box');
    }
  }
}

void main() {
  setUpAll(loadFaces);

  // The third chosen, none, the first, and the one turned off (B).
  for (final axis in Axis.values) {
    for (final direction in TextDirection.values) {
      for (final initial in <String?>['C', null, 'A', 'B']) {
        testWidgets('grouped radios in a ${axis.name} line, ${direction.name}, '
            'chosen $initial: one Tab stop, arrows choose, each on its '
            "caller's node", (t) async {
          final before = FocusNode();
          final nodes = {for (final o in _options) o: FocusNode()};
          addTearDown(before.dispose);
          for (final node in nodes.values) {
            addTearDown(node.dispose);
          }
          await t.pumpWidget(
            _group(
              direction: direction,
              before: before,
              nodes: nodes,
              initial: initial,
              axis: axis,
            ),
          );
          await t.pumpAndSettle();
          for (final o in _options) {
            expect(
              t.widget<TermRadio<String>>(find.byKey(ValueKey(o))).focusNode,
              same(nodes[o]),
            );
          }
          nodes['A']!.requestFocus();
          await t.pump();
          expect(FocusManager.instance.primaryFocus, same(nodes['A']));
          await _checkGroup(t, before);
          // A radio is no button; the one turned off says so.
          for (final o in _options) {
            expect(
              t.getSemantics(find.byKey(ValueKey(o))),
              isSemantics(
                label: o,
                isButton: false,
                isInMutuallyExclusiveGroup: true,
                hasCheckedState: true,
                hasEnabledState: true,
                isEnabled: o != 'B',
                isFocusable: o != 'B',
                hasTapAction: o != 'B',
                hasFocusAction: o != 'B',
              ),
            );
          }
        });
      }
    }
  }

  testWidgets('a radio that holds its own choice is a Tab stop of its own, '
      'and its onChanged null turns it off', (t) async {
    final heard = <String?>[];
    await t.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: TermThemeData.dark(),
          child: Column(
            children: [
              TermRadio<String>(
                value: 'staging',
                groupValue: 'production',
                label: 'staging',
                onChanged: heard.add,
              ),
              const TermRadio<String>(
                value: 'canary',
                groupValue: 'production',
                label: 'canary',
              ),
            ],
          ),
        ),
      ),
    );
    await t.tap(find.text('staging'));
    await t.tap(find.text('canary'));
    await t.pumpAndSettle();
    expect(heard, ['staging']);
    expect(
      t.getSemantics(find.bySemanticsLabel('canary')),
      isSemantics(
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
  });

  testWidgets("a caller's node stays its own as the group rebuilds, takes "
      'a second node, and lets both go', (t) async {
    final before = FocusNode();
    final first = {for (final o in _options) o: FocusNode()};
    final second = FocusNode(debugLabel: 'A again');
    addTearDown(before.dispose);
    addTearDown(second.dispose);
    for (final node in first.values) {
      addTearDown(node.dispose);
    }
    Future<void> pump(Map<String, FocusNode> nodes) async {
      await t.pumpWidget(
        _group(
          direction: TextDirection.ltr,
          before: before,
          nodes: nodes,
          initial: 'C',
        ),
      );
      await t.pumpAndSettle();
    }

    await pump(first);
    first['A']!.requestFocus();
    await t.pump();
    // The same node through a rebuild keeps the focus.
    await pump(first);
    expect(FocusManager.instance.primaryFocus, same(first['A']));

    // A second node for A: the radio takes it, and the first lets go.
    var heard = 0;
    void listen() => heard++;
    second.addListener(listen);
    addTearDown(() => second.removeListener(listen));
    await pump({...first, 'A': second});
    expect(
      t.widget<TermRadio<String>>(find.byKey(const ValueKey('A'))).focusNode,
      same(second),
    );
    second.requestFocus();
    await t.pump();
    expect(FocusManager.instance.primaryFocus, same(second));
    expect(heard, greaterThan(0));
    expect(first['A']!.hasFocus, isFalse);
    await _checkGroup(t, before);

    // With the group gone, every node still works for another focusable
    // (one a turned-off radio held can be focused again where it is wanted).
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            for (final node in [...first.values, second])
              Focus(
                focusNode: node,
                canRequestFocus: true,
                child: const SizedBox(height: 4),
              ),
          ],
        ),
      ),
    );
    for (final node in [...first.values, second]) {
      node.requestFocus();
      await t.pump();
      expect(FocusManager.instance.primaryFocus, same(node));
    }
  });

  // A one-choice segmented control that is never empty is a group of
  // radios too.
  Widget segments({
    required TextDirection direction,
    required FocusNode before,
    required String? initial,
    bool emptySelectionAllowed = false,
    void Function(Set<String>)? onChosen,
  }) {
    var chosen = initial;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TermTheme(
        data: TermThemeData.dark(),
        child: Directionality(
          textDirection: direction,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Focus(focusNode: before, child: const Text('before')),
                TermToggleGroup<String>(
                  key: const ValueKey('radios'),
                  options: _options,
                  selected: {?chosen},
                  isEnabled: (v) => v != 'B',
                  emptySelectionAllowed: emptySelectionAllowed,
                  labelOf: (v) => v,
                  semanticLabel: 'period',
                  onSelectionChanged: (next) {
                    setState(() => chosen = next.firstOrNull);
                    onChosen?.call(next);
                  },
                ),
                const Focus(child: Text('after')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  for (final direction in TextDirection.values) {
    for (final initial in <String?>['C', null, 'B']) {
      testWidgets('one-choice segments, ${direction.name}, chosen $initial: '
          'one Tab stop, arrows choose', (t) async {
        final before = FocusNode();
        addTearDown(before.dispose);
        await t.pumpWidget(
          segments(direction: direction, before: before, initial: initial),
        );
        await t.pumpAndSettle();
        await _checkGroup(t, before);
      });
    }
  }

  for (final axis in Axis.values) {
    for (final direction in TextDirection.values) {
      testWidgets('grouped radios in a ${axis.name} line, ${direction.name}: '
          "a press anywhere in a radio's box chooses it", (t) async {
        final before = FocusNode();
        addTearDown(before.dispose);
        String? chosen = 'C';
        await t.pumpWidget(
          _group(
            direction: direction,
            before: before,
            nodes: const {},
            initial: chosen,
            axis: axis,
            onChosen: (v) => chosen = v,
          ),
        );
        await t.pumpAndSettle();
        await _pressEverywhere(t, () => chosen, const ['A', 'C', 'D']);
      });
    }
  }

  for (final direction in TextDirection.values) {
    testWidgets('one-choice segments, ${direction.name}: a press anywhere in '
        "a segment's box chooses it", (t) async {
      final before = FocusNode();
      addTearDown(before.dispose);
      String? chosen = 'C';
      await t.pumpWidget(
        segments(
          direction: direction,
          before: before,
          initial: chosen,
          onChosen: (next) => chosen = next.firstOrNull,
        ),
      );
      await t.pumpAndSettle();
      await _pressEverywhere(t, () => chosen, const ['A', 'C', 'D']);
    });
  }

  testWidgets('Home and End choose the first and the last segment that can '
      'be chosen', (t) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    final heard = <Set<String>>[];
    await t.pumpWidget(
      segments(
        direction: TextDirection.ltr,
        before: before,
        initial: 'C',
        onChosen: heard.add,
      ),
    );
    await t.pumpAndSettle();
    before.requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.end);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.home);
    await t.pump();
    expect(heard, [
      {'D'},
      {'A'},
    ]);
    expect(
      t.getSemantics(find.bySemanticsLabel('A')),
      isSemantics(isFocused: true, isChecked: true, isButton: false),
    );
  });

  testWidgets('segments a press may empty stay a toggle group', (t) async {
    final before = FocusNode();
    addTearDown(before.dispose);
    final heard = <Set<String>>[];
    await t.pumpWidget(
      segments(
        direction: TextDirection.ltr,
        before: before,
        initial: 'C',
        emptySelectionAllowed: true,
        onChosen: heard.add,
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(RawSegmentedButton<String>), findsOneWidget);
    expect(find.byType(RadioGroup<String>), findsNothing);
    await t.tap(find.text('C'));
    await t.pumpAndSettle();
    expect(heard, [<String>{}]);
  });

  // The gallery's single choices: radios grouped at their owner, the
  // segments of a one-choice toggle group (a RadioGroup when it is never
  // empty).
  bool singleChoice(Widget w) =>
      w is RadioGroup || (w is RawSegmentedButton && !w.multiSelectionEnabled);

  for (final direction in TextDirection.values) {
    testWidgets('every single choice in the gallery, ${direction.name}', (
      t,
    ) async {
      // Tall enough that a page's lazy lists build every choice.
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1440, 8000);
      addTearDown(t.view.reset);
      kitShownDirection = direction;
      addTearDown(() => kitShownDirection = TextDirection.ltr);
      // The gallery's pages hold endless motion (a spinner, a caret): frames
      // enough for a page, a scroll or a move to finish.
      Future<void> settle() async {
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(milliseconds: 50));
        }
      }

      final problems = <String>[];
      final seen = <String>[];
      for (final page in galleryPages) {
        await t.pumpWidget(const SizedBox());
        await t.pumpWidget(page.build(Brightness.dark));
        await settle();
        final count = find.byWidgetPredicate(singleChoice).evaluate().length;
        for (var i = 0; i < count; i++) {
          await t.pumpWidget(const SizedBox());
          await t.pumpWidget(page.build(Brightness.dark));
          await settle();
          final group = find.byWidgetPredicate(singleChoice).at(i);
          final name = '${page.id} #$i (${t.widget(group).runtimeType})';
          // The focusable just before the group: the one a Tab leaves to
          // land in it.
          FocusNode? before;
          for (var tab = 0; tab < 400; tab++) {
            final from = FocusManager.instance.primaryFocus;
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            await t.pump();
            final at = FocusManager.instance.primaryFocus?.context;
            if (at != null &&
                find
                    .descendant(
                      of: group,
                      matching: find.byElementPredicate((e) => e == at),
                    )
                    .evaluate()
                    .isNotEmpty) {
              before = from;
              break;
            }
          }
          if (before == null) {
            problems.add('$name: no Tab reaches it');
            continue;
          }
          seen.add(name);
          final report = await const DesignRadioGroupCheck(look: 'Terminal')
              .check(
                t.element(group),
                before: before,
                sendKeyEvent: t.sendKeyEvent,
                pump: settle,
              );
          problems.addAll([for (final p in report.problems) '$name: $p']);
        }
      }
      await t.pumpWidget(const SizedBox());
      if (!seen.any((s) => s.contains('RadioGroup'))) {
        problems.add('the gallery groups none of its radios');
      }
      expect(problems, isEmpty, reason: 'checked: ${seen.join(', ')}');
    });
  }
}
