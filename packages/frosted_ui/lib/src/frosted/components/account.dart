// The demo account shell: who the app belongs to, as its chrome shows them
// (the bell and the avatar at a top bar's end, the sidebar's foot). App
// chrome, exported from the host library, not the main one.
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../glyphs.dart';
import '../localizations.dart';
import 'avatar/avatar.dart';
import 'icon-button/round_button.dart';

/// Who the app belongs to, as its chrome shows them: the [initials] in the
/// avatar, the [name] and the quiet [meta] line ("Profile and settings")
/// at the sidebar's foot, the [unread] count the bell wears, and where the
/// avatar ([onProfile]) and the bell ([onNotifications]) lead. The app
/// mounts one [FrostedAccountScope] above its router; the top bars and the
/// sidebar read it, so no page passes the person around. [profileLocation]
/// is the profile page's path: the sidebar's foot is current there (a
/// `:name` segment stands for any one, so '/:root/profile' is the profile
/// pushed on any root). [notificationsLocation] is the bell's page, where
/// the sidebar marks nothing current, as the source's notifications do.
///
/// ```dart
/// FrostedAccount(name: 'Maren Holt', initials: 'MH', meta: 'Profile and settings', unread: 1, onProfile: (context) => Navigator.of(context).pushNamed('/profile'))
/// ```
@immutable
class FrostedAccount {
  /// Creates a [FrostedAccount].
  const FrostedAccount({
    required this.name,
    required this.initials,
    this.meta,
    this.unread = 0,
    this.onProfile,
    this.onNotifications,
    this.profileLocation,
    this.notificationsLocation,
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
  final void Function(BuildContext context)? onProfile;

  /// Opens the notifications.
  final void Function(BuildContext context)? onNotifications;

  /// The profile page's path, where the sidebar's foot is current: read as
  /// written ('/home/profile'), or with go_router's `:name` segments
  /// standing for any one segment ('/:root/profile', the profile pushed on
  /// any root, as a router that nests it under every branch has it).
  final String? profileLocation;

  /// The notifications page's path, read as [profileLocation] is
  /// ('/:root/notifications'): while it is shown the sidebar marks no
  /// destination current, as the source's notifications light none.
  final String? notificationsLocation;

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

/// Publishes the app's [FrostedAccount] to its chrome: mount one above the
/// router (around the host's child), rebuilt when the person or the unread
/// count changes.
///
/// ```dart
/// FrostedAccountScope(account: account, child: child)
/// ```
class FrostedAccountScope extends InheritedWidget {
  /// Creates a [FrostedAccountScope].
  const FrostedAccountScope({
    required this.account,
    required super.child,
    super.key,
  });

  /// The account the bars show.
  final FrostedAccount account;

  /// The account in force at [context]; null when the app publishes none,
  /// and the bars then draw no bell or avatar.
  static FrostedAccount? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FrostedAccountScope>()
      ?.account;

  @override
  bool updateShouldNotify(FrostedAccountScope oldWidget) =>
      account != oldWidget.account;
}

/// The bell, then the avatar, of [account], 8 apart: what a top bar wears
/// at its end on a root (`.top-r`) and on a desktop detail. Plumbing of
/// the bars.
///
/// ```dart
/// FrostedAccountMarks(account: const FrostedAccount(name: 'Maya Chen', initials: 'MC'))
/// ```
class FrostedAccountMarks extends StatelessWidget {
  /// Creates a [FrostedAccountMarks].
  const FrostedAccountMarks({
    required this.account,
    this.bell = true,
    this.avatar = true,
    this.bellKey,
    this.avatarKey,
    super.key,
  });

  /// Whose bell and avatar.
  final FrostedAccount account;

  /// Whether the bell shows.
  final bool bell;

  /// Whether the avatar shows.
  final bool avatar;

  /// The walkthrough keys set on the bell's and the avatar's hit targets.
  final Key? bellKey;

  /// A key for the avatar.
  final Key? avatarKey;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: FrostedChromeMetrics.barEndGap,
    children: [
      if (bell) _bellOf(context, account, key: bellKey),
      if (avatar) _avatarOf(context, account, key: avatarKey),
    ],
  );
}

/// The bell that opens [account]'s notifications, carrying [key].
Widget _bellOf(BuildContext context, FrostedAccount account, {Key? key}) {
  final open = account.onNotifications;
  return FrostedBell(
    key: key,
    unread: account.unread,
    onPressed: open == null ? null : () => open(context),
  );
}

/// The bar's avatar that opens [account]'s profile, carrying [key].
Widget _avatarOf(BuildContext context, FrostedAccount account, {Key? key}) {
  final open = account.onProfile;
  return FrostedAvatar(
    account.initials,
    key: key,
    name: FrostedLocalizations.of(context).profileAndSettings,
    onPressed: open == null ? null : () => open(context),
  );
}

/// The bell of a top bar: a round button that opens the notifications,
/// wearing the coral dot while [unread] is more than none and saying how
/// many to a screen reader.
///
/// ```dart
/// FrostedBell(unread: 1, onPressed: () => Navigator.of(context).pushNamed('/notifications'))
/// ```
class FrostedBell extends StatelessWidget {
  /// Creates a [FrostedBell].
  const FrostedBell({required this.unread, required this.onPressed, super.key});

  /// How many notifications are unread.
  final int unread;

  /// Opens the notifications; null draws the bell inert.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FrostedIconButton(
    FrostedGlyphs.bell,
    label: FrostedLocalizations.of(context).unreadNotifications(unread),
    badge: unread > 0,
    onPressed: onPressed,
  );
}
