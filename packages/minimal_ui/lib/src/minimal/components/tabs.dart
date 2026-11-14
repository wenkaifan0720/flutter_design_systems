import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/edge_fade.dart';
import '../internal/face.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'pressable.dart';

/// In-page section tabs — Overview · Activity · Notes on a detail page: a
/// 44 px strip over the page's hairline, 13 px medium labels (the current
/// one in the ink, the rest quiet) with an optional mono count beside each,
/// and a 2 px ink underline under the current tab. A strip wider than the
/// screen scrolls sideways.
///
/// The strip is ONE focus stop: focused, the current tab wears the 2 px
/// focus ring and the arrow keys move the choice to the neighbour (Home and
/// End to the ends), scrolling it into view — focus and choice never part,
/// so a following Enter or Space changes nothing. A screen reader meets each
/// tab as a button that announces itself selected. [padding] insets the
/// labels (pass `MinimalInsets.gutter` on a full-bleed page: the first
/// label's glyphs sit exactly on the gutter) while the hairline runs edge
/// to edge. A null [onChanged] disables the strip.
///
/// ```dart
/// MinimalTabBar(tabs: ['Overview', 'Activity', 'Notes'], counts: [null, 12, 3], selectedIndex: tab, onChanged: go)
/// ```
class MinimalTabBar extends StatefulWidget {
  /// A strip of [tabs].
  const MinimalTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onChanged,
    this.counts,
    this.padding = EdgeInsets.zero,
  });

  /// The tabs' names.
  final List<String> tabs;

  /// The current tab.
  final int selectedIndex;

  /// Null disables the strip.
  final ValueChanged<int>? onChanged;

  /// One count per tab (null for a tab without one), printed in mono after
  /// its label.
  final List<int?>? counts;

  /// The strip's inset for its labels; the hairline under them ignores it.
  final EdgeInsetsGeometry padding;

  @override
  State<MinimalTabBar> createState() => _MinimalTabBarState();
}

const double _underline = 2;

/// How far a tab's press wash and focus ring stand past its words.
const double _halo = MinimalSpacing.s8;

/// The pressable's own wash, turned off: the tab paints a wider one.
const MinimalStyle _ownWash = MinimalStyle(
  overlay: WidgetStatePropertyAll<Color?>(Color(0x00000000)),
);

class _MinimalTabBarState extends State<MinimalTabBar> {
  bool _focus = false;
  List<GlobalKey> _keys = const [];

  List<GlobalKey> _keysFor(int n) {
    if (_keys.length != n) _keys = [for (var i = 0; i < n; i++) GlobalKey()];
    return _keys;
  }

