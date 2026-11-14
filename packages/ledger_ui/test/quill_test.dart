// Quill's screens hold what design6 asks of an app on the look: nothing overflows at 390, 768 and 1440, by day and by
// night; no words under 11 px; at 390 the entry's act spans the content; and every section keeps its keylines and one
// height per row of controls (P).
//
// Keylines are read twice. ui_core's DesignKeylineCheck reads Ledger's regions (the page, the bars, each LedgerSection,
// each LedgerSlip), less what it misreads ([_misread], each with its reason); and this file's own ruler:
// a section's things are grouped into rows (things whose heights overlap), and each row's first thing starts on a
// leading keyline and its last glyph, control or sum ends on a trailing one. A glyph is measured by its ink, not its box
// (Lucide draws inside a margin of its 24 grid); a ring, a disc or a mark by its paint; words by their lines. A section
// may start its rows on its own edge and on one column after a lead (the words beside a glyph or a mark); its glyphs,
// controls and sums end on its other edge. Controls that share a row share a height. Slips are their own printed
// composition and are measured as one thing.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_core/alignment.dart';

import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/quill/entry.dart';
import '../example/lib/kit_gallery/quill/quill.dart';
import '../example/lib/kit_gallery/quill/register.dart';

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

typedef _Screen = ({String name, QuillPage page, Widget? pushed});

final List<_Screen> _screens = [
  (name: 'overview', page: QuillPage.overview, pushed: null),
  (name: 'home', page: QuillPage.home, pushed: null),
  (name: 'register', page: QuillPage.register, pushed: null),
  (name: 'settings', page: QuillPage.settings, pushed: null),
  (name: 'entry', page: QuillPage.overview, pushed: const QuillEntryPage()),
  (
    name: 'receipt',
    page: QuillPage.register,
    pushed: QuillReceiptPage(tx: kitRecent.first),
  ),
];

/// What ui_core's keyline check (second pass, fdd4fc74cc) still misreads on Quill, by the words of its report, each
/// with why it is not a fault. Told to the coordinator; not a to-do.
const Map<String, String> _misread = {
  // Entry and receipt from 1440: the crumb (the source's `.crumb`) hangs 4 into the gutter so its 15 px chevron's ink,
  // 5 inside its box, meets the keyline (57 against 56); the check reads a leading icon by its box (52).
  'an icon starts 52 px in; the leading keyline is 56 px in': "the crumb's chevron hangs 4 so its ink meets the keyline; the check reads its box",
  // Register at 390: the filter chips (All, Money in, Money out, Pending) are packed from the start, as the source's
  // `.filters` are; the row is one run over two thirds of the page, so the check anchors it at both ends.
  'page: a button "Pending" ends ': 'filter chips packed from the start: one run over two thirds read as anchored at both ends',
};

const Size _phone = Size(390, 844);
const Size _tablet = Size(768, 1024);
const Size _desktop = Size(1440, 900);

Future<void> _open(
  WidgetTester t,
  _Screen s,
  Size size, {
  QuillAppearance appearance = QuillAppearance.light,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    QuillApp(
      key: UniqueKey(),
      initialPage: s.page,
      initialAppearance: appearance,
    ),
  );
  await t.pumpAndSettle();
  final pushed = s.pushed;
  if (pushed != null) {
    t.state<QuillFrameState>(find.byType(QuillFrame)).push(pushed);
    await t.pumpAndSettle();
  }
}

/// The empty part of Lucide's 24 grid on each side of a glyph's ink (its stroke's half counted as ink).
final Map<int, double> _margins = {
  LucideIcons.chevronRight.codePoint: 8,
  LucideIcons.chevronLeft.codePoint: 8,
  LucideIcons.chevronDown.codePoint: 5,
  LucideIcons.chevronUp.codePoint: 5,
  LucideIcons.check.codePoint: 3,
  LucideIcons.x.codePoint: 5,
  LucideIcons.arrowRight.codePoint: 4,
  LucideIcons.plus.codePoint: 4,
  LucideIcons.minus.codePoint: 4,
};

/// One thing a ruler reads: where it stands, and whether its end is a trailing keyline's business.
typedef _Thing = ({Rect rect, bool ends, String what});

bool _visible(RenderObject o) {
  for (RenderObject? r = o; r != null; r = r.parent) {
    if (r is RenderOpacity && r.opacity == 0) return false;
    if (r is RenderAnimatedOpacity && r.opacity.value == 0) return false;
    if (r is RenderOffstage && r.offstage) return false;
  }
  return true;
}

bool _isIcon(RenderParagraph p) =>
    p.text.style?.fontFamily?.toLowerCase().contains('lucide') ?? false;

