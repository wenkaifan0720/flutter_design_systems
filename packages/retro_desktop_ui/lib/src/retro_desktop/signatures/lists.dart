// What a window lists: sorted columns, icons of folders and files, a tree with its shares, a checklist, a table, a document.
// Each stands flush in a window and brings its own well, so a window that holds one has nothing to pad.
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../press.dart';

import '../glyphs.dart';

import '../controls.dart';
import '../frames.dart';
import '../internal/face.dart' show RetroDesktopFaceScale, retroDesktopFace;
import '../layout.dart';
import '../acts.dart' show RetroDesktopButtonSize;
import '../pixels.dart';
import '../show.dart' show RetroDesktopDivider;
import '../theme.dart';
import '../localizations.dart';
import '../component_themes.dart';
import '../wayfinding.dart';
import '../internal/caps.dart';

// Keep specified columns readable on narrow screens by scrolling the full table, with the look's scroll bar under it:
// clipped at the frame with no bar, its last column read as cut off mid-word rather than as more to the side.
Widget _tableViewport({
  required double minimumWidth,
  required LayoutWidgetBuilder builder,
}) => _TableViewport(minimumWidth: minimumWidth, builder: builder);

class _TableViewport extends StatefulWidget {
  const _TableViewport({required this.minimumWidth, required this.builder});
  final double minimumWidth;
  final LayoutWidgetBuilder builder;
  @override
  State<_TableViewport> createState() => _TableViewportState();
}

class _TableViewportState extends State<_TableViewport> {
  final _scroll = ScrollController();
  // Bumped when the scroll view's extent is known or changes, which moves no pixels and so tells the controller nothing.
  final _metrics = ValueNotifier(0);
  @override
  void dispose() {
    _scroll.dispose();
    _metrics.dispose();
    super.dispose();
  }

  // The bar stands under the table in a column, not over it: a table's height is its rows', and a bar laid over the
  // content needs a box of fixed height around both.
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, room) {
      if (!room.hasBoundedWidth || room.maxWidth >= widget.minimumWidth) {
        return widget.builder(context, room);
      }
      return NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _metrics.value++;
          return false;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: widget.minimumWidth,
                child: LayoutBuilder(builder: widget.builder),
              ),
            ),
            _SidewaysBar(controller: _scroll, metrics: _metrics),
          ],
        ),
      );
    },
  );
}

