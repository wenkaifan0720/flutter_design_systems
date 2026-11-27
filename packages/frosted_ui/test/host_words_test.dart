// The host and an app's words and direction: under FrostedHost a page keeps
// the Material words its app gives (a translation stands), and the
// direction the app sets around the host. An app with no Material words
// (a WidgetsApp) gets Flutter's English ones from the host, and still keeps
// its direction: a Localizations sets its own locale's direction under it,
// which once turned every page under the host left to right.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

class _Fine extends DefaultMaterialLocalizations {
  @override
  String get okButtonLabel => 'Fine';
}

class _FineDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _FineDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(_Fine());

  @override
  bool shouldReload(_FineDelegate old) => false;
}

void main() {
  late BuildContext page;
  final probe = Builder(
    builder: (context) {
      page = context;
      return const SizedBox.shrink();
    },
  );

  testWidgets('an app\'s own Material words stand under the host', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [_FineDelegate()],
        builder: (context, child) =>
            FrostedHost(brightness: Brightness.light, child: child!),
        home: probe,
      ),
    );
    expect(MaterialLocalizations.of(page).okButtonLabel, 'Fine');
  });

  testWidgets('the direction set around the host reaches the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: FrostedHost(brightness: Brightness.light, child: child!),
        ),
        home: probe,
      ),
    );
    expect(Directionality.of(page), TextDirection.rtl);
  });

  testWidgets('an app with no Material words gets them and keeps its '
      'direction', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: FrostedHost(brightness: Brightness.light, child: probe),
        ),
      ),
    );
    expect(MaterialLocalizations.of(page).okButtonLabel, 'OK');
    expect(Directionality.of(page), TextDirection.rtl);
  });

  // An app in another language that gives no Material words of the library
  // the look is built on (none, or flutter_localizations' of Flutter's own
  // type): Flutter's English delegate loads only in English, so a field, a
  // date picker and a dialog threw for want of them. They build, with
  // Material words (English in the catalog, the app's language in the
  // package: translated_words_test), and ui_core's shared words speak the
  // app's language.
  for (final (locale, direction) in const [
    (Locale('de'), TextDirection.ltr),
    (Locale('ar'), TextDirection.rtl),
  ]) {
    testWidgets('a field, a date picker and a dialog build under an app in '
        '${locale.languageCode} with no Material words', (tester) async {
      late BuildContext at;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          locale: locale,
          supportedLocales: RawWidgetsLocalizations.supportedLocales,
          localizationsDelegates: const [RawWidgetsLocalizations.delegate],
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          builder: (context, child) => Directionality(
            textDirection: direction,
            child: FrostedHost(brightness: Brightness.light, child: child!),
          ),
          home: Builder(
            builder: (context) {
              at = context;
              return Center(
                child: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FrostedTextField(labelText: 'Name', value: 'Ada'),
                      FrostedDatePicker(
                        value: DateTime(2026, 11, 14),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(EditableText));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      unawaited(FrostedDialog.show(at, title: 'Freeze the card?'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Freeze the card?'), findsOneWidget);
      expect(MaterialLocalizations.of(at).okButtonLabel, isNotEmpty);
      expect(Directionality.of(at), direction);
      final shared = RawWidgetsLocalizations.forLocale(locale);
      expect(
        RawWidgetsLocalizations.of(at).closeButtonLabel,
        shared.closeButtonLabel,
      );
      expect(shared.closeButtonLabel, isNot('Close'));
    });
  }

  // On iOS a field's selected text raises its context menu: the look draws
  // its own (its words, ui_core's), never Cupertino's, so an app that gives
  // no Cupertino words (none in German or Arabic) still shows it.
  for (final (locale, direction) in const [
    (Locale('de'), TextDirection.ltr),
    (Locale('ar'), TextDirection.rtl),
  ]) {
    final fields = <String, Widget>{
      'text field': const FrostedTextField(
        labelText: 'Name',
        value: 'Ada Lovelace',
      ),
      'text area': const FrostedTextArea(
        labelText: 'Note',
        value: 'Ada Lovelace',
      ),
      'amount field': const FrostedAmountField(
        labelText: 'Amount',
        value: '500',
      ),
      'password field': const FrostedPasswordField(
        labelText: 'Password',
        value: 'secret words',
      ),
      'search field': const FrostedSearchField(hintText: 'Search'),
    };
    for (final MapEntry(key: name, value: field) in fields.entries) {
      testWidgets(
        'in ${locale.languageCode}, a $name shows its menu over '
        'selected text',
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
        (tester) async {
          await tester.pumpWidget(
            WidgetsApp(
              color: const Color(0xFF000000),
              locale: locale,
              supportedLocales: RawWidgetsLocalizations.supportedLocales,
              localizationsDelegates: const [RawWidgetsLocalizations.delegate],
              pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
                settings: settings,
                pageBuilder: (context, _, _) => builder(context),
              ),
              builder: (context, child) => Directionality(
                textDirection: direction,
                child: FrostedHost(brightness: Brightness.light, child: child!),
              ),
              home: Center(child: SizedBox(width: 340, child: field)),
            ),
          );
          await tester.pumpAndSettle();
          final editable = find.byType(EditableText);
          final state = tester.state<EditableTextState>(editable);
          if (name == 'search field') {
            // An editable field: typed into, then a word chosen by a double
            // tap, as a person does (on iOS a long press there moves the
            // caret).
            await tester.enterText(editable, 'Ada Lovelace');
            await tester.pump(const Duration(milliseconds: 400));
            await tester.tap(editable);
            await tester.pump(const Duration(milliseconds: 50));
            await tester.tap(editable);
            await tester.pump(const Duration(milliseconds: 300));
            expect(state.textEditingValue.selection.isCollapsed, isFalse);
          } else {
            await tester.tap(editable);
            await tester.pump(const Duration(milliseconds: 300));
            await tester.longPress(editable);
            await tester.pump(const Duration(milliseconds: 300));
            state.selectAll(SelectionChangedCause.toolbar);
          }
          state.showToolbar();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(find.byType(FrostedTextContextMenu), findsOneWidget);
          // Material's words: English in the catalog, the app's language in
          // the package.
          if (name != 'password field') {
            final words = MaterialLocalizations.of(tester.element(editable));
            expect(find.text(words.copyButtonLabel), findsOneWidget);
          }
        },
      );
    }
  }

  // The selection's handles and menu build in the root overlay, above a
  // host put under home rather than in the app's builder: they read the
  // theme's default there rather than throwing for want of one.
  testWidgets(
    'text selected under a host under home shows its handles and '
    'menu',
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FrostedHost(
            brightness: Brightness.light,
            child: Center(
              child: SizedBox(
                width: 340,
                child: FrostedTextField(
                  labelText: 'Name',
                  value: 'Ada Lovelace',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final editable = find.byType(EditableText);
      await tester.tap(editable);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.longPress(editable);
      await tester.pump(const Duration(milliseconds: 300));
      final state = tester.state<EditableTextState>(editable);
      state.selectAll(SelectionChangedCause.toolbar);
      state.showToolbar();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FrostedTextContextMenu), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    },
  );
}
