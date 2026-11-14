/// Every action a page can run, searchable from one field, painted on
/// ui_core's command palette.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/controls.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'code.dart';
import 'search.dart';
import 'states.dart';

/// The palette's measure: the tallest the result list grows (as a share of
/// the screen, and absolutely), a result row's side padding and the shown
/// palette's width.
abstract final class _CommandMetrics {
  static const double listShare = 0.55;
  static const double listMax = 420;
  static const double rowPad = 8;
  static const double width = 560;
}

/// One action a [MinimalCommand] offers: its [label], an optional glyph,
/// the [group] it is listed under, its keyboard [shortcut] printed as key
/// caps, and the extra [keywords] a search should also match.
///
/// [onSelected] runs when the action is chosen; an action without one is
/// listed but disabled.
///
/// ```dart
/// MinimalCommandItem('New habit', icon: LucideIcons.plus, group: 'Habits', shortcut: 'N', onSelected: create)
/// ```
@immutable
class MinimalCommandItem {
  /// A command saying [label].
  const MinimalCommandItem(
    this.label, {
    this.icon,
    this.group,
    this.detail,
    this.shortcut,
    this.keywords = const <String>[],
    this.onSelected,
  });

  /// What the command says, and what a query matches first.
  final String label;

  /// A glyph before the label.
  final IconData? icon;

  /// The heading the action is listed under; actions keep the order their
  /// groups first appear in.
  final String? group;

  /// A quiet second word after the label (`HAB-4`, `Morning`).
  final String? detail;

  /// The action's shortcut as a chord of space-separated keys (`'⌘ K'`,
  /// `'G T'`), printed as caps by [MinimalKbd.chord] — the same shape a
  /// [MinimalMenuItem] and a [MinimalSearchField] take.
  final String? shortcut;

  /// The chord's keys, one per cap.
  List<String> get _keys => shortcut == null
      ? const <String>[]
      : shortcut!.split(' ').where((k) => k.isNotEmpty).toList();

  /// More words a search matches the action by.
  final List<String> keywords;

  /// What choosing the action does; null lists it disabled.
  final VoidCallback? onSelected;

  /// Whether it can run: it has an [onSelected].
  bool get enabled => onSelected != null;

  /// What ui_core's palette lists: its words, and the group and detail as
  /// more words a search matches.
  DesignCommand _design() => DesignCommand(
    label: label,
    onPressed: onSelected,
    group: group,
    keywords: [...keywords, ?group, ?detail],
    shortcut: shortcut,
    enabled: enabled,
    data: this,
  );
}

/// Minimal's command palette — every action a page can run, searchable
/// from one field: type to filter (the best matches first, by words and
/// initials), arrow keys to move the highlight, Enter to run it; a pointer
/// moves the highlight too. Results are listed under their groups, each
/// row a glyph, the label and its shortcut as key caps; nothing matching
/// prints an empty state, and a screen reader hears how many match. The
/// field is a [MinimalSearchField], clear cap and all. Result rows are the
/// dense 36 px register (`t.rowHeightCompact`), grown with larger text —
/// with the table's 40 and the menu's and time columns' 32, the dense-list
/// exception to the 44 px target: a palette is walked by keyboard and read
/// far more than it is tapped.
///
/// [show] presents it in a card over the app and runs the chosen action
/// once the card has closed and focus is back. Compose the widget directly
/// for a palette that lives in a panel; [onSelected] then hears the choice
/// (and the action's own `onSelected` is the caller's to run). The
/// behaviour is ui_core's ([DesignCommandPalette]); Minimal paints it.
///
/// [style] dresses this palette's result rows, `components.command` every
/// palette's, resolved with [WidgetState.selected] on the highlighted one:
/// fill (the highlight), foreground (the glyph), overlay, shape (else
/// `shapes.small`) and padding.
///
/// ```dart
/// MinimalCommand.show(context, actions: [MinimalCommandItem('New habit', icon: LucideIcons.plus, shortcut: 'N', onSelected: create)])
/// ```
class MinimalCommand extends StatefulWidget {
  /// A palette of [actions].
  const MinimalCommand({
    super.key,
    required this.actions,
    this.onSelected,
    this.hint,
    this.initialQuery = '',
    this.autofocus = true,
    this.focusNode,
    this.emptyTitle,
    this.style,
  });

  /// The search field's focus, when the app moves it.
  final FocusNode? focusNode;

