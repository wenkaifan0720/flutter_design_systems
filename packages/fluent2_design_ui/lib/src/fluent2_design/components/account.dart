// The host app's account, as the chrome shows it (the avatar, the bell and
// its count). Host vocabulary: the package exports it from its host library,
// beside ui_core's host.
import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button/button.dart';

/// Who the app belongs to, as its chrome shows them: their [name] and
/// [initials] (or [image]) in the avatar, the quiet [meta] line under the
/// name at the nav pane's foot, the [unread] count the bell wears, and
/// where the avatar ([onProfile]) and the bell ([onNotifications]) lead.
/// The app mounts one [Fluent2AccountScope] above its router; the top bars
/// and the nav pane read it, so no page passes the person around.
/// [profileLocation] is the profile page's path: the pane's foot is
/// current there (a `:name` segment stands for any one, so
/// '/:root/profile' is the profile pushed on any root).
/// [notificationsLocation] is the bell's page.
///
/// ```dart
/// Fluent2Account(name: 'Ines Duarte', initials: 'ID', meta: 'ines@northwind.example', unread: 3, onProfile: (context) => Navigator.of(context).pushNamed('/profile'))
/// ```
@immutable
class Fluent2Account {
  /// An account called [name].
  const Fluent2Account({
    required this.name,
    required this.initials,
    this.meta,
    this.image,
    this.unread = 0,
    this.onProfile,
    this.onNotifications,
    this.profileLocation,
    this.notificationsLocation,
  });

  /// The person's name.
  final String name;

  /// One or two letters, the avatar's face.
  final String initials;

  /// The quiet line under the name (their address, their role).
  final String? meta;

  /// Their picture; null draws the initials.
  final ImageProvider? image;

  /// How many notifications are unread: the bell wears the count while
  /// more than none.
  final int unread;

  /// Opens the profile; run with the tapped control's context.
  final void Function(BuildContext context)? onProfile;

  /// Opens the notifications.
  final void Function(BuildContext context)? onNotifications;

  /// The profile page's path ('/home/profile', or '/:root/profile').
  final String? profileLocation;

  /// The notifications page's path, read as [profileLocation] is.
  final String? notificationsLocation;

  /// Whether the page at [path] is the profile, or a page under it.
  bool showsProfile(String path) => _shows(profileLocation, path);

  /// Whether the page at [path] is the notifications, or a page under it.
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

/// Publishes the app's [Fluent2Account] to its chrome: mount one above the
/// router (around the host's child).
///
/// ```dart
/// Fluent2AccountScope(account: account, child: child)
/// ```
class Fluent2AccountScope extends InheritedWidget {
  /// Puts [account] in scope for [child].
  const Fluent2AccountScope({
    required this.account,
    required super.child,
    super.key,
  });

  /// The account the chrome shows.
  final Fluent2Account account;

  /// The account in force at [context]; null when the app publishes none,
  /// and the bars then draw no bell or avatar.
  static Fluent2Account? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<Fluent2AccountScope>()
      ?.account;

  @override
  bool updateShouldNotify(Fluent2AccountScope oldWidget) =>
      account != oldWidget.account;
}

/// Fluent 2's CounterBadge as the bell wears it: the count (99+ past 99)
/// in caption2Strong on the danger fill, a pill 16 tall. Plumbing of the
/// bars; the count badge a page places is `Fluent2Badge`.
class _BellCount extends StatelessWidget {
  const _BellCount(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.colors.statusDangerBackground3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.colors.neutralBackground1),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textScaler: TextScaler.noScaling,
        style: t.caption2Strong.c(t.colors.neutralForegroundOnBrand).line(12),
      ),
    );
  }
}

/// The bell that opens [account]'s notifications, its count at its top
/// end corner. Plumbing of the bars.
class Fluent2Bell extends StatelessWidget {
  /// The notifications bell of [account].
  const Fluent2Bell({required this.account, super.key});

  /// The account whose unread count the bell shows.
  final Fluent2Account account;

  @override
  Widget build(BuildContext context) {
    final open = account.onNotifications;
    final n = account.unread;
    return Fluent2IconButton(
      Fluent2Icons.alert,
      label: n > 0
          ? Fluent2Localizations.of(context).notificationsUnread(n)
          : Fluent2Localizations.of(context).notifications,
      onPressed: open == null ? null : () => open(context),
      badge: n > 0 ? _BellCount(n) : null,
    );
  }
}
