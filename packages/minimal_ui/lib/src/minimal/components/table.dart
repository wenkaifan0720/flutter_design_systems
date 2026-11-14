import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/column_plan.dart';
import '../internal/edge_fade.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';
import 'status.dart';
import 'tag.dart';

/// The table's measure: its header band, its rows (a dense 40 — the one
/// row register under the 44 px target, because a table row is read far
/// more than it is tapped), the side inset of its first and last cells
/// (the screen gutter, so the first column lines up with the page's type
/// above it), the header's type and sort glyph, a text cell's vertical
/// padding, and how far a sortable header's tap area reaches above the
/// band. The air between columns is [MinimalColumnMetrics]'.
abstract final class _TableMetrics {
  static const double header = 30;
  static const double row = 40;
  static const double inset = MinimalChromeMetrics.gutter;
  static const double headerType = 11;
  static const double sortGlyph = 12;
  static const double sortGap = 2;
  static const double cellPad = 6;
  static const double headerReach = 7;
}

/// One column of a [MinimalTable]: its header [label], how much of the width
/// it takes, and how its cells print.
///
/// A column is either a fixed [width] or a share of what the fixed ones
/// leave ([flex]). Under a larger text scale a fixed width grows as far as
/// its header, its text cells or its badges need (never past the scale
/// itself). Columns share the width by need: where the table is short of
/// room a fixed column first gives up its air past its content, then the
/// gaps close from 16 to 8 px (never between two [numeric] or [mono]
/// columns, whose figures would read as one), then the shared columns'
/// words are cut, never under 72 px and never into a badge. A column with
/// a widget cell keeps its width, and its widgets shorten.
///
/// [numeric] is the figure register — mono, tabular and right-aligned, so a
/// column of quantities or times lines up on its last digit. [mono] prints
/// an identifier column (`1047`, `HAB-4`) in the quiet mono without
/// right-aligning it. [sortable] makes the header a control that reports to
/// [MinimalTable.onSort]; the table never reorders rows itself.
///
/// ```dart
/// MinimalColumn('Qty', width: 44, numeric: true, sortable: true)
/// ```
@immutable
class MinimalColumn {
  /// A column headed [label].
  const MinimalColumn(
    this.label, {
    this.width,
    this.flex = 1,
    this.numeric = false,
    this.mono = false,
    this.sortable = false,
    this.alignEnd,
  }) : assert(width == null || width > 0, 'a fixed column has a width');

  /// The header text; the table upper-cases it.
  final String label;

  /// A fixed width in logical pixels; null shares the free width by [flex].
  final double? width;

  /// Its share of the width over what the shared columns' words ask for,
  /// when it has no fixed width.
  final int flex;

  /// Figures: mono, tabular, right-aligned.
  final bool numeric;

  /// Identifiers: mono in the quiet ink, aligned at the start.
  final bool mono;

  /// Whether its header sorts the table.
  final bool sortable;

  /// Right-align the column's header and cells; null aligns [numeric]
  /// columns at the end and everything else at the start.
  final bool? alignEnd;

  bool get _end => alignEnd ?? numeric;
}

/// One cell of a [MinimalTableRow]: plain text in the column's register, a
/// status badge, or any widget.
///
/// Text inherits its column's register — mono for [MinimalColumn.numeric]
/// and [MinimalColumn.mono] columns, 13 px Geist otherwise. [strong] is the
/// row's name (a customer, a habit) at medium weight; [tone] tints the
/// text for a value that needs the eye (a late time).
///
/// ```dart
/// MinimalCell.badge('Ready', tone: MinimalTone.success)
/// ```
@immutable
class MinimalCell {
  /// A text cell.
  const MinimalCell(String this.text, {this.strong = false, this.tone})
    : child = null,
      badge = false;

  /// A [MinimalStatusBadge]: the table's status register (`● Ready`).
  const MinimalCell.badge(String this.text, {this.tone = MinimalTone.neutral})
    : child = null,
      strong = false,
      badge = true;

  /// Any widget, aligned like the column's text.
  const MinimalCell.widget(Widget this.child)
    : text = null,
      strong = false,
      tone = null,
      badge = false;

