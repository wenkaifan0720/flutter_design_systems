import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/soft_routes.dart';
import '../../internal/bare_field.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/keys.dart';
import '../../internal/menu_wake.dart';
import '../../internal/panel.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../host.dart';

export 'package:ui_core/ui_core.dart' show RawCommand;
export 'package:ui_core/ui_core.dart' show RawMenuEntry;

// ---------------------------------------------------------------------------
// Shortcuts
// ---------------------------------------------------------------------------

/// [shortcut]'s keys as Frosted's menus and palette write them, for a
/// [RawMenuEntry.shortcut] or a [RawCommand.shortcut]: ui_core's keys
/// ([rawShortcutKeys]) in the platform's order and the reader's words,
/// close together with Apple's symbols ("⇧⌘Z", each symbol drawn as the
/// look's glyph) on macOS and iOS, and joined by "+" elsewhere
/// ("Ctrl+Shift+Z"). [platform] is [defaultTargetPlatform] when null.
///
/// ```dart
/// RawMenuEntry(label: 'Redo', shortcut: frostedShortcutLabel(context, const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true)), onPressed: redo)
/// ```
String frostedShortcutLabel(
  BuildContext context,
  MenuSerializableShortcut shortcut, {
  TargetPlatform? platform,
}) {
  final on = platform ?? defaultTargetPlatform;
  final apple = on == TargetPlatform.macOS || on == TargetPlatform.iOS;
  return rawShortcutKeys(
    context,
    shortcut,
    platform: on,
  ).join(apple ? '' : '+');
}

// ---------------------------------------------------------------------------
// Menu bar
// ---------------------------------------------------------------------------

/// A desktop's menu bar (File, Edit, View; Material's MenuBar): the menus'
/// names on a strip of glass, each opening its menu on the look's panel
/// under it, a submenu beside its row. Once one menu is open the pointer
/// moving along the bar opens the next; the arrows walk the bar and the
/// menus, Return runs an item, Escape closes the menu and goes back to its
/// name. Each item may show its [RawMenuEntry.shortcut] (written by
/// [frostedShortcutLabel]) and a check.
/// ui_core's [RawMenuBar] is the behaviour.
///
/// ```dart
/// FrostedMenuBar(menus: [RawMenuEntry(label: 'File', children: [RawMenuEntry(label: 'New', shortcut: '⌘N', onPressed: create), RawMenuEntry.divider(), RawMenuEntry(label: 'Close', onPressed: close)])])
/// ```
class FrostedMenuBar extends StatelessWidget {
  /// A menu bar of [menus].
  const FrostedMenuBar({required this.menus, this.label, super.key});

  /// The bar's menus, in order.
  final List<RawMenuEntry> menus;

  /// What a screen reader calls the bar.
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Its menus tell a key's opening from a pointer's (FrostedMenuWake).
    FrostedLastInput.watch();
    final t = context.frostedTheme;
    // The bar is drawn at its 32 high items and the inset round them; each
    // item's target (the floor, 40) overhangs it, centred.
    const item = 32.0, inset = FrostedSpacing.s4;
    final target = FrostedBreakpoints.hitTargetOf(context);
    final reach = math.max(item + 2 * inset, target);
    return RawMenuBar(
      menus: menus,
      // Frosted's rows follow a moving pointer (FrostedPanelRow.followsPointer,
      // woken by FrostedMenuWake); ui_core's follow lights the row a menu
      // opens under a resting pointer, so a menu the keys open would light
      // that row rather than the first.
      highlightFollowsPointer: false,
      semanticLabel: label ?? RawWidgetsLocalizations.of(context).menuBarLabel,
      barBuilder: (context, items) => SizedBox(
        height: reach,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: (reach - item) / 2 - inset,
              bottom: (reach - item) / 2 - inset,
              child: FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(FrostedCorners.r12),
                color: t.glass.fill,
                ring: frostedLitEdge(t, t.colorScheme.border),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: inset),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: FrostedSpacing.s2,
                children: items,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == RawMenuLevel.bar) {
          final on =
              states.contains(WidgetState.selected) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed);
          final face = SizedBox(
            height: item,
            child: FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(FrostedCorners.r10),
              color: on ? t.glass.wash : null,
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedSpacing.s10,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  entry.label,
                  style: t.textTheme.labelLarge.c(
                    states.contains(WidgetState.disabled)
                        ? t.colorScheme.textTertiary
                        : t.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          );
          return SizedBox(
            height: reach,
            child: Center(
              widthFactor: 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: target),
                child: frostedRingFor(states, face, radius: FrostedCorners.r10),
              ),
            ),
          );
        }
        return _menuRow(context, entry, states);
      },
      dividerBuilder: _menuDivider,
      surfaceBuilder: _menuSurface,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RawMenuEntry>('menus', menus))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// A row of a Frosted menu (the menu bar's, a context menu's): the panel's
