import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../pagination/pagination.dart';

// A table's caller builds its controller and columns, and reads its sort
// and selection.
export 'package:ui_core/ui_core.dart'
    show
        DesignSelection,
        DesignSortDirection,
        DesignTableColumn,
        DesignTableController;

/// Rows of facts in columns: a [caption] in a heading's weight, the
/// columns' names in bold over an ink rule, each row on a hairline rule,
/// numbers lined up at the end. A column with a sort key sorts on a press
/// of its name, which is a link with an arrow that says the way it runs.
///
/// The rows take one tab stop: the arrow keys walk them, the row reached
/// lies on the yellow plate. With [selectable] a press or Space ticks a row
/// (a square tick at its start); with the controller's page size the pages
/// follow under it as a [CivicPagination].
///
/// The [controller] is the caller's: it makes it, keeps it across rebuilds
/// and disposes it.
///
/// Reads [CivicStyle]'s fill (a row, by state: hovered, selected),
/// foreground (a row's words), edge (the rows' rules) and textStyle (the
/// columns' names): its `style:`, then [CivicThemeData.tableStyle]. The
/// ink rule under the names and the focus plate are the look's.
///
/// ```dart
/// CivicTable<Map<String, String>>(
///   caption: 'Permits in your household',
///   controller: permits,
///   cellBuilder: (context, permit, column) => Text(permit[column.id] ?? ''),
/// )
/// ```
class CivicTable<R> extends StatelessWidget {
  /// A table of [controller]'s rows.
  const CivicTable({
    super.key,
    required this.controller,
    required this.cellBuilder,
    this.caption,
    this.selectable = false,
    this.onActivate,
    this.style,
  });

  /// The rows, the columns and the table's view of them.
  final DesignTableController<R> controller;

  /// A cell's content; the table sets its words' style.
  final Widget Function(
    BuildContext context,
    R row,
    DesignTableColumn<R> column,
  )
  cellBuilder;

  /// What the table shows, over it.
  final String? caption;

  /// Whether rows can be ticked.
  final bool selectable;

  /// A row's Enter, or its press when rows cannot be ticked; null leaves
  /// rows to be read.
  final ValueChanged<R>? onActivate;

