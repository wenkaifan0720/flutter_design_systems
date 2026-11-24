/// Studio's wayfinding: [StudioBreadcrumb] (the way here, printed on the
/// metal), [StudioPagination] (a page readout between two keys, as a track
/// selector), [StudioStepProgress] (lamps along an engraved line) and
/// [StudioPageDots] (a row of small lamps).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'internal/strip.dart';
import 'surface.dart';
import 'theme.dart';

/// One place in a [StudioBreadcrumb].
///
/// ```dart
/// StudioCrumb('Library', onPressed: () => go(library))
/// ```
@immutable
class StudioCrumb {
  /// A crumb reading [label]; [onPressed] goes there (null for where you
  /// are).
  const StudioCrumb(this.label, {this.onPressed});

  /// Its words.
  final String label;

  /// Goes there; null for the page you are on.
  final VoidCallback? onPressed;
}

/// The way here: each place printed in the legend's ink, a small engraved
/// chevron between them, the last (where you are) heavier and not a key.
/// A place you can go back to sinks a recess under its words when pressed.
///
/// Reads [style]'s `foreground` and `textStyle`, then
/// [StudioThemeData.breadcrumbStyle].
///
/// ```dart
/// StudioBreadcrumb(crumbs: [StudioCrumb('Library', onPressed: back), const StudioCrumb('Season 2')])
/// ```
class StudioBreadcrumb extends StatelessWidget {
  /// A breadcrumb over [crumbs].
  const StudioBreadcrumb({super.key, required this.crumbs, this.style});

  /// The places, first to last.
  final List<StudioCrumb> crumbs;

