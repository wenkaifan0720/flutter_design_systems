/// Studio's collections, each on ui_core's behaviour: [StudioDataTable]
/// (rows on glass that sort, select and page), [StudioScrollArea] (a slot
/// with a metal thumb riding it), [StudioSplitView] (two panes and a groove
/// with a grip between them), [StudioCarousel] (slides in a glass window),
/// [StudioReorderableList], [StudioSwipeRow], [StudioPullToRefresh] and
/// [StudioTree].
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'feedback.dart';
import 'surface.dart';
import 'theme.dart';
import 'wayfinding.dart';
import 'words.dart';

Color _ring(StudioColors c, Set<WidgetState> states) =>
    states.contains(WidgetState.focused)
    ? c.focusRing
    : c.focusRing.withValues(alpha: 0);

// The slot a lit row or a pressed one sits in, pressed into the glass.
StudioFace _slot(StudioColors c, {required bool shown, Color? focus}) =>
    StudioFace(
      fill: Color.lerp(c.displayLow, c.shadow, 0.06)!,
      fillLow: Color.lerp(c.display, c.shadow, 0.03)!,
      depth: StudioDepth.sunk,
      radius: StudioRadii.small,
      presence: shown ? 1 : 0,
      focus: focus ?? const Color(0x00000000),
    );

/// A column of a [StudioDataTable]: [flex] shares the width out.
class StudioDataColumn<R> extends DesignTableColumn<R> {
  /// A column [label]led, sortable by [sortKey].
  const StudioDataColumn({
    required super.id,
    required super.label,
    super.sortKey,
    super.numeric,
    this.flex = 1,
  });

  /// Its share of the width.
  final int flex;
}

/// Holds a [StudioDataTable]'s rows, sort, selection and page.
class StudioTableController<R> extends DesignTableController<R> {
  /// A controller over [rows] in [columns].
  StudioTableController({
    required super.rows,
    required List<StudioDataColumn<R>> super.columns,
    super.rowKey,
    super.pageSize,
    super.filter,
  });
}

/// A data table on a glass panel: the columns' names printed small along
/// the top (a press sorts by one, an arrow says which way), the rows under
/// them parted by fine lines. A chosen row's lamp is lit in the first
/// column; the header's lamp chooses the page. With a page size, the page
/// readout stands under it.
///
/// Built on ui_core's DesignDataTable: the arrows walk the rows, Space
/// chooses one, Enter opens it ([onActivate]).
///
/// Reads [style]'s `fill` (the glass) and `padding` (a cell's), then
/// [StudioThemeData.dataTableStyle].
///
/// ```dart
/// StudioDataTable<Map<String, String>>(controller: table, cell: (row, id) => row[id] ?? '')
/// ```
class StudioDataTable<R> extends StatelessWidget {
  /// A table over [controller]'s rows.
  const StudioDataTable({
    super.key,
    required this.controller,
    required this.cell,
    this.selectable = true,
    this.onActivate,
    this.emptyText = 'Nothing to show',
    this.style,
  });

  /// The rows, columns, sort, selection and page.
  final StudioTableController<R> controller;

  /// A cell's words: `row`'s value in the column `columnId`.
  final String Function(R row, String columnId) cell;

  /// Whether rows can be chosen.
  final bool selectable;

  /// Opens a row (Enter, a double press).
  final ValueChanged<R>? onActivate;

  /// What it says with no rows.
  final String emptyText;

  /// Its style, over [StudioThemeData.dataTableStyle].
  final StudioStyle? style;

