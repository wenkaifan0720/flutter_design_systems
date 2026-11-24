// A toast stands above a page's foot (BrutalScreen's footer, on its rule),
// as a Scaffold keeps a snackbar above its persistent footer buttons: on a
// phone "Changes saved" stood over the page's Save.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final width in const [390.0, 900.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('at ${width.round()}, ${direction.name}: a toast stands '
          'above the page foot', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final page = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, navigator) => Directionality(
              textDirection: direction,
              child: BrutalTheme(
                data: BrutalThemeData.light(),
                child: BrutalToaster(child: navigator!),
              ),
            ),
            home: BrutalScreen(
              key: page,
              topBar: const BrutalAppBar(title: 'Task details'),
              footer: BrutalButton.filled('Save changes', onPressed: () {}),
              body: const Text('Proof the studio map'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final save = tester.getRect(find.text('Save changes'));
        final rule = tester.getRect(find.byType(BrutalRule).last);
        expect(rule.bottom, lessThanOrEqualTo(save.top), reason: 'the foot');
        final handle = showBrutalToast(
          page.currentContext!,
          'Changes saved',
          duration: null,
        );
        await tester.pumpAndSettle();
        final toast = tester.getRect(
          find
              .ancestor(
                of: find.text('Changes saved'),
                matching: find.byType(BrutalSurface),
              )
              .first,
        );
        final shadow = BrutalThemeData.light().shadowOffset;
        expect(
          toast.bottom + shadow,
          lessThanOrEqualTo(rule.top),
          reason: 'toast $toast, foot from $rule',
        );
        handle.dismiss();
        await tester.pumpAndSettle();
      });
    }
  }
}
