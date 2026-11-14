import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/bar_slot.dart';
import '../internal/cap_center.dart';
import '../internal/end_glyph.dart';
import '../internal/hit_slop.dart';
import '../internal/side_inset.dart';
import '../theme.dart';
import 'avatar/avatar.dart';
import 'brand/brand.dart';
import 'icon-button/icon_button.dart';
import 'pressable/pressable.dart';
import 'sheet.dart';
import 'sheet_page.dart';

/// Who the app belongs to, as its chrome shows them: the [initials] in the
/// avatar, the [name] and the quiet [meta] line ("Member since 2023") at the
/// sidebar's foot, the [unread] count the bell wears, and where the avatar
/// ([onProfilePressed]) and the bell ([onNotificationsPressed]) lead. The app
/// mounts one [LedgerAccountScope] above its router; the top bars and the
/// sidebar read it, so no page passes the person around. [profileLocation] is
/// the profile page's path: the sidebar's foot is current there (a `:name`
/// segment stands for any one, so '/:root/profile' is the profile pushed on any
/// root). [notificationsLocation] is the bell's page, where the sidebar marks
/// nothing current, as the source's notifications do. [searchHint] and
/// [onSearchPressed] are the app's search, which the desktop's masthead offers
/// beside the bell.
///
/// ```dart
/// LedgerAccount(name: 'Maren Holt', initials: 'MH', meta: 'Since Mar 2023', unread: 2, onProfilePressed: (context) => open('/profile'))
/// ```
@immutable
class LedgerAccount {
  /// The signed-in person named [name].
  const LedgerAccount({
    required this.name,
    required this.initials,
    this.meta,
    this.unread = 0,
    this.onProfilePressed,
    this.onNotificationsPressed,
    this.profileLocation,
    this.notificationsLocation,
    this.searchHint,
    this.onSearchPressed,
  });

  /// The person's name, as the sidebar's foot prints it.
  final String name;

  /// One or two letters, the avatar's face.
  final String initials;

  /// The quiet line under the name.
  final String? meta;

  /// How many notifications are unread: the bell wears its dot while more
  /// than none.
  final int unread;

  /// Opens the profile; run with the tapped control's context (under the
  /// router).
  final void Function(BuildContext context)? onProfilePressed;

  /// Opens the notifications.
  final void Function(BuildContext context)? onNotificationsPressed;

  /// The profile page's path, where the sidebar's foot is current: read as
  /// written ('/home/profile'), or with go_router's `:name` segments
  /// standing for any one segment ('/:root/profile', the profile pushed on
  /// any root, as a router that nests it under every branch has it).
  final String? profileLocation;

  /// The notifications page's path, read as [profileLocation] is
  /// ('/:root/notifications'): while it is shown the sidebar marks no
  /// destination current, as the source's notifications light none.
  final String? notificationsLocation;

  /// The words the desktop masthead's search pill shows ("Search activity");
  /// with [onSearchPressed], every desktop masthead carries the pill.
  final String? searchHint;

  /// Opens the app's search; null draws no pill.
  final void Function(BuildContext context)? onSearchPressed;

  /// Whether the page at [path] is the profile, or a page under it, by
  /// [profileLocation].
  bool showsProfile(String path) => _shows(profileLocation, path);

  /// Whether the page at [path] is the notifications, or a page under it,
  /// by [notificationsLocation].
  bool showsNotifications(String path) => _shows(notificationsLocation, path);

  static bool _shows(String? at, String path) {
    if (at == null) return false;
    if (!at.contains('/:')) {
      return path == at || path.startsWith(at.endsWith('/') ? at : '$at/');
    }
    List<String> parts(String p) => [
      for (final s in p.split('/'))
        if (s.isNotEmpty) s,
    ];
    final want = parts(at);
    final have = parts(path);
    if (have.length < want.length) return false;
    for (var i = 0; i < want.length; i++) {
      if (!want[i].startsWith(':') && want[i] != have[i]) return false;
    }
    return true;
  }
}

/// Publishes the app's [LedgerAccount] to its chrome: mount one above the
/// router (around the host's child), rebuilt when the person or the unread
/// count changes.
///
/// ```dart
/// LedgerAccountScope(account: account, child: child)
/// ```
class LedgerAccountScope extends InheritedWidget {
  /// Publishes [account] to the chrome under it.
  const LedgerAccountScope({
    required this.account,
    required super.child,
    super.key,
  });

