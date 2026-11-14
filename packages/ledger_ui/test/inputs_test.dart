// The Stage C inputs: each control built from its doc comment's example or
// the Keel pilot's words (the gallery's generated keel.dart), pumped on a
// phone and at desktop width in both appearances, read back through its
// semantics, then driven: a tap calls back with the new value, and a null
// callback leaves the control inert and says so.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- The frame ---------------------------------------------------------------

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);
const Key _frame = ValueKey<String>('frame');

/// A page's column: the gutter at its sides (24, 56 from 1024), the widget
/// as wide as the column, free to grow down.
Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => LedgerHost(brightness: brightness, child: page!),
  home: Builder(
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: LedgerLayout.gutter(context),
        vertical: 24,
      ),
      child: KeyedSubtree(key: _frame, child: child),
    ),
  ),
);

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(child, brightness));
}

/// The theme the frame's widget is drawn in.
LedgerThemeData _theme(WidgetTester t) =>
    t.element(find.byKey(_frame)).ledgerTheme;

/// Pumps [child] on a phone and at desktop width, light and dark. Each lays
/// out clean (nothing overflows or throws, no words cut short), then
/// [check] runs. The desktop's dark stays pumped for what follows.
Future<void> _everywhere(
  WidgetTester t,
  Widget child, [
  void Function(bool wide, LedgerThemeData theme)? check,
]) async {
  for (final size in const [_phone, _desktop]) {
    for (final brightness in Brightness.values) {
      await _pump(t, child, size: size, brightness: brightness);
      final where = '${size.width.round()} wide, ${brightness.name}';
      expect(t.takeException(), isNull, reason: where);
      _expectWordsFit(t, where);
      check?.call(size == _desktop, _theme(t));
    }
  }
}

/// Every line of words stands whole: none clipped at its end or its foot.
void _expectWordsFit(WidgetTester t, String where) {
  for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
    if (!p.hasSize) continue;
    final words = p.text.toPlainText();
    final oneLine = !p.softWrap || p.maxLines == 1;
    if (oneLine) {
      expect(
        p.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(p.size.width + .5),
        reason: '"$words" is cut short ($where)',
      );
    } else {
      expect(p.didExceedMaxLines, isFalse, reason: '"$words" ($where)');
    }
    expect(
      p.getMinIntrinsicHeight(p.size.width),
      lessThanOrEqualTo(p.size.height + .5),
      reason: '"$words" is cut at its foot ($where)',
    );
  }
}

/// Every label and value the semantics tree speaks, in its order.
List<String> _spoken(WidgetTester t) {
  final words = <String>[];
  void walk(SemanticsNode node) {
    // A node merged into its parent speaks in the parent's words.
    if (node.isMergedIntoParent) return;
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) words.add(data.label);
    if (data.value.isNotEmpty) words.add(data.value);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  for (final view in t.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) walk(root);
  }
  return words;
}

SemanticsNode _node(WidgetTester t, Pattern label) =>
    t.getSemantics(find.bySemanticsLabel(label));

/// The labels of [node]'s own children, in their order.
List<String> _childLabels(SemanticsNode node) {
  final labels = <String>[];
  node.visitChildren((child) {
    labels.add(child.getSemanticsData().label);
    return true;
  });
  return labels;
}

/// A button (or a link) that takes a tap.
Matcher _live({String? label, String? value, bool link = false}) => isSemantics(
  label: label,
  value: value,
  isLink: link,
  isButton: !link,
  hasEnabledState: true,
  isEnabled: true,
  hasTapAction: true,
);

/// A button (or a link) held: it says it is not enabled and takes no tap.
Matcher _inert({String? label, String? value, bool link = false}) =>
    isSemantics(
      label: label,
      value: value,
      isLink: link,
      isButton: !link,
      hasEnabledState: true,
      isEnabled: false,
      hasTapAction: false,
    );

Widget _atStart(Widget child) =>
    Align(alignment: AlignmentDirectional.centerStart, child: child);

/// Loads every family the test asset bundle declares, so text lays out in
/// its real faces instead of the test font's boxes.
Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    // The look names its faces as the package that bundles them registers
    // them (ledgerFontFamily); a family a package already names keeps it.
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

// --- The pilot's words (copied from the gallery's keel.dart) -----------------

const List<String> _ranges = ['1M', '3M', '1Y', 'All'];
const String _range = '1Y';

