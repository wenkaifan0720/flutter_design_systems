/// Keycap's wayfinding: [KeycapBreadcrumb] (the way here, printed on the
/// case), [KeycapPagination] (page keys, the current one latched),
/// [KeycapStepProgress] (where a job's steps stand) and [KeycapPageDots]
/// (which of a few pages shows).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'internal/small_key.dart';
import 'internal/spring_value.dart';
import 'theme.dart';

/// One place on the way to a [KeycapBreadcrumb]'s current one.
@immutable
class KeycapCrumb {
  /// A place called [label]; [onPressed] goes back to it.
  const KeycapCrumb(this.label, {this.onPressed});

  /// Its name.
  final String label;

  /// Goes there; null for the current place (the last).
  final VoidCallback? onPressed;
}

/// The way to where the reader is, printed on the case: each place before
/// it in the muted ink, a link back to it; the current place in the ink,
/// last. Below 600 wide only the place above shows, with a back chevron.
///
/// ```dart
/// KeycapBreadcrumb(crumbs: [KeycapCrumb('Folders', onPressed: toFolders), KeycapCrumb('Garden', onPressed: toGarden), const KeycapCrumb('Seed list')])
/// ```
class KeycapBreadcrumb extends StatelessWidget {
  /// A breadcrumb of [crumbs], the last the current place.
  const KeycapBreadcrumb({super.key, required this.crumbs, this.semanticLabel});

  /// The places, first to current.
  final List<KeycapCrumb> crumbs;

  /// Its name, for a screen reader ("Breadcrumb").
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    assert(crumbs.isNotEmpty, 'A breadcrumb needs at least its current place.');
    if (crumbs.isEmpty) return const SizedBox.shrink();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final sep = Icon(
      rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      size: 14,
      color: c.inkMuted,
    );
    if (narrow && crumbs.length > 1) {
      final up = crumbs[crumbs.length - 2];
      return Semantics(
        container: true,
        label: semanticLabel,
        child: _Crumb(
          label: up.label,
          onPressed: up.onPressed,
          current: false,
          leading: Icon(
            rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
            size: 16,
            color: c.inkMuted,
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i > 0) ExcludeSemantics(child: sep),
            _Crumb(
              label: crumb.label,
              onPressed: i == crumbs.length - 1 ? null : crumb.onPressed,
              current: i == crumbs.length - 1,
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

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.onPressed,
    required this.current,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool current;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    Widget words(Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?leading,
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.secondary.copyWith(
            color: color,
            fontWeight: current ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
    const pad = EdgeInsets.symmetric(
      horizontal: KeycapSpacing.tight + 2,
      vertical: KeycapSpacing.tight,
    );
    if (current || onPressed == null) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Padding(padding: pad, child: words(c.ink)),
      );
    }
    return RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      button: false,
      link: true,
      excludeSemantics: true,
      builder: (context, states, _) {
        final pressed = states.contains(WidgetState.pressed);
        final focused = states.contains(WidgetState.focused);
        return TapTargetPadding(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KeycapMetrics.smallKeyRadius),
              border: Border.all(
                color: focused ? c.focus : c.focus.withValues(alpha: 0),
                width: KeycapMetrics.focusWidth,
              ),
            ),
            child: Padding(
              padding: pad,
              child: words(pressed ? c.ink : c.inkMuted),
            ),
          ),
        );
      },
    );
  }
}