/// The things in [root], slips and drawn marks each as one.
List<_Thing> _things(WidgetTester t, RenderBox root) {
  final out = <_Thing>[];
  final slips = <RenderObject>{
    for (final e in find.byType(LedgerSlip).evaluate()) e.renderObject!,
    for (final e in find.byType(LedgerReceipt).evaluate()) e.renderObject!,
  };
  final amounts = <RenderObject>{
    for (final e in find.byType(LedgerAmount).evaluate()) e.renderObject!,
  };
  // A switch and an icon button end their row; a button stands where its row starts it, and so does a select from 600
  // (at its measure, the start of its cell), read as one control as ui_core reads a control by its face.
  final controls = <RenderObject, bool>{
    for (final type in const [LedgerSwitch, LedgerIconButton])
      for (final e in find.byType(type).evaluate()) e.renderObject!: true,
    for (final e in find.byType(LedgerButton).evaluate())
      e.renderObject!: false,
    for (final e in find.byWidgetPredicate((w) => w is LedgerSelect).evaluate())
      e.renderObject!: false,
  };
  Rect global(RenderBox b, Rect r) =>
      MatrixUtils.transformRect(b.getTransformTo(null), r);
  void visit(RenderObject o, {bool inAmount = false}) {
    if (!_visible(o)) return;
    if (o is RenderBox && o.hasSize && slips.contains(o)) {
      out.add((
        rect: global(o, Offset.zero & o.size),
        ends: false,
        what: 'slip',
      ));
      return;
    }
    if (o is RenderBox && o.hasSize && controls.containsKey(o)) {
      out.add((
        rect: global(o, Offset.zero & o.size),
        ends: controls[o]!,
        what: 'control',
      ));
      return;
    }
    final amount = inAmount || amounts.contains(o);
    if (o is RenderParagraph) {
      final text = o.text.toPlainText();
      if (text.trim().isEmpty) return;
      if (_isIcon(o)) {
        final size = o.size.height;
        final m = (_margins[text.runes.first] ?? 2) * size / 24;
        final box = global(o, Offset.zero & o.size);
        out.add((
          rect: Rect.fromLTRB(
            box.left + m,
            box.top + m,
            box.right - m,
            box.bottom - m,
          ),
          ends: true,
          what: 'glyph',
        ));
        return;
      }
      final lines = <double, Rect>{};
      for (final b in o.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )) {
        final r = b.toRect();
        lines.update(
          r.top.roundToDouble(),
          (l) => l.expandToInclude(r),
          ifAbsent: () => r,
        );
      }
      for (final r in lines.values) {
        out.add((
          rect: global(o, r),
          ends: amount,
          what: amount ? 'sum' : 'words',
        ));
      }
      return;
    }
    if (o is RenderDecoratedBox && o.hasSize) {
      final d = o.decoration;
      final drawn = d is BoxDecoration && (d.color != null || d.border != null);
      final s = o.size;
      if (drawn && s.width <= 64 && s.height <= 64 && s.width >= 8) {
        // A mark, a ring, a disc: its paint, its glyph inside it.
        out.add((rect: global(o, Offset.zero & s), ends: false, what: 'mark'));
        return;
      }
    }
    if (o is RenderBox &&
        o.hasSize &&
        o.size.height <= 2 &&
        o.size.width >= 24) {
      // A rule: a hairline across the row (a ColoredBox's or a coloured DecoratedBox's).
      final d = o is RenderDecoratedBox ? o.decoration : null;
      final ruled =
          '${o.runtimeType}' == '_RenderColoredBox' ||
          (d is BoxDecoration && d.color != null);
      if (ruled) {
        out.add((
          rect: global(o, Offset.zero & o.size),
          ends: false,
          what: 'rule',
        ));
        return;
      }
    }
    o.visitChildren((c) => visit(c, inAmount: amount));
  }

  visit(root);
  return out;
}

/// [things] in rows: things whose heights overlap stand in one.
List<List<_Thing>> _rows(List<_Thing> things) {
  final parent = List<int>.generate(things.length, (i) => i);
  int find(int i) => parent[i] == i ? i : parent[i] = find(parent[i]);
  for (var i = 0; i < things.length; i++) {
    for (var j = i + 1; j < things.length; j++) {
      final a = things[i].rect, b = things[j].rect;
      final overlap =
          (a.bottom < b.bottom ? a.bottom : b.bottom) -
          (a.top > b.top ? a.top : b.top);
      // Two hairlines on one line overlap by their whole 1 px.
      final thin = (a.height < b.height ? a.height : b.height) / 2;
      if (overlap > (thin < 1 ? thin : 1)) parent[find(i)] = find(j);
    }
  }
  final rows = <int, List<_Thing>>{};
  for (var i = 0; i < things.length; i++) {
    rows.putIfAbsent(find(i), () => []).add(things[i]);
  }
  return rows.values.toList();
}

