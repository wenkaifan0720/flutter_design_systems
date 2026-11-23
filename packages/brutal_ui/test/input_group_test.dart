// An input group's add-on cells keep their words on one line while the entry
// keeps at least a quarter of the box to type in; only when one line would
// leave it less (large text on a phone) does each cell take at most a quarter
// and wrap its words there.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, double textScale) async {
  // The look's own faces, as an app loads them: the test font's square
  // letters are far wider than any real word.
  await tester.runAsync(brutalLoadFonts);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: BrutalHost(theme: BrutalThemeData.light(), child: child!),
      ),
      home: const Padding(
        padding: EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: BrutalInputGroup(
            labelText: 'Your page',
            before: 'https://',
            after: '.admit.events',
            hintText: 'your-night',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('on a phone at 1x the add-ons keep one line', (tester) async {
    await _pump(tester, 1);
    final before = tester.getSize(find.text('https://'));
    final after = tester.getSize(find.text('.admit.events'));
    expect(after.height, before.height);
  });

  testWidgets('under twice the text the entry keeps room to type', (
    tester,
  ) async {
    await _pump(tester, 2);
    expect(tester.takeException(), isNull);
    final box = tester.getSize(find.byType(BrutalInputGroup)).width;
    final entry = tester.getSize(find.byType(EditableText)).width;
    expect(entry, greaterThanOrEqualTo(box / 4));
  });
}