  /// Overrides for this table's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final heading = caption;
    final names = text.label.merge(
      DesignStyleOf([style, t.tableStyle], const {}).textStyle,
    );
    Widget table(BuildContext context, BoxConstraints constraints) {
      final columns = controller.columns;
      final scaler = MediaQuery.textScalerOf(context);
      final minimum = [
        for (final column in columns)
          _columnWidth(context, column, names, scaler),
      ];
      final sum = minimum.fold<double>(0, (a, b) => a + b);
      final tickWidth = selectable ? _tick + CivicSpacing.s16 : 0.0;
      final width = math.max(
        constraints.hasBoundedWidth ? constraints.maxWidth : 0.0,
        sum + tickWidth,
      );
      final share = (width - tickWidth) / math.max(1, columns.length);
      final equal = minimum.every((w) => w <= share);
      Widget cell(int index, Widget child) => Expanded(
        flex: equal ? 1 : minimum[index].ceil(),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            top: CivicSpacing.s12,
            bottom: CivicSpacing.s12,
            end: CivicSpacing.s16,
          ),
          child: Align(
            alignment: columns[index].numeric
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: child,
          ),
        ),
      );
      Widget tick(bool on, Color ink) => Padding(
        padding: const EdgeInsetsDirectional.only(end: CivicSpacing.s16),
        child: SizedBox.square(
          dimension: _tick,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: ink, width: CivicMetrics.edge),
            ),
            child: on
                ? Icon(LucideIcons.check, size: _glyph, color: ink)
                : null,
          ),
        ),
      );
      final table = DesignDataTable<R>(
        controller: controller,
        selectable: selectable,
        onActivate: onActivate,
        headerRowBuilder: (context, cells) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: t.border, width: CivicMetrics.edge),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (selectable) const SizedBox(width: _tick + CivicSpacing.s16),
              for (final (i, c) in cells.indexed) cell(i, c),
            ],
          ),
        ),
        headerBuilder: (context, column, sort, states) {
          if (!column.sortable) {
            return Text(column.label, style: names);
          }
          final focused = states.contains(WidgetState.focused);
          final ink = focused ? t.onFocus : t.action;
          return CivicSpringValue(
            value: focused ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            builder: (context, focus, _) => CustomPaint(
              painter: CivicFacePainter(
                fill: t.focus.withValues(alpha: 0),
                edgeColor: t.onFocus,
                edgeHeight: 0,
                press: 0,
                focus: focus,
                focusColor: t.focus,
                barColor: t.focusBar,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: CivicMetrics.bar),
                child: Wrap(
                  spacing: CivicSpacing.s4,
                  alignment: column.numeric
                      ? WrapAlignment.end
                      : WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      column.label,
                      style: names.copyWith(
                        color: ink,
                        decoration: TextDecoration.underline,
                        decorationColor: ink,
                      ),
                    ),
                    Icon(
                      switch (sort) {
                        DesignSortDirection.ascending => LucideIcons.arrowUp,
                        DesignSortDirection.descending => LucideIcons.arrowDown,
                        null => LucideIcons.arrowUpDown,
                      },
                      size: _glyph,
                      applyTextScaling: true,
                      color: ink,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        cellBuilder: cellBuilder,
        rowBuilder: (context, row, cells) {
          final focused = row.states.contains(WidgetState.focused);
          final hovered = row.states.contains(WidgetState.hovered);
          final so = DesignStyleOf(
            [style, t.tableStyle],
            {...row.states, if (row.selected) WidgetState.selected},
          );
          final ink = focused ? t.onFocus : so.foreground ?? t.textPrimary;
          final rest =
              so.fill ??
              (row.selected || hovered
                  ? t.surface
                  : t.surface.withValues(alpha: 0));
          return CivicSpringValue(
            value: focused ? 1 : 0,
            spring: CivicMotion.focus,
            effects: true,
            builder: (context, focus, _) => DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(rest, t.focus, focus),
                border: Border(
                  bottom: BorderSide(
                    color: Color.lerp(so.edge ?? t.rule, t.onFocus, focus)!,
                    width: 1 + (CivicMetrics.bar - 1) * focus,
                  ),
                ),
              ),
              child: DefaultTextStyle.merge(
                style: text.body.copyWith(color: ink),
                child: IconTheme.merge(
                  data: IconThemeData(color: ink),
                  child: Row(
                    children: [
                      if (selectable) tick(row.selected, ink),
                      for (final (i, c) in cells.indexed) cell(i, c),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
      if (!constraints.hasBoundedWidth || width > constraints.maxWidth + 0.01) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: table),
        );
      }
      return table;
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heading != null) ...[
            Semantics(header: true, child: Text(heading, style: text.headingM)),
            const SizedBox(height: CivicSpacing.s16),
          ],
          LayoutBuilder(builder: table),
          if (controller.pageCount > 1) ...[
            const SizedBox(height: CivicSpacing.s24),
            CivicPagination(
              pageCount: controller.pageCount,
              selectedIndex: controller.page,
              onPageChanged: controller.goToPage,
            ),
          ],
        ],
      ),
    );
  }

  static double _columnWidth(
    BuildContext context,
    DesignTableColumn<dynamic> column,
    TextStyle style,
    TextScaler scaler,
  ) {
    final p = TextPainter(
      text: TextSpan(text: column.label, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final word = p.minIntrinsicWidth.ceilToDouble();
    p.dispose();
    final icon = column.sortable ? scaler.scale(_glyph) : 0.0;
    return math.max(word, icon) + CivicSpacing.s16;
  }

  /// A row's tick box, and the room a header keeps for it.
  static const double _tick = 24;

  /// The tick's and a sort arrow's glyph.
  static const double _glyph = 18;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<DesignTableController<R>>('controller', controller),
      )
      ..add(StringProperty('caption', caption, defaultValue: null))
      ..add(FlagProperty('selectable', value: selectable, ifTrue: 'selectable'))
      ..add(ObjectFlagProperty<ValueChanged<R>>.has('onActivate', onActivate))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
