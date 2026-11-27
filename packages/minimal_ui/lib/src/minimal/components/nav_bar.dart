import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/nav_faces.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';
import 'nav_item.dart';

/// Minimal's bottom navigation: a slim bar docked on the bottom edge — a
/// 1 px top hairline over [MinimalChromeMetrics.tabHeight] of the ground, then
/// the bottom safe area — with a 20 px glyph over a 10.5 px label per tab.
/// The current tab is the ink; the rest are the quiet ink. An optional
/// [action] stands as a square at the trailing end: the app's one act
/// reachable from every root.
///
/// An app's bar is [MinimalAppShell]'s, which paints these places and gives
/// them their tab semantics; this bar is for a frame of the app's own.
///
/// ```dart
/// MinimalNavigationBar(items: const [MinimalNavItem(LucideIcons.calendarCheck, 'Today'), MinimalNavItem(LucideIcons.listChecks, 'Habits')], selectedIndex: tab, onDestinationSelected: go)
/// ```
class MinimalNavigationBar extends StatelessWidget {
  /// A tab bar of [items].
  const MinimalNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.action,
    this.onAction,
    this.actionLabel,
    this.actionAccent = false,
    this.actionKey,
  });

  /// The tabs, start to end.
  final List<MinimalNavItem> items;

  /// The current tab.
  final int selectedIndex;

  /// Reports the tab pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// The trailing square's glyph, or null for a bar of tabs alone.
  final IconData? action;

  /// The create square's press; null hides it.
  final VoidCallback? onAction;

  /// What the action does, announced for the icon-only square.
  final String? actionLabel;

  /// Accent-fill the square; otherwise it wears the ink.
  final bool actionAccent;

  /// A key for the create square, for tests to find it.
  final Key? actionKey;

  /// The bar's whole height over a bottom safe area of [safeBottom]: the
  /// allowance a nav root reserves under its content.
  static double heightIn(double safeBottom) =>
      MinimalChromeMetrics.tabHeight + safeBottom;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final action = this.action;
    // Toasts stand above the bar (ui_core's RawToasterKeepClear), and follow
    // it as it slides in or away.
    return RawToasterKeepClear(
      child: Container(
        height: heightIn(safeBottom),
        padding: EdgeInsets.only(bottom: safeBottom),
        decoration: BoxDecoration(
          color: t.background,
          border: Border(top: t.rule),
        ),
        child: Row(
          children: [
            for (final (i, item) in items.indexed)
              Expanded(
                child: _Tab(
                  key: item.key,
                  item: item,
                  active: i == selectedIndex,
                  onPressed: onDestinationSelected == null
                      ? null
                      : () => onDestinationSelected!(i),
                ),
              ),
            if (action != null)
              SizedBox(
                width: MinimalChromeMetrics.tabActionSlot,
                child: Center(
                  child: MinimalPressable(
                    key: actionKey,
                    onPressed: onAction,
                    enabled: onAction != null,
                    semanticLabel:
                        actionLabel ?? MinimalLocalizations.of(context).create,
                    child: Container(
                      width: MinimalChromeMetrics.tabAction,
                      height: MinimalChromeMetrics.tabAction,
                      decoration: minimalFrame(
                        t.shapes.small,
                        fill: actionAccent ? t.primary : t.foreground,
                      ),
                      child: MinimalIcon(
                        action,
                        color: actionAccent
                            ? t.primaryForeground
                            : t.background,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalNavItem>('items', items))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(DiagnosticsProperty<IconData>('action', action, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onAction', onAction))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'actionAccent',
          value: actionAccent,
          ifTrue: 'actionAccent',
        ),
      )
      ..add(
        DiagnosticsProperty<Key>('actionKey', actionKey, defaultValue: null),
      );
  }
}

/// One tab: the glyph over its label, the whole cell the target.
class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.item,
    required this.active,
    required this.onPressed,
  });

  final MinimalNavItem item;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // The selected state rides the pressable's own node — the one a screen
    // reader focuses — so the current tab is announced as selected.
    return MinimalPressable(
      onPressed: onPressed,
      semanticLabel: item.semanticLabel ?? item.label,
      selected: active,
      // The current tab's ink fades in, the last one's out.
      child: MinimalTabFace(item: item, selected: active),
    );
  }
}
