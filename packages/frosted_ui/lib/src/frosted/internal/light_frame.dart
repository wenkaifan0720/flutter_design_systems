import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The box one light is laid over: the app below a host. A page's backdrop
/// under it ([FrostedAnchoredLight]) paints the part of that one light that
/// falls in its own box, so pages standing side by side (a list beside its
/// detail, a page beside the navigation) show one continuous light, never
/// two meeting in a straight seam.
class FrostedLightFrame extends SingleChildRenderObjectWidget {
  /// The frame round [child].
  const FrostedLightFrame({super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLightFrame();
}

class _RenderLightFrame extends RenderProxyBox {
  final Set<_RenderAnchoredLight> _lights = <_RenderAnchoredLight>{};

  @override
  void performLayout() {
    final before = hasSize ? size : null;
    super.performLayout();
    // A light whose own box kept its size still spans the frame's: it
    // paints again when the frame changes size.
    if (before != size) {
      for (final light in _lights) {
        light.markNeedsPaint();
      }
    }
  }
}

/// A backdrop's light, laid over the nearest [FrostedLightFrame] and painted
/// within its own box: [painter] (or [decoration]) drawn at the frame's size
/// from the frame's corner. Where it stands is taken from layout, not from a
/// transition's movement, so a page sliding in carries its part of the
/// light with it. With no frame above it (or a sliver between them) it lays
/// the light over its own box.
class FrostedAnchoredLight extends LeafRenderObjectWidget {
  /// A light drawn by [painter] or [decoration] (one of them).
  const FrostedAnchoredLight({this.painter, this.decoration, super.key})
    : assert((painter == null) != (decoration == null));

  /// The light, painted at the frame's size.
  final CustomPainter? painter;

  /// The light as a decoration (an image backdrop), painted at the frame's
  /// size.
  final Decoration? decoration;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderAnchoredLight(
    painter: painter,
    decoration: decoration,
    configuration: createLocalImageConfiguration(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderAnchoredLight)
      ..painter = painter
      ..decoration = decoration
      ..configuration = createLocalImageConfiguration(context);
  }
}

class _RenderAnchoredLight extends RenderBox {
  _RenderAnchoredLight({
    required this._configuration,
    this._painter,
    this._decoration,
  });

  _RenderLightFrame? _frame;

  CustomPainter? _painter;
  set painter(CustomPainter? value) {
    final old = _painter;
    if (identical(old, value)) return;
    _painter = value;
    if (old == null ||
        value == null ||
        value.runtimeType != old.runtimeType ||
        value.shouldRepaint(old)) {
      markNeedsPaint();
    }
  }

  Decoration? _decoration;
  BoxPainter? _boxPainter;
  set decoration(Decoration? value) {
    if (value == _decoration) return;
    _boxPainter?.dispose();
    _boxPainter = null;
    _decoration = value;
    markNeedsPaint();
  }

  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var node = parent;
    while (node != null && node is! _RenderLightFrame) {
      node = node.parent;
    }
    _frame = node as _RenderLightFrame?;
    _frame?._lights.add(this);
  }

  @override
  void detach() {
    _frame?._lights.remove(this);
    _frame = null;
    _boxPainter?.dispose();
    _boxPainter = null;
    super.detach();
  }

  @override
  void dispose() {
    _boxPainter?.dispose();
    _boxPainter = null;
    super.dispose();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  /// Where this box stands in its frame, by the offsets layout gave each box
  /// between them (a proxy's child stands at its corner); null when
  /// something other than a box stands between (a sliver), or there is no
  /// frame.
  Offset? _place() {
    final frame = _frame;
    if (frame == null || !frame.hasSize) return null;
    var at = Offset.zero;
    RenderObject node = this;
    while (!identical(node, frame)) {
      final up = node.parent;
      if (up is! RenderBox) return null;
      if (node.parentData case final BoxParentData data) at += data.offset;
      node = up;
    }
    return at;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final place = _place();
    final canvas = context.canvas..save();
    // Its part of the frame's light, cut to its own box; with no frame, the
    // light over its own box, painted as a CustomPaint or a DecoratedBox
    // paints it.
    final whole = place == null ? size : _frame!.size;
    if (place != null) canvas.clipRect(offset & size);
    final origin = offset - (place ?? Offset.zero);
    canvas.translate(origin.dx, origin.dy);
    if (_painter case final painter?) {
      painter.paint(canvas, whole);
    } else if (_decoration case final decoration?) {
      (_boxPainter ??= decoration.createBoxPainter(
        markNeedsPaint,
      )).paint(canvas, Offset.zero, _configuration.copyWith(size: whole));
    }
    canvas.restore();
  }
}
