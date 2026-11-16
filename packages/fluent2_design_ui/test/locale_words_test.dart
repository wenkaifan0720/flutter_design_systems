// The published package's words for the machinery under the look in any
// language (its own copy of internal/platform_words.dart): an app that gives
// no Material or Cupertino words gets material_ui's and cupertino_ui's own
// translations where they have its language, and English where they do not.
// A field's selection menu reads them on a phone of each platform.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;

/// An app in [locale] with ui_core's and Fluent 2's words alone, a field on
/// its one page.
Widget _app(Locale locale) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: [locale],
  localizationsDelegates: const [
    DesignLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => Fluent2Host(child: child!),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => Center(
      child: SizedBox(
        width: 320,
        child: Fluent2TextField(value: '', label: 'Name', onChanged: (_) {}),
      ),
    ),
  ),
);

void main() {
  const platforms = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });

  for (final (language, copy) in const [
    ('de', 'Kopieren'),
    ('ar', 'نسخ'),
    // A language neither library has: English.
    ('tlh', 'Copy'),
  ]) {
    testWidgets(
      'a field reads "$copy" for copy in $language',
      variant: platforms,
      (tester) async {
        await tester.pumpWidget(_app(Locale(language)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final field = find.byType(EditableText);
        final context = tester.element(field);
        expect(MaterialLocalizations.of(context).copyButtonLabel, copy);
        expect(CupertinoLocalizations.of(context).copyButtonLabel, copy);

        await tester.tap(field);
        await tester.pump();
        await tester.enterText(field, 'Hallo Welt');
        await tester.pumpAndSettle();
        final state = tester.state<EditableTextState>(field);
        state.selectAll(SelectionChangedCause.toolbar);
        await tester.pump();
        state.showToolbar();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(state.selectionOverlay?.toolbarIsVisible, isTrue);
        expect(find.text(copy), findsOneWidget);
      },
    );
  }
}
