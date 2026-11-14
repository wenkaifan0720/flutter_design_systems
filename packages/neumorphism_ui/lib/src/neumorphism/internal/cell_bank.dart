// A bank of cells: the look's one model for a segmented control, a latch bank and a tab bar (polish round 3, the
// cells model). The bank is one raised part, split by full-height engraved seams into equal cells. The chosen cell is
// its whole cell pressed in, flush to the bank's rim and to the seams, under one even tint: its outer corners are the
// bank's corners moved in by the rim, around the same centres, and its inner corners are square. Every seam stays.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../frames.dart';
import 'geometry.dart' show neumorphicStrokePaint;
import 'reach.dart';
import '../knobs.dart';
import '../shapes.dart';
import '../theme.dart';

/// What a cell of a bank knows about itself: its outline and whether it is the chosen one.
class NeumorphicCellScope extends InheritedWidget {
  /// Publishes [border] and [chosen] to a cell's [child].
  const NeumorphicCellScope({
    super.key,
    required this.border,
    required this.chosen,
    required super.child,
  });

  /// The cell's outline, concentric with the bank.
  final NeumorphicCellBorder border;

  /// Whether this cell is the bank's chosen one.
  final bool chosen;

  /// The cell [context] stands in.
  static NeumorphicCellScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NeumorphicCellScope>()!;

  @override
  bool updateShouldNotify(NeumorphicCellScope old) =>
      old.border != border || old.chosen != chosen;
}

/// The most a choice control (a select, a bank of segments, latches or buttons) takes in a column wider than it, from a
/// medium window up.
const double neumorphicWideControlMax = 320;

/// The width a choice control takes in [available] when its own is [own]. From a medium window (600) up it is a control,
/// not a band (design6 P, the user on another look's form: "some dropdown spans the entire width"): in a column wider
/// than [neumorphicWideControlMax] it takes its own width, at most the column; a column no wider (a rail, a cell of a
/// form's grid) it fills. On a phone it spans its column, as every field there does.
double neumorphicControlWidth(
  BuildContext context,
  double available,
  double own,
) {
  final window = MediaQuery.maybeSizeOf(context)?.width ?? 0;
  if (NeumorphicWindow.forWidth(window) == NeumorphicWindow.compact ||
      available <= neumorphicWideControlMax) {
    return available;
  }
  return math.min(available, own);
}

/// A wide button's room: its whole column on a phone, and from a medium window up a column no wider than half again a
/// control's most ([most], a control's unless a part needs more: a month's seven 48 px days); in a wider one it takes
/// that most, at [alignment]. Capped in a column a little wider than its most, it stood at three quarters of it, under
/// a card of that column and aligned to neither (a checkout's Pay key under its order).
Widget neumorphicWideRoom(
  AlignmentGeometry alignment,
  Widget child, {
  double most = neumorphicWideControlMax,
}) => LayoutBuilder(
  builder: (context, box) {
    if (!box.hasBoundedWidth || box.maxWidth <= most * 1.5) return child;
    final width = neumorphicControlWidth(context, box.maxWidth, most);
    if (width >= box.maxWidth) return child;
    return Align(
      alignment: alignment,
      heightFactor: 1,
      child: SizedBox(width: width, child: child),
    );
  },
);

/// A bank of [children] in equal cells. [minCellWidth] is the least a cell may be before the bank wraps to another row
/// (or, with [scroll], scrolls sideways); [contentHeight] gives a cell's content height at a cell width, so every row
/// is as tall as its tallest cell and never under a field's height.
class NeumorphicCellBank extends StatelessWidget {
  /// A bank of [children], [selected] chosen.
  const NeumorphicCellBank({
    super.key,
    required this.children,
    required this.selected,
    required this.minCellWidth,
    required this.contentHeight,
    this.scroll = false,
    this.side,
    this.edge,
    this.naturalWidth,
    this.group,
  });

  /// The cells, in reading order.
  final List<Widget> children;

  /// The chosen cell's index, or -1 for none.
  final int selected;

  /// The least a cell may be before the bank wraps (or scrolls).
  final double minCellWidth;

  /// A cell's content height at a cell width.
  final double Function(double cellWidth) contentHeight;

  /// One row that scrolls sideways when its cells don't fit, as a tab bar does; else the bank wraps.
  final bool scroll;

  /// The bank's own outline width and colour, from a style.
  final BorderSide? side;

  /// The rim's colour alone, from a style; it prints the rim at the look's width.
  final Color? edge;

  /// The width to take when the bank has no bound: the cells at their least, by default.
  final double? naturalWidth;

