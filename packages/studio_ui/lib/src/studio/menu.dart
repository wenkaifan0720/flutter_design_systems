/// Studio's menus: [StudioMenuItem] (one action), [StudioMenu] (a list of
/// them that a key opens), [StudioMenuBar] (a desktop's row of menus on a
/// faceplate) and [StudioCommandPalette] (find an action by typing, as a
/// panel or with [showStudioCommandPalette]). Every open list is glass in a
/// bezel ([StudioListBezel]) with [StudioMenuRow] rows.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'internal/strip.dart';
import 'select.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

/// One action in a menu: words, a glyph, its keys.
///
/// ```dart
/// StudioMenuItem(label: 'Rename', icon: const Icon(LucideIcons.pencil), onPressed: rename)
/// ```
@immutable
class StudioMenuItem {
  /// An action [label]led; a null [onPressed] disables it.
  const StudioMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.shortcut,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// What it does; null disables it.
  final VoidCallback? onPressed;

  /// A glyph before its words.
  final Widget? icon;

  /// The keys that do it too, printed at its end (`⌘ R`).
  final String? shortcut;

  /// Whether it destroys something: its words in the danger colour.
  final bool isDestructiveAction;
}

/// A menu: [builder] draws what opens it (a key, given `toggle` and
/// whether it is `open`), and [items] open in a glass list under it. Down
/// on the opener opens it too; the arrows walk the rows, a letter jumps to
/// the next row starting with it, Escape closes it.
///
/// ```dart
/// StudioMenu(items: [StudioMenuItem(label: 'Rename', onPressed: rename)], builder: (context, toggle, open) => StudioIconButton(icon: const Icon(LucideIcons.ellipsis), tooltip: 'More', selected: open, onPressed: toggle))
/// ```
class StudioMenu extends StatelessWidget {
  /// A menu of [items].
  const StudioMenu({
    super.key,
    required this.items,
    required this.builder,
    this.semanticLabel,
    this.alignEnd = false,
  });

  /// The actions.
  final List<StudioMenuItem> items;

  /// The opener.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What a screen reader calls the menu.
  final String? semanticLabel;

  /// Whether the list lines up with the opener's end, not its start.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    arrowKeyNavigation: true,
    semanticLabel: semanticLabel,
    placement: DesignOverlayPlacement(
      align: alignEnd ? DesignOverlayAlign.end : DesignOverlayAlign.start,
      gap: StudioSpacing.tight,
      margin: StudioSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: StudioMotion.dampingRatio,
    stiffness: StudioMotion.overlayStiffness,
    anchorBuilder: (context, anchor) => Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.arrowDown ||
            anchor.isOpen) {
          return KeyEventResult.ignored;
        }
        anchor.open();
        return KeyEventResult.handled;
      },
      child: builder(context, anchor.toggle, anchor.isOpen),
    ),
    overlayBuilder: (context, info) => FadeTransition(
      opacity: info.animation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
        child: IntrinsicWidth(
          child: StudioMenuList<int>(
            showLamps: false,
            items: [
              for (final (i, item) in items.indexed)
                StudioMenuEntry(
                  value: i,
                  label: item.label,
                  icon: item.icon,
                  shortcut: item.shortcut,
                  enabled: item.onPressed != null,
                  isDestructiveAction: item.isDestructiveAction,
                ),
            ],
            onChosen: (i) {
              info.close();
              items[i].onPressed?.call();
            },
          ),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('items', items.length))
      ..add(FlagProperty('alignEnd', value: alignEnd, ifTrue: 'align end'));
  }
}

/// One menu of a [StudioMenuBar]: its title and its actions.
///
/// ```dart
/// StudioMenuBarMenu('Episode', [StudioMenuItem(label: 'New', shortcut: '⌘ N', onPressed: create)])
/// ```
@immutable
class StudioMenuBarMenu {
  /// A menu titled [label].
  const StudioMenuBarMenu(this.label, this.items);

  /// Its title in the bar.
  final String label;

  /// Its actions.
  final List<StudioMenuItem> items;
}

