// Counts speak in their language's plural forms: an insight's row of
// visit dots says "1 visit" and "2 visits" in English (it said "1 visits"), through FrostedLocalizations.visits, and
// each of Arabic's six forms in the gallery's Arabic words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

// The gallery is the example app; its Arabic words are the plural-rich language checked here.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/arabic.dart';
import '../example/lib/kit_gallery/kit.dart';

Widget _insight(int visits) {
  final t = FrostedThemeData.opal();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, page) =>
        FrostedHost(theme: t, darkTheme: t, child: page!),
    home: Builder(
      builder: (context) => kitWords(
        context,
        SingleChildScrollView(
          child: FrostedInsight(
            icon: FrostedGlyphs.utensils,
            kind: 'Insight · Dining out',
            title: r'$36.40 over budget',
            body: 'Blue Fern Café',
            hue: context.frostedTheme.hues.coral,
            visits: visits,
          ),
        ),
      ),
    ),
  );
}

/// What the dots say.
String? _said(WidgetTester tester) {
  final labels = [
    for (final s in tester.widgetList<Semantics>(find.byType(Semantics)))
      if (s.properties.label case final label?
          when RegExp('visit|زيار').hasMatch(label))
        label,
  ];
  return labels.length == 1 ? labels.single : '$labels';
}

void main() {
  for (final (count, english) in [
    (1, '1 visit'),
    (2, '2 visits'),
    (13, '13 visits'),
  ]) {
    testWidgets('$count in English: "$english"', (tester) async {
      await tester.pumpWidget(_insight(count));
      expect(_said(tester), english);
    });
  }

  for (final (count, arabic) in [
    (1, 'زيارة واحدة'),
    (2, 'زيارتان'),
    (3, '3 زيارات'),
    (10, '10 زيارات'),
    (11, '11 زيارة'),
    (100, '100 زيارة'),
    (103, '103 زيارات'),
  ]) {
    testWidgets('$count in Arabic: "$arabic"', (tester) async {
      kitShownDirection = TextDirection.rtl;
      addTearDown(() => kitShownDirection = TextDirection.ltr);
      await tester.pumpWidget(_insight(count));
      expect(_said(tester), arabic);
    });
  }
}