  /// What the cell prints.
  final String? text;

  /// A widget in place of text.
  final Widget? child;

  /// Whether it prints in the strong ink: a row's name.
  final bool strong;

  /// Its tone: a status's.
  final MinimalTone? tone;

  /// Whether it prints as a status badge.
  final bool badge;
}

/// One row of a [MinimalTable]: its cells, one per column, and its state.
///
/// [faded] is the settled row that stays for reference (picked up, closed)
/// at half strength; [selected] is the row the page is acting on, on the
/// selection fill. [onPressed] overrides
/// the table's [MinimalTable.onRowPressed] for this row.
///
/// ```dart
/// MinimalTableRow([MinimalCell('1039'), MinimalCell('Jonas Weber')], faded: true)
/// ```
@immutable
class MinimalTableRow {
  /// A row of [cells].
  const MinimalTableRow(
    this.cells, {
    this.faded = false,
    this.selected = false,
    this.onPressed,
    this.semanticLabel,
  });

  /// Its cells, one per column.
  final List<MinimalCell> cells;

  /// Whether it prints faint: archived, past.
  final bool faded;

  /// Whether it is selected.
  final bool selected;

  /// Opens the row; null leaves it still.
  final VoidCallback? onPressed;

  /// What a screen reader announces for the row; null reads its cells.
  final String? semanticLabel;
}

