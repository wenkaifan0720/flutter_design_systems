/// What holds and lays out content: a disclosure, tables, a divider, a
/// scroll area with its bar, a split view, a list you reorder, a pull to
/// refresh, a tree, a timeline, avatars, a picture in a frame and a list
/// of terms.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import '../grid.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../primitives/spring.dart';
import '../style.dart';
import '../theme.dart';
import 'feedback.dart';

const _clear = Color(0x00000000);

bool _touch(BuildContext context) =>
    DesignTapTargets.of(context).inputOn() == DesignInput.touch;

/// A line of rule in [color], [stroke] thick, across the middle of
/// whatever box it is given.
class _Rule extends StatelessWidget {
  const _Rule({required this.color, required this.stroke, this.axis});

  final Color color;
  final double stroke;
  final Axis? axis;

  @override
  Widget build(BuildContext context) => Center(
    child: axis == Axis.vertical
        ? Container(width: stroke, color: color)
        : Container(height: stroke, color: color),
  );
}

/// A part that opens to show more: `▸ title`, pressed `▾ title` with
/// [child] revealed under it from its top line, a short reveal with no
/// bounce (none under Reduce Motion).
///
/// ```dart
/// TermDisclosure(title: 'environment', child: Text('NODE_ENV=production'))
/// ```
class TermDisclosure extends StatefulWidget {
  /// A disclosure titled [title] over [child].
  const TermDisclosure({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.style,
  });

  /// Its title.
  final String title;

  /// What it shows open.
  final Widget child;

  /// Whether it starts open.
  final bool initiallyExpanded;

  /// Called with each open or close.
  final ValueChanged<bool>? onExpansionChanged;

  /// Overrides, over the theme's [TermThemeData.disclosureStyle]:
  /// `foreground` (the title) and `edge` (the marker).
  final TermStyle? style;

  @override
  State<TermDisclosure> createState() => _TermDisclosureState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
  }
}

class _TermDisclosureState extends State<TermDisclosure> {
  late bool _open = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _open = !_open);
    widget.onExpansionChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TermTapTarget(
          child: DesignPressable(
            onPressed: _toggle,
            expanded: _open,
            semanticLabel: widget.title,
            excludeSemantics: true,
            mouseCursor: SystemMouseCursors.click,
            builder: (context, states, _) {
              final own = TermStyleOf([
                widget.style,
                theme.disclosureStyle,
              ], states);
              final lit =
                  states.contains(WidgetState.focused) ||
                  states.contains(WidgetState.pressed);
              final ink = own.foreground ?? theme.foreground;
              return SizedBox(
                height: grid.lineHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: grid.cols(2),
                      child: Text(
                        _open ? '▾' : '▸',
                        style: theme.textStyle.copyWith(
                          color: own.edge ?? theme.accent,
                        ),
                      ),
                    ),
                    ColoredBox(
                      color: lit ? ink : _clear,
                      child: Text(
                        widget.title,
                        style: theme.boldStyle.copyWith(
                          color: lit ? theme.background : ink,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TermSpring(
          target: _open ? 1 : 0,
          token: TermMotion.reveal,
          spatial: true,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: grid.cols(2)),
            child: widget.child,
          ),
          builder: (context, t, child) {
            final v = t >= 0.995 ? 1.0 : t.clamp(0.0, 1.0);
            if (v <= 0.005) return const SizedBox.shrink();
            return ClipRect(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: v,
                child: child,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A column of a [TermTable].
@immutable
class TermColumn {
  /// A column headed [label], [cols] cells wide (null: a share of what is
  /// left); [numeric] lines its numbers up at the end.
  const TermColumn({required this.label, this.cols, this.numeric = false});

  /// Its heading.
  final String label;

  /// Its width in cells, or null for an equal share of the rest.
  final int? cols;

  /// Whether it holds numbers.
  final bool numeric;
}

Widget _cell(TermGrid grid, int? cols, bool numeric, Widget child) {
  final aligned = Align(
    alignment: numeric
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart,
    child: child,
  );
  return cols == null
      ? Expanded(child: aligned)
      : SizedBox(width: grid.cols(cols), child: aligned);
}

/// A table as a command prints one: the headings dim over a rule, the
/// columns two cells apart, numbers lined up at the end, each row one
/// line. When every column has its width and they don't fit, it scrolls
/// sideways rather than wrap.
///
/// ```dart
/// TermTable(
///   columns: const [TermColumn(label: 'run', cols: 6), TermColumn(label: 'branch'), TermColumn(label: 'took', cols: 7, numeric: true)],
///   rows: [[Text('#1482'), Text('main'), Text('2m 14s')]],
/// )
/// ```
class TermTable extends StatelessWidget {
  /// A table of [rows] under [columns].
  const TermTable({
    super.key,
    required this.columns,
    required this.rows,
    this.semanticLabel,
    this.style,
  });

  /// The columns.
  final List<TermColumn> columns;

  /// The rows, a widget per column.
  final List<List<Widget>> rows;

  /// What a screen reader calls the table.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.tableStyle]: `foreground`
  /// (the cells) and `edge` (the rule under the headings).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.tableStyle], const {});
    final gap = SizedBox(width: grid.cols(2));
    Widget line(List<Widget> cells, {Decoration? decoration}) => Container(
      height: grid.lineHeight,
      decoration: decoration,
      child: Row(
        children: [
          for (var i = 0; i < columns.length; i++) ...[
            if (i > 0) gap,
            _cell(grid, columns[i].cols, columns[i].numeric, cells[i]),
          ],
        ],
      ),
    );
    final table = DefaultTextStyle.merge(
      style: TextStyle(color: own.foreground ?? theme.foreground),
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            child: line(
              [
                for (final c in columns)
                  Text(
                    c.label,
                    style: theme.boldStyle.copyWith(color: theme.dim),
                  ),
              ],
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: own.edge ?? theme.rule,
                    width: termStroke(theme, grid),
                  ),
                ),
              ),
            ),
          ),
          for (final r in rows) Semantics(container: true, child: line(r)),
        ],
      ),
    );
    final fixed = columns.every((c) => c.cols != null);
    final Widget body = fixed
        ? LayoutBuilder(
            builder: (context, c) {
              var cols = 0;
              for (final col in columns) {
                cols += col.cols!;
              }
              cols += 2 * (columns.length - 1);
              final width = grid.cols(cols);
              if (!c.maxWidth.isFinite || width <= c.maxWidth) {
                return SizedBox(width: width, child: table);
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: width, child: table),
              );
            },
          )
        : table;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: body,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('columns', columns.length))
      ..add(IntProperty('rows', rows.length));
  }
}