  /// The commands, in the order they list.
  final List<MinimalCommandItem> actions;

  /// The chosen action.
  final ValueChanged<MinimalCommandItem>? onSelected;

  /// The search field's placeholder.
  final String? hint;

  /// The search the palette opens with.
  final String initialQuery;

  /// Focus the search field at once, so typing filters and the arrow keys
  /// move the highlight. Off, the palette waits for a tap or Tab (a
  /// palette composed in a page that should not scroll to it).
  final bool autofocus;

  /// The empty state's title when nothing matches.
  final String? emptyTitle;

  /// This palette's result rows, over `components.command`.
  final MinimalStyle? style;

  /// Present the palette in a card over the whole app, a third of the way
  /// down, on a dimmed page. The chosen action's `onSelected` runs after
  /// the card has closed, and the future completes with that action (null
  /// when dismissed). [title] is what a screen reader calls it; [subtitle]
  /// (what it acts in) stands as a pill over the field.
  static Future<MinimalCommandItem?> show(
    BuildContext context, {
    required List<MinimalCommandItem> actions,
    String? title,
    String? subtitle,
    String? hint,
    String? emptyTitle,
    MinimalStyle? style,
  }) async {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    MinimalCommandItem? chosen;
    await showDesignCommandPalette(
      context: context,
      barrierColor: t.overlay,
      barrierLabel: words.close,
      alignment: const Alignment(0, -0.5),
      palette: (run) => _palette(
        context,
        actions: actions,
        hint: hint,
        emptyTitle: emptyTitle,
        style: style,
        label: title ?? words.commands,
        onSelected: (c) {
          chosen = c.data as MinimalCommandItem?;
          run(c);
        },
      ),
      surfaceBuilder: (context, palette) =>
          _Card(subtitle: subtitle, child: palette),
    );
    return chosen;
  }

  @override
  State<MinimalCommand> createState() => _MinimalCommandState();
}

/// ui_core's palette, Minimal's paint.
DesignCommandPalette _palette(
  BuildContext context, {
  required List<MinimalCommandItem> actions,
  required String label,
  String? hint,
  String? emptyTitle,
  MinimalStyle? style,
  TextEditingController? controller,
  ValueChanged<DesignCommand>? onSelected,
  bool autofocus = true,
  FocusNode? focusNode,
}) {
  final words = MinimalLocalizations.of(context);
  final listMax = math.min(
    _CommandMetrics.listMax,
    MediaQuery.sizeOf(context).height * _CommandMetrics.listShare,
  );
  return DesignCommandPalette(
    commands: [for (final a in actions) a._design()],
    controller: controller,
    onSelected: onSelected,
    autofocus: autofocus,
    focusNode: focusNode,
    maxHeight: listMax,
    semanticLabel: label,
    resultsMessage: words.results,
    fieldBuilder: (context, f) => Padding(
      padding: const EdgeInsets.only(bottom: MinimalSpacing.s4),
      child: MinimalSearchField(
        controller: f.controller,
        focusNode: f.focusNode,
        hint: hint ?? words.commandHint,
        onSubmitted: (_) => f.submit(),
        clearable: true,
      ),
    ),
    groupBuilder: (context, group) => _GroupHeader(label: group),
    emptyBuilder: (context) => MinimalEmptyState(
      icon: LucideIcons.searchX,
      title: emptyTitle ?? words.noMatchingCommands,
      body: controller == null
          ? null
          : words.nothingMatches(controller.text.trim()),
    ),
    itemBuilder: (context, command, states) => _ResultRow(
      action: command.data! as MinimalCommandItem,
      highlighted: states.contains(WidgetState.focused),
      states: states,
      style: style,
    ),
  );
}

class _MinimalCommandState extends State<MinimalCommand> {
  late final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // After the palette's own post-frame focus: the start query filters
      // as typing would.
      scheduleMicrotask(() {
        if (!mounted) return;
        if (widget.initialQuery.isNotEmpty) _query.text = widget.initialQuery;
      });
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSelected = widget.onSelected;
    return Material(
      type: MaterialType.transparency,
      child: _palette(
        context,
        actions: widget.actions,
        hint: widget.hint,
        emptyTitle: widget.emptyTitle,
        style: widget.style,
        controller: _query,
        label: MinimalLocalizations.of(context).commands,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        onSelected: onSelected == null
            ? null
            : (c) => onSelected(c.data! as MinimalCommandItem),
      ),
    );
  }
}

