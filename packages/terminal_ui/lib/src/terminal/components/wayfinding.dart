/// Where you are and how to move on: a path, pages, page dots, a run of
/// steps, a menubar, a rail of numbered destinations, and the shell that
/// picks the bar, the rail or the side pane by the screen's width.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/focus_block.dart';
import '../internal/menu_marks.dart';
import '../primitives/control.dart';
import '../primitives/menu.dart';
import '../style.dart';
import '../theme.dart';
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
      label: 'path',
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
                  child: DesignPressable(
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
                      final lit =
                          states.contains(WidgetState.focused) ||
                          states.contains(WidgetState.pressed);
                      final ink = own.foreground ?? theme.accent;
                      return ColoredBox(
                        color: lit ? ink : const Color(0x00000000),
                        child: Text(
                          crumb.label,
                          style: theme.textStyle.copyWith(
                            color: lit ? theme.background : ink,
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
    final grid = context.termGrid;
    final go = onChanged;
    final prev = go != null && page > 1 ? () => go(page - 1) : null;
    final next = go != null && page < pageCount ? () => go(page + 1) : null;
    return LayoutBuilder(
      builder: (context, c) {
        // Every page a target a finger can hit (or a pointer's line): when
        // the row of them would not fit, the count stands in for them.
        final floor = grid.ceil(DesignTapTargets.of(context).floorOn()).width;
        double slot(int? p) => p == null
            ? grid.cols(3)
            : math.max(floor, grid.cols('$p'.length + 3));
        final needed =
            2 * math.max(floor, grid.cols(3)) +
            _shown().fold(0.0, (sum, p) => sum + slot(p));
        final narrow = c.maxWidth.isFinite && needed > c.maxWidth;
        return Semantics(
          container: true,
          label: 'pages',
          explicitChildNodes: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TermIconButton(
                glyph: '‹',
                semanticLabel: 'previous page',
                onPressed: prev,
              ),
              if (narrow)
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: grid.cellWidth,
                  ),
                  child: Text(
                    '$page/$pageCount',
                    semanticsLabel: 'page $page of $pageCount',
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
                      child: DesignPressable(
                        onPressed: go == null || p == page ? null : () => go(p),
                        selected: p == page,
                        semanticSelected: p == page,
                        semanticLabel: 'page $p',
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
                semanticLabel: 'next page',
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
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.paginationStyle], const {});
    Widget dot(int i) => SizedBox(
      width: grid.cols(2),
      height: grid.lineHeight,
      child: Center(
        child: Text(
          i == index ? '●' : '·',
          style: theme.textStyle.copyWith(
            color: i == index
                ? own.fill ?? theme.accent
                : own.foreground ?? theme.dim,
          ),
        ),
      ),
    );
    return Semantics(
      label: 'page ${index + 1} of $count',
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
                child: DesignPressable(
                  onPressed: () => onChanged!(i),
                  selected: i == index,
                  semanticLabel: 'page ${i + 1}',
                  excludeSemantics: true,
                  mouseCursor: SystemMouseCursors.click,
                  builder: (context, states, _) => dot(i),
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
      final said = switch (s.state) {
        TermStepState.upcoming => 'to come',
        TermStepState.current => 'current',
        TermStepState.done => 'done',
        TermStepState.failed => 'failed',
      };
      return Semantics(
        label: 'step ${i + 1} of ${steps.length}, ${s.label}, $said',
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

/// A menubar, as a full-screen terminal program draws one: the menus'
/// names along the top line, the open one in inverse video, each menu a
/// raised pane revealed in place under its name; the arrows move along and
/// into them, Escape closes.
///
/// ```dart
/// TermMenuBar(menus: [
///   DesignMenuEntry(label: 'run', children: [
///     DesignMenuEntry(label: 'rerun', shortcut: 'R', onPressed: rerun),
///   ]),
/// ])
/// ```
class TermMenuBar extends StatelessWidget {
  /// A menubar of [menus].
  const TermMenuBar({super.key, required this.menus, this.style});

  /// The menus, each with its items as children.
  final List<DesignMenuEntry> menus;

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
    return DesignMenuBar(
      menus: menus,
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.menu) {
          return TermMenuRow(
            label: entry.isSubmenu ? '${entry.label} ›' : entry.label,
            states: states,
            trailing: termKeysShown(context) ? entry.shortcut : null,
            checked: entry.checked,
          );
        }
        final own = TermStyleOf([style, theme.menuBarStyle], states);
        final lit =
            states.contains(WidgetState.selected) ||
            states.contains(WidgetState.focused);
        final ink = own.foreground ?? theme.foreground;
        // A menu's name is one line; what a tap reaches is the floor, so
        // under a finger the bar is two lines with the names in its middle.
        return TermTapTarget(
          child: ColoredBox(
            color: lit ? own.fill ?? ink : const Color(0x00000000),
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
                          : lit
                          ? theme.background
                          : ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      dividerBuilder: (context) => SizedBox(
        height: grid.lineHeight,
        child: Center(
          child: Container(height: termStroke(theme, grid), color: theme.rule),
        ),
      ),
      surfaceBuilder: (context, info, items) => TermMenuReveal(
        info: info,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: grid.cols(24)),
          child: TermPane(
            raised: true,
            focused: true,
            // A cell inside the frame each side, so a lit row's bar stands
            // clear of the frame's sides as of its top and bottom lines.
            padding: const TermInset(),
            // A letter takes the keys to the next item it starts: ui_core's
            // menu bar does that. One row current, shown once the keys or
            // the pointer move.
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
      ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          end: BorderSide(
            color: rest.edge ?? theme.rule,
            width: termStroke(theme, grid),
          ),
        ),
      ),
      child: SizedBox(
        width: grid.cols(7),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          // Each item the rail's width: its fill and its reach.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                DesignPressable(
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
                  builder: (context, states, _) {
                    final own = TermStyleOf([
                      style,
                      theme.sideBarStyle,
                    ], states);
                    final on = i == selectedIndex;
                    final lit = on || states.contains(WidgetState.pressed);
                    final ink = own.foreground ?? theme.foreground;
                    final words = lit ? theme.background : ink;
                    final d = destinations[i];
                    return TermStateSprings(
                      pressed: states.contains(WidgetState.pressed),
                      focused: states.contains(WidgetState.focused),
                      builder: (context, press, focus) => CustomPaint(
                        // The keyboard's focus: a block at the item's start,
                        // as a list's row has it.
                        foregroundPainter: focus > 0
                            ? TermFocusBlockPainter(
                                amount: focus,
                                color: theme.accent,
                                cellWidth: grid.cellWidth,
                                direction: Directionality.of(context),
                              )
                            : null,
                        child: ColoredBox(
                          color: lit
                              ? own.fill ?? ink
                              : const Color(0x00000000),
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
                                    color: lit ? words : theme.dim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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

/// An app's shell that fits its screen: the [topBar] over the [body] and
/// the [statusLine] under it; the destinations as a [TermNavigationBar] at
/// a phone's foot, a [TermNavigationRail] beside a tablet's body, a
/// [TermSideBar] pane at a desk. It goes by its own width (under 600, to
/// 1100, past it), so a shell in a pane of a wider screen fits the pane.
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
    final nav = destinations.isNotEmpty;
    final Widget middle;
    if (nav && width >= 1100) {
      middle = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: grid.cols(26),
            child: TermSideBar(
              title: title,
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
          Expanded(child: body),
        ],
      );
    } else if (nav && width >= 600) {
      middle = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TermNavigationRail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          Expanded(child: body),
        ],
      );
    } else {
      middle = body;
    }
    return ColoredBox(
      color: theme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?topBar,
          Expanded(child: middle),
          ?statusLine,
          if (nav && width < 600)
            TermNavigationBar(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
        ],
      ),
    );
  }
}
