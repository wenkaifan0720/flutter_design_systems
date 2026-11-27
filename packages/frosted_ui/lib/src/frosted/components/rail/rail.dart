import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';
import '../nav_bar.dart';
import '../pressable/pressable.dart';

/// The destinations as a narrow column down the window's start edge, for a
/// window too wide for the tab bar and too narrow for the sidebar: 80 wide
/// in the sidebar's translucent white with its hairline at the end, each
/// destination its glyph in a 56 by 32 pill over its word, the selected
/// one's pill on the brighter glass with its glyph in the ink. [leading]
/// stands over the destinations (the main act), [trailing] at the foot.
/// Each destination is a link that says whether it is selected; the arrow
/// keys and Tab move between them.
///
/// ```dart
/// FrostedNavigationRail(items: tabs, selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i))
/// ```
class FrostedNavigationRail extends StatelessWidget {
  /// A rail of [items], [selectedIndex] lit.
  const FrostedNavigationRail({
    required this.items,
    this.selectedIndex,
    this.onDestinationSelected,
    this.leading,
    this.trailing,
    this.semanticLabel,
    super.key,
  }) : assert(
         selectedIndex == null || selectedIndex >= 0,
         'A rail\'s selected index is not negative.',
       );

  /// The destinations, in the tab bar's order.
  final List<FrostedNavItem> items;

  /// The selected destination's index; null lights none.
  final int? selectedIndex;

  /// Called with the index of the pressed destination.
  final ValueChanged<int>? onDestinationSelected;

  /// What stands over the destinations.
  final Widget? leading;

  /// What stands at the rail's foot.
  final Widget? trailing;

  /// What a screen reader calls the rail.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: SizedBox(
        width: 80,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.glass.sidebar,
            border: BorderDirectional(
              end: BorderSide(
                color: t.glass.sidebarEdge,
                width: FrostedStrokes.hairline,
              ),
            ),
          ),
          child: SafeArea(
            right: false,
            child: FocusTraversalGroup(
              // The trailing part stands at the foot while the places fit;
              // a rail shorter than its places scrolls them.
              child: CustomScrollView(
                primary: false,
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                        const SizedBox(height: FrostedSpacing.s16),
                        if (leading case final leading?) ...[
                          leading,
                          const SizedBox(height: FrostedSpacing.s16),
                        ],
                        for (final (i, item) in items.indexed)
                          _RailDestination(
                            item: item,
                            selected: i == selectedIndex,
                            onPressed: onDestinationSelected == null
                                ? null
                                : () => onDestinationSelected!(i),
                          ),
                        const Spacer(),
                        ?trailing,
                        const SizedBox(height: FrostedSpacing.s16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedNavItem>('items', items))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final FrostedNavItem item;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    const pill = Size(56, 32);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s4),
      child: FrostedPressable(
        key: item.key,
        onPressed: onPressed,
        semanticLabel: item.label,
        role: FrostedPressRole.link,
        selected: selected,
        radius: pill.height / 2,
        // 56 tall, and taller as large text needs it.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 72,
            maxWidth: 72,
            minHeight: 56,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedSpacing.s4,
            children: [
              AnimatedContainer(
                duration: motion.fast,
                curve: motion.curve,
                width: pill.width,
                height: pill.height,
                decoration: ShapeDecoration(
                  shape: FrostedCorners.full.copyWith(
                    side: selected
                        ? BorderSide(
                            color: t.glass.edge,
                            width: FrostedStrokes.hairline,
                          )
                        : BorderSide.none,
                  ),
                  color: selected ? t.glass.navCurrent : null,
                ),
                child: Icon(
                  selected ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: FrostedChromeMetrics.navGlyph,
                  color: selected
                      ? t.colorScheme.textPrimary
                      : t.colorScheme.textTertiary,
                ),
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected
                    ? t.textTheme.labelSmall.semibold.c(
                        t.colorScheme.textPrimary,
                      )
                    : t.textTheme.labelSmall.c(t.colorScheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
