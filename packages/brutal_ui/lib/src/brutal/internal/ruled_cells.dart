import 'package:flutter/widgets.dart';

import '../surface.dart';
import '../theme.dart';

/// How far a cell's fill runs past each of its sides, under the rules [brutalRuledCells] draws over its cells: zero on
/// a side no rule covers.
class BrutalCellReach extends InheritedWidget {
  /// [reach] for the cells in [child].
  const BrutalCellReach({super.key, required this.reach, required super.child});

  /// How far past each side.
  final EdgeInsetsGeometry reach;

  /// The nearest reach; zero outside a ruled row.
  static EdgeInsets of(BuildContext context) =>
      (context.dependOnInheritedWidgetOfExactType<BrutalCellReach>()?.reach ??
              EdgeInsets.zero)
          .resolve(Directionality.of(context));

  @override
  bool updateShouldNotify(BrutalCellReach old) => reach != old.reach;
}

/// [child], a cell's face drawn with no fill of its own, over [fill] reaching [reach] past the cell's sides. Two shapes
/// of one ink that meet on a fraction of a pixel each shade the pixel they share, and a light seam shows between
/// them; the fill runs on under the rule beside it instead, and the rule covers it.
class BrutalReachingFill extends StatelessWidget {
  /// [fill] under [child], [reach] past its sides.
  const BrutalReachingFill({
    super.key,
    required this.reach,
    required this.fill,
    required this.child,
  });

  /// How far past each side.
  final EdgeInsets reach;

  /// The cell's fill; it moves as a face's does.
  final Color fill;

  /// The cell's face.
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.passthrough,
    children: [
      Positioned(
        left: -reach.left,
        top: -reach.top,
        right: -reach.right,
        bottom: -reach.bottom,
        child: AnimatedBrutalSurface(
          stiffness: BrutalMotion.colorStiffness,
          face: BrutalFace(
            fill: fill,
            border: fill.withValues(alpha: 0),
            foreground: fill,
            borderWidth: 0,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      child,
    ],
  );
}

/// [cells] in a row, each [width] wide or, when null, an equal share, a [rule] between each two drawn over them, so a
/// cell's fill can run under the rules round it ([reach] for the cell at an index). The rules run [ruleRise] up past
/// the row's top, under a rule across it drawn after, so the two meet on no shared pixel either.
Widget brutalRuledCells({
  required List<Widget> cells,
  required double gap,
  required Widget Function() rule,
  required EdgeInsetsGeometry Function(int index) reach,
  double? width,
  MainAxisSize mainAxisSize = MainAxisSize.max,
  double ruleRise = 0,
}) {
  Widget slot(Widget child) => width == null
      ? Expanded(child: child)
      : SizedBox(width: width, child: child);
  return Stack(
    clipBehavior: Clip.none,
    fit: StackFit.passthrough,
    children: [
      Row(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, cell) in cells.indexed) ...[
            if (i > 0) SizedBox(width: gap),
            slot(BrutalCellReach(reach: reach(i), child: cell)),
          ],
        ],
      ),
      Positioned(
        left: 0,
        right: 0,
        top: -ruleRise,
        bottom: 0,
        child: IgnorePointer(
          child: Row(
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) rule(),
                slot(const SizedBox()),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}
