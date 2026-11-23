/// Keycap's menus and small panels over the keyboard: [KeycapMenu] (a
/// key's list of actions), [KeycapContextMenu] (a secondary click's or a
/// long press's), [KeycapMenuBar] (a row of small keys, as a keyboard's
/// function row, each opening its menu), [KeycapCommandPalette] (a search
/// over every command), [KeycapPopover], [KeycapHoverCard] and
/// [KeycapTooltip]. Every open list is a [KeycapMenuPanel] of
/// [KeycapMenuRow]s, the one lit row on a plate inset in it.
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'select.dart';
import 'theme.dart';

// The ui_core types these parts' APIs take, through the look's barrel.
export 'package:ui_core/ui_core.dart' show DesignOverlayAnchor;
export 'package:ui_core/ui_core.dart' show RawCommand;
export 'package:ui_core/ui_core.dart' show RawMenuEntry;

double _rowHeight(BuildContext context) =>
    KeycapTheme.of(context).controlHeight - KeycapSpacing.tight;

bool _lit(Set<WidgetState> states) =>
    states.contains(WidgetState.focused) ||
    states.contains(WidgetState.hovered) ||
    states.contains(WidgetState.pressed);

/// A menu entry's row: its words (in the danger ink when the entry
/// destroys something), its shortcut or a chevron to its submenu at the
/// end, a tick when it is checked.
Widget _entryRow(
  BuildContext context,
  RawMenuEntry entry,
  Set<WidgetState> states,
) {
  final enabled = entry.enabled && !states.contains(WidgetState.disabled);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return KeycapMenuRow(
    label: entry.label,
    height: _rowHeight(context),
    enabled: enabled,
    chosen: entry.checked ?? false,
    isDestructiveAction: entry.isDestructiveAction,
    lit: enabled && (_lit(states) || states.contains(WidgetState.selected)),
    trailing: entry.children != null
        ? Icon(rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight)
        : entry.shortcut == null
        ? null
        : Text(entry.shortcut!),
  );
}

/// A hairline between groups of rows.
Widget _divider(BuildContext context) {
  final c = KeycapTheme.of(context).colors;
  return Padding(
    padding: const EdgeInsets.symmetric(
      vertical: KeycapSpacing.tight,
      horizontal: KeycapSpacing.small,
    ),
    child: SizedBox(height: 1, child: ColoredBox(color: c.hairline)),
  );
}

/// The panel a menu's rows stand on, revealed as [info] runs.
Widget _panel(RawPopoverInfo info, List<Widget> items) => KeycapMenuReveal(
  animation: info.animation,
  below: info.side != RawPopoverSide.above,
  child: ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 200),
    child: KeycapMenuPanel(
      maxHeight: info.maxSize.height,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        ),
      ),
    ),
  ),
);

/// A key's menu: its actions in a panel laid over the keyboard. [builder]
/// draws the key (usually a [KeycapIconButton] with a "More" glyph) and
/// gets the anchor to open it with. The arrows move the lit row; Enter
/// runs it; Escape closes the menu and gives the key back its focus. An
/// entry marked [RawMenuEntry.isDestructiveAction] prints in the danger
/// ink.
///
/// ```dart
/// KeycapMenu(entries: [RawMenuEntry(label: 'Rename', onPressed: rename), const RawMenuEntry.divider(), RawMenuEntry(label: 'Delete', isDestructiveAction: true, onPressed: delete)], builder: (context, anchor) => KeycapIconButton(icon: const Icon(LucideIcons.ellipsis), semanticLabel: 'More', onPressed: anchor.toggle))
/// ```
class KeycapMenu extends StatelessWidget {
  /// A menu of [entries].
  const KeycapMenu({
    super.key,
    required this.entries,
    required this.builder,
    this.semanticLabel,
  });

  /// The rows.
  final List<RawMenuEntry> entries;

  /// Draws the key that opens it.
  final Widget Function(BuildContext context, DesignOverlayAnchor anchor)
  builder;

