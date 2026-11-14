import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../list/check_indicator.dart';
import '../pressable/pressable.dart';

/// Which way a [Fluent2Table]'s sorted column runs.
enum Fluent2SortDirection {
  /// Smallest first.
  ascending,

  /// Largest first.
  descending,
}

/// A table's density, Fluent's `size`: [extraSmall] rows 24 tall in
/// caption1 with no hairlines, [small] 34, [medium] 44 (the default). On a
/// phone every row keeps 44.
enum Fluent2TableSize {
  /// The extra-small size.
  extraSmall,

  /// The small size.
  small,

  /// The medium size.
  medium,
}

/// How a selected row is lit, Fluent's row `appearance`: [neutral] the
/// subtle selected fill, [brand] the brand's tint.
enum Fluent2TableSelectionAppearance {
  /// A chosen row in the neutral selection fill.
  neutral,

  /// A chosen row in the brand selection fill.
  brand,
}

/// One column of a [Fluent2Table]: its header [label], a fixed [width] or a
/// [flex] share of the room no narrower than [minWidth], [numeric] figures
/// set at the end in tabular digits, and whether its header sorts
/// ([sortable]).
///
/// ```dart
/// Fluent2TableColumn('Modified', minWidth: 120, sortable: true)
/// ```
@immutable
class Fluent2TableColumn {
  /// A column headed [label].
  const Fluent2TableColumn(
    this.label, {
    this.width,
    this.flex = 1,
    this.minWidth = 96,
    this.numeric = false,
    this.sortable = false,
  });

  /// The header's words.
  final String label;

  /// A fixed width; null takes a [flex] share.
  final double? width;

  /// The column's share of the room left when it has no fixed width.
  final int flex;

  /// The narrowest the column stands.
  final double minWidth;

  /// Whether it holds figures, set at the end in tabular digits.
  final bool numeric;

  /// Whether its header sorts the table.
  final bool sortable;
}

/// One cell of a [Fluent2TableRow], Fluent's `TableCellLayout`: its [media]
/// (a glyph or an avatar, 20, or 24 when [primary]) 8 before its [text]
/// (semibold when [primary]) over a [description] in caption1 and the
/// second ink.
///
/// ```dart
/// Fluent2TableCell('Q3 plan.docx', media: Icon(Fluent2Icons.document), primary: true)
/// ```
@immutable
class Fluent2TableCell {
  /// A cell showing [text].
  const Fluent2TableCell(
    this.text, {
    this.description,
    this.media,
    this.primary = false,
  });

  /// The cell's words.
  final String text;

  /// A quieter line under [text]; null shows none.
  final String? description;

  /// What leads the cell (an icon, an avatar); null shows nothing.
  final Widget? media;

  /// Whether this is the row's main cell, its words in the stronger weight.
  final bool primary;
}

/// One row of a [Fluent2Table]: its [cells] in the columns' order and what
/// a press on it does ([onTap]).
///
/// ```dart
/// Fluent2TableRow(cells: [Fluent2TableCell('Q3 plan.docx'), Fluent2TableCell('Kai Tanaka'), Fluent2TableCell('2h ago')], onPressed: open)
/// ```
@immutable
class Fluent2TableRow {
  /// A row of [cells].
  const Fluent2TableRow({required this.cells, this.onPressed, this.label});

  /// The row's cells, one per column.
  final List<Fluent2TableCell> cells;

  /// Called when the row is pressed; null makes it still.
  final VoidCallback? onPressed;

  /// What a screen reader says for the row; null says its cells.
  final String? label;
}

/// Fluent 2's Table (and DataGrid's look): a header row in body1 over
/// [rows] 44 tall with a hairline under each, cells 8 in at their sides,
/// each a [Fluent2TableCell] layout. A [Fluent2TableColumn.sortable] header
/// is a press that asks [onSort] for its column, the sorted one wearing its
/// 12 arrow. With [selected] set the rows are selectable: Fluent's checkbox
/// in a 44 column at the start (the header's selects them all), a selected
/// row lit by [selectionAppearance], a change told through
/// [onSelectionChanged]. Rows step through the subtle fill's hover and
/// pressed steps. When the columns need more room than there is (a phone)
/// the table scrolls sideways. Read as rows of cells, sorting and selection
/// said.
///
/// ```dart
/// Fluent2Table(columns: const [Fluent2TableColumn('Name', flex: 2), Fluent2TableColumn('Modified')], rows: [Fluent2TableRow(cells: [Fluent2TableCell('Q3 plan.docx'), Fluent2TableCell('2h ago')])])
/// ```
class Fluent2Table extends StatelessWidget {
  /// A table of [rows] under [columns].
  const Fluent2Table({
    required this.columns,
    required this.rows,
    this.sortColumn,
    this.sortDirection = Fluent2SortDirection.ascending,
    this.onSort,
    this.selected,
    this.onSelectionChanged,
    this.size = Fluent2TableSize.medium,
    this.selectionAppearance = Fluent2TableSelectionAppearance.neutral,
    this.label,
    super.key,
  });

