/// Where a reader is in a run of pages or steps: pagination, page dots and
/// a step progress.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'icon_button.dart';
import 'pressable.dart';

/// The page numbers a pagination shows for [page] of [count] (both from
/// 0): the first, the last, [page] and [siblings] either side, with null
/// for every gap the ellipsis stands in.
List<int?> _pages(int page, int count, int siblings) {
  final shown = <int>{0, count - 1};
  for (var i = page - siblings; i <= page + siblings; i++) {
    if (i >= 0 && i < count) shown.add(i);
  }
  final sorted = shown.toList()..sort();
  final out = <int?>[];
  for (var i = 0; i < sorted.length; i++) {
    if (i > 0 && sorted[i] - sorted[i - 1] > 1) {
      // A gap of one page shows that page rather than an ellipsis.
      if (sorted[i] - sorted[i - 1] == 2) {
        out.add(sorted[i] - 1);
      } else {
        out.add(null);
      }
    }
    out.add(sorted[i]);
  }
  return out;
}

/// The way through a long list split into pages — a table's rows, search
/// results: Previous, the page numbers (the first, the last and the
/// current one's neighbours, an ellipsis for each gap) and Next. Each
/// number is a 32 px square on the `shapes.small` step in mono; the current
/// page stands on the surface inside the control edge, the rest are bare.
/// Under 360 px it folds to "Page 3 of 12" between the two arrows.
///
/// [page] counts from 0. Each control keeps a 44 px target, and its press
/// wash and focus ring take its own square.
///
/// ```dart
/// MinimalPagination(page: page, pageCount: 12, onPageChanged: (p) => setState(() => page = p))
/// ```
class MinimalPagination extends StatelessWidget {
  /// A pager over [pageCount] pages.
  const MinimalPagination({
    super.key,
    required this.page,
    required this.pageCount,
    this.onPageChanged,
    this.siblings = 1,
  }) : assert(pageCount > 0);

  /// The current page, from 0.
  final int page;

  /// How many pages there are.
  final int pageCount;

  /// Null shows the place without letting it move.
  final ValueChanged<int>? onPageChanged;

  /// The pages shown either side of the current one.
  final int siblings;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final l = MinimalLocalizations.of(context);
    final change = onPageChanged;
    final current = page.clamp(0, pageCount - 1);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = MinimalIconButton(
      rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
      variant: MinimalIconButtonVariant.ghost,
      label: l.previousPage,
      onPressed: change == null || current == 0
          ? null
          : () => change(current - 1),
    );
    final on = MinimalIconButton(
      rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      variant: MinimalIconButtonVariant.ghost,
      label: l.nextPage,
      onPressed: change == null || current == pageCount - 1
          ? null
          : () => change(current + 1),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth < 360) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                back,
                // Large text in a narrow column wraps between the arrows.
                Flexible(
                  child: Padding(
                    padding: MinimalInsets.horizontal12,
                    child: minimalCapLabel(
                      Text(
                        l.pageOf(current + 1, pageCount),
                        textAlign: TextAlign.center,
                        style: t.bodySmall.c(t.mutedForeground),
                      ),
                    ),
                  ),
                ),
                on,
              ],
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              back,
              const MinimalGap(MinimalSpacing.s4),
              for (final p in _pages(current, pageCount, siblings)) ...[
                if (p == null)
                  // Three dots on the figures' middle, not a full stop's
                  // baseline: the gap reads on the numbers' line.
                  const SizedBox(
                    width: MinimalChromeMetrics.control,
                    child: ExcludeSemantics(
                      child: Center(
                        child: MinimalIcon(
                          LucideIcons.ellipsis,
                          size: MinimalIconSize.i16,
                        ),
                      ),
                    ),
                  )
                else
                  _PageCell(
                    number: p + 1,
                    current: p == current,
                    label: l.pageOf(p + 1, pageCount),
                    onPressed: change == null ? null : () => change(p),
                  ),
                const MinimalGap(MinimalSpacing.s2),
              ],
              const MinimalGap(MinimalSpacing.s2),
              on,
            ],
          );
        },
      ),
    );
  }
}

class _PageCell extends StatelessWidget {
  const _PageCell({
    required this.number,
    required this.current,
    required this.label,
    required this.onPressed,
  });

