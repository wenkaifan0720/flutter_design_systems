/// How far through a form a person is, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../format.dart';
import '../../internal/face.dart';
import '../../theme.dart';

/// How far through a run of steps a person is (Payee, Amount, Review): each
/// step a numbered mark on one rule, a step done a disc of the ink with its
/// tick, the step at hand ringed in the ink round its figure, the steps to
/// come ringed in the light rule round theirs; the rule inked up to the
/// step at hand. Each step's name in the mono capitals under its mark (the
/// one at hand in the ink). A screen reader hears it as one line: "Step 2
/// of 3, Amount". The marks move in Ledger's one motion as [currentStep]
/// changes. On a phone with more steps than fit, the names under the marks
/// give way to the step at hand's name alone.
///
/// ```dart
/// LedgerStepProgress(steps: const ['Payee', 'Amount', 'Review'], currentStep: 1)
/// ```
class LedgerStepProgress extends StatelessWidget {
  /// [steps], [currentStep] the one at hand (from 0).
  const LedgerStepProgress({
    required this.steps,
    required this.currentStep,
    super.key,
  }) : assert(currentStep >= 0);

  /// The steps' names.
  final List<String> steps;

  /// The step at hand, from 0.
  final int currentStep;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('steps', steps))
      ..add(IntProperty('currentStep', currentStep));
  }

  @override
  Widget build(BuildContext context) {
    assert(steps.length > 1 && currentStep < steps.length);
    final t = context.ledgerTheme;
    return Semantics(
      container: true,
      label:
          'Step ${currentStep + 1} of ${steps.length}, ${steps[currentStep]}',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final each = box.maxWidth / steps.length;
          final named = each >= MediaQuery.textScalerOf(context).scale(_named);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LedgerSpacing.s8,
            children: [
              SizedBox(
                height: _mark,
                child: Stack(
                  children: [
                    // The rule from the first mark's middle to the last's,
                    // inked to the step at hand.
                    Positioned(
                      left: each / 2,
                      right: each / 2,
                      top: _mark / 2 - .5,
                      height: 1,
                      child: ColoredBox(color: t.border),
                    ),
                    PositionedDirectional(
                      start: each / 2,
                      top: _mark / 2 - 1,
                      height: 2,
                      width: (box.maxWidth - each),
                      child: LedgerEase(
                        value: currentStep / (steps.length - 1),
                        builder: (context, at, _) => FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: at.clamp(0.0, 1.0),
                          child: ColoredBox(color: t.textPrimary),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          Expanded(
                            child: Center(
                              child: _Mark(n: i + 1, at: i - currentStep),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (named)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      Expanded(
                        child: Text(
                          steps[i].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: (i == currentStep ? t.meta.medium : t.meta)
                              .colored(
                                i == currentStep
                                    ? t.textPrimary
                                    : i < currentStep
                                    ? t.textSecondary
                                    : t.textTertiary,
                              ),
                        ),
                      ),
                  ],
                )
              else
                Text(
                  '${LedgerFormat.isolated('${currentStep + 1} / ${steps.length}')} · ${steps[currentStep]}'
                      .toUpperCase(),
                  textAlign: TextAlign.center,
                  style: t.meta.medium.colored(t.textPrimary),
                ),
            ],
          );
        },
      ),
    );
  }

  static const double _mark = 28;
  static const double _named = 72;
}

/// One step's mark: done (at < 0), at hand (0) or to come (at > 0).
class _Mark extends StatelessWidget {
  const _Mark({required this.n, required this.at});

  final int n;
  final int at;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final done = at < 0;
    return LedgerFace(
      style: LedgerFaceStyle(
        ink: done
            ? t.surface
            : at == 0
            ? t.textPrimary
            : t.textTertiary,
        ground: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? t.textPrimary : t.surface,
          border: Border.all(
            color: at <= 0 ? t.textPrimary : t.border,
            width: at == 0 ? 1.5 : 1,
          ),
        ),
      ),
      builder: (context, s, _) => Container(
        width: LedgerStepProgress._mark,
        height: LedgerStepProgress._mark,
        alignment: Alignment.center,
        decoration: s.ground,
        child: done
            ? Icon(LucideIcons.check, size: 14, color: s.ink)
            : Text(
                '$n',
                textScaler: TextScaler.noScaling,
                style: t.meta.medium.colored(s.ink),
              ),
      ),
    );
  }
}
