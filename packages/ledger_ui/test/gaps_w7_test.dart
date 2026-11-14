// The slip-and-sheet gaps the Keel app found:
// the shadows under the desktop dialog and the card face set against the
// captures, the small card's own width, the slip's band and head made
// public, and the slip family's new parts (the statement, the memo and the
// memo slip, the frozen notice, the dialog lead, the card's details, the
// hairline between effects, the done head, the split ticket, the saved
// after line and the saved before row). Every word and figure is the
// pilot's (ledger/src pages and the captures).
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- The frame (as display_test.dart's) --------------------------------------

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

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
}) async {
  _size(t, size);
  await t.pumpWidget(_host(child, brightness));
}

LedgerThemeData _theme(WidgetTester t) =>
    t.element(find.byKey(_frame)).ledgerTheme;

/// Pumps [child] on a phone and at desktop width, light and dark. Each lays
/// out clean (nothing overflows or throws, no words cut short), then
/// [check] runs.
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

/// The style the first run of words of the line [text] is set in.
TextStyle _style(WidgetTester t, String text) {
  final paragraph = t.renderObject<RenderParagraph>(
    find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText() == text,
    ),
  );
  TextStyle? found;
  void walk(InlineSpan span, TextStyle style) {
    if (found != null) return;
    final own = span.style == null ? style : style.merge(span.style);
    if (span is TextSpan) {
      if (span.text?.isNotEmpty ?? false) {
        found = own;
        return;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        walk(child, own);
      }
    }
  }

  walk(paragraph.text, const TextStyle());
  return found!;
}

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

// --- Pixels -----------------------------------------------------------------

const Key _shot = ValueKey<String>('shot');

/// Reads the colours at [at] (2x pixels) of the boundary [_shot], drawn at
/// 2x with real blurred shadows (flutter_test draws every BoxShadow solid
/// unless [debugDisableShadows] is off: the "dark band" the app's shots
/// showed).
Future<List<(int, int, int)>> _pixels(WidgetTester t, List<Offset> at) async {
  final boundary = t.renderObject(find.byKey(_shot)) as RenderRepaintBoundary;
  final read = await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (image.width, bytes!);
  });
  final (width, bytes) = read!;
  return [
    for (final p in at)
      (
        bytes.getUint8(((p.dy.toInt() * width) + p.dx.toInt()) * 4),
        bytes.getUint8(((p.dy.toInt() * width) + p.dx.toInt()) * 4 + 1),
        bytes.getUint8(((p.dy.toInt() * width) + p.dx.toInt()) * 4 + 2),
      ),
  ];
}

void _expectNear(
  List<(int, int, int)> got,
  List<(int, int, int)> want,
  String what,
) {
  for (var i = 0; i < want.length; i++) {
    final (r, g, b) = got[i];
    final (wr, wg, wb) = want[i];
    expect(
      [(r - wr).abs(), (g - wg).abs(), (b - wb).abs()].every((d) => d <= 8),
      isTrue,
      reason: '$what, sample $i: got $got[$i], the capture $want[$i]',
    );
  }
}

/// Runs [body] with shadows drawn as the app draws them (blurred), the
/// test's own setting restored before the test ends.
Future<void> _realShadows(Future<void> Function() body) async {
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
  }
}

// --- The pilot's words ------------------------------------------------------

const _cardNumber = ['4242', '4242', '4242', '7730'];
const _debitNumber = ['4242', '4242', '4242', '3907'];

const _declined = LedgerEffect(
  icon: LucideIcons.ban,
  title: 'Declined',
  text: 'New purchases and cash withdrawals.',
  blocking: true,
);
const _goesThrough = LedgerEffect(
  icon: LucideIcons.check,
  title: 'Still goes through',
  text: 'Autopay on Nov 12, refunds and payments.',
);

