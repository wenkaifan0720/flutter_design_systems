/// A row of related actions joined into one bordered bar: a toolbar.
library;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/give_way_row.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// One action of a [MinimalButtonGroup]: words, a glyph, or both. A glyph
/// alone names itself to a screen reader through [semanticLabel].
@immutable
class MinimalButtonGroupItem {
  /// A cell of a [MinimalButtonGroup]: a label, a glyph or both.
  const MinimalButtonGroupItem({
    this.label,
    this.icon,
    this.onPressed,
    this.semanticLabel,
    this.iconTrails = false,
  }) : assert(
         label != null || (icon != null && semanticLabel != null),
         'an action says its label, or shows a glyph and names it',
       );

  /// What the cell says.
  final String? label;

  /// Its glyph.
  final IconData? icon;

  /// Null disables this action alone.
  final VoidCallback? onPressed;

  /// What a screen reader hears for a glyph-only action.
  final String? semanticLabel;

  /// Whether the glyph follows the words rather than leading them: a
  /// Next's chevron trails its word, a Previous's leads it.
  final bool iconTrails;
}

/// Related actions joined into one bar — a document's Bold, Italic and
/// Link, a list's Previous and Next, an editor's Undo and Redo. One
/// bordered frame on the `shapes.small` step holds them, split by
/// full-height hairlines; each action is a cell that fills its slot edge to
/// edge, so its press wash and focus ring take the cell's exact shape: the
/// frame's corners at the ends, square where it meets a neighbour.
///
/// It is the secondary register of [MinimalButton], joined: use it where
/// the actions belong together and read left to right. A lone action, or
/// the page's one thing to do, is a [MinimalButton].
///
/// [style] dresses the frame, over `components.secondaryButton`: fill,
/// foreground, edge or side, shape, padding, textStyle and iconSize.
///
/// ```dart
/// MinimalButtonGroup(items: [MinimalButtonGroupItem(label: 'Day', onPressed: day), MinimalButtonGroupItem(label: 'Week', onPressed: week)])
/// ```
class MinimalButtonGroup extends StatelessWidget {
  /// Buttons joined in one outline.
  const MinimalButtonGroup({
    super.key,
    required this.items,
    this.style,
    this.expand = false,
  });

  /// The cells, start to end.
  final List<MinimalButtonGroupItem> items;

  /// The bar's style, over `components.secondaryButton`.
  final MinimalStyle? style;

  /// Fill the available width, every action an equal share: a phone's
  /// column, up to the control measure (`MinimalLayout.controlMax`) from a
  /// tablet up.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    // A const list's length is not a constant, so the count is checked here
    // and the constructor stays const.
    assert(items.isNotEmpty, 'a group holds at least one action');
    final t = context.minimalTheme;
    final layers = <MinimalStyle?>[style, t.components.secondaryButton];
    final so = MinimalStyleOf(layers, const {});
    final frame = so.shape ?? t.shapes.small;
    final rim = so.rim(t.border, t.rim);
    final height = t.density.height(MinimalChromeMetrics.control);
    final n = items.length;
    // The hairline between two cells, the frame's own rim: full height
    // inside the frame, so it meets the rim top and bottom.
    Widget hairline() => Container(width: rim.width, color: rim.color);
    Widget cell(int i) => _Cell(
      item: items[i],
      layers: layers,
      shape: minimalCell(frame, index: i, count: n, inset: rim.width),
      height: height - 2 * rim.width,
    );

    // The frame's decoration already pads its content by the rim's width,
    // so the cells and hairlines start right inside the rim.
    final bar = Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        height: height,
        decoration: minimalFrame(frame, fill: so.fill ?? t.card, side: rim),
        child: expand
            // Even shares in whole pixels (the leftover pixels one each to
            // the first cells), so every hairline lands on a pixel and
            // draws one sharp line rather than two pale halves.
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final free = constraints.maxWidth - (n - 1) * rim.width;
                  final whole = free.isFinite ? free.floor() : 0;
                  final share = whole ~/ n;
                  final extra = whole - share * n;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) hairline(),
                        Expanded(
                          flex: share < 1 ? 1 : share + (i < extra ? 1 : 0),
                          child: cell(i),
                        ),
                      ],
                    ],
                  );
                },
              )
            // Each cell keeps its width where the words fit; where they do
            // not (large text, a phone's column) the cells give way in
            // proportion and ellipsize, the hairlines between them kept.
            // A cell's width is rounded up to a whole pixel so the
            // hairlines fall on pixels.
            : MinimalGiveWayRow(
                stretch: true,
                fixed: {for (var i = 1; i < n; i++) 2 * i - 1},
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) hairline(),
                    IntrinsicWidth(stepWidth: 1, child: cell(i)),
                  ],
                ],
              ),
      ),
    );
    // Expanded, it fills a phone's column and stops at the control measure
    // (320) from a tablet up, as an expanded button.
    if (expand) return MinimalLayout.capControl(context, bar);
    // The frame hugs its cells, also in a column that stretches it.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: bar,
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.item,
    required this.layers,
    required this.shape,
    required this.height,
  });

  final MinimalButtonGroupItem item;
  final List<MinimalStyle?> layers;
  final OutlinedBorder shape;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final label = item.label;
    final icon = item.icon;
    return MinimalPressable(
      onPressed: item.onPressed,
      enabled: item.onPressed != null,
      shape: shape,
      // The cell's ring stays inside the frame: outside it would cross the
      // neighbour's hairline.
      focusInside: true,
      semanticLabel: item.semanticLabel,
      builder: (context, states) {
        final so = MinimalStyleOf(layers, states);
        final ink = so.foreground ?? t.foreground;
        final glyph = icon == null
            ? null
            : MinimalIcon(
                icon,
                size: so.iconSize ?? MinimalIconSize.i16,
                color: ink,
              );
        final trails = item.iconTrails && label != null;
        return Container(
          height: height,
          padding:
              so.padding ??
              t.density.padding(
                EdgeInsets.symmetric(
                  horizontal: label == null
                      ? MinimalSpacing.s8
                      : MinimalSpacing.s12,
                ),
              ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyph != null && !trails) glyph,
              if (glyph != null && label != null && !trails)
                const MinimalGap(MinimalChromeMetrics.iconGap),
              if (label != null)
                Flexible(
                  child: minimalCapLabel(
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: so.text(t.control, ink),
                    ),
                  ),
                ),
              if (glyph != null && trails) ...[
                const MinimalGap(MinimalChromeMetrics.iconGap),
                glyph,
              ],
            ],
          ),
        );
      },
    );
  }
}
