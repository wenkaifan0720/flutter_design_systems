/// A ruled table of records, sorted by its headings, on ui_core's data table.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme.dart';
import '../../internal/cap_center.dart';
import '../checkbox/checkbox.dart';

export 'package:ui_core/ui_core.dart'
    show DesignSortDirection, DesignTableColumn, DesignTableController;

/// A ruled table of records (a month's entries, a statement): the headings
/// in the small capitals over the ink rule, each a press that sorts by it
/// (its arrow saying which way), the rows ruled under in the body face with
/// numeric columns in the figures' face at their end. A row is a press that
/// selects it when [selectable] (its box drawn at its start, filled when
/// chosen; the box over the headings chooses the page), else opens it with
/// [onActivate]. When columns cannot fit whole words, the other fields appear
/// below the first text field with their column labels. The arrow keys move
/// along the rows, one tab stop for all
/// of them. [controller] holds the rows, the sort and the selection.
///
/// ```dart
/// LedgerDataTable<({String title, String amount})>(controller: table, cellText: (e, column) => column.id == 'amount' ? e.amount : e.title)
/// ```
class LedgerDataTable<R> extends StatelessWidget {
  /// The rows of [controller]'s page under its headings.
  const LedgerDataTable({
    required this.controller,
    required this.cellText,
    this.selectable = true,
    this.onActivate,
    super.key,
  });

  /// The rows, the columns and the table's view of them; the caller's.
  final DesignTableController<R> controller;

  /// What a row says in a column.
  final String Function(R row, DesignTableColumn<R> column) cellText;

  /// Whether a press selects rows.
  final bool selectable;

