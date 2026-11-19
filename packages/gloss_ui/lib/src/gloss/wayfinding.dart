/// Gloss's ways of saying where you are and going on: the breadcrumb, the
/// pagination trough, the step progress (sockets that fill with gel), the
/// page dots, the menubar and the command palette.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'fonts.dart';
import 'internal/entry_parts.dart';
import 'internal/menu_parts.dart';
import 'popovers.dart';
import 'surface.dart';
import 'theme.dart';

/// One step of a [GlossBreadcrumb].
@immutable
class GlossCrumb {
  /// A crumb reading [label] that goes back there on [onPressed].
  const GlossCrumb(this.label, {this.onPressed});

  /// Its words.
  final String label;

  /// Goes there; null on the last crumb (where you are).
  final VoidCallback? onPressed;
}

/// A breadcrumb: the way down to here, each step a jade link, the steps
/// parted by small chevrons engraved into the page, here in plain ink.
///
/// ```dart
/// GlossBreadcrumb(crumbs: [GlossCrumb('Recipes', onPressed: () {}), GlossCrumb('Lemon risotto')])
/// ```
class GlossBreadcrumb extends StatelessWidget {
  /// A breadcrumb of [crumbs], the last where you are.
  const GlossBreadcrumb({super.key, required this.crumbs, this.style});

  /// The steps, the first the top.
  final List<GlossCrumb> crumbs;

  /// Its own style, over [GlossThemeData.breadcrumbStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: GlossSpacing.tight,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GlossMetrics.rimRoom,
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                    size: 14,
                    color: c.inkSecondary,
                    shadows: [
                      Shadow(
                        color: c.letterpress,
                        offset: Offset(0, c.letterpressBelow ? 1 : -1),
                      ),
                    ],
                  ),
                ),
              ),
            if (i == crumbs.length - 1 || crumb.onPressed == null)
              Semantics(
                // The last crumb is the page: a screen reader hears so.
                selected: i == crumbs.length - 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GlossMetrics.rimRoom,
                  ),
                  child: Text(
                    crumb.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.secondary
                        .copyWith(
                          color: c.ink,
                          fontWeight: FontWeight.w600,
                          fontVariations: glossWeightAxis(FontWeight.w600),
                        )
                        .merge(
                          DesignStyleOf([
                            style,
                            theme.breadcrumbStyle,
                          ], const {}).textStyle,
                        ),
                  ),
                ),
              )
            else
              _CrumbLink(crumb: crumb, style: style),
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

class _CrumbLink extends StatelessWidget {
  const _CrumbLink({required this.crumb, required this.style});

