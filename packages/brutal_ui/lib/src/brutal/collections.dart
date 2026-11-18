/// Brutal's collections, painted over the foundation's behaviour: a data
/// table that sorts, selects and pages; a scroll area with a square thumb;
/// panes split by a draggable rule; a carousel; a list reordered by its
/// handles; a row with actions behind it; pull to refresh; and a tree.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'feedback.dart';
import 'lists.dart';
import 'localizations.dart';
import 'surface.dart';
import 'theme.dart';
import 'wayfinding.dart';

/// A column of a [BrutalDataTable]: [label] over its cells, sortable when
/// it has a [sortKey].
class BrutalDataColumn<R> extends DesignTableColumn<R> {
  /// A column named [id], headed [label].
  const BrutalDataColumn({
    required super.id,
    required super.label,
    super.sortKey,
    super.numeric,
    this.flex = 1,
  });

  /// Its share of the table's width.
  final int flex;
}

/// A [BrutalDataTable]'s rows and its view of them: the filter ([query]),
/// the sort, the selection and the page. Make it in a State, keep it
/// across rebuilds and dispose it.
///
/// ```dart
/// final table = BrutalTableController<Map<String, String>>(rows: orders, columns: [BrutalDataColumn(id: 'name', label: 'Name', sortKey: (o) => o['name']!)], pageSize: 10);
/// ```
class BrutalTableController<R> extends DesignTableController<R> {
  /// A table of [rows] in [columns]; [pageSize] null shows every row.
  BrutalTableController({
    required super.rows,
    required List<BrutalDataColumn<R>> super.columns,
    super.rowKey,
    super.pageSize,
    super.filter,
  });
}

/// A table that sorts, selects and pages: its header in ink (a press on a
/// sortable heading sorts by it, its arrow says which way), each row on a
/// rule with a box for its selection (lime once chosen, ink while pressed),
/// and pages under it when [BrutalTableController.pageSize] is set.
///
/// Up and Down move through the rows, Space (or a press) selects one,
/// Shift extends the selection, Ctrl or Cmd A selects the page, and Enter
/// opens one with [onActivate].
///
/// Reads [style]'s `fill` (a row in its states, selected among them; a
/// pressed row stays ink), `foreground` (a row's words, but a pressed
/// one's), `edge` (the frame and the rules between rows), `padding` (each
/// cell's) and `textStyle` (the cells' words), then
/// [BrutalThemeData.dataTableStyle]'s. The header row stays ink.
///
/// ```dart
/// BrutalDataTable<Map<String, String>>(controller: table, cell: (o, column) => o[column] ?? '')
/// ```
class BrutalDataTable<R> extends StatelessWidget {
  /// A table of [controller]'s page.
  const BrutalDataTable({
    super.key,
    required this.controller,
    required this.cell,
    this.selectable = true,
    this.onActivate,
    this.emptyText = 'Nothing to show',
    this.style,
  });

  /// The rows, the columns and the view of them.
  final BrutalTableController<R> controller;

  /// A cell's words: [R]'s value in the column of that id.
  final String Function(R row, String columnId) cell;

  /// Whether a press and Space select rows.
  final bool selectable;

  /// A row's Enter, or its press when the table does not select.
  final ValueChanged<R>? onActivate;

  /// What it says when no row matches.
  final String emptyText;

  /// Its style, over [BrutalThemeData.dataTableStyle].
  final BrutalStyle? style;

