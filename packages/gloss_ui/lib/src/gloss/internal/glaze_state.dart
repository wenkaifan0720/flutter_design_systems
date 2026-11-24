/// Interaction lighting for parts that paint their own shape or own their
/// editable child’s pointer gestures.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../surface.dart';
import '../theme.dart';

/// Animates the light going into a custom-painted part.
Widget animatedGlazePaint(
  BuildContext context,
  Color light,
  CustomPainter Function(Color light) painter, {
  Widget? child,
}) {
  Widget paint(Color value, Widget? content) =>
      CustomPaint(painter: painter(value), child: content);
  if (RawMotionPolicy.of(context).reduceMotion) return paint(light, child);
  return TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: light),
    duration: const Duration(milliseconds: 140),
    curve: Curves.easeOut,
    child: child,
    builder: (context, value, content) => paint(value!, content),
  );
}

/// A glazed face whose child handles the actual pointer gestures. Observing
/// the pointer here leaves editing, selection and dragging with the child.
class GlazePointerSurface extends StatelessWidget {
  /// Places [child] on the interactive [face].
  const GlazePointerSurface({
    super.key,
    required this.face,
    required this.enabled,
    this.child,
  });

  /// The surface with its current keyboard and selection state.
  final GlossFace face;

  /// Whether the part responds to the pointer.
  final bool enabled;

  /// The content drawn over the glaze.
  final Widget? child;

  @override
  Widget build(BuildContext context) => GlazePointerBuilder(
    enabled: enabled,
    builder: (over, pressed) {
      final pointer = glossGlazeOf(GlossTheme.of(context).colors, {
        if (over) WidgetState.hovered,
        if (pressed) WidgetState.pressed,
      });
      final light = enabled && (pressed || pointer.a > face.focus.a)
          ? pointer
          : face.focus;
      return AnimatedGlossSurface(
        face: face.copyWith(focus: light, travel: pressed ? 1 : face.travel),
        child: child,
      );
    },
  );
}

/// Supplies pointer state without joining the child's gesture arena.
class GlazePointerBuilder extends StatefulWidget {
  /// Observes pointer changes in the area produced by [builder].
  const GlazePointerBuilder({
    super.key,
    required this.enabled,
    required this.builder,
  });

  /// Whether the part responds to the pointer.
  final bool enabled;

  /// Builds the part from the current pointer state.
  final Widget Function(bool hovered, bool pressed) builder;
  @override
  State<GlazePointerBuilder> createState() => _GlazePointerBuilderState();
}

class _GlazePointerBuilderState extends State<GlazePointerBuilder> {
  bool _over = false;
  int? _pointer;

  void _release(PointerEvent event) {
    if (event.pointer == _pointer) setState(() => _pointer = null);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    onEnter: (_) => setState(() => _over = true),
    onExit: (_) => setState(() => _over = false),
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: widget.enabled
          ? (event) => setState(() => _pointer = event.pointer)
          : null,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: widget.builder(
        widget.enabled && _over,
        widget.enabled && _pointer != null,
      ),
    ),
  );
}
