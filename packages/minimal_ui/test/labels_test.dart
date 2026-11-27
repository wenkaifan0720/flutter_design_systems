// A label is read once and names what it should: a control in a field
// wrapper (one that draws no label of its own) is announced with the field's
// label once, not twice; in a list
// row a monogram (the avatar repeating the title) stays out of the row's
// name, and a status tag stays in it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Widget child) => MaterialApp(
  builder: (context, app) =>
      MinimalHost(brightness: Brightness.light, child: app!),
  home: Material(
    type: MaterialType.transparency,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

/// How many times [words] is said across the live semantics tree.
int _said(WidgetTester tester, String words) {
  var n = 0;
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    n += RegExp(RegExp.escape(words)).allMatches(data.label).length;
    n += RegExp(RegExp.escape(words)).allMatches(data.value).length;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return n;
}

void main() {
  final controls = <String, Widget Function(String label)>{
    'a switch': (label) => MinimalSwitch(value: true, onChanged: (_) {}),
    'a segmented control': (label) => MinimalSegmentedButton<int>(
      segments: const [
        MinimalButtonSegment(0, 'System'),
        MinimalButtonSegment(1, 'Light'),
      ],
      value: 0,
      onChanged: (_) {},
    ),
    'a radio group': (label) => MinimalRadioGroup<int>(
      value: 0,
      onChanged: (_) {},
      options: const [
        MinimalRadioOption(value: 0, label: 'Standard'),
        MinimalRadioOption(value: 1, label: 'Ember'),
      ],
    ),
    // The wrapper's label names it; the field draws none of its own.
    'a text field': (label) => const MinimalTextField(),
  };
  for (final MapEntry(key: name, value: build) in controls.entries) {
    testWidgets('$name in a field wrapper says its label once', (tester) async {
      await tester.pumpWidget(
        _app(
          MinimalFormField(labelText: 'Appearance', child: build('Appearance')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_said(tester, 'Appearance'), 1);
    });
  }

  testWidgets("a monogram stays out of the row's name", (tester) async {
    await tester.pumpWidget(
      _app(
        MinimalListTile(
          title: 'Piranesi',
          leading: const MinimalAvatar('Piranesi'),
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_said(tester, 'Piranesi'), 1);
  });

  testWidgets("a status tag stays in the row's name", (tester) async {
    await tester.pumpWidget(
      _app(
        MinimalListTile(
          title: 'Piranesi',
          trailing: const MinimalTag('Reading', tone: MinimalTone.primary),
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.semantics.byPredicate(
      (node) => node.label.contains('Piranesi'),
    );
    expect(row, findsOneWidget);
    expect(row.evaluate().single.label, contains('Reading'));
  });
}
