/// A strip of keys or legends that scrolls sideways when it is wider than
/// its room (a bank of keys at 200% text on a phone, say), and stands still
/// when it fits.
library;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// [child] (a row of keys or legends) in its room, scrolled sideways when
/// it is wider. With [fill] it stands at least as wide as its room (a
/// strip whose line runs the width). Only a strip that scrolls is clipped
/// (a focus ring drawn just outside the room still shows): one that fits
/// keeps every glow and shadow round its keys.
class StudioStrip extends StatefulWidget {
  /// A strip of [child].
  const StudioStrip({super.key, required this.child, this.fill = false});

  /// The row.
  final Widget child;

  /// Whether it stands at least its room's width.
  final bool fill;

  @override
  State<StudioStrip> createState() => _StudioStripState();
}

class _StudioStripState extends State<StudioStrip> {
  bool _scrolls = false;

  bool _measured(ScrollMetricsNotification note) {
    final scrolls = note.metrics.maxScrollExtent > 0;
    if (scrolls != _scrolls && mounted) setState(() => _scrolls = scrolls);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Widget strip(double? least) => ClipRect(
      clipper: const _Outset(StudioMetrics.focusGap + StudioMetrics.focusWidth),
      clipBehavior: _scrolls ? Clip.hardEdge : Clip.none,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _measured,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: least == null
              ? widget.child
              : ConstrainedBox(
                  constraints: BoxConstraints(minWidth: least),
                  child: widget.child,
                ),
        ),
      ),
    );
    if (!widget.fill) return strip(null);
    return LayoutBuilder(
      builder: (context, constraints) =>
          strip(constraints.hasBoundedWidth ? constraints.maxWidth : null),
    );
  }
}

// The room, grown by [by] on every side.
class _Outset extends CustomClipper<Rect> {
  const _Outset(this.by);

  final double by;

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(by);

  @override
  bool shouldReclip(_Outset old) => old.by != by;
}
