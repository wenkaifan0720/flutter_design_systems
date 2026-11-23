// The names fluent2_design_ui 0.5.0 renames: field_words.dart calls them as before `dart fix --apply`,
// field_words.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void calls(BuildContext context) {
  final v1 = Fluent2FormField(
    label: 'Text',
    helper: 'Text',
    child: const SizedBox(),
  );
  print(v1.label);
  print(v1.helper);
  final v2 = Fluent2TextField(hint: 'Text');
  print(v2.hint);
  final v3 = Fluent2TextArea(hint: 'Text');
  print(v3.hint);
  final v4 = Fluent2SearchBox(hint: 'Text');
  print(v4.hint);
  final v5 = Fluent2SearchEntry(onPressed: () {}, hint: 'Text');
  print(v5.hint);
  final v6 = Fluent2PasswordField(hint: 'Text');
  print(v6.hint);
  final v7 = Fluent2InputGroup(hint: 'Text');
  print(v7.hint);
  final v8 = Fluent2Combobox<String>(
    options: const [],
    value: 'a',
    onChanged: (_) {},
    hint: 'Text',
  );
  print(v8.hint);
  final v9 = Fluent2MultiSelect<String>(
    options: const [],
    selected: const [],
    onChanged: (_) {},
    hint: 'Text',
  );
  print(v9.hint);
  final v10 = Fluent2DatePicker(
    value: DateTime(2026),
    onChanged: (_) {},
    hint: 'Text',
  );
  print(v10.hint);
  final v11 = Fluent2Composer(onSend: (_) {}, hint: 'Text');
  print(v11.hint);
  print([v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11]);
}
