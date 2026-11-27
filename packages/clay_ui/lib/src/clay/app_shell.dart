/// The host's app shell: [ClayAppShell] round a router's page or a
/// preview's, its places as [ClayTab]s and its one act a [ClayShellAction].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import 'button.dart';
import 'navigation.dart';
import 'theme.dart';

/// The app's places and its one act round a root page: [ClayScaffold]'s
/// dock on a phone, its rail on a tablet, its sidebar on a desktop. The act
/// is coral clay in the chrome, never floating over the page: a ball at the
/// dock's end on a phone, under the app's name at the head of the rail, a
/// worded key under it on the sidebar. It is the host's frame round one
/// page, a router's or a preview's: an app that keeps a stack of pages per
/// place builds on [ClayScaffold.branches] instead.
///
/// ```dart
/// ClayAppShell(tabs: const [ClayTab(LucideIcons.sun, 'Today'), ClayTab(LucideIcons.listChecks, 'Habits')], selectedIndex: 0, onDestinationSelected: (i) {}, child: const TodayPage())
/// ```
class ClayAppShell extends StatelessWidget {
  /// [child] with the app's [tabs].
  const ClayAppShell({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.action,
    this.brand,
    this.showPlaces = true,
  });

  /// The app's places.
  final List<ClayTab> tabs;

  /// The place shown.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The page.
  final Widget child;

  /// The app's one act.
  final ShellAction? action;

  /// The app's name, at the head of the rail or the sidebar.
  final String? brand;

  /// Whether a phone's dock stands: false while a page pushed over the root
  /// covers it (a rail or a sidebar stays).
  final bool showPlaces;

  @override
  Widget build(BuildContext context) {
    final act = action;
    final name = brand;
    return ClayScaffold(
      destinations: [
        for (final tab in tabs)
          ClayDestination(icon: tab.icon, label: tab.label, key: tab.key),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: tabs.isNotEmpty ? onDestinationSelected : null,
      showNavigation: showPlaces,
      brand: name == null || name.isEmpty ? null : _Brand(name),
      action: act == null ? null : _ActKey(act),
      body: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ClayTab>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<ShellAction>('action', action, defaultValue: null),
      )
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        FlagProperty('showPlaces', value: showPlaces, ifTrue: 'showPlaces'),
      );
  }
}

/// The app's name at the head of its places: in the title type where it
/// fits, its first letter where it does not (a rail).
class _Brand extends StatelessWidget {
  const _Brand(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 120;
        return Semantics(
          header: true,
          label: name,
          child: ExcludeSemantics(
            child: Text(
              narrow ? name.characters.first.toUpperCase() : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: narrow ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.title.copyWith(color: theme.colors.ink),
            ),
          ),
        );
      },
    );
  }
}

/// The shell's act: coral clay when it is the app's standing invitation
/// ([ShellAction.accent]), else plain clay. The sidebar has room for its
/// words: a key with its glyph; elsewhere a ball.
class _ActKey extends StatelessWidget {
  const _ActKey(this.action);

  final ShellAction action;

  @override
  Widget build(BuildContext context) {
    final words = action.label ?? 'New';
    void press() => action.onPressed(context);
    final wide =
        MediaQuery.sizeOf(context).width >= ClayMetrics.sidebarBreakpoint;
    if (wide) {
      final glyph = Icon(action.icon);
      return KeyedSubtree(
        key: action.key,
        child: action.accent
            ? ClayButton.filled(words, onPressed: press, icon: glyph)
            : ClayButton(words, onPressed: press, icon: glyph),
      );
    }
    return KeyedSubtree(
      key: action.key,
      child: action.accent
          ? ClayIconButton.filled(
              onPressed: press,
              tooltip: words,
              icon: Icon(action.icon),
            )
          : ClayIconButton(
              onPressed: press,
              tooltip: words,
              icon: Icon(action.icon),
            ),
    );
  }
}

/// One of an app shell's places as an app declares it: its glyph, its name
/// and the key on its cell.
///
/// ```dart
/// ClayTab(LucideIcons.sun, 'Today', ValueKey('open-today'))
/// ```
@immutable
class ClayTab {
  /// A place called [label], shown by [icon].
  const ClayTab(this.icon, this.label, [this.key]);

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its cell.
  final Key? key;
}

/// The app's one act beside its places (add, log, capture): coral clay in
/// the chrome when [accent], plain clay when not.
///
/// ```dart
/// ClayShellAction(icon: LucideIcons.plus, accent: true, onPressed: (context) => openNewHabit(context))
/// ```
class ClayShellAction extends ShellAction {
  /// An act wearing [icon].
  const ClayShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent = true,
    super.key,
  });
}
