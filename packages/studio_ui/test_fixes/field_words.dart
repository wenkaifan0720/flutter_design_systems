// The names studio_ui 0.3.0 renames: field_words.dart calls them as before `dart fix --apply`,
// field_words.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

void calls(BuildContext context) {
  final v1 = StudioTextField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v1.label);
  print(v1.hint);
  print(v1.helper);
  print(v1.error);
  final v2 = StudioPasswordField(label: 'Text', helper: 'Text', error: 'Text');
  print(v2.label);
  print(v2.helper);
  print(v2.error);
  final v3 = StudioInputGroup(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v3.label);
  print(v3.hint);
  print(v3.helper);
  print(v3.error);
  final v4 = StudioCodeField(label: 'Text', error: 'Text');
  print(v4.label);
  print(v4.error);
  final v5 = StudioFormField(
    label: 'Text',
    helper: 'Text',
    error: 'Text',
    child: const SizedBox(),
  );
  print(v5.label);
  print(v5.helper);
  print(v5.error);
  final v6 = StudioCombobox<String>(
    labelOf: (v) => v,
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v6.label);
  print(v6.hint);
  print(v6.helper);
  print(v6.error);
  final v7 = StudioTagInput<String>(
    values: const [],
    onChanged: (_) {},
    labelOf: (v) => v,
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v7.label);
  print(v7.hint);
  print(v7.helper);
  print(v7.error);
  final v8 = StudioDatePicker(
    value: DateTime(2026),
    onChanged: (_) {},
    firstDate: DateTime(2026),
    lastDate: DateTime(2026),
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v8.label);
  print(v8.hint);
  print(v8.helper);
  print(v8.error);
  final v9 = StudioDateRangePicker(
    value: null,
    onChanged: (_) {},
    firstDate: DateTime(2026),
    lastDate: DateTime(2026),
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v9.label);
  print(v9.hint);
  print(v9.helper);
  print(v9.error);
  final v10 = StudioSelect<String>(
    items: const [],
    value: 'a',
    onChanged: (_) {},
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v10.label);
  print(v10.hint);
  print(v10.helper);
  print(v10.error);
  final v11 = StudioInput(
    hint: 'Text',
    label: 'Text',
    error: 'Text',
    obscure: true,
  );
  print(v11.label);
  print(v11.hint);
  print(v11.error);
  print(v11.obscure);
  final v12 = StudioSearchField(hint: 'Text');
  print(v12.hint);
  final v13 = StudioHost(light: null, dark: null, child: const SizedBox());
  print(v13.light);
  print(v13.dark);
  final v14 = StudioPreview(
    light: null,
    dark: null,
    activeIndex: 1,
    child: const SizedBox(),
  );
  print(v14.light);
  print(v14.dark);
  print(v14.activeIndex);
  final v15 = StudioStepProgress(steps: const [], current: 1);
  print(v15.current);
  final v16 = StudioFileDrop(
    onChoose: () {},
    label: 'Text',
    hint: 'Text',
    error: 'Text',
  );
  print(v16.label);
  print(v16.hint);
  print(v16.error);
  print([
    v1,
    v2,
    v3,
    v4,
    v5,
    v6,
    v7,
    v8,
    v9,
    v10,
    v11,
    v12,
    v13,
    v14,
    v15,
    v16,
  ]);
}
