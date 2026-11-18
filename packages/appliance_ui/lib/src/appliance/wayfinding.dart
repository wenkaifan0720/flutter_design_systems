/// Appliance's wayfinding: [ApplianceBreadcrumb] (the way back, printed),
/// [AppliancePagination] (numbered keys), [ApplianceStepProgress] (lamps on
/// a seam), [AppliancePageDots] (a row of lamps), [ApplianceMenuBar] (menus
/// in a moulded strip) and [ApplianceCommandPalette] (a search over every
/// command, on a plate).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'actions.dart';
import 'internal/bare_field.dart';
import 'internal/glyphs.dart';
import 'internal/menu_paint.dart';
import 'lists.dart';
import 'material.dart';
import 'menus.dart';
import 'theme.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart' show DesignCommand;
export 'package:ui_core/ui_core.dart' show DesignMenuEntry;
// A menu's or a command's shortcut words, as the platform writes them.
export 'package:ui_core/ui_core.dart'
    show designShortcutKeys, designShortcutLabel;

/// A chevron to the end side (the start side when [back]), mirrored for
/// right-to-left text.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.color, this.back = false});

  final Color color;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: back != rtl,
      child: CustomPaint(
        size: const Size.square(16),
        painter: ApplianceChevronPainter(color),
      ),
    );
  }
}

/// One step of a breadcrumb trail.
@immutable
class ApplianceCrumb {
  /// A step reading [label]; [onPressed] goes back to it.
  const ApplianceCrumb(this.label, {this.onPressed});

  /// Its words.
  final String label;

  /// Goes back to it; null for the page you are on.
  final VoidCallback? onPressed;
}

/// A breadcrumb trail: the pages above this one, printed small and muted
/// with chevrons between, each going back there; the page you are on last,
/// in the print. A press darkens a step; the bezel rings it for the
/// keyboard.
///
/// ```dart
/// ApplianceBreadcrumb(crumbs: [ApplianceCrumb('Shop', onPressed: () {}), ApplianceCrumb('Kitchen', onPressed: () {}), const ApplianceCrumb('Kettles')])
/// ```
class ApplianceBreadcrumb extends StatelessWidget {
  /// A trail of [crumbs], the last the page you are on.
  const ApplianceBreadcrumb({
    super.key,
    required this.crumbs,
    this.semanticLabel = 'Breadcrumb',
    this.style,
  });

  /// The steps, the first the top.
  final List<ApplianceCrumb> crumbs;

  /// The trail's name for a screen reader.
  final String semanticLabel;

