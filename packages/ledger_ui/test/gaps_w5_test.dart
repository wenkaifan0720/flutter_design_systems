// The design-system gaps the Keel app found in the inputs, the button, the
// goals, the gauge and the money, and the row heights measured on the live
// source: each pumped as the pilot uses it, measured or read back through its
// semantics against the source's figures.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/src/ledger/internal/button_ends.dart';
import 'package:ledger_ui/src/ledger/internal/on_cheque.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- The frame (as inputs_test.dart's) ---------------------------------------

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);
const Key _frame = ValueKey<String>('frame');

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

LedgerThemeData _theme(WidgetTester t) =>
    t.element(find.byKey(_frame)).ledgerTheme;

/// Pumps [child] on a phone and at desktop width, light and dark; each lays
/// out clean, then [check] runs.
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
      check?.call(size == _desktop, _theme(t));
    }
  }
}

/// Every label and value the semantics tree speaks, in its order.
List<String> _spoken(WidgetTester t) {
  final words = <String>[];
  void walk(SemanticsNode node) {
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

Widget _atStart(Widget child) =>
    Align(alignment: AlignmentDirectional.centerStart, child: child);

/// The Container ruled all round that holds [of] (the cheque's sum box).
Finder _ringed(Finder of) => find.ancestor(
  of: of,
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).border is Border &&
        ((w.decoration! as BoxDecoration).border! as Border).top.width > 0,
  ),
);

/// The bottom rule's colour of the Container that holds [of].
Color? _ruleUnder(WidgetTester t, Finder of) {
  final box = t.widget<Container>(
    find
        .ancestor(
          of: of,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).border is Border &&
                ((w.decoration! as BoxDecoration).border! as Border)
                        .bottom
                        .width >
                    0,
          ),
        )
        .first,
  );
  return ((box.decoration! as BoxDecoration).border! as Border).bottom.color;
}

// --- The pilot's words (the gallery's keel.dart) -----------------------------

const String _transferWords = 'Five hundred and 00/100';
const double _transferAmount = 500;
const String _transferNote = 'November top-up';

