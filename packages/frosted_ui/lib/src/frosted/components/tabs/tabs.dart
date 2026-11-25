import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../../internal/panel.dart' show frostedRingFor;
import '../../localizations.dart';
import '../../internal/cap.dart';
import '../../internal/chosen_plate.dart';
import '../../internal/dim.dart';
import '../../internal/bleed.dart';

// How far past a scrolling strip's line its viewport stands.
const double _stripReach = FrostedChromeMetrics.stripReach;

/// In-page tabs: peer section labels as a row of pills 40 tall, the current
/// one on the sidebar's lit pill (white at 80% under the rim and the
/// hairline edge, its word in the 600 ink), the rest bare in the quieter
/// ink. A row too long for its width scrolls sideways; with [expand] the
/// tabs share the width instead (a few short ones). A null [onChanged]
/// shows the choice inert. ui_core's [RawTabBar] is the behaviour: the
/// row is one Tab stop, on the chosen tab; the arrows move along it
/// (mirrored right to left, wrapping), Home and End to its ends, choosing
/// as they go; a screen reader hears a tab bar named [label], each tab its
/// name and its place ("Income, tab 2 of 3"). DERIVED: the source has no
/// tab row; the sidebar's current row (`.nav.on`) lends the chosen tab its
/// face.
///
/// ```dart
/// FrostedTabBar(tabs: const ['Spending', 'Income', 'Transfers'], selectedIndex: tab, expand: true, onChanged: setTab)
/// ```
class FrostedTabBar extends StatefulWidget {
  /// Creates a [FrostedTabBar].
  const FrostedTabBar({
    required this.tabs,
    this.selectedIndex = 0,
    this.onChanged,
    this.label,
    this.expand = false,
    this.style,
    super.key,
  }) : assert(
         selectedIndex >= 0,
         'A tab bar\'s selected index is not negative.',
       );

  /// The labels, in order.
  final List<String> tabs;

  /// The current tab.
  final int selectedIndex;

  /// What choosing a tab does with its index; null makes the row inert.
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls the group.
  final String? label;

  /// Whether the tabs share the row's width rather than keeping their own.
  final bool expand;

  /// This bar's own style, over `FrostedThemeData.components.tabBar`: each
  /// tab's fill (selected for the chosen one), words, edge or side, overlay,
  /// shape, padding and least size, each per state.
  ///
  /// ```dart
  /// FrostedTabBar(
  ///   tabs: const ['Overview', 'Activity'],
  ///   selectedIndex: tab,
  ///   onChanged: setTab,
  ///   style: FrostedStyle(
  ///     fill: WidgetStateProperty.resolveWith(
  ///       (states) => states.contains(WidgetState.selected)
  ///           ? const Color(0xFFE8E6FF)
  ///           : null,
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  State<FrostedTabBar> createState() => _FrostedTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: 0))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('expand', value: expand, ifTrue: 'expand'))
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

class _FrostedTabBarState extends State<FrostedTabBar>
    with SingleTickerProviderStateMixin {
  late RawTabController _controller = _made();

  int get _shown => widget.tabs.isEmpty
      ? 0
      : widget.selectedIndex.clamp(0, widget.tabs.length - 1);

  RawTabController _made() => RawTabController(
    length: widget.tabs.length,
    initialIndex: _shown,
    vsync: this,
  )..addListener(_chosen);

  // A tab chosen in the bar (a press, an arrow): told to the caller, whose
  // selectedIndex comes back on the next build.
  void _chosen() {
    final i = _controller.index;
    if (i != _shown) widget.onChanged?.call(i);
  }

  @override
  void didUpdateWidget(FrostedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.length != oldWidget.tabs.length) {
      _controller.dispose();
      _controller = _made();
    } else if (_controller.index != _shown) {
      _controller.index = _shown;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? FrostedLocalizations.of(context).sections;
    final t = context.frostedTheme;
    final layers = FrostedStyleLayers(widget.style, t.components.tabBar);
    final cut = layers.cut(FrostedCorners.full);
    const height = FrostedChromeMetrics.tabHeight;
    final corner = FrostedStyleLayers.radiusOf(cut, height, height / 2);
    final inert = widget.onChanged == null;

    Widget draw(String name, Set<WidgetState> states) {
      final on = states.contains(WidgetState.selected);
      final s = layers.at(states);
      final (edge, edges) = s.edgeOf(
        on ? t.glass.edge : null,
        FrostedStrokes.regular,
      );
      return s.least(
        SizedBox(
          height: height,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(corner),
            shape: cut,
            // The chosen tab stands on the look's chosen plate: thicker,
            // brighter glass raised off the row.
            color: s.fill ?? (on ? FrostedChosenPlate.fillOf(t) : null),
            wash: s.overlay,
            edge: edge,
            edges: edges,
            sheen: on ? FrostedChosenPlate.lightOf(t) : null,
            shadows: on && s.side == null
                ? FrostedChosenPlate.shadowsOf(t)
                : const <BoxShadow>[],
            padding:
                s.padding?.resolve(Directionality.of(context)) ??
                const EdgeInsets.symmetric(
                  horizontal: FrostedChromeMetrics.tabInset,
                ),
            child: Center(
              child: FrostedEase<TextStyle>(
                value: s.words(
                  on
                      ? t.textTheme.labelLarge.c(FrostedChosenPlate.inkOf(t))
                      : t.textTheme.link,
                ),
                lerp: FrostedEase.words,
                builder: (context, words) => frostedCapCentred(
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: words,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final bar = RawTabBar(
      controller: _controller,
      semanticLabel: label,
      tabs: [
        for (final name in widget.tabs) RawTab(label: name, enabled: !inert),
      ],
      // The face is 40 tall; the tab stands in a row a target tall (the
      // floor, 40, or an app's higher one), so its tap reaches the box a
      // screen reader outlines rather than being cut at the face's 40.
      tabBuilder: (context, tab, details) => SizedBox(
        height: math.max(height, FrostedBreakpoints.hitTargetOf(context)),
        child: Center(
          widthFactor: 1,
          child: frostedRingFor(
            details.states,
            // An inert row shows its choice as it stands, undimmed.
            draw(tab.label, {...details.states}..remove(WidgetState.disabled)),
            radius: corner,
            shape: cut,
          ),
        ),
      ),
    );
    if (widget.expand) return bar;
    final across = FrostedBreakpoints.isWide(context)
        ? _stripReach
        : math.max(_stripReach, FrostedBreakpoints.gutter(context));
    // The strip scrolls within its line, but the chosen plate's lift and rim
    // and a tab's focus ring reach past the line: its viewport stands that
    // far out on every side, so it clips only what scrolls away, never the
    // plate (cut flat at the strip's start and foot). On a phone the strip
    // runs on under the page's gutters to the screen's edges, the gutter its
    // own padding: the first tab stands on the keyline at rest, and one
    // scrolled under a gutter is drawn, tapped and outlined there.
    return FrostedBleed(
      reach: _stripReach,
      across: across,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: across,
          vertical: _stripReach,
        ),
        child: bar,
      ),
    );
  }
}
