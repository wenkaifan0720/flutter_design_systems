/// Clay's wayfinding: breadcrumbs, pages in a groove, the steps of a flow
/// as balls on a groove, page dots, the desktop menu bar and the command
/// palette.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'actions.dart' show ClayLink;
import 'button.dart';
import 'fonts.dart';
import 'internal/entry_parts.dart';
import 'internal/menu.dart';
import 'internal/words_fit.dart';
import 'popovers.dart' show ClayMenuItem;
import 'select.dart' show ClayMenuReveal;
import 'surface.dart';
import 'theme.dart';

/// One place in a [ClayBreadcrumb].
@immutable
class ClayCrumb {
  /// A place named [label], reached by [onPressed]; the last crumb, where
  /// the reader is, takes none.
  const ClayCrumb({required this.label, this.onPressed});

  /// Its name.
  final String label;

  /// Goes there; null for the place the reader is.
  final VoidCallback? onPressed;
}

/// Where a page sits: each place above it a link, a small chevron between,
/// the page itself last in plain ink.
///
/// ```dart
/// ClayBreadcrumb(crumbs: [ClayCrumb(label: 'Habits', onPressed: () {}), const ClayCrumb(label: 'Drink water')])
/// ```
class ClayBreadcrumb extends StatelessWidget {
  /// A trail of [crumbs], the current place last.
  const ClayBreadcrumb({super.key, required this.crumbs, this.style});

  /// The places, outermost first.
  final List<ClayCrumb> crumbs;

