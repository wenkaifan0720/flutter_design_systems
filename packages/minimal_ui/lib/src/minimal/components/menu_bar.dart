/// A desktop app's row of menus (File, Edit, View), painted on ui_core's
/// menubar.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/controls.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'code.dart';
import 'pressable.dart';

/// One entry of a [MinimalMenuBar]: a top menu or a submenu ([children]),
/// a command ([onPressed]), or a hairline between groups
/// ([MinimalMenuEntry.divider]).
///
/// ```dart
/// MinimalMenuEntry('File', children: [MinimalMenuEntry('New', shortcut: '⌘ N', onPressed: create)])
/// ```
@immutable
class MinimalMenuEntry {
  /// An entry [label]led.
  const MinimalMenuEntry(
    this.label, {
    this.onPressed,
    this.children,
    this.icon,
    this.shortcut,
    this.checked,
  }) : divider = false;

  /// A hairline between groups of items.
  const MinimalMenuEntry.divider()
    : label = '',
      onPressed = null,
      children = null,
      icon = null,
      shortcut = null,
      checked = null,
      divider = true;

  /// Its words.
  final String label;

  /// What the command does, once its menus closed; null disables a command,
  /// as a menu with no [children] is disabled.
  final VoidCallback? onPressed;

  /// The menu or submenu it opens; null: a command.
  final List<MinimalMenuEntry>? children;

  /// A 16 px glyph before the words.
  final IconData? icon;

  /// The key that runs it, printed as key caps at the end (`⌘ S`): a hint,
  /// not a binding.
  final String? shortcut;

  /// The check of an item that toggles; null: none.
  final bool? checked;

  /// Whether it is a hairline.
  final bool divider;

  DesignMenuEntry _design() => divider
      ? const DesignMenuEntry.divider()
      : DesignMenuEntry(
          label: label,
          onPressed: onPressed,
          children: children == null
              ? null
              : [for (final c in children!) c._design()],
          shortcut: shortcut,
          checked: checked,
          data: icon,
        );
}

/// A row of menus across a desktop app's top: File, Edit, View. A quiet
/// strip on a hairline (its outline `shapes.small`), its menus' names in
/// the control weight; an open menu's name stands on the quiet fill, and
/// its menu is Minimal's card of 32 px items (a glyph, the words, the key
/// caps or a chevron to a submenu, a check), the active item in the
/// selection fill.
///
/// The bar is one tab stop: Left and Right move along it, Down, Enter and
/// Space open a menu; in a menu Up and Down move, Right opens a submenu or
/// moves to the next menu, Escape closes it with focus back on the bar;
/// while a menu is open a pointer over another name opens that one. The
/// behaviour is ui_core's ([DesignMenuBar]); Minimal paints it. A phone has
/// no menu bar: a [MinimalMenu] under a button holds the same commands.
///
/// [style] dresses the strip (fill, edge or side, shape); the menus read
/// `components.menu`.
///
/// ```dart
/// MinimalMenuBar(menus: [MinimalMenuEntry('File', children: [MinimalMenuEntry('New', onPressed: create), MinimalMenuEntry('Open…', onPressed: open)])])
/// ```
class MinimalMenuBar extends StatelessWidget {
  /// A bar of [menus], each with its children.
  const MinimalMenuBar({
    super.key,
    required this.menus,
    this.label,
    this.style,
  });

  /// The top menus.
  final List<MinimalMenuEntry> menus;

  /// What a screen reader calls the bar.
  final String? label;

  /// The strip's style.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final strip = MinimalStyleOf([style], const {});
    final outline = strip.shape ?? t.shapes.small;
    const pad = MinimalControlMetrics.segmentInset;
    final item = MinimalShapes.inset(outline, pad);

    Widget top(DesignMenuEntry entry, Set<WidgetState> states) => Container(
      height: t.density.height(MinimalChromeMetrics.controlSm),
      padding: const EdgeInsets.symmetric(
        horizontal: MinimalControlMetrics.segmentPad,
      ),
      alignment: Alignment.center,
      decoration: minimalFrame(item, fill: states.chosen ? t.muted : null),
      foregroundDecoration: minimalStateLayer(t, item, states, inside: true),
      child: Text(
        entry.label,
        style: t.bodySmall.medium.c(states.off ? t.textTertiary : t.foreground),
        maxLines: 1,
      ),
    );

    Widget row(DesignMenuEntry entry, Set<WidgetState> states) {
      final keys = entry.shortcut;
      final glyph = entry.data;
      return MinimalKitRow(
        states: states,
        label: entry.label,
        icon: glyph is IconData ? glyph : null,
        checked: entry.checked ?? false,
        trailing: entry.isSubmenu
            ? MinimalIcon(
                Directionality.of(context) == TextDirection.rtl
                    ? LucideIcons.chevronLeft
                    : LucideIcons.chevronRight,
                size: MinimalIconSize.i16,
                color: t.textTertiary,
              )
            : keys == null
            ? null
            : MinimalKbd.chord(keys),
      );
    }

    return MinimalHitTarget(
      child: DesignMenuBar(
        menus: [for (final m in menus) m._design()],
        semanticLabel: label ?? MinimalLocalizations.of(context).menuBar,
        itemBuilder: (context, entry, level, states) =>
            level == DesignMenuLevel.bar
            ? top(entry, states)
            : row(entry, states),
        dividerBuilder: (context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s4),
          child: Container(height: t.hairline, color: t.border),
        ),
        barBuilder: (context, items) => Container(
          padding: const EdgeInsets.all(pad),
          decoration: minimalFrame(
            outline,
            fill: strip.fill ?? t.card,
            side: strip.rim(t.border, t.rim),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: items),
        ),
        surfaceBuilder: (context, info, items) => minimalKitPresence(
          context,
          info,
          MinimalKitPanel(
            padding: const EdgeInsets.all(MinimalSpacing.s4),
            width: 224,
            maxHeight: info.maxSize.height,
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
  }
}