  @override
  void didUpdateWidget(MinimalTabBar old) {
    super.didUpdateWidget(old);
    if (widget.selectedIndex == old.selectedIndex) return;
    // A choice made off screen (a key press, a parent) scrolls into view.
    final forward = widget.selectedIndex > old.selectedIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.selectedIndex >= _keys.length) return;
      final tab = _keys[widget.selectedIndex].currentContext;
      if (tab == null) return;
      final instant = tab.minimalStill;
      Scrollable.ensureVisible(
        tab,
        duration: instant ? Duration.zero : MinimalMotion.base,
        curve: MinimalMotion.out,
        alignmentPolicy: forward
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  void _select(int i) {
    final onChanged = widget.onChanged;
    if (onChanged == null || i == widget.selectedIndex) return;
    HapticFeedback.selectionClick();
    onChanged(i);
  }

  void _move(MinimalSeek seek, bool rtl) {
    _select(
      minimalSeekIndex(
        seek,
        index: widget.selectedIndex,
        last: widget.tabs.length - 1,
        rtl: rtl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    final counts = widget.counts;
    final index = widget.selectedIndex;
    assert(counts == null || counts.length == tabs.length, 'a count per tab');
    assert(index >= 0 && index < tabs.length, 'index out of range');
    final t = context.minimalTheme;
    final enabled = widget.onChanged != null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final instant = context.minimalStill;
    final keys = _keysFor(tabs.length);

    Widget tab(int i) {
      final selected = i == index;
      final count = counts?[i];
      // The strip is the focus stop, so a tab is a tap and a screen-reader
      // button but never a stop of its own; the current tab shows the
      // strip's focus.
      return KeyedSubtree(
        key: keys[i],
        child: MinimalPressable(
          onPressed: enabled ? () => _select(i) : null,
          enabled: enabled,
          shape: t.shapes.mark,
          selected: selected,
          focusable: false,
          // The tab paints its own wash, wider than its words.
          style: _ownWash,
          builder: (context, states) => SizedBox(
            height: MinimalChromeMetrics.row,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The press wash and the strip's focus ring stand [_halo]
                // past the words on either side, so neither hugs a glyph;
                // the tab's width, and so the strip's layout, stay the
                // words'.
                Positioned(
                  left: -_halo,
                  right: -_halo,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: minimalFrame(
                        t.shapes.mark,
                        fill: states.down
                            ? minimalPressInk(t).withValues(alpha: 0.08)
                            : null,
                        side: selected && _focus && enabled
                            ? BorderSide(
                                color: t.ring,
                                width: t.focusWidth,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              )
                            : BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // The label and count ARE the tab's width, so the first
                // label's glyphs start exactly at the strip's inset.
                Center(
                  widthFactor: 1,
                  // The label and its count each by their capitals, on the
                  // tab's middle.
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The label's ink lerps as the tab is chosen.
                      MinimalFace(
                        ink: selected ? t.foreground : t.mutedForeground,
                        builder: (context, ink) => minimalCapLabel(
                          Text(
                            tabs[i],
                            style: t.bodySmall.medium.c(
                              ink ?? t.mutedForeground,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                      if (count != null) ...[
                        const MinimalGap(MinimalControlMetrics.countGap),
                        minimalCapLabel(
                          Text(
                            '$count',
                            style: t.countFigure.c(t.mutedForeground),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: instant ? Duration.zero : MinimalMotion.fast,
                    curve: MinimalMotion.out,
                    height: _underline,
                    decoration: BoxDecoration(
                      color: selected
                          ? t.foreground
                          : t.foreground.withValues(alpha: 0),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(_underline / 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      shortcuts: minimalSeekShortcuts,
      actions: <Type, Action<Intent>>{
        MinimalSeekIntent: CallbackAction<MinimalSeekIntent>(
          onInvoke: (intent) {
            _move(intent.seek, rtl);
            return null;
          },
        ),
      },
      // The page's rule paints first, so the current tab's underline lies
      // over it rather than under it.
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: t.rule)),
        // The strip, and so its hairline, takes the width it is given (its
        // labels' alone where the width is unbounded).
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          heightFactor: 1,
          // Scrolled labels stop at the strip's ends (the fade cuts a faded
          // end); the halo and the focus ring, which stand past a tab's
          // words, keep their room at an unfaded end and above and below.
          child: ClipRect(
            clipper: const _StripClip(),
            child: MinimalEdgeFade(
              reach: _reach,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: widget.padding,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++) ...[
                      if (i > 0) const MinimalGap(MinimalChromeMetrics.gutter),
                      tab(i),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How far past the strip's ends a tab's halo and its ring reach.
const double _reach = _halo + MinimalChromeMetrics.focusRing;

/// The strip's scroll clip: its own width, give or take a tab's halo and
/// the focus ring round it, and generous room above and below for the ring.
class _StripClip extends CustomClipper<Rect> {
  const _StripClip();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -_reach,
    -MinimalChromeMetrics.gutter,
    size.width + _reach,
    size.height + MinimalChromeMetrics.gutter,
  );

  @override
  bool shouldReclip(_StripClip oldClipper) => false;
}
