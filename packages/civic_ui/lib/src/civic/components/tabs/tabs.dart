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
class CivicTabBar extends StatelessWidget {
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

  /// Called with a tab's index when it is pressed; null disables the bar.
  final ValueChanged<int>? onTap;

  /// Overrides for the tabs' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.rule)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          spacing: CivicSpacing.s4,
          children: [
            for (final (i, label) in tabs.indexed)
              _Tab(
                label: label,
                selected: i == selectedIndex,
                index: i,
                count: tabs.length,
                style: style,
                onPressed: onTap == null ? null : () => onTap!(i),
              ),
          ],
        ),
      ),
    );
  }

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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.index,
    required this.count,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final int index;
  final int count;
  final CivicStyle? style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    return DesignPressable(
      onPressed: onPressed,
      selected: selected,
      tab: true,
      button: false,
      semanticSelected: selected,
      semanticLabel: label,
      excludeSemantics: true,
      mouseCursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      builder: (context, states, _) {
        final so = DesignStyleOf([style, t.tabStyle], states);
        return CivicSpringValue(
          value: states.contains(WidgetState.focused) ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) => CivicSpringValue(
            value: selected ? 1 : 0,
            spring: CivicMotion.state,
            builder: (context, on, _) {
              final rest =
                  so.foreground ?? (selected ? t.textPrimary : t.action);
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
                  amount: on * (1 - focus),
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
                    child: CivicUnderlined(
                      style: text.body
                          .merge(so.textStyle)
                          .copyWith(
                            color: ink,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
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
              );
            },
          ),
        );
      },
    );
  }
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
