// The rows check's everyday case, part 2 of 2 (screen_checks.dart): every
// screen and gallery page once, the width, appearance and density turning
// over them, read in two files side by side.
@Tags(['goldens'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'screen_checks.dart';

void main() => screenRowsOnce(1, 2);
