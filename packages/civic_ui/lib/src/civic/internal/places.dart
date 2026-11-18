import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'paint.dart';
import 'spring.dart';

// An app's places as Civic paints them: the band along a phone's foot, the
// rail down a tablet's start and the site's side navigation, each round its
// places, and a place's face in each. What CivicNavigationBar and
// CivicSideNavigation stand their own pressable places in, and what
// CivicShellFrame gives ui_core's DesignAdaptiveShell to paint with.

/// The size the bar's and the rail's place names set at, for the places
/// under it.
class CivicPlaceNames extends InheritedWidget {
  /// [names] for [child]'s places.
  const CivicPlaceNames({super.key, required this.names, required super.child});

  /// The names' scale.
  final TextScaler names;

  /// The scale at [context]; the reader's own, at most 1.3 times, outside
  /// a band or a rail.
  static TextScaler of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CivicPlaceNames>()?.names ??
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

  @override
  bool updateShouldNotify(CivicPlaceNames oldWidget) =>
      oldWidget.names != names;
}

/// A bar place's name, as [CivicBarPlace] sets it.
TextStyle civicPlaceNameStyle(
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

/// The places' names all set at one size: the reader's text size, at most
/// 1.3 times (the bar keeps its height), and no larger than lets the
/// longest of [labels], in bold, fit a place's [share] of the bar.
TextScaler civicPlaceNames(
  BuildContext context,
  List<CivicStyle?> styles,
  List<String> labels,
  double share,
) {
  final asked = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
  if (!share.isFinite || labels.isEmpty) return asked;
  final style = civicPlaceNameStyle(context, styles, bold: true);
  final size = style.fontSize ?? 15;
  var factor = asked.scale(size) / size;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    if (painter.width > 0) factor = math.min(factor, share / painter.width);
    painter.dispose();
  }
  return TextScaler.linear(factor);
}

/// The band along a phone's foot under a hairline, [places] sharing its
/// width, their names at one size ([civicPlaceNames]).
class CivicPlacesBand extends StatelessWidget {
  /// The band of [places], named [labels].
  const CivicPlacesBand({
    super.key,
    required this.styles,
    required this.labels,
    required this.places,
    this.group,
  });

  /// The places' styles, the nearest first.
  final List<CivicStyle?> styles;

  /// The places' names.
  final List<String> labels;

  /// The places, pressable.
  final List<Widget> places;

  /// Round the places' row alone (ui_core's shell's tab bar, the act
  /// outside it), when given.
  final Widget Function(Widget places)? group;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final place in places) Expanded(child: place)],
    );
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: SizedBox(
            height: CivicChromeMetrics.navigationBar,
            child: LayoutBuilder(
              builder: (context, constraints) => CivicPlaceNames(
                names: civicPlaceNames(
                  context,
                  styles,
                  labels,
                  constraints.maxWidth / math.max(1, labels.length) -
                      2 * CivicSpacing.s4,
                ),
                child: group?.call(row) ?? row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rail down a tablet's start, on the card's face beside a hairline:
/// [lead] (an app's one act) over [places].
class CivicPlacesRail extends StatelessWidget {
  /// The rail of [places], named [labels].
  const CivicPlacesRail({
    super.key,
    required this.styles,
    required this.labels,
    required this.places,
    this.lead,
  });

  /// The places' styles, the nearest first.
  final List<CivicStyle?> styles;

  /// The places' names.
  final List<String> labels;

  /// The places, pressable.
  final List<Widget> places;

  /// What stands over the places.
  final Widget? lead;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final first = lead;
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
          child: CivicPlaceNames(
            names: civicPlaceNames(
              context,
              styles,
              labels,
              CivicChromeMetrics.navigationRail - 2 * CivicSpacing.s4,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: CivicSpacing.s12,
                bottom: CivicSpacing.s12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                children: [
                  if (first != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: CivicSpacing.s4,
                        bottom: CivicSpacing.s16,
                      ),
                      child: first,
                    ),
                  for (final place in places)
                    SizedBox(
                      height: CivicChromeMetrics.railPlace,
                      child: place,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The site's side navigation down the start of the page on its ground:
/// [header] over [places] over [footer].
class CivicPlacesSide extends StatelessWidget {
  /// The side navigation of [places].
  const CivicPlacesSide({
    super.key,
    required this.styles,
    required this.places,
    this.header,
    this.footer,
  });

  /// The places' styles, the nearest first.
  final List<CivicStyle?> styles;

  /// The places, pressable.
  final List<Widget> places;

  /// What stands above the places.
  final Widget? header;

  /// What stands below them.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
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
              ...places,
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
}

/// A place's face in the band or the rail ([rail]): its glyph over its
/// name, the current one in bold ink under (in the rail, beside) a bar in
/// the action colour; a press greys it, a keyboard focus lays it on the
/// yellow plate. Its names' size is the band's or the rail's
/// ([CivicPlaceNames]).
class CivicBarPlace extends StatelessWidget {
  /// The face of the place [label].
  const CivicBarPlace({
    super.key,
    required this.styles,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.states,
    required this.selected,
    this.rail = false,
  });

  /// The place's styles, the nearest first.
  final List<CivicStyle?> styles;

  /// Its glyph.
  final IconData icon;

  /// Its glyph while it is the current place.
  final IconData? selectedIcon;

  /// Its name.
  final String label;

  /// Its pressable states.
  final Set<WidgetState> states;

  /// Whether it is the current place.
  final bool selected;

  /// Whether it stands in the rail: its bar at its start, not over it.
  final bool rail;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final names = CivicPlaceNames.of(context);
    return CivicSpringValue(
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
                    ? const EdgeInsetsDirectional.only(start: CivicMetrics.edge)
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
                          selected ? selectedIcon ?? icon : icon,
                          size: 24,
                          color: ink,
                        ),
                        // A place's name is never cut: every name sets at
                        // the size the longest fits its share of the bar
                        // at, inside a gap from its neighbours.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicSpacing.s4,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              textScaler: names,
                              style: civicPlaceNameStyle(
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

/// A place's face in the side navigation: a row of words in ink, the
/// current one bold on a white face (by night, slate) with the inset rule
/// in the action colour at its start; a pointer over a place lays a paler
/// face under it, a press the whole face, a keyboard focus the yellow
/// plate.
class CivicSidePlace extends StatelessWidget {
  /// The face of the place [label].
  const CivicSidePlace({
    super.key,
    required this.styles,
    required this.label,
    required this.states,
    required this.selected,
  });

  /// The place's styles, the nearest first.
  final List<CivicStyle?> styles;

  /// Its name.
  final String label;

  /// Its pressable states.
  final Set<WidgetState> states;

  /// Whether it is the current place.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    return CivicSpringValue(
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
                  // The words start where the bar's do: the face's margin
                  // and its own room make the side navigation's inset.
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
                          label,
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