/// A table you work in, on [DesignDataTable]: headings that sort when
/// pressed (`↑` or `↓` after the one sorted), rows that select with a
/// press or Space (`[x]` in the first column) and open with Enter, the
/// arrows moving a `>` down the rows, one tab stop for them all. The
/// page's rows come from the [controller]: its filter, sort and page.
///
/// ```dart
/// TermDataTable<Map<String, String>>(
///   controller: table,
///   widths: const {'id': 6, 'took': 7},
///   cellBuilder: (context, run, column) => Text(run[column.id] ?? ''),
/// )
/// ```
class TermDataTable<R> extends StatelessWidget {
  /// A table of [controller]'s page.
  const TermDataTable({
    super.key,
    required this.controller,
    required this.cellBuilder,
    this.widths = const {},
    this.selectable = true,
    this.onActivate,
    this.style,
  });

  /// The rows, the columns and the view of them. The caller makes it,
  /// keeps it and disposes it.
  final DesignTableController<R> controller;

  /// A cell's words.
  final Widget Function(
    BuildContext context,
    R row,
    DesignTableColumn<R> column,
  )
  cellBuilder;

  /// Columns' widths in cells, by column id; a column without one takes a
  /// share of the rest.
  final Map<String, int> widths;

  /// Whether rows select.
  final bool selectable;

  /// A row's Enter, or its press when the table does not select.
  final ValueChanged<R>? onActivate;

