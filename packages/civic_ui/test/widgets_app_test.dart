// Civic needs no Material: under a bare WidgetsApp, as the README's first app
// stands, a button presses and its words are Civic's; a page of its parts
// takes typing and a tick, opens a dialog that Escape closes, by day and by
// night, with nothing thrown and no localizations of the app's own.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("the README's app: Civic's theme over a bare WidgetsApp", (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF0F4C81),
        builder: (context, _) => CivicTheme(
          data: CivicThemeData.light(),
          child: CivicScaffold(
            body: CivicButton(
              onPressed: () => pressed++,
              child: const Text('Continue'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final words = DefaultTextStyle.of(tester.element(find.text('Continue')));
    expect(words.style.fontFamily, civicFontFamily('AtkinsonNext'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(pressed, 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'a page of parts under a bare WidgetsApp (${brightness.name})',
      (tester) async {
        var name = '';
        var email = false;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFF0F4C81),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, animation, secondary) => builder(context),
            ),
            builder: (context, navigator) => CivicTheme(
              data: brightness == Brightness.light
                  ? CivicThemeData.light()
                  : CivicThemeData.dark(),
              child: navigator!,
            ),
            home: StatefulBuilder(
              builder: (context, setState) => CivicScaffold(
                body: CivicPageBody(
                  title: 'Your details',
                  children: [
                    CivicTextField(
                      labelText: 'Full name',
                      onChanged: (v) => name = v,
                    ),
                    CivicCheckbox(
                      value: email,
                      labelText: 'Email me a copy',
                      onChanged: (v) => setState(() => email = v ?? false),
                    ),
                    CivicButton(
                      onPressed: () => showCivicDialog<void>(
                        context: context,
                        builder: (context) => CivicDialog(
                          title: 'Send your application?',
                          content: const Text('You cannot change it after.'),
                          actions: [
                            CivicButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Send'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), 'Amara Okafor');
        await tester.pumpAndSettle();
        expect(name, 'Amara Okafor');
        await tester.tap(find.text('Email me a copy'));
        await tester.pumpAndSettle();
        expect(email, isTrue);
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Send your application?'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Send your application?'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
