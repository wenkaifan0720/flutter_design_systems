import 'dart:math' as math;

import 'package:flutter/rendering.dart';
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

/// Bottom navigation that wraps destinations when their labels need more room.
class CivicPlacesBand extends StatelessWidget {
  /// The band of [places], named [labels].
  const CivicPlacesBand({
    super.key,
    required this.styles,
    required this.labels,
    required this.places,
    this.group,
    this.trailing,
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

  /// An action alongside the navigation, outside the group of destinations.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignStyleOf(styles, const {}).fill ?? t.background,
          border: Border(top: BorderSide(color: t.rule)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final style = civicPlaceNameStyle(
                      context,
                      styles,
                      bold: true,
                    );
                    final widths = [
                      for (final label in labels)
                        (_longestWord(context, label, style) +
                                2 * CivicSpacing.s4)
                            .clamp(48.0, math.max(48.0, width)),
                    ];
                    final rows = <Widget>[];
                    for (var first = 0; first < places.length;) {
                      var end = first + 1;
                      var used = widths[first];
                      while (end < places.length &&
                          used + widths[end] <= width) {
                        used += widths[end++];
                      }
                      final share = width / (end - first);
                      final equal = widths
                          .getRange(first, end)
                          .every((w) => w <= share);
                      rows.add(
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = first; i < end; i++)
                                Expanded(
                                  flex: equal ? 1 : widths[i].ceil(),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight:
                                          CivicChromeMetrics.navigationBar,
                                    ),
                                    child: places[i],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                      first = end;
                    }
                    final destinations = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: rows,
                    );
                    return group?.call(destinations) ?? destinations;
                  },
                ),
              ),
              ?trailing,
            ],
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
    final style = civicPlaceNameStyle(context, styles, bold: true);
    final maxWidth = MediaQuery.sizeOf(context).width / 3;
    final width = labels
        .fold<double>(
          CivicChromeMetrics.navigationRail,
          (w, label) => math.max(
            w,
            _longestWord(context, label, style) +
                2 * CivicSpacing.s4 +
                CivicMetrics.edge,
          ),
        )
        .clamp(
          CivicChromeMetrics.navigationRail,
          math.max(maxWidth, CivicChromeMetrics.navigationRail),
        )
        .toDouble();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignStyleOf(styles, const {}).fill ?? t.background,
          border: BorderDirectional(end: BorderSide(color: t.rule)),
        ),
        child: SizedBox(
          width: width,
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: CivicChromeMetrics.railPlace,
                    ),
                    child: place,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The site's side navigation down the start of the page on its ground:
/// [header] over [places] over [footer]. It is 240 wide, or as wide as its
/// words need at the reader's text size, to a third of the window: every
/// word of a place and of the header whole (they wrap by words), and the
/// footer (the app's act) on one line.
class CivicPlacesSide extends StatelessWidget {
  /// The side navigation of [places].
  const CivicPlacesSide({
    super.key,
    required this.styles,
    required this.places,
    this.header,
    this.footer,
    this.headerInset = CivicSpacing.s24,
  });

  /// The places' styles, the nearest first.
  final List<CivicStyle?> styles;

  /// The places, pressable.
  final List<Widget> places;

  /// Space above the header.
  final double headerInset;

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
        child: _WordsWide(
          least: CivicChromeMetrics.sideNavigation,
          most: MediaQuery.sizeOf(context).width / 3,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: headerInset,
              bottom: CivicSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    child: _WholeLine(child: foot),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Lays its child out as wide as its words need (its least intrinsic width:
// every word whole), from [least] to [most].
class _WordsWide extends SingleChildRenderObjectWidget {
  const _WordsWide({
    required this.least,
    required this.most,
    required super.child,
  });

  final double least;
  final double most;

  @override
  _RenderWordsWide createRenderObject(BuildContext context) =>
      _RenderWordsWide(least, most);

  @override
  void updateRenderObject(BuildContext context, _RenderWordsWide box) {
    box
      ..least = least
      ..most = most;
  }
}

class _RenderWordsWide extends RenderProxyBox {
  _RenderWordsWide(this._least, this._most);

  double get least => _least;
  double _least;
  set least(double value) {
    if (value == _least) return;
    _least = value;
    markNeedsLayout();
  }

  double get most => _most;
  double _most;
  set most(double value) {
    if (value == _most) return;
    _most = value;
    markNeedsLayout();
  }

  double _width() {
    // Whole pixels: the words' width up, the most down.
    final words = (child?.getMinIntrinsicWidth(double.infinity) ?? 0)
        .ceilToDouble();
    return math.max(least, math.min(words, most.floorToDouble()));
  }

  BoxConstraints _for(BoxConstraints constraints) =>
      BoxConstraints.tightFor(width: _width()).enforce(constraints);

  @override
  double computeMinIntrinsicWidth(double height) => _width();

  @override
  double computeMaxIntrinsicWidth(double height) => _width();

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      child?.getDryLayout(_for(constraints)) ?? _for(constraints).smallest;

  @override
  void performLayout() {
    final box = child;
    if (box == null) {
      size = _for(constraints).smallest;
      return;
    }
    box.layout(_for(constraints), parentUsesSize: true);
    size = box.size;
  }
}

// Its child, its least intrinsic width its whole line's: the side
// navigation widens for it to stand on one line.
class _WholeLine extends SingleChildRenderObjectWidget {
  const _WholeLine({required super.child});

  @override
  _RenderWholeLine createRenderObject(BuildContext context) =>
      _RenderWholeLine();
}

class _RenderWholeLine extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0;
}

/// A place's face in the band or the rail ([rail]): its glyph over its
/// name, the current one in bold ink over (in the rail, beside) a bar in
/// the action colour; a press greys it, a keyboard focus lays it on the
/// yellow plate. Labels use the reader's text size.
///
/// In the band the bar stands at the place's foot, under its name: at its
/// top it stood on the band's rule, against the page, and read as an
/// underline on whatever scrolled behind it.
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

  /// Whether it stands in the rail: its bar at its start, not under it.
  final bool rail;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
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
                barColor: t.focusBar,
              ),
              foregroundPainter: _PlaceBar(
                // The focus plate's ink bar says it while the keys are on it.
                amount: on * (1 - focus.clamp(0.0, 1.0)),
                color: so.edge ?? t.action,
                start: rail ? Directionality.of(context) : null,
              ),
              // A press greys the place under the band's rule, never over
              // it.
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
                          ? CivicSpacing.s8
                          : CivicSpacing.s8 - CivicMetrics.edge,
                      // In the band the bar has its own room under the name.
                      bottom: rail
                          ? CivicSpacing.s4
                          : CivicSpacing.s4 + CivicMetrics.bar,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicSpacing.s4,
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
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
class _PlaceBar extends CustomPainter {
  _PlaceBar({required this.amount, required this.color, this.start});

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
        Rect.fromLTWH(
          (size.width - w) / 2,
          size.height - CivicMetrics.bar,
          w,
          CivicMetrics.bar,
        ),
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
  bool shouldRepaint(_PlaceBar old) =>
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
                barColor: t.focusBar,
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
                        // Its longest word in bold, chosen or not: the
                        // side navigation, as wide as its words, keeps its
                        // width as the choice moves.
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: _longestWord(
                              context,
                              label,
                              text.body
                                  .merge(so.textStyle)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
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

// The widest word of [label] in [style], at the reader's text size.
double _longestWord(BuildContext context, String label, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
  )..layout();
  final width = painter.minIntrinsicWidth;
  painter.dispose();
  return width.ceilToDouble();
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