/// A desktop's menu bar: the menus' titles engraved along a brushed
/// faceplate; the open menu's title sits in a slot with its words lit, its
/// list hanging below it. The arrows cross the bar and walk the lists.
///
/// Built on ui_core's DesignMenuBar.
///
/// Reads [style]'s `fill` (the plate), `minimumSize` (its height) and
/// `textStyle`, then [StudioThemeData.menuBarStyle].
///
/// ```dart
/// StudioMenuBar(menus: [StudioMenuBarMenu('Episode', [StudioMenuItem(label: 'New', onPressed: create)])])
/// ```
class StudioMenuBar extends StatelessWidget {
  /// A bar of [menus].
  const StudioMenuBar({super.key, required this.menus, this.style});

  /// The menus, in order.
  final List<StudioMenuBarMenu> menus;

  /// Its style, over [StudioThemeData.menuBarStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.menuBarStyle];
    final bar = DesignStyleOf(layers, const {});
    // Its titles stand a recess inset in from the bar's edges; where a finger
    // reaches them the bar grows so each title is a finger's floor tall.
    final height = math.max(
      bar.minimumSize?.height ?? 40.0,
      DesignTapTargets.of(context).floorOn().height +
          2 * StudioMetrics.recessInset,
    );
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
      barBuilder: (context, items) => StudioSurface(
        face: c.panelFace.copyWith(
          radius: StudioRadii.small,
          fill: bar.fill,
          brushed: true,
        ),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.tight,
              vertical: StudioMetrics.recessInset,
            ),
            child: StudioStrip(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.menu) {
          final item = entry.data as StudioMenuItem?;
          return StudioMenuRow(
            label: entry.label,
            icon: item?.icon,
            isDestructiveAction: item?.isDestructiveAction ?? false,
            states: states,
            trailing: entry.shortcut == null ? null : Text(entry.shortcut!),
          );
        }
        final layered = DesignStyleOf(layers, states);
        final open =
            states.contains(WidgetState.selected) ||
            states.contains(WidgetState.pressed);
        final ink = open ? c.litLegend : layered.foreground ?? c.legend;
        return AnimatedStudioSurface(
          stiffness: StudioMotion.lampStiffness,
          face: c.recessFace.copyWith(
            radius: StudioRadii.small - 1,
            presence: open || states.contains(WidgetState.hovered) ? 1 : 0,
            focus: states.contains(WidgetState.focused)
                ? c.focusRing
                : c.focusRing.withValues(alpha: 0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.medium,
            ),
            child: Center(
              widthFactor: 1,
              child: DesignCapCenter(
                capHeightFactor: theme.capHeightFactor,
                child: Text(
                  entry.label,
                  maxLines: 1,
                  style: layered.text(
                    theme.textTheme.label.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w500,
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 220,
            maxWidth: 320,
            maxHeight: info.maxSize.height,
          ),
          child: StudioListBezel(
            child: IntrinsicWidth(
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
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('menus', menus.length));
  }
}

/// A command a [StudioCommandPalette] finds.
///
/// ```dart
/// StudioCommand(label: 'New episode', group: 'Episodes', shortcut: '⌘ N', onPressed: create)
/// ```
@immutable
class StudioCommand {
  /// A command [label]led; a null [onPressed] disables it.
  const StudioCommand({
    required this.label,
    required this.onPressed,
    this.group,
    this.icon,
    this.shortcut,
    this.keywords = const [],
  });

  /// Its words.
  final String label;

  /// What it does; null disables it.
  final VoidCallback? onPressed;

  /// The heading it lists under.
  final String? group;

  /// A glyph before its words.
  final Widget? icon;

  /// The keys that do it too.
  final String? shortcut;

  /// Other words that find it.
  final List<String> keywords;
}

/// A command palette: a search window over a glass list of commands,
/// grouped under printed headings, that narrows as you type. The arrows
/// walk the list and Enter runs the lit command; the search keeps the
/// keyboard throughout (Enter is taken in its editing-complete, never its
/// submit, so on the web typing carries on).
///
/// Built on ui_core's DesignCommandPalette. Show it over a page with
/// [showStudioCommandPalette].
///
/// Reads [style]'s `fill` (the panel), then
/// [StudioThemeData.commandPaletteStyle].
///
/// ```dart
/// StudioCommandPalette(commands: commands, onSelected: (c) => c.onPressed?.call())
/// ```
class StudioCommandPalette extends StatelessWidget {
  /// A palette of [commands].
  const StudioCommandPalette({
    super.key,
    required this.commands,
    this.onSelected,
    this.hint = 'Type a command or search',
    this.emptyText = 'No commands match',
    this.autofocus = false,
    this.style,
  });

  /// What it finds.
  final List<StudioCommand> commands;

  /// Called with the command taken.
  final ValueChanged<StudioCommand>? onSelected;

  /// What the search says while empty.
  final String hint;

  /// What the list says when nothing matches.
  final String emptyText;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [StudioThemeData.commandPaletteStyle].
  final StudioStyle? style;

  DesignCommandPalette _body(ValueChanged<DesignCommand>? run) =>
      DesignCommandPalette(
        commands: [
          for (final c in commands)
            DesignCommand(
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
        fieldBuilder: (context, field) => StudioTextField(
          controller: field.controller,
          focusNode: field.focusNode,
          hint: hint,
          semanticLabel: hint,
          textCapitalization: TextCapitalization.none,
          prefixIcon: const Icon(LucideIcons.search),
          // Enter runs the lit command and the search keeps the keyboard.
          onEditingComplete: field.submit,
        ),
        itemBuilder: (context, command, states) {
          final c = command.data! as StudioCommand;
          return StudioMenuRow(
            label: c.label,
            icon: c.icon,
            states: states,
            trailing: c.shortcut == null ? null : Text(c.shortcut!),
          );
        },
        groupBuilder: (context, group) {
          final theme = StudioTheme.of(context);
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              StudioSpacing.medium,
              StudioSpacing.medium,
              StudioSpacing.medium,
              StudioSpacing.tight,
            ),
            child: StudioLegend(group, color: theme.colors.onDisplayMuted),
          );
        },
        emptyBuilder: (context) {
          final theme = StudioTheme.of(context);
          return Padding(
            padding: const EdgeInsets.all(StudioSpacing.medium),
            child: Text(
              emptyText,
              style: theme.textTheme.secondary.copyWith(
                color: theme.colors.onDisplayMuted,
              ),
            ),
          );
        },
        layoutBuilder: (context, field, results) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field,
            const SizedBox(height: StudioSpacing.small),
            Flexible(
              child: StudioSurface(
                face: StudioTheme.of(context).colors.displayFace
                    .copyWith(radius: StudioRadii.bank),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(StudioRadii.bank),
                  child: Padding(
                    padding: const EdgeInsets.all(StudioMetrics.recessInset),
                    child: results,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => _panel(
    context,
    style,
    _body(
      onSelected == null ? null : (c) => onSelected!(c.data! as StudioCommand),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('commands', commands.length))
      ..add(StringProperty('hint', hint));
  }
}

Widget _panel(BuildContext context, StudioStyle? style, Widget child) {
  final theme = StudioTheme.of(context);
  final c = theme.colors;
  final night = c.brightness == Brightness.dark;
  final layered = DesignStyleOf([style, theme.commandPaletteStyle], const {});
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StudioRadii.panel),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: night ? 0.6 : 0.3),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: StudioSurface(
        face: layered.on(
          c.panelFace.copyWith(radius: StudioRadii.panel, brushed: true),
        ),
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              const EdgeInsets.all(StudioSpacing.medium),
          child: child,
        ),
      ),
    ),
  );
}

/// Shows a [StudioCommandPalette] of [commands] over the page, under a
/// dimmed barrier, and runs the command taken.
///
/// ```dart
/// showStudioCommandPalette(context, commands: commands)
/// ```
Future<void> showStudioCommandPalette(
  BuildContext context, {
  required List<StudioCommand> commands,
  String hint = 'Type a command or search',
  StudioStyle? style,
}) {
  final scrim = StudioTheme.of(context).colors.scrim;
  return showDesignCommandPalette(
    context: context,
    barrierColor: scrim,
    palette: (run) => StudioCommandPalette(
      commands: commands,
      hint: hint,
      autofocus: true,
      style: style,
    )._body(run),
    surfaceBuilder: (context, palette) => Padding(
      padding: const EdgeInsets.all(StudioSpacing.regular),
      child: _panel(context, style, palette),
    ),
  ).then((_) {});
}