  /// Wraps the bank itself, inside any sideways scroll: the semantics that group its cells (a tab bar's role) go here, so
  /// no scrolling node comes between the group and its cells.
  final Widget Function(Widget bank)? group;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final t = NeumorphicTheme.of(context);
    final dir = Directionality.of(context);
    final count = children.length;
    return LayoutBuilder(
      builder: (context, box) {
        final least = count * minCellWidth;
        // A tab bar is the page's band on a phone; from a medium window up it keeps to its tabs, from its column's
        // start, scrolling only when they need more than the column (design6 P, 11-12: three tabs spread over a 1440
        // column read as a band). Every other bank takes its own width when wide: its natural width up to the most a
        // control takes, never under what its labels need on one row.
        final available = !box.hasBoundedWidth
            ? naturalWidth ?? least
            : scroll
            ? neumorphicControlWidth(
                context,
                box.maxWidth,
                math.max(least, naturalWidth ?? least),
              )
            : neumorphicControlWidth(
                context,
                box.maxWidth,
                math.max(
                  least,
                  math.min(naturalWidth ?? least, neumorphicWideControlMax),
                ),
              );
        var columns = scroll
            ? count
            : math.max(1, math.min(count, (available / minCellWidth).floor()));
        // A few choices that can't share a row stand one to a row, a short list: in two rows they made a lump (two
        // and one, its last cell double wide) or a grid whose seams gave way round the chosen cell on two sides.
        // More than four are a grid (the hours), its rows as even as the cells allow: five cells in two rows are three
        // and two, not four and one.
        if (!scroll && columns < count) {
          if (count <= 4) {
            columns = 1;
          } else {
            final rows = (count / columns).ceil();
            columns = (count / rows).ceil();
          }
        }
        final cellWidth = scroll
            ? math.max(minCellWidth, available / count)
            : available / columns;
        final width = cellWidth * columns;
        final rows = (count / columns).ceil();
        // As tall as a field beside it (NeumorphicFieldBox): a field's least height, plus the content-safe insets its
        // shape keeps from its corners. One row draws the density's height and its cells reach the platform's target
        // past the face (as a field and a button do); a grid's inner rows have nowhere to reach, so its rows keep it.
        final target = NeumorphicChromeMetrics.targetSize;
        final floor = rows > 1
            ? math.max(target, t.density.height(48))
            : t.density.height(48);
        final content = contentHeight(cellWidth);
        final rowHeight = math.max(floor, content);
        final size = Size(width, rowHeight * rows);
        final over = math.max(0.0, (target - rowHeight) / 2);
        // A capsule holds one line in one row. When a label wraps or the bank breaks into rows, the bank takes the
        // theme's rounded frame instead, as every pill does (inlineRoleShape).
        final wraps = rows > 1 || content > contentHeight(double.infinity) + .5;
        final bankShape = wraps && t.shapes.capsule is NeumorphicStadiumBorder
            ? const NeumorphicRoundedBorder()
            : t.shapes.capsule;
        // The rim the bank prints inside its outline: the cells' faces start inside it.
        final rim =
            side?.width ??
            (edge != null || t.highContrast ? neumorphicEdgeWidth : 0.0);
        // A short last row's cells share its width: an empty place beside them read as a dead cell (Next | ____).
        Rect cellRect(int i) {
          final row = i ~/ columns, col = i % columns;
          final inRow = math.min(columns, count - row * columns);
          final w = width / inRow;
          final visual = dir == TextDirection.rtl ? inRow - 1 - col : col;
          return Rect.fromLTWH(visual * w, row * rowHeight, w, rowHeight);
        }

        // A cell of one row with its reach: past the face by [over] above and below, its outline still the face's.
        Rect reachRect(int i) {
          final r = cellRect(i);
          return Rect.fromLTRB(
            r.left,
            i < columns ? r.top - over : r.top,
            r.right,
            i >= (rows - 1) * columns ? r.bottom + over : r.bottom,
          );
        }

        final bank = Offset.zero & size;
        Widget bankBody = SizedBox.fromSize(
          size: size,
          // The seams over the cells, a foreground paint that takes no taps.
          child: CustomPaint(
            foregroundPainter: _Seams(
              t.colors,
              columns: columns,
              rows: rows,
              count: count,
              cellWidth: cellWidth,
              rowHeight: rowHeight,
              width: neumorphicRuleWidth,
              rtl: dir == TextDirection.rtl,
              chosen: selected,
              outline: NeumorphicShapes.inset(
                bankShape,
                rim,
              ).getOuterPath(bank.deflate(rim)),
              flat: NeumorphicFlatScope.of(context),
            ),
            // What its cells' words take, the least cell on each column: the width a reader of the bank's content
            // (ui_core's width check) is given, the cells being placed by hand.
            child: _ContentWidth(
              width: columns * minCellWidth,
              // Unclipped: a cell's reach runs past the face, and its spoken node with it.
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < count; i++)
                    Positioned.fromRect(
                      rect: reachRect(i),
                      child: Builder(
                        builder: (context) {
                          final r = reachRect(i);
                          return NeumorphicCellScope(
                            border: NeumorphicCellBorder(
                              bank: bankShape,
                              frame: rim,
                              reach: EdgeInsets.fromLTRB(
                                r.left - bank.left,
                                r.top - bank.top,
                                bank.right - r.right,
                                bank.bottom - r.bottom,
                              ),
                              // A chosen cell rounds as a control where it meets its neighbour: at the least round
                              // its inner end read as a square cut (Day | Night, Card | Bank | Later).
                              joins: NeumorphicRadii.control,
                            ),
                            chosen: i == selected,
                            child: children[i],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        // The bank's own face and rim: one raised part, whatever it stands on decides its depth.
        final draw = NeumorphicSurface.resolve(
          NeumorphicSurfaceLevel.part,
          NeumorphicSurface.on(context),
        );
        final rimSide = rim == 0
            ? null
            : BorderSide(
                color: side?.color ?? edge ?? t.colors.edge,
                width: rim,
              );
        bankBody = CustomPaint(
          painter: _BankFace(
            t.colors,
            draw,
            bankShape,
            t.elevation,
            NeumorphicFlatScope.of(context),
          ),
          foregroundPainter: rimSide == null
              ? null
              : _BankRim(bankShape, rimSide),
          child: bankBody,
        );
        // The bank is one control: one item for ui_core's keyline and label checks, whatever its cells hold.
        bankBody = DesignKeylineFace(child: bankBody);
        bankBody = group?.call(bankBody) ?? bankBody;
        // A control's 48 target round the bank's face, as a button and a field keep: the face takes the density's
        // height in it, and a press in the margin reaches the cell it stands over.
        bankBody = NeumorphicReach(
          height: rowHeight * rows + 2 * over,
          child: bankBody,
        );
        if (scroll && width > available + .5) {
          // Room inside the scroll's clip for the bank's own cast; the clip fades out at an end with more cells
          // beyond it, so the bank reads as going on (cut square, its last tab read as gone).
          return _FadedScroll(child: bankBody);
        }
        return Align(
          alignment: AlignmentDirectional.topStart,
          widthFactor: 1,
          heightFactor: 1,
          child: bankBody,
        );
      },
    );
  }
}

class _BankFace extends CustomPainter {
  _BankFace(this.c, this.draw, this.shape, this.elevation, this.flat);
  final NeumorphicColors c;
  final NeumorphicDraw draw;
  final OutlinedBorder shape;
  final NeumorphicElevation elevation;
  final bool flat;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = shape.getOuterPath(Offset.zero & size);
    neumorphicPaintCast(
      canvas,
      outline,
      draw,
      c,
      flat: flat,
      elevation: elevation,
    );
    // Flat, a bank has no relief to be found by: its outline is printed in the quiet ink, as its seams are, so a cell
    // at its end still stands in it (alone, Off floated beside one seam).
    if (flat) canvas.drawPath(outline, neumorphicStrokePaint(c.quiet, 1));
  }

  @override
  bool shouldRepaint(_BankFace o) =>
      o.c != c ||
      o.draw != draw ||
      o.shape != shape ||
      o.elevation != elevation ||
      o.flat != flat;
}

/// The bank's rim, drawn over the cells so the chosen one never covers it.
class _BankRim extends CustomPainter {
  _BankRim(this.shape, this.side);
  final OutlinedBorder shape;
  final BorderSide side;

  @override
  void paint(Canvas canvas, Size size) =>
      shape.copyWith(side: side).paint(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_BankRim o) => o.shape != shape || o.side != side;
}

/// The engraved seams between cells: a crease and a catch-light, full height between rims, clipped to the bank's
/// inner outline. A short last row's cells share its width, so its seams stand where its own cells meet.
class _Seams extends CustomPainter {
  _Seams(
    this.c, {
    required this.columns,
    required this.rows,
    required this.count,
    required this.cellWidth,
    required this.rowHeight,
    required this.width,
    required this.rtl,
    required this.outline,
    required this.flat,
    this.chosen = -1,
  });
  final NeumorphicColors c;
  final int columns, rows, count;

  /// The chosen cell: no seam is cut along its well. Its well is rounded where it meets a neighbour, and a straight
  /// seam beside that round left a notch of the bank's face at each of its corners; without it the well reads as one
  /// pressed shape set in the bank.
  final int chosen;
  final double cellWidth, rowHeight, width;
  final bool rtl, flat;
  final Path outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(outline);
    final dark = Paint()..color = flat ? c.quiet : c.crease;
    final light = Paint()..color = c.rim;
    void vertical(double x, double top, double bottom) {
      canvas.drawRect(Rect.fromLTRB(x - width, top, x, bottom), dark);
      if (!flat) {
        canvas.drawRect(Rect.fromLTRB(x, top, x + width, bottom), light);
      }
    }

    void horizontal(double y, double left, double right) {
      canvas.drawRect(Rect.fromLTRB(left, y - width, right, y), dark);
      if (!flat) {
        canvas.drawRect(Rect.fromLTRB(left, y, right, y + width), light);
      }
    }

    // The chosen cell's span on the screen, in its row.
    Rect? well;
    if (chosen >= 0 && chosen < count) {
      final row = chosen ~/ columns, col = chosen % columns;
      final inRow = math.min(columns, count - row * columns);
      final w = size.width / inRow;
      final left = rtl ? size.width - (col + 1) * w : col * w;
      well = Rect.fromLTWH(left, row * rowHeight, w, rowHeight);
    }
    for (var row = 0; row < rows; row++) {
      final inRow = math.min(columns, count - row * columns);
      final w = size.width / inRow;
      for (var col = 1; col < inRow; col++) {
        final x = rtl ? size.width - col * w : col * w;
        final top = row * rowHeight;
        if (well != null &&
            well.top == top &&
            ((x - well.left).abs() < .5 || (x - well.right).abs() < .5)) {
          continue;
        }
        vertical(x, top, (row + 1) * rowHeight);
      }
      if (row > 0) {
        final y = row * rowHeight;
        if (well != null &&
            ((well.top - y).abs() < .5 || (well.bottom - y).abs() < .5)) {
          horizontal(y, 0, well.left);
          horizontal(y, well.right, size.width);
        } else {
          horizontal(y, 0, size.width);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Seams o) =>
      o.c != c ||
      o.columns != columns ||
      o.rows != rows ||
      o.count != count ||
      o.cellWidth != cellWidth ||
      o.rowHeight != rowHeight ||
      o.width != width ||
      o.rtl != rtl ||
      o.flat != flat ||
      o.chosen != chosen ||
      o.outline != outline;
}

/// The chosen cell's face: the cell pressed in, edge to edge inside its outline, with one even tint of the pigment.
/// It eases in and out with the theme's state motion. Unchosen, it paints nothing: the bank's raised face shows.
class NeumorphicCellFace extends StatelessWidget {
  /// The cell's face under [child].
  const NeumorphicCellFace({super.key, required this.child, this.chosen});

  /// What the cell shows: its label, glyph or mark.
  final Widget child;

  /// Whether the cell is in; null asks its bank (a bank of one choice). A toggle group, where any number are in, says.
  final bool? chosen;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final cell = NeumorphicCellScope.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: (chosen ?? cell.chosen) ? 1 : 0),
      duration: NeumorphicMotion.of(context).state,
      curve: NeumorphicMotion.of(context).standard,
      child: child,
      builder: (context, depth, child) => CustomPaint(
        painter: depth == 0
            ? null
            : _ChosenCell(
                t.colors,
                t.elevation,
                cell.border,
                depth,
                NeumorphicFlatScope.of(context),
                EdgeInsets.zero,
              ),
        child: child,
      ),
    );
  }
}

/// A chosen row's band: the chosen cell's well (the groove's pair inside [border], under the wash) behind [child], run
/// [outset] past it (in, where negative), as a grouped list's row is a band of its card inside its rim.
class NeumorphicChosenBand extends StatelessWidget {
  /// The band behind [child], in when [chosen].
  const NeumorphicChosenBand({
    super.key,
    required this.chosen,
    required this.border,
    this.outset = EdgeInsets.zero,
    required this.child,
  });

  /// Whether the row is the chosen one.
  final bool chosen;

  /// The band's outline.
  final ShapeBorder border;

  /// How far the band runs past [child], side by side.
  final EdgeInsets outset;

  /// The row.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: chosen ? 1 : 0),
      duration: NeumorphicMotion.of(context).state,
      curve: NeumorphicMotion.of(context).standard,
      child: child,
      builder: (context, depth, child) => CustomPaint(
        painter: depth == 0
            ? null
            : _ChosenCell(
                t.colors,
                t.elevation,
                border,
                depth,
                NeumorphicFlatScope.of(context),
                outset,
              ),
        child: child,
      ),
    );
  }
}

class _ChosenCell extends CustomPainter {
  _ChosenCell(
    this.c,
    this.elevation,
    this.border,
    this.depth,
    this.flat,
    this.outset,
  );
  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final ShapeBorder border;
  final double depth;
  final bool flat;
  final EdgeInsets outset;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = border.getOuterPath(outset.inflateRect(Offset.zero & size));
    if (!flat && elevation.depth > 0) {
      final box = shape.getBounds();
      Paint blurred(Color color, double blur) => Paint()
        ..isAntiAlias = true
        ..color = color.withValues(alpha: color.a * depth * elevation.strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2);
      Path outside(Offset by) => Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(box.inflate(24))
        ..addPath(shape, by * elevation.depth);
      canvas.save();
      canvas.clipPath(shape);
      // The groove's pair: light from the top left, dark from the bottom right.
      canvas.drawPath(
        outside(const Offset(-3, -3)),
        blurred(c.highlight, 7 * elevation.depth),
      );
      canvas.drawPath(
        outside(const Offset(3, 3)),
        blurred(c.shadowInset, 7 * elevation.depth),
      );
      canvas.restore();
    }
    canvas.drawPath(
      shape,
      Paint()
        ..isAntiAlias = true
        ..color = c.wash.withValues(alpha: c.wash.a * depth),
    );
  }

