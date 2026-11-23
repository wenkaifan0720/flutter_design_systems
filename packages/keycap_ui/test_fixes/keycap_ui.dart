// The names keycap_ui 0.3.0 renames: keycap_ui.dart calls them as before `dart fix --apply`,
// keycap_ui.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

void calls(BuildContext context) {
  final v1 = const KeycapTextField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v1.label);
  print(v1.hint);
  print(v1.helper);
  print(v1.error);
  final v2 = const KeycapPasswordField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v2.label);
  print(v2.hint);
  print(v2.helper);
  print(v2.error);
  final v3 = const KeycapInputGroup(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
    prefix: 'Text',
    suffix: 'Text',
  );
  print(v3.label);
  print(v3.hint);
  print(v3.helper);
  print(v3.error);
  print(v3.prefix);
  print(v3.suffix);
  final v4 = const KeycapCombobox<String>(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v4.label);
  print(v4.hint);
  print(v4.helper);
  print(v4.error);
  final v5 = KeycapTagInput<String>(
    values: const [],
    onChanged: (_) {},
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v5.label);
  print(v5.hint);
  print(v5.helper);
  print(v5.error);
  final v6 = KeycapSelect<int>(
    items: const [],
    value: null,
    onChanged: (_) {},
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v6.label);
  print(v6.hint);
  print(v6.helper);
  print(v6.error);
  final v7 = KeycapDatePicker(
    value: null,
    onChanged: (_) {},
    firstDate: DateTime(2026),
    lastDate: DateTime(2026),
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v7.label);
  print(v7.hint);
  print(v7.helper);
  print(v7.error);
  final v8 = KeycapDateRangePicker(
    value: null,
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
  final v9 = KeycapTimePicker(
    value: null,
    onChanged: (_) {},
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v9.label);
  print(v9.hint);
  print(v9.helper);
  print(v9.error);
  final v10 = const KeycapSearchField(hint: 'Text');
  print(v10.hint);
  final v11 = const KeycapCommandPalette(commands: [], hint: 'Text');
  print(v11.hint);
  final v12 = const KeycapFieldMessage(helper: 'Text', error: 'Text');
  print(v12.helper);
  print(v12.error);
  final v13 = KeycapHost(
    light: KeycapThemeData.light(),
    dark: KeycapThemeData.light(),
    child: const SizedBox(),
  );
  print(v13.light);
  print(v13.dark);
  final v14 = const KeycapStepProgress(steps: ['One', 'Two'], current: 1);
  print(v14.current);
  final v15 = const KeycapListTile(title: 'Text', destructive: true);
  print(v15.destructive);
  final v16 = const KeycapMenuRow(label: 'Text', height: 40, destructive: true);
  print(v16.destructive);
  final v17 = KeycapSheetAction(
    label: 'Text',
    onPressed: () {},
    destructive: true,
  );
  print(v17.destructive);
  final v18 = KeycapScaffold(
    destinations: const [],
    selectedIndex: 1,
    body: const SizedBox(),
    onSelected: (_) {},
  );
  print(v18.onSelected);
  final v19 = KeycapNavigationBar(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v19.onSelected);
  final v20 = KeycapNavigationRail(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v20.onSelected);
  final v21 = KeycapSideNavigation(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v21.onSelected);
  final v22 = KeycapIconButton(
    icon: const SizedBox(),
    semanticLabel: 'Text',
    onPressed: () {},
    selected: true,
  );
  print(v22.selected);
  final v23 = KeycapDisclosure(
    title: 'Text',
    open: true,
    initiallyOpen: true,
    onChanged: (_) {},
    child: const SizedBox(),
  );
  print(v23.open);
  print(v23.initiallyOpen);
  print(v23.onChanged);
  final v24 = KeycapRadioGroup<String>(
    options: const ['One', 'Two'],
    labelOf: (v) => v,
    onChanged: (_) {},
    value: 'Text',
  );
  print(v24.value);
  final v25 = KeycapPagination(page: 1, pageCount: 1, onChanged: (_) {});
  print(v25.onChanged);
  final v26 = KeycapPageDots(count: 1, index: 1, onChanged: (_) {});
  print(v26.count);
  print(v26.index);
  print(v26.onChanged);
  showKeycapCommandPalette(context: context, commands: const [], hint: 'Text');
  print(KeycapTextTheme.of(KeycapColors.light));
}
