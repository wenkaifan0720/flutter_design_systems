import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../nav_bar.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';

/// The destinations as a narrow column down the window's start edge, for a
/// window too wide for the tab bar and too narrow for the sidebar: 80 wide
/// in the sidebar's translucent white with its hairline at the end, each
/// destination its glyph in a 56 by 32 pill over its word, the selected
/// one's pill on the brighter glass with its glyph in the ink. [leading]
/// stands over the destinations (the main act), [trailing] at the foot.
/// Each destination is a link that says whether it is selected; the arrow
/// keys and Tab move between them.
///
/// ```dart
/// FrostedNavigationRail(items: tabs, selectedIndex: index, onDestinationSelected: (i) => setState(() => index = i))
/// ```
class FrostedNavigationRail extends StatelessWidget {
  /// A rail of [items], [selectedIndex] lit.
  const FrostedNavigationRail({
    required this.items,
    this.selectedIndex,
    this.onDestinationSelected,
    this.leading,
    this.trailing,
    this.label,
    super.key,
  });

  /// The destinations, in the tab bar's order.
  final List<FrostedNavItem> items;

  /// The selected destination's index; null lights none.
  final int? selectedIndex;

  /// Called with the index of the pressed destination.
  final ValueChanged<int>? onDestinationSelected;

  /// What stands over the destinations.
  final Widget? leading;

  /// What stands at the rail's foot.
  final Widget? trailing;

