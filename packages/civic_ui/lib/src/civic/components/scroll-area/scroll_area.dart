import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A region that scrolls inside the page (terms, a long list of
/// addresses), with a scrollbar a reader can always see and grab: a wide
/// square thumb in ink on a pale track along its end edge, shown whenever
/// there is more to scroll, never fading away. A pointer over the thumb
/// darkens it and a drag deepens it further; a drag along the track moves
/// the region.
///
/// With [focusable] (for a region with nothing focusable in it) the region
/// is a tab stop the arrow keys and Page Up and Page Down scroll, standing
/// in the yellow ring while the keyboard is on it. Its content then stands
/// 8 in from the region's edge, so the focus never touches the words. ui_core's
/// [RawScrollArea], Civic's painting.
///
/// Reads [CivicStyle]'s fill (the thumb, by state) and edge (the track):
/// its `style:`, then [CivicThemeData.scrollAreaStyle].
///
/// ```dart
/// CivicScrollArea(
///   controller: terms,
///   semanticLabel: 'Terms of the permit',
///   child: SingleChildScrollView(
///     controller: terms,
///     child: Text('The permit is for the vehicle named on it.'),
///   ),
/// )
/// ```
class CivicScrollArea extends StatelessWidget {
  /// [child], a scroll view on [controller], with Civic's scrollbar.
  const CivicScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.focusable = false,
    this.semanticLabel,
    this.style,
  });

  /// The scroll view's controller ([child] uses the same one).
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// The way it scrolls.
  final Axis axis;

  /// Whether the region is a tab stop the keys scroll (on for a region
  /// with nothing focusable in it).
  final bool focusable;

  /// What a screen reader calls the region.
  final String? semanticLabel;

  /// Overrides for this region's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return RawScrollArea(
      controller: controller,
      axis: axis,
      thickness: _thickness,
      minThumbLength: CivicMetrics.controlHeight,
      visibility: DesignScrollbarVisibility.always,
      focusable: focusable,
      semanticLabel: semanticLabel,
      trackBuilder: (context, thumb) {
        final so = DesignStyleOf([style, t.scrollAreaStyle], thumb.states);
        return ColoredBox(color: so.edge ?? t.surface);
      },
      thumbBuilder: (context, thumb) {
        final so = DesignStyleOf([style, t.scrollAreaStyle], thumb.states);
        final held = thumb.states.contains(WidgetState.pressed);
        final over = thumb.states.contains(WidgetState.hovered);
        return CivicSpringValue(
          value: held ? 1 : (over ? 0.5 : 0),
          spring: CivicMotion.press,
          builder: (context, w, _) => Padding(
            // The thumb stands clear of the track's sides, square.
            padding: const EdgeInsets.all(2),
            child: ColoredBox(
              color: so.fill ?? Color.lerp(t.textSecondary, t.textPrimary, w)!,
            ),
          ),
        );
      },
      frameBuilder: focusable
          ? (context, focused, area) => CivicSpringValue(
              value: focused ? 1 : 0,
              spring: CivicMotion.focus,
              effects: true,
              child: area,
              // The well's focus: an ink edge inside, the yellow ring
              // outside it, both over the region and never across it.
              builder: (context, focus, region) => DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: t.focus.withValues(alpha: focus),
                    width: CivicMetrics.focusRing,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: t.onFocus.withValues(alpha: focus),
                      width: CivicMetrics.edge,
                    ),
                  ),
                  // The edge stands outside the content's padding.
                  child: Padding(
                    padding: const EdgeInsets.all(
                      CivicMetrics.edge + CivicSpacing.s8,
                    ),
                    child: region,
                  ),
                ),
              ),
            )
          : null,
      child: child,
    );
  }

  static const double _thickness = 12;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Axis>('axis', axis, defaultValue: Axis.vertical))
      ..add(FlagProperty('focusable', value: focusable, ifTrue: 'focusable'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
