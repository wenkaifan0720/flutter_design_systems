// ui_core's row check (rows_widths_checks.dart) in Fluent 2's comfortable density, by day and by night, over every gallery
// page and the app screens: controls sharing a row show one top and one bottom by their drawn outline.
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';
import 'rows_widths_checks.dart';

void main() {
  setUpAll(loadFluent2TestFonts);
  rowChecks('comfortable');
}
