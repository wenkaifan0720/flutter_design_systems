// The sweep of Brindlemere's screens at a phone's 390 (screens_matrix.dart):
// every setting there that the everyday run did not deal the screen.
@Tags(['sweep'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'screens_matrix.dart';

void main() {
  setUpAll(loadScreenFonts);
  screensMatrix((i, j) => !everyRun(i, j) && screenSettings[j].$1 == 390);
}
