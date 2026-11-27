import '../internal/well.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../icons.dart';
import '../localizations.dart';
import '../theme.dart';
import 'account.dart';
import 'app_shell.dart';
import 'avatar/avatar.dart';
import 'button/button.dart';
import 'nav_bar.dart';
import '../internal/nav_faces.dart';
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
/// The shell mounts it from 1024 wide, and folded to its rail from 640 (a
/// tablet, a narrow window); a page never composes navigation.
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
  final Fluent2ShellAction? action;

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
              semanticLabel: collapsed
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
                  semanticLabel: act.label ?? words.create,
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
    // The pane stands at the window's start: it keeps clear of a notch or
    // a system bar on that side (the left, or the right in a right-to-left
    // app), and the page beside it keeps the end.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: widthOf(collapsed: collapsed),
      child: ColoredBox(
        color: solid ? t.colors.neutralBackground2 : t.background,
        child: SafeArea(
          left: !rtl,
          right: rtl,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Fluent2NavItem>('items', items))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<Fluent2ShellAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(FlagProperty('collapsed', value: collapsed, ifTrue: 'collapsed'))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onToggle', onToggle))
      ..add(
        FlagProperty(
          'profileCurrent',
          value: profileCurrent,
          ifTrue: 'profileCurrent',
        ),
      )
      ..add(
        FlagProperty('noneCurrent', value: noneCurrent, ifTrue: 'noneCurrent'),
      )
      ..add(FlagProperty('solid', value: solid, ifTrue: 'solid'));
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

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Fluent2Pressable(
    focusNode: focusNode,
    autofocus: autofocus,
    onPressed: onPressed,
    semanticLabel: label,
    selected: selected,
    radius: Fluent2Radius.medium,
    builder: (context, states) => Fluent2PaneItemFace(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      selected: selected,
      collapsed: collapsed,
      trailing: trailing,
      states: states,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(
        DiagnosticsProperty<IconData>(
          'selectedIcon',
          selectedIcon,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<bool>('selected', selected))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onPressed', onPressed))
      ..add(FlagProperty('collapsed', value: collapsed, ifTrue: 'collapsed'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
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
      semanticLabel: '${account.name}, profile and settings',
      selected: current,
      radius: Fluent2Radius.medium,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Fluent2Spacing.xs,
          vertical: Fluent2Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: current
              ? fluent2Step(t, t.colors.subtleBackgroundSelected)
              : states.press.pick(
                  t.colors.subtleBackground,
                  fluent2Step(t, t.colors.subtleBackgroundHover),
                  fluent2Step(t, t.colors.subtleBackgroundPressed),
                  t.colors.subtleBackground,
                ),
          borderRadius: BorderRadius.circular(Fluent2Radius.medium),
        ),
        child: Row(
          spacing: Fluent2Spacing.s,
          children: [
            // The collapsed rail's width is fixed: its avatar keeps its
            // size at any text size, as a rail's glyphs do.
            MediaQuery.withNoTextScaling(
              child: Fluent2Avatar(
                name: account.name,
                initials: account.initials,
                image: account.image,
                color: Fluent2AvatarColor.colorful,
              ),
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