  /// A row's Enter, or its press when the table does not select.
  final ValueChanged<R>? onActivate;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('cellText', cellText));
    properties
      ..add(
        DiagnosticsProperty<DesignTableController<R>>('controller', controller),
      )
      ..add(FlagProperty('selectable', value: selectable, ifTrue: 'selectable'))
      ..add(ObjectFlagProperty<ValueChanged<R>>.has('onActivate', onActivate));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    AlignmentDirectional side(bool numeric) => numeric
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final scaler = MediaQuery.textScalerOf(context);
          final columns = controller.columns;
          final wordColumns = columns.where((column) => !column.numeric).length;
          final weight = wordColumns * 3 + (columns.length - wordColumns) * 2;
          final gaps =
              math.max(0, columns.length - (selectable ? 0 : 1)) *
                  LedgerSpacing.s12 +
              (selectable ? _box : 0);
          final room = math.max(0.0, box.maxWidth - gaps);
          final unit = box.hasBoundedWidth && weight > 0 ? room / weight : 0.0;
          final amounts = <int, double>{};
          final painter = TextPainter(
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          );
          double measure(String value, TextStyle style) {
            painter.text = TextSpan(text: value, style: style);
            painter.layout();
            return painter.width.ceilToDouble();
          }

          final rows = controller.pageRows;
          var wordWidth = 0.0;
          final breaks = RegExp(r'\s+');
          for (final (index, column) in columns.indexed) {
            if (!column.numeric) {
              for (final row in rows) {
                for (final word in cellText(row, column).split(breaks)) {
                  wordWidth = math.max(wordWidth, measure(word, t.body));
                }
              }
              continue;
            }
            var width = measure(column.label.toUpperCase(), t.tag);
            if (controller.sortColumn == column.id) {
              width += LedgerSpacing.s4 + LedgerIconSize.i14;
            }
            for (final row in rows) {
              width = math.max(
                width,
                measure(cellText(row, column), t.figureSmall),
              );
            }
            amounts[index] = math.max(width, unit * 2);
          }
          painter.dispose();
          final amountWidth = amounts.values.fold(0.0, (a, b) => a + b);
          final stacked =
              box.hasBoundedWidth &&
              wordColumns > 0 &&
              room - amountWidth < wordColumns * wordWidth;
          final minimum = gaps + amountWidth + wordColumns * scaler.scale(32);
          final tableWidth = box.hasBoundedWidth
              ? math.max(box.maxWidth, minimum)
              : minimum;
          Widget flexed(int index, Widget child) => amounts.containsKey(index)
              ? SizedBox(width: amounts[index], child: child)
              : Expanded(child: child);
          final firstText = columns.indexWhere((column) => !column.numeric);
          Widget stackedCells(List<Widget> cells) => Padding(
            padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: LedgerSpacing.s4,
              children: [
                cells[firstText],
                for (final (i, cell) in cells.indexed)
                  if (i != firstText)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: LedgerSpacing.s8,
                      children: [
                        Text(
                          columns[i].label.toUpperCase(),
                          style: t.tag.colored(t.textSecondary),
                        ),
                        if (columns[i].numeric)
                          FittedBox(fit: BoxFit.scaleDown, child: cell)
                        else
                          cell,
                      ],
                    ),
              ],
            ),
          );
          final table = DesignDataTable<R>(
            controller: controller,
            selectable: selectable,
            onActivate: onActivate,
            sortedHint: (d) =>
                d == DesignSortDirection.ascending ? 'ascending' : 'descending',
            headerBuilder: (context, column, sort, states) {
              final hot =
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed);
              // The heading's press spans its column; its words keep to a side.
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: _row),
                child: Align(
                  alignment: side(column.numeric),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: LedgerSpacing.s4,
                    children: [
                      Flexible(
                        child: ledgerCapCenter(
                          t.tag,
                          Text(
                            column.label.toUpperCase(),
                            style: t.tag.colored(
                              hot || sort != null
                                  ? t.textPrimary
                                  : t.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (sort != null)
                        Icon(
                          sort == DesignSortDirection.ascending
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                          size: LedgerIconSize.i14,
                          color: t.textPrimary,
                        ),
                    ],
                  ),
                ),
              );
            },
            headerRowBuilder: (context, cells) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: t.headRule, width: 1.5),
                ),
              ),
              child: Row(
                spacing: LedgerSpacing.s12,
                children: [
                  if (selectable)
                    DesignTapTarget(
                      minSize: const Size.square(_box),
                      child: LedgerCheckbox(
                        value: switch (controller.pageSelection) {
                          DesignSelection.all => true,
                          DesignSelection.none => false,
                          _ => null,
                        },
                        tristate: true,
                        semanticLabel: 'Choose the page',
                        onChanged: (_) => controller.togglePage(),
                      ),
                    ),
                  if (stacked)
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: LedgerSpacing.s8,
                        children: [
                          for (final cell in cells) IntrinsicWidth(child: cell),
                        ],
                      ),
                    )
                  else
                    for (final (i, h) in cells.indexed) flexed(i, h),
                ],
              ),
            ),
            cellBuilder: (context, row, column) {
              final style = column.numeric ? t.figureSmall : t.body;
              return ledgerCapCenter(
                style,
                Text(
                  cellText(row, column),
                  softWrap: !column.numeric,
                  textAlign: column.numeric
                      ? (rtl ? TextAlign.left : TextAlign.right)
                      : null,
                  style: style.colored(t.textPrimary),
                ),
              );
            },
            rowBuilder: (context, row, cells) {
              final focused = row.states.contains(WidgetState.focused);
              final hot =
                  row.states.contains(WidgetState.hovered) ||
                  row.states.contains(WidgetState.pressed);
              return AnimatedContainer(
                duration: LedgerMotion.of(context),
                constraints: const BoxConstraints(minHeight: _row),
                foregroundDecoration: focused
                    ? BoxDecoration(
                        border: Border.all(color: t.textPrimary, width: 1.5),
                      )
                    : null,
                decoration: BoxDecoration(
                  color: row.selected
                      ? t.selectedFill
                      : hot
                      ? t.surfaceAlt
                      : null,
                  border: Border(bottom: BorderSide(color: t.hairline)),
                ),
                child: Row(
                  spacing: LedgerSpacing.s12,
                  children: [
                    if (selectable)
                      // The row is the press; its box only says it is chosen.
                      ExcludeSemantics(
                        child: IgnorePointer(
                          child: SizedBox(
                            width: _box,
                            child: Center(
                              child: LedgerCheckbox(
                                value: row.selected,
                                onChanged: (_) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (stacked)
                      Expanded(child: stackedCells(cells))
                    else
                      for (final (i, c) in cells.indexed)
                        flexed(
                          i,
                          Align(
                            alignment: side(controller.columns[i].numeric),
                            child: c,
                          ),
                        ),
                  ],
                ),
              );
            },
          );
          if (stacked || (box.hasBoundedWidth && tableWidth == box.maxWidth)) {
            return table;
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: tableWidth, child: table),
          );
        },
      ),
    );
  }

  static const double _row = 44;
  static const double _box = 44;
}