void main() {
  setUpAll(_loadFonts);
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  // --- 3. a target of 0 ------------------------------------------------------

  group('a target of 0', () {
    test('LedgerFormat.percent reads no share of nothing', () {
      expect(LedgerFormat.percent(0, 0), 0);
      expect(LedgerFormat.percent(50, 0), 0);
      expect(LedgerFormat.percent(double.nan, 100), 0);
      expect(LedgerFormat.percent(2840, 4000), 71);
    });

    testWidgets('a goal with none set reads 0% on an empty gauge', (t) async {
      await _everywhere(
        t,
        LedgerRows(
          children: [
            LedgerGoalLine(
              icon: LucideIcons.plane,
              name: 'Your goal',
              saved: 0,
              target: 0,
              by: 'by a date',
              onTap: () {},
            ),
            LedgerGoalCard(
              icon: LucideIcons.plane,
              name: 'New goal',
              saved: 0,
              target: 0,
              status: 'On track',
              note: 'Set a target to begin.',
              onTap: () {},
            ),
          ],
        ),
        (wide, theme) {
          expect(find.text('0%'), findsNWidgets(2));
          expect(_node(t, 'Your goal, 0%, by a date'), isNotNull);
          expect(_node(t, 'New goal, 0%, On track'), isNotNull);
        },
      );
    });
  });

  // --- 4. the share ends the goal's line -------------------------------------

  group("the goal's share", () {
    testWidgets("ends at the line's end, the leader 20 clear of each", (
      t,
    ) async {
      await _everywhere(
        t,
        Column(
          children: [
            LedgerGoalLine(
              key: const ValueKey('line'),
              icon: LucideIcons.plane,
              name: 'Lisbon in May',
              saved: 2840,
              target: 4000,
              by: 'by May 2027',
              onTap: () {},
            ),
            LedgerGoalCard(
              key: const ValueKey('card'),
              icon: LucideIcons.bike,
              name: 'New bike',
              saved: 430,
              target: 1200,
              by: 'by Oct 2027',
              status: 'On track',
              note: 'At \$80 a month you get there in time.',
              onTap: () {},
            ),
          ],
        ),
        (wide, theme) {
          for (final (key, share) in [('line', '71%'), ('card', '36%')]) {
            final goal = find.byKey(ValueKey(key));
            final gauge = t.getRect(
              find.descendant(of: goal, matching: find.byType(LedgerGauge)),
            );
            final pct = t.getRect(
              find.descendant(of: goal, matching: find.text(share)),
            );
            // `.goal .line` is as wide as its gauge; the share ends it.
            expect(pct.right, moreOrLessEquals(gauge.right, epsilon: .01));
            // Centred on the 32 glyph's line, as `.goal .line` centres.
            final glyph = t.getRect(
              find.descendant(of: goal, matching: find.byType(LedgerGlyph)),
            );
            expect(
              pct.center.dy,
              moreOrLessEquals(glyph.center.dy, epsilon: .01),
            );
          }
        },
      );
    });
  });

  // --- 6. the cheque's amount stands as the source's -------------------------

  group('LedgerChequeAmount', () {
    testWidgets("its box holds the input's normal line: 95 tall, 116 wide", (
      t,
    ) async {
      final sum = TextEditingController(text: '500.00');
      addTearDown(sum.dispose);
      await _everywhere(
        t,
        LedgerChequeAmount(
          key: const ValueKey('amount'),
          label: 'Amount',
          words: _transferWords,
          unit: 'dollars',
          controller: sum,
        ),
        (wide, theme) {
          // The transfer's capture: `.amount-box` 95 (116 on the desktop),
          // `.amount-row` 197.8 (218.8) with its rule; here 198 (219), the
          // label's line the whole 22 a Text of the body takes.
          // The box's Container holds its 8 margin above.
          final box = t.getSize(_ringed(find.byType(EditableText)).first);
          expect(box.height, (wide ? 116 : 95) + 8);
          final row = t.getSize(find.byKey(const ValueKey('amount')));
          expect(row.height, moreOrLessEquals(wide ? 219 : 198));
        },
      );
    });

    testWidgets('typed: the sum read back as the input holds it', (t) async {
      await _everywhere(
        t,
        const LedgerChequeAmount(
          label: 'Amount',
          words: _transferWords,
          unit: 'dollars',
          amount: _transferAmount,
          typed: true,
        ),
        (wide, theme) {
          expect(find.text('500.00'), findsOneWidget);
          expect(find.byType(EditableText), findsNothing);
          expect(
            _node(t, 'Amount'),
            isSemantics(label: 'Amount', value: '\$500.00', isTextField: false),
          );
          final box = t.getSize(_ringed(find.text('500.00')).first);
          expect(box.height, (wide ? 116 : 95) + 8);
        },
      );
    });
  });

  // --- 10. a setting with no destination -------------------------------------

  group('LedgerSettingRow', () {
    testWidgets('with no onTap it stands in the full ink, read as words', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerRows(
          children: [
            LedgerSettingRow(
              icon: LucideIcons.circleDollarSign,
              title: 'Currency',
              value: 'USD',
              subtitle: 'US dollar',
            ),
          ],
        ),
        (wide, theme) {
          for (final words in ['Currency', 'USD']) {
            expect(
              t.widget<Text>(find.text(words)).style?.color,
              theme.textPrimary,
              reason: words,
            );
          }
          // Not a control: no button, nothing disabled, no tap.
          expect(
            _node(t, 'Currency'),
            isSemantics(
              label: 'Currency',
              value: 'USD',
              isButton: false,
              hasEnabledState: false,
              hasTapAction: false,
            ),
          );
          expect(_spoken(t), ['Currency', 'USD']);
        },
      );
    });

    testWidgets('disabled it is held in the third ink', (t) async {
      await _everywhere(
        t,
        LedgerSettingRow(
          icon: LucideIcons.gauge,
          title: 'Monthly spending limit',
          value: r'$2,000',
          subtitle: 'Resets on the 1st',
          enabled: false,
          onTap: () => fail('a held row takes no tap'),
        ),
        (wide, theme) {
          expect(
            _node(t, 'Monthly spending limit'),
            isSemantics(
              isButton: true,
              hasEnabledState: true,
              isEnabled: false,
              hasTapAction: false,
            ),
          );
          expect(
            t.widget<Text>(find.text('Monthly spending limit')).style?.color,
            theme.textTertiary,
          );
        },
      );
      await t.tap(find.text('Monthly spending limit'), warnIfMissed: false);
    });
  });

  // --- the rows' heights, as the live profile measures them -------------------

  group('row heights', () {
    testWidgets('a switch row is 71 with its rule, 70 last', (t) async {
      await _everywhere(
        t,
        LedgerRows(
          children: [
            LedgerToggleRow(
              key: const ValueKey('bills'),
              icon: LucideIcons.receipt,
              title: 'Bills',
              subtitle: 'A reminder before each bill is due',
              value: true,
              onChanged: (_) {},
            ),
            LedgerToggleRow(
              key: const ValueKey('weekly'),
              icon: LucideIcons.calendarDays,
              title: 'Weekly summary',
              subtitle: 'Mondays, the week in one note',
              value: false,
              onChanged: (_) {},
            ),
          ],
        ),
        (wide, theme) {
          final first = t.getRect(find.byKey(const ValueKey('bills')));
          final last = t.getRect(find.byKey(const ValueKey('weekly')));
          // The profile at 390: `.toggle-row` 71.8, the last 70.8; held
          // to whole pixels (the title's line 21), 71 and 70.
          expect(first.height, moreOrLessEquals(70));
          expect(last.top - first.top, moreOrLessEquals(71));
          expect(last.height, moreOrLessEquals(70));
        },
      );
    });

    testWidgets('a setting row is 70 with its rule, 69 last', (t) async {
      await _everywhere(
        t,
        LedgerRows(
          children: [
            LedgerSettingRow(
              key: const ValueKey('month'),
              icon: LucideIcons.calendar1,
              title: 'Month starts on',
              value: 'the 1st',
              subtitle: 'Budgets and Spending follow it',
              onTap: () {},
            ),
            const LedgerSettingRow(
              key: ValueKey('currency'),
              icon: LucideIcons.circleDollarSign,
              title: 'Currency',
              value: 'USD',
              subtitle: 'US dollar',
            ),
          ],
        ),
        (wide, theme) {
          final month = t.getRect(find.byKey(const ValueKey('month')));
          final currency = t.getRect(find.byKey(const ValueKey('currency')));
          // The profile at 390: `.set-row` 70 with its rule (Month starts
          // on), 69 last in its group (Currency): 28 + 20 + 3 + 18.
          expect(currency.top - month.top, moreOrLessEquals(70));
          expect(currency.height, moreOrLessEquals(69));
        },
      );
    });

    testWidgets('a setting row with no sub stands on its 40 glyph', (t) async {
      await _pump(
        t,
        const LedgerSettingRow(
          key: ValueKey('bare'),
          icon: LucideIcons.keyRound,
          title: 'Change passcode',
        ),
      );
      expect(t.getSize(find.byKey(const ValueKey('bare'))).height, 28 + 40);
    });
  });

  // --- 13. keys on the filters and the clear ---------------------------------

  group('keys', () {
    testWidgets("each filter takes its key; the search's clear takes one", (
      t,
    ) async {
      final picked = <String?>[];
      final words = TextEditingController(text: 'fern');
      addTearDown(words.dispose);
      var cleared = 0;
      await _pump(
        t,
        Column(
          children: [
            LedgerFilters(
              label: 'Direction',
              options: const ['All', 'Money in', 'Money out'],
              value: 'All',
              optionKeys: const {'Money in': ValueKey('in')},
              onChanged: picked.add,
            ),
            LedgerSearchField(
              controller: words,
              hint: 'Search merchants and categories',
              onCleared: () => cleared++,
              clearKey: const ValueKey('clear'),
            ),
          ],
        ),
      );
      await t.tap(find.byKey(const ValueKey('in')));
      expect(picked, ['Money in']);
      await t.tap(find.byKey(const ValueKey('clear')));
      expect(cleared, 1);
    });
  });

  // --- 14. a button's spoken name --------------------------------------------

  group('LedgerButton', () {
    testWidgets('says its spoken name, else its words', (t) async {
      var taps = 0;
      await _everywhere(
        t,
        _atStart(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LedgerButton(
                'Change',
                size: LedgerButtonSize.small,
                semanticLabel: 'Change category',
                onPressed: () => taps++,
              ),
              LedgerButton.filled('Continue', onPressed: () {}),
            ],
          ),
        ),
        (wide, theme) {
          expect(
            _node(t, 'Change category'),
            isSemantics(label: 'Change category', isButton: true),
          );
          expect(_spoken(t), ['Change category', 'Continue']);
          expect(find.text('Change'), findsOneWidget);
        },
      );
      t.semantics.tap(find.semantics.byLabel('Change category'));
      expect(taps, 1);
    });

    testWidgets('compact it stands 40, 16 inside its ends', (t) async {
      await _everywhere(
        t,
        _atStart(
          LedgerButton(
            'Add money',
            key: const ValueKey('compact'),
            size: LedgerButtonSize.medium,
            icon: LucideIcons.plus,
            onPressed: () {},
          ),
        ),
        (wide, theme) {
          final face = t.getRect(find.byKey(const ValueKey('compact')));
          final glyph = t.getRect(find.byIcon(LucideIcons.plus));
          expect(face.height, 40);
          // 16 inside its ring of 1.
          expect(glyph.left - face.left, moreOrLessEquals(17));
          expect(t.widget<Text>(find.text('Add money')).style?.fontSize, 14);
        },
      );
    });
  });

  // --- 9. the gauge stops at its end -----------------------------------------

  group('LedgerGauge', () {
    testWidgets('spending past its end is clipped to its box', (t) async {
      await _pump(
        t,
        const LedgerGauge(ratio: 1.6, budgetAt: 250 / 300, tick: false),
      );
      final paint = t.renderObject<RenderCustomPaint>(
        find.descendant(
          of: find.byType(LedgerGauge),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(paint, paints..clipRect(rect: Offset.zero & paint.size));
    });

    testWidgets("the pace's key: 4 dashes of 3, 2 apart, flush", (t) async {
      await _pump(
        t,
        _atStart(
          const LedgerChartKey(
            entries: [LedgerKeyEntry(LedgerKeySwatch.pace, 'Budget pace')],
          ),
        ),
      );
      final swatch = t.renderObject<RenderCustomPaint>(
        find.descendant(
          of: find.byType(LedgerChartKey),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(swatch.size, const Size(18, 1.5));
      expect(
        swatch,
        paints
          ..rect(rect: const Rect.fromLTWH(0, 0, 3, 1.5))
          ..rect(rect: const Rect.fromLTWH(5, 0, 3, 1.5))
          ..rect(rect: const Rect.fromLTWH(10, 0, 3, 1.5))
          ..rect(rect: const Rect.fromLTWH(15, 0, 3, 1.5)),
      );
    });
  });

  // --- 19. read-only parts of the transfer's form ----------------------------

  group('read only', () {
    testWidgets('a pick shown keeps its chevron and is no control', (t) async {
      await _everywhere(
        t,
        const LedgerPickLine(
          label: 'From',
          icon: LucideIcons.wallet,
          name: 'Everyday',
          mask: '··4821',
          balance: 6248.3,
          note: 'Available',
          showChevron: true,
        ),
        (wide, theme) {
          expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
          expect(
            t.getSemantics(find.text('Everyday')),
            isSemantics(isButton: false, hasTapAction: false),
          );
        },
      );
    });

    testWidgets("a field's value is read only, on a cheque's faint rule", (
      t,
    ) async {
      await _everywhere(
        t,
        const Column(
          children: [
            LedgerField(
              key: ValueKey('off'),
              label: 'Note',
              value: _transferNote,
            ),
            LedgerOnCheque(
              child: LedgerField(
                key: ValueKey('on'),
                label: 'Memo',
                value: _transferNote,
              ),
            ),
          ],
        ),
        (wide, theme) {
          expect(find.byType(EditableText), findsNothing);
          expect(
            _node(t, 'Note'),
            isSemantics(
              label: 'Note',
              value: _transferNote,
              isTextField: true,
              isReadOnly: true,
            ),
          );
          final off = find.descendant(
            of: find.byKey(const ValueKey('off')),
            matching: find.text(_transferNote),
          );
          final on = find.descendant(
            of: find.byKey(const ValueKey('on')),
            matching: find.text(_transferNote),
          );
          // Off a cheque the ink; on one the faint ink.
          expect(_ruleUnder(t, off), theme.headRule);
          expect(_ruleUnder(t, on), theme.textFaint);
          // `.input`: the typed line 24, ruled 4 above and 8 under.
          expect(
            t.getSize(find.byKey(const ValueKey('off'))).height,
            16 + 16 + 4 + 4 + 24 + 8 + 1,
          );
        },
      );
    });
  });
  // --- the rest: the stepper alone, the row's button ends, the 12 amount -----

  group('the rest', () {
    testWidgets("the stepper's sum stands on its input's own line", (t) async {
      await _everywhere(
        t,
        Column(
          children: [
            LedgerStepper(
              key: const ValueKey('rings'),
              value: 250,
              label: 'Monthly budget',
              onChanged: (_) {},
            ),
            LedgerStepper(
              key: const ValueKey('alone'),
              value: 110,
              label: 'Amount to add',
              showRings: false,
              onChanged: (_) {},
            ),
          ],
        ),
        (wide, theme) {
          // `.stepper-input` 72/1.05 (88): the live sheets' `.stepper`
          // 91.59 (108.4) and `.add-amount` 75.59 (92.4) tall; the line
          // held to the whole pixel here, 76 (92).
          final line = wide ? 92.0 : 76.0;
          expect(
            t.getSize(find.byKey(const ValueKey('rings'))).height,
            closeTo(6 + line + 10, .05),
          );
          // `.add-amount`: 4 above, 8 under, no rings.
          final alone = find.byKey(const ValueKey('alone'));
          expect(t.getSize(alone).height, closeTo(4 + line + 8, .05));
          expect(
            find.descendant(of: alone, matching: find.byIcon(LucideIcons.plus)),
            findsNothing,
          );
          expect(
            _node(t, 'Amount to add'),
            isSemantics(
              value: '\$110',
              hasIncreaseAction: true,
              hasDecreaseAction: true,
            ),
          );
        },
      );
    });

    testWidgets('a row of buttons keeps 16 inside their ends', (t) async {
      await _pump(
        t,
        _atStart(
          LedgerButtonEnds(
            child: LedgerButton(
              'Back to Home',
              key: const ValueKey('row'),
              icon: LucideIcons.house,
              onPressed: () {},
            ),
          ),
        ),
      );
      final face = t.getRect(find.byKey(const ValueKey('row')));
      final glyph = t.getRect(find.byIcon(LucideIcons.house));
      // 16 inside its ring of 1 (`.form-actions-row .btn`: 0 16).
      expect(glyph.left - face.left, moreOrLessEquals(17));
    });

    testWidgets("a holding's today amount is 12 on 20", (t) async {
      await _pump(
        t,
        _atStart(const LedgerAmount(73.42, size: LedgerAmountSize.today)),
      );
      final style = t.widget<Text>(find.byType(Text)).textSpan!.style!;
      expect(style.fontSize, 12);
      expect(style.fontSize! * style.height!, moreOrLessEquals(20));
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
