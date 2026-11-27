// The parts drawn round their words or a glyph grow with the reader's text size, face, words and glyph alike: a tag,
// a monogram, a glyph's token and a date's block stand as large as the row's words at 130% and 200%. A monogram
// beside the words that name it is decoration: a row led by one reads its title once.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> _pump(WidgetTester t, Widget part, {double scale = 1}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: FrostedHost(brightness: Brightness.light, child: page!),
      ),
      home: Align(alignment: Alignment.topLeft, child: part),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

void main() {
  final marks = <String, (Widget, Finder)>{
    'tag': (
      const FrostedTag('Reading', icon: FrostedGlyphs.check),
      find.byType(FrostedTag),
    ),
    'monogram': (
      const FrostedMonogram('Piranesi'),
      find.byType(FrostedMonogram),
    ),
    'glyph token': (
      const FrostedIconMark(FrostedGlyphs.wallet),
      find.byType(FrostedIconMark),
    ),
    'date block': (
      FrostedDateBlock(DateTime(2026, 11, 1)),
      find.byType(FrostedDateBlock),
    ),
  };
  for (final MapEntry(key: name, value: (part, finder)) in marks.entries) {
    for (final scale in [1.3, 2.0]) {
      testWidgets('a $name grows with the text at ${(scale * 100).round()}%', (
        t,
      ) async {
        await _pump(t, part);
        final rest = t.getSize(finder);
        await _pump(t, part, scale: scale);
        final grown = t.getSize(finder);
        expect(grown.height, moreOrLessEquals(rest.height * scale, epsilon: 1));
        expect(grown.width, greaterThan(rest.width));
      });
    }
  }

  testWidgets("a tag's words, figure and glyph grow with it and stay inside", (
    t,
  ) async {
    const part = FrostedTag('results', figure: '13', icon: FrostedGlyphs.check);
    await _pump(t, part);
    final words = t.widget<Text>(find.text('results')).style!.fontSize!;
    final glyph = t.widget<Icon>(find.byType(Icon)).size!;
    await _pump(t, part, scale: 2);
    final tag = t.getRect(find.byType(FrostedTag));
    expect(t.widget<Text>(find.text('results')).style!.fontSize, words * 2);
    expect(t.widget<Icon>(find.byType(Icon)).size, glyph * 2);
    for (final f in [
      find.text('results'),
      find.text('13'),
      find.byType(Icon),
    ]) {
      final r = t.getRect(f);
      expect(r.top, greaterThanOrEqualTo(tag.top));
      expect(r.bottom, lessThanOrEqualTo(tag.bottom));
      expect(r.left, greaterThanOrEqualTo(tag.left));
      expect(r.right, lessThanOrEqualTo(tag.right));
    }
  });

  testWidgets("a monogram's letters grow with its square", (t) async {
    await _pump(t, const FrostedMonogram('Piranesi'));
    final rest = t.widget<Text>(find.text('PI')).style!.fontSize!;
    await _pump(t, const FrostedMonogram('Piranesi'), scale: 1.5);
    expect(t.widget<Text>(find.text('PI')).style!.fontSize, rest * 1.5);
  });

  testWidgets('a monogram is decoration unless it has a label', (t) async {
    final semantics = t.ensureSemantics();
    await _pump(t, const FrostedMonogram('Piranesi'));
    expect(find.bySemanticsLabel('Piranesi'), findsNothing);
    await _pump(t, const FrostedMonogram('Piranesi', label: 'Piranesi'));
    expect(find.bySemanticsLabel('Piranesi'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a row led by a monogram reads its title once', (t) async {
    final semantics = t.ensureSemantics();
    await _pump(
      t,
      SizedBox(
        width: 358,
        child: FrostedListTile(
          title: 'Piranesi',
          meta: 'Susanna Clarke',
          leading: const FrostedMonogram('Piranesi'),
          onPressed: () {},
        ),
      ),
    );
    final node = t.getSemantics(find.byType(FrostedListTile));
    final heard = node.getSemanticsData().label;
    expect(RegExp('Piranesi').allMatches(heard).length, 1, reason: heard);
    semantics.dispose();
  });
}
