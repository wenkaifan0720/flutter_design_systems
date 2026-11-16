/// Brutal's navigation, all cells on shared rules: [BrutalAppBar] with its
/// [BrutalAppBarAction]s, [BrutalTabBar], and the three ways between an
/// app's places ([BrutalNavigationBar] under 600 px, [BrutalNavigationRail]
/// to 1024, [BrutalSideNavigation] past it), which [BrutalScaffold] picks by
/// width.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'lists.dart';
import 'surface.dart';
import 'theme.dart';

/// The words under a bar's or a rail's icons grow with the reader's text size
/// only to 1.3, as Flutter's own bottom navigation bar's do, and shrink to
/// their cell where even that would not fit, as a tab bar's do on iOS: never
/// cut off.
TextScaler _labelScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

/// A cell that turns over to ink while pressed or chosen, and shows its
/// keyboard focus as a square line inside itself. Every navigation cell is
/// one.
class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.onPressed,
    required this.builder,
    this.layers = const [],
    this.chosen = false,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final bool chosen;
  final String? semanticLabel;
  final List<BrutalStyle?> layers;
  final Widget Function(
    BuildContext context,
    Color words,
    bool lit,
    DesignStyleOf layered,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final c = BrutalTheme.of(context).colors;
    return DesignPressable(
      onPressed: onPressed,
      selected: chosen,
      semanticSelected: chosen ? true : null,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf(layers, {
          ...states,
          if (chosen) WidgetState.selected,
        });
        final lit = chosen || states.contains(WidgetState.pressed);
        final disabled = states.contains(WidgetState.disabled);
        final words =
            layered.foreground ??
            (disabled
                ? c.disabled
                : lit
                ? c.onColor(layered.fill ?? c.ink)
                : c.ink);
        return AnimatedBrutalSurface(
          stiffness: BrutalMotion.colorStiffness,
          face: BrutalFace(
            fill: lit ? (layered.fill ?? c.ink) : c.ink.withValues(alpha: 0),
            border: c.ink.withValues(alpha: 0),
            foreground: words,
            borderWidth: 0,
          ),
          child: CustomPaint(
            foregroundPainter: states.contains(WidgetState.focused)
                ? BrutalInsetFocusPainter(lit ? c.paper : c.ink)
                : null,
            child: builder(context, words, lit, layered),
          ),
        );
      },
    );
  }
}

/// A square action cell at the end of a [BrutalAppBar]: a glyph, its own
/// rule at its start.
///
/// Reads [style]'s `fill` (while pressed), `foreground` and `iconSize`, then
/// [BrutalThemeData.iconButtonStyle]'s.
///
/// ```dart
/// BrutalAppBarAction(icon: const Icon(LucideIcons.search), semanticLabel: 'Search', onPressed: () {})
/// ```
class BrutalAppBarAction extends StatelessWidget {
  /// An action showing [icon].
  const BrutalAppBarAction({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.style,
  });

  /// The glyph, 24 px.
  final Widget icon;

  /// What a screen reader calls it.
  final String semanticLabel;

  /// Called when pressed; null disables it.
  final VoidCallback? onPressed;

