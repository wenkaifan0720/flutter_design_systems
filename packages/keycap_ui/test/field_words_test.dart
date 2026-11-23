// Each of Keycap's fields is read with its help and with its error. A field
// typed in has them on its text field's node, never on a node of their own
// beside it (DesignFieldWordsCheck); a select, a picker or a switch in a
// field has them as the hint of its one node, named by its label.
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

const _help = 'Shown in the sidebar';
const _error = 'Give the folder a name';

Widget _app(Widget field) => MaterialApp(
  builder: (context, app) =>
      KeycapHost(brightness: Brightness.light, child: app!),
  home: Center(child: SizedBox(width: 360, child: field)),
);

const _cases = [('help', _help, null), ('error', null, _error)];

void main() {
  final typed = <String, Widget Function(String? help, String? error)>{
    'text field': (h, e) =>
        KeycapTextField(labelText: 'Folder name', helperText: h, errorText: e),
    'text area': (h, e) => KeycapTextField(
      labelText: 'Description',
      maxLines: 4,
      minLines: 3,
      helperText: h,
      errorText: e,
    ),
    'password field': (h, e) =>
        KeycapPasswordField(labelText: 'Password', helperText: h, errorText: e),
    'input group': (h, e) => KeycapInputGroup(
      labelText: 'Width',
      suffixText: 'px',
      helperText: h,
      errorText: e,
    ),
    'combobox': (h, e) => KeycapCombobox<String>(
      labelText: 'Folder',
      options: const ['Work', 'Ideas'],
      helperText: h,
      errorText: e,
    ),
    'tag input': (h, e) => KeycapTagInput<String>(
      labelText: 'Tags',
      values: const [],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
    'tag input holding tags': (h, e) => KeycapTagInput<String>(
      labelText: 'Tags',
      values: const ['Work', 'Ideas'],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
  };
  for (final MapEntry(key: kind, value: field) in typed.entries) {
    for (final (words, help, error) in _cases) {
      testWidgets('a $kind reads its $words on its text field', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_app(field(help, error)));
        await tester.pump(const Duration(seconds: 1));
        DesignFieldWordsCheck(
          look: 'Keycap',
          words: [?help, ?error],
        ).check(tester.element(find.byType(Center).first)).verify();
        semantics.dispose();
      });
    }
  }

  final controls = <String, (String, Widget Function(String?, String?))>{
    'select': (
      'Sort by',
      (h, e) => KeycapSelect<int>(
        labelText: 'Sort by',
        items: const [
          KeycapSelectItem(value: 1, label: 'Name'),
          KeycapSelectItem(value: 2, label: 'Date'),
        ],
        value: 1,
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'date picker': (
      'Remind me on',
      (h, e) => KeycapDatePicker(
        labelText: 'Remind me on',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'date range picker': (
      'Show notes from',
      (h, e) => KeycapDateRangePicker(
        labelText: 'Show notes from',
        value: null,
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'time picker': (
      'Remind me at',
      (h, e) => KeycapTimePicker(
        labelText: 'Remind me at',
        value: const RawTimeOfDay(hour: 8, minute: 0),
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'field': (
      'Sync',
      (h, e) => KeycapField(
        labelText: 'Sync',
        helperText: h,
        errorText: e,
        child: KeycapSwitch(value: true, onChanged: (_) {}),
      ),
    ),
  };
  for (final MapEntry(key: kind, value: (label, field)) in controls.entries) {
    for (final (words, help, error) in _cases) {
      testWidgets('a $kind reads its $words as its hint', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_app(field(help, error)));
        await tester.pump(const Duration(seconds: 1));
        final said = (help ?? error)!;
        // Read on the control's node, named by the label...
        expect(
          find.semantics.byPredicate((node) {
            final data = node.getSemanticsData();
            return data.hint.contains(said) &&
                (data.label.isEmpty || data.label.startsWith(label));
          }),
          findsOneWidget,
        );
        // ...and nowhere on a node of its own.
        expect(find.semantics.byLabel(said), findsNothing);
        semantics.dispose();
      });
    }
  }

  testWidgets('an empty error marks a field wrong without words', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const KeycapTextField(
          labelText: 'Folder name',
          helperText: _help,
          errorText: '',
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData()
          .validationResult,
      SemanticsValidationResult.invalid,
    );
    // The help gives way, as it does to an error with words.
    expect(find.text(_help), findsNothing);
    semantics.dispose();
  });
}
