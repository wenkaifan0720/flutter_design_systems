// The test tiers. `flutter test --exclude-tags goldens,sweep` is the one to
// run on every change: each matrix (a screen or a part at every width, night
// and paper, right to left, twice the text) runs one case per screen or part,
// in turn, so across them every width, both themes, right to left and 200%
// text are still met. `--tags sweep` runs the rest of each matrix, and
// `--tags goldens` the pictures (recorded on macOS), before a release.

/// The tags of case [cell] of the [cells] cases a matrix runs [subject] (a
/// screen's or a part's number) through: none on the subject's turn
/// (`subject % cells`), so the everyday tier runs it, else `sweep`.
List<String>? sweepUnlessTurn(int subject, int cell, int cells) =>
    cell == subject % cells ? null : const ['sweep'];