/// The look's sideways scroll bar (the scroll area's track and thumb) under a table that scrolls sideways. The table's
/// scroll view carries the scroll's semantics and keys; the bar is for the eye and the pointer.
class _SidewaysBar extends StatelessWidget {
  const _SidewaysBar({required this.controller, required this.metrics});
  final ScrollController controller;
  final Listenable metrics;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: SizedBox(
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.chisel ? c.platinumLight : c.platinumDark,
            border: Border(top: BorderSide(color: c.outline)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: LayoutBuilder(
              builder: (context, box) => ListenableBuilder(
                listenable: Listenable.merge([controller, metrics]),
                builder: (context, _) {
                  if (!controller.hasClients ||
                      !controller.position.hasContentDimensions) {
                    return const SizedBox.expand();
                  }
                  final p = controller.position;
                  final whole = p.maxScrollExtent + p.viewportDimension;
                  final run = box.maxWidth;
                  final width = whole <= 0
                      ? run
                      : math.min(
                          run,
                          math.max(32.0, run * p.viewportDimension / whole),
                        );
                  final travel = run - width;
                  final at = p.maxScrollExtent <= 0
                      ? 0.0
                      : travel * (p.pixels / p.maxScrollExtent).clamp(0.0, 1.0);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: travel <= 0
                        ? null
                        : (d) => controller.jumpTo(
                            (p.pixels +
                                    (rtl ? -d.delta.dx : d.delta.dx) *
                                        p.maxScrollExtent /
                                        travel)
                                .clamp(0.0, p.maxScrollExtent),
                          ),
                    child: Stack(
                      children: [
                        PositionedDirectional(
                          start: at.roundToDouble(),
                          top: 0,
                          bottom: 0,
                          width: width.roundToDouble(),
                          child: retroDesktopFace(
                            states: const {},
                            scale: RetroDesktopFaceScale.mark,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
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
                                      child: CustomPaint(
                                        painter: _SidewaysRidges(c),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The thumb's three grip ridges, upright on a sideways bar.
class _SidewaysRidges extends CustomPainter {
  const _SidewaysRidges(this.c);
  final RetroDesktopColors c;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final at = 2.0 + i * 3;
      canvas.drawLine(
        Offset(at, 1),
        Offset(at, size.height - 1),
        Paint()..color = c.bevelDark,
      );
    }
  }

  @override
  bool shouldRepaint(_SidewaysRidges old) => old.c != c;
}

/// A column of a `RetroDesktopListTable`. No [width] means it takes the room. [sorted] marks the one it's sorted by.
/// [figures] sets its cells in the fixed-width face, as sizes and times are; false sets words (a kind, a date written
/// out) in the text face. [end] stands its cells and head at its end, so amounts and sizes line up there.
class RetroDesktopListTableColumn {
  /// Creates a [RetroDesktopListTableColumn].
  const RetroDesktopListTableColumn(
    this.label, {
    this.width,
    this.sorted = false,
    this.figures = true,
    this.end = false,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// The width in logical pixels.
  final double? width;

  /// Whether this column identifies the active sort order.
  final bool sorted;

  /// Whether its cells are figures, in the fixed-width face.
  final bool figures;

  /// Whether its cells and head stand at its end.
  final bool end;
}

/// A row of a `RetroDesktopListTable`: an icon, a name and a line, then one cell for each column after the first.
class RetroDesktopListTableRow {
  /// Creates a [RetroDesktopListTableRow].
  const RetroDesktopListTableRow({
    required this.title,
    this.note,
    this.icon = RetroDesktopGlyphs.fileText,
    this.selected = false,
    this.cells = const [],
    this.onPressed,
    this.key,
  });

  /// The heading displayed above the content.
  final String title;

  /// Supporting text shown with the main content.
  final String? note;

  /// The glyph shown with the content.
  final IconData icon;

  /// The icon takes the highlight: pinned, starred, playing.
  final bool selected;

  /// `(figure, small line)`.
  final List<(String, String?)> cells;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The stable identity of this item.
  final Key? key;
}

class _HeadPainter extends RetroDesktopPixelPainter {
  const _HeadPainter(this.c, this.fill);
  final RetroDesktopColors c;
  final Color fill;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    px.canvas.drawRect(r, Paint()..color = fill);
    px.fillExact(r.left, r.top, r.right, r.top + px.hair, c.bevelLight);
    px.fillExact(
      r.left,
      r.bottom - px.hair,
      r.right,
      r.bottom,
      c.dark ? c.shade : c.bevelDarker,
    );
    px.fillExact(
      r.right - px.hairX,
      r.top,
      r.right,
      r.bottom - px.hair,
      c.bevelDark,
    );
    px.fillExact(
      r.left,
      r.top,
      r.left + px.hairX,
      r.bottom - px.hair,
      c.bevelLight,
    );
  }

  @override
  bool shouldRepaint(_HeadPainter o) => o.c != c || o.fill != fill;
}

class _ColumnHead extends StatefulWidget {
  const _ColumnHead(
    this.label, {
    this.sorted = false,
    this.height = 21,
    this.triangle = true,
    this.end = false,
    this.ascending = false,
    this.onPressed,
  });
  final String label;
  final bool sorted, triangle, end, ascending;
  final double height;

  /// Sorts by this column. On a desk the head presses at its drawn height, as the list's rows do: the list is one focus
  /// stop, and the keyboard sorts from the application's View menu. On a phone it is a control of its own, its face
  /// filling a finger's reach.
  final VoidCallback? onPressed;

  @override
  State<_ColumnHead> createState() => _ColumnHeadState();
}

class _ColumnHeadState extends State<_ColumnHead> {
  bool _held = false;

  void _hold(bool v) {
    if (v != _held) setState(() => _held = v);
  }

  @override
  Widget build(BuildContext context) {
    final onPressed = widget.onPressed;
    if (onPressed == null) return _face(context, held: false);
    if (!RetroDesktopTheme.of(context).desk) {
      return RetroDesktopPressable(
        label: widget.label,
        selected: widget.sorted,
        ringInside: true,
        onPressed: onPressed,
        builder: (context, states) => _face(
          context,
          held: states.contains(WidgetState.pressed),
          least: RetroDesktopReach.least(context),
        ),
      );
    }
    return Semantics(
      button: true,
      selected: widget.sorted,
      label: widget.label,
      onTap: onPressed,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _hold(true),
          onTapUp: (_) => _hold(false),
          onTapCancel: () => _hold(false),
          onTap: onPressed,
          child: _face(context, held: _held),
        ),
      ),
    );
  }

  Widget _face(BuildContext context, {required bool held, double least = 0}) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final label = widget.label;
    final sorted = widget.sorted;
    final end = widget.end;
    return RetroDesktopPixelPaint(
      painter: _HeadPainter(
        c,
        held || sorted ? c.platinumDark : c.platinumLight,
      ),
      child: SizedBox(
        height: math.max(
          math.max(widget.height, least),
          MediaQuery.textScalerOf(context).scale(t.type.chrome.fontSize ?? 16) *
                  (t.type.chrome.height ?? 1) +
              4,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: RetroDesktopFitRow(
            fill: 0,
            gap: 6,
            children: [
              RetroDesktopCaps(
                style: t.type.chrome,
                Text(
                  label,
                  style: t.type.chrome.copyWith(
                    color: sorted ? c.text : c.textSecondary,
                  ),
                  textAlign: end ? TextAlign.end : TextAlign.start,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sorted && widget.triangle)
                RetroDesktopTriangleMark(
                  widget.ascending ? AxisDirection.up : AxisDirection.down,
                  size: 9,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A scroll bar's look: both arrows, a track, a thumb sized for how much is shown. Its bevel, stripes and thumb are drawn on
/// the device's grid.
class _ScrollBarPainter extends RetroDesktopPixelPainter {
  const _ScrollBarPainter(this.c, this.shown, this.rtl);
  final RetroDesktopColors c;
  final double shown;
  final bool rtl;
  static const width = 16.0;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    final w = px.hairX, h = px.hair;
    final left = px.x(rtl ? 0 : s.width - width);
    final right = px.x(rtl ? width : s.width);
    final top = px.y(0), bottom = px.y(s.height);
    if (bottom - top < 16 * 3) return;
    final edge = rtl ? right - w : left;
    px.fillExact(left, top, right, bottom, c.platinumDark);
    final inner = rtl ? right - 2 * w : left + w;
    px.fillExact(inner, top, inner + w, bottom, c.bevelDark);
    px.fillExact(edge, top, edge + w, bottom, c.outline);
    final l = rtl ? left : left + w;
    final r = rtl ? right - w : right;
    void arrow(double from, double to, AxisDirection dir, double rule) {
      final box = Rect.fromLTRB(l, from, r, to);
      px.fillExact(box.left, box.top, box.right, box.bottom, c.platinumLight);
      px.bevel(box, c.bevelLight, c.bevelDark);
      px.fillExact(box.left, rule, box.right, rule + h, c.outline);
      canvas.save();
      canvas.translate(
        box.left + (box.width - 9) / 2,
        box.top + (box.height - 9) / 2,
      );
      retroDesktopPaintTriangle(
        canvas,
        const Size(9, 9),
        dir,
        c.dark ? c.textTertiary : c.bevelDarker,
        c.dark ? c.shade : c.outline,
      );
      canvas.restore();
    }

    final topTo = px.y(16);
    final bottomFrom = px.y(s.height - 16);
    arrow(top, topTo, AxisDirection.up, topTo - h);
    arrow(bottomFrom, bottom, AxisDirection.down, bottomFrom);
    final track = bottomFrom - topTo;
    final thumbH =
        px.y(topTo + math.max(40, track * shown.clamp(0, 1))) - topTo;
    final thumb = Rect.fromLTRB(l, topTo, r, topTo + thumbH);
    canvas.drawRect(
      thumb,
      Paint()..color = Color.lerp(c.thumbTop, c.thumbBottom, .5)!,
    );
    px.fillExact(
      thumb.left,
      thumb.bottom - h,
      thumb.right,
      thumb.bottom,
      c.outline,
    );
    final body = Rect.fromLTRB(
      thumb.left,
      thumb.top,
      thumb.right,
      thumb.bottom - h,
    );
    px.bevel(body, const Color(0x8CFFFFFF), c.highlight);
    // Three grip lines, each shade over light.
    final mid = (body.top + body.bottom) / 2;
    for (final dy in [-4.0, 0.0, 4.0]) {
      final y = px.y(mid + dy - 1);
      final x0 = px.x((body.left + body.right) / 2 - 3.5);
      final x1 = px.x((body.left + body.right) / 2 + 3.5);
      px.fillExact(x0, y, x1, y + h, c.highlightDark);
      px.fillExact(x0, y + h, x1, y + 2 * h, const Color(0xB3FFFFFF));
    }
  }

  @override
  bool shouldRepaint(_ScrollBarPainter o) =>
      o.c != c || o.shown != shown || o.rtl != rtl;
}

/// A row's ground: [tint] over the span [span] (left to right, as painted), a [rule] over it and an [under] rule.
class _CellTint extends RetroDesktopPixelPainter {
  const _CellTint(this.rule, this.tint, this.span, {this.under});
  final Color? rule, under;
  final Color tint;
  final (double, double)? span;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final at = span;
    if (at != null && at.$2 > at.$1) {
      px.fill(
        Rect.fromLTRB(at.$1, 0, math.min(at.$2, s.width), s.height),
        tint,
      );
    }
    if (rule != null) px.ruleAcross(0, s.width, 0, rule!);
    if (under != null) px.ruleAcross(0, s.width, s.height - px.hair, under!);
  }

  @override
  bool shouldRepaint(_CellTint o) =>
      o.rule != rule || o.under != under || o.tint != tint || o.span != span;
}

/// The span of column [k] across [width], as painted: [starts] are the columns' starts reading from the start edge.
(double, double)? _columnSpan(
  int k,
  List<double> starts,
  double width, {
  required bool rtl,
}) {
  if (k < 0 || k >= starts.length) return null;
  final from = starts[k];
  final to = k + 1 < starts.length ? starts[k + 1] : width;
  return rtl ? (width - to, width - from) : (from, to);
}

/// A list in sorted columns: named heads, the sorted one darker with its triangle, rows of an icon, a name and a line, then
/// figures. On a desktop, when [total] says it holds more than it shows, a scroll bar stands at its end. Give it a window's
/// whole height: it brings its well.
///
/// Give it [onSelected] and it is a list you choose from, as the period's were: one row is [selected] and lit across every
/// column; a press selects, a second press soon after or Return opens ([onOpen]), the arrows move the selection while the
/// list has focus, and on a phone a press opens at once. Give it [onSort] and its heads press: the sorted one again turns
/// the order over, which [ascending] shows.
///
/// ```dart
/// RetroDesktopListTable(columns: const [RetroDesktopListTableColumn('Name'), RetroDesktopListTableColumn('Edited', width: 100, sorted: true)], rows: [RetroDesktopListTableRow(title: 'A note', note: 'Where it is', cells: const [('09:14', 'today')])], total: 40)
/// ```
class RetroDesktopListTable extends StatefulWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopListTable].
  const RetroDesktopListTable({
    super.key,
    this.style,
    required this.columns,
    required this.rows,
    this.total,
    this.selected,
    this.onSelected,
    this.onOpen,
    this.onSort,
    this.ascending = false,
    this.label,
  });

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The columns displayed in order.
  final List<RetroDesktopListTableColumn> columns;

  /// The rows displayed in order.
  final List<RetroDesktopListTableRow> rows;

  /// The total value displayed after the items.
  final int? total;

  /// The selected row's place, lit across every column.
  final int? selected;

  /// Selects a row: a press, or the arrows while the list has focus.
  final ValueChanged<int>? onSelected;

  /// Opens a row: a second press soon after the first, Return while the list has focus, or on a phone one press.
  final ValueChanged<int>? onOpen;

  /// A press on a column's head, by its place: sort by it.
  final ValueChanged<int>? onSort;

  /// The sorted column runs smallest (or first) first: its triangle points up.
  final bool ascending;

  /// The list's name for a screen reader.
  final String? label;

  @override
  State<RetroDesktopListTable> createState() => _RetroDesktopListTableState();
}

class _RetroDesktopListTableState extends State<RetroDesktopListTable> {
  final _focus = FocusNode(debugLabel: 'RetroDesktopListTable');
  int? _lastRow;
  Duration? _lastAt;
  Duration? _down;

  // The row the keys last chose, until the owner rebuilds the list with it: an arrow and Return in one frame open the
  // row the arrow reached, not the one drawn before it.
  int? _chosen;

  bool get _choosing => widget.onSelected != null || widget.onOpen != null;

  @override
  void didUpdateWidget(RetroDesktopListTable old) {
    super.didUpdateWidget(old);
    _chosen = null;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // A second press on the same row within a double press's time opens it; the time is the pointer's own, so a test's
  // and a slow machine's presses count alike.
  void _press(int i, Duration? at) {
    _focus.requestFocus();
    _chosen = i;
    widget.onSelected?.call(i);
    if (!RetroDesktopTheme.of(context).desk) {
      widget.onOpen?.call(i);
      return;
    }
    final last = _lastAt;
    final twice =
        at != null &&
        _lastRow == i &&
        last != null &&
        at - last <= kDoubleTapTimeout;
    _lastRow = twice ? null : i;
    _lastAt = twice ? null : at;
    if (twice) widget.onOpen?.call(i);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = widget.rows.length;
    final at = _chosen ?? widget.selected;
    if (n == 0) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (at == null || widget.onOpen == null) return KeyEventResult.ignored;
      widget.onOpen!(at);
      return KeyEventResult.handled;
    }
    final int to;
    if (key == LogicalKeyboardKey.arrowDown) {
      to = at == null ? 0 : math.min(n - 1, at + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      to = at == null ? n - 1 : math.max(0, at - 1);
    } else if (key == LogicalKeyboardKey.home) {
      to = 0;
    } else if (key == LogicalKeyboardKey.end) {
      to = n - 1;
    } else {
      return KeyEventResult.ignored;
    }
    _chosen = to;
    widget.onSelected?.call(to);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final columns = widget.columns;
    final rows = widget.rows;
    final total = widget.total;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final bar = t.desk && total != null && total > rows.length;
    // A set column grows with the reader's text (at twice the size, 80 lp held "Ed…" and "09:…"); the table scrolls
    // across when the columns no longer fit.
    final scaler = MediaQuery.textScalerOf(context);
    double widthOf(int k) {
      final set = columns[k].width ?? 80;
      return math.max(set, scaler.scale(set));
    }

    final fixedW = [for (var k = 1; k < columns.length; k++) widthOf(k)]
        .fold<double>(0, (a, w) => a + w);
    final sortedAt = columns.indexWhere((col) => col.sorted);
    Widget row(int i) {
      final r = rows[i];
      final lit = _choosing && widget.selected == i;
      final ink = lit ? c.onHighlight : null;
      final cells = <Widget>[
        for (var k = 1; k < columns.length; k++)
          SizedBox(
            width: widthOf(k),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: k - 1 < r.cells.length
                  ? Column(
                      crossAxisAlignment: columns[k].end
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          r.cells[k - 1].$1,
                          style:
                              (columns[k].figures ? t.type.figure : t.type.body)
                                  .copyWith(color: ink),
                          textAlign: columns[k].end
                              ? TextAlign.end
                              : TextAlign.start,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (r.cells[k - 1].$2 != null)
                          Text(
                            r.cells[k - 1].$2!,
                            style: t.type.meta.copyWith(color: ink),
                            textAlign: columns[k].end
                                ? TextAlign.end
                                : TextAlign.start,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : null,
            ),
          ),
      ];
      final body = LayoutBuilder(
        builder: (context, box) => RetroDesktopPixelPaint(
          // The sorted column is tinted, as its head is darker; the selected row is lit across every column, that tint
          // under it included.
          painter: _CellTint(
            i == 0 ? null : c.divider,
            lit ? c.highlight : c.paperDim,
            lit
                ? (0, box.maxWidth)
                : _columnSpan(
                    sortedAt,
                    [
                      0,
                      for (
                        var k = 1, at = box.maxWidth - fixedW;
                        k < columns.length;
                        at += widthOf(k), k++
                      )
                        at,
                    ],
                    box.maxWidth,
                    rtl: rtl,
                  ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, i == 0 ? 6 : 7, 8, 6),
                  child: Row(
                    children: [
                      Icon(
                        r.icon,
                        size: 16,
                        color:
                            ink ?? (r.selected ? c.highlight : c.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              r.title,
                              style: t.type
                                  .text(14, 19, weight: FontWeight.w600)
                                  .copyWith(color: ink),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (r.note != null)
                              Text(
                                r.note!,
                                style: t.type.meta.copyWith(color: ink),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ...cells,
            ],
          ),
        ),
      );
      if (_choosing) {
        // One focus stop for the whole list, as the period's lists were: a row is a place to press, not a tab stop. The
        // press's time is kept by the state: a press that raises its window rebuilds the rows before the tap lands.
        return KeyedSubtree(
          key: r.key,
          child: Semantics(
            button: true,
            selected: lit,
            label: r.title,
            onTap: () => _press(i, null),
            excludeSemantics: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Listener(
                onPointerDown: (e) => _down = e.timeStamp,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _press(i, _down ?? Duration.zero),
                  child: body,
                ),
              ),
            ),
          ),
        );
      }
      if (r.onPressed == null) return KeyedSubtree(key: r.key, child: body);
      return RetroDesktopPressable(
        key: r.key,
        button: true,
        label: r.title,
        onPressed: r.onPressed,
        child: body,
      );
    }

    Widget head(int k) => _ColumnHead(
      columns[k].label,
      sorted: columns[k].sorted,
      end: columns[k].end,
      ascending: widget.ascending,
      onPressed: widget.onSort == null ? null : () => widget.onSort!(k),
    );
    final list = RetroDesktopColumn(
      children: [
        Row(
          children: [
            Expanded(child: columns.isEmpty ? const _ColumnHead('') : head(0)),
            for (var k = 1; k < columns.length; k++)
              SizedBox(width: widthOf(k), child: head(k)),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          if (t.desk)
            RetroDesktopGrow(most: 14, child: row(i))
          else
            // On a phone a row is a finger's reach tall.
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: RetroDesktopReach.least(context),
              ),
              child: row(i),
            ),
      ],
    );
    final viewport = _tableViewport(
      minimumWidth: fixedW + MediaQuery.textScalerOf(context).scale(120),
      builder: (_, _) => list,
    );
    final well = RetroDesktopWell(
      style: widget.style,
      child: bar
          ? RetroDesktopPixelPaint(
              painter: _ScrollBarPainter(c, rows.length / total, rtl),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: _ScrollBarPainter.width,
                ),
                child: viewport,
              ),
            )
          : viewport,
    );
    if (!_choosing) return well;
    return Semantics(
      container: true,
      label: widget.label,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _key,
        child: ListenableBuilder(
          listenable: _focus,
          builder: (context, child) => RetroDesktopHighlight(
            shape: const RoundedRectangleBorder(),
            focused: _focus.hasFocus,
            child: child,
          ),
          child: well,
        ),
      ),
    );
  }
}

/// A column of a `RetroDesktopTable`. Give a [width], or a share of what's left as [flex]. [figures] sets it in mono. [end] stands
/// it at its column's end: amounts line up there.
class RetroDesktopTableColumn {
  /// Creates a [RetroDesktopTableColumn].
  const RetroDesktopTableColumn(
    this.label, {
    this.width,
    this.flex = 1,
    this.figures = false,
    this.sorted = false,
    this.end = false,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// The width in logical pixels.
  final double? width;

  /// The relative share of remaining layout space.
  final double flex;

  /// Whether its cells are figures, in the fixed-width face.
  final bool figures;

  /// Whether this column identifies the active sort order.
  final bool sorted;

  /// Whether its cells stand at the column's end, where amounts line up.
  final bool end;
}

/// A table: heads in the system face, the first column tinted and heavier, a total row. Nothing wraps: a cell too long ends
/// in an ellipsis. Give it a window's whole width: it brings its well.
///
/// ```dart
/// RetroDesktopTable(columns: const [RetroDesktopTableColumn('Part'), RetroDesktopTableColumn('Qty', width: 40, figures: true)], rows: const [['Leg', '4'], ['Wedge', '8']], total: const ['Total', '12'])
/// ```
class RetroDesktopTable extends StatelessWidget implements RetroDesktopFlush {
  /// Creates a [RetroDesktopTable].
  const RetroDesktopTable({
    super.key,
    this.style,
    required this.columns,
    required this.rows,
    this.total,
    this.due,
  });

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The columns displayed in order.
  final List<RetroDesktopTableColumn> columns;

  /// The rows displayed in order.
  final List<List<String>> rows;

  /// The total value displayed after the items.
  final List<String>? total;

  /// The amount to pay, set apart at the foot under a double rule: its label at the start, its figure larger at the end.
  /// Pass the figure formatted, with its currency.
  final (String, String)? due;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final amount = due;
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String words, TextStyle style) {
      final p = TextPainter(
        text: TextSpan(text: words, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    // A column is never narrower than its head's words, nor a figures column than its widest figure (an amount cut
    // to "$8…" misreads): a share that falls short is held at them, and the others share what is left. Words in other
    // columns may still end in an ellipsis.
    // A set width is kept while its words fit in it; at a larger text size it grows to them as well.
    final least = [
      for (final (k, col) in columns.indexed)
        [
          ?col.width,
          measure(col.label, t.type.chrome) + 17,
          if (col.figures)
            for (final line in [...rows, ?total])
              if (k < line.length)
                measure(line[k], t.type.mono(12, 18, weight: FontWeight.w700)) +
                    17,
        ].fold(0.0, math.max).ceilToDouble(),
    ];
    return RetroDesktopWell(
      style: style,
      child: _tableViewport(
        minimumWidth: [
          for (var k = 0; k < columns.length; k++)
            columns[k].width != null
                ? least[k]
                : math.max(least[k], scaler.scale(72)),
        ].fold<double>(0, (sum, w) => sum + w),
        builder: (context, box) {
          final held = <int, double>{
            for (var k = 0; k < columns.length; k++)
              if (columns[k].width != null) k: least[k],
          };
          double room() => math.max(
            0.0,
            box.maxWidth - held.values.fold<double>(0, (a, w) => a + w),
          );
          double shares() => [
            for (var k = 0; k < columns.length; k++)
              if (!held.containsKey(k)) columns[k].flex,
          ].fold<double>(0, (a, f) => a + f);
          while (true) {
            final r = room(), s = shares();
            final short = [
              for (var k = 0; k < columns.length; k++)
                if (!held.containsKey(k) &&
                    s > 0 &&
                    r * columns[k].flex / s < least[k])
                  k,
            ];
            if (short.isEmpty) break;
            for (final k in short) {
              held[k] = least[k];
            }
          }
          final room0 = room(), shares0 = shares();
          final widths = <double>[];
          var at = 0.0, placed = 0.0;
          for (var k = 0; k < columns.length; k++) {
            final col = columns[k];
            at += held[k] ?? (shares0 == 0 ? 0 : room0 * col.flex / shares0);
            final edge = math.min(box.maxWidth, at.roundToDouble());
            widths.add(edge - placed);
            placed = edge;
          }
          Widget cell(
            int k,
            String word, {
            bool head = false,
            bool sum = false,
          }) {
            final col = columns[k];
            final style = sum
                ? (col.figures
                      ? t.type.mono(12, 18, weight: FontWeight.w700)
                      : t.type.text(14, 18, weight: FontWeight.w700))
                : col.figures
                ? t.type.mono(12, 18, weight: FontWeight.w600)
                : k == 0
                ? t.type.text(14, 18, weight: FontWeight.w600)
                : t.type.text(14, 18);
            return SizedBox(
              width: widths[k],
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                child: Text(
                  word,
                  style: style,
                  textAlign: col.end ? TextAlign.end : TextAlign.start,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }

          final rtl = Directionality.of(context) == TextDirection.rtl;
          final starts = <double>[];
          for (var k = 0, at = 0.0; k < widths.length; at += widths[k], k++) {
            starts.add(at);
          }
          // The sorted column is tinted, as its head is darker; a table sorted by nothing is plain.
          final sorted = _columnSpan(
            columns.indexWhere((col) => col.sorted),
            starts,
            box.maxWidth,
            rtl: rtl,
          );
          Widget line(List<String> words, {bool sum = false}) {
            final cells = [
              for (var k = 0; k < columns.length; k++)
                cell(k, k < words.length ? words[k] : '', sum: sum),
            ];
            return RetroDesktopPixelPaint(
              painter: _CellTint(
                sum ? c.bevelDark : null,
                c.paperDim,
                sum ? null : sorted,
                under: sum ? null : c.divider,
              ),
              child: Padding(
                padding: EdgeInsets.only(top: sum ? 1 : 0, bottom: sum ? 0 : 1),
                child: Row(children: cells),
              ),
            );
          }

          return RetroDesktopColumn(
            children: [
              Row(
                children: [
                  for (var k = 0; k < columns.length; k++)
                    SizedBox(
                      width: widths[k],
                      child: _ColumnHead(
                        columns[k].label,
                        sorted: columns[k].sorted,
                        triangle: false,
                        height: 20,
                        end: columns[k].end,
                      ),
                    ),
                ],
              ),
              for (final row in rows) line(row),
              if (total != null) line(total!, sum: true),
              if (amount != null) _Due(label: amount.$1, figure: amount.$2),
            ],
          );
        },
      ),
    );
  }
}

/// The amount due at a table's foot: a double rule over it, the label in the text face, the figure larger in the
/// fixed-width face at the end, under the column of amounts.
class _Due extends StatelessWidget {
  const _Due({required this.label, required this.figure});
  final String label, figure;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return RetroDesktopPixelPaint(
      painter: _DoubleRule(c.dark ? c.textSecondary : c.outline),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label,
                style: t.type.text(14, 18, weight: FontWeight.w700),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              figure,
              style: t.type.mono(18, 22, weight: FontWeight.w700),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoubleRule extends RetroDesktopPixelPainter {
  const _DoubleRule(this.color);
  final Color color;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    px.ruleAcross(0, s.width, 0, color);
    px.ruleAcross(0, s.width, 3 * px.hair, color);
  }

  @override
  bool shouldRepaint(_DoubleRule o) => o.color != color;
}

/// One folder of a `RetroDesktopFolderGrid`.
class RetroDesktopFolder {
  /// Creates a [RetroDesktopFolder].
  const RetroDesktopFolder(
    this.name, {
    this.icon,
    this.art,
    this.note,
    this.selected = false,
    this.onPressed,
    this.key,
  });

  /// The name identifying this item.
  final String name;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Any app-supplied image or drawing; the fallback is a folder glyph.
  final Widget? art;

  /// Supporting text shown with the main content.
  final String? note;

  /// Whether the part represents the current selection.
  final bool selected;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The stable identity of this item.
  final Key? key;
}

/// Folders in an icon view: a drawn folder with your icon on it, its name, a count under it, as many to a row as fit. The
/// selected one's name takes the highlight; an app's own [RetroDesktopFolder.art] may show it on the folder too.
///
/// ```dart
/// RetroDesktopFolderGrid(items: const [RetroDesktopFolder('Workshop', icon: RetroDesktopGlyphs.hammer, note: '9 notes', selected: true)])
/// ```
class RetroDesktopFolderGrid extends StatelessWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopFolderGrid].
  const RetroDesktopFolderGrid({super.key, this.style, required this.items});

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The items displayed in their supplied order.
  final List<RetroDesktopFolder> items;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    Widget item(RetroDesktopFolder f) {
      final name = Text(
        f.name,
        style: t.type.text(
          13,
          17,
          weight: FontWeight.w600,
          color: f.selected ? c.onHighlight : c.text,
        ),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
      final Widget box = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: retroDesktopOwnSize(
              width: 56,
              height: 44,
              child:
                  f.art ??
                  Icon(
                    f.icon ?? RetroDesktopGlyphs.folder,
                    size: 36,
                    color: c.text,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          DecoratedBox(
            decoration: ShapeDecoration(
              shape: t.shapes.small,
              color: f.selected ? c.highlight : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: name,
            ),
          ),
          if (f.note != null) ...[
            const SizedBox(height: 4),
            Text(
              f.note!,
              style: t.type.text(12, 15, color: c.textTertiary),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
      // Each tile fills its row's height, its picture at the top: a row of
      // tiles shows one top and one bottom whatever a name or note wraps to.
      // A tile has no face of its own (a picture, its name, a note), so to
      // the shared checks it is its cell: the chosen one's lit name is not
      // its outline, nor is the others' picture.
      final held = KeyedSubtree(
        key: f.key,
        child: retroDesktopFillHeight(DesignKeylineFace(child: box)),
      );
      if (f.onPressed == null) return held;
      return RetroDesktopPressable(
        button: true,
        selected: f.selected,
        label: f.name,
        onPressed: f.onPressed,
        alignment: Alignment.topCenter,
        child: held,
      );
    }

    final gap = t.desk ? 6.0 : 4.0;
    return RetroDesktopWell(
      style: style,
      child: Padding(
        padding: t.desk
            ? const EdgeInsets.fromLTRB(8, 16, 8, 14)
            : const EdgeInsets.fromLTRB(6, 14, 6, 12),
        child: LayoutBuilder(
          builder: (context, box) => RetroDesktopGridOf(
            columns: math.max(1, ((box.maxWidth + gap) / (100 + gap)).floor()),
            gap: gap,
            runGap: t.desk ? 14 : 10,
            children: [for (final f in items) item(f)],
          ),
        ),
      ),
    );
  }
}

/// One file of a `RetroDesktopFileGrid`: its name, its kind on a small ink tab, and a note.
class RetroDesktopFile {
  /// Creates a [RetroDesktopFile].
  const RetroDesktopFile(
    this.name, {
    required this.kind,
    this.note,
    this.art,
    this.selected = false,
    this.onPressed,
    this.key,
  });

  /// The name identifying this item.
  final String name;

  /// The visual category used to draw this item.
  final String kind;

  /// Supporting text shown with the main content.
  final String? note;

  /// Any app-supplied image or drawing; the fallback is a file glyph.
  final Widget? art;

  /// Whether the part represents the current selection.
  final bool selected;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The stable identity of this item.
  final Key? key;
}

/// Files as icons: a drawn page with its corner folded, a tab with its kind, a name that may break anywhere, a small line. As
/// many to a row as fit.
///
/// ```dart
/// RetroDesktopFileGrid(items: const [RetroDesktopFile('plan.pdf', kind: 'PDF', note: '2 pages')])
/// ```
class RetroDesktopFileGrid extends StatelessWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopFileGrid].
  const RetroDesktopFileGrid({super.key, this.style, required this.items});

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The items displayed in their supplied order.
  final List<RetroDesktopFile> items;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    Widget item(RetroDesktopFile f, double room) {
      final nameStyle = t.type.text(
        12,
        15,
        weight: FontWeight.w600,
        color: f.selected ? c.onHighlight : c.text,
      );
      // A name breaks between its words. At a large text size its words
      // shrink just enough that the longest stands whole in the cell (twice
      // the text size broke a name inside a word); only a piece longer than
      // its cell at the plain size breaks anywhere.
      double widest(TextScaler scaler) {
        var most = 0.0;
        for (final piece in f.name.split(RegExp(r'(?<=[-\s])'))) {
          final tp = TextPainter(
            text: TextSpan(text: piece.trimRight(), style: nameStyle),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          most = math.max(most, tp.width);
          tp.dispose();
        }
        return most;
      }

      var name = f.name;
      double? nameScale;
      if (widest(MediaQuery.textScalerOf(context)) > room) {
        final plain = widest(TextScaler.noScaling);
        if (plain > room) {
          name = f.name.characters.join('\u200B');
        } else if (plain > 0) {
          nameScale = math.max(1.0, room / plain - .01);
        }
      }
      Widget nameText = Text(
        name,
        textAlign: TextAlign.center,
        style: nameStyle,
      );
      if (nameScale != null) {
        nameText = MediaQuery.withClampedTextScaling(
          maxScaleFactor: nameScale,
          child: nameText,
        );
      }
      final box = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          retroDesktopOwnSize(
            width: 44,
            height: 52,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child:
                      f.art ??
                      Icon(
                        RetroDesktopGlyphs.fileText,
                        size: 36,
                        color: c.text,
                      ),
                ),
                PositionedDirectional(
                  start: -4,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: t.shapes.full,
                      color: c.text,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 1, 4, 0),
                      child: Text(
                        f.kind,
                        style: t.type
                            .pixel(15, 14, color: c.paper)
                            .copyWith(letterSpacing: 15 * .03),
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          DecoratedBox(
            decoration: ShapeDecoration(
              shape: t.shapes.small,
              color: f.selected ? c.highlight : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: nameText,
            ),
          ),
          if (f.note != null) ...[
            const SizedBox(height: 5),
            Text(
              f.note!,
              textAlign: TextAlign.center,
              style: t.type.text(12, 15, color: c.textTertiary),
            ),
          ],
        ],
      );
      // Each tile fills its row's height, its picture at the top: a row of
      // tiles shows one top and one bottom whatever a name or note wraps to.
      // A tile has no face of its own (a picture, its name, a note), so to
      // the shared checks it is its cell: the chosen one's lit name is not
      // its outline, nor is the others' picture.
      final held = KeyedSubtree(
        key: f.key,
        child: retroDesktopFillHeight(DesignKeylineFace(child: box)),
      );
      if (f.onPressed == null) return held;
      return RetroDesktopPressable(
        button: true,
        selected: f.selected,
        label: f.name,
        onPressed: f.onPressed,
        alignment: Alignment.topCenter,
        child: held,
      );
    }

    return RetroDesktopWell(
      style: style,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
        child: LayoutBuilder(
          builder: (context, box) {
            final columns = math.max(
              1,
              ((box.maxWidth + 6) / (90 + 6)).floor(),
            );
            final room = (box.maxWidth + 6) / columns - 6 - 6;
            return RetroDesktopGridOf(
              columns: columns,
              gap: 6,
              runGap: 14,
              children: [for (final f in items) item(f, room)],
            );
          },
        ),
      ),
    );
  }
}

class _HatchTrack extends RetroDesktopPixelPainter {
  const _HatchTrack(this.c, this.share, this.track, {this.rtl = false});
  final RetroDesktopColors c;
  // A share bar is a track like a progress bar's: the family's capsule.
  final OutlinedBorder track;
  final double share;
  // Right to left the share fills from the right, as the row reads; the sunk
  // edge stays top and left (the light doesn't turn round).
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    final w = px.hairX, h = px.hair;
    final outline = track.copyWith(
      side: BorderSide(color: c.control, width: w),
    );
    px.canvas.save();
    px.canvas.clipPath(outline.getOuterPath(r));
    px.canvas.drawRect(r, Paint()..color = c.paper);
    px.fillExact(
      r.left + w,
      r.top + h,
      r.right - w,
      r.top + 2 * h,
      c.bevelDark,
    );
    px.fillExact(
      r.left + w,
      r.top + h,
      r.left + 2 * w,
      r.bottom - h,
      c.bevelDark,
    );
    final inner = Rect.fromLTRB(
      r.left + w,
      r.top + h,
      r.right - w,
      r.bottom - h,
    );
    final reach = inner.width * share.clamp(0, 1);
    if (rtl) {
      final from = px.x(inner.right - reach);
      if (from < inner.right) {
        final fill = Rect.fromLTRB(from, inner.top, inner.right, inner.bottom);
        px.diagonal(fill, 3, 1, c.hatch);
        px.fillExact(from, inner.top, from + w, inner.bottom, c.text);
      }
    } else {
      final to = px.x(inner.left + reach);
      if (to > inner.left) {
        final fill = Rect.fromLTRB(inner.left, inner.top, to, inner.bottom);
        px.diagonal(fill, 3, 1, c.hatch);
        px.fillExact(to - w, inner.top, to, inner.bottom, c.text);
      }
    }
    px.canvas.restore();
    outline.paint(px.canvas, r);
  }

  @override
  bool shouldRepaint(_HatchTrack o) =>
      o.c != c || o.share != share || o.track != track || o.rtl != rtl;
}

/// A row of a `RetroDesktopTreeBars`. [open] draws a triangle (null none); [level] 1 is indented and lighter.
class RetroDesktopTreeRow {
  /// Creates a [RetroDesktopTreeRow].
  const RetroDesktopTreeRow(
    this.name,
    this.value, {
    required this.share,
    this.level = 0,
    this.open,
  });

  /// The name identifying this item.
  final String name;

  /// The current value to display or edit.
  final String value;

  /// Of the whole, 0 to 1.
  final double share;

  /// The indentation level of this tree item.
  final int level;

  /// Whether the row is open: a triangle pointing down, or right when false; null draws none.
  final bool? open;
}

/// What takes the room: a tree of names, each with a hatched bar for its share and its figure at the end, a total under them.
///
/// ```dart
/// RetroDesktopTreeBars(rows: const [RetroDesktopTreeRow('Pictures', '538 MB', share: .39, open: true), RetroDesktopTreeRow('Scans', '412 MB', share: .3, level: 1)], totalName: 'Total', total: '950 MB')
/// ```
class RetroDesktopTreeBars extends StatelessWidget {
  /// Creates a [RetroDesktopTreeBars].
  const RetroDesktopTreeBars({
    super.key,
    required this.rows,
    this.totalName,
    this.total,
  });

  /// The rows displayed in order.
  final List<RetroDesktopTreeRow> rows;

  /// The label describing the total.
  final String? totalName;

  /// The total value displayed after the items.
  final String? total;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final value = t.type.figure;
    final bold = t.type.mono(12, 16, weight: FontWeight.w700);
    double widthOf(String s, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final w = tp.width;
      tp.dispose();
      return w;
    }

    return LayoutBuilder(
      builder: (context, box) {
        var valueW = 58.0;
        for (final r in rows) {
          valueW = math.max(valueW, widthOf(r.value, value).ceilToDouble());
        }
        if (total != null) {
          valueW = math.max(valueW, widthOf(total!, bold).ceilToDouble());
        }
        valueW = math.min(valueW, box.maxWidth * .34);
        final nameW = math.min(104.0, box.maxWidth * .4);
        Widget row(
          String name,
          String figure,
          double? share,
          int level,
          bool? open, {
          bool sum = false,
        }) {
          return Row(
            children: [
              SizedBox(
                width: nameW,
                child: Row(
                  children: [
                    SizedBox(width: level > 0 ? 14 : 0),
                    if (level == 0) ...[
                      if (open != null)
                        RetroDesktopTriangleMark(
                          open
                              ? AxisDirection.down
                              : (rtl
                                    ? AxisDirection.left
                                    : AxisDirection.right),
                          size: 9,
                        )
                      else
                        const SizedBox(width: 9),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        style: level > 0
                            ? t.type.text(12, 16, color: c.textSecondary)
                            : t.type.text(
                                12,
                                16,
                                weight: sum ? FontWeight.w700 : FontWeight.w600,
                              ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: share == null
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 9,
                        child: RetroDesktopPixelPaint(
                          painter: _HatchTrack(
                            c,
                            share,
                            t.shapes.full,
                            rtl: rtl,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: valueW,
                child: Text(
                  figure,
                  textAlign: TextAlign.end,
                  style: sum ? bold : value,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }

        return RetroDesktopColumn(
          gap: 4,
          children: [
            for (final r in rows)
              row(r.name, r.value, r.share, r.level, r.open),
            if (total != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RetroDesktopColumn(
                  gap: 3,
                  children: [
                    const RetroDesktopDivider.etched(),
                    row(totalName ?? '', total!, null, 0, null, sum: true),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A line of a `RetroDesktopChecklist`. [isCurrent] is the one to do now; [chips] are small dates and references.
class RetroDesktopCheckItem {
  /// Creates a [RetroDesktopCheckItem].
  const RetroDesktopCheckItem(
    this.text, {
    this.value = false,
    this.isCurrent = false,
    this.chips = const [],
    this.selectedChip,
    this.onChanged,
  });

  /// The text displayed by this part.
  final String text;

  /// Whether the checklist item is complete.
  final bool value;

  /// Highlights this item as the next one to complete.
  final bool isCurrent;

  /// The chips displayed with this item.
  final List<String> chips;

  /// Which chip takes the highlight, on the next line.
  final String? selectedChip;

  /// Reports a request to change the completion state.
  final ValueChanged<bool>? onChanged;
}

// The next item reads by its tint alone, in the family's control shape; the
// rail that once repeated it at the start edge is gone (one cue per state).
class _NextPainter extends RetroDesktopPixelPainter {
  const _NextPainter(this.rule, this.fill, this.shape);
  final Color? rule, fill;
  final OutlinedBorder shape;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    if (fill != null) {
      px.canvas.drawPath(
        shape.getOuterPath(px.snap(Offset.zero & s)),
        Paint()..color = fill!,
      );
    }
    if (rule != null) px.ruleAcross(0, s.width, s.height - px.hair, rule!);
  }

  @override
  bool shouldRepaint(_NextPainter o) =>
      o.rule != rule || o.fill != fill || o.shape != shape;
}

/// A checklist in a group box: its count and progress worked out from the items, the next one lit, what's done gone quiet.
///
/// ```dart
/// RetroDesktopChecklist(title: 'Checklist', items: const [RetroDesktopCheckItem('Cut the legs', value: true), RetroDesktopCheckItem('Glue up', isCurrent: true, chips: ['today 14:00'], selectedChip: 'today 14:00')])
/// ```
class RetroDesktopChecklist extends StatelessWidget {
  /// Creates a [RetroDesktopChecklist].
  const RetroDesktopChecklist({
    super.key,
    this.style,
    required this.title,
    required this.items,
    this.icon = RetroDesktopGlyphs.listChecks,
  });

  /// Overrides the enclosing group box's card theme.
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String title;

  /// The glyph shown with the content.
  final IconData icon;

  /// The items displayed in their supplied order.
  final List<RetroDesktopCheckItem> items;

  /// An item presses whole, as a setting's row does: on a phone at least 44 lp tall, its line in the middle.
  Widget _item(BuildContext context, int i) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final item = items[i];
    final toggle = item.onChanged;
    final drawn = RetroDesktopPixelPaint(
      painter: _NextPainter(
        i == items.length - 1 ? null : c.divider,
        item.isCurrent ? c.highlightContainer : null,
        t.shapes.small.copyWith(side: BorderSide.none),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: toggle == null ? 0 : RetroDesktopReach.least(context),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 8, 6, i == items.length - 1 ? 8 : 9),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: _CheckLine(item),
          ),
        ),
      ),
    );
    if (toggle == null) return drawn;
    // The row is the control's face: ground-coloured, drawn only by its rule, so it is marked as one.
    return RetroDesktopPressable(
      button: true,
      checked: item.value,
      label: item.text,
      onPressed: () => toggle(!item.value),
      child: DesignKeylineFace(child: drawn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final done = items.where((i) => i.value).length;
    final share = items.isEmpty ? 0.0 : done / items.length;
    return RetroDesktopGroupBox(
      style: style,
      title: title,
      icon: icon,
      count: RetroDesktopLocalizations.of(context)
          .completedCount(done, items.length),
      child: RetroDesktopColumn(
        gap: 8,
        children: [
          RetroDesktopFitRow(
            fill: 0,
            gap: 10,
            children: [
              RetroDesktopLinearProgressIndicator(value: share, label: title),
              Text(
                RetroDesktopLocalizations.of(context).formatPercent(share),
                style: t.type.pixel(18, 16),
              ),
            ],
          ),
          RetroDesktopColumn(
            children: [
              for (var i = 0; i < items.length; i++) _item(context, i),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine(this.item);
  final RetroDesktopCheckItem item;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final words = Text(
      item.text,
      style: t.type.text(15, 21, color: item.value ? c.textTertiary : c.text),
    );
    final chips = item.chips.isEmpty
        ? null
        : Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final chip in item.chips)
                RetroDesktopChip(
                  chip,
                  size: RetroDesktopButtonSize.small,
                  icon: chip == item.selectedChip
                      ? RetroDesktopGlyphs.bell
                      : null,
                  selected: chip == item.selectedChip,
                ),
            ],
          );
    // The box stands on the first line's middle, its reach overhanging the line (set from the top, the reach's
    // middle put the box 10 px under the words). Where the row toggles, the row is the control: the box is its face
    // alone, drawn live (drawn as a box without its own callback it was greyed, as an unavailable box is; drawn as a
    // live box it was a second press target inside the row's).
    final toggle = item.onChanged;
    final Widget check;
    if (toggle != null) {
      // Its middle on the first line's capitals as the engine draws them, on the baseline it rounds to a whole pixel
      // (the line's middle left it a device pixel high).
      check = RetroDesktopOnCaps(
        style: t.type.text(15, 21),
        child: retroDesktopCheckFace(context, item.value),
      );
    } else {
      // A list that only shows: the box is the control and keeps its own reach, so the row stands as tall as it.
      check = Padding(
        padding: const EdgeInsets.only(top: 3),
        child: RetroDesktopCheckbox(value: item.value, label: item.text),
      );
    }
    // Chips beside the words centre them on the chips' height: a live box goes with its words there, so it stays on
    // their first line (from the row's top it stood 2 px above them).
    final paired = chips != null && t.desk && toggle != null;
    final content = chips == null
        ? words
        : t.desk
        ? RetroDesktopFitRow(
            fill: 0,
            gap: 12,
            fillShare: .5,
            children: [
              paired
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        check,
                        const SizedBox(width: 12),
                        Flexible(child: words),
                      ],
                    )
                  : words,
              chips,
            ],
          )
        : RetroDesktopColumn(gap: 4, children: [words, chips]);
    return LayoutBuilder(
      builder: (context, room) => room.maxWidth < 120
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                check,
                if (paired)
                  RetroDesktopColumn(gap: 4, children: [words, chips])
                else
                  content,
              ],
            )
          : paired
          ? content
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                check,
                const SizedBox(width: 12),
                Expanded(child: content),
              ],
            ),
    );
  }
}

/// A document on paper: where it lives, a big title, its dates, tags, paragraphs set to read, then what you add. It brings its
/// well; a phone tightens its margins. `(label, value)` for [meta], the value heavier.
///
/// ```dart
/// RetroDesktopDocument(path: const ['Notes', 'Workshop'], title: 'Build plan', meta: const [('Edited', 'today 09:14')], tags: const ['walnut'], paragraphs: const ['Seat first, then the legs.'])
/// ```
class RetroDesktopDocument extends StatelessWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopDocument].
  const RetroDesktopDocument({
    super.key,
    this.style,
    required this.title,
    this.path = const [],
    this.meta = const [],
    this.tags = const [],
    this.addTag,
    this.paragraphs = const [],
    this.children = const [],
  });

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String title;

  /// The displayed path or breadcrumb.
  final List<String> path;

  /// The tags displayed with this item.
  final List<String> tags;

  /// The document paragraphs in reading order.
  final List<String> paragraphs;

  /// Secondary information displayed with the main content.
  final List<(String, String)> meta;

  /// The outlined chip that adds a tag.
  final String? addTag;

  /// What stands after the words: a `RetroDesktopChecklist`, `RetroDesktopDisclosure`s.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final digit = TextPainter(
      text: TextSpan(text: '0', style: t.type.body),
      textDirection: TextDirection.ltr,
      // The measure is counted in the reader's characters.
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final measure = digit.width * (t.desk ? 56 : 62);
    digit.dispose();
    return RetroDesktopWell(
      style: style,
      padding: t.desk
          ? const EdgeInsets.fromLTRB(46, 34, 46, 38)
          : const EdgeInsets.fromLTRB(16, 20, 16, 22),
      child: RetroDesktopColumn(
        gap: t.desk ? 20 : 18,
        children: [
          if (path.isNotEmpty)
            RetroDesktopBreadcrumb(
              items: [for (final p in path) RetroDesktopBreadcrumbItem(p)],
            ),
          RetroDesktopBalancedText(title, style: t.type.title),
          if (meta.isNotEmpty)
            Wrap(
              spacing: 12,
              runSpacing: 2,
              children: [
                for (final m in meta)
                  Text.rich(
                    TextSpan(
                      style: t.type.meta,
                      children: [
                        if (m.$1.isNotEmpty) TextSpan(text: '${m.$1} '),
                        TextSpan(
                          text: m.$2,
                          style: t.type.text(
                            12,
                            16,
                            weight: FontWeight.w600,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (tags.isNotEmpty || addTag != null)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags)
                  RetroDesktopChip(tag, leading: const Text('#')),
                if (addTag != null)
                  RetroDesktopChip.outlined(
                    addTag!,
                    icon: RetroDesktopGlyphs.plus,
                  ),
              ],
            ),
          if (path.isNotEmpty || meta.isNotEmpty || tags.isNotEmpty)
            const RetroDesktopDivider.etched(),
          if (paragraphs.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: measure),
              child: RetroDesktopColumn(
                gap: 14,
                children: [
                  for (final p in paragraphs) Text(p, style: t.type.read),
                ],
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
