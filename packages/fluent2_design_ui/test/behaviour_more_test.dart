// The behaviour law (behaviour_law.dart) over the other half of the package's parts (behaviour_parts.dart):
// behaviour_test.dart takes every other part from the first, this file the rest, so neither sets the run's floor.
import 'behaviour_law.dart';
import 'behaviour_parts.dart';

void main() => behaviourLaw(
  behaviourParts,
  reads: (path) => !lawLeftOut(path),
  slice: 1,
  slices: 2,
);
