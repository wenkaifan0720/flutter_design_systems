// One trough for every row of choices Comic draws (segmented buttons, tabs, the pager and the stepper): a single rim
// around cells that stand side by side with no dividers, and, where one cell is chosen, a floating thumb. The thumb is
// the trough's own outline moved in by the rim and one gap on every side (concentric: each corner is the trough's
// less that inset, floored at zero; a capsule's thumb is a capsule), and it slides from cell to cell on the motion
// tokens. Cells take one width, so no choice reads larger than another, and a cell's words never move when it is
// chosen: only their ink changes.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../press.dart';
import '../styled.dart';
import '../theme.dart';

/// The trough: [shape] filled with [fill] and ringed by [rim], holding [cells] in reading order.
///
/// The trough stands exactly a field's height. A cell gets the trough's whole height, the rim's bands above and below
/// it included (the rim is drawn over the cells), so its press is the trough's full target and a 48 px touch target
/// never makes the trough taller than the field beside it; what a cell draws stands the rim and [gap] in from the
/// trough's outline, in [cellShape] ([shape] inset by the rim and [gap]). With [lit] set, the thumb, [thumb]-filled
/// in [cellShape], sits under that cell and slides when [lit] changes (a cut under Reduce Motion).
///
/// With [equal] every cell takes the widest one's width (or [cellWidth] where the row is unbounded), shrinking all
/// alike where the row is narrower; without it each cell takes its own width and [grow] cells share what is left.
class ComicTrack extends StatelessWidget {
  /// Creates a trough.
  const ComicTrack({
    super.key,
    required this.shape,
    required this.rim,
    required this.fill,
    required this.cells,
    this.thumb,
    this.lit,
    this.gap = ComicTrack.inset,
    this.equal = true,
    this.cellWidth,
    this.grow = const {},
    this.minHeight,
  });

  /// How far a cell's face and the thumb stand inside the rim: 2, so a chosen cell reads filled, its thumb a hair
  /// inside the rim (the design kit's checks holds a chosen fill to its cell, short by at most a quarter of its height; the
  /// user, on Retro: "the highlight doesnt fill the entire tab, is that by design?").
  static const double inset = 2;

  /// The trough's outline.
  final OutlinedBorder shape;

  /// The trough's rim.
  final BorderSide rim;

  /// The trough's fill.
  final Color fill;

  /// The thumb's fill.
  final Color? thumb;

  /// The chosen cell, from zero; null draws no thumb.
  final int? lit;

  /// The room between the rim and a cell's face.
  final double gap;

  /// Whether every cell takes one width.
  final bool equal;

  /// One cell's width where the row is unbounded; null takes the widest cell's.
  final double? cellWidth;

  /// Cells, by position, that take the width the others leave when [equal] is false.
  final Set<int> grow;

  /// The least outer height; null takes a field's.
  final double? minHeight;

  /// The cells, in reading order.
  final List<Widget> cells;

  /// The outline a cell's face, wash and ring take inside a trough of [shape] with [rim].
  static OutlinedBorder cellShape(
    OutlinedBorder shape,
    BorderSide rim, [
    double gap = inset,
  ]) => comicInsetShape(shape, rim.width + gap);

  /// A field's height at [context]: the trough stands as tall as the fields beside it.
  static double fieldHeight(BuildContext context) => math.max(
    ComicTapTarget.targetOf(context),
    ComicTheme.of(context).density.height(48),
  );

