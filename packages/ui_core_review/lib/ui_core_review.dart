/// A layout review for design systems on ui_core, never published: a look's own rows, keylines, widths, spacing, a
/// field's own parts and its alignment matrix, each held to the look's own numbers. It re-exports ui_core_test, so
/// a test that takes a review check imports this library in place of that one.
library;

export 'package:ui_core_test/ui_core_test.dart';

export 'src/review.dart';
