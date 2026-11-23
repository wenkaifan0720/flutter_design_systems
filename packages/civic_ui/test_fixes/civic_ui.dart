// The names civic_ui 0.5.0 renames: civic_ui.dart calls them as before `dart fix --apply`,
// civic_ui.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

void calls(BuildContext context) {
  final v1 = CivicInput(
    label: 'Text',
    hint: 'Text',
    error: 'Text',
    obscure: true,
  );
  print(v1.label);
  print(v1.hint);
  print(v1.error);
  print(v1.obscure);
  final v2 = CivicShellFrame(
    places: const [],
    selectedIndex: 1,
    onSelected: (_) {},
    child: const SizedBox(),
  );
  print(v2.places);
  print(v2.onSelected);
  final v3 = CivicHost(child: const SizedBox(), light: null, dark: null);
  print(v3.light);
  print(v3.dark);
  final v4 = CivicPreview(
    child: const SizedBox(),
    light: null,
    dark: null,
    activeIndex: 1,
  );
  print(v4.light);
  print(v4.dark);
  print(v4.activeIndex);
  final v5 = CivicPageDots(count: 1, index: 1, onChanged: (_) {});
  print(v5.count);
  print(v5.index);
  print(v5.onChanged);
  final v6 = CivicStepIndicator(steps: const [], current: 1);
  print(v6.current);
  final v7 = CivicIconButton(
    icon: const IconData(0xe000),
    semanticLabel: 'Text',
    onPressed: () {},
    selected: true,
  );
  print(v7.selected);
  final v8 = CivicBadge(count: 1, noun: 'Text', max: 1);
  print(v8.max);
  print([v1, v2, v3, v4, v5, v6, v7, v8]);
}
