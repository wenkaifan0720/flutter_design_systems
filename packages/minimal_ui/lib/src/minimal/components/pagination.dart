/// Where a reader is in a run of pages or steps: pagination, page dots and
/// a step progress.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawFocusShown;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
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
/// [page] counts from 0. Each control keeps the tap floor's target, and its press
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
  }) : assert(pageCount > 0, 'a pager holds at least one page'),
       assert(
         page >= 0 && page < pageCount,
         'page counts from 0 to pageCount - 1',
       ),
       assert(siblings >= 0, 'siblings is never negative');

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
      semanticLabel: l.previousPage,
      onPressed: change == null || current == 0
          ? null
          : () => change(current - 1),
    );
    final on = MinimalIconButton(
      rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      variant: MinimalIconButtonVariant.ghost,
      semanticLabel: l.nextPage,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('page', page))
      ..add(IntProperty('pageCount', pageCount))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onPageChanged',
          onPageChanged,
        ),
      )
      ..add(IntProperty('siblings', siblings, defaultValue: 1));
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
/// current dot grows into place in [MinimalMotion.base].
///
/// With [onPageChanged] the dots are one control, as iOS's page control is: a
/// tap before the current dot goes back a page, a tap after it on a page,
/// the arrow keys step it, and a screen reader adjusts it (swipe up or
/// down). The dots are too small to tap one by one; the control is laid
/// out at the tap floor round them.
///
/// ```dart
/// MinimalPageDots(pageCount: 4, page: page, onPageChanged: controller.jumpToPage)
/// ```
class MinimalPageDots extends StatefulWidget {
  /// A dot for each of [pageCount] pages.
  const MinimalPageDots({
    super.key,
    required this.pageCount,
    required this.page,
    this.onPageChanged,
    this.position,
  }) : assert(pageCount > 0, 'dots for at least one page'),
       assert(
         page >= 0 && page < pageCount,
         'selectedIndex counts from 0 to count - 1',
       );

  /// How many pages there are.
  final int pageCount;

  /// The current page, from 0.
  final int page;

  /// Reports the page the control steps to; null leaves the dots still.
  final ValueChanged<int>? onPageChanged;

  /// Where the pages are while they move, in pages (1.5 is half way from the
  /// second to the third; past the last it runs on toward the first), so the
  /// long dot travels with a swipe instead of jumping when it ends. Null: the
  /// dots ease to [page] when it changes.
  final double? position;

  static const double _dot = 6;
  static const double _long = 18;
  static const double _cell = 16;

  /// A dot's cell across: the dot and its air either side.
  static const double _pitch = _dot + 2 * MinimalSpacing.s4;

  @override
  State<MinimalPageDots> createState() => _MinimalPageDotsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pageCount', pageCount))
      ..add(IntProperty('page', page))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onPageChanged',
          onPageChanged,
        ),
      )
      ..add(DoubleProperty('position', position, defaultValue: null));
  }
}

class _MinimalPageDotsState extends State<MinimalPageDots> {
  // Focus shows as ui_core's parts show it: after a key, not after a
  // click (on the web, a click that focuses through semantics too).
  late final RawFocusShown _shown = RawFocusShown((shown) {
    if (mounted) setState(() => _focus = shown);
  });

  @override
  void dispose() {
    _shown.dispose();
    super.dispose();
  }

  bool _focus = false;

  void _step(int by) {
    final next = widget.page + by;
    if (next < 0 || next >= widget.pageCount) return;
    widget.onPageChanged?.call(next);
  }

  // A tap before the current dot steps back, after it on.
  void _tapAt(Offset at, bool rtl) {
    const pitch = MinimalPageDots._pitch;
    final start = widget.page * pitch;
    final end = start + MinimalPageDots._long + 2 * MinimalSpacing.s4;
    final x = rtl ? context.size!.width - at.dx : at.dx;
    if (x < start) _step(-1);
    if (x > end) _step(1);
  }

  // The dots hug their run on their start, whatever stretches them: the
  // control is as wide as the dots it steps through, not its column.
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    heightFactor: 1,
    child: _control(context),
  );

  Widget _control(BuildContext context) {
    final t = context.minimalTheme;
    final l = MinimalLocalizations.of(context);
    final count = widget.pageCount;
    final selected = widget.page;
    final at = widget.position;
    // Followed frame by frame, the dots must not ease after it as well.
    final duration = context.minimalStill || at != null
        ? Duration.zero
        : MinimalMotion.base;
    final shape = t.shapes.pill;
    final press = widget.onPageChanged;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // How much of the current page's long dot dot [i] wears: whole on the
    // page, none a page away, measured round the ring (the last page's
    // neighbour on the far side is the first).
    double share(int i) {
      if (at == null) return i == selected ? 1 : 0;
      final d = (i - at).abs();
      return math.max(0.0, 1 - math.min(d, count - d));
    }

    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          SizedBox(
            height: MinimalPageDots._cell,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinimalSpacing.s4,
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: duration,
                  curve: MinimalMotion.out,
                  width:
                      MinimalPageDots._dot +
                      (MinimalPageDots._long - MinimalPageDots._dot) * share(i),
                  height: MinimalPageDots._dot,
                  decoration: minimalFrame(
                    shape,
                    // The other pages on the control edge's ink, 3:1 on
                    // the ground: a hairline's grey would all but vanish.
                    fill: Color.lerp(t.input, t.foreground, share(i)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    if (press == null) {
      return Semantics(
        container: true,
        label: l.pageOf(selected + 1, count),
        child: ExcludeSemantics(child: dots),
      );
    }
    return Semantics(
      container: true,
      value: l.pageOf(selected + 1, count),
      increasedValue: selected < count - 1
          ? l.pageOf(selected + 2, count)
          : null,
      decreasedValue: selected > 0 ? l.pageOf(selected, count) : null,
      onIncrease: selected < count - 1 ? () => _step(1) : null,
      onDecrease: selected > 0 ? () => _step(-1) : null,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          onFocusChange: _shown.focused,
          mouseCursor: SystemMouseCursors.click,
          shortcuts: minimalSeekShortcuts,
          actions: <Type, Action<Intent>>{
            MinimalSeekIntent: CallbackAction<MinimalSeekIntent>(
              onInvoke: (intent) {
                final forward = switch (intent.seek) {
                  MinimalSeek.right => !rtl,
                  MinimalSeek.left => rtl,
                  MinimalSeek.last => true,
                  MinimalSeek.first => false,
                };
                _step(forward ? 1 : -1);
                return null;
              },
            ),
          },
          // Laid out at the floor round the dots, a tap in the room landing
          // on the nearest dot's side of the current one.
          child: MinimalTapBand(
            across: count * MinimalPageDots._pitch,
            child: Builder(
              builder: (context) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _tapAt(d.localPosition, rtl),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: minimalRingFrame(
                    shape,
                    ring: _focus ? t.ring : null,
                    ground: minimalGround(context),
                    width: t.focusWidth,
                  ),
                  child: dots,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
    assert(steps.isNotEmpty, 'a step progress has at least one step');
    assert(
      current >= 0 && current <= steps.length,
      'current counts from 0 to steps.length (all done)',
    );
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('steps', steps))
      ..add(IntProperty('current', current))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onStepPressed',
          onStepPressed,
        ),
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
                  // An upcoming step's number is read: the secondary ink.
                  .c(current ? t.foreground : t.mutedForeground),
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
