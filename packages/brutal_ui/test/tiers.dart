// The tiers of Brutal's tests. The everyday run, `flutter test --exclude-tags
// goldens,sweep`, keeps a representative of every matrix: each part, screen
// and value of each axis (width, day and night, right to left, 200% text,
// platform) at least once, the values turning over the cases, so a fault
// class is still caught on every run. The rest of each matrix is tagged
// `sweep`; `flutter test --tags sweep` runs it, and a full run (`flutter
// test`, at READY and release) runs every tier.
library;

/// The tag of a case only the full sweep runs.
const sweep = 'sweep';

/// The tags of one case of a matrix: none when [everyday], so every run has
/// it, else [sweep].
List<String>? sweepUnless(bool everyday) => everyday ? null : const [sweep];
