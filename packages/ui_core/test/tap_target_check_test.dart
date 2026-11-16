import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

// A 32 pt face that widens its own hit test to 44 pt, as Ledger's hit slop
// does: inside a parent as tight as the face, a tap reaches 32 pt.
class _Slop extends SingleChildRenderObjectWidget {
  const _Slop({required this.label, this.outline = 44, super.child});

  final String label;
  final double outline;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSlop(label, outline);
}

class _RenderSlop extends RenderProxyBox {
  _RenderSlop(this.label, this.outline);

  final String label;
  final double outline;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final pad = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: outline,
      height: outline,
    );
    if (!pad.contains(position)) return false;
    // A tap in the slop goes to the face at its nearest point.
    final inside = Offset(
      position.dx.clamp(0, size.width - .01),
      position.dy.clamp(0, size.height - .01),
    );
    child!.hitTest(result, position: inside);
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isButton = true
      ..label = label
      ..textDirection = TextDirection.ltr
      ..onTap = () {};
  }

  @override
  Rect get semanticBounds => Rect.fromCenter(
    center: size.center(Offset.zero),
    width: outline,
    height: outline,
  );
}

Widget _button(
  String label, {
  double size = 32,
  bool slop = false,
  double outline = 44,
}) {
  final face = GestureDetector(
    onTap: () {},
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: slop,
    child: SizedBox.square(dimension: size),
  );
  if (slop) return _Slop(label: label, outline: outline, child: face);
  return Semantics(button: true, label: label, child: face);
}

Future<DesignAlignmentReport> _check(
  WidgetTester tester,
  Widget row, {
  DesignInput? input,
  DesignTapTargets? targets,
}) async {
  final semantics = tester.ensureSemantics();
  Widget page = Directionality(
    textDirection: TextDirection.ltr,
    child: Center(key: const Key('page'), child: row),
  );
  if (targets != null) {
    page = DesignTapTargetScope(targets: targets, child: page);
  }
  await tester.pumpWidget(page);
  final report = DesignTapTargetCheck(
    look: 'Test',
    input: input,
  ).check(tester.element(find.byKey(const Key('page'))));
  semantics.dispose();
  return report;
}