/// Minimal's dense data table — the back-office list where every row is
/// a record and every column a field: a 30 px header on the quiet fill
/// with uppercase labels, 40 px rows divided by hairlines (the dense-list
/// exception to the 44 px target, with the table palette's 36 and the
/// menu's 32), figures in
/// right-aligned mono, dot badges for status, and no card around it. It
/// runs edge to edge, so stand it in a `padding: EdgeInsets.zero` screen.
///
/// Sorting is the page's: tap a [MinimalColumn.sortable] header and
/// [onSort] reports the column and direction; the page reorders [rows] and
/// passes [sortColumn] and [sortAscending] back for the indicator — `↑` or
/// `↓` after that column's label, the only glyph a header prints. Its
/// columns stand 16 px apart where there is room and share the width by
/// need ([MinimalColumn]). When they cannot fit without cutting what must
/// stay whole, the table scrolls sideways as one piece, every word whole
/// (each column at its want), its words fading at
/// the cut edge while its band and rules run on to the frame's edge, rather
/// than spill out of what holds it.
///
/// The header stays put while the rows scroll under it in two cases. Given
/// a bounded height (an `Expanded`, a `SizedBox`), the table scrolls its
/// own rows. In a scrolling page, use [MinimalTable.sliver] inside a
/// `CustomScrollView` (a `scroll: false` screen): the header pins to the
/// top of the page while the table's rows pass under it, and leaves with
/// the table's last row; a sortable pinned header stands on a 7 px band of
/// the page's ground, its tap area's reach. A plain [MinimalTable] in a
/// scrolling page is as
/// tall as its rows, and its header scrolls away with them.
///
/// ```dart
/// MinimalTable(columns: const [MinimalColumn('#', width: 40, mono: true), MinimalColumn('Customer'), MinimalColumn('Qty', width: 38, numeric: true)], rows: [for (final o in orders) MinimalTableRow([MinimalCell(o.id), MinimalCell(o.name, strong: true), MinimalCell('${o.qty}')])], onRowPressed: open)
/// ```
class MinimalTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const MinimalTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowPressed,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.emptyLabel,
    this.minWidth,
  }) : _sliver = false;

  /// The table as a sliver, for a `CustomScrollView`: its header pins while
  /// its rows scroll under it. A table too wide for the view scrolls
  /// sideways as one piece instead, its header with it.
  const MinimalTable.sliver({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowPressed,
    this.sortColumn,
    this.sortAscending = true,
    this.onSort,
    this.emptyLabel,
    this.minWidth,
  }) : _sliver = true;

  /// The columns, start to end.
  final List<MinimalColumn> columns;

  /// The rows, top to bottom.
  final List<MinimalTableRow> rows;

  /// A tapped row's index in [rows]; null leaves rows inert.
  final ValueChanged<int>? onRowPressed;

  /// The column the rows are sorted by, for the header's indicator.
  final int? sortColumn;

  /// Whether the sorted column runs up.
  final bool sortAscending;

  /// A sortable header was tapped: the column, and the direction the page
  /// should sort it in (the other way when it already sorts by it).
  final void Function(int column, bool ascending)? onSort;

  /// The quiet line a table with no rows prints under its header.
  final String? emptyLabel;

  /// The narrowest the table lays out before it scrolls sideways. It is
  /// never less than the columns need uncut: each fixed column's content
  /// (all of a widget column's width), each shared column's words up to
  /// 72 px and its badges whole, 8 px between columns.
  final double? minWidth;

  final bool _sliver;

  /// Each column as the width plan sees it, from what its content needs:
  /// its header (with room for the sort arrow), its text cells and its
  /// badges, measured at the text scale.
  ///
  /// A fixed column takes its declared width, grown under a larger text
  /// scale as far as its content needs and never past the scale itself (a
  /// faded `Picked up` keeps its one word); short of room it gives way down
  /// to its content. A widget cell is not measured, so a column with one
  /// keeps its width. A shared column wants its widest words, and is cut to
  /// no less than 72 px of them and never into a badge.
  List<MinimalPlanColumn> _plan(BuildContext context) {
    final t = context.minimalTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
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

    MinimalPlanColumn plan(int i, MinimalColumn column) {
      var words =
          measure(column.label.toUpperCase(), _headerType(t)) +
          (column.sortable
              ? _TableMetrics.sortGap + _TableMetrics.sortGlyph
              : 0);
      var badges = 0.0;
      var widgets = false;
      for (final row in rows) {
        final cell = row.cells[i];
        switch (cell) {
          case MinimalCell(child: _?):
            widgets = true;
          case MinimalCell(:final text?, badge: true):
            badges = math.max(
              badges,
              measure(text, MinimalStatusBadge.labelStyleOf(t)) +
                  MinimalStatusBadge.padding.horizontal +
                  MinimalStatusBadge.dotSize +
                  MinimalStatusBadge.dotGap +
                  2 * t.hairline,
            );
          case MinimalCell(:final text?):
            words = math.max(words, measure(text, _cellStyle(t, column, cell)));
        }
      }
      final content = math.max(words, badges);
      final figures = column.numeric || column.mono;
      if (column.width case final width?) {
        final grown = scaler.scale(width) <= width
            ? width
            : math.min(scaler.scale(width), math.max(width, content));
        return MinimalPlanColumn.fixed(
          grown,
          least: widgets ? null : math.min(grown, content),
          figures: figures,
        );
      }
      // The floor is a run of words, so it grows with them.
      final cut = scaler.scale(MinimalColumnMetrics.minShared);
      return MinimalPlanColumn.shared(
        flex: column.flex,
        want: widgets ? math.max(content, cut) : content,
        least: math.max(badges, widgets ? cut : math.min(words, cut)),
        figures: figures,
      );
    }

    return [for (final (i, column) in columns.indexed) plan(i, column)];
  }

  @override
  Widget build(BuildContext context) {
    assert(
      rows.every((row) => row.cells.length == columns.length),
      'every MinimalTableRow has one cell per MinimalColumn',
    );
    final plan = _plan(context);
    const insets = 2 * _TableMetrics.inset;
    // The width it scrolls at: the least that cuts nothing that must stay
    // whole, or [minWidth].
    final need = math.max(minWidth ?? 0, minimalLeastExtent(plan) + insets);
    // The width it scrolls at: every word whole, since it scrolls anyway.
    final whole = math.max(need, minimalWholeExtent(plan) + insets);
    // The last shared column takes what rounding leaves.
    final fill = columns.lastIndexWhere((c) => c.width == null);

    Widget headerAt(_Layout layout) => _HeaderRow(
      columns: columns,
      layout: layout,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
      onSort: onSort,
    );
    List<Widget> bodyAt(_Layout layout) => [
      if (rows.isEmpty)
        _EmptyRow(label: emptyLabel ?? MinimalLocalizations.of(context).noRows)
      else
        for (final (i, row) in rows.indexed)
          _BodyRow(
            columns: columns,
            layout: layout,
            row: row,
            last: i == rows.length - 1,
            onPressed:
                row.onPressed ??
                (onRowPressed == null ? null : () => onRowPressed!(i)),
          ),
    ];
    _Layout layoutAt(double width) => (
      plan: minimalPlanColumns(plan, width - insets),
      fill: fill < 0 ? null : fill,
    );

    final sorts = onSort != null && columns.any((c) => c.sortable);
    if (_sliver) {
      // A sliver's constraints change with every scrolled frame; the rows
      // are laid out again only when the width does.
      double? laidFor;
      late Widget header;
      late List<Widget> body;
      return SliverLayoutBuilder(
        builder: (context, constraints) {
          final scrolls = constraints.crossAxisExtent < need;
          final width = scrolls ? whole : constraints.crossAxisExtent;
          if (laidFor != width) {
            final layout = layoutAt(width);
            header = headerAt(layout);
            body = bodyAt(layout);
            laidFor = width;
          }
          if (scrolls) {
            return SliverToBoxAdapter(
              child: MinimalTableGround(
                child: MinimalEdgeFade(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: whole,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [header, ...body],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          final t = context.minimalTheme;
          return SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeader(
                  // A pinned header takes no point outside its extent, so a
                  // sortable one carries its reach as a band of the page's
                  // ground above the header row.
                  extent:
                      _TableMetrics.header +
                      2 * t.hairline +
                      (sorts ? _TableMetrics.headerReach : 0),
                  child: sorts
                      ? ColoredBox(
                          color: t.background,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: _TableMetrics.headerReach,
                            ),
                            child: _HeaderReach(child: header),
                          ),
                        )
                      : header,
                ),
              ),
              SliverList.list(children: body),
            ],
          );
        },
      );
    }

    final boxed = LayoutBuilder(
      builder: (context, constraints) {
        // Unbounded (a sideways scroll view of the page's own), it takes
        // the width it would scroll at.
        final scrolls =
            constraints.hasBoundedWidth && constraints.maxWidth < need;
        final width = constraints.hasBoundedWidth && !scrolls
            ? constraints.maxWidth
            : whole;
        final bounded = constraints.hasBoundedHeight;
        final layout = layoutAt(width);
        final header = headerAt(layout);
        final body = bodyAt(layout);

        Widget table = bounded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(
                    child: ListView(padding: EdgeInsets.zero, children: body),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, ...body],
              );
        table = SizedBox(width: width, child: table);
        if (!scrolls) return table;
        // A table cut by the screen fades its words at the cut, so it reads
        // as scrollable rather than clipped; its band and rules stand on the
        // ground under the fade and run to the frame's edge.
        return MinimalTableGround(
          child: MinimalEdgeFade(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: bounded
                  ? SizedBox(height: constraints.maxHeight, child: table)
                  : table,
            ),
          ),
        );
      },
    );
    return sorts ? _HeaderReach(child: boxed) : boxed;
  }
}