  /// Its style, over [BrutalThemeData.iconButtonStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: BrutalAppBar.height,
    child: _Cell(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      layers: [style, BrutalTheme.of(context).iconButtonStyle],
      builder: (context, words, _, layered) => Center(
        child: IconTheme.merge(
          data: IconThemeData(size: layered.iconSize ?? 24, color: words),
          child: icon,
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// The bar over a screen: a back cell at the start when [onBack] is set
/// (or the [leading] cell given, usually [autoLeading]'s), the [title] in
/// the title type, and square [actions] at the end, each on a full-height
/// rule. A rule runs under the whole bar.
///
/// Reads [style]'s `fill` (the bar), `edge` (its rules), `foreground` (the
/// title and the back glyph) and `textStyle` (the title), then
/// [BrutalThemeData.appBarStyle]'s.
///
/// ```dart
/// BrutalAppBar(title: 'Tickets', onBack: () => Navigator.pop(context), actions: [BrutalAppBarAction(icon: const Icon(LucideIcons.search), semanticLabel: 'Search', onPressed: () {})])
/// ```
class BrutalAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// A bar titled [title].
  const BrutalAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.large = false,
    this.style,
  });

  /// The way out the route implies, for [leading]: a back cell on a pushed
  /// page, a close cell in a sheet ([RoutePresentation.sheet]), nothing at
  /// a root. Either pops the route. [key] goes on the cell.
  ///
  /// ```dart
  /// BrutalAppBar(title: 'Event', leading: BrutalAppBar.autoLeading(context))
  /// ```
  static Widget? autoLeading(BuildContext context, {Key? key}) =>
      switch (RoutePresentation.of(context)) {
        RoutePresentation.root => null,
        RoutePresentation.pushed => _ExitCell(key: key, close: false),
        RoutePresentation.sheet => _ExitCell(key: key, close: true),
      };

  /// The screen's name.
  final String title;

  /// Called by the back cell; null: no back cell.
  final VoidCallback? onBack;

  /// The start cell in place of the back cell, usually [autoLeading]'s;
  /// it stands in a square cell on the bar's rule.
  final Widget? leading;

  /// Action cells at the end, usually [BrutalAppBarAction]s.
  final List<Widget> actions;

  /// Whether the title stands in the headline type under the bar's row: a
  /// top-level screen's.
  final bool large;

  /// The bar's row's height, without the rule.
  static const double height = 56;

  /// Its style, over [BrutalThemeData.appBarStyle].
  final BrutalStyle? style;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + BrutalMetrics.maxBorderWidth + (large ? 56 : 0));

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.appBarStyle], const {});
    final rule = layered.side?.color ?? layered.edge;
    final words = layered.foreground ?? c.ink;
    final top = MediaQuery.paddingOf(context).top;
    final margin = BrutalSpacing.pageMargin(MediaQuery.sizeOf(context).width);
    final back = onBack;
    final start = leading ?? (back == null ? null : _ExitCell(onPressed: back));
    final row = SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (start != null) ...[
            SizedBox(width: height, child: start),
            BrutalRule(vertical: true, color: rule),
          ],
          Expanded(
            child: large
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: start == null ? margin : BrutalSpacing.regular,
                      end: BrutalSpacing.regular,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        header: true,
                        child: DesignCapCenter(
                          capHeightFactor: BrutalTheme.of(context)
                              .capHeightFactor,
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: layered.text(
                              theme.textTheme.title.copyWith(color: words),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          for (final action in actions) ...[
            BrutalRule(vertical: true, color: rule),
            action,
          ],
        ],
      ),
    );
    return _BarLayers(
      layers: [style, theme.appBarStyle],
      child: ColoredBox(
        color: layered.fill ?? c.paper,
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row,
              if (large)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: margin,
                    end: margin,
                    bottom: BrutalSpacing.medium,
                  ),
                  child: Semantics(
                    header: true,
                    child: SizedBox(
                      height: 56 - BrutalSpacing.medium,
                      child: Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: layered.text(
                            theme.textTheme.headline.copyWith(color: words),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              BrutalRule(color: rule),
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
      ..add(StringProperty('title', title))
      ..add(ObjectFlagProperty<VoidCallback>.has('onBack', onBack))
      ..add(FlagProperty('large', value: large, ifTrue: 'large'))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// The bar's style layers, for its exit cell.
class _BarLayers extends InheritedWidget {
  const _BarLayers({required this.layers, required super.child});

  final List<BrutalStyle?> layers;

  @override
  bool updateShouldNotify(_BarLayers old) => old.layers != layers;
}

/// The bar's back or close cell: the arrow (or the cross) in the bar's
/// words, turning over to ink while pressed. Given no [onPressed], it pops
/// the route it stands in.
class _ExitCell extends StatelessWidget {
  const _ExitCell({super.key, this.close = false, this.onPressed});

  final bool close;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final layers =
        context.getInheritedWidgetOfExactType<_BarLayers>()?.layers ??
        [theme.appBarStyle];
    final bar = DesignStyleOf(layers, const {});
    final words = DesignLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return _Cell(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      semanticLabel: close ? words.closeButtonLabel : words.backButtonTooltip,
      layers: [
        BrutalStyle(
          foreground: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed) ? null : bar.foreground,
          ),
        ),
      ],
      builder: (context, words, _, _) => Center(
        child: Icon(
          close
              ? LucideIcons.x
              : rtl
              ? LucideIcons.arrowRight
              : LucideIcons.arrowLeft,
          size: 24,
          color: words,
        ),
      ),
    );
  }
}

/// One of an app's places, for [BrutalNavigationBar], [BrutalNavigationRail],
/// [BrutalSideNavigation] and [BrutalScaffold].
@immutable
class BrutalDestination {
  /// A place called [label], shown by [icon].
  const BrutalDestination({required this.icon, required this.label, this.key});

  /// Its glyph.
  final IconData icon;

  /// Its name.
  final String label;

  /// The key on its cell, the target a test or a walkthrough taps.
  final Key? key;
}

/// The bar of an app's places along a phone's bottom: a cell for each, all
/// the same width, on full-height rules, under a rule across the screen.
/// The chosen cell is filled with ink.
///
/// Reads [style]'s `fill` (a chosen or pressed cell's), `foreground` (in
/// each cell's states), `edge` (the rules), `textStyle` (the names) and
/// `iconSize`, then [BrutalThemeData.navigationBarStyle]'s.
///
/// ```dart
/// BrutalNavigationBar(destinations: const [BrutalDestination(icon: LucideIcons.house, label: 'Home'), BrutalDestination(icon: LucideIcons.ticket, label: 'Tickets')], selectedIndex: index, onSelected: (i) => setState(() => index = i))
/// ```
class BrutalNavigationBar extends StatelessWidget {
  /// A bar over [destinations].
  const BrutalNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.style,
  });

  /// Its style, over [BrutalThemeData.navigationBarStyle].
  final BrutalStyle? style;

  /// The places, two to five.
  final List<BrutalDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final layers = [style, theme.navigationBarStyle];
    final bar = DesignStyleOf(layers, const {});
    final rule = bar.side?.color ?? bar.edge;
    return ColoredBox(
      color: theme.colors.paper,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrutalRule(color: rule),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, d) in destinations.indexed) ...[
                  if (i > 0) BrutalRule(vertical: true, color: rule),
                  Expanded(
                    child: _Cell(
                      key: d.key,
                      onPressed: () => onSelected(i),
                      chosen: i == selectedIndex,
                      semanticLabel: d.label,
                      layers: layers,
                      builder: (context, words, _, layered) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            d.icon,
                            size: layered.iconSize ?? 24,
                            color: words,
                          ),
                          const SizedBox(height: BrutalSpacing.tight),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              d.label.toUpperCase(),
                              textScaler: _labelScaler(context),
                              maxLines: 1,
                              style: layered.text(
                                theme.textTheme.caption.copyWith(color: words),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: bottom),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      )
      ..add(IterableProperty<BrutalDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected),
      );
  }
}

