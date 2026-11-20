// The test tiers. The
// everyday tier, `flutter test --exclude-tags goldens,sweep`, keeps one
// representative case of each exhaustive matrix (a page per size, a theme each
// way, right to left once, 200% text once); `flutter test --tags sweep` runs
// the other cases, and a run with no tag filter runs every case.

/// The tags of one case of an exhaustive matrix: none for its representative
/// ([everyday]), which every tier runs; `sweep` for the rest.
List<String>? sweepUnless(bool everyday) => everyday ? null : const ['sweep'];
