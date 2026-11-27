import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../icons.dart';
import '../internal/icon_fill.dart';
import '../internal/layer.dart';
import '../internal/measure.dart';
import '../internal/well.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button/button.dart';
import 'checkbox/checkbox.dart';
import 'feedback/spinner.dart';
import 'navigation.dart';
import 'pressable/pressable.dart';

/// A scroll thumb's room inside its track: Fluent's ScrollBar thumb stands
/// 3 in from the track's sides, finer than the 4-pt grid.
const double _thumbInset = 3;

/// The scroll area's bar: the strip it is drawn and pressed in.
const double _barThickness = 12;

/// A reorder grip's dots and the room between them: Fluent's six-dot
/// ReOrderDotsVertical glyph, 3 by 3 and 3 apart.
const double _gripDot = 3;

/// A sortable data grid with optional row selection and pagination.
///
/// Cells wrap long values. The grid scrolls horizontally when the column
/// headings exceed its available width.
///
/// ```dart
/// Fluent2DataGrid<Map<String, String>>(semanticLabel: 'Files', controller: files, cell: (row, column) => row[column.id] ?? '')
/// ```
class Fluent2DataGrid<R> extends StatelessWidget {
  /// A table over [controller].
  const Fluent2DataGrid({
    super.key,
    required this.controller,
    required this.cell,
    this.semanticLabel,
    this.selectable = true,
    this.onActivate,
  });

  /// The rows, columns, sort, page and selection.
  final RawDataTableController<R> controller;

  /// Returns the displayed value for a cell.
  final String Function(R row, RawDataColumn<R> column) cell;

  /// The grid's accessibility label.
  final String? semanticLabel;

  /// Whether rows can be ticked.
  final bool selectable;