/// The column of an app's places at a tablet's side: square cells stacked
/// on shared rules, a rule down its end. The chosen cell is filled with
/// ink.
///
/// Reads [style]'s `fill` (a chosen or pressed cell's), `foreground` (in
/// each cell's states), `edge` (the rules), `textStyle` (the names) and
/// `iconSize`, then [BrutalThemeData.navigationRailStyle]'s.
///
/// ```dart
/// BrutalNavigationRail(destinations: places, selectedIndex: index, onSelected: (i) => setState(() => index = i))
/// ```
class BrutalNavigationRail extends StatelessWidget {
  /// A rail over [destinations].
  const BrutalNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.leading,
    this.style,
  });

  /// Its style, over [BrutalThemeData.navigationRailStyle].
  final BrutalStyle? style;

  /// The places.
  final List<BrutalDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// What stands over the cells: the app's mark.
  final Widget? leading;

  /// The rail's width, without its rule.
  static const double width = 88;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final pad = MediaQuery.paddingOf(context);
    final layers = [style, theme.navigationRailStyle];
    final frame = DesignStyleOf(layers, const {});
    final rule = frame.side?.color ?? frame.edge;
    return ColoredBox(
      color: theme.colors.paper,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: width,
            // Places that outgrow a short window scroll, never spill.
            child: SingleChildScrollView(
              primary: false,
              padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: BrutalAppBar.height,
                    child: Center(child: leading),
                  ),
                  BrutalRule(color: rule),
                  for (final (i, d) in destinations.indexed) ...[
                    SizedBox(
                      height: 72,
                      child: _Cell(
                        key: d.key,
                        onPressed: () => onSelected(i),
                        chosen: i == selectedIndex,
                        semanticLabel: d.label,
                        layers: layers,
                        builder: (context, words, _, layered) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              d.icon,
                              size: layered.iconSize ?? 24,
                              color: words,
                            ),
                            const SizedBox(height: BrutalSpacing.tight),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  d.label.toUpperCase(),
                                  textScaler: _labelScaler(context),
                                  maxLines: 1,
                                  style: layered.text(
                                    theme.textTheme.caption.copyWith(
                                      color: words,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    BrutalRule(color: rule),
                  ],
                ],
              ),
            ),
          ),
          BrutalRule(vertical: true, color: rule),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      )
      ..add(IterableProperty<BrutalDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected),
      );
  }
}

