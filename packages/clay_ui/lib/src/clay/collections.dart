/// Clay's collections: a data table on a clay card, a scroll area with a
/// clay thumb in a groove, a split view, a carousel in a well, a list
/// reordered by hand, a row with actions under it, pull to refresh and a
/// tree.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'choices.dart' show ClayCheckMark;
import 'feedback.dart' show ClaySpinner;
import 'fonts.dart';
import 'internal/menu.dart' show ClayChevronPainter;
import 'lists.dart' show ClayGroove;
import 'surface.dart';
import 'theme.dart';
import 'wayfinding.dart' show ClayPageDots, ClayPagination;

/// A row's face in a clay list: bare clay; a pale coral dent when chosen;
/// a faint dent under the pointer, a deeper one under a press; a rim under
/// focus.
ClayFace _rowFace(
  ClayColors c,
  Set<WidgetState> states, {
  required bool chosen,
  double radius = ClayRadius.control - 4,
  Color? fill,
}) {
  final pressed = states.contains(WidgetState.pressed);
  final hovered = states.contains(WidgetState.hovered);
  final well = ClayFace.well(
    c,
    color: chosen ? (fill ?? Color.lerp(c.well, c.accent, 0.2)) : null,
    radius: radius,
  );
  final show = chosen || pressed ? 1.0 : (hovered ? 0.45 : 0.0);
  return well.copyWith(
    color: well.color.withValues(alpha: well.color.a * show),
    lightOpacity: well.lightOpacity * show,
    shadeOpacity: well.shadeOpacity * show * (pressed ? 1.2 : 0.8),
    focus: states.contains(WidgetState.focused) ? 1 : 0,
    focusColor: c.focus,
  );
}

/// A column of a [ClayDataTable]: its share of the width in [flex].
class ClayDataColumn<R> extends DesignTableColumn<R> {
  /// A column [id] headed [label].
  const ClayDataColumn({
    required super.id,
    required super.label,
    super.sortKey,
    super.numeric,
    this.flex = 1,
  });

  /// Its share of the table's width.
  final int flex;
}

/// The rows, sort, filter, page and selection of a [ClayDataTable]; the
/// caller makes it and disposes it.
class ClayTableController<R> extends DesignTableController<R> {
  /// A controller over [rows] in [columns].
  ClayTableController({
    required super.rows,
    required List<ClayDataColumn<R>> super.columns,
    super.rowKey,
    super.pageSize,
    super.filter,
  });
}

/// A data table on a clay card: headings that sort on a tap (the sorted one
/// with its arrow), rows between soft grooves that dent under the pointer
/// and turn pale coral when chosen, and pages under it when there are many.
///
/// ```dart
/// ClayDataTable<({String name, int days})>(controller: controller, cell: (habit, column) => column == 'name' ? habit.name : '${habit.days} days')
/// ```
class ClayDataTable<R> extends StatelessWidget {
  /// A table over [controller]'s rows.
  const ClayDataTable({
    super.key,
    required this.controller,
    required this.cell,
    this.selectable = true,
    this.onActivate,
    this.emptyText,
    this.style,
  });

  /// The rows and their state.
  final ClayTableController<R> controller;

  /// A cell's words: the row and the column's id.
  final String Function(R row, String columnId) cell;

  /// Whether rows can be chosen.
  final bool selectable;

  /// A row opened (Enter, or a double tap).
  final ValueChanged<R>? onActivate;

  /// What it says when no row matches.
  final String? emptyText;

  /// This table's own style, over [ClayThemeData.dataTableStyle]: `fill`
  /// the card, a chosen row's dent under `selected`.
  final ClayStyle? style;