  @override
  bool shouldRepaint(_ChosenCell o) =>
      o.c != c ||
      o.elevation != elevation ||
      o.border != border ||
      o.depth != depth ||
      o.flat != flat ||
      o.outset != outset;
}

/// [child] as it is laid out, its intrinsic width [width]: what its content takes, where the child (cells placed by
/// hand) cannot say.
class _ContentWidth extends SingleChildRenderObjectWidget {
  const _ContentWidth({required this.width, required super.child});

  final double width;

  @override
  _RenderContentWidth createRenderObject(BuildContext context) =>
      _RenderContentWidth(width);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderContentWidth renderObject,
  ) {
    renderObject.width = width;
  }
}

class _RenderContentWidth extends RenderShiftedBox {
  _RenderContentWidth(this._width) : super(null);

  double _width;
  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _width;

  @override
  double computeMaxIntrinsicWidth(double height) => _width;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child?.getDryLayout(constraints) ?? constraints.smallest;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = child.size;
    (child.parentData! as BoxParentData).offset = Offset.zero;
  }
}

/// [child] in a sideways scroll whose ends fade out where more lies beyond them, inside [padding]: for a part of
/// another library (a table wider than its room). Hidden from the barrel.
Widget neumorphicFadedScroll({
  EdgeInsets padding = const EdgeInsets.all(8),
  required Widget child,
}) => _FadedScroll(padding: padding, child: child);

