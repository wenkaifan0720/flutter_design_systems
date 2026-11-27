// A control's spoken name, heard once: a slider inside the field wrapper
// reads the field's label once with its own words for the value; a row's
// name leaves out a monogram that repeats its title but keeps its status
// tag, and a control at the row's end keeps its own node.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> _pump(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, page) => FrostedHost(child: page!),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    ),
  );
  expect(t.takeException(), isNull);
}

/// Every node a screen reader can land on: the root's descendants that
/// are not merged into a node above them, with words of their own.
List<SemanticsData> _heard(WidgetTester t) {
  final out = <SemanticsData>[];
  void walk(SemanticsNode n) {
    final data = n.getSemanticsData();
    if (data.label.isNotEmpty || data.value.isNotEmpty) out.add(data);
    if (n.mergeAllDescendantsIntoThisNode) return;
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  var root = t.getSemantics(find.byType(FrostedHost));
  while (root.parent != null) {
    root = root.parent!;
  }
  walk(root);
  return out;
}

void main() {
  testWidgets(
    'a slider in the field wrapper says its name once, its value in its own words',
    (t) async {
      final h = t.ensureSemantics();
      await _pump(
        t,
        FrostedFormField(
          labelText: 'Text size',
          child: FrostedSlider(
            semanticLabel: 'Text size',
            value: 4,
            max: 8,
            divisions: 8,
            semanticFormatterCallback: (v) => '${(70 + v * 15).round()}%',
            onChanged: (_) {},
          ),
        ),
      );
      final heard = _heard(t);
      expect(heard, hasLength(1));
      expect(heard.single.label, 'Text size');
      expect(heard.single.value, '130%');
      h.dispose();
    },
  );

  testWidgets(
    "a row's name leaves its monogram out and keeps its tag; its menu is its own node",
    (t) async {
      final h = t.ensureSemantics();
      await _pump(
        t,
        FrostedListTile(
          leading: const FrostedMonogram('Piranesi'),
          title: 'Piranesi',
          meta: 'Susanna Clarke',
          trailing: const FrostedTag('Overdue', tone: FrostedTone.danger),
          onPressed: () {},
          action: FrostedIconButton(
            FrostedGlyphs.more,
            semanticLabel: 'More',
            onPressed: () {},
          ),
        ),
      );
      final heard = _heard(t).map((d) => d.label).toList();
      expect(heard, ['Piranesi\nSusanna Clarke\nOverdue', 'More']);
      h.dispose();
    },
  );
}
