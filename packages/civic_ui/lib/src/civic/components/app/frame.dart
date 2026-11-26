import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/frame_scope.dart';
import '../../internal/places.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../icon-button/icon_button.dart';
import '../navigation/navigation.dart';

/// One of an app's places, written as generated code writes it: its glyph,
/// its name and the key its control carries.
///
/// ```dart
/// const CivicNavItem(LucideIcons.fileText, 'Applications', ValueKey('applications'))
/// ```
class CivicNavItem extends CivicNavigationDestination {
  /// The place called [label].
  const CivicNavItem(IconData icon, String label, [Key? key])
    : super(icon: icon, label: label, key: key);
}

/// The app's one act beside its places (Apply, Report a problem): a square
/// in the action colour at the end of the places on a phone, over them in a
/// tablet's rail, a button under them from 1024 wide. Give it a [label]: it
/// is what a screen reader says, and from 1024 wide what the button says.
///
/// ```dart
/// CivicShellAction(
///   icon: LucideIcons.plus,
///   label: 'Apply for a permit',
///   onPressed: (context) => Navigator.of(context).pushNamed('/apply'),
/// )
/// ```
@immutable
class CivicShellAction {
  /// The act.
  const CivicShellAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.accent = false,
    this.key,
  });

  /// Its glyph.
  final IconData icon;

  /// What it does, run with a context under the app's navigator.
  final void Function(BuildContext context) onPressed;

  /// Its words: what a screen reader says, and from 1024 wide what the
  /// button says.
  final String? label;

  /// Whether it stands in the action colour; otherwise in ink.
  final bool accent;

  /// The key its control carries, for a test to find it by.
  final Key? key;
}

