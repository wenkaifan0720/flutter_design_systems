// The names clay_ui 0.3.0 renames: clay_ui.dart calls them as before `dart fix --apply`,
// clay_ui.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_host.dart';
import 'package:clay_ui/clay_ui.dart';

void calls(BuildContext context) {
  final v1 = const ClayInput(
    label: 'Text',
    hint: 'Text',
    error: 'Text',
    obscure: true,
  );
  print(v1.label);
  print(v1.hint);
  print(v1.error);
  print(v1.obscure);
  final v2 = const ClayTextField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v2.label);
  print(v2.hint);
  print(v2.helper);
  print(v2.error);
  final v3 = const ClayTextArea(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v3.label);
  print(v3.hint);
  print(v3.helper);
  print(v3.error);
  final v4 = const ClayPasswordField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v4.label);
  print(v4.hint);
  print(v4.helper);
  print(v4.error);
  final v5 = const ClayInputGroup(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v5.label);
  print(v5.hint);
  print(v5.helper);
  print(v5.error);
  final v6 = const ClayCombobox<String>(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v6.label);
  print(v6.hint);
  print(v6.helper);
  print(v6.error);
  final v7 = ClayTagInput<String>(
    values: const [],
    onChanged: (_) {},
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v7.label);
  print(v7.hint);
  print(v7.helper);
  print(v7.error);
  final v8 = ClaySelect<int>(
    items: const [],
    value: null,
    onChanged: (_) {},
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v8.label);
  print(v8.hint);
  print(v8.helper);
  print(v8.error);
  final v9 = ClayDatePicker(
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
  final v10 = ClayDateRangePicker(
    value: null,
    onChanged: (_) {},
    firstDate: DateTime(2026),
    lastDate: DateTime(2026),
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v10.label);
  print(v10.hint);
  print(v10.helper);
  print(v10.error);
  final v11 = ClayTimeField(
    value: null,
    onChanged: (_) {},
    label: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v11.label);
  print(v11.helper);
  print(v11.error);
  final v12 = const ClaySearchField(hint: 'Text');
  print(v12.hint);
  final v13 = const ClayCommandPalette(commands: [], hint: 'Text');
  print(v13.hint);
  final v14 = const ClayFieldMessage(helper: 'Text', error: 'Text');
  print(v14.helper);
  print(v14.error);
  final v15 = ClayPreview(
    activeIndex: 1,
    light: ClayThemeData.clay(Brightness.light),
    dark: ClayThemeData.clay(Brightness.light),
    child: const SizedBox(),
  );
  print(v15.activeIndex);
  print(v15.light);
  print(v15.dark);
  final v16 = ClayHost(
    light: ClayThemeData.clay(Brightness.light),
    dark: ClayThemeData.clay(Brightness.light),
    child: const SizedBox(),
  );
  print(v16.light);
  print(v16.dark);
  final v17 = const ClayStepProgress(steps: ['One', 'Two'], current: 1);
  print(v17.current);
  final v18 = ClayDialogAction(
    label: 'Text',
    onPressed: () {},
    primary: true,
    destructive: true,
  );
  print(v18.primary);
  print(v18.destructive);
  final v19 = const ClayListTile(title: 'Text', destructive: true);
  print(v19.destructive);
  showClayCommandPalette(context, commands: const [], hint: 'Text');
  final v101 = ClayAppShell(
    tabs: const [],
    selectedIndex: 1,
    child: const SizedBox(),
    onSelected: (_) {},
  );
  print(v101.onSelected);
  final v102 = ClayScaffold(body: const SizedBox(), onSelected: (_) {});
  print(v102.onSelected);
  final v103 = ClayNavigationBar(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v103.onSelected);
  final v104 = ClayNavigationRail(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v104.onSelected);
  final v105 = ClaySidebar(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v105.onSelected);
  final v106 = ClayTabBar(
    tabs: const ['One', 'Two'],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v106.onSelected);
  final v107 = ClayIconButton(
    onPressed: () {},
    icon: const SizedBox(),
    tooltip: 'Text',
    selected: true,
  );
  print(v107.selected);
  final v108 = ClayDisclosure(
    title: 'Text',
    child: const SizedBox(),
    onChanged: (_) {},
  );
  print(v108.onChanged);
  final v109 = const ClayBadge(count: 1, max: 1);
  print(v109.max);
  final v110 = ClayRadioGroup<String>(
    options: const ['One', 'Two'],
    labelOf: (v) => v,
    onChanged: (_) {},
    value: 'Text',
  );
  print(v110.value);
  final v111 = ClayPagination(page: 1, count: 1, onChanged: (_) {});
  print(v111.count);
  print(v111.onChanged);
  final v112 = ClayPageDots(count: 1, index: 1, onChanged: (_) {});
  print(v112.count);
  print(v112.index);
  print(v112.onChanged);
  final vPlain = const ClayIconButton.plain(
    onPressed: null,
    icon: SizedBox(),
    tooltip: 'Text',
    selected: true,
  );
  print(vPlain.selected);
  print(
    ClayTextTheme.of(
      ink: const Color(0xFF000000),
      secondaryInk: const Color(0xFF000000),
    ),
  );
  final v201 = ClayFileDrop(onChoose: () {}, label: 'Text', hint: 'Text');
  print(v201.label);
  print(v201.hint);
}
