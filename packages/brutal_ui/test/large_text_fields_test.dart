// The stepper and the date field at 100% and 200% text, by day and night,
// left to right and right to left (11-18, a form's Due date and Estimate):
// the stepper's number cell holds its widest value with its figures clear of
// the rules, its cells as tall as the number; the date field shows the
// whole date, taking a second line rather than cutting it.
import 'dart:convert';

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, TextField;
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

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  required double scale,
  required Brightness brightness,
  required TextDirection direction,
}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: BrutalHost(brightness: brightness, child: page!),
        ),
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

/// A cell of the stepper's row: a box that sets its width, the row its height.
final Finder _widthOnly = find.byWidgetPredicate(
  (w) => w is SizedBox && w.width != null && w.height == null,
);

void main() {
  setUpAll(_loadFonts);

  for (final scale in const [1.0, 2.0]) {
    for (final brightness in Brightness.values) {
      for (final direction in TextDirection.values) {
        final where =
            '${(scale * 100).round()}% ${brightness.name} ${direction.name}';

        testWidgets('the stepper holds its widest value at $where', (t) async {
          await _pump(
            t,
            BrutalStepper(
              value: 45,
              min: 5,
              max: 480,
              semanticLabel: 'Estimate',
              onChanged: (_) {},
            ),
            scale: scale,
            brightness: brightness,
            direction: direction,
          );
          final field = find.byType(TextField);
          final cell = find.ancestor(of: field, matching: _widthOnly).first;
          final style = t.widget<TextField>(field).style;
          final widest = TextPainter(
            text: TextSpan(text: '480', style: style),
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.linear(scale),
          )..layout();
          addTearDown(widest.dispose);
          // The widest value keeps at least 4 from the rules at both sides.
          expect(
            t.getSize(cell).width,
            greaterThanOrEqualTo(widest.width + 2 * 4),
            reason: where,
          );
          expect(
            t.getSize(cell).height,
            greaterThanOrEqualTo(widest.height + 2 * 4),
            reason: where,
          );
          // The step cells as tall as the number's cell: one row, one height.
          for (final icon in const [LucideIcons.minus, LucideIcons.plus]) {
            final step = find
                .ancestor(of: find.byIcon(icon), matching: _widthOnly)
                .first;
            expect(
              t.getSize(step).height,
              t.getSize(cell).height,
              reason: '$where $icon',
            );
          }
        });

        testWidgets('the date field shows the whole date at $where', (t) async {
          await _pump(
            t,
            BrutalDatePicker(
              label: 'Due date',
              value: DateTime(2026, 11, 20),
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
              onChanged: (_) {},
            ),
            scale: scale,
            brightness: brightness,
            direction: direction,
          );
          final date = find.text('Friday, 20 November 2026');
          expect(date, findsOneWidget, reason: where);
          final paragraph = t.renderObject<RenderParagraph>(date);
          expect(paragraph.didExceedMaxLines, isFalse, reason: where);
        });
      }
    }
  }
}