  final int number;
  final bool current;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shape = t.shapes.small;
    final size = t.density.height(MinimalChromeMetrics.control);
    // The current page is no control (pressing it would go nowhere), so the
    // pressable hands back its bare face; its own node still says which page
    // this is and that it is the current one.
    final cell = MinimalPressable(
      onPressed: current ? null : onPressed,
      selected: current,
      shape: shape,
      semanticLabel: label,
      child: Container(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        padding: const EdgeInsets.symmetric(horizontal: MinimalSpacing.s4),
        alignment: Alignment.center,
        decoration: minimalFrame(
          shape,
          fill: current ? t.card : null,
          side: current
              ? BorderSide(color: t.input, width: t.rim)
              : BorderSide.none,
        ),
        child: ExcludeSemantics(
          child: minimalCapLabel(
            Text(
              '$number',
              style: (current ? t.mono.semibold : t.mono).c(
                current ? t.foreground : t.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
    if (!current) return cell;
    return Semantics(
      container: true,
      button: true,
      selected: true,
      label: label,
      child: cell,
    );
  }
}

/// Which of a few pages a carousel or an onboarding run stands on: a dot
/// for each, the current one drawn long in the ink, the rest small on the
/// control edge's ink (3:1 on the ground) — a capsule role, so the dots
/// follow `shapes.pill`. The
/// current dot grows into place in [MinimalMotion.base]. With
/// [onChanged] each dot is a control that jumps to its page.
///
/// ```dart
/// MinimalPageDots(count: 4, selectedIndex: page, onChanged: controller.jumpToPage)
/// ```
class MinimalPageDots extends StatelessWidget {
  /// A dot for each of [count] pages.
  const MinimalPageDots({
    super.key,
    required this.count,
    required this.selectedIndex,
    this.onChanged,
    this.position,
  });

  /// How many pages there are.
  final int count;

  /// The current page, from 0.
  final int selectedIndex;

  /// Reports the dot pressed; null leaves the dots still.
  final ValueChanged<int>? onChanged;

  /// Where the pages are while they move, in pages (1.5 is half way from the
  /// second to the third; past the last it runs on toward the first), so the
  /// long dot travels with a swipe instead of jumping when it ends. Null: the
  /// dots ease to [selectedIndex] when it changes.
  final double? position;

  static const double _dot = 6;
  static const double _long = 18;
  static const double _cell = 16;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final l = MinimalLocalizations.of(context);
    final at = position;
    // Followed frame by frame, the dots must not ease after it as well.
    final duration = context.minimalStill || at != null
        ? Duration.zero
        : MinimalMotion.base;
    final shape = t.shapes.pill;
    final press = onChanged;
    // How much of the current page's long dot dot [i] wears: whole on the
    // page, none a page away, measured round the ring (the last page's
    // neighbour on the far side is the first).
    double share(int i) {
      if (at == null) return i == selectedIndex ? 1 : 0;
      final d = (i - at).abs();
      return math.max(0.0, 1 - math.min(d, count - d));
    }

    return Semantics(
      container: true,
      label: l.pageOf(selectedIndex + 1, count),
      child: MinimalHitTarget(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              _OwnSides(
                child: MinimalPressable(
                  onPressed: press == null || i == selectedIndex
                      ? null
                      : () => press(i),
                  focusable: press != null,
                  shape: shape,
                  semanticLabel: l.pageOf(i + 1, count),
                  child: SizedBox(
                    height: _cell,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MinimalSpacing.s4,
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: duration,
                          curve: MinimalMotion.out,
                          width: _dot + (_long - _dot) * share(i),
                          height: _dot,
                          decoration: minimalFrame(
                            shape,
                            // The other pages on the control edge's ink,
                            // 3:1 on the ground: a hairline's grey would
                            // all but vanish.
                            fill: Color.lerp(t.input, t.foreground, share(i)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Takes a point only between its own sides, at any height. The dots stand
/// edge to edge, narrower than a touch target, so one dot's 44 px margin
/// would reach into the next and take its taps; this keeps each tap on the
/// dot under it, while the row's [MinimalHitTarget] still pads the ends and
/// the height.
class _OwnSides extends SingleChildRenderObjectWidget {
  const _OwnSides({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOwnSides();
}

class _RenderOwnSides extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (position.dx < 0 || position.dx >= size.width) return false;
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// A short run of steps toward one goal — an onboarding, a checkout, an
/// import: a numbered circle for each step joined by hairlines, its name
/// under it. A finished step is the ink circle with a tick and an ink line
/// on to the next; the current one is said in ink and weight, its circle
/// an ink rim round its number and its name at medium weight in the ink;
/// the steps ahead stay on the control edge in the faint ink. The circles are round by
/// meaning in every corner family. Too narrow for every name, it prints
/// the current step's alone ("Step 2 of 4 · Plan").
///
/// With [onStepPressed] each finished step is a control that goes back to
/// it; steps ahead never are.
///
/// ```dart
/// MinimalStepProgress(steps: const ['Account', 'Plan', 'Pay'], current: 1)
/// ```
class MinimalStepProgress extends StatelessWidget {
  /// The progress through [steps].
  const MinimalStepProgress({
    super.key,
    required this.steps,
    required this.current,
    this.onStepPressed,
  });

  /// The steps' names, in order.
  final List<String> steps;

  /// The step being worked on, from 0; `steps.length` once all are done.
  final int current;

  /// Reports the step pressed; null leaves the steps still.
  final ValueChanged<int>? onStepPressed;

  static const double _mark = 22;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final l = MinimalLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final roomy = box.maxWidth >= steps.length * 96;
        final row = Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              // The line stands on a whole pixel: centred in the marks'
              // even height, a 1 px line straddles two pixels and prints as
              // a faint 2 px smear (the track fainter than any hairline,
              // the done stretch a mid grey).
              if (i > 0)
                Expanded(
                  child: SizedBox(
                    height: _mark,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: t.hairline,
                        margin: EdgeInsets.fromLTRB(
                          MinimalSpacing.s4,
                          ((_mark - t.hairline) / 2).floorToDouble(),
                          MinimalSpacing.s4,
                          0,
                        ),
                        color: i <= current ? t.foreground : t.border,
                      ),
                    ),
                  ),
                ),
              _StepMark(
                number: i + 1,
                done: i < current,
                current: i == current,
                size: _mark,
                label:
                    '${l.stepOf(i + 1, steps.length)}, ${steps[i]}'
                    '${i < current
                        ? ', ${l.completed}'
                        : i == current
                        ? ', ${l.current}'
                        : ''}',
                onPressed: onStepPressed == null || i >= current
                    ? null
                    : () => onStepPressed!(i),
              ),
            ],
          ],
        );
        // Each name stands under its own circle: centred on it, in the room
        // halfway to each neighbour's; the first starts with the run and
        // the last ends with it. The circles sit at the run's ends and
        // evenly between (the hairlines share the rest).
        final n = steps.length;
        final pitch = n < 2 ? 0.0 : (box.maxWidth - _mark) / (n - 1);
        Widget name(int i) => ExcludeSemantics(
          child: Text(
            steps[i],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: i == 0
                ? TextAlign.start
                : i == n - 1
                ? TextAlign.end
                : TextAlign.center,
            style: i == current
                ? t.caption.medium.c(t.foreground)
                : t.caption.c(t.mutedForeground),
          ),
        );
        final names = roomy
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  // The first name, in flow, gives the line its height.
                  SizedBox(
                    width: n < 2 ? box.maxWidth : pitch / 2 + _mark / 2,
                    child: name(0),
                  ),
                  for (var i = 1; i < n; i++)
                    i == n - 1
                        ? PositionedDirectional(
                            end: 0,
                            top: 0,
                            width: pitch / 2 + _mark / 2,
                            child: name(i),
                          )
                        : PositionedDirectional(
                            start: _mark / 2 + i * pitch - pitch / 2,
                            top: 0,
                            width: pitch,
                            child: name(i),
                          ),
                ],
              )
            : ExcludeSemantics(
                child: Text(
                  '${l.stepOf((current + 1).clamp(1, steps.length), steps.length)}'
                  ' · ${steps[current.clamp(0, steps.length - 1)]}',
                  style: t.caption.medium.c(t.foreground),
                ),
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [row, const MinimalGap(MinimalSpacing.s8), names],
        );
      },
    );
  }
}

class _StepMark extends StatelessWidget {
  const _StepMark({
    required this.number,
    required this.done,
    required this.current,
    required this.size,
    required this.label,
    required this.onPressed,
  });

  final int number;
  final bool done;
  final bool current;
  final double size;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    const shape = CircleBorder();
    final mark = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: minimalFrame(
        shape,
        fill: done ? t.foreground : t.card,
        side: BorderSide(
          color: done
              ? t.foreground
              : current
              ? t.foreground
              : t.input,
          width: current ? t.focusWidth * 0.75 : t.rim,
        ),
      ),
      child: done
          // The tick on Lucide's own full stroke, not the look's lighter
          // cut: a hair of dark on the light disc of a dark theme thins to
          // grey, so the tick is drawn heavier than a row's glyph.
          ? Icon(LucideIcons.check, size: MinimalIconSize.i14, color: t.card)
          : Text(
              '$number',
              style: t.mono
                  .copyWith(fontSize: 11)
                  .c(current ? t.foreground : t.textTertiary),
            ),
    );
    return MinimalPressable(
      onPressed: onPressed,
      shape: shape,
      semanticLabel: label,
      child: onPressed == null
          // A step of its own for a screen reader, not merged into the
          // run's other words.
          ? Semantics(
              container: true,
              label: label,
              child: ExcludeSemantics(child: mark),
            )
          : ExcludeSemantics(child: mark),
    );
  }
}