  final GlossCrumb crumb;
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: crumb.onPressed,
      button: false,
      link: true,
      semanticLabel: crumb.label,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.breadcrumbStyle], states);
        final pressed = states.contains(WidgetState.pressed);
        final ink =
            layered.foreground ??
            (pressed ? Color.lerp(c.jadeInk, c.ink, 0.45)! : c.jadeInk);
        final clear = c.page.withValues(alpha: 0);
        return DesignTapTarget(
          child: AnimatedGlossSurface(
            face: GlossFace(
              top: clear,
              middle: clear,
              bottom: clear,
              foreground: ink,
              radius: 6,
              focus: glossFocusOf(
                c,
                focused: states.contains(WidgetState.focused),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlossMetrics.rimRoom,
              ),
              child: Text(
                crumb.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.secondary
                    .copyWith(
                      color: ink,
                      decoration: pressed ? TextDecoration.underline : null,
                      decorationColor: ink,
                    )
                    .merge(layered.textStyle),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The pages a pagination shows around [page] of [count] (0-based), with
/// null where a run is left out: always as many cells, wherever [page] is.
List<int?> _pageWindow(int page, int count, {int around = 1}) {
  if (count <= 2 * around + 5) return [for (var i = 0; i < count; i++) i];
  final shown = <int>{
    0,
    count - 1,
    for (var i = page - around; i <= page + around; i++)
      if (i >= 0 && i < count) i,
  };
  // Near an end, show enough at that end that a gap never hides one page.
  if (page <= around + 2) {
    for (var i = 0; i <= around * 2 + 2 && i < count; i++) {
      shown.add(i);
    }
  }
  if (page >= count - around - 3) {
    for (var i = count - 1; i >= count - around * 2 - 3 && i >= 0; i--) {
      shown.add(i);
    }
  }
  final sorted = shown.toList()..sort();
  final out = <int?>[];
  for (final (i, p) in sorted.indexed) {
    if (i > 0) {
      final gap = p - sorted[i - 1];
      if (gap == 2) {
        out.add(p - 1);
      } else if (gap > 2) {
        out.add(null);
      }
    }
    out.add(p);
  }
  return out;
}

/// Pagination: the pages set in a trough, the current one standing up as a
/// pearl key with jade figures, chevron beads at the ends. Runs of pages far
/// from here fold to an ellipsis.
///
/// ```dart
/// GlossPagination(page: 2, pageCount: 12, onChanged: (page) {})
/// ```
class GlossPagination extends StatelessWidget {
  /// Pagination at [page] (0-based) of [pageCount].
  const GlossPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.style,
  }) : assert(pageCount > 0),
       assert(page >= 0 && page < pageCount);

  /// The current page, from 0.
  final int page;

  /// How many pages.
  final int pageCount;

  /// The page to go to; null disables it.
  final ValueChanged<int>? onChanged;

  /// Its own style, over [GlossThemeData.paginationStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 420;
    final window = _pageWindow(page, pageCount, around: narrow ? 0 : 1);
    // The current page is a plate inset 4 in the trough, its corners 4
    // less (concentric), as a lit row in a well.
    const inset = 4.0;
    final key = theme.controlHeight - 2 * inset;
    final corner = GlossMetrics.fieldRadius + inset;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget cell({
      required String semanticLabel,
      required VoidCallback? onPressed,
      required Widget child,
      bool current = false,
    }) => DesignPressable(
      onPressed: onChanged == null ? null : onPressed,
      semanticLabel: semanticLabel,
      selected: current,
      semanticSelected: current,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [style, theme.paginationStyle],
          {...states, if (current) WidgetState.selected},
        );
        final disabled = states.contains(WidgetState.disabled);
        final clear = c.well.withValues(alpha: 0);
        var face = current
            ? GlossFace.pearl(c, radius: corner - inset)
            : GlossFace(
                top: clear,
                middle: clear,
                bottom: clear,
                foreground: c.ink,
                radius: corner - inset,
              );
        if (current && layered.fill != null) face = face.glazed(layered.fill!);
        // A page's tap is the trough's whole height (a finger's 48); its
        // plate stands inset 4 in it.
        return DesignTapTarget(
          child: SizedBox(
            height: theme.controlHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: inset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: key),
                child: AnimatedGlossSurface(
                  face: face.copyWith(
                    foreground:
                        layered.foreground ??
                        (disabled
                            ? c.inkDisabled
                            : current && c.brightness == Brightness.light
                            ? c.jadeInk
                            : c.ink),
                    travel: states.contains(WidgetState.pressed) ? 1 : 0,
                    focus: glossFocusOf(
                      c,
                      focused: states.contains(WidgetState.focused),
                    ),
                  ),
                  child: Center(widthFactor: 1, child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
    Widget figure(int p) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: GlossSpacing.small),
      child: Builder(
        builder: (context) => DesignCapCenter(
          capHeightFactor: glossCapHeightFactor,
          child: Text(
            '${p + 1}',
            style: theme.textTheme.label.copyWith(
              color: DefaultTextStyle.of(context).style.color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: theme.controlHeight,
        child: GlossSurface(
          face: GlossFace.well(c, radius: corner),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                cell(
                  semanticLabel: words.previousPageTooltip,
                  onPressed: page > 0 ? () => onChanged!(page - 1) : null,
                  child: Icon(
                    rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                    size: 18,
                  ),
                ),
                for (final p in window)
                  if (p == null)
                    SizedBox(
                      width: 24,
                      // Set on the figures' line, as they are.
                      child: Center(
                        child: ExcludeSemantics(
                          child: DesignCapCenter(
                            capHeightFactor: glossCapHeightFactor,
                            child: Text(
                              '…',
                              style: theme.textTheme.label.copyWith(
                                color: c.inkSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    cell(
                      semanticLabel: words.positionLabel(p + 1, pageCount),
                      onPressed: p == page ? () {} : () => onChanged!(p),
                      current: p == page,
                      child: figure(p),
                    ),
                cell(
                  semanticLabel: words.nextPageTooltip,
                  onPressed: page < pageCount - 1
                      ? () => onChanged!(page + 1)
                      : null,
                  child: Icon(
                    rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
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

/// Step progress: a socket for each step, joined by a groove pressed into
/// the page. Steps done fill with jade gel and a tick, the current one is
/// a jade gel bead with its number, the ones to come are empty sockets.
/// The groove fills with gel up to here.
///
/// ```dart
/// GlossStepProgress(steps: const ['Recipes', 'Days', 'List'], current: 1)
/// ```
class GlossStepProgress extends StatelessWidget {
  /// Progress through [steps], at [current] (0-based).
  const GlossStepProgress({
    super.key,
    required this.steps,
    required this.current,
    this.style,
  }) : assert(current >= 0);

  /// The steps' names.
  final List<String> steps;

  /// The step you are on, from 0; [steps]' length when all are done.
  final int current;

  /// Its own style, over [GlossThemeData.stepProgressStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final layered = DesignStyleOf([style, theme.stepProgressStyle], const {});
    const bead = 28.0;
    final narrow = MediaQuery.sizeOf(context).width < 420;
    return Semantics(
      container: true,
      label: steps.isEmpty
          ? null
          : words.positionLabel(
              (current + 1).clamp(1, steps.length),
              steps.length,
            ),
      // One groove runs behind the beads from the first's middle to the
      // last's (the beads cover it), its gel filled up to the current step.
      child: Stack(
        children: [
          if (steps.length > 1)
            Positioned(
              left: _slot / 2,
              right: _slot / 2,
              top: bead / 2 - 3,
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GlossSurface(face: GlossFace.well(c)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      end: (current / (steps.length - 1)).clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    builder: (context, fill, _) => FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: fill,
                      child: fill == 0
                          ? null
                          : Padding(
                              padding: const EdgeInsets.all(
                                GlossMetrics.hairline,
                              ),
                              child: GlossSurface(
                                face: GlossFace.gel(c).copyWith(
                                  lift: 0,
                                  lens: 0.5,
                                  glow: c.jadeGlow,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, step) in steps.indexed)
                _StepBead(
                  index: i,
                  label: step,
                  done: i < current,
                  here: i == current,
                  showLabel: !narrow || i == current,
                  size: bead,
                  tint: layered.fill,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // The room each step takes: its bead, and its name under it.
  static const double _slot = 72;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('steps', steps))
      ..add(IntProperty('current', current));
  }
}

class _StepBead extends StatelessWidget {
  const _StepBead({
    required this.index,
    required this.label,
    required this.done,
    required this.here,
    required this.showLabel,
    required this.size,
    required this.tint,
  });

  final int index;
  final String label;
  final bool done;
  final bool here;
  final bool showLabel;
  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    var face = done || here
        ? GlossFace.gel(c).copyWith(lift: here ? 0.8 : 0.4)
        : GlossFace.well(c);
    if ((done || here) && tint != null) face = face.glazed(tint!);
    return SizedBox(
      width: GlossStepProgress._slot,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: size,
            child: AnimatedGlossSurface(
              face: face.copyWith(
                foreground: done || here ? c.onJade : c.inkSecondary,
              ),
              child: Center(
                child: done
                    ? const Icon(LucideIcons.check, size: 16)
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: glossWeightAxis(FontWeight.w700),
                          color: here ? c.onJade : c.inkSecondary,
                        ),
                      ),
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: GlossSpacing.tight + 2),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.caption.copyWith(
                color: here ? c.ink : c.inkSecondary,
                fontWeight: here ? FontWeight.w600 : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Page dots: a small socket for each page pressed into the surface, the
/// current one a lozenge of jade gel. With [onChanged] each dot goes to its
/// page.
///
/// ```dart
/// GlossPageDots(count: 4, index: 1)
/// ```
class GlossPageDots extends StatelessWidget {
  /// Dots for [count] pages, at [index].
  const GlossPageDots({
    super.key,
    required this.count,
    required this.index,
    this.onChanged,
    this.style,
  });

  /// How many pages.
  final int count;

  /// The page shown.
  final int index;

  /// The page to go to; null: the dots only show.
  final ValueChanged<int>? onChanged;

  /// Its own style, over [GlossThemeData.pageDotsStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final layered = DesignStyleOf([style, theme.pageDotsStyle], const {});
    Widget dot(int i) {
      final on = i == index;
      var gel = GlossFace.gel(c).copyWith(lift: 0.3, lens: 0.6);
      if (layered.fill != null) gel = gel.glazed(layered.fill!);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: on ? 22 : 8,
        height: 8,
        child: AnimatedGlossSurface(face: on ? gel : GlossFace.well(c)),
      );
    }

    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          onChanged == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GlossSpacing.tight,
                  ),
                  child: dot(i),
                )
              : DesignPressable(
                  onPressed: () => onChanged!(i),
                  semanticLabel: words.positionLabel(i + 1, count),
                  selected: i == index,
                  semanticSelected: i == index,
                  builder: (context, states, _) => DesignTapTarget(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: GlossFocusHalo(
                        focused: states.contains(WidgetState.focused),
                        inside: true,
                        child: Center(child: dot(i)),
                      ),
                    ),
                  ),
                ),
      ],
    );
    if (onChanged != null) return dots;
    return Semantics(
      label: words.positionLabel(index + 1, count),
      child: ExcludeSemantics(child: dots),
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

/// One menu of a [GlossMenuBar].
@immutable
class GlossMenuBarMenu {
  /// A menu named [label] holding [items].
  const GlossMenuBarMenu(this.label, this.items);

  /// What the bar says.
  final String label;

  /// Its rows.
  final List<GlossMenuItem> items;
}

/// A menubar: a level chrome strip of menus for a desktop window. A press or
/// the keys open a menu, and while one is open the pointer moves along the
/// bar to open the others; Left and Right move between menus.
///
/// ```dart
/// GlossMenuBar(menus: [GlossMenuBarMenu('Recipe', [GlossMenuItem(label: 'New', onPressed: () {})])])
/// ```
class GlossMenuBar extends StatelessWidget {
  /// A menubar of [menus].
  const GlossMenuBar({super.key, required this.menus, this.style});

  /// The menus.
  final List<GlossMenuBarMenu> menus;

  /// Its own style, over [GlossThemeData.menuBarStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.menuBarStyle];
    final bar = DesignStyleOf(layers, const {});
    // The strip is chrome, as a bar is: level, in the bars' glaze, edged by
    // a hairline; only the menu a pointer is on rises as a plate.
    var strip = GlossFace(
      top: c.barTop,
      middle: c.barMiddle,
      bottom: c.barBottom,
      edge: c.hairline,
      foreground: c.ink,
      radius: 12,
    );
    if (bar.fill != null) strip = strip.glazed(bar.fill!);
    return DesignMenuBar(
      menus: [
        for (final menu in menus)
          DesignMenuEntry(
            label: menu.label,
            children: [
              for (final item in menu.items)
                DesignMenuEntry(
                  label: item.label,
                  onPressed: item.onPressed,
                  shortcut: item.shortcut,
                  data: item,
                ),
            ],
          ),
      ],
      // The strip holds its menus' plates 3 in from its rim; a plate is a
      // tap's height at least (a finger's on a touch screen).
      barBuilder: (context, items) => SizedBox(
        height: math.max(
          bar.minimumSize?.height ?? 40,
          DesignTapTargets.of(context).floorOn().height + 6,
        ),
        child: GlossSurface(
          face: strip,
          child: Padding(
            padding: const EdgeInsets.all(GlossMetrics.frameRim),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.menu) {
          final item = entry.data as GlossMenuItem?;
          return GlossMenuRow(
            label: entry.label,
            icon: item?.icon,
            isDestructiveAction: item?.isDestructiveAction ?? false,
            states: states,
            trailing: entry.shortcut == null ? null : Text(entry.shortcut!),
          );
        }
        final layered = DesignStyleOf(layers, states);
        final open = states.contains(WidgetState.selected);
        final plate = glossRowPlate(
          c,
          lit: open,
          pressed: states.contains(WidgetState.pressed),
          radius: 11,
        );
        return AnimatedGlossSurface(
          face: plate.copyWith(
            foreground: layered.foreground ?? c.ink,
            focus: glossFocusOf(
              c,
              focused: states.contains(WidgetState.focused),
            ),
          ),
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(horizontal: GlossSpacing.medium),
            child: Center(
              widthFactor: 1,
              child: Builder(
                builder: (context) => DesignCapCenter(
                  capHeightFactor: glossCapHeightFactor,
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    style: theme.textTheme.label
                        .copyWith(
                          color: DefaultTextStyle.of(context).style.color,
                        )
                        .merge(layered.textStyle),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      surfaceBuilder: (context, info, items) => glossPanelArrival(
        info,
        GlossMenuPanel(
          maxHeight: info.maxSize.height.clamp(120.0, 420.0),
          children: items,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<GlossMenuBarMenu>('menus', menus));
  }
}

/// One command of a [GlossCommandPalette].
@immutable
class GlossCommand {
  /// A command named [label] that does [onPressed].
  const GlossCommand({
    required this.label,
    required this.onPressed,
    this.group,
    this.icon,
    this.shortcut,
    this.keywords = const [],
  });

  /// What it says.
  final String label;

  /// What it does; null disables it.
  final VoidCallback? onPressed;

  /// The heading it lists under.
  final String? group;

  /// Its glyph.
  final IconData? icon;

  /// The keys that do it too.
  final String? shortcut;

  /// More words it is found by.
  final List<String> keywords;
}

/// A command palette: a search well over a list of commands, the best
/// matches first. Up and Down move the lit row and Enter runs it, the
/// focus staying in the well.
///
/// ```dart
/// GlossCommandPalette(commands: [GlossCommand(label: 'New recipe', onPressed: () {})])
/// ```
class GlossCommandPalette extends StatelessWidget {
  /// A palette of [commands].
  const GlossCommandPalette({
    super.key,
    required this.commands,
    this.onSelected,
    this.hint,
    this.emptyText,
    this.autofocus = false,
    this.style,
  });

  /// The commands.
  final List<GlossCommand> commands;

  /// Takes the chosen command; null runs its own onPressed.
  final ValueChanged<GlossCommand>? onSelected;

  /// What the empty well says; null: the platform's word for search.
  final String? hint;

  /// What it says when nothing matches; null: the platform's words.
  final String? emptyText;

  /// Whether the well takes the focus once built.
  final bool autofocus;

  /// Its own style, over [GlossThemeData.commandPaletteStyle].
  final GlossStyle? style;

  DesignCommandPalette _body(
    BuildContext context,
    ValueChanged<DesignCommand>? run,
  ) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final said = hint ?? words.searchFieldLabel;
    return DesignCommandPalette(
      commands: [
        for (final command in commands)
          DesignCommand(
            label: command.label,
            onPressed: command.onPressed,
            group: command.group,
            keywords: command.keywords,
            shortcut: command.shortcut,
            enabled: command.onPressed != null,
            data: command,
          ),
      ],
      autofocus: autofocus,
      onSelected: run,
      // The field is a node of its own: a screen reader outlines its well,
      // never the page round the palette.
      fieldBuilder: (context, field) => ListenableBuilder(
        listenable: field.focusNode,
        builder: (context, _) => Semantics(
          container: true,
          child: GlossEntryWell(
            focusNode: field.focusNode,
            face: glossEntryFace(theme, {
              if (field.focusNode.hasFocus) WidgetState.focused,
            }),
            leading: const Icon(LucideIcons.search),
            // Enter runs the lit command in onEditingComplete alone: the well
            // keeps the focus, and with no onSubmitted Flutter does not
            // restart its text input (a browser's restarted input takes no
            // typing).
            child: GlossEntryText(
              controller: field.controller,
              focusNode: field.focusNode,
              hint: said,
              semanticLabel: said,
              onEditingComplete: field.submit,
            ),
          ),
        ),
      ),
      itemBuilder: (context, command, states) {
        final given = command.data! as GlossCommand;
        return GlossMenuRow(
          label: given.label,
          icon: given.icon,
          states: states,
          trailing: given.shortcut == null ? null : Text(given.shortcut!),
        );
      },
      groupBuilder: (context, group) => Padding(
        padding: const EdgeInsets.fromLTRB(
          GlossSpacing.medium,
          GlossSpacing.medium,
          GlossSpacing.medium,
          GlossSpacing.tight,
        ),
        child: Text(
          group,
          style: glossLetterpress(
            theme.textTheme.caption.copyWith(
              color: c.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
            c,
          ),
        ),
      ),
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(GlossSpacing.medium),
        child: Text(
          emptyText ?? words.noResultsLabel,
          style: theme.textTheme.secondary,
        ),
      ),
      layoutBuilder: (context, field, results) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          const SizedBox(height: GlossSpacing.small),
          Flexible(child: results),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _palettePanel(
    context,
    style,
    _body(
      context,
      onSelected == null ? null : (c) => onSelected!(c.data! as GlossCommand),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('commands', commands.length))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

Widget _palettePanel(BuildContext context, GlossStyle? style, Widget child) {
  final theme = GlossTheme.of(context);
  final c = theme.colors;
  final layered = DesignStyleOf([style, theme.commandPaletteStyle], const {});
  var face = glossPanelFace(c, radius: 20);
  if (layered.fill != null) face = face.glazed(layered.fill!);
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: GlossSurface(
      face: face,
      child: Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.all(GlossSpacing.small),
        child: child,
      ),
    ),
  );
}

/// Opens the command palette over the page, a little above its middle,
/// closing when a command runs, on Escape or on a press outside.
///
/// ```dart
/// showGlossCommandPalette(context, commands: [GlossCommand(label: 'New recipe', onPressed: () {})])
/// ```
Future<void> showGlossCommandPalette(
  BuildContext context, {
  required List<GlossCommand> commands,
  String? hint,
  GlossStyle? style,
}) {
  final theme = GlossTheme.of(context);
  return showDesignCommandPalette(
    context: context,
    barrierColor: theme.colors.scrim,
    palette: (run) => GlossCommandPalette(
      commands: commands,
      hint: hint,
      autofocus: true,
      style: style,
    )._body(context, run),
    surfaceBuilder: (context, palette) => GlossTheme(
      data: theme,
      child: Padding(
        padding: const EdgeInsets.all(GlossSpacing.regular),
        child: Builder(
          builder: (context) => _palettePanel(context, style, palette),
        ),
      ),
    ),
  );
}
