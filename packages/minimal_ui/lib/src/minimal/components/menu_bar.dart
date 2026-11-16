/// A desktop app's row of menus (File, Edit, View), painted on ui_core's
/// menubar.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
/// behaviour is ui_core's ([DesignMenuBar]); Minimal paints it, and its
/// menus keep [MinimalMenu]'s one place: the row with the keys alone takes
/// the muted fill, and the pointer moves the keys (over a row it is the
/// place; off the rows, none). A menu the pointer opened starts on none
/// (the first arrow lands on the first row), one a key opened on its first
/// row. A phone has no menu bar: a [MinimalMenu] under a button holds the
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

    // A top item stands a finger wide at a finger; the band round the bar
    // gives it the floor's height.
    final across = minimalTapFloor(context);
    Widget top(DesignMenuEntry entry, Set<WidgetState> states) => Container(
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

    Widget row(DesignMenuEntry entry, Set<WidgetState> states) {
      final keys = entry.shortcut;
      final glyph = entry.data;
      return _BarMenuRow(
        states: states,
        builder: (states) => MinimalKitRow(
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
        ),
      );
    }

    return _BarInputScope(
      child: MinimalTapBand(
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
            _BarMenuCard(
              child: MinimalKitPanel(
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
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<MinimalMenuEntry>('menus', menus))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      );
  }
}

/// The card of one of the bar's menus, holding the keys while no row has
/// them: a menu the pointer opened (ui_core gives its first row the keys on
/// every open; here none is lit until the pointer or a key moves), or the
/// pointer gone off the rows. From the card Down goes to the first row, Up
/// to the last; Home, End, letters, Escape and the bar's arrows go on to
/// ui_core.
class _BarMenuCard extends StatefulWidget {
  const _BarMenuCard({required this.child});

  final Widget child;

  @override
  State<_BarMenuCard> createState() => _BarMenuCardState();
}

class _BarMenuCardState extends State<_BarMenuCard> {
  final FocusNode _card = FocusNode(debugLabel: 'menu', skipTraversal: true);

  @override
  void initState() {
    super.initState();
    // Opened from a key (Down, Enter, Space on the bar; Left and Right
    // along it or into a submenu): ui_core's first row keeps the keys.
    final input = context.getInheritedWidgetOfExactType<_BarInput>();
    if (input == null || !input.pointer.value) return;
    // After ui_core's own focus on open, in the same frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _card.requestFocus();
    });
  }

  @override
  void dispose() {
    _card.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    if (!down && event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final rows = [
      for (final row
          in node.nearestScope?.traversalDescendants ?? <FocusNode>[])
        if (row.canRequestFocus && !row.skipTraversal) row,
    ];
    if (rows.isEmpty) return KeyEventResult.ignored;
    (down ? rows.first : rows.last).requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => _BarMenuPlace(
    card: _card,
    child: Focus(
      focusNode: _card,
      includeSemantics: false,
      onKeyEvent: _key,
      child: widget.child,
    ),
  );
}

/// The card a menu's rows hand the keys back to when the pointer leaves.
class _BarMenuPlace extends InheritedWidget {
  const _BarMenuPlace({required this.card, required super.child});

  final FocusNode card;

  @override
  bool updateShouldNotify(_BarMenuPlace old) => card != old.card;
}

/// A row in one of the bar's menus: the place (the one row with the keys)
/// takes the muted fill, whatever moved it there; the pointer over a row
/// makes it the place, and off it hands the keys back to the card.
class _BarMenuRow extends StatelessWidget {
  const _BarMenuRow({required this.states, required this.builder});

  /// ui_core's states for the row.
  final Set<WidgetState> states;

  /// Paints the row for its states, focused when it is the place.
  final Widget Function(Set<WidgetState> states) builder;

  @override
  Widget build(BuildContext context) {
    // The row's own node (ui_core's press), heard here as it changes.
    final node = Focus.maybeOf(context);
    final place = node?.hasPrimaryFocus ?? false;
    final off = MinimalKitStates(states).off;
    return MouseRegion(
      onEnter: (_) {
        context.getInheritedWidgetOfExactType<_BarInput>()?.pointer.value =
            true;
        if (!off && node != null && !node.hasPrimaryFocus) node.requestFocus();
      },
      onExit: (_) {
        if (node != null && node.hasPrimaryFocus) {
          context
              .getInheritedWidgetOfExactType<_BarMenuPlace>()
              ?.card
              .requestFocus();
        }
      },
      child: builder({
        for (final state in states)
          if (state != WidgetState.focused && state != WidgetState.hovered)
            state,
        if (place && !off) WidgetState.focused,
      }),
    );
  }
}

/// What last moved through the bar and its menus, the pointer or a key, so a
/// menu opening knows which opened it: a key's press and release both come
/// before the menu builds, so the keys held then cannot tell.
class _BarInputScope extends StatefulWidget {
  const _BarInputScope({required this.child});

  final Widget child;

  @override
  State<_BarInputScope> createState() => _BarInputScopeState();
}

class _BarInputScopeState extends State<_BarInputScope> {
  // A plain box, read when a menu opens: nothing repaints when it changes.
  final _Box _pointer = _Box();

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    // A key on the bar or in a menu: whatever opens next, a key opened.
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent) _pointer.value = false;
      return KeyEventResult.ignored;
    },
    child: Listener(
      onPointerDown: (_) => _pointer.value = true,
      onPointerHover: (_) => _pointer.value = true,
      child: _BarInput(pointer: _pointer, child: widget.child),
    ),
  );
}

class _Box {
  bool value = false;
}

class _BarInput extends InheritedWidget {
  const _BarInput({required this.pointer, required super.child});

  /// Whether the pointer moved last.
  final _Box pointer;

  @override
  bool updateShouldNotify(_BarInput old) => pointer != old.pointer;
}
