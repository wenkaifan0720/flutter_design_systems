// In one form every label starts on one line: a field around a segmented
// choice, a slider or a switch sets its label, help and error where a text
// field sets its own, and the help under a slider stands there too. They
// started at the control's edge, a column of their own 16 px out.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a form field\'s label and help line up with a text '
        'field\'s (${direction.name})', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final home = ClayScreen(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ClayTextField(labelText: 'Title', helperText: 'As printed'),
            const SizedBox(height: 16),
            ClayFormField(
              labelText: 'Status',
              errorText: 'Pick one',
              child: ClaySegmentedButton<String>(
                segments: const [
                  ClaySegment(value: 'read', label: 'Read'),
                  ClaySegment(value: 'done', label: 'Done'),
                ],
                selected: 'read',
                onChanged: (_) {},
              ),
            ),
            const SizedBox(height: 16),
            ClayFormField(
              labelText: 'Text size',
              helperText: '100%',
              child: ClaySlider(value: 1, min: 0.8, max: 2, onChanged: (_) {}),
            ),
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ClayTheme(
            data: ClayThemeData.clay(Brightness.light),
            child: ClayToaster(child: app!),
          ),
          home: Directionality(textDirection: direction, child: home),
        ),
      );
      await tester.pumpAndSettle();
      final rtl = direction == TextDirection.rtl;
      double start(String text) {
        final r = tester.getRect(find.text(text));
        return rtl ? r.right : r.left;
      }

      for (final words in ['Status', 'Text size']) {
        expect(
          start(words),
          moreOrLessEquals(start('Title'), epsilon: 0.5),
          reason: '"$words" starts off the form\'s label line',
        );
      }
      for (final words in ['Pick one', '100%']) {
        expect(
          start(words),
          moreOrLessEquals(start('As printed'), epsilon: 0.5),
          reason: '"$words" starts off the form\'s help line',
        );
      }
    });
  }
}
