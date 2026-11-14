/// The width probe every `ExpressivePressable` carries: whether the parent
/// fixed the component's width (a button group lays its members out at
/// tight widths as they squish), read by the content inside the
/// pressable's surface, whose `Stack` loosens its constraints — a
/// button's label row, an icon button's glyph. Compose's content fills the
/// container and centres whatever width the parent fixes. Internal: the
/// barrel never exports it.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Records whether the button was given a tight width, for the content
/// inside the pressable's surface: the surface's `Stack` loosens its
/// constraints, and Compose's content `Row` fills the container and centres
/// (`horizontalArrangement = Center`) whatever width the parent fixes.
class ExpressiveWidthProbe extends SingleChildRenderObjectWidget {
  /// A probe around [child].
  const ExpressiveWidthProbe({super.key, required super.child});

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderWidthProbe();
}

/// [ExpressiveWidthProbe]'s render object: it remembers whether its width was fixed.
class _RenderWidthProbe extends RenderProxyBox {
  bool _tight = false;

  /// The content that reads the probe, re-laid out when the probe's answer
  /// changes.
  _RenderFillProbedWidth? client;

  @override
  void performLayout() {
    final tight = constraints.hasTightWidth;
    if (tight != _tight) {
      _tight = tight;
      // The client's constraints need not change with ours, so it is
      // re-laid out explicitly (the mutation LayoutBuilder also makes).
      invokeLayoutCallback<BoxConstraints>((_) => client?.markNeedsLayout());
    }
    super.performLayout();
  }
}

/// The content's root: under a probe that was given a tight width it takes
/// the full width it is offered, so the row centres in the container.
class ExpressiveFillProbedWidth extends SingleChildRenderObjectWidget {
  /// A widget filling the width a probe was given, around [child].
  const ExpressiveFillProbedWidth({super.key, required super.child});

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderFillProbedWidth();
}

/// [ExpressiveFillProbedWidth]'s render object, found by its nearest
/// [_RenderWidthProbe] ancestor.
class _RenderFillProbedWidth extends RenderProxyBox {
  _RenderWidthProbe? _probe;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    RenderObject? node = parent;
    while (node != null && node is! _RenderWidthProbe) {
      node = node.parent;
    }
    _probe = node as _RenderWidthProbe?;
    _probe?.client = this;
  }

  @override
  void detach() {
    if (_probe?.client == this) _probe!.client = null;
    _probe = null;
    super.detach();
  }

  @override
  void performLayout() {
    final fill = (_probe?._tight ?? false) && constraints.hasBoundedWidth;
    final inner = fill
        ? constraints.tighten(width: constraints.maxWidth)
        : constraints;
    size = (child!..layout(inner, parentUsesSize: true)).size;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final fill = (_probe?._tight ?? false) && constraints.hasBoundedWidth;
    return child!.getDryLayout(
      fill ? constraints.tighten(width: constraints.maxWidth) : constraints,
    );
  }
}
