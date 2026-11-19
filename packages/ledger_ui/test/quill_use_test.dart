// Quill in use: what a person does in it holds as they move through it. A saved entry joins the register and its
// search; an amount reads as the dollars it was written as, a decimal comma included; a corrected field drops its
// error; signing out closes the account until Sign in; a changed name stays; the register counts only what a scroll
// reaches; the currency is a fact, not a choice the app could not keep; and at twice the text size the tab bar's names
// read large, breaking between their words.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../example/lib/kit_gallery/quill/entry.dart';
import '../example/lib/kit_gallery/quill/quill.dart';
import '../example/lib/kit_gallery/quill/register.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);

Future<void> _open(
  WidgetTester t,
  QuillPage page,
  Size size, {
  double? textScale,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    QuillApp(key: UniqueKey(), initialPage: page, textScale: textScale),
  );
  await t.pumpAndSettle();
}

QuillFrameState _frame(WidgetTester t) =>
    t.state<QuillFrameState>(find.byType(QuillFrame));

Future<void> _tab(WidgetTester t, String id) async {
  // ui_core's shell presses the tab over Ledger's face.
  await t.tap(find.byKey(ValueKey('tab-$id')), warnIfMissed: false);
  await t.pumpAndSettle();
}

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is LedgerTextField && w.label == label),
  matching: find.byType(EditableText),
);

Future<void> _choose(WidgetTester t, String select, String option) async {
  final field = find.byWidgetPredicate(
    (w) => w is LedgerSelect && w.label == select,
  );
  await t.tap(
    find.descendant(of: field, matching: find.byType(LedgerPressable)).first,
  );
  await t.pumpAndSettle();
  await t.tap(find.text(option).last);
  await t.pumpAndSettle();
}

Future<void> _newEntry(
  WidgetTester t, {
  required String amount,
  required String payee,
}) async {
  _frame(t).push(const QuillEntryPage());
  await t.pumpAndSettle();
  await t.enterText(_field('Amount'), amount);
  await t.enterText(_field('Payee'), payee);
  await t.pumpAndSettle();
  await _choose(t, 'Category', 'Groceries');
}

Future<void> _save(WidgetTester t) async {
  await t.tap(find.widgetWithText(LedgerButton, 'Save entry'));
  await t.pumpAndSettle();
}

