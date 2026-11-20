// The rows check at 1440 by day: every screen and gallery page under each
// density (screen_checks.dart). The sweep; screen_rows_part_<n>_test.dart
// reads each page once.
@Tags(['goldens', 'sweep'])
library;

import 'dart:ui' show Brightness;

import 'package:flutter_test/flutter_test.dart';

import 'screen_checks.dart';

void main() => screenRowsSweep(1440, Brightness.light);