  static const double _box = 44;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final layers = [style, theme.dataTableStyle];
    final frame = DesignStyleOf(layers, const {});
    StudioDataColumn<R> col(DesignTableColumn<R> column) =>
        column as StudioDataColumn<R>;
    final pad =
        frame.padding(Directionality.of(context)) ??
        const EdgeInsets.symmetric(
          horizontal: StudioSpacing.medium,
          vertical: StudioSpacing.medium,
        );
    Widget line() => Container(height: 1, color: c.displayLine);
    Widget lamp(bool on, {bool some = false}) => SizedBox(
      width: _box,
      child: Center(
        child: some
            ? Container(width: 8, height: 2, color: c.indicator)
            : StudioLamp(on: on, size: 8),
      ),
    );
    final table = DesignDataTable<R>(
      controller: controller,
      selectable: selectable,
      onActivate: onActivate,
      headerBuilder: (context, column, sort, states) => AnimatedStudioSurface(
        stiffness: StudioMotion.lampStiffness,
        face: _slot(
          c,
          shown: states.contains(WidgetState.pressed),
          focus: _ring(c, states),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _box),
          child: Padding(
            padding: pad,
            child: Row(
              mainAxisAlignment: column.numeric
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                // A head wider than its column is set smaller, never cut.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: StudioLegend(
                      column.label,
                      color: sort == null ? c.onDisplayMuted : c.onDisplay,
                    ),
                  ),
                ),
                if (column.sortable) ...[
                  const SizedBox(width: StudioSpacing.tight),
                  Icon(
                    switch (sort) {
                      DesignSortDirection.ascending => LucideIcons.arrowUp,
                      DesignSortDirection.descending => LucideIcons.arrowDown,
                      null => LucideIcons.arrowUpDown,
                    },
                    size: StudioIconSizes.small,
                    color: sort == null ? c.onDisplayMuted : c.litLegend,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      headerRowBuilder: (context, cells) {
        final page = controller.pageSelection;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectable)
                DesignPressable(
                  onPressed: controller.pageRows.isEmpty
                      ? null
                      : controller.togglePage,
                  semanticLabel: 'Choose the page',
                  checked: page == DesignSelection.all,
                  mixed: page == DesignSelection.some,
                  builder: (context, states, _) => AnimatedStudioSurface(
                    face: _slot(c, shown: false, focus: _ring(c, states)),
                    child: lamp(
                      page == DesignSelection.all,
                      some: page == DesignSelection.some,
                    ),
                  ),
                ),
              for (final (i, cellWidget) in cells.indexed)
                Expanded(
                  flex: col(controller.columns[i]).flex,
                  child: cellWidget,
                ),
            ],
          ),
        );
      },
      cellBuilder: (context, row, column) {
        final text = Text(
          cell(row, column.id),
          textAlign: column.numeric ? TextAlign.end : TextAlign.start,
          maxLines: column.numeric ? 1 : null,
          softWrap: !column.numeric,
          style: frame
              .text(t.body)
              .copyWith(
                fontFeatures: column.numeric
                    ? const [FontFeature.tabularFigures()]
                    : null,
              ),
        );
        // A figure is one line: in a narrow column it is set smaller,
        // never broken.
        return Padding(
          padding: pad,
          child: column.numeric
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: text,
                )
              : text,
        );
      },
      rowBuilder: (context, row, cells) {
        final layered = DesignStyleOf(layers, {
          ...row.states,
          if (row.selected) WidgetState.selected,
        });
        final ink = layered.foreground ?? c.onDisplay;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line(),
            AnimatedStudioSurface(
              stiffness: StudioMotion.lampStiffness,
              face: _slot(
                c,
                shown:
                    row.selected ||
                    row.states.contains(WidgetState.pressed) ||
                    row.states.contains(WidgetState.hovered),
                focus: _ring(c, row.states),
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: ink,
                  fontWeight: row.selected ? FontWeight.w600 : null,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (selectable)
                        ExcludeSemantics(child: lamp(row.selected)),
                      for (final (i, cellWidget) in cells.indexed)
                        Expanded(
                          flex: col(controller.columns[i]).flex,
                          // Figures stand at the column's end, words at its
                          // start.
                          child: Align(
                            alignment: col(controller.columns[i]).numeric
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            widthFactor: 1,
                            child: cellWidget,
                          ),
                        ),
                    ],
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
          StudioSurface(
            face: c.displayFace.copyWith(
              radius: StudioRadii.display,
              fill: frame.fill,
            ),
            child: Padding(
              padding: const EdgeInsets.all(StudioMetrics.recessInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: t.body.copyWith(color: c.onDisplay),
                    child: table,
                  ),
                  if (controller.pageRows.isEmpty) ...[
                    line(),
                    Padding(
                      padding: const EdgeInsets.all(StudioSpacing.regular),
                      child: Text(
                        emptyText,
                        style: t.secondary.copyWith(color: c.onDisplayMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (controller.pageSize != null && controller.pageCount > 1) ...[
            const SizedBox(height: StudioSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: Text(
                    // Counts are plurals in the app's language.
                    selectable && controller.selectedCount > 0
                        ? DesignLocalizations.of(context)
                              .selectedRowCountTitle(controller.selectedCount)
                        : StudioLocalizations.of(context)
                              .rowCount(controller.filteredRows.length),
                    style: t.secondary.copyWith(color: c.legendMuted),
                  ),
                ),
                StudioPagination(
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

/// A scrolling pane with its own scrollbar: a fine slot along its edge and
/// a small brushed cap riding it, standing whenever there is more to
/// scroll. Drag the cap, press the slot to page; with the keyboard, the
/// arrows and Page keys scroll it.
///
/// Built on ui_core's DesignScrollArea. [child] must scroll on
/// [controller].
///
/// ```dart
/// StudioScrollArea(controller: scroll, child: ListView(controller: scroll, children: rows))
/// ```
class StudioScrollArea extends StatelessWidget {
  /// A pane scrolling [child] on [controller].
  const StudioScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
  });

  /// The scroll it shows.
  final ScrollController controller;

  /// What scrolls.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// What a screen reader calls the pane.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      semanticLabel: semanticLabel,
      thickness: 12,
      // A slot and its cap stand whenever there is more to scroll: gear
      // does not hide its controls.
      visibility: DesignScrollbarVisibility.always,
      trackBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Center(
          child: Container(
            width: thumb.axis == Axis.vertical ? 4 : null,
            height: thumb.axis == Axis.vertical ? null : 4,
            decoration: BoxDecoration(
              color: c.slot,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final held = thumb.states.contains(WidgetState.pressed);
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.hair),
            child: StudioSurface(
              face: StudioFace(
                fill: c.cap,
                fillLow: c.capLow,
                depth: StudioDepth.raised,
                radius: 4,
                travel: held ? 0.5 : 0,
                brushed: true,
              ),
            ),
          ),
        );
      },
      // The frame is only its focus ring: the area lies on the glass it
      // scrolls in, and a face of its own would shade it.
      frameBuilder: (context, focused, area) => AnimatedStudioSurface(
        face: StudioFace(
          fill: const Color(0x00000000),
          fillLow: const Color(0x00000000),
          depth: StudioDepth.level,
          presence: 0,
          radius: StudioRadii.small,
          focus: focused ? c.focusRing : c.focusRing.withValues(alpha: 0),
        ),
        child: area,
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('axis', axis));
  }
}

/// Two panes and a groove between them with a small brushed grip: drag
/// the grip to share the room out; with the keyboard, the arrows move it.
///
/// Built on ui_core's DesignSplitView.
///
/// ```dart
/// StudioSplitView(first: episodes, second: notes, initialFraction: 0.4)
/// ```
class StudioSplitView extends StatelessWidget {
  /// [first] and [second], side by side (or stacked, [axis] vertical).
  const StudioSplitView({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = 0.5,
    this.minFirst = 160,
    this.minSecond = 160,
    this.onChanged,
    this.semanticLabel = 'Resize the panes',
  });

  /// The start (or top) pane.
  final Widget first;

  /// The end (or bottom) pane.
  final Widget second;

  /// Side by side, or stacked.
  final Axis axis;

  /// The first pane's share at the start.
  final double initialFraction;

  /// The first pane's least extent.
  final double minFirst;

  /// The second pane's least extent.
  final double minSecond;

  /// Called with the first pane's share as it moves.
  final ValueChanged<double>? onChanged;

  /// What a screen reader calls the grip.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      initialFraction: initialFraction,
      minFirst: minFirst,
      minSecond: minSecond,
      onChanged: onChanged,
      semanticLabel: semanticLabel,
      dividerThickness: 3,
      hitExtent: 16,
      dividerBuilder: (context, states, axis) {
        final along = axis == Axis.horizontal;
        final held = states.contains(WidgetState.pressed);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // The groove: a dark line with a lit edge beside it.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: along
                      ? Border(
                          left: BorderSide(color: c.groove, width: 2),
                          right: BorderSide(color: c.edgeLight),
                        )
                      : Border(
                          top: BorderSide(color: c.groove, width: 2),
                          bottom: BorderSide(color: c.edgeLight),
                        ),
                ),
              ),
            ),
            OverflowBox(
              maxWidth: along ? 12 : 36,
              maxHeight: along ? 36 : 12,
              child: SizedBox(
                width: along ? 12 : 36,
                height: along ? 36 : 12,
                child: AnimatedStudioSurface(
                  face: StudioFace(
                    fill: c.cap,
                    fillLow: c.capLow,
                    depth: StudioDepth.raised,
                    radius: StudioRadii.cap,
                    travel: held ? 0.5 : 0,
                    brushed: true,
                    focus: _ring(c, states),
                  ),
                  child: Center(
                    child: Container(
                      width: along ? 2 : 16,
                      height: along ? 16 : 2,
                      color: held ? c.indicator : c.legendMuted,
                    ),
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
      ..add(EnumProperty<Axis>('axis', axis))
      ..add(DoubleProperty('initialFraction', initialFraction));
  }
}

/// Slides in a glass window, one at a time: a key back, the page lamps, a
/// key on under it. Swipe or press to turn; with the keyboard, the arrows.
///
/// Built on ui_core's DesignCarousel.
///
/// ```dart
/// StudioCarousel(itemCount: covers.length, itemBuilder: (context, i) => covers[i], semanticLabel: 'Featured shows')
/// ```
class StudioCarousel extends StatelessWidget {
  /// A carousel of [itemCount] slides.
  const StudioCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 16 / 9,
    this.semanticLabel,
    this.onPageChanged,
  });

  /// How many slides.
  final int itemCount;

  /// Builds slide `i`.
  final IndexedWidgetBuilder itemBuilder;

  /// The window's shape.
  final double aspectRatio;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Called as a slide comes round.
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
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
            child: StudioSurface(
              face: c.displayFace.copyWith(
                radius: StudioRadii.display,
                focus: controls.focused
                    ? c.focusRing
                    : c.focusRing.withValues(alpha: 0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(StudioMetrics.recessInset),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    StudioRadii.display - StudioMetrics.recessInset,
                  ),
                  child: viewport,
                ),
              ),
            ),
          ),
          const SizedBox(height: StudioSpacing.medium),
          Row(
            children: [
              StudioIconButton(
                icon: Transform.flip(
                  flipX: rtl,
                  child: const Icon(LucideIcons.chevronLeft),
                ),
                tooltip: 'Previous slide',
                onPressed: controls.previous,
              ),
              Expanded(
                child: Center(
                  child: StudioPageDots(
                    count: controls.count,
                    index: controls.page,
                    onChanged: controls.goToPage,
                  ),
                ),
              ),
              StudioIconButton(
                icon: Transform.flip(
                  flipX: rtl,
                  child: const Icon(LucideIcons.chevronRight),
                ),
                tooltip: 'Next slide',
                onPressed: controls.next,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('itemCount', itemCount));
  }
}

// A knurled grip: three short grooves to take hold of.
class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: StudioMetrics.lip),
          Container(width: 16, height: 1.5, color: c.groove),
          Container(width: 16, height: 1, color: c.edgeLight),
        ],
      ],
    );
  }
}

