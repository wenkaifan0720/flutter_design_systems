import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// Which of [pageCount] pages shows ([selectedIndex], from 0): a row of square marks,
/// the shown one a longer bar in ink, the others on the rule, then the
/// place in words ("2 of 5"), so no one has to count marks.
///
/// With [onPageChanged] each mark is a button (24 wide, 48 tall) that shows
/// its page: a pointer over one darkens it, a press darkens it further, a
/// keyboard focus lays it on the yellow plate over the ink bar. A screen
/// reader hears each as "Page 2 of 5", the shown one selected. Every
/// change moves on Civic's springs.
///
/// Reads [CivicStyle]'s fill (the shown mark) and foreground (the words):
/// its `style:`, then [CivicThemeData.pageDotsStyle].
///
/// ```dart
/// CivicPageDots(pageCount: 5, selectedIndex: 1, onPageChanged: (page) {})
/// ```
class CivicPageDots extends StatelessWidget {
  /// [pageCount] marks, [selectedIndex] shown.
  const CivicPageDots({
    super.key,
    required this.pageCount,
    required this.selectedIndex,
    this.onPageChanged,
    this.pageLabel,
    this.style,
  }) : assert(pageCount > 0, 'There is at least one page.');

  /// How many pages there are.
  final int pageCount;

  /// The page shown, from 0.
  final int selectedIndex;

  /// Shows a page by its index; null: the marks only say where the reader
  /// is.
  final ValueChanged<int>? onPageChanged;

  /// What a screen reader calls page `page` (from 1) of `count`; null:
  /// "Page 2 of 5".
  final String Function(int page, int count)? pageLabel;

  /// Overrides for these marks' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final words = RawWidgetsLocalizations.of(context);
    final so = DesignStyleOf([style, t.pageDotsStyle], const {});
    final at = selectedIndex.clamp(0, pageCount - 1);
    final change = onPageChanged;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CivicSpacing.s8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < pageCount; i++)
              RawButton(
                // The shown page's mark stays in reach of the keys; a press
                // on it changes nothing.
                onPressed: change == null
                    ? null
                    : () {
                        if (i != at) change(i);
                      },
                selected: i == at,
                semanticSelected: i == at,
                semanticLabel:
                    pageLabel?.call(i + 1, pageCount) ??
                    'Page ${i + 1} of $pageCount',
                excludeSemantics: true,
                mouseCursor: change == null
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                builder: (context, states, _) => _Mark(
                  states: states,
                  shown: i == at,
                  live: change != null,
                  fill: so.fill ?? t.textPrimary,
                ),
              ),
          ],
        ),
        ExcludeSemantics(
          child: Text(
            words.positionLabel(at + 1, pageCount),
            style: context.civicText.bodySmall.copyWith(
              color: so.foreground ?? t.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pageCount', pageCount))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onPageChanged',
          onPageChanged,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.states,
    required this.shown,
    required this.live,
    required this.fill,
  });

  final Set<WidgetState> states;
  final bool shown;
  final bool live;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final wash = states.contains(WidgetState.pressed)
        ? 1.0
        : states.contains(WidgetState.hovered)
        ? 0.5
        : 0.0;
    return CivicSpringValue(
      value: shown ? 1 : 0,
      spring: CivicMotion.state,
      builder: (context, on, _) => CivicSpringValue(
        value: wash,
        spring: CivicMotion.press,
        builder: (context, w, _) => CivicSpringValue(
          value: states.contains(WidgetState.focused) ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, focus, _) {
            final rest = Color.lerp(t.rule, t.textSecondary, w)!;
            final mark = Color.lerp(
              Color.lerp(rest, fill, on)!,
              t.onFocus,
              focus,
            )!;
            return SizedBox(
              // At least 24 wide when it is a button.
              width: 8 + 16 * on + (live ? 16 : 8),
              height: live ? CivicMetrics.controlHeight : 16,
              child: Center(
                child: CustomPaint(
                  painter: CivicFacePainter(
                    fill: t.focus.withValues(alpha: 0),
                    edgeColor: t.onFocus,
                    edgeHeight: 0,
                    press: 0,
                    focus: focus,
                    focusColor: t.focus,
                    barColor: t.focusBar,
                    outset: CivicMetrics.edge,
                  ),
                  // Room round the mark for the focus plate; a mark that
                  // only says where the reader is takes no focus.
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: live ? 8 : 4,
                    ),
                    child: SizedBox(
                      width: 8 + 16 * on,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: mark),
                      ),
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
