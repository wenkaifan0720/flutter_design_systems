/// A group of chips or tags that wraps onto more runs, its controls' tap
/// targets taking the room between their faces.
library;

// A private named parameter (this._spacing) would need Dart 3.12's language,
// which an app the kit is copied into may not have.
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'tap_target.dart';

/// A group of chips, tags or filters that wraps onto more runs as [Wrap]
/// does, its controls' tap targets taking the room between their faces.
///
/// Each child is a control laid out at the touch floor by [TapTargetPadding]:
/// its box is its target, its face smaller inside it. A [Wrap] puts its
/// spacing between the boxes, so faces smaller than the floor stand the
/// spacing and their targets' room apart: 32 px chips on a 40 floor, 8
/// apart, stand 16 apart, a gap the eye reads as two groups. A chip group
/// puts [spacing] and [runSpacing] between the faces instead and lets the
/// targets reach into it: two faces stand the spacing apart, or as far as
/// their targets need where that is more (the floor less the face), so the
/// targets meet or stand apart and never overlap, and each keeps the floor.
/// A child with no tap target of its own is its own face, as in a [Wrap].
///
/// Its runs go along [direction] and stack across it, placed by
/// [alignment], [runAlignment] and [crossAxisAlignment] as a [Wrap] places
/// them; right to left (and [VerticalDirection.up]) mirror them.
///
/// ```dart
/// RawChipGroup(spacing: 8, runSpacing: 8, children: [for (final tag in const ['Planning', 'Design']) TapTargetPadding(child: Text(tag))])
/// ```
class RawChipGroup extends MultiChildRenderObjectWidget {
  /// A group of [children], [spacing] between faces in a run and
  /// [runSpacing] between runs.
  const RawChipGroup({
    super.key,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    super.children,
  }) : assert(spacing >= 0, 'spacing is not negative'),
       assert(runSpacing >= 0, 'runSpacing is not negative');

  /// The way a run goes: across for chips in lines, down for chips in
  /// columns.
  final Axis direction;

  /// How the children of a run are placed along it, as [Wrap.alignment].
  final WrapAlignment alignment;

  /// The least room between two faces in a run, as the look spaces its
  /// chips; their targets take it where it is enough, and push the faces
  /// further apart where it is not.
  final double spacing;

  /// How the runs are placed across the group, as [Wrap.runAlignment].
  final WrapAlignment runAlignment;

  /// The least room between the faces of two runs, as [spacing] is in one.
  final double runSpacing;

  /// How the children of a run are placed across it, as
  /// [Wrap.crossAxisAlignment].
  final WrapCrossAlignment crossAxisAlignment;

  /// The direction a horizontal run goes in (and the side a vertical group
  /// starts on); null reads the ambient [Directionality].
  final TextDirection? textDirection;

  /// The way runs stack (and a vertical run goes): down by default.
  final VerticalDirection verticalDirection;

  @override
  RenderChipGroup createRenderObject(BuildContext context) => RenderChipGroup(
    direction: direction,
    alignment: alignment,
    spacing: spacing,
    runAlignment: runAlignment,
    runSpacing: runSpacing,
    crossAxisAlignment: crossAxisAlignment,
    textDirection: textDirection ?? Directionality.maybeOf(context),
    verticalDirection: verticalDirection,
  );

  @override
  void updateRenderObject(BuildContext context, RenderChipGroup renderObject) {
    renderObject
      ..direction = direction
      ..alignment = alignment
      ..spacing = spacing
      ..runAlignment = runAlignment
      ..runSpacing = runSpacing
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..verticalDirection = verticalDirection;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('direction', direction))
      ..add(
        EnumProperty<WrapAlignment>(
          'alignment',
          alignment,
          defaultValue: WrapAlignment.start,
        ),
      )
      ..add(DoubleProperty('spacing', spacing, defaultValue: 0))
      ..add(
        EnumProperty<WrapAlignment>(
          'runAlignment',
          runAlignment,
          defaultValue: WrapAlignment.start,
        ),
      )
      ..add(DoubleProperty('runSpacing', runSpacing, defaultValue: 0))
      ..add(
        EnumProperty<WrapCrossAlignment>(
          'crossAxisAlignment',
          crossAxisAlignment,
          defaultValue: WrapCrossAlignment.start,
        ),
      )
      ..add(
        EnumProperty<TextDirection>(
          'textDirection',
          textDirection,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<VerticalDirection>(
          'verticalDirection',
          verticalDirection,
          defaultValue: VerticalDirection.down,
        ),
      );
  }
}

