// A page's bar is ruled along its foot while the content has scrolled under
// it, as the foot is ruled along its top, so a row cut at the bar's edge
// reads as going on above, not cut straight off at the bar's edge.
// At the top, the bar stands on the case with no rule.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(keycapLoadFonts);

  // The colour of the rule along the bar's foot, transparent when none.
  Color rule(WidgetTester tester) {
    final boxes = find
        .ancestor(
          of: find.byType(KeycapAppBar),
          matching: find.byType(DecoratedBox),
        )
        .evaluate()
        .map((e) => (e.widget as DecoratedBox).decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border is Border)
        .toList();
    expect(boxes, hasLength(1));
    return (boxes.single.border! as Border).bottom.color;
  }

  Widget rows() => KeycapListGroup(
    children: [
      for (var i = 0; i < 30; i++)
        KeycapListTile(title: 'Book $i', onTap: () {}),
    ],
  );

  for (final (name, page) in [
    (
      'a scrolling page',
      KeycapScreen(
        topBar: const KeycapAppBar(title: 'Books'),
        body: rows(),
      ),
    ),
    (
      'a page whose body scrolls itself',
      KeycapScreen(
        topBar: const KeycapAppBar(title: 'Books'),
        scroll: false,
        body: ListView(children: [rows()]),
      ),
    ),
  ]) {
    testWidgets('$name: ruled under the bar only while scrolled', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              KeycapHost(brightness: Brightness.light, child: child!),
          home: page,
        ),
      );
      await tester.pumpAndSettle();
      final hairline = KeycapThemeData.preset(
        KeycapThemeData.presets.first,
        Brightness.light,
      ).colors.hairline;
      expect(rule(tester).a, 0);
      await tester.drag(find.text('Book 3'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(rule(tester), hairline);
      await tester.drag(find.text('Book 8'), const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(rule(tester).a, 0);
    });
  }
}