  /// The menu's name, for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => RawPopover(
    arrowKeyNavigation: true,
    semanticLabel: semanticLabel,
    placement: const RawPopoverPlacement(
      gap: KeycapSpacing.tight + 2,
      margin: KeycapSpacing.small,
      matchAnchorWidth: false,
      maxWidth: 320,
    ),
    dampingRatio: KeycapMotion.panel.dampingRatio,
    stiffness: KeycapMotion.panel.stiffness,
    anchorBuilder: builder,
    overlayBuilder: (context, info) => _panel(info, [
      for (final entry in entries)
        if (entry.divider)
          _divider(context)
        else
          RawButton(
            onPressed: entry.onPressed == null
                ? null
                : () {
                    info.close();
                    entry.onPressed!();
                  },
            checked: entry.checked,
            semanticLabel: entry.label,
            excludeSemantics: true,
            builder: (context, states, _) => KeycapMenuRow(
              label: entry.label,
              height: _rowHeight(context),
              enabled: entry.onPressed != null,
              chosen: entry.checked ?? false,
              isDestructiveAction: entry.isDestructiveAction,
              lit: entry.onPressed != null && _lit(states),
              trailing: entry.shortcut == null ? null : Text(entry.shortcut!),
            ),
          ),
    ]),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}

/// A menu that opens where a secondary click or a long press lands on
/// [child] (a note's row, a folder). Built on ui_core's
/// `RawContextMenu`. An entry marked [RawMenuEntry.isDestructiveAction]
/// prints in the danger ink.
///
/// ```dart
/// KeycapContextMenu(entries: [RawMenuEntry(label: 'Pin', onPressed: pin)], child: row)
/// ```
class KeycapContextMenu extends StatelessWidget {
  /// A context menu over [child].
  const KeycapContextMenu({
    super.key,
    required this.entries,
    required this.child,
    this.semanticLabel,
  });

  /// The rows.
  final List<RawMenuEntry> entries;

  /// What it opens over.
  final Widget child;

  /// The menu's name, for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => RawContextMenu(
    menuChildren: entries,
    semanticLabel: semanticLabel,
    dampingRatio: KeycapMotion.panel.dampingRatio,
    stiffness: KeycapMotion.panel.stiffness,
    itemBuilder: (context, entry, level, states) =>
        _entryRow(context, entry, states),
    surfaceBuilder: (context, info, items) => _panel(info, items),
    dividerBuilder: _divider,
    child: MouseRegion(
      cursor: SystemMouseCursors.contextMenu,
      hitTestBehavior: HitTestBehavior.opaque,
      child: child,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('entries', entries.length));
  }
}

/// A row of menus, as a keyboard's function row: small modifier keys set
/// side by side, each opening its menu in a panel under it and staying part
/// way down while it is open. The arrows move along the row and through a
/// menu. Built on ui_core's `RawMenuBar`.
///
/// ```dart
/// KeycapMenuBar(menus: [RawMenuEntry(label: 'File', children: [RawMenuEntry(label: 'New note', shortcut: 'Ctrl+N', onPressed: newNote)])])
/// ```
class KeycapMenuBar extends StatelessWidget {
  /// A menubar of [menus].
  const KeycapMenuBar({super.key, required this.menus, this.semanticLabel});

  /// The menus, each with its rows as children.
  final List<RawMenuEntry> menus;

  /// The bar's name, for a screen reader.
  final String? semanticLabel;

