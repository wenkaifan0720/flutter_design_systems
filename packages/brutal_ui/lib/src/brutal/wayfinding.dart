/// Brutal's ways round an app beyond its bars: [BrutalBreadcrumb] (the path
/// in words and slashes), [BrutalPagination] and [BrutalStepProgress] (cells
/// on shared rules), [BrutalPageDots] (squares, the current one a bar),
/// [BrutalMenuBar] (a desk app's menus) and the command palette
/// ([BrutalCommandPalette], [showBrutalCommandPalette]).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'actions.dart';
import 'lists.dart';
import 'menu.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

/// One place on a [BrutalBreadcrumb]'s path.
@immutable
class BrutalCrumb {
  /// A place called [label]; [onPressed] goes back to it.
  const BrutalCrumb(this.label, {this.onPressed});

  /// Its name.
  final String label;

  /// Goes there; null for the page you are on.
  final VoidCallback? onPressed;
}

/// Where a page stands: the places above it as links, slashes between, the
/// page itself last in heavy words.
///
/// ```dart
/// BrutalBreadcrumb(crumbs: [BrutalCrumb('Events', onPressed: () => go(events)), const BrutalCrumb('Low Tide')])
/// ```
class BrutalBreadcrumb extends StatelessWidget {
  /// A path of [crumbs], the current page last.
  const BrutalBreadcrumb({super.key, required this.crumbs, this.style});

  /// The places, the top first.
  final List<BrutalCrumb> crumbs;

