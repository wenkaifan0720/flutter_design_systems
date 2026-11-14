import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../icons.dart';
import '../internal/cap_label.dart';
import '../internal/icon_fill.dart';
import '../localizations.dart';
import '../styled.dart';
import '../theme.dart';
import 'account.dart';
import 'avatar/avatar.dart';
import 'button/button.dart';
import 'nav_bar.dart';
import 'pressable/pressable.dart';

/// The desktop nav pane, Fluent 2's `NavDrawer` standing on the window's
/// ground: the hamburger and the app's [brand] at its head (the hamburger
/// folds the pane to a 48 rail of glyphs, [collapsed]), the shell's act as
/// the primary button under it, then one item per destination (40 tall,
/// its glyph 20 and 16 before its word in body1, the second ink), the
/// selected item in body1Strong with its filled glyph in the brand on a
/// subtle fill, Fluent's selection indicator (a brand pill 4 by 20) at its
/// start; the account at its foot as a persona that opens the profile,
/// current while the profile is shown ([profileCurrent]). On the media
/// ground ([solid]) it stands on the dark surface.
///
/// The shell mounts it from 1024 wide; a page never composes navigation.
///
/// ```dart
/// Fluent2NavigationDrawer(items: tabs, selectedIndex: 0, onDestinationSelected: select, brand: 'Northwind')
/// ```
class Fluent2NavigationDrawer extends StatelessWidget {
  /// A desktop navigation pane of [items].
  const Fluent2NavigationDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.action,
    this.brand,
    this.collapsed = false,
    this.onToggle,
    this.profileCurrent = false,
    this.noneCurrent = false,
    this.solid = false,
    super.key,
  });

  /// The destinations, in order.
  final List<Fluent2NavItem> items;

  /// The index of the chosen item.
  final int selectedIndex;

  /// Called with a destination's index when it is pressed.
  final ValueChanged<int> onDestinationSelected;

  /// The shell's act: the primary button under the head.
  final ShellAction? action;

  /// The app's name at the head.
  final String? brand;

  /// Folded to the rail of glyphs.
  final bool collapsed;

  /// What the hamburger does; null draws no hamburger.
  final VoidCallback? onToggle;

  /// Whether the account's profile is the page shown.
  final bool profileCurrent;

  /// Whether no destination is current (the notifications are shown).
  final bool noneCurrent;

  /// Stand on the dark surface (the media ground).
  final bool solid;

  /// The pane's width: 260, or the 48 rail.
  static double widthOf({required bool collapsed}) => collapsed
      ? Fluent2ChromeMetrics.paneRail
      : Fluent2ChromeMetrics.paneWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final account = Fluent2AccountScope.maybeOf(context);
    final act = action;
    final toggle = onToggle;
    final words = Fluent2Localizations.of(context);
    final head = SizedBox(
      height: Fluent2ChromeMetrics.paneHead,
      child: Row(
        children: [
          if (toggle != null)
            Fluent2IconButton(
              Fluent2Icons.navigation,
              label: collapsed
                  ? words.expandNavigation
                  : words.collapseNavigation,
              size: Fluent2ButtonSize.large,
              onPressed: toggle,
            ),
          if (!collapsed && brand != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: Fluent2Spacing.s,
                ),
                child: Text(
                  brand!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.subtitle2,
                ),
              ),
            ),
        ],
      ),
    );
    final children = <Widget>[
      // A head with neither the hamburger nor the brand is left out, so the
      // items start at the pane's top rather than under an empty row.
      if (toggle != null || (!collapsed && brand != null)) head,
      if (act != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.s),
          child: collapsed
              ? Fluent2IconButton(
                  act.icon,
                  key: act.key,
                  label: act.label ?? words.create,
                  appearance: act.accent
                      ? Fluent2ButtonAppearance.primary
                      : Fluent2ButtonAppearance.secondary,
                  size: Fluent2ButtonSize.large,
                  onPressed: () => act.onPressed(context),
                )
              : Fluent2Button(
                  act.label ?? words.create,
                  key: act.key,
                  icon: act.icon,
                  appearance: act.accent
                      ? Fluent2ButtonAppearance.primary
                      : Fluent2ButtonAppearance.secondary,
                  size: Fluent2ButtonSize.large,
                  expand: true,
                  onPressed: () => act.onPressed(context),
                ),
        ),
      const SizedBox(height: Fluent2Spacing.xs),
      for (final (i, item) in items.indexed)
        Fluent2NavigationDrawerItem(
          key: item.key,
          icon: item.icon,
          selectedIcon: item.selectedIcon,
          label: item.label,
          selected: !noneCurrent && !profileCurrent && i == selectedIndex,
          collapsed: collapsed,
          onPressed: () => onDestinationSelected(i),
        ),
      const Spacer(),
      if (account != null)
        _AccountFoot(
          account: account,
          current: profileCurrent,
          collapsed: collapsed,
        ),
    ];
    // Under a finger the rail's 48 is the target itself: its controls take
    // the whole width rather than stand 4 in from each side.
    final side = collapsed && Fluent2Layout.padded(context)
        ? 0.0
        : Fluent2ChromeMetrics.paneInset;
    return SizedBox(
      width: widthOf(collapsed: collapsed),
      child: ColoredBox(
        color: solid ? t.colors.neutralBackground2 : t.background,
        child: SafeArea(
          right: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              side,
              Fluent2ChromeMetrics.paneInset,
              side,
              Fluent2Spacing.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Fluent2Spacing.xxs,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// One destination of the nav pane (Fluent's `NavItem`): 40 tall, its
/// glyph 20 and 16 before its word, a subtle fill under the pointer and
/// while [selected], the selection indicator at its start; folded
/// ([collapsed]), the glyph alone. Read as a button named [label],
/// selected or not.
///
/// ```dart
/// Fluent2NavigationDrawerItem(icon: Fluent2Icons.folder, selectedIcon: Fluent2Icons.folderFilled, label: 'Files', selected: true, onPressed: open)
/// ```
class Fluent2NavigationDrawerItem extends StatelessWidget {
  /// One row of the navigation pane showing [icon] and [label].
  const Fluent2NavigationDrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.selectedIcon,
    this.collapsed = false,
    this.trailing,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The row's glyph.
  final IconData icon;

  /// The glyph while selected; null wears [icon]'s filled twin, which it
  /// also wears under the pointer.
  final IconData? selectedIcon;

  /// The row's words.
  final String label;

  /// Whether this is the current destination.
  final bool selected;

  /// Called when the row is pressed.
  final VoidCallback? onPressed;

  /// Whether the pane is a rail, the row its glyph alone.
  final bool collapsed;

  /// What stands at the item's end (a count).
  final Widget? trailing;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: label,
      selected: selected,
      radius: Fluent2Radius.medium,
      builder: (context, states) {
        final press = states.press;
        final fill = selected
            ? press.pick(
                t.colors.subtleBackgroundSelected,
                t.colors.subtleBackgroundHover,
                t.colors.subtleBackgroundPressed,
              )
            : press.pick(
                t.colors.subtleBackground,
                t.colors.subtleBackgroundHover,
                t.colors.subtleBackgroundPressed,
              );
        // Disabled, the glyph and the words take the disabled ink.
        final off = press == Fluent2Press.disabled;
        final ink = off
            ? t.colors.neutralForegroundDisabled
            : selected
            ? t.colors.neutralForeground1
            : press.pick(
                t.colors.neutralForeground2,
                t.colors.neutralForeground2Hover,
                t.colors.neutralForeground2Pressed,
              );
        return fluent2EasedInks(
          [
            fill,
            ink,
            selected && !off ? t.colors.neutralForeground2BrandSelected : ink,
          ],
          (context, inks) {
            final [fill, ink, glyphInk] = inks;
            final glyph = Icon(
              selected
                  ? (selectedIcon ?? fluent2Filled(icon))
                  : press == Fluent2Press.hover || press == Fluent2Press.pressed
                  ? fluent2Filled(icon)
                  : icon,
              size: Fluent2IconSize.i20,
              color: glyphInk,
            );
            return Container(
              height: Fluent2ChromeMetrics.paneItem,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(Fluent2Radius.medium),
              ),
              // The glyph and the words stand in the item's middle (a stack
              // leaves a loose child at its top).
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (selected)
                    PositionedDirectional(
                      start: 0,
                      top:
                          (Fluent2ChromeMetrics.paneItem -
                              Fluent2ChromeMetrics.paneIndicatorHeight) /
                          2,
                      child: Container(
                        width: Fluent2ChromeMetrics.paneIndicatorWidth,
                        height: Fluent2ChromeMetrics.paneIndicatorHeight,
                        decoration: BoxDecoration(
                          color: t.colors.compoundBrandForeground1,
                          borderRadius: BorderRadius.circular(
                            Fluent2Radius.circular,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: collapsed ? 0 : Fluent2ChromeMetrics.paneItemStart,
                      end: collapsed ? 0 : Fluent2ChromeMetrics.paneItemEnd,
                    ),
                    child: collapsed
                        ? Center(child: glyph)
                        : Row(
                            spacing: Fluent2ChromeMetrics.paneItemGap,
                            children: [
                              glyph,
                              // A destination's name stays whole: one
                              // longer than the pane is drawn smaller,
                              // never cut.
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: fluent2CapCentred(
                                    Text(
                                      label,
                                      maxLines: 1,
                                      softWrap: false,
                                      style:
                                          (selected ? t.body1Strong : t.body1)
                                              .c(ink),
                                    ),
                                  ),
                                ),
                              ),
                              ?trailing,
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AccountFoot extends StatelessWidget {
  const _AccountFoot({
    required this.account,
    required this.current,
    required this.collapsed,
  });

  final Fluent2Account account;
  final bool current;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final open = account.onProfile;
    return Fluent2Pressable(
      onPressed: open == null ? null : () => open(context),
      label: '${account.name}, profile and settings',
      selected: current,
      radius: Fluent2Radius.medium,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Fluent2Spacing.xs,
          vertical: Fluent2Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: current
              ? t.colors.subtleBackgroundSelected
              : states.press.pick(
                  t.colors.subtleBackground,
                  t.colors.subtleBackgroundHover,
                  t.colors.subtleBackgroundPressed,
                  t.colors.subtleBackground,
                ),
          borderRadius: BorderRadius.circular(Fluent2Radius.medium),
        ),
        child: Row(
          spacing: Fluent2Spacing.s,
          children: [
            Fluent2Avatar(
              name: account.name,
              initials: account.initials,
              image: account.image,
              color: Fluent2AvatarColor.colorful,
            ),
            if (!collapsed)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: current ? t.body1Strong : t.body1,
                    ),
                    if (account.meta != null)
                      Text(
                        account.meta!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption1.c(t.textSecondary),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
