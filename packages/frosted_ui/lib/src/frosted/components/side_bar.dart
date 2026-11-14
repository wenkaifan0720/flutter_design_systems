import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../internal/css_shadow.dart';
import '../internal/face.dart';
import 'wordmark/wordmark.dart';
import '../theme.dart';
import 'account.dart';
import 'avatar/avatar.dart';
import 'nav_bar.dart';
import 'pressable/pressable.dart';
import '../internal/chosen_plate.dart';
import '../internal/dim.dart';

/// The desktop sidebar, as the source stands it from 1024 wide (`.side`):
/// a column 240 wide down the window's left edge in a translucent white
/// over the light, a hairline at its right edge, 28 above its parts, 20 at
/// their start, 16 at their end and 24 under them, 24 between: the app's
/// wordmark ([brand], its mark on the ink), the main act as the ink button
/// (the tab the phone draws as the pill, or the shell's [action]), the tabs
/// as links in pills (the selected one on the brighter glass, its glyph and
/// word in the ink), and at the foot the account: the avatar, the name and
/// its quiet line, on the lit pill while its profile is shown. On a page
/// that lights none ([noneCurrent]: the notifications) no destination is
/// current. A [header] stands in the wordmark's place and a [footer] in the
/// account's.
///
/// The shell mounts it in place of the tab bar at desktop width; a page
/// never composes navigation.
///
/// ```dart
/// FrostedNavigationDrawer(items: tabs, selectedIndex: 0, onDestinationSelected: select, brand: 'Harbor')
/// ```
class FrostedNavigationDrawer extends StatelessWidget {
  /// Creates a [FrostedNavigationDrawer].
  const FrostedNavigationDrawer({
    required this.items,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.action,
    this.brand,
    this.profileCurrent = false,
    this.noneCurrent = false,
    this.solid = false,
    super.key,
  });

  /// The destinations, in the tab bar's order.
  final List<FrostedNavItem> items;

  /// The selected destination's index.
  final int selectedIndex;

  /// Called with the index of the pressed destination; null leaves the
  /// destinations inert.
  final ValueChanged<int>? onDestinationSelected;

  /// What stands at the top in place of the [brand]'s wordmark.
  final Widget? header;

  /// What stands at the foot in place of the account.
  final Widget? footer;

  /// The shell's act, drawn as the ink button under the wordmark.
  final ShellAction? action;

  /// The app's wordmark.
  final String? brand;

  /// Whether the account's profile is the page shown.
  final bool profileCurrent;

  /// Whether the page shown lights no destination (the notifications).
  final bool noneCurrent;

  /// Paint the solid ground (the media ground).
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final account = FrostedAccountScope.maybeOf(context);
    final act = action;
    final actTab = FrostedNavigationBar.actTab(
      items.length,
      action: act != null,
    );
    final name = brand;
    final select = onDestinationSelected;
    // The sidebar is a bar of glass the page's backdrop runs on under,
    // edged by a hairline at its end.
    return FrostedFace(
      material: solid ? FrostedMaterial.paint : FrostedMaterial.bar,
      radius: BorderRadius.zero,
      color: solid ? t.colorScheme.background : null,
      ring: const Color(0x00000000),
      sheen: const Color(0x00000000),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            end: BorderSide(color: t.glass.sidebarEdge),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FrostedChromeMetrics.sideStart,
            FrostedChromeMetrics.sideTop,
            FrostedChromeMetrics.sideEnd + FrostedChromeMetrics.outline,
            FrostedChromeMetrics.sideBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedChromeMetrics.sideGap,
            children: [
              if (header case final header?)
                header
              else if (name != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: FrostedChromeMetrics.brandInset,
                  ),
                  child: SizedBox(
                    height: FrostedChromeMetrics.brandHeight,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FrostedWordmark(name),
                    ),
                  ),
                ),
              if (actTab != null)
                FrostedSidebarAction(
                  key: items[actTab].key,
                  icon: items[actTab].icon,
                  label: items[actTab].actionLabel ?? items[actTab].label,
                  selected:
                      actTab == selectedIndex &&
                      !profileCurrent &&
                      !noneCurrent,
                  onPressed: select == null ? null : () => select(actTab),
                )
              else if (act != null)
                FrostedSidebarAction(
                  key: act.key,
                  icon: act.icon,
                  label: act.label ?? '',
                  onPressed: () => act.onPressed(context),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FrostedChromeMetrics.navGap,
                children: [
                  for (final (i, item) in items.indexed)
                    if (i != actTab)
                      _Link(
                        item: item,
                        selected:
                            i == selectedIndex &&
                            !profileCurrent &&
                            !noneCurrent,
                        onTap: select == null ? null : () => select(i),
                      ),
                ],
              ),
              const Spacer(),
              if (footer case final footer?)
                footer
              else if (account != null)
                _Foot(account: account, current: profileCurrent),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sidebar's main act (`.btn-move`): the ink button 40 tall across the
/// sidebar, its glyph 8 before its word, both on the ink; ringed in white
/// and ink while [current] (Move money).
///
/// ```dart
/// FrostedSidebarAction(icon: FrostedGlyphs.arrowRightLeft, label: 'Move money', onPressed: openMove)
/// ```
class FrostedSidebarAction extends StatelessWidget {
  /// Creates a [FrostedSidebarAction].
  const FrostedSidebarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The act's glyph.
  final IconData icon;

