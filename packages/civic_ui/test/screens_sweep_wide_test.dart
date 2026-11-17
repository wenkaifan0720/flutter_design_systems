// The sweep of Brindlemere's screens wider than a phone, at 768 and 1440
// (screens_matrix.dart): every setting there that the everyday run did not
// deal the screen.
@Tags(['sweep'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'screens_matrix.dart';

void main() {
  setUpAll(loadScreenFonts);
  screensMatrix((i, j) => !everyRun(i, j) && screenSettings[j].$1 > 390);
}
