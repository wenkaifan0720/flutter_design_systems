import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Reports its child's laid-out height to [onHeight] after the frame that
/// changed it (the shell's measured allowance). Plumbing of the shell and
/// the preview.
class Fluent2ReportHeight extends SingleChildRenderObjectWidget {
  /// Reports [child]'s height to [onHeight].
  const Fluent2ReportHeight({
    required this.onHeight,
    required super.child,
    super.key,
  });

  /// Called with the child's height after a frame that changed it.
  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportHeight(onHeight);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderReportHeight).onHeight = onHeight;
  }
}

class _RenderReportHeight extends RenderProxyBox {
  _RenderReportHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(height);
    });
  }
}
