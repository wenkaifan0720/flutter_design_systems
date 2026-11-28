// The family's round-3 items, as Terminal answers them: the faces the parts
// draw with (Terminal's glyphs are its face's own) load before the first
// frame, the README's one list of delegates is the example's and works, and
// at a desk a page's keys stand in its column, under its answers.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../example/lib/main.dart';

void main() {
  test(
    'termLoadFonts loads every face a part draws with, its glyphs too',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final asked = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler('flutter/assets', (message) async {
        final key = utf8.decode(message!.buffer.asUint8List());
        asked.add(key);
        final file = File('assets/fonts/${key.split('/').last}');
        return ByteData.sublistView(file.readAsBytesSync());
      });
      addTearDown(
        () => messenger.setMockMessageHandler('flutter/assets', null),
      );
      await termLoadFonts();
      final files = {for (final key in asked) key.split('/').last};
      expect(files, {
        'JetBrainsMonoNL-Regular.ttf',
        'JetBrainsMonoNL-Bold.ttf',
        'LiberationMono-Regular.ttf',
        'LiberationMono-Bold.ttf',
      });
      // Every family a theme's words name (a glyph, a box line and a mark are
      // characters of the face) is one the loader loads.
      for (final theme in [TermThemeData.dark(), TermThemeData.light()]) {
        for (final style in [
          theme.textStyle,
          theme.boldStyle,
          theme.dimStyle,
        ]) {
          final families = [style.fontFamily, ...?style.fontFamilyFallback];
          for (final family in families.nonNulls) {
            expect(
              [termFontFamily, termFallbackFontFamily]
                  .map(termRegisteredFamily)
                  .followedBy([termFontFamily, termFallbackFontFamily]),
              contains(family),
            );
          }
        }
      }
    },
  );

  test(
    "the README's delegates are the example's, with no flutter_localizations",
    () {
      final readme = File('README.md').readAsStringSync();
      for (final line in [
        '...GlobalMaterialLocalizations.delegates,',
        'RawWidgetsLocalizations.delegate,',
        'TermLocalizations.delegate,',
      ]) {
        expect(RegExp(RegExp.escape(line)).allMatches(readme), hasLength(1));
      }
      expect(readme, contains('needs no `flutter_localizations` dependency'));
      expect(readme, isNot(contains('Nothing needs setting')));
    },
  );

  testWidgets(
    'the example lists the README\'s delegates, and they speak Arabic',
    (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('ar')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final shelf = Shelf.sample();
      addTearDown(shelf.dispose);
      await tester.pumpWidget(ShelfApp(shelf: shelf));
      await tester.pumpAndSettle();
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.localizationsDelegates, [
        ...GlobalMaterialLocalizations.delegates,
        RawWidgetsLocalizations.delegate,
        TermLocalizations.delegate,
      ]);
      final context = tester.element(find.byType(ShelfShell));
      expect(Localizations.localeOf(context).languageCode, 'ar');
      expect(
        RawWidgetsLocalizations.of(context).backButtonTooltip,
        isNot(const DefaultRawWidgetsLocalizations().backButtonTooltip),
      );
      expect(
        TermLocalizations.of(context).paginationLabel,
        isNot(const DefaultTermLocalizations().paginationLabel),
      );
      expect(Directionality.of(context), TextDirection.rtl);
    },
  );

  for (final rtl in [false, true]) {
    testWidgets('at 1440 a page\'s keys stand in its column, under its answers '
        '(${rtl ? 'rtl' : 'ltr'})', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      if (rtl) {
        tester.platformDispatcher.localesTestValue = const [Locale('ar')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      }
      final shelf = Shelf.sample();
      addTearDown(shelf.dispose);
      await tester.pumpWidget(ShelfApp(shelf: shelf));
      await tester.pumpAndSettle();
      final lh = tester.element(find.byType(ShelfShell)).termGrid.lineHeight;

      void keysInColumn(Finder keys, Finder column) {
        final col = tester.getRect(column);
        final key = tester.getRect(keys);
        expect(key.left, greaterThanOrEqualTo(col.left - 0.5));
        expect(key.right, lessThanOrEqualTo(col.right + 0.5));
        // At the column's start, a line under the answer above it.
        if (rtl) {
          expect(key.right, moreOrLessEquals(col.right, epsilon: 0.5));
        } else {
          expect(key.left, moreOrLessEquals(col.left, epsilon: 0.5));
        }
        expect(key.top - col.bottom, inInclusiveRange(0, 2 * lh));
      }

      // The add place: "save book" under the last answer.
      await tester.tap(
        find.bySemanticsLabel(RegExp('^add')).hitTestable().first,
      );
      await tester.pumpAndSettle();
      keysInColumn(
        find.widgetWithText(TermButton, 'save book'),
        find.byType(TermDatePicker),
      );

      // A book: edit and delete under its details.
      await tester.tap(
        find.bySemanticsLabel(RegExp('^books')).hitTestable().first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Middlemarch'));
      await tester.pumpAndSettle();
      final column = find.ancestor(
        of: find.byType(TermDescriptionList),
        matching: find.byType(TermPane),
      );
      keysInColumn(find.widgetWithText(TermButton, 'edit'), column.first);
      final delete = tester.getRect(find.widgetWithText(TermButton, 'delete'));
      final details = tester.getRect(column.first);
      expect(delete.left, greaterThanOrEqualTo(details.left - 0.5));
      expect(delete.right, lessThanOrEqualTo(details.right + 0.5));
    });
  }
}
