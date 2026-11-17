// design6's rows check at 390 by night: every screen and gallery page under each density (design6_support.dart). The
// sweep; design6_test.dart reads each page once.
@Tags(['goldens', 'sweep'])
library;

import 'dart:ui' show Brightness;

import 'package:flutter_test/flutter_test.dart';

import 'design6_support.dart';

void main() => design6RowsSweep(390, Brightness.dark);
