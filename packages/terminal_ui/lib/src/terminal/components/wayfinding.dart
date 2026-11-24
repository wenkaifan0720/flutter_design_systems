/// Where you are and how to move on: a path, pages, page dots, a run of
/// steps, a menubar, a rail of numbered destinations, and the shell that
/// picks the bar, the rail or the side pane by the screen's width.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/menu_marks.dart';
import '../internal/shell_face.dart';
import '../primitives/control.dart';
import '../primitives/menu.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';
import 'button.dart';
import 'key_hint.dart';
import 'navigation.dart';
import 'pane.dart';

/// One step of a [TermBreadcrumb]: its words, and where pressing it goes
/// (null for the last, where you are).
typedef TermCrumb = ({String label, VoidCallback? onPressed});

/// Where you are, as a path: `~/atlas-api/runs/#1482`, each step back a
/// link, the last one bold, where you are. It reads left to right in any
/// app, as a path does.
///
/// ```dart
/// TermBreadcrumb(crumbs: [
///   (label: '~', onPressed: goHome),
///   (label: 'atlas-api', onPressed: openProject),
///   (label: '#1482', onPressed: null),
/// ])
/// ```
class TermBreadcrumb extends StatelessWidget {
  /// A path through [crumbs].
  const TermBreadcrumb({super.key, required this.crumbs, this.style});

  /// The steps, from the root.
  final List<TermCrumb> crumbs;