/// The alert switches: glyph, label, sub, on.
const List<(IconData, String, String, bool)> _alerts = [
  (LucideIcons.receipt, 'Bills', 'A reminder before each bill is due', true),
  (LucideIcons.chartPie, 'Budgets', 'When a category goes over', true),
  (LucideIcons.badgeDollarSign, 'Large purchases', 'Over \$200', true),
  (
    LucideIcons.calendarDays,
    'Weekly summary',
    'Mondays, the week in one note',
    false,
  ),
];
const String _monthlyLimit = '\$2,000';
const String _merchant = 'Blue Fern Café';
const String _transferNote = 'November top-up';
const (IconData, String, String, double) _from = (
  LucideIcons.wallet,
  'Everyday',
  '··4821',
  6248.3,
);
const (IconData, String, String, double) _to = (
  LucideIcons.landmark,
  'Savings',
  '··9015',
  21500,
);
const double _transferAmount = 500;
const String _transferWords = 'Five hundred and 00/100';
const double _diningBudget = 250;

void main() {
  setUpAll(_loadFonts);
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  group('LedgerSegmentedControl', () {
    testWidgets('each chip says whether it is chosen; a tap chooses', (
      t,
    ) async {
      final picked = <String>[];
      await _everywhere(
        t,
        _atStart(
          LedgerSegmentedControl(
            options: _ranges,
            value: _range,
            onChanged: picked.add,
          ),
        ),
        (wide, theme) {
          for (final o in _ranges) {
            expect(
              _node(t, o),
              allOf(
                _live(label: o),
                isSemantics(hasSelectedState: true, isSelected: o == _range),
              ),
              reason: o,
            );
          }
          // The chosen one in the ink, the rest in the second ink.
          expect(t.widget<Text>(find.text(_range)).style?.color, theme.surface);
          expect(
            t.widget<Text>(find.text('All')).style?.color,
            theme.textSecondary,
          );
        },
      );
      expect(picked, isEmpty);
      await t.tap(find.text('3M'));
      expect(picked, ['3M']);
      // The chosen chip again changes nothing, by touch or by the reader.
      await t.tap(find.text(_range));
      t.semantics.tap(find.semantics.byLabel(_range));
      expect(picked, ['3M']);
    });

    testWidgets('with no onChanged every chip is held', (t) async {
      await _everywhere(
        t,
        _atStart(const LedgerSegmentedControl(options: _ranges, value: _range)),
        (wide, theme) {
          for (final o in _ranges) {
            expect(_node(t, o), _inert(label: o), reason: o);
          }
          expect(
            _node(t, _range),
            isSemantics(hasSelectedState: true, isSelected: true),
          );
        },
      );
      await t.tap(find.text('3M'));
      expect(t.takeException(), isNull);
    });

    testWidgets('26 tall in a ring 3 inside', (t) async {
      await _pump(
        t,
        _atStart(
          LedgerSegmentedControl(
            options: _ranges,
            value: _range,
            onChanged: (_) {},
          ),
        ),
      );
      // `.chip` 26 tall; `.chips` 3 inside its 1 px ring.
      expect(
        t.getSize(find.byType(LedgerSegmentedControl)).height,
        26 + 2 * (3 + 1),
      );
    });
  });

  group('LedgerFilters', () {
    testWidgets('a named set; a tap picks, the picked one again lets go', (
      t,
    ) async {
      final direction = <String?>[];
      final account = <String?>[];
      await _everywhere(
        t,
        Wrap(
          spacing: LedgerSpacing.s16,
          runSpacing: LedgerSpacing.s8,
          children: [
            LedgerFilters(
              label: 'Direction',
              options: const ['All', 'Money in', 'Money out'],
              value: 'All',
              onChanged: direction.add,
            ),
            LedgerFilters(
              label: 'Account',
              options: const ['Keel Card', 'Everyday'],
              value: null,
              onChanged: account.add,
            ),
          ],
        ),
        (wide, theme) {
          expect(_spoken(t), [
            'Direction',
            'All',
            'Money in',
            'Money out',
            'Account',
            'Keel Card',
            'Everyday',
          ]);
          expect(_childLabels(_node(t, 'Direction')), [
            'All',
            'Money in',
            'Money out',
          ]);
          for (final o in ['All', 'Money in', 'Money out', 'Keel Card']) {
            expect(
              _node(t, o),
              allOf(
                _live(label: o),
                isSemantics(hasSelectedState: true, isSelected: o == 'All'),
              ),
              reason: o,
            );
          }
        },
      );
      await t.tap(find.text('Money in'));
      await t.tap(find.text('All'));
      await t.tap(find.text('Everyday'));
      expect(direction, ['Money in', null]);
      expect(account, ['Everyday']);
    });

    testWidgets('with no onChanged every filter is held', (t) async {
      await _everywhere(
        t,
        const LedgerFilters(
          label: 'Direction',
          options: ['All', 'Money in', 'Money out'],
          value: 'All',
        ),
        (wide, theme) {
          for (final o in ['All', 'Money in', 'Money out']) {
            expect(_node(t, o), _inert(label: o), reason: o);
          }
        },
      );
    });

    testWidgets('each pill its own width, side by side in a page column', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerFilters(
          label: 'Direction',
          options: ['All', 'Money in', 'Money out'],
          value: 'All',
        ),
        (wide, theme) {
          final all = t.getRect(find.text('All'));
          final moneyIn = t.getRect(find.text('Money in'));
          final out = t.getRect(find.text('Money out'));
          expect(moneyIn.top, all.top);
          expect(out.top, all.top);
          // `.filter` 0 13 inside its 1 px ring; `.filters` 6 apart.
          expect(moneyIn.left - all.right, 2 * (13 + 1) + 6);
          expect(out.left - moneyIn.right, 2 * (13 + 1) + 6);
        },
      );
    });
  });

  group('LedgerSwitch', () {
    testWidgets('says its label and whether it is on; a tap flips it', (
      t,
    ) async {
      final bills = <bool>[];
      final weekly = <bool>[];
      await _everywhere(
        t,
        Row(
          spacing: 16,
          children: [
            LedgerSwitch(
              value: true,
              semanticLabel: 'Bills',
              onChanged: bills.add,
            ),
            LedgerSwitch(
              value: false,
              semanticLabel: 'Weekly summary',
              onChanged: weekly.add,
            ),
            const LedgerSwitch(
              value: true,
              semanticLabel: 'Contactless',
              onChanged: null,
            ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'Bills'),
            allOf(
              _live(label: 'Bills'),
              isSemantics(hasToggledState: true, isToggled: true),
            ),
          );
          expect(
            _node(t, 'Weekly summary'),
            allOf(
              _live(label: 'Weekly summary'),
              isSemantics(hasToggledState: true, isToggled: false),
            ),
          );
          // Held while the card is frozen: still on, dimmed to .45.
          expect(
            _node(t, 'Contactless'),
            allOf(
              _inert(label: 'Contactless'),
              isSemantics(hasToggledState: true, isToggled: true),
            ),
          );
          final dimmed = find.descendant(
            of: find.byType(LedgerSwitch).last,
            matching: find.byType(Opacity),
          );
          expect(t.widget<Opacity>(dimmed).opacity, .45);
          for (final e in t.elementList(find.byType(LedgerSwitch))) {
            expect(e.size, const Size(44, 26));
          }
        },
      );
      await t.tap(find.byType(LedgerSwitch).first);
      await t.tap(find.byType(LedgerSwitch).at(1));
      await t.tap(find.byType(LedgerSwitch).last);
      expect(bills, [false]);
      expect(weekly, [true]);
    });
  });

  group('LedgerToggleRow', () {
    testWidgets('the whole row flips its switch, once', (t) async {
      final flips = <String, List<bool>>{};
      await _everywhere(
        t,
        LedgerRows(
          children: [
            for (final (icon, label, sub, on) in _alerts)
              LedgerToggleRow(
                icon: icon,
                title: label,
                subtitle: sub,
                value: on,
                onChanged: (v) => (flips[label] ??= []).add(v),
              ),
          ],
        ),
        (wide, theme) {
          for (final (_, label, sub, on) in _alerts) {
            expect(
              _node(t, label),
              allOf(
                _live(label: label),
                isSemantics(hasToggledState: true, isToggled: on),
              ),
              reason: label,
            );
            // The row speaks for its switch; the sub is in its words.
            expect(find.text(sub), findsOneWidget);
          }
          expect(_spoken(t), [for (final (_, label, _, _) in _alerts) label]);
        },
      );
      await t.tap(find.text('Budgets'));
      await t.tap(
        find.descendant(
          of: find.widgetWithText(LedgerToggleRow, 'Large purchases'),
          matching: find.byType(LedgerSwitch),
        ),
      );
      await t.tap(find.text('Mondays, the week in one note'));
      expect(flips, {
        'Budgets': [false],
        'Large purchases': [false],
        'Weekly summary': [true],
      });
    });

    testWidgets('with no onChanged it is held and dimmed', (t) async {
      final (icon, label, sub, on) = _alerts.first;
      await _everywhere(
        t,
        LedgerToggleRow(icon: icon, title: label, subtitle: sub, value: on),
        (wide, theme) {
          expect(
            _node(t, label),
            allOf(
              _inert(label: label),
              isSemantics(hasToggledState: true, isToggled: true),
            ),
          );
          expect(
            t.widget<Text>(find.text(label)).style?.color,
            theme.textTertiary,
          );
          expect(
            t
                .widget<Opacity>(
                  find.descendant(
                    of: find.byType(LedgerSwitch),
                    matching: find.byType(Opacity),
                  ),
                )
                .opacity,
            .45,
          );
        },
      );
    });
  });

  group('LedgerSettingRow', () {
    testWidgets('says its label and value; a tap opens it', (t) async {
      var taps = 0;
      await _everywhere(
        t,
        LedgerRows(
          children: [
            LedgerSettingRow(
              icon: LucideIcons.gauge,
              title: 'Monthly spending limit',
              value: _monthlyLimit,
              subtitle: 'Resets on the 1st',
              onTap: () => taps++,
            ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'Monthly spending limit'),
            _live(label: 'Monthly spending limit', value: _monthlyLimit),
          );
          expect(_spoken(t), ['Monthly spending limit', _monthlyLimit]);
          // The label on its leader to the value at the column's end.
          final value = t.getRect(find.text(_monthlyLimit));
          final name = t.getRect(find.text('Monthly spending limit'));
          expect(value.left - name.right, greaterThanOrEqualTo(2 * 6 + 8));
          expect(
            t.widget<Text>(find.text(_monthlyLimit)).style?.color,
            theme.textPrimary,
          );
        },
      );
      await t.tap(find.text('Monthly spending limit'));
      expect(taps, 1);
    });

    testWidgets('disabled it is held and dimmed', (t) async {
      await _everywhere(
        t,
        const LedgerSettingRow(
          icon: LucideIcons.gauge,
          title: 'Monthly spending limit',
          value: _monthlyLimit,
          subtitle: 'Resets on the 1st',
          enabled: false,
        ),
        (wide, theme) {
          expect(
            _node(t, 'Monthly spending limit'),
            _inert(label: 'Monthly spending limit', value: _monthlyLimit),
          );
          for (final words in ['Monthly spending limit', _monthlyLimit]) {
            expect(
              t.widget<Text>(find.text(words)).style?.color,
              theme.textTertiary,
            );
          }
        },
      );
    });
  });

  group('LedgerSearchField', () {
    testWidgets('as a link it says where it leads; a tap follows it', (
      t,
    ) async {
      var taps = 0;
      await _everywhere(
        t,
        LedgerSearchField(
          hint: 'Search merchants and categories',
          semanticLabel: "Search October's activity",
          onTap: () => taps++,
        ),
        (wide, theme) {
          expect(
            _node(t, "Search October's activity"),
            _live(label: "Search October's activity", link: true),
          );
          expect(_spoken(t), ["Search October's activity"]);
          expect(find.text('Search merchants and categories'), findsOneWidget);
          expect(
            t.getSize(find.byType(LedgerSearchField)).height,
            LedgerChromeMetrics.searchHeight,
          );
        },
      );
      await t.tap(find.byType(LedgerSearchField));
      expect(taps, 1);
    });

    testWidgets('live it is a text field: typed words, then a clear', (
      t,
    ) async {
      final controller = TextEditingController(
        text: _merchant.substring(0, _merchant.lastIndexOf(' ')),
      );
      addTearDown(controller.dispose);
      final typed = <String>[];
      var clears = 0;
      await _everywhere(
        t,
        LedgerSearchField(
          hint: 'Search merchants and categories',
          semanticLabel: 'Search activity',
          controller: controller,
          onChanged: typed.add,
          onCleared: () {
            clears++;
            controller.clear();
          },
        ),
        (wide, theme) {
          expect(_node(t, 'Search activity'), isSemantics(isTextField: true));
          expect(_spoken(t), contains('Blue Fern'));
          expect(_node(t, 'Clear'), _live(label: 'Clear'));
          // The placeholder gives way to the words typed.
          expect(find.text('Search merchants and categories'), findsNothing);
        },
      );
      await t.enterText(find.byType(EditableText), _merchant);
      expect(typed, [_merchant]);
      await t.tap(find.bySemanticsLabel('Clear'));
      await t.pump();
      expect(clears, 1);
      expect(controller.text, isEmpty);
      expect(find.bySemanticsLabel('Clear'), findsNothing);
      expect(find.text('Search merchants and categories'), findsOneWidget);
    });
  });

  group('LedgerField', () {
    testWidgets('a text field named by its label; typing calls back', (
      t,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final typed = <String>[];
      final field = LedgerField(
        label: 'Note',
        controller: controller,
        hint: 'What it is for',
        onChanged: typed.add,
      );
      await _everywhere(t, field, (wide, theme) {
        expect(_node(t, 'Note'), isSemantics(isTextField: true));
        // The label is set in the small capitals and said once, as the
        // field's name.
        expect(find.text('NOTE'), findsOneWidget);
        expect(_spoken(t), isNot(contains('NOTE')));
        expect(find.text('What it is for'), findsOneWidget);
      });
      await t.enterText(find.byType(EditableText), _transferNote);
      await t.pump();
      expect(typed, [_transferNote]);
      expect(controller.text, _transferNote);
      expect(_spoken(t), contains(_transferNote));
      // The placeholder gives way to the words typed.
      expect(find.text('What it is for'), findsNothing);
    });

    testWidgets('a control in the typed line: a named group, not a field', (
      t,
    ) async {
      final picks = <String>[];
      var when = 'Today';
      await _everywhere(
        t,
        StatefulBuilder(
          builder: (context, setState) => LedgerField(
            label: 'When',
            child: LedgerSegmentedControl(
              options: const ['Today', 'Later'],
              value: when,
              onChanged: (v) {
                picks.add(v);
                setState(() => when = v);
              },
            ),
          ),
        ),
        (wide, theme) {
          final field = _node(t, 'When');
          expect(field, isSemantics(isTextField: false));
          expect(_childLabels(field), ['Today', 'Later']);
          expect(find.byType(EditableText), findsNothing);
          expect(find.text('WHEN'), findsOneWidget);
          // The chips stand at the field's start, as wide as they are.
          expect(
            t.getRect(find.byType(LedgerSegmentedControl)).left,
            t.getRect(find.byType(LedgerField)).left,
          );
        },
      );
      await t.tap(find.text('Later'));
      await t.pump();
      expect(picks, ['Later']);
      expect(
        _node(t, 'Later'),
        isSemantics(hasSelectedState: true, isSelected: true),
      );
    });
  });

  group('LedgerPickLine', () {
    testWidgets('live it says its account and balance; a tap picks another', (
      t,
    ) async {
      final taps = <String>[];
      await _everywhere(
        t,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (label, account, note) in [
              ('From', _from, 'Available'),
              ('To', _to, 'Balance'),
            ])
              LedgerPickLine(
                label: label,
                icon: account.$1,
                name: account.$2,
                mask: account.$3,
                balance: account.$4,
                note: note,
                onTap: () => taps.add(label),
              ),
          ],
        ),
        (wide, theme) {
          expect(
            _node(t, 'From: Everyday'),
            _live(label: 'From: Everyday', value: '\$6,248.30'),
          );
          expect(
            _node(t, 'To: Savings'),
            _live(label: 'To: Savings', value: '\$21,500.00'),
          );
          expect(_spoken(t), [
            'From: Everyday',
            '\$6,248.30',
            'To: Savings',
            '\$21,500.00',
          ]);
        },
      );
      await t.tap(find.text('Savings'));
      await t.tap(find.text('Everyday'));
      expect(taps, ['To', 'From']);
    });

    testWidgets('read back it is one line of words, no control', (t) async {
      await _everywhere(
        t,
        LedgerPickLine(
          label: 'From',
          icon: _from.$1,
          name: _from.$2,
          mask: _from.$3,
          balance: _from.$4,
          note: 'Available',
        ),
        (wide, theme) {
          final line = _node(t, RegExp('^From:'));
          expect(line, isSemantics(isButton: false, hasTapAction: false));
          final label = line.getSemanticsData().label;
          expect(label, startsWith('From:\nEveryday\n··4821\n'));
          expect(label, contains('\$6,248.30'));
          expect(find.byIcon(LucideIcons.chevronDown), findsNothing);
        },
      );
    });
  });

  group('LedgerChequeAmount', () {
    testWidgets('read back: the engraved sum and the sum in words', (t) async {
      await _everywhere(
        t,
        const LedgerChequeAmount(
          label: 'Amount',
          words: _transferWords,
          unit: 'dollars',
          amount: _transferAmount,
        ),
        (wide, theme) {
          // Read back, the sum says what it is.
          expect(_spoken(t), ['Amount\n\$500.00', _transferWords, 'DOLLARS']);
          expect(find.text('AMOUNT'), findsOneWidget);
        },
      );
    });

    testWidgets('live: a text field named by its label', (t) async {
      final controller = TextEditingController(
        text: _transferAmount.toStringAsFixed(0),
      );
      addTearDown(controller.dispose);
      final typed = <String>[];
      await _everywhere(
        t,
        LedgerChequeAmount(
          label: 'Amount',
          words: _transferWords,
          unit: 'dollars',
          controller: controller,
          onChanged: typed.add,
        ),
        (wide, theme) {
          expect(_node(t, 'Amount'), isSemantics(isTextField: true));
          expect(_spoken(t), contains('500'));
        },
      );
      await t.enterText(find.byType(EditableText), '500.00');
      expect(typed, ['500.00']);
    });
  });

  group('LedgerStepper', () {
    testWidgets('an adjustable sum; its rings and the reader move it by 5', (
      t,
    ) async {
      final moves = <num>[];
      await _everywhere(
        t,
        LedgerStepper(
          value: _diningBudget,
          label: 'Monthly budget',
          onChanged: moves.add,
        ),
        (wide, theme) {
          expect(
            _node(t, 'Monthly budget'),
            isSemantics(
              value: '\$250',
              increasedValue: '\$255',
              decreasedValue: '\$245',
              hasIncreaseAction: true,
              hasDecreaseAction: true,
            ),
          );
          expect(
            _node(t, 'Lower Monthly budget'),
            _live(label: 'Lower Monthly budget'),
          );
          expect(
            _node(t, 'Raise Monthly budget'),
            _live(label: 'Raise Monthly budget'),
          );
          expect(
            t.widget<Text>(find.text('\$250')).style?.fontSize,
            wide ? 88 : 72,
          );
        },
      );
      await t.tap(find.bySemanticsLabel('Lower Monthly budget'));
      await t.tap(find.bySemanticsLabel('Raise Monthly budget'));
      t.semantics.increase(find.semantics.byLabel('Monthly budget'));
      t.semantics.decrease(find.semantics.byLabel('Monthly budget'));
      expect(moves, [245, 255, 255, 245]);
    });

    testWidgets('at its floor it lowers no further', (t) async {
      final moves = <num>[];
      await _everywhere(
        t,
        LedgerStepper(
          value: _diningBudget,
          label: 'Monthly budget',
          min: _diningBudget,
          onChanged: moves.add,
        ),
        (wide, theme) {
          expect(
            _node(t, 'Monthly budget'),
            isSemantics(
              value: '\$250',
              increasedValue: '\$255',
              hasIncreaseAction: true,
              hasDecreaseAction: false,
            ),
          );
          expect(
            _node(t, 'Lower Monthly budget'),
            _inert(label: 'Lower Monthly budget'),
          );
        },
      );
      await t.tap(find.bySemanticsLabel('Lower Monthly budget'));
      expect(moves, isEmpty);
    });

    testWidgets('with no onChanged it holds its sum', (t) async {
      await _everywhere(
        t,
        const LedgerStepper(value: _diningBudget, label: 'Monthly budget'),
        (wide, theme) {
          expect(
            _node(t, 'Monthly budget'),
            isSemantics(
              value: '\$250',
              hasIncreaseAction: false,
              hasDecreaseAction: false,
            ),
          );
          for (final ring in ['Lower Monthly budget', 'Raise Monthly budget']) {
            expect(_node(t, ring), _inert(label: ring));
          }
        },
      );
    });

    testWidgets('each ring says its own words whole when given', (t) async {
      await _everywhere(
        t,
        LedgerStepper(
          value: _diningBudget,
          label: 'Monthly budget',
          lowerLabel: 'Lower the budget',
          raiseLabel: 'Raise the budget',
          onChanged: (_) {},
        ),
        (wide, theme) {
          for (final ring in ['Lower the budget', 'Raise the budget']) {
            expect(_node(t, ring), _live(label: ring));
          }
        },
      );
    });
  });
}

/// Reduced motion on, as a reader who asked for it has it: every Ledger
/// change lands at once, so a test reads the settled frame.
void _stillMotion() =>
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );

/// The platform's own motion back.
void _movingMotion() => TestWidgetsFlutterBinding.instance.platformDispatcher
    .clearAccessibilityFeaturesTestValue();
