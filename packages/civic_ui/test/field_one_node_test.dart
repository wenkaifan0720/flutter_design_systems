// A text field is one text field to a screen reader, named by its label,
// before and after a clear key joins it with the first letter: the line's
// own tap stays out of the semantics tree, as Flutter's text field keeps
// its own, so the entry is never left in a node of its own, unnamed. On
// ui_core 0.4.1 the entry keeps its very node as the key joins (on the web
// that node is the browser's input, and a new one loses the keys typed
// while it is made).
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

class _Search extends StatefulWidget {
  const _Search();

  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  final text = TextEditingController();

  @override
  void initState() {
    super.initState();
    text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicTextField(
    labelText: 'Street',
    hintText: 'Street or postcode',
    controller: text,
    suffixIcon: text.text.isEmpty
        ? null
        : CivicIconButton(
            icon: LucideIcons.x,
            semanticLabel: 'Clear',
            onPressed: text.clear,
          ),
  );
}

void main() {
  testWidgets('a field stays one named text field as a clear key joins it', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      kitApp(
        brightness: Brightness.light,
        home: const Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: _Search()),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    SemanticsNode entry() => tester.getSemantics(find.byType(EditableText));
    final empty = entry().getSemanticsData();
    expect(empty.flagsCollection.isTextField, isTrue);
    expect(empty.label, startsWith('Street'));
    await tester.enterText(find.byType(EditableText), 'p');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Clear'), findsOneWidget);
    final typed = entry().getSemanticsData();
    expect(typed.flagsCollection.isTextField, isTrue);
    expect(typed.label, startsWith('Street'), reason: 'an unnamed entry');
    // The line's tap that focuses the entry from its padding is out of the
    // semantics tree: on ui_core 0.4.1 the entry is then the field's one
    // node, the same node before and after the key joins.
    final taps = tester.widgetList<GestureDetector>(
      find.ancestor(
        of: find.byType(EditableText),
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onTap != null,
        ),
      ),
    );
    expect(taps, isNotEmpty);
    for (final tap in taps) {
      expect(tap.excludeFromSemantics, isTrue, reason: 'a tap in the tree');
    }
    semantics.dispose();
  });
}
