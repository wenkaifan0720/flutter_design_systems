import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// Lays out [count] cells through [builder], each under the key it is
/// handed, and stands [pill] under the [selected] one, inset by [inset]:
/// when the choice changes the pill slides to it (at once under Reduce
/// Motion). Null [selected] stands no pill. The selection of the navigation
/// bar, the segmented control and the filter chips. Plumbing of the
/// components.
class FrostedSlidingPill extends StatefulWidget {
  /// Creates a [FrostedSlidingPill].
  const FrostedSlidingPill({
    required this.count,
    required this.selected,
    required this.pill,
    required this.builder,
    this.inset = EdgeInsets.zero,
    super.key,
  });

  /// How many cells [builder] lays out.
  final int count;

  /// The cell the pill stands under; null for none.
  final int? selected;

  /// What slides.
  final Widget pill;

  /// Lays out the cells, cell `i` keyed with `keys[i]`.
  final Widget Function(BuildContext context, List<Key> keys) builder;

  /// How far inside its cell the pill stands.
  final EdgeInsets inset;

  @override
  State<FrostedSlidingPill> createState() => _FrostedSlidingPillState();
}

class _FrostedSlidingPillState extends State<FrostedSlidingPill> {
  final _cells = <GlobalKey>[];

  /// Where the pill stands, measured after the cells' layout.
  Rect? _at;

  /// Whether the pill has stood anywhere yet: its first place is taken at
  /// once, not slid to.
  bool _placed = false;

  @override
  Widget build(BuildContext context) {
    while (_cells.length < widget.count) {
      _cells.add(GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final at = _at;
    final moves = FrostedMotion.of(context).moves && _placed;
    return Stack(
      children: [
        if (at != null)
          AnimatedPositioned.fromRect(
            rect: at,
            duration: moves
                ? FrostedChromeMetrics.selectionSlide
                : Duration.zero,
            curve: Curves.easeOutCubic,
            child: IgnorePointer(child: widget.pill),
          ),
        widget.builder(context, _cells.sublist(0, widget.count)),
      ],
    );
  }

  void _measure() {
    if (!mounted) return;
    final i = widget.selected;
    Rect? next;
    final me = context.findRenderObject() as RenderBox?;
    final cell = i == null || i >= _cells.length
        ? null
        : _cells[i].currentContext?.findRenderObject() as RenderBox?;
    if (me != null && cell != null && me.hasSize && cell.hasSize) {
      final o = cell.localToGlobal(Offset.zero, ancestor: me);
      next = widget.inset.deflateRect(o & cell.size);
    }
    if (next != _at) {
      setState(() {
        _placed = _at != null;
        _at = next;
      });
    }
  }
}
