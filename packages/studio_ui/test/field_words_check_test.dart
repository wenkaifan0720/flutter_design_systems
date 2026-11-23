// A field's help and its error are read on the field itself, as Material's
// TextField reads them, never on a node of their own beside it: a text field
// as ui_core_test's DesignFieldWordsCheck reads them, a field round another
// control (a select, a date picker, a form field) on the node that names it.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

// The gallery's app frame; a test reads it from the example.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart' show kitApp;

const _help = 'Shown on the episode page';
const _error = 'Give the episode a title';

const _shows = ['Morning edition', 'Field notes'];

void _none() {}

// Each text field, given its help or its error.
final _textFields = <String, Widget Function(String? help, String? error)>{
  'text field': (help, error) =>
      StudioTextField(labelText: 'Title', helperText: help, errorText: error),
  'password field': (help, error) => StudioPasswordField(
    labelText: 'Password',
    helperText: help,
    errorText: error,
  ),
  'input group': (help, error) => StudioInputGroup(
    labelText: 'Feed address',
    leading: const Text('https://'),
    helperText: help,
    errorText: error,
  ),
  'combobox': (help, error) => StudioCombobox<String>(
    labelText: 'Show',
    options: _shows,
    labelOf: (s) => s,
    onSelected: (_) {},
    helperText: help,
    errorText: error,
  ),
  for (final tags in const [
    <String>[],
    ['Interviews'],
    ['Interviews', 'Science', 'Music'],
  ])
    'tag input with ${tags.length} tags': (help, error) =>
        StudioTagInput<String>(
          labelText: 'Topics',
          values: tags,
          options: _shows,
          labelOf: (s) => s,
          onChanged: (_) {},
          helperText: help,
          errorText: error,
        ),
};

// Each field round another control, its label, given its help or its error.
final _controlFields =
    <String, (String, Widget Function(String? help, String? error))>{
      'select': (
        'Show',
        (help, error) => StudioSelect<String>(
          labelText: 'Show',
          value: _shows.first,
          items: [for (final s in _shows) StudioSelectItem(value: s, label: s)],
          onChanged: (_) {},
          helperText: help,
          errorText: error,
        ),
      ),
      'date picker': (
        'Release date',
        (help, error) => StudioDatePicker(
          labelText: 'Release date',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          onChanged: (_) {},
          helperText: help,
          errorText: error,
        ),
      ),
      'date range picker': (
        'Recording days',
        (help, error) => StudioDateRangePicker(
          labelText: 'Recording days',
          value: null,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          onChanged: (_) {},
          helperText: help,
          errorText: error,
        ),
      ),
      'form field': (
        'Publish at',
        (help, error) => StudioFormField(
          labelText: 'Publish at',
          helperText: help,
          errorText: error,
          child: const StudioButton('Pick a time', onPressed: _none),
        ),
      ),
    };

Widget _host(Widget field) => kitApp(
  brightness: Brightness.light,
  home: Align(
    alignment: Alignment.topCenter,
    child: SizedBox(width: 360, child: Column(children: [field])),
  ),
);

// Every node under [node], itself first.
Iterable<SemanticsNode> _all(SemanticsNode node) sync* {
  yield node;
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* _all(child);
  }
}

bool _reads(SemanticsData d, String words) =>
    d.label.contains(words) ||
    d.hint.contains(words) ||
    d.value.contains(words) ||
    d.tooltip.contains(words);

void main() {
  setUpAll(studioLoadFonts);

  for (final MapEntry(key: kind, value: field) in _textFields.entries) {
    for (final (what, words) in const [('help', _help), ('error', _error)]) {
      testWidgets('a $kind reads its $what on the field', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            field(
              what == 'help' ? words : null,
              what == 'error' ? words : null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final report = DesignFieldWordsCheck(
          look: 'studio',
          words: [words],
        ).check(tester.element(find.byType(Column).first));
        expect(report.problems, isEmpty);
        semantics.dispose();
      });
    }
  }

  for (final MapEntry(key: kind, value: (label, field))
      in _controlFields.entries) {
    for (final (what, words) in const [('help', _help), ('error', _error)]) {
      testWidgets('a $kind reads its $what on the node naming it', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            field(
              what == 'help' ? words : null,
              what == 'error' ? words : null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        var root = tester.getSemantics(find.byType(Column).first);
        while (root.parent != null) {
          root = root.parent!;
        }
        final readers = [
          for (final node in _all(root))
            if (_reads(node.getSemanticsData(), words)) node.getSemanticsData(),
        ];
        expect(readers, hasLength(1), reason: 'read once, on one node');
        expect(readers.single.label, contains(label));
        final named = [
          for (final node in _all(root))
            if (node.getSemanticsData().label.contains(label))
              node.getSemanticsData().label,
        ];
        expect(named, hasLength(1), reason: 'its label on one node');
        expect(
          named.single.split('\n').where((line) => line == label),
          hasLength(1),
          reason: 'its label read once',
        );
        semantics.dispose();
      });
    }
  }
}
