// A field's semantics keep their shape while its controls come and go: the
// text entry's node is the same node, with the same id, whether or not a
// trailing control (a clear key that shows with the first letter) stands
// beside it, and so is every node the field had. On the web a text field's
// node is the browser's input; a node that splits or changes id there is a
// new input, and the keys typed after it are lost while the field still
// looks focused. A line whose tap is in the semantics tree (a look that
// leaves its line's tap there) gives the entry a node of its own beside the
// press. Alone, that entry is still read as one text field named by the
// field: its label, its placeholder or help or error, and the entry on one
// node, as published looks are read. A control that joins it then gives it
// a node apart, so such a line keeps its node only with a second control
// from the start.
import 'package:material_ui/material_ui.dart'
    show
        DefaultMaterialLocalizations,
        InputDecoration,
        Material,
        MaterialType,
        TextField;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');

Widget _layout(BuildContext context, RawInputDecoratorDetails parts) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [?parts.label, parts.control, ?parts.helper, ?parts.error],
);

// A search field whose glyph gives way to a clear key once it holds text,
// as Ledger's did.
class _Search extends StatefulWidget {
  const _Search({this.helperText, this.leading = false, this.tapped = false});

  final String? helperText;
  final bool leading;

  // Whether the line's tap is in the semantics tree.
  final bool tapped;

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
    helperText: widget.helperText,
    focusNode: node,
    builder: _layout,
    // As a look's text field is: Material's text field in a line the whole
    // of which focuses it, its trailing act after it.
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: !widget.tapped,
      onTap: node.requestFocus,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading)
            RawButton(
              onPressed: () {},
              semanticLabel: 'Filters',
              excludeSemantics: true,
              builder: (context, states, _) => const Text('F'),
            ),
          SizedBox(
            width: 200,
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

// The field's nodes, as a screen reader and the web's engine get them (a
// node merged into another is not one): from the node over the
// [RawInputDecorator] down, each with its id and role.
({int entry, Map<int, String> nodes, String shape, String name}) _read(
  WidgetTester tester,
) {
  final entry = tester.getSemantics(find.byType(EditableText));
  final field = tester.getSemantics(find.byType(RawInputDecorator));
  final nodes = <int, String>{};
  String describe(SemanticsNode node) {
    final data = node.getSemanticsData();
    final role = data.flagsCollection.isTextField
        ? 'entry'
        : data.flagsCollection.isButton
        ? 'button'
        : 'node';
    nodes[node.id] = role;
    final children = <String>[];
    node.visitChildren((child) {
      children.add(describe(child));
      return true;
    });
    final self = '#${node.id} $role';
    return children.isEmpty ? self : '$self(${children.join(', ')})';
  }

  final shape = describe(field);
  // What names the entry: its own label, else its nearest named node above.
  var name = '';
  for (SemanticsNode? n = entry; n != null && name.isEmpty; n = n.parent) {
    name = n.getSemanticsData().label;
    if (n == field) break;
  }
  return (entry: entry.id, nodes: nodes, shape: shape, name: name);
}

void main() {
  for (final (name, helper, leading, tapped) in [
    ('a lone entry', null, false, false),
    ('an entry with help', 'Title or ID', false, false),
    ('an entry after a leading key', null, true, false),
    ('an entry after a leading key in a tapped line', null, true, true),
  ]) {
    testWidgets('$name keeps its node as a clear key comes and goes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Center(
              child: _Search(
                helperText: helper,
                leading: leading,
                tapped: tapped,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(_fieldKey));
      await tester.pump();
      final empty = _read(tester);
      await tester.enterText(find.byKey(_fieldKey), 'p');
      await tester.pump();
      final typed = _read(tester);
      final change = '${empty.shape} → ${typed.shape}';
      expect(typed.entry, empty.entry, reason: 'the entry\'s node: $change');
      expect(typed.nodes[typed.entry], 'entry', reason: change);
      // Every node the field had is there, in its role; the clear key is
      // the one node added.
      for (final MapEntry(key: id, value: role) in empty.nodes.entries) {
        expect(typed.nodes[id], role, reason: 'node #$id: $change');
      }
      expect(typed.nodes.length, empty.nodes.length + 1, reason: change);
      expect(empty.name, contains('Search tasks'), reason: empty.shape);
      expect(typed.name, contains('Search tasks'), reason: typed.shape);
      await tester.enterText(find.byKey(_fieldKey), '');
      await tester.pump();
      final cleared = _read(tester);
      expect(cleared.entry, empty.entry);
      expect(cleared.shape, empty.shape);
      semantics.dispose();
    });
  }

  // A lone entry under a look's own press (a line's tap left in the
  // semantics tree), or behind a node between, as published looks have it.
  for (final between in [false, true]) {
    for (final (name, hint, helper, error, heard) in [
      ('a placeholder', 'name@example.com', null, null, 'name@example.com'),
      (
        'help',
        null,
        'We send your sign-in link here.',
        null,
        'We send your sign-in link here.',
      ),
      (
        'an error',
        null,
        null,
        'Enter an email address',
        'Enter an email address',
      ),
    ]) {
      testWidgets(
        'a lone entry ${between ? 'behind a node between' : 'in a tapped line'} '
        'is one text field, named, with $name',
        (tester) async {
          final semantics = tester.ensureSemantics();
          final node = FocusNode();
          addTearDown(node.dispose);
          Widget entry = SizedBox(
            width: 200,
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                focusNode: node,
                decoration: InputDecoration.collapsed(hintText: hint),
              ),
            ),
          );
          if (between) entry = Semantics(container: true, child: entry);
          await tester.pumpWidget(
            harness(
              Localizations(
                locale: const Locale('en'),
                delegates: const [
                  DefaultMaterialLocalizations.delegate,
                  DefaultWidgetsLocalizations.delegate,
                ],
                child: Center(
                  child: RawInputDecorator(
                    labelText: 'Email',
                    helperText: helper,
                    errorText: error,
                    focusNode: node,
                    builder: _layout,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: between,
                      onTap: node.requestFocus,
                      child: entry,
                    ),
                  ),
                ),
              ),
            ),
          );
          // The node a screen reader lands on to type is the one that
          // names the field and says its placeholder, help or error (a
          // placeholder drawn in the entry is among its words).
          final data = tester
              .getSemantics(find.byType(EditableText))
              .getSemanticsData();
          expect(data.flagsCollection.isTextField, isTrue);
          expect(data.label, startsWith('Email'));
          expect('${data.label}\n${data.hint}', contains(heard));
          semantics.dispose();
        },
      );
    }
  }
}
