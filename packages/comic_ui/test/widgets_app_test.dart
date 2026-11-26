// Comic needs no Material app: under a bare WidgetsApp, as the README's first app stands, a button presses; a page of
// its parts takes typing and a tick, opens a dialog that Escape closes, by day and by night, with nothing thrown and no
// localizations of the app's own.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart' show loadComicFonts;

void main() {
  setUpAll(loadComicFonts);
  testWidgets("the README's app: Comic's theme over a bare WidgetsApp", (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFF3E92),
        builder: (context, _) => ComicTheme(
          data: ComicThemeData.offset(),
          child: ComicScaffold(
            body: Center(
              child: ComicButton.filled('Read on', onPressed: () => pressed++),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('READ ON'));
    await tester.pumpAndSettle();
    expect(pressed, 1);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'a page of parts under a bare WidgetsApp (${brightness.name})',
      (tester) async {
        var name = '';
        var copy = false;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFFFF3E92),
            pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, animation, secondary) => builder(context),
            ),
            builder: (context, navigator) => ComicTheme(
              data: ComicThemeData.offset(brightness),
              child: navigator!,
            ),
            home: StatefulBuilder(
              builder: (context, setState) => ComicScaffold(
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ComicTextField(
                      labelText: 'Your name',
                      onChanged: (v) => name = v,
                    ),
                    ComicCheckbox(
                      value: copy,
                      label: 'Send me a copy',
                      onChanged: (v) => setState(() => copy = v ?? false),
                    ),
                    ComicButton.filled(
                      'Send',
                      onPressed: () => showComicDialog<void>(
                        context,
                        builder: (context) => ComicDialog(
                          title: 'Send the letter?',
                          message: 'It goes out with the next issue.',
                          actions: [
                            ComicButton.filled(
                              'Send it',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
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
        await tester.tap(find.byType(ComicCheckbox));
        await tester.pumpAndSettle();
        expect(copy, isTrue);
        await tester.tap(find.text('SEND'));
        await tester.pumpAndSettle();
        expect(find.text('Send the letter?'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Send the letter?'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
