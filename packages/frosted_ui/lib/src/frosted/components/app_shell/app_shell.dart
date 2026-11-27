import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

export 'package:ui_core/ui_core.dart'
    show RawBranchBackBehavior, RawNavigationDestination;

import '../../chrome_metrics.dart';
import '../../internal/chosen_plate.dart';
import '../../internal/dim.dart';
import '../../internal/footer_band.dart';
import '../../internal/face.dart';
import '../../internal/sliding_pill.dart';
import '../../theme.dart';
import '../glass.dart' show FrostedBackdropView;
import '../pressable/pressable.dart' show FrostedFocusRing;

/// An app's frame: its places in Frosted's glass tab bar along the foot of a
/// phone or a tablet, and in the sidebar down the start edge from 1024 wide,
/// each place keeping its own stack of pages (as Material's
/// `NavigationBar` and `NavigationDrawer` round a `Scaffold`, or
/// Cupertino's tab scaffold). A page pushed in a place keeps the sidebar
/// beside it while the tab bar steps away ([hideBarOnPush]); back pops it.
/// Toasts keep clear of the tab bar and centre on the page beside the
/// sidebar.
///
/// Built on ui_core's [RawAdaptiveShell.branches], which gives the places
/// their keys (one tab stop, the arrows along them, F6 to the page) and
/// their meaning to a screen reader (tabs in a tab bar, the navigation
/// menu). Each of [destinations] opens its root page from [branches], in
/// order. The sidebar heads itself with [header] (the app's
/// [FrostedWordmark]) and ends with [footer] (the account).
///
/// A page pushes in its own place with `Navigator.of(context).push`; one
/// pushed on the app's root navigator covers the whole frame, as a
/// full-screen editor does.
///
/// ```dart
/// FrostedAppShell(header: const FrostedWordmark('Harbor'), destinations: const [RawNavigationDestination(label: 'Home', icon: FrostedGlyphs.house), RawNavigationDestination(label: 'Account', icon: FrostedGlyphs.person)], branches: [(context) => const Text('Home'), (context) => const Text('Account')])
/// ```
class FrostedAppShell extends StatefulWidget {
  /// A frame over [destinations], each opening its page from [branches].
  const FrostedAppShell({
    required this.destinations,
    required this.branches,
    this.selectedIndex,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.sidebarWidth = FrostedChromeMetrics.sideWidth,
    super.key,
  }) : assert(
         destinations.length == branches.length,
         'Each place has its root page.',
       );

  /// The app's places, two to five, in order.
  final List<RawNavigationDestination> destinations;

  /// Each place's root page, in [destinations]' order.
  final List<WidgetBuilder> branches;

  /// The place shown, when the page keeps it; null: the frame keeps its own,
  /// starting at the first.
  final int? selectedIndex;

  /// Called with the place chosen (the one shown again included, which pops
  /// it to its root).
  final ValueChanged<int>? onDestinationSelected;

  /// What heads the sidebar: the app's [FrostedWordmark], say.
  final Widget? header;

  /// What stands at the sidebar's foot: the account, say.
  final Widget? footer;

  /// The places' navigators' keys, to push in a place from outside (a
  /// notification opening a record); null: the frame's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place at its root page.
  final RawBranchBackBehavior backBehavior;

  /// Whether the tab bar steps away while a page is pushed over a place's
  /// root (the sidebar stays). False keeps the bar under pushed pages, as
  /// Cupertino's tab scaffold does.
  final bool hideBarOnPush;

  /// How wide the sidebar stands, its own width whatever the page's.
  final double sidebarWidth;

  @override
  State<FrostedAppShell> createState() => _FrostedAppShellState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>('destinations', [
          for (final d in destinations) d.label,
        ]),
      )
      ..add(IntProperty('branches', branches.length))
      ..add(
        IterableProperty<GlobalKey<NavigatorState>>(
          'navigatorKeys',
          navigatorKeys,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        EnumProperty<RawBranchBackBehavior>(
          'backBehavior',
          backBehavior,
          defaultValue: RawBranchBackBehavior.firstDestination,
        ),
      )
      ..add(
        FlagProperty(
          'hideBarOnPush',
          value: hideBarOnPush,
          ifFalse: 'bar kept under pushed pages',
        ),
      )
      ..add(
        DoubleProperty(
          'sidebarWidth',
          sidebarWidth,
          defaultValue: FrostedChromeMetrics.sideWidth,
        ),
      );
  }
}

