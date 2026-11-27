// A control inside ComicFormField is heard with the field's label once: a control that names itself the same way
// says it no more, and a segmented choice is a group whose segments keep nodes of their own.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

/// How many times [word] is heard, over every node a screen reader stops on.
int _heard(WidgetTester tester, String word) {
  final pattern = RegExp('\\b${RegExp.escape(word)}\\b');
  var n = 0;
  void walk(SemanticsNode node) {
    // A node merged into its parent is heard in the parent's words, not again on its own.
    if (!node.isMergedIntoParent) {
      final d = node.getSemanticsData();
      for (final s in [d.label, d.value, d.hint]) {
        n += pattern.allMatches(s).length;
      }
    }
    node.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  var root = tester.getSemantics(find.byType(ComicFormField));
  while (root.parent != null) {
    root = root.parent!;
  }
  walk(root);
  return n;
}

Future<void> _pump(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    comicApp(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [field]),
      ),
      width: 390,
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  final once = <String, Widget>{
    'a switch': ComicFormField(
      'Alerts',
      child: ComicSwitch(
        semanticLabel: 'Alerts',
        value: true,
        onChanged: (_) {},
      ),
    ),
    'a checkbox': ComicFormField(
      'Alerts',
      child: ComicCheckbox(
        semanticLabel: 'Alerts',
        value: true,
        onChanged: (_) {},
      ),
    ),
    'a quiet slider': ComicFormField(
      'Alerts',
      child: ComicSlider(
        label: 'Alerts',
        quiet: true,
        value: .4,
        onChanged: (_) {},
      ),
    ),
    'a segmented choice': ComicFormField(
      'Alerts',
      child: ComicSegmentedButton<String>(
        semanticLabel: 'Alerts',
        segments: const [
          ComicButtonSegment('on', 'On'),
          ComicButtonSegment('off', 'Off'),
        ],
        value: 'on',
        onChanged: (_) {},
      ),
    ),
    'a date field': ComicFormField(
      'Alerts',
      child: ComicDateField(value: DateTime(2026, 11, 9), onChanged: (_) {}),
    ),
    'a select': ComicFormField(
      'Alerts',
      child: ComicSelect<String>(
        options: const [
          ComicSelectOption('on', 'On'),
          ComicSelectOption('off', 'Off'),
        ],
        value: 'on',
        onChanged: (_) {},
      ),
    ),
  };
  for (final e in once.entries) {
    testWidgets('${e.key} in a form field reads its label once', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pump(tester, e.value);
        expect(_heard(tester, 'Alerts'), 1);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'a segmented choice in a form field keeps a node for each segment',
    (tester) async {
      final semantics = tester.ensureSemantics();
      String? picked;
      try {
        await _pump(
          tester,
          ComicFormField(
            'View',
            child: ComicSegmentedButton<String>(
              segments: const [
                ComicButtonSegment('all', 'All'),
                ComicButtonSegment('saved', 'Saved'),
              ],
              value: 'all',
              onChanged: (v) => picked = v,
            ),
          ),
        );
        for (final name in ['All', 'Saved']) {
          final node = tester.getSemantics(
            find.bySemanticsLabel(RegExp('^$name\$')),
          );
          // getSemantics climbs out of a merged node: a segment merged into the field reads as the whole field.
          expect(node.getSemanticsData().label, name);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
            reason: name,
          );
        }
        tester.semantics.tap(find.semantics.byLabel('Saved'));
        await tester.pump();
        expect(picked, 'saved');
        expect(_heard(tester, 'View'), 1);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('a control named otherwise keeps its own name in a form field', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(
        tester,
        ComicFormField(
          'Alerts',
          child: ComicSwitch(
            semanticLabel: 'Push',
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(_heard(tester, 'Alerts'), 1);
      expect(_heard(tester, 'Push'), 1);
    } finally {
      semantics.dispose();
    }
  });
}
