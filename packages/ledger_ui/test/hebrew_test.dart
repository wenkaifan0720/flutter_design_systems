// Quill right to left speaks Hebrew: every word on its screens, its account sheet and its sign-out dialog reads that
// way, so a mirrored Quill never shows English reordered by the bidi algorithm ("8 of 12 packed" read as "of 12 packed
// 8"). What stays in Latin letters is what a Hebrew page keeps in them: figures, money, codes (··4821, T280812BLUE) and
// the install's code.
// The gallery is the example app; a test reads its pages from there.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/quill/entry.dart';
import '../example/lib/kit_gallery/quill/home.dart';
import '../example/lib/kit_gallery/quill/quill.dart';
import '../example/lib/kit_gallery/quill/register.dart';
import '../example/lib/kit_gallery/quill/words.dart';

/// Words in Latin letters a Hebrew page keeps: the Overview's install code, the package's name (upper-cased in a
/// bar's meta) and the owner's email.
const Set<String> _kept = {
  'ledger_ui',
  'LEDGER_UI',
  'Flutter',
  'FLUTTER',
  'maren.holt',
  'example.com',
  'builder',
  'MaterialApp',
  'CupertinoApp',
  'WidgetsApp',
  'flutter',
  'pub',
  'add',
  'context',
  'child',
  'LedgerTheme',
  'data',
  'LedgerThemeData.light',
};

/// Each Latin word in [text] that is not a code (one with a figure in it) or a kept word.
Iterable<String> _english(String text) =>
    RegExp(r"[A-Za-z][A-Za-z_.']*[A-Za-z]")
        .allMatches(text)
        .map((m) => m.group(0)!)
        .where((w) => !_kept.contains(w) && !RegExp(r'\d').hasMatch(w));

List<String> _englishOnScreen(WidgetTester t) {
  final out = <String>{};
  for (final e in find.byType(RichText).evaluate()) {
    final text = (e.widget as RichText).text.toPlainText();
    // Codes stand beside their words: a receipt's number, a card's mask.
    for (final word in text.split(RegExp(r'\s+'))) {
      if (RegExp(r'\d').hasMatch(word)) continue;
      out.addAll(_english(word));
    }
  }
  for (final e in find.byType(EditableText).evaluate()) {
    out.addAll(_english((e.widget as EditableText).controller.text));
  }
  return out.toList()..sort();
}

Future<void> _open(WidgetTester t, QuillPage page, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    QuillApp(
      key: UniqueKey(),
      initialPage: page,
      initialDirection: TextDirection.rtl,
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    final at = '${size.width.toInt()}';
    for (final page in QuillPage.values) {
      testWidgets('$at ${page.name} speaks Hebrew', (t) async {
        await _open(t, page, size);
        expect(_englishOnScreen(t), isEmpty);
      });
    }
    testWidgets(
      '$at the receipt, the entry, the account sheet and the dialog speak Hebrew',
      (t) async {
        await _open(t, QuillPage.home, size);
        final frame = t.state<QuillFrameState>(find.byType(QuillFrame));
        frame.push(QuillReceiptPage(tx: kitDays.first.rows.first));
        await t.pumpAndSettle();
        expect(_englishOnScreen(t), isEmpty, reason: 'receipt');
        Navigator.of(t.element(find.byType(QuillReceiptPage))).pop();
        await t.pumpAndSettle();
        frame.push(const QuillEntryPage());
        await t.pumpAndSettle();
        expect(_englishOnScreen(t), isEmpty, reason: 'entry');
        Navigator.of(t.element(find.byType(QuillEntryPage))).pop();
        await t.pumpAndSettle();
        unawaited(
          showQuillAccount(
            t.element(find.byType(QuillHome)),
            kitAccounts.first,
          ),
        );
        await t.pumpAndSettle();
        expect(_englishOnScreen(t), isEmpty, reason: 'account sheet');
      },
    );
    testWidgets(
      '$at the register searching, finding nothing, and unable to load speak Hebrew',
      (t) async {
        await _open(t, QuillPage.register, size);
        await t.enterText(find.byType(EditableText), 'קפה');
        await t.pumpAndSettle();
        expect(
          find.textContaining(
            quillHebrewWords['Blue Fern Café']!,
            findRichText: true,
          ),
          findsWidgets,
        );
        expect(_englishOnScreen(t), isEmpty, reason: 'searching');
        await t.enterText(find.byType(EditableText), 'אין כזה');
        await t.pumpAndSettle();
        expect(
          find.text(quillHebrewWords['Nothing found']!, findRichText: true),
          findsOneWidget,
        );
        expect(_englishOnScreen(t), isEmpty, reason: 'nothing found');
        t.view.physicalSize = size;
        await t.pumpWidget(
          QuillApp(
            key: UniqueKey(),
            initialPage: QuillPage.register,
            initialDirection: TextDirection.rtl,
            registerOffline: true,
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.text(
            quillHebrewWords['The register could not load']!,
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(_englishOnScreen(t), isEmpty, reason: 'unable to load');
      },
    );
    testWidgets('$at sign out asks in Hebrew', (t) async {
      await _open(t, QuillPage.settings, size);
      final out = find
          .text(quillHebrewWords['Sign out']!, findRichText: true)
          .first;
      await t.ensureVisible(out);
      await t.pumpAndSettle();
      await t.tap(out);
      await t.pumpAndSettle();
      expect(
        find.text(quillHebrewWords['Sign out of Quill?']!, findRichText: true),
        findsOneWidget,
      );
      expect(_englishOnScreen(t), isEmpty);
    });
  }
}