  /// Overrides, over the theme's [TermThemeData.tableStyle]: `fill` (a
  /// selected row), `foreground` (the cells) and `edge` (the rule under
  /// the headings).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final rule = TermStyleOf([style, theme.tableStyle], const {}).edge;
    List<Widget> laid(List<Widget> cells, {Widget? lead}) {
      final cols = controller.columns;
      return [
        SizedBox(width: grid.cols(2), child: lead),
        if (selectable) SizedBox(width: grid.cols(4), child: null),
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) SizedBox(width: grid.cols(2)),
          _cell(grid, widths[cols[i].id], cols[i].numeric, cells[i]),
        ],
      ];
    }

    Widget mark(String m, Color ink) =>
        Text(m, style: theme.textStyle.copyWith(color: ink));

    return DefaultTextStyle.merge(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
      child: DesignDataTable<R>(
        controller: controller,
        selectable: selectable,
        onActivate: onActivate,
        headerBuilder: (context, column, sort, states) {
          final lit =
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed);
          final words =
              '${column.label}${switch (sort) {
                DesignSortDirection.ascending => ' ↑',
                DesignSortDirection.descending => ' ↓',
                null => '',
              }}';
          // A heading is one line; what a tap reaches is the floor (a
          // finger's five cells and two lines), the words at its start, or
          // at its end over numbers.
          return TermTapTarget(
            alignment: column.numeric
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: ColoredBox(
              color: lit ? theme.foreground : _clear,
              child: Text(
                words,
                style: theme.boldStyle.copyWith(
                  color: lit
                      ? theme.background
                      : sort != null
                      ? theme.foreground
                      : theme.dim,
                  decoration: column.sortable && !lit
                      ? TextDecoration.underline
                      : null,
                  decorationColor: theme.rule,
                ),
              ),
            ),
          );
        },
        headerRowBuilder: (context, cells) {
          final row = laid(cells);
          final height = _touch(context) ? grid.lines(2) : grid.lineHeight;
          if (selectable) {
            final page = controller.pageSelection;
            // The page's box reaches over the cursor's column before it, so
            // a finger has six cells of it.
            row[0] = const SizedBox.shrink();
            row[1] = SizedBox(
              width: grid.cols(6),
              height: height,
              child: DesignPressable(
                onPressed: controller.togglePage,
                checked: page == DesignSelection.all,
                semanticLabel: 'select page',
                excludeSemantics: true,
                mouseCursor: SystemMouseCursors.click,
                builder: (context, states, _) => Padding(
                  padding: EdgeInsetsDirectional.only(start: grid.cols(2)),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: mark(
                      switch (page) {
                        DesignSelection.all => '[x]',
                        DesignSelection.some => '[-]',
                        DesignSelection.none => '[ ]',
                      },
                      states.contains(WidgetState.focused)
                          ? theme.accent
                          : theme.dim,
                    ),
                  ),
                ),
              ),
            );
          }
          return Container(
            height: height,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: rule ?? theme.rule,
                  width: termStroke(theme, grid),
                ),
              ),
            ),
            child: Row(children: row),
          );
        },
        cellBuilder: (context, row, column) =>
            cellBuilder(context, row, column),
        rowBuilder: (context, row, cells) {
          final own = TermStyleOf([style, theme.tableStyle], row.states);
          final focused = row.states.contains(WidgetState.focused);
          final pressed = row.states.contains(WidgetState.pressed);
          final ground = row.selected || pressed
              ? own.fill ?? termRowShade(theme)
              : _clear;
          final out = laid(
            cells,
            lead: focused ? mark('>', theme.accent) : null,
          );
          if (selectable) {
            out[1] = SizedBox(
              width: grid.cols(4),
              child: mark(
                row.selected ? '[x]' : '[ ]',
                row.selected ? theme.accent : theme.dim,
              ),
            );
          }
          return ColoredBox(
            color: ground,
            child: SizedBox(
              height: _touch(context) ? grid.lines(2) : grid.lineHeight,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: own.foreground ?? theme.foreground),
                child: Row(children: out),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The shade a selected row sits on: the rule's ink, faint, over the
/// background.
Color termRowShade(TermThemeData theme) =>
    Color.alphaBlend(theme.rule.withValues(alpha: 0.35), theme.background);

/// A rule across the line (or down it, [TermDivider.vertical]), at the
/// theme's stroke; with [label], `label ──────`.
///
/// ```dart
/// const TermDivider(label: 'older')
/// ```
class TermDivider extends StatelessWidget {
  /// A rule across the line.
  const TermDivider({super.key, this.label, this.style})
    : axis = Axis.horizontal;

  /// A rule down a cell's middle, for between columns.
  const TermDivider.vertical({super.key, this.style})
    : axis = Axis.vertical,
      label = null;

  /// Which way it runs.
  final Axis axis;

  /// Dim words at its start, or null.
  final String? label;

  /// Overrides, over the theme's [TermThemeData.dividerStyle]: `edge` (the
  /// rule) and `foreground` (its label).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.dividerStyle], const {});
    final rule = _Rule(
      color: own.edge ?? theme.rule,
      stroke: termStroke(theme, grid),
      axis: axis,
    );
    if (axis == Axis.vertical) {
      return ExcludeSemantics(
        child: SizedBox(width: grid.cellWidth, child: rule),
      );
    }
    return SizedBox(
      height: grid.lineHeight,
      child: label == null
          ? ExcludeSemantics(child: rule)
          : Row(
              children: [
                Text(
                  label!,
                  style: theme.textStyle.copyWith(
                    color: own.foreground ?? theme.dim,
                  ),
                ),
                SizedBox(width: grid.cellWidth),
                Expanded(child: ExcludeSemantics(child: rule)),
              ],
            ),
    );
  }
}

/// [child], a scroll view on [controller], with a bar one cell wide down
/// its end: a light rule for the track, a block for the thumb, lit in the
/// accent while held; it shows while scrolling and under a pointer, and
/// steps off rather than fade.
///
/// ```dart
/// TermScrollArea(
///   controller: scroll,
///   child: ListView(controller: scroll, children: lines),
/// )
/// ```
class TermScrollArea extends StatelessWidget {
  /// A scroll area round [child].
  const TermScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.visibility = DesignScrollbarVisibility.auto,
    this.semanticLabel,
    this.style,
  });

  /// The scroll view's controller.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// When the bar shows.
  final DesignScrollbarVisibility visibility;

  /// What a screen reader calls the area.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.scrollbarStyle]: `fill`
  /// (the thumb) and `edge` (the track).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      visibility: visibility,
      semanticLabel: semanticLabel,
      timeToFade: const Duration(milliseconds: 900),
      thickness: axis == Axis.vertical ? grid.cellWidth : grid.lineHeight / 2,
      minThumbLength: grid.lineHeight,
      thumbBuilder: (context, thumb) {
        if (!thumb.visible) return const SizedBox.shrink();
        final own = TermStyleOf([style, theme.scrollbarStyle], thumb.states);
        final held = thumb.states.contains(WidgetState.pressed);
        return ColoredBox(color: held ? theme.accent : own.fill ?? theme.dim);
      },
      trackBuilder: (context, thumb) {
        if (!thumb.visible) return const SizedBox.shrink();
        final own = TermStyleOf([style, theme.scrollbarStyle], thumb.states);
        return _Rule(
          color: own.edge ?? theme.rule,
          stroke: termStroke(theme, grid),
          axis: axis == Axis.vertical ? Axis.vertical : Axis.horizontal,
        );
      },
      child: child,
    );
  }
}