  /// The signed-in person.
  final LedgerAccount account;

  /// The account in force at [context]; null when the app publishes none,
  /// and the bars then draw no bell or avatar.
  static LedgerAccount? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LedgerAccountScope>()?.account;

  @override
  bool updateShouldNotify(LedgerAccountScope oldWidget) =>
      account != oldWidget.account;
}

/// The bell, then the avatar, of [account]: what the phone's top bar wears
/// at its end on a tab's page, 4 apart. The desktop's masthead wears the
/// bell alone (ringed), the avatar standing at the sidebar's foot.
///
/// ```dart
/// LedgerAccountMarks(account: account)
/// ```
class LedgerAccountMarks extends StatelessWidget {
  /// The bell and the avatar of [account].
  const LedgerAccountMarks({
    required this.account,
    this.showBell = true,
    this.showAvatar = true,
    this.bellKey,
    this.avatarKey,
    super.key,
  });

  /// The signed-in person.
  final LedgerAccount account;

  /// Whether the bell stands.
  final bool showBell;

  /// Whether the avatar stands.
  final bool showAvatar;

  /// The walkthrough keys set on the bell's and the avatar's hit targets.
  final Key? bellKey;

  /// The walkthrough key set on the avatar.
  final Key? avatarKey;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: LedgerChromeMetrics.toolsGap,
    children: [
      if (showBell) _bellOf(context, account, key: bellKey),
      if (showAvatar) _avatarOf(context, account, key: avatarKey),
    ],
  );
}

/// The bell that opens [account]'s notifications, carrying [key].
Widget _bellOf(
  BuildContext context,
  LedgerAccount account, {
  Key? key,
  bool ringed = false,
}) {
  final open = account.onNotificationsPressed;
  final onPressed = open == null ? null : () => open(context);
  return ringed
      ? LedgerBell.outlined(
          key: key,
          unread: account.unread,
          onPressed: onPressed,
        )
      : LedgerBell(key: key, unread: account.unread, onPressed: onPressed);
}

/// The bar's avatar that opens [account]'s profile, carrying [key].
Widget _avatarOf(BuildContext context, LedgerAccount account, {Key? key}) {
  final open = account.onProfilePressed;
  return LedgerAvatar(
    key: key,
    initials: account.initials,
    label: 'Profile and settings',
    onTap: open == null ? null : () => open(context),
  );
}

