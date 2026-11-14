/// The table: records with the same fields (CONTRACT §4.1 `table`, the
/// one row Compose's material3 does not carry). Expressive derives it from
/// its list grammar rather than inventing one: Material's list item tokens
/// give the row's height, its leading and trailing space and its type, the
/// divider stands between rows, a chosen row wears the list's selected
/// container, and a row that opens something takes the press every list
/// item has.
///
/// Narrower than [ExpressiveTable.stackBelow] (the medium window class:
/// every phone held upright) a row stops being a row: it becomes a list
/// item, its first cell the headline and each other cell a supporting line
/// under its column's name. Nothing is cut and nothing scrolls sideways.
library;

import 'package:flutter/widgets.dart';

import '../internal/cap_label.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/list_tokens.g.dart';
import '../states.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../internal/styled_content.dart';
import '../theme.dart';
import 'lists.dart';

/// A column of an [ExpressiveTable].
@immutable
class ExpressiveTableColumn {
  /// A column headed [label].
  const ExpressiveTableColumn(this.label, {this.numeric = false, this.flex = 1})
    : assert(flex > 0, 'a column takes a share of the width');

  /// The column's head.
  final String label;

  /// Figures: set to the column's end in tabular numerals, so they line up.
  final bool numeric;

  /// Its share of the width, beside the other columns' shares.
  final int flex;
}

/// A row of an [ExpressiveTable]: its cells in column order, each a
/// `String` or a `Widget`. The first cell is what the row is called.
@immutable
class ExpressiveTableRow {
  /// A row of [cells].
  const ExpressiveTableRow(
    this.cells, {
    this.onPressed,
    this.selected = false,
    this.style,
    this.key,
  });

  /// Stateful overrides for this row.
  final ExpressiveComponentThemeData? style;

  /// The cells, in column order: each a `String` or a `Widget`.
  final List<Object> cells;

  /// Called when the row is pressed: the whole row opens something. Null:
  /// the row takes no press.
  final VoidCallback? onPressed;

  /// Chosen: the row wears the list's selected container.
  final bool selected;

  /// The key on the row.
  final Key? key;
}