/// [child], a vertical scroll view, given whole lines of the height it is
/// offered (what is left over stays empty under it) and brought to rest on
/// a whole line after every scroll, so its edges cut between lines, never
/// through one, as a terminal's window does.
///
/// ```dart
/// TermWholeLines(child: ListView(children: lines))
/// ```
class TermWholeLines extends StatelessWidget {
  /// Whole lines of [child].
  const TermWholeLines({super.key, required this.child});

  /// The scroll view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final lh = grid.lineHeight;
    final view = NotificationListener<ScrollEndNotification>(
      onNotification: (end) {
        final m = end.metrics;
        final at = end.context;
        if (m.axis != Axis.vertical || at == null) return false;
        final line = (m.pixels / lh).round() * lh;
        final to = line.clamp(m.minScrollExtent, m.maxScrollExtent);
        if ((to - m.pixels).abs() < 0.5) return false;
        Scrollable.maybeOf(at)?.position
            .animateTo(to, duration: TermMotion.screen, curve: Curves.easeOut);
        return false;
      },
      child: child,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) return view;
        // As tall as the view wants, up to whole lines of the room; as wide
        // as it was offered. Any height left over stays empty under it.
        return Align(
          alignment: AlignmentDirectional.topStart,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.minWidth,
              maxWidth: constraints.maxWidth,
              maxHeight: grid.lines(grid.linesIn(constraints.maxHeight)),
            ),
            child: view,
          ),
        );
      },
    );
  }
}

/// Two panes split by a rule you drag, a cell wide: the rule turns heavy
/// and takes the accent while held, focused or under a pointer; the
/// arrows move it a step, as tmux resizes a pane.
///
/// ```dart
/// TermSplitView(first: files, second: preview, initialFraction: 0.3)
/// ```
class TermSplitView extends StatelessWidget {
  /// [first] and [second], side by side (or stacked, [axis] vertical).
  const TermSplitView({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = 0.5,
    this.onChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.semanticLabel,
    this.style,
  });

  /// The first pane: the start (or top).
  final Widget first;

  /// The second pane.
  final Widget second;

  /// Side by side, or stacked.
  final Axis axis;

  /// The first pane's share, when the app holds it.
  final double? fraction;

  /// Its share at first, when the view holds it.
  final double initialFraction;

  /// Called with each new share.
  final ValueChanged<double>? onChanged;

  /// The least the first pane may have, in pixels.
  final double minFirst;

