/// Gloss's collections: the data table, the scroll area, the split view,
/// the carousel, the reorderable list, the swipe row, pull to refresh and
/// the tree, each on the headless behaviour, drawn in porcelain, wells and
/// gel.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'display.dart';
import 'feedback.dart';
import 'internal/chevron.dart';
import 'internal/glaze_state.dart';
import 'surface.dart';
import 'theme.dart';
import 'wayfinding.dart';

/// A column of a [GlossDataTable].
class GlossDataColumn<R> extends RawDataColumn<R> {
  /// A column [id] headed [label].
  const GlossDataColumn({
    required super.id,
    required super.label,
    super.sortKey,
    super.numeric,
    this.flex = 1,
  });

  /// Its share of the width.
  final int flex;
}

/// The rows, sorting, filtering, paging and selection of a
/// [GlossDataTable]: make it in a State, dispose it there.
class GlossTableController<R> extends RawDataTableController<R> {
  /// A controller over [rows] in [columns].
  GlossTableController({
    required super.rows,
    required List<GlossDataColumn<R>> super.columns,
    super.rowKey,
    super.pageSize,
    super.filter,
  });
}

/// A small socket a row's selection shows in: jade gel and a tick when on,
/// a bar when some are.
Widget _tick(GlossColors c, {required bool on, bool some = false}) =>
    SizedBox.square(
      dimension: 20,
      child: AnimatedGlossSurface(
        face: on || some
            ? GlossFace.gel(c, radius: 6).copyWith(lift: 0.4)
            : GlossFace.well(c, radius: 6),
        child: on
            ? Icon(LucideIcons.check, size: 14, color: c.onJade)
            : some
            ? Center(
                child: SizedBox(
                  width: 9,
                  height: 2,
                  child: ColoredBox(color: c.onJade),
                ),
              )
            : null,
      ),
    );

/// A data table: rows that sort by their headings, select, filter and
/// page, on a porcelain card. The headings are letterpressed; a chosen row
/// is glazed pale jade; the pages are a [GlossPagination] under it.
///
/// ```dart
/// GlossDataTable<({String name, int minutes})>(controller: controller, cell: (recipe, column) => column == 'name' ? recipe.name : '${recipe.minutes} min')
/// ```
class GlossDataTable<R> extends StatelessWidget {
  /// A table over [controller].
  const GlossDataTable({
    super.key,
    required this.controller,
    required this.cell,
    this.selectable = true,
    this.onActivate,
    this.emptyText,
    this.style,
  });

  /// Its rows, columns and state.
  final GlossTableController<R> controller;

  /// A cell's words.
  final String Function(R row, String columnId) cell;

  /// Whether rows can be chosen.
  final bool selectable;

  /// A row opened (Enter, a double press).
  final ValueChanged<R>? onActivate;

  /// What it says with no rows; null: the platform's words.
  final String? emptyText;

  /// Its own style, over [GlossThemeData.dataTableStyle].
  final GlossStyle? style;

