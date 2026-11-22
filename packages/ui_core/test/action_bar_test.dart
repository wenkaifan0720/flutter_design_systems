import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// An action [width] wide (its content's own width) and 44 high, a box a
// test finds by its label.
Widget _action(String label, {double width = 80}) =>
    SizedBox(key: ValueKey(label), width: width, height: 44);

// A bar of [labels] [width] wide.
Widget _bar(
  List<String> labels, {
  double width = 400,
  bool expanded = false,
  MainAxisAlignment alignment = MainAxisAlignment.end,
  Map<String, double> widths = const {},
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  ValueChanged<bool>? onStackedChanged,
}) => harness(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      child: RawActionBar(
        expanded: expanded,
        alignment: alignment,
        onStackedChanged: onStackedChanged,
        children: [for (final l in labels) _action(l, width: widths[l] ?? 80)],
      ),
    ),
  ),
  textDirection: direction,
  textScale: textScale,
);

void main() {
  Rect box(WidgetTester tester, String label) =>
      tester.getRect(find.byKey(ValueKey(label)));

  testWidgets('side by side at the end while they fit, first given at the '
      'start', (tester) async {
    await tester.pumpWidget(_bar(['Cancel', 'Discard', 'Save']));
    final cancel = box(tester, 'Cancel');
    final discard = box(tester, 'Discard');
    final save = box(tester, 'Save');
    expect({cancel.top, discard.top, save.top}, {0.0}, reason: 'one row');
    expect(save.right, 400, reason: 'at the end');
    expect(discard.right, save.left - 8);
    expect(cancel.right, discard.left - 8);
    expect(cancel.width, 80, reason: 'each at its own width');
  });

  testWidgets('right to left, the row is mirrored: the first given stands '
      'at the right, the confirming one at the left', (tester) async {
    await tester.pumpWidget(
      _bar(['Cancel', 'Save'], direction: TextDirection.rtl),
    );
    final cancel = box(tester, 'Cancel');
    final save = box(tester, 'Save');
    expect(save.left, 0, reason: 'the end is the left');
    expect(cancel.left, save.right + 8);
  });

  testWidgets('expanded, side-by-side actions share the row equally', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bar(['Cancel', 'Save'], expanded: true, widths: {'Save': 120}),
    );
    final cancel = box(tester, 'Cancel');
    final save = box(tester, 'Save');
    expect(cancel.width, (400 - 8) / 2);
    expect(save.width, (400 - 8) / 2);
    expect(cancel.left, 0);
    expect(save.right, 400);
  });

  testWidgets('when they do not fit they stack in one column, each as wide '
      'as the bar, the confirming one on top', (tester) async {
    bool? stacked;
    await tester.pumpWidget(
      _bar(
        ['Cancel', 'Discard', 'Save changes'],
        width: 300,
        widths: {'Save changes': 160},
        onStackedChanged: (s) => stacked = s,
      ),
    );
    await tester.pump();
    final cancel = box(tester, 'Cancel');
    final discard = box(tester, 'Discard');
    final save = box(tester, 'Save changes');
    expect(
      {cancel.width, discard.width, save.width},
      {300.0},
      reason: 'one column, one width: no ragged stack',
    );
    expect(save.top, 0, reason: 'the confirming one on top');
    expect(discard.top, save.bottom + 8);
    expect(cancel.top, discard.bottom + 8, reason: 'the dismissive one last');
    expect(stacked, isTrue);
  });

  testWidgets('never two on a line and one under them: three that do not fit '
      'all stack', (tester) async {
    // Two of the three would fit (80 + 8 + 80), three do not.
    await tester.pumpWidget(_bar(['A', 'B', 'C'], width: 200));
    final tops = {
      for (final l in ['A', 'B', 'C']) box(tester, l).top,
    };
    expect(tops.length, 3, reason: 'each on a line of its own');
  });

  testWidgets('at 2x text, words that fit at 1x stack', (tester) async {
    Widget bar(double scale) => harness(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 300,
          child: RawActionBar(
            children: [
              for (final l in ['Keep editing', 'Discard'])
                Text(l, key: ValueKey(l), style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
      textScale: scale,
    );
    await tester.pumpWidget(bar(1));
    expect(box(tester, 'Keep editing').top, box(tester, 'Discard').top);
    await tester.pumpWidget(bar(2));
    expect(
      box(tester, 'Discard').bottom,
      lessThanOrEqualTo(box(tester, 'Keep editing').top),
    );
    expect(box(tester, 'Discard').width, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it answers intrinsic and dry layout as it lays out', (
    tester,
  ) async {
    await tester.pumpWidget(_bar(['No', 'Yes'], widths: {'Yes': 100}));
    final render = tester.renderObject<RenderBox>(find.byType(RawActionBar));
    expect(render.getMaxIntrinsicWidth(double.infinity), 80 + 8 + 100);
    expect(render.getMinIntrinsicWidth(double.infinity), 100);
    expect(render.getMinIntrinsicHeight(400), 44);
    expect(render.getMaxIntrinsicHeight(150), 44 + 8 + 44, reason: 'stacked');
    expect(render.getDryLayout(const BoxConstraints(maxWidth: 400)).height, 44);
    expect(render.getDryLayout(const BoxConstraints(maxWidth: 150)).height, 96);
    expect(render.getDryLayout(const BoxConstraints(maxWidth: 150)).width, 150);
  });

  testWidgets('expanded, it stacks once the widest no longer fits its share', (
    tester,
  ) async {
    // 120 x 2 + 8 = 248 > 240: the share is too narrow for the widest.
    await tester.pumpWidget(
      _bar(['No', 'Yes'], width: 240, expanded: true, widths: {'Yes': 120}),
    );
    expect(box(tester, 'Yes').bottom, lessThanOrEqualTo(box(tester, 'No').top));
  });

  testWidgets('each action keeps its own node; the stack reads top down', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 120,
            child: RawActionBar(
              children: [
                for (final l in ['Cancel', 'Delete'])
                  Semantics(
                    button: true,
                    label: l,
                    child: SizedBox(width: 100, height: 44, key: ValueKey(l)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete'), findsOneWidget);
    expect(box(tester, 'Delete').top, 0, reason: 'stacked, Delete on top');
    semantics.dispose();
  });

  test('its properties for the inspector', () {
    const bar = RawActionBar(
      spacing: 12,
      overflowSpacing: 4,
      expanded: true,
      children: [SizedBox()],
    );
    final text = bar.toDiagnosticsNode().toStringDeep();
    expect(text, contains('spacing: 12.0'));
    expect(text, contains('overflowSpacing: 4.0'));
    expect(text, contains('expanded'));
  });
}
