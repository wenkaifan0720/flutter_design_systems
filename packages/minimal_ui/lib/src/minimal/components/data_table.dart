/// A data table that sorts, selects, filters and pages its rows itself,
/// painted on ui_core's data table.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/column_plan.dart';
import '../internal/edge_fade.dart';
import '../internal/field.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'pressable.dart';
import 'status.dart';

const double _header = 30;
const double _row = 40;
const double _box = 16;
const double _check = 40;

/// The sort arrow after a header's label, and the air before it.
const double _sortGlyph = 12;
const double _sortGap = 2;

/// One column of a [MinimalDataTable]: its [label], the words a row shows
/// in it ([value]), and whether a press on its header sorts it.
///
/// ```dart
/// MinimalDataColumn<({String name, double total})>('Total', value: (o) => '\$${o.total}', sortKey: (o) => o.total, numeric: true)
/// ```
@immutable
class MinimalDataColumn<R> {
  /// A column headed [label].
  const MinimalDataColumn(
    this.label, {
    required this.value,
    this.sortKey,
    this.sortable = false,
    this.numeric = false,
    this.mono = false,
    this.flex = 1,
    this.cell,
  });

  /// Its heading, printed in capitals.
  final String label;

  /// The words a row shows in it.
  final String Function(R row) value;

  /// What a row sorts by; null with [sortable] sorts by [value].
  final Comparable<Object?> Function(R row)? sortKey;

  /// Whether a press on its header sorts it (always, with a [sortKey]).
  final bool sortable;

  /// Figures: right-aligned, in mono. A figure column is as wide as its
  /// widest figure (or its header), never cut short.
  final bool numeric;

  /// Its values in mono (an id, a code). An id column, like a figure
  /// column, is as wide as its widest id (or its header), never cut short.
  final bool mono;

  /// Its share of the width the figure and id columns leave, over what the
  /// shared columns' words ask for; [numeric] and [mono] columns take their
  /// own width instead.
  final int flex;

  /// Paints a row's cell in place of [value]'s words (a status badge). The
  /// column is measured as a status badge of [value], and is never cut
  /// narrower than that.
  final Widget Function(BuildContext context, R row)? cell;
}

/// The back-office table that does its own work: the rows of [rows] under
/// [columns], sorted by a press on a sortable header (ascending, descending,
/// then as given), filtered by [query], [pageSize] at a time with a pager
/// under them, and selected by a press, Space, Shift for a run or Ctrl/Cmd
/// with A for the page, with a select-all box in the header.
///
/// [MinimalTable]'s look: a 30 px header on the quiet fill with capital
/// labels (an arrow after the sorted one), 40 px rows on hairlines, figures
/// right-aligned in mono; a selected row takes the selection fill. The
/// cells keep the gutter at each side; past a check column the figures end
/// as far in as the boxes start (12 px), so the two sides match. Figure
/// and id columns take their content's width, 16 px apart, and the other
/// columns share the rest by need: each its words first, then what is over
/// by [MinimalDataColumn.flex]. Short of room the gaps close to 8 px (the
/// gap after a figure or id column keeps its 16, so an id never reads as
/// one string with what follows) and the shared columns' words are cut,
/// never under 72 px
/// and never into a
/// badge; past that (a phone, large text) the table scrolls sideways as one
/// piece, its words fading at the cut edge while its band and rules run on
/// to the frame's edge. One tab
/// stop for the rows: Up and Down move, Home and End to the ends, Enter
/// opens a row ([onRowActivated]). The behaviour is ui_core's
/// ([DesignDataTable], [DesignTableController]); Minimal paints it. A table
/// the page sorts and pages itself is [MinimalTable].
///
/// ```dart
/// MinimalDataTable<({String name, double total})>(rows: orders, columns: [MinimalDataColumn('Customer', value: (o) => o.name, sortable: true), MinimalDataColumn('Total', value: (o) => '\$${o.total}', sortKey: (o) => o.total, numeric: true)], pageSize: 10, onSelectionChanged: setChosen)
/// ```
class MinimalDataTable<R> extends StatefulWidget {
  /// A table of [rows] in [columns].
  const MinimalDataTable({
    super.key,
    required this.rows,
    required this.columns,
    this.rowKey,
    this.pageSize,
    this.query = '',
    this.filter,
    this.selectable = true,
    this.onSelectionChanged,
    this.onRowActivated,
  });

  /// Every row, unsorted.
  final List<R> rows;

  /// The columns, in order.
  final List<MinimalDataColumn<R>> columns;

