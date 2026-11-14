/// The data table, painted on ui_core's `DesignDataTable`: sortable
/// headers, selectable rows, a page at a time.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../icons.dart';
import '../internal/state_face.dart';
import '../internal/tokens/list_tokens.g.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'lists.dart' show ExpressiveDivider;
import 'selection.dart' show ExpressiveCheckbox;
import 'wayfinding.dart' show ExpressivePagination;

// The table's state, so a screen builds an ExpressiveDataTable through the
// barrel alone.
export 'package:ui_core/ui_core.dart'
    show
        DesignSelection,
        DesignSortDirection,
        DesignTableColumn,
        DesignTableController,
        DesignTableRow;

/// A sorted header's arrow: Material's small icon.
const double _arrow = 18;

/// The rows a [DesignTableController] holds, a page at a time, under a
/// header that sorts (shadcn's `DataTable`; Material's data table): rows
/// in the list item's grammar, as [ExpressiveTable]'s, at least 56dp tall,
/// a hairline between each, a chosen row on the list's selected container
/// (`secondaryContainer`), the state layer filling the row's own square,
/// the focus ring inside it. With [selectable] a checkbox stands before
/// each row and a tristate one before the header, which takes the page.
/// A sortable header is a pill: its label and an arrow pointing the sort's
/// way, its state layer on the pill, its target 48dp tall. Past one page,
/// [ExpressivePagination] stands under the rows.
///
/// The keys are ui_core's: one tab stop for the rows, Up and Down between
/// them, Home and End, Space or a press selects, Shift with either a run,
/// Ctrl or Cmd with A the page, Enter runs [onActivate]. Give it a bounded
/// width: the columns share it ([columnFlex]).
///
/// ```dart
/// ExpressiveDataTable<String>(controller: orders, cellBuilder: (context, order, column) => Text(order))
/// ```
class ExpressiveDataTable<R> extends StatelessWidget {
  /// A table of [controller]'s rows.
  const ExpressiveDataTable({
    required this.controller,
    required this.cellBuilder,
    this.selectable = true,
    this.onActivate,
    this.columnFlex = const <String, int>{},
    super.key,
  });

  /// The rows, columns, sort, filter, selection and page.
  final DesignTableController<R> controller;

  /// A cell: usually a `Text`, which takes the row's type and colour.
  final Widget Function(
    BuildContext context,
    R row,
    DesignTableColumn<R> column,
  )
  cellBuilder;

  /// Whether rows are chosen, each with its checkbox.
  final bool selectable;

  /// A row's Enter, or its press when rows are not chosen.
  final ValueChanged<R>? onActivate;

