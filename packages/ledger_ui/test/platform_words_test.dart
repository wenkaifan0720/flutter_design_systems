// In an app that gives none of material_ui's or cupertino_ui's words (here a WidgetsApp; in the field, Flutter's
// MaterialApp with flutter_localizations, whose words are Flutter's types), a field's menu speaks the app's language
// from material_ui's and cupertino_ui's own translations, and a language they do not know reads English.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

Widget _app(Locale locale, TextDirection direction, {bool design = true}) =>
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: design
          ? RawWidgetsLocalizations.supportedLocales
          : [locale],
      localizationsDelegates: design
          ? const [RawWidgetsLocalizations.delegate]
          : const [],
      builder: (context, _) => Directionality(
        textDirection: direction,
        child: LedgerHost(
          brightness: Brightness.light,
          child: Navigator(
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => const Center(
                child: SizedBox(
                  width: 340,
                  child: LedgerTextField(labelText: 'Name'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _openMenu(WidgetTester t) async {
  final field = find.byType(EditableText);
  await t.tap(field);
  await t.enterText(field, 'Kontoauszug');
  await t.pump();
  final state = t.state<EditableTextState>(field);
  state.selectAll(SelectionChangedCause.keyboard);
  await t.pump();
  // A press held may have opened it already: open it afresh.
  state.hideToolbar();
  await t.pump();
  state.showToolbar();
  await t.pumpAndSettle();
}

void main() {
  for (final platform in const [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('a field\'s menu reads German under de on ${platform.name}', (
      t,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await t.pumpWidget(_app(const Locale('de'), TextDirection.ltr));
      await t.pumpAndSettle();
      await _openMenu(t);
      expect(t.takeException(), isNull);
      expect(find.text('Kopieren'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a field\'s menu reads Arabic under ar on ${platform.name}', (
      t,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await t.pumpWidget(_app(const Locale('ar'), TextDirection.rtl));
      await t.pumpAndSettle();
      await _openMenu(t);
      expect(t.takeException(), isNull);
      expect(find.text('Copy'), findsNothing);
      expect(find.textContaining('نسخ'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'a language material_ui does not know reads English on ${platform.name}',
      (t) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await t.pumpWidget(
          _app(const Locale('tlh'), TextDirection.ltr, design: false),
        );
        await t.pumpAndSettle();
        await _openMenu(t);
        expect(t.takeException(), isNull);
        expect(find.text('Copy'), findsOneWidget);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
