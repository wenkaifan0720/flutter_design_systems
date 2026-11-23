// A select's list is plastic from its first frame: as it starts to open, the
// keys under it never show through its rows. Before, it faded in over about
// 60 ms, the field below it showing through its words.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, MaterialApp;

/// How much of [of] shows: the product of the opacities above it.
double _shown(WidgetTester tester, Finder of) {
  var shown = 1.0;
  for (final o in tester.widgetList<Opacity>(
    find.ancestor(of: of, matching: find.byType(Opacity)),
  )) {
    shown *= o.opacity;
  }
  return shown;
}

void main() {
  setUpAll(keycapLoadFonts);

  testWidgets("a select's list is opaque from its first frame", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        builder: (context, app) =>
            KeycapHost(brightness: Brightness.light, child: app!),
        home: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeycapSelect<String>(
                labelText: 'Folder',
                value: 'Work',
                items: const [
                  KeycapSelectItem(value: 'Work', label: 'Work'),
                  KeycapSelectItem(value: 'Home', label: 'Home'),
                  KeycapSelectItem(value: 'Ideas', label: 'Ideas'),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 24),
              const KeycapTextField(labelText: 'Notes'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Work'));
    // The list's first frame and its second, 16 ms into the spring.
    for (var i = 0; i < 2; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Home'), findsOneWidget, reason: 'the list is open');
      expect(_shown(tester, find.text('Home')), greaterThan(0.99));
    }
    await tester.pumpAndSettle();
  });
}