class _FrostedAppShellState extends State<FrostedAppShell> {
  int _own = 0;

  int get _selected => widget.selectedIndex ?? _own;

  void _select(int index) {
    if (widget.selectedIndex == null) setState(() => _own = index);
    widget.onDestinationSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) => FrostedShellFoot(
    hideBarOnPush: widget.hideBarOnPush,
    child: RawAdaptiveShell.branches(
      destinations: widget.destinations,
      branches: widget.branches,
      navigatorKeys: widget.navigatorKeys,
      backBehavior: widget.backBehavior,
      hideBarOnPush: widget.hideBarOnPush,
      selectedIndex: _selected,
      onDestinationSelected: _select,
      // The tab bar to a desktop's width, the sidebar from there.
      modeForWidth: (width) => width < FrostedBreakpoints.wide
          ? RawNavigationMode.bar
          : RawNavigationMode.sidebar,
      destinationBuilder: (context, destination, details) =>
          details.mode.isHorizontal
          ? _Tab(destination: destination, states: details.states)
          : _Link(destination: destination, states: details.states),
      navigationBuilder: (context, details) => details.mode.isHorizontal
          ? _Bar(details: details)
          : _Sidebar(
              details: details,
              width: widget.sidebarWidth,
              header: widget.header,
              footer: widget.footer,
            ),
    ),
  );
}

/// The tab bar: the slab of glass 64 tall on the page's gutter, 12 over the
/// foot (or the system's inset), the chosen tab on a brighter plate that
/// slides between them. From a tablet's width it hugs its tabs in the
/// middle of the foot.
class _Bar extends StatelessWidget {
  const _Bar({required this.details});

  final RawNavigationDetails details;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final count = details.destinations.length;
    const edges = EdgeInsets.all(FrostedStrokes.regular);
    final radius = t.corner(
      RawCorner.extraLarge,
      FrostedChromeMetrics.slabRadius,
    );
    const plateInset =
        FrostedChromeMetrics.selectionInset + FrostedStrokes.regular;
    final slab = SizedBox(
      height: FrostedChromeMetrics.slabHeight,
      child: FrostedFace(
        material: FrostedMaterial.bar,
        radius: BorderRadius.circular(radius),
        edge: t.glass.edge,
        edges: edges,
        sheen: t.glass.rim,
        shadows: t.shadows.bar,
        child: FrostedSlidingPill(
          count: count,
          selected: details.selectedIndex,
          inset: const EdgeInsets.all(FrostedChromeMetrics.selectionInset),
          pill: FrostedChosenPlate(
            radius: BorderRadius.circular(math.max(0, radius - plateInset)),
          ),
          builder: (context, keys) => details.group(
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, destination) in details.destinations.indexed)
                  Expanded(
                    child: KeyedSubtree(key: keys[i], child: destination),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final box = Padding(
      padding: EdgeInsets.fromLTRB(
        FrostedChromeMetrics.tabBarSide,
        FrostedSpacing.s8,
        FrostedChromeMetrics.tabBarSide,
        math.max(
          FrostedChromeMetrics.tabBarBottom,
          MediaQuery.paddingOf(context).bottom,
        ),
      ),
      child: slab,
    );
    // The look's light under the slab, so the glass reads the page's ground.
    return _OnLight(
      child: FrostedBreakpoints.isCompact(context)
          ? box
          : Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      2 * FrostedChromeMetrics.tabBarSide +
                      count * FrostedChromeMetrics.tabBarTabMedium,
                ),
                child: box,
              ),
            ),
    );
  }
}

