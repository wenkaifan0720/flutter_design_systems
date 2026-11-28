import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../ground.dart';
import '../internal/controls.dart';
import '../internal/nav_faces.dart';
import '../internal/press_feedback.dart';
import '../internal/rail_action.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'nav_bar.dart';
import 'navigation.dart';
import 'shell_action.dart';
import 'nav_item.dart';

/// The frame of an app: its places along the bottom of a phone, down a rail
/// on a tablet, in a sidebar on a desktop, and its pages beside or above
/// them.
///
/// The shell reads its own width against Minimal's two breakpoints, the
/// same ones [MinimalLayout] keeps: under [MinimalLayout.compact] the places
/// stand in a bar along the bottom, a glyph over each label; up to
/// [MinimalLayout.expanded] in a rail at the start edge; from there in a
/// sidebar [sidebarWidth] wide, [header] at its head. The current place is
/// said in type alone, its glyph and label in the full ink.
///
/// [MinimalAppShell.branches] gives each place a navigator of its own, so
/// a page pushed on one keeps the rail or the sidebar beside it while the
/// phone's bar steps away for it, and back pops it before it leaves the
/// place. Choosing the current place again
/// returns it to its first page. The plain constructor stands [body], the
/// app's own, beside the places.
///
/// A screen reader hears the places as tabs, the current one selected, each
/// with its place ("Tab 1 of 3"); a sidebar is the navigation menu. The
/// places are one Tab stop, the arrow keys walking them, and F6 moves
/// between them and the page. Toasts stand above the bar and beside the
/// rail or the sidebar.
///
/// [action] is the app's one act from every place: the square at the bar's
/// end, at the top of the rail, or a button under the sidebar's head.
///
/// [extended] false folds the sidebar to the rail at any wide width, as
/// Flutter's `NavigationRail.extended` does, the pages keeping their state
/// and taking the room; with [onExtendedChanged] the sidebar's head and the
/// folded rail's top hold a key that folds and unfolds it. Keep the answer
/// in the app's settings to open the app as the person left it.
///
/// ```dart
/// MinimalAppShell.branches(destinations: const [MinimalNavItem(LucideIcons.bookOpen, 'Books'), MinimalNavItem(LucideIcons.settings, 'Settings')], selectedIndex: place, onDestinationSelected: (index) => setState(() => place = index), branches: [(context) => const BooksPage(), (context) => const SettingsPage()])
/// ```
class MinimalAppShell extends StatelessWidget {
  /// A shell round the app's own [body].
  const MinimalAppShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.body,
    this.action,
    this.header,
    this.sidebarWidth = defaultSidebarWidth,
    this.extended = true,
    this.onExtendedChanged,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination;

  /// A shell whose places each keep a navigator of their own, starting on
  /// its [branches] page: a page pushed on a place keeps the rail or the
  /// sidebar, and back pops it, then goes where [backBehavior] says.
  const MinimalAppShell.branches({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.action,
    this.header,
    this.sidebarWidth = defaultSidebarWidth,
    this.extended = true,
    this.onExtendedChanged,
  }) : body = null;

  /// The places, in order.
  final List<MinimalNavItem> destinations;

  /// The current place.
  final int selectedIndex;

  /// Reports the place chosen, the current one again included; null
  /// disables them all.
  final ValueChanged<int>? onDestinationSelected;

  /// The app's pages; null with [branches].
  final Widget? body;

  /// Each place's first page; null with [body].
  final List<WidgetBuilder>? branches;

  /// The places' navigators' keys, to push onto a place from outside it;
  /// null keeps the shell's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a place's first page.
  final RawBranchBackBehavior backBehavior;

  /// The app's one act from every place.
  final MinimalShellAction? action;

  /// What stands at the sidebar's head, a bar tall: the app's name, a
  /// workspace switch. The shell insets it to the sidebar's gutter, as the
  /// items under it: pass bare content (a `Text`), no padding of its own.
  /// The bar and the rail leave it out.
  final Widget? header;

  /// The sidebar's width.
  final double sidebarWidth;

  /// Whether a wide shell shows the sidebar (true) or folds it to the rail
  /// (false). The bar and the rail of narrower widths stay as they are.
  final bool extended;

  /// Called with the [extended] the person asks for from the key at the
  /// sidebar's head or the folded rail's top; null: no key, the caller
  /// alone folds it.
  ///
  /// ```dart
  /// MinimalAppShell(destinations: const [MinimalNavItem(LucideIcons.bookOpen, 'Books'), MinimalNavItem(LucideIcons.settings, 'Settings')], selectedIndex: place, onDestinationSelected: go, extended: wide, onExtendedChanged: (value) => setState(() => wide = value), body: const BooksPage())
  /// ```
  final ValueChanged<bool>? onExtendedChanged;