/// Pages of a long list: a key to the page before, keys for the pages near
/// this one (the current latched down), a key to the page after. Below
/// 600 wide, "Page 3 of 12" between the two arrow keys.
///
/// ```dart
/// KeycapPagination(page: page, pageCount: 12, onPageChanged: (p) => setState(() => page = p))
/// ```
class KeycapPagination extends StatelessWidget {
  /// Pagination at [page] (from 1) of [pageCount].
  const KeycapPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    this.semanticLabel,
  }) : assert(page >= 1 && page <= pageCount);

  /// The current page, from 1.
  final int page;

  /// How many pages.
  final int pageCount;

  /// Called with the page to go to; null turns it off.
  final ValueChanged<int>? onPageChanged;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  /// A page key's side.
  static const double keySide = 40;

  List<int?> _pages() {
    if (pageCount <= 7) return [for (var i = 1; i <= pageCount; i++) i];
    final out = <int?>[1];
    final from = (page - 1).clamp(2, pageCount - 4);
    final to = (page + 1).clamp(5, pageCount - 1);
    if (from > 2) out.add(null);
    for (var i = from; i <= to; i++) {
      out.add(i);
    }
    if (to < pageCount - 1) out.add(null);
    out.add(pageCount);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final go = onPageChanged;
    final prev = KeycapSmallKey(
      icon: rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
      semanticLabel: words.previousPageTooltip,
      onPressed: go == null || page <= 1 ? null : () => go(page - 1),
      side: keySide,
    );
    final next = KeycapSmallKey(
      icon: rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      semanticLabel: words.nextPageTooltip,
      onPressed: go == null || page >= pageCount ? null : () => go(page + 1),
      side: keySide,
    );
    final List<Widget> middle;
    if (narrow) {
      middle = [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.medium),
          child: Text(
            words.positionLabel(page, pageCount),
            style: theme.textTheme.figure.copyWith(color: c.ink),
          ),
        ),
      ];
    } else {
      middle = [
        for (final p in _pages())
          if (p == null)
            SizedBox(
              width: keySide / 1.5,
              child: Center(
                child: Text(
                  '…',
                  style: theme.textTheme.figure.copyWith(color: c.inkMuted),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KeycapMetrics.keyGap / 2,
              ),
              child: _PageKey(
                page: p,
                current: p == page,
                onPressed: go == null ? null : () => go(p),
              ),
            ),
      ];
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          prev,
          const SizedBox(width: KeycapSpacing.small),
          ...middle,
          const SizedBox(width: KeycapSpacing.small),
          next,
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

class _PageKey extends StatelessWidget {
  const _PageKey({
    required this.page,
    required this.current,
    required this.onPressed,
  });

  final int page;
  final bool current;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    const side = KeycapPagination.keySide;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: '$page',
      selected: current,
      semanticSelected: current,
      excludeSemantics: true,
      builder: (context, states, _) {
        final face = keycapKeyFace(
          theme,
          KeycapKind.alpha,
          states,
          latched: current,
          radius: KeycapMetrics.smallKeyRadius,
        );
        return TapTargetPadding(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: side),
            child: SizedBox(
              height: side,
              child: AnimatedKeycapCap(
                face: face,
                walls: KeycapMetrics.walls(side),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeycapSpacing.small,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: RawCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: Text(
                        RawWidgetsLocalizations.of(context).formatDecimal(page),
                        style: theme.textTheme.figure.copyWith(
                          color: face.legend,
                          fontWeight: current
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Where a job's steps stand (share and export, a first run): each step a
/// small well holding its number, a done step's well holding a tick on a
/// tab of accent plastic, the current step's ringed in the accent, joined
/// by a slot filled as far as the work has gone. Each step's name is under
/// it from 600 wide; below, only the current one's, beside the count.
///
/// ```dart
/// KeycapStepProgress(steps: const ['Format', 'Contents', 'Share'], currentStep: 1)
/// ```
class KeycapStepProgress extends StatelessWidget {
  /// Progress through [steps], at [currentStep] (from 0).
  const KeycapStepProgress({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  /// Each step's name.
  final List<String> steps;

  /// The step under way (from 0); [steps]' length once all are done.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    assert(
      currentStep >= 0 && currentStep <= steps.length,
      'current is a step (or steps.length when all are done).',
    );
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final dot = KeycapMetrics.grown(context, 28, theme.textTheme.figure);
    Widget mark(int i) {
      final done = i < currentStep;
      final here = i == currentStep;
      final Widget inner = done
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: c.accent.top,
                borderRadius: BorderRadius.circular(
                  KeycapMetrics.smallKeyRadius,
                ),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.check,
                  size: 16,
                  color: c.accent.legend,
                ),
              ),
            )
          : Center(
              child: Text(
                '${i + 1}',
                style: theme.textTheme.figure.copyWith(
                  color: here ? c.accentInk : c.inkMuted,
                  fontWeight: here ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
      return SizedBox.square(
        dimension: dot,
        child: KeycapWell(
          radius: BorderRadius.circular(KeycapMetrics.smallKeyRadius + 2),
          rim: here ? c.accentInk : null,
          padding: EdgeInsets.all(done ? KeycapSpacing.hairline : 0),
          child: inner,
        ),
      );
    }

    Widget join(int i) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.tight),
        child: SizedBox(
          height: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: i < currentStep ? c.accent.top : c.well,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );

    final label = currentStep >= steps.length ? steps.last : steps[currentStep];
    return Semantics(
      container: true,
      label: words.positionLabel(
        (currentStep + 1).clamp(1, steps.length),
        steps.length,
      ),
      value: label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) join(i),
                mark(i),
              ],
            ],
          ),
          const SizedBox(height: KeycapSpacing.small),
          if (wide)
            Row(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: Text(
                      steps[i],
                      textAlign: i == 0
                          ? TextAlign.start
                          : i == steps.length - 1
                          ? TextAlign.end
                          : TextAlign.center,
                      maxLines: 2,
                      style: theme.textTheme.secondary.copyWith(
                        color: i == currentStep ? c.ink : c.inkMuted,
                        fontWeight: i == currentStep
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            )
          else
            Text(
              '${words.positionLabel((currentStep + 1).clamp(1, steps.length), steps.length)} · $label',
              style: theme.textTheme.secondary.copyWith(color: c.ink),
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
      ..add(IntProperty('currentStep', currentStep));
  }
}

/// Which of a few pages shows (a carousel's, a first run's): small wells
/// in a row, the current page's stretched and holding a tab of accent
/// plastic. With [onPageChanged] the row is one control, at least 44 high: a
/// tap on either side steps a page that way, the arrow keys (and Home and
/// End) step it, and a screen reader adjusts it.
///
/// ```dart
/// KeycapPageDots(pageCount: 4, page: page, onPageChanged: (i) => controller.animateToPage(i))
/// ```
class KeycapPageDots extends StatelessWidget {
  /// Dots for [pageCount] pages at [page].
  const KeycapPageDots({
    super.key,
    required this.pageCount,
    required this.page,
    this.onPageChanged,
  }) : assert(page >= 0 && page < pageCount);

  /// How many pages.
  final int pageCount;

  /// The page showing, from 0.
  final int page;

  /// Goes to a page; the dots only show when null.
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    final words = RawWidgetsLocalizations.of(context);
    // A page not showing is a small well. By night a well is lighter than
    // the case (the plastic's wall shade): a darker one vanished into it.
    final rest = c.brightness == Brightness.dark ? c.alpha.wall : c.wellPressed;
    Widget dot(int i) => KeycapSpringValue(
      value: i == page ? 1 : 0,
      spring: KeycapMotion.latch,
      builder: (context, t, _) => SizedBox(
        width: 8 + 12 * t.clamp(0.0, 1.0),
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(rest, c.accent.top, t.clamp(0.0, 1.0)),
            borderRadius: BorderRadius.circular(4),
            border: Border(
              top: BorderSide(
                color: c.wellShade.withValues(
                  alpha: c.wellShade.a * (1 - t.clamp(0.0, 1.0)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final go = onPageChanged;
    if (go == null) {
      return Semantics(
        label: words.positionLabel(page + 1, pageCount),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < pageCount; i++) ...[
              if (i > 0) const SizedBox(width: KeycapSpacing.small),
              dot(i),
            ],
          ],
        ),
      );
    }
    return _DotsStepper(
      count: pageCount,
      index: page,
      onChanged: go,
      dots: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pageCount; i++) ...[
            if (i > 0) const SizedBox(width: KeycapSpacing.small),
            dot(i),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pageCount', pageCount))
      ..add(IntProperty('page', page));
  }
}

/// [KeycapPageDots]' control: one target round the dots that steps a page
/// toward the side tapped, by the arrow keys, or by a screen reader's
/// adjust.
class _DotsStepper extends StatefulWidget {
  const _DotsStepper({
    required this.count,
    required this.index,
    required this.onChanged,
    required this.dots,
  });

  final int count;
  final int index;
  final ValueChanged<int> onChanged;
  final Widget dots;

  @override
  State<_DotsStepper> createState() => _DotsStepperState();
}

class _DotsStepperState extends State<_DotsStepper> {
  bool _focused = false;

  void _go(int to) {
    final next = to.clamp(0, widget.count - 1);
    if (next != widget.index) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final i = widget.index;
    final n = widget.count;
    return Semantics(
      container: true,
      slider: true,
      value: words.positionLabel(i + 1, n),
      increasedValue: i < n - 1 ? words.positionLabel(i + 2, n) : null,
      decreasedValue: i > 0 ? words.positionLabel(i, n) : null,
      onIncrease: i < n - 1 ? () => _go(i + 1) : null,
      onDecrease: i > 0 ? () => _go(i - 1) : null,
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          final key = event.logicalKey;
          final forward = rtl
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowRight;
          final back = rtl
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft;
          final int? to = key == forward
              ? i + 1
              : key == back
              ? i - 1
              : key == LogicalKeyboardKey.home
              ? 0
              : key == LogicalKeyboardKey.end
              ? n - 1
              : null;
          if (to == null) return KeyEventResult.ignored;
          _go(to);
          return KeyEventResult.handled;
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final width = context.size?.width ?? 0;
              final after = details.localPosition.dx > width / 2;
              _go(after != rtl ? i + 1 : i - 1);
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KeycapMetrics.keyRadius),
                border: Border.all(
                  color: _focused ? c.focus : c.focus.withValues(alpha: 0),
                  width: KeycapMetrics.focusWidth,
                ),
              ),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KeycapSpacing.medium,
                  ),
                  child: Center(widthFactor: 1, child: widget.dots),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