/// Rounds to the half pixel a ruler reads.
double _r(double x) => (x * 2).roundToDouble() / 2;

/// [xs] as a ruler groups them: lines within 1.5 px of each other are one (a capital's side bearing, a tracked label's
/// spacing); each group named by its first.
List<double> _lines(Iterable<double> xs) {
  final sorted = xs.toList()..sort();
  final out = <double>[];
  for (final x in sorted) {
    if (out.isEmpty || x - out.last > 1.5) out.add(x);
  }
  return out;
}

/// A section's leading and trailing keylines, relative to its own edges.
({Set<double> leading, Set<double> trailing, List<String> notes}) _keylines(
  WidgetTester t,
  Element section,
) {
  final box = section.renderObject! as RenderBox;
  final edge = box.localToGlobal(Offset.zero).dx;
  final width = box.size.width;
  final leading = <double>{};
  final trailing = <double>{};
  final notes = <String>[];
  for (final row in _rows(_things(t, box))) {
    row.sort((a, b) => a.rect.left.compareTo(b.rect.left));
    final first = row.first;
    leading.add(_r(first.rect.left - edge));
    final last = row.reduce((a, b) => a.rect.right >= b.rect.right ? a : b);
    // A lone thing stands where its row starts it; the last of several ends on the edge when it is a glyph, a
    // switch, an icon button or a sum.
    if (row.length > 1 && last.ends) {
      final at = _r(edge + width - last.rect.right);
      trailing.add(at);
      if (at.abs() > 1) {
        notes.add(
          '${last.what} ends ${at}px short at y=${last.rect.top.round()}',
        );
      }
    }
  }
  return (leading: leading, trailing: trailing, notes: notes);
}

String _sectionName(Element e) {
  final head = (e.widget as LedgerSection).head;
  return head is LedgerHead ? head.label : '${head.runtimeType}';
}

