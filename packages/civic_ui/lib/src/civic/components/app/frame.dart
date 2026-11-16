import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../../internal/frame_scope.dart';
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
/// wide ([CivicNavigationBar]), the same places down the start as a rail
/// from 600 (a tablet), the site's [CivicSideNavigation] from 1024, with the
/// app's one [action]. What [CivicShell] stands a router's branches in, and
/// [CivicPreview] one page; an app with its own navigation can stand its
/// pages in it too.
///
/// [showPlaces] false takes the bar off a phone (a page pushed over a
/// place); from 600 wide the places stay on every page.
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

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return child;
    final t = context.civicTheme;
    final act = action;
    final width = MediaQuery.sizeOf(context).width;
    if (CivicLayout.isApp(width) && width >= CivicLayout.medium) {
      // A tablet: the phone's places down the start, the act over them.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MediaQuery.removePadding(
            context: context,
            removeRight: Directionality.of(context) == TextDirection.ltr,
            removeLeft: Directionality.of(context) == TextDirection.rtl,
            child: CivicRailScope(
              leading: act == null ? null : _Act(act, wide: false),
              child: CivicNavigationBar(
                destinations: places,
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelected,
              ),
            ),
          ),
          Expanded(
            child: CivicFrameScope(besideNavigation: true, child: child),
          ),
        ],
      );
    }
    if (!CivicLayout.isApp(width)) {
      final name = brand;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MediaQuery.removePadding(
            context: context,
            removeRight: Directionality.of(context) == TextDirection.ltr,
            removeLeft: Directionality.of(context) == TextDirection.rtl,
            child: CivicSideNavigation(
              destinations: places,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelected,
              header: name == null
                  ? null
                  : Text(name, style: context.civicText.headingS),
              footer: act == null ? null : _Act(act, wide: true),
            ),
          ),
          // The page's bar and column line up with the places beside it.
          Expanded(
            child: CivicFrameScope(besideNavigation: true, child: child),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: showPlaces,
            child: child,
          ),
        ),
        if (showPlaces)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CivicNavigationBar(
                  destinations: places,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                ),
              ),
              if (act != null)
                // The act's square stands on the bar's rule, at its end.
                DecoratedBox(
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
                      child: Center(child: _Act(act, wide: false)),
                    ),
                  ),
                ),
            ],
          ),
      ],
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