/// Where a [RenderChipGroup] places a child.
class ChipGroupParentData extends ContainerBoxParentData<RenderBox> {}

/// [RawChipGroup]'s render object: its children in runs as a [RenderWrap]
/// lays them out, the room between two faces the spacing or their targets'
/// room, whichever is more.
class RenderChipGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ChipGroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ChipGroupParentData> {
  /// A group laid out as the arguments say.
  RenderChipGroup({
    Axis direction = Axis.horizontal,
    WrapAlignment alignment = WrapAlignment.start,
    double spacing = 0,
    WrapAlignment runAlignment = WrapAlignment.start,
    double runSpacing = 0,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    List<RenderBox>? children,
  }) : _direction = direction,
       _alignment = alignment,
       _spacing = spacing,
       _runAlignment = runAlignment,
       _runSpacing = runSpacing,
       _crossAxisAlignment = crossAxisAlignment,
       _textDirection = textDirection,
       _verticalDirection = verticalDirection {
    addAll(children);
  }

  /// [RawChipGroup.direction].
  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  /// [RawChipGroup.alignment].
  WrapAlignment get alignment => _alignment;
  WrapAlignment _alignment;
  set alignment(WrapAlignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  /// [RawChipGroup.spacing].
  double get spacing => _spacing;
  double _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  /// [RawChipGroup.runAlignment].
  WrapAlignment get runAlignment => _runAlignment;
  WrapAlignment _runAlignment;
  set runAlignment(WrapAlignment value) {
    if (_runAlignment == value) return;
    _runAlignment = value;
    markNeedsLayout();
  }

  /// [RawChipGroup.runSpacing].
  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  /// [RawChipGroup.crossAxisAlignment].
  WrapCrossAlignment get crossAxisAlignment => _crossAxisAlignment;
  WrapCrossAlignment _crossAxisAlignment;
  set crossAxisAlignment(WrapCrossAlignment value) {
    if (_crossAxisAlignment == value) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  /// [RawChipGroup.textDirection], resolved.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// [RawChipGroup.verticalDirection].
  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection == value) return;
    _verticalDirection = value;
    markNeedsLayout();
  }

  bool get _flipMain => switch (direction) {
    Axis.horizontal => textDirection == TextDirection.rtl,
    Axis.vertical => verticalDirection == VerticalDirection.up,
  };

