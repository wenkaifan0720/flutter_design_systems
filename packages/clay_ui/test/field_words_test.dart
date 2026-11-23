// Each of Clay's fields is read with its help and with its error. A field
// typed in has them on its text field's node, never on a node of their own
// beside it (DesignFieldWordsCheck); a select, a picker or a switch in a form
// field has them as the hint of its one node, named by its label.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

const _help = 'Shown on Today';
const _error = 'Name the habit';

Widget _app(Widget field) => MaterialApp(
  builder: (context, app) =>
      ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
  home: Center(child: SizedBox(width: 360, child: field)),
);

const _cases = [('help', _help, null), ('error', null, _error)];

void main() {
  final typed = <String, Widget Function(String? help, String? error)>{
    'text field': (h, e) =>
        ClayTextField(labelText: 'Habit name', helperText: h, errorText: e),
    'text area': (h, e) =>
        ClayTextArea(labelText: 'Why it matters', helperText: h, errorText: e),
    'password field': (h, e) =>
        ClayPasswordField(labelText: 'Password', helperText: h, errorText: e),
    'input group': (h, e) => ClayInputGroup(
      labelText: 'Water',
      suffixText: 'glasses',
      helperText: h,
      errorText: e,
    ),
    'combobox': (h, e) => ClayCombobox<String>(
      labelText: 'Habit',
      options: const ['Read', 'Walk'],
      helperText: h,
      errorText: e,
    ),
    'tag input': (h, e) => ClayTagInput<String>(
      labelText: 'Tags',
      values: const [],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
    'tag input holding tags': (h, e) => ClayTagInput<String>(
      labelText: 'Tags',
      values: const ['Morning', 'Health'],
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
          look: 'Clay',
          words: [?help, ?error],
        ).check(tester.element(find.byType(Center).first)).verify();
        semantics.dispose();
      });
    }
  }

  final controls = <String, (String, Widget Function(String?, String?))>{
    'select': (
      'Repeat',
      (h, e) => ClaySelect<int>(
        labelText: 'Repeat',
        items: const [
          ClaySelectItem(value: 1, label: 'Daily'),
          ClaySelectItem(value: 7, label: 'Weekly'),
        ],
        value: 1,
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'date picker': (
      'Starts on',
      (h, e) => ClayDatePicker(
        labelText: 'Starts on',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'date range picker': (
      'Away',
      (h, e) => ClayDateRangePicker(
        labelText: 'Away',
        value: null,
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'time field': (
      'Remind me at',
      (h, e) => ClayTimeField(
        labelText: 'Remind me at',
        value: const ClayTime(hour: 8, minute: 0),
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
    ),
    'form field': (
      'Reminders',
      (h, e) => ClayFormField(
        labelText: 'Reminders',
        helperText: h,
        errorText: e,
        child: ClaySwitch(value: true, onChanged: (_) {}),
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
}
