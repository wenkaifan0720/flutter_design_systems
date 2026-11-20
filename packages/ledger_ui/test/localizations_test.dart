// Ledger under an app in another language that gives no Material or
// Cupertino words of the library Ledger is built on (an app on
// flutter_localizations gives another library's): its fields, its date
// picker and its sheet build, focus, open their menus and speak ui_core's
// words in the app's language, never throwing for want of Material's.
import 'package:flutter/foundation.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoLocalizations;
import 'package:material_ui/material_ui.dart'
    show MaterialApp, MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

Widget _app(Locale locale, TextDirection direction, Widget page) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: DesignLocalizations.supportedLocales,
  localizationsDelegates: const [DesignLocalizations.delegate],
  builder: (context, _) => Directionality(
    textDirection: direction,
    child: LedgerHost(
      brightness: Brightness.light,
      child: Navigator(
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          pageBuilder: (_, _, _) =>
              Center(child: SizedBox(width: 340, child: page)),
        ),
      ),
    ),
  ),
);

/// The menu's Copy in the words the field reads: Cupertino's on iOS, Material's elsewhere (English in an
/// app on flutter/material, the app's language in the package, which loads material_ui's and cupertino_ui's translations).
String _copy(BuildContext field, TargetPlatform platform) =>
    platform == TargetPlatform.iOS
    ? CupertinoLocalizations.of(field).copyButtonLabel
    : MaterialLocalizations.of(field).copyButtonLabel;

void main() {
  for (final (locale, direction) in const [
    (Locale('ar'), TextDirection.rtl),
    (Locale('de'), TextDirection.ltr),
  ]) {
    for (final platform in const [TargetPlatform.android, TargetPlatform.iOS]) {
      final at = '${locale.languageCode} on ${platform.name}';

      testWidgets('a text field builds, focuses and opens its menu under $at', (
        t,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await t.pumpWidget(
          _app(
            locale,
            direction,
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LedgerTextField(label: 'Name'),
                LedgerPasswordField(label: 'Password'),
                LedgerTextArea(label: 'Memo'),
              ],
            ),
          ),
        );
        await t.pumpAndSettle();
        final fields = find.byType(EditableText);
        expect(fields, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          final field = fields.at(i);
          await t.tap(field);
          await t.enterText(field, 'Kontoauszug');
          await t.pump();
          // A press held on the words, as a finger selects them.
          await t.longPress(field);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          // The words chosen and the menu open over them: on iOS cupertino's
          // toolbar, which reads CupertinoLocalizations; elsewhere Material's.
          final state = t.state<EditableTextState>(field);
          if (!state.widget.obscureText) {
            state.selectAll(SelectionChangedCause.keyboard);
            await t.pump();
          }
          // A press held may have opened it already: open it afresh.
          state.hideToolbar();
          await t.pump();
          state.showToolbar();
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          if (!state.widget.obscureText) {
            expect(
              find.text(_copy(t.element(field), platform)),
              findsOneWidget,
            );
          }
          state.hideToolbar();
          await t.pumpAndSettle();
        }
        debugDefaultTargetPlatformOverride = null;
      });

      testWidgets('a date picker and a sheet build and open under $at', (
        t,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await t.pumpWidget(
          _app(
            locale,
            direction,
            Builder(
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LedgerDatePicker(
                    value: DateTime(2026, 10, 14),
                    onChanged: (_) {},
                  ),
                  LedgerButton(
                    'Open',
                    onPressed: () => LedgerSheet.show<void>(
                      context,
                      title: 'Sheet',
                      builder: (_) => [const Text('Body')],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.byType(LedgerButton));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.text('Body'), findsOneWidget);
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('a stepper field says its range in ${locale.languageCode}', (
      t,
    ) async {
      await t.pumpWidget(
        _app(
          locale,
          direction,
          LedgerStepper(
            size: LedgerStepperSize.field,
            label: 'Minuten',
            value: 45,
            min: 5,
            max: 480,
            step: 5,
            onChanged: (_) {},
          ),
        ),
      );
      await t.pumpAndSettle();
      final words = DesignLocalizations.forLocale(locale);
      final range =
          '${words.formatDecimal(5)}\u2013${words.formatDecimal(480)}';
      await t.tap(find.byType(EditableText));
      await t.enterText(find.byType(EditableText), '900');
      await t.pump();
      expect(find.text(range), findsOneWidget);
      expect(find.textContaining(RegExp('From|Enter')), findsNothing);
      await t.enterText(find.byType(EditableText), 'x');
      await t.pump();
      expect(find.text(range), findsOneWidget);
    });

    testWidgets('ui_core\'s words are in ${locale.languageCode}', (t) async {
      late DesignLocalizations words;
      await t.pumpWidget(
        _app(
          locale,
          direction,
          Builder(
            builder: (context) {
              words = DesignLocalizations.of(context);
              return const LedgerTextField(label: 'Name');
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final shared = DesignLocalizations.forLocale(locale);
      expect(words.closeButtonLabel, shared.closeButtonLabel);
      expect(words.closeButtonLabel, isNot('Close'));
    });
  }

  // The host under the app's home rather than in its builder: a field's
  // selection handles and menu build in the root overlay, above the host and
  // its theme, and read Ledger's theme there (its default, as Theme.of gives
  // Material's), never throwing for want of one.
  for (final platform in const [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('a field under a host in home selects on ${platform.name}', (
      t,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await t.pumpWidget(
        const MaterialApp(
          home: LedgerHost(
            brightness: Brightness.light,
            child: Center(
              child: SizedBox(
                width: 340,
                child: LedgerTextField(label: 'Name'),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final field = find.byType(EditableText);
      await t.tap(field);
      await t.enterText(field, 'Kontoauszug');
      await t.pump();
      await t.longPress(field);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final state = t.state<EditableTextState>(field);
      state.selectAll(SelectionChangedCause.keyboard);
      await t.pump();
      // A press held may have opened it already: open it afresh.
      state.hideToolbar();
      await t.pump();
      state.showToolbar();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text(_copy(t.element(field), platform)), findsOneWidget);
      state.hideToolbar();
      await t.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
