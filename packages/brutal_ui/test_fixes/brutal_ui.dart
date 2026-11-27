// The names brutal_ui 0.4.0 renames: brutal_ui.dart calls them as before `dart fix --apply`,
// brutal_ui.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_host.dart';
import 'package:brutal_ui/brutal_ui.dart';

void calls(BuildContext context) {
  final v1 = BrutalInput(hint: 'Text');
  print(v1.hint);
  final v2 = BrutalSearchField(label: 'Text', hint: 'Text');
  print(v2.label);
  print(v2.hint);
  final v3 = BrutalPasswordField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v3.label);
  print(v3.hint);
  print(v3.helper);
  print(v3.error);
  final v4 = BrutalInputGroup(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v4.label);
  print(v4.hint);
  print(v4.helper);
  print(v4.error);
  final v5 = BrutalCodeField(label: 'Text', helper: 'Text', error: 'Text');
  print(v5.label);
  print(v5.helper);
  print(v5.error);
  final v6 = BrutalCombobox<String>(
    labelOf: (v) => '$v',
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v6.label);
  print(v6.hint);
  print(v6.helper);
  print(v6.error);
  print(v6.labelOf);
  final v7 = BrutalTagInput<String>(
    values: const [],
    onChanged: (_) {},
    labelOf: (v) => '$v',
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v7.label);
  print(v7.hint);
  print(v7.helper);
  print(v7.error);
  print(v7.labelOf);
  final v8 = BrutalDatePicker(
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
  final v9 = BrutalDateRangePicker(
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
  final v10 = BrutalSelect<String>(
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
  final v11 = BrutalTextField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v11.label);
  print(v11.hint);
  print(v11.helper);
  print(v11.error);
  final v12 = BrutalFieldMessage(helper: 'Text', error: 'Text');
  print(v12.helper);
  print(v12.error);
  final v13 = BrutalFileDrop(onChoose: () {}, label: 'Text', hint: 'Text');
  print(v13.label);
  print(v13.hint);
  final v14 = BrutalCommandPalette(commands: const [], hint: 'Text');
  print(v14.hint);
  showBrutalCommandPalette(context, commands: const [], hint: 'Text');
  final v15 = BrutalHost(light: null, dark: null, child: const SizedBox());
  print(v15.light);
  print(v15.dark);
  final v16 = BrutalPreview(
    child: const SizedBox(),
    light: null,
    dark: null,
    activeIndex: 1,
  );
  print(v16.light);
  print(v16.dark);
  print(v16.activeIndex);
  final v17 = BrutalAppShell(
    tabs: const [],
    selectedIndex: 1,
    onSelected: (_) {},
    child: const SizedBox(),
  );
  print(v17.onSelected);
  final v18 = BrutalNavigationBar(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v18.onSelected);
  final v19 = BrutalNavigationRail(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v19.onSelected);
  final v20 = BrutalSideNavigation(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v20.onSelected);
  final v21 = BrutalScaffold(body: const SizedBox(), onSelected: (_) {});
  print(v21.onSelected);
  final v22 = BrutalTabBar(
    tabs: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v22.onSelected);
  final v23 = BrutalDialogAction(
    label: 'Text',
    onPressed: () {},
    primary: true,
    destructive: true,
  );
  print(v23.primary);
  print(v23.destructive);
  final v24 = BrutalSwipeAction(
    label: 'Text',
    onPressed: () {},
    destructive: true,
  );
  print(v24.destructive);
  final v25 = BrutalListTile(title: 'Text', destructive: true);
  print(v25.destructive);
  final v26 = BrutalIconButton(
    onPressed: () {},
    icon: const SizedBox(),
    tooltip: 'Text',
    selected: true,
  );
  final v27 = BrutalIconButton.plain(
    onPressed: () {},
    icon: const SizedBox(),
    tooltip: 'Text',
    selected: true,
  );
  print(v26.selected);
  final v28 = BrutalDisclosure(
    title: 'Text',
    child: const SizedBox(),
    onChanged: (_) {},
  );
  print(v28.onChanged);
  final v29 = BrutalStepProgress(steps: const [], current: 1);
  print(v29.current);
  final v30 = BrutalPageDots(count: 1, index: 1, onChanged: (_) {});
  print(v30.count);
  print(v30.index);
  print(v30.onChanged);
  final v31 = BrutalPagination(page: 1, pageCount: 1, onChanged: (_) {});
  print(v31.onChanged);
  final v32 = BrutalBadge(count: 1, max: 1);
  print(v32.max);
  BrutalTextTheme.of(const BrutalColors.light());
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
    v25,
    v26,
    v27,
    v28,
    v29,
    v30,
    v31,
    v32,
  ]);
}
