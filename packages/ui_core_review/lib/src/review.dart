/// Whether a look's controls line up where they share a line: in a row of
/// controls of one size, one height, one vertical centre, and every label's
/// and text entry's capitals on that centre (what the eye compares; one
/// baseline only among labels of one size and style); each icon's ink
/// centred in its control; and the same sizes and places on every platform
/// the look runs on.
///
/// These are a look's own rules, not universal truth: the review checks its
/// grid and its taste, and each look passes its own numbers (its sizes, its
/// keylines, its widths, its gaps). Our looks' QA tool, never published. A
/// look fills a [DesignAlignmentMatrix] with its own controls, one
/// [DesignAlignmentRow] per size; its tests call
/// [DesignAlignmentMatrix.check] and its review page shows a
/// [DesignAlignmentSheet]. Its tests also give each of its text entries to a
/// [DesignTextEntryCheck], its cards to a [DesignKeylineCheck], its rows to
/// a [DesignRowCheck], its controls' widths to a [DesignWidthCheck], its
/// gaps to a [DesignSpacingCheck] and its fields' own parts to a
/// [DesignFieldPartsCheck]. A test that uses one imports this library in
/// place of the checks' library, which it re-exports.
///
/// What keeps a line straight, for a look's author:
/// - one control height per size and density, taken by every control that
///   can share a line;
/// - content centred in a box of that height, rather than padding added to
///   a line height;
/// - even leading ([TextLeadingDistribution.even]) on control labels, so a
///   label's line box is centred on its glyphs;
/// - a row that centres its controls, never one that aligns them to the
///   bottom or the top;
/// - a theme under the look that pins its density. Material's
///   `ThemeData.visualDensity` is compact on desktop unless the theme says
///   otherwise, and a test runs as Android, so no test sees it;
/// - a text entry that is a `TextField` (validated by the look's own
///   `FormField`, never a `TextFormField`) inside the look's own box, its
///   decoration null or collapsed with `contentPadding`, `constraints`,
///   `isDense` and `visualDensity` all set, its one line centred by
///   alignment, and its icons, counter, help and error the look's own
///   widgets beside or under the box: a decoration field left unset is
///   filled from the platform and the host theme.
library;

import 'dart:math' as math;

import 'dart:ui' show SemanticsInputType;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:ui_core/ui_core.dart';

import 'internal/drawn_pixels.dart';
import 'internal/label_line.dart';

import 'package:ui_core_test/ui_core_test.dart';

part 'checks/review/alignment_matrix.dart';
part 'checks/review/field_parts_check.dart';
part 'checks/review/keyline_check.dart';
part 'checks/review/row_check.dart';
part 'checks/review/spacing_check.dart';
part 'checks/review/width_check.dart';
part 'checks/shared/reading.dart';
part 'checks/shared/shape.dart';
