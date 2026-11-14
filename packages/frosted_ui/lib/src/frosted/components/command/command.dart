import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/bare_field.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/keys.dart';
import '../../internal/panel.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../host.dart';

export 'package:ui_core/ui_core.dart' show DesignCommand;
export 'package:ui_core/ui_core.dart' show DesignMenuEntry;

// ---------------------------------------------------------------------------
// Menu bar
// ---------------------------------------------------------------------------

/// A desktop's menu bar (File, Edit, View; Material's MenuBar): the menus'
/// names on a strip of glass, each opening its menu on the look's panel
/// under it, a submenu beside its row. Once one menu is open the pointer
/// moving along the bar opens the next; the arrows walk the bar and the
/// menus, Return runs an item, Escape closes the menu and goes back to its
/// name. Each item may show its [DesignMenuEntry.shortcut] and a check.
/// ui_core's [DesignMenuBar] is the behaviour.
///
/// ```dart
/// FrostedMenuBar(menus: [DesignMenuEntry(label: 'File', children: [DesignMenuEntry(label: 'New', shortcut: '⌘N', onPressed: create), DesignMenuEntry.divider(), DesignMenuEntry(label: 'Close', onPressed: close)])])
/// ```
class FrostedMenuBar extends StatelessWidget {
  /// A menu bar of [menus].
  const FrostedMenuBar({required this.menus, this.label, super.key});

  /// The bar's menus, in order.
  final List<DesignMenuEntry> menus;

  /// What a screen reader calls the bar.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // The bar is drawn at its 32 high items and the inset round them; each
    // item's target (48 under a finger) overhangs it, centred.
    const item = 32.0, inset = FrostedSpacing.s4;
    final target = FrostedBreakpoints.hitTargetOf(context);
    final reach = math.max(item + 2 * inset, target);
    return DesignMenuBar(
      menus: menus,
      semanticLabel: label ?? DesignLocalizations.of(context).menuBarLabel,
      barBuilder: (context, items) => FrostedOverhang(
        height: item + 2 * inset,
        child: SizedBox(
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
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.bar) {
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
        final shortcut = entry.shortcut;
        return SizedBox(
          width: 240 - 2 * FrostedChromeMetrics.menuInset,
          child: FrostedPanelRow(
            label: entry.label,
            states: {
              ...states,
              if (entry.checked ?? false) WidgetState.selected,
            },
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
      },
      dividerBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: FrostedSpacing.s4),
        child: SizedBox(
          height: FrostedStrokes.hairline,
          child: ColoredBox(color: t.colorScheme.border),
        ),
      ),
      surfaceBuilder: (context, info, items) => FrostedPanel(
        presence: info.animation,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: info.maxSize.height),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedChromeMetrics.menuItemsGap,
              children: items,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Command palette
// ---------------------------------------------------------------------------

/// A palette of [commands] found by typing (shadcn's Command, a desktop's
/// ⌘K): a search field over the matches, grouped under their [group]
/// names, the best match lit; the arrows move the light, Return runs it,
/// Escape closes. A screen reader hears how many match as the query
/// changes. Build it in place, or raise it over the app with [show] (and
/// on Ctrl+K or ⌘K with ui_core's `DesignCommandShortcut`). ui_core's
/// [DesignCommandPalette] is the behaviour.
///
/// ```dart
/// FrostedCommand.show(context, commands: [DesignCommand(label: 'New payment', group: 'Money', shortcut: '⌘P', onPressed: pay), DesignCommand(label: 'Settings', onPressed: openSettings)])
/// ```
class FrostedCommand extends StatelessWidget {
  /// A palette of [commands].
  const FrostedCommand({
    required this.commands,
    this.onSelected,
    this.hint,
    this.width = 520,
    this.maxHeight = 360,
    this.label,
    super.key,
  });

  /// What it offers.
  final List<DesignCommand> commands;

  /// Called with the command run (as well as its own `onPressed`).
  final ValueChanged<DesignCommand>? onSelected;

  /// The field's placeholder ("Type a command or search" when null).
  final String? hint;

  /// The palette's width.
  final double width;

  /// The tallest the matches stand before they scroll.
  final double maxHeight;

  /// What a screen reader calls the palette.
  final String? label;

  /// Raises a palette of [commands] over the whole app, a third of the way
  /// down, over the scrim; running a command closes it and runs it.
  static Future<void> show(
    BuildContext context, {
    required List<DesignCommand> commands,
    String? hint,
  }) {
    final t = context.frostedTheme;
    final navigator = FrostedHost.navigatorOf(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return showDesignCommandPalette(
      context: navigator.context,
      barrierColor: t.colorScheme.overlay,
      barrierLabel: DesignLocalizations.of(context).closeButtonLabel,
      palette: (run) => _palette(
        context,
        commands: commands,
        onSelected: run,
        hint: hint,
        maxHeight: 360,
        label: null,
      ),
      surfaceBuilder: (dialogContext, palette) => themes.wrap(
        FrostedPanel(width: 520, padding: EdgeInsets.zero, child: palette),
      ),
    );
  }

  static DesignCommandPalette _palette(
    BuildContext context, {
    required List<DesignCommand> commands,
    required ValueChanged<DesignCommand>? onSelected,
    required String? hint,
    required double maxHeight,
    required String? label,
  }) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    return DesignCommandPalette(
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
                  hint: hint ?? words.searchCommands,
                  label: label ?? words.searchCommands,
                  onSubmitted: (_) => field.submit(),
                ),
              ),
            ],
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
          DesignLocalizations.of(context).noResultsLabel,
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
    child: _palette(
      context,
      commands: commands,
      onSelected: onSelected,
      hint: hint,
      maxHeight: maxHeight,
      label: label,
    ),
  );
}