/// A tab: its glyph 4 over its word in the faint ink; the chosen one in the
/// ink, its word semibold, its glyph the chosen one.
class _Tab extends StatelessWidget {
  const _Tab({required this.destination, required this.states});

  final RawNavigationDestination destination;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final selected = states.contains(WidgetState.selected);
    final ink = selected
        ? t.colorScheme.textPrimary
        : t.colorScheme.textTertiary;
    final glyph = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;
    return FrostedFocusRing(
      shown: states.contains(WidgetState.focused),
      hovered: states.contains(WidgetState.hovered),
      radius: t.corner(RawCorner.small, FrostedCorners.r10),
      insets: const EdgeInsets.all(FrostedStrokes.heavy),
      inside: true,
      child: FrostedEase<(Color, TextStyle)>(
        value: (
          ink,
          selected ? t.textTheme.tab.semibold.c(ink) : t.textTheme.tab.c(ink),
        ),
        lerp: FrostedEase.inkAndWords,
        builder: (context, shown) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedChromeMetrics.tabGap,
            children: [
              // The chosen glyph fades in over the plain one.
              AnimatedSwitcher(
                duration: motion.base,
                switchInCurve: motion.curve,
                switchOutCurve: motion.curve,
                child: Icon(
                  glyph,
                  key: ValueKey(glyph),
                  size: FrostedChromeMetrics.tabGlyph,
                  color: shown.$1,
                ),
              ),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: shown.$2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sidebar: a column of glass down the start edge, a hairline at its
/// end, the [header] over the places and the [footer] at its foot.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.details,
    required this.width,
    required this.header,
    required this.footer,
  });

  final RawNavigationDetails details;
  final double width;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final padding = MediaQuery.paddingOf(context);
    return SizedBox(
      width: width,
      child: _OnLight(
        child: FrostedFace(
          material: FrostedMaterial.bar,
          radius: BorderRadius.zero,
          ring: const Color(0x00000000),
          sheen: const Color(0x00000000),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: BorderDirectional(
                end: BorderSide(color: t.glass.sidebarEdge),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                FrostedChromeMetrics.sideStart,
                FrostedChromeMetrics.sideTop + padding.top,
                FrostedChromeMetrics.sideEnd + FrostedChromeMetrics.outline,
                FrostedChromeMetrics.sideBottom + padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FrostedChromeMetrics.sideGap,
                children: [
                  ?header,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: FrostedChromeMetrics.navGap,
                    children: details.destinations,
                  ),
                  const Spacer(),
                  ?footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A place in the sidebar: its glyph 12 before its word in a pill 40 tall;
/// the chosen one on the brighter plate, in the ink.
class _Link extends StatelessWidget {
  const _Link({required this.destination, required this.states});

  final RawNavigationDestination destination;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const h = FrostedChromeMetrics.navLink;
    final selected = states.contains(WidgetState.selected);
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
            selected
                ? (destination.selectedIcon ?? destination.icon)
                : destination.icon,
            size: FrostedChromeMetrics.navGlyph,
            color: shown.$1,
          ),
          Expanded(
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: shown.$2,
            ),
          ),
        ],
      ),
    );
    const padding = EdgeInsets.symmetric(
      horizontal: FrostedChromeMetrics.navLinkInset,
    );
    return FrostedFocusRing(
      shown: states.contains(WidgetState.focused),
      hovered: states.contains(WidgetState.hovered),
      radius: h / 2,
      child: SizedBox(
        height: h,
        // The chosen place stands on thicker, brighter glass; the others on
        // the bar's own. Both keep the same room, so a glyph and its word
        // stand still as the place is chosen.
        child: selected
            ? FrostedChosenPlate(
                radius: BorderRadius.circular(h / 2),
                padding: padding,
                child: row,
              )
            : FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(h / 2),
                padding: padding,
                child: row,
              ),
      ),
    );
  }
}

/// The look's light behind the navigation's glass: the part of the app's
/// one backdrop that stands under it, so it meets the page's with no seam.
class _OnLight extends StatelessWidget {
  const _OnLight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: FrostedBackdropView()),
      child,
    ],
  );
}
