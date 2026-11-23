// Each of Appliance's fields is read with its help and with its error: a
// field typed in or opened has them on its control's node, never on a node
// of their own beside it (DesignFieldWordsCheck).
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _help = 'We ring before we come';
const _error = 'Choose a delivery day';

Widget _app(Widget field) => MaterialApp(
  builder: (context, app) =>
      ApplianceHost(brightness: Brightness.light, child: app!),
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, child: field)),
  ),
);

const _cases = [('help', _help, null), ('error', null, _error)];

void main() {
  setUpAll(applianceLoadFonts);
  final fields = <String, Widget Function(String? help, String? error)>{
    'a text field': (h, e) =>
        ApplianceTextField(labelText: 'Name', helperText: h, errorText: e),
    'a text area': (h, e) => ApplianceTextField(
      labelText: 'Note for the driver',
      maxLines: 4,
      helperText: h,
      errorText: e,
    ),
    'a password field': (h, e) =>
        AppliancePasswordField(helperText: h, errorText: e),
    'an input group': (h, e) => ApplianceInputGroup(
      labelText: 'Quantity',
      suffix: 'boxes',
      helperText: h,
      errorText: e,
    ),
    'a combobox': (h, e) => ApplianceCombobox<String>(
      labelText: 'Item',
      options: const ['Kettle', 'Toaster'],
      onSelected: (_) {},
      helperText: h,
      errorText: e,
    ),
    'a tag input': (h, e) => ApplianceTagInput<String>(
      labelText: 'Rooms',
      values: const [],
      options: const ['Hall', 'Kitchen'],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
    'a tag input holding tags': (h, e) => ApplianceTagInput<String>(
      labelText: 'Rooms',
      values: const ['Hall'],
      options: const ['Hall', 'Kitchen'],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
  };
  for (final MapEntry(key: kind, value: field) in fields.entries) {
    for (final (words, help, error) in _cases) {
      testWidgets('$kind reads its $words on its text field', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_app(field(help, error)));
        await tester.pump(const Duration(seconds: 1));
        DesignFieldWordsCheck(
          look: 'Appliance',
          words: [?help, ?error],
        ).check(tester.element(find.byType(Center).first)).verify();
        semantics.dispose();
      });
    }
  }

  // A select and a date picker are keys, not text fields: the words are the
  // key's hint, and on no node of their own.
  final keys = <String, Widget Function(String? help, String? error)>{
    'a select': (h, e) => ApplianceSelect<int>(
      labelText: 'Deliver every',
      value: 1,
      items: const [
        ApplianceSelectItem(value: 1, label: 'One week'),
        ApplianceSelectItem(value: 2, label: 'Two weeks'),
      ],
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
    'a date picker': (h, e) => ApplianceDatePicker(
      labelText: 'Delivery day',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      onChanged: (_) {},
      helperText: h,
      errorText: e,
    ),
  };
  for (final MapEntry(key: kind, value: field) in keys.entries) {
    for (final (words, help, error) in _cases) {
      testWidgets('$kind reads its $words on its key', (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_app(field(help, error)));
        await tester.pump(const Duration(seconds: 1));
        final said = help ?? error!;
        expect(find.semantics.byHint(said), findsOne);
        expect(tester.getSemantics(find.byType(RawButton).first).hint, said);
        expect(find.semantics.byLabel(said), findsNothing);
        semantics.dispose();
      });
    }
  }
}
