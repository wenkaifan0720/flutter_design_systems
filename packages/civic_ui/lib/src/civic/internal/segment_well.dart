import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../material.dart';
import '../theme.dart';
import 'spring.dart';

/// One segment of a typed date or time (the day, the hour): its figures,
/// or its placeholder in the hint's grey, and, while it takes the typing,
/// the yellow plate behind it, as a selection. Every segment stands the
/// same gap from the text either side of it, the gap that brings two
/// figures to a finger's target, so "24 / 2026" spaces as "11 / 24" does.
/// Plumbing of the date and time inputs.
class CivicDateSegment extends StatelessWidget {
  /// A segment.
  const CivicDateSegment({super.key, required this.details});

  /// What the field gives the segment.
  final DesignDateSegmentDetails details;

  /// The room either side of a segment's figures in [style]: what brings two
  /// figures up to the tap floor's width, and never less than 4.
  static double gapFor(BuildContext context, TextStyle style) {
    final floor = DesignTapTargets.of(context).floorOn().width;
    final zero = DesignLocalizations.of(context).formatDecimal(0);
    final painter = TextPainter(
      text: TextSpan(text: '$zero$zero', style: style),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final two = painter.width;
    painter.dispose();
    return math.max(4, (floor - two) / 2).floorToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final focused = details.states.contains(WidgetState.focused);
    final disabled = details.states.contains(WidgetState.disabled);
    final ink = disabled
        ? t.textDisabled
        : details.isPlaceholder
        ? t.textSecondary
        : t.textPrimary;
    final style = text.body.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final gap = gapFor(context, style);
    return DesignTapTarget(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gap - 2),
        child: CivicSpringValue(
          value: focused ? 1 : 0,
          spring: CivicMotion.focus,
          effects: true,
          builder: (context, f, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: t.focus.withValues(alpha: t.focus.a * f),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                details.text,
                style: style.copyWith(color: Color.lerp(ink, t.onFocus, f)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The text between a date's or a time's segments, in the hint's grey.
Widget civicSegmentLiteral(BuildContext context, String literal) => Text(
  literal,
  style: context.civicText.body.copyWith(
    color: context.civicTheme.textSecondary,
  ),
);

/// The well a typed date or time stands in: the field's square well, its
/// edge doubled and ringed in yellow while a segment takes the typing, in
/// the error colour on an error.
Widget civicSegmentWell(
  BuildContext context,
  Set<WidgetState> states,
  Widget segments, {
  List<DesignStyle?> styles = const [],
  bool isError = false,
}) {
  final t = context.civicTheme;
  final so = DesignStyleOf(styles, states);
  final disabled = states.contains(WidgetState.disabled);
  final error = isError || states.contains(WidgetState.error);
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: CivicMetrics.controlHeight),
    child: CivicWell(
      fill: so.fill ?? (disabled ? t.disabledFill : t.background),
      edgeColor:
          so.edge ??
          (error
              ? t.danger
              : disabled
              ? t.textDisabled
              : t.border),
      focused: states.contains(WidgetState.focused),
      // A text field's measures: 48 high with its edge, the figures 12 in.
      child: Padding(
        // The first and last segments bring their own gap.
        padding: const EdgeInsets.symmetric(
          horizontal: CivicMetrics.edge + CivicSpacing.s4,
          vertical: CivicMetrics.edge,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CivicMetrics.controlHeight - 2 * CivicMetrics.edge,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: segments,
          ),
        ),
      ),
    ),
  );
}
