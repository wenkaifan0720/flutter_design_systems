import 'package:material_ui/material_ui.dart';

import '../kit.dart';

/// Choices that open a panel: a combobox, tags, chips, a drop zone, dates, a time and a colour.
Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Pickers',
  sections: kitSpecimens(const [
    'Combobox',
    'MultiSelect',
    'Chip',
    'FileUpload',
    'DatePicker',
    'DateRangePicker',
    'TimePicker',
    'Calendar',
    'ColorPicker',
  ]),
);
