// The names comic_ui 0.5.0 renames: comic_ui.dart calls them as before `dart fix --apply`,
// comic_ui.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

void calls(BuildContext context) {
  final v1 = ComicTextField(
    hint: 'Text',
    prefix: 'Text',
    label: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v1.label);
  print(v1.hint);
  print(v1.helper);
  print(v1.error);
  print(v1.prefix);
  final v2 = ComicInput(hint: 'Text');
  print(v2.hint);
  final v3 = ComicTextArea(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v3.label);
  print(v3.hint);
  print(v3.helper);
  print(v3.error);
  final v4 = ComicSearchField(hint: 'Text');
  print(v4.hint);
  final v5 = ComicSelect<String>(
    options: const [],
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v5.label);
  print(v5.hint);
  print(v5.helper);
  print(v5.error);
  final v6 = ComicSelectField(value: 'Text', note: 'Text', label: 'Text');
  print(v6.label);
  print(v6.note);
  final v7 = ComicCombobox<String>(
    options: const [],
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
  );
  print(v7.label);
  print(v7.hint);
  print(v7.helper);
  final v8 = ComicPasswordField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v8.label);
  print(v8.hint);
  print(v8.helper);
  print(v8.error);
  final v9 = ComicInputGroup(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v9.label);
  print(v9.hint);
  print(v9.helper);
  print(v9.error);
  final v10 = ComicMultiSelect<String>(
    values: const [],
    onChanged: (_) {},
    labelOf: (v) => '$v',
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v10.label);
  print(v10.hint);
  print(v10.helper);
  print(v10.error);
  print(v10.labelOf);
  final v11 = ComicFormField(
    'Text',
    child: const SizedBox(),
    help: 'Text',
    error: 'Text',
  );
  print(v11.help);
  print(v11.error);
  final v12 = ComicFileUpload(label: 'Text', hint: 'Text', error: 'Text');
  print(v12.label);
  print(v12.hint);
  print(v12.error);
  final v13 = ComicNumberField(value: 1, note: 'Text');
  print(v13.note);
  final v14 = ComicInputOtp(label: 'Text', error: 'Text');
  print(v14.label);
  print(v14.error);
  final v15 = ComicReply(
    person: const ComicPerson(initials: 'AL'),
    hint: 'Text',
  );
  print(v15.hint);
  final v16 = ComicCommand(commands: const [], hint: 'Text');
  print(v16.hint);
  showComicCommand(context, commands: const [], hint: 'Text');
  final v17 = ComicRadioGroup<String>(
    label: 'Text',
    options: const [],
    value: 'a',
  );
  print(v17.label);
  print(v17.value);
  final v18 = ComicTabBar(tabs: const [], onChanged: (_) {});
  print(v18.onChanged);
  final v19 = ComicPageDots(
    count: 1,
    selectedIndex: 1,
    label: 'Text',
    onChanged: (_) {},
  );
  print(v19.count);
  print(v19.onChanged);
  final v20 = ComicPagination(count: 1, page: 1, onChanged: (_) {});
  print(v20.count);
  print(v20.onChanged);
  final v21 = ComicIconButton(
    const IconData(0xe000),
    label: 'Text',
    selected: true,
  );
  print(v21.selected);
  final v22 = ComicListTile(title: 'Text', destructive: true);
  print(v22.destructive);
  final v23 = ComicSheetAction<String>('Text', value: 'a', destructive: true);
  print(v23.destructive);
  final v24 = ComicToggleGroup<String>(
    values: const [],
    selected: const {},
    onChanged: (_) {},
    labelOf: (v) => '$v',
    multiple: true,
    allowEmpty: true,
  );
  print(v24.onChanged);
  print(v24.multiple);
  print(v24.allowEmpty);
  showComicDatePicker(context, confirm: 'Text', cancel: 'Text');
  showComicDateRangePicker(
    context,
    firstDate: DateTime(2026),
    lastDate: DateTime(2026),
    confirm: 'Text',
    cancel: 'Text',
  );
  showComicTimePicker(context, confirm: 'Text', cancel: 'Text');
  ComicTextSelectionControls.of(TargetPlatform.android);
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
    v17,
    v18,
    v19,
    v20,
    v21,
    v22,
    v23,
    v24,
  ]);
}