/// A sideways scroll whose ends fade out where more lies beyond them: a tab bar's bank, a table wider than its room.
class _FadedScroll extends StatefulWidget {
  /// Scrolls [child] sideways inside [padding].
  const _FadedScroll({
    this.padding = const EdgeInsets.all(8),
    required this.child,
  });

  /// Room inside the scroll's clip round [child] (a bank's own cast).
  final EdgeInsets padding;

  /// What scrolls.
  final Widget child;
  @override
  State<_FadedScroll> createState() => _FadedScrollState();
}

class _FadedScrollState extends State<_FadedScroll> {
  final _scroll = ScrollController();
  var _before = false, _after = true;

  void _edges() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final before = p.pixels > p.minScrollExtent + .5;
    final after = p.pixels < p.maxScrollExtent - .5;
    if (before != _before || after != _after) {
      setState(() {
        _before = before;
        _after = after;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_edges);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _edges();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Ends on the screen: in a right-to-left page the scroll's start is at the right.
    final left = rtl ? _after : _before, right = rtl ? _before : _after;
    const fade = 32.0;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        final w = rect.width <= 0 ? 1.0 : rect.width;
        final edge = (fade / w).clamp(0.0, .5);
        return LinearGradient(
          colors: [
            Color(left ? 0x00000000 : 0xFF000000),
            const Color(0xFF000000),
            const Color(0xFF000000),
            Color(right ? 0x00000000 : 0xFF000000),
          ],
          stops: [0, edge, 1 - edge, 1],
        ).createShader(rect);
      },
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _edges();
          return false;
        },
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}
