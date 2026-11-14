// Round 4's containers: a data table, a scroll area, resizable panes, a reorderable list, swipe actions, pull to
// refresh, a tree, a timeline, a tag and a status view. The first seven stand on ui_core's behaviour (sorting, paging,
// selection, the scroll bar, the divider's drag, reordering, the swipe, the pull, the tree's keys); the last three are
// paint. This file draws them in Retro Desktop's hand: lists in white wells, the machine's grey for headers and grips.
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:ui_core/ui_core.dart';

import 'chrome.dart';
import 'component_themes.dart';
import 'controls.dart';
import 'glyphs.dart';
import 'internal/face.dart';
import 'internal/parts.dart';
import 'layout.dart' show RetroDesktopReach, retroDesktopOwnSize;
import 'localizations.dart';
import 'pixels.dart';
import 'press.dart';
import 'tell.dart';
import 'theme.dart';
import 'wayfinding.dart';
import 'internal/caps.dart';

BorderSide _rule(RetroDesktopThemeData t) => BorderSide(
  color: t.colors.divider,
  width: t.strokes.hairline == 0 ? 1 : t.strokes.hairline,
);

/// A table you can sort, select from and page through: a column's head sorts
/// it (again reverses it), the boxes choose rows, the pages step it. ui_core's
/// data table carries the sort, the selection, the paging and the keys; the
/// look draws the white well, the grey header and the lit rows.
///
/// ```dart
/// RetroDesktopDataTable<Map<String, String>>(controller: orders, cellText: (row, column) => row[column.id] ?? '')
/// ```
class RetroDesktopDataTable<R> extends StatelessWidget {
  /// Creates a [RetroDesktopDataTable].
  const RetroDesktopDataTable({
    super.key,
    required this.controller,
    required this.cellText,
    this.selectable = true,
    this.onActivate,
    this.selectLabel,
    this.selectAllLabel,
  });

  /// The rows, columns, sort, page and selection; the caller disposes it.
  final DesignTableController<R> controller;

  /// A cell's words.
  final String Function(R row, DesignTableColumn<R> column) cellText;

  /// Whether rows can be chosen with boxes.
  final bool selectable;

  /// Called when a row is opened (Enter, or a double press).
  final ValueChanged<R>? onActivate;