/// Records with the same fields, in rows under their columns' heads, from
/// the list's tokens: each row at least a one-line list item tall, a
/// divider between rows, figures at the column's end in tabular numerals.
/// A row with `onPressed` takes the list item's press; a selected one wears
/// the list's selected container. Under [stackBelow] wide each row is a list
/// item instead, its other cells named lines under its first.
///
/// A screen reader hears each row as one node: every cell under its
/// column's name.
///
/// ```dart
/// ExpressiveTable(columns: const [ExpressiveTableColumn('Plant', flex: 2), ExpressiveTableColumn('Water', numeric: true)], rows: const [ExpressiveTableRow(['Fern', '200 ml']), ExpressiveTableRow(['Cactus', '50 ml'])])
/// ```
class ExpressiveTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const ExpressiveTable({
    required this.columns,
    required this.rows,
    this.semanticLabel,
    this.style,
    this.stackBelow = ExpressiveWindowSizeClass.medium,
    super.key,
  });

  /// Stateful visual slots for the table rows and header.
  final ExpressiveComponentThemeData? style;

  /// The columns, in order.
  final List<ExpressiveTableColumn> columns;

  /// The rows, in order.
  final List<ExpressiveTableRow> rows;

  /// What the table is, read out before it.
  final String? semanticLabel;

  /// The window class from which rows stand as rows: narrower than its
  /// least width, each row stacks as a list item.
  final ExpressiveWindowSizeClass stackBelow;

  String _spoken(ExpressiveTableRow row) => <String>[
    for (var i = 0; i < row.cells.length && i < columns.length; i++)
      if (row.cells[i] is String) '${columns[i].label}: ${row.cells[i]}',
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final Widget table = LayoutBuilder(
      builder: (context, box) => box.maxWidth < stackBelow.minWidth
          ? _stacked(context)
          : _ruled(context),
    );
    final label = semanticLabel;
    return label == null
        ? table
        : Semantics(container: true, label: label, child: table);
  }

  Widget _stacked(BuildContext context) {
    final t = context.expressiveTheme;
    return ExpressiveListSection(
      children: <Widget>[
        for (final row in rows)
          Semantics(
            key: row.key,
            selected: row.selected,
            // A selected row is written in the list item's selected
            // colours (`ListTokens.itemSelected…`) on its container.
            child: ExpressiveListTile(
              style: _tableRowStyle(
                ExpressiveComponentThemeData(
                  backgroundColor: row.selected
                      ? WidgetStatePropertyAll(
                          t.colors.role(ListTokens.itemSelectedContainerColor),
                        )
                      : null,
                ).merge(t.tableTheme).merge(style).merge(row.style),
                row.selected,
              ),
              title: _cellText(
                row.cells.isEmpty ? '' : row.cells.first,
                row.selected
                    ? TextStyle(
                        color: t.colors.role(
                          ListTokens.itemSelectedLabelTextColor,
                        ),
                      )
                    : null,
              ),
              subtitle: _supporting(
                row,
                row.selected
                    ? TextStyle(
                        color: t.colors.role(
                          ListTokens.itemSelectedSupportingTextColor,
                        ),
                      )
                    : null,
              ),
              trailing: _trailingWidget(row),
              tileColor: null,
              semanticLabel: _spoken(row),
              onTap: row.onPressed,
            ),
          ),
      ],
    );
  }

  Widget _cellText(Object cell, [TextStyle? style]) => cell is Widget
      ? cell
      : Builder(
          builder: (context) {
            final scope = ExpressiveStyleScope.maybeOf(context);
            final ink = scope?.style.foregroundColor?.resolve(scope.states);
            return Text(
              '$cell',
              style: (style ?? const TextStyle()).copyWith(
                color: ink ?? style?.color,
              ),
            );
          },
        );

  Widget? _supporting(ExpressiveTableRow row, [TextStyle? style]) {
    final lines = <String>[
      for (var i = 1; i < row.cells.length && i < columns.length; i++)
        if (row.cells[i] is String) '${columns[i].label}: ${row.cells[i]}',
    ];
    return lines.isEmpty
        ? null
        : Builder(
            builder: (context) {
              final scope = ExpressiveStyleScope.maybeOf(context);
              final ink = scope?.style.foregroundColor?.resolve(scope.states);
              return Text(
                lines.join('\n'),
                style: (style ?? const TextStyle()).copyWith(
                  color: ink ?? style?.color,
                ),
              );
            },
          );
  }

  Widget? _trailingWidget(ExpressiveTableRow row) {
    for (var i = 1; i < row.cells.length; i++) {
      final cell = row.cells[i];
      if (cell is Widget) return cell;
    }
    return null;
  }

  Widget _ruled(BuildContext context) {
    final t = context.expressiveTheme;
    final head = t.type
        .of(ExpressiveTypeKey.labelLarge)
        .copyWith(color: t.colors.role(ListTokens.itemSupportingTextColor));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ExcludeSemantics(
          child: _Cells(
            columns: columns,
            cells: <Object>[for (final c in columns) c.label],
            style: head,
            numericStyle: head,
            visual: t.tableTheme.merge(style),
          ),
        ),
        for (final row in rows) ...<Widget>[
          const ExpressiveDivider(),
          _RuledRow(
            key: row.key,
            columns: columns,
            row: row,
            spoken: _spoken(row),
            style: t.tableTheme.merge(style).merge(row.style),
          ),
        ],
      ],
    );
  }
}

class _RuledRow extends StatelessWidget {
  const _RuledRow({
    required this.columns,
    required this.row,
    required this.spoken,
    required this.style,
    super.key,
  });