  /// Tells rows apart when [rows] is replaced (the row itself unstated).
  final Object Function(R row)? rowKey;

  /// Rows per page; null shows every row and no pager.
  final int? pageSize;

  /// What [filter] keeps rows by; empty keeps every row.
  final String query;

  /// Whether [query] keeps a row; unstated, whether any column's words
  /// contain it, case aside.
  final bool Function(R row, String query)? filter;

  /// Whether rows can be selected.
  final bool selectable;

  /// Called with the selected rows as the selection changes.
  final ValueChanged<List<R>>? onSelectionChanged;

  /// A row's Enter, or its press when the table does not select.
  final ValueChanged<R>? onRowActivated;

  @override
  State<MinimalDataTable<R>> createState() => _MinimalDataTableState<R>();
}

class _MinimalDataTableState<R> extends State<MinimalDataTable<R>> {
  late DesignTableController<R> _table = _make();
  int _selected = 0;

  DesignTableController<R> _make() =>
      DesignTableController<R>(
          rows: widget.rows,
          rowKey: widget.rowKey,
          pageSize: widget.pageSize,
          columns: [
            for (final (i, c) in widget.columns.indexed)
              DesignTableColumn<R>(
                id: '$i',
                label: c.label,
                numeric: c.numeric,
                sortKey:
                    c.sortKey ??
                    (c.sortable ? (R row) => c.value(row).toLowerCase() : null),
              ),
          ],
          filter:
              widget.filter ??
              (row, query) {
                final q = query.toLowerCase();
                return widget.columns.any(
                  (c) => c.value(row).toLowerCase().contains(q),
                );
              },
        )
        ..query = widget.query
        ..addListener(_changed);

