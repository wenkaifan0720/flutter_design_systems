/// A ruled table of records, sorted by its headings, on ui_core's data table.
library;

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
/// [onActivate]. The arrow keys move along the rows, one tab stop for all
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
    // A column's share of the line: words take more than figures.
    Widget flexed(int i, Widget child) =>
        Expanded(flex: controller.columns[i].numeric ? 2 : 3, child: child);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => DesignDataTable<R>(
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
          return SizedBox(
            height: _row,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.tag.colored(
                          hot || sort != null ? t.textPrimary : t.textSecondary,
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
            border: Border(bottom: BorderSide(color: t.headRule, width: 1.5)),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  static const double _row = 44;
  static const double _box = 44;
}