  /// The sidebar's width unless [sidebarWidth] says otherwise.
  static const double defaultSidebarWidth = 248;

  /// How the places stand at [width]: a bar under [MinimalLayout.compact],
  /// a rail under [MinimalLayout.expanded], a sidebar from there.
  static RawNavigationMode modeFor(double width) =>
      width < MinimalLayout.compact
      ? RawNavigationMode.bar
      : width < MinimalLayout.expanded
      ? RawNavigationMode.rail
      : RawNavigationMode.sidebar;

  // A wide shell folded to the rail.
  RawNavigationMode _modeFor(double width) {
    final mode = modeFor(width);
    return !extended && mode == RawNavigationMode.sidebar
        ? RawNavigationMode.rail
        : mode;
  }

  @override
  Widget build(BuildContext context) {
    final places = [
      for (final item in destinations)
        RawNavigationDestination(
          label: item.label ?? item.semanticLabel ?? '',
          icon: item.icon,
          data: item,
        ),
    ];
    final branches = this.branches;
    // Whether the shell is wide enough for the sidebar, folded or not: the
    // folded rail's key unfolds it there, and only there.
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.hasBoundedWidth
            ? box.maxWidth
            : MediaQuery.sizeOf(context).width;
        final wide = modeFor(width) == RawNavigationMode.sidebar;
        Widget navigation(BuildContext context, RawNavigationDetails details) =>
            _navigation(context, details, wide: wide);
        return branches == null
            ? RawAdaptiveShell(
                destinations: places,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinationBuilder: _destination,
                navigationBuilder: navigation,
                modeForWidth: _modeFor,
                body: body!,
              )
            : RawAdaptiveShell.branches(
                destinations: places,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinationBuilder: _destination,
                navigationBuilder: navigation,
                modeForWidth: _modeFor,
                branches: branches,
                navigatorKeys: navigatorKeys,
                backBehavior: backBehavior,
              );
      },
    );
  }

  Widget _destination(
    BuildContext context,
    RawNavigationDestination destination,
    RawDestinationDetails details,
  ) {
    final t = context.minimalTheme;
    final item = destinations[details.index];
    final states = details.states;
    final selected = states.contains(WidgetState.selected);
    final enabled = !states.contains(WidgetState.disabled);
    final face = switch (details.mode) {
      RawNavigationMode.bar ||
      RawNavigationMode.top => MinimalTabFace(item: item, selected: selected),
      RawNavigationMode.rail => MinimalRailFace(
        item: item,
        selected: selected,
        width: minimalRailCellWidth(context, destinations),
      ),
      RawNavigationMode.sidebar => MinimalSidebarFace(
        item: item,
        selected: selected,
      ),
    };
    return KeyedSubtree(
      key: item.key,
      child: MinimalPressFeedback(
        states: states,
        enabled: enabled,
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
        shape: details.mode == RawNavigationMode.bar ? null : t.shapes.small,
        focusInside: details.mode != RawNavigationMode.rail,
        child: face,
      ),
    );
  }

  Widget _navigation(
    BuildContext context,
    RawNavigationDetails details, {
    required bool wide,
  }) {
    final index = details.selectedIndex;
    final ground = index >= 0 && index < destinations.length
        ? destinations[index].ground
        : MinimalGround.surface;
    return MinimalGroundScope(
      ground: ground,
      child: Builder(
        builder: (context) => switch (details.mode) {
          // Minimal's widths never ask for a header of places; were one
          // asked for, it would be the bar's row.
          RawNavigationMode.bar ||
          RawNavigationMode.top => _bar(context, details),
          RawNavigationMode.rail => _side(
            context,
            _rail(context, details, folded: wide && !extended),
          ),
          RawNavigationMode.sidebar => _side(
            context,
            _sidebar(context, details),
          ),
        },
      ),
    );
  }

  // The rail or the sidebar on the side's card, its edge ruled: as one
  // folds to the other the card's width eases between theirs, the
  // sidebar's words cut at its edge rather than squeezed.
  Widget _side(BuildContext context, Widget side) {
    final t = context.minimalTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.card,
        border: rtl ? Border(left: t.rule) : Border(right: t.rule),
      ),
      // Under Reduce Motion it folds at once.
      child: context.minimalStill
          ? side
          : AnimatedSize(
              duration: MinimalMotion.slow,
              curve: MinimalMotion.out,
              alignment: AlignmentDirectional.topStart,
              clipBehavior: Clip.hardEdge,
              child: side,
            ),
    );
  }

  // The key that folds the sidebar to the rail and back, when the caller
  // takes the answer; its glyph's panel stands on the start side.
  Widget? _fold(BuildContext context) {
    final onChanged = onExtendedChanged;
    if (onChanged == null) return null;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final words = MinimalLocalizations.of(context);
    return MinimalIconButton(
      switch ((extended, rtl)) {
        (true, false) => LucideIcons.panelLeftClose,
        (true, true) => LucideIcons.panelRightClose,
        (false, false) => LucideIcons.panelLeftOpen,
        (false, true) => LucideIcons.panelRightOpen,
      },
      semanticLabel:
          '${RawWidgetsLocalizations.of(context).drawerLabel}, '
          '${words.expandedState(expanded: extended)}',
      variant: MinimalIconButtonVariant.ghost,
      onPressed: () => onChanged(!extended),
    );
  }

  Widget _bar(BuildContext context, RawNavigationDetails details) {
    final t = context.minimalTheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final action = this.action;
    final tabs = Row(
      children: [
        for (final place in details.destinations) Expanded(child: place),
      ],
    );
    return Container(
      height: MinimalNavigationBar.heightIn(safeBottom),
      padding: EdgeInsets.only(bottom: safeBottom),
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: t.rule),
      ),
      child: action == null
          ? tabs
          : Row(
              children: [
                // The tab bar is the places alone; the act is no tab.
                Expanded(child: details.group(tabs)),
                SizedBox(
                  width: MinimalChromeMetrics.tabActionSlot,
                  child: Center(child: MinimalRailAction(action: action)),
                ),
              ],
            ),
    );
  }

  Widget _rail(
    BuildContext context,
    RawNavigationDetails details, {
    required bool folded,
  }) {
    final action = this.action;
    final cell = minimalRailCellWidth(context, destinations);
    // Folded from a sidebar, the rail's top holds the key that unfolds it.
    final unfold = folded ? _fold(context) : null;
    return SizedBox(
      width: cell + MinimalNavigationRail.width - MinimalNavigationRail.cell,
      child: SafeArea(
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s12),
          child: Column(
            children: [
              if (unfold != null) ...[
                unfold,
                const MinimalGap(MinimalSpacing.s12),
              ],
              if (action != null) ...[
                MinimalRailAction(action: action),
                const MinimalGap(MinimalSpacing.s12),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  // Cut a scrolled run past the rail's room, but not a
                  // place's focus ring, drawn outside its cell.
                  child: ClipRect(
                    clipper: const MinimalRingRoom(),
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final place in details.destinations)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: MinimalSpacing.s4,
                              ),
                              child: place,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebar(BuildContext context, RawNavigationDetails details) {
    final action = this.action;
    final head = header;
    final fold = _fold(context);
    return SizedBox(
      width: sidebarWidth,
      child: SafeArea(
        left: false,
        right: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MinimalSpacing.s8,
            head == null && fold == null ? MinimalSpacing.s8 : 0,
            MinimalSpacing.s8,
            MinimalSpacing.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The head stands in a band a page's bar tall, so it lines up
              // with the bar of the page beside it.
              // The fold key at the band's end, on the head's middle.
              if (head != null || fold != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: MinimalChromeMetrics.barHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: MinimalSpacing.s8,
                      end: fold == null ? MinimalSpacing.s8 : 0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [?head],
                          ),
                        ),
                        ?fold,
                      ],
                    ),
                  ),
                ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MinimalSpacing.s8,
                  ),
                  child: Builder(
                    builder: (context) => MinimalButton(
                      action.label ?? MinimalLocalizations.of(context).create,
                      key: action.key,
                      icon: action.icon,
                      variant: action.primary
                          ? MinimalButtonVariant.primary
                          : MinimalButtonVariant.secondary,
                      expand: true,
                      onPressed: () => action.onPressed(context),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final place in details.destinations)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: MinimalSpacing.s2,
                          ),
                          child: place,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(
        IterableProperty<GlobalKey<NavigatorState>>(
          'navigatorKeys',
          navigatorKeys,
          defaultValue: null,
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
        DiagnosticsProperty<MinimalShellAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(
        DoubleProperty(
          'sidebarWidth',
          sidebarWidth,
          defaultValue: defaultSidebarWidth,
        ),
      )
      ..add(
        FlagProperty(
          'extended',
          value: extended,
          ifFalse: 'folded to the rail',
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onExtendedChanged',
          onExtendedChanged,
        ),
      );
  }
}
