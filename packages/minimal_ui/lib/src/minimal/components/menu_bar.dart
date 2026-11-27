/// A desktop app's row of menus (File, Edit, View), painted on ui_core's
/// menubar.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/controls.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'code.dart';

/// One entry of a [MinimalMenuBar]: a top menu or a submenu ([children]),
/// a command ([onPressed]), or a hairline between groups
/// ([MinimalMenuEntry.divider]).
///
/// ```dart
/// MinimalMenuEntry('File', children: [MinimalMenuEntry('New', shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true), onPressed: create)])
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
    this.isDestructiveAction = false,
  }) : divider = false;

  /// A hairline between groups of items.
  const MinimalMenuEntry.divider()
    : label = '',
      onPressed = null,
      children = null,
      icon = null,
      shortcut = null,
      checked = null,
      isDestructiveAction = false,
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

  /// The keys that run it, printed as key caps at the end in the
  /// platform's order and the reader's words (`⌘ S` on a Mac, `Ctrl S`
  /// elsewhere; ui_core's [rawShortcutKeys]): a hint, not a binding.
  final MenuSerializableShortcut? shortcut;

  /// The check of an item that toggles; null: none.
  final bool? checked;

  /// Whether the command destroys something (Delete, Remove): its words and
  /// glyph stand in the destructive ink.
  final bool isDestructiveAction;

  /// Whether it is a hairline.
  final bool divider;

  RawMenuEntry _design(BuildContext context) => divider
      ? const RawMenuEntry.divider()
      : RawMenuEntry(
          label: label,
          onPressed: onPressed,
          children: children == null
              ? null
              : [for (final c in children!) c._design(context)],
          // What a screen reader adds: the keys in words.
          shortcut: switch (shortcut) {
            final keys? => rawShortcutLabel(context, keys, appleSymbols: false),
            null => null,
          },
          checked: checked,
          isDestructiveAction: isDestructiveAction,
          data: this,
        );
}

/// A row of menus across a desktop app's top: File, Edit, View. A quiet
/// strip on a hairline (its outline `shapes.small`), its menus' names in
/// the control weight; an open menu's name stands on the quiet fill, and
/// its menu is Minimal's card of 32 px items, at the tap floor on touch (a
/// glyph, the words, the key caps or a chevron to a submenu, a check), the
/// active item in the muted fill.
///
/// The bar is one tab stop: Left and Right move along it, Down, Enter and
/// Space open a menu; in a menu Up and Down move, Right opens a submenu or
/// moves to the next menu, Escape closes it with focus back on the bar;
/// while a menu is open a pointer over another name opens that one. One
/// row is lit, the one with the keys, which the pointer moves too (over a
/// row it is the place; off the rows, none), on the muted fill; the keys'
/// row also wears the accent focus ring, inside its edge. A menu the
/// pointer opened starts on none (Down lands on the first row, Up on the
/// last), one a key opened on its first row. The behaviour is ui_core's
/// ([RawMenuBar], its highlight following the pointer); Minimal paints
/// it. A phone has no menu bar: a [MinimalMenu] under a button holds the
/// same commands.
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
    this.semanticLabel,
    this.style,
  });

  /// The top menus.
  final List<MinimalMenuEntry> menus;

  /// What a screen reader calls the bar.
  final String? semanticLabel;

  /// The strip's style.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final strip = MinimalStyleOf([style], const {});
    final outline = strip.shape ?? t.shapes.small;
    const pad = MinimalControlMetrics.segmentInset;
    final item = MinimalShapes.inset(outline, pad);

    // A top item stands a finger wide at a finger; the band round the bar
    // gives it the floor's height.
    final across = minimalTapFloor(context);
    Widget top(RawMenuEntry entry, Set<WidgetState> states) => Container(
      height: t.density.height(MinimalChromeMetrics.controlSm),
      constraints: BoxConstraints(minWidth: across),
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

    // ui_core lights one row, the current one (hovered when the pointer
    // moved last, focused when a key did): the muted fill, and the keys'
    // row the accent ring inside its edge.
    Widget row(RawMenuEntry entry, Set<WidgetState> states) {
      final source = entry.data;
      final keys = source is MinimalMenuEntry ? source.shortcut : null;
      // A finger tall on touch, as every Minimal menu's rows are; 32 under
      // a pointer.
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: math.max(32, across)),
        child: MinimalKitRow(
          states: states,
          label: entry.label,
          icon: source is MinimalMenuEntry ? source.icon : null,
          checked: entry.checked ?? false,
          destructive: entry.isDestructiveAction,
          ring: true,
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
              : MinimalKbd.shortcut(keys),
        ),
      );
    }

    return MinimalTapBand(
      child: RawMenuBar(
        menus: [for (final m in menus) m._design(context)],
        semanticLabel:
            semanticLabel ?? MinimalLocalizations.of(context).menuBar,
        itemBuilder: (context, entry, level, states) =>
            level == RawMenuLevel.bar ? top(entry, states) : row(entry, states),
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
          // Past the window's width (large text on a phone) the menus
          // scroll along the bar rather than run off it.
          child: ClipRect(
            clipper: const MinimalRingRoom(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
          ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalMenuEntry>('menus', menus))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      );
  }
}