/// The air a search field's 44 px band keeps over its box at the theme's
/// density and text size (8 at compact, 6 at standard, none once the box
/// fills the band).
double _fieldAir(BuildContext context) {
  final t = context.minimalTheme;
  final box = minimalGrownHeight(
    context,
    t.density.height(MinimalChromeMetrics.control),
  );
  return math.max(0, (MinimalLayout.minHitTarget - box) / 2);
}

/// The shown palette's card: the surface on `shapes.large` with its rim and
/// the large shadow, at most 560 px wide, padded 8 px; [subtitle] as a pill
/// over the field.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.subtitle});

  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shape = t.shapes.large;
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinimalChromeMetrics.gutter,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _CommandMetrics.width),
        child: Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: minimalFrame(
              shape,
              fill: t.card,
              side: BorderSide(color: t.border, width: t.rim),
              shadows: t.shadowLg,
            ),
            child: minimalClip(
              shape,
              child: Padding(
                // The field's 44 px band keeps air over its box; the card
                // takes it off its own top, so the field stands 8 px from
                // the card's top as from its sides. A pill over it stands
                // on the full 8.
                padding: EdgeInsets.fromLTRB(
                  MinimalSpacing.s8,
                  subtitle == null
                      ? math.max(0, MinimalSpacing.s8 - _fieldAir(context))
                      : MinimalSpacing.s8,
                  MinimalSpacing.s8,
                  MinimalSpacing.s8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (subtitle != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: MinimalSpacing.s8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: MinimalSpacing.s8,
                            vertical: MinimalSpacing.s2,
                          ),
                          decoration: minimalFrame(
                            t.shapes.pill,
                            fill: t.muted,
                          ),
                          child: Text(
                            subtitle,
                            style: t.caption.medium.c(t.mutedForeground),
                          ),
                        ),
                      ),
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // ui_core marks it a heading. Every group opens on the same air, more
    // than lies between two rows, so a label reads as a break and stands
    // close over its own rows.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _CommandMetrics.rowPad,
        MinimalSpacing.s16,
        _CommandMetrics.rowPad,
        MinimalSpacing.s4,
      ),
      child: Text(
        label.toUpperCase(),
        style: t.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.action,
    required this.highlighted,
    required this.states,
    this.style,
  });

  final MinimalCommandItem action;
  final bool highlighted;
  final Set<WidgetState> states;
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final icon = action.icon;
    final detail = action.detail;
    final keys = action._keys;
    final so = MinimalStyleOf(
      [style, t.components.command],
      {
        ...states.where(
          (s) => s != WidgetState.selected && s != WidgetState.focused,
        ),
        if (highlighted) WidgetState.selected,
      },
    );
    final shape = so.shape ?? t.shapes.small;
    final pressed = states.contains(WidgetState.pressed);
    return Semantics(
      label: keys.isEmpty
          ? action.label
          : '${action.label}, ${keys.map(MinimalKbd.spokenName).join(' ')}',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: action.enabled ? 1 : 0.45,
          child: Container(
            // Larger text grows the row, so its words keep their air.
            constraints: BoxConstraints(
              minHeight: minimalGrownHeight(context, t.rowHeightCompact),
            ),
            padding:
                so.padding ??
                const EdgeInsets.symmetric(horizontal: _CommandMetrics.rowPad),
            decoration: minimalFrame(
              shape,
              fill: so.fill ?? (highlighted ? t.selection : null),
            ),
            foregroundDecoration: pressed
                ? minimalFrame(
                    shape,
                    fill: so.overlay ?? t.foreground.withValues(alpha: 0.06),
                  )
                : null,
            child: Row(
              children: [
                if (icon != null) ...[
                  MinimalIcon(
                    icon,
                    size: MinimalIconSize.i16,
                    color:
                        so.foreground ??
                        (highlighted ? t.foreground : t.mutedForeground),
                  ),
                  const MinimalGap(MinimalSpacing.s8 + MinimalSpacing.s2),
                ],
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: action.label, style: t.body),
                        if (detail != null)
                          TextSpan(
                            text: '  $detail',
                            style: t.mono.c(t.mutedForeground),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (keys.isNotEmpty) ...[
                  const MinimalGap(MinimalSpacing.s8),
                  MinimalKbd.chord(action.shortcut!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