  /// Its style, over [BrutalThemeData.breadcrumbStyle]: `foreground` (the
  /// current page and the slashes) and `textStyle`. The links between read
  /// [BrutalThemeData.linkStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([
      this.style,
      theme.breadcrumbStyle,
    ], const {});
    final style = layered.text(
      theme.textTheme.label.copyWith(fontSize: 15, height: 20 / 15),
    );
    return Semantics(
      container: true,
      label: 'Breadcrumb',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: BrutalSpacing.small,
        runSpacing: BrutalSpacing.tight,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Text(
                  '/',
                  style: style.copyWith(
                    color: layered.foreground ?? c.inkMuted,
                  ),
                ),
              ),
            if (i == crumbs.length - 1 || crumb.onPressed == null)
              Semantics(
                // The page you are on.
                selected: i == crumbs.length - 1,
                child: Text(
                  crumb.label,
                  style: style.copyWith(
                    fontWeight: FontWeight.w700,
                    color: layered.foreground,
                  ),
                ),
              )
            else
              BrutalLink(
                crumb.label,
                onPressed: crumb.onPressed,
                style: BrutalStyle(
                  textStyle: WidgetStatePropertyAll(
                    style.copyWith(color: null),
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

/// A square cell on a strip's shared rules that is pressed: ink while
/// chosen or pressed, the inset focus rule from the keyboard.
class _StripCell extends StatelessWidget {
  const _StripCell({
    required this.onPressed,
    required this.semanticLabel,
    required this.child,
    required this.layers,
    this.chosen = false,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final Widget child;
  final bool chosen;
  final List<BrutalStyle?> layers;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final side =
        DesignStyleOf(layers, const {}).minimumSize?.height ??
        theme.controlHeight;
    return TapTargetPadding(
      child: RawButton(
        onPressed: onPressed,
        selected: chosen,
        semanticLabel: semanticLabel,
        builder: (context, states, _) {
          final layered = DesignStyleOf(layers, {
            ...states,
            if (chosen) WidgetState.selected,
          });
          final disabled = states.contains(WidgetState.disabled);
          final lit = chosen || states.contains(WidgetState.pressed);
          final ink =
              layered.foreground ??
              (disabled && !chosen
                  ? c.disabled
                  : lit
                  ? c.onColor(layered.fill ?? c.ink)
                  : c.ink);
          return ConstrainedBox(
            constraints: BoxConstraints(minWidth: side, minHeight: side),
            child: CustomPaint(
              foregroundPainter: states.contains(WidgetState.focused)
                  ? BrutalInsetFocusPainter(lit ? c.paper : c.ink)
                  : null,
              child: ColoredBox(
                color: lit
                    ? (layered.fill ?? c.ink)
                    : c.ink.withValues(alpha: 0),
                child: Center(
                  widthFactor: 1,
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: layered.iconSize ?? 20,
                      color: ink,
                    ),
                    child: DefaultTextStyle.merge(
                      style: layered.text(
                        theme.textTheme.label.copyWith(
                          fontSize: 15,
                          height: 20 / 15,
                          color: ink,
                        ),
                      ),
                      child: Padding(
                        padding:
                            layered.padding(Directionality.of(context)) ??
                            const EdgeInsets.symmetric(
                              horizontal: BrutalSpacing.small,
                            ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// [cells] butted on shared rules in a flat ruled strip, in [layers]'
/// `fill` and `edge`, and `minimumSize`'s height.
Widget _strip(
  BrutalThemeData theme,
  List<BrutalStyle?> layers,
  List<Widget> cells,
) {
  final c = theme.colors;
  final strip = DesignStyleOf(layers, const {});
  final rule = strip.side?.color ?? strip.edge ?? c.ink;
  return Align(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    heightFactor: 1,
    child: BrutalSurface(
      face: BrutalFace(
        fill: strip.fill ?? c.surface,
        border: rule,
        foreground: c.ink,
      ),
      child: SizedBox(
        height: strip.minimumSize?.height ?? theme.controlHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, cell) in cells.indexed) ...[
              if (i > 0)
                SizedBox(
                  width: theme.borderWidth,
                  child: ColoredBox(color: rule),
                ),
              cell,
            ],
          ],
        ),
      ),
    ),
  );
}

/// Pages of a list as cells on shared rules: back, the pages near the
/// current one (the first and last always, a gap as an ellipsis), next. The
/// current page is ink.
///
/// Reads [style]'s `fill` (the strip, and a current or pressed cell in
/// those states), `edge`, `foreground`, `padding`, `minimumSize` (its
/// height), `textStyle` and `iconSize`, then
/// [BrutalThemeData.paginationStyle]'s.
///
/// ```dart
/// BrutalPagination(page: page, pageCount: 12, onChanged: (p) => setState(() => page = p))
/// ```
class BrutalPagination extends StatelessWidget {
  /// Pages 1 to [pageCount], at [page].
  const BrutalPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.style,
  });

  /// Its style, over [BrutalThemeData.paginationStyle].
  final BrutalStyle? style;

  /// The current page, from 1.
  final int page;

  /// How many pages.
  final int pageCount;

  /// Called with the page to go to; null disables it.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final layers = [style, theme.paginationStyle];
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    VoidCallback? go(int p) =>
        onChanged == null || p < 1 || p > pageCount || p == page
        ? null
        : () => onChanged!(p);
    List<int> near(int reach) => <int>{
      1,
      pageCount,
      for (var p = page - reach; p <= page + reach; p++)
        if (p >= 1 && p <= pageCount) p,
    }.toList()..sort();
    final side =
        DesignStyleOf(layers, const {}).minimumSize?.height ??
        theme.controlHeight;
    // The strip's width for [pages] between back and next: square cells,
    // a narrow gap where pages are skipped, a rule between each two and
    // round them.
    double widthOf(List<int> pages) {
      var gaps = 0;
      for (var i = 1; i < pages.length; i++) {
        if (pages[i] - pages[i - 1] > 1) gaps++;
      }
      final parts = pages.length + 2 + gaps;
      return (pages.length + 2) * side +
          gaps * _gapWidth +
          (parts + 1) * theme.borderWidth;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth;
        final shown = [
          near(1),
          near(0),
        ].where((s) => !room.isFinite || widthOf(s) <= room).firstOrNull;
        return Semantics(
          container: true,
          label: 'Pages',
          child: _strip(theme, layers, [
            _StripCell(
              onPressed: page > 1 ? go(page - 1) : null,
              semanticLabel: words.previousPageTooltip,
              layers: layers,
              child: Transform.flip(
                flipX: rtl,
                child: const Icon(LucideIcons.chevronLeft),
              ),
            ),
            if (shown == null)
              // Too narrow for pages to press: where it stands, in words.
              Semantics(
                label: words.positionLabel(page, pageCount),
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BrutalSpacing.medium,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        '$page / $pageCount',
                        style: theme.textTheme.label.copyWith(
                          color: theme.colors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              for (final (i, p) in shown.indexed) ...[
                if (i > 0 && p - shown[i - 1] > 1)
                  const ExcludeSemantics(
                    child: SizedBox(
                      width: _gapWidth,
                      child: Center(child: Text('…')),
                    ),
                  ),
                _StripCell(
                  onPressed: onChanged == null ? null : () => onChanged!(p),
                  chosen: p == page,
                  layers: layers,
                  semanticLabel: words.positionLabel(p, pageCount),
                  child: Text('$p'),
                ),
              ],
            _StripCell(
              onPressed: page < pageCount ? go(page + 1) : null,
              semanticLabel: words.nextPageTooltip,
              layers: layers,
              child: Transform.flip(
                flipX: rtl,
                child: const Icon(LucideIcons.chevronRight),
              ),
            ),
          ]),
        );
      },
    );
  }

  static const double _gapWidth = 32;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('page', page))
      ..add(IntProperty('pageCount', pageCount));
  }
}

/// The steps of a task as cells on shared rules across the width: a step
/// done is ink with a check, the current one carries a heavy bar at its
/// foot, those to come are grey.
///
/// Reads [style]'s `fill` (the box), `edge` (its rules, and the current
/// step's bar), `foreground` (the current step's words), `padding` and
/// `textStyle` (the names), then [BrutalThemeData.stepProgressStyle]'s.
///
/// ```dart
/// BrutalStepProgress(steps: const ['Tickets', 'Details', 'Pay'], current: 1)
/// ```
class BrutalStepProgress extends StatelessWidget {
  /// [steps], at [current] (from 0).
  const BrutalStepProgress({
    super.key,
    required this.steps,
    required this.current,
    this.style,
  });

  /// Its style, over [BrutalThemeData.stepProgressStyle].
  final BrutalStyle? style;

  /// Each step's name.
  final List<String> steps;

  /// The step being done, from 0; [steps]' length once all are done.
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.stepProgressStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    if (steps.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: 'Step ${(current + 1).clamp(1, steps.length)} of ${steps.length}',
      child: BrutalSurface(
        face: BrutalFace(
          fill: layered.fill ?? c.surface,
          border: rule,
          foreground: c.ink,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final direction = Directionality.of(context);
            final padding =
                layered.padding(direction)?.horizontal ??
                2 * BrutalSpacing.medium;
            final width =
                (constraints.maxWidth -
                        theme.borderWidth * (steps.length - 1)) /
                    steps.length -
                padding;
            final painter = TextPainter(
              textDirection: direction,
              textScaler: MediaQuery.textScalerOf(context),
            );
            final stack = steps.indexed.any((entry) {
              painter.text = TextSpan(
                text: entry.$2,
                style: _nameStyle(theme, layered, entry.$1 == current),
              );
              painter.layout();
              return painter.width > width;
            });
            painter.dispose();
            final cells = <Widget>[
              for (final (i, name) in steps.indexed) ...[
                if (i > 0) BrutalRule(vertical: !stack, color: rule),
                if (stack)
                  _step(context, theme, layered, i, name, stacked: true)
                else
                  Expanded(child: _step(context, theme, layered, i, name)),
              ],
            ];
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            );
          },
        ),
      ),
    );
  }

  TextStyle _nameStyle(
    BrutalThemeData theme,
    DesignStyleOf layered,
    bool current,
  ) => layered.text(
    theme.textTheme.label.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: current ? FontWeight.w700 : FontWeight.w600,
    ),
  );

  Widget _step(
    BuildContext context,
    BrutalThemeData theme,
    DesignStyleOf layered,
    int i,
    String name, {
    bool stacked = false,
  }) {
    final c = theme.colors;
    final done = i < current;
    final now = i == current;
    final ink = done
        ? c.paper
        : now
        ? (layered.foreground ?? c.ink)
        : c.inkMuted;
    final number = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${i + 1}'.padLeft(2, '0'),
          style: theme.textTheme.caption.copyWith(color: ink),
        ),
        if (done) ...[
          const SizedBox(width: BrutalSpacing.tight),
          Icon(LucideIcons.check, size: 14, color: ink),
        ],
      ],
    );
    final label = Text(
      name,
      style: _nameStyle(theme, layered, now).copyWith(color: ink),
    );
    return Semantics(
      label:
          '$name, ${done
              ? 'done'
              : now
              ? 'current'
              : 'to come'}',
      excludeSemantics: true,
      child: ColoredBox(
        color: done ? c.ink : c.ink.withValues(alpha: 0),
        child: Stack(
          children: [
            Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  const EdgeInsets.fromLTRB(
                    BrutalSpacing.medium,
                    BrutalSpacing.small,
                    BrutalSpacing.medium,
                    BrutalSpacing.medium,
                  ),
              child: stacked
                  ? Row(
                      children: [
                        number,
                        const SizedBox(width: BrutalSpacing.medium),
                        Expanded(child: label),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        number,
                        const SizedBox(height: BrutalSpacing.tight),
                        label,
                      ],
                    ),
            ),
            if (now)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: BrutalSpacing.tight,
                child: ColoredBox(
                  color: layered.side?.color ?? layered.edge ?? c.ink,
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
      ..add(IntProperty('current', current));
  }
}

/// Where a carousel or a run of pages stands: a small square a page, the
/// current one stretched to a bar. Given [onChanged], each is a button that
/// goes to its page.
///
/// Reads [style]'s `foreground` (selected for the current page's bar, and
/// the rest's squares), then [BrutalThemeData.pageDotsStyle]'s.
///
/// ```dart
/// BrutalPageDots(count: 4, index: page, onChanged: goTo)
/// ```
class BrutalPageDots extends StatelessWidget {
  /// [count] dots at [index].
  const BrutalPageDots({
    super.key,
    required this.count,
    required this.index,
    this.onChanged,
    this.style,
  });

  /// Its style, over [BrutalThemeData.pageDotsStyle].
  final BrutalStyle? style;

  /// How many pages.
  final int count;

  /// The current page, from 0.
  final int index;

  /// Goes to a page; null: the dots only show.
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final reduce = designReduceMotionOf(context);
    final layers = [style, theme.pageDotsStyle];
    Widget dot(int i) => AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: i == index ? 24 : 8,
      height: 8,
      color:
          DesignStyleOf(layers, {
            if (i == index) WidgetState.selected,
          }).foreground ??
          (i == index ? c.ink : c.inkMuted),
    );
    return Semantics(
      container: true,
      label: words.positionLabel(index + 1, count),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            if (onChanged == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BrutalSpacing.tight,
                ),
                child: ExcludeSemantics(child: dot(i)),
              )
            else
              TapTargetPadding(
                child: RawButton(
                  onPressed: () => onChanged!(i),
                  selected: i == index,
                  semanticLabel: words.positionLabel(i + 1, count),
                  builder: (context, states, _) => CustomPaint(
                    foregroundPainter: states.contains(WidgetState.focused)
                        ? BrutalInsetFocusPainter(c.ink)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(BrutalSpacing.small),
                      child: dot(i),
                    ),
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
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      )
      ..add(IntProperty('count', count))
      ..add(IntProperty('index', index))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged));
  }
}