  /// What a screen reader calls the rail.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: SizedBox(
        width: 80,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.glass.sidebar,
            border: BorderDirectional(
              end: BorderSide(
                color: t.glass.sidebarEdge,
                width: FrostedStrokes.hairline,
              ),
            ),
          ),
          child: SafeArea(
            right: false,
            child: FocusTraversalGroup(
              // The trailing part stands at the foot while the places fit;
              // a rail shorter than its places scrolls them.
              child: CustomScrollView(
                primary: false,
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                        const SizedBox(height: FrostedSpacing.s16),
                        if (leading case final leading?) ...[
                          leading,
                          const SizedBox(height: FrostedSpacing.s16),
                        ],
                        for (final (i, item) in items.indexed)
                          _RailDestination(
                            item: item,
                            selected: i == selectedIndex,
                            onPressed: onDestinationSelected == null
                                ? null
                                : () => onDestinationSelected!(i),
                          ),
                        const Spacer(),
                        ?trailing,
                        const SizedBox(height: FrostedSpacing.s16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailDestination extends StatelessWidget {
  const _RailDestination({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final FrostedNavItem item;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    const pill = Size(56, 32);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s4),
      child: FrostedPressable(
        key: item.key,
        onPressed: onPressed,
        label: item.label,
        role: FrostedPressRole.link,
        selected: selected,
        radius: pill.height / 2,
        // 56 tall, and taller as large text needs it.
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 72,
            maxWidth: 72,
            minHeight: 56,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: FrostedSpacing.s4,
            children: [
              AnimatedContainer(
                duration: motion.fast,
                curve: motion.curve,
                width: pill.width,
                height: pill.height,
                decoration: ShapeDecoration(
                  shape: FrostedCorners.full.copyWith(
                    side: selected
                        ? BorderSide(
                            color: t.glass.edge,
                            width: FrostedStrokes.hairline,
                          )
                        : BorderSide.none,
                  ),
                  color: selected ? t.glass.navCurrent : null,
                ),
                child: Icon(
                  selected ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: FrostedChromeMetrics.navGlyph,
                  color: selected
                      ? t.colorScheme.textPrimary
                      : t.colorScheme.textTertiary,
                ),
              ),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected
                    ? t.textTheme.labelSmall.semibold.c(
                        t.colorScheme.textPrimary,
                      )
                    : t.textTheme.labelSmall.c(t.colorScheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One step of a [FrostedBreadcrumb]: its [label], and where a press takes
/// the reader ([onPressed]); the last step is the page itself.
class FrostedBreadcrumbItem {
  /// A step named [label].
  const FrostedBreadcrumbItem(this.label, {this.onPressed, this.key});

  /// The step's words.
  final String label;

  /// Where a press goes; null for a step that is not a link.
  final VoidCallback? onPressed;

  /// A key for the step's target.
  final Key? key;
}

/// Where the page stands in the app's tree: each step from the root as a
/// link in the quiet ink, a chevron between (mirrored right to left), the
/// last step (the page) in the ink and not a link. The steps wrap onto a
/// second line rather than cut. Read aloud as a navigation list, the last
/// step said to be the current page.
///
/// ```dart
/// FrostedBreadcrumb(items: [FrostedBreadcrumbItem('Home', onPressed: home), FrostedBreadcrumbItem('Projects', onPressed: projects), FrostedBreadcrumbItem('Lighthouse')])
/// ```
class FrostedBreadcrumb extends StatelessWidget {
  /// The trail of [items], root first.
  const FrostedBreadcrumb({required this.items, this.label, super.key});

  /// The steps, root first; the last is the page.
  final List<FrostedBreadcrumbItem> items;

  /// What a screen reader calls the trail.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final children = <Widget>[];
    for (final (i, item) in items.indexed) {
      final last = i == items.length - 1;
      if (i > 0) {
        children.add(
          ExcludeSemantics(
            child: Icon(
              FrostedGlyphs.forward,
              size: 14,
              color: t.colorScheme.textTertiary,
            ),
          ),
        );
      }
      final word = Text(
        item.label,
        style: last
            ? t.textTheme.link.semibold.c(t.colorScheme.textPrimary)
            : t.textTheme.link.c(t.colorScheme.textSecondary),
      );
      children.add(
        last || item.onPressed == null
            ? Semantics(
                key: item.key,
                selected: last,
                label: item.label,
                excludeSemantics: true,
                child: word,
              )
            : FrostedHitSlop(
                child: FrostedPressable(
                  key: item.key,
                  onPressed: item.onPressed,
                  label: item.label,
                  role: FrostedPressRole.link,
                  radius: FrostedSpacing.s4,
                  child: word,
                ),
              ),
      );
    }
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Wrap(
        spacing: FrostedSpacing.s6,
        runSpacing: FrostedSpacing.s4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

/// Pages of a long list, one at a time: the previous and next glyph
/// buttons either side of the page numbers, the selected page on the
/// brighter glass in the ink, the rest in the quiet ink; past seven pages
/// the middle folds into an ellipsis round the selected one. Each number
/// is a button that says its page and whether it is selected; the arrows
/// say previous and next and go inert at the ends.
///
/// ```dart
/// FrostedPagination(pageCount: 12, selectedIndex: page, onChanged: (p) => setState(() => page = p))
/// ```
class FrostedPagination extends StatelessWidget {
  /// [pageCount] pages, [selectedIndex] (from 0) selected.
  const FrostedPagination({
    required this.pageCount,
    required this.selectedIndex,
    this.onChanged,
    this.label,
    super.key,
  }) : assert(pageCount > 0);

  /// How many pages.
  final int pageCount;

  /// The selected page, from 0.
  final int selectedIndex;

  /// Called with the page pressed; null makes it inert.
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls it.
  final String? label;

  /// The pages shown: every one up to seven, else the ends and the
  /// selected page's neighbours, null for a fold.
  List<int?> get _shown {
    if (pageCount <= 7) return [for (var i = 0; i < pageCount; i++) i];
    final s = selectedIndex;
    final last = pageCount - 1;
    if (s < 4) return [0, 1, 2, 3, 4, null, last];
    if (s > last - 4) {
      return [0, null, last - 4, last - 3, last - 2, last - 1, last];
    }
    return [0, null, s - 1, s, s + 1, null, last];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    return FrostedDim(off: onChanged == null, child: pages);
  }

  Widget _pages(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final target = FrostedBreakpoints.hitTargetOf(context);
    const d = 36.0;
    void go(int i) => onChanged?.call(i.clamp(0, pageCount - 1));
    Widget arrow(IconData icon, String name, bool live, int to) =>
        FrostedHitSlop(
          target: target,
          child: FrostedPressable(
            onPressed: live && onChanged != null ? () => go(to) : null,
            label: name,
            radius: d / 2,
            child: SizedBox.square(
              dimension: d,
              child: FrostedDim(
                off: !(live || onChanged == null),
                child: Icon(icon, size: 18, color: t.colorScheme.textPrimary),
              ),
            ),
          ),
        );
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedSpacing.s4,
        children: [
          // A pair of chevrons: [FrostedGlyphs.back] is an arrow, and
          // stood an arrow at one end against a chevron at the other.
          arrow(
            FrostedGlyphs.chevronLeft,
            words.previous,
            selectedIndex > 0,
            selectedIndex - 1,
          ),
          for (final page in _shown)
            if (page == null)
              ExcludeSemantics(
                child: SizedBox(
                  width: d * .75,
                  child: Text(
                    '…',
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleMedium.c(
                      t.colorScheme.textTertiary,
                    ),
                  ),
                ),
              )
            else
              FrostedHitSlop(
                target: target,
                child: FrostedPressable(
                  onPressed: onChanged == null ? null : () => go(page),
                  label: words.page(page + 1, pageCount),
                  selected: page == selectedIndex,
                  radius: d / 2,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: d,
                      minHeight: d,
                    ),
                    child: FrostedFace(
                      material: FrostedMaterial.paint,
                      radius: BorderRadius.circular(d / 2),
                      color: page == selectedIndex ? t.glass.fillHigh : null,
                      edge: page == selectedIndex ? t.glass.edge : null,
                      sheen: page == selectedIndex ? t.glass.rim : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FrostedSpacing.s8,
                      ),
                      // As tall as the 36 face in a box of any height.
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          '${page + 1}',
                          style: page == selectedIndex
                              ? t.textTheme.labelLarge.tabular.semibold.c(
                                  t.colorScheme.textPrimary,
                                )
                              : t.textTheme.labelLarge.tabular.c(
                                  t.colorScheme.textSecondary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          arrow(
            FrostedGlyphs.forward,
            words.next,
            selectedIndex < pageCount - 1,
            selectedIndex + 1,
          ),
        ],
      ),
    );
  }
}

/// Where a flow of steps stands: [count] segments of the glass tube across
/// the width, those up to [currentStep] filled with the signature band,
/// over the step's [name] and its place ("Step 2 of 4", or [phase] in its
/// stead). Display only; read aloud as the step's place and its name.
///
/// ```dart
/// FrostedStepProgress(count: 4, currentStep: 1, name: 'Your details')
/// ```
class FrostedStepProgress extends StatelessWidget {
  /// Step [currentStep] (from 0) of [count], named [name].
  const FrostedStepProgress({
    required this.count,
    required this.currentStep,
    required this.name,
    this.phase,
    super.key,
  }) : assert(count > 0 && currentStep >= 0 && currentStep < count);

  /// How many steps.
  final int count;

  /// The step it stands at, from 0.
  final int currentStep;

  /// The step's name.
  final String name;

  /// Words in place of "Step 2 of 4" ("Almost done").
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final place =
        phase ?? FrostedLocalizations.of(context).step(currentStep + 1, count);
    const h = 6.0;
    const end = Radius.circular(h / 2);
    return Semantics(
      container: true,
      label: '$place, $name',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedSpacing.s8,
        children: [
          Row(
            spacing: FrostedSpacing.s4,
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: SizedBox(
                    height: h,
                    child: FrostedFace(
                      material: FrostedMaterial.paint,
                      radius: const BorderRadius.all(end),
                      color: t.glass.track,
                      ring: t.glass.trackEdge,
                      clipChild: true,
                      child: AnimatedOpacity(
                        opacity: i <= currentStep ? 1 : 0,
                        duration: motion.base,
                        curve: motion.curve,
                        child: FrostedFace(
                          material: FrostedMaterial.paint,
                          radius: const BorderRadius.all(end),
                          gradients: [t.hues.iris.band],
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: place,
                  style: t.textTheme.labelMedium.c(t.colorScheme.textSecondary),
                ),
                const TextSpan(text: '  '),
                TextSpan(text: name, style: t.textTheme.titleMedium.semibold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Which of a few pages is shown: [count] dots, the selected one a short
/// capsule in the ink, the rest small rounds of the strong hairline. With
/// [onChanged] each dot takes a press (in a 44 or 48 target) and the arrow
/// keys move along them; read aloud as [label] and the page's place. Given
/// a [position], the capsule moves with the pages as they slide.
///
/// ```dart
/// FrostedPageDots(count: 4, selectedIndex: page, label: 'Welcome', onChanged: (i) => controller.animateToPage(i, duration: d, curve: c))
/// ```
class FrostedPageDots extends StatelessWidget {
  /// [count] dots, [selectedIndex] (from 0) lit.
  const FrostedPageDots({
    required this.count,
    required this.selectedIndex,
    required this.label,
    this.onChanged,
    this.position,
    super.key,
  });

  /// How many pages.
  final int count;

  /// The page shown, from 0.
  final int selectedIndex;

  /// What a screen reader calls the pages.
  final String label;

  /// Called with the dot pressed; null makes the dots display only.
  final ValueChanged<int>? onChanged;

  /// Where the pages are, in pages, frame by frame (1.5 is half way from the
  /// second to the third; past the last it runs on towards the first, as a
  /// looping carousel's does). Given, the capsule grows from one dot into
  /// the next as the pages slide, rather than easing after a page lands;
  /// null follows [selectedIndex].
  final ValueListenable<double>? position;

  @override
  Widget build(BuildContext context) {
    final at = position;
    if (at == null) return _dots(context, null);
    return ValueListenableBuilder<double>(
      valueListenable: at,
      builder: (context, where, _) => _dots(context, where),
    );
  }

  Widget _dots(BuildContext context, double? where) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final words = FrostedLocalizations.of(context);
    Widget dot(int i) {
      if (where != null) {
        // How near the pages stand to this dot, 1 on it, 0 a page away (the
        // last and the first are neighbours).
        final d = (where - i).abs() % count;
        final near = (1 - (d < count - d ? d : count - d)).clamp(0.0, 1.0);
        return SizedBox(
          width: 6 + 12 * near,
          height: 6,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: FrostedCorners.full,
              color: Color.lerp(
                t.colorScheme.borderStrong,
                t.colorScheme.textPrimary,
                near,
              ),
            ),
          ),
        );
      }
      final on = i == selectedIndex;
      return AnimatedContainer(
        duration: motion.base,
        curve: motion.curve,
        width: on ? 18 : 6,
        height: 6,
        decoration: ShapeDecoration(
          shape: FrostedCorners.full,
          color: on ? t.colorScheme.textPrimary : t.colorScheme.borderStrong,
        ),
      );
    }

    final live = onChanged;
    if (live == null) {
      return Semantics(
        label: label,
        value: words.page(selectedIndex + 1, count),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedSpacing.s6,
          children: [for (var i = 0; i < count; i++) dot(i)],
        ),
      );
    }
    final target = FrostedBreakpoints.hitTargetOf(context);
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            FrostedPressable(
              onPressed: () => live(i),
              label: words.page(i + 1, count),
              selected: i == selectedIndex,
              radius: 3,
              child: SizedBox(
                width: target * .6,
                height: target,
                child: Center(child: dot(i)),
              ),
            ),
        ],
      ),
    );
  }
}
