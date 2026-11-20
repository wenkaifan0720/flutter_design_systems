// Gallery controls keep their row alignment and responsive width.
// - DesignRowCheck over every gallery page and the app screens, under each
//   density the look ships, by day and by night: controls sharing a row
//   show one top and one bottom by their drawn outline;
// - DesignWidthCheck over every gallery page and the app screens at 600,
//   1024, 1440 and 1920 wide, with a pointer (a desktop's or a tablet's
//   browser): a select, a button, a stepper or a segmented control keeps to
//   its content and padding, at most 320;
// - checkList on every select at 390 and 1440, with a pointer: its open
//   list at least the field's width, on its leading edge, its words on the
//   field's less the check column Fluent's listbox sets before them, as the
//   look declares it (ui_core_checks.dart); a select whose options carry
//   glyphs keeps their column in its face too.
// Each prints what it names as ROWS, WIDTHS or LIST lines into the log. The row check runs a file per density
// (rows_standard_test.dart, rows_comfortable_test.dart, rows_compact_test.dart); the checks are in
// rows_widths_checks.dart.
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';
import 'rows_widths_checks.dart';

void main() {
  setUpAll(loadFluent2TestFonts);
  widthChecks();
  listChecks();
}