/// The list of an app's places down a desktop's side: a header cell, then a
/// row for each place on a shared rule, a rule down its end. The chosen row
/// is filled with ink.
///
/// Reads [style]'s `fill` (a chosen or pressed cell's), `foreground` (in
/// each cell's states), `edge` (the rules), `textStyle` (the names) and
/// `iconSize`, then [BrutalThemeData.sideNavigationStyle]'s.
///
/// ```dart
/// BrutalSideNavigation(header: const Text('ADMIT'), destinations: places, selectedIndex: index, onSelected: (i) => setState(() => index = i))
/// ```
class BrutalSideNavigation extends StatelessWidget {
  /// A side list over [destinations].
  const BrutalSideNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.header,
    this.footer,
    this.style,
  });

  /// Its style, over [BrutalThemeData.sideNavigationStyle].
  final BrutalStyle? style;

  /// The places.
  final List<BrutalDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int> onSelected;

  /// What stands in the top cell: the app's name.
  final Widget? header;

  /// What stands at the foot: the account.
  final Widget? footer;

  /// The list's width, without its rule.
  static const double width = 240;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final pad = MediaQuery.paddingOf(context);
    final layers = [style, theme.sideNavigationStyle];
    final frame = DesignStyleOf(layers, const {});
    final rule = frame.side?.color ?? frame.edge;
    return ColoredBox(
      color: theme.colors.paper,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: width,
            // Places that outgrow a short window scroll, never spill; the
            // footer keeps the foot while there is room.
            child: CustomScrollView(
              primary: false,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(top: pad.top),
                  sliver: SliverList.list(
                    addSemanticIndexes: false,
                    children: [
                      SizedBox(
                        height: BrutalAppBar.height,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BrutalSpacing.regular,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: DefaultTextStyle.merge(
                              style: theme.textTheme.title,
                              child: header ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                      BrutalRule(color: rule),
                      for (final (i, d) in destinations.indexed) ...[
                        SizedBox(
                          height: 52,
                          child: _Cell(
                            key: d.key,
                            onPressed: () => onSelected(i),
                            chosen: i == selectedIndex,
                            semanticLabel: d.label,
                            layers: layers,
                            builder: (context, words, _, layered) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BrutalSpacing.regular,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    d.icon,
                                    size: layered.iconSize ?? 20,
                                    color: words,
                                  ),
                                  const SizedBox(width: BrutalSpacing.medium),
                                  Expanded(
                                    child: DesignCapCenter(
                                      capHeightFactor: BrutalTheme.of(context)
                                          .capHeightFactor,
                                      child: Text(
                                        d.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: layered.text(
                                          theme.textTheme.label.copyWith(
                                            color: words,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        BrutalRule(color: rule),
                      ],
                    ],
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: pad.bottom),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (footer != null) ...[
                          BrutalRule(color: rule),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          BrutalRule(vertical: true, color: rule),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      )
      ..add(IterableProperty<BrutalDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected),
      );
  }
}

/// A screen with its places: under 600 px wide a [BrutalNavigationBar]
/// along the bottom, to 1024 a [BrutalNavigationRail], past it a
/// [BrutalSideNavigation]; [appBar] over [body] beside or above them, and
/// the screen's one [floatingButton] over the body's bottom end.
///
/// ```dart
/// BrutalScaffold(appBar: const BrutalAppBar(title: 'Home'), destinations: places, selectedIndex: 0, onSelected: (i) {}, body: const SizedBox.expand())
/// ```
class BrutalScaffold extends StatelessWidget {
  /// A screen of [body].
  const BrutalScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onSelected,
    this.brand,
    this.sideFooter,
    this.floatingButton,
  });

  /// The screen's content.
  final Widget body;

  /// The screen's one act, held over [body] at its bottom end the page's
  /// margin in (above the bar on a phone): usually a [BrutalFloatingButton].
  final Widget? floatingButton;

  /// The bar over it.
  final Widget? appBar;

  /// The app's places; none: no navigation.
  final List<BrutalDestination> destinations;

  /// The chosen place.
  final int selectedIndex;

  /// Called with the place chosen.
  final ValueChanged<int>? onSelected;

  /// The app's name, at the head of the rail and the side list.
  final Widget? brand;

  /// What stands at the foot of the side list.
  final Widget? sideFooter;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final places = destinations.isNotEmpty && onSelected != null;
    final under = places && width < 600;
    // The body is a semantics container of its own, so a navigator in it (a
    // router's shell) hides only what lies under its page, never the places
    // beside it or the bar over it.
    final content0 = MediaQuery.removePadding(
      context: context,
      removeTop: appBar != null,
      removeBottom: under,
      child: Semantics(container: true, child: body),
    );
    final fab = floatingButton;
    final margin = BrutalSpacing.pageMargin(width);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?appBar,
        Expanded(
          child: fab == null
              ? content0
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    content0,
                    PositionedDirectional(
                      end: margin,
                      bottom:
                          margin +
                          (under ? 0 : MediaQuery.paddingOf(context).bottom),
                      child: fab,
                    ),
                  ],
                ),
        ),
      ],
    );
    Widget content;
    if (!places) {
      content = column;
    } else if (width < 600) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: column),
          BrutalNavigationBar(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onSelected: onSelected!,
          ),
        ],
      );
    } else {
      final side = width >= 1024
          ? BrutalSideNavigation(
              header: brand,
              footer: sideFooter,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected!,
            )
          : BrutalNavigationRail(
              leading: brand,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: onSelected!,
            );
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          side,
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: true,
              removeRight: true,
              child: column,
            ),
          ),
        ],
      );
    }
    return ColoredBox(color: theme.colors.paper, child: content);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalDestination>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected),
      );
  }
}

