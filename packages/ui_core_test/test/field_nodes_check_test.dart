// DesignFieldNodesCheck: a text field keeps its nodes as its text changes.
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, Material, MaterialType, TextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');

// A search field whose glyph gives way to a clear key with the first
// letter, in a line the whole of which focuses it; [boxes]: the look puts
// its entry in a node of its own once it holds text.
class _Search extends StatefulWidget {
  const _Search({this.tapped = false, this.boxes = false});

  final bool tapped;
  final bool boxes;

  @override
  State<_Search> createState() => _SearchState();
}

class _SearchState extends State<_Search> {
  final text = TextEditingController();
  final node = FocusNode();

  @override
  void initState() {
    super.initState();
    text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    text.dispose();
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawInputDecorator(
    labelText: 'Search tasks',
    focusNode: node,
    builder: (context, parts) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [?parts.label, parts.control],
    ),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: !widget.tapped,
      onTap: node.requestFocus,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            child: Semantics(
              container: widget.boxes && text.text.isNotEmpty,
              child: Material(
                type: MaterialType.transparency,
                child: TextField(
                  key: _fieldKey,
                  controller: text,
                  focusNode: node,
                  decoration: null,
                ),
              ),
            ),
          ),
          if (text.text.isEmpty)
            const Text('⌕', semanticsLabel: '')
          else
            RawButton(
              onPressed: text.clear,
              semanticLabel: 'Clear',
              excludeSemantics: true,
              builder: (context, states, _) => const Text('x'),
            ),
        ],
      ),
    ),
  );
}

Future<DesignAlignmentReport> _type(WidgetTester tester, _Search field) async {
  await tester.pumpWidget(
    harness(
      Localizations(
        locale: const Locale('en'),
        delegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Center(child: field),
      ),
    ),
  );
  await tester.tap(find.byType(EditableText));
  await tester.pump();
  const check = DesignFieldNodesCheck(look: 'Test');
  final screen = tester.element(find.byType(Center));
  final empty = check.read(screen);
  expect(empty.length, 1);
  await tester.enterText(find.byType(EditableText), 'p');
  await tester.pump();
  return check.check(empty, screen);
}

void main() {
  for (final tapped in [false, true]) {
    testWidgets('a field whose clear key shows with the first letter keeps '
        'its nodes${tapped ? ', its line\'s tap in the semantics tree' : ''}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final report = await _type(tester, _Search(tapped: tapped));
      expect(report.problems, isEmpty);
      semantics.dispose();
    });
  }

  testWidgets('an entry put in a node of its own with the first letter is '
      'reported', (tester) async {
    final semantics = tester.ensureSemantics();
    final report = await _type(tester, const _Search(boxes: true));
    expect(report.problems, isNotEmpty);
    expect(
      report.problems.first,
      allOf(
        startsWith('a field "Search tasks": its text entry moved from node #'),
        endsWith(
          'as its text changed: on the web that is a new input, and the '
          'keys typed meanwhile are lost',
        ),
      ),
    );
    semantics.dispose();
  });
}
