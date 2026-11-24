// The laid-out room a compact face of several targets stands in at a
// finger (a field with its clear glyph, a strip of joined buttons, a row
// of stars): [TapTargetPadding] for a part that is more than one control.
// TapTargetPadding sends a tap in its room to the child's centre, which is
// right for one control; a band sends it to the nearest point of the face,
// so a tap above a strip's third button presses the third. The room is in
// the layout, so the area a tap reaches is the band's box. Not exported:
// the parts call it, pages never do.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'controls.dart';

/// [child] (a face [face] tall, or its own height when null) laid out with
/// as much room above and below as brings it up to the tap floor at the
/// context ([minimalTapFloor]), and, when [across] is set, as much at
/// either side as brings a face [across] wide up to it. A tap in the room,
/// or on the face's outermost [inset], lands [inset] inside the face's
/// nearest edge, where its own control takes it.
class MinimalTapBand extends SingleChildRenderObjectWidget {
  /// The band round [child].
  const MinimalTapBand({
    super.key,
    this.face,
    this.across,
    this.inset = 4,
    required Widget super.child,
  });

  /// The face's height the room is reckoned from; null: the child's own.
  final double? face;

  /// The face's width the side room is reckoned from; null: no side room.
  final double? across;

  /// How far inside the face's nearest edge a tap in the room lands.
  final double inset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMinimalTapBand(minimalTapFloor(context), face, across, inset);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMinimalTapBand renderObject,
  ) {
    renderObject
      ..floor = minimalTapFloor(context)
      ..face = face
      ..across = across
      ..inset = inset;
  }
}

/// [MinimalTapBand]'s render object.
class RenderMinimalTapBand extends RenderShiftedBox {
  /// A band reckoned from a tap floor.
  RenderMinimalTapBand(this._floor, this._face, this._across, this._inset)
    : super(null);

  double _floor;

  /// Sets the floor.
  set floor(double v) {
    if (v == _floor) return;
    _floor = v;
    markNeedsLayout();
  }

  double? _face;

  /// Sets the face.
  set face(double? v) {
    if (v == _face) return;
    _face = v;
    markNeedsLayout();
  }

  double? _across;

  /// Sets the across.
  set across(double? v) {
    if (v == _across) return;
    _across = v;
    markNeedsLayout();
  }

  double _inset;

  /// Sets the inset.
  set inset(double v) {
    if (v == _inset) return;
    _inset = v;
  }

  double _airDown(double height) =>
      math.max(0, (_floor - (_face ?? height)) / 2);

  double _airAcross() {
    final across = _across;
    return across == null ? 0 : math.max(0, (_floor - across) / 2);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      (child?.getMinIntrinsicWidth(height) ?? 0) + 2 * _airAcross();

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height) ?? 0) + 2 * _airAcross();

  @override
  double computeMinIntrinsicHeight(double width) {
    final h = child?.getMinIntrinsicHeight(width) ?? 0;
    return h + 2 * _airDown(h);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final h = child?.getMaxIntrinsicHeight(width) ?? 0;
    return h + 2 * _airDown(h);
  }

  BoxConstraints _inner(BoxConstraints constraints, double down) => constraints
      .deflate(EdgeInsets.symmetric(horizontal: _airAcross(), vertical: down));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    // The room depends on the face, so the face is measured first.
    final probe = child.getDryLayout(_inner(constraints, 0));
    final down = _airDown(probe.height);
    final face = child.getDryLayout(_inner(constraints, down));
    return constraints.constrain(
      Size(face.width + 2 * _airAcross(), face.height + 2 * down),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final down = _face == null ? null : _airDown(0);
    if (down != null) {
      child.layout(_inner(constraints, down), parentUsesSize: true);
    } else {
      child.layout(_inner(constraints, 0), parentUsesSize: true);
    }
    final air = down ?? _airDown(child.size.height);
    final side = _airAcross();
    size = constraints.constrain(
      Size(child.size.width + 2 * side, child.size.height + 2 * air),
    );
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final at = (child.parentData! as BoxParentData).offset;
    final extent = child.size;
    double into(double v, double length) {
      final edge = math.min(_inset, length / 2);
      return v.clamp(edge, length - edge);
    }

    // Also inside the face, a tap on its rim lands [inset] in, so a control
    // standing just inside the rim reaches the band's edge unbroken.
    final local = position - at;
    final inside = Offset(
      into(local.dx, extent.width),
      into(local.dy, extent.height),
    );
    if (inside == local) return super.hitTest(result, position: position);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(inside),
      position: inside,
      hitTest: (result, _) => child.hitTest(result, position: inside),
    );
  }
}

/// [child] reached from anywhere its parent lets a tap through: a tap past
/// its box, or in its air between and round its parts, lands [inset] inside
/// the nearest part's nearest edge (past its rim). For a run of controls
/// smaller than the box they stand in (a field's tags and entry, a short
/// tag beside a taller entry), so a tap in the box's air above or below
/// them reaches the one under it.
class MinimalTapReach extends SingleChildRenderObjectWidget {
  /// [child] reached from its parent's whole box.
  const MinimalTapReach({
    super.key,
    this.inset = MinimalSpacing.s4,
    required Widget super.child,
  });

  /// How far inside the run's nearest edge a tap past it lands.
  final double inset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMinimalTapReach(inset);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMinimalTapReach renderObject,
  ) => renderObject.inset = inset;
}

/// [MinimalTapReach]'s render object.
class RenderMinimalTapReach extends RenderProxyBox {
  /// A reach landing [inset] inside the run.
  RenderMinimalTapReach(this.inset);

