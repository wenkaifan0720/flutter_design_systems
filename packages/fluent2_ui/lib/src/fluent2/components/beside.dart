import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/layer.dart';
import '../theme.dart';

/// The desktop's two columns: the [pane] at the start on the ground, and
/// [child] on the content layer beside it, the layer's top-start corner
/// rounded at 8 with a hairline along its top and start edges. Plumbing
/// of the shell and the preview.
class Fluent2Beside extends StatelessWidget {
  /// Stands [pane] beside [child].
  const Fluent2Beside({required this.pane, required this.child, super.key});

  /// The column at the start, on the ground.
  final Widget pane;

  /// The content layer beside the pane.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    const corner = Radius.circular(Fluent2ChromeMetrics.layerRadius);
    final radius = const BorderRadiusDirectional.only(topStart: corner)
        .resolve(Directionality.of(context));
    return ColoredBox(
      color: t.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pane,
          Expanded(
            // Its own semantics container: the routes inside block what
            // was painted before them (a modal barrier does), and the pane
            // was, so without one a screen reader loses the pane.
            child: Semantics(
              container: true,
              child: Padding(
                padding: EdgeInsets.only(
                  top:
                      MediaQuery.paddingOf(context).top +
                      Fluent2ChromeMetrics.paneInset,
                ),
                child: CustomPaint(
                  foregroundPainter: _LayerEdge(
                    color: t.colors.neutralStroke2,
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: ColoredBox(
                      color: Fluent2Layer.fillOf(t),
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        removeLeft: true,
                        child: Fluent2Layer(child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The content layer's edge: a hairline down its start edge, round its
/// top-start corner and along its top.
class _LayerEdge extends CustomPainter {
  _LayerEdge({required this.color, required this.rtl});

  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const r = Fluent2ChromeMetrics.layerRadius;
    const h = Fluent2ChromeMetrics.hairline / 2;
    final path = Path();
    if (rtl) {
      path
        ..moveTo(size.width - h, size.height)
        ..lineTo(size.width - h, r)
        ..arcToPoint(
          Offset(size.width - r, h),
          radius: const Radius.circular(r - h),
          clockwise: false,
        )
        ..lineTo(0, h);
    } else {
      path
        ..moveTo(h, size.height)
        ..lineTo(h, r)
        ..arcToPoint(Offset(r, h), radius: const Radius.circular(r - h))
        ..lineTo(size.width, h);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Fluent2ChromeMetrics.hairline
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_LayerEdge old) => old.color != color || old.rtl != rtl;
}
