// The behaviour law (behaviour_law.dart) over the package's parts (behaviour_parts.dart): every part in the library
// that takes a callback, but the page patterns and the sign-in buttons, which the package leaves out. This file takes
// every other part from the first, and checks that the table names every part; behaviour_more_test.dart the rest.
import 'behaviour_law.dart';
import 'behaviour_parts.dart';

void main() => behaviourLaw(
  behaviourParts,
  reads: (path) => !lawLeftOut(path),
  slice: 0,
  slices: 2,
);
