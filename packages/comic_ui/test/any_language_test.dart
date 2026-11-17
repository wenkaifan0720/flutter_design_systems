// Under an app in another language that gives no Material or Cupertino words of the libraries Comic is built on, every
// part builds, and on Android and iOS each field takes text and opens its menu over a selection: the machinery under a
// field (the editable text, a raised route) asks for Material's words, and on iOS its selection for Cupertino's, and
// Flutter's own delegates load only in English, so in 0.1.0 a field threw "No MaterialLocalizations found". ui_core's
// shared words follow the app's language.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';

import 'tiers.dart';

void main() {
  for (final (l, (locale, direction)) in const [
    (Locale('ar'), TextDirection.rtl),
    (Locale('de'), TextDirection.ltr),
  ].indexed) {
    final language = locale.languageCode;

    Future<void> pumpIn(WidgetTester tester, WidgetBuilder builder) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          locale: locale,
          supportedLocales: DesignLocalizations.supportedLocales,
          localizationsDelegates: const [DesignLocalizations.delegate],
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          home: Directionality(
            textDirection: direction,
            child: ComicHost(
              light: ComicThemeData.offset(),
              child: Center(
                child: SizedBox(
                  width: 390,
                  height: 640,
                  child: Builder(builder: builder),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('a field builds and takes words under an app in $language '
        'with no Material words, and ui_core speaks $language', (tester) async {
      late DesignLocalizations words;
      await pumpIn(tester, (context) {
        words = DesignLocalizations.of(context);
        return const ComicTextField(label: 'Name', hint: 'As on your card');
      });
      expect(tester.takeException(), isNull);
      expect(
        words.closeButtonLabel,
        DesignLocalizations.forLocale(locale).closeButtonLabel,
      );
      expect(words.closeButtonLabel, isNot('Close'));
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // Each field takes words, then a double tap selects one and opens the menu (else the selection and the menu are
    // asked for directly, as for a field that takes only digits).
    Future<void> selectInEachField(WidgetTester tester) async {
      final fields = find.byType(EditableText, skipOffstage: false);
      final count = fields.evaluate().length;
      for (var i = 0; i < count; i++) {
        final field = fields.at(i);
        final state = tester.state<EditableTextState>(field);
        if (!state.mounted || !state.widget.focusNode.canRequestFocus) {
          continue;
        }
        await tester.ensureVisible(field);
        await tester.pump();
        if (!state.widget.readOnly) {
          await tester.enterText(field, '1234 Ada Lovelace');
          await tester.pump();
        }
        expect(tester.takeException(), isNull, reason: 'field $i takes words');
        final at =
            tester.getTopLeft(field) +
            Offset(12, tester.getSize(field).height / 2);
        await tester.tapAt(at);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(at);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'field $i selects');
        if (!state.mounted) continue;
        if (!(state.selectionOverlay?.toolbarIsVisible ?? false)) {
          state.selectAll(SelectionChangedCause.toolbar);
          await tester.pump();
          state.showToolbar();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull, reason: 'field $i menu');
        if (state.selectionOverlay?.toolbarIsVisible ?? false) {
          expect(
            find.byType(ComicTextContextMenu),
            findsWidgets,
            reason: 'field $i opens Comic\'s menu',
          );
          state.hideToolbar();
          await tester.pump();
        }
      }
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    // Every run builds each part once, in Arabic and in German in turn, on Android or iOS in turn; the sweep builds
    // it in the other language and on the other platform.
    for (final (i, entry)
        in comicInventory.entries.where((e) => e.builder != null).indexed) {
      final platform = (i ~/ 2).isEven
          ? TargetPlatform.android
          : TargetPlatform.iOS;
      testWidgetsOnEveryPlatform(
        '${entry.row} builds under an app in $language, and its fields '
        'select and open their menu',
        (tester) async {
          await pumpIn(tester, entry.builder!);
          expect(tester.takeException(), isNull);
          await selectInEachField(tester);
        },
        everyday: i % 2 == l ? {platform} : const {},
        across: const {TargetPlatform.android, TargetPlatform.iOS},
      );
    }
  }
}