  /// The least the second may have.
  final double minSecond;

  /// What a screen reader calls the divider.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.splitViewStyle]: `edge`
  /// (the rule) and `fill` (the rule while held).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final across = axis == Axis.horizontal ? grid.cellWidth : grid.lineHeight;
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      fraction: fraction,
      initialFraction: initialFraction,
      onChanged: onChanged,
      minFirst: minFirst,
      minSecond: minSecond,
      semanticLabel: semanticLabel,
      dividerThickness: across,
      hitExtent: math.max(across, 24),
      dividerBuilder: (context, states, axis) {
        final own = TermStyleOf([style, theme.splitViewStyle], states);
        final held =
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused);
        final stroke = termStroke(theme, grid);
        return MouseRegion(
          cursor: axis == Axis.horizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          child: _Rule(
            color: held ? own.fill ?? theme.accent : own.edge ?? theme.rule,
            stroke: held ? stroke * 2 : stroke,
            axis: axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
          ),
        );
      },
    );
  }
}

/// A list you put in order: each row a `≡` handle and its words; drag the
/// handle (or long-press the row on a phone), or use the row's move up and
/// move down actions. The row on the move is drawn raised, framed in the
/// accent.
///
/// ```dart
/// TermReorderableList<String>(
///   items: steps,
///   labelOf: (s) => s,
///   onReorder: (from, to) => setState(() => steps.insert(to, steps.removeAt(from))),
/// )
/// ```
class TermReorderableList<T extends Object> extends StatelessWidget {
  /// A list of [items] in order.
  const TermReorderableList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.labelOf,
    this.itemBuilder,
    this.keyOf,
    this.shrinkWrap = false,
    this.style,
  });

  /// The items, in order.
  final List<T> items;

  /// Called with an item's move.
  final void Function(int from, int to) onReorder;

  /// An item's words, and what a screen reader calls it.
  final String Function(T item) labelOf;

  /// An item's row after its handle; null: its words.
  final Widget Function(BuildContext context, T item)? itemBuilder;

  /// Tells items apart across moves.
  final Object Function(T item)? keyOf;

  /// Whether the list is only as tall as its items.
  final bool shrinkWrap;

  /// Overrides, over the theme's [TermThemeData.listTileStyle]: `fill` (the
  /// row on the move), `foreground` (the words) and `edge` (its frame).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.listTileStyle], const {});
    return DesignReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      keyOf: keyOf,
      shrinkWrap: shrinkWrap,
      itemBuilder: (context, item, reorder) => SizedBox(
        height: _touch(context) ? grid.lines(2) : grid.lineHeight,
        child: Row(
          children: [
            reorder.handle(
              MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: SizedBox(
                  width: grid.cols(3),
                  child: Center(
                    child: Text(
                      '≡',
                      style: theme.textStyle.copyWith(color: theme.dim),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child:
                  itemBuilder?.call(context, item) ??
                  Text(
                    labelOf(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(
                      color: own.foreground ?? theme.foreground,
                    ),
                  ),
            ),
          ],
        ),
      ),
      proxyDecorator: (child, index, animation) => DecoratedBox(
        decoration: BoxDecoration(
          color: own.fill ?? theme.surface,
          border: Border.all(
            color: own.edge ?? theme.accent,
            width: termStroke(theme, grid),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A scroll view refreshed by a pull: one line over the list says what
/// the pull will do (`↓ pull to refresh`, `↑ let go to refresh`), then the
/// spinner while it works and `✓ up to date` once done.
///
/// ```dart
/// TermPullToRefresh(onRefresh: reload, child: ListView(children: rows))
/// ```
class TermPullToRefresh extends StatelessWidget {
  /// [child], refreshed by [onRefresh].
  const TermPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.style,
  });

  /// Refreshes; the line shows until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  /// Overrides, over the theme's [TermThemeData.spinnerStyle]:
  /// `foreground` (the spinner and the words).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final ink =
        TermStyleOf([style, theme.spinnerStyle], const {}).foreground ??
        theme.accent;
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      triggerDistance: grid.lines(3),
      restExtent: grid.lines(2),
      child: child,
      indicatorBuilder: (context, details) {
        final words = switch (details.mode) {
          DesignRefreshMode.inactive => null,
          DesignRefreshMode.drag => ('↓', 'pull to refresh', theme.dim),
          DesignRefreshMode.armed => ('↑', 'let go to refresh', ink),
          DesignRefreshMode.refresh => (null, 'refreshing', ink),
          DesignRefreshMode.done => ('✓', 'up to date', theme.success),
        };
        if (words == null) return const SizedBox.shrink();
        return SizedBox(
          height: details.extent,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: grid.lines(2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (words.$1 == null)
                      TermSpinner(color: ink)
                    else
                      Text(
                        words.$1!,
                        style: theme.textStyle.copyWith(color: words.$3),
                      ),
                    SizedBox(width: grid.cellWidth),
                    Text(
                      words.$2,
                      style: theme.textStyle.copyWith(color: words.$3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A tree as `tree` prints one: `├─` and `└─` before each node, `│`
/// carrying each open branch down, `▸` or `▾` on a node with children;
/// the keyboard's row in inverse video, the chosen in bold accent. The
/// arrows walk it (→ opens, ← closes or climbs), Enter opens a leaf.
///
/// ```dart
/// TermTree<String>(controller: tree, labelOf: (path) => path.split('/').last)
/// ```
class TermTree<T extends Object> extends StatelessWidget {
  /// A tree of [controller]'s nodes.
  const TermTree({
    super.key,
    required this.controller,
    required this.labelOf,
    this.onActivate,
    this.semanticLabel,
    this.style,
  });

  /// The nodes, which are open and which chosen. The caller makes it,
  /// keeps it and disposes it.
  final DesignTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A leaf's Enter or press.
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls the tree.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.treeStyle]: `fill` (the
  /// keyboard's row), `foreground` (the names) and `edge` (the guides).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final byNode = {for (final r in controller.rows) r.node: r};
        bool last(DesignTreeRow<T> r) => r.position == r.siblingCount - 1;
        String guides(DesignTreeRow<T> row) {
          if (row.depth == 0) return '';
          final out = <String>[last(row) ? '└─' : '├─'];
          var up = row.parent == null ? null : byNode[row.parent];
          while (up != null && up.depth > 0) {
            out.add(last(up) ? '  ' : '│ ');
            up = up.parent == null ? null : byNode[up.parent];
          }
          return out.reversed.join();
        }

        return DesignTree<T>(
          controller: controller,
          labelOf: labelOf,
          onActivate: onActivate,
          semanticLabel: semanticLabel,
          rowBuilder: (context, item) {
            final own = TermStyleOf([style, theme.treeStyle], item.states);
            final lit =
                item.states.contains(WidgetState.focused) ||
                item.states.contains(WidgetState.pressed);
            final ink = own.foreground ?? theme.foreground;
            final name = item.selected ? theme.accent : ink;
            return SizedBox(
              height: _touch(context) ? grid.lines(2) : grid.lineHeight,
              child: Row(
                children: [
                  Text(
                    guides(item.row),
                    style: theme.textStyle.copyWith(
                      color: own.edge ?? theme.rule,
                    ),
                  ),
                  SizedBox(
                    width: grid.cols(2),
                    child: item.hasChildren
                        ? GestureDetector(
                            onTap: item.toggle,
                            child: Text(
                              item.expanded ? '▾' : '▸',
                              style: theme.textStyle.copyWith(color: theme.dim),
                            ),
                          )
                        : null,
                  ),
                  Flexible(
                    child: ColoredBox(
                      color: lit ? own.fill ?? ink : _clear,
                      child: Text(
                        labelOf(item.row.node),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (item.selected ? theme.boldStyle : theme.textStyle)
                                .copyWith(color: lit ? theme.background : name),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// One entry of a [TermTimeline].
@immutable
class TermTimelineEntry {
  /// An entry titled [title] at [time].
  const TermTimelineEntry({
    required this.title,
    this.time,
    this.detail,
    this.tone = TermTone.neutral,
  });

  /// What happened.
  final String title;

  /// When, as the app writes it (`14:02`, `2m ago`).
  final String? time;

  /// More, dim, under the title.
  final String? detail;

  /// Its mark: the tone's glyph in its ink.
  final TermTone tone;
}

/// What happened, in order: the time dim at the start, each entry's mark
/// (`✓`, `✗`, `!`, `·`) in its tone's ink on a rule that runs down to the
/// next, the title and its detail after.
///
/// ```dart
/// TermTimeline(entries: const [
///   TermTimelineEntry(time: '14:02', title: 'build passed', tone: TermTone.success),
///   TermTimelineEntry(time: '14:05', title: 'deploy started'),
/// ])
/// ```
class TermTimeline extends StatelessWidget {
  /// A timeline of [entries].
  const TermTimeline({super.key, required this.entries, this.style});

  /// The entries, oldest first (or as the app orders them).
  final List<TermTimelineEntry> entries;

  /// Overrides, over the theme's [TermThemeData.timelineStyle]:
  /// `foreground` (the titles) and `edge` (the rule between marks).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.timelineStyle], const {});
    var timeCols = 0;
    for (final e in entries) {
      timeCols = math.max(timeCols, e.time?.characters.length ?? 0);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, e) in entries.indexed)
          Semantics(
            container: true,
            label: [?e.time, e.title, ?e.detail].join(', '),
            excludeSemantics: true,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (timeCols > 0)
                    SizedBox(
                      width: grid.cols(timeCols + 1),
                      child: Text(e.time ?? '', style: theme.dimStyle),
                    ),
                  SizedBox(
                    width: grid.cols(2),
                    child: Column(
                      children: [
                        SizedBox(
                          height: grid.lineHeight,
                          child: Text(
                            e.tone.glyph,
                            style: theme.boldStyle.copyWith(
                              color: e.tone == TermTone.neutral
                                  ? theme.foreground
                                  : e.tone.colorIn(theme),
                            ),
                          ),
                        ),
                        if (i < entries.length - 1)
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: SizedBox(
                                width: grid.cellWidth,
                                child: _Rule(
                                  color: own.edge ?? theme.rule,
                                  stroke: termStroke(theme, grid),
                                  axis: Axis.vertical,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < entries.length - 1 ? grid.lineHeight : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title,
                            style: theme.textStyle.copyWith(
                              color: own.foreground ?? theme.foreground,
                            ),
                          ),
                          if (e.detail != null)
                            Text(e.detail!, style: theme.dimStyle),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

const _avatarSlots = [
  TermAnsi.red,
  TermAnsi.green,
  TermAnsi.yellow,
  TermAnsi.blue,
  TermAnsi.magenta,
  TermAnsi.cyan,
];

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = [for (final w in words.take(2)) w.characters.first];
  return letters.join().toUpperCase();
}

/// Someone, as their initials in bold on a block of colour picked from
/// the palette by their name (the same name, the same colour), a cell
/// either side: ` AL `. [lines] 2 makes it two lines tall for a profile.
///
/// ```dart
/// TermAvatar(name: 'Ada Lovelace')
/// ```
class TermAvatar extends StatelessWidget {
  /// [name]'s avatar.
  const TermAvatar({super.key, required this.name, this.lines = 1, this.style})
    : assert(lines == 1 || lines == 2, 'An avatar is one line or two.');

  /// Whose it is.
  final String name;

  /// One line, or two.
  final int lines;

  /// Overrides, over the theme's [TermThemeData.avatarStyle]: `fill` (the
  /// block) and `foreground` (the initials).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.avatarStyle], const {});
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    final ground =
        own.fill ?? _avatarSlots[hash % _avatarSlots.length].of(theme.palette);
    final words =
        own.foreground ??
        (termContrast(theme.background, ground) >=
                termContrast(theme.foreground, ground)
            ? theme.background
            : theme.foreground);
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: ColoredBox(
        color: ground,
        child: SizedBox(
          width: grid.cols(4),
          height: grid.lines(lines),
          child: Center(
            child: Text(
              _initials(name),
              style: theme.boldStyle.copyWith(color: words),
            ),
          ),
        ),
      ),
    );
  }
}

/// A few people side by side, a cell apart, and `+3` for the rest.
///
/// ```dart
/// TermAvatarGroup(names: const ['Ada Lovelace', 'Alan Turing', 'Grace Hopper'])
/// ```
class TermAvatarGroup extends StatelessWidget {
  /// The avatars of [names].
  const TermAvatarGroup({
    super.key,
    required this.names,
    this.max = 4,
    this.style,
  });

  /// Who.
  final List<String> names;

  /// The most shown; the rest are counted.
  final int max;

  /// Overrides for each avatar, over the theme's
  /// [TermThemeData.avatarStyle].
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final shown = names.take(max).toList();
    final rest = names.length - shown.length;
    return Semantics(
      label: '${names.length} people: ${names.join(', ')}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, n) in shown.indexed) ...[
            if (i > 0) SizedBox(width: grid.cellWidth),
            TermAvatar(name: n, style: style),
          ],
          if (rest > 0) ...[
            SizedBox(width: grid.cellWidth),
            Text('+$rest', style: theme.dimStyle),
          ],
        ],
      ),
    );
  }
}

/// A picture in a box-drawn frame, whole cells wide and [lines] tall,
/// [caption] set into the top line; until it loads (or if it can't), a
/// shade with its [alt] words dim in the middle.
///
/// ```dart
/// TermMedia(image: NetworkImage(url), alt: 'the deploy graph', lines: 10)
/// ```
class TermMedia extends StatelessWidget {
  /// A picture from [image] (or the app's media [slotId]).
  const TermMedia({
    super.key,
    this.image,
    this.slotId,
    required this.alt,
    this.caption,
    this.lines = 8,
    this.fit = BoxFit.cover,
    this.style,
  }) : assert(
         (image == null) != (slotId == null),
         'A TermMedia shows an image or a media slot, one of the two.',
       );

  /// The picture.
  final ImageProvider? image;

  /// Or the app's media slot, by id.
  final String? slotId;

  /// What it shows, in words: for a screen reader, and shown until it
  /// loads.
  final String alt;

  /// Words set into the frame's top line, or null.
  final String? caption;

  /// Its height in lines, the frame's included.
  final int lines;

  /// How it fills the frame.
  final BoxFit fit;

  /// Overrides, over the theme's [TermThemeData.mediaStyle]: `fill` (the
  /// shade before it loads), `edge` (the frame) and `foreground` (the alt
  /// words).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.mediaStyle], const {});
    final cw = grid.cellWidth;
    final shade = ColoredBox(
      color: own.fill ?? termRowShade(theme),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: cw),
          child: Text(
            alt,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textStyle.copyWith(color: own.foreground ?? theme.dim),
          ),
        ),
      ),
    );
    final picture = image != null
        ? Image(
            image: image!,
            fit: fit,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, sync) =>
                frame == null && !sync ? shade : child,
            errorBuilder: (context, error, stack) => shade,
          )
        : MediaSlotImage(slotId: slotId!, fallback: shade, fit: fit);
    final wordsAt = cw * 2;
    return Semantics(
      image: true,
      label: alt,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth.isFinite
              ? grid.cols(grid.colsIn(c.maxWidth))
              : grid.cols(40);
          return SizedBox(
            width: width,
            height: grid.lines(lines),
            child: CustomPaint(
              foregroundPainter: TermFramePainter(
                grid: grid,
                color: own.edge ?? theme.rule,
                stroke: termStroke(theme, grid),
                textDirection: Directionality.of(context),
                topGaps: [
                  if (caption != null)
                    (
                      start: wordsAt - cw / 2,
                      end: wordsAt + grid.widthOf(caption!) + cw / 2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    left: cw / 2,
                    right: cw / 2,
                    top: grid.lineHeight / 2,
                    bottom: grid.lineHeight / 2,
                    child: ClipRect(child: picture),
                  ),
                  if (caption != null)
                    PositionedDirectional(
                      top: 0,
                      start: wordsAt,
                      child: ColoredBox(
                        color: theme.background,
                        child: Text(caption!, style: theme.dimStyle),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Terms and their values, as `key: value` pairs print: the terms dim in
/// a column as wide as the longest, a dotted leader to each value; on a
/// narrow screen, each value under its term.
///
/// ```dart
/// TermDescriptionList(items: const [('branch', 'main'), ('commit', '4f2a91c')])
/// ```
class TermDescriptionList extends StatelessWidget {
  /// A list of [items].
  const TermDescriptionList({super.key, required this.items, this.style});

  /// Each term and its value.
  final List<(String, String)> items;

  /// Overrides, over the theme's [TermThemeData.descriptionListStyle]:
  /// `foreground` (the values) and `edge` (the leaders).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.descriptionListStyle], const {});
    var termCols = 0;
    for (final (t, _) in items) {
      termCols = math.max(termCols, t.characters.length);
    }
    final valueStyle = theme.textStyle.copyWith(
      color: own.foreground ?? theme.foreground,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final narrow =
            c.maxWidth.isFinite && grid.colsIn(c.maxWidth) < termCols + 20;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (t, v) in items)
              Semantics(
                container: true,
                label: '$t: $v',
                excludeSemantics: true,
                child: narrow
                    ? Padding(
                        padding: EdgeInsets.only(bottom: grid.lineHeight / 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t, style: theme.dimStyle),
                            Text(v, style: valueStyle),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: grid.cols(termCols + 3),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: t, style: theme.dimStyle),
                                  TextSpan(
                                    text:
                                        ' ${'·' * (termCols + 1 - t.characters.length)}',
                                    style: theme.textStyle.copyWith(
                                      color: own.edge ?? theme.rule,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          Expanded(child: Text(v, style: valueStyle)),
                        ],
                      ),
              ),
          ],
        );
      },
    );
  }
}
