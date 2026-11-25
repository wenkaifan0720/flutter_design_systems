import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
    show RawDataColumn, RawDataTableController;
export 'package:ui_core/ui_core.dart' show RawTreeController;

// ---------------------------------------------------------------------------
// Data table
// ---------------------------------------------------------------------------

/// A table of records to sort, select and page through (Material's
/// DataTable, shadcn's data table): the column names over hairline-ruled
/// rows 52 tall on the glass, a sortable column's name pressed to sort it
/// (its chevron saying which way), a check at each row's start and one over
/// them for the whole page, the chosen rows on the accent's wash, the page
/// numbers under the table once there is more than a page. One Tab stop
/// for the rows. Narrow tables scroll horizontally, and longer cells wrap.
/// The arrows walk the rows, Space selects, Shift extends, and Return
/// opens a row with [onActivate]. ui_core's [RawDataTable] and
/// [RawDataTableController] are the behaviour.
///
/// ```dart
/// FrostedDataTable<({String payee, int cents})>(controller: RawDataTableController(rows: payments, pageSize: 10, columns: [RawDataColumn(id: 'who', label: 'Payee', sortKey: (p) => p.payee), RawDataColumn(id: 'sum', label: 'Amount', numeric: true, sortKey: (p) => p.cents)]), cellBuilder: (context, p, column) => Text(column.id == 'who' ? p.payee : money(p.cents)))
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
  final RawDataTableController<R> controller;

  /// Builds a cell (a [Text] takes the table's type).
  final Widget Function(BuildContext context, R row, RawDataColumn<R> column)
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
    // The header row is at least the touch target tall: its heads sort. The
    // checks' column is at least the target wide, so a check stands in its
    // whole target (the floor, 40).
    final head0 = math.max(_head, FrostedBreakpoints.hitTargetOf(context));
    // A check stands inset in its column where there is room; on a phone it
    // gives up the inset (down to its bare target) before the columns give up
    // theirs.
    const checkInset = FrostedSpacing.s8;
    final target = math.max(_check, FrostedBreakpoints.hitTargetOf(context));
    final body = t.textTheme.titleMedium.fontSize ?? 16;
    final scaledBody = MediaQuery.textScalerOf(context).scale(body);
    // A column's words take about five of their ems. At the reader's own text
    // size the table keeps to its width, as it always has; once larger text
    // leaves its columns less than that, it scrolls sideways rather than
    // breaking its words.
    final words5 = columns.length * (5 * scaledBody + 2 * FrostedSpacing.s12);
    final grown = scaledBody > body + .01;
    Widget viewport(Widget child) => LayoutBuilder(
      builder: (context, box) {
        final full = target + 2 * checkInset;
        if (!selectable) {
          if (!grown || !box.hasBoundedWidth || box.maxWidth >= words5) {
            return child;
          }
        } else if (!box.hasBoundedWidth) {
          return _CheckColumn(width: full, child: child);
        } else {
          final room = box.maxWidth - words5;
          if (!grown || room >= target) {
            return _CheckColumn(width: room.clamp(target, full), child: child);
          }
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (selectable ? full : 0) + words5,
            child: _CheckColumn(width: full, child: child),
          ),
        );
      },
    );
    Widget celled(RawDataColumn<R> column, Widget child) => Expanded(
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
          child: viewport(
            Semantics(
              label: label,
              container: true,
              child: RawDataTable<R>(
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
                          width: _CheckColumn.of(context),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  (_CheckColumn.of(context) - target) / 2,
                            ),
                            child: FrostedCheckbox(
                              value: switch (controller.pageSelection) {
                                RawDataTableSelection.none => false,
                                RawDataTableSelection.some => null,
                                RawDataTableSelection.all => true,
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
                                RawSortDirection.ascending =>
                                  FrostedGlyphs.chevronUp,
                                RawSortDirection.descending =>
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
                  // A longer cell can wrap while retaining the row’s middle.
                  child: RawCapCenter(
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
                    constraints: const BoxConstraints(minHeight: _row),
                    padding: const EdgeInsets.symmetric(
                      vertical: FrostedSpacing.s4,
                    ),
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
                            width: _CheckColumn.of(context),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    (_CheckColumn.of(context) - target) / 2,
                              ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawDataTableController<R>>(
          'controller',
          controller,
        ),
      )
      ..add(
        FlagProperty(
          'selectable',
          value: selectable,
          ifFalse: 'selectable: false',
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<R>>.has('onActivate', onActivate))
      ..add(StringProperty('label', label, defaultValue: null));
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
/// ui_core's [RawTree] is the behaviour.
///
/// ```dart
/// FrostedTreeView<String>(controller: RawTreeController(roots: const ['Bills', 'Trips'], childrenOf: (f) => folders[f] ?? const <String>[]), labelOf: (f) => f, onActivate: open)
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
  final RawTreeController<T> controller;

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
    return RawTree<T>(
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
        // A row is at least the touch target tall (the floor, 40).
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
                                ? RawWidgetsLocalizations.of(context)
                                      .expandedIconTapHint
                                : RawWidgetsLocalizations.of(context)
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawTreeController<T>>('controller', controller))
      ..add(ObjectFlagProperty<String Function(T node)>.has('labelOf', labelOf))
      ..add(
        ObjectFlagProperty<Widget? Function(T node)>.has(
          'leadingOf',
          leadingOf,
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onActivate', onActivate))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// The width of a data table's checks' column, as its room allows.
class _CheckColumn extends InheritedWidget {
  const _CheckColumn({required this.width, required super.child});

  final double width;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CheckColumn>()!.width;

  @override
  bool updateShouldNotify(_CheckColumn oldWidget) => width != oldWidget.width;
}
