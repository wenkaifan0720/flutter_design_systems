import 'package:minimal_ui/minimal_ui.dart';

/// A select's options: two to choose and one that is turned off.
const selectOptions = [
  MinimalSelectOption('daily', 'Every day'),
  MinimalSelectOption('evening', 'Every evening', subtitle: 'After 18:00'),
  MinimalSelectOption('custom', 'Custom…', enabled: false),
];
