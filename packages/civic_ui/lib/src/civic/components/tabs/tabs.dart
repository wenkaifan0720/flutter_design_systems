import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../../internal/underline.dart';

/// Views of one thing, side by side over a rule: each a word, the current
/// one in bold ink standing on a bar in the action colour, the rest in the
/// action colour, underlined, as links are. A keyboard focus lays a tab on
/// the yellow plate over the ink bar. More tabs than fit scroll along.
///
/// ui_core's [DesignTabBar] under Civic's painting: the bar is one tab stop,
/// the arrow keys moving along it (mirrored right to left, Home and End to
/// the ends) and choosing the tab they reach; the chosen tab's bar and words
/// change on Civic's state spring, and the strip scrolls the tab into view.
/// A screen reader hears a tab bar of tabs, each with its place ("Tab 1 of
/// 3").
///
/// Reads [CivicStyle]'s foreground (a tab's name, by state: selected,
/// focused) and textStyle (the names): its `style:`, then
/// [CivicThemeData.tabStyle]. The selected tab's edges and the focus plate
/// are the look's.
///
/// ```dart
/// CivicTabBar(
///   tabs: const ['Details', 'Documents', 'History'],
///   selectedIndex: tab,
///   onTap: (i) => setState(() => tab = i),
/// )
/// ```
class CivicTabBar extends StatefulWidget {
  /// A tab bar.
  const CivicTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
    this.style,
  });

  /// The tabs' words.
  final List<String> tabs;

  /// The current tab.
  final int selectedIndex;

  /// Called with a tab's index when it is chosen (pressed, or reached with
  /// the arrow keys); null disables the bar.
  final ValueChanged<int>? onTap;

  /// Overrides for the tabs' look.
  final CivicStyle? style;

  @override
  State<CivicTabBar> createState() => _CivicTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onTap', onTap))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicTabBarState extends State<CivicTabBar>
    with TickerProviderStateMixin {
  late DesignTabController _controller = _make();

  DesignTabController _make() => DesignTabController(
    length: widget.tabs.length,
    initialIndex: widget.tabs.isEmpty
        ? 0
        : widget.selectedIndex.clamp(0, widget.tabs.length - 1),
    vsync: this,
    dampingRatio: CivicMotion.state.dampingRatio,
    stiffness: CivicMotion.state.stiffness,
  )..addListener(_chosen);

  // The bar chose a tab (a press, or the arrows reaching it): the caller's
  // to keep.
  void _chosen() {
    final i = _controller.index;
    if (i != widget.selectedIndex) widget.onTap?.call(i);
  }

  @override
  void didUpdateWidget(CivicTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabs.length != widget.tabs.length) {
      _controller
        ..removeListener(_chosen)
        ..dispose();
      _controller = _make();
    } else if (widget.selectedIndex != _controller.index &&
        widget.selectedIndex >= 0 &&
        widget.selectedIndex < widget.tabs.length) {
      _controller.animateTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_chosen)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final enabled = widget.onTap != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.rule)),
      ),
      child: DesignTabBar(
        controller: _controller,
        isScrollable: true,
        tabs: [
          for (final label in widget.tabs)
            DesignTab(label: label, enabled: enabled),
        ],
        tabBuilder: (context, tab, details) => Padding(
          padding: EdgeInsetsDirectional.only(
            end: details.index < details.count - 1 ? CivicSpacing.s4 : 0,
          ),
          child: _Tab(
            label: tab.label,
            states: details.states,
            selection: details.selection,
            style: widget.style,
          ),
        ),
      ),
    );
  }
}

// A tab's face: its words, the bar under the chosen one ([selection] of the
// way there) and the focus plate.
class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.states,
    required this.selection,
    required this.style,
  });

  final String label;
  final Set<WidgetState> states;
  final double selection;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final selected = states.contains(WidgetState.selected);
    final so = DesignStyleOf([style, t.tabStyle], states);
    final base = text.body.merge(so.textStyle);
    return CivicSpringValue(
      value: states.contains(WidgetState.focused) ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      builder: (context, focus, _) {
        final rest = so.foreground ?? (selected ? t.textPrimary : t.action);
        final ink = Color.lerp(rest, t.onFocus, focus)!;
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
          foregroundPainter: _Under(
            amount: selection * (1 - focus),
            color: t.action,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CivicMetrics.controlHeight + 4,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CivicSpacing.s16,
                vertical: CivicSpacing.s12,
              ),
              // The label's bold room, chosen or not: a tab keeps its width
              // as it is chosen (ui_core's strip does not lay the tabs out
              // again as one is), and the tabs beside it stand still.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: _boldWidth(context, label, base),
                ),
                // Across the room, at the tab's top as before: a label's
                // underline never lifts or drops it as the choice moves.
                child: Align(
                  alignment: Alignment.topCenter,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: CivicUnderlined(
                    style: base.copyWith(
                      color: ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      decoration: selected
                          ? TextDecoration.none
                          : TextDecoration.underline,
                      decorationColor: ink.withValues(
                        alpha: ink.a * (1 - focus),
                      ),
                    ),
                    child: Text(label),
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

// How wide [label] stands in bold, at the reader's text size.
double _boldWidth(BuildContext context, String label, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: style.copyWith(fontWeight: FontWeight.w700),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width.ceilToDouble();
}

class _Under extends CustomPainter {
  _Under({required this.amount, required this.color});

  final double amount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final a = amount.clamp(0.0, 1.0);
    if (a <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - CivicMetrics.bar,
        size.width,
        CivicMetrics.bar,
      ),
      Paint()..color = color.withValues(alpha: color.a * a),
    );
  }

  @override
  bool shouldRepaint(_Under old) => old.amount != amount || old.color != color;
}