/// row, 240 wide with the panel's inset, its check, and its submenu's arrow
/// or its shortcut at the end.
Widget _menuRow(
  BuildContext context,
  RawMenuEntry entry,
  Set<WidgetState> states,
) {
  final t = context.frostedTheme;
  final shortcut = entry.shortcut;
  return SizedBox(
    width: 240 - 2 * FrostedChromeMetrics.menuInset,
    child: FrostedPanelRow(
      label: entry.label,
      followsPointer: true,
      isDestructiveAction: entry.isDestructiveAction,
      states: {...states, if (entry.checked ?? false) WidgetState.selected},
      checkable: entry.checked != null,
      trailing: entry.isSubmenu
          ? Icon(
              FrostedGlyphs.forward,
              size: FrostedChromeMetrics.menuItemGlyph,
              color: t.colorScheme.textTertiary,
            )
          : shortcut == null
          ? null
          : FrostedKeys(shortcut),
    ),
  );
}

/// A Frosted menu's divider: a hairline with 4 above and below.
Widget _menuDivider(BuildContext context) => Padding(
  padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s4),
  child: SizedBox(
    height: FrostedStrokes.hairline,
    child: ColoredBox(color: context.frostedTheme.colorScheme.border),
  ),
);

/// A Frosted menu's panel round its [items], scrolling them when the room
/// is short.
Widget _menuSurface(
  BuildContext context,
  RawPopoverInfo info,
  List<Widget> items,
) => FrostedPanel(
  presence: info.animation,
  // As wide as its rows: a context menu's overlay offers the window's
  // width, which a stretched column would take.
  child: IntrinsicWidth(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: info.maxSize.height),
      child: SingleChildScrollView(
        child: FrostedMenuWake(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedChromeMetrics.menuItemsGap,
            children: items,
          ),
        ),
      ),
    ),
  ),
);

// ---------------------------------------------------------------------------
// Context menu
// ---------------------------------------------------------------------------

/// A menu of [items] over [child], opened where the user asks for it
/// (Material's context menu, shadcn's Context Menu): a right click or a long
/// press opens it at the pointer, Shift+F10 or the Menu key at the focused
/// control, and a screen reader finds "Show menu" among [child]'s actions.
/// Its rows are the menu bar's on the look's panel (commands, submenus,
/// dividers, checks, shortcuts), the light following the pointer. Escape, a
/// tap outside or the system back closes it and the focus goes back; on the
/// web the browser's own menu stays shut over [child]. ui_core's
/// [RawContextMenu] is the behaviour.
///
/// ```dart
/// FrostedContextMenu(items: [RawMenuEntry(label: 'Copy', onPressed: copy), RawMenuEntry.divider(), RawMenuEntry(label: 'Delete', onPressed: delete)], child: card)
/// ```
class FrostedContextMenu extends StatelessWidget {
  /// A context menu of [items] over [child].
  const FrostedContextMenu({
    required this.items,
    required this.child,
    this.label,
    super.key,
  });

  /// The menu's rows, in order: commands, submenus and dividers. Empty: no
  /// menu.
  final List<RawMenuEntry> items;

  /// The region that opens it.
  final Widget child;

  /// What a screen reader calls the menu; null: none.
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Its menu tells a key's opening from a pointer's (FrostedMenuWake).
    FrostedLastInput.watch();
    return RawContextMenu(
      menuChildren: items,
      // Frosted's rows follow a moving pointer (FrostedPanelRow.followsPointer,
      // woken by FrostedMenuWake); ui_core's follow lights the row a menu
      // opens under a resting pointer, so a menu the keys open would light
      // that row rather than the first.
      highlightFollowsPointer: false,
      semanticLabel: label,
      itemBuilder: (context, entry, level, states) =>
          _menuRow(context, entry, states),
      dividerBuilder: _menuDivider,
      surfaceBuilder: _menuSurface,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RawMenuEntry>('items', items))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

// ---------------------------------------------------------------------------
// Command palette
// ---------------------------------------------------------------------------

/// A palette of [commands] found by typing (shadcn's Command, a desktop's
/// ⌘K): a search field over the matches, grouped under their [RawCommand.group]
/// names, the best match lit; the arrows move the light, Return runs it,
/// Escape closes. A screen reader hears how many match as the query
/// changes. Build it in place, or raise it over the app with [show] (and
/// on Ctrl+K or ⌘K with ui_core's `RawCommandShortcut`). ui_core's
/// [RawCommandPalette] is the behaviour.
///
/// ```dart
/// FrostedCommand.show(context, commands: [RawCommand(label: 'New payment', group: 'Money', shortcut: '⌘P', onPressed: pay), RawCommand(label: 'Settings', onPressed: openSettings)])
/// ```
class FrostedCommand extends StatelessWidget {
  /// A palette of [commands].
  const FrostedCommand({
    required this.commands,
    this.onSelected,
    this.hintText,
    this.width = 520,
    this.maxHeight = 360,
    this.labelText,
    super.key,
  });

