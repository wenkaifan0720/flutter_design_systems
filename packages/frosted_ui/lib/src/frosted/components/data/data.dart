import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/panel.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../marks/marks.dart';
import '../move/move.dart';
import '../pressable/pressable.dart';
import '../../internal/cap.dart';

export 'package:ui_core/ui_core.dart'
    show DesignTableColumn, DesignTableController;
export 'package:ui_core/ui_core.dart' show DesignTreeController;

// ---------------------------------------------------------------------------
// Data table
// ---------------------------------------------------------------------------

/// A table of records to sort, select and page through (Material's
/// DataTable, shadcn's data table): the column names over hairline-ruled
/// rows 52 tall on the glass, a sortable column's name pressed to sort it
/// (its chevron saying which way), a check at each row's start and one over
/// them for the whole page, the chosen rows on the accent's wash, the page
/// numbers under the table once there is more than a page. One Tab stop
/// for the rows: the arrows walk them, Space selects, Shift extends, Return
/// opens a row with [onActivate]. ui_core's [DesignDataTable] and
/// [DesignTableController] are the behaviour.
///
/// ```dart
/// FrostedDataTable<({String payee, int cents})>(controller: DesignTableController(rows: payments, pageSize: 10, columns: [DesignTableColumn(id: 'who', label: 'Payee', sortKey: (p) => p.payee), DesignTableColumn(id: 'sum', label: 'Amount', numeric: true, sortKey: (p) => p.cents)]), cellBuilder: (context, p, column) => Text(column.id == 'who' ? p.payee : money(p.cents)))
/// ```
class FrostedDataTable<R> extends StatelessWidget {
  /// A table of [controller]'s rows, each cell from [cellBuilder].
  const FrostedDataTable({
    required this.controller,
    required this.cellBuilder,
    this.selectable = true,
    this.onActivate,
    this.label,
    super.key,
  });

  /// The rows, columns, sort, pages and selection.
  final DesignTableController<R> controller;

  /// Builds a cell (a [Text] takes the table's type).
  final Widget Function(
    BuildContext context,
    R row,
    DesignTableColumn<R> column,
  )
  cellBuilder;

  /// Whether rows carry a check and can be selected.
  final bool selectable;

  /// Called as Return or a double press opens a row.
  final ValueChanged<R>? onActivate;

  /// What a screen reader calls the table.
  final String? label;

