// The lists Ledger's fields open, held by ui_core's DesignWidthCheck.checkList:
// the field's width on its leading edge,
// wider only to fit the widest option, its words 16 in from the field's (a
// field written on a rule has no inset; the list's rows keep their 16), 46
// where the options carry glyphs (16, the glyph's 18 and its 12). On a phone
// and at desktop width, left to right and right to left; right to left in
// Hebrew, as a right-to-left app is worded (checkList reads a line's words
// from its first letter, which a Latin word in a right-to-left line sets at
// its far end). Since ui_core's 0.2.0 candidate it reads a right-to-left
// entry's words where they stand, its caret's margin aside.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const Key _form = ValueKey<String>('form');

/// A form's column: the gutter at its sides (24, 56 from 1024), the field
/// in it as a page sets it.
Widget _host(Widget child, TextDirection direction) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => Directionality(
    textDirection: direction,
    child: LedgerHost(brightness: Brightness.light, child: page!),
  ),
  home: Builder(
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: LedgerLayout.gutter(context),
        vertical: 24,
      ),
      child: KeyedSubtree(key: _form, child: child),
    ),
  ),
);

/// The field's control, as checkList reads a field: the select's face, the
/// combobox's entry and toggle, the multi-select's groove of tags and entry.
Finder _under(bool Function(Widget) kind) => find
    .descendant(of: find.byKey(_form), matching: find.byWidgetPredicate(kind))
    .first;

/// One field: its name, its widget in [rtl] Hebrew or else English, the
/// words its list stands in, the control checkList reads and how a person
/// opens its list.
typedef _Case = (
  String,
  Widget Function(bool rtl),
  double,
  Finder Function(),
  Future<void> Function(WidgetTester),
);

Future<void> _tap(WidgetTester t, Finder f) async => t.tap(f);

final List<_Case> _cases = [
  (
    'a select',
    (rtl) => LedgerSelect<String>(
      label: rtl ? 'מטבע' : 'Currency',
      value: 'USD',
      items: [
        LedgerSelectItem(
          value: 'USD',
          label: rtl ? 'דולר אמריקאי' : 'US dollar',
        ),
        LedgerSelectItem(value: 'EUR', label: rtl ? 'אירו' : 'Euro'),
        LedgerSelectItem(
          value: 'GBP',
          label: rtl ? 'לירה שטרלינג' : 'Pound sterling',
        ),
      ],
      onChanged: (_) {},
    ),
    16,
    () => _under((w) => w is LedgerPressable),
    (t) => _tap(t, _under((w) => w is LedgerPressable)),
  ),
  (
    'a select whose options carry glyphs',
    (rtl) => LedgerSelect<String>(
      label: rtl ? 'קטגוריה' : 'Category',
      value: 'Rent',
      items: [
        LedgerSelectItem(
          value: 'Groceries',
          label: rtl ? 'מצרכים' : 'Groceries',
          icon: LucideIcons.shoppingBasket,
        ),
        LedgerSelectItem(
          value: 'Rent',
          label: rtl ? 'שכירות' : 'Rent',
          icon: LucideIcons.house,
        ),
      ],
      onChanged: (_) {},
    ),
    16 + 18 + 12,
    () => _under((w) => w is LedgerPressable),
    (t) => _tap(t, _under((w) => w is LedgerPressable)),
  ),
  (
    'a combobox',
    (rtl) => LedgerCombobox<String>(
      label: rtl ? 'מקבל' : 'Payee',
      options: rtl
          ? const ['בית קפה', 'בית מרקחת', 'ספרים']
          : const ['Corner Market', 'Cedar Books', 'Blue Fern Café'],
      onSelected: (_) {},
    ),
    16,
    () => _under((w) => w is DesignCombobox),
    (t) async {
      final entry = _under((w) => w is EditableText);
      await t.tap(entry);
      await t.pump();
      final rtl = Directionality.of(t.element(entry)) == TextDirection.rtl;
      await t.enterText(entry, rtl ? 'ב' : 'C');
    },
  ),
  (
    'a multi-select',
    (rtl) => LedgerMultiSelect<String>(
      label: rtl ? 'מתחלקים עם' : 'Split with',
      values: [rtl ? 'מרן' : 'Maren'],
      options: rtl
          ? const ['מרן', 'תאו', 'אנה']
          : const ['Maren', 'Theo', 'Ana'],
      onChanged: (_) {},
    ),
    16,
    () => _under((w) => w is DesignTagInput),
    (t) => _tap(t, _under((w) => w is EditableText)),
  ),
];

void main() {
  for (final (name, field, indent, control, open) in _cases) {
    for (final size in const [Size(390, 844), Size(1440, 900)]) {
      for (final direction in TextDirection.values) {
        final rtl = direction == TextDirection.rtl;
        testWidgets(
          '$name at ${size.width.round()}, ${direction.name}: its list on '
          "the field's edge and width, its words ${indent.round()} in",
          (t) async {
            t.view.physicalSize = size;
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            await t.pumpWidget(_host(field(rtl), direction));
            await t.pumpAndSettle();
            await open(t);
            await t.pumpAndSettle();
            final report = await DesignWidthCheck(
              look: 'Ledger',
              listWordsIndent: indent,
            ).checkList(t.element(control()), runAsync: t.runAsync);
            final tags = name == 'a multi-select';
            final problems = [
              // checkList lets a list's words go where chips stand before
              // the entry only when a chip is a control holding its words;
              // a Ledger tag is its words beside its remove button, so it
              // reads the entry's caret, past the tag, as the field's
              // words. The list's words are held from the field's start
              // below instead.
              for (final p in report.problems)
                if (!(tags && p.contains("the field's words"))) p,
            ];
            if (tags) {
              final groove = t.getRect(control());
              final words = t.getRect(find.text(rtl ? 'תאו' : 'Theo').last);
              final inset = rtl
                  ? groove.right - words.right
                  : words.left - groove.left;
              if ((inset - indent).abs() > 1) {
                problems.add(
                  "the list's words stand $inset in from the field's start, "
                  'not $indent',
                );
              }
            }
            await t.sendKeyEvent(LogicalKeyboardKey.escape);
            await t.pumpAndSettle();
            expect(problems, isEmpty, reason: problems.join('\n'));
          },
        );
      }
    }
  }

  // Nothing matching: the paper that says so is the field's width too, as its
  // options' paper is (a slip as wide as "No results" read as another list).
  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets(
      "a combobox at ${size.width.round()} matching nothing: the paper that "
      "says so is the field's width",
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final (_, field, _, control, _) = _cases.firstWhere(
          (c) => c.$1 == 'a combobox',
        );
        await t.pumpWidget(_host(field(false), TextDirection.ltr));
        await t.pumpAndSettle();
        final entry = _under((w) => w is EditableText);
        await t.tap(entry);
        await t.pump();
        await t.enterText(entry, 'Zz');
        await t.pumpAndSettle();
        final paper = t.getRect(
          find
              .ancestor(
                of: find.text('No results'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final box = t.getRect(control());
        expect(paper.width, moreOrLessEquals(box.width, epsilon: 1));
        expect(paper.left, moreOrLessEquals(box.left, epsilon: 1));
      },
    );
  }
}