  /// The columns, in order.
  final List<Fluent2TableColumn> columns;

  /// The rows, in order.
  final List<Fluent2TableRow> rows;

  /// The sorted column's index.
  final int? sortColumn;

  /// Which way the sorted column runs.
  final Fluent2SortDirection sortDirection;

  /// Asked to sort by the column pressed.
  final ValueChanged<int>? onSort;

  /// The selected rows' indexes; set to make the rows selectable.
  final Set<int>? selected;

  /// Told the rows selected after a change; null draws the selection
  /// disabled.
  final ValueChanged<Set<int>>? onSelectionChanged;

  /// Fluent's `size`: the rows' height.
  final Fluent2TableSize size;

  /// The fill a selected row wears.
  final Fluent2TableSelectionAppearance selectionAppearance;

  /// What a screen reader calls the table.
  final String? label;

  /// The selection column's width (Fluent's `CELL_WIDTH`).
  static const double selectionWidth = 44;

  /// The selection column's width at [context]: [selectionWidth], a whole
  /// target (48) under a finger.
  static double selectionWidthOf(BuildContext context) =>
      Fluent2Layout.padded(context)
      ? Fluent2Layout.touchHitTarget
      : selectionWidth;

  /// The heading row's height at [context]: 32 on the desktop, a target
  /// (44, 48 under a finger) elsewhere.
  static double headerHeightOf(BuildContext context) =>
      Fluent2Layout.isWide(context) && !Fluent2Layout.padded(context)
      ? 32
      : Fluent2Layout.hitTargetOf(context);

  double _rowHeight(BuildContext context) {
    final h = switch (size) {
      Fluent2TableSize.extraSmall => 24.0,
      Fluent2TableSize.small => 34.0,
      Fluent2TableSize.medium => 44.0,
    };
    return Fluent2Layout.isWide(context) && !Fluent2Layout.padded(context)
        ? h
        : math.max(h, Fluent2Layout.hitTargetOf(context));
  }