  /// Each column's share of the width by its id; 1 when absent.
  final Map<String, int> columnFlex;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final t = context.expressiveTheme;
        final strings = ExpressiveLocalizations.of(context);
        final pages = controller.pageCount;
        final empty = controller.pageRows.isEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DesignDataTable<R>(
              controller: controller,
              selectable: selectable,
              onActivate: onActivate,
              headerRowBuilder: (context, cells) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _line(
                    context,
                    lead: selectable
                        ? ExpressiveCheckbox(
                            value: switch (controller.pageSelection) {
                              DesignSelection.none => false,
                              DesignSelection.some => null,
                              DesignSelection.all => true,
                            },
                            tristate: true,
                            semanticLabel: strings.selectPage,
                            onChanged: !empty
                                ? (_) => controller.togglePage()
                                : null,
                          )
                        : null,
                    cells: cells,
                  ),
                  const ExpressiveDivider(),
                ],
              ),
              headerBuilder: _header,
              cellBuilder: (context, row, column) => Align(
                alignment: column.numeric
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: cellBuilder(context, row, column),
              ),
              rowBuilder: (context, row, cells) => _row(context, row, cells),
            ),
            if (empty)
              SizedBox(
                height: ListTokens.itemOneLineContainerHeight,
                child: Center(
                  child: Text(
                    strings.noResults,
                    style: t.type.bodyMedium.copyWith(
                      color: t.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (pages > 1)
              Padding(
                padding: const EdgeInsets.only(top: ExpressiveSpacing.s8),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ExpressivePagination(
                    page: controller.page + 1,
                    count: pages,
                    onChanged: (page) => controller.goToPage(page - 1),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// One line of the table: the checkbox slot, then the cells in their
  /// shares, inset as a list item.
  Widget _line(
    BuildContext context, {
    required Widget? lead,
    required List<Widget> cells,
  }) {
    final columns = controller.columns;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: ListTokens.itemOneLineContainerHeight,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: lead == null
              ? ListTokens.itemLeadingSpace
              : ExpressiveSpacing.s4,
          end: ListTokens.itemTrailingSpace,
        ),
        child: Row(
          children: <Widget>[
            if (lead != null) ...<Widget>[
              SizedBox(
                width: ExpressiveSpacing.s48,
                child: Center(child: lead),
              ),
              const SizedBox(width: ExpressiveSpacing.s4),
            ],
            for (var i = 0; i < cells.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: ListTokens.itemBetweenSpace),
              Expanded(
                flex: i < columns.length ? columnFlex[columns[i].id] ?? 1 : 1,
                child: cells[i],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    DesignTableColumn<R> column,
    DesignSortDirection? sort,
    Set<WidgetState> states,
  ) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final ink = sort == null ? c.onSurfaceVariant : c.onSurface;
    final label = Text(
      column.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: t.type.labelLarge.copyWith(color: ink),
    );
    final align = column.numeric
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    if (!column.sortable) return Align(alignment: align, child: label);
    // The pill's padding stands outside the column's edge, so the label
    // lines up with the cells under it.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shift = (column.numeric ? 1 : -1) * (rtl ? -1 : 1) * 8.0;
    // The pill keeps its 32dp; the header's target is 48dp tall.
    return ExpressiveMinimumInteractiveSize(
      child: Align(
        alignment: align,
        child: Transform.translate(
          offset: Offset(shift, 0),
          child: ExpressiveStateFace(
            states: states,
            shape: t.shapes.full,
            color: const Color(0x00000000),
            contentColor: ink,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: ExpressiveSpacing.s8,
              vertical: ExpressiveSpacing.s6,
            ),
            // A numeric column's arrow stands before its label (as
            // Flutter's DataTable puts it), so the label ends where the
            // numbers under it do.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (!column.numeric) Flexible(child: label),
                if (!column.numeric)
                  const SizedBox(width: ExpressiveSpacing.s4),
                SizedBox.square(
                  dimension: _arrow,
                  child: sort == null
                      ? null
                      : Icon(
                          sort == DesignSortDirection.ascending
                              ? ExpressiveSymbols.arrowUpward
                              : ExpressiveSymbols.arrowDownward,
                          size: _arrow,
                          color: ink,
                        ),
                ),
                if (column.numeric) const SizedBox(width: ExpressiveSpacing.s4),
                if (column.numeric) Flexible(child: label),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, DesignTableRow<R> row, List<Widget> cells) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final strings = ExpressiveLocalizations.of(context);
    final content = c.role(
      row.selected
          ? ListTokens.itemSelectedLabelTextColor
          : ListTokens.itemLabelTextColor,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (row.index > 0) const ExpressiveDivider(),
        ExpressiveStateFace(
          states: row.states,
          shape: t.shapes.of(ListTokens.itemContainerShape),
          color: row.selected
              ? c.role(ListTokens.itemSelectedContainerColor)
              : const Color(0x00000000),
          contentColor: content,
          focusInward: true,
          child: DefaultTextStyle.merge(
            style: t.type
                .of(ListTokens.itemLabelTextFont)
                .copyWith(color: content),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: _line(
              context,
              lead: selectable
                  ? ExcludeFocus(
                      child: ExpressiveCheckbox(
                        value: row.selected,
                        semanticLabel: strings.selectRow,
                        onChanged: (_) => row.toggle(),
                      ),
                    )
                  : null,
              cells: cells,
            ),
          ),
        ),
      ],
    );
  }
}