/// The way back off a pushed page, or the close of a cover or a sheet, as
/// the route's bar draws it: on a phone the 36 ringed button with the
/// chevron (the cross to close) saying "Back to [label]"; at desktop width
/// the crumb over the title, the 15 chevron and [label] in the mono
/// capitals, hung 4 into the gutter; on a sheet's card the ringed close.
/// [label] names where back goes (Home, Activity); unset, the bar's
/// `backLabel` names it.
///
/// ```dart
/// LedgerBack(label: 'Activity', onPressed: () => Navigator.of(context).maybePop())
/// ```
///
/// ```dart
/// LedgerBack.close(onPressed: () => Navigator.of(context).maybePop())
/// ```
class LedgerBack extends StatelessWidget {
  /// The way back.
  const LedgerBack({
    required this.onPressed,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _close = false;

  /// The close of a cover or a sheet: the ringed cross, saying "Close".
  const LedgerBack.close({
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : label = null,
       _close = true;

  /// What a press does: pop the route.
  final VoidCallback? onPressed;

  /// Where back goes.
  final String? label;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  final bool _close;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final where = label ?? _BackLabel.of(context);
    final close = _close;
    final words = DesignLocalizations.of(context);
    // "Back to Home" stays English in 0.1.0: the shared words have no
    // "back to" phrase.
    final spoken = close
        ? words.closeButtonLabel
        : where == null
        ? words.backButtonTooltip
        : 'Back to $where';
    // The icon button turns its chevron with the page itself; the crumb's
    // bare glyph is turned here.
    final glyph = close ? LucideIcons.x : LucideIcons.chevronLeft;
    if (close ||
        LedgerSheetShell.around(context) ||
        !LedgerLayout.isWide(context)) {
      return LedgerIconButton.outlined(
        glyph,
        semanticLabel: spoken,
        size: LedgerIconButtonSize.small,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
      );
    }
    final crumb = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: LedgerChromeMetrics.crumbGap,
      children: [
        Icon(
          ledgerDirectional(context, glyph),
          size: LedgerChromeMetrics.crumbGlyph,
          color: t.textSecondary,
        ),
        Flexible(
          child: ledgerCapCenter(
            t.meta,
            Text(
              (where ?? words.backButtonTooltip).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.meta.colored(t.textSecondary),
            ),
          ),
        ),
      ],
    );
    return Transform.translate(
      // Hung into the gutter at the reading start.
      offset: Offset(
        Directionality.of(context) == TextDirection.rtl
            ? LedgerChromeMetrics.crumbHang
            : -LedgerChromeMetrics.crumbHang,
        0,
      ),
      child: LedgerHitSlop(
        child: LedgerPressable(
          onTap: onPressed,
          label: spoken,
          role: LedgerPressRole.link,
          focusNode: focusNode,
          autofocus: autofocus,
          child: crumb,
        ),
      ),
    );
  }
}

/// Publishes the bar's `backLabel` to a [LedgerBack] inside it.
class _BackLabel extends InheritedWidget {
  const _BackLabel({required this.label, required super.child});

  final String? label;

  static String? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_BackLabel>()?.label;

  @override
  bool updateShouldNotify(_BackLabel oldWidget) => label != oldWidget.label;
}

/// The head of a page, in the register its route earns
/// (`RoutePresentation.of`), as the source's shell draws it. A screen stands
/// the one bar in two places:
///
/// - the phone's top bar, 60 tall, opaque paper pinned over the page: on
///   a tab's page the wordmark, then the bell and the avatar; on a pushed
///   page the ringed way back, what the page is ([title]: Account,
///   Transaction) in the serif, centred, and an empty 36 to balance it
///   (the page's [actions] stand there instead when it has one);
/// - the masthead, at the top of the page: on a tab's page the [meta] line
///   in the mono capitals over the [title] in the serif (30, 40 on the
///   desktop), [titleItalic] after it in the italic ("Good evening,
///   *Maren*", "Move *money*"); on the desktop every page's masthead, a
///   pushed page's with the crumb naming where back goes ([backLabel]) over
///   its title, and the search pill and the ringed bell at its end. A
///   [heading] (Spending's month bar) stands in the title's place. A
///   pushed page on a phone has no masthead: its bar names it.
///
/// On a sheet's card it is the sheet's head: the [title] in the serif over
/// the ink rule, the ringed close at its end. Leave [leading] unset: the
/// route's own exit appears ([autoLeading]); a page never authors its own
/// back or close. The bell, avatar and search come from the app's
/// [LedgerAccountScope], the wordmark's name from the app's title.
///
/// ```dart
/// LedgerTopBar(title: 'Good evening,', titleItalic: 'Maren', meta: 'Wednesday, October 28 · 7:40 PM')
/// ```
class LedgerTopBar extends StatelessWidget {
  /// A page's head, titled [title] on a pushed page.
  const LedgerTopBar({
    super.key,
    this.title,
    this.titleItalic,
    this.meta,
    this.leading,
    this.backLabel,
    this.actions = const [],
    this.bellKey,
    this.avatarKey,
    this.heading,
  });

  /// The page's name (a tab's), or what the page is (a pushed page's).
  final String? title;

  /// Words set in the italic after the [title], a space between.
  final String? titleItalic;

  /// The masthead's line over the title (a tab's date), set in capitals.
  final String? meta;

  /// Replaces the route's own exit; leave null.
  final Widget? leading;

  /// Where back goes, as the crumb and the back button name it (Home,
  /// Spending).
  final String? backLabel;

  /// The page's own controls (at most two): at the masthead's end, or a
  /// pushed page's bar's on a phone.
  final List<Widget> actions;

  /// The walkthrough keys set on the account's bell and avatar where the
  /// bar draws them (the phone's top bar on a tab's page; the desktop's
  /// masthead draws the bell).
  final Key? bellKey;

  /// The walkthrough key set on the avatar.
  final Key? avatarKey;

  /// A control standing in the masthead's title place, in place of the
  /// [title]'s words: Spending's month bar (`.monthbar`, the way to earlier
  /// months, the month opening its menu, the way to the next), the page's own
  /// part. It stands at the masthead's top on a phone (`.masthead` 24), 10
  /// under the [meta] on the desktop (`.monthbar { margin-top: 10px }`). The
  /// source's phone bar carries its own date line, so a page passes [meta] for
  /// the desktop only (`meta_desk`). The phone's strip and a pushed page's bar
  /// still read [title].
  final Widget? heading;

  /// The explicit "no bar" for a page whose route would otherwise derive one
  /// (`LedgerScreen(topBar: LedgerTopBar.none)`).
  static const Widget none = SizedBox.shrink(
    key: ValueKey<String>('quire:top-bar:none'),
  );

  /// The route's exit when it can pop: the way back on a pushed page, the
  /// close on a sheet or a cover (the way back on a sheet that closes back,
  /// [LedgerSheetPage.back]), each popping the route; nothing on a root.
  /// This is the only back or close a Ledger page has.
  static Widget? autoLeading(BuildContext context, {Key? key, String? label}) {
    // The page's own route, not its navigator: a root stays exitless while a
    // sheet or a page stands over it.
    final register = RoutePresentation.of(context);
    if (register == RoutePresentation.root) return null;
    final close =
        register == RoutePresentation.sheet &&
        !LedgerSheetPage.closesBack(context);
    void pop() => Navigator.of(context).maybePop();
    return close
        ? LedgerBack.close(key: key, onPressed: pop)
        : LedgerBack(key: key, label: label, onPressed: pop);
  }

  @override
  Widget build(BuildContext context) {
    final exit = leading ?? autoLeading(context, label: backLabel);
    final Widget head;
    if (LedgerSheetShell.around(context)) {
      head = LedgerSheetHead(title: title ?? '', close: exit);
    } else {
      final wide = LedgerLayout.isWide(context);
      final slot =
          LedgerBarSlotScope.of(context) ??
          (wide ? LedgerBarSlot.masthead : LedgerBarSlot.strip);
      head = switch (slot) {
        LedgerBarSlot.strip =>
          wide ? const SizedBox.shrink() : _strip(context, exit),
        LedgerBarSlot.masthead => _masthead(context, exit, wide),
      };
    }
    return _BackLabel(label: backLabel, child: head);
  }

  /// The phone's top bar, opaque paper.
  Widget _strip(BuildContext context, Widget? exit) {
    final t = context.ledgerTheme;
    final account = LedgerAccountScope.maybeOf(context);
    final Widget row;
    if (exit == null) {
      final name = LedgerWordmark.nameOf(context);
      row = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerChromeMetrics.topBarSide,
        ),
        child: Row(
          children: [
            if (name != null) LedgerWordmark(name),
            const Spacer(),
            ...actions,
            if (account != null)
              LedgerAccountMarks(
                account: account,
                bellKey: bellKey,
                avatarKey: avatarKey,
              ),
          ],
        ),
      );
    } else {
      row = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerChromeMetrics.topBarSide,
        ),
        child: NavigationToolbar(
          // The toolbar holds its leading to the bar's whole height; the
          // way back keeps its own round 36 in the middle of it.
          leading: Center(widthFactor: 1, child: exit),
          middle: title == null
              ? null
              : Semantics(
                  header: true,
                  child: ledgerCapCenter(
                    t.barTitle,
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.barTitle,
                    ),
                  ),
                ),
          trailing: actions.isEmpty
              ? const SizedBox(width: LedgerChromeMetrics.topBarSlot)
              : Row(mainAxisSize: MainAxisSize.min, children: actions),
          middleSpacing: LedgerChromeMetrics.toolsGap,
        ),
      );
    }
    final top = MediaQuery.paddingOf(context).top;
    return Semantics(
      container: true,
      // The page's paper, opaque: the source frosts the bar, but a page that
      // scrolls under glass smears through it (no glass, no glow). 60 in
      // all, the hairline drawn over its foot: CSS's border-box leaves 59
      // over the hairline, which centres the 40 avatar and the 28 wordmark
      // on half pixels; on the whole 60 they stand on whole pixels (10 and
      // 16 down), as the browser's snapped paint shows them.
      child: Container(
        color: t.topBarFill,
        foregroundDecoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.hairline)),
        ),
        padding: EdgeInsets.only(top: top),
        // A region for the keyline check: the bar's faces on the page's
        // gutter.
        child: SizedBox(
          height: LedgerChromeMetrics.topBarHeight,
          child: DesignKeylineRegion(label: 'top bar', child: row),
        ),
      ),
    );
  }

  /// `.monthbar { margin-top: 10px }`: a [heading] under the
  /// desktop's meta.
  static const double _headingGapWide = 10;

  /// The masthead: on a phone a tab's meta over its title; on the desktop
  /// every page's, with the crumb, the search pill and the bell.
  Widget _masthead(BuildContext context, Widget? exit, bool wide) {
    final t = context.ledgerTheme;
    final pushed = exit != null;
    if (!wide && pushed && LedgerSideInset.of(context) == 0) {
      return const SizedBox.shrink();
    }
    final account = LedgerAccountScope.maybeOf(context);
    final titleStyle = wide
        ? t.title.sized(LedgerChromeMetrics.titleWide)
        : t.title;
    final words = heading != null
        ? SizedBox(width: double.infinity, child: heading)
        : title == null && titleItalic == null
        ? null
        : Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  if (title != null) TextSpan(text: title),
                  if (title != null && titleItalic != null)
                    const TextSpan(text: ' '),
                  if (titleItalic != null)
                    TextSpan(text: titleItalic, style: titleStyle.italic),
                ],
              ),
              style: titleStyle,
            ),
          );
    // One page frame: at desktop width a pushed page's crumb stands in the
    // eyebrow's own line (the meta's 16, the title 8 under it), so its
    // title, search and bell stand where a tab's do. A meta it has too sets
    // on that line after the crumb.
    final eyebrow =
        (MediaQuery.textScalerOf(context).scale(t.meta.fontSize!) *
                t.meta.height!)
            .roundToDouble();
    final crumb = wide && pushed
        ? SizedBox(
            height: eyebrow,
            child: Row(
              spacing: LedgerChromeMetrics.crumbToMeta,
              children: [
                exit,
                if (meta != null) ...[
                  Text('·', style: t.meta.colored(t.textFaint)),
                  Flexible(
                    child: Text(
                      meta!.toUpperCase(),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: t.meta,
                    ),
                  ),
                ],
              ],
            ),
          )
        : null;
    final lead = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crumb != null)
          crumb
        else if (meta != null)
          Text(meta!.toUpperCase(), style: t.meta),
        if (words != null) ...[
          SizedBox(
            height: meta != null || crumb != null
                ? (heading != null
                      // `.monthbar`: 10 under the desktop's meta, none on
                      // a phone.
                      ? (wide ? _headingGapWide : 0)
                      : wide
                      ? LedgerChromeMetrics.titleGapWide
                      : LedgerChromeMetrics.titleGap)
                : 0,
          ),
          words,
        ],
      ],
    );
    if (!wide) {
      return Padding(
        padding: const EdgeInsets.only(top: LedgerChromeMetrics.mastTop),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: lead),
            ...actions,
          ],
        ),
      );
    }
    final search = account?.onSearchPressed;
    return Padding(
      padding: const EdgeInsets.only(bottom: LedgerChromeMetrics.mastFootWide),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: LedgerChromeMetrics.mastToolsGap,
        children: [
          Expanded(child: lead),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: LedgerChromeMetrics.deskToolsGap,
            children: [
              ...actions,
              if (account != null && search != null)
                _SearchPill(
                  hint:
                      account.searchHint ??
                      DesignLocalizations.of(context).searchFieldLabel,
                  onTap: () => search(context),
                ),
              if (account != null)
                _bellOf(context, account, key: bellKey, ringed: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// The desktop masthead's search: a 264 by 40 pill of raised paper ringed
/// in the rule, its glyph and its hint, opening the app's search.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerPressable(
      onTap: onTap,
      label: hint,
      role: LedgerPressRole.link,
      radius: t.controlRadius,
      child: Container(
        width: LedgerChromeMetrics.deskSearchWidth,
        // 40 at standard, 4 off each density step: the bell beside it
        // (an icon button) steps the same.
        height: t.density.height(
          LedgerChromeMetrics.deskSearchHeight,
          floor: LedgerChromeMetrics.densityFloor,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LedgerChromeMetrics.searchPad,
        ),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.controlRadius),
          border: Border.all(color: t.border),
        ),
        child: Row(
          spacing: LedgerChromeMetrics.searchGap,
          children: [
            Icon(
              LucideIcons.search,
              size: LedgerChromeMetrics.searchGlyph,
              color: t.textSecondary,
            ),
            Expanded(
              child: ledgerCapCenter(
                t.search,
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.search.sized(LedgerChromeMetrics.deskSearchText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
