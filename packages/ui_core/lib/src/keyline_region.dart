/// A card or a section whose contents share keylines, and a face the
/// checks in `alignment.dart` cannot read from its pixels.
library;

import 'package:flutter/widgets.dart';

/// Marks [child] as a card or a section whose contents share keylines: a
/// keyline is the line that what starts a row (or ends one) sits on, so a
/// card's title, its rows' words, its fields and its dividers start on one
/// line, and its switches, chevrons and selects end on another.
///
/// It lays out and paints nothing. A look's own card and section widgets put
/// it around their content once, so every screen built from them is
/// checked; `DesignKeylineCheck` in `alignment.dart` reads it, and
/// `DesignKeylineSheet` draws it for review.
///
/// A gallery marks each section's column of examples too, with
/// [startAligned], so every example starts on the column's edge.
///
/// ```dart
/// DesignKeylineRegion(label: 'Settings', indents: const [40], child: const Text('Settings'))
/// ```
class DesignKeylineRegion extends StatelessWidget {
  /// Marks [child].
  const DesignKeylineRegion({
    super.key,
    this.label,
    this.indents = const [],
    this.trailingIndents = const [],
    this.mixedHeights,
    this.startAligned = false,
    required this.child,
  });

  /// What the check and the sheet call it.
  final String? label;

  /// The leading keylines allowed besides the first, each this many logical
  /// pixels further in: a nested level you mean, such as rows' words after
  /// their 40 px avatars.
  final List<double> indents;

  /// The same at the trailing side: keylines allowed this many pixels in
  /// from the first trailing one.
  final List<double> trailingIndents;

  /// Why controls that share a row here may differ in height or centre
  /// (a gallery's ladder of one control per size, side by side on
  /// purpose); null: they may not. `DesignKeylineCheck` and
  /// `DesignRowCheck` leave such rows unheld, and name a to-do given here.
  final String? mixedHeights;

  /// Whether every row here starts on the leading keyline, however it is
  /// aligned: a gallery section's examples, each on its column's edge,
  /// where one centred (a stepper, a sum, a line of words centred in its
  /// box) or set at the trailing end is off. False (a card, a dialog): a
  /// row of one item may stand centred (an empty state) or at the end (a
  /// dialog's actions).
  final bool startAligned;

  /// The card's or the section's content.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Marks [child] as one face for the checks in `alignment.dart`: a
/// control's face or a well (a field's, a list's, a table's) whose pixels
/// may not show it, or a picture with things placed on it.
///
/// It lays out and paints nothing. The checks find a face by what it
/// paints, so a look marks its own face and well widgets when their pixels
/// cannot show them: a face in the colour of the ground drawn only by its
/// shadows, a pane of glass, or a picture whose marks (a floor plan's room
/// keys) are not items to line up. `DesignKeylineCheck` takes the marked
/// box as one item, before it looks at pixels, and reads nothing inside it
/// as an item of the region around it; to have what a well holds judged
/// by keylines of its own, put a [DesignKeylineRegion] inside it.
/// `DesignLabelCheck` takes it as the face of the control it is in.
///
/// ```dart
/// DesignKeylineFace(child: SizedBox(width: 120, height: 40))
/// ```
class DesignKeylineFace extends StatelessWidget {
  /// Marks [child].
  const DesignKeylineFace({super.key, required this.child});

  /// The face, the well or the picture.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