/// A list you put in order: rows on glass, each with a knurled grip at its
/// start. Drag a grip (or long-press a row) and the row lifts with a
/// shadow under it; with the keyboard, the row's actions move it up or
/// down, and a screen reader hears where it went.
///
/// Built on ui_core's DesignReorderableList.
///
/// ```dart
/// StudioReorderableList<String>(items: queue, labelOf: (s) => s, onReorder: (from, to) => setState(() => queue.insert(to, queue.removeAt(from))), itemBuilder: (context, s) => Text(s))
/// ```
class StudioReorderableList<T extends Object> extends StatelessWidget {
  /// A list of [items].
  const StudioReorderableList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.labelOf,
    this.shrinkWrap = true,
  });

  /// The items, in order.
  final List<T> items;

  /// Moves the item at `from` to `to`.
  final void Function(int from, int to) onReorder;

  /// An item's row content.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// An item's words, for a screen reader.
  final String Function(T item) labelOf;

  /// Whether it takes only its rows' height.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final night = c.brightness == Brightness.dark;
    final rowHeight = theme.controlHeight + 8;
    return StudioSurface(
      face: c.displayFace.copyWith(radius: StudioRadii.display),
      child: Padding(
        padding: const EdgeInsets.all(StudioMetrics.recessInset),
        child: DesignReorderableList<T>(
          items: items,
          onReorder: onReorder,
          labelOf: labelOf,
          shrinkWrap: shrinkWrap,
          // The lifted row keeps the corners of the glass's inner wall, so
          // at either end of the list it follows the well.
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  StudioRadii.display - StudioMetrics.recessInset,
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow.withValues(
                      alpha: (night ? 0.6 : 0.25) * animation.value,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: StudioSurface(
                face: c.displayFace.copyWith(
                  radius: StudioRadii.display - StudioMetrics.recessInset,
                ),
                // The rule above the row stays in the list: across the
                // lifted glass it would run past its round corners.
                child: _Lifted(child: child),
              ),
            ),
          ),
          itemBuilder: (context, item, reorder) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reorder.index > 0) const _Rule(),
              DefaultTextStyle.merge(
                style: theme.textTheme.body.copyWith(color: c.onDisplay),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: rowHeight),
                  child: Row(
                    children: [
                      reorder.handle(
                        SizedBox(
                          width: 44,
                          height: rowHeight,
                          child: const Center(child: _Grip()),
                        ),
                      ),
                      Expanded(child: itemBuilder(context, item)),
                      const SizedBox(width: StudioSpacing.regular),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}

/// An action a [StudioSwipeRow] shows.
@immutable
class StudioSwipeAction {
  /// An action [label]led.
  const StudioSwipeAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  /// Its legend.
  final String label;

  /// What it does.
  final VoidCallback onPressed;

  /// Its glyph.
  final Widget? icon;

  /// Whether it destroys something: its legend and glyph in red.
  final bool destructive;
}

// A swipe action's key, across.
const double _swipeKeyExtent = 88;

// The row's corners: a display's glass less the recess it stands in, so the
// row is concentric with the well round it.
const double _swipeRadius = StudioRadii.display - StudioMetrics.recessInset;

/// A row that slides aside to show keys behind it: drag it toward its
/// start or end and [startActions] or [endActions] stand in the metal it
/// leaves; dragged far enough, the first action's lamp lights and letting
/// go does it. With the keyboard or a screen reader the actions are the
/// row's own.
///
/// It is a plate of glass with the corners of a display's inner wall: set it
/// in a [StudioDisplay] with [StudioMetrics.recessInset] round it, and its
/// corners follow the well's at rest and as it slides.
///
/// Built on ui_core's DesignSwipeActions.
///
/// ```dart
/// StudioSwipeRow(endActions: [StudioSwipeAction(label: 'Delete', icon: const Icon(LucideIcons.trash2), destructive: true, onPressed: delete)], child: row)
/// ```
class StudioSwipeRow extends StatelessWidget {
  /// [child] with actions behind it.
  const StudioSwipeRow({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
  });

  /// The row.
  final Widget child;

  /// What a drag toward the end shows, at the start.
  final List<StudioSwipeAction> startActions;

  /// What a drag toward the start shows, at the end.
  final List<StudioSwipeAction> endActions;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    DesignSwipeAction wrap(StudioSwipeAction a) => DesignSwipeAction(
      label: a.label,
      onPressed: a.onPressed,
      destructive: a.destructive,
      data: a,
    );
    const corners = BorderRadius.all(Radius.circular(_swipeRadius));
    // The metal it uncovers follows the well's inner wall; the plate keeps
    // its own round corners as it slides, the metal running on under them.
    return ClipRRect(
      borderRadius: corners,
      child: DesignSwipeActions(
        startActions: [for (final a in startActions) wrap(a)],
        endActions: [for (final a in endActions) wrap(a)],
        actionExtent: _swipeKeyExtent,
        underlap: _swipeRadius,
        actionBuilder: (context, action, details) {
          final a = action.data! as StudioSwipeAction;
          final pressed = details.states.contains(WidgetState.pressed);
          final ink = action.destructive ? c.dangerLegend : c.onKey;
          // The key stands whole in the metal, anchored at the row's outer
          // edge: the sliding row uncovers it, never squeezes it. The actions
          // are laid out from the row's edge on either side, so that edge is
          // their start.
          return ColoredBox(
            color: c.panelLow,
            child: ClipRect(
              child: OverflowBox(
                minWidth: _swipeKeyExtent,
                maxWidth: _swipeKeyExtent,
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.all(StudioSpacing.tight),
                  child: AnimatedStudioSurface(
                    face: c.keyFace.copyWith(
                      travel: pressed || details.armed ? 1 : 0,
                      foreground: ink,
                      focus: _ring(c, details.states),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (a.icon != null)
                            IconTheme.merge(
                              data: IconThemeData(
                                size: StudioIconSizes.regular,
                                color: ink,
                              ),
                              child: a.icon!,
                            ),
                          const SizedBox(height: StudioSpacing.tight),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StudioLamp(
                                on: details.armed,
                                size: 5,
                                color: action.destructive ? c.danger : null,
                              ),
                              const SizedBox(width: StudioSpacing.tight),
                              Text(
                                a.label,
                                maxLines: 1,
                                style: theme.textTheme.caption.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        // The row is glass: it slides whole over the metal it uncovers.
        child: ClipRRect(
          borderRadius: corners,
          child: ColoredBox(color: c.display, child: child),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('startActions', startActions.length))
      ..add(IntProperty('endActions', endActions.length));
  }
}

// The hairline between two rows of a reorderable list; a lifted row leaves
// it behind (its room stays, so the row keeps its height as it lifts).
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: context.dependOnInheritedWidgetOfExactType<_Lifted>() != null
        ? null
        : ColoredBox(color: StudioTheme.of(context).colors.displayLine),
  );
}

// Marks a reorderable list's row as lifted, riding in the overlay.
class _Lifted extends InheritedWidget {
  const _Lifted({required super.child});

  @override
  bool updateShouldNotify(_Lifted oldWidget) => false;
}

/// Pull down to refresh: as the list is pulled, a ring of lamps over it
/// lights one by one; at the top it is armed (all lit), let go and the
/// lamps chase round while [onRefresh] runs, then a lit check.
///
/// Built on ui_core's DesignPullToRefresh; a screen reader has its own
/// refresh action.
///
/// ```dart
/// StudioPullToRefresh(onRefresh: reload, child: ListView(children: rows))
/// ```
class StudioPullToRefresh extends StatelessWidget {
  /// [child], refreshed by [onRefresh].
  const StudioPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Fetches again; the lamps chase until it completes.
  final Future<void> Function() onRefresh;

  /// The scrolling list.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      indicatorBuilder: (context, details) {
        final Widget mark = switch (details.mode) {
          DesignRefreshMode.refresh => const StudioSpinner(size: 24),
          DesignRefreshMode.done => Icon(
            LucideIcons.check,
            size: StudioIconSizes.regular,
            color: c.indicator,
          ),
          _ => StudioLampRing(
            lit: details.mode == DesignRefreshMode.armed
                ? 1
                : details.progress.clamp(0.0, 1.0),
            size: 24,
          ),
        };
        return SizedBox(
          height: details.extent,
          child: ClipRect(
            child: Center(
              child: SizedBox.square(
                dimension: 40,
                child: StudioSurface(
                  face: c.readoutFace.copyWith(radius: 20),
                  child: Center(child: mark),
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

/// Holds a [StudioTree]'s nodes, which are open and which are chosen.
class StudioTreeController<T extends Object> extends DesignTreeController<T> {
  /// A controller over [roots].
  StudioTreeController({
    required super.roots,
    required super.childrenOf,
    super.expanded,
    super.multiSelectionEnabled,
  });
}

/// A tree: rows that open to show the rows under them, each level set in
/// by an engraved line; a small wedge opens and closes a row. The chosen
/// row sits in a slot with its lamp lit.
///
/// Built on ui_core's DesignTree: the arrows walk and open the rows, Enter
/// opens one ([onActivate]).
///
/// ```dart
/// StudioTree<String>(controller: folders, labelOf: (path) => path.split('/').last)
/// ```
class StudioTree<T extends Object> extends StatelessWidget {
  /// A tree over [controller]'s nodes.
  const StudioTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.iconOf,
    this.onActivate,
    this.semanticLabel,
  });

  /// The nodes, open and chosen.
  final StudioTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's glyph.
  final Widget? Function(T node)? iconOf;

  /// Opens a node.
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DesignTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: semanticLabel,
      rowBuilder: (context, item) {
        final states = item.states;
        final ink = item.selected ? c.legend : c.legend;
        final icon = iconOf?.call(item.row.node);
        return AnimatedStudioSurface(
          stiffness: StudioMotion.lampStiffness,
          face: c.recessFace.copyWith(
            radius: StudioRadii.small,
            presence:
                item.selected ||
                    states.contains(WidgetState.pressed) ||
                    states.contains(WidgetState.hovered)
                ? 1
                : 0,
            focus: _ring(c, states),
          ),
          // A row is a little under a key's height, never under a finger's
          // floor where a finger reaches it.
          child: SizedBox(
            height: math.max(
              theme.controlHeight - 4,
              DesignTapTargets.of(context).floorOn().height,
            ),
            child: Row(
              children: [
                for (var d = 0; d < item.row.depth; d++)
                  SizedBox(
                    width: 20,
                    child: Center(child: Container(width: 1, color: c.groove)),
                  ),
                SizedBox(
                  width: 32,
                  child: item.hasChildren
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: item.toggle,
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: AnimatedRotation(
                                turns: item.expanded ? 0.25 : 0,
                                duration:
                                    MediaQuery.maybeDisableAnimationsOf(
                                          context,
                                        ) ??
                                        false
                                    ? Duration.zero
                                    : const Duration(milliseconds: 140),
                                child: Transform.flip(
                                  flipX: rtl,
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    size: 16,
                                    color: c.legendMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                if (icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      size: StudioIconSizes.medium,
                      color: c.legendMuted,
                    ),
                    child: icon,
                  ),
                  const SizedBox(width: StudioSpacing.small),
                ],
                Expanded(
                  child: Text(
                    labelOf(item.row.node),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.body.copyWith(
                      color: ink,
                      fontWeight: item.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: StudioSpacing.medium,
                  ),
                  child: StudioLamp(on: item.selected, size: 6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