  /// The act's words.
  final String label;

  /// What a press does.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Whether the act's page is the one shown.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const h = FrostedChromeMetrics.sideAct;
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: label,
      role: FrostedPressRole.link,
      selected: selected ? true : null,
      radius: h / 2,
      child: SizedBox(
        height: h,
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(h / 2),
          gradients: [t.colorScheme.buttonFill],
          sheen: t.colorScheme.buttonSheen,
          shadows: [
            if (selected) ...[
              frostedShadow(
                color: t.colorScheme.ringInner,
                spread: FrostedChromeMetrics.movePillRingInner,
              ),
              frostedShadow(
                color: t.colorScheme.ringOuter,
                spread: FrostedChromeMetrics.movePillRingOuter,
              ),
            ],
            ...t.shadows.button,
          ],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: FrostedChromeMetrics.sideActGap,
            children: [
              Icon(
                icon,
                size: FrostedChromeMetrics.sideActGlyph,
                color: t.colorScheme.onButton,
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.labelLarge.c(t.colorScheme.onButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FrostedNavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const h = FrostedChromeMetrics.navLink;
    // The glyph's ink and the word ease as the plate comes and goes.
    final row = FrostedEase<(Color, TextStyle)>(
      value: (
        selected ? t.colorScheme.textPrimary : t.colorScheme.textTertiary,
        selected
            ? t.textTheme.link.semibold.c(t.colorScheme.textPrimary)
            : t.textTheme.link.c(t.colorScheme.textSecondary),
      ),
      lerp: FrostedEase.inkAndWords,
      builder: (context, shown) => Row(
        spacing: FrostedChromeMetrics.navLinkGap,
        children: [
          Icon(
            selected ? (item.selectedIcon ?? item.icon) : item.icon,
            size: FrostedChromeMetrics.navGlyph,
            color: shown.$1,
          ),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: shown.$2,
            ),
          ),
        ],
      ),
    );
    return FrostedPressable(
      key: item.key,
      onPressed: onTap,
      label: item.label,
      selected: selected,
      radius: h / 2,
      child: SizedBox(
        height: h,
        // The page shown stands on thicker, brighter glass raised off the
        // bar's; the others are the bar's own glass. Both keep the same room,
        // so a link's glyph and word stand still when it is chosen (design6
        // P: one leading keyline).
        child: selected
            ? FrostedChosenPlate(
                radius: BorderRadius.circular(h / 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedChromeMetrics.navLinkInset,
                ),
                child: row,
              )
            : FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(h / 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: FrostedChromeMetrics.navLinkInset,
                ),
                child: row,
              ),
      ),
    );
  }
}

class _Foot extends StatelessWidget {
  const _Foot({required this.account, required this.current});

  final FrostedAccount account;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final open = account.onProfile;
    final meta = account.meta;
    final footInset = const EdgeInsetsDirectional.fromSTEB(
      FrostedChromeMetrics.footInsetStart,
      FrostedChromeMetrics.footInsetVertical,
      FrostedChromeMetrics.footInsetEnd,
      FrostedChromeMetrics.footInsetVertical,
    ).resolve(Directionality.of(context));
    Widget plate({required Widget child}) => current
        ? FrostedChosenPlate(
            radius: BorderRadius.circular(FrostedCorners.rFull),
            padding: footInset,
            child: child,
          )
        : FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedCorners.rFull),
            padding: footInset,
            child: child,
          );
    final foot = plate(
      child: Row(
        spacing: FrostedChromeMetrics.footGap,
        children: [
          FrostedAvatar(account.initials, size: FrostedAvatarSize.small),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.footLineGap,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.link.c(t.colorScheme.textPrimary).line(17),
                ),
                if (meta != null)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall.line(14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return FrostedPressable(
      onPressed: open == null ? null : () => open(context),
      label: [account.name, ?meta].join(', '),
      role: FrostedPressRole.link,
      selected: current ? true : null,
      radius: FrostedCorners.rFull,
      child: foot,
    );
  }
}
