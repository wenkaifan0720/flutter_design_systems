// Check wheel rows, table figures, chips and calendar cells as the reader
// increases the text scale on a narrow screen.
import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : brutalRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _pump(WidgetTester t, Widget child, double scale) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: BrutalHost(brightness: Brightness.light, child: page!),
      ),
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.all(BrutalSpacing.large),
          child: SizedBox(width: 342, child: child),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester t, String text) =>
    t.renderObject<RenderParagraph>(find.text(text).first);

/// The size [text] is laid out at, against its size at 1x.
double _scale(WidgetTester t, String text) {
  final p = _paragraph(t, text);
  return p.textScaler.scale(p.text.style!.fontSize!) / p.text.style!.fontSize!;
}

/// [text] on one line, every character laid out, not cut by its box.
void _whole(WidgetTester t, String text, {Rect? inside}) {
  final p = _paragraph(t, text);
  expect(p.didExceedMaxLines, isFalse, reason: text);
  expect(
    p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    ),
    hasLength(1),
    reason: '$text on one line',
  );
  expect(
    p.size.width,
    greaterThanOrEqualTo(p.getMaxIntrinsicWidth(double.infinity) - 0.5),
    reason: text,
  );
  if (inside != null) {
    final rect = t.getRect(find.text(text).first);
    expect(rect.top, greaterThanOrEqualTo(inside.top - 0.5), reason: text);
    expect(rect.bottom, lessThanOrEqualTo(inside.bottom + 0.5), reason: text);
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final scale in const [1.0, 2.0, 3.0]) {
    final at = '${(scale * 100).round()}%';

    group('at $at', () {
      testWidgets('the time wheels keep their rows, as Cupertino\'s do', (
        t,
      ) async {
        await _pump(
          t,
          BrutalTimePicker(
            value: const BrutalTime(hour: 19, minute: 30),
            onChanged: (_) {},
          ),
          scale,
        );
        expect(t.takeException(), isNull);
        expect(_scale(t, '19'), 1);
        // The chosen row and its neighbours read whole, one over another.
        // The hours are the first column (the minutes have a 20 too).
        final rows = [
          for (final h in ['18', '19', '20']) t.getRect(find.text(h).first),
        ];
        for (final h in ['18', '19', '20', '30']) {
          _whole(t, h);
        }
        expect(rows[0].bottom, lessThanOrEqualTo(rows[1].top));
        expect(rows[1].bottom, lessThanOrEqualTo(rows[2].top));
      });

      testWidgets('a count wheel keeps its rows, as Cupertino\'s do', (
        t,
      ) async {
        await _pump(
          t,
          BrutalWheelPicker<int>(
            items: const [1, 2, 3, 4, 5],
            value: 2,
            labelOf: (n) => n == 1 ? '1 ticket' : '$n tickets',
            onChanged: (_) {},
          ),
          scale,
        );
        expect(t.takeException(), isNull);
        expect(_scale(t, '2 tickets'), 1);
        for (final row in ['1 ticket', '2 tickets', '3 tickets']) {
          _whole(t, row);
        }
        expect(
          t.getRect(find.text('1 ticket')).bottom,
          lessThanOrEqualTo(t.getRect(find.text('2 tickets')).top),
        );
        expect(
          t.getRect(find.text('2 tickets')).bottom,
          lessThanOrEqualTo(t.getRect(find.text('3 tickets')).top),
        );
      });

      testWidgets('a button group\'s words grow to twice their size and stay '
          'in its cells', (t) async {
        await _pump(
          t,
          BrutalButtonGroup(
            semanticLabel: 'Zoom',
            items: [
              BrutalButtonGroupItem(
                icon: LucideIcons.minus,
                tooltip: 'Zoom out',
                onPressed: () {},
              ),
              BrutalButtonGroupItem(label: '100%', onPressed: () {}),
              BrutalButtonGroupItem(
                icon: LucideIcons.plus,
                tooltip: 'Zoom in',
                onPressed: () {},
              ),
            ],
          ),
          scale,
        );
        expect(t.takeException(), isNull);
        expect(_scale(t, '100%'), scale > 2 ? 2 : scale);
        _whole(t, '100%', inside: t.getRect(find.byType(BrutalButtonGroup)));
      });

      testWidgets('the calendar\'s days grow to twice their size and stay '
          'in their cells', (t) async {
        await _pump(
          t,
          BrutalCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            selectedDate: DateTime(2026, 11, 20),
            currentDate: DateTime(2026, 11, 18),
            onDateChanged: (_) {},
          ),
          scale,
        );
        expect(t.takeException(), isNull);
        expect(_scale(t, '12'), scale > 2 ? 2 : scale);
        // Seven days to a row: a two-digit day stays clear of its
        // neighbours.
        final days = [
          for (final d in ['10', '11', '12', '13', '14'])
            t.getRect(find.text(d)),
        ];
        for (var i = 0; i + 1 < days.length; i++) {
          expect(
            days[i].right,
            lessThanOrEqualTo(days[i + 1].left),
            reason: '${10 + i} and ${11 + i}',
          );
        }
        for (final d in ['10', '20', '30']) {
          _whole(t, d);
        }
      });

      testWidgets('a table\'s times and prices never break', (t) async {
        await _pump(
          t,
          const BrutalTable(
            columns: [
              BrutalTableColumn('Night', flex: 3),
              BrutalTableColumn('Doors'),
              BrutalTableColumn('Price', numeric: true),
            ],
            rows: [
              ['Northern Lights Revue', '19:30', '£18.00'],
              ['Late set', '22:00', '£12.50'],
            ],
          ),
          scale,
        );
        expect(t.takeException(), isNull);
        for (final figure in ['19:30', '£18.00', '22:00', '£12.50', 'PRICE']) {
          _whole(t, figure);
        }
        // A name wraps between its words, never inside one.
        final name = _paragraph(t, 'Northern Lights Revue');
        for (final word in RegExp(r'\S+').allMatches('Northern Lights Revue')) {
          expect(
            name.getBoxesForSelection(
              TextSelection(baseOffset: word.start, extentOffset: word.end),
            ),
            hasLength(1),
            reason: word.group(0),
          );
        }
      });

      testWidgets('a chip grows with its words, as Material\'s filter chip '
          'does', (t) async {
        await _pump(
          t,
          Wrap(
            spacing: BrutalSpacing.small,
            runSpacing: BrutalSpacing.small,
            children: [
              for (final l in ['Planning', 'Review', 'Fieldwork'])
                BrutalChip(
                  label: l,
                  selected: l == 'Review',
                  onSelected: (_) {},
                ),
            ],
          ),
          scale,
        );
        expect(t.takeException(), isNull);
        // The chip's ruled cell (its press reaches 48 round it).
        Finder cell(int i) => find
            .descendant(
              of: find.byType(BrutalChip).at(i),
              matching: find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == 'AnimatedBrutalSurface',
              ),
            )
            .first;
        for (final (i, l) in ['Planning', 'Review', 'Fieldwork'].indexed) {
          final rect = t.getRect(cell(i));
          expect(rect.height, greaterThanOrEqualTo(BrutalChip.height));
          if (scale == 1) expect(rect.height, BrutalChip.height);
          // Clear of its 2 px rules.
          _whole(t, l, inside: rect.deflate(2));
        }
      });
    });
  }
}