  /// Called when the user opens a row with a pointer or Enter.
  final ValueChanged<R>? onActivate;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final words = Fluent2Localizations.of(context);
    const space = EdgeInsets.symmetric(horizontal: Fluent2Spacing.m);
    int flex(RawDataColumn<R> column) => column.numeric ? 2 : 3;
    Widget box(RawDataColumn<R> column, Widget child) => Expanded(
      flex: flex(column),
      child: Align(
        alignment: column.numeric
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    );
    // Rows, headings and the tick column are targets: the floor (40) under
    // a finger.
    final target = Fluent2Layout.hitTargetOf(context);
    final heading = Fluent2Layout.padded(context) ? target : 32.0;
    // Keep headers and their sort indicators together. On a narrow screen
    // the grid scrolls as a whole, keeping the headers aligned with the rows.
    var unit = 0.0;
    var totalFlex = 0;
    for (final column in controller.columns) {
      final labelWidth = fluent2WordsWidth(context, [
        column.label,
      ], t.caption1Strong);
      final width =
          labelWidth +
          space.horizontal +
          (column.sortable ? 12 + Fluent2Spacing.xs : 0);
      final fraction = flex(column);
      if (width / fraction > unit) unit = width / fraction;
      totalFlex += fraction;
    }
    final minWidth =
        (unit * totalFlex).ceilToDouble() + (selectable ? target : 0);
    Widget tick(bool? value, VoidCallback toggle, String name) => SizedBox(
      width: target,
      child: Center(
        child: Fluent2Checkbox(
          value: value,
          semanticLabel: name,
          onChanged: (_) => toggle(),
        ),
      ),
    );
    return Semantics(
      label: semanticLabel,
      container: true,
      explicitChildNodes: true,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, bounds) {
                final grid = RawDataTable<R>(
                  controller: controller,
                  selectable: selectable,
                  onActivate: onActivate,
                  headerRowBuilder: (context, cells) => DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: c.neutralStroke2),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (selectable)
                          tick(
                            switch (controller.pageSelection) {
                              RawDataTableSelection.all => true,
                              RawDataTableSelection.none => false,
                              RawDataTableSelection.some => null,
                            },
                            controller.togglePage,
                            words.selectAllRows,
                          ),
                        for (final (i, column) in controller.columns.indexed)
                          box(column, cells[i]),
                      ],
                    ),
                  ),
                  headerBuilder: (context, column, sort, states) {
                    final press = states.press;
                    return Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Container(
                          constraints: BoxConstraints(minHeight: heading),
                          padding: space,
                          decoration: BoxDecoration(
                            color: press.pick(
                              c.subtleBackground,
                              fluent2Step(t, c.subtleBackgroundHover),
                              fluent2Step(t, c.subtleBackgroundPressed),
                            ),
                            borderRadius: BorderRadius.circular(t.radiusMedium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: Fluent2Spacing.xs,
                            children: [
                              Flexible(
                                child: Text(
                                  column.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.caption1Strong.c(t.textSecondary),
                                ),
                              ),
                              if (sort != null)
                                Icon(
                                  sort == RawSortDirection.ascending
                                      ? Fluent2Icons.arrowUp
                                      : Fluent2Icons.arrowDown,
                                  size: 12,
                                  color: c.compoundBrandForeground1,
                                ),
                            ],
                          ),
                        ),
                        if (states.focused)
                          const Positioned.fill(
                            child: IgnorePointer(child: Fluent2FocusRing()),
                          ),
                      ],
                    );
                  },
                  cellBuilder: (context, row, column) => Padding(
                    padding: space.copyWith(
                      top: Fluent2Spacing.mNudge,
                      bottom: Fluent2Spacing.mNudge,
                    ),
                    child: Text(
                      cell(row, column),
                      style: column.numeric ? t.body1.tabular : t.body1,
                      textAlign: column.numeric
                          ? TextAlign.end
                          : TextAlign.start,
                    ),
                  ),
                  rowBuilder: (context, row, cells) {
                    final press = row.states.press;
                    final fill = row.selected
                        ? press.pick(
                            fluent2Step(t, c.subtleBackgroundSelected),
                            fluent2Step(t, c.subtleBackgroundHover),
                            fluent2Step(t, c.subtleBackgroundPressed),
                          )
                        : press.pick(
                            c.subtleBackground,
                            fluent2Step(t, c.subtleBackgroundHover),
                            fluent2Step(t, c.subtleBackgroundPressed),
                          );
                    return Stack(
                      fit: StackFit.passthrough,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: fill,
                            border: Border(
                              bottom: BorderSide(color: c.neutralStroke2),
                            ),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: target),
                            child: Row(
                              children: [
                                if (selectable)
                                  tick(
                                    row.selected,
                                    row.toggle,
                                    words.selectRow(words.row),
                                  ),
                                for (final (i, column)
                                    in controller.columns.indexed)
                                  box(column, cells[i]),
                              ],
                            ),
                          ),
                        ),
                        if (row.states.focused)
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: Fluent2FocusRing(
                                radius: Fluent2Radius.none,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
                if (bounds.hasBoundedWidth && bounds.maxWidth >= minWidth) {
                  return grid;
                }
                final table = SizedBox(width: minWidth, child: grid);
                if (!bounds.hasBoundedWidth) return table;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: table,
                );
              },
            ),
            if (controller.pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: Fluent2Spacing.m),
                child: Center(
                  child: Fluent2Pagination(
                    page: controller.page + 1,
                    pages: controller.pageCount,
                    onChanged: (p) => controller.goToPage(p - 1),
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
      ..add(
        DiagnosticsProperty<RawDataTableController<R>>(
          'controller',
          controller,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(R row, RawDataColumn<R> column)>.has(
          'cell',
          cell,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'selectable',
          value: selectable,
          ifFalse: 'selectable: false',
        ),
      )
      ..add(ObjectFlagProperty<ValueChanged<R>?>.has('onActivate', onActivate));
  }
}

/// A scrolling region with Fluent's thin bar: 6 wide while it rests, in the
/// accessible stroke, fading when idle. It takes the keyboard when reached and
/// wears the focus ring round the region.
///
/// ```dart
/// Fluent2ScrollArea(controller: scroll, child: ListView(controller: scroll, children: rows))
/// ```
class Fluent2ScrollArea extends StatelessWidget {
  /// A region round [child], which scrolls on [controller].
  const Fluent2ScrollArea({
    this.focusNode,
    this.autofocus = false,
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
    this.thumbVisibility = false,
  });

  /// The scroll position, also given to [child].
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// The way it scrolls.
  final Axis axis;

  /// The region's name.
  final String? semanticLabel;

  /// Whether the bar always shows. A bar that always shows stands in a
  /// gutter of its own beside [child], so no tap meant for the content lands
  /// on it; one that fades lies over the content's edge.
  final bool thumbVisibility;

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final moves = Fluent2Motion.of(context, Fluent2Motion.normal);
    return RawScrollArea(
      focusNode: focusNode,
      autofocus: autofocus,
      controller: controller,
      axis: axis,
      thickness: _barThickness,
      semanticLabel: semanticLabel,
      visibility: thumbVisibility
          ? RawScrollbarVisibility.always
          : RawScrollbarVisibility.auto,
      thumbBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: moves,
        child: Padding(
          padding: const EdgeInsets.all(_thumbInset),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: thumb.states.pressed
                  ? c.neutralForeground3Pressed
                  : thumb.states.hovered
                  ? c.neutralForeground3Hover
                  : c.neutralStrokeAccessible,
              borderRadius: BorderRadius.circular(Fluent2Radius.circular),
            ),
          ),
        ),
      ),
      frameBuilder: (context, focused, area) => Stack(
        fit: StackFit.passthrough,
        children: [
          area,
          if (focused)
            const Positioned.fill(
              child: IgnorePointer(child: Fluent2FocusRing()),
            ),
        ],
      ),
      child: thumbVisibility
          ? Padding(
              padding: axis == Axis.vertical
                  ? const EdgeInsetsDirectional.only(end: _barThickness)
                  : const EdgeInsets.only(bottom: _barThickness),
              child: child,
            )
          : child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ScrollController>('controller', controller))
      ..add(EnumProperty<Axis>('axis', axis, defaultValue: Axis.vertical))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'thumbVisibility',
          value: thumbVisibility,
          ifTrue: 'thumbVisibility',
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// Two panes with a hairline between them that drags, or with the keyboard on
/// its grip takes the arrows, to share the room: Fluent's subtle grip, the
/// line in the brand while it is held.
///
/// ```dart
/// Fluent2Resizable(first: list, second: detail, minFirst: 240, minSecond: 320)
/// ```
class Fluent2Resizable extends StatelessWidget {
  /// Two panes sharing the room.
  const Fluent2Resizable({
    this.focusNode,
    this.autofocus = false,
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = .5,
    this.minFirst = 0,
    this.minSecond = 0,
    this.onChanged,
  });