  /// The steps' style, over [ApplianceThemeData.linkStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    assert(crumbs.isNotEmpty);
    final last = crumbs.length - 1;
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: ApplianceSpacing.tight,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ApplianceSpacing.tight,
                  ),
                  child: _Chevron(color: c.printDisabled),
                ),
              ),
            if (i == last || crumb.onPressed == null)
              Semantics(
                label: crumb.label,
                // The page you are on.
                selected: i == last,
                child: ExcludeSemantics(
                  child: Text(
                    crumb.label,
                    style: t.secondary.copyWith(
                      color: c.print,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              DesignPressable(
                onPressed: crumb.onPressed,
                button: false,
                link: true,
                semanticLabel: crumb.label,
                excludeSemantics: true,
                builder: (context, states, _) {
                  final layered = DesignStyleOf([
                    style,
                    theme.linkStyle,
                  ], states);
                  final ink =
                      layered.foreground ??
                      (states.contains(WidgetState.pressed)
                          ? c.print
                          : c.printMuted);
                  return DesignTapTarget(
                    child: AnimatedApplianceSurface(
                      control: false,
                      face: ApplianceFace(
                        top: c.face.withValues(alpha: 0),
                        bottom: c.face.withValues(alpha: 0),
                        lift: 0,
                        radius: BorderRadius.circular(ApplianceSpacing.tight),
                        foreground: ink,
                        focus: states.contains(WidgetState.focused)
                            ? c.focus
                            : c.focus.withValues(alpha: 0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ApplianceSpacing.nudge,
                        ),
                        child: Text(
                          crumb.label,
                          style: layered.text(
                            t.secondary.copyWith(
                              color: ink,
                              decoration: TextDecoration.underline,
                              decorationColor: c.hairline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
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

/// A small square key: a page's number, a step back or on.
class _PageKey extends StatelessWidget {
  const _PageKey({
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    this.current = false,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final Widget Function(Color ink) child;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      selected: current,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf([theme.navigationStyle], states);
        final face = layered.on(
          applianceKeyFace(
            c,
            down: current || states.contains(WidgetState.pressed),
            disabled: onPressed == null && !current,
            focused: states.contains(WidgetState.focused),
            radius: ApplianceMetrics.smallKeyRadius,
          ),
        );
        return DesignTapTarget(
          child: SizedBox(
            height: 36,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 36),
              child: AnimatedApplianceSurface(
                face: face,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ApplianceSpacing.small,
                      ),
                      child: child(face.foreground),
                    ),
                    if (current)
                      const PositionedDirectional(
                        top: 4,
                        start: 4,
                        child: ApplianceLamp(lit: true, size: 4),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pagination: a key back, the pages' numbered keys (the current one down,
/// its lamp lit; a long run folded round it) and a key on.
///
/// ```dart
/// AppliancePagination(page: 2, pageCount: 9, onChanged: (page) {})
/// ```
class AppliancePagination extends StatelessWidget {
  /// Keys for [pageCount] pages, [page] (from 1) current.
  const AppliancePagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
    this.semanticLabel = 'Pages',
    this.style,
  }) : assert(pageCount > 0 && page >= 1 && page <= pageCount);

  /// The current page, from 1.
  final int page;

  /// How many pages there are.
  final int pageCount;

  /// Goes to a page.
  final ValueChanged<int> onChanged;

  /// The keys' name for a screen reader.
  final String semanticLabel;

  /// The pages shown: every one when there are few, else the ends and the
  /// current page's neighbours, nulls for the folds.
  List<int?> get _shown {
    if (pageCount <= 7) return [for (var p = 1; p <= pageCount; p++) p];
    final from = (page - 1).clamp(2, pageCount - 3);
    final to = (page + 1).clamp(4, pageCount - 1);
    return [
      1,
      if (from > 2) null,
      for (var p = from; p <= to; p++) p,
      if (to < pageCount - 1) null,
      pageCount,
    ];
  }

  /// Its style, over [ApplianceThemeData.buttonStyle]: textStyle (the figures).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).buttonStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final figure = look
        .text(theme.textTheme.secondary)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return LayoutBuilder(
      builder: (context, box) {
        final shown = _shown;
        final gaps = (shown.length + 1) * (ApplianceSpacing.tight + 2);
        final folds = shown.where((p) => p == null).length;
        final need = (shown.length - folds + 2) * 48.0 + folds * 24 + gaps;
        // Too narrow for every key: the arrows and where you are.
        final compact = box.hasBoundedWidth && need > box.maxWidth;
        return Semantics(
          container: true,
          label: semanticLabel,
          explicitChildNodes: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageKey(
                semanticLabel: 'Previous page',
                onPressed: page > 1 ? () => onChanged(page - 1) : null,
                child: (ink) => _Chevron(color: ink, back: true),
              ),
              if (compact) ...[
                const SizedBox(width: ApplianceSpacing.small),
                Semantics(
                  label: 'Page $page of $pageCount',
                  excludeSemantics: true,
                  child: Text(
                    '$page / $pageCount',
                    style: figure.copyWith(
                      color: c.print,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: ApplianceSpacing.tight),
              ] else
                for (final p in shown) ...[
                  const SizedBox(width: ApplianceSpacing.tight + 2),
                  if (p == null)
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 24,
                        child: Text(
                          '…',
                          textAlign: TextAlign.center,
                          style: figure.copyWith(color: c.printMuted),
                        ),
                      ),
                    )
                  else
                    _PageKey(
                      semanticLabel: 'Page $p of $pageCount',
                      current: p == page,
                      onPressed: p == page ? null : () => onChanged(p),
                      child: (ink) => DesignCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: Text(
                          '$p',
                          style: figure.copyWith(
                            color: ink,
                            fontWeight: p == page ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ),
                ],
              const SizedBox(width: ApplianceSpacing.tight + 2),
              _PageKey(
                semanticLabel: 'Next page',
                onPressed: page < pageCount ? () => onChanged(page + 1) : null,
                child: (ink) => _Chevron(color: ink),
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

/// Step progress: a lamp for each step on one seam across the panel. The
/// steps done are lit, the current one lit in a ring with its words in the
/// print, the steps to come out.
///
/// ```dart
/// ApplianceStepProgress(steps: const ['Basket', 'Delivery', 'Payment', 'Done'], current: 1)
/// ```
class ApplianceStepProgress extends StatelessWidget {
  /// Progress through [steps], [current] (from 0) under way.
  const ApplianceStepProgress({
    super.key,
    required this.steps,
    required this.current,
    this.style,
  }) : assert(current >= 0);

  /// The steps' names.
  final List<String> steps;

  /// The step under way, from 0.
  final int current;

  static const double _lamp = 12;
  static const double _ring = 22;

  /// Its style, over [ApplianceThemeData.progressStyle]: foreground (the lit seam).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).progressStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final n = steps.length;
    assert(n > 1 && current < n);
    return Semantics(
      container: true,
      label: 'Step ${current + 1} of $n, ${steps[current]}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final cell = box.maxWidth / n;
            return Stack(
              children: [
                // The seam the lamps sit on, lit as far as the current step.
                PositionedDirectional(
                  top: _ring / 2 - 1,
                  start: cell / 2,
                  end: cell / 2,
                  child: Container(height: 2, color: c.seamShade),
                ),
                PositionedDirectional(
                  top: _ring / 2 - 1,
                  start: cell / 2,
                  width: cell * current,
                  child: Container(
                    height: 2,
                    color: look.foreground ?? c.signal,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, step) in steps.indexed)
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox.square(
                              dimension: _ring,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: c.face,
                                  border: Border.all(
                                    color: i == current
                                        ? c.signal
                                        : c.signal.withValues(alpha: 0),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: ApplianceLamp(
                                    lit: i <= current,
                                    size: _lamp,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: ApplianceSpacing.small),
                            Text(
                              step,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.secondary.copyWith(
                                color: i == current ? c.print : c.printMuted,
                                fontWeight: i == current
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('steps', steps))
      ..add(IntProperty('current', current));
  }
}

/// Page dots: a lamp for each page, the one shown lit. With [onChanged]
/// each lamp is a target that turns to its page.
///
/// ```dart
/// AppliancePageDots(count: 4, index: 1)
/// ```
class AppliancePageDots extends StatelessWidget {
  /// Lamps for [count] pages, [index] (from 0) lit.
  const AppliancePageDots({
    super.key,
    required this.count,
    required this.index,
    this.onChanged,
    this.style,
  }) : assert(count > 0 && index >= 0 && index < count);

  /// How many pages.
  final int count;

  /// The page shown, from 0.
  final int index;

  /// Turns to a page; null: the lamps only show.
  final ValueChanged<int>? onChanged;

  /// Its style, over [ApplianceThemeData.progressStyle]: foreground (the lamps).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).progressStyle,
    ], const {});
    final change = onChanged;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          if (change == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ApplianceSpacing.tight,
              ),
              child: ApplianceLamp(lit: i == index, color: look.foreground),
            )
          else
            DesignPressable(
              onPressed: () => change(i),
              selected: i == index,
              semanticLabel: 'Page ${i + 1} of $count',
              excludeSemantics: true,
              builder: (context, states, _) {
                final c = ApplianceTheme.of(context).colors;
                return DesignTapTarget(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: states.contains(WidgetState.focused)
                            ? c.focus
                            : c.focus.withValues(alpha: 0),
                        width: ApplianceMetrics.focusWidth,
                      ),
                    ),
                    child: ApplianceLamp(
                      lit: i == index,
                      color: look.foreground,
                    ),
                  ),
                );
              },
            ),
      ],
    );
    if (change != null) return row;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: ExcludeSemantics(child: row),
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

/// A menubar: the menus' names on flat keys in a moulded strip; each opens
/// a plate of rows, a row's shortcut in small key caps at its end and a
/// check's lamp lit when it is on. The arrows walk the bar and the menus;
/// Escape closes them.
///
/// ```dart
/// ApplianceMenuBar(menus: [DesignMenuEntry(label: 'List', children: [DesignMenuEntry(label: 'Print', shortcut: 'Ctrl+P', onPressed: () {})])])
/// ```
class ApplianceMenuBar extends StatelessWidget {
  /// A menubar of [menus], each with its [DesignMenuEntry.children].
  const ApplianceMenuBar({
    super.key,
    required this.menus,
    this.semanticLabel,
    this.style,
  });

  /// The top menus.
  final List<DesignMenuEntry> menus;

  /// The bar's name for a screen reader.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.menuStyle]: fill (the bar), the rows.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).menuStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return DesignMenuBar(
      menus: menus,
      semanticLabel: semanticLabel,
      barBuilder: (context, items) => ApplianceSurface(
        face: ApplianceFace.well(
          c,
          radius: ApplianceMetrics.troughRadius,
          fill: look.fill ?? c.trough,
        ),
        // Each key reaches over the well's inset above and below it.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ApplianceMetrics.capInset,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const SizedBox(width: ApplianceMetrics.capInset),
                item,
              ],
            ],
          ),
        ),
      ),
      dividerBuilder: applianceMenuSeam,
      surfaceBuilder: (context, info, items) => applianceMenuPanel(info, items),
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.menu) {
          return applianceMenuEntryRow(context, entry, states, style: style);
        }
        final open = states.contains(WidgetState.selected);
        final down = open || states.contains(WidgetState.pressed);
        final face = ApplianceFace(
          top: down ? c.keyDownTop : c.keyTop.withValues(alpha: 0),
          bottom: down ? c.keyDownBottom : c.keyBottom.withValues(alpha: 0),
          lift: down ? -0.6 : 0,
          travel: down ? 0.6 : 0,
          radius: BorderRadius.circular(
            ApplianceMetrics.troughRadius - ApplianceMetrics.capInset,
          ),
          foreground: entry.enabled ? c.print : c.printDisabled,
          focus: states.contains(WidgetState.focused)
              ? c.focus
              : c.focus.withValues(alpha: 0),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: ApplianceMetrics.capInset,
          ),
          child: SizedBox(
            height: theme.controlHeight - 2 * ApplianceMetrics.capInset,
            child: AnimatedApplianceSurface(
              face: face,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ApplianceSpacing.medium,
                ),
                child: Center(
                  widthFactor: 1,
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(
                      entry.label,
                      style: theme.textTheme.label.copyWith(
                        color: face.foreground,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<DesignMenuEntry>('menus', menus));
  }
}

/// A command palette's body: a search well over the commands, grouped
/// under their headings, the highlighted one lit. Up and Down move the
/// highlight; Enter runs it. Inline on a page it waits to be reached;
/// [showApplianceCommandPalette] opens it on a plate over the page.
///
/// ```dart
/// ApplianceCommandPalette(commands: [DesignCommand(label: 'New list', group: 'Lists', onPressed: () {})])
/// ```
class ApplianceCommandPalette extends StatelessWidget {
  /// A palette over [commands].
  const ApplianceCommandPalette({
    super.key,
    required this.commands,
    this.onSelected,
    this.hint = 'Type a command',
    this.emptyLabel = 'No command matches',
    this.autofocus = false,
    this.maxHeight = 320,
    this.style,
  });

  /// The commands.
  final List<DesignCommand> commands;

  /// Takes the command chosen; null runs its own [DesignCommand.onPressed].
  final ValueChanged<DesignCommand>? onSelected;

  /// What the well says while empty.
  final String hint;

  /// What the list says when nothing matches.
  final String emptyLabel;

  /// Whether the well takes the focus when shown.
  final bool autofocus;

  /// The list's greatest height before it scrolls.
  final double maxHeight;

  /// Its style, over [ApplianceThemeData.menuStyle]: the rows.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return DesignCommandPalette(
      commands: commands,
      onSelected: onSelected,
      autofocus: autofocus,
      maxHeight: maxHeight,
      layoutBuilder: (context, field, results) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          const SizedBox(height: ApplianceSpacing.small),
          results,
        ],
      ),
      fieldBuilder: (context, field) => ListenableBuilder(
        listenable: field.focusNode,
        builder: (context, _) => _PaletteWell(field: field, hint: hint),
      ),
      groupBuilder: (context, group) => Padding(
        padding: const EdgeInsetsDirectional.only(
          start: ApplianceSpacing.medium,
          top: ApplianceSpacing.small,
          bottom: ApplianceSpacing.tight,
        ),
        child: Text(
          group.toUpperCase(),
          style: theme.textTheme.legend.copyWith(color: c.printMuted),
        ),
      ),
      emptyBuilder: (context) => SizedBox(
        height: theme.controlHeight,
        child: Center(
          child: Text(
            emptyLabel,
            style: theme.textTheme.body.copyWith(color: c.printMuted),
          ),
        ),
      ),
      itemBuilder: (context, command, states) => ApplianceMenuRow(
        style: style,
        label: command.label,
        states: states,
        enabled: command.enabled,
        trailing: command.shortcut == null
            ? null
            : MenuShortcut(command.shortcut!),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('commands', commands.length));
  }
}

/// The palette's search well: a lens, then the words. Enter runs the
/// highlighted command from onEditingComplete, so the well keeps its focus
/// (and its typing, on the web) when the palette stays open.
class _PaletteWell extends StatelessWidget {
  const _PaletteWell({required this.field, required this.hint});

  final DesignComboboxField field;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final focused = field.focusNode.hasFocus;
    return AnimatedApplianceSurface(
      face: ApplianceFace.well(c)
          .copyWith(focus: focused ? c.focus : c.focus.withValues(alpha: 0)),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: ApplianceSpacing.medium,
          end: ApplianceSpacing.medium,
        ),
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(size: 20, color: c.printMuted),
              child: const ApplianceGlyph(ApplianceLensPainter.new),
            ),
            const SizedBox(width: ApplianceSpacing.small),
            Expanded(
              child: DesignCapCenter(
                capHeightFactor: theme.capHeightFactor,
                child: ApplianceBareField(
                  controller: field.controller,
                  focusNode: field.focusNode,
                  minHeight: theme.controlHeight,
                  hint: hint,
                  semanticLabel: hint,
                  onEditingComplete: field.submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a command palette on a plate over the page, the page dimmed
/// behind it; Escape or a press outside closes it. A command chosen runs
/// after it closed.
///
/// ```dart
/// showApplianceCommandPalette(context: context, commands: [DesignCommand(label: 'New list', onPressed: () {})])
/// ```
Future<void> showApplianceCommandPalette({
  required BuildContext context,
  required List<DesignCommand> commands,
  String hint = 'Type a command',
}) {
  final c = ApplianceTheme.of(context).colors;
  return showDesignCommandPalette(
    context: context,
    barrierColor: c.scrim,
    palette: (run) => DesignCommandPalette(
      commands: commands,
      onSelected: run,
      fieldBuilder: (context, field) => ListenableBuilder(
        listenable: field.focusNode,
        builder: (context, _) => _PaletteWell(field: field, hint: hint),
      ),
      itemBuilder: (context, command, states) => ApplianceMenuRow(
        label: command.label,
        states: states,
        enabled: command.enabled,
        trailing: command.shortcut == null
            ? null
            : MenuShortcut(command.shortcut!),
      ),
      groupBuilder: (context, group) {
        final theme = ApplianceTheme.of(context);
        return Padding(
          padding: const EdgeInsetsDirectional.only(
            start: ApplianceSpacing.medium,
            top: ApplianceSpacing.small,
            bottom: ApplianceSpacing.tight,
          ),
          child: Text(
            group.toUpperCase(),
            style: theme.textTheme.legend.copyWith(
              color: theme.colors.printMuted,
            ),
          ),
        );
      },
      layoutBuilder: (context, field, results) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          const SizedBox(height: ApplianceSpacing.small),
          results,
        ],
      ),
    ),
    surfaceBuilder: (context, palette) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ApplianceSpacing.regular,
        ),
        child: ApplianceSurface(
          face: ApplianceFace.plate(ApplianceTheme.of(context).colors),
          child: Padding(
            padding: const EdgeInsets.all(ApplianceSpacing.medium),
            child: palette,
          ),
        ),
      ),
    ),
  );
}