  /// What it offers.
  final List<RawCommand> commands;

  /// Called with the command run (as well as its own `onPressed`).
  final ValueChanged<RawCommand>? onSelected;

  /// The field's placeholder ("Type a command or search" when null).
  final String? hintText;

  /// The palette's width.
  final double width;

  /// The tallest the matches stand before they scroll.
  final double maxHeight;

  /// What a screen reader calls the palette.
  final String? labelText;

  /// Raises a palette of [commands] over the whole app, a third of the way
  /// down, over the scrim; running a command closes it and runs it.
  static Future<void> show(
    BuildContext context, {
    required List<RawCommand> commands,
    String? hintText,
  }) {
    final t = context.frostedTheme;
    final navigator = FrostedHost.navigatorOf(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return showRawCommandPalette(
      context: navigator.context,
      // The page under the palette dims and softens, as under every raised
      // slab.
      barrierBuilder: frostedSoftBarrier(
        color: t.colorScheme.overlay,
        soften: t.materials.soften,
      ),
      barrierLabel: RawWidgetsLocalizations.of(context).closeButtonLabel,
      palette: (run) => _palette(
        context,
        commands: commands,
        onSelected: run,
        hint: hintText,
        maxHeight: 360,
        label: null,
      ),
      surfaceBuilder: (dialogContext, palette) => themes.wrap(
        FrostedPanel(width: 520, padding: EdgeInsets.zero, child: palette),
      ),
    );
  }

  static RawCommandPalette _palette(
    BuildContext context, {
    required List<RawCommand> commands,
    required ValueChanged<RawCommand>? onSelected,
    required String? hint,
    required double maxHeight,
    required String? label,
  }) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    return RawCommandPalette(
      commands: commands,
      onSelected: onSelected,
      maxHeight: maxHeight,
      semanticLabel: label ?? words.searchCommands,
      // At least the field's height, growing with larger text; the line
      // stands on its centre by the row's alignment.
      fieldBuilder: (context, field) => ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.field,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FrostedChromeMetrics.fieldInset,
          ),
          // The line answers taps from the field's top to its bottom.
          child: FrostedFieldRoom(
            child: Row(
              spacing: FrostedSpacing.s10,
              children: [
                Icon(
                  FrostedGlyphs.search,
                  size: FrostedIconSize.i18,
                  color: t.colorScheme.textTertiary,
                ),
                Expanded(
                  child: FrostedBareField(
                    controller: field.controller,
                    focusNode: field.focusNode,
                    hintText: hint ?? words.searchCommands,
                    labelText: label ?? words.searchCommands,
                    // Return runs the command and the search keeps the
                    // focus, as the combobox's.
                    onEditingComplete: field.submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      layoutBuilder: (context, field, results) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          SizedBox(
            height: FrostedStrokes.hairline,
            child: ColoredBox(color: t.colorScheme.border),
          ),
          Padding(
            padding: const EdgeInsets.all(FrostedChromeMetrics.menuInset),
            child: results,
          ),
        ],
      ),
      groupBuilder: (context, group) => Padding(
        padding: const EdgeInsets.fromLTRB(
          FrostedChromeMetrics.menuHeadSide,
          FrostedSpacing.s8,
          FrostedChromeMetrics.menuHeadSide,
          FrostedSpacing.s4,
        ),
        child: Text(group, style: t.textTheme.labelMedium.line(15.6)),
      ),
      emptyBuilder: (context) => Padding(
        padding: const EdgeInsets.all(FrostedSpacing.s24),
        child: Text(
          RawWidgetsLocalizations.of(context).noResultsLabel,
          textAlign: TextAlign.center,
          style: t.textTheme.titleMedium.c(t.colorScheme.textTertiary),
        ),
      ),
      itemBuilder: (context, command, states) {
        final shortcut = command.shortcut;
        return FrostedPanelRow(
          label: command.label,
          states: {...states, if (!command.enabled) WidgetState.disabled},
          checkable: false,
          trailing: shortcut == null ? null : FrostedKeys(shortcut),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => FrostedPanel(
    width: width,
    padding: EdgeInsets.zero,
    inPlace: true,
    child: _palette(
      context,
      commands: commands,
      onSelected: onSelected,
      hint: hintText,
      maxHeight: maxHeight,
      label: labelText,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RawCommand>('commands', commands))
      ..add(
        ObjectFlagProperty<ValueChanged<RawCommand>>.has(
          'onSelected',
          onSelected,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(DoubleProperty('width', width, defaultValue: 520))
      ..add(DoubleProperty('maxHeight', maxHeight, defaultValue: 360))
      ..add(StringProperty('labelText', labelText, defaultValue: null));
  }
}
