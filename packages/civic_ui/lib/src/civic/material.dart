/// Civic's material: the face a button wears (a square fill on a solid edge
/// a press sinks onto), the well a field is (a square fill inside an ink
/// edge), and the focus they share: the yellow plate over the ink bar on a
/// face, the doubled edge in a yellow ring on a well. Every Civic part is
/// drawn with them; they are public so an app's own part can wear the look.
///
/// The colours are the caller's; the edges' widths, the focus and the
/// springs that move them are the look's.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/paint.dart';
import 'internal/spring.dart';
import 'theme.dart';

export 'internal/paint.dart' show CivicMetrics;

/// A face round [child]: [fill] on a solid edge [edgeHeight] tall in
/// [edgeColor], which a press sinks onto. [focused] floods it to the theme's
/// yellow plate over a [CivicMetrics.bar]-thick ink bar; [pressed] sinks
/// it. Both move on Civic's press spring.
///
/// The face's size is its child's, the edge included: leave [edgeHeight]
/// of room under the child for it.
///
/// ```dart
/// CivicFace(
///   fill: context.civicTheme.action,
///   edgeColor: context.civicTheme.actionEdge,
///   edgeHeight: CivicMetrics.bar,
///   pressed: pressed,
///   focused: focused,
///   child: const Padding(
///     padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + CivicMetrics.bar),
///     child: Text('Continue'),
///   ),
/// )
/// ```
class CivicFace extends StatelessWidget {
  /// A face.
  const CivicFace({
    super.key,
    required this.fill,
    this.edgeColor,
    this.edgeHeight = 0,
    this.side,
    this.pressed = false,
    this.focused = false,
    this.child,
  });

  /// The face's fill at rest.
  final Color fill;

  /// The solid edge under it; null is the ink.
  final Color? edgeColor;

  /// The solid edge's height at rest; 0 for a face with none.
  final double edgeHeight;

  /// An edge round the face, inside its box: a secondary button's.
  final BorderSide? side;

  /// Whether it is pressed: the face sinks onto its edge.
  final bool pressed;

  /// Whether it holds the keyboard's focus: the yellow plate and the bar.
  final bool focused;

  /// What stands on the face.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return CivicSpringValue(
      value: pressed ? 1 : 0,
      spring: CivicMotion.press,
      builder: (context, press, _) => CivicSpringValue(
        value: focused ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) => CustomPaint(
          painter: CivicFacePainter(
            fill: fill,
            edgeColor: edgeColor ?? t.onFocus,
            edgeHeight: edgeHeight,
            press: press,
            focus: focus,
            focusColor: t.focus,
            barColor: t.focusBar,
            side: side,
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fill', fill))
      ..add(ColorProperty('edgeColor', edgeColor, defaultValue: null))
      ..add(DoubleProperty('edgeHeight', edgeHeight, defaultValue: 0))
      ..add(FlagProperty('pressed', value: pressed, ifTrue: 'pressed'))
      ..add(FlagProperty('focused', value: focused, ifTrue: 'focused'));
  }
}

/// A well round [child]: [fill] inside a [CivicMetrics.edge] edge in
/// [edgeColor], square, or round with [circle]. [focused] doubles the edge
/// in the ink and rings it in the theme's yellow, on Civic's press spring.
///
/// Leave [CivicMetrics.edge] of room inside it for the edge, and the ring's
/// [CivicMetrics.focusRing] outside it where a clip could cut it.
///
/// ```dart
/// CivicWell(
///   focused: focused,
///   child: const Padding(
///     padding: EdgeInsets.all(CivicMetrics.edge + 12),
///     child: Text('42'),
///   ),
/// )
/// ```
class CivicWell extends StatelessWidget {
  /// A well.
  const CivicWell({
    super.key,
    this.fill,
    this.edgeColor,
    this.focused = false,
    this.circle = false,
    this.child,
  });

  /// The well's fill; null is the page's.
  final Color? fill;

  /// Its edge at rest; null is the ink.
  final Color? edgeColor;

  /// Whether it holds the keyboard's focus: the doubled edge and the ring.
  final bool focused;

  /// Whether the well is round: a radio's.
  final bool circle;

  /// What stands in the well.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return CivicSpringValue(
      value: focused ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      child: child,
      builder: (context, focus, child) => CustomPaint(
        painter: CivicWellPainter(
          fill: fill ?? t.background,
          edgeColor: edgeColor ?? t.border,
          focus: focus,
          focusColor: t.focus,
          focusEdgeColor: t.border,
          circle: circle,
        ),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fill', fill, defaultValue: null))
      ..add(ColorProperty('edgeColor', edgeColor, defaultValue: null))
      ..add(FlagProperty('focused', value: focused, ifTrue: 'focused'))
      ..add(FlagProperty('circle', value: circle, ifTrue: 'round'));
  }
}