  /// A key's height.
  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return RawMenuBar(
      menus: menus,
      semanticLabel: semanticLabel,
      barBuilder: (context, items) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(width: KeycapMetrics.keyGap),
            item,
          ],
        ],
      ),
      dividerBuilder: _divider,
      surfaceBuilder: (context, info, items) => _panel(info, items),
      itemBuilder: (context, entry, level, states) {
        if (level == RawMenuLevel.menu) {
          return _entryRow(context, entry, states);
        }
        final open = states.contains(WidgetState.selected);
        var face = keycapKeyFace(theme, KeycapKind.modifier, {
          ...states,
          if (!entry.enabled) WidgetState.disabled,
        }, radius: KeycapMetrics.smallKeyRadius);
        if (open && !states.contains(WidgetState.pressed)) {
          face = face.copyWith(travel: keycapLatchTravel);
        }
        final tall = KeycapMetrics.grown(
          context,
          height,
          theme.textTheme.secondary,
        );
        return TapTargetPadding(
          child: SizedBox(
            height: tall,
            child: AnimatedKeycapCap(
              face: face,
              walls: KeycapMetrics.walls(tall),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KeycapSpacing.medium,
                ),
                child: Center(
                  widthFactor: 1,
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(
                      entry.label,
                      maxLines: 1,
                      style: theme.textTheme.secondary.copyWith(
                        color: face.legend,
                        fontWeight: FontWeight.w500,
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
    properties.add(IntProperty('menus', menus.length));
  }
}

/// The palette's search well.
class _PaletteWell extends StatelessWidget {
  const _PaletteWell({required this.field, required this.hint});

  final DesignComboboxField field;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final focused = field.focusNode.hasFocus;
    final words = theme.textTheme.body.copyWith(color: c.ink);
    return KeycapWell(
      radius: BorderRadius.circular(KeycapMetrics.fieldRadius),
      rim: focused ? c.focus : null,
      clip: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.medium),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 20, color: c.inkMuted),
            const SizedBox(width: KeycapSpacing.small),
            Expanded(
              child: DesignCapCenter(
                capHeightFactor: theme.capHeightFactor,
                child: Semantics(
                  container: true,
                  label: hint,
                  child: DesignTextEntryBox(
                    minHeight: theme.controlHeight,
                    controller: field.controller,
                    hint: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: words.copyWith(color: c.inkMuted),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        controller: field.controller,
                        focusNode: field.focusNode,
                        decoration: null,
                        style: words,
                        cursorColor: c.accent.top,
                        cursorWidth: 2,
                        onEditingComplete: field.submit,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

RawCommandPalette _palette({
  required List<RawCommand> commands,
  required ValueChanged<RawCommand>? onSelected,
  required String hint,
  required String emptyLabel,
  bool autofocus = true,
  double maxHeight = 360,
}) => RawCommandPalette(
  commands: commands,
  onSelected: onSelected,
  autofocus: autofocus,
  maxHeight: maxHeight,
  layoutBuilder: (context, field, results) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      field,
      const SizedBox(height: KeycapSpacing.small),
      results,
    ],
  ),
  fieldBuilder: (context, field) => ListenableBuilder(
    listenable: field.focusNode,
    builder: (context, _) => _PaletteWell(field: field, hint: hint),
  ),
  groupBuilder: (context, group) {
    final theme = KeycapTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: KeycapSpacing.medium,
        top: KeycapSpacing.small,
        bottom: KeycapSpacing.tight,
      ),
      child: Text(
        group.toUpperCase(),
        style: theme.textTheme.legend.copyWith(color: theme.colors.inkMuted),
      ),
    );
  },
  emptyBuilder: (context) {
    final theme = KeycapTheme.of(context);
    return SizedBox(
      height: theme.controlHeight,
      child: Center(
        child: Text(
          emptyLabel,
          style: theme.textTheme.body.copyWith(color: theme.colors.inkMuted),
        ),
      ),
    );
  },
  itemBuilder: (context, command, states) => KeycapMenuRow(
    label: command.label,
    height: _rowHeight(context),
    enabled: command.enabled,
    lit: command.enabled && _lit(states),
    trailing: command.shortcut == null ? null : Text(command.shortcut!),
  ),
);

/// A search over every command: a well to type in over the commands that
/// fit, grouped, the lit one run by Enter. Inline here; laid over the
/// screen by [showKeycapCommandPalette]. Built on ui_core's
/// `RawCommandPalette`.
///
/// ```dart
/// KeycapCommandPalette(commands: [RawCommand(label: 'New note', group: 'Notes', shortcut: 'Ctrl+N', onPressed: newNote)])
/// ```
class KeycapCommandPalette extends StatelessWidget {
  /// A palette of [commands].
  const KeycapCommandPalette({
    super.key,
    required this.commands,
    this.onSelected,
    this.hintText,
    this.emptyLabel,
    this.autofocus = false,
    this.maxHeight = 320,
  });

  /// What can be run.
  final List<RawCommand> commands;

  /// Called with the command run.
  final ValueChanged<RawCommand>? onSelected;

  /// What the empty well says; the kit's "Search" when null.
  final String? hintText;

  /// What the list says when nothing fits; the kit's "No results" when
  /// null.
  final String? emptyLabel;

  /// Whether the well takes focus when it first appears.
  final bool autofocus;

  /// The tallest the list stands.
  final double maxHeight;

  @override
  Widget build(BuildContext context) => _palette(
    commands: commands,
    onSelected: onSelected,
    hint: hintText ?? RawWidgetsLocalizations.of(context).searchFieldLabel,
    emptyLabel:
        emptyLabel ?? RawWidgetsLocalizations.of(context).noResultsLabel,
    autofocus: autofocus,
    maxHeight: maxHeight,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('commands', commands.length));
  }
}

/// Lays a [KeycapCommandPalette] over the screen on a panel, the keyboard
/// dimmed under it; the command chosen runs once it has closed.
///
/// ```dart
/// showKeycapCommandPalette(context: context, commands: commands)
/// ```
Future<void> showKeycapCommandPalette({
  required BuildContext context,
  required List<RawCommand> commands,
  String? hintText,
  String? emptyLabel,
}) {
  final c = KeycapTheme.of(context).colors;
  final words = RawWidgetsLocalizations.of(context);
  return showDesignCommandPalette(
    context: context,
    barrierColor: c.scrim,
    palette: (run) => _palette(
      commands: commands,
      onSelected: run,
      hint: hintText ?? words.searchFieldLabel,
      emptyLabel: emptyLabel ?? words.noResultsLabel,
    ),
    surfaceBuilder: (context, palette) => ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.regular),
        child: KeycapPanel(
          child: Padding(
            padding: const EdgeInsets.all(KeycapSpacing.medium),
            child: palette,
          ),
        ),
      ),
    ),
  );
}