void main() {
  setUpAll(_loadFonts);
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  for (final s in _screens) {
    group(s.name, () {
      testWidgets('lays out clean at 390, 768 and 1440, by day and by night', (
        t,
      ) async {
        for (final size in const [_phone, _tablet, _desktop]) {
          for (final a in const [QuillAppearance.light, QuillAppearance.dark]) {
            await _open(t, s, size, appearance: a);
            expect(
              t.takeException(),
              isNull,
              reason: '${size.width.round()} wide, ${a.name}',
            );
          }
        }
      });

      testWidgets('sets no words under 11 px', (t) async {
        final small = <String>{};
        for (final size in const [_phone, _desktop]) {
          await _open(t, s, size);
          // The seal's ring lettering is engraving, read as one picture by its spoken label (DECISIONS.md).
          final engraved = find.descendant(
            of: find.byType(LedgerSeal),
            matching: find.byType(RichText),
          );
          final exempt = {for (final e in engraved.evaluate()) e.renderObject};
          for (final e in find.byType(RichText).evaluate()) {
            final p = e.renderObject! as RenderParagraph;
            if (exempt.contains(p) ||
                _isIcon(p) ||
                p.text.toPlainText().trim().isEmpty ||
                !_visible(p)) {
              continue;
            }
            p.text.visitChildren((span) {
              if (span is TextSpan && (span.text?.trim().isNotEmpty ?? false)) {
                final px = p.textScaler.scale(
                  span.style?.fontSize ?? p.text.style?.fontSize ?? 14,
                );
                if (px < 11) {
                  small.add('"${span.text}" ${px}px at ${size.width.round()}');
                }
              }
              return true;
            });
          }
        }
        expect(small, isEmpty, reason: small.join('\n'));
      });

      testWidgets('keeps every section on its keylines at 390 and 1440', (
        t,
      ) async {
        final report = <String>[];
        final problems = <String>[];
        for (final size in const [_phone, _desktop]) {
          await _open(t, s, size);
          for (final e in find.byType(LedgerSection).evaluate()) {
            final k = _keylines(t, e);
            final name = '${s.name} ${size.width.round()} "${_sectionName(e)}"';
            final leading = _lines(k.leading);
            report.add('$name leading $leading trailing ${_lines(k.trailing)}');
            if (leading.first.abs() > 1.5) {
              problems.add('$name: no row starts on its edge ($leading)');
            }
            if (leading.length > 2) {
              problems.add(
                '$name: rows start on ${leading.length} lines $leading',
              );
            }
            for (final n in k.notes) {
              problems.add('$name: $n');
            }
          }
        }
        // Every section's keylines go with a failure, so a fix reads the whole page.
        expect(
          problems,
          isEmpty,
          reason: [...problems, '', ...report].join('\n'),
        );
      });

      testWidgets('sets the controls that share a row at one height', (
        t,
      ) async {
        final uneven = <String>[];
        for (final size in const [_phone, _desktop]) {
          await _open(t, s, size);
          final boxes = <_Thing>[
            for (final type in const [
              LedgerTextField,
              LedgerSelect<String>,
              LedgerSelect<LedgerDensity>,
              LedgerButton,
              LedgerIconButton,
              LedgerSwitch,
            ])
              for (final e in find.byType(type).evaluate())
                if (e.renderObject case final RenderBox b when b.hasSize)
                  (
                    rect: b.localToGlobal(Offset.zero) & b.size,
                    ends: true,
                    what: '$type',
                  ),
          ];
          for (final row in _rows(boxes)) {
            row.sort((a, b) => a.rect.left.compareTo(b.rect.left));
            // Neighbours on one line: no wider apart than a field pair's gap (columns stand 56 apart).
            for (var i = 1; i < row.length; i++) {
              final a = row[i - 1], b = row[i];
              if (b.rect.left - a.rect.right > 32) continue;
              if (_r(a.rect.height) != _r(b.rect.height)) {
                uneven.add(
                  '${s.name} ${size.width.round()}: ${a.what} ${a.rect.height}, ${b.what} ${b.rect.height}',
                );
              }
            }
          }
        }
        expect(uneven, isEmpty, reason: uneven.join('\n'));
      });

      testWidgets("holds ui_core's keyline check at 390 and 1440", (t) async {
        final problems = <String>[];
        // Tall enough that the whole page is laid out and painted: the check reads its pixels.
        for (final size in const [Size(390, 3200), Size(1440, 2400)]) {
          await _open(t, s, size);
          final report =
              await const DesignKeylineCheck(
                look: 'Ledger',
                pixelRatio: 2,
              ).check(
                t.element(find.byType(LedgerScreen).last),
                runAsync: t.runAsync,
              );
          problems.addAll([
            for (final p in report.problems)
              if (!_misread.keys.any(p.contains)) '${size.width.round()}: $p',
          ]);
        }
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    });
  }

  // design6 P (11-11 noon, the user on :8506: "some dropdown spans the entire width"): from 600 a select stands at its
  // measure, at most LedgerLayout.fieldMeasure, never its column or the page; on a phone it spans its column. Its open
  // list hugs its options, never narrower than the select.
  testWidgets(
    'a select stands at its measure from 600 and spans its column on a phone',
    (t) async {
      final wrong = <String>[];
      for (final name in const ['entry', 'settings']) {
        final s = _screens.firstWhere((s) => s.name == name);
        for (final size in const [
          _phone,
          Size(600, 900),
          Size(1024, 768),
          _desktop,
          Size(1920, 1080),
        ]) {
          await _open(t, s, size);
          for (final e
              in find.byWidgetPredicate((w) => w is LedgerSelect).evaluate()) {
            final label = (e.widget as LedgerSelect).label;
            final slot = (e.renderObject! as RenderBox).size.width;
            final face = t.getRect(
              find
                  .descendant(
                    of: find.byWidget(e.widget),
                    matching: find.byType(LedgerPressable),
                  )
                  .first,
            );
            final at = '$name ${size.width.round()} "$label"';
            if (size.width < LedgerLayout.measuredFrom) {
              if ((face.width - slot).abs() > .5) {
                wrong.add('$at: ${face.width} of its column $slot');
              }
            } else if (face.width > LedgerLayout.fieldMeasure + .5) {
              wrong.add(
                '$at: ${face.width} wide (at most ${LedgerLayout.fieldMeasure})',
              );
            }
          }
        }
      }
      expect(wrong, isEmpty, reason: wrong.join('\n'));
    },
  );

  testWidgets("a select's open list hugs its options", (t) async {
    await _open(t, _screens.firstWhere((s) => s.name == 'settings'), _desktop);
    final select = find.byWidgetPredicate(
      (w) => w is LedgerSelect && w.label == 'Currency',
    );
    final anchor = find
        .descendant(of: select, matching: find.byType(LedgerPressable))
        .first;
    final face = t.getRect(anchor);
    await t.tap(anchor);
    await t.pumpAndSettle();
    final list = t.getRect(
      find
          .ancestor(
            of: find.text('Pound sterling'),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    );
    expect(list.width, greaterThanOrEqualTo(face.width - .5));
    expect(list.width, lessThanOrEqualTo(LedgerLayout.fieldMeasure + .5));
  });

  testWidgets("at 390 the entry's act spans the content", (t) async {
    await _open(t, _screens.firstWhere((s) => s.name == 'entry'), _phone);
    final save = t.getRect(find.widgetWithText(LedgerButton, 'Save entry'));
    expect(
      save.width,
      greaterThanOrEqualTo(_phone.width - 2 * LedgerSpacing.s24 - .5),
    );
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