/// The header's register: [MinimalThemeData.label] a step down.
TextStyle _headerType(MinimalThemeData t) =>
    t.label.copyWith(fontSize: _TableMetrics.headerType);

/// A text cell's register in [column]: mono for figures and identifiers,
/// 13 px Geist otherwise. Mono cells (ids, quantities, times) keep the
/// quiet ink so the row's name leads; a strong or toned cell asks for the
/// eye.
TextStyle _cellStyle(
  MinimalThemeData t,
  MinimalColumn column,
  MinimalCell cell,
) {
  final mono = column.numeric || column.mono;
  final tone = cell.tone;
  final style = (mono ? t.mono : t.bodySmall).c(
    tone != null
        ? t.tone(tone).foreground
        : mono && !cell.strong
        ? t.mutedForeground
        : t.foreground,
  );
  return cell.strong ? style.medium : style;
}

/// The table's columns laid out for one width: the plan's widths and gaps,
/// and the column (the last shared one) that takes what rounding leaves.
typedef _Layout = ({MinimalColumnPlan plan, int? fill});

/// Lays [cells] out on the table's grid: each column at its planned width,
/// the planned gaps between, the inset at both ends. Cells are centred on
/// the row and each cell's words carry their capitals on its middle, so a
/// 12 px mono id and a 13 px name read as one line (their baselines a third
/// of a pixel apart), level with a badge or a control in the next cell.
Widget _grid(_Layout layout, List<Widget> cells) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: _TableMetrics.inset),
  child: Row(
    children: [
      for (final (i, cell) in cells.indexed) ...[
        if (i > 0) SizedBox(width: layout.plan.gapBefore(i)),
        if (i == layout.fill)
          Expanded(child: cell)
        else
          SizedBox(width: layout.plan.widths[i], child: cell),
      ],
    ],
  ),
);

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.columns,
    required this.layout,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  final List<MinimalColumn> columns;
  final _Layout layout;
  final int? sortColumn;
  final bool sortAscending;
  final void Function(int column, bool ascending)? onSort;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final type = _headerType(t);
    final onSort = this.onSort;
    // On a sideways table's ground the ground draws the band and its rules
    // across the frame; the row keeps the rules' room.
    final grounded = MinimalTableGround.of(context);
    final rule = grounded ? t.rule.copyWith(color: _clear) : t.rule;
    final band = Container(
      constraints: const BoxConstraints(minHeight: _TableMetrics.header),
      decoration: BoxDecoration(
        color: grounded ? null : t.muted,
        border: Border(top: rule, bottom: rule),
      ),
      child: _grid(layout, [
        for (final (i, column) in columns.indexed)
          _HeaderCell(
            column: column,
            type: type,
            active: sortColumn == i,
            ascending: sortAscending,
            onPressed: column.sortable && onSort != null
                ? () => onSort(i, sortColumn == i ? !sortAscending : true)
                : null,
          ),
      ]),
    );
    if (!grounded) return band;
    return MinimalTableGroundRow(
      header: true,
      fill: t.muted,
      top: t.rule,
      bottom: t.rule,
      child: band,
    );
  }
}

