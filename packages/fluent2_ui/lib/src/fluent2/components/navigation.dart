// Ways round an app the inventory adds: the rail, the pager, the step heading and the page dots.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../internal/hit_slop.dart';
import '../internal/well.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button/button.dart';
import 'nav_bar.dart';
import 'nav_pane.dart';
import 'pressable/pressable.dart';
import 'tooltip/tooltip.dart';

import 'package:ui_core/ui_core.dart';

/// The folded nav pane as a rail: 48 wide, each destination its glyph alone
/// in a 40 item, the selection indicator at its start, its name in a tooltip.
///
/// ```dart
/// Fluent2NavigationRail(items: const [Fluent2NavItem(Fluent2Icons.home, 'Home')], selectedIndex: 0, onDestinationSelected: go)
/// ```
class Fluent2NavigationRail extends StatelessWidget {
  /// A rail of [items].
  const Fluent2NavigationRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.label,
  });

  /// The destinations.
  final List<Fluent2NavItem> items;

  /// Which one is current.
  final int selectedIndex;

  /// Told the destination pressed; null draws them out of use.
  final ValueChanged<int>? onDestinationSelected;

  /// What stands over the destinations.
  final Widget? header;

  /// What stands at the rail's foot.
  final Widget? footer;

  /// What a screen reader calls it.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final go = onDestinationSelected;
    // Under a finger a destination spans the rail, a whole target (48)
    // wide; the end stroke is drawn over the rail, not beside its items.
    final touch = Fluent2Layout.padded(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: Fluent2Spacing.xs),
        decoration: BoxDecoration(color: t.colors.neutralBackground1),
        foregroundDecoration: BoxDecoration(
          border: BorderDirectional(
            end: BorderSide(color: t.colors.neutralStroke2),
          ),
        ),
        child: Column(
          children: [
            ?header,
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: touch ? 0 : Fluent2Spacing.xs,
                  ),
                  child: Column(
                    spacing: Fluent2Spacing.xxs,
                    children: [
                      for (final (i, item) in items.indexed)
                        Fluent2Tooltip(
                          message: item.label,
                          position: Fluent2TooltipPosition.after,
                          child: Fluent2NavigationDrawerItem(
                            key: item.key,
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            label: item.label,
                            selected: i == selectedIndex,
                            collapsed: true,
                            onPressed: go == null ? null : () => go(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// A pager of subtle buttons: a chevron each way, the page numbers with gaps
/// where there are too many, the current one on the selected fill in strong
/// words. Too narrow for the numbers, it says "Page 4 of 12" between the
/// chevrons.
///
/// ```dart
/// Fluent2Pagination(page: 4, pages: 12, onChanged: (p) => setState(() => page = p))
/// ```
class Fluent2Pagination extends StatelessWidget {
  /// A pager at [page] of [pages], counted from 1.
  const Fluent2Pagination({
    super.key,
    required this.page,
    required this.pages,
    this.onChanged,
    this.label,
  }) : assert(page >= 1 && page <= pages);

  /// The current page, from 1.
  final int page;

  /// How many there are.
  final int pages;

  /// Told the page pressed; null draws it out of use.
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls it.
  final String? label;

  /// Page numbers with the gaps shown as null: the ends, and two either side
  /// of the current page.
  static List<int?> _shown(int page, int pages) {
    final out = <int?>[];
    var last = 0;
    for (var p = 1; p <= pages; p++) {
      if (p == 1 || p == pages || (p - page).abs() <= 1) {
        if (p - last > 1) out.add(null);
        out.add(p);
        last = p;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final words = Fluent2Localizations.of(context);
    final go = onChanged;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget chevron(bool back) {
      final to = back ? page - 1 : page + 1;
      final ok = go != null && to >= 1 && to <= pages;
      return Fluent2IconButton(
        (back != rtl) ? Fluent2Icons.chevronLeft : Fluent2Icons.chevronRight,
        label: back
            ? DesignLocalizations.of(context).previousPageTooltip
            : DesignLocalizations.of(context).nextPageTooltip,
        onPressed: ok ? () => go(to) : null,
      );
    }

    Widget number(int p) {
      final current = p == page;
      return Fluent2Pressable(
        onPressed: go == null ? null : () => go(p),
        label: words.pageNumber(p),
        selected: current,
        radius: Fluent2Radius.medium,
        builder: (context, states) {
          final press = states.press;
          return Container(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Fluent2Spacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Fluent2Radius.medium),
              color: current
                  ? press.pick(
                      t.colors.subtleBackgroundSelected,
                      t.colors.subtleBackgroundHover,
                      t.colors.subtleBackgroundPressed,
                    )
                  : press.pick(
                      t.colors.subtleBackground,
                      t.colors.subtleBackgroundHover,
                      t.colors.subtleBackgroundPressed,
                    ),
            ),
            child: Text(
              '$p',
              style: (current ? t.body1Strong : t.body1).tabular.c(
                press == Fluent2Press.disabled
                    ? t.colors.neutralForegroundDisabled
                    : current
                    ? t.colors.neutralForeground1
                    : t.colors.neutralForeground2,
              ),
            ),
          );
        },
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, box) {
          final shown = _shown(page, pages);
          // Under a finger each press is a whole target (48) wide and each
          // gap 32, with the row's spacing between.
          final gaps = shown.where((p) => p == null).length;
          final need = Fluent2Layout.padded(context)
              ? (shown.length - gaps + 2) * Fluent2Layout.touchHitTarget +
                    gaps * 32.0 +
                    (shown.length + 1) * Fluent2Spacing.xxs
              : (shown.length + 2) * 44.0;
          final fits = !box.hasBoundedWidth || box.maxWidth >= need;
          return Fluent2HitSlop(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Fluent2Spacing.xxs,
              children: [
                chevron(true),
                if (fits)
                  for (final p in shown)
                    if (p == null)
                      SizedBox(
                        width: 32,
                        child: ExcludeSemantics(
                          child: Text(
                            '…',
                            textAlign: TextAlign.center,
                            style: t.body1.c(t.textTertiary),
                          ),
                        ),
                      )
                    else
                      number(p)
                else
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Fluent2Spacing.s,
                      ),
                      child: Text(
                        words.pageOf(page, pages),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.body1.tabular,
                      ),
                    ),
                  ),
                chevron(false),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Where a run of steps has got to: "Step 2 of 3" in caption1 over the step's
/// [name] in subtitle2, its [phase] beside it, and a 4 bar cut into one
/// segment per step, the done and the current in the brand.
///
/// ```dart
/// Fluent2StepProgress(count: 3, currentStep: 1, name: 'Your details')
/// ```
class Fluent2StepProgress extends StatelessWidget {
  /// Step [currentStep] (from 0) of [count].
  const Fluent2StepProgress({
    super.key,
    required this.count,
    required this.currentStep,
    required this.name,
    this.phase,
  }) : assert(count > 0),
       assert(currentStep >= 0 && currentStep < count);

  /// How many steps there are.
  final int count;

  /// The current one, from 0.
  final int currentStep;

  /// The current step's name.
  final String name;

  /// A word for how it stands ('Optional'); null shows none.
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final step = Fluent2Localizations.of(context)
        .stepOf(currentStep + 1, count);
    return Semantics(
      container: true,
      label: '$step, $name',
      value: phase,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(step, style: t.caption1.c(t.textSecondary)),
          const SizedBox(height: Fluent2Spacing.xxs),
          Row(
            children: [
              Expanded(child: Text(name, style: t.subtitle2)),
              if (phase != null)
                Text(phase!, style: t.caption1.c(t.textTertiary)),
            ],
          ),
          const SizedBox(height: Fluent2Spacing.s),
          Row(
            spacing: Fluent2Spacing.xs,
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Fluent2Radius.small),
                      color: i <= currentStep
                          ? t.colors.compoundBrandBackground
                          : fluent2Rail(t),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fluent's carousel nav: a dot for each page, 8 round in the accessible
/// stroke, the current a 16 pill in the brand. Each is a 44 target when
/// [onChanged] is set; otherwise the row only tells.
///
/// ```dart
/// Fluent2PageDots(count: 4, selectedIndex: 1, label: 'Photos', onChanged: go)
/// ```
class Fluent2PageDots extends StatelessWidget {
  /// A dot for each of [count] pages.
  const Fluent2PageDots({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.label,
    this.onChanged,
    this.position,
  });

  /// How many pages.
  final int count;

  /// The current page, from 0.
  final int selectedIndex;

  /// What a screen reader calls them.
  final String label;

  /// Told the dot pressed; null leaves them telling.
  final ValueChanged<int>? onChanged;

  /// Where the pages are, in pages, frame by frame (1.5 is half way from
  /// the second page to the third; past the last page it runs on to the
  /// first): the pill passes from dot to dot with it, under the finger,
  /// instead of stepping to [selectedIndex]. A carousel gives its
  /// `controls.position`.
  final double? position;

  /// How much dot [i] is the current one: 1 on it, 0 a page or more away.
  double _current(int i) {
    final p = position;
    if (p == null) return i == selectedIndex ? 1 : 0;
    var d = (i - p).abs();
    if (p > count - 1) d = math.min(d, (i + count - p).abs());
    return (1 - d).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final words = Fluent2Localizations.of(context);
    final go = onChanged;
    final moves = Fluent2Motion.of(context, Fluent2Motion.normal);
    Widget dot(int i, Set<WidgetState> states) {
      final f = _current(i);
      final press = states.press;
      final decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(Fluent2Radius.circular),
        color: Color.lerp(
          press.pick(
            t.colors.neutralStrokeAccessible,
            t.colors.neutralStrokeAccessibleHover,
            t.colors.neutralStrokeAccessiblePressed,
            t.colors.neutralForegroundDisabled,
          ),
          press.pick(
            t.colors.compoundBrandBackground,
            t.colors.compoundBrandBackgroundHover,
            t.colors.compoundBrandBackgroundPressed,
          ),
          f,
        ),
      );
      // Following [position], the pill is where the pages are each frame;
      // otherwise it eases to the dot chosen.
      return position != null
          ? Container(width: 8 + 8 * f, height: 8, decoration: decoration)
          : AnimatedContainer(
              duration: moves,
              curve: Fluent2Motion.decelerateMid,
              width: 8 + 8 * f,
              height: 8,
              decoration: decoration,
            );
    }

    if (go == null) {
      return Semantics(
        label: label,
        value: words.pageOf(selectedIndex + 1, count),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Fluent2Spacing.s,
          children: [for (var i = 0; i < count; i++) dot(i, const {})],
        ),
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Fluent2Pressable(
              onPressed: () => go(i),
              label: words.pageOf(i + 1, count),
              selected: i == selectedIndex,
              radius: Fluent2Radius.medium,
              // Under a finger each dot is a whole target (48) wide; under a
              // pointer half that. The current one's cell is wider by what
              // its pill is wider, so every gap between dots is the same.
              builder: (context, states) => SizedBox(
                width:
                    Fluent2Layout.hitTargetOf(context) *
                        (Fluent2Layout.padded(context) ? 1 : .5) +
                    8 * _current(i),
                height: Fluent2Layout.hitTargetOf(context),
                child: Center(child: dot(i, states)),
              ),
            ),
        ],
      ),
    );
  }
}