  /// The pane at the start, or the top.
  final Widget first;

  /// The pane at the end, or the bottom.
  final Widget second;

  /// Side by side, or one over the other.
  final Axis axis;

  /// The first pane's share at the start.
  final double initialFraction;

  /// The least the first pane may take.
  final double minFirst;

  /// The least the second pane may take.
  final double minSecond;

  /// Told the first pane's share as it moves.
  final ValueChanged<double>? onChanged;

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    return RawSplitView(
      focusNode: focusNode,
      autofocus: autofocus,
      first: first,
      second: second,
      axis: axis,
      initialFraction: initialFraction,
      minFirst: minFirst,
      minSecond: minSecond,
      onChanged: onChanged,
      hitExtent: 16,
      semanticLabel: RawWidgetsLocalizations.of(context).splitViewHandleLabel,
      dividerBuilder: (context, states, axis) {
        final along = axis == Axis.horizontal;
        final held = states.pressed;
        final over = states.hovered;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            ColoredBox(
              color: held
                  ? c.compoundBrandStroke
                  : over
                  ? fluent2Step(t, c.neutralStroke1Hover)
                  : fluent2Step(t, c.neutralStroke2),
              child: const SizedBox.expand(),
            ),
            Container(
              width: along ? 8 : 24,
              height: along ? 24 : 8,
              decoration: BoxDecoration(
                color: c.neutralBackground1,
                borderRadius: BorderRadius.circular(t.radiusMedium),
                border: Border.all(
                  color: held
                      ? c.compoundBrandStroke
                      : fluent2Step(t, c.neutralStroke1),
                ),
              ),
            ),
            if (states.focused)
              SizedBox(
                width: along ? 12 : 28,
                height: along ? 28 : 12,
                child: const IgnorePointer(child: Fluent2FocusRing()),
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
      ..add(EnumProperty<Axis>('axis', axis, defaultValue: Axis.horizontal))
      ..add(
        DoubleProperty('initialFraction', initialFraction, defaultValue: .5),
      )
      ..add(DoubleProperty('minFirst', minFirst, defaultValue: 0))
      ..add(DoubleProperty('minSecond', minSecond, defaultValue: 0))
      ..add(
        ObjectFlagProperty<ValueChanged<double>?>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// Slides one at a time, Fluent's Carousel: the viewport with its corners 4,
/// and under it a chevron each way either side of the page dots, with play and
/// pause when it [autoplay]s. A slide turns by drag, by the chevrons or by the
/// arrows while it holds focus.
///
/// ```dart
/// Fluent2CarouselView(semanticLabel: 'Highlights', children: slides)
/// ```
class Fluent2CarouselView extends StatelessWidget {
  /// A carousel of [children].
  const Fluent2CarouselView({
    this.focusNode,
    this.autofocus = false,
    super.key,
    required this.children,
    this.semanticLabel,
    this.initialItem = 0,
    this.looping = false,
    this.autoplay,
    this.onChanged,
    this.aspect = 16 / 9,
  });

  /// The slides.
  final List<Widget> children;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// The first slide shown.
  final int initialItem;

  /// Whether it runs past its ends.
  final bool looping;

  /// How long each slide stays, when it turns by itself.
  final Duration? autoplay;

  /// Told the slide it settles on.
  final ValueChanged<int>? onChanged;

  /// The viewport's width over its height.
  final double aspect;

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final words = Fluent2Localizations.of(context);
    final n = children.length;
    // The frame holds the corner, not each slide: a slide moving past the
    // frame's edge is cut by the frame's corners, never square.
    return RawCarousel(
      focusNode: focusNode,
      autofocus: autofocus,
      itemCount: n,
      itemBuilder: (context, i) => children[i],
      initialPage: initialItem,
      loop: looping,
      autoplayInterval: autoplay,
      onPageChanged: onChanged,
      semanticLabel: semanticLabel ?? '',
      slideLabel: (i, count) =>
          RawWidgetsLocalizations.of(context).carouselSlideLabel(i, count),
      duration: Fluent2Motion.of(context, Fluent2Motion.slow),
      layoutBuilder: (context, viewport, controls) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: aspect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    context.fluent2Theme.radiusMedium,
                  ),
                  child: viewport,
                ),
              ),
              if (controls.focused)
                const Positioned.fill(
                  child: IgnorePointer(child: Fluent2FocusRing()),
                ),
            ],
          ),
          if (n > 1) ...[
            const SizedBox(height: Fluent2Spacing.xs),
            Row(
              children: [
                Fluent2IconButton(
                  Fluent2Icons.chevronLeft,
                  semanticLabel: words.previousSlide,
                  onPressed: controls.previous,
                ),
                Expanded(
                  child: Center(
                    // The pill follows the slides frame by frame, under the
                    // finger and round a looping.
                    child: ValueListenableBuilder<double>(
                      valueListenable: controls.position,
                      builder: (context, position, _) => Fluent2PageDots(
                        count: n,
                        selectedIndex: controls.page,
                        position: position,
                        semanticLabel: RawWidgetsLocalizations.of(context)
                            .carouselSlideLabel(controls.page, n),
                        onChanged: controls.goToPage,
                      ),
                    ),
                  ),
                ),
                if (controls.togglePlay != null)
                  Fluent2IconButton(
                    controls.playing ? Fluent2Icons.pause : Fluent2Icons.play,
                    semanticLabel: controls.playing ? words.pause : words.play,
                    onPressed: controls.togglePlay,
                  ),
                Fluent2IconButton(
                  Fluent2Icons.chevronRight,
                  semanticLabel: words.nextSlide,
                  onPressed: controls.next,
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
    properties
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(IntProperty('initialItem', initialItem, defaultValue: 0))
      ..add(FlagProperty('looping', value: looping, ifTrue: 'looping'))
      ..add(
        DiagnosticsProperty<Duration>('autoplay', autoplay, defaultValue: null),
      )
      ..add(ObjectFlagProperty<ValueChanged<int>?>.has('onChanged', onChanged))
      ..add(DoubleProperty('aspect', aspect, defaultValue: 16 / 9))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// A list whose rows drag by their grip, or move with the keyboard from it:
/// a dot grip at each row's end, a hairline between rows, and the row being
/// carried lifted in `shadow16`.
///
/// ```dart
/// Fluent2ReorderableListView<String>(items: tasks, onReorder: move, labelOf: (t) => t, itemBuilder: (context, t) => Text(t))
/// ```
class Fluent2ReorderableListView<T extends Object> extends StatelessWidget {
  /// A list of [items].
  const Fluent2ReorderableListView({
    super.key,
    required this.items,
    required this.onReorder,
    required this.labelOf,
    required this.itemBuilder,
    this.shrinkWrap = false,
  });

  /// The rows, in order.
  final List<T> items;

  /// Told a row's move, from and to.
  final void Function(int from, int to) onReorder;

  /// A row's name, for its handle and the announcement.
  final String Function(T item) labelOf;

  /// A row's content.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Whether the list takes only the height its rows need.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    return RawReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      shrinkWrap: shrinkWrap,
      proxyDecorator: (child, index, animation) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.neutralBackground1,
          borderRadius: BorderRadius.circular(t.radiusMedium),
          boxShadow: t.shadows.shadow16,
        ),
        child: child,
      ),
      itemBuilder: (context, item, r) => DecoratedBox(
        decoration: BoxDecoration(
          border: r.index > 0
              ? Border(top: BorderSide(color: c.neutralStroke2))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Fluent2Spacing.m,
                  vertical: Fluent2Spacing.mNudge,
                ),
                child: DefaultTextStyle.merge(
                  style: t.body1,
                  child: itemBuilder(context, item),
                ),
              ),
            ),
            r.handle(const _Grip()),
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
      ..add(ObjectFlagProperty<String Function(T item)>.has('labelOf', labelOf))
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext context, T item)>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(
        FlagProperty('shrinkWrap', value: shrinkWrap, ifTrue: 'shrinkWrap'),
      );
  }
}

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    final ink = context.fluent2Theme.colors.neutralForeground3;
    Widget dot() => Container(
      width: _gripDot,
      height: _gripDot,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
    );
    final side = Fluent2Layout.hitTargetOf(context);
    return SizedBox(
      width: side,
      height: side,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _gripDot,
          children: [
            for (var c = 0; c < 2; c++)
              Column(
                mainAxisSize: MainAxisSize.min,
                spacing: _gripDot,
                children: [for (var r = 0; r < 3; r++) dot()],
              ),
          ],
        ),
      ),
    );
  }
}