  static const double _row = 52;
  static const double _head = 40;
  static const double _check = 44;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final columns = controller.columns;
    // The header row is at least the touch target tall: its heads sort.
    final head0 = math.max(_head, FrostedBreakpoints.hitTargetOf(context));
    Widget celled(DesignTableColumn<R> column, Widget child) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.s12),
        child: Align(
          alignment: column.numeric
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: child,
        ),
      ),
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final table = FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(FrostedCorners.r18),
          color: t.glass.fill,
          ring: t.glass.edge,
          clipChild: true,
          child: Semantics(
            label: label,
            container: true,
            child: DesignDataTable<R>(
              controller: controller,
              selectable: selectable,
              onActivate: onActivate,
              // The rule under the heads is painted over them, so it takes
              // nothing from their height.
              headerRowBuilder: (context, cells) => Container(
                height: head0,
                color: t.glass.wash,
                foregroundDecoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: t.colorScheme.border),
                  ),
                ),
                child: Row(
                  children: [
                    if (selectable)
                      SizedBox(
                        width: _check,
                        child: Center(
                          child: FrostedCheckbox(
                            value: switch (controller.pageSelection) {
                              DesignSelection.none => false,
                              DesignSelection.some => null,
                              DesignSelection.all => true,
                            },
                            label: words.selectAll,
                            onChanged: (_) => controller.togglePage(),
                          ),
                        ),
                      ),
                    for (final (i, cell) in cells.indexed)
                      celled(columns[i], cell),
                  ],
                ),
              ),
              headerBuilder: (context, column, sort, states) {
                final lit =
                    states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.pressed) ||
                    sort != null;
                final words = frostedCapCentred(
                  Text(
                    column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.labelSmall.semibold.c(
                      lit
                          ? t.colorScheme.textPrimary
                          : t.colorScheme.textSecondary,
                    ),
                  ),
                );
                final head = !column.sortable
                    ? words
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: FrostedSpacing.s4,
                        children: [
                          Flexible(child: words),
                          Icon(
                            switch (sort) {
                              null => FrostedGlyphs.sort,
                              DesignSortDirection.ascending =>
                                FrostedGlyphs.chevronUp,
                              DesignSortDirection.descending =>
                                FrostedGlyphs.chevronDown,
                            },
                            size: 14,
                            color: sort == null
                                ? t.colorScheme.textTertiary
                                : t.colorScheme.textPrimary,
                          ),
                        ],
                      );
                // A sortable head answers its whole cell, the header row
                // as tall as the touch target.
                return SizedBox(
                  height: head0,
                  width: double.infinity,
                  child: Align(
                    alignment: column.numeric
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: frostedRingFor(states, head, radius: 4),
                  ),
                );
              },
              cellBuilder: (context, row, column) => DefaultTextStyle.merge(
                style:
                    (column.numeric
                            ? t.textTheme.titleMedium.tabular
                            : t.textTheme.titleMedium)
                        .c(t.colorScheme.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // One line in the body face: its capitals on the row's middle.
                child: DesignCapCenter(
                  capHeightFactor: frostedSansCap,
                  child: cellBuilder(context, row, column),
                ),
              ),
              rowBuilder: (context, row, cells) {
                final lit =
                    row.states.contains(WidgetState.hovered) ||
                    row.states.contains(WidgetState.pressed);
                // A row lighting under the pointer or being chosen eases.
                final motion = FrostedMotion.of(context);
                final face = AnimatedContainer(
                  duration: motion.fast,
                  curve: motion.curve,
                  height: _row,
                  decoration: BoxDecoration(
                    color: row.selected
                        ? t.colorScheme.accentSubtle
                        : (lit ? t.glass.wash : null),
                  ),
                  // The rule drawn over the row, taking no room: the cells
                  // keep the row's middle.
                  foregroundDecoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: t.colorScheme.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (selectable)
                        SizedBox(
                          width: _check,
                          child: Center(
                            child: FrostedCheckbox(
                              value: row.selected,
                              label: words.selectRow,
                              onChanged: (_) => row.toggle(),
                            ),
                          ),
                        ),
                      for (final (i, cell) in cells.indexed)
                        celled(columns[i], cell),
                    ],
                  ),
                );
                return FrostedFocusRing(
                  shown: row.states.contains(WidgetState.focused),
                  child: face,
                );
              },
            ),
          ),
        );
        final pages = controller.pageCount;
        if (pages <= 1) return table;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostedSpacing.s12,
          children: [
            table,
            Center(
              child: FrostedPagination(
                pageCount: pages,
                selectedIndex: controller.page,
                onChanged: controller.goToPage,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tree view
// ---------------------------------------------------------------------------

/// Nested rows to open and close (Material's TreeView, a folder list):
/// each row indented 20 a level, a chevron before a row with children
/// (turned down while open), its [leadingOf] glyph and [labelOf] words;
/// the chosen row on the accent's wash. One Tab stop for the tree: Up and
/// Down walk the visible rows, Right opens (then steps in), Left closes
/// (then steps out), Home and End go to the ends, Return opens a row with
/// [onActivate]. A screen reader hears each row's level and place.
/// ui_core's [DesignTree] is the behaviour.
///
/// ```dart
/// FrostedTreeView<String>(controller: DesignTreeController(roots: const ['Bills', 'Trips'], childrenOf: (f) => folders[f] ?? const <String>[]), labelOf: (f) => f, onActivate: open)
/// ```
class FrostedTreeView<T extends Object> extends StatelessWidget {
  /// A tree of [controller]'s nodes.
  const FrostedTreeView({
    required this.controller,
    required this.labelOf,
    this.leadingOf,
    this.onActivate,
    this.label,
    super.key,
  });

  /// The nodes, which are open and which chosen.
  final DesignTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's glyph, before its words.
  final Widget? Function(T node)? leadingOf;

  /// Called as Return or a press opens a node.
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls the tree.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return DesignTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: label,
      rowBuilder: (context, item) {
        final states = item.states;
        final lit =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        final lead = leadingOf?.call(item.row.node);
        // A row is at least the touch target tall (48 under a finger).
        final face = SizedBox(
          height: math.max(
            FrostedChromeMetrics.menuItem,
            FrostedBreakpoints.hitTargetOf(context),
          ),
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.menuItemRadius),
            color: item.selected
                ? t.colorScheme.accentSubtle
                : (lit ? t.glass.wash : null),
            padding: EdgeInsetsDirectional.only(
              start: FrostedSpacing.s4 + 20.0 * item.row.depth,
              end: FrostedSpacing.s10,
            ).resolve(Directionality.of(context)),
            child: Row(
              spacing: FrostedSpacing.s6,
              children: [
                SizedBox.square(
                  dimension: 28,
                  child: item.hasChildren
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: item.toggle,
                          child: Semantics(
                            button: true,
                            label: item.expanded
                                ? DesignLocalizations.of(context)
                                      .expandedIconTapHint
                                : DesignLocalizations.of(context)
                                      .collapsedIconTapHint,
                            excludeSemantics: true,
                            child: AnimatedRotation(
                              turns: item.expanded ? .25 : 0,
                              duration: FrostedMotion.of(context).fast,
                              child: Icon(
                                FrostedGlyphs.forward,
                                size: 16,
                                color: t.colorScheme.textTertiary,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                if (lead != null)
                  IconTheme.merge(
                    data: IconThemeData(
                      size: FrostedIconSize.i18,
                      color: t.colorScheme.textSecondary,
                    ),
                    child: lead,
                  ),
                Expanded(
                  child: Text(
                    labelOf(item.row.node),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: item.selected
                        ? t.textTheme.link.semibold.c(t.colorScheme.textPrimary)
                        : t.textTheme.link.c(t.colorScheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
        return frostedRingFor(
          states,
          face,
          radius: FrostedChromeMetrics.menuItemRadius,
        );
      },
    );
  }
}
