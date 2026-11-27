// By night the ink act's word sets a cut heavier (an optical match for the
// light words beside it), and a heavier cut sets wider. The act keeps the
// room it takes by day: its pill stands as wide, so nothing beside it moves
// when the theme turns (a docked band's caption that fit by day wrapped by
// night and the band stood 10 taller). Measured in the look's own faces: the
// test font draws every weight alike.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> _fonts() async {
  final manifest = (json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>).cast<Map<String, dynamic>>();
  for (final family in manifest) {
    final name = family['family'] as String;
    final fonts = (family['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final alias in [
      name,
      if (!name.startsWith('packages/')) 'packages/frosted_ui/$name',
    ]) {
      final loader = FontLoader(alias);
      for (final font in fonts) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  }
}

const _words = ['Transfer', 'Freeze', 'Switch task', 'Stop timer', 'OK'];
const _caption = 'To Jonah Reyes · arrives Thursday';

/// Each act's size, then the caption's, in [brightness].
Future<List<Size>> _room(WidgetTester tester, Brightness brightness) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          FrostedHost(brightness: brightness, child: page!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final w in _words) FrostedButton(w, onPressed: () {}),
            FrostedButton(
              'Transfer',
              onPressed: () {},
              size: FrostedButtonSize.small,
            ),
            // The docked band's caption beside its act: one line by day.
            SizedBox(
              width: 326,
              child: Row(
                children: [
                  const Expanded(child: Text(_caption)),
                  FrostedButton('Transfer', onPressed: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  for (final w in _words) {
    // The heavier word is never cut short where its own weight fits.
    final paragraph = tester.renderObject<RenderParagraph>(find.text(w).first);
    expect(paragraph.didExceedMaxLines, isFalse, reason: w);
  }
  return [
    for (final e in find.byType(FrostedButton).evaluate())
      (e.renderObject! as RenderBox).size,
    tester.getSize(find.text(_caption)),
  ];
}

FontWeight? _weightOf(WidgetTester tester, String word) =>
    tester.widget<Text>(find.text(word).first).style?.fontWeight;

void main() {
  setUpAll(_fonts);

  testWidgets('an ink act takes the room by night it takes by day', (
    tester,
  ) async {
    final day = await _room(tester, Brightness.light);
    final dayWeight = _weightOf(tester, 'Transfer')!;
    final night = await _room(tester, Brightness.dark);
    // The word is still a cut heavier by night ...
    expect(_weightOf(tester, 'Transfer'), FontWeight(dayWeight.value + 100));
    // ... in the room it takes by day.
    expect(night, day);
  });

  testWidgets('the night word sets wider than the day word', (tester) async {
    // The guard on the test itself: in the test font every weight sets alike
    // and the room above would hold with or without the fix.
    double width(FontWeight weight) {
      final p = TextPainter(
        text: TextSpan(
          text: 'Switch task',
          style: TextStyle(
            fontFamily: 'packages/frosted_ui/DMSans',
            fontSize: 14,
            fontWeight: weight,
            fontVariations: [FontVariation.weight(weight.value.toDouble())],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    expect(width(FontWeight.w700), greaterThan(width(FontWeight.w600) + 1));
  });
}