  @override
  Widget build(BuildContext context) {
    final inner = cellShape(shape, rim, gap);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final motion = ComicMotion.of(context);
    final height = minHeight ?? fieldHeight(context);
    final lit = this.lit;
    return _TrackRim(
      rim: rim.width,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(shape: shape.copyWith(side: rim)),
        child: DecoratedBox(
          decoration: ShapeDecoration(color: fill, shape: shape),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: rim.width),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: lit?.toDouble() ?? -1),
              duration: still || lit == null ? Duration.zero : motion.state,
              curve: motion.standard,
              builder: (context, at, _) => _Cells(
                thumbAt: lit == null ? null : at,
                thumbShape: inner,
                thumb: thumb,
                gap: gap,
                equal: equal,
                cellWidth: cellWidth == null
                    ? null
                    : math.max(0, cellWidth! - 2 * rim.width / cells.length),
                grow: grow,
                height: math.max(0, height),
                rim: rim.width,
                direction: Directionality.of(context),
                children: cells,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rim's width, for the faces of a trough's cells: a cell spans the rim's bands, its face stands inside them.
class _TrackRim extends InheritedWidget {
  const _TrackRim({required this.rim, required super.child});

  final double rim;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TrackRim>()?.rim ?? 0;

  @override
  bool updateShouldNotify(_TrackRim old) => rim != old.rim;
}

/// A cell's face inside a trough: [child] centred [gap] inside the cell, with the press's marks in [shape], so its
/// wash and ring are concentric with the trough and the thumb. Where the row is too narrow for a cell's words they
/// shrink on one line rather than break, so every cell keeps one height and its words their place.
class ComicTrackFace extends StatelessWidget {
  /// Creates a cell face.
  const ComicTrackFace({
    super.key,
    required this.states,
    required this.shape,
    required this.child,
    this.gap = ComicTrack.inset,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.overlay,
    this.fill,
  });

  /// A styled part's wash for these states, drawn as given.
  final Color? overlay;

  /// The cell's own fill in [shape], under its marks: a cell lit on its own where several can be on at once (a toggle
  /// group), as the thumb lights one.
  final Color? fill;

  /// The press's states.
  final Set<WidgetState> states;

  /// The cell's outline: the trough's less the rim and [gap].
  final OutlinedBorder shape;

  /// What the cell says.
  final Widget child;

  /// The room between the rim and the face.
  final double gap;

  /// The room inside the face: by default 14, so with the trough's 2.5 rim and the 2 px [gap] an end cell's words
  /// stand on a text field's keyline ([comicFieldWords]) from the trough's outline.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: gap,
      vertical: gap + _TrackRim.of(context),
    ),
    child: ComicStateDecoration(
      decoration: fill == null
          ? const BoxDecoration()
          : ShapeDecoration(color: fill, shape: shape),
      child: ComicHighlight(
        states: states,
        shape: shape,
        overlay: overlay,
        child: Padding(
          padding: padding,
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ),
    ),
  );
}

class _Cells extends MultiChildRenderObjectWidget {
  const _Cells({
    required this.thumbAt,
    required this.thumbShape,
    required this.thumb,
    required this.gap,
    required this.equal,
    required this.cellWidth,
    required this.grow,
    required this.height,
    required this.rim,
    required this.direction,
    required super.children,
  });

  final double? thumbAt;
  final OutlinedBorder thumbShape;
  final Color? thumb;
  final double gap;
  final bool equal;
  final double? cellWidth;
  final Set<int> grow;
  final double height;
  final double rim;
  final TextDirection direction;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCells()
    ..thumbAt = thumbAt
    ..thumbShape = thumbShape
    ..thumb = thumb
    ..gap = gap
    ..equal = equal
    ..cellWidth = cellWidth
    ..grow = grow
    ..least = height
    ..rim = rim
    ..direction = direction;

  @override
  void updateRenderObject(BuildContext context, _RenderCells cells) => cells
    ..thumbAt = thumbAt
    ..thumbShape = thumbShape
    ..thumb = thumb
    ..gap = gap
    ..equal = equal
    ..cellWidth = cellWidth
    ..grow = grow
    ..least = height
    ..rim = rim
    ..direction = direction;
}

class _CellData extends ContainerBoxParentData<RenderBox> {}

class _RenderCells extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellData> {
  double? _thumbAt;
  set thumbAt(double? v) {
    if (v == _thumbAt) return;
    _thumbAt = v;
    markNeedsPaint();
  }

  OutlinedBorder? _thumbShape;
  set thumbShape(OutlinedBorder v) {
    if (v == _thumbShape) return;
    _thumbShape = v;
    markNeedsPaint();
  }

  Color? _thumb;
  set thumb(Color? v) {
    if (v == _thumb) return;
    _thumb = v;
    markNeedsPaint();
  }

  double _gap = 0;
  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsPaint();
  }

  bool _equal = true;
  set equal(bool v) {
    if (v == _equal) return;
    _equal = v;
    markNeedsLayout();
  }

  double? _cellWidth;
  set cellWidth(double? v) {
    if (v == _cellWidth) return;
    _cellWidth = v;
    markNeedsLayout();
  }

  Set<int> _grow = const {};
  set grow(Set<int> v) {
    if (setEquals(v, _grow)) return;
    _grow = v;
    markNeedsLayout();
  }

  double _least = 0;
  set least(double v) {
    if (v == _least) return;
    _least = v;
    markNeedsLayout();
  }

  double _rim = 0;
  set rim(double v) {
    if (v == _rim) return;
    _rim = v;
    markNeedsPaint();
  }

  TextDirection _direction = TextDirection.ltr;
  set direction(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellData) child.parentData = _CellData();
  }

  List<RenderBox> get _kids => getChildrenAsList();

