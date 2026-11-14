import 'package:flutter/widgets.dart';

/// A horizontally scrolling strip's affordance: the strip's own content
/// fades out over a short run at each edge beyond which more of it lies, so
/// a table, a code line or a tab strip cut by the screen reads as
/// scrollable rather than clipped. Drawn only while there is more to reach
/// on that side; a strip that fits shows none.
///
/// The fade masks the content's alpha rather than painting a colour over
/// it, so it holds on any ground — the page, a sheet, a card, the code
/// block's sunken well — and never bleaches a header band, a hairline or a
/// selected row's tint. Not exported: the scrolling components wrap their
/// own scroll view in it.
class MinimalEdgeFade extends StatefulWidget {
  /// Fades [child]'s scrolled-off edges over [width].
  const MinimalEdgeFade({
    super.key,
    required this.child,
    this.width = extent,
    this.reach = 0,
  });

  /// The strip: a horizontal scroll view, directly or a few boxes down.
  final Widget child;

  /// The fade's run at each edge.
  final double width;

  /// How far past an unfaded end the strip's content may paint (a tab's
  /// press wash and ring stand out beyond its words). Past a faded end
  /// nothing paints, so a scrolled-off label never shows beyond the fade.
  /// Zero leaves the clipping to the caller.
  final double reach;

  /// The fade's default run at each edge.
  static const double extent = 20;

  @override
  State<MinimalEdgeFade> createState() => _MinimalEdgeFadeState();
}

class _MinimalEdgeFadeState extends State<MinimalEdgeFade> {
  /// Whether more of the strip lies off the left and off the right edge.
  bool _left = false;
  bool _right = false;

  bool _read(ScrollMetrics metrics) {
    if (metrics.axis != Axis.horizontal) return false;
    final before = metrics.extentBefore > _slack;
    final after = metrics.extentAfter > _slack;
    final reversed = metrics.axisDirection == AxisDirection.left;
    final left = reversed ? after : before;
    final right = reversed ? before : after;
    if (left != _left || right != _right) {
      setState(() {
        _left = left;
        _right = right;
      });
    }
    return false;
  }

  /// Sub-pixel scroll extents are not "more".
  static const double _slack = 0.5;

  static const Color _opaque = Color(0xFFFFFFFF);
  static const Color _clear = Color(0x00FFFFFF);

  Shader _mask(Rect bounds, {required bool left, required bool right}) {
    final run = bounds.width <= 0
        ? 0.0
        : (widget.width / bounds.width).clamp(0.0, 0.5);
    return LinearGradient(
      colors: [
        left ? _clear : _opaque,
        _opaque,
        _opaque,
        right ? _clear : _opaque,
      ],
      stops: [0, run, 1 - run, 1],
    ).createShader(bounds);
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) => _read(n.metrics),
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) => _read(n.metrics),
          // Always mounted, so the strip's scroll state survives the fade
          // coming and going; a strip that fits is masked fully opaque.
          child: _ends(
            ShaderMask(
              blendMode: BlendMode.dstIn,
              // A fresh callback per build, so a change of side repaints.
              shaderCallback: (bounds) =>
                  _mask(bounds, left: _left, right: _right),
              child: widget.child,
            ),
          ),
        ),
      );

  /// The strip cut at a faded end and given [MinimalEdgeFade.reach] past an
  /// unfaded one; the same tree either way, so the scroll state survives.
  Widget _ends(Widget strip) => widget.reach <= 0
      ? strip
      : ClipRect(
          clipper: _Ends(
            left: _left ? 0 : widget.reach,
            right: _right ? 0 : widget.reach,
          ),
          child: strip,
        );
}

/// A clip open above and below, and [left] and [right] past the ends.
class _Ends extends CustomClipper<Rect> {
  const _Ends({required this.left, required this.right});

  final double left;
  final double right;

  /// Room above and below: the caller's own clip decides there.
  static const double _open = 1e4;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-left, -_open, size.width + right, size.height + _open);

  @override
  bool shouldReclip(_Ends old) => old.left != left || old.right != right;
}
