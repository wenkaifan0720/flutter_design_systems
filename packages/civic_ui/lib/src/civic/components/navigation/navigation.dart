import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/frame_scope.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// One place a [CivicNavigationBar] or a [CivicSideNavigation] goes.
@immutable
class CivicNavigationDestination {
  /// A destination called [label].
  const CivicNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.key,
  });

  /// Its glyph, in the [CivicNavigationBar] (the side navigation is words
  /// alone).
  final IconData icon;

  /// Its glyph while it is the current place; null keeps [icon].
  final IconData? selectedIcon;

  /// Its name, always shown.
  final String label;

  /// The key its control carries, so a test can find it and press it.
  final Key? key;
}

/// The places of a service in an app, along the bottom under a hairline:
/// each a glyph over its name (always shown: a glyph alone says too
/// little), the current one in bold ink under a bar in the action colour,
/// the rest in the secondary ink. A [CivicScaffold] from
/// [CivicLayout.medium] wide (a tablet) stands the same places down the
/// start as a rail, on the card's face beside a hairline, the current
/// one's bar at its start. On the site (from [CivicLayout.expanded] wide) a
/// page stands a [CivicSideNavigation] instead.
///
/// Reads [CivicStyle]'s fill (the band's ground), foreground (a place's
/// glyph and name, by its states: selected for the current one), edge (the
/// current place's bar) and textStyle (the names): its `style:`, then
/// [CivicThemeData.navigationStyle]. The names always show, and the focus
/// plate is the look's.
///
/// ```dart
/// CivicNavigationBar(
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   destinations: const [
///     CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
///     CivicNavigationDestination(icon: LucideIcons.fileText, label: 'Applications'),
///   ],
/// )
/// ```
class CivicNavigationBar extends StatelessWidget {
  /// The bottom navigation.
  const CivicNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
  });

  /// The places.
  final List<CivicNavigationDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with a place's index when it is pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// Overrides for these places' look.
  final CivicStyle? style;

  /// The bar's height, the safe area aside.
  static const double height = CivicChromeMetrics.navigationBar;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final styles = [style, t.navigationStyle];
    final bottom = MediaQuery.paddingOf(context).bottom;
    if (CivicRailScope.of(context)) {
      final lead = CivicRailScope.leadingOf(context);
      final names = _namesScaler(
        context,
        styles,
        CivicChromeMetrics.navigationRail - 2 * CivicSpacing.s4,
      );
      return Semantics(
        container: true,
        explicitChildNodes: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DesignStyleOf(styles, const {}).fill ?? t.background,
            border: BorderDirectional(end: BorderSide(color: t.rule)),
          ),
          child: SizedBox(
            width: CivicChromeMetrics.navigationRail,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: CivicSpacing.s12,
                bottom: CivicSpacing.s12 + bottom,
              ),
              child: Column(
                children: [
                  if (lead != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: CivicSpacing.s4,
                        bottom: CivicSpacing.s16,
                      ),
                      child: lead,
                    ),
                  for (final (i, d) in destinations.indexed)
                    SizedBox(
                      height: CivicChromeMetrics.railPlace,
                      child: _BarItem(
                        styles: styles,
                        destination: d,
                        selected: i == selectedIndex,
                        index: i,
                        count: destinations.length,
                        names: names,
                        rail: true,
                        onPressed: onDestinationSelected == null
                            ? null
                            : () => onDestinationSelected!(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignStyleOf(styles, const {}).fill ?? t.background,
          // A hairline over the places, as over an app's action foot: no
          // ink edge round the app's own chrome.
          border: Border(top: BorderSide(color: t.rule)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final names = _namesScaler(
                  context,
                  styles,
                  constraints.maxWidth / destinations.length -
                      2 * CivicSpacing.s4,
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, d) in destinations.indexed)
                      Expanded(
                        child: _BarItem(
                          styles: styles,
                          destination: d,
                          selected: i == selectedIndex,
                          index: i,
                          count: destinations.length,
                          names: names,
                          onPressed: onDestinationSelected == null
                              ? null
                              : () => onDestinationSelected!(i),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // The places' names all set at one size: the reader's text size, at most
  // 1.3 times (the bar keeps its height), and no larger than lets the
  // longest name, in bold, fit a place's [share] of the bar.
  TextScaler _namesScaler(
    BuildContext context,
    List<CivicStyle?> styles,
    double share,
  ) {
    final asked = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    if (!share.isFinite || destinations.isEmpty) return asked;
    final style = _nameStyle(context, styles, bold: true);
    final size = style.fontSize ?? 15;
    var factor = asked.scale(size) / size;
    for (final d in destinations) {
      final painter = TextPainter(
        text: TextSpan(text: d.label, style: style),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      if (painter.width > 0) {
        factor = math.min(factor, share / painter.width);
      }
      painter.dispose();
    }
    return TextScaler.linear(factor);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

// A bar place's name, as [_BarItem] sets it.
TextStyle _nameStyle(
  BuildContext context,
  List<CivicStyle?> styles, {
  required bool bold,
  Set<WidgetState> states = const {},
}) => context.civicText.bodySmall
    .merge(DesignStyleOf(styles, states).textStyle)
    .copyWith(
      fontSize: 15,
      height: 1.2,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.styles,
    required this.destination,
    required this.selected,
    required this.index,
    required this.count,
    required this.names,
    required this.onPressed,
    this.rail = false,
  });

  final List<CivicStyle?> styles;
  final CivicNavigationDestination destination;
  final bool selected;
  final int index;
  final int count;
  final TextScaler names;
  final VoidCallback? onPressed;

  /// Whether it stands in the rail: its bar at its start, not over it.
  final bool rail;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DesignPressable(
      key: destination.key,
      onPressed: onPressed,
      tab: true,
      button: false,
      semanticSelected: selected,
      semanticLabel: destination.label,
      excludeSemantics: true,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states, _) => CivicSpringValue(
        value: states.contains(WidgetState.focused) ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) => CivicSpringValue(
          // A press held on a place greys it, as a list row's.
          value: states.contains(WidgetState.pressed) ? 1 : 0,
          spring: CivicMotion.press,
          effects: true,
          builder: (context, held, _) => CivicSpringValue(
            value: selected ? 1 : 0,
            spring: CivicMotion.state,
            builder: (context, on, _) {
              final so = DesignStyleOf(styles, {
                ...states,
                if (selected) WidgetState.selected,
              });
              final ink = Color.lerp(
                so.foreground ??
                    Color.lerp(t.textSecondary, t.textPrimary, on.clamp(0, 1)),
                t.onFocus,
                focus,
              )!;
              return CustomPaint(
                painter: CivicFacePainter(
                  fill: t.focus.withValues(alpha: 0),
                  edgeColor: t.onFocus,
                  edgeHeight: 0,
                  press: 0,
                  focus: focus,
                  focusColor: t.focus,
                  barColor: t.onFocus,
                ),
                foregroundPainter: _TopBar(
                  amount: on,
                  color: so.edge ?? t.action,
                  start: rail ? Directionality.of(context) : null,
                ),
                // A press greys the place under the bar's ink rule, never
                // over it.
                child: Padding(
                  padding: rail
                      ? const EdgeInsetsDirectional.only(
                          start: CivicMetrics.edge,
                        )
                      : const EdgeInsets.only(top: CivicMetrics.edge),
                  child: ColoredBox(
                    color: Color.lerp(
                      t.surface,
                      t.rule,
                      0.5,
                    )!.withValues(alpha: held.clamp(0.0, 1.0) * (1 - focus)),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: rail
                            ? CivicSpacing.s4
                            : CivicSpacing.s4 - CivicMetrics.edge,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: CivicSpacing.s4,
                        children: [
                          Icon(
                            selected
                                ? destination.selectedIcon ?? destination.icon
                                : destination.icon,
                            size: 24,
                            color: ink,
                          ),
                          // A place's name is never cut: every name sets at the
                          // size the longest fits its share of the bar at, inside
                          // a gap from its neighbours.
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: CivicSpacing.s4,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                destination.label,
                                maxLines: 1,
                                softWrap: false,
                                textScaler: names,
                                style: _nameStyle(
                                  context,
                                  styles,
                                  bold: selected,
                                  states: {
                                    ...states,
                                    if (selected) WidgetState.selected,
                                  },
                                ).copyWith(color: ink),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The current place's bar: across the top of a place in the bottom bar,
/// down the [start] of one in the rail.
class _TopBar extends CustomPainter {
  _TopBar({required this.amount, required this.color, this.start});

  final double amount;
  final Color color;
  final TextDirection? start;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.clamp(0.0, 1.0);
    if (a <= 0) return;
    final paint = Paint()..color = color;
    final side = start;
    if (side == null) {
      final w = size.width * 0.6 * a;
      canvas.drawRect(
        Rect.fromLTWH((size.width - w) / 2, 0, w, CivicMetrics.bar),
        paint,
      );
      return;
    }
    final h = size.height * 0.6 * a;
    final x = side == TextDirection.rtl ? size.width - CivicMetrics.bar : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(x, (size.height - h) / 2, CivicMetrics.bar, h),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TopBar old) =>
      old.amount != amount || old.color != color || old.start != start;
}

/// The places of a service's site, down the start of the page on its
/// ground: each a row of words in ink, the current one bold on a white face
/// (by night, slate) with the inset rule in the action colour at its start;
/// a pointer over a place lays a paler face under it. Words alone: beside
/// a name this size a place's glyph would only decorate (the bar along a
/// phone's foot keeps them, over its small names). A [header] and a
/// [footer] may stand above and below the places.
///
/// Reads [CivicStyle]'s fill (the band's ground), foreground (a place's
/// name, by its states: selected for the current one), edge (the
/// current place's rule) and textStyle (the names): its `style:`, then
/// [CivicThemeData.navigationStyle]. The names always show, and the focus
/// plate is the look's.
///
/// ```dart
/// CivicSideNavigation(
///   selectedIndex: index,
///   onDestinationSelected: (i) => setState(() => index = i),
///   destinations: destinations,
/// )
/// ```
class CivicSideNavigation extends StatelessWidget {
  /// The side navigation.
  const CivicSideNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.footer,
    this.style,
  });

  /// The places.
  final List<CivicNavigationDestination> destinations;

  /// The current place.
  final int selectedIndex;

  /// Called with a place's index when it is pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// Overrides for these places' look.
  final CivicStyle? style;

  /// What stands above the places.
  final Widget? header;

  /// What stands below them.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final styles = [style, t.navigationStyle];
    final head = header;
    final foot = footer;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: DesignStyleOf(styles, const {}).fill ?? t.ground,
        child: SizedBox(
          width: CivicChromeMetrics.sideNavigation,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s24),
            children: [
              if (head != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CivicSpacing.s20,
                    0,
                    CivicSpacing.s20,
                    CivicSpacing.s16,
                  ),
                  child: head,
                ),
              for (final (i, d) in destinations.indexed)
                _SideItem(
                  styles: styles,
                  destination: d,
                  selected: i == selectedIndex,
                  onPressed: onDestinationSelected == null
                      ? null
                      : () => onDestinationSelected!(i),
                ),
              if (foot != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CivicSpacing.s20,
                    CivicSpacing.s16,
                    CivicSpacing.s20,
                    0,
                  ),
                  child: foot,
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
      ..add(IntProperty('destinations', destinations.length))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.styles,
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final List<CivicStyle?> styles;
  final CivicNavigationDestination destination;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    return DesignPressable(
      key: destination.key,
      onPressed: onPressed,
      link: true,
      button: false,
      semanticSelected: selected,
      semanticLabel: destination.label,
      excludeSemantics: true,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states, _) => CivicSpringValue(
        value: states.contains(WidgetState.focused) ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) {
          final so = DesignStyleOf(styles, {
            ...states,
            if (selected) WidgetState.selected,
          });
          // The current place stands on the card's face; a pointer over
          // another lays a paler one under it, a press the whole face.
          final held = states.contains(WidgetState.pressed);
          final over = states.contains(WidgetState.hovered);
          final face = t.background.withValues(
            alpha: selected || held ? 1 : (over ? 0.6 : 0),
          );
          final ink = Color.lerp(
            so.foreground ?? t.textPrimary,
            t.onFocus,
            focus,
          )!;
          final rule = selected ? CivicMetrics.insetRule : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CivicSpacing.s8,
              vertical: 2,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CivicMetrics.corner),
              child: CustomPaint(
                painter: CivicFacePainter(
                  fill: face,
                  edgeColor: t.onFocus,
                  edgeHeight: 0,
                  press: 0,
                  focus: focus,
                  focusColor: t.focus,
                  barColor: t.onFocus,
                ),
                foregroundPainter: _StartRule(
                  width: rule,
                  color: so.edge ?? t.action,
                  direction: Directionality.of(context),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: CivicMetrics.controlHeight,
                  ),
                  child: Padding(
                    // The words start where the bar's do: the face's margin and
                    // its own room make the side navigation's inset.
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      CivicLayout.sideNavigationInset - CivicSpacing.s8,
                      CivicSpacing.s8,
                      CivicSpacing.s8,
                      CivicSpacing.s8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            destination.label,
                            style: text.body
                                .merge(so.textStyle)
                                .copyWith(
                                  color: ink,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StartRule extends CustomPainter {
  _StartRule({
    required this.width,
    required this.color,
    required this.direction,
  });

  final double width;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;
    final x = direction == TextDirection.rtl ? size.width - width : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, width, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StartRule old) =>
      old.width != width || old.color != color || old.direction != direction;
}