  /// Overrides, over the theme's [TermThemeData.breadcrumbStyle]:
  /// `foreground` (the steps back) and `edge` (the `/` between them).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final rest = TermStyleOf([style, theme.breadcrumbStyle], const {});
    return Semantics(
      container: true,
      label: TermLocalizations.of(context).breadcrumbLabel,
      explicitChildNodes: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (i, crumb) in crumbs.indexed) ...[
              if (i > 0)
                ExcludeSemantics(
                  child: Text(
                    '/',
                    style: theme.textStyle.copyWith(
                      color: rest.edge ?? theme.rule,
                    ),
                  ),
                ),
              if (i == crumbs.length - 1 || crumb.onPressed == null)
                Semantics(
                  label: crumb.label,
                  excludeSemantics: true,
                  child: Text(crumb.label, style: theme.boldStyle),
                )
              else
                TermTapTarget(
                  child: RawButton(
                    onPressed: crumb.onPressed,
                    link: true,
                    button: false,
                    semanticLabel: crumb.label,
                    excludeSemantics: true,
                    mouseCursor: crumb.onPressed == null
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    builder: (context, states, _) {
                      final own = TermStyleOf([
                        style,
                        theme.breadcrumbStyle,
                      ], states);
                      // A press: the crumb in inverse video. The keyboard's
                      // focus: the cursor behind it, half a cell past it.
                      final lit = states.contains(WidgetState.pressed);
                      final focused =
                          !lit && states.contains(WidgetState.focused);
                      final ink = own.foreground ?? theme.accent;
                      return TermCursorSpan(
                        focus: focused ? 1 : 0,
                        child: ColoredBox(
                          color: lit ? ink : const Color(0x00000000),
                          child: Text(
                            crumb.label,
                            style: theme.textStyle.copyWith(
                              color: lit
                                  ? theme.background
                                  : focused
                                  ? theme.onAccent
                                  : ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('crumbs', crumbs.length));
  }
}

/// Pages, as a pager prints them: `‹  1 … 4 [5] 6 … 21  ›`, the page you
/// are on in inverse video, a gap for the pages between; where the line is
/// short, `‹ 5/21 ›`. A screen reader hears each page's number and which is
/// current.
///
/// ```dart
/// TermPagination(page: 5, pageCount: 21, onChanged: (p) => setState(() => page = p))
/// ```
class TermPagination extends StatelessWidget {
  /// Pages 1 to [pageCount], on [page].
  const TermPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.style,
  }) : assert(pageCount >= 1),
       assert(page >= 1 && page <= pageCount);

  /// The page you are on, from 1.
  final int page;

  /// How many pages.
  final int pageCount;

  /// Called with the page chosen; null disables it.
  final ValueChanged<int>? onChanged;

  /// Overrides, over the theme's [TermThemeData.paginationStyle]: `fill`
  /// (the current page) and `foreground` (the numbers).
  final TermStyle? style;

  List<int?> _shown() {
    final out = <int?>[];
    int? last;
    for (var p = 1; p <= pageCount; p++) {
      final keep = p == 1 || p == pageCount || (p - page).abs() <= 1;
      if (!keep) continue;
      if (last != null && p - last > 1) out.add(null);
      out.add(p);
      last = p;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final words = TermLocalizations.of(context);
    final grid = context.termGrid;
    final go = onChanged;
    final prev = go != null && page > 1 ? () => go(page - 1) : null;
    final next = go != null && page < pageCount ? () => go(page + 1) : null;
    return LayoutBuilder(
      builder: (context, c) {
        // Every page a target a finger can hit (or a pointer's line): when
        // the row of them would not fit, the count stands in for them.
        final floor = grid.ceil(RawTapTargets.of(context).floorOn()).width;
        double slot(int? p) => p == null
            ? grid.cols(3)
            : math.max(floor, grid.cols('$p'.length + 3));
        final needed =
            2 * math.max(floor, grid.cols(3)) +
            _shown().fold(0.0, (sum, p) => sum + slot(p));
        final narrow = c.maxWidth.isFinite && needed > c.maxWidth;
        return Semantics(
          container: true,
          label: words.paginationLabel,
          explicitChildNodes: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TermIconButton(
                glyph: '‹',
                semanticLabel: words.previousPageLabel,
                onPressed: prev,
              ),
              if (narrow)
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: grid.cellWidth,
                  ),
                  child: Text(
                    '$page/$pageCount',
                    semanticsLabel: words.pagePositionLabel(page, pageCount),
                  ),
                )
              else
                for (final p in _shown())
                  if (p == null)
                    SizedBox(
                      width: grid.cols(3),
                      height: grid.lineHeight,
                      child: Center(
                        child: ExcludeSemantics(
                          child: Text('…', style: theme.dimStyle),
                        ),
                      ),
                    )
                  else
                    TermTapTarget(
                      child: RawButton(
                        onPressed: go == null || p == page ? null : () => go(p),
                        selected: p == page,
                        semanticSelected: p == page,
                        semanticLabel: words.pageLabel(p),
                        excludeSemantics: true,
                        // The page open now takes no press, so no click.
                        mouseCursor: go == null || p == page
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                        builder: (context, states, _) {
                          final own = TermStyleOf([
                            style,
                            theme.paginationStyle,
                          ], states);
                          return TermStateSprings(
                            pressed: states.contains(WidgetState.pressed),
                            focused: states.contains(WidgetState.focused),
                            builder: (context, press, focus) => TermCellFace(
                              label: '$p',
                              on: p == page,
                              enabled: go != null,
                              press: press,
                              focus: focus,
                              fill: own.fill,
                              foreground: own.foreground,
                            ),
                          );
                        },
                      ),
                    ),
              TermIconButton(
                glyph: '›',
                semanticLabel: words.nextPageLabel,
                onPressed: next,
              ),
            ],
          ),
        );
      },
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

/// Where you are in a short run of pages: `· · ● · ·`, a cell each, the
/// current one solid in the accent. With [onChanged] each dot is a target.
///
/// ```dart
/// TermPageDots(count: 5, index: 2)
/// ```
class TermPageDots extends StatelessWidget {
  /// [count] dots, [index] current.
  const TermPageDots({
    super.key,
    required this.count,
    required this.index,
    this.onChanged,
    this.style,
  });

  /// How many pages.
  final int count;

  /// The current page, from 0.
  final int index;

  /// Called with a dot pressed; null: the dots only show.
  final ValueChanged<int>? onChanged;

  /// Overrides, over the theme's [TermThemeData.paginationStyle]: `fill`
  /// (the current dot) and `foreground` (the others).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final words = TermLocalizations.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.paginationStyle], const {});
    // A dot: pressed, its cell in inverse video; under the keyboard's
    // focus, the cursor over it, half a cell past it each side.
    Widget dot(int i, [Set<WidgetState> states = const {}]) {
      final ink = i == index
          ? own.fill ?? theme.accent
          : own.foreground ?? theme.dim;
      return SizedBox(
        width: grid.cols(2),
        height: grid.lineHeight,
        child: Center(
          child: TermStateSprings(
            pressed: states.contains(WidgetState.pressed),
            focused: states.contains(WidgetState.focused),
            builder: (context, press, focus) => TermCursorSpan(
              focus: focus * (1 - press),
              child: ColoredBox(
                color: ink.withValues(alpha: ink.a * press),
                child: Text(
                  i == index ? '●' : '·',
                  style: theme.textStyle.copyWith(
                    color: Color.lerp(
                      termCursorInk(theme, ink, focus * (1 - press)),
                      theme.background,
                      press,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: words.pagePositionLabel(index + 1, count),
      excludeSemantics: onChanged == null,
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            if (onChanged == null)
              ExcludeSemantics(child: dot(i))
            else
              TermTapTarget(
                child: RawButton(
                  onPressed: () => onChanged!(i),
                  selected: i == index,
                  semanticLabel: words.pageLabel(i + 1),
                  excludeSemantics: true,
                  mouseCursor: SystemMouseCursors.click,
                  builder: (context, states, _) => dot(i, states),
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
      ..add(IntProperty('index', index));
  }
}

/// How a step of [TermSteps] stands.
enum TermStepState {
  /// Not reached: `○`, dim.
  upcoming,

  /// Where you are: `●` in the accent.
  current,

  /// Done: `✓` in green.
  done,

  /// Failed: `✗` in red.
  failed,
}

/// A run of steps, as a wizard or a pipeline shows them:
/// `✓ source ── ✓ build ── ● test ── ○ deploy`, each with its mark so it
/// reads without colour; on a narrow screen, one under another.
///
/// ```dart
/// TermSteps(steps: const [
///   (label: 'source', state: TermStepState.done),
///   (label: 'test', state: TermStepState.current),
///   (label: 'deploy', state: TermStepState.upcoming),
/// ])
/// ```
class TermSteps extends StatelessWidget {
  /// The [steps], in order.
  const TermSteps({super.key, required this.steps, this.style});

  /// Each step's words and state.
  final List<({String label, TermStepState state})> steps;

  /// Overrides, over the theme's [TermThemeData.stepsStyle]: `fill` (the
  /// current step's mark), `foreground` (the words) and `edge` (the rule
  /// between steps).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.stepsStyle], const {});
    final rule = own.edge ?? theme.rule;
    Widget step(int i) {
      final s = steps[i];
      final (mark, ink) = switch (s.state) {
        TermStepState.upcoming => ('○', theme.dim),
        TermStepState.current => ('●', own.fill ?? theme.accent),
        TermStepState.done => ('✓', theme.success),
        TermStepState.failed => ('✗', theme.danger),
      };
      final words = TermLocalizations.of(context);
      final said = switch (s.state) {
        TermStepState.upcoming => words.stepUpcomingLabel,
        TermStepState.current => words.stepCurrentLabel,
        TermStepState.done => words.stepDoneLabel,
        TermStepState.failed => words.stepFailedLabel,
      };
      return Semantics(
        label: words.stepLabel(i + 1, steps.length, s.label, said),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mark, style: theme.boldStyle.copyWith(color: ink)),
            SizedBox(width: grid.cellWidth),
            Text(
              s.label,
              style:
                  (s.state == TermStepState.current
                          ? theme.boldStyle
                          : theme.textStyle)
                      .copyWith(
                        color: s.state == TermStepState.upcoming
                            ? theme.dim
                            : own.foreground ?? theme.foreground,
                      ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        var cols = 0;
        for (final s in steps) {
          cols += 2 + s.label.length + 4;
        }
        final fits = !c.maxWidth.isFinite || grid.cols(cols) <= c.maxWidth;
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  ExcludeSemantics(
                    child: Text(
                      '│',
                      style: theme.textStyle.copyWith(color: rule),
                    ),
                  ),
                step(i),
              ],
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                ExcludeSemantics(
                  child: Text(
                    ' ── ',
                    style: theme.textStyle.copyWith(color: rule),
                  ),
                ),
              step(i),
            ],
          ],
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('steps', steps.length));
  }
}

// A row of a menu ui_core opens (a menubar's, a context menu's): a submenu
// marked `›`, its key dim at the end, a check before a checked one.
Widget _menuRow(
  BuildContext context,
  RawMenuEntry entry,
  Set<WidgetState> states,
) => TermMenuRow(
  label: entry.isSubmenu ? '${entry.label} ›' : entry.label,
  states: states,
  trailing: termKeysShown(context) ? entry.shortcut : null,
  checked: entry.checked,
  danger: entry.isDestructiveAction,
);

// A rule across a menu, on a line of its own.
Widget _menuDivider(BuildContext context) {
  final theme = TermTheme.of(context);
  final grid = context.termGrid;
  return SizedBox(
    height: grid.lineHeight,
    child: Center(
      child: Container(height: termStrokeWidth(theme, grid), color: theme.rule),
    ),
  );
}

// A menu's raised pane, revealed from its top line.
Widget _menuPlate(
  BuildContext context,
  RawPopoverInfo info,
  List<Widget> items,
) => TermMenuReveal(
  info: info,
  child: ConstrainedBox(
    constraints: BoxConstraints(minWidth: context.termGrid.cols(24)),
    child: TermPane(
      raised: true,
      focused: true,
      // A cell inside the frame each side, so a lit row's bar stands clear
      // of the frame's sides as of its top and bottom lines.
      padding: const TermInset(),
      // A letter takes the keys to the next item it starts: ui_core's menu
      // does that. One row current, shown once the keys or the pointer
      // move.
      child: TermMenuMarks(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items,
          ),
        ),
      ),
    ),
  ),
);

/// A menu over [child] that opens where it is asked for: at the pointer on
/// a right click or a long press, at the focused widget on Shift+F10 or the
/// Menu key, and from a screen reader's "Show menu". Its rows are a
/// [TermMenuBar] menu's: [menuChildren] are commands, submenus (`›`),
/// checks and rules, each command's key dim at the end.
///
/// The behaviour is ui_core's `RawContextMenu`: the arrows walk the
/// rows and into submenus, a letter goes to the next row it starts, Return
/// picks, Escape closes; one is open at a time, and on the web the
/// browser's own menu stays shut over [child]. Terminal paints the rows and
/// the raised pane.
///
/// ```dart
/// TermContextMenu(
///   menuChildren: [
///     RawMenuEntry(label: 'rerun', shortcut: 'r', onPressed: rerun),
///     RawMenuEntry(label: 'copy link', onPressed: copy),
///   ],
///   child: const Text('run #1482'),
/// )
/// ```
class TermContextMenu extends StatelessWidget {
  /// A menu of [menuChildren] over [child].
  const TermContextMenu({
    super.key,
    required this.menuChildren,
    required this.child,
    this.semanticLabel,
  });

  /// The menu's rows.
  final List<RawMenuEntry> menuChildren;

  /// The region it opens over.
  final Widget child;

  /// What a screen reader calls the menu.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    TermMenuMarks.watchInput();
    return RawContextMenu(
      menuChildren: menuChildren,
      semanticLabel: semanticLabel,
      dampingRatio: TermMotion.reveal.dampingRatio,
      stiffness: TermMotion.reveal.stiffness,
      itemBuilder: (context, entry, level, states) =>
          _menuRow(context, entry, states),
      dividerBuilder: _menuDivider,
      surfaceBuilder: _menuPlate,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('menuChildren', menuChildren.length));
  }
}

/// A menubar, as a full-screen terminal program draws one: the menus'
/// names along the top line, the open one in inverse video, each menu a
/// raised pane revealed in place under its name; the arrows move along and
/// into them, Escape closes.
///
/// ```dart
/// TermMenuBar(menus: [
///   RawMenuEntry(label: 'run', children: [
///     RawMenuEntry(label: 'rerun', shortcut: 'R', onPressed: rerun),
///   ]),
/// ])
/// ```
class TermMenuBar extends StatelessWidget {
  /// A menubar of [menus].
  const TermMenuBar({super.key, required this.menus, this.style});

  /// The menus, each with its items as children.
  final List<RawMenuEntry> menus;

  /// Overrides for the menus' names, over the theme's
  /// [TermThemeData.menuBarStyle]: `fill` (an open or lit name) and
  /// `foreground` (the names). The menus' rows read
  /// [TermThemeData.menuStyle].
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    TermMenuMarks.watchInput();
    return RawMenuBar(
      menus: menus,
      itemBuilder: (context, entry, level, states) {
        if (level == RawMenuLevel.menu) {
          return _menuRow(context, entry, states);
        }
        final own = TermStyleOf([style, theme.menuBarStyle], states);
        // The open menu's name in inverse video; the keyboard's focus the
        // cursor over it (on the open one, hollow).
        final lit = states.contains(WidgetState.selected);
        final cursor = entry.enabled && states.contains(WidgetState.focused)
            ? 1.0
            : 0.0;
        final ink = own.foreground ?? theme.foreground;
        final bar = own.fill ?? ink;
        // A menu's name is one line; what a tap reaches is the floor, so
        // under a finger the bar is two lines with the names in its middle.
        return TermTapTarget(
          child: ColoredBox(
            color: lit
                ? bar.withValues(alpha: bar.a * (1 - cursor))
                : const Color(0x00000000),
            child: TermCursorCells(
              focus: cursor,
              hollow: lit,
              child: SizedBox(
                height: grid.lineHeight,
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: grid.cellWidth,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      entry.label,
                      style: theme.textStyle.copyWith(
                        color: !entry.enabled
                            ? theme.rule
                            : termCursorInk(
                                theme,
                                lit ? theme.background : ink,
                                cursor,
                                hollow: lit,
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
      dividerBuilder: _menuDivider,
      surfaceBuilder: _menuPlate,
      barBuilder: (context, items) => ColoredBox(
        color: theme.surface,
        child: Row(children: items),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('menus', menus.length));
  }
}

/// A rail of destinations down the screen's edge, for a tablet: each a
/// glyph over its number, the current one in inverse video, a rule beside
/// the rail.
///
/// ```dart
/// TermNavigationRail(
///   destinations: destinations,
///   selectedIndex: 0,
///   onDestinationSelected: (i) {},
/// )
/// ```
class TermNavigationRail extends StatelessWidget {
  /// A rail over [destinations].
  const TermNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.style,
  });

  /// Where it goes.
  final List<TermNavigationDestination> destinations;

  /// The current one.
  final int selectedIndex;

  /// Called with the destination pressed.
  final ValueChanged<int>? onDestinationSelected;

  /// Overrides, over the theme's [TermThemeData.sideBarStyle]: `fill` (the
  /// current item), `foreground` (the glyphs) and `edge` (the rule beside
  /// the rail).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final rest = TermStyleOf([style, theme.sideBarStyle], const {});
    Widget face(int i, Set<WidgetState> states) {
      final own = TermStyleOf([style, theme.sideBarStyle], states);
      final on = i == selectedIndex;
      final lit = on || states.contains(WidgetState.pressed);
      final ink = own.foreground ?? theme.foreground;
      final d = destinations[i];
      return TermStateSprings(
        pressed: states.contains(WidgetState.pressed),
        focused: states.contains(WidgetState.focused),
        builder: (context, press, focus) {
          // The keyboard's focus: the cursor over the item; on the current
          // item's inverse, hollow.
          final bar = own.fill ?? ink;
          final words = termCursorInk(
            theme,
            lit ? theme.background : ink,
            focus,
            hollow: lit,
          );
          return ColoredBox(
            color: lit
                ? bar.withValues(alpha: bar.a * (1 - focus))
                : const Color(0x00000000),
            child: TermCursorCells(
              focus: focus,
              hollow: lit,
              child: SizedBox(
                height: grid.lines(2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      d.glyph ?? d.label.characters.first,
                      style: theme.boldStyle.copyWith(color: words),
                    ),
                    Text(
                      '${i + 1}',
                      style: theme.textStyle.copyWith(
                        color: lit
                            ? words
                            : termCursorInk(theme, theme.dim, focus),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // In TermScaffold's shell, its destinations stand in the items'
    // places: the shell presses them and gives them their keys.
    final shell = TermShellDestinations.maybeOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          end: BorderSide(
            color: rest.edge ?? theme.rule,
            width: termStrokeWidth(theme, grid),
          ),
        ),
      ),
      child: SizedBox(
        width: grid.cols(7),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          // Each item the rail's width: its fill and its reach.
          child: _RailColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                if (shell != null)
                  TermShellFace(
                    face: (context, states) => face(i, states),
                    child: shell[i],
                  )
                else
                  RawButton(
                    onPressed: onDestinationSelected == null
                        ? null
                        : () => onDestinationSelected!(i),
                    selected: i == selectedIndex,
                    semanticSelected: i == selectedIndex,
                    semanticLabel: destinations[i].label,
                    excludeSemantics: true,
                    mouseCursor: onDestinationSelected == null
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    builder: (context, states, _) => face(i, states),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('selectedIndex', selectedIndex));
  }
}

// A rail's destinations down its height; where they don't fit it (larger
// text on a short screen), they scroll.
class _RailColumn extends StatelessWidget {
  const _RailColumn({required this.crossAxisAlignment, required this.children});

  final CrossAxisAlignment crossAxisAlignment;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final column = Column(
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
      if (!box.hasBoundedHeight) return column;
      return SingleChildScrollView(child: column);
    },
  );
}

/// An app's shell that fits its screen: the [topBar] over the [body] and
/// the [statusLine] under it; the destinations as a [TermNavigationBar] at
/// a phone's foot, a [TermNavigationRail] beside a tablet's body, a
/// [TermSideBar] pane at a desk. It goes by its own width (under 600, to
/// 1100, past it), so a shell in a pane of a wider screen fits the pane.
///
/// The behaviour is ui_core's `RawAdaptiveShell`: the destinations are
/// one tab stop, on the current one, the arrows moving along them (Left
/// and Right in the window list, Up and Down in the rail and the side
/// pane), Enter or Space going there; F6 moves the keys between the
/// destinations and the body; a screen reader hears each destination as a
/// tab and its place ("Tab 2 of 4"), the side pane as the navigation menu.
///
/// ```dart
/// TermScaffold(
///   topBar: const TermTopBar(title: 'slipway'),
///   destinations: destinations,
///   selectedIndex: tab,
///   onDestinationSelected: (i) => setState(() => tab = i),
///   body: pages[tab],
/// )
/// ```
class TermScaffold extends StatelessWidget {
  /// A shell round [body].
  const TermScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.statusLine,
    this.destinations = const [],
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.title,
  });

  /// The screen's content.
  final Widget body;

  /// Over the body.
  final Widget? topBar;

  /// Under the body: a [TermStatusLine].
  final Widget? statusLine;

  /// Where the app goes; none: no navigation.
  final List<TermNavigationDestination> destinations;

  /// The current destination.
  final int selectedIndex;

  /// Called with a destination chosen.
  final ValueChanged<int>? onDestinationSelected;

  /// The side pane's title at a desk.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _shell(
        context,
        constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width,
      ),
    );
  }

  Widget _shell(BuildContext context, double width) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    // Along the screen's foot the status line is a bar, as a phone's window
    // list is: the toasts stand above it (a line clear, the toaster's
    // padding), never on it over the page's last line.
    final footLine = statusLine == null
        ? null
        : RawToasterKeepClear(child: statusLine);
    if (destinations.isEmpty) {
      return ColoredBox(
        color: theme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?topBar,
            Expanded(child: body),
            ?footLine,
          ],
        ),
      );
    }
    // Terminal's widths, not Material's classes: the side pane's 26 cells
    // and a page beside them fit from 1100.
    final mode = width < 600
        ? RawNavigationMode.bar
        : width < 1100
        ? RawNavigationMode.rail
        : RawNavigationMode.sidebar;
    final bar = mode == RawNavigationMode.bar;
    final shell = RawAdaptiveShell(
      mode: mode,
      destinations: [
        for (final d in destinations)
          RawNavigationDestination(
            label: d.badge == null ? d.label : '${d.label}, ${d.badge}',
            // Terminal draws its places in characters (a glyph, a number,
            // a name); no icon is drawn.
            icon: const IconData(0x20),
          ),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinationBuilder: (context, _, details) =>
          TermShellFace.build(context, details.states),
      navigationBuilder: (context, details) => TermShellDestinations(
        destinations: details.destinations,
        child: switch (details.mode) {
          RawNavigationMode.bar => TermNavigationBar(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          RawNavigationMode.rail => TermNavigationRail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          RawNavigationMode.sidebar => SizedBox(
            width: grid.cols(26),
            child: TermSideBar(
              title: title,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        },
      ),
      // On a phone the status line stands over the window list, as a
      // multiplexer's does; beside a rail or a pane it runs the screen's
      // width under both.
      body: bar
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: body),
                ?statusLine,
              ],
            )
          : body,
    );
    return ColoredBox(
      color: theme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?topBar,
          Expanded(child: shell),
          if (!bar) ?footLine,
        ],
      ),
    );
  }
}
