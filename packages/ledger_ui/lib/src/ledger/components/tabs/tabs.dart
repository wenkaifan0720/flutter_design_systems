import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_center.dart';
import '../../internal/state_face.dart';
import '../../theme.dart';

/// In-page sections, peers of one page: a strip 44 tall over the page's
/// hairline, each [tabs] label set in the sans medium with an optional
/// [counts] figure after it in the mono, the chosen one in the ink under
/// one ink rule and the rest in the second ink. A strip
/// wider than its room scrolls sideways, keeping the chosen tab in view.
/// The strip is ui_core's [DesignTabBar]: one tab stop, the arrow keys
/// (mirrored right to left, wrapping) and Home and End move the choice and
/// the focus with it, and the change runs on ui_core's spring, the old
/// tab's rule drawn back out as the new one's is drawn in. [padding] insets
/// the labels (the page's gutter on a full-bleed strip) while the hairline
/// runs edge to edge. A null [onSelected] shows the strip without letting
/// it change. A screen reader hears a tab bar, each tab its label, its
/// count and its place ("Entries, 12, Tab 2 of 3"), and whether it is
/// chosen. Supply [children] to show a named, swipeable tab panel below the
/// strip. Give the widget a bounded height when showing panels.
///
/// ```dart
/// LedgerTabs(tabs: const ['Overview', 'Entries', 'Notes'], counts: const [null, 12, 3], selectedIndex: tab, onSelected: (i) => setState(() => tab = i))
/// ```
class LedgerTabs extends StatefulWidget {
  /// A strip of [tabs], the one at [selectedIndex] chosen.
  const LedgerTabs({
    required this.tabs,
    required this.selectedIndex,
    this.onSelected,
    this.counts,
    this.children,
    this.padding = EdgeInsets.zero,
    super.key,
  }) : assert(
         counts == null || counts.length == tabs.length,
         'one count (or null) for each tab',
       ),
       assert(children == null || children.length == tabs.length);

  /// The tabs' words, in order.
  final List<String> tabs;

  /// The chosen tab.
  final int selectedIndex;

  /// Called with the tab pressed; null shows the strip without letting it
  /// change.
  final ValueChanged<int>? onSelected;

  /// One count per tab (null for a tab without one), printed in the mono
  /// after its label.
  final List<int?>? counts;

  /// A page for each tab, in the same order as [tabs]. Omit to show only the strip.
  final List<Widget>? children;

  /// The strip's inset for its labels; the hairline under them ignores it.
  final EdgeInsetsGeometry padding;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected))
      ..add(IterableProperty<int?>('counts', counts, defaultValue: null))
      ..add(IterableProperty<Widget>('children', children, defaultValue: null))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }

  @override
  State<LedgerTabs> createState() => _LedgerTabsState();
}

class _LedgerTabsState extends State<LedgerTabs> with TickerProviderStateMixin {
  late DesignTabController _controller = _make();

  DesignTabController _make() => DesignTabController(
    length: widget.tabs.length,
    initialIndex: widget.tabs.isEmpty
        ? 0
        : widget.selectedIndex.clamp(0, widget.tabs.length - 1),
    vsync: this,
  )..addListener(_chosen);

  // A tab the person chose: the caller's to take (or not).
  void _chosen() {
    final at = _controller.index;
    if (at != widget.selectedIndex) widget.onSelected?.call(at);
  }

  @override
  void didUpdateWidget(LedgerTabs old) {
    super.didUpdateWidget(old);
    if (old.tabs.length != widget.tabs.length) {
      _controller.dispose();
      _controller = _make();
    } else if (widget.selectedIndex != _controller.index &&
        widget.selectedIndex >= 0 &&
        widget.selectedIndex < widget.tabs.length) {
      _controller.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final n = widget.tabs.length;
    final dir = Directionality.of(context);
    final inset = widget.padding.resolve(dir);
    final (start, end) = dir == TextDirection.rtl
        ? (inset.right, inset.left)
        : (inset.left, inset.right);
    final strip = DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: inset.top, bottom: inset.bottom),
        child: DesignTabBar(
          controller: _controller,
          isScrollable: true,
          tabs: [
            for (var i = 0; i < n; i++)
              DesignTab(
                label: switch (widget.counts?[i]) {
                  final count? => '${widget.tabs[i]}, $count',
                  null => widget.tabs[i],
                },
                enabled: widget.onSelected != null,
              ),
          ],
          // The tabs meet: each one's press takes half the gap on either
          // side of its words, so a tap between two reaches the nearer; the
          // ends take the strip's inset, which scrolls with them.
          tabBuilder: (context, tab, details) => _Tab(
            before: details.index == 0 ? start : _gap / 2,
            after: details.index == n - 1 ? end : _gap / 2,
            label: widget.tabs[details.index],
            count: widget.counts?[details.index],
            states: details.states,
            chosen: details.selection,
          ),
        ),
      ),
    );
    final pages = widget.children;
    if (pages == null || pages.isEmpty) return strip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        strip,
        Expanded(
          child: DesignTabView(
            controller: _controller,
            physics: widget.onSelected == null
                ? const NeverScrollableScrollPhysics()
                : null,
            children: [
              for (var i = 0; i < pages.length; i++)
                Semantics(
                  label: widget.tabs[i],
                  explicitChildNodes: true,
                  child: pages[i],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // DERIVED (the source's tab bar is the shell's): tabs 28 apart.
  static const double _gap = 28;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.before,
    required this.after,
    required this.label,
    required this.states,
    required this.chosen,
    this.count,
  });

  /// The room of the gap its press takes before and after its words.
  final double before;
  final double after;
  final String label;
  final int? count;
  final Set<WidgetState> states;

  /// How chosen it is on ui_core's spring: 1 at rest on it, 0 a tab away.
  final double chosen;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final room = EdgeInsetsDirectional.only(start: before, end: after);
    // A tab's words narrower than the tap floor stand centred in it.
    final least = math.max(
      0.0,
      DesignTapTargets.of(context).floorOn().width - before - after,
    );
    final on = chosen.clamp(0.0, 1.0);
    final ink = Color.lerp(t.textSecondary, t.textPrimary, on)!;
    // Chosen, the tab's words ink up and its rule is drawn in under it from
    // the reading start; left, the rule is drawn back out. ui_core's
    // selection moves both.
    return LedgerStateFace(
      states: states,
      radius: t.smallRadius,
      ringInsets: room,
      child: Padding(
        padding: room,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: least),
          child: SizedBox(
            height: _height,
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: _countGap,
                    children: [
                      ledgerCapCenter(
                        t.rowTitle,
                        Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: t.rowTitle.sized(14).line(20).colored(ink),
                        ),
                      ),
                      if (count != null)
                        ledgerCapCenter(
                          t.meta,
                          Text(
                            '$count',
                            style: t.meta.line(16).colored(t.textTertiary),
                          ),
                        ),
                    ],
                  ),
                ),
                // The ink rule the chosen tab stands on: one, and heavier
                // than a hairline, so a choice never reads as focus (the
                // double rule under a control).
                if (on > 0)
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: on,
                      child: Container(height: _rule, color: t.textPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _height = 44;
  static const double _rule = 2;
  static const double _countGap = 6;
}
