// A toast stands above a page's action foot (CivicPageBody's action in an
// app-sized window), as a Scaffold keeps a snackbar above its persistent
// footer buttons: on a 900 window "Changes saved" covered the page's Save.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final width in [390.0, 900.0]) {
    testWidgets('at ${width.round()} a toast stands above the page foot', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final page = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, navigator) => CivicTheme(
            data: CivicThemeData.light(),
            child: CivicToaster(child: navigator!),
          ),
          home: CivicPageBody(
            key: page,
            title: 'Task',
            action: CivicButton(onPressed: () {}, child: const Text('Save')),
            children: const [Text('Details')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      CivicToast.show(page.currentContext!, 'Changes saved');
      await tester.pumpAndSettle();
      final save = tester.getRect(find.widgetWithText(CivicButton, 'Save'));
      final toast = tester.getRect(find.text('Changes saved'));
      expect(toast.bottom, lessThanOrEqualTo(save.top), reason: '$toast $save');
      // Let the toast's time run out.
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
    });
  }
}
