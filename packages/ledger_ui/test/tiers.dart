// The tiers of Ledger's tests. The everyday run, `flutter test --exclude-tags goldens,sweep`, keeps a case of every
// matrix: each page, size, appearance and density at least once, the values turning over the cases, so a fault class
// is still caught on every run. The pixel checks run on macOS, `flutter test --tags goldens --exclude-tags sweep`.
// The rest of each matrix is tagged `sweep`: `flutter test --tags sweep` runs it, and a full run (`flutter test`, at
// READY and release) runs every tier.

/// The tag of a case only the full sweep runs.
const String sweep = 'sweep';

/// The tags of one case of a matrix: none when [everyday], so every run has it, else [sweep].
List<String>? sweepUnless(bool everyday) => everyday ? null : const [sweep];

/// The tags of one pixel case of a matrix: goldens, and [sweep] unless [everyday].
List<String> goldensSweepUnless(bool everyday) => [
  'goldens',
  if (!everyday) sweep,
];

/// The value of [values] for the [i]th case of a matrix: the values turn over the cases, so every value has a case.
T turn<T>(List<T> values, int i) => values[i % values.length];