  /// Its style, over [StudioThemeData.breadcrumbStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: StudioSpacing.tight,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Transform.flip(
                  flipX: rtl,
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: StudioIconSizes.small,
                    color: c.legendMuted,
                  ),
                ),
              ),
            if (i == crumbs.length - 1 || crumb.onPressed == null)
              Semantics(
                // The page you are on.
                selected: i == crumbs.length - 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.hair,
                  ),
                  child: Text(
                    crumb.label,
                    style:
                        RawStyleOf(
                          [style, theme.breadcrumbStyle],
                          const {WidgetState.selected},
                        ).text(
                          theme.textTheme.secondary.copyWith(
                            color: c.legend,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
              )
            else
              RawButton(
                onPressed: crumb.onPressed,
                semanticLabel: crumb.label,
                excludeSemantics: true,
                link: true,
                builder: (context, states, _) {
                  final layered = RawStyleOf([
                    style,
                    theme.breadcrumbStyle,
                  ], states);
                  return TapTargetPadding(
                    child: AnimatedStudioSurface(
                      face: c.recessFace.copyWith(
                        radius: StudioRadii.small,
                        presence: states.contains(WidgetState.pressed) ? 1 : 0,
                        focus: states.contains(WidgetState.focused)
                            ? c.focusRing
                            : c.focusRing.withValues(alpha: 0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: StudioSpacing.hair,
                        ),
                        child: Text(
                          crumb.label,
                          style: layered.text(
                            theme.textTheme.secondary.copyWith(
                              color: layered.foreground ?? c.legendMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('crumbs', crumbs.length));
  }
}

/// Pages, as a player picks a track: a key back, the page and the count in
/// a readout (`03 / 12`), a key on. A key at an end goes dark.
///
/// [page] counts from 1. A null [onChanged] disables it.
///
/// ```dart
/// StudioPagination(page: page, pageCount: 12, onChanged: (p) => setState(() => page = p))
/// ```
class StudioPagination extends StatelessWidget {
  /// Pages at [page] of [pageCount].
  const StudioPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.semanticLabel = 'Page',
  }) : assert(pageCount > 0),
       assert(page >= 1 && page <= pageCount);

  /// The page shown, from 1.
  final int page;

  /// How many pages there are.
  final int pageCount;

  /// Called with the page to show; null disables it.
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls the readout.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final change = onChanged;
    final width = '$pageCount'.length.clamp(2, 4);
    // Zero-padded figures in the reader's digits, ungrouped.
    String two(int n) => [
      for (final d in n.toString().padLeft(width, '0').codeUnits)
        words.formatDecimal(d - 0x30),
    ].join();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return StudioStrip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudioIconButton(
            icon: Transform.flip(
              flipX: rtl,
              child: const Icon(LucideIcons.skipBack),
            ),
            tooltip: words.previousPageTooltip,
            onPressed: change != null && page > 1
                ? () => change(page - 1)
                : null,
          ),
          const SizedBox(width: StudioSpacing.small),
          Semantics(
            label: semanticLabel,
            value: words.positionLabel(page, pageCount),
            liveRegion: true,
            excludeSemantics: true,
            child: StudioReadout(
              '${two(page)} / ${two(pageCount)}',
              minWidth: 96,
            ),
          ),
          const SizedBox(width: StudioSpacing.small),
          StudioIconButton(
            icon: Transform.flip(
              flipX: rtl,
              child: const Icon(LucideIcons.skipForward),
            ),
            tooltip: words.nextPageTooltip,
            onPressed: change != null && page < pageCount
                ? () => change(page + 1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('page', page))
      ..add(IntProperty('pageCount', pageCount));
  }
}

/// Steps along an engraved line, each a lamp with its name printed under
/// it: the steps done lit, the [currentStep] one lit with a ring round it and
/// its name heavier, the ones to come dark. Read to a screen reader as
/// "Step 2 of 3, Details".
///
/// ```dart
/// StudioStepProgress(steps: const ['Record', 'Edit', 'Publish'], currentStep: 1)
/// ```
class StudioStepProgress extends StatelessWidget {
  /// Progress through [steps], at [currentStep] (from 0).
  const StudioStepProgress({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  /// The steps' names, in order.
  final List<String> steps;

  /// The step you are on, from 0.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    assert(steps.length > 1, 'A step progress has two steps or more.');
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Semantics(
      container: true,
      label:
          'Step ${currentStep + 1} of ${steps.length}, '
          '${steps[currentStep.clamp(0, steps.length - 1)]}',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final n = steps.length;
          return Stack(
            children: [
              // The engraved line from the first lamp to the last, lit as
              // far as the current step.
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: (n - 1) / n,
                  child: Stack(
                    children: [
                      Container(height: 2, color: c.groove),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(top: StudioSpacing.hair),
                        color: c.edgeLight,
                      ),
                      FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: (currentStep / (n - 1)).clamp(0.0, 1.0),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: c.indicator,
                            boxShadow: [
                              BoxShadow(
                                color: c.indicator.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, name) in steps.indexed)
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: i == currentStep
                                        ? c.indicator.withValues(alpha: 0.7)
                                        : c.indicator.withValues(alpha: 0),
                                    width: 1.5,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    StudioMetrics.lip,
                                  ),
                                  child: StudioLamp(
                                    on: i <= currentStep,
                                    size: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: StudioSpacing.small),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.caption.copyWith(
                              color: i <= currentStep
                                  ? c.legend
                                  : c.legendMuted,
                              fontWeight: i == currentStep
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('steps', steps))
      ..add(IntProperty('current', currentStep));
  }
}

/// Where you are among pages: a row of small lamps, the current one lit.
/// Given [onChanged], each lamp is a key (a 44 target round it) that goes
/// to its page.
///
/// ```dart
/// StudioPageDots(count: 4, index: page, onChanged: goTo)
/// ```
class StudioPageDots extends StatelessWidget {
  /// [count] lamps, [index] lit.
  const StudioPageDots({
    super.key,
    required this.count,
    required this.index,
    this.onChanged,
  });

  /// How many pages.
  final int count;

  /// The page shown, from 0.
  final int index;

  /// Goes to a page; null makes the lamps a readout only.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final change = onChanged;
    return Semantics(
      container: true,
      value: words.positionLabel(index + 1, count),
      excludeSemantics: change == null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            change == null
                ? Padding(
                    padding: const EdgeInsets.all(StudioSpacing.tight + 2),
                    child: StudioLamp(on: i == index, size: 8),
                  )
                : RawButton(
                    onPressed: () => change(i),
                    semanticLabel: words.positionLabel(i + 1, count),
                    selected: i == index,
                    semanticSelected: i == index,
                    builder: (context, states, _) {
                      final c = StudioTheme.of(context).colors;
                      return TapTargetPadding(
                        child: Container(
                          padding: const EdgeInsets.all(StudioSpacing.tight),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: states.contains(WidgetState.focused)
                                  ? c.focusRing
                                  : c.focusRing.withValues(alpha: 0),
                              width: 2,
                            ),
                          ),
                          child: StudioLamp(on: i == index, size: 8),
                        ),
                      );
                    },
                  ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('index', index));
  }
}
