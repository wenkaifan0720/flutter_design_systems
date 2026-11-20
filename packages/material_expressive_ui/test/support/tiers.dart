/// The everyday suite samples pages, widths, presets, settings and languages.
/// Run it with `flutter test --exclude-tags goldens,sweep`. The remaining
/// combinations run with `flutter test --tags sweep`.
library;

/// The tag for cases covered by the exhaustive suite.
const String sweep = 'sweep';

/// A matrix case's tags: none for an [everyday] representative, else
/// [sweep].
List<String> sweepUnless(bool everyday) =>
    everyday ? const <String>[] : const <String>[sweep];

/// Whether case [column] of [columns] is row [row]'s everyday case: the rows
/// take the columns in turn, so every row runs once a day and every column
/// as soon as there are as many rows.
bool everydayTurn(int row, int column, int columns) => row % columns == column;

/// Whether row [row] is one of the everyday rows of a matrix with a single
/// dimension: one in every [every], the first among them.
bool everydayEvery(int row, int every) => row % every == 0;

/// Whether case [column] of [columns] is met on row [row] of [rows] in the
/// everyday tier: each column once, on rows spread across the matrix (one
/// page per preset, size or mode). For a matrix whose rows are met every
/// run elsewhere: every gallery page is walked daily by gallery_live_test.
bool everydayOnce(int row, int column, int rows, int columns) =>
    row == column * rows ~/ columns;