  void _changed() {
    final count = _table.selectedCount;
    if (count != _selected) {
      _selected = count;
      widget.onSelectionChanged?.call(_table.selectedRows);
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(MinimalDataTable<R> old) {
    super.didUpdateWidget(old);
    if (old.columns.length != widget.columns.length) {
      _table.dispose();
      _table = _make();
      return;
    }
    if (!identical(old.rows, widget.rows)) _table.rows = widget.rows;
    if (old.pageSize != widget.pageSize) _table.pageSize = widget.pageSize;
    _table.query = widget.query;
  }

  @override
  void dispose() {
    _table.dispose();
    super.dispose();
  }

  /// The columns last measured, and what they were measured for.
  List<MinimalPlanColumn>? _plan;
  Object? _measuredFor;

  /// Each column as the width plan sees it, measured over every row, so no
  /// page cuts one short and the columns keep their places from page to
  /// page. A figure or id column (with no cell of its own) is as wide as
  /// its header or its widest value. A column with a cell wants a status
  /// badge of its widest value, and keeps it whole. Any other column shares
  /// the rest, wanting its widest words and cut to no less than 72 px.
  List<MinimalPlanColumn> _measure(BuildContext context, TextStyle headerType) {
    final t = context.minimalTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // The rows' count with the list: a list grown in place still measures
    // its new rows.
    final key = (
      widget.rows,
      widget.rows.length,
      widget.columns,
      t,
      scaler,
      direction,
    );
    final cached = _plan;
    if (cached != null && _measuredFor == key) return cached;
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width.ceilToDouble();
    }

    double widest(MinimalDataColumn<R> c, double Function(String) of) => [
      measure(c.label.toUpperCase(), headerType) +
          (c.sortKey != null || c.sortable ? _sortGap + _sortGlyph : 0),
      for (final row in widget.rows) of(c.value(row)),
    ].reduce(math.max);
    double badge(String label) =>
        measure(label, MinimalStatusBadge.labelStyleOf(t)) +
        MinimalStatusBadge.padding.horizontal +
        MinimalStatusBadge.dotSize +
        MinimalStatusBadge.dotGap +
        2 * t.hairline;

    // The least a column of words is cut to grows with the words.
    final cut = scaler.scale(MinimalColumnMetrics.minShared);

    MinimalPlanColumn plan(MinimalDataColumn<R> c) {
      if (c.cell != null) {
        final badges = [
          0.0,
          for (final row in widget.rows) badge(c.value(row)),
        ].reduce(math.max);
        final header = widest(c, (_) => 0.0);
        return MinimalPlanColumn.shared(
          flex: c.flex,
          want: math.max(header, badges),
          least: math.max(badges, math.min(header, cut)),
        );
      }
      if (c.numeric || c.mono) {
        return MinimalPlanColumn.fixed(
          widest(c, (v) => measure(v, t.monoValue)),
          figures: true,
        );
      }
      final words = widest(c, (v) => measure(v, t.bodySmall));
      return MinimalPlanColumn.shared(
        flex: c.flex,
        want: words,
        least: math.min(words, cut),
      );
    }

    final columns = [for (final c in widget.columns) plan(c)];
    _plan = columns;
    _measuredFor = key;
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    // The table's header type (MinimalTable): the label at 11 px.
    final headerType = t.label.copyWith(fontSize: 11);
    const inset = MinimalChromeMetrics.gutter;
    final byId = {for (final (i, c) in widget.columns.indexed) '$i': c};
    final plan = _measure(context, headerType);
    final lead = widget.selectable ? _check : inset;
    // The air after the last column: the gutter, or, past a check column,
    // the air before its boxes, so the two sides match.
    final trail = widget.selectable ? (_check - _box) / 2 : inset;
    // The width it scrolls at: the least that cuts nothing that must stay
    // whole.
    final need = lead + trail + minimalLeastExtent(plan);
    // The width it scrolls at: every word whole, since it scrolls anyway.
    final whole = math.max(need, lead + trail + minimalWholeExtent(plan));
    // The last shared column takes what rounding leaves; with none, the
    // last column takes the slack, so the figures still end at the table's
    // end.
    final shared = plan.lastIndexWhere((c) => c.shared);
    final fill = shared >= 0 ? shared : plan.length - 1;
    // On a sideways table's ground (it scrolls) the ground draws the band,
    // a picked row's wash and the rules across the frame; a row keeps the
    // rule's room, unpainted.
    final clear = t.rule.copyWith(color: const Color(0x00000000));

    Widget box(bool? on, Set<WidgetState> states) {
      final shape = t.shapes.mark;
      final filled = on != false;
      return Container(
        width: _box,
        height: _box,
        decoration: minimalFrame(
          shape,
          fill: filled ? t.primary : t.card,
          side: BorderSide(color: filled ? t.primary : t.input, width: t.rim),
        ),
        foregroundDecoration: minimalStateLayer(
          t,
          shape,
          states,
          ground: minimalGround(context),
        ),
        child: on == false
            ? null
            : MinimalIcon(
                on == true ? LucideIcons.check : LucideIcons.minus,
                size: MinimalIconSize.i14,
                color: t.primaryForeground,
              ),
      );
    }

    Widget cells(MinimalColumnPlan layout, List<Widget> cells) => Row(
      children: [
        for (final (i, cell) in cells.indexed) ...[
          if (i > 0) SizedBox(width: layout.gapBefore(i)),
          if (i == fill)
            Expanded(child: cell)
          else
            SizedBox(width: layout.widths[i], child: cell),
        ],
      ],
    );

    Widget tableAt(MinimalColumnPlan layout) => DesignDataTable<R>(
      controller: _table,
      selectable: widget.selectable,
      onActivate: widget.onRowActivated,
      sortedHint: (d) => d == DesignSortDirection.ascending
          ? words.sortedAscending
          : words.sortedDescending,
      headerBuilder: (context, column, sort, states) {
        final c = byId[column.id]!;
        const shape = RoundedRectangleBorder();
        return Container(
          height: _header,
          alignment: c.numeric
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          foregroundDecoration: minimalStateLayer(
            t,
            shape,
            states,
            inside: true,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  c.label.toUpperCase(),
                  style: headerType.c(
                    sort == null ? t.mutedForeground : t.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sort != null) ...[
                const MinimalGap(2),
                MinimalIcon(
                  sort == DesignSortDirection.ascending
                      ? LucideIcons.arrowUp
                      : LucideIcons.arrowDown,
                  size: 12,
                  color: t.foreground,
                ),
              ],
            ],
          ),
        );
      },
      headerRowBuilder: (context, header) {
        final grounded = MinimalTableGround.of(context);
        final band = Container(
          height: _header,
          padding: EdgeInsetsDirectional.only(end: trail),
          decoration: BoxDecoration(
            color: grounded ? null : t.muted,
            border: Border(bottom: grounded ? clear : t.rule),
          ),
          child: Row(
            children: [
              if (widget.selectable)
                SizedBox(
                  width: _check,
                  child: Center(
                    child: MinimalPressable(
                      onPressed: _table.togglePage,
                      checked: _table.pageSelection == DesignSelection.all,
                      semanticLabel: words.selectAllRows,
                      shape: t.shapes.mark,
                      builder: (context, states) =>
                          box(switch (_table.pageSelection) {
                            DesignSelection.none => false,
                            DesignSelection.some => null,
                            DesignSelection.all => true,
                          }, const {}),
                    ),
                  ),
                )
              else
                const MinimalGap(inset),
              Expanded(child: cells(layout, header)),
            ],
          ),
        );
        if (!grounded) return band;
        return MinimalTableGroundRow(
          header: true,
          fill: t.muted,
          bottom: t.rule,
          child: band,
        );
      },
      cellBuilder: (context, row, column) {
        final c = byId[column.id]!;
        final custom = c.cell;
        if (custom != null) return custom(context, row);
        // The words by their capitals, on the row's middle.
        return minimalCapLabel(
          Text(
            c.value(row),
            textAlign: c.numeric ? TextAlign.end : TextAlign.start,
            style: (c.numeric || c.mono ? t.monoValue : t.bodySmall).c(
              t.foreground,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
      rowBuilder: (context, row, cellsOf) {
        const shape = RoundedRectangleBorder();
        final grounded = MinimalTableGround.of(context);
        final line = Container(
          constraints: const BoxConstraints(minHeight: _row),
          padding: EdgeInsetsDirectional.only(end: trail),
          decoration: BoxDecoration(
            color: row.selected && !grounded ? t.selection : null,
            border: Border(bottom: grounded ? clear : t.rule),
          ),
          foregroundDecoration: minimalStateLayer(
            t,
            shape,
            row.states,
            inside: true,
          ),
          child: Row(
            children: [
              if (widget.selectable)
                SizedBox(
                  width: _check,
                  child: Center(
                    // The row's own press toggles it; the box only shows it.
                    child: ExcludeSemantics(child: box(row.selected, const {})),
                  ),
                )
              else
                const MinimalGap(inset),
              Expanded(child: cells(layout, cellsOf)),
            ],
          ),
        );
        if (!grounded) return line;
        return MinimalTableGroundRow(
          fill: row.selected ? t.selection : null,
          bottom: t.rule,
          child: line,
        );
      },
    );

    final size = _table.pageSize;
    final count = _table.filteredRows.length;
    Widget? pager;
    if (size != null && count > size) {
      final first = _table.page * size + 1;
      final last = (first + size - 1).clamp(1, count);
      pager = Padding(
        // The count starts on the table's leading edge: the check boxes'
        // where they lead the rows, else the cells'.
        padding: EdgeInsetsDirectional.only(
          start: widget.selectable ? (_check - _box) / 2 : inset,
          end: trail - MinimalSpacing.s8,
          top: MinimalSpacing.s4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                words.rowsOf(first, last, count),
                style: t.monoValue.c(t.mutedForeground),
              ),
            ),
            MinimalIconButton(
              Directionality.of(context) == TextDirection.rtl
                  ? LucideIcons.chevronRight
                  : LucideIcons.chevronLeft,
              label: words.previousPage,
              size: MinimalButtonSize.small,
              onPressed: _table.page > 0
                  ? () => _table.goToPage(_table.page - 1)
                  : null,
            ),
            const MinimalGap(MinimalSpacing.s8),
            MinimalIconButton(
              Directionality.of(context) == TextDirection.rtl
                  ? LucideIcons.chevronLeft
                  : LucideIcons.chevronRight,
              label: words.nextPage,
              size: MinimalButtonSize.small,
              onPressed: _table.page < _table.pageCount - 1
                  ? () => _table.goToPage(_table.page + 1)
                  : null,
            ),
          ],
        ),
      );
    }

    // The columns share the width there is. Too narrow for every column at
    // its least, the table scrolls sideways as one piece, its header with
    // it, its words fading where it is cut while its band and rules run on
    // to the edge; the pager stays put under it.
    final fitted = LayoutBuilder(
      builder: (context, box) {
        final scrolls = box.hasBoundedWidth && box.maxWidth < need;
        final width = box.hasBoundedWidth && !scrolls ? box.maxWidth : whole;
        final table = tableAt(minimalPlanColumns(plan, width - lead - trail));
        if (!scrolls) {
          return box.hasBoundedWidth
              ? table
              : SizedBox(width: width, child: table);
        }
        return MinimalTableGround(
          child: MinimalEdgeFade(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: whole, child: table),
            ),
          ),
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fitted,
        // The empty line starts on the first column's keyline, its
        // heading's, past the check column where there is one.
        if (count == 0)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: lead,
              end: trail,
              top: MinimalSpacing.s16,
              bottom: MinimalSpacing.s16,
            ),
            child: Text(words.noRows, style: t.bodySmall.c(t.mutedForeground)),
          ),
        ?pager,
      ],
    );
  }
}
