// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/demos/charts.dart';
import '../example/lib/kit_gallery/simmer/simmer.dart';

Future<void> _show(
  WidgetTester tester, {
  SimmerScene? scene,
  SimmerPlace? place,
  SimmerPart? part,
  TextDirection direction = TextDirection.ltr,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SimmerApp(
      initialScene: scene,
      initialPlace: place ?? scene?.place ?? SimmerPlace.overview,
      parts: [?part],
      initialPart: part == null ? null : 0,
      initialDirection: direction,
      initialAppearance: direction == TextDirection.rtl
          ? SimmerAppearance.dark
          : SimmerAppearance.light,
      textScale: 2,
    ),
  );
  await tester.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );

Rect _letter(RenderParagraph paragraph, int offset) => paragraph
    .getBoxesForSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + 1),
    )
    .single
    .toRect();

void main() {
  setUpAll(() async {
    final manifest = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final family = entry['family'] as String;
      final loader = FontLoader(
        family.startsWith('packages/') ? family : glossRegisteredFamily(family),
      );
      for (final font
          in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'making the shopping list opens its real ingredients at ${width.toInt()}',
      (tester) async {
        await _show(tester, scene: SimmerScene.emptyList, width: width);
        expect(find.text('The list is clear'), findsOneWidget);
        await tester.tap(find.text('Plan more dinners'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Make the shopping list'));
        await tester.pumpAndSettle();
        expect(find.text('Make the shopping list'), findsNothing);
        expect(find.text('The list is clear'), findsNothing);
        expect(find.text('Orzo'), findsOneWidget);
        expect(find.text('White miso'), findsOneWidget);
        expect(find.text('The list has 6 dinners in it'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'the sparkline and its total stay together inside a narrow chart page',
    (tester) async {
      await _show(tester, part: (title: 'Charts', build: kitChartsDemo));
      final value = tester.getRect(find.text('18'));
      final line = tester.getRect(find.byType(GlossSparkline));
      expect(value.right, lessThanOrEqualTo(390 - GlossSpacing.regular));
      expect(value.left, greaterThanOrEqualTo(line.right));
      expect(line.center.dy, closeTo(value.center.dy, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dietary tags leave painted room above and below enlarged type', (
    tester,
  ) async {
    await _show(tester, scene: SimmerScene.recipe);
    for (final name in ['Vegetarian', 'Vegan', 'Dairy-free']) {
      final text = find.text(name).last;
      final tag = find
          .ancestor(of: text, matching: find.byType(GlossSurface))
          .first;
      final paragraph = _paragraph(tester, text);
      final glyphs = _letter(paragraph, name.indexOf(RegExp('[gy]')));
      final top = paragraph.localToGlobal(glyphs.topLeft).dy;
      final bottom = paragraph.localToGlobal(glyphs.bottomRight).dy;
      expect(top, greaterThan(tester.getTopLeft(tag).dy + 1), reason: name);
      expect(bottom, lessThan(tester.getBottomLeft(tag).dy - 1), reason: name);
    }
  });

  testWidgets(
    'a switch uses the same trailing column for time and diet filters',
    (tester) async {
      await _show(tester, scene: SimmerScene.filter);
      Finder row(String name) =>
          find.byWidgetPredicate((w) => w is GlossListTile && w.title == name);
      Finder toggle(String name) =>
          find.descendant(of: row(name), matching: find.byType(GlossSwitch));
      final title = find.descendant(
        of: row('Under 25 min'),
        matching: find.text('Under 25 min'),
      );
      final control = tester.getCenter(toggle('Under 25 min'));
      expect(control.dx, closeTo(tester.getCenter(toggle('Vegan')).dx, 1));
      expect(control.dy, closeTo(tester.getCenter(title).dy, 5));
    },
  );

  testWidgets('the whole servings label fits alongside or above its stepper', (
    tester,
  ) async {
    await _show(tester, scene: SimmerScene.recipe);
    final paragraph = _paragraph(tester, find.text('Servings'));
    expect(_letter(paragraph, 0).top, _letter(paragraph, 7).top);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the RTL account keeps the email domain on one line', (
    tester,
  ) async {
    await _show(
      tester,
      place: SimmerPlace.settings,
      direction: TextDirection.rtl,
    );
    final paragraph = _paragraph(tester, find.textContaining('example.com'));
    final content = paragraph.text.toPlainText(includeSemanticsLabels: false);
    final start = content.indexOf('example.com');
    final first = _letter(paragraph, start);
    final last = _letter(paragraph, start + 'example.com'.length - 1);
    expect(first.top, last.top);
    expect(first.left, lessThan(last.left));
  });

  testWidgets(
    'RTL search keeps the duration before its cuisine and quotes around the query',
    (tester) async {
      await _show(
        tester,
        scene: SimmerScene.search,
        direction: TextDirection.rtl,
      );
      final result = _paragraph(tester, find.textContaining('Italian').first);
      final metadata = result.text.toPlainText();
      final minutes = _letter(result, metadata.indexOf('min'));
      final number = _letter(result, metadata.indexOf('20'));
      expect(number.top, minutes.top);
      expect(number.left, lessThan(minutes.left));
      final cuisine = _letter(result, metadata.indexOf('Italian'));
      if (minutes.top == cuisine.top) {
        expect(minutes.left, lessThan(cuisine.left));
      }

      for (final query in ['quince', 'سفرجل']) {
        await tester.enterText(find.byType(EditableText), query);
        await tester.pumpAndSettle();
        final heading = _paragraph(tester, find.textContaining('Nothing for'));
        final text = heading.text.toPlainText();
        final open = _letter(heading, text.indexOf('“'));
        final close = _letter(heading, text.indexOf('”'));
        final first = _letter(heading, text.indexOf(query));
        final last = _letter(heading, text.indexOf(query) + query.length - 1);
        expect(open.top, close.top, reason: query);
        expect(open.right, lessThanOrEqualTo(first.left + 1), reason: query);
        expect(open.right, lessThanOrEqualTo(last.left + 1), reason: query);
        expect(
          close.left,
          greaterThanOrEqualTo(first.right - 1),
          reason: query,
        );
        expect(close.left, greaterThanOrEqualTo(last.right - 1), reason: query);
      }
    },
  );
}
