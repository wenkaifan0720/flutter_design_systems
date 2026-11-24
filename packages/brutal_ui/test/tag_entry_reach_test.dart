// A tag input's entry keeps the look's tap floor when the tags push it to a
// line of its own: its node stood 46 under a finger's 48, held off the tags
// above it and the box's rule under it.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  List<String> values, {
  double width = 260,
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
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: width,
              child: BrutalTagInput<String>(
                labelText: 'Kinds',
                values: values,
                options: const ['Jazz', 'Folk', 'Choral', 'Organ', 'Brass'],
                displayStringForOption: (v) => v,
                onChanged: (_) {},
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
  testWidgets('under two tags, each a line, the entry on a line of its own '
      'reaches 48', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, const ['Choral', 'Organ']);
    final entry = tester.getSemantics(find.byType(EditableText));
    final tag = tester.getRect(find.text('Organ'));
    final box = tester.getRect(find.byType(EditableText));
    // The tags stand above it: it is on a line of its own.
    expect(box.top, greaterThan(tag.bottom));
    expect(entry.rect.height, greaterThanOrEqualTo(48));
    semantics.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('with no tags the box stays one control tall', (tester) async {
    await _pump(tester, const []);
    final theme = BrutalThemeData.light();
    expect(
      tester.getSize(find.byType(EditableText)).height,
      lessThanOrEqualTo(theme.controlHeight),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