/// A list that refreshes when pulled from its top, as Windows' refresh
/// container does: the pull opens a band of the page's ground over the list's
/// top edge (a hairline at its foot), and Fluent's spinner in it fills with
/// the pull, then turns until [onRefresh] completes. Nothing floats over the
/// rows: no disc, no shadow.
///
/// ```dart
/// Fluent2RefreshIndicator(onRefresh: reload, child: ListView(children: rows))
/// ```
class Fluent2RefreshIndicator extends StatelessWidget {
  /// A pull to refresh round [child].
  const Fluent2RefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// The refresh; the spinner turns until it completes.
  final Future<void> Function() onRefresh;

  /// The scrolling list.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return RawRefreshIndicator(
      onRefresh: onRefresh,
      refreshLabel: RawWidgetsLocalizations.of(context).refreshLabel,
      refreshingMessage: RawWidgetsLocalizations.of(context).refreshingMessage,
      doneMessage: RawWidgetsLocalizations.of(context).refreshedMessage,
      indicatorBuilder: (context, s) => DecoratedBox(
        decoration: BoxDecoration(
          color: Fluent2Layer.groundOf(context),
          border: Border(
            bottom: BorderSide(color: fluent2Step(t, t.colors.neutralStroke2)),
          ),
        ),
        child: Center(
          child: Opacity(
            opacity: s.mode == RawRefreshIndicatorMode.inactive
                ? 0
                : s.progress.clamp(0.0, 1.0),
            child: Fluent2Spinner(
              size: Fluent2SpinnerSize.extraSmall,
              value: switch (s.mode) {
                RawRefreshIndicatorMode.refresh => null,
                RawRefreshIndicatorMode.done => 1,
                _ => s.progress.clamp(0.0, 1.0),
              },
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<Future<void> Function()>.has('onRefresh', onRefresh),
    );
  }
}

/// One event of a [Fluent2Timeline].
///
/// ```dart
/// Fluent2TimelineEntry(title: 'Approved', time: '2:30 PM', body: 'By Sam')
/// ```
@immutable
class Fluent2TimelineEntry {
  /// An event called [title].
  const Fluent2TimelineEntry({
    required this.title,
    this.time,
    this.body,
    this.icon,
    this.tone,
  });

  /// What happened.
  final String title;

  /// When, already in words.
  final String? time;

  /// More about it.
  final String? body;

  /// Its glyph; null wears its tone's.
  final IconData? icon;

  /// What it says it was; null is neutral.
  final Fluent2Tone? tone;
}

/// An activity feed, as Fluent's apps list what happened (a Teams activity, a
/// file's version history): each event a row led by its glyph (filled when it
/// has a tone, as a status glyph is) on a
/// 32 disc of its tone's tint (the neutral tint when it has none), the title
/// in body1 strong with its time in caption1 at the end, its words in body1
/// under it. No rail joins the rows; their order says the sequence. An entry
/// with no glyph wears its tone's: a check for success, the warning and error
/// glyphs, the info glyph, else the history glyph.
///
/// ```dart
/// Fluent2Timeline(entries: const [Fluent2TimelineEntry(title: 'Created', time: 'Monday')])
/// ```
class Fluent2Timeline extends StatelessWidget {
  /// A timeline of [entries], first at the top.
  const Fluent2Timeline({super.key, required this.entries});

  /// The events, in order.
  final List<Fluent2TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: Fluent2Spacing.l,
      children: [
        for (final e in entries)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Fluent2Spacing.m,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.tone == null
                        ? fluent2Well(t)
                        : t.tone(e.tone!).tint,
                    // A tone's tint wears its edge, as a message bar's and
                    // a tint badge's do: the tint alone all but vanishes on
                    // the brand-tinted page.
                    border: e.tone == null
                        ? null
                        : Border.all(color: t.tone(e.tone!).border),
                  ),
                  // A status glyph is filled, as a message bar's is; any
                  // other glyph keeps its outline at rest (a glyph fills in
                  // only under the pointer or while chosen).
                  child: Icon(
                    e.tone == null
                        ? e.icon ?? _glyphOf(e.tone)
                        : fluent2Filled(e.icon ?? _glyphOf(e.tone)),
                    size: 16,
                    color: e.tone == null
                        ? t.colors.neutralForeground2
                        : t.tone(e.tone!).ink,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: Fluent2Spacing.sNudge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: Fluent2Spacing.xxs,
                    children: [
                      // The time stands at the row's end while the words
                      // leave it room, and goes under them when they don't
                      // (larger text, a narrow column): a word never breaks.
                      Wrap(
                        spacing: Fluent2Spacing.s,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(e.title, style: t.body1Strong),
                          if (e.time != null)
                            Text(e.time!, style: t.caption1.c(t.textTertiary)),
                        ],
                      ),
                      if (e.body != null)
                        Text(e.body!, style: t.body1.c(t.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static IconData _glyphOf(Fluent2Tone? tone) => switch (tone) {
    Fluent2Tone.success => Fluent2Icons.checkmarkCircle,
    Fluent2Tone.warning => Fluent2Icons.warning,
    Fluent2Tone.danger || Fluent2Tone.severe => Fluent2Icons.errorCircle,
    Fluent2Tone.informative => Fluent2Icons.info,
    _ => Fluent2Icons.history,
  };

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<Fluent2TimelineEntry>('entries', entries));
  }
}