  /// The boxes' names for a screen reader.
  final String? selectLabel, selectAllLabel;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    Widget box(Widget child) => SizedBox(
      width: math.max(40, RetroDesktopReach.least(context)),
      child: Center(child: child),
    );
    final table = DesignDataTable<R>(
      controller: controller,
      selectable: selectable,
      onActivate: onActivate,
      headerRowBuilder: (context, cells) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.platinumLight,
          border: Border(bottom: BorderSide(color: c.outline)),
        ),
        // The rule under the heads stands below them, not inside each head's box: inside, a sorted head's mark and
        // the rule read as one face whose middle stood 11 px below the words.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selectable)
                  box(
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) {
                        final all = controller.pageSelection;
                        return RetroDesktopCheckbox(
                          label:
                              selectAllLabel ??
                              RetroDesktopLocalizations.of(context)
                                  .selectAllRows,
                          value: all == DesignSelection.all
                              ? true
                              : all == DesignSelection.none
                              ? false
                              : null,
                          onChanged: (_) => controller.togglePage(),
                        );
                      },
                    ),
                  ),
                for (final cell in cells) Expanded(child: cell),
              ],
            ),
          ),
        ),
      ),
      headerBuilder: (context, column, sort, states) => RetroDesktopHighlight(
        shape: const RoundedRectangleBorder(),
        focused: states.contains(WidgetState.focused),
        inside: true,
        child: retroDesktopHeldGround(
          t,
          held: states.contains(WidgetState.pressed),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            // On the head row's middle line in a head stretched to its row, whichever head stands tallest.
            child: Align(
              alignment: column.numeric
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: RetroDesktopCaps(
                      style: t.type.chrome,
                      Text(
                        column.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.type.chrome.copyWith(color: c.text),
                      ),
                    ),
                  ),
                  if (sort != null) ...[
                    const SizedBox(width: 6),
                    RetroDesktopTriangleMark(
                      sort == DesignSortDirection.ascending
                          ? AxisDirection.up
                          : AxisDirection.down,
                      size: 8,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      cellBuilder: (context, row, column) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Align(
          alignment: column.numeric
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Text(
            cellText(row, column),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      rowBuilder: (context, row, cells) {
        final lit = row.selected;
        return RetroDesktopHighlight(
          shape: const RoundedRectangleBorder(),
          focused: row.states.contains(WidgetState.focused),
          inside: true,
          child: retroDesktopHeldGround(
            t,
            held: !lit && row.states.contains(WidgetState.pressed),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lit ? c.highlight : null,
                border: Border(bottom: _rule(t)),
              ),
              child: DefaultTextStyle.merge(
                style: t.type.body.copyWith(
                  color: lit ? c.onHighlight : c.text,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (selectable)
                        box(
                          RetroDesktopCheckbox(
                            label:
                                selectLabel ??
                                RetroDesktopLocalizations.of(context).selectRow,
                            value: row.selected,
                            onChanged: (_) => row.toggle(),
                          ),
                        ),
                      for (final cell in cells) Expanded(child: cell),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        retroDesktopSunkenBox(
          context,
          states: const {},
          padding: EdgeInsets.zero,
          child: table,
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.pageCount <= 1
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: RetroDesktopPagination(
                      count: controller.pageCount,
                      page: controller.page,
                      onChanged: controller.goToPage,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// The period's scroll bar beside what scrolls: a grey track, a raised thumb
/// (Platinum's ridged one, Chisel's bevelled block). It stands while there is
/// more to see. ui_core's scroll area carries the drag, the track's press and
/// the keys.
///
/// ```dart
/// RetroDesktopScrollArea(controller: scroll, child: ListView(controller: scroll, children: rows))
/// ```
class RetroDesktopScrollArea extends StatelessWidget {
  /// Creates a [RetroDesktopScrollArea].
  const RetroDesktopScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.label,
    this.focusNode,
    this.autofocus = false,
  });

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The scroll view's controller; the caller disposes it.
  final ScrollController controller;

  /// The scroll view, on [controller].
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// Its name for a screen reader.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      thickness: 16,
      visibility: DesignScrollbarVisibility.always,
      semanticLabel: label,
      focusNode: focusNode,
      autofocus: autofocus,
      frameBuilder: (context, focused, area) => RetroDesktopHighlight(
        shape: t.shapes.small,
        focused: focused,
        child: area,
      ),
      trackBuilder: (context, thumb) => DecoratedBox(
        decoration: BoxDecoration(
          color: t.chisel ? c.platinumLight : c.platinumDark,
          border: axis == Axis.vertical
              ? BorderDirectional(start: BorderSide(color: c.outline))
              : Border(top: BorderSide(color: c.outline)),
        ),
      ),
      thumbBuilder: (context, thumb) => retroDesktopFace(
        states: {
          if (thumb.states.contains(WidgetState.pressed)) WidgetState.pressed,
        },
        scale: RetroDesktopFaceScale.mark,
        gradient: LinearGradient(
          begin: axis == Axis.vertical
              ? Alignment.centerLeft
              : Alignment.topCenter,
          end: axis == Axis.vertical
              ? Alignment.centerRight
              : Alignment.bottomCenter,
          colors: [c.thumbTop, c.thumbBottom],
        ),
        component: const RetroDesktopStyle(),
        padding: EdgeInsets.zero,
        child: Center(
          child: t.chisel
              ? const SizedBox.shrink()
              : retroDesktopOwnSize(
                  width: 10,
                  height: 10,
                  child: CustomPaint(painter: _Ridges(c, axis)),
                ),
        ),
      ),
      child: child,
    );
  }
}

class _Ridges extends CustomPainter {
  const _Ridges(this.c, this.axis);
  final RetroDesktopColors c;
  final Axis axis;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final at = 2.0 + i * 3;
      final a = axis == Axis.vertical ? Offset(1, at) : Offset(at, 1);
      final b = axis == Axis.vertical
          ? Offset(size.width - 1, at)
          : Offset(at, size.height - 1);
      canvas.drawLine(a, b, Paint()..color = c.bevelDark);
    }
  }

  @override
  bool shouldRepaint(_Ridges old) => old.c != c || old.axis != axis;
}

/// Two panes and the bar between them that moves: drag it, or focus it and
/// use the arrows. The bar is the machine's grey with its grip. ui_core's
/// split view carries the drag, the keys and the limits.
///
/// ```dart
/// RetroDesktopResizable(first: folders, second: files, minFirst: 160, minSecond: 240)
/// ```
class RetroDesktopResizable extends StatelessWidget {
  /// Creates a [RetroDesktopResizable].
  const RetroDesktopResizable({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = .5,
    this.minFirst = 0,
    this.minSecond = 0,
    this.onChanged,
    this.label,
    this.focusNode,
    this.autofocus = false,
  });

  /// The bar's focus node; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the bar takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// The panes, start then end (or top then bottom).
  final Widget first, second;

  /// Which way they stand.
  final Axis axis;

  /// Where the bar starts, 0 to 1.
  final double initialFraction;

  /// The least each pane keeps.
  final double minFirst, minSecond;

  /// Reports where the bar moved to.
  final ValueChanged<double>? onChanged;

  /// The bar's name for a screen reader.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      initialFraction: initialFraction,
      minFirst: minFirst,
      minSecond: minSecond,
      onChanged: onChanged,
      dividerThickness: 6,
      hitExtent: math.max(12, RetroDesktopReach.least(context)),
      semanticLabel:
          label ?? DesignLocalizations.of(context).splitViewHandleLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      dividerBuilder: (context, states, axis) => RetroDesktopHighlight(
        shape: const RoundedRectangleBorder(),
        focused: states.contains(WidgetState.focused),
        child: retroDesktopHeldGround(
          t,
          held: states.contains(WidgetState.pressed),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.platinum,
              border: axis == Axis.horizontal
                  ? Border.symmetric(vertical: BorderSide(color: c.outline))
                  : Border.symmetric(horizontal: BorderSide(color: c.outline)),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: axis == Axis.horizontal ? 0 : 1,
                child: SizedBox(
                  width: 2,
                  height: 16,
                  child: ColoredBox(color: c.bevelDark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A list whose rows move the period's way: drag a row by its grip and a
/// dotted outline of it follows the pointer while a line shows where it will
/// land. Nothing moves until the drop, and a drop off the list leaves it as it
/// was. From the keyboard, focus a row and move it with Alt and the arrows.
/// ui_core's reorderable list carries the keys, the focus and the
/// announcement; the drag is the look's own.
///
/// ```dart
/// RetroDesktopReorderableListView<String>(items: steps, labelOf: (s) => s, itemBuilder: (context, s) => Text(s), onReorder: (from, to) {})
/// ```
class RetroDesktopReorderableListView<T extends Object> extends StatefulWidget {
  /// Creates a [RetroDesktopReorderableListView].
  const RetroDesktopReorderableListView({
    super.key,
    required this.items,
    required this.onReorder,
    required this.labelOf,
    required this.itemBuilder,
    this.keyOf,
    this.shrinkWrap = true,
    this.gripLabel,
  });

  /// The rows' values, in order.
  final List<T> items;

  /// Reports a move from one place to another; [to] counts the places after
  /// the row has left its own.
  final void Function(int from, int to) onReorder;

  /// A row's name for a screen reader.
  final String Function(T item) labelOf;

  /// A row's content; the grip stands at its end.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// A row's identity; null uses the value itself.
  final Object Function(T item)? keyOf;

  /// Whether the list takes only its rows' height.
  final bool shrinkWrap;

  /// The grip's name for a screen reader.
  final String? gripLabel;

  @override
  State<RetroDesktopReorderableListView<T>> createState() =>
      _ReorderableListState<T>();
}

class _ReorderableListState<T extends Object>
    extends State<RetroDesktopReorderableListView<T>> {
  // The list's box, and each row's by its key: where the pointer is over.
  final GlobalKey _list = GlobalKey();
  final Map<Object, GlobalKey> _rows = {};

  // The dragged row's key and size, while a drag is on.
  Object? _dragged;
  Size _grab = Size.zero;

  // Where the dragged row would land: a place from 0 (before the first row)
  // to the count (after the last), and the line's height in the list; null
  // while the pointer is off the list or the drop would change nothing.
  int? _place;
  double? _line;

  Object _keyOf(T item) => widget.keyOf?.call(item) ?? item;

  RenderBox? _box(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize ? box : null;
  }

  void _track(Offset pointer) {
    final list = _box(_list);
    final items = widget.items;
    final from = items.indexWhere((i) => _keyOf(i) == _dragged);
    int? place;
    double? line;
    if (list != null &&
        from >= 0 &&
        (Offset.zero & list.size)
            .inflate(24)
            .contains(list.globalToLocal(pointer))) {
      // The pointer lands below every row whose middle it has passed.
      var below = 0;
      Rect? edge;
      for (var i = 0; i < items.length; i++) {
        final row = _rows[_keyOf(items[i])];
        final box = row == null ? null : _box(row);
        if (box == null) continue;
        final at =
            list.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
        if (list.globalToLocal(pointer).dy > at.center.dy) {
          below = i + 1;
          edge = Rect.fromLTRB(at.left, at.bottom, at.right, at.bottom);
        } else if (i == below) {
          edge = Rect.fromLTRB(at.left, at.top, at.right, at.top);
        }
      }
      if (below != from && below != from + 1 && edge != null) {
        place = below;
        line = edge.top.clamp(1.0, math.max(1.0, list.size.height - 1));
      }
    }
    if (place != _place || line != _line) {
      setState(() {
        _place = place;
        _line = line;
      });
    }
  }

  void _drop() {
    if (!mounted) return;
    final items = widget.items;
    final from = items.indexWhere((i) => _keyOf(i) == _dragged);
    final place = _place;
    setState(() {
      _dragged = null;
      _place = null;
      _line = null;
    });
    if (from < 0 || place == null) return;
    final to = place > from ? place - 1 : place;
    final label = widget.labelOf(items[from]);
    widget.onReorder(from, to);
    if (MediaQuery.maybeSupportsAnnounceOf(context) ?? false) {
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          DesignLocalizations.of(context)
              .reorderableListMovedMessage(label, to + 1, items.length),
          Directionality.of(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final keys = {for (final item in widget.items) _keyOf(item)};
    _rows.removeWhere((key, _) => !keys.contains(key));
    final line = _line;
    return retroDesktopSunkenBox(
      context,
      states: const {},
      padding: EdgeInsets.zero,
      child: Stack(
        key: _list,
        fit: StackFit.passthrough,
        children: [
          DesignReorderableList<T>(
            items: widget.items,
            onReorder: widget.onReorder,
            labelOf: widget.labelOf,
            keyOf: widget.keyOf,
            shrinkWrap: widget.shrinkWrap,
            // Only the grip starts a drag, and the drag is the look's own:
            // rows never spring aside.
            longPressToDrag: false,
            // A row is a tab stop: the keyboard reaches it, rings it, and
            // moves it with Alt and the arrows (ui_core keeps the focus in it).
            itemBuilder: (context, item, r) {
              final key = _keyOf(item);
              final row = _rows.putIfAbsent(key, GlobalKey.new);
              return _ReorderRow(
                child: DecoratedBox(
                  key: row,
                  decoration: BoxDecoration(
                    color: c.paper,
                    border: r.index < r.count - 1
                        ? Border(bottom: _rule(t))
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DefaultTextStyle.merge(
                            style: t.type.body.copyWith(color: c.text),
                            child: widget.itemBuilder(context, item),
                          ),
                        ),
                        Draggable<Object>(
                          data: key,
                          hitTestBehavior: HitTestBehavior.opaque,
                          maxSimultaneousDrags:
                              _dragged == null || _dragged == key ? 1 : 0,
                          // The outline starts on the row, the pointer where
                          // it took hold.
                          dragAnchorStrategy: (draggable, context, pointer) {
                            final box = _box(row);
                            if (box == null) return Offset.zero;
                            _grab = box.size;
                            return box.globalToLocal(pointer);
                          },
                          feedback: Builder(
                            builder: (_) => RetroDesktopPixelPaint(
                              painter: _DragOutline(c.text),
                              child: SizedBox.fromSize(size: _grab),
                            ),
                          ),
                          onDragStarted: () => setState(() => _dragged = key),
                          onDragUpdate: (d) => _track(d.globalPosition),
                          onDragEnd: (_) => _drop(),
                          child: Semantics(
                            label:
                                widget.gripLabel ??
                                RetroDesktopLocalizations.of(context).reorder,
                            child: SizedBox.square(
                              dimension: 44,
                              child: Icon(
                                RetroDesktopGlyphs.menu,
                                size: 16,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (line != null)
            Positioned(
              left: 2,
              right: 2,
              top: line - 1,
              height: 2,
              child: IgnorePointer(
                child: RetroDesktopPixelPaint(painter: _Solid(c.text)),
              ),
            ),
        ],
      ),
    );
  }
}

// A dragged row's outline: one pixel on, one off, the row's size, as the
// period drew whatever was being dragged.
class _DragOutline extends RetroDesktopPixelPainter {
  const _DragOutline(this.ink);
  final Color ink;

  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    for (var x = 0.0; x < s.width; x += 2) {
      px.fill(Rect.fromLTWH(x, 0, 1, 1), ink);
      px.fill(Rect.fromLTWH(x, s.height - 1, 1, 1), ink);
    }
    for (var y = 2.0; y < s.height - 1; y += 2) {
      px.fill(Rect.fromLTWH(0, y, 1, 1), ink);
      px.fill(Rect.fromLTWH(s.width - 1, y, 1, 1), ink);
    }
  }

  @override
  bool shouldRepaint(_DragOutline o) => o.ink != ink;
}

// The insertion line: solid ink, whole pixels.
class _Solid extends RetroDesktopPixelPainter {
  const _Solid(this.ink);
  final Color ink;

  @override
  void paint(RetroDesktopPixelGrid px, Size s) => px.fill(Offset.zero & s, ink);

  @override
  bool shouldRepaint(_Solid o) => o.ink != ink;
}

// One reorderable row's tab stop: the ring inside its outline (outside, it
// would cross the next row and the list's well), drawn only when the keyboard
// brought the focus.
class _ReorderRow extends StatefulWidget {
  const _ReorderRow({required this.child});
  final Widget child;

  @override
  State<_ReorderRow> createState() => _ReorderRowState();
}

class _ReorderRowState extends State<_ReorderRow> {
  bool _ring = false;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    onShowFocusHighlight: (on) => setState(() => _ring = on),
    child: RetroDesktopHighlight(
      shape: retroDesktopItemShape(RetroDesktopTheme.of(context)),
      focused: _ring,
      inside: true,
      child: widget.child,
    ),
  );
}

/// A tree of folders and what is in them: triangles open and close a branch,
/// the arrows walk it, the chosen row lit. ui_core's tree carries the
/// expansion, the selection, the keys and the levels a screen reader hears.
///
/// ```dart
/// RetroDesktopTreeView<String>(controller: tree, labelOf: (name) => name)
/// ```
class RetroDesktopTreeView<T extends Object> extends StatelessWidget {
  /// Creates a [RetroDesktopTreeView].
  const RetroDesktopTreeView({
    super.key,
    required this.controller,
    required this.labelOf,
    this.iconOf,
    this.onActivate,
    this.label,
  });

  /// The roots, what is open and what is chosen; the caller disposes it.
  final DesignTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's glyph, if any.
  final IconData? Function(T node)? iconOf;

  /// Called when a node is opened (Enter, or a double press).
  final ValueChanged<T>? onActivate;

  /// The tree's name for a screen reader.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return retroDesktopSunkenBox(
      context,
      states: const {},
      padding: const EdgeInsets.all(2),
      child: DesignTree<T>(
        controller: controller,
        labelOf: labelOf,
        onActivate: onActivate,
        semanticLabel: label,
        rowBuilder: (context, item) {
          final lit = item.selected;
          final ink = lit ? c.onHighlight : c.text;
          final icon = iconOf?.call(item.row.node);
          return RetroDesktopHighlight(
            shape: retroDesktopItemShape(t),
            focused: item.states.contains(WidgetState.focused),
            inside: true,
            child: retroDesktopHeldGround(
              t,
              held: !lit && item.states.contains(WidgetState.pressed),
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: retroDesktopItemShape(t),
                  color: lit ? c.highlight : null,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: 4 + 18.0 * item.row.depth,
                    end: 8,
                  ),
                  child: SizedBox(
                    height: math.max(30, RetroDesktopReach.least(context)),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: item.hasChildren
                              ? ExcludeSemantics(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: item.toggle,
                                    child: Center(
                                      child: RetroDesktopTriangleMark(
                                        item.expanded
                                            ? AxisDirection.down
                                            : Directionality.of(context) ==
                                                  TextDirection.rtl
                                            ? AxisDirection.left
                                            : AxisDirection.right,
                                        // The folder list's disclosure size.
                                        size: 9,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (icon != null) ...[
                          Icon(icon, size: 16, color: ink),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            labelOf(item.row.node),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.type.body.copyWith(color: ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One step of a [RetroDesktopTimeline].
@immutable
class RetroDesktopTimelineEntry {
  /// Creates a [RetroDesktopTimelineEntry].
  const RetroDesktopTimelineEntry(
    this.title, {
    this.time,
    this.note,
    this.done = false,
    this.current = false,
  });

  /// What happened, or will.
  final String title;

  /// When, and a line more.
  final String? time, note;

  /// Whether it has happened.
  final bool done;

  /// Whether it is happening now.
  final bool current;
}

/// What happened, in order, down a line: each step a square on it, filled in
/// ink once done, lit while it is the one now, open while it is to come.
///
/// ```dart
/// RetroDesktopTimeline(entries: const [RetroDesktopTimelineEntry('Ordered', time: '9:02', done: true), RetroDesktopTimelineEntry('Packed', current: true), RetroDesktopTimelineEntry('Delivered')])
/// ```
class RetroDesktopTimeline extends StatelessWidget {
  /// Creates a [RetroDesktopTimeline].
  const RetroDesktopTimeline({super.key, required this.entries});

  /// The steps, first to last.
  final List<RetroDesktopTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          MergeSemantics(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The mark's own width: it stands on the column's edge,
                  // the words where they were.
                  SizedBox(
                    width: 10,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 1,
                          height: 6,
                          child: i == 0 ? null : ColoredBox(color: c.outline),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: ShapeDecoration(
                            color: entries[i].current
                                ? c.highlight
                                : entries[i].done
                                ? c.text
                                : c.paper,
                            shape: t.shapes.small.copyWith(
                              side: BorderSide(color: c.text),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: 1,
                            child: i == entries.length - 1
                                ? null
                                : ColoredBox(color: c.outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entries[i].title,
                                  style:
                                      (entries[i].current
                                              ? t.type.chrome
                                              : t.type.body)
                                          .copyWith(
                                            color:
                                                entries[i].done ||
                                                    entries[i].current
                                                ? c.text
                                                : c.textSecondary,
                                          ),
                                ),
                              ),
                              if (entries[i].time != null)
                                Text(entries[i].time!, style: t.type.meta),
                            ],
                          ),
                          if (entries[i].note != null)
                            Text(entries[i].note!, style: t.type.meta),
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

/// A small label on a thing: a category, a state, a count of kind. The
/// machine's grey in an outline, small words; it presses nothing (a
/// [RetroDesktopChip] does) and asks for nothing (a [RetroDesktopFlag] does).
///
/// ```dart
/// RetroDesktopTag('Draft', icon: RetroDesktopGlyphs.tag)
/// ```
class RetroDesktopTag extends StatelessWidget {
  /// Creates a [RetroDesktopTag].
  const RetroDesktopTag(this.label, {super.key, this.icon});

  /// The words on the tag.
  final String label;

  /// A glyph before them.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    // A tag is as wide as its words wherever it is set: a column that stretches its children drew it across a card.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: retroDesktopFace(
        states: const {},
        scale: RetroDesktopFaceScale.mark,
        component: t.badgeTheme.merge(
          RetroDesktopStyle(
            fill: WidgetStatePropertyAll(c.platinumLight),
            foreground: WidgetStatePropertyAll(c.text),
            textStyle: WidgetStatePropertyAll(t.type.small),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: c.text),
              const SizedBox(width: 4),
            ],
            RetroDesktopCaps(Text(label)),
          ],
        ),
      ),
    );
  }
}

/// Which state a [RetroDesktopStatusView] reports.
enum RetroDesktopStatus {
  /// Work under way.
  loading,

  /// Nothing to show yet.
  empty,

  /// Something went wrong.
  error,

  /// Done.
  success,
}

/// A page's or a pane's state while it has no content of its own: loading,
/// empty, failed or done, each in the look's own alert window. One part for
/// the four, so a page swaps its state and nothing else.
///
/// ```dart
/// RetroDesktopStatusView(status: RetroDesktopStatus.error, title: 'Could not load', onRetry: () {})
/// ```
class RetroDesktopStatusView extends StatelessWidget {
  /// Creates a [RetroDesktopStatusView].
  const RetroDesktopStatusView({
    super.key,
    required this.status,
    this.title,
    this.message,
    this.onRetry,
    this.action,
  }) : assert(
         title != null || status == RetroDesktopStatus.loading,
         'Only loading names itself; give empty, error and success a title.',
       );

  /// Which state it reports.
  final RetroDesktopStatus status;

  /// Its head and a line more; loading names itself when [title] is null,
  /// every other state needs one.
  final String? title, message;

  /// Tries again, on an error.
  final VoidCallback? onRetry;

  /// A button beside it.
  final Widget? action;

  @override
  Widget build(BuildContext context) => switch (status) {
    RetroDesktopStatus.loading => RetroDesktopLoadingState(
      title: title,
      message: message,
      action: action,
    ),
    RetroDesktopStatus.empty => RetroDesktopEmptyState(
      title: title!,
      message: message,
      action: action,
    ),
    RetroDesktopStatus.error => RetroDesktopErrorState(
      title: title!,
      message: message,
      onRetry: onRetry,
      action: action,
    ),
    RetroDesktopStatus.success => RetroDesktopSuccessState(
      title: title!,
      message: message,
      action: action,
    ),
  };
}