  bool get _flipCross => switch (direction) {
    Axis.horizontal => verticalDirection == VerticalDirection.up,
    Axis.vertical => textDirection == TextDirection.rtl,
  };

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ChipGroupParentData) {
      child.parentData = ChipGroupParentData();
    }
  }

  // The room a child's target takes round its face, in the order the runs
  // flow: (along before, along after, across before, across after).
  _Room _roomOf(Size size, Rect face) {
    final left = face.left, top = face.top;
    final right = size.width - face.right, bottom = size.height - face.bottom;
    final (mainStart, mainEnd, crossStart, crossEnd) = switch (direction) {
      Axis.horizontal => (left, right, top, bottom),
      Axis.vertical => (top, bottom, left, right),
    };
    double room(double v) => math.max(0, v);
    return (
      room(_flipMain ? mainEnd : mainStart),
      room(_flipMain ? mainStart : mainEnd),
      room(_flipCross ? crossEnd : crossStart),
      room(_flipCross ? crossStart : crossEnd),
    );
  }

  // A child's face as laid out: its TapTargetPadding's child, reached
  // through single-child boxes, as the target last placed it; else its whole
  // box.
  static Rect _laidFace(RenderBox child) {
    RenderObject node = child;
    var offset = Offset.zero;
    while (true) {
      if (node is RenderTapTargetPadding) {
        final face = node.faceRect;
        return face == null ? Offset.zero & child.size : face.shift(offset);
      }
      RenderObject? next;
      var count = 0;
      node.visitChildren((c) {
        next = c;
        count++;
      });
      final only = next;
      if (count != 1 || only == null) return Offset.zero & child.size;
      final data = only.parentData;
      if (data is BoxParentData) offset += data.offset;
      node = only;
    }
  }

  // A child's face as its dry layout gives it: a TapTargetPadding's child
  // placed in its target by its alignment, reached through boxes that pass
  // their constraints on; else the child's whole box.
  Rect _dryFace(RenderBox child, BoxConstraints constraints, Size size) {
    RenderObject node = child;
    while (true) {
      if (node is RenderTapTargetPadding) {
        final face = node.child;
        if (face == null) break;
        final faceSize = face.getDryLayout(constraints);
        final free = size - faceSize as Offset;
        final at = node.alignment.resolve(node.textDirection).alongOffset(free);
        return at & faceSize;
      }
      if (node is! RenderProxyBox || node.child == null) break;
      node = node.child!;
    }
    return Offset.zero & size;
  }

  _Laid _lay(
    BoxConstraints constraints, {
    required Size Function(RenderBox child, BoxConstraints constraints) sizeOf,
    required Rect Function(
      RenderBox child,
      BoxConstraints constraints,
      Size size,
    )
    faceOf,
  }) {
    final horizontal = direction == Axis.horizontal;
    final childConstraints = horizontal
        ? BoxConstraints(maxWidth: constraints.maxWidth)
        : BoxConstraints(maxHeight: constraints.maxHeight);
    final limit = horizontal ? constraints.maxWidth : constraints.maxHeight;
    final runs = <_Run>[];
    var run = _Run();
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final size = sizeOf(child, childConstraints);
      final room = _roomOf(size, faceOf(child, childConstraints, size));
      final main = horizontal ? size.width : size.height;
      final cross = horizontal ? size.height : size.width;
      final gap = run.isEmpty
          ? 0.0
          : math.max(0.0, spacing - run.trailing - room.$1);
      if (!run.isEmpty &&
          run.main + gap + main > limit + precisionErrorTolerance) {
        runs.add(run);
        run = _Run();
      }
      run.add(
        child,
        size,
        main,
        cross,
        room,
        run.isEmpty ? 0.0 : math.max(0.0, spacing - run.trailing - room.$1),
      );
    }
    if (!run.isEmpty) runs.add(run);
    // Across: each run's children placed in it, then the room its faces
    // leave at its two sides.
    for (final r in runs) {
      r.placeAcross(crossAxisAlignment);
    }
    var mainExtent = 0.0;
    var crossExtent = 0.0;
    final runGaps = <double>[];
    for (var i = 0; i < runs.length; i++) {
      mainExtent = math.max(mainExtent, runs[i].main);
      final gap = i == 0
          ? 0.0
          : math.max(
              0.0,
              runSpacing - runs[i - 1].crossTrailing - runs[i].crossLeading,
            );
      runGaps.add(gap);
      crossExtent += gap + runs[i].cross;
    }
    final size = constraints.constrain(
      horizontal
          ? Size(mainExtent, crossExtent)
          : Size(crossExtent, mainExtent),
    );
    return _Laid(runs, runGaps, size, crossExtent);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _lay(
    constraints,
    sizeOf: (child, c) => child.getDryLayout(c),
    faceOf: _dryFace,
  ).size;

  @override
  double computeMinIntrinsicWidth(double height) => switch (direction) {
    Axis.horizontal => _childExtents(
      (c) => c.getMinIntrinsicWidth(double.infinity),
    ),
    Axis.vertical => computeDryLayout(BoxConstraints(maxHeight: height)).width,
  };

  @override
  double computeMaxIntrinsicWidth(double height) => switch (direction) {
    Axis.horizontal => computeDryLayout(const BoxConstraints()).width,
    Axis.vertical => computeDryLayout(BoxConstraints(maxHeight: height)).width,
  };

  @override
  double computeMinIntrinsicHeight(double width) => switch (direction) {
    Axis.horizontal => computeDryLayout(BoxConstraints(maxWidth: width)).height,
    Axis.vertical => _childExtents(
      (c) => c.getMinIntrinsicHeight(double.infinity),
    ),
  };

  @override
  double computeMaxIntrinsicHeight(double width) => switch (direction) {
    Axis.horizontal => computeDryLayout(BoxConstraints(maxWidth: width)).height,
    Axis.vertical => computeDryLayout(const BoxConstraints()).height,
  };

  double _childExtents(double Function(RenderBox child) of) {
    var most = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      most = math.max(most, of(child));
    }
    return most;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  @override
  void performLayout() {
    final laid = _lay(
      constraints,
      sizeOf: (child, c) {
        child.layout(c, parentUsesSize: true);
        return child.size;
      },
      faceOf: (child, c, size) => _laidFace(child),
    );
    size = laid.size;
    final horizontal = direction == Axis.horizontal;
    final mainSize = horizontal ? size.width : size.height;
    final crossSize = horizontal ? size.height : size.width;
    final runFree = math.max(0.0, crossSize - laid.crossExtent);
    final (runLead, runBetween) = _distribute(
      runAlignment,
      runFree,
      laid.runs.length,
    );
    var crossAt = runLead;
    for (var i = 0; i < laid.runs.length; i++) {
      final run = laid.runs[i];
      crossAt += laid.runGaps[i] + (i == 0 ? 0 : runBetween);
      final (lead, between) = _distribute(
        alignment,
        math.max(0.0, mainSize - run.main),
        run.children.length,
      );
      var mainAt = lead;
      for (var j = 0; j < run.children.length; j++) {
        final c = run.children[j];
        mainAt += c.gap + (j == 0 ? 0 : between);
        final main = _flipMain ? mainSize - mainAt - c.main : mainAt;
        final across = crossAt + c.across;
        final cross = _flipCross ? crossSize - across - c.cross : across;
        (c.child.parentData! as ChipGroupParentData).offset = horizontal
            ? Offset(main, cross)
            : Offset(cross, main);
        mainAt += c.main;
      }
      crossAt += run.cross;
    }
  }

  // Where free room goes as [alignment] places [count] items: before the
  // first, and between each two.
  static (double, double) _distribute(
    WrapAlignment alignment,
    double free,
    int count,
  ) => switch (alignment) {
    WrapAlignment.start => (0.0, 0.0),
    WrapAlignment.end => (free, 0.0),
    WrapAlignment.center => (free / 2, 0.0),
    WrapAlignment.spaceBetween =>
      count > 1 ? (0.0, free / (count - 1)) : (0.0, 0.0),
    WrapAlignment.spaceAround =>
      count > 0 ? (free / count / 2, free / count) : (0.0, 0.0),
    WrapAlignment.spaceEvenly =>
      count > 0 ? (free / (count + 1), free / (count + 1)) : (0.0, 0.0),
  };

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('direction', direction))
      ..add(DoubleProperty('spacing', spacing))
      ..add(DoubleProperty('runSpacing', runSpacing))
      ..add(
        EnumProperty<TextDirection>(
          'textDirection',
          textDirection,
          defaultValue: null,
        ),
      );
  }
}