/// A rule kept for its room on a table's ground, which draws it.
const Color _clear = Color(0x00000000);

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.type,
    required this.active,
    required this.ascending,
    required this.onPressed,
  });

  final MinimalColumn column;
  final TextStyle type;
  final bool active;
  final bool ascending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final ink = active ? t.foreground : t.mutedForeground;
    final text = Flexible(
      child: minimalCapLabel(
        Text(
          column.label.toUpperCase(),
          style: type.c(ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: column._end ? TextAlign.end : TextAlign.start,
        ),
      ),
    );
    // Only the column the rows are sorted by shows a direction, always
    // after its label; an idle sortable header prints its label alone (a
    // touch screen has no hover to reveal a glyph with).
    final glyph = column.sortable && active
        ? MinimalIcon(
            ascending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: _TableMetrics.sortGlyph,
            color: t.mutedForeground,
          )
        : null;
    const gap = MinimalGap(_TableMetrics.sortGap);
    final content = Row(
      mainAxisAlignment: column._end
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        text,
        if (glyph != null) ...[gap, glyph],
      ],
    );
    final cell = SizedBox(height: _TableMetrics.header, child: content);
    if (onPressed == null) return Semantics(header: true, child: cell);
    return _ReachTarget(
      child: MinimalPressable(
        onPressed: onPressed,
        shape: t.shapes.mark,
        selected: active,
        semanticLabel: active
            ? '${column.label}, sorted ${ascending ? 'ascending' : 'descending'}'
            : '${column.label}, sort',
        child: ExcludeSemantics(child: cell),
      ),
    );
  }
}