  static const double _box = 48;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final words = RawWidgetsLocalizations.of(context);
    final layers = [style, theme.dataTableStyle];
    final frame = RawStyleOf(layers, const {});
    int flex(RawDataColumn<R> col) => (col as GlossDataColumn<R>).flex;
    const pad = EdgeInsets.symmetric(
      horizontal: GlossSpacing.medium,
      vertical: GlossSpacing.medium,
    );
    final light = c.brightness == Brightness.light;
    final glaze = light ? const Color(0xFFDDF2EA) : const Color(0xFF1F3F35);
    final table = RawDataTable<R>(
      controller: controller,
      selectable: selectable,
      onActivate: onActivate,
      headerBuilder: (context, column, sort, states) {
        final focused = states.contains(WidgetState.focused);
        return GlossGlazeHighlight(
          focused: focused,
          hovered: states.contains(WidgetState.hovered),
          pressed: states.contains(WidgetState.pressed),
          inside: true,
          radius: 8,
          inset: 1,
          // A header sorts on a tap: a finger's height (the touch floor) on
          // every input, so the header row keeps one height.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: RawTapTargets.of(context).touch.height,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlossSpacing.medium,
                vertical: GlossSpacing.small,
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
                      style: glossLetterpress(
                        t.caption.copyWith(
                          color: sort == null ? c.inkSecondary : c.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        c,
                      ),
                    ),
                  ),
                  // Only the column the rows are sorted by carries an arrow
                  // (as a desk's tables do): an arrow on every heading
                  // would take the room a narrow column's words need.
                  if (column.sortable && sort != null) ...[
                    const SizedBox(width: GlossSpacing.tight),
                    Icon(
                      switch (sort) {
                        RawSortDirection.ascending => LucideIcons.arrowUp,
                        RawSortDirection.descending => LucideIcons.arrowDown,
                      },
                      size: 14,
                      color: c.jadeInk,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      headerRowBuilder: (context, cells) {
        final page = controller.pageSelection;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectable)
                RawButton(
                  onPressed: controller.pageRows.isEmpty
                      ? null
                      : controller.togglePage,
                  semanticLabel: words.selectedLabel,
                  // A checkbox, not a button, as Flutter's Checkbox reads.
                  button: false,
                  checked: page == RawDataTableSelection.all,
                  builder: (context, states, _) => GlossGlazeHighlight(
                    focused: states.contains(WidgetState.focused),
                    hovered: states.contains(WidgetState.hovered),
                    pressed: states.contains(WidgetState.pressed),
                    inside: true,
                    radius: 8,
                    inset: 1,
                    child: SizedBox(
                      width: _box,
                      child: Center(
                        child: _tick(
                          c,
                          on: page == RawDataTableSelection.all,
                          some: page == RawDataTableSelection.some,
                        ),
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
                fontFeatures: column.numeric
                    ? const [FontFeature.tabularFigures()]
                    : null,
              )
              .merge(frame.textStyle),
        ),
      ),
      rowBuilder: (context, row, cells) {
        final states = row.states;
        final pressed = states.contains(WidgetState.pressed);
        final layered = RawStyleOf(layers, {
          ...states,
          if (row.selected) WidgetState.selected,
        });
        final clear = c.page.withValues(alpha: 0);
        var plate = pressed
            ? GlossFace.well(c, radius: 10).copyWith(lift: -0.6)
            : row.selected
            ? GlossFace(
                top: glaze,
                middle: glaze,
                bottom: glaze,
                foreground: c.ink,
                radius: 10,
              )
            : GlossFace(
                top: clear,
                middle: clear,
                bottom: clear,
                foreground: c.ink,
                radius: 10,
              );
        if (row.selected && layered.fill != null) {
          plate = plate.glazed(layered.fill!);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GlossDivider(
              indent: GlossSpacing.small,
              endIndent: GlossSpacing.small,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlossSpacing.tight,
                vertical: GlossMetrics.rimRoom,
              ),
              child: AnimatedGlossSurface(
                face: plate.copyWith(
                  foreground: layered.foreground ?? c.ink,
                  focus: glossGlazeOf(c, states),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (selectable)
                        ExcludeSemantics(
                          child: SizedBox(
                            width: _box - 4,
                            child: Center(child: _tick(c, on: row.selected)),
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
    // The rows sit in a well below the page (law 3), not on a raised card.
    var card = GlossFace.well(c, radius: GlossMetrics.wellRadius);
    if (frame.fill != null) card = card.glazed(frame.fill!);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GlossSurface(
            face: card,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GlossSpacing.tight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  table,
                  if (controller.pageRows.isEmpty) ...[
                    const GlossDivider(),
                    Padding(
                      padding: const EdgeInsets.all(GlossSpacing.regular),
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
            const SizedBox(height: GlossSpacing.medium),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GlossSpacing.medium,
              runSpacing: GlossSpacing.small,
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
                GlossPagination(
                  page: controller.page,
                  pageCount: controller.pageCount,
                  onPageChanged: controller.goToPage,
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

/// A scroll area: [child] scrolling with a pearl bead for its thumb in a
/// groove along its edge, shown while it scrolls or the pointer is near.
/// The keys scroll it once it has the focus.
///
/// ```dart
/// GlossScrollArea(controller: scroll, child: Column(children: rows))
/// ```
class GlossScrollArea extends StatelessWidget {
  /// A scroll area over [child], scrolled by [controller].
  const GlossScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.semanticLabel,
    this.style,
  });

  /// The scroll position: the caller's, given to [child]'s scrollable too.
  final ScrollController controller;

  /// What scrolls.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its own style, over [GlossThemeData.scrollAreaStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.scrollAreaStyle];
    return RawScrollArea(
      controller: controller,
      axis: axis,
      semanticLabel: semanticLabel,
      thickness: 12,
      trackBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: const Duration(milliseconds: 160),
        child: Padding(
          padding: const EdgeInsets.all(GlossMetrics.rimRoom),
          child: GlossSurface(face: GlossFace.well(c).copyWith(lift: -0.6)),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final held = thumb.states.contains(WidgetState.pressed);
        var bead = GlossFace.pearl(c).copyWith(
          lift: held ? 0.4 : 0.8,
          travel: held ? 1 : 0,
          focus: glossGlazeOf(c, thumb.states),
        );
        final fill = RawStyleOf(layers, thumb.states).fill;
        if (fill != null) bead = bead.glazed(fill);
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.all(GlossMetrics.rimRoom),
            child: AnimatedGlossSurface(face: bead),
          ),
        );
      },
      frameBuilder: (context, focused, area) => GlazePointerBuilder(
        enabled: true,
        builder: (over, down) => GlossGlazeHighlight(
          focused: focused,
          hovered: over,
          pressed: down,
          inside: true,
          radius: 8,
          inset: 1,
          child: area,
        ),
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

/// A split view: two panes with a groove between them and a pearl grip in
/// the groove's middle; a drag on the groove, or the arrows once it has the
/// focus, moves it.
///
/// ```dart
/// GlossSplitView(first: RecipeList(), second: RecipeDetail())
/// ```
class GlossSplitView extends StatelessWidget {
  /// Two panes side by side (or one over the other).
  const GlossSplitView({
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

  /// The first pane (the start, or the top).
  final Widget first;

  /// The second pane.
  final Widget second;

  /// Side by side (horizontal) or stacked.
  final Axis axis;

  /// The first pane's share to begin with.
  final double initialFraction;

  /// The narrowest the first pane gets.
  final double minFirst;

  /// The narrowest the second pane gets.
  final double minSecond;

  /// The first pane's new share.
  final ValueChanged<double>? onChanged;

  /// What a screen reader calls the grip; null: the platform's words.
  final String? semanticLabel;

  /// Its own style, over [GlossThemeData.splitViewStyle].
  final GlossStyle? style;

  static const double _line = 2;
  static const double _reach = 16;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.splitViewStyle];
    // Nothing a tap reaches sits under the handle's reach: each pane stands
    // clear of the line by what the reach adds to it.
    const clear = (_reach - _line) / 2;
    final across = axis == Axis.horizontal;
    return RawSplitView(
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
          semanticLabel ??
          RawWidgetsLocalizations.of(context).splitViewHandleLabel,
      dividerThickness: _line,
      hitExtent: _reach,
      dividerBuilder: (context, states, axis) {
        final along = axis == Axis.horizontal;
        final layered = RawStyleOf(layers, states);
        final held = states.contains(WidgetState.pressed);
        var grip = GlossFace.pearl(c)
            .copyWith(lift: held ? 0.5 : 1, focus: glossGlazeOf(c, states));
        if (layered.fill != null) grip = grip.glazed(layered.fill!);
        // A finger needs the bead to find the line; under a pointer the
        // line and the cursor say it, and the bead comes up only while the
        // pointer is over it, the keys hold it or it is held.
        final touch = RawTapTargets.of(context).inputOn() == RawInput.touch;
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
              child: along
                  ? const GlossDivider.vertical()
                  : const GlossDivider(),
            ),
            OverflowBox(
              maxWidth: along ? 10 : 40,
              maxHeight: along ? 40 : 10,
              child: AnimatedOpacity(
                opacity: shown ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: SizedBox(
                  width: along ? 10 : 40,
                  height: along ? 40 : 10,
                  child: AnimatedGlossSurface(face: grip),
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

/// A carousel: slides in a sunken frame, a pearl bead each side to turn
/// them and page dots between. A swipe turns them too; the arrows do once
/// the frame has the focus.
///
/// ```dart
/// GlossCarousel(itemCount: 3, itemBuilder: (context, i) => photos[i])
/// ```
class GlossCarousel extends StatelessWidget {
  /// A carousel of [itemCount] slides.
  const GlossCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 16 / 9,
    this.semanticLabel,
    this.onPageChanged,
  });

  /// How many slides.
  final int itemCount;

  /// Builds a slide.
  final IndexedWidgetBuilder itemBuilder;

  /// The frame's width over its height.
  final double aspectRatio;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// The slide now showing.
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RawCarousel(
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
            child: GlazePointerSurface(
              enabled: itemCount > 0,
              face: GlossFace.well(
                c,
                radius: GlossMetrics.cardRadius,
              ).copyWith(focus: glossFocusOf(c, focused: controls.focused)),
              child: Padding(
                padding: const EdgeInsets.all(GlossMetrics.frameRim),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    GlossMetrics.cardRadius - 3,
                  ),
                  child: viewport,
                ),
              ),
            ),
          ),
          const SizedBox(height: GlossSpacing.medium),
          Row(
            children: [
              GlossIconButton(
                onPressed: controls.previous,
                tooltip: words.previousPageTooltip,
                icon: Icon(
                  rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                ),
              ),
              Expanded(
                child: Center(
                  child: GlossPageDots(
                    pageCount: controls.count,
                    page: controls.page,
                    onPageChanged: controls.goToPage,
                  ),
                ),
              ),
              GlossIconButton(
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

/// A reorderable list: rows in a well, engraved lines between, each with
/// a grip pressed into its start. A drag on the grip (or a long press)
/// lifts the row out of the well as a porcelain plate to set down
/// elsewhere; a screen reader moves rows with its actions.
///
/// ```dart
/// GlossReorderableList<String>(items: steps, labelOf: (s) => s, onReorder: (from, to) {}, itemBuilder: (context, s) => Text(s))
/// ```
class GlossReorderableList<T extends Object> extends StatelessWidget {
  /// A list of [items] in their order.
  const GlossReorderableList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.labelOf,
    this.shrinkWrap = true,
  });

  /// The items.
  final List<T> items;

  /// Moves the item at `from` to `to` (after it is taken out).
  final void Function(int from, int to) onReorder;

  /// A row's body.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// An item's words, for a screen reader's moves.
  final String Function(T item) labelOf;

  /// Whether it is as tall as its rows (inside another scroll).
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final rowHeight = theme.controlHeight + 8;
    return GlossSurface(
      face: GlossFace.well(c, radius: GlossMetrics.wellRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlossMetrics.wellRadius),
        child: RawReorderableList<T>(
          items: items,
          onReorder: onReorder,
          labelOf: labelOf,
          shrinkWrap: shrinkWrap,
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (context, _) => Transform.scale(
              scale: 1 + 0.02 * animation.value,
              child: GlossSurface(
                face: GlossFace.porcelain(c, radius: 14).copyWith(lift: 1),
                child: child,
              ),
            ),
          ),
          itemBuilder: (context, item, reorder) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reorder.index > 0)
                const GlossEngravedLine(indent: 48, endIndent: 2),
              DefaultTextStyle.merge(
                style: theme.textTheme.body.copyWith(color: c.ink),
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
                              shadows: [
                                Shadow(
                                  color: c.letterpress,
                                  offset: Offset(
                                    0,
                                    c.letterpressBelow ? 1 : -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: itemBuilder(context, item)),
                      const SizedBox(width: GlossSpacing.regular),
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

/// One action behind a [GlossSwipeRow].
@immutable
class GlossSwipeAction {
  /// An action [label]led that does [onPressed].
  const GlossSwipeAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// What it does.
  final VoidCallback onPressed;

  /// Its glyph.
  final IconData? icon;

  /// Whether it destroys something: ruby gel.
  final bool isDestructiveAction;
}

/// A row with actions behind it: a swipe slides it aside to show them as
/// gel blocks (ruby for one that destroys, jade otherwise); a full swipe
/// does the outermost. A screen reader offers them as the row's actions.
///
/// ```dart
/// GlossSwipeRow(endActions: [GlossSwipeAction(label: 'Delete', isDestructiveAction: true, onPressed: () {})], child: const GlossListTile(title: 'Lemon risotto'))
/// ```
class GlossSwipeRow extends StatelessWidget {
  /// A row over its actions.
  const GlossSwipeRow({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
  });

  /// The row.
  final Widget child;

  /// The actions behind its start.
  final List<GlossSwipeAction> startActions;

  /// The actions behind its end.
  final List<GlossSwipeAction> endActions;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    RawSwipeAction wrap(GlossSwipeAction a) => RawSwipeAction(
      label: a.label,
      onPressed: a.onPressed,
      destructive: a.isDestructiveAction,
      data: a,
    );
    return ClipRect(
      child: RawSwipeActions(
        startActions: [for (final a in startActions) wrap(a)],
        endActions: [for (final a in endActions) wrap(a)],
        actionExtent: 88,
        // The row opens and settles on Gloss's panel spring; a scroll of
        // the list round it closes it (ui_core's).
        dampingRatio: GlossMotion.panelDamping,
        stiffness: GlossMotion.panelStiffness,
        actionBuilder: (context, action, details) {
          final a = action.data! as GlossSwipeAction;
          final pressed = details.states.contains(WidgetState.pressed);
          final face =
              (a.isDestructiveAction ? GlossFace.ruby(c) : GlossFace.gel(c))
                  .copyWith(
                    radius: 0,
                    lift: 0,
                    lens: details.armed ? 0.9 : 0.55,
                    travel: pressed ? 1 : 0,
                    focus: glossGlazeOf(c, details.states),
                  );
          final ink = a.isDestructiveAction ? c.onDanger : c.onJade;
          return AnimatedGlossSurface(
            face: face.copyWith(foreground: ink),
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
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        // The row brings no floor of its own: the actions only ever fill
        // the strip it uncovers, so the well it sits in shows through.
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

/// Pull to refresh: a pull down past the top lowers a pearl bead with an
/// arrow that turns jade gel once letting go would refresh, then a spinner
/// while [onRefresh] runs, then a tick.
///
/// ```dart
/// GlossPullToRefresh(onRefresh: sync, child: ListView(children: rows))
/// ```
class GlossPullToRefresh extends StatelessWidget {
  /// Pull to refresh over [child] (a scrollable).
  const GlossPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Refreshes; the spinner shows until it completes.
  final Future<void> Function() onRefresh;

  /// The scrollable.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    return RawRefreshIndicator(
      onRefresh: onRefresh,
      indicatorBuilder: (context, details) {
        final armed = details.mode == RawRefreshIndicatorMode.armed;
        final done = details.mode == RawRefreshIndicatorMode.done;
        final turning = details.mode == RawRefreshIndicatorMode.refresh;
        final face = armed || done
            ? GlossFace.gel(c).copyWith(foreground: c.onJade)
            : GlossFace.pearl(c).copyWith(foreground: c.inkSecondary);
        return SizedBox(
          height: details.extent,
          child: ClipRect(
            child: Center(
              child: SizedBox.square(
                dimension: 40,
                child: turning
                    ? GlossSurface(
                        face: GlossFace.pearl(c),
                        child: const Center(child: GlossSpinner(size: 24)),
                      )
                    : AnimatedGlossSurface(
                        face: face,
                        child: Center(
                          child: Transform.rotate(
                            angle: done
                                ? 0
                                : 3.14159 * details.progress.clamp(0.0, 1.0),
                            child: Icon(
                              done ? LucideIcons.check : LucideIcons.arrowDown,
                              size: 20,
                              color: face.foreground,
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

/// The nodes and the open and chosen state of a [GlossTree]: make it in a
/// State, dispose it there.
class GlossTreeController<T extends Object> extends RawTreeController<T> {
  /// A controller over [roots], [childrenOf] each.
  GlossTreeController({
    required super.roots,
    required super.childrenOf,
    super.expanded,
  });
}

/// A tree: nested rows with grooves down the levels, each branch opened by
/// its chevron; the chosen row stands on a pale glazed plate with jade
/// words. The arrows walk it, Right opens and Left closes.
///
/// ```dart
/// GlossTree<String>(controller: controller, labelOf: (folder) => folder)
/// ```
class GlossTree<T extends Object> extends StatelessWidget {
  /// A tree over [controller].
  const GlossTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.iconOf,
    this.onActivate,
    this.semanticLabel,
    this.style,
  });

  /// Its nodes and state.
  final GlossTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's glyph.
  final IconData? Function(T node)? iconOf;

  /// A node opened (Enter, a press).
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its own style, over [GlossThemeData.treeStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.treeStyle];
    return RawTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: semanticLabel,
      rowBuilder: (context, item) {
        final states = item.states;
        final layered = RawStyleOf(layers, {
          ...states,
          if (item.selected) WidgetState.selected,
        });
        final light = c.brightness == Brightness.light;
        final glaze = light ? const Color(0xFFDDF2EA) : const Color(0xFF1F3F35);
        final clear = c.page.withValues(alpha: 0);
        var plate = states.contains(WidgetState.pressed)
            ? GlossFace.well(c, radius: 10).copyWith(lift: -0.6)
            : item.selected
            ? GlossFace(
                top: glaze,
                middle: glaze,
                bottom: glaze,
                foreground: c.jadeInk,
                radius: 10,
              )
            : GlossFace(
                top: clear,
                middle: clear,
                bottom: clear,
                foreground: c.ink,
                radius: 10,
              );
        if (item.selected && layered.fill != null) {
          plate = plate.glazed(layered.fill!);
        }
        final ink = layered.foreground ?? (item.selected ? c.jadeInk : c.ink);
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: ColoredBox(color: c.hairline)),
                          Expanded(
                            child: ColoredBox(
                              color: c.lip.withValues(alpha: c.lip.a * 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: AnimatedGlossSurface(
                  face: plate.copyWith(
                    foreground: ink,
                    focus: glossGlazeOf(c, states),
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
                                  // Closed, it points along the line (to
                                  // the end side); open, down at what it
                                  // holds.
                                  child: Center(
                                    child: AnimatedRotation(
                                      turns: item.expanded
                                          ? 0
                                          : Directionality.of(context) ==
                                                TextDirection.rtl
                                          ? 0.25
                                          : -0.25,
                                      duration:
                                          MediaQuery.maybeDisableAnimationsOf(
                                                context,
                                              ) ??
                                              false
                                          ? Duration.zero
                                          : const Duration(milliseconds: 180),
                                      curve: Curves.easeOutCubic,
                                      child: GlossChevron(
                                        open: false,
                                        color: c.inkSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: ink),
                        const SizedBox(width: GlossSpacing.small),
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
                                    : null,
                              )
                              .merge(layered.textStyle),
                        ),
                      ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('semanticLabel', semanticLabel));
  }
}