  @override
  Widget build(BuildContext context) {
    final selectable = selected != null;
    final lead = selectable ? selectionWidthOf(context) : 0.0;
    // A column's fixed and least widths grow with the reader's text, so at a
    // large text size the cells keep their words and the table scrolls,
    // rather than every cell shortening to a stub.
    final grow = math.max(1.0, MediaQuery.textScalerOf(context).scale(14) / 14);
    return LayoutBuilder(
      builder: (context, box) {
        final least =
            lead +
            columns.fold<double>(
              0,
              (s, c) => s + (c.width ?? c.minWidth) * grow,
            );
        final room = box.maxWidth.isFinite ? box.maxWidth : least;
        final total = math.max(room, least);
        final widths = _widths(total - lead, grow);
        final table = SizedBox(
          width: total,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, widths),
              for (final (i, row) in rows.indexed)
                _TableRowView(
                  table: this,
                  index: i,
                  row: row,
                  widths: widths,
                  height: _rowHeight(context),
                ),
            ],
          ),
        );
        final framed = Semantics(
          container: true,
          explicitChildNodes: true,
          label: label,
          child: table,
        );
        if (total <= room + 0.5) return framed;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: framed,
        );
      },
    );
  }

  /// Each column's width in [room]: a fixed width as given, the flexible
  /// ones sharing what is left by their flex, a column whose share falls
  /// under its least width held at it and the rest shared again, so the
  /// widths never add up past the room they were given more than the
  /// least widths force; fixed and least widths taken [grow] times.
  List<double> _widths(double room, double grow) {
    final widths = [for (final c in columns) (c.width ?? 0.0) * grow];
    final open = {
      for (final (i, c) in columns.indexed)
        if (c.width == null) i,
    };
    var left = math.max(
      0.0,
      room - columns.fold<double>(0, (s, c) => s + (c.width ?? 0) * grow),
    );
    while (open.isNotEmpty) {
      final flexes = open.fold<int>(0, (s, i) => s + columns[i].flex);
      final short = {
        for (final i in open)
          if (flexes == 0 ||
              left * columns[i].flex / flexes < columns[i].minWidth * grow)
            i,
      };
      if (short.isEmpty) {
        for (final i in open) {
          widths[i] = left * columns[i].flex / flexes;
        }
        break;
      }
      for (final i in short) {
        widths[i] = columns[i].minWidth * grow;
        left = math.max(0.0, left - columns[i].minWidth * grow);
      }
      open.removeAll(short);
    }
    return widths;
  }

  Widget _header(BuildContext context, List<double> widths) {
    final t = context.fluent2Theme;
    final all = selected;
    final change = onSelectionChanged;
    final Widget? check = all == null
        ? null
        : SizedBox(
            width: selectionWidthOf(context),
            child: _SelectCell(
              checked: all.isEmpty
                  ? false
                  : all.length >= rows.length
                  ? true
                  : null,
              label: Fluent2Localizations.of(context).selectAllRows,
              onTap: change == null || rows.isEmpty
                  ? null
                  : () => change(
                      all.length >= rows.length
                          ? <int>{}
                          : {for (var i = 0; i < rows.length; i++) i},
                    ),
            ),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: size == Fluent2TableSize.extraSmall
            ? null
            : Border(
                bottom: BorderSide(
                  color: fluent2Step(t, t.colors.neutralStroke2),
                ),
              ),
      ),
      child: SizedBox(
        height: headerHeightOf(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?check,
            for (final (i, column) in columns.indexed)
              SizedBox(
                width: widths[i],
                child: _HeaderCell(
                  column: column,
                  sorted: sortColumn == i ? sortDirection : null,
                  onTap: column.sortable && onSort != null
                      ? () => onSort!(i)
                      : null,
                  small: size == Fluent2TableSize.extraSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.sorted,
    required this.onTap,
    required this.small,
  });

  final Fluent2TableColumn column;
  final Fluent2SortDirection? sorted;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final type = small ? t.caption1 : t.body1;
    Widget face(Color ink, Color fill) {
      final words = Flexible(
        child: fluent2CapCentred(
          Text(
            column.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.c(ink),
          ),
        ),
      );
      final arrow = sorted == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: Fluent2Spacing.xxs),
              child: Icon(
                sorted == Fluent2SortDirection.ascending
                    ? Fluent2Icons.arrowUp
                    : Fluent2Icons.arrowDown,
                size: Fluent2IconSize.i12,
                color: ink,
              ),
            );
      return Container(
        color: fill,
        padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.s),
        alignment: column.numeric
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Fluent2Spacing.xs,
          children: [words, ?arrow],
        ),
      );
    }

    if (!column.sortable) {
      return Semantics(
        container: true,
        header: true,
        label: column.label,
        excludeSemantics: true,
        child: face(t.textPrimary, t.colors.transparentBackground),
      );
    }
    return Fluent2Pressable(
      onPressed: onTap,
      label: Fluent2Localizations.of(context).sortBy(column.label),
      value: sorted == null
          ? null
          : sorted == Fluent2SortDirection.ascending
          ? 'ascending'
          : 'descending',
      radius: Fluent2Radius.medium,
      builder: (context, states) => face(
        states.press.pick(
          t.colors.neutralForeground1,
          t.colors.neutralForeground1Hover,
          t.colors.neutralForeground1Pressed,
          t.textDisabled,
        ),
        states.press.pick(
          t.colors.subtleBackground,
          t.colors.subtleBackgroundHover,
          t.colors.subtleBackgroundPressed,
        ),
      ),
    );
  }
}

class _SelectCell extends StatelessWidget {
  const _SelectCell({
    required this.checked,
    required this.label,
    required this.onTap,
  });

