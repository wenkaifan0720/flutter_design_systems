// Brutal stands on ui_core's 40 touch floor: a finger's target is 40 by 40
// (it was 48), and the parts that stood on the old floor (a slider's height
// and thumb, a calendar's day, a tag's remove key) stand on the new one, the
// same height under a pointer, as they were.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 358,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => BrutalTheme(
        data: BrutalThemeData.light(),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SizedBox(
              width: width,
              // A tag input's entry takes focus under a press: its selection
              // stands in an overlay.
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) =>
                        Align(alignment: Alignment.topCenter, child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test("the finger's floor is 40, the pointer's 24", () {
    expect(BrutalTheme.tapTargets.touch, const Size(40, 40));
    expect(BrutalTheme.tapTargets.pointer, const Size(24, 24));
    expect(BrutalChromeMetrics.touchTarget, 40);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    testWidgets('a slider stands 40 tall (${platform.name})', (tester) async {
      await _pump(
        tester,
        BrutalSlider(value: .4, onChanged: (_) {}, semanticLabel: 'Volume'),
      );
      expect(tester.getSize(find.byType(BrutalSlider)).height, 40);
    }, variant: TargetPlatformVariant.only(platform));

    testWidgets('a range slider\'s thumbs stand 40 tall (${platform.name})', (
      tester,
    ) async {
      await _pump(
        tester,
        BrutalRangeSlider(
          values: const BrutalRangeValues(.2, .6),
          onChanged: (_) {},
          startLabel: 'From',
          endLabel: 'To',
        ),
      );
      expect(tester.getSize(find.byType(BrutalRangeSlider)).height, 40);
    }, variant: TargetPlatformVariant.only(platform));
  }

  testWidgets("a tag's remove key is the finger's 40 square, reached above "
      'and below the tag', (tester) async {
    final semantics = tester.ensureSemantics();
    var values = const ['Choral', 'Organ'];
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => BrutalTagInput<String>(
          labelText: 'Kinds',
          values: values,
          options: const ['Jazz', 'Folk', 'Choral', 'Organ'],
          displayStringForOption: (v) => v,
          onChanged: (v) => setState(() => values = v),
        ),
      ),
      width: 260,
    );
    final cross = tester.getRect(find.bySemanticsLabel('Remove Organ'));
    expect(cross.size, const Size(40, 40));
    // The target merges nothing: a screen reader hears the tag's words, and
    // its Remove button, as two.
    final words = tester.getSemantics(find.text('Organ')).getSemanticsData();
    expect(words.label, 'Organ');
    expect(words.hasAction(SemanticsAction.tap), isFalse);
    final face = tester.getRect(
      find
          .ancestor(
            of: find.text('Organ'),
            matching: find.byType(AnimatedBrutalSurface),
          )
          .first,
    );
    // Above the face, over the label: the words take no press.
    await tester.tapAt(Offset(face.left + 6, face.top - 4));
    await tester.pumpAndSettle();
    expect(values, const ['Choral', 'Organ']);
    // Above the face, over the cross: the tag goes.
    await tester.tapAt(Offset(cross.center.dx, face.top - 4));
    await tester.pumpAndSettle();
    expect(values, const ['Choral']);
    semantics.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