  /// How far inside the run's nearest edge a tap past it lands.
  double inset;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.isEmpty) return false;
    if (size.contains(position) && super.hitTest(result, position: position)) {
      return true;
    }
    final part = _nearest(position);
    if (part == null) return false;
    double into(double v, double start, double length) {
      final edge = math.min(inset, length / 2);
      return v.clamp(start + edge, start + length - edge);
    }

    final inside = Offset(
      into(position.dx, part.left, part.width),
      into(position.dy, part.top, part.height),
    );
    if (inside == position) return false;
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(inside),
      position: inside,
      hitTest: (result, _) => super.hitTest(result, position: inside),
    );
  }

  // The part of the run nearest [position], in this box's coordinates: a
  // child of the run (a tag, the entry), else the run itself.
  Rect? _nearest(Offset position) {
    final run = child;
    if (run == null || !run.hasSize) return null;
    final parts = <Rect>[];
    run.visitChildren((part) {
      final at = part.parentData;
      if (part is RenderBox && part.hasSize && at is BoxParentData) {
        if (!part.size.isEmpty) parts.add(at.offset & part.size);
      }
    });
    if (parts.isEmpty) parts.add(Offset.zero & run.size);
    Rect? best;
    var least = double.infinity;
    for (final r in parts) {
      final dx = math.max(
        0.0,
        math.max(r.left - position.dx, position.dx - r.right),
      );
      final dy = math.max(
        0.0,
        math.max(r.top - position.dy, position.dy - r.bottom),
      );
      final d = dx * dx + dy * dy;
      if (d < least) {
        least = d;
        best = r;
      }
    }
    return best;
  }
}

/// [child] (the controls inside a compact face: a field's clear glyph, its
/// password eye) under floors of [height]: each control keeps the floor's
/// width, laid out, and stands no taller than the face, whose
/// [MinimalTapBand] gives it the floor's height. Pass the face's height
/// inside its rim as [height] where a key is shorter than the face (a 28
/// glyph in a 40 toolbar field), so the face's air above and below the key
/// is the key's, not the field's. The floors outside stay readable
/// ([minimalBandFloor]).
Widget minimalInlineTargets(
  BuildContext context,
  Widget child, {
  double height = 0,
}) {
  final targets = RawTapTargets.of(context);
  return _BandTargets(
    targets: _BandTargets.maybeOf(context) ?? targets,
    child: RawTapTargetScope(
      targets: targets.copyWith(
        touch: Size(targets.touch.width, height),
        pointer: Size(targets.pointer.width, height),
      ),
      child: child,
    ),
  );
}

/// [target] as its one screen-reader node, as tall as the band it stands
/// in under [minimalInlineTargets] (a field's clear glyph, its eye): the
/// band's room reaches it, so the box a screen reader outlines is the one a
/// tap reaches. Elsewhere [target] as it is.
Widget minimalInlineNode(BuildContext context, Widget target) {
  if (_BandTargets.maybeOf(context) == null) return target;
  return _BandNode(floor: minimalBandFloor(context), child: target);
}

class _BandNode extends SingleChildRenderObjectWidget {
  const _BandNode({required this.floor, required Widget super.child});

  final double floor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBandNode(floor);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderBandNode).floor = floor;
}

class _RenderBandNode extends RenderProxyBox {
  _RenderBandNode(this._floor);

  double _floor;

  set floor(double v) {
    if (v == _floor) return;
    _floor = v;
    markNeedsSemanticsUpdate();
  }

  // The band's height, on the control's middle.
  @override
  Rect get semanticBounds => Rect.fromCenter(
    center: size.center(Offset.zero),
    width: size.width,
    height: math.max(size.height, _floor),
  );

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}

/// The tap floor's height of the band a face stands in: under
/// [minimalInlineTargets], the floor outside it, else [minimalTapFloor].
double minimalBandFloor(BuildContext context) =>
    _BandTargets.maybeOf(context)?.floorOn().height ?? minimalTapFloor(context);

class _BandTargets extends InheritedWidget {
  const _BandTargets({required this.targets, required super.child});

  final RawTapTargets targets;

  static RawTapTargets? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BandTargets>()?.targets;

  @override
  bool updateShouldNotify(_BandTargets oldWidget) =>
      targets != oldWidget.targets;
}

/// A compact face of several controls (a strip of joined toggles, a field
/// with its steppers) as one band: its controls keep the floor's width
/// ([minimalInlineTargets]) and the band round the face gives them the
/// floor's height ([MinimalTapBand]).
Widget minimalTapStrip(BuildContext context, Widget face) =>
    MinimalTapBand(child: minimalInlineTargets(context, face));

/// The gap between two small buttons side by side on an end keyline (a
/// month's arrows), both faces on their targets' end: none where a finger's
/// targets already hold the faces apart, [MinimalSpacing.s8] where a
/// pointer's do not.
double minimalArrowGap(BuildContext context) => math.max(
  0,
  MinimalSpacing.s8 -
      math.max(0, minimalTapFloor(context) - MinimalChromeMetrics.controlSm),
);

/// Where the faces of the controls under it stand in their tap targets
/// ([MinimalPressable.tapAlignment] for the ones that do not say): a list
/// row's trailing slot stands its control on the end keyline, a field its
/// trailing keys. Not exported: the parts set it.
class MinimalTapAlignment extends InheritedWidget {
  /// [child]'s controls placed by [alignment].
  const MinimalTapAlignment({
    super.key,
    required this.alignment,
    required super.child,
  });

  /// Where a face stands in its target.
  final AlignmentGeometry alignment;

  /// The alignment over [context], or null.
  static AlignmentGeometry? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MinimalTapAlignment>()
      ?.alignment;

  @override
  bool updateShouldNotify(MinimalTapAlignment oldWidget) =>
      alignment != oldWidget.alignment;
}
