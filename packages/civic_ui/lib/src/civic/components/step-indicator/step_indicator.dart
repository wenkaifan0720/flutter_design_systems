import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/spring.dart';
import '../../theme.dart';

/// Where a reader is in a form of several pages: "Step 2 of 5" over a band
/// of [steps]' segments, the steps done in the action colour, the
/// [currentStep] one in ink, those to come on the rule. From 600 wide each
/// segment has its step's words under it, the done ones ticked and the
/// current one bold; below 600 the count says the current step's words.
/// A change of step moves on Civic's springs.
///
/// It says where the reader is; it is not a way about the form (its back
/// link and task list are). A screen reader hears the count and the step
/// as one line.
///
/// Reads [CivicStyle]'s fill (the done segments) and foreground (the
/// count's words): its `style:`, then [CivicThemeData.stepIndicatorStyle].
///
/// ```dart
/// CivicStepIndicator(
///   steps: ['Your vehicle', 'Your details', 'Proof of address', 'Check'],
///   currentStep: 1,
/// )
/// ```
class CivicStepIndicator extends StatelessWidget {
  /// [steps] with the reader at [currentStep] (from 0).
  const CivicStepIndicator({
    super.key,
    required this.steps,
    required this.currentStep,
    this.countLabel,
    this.style,
  });

  /// Each step's words, in order.
  final List<String> steps;

  /// The reader's step, from 0.
  final int currentStep;

  /// The count's words for step `step` (from 1) of `count`; null: "Step 2
  /// of 5".
  final String Function(int step, int count)? countLabel;

  /// Overrides for this indicator's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.stepIndicatorStyle], const {});
    assert(steps.isNotEmpty, 'A form has at least one step.');
    final at = currentStep.clamp(0, steps.length - 1);
    final count =
        countLabel?.call(at + 1, steps.length) ??
        'Step ${at + 1} of ${steps.length}';
    final wide =
        (MediaQuery.maybeSizeOf(context)?.width ?? 1024) >= CivicLayout.medium;
    final line = wide ? count : '$count: ${steps[at]}';
    return Semantics(
      container: true,
      label: wide ? '$count: ${steps[at]}' : line,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s8,
        children: [
          Text(
            line,
            style: text.body.copyWith(color: so.foreground ?? t.textSecondary),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CivicSpacing.s4,
            children: [
              for (final (i, step) in steps.indexed)
                Expanded(
                  child: _Segment(
                    words: wide ? step : null,
                    done: i < at,
                    current: i == at,
                    fill: so.fill ?? t.action,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('steps', steps))
      ..add(IntProperty('currentStep', currentStep))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.words,
    required this.done,
    required this.current,
    required this.fill,
  });

  final String? words;
  final bool done;
  final bool current;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final label = words;
    return CivicSpringValue(
      value: done ? 1 : (current ? 0.5 : 0),
      spring: CivicMotion.state,
      builder: (context, v, _) {
        // To come, on the rule; the current step in ink; done, the action.
        final band = v <= 0.5
            ? Color.lerp(t.rule, t.textPrimary, v / 0.5)!
            : Color.lerp(t.textPrimary, fill, (v - 0.5) / 0.5)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: CivicSpacing.s8,
          children: [
            // The band spans the step's share of the row.
            SizedBox(
              width: double.infinity,
              height: 8,
              child: DecoratedBox(decoration: BoxDecoration(color: band)),
            ),
            if (label != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: CivicSpacing.s4,
                children: [
                  if (done)
                    Icon(
                      LucideIcons.check,
                      size: 18,
                      color: t.textPrimary,
                      applyTextScaling: true,
                    ),
                  Flexible(
                    child: Text(
                      label,
                      style: (current ? text.label : text.bodySmall).copyWith(
                        color: current || done
                            ? t.textPrimary
                            : t.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
