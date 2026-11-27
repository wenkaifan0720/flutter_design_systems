// The names gloss_ui 0.3.0 and 0.6.0 rename: gloss_ui.dart calls them as before `dart fix --apply`,
// gloss_ui.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

void calls(BuildContext context) {
  final v1 = GlossInput(
    hint: 'Text',
    label: 'Text',
    error: 'Text',
    obscure: true,
  );
  print(v1.hint);
  print(v1.label);
  print(v1.error);
  print(v1.obscure);
  final v2 = GlossSearchField(hint: 'Text');
  print(v2.hint);
  final v3 = GlossPasswordField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v3.label);
  print(v3.hint);
  print(v3.helper);
  print(v3.error);
  final v4 = GlossInputGroup(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v4.label);
  print(v4.hint);
  print(v4.helper);
  print(v4.error);
  final v5 = GlossTextArea(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v5.label);
  print(v5.hint);
  print(v5.helper);
  print(v5.error);
  final v6 = GlossCombobox<String>(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v6.label);
  print(v6.hint);
  print(v6.helper);
  print(v6.error);
  final v7 = GlossTagInput<String>(
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
  final v8 = GlossDatePicker(
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
  final v9 = GlossDateRangePicker(
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
  final v10 = GlossSelect<String>(
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
  final v11 = GlossTextField(
    label: 'Text',
    hint: 'Text',
    helper: 'Text',
    error: 'Text',
  );
  print(v11.label);
  print(v11.hint);
  print(v11.helper);
  print(v11.error);
  final v12 = GlossFieldMessage(helper: 'Text', error: 'Text');
  print(v12.helper);
  print(v12.error);
  final v13 = GlossFileDrop(onChoose: () {}, label: 'Text', hint: 'Text');
  print(v13.label);
  print(v13.hint);
  final v14 = GlossCommandPalette(commands: const [], hint: 'Text');
  print(v14.hint);
  showGlossCommandPalette(context, commands: const [], hint: 'Text');
  final v15 = GlossHost(light: null, dark: null, child: const SizedBox());
  print(v15.light);
  print(v15.dark);
  final v16 = GlossPreview(
    child: const SizedBox(),
    light: null,
    dark: null,
    activeIndex: 1,
  );
  print(v16.light);
  print(v16.dark);
  print(v16.activeIndex);
  final v17 = GlossAppShell(
    destinations: const [],
    branches: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v17.onSelected);
  final v18 = GlossNavigationBar(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v18.onSelected);
  final v19 = GlossNavigationRail(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v19.onSelected);
  final v20 = GlossSidebar(
    destinations: const [],
    selectedIndex: 1,
    onSelected: (_) {},
  );
  print(v20.onSelected);
  final v21 = GlossScaffold(body: const SizedBox(), onSelected: (_) {});
  print(v21.onSelected);
  final v22 = GlossTabBar(tabs: const [], selectedIndex: 1, onSelected: (_) {});
  print(v22.onSelected);
  final v23 = GlossDialogAction(
    label: 'Text',
    onPressed: () {},
    primary: true,
    destructive: true,
  );
  print(v23.primary);
  print(v23.destructive);
  final v24 = GlossListTile(title: 'Text', destructive: true);
  print(v24.destructive);
  final v25 = GlossIconButton(
    onPressed: () {},
    icon: const SizedBox(),
    tooltip: 'Text',
    selected: true,
  );
  final v26 = GlossIconButton.plain(
    onPressed: () {},
    icon: const SizedBox(),
    tooltip: 'Text',
    selected: true,
  );
  print(v25.selected);
  final v27 = GlossDisclosure(
    title: 'Text',
    child: const SizedBox(),
    onChanged: (_) {},
  );
  print(v27.onChanged);
  final v28 = GlossStepProgress(steps: const [], current: 1);
  print(v28.current);
  final v29 = GlossPageDots(count: 1, index: 1, onChanged: (_) {});
  print(v29.count);
  print(v29.index);
  print(v29.onChanged);
  final v30 = GlossPagination(page: 1, pageCount: 1, onChanged: (_) {});
  print(v30.onChanged);
  final v31 = GlossBadge(count: 1, max: 1);
  print(v31.max);
  GlossTextTheme.of(const GlossColors.light());
  final v32 = GlossRadioGroup<String>(
    options: const [],
    value: 'a',
    labelOf: (v) => '$v',
    onChanged: (_) {},
  );
  print(v32.value);
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
  // 0.6.0: the tag's palette tone.
  print(GlossTag('Text', tone: GlossTagTone.jade));
}
