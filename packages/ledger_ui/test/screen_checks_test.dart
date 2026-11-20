// The screen checks, each matrix by its everyday cases (screen_checks.dart).
// The rows check's everyday case runs in screen_rows_part_<n>_test.dart; the
// sweep files run the rest, each in its own process:
// screen_rows_<width>_<day|night>_test.dart and screen_sweep_test.dart.
import 'screen_checks.dart';

void main() => screenChecksMain();