  /// This trail's own style, over [ClayThemeData.breadcrumbStyle]:
  /// `foreground` the current place.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.breadcrumbStyle], const {});
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: ClaySpacing.tight,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Icon(
                  rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                  size: 16,
                  color: c.inkSecondary,
                ),
              ),
            if (i < crumbs.length - 1 && crumb.onPressed != null)
              ClayLink(crumb.label, onPressed: crumb.onPressed)
            else
              Semantics(
                // The place the reader is: said as the current page.
                selected: i == crumbs.length - 1,
                child: DesignCapCenter(
                  capHeightFactor: clayCapHeightFactor,
                  child: Text(
                    crumb.label,
                    style: theme.textTheme.body
                        .copyWith(
                          color: layered.foreground ?? c.ink,
                          fontWeight: FontWeight.w600,
                          fontVariations: clayWeight(FontWeight.w600),
                        )
                        .merge(layered.textStyle),
                  ),
                ),
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

/// The page keys a [ClayPagination] shows for [page] of [count]: the first,
/// the last, the page and its neighbours, null for a gap.
// The pages a bar shows: the first, the last, the current one with
// [siblings] either side, and a gap (null) for each run left out; always
// 2 × [siblings] + 5 places, or every page when there are no more.
List<int?> _pagesShown(int page, int count, {int siblings = 1}) {
  final places = 2 * siblings + 5;
  if (count <= places) return [for (var i = 1; i <= count; i++) i];
  final run = places - 2;
  final from = math.max(page - siblings, 1);
  final to = math.min(page + siblings, count);
  if (from <= 3) {
    return [for (var i = 1; i <= run; i++) i, null, count];
  }
  if (to >= count - 2) {
    return [1, null, for (var i = count - run + 1; i <= count; i++) i];
  }
  return [1, null, for (var i = from; i <= to; i++) i, null, count];
}

/// Pages in a groove: the page the reader is on rises out of it, the
/// others lie in it as figures; arrows either side turn a page.
///
/// ```dart
/// ClayPagination(page: 3, pageCount: 12, onPageChanged: (page) {})
/// ```
class ClayPagination extends StatelessWidget {
  /// Pages 1 to [pageCount], [page] current.
  const ClayPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    this.style,
  }) : assert(pageCount >= 1),
       assert(page >= 1 && page <= pageCount);

  /// The current page, from 1.
  final int page;

  /// How many pages there are.
  final int pageCount;

  /// A page chosen; null turns the keys off.
  final ValueChanged<int>? onPageChanged;

  /// This bar's own style, over [ClayThemeData.paginationStyle]: `fill`
  /// the current page.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final side = theme.controlHeight - 8;
    Widget arrow(bool next) {
      final to = next ? page + 1 : page - 1;
      final can = to >= 1 && to <= pageCount && onPageChanged != null;
      return ClayIconButton.plain(
        onPressed: can ? () => onPageChanged!(to) : null,
        tooltip: next ? words.nextPageTooltip : words.previousPageTooltip,
        icon: Icon(
          next == rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
        ),
      );
    }

    // Each page takes a finger's tap: its key a little wider than its face.
    // Where seven places do not fit beside the arrows (a phone), the bar
    // keeps the first, the current and the last page.
    final key = side + 4;
    final ends = 2 * theme.controlHeight + 2 * ClaySpacing.tight + 4;
    return LayoutBuilder(
      builder: (context, box) => Semantics(
        container: true,
        explicitChildNodes: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            arrow(false),
            const SizedBox(width: ClaySpacing.tight),
            Flexible(
              child: SizedBox(
                height: theme.controlHeight,
                child: ClaySurface(
                  face: ClayFace.well(
                    c,
                    color: Color.lerp(c.well, c.track, 0.25),
                    radius: theme.controlHeight / 2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClaySpacing.hairline,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final p in _pagesShown(
                            page,
                            pageCount,
                            siblings: box.maxWidth - ends >= 7 * key ? 1 : 0,
                          ))
                            p == null
                                ? SizedBox(
                                    width: side * 0.75,
                                    child: Center(
                                      child: Text(
                                        '…',
                                        style: theme.textTheme.body.copyWith(
                                          color: c.inkSecondary,
                                        ),
                                      ),
                                    ),
                                  )
                                : _PageKey(
                                    label: words.formatDecimal(p),
                                    current: p == page,
                                    side: side,
                                    onPressed:
                                        onPageChanged == null || p == page
                                        ? null
                                        : () => onPageChanged!(p),
                                    semanticLabel:
                                        'Page ${words.formatDecimal(p)}',
                                    style: style,
                                  ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: ClaySpacing.tight),
            arrow(true),
          ],
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

class _PageKey extends StatelessWidget {
  const _PageKey({
    required this.label,
    required this.current,
    required this.side,
    required this.onPressed,
    required this.semanticLabel,
    required this.style,
  });

  final String label;
  final bool current;
  final double side;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      semanticSelected: current,
      // The current page is said, not pressed.
      enabled: onPressed != null || current,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [style, theme.paginationStyle],
          {...states, if (current) WidgetState.selected},
        );
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered);
        final focus = states.contains(WidgetState.focused) ? 1.0 : 0.0;
        final face = current
            ? ClayFace.raised(
                c,
                color: layered.fill ?? c.risen,
                radius: side / 2,
              ).copyWith(elevation: 0.7, focus: focus, focusColor: c.focus)
            : ClayFace.well(c, radius: side / 2).copyWith(
                color: c.well.withValues(alpha: pressed ? 1 : 0),
                lightOpacity: pressed ? null : 0,
                shadeOpacity: pressed ? null : (hovered ? 0.12 : 0),
                focus: focus,
                focusColor: c.focus,
              );
        final weight = current ? FontWeight.w600 : FontWeight.w400;
        // The key takes a tap over the groove's whole height and 2 px
        // beside its face; the face sits inset in it.
        return SizedBox(
          height: theme.controlHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClaySpacing.hairline,
              vertical: ClaySpacing.tight,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: side),
              child: AnimatedClaySurface(
                face: face,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClaySpacing.tight,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      label,
                      style: theme.textTheme.body.copyWith(
                        color: layered.foreground ?? c.ink,
                        fontWeight: weight,
                        fontVariations: clayWeight(weight),
                        fontFeatures: const [FontFeature.tabularFigures()],
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

/// The steps of a flow as balls along a groove: those done raised in coral
/// with a check, the current one raised in clay with its number, those to
/// come pressed in; each step's name under its ball.
///
/// ```dart
/// ClayStepProgress(steps: const ['Habit', 'Schedule', 'Reminder'], currentStep: 1)
/// ```
class ClayStepProgress extends StatelessWidget {
  /// [steps], the one at [currentStep] under way.
  const ClayStepProgress({
    super.key,
    required this.steps,
    required this.currentStep,
    this.style,
  });

  /// Each step's name.
  final List<String> steps;

  /// The step under way, from 0; [steps]' length once all are done.
  final int currentStep;

  /// This bar's own style, over [ClayThemeData.stepProgressStyle]: `fill`
  /// the steps done.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.stepProgressStyle], const {});
    final done = layered.fill ?? c.accent;
    const ball = 32.0;
    return Semantics(
      container: true,
      label:
          'Step ${math.min(currentStep + 1, steps.length)} of ${steps.length}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, name) in steps.indexed)
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: ball,
                      child: LayoutBuilder(
                        // The cell's whole width, so the groove starts at
                        // its ball's edge, not at the next cell's.
                        builder: (context, box) => SizedBox(
                          width: box.maxWidth,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // One groove across the gap from this ball to the
                              // next (the steps are a cell apart), filled where
                              // the flow has passed.
                              if (i < steps.length - 1)
                                PositionedDirectional(
                                  start: box.maxWidth / 2 + ball / 2 + 4,
                                  width: math.max(0, box.maxWidth - ball - 8),
                                  top: (ball - 6) / 2,
                                  height: 6,
                                  child: _Run(
                                    filled: i < currentStep,
                                    color: done,
                                  ),
                                ),
                              SizedBox.square(
                                dimension: ball,
                                child: AnimatedClaySurface(
                                  face: i < currentStep
                                      ? ClayFace.raised(
                                          c,
                                          color: done,
                                          radius: ball / 2,
                                        ).copyWith(elevation: 0.7)
                                      : i == currentStep
                                      ? ClayFace.raised(
                                          c,
                                          radius: ball / 2,
                                        ).copyWith(
                                          elevation: 0.7,
                                          focus: 1,
                                          focusColor: c.accentInk,
                                        )
                                      : ClayFace.well(
                                          c,
                                          color: c.track,
                                          radius: ball / 2,
                                        ),
                                  child: Center(
                                    child: i < currentStep
                                        ? Icon(
                                            LucideIcons.check,
                                            size: 16,
                                            color: c.onColor(done),
                                          )
                                        : Text(
                                            '${i + 1}',
                                            style: theme.textTheme.secondary
                                                .copyWith(
                                                  color: i == currentStep
                                                      ? c.ink
                                                      : c.inkSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontVariations: clayWeight(
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: ClaySpacing.small),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ClaySpacing.tight,
                      ),
                      child: _StepName(
                        name: name,
                        style: theme.textTheme.caption.copyWith(
                          color: i == currentStep ? c.ink : c.inkSecondary,
                          fontWeight: i == currentStep
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('steps', steps.length))
      ..add(IntProperty('currentStep', currentStep));
  }
}

// A step's name under its ball: it wraps between words; a word too wide for
// its cell (large text on a phone) lowers the name's size until it fits,
// rather than break across two lines.
class _StepName extends StatelessWidget {
  const _StepName({required this.name, required this.style});

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Text(
      name,
      textAlign: TextAlign.center,
      style: style,
      textScaler: clayScalerToFit(
        MediaQuery.textScalerOf(context),
        fontSize: style.fontSize ?? 14,
        widest: clayWidestWord(context, [name], style),
        room: box.maxWidth,
      ),
    ),
  );
}

class _Run extends StatelessWidget {
  const _Run({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = ClayTheme.of(context).colors;
    return ClaySurface(
      face: filled
          ? ClayFace.raised(
              c,
              color: color,
              radius: 3,
            ).copyWith(shadowOpacity: 0)
          : ClayFace.well(
              c,
              color: Color.lerp(c.well, c.track, 0.5),
              radius: 3,
            ),
    );
  }
}

/// Which page of a few is showing: small cups pressed into the clay, the
/// current one a raised coral pill. With [onPageChanged] a dot takes a tap.
///
/// ```dart
/// ClayPageDots(pageCount: 4, page: 1, onPageChanged: (page) {})
/// ```
class ClayPageDots extends StatelessWidget {
  /// [pageCount] dots, [page] current.
  const ClayPageDots({
    super.key,
    required this.pageCount,
    required this.page,
    this.onPageChanged,
    this.style,
  });

  /// How many pages.
  final int pageCount;

  /// The current page, from 0.
  final int page;

  /// A page chosen; null: the dots only show.
  final ValueChanged<int>? onPageChanged;

  /// These dots' own style, over [ClayThemeData.pageDotsStyle]: `fill` the
  /// current one.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.pageDotsStyle], const {});
    final fill = layered.fill ?? c.accent;
    Widget dot(int i, Set<WidgetState> states) {
      final current = i == page;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: current ? 22 : 8,
        height: 8,
        child: AnimatedClaySurface(
          face: current
              ? ClayFace.raised(
                  c,
                  color: fill,
                  radius: 4,
                ).copyWith(elevation: 0.5)
              : ClayFace.well(c, color: c.track, radius: 4).copyWith(
                  focus: states.contains(WidgetState.focused) ? 1 : 0,
                  focusColor: c.focus,
                ),
        ),
      );
    }

    final words = RawWidgetsLocalizations.of(context);
    return Semantics(
      container: true,
      label:
          'Page ${words.formatDecimal(page + 1)} of '
          '${words.formatDecimal(pageCount)}',
      explicitChildNodes: onPageChanged != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pageCount; i++)
            onPageChanged == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClaySpacing.tight,
                    ),
                    child: ExcludeSemantics(child: dot(i, const {})),
                  )
                : RawButton(
                    onPressed: i == page ? null : () => onPageChanged!(i),
                    enabled: true,
                    semanticLabel: 'Page ${words.formatDecimal(i + 1)}',
                    semanticSelected: i == page,
                    // The platform's floor: a finger's 44, a pointer's 24.
                    builder: (context, states, _) => TapTargetPadding(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClaySpacing.tight,
                        ),
                        child: dot(i, states),
                      ),
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
      ..add(IntProperty('page', page));
  }
}

/// One menu of a [ClayMenuBar].
@immutable
class ClayMenuBarMenu {
  /// A menu named [label] holding [items].
  const ClayMenuBarMenu({required this.label, required this.items});

  /// Its name on the bar.
  final String label;

  /// What it holds.
  final List<ClayMenuItem> items;

  @override
  String toString() => 'ClayMenuBarMenu($label)';
}

/// The desktop's menu bar: a slab of clay along the top, each menu's name a
/// key that dents when open; its menu floats under it on clay. The arrows
/// walk the bar and its menus.
///
/// ```dart
/// ClayMenuBar(menus: [ClayMenuBarMenu(label: 'Habit', items: [ClayMenuItem(label: 'New habit', onPressed: () {})])])
/// ```
class ClayMenuBar extends StatelessWidget {
  /// A bar of [menus].
  const ClayMenuBar({super.key, required this.menus, this.style});

  /// The menus, in order.
  final List<ClayMenuBarMenu> menus;

  /// This bar's own style, over [ClayThemeData.menuBarStyle]: `fill` the
  /// slab.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.menuBarStyle];
    final bar = DesignStyleOf(layers, const {});
    const inset = 4.0;
    return RawMenuBar(
      menus: [
        for (final menu in menus)
          RawMenuEntry(
            label: menu.label,
            children: [
              for (final item in menu.items)
                RawMenuEntry(
                  label: item.label,
                  onPressed: item.onPressed,
                  shortcut: item.shortcut,
                  isDestructiveAction: item.isDestructiveAction,
                  data: item,
                ),
            ],
          ),
      ],
      barBuilder: (context, items) => SizedBox(
        height: math.max(
          bar.minimumSize?.height ?? 44,
          DesignTapTargets.of(context).floorOn().height + 2 * inset,
        ),
        child: ClaySurface(
          face: ClayFace.raised(
            c,
            color: bar.fill,
            radius: ClayRadius.control,
          ).copyWith(elevation: 0.6),
          child: Padding(
            padding: const EdgeInsets.all(inset),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == RawMenuLevel.menu) {
          final item = entry.data as ClayMenuItem?;
          return ClayMenuRow(
            label: entry.label,
            leading: item?.icon == null ? null : Icon(item!.icon),
            isDestructiveAction: entry.isDestructiveAction,
            states: states,
            trailing: entry.shortcut == null ? null : Text(entry.shortcut!),
          );
        }
        final layered = DesignStyleOf(layers, states);
        final open = states.contains(WidgetState.selected);
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered);
        final show = open || pressed ? 1.0 : (hovered ? 0.45 : 0.0);
        final well = ClayFace.well(c, radius: ClayRadius.control - inset);
        return AnimatedClaySurface(
          face: well.copyWith(
            color: well.color.withValues(alpha: well.color.a * show),
            lightOpacity: well.lightOpacity * show,
            shadeOpacity: well.shadeOpacity * show,
            focus: states.contains(WidgetState.focused) ? 1 : 0,
            focusColor: c.focus,
          ),
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(horizontal: ClaySpacing.medium),
            child: Center(
              widthFactor: 1,
              child: DesignCapCenter(
                capHeightFactor: clayCapHeightFactor,
                child: Text(
                  entry.label,
                  maxLines: 1,
                  style: theme.textTheme.label
                      .copyWith(color: layered.foreground ?? c.ink)
                      .merge(layered.textStyle),
                ),
              ),
            ),
          ),
        );
      },
      surfaceBuilder: (context, info, items) => ClayMenuReveal(
        info: info,
        child: clayMenuPanel(
          context,
          items,
          maxHeight: info.maxSize.height.clamp(120.0, 420.0),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<ClayMenuBarMenu>('menus', menus));
  }
}

/// One command of a [ClayCommandPalette].
@immutable
class ClayCommand {
  /// A command named [label] that does [onPressed].
  const ClayCommand({
    required this.label,
    required this.onPressed,
    this.group,
    this.icon,
    this.shortcut,
    this.keywords = const [],
  });

  /// Its name.
  final String label;

  /// What it does; null shows it off.
  final VoidCallback? onPressed;

  /// The heading it is listed under.
  final String? group;

  /// Its glyph.
  final IconData? icon;

  /// Its keys, as the reader's keyboard writes them (⌘N).
  final String? shortcut;

  /// Other words it is found by.
  final List<String> keywords;
}

/// A command palette: a search well over the commands it finds, grouped,
/// on floating clay. Up and Down walk the list; Enter runs the lit one.
/// [showClayCommandPalette] opens it over the page.
///
/// ```dart
/// ClayCommandPalette(commands: [ClayCommand(label: 'New habit', onPressed: () {})])
/// ```
class ClayCommandPalette extends StatelessWidget {
  /// A palette of [commands].
  const ClayCommandPalette({
    super.key,
    required this.commands,
    this.onSelected,
    this.hintText,
    this.emptyText,
    this.autofocus = false,
    this.style,
  });

  /// The commands it searches.
  final List<ClayCommand> commands;

  /// A command run (after its own [ClayCommand.onPressed]).
  final ValueChanged<ClayCommand>? onSelected;

  /// What the empty well says; null: "Search".
  final String? hintText;

  /// What it says when nothing matches.
  final String? emptyText;

  /// Whether the well takes the focus once built.
  final bool autofocus;

  /// This palette's own style, over [ClayThemeData.commandPaletteStyle].
  final ClayStyle? style;

  RawCommandPalette _body(BuildContext context, ValueChanged<RawCommand>? run) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final said = hintText ?? words.searchFieldLabel;
    return RawCommandPalette(
      commands: [
        for (final command in commands)
          RawCommand(
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
          child: ClayEntryWell(
            focusNode: field.focusNode,
            face: clayEntryFace(theme, {
              if (field.focusNode.hasFocus) WidgetState.focused,
            }),
            leading: const Icon(LucideIcons.search),
            // Enter runs the lit command and the well keeps the focus.
            child: ClayEntryText(
              controller: field.controller,
              focusNode: field.focusNode,
              hintText: said,
              semanticLabel: said,
              onEditingComplete: field.submit,
            ),
          ),
        ),
      ),
      itemBuilder: (context, command, states) {
        final given = command.data! as ClayCommand;
        return ClayMenuRow(
          label: given.label,
          leading: given.icon == null ? null : Icon(given.icon),
          // The lit command sinks into a soft well with no rim: the focus
          // stays in the field, and only one thing on screen is ringed.
          states: {
            for (final s in states)
              s == WidgetState.focused ? WidgetState.hovered : s,
          },
          trailing: given.shortcut == null ? null : Text(given.shortcut!),
        );
      },
      groupBuilder: (context, group) => Padding(
        padding: const EdgeInsets.fromLTRB(
          ClaySpacing.medium,
          ClaySpacing.medium,
          ClaySpacing.medium,
          ClaySpacing.tight,
        ),
        child: Text(
          group,
          style: theme.textTheme.caption.copyWith(
            color: c.inkSecondary,
            fontWeight: FontWeight.w600,
            fontVariations: clayWeight(FontWeight.w600),
          ),
        ),
      ),
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(ClaySpacing.medium),
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
          const SizedBox(height: ClaySpacing.small),
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
      onSelected == null ? null : (c) => onSelected!(c.data! as ClayCommand),
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

Widget _palettePanel(BuildContext context, ClayStyle? style, Widget child) {
  final theme = ClayTheme.of(context);
  final c = theme.colors;
  final layered = DesignStyleOf([style, theme.commandPaletteStyle], const {});
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: ClaySurface(
      face: clayMenuFace(c).copyWith(
        color: layered.fill,
        radius: clayRadiusOf(layered.shape, ClayRadius.extraLarge),
      ),
      child: Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.all(ClaySpacing.small),
        child: child,
      ),
    ),
  );
}

/// Opens a [ClayCommandPalette] of [commands] over the page, the page
/// dimmed under it; a command chosen closes it and runs.
Future<void> showClayCommandPalette(
  BuildContext context, {
  required List<ClayCommand> commands,
  String? hintText,
  ClayStyle? style,
}) {
  final theme = ClayTheme.of(context);
  return showDesignCommandPalette(
    context: context,
    barrierColor: theme.colors.scrim,
    palette: (run) => ClayCommandPalette(
      commands: commands,
      hintText: hintText,
      autofocus: true,
      style: style,
    )._body(context, run),
    surfaceBuilder: (context, palette) => ClayTheme(
      data: theme,
      child: Padding(
        padding: const EdgeInsets.all(ClaySpacing.regular),
        child: Builder(
          builder: (context) => _palettePanel(context, style, palette),
        ),
      ),
    ),
  );
}
