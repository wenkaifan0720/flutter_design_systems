// The rest of the screen checks' sweep (screen_checks.dart): the outline at
// every size, density and appearance, and the width check on every screen,
// page, dialog and sheet at each width; screen_checks_test.dart reads their
// everyday cases.
@Tags(['goldens', 'sweep'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'screen_checks.dart';

void main() => screenSweep();
