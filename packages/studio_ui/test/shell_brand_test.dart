// On a wide screen the app's name at the head of the side panel sits on the
// line of the page title beside it.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:studio_ui/studio_ui.dart';

void main() {
  setUpAll(studioLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('the brand sits on the title\'s line at 1440 in '
        '${direction.name}', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(1440 * 2, 900 * 2);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => Directionality(
            textDirection: direction,
            child: StudioHost(brightness: Brightness.light, child: app!),
          ),
          home: StudioAppShell(
            brand: 'Stint',
            tabs: const [
              StudioTab(LucideIcons.house, 'Home'),
              StudioTab(LucideIcons.listTodo, 'Tasks'),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
            child: const StudioScreen(
              topBar: StudioAppBar(title: 'Today'),
              body: Text('Up next'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final brand = tester.getRect(find.text('Stint'));
      final title = tester.getRect(find.text('Today'));
      expect(brand.center.dy, moreOrLessEquals(title.center.dy, epsilon: 1));
    });
  }
}