// The room a child's target takes round its face, in flow order: along
// before, along after, across before, across after.
typedef _Room = (double, double, double, double);

class _Laid {
  _Laid(this.runs, this.runGaps, this.size, this.crossExtent);

  final List<_Run> runs;
  final List<double> runGaps;
  final Size size;
  final double crossExtent;
}

class _Placed {
  _Placed(this.child, this.main, this.cross, this.room, this.gap);

  final RenderBox child;
  final double main;
  final double cross;
  final _Room room;
  final double gap;
  // Its offset across the run, from the run's start.
  double across = 0;
}

class _Run {
  final children = <_Placed>[];
  double main = 0;
  double cross = 0;
  double crossLeading = 0;
  double crossTrailing = 0;

  bool get isEmpty => children.isEmpty;

  // The room the last child's target takes after its face along the run.
  double get trailing => children.isEmpty ? 0 : children.last.room.$2;

  void add(
    RenderBox child,
    Size size,
    double childMain,
    double childCross,
    _Room room,
    double gap,
  ) {
    children.add(_Placed(child, childMain, childCross, room, gap));
    main += gap + childMain;
    cross = math.max(cross, childCross);
  }

  // Places each child across the run, then reads the room its faces leave
  // before and after them across it.
  void placeAcross(WrapCrossAlignment alignment) {
    var leading = double.infinity;
    var trailing = double.infinity;
    for (final c in children) {
      final free = cross - c.cross;
      c.across = switch (alignment) {
        WrapCrossAlignment.start => 0,
        WrapCrossAlignment.end => free,
        WrapCrossAlignment.center => free / 2,
      };
      leading = math.min(leading, c.across + c.room.$3);
      trailing = math.min(trailing, cross - c.across - c.cross + c.room.$4);
    }
    crossLeading = leading.isFinite ? leading : 0;
    crossTrailing = trailing.isFinite ? trailing : 0;
  }
}
