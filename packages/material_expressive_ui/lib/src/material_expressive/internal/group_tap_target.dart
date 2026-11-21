import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// [TapTargetPadding]'s layout and reach without a node of its own, for a
/// target whose parts are nodes already: a pressable's
/// `ExpressiveSemanticsGroup` spans its target, and a range slider's two
/// handles are a slider each. [TapTargetPadding] merges what it holds into
/// one node, which would make those parts one.
class ExpressiveGroupTapTarget extends TapTargetPadding {
  /// A target at least [minSize] round [child], [child] placed by
  /// [alignment].
  const ExpressiveGroupTapTarget({
    required Size super.minSize,
    super.alignment,
    required super.child,
    super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGroupTapTarget(
        minSize!,
        alignment: alignment,
        textDirection: Directionality.maybeOf(context),
        devicePixelRatio:
            MediaQuery.maybeDevicePixelRatioOf(context) ??
            View.maybeOf(context)?.devicePixelRatio ??
            1,
      );
}

class _RenderGroupTapTarget extends RenderTapTargetPadding {
  _RenderGroupTapTarget(
    super.minSize, {
    super.alignment,
    super.textDirection,
    super.devicePixelRatio,
  });

  // The parts' own nodes stand; this target adds none.
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {}
}