  final bool? checked;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    checked: checked ?? false,
    mixed: checked == null ? true : null,
    child: Fluent2Pressable(
      onPressed: onTap,
      label: label,
      radius: Fluent2Radius.medium,
      builder: (context, states) => Center(
        child: Fluent2CheckIndicator(checked: checked, press: states.press),
      ),
    ),
  );
}

class _TableRowView extends StatelessWidget {
  const _TableRowView({
    required this.table,
    required this.index,
    required this.row,
    required this.widths,
    required this.height,
  });

  final Fluent2Table table;
  final int index;
  final Fluent2TableRow row;
  final List<double> widths;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final picked = table.selected;
    final on = picked?.contains(index) ?? false;
    final change = table.onSelectionChanged;
    final VoidCallback? toggle = picked == null || change == null
        ? null
        : () => change(on ? ({...picked}..remove(index)) : {...picked, index});
    final press = row.onPressed ?? toggle;
    final small = table.size == Fluent2TableSize.extraSmall;
    final spoken =
        row.label ??
        [
          for (final cell in row.cells)
            [
              cell.text,
              if (cell.description != null) cell.description!,
            ].join(', '),
        ].join('; ');

    Widget face(Fluent2Press state) {
      final fill = on
          ? (table.selectionAppearance == Fluent2TableSelectionAppearance.brand
                ? fluent2BrandWell(t)
                : fluent2Step(t, t.colors.subtleBackgroundSelected))
          : state == Fluent2Press.disabled
          ? t.colors.subtleBackground
          : state.pick(
              t.colors.subtleBackground,
              t.colors.subtleBackgroundHover,
              t.colors.subtleBackgroundPressed,
            );
      return Container(
        constraints: BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          color: fill,
          border: small
              ? null
              : Border(
                  bottom: BorderSide(
                    color: fluent2Step(t, t.colors.neutralStroke2),
                  ),
                ),
        ),
        child: Row(
          children: [
            if (picked != null)
              SizedBox(width: Fluent2Table.selectionWidthOf(context)),
            for (final (i, column) in table.columns.indexed)
              SizedBox(
                width: widths[i],
                child: _CellView(
                  cell: i < row.cells.length
                      ? row.cells[i]
                      : const Fluent2TableCell(''),
                  numeric: column.numeric,
                  small: small,
                ),
              ),
          ],
        ),
      );
    }

    final body = press == null
        ? Semantics(
            container: true,
            label: spoken,
            selected: picked == null ? null : on,
            excludeSemantics: true,
            child: face(Fluent2Press.rest),
          )
        : Semantics(
            container: true,
            child: Fluent2Pressable(
              onPressed: press,
              label: spoken,
              selected: picked == null ? null : on,
              radius: Fluent2Radius.medium,
              builder: (context, states) => face(states.press),
            ),
          );
    if (picked == null) return body;
    return Stack(
      children: [
        body,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width: Fluent2Table.selectionWidthOf(context),
          child: _SelectCell(
            checked: on,
            label: Fluent2Localizations.of(context).selectRow(
              row.cells.isEmpty
                  ? Fluent2Localizations.of(context).row
                  : row.cells.first.text,
            ),
            onTap: toggle,
          ),
        ),
      ],
    );
  }
}

class _CellView extends StatelessWidget {
  const _CellView({
    required this.cell,
    required this.numeric,
    required this.small,
  });

  final Fluent2TableCell cell;
  final bool numeric;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final description = cell.description;
    final media = cell.media;
    final base = small ? t.caption1 : t.body1;
    final main = cell.primary ? base.strong : base;
    final head = Text(
      cell.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: numeric ? TextAlign.end : TextAlign.start,
      style: numeric ? main.tabular : main,
    );
    // Words alone stand on the row's middle by their capitals.
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: numeric
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (description == null) fluent2CapCentred(head) else head,
        if (description != null)
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption1.c(t.textSecondary),
          ),
      ],
    );
    final glyph = small
        ? Fluent2IconSize.i16
        : cell.primary
        ? Fluent2IconSize.i24
        : Fluent2IconSize.i20;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Fluent2Spacing.s,
        vertical: Fluent2Spacing.xxs,
      ),
      child: Row(
        spacing: Fluent2Spacing.s,
        children: [
          if (media != null)
            IconTheme.merge(
              data: IconThemeData(size: glyph, color: t.textSecondary),
              child: media,
            ),
          Expanded(child: words),
        ],
      ),
    );
  }
}
