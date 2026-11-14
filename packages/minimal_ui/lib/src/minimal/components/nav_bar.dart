import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/face.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';
import '../ground.dart';

/// One destination in a [MinimalNavigationBar]: its glyph, its label, and the
/// walkthrough [key] its tab carries. Every tab says what it is: the label
/// is required (Cody's positional shape), and a glyph-only tab is
/// [MinimalNavItem.iconOnly], which prints no words but still announces its
/// [semanticLabel].
@immutable
class MinimalNavItem {
  /// A destination showing [icon] and [label].
  const MinimalNavItem(this.icon, [this.label, this.key])
    : semanticLabel = null,
      ground = MinimalGround.surface,
      assert(
        label != null,
        'A tab needs words: pass its label, or use '
        'MinimalNavItem.iconOnly(icon, semanticLabel: ...).',
      );

  /// A tab that prints only its glyph; a screen reader still hears
  /// [semanticLabel].
  const MinimalNavItem.iconOnly(
    this.icon, {
    required String this.semanticLabel,
    this.key,
    this.ground = MinimalGround.surface,
  }) : label = null;

  /// A tab whose root stands on the media ground: while it is selected the
  /// shell draws its bar in the dark tokens and the root ends at the bar's
  /// top. Its root page stands on media through
  /// `MinimalPage(ground: MinimalGround.media)`.
  ///
  /// ```dart
  /// MinimalNavItem.media(LucideIcons.play, 'Watch')
  /// ```
  const MinimalNavItem.media(this.icon, String this.label, [this.key])
    : semanticLabel = null,
      ground = MinimalGround.media;

  /// Its glyph.
  final IconData icon;

  /// The words printed under the glyph; null only for
  /// [MinimalNavItem.iconOnly].
  final String? label;

  /// A key for its tab, for tests to find it.
  final Key? key;

  /// What a screen reader announces for a glyph-only tab.
  final String? semanticLabel;

  /// The ground this tab's root stands on. It paints the shell's BAR while
  /// the tab is selected; the root page publishes its own.
  final MinimalGround ground;
}

/// Minimal's bottom navigation: a slim bar docked on the bottom edge — a
/// 1 px top hairline over [MinimalChromeMetrics.tabHeight] of the ground, then
/// the bottom safe area — with a 20 px glyph over a 10.5 px label per tab.
/// The current tab is the ink; the rest are the quiet ink. An optional
/// [action] stands as a square at the trailing end: the app's one act
/// reachable from every root.
///
/// [MinimalShell] mounts it; a page never composes nav itself.
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
    return Container(
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
                      color: actionAccent ? t.primaryForeground : t.background,
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
    final t = context.minimalTheme;
    final inkTo = active ? t.foreground : t.mutedForeground;
    final label = item.label;
    // The selected state rides the pressable's own node — the one a screen
    // reader focuses — so the current tab is announced as selected.
    return MinimalPressable(
      onPressed: onPressed,
      semanticLabel: item.semanticLabel ?? label,
      selected: active,
      // The current tab's ink fades in, the last one's out.
      child: MinimalFace(
        height: MinimalChromeMetrics.tabHeight,
        ink: inkTo,
        builder: (context, lerped) {
          final ink = lerped ?? inkTo;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MinimalIcon(
                item.icon,
                size: MinimalChromeMetrics.tabIcon,
                color: ink,
              ),
              if (label != null) ...[
                const SizedBox(height: MinimalChromeMetrics.tabLabelGap),
                // The pressable already announces the label.
                ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.medium.copyWith(
                      fontSize: MinimalChromeMetrics.tabLabel,
                      height: MinimalChromeMetrics.tabLabelLeading,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