void main() {
  testWidgets('a hit slop a tight row cuts is named', (tester) async {
    // A 32 pt row, as tall as the face: the slop's 44 pt never takes a tap.
    final report = await _check(
      tester,
      SizedBox(height: 32, child: _button('Add', slop: true)),
    );
    expect(report.problems, hasLength(1));
    expect(
      report.problems.single,
      allOf(
        contains('a button "Add"'),
        contains('a tap reaches it over'),
        contains('under the 44 × 44 a finger needs'),
        contains('a screen reader outlines 44 × 44'),
      ),
    );
    expect(report.verify, throwsA(isA<DesignAlignmentError>()));
  });

  testWidgets('a hit slop with room round it passes', (tester) async {
    final report = await _check(
      tester,
      SizedBox.square(
        dimension: 44,
        child: Center(child: _button('Add', slop: true)),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a target laid out at the floor passes', (tester) async {
    final report = await _check(tester, _button('Add', size: 44));
    expect(report.problems, isEmpty);
  });

  testWidgets('a target smaller than the floor is named', (tester) async {
    final report = await _check(tester, _button('Add', size: 24));
    expect(report.problems.single, contains('a tap reaches it over 24 × 24'));
  });

  testWidgets('it asks for semantics', semanticsEnabled: false, (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(key: const Key('page'), child: _button('Add')),
      ),
    );
    expect(
      () =>
          const DesignTapTargetCheck(look: 'Test')
              .check(tester.element(find.byKey(const Key('page')))),
      throwsStateError,
    );
  });

  testWidgets('a part a larger control takes taps for passes', (tester) async {
    // A clock dial's hours: each one a button to a screen reader, the dial
    // takes the tap.
    final report = await _check(
      tester,
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (_) {},
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            children: [
              for (final (i, at) in const [
                (12, Offset(100, 0)),
                (3, Offset(200, 100)),
                (6, Offset(100, 200)),
              ].indexed)
                Positioned(
                  left: at.$2.dx,
                  top: at.$2.dy,
                  child: Semantics(
                    button: true,
                    label: '${at.$1} o\'clock $i',
                    onTap: () {},
                    child: const SizedBox(width: 40, height: 40),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a pointer is held to its own floor, a finger to its', (
    tester,
  ) async {
    // A 32 pt button: room for a pointer (24), short of a finger (44).
    final pointer = await _check(
      tester,
      _button('Add'),
      input: DesignInput.pointer,
    );
    expect(pointer.problems, isEmpty);
    final touch = await _check(tester, _button('Add'));
    expect(touch.problems.single, contains('under the 44 × 44 a finger needs'));
    final small = await _check(
      tester,
      _button('Add', size: 16),
      input: DesignInput.pointer,
    );
    expect(
      small.problems.single,
      contains('under the 24 × 24 a pointer needs'),
    );
  });

  testWidgets("the look's declared floor is the one held", (tester) async {
    final report = await _check(
      tester,
      _button('Add', size: 44),
      targets: const DesignTapTargets(touch: Size.square(48)),
    );
    expect(report.problems.single, contains('under the 48 × 48 a finger'));
  });

  testWidgets('a screen reader outlines what a tap reaches, at any floor', (
    tester,
  ) async {
    // A 46 pt face in a 46 pt row: over the floor, but a screen reader
    // outlines 56.
    final report = await _check(
      tester,
      SizedBox(
        height: 46,
        child: _button('Add', size: 46, slop: true, outline: 56),
      ),
      input: DesignInput.pointer,
    );
    expect(
      report.problems.single,
      allOf(
        contains('a screen reader outlines 56 × 56'),
        contains('the box a screen reader outlines is the box a tap reaches'),
      ),
    );
  });

  testWidgets('a control laid out by DesignTapTarget passes', (tester) async {
    final report = await _check(
      tester,
      DesignTapTarget(
        child: Semantics(
          button: true,
          label: 'Add',
          child: GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.square(dimension: 24),
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  for (final alignment in const [
    AlignmentDirectional.centerStart,
    AlignmentDirectional.centerEnd,
  ]) {
    testWidgets('a face on its target\'s $alignment edge passes: the target '
        'is the reach, whichever way it grows', (tester) async {
      final report = await _check(
        tester,
        SizedBox(
          width: 200,
          child: Align(
            alignment: alignment,
            child: Semantics(
              button: true,
              label: 'Paid',
              child: DesignTapTarget(
                alignment: alignment,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: const SizedBox.square(dimension: 24),
                ),
              ),
            ),
          ),
        ),
      );
      expect(report.problems, isEmpty);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('a face whose reach stands to one side is read over all of '
        'it ($direction)', (tester) async {
      // Minimal's checkbox: a 16 pt face on its reach's start edge, the
      // reach 44 pt, all its room toward the end.
      final report = await _check(
        tester,
        Directionality(
          textDirection: direction,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                end: 28,
                top: 14,
                bottom: 14,
              ),
              child: Semantics(
                container: true,
                checked: true,
                label: 'Done',
                onTap: () {},
                child: const SizedBox.square(dimension: 16),
              ),
            ),
          ),
        ),
      );
      expect(report.problems, isEmpty);
    });
  }

  testWidgets('a link in a sentence is set by its line', (tester) async {
    // WCAG 2.2's 2.5.8 exempts a target in a sentence: its line cannot grow.
    final terms = TapGestureRecognizer()..onTap = () {};
    addTearDown(terms.dispose);
    final report = await _check(
      tester,
      SizedBox(
        width: 300,
        child: Text.rich(
          TextSpan(
            text: 'By going on you agree to the ',
            children: [
              TextSpan(text: 'terms', recognizer: terms),
              const TextSpan(text: ' of the shop.'),
            ],
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a link that is its whole text is held to the floor', (
    tester,
  ) async {
    final terms = TapGestureRecognizer()..onTap = () {};
    addTearDown(terms.dispose);
    final report = await _check(
      tester,
      Text.rich(TextSpan(text: 'Terms', recognizer: terms)),
    );
    expect(
      report.problems.single,
      allOf(contains('"Terms"'), contains('under the 44 × 44 a finger needs')),
    );
  });

  testWidgets('a link set as a widget in a sentence is set by its line', (
    tester,
  ) async {
    // Expressive's links are WidgetSpans, to keep focus and state layers.
    final report = await _check(
      tester,
      SizedBox(
        width: 300,
        child: Text.rich(
          TextSpan(
            text: 'Read the ',
            children: [
              WidgetSpan(child: _widgetLink('house rules')),
              const TextSpan(text: ' before you book.'),
            ],
          ),
        ),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a link set as a widget that is its whole text is held to the '
      'floor', (tester) async {
    final report = await _check(
      tester,
      Text.rich(TextSpan(children: [WidgetSpan(child: _widgetLink('Terms'))])),
    );
    expect(
      report.problems.single,
      allOf(contains('"Terms"'), contains('under the 44 × 44 a finger needs')),
    );
  });

  testWidgets('a chip scrolled half out of its row is read by what shows', (
    tester,
  ) async {
    // Expressive's filter chips: a 48 pt tap round a 32 pt face, in a row
    // that scrolls across. "Classical" shows 6 pt at the row's end, and a
    // tap on that slice reaches it: a sliver at a scroll edge is scrolling.
    final report = await _check(tester, _chipRow(face: 32, tap: 48));
    expect(report.problems, isEmpty);
  });

  testWidgets('a chip a scroll edge cuts is still held to the floor across '
      'the cut', (tester) async {
    final report = await _check(tester, _chipRow(face: 30));
    expect(report.problems, hasLength(3));
    expect(
      report.problems.last,
      allOf(contains('"Classical"'), contains('under the 44 × 44')),
    );
  });

  testWidgets('a field whose ground focuses it on a press off its words '
      'reaches over its ground', (tester) async {
    // Neumorphism's seat: a 48 pt band behind a 22 pt line of words.
    final report = await _check(tester, const _SeatedField(_Ground.field));
    expect(report.problems, isEmpty);
  });

  testWidgets('a key whose node is the field\'s own child is part of it: '
      'behind its words, or at its end, as Neumorphism\'s clear key', (
    tester,
  ) async {
    expect(
      (await _check(tester, const _SeatedField(_Ground.key))).problems,
      isNot(contains(startsWith('a text field "Room"'))),
    );
    // A 350 pt field, its words over 302 pt, its 48 pt key at its end.
    for (final direction in TextDirection.values) {
      final report = await _check(
        tester,
        Directionality(textDirection: direction, child: const _EndKeyField()),
      );
      expect(report.problems, isEmpty, reason: '$direction');
    }
  });

  testWidgets('a field whose ground does nothing, or is a key beside the '
      'field\'s node, reaches over its line', (tester) async {
    for (final ground in [_Ground.none, _Ground.keyBeside]) {
      final report = await _check(tester, _SeatedField(ground));
      expect(
        report.problems,
        contains(
          allOf(
            startsWith('a text field "Room"'),
            contains('a tap reaches it over 310 × 22'),
          ),
        ),
        reason: '$ground',
      );
    }
  });
}

// Three chips, [face] pt high and 179 wide, a 48 pt [tap] round each when
// given, in a 380 pt row that scrolls across: the third shows 6 pt.
Widget _chipRow({required double face, double? tap}) => SizedBox(
  width: 380,
  height: 48,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
      for (final name in const ['Jazz', 'Folk', 'Classical'])
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Center(
            child: Semantics(
              container: true,
              button: true,
              label: name,
              child: _tapRound(
                tap,
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: SizedBox(width: 179, height: face),
                ),
              ),
            ),
          ),
        ),
    ],
  ),
);

Widget _tapRound(double? tap, Widget chip) => tap == null
    ? chip
    : DesignTapTarget(minSize: Size.square(tap), child: chip);

// A link set as a widget: its own node, a tap on its words.
Widget _widgetLink(String words) => Semantics(
  link: true,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {},
    child: Text(words),
  ),
);

// What stands behind a seated field's line of words: nothing that acts, a
// handler of the field's own that focuses it, a key with a node of its own
// inside the field's node, or one whose node is beside the field's.
enum _Ground { none, field, key, keyBeside }

// A 310 pt field: one line of words in a 48 pt band, [ground] behind it.
class _SeatedField extends StatefulWidget {
  const _SeatedField(this.ground);

  final _Ground ground;

  @override
  State<_SeatedField> createState() => _SeatedFieldState();
}

class _SeatedFieldState extends State<_SeatedField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ground = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: switch (widget.ground) {
        _Ground.none => null,
        _Ground.field => _focus.requestFocus,
        _Ground.key || _Ground.keyBeside => _controller.clear,
      },
    );
    final key = Semantics(
      container: true,
      button: true,
      label: 'Clear',
      onTap: _controller.clear,
      child: ground,
    );
    final line = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        heightFactor: 1,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          style: const TextStyle(fontSize: 16, height: 22 / 16),
          decoration: const InputDecoration.collapsed(hintText: null),
        ),
      ),
    );
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            width: 310,
            child: widget.ground == _Ground.keyBeside
                ? Stack(
                    children: [
                      Positioned.fill(child: key),
                      Semantics(container: true, label: 'Room', child: line),
                    ],
                  )
                : Semantics(
                    container: true,
                    label: 'Room',
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: widget.ground == _Ground.key ? key : ground,
                        ),
                        line,
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// A 350 pt search field: its words a 302 x 48 TextField, a 48 pt clear key
// at its end whose node is the field's child.
class _EndKeyField extends StatefulWidget {
  const _EndKeyField();

  @override
  State<_EndKeyField> createState() => _EndKeyFieldState();
}

class _EndKeyFieldState extends State<_EndKeyField> {
  final _controller = TextEditingController(text: 'lamp');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Localizations(
    locale: const Locale('en'),
    delegates: const [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 350,
          height: 48,
          child: Semantics(
            container: true,
            label: 'Search',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 16, height: 22 / 16),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                Semantics(
                  container: true,
                  button: true,
                  label: 'Clear',
                  onTap: _controller.clear,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: _controller.clear,
                    child: const SizedBox.square(dimension: 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