/// A small panel of keycap plastic laid over the keyboard by its key
/// ([builder] draws the key and gets the anchor): a few words, a short
/// form. Escape or a tap outside closes it.
///
/// ```dart
/// KeycapPopover(builder: (context, anchor) => KeycapIconButton(icon: const Icon(LucideIcons.info), semanticLabel: 'About sync', onPressed: anchor.toggle), content: (context, close) => const Text('Notes sync when you are online.'))
/// ```
class KeycapPopover extends StatelessWidget {
  /// A popover.
  const KeycapPopover({
    super.key,
    required this.builder,
    required this.content,
    this.semanticLabel,
    this.width = 300,
    this.style,
  });

  /// Draws the key that opens it.
  final Widget Function(BuildContext context, DesignOverlayAnchor anchor)
  builder;

  /// What it holds; `close` puts it away.
  final Widget Function(BuildContext context, VoidCallback close) content;

  /// Its name, for a screen reader.
  final String? semanticLabel;

  /// Its width.
  final double width;

  /// Overrides, over [KeycapThemeData.tooltipStyle]: [DesignStyle.fill] its
  /// plastic.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    semanticLabel: semanticLabel,
    placement: RawPopoverPlacement(
      gap: KeycapSpacing.small,
      margin: KeycapSpacing.small,
      matchAnchorWidth: false,
      maxWidth: width,
      preferredExtent: 240,
    ),
    dampingRatio: KeycapMotion.panel.dampingRatio,
    stiffness: KeycapMotion.panel.stiffness,
    anchorBuilder: builder,
    overlayBuilder: (context, info) => KeycapMenuReveal(
      animation: info.animation,
      below: info.side != RawPopoverSide.above,
      child: SizedBox(
        width: width,
        child: _Card(
          style: style,
          maxHeight: info.maxSize.height,
          child: content(context, info.close),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.style, this.maxHeight});

  final Widget child;
  final KeycapStyle? style;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = DesignStyleOf([style, theme.tooltipStyle], const {});
    return Padding(
      padding: const EdgeInsets.only(bottom: KeycapSpacing.small),
      child: KeycapPanel(
        radius: BorderRadius.circular(KeycapMenuPanel.radius),
        color: layered.fill,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight ?? double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KeycapSpacing.regular),
            child: DefaultTextStyle.merge(
              style: theme.textTheme.body.copyWith(color: theme.colors.ink),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A card laid over the keyboard while a pointer rests on [child] (a
/// person's name, a linked note): more about it, read not pressed. Touch
/// and keyboards reach the same through [child]'s own action.
///
/// ```dart
/// KeycapHoverCard(card: (context) => const Text('Rosa Vidal · 41 notes'), child: const Text('Rosa'))
/// ```
class KeycapHoverCard extends StatelessWidget {
  /// A hover card over [child].
  const KeycapHoverCard({
    super.key,
    required this.child,
    required this.card,
    this.width = 280,
    this.style,
  });

  /// What a pointer rests on.
  final Widget child;

  /// What the card says.
  final WidgetBuilder card;

  /// Its width.
  final double width;

  /// Overrides, over [KeycapThemeData.tooltipStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    trigger: RawPopoverTrigger.hover,
    focusOnOpen: false,
    placement: RawPopoverPlacement(
      gap: KeycapSpacing.small,
      margin: KeycapSpacing.small,
      matchAnchorWidth: false,
      maxWidth: width,
    ),
    dampingRatio: KeycapMotion.panel.dampingRatio,
    stiffness: KeycapMotion.panel.stiffness,
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => KeycapMenuReveal(
      animation: info.animation,
      below: info.side != RawPopoverSide.above,
      child: SizedBox(
        width: width,
        child: _Card(
          style: style,
          child: Builder(builder: card),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('width', width));
  }
}

/// A key's name in a few words, on a small dark tab over it while a
/// pointer rests on it, a finger holds it or the keyboard's focus is on
/// it. Built on Flutter's `RawTooltip`, with ui_core's `RawTooltipFocusFix`
/// and `RawTooltipPlacement`.
///
/// ```dart
/// KeycapTooltip(message: 'Bold', child: KeycapIconButton(icon: const Icon(LucideIcons.bold), semanticLabel: 'Bold', onPressed: bold))
/// ```
class KeycapTooltip extends StatelessWidget {
  /// A tooltip over [child].
  const KeycapTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
  });

  /// Its words.
  final String message;

  /// What it names.
  final Widget child;

  /// Overrides, over [KeycapThemeData.tooltipStyle]: [DesignStyle.fill] the
  /// tab, [DesignStyle.foreground] its words.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.tooltipStyle], const {});
    // One node, the tooltip on its control, as the published look read.
    return MergeSemantics(
      child: RawTooltipPlacement(
        placement: const RawPopoverPlacement(
          side: RawPopoverSide.above,
          align: RawPopoverAlign.center,
          gap: KeycapSpacing.tight + 2,
          matchAnchorWidth: false,
          maxWidth: 260,
          preferredExtent: 48,
        ),
        builder: (context, positionDelegate) => RawTooltip(
          semanticsTooltip: message,
          hoverDelay: const Duration(milliseconds: 500),
          positionDelegate: positionDelegate,
          tooltipBuilder: (context, animation) => FadeTransition(
            opacity: animation,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KeycapSpacing.small + 2,
                vertical: KeycapSpacing.tight + 2,
              ),
              decoration: BoxDecoration(
                color: layered.fill ?? c.toast,
                borderRadius: BorderRadius.circular(
                  KeycapMetrics.smallKeyRadius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: theme.textTheme.secondary.copyWith(
                  color: layered.foreground ?? c.onToast,
                ),
              ),
            ),
          ),
          // It shows on the keyboard's focus as well.
          child: RawTooltipFocusFix(child: child),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}
