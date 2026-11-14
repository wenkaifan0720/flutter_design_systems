import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../internal/cap_center.dart';
import '../../internal/face.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// In-page sections, peers of one page: a strip 44 tall over the page's
/// hairline, each [tabs] label set in the sans medium with an optional
/// [counts] figure after it in the mono, the chosen one in the ink under
/// one ink rule and the rest in the second ink. A strip
/// wider than its room scrolls sideways, keeping the chosen tab in view.
/// The arrow keys (and Home and End) move the choice from a focused tab, and
/// focus goes with it. [padding] insets the labels (the page's gutter on a
/// full-bleed strip) while the hairline runs edge to edge. A null
/// [onSelected] shows the strip without letting it change. Each tab says its
/// label, its count and whether it is chosen.
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
    this.padding = EdgeInsets.zero,
    super.key,
  }) : assert(
         counts == null || counts.length == tabs.length,
         'one count (or null) for each tab',
       );

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

  /// The strip's inset for its labels; the hairline under them ignores it.
  final EdgeInsetsGeometry padding;

  @override
  State<LedgerTabs> createState() => _LedgerTabsState();
}

class _LedgerTabsState extends State<LedgerTabs> {
  final ScrollController _scroll = ScrollController();
  late List<FocusNode> _nodes = _make(widget.tabs.length);
  late List<GlobalKey> _keys = [
    for (var i = 0; i < widget.tabs.length; i++) GlobalKey(),
  ];

  static List<FocusNode> _make(int n) => [
    for (var i = 0; i < n; i++) FocusNode(debugLabel: 'LedgerTab $i'),
  ];

  @override
  void didUpdateWidget(LedgerTabs old) {
    super.didUpdateWidget(old);
    if (old.tabs.length != widget.tabs.length) {
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = _make(widget.tabs.length);
      _keys = [for (var i = 0; i < widget.tabs.length; i++) GlobalKey()];
    }
    if (old.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _reveal() {
    final at = widget.selectedIndex.clamp(0, _keys.length - 1);
    final context = _keys[at].currentContext;
    if (!mounted || context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: .5,
      duration: LedgerMotion.of(context, LedgerMotion.base),
      curve: LedgerMotion.out,
    );
  }

  void _go(int to) {
    final onSelected = widget.onSelected;
    if (onSelected == null || widget.tabs.isEmpty) return;
    final at = to.clamp(0, widget.tabs.length - 1);
    _nodes[at].requestFocus();
    if (at != widget.selectedIndex) onSelected(at);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final to = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => widget.selectedIndex + (rtl ? -1 : 1),
      LogicalKeyboardKey.arrowLeft => widget.selectedIndex + (rtl ? 1 : -1),
      LogicalKeyboardKey.home => 0,
      LogicalKeyboardKey.end => widget.tabs.length - 1,
      _ => null,
    };
    if (to == null || widget.onSelected == null) return KeyEventResult.ignored;
    _go(to);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _key,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.hairline)),
        ),
        child: SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          child: Row(
            spacing: _gap,
            children: [
              for (var i = 0; i < widget.tabs.length; i++)
                KeyedSubtree(
                  key: _keys[i],
                  child: _Tab(
                    label: widget.tabs[i],
                    count: widget.counts?[i],
                    selected: i == widget.selectedIndex,
                    focusNode: _nodes[i],
                    onTap: widget.onSelected == null ? null : () => _go(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // DERIVED (the source's tab bar is the shell's): tabs 28 apart.
  static const double _gap = 28;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.focusNode,
    this.count,
    this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerPressable(
      onTap: onTap,
      focusNode: focusNode,
      label: label,
      value: count == null ? null : '$count',
      selected: selected,
      radius: t.smallRadius,
      // Chosen, the tab's words ink up and its rule is drawn in under
      // it from the reading start; left, the rule is drawn back out. One
      // value moves both, in Ledger's one motion.
      child: LedgerEase(
        value: selected ? 1 : 0,
        duration: LedgerMotion.base,
        builder: (context, chosen, _) {
          final ink = Color.lerp(t.textSecondary, t.textPrimary, chosen)!;
          return SizedBox(
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
                if (chosen > 0)
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 0,
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: chosen.clamp(0.0, 1.0),
                      child: Container(height: _rule, color: t.textPrimary),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static const double _height = 44;
  static const double _rule = 2;
  static const double _countGap = 6;
}