/// A row of tabs over a view: cells on full-height rules over a rule across.
/// The chosen tab stands on a heavy ink bar and reads in bold ink; the
/// others are muted. Below 600 px the cells span the row; wider, each takes
/// its words' width and the rule runs on.
///
/// Left and Right move the choice.
///
/// Reads [style]'s `fill` (a pressed tab's), `foreground` (in each tab's
/// states: selected while chosen), `edge` (the rules and the chosen tab's
/// bar), `padding` and `textStyle`, then [BrutalThemeData.tabBarStyle]'s.
///
/// ```dart
/// BrutalTabBar(tabs: const ['Upcoming', 'Past'], selectedIndex: index, onSelected: (i) => setState(() => index = i))
/// ```
class BrutalTabBar extends StatelessWidget {
  /// Tabs reading [tabs].
  const BrutalTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.expand,
    this.style,
  });

  /// Its style, over [BrutalThemeData.tabBarStyle].
  final BrutalStyle? style;

  /// The tabs' names.
  final List<String> tabs;

  /// The chosen tab.
  final int selectedIndex;

  /// Called with the tab chosen.
  final ValueChanged<int> onSelected;

  /// Whether the cells span the row; null: below 600 px they do.
  final bool? expand;

  /// The chosen tab's bar's height.
  static const double barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final wide = expand ?? MediaQuery.sizeOf(context).width < 600;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layers = [style, theme.tabBarStyle];
    final frame = DesignStyleOf(layers, const {});
    final rule = frame.side?.color ?? frame.edge;
    void move(int by) {
      final next = (selectedIndex + by).clamp(0, tabs.length - 1);
      if (next != selectedIndex) onSelected(next);
    }

    Widget cell(int i) {
      final chosen = i == selectedIndex;
      return DesignPressable(
        onPressed: () => onSelected(i),
        tab: true,
        selected: chosen,
        semanticSelected: chosen,
        semanticLabel: tabs[i],
        excludeSemantics: true,
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _TabMove(
            rtl ? 1 : -1,
          ),
          const SingleActivator(LogicalKeyboardKey.arrowRight): _TabMove(
            rtl ? -1 : 1,
          ),
        },
        actions: {
          _TabMove: CallbackAction<_TabMove>(
            onInvoke: (intent) {
              move(intent.by);
              return null;
            },
          ),
        },
        builder: (context, states, _) {
          final layered = DesignStyleOf(layers, {
            ...states,
            if (chosen) WidgetState.selected,
          });
          final pressed = states.contains(WidgetState.pressed);
          final words =
              layered.foreground ??
              (pressed
                  ? c.onColor(layered.fill ?? c.ink)
                  : chosen
                  ? c.ink
                  : c.inkMuted);
          return AnimatedBrutalSurface(
            stiffness: BrutalMotion.colorStiffness,
            face: BrutalFace(
              fill: pressed
                  ? (layered.fill ?? c.ink)
                  : c.ink.withValues(alpha: 0),
              border: c.ink.withValues(alpha: 0),
              foreground: words,
              borderWidth: 0,
            ),
            child: CustomPaint(
              foregroundPainter: states.contains(WidgetState.focused)
                  ? BrutalInsetFocusPainter(pressed ? c.paper : c.ink)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                          layered.padding(Directionality.of(context)) ??
                          const EdgeInsets.symmetric(
                            horizontal: BrutalSpacing.regular,
                          ),
                      child: Center(
                        widthFactor: 1,
                        child: DesignCapCenter(
                          capHeightFactor: BrutalTheme.of(context)
                              .capHeightFactor,
                          child: Text(
                            tabs[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: layered.text(
                              theme.textTheme.label.copyWith(
                                color: words,
                                fontWeight: chosen
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Every tab keeps the bar's room, so the labels share a
                  // line whichever is chosen.
                  SizedBox(
                    height: BrutalTabBar.barHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TabBar(
                          on: chosen,
                          color: rule ?? c.ink,
                          rest: theme.borderWidth,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    final row = Row(
      mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) BrutalRule(vertical: true, color: rule),
          if (wide)
            Expanded(child: cell(i))
          else
            IntrinsicWidth(child: cell(i)),
        ],
      ],
    );
    return SizedBox(
      height: 48 + theme.borderWidth,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BrutalRule(color: rule),
          ),
          // Tabs that hug their words scroll sideways when more of them
          // than fit; tabs that fill share the width.
          if (wide)
            row
          else
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: row),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      )
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onSelected', onSelected))
      ..add(DiagnosticsProperty<bool>('expand', expand, defaultValue: null));
  }
}

class _TabMove extends Intent {
  const _TabMove(this.by);

  final int by;
}

/// The chosen tab's heavy bar, growing from the rule's height on the move
/// spring; an unchosen tab keeps the plain rule.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.on, required this.color, required this.rest});

  final bool on;
  final Color color;
  final double rest;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: on ? BrutalTabBar.barHeight : rest),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, h, _) => SizedBox(
        height: math.max(h, rest),
        child: ColoredBox(color: color),
      ),
    );
  }
}