  static const double _box = 48;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layers = [style, theme.dataTableStyle];
    final frame = DesignStyleOf(layers, const {});
    final rule = frame.side?.color ?? frame.edge ?? c.ink;
    BrutalDataColumn<R> brutal(DesignTableColumn<R> col) =>
        col as BrutalDataColumn<R>;
    Widget check(bool on, Color ink, {bool some = false}) => SizedBox(
      width: _box,
      child: Center(
        child: SizedBox.square(
          dimension: 18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: on ? ink : null,
              border: Border.all(color: ink, width: theme.borderWidth),
            ),
            child: on
                ? Icon(LucideIcons.check, size: 14, color: c.onColor(ink))
                : some
                ? Center(
                    child: SizedBox(
                      width: 8,
                      height: 2,
                      child: ColoredBox(color: ink),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
    final pad =
        frame.padding(Directionality.of(context)) ??
        const EdgeInsets.symmetric(
          horizontal: BrutalSpacing.medium,
          vertical: BrutalSpacing.medium,
        );
    final table = DesignDataTable<R>(
      controller: controller,
      selectable: selectable,
      onActivate: onActivate,
      headerBuilder: (context, column, sort, states) {
        final lit = states.contains(WidgetState.pressed);
        final words = Text(
          column.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.caption.copyWith(color: lit ? c.ink : c.paper),
        );
        return ColoredBox(
          color: lit ? c.paper : c.ink,
          child: CustomPaint(
            foregroundPainter: states.contains(WidgetState.focused)
                ? BrutalInsetFocusPainter(c.paper)
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _box),
              child: Padding(
                padding: pad,
                child: Row(
                  mainAxisAlignment: column.numeric
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(child: words),
                    if (column.sortable) ...[
                      const SizedBox(width: BrutalSpacing.tight),
                      Icon(
                        switch (sort) {
                          DesignSortDirection.ascending => LucideIcons.arrowUp,
                          DesignSortDirection.descending =>
                            LucideIcons.arrowDown,
                          null => LucideIcons.arrowUpDown,
                        },
                        size: 14,
                        color: (lit ? c.ink : c.paper).withValues(
                          alpha: sort == null ? 0.6 : 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      headerRowBuilder: (context, cells) {
        final page = controller.pageSelection;
        return ColoredBox(
          color: c.ink,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selectable)
                  DesignPressable(
                    onPressed: controller.pageRows.isEmpty
                        ? null
                        : controller.togglePage,
                    semanticLabel: 'Select the page',
                    checked: page == DesignSelection.all,
                    builder: (context, states, _) => CustomPaint(
                      foregroundPainter: states.contains(WidgetState.focused)
                          ? BrutalInsetFocusPainter(c.paper)
                          : null,
                      child: check(
                        page == DesignSelection.all,
                        c.paper,
                        some: page == DesignSelection.some,
                      ),
                    ),
                  ),
                for (final (i, cellWidget) in cells.indexed) ...[
                  if (i > 0 || selectable)
                    BrutalRule(color: c.paper, vertical: true),
                  Expanded(
                    flex: brutal(controller.columns[i]).flex,
                    child: cellWidget,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      cellBuilder: (context, row, column) => Padding(
        padding: pad,
        child: Text(
          cell(row, column.id),
          textAlign: column.numeric ? TextAlign.end : TextAlign.start,
          style: column.numeric
              ? frame
                    .text(t.body)
                    .copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )
              : frame.text(t.body),
        ),
      ),
      rowBuilder: (context, row, cells) {
        final pressed = row.states.contains(WidgetState.pressed);
        final layered = DesignStyleOf(layers, {
          ...row.states,
          if (row.selected) WidgetState.selected,
        });
        final fill = pressed
            ? c.ink
            : layered.fill ?? (row.selected ? c.lime : c.surface);
        final ink = pressed
            ? c.onColor(fill)
            : layered.foreground ?? c.onColor(fill);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BrutalRule(color: rule),
            ColoredBox(
              color: fill,
              child: CustomPaint(
                foregroundPainter: row.states.contains(WidgetState.focused)
                    ? BrutalInsetFocusPainter(ink)
                    : null,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: ink),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (selectable)
                          ExcludeSemantics(child: check(row.selected, ink)),
                        for (final (i, cellWidget) in cells.indexed) ...[
                          if (i > 0 || selectable)
                            BrutalRule(color: ink, vertical: true),
                          Expanded(
                            flex: brutal(controller.columns[i]).flex,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: 1,
                              child: cellWidget,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          BrutalSurface(
            face: BrutalFace(
              fill: frame.fill ?? c.surface,
              border: rule,
              foreground: c.ink,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                table,
                if (controller.pageRows.isEmpty) ...[
                  BrutalRule(color: rule),
                  Padding(
                    padding: const EdgeInsets.all(BrutalSpacing.regular),
                    child: Text(emptyText, style: t.secondary),
                  ),
                ],
              ],
            ),
          ),
          if (controller.pageSize != null && controller.pageCount > 1) ...[
            const SizedBox(height: BrutalSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectable && controller.selectedCount > 0
                        ? DesignLocalizations.of(context)
                              .selectedRowCountTitle(controller.selectedCount)
                        : BrutalLocalizations.of(context)
                              .rowCount(controller.filteredRows.length),
                    style: t.secondary,
                  ),
                ),
                BrutalPagination(
                  page: controller.page + 1,
                  pageCount: controller.pageCount,
                  onChanged: (p) => controller.goToPage(p - 1),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('selectable', value: selectable, ifTrue: 'selectable'),
    );
  }
}

/// [child], a scroll view on [controller], with a square ink thumb on a
/// ruled track at its end edge: shown while it scrolls or the pointer is
/// over it, held while dragged. Focused, the arrows and Page keys scroll it.
///
/// Reads [style]'s `edge` (the track's rule) and `foreground` (the thumb, in
/// its states), then [BrutalThemeData.scrollAreaStyle]'s.
///
/// ```dart
/// BrutalScrollArea(controller: scroll, child: ListView(controller: scroll, children: rows))
/// ```
class BrutalScrollArea extends StatelessWidget {
  /// A scroll area on [controller].
  const BrutalScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
    this.style,
  });

  /// The scroll view's controller.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.scrollAreaStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.scrollAreaStyle];
    final track = DesignStyleOf(layers, const {});
    final rule = track.side?.color ?? track.edge;
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      semanticLabel: semanticLabel,
      thickness: 12,
      trackBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: const Duration(milliseconds: 120),
        child: Align(
          alignment: thumb.axis == Axis.vertical
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.topCenter,
          child: BrutalRule(vertical: thumb.axis == Axis.vertical, color: rule),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final held = thumb.states.contains(WidgetState.pressed);
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: ColoredBox(
            color:
                DesignStyleOf(layers, thumb.states).foreground ??
                (held ? c.ink : c.inkMuted),
          ),
        );
      },
      frameBuilder: (context, focused, area) => CustomPaint(
        foregroundPainter: focused ? BrutalInsetFocusPainter(c.ink) : null,
        child: area,
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ScrollController>('controller', controller))
      ..add(DiagnosticsProperty<Axis>('axis', axis))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// [first] and [second] side by side (or stacked, [axis] vertical) with a
/// 2 px ink rule between that a drag moves; a square grip on the rule shows
/// where to take it. Focused, the arrow keys move it.
///
/// Reads [style]'s `edge` (the rule and the grip's) and `fill` (the grip,
/// in its states; pressed or focused it is the signal colour unless the
/// style says), then [BrutalThemeData.splitViewStyle]'s.
///
/// ```dart
/// BrutalSplitView(first: list, second: detail, initialFraction: 0.4)
/// ```
class BrutalSplitView extends StatelessWidget {
  /// Two panes split at [initialFraction] (the first pane's share).
  const BrutalSplitView({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = 0.5,
    this.minFirst = 120,
    this.minSecond = 120,
    this.onChanged,
    this.semanticLabel = 'Resize the panes',
    this.style,
  });

  /// The first pane: start, or top.
  final Widget first;

  /// The second pane.
  final Widget second;

  /// Which way the panes lie.
  final Axis axis;

  /// The first pane's share to start with.
  final double initialFraction;

  /// The narrowest the first pane goes.
  final double minFirst;

  /// The narrowest the second pane goes.
  final double minSecond;

  /// Called with the first pane's share as it moves.
  final ValueChanged<double>? onChanged;

  /// What a screen reader calls the divider.
  final String semanticLabel;

  /// Its style, over [BrutalThemeData.splitViewStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.splitViewStyle];
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      initialFraction: initialFraction,
      minFirst: minFirst,
      minSecond: minSecond,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      dividerThickness: theme.borderWidth,
      hitExtent: 16,
      dividerBuilder: (context, states, axis) {
        final active =
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused);
        final along = axis == Axis.horizontal;
        final layered = DesignStyleOf(layers, states);
        final rule = layered.side?.color ?? layered.edge ?? c.ink;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: ColoredBox(color: rule)),
            OverflowBox(
              maxWidth: along ? 12 : 32,
              maxHeight: along ? 32 : 12,
              child: SizedBox(
                width: along ? 12 : 32,
                height: along ? 32 : 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: layered.fill ?? (active ? c.signal : c.surface),
                    border: Border.all(color: rule, width: theme.borderWidth),
                  ),
                ),
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
      ..add(DiagnosticsProperty<Axis>('axis', axis))
      ..add(DoubleProperty('initialFraction', initialFraction))
      ..add(DoubleProperty('minFirst', minFirst))
      ..add(DoubleProperty('minSecond', minSecond))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged),
      )
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// Slides in a ruled frame, turned by a swipe, the arrow keys or the two
/// square cells under it, with the place shown as page dots between them.
///
/// Reads [style]'s `fill` (the frame and the cells at rest), `edge`,
/// `foreground` (the cells' arrows at rest) and `iconSize`, then
/// [BrutalThemeData.carouselStyle]'s. A pressed cell stays ink.
///
/// ```dart
/// BrutalCarousel(itemCount: 3, itemBuilder: (context, i) => slides[i])
/// ```
class BrutalCarousel extends StatelessWidget {
  /// A carousel of [itemCount] slides.
  const BrutalCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 16 / 9,
    this.semanticLabel,
    this.onPageChanged,
    this.style,
  });

  /// How many slides.
  final int itemCount;

  /// Builds a slide.
  final IndexedWidgetBuilder itemBuilder;

  /// The frame's width over its height.
  final double aspectRatio;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Called with the slide it turns to.
  final ValueChanged<int>? onPageChanged;

  /// Its style, over [BrutalThemeData.carouselStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.carouselStyle];
    final frame = DesignStyleOf(layers, const {});
    final rule = frame.side?.color ?? frame.edge ?? c.ink;
    Widget turn(IconData icon, String label, VoidCallback? onPressed) =>
        DesignPressable(
          onPressed: onPressed,
          semanticLabel: label,
          builder: (context, states, _) {
            final disabled = onPressed == null;
            final lit = states.contains(WidgetState.pressed);
            final layered = DesignStyleOf(layers, states);
            final ink = disabled
                ? c.inkMuted
                : lit
                ? c.paper
                : layered.foreground ?? c.ink;
            return SizedBox.square(
              dimension: 44,
              child: AnimatedBrutalSurface(
                face: BrutalFace(
                  fill: lit ? c.ink : layered.fill ?? c.surface,
                  border: disabled
                      ? c.disabled
                      : layered.side?.color ?? layered.edge ?? c.ink,
                  foreground: ink,
                  focus: states.contains(WidgetState.focused)
                      ? c.ink
                      : c.ink.withValues(alpha: 0),
                ),
                child: Icon(icon, size: layered.iconSize ?? 20, color: ink),
              ),
            );
          },
        );
    return DesignCarousel(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      semanticLabel: semanticLabel,
      onPageChanged: onPageChanged,
      layoutBuilder: (context, viewport, controls) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: BrutalSurface(
              face: BrutalFace(
                fill: frame.fill ?? c.surface,
                border: rule,
                foreground: c.ink,
                focus: controls.focused ? c.ink : c.ink.withValues(alpha: 0),
              ),
              child: ClipRect(child: viewport),
            ),
          ),
          const SizedBox(height: BrutalSpacing.medium),
          Row(
            children: [
              turn(LucideIcons.arrowLeft, 'Previous slide', controls.previous),
              Expanded(
                child: Center(
                  child: BrutalPageDots(
                    count: controls.count,
                    index: controls.page,
                    onChanged: controls.goToPage,
                  ),
                ),
              ),
              turn(LucideIcons.arrowRight, 'Next slide', controls.next),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('itemCount', itemCount))
      ..add(
        ObjectFlagProperty<IndexedWidgetBuilder>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(DoubleProperty('aspectRatio', aspectRatio))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onPageChanged',
          onPageChanged,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A list put in order by dragging rows by their handles (a long press
/// anywhere on a row, too), or from the keyboard: on a handle, Alt with
/// Up or Down moves its row, and a screen reader offers the moves as
/// actions. Rows stand on rules; the row in flight is lifted on its shadow.
///
/// Reads [style]'s `fill` (the box and the row in flight), `edge` (the
/// frame and the rules), `foreground` (the rows' words), `minimumSize` (a
/// row's least height), `textStyle` and `iconSize` (the grips), then
/// [BrutalThemeData.reorderableListStyle]'s.
///
/// ```dart
/// BrutalReorderableList<String>(items: acts, labelOf: (a) => a, onReorder: (from, to) => setState(() => acts.insert(to, acts.removeAt(from))), itemBuilder: (context, a) => Text(a))
/// ```
class BrutalReorderableList<T extends Object> extends StatelessWidget {
  /// A list of [items] put in order by [onReorder].
  const BrutalReorderableList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.labelOf,
    this.shrinkWrap = true,
    this.style,
  });

  /// The rows, in order.
  final List<T> items;

  /// Moves the row at `from` to `to` (an index in the list without it).
  final void Function(int from, int to) onReorder;

  /// What a row shows, beside its handle.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// What a screen reader calls a row.
  final String Function(T item) labelOf;

  /// Whether the list is as tall as its rows (in a page that scrolls).
  final bool shrinkWrap;

  /// Its style, over [BrutalThemeData.reorderableListStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([
      style,
      theme.reorderableListStyle,
    ], const {});
    final fill = layered.fill ?? c.surface;
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    final words = layered.foreground ?? c.ink;
    final rowHeight = layered.minimumSize?.height ?? theme.controlHeight + 8;
    return BrutalSurface(
      face: BrutalFace(fill: fill, border: rule, foreground: words),
      child: DesignReorderableList<T>(
        items: items,
        onReorder: onReorder,
        labelOf: labelOf,
        shrinkWrap: shrinkWrap,
        proxyDecorator: (child, index, animation) => AnimatedBuilder(
          animation: animation,
          // Lifted against its shadow: up, and back from the end side.
          builder: (context, _) => Transform.translate(
            offset:
                -theme.shadowIn(Directionality.of(context)) * animation.value,
            child: BrutalSurface(
              face: BrutalFace(
                fill: fill,
                border: rule,
                foreground: words,
                shadow: c.ink,
              ),
              child: child,
            ),
          ),
        ),
        itemBuilder: (context, item, reorder) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reorder.index > 0) BrutalRule(color: rule),
            DefaultTextStyle.merge(
              style: layered.text(theme.textTheme.body).copyWith(color: words),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: rowHeight),
                child: Row(
                  children: [
                    reorder.handle(
                      SizedBox(
                        width: 48,
                        height: rowHeight,
                        child: Icon(
                          LucideIcons.gripVertical,
                          size: layered.iconSize ?? 20,
                          color: c.inkMuted,
                        ),
                      ),
                    ),
                    Expanded(child: itemBuilder(context, item)),
                    const SizedBox(width: BrutalSpacing.regular),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('items', items))
      ..add(
        ObjectFlagProperty<void Function(int from, int to)>.has(
          'onReorder',
          onReorder,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext context, T item)>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(ObjectFlagProperty<String Function(T item)>.has('labelOf', labelOf))
      ..add(FlagProperty('shrinkWrap', value: shrinkWrap, ifTrue: 'shrinkWrap'))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// An action behind a [BrutalSwipeRow].
@immutable
class BrutalSwipeAction {
  /// An action reading [label].
  const BrutalSwipeAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  /// What it says.
  final String label;

  /// What it does; the row closes after.
  final VoidCallback onPressed;

  /// An icon over the label.
  final IconData? icon;

  /// Whether it destroys: drawn in the danger colour.
  final bool destructive;
}

/// [child] with actions behind its edges, shown by a swipe: square ink
/// cells on rules ([BrutalSwipeAction.destructive] ones in the danger
/// colour). A long swipe runs the first; the actions are also a screen
/// reader's custom actions.
///
/// Reads [style]'s `fill` (a plain action's cell; a destructive one stays
/// in the danger colour), `foreground` (its words), `edge`, `textStyle`
/// and `iconSize`, then [BrutalThemeData.swipeRowStyle]'s.
///
/// ```dart
/// BrutalSwipeRow(endActions: [BrutalSwipeAction(label: 'Delete', destructive: true, onPressed: delete)], child: BrutalListTile(title: 'Low Tide'))
/// ```
class BrutalSwipeRow extends StatelessWidget {
  /// A row over its actions.
  const BrutalSwipeRow({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
    this.style,
  });

  /// The row.
  final Widget child;

  /// Behind the start edge, shown by a swipe toward the end.
  final List<BrutalSwipeAction> startActions;

  /// Behind the end edge, shown by a swipe toward the start.
  final List<BrutalSwipeAction> endActions;

  /// Its style, over [BrutalThemeData.swipeRowStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.swipeRowStyle];
    DesignSwipeAction wrap(BrutalSwipeAction a) => DesignSwipeAction(
      label: a.label,
      onPressed: a.onPressed,
      destructive: a.destructive,
      data: a,
    );
    // The row's box holds the moving row: dragged, it slides under its own
    // edge, never past it.
    return ClipRect(
      child: DesignSwipeActions(
        startActions: [for (final a in startActions) wrap(a)],
        endActions: [for (final a in endActions) wrap(a)],
        actionExtent: 88,
        actionBuilder: (context, action, details) {
          final a = action.data! as BrutalSwipeAction;
          final pressed = details.states.contains(WidgetState.pressed);
          final layered = DesignStyleOf(layers, details.states);
          final fill = action.destructive ? c.danger : layered.fill ?? c.ink;
          final words = action.destructive
              ? c.onDanger
              : layered.foreground ?? c.onColor(fill);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: pressed ? c.paper : fill,
              border: BorderDirectional(
                start: BorderSide(
                  color: layered.side?.color ?? layered.edge ?? c.ink,
                  width: theme.borderWidth,
                ),
              ),
            ),
            child: CustomPaint(
              foregroundPainter: details.states.contains(WidgetState.focused)
                  ? BrutalInsetFocusPainter(pressed ? c.ink : words)
                  : null,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (a.icon != null)
                      Icon(
                        a.icon,
                        size: layered.iconSize ?? 20,
                        color: pressed ? c.ink : words,
                      ),
                    Text(
                      a.label.toUpperCase(),
                      maxLines: 1,
                      style: layered
                          .text(theme.textTheme.caption)
                          .copyWith(
                            color: pressed ? c.ink : words,
                            decoration: details.armed
                                ? TextDecoration.underline
                                : null,
                            decorationThickness: 2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: ColoredBox(color: c.surface, child: child),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalSwipeAction>('startActions', startActions))
      ..add(IterableProperty<BrutalSwipeAction>('endActions', endActions))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A scroll view refreshed by pulling it down past a mark: a ruled square
/// fills from the foot as it is pulled, turns to ink with an arrow once far
/// enough, spins while [onRefresh] runs and shows a tick when done.
///
/// Reads [style]'s `edge` (the square's rule) and `fill` (what fills it as
/// it is pulled), then [BrutalThemeData.pullToRefreshStyle]'s.
///
/// ```dart
/// BrutalPullToRefresh(onRefresh: reload, child: ListView(children: rows))
/// ```
class BrutalPullToRefresh extends StatelessWidget {
  /// [child] refreshed by [onRefresh].
  const BrutalPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.style,
  });

  /// Refreshes; the indicator spins until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  /// Its style, over [BrutalThemeData.pullToRefreshStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.pullToRefreshStyle], const {});
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      indicatorBuilder: (context, details) {
        final armed = details.mode == DesignRefreshMode.armed;
        final Widget mark = switch (details.mode) {
          DesignRefreshMode.refresh => const BrutalSpinner(size: 20),
          DesignRefreshMode.done => Icon(
            LucideIcons.check,
            size: 20,
            color: c.paper,
          ),
          _ => Icon(
            LucideIcons.arrowDown,
            size: 20,
            color: armed ? c.paper : c.ink,
          ),
        };
        final solid = armed || details.mode == DesignRefreshMode.done;
        return SizedBox(
          height: details.extent,
          child: ClipRect(
            child: Center(
              child: SizedBox.square(
                dimension: 40,
                child: BrutalSurface(
                  face: BrutalFace(
                    fill: solid ? c.ink : c.surface,
                    border: layered.side?.color ?? layered.edge ?? c.ink,
                    foreground: c.ink,
                    shadow: c.ink,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!solid && details.mode == DesignRefreshMode.drag)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: details.progress.clamp(0.0, 1.0),
                            widthFactor: 1,
                            child: ColoredBox(color: layered.fill ?? c.lime),
                          ),
                        ),
                      mark,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<Future<void> Function()>.has('onRefresh', onRefresh),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A [BrutalTree]'s nodes and which are open and selected. Make it in a
/// State, keep it across rebuilds and dispose it.
///
/// ```dart
/// final tree = BrutalTreeController<String>(roots: const ['Posters', 'Tickets'], childrenOf: (folder) => folders[folder] ?? const <String>[]);
/// ```
class BrutalTreeController<T extends Object> extends DesignTreeController<T> {
  /// A tree from [roots], each node's children from [childrenOf].
  BrutalTreeController({
    required super.roots,
    required super.childrenOf,
    super.expanded,
    super.multiSelectionEnabled,
  });
}

/// Nodes in rows, each child indented a step and hung from a rule; a
/// square cell opens a node with children (plus, or minus while open). The
/// selected row is ink. Up and Down move, Right and Left open and close,
/// Enter or Space selects.
///
/// Reads [style]'s `fill` (a row while selected or pressed), `foreground`
/// (a row's words at rest), `minimumSize` (a row's height), `textStyle` and
/// `iconSize` in its states, selected among them, then
/// [BrutalThemeData.treeStyle]'s.
///
/// ```dart
/// BrutalTree<String>(controller: tree, labelOf: (folder) => folder)
/// ```
class BrutalTree<T extends Object> extends StatelessWidget {
  /// A tree of [controller]'s nodes.
  const BrutalTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.iconOf,
    this.onActivate,
    this.semanticLabel,
    this.style,
  });

  /// The nodes, and which are open and selected.
  final BrutalTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's icon; null shows none.
  final IconData? Function(T node)? iconOf;

  /// Called when a node is chosen.
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.treeStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.treeStyle];
    return DesignTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: semanticLabel,
      rowBuilder: (context, item) {
        final states = item.states;
        final lit = item.selected || states.contains(WidgetState.pressed);
        final layered = DesignStyleOf(layers, {
          ...states,
          if (item.selected) WidgetState.selected,
        });
        final fill = lit ? layered.fill ?? c.ink : c.ink.withValues(alpha: 0);
        final ink = lit ? c.onColor(fill) : layered.foreground ?? c.ink;
        final icon = iconOf?.call(item.row.node);
        return ColoredBox(
          color: fill,
          child: CustomPaint(
            foregroundPainter: states.contains(WidgetState.focused)
                ? BrutalInsetFocusPainter(ink)
                : null,
            child: SizedBox(
              height: layered.minimumSize?.height ?? theme.controlHeight - 4,
              child: Row(
                children: [
                  for (var d = 0; d < item.row.depth; d++)
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: SizedBox(
                          width: theme.borderWidth,
                          height: double.infinity,
                          child: ColoredBox(color: lit ? ink : c.inkMuted),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 36,
                    child: item.hasChildren
                        ? MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: item.toggle,
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: _OpenCell(
                                  open: item.expanded,
                                  ink: ink,
                                  width: theme.borderWidth,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (icon != null) ...[
                    Icon(icon, size: layered.iconSize ?? 18, color: ink),
                    const SizedBox(width: BrutalSpacing.small),
                  ],
                  Expanded(
                    child: Text(
                      labelOf(item.row.node),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: layered
                          .text(theme.textTheme.body)
                          .copyWith(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalTreeController<T>>('controller', controller),
      )
      ..add(ObjectFlagProperty<String Function(T node)>.has('labelOf', labelOf))
      ..add(
        ObjectFlagProperty<IconData? Function(T node)>.has('iconOf', iconOf),
      )
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onActivate', onActivate))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _OpenCell extends StatelessWidget {
  const _OpenCell({required this.open, required this.ink, required this.width});

  final bool open;
  final Color ink;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 18,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: ink, width: width),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(width: 8, height: 2, child: ColoredBox(color: ink)),
          if (!open)
            SizedBox(width: 2, height: 8, child: ColoredBox(color: ink)),
        ],
      ),
    ),
  );
}