/// One menu of a [BrutalMenuBar]: its name on the bar and its items.
@immutable
class BrutalMenuBarMenu {
  /// A menu called [label] holding [items].
  const BrutalMenuBarMenu(this.label, this.items);

  /// Its name on the bar.
  final String label;

  /// Its commands.
  final List<BrutalMenuItem> items;
}

/// A desk app's menus: their names in cells on a ruled bar, each dropping
/// a raised menu. An open menu's cell is ink; the arrows move along the
/// bar and through the menus.
///
/// Reads [style]'s `fill` and `edge` for the bar, and `foreground`, `fill`
/// (an open or pressed cell's), `padding` and `textStyle` for its cells,
/// then [BrutalThemeData.menuBarStyle]'s; the menus it drops read
/// [BrutalThemeData.menuStyle].
///
/// ```dart
/// BrutalMenuBar(menus: [BrutalMenuBarMenu('Ticket', [BrutalMenuItem(label: 'Print', onPressed: printTicket)])])
/// ```
class BrutalMenuBar extends StatelessWidget {
  /// A bar of [menus].
  const BrutalMenuBar({super.key, required this.menus, this.style});

  /// The menus, start to end.
  final List<BrutalMenuBarMenu> menus;

  /// Its style, over [BrutalThemeData.menuBarStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.menuBarStyle];
    final bar = DesignStyleOf(layers, const {});
    final rule = bar.side?.color ?? bar.edge ?? c.ink;
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
                  shortcut: item.shortcutLabel(context),
                  data: item,
                ),
            ],
          ),
      ],
      barBuilder: (context, items) => BrutalSurface(
        face: BrutalFace(
          fill: bar.fill ?? c.surface,
          border: rule,
          foreground: c.ink,
        ),
        child: SizedBox(
          height: bar.minimumSize?.height ?? theme.controlHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items) ...[
                item,
                SizedBox(
                  width: theme.borderWidth,
                  child: ColoredBox(color: rule),
                ),
              ],
            ],
          ),
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == RawMenuLevel.menu) {
          final item = entry.data as BrutalMenuItem?;
          return BrutalMenuRow(
            label: entry.label,
            icon: item?.icon,
            isDestructiveAction: item?.isDestructiveAction ?? false,
            states: states,
            trailing: entry.shortcut == null ? null : Text(entry.shortcut!),
          );
        }
        final layered = DesignStyleOf(layers, states);
        final lit =
            states.contains(WidgetState.selected) ||
            states.contains(WidgetState.pressed);
        final ink =
            layered.foreground ??
            (lit ? c.onColor(layered.fill ?? c.ink) : c.ink);
        return CustomPaint(
          foregroundPainter: states.contains(WidgetState.focused)
              ? BrutalInsetFocusPainter(ink)
              : null,
          child: ColoredBox(
            color: lit ? (layered.fill ?? c.ink) : c.ink.withValues(alpha: 0),
            child: Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  const EdgeInsets.symmetric(horizontal: BrutalSpacing.medium),
              child: Center(
                widthFactor: 1,
                child: DesignCapCenter(
                  capHeightFactor: BrutalTheme.of(context).capHeightFactor,
                  child: Text(
                    entry.label,
                    maxLines: 1,
                    style: layered.text(
                      theme.textTheme.label.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      surfaceBuilder: (context, info, items) => FadeTransition(
        opacity: info.animation,
        child: BrutalMenuPanel(
          maxHeight: info.maxSize.height - theme.shadowOffset,
          children: items,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BrutalMenuBarMenu>('menus', menus))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A command a [BrutalCommandPalette] finds.
@immutable
class BrutalCommand {
  /// A command reading [label] that runs [onPressed].
  const BrutalCommand({
    required this.label,
    required this.onPressed,
    this.group,
    this.icon,
    this.shortcut,
    this.keywords = const [],
  });

  /// Its words.
  final String label;

  /// What it does; null shows it disabled.
  final VoidCallback? onPressed;

  /// The heading it stands under.
  final String? group;

  /// A glyph before the words.
  final IconData? icon;

  /// Its keys, shown at the row's end.
  final String? shortcut;

  /// Other words that find it.
  final List<String> keywords;
}

/// A field over a list of commands: typing narrows the list, the arrows
/// move through it and Enter runs one. [showBrutalCommandPalette] opens it
/// over the page; it also stands in a page as it is (a sidebar's search).
///
/// Its box reads [style]'s `fill`, `edge`, `padding` and `textStyle` (the
/// group headings), then [BrutalThemeData.commandPaletteStyle]'s; its field
/// reads [BrutalThemeData.textFieldStyle] and its rows
/// [BrutalThemeData.menuStyle].
///
/// ```dart
/// BrutalCommandPalette(commands: commands, onSelected: (c) => c.onPressed?.call())
/// ```
class BrutalCommandPalette extends StatelessWidget {
  /// A palette of [commands].
  const BrutalCommandPalette({
    super.key,
    required this.commands,
    this.onSelected,
    this.hint = 'Type a command or search',
    this.emptyText = 'No commands match',
    this.autofocus = false,
    this.style,
  });

  /// Its style, over [BrutalThemeData.commandPaletteStyle].
  final BrutalStyle? style;

  /// What it finds.
  final List<BrutalCommand> commands;

  /// Takes the command chosen; null runs its own `onPressed`.
  final ValueChanged<BrutalCommand>? onSelected;

  /// What the empty field says.
  final String hint;

  /// What the list says when nothing matches.
  final String emptyText;

  /// {@macro design.autofocus}
  final bool autofocus;

  RawCommandPalette _body(ValueChanged<RawCommand>? run) => RawCommandPalette(
    commands: [
      for (final c in commands)
        RawCommand(
          label: c.label,
          onPressed: c.onPressed,
          group: c.group,
          keywords: c.keywords,
          shortcut: c.shortcut,
          enabled: c.onPressed != null,
          data: c,
        ),
    ],
    autofocus: autofocus,
    onSelected: run,
    fieldBuilder: (context, field) => BrutalTextField(
      controller: field.controller,
      focusNode: field.focusNode,
      hint: hint,
      semanticLabel: hint,
      prefixIcon: const Icon(LucideIcons.search),
      // Enter in onEditingComplete alone: the field keeps the keyboard, and
      // with no onSubmitted Flutter does not restart its text input (a
      // browser's restarted input takes no typing).
      onEditingComplete: field.submit,
    ),
    itemBuilder: (context, command, states) {
      final c = command.data! as BrutalCommand;
      return BrutalMenuRow(
        label: c.label,
        icon: c.icon,
        states: states,
        trailing: c.shortcut == null ? null : Text(c.shortcut!),
      );
    },
    groupBuilder: (context, group) => Padding(
      padding: const EdgeInsets.fromLTRB(
        BrutalSpacing.medium,
        BrutalSpacing.medium,
        BrutalSpacing.medium,
        BrutalSpacing.tight,
      ),
      child: Text(
        group.toUpperCase(),
        style:
            DesignStyleOf([
              style,
              BrutalTheme.of(context).commandPaletteStyle,
            ], const {}).text(
              BrutalTheme.of(context).textTheme.caption
                  .copyWith(color: BrutalTheme.of(context).colors.inkMuted),
            ),
      ),
    ),
    emptyBuilder: (context) => Padding(
      padding: const EdgeInsets.all(BrutalSpacing.medium),
      child: Text(
        emptyText,
        style: BrutalTheme.of(context).textTheme.secondary,
      ),
    ),
    layoutBuilder: (context, field, results) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        const SizedBox(height: BrutalSpacing.small),
        // The results take what room is left and scroll in it.
        Flexible(child: results),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => _panel(
    context,
    style,
    _body(
      onSelected == null ? null : (c) => onSelected!(c.data! as BrutalCommand),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      )
      ..add(IterableProperty<BrutalCommand>('commands', commands))
      ..add(
        ObjectFlagProperty<ValueChanged<BrutalCommand>>.has(
          'onSelected',
          onSelected,
        ),
      )
      ..add(StringProperty('hint', hint))
      ..add(StringProperty('emptyText', emptyText))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

/// A palette's raised box.
Widget _panel(BuildContext context, BrutalStyle? style, Widget child) {
  final theme = BrutalTheme.of(context);
  final c = theme.colors;
  final layered = DesignStyleOf([style, theme.commandPaletteStyle], const {});
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: BrutalSurface(
      face: layered.on(
        BrutalFace(
          fill: c.surface,
          border: c.ink,
          foreground: c.ink,
          shadow: c.ink,
        ),
      ),
      child: Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.all(BrutalSpacing.medium),
        child: child,
      ),
    ),
  );
}

/// Opens [commands] as a palette over the page, under the look's scrim;
/// the command chosen runs once it has closed. Escape or a press on the
/// scrim closes it.
///
/// ```dart
/// showBrutalCommandPalette(context, commands: commands)
/// ```
Future<void> showBrutalCommandPalette(
  BuildContext context, {
  required List<BrutalCommand> commands,
  String hint = 'Type a command or search',
  BrutalStyle? style,
}) {
  final scrim = BrutalTheme.of(context).colors.scrim;
  return showDesignCommandPalette(
    context: context,
    barrierColor: scrim,
    palette: (run) => BrutalCommandPalette(
      commands: commands,
      hint: hint,
      autofocus: true,
      style: style,
    )._body(run),
    surfaceBuilder: (context, palette) => Padding(
      padding: const EdgeInsets.all(BrutalSpacing.regular),
      child: _panel(context, style, palette),
    ),
  );
}
