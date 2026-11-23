// A combobox's text input says whether its list is open: expanded while it shows, collapsed once Escape closes it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

Widget _host(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      RetroDesktopHost(brightness: Brightness.light, child: app!),
  home: home,
);

void _expectExpanded(WidgetTester tester, bool open) => expect(
  tester.getSemantics(find.byType(EditableText)),
  isSemantics(isTextField: true, hasExpandedState: true, isExpanded: open),
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in RetroDesktopAppearance.values) {
    testWidgets(
      'a ${appearance.name} combobox says on its text input whether its list is open',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            RetroDesktopTheme(
              data: RetroDesktopThemeData.classic().copyWith(
                appearance: appearance,
              ),
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: RetroDesktopCombobox<String>(
                    labelText: 'Folder',
                    options: const ['Documents', 'Pictures'],
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        _expectExpanded(tester, false);
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'P');
        await tester.pumpAndSettle();
        expect(find.text('Pictures'), findsOneWidget);
        _expectExpanded(tester, true);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Pictures'), findsNothing);
        _expectExpanded(tester, false);
        semantics.dispose();
      },
    );
  }
}
