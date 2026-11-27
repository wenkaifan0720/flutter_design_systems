import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/measure.dart';
import '../internal/nav_faces.dart';
import '../localizations.dart';
import '../theme.dart';
import 'acrylic.dart';
import 'button/button.dart';
import 'nav_bar.dart';
import 'pressable/pressable.dart';
import 'tooltip/tooltip.dart';

/// The frame of an app: its places in a tab bar along the foot of a phone,
/// in the nav pane's rail on a tablet, in the nav pane on a desktop, and its
/// pages beside or above them.
///
/// The shell reads its own width against Fluent's breakpoints, the ones
/// [Fluent2Layout] keeps: under [Fluent2Layout.medium] (640) the places
/// stand in the acrylic tab bar, a glyph over each label; up to
/// [Fluent2Layout.wide] (1024) in a rail of glyphs down the start edge, each
/// named in a tooltip; from there in the nav pane, [sidebarWidth] wide,
/// [header] at its head. The current place wears its filled glyph and the
/// brand's selection indicator.
///
/// [Fluent2AppShell.branches] gives each place a navigator of its own, so a
/// page pushed on one keeps the rail or the pane beside it while the phone's
/// tab bar steps away for it, and back pops it before it leaves the place.
/// Choosing the current place again returns it to its first page. The plain
/// constructor stands [body], the app's own, beside the places.
///
/// A screen reader hears the places as tabs, the current one selected, each
/// with its place ("Tab 1 of 3"); the pane is the navigation menu. The
/// places are one Tab stop, the arrow keys walking them, and F6 moves
/// between them and the page. Toasts stand above the tab bar and beside the
/// rail or the pane.
///
/// [action] is the app's one act from every place: on a phone Fluent's
/// floating action button over the end of each place's first page, above
/// the tab bar; at the top of the rail; the primary button under the pane's
/// head.
///
/// ```dart
/// Fluent2AppShell.branches(destinations: const [Fluent2NavItem(Fluent2Icons.home, 'Home'), Fluent2NavItem(Fluent2Icons.settings, 'Settings')], selectedIndex: place, onDestinationSelected: (index) => setState(() => place = index), branches: [(context) => const HomePage(), (context) => const SettingsPage()])
/// ```
class Fluent2AppShell extends StatelessWidget {
  /// A shell round the app's own [body].
  const Fluent2AppShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required Widget this.body,
    this.action,
    this.header,
    this.sidebarWidth = defaultSidebarWidth,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination;

  /// A shell whose places each keep a navigator of their own, starting on
  /// its [branches] page: a page pushed on a place keeps the rail or the
  /// pane, and back pops it, then goes where [backBehavior] says.
  const Fluent2AppShell.branches({
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
  }) : body = null;

  /// The places, in order.
  final List<Fluent2NavItem> destinations;

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
  final Fluent2ShellAction? action;

  /// What stands at the pane's head, a bar tall: the app's name, an account
  /// switch. The tab bar and the rail leave it out.
  final Widget? header;

  /// The pane's width.
  final double sidebarWidth;

  /// The pane's width unless [sidebarWidth] says otherwise: Fluent's 260.
  static const double defaultSidebarWidth = Fluent2ChromeMetrics.paneWidth;

