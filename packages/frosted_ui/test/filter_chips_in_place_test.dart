// Filter chips are separate things, so a choice changes in place (the user, 11-13, on the published gallery: "why does
// the filter also has the selection indicator sliding?"). Through a change of choice nothing in the row travels: every
// box it lays out stands where a box stood at rest, before or after (a plate sliding between the chips would cross the
// gaps). The chip left and the chip chosen each fade their own glass, mid-way at once; the chip between them does not
// change. The segmented control, whose segments share one capsule, still slides its plate.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _words = ['All', 'Money in', 'Money out'];

Future<ValueNotifier<String>> _pump(
  WidgetTester t, {
  double width = 1440,
}) async {
  t.view.physicalSize = Size(width, 400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final value = ValueNotifier('All');
  addTearDown(value.dispose);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          FrostedHost(brightness: Brightness.dark, child: page!),
      home: Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ValueListenableBuilder<String>(
            valueListenable: value,
            builder: (context, chosen, _) => FrostedFilterChipGroup<String>(
              options: [for (final w in _words) FrostedFilterOption(w, w)],
              value: chosen,
              onChanged: (v) => value.value = v,
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return value;
}

/// Every box the row lays out, where it stands on the screen.
Set<Rect> _boxes(WidgetTester t) {
  final out = <Rect>{};
  void visit(RenderObject o) {
    if (o is RenderBox && o.hasSize) {
      out.add(
        MatrixUtils.transformRect(o.getTransformTo(null), Offset.zero & o.size),
      );
    }
    o.visitChildren(visit);
  }

  visit(t.renderObject(find.byType(FrostedFilterChipGroup<String>)));
  return out;
}

/// The fades inside the chip that says [word] standing part of the way
/// between hidden and shown.
List<double> _fading(WidgetTester t, String word) => [
  for (final o in t.renderObjectList<RenderAnimatedOpacity>(
    find.descendant(
      of: find.ancestor(
        of: find.text(word),
        matching: find.byType(FrostedPressable),
      ),
      matching: find.byType(AnimatedOpacity),
    ),
  ))
    if (o.opacity.value > 0 && o.opacity.value < 1) o.opacity.value,
];

void main() {
  for (final width in [1440.0, 390.0]) {
    testWidgets('at $width the chosen face does not move between chips', (
      t,
    ) async {
      final value = await _pump(t, width: width);
      final before = _boxes(t);
      value.value = 'Money out';
      await t.pump();
      final seen = <Set<Rect>>[];
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 10));
        seen.add(_boxes(t));
      }
      await t.pumpAndSettle();
      final after = _boxes(t);
      final travelled = {
        for (final frame in seen)
          for (final r in frame)
            if (!before.contains(r) && !after.contains(r)) r,
      };
      expect(
        travelled,
        isEmpty,
        reason: 'a box in the row stood where no box stands at rest',
      );
    });
  }

  testWidgets('the chip left and the chip chosen fade their own glass; the '
      'chip between them stays', (t) async {
    final value = await _pump(t);
    value.value = 'Money out';
    await t.pump();
    // About half of the change (FrostedMotion.fast, 120 ms).
    await t.pump(const Duration(milliseconds: 60));
    expect(_fading(t, 'All'), isNotEmpty, reason: 'the chip left fades');
    expect(_fading(t, 'Money out'), isNotEmpty, reason: 'the chip fades in');
    expect(_fading(t, 'Money in'), isEmpty, reason: 'nothing crosses it');
    await t.pumpAndSettle();
    expect(_fading(t, 'All'), isEmpty);
    expect(_fading(t, 'Money out'), isEmpty);
  });
}