/// Lets a sortable header cell take taps a little above the table (the
/// 30 px band alone is under the 44 px minimum), so whatever sits above a
/// sortable table gives up that sliver. Below the band the first row keeps
/// its own taps. Only a point over a sortable header ([_ReachTarget]) is
/// taken: above a label header the tap passes on.
class _HeaderReach extends SingleChildRenderObjectWidget {
  const _HeaderReach({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeaderReach();
}

class _RenderHeaderReach extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    if (position.dx < 0 ||
        position.dx > size.width ||
        position.dy < -_TableMetrics.headerReach ||
        position.dy >= 0) {
      return false;
    }
    // The same column, halfway down the header band.
    final inside = Offset(position.dx, _TableMetrics.header / 2);
    final probe = BoxHitTestResult();
    if (!super.hitTest(probe, position: inside) ||
        !probe.path.any((entry) => entry.target is _RenderReachTarget)) {
      return false;
    }
    return super.hitTest(result, position: inside);
  }
}

/// Marks a sortable header cell as a target [_HeaderReach] may extend.
class _ReachTarget extends SingleChildRenderObjectWidget {
  const _ReachTarget({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderReachTarget();
}

class _RenderReachTarget extends RenderProxyBox {}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  _PinnedHeader({required this.extent, required this.child});

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: extent, child: child);

  @override
  bool shouldRebuild(_PinnedHeader oldDelegate) =>
      oldDelegate.extent != extent || oldDelegate.child != child;
}

class _BodyRow extends StatelessWidget {
  const _BodyRow({
    required this.columns,
    required this.layout,
    required this.row,
    required this.last,
    this.onPressed,
  });

  final List<MinimalColumn> columns;
  final _Layout layout;
  final MinimalTableRow row;

  /// The table's last row, drawn without the rule under it.
  final bool last;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // On a sideways table's ground the ground draws the wash and the rule
    // across the frame.
    final grounded = MinimalTableGround.of(context);
    Widget content = Container(
      constraints: const BoxConstraints(minHeight: _TableMetrics.row),
      alignment: AlignmentDirectional.centerStart,
      // The selected row is said by the selection's wash alone: the one
      // wash the look allows, and no bar of the accent beside it.
      decoration: row.selected && !grounded
          ? BoxDecoration(color: t.selection)
          : null,
      // The rule is painted over the row's foot, so the cells are centred
      // on the whole row, the rule's pixel with it. The last row has none:
      // the table's end, or its card's edge, divides it from what follows.
      foregroundDecoration: last || grounded
          ? null
          : BoxDecoration(border: Border(bottom: t.rule)),
      child: _grid(layout, [
        for (final (i, column) in columns.indexed)
          _Cell(column: column, cell: row.cells[i]),
      ]),
    );
    if (row.faded) content = Opacity(opacity: 0.5, child: content);
    // A row with its own announcement says that instead of its cells.
    if (row.semanticLabel != null) content = ExcludeSemantics(child: content);
    final Widget pressed = onPressed == null
        ? Semantics(
            container: true,
            selected: row.selected,
            label: row.semanticLabel,
            child: content,
          )
        : MinimalPressable(
            onPressed: onPressed,
            radius: 0,
            selected: row.selected ? true : null,
            semanticLabel: row.semanticLabel,
            child: content,
          );
    if (!grounded) return pressed;
    return MinimalTableGroundRow(
      fill: row.selected ? t.selection : null,
      bottom: last ? BorderSide.none : t.rule,
      opacity: row.faded ? 0.5 : 1,
      child: pressed,
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.column, required this.cell});

  final MinimalColumn column;
  final MinimalCell cell;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final align = column._end
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final child = cell.child;
    final text = cell.text;
    if (child != null) return Align(alignment: align, child: child);
    if (cell.badge) {
      return Align(
        alignment: align,
        child: MinimalStatusBadge(
          text ?? '',
          tone: cell.tone ?? MinimalTone.neutral,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _TableMetrics.cellPad),
      child: minimalCapLabel(
        Text(
          text ?? '',
          style: _cellStyle(t, column, cell),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: column._end ? TextAlign.end : TextAlign.start,
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Container(
      constraints: const BoxConstraints(minHeight: _TableMetrics.row),
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: _TableMetrics.inset),
      child: Text(label, style: t.bodySmall.c(t.mutedForeground)),
    );
  }
}