/// An app's frame: its places along the bottom of a phone, in a rail from
/// 600 wide and in a side navigation from 1024, with the page beside them.
///
/// The places are painted as [CivicNavigationBar] and [CivicSideNavigation]
/// paint them, with the app's one [action] beside them.
///
/// [CivicAppShell.branches] gives each place its own stack of pages: a page
/// pushed with `Navigator.of(context).push` stands over its place, the
/// rail or the side navigation still beside it while a phone's bar steps
/// away ([hideBarOnPush]), and back pops it. Choosing the place again goes
/// back to its first page. A page pushed on the app's root navigator
/// covers the whole frame, as a full-screen form does. [CivicAppShell]
/// stands the app's own [child] instead (a router's branches), with
/// [showPlaces] false while a page is pushed over a place.
///
/// ui_core's [RawAdaptiveShell] under Civic's painting and Civic's
/// widths: the places are one tab stop, the arrow keys moving along them
/// (Up and Down in the rail and the side navigation) and Enter or Space
/// choosing; F6 moves the focus between the places and the page. A screen
/// reader hears each place as a tab with its place ("Tab 1 of 3"), and the
/// side navigation as the navigation menu.
///
/// [showPlaces] false takes the bar off a phone, on a spring; from 600
/// wide the places stay on every page.
///
/// ```dart
/// CivicAppShell.branches(
///   destinations: const [
///     CivicNavItem(LucideIcons.house, 'Home'),
///     CivicNavItem(LucideIcons.fileText, 'Applications'),
///   ],
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   branches: [
///     (context) => const HomePage(),
///     (context) => const ApplicationsPage(),
///   ],
/// )
/// ```
class CivicAppShell extends StatelessWidget {
  /// The frame around the app's own [child].
  const CivicAppShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.child,
    this.action,
    this.brand,
    this.showPlaces = true,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false;

  /// A frame whose places each keep their own stack of pages, starting on
  /// its [branches] page.
  const CivicAppShell.branches({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.action,
    this.brand,
    this.showPlaces = true,
  }) : child = null;

  /// The app's places, in order.
  final List<CivicNavigationDestination> destinations;

  /// The place the reader is in.
  final int selectedIndex;

  /// Called with a place's index when the reader picks it.
  final ValueChanged<int>? onDestinationSelected;

  /// The page, or the router's branches; null with [branches].
  final Widget? child;

  /// Each place's first page; null with [child].
  final List<WidgetBuilder>? branches;

  /// The places' navigators' keys, to push onto a place from outside (a
  /// notification opening a detail); null: the frame's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place at its first page: to the first place,
  /// then out of the app.
  final RawBranchBackBehavior backBehavior;

  /// Whether a phone's bar steps away while a page is pushed over a place
  /// ([CivicAppShell.branches]); the rail and the side navigation stay.
  final bool hideBarOnPush;

  /// The app's one act.
  final CivicShellAction? action;

  /// The service's name, above the places from 1024 wide.
  final String? brand;

  /// Whether a phone shows the places' bar.
  final bool showPlaces;

  /// How the places stand in a window [width] wide: Civic's widths, not
  /// Material's (a bar below [CivicLayout.medium], a rail to
  /// [CivicLayout.expanded], the site's side navigation from there).
  static RawNavigationMode modeFor(double width) => !CivicLayout.isApp(width)
      ? RawNavigationMode.sidebar
      : width >= CivicLayout.medium
      ? RawNavigationMode.rail
      : RawNavigationMode.bar;

  @override
  Widget build(BuildContext context) {
    final pages = branches;
    if (destinations.isEmpty) {
      return child ??
          (pages == null || pages.isEmpty
              ? const SizedBox()
              : pages.first(context));
    }
    // The places' mode and the pages' frame from the one width: the
    // frame's own.
    return LayoutBuilder(
      builder: (context, constraints) => _frame(
        context,
        modeFor(
          constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width,
        ),
      ),
    );
  }

  Widget _frame(BuildContext context, RawNavigationMode mode) {
    final t = context.civicTheme;
    final styles = [null, t.navigationStyle];
    final labels = [for (final p in destinations) p.label];
    final act = action;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The places beside the page take no inset on the page's side.
    Widget beside(Widget navigation) => MediaQuery.removePadding(
      context: context,
      removeRight: !rtl,
      removeLeft: rtl,
      child: navigation,
    );
    final raw = [
      for (final p in destinations)
        RawNavigationDestination(
          label: p.label,
          icon: p.icon,
          selectedIcon: p.selectedIcon,
        ),
    ];
    Widget place(
      BuildContext context,
      RawNavigationDestination destination,
      RawDestinationDetails details,
    ) {
      final selected = details.states.contains(WidgetState.selected);
      // The key a test finds the place by, as the place's own.
      return KeyedSubtree(
        key: destinations[details.index].key,
        child: details.mode == RawNavigationMode.sidebar
            ? CivicSidePlace(
                styles: styles,
                label: destination.label,
                states: details.states,
                selected: selected,
              )
            : CivicBarPlace(
                styles: styles,
                icon: destination.icon,
                selectedIcon: destination.selectedIcon,
                label: destination.label,
                states: details.states,
                selected: selected,
                rail: details.mode == RawNavigationMode.rail,
              ),
      );
    }

    Widget navigation(BuildContext context, RawNavigationDetails details) =>
        switch (details.mode) {
          // A phone: the places along the foot, the act's square at their
          // end. A bar is a tab bar to a screen reader, which holds its tabs
          // alone: the shell's group stands round the places, the act
          // outside it. Civic's places never stand in a header ([modeFor]).
          RawNavigationMode.bar || RawNavigationMode.top => CivicPlacesBand(
            styles: styles,
            labels: labels,
            places: details.destinations,
            group: details.group,
            trailing: act == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: CivicSpacing.s4,
                      end: CivicSpacing.s8,
                    ),
                    child: _Act(act, wide: false),
                  ),
          ),
          // A tablet: the phone's places down the start, the act over them.
          RawNavigationMode.rail => beside(
            CivicPlacesRail(
              styles: styles,
              labels: labels,
              lead: act == null ? null : _Act(act, wide: false),
              places: details.destinations,
            ),
          ),
          RawNavigationMode.sidebar => beside(
            CivicPlacesSide(
              styles: styles,
              headerInset: brand == null
                  ? CivicSpacing.s24
                  : MediaQuery.paddingOf(context).top +
                        civicHeaderInset(context, context.civicText.headingS),
              header: brand == null
                  ? null
                  : Text(brand!, style: context.civicText.headingS),
              footer: act == null ? null : _Act(act, wide: true),
              places: details.destinations,
            ),
          ),
        };

    final pages = branches;
    // The pages' bar and column line up with the places beside them.
    return CivicFrameScope(
      besideNavigation: mode != RawNavigationMode.bar,
      child: pages == null
          ? RawAdaptiveShell(
              modeForWidth: modeFor,
              showNavigation: showPlaces,
              dampingRatio: CivicMotion.panel.dampingRatio,
              stiffness: CivicMotion.panel.stiffness,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: raw,
              destinationBuilder: place,
              navigationBuilder: navigation,
              body: child!,
            )
          : RawAdaptiveShell.branches(
              modeForWidth: modeFor,
              showNavigation: showPlaces,
              hideBarOnPush: hideBarOnPush,
              backBehavior: backBehavior,
              navigatorKeys: navigatorKeys,
              dampingRatio: CivicMotion.panel.dampingRatio,
              stiffness: CivicMotion.panel.stiffness,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: raw,
              destinationBuilder: place,
              navigationBuilder: navigation,
              branches: pages,
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        FlagProperty(
          'hideBarOnPush',
          value: hideBarOnPush,
          ifFalse: 'bar under pushed pages',
        ),
      )
      ..add(
        FlagProperty('showPlaces', value: showPlaces, ifFalse: 'places hidden'),
      );
  }
}

/// The old name of [CivicAppShell].
@Deprecated(
  'Use CivicAppShell. '
  'This name was deprecated in 0.8.0 and is removed in 1.0.0.',
)
typedef CivicShellFrame = CivicAppShell;

/// The act: a square of its glyph in an app; from 1024 wide its words
/// beside the glyph when it has them.
class _Act extends StatelessWidget {
  const _Act(this.action, {required this.wide});

  final CivicShellAction action;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final (fill, ink) = action.accent
        ? (t.action, t.onAction)
        : (t.textPrimary, t.background);
    final words = action.label;
    void press() => action.onPressed(context);
    if (wide && words != null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: action.accent
            ? CivicButton(
                key: action.key,
                icon: action.icon,
                expand: false,
                onPressed: press,
                child: Text(words),
              )
            : CivicButton.secondary(
                key: action.key,
                icon: action.icon,
                expand: false,
                onPressed: press,
                child: Text(words),
              ),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: CivicIconButton(
        key: action.key,
        icon: action.icon,
        semanticLabel: words ?? '',
        onPressed: press,
        style: CivicStyle(
          fill: WidgetStatePropertyAll(fill),
          foreground: WidgetStatePropertyAll(ink),
        ),
      ),
    );
  }
}
