import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

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
class CivicShellAction extends ShellAction {
  /// The act.
  const CivicShellAction({
    required super.icon,
    required super.onPressed,
    super.label,
    super.accent,
    super.key,
  });
}

/// An app's frame around its pages: the places along the bottom below 600
/// wide (as a [CivicNavigationBar] paints them), the same places down the
/// start as a rail from 600 (a tablet), the site's side navigation (as a
/// [CivicSideNavigation] paints it) from 1024, with the app's one [action].
/// What `CivicShell` stands a router's branches in, and [CivicPreview] one
/// page; an app with its own navigation can stand its pages in it too.
///
/// ui_core's [DesignAdaptiveShell] under Civic's painting and Civic's
/// widths: the places are one tab stop, the arrow keys moving along them
/// (Up and Down in the rail and the side navigation) and Enter or Space
/// choosing; F6 moves the focus between the places and the page. A screen
/// reader hears each place as a tab with its place ("Tab 1 of 3"), and the
/// side navigation as the navigation menu.
///
/// [showPlaces] false takes the bar off a phone (a page pushed over a
/// place), on a spring; from 600 wide the places stay on every page.
///
/// ```dart
/// CivicShellFrame(
///   places: const [
///     CivicNavItem(LucideIcons.house, 'Home'),
///     CivicNavItem(LucideIcons.fileText, 'Applications'),
///   ],
///   selectedIndex: index,
///   onSelected: (i) => setState(() => index = i),
///   child: pages[index],
/// )
/// ```
class CivicShellFrame extends StatelessWidget {
  /// The frame around [child].
  const CivicShellFrame({
    super.key,
    required this.places,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.action,
    this.brand,
    this.showPlaces = true,
  });

  /// The app's places, in order.
  final List<CivicNavigationDestination> places;

  /// The place the reader is in.
  final int selectedIndex;

  /// Called with a place's index when the reader picks it.
  final ValueChanged<int>? onSelected;

  /// The page, or the router's branches.
  final Widget child;

  /// The app's one act.
  final ShellAction? action;

  /// The service's name, above the places from 1024 wide.
  final String? brand;

  /// Whether a phone shows the places' bar.
  final bool showPlaces;

  /// How the places stand in a window [width] wide: Civic's widths, not
  /// Material's (a bar below [CivicLayout.medium], a rail to
  /// [CivicLayout.expanded], the site's side navigation from there).
  static DesignNavigationMode modeFor(double width) => !CivicLayout.isApp(width)
      ? DesignNavigationMode.sidebar
      : width >= CivicLayout.medium
      ? DesignNavigationMode.rail
      : DesignNavigationMode.bar;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return child;
    final t = context.civicTheme;
    final styles = [null, t.navigationStyle];
    final labels = [for (final p in places) p.label];
    final act = action;
    final mode = modeFor(MediaQuery.sizeOf(context).width);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The places beside the page take no inset on the page's side.
    Widget beside(Widget navigation) => MediaQuery.removePadding(
      context: context,
      removeRight: !rtl,
      removeLeft: rtl,
      child: navigation,
    );
    return DesignAdaptiveShell(
      mode: mode,
      showNavigation: showPlaces,
      dampingRatio: CivicMotion.panel.dampingRatio,
      stiffness: CivicMotion.panel.stiffness,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: [
        for (final p in places)
          DesignNavigationDestination(
            label: p.label,
            icon: p.icon,
            selectedIcon: p.selectedIcon,
          ),
      ],
      destinationBuilder: (context, destination, details) {
        final selected = details.states.contains(WidgetState.selected);
        // The key a test finds the place by, as the place's own.
        return KeyedSubtree(
          key: places[details.index].key,
          child: details.mode == DesignNavigationMode.sidebar
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
                  rail: details.mode == DesignNavigationMode.rail,
                ),
        );
      },
      navigationBuilder: (context, details) => switch (details.mode) {
        // A phone: the places along the foot, the act's square at their end.
        // A bar is a tab bar to a screen reader, which holds its tabs alone:
        // the shell's group stands round the places, the act outside it.
        DesignNavigationMode.bar => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CivicPlacesBand(
                styles: styles,
                labels: labels,
                places: details.destinations,
                group: details.group,
              ),
            ),
            if (act != null) _ActSquare(act),
          ],
        ),
        // A tablet: the phone's places down the start, the act over them.
        DesignNavigationMode.rail => beside(
          CivicPlacesRail(
            styles: styles,
            labels: labels,
            lead: act == null ? null : _Act(act, wide: false),
            places: details.destinations,
          ),
        ),
        DesignNavigationMode.sidebar => beside(
          CivicPlacesSide(
            styles: styles,
            header: brand == null
                ? null
                : Text(brand!, style: context.civicText.headingS),
            footer: act == null ? null : _Act(act, wide: true),
            places: details.destinations,
          ),
        ),
      },
      // The page's bar and column line up with the places beside it.
      body: CivicFrameScope(
        besideNavigation: mode != DesignNavigationMode.bar,
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(StringProperty('brand', brand, defaultValue: null))
      ..add(
        FlagProperty('showPlaces', value: showPlaces, ifFalse: 'places hidden'),
      );
  }
}

/// The act's square on a phone: its glyph on the bar's ground and rule, at
/// the bar's height above the safe inset.
class _ActSquare extends StatelessWidget {
  const _ActSquare(this.action);

  final ShellAction action;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: BorderSide(color: t.rule)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: CivicSpacing.s4,
          end: CivicSpacing.s8,
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: SizedBox(
          height: CivicNavigationBar.height,
          child: Center(child: _Act(action, wide: false)),
        ),
      ),
    );
  }
}

/// The act: a square of its glyph in an app; from 1024 wide its words
/// beside the glyph when it has them.
class _Act extends StatelessWidget {
  const _Act(this.action, {required this.wide});

  final ShellAction action;
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