  /// How the places stand at [width]: a tab bar under
  /// [Fluent2Layout.medium], a rail under [Fluent2Layout.wide], the pane
  /// from there.
  static RawNavigationMode modeFor(double width) => width < Fluent2Layout.medium
      ? RawNavigationMode.bar
      : width < Fluent2Layout.wide
      ? RawNavigationMode.rail
      : RawNavigationMode.sidebar;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final t = context.fluent2Theme;
      final width = box.hasBoundedWidth
          ? box.maxWidth
          : MediaQuery.sizeOf(context).width;
      // Every tab's label whole, one size across the bar, as the standalone
      // bar sets them.
      final scale = fluent2FitScale(
        context,
        [for (final item in destinations) item.label],
        t.caption1Strong,
        width / math.max(1, destinations.length) -
            2 * Fluent2ChromeMetrics.tabLabelSide,
      );
      final places = [
        for (final item in destinations)
          RawNavigationDestination(
            label: item.label,
            icon: item.icon,
            data: item,
          ),
      ];
      Widget destination(
        BuildContext context,
        RawNavigationDestination destination,
        RawDestinationDetails details,
      ) => _destination(context, details, scale);
      Widget navigation(BuildContext context, RawNavigationDetails details) =>
          _navigation(context, details, scale);
      final branches = this.branches;
      final shell = branches == null
          ? RawAdaptiveShell(
              destinations: places,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinationBuilder: destination,
              navigationBuilder: navigation,
              modeForWidth: modeFor,
              body: _ActOverPage(child: body!),
            )
          : RawAdaptiveShell.branches(
              destinations: places,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinationBuilder: destination,
              navigationBuilder: navigation,
              modeForWidth: modeFor,
              branches: [
                for (final first in branches)
                  (context) => _ActOverPage(child: first(context)),
              ],
              navigatorKeys: navigatorKeys,
              backBehavior: backBehavior,
            );
      return _ShellScope(mode: modeFor(width), action: action, child: shell);
    },
  );

  Widget _destination(
    BuildContext context,
    RawDestinationDetails details,
    double scale,
  ) {
    final item = destinations[details.index];
    final states = details.states;
    final selected = states.contains(WidgetState.selected);
    final face = switch (details.mode) {
      RawNavigationMode.bar || RawNavigationMode.top => Fluent2TabFace(
        icon: item.icon,
        selectedIcon: item.selectedIcon,
        label: item.label,
        selected: selected,
        scale: scale,
        states: states,
      ),
      // The rail's glyphs are named in a tooltip after them, as the
      // standalone rail names them.
      RawNavigationMode.rail => Fluent2Tooltip(
        message: item.label,
        position: Fluent2TooltipPosition.after,
        child: Fluent2PaneItemFace(
          icon: item.icon,
          selectedIcon: item.selectedIcon,
          label: item.label,
          selected: selected,
          collapsed: true,
          states: states,
        ),
      ),
      RawNavigationMode.sidebar => Fluent2PaneItemFace(
        icon: item.icon,
        selectedIcon: item.selectedIcon,
        label: item.label,
        selected: selected,
        states: states,
      ),
    };
    return KeyedSubtree(
      key: item.key,
      child: Fluent2PressFace(
        states: states,
        radius: Fluent2Radius.medium,
        padded: false,
        child: face,
      ),
    );
  }

  Widget _navigation(
    BuildContext context,
    RawNavigationDetails details,
    double scale,
  ) => switch (details.mode) {
    // Fluent's widths never ask for a header of places; were one asked
    // for, it would be the tab bar's row.
    RawNavigationMode.bar ||
    RawNavigationMode.top => _bar(context, details, scale),
    RawNavigationMode.rail => _rail(context, details),
    RawNavigationMode.sidebar => _pane(context, details),
  };

  Widget _bar(
    BuildContext context,
    RawNavigationDetails details,
    double scale,
  ) {
    final t = context.fluent2Theme;
    final inset = MediaQuery.paddingOf(context).bottom;
    final size = t.caption1.fontSize ?? 12;
    // The bar grows by what the labels' line grows.
    final grown = (scale - 1) * size * (t.caption1.height ?? 1);
    return Fluent2Acrylic(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: t.colors.neutralStroke2)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: SizedBox(
            height: Fluent2ChromeMetrics.tabBarHeight + math.max(0, grown),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final place in details.destinations)
                  Expanded(child: place),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rail(BuildContext context, RawNavigationDetails details) {
    final t = context.fluent2Theme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final act = action;
    // Under a finger an item spans the rail (48, past the floor's 40).
    final touch = Fluent2Layout.padded(context);
    return Container(
      width: Fluent2ChromeMetrics.paneRail,
      decoration: BoxDecoration(color: t.background),
      foregroundDecoration: BoxDecoration(
        border: BorderDirectional(
          end: BorderSide(color: t.colors.neutralStroke2),
        ),
      ),
      child: SafeArea(
        left: !rtl,
        right: rtl,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: touch ? 0 : Fluent2Spacing.xs,
            vertical: Fluent2Spacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (act != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
                  child: Center(child: _ActButton(action: act, compact: true)),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Fluent2Spacing.xxs,
                    children: details.destinations,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pane(BuildContext context, RawNavigationDetails details) {
    final t = context.fluent2Theme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final act = action;
    final head = header;
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(color: t.background),
      foregroundDecoration: BoxDecoration(
        border: BorderDirectional(
          end: BorderSide(color: t.colors.neutralStroke2),
        ),
      ),
      child: SafeArea(
        left: !rtl,
        right: rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Fluent2ChromeMetrics.paneInset,
            Fluent2ChromeMetrics.paneInset,
            Fluent2ChromeMetrics.paneInset,
            Fluent2Spacing.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The head stands a bar tall, so it lines up with the bar of
              // the page beside it.
              if (head != null)
                SizedBox(
                  height: Fluent2ChromeMetrics.paneHead,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: Fluent2Spacing.s,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: DefaultTextStyle.merge(
                        style: t.subtitle2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: head,
                      ),
                    ),
                  ),
                ),
              if (act != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Fluent2Spacing.s,
                  ),
                  child: _ActButton(action: act, compact: false),
                ),
              const SizedBox(height: Fluent2Spacing.xs),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Fluent2Spacing.xxs,
                    children: details.destinations,
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
      ..add(IterableProperty<Fluent2NavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>?>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(DiagnosticsProperty<Widget>('body', body, defaultValue: null))
      ..add(
        IterableProperty<WidgetBuilder>(
          'branches',
          branches,
          defaultValue: null,
        ),
      )
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
        DiagnosticsProperty<Fluent2ShellAction>(
          'action',
          action,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<Widget>('header', header, defaultValue: null))
      ..add(
        DoubleProperty(
          'sidebarWidth',
          sidebarWidth,
          defaultValue: defaultSidebarWidth,
        ),
      );
  }
}

/// The app's one act from every place of a [Fluent2AppShell] or a
/// [Fluent2NavigationBar] or [Fluent2NavigationDrawer]: its glyph, what it
/// does, and its words, printed beside the glyph where there is room (the
/// pane's button, an extended floating button) and spoken where there is
/// not.
///
/// ```dart
/// Fluent2ShellAction(icon: Fluent2Icons.edit, label: 'New message', accent: true, onPressed: (context) => Navigator.of(context).push(compose))
/// ```
@immutable
class Fluent2ShellAction with Diagnosticable {
  /// The act: [icon], [label], [onPressed] with a context under the app's
  /// navigator.
  const Fluent2ShellAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.accent = false,
    this.key,
  });

  /// The glyph it wears.
  final IconData icon;

  /// What it does, run with a context under the app's navigator.
  final void Function(BuildContext context) onPressed;

  /// Its words; null says the localized "Create".
  final String? label;

  /// Whether it wears the brand (the primary button) rather than the
  /// secondary one.
  final bool accent;

  /// The key set on its button.
  final Key? key;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(
        ObjectFlagProperty<void Function(BuildContext)>.has(
          'onPressed',
          onPressed,
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('accent', value: accent, ifTrue: 'accent'))
      ..add(DiagnosticsProperty<Key>('key', key, defaultValue: null));
  }
}

// The shell's mode and act, for the act a phone's first pages float.
class _ShellScope extends InheritedWidget {
  const _ShellScope({
    required this.mode,
    required this.action,
    required super.child,
  });

  final RawNavigationMode mode;
  final Fluent2ShellAction? action;

  static _ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShellScope>();

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      mode != oldWidget.mode || action != oldWidget.action;
}

// A place's first page, with the shell's act floating over its end above
// the tab bar while the places stand in the bar.
class _ActOverPage extends StatelessWidget {
  const _ActOverPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = _ShellScope.maybeOf(context);
    final act = scope?.action;
    if (act == null || scope?.mode != RawNavigationMode.bar) return child;
    return Stack(
      children: [
        Positioned.fill(child: child),
        PositionedDirectional(
          end: Fluent2ChromeMetrics.fabInset,
          bottom: Fluent2ChromeMetrics.fabInset,
          child: Builder(
            builder: (context) => Fluent2FloatingActionButton(
              key: act.key,
              icon: act.icon,
              label: act.label,
              onPressed: () => act.onPressed(context),
            ),
          ),
        ),
      ],
    );
  }
}

// The act at the head of the rail (its glyph alone) or under the pane's
// head (the primary or secondary button, its words beside the glyph).
class _ActButton extends StatelessWidget {
  const _ActButton({required this.action, required this.compact});

  final Fluent2ShellAction action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final words = Fluent2Localizations.of(context);
    final appearance = action.accent
        ? Fluent2ButtonAppearance.primary
        : Fluent2ButtonAppearance.secondary;
    return compact
        ? Fluent2IconButton(
            action.icon,
            key: action.key,
            semanticLabel: action.label ?? words.create,
            appearance: appearance,
            size: Fluent2ButtonSize.large,
            onPressed: () => action.onPressed(context),
          )
        : Fluent2Button(
            action.label ?? words.create,
            key: action.key,
            icon: action.icon,
            appearance: appearance,
            size: Fluent2ButtonSize.large,
            expand: true,
            onPressed: () => action.onPressed(context),
          );
  }
}