void main() {
  setUpAll(_loadFonts);

  group('gap 8: the shadows', () {
    // The capture's column under the face's middle (pages/cards/mobile,
    // 2x): the face's last row at 859 on the paper, then 5, 21 and 41 rows
    // under it.
    testWidgets('the card face casts the capture\'s soft shadow on a phone', (
      t,
    ) async {
      await _realShadows(() async {
        _size(t, _phone);
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) =>
                LedgerHost(brightness: Brightness.light, child: page!),
            home: RepaintBoundary(
              key: _shot,
              child: const ColoredBox(
                color: Color(0xFFF2EDE3),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 100, 24, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: LedgerCardFace(
                      brand: 'Keel',
                      kind: 'Credit',
                      number: _cardNumber,
                      holder: 'MAREN HOLT',
                      account: 'Keel Card',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(t.getSize(find.byType(LedgerCardFace)), const Size(342, 216));
        // The face's last 2x row: (100 + 216) * 2 - 1.
        const last = 631.0;
        final got = await _pixels(t, [
          const Offset(390, last + 5),
          const Offset(390, last + 21),
          const Offset(390, last + 41),
        ]);
        _expectNear(got, const [
          (165, 164, 159),
          (189, 187, 180),
          (214, 210, 202),
        ], 'under the card face');
      });
    }, tags: 'goldens');

    // The capture's column under the freeze dialog's middle
    // (overlays/cards/freeze/desktop, 2x): the dialog 440 wide, its last
    // row at 1287 over the scrimmed page (149 grey far under it), then 5,
    // 21, 41, 81 and 161 rows under it.
    testWidgets('the desktop dialog casts the capture\'s soft shadow', (
      t,
    ) async {
      await _realShadows(() async {
        _size(t, _desktop);
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) =>
                LedgerHost(brightness: Brightness.light, child: page!),
            home: RepaintBoundary(
              key: _shot,
              child: const ColoredBox(
                color: Color(0xFF959595),
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 440,
                      height: 388,
                      child: LedgerSheetCard(child: SizedBox.expand()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        // The dialog's last 2x row: (100 + 388) * 2 - 1.
        const last = 975.0;
        final got = await _pixels(t, [
          for (final d in const [5, 21, 41, 81, 161]) Offset(1440, last + d),
        ]);
        _expectNear(got, const [
          (108, 110, 112),
          (114, 115, 117),
          (120, 121, 122),
          (132, 133, 133),
          (146, 146, 146),
        ], 'under the dialog');
      });
    }, tags: 'goldens');
    // Both read the drawn pixels, so they depend on the rasterizer, as a
    // golden does: tagged goldens, Linux CI skips them and the macOS goldens
    // job runs them.
  });

  group('the small card face', () {
    testWidgets('stands 264 by 166 (280 by 176) at its column\'s start', (
      t,
    ) async {
      // The column holds its child tight across: the face keeps its own
      // width (`.card-sm`), as on the Cards page (24 in, 264 wide).
      await _everywhere(
        t,
        const LedgerCardFace(
          brand: 'Keel',
          kind: 'Debit',
          number: _debitNumber,
          holder: 'MAREN HOLT',
          account: 'Everyday',
          stock: LedgerCardStock.debit,
          size: LedgerCardSize.small,
        ),
        (wide, theme) {
          final face = t.getRect(
            find.bySemanticsLabel('Debit card ending 3907'),
          );
          expect(face.size, wide ? const Size(280, 176) : const Size(264, 166));
          expect(face.left, wide ? 56 : 24);
        },
      );
    });

    testWidgets('the regular face still fills a phone\'s column', (t) async {
      await _pump(
        t,
        const LedgerCardFace(
          brand: 'Keel',
          kind: 'Credit',
          number: _cardNumber,
          holder: 'MAREN HOLT',
          account: 'Keel Card',
        ),
      );
      expect(
        t.getSize(find.bySemanticsLabel('Credit card ending 7730')),
        const Size(342, 216),
      );
    });
  });

  group('the slip\'s band and head', () {
    testWidgets('print a page\'s own slip as the receipt prints its own', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerSlip(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LedgerSlipBand(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LedgerSlipHead('Keel · New goal', 'Savings'),
              ),
            ],
          ),
        ),
        (wide, theme) {
          expect(t.getSize(find.byType(LedgerSlipBand)).height, 14);
          expect(find.text('KEEL · NEW GOAL'), findsOneWidget);
          expect(find.text('SAVINGS'), findsOneWidget);
          // The source's 10, raised to 11: no words under 11 px.
          expect(_style(t, 'SAVINGS').fontSize, 11);
          // `.receipt-head`: 12 over its words, 18 under (16, 26).
          expect(
            t.getSize(find.byType(LedgerSlipHead)).height,
            (wide ? 16 + 26 : 12 + 18) + 16,
          );
          expect(_spoken(t), ['KEEL · NEW GOAL', 'SAVINGS']);
        },
      );
    });
  });

  group('LedgerStatementSlip', () {
    testWidgets('the balance against its due day, its lines, the last '
        'payment', (t) async {
      var opened = 0;
      await _everywhere(
        t,
        LedgerStatementSlip(
          kind: 'Keel Card · Statement',
          number: '··7730',
          balance: 1326.44,
          due: 'Nov 12',
          dueNote: 'In 15 days',
          details: const [
            LedgerKeyValue('Closed', 'Today · Oct 28'),
            LedgerKeyValue('Autopay', 'Full balance'),
            LedgerKeyValue('Paid from', 'Everyday ··4821'),
          ],
          last: LedgerRow(
            leading: const LedgerGlyph(
              LucideIcons.creditCard,
              tone: LedgerGlyphTone.move,
            ),
            title: 'Last payment',
            value: const LedgerAmount(1180.22),
            subtitle: 'Oct 12 · from Everyday',
            onTap: () => opened++,
          ),
        ),
        (wide, theme) {
          expect(find.text('KEEL CARD · STATEMENT'), findsOneWidget);
          expect(find.text('STATEMENT BALANCE'), findsOneWidget);
          expect(find.text('DUE'), findsOneWidget);
          expect(find.text('IN 15 DAYS'), findsOneWidget);
          final date = _style(t, 'Nov 12');
          expect(date.fontSize, 28);
          expect(date.fontSize! * date.height!, closeTo(30, .01));
          final figure = t.widget<LedgerFigure>(find.byType(LedgerFigure));
          expect(figure.size, LedgerFigureSize.section);
          // The due day stands at the slip's far side, its figure's foot
          // level with the date's block.
          final slip = t.getRect(find.byType(LedgerStatementSlip));
          expect(
            t.getRect(find.text('IN 15 DAYS')).right,
            closeTo(slip.right - (wide ? 32 : 20), .5),
          );
          expect(find.byType(LedgerKeyValue), findsNWidgets(3));
        },
      );
      await t.tap(find.text('Last payment'));
      expect(opened, 1);
    });
  });

  group('LedgerMemo', () {
    testWidgets('the verdict beside its seal, the foot one link', (t) async {
      var opened = 0;
      await _everywhere(
        t,
        LedgerMemo(
          text: 'Dining out is\n',
          over: '\$36.40 over',
          textAfter: '\nbudget.',
          seal: const LedgerSeal(
            kicker: 'Dining',
            value: 'Over',
            foot: '+\$36.40',
            tone: LedgerSealTone.over,
          ),
          leading: const LedgerMonogram(
            'Blue Fern Café',
            size: LedgerMonogramSize.dense,
          ),
          note: '13 visits to Blue Fern Café\ncame to ',
          noteAmount: '\$84.25',
          noteAfter: '.',
          onTap: () => opened++,
        ),
        (wide, theme) {
          // `.memo .seal`: 92.
          final seal = t.widget<LedgerSeal>(find.byType(LedgerSeal));
          expect(seal.size, LedgerSealSize.memo);
          final words = _style(t, 'Dining out is\n\$36.40 over\nbudget.');
          expect(words.fontSize, 28);
          expect(
            _node(t, RegExp('13 visits')),
            isSemantics(isLink: true, hasTapAction: true),
          );
        },
      );
      await t.tap(find.textContaining('13 visits'));
      expect(opened, 1);
    });
  });

  group('LedgerMemoSlip', () {
    testWidgets('the goal\'s standing, its note, its acts', (t) async {
      await _everywhere(
        t,
        LedgerMemoSlip(
          label: 'Behind',
          note:
              'At \$150 a month you reach \$3,890 by May 1. Add \$110 to stay '
              'on track.',
          actions: [
            LedgerButton.filled('Add \$110', onPressed: () {}),
            LedgerButton('Add money', icon: LucideIcons.plus, onPressed: () {}),
          ],
        ),
        (wide, theme) {
          expect(find.text('BEHIND'), findsOneWidget);
          expect(_style(t, 'BEHIND').color, theme.textSecondary);
          final note = _style(
            t,
            find
                .textContaining('At \$150')
                .evaluate()
                .map((e) => (e.widget as Text).data!)
                .first,
          );
          expect(note.fontSize, 22);
          expect(note.fontSize! * note.height!, closeTo(27, .01));
          // `.goal-memo`: 18 above its label, 20 at its sides.
          final slip = t.getRect(find.byType(LedgerMemoSlip));
          final label = t.getRect(find.text('BEHIND'));
          expect(label.top - slip.top, 18);
          expect(label.left - slip.left, 20);
          // The acts 10 apart.
          final a = t.getRect(find.byType(LedgerButton).first);
          final b = t.getRect(find.byType(LedgerButton).last);
          if (a.top == b.top) expect(b.left - a.right, 10);
        },
      );
    });
  });

  group('LedgerFrozenBanner', () {
    testWidgets('a phone stacks it; the desktop sets Unfreeze beside the '
        'head and the effects side by side', (t) async {
      var unfrozen = 0;
      await _everywhere(
        t,
        LedgerFrozenBanner(
          title: 'Frozen today at 7:40 PM',
          text: 'Nothing is cancelled. Unfreeze it any time.',
          effects: const [_declined, _goesThrough],
          actionLabel: 'Unfreeze card',
          onActionPressed: () => unfrozen++,
          actionKey: const ValueKey('unfreeze'),
        ),
        (wide, theme) {
          final slip = t.getRect(find.byType(LedgerFrozenBanner));
          final act = t.getRect(find.byType(LedgerButton));
          final title = t.getRect(find.text('Frozen today at 7:40 PM'));
          final declined = t.getRect(find.text('Declined'));
          final through = t.getRect(find.text('Still goes through'));
          expect(_style(t, 'Frozen today at 7:40 PM').fontSize, 22);
          if (wide) {
            // `.frozen-banner` from 1024: padding 18 22 8.
            expect(act.right, closeTo(slip.right - 22, .5));
            expect(act.top, lessThan(title.bottom));
            expect(declined.top, through.top);
          } else {
            // `.fb-btn`: the slip's width inside its 16.
            expect(act.width, closeTo(slip.width - 32, .5));
            // The live notice's first `.effect` stands 73 under its top:
            // 16, the head, its 4, the effects' 6 and then their rule.
            expect(
              t.getRect(find.byType(LedgerEffect).first).top - slip.top,
              closeTo(73, .5),
            );
            expect(act.top, greaterThan(through.bottom));
            expect(through.top, greaterThan(declined.bottom));
          }
          expect(
            t.getSemantics(find.text('Frozen today at 7:40 PM')),
            isSemantics(isHeader: true),
          );
        },
      );
      await t.tap(find.text('Unfreeze card'));
      expect(unfrozen, 1);
      // A walkthrough's key lands on the button.
      await t.tap(find.byKey(const ValueKey('unfreeze')));
      expect(unfrozen, 2);
    });
  });

  group('LedgerDialogLead and LedgerEffects', () {
    testWidgets('the lead in the serif at 22, a hairline between effects', (
      t,
    ) async {
      await _everywhere(
        t,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerDialogLead(
              'Freezing stops the card, not the account.\n'
              'Unfreeze it any time.',
            ),
            LedgerEffects(children: [_declined, _goesThrough]),
          ],
        ),
        (wide, theme) {
          final lead = _style(
            t,
            'Freezing stops the card, not the account.\nUnfreeze it any time.',
          );
          expect(lead.fontSize, 22);
          expect(lead.fontSize! * lead.height!, closeTo(27, .01));
          // `.dialog-lead`: 12 above its words, 4 under.
          final box = t.getRect(find.byType(LedgerDialogLead));
          final words = t.getRect(find.textContaining('Freezing stops'));
          expect(words.top - box.top, 12);
          expect(box.bottom - words.bottom, 4);
          // `.effects`: 6 under the lead; each effect 12 + 12 round its
          // words, a 1 px hairline between the two and none under the last.
          final effects = find.byType(LedgerEffect);
          final one = t.getRect(effects.first);
          final two = t.getRect(effects.last);
          expect(one.top - box.bottom, 6);
          expect(two.top - one.bottom, 1);
          expect(t.getRect(find.byType(LedgerEffects)).bottom, two.bottom);
        },
      );
    });
  });

  group('LedgerCardDetails', () {
    testWidgets('the number spread across, expiry, CVC and name under a '
        'rule', (t) async {
      await _everywhere(
        t,
        const LedgerCardDetails(
          number: _cardNumber,
          expiry: '09/29',
          cvc: '317',
          name: 'Maren Holt',
        ),
        (wide, theme) {
          expect(_spoken(t), [
            'CARD NUMBER',
            '4242 4242 4242 7730',
            'EXPIRES',
            '09/29',
            'CVC',
            '317',
            'NAME ON CARD',
            'Maren Holt',
          ]);
          expect(_style(t, '7730').fontSize, 21);
          expect(_style(t, '317').fontSize, 16);
          // `.cd-num`: space-between, the last group at the inner edge.
          final panel = t.getRect(find.byType(LedgerCardDetails));
          expect(
            t.getRect(find.text('7730')).right,
            closeTo(panel.right - 18, .5),
          );
          expect(t.getRect(find.text('CARD NUMBER')).top - panel.top, 18);
        },
      );
    });
  });

  group('LedgerDoneHead', () {
    testWidgets('the green meta, the title ending in its green italic', (
      t,
    ) async {
      await _everywhere(
        t,
        const LedgerDoneHead(
          meta: 'Transfer sent · 7:40 PM',
          title: '\$500.00 is on its way to',
          emphasis: 'Savings',
        ),
        (wide, theme) {
          expect(_style(t, 'TRANSFER SENT · 7:40 PM').color, theme.accent);
          final title = _style(t, '\$500.00 is on its way to Savings');
          expect(title.fontSize, wide ? 44 : 32);
          expect(title.fontSize! * title.height!, closeTo(wide ? 48 : 36, .01));
          expect(
            _node(t, '\$500.00 is on its way to Savings'),
            isSemantics(isHeader: true),
          );
        },
      );
    });
  });

  group('LedgerSplitTicket', () {
    testWidgets('two even halves torn apart, theirs on the wash', (t) async {
      await _everywhere(
        t,
        const LedgerSplitTicket(
          start: 'Cinema Lumen · Mon, Oct 26',
          end: 'Total \$28.00',
          mine: LedgerSplitHalf(
            name: 'Maren Holt',
            initials: 'MH',
            note: 'You paid',
            amount: 14,
          ),
          theirs: LedgerSplitHalf(
            name: 'Jonah Reyes',
            initials: 'JR',
            note: 'Owes you',
            amount: 14,
          ),
        ),
        (wide, theme) {
          expect(find.text('CINEMA LUMEN · MON, OCT 26'), findsOneWidget);
          expect(find.text('TOTAL \$28.00'), findsOneWidget);
          expect(find.byType(LedgerFigure), findsNWidgets(2));
          final mine = t.getRect(find.text('Maren Holt'));
          final theirs = t.getRect(find.text('Jonah Reyes'));
          final ticket = t.getRect(find.byType(LedgerSplitTicket));
          // `.half`: 16 in; the perforation 18 wide between halves of one
          // share.
          expect(mine.left - ticket.left, 16);
          expect(
            theirs.left - ticket.left,
            closeTo((ticket.width - 18) / 2 + 18 + 16, .5),
          );
          expect(find.byType(LedgerPerforation), findsOneWidget);
          final monograms = t
              .widgetList<LedgerMonogram>(find.byType(LedgerMonogram))
              .toList();
          expect(monograms.last.tone, LedgerMonogramTone.moneyIn);
        },
      );
    });
  });

  group('LedgerSavedAfter', () {
    testWidgets('the sum after on the leader, the green gauge, how it adds '
        'up', (t) async {
      await _everywhere(
        t,
        const LedgerSavedAfter(
          value: '\$2,950 · 74%',
          ratio: 2950 / 4000,
          subtitle: '\$2,840 saved + \$110',
          trailingSubtitle: 'of \$4,000',
        ),
        (wide, theme) {
          expect(find.text('Saved after'), findsOneWidget);
          expect(_style(t, '\$2,950 · 74%').fontSize, 13);
          final gauge = t.widget<LedgerGauge>(find.byType(LedgerGauge));
          expect(gauge.tone, LedgerGaugeTone.green);
          expect(gauge.tick, isFalse);
          // `.add-after`: 14 inside a rule above and below.
          final box = t.getRect(find.byType(LedgerSavedAfter));
          expect(t.getRect(find.text('Saved after')).top - box.top, 1 + 14);
          expect(
            box.bottom - t.getRect(find.text('of \$4,000')).bottom,
            14 + 1,
          );
        },
      );
    });
  });

  group('LedgerBeforeRow', () {
    testWidgets('the dashed box, the title in the second ink', (t) async {
      await _everywhere(
        t,
        const LedgerBeforeRow(
          title: 'Saved before Jun 1',
          value: LedgerAmount(790, tone: LedgerTone.moneyIn, showSign: true),
          subtitle: '3 contributions',
        ),
        (wide, theme) {
          final title = _style(t, 'Saved before Jun 1');
          expect(title.color, theme.textSecondary);
          expect(title.fontWeight, FontWeight.w500);
          expect(
            t.getSize(
              find.descendant(
                of: find.byType(LedgerBeforeRow),
                matching: find.byWidgetPredicate(
                  (w) => w is SizedBox && w.width == 40 && w.height == 44,
                ),
              ),
            ),
            const Size(40, 44),
          );
          expect(find.text('3 contributions'), findsOneWidget);
        },
      );
    });
  });
}
