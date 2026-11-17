// The rows check's everyday case, part 1 of 2 (design6_support.dart): every screen and gallery page once, the width,
// appearance and density turning over them, read in two files side by side.
@Tags(['goldens'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'design6_support.dart';

void main() => design6RowsOnce(0, 2);
