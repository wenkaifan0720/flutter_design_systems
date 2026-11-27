import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';

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
  const FrostedBreadcrumb({required this.items, this.semanticLabel, super.key});

  /// The steps, root first; the last is the page.
  final List<FrostedBreadcrumbItem> items;

  /// What a screen reader calls the trail.
  final String? semanticLabel;

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
                // A step that is not a link stands as tall as the links'
                // targets, so a line holding only the page steps from the
                // line above as the links' lines do.
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: FrostedBreakpoints.hitTargetOf(context),
                  ),
                  child: Center(widthFactor: 1, child: word),
                ),
              )
            : FrostedPressable(
                key: item.key,
                onPressed: item.onPressed,
                semanticLabel: item.label,
                role: FrostedPressRole.link,
                radius: FrostedSpacing.s4,
                child: word,
              ),
      );
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      // The crumbs stand 6 apart, their targets taking the room between
      // them (ui_core's chip group).
      child: RawChipGroup(
        spacing: FrostedSpacing.s6,
        runSpacing: FrostedSpacing.s4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedBreadcrumbItem>('items', items))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

/// Pages of a long list, one at a time: the previous and next glyph
/// buttons either side of the page numbers, the selected page on the
/// brighter glass in the ink, the rest in the quiet ink; past seven pages
/// the middle folds into an ellipsis round the selected one (past five
/// where seven touch targets do not fit the width, as on a phone). Each
/// number is a button that says its page and whether it is selected; the
/// arrows say previous and next and go inert at the ends. Each stands in
/// its touch target, the targets edge to edge.
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
    this.semanticLabel,
    super.key,
  }) : assert(pageCount > 0),
       assert(
         selectedIndex >= 0 && selectedIndex < pageCount,
         'The page shown is one of the pages.',
       );

  /// How many pages.
  final int pageCount;

  /// The selected page, from 0.
  final int selectedIndex;

  /// Called with the page pressed; null makes it inert.
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// The pages shown in [width] at [target] apiece: every one when up to
  /// seven fit (four or fewer always show), else the ends and the selected
  /// page's neighbours in seven places or, where seven do not fit, five,
  /// null for a fold.
  List<int?> _shown(double width, double target) {
    bool fits(double w) => !width.isFinite || w <= width;
    if (pageCount <= 4 || (pageCount <= 7 && fits((pageCount + 2) * target))) {
      return [for (var i = 0; i < pageCount; i++) i];
    }
    // The widest a fold of [slots] stands: slots - 1 pages, a fold and
    // both arrows.
    final slots = fits(8 * target + _fold) ? 7 : 5;
    final s = selectedIndex;
    final last = pageCount - 1;
    final run = slots - 2;
    if (s < run - 1) return [for (var i = 0; i < run; i++) i, null, last];
    if (s > last - run + 1) {
      return [0, null, for (var i = last - run + 1; i <= last; i++) i];
    }
    final k = (slots - 5) ~/ 2;
    return [0, null, for (var i = s - k; i <= s + k; i++) i, null, last];
  }

  // A fold's width.
  static const double _fold = 27;

  @override
  Widget build(BuildContext context) => FrostedDim(
    off: onChanged == null,
    child: LayoutBuilder(
      builder: (context, box) => _pages(context, box.maxWidth),
    ),
  );

  Widget _pages(BuildContext context, double width) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final target = FrostedBreakpoints.hitTargetOf(context);
    const d = 36.0;
    void go(int i) => onChanged?.call(i.clamp(0, pageCount - 1));
    // An arrow keeps its target's room when it goes inert at an end, its
    // face on [side], so the pages never shift as the selection moves.
    Widget arrow(
      IconData icon,
      String name,
      bool live,
      int to,
      AlignmentDirectional side,
    ) => SizedBox.square(
      dimension: target,
      child: Align(
        alignment: side,
        child: FrostedTargetSide(
          alignment: side,
          child: FrostedPressable(
            onPressed: live && onChanged != null ? () => go(to) : null,
            semanticLabel: name,
            radius: d / 2,
            child: SizedBox.square(
              dimension: d,
              child: FrostedDim(
                off: !(live || onChanged == null),
                child: Icon(icon, size: 18, color: t.colorScheme.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      // The targets stand edge to edge: a tap between two faces goes to
      // the nearer.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A pair of chevrons: [FrostedGlyphs.back] is an arrow, and
          // stood an arrow at one end against a chevron at the other.
          // The arrows keep to the row's ends, their targets growing inward.
          arrow(
            FrostedGlyphs.chevronLeft,
            words.previous,
            selectedIndex > 0,
            selectedIndex - 1,
            AlignmentDirectional.centerStart,
          ),
          for (final page in _shown(width, target))
            if (page == null)
              ExcludeSemantics(
                child: SizedBox(
                  width: _fold,
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
              FrostedPressable(
                onPressed: onChanged == null ? null : () => go(page),
                semanticLabel: words.page(page + 1, pageCount),
                selected: page == selectedIndex,
                radius: d / 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: d, minHeight: d),
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
          arrow(
            FrostedGlyphs.forward,
            words.next,
            selectedIndex < pageCount - 1,
            selectedIndex + 1,
            AlignmentDirectional.centerEnd,
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pageCount', pageCount))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('currentStep', currentStep))
      ..add(StringProperty('name', name))
      ..add(StringProperty('phase', phase, defaultValue: null));
  }
}

/// Which of a few pages is shown: [pageCount] dots, the selected one a short
/// capsule in the ink, the rest small rounds of the strong hairline. With
/// [onChanged] each dot takes a press (in a target of the floor, 40) and
/// the arrow keys move along them; read aloud as [semanticLabel] and the page's
/// place. Given a [position], the capsule moves with the pages as they
/// slide.
///
/// ```dart
/// FrostedPageDots(pageCount: 4, selectedIndex: page, semanticLabel: 'Welcome', onChanged: (i) => controller.animateToPage(i, duration: d, curve: c))
/// ```
class FrostedPageDots extends StatelessWidget {
  /// [pageCount] dots, [selectedIndex] (from 0) lit.
  const FrostedPageDots({
    required this.pageCount,
    required this.selectedIndex,
    required this.semanticLabel,
    this.onChanged,
    this.position,
    super.key,
  }) : assert(pageCount > 0, 'Page dots stand for at least one page.'),
       assert(
         selectedIndex >= 0 && selectedIndex < pageCount,
         'The page shown is one of the pages.',
       );

  /// How many pages.
  final int pageCount;

  /// The page shown, from 0.
  final int selectedIndex;

  /// What a screen reader calls the pages.
  final String semanticLabel;

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
        final d = (where - i).abs() % pageCount;
        final near = (1 - (d < pageCount - d ? d : pageCount - d)).clamp(
          0.0,
          1.0,
        );
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
        label: semanticLabel,
        value: words.page(selectedIndex + 1, pageCount),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedSpacing.s6,
          children: [for (var i = 0; i < pageCount; i++) dot(i)],
        ),
      );
    }
    final target = FrostedBreakpoints.hitTargetOf(context);
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pageCount; i++)
            FrostedPressable(
              onPressed: () => live(i),
              semanticLabel: words.page(i + 1, pageCount),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('pageCount', pageCount))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<ValueListenable<double>>(
          'position',
          position,
          defaultValue: null,
        ),
      );
  }
}