  final List<ExpressiveTableColumn> columns;
  final ExpressiveTableRow row;
  final String spoken;
  final ExpressiveComponentThemeData style;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final content = t.colors.role(
      row.selected
          ? ListTokens.itemSelectedLabelTextColor
          : ListTokens.itemLabelTextColor,
    );
    final style = t.type
        .of(ListTokens.itemLabelTextFont)
        .copyWith(color: content);
    final cells = _Cells(
      columns: columns,
      cells: row.cells,
      visual: this.style,
      selected: row.selected,
      inheritState: row.onPressed != null,
      style: style,
      numericStyle: style.copyWith(
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
    final container = row.selected
        ? t.colors.role(ListTokens.itemSelectedContainerColor)
        : expressiveTransparent;
    final pressed = row.onPressed;
    if (pressed == null) {
      return Semantics(
        container: true,
        selected: row.selected,
        label: spoken,
        child: ExcludeSemantics(
          child: ExpressiveSurface(
            componentStyle: ExpressiveComponentThemeData(
              backgroundColor: this.style.backgroundColor,
              foregroundColor: this.style.foregroundColor,
              outline: this.style.outline,
              overlayColor: this.style.overlayColor,
              side: this.style.side,
              shape: this.style.shape,
            ),
            states: {if (row.selected) WidgetState.selected},
            shape: t.shapes.of(ListTokens.itemContainerShape),
            color: container,
            contentColor: content,
            child: cells,
          ),
        ),
      );
    }
    return ExpressivePressable(
      componentStyle: this.style,
      shapes: ExpressivePressShapes.all(
        t.shapes.of(ListTokens.itemContainerShape),
      ),
      motion: ListItemBehavior.shapeMotion,
      color: container,
      contentColor: content,
      selected: row.selected,
      semanticLabel: spoken,
      onPressed: pressed,
      child: ExcludeSemantics(child: cells),
    );
  }
}

/// One line of cells, each in its column's share, at least a one-line list
/// item tall, inset by the list's leading and trailing space.
class _Cells extends StatelessWidget {
  const _Cells({
    required this.columns,
    required this.cells,
    required this.style,
    required this.numericStyle,
    this.visual = const ExpressiveComponentThemeData(),
    this.selected = false,
    this.inheritState = false,
  });

  final List<ExpressiveTableColumn> columns;
  final List<Object> cells;
  final TextStyle style;
  final TextStyle numericStyle;
  final ExpressiveComponentThemeData visual;
  final bool selected;
  final bool inheritState;

  @override
  Widget build(BuildContext context) {
    final scope = inheritState ? ExpressiveStyleScope.maybeOf(context) : null;
    Widget content(BuildContext context) {
      final inherited = ExpressiveStyleScope.maybeOf(context)!;
      final states = inherited.states;
      final resolved = inherited.style;
      TextStyle textStyle(TextStyle own) => own
          .merge(resolved.textStyle?.resolve(states))
          .copyWith(color: resolved.foregroundColor?.resolve(states));
      return ExpressiveStyledContent(
        minimumSize: const Size(0, ListTokens.itemOneLineContainerHeight),
        padding: const EdgeInsetsDirectional.only(
          start: ListTokens.itemLeadingSpace,
          end: ListTokens.itemTrailingSpace,
          top: ListTokens.itemTopSpace,
          bottom: ListTokens.itemBottomSpace,
        ),
        center: false,
        child: Row(
          children: <Widget>[
            for (var i = 0; i < columns.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: ListTokens.itemBetweenSpace),
              Expanded(
                flex: columns[i].flex,
                child: _cell(
                  i < cells.length ? cells[i] : '',
                  columns[i].numeric,
                  textStyle(columns[i].numeric ? numericStyle : style),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (scope != null) return content(context);
    return ExpressiveStyleScope(
      style: visual,
      states: {if (selected) WidgetState.selected},
      inset: EdgeInsets.zero,
      child: Builder(builder: content),
    );
  }

  Widget _cell(Object cell, bool numeric, TextStyle resolved) {
    if (cell is Widget) {
      return Align(
        alignment: numeric
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: cell,
      );
    }
    // A cell's words on its row's middle, by their capitals.
    return expressiveFaceLabel(
      Text(
        '$cell',
        style: resolved,
        textAlign: numeric ? TextAlign.end : TextAlign.start,
      ),
    );
  }
}

// Keep selected-row semantics independent of whether it opens a destination.
ExpressiveComponentThemeData _tableRowStyle(
  ExpressiveComponentThemeData style,
  bool selected,
) {
  if (!selected) return style;
  WidgetStateProperty<T?>? selectedValue<T>(
    WidgetStateProperty<T?>? property,
  ) => property == null
      ? null
      : WidgetStateProperty.resolveWith(
          (states) => property.resolve({...states, WidgetState.selected}),
        );
  return ExpressiveComponentThemeData(
    backgroundColor: selectedValue(style.backgroundColor),
    foregroundColor: selectedValue(style.foregroundColor),
    outline: selectedValue(style.outline),
    overlayColor: selectedValue(style.overlayColor),
    side: selectedValue(style.side),
    shape: selectedValue(style.shape),
    padding: selectedValue(style.padding),
    minimumSize: selectedValue(style.minimumSize),
    textStyle: selectedValue(style.textStyle),
    iconSize: selectedValue(style.iconSize),
  );
}