  static const double _box = 48;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final words = DesignLocalizations.of(context);
    final layers = [style, theme.dataTableStyle];
    final frame = DesignStyleOf(layers, const {});
    int flex(DesignTableColumn<R> col) => (col as ClayDataColumn<R>).flex;
    const pad = EdgeInsets.symmetric(
      horizontal: ClaySpacing.medium,
      vertical: ClaySpacing.medium,
    );
    Widget mark(bool? value) => IgnorePointer(
      child: SizedBox.square(
        dimension: 24,
        child: ClayCheckMark(value: value, states: const {}),
      ),
    );
    final table = DesignDataTable<R>(
      controller: controller,
      selectable: selectable,
      onActivate: onActivate,
      headerBuilder: (context, column, sort, states) => AnimatedClaySurface(
        face: _rowFace(c, states, chosen: false, radius: 10),
        // A heading sorts on a tap: a finger's height.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClaySpacing.medium,
              vertical: ClaySpacing.small,
            ),
            child: Row(
              mainAxisAlignment: column.numeric
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      color: sort == null ? c.inkSecondary : c.ink,
                      fontWeight: FontWeight.w600,
                      fontVariations: clayWeight(FontWeight.w600),
                    ),
                  ),
                ),
                // Only the column the rows are sorted by carries an arrow.
                if (column.sortable && sort != null) ...[
                  const SizedBox(width: ClaySpacing.tight),
                  Icon(
                    switch (sort) {
                      DesignSortDirection.ascending => LucideIcons.arrowUp,
                      DesignSortDirection.descending => LucideIcons.arrowDown,
                    },
                    size: 14,
                    color: c.accentInk,
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
                  semanticLabel: words.selectedLabel,
                  // A checkbox, not a button, as Flutter's Checkbox reads.
                  button: false,
                  checked: page == DesignSelection.all,
                  builder: (context, states, _) => AnimatedClaySurface(
                    face: _rowFace(c, states, chosen: false, radius: 10),
                    child: SizedBox(
                      width: _box,
                      child: Center(
                        child: mark(switch (page) {
                          DesignSelection.all => true,
                          DesignSelection.some => null,
                          DesignSelection.none => false,
                        }),
                      ),
                    ),
                  ),
                ),
              for (final (i, cellWidget) in cells.indexed)
                Expanded(flex: flex(controller.columns[i]), child: cellWidget),
            ],
          ),
        );
      },
      cellBuilder: (context, row, column) => Padding(
        padding: pad,
        child: Text(
          cell(row, column.id),
          textAlign: column.numeric ? TextAlign.end : TextAlign.start,
          style: t.body
              .copyWith(
                color: c.ink,
                fontFeatures: column.numeric
                    ? const [FontFeature.tabularFigures()]
                    : null,
              )
              .merge(frame.textStyle),
        ),
      ),
      rowBuilder: (context, row, cells) {
        final layered = DesignStyleOf(layers, {
          ...row.states,
          if (row.selected) WidgetState.selected,
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ClayGroove(
              indent: ClaySpacing.small,
              endIndent: ClaySpacing.small,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClaySpacing.tight,
                vertical: 2,
              ),
              child: AnimatedClaySurface(
                face: _rowFace(
                  c,
                  row.states,
                  chosen: row.selected,
                  radius: 12,
                  fill: row.selected ? layered.fill : null,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (selectable)
                        ExcludeSemantics(
                          child: SizedBox(
                            width: _box - 4,
                            child: Center(child: mark(row.selected)),
                          ),
                        ),
                      for (final (i, cellWidget) in cells.indexed)
                        Expanded(
                          flex: flex(controller.columns[i]),
                          // A number stands at its column's end, under its
                          // heading; words at the start.
                          child: Align(
                            alignment: controller.columns[i].numeric
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
          ClaySurface(
            face: ClayFace.raised(
              c,
              color: frame.fill,
              radius: clayRadiusOf(frame.shape, ClayRadius.large),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: ClaySpacing.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  table,
                  if (controller.pageRows.isEmpty) ...[
                    const ClayGroove(
                      indent: ClaySpacing.small,
                      endIndent: ClaySpacing.small,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(ClaySpacing.regular),
                      child: Text(
                        emptyText ?? words.noResultsLabel,
                        style: t.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (controller.pageSize != null && controller.pageCount > 1) ...[
            const SizedBox(height: ClaySpacing.medium),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: ClaySpacing.medium,
              runSpacing: ClaySpacing.small,
              children: [
                Text(
                  selectable && controller.selectedCount > 0
                      ? words.selectedRowCountTitle(controller.selectedCount)
                      : words.positionLabel(
                          controller.page + 1,
                          controller.pageCount,
                        ),
                  style: t.secondary,
                ),
                ClayPagination(
                  page: controller.page + 1,
                  count: controller.pageCount,
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

/// A scroll area: its own scroll bar, a white clay pill riding a soft
/// groove, shown while it scrolls or the pointer is near; it takes the keys
/// (arrows, Page Up and Down) once focused, rimmed then.
///
/// ```dart
/// ClayScrollArea(controller: controller, child: ListView(controller: controller, children: const [Text('Notes')]))
/// ```
class ClayScrollArea extends StatelessWidget {
  /// A scroll area over [child], driven by [controller].
  const ClayScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
    this.style,
  });

  /// The scroll it follows; [child]'s scroll view must take it too.
  final ScrollController controller;

  /// The scrolling content.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This area's own style, over [ClayThemeData.scrollAreaStyle]: `fill`
  /// the thumb.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.scrollAreaStyle];
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      semanticLabel: semanticLabel,
      thickness: 12,
      trackBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Padding(
          padding: const EdgeInsets.all(ClaySpacing.hairline),
          child: ClaySurface(
            face: ClayFace.well(
              c,
              color: Color.lerp(c.well, c.track, 0.25),
              radius: 4,
            ),
          ),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final held = thumb.states.contains(WidgetState.pressed);
        final fill = DesignStyleOf(layers, thumb.states).fill;
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.all(ClaySpacing.hairline),
            child: AnimatedClaySurface(
              face: ClayFace.raised(
                c,
                color: fill,
                radius: 4,
              ).copyWith(elevation: 0.5, press: held ? 1 : 0),
            ),
          ),
        );
      },
      frameBuilder: (context, focused, area) => AnimatedClaySurface(
        face: ClayFace.flat(c, radius: 12).copyWith(
          color: c.ground.withValues(alpha: 0),
          shadowOpacity: 0,
          lightOpacity: 0,
          shadeOpacity: 0,
          focus: focused ? 1 : 0,
          focusColor: c.focus,
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

/// Two panes and a groove between them that a drag, or the arrows once
/// focused, moves; a small clay grip rises on the groove under the pointer,
/// the keys or a finger.
///
/// ```dart
/// ClaySplitView(first: const Text('Habits'), second: const Text('Drink water'))
/// ```
class ClaySplitView extends StatelessWidget {
  /// [first] and [second] side by side (or one over the other).
  const ClaySplitView({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = 0.5,
    this.minFirst = 120,
    this.minSecond = 120,
    this.onChanged,
    this.semanticLabel,
    this.style,
  });

  /// The start (or top) pane.
  final Widget first;

  /// The end (or bottom) pane.
  final Widget second;

  /// Which way the panes lie.
  final Axis axis;

  /// The first pane's share at first.
  final double initialFraction;

  /// The first pane's least extent.
  final double minFirst;

  /// The second pane's least extent.
  final double minSecond;

  /// The first pane's share as it moves.
  final ValueChanged<double>? onChanged;

  /// What a screen reader calls the groove.
  final String? semanticLabel;

  /// This view's own style, over [ClayThemeData.splitViewStyle]: `fill` the
  /// grip.
  final ClayStyle? style;

  static const double _line = 2;
  static const double _reach = 16;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.splitViewStyle];
    // Nothing a tap reaches sits under the groove's reach.
    const clear = (_reach - _line) / 2;
    final across = axis == Axis.horizontal;
    return DesignSplitView(
      first: Padding(
        padding: across
            ? const EdgeInsetsDirectional.only(end: clear)
            : const EdgeInsets.only(bottom: clear),
        child: first,
      ),
      second: Padding(
        padding: across
            ? const EdgeInsetsDirectional.only(start: clear)
            : const EdgeInsets.only(top: clear),
        child: second,
      ),
      axis: axis,
      initialFraction: initialFraction,
      minFirst: minFirst,
      minSecond: minSecond,
      onChanged: onChanged,
      semanticLabel:
          semanticLabel ?? DesignLocalizations.of(context).splitViewHandleLabel,
      dividerThickness: _line,
      hitExtent: _reach,
      dividerBuilder: (context, states, axis) {
        final along = axis == Axis.horizontal;
        final layered = DesignStyleOf(layers, states);
        final held = states.contains(WidgetState.pressed);
        final touch = DesignTapTargets.of(context).floorOn().height >= 44;
        final shown =
            touch ||
            held ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(c.well, c.track, 0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            OverflowBox(
              maxWidth: along ? 12 : 44,
              maxHeight: along ? 44 : 12,
              child: AnimatedOpacity(
                opacity: shown ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: SizedBox(
                  width: along ? 12 : 44,
                  height: along ? 44 : 12,
                  child: AnimatedClaySurface(
                    face: ClayFace.raised(c, color: layered.fill, radius: 6)
                        .copyWith(
                          elevation: 0.6,
                          press: held ? 1 : 0,
                          focus: states.contains(WidgetState.focused) ? 1 : 0,
                          focusColor: c.focus,
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

/// A carousel: slides set in a well, turned by a swipe, the arrows beside
/// the dots under it, or the keys once focused. A slide lies in the well
/// (a picture, a tinted panel casting no shadow): the well's edge would
/// cut the shadow of anything that fills it.
///
/// ```dart
/// ClayCarousel(itemCount: 3, itemBuilder: (context, i) => Center(child: Text('Tip ${i + 1}')))
/// ```
class ClayCarousel extends StatelessWidget {
  /// A carousel of [itemCount] slides.
  const ClayCarousel({
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

  /// The well's shape.
  final double aspectRatio;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// A slide turned to.
  final ValueChanged<int>? onPageChanged;

  /// This carousel's own style, over [ClayThemeData.carouselStyle]: `fill`
  /// the well its slides sit in, `shape` its corners.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layered = DesignStyleOf([style, theme.carouselStyle], const {});
    final radius = clayRadiusOf(layered.shape, ClayRadius.large);
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
            child: AnimatedClaySurface(
              face: ClayFace.well(
                c,
                color: layered.fill,
                radius: radius,
              ).copyWith(focus: controls.focused ? 1 : 0, focusColor: c.focus),
              child: Padding(
                padding: const EdgeInsets.all(ClaySpacing.tight),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(math.max(0, radius - 4)),
                  child: viewport,
                ),
              ),
            ),
          ),
          const SizedBox(height: ClaySpacing.medium),
          Row(
            children: [
              ClayIconButton(
                onPressed: controls.previous,
                tooltip: words.previousPageTooltip,
                icon: Icon(
                  rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                ),
              ),
              Expanded(
                child: Center(
                  child: ClayPageDots(
                    count: controls.count,
                    index: controls.page,
                    onChanged: controls.goToPage,
                  ),
                ),
              ),
              ClayIconButton(
                onPressed: controls.next,
                tooltip: words.nextPageTooltip,
                icon: Icon(
                  rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                ),
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
    properties
      ..add(IntProperty('itemCount', itemCount))
      ..add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

/// A list put in order by hand: rows on a clay card, each with a grip at
/// its start; a drag lifts a row off the card and sets it down elsewhere,
/// and the keys move it up or down (said as it moves).
///
/// ```dart
/// ClayReorderableList<String>(items: const ['Walk', 'Read'], onReorder: (from, to) {}, labelOf: (s) => s, itemBuilder: (context, s) => Text(s))
/// ```
class ClayReorderableList<T extends Object> extends StatelessWidget {
  /// A list of [items] put in order by hand.
  const ClayReorderableList({
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

  /// A row moved: its index `from`, and the index it now stands before,
  /// `to`.
  final void Function(int from, int to) onReorder;

  /// A row's content, after its grip.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// What a screen reader calls a row.
  final String Function(T item) labelOf;

  /// Whether it sizes to its rows (inside another scroll).
  final bool shrinkWrap;

  /// This list's own style, over [ClayThemeData.reorderableListStyle]:
  /// `fill` the slab, `foreground` the words, `shape` its corners.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final rowHeight = theme.controlHeight + 8;
    final layered = DesignStyleOf([
      style,
      theme.reorderableListStyle,
    ], const {});
    final radius = clayRadiusOf(layered.shape, ClayRadius.large);
    return ClaySurface(
      face: ClayFace.raised(c, color: layered.fill, radius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DesignReorderableList<T>(
          items: items,
          onReorder: onReorder,
          labelOf: labelOf,
          shrinkWrap: shrinkWrap,
          // The row a drag holds lifts off the card as a slab of its own.
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Transform.scale(
              scale: 1 + 0.02 * animation.value,
              child: ClaySurface(
                face: ClayFace.floating(
                  c,
                  color: layered.fill,
                  radius: ClayRadius.control,
                ),
                child: child,
              ),
            ),
          ),
          itemBuilder: (context, item, reorder) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reorder.index > 0)
                const ClayGroove(indent: 48, endIndent: ClaySpacing.roomy),
              DefaultTextStyle.merge(
                style: theme.textTheme.body.copyWith(
                  color: layered.foreground ?? c.ink,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: rowHeight),
                  child: Row(
                    children: [
                      reorder.handle(
                        MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: SizedBox(
                            width: 48,
                            height: rowHeight,
                            child: Icon(
                              LucideIcons.gripVertical,
                              size: 20,
                              color: c.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: itemBuilder(context, item)),
                      const SizedBox(width: ClaySpacing.regular),
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

/// One action under a [ClaySwipeRow].
@immutable
class ClaySwipeAction {
  /// An action named [label] that does [onPressed].
  const ClaySwipeAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// What it does.
  final VoidCallback onPressed;

  /// Its glyph, over the words.
  final IconData? icon;

  /// Whether it destroys something: a danger slab.
  final bool isDestructiveAction;
}

/// A row with actions under it: a swipe slides the row aside and shows
/// them as clay slabs (coral, or the danger red); a long swipe takes the
/// last; a scroll of the list closes it.
///
/// ```dart
/// ClaySwipeRow(endActions: [ClaySwipeAction(label: 'Delete', onPressed: () {}, isDestructiveAction: true)], child: const Text('Drink water'))
/// ```
class ClaySwipeRow extends StatelessWidget {
  /// [child] with [startActions] and [endActions] under it.
  const ClaySwipeRow({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
    this.style,
  });

  /// The row.
  final Widget child;

  /// The actions a swipe toward the end shows.
  final List<ClaySwipeAction> startActions;

  /// The actions a swipe toward the start shows.
  final List<ClaySwipeAction> endActions;

  /// This row's own style, over [ClayThemeData.swipeRowStyle]: `fill` the
  /// clay of an action that is not destructive, `foreground` its ink.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.swipeRowStyle], const {});
    DesignSwipeAction wrap(ClaySwipeAction a) => DesignSwipeAction(
      label: a.label,
      onPressed: a.onPressed,
      destructive: a.isDestructiveAction,
      data: a,
    );
    return ClipRect(
      child: DesignSwipeActions(
        startActions: [for (final a in startActions) wrap(a)],
        endActions: [for (final a in endActions) wrap(a)],
        actionExtent: 88,
        dampingRatio: ClayMotion.panelDamping,
        stiffness: ClayMotion.panelStiffness,
        actionBuilder: (context, action, details) {
          final a = action.data! as ClaySwipeAction;
          final pressed = details.states.contains(WidgetState.pressed);
          final fill = a.isDestructiveAction
              ? c.danger
              : layered.fill ?? c.accent;
          final ink = a.isDestructiveAction
              ? c.onColor(fill)
              : layered.foreground ?? c.onColor(fill);
          return Padding(
            padding: const EdgeInsets.all(ClaySpacing.tight),
            child: AnimatedClaySurface(
              face: ClayFace.raised(c, color: fill, radius: ClayRadius.control)
                  .copyWith(
                    elevation: details.armed ? 1 : 0.6,
                    press: pressed ? 1 : 0,
                    focus: details.states.contains(WidgetState.focused) ? 1 : 0,
                    focusColor: ink,
                  ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (a.icon != null) Icon(a.icon, size: 20, color: ink),
                    Text(
                      a.label,
                      maxLines: 1,
                      style: theme.textTheme.caption.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w600,
                        fontVariations: clayWeight(FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: child,
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

/// Pull to refresh: pulled past its mark a clay ball turns its arrow; let
/// go, it spins until [onRefresh] ends, then shows a coral check.
///
/// ```dart
/// ClayPullToRefresh(onRefresh: () async {}, child: ListView(children: const [Text('Today')]))
/// ```
class ClayPullToRefresh extends StatelessWidget {
  /// [child], refreshed by [onRefresh].
  const ClayPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.style,
  });

  /// Fetches again.
  final Future<void> Function() onRefresh;

  /// The scrolling content.
  final Widget child;

  /// Its own style, over [ClayThemeData.pullToRefreshStyle]: `fill` the
  /// ball once a release would refresh, `foreground` its glyph.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.pullToRefreshStyle], const {});
    final warm = layered.fill ?? c.accent;
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      indicatorBuilder: (context, details) {
        final armed = details.mode == DesignRefreshMode.armed;
        final done = details.mode == DesignRefreshMode.done;
        final turning = details.mode == DesignRefreshMode.refresh;
        final coral = armed || done;
        final ink = coral
            ? layered.foreground ?? c.onColor(warm)
            : c.inkSecondary;
        return SizedBox(
          height: details.extent,
          child: ClipRect(
            child: Center(
              child: SizedBox.square(
                dimension: 40,
                child: AnimatedClaySurface(
                  face: ClayFace.raised(
                    c,
                    color: coral ? warm : null,
                    radius: 20,
                  ).copyWith(elevation: 0.7),
                  child: Center(
                    child: turning
                        ? const ClaySpinner(size: 24)
                        : Transform.rotate(
                            angle: done
                                ? 0
                                : math.pi * details.progress.clamp(0.0, 1.0),
                            child: Icon(
                              done ? LucideIcons.check : LucideIcons.arrowDown,
                              size: 20,
                              color: ink,
                            ),
                          ),
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
}

/// The nodes of a [ClayTree], which open, and which is chosen; the caller
/// makes it and disposes it.
class ClayTreeController<T extends Object> extends DesignTreeController<T> {
  /// A controller over [roots], each node's children by [childrenOf].
  ClayTreeController({
    required super.roots,
    required super.childrenOf,
    super.expanded,
  });
}

/// A tree: nested rows with soft grooves down their depth, a chevron that
/// opens a node, the chosen row a pale coral dent. The arrows walk it, Right
/// and Left open and close a node.
///
/// ```dart
/// ClayTree<String>(controller: controller, labelOf: (node) => node)
/// ```
class ClayTree<T extends Object> extends StatelessWidget {
  /// A tree over [controller]'s nodes.
  const ClayTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.iconOf,
    this.onActivate,
    this.semanticLabel,
    this.style,
  });

  /// The nodes and their state.
  final ClayTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's glyph.
  final IconData? Function(T node)? iconOf;

  /// A node opened (Enter, or a tap on a leaf).
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This tree's own style, over [ClayThemeData.treeStyle]: `fill` the
  /// chosen row's dent.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.treeStyle];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return DesignTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: semanticLabel,
      rowBuilder: (context, item) {
        final states = item.states;
        final layered = DesignStyleOf(layers, {
          ...states,
          if (item.selected) WidgetState.selected,
        });
        final ink = layered.foreground ?? c.ink;
        final icon = iconOf?.call(item.row.node);
        return SizedBox(
          height: theme.controlHeight - 4,
          child: Row(
            children: [
              for (var d = 0; d < item.row.depth; d++)
                SizedBox(
                  width: 22,
                  child: Center(
                    child: SizedBox(
                      width: 2,
                      height: double.infinity,
                      child: ColoredBox(
                        color: Color.lerp(c.well, c.track, 0.5)!,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: AnimatedClaySurface(
                  face: _rowFace(
                    c,
                    states,
                    chosen: item.selected,
                    radius: 12,
                    fill: item.selected ? layered.fill : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: item.hasChildren
                            ? MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: item.toggle,
                                  behavior: HitTestBehavior.opaque,
                                  // Closed, it points along the line; open,
                                  // down at what it holds.
                                  child: Center(
                                    child: AnimatedRotation(
                                      turns: item.expanded
                                          ? 0
                                          : (rtl ? 0.25 : -0.25),
                                      duration: still
                                          ? Duration.zero
                                          : const Duration(milliseconds: 180),
                                      curve: Curves.easeOutCubic,
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CustomPaint(
                                          painter: ClayChevronPainter(
                                            c.inkSecondary,
                                            0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: ink),
                        const SizedBox(width: ClaySpacing.small),
                      ],
                      Expanded(
                        child: Text(
                          labelOf(item.row.node),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.body
                              .copyWith(
                                color: ink,
                                fontWeight: item.selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontVariations: clayWeight(
                                  item.selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              )
                              .merge(layered.textStyle),
                        ),
                      ),
                      const SizedBox(width: ClaySpacing.small),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
