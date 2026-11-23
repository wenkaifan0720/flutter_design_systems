import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

Widget branches() => TermCombobox<String>(
  labelText: 'branch',
  options: const ['main'],
  errorText: 'search failed, try later',
);

Widget regions() => TermTagInput<String>(
  values: const [],
  onChanged: (_) {},
  errorText: 'search failed, try later',
);

String words(TermCombobox<String> box, TermTagInput<String> tags) =>
    box.errorText + tags.errorText;