  /// Each cell's width and the row's height under [constraints].
  (List<double>, double) _measure(BoxConstraints constraints) {
    final kids = _kids;
    if (kids.isEmpty) return (const [], _least);
    final room = constraints.maxWidth;
    List<double> widths;
    if (_equal) {
      // [_cellWidth] stands only in an unbounded row; a bounded one hugs the widest cell.
      var one =
          (room.isFinite ? null : _cellWidth) ??
          kids
              .map((k) => k.getMaxIntrinsicWidth(double.infinity))
              .reduce(math.max);
      if (room.isFinite && one * kids.length > room) {
        // Equal cells too wide for the row (large text, a narrow phone): an equal cell would shrink only the longest
        // words. Each cell takes its own words' width instead, the room left shared out; past that, every cell's
        // words shrink by one factor, its face's own room (a default face's padding and gap) held.
        final natural = [
          for (final k in kids) k.getMaxIntrinsicWidth(double.infinity),
        ];
        final sum = natural.fold<double>(0, (a, b) => a + b);
        final n = kids.length;
        if (sum <= room) {
          widths = [for (final w in natural) w + (room - sum) / n];
        } else {
          const pad = 2 * (14 + ComicTrack.inset);
          final words = natural.map((w) => math.max(0.0, w - pad));
          final total = words.fold<double>(0, (a, b) => a + b);
          final s = total <= 0
              ? 0.0
              : ((room - n * pad) / total).clamp(0.0, 1.0);
          widths = [
            for (final w in natural)
              math.min(w, pad) + s * math.max(0.0, w - pad),
          ];
          final drawn = widths.fold<double>(0, (a, b) => a + b);
          // A row too narrow for even the faces' own room: the cells shrink together.
          if (drawn > room) widths = [for (final w in widths) w * room / drawn];
        }
      } else {
        // Given more than it needs (a tab bar across its column), the cells share it: the fill covers its cells.
        if (constraints.minWidth > one * kids.length) {
          one = constraints.minWidth / kids.length;
        }
        widths = List.filled(kids.length, one);
      }
    } else {
      widths = [
        for (var i = 0; i < kids.length; i++)
          _grow.contains(i) ? 0 : kids[i].getMaxIntrinsicWidth(double.infinity),
      ];
      final fixed = widths.fold<double>(0, (a, b) => a + b);
      final growing = [
        for (var i = 0; i < kids.length; i++)
          if (_grow.contains(i)) i,
      ];
      if (growing.isNotEmpty) {
        final wanted = [
          for (final i in growing)
            kids[i].getMaxIntrinsicWidth(double.infinity),
        ];
        final left = room.isFinite
            ? math.max(0.0, room - fixed)
            : wanted.fold<double>(0, (a, b) => a + b);
        final each = room.isFinite ? left / growing.length : null;
        for (var k = 0; k < growing.length; k++) {
          widths[growing[k]] = each ?? wanted[k];
        }
      } else if (room.isFinite && fixed > room) {
        final k = room / fixed;
        widths = [for (final w in widths) w * k];
      }
    }
    var height = _least;
    for (var i = 0; i < kids.length; i++) {
      height = math.max(height, kids[i].getMaxIntrinsicHeight(widths[i]));
    }
    return (widths, height);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) {
    final kids = _kids;
    if (kids.isEmpty) return 0;
    if (_equal) {
      return kids.length *
          kids
              .map((k) => k.getMaxIntrinsicWidth(double.infinity))
              .reduce(math.max);
    }
    return kids.fold<double>(
      0,
      (a, k) => a + k.getMaxIntrinsicWidth(double.infinity),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _measure(BoxConstraints(maxWidth: width)).$2;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _measure(BoxConstraints(maxWidth: width)).$2;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final (widths, height) = _measure(constraints);
    return constraints.constrain(
      Size(widths.fold<double>(0, (a, b) => a + b), height),
    );
  }

  final List<Rect> _cells = [];

  @override
  void performLayout() {
    final (widths, height) = _measure(constraints);
    final total = widths.fold<double>(0, (a, b) => a + b);
    size = constraints.constrain(Size(total, height));
    _cells.clear();
    var x = _direction == TextDirection.rtl ? size.width : 0.0;
    final kids = _kids;
    for (var i = 0; i < kids.length; i++) {
      final w = widths[i];
      kids[i].layout(BoxConstraints.tight(Size(w, size.height)));
      final left = _direction == TextDirection.rtl ? x - w : x;
      (kids[i].parentData! as _CellData).offset = Offset(left, 0);
      _cells.add(Rect.fromLTWH(left, 0, w, size.height));
      x = _direction == TextDirection.rtl ? x - w : x + w;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final at = _thumbAt, thumb = _thumb, shape = _thumbShape;
    if (at != null && thumb != null && shape != null && _cells.isNotEmpty) {
      final i = at.clamp(0, _cells.length - 1).toDouble();
      final from = _cells[i.floor()], to = _cells[i.ceil()];
      // The cells span the rim's bands above and below; the thumb stands the rim and the gap inside the outline.
      final rect = EdgeInsets.symmetric(
        horizontal: _gap,
        vertical: _gap + _rim,
      ).deflateRect(Rect.lerp(from, to, i - i.floor())!);
      context.canvas.drawPath(
        shape.getOuterPath(rect.shift(offset), textDirection: _direction),
        Paint()..color = thumb,
      );
    }
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Where a boxed control's words start inside its box, before density: a text field's 16 inside its 2.5 rim. Fields,
/// selects and choices stacked in a panel share it, so their words stand on one inner keyline.
const double comicFieldWords = 16 + 2.5;

/// [comicFieldWords] under [t]'s density.
double comicFieldWordsAt(ComicThemeData t) => t.density
    .padding(const EdgeInsets.symmetric(horizontal: comicFieldWords))
    .left;

/// The room inside a picker's box under [t]'s density: its words on [comicFieldWords], as a text field's; a select's
/// list sets its words on [EdgeInsetsDirectional.start].
EdgeInsetsDirectional comicFieldInset(ComicThemeData t) {
  final p = t.density.padding(
    const EdgeInsets.symmetric(horizontal: comicFieldWords, vertical: 8),
  );
  return EdgeInsetsDirectional.fromSTEB(p.left, p.top, p.right, p.bottom);
}

/// The most a dropdown's closed face takes from 600 up (a dropdown's width): its content's width or a form
/// grid's cell, never a whole column.
const double comicDropdownMost = 320;

/// [face], a dropdown's closed face with its label, kept to [comicDropdownMost] at the start of the width it is given
/// from 600 up; on a phone it takes its column. The face is marked ([ComicAnchorFace]) so a menu anchored on the
/// wider room around it opens from the face.
Widget comicDropdownWidth(BuildContext context, Widget face) {
  final marked = ComicAnchorFace(child: face);
  if (ComicTheme.of(context).width < 600) return marked;
  return Align(
    alignment: AlignmentDirectional.topStart,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: comicDropdownMost),
      child: marked,
    ),
  );
}

/// Marks a dropdown's drawn face inside the room [comicDropdownWidth] gives it; [comicAnchorFaceOf] finds it.
class ComicAnchorFace extends SingleChildRenderObjectWidget {
  /// Creates a [ComicAnchorFace].
  const ComicAnchorFace({super.key, super.child});

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderAnchorFace();
}

class _RenderAnchorFace extends RenderProxyBox {}

/// The box a menu opens from when anchored on [root]: the marked face found down [root]'s single-child chain, or
/// [root] itself.
RenderBox comicAnchorFaceOf(RenderBox root) {
  RenderObject? at = root;
  while (at != null) {
    if (at is _RenderAnchorFace) return at;
    RenderObject? only;
    var count = 0;
    at.visitChildren((child) {
      only = child;
      count++;
    });
    at = count == 1 ? only : null;
  }
  return root;
}

/// From 600 wide up a button keeps to its words (the design kit's DesignWidthCheck: a button stretched across its
/// column reads as a banner). Forced wider than [comicDropdownMost] (a column that stretches its children, a block
/// button's whole width), it takes its content's width at the start of the room it is given; under that, or on a
/// phone, it takes what its parent gives it.
class ComicButtonRoom extends SingleChildRenderObjectWidget {
  /// Creates a [ComicButtonRoom].
  const ComicButtonRoom({super.key, required Widget super.child});

  @override
  RenderShiftedBox createRenderObject(BuildContext context) =>
      _RenderButtonRoom(
        ComicTheme.of(context).width >= 600,
        Directionality.of(context),
      );

  @override
  void updateRenderObject(BuildContext context, RenderShiftedBox renderObject) {
    (renderObject as _RenderButtonRoom)
      ..wide = ComicTheme.of(context).width >= 600
      ..direction = Directionality.of(context);
  }
}

class _RenderButtonRoom extends RenderShiftedBox {
  _RenderButtonRoom(this._wide, this._direction) : super(null);

  bool _wide;
  set wide(bool value) {
    if (value == _wide) return;
    _wide = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  bool _holds(BoxConstraints c) => _wide && c.minWidth > comicDropdownMost;

  BoxConstraints _inner(RenderBox child, BoxConstraints c) {
    final words = child.getMaxIntrinsicWidth(
      c.hasBoundedHeight ? c.maxHeight : double.infinity,
    );
    return c.copyWith(minWidth: 0, maxWidth: math.min(c.maxWidth, words));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    if (!_holds(constraints)) return child.getDryLayout(constraints);
    final face = child.getDryLayout(_inner(child, constraints));
    return constraints.constrain(face);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final data = child.parentData! as BoxParentData;
    if (!_holds(constraints)) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
      data.offset = Offset.zero;
      return;
    }
    child.layout(_inner(child, constraints), parentUsesSize: true);
    size = constraints.constrain(child.size);
    data.offset = Offset(
      _direction == TextDirection.rtl ? size.width - child.size.width : 0,
      (size.height - child.size.height) / 2,
    );
  }
}
