import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// Geometry the small controls share — the filter pill, the tabs' counts,
/// the segmented track — named once so a chip, a tab strip and a property
/// pill cannot drift apart. Not exported: pages never need it.
abstract final class MinimalControlMetrics {
  /// A pill's side padding, and its tighter start before a glyph.
  static const double pillPad = 9;

  /// A pill's tighter start padding before a glyph.
  static const double pillPadGlyph = 8;

  /// A pill's label size: the sm button's, a half step under
  /// [MinimalThemeData.control].
  static const double pillLabel = 12.5;

  /// The size of a mono count beside a label (a chip's, a tab's).
  static const double countFigure = 11;

  /// The gap between a label and its count.
  static const double countGap = 6;

  /// A segmented track's inset around its thumb, and a segment's side
  /// padding around its label.
  static const double segmentInset = 2;

  /// A segment's side padding around its label.
  static const double segmentPad = 10;

  /// The steady width of a stepper's value slot, in ems of its figure: room
  /// for three figures and a short unit (`20 pages`, `10 min`), so steppers
  /// stacked in a form share one footprint, with a unit or without.
  static const double stepperValueEm = 4.5;
}

/// Where an arrow key walks a strip of views (a segmented track, a tab
/// strip): one step each way, or to either end.
enum MinimalSeek {
  /// One step right.
  right,

  /// One step left.
  left,

  /// To the first.
  first,

  /// To the last.
  last,
}

/// The keyboard walk of a strip of views, as an intent.
class MinimalSeekIntent extends Intent {
  /// An intent to move by [seek].
  const MinimalSeekIntent(this.seek);

  /// Which way, and how far.
  final MinimalSeek seek;
}

/// The arrow, Home and End keys every strip of views binds.
const Map<ShortcutActivator, Intent> minimalSeekShortcuts =
    <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowRight): MinimalSeekIntent(
        MinimalSeek.right,
      ),
      SingleActivator(LogicalKeyboardKey.arrowLeft): MinimalSeekIntent(
        MinimalSeek.left,
      ),
      SingleActivator(LogicalKeyboardKey.home): MinimalSeekIntent(
        MinimalSeek.first,
      ),
      SingleActivator(LogicalKeyboardKey.end): MinimalSeekIntent(
        MinimalSeek.last,
      ),
    };

/// The index [seek] lands on from [index] in a strip whose last view is
/// [last]; the arrows follow the reading direction.
int minimalSeekIndex(
  MinimalSeek seek, {
  required int index,
  required int last,
  required bool rtl,
}) {
  final forward = rtl ? -1 : 1;
  return switch (seek) {
    MinimalSeek.right => (index + forward).clamp(0, last),
    MinimalSeek.left => (index - forward).clamp(0, last),
    MinimalSeek.first => 0,
    MinimalSeek.last => last,
  };
}

/// The least a tap reaches on a control at [context], by what reaches it:
/// the floors [MinimalTheme] declares ([MinimalLayout.tapTargets]), 44 for
/// a finger and 24 for a pointer. A row or a strip that is its own tap
/// target stands at least this tall; a compact face stands in the same
/// target with more room round it, so density never moves it.
double minimalTapFloor(BuildContext context) =>
    DesignTapTargets.of(context).floorOn().height;

/// A control's [height] grown by what the text scale adds to its 16 px
/// label line, so the words keep at 130% the air they have at 100% (the
/// control grows taller rather than crowd its words); [height] itself at
/// 100% and below.
double minimalGrownHeight(BuildContext context, double height) {
  final line = MediaQuery.textScalerOf(context).scale(16);
  return line <= 16 ? height : height + line - 16;
}

/// The mono count style beside a label: [MinimalThemeData.mono] at
/// [MinimalControlMetrics.countFigure].
extension MinimalCountFigure on MinimalThemeData {
  /// The mono face at a count's size.
  TextStyle get countFigure =>
      mono.copyWith(fontSize: MinimalControlMetrics.countFigure);
}

/// A clip as large as its box and a focus ring's reach round it (its gap and
/// its stroke): what cuts a scrolled run of controls without cutting the
/// ring of the one at its edge.
class MinimalRingRoom extends CustomClipper<Rect> {
  /// The clip.
  const MinimalRingRoom();

  @override
  Rect getClip(Size size) =>
      (Offset.zero & size).inflate(2 * MinimalChromeMetrics.focusRing);

  @override
  bool shouldReclip(MinimalRingRoom oldClipper) => false;
}
