// A field reads its label once: a date field and a select say their label,
// then their value, never the label twice ("Date started, Date started").
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

/// What each node a screen reader visits says: its label, then its value.
List<String> _said(WidgetTester tester) {
  final out = <String>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent) {
      final data = node.getSemanticsData();
      final said = [data.label, data.value].where((s) => s.isNotEmpty);
      if (said.isNotEmpty) out.add(said.join(', '));
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

int _count(String said, String words) =>
    RegExp(RegExp.escape(words)).allMatches(said).length;

void main() {
  setUpAll(studioLoadFonts);

  testWidgets('a date field and a select say their label once', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            StudioHost(brightness: Brightness.light, child: app!),
        home: StudioScreen(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: StudioSpacing.regular,
            children: [
              StudioDatePicker(
                labelText: 'Date started',
                value: DateTime(2026, 11, 3),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onChanged: (_) {},
              ),
              StudioSelect<String>(
                labelText: 'Palette',
                value: 'anodised',
                items: const [
                  StudioSelectItem(value: 'anodised', label: 'Anodised'),
                  StudioSelectItem(value: 'cobalt', label: 'Cobalt'),
                ],
                onChanged: (_) {},
              ),
              const StudioTextFormField(
                labelText: 'Title',
                initialValue: 'Pilot',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final said = _said(tester);
    for (final label in ['Date started', 'Palette', 'Title']) {
      final nodes = said.where((s) => s.contains(label)).toList();
      expect(nodes, hasLength(1), reason: '$label in $said');
      expect(_count(nodes.single, label), 1, reason: nodes.single);
    }
    // The value with the label, the day with its year.
    expect(
      said.where((s) => s.contains('Date started')).single,
      contains('2026'),
    );
    expect(
      said.where((s) => s.contains('Palette')).single,
      contains('Anodised'),
    );
    semantics.dispose();
  });

  testWidgets('a field takes the column width', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            StudioHost(brightness: Brightness.light, child: app!),
        home: StudioScreen(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudioTextFormField(key: Key('text'), labelText: 'Title'),
              StudioDatePicker(
                key: const Key('date'),
                labelText: 'Date started',
                value: null,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onChanged: (_) {},
              ),
              StudioSelect<String>(
                key: const Key('select'),
                labelText: 'Palette',
                value: null,
                items: const [
                  StudioSelectItem(value: 'anodised', label: 'Anodised'),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final text = tester.getRect(find.byKey(const Key('text')));
    for (final key in ['date', 'select']) {
      final r = tester.getRect(find.byKey(Key(key)));
      expect(r.left, text.left, reason: key);
      expect(r.width, text.width, reason: key);
    }
  });
}