Future<void> _signOut(WidgetTester t) async {
  final out = find.widgetWithText(LedgerButton, 'Sign out');
  await t.scrollUntilVisible(
    out,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.pumpAndSettle();
  await t.tap(out);
  await t.pumpAndSettle();
  await t.tap(
    find
        .descendant(
          of: find.byType(LedgerDialog),
          matching: find.text('Sign out'),
        )
        .last,
  );
  await t.pumpAndSettle();
}

/// Lets a toast run out, so no timer outlives the test.
Future<void> _rest(WidgetTester t) async {
  await t.pump(const Duration(seconds: 30));
  await t.pumpAndSettle();
}

String _meta(WidgetTester t) {
  final bar = t.widget<LedgerTopBar>(find.byType(LedgerTopBar).last);
  return bar.meta ?? '';
}

void main() {
  setUpAll(_loadFonts);

  test('an amount reads as the dollars it was written as', () {
    const read = {
      '17.43': 17.43,
      '17,43': 17.43,
      r'$17.43': 17.43,
      ' 17.4 ': 17.4,
      '17': 17.0,
      '.43': .43,
      '1,743': 1743.0,
      '1,743.50': 1743.5,
      '1.743,50': 1743.5,
      '1.234.567': 1234567.0,
      '1,234,567.89': 1234567.89,
    };
    for (final MapEntry(:key, :value) in read.entries) {
      expect(quillAmount(key), value, reason: key);
    }
    // Nothing it would have to guess at: a third decimal, a stray mark, a sign, a word.
    for (final unread in const [
      '',
      ',',
      '17.435',
      '1,743.500',
      '17,4,3',
      '1.74.3',
      '-5',
      '17a',
      'twelve',
    ]) {
      expect(quillAmount(unread), isNull, reason: unread);
    }
  });

  testWidgets('a decimal comma prints the same receipt as a decimal point', (
    t,
  ) async {
    await _open(t, QuillPage.register, _desktop);
    _frame(t).push(const QuillEntryPage());
    await t.pumpAndSettle();
    final figure = find.descendant(
      of: find.byType(LedgerReceipt),
      matching: find.byType(LedgerFigure),
    );
    await t.enterText(_field('Amount'), '17,43');
    await t.pumpAndSettle();
    expect(t.widget<LedgerFigure>(figure).amount, -17.43);
    await t.enterText(_field('Amount'), '17.43');
    await t.pumpAndSettle();
    expect(t.widget<LedgerFigure>(figure).amount, -17.43);
  });

  testWidgets('an amount it cannot read is named, never saved as another', (
    t,
  ) async {
    await _open(t, QuillPage.register, _desktop);
    await _newEntry(t, amount: '17,4,3', payee: 'Oriole Books');
    await _save(t);
    expect(find.text('Enter an amount such as 17.43'), findsOneWidget);
    expect(find.byType(QuillEntryPage), findsOneWidget);
  });

  testWidgets('a corrected field drops its error as it is corrected', (
    t,
  ) async {
    await _open(t, QuillPage.register, _desktop);
    _frame(t).push(const QuillEntryPage());
    await t.pumpAndSettle();
    await _save(t);
    expect(find.text('Enter what was paid'), findsOneWidget);
    expect(find.text('Say who was paid'), findsOneWidget);
    await t.enterText(_field('Amount'), '17.43');
    await t.pumpAndSettle();
    expect(find.text('Enter what was paid'), findsNothing);
    expect(find.text('Say who was paid'), findsOneWidget);
    await t.enterText(_field('Payee'), 'Oriole Books');
    await t.pumpAndSettle();
    expect(find.text('Say who was paid'), findsNothing);
    // Emptied again, the field says so again.
    await t.enterText(_field('Amount'), '');
    await t.pumpAndSettle();
    expect(find.text('Enter what was paid'), findsOneWidget);
  });

  for (final size in const [_phone, _desktop]) {
    final at = '${size.width.round()}';

    testWidgets(
      '$at a saved entry joins its day in the register, its search and its receipt',
      (t) async {
        await _open(t, QuillPage.register, size);
        final before = find.byType(LedgerTransactionRow).evaluate().length;
        await _newEntry(t, amount: '17,43', payee: 'Oriole Books');
        await _save(t);
        expect(find.byType(QuillEntryPage), findsNothing);
        expect(find.byType(LedgerTransactionRow), findsNWidgets(before + 1));
        expect(_meta(t), '${before + 1} entries since Oct 25');
        await t.enterText(
          find.descendant(
            of: find.byType(LedgerSearchField),
            matching: find.byType(EditableText),
          ),
          'Oriole',
        );
        await t.pumpAndSettle();
        expect(find.text('Nothing found'), findsNothing);
        expect(
          find.widgetWithText(LedgerTransactionRow, 'Oriole Books'),
          findsOneWidget,
        );
        expect(_meta(t), '1 of ${before + 1} entries');
        final row = t.widget<LedgerTransactionRow>(
          find.widgetWithText(LedgerTransactionRow, 'Oriole Books'),
        );
        expect(row.amount, -17.43);
        await t.tap(find.widgetWithText(LedgerTransactionRow, 'Oriole Books'));
        await t.pumpAndSettle();
        expect(find.byType(QuillReceiptPage), findsOneWidget);
        expect(
          t.widget<LedgerFigure>(find.byType(LedgerFigure).last).amount,
          -17.43,
        );
        await _rest(t);
      },
    );

    testWidgets('$at the register counts only the entries a scroll reaches', (
      t,
    ) async {
      await _open(t, QuillPage.register, size);
      final rows = find.byType(LedgerTransactionRow).evaluate().length;
      expect(_meta(t), '$rows entries since Oct 25');
      await t.tap(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is LedgerFilters),
          matching: find.text('Pending'),
        ),
      );
      await t.pumpAndSettle();
      final pending = find.byType(LedgerTransactionRow).evaluate().length;
      expect(_meta(t), '$pending of $rows entries');
    });
  }

  testWidgets('signing out closes the account until Sign in', (t) async {
    await _open(t, QuillPage.settings, _phone);
    await _signOut(t);
    expect(find.text('Signed out'), findsOneWidget);
    expect(find.text('You are signed out'), findsOneWidget);
    expect(find.widgetWithText(LedgerButton, 'Sign out'), findsNothing);
    expect(find.text('maren.holt@example.com'), findsNothing);
    // The toast stands over a phone's tab bar while it shows.
    await _rest(t);
    await _tab(t, 'register');
    expect(find.byType(QuillSignedOutPage), findsOneWidget);
    expect(find.byType(LedgerTransactionRow), findsNothing);
    await _tab(t, 'home');
    expect(find.byType(QuillSignedOutPage), findsOneWidget);
    expect(find.byType(LedgerFigure), findsNothing);
    _frame(t).push(const QuillEntryPage());
    await t.pumpAndSettle();
    expect(find.byType(LedgerTextField), findsNothing);
    await t.tap(find.text('Sign in'));
    await t.pumpAndSettle();
    expect(_field('Amount'), findsOneWidget);
    Navigator.of(t.element(find.byType(QuillEntryPage))).pop();
    await t.pumpAndSettle();
    await _tab(t, 'register');
    expect(find.byType(LedgerTransactionRow), findsWidgets);
    await _rest(t);
  });

  testWidgets(
    'signing out at desktop width closes the receipt a person had open',
    (t) async {
      await _open(t, QuillPage.settings, _desktop);
      final settings = t.element(find.byType(QuillFrame));
      _frame(t)
          .push(QuillReceiptPage(tx: quillDays(settings).first.rows.first));
      await t.pumpAndSettle();
      _frame(t).signOut();
      await t.pumpAndSettle();
      expect(find.byType(QuillReceiptPage), findsNothing);
      expect(find.text('You are signed out'), findsOneWidget);
    },
  );

  testWidgets('a changed name stays as Quill moves between pages', (t) async {
    await _open(t, QuillPage.settings, _phone);
    await t.tap(
      find.byWidgetPredicate((w) => w is LedgerSettingRow && w.title == 'Name'),
    );
    await t.pumpAndSettle();
    await t.enterText(
      find.descendant(
        of: find.byType(LedgerDialog),
        matching: find.byType(EditableText),
      ),
      'Rowan Vale',
    );
    await t.tap(
      find
          .descendant(
            of: find.byType(LedgerDialog),
            matching: find.text('Save'),
          )
          .last,
    );
    await t.pumpAndSettle();
    expect(find.text('Rowan Vale'), findsWidgets);
    await _tab(t, 'register');
    await _tab(t, 'home');
    expect(find.text('Good evening, Rowan'), findsOneWidget);
    await _tab(t, 'settings');
    expect(find.text('Rowan Vale'), findsWidgets);
    expect(find.text('Maren Holt'), findsNothing);
  });

  testWidgets('the currency is a fact, not a choice', (t) async {
    await _open(t, QuillPage.settings, _desktop);
    expect(
      find.byWidgetPredicate((w) => w is LedgerSelect && w.label == 'Currency'),
      findsNothing,
    );
    final row = t.widget<LedgerSettingRow>(
      find.byWidgetPredicate(
        (w) => w is LedgerSettingRow && w.title == 'Currency',
      ),
    );
    expect(row.value, 'US dollar');
    expect(row.onTap, isNull);
  });

  group("the tab bar's names", () {
    double scaleOf(WidgetTester t, String label) {
      final p = t.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(LedgerNavBar),
              matching: find.text(label),
            )
            .first,
      );
      return p.textScaler.scale(11) / 11;
    }

    int linesOf(WidgetTester t, String label) {
      final p = t.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byType(LedgerNavBar),
              matching: find.text(label),
            )
            .first,
      );
      final text = p.text.toPlainText();
      final boxes = p.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      return {for (final b in boxes) b.top.round()}.length;
    }

    testWidgets('at the reader\'s size stand on one line at that size', (
      t,
    ) async {
      await _open(t, QuillPage.register, _phone);
      for (final label in const [
        'Ledger',
        'Home',
        'Register',
        'Settings',
        'New entry',
      ]) {
        expect(scaleOf(t, label), 1, reason: label);
        expect(linesOf(t, label), 1, reason: label);
      }
    });

    testWidgets(
      'at twice the text size read large, a name of two words on two lines',
      (t) async {
        await _open(t, QuillPage.register, _phone, textScale: 2);
        // The widest word (Settings, Register) sets the size, not "New entry" on one line (1.33).
        for (final label in const [
          'Ledger',
          'Home',
          'Register',
          'Settings',
          'New entry',
        ]) {
          expect(scaleOf(t, label), greaterThan(1.6), reason: label);
        }
        expect(linesOf(t, 'New entry'), 2);
        expect(linesOf(t, 'Home'), 1);
        // No word broken, and the bar holds what it shows.
        for (final e
            in find
                .descendant(
                  of: find.byType(LedgerNavBar),
                  matching: find.byType(RichText),
                )
                .evaluate()) {
          final p = e.renderObject! as RenderParagraph;
          expect(
            p.getMinIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(p.size.width + .5),
            reason: '${p.text}',
          );
          expect(p.didExceedMaxLines, isFalse, reason: '${p.text}');
        }
        final bar = t.getRect(find.byType(LedgerNavBar));
        expect(bar.bottom, lessThanOrEqualTo(_phone.height + .5));
        expect(t.takeException(), isNull);
      },
    );
  });
}
