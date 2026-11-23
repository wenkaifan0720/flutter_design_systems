// The names clay_ui 0.3.0 renames: clay_parts.dart calls them as before `dart fix --apply`,
// clay_parts.dart.expect as after.
import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_parts.dart';

void calls() {
  final v1 = ClayEntryText(
    controller: TextEditingController(),
    focusNode: FocusNode(),
    hint: 'Text',
  );
  print(v1.hint);
  final v2 = const ClayMenuEntry<String>(
    value: 'Text',
    label: 'Text',
    destructive: true,
  );
  print(v2.destructive);
  final v3 = const ClayMenuRow(label: 'Text', states: {}, destructive: true);
  print(v3.destructive);
}
