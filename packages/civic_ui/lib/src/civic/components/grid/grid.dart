import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';

/// [children] in columns that follow the room: one below 600 wide, two to
/// 1024, three from there ([maxColumns] at most), each row's cells as tall
/// as its tallest, so cards side by side line up. Reading order stays the
/// children's order, row by row (mirrored right to left).
///
/// ```dart
/// CivicGrid(
///   children: [
///     CivicCard(title: 'Parking', child: Text('Permits, fines, bays')),
///     CivicCard(title: 'Bins', child: Text('Collections, new bins')),
///     CivicCard(title: 'Council tax', child: Text('Pay, discounts')),
///   ],
/// )
/// ```
class CivicGrid extends StatelessWidget {
  /// [children] in columns.
  const CivicGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
    this.spacing = CivicSpacing.s16,
  }) : assert(maxColumns > 0 && spacing >= 0);

  /// The cells, in reading order.
  final List<Widget> children;

  /// The most columns it uses, however wide.
  final int maxColumns;

  /// The gap between cells, both ways.
  final double spacing;

  /// How many columns [width] holds, at most [maxColumns].
  static int columnsFor(double width, {int maxColumns = 3}) => math.min(
    maxColumns,
    width < CivicLayout.medium
        ? 1
        : width < CivicLayout.expanded
        ? 2
        : 3,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = columnsFor(box.maxWidth, maxColumns: maxColumns);
      if (n == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: spacing,
          children: children,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: [
          for (var i = 0; i < children.length; i += n)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: spacing,
                children: [
                  for (var j = i; j < i + n; j++)
                    Expanded(
                      child: j < children.length
                          ? children[j]
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        ],
      );
    },
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('children', children.length))
      ..add(IntProperty('maxColumns', maxColumns, defaultValue: 3))
      ..add(DoubleProperty('spacing', spacing, defaultValue: CivicSpacing.s16));
  }
}
