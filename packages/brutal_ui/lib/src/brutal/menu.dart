/// Brutal's menus: [BrutalMenu], a list of [BrutalMenuItem]s that drops
/// from whatever opens it, drawn on [BrutalMenuPanel] (a raised ruled box)
/// in [BrutalMenuRow]s (ink when chosen or pressed, a solid bar inside the
/// row where the pointer or the keyboard is). The split button, the menu
/// bar, the palette, the combobox and the tag input draw their lists with
/// them. In a menu the pointer and the keyboard are one: the pointer's move
/// takes the keyboard to its row, so one row is lit; a menu a pointer opened
/// lights none until the pointer moves onto one or a key is pressed (ui_core
/// keeps the keys on the menu's surface until then).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/keep_in_view.dart';
import 'internal/type_ahead.dart';
import 'internal/focus_ink.dart';
import 'surface.dart';
import 'theme.dart';

/// One command in a [BrutalMenu].
///
/// ```dart
/// BrutalMenuItem(label: 'Share', icon: LucideIcons.share2, onPressed: share)
/// ```
@immutable
class BrutalMenuItem {
  /// A command reading [label]; a null [onPressed] shows it disabled.
  const BrutalMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.shortcut,
    this.activator,
    this.isDestructiveAction = false,
  });

  /// The words.
  final String label;

  /// What choosing it does; null disables it.
  final VoidCallback? onPressed;

  /// A glyph before the words.
  final IconData? icon;

  /// The keys that run it, shown at the row's end as written (`⌘S`); see
  /// [activator].
  final String? shortcut;

  /// The shortcut that runs it, shown at the row's end in the platform's
  /// order and the reader's words when there is no [shortcut] (ui_core's
  /// [designShortcutLabel]: `⌘S` on a Mac, `Ctrl+S` elsewhere). It only
  /// shows the keys: binding them is the app's.
  final MenuSerializableShortcut? activator;

  /// What its row shows at its end: [shortcut], else [activator]'s keys.
  String? shortcutLabel(BuildContext context) {
    final keys = activator;
    return shortcut ??
        (keys == null ? null : designShortcutLabel(context, keys));
  }

  /// Whether it destroys something: its words in the danger colour.
  final bool isDestructiveAction;
}

/// A menu's raised box: the surface in the look's rule over its hard shadow,
/// its rows apart on rules, scrolling inside once it is taller than
/// [maxHeight].
///
/// Its [BrutalMenuRow]s light one row, the keyboard's: a pointer moving onto
/// a row takes the keyboard there. Opened by a pointer's press, it lights no
/// row until the pointer moves onto one or a key is pressed: ui_core's
/// surface holds the keys until then, Down going to the first row and Up to
/// the last.
///
/// Reads [style]'s `fill` and `edge` (the box and the rules between rows),
/// then [BrutalThemeData.menuStyle]'s.
///
/// ```dart
/// BrutalMenuPanel(children: [for (final item in items) row(item)])
/// ```
class BrutalMenuPanel extends StatelessWidget {
  /// A panel round [children].
  const BrutalMenuPanel({
    super.key,
    required this.children,
    this.maxHeight = 360,
    this.minWidth = 200,
    this.style,
  });

  /// The rows, top to bottom; a rule stands between each two.
  final List<Widget> children;

  /// The tallest it stands before it scrolls.
  final double maxHeight;

  /// The narrowest it stands.
  final double minWidth;

  /// Its style, over [BrutalThemeData.menuStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.menuStyle], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    return _OnPanel(
      child: BrutalSurface(
        face: BrutalFace(
          fill: layered.fill ?? c.surface,
          border: rule,
          foreground: c.ink,
          shadow: c.ink,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth - 2 * theme.borderWidth,
            maxHeight: maxHeight,
          ),
          child: SingleChildScrollView(
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, row) in children.indexed) ...[
                    if (i > 0)
                      SizedBox(
                        height: theme.borderWidth,
                        child: ColoredBox(color: rule),
                      ),
                    row,
                  ],
                ],
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
      ..add(DoubleProperty('maxHeight', maxHeight))
      ..add(DoubleProperty('minWidth', minWidth))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

// Marks a menu's panel: its rows light the keyboard's row only, as the
// pointer's move takes the keyboard there.
class _OnPanel extends InheritedWidget {
  const _OnPanel({required super.child});

  static bool on(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_OnPanel>() != null;

  @override
  bool updateShouldNotify(_OnPanel oldWidget) => false;
}

/// A menu row with a label, an optional [icon] and a [trailing] widget.
///
/// A selected or pressed row fills with ink. A destructive row uses the
/// danger colour and a disabled row uses muted ink. A narrow accent bar
/// marks the focused row. Moving the pointer inside a [BrutalMenuPanel]
/// transfers keyboard focus to that row.
///
/// Reads [style]'s `fill` and `foreground` in its states, `padding`,
/// `minimumSize` (its height), `textStyle` and `iconSize`, then
/// [BrutalThemeData.menuStyle]'s.
class BrutalMenuRow extends StatelessWidget {
  /// A row reading [label].
  const BrutalMenuRow({
    super.key,
    required this.label,
    required this.states,
    this.icon,
    this.trailing,
    this.isDestructiveAction = false,
    this.checked = false,
    this.style,
  });

  /// The words.
  final String label;

  /// Its states, from the pressable under it.
  final Set<WidgetState> states;

  /// A glyph before the words.
  final IconData? icon;

  /// What stands at the row's end: a shortcut, a chevron.
  final Widget? trailing;

  /// Whether it destroys something.
  final bool isDestructiveAction;

  /// Whether it is on: a square mark at its start. A list's chosen row is
  /// also [WidgetState.selected] in [states], which inks it.
  final bool checked;

  /// Its style, over [BrutalThemeData.menuStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.menuStyle], states);
    final disabled = states.contains(WidgetState.disabled);
    // Ink is the chosen row, or the one pressed on the way to choosing it;
    // where the pointer or the keyboard is, a bar along its lower edge.
    final lit =
        !disabled &&
        (states.contains(WidgetState.selected) ||
            states.contains(WidgetState.pressed));
    // On a menu's panel the pointer moves the keyboard: one row is lit, the
    // keyboard's, whether or not the platform shows focus after a touch.
    final onPanel = _OnPanel.on(context);
    final here =
        !disabled &&
        (states.contains(WidgetState.focused) ||
            (onPanel
                ? Focus.maybeOf(context)?.hasPrimaryFocus ?? false
                : states.contains(WidgetState.hovered)));
    final bar = isDestructiveAction ? c.danger : c.ink;
    final words =
        layered.foreground ??
        (disabled
            ? c.disabled
            : layered.fill != null
            ? c.onColor(layered.fill!)
            : lit
            ? (isDestructiveAction ? c.onDanger : c.paper)
            : (isDestructiveAction ? c.danger : c.ink));
    final row = SizedBox(
      height:
          layered.minimumSize?.height ??
          theme.controlHeight - theme.borderWidth,
      child: CustomPaint(
        foregroundPainter: here
            ? BrutalInsetFocusPainter(
                brutalFocusInk(c, layered.fill ?? (lit ? bar : c.surface)),
              )
            : null,
        child: AnimatedBrutalSurface(
          stiffness: BrutalMotion.colorStiffness,
          face: BrutalFace(
            fill: layered.fill ?? (lit ? bar : bar.withValues(alpha: 0)),
            border: bar.withValues(alpha: 0),
            foreground: words,
            borderWidth: 0,
          ),
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.symmetric(horizontal: BrutalSpacing.medium),
            child: Row(
              children: [
                if (checked) ...[
                  SizedBox.square(
                    dimension: 12,
                    child: ColoredBox(color: words),
                  ),
                  const SizedBox(width: BrutalSpacing.medium),
                ],
                if (icon != null) ...[
                  Icon(icon, size: layered.iconSize ?? 20, color: words),
                  const SizedBox(width: BrutalSpacing.medium),
                ],
                Expanded(
                  child: DesignCapCenter(
                    capHeightFactor: BrutalTheme.of(context).capHeightFactor,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: layered.text(
                        theme.textTheme.body.copyWith(color: words),
                      ),
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: BrutalSpacing.large),
                  DefaultTextStyle(
                    style: theme.textTheme.secondary.copyWith(
                      color: lit ? words : c.inkMuted,
                    ),
                    child: IconTheme.merge(
                      data: IconThemeData(size: 16, color: words),
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!onPanel || disabled) return row;
    // A move, not a row scrolled under a resting pointer, takes the keyboard.
    return MouseRegion(
      onHover: (_) {
        final node = Focus.maybeOf(context, createDependency: false);
        if (node != null && node.canRequestFocus && !node.hasPrimaryFocus) {
          node.requestFocus();
        }
      },
      child: row,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'isDestructiveAction',
        ),
      )
      ..add(FlagProperty('checked', value: checked, ifTrue: 'checked'))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A menu of [items] that drops from what [builder] draws. [builder] gets
/// a callback that opens and closes it and whether it is open; give that
/// callback to the trigger's `onPressed`.
///
/// Enter, Space or Down on the trigger opens it with the keyboard on the
/// first item. Up and Down move through the items, round from the end to the
/// start; Home and End go to the ends; a typed letter goes to the next item
/// starting with it; Enter runs one and closes it; Escape closes it and the
/// focus goes back to the trigger.
///
/// Its [style] reaches its panel and rows ([BrutalMenuPanel],
/// [BrutalMenuRow]), over [BrutalThemeData.menuStyle].
///
/// ```dart
/// BrutalMenu(items: [BrutalMenuItem(label: 'Share', onPressed: share), BrutalMenuItem(label: 'Delete', onPressed: delete, isDestructiveAction: true)], builder: (context, toggle, open) => BrutalIconButton(onPressed: toggle, tooltip: 'More', icon: const Icon(LucideIcons.ellipsis)))
/// ```
class BrutalMenu extends StatelessWidget {
  /// A menu of [items] opened from [builder]'s trigger.
  const BrutalMenu({
    super.key,
    required this.items,
    required this.builder,
    this.semanticLabel,
    this.alignEnd = false,
    this.style,
  });

  /// The commands, top to bottom.
  final List<BrutalMenuItem> items;

  /// Draws the trigger, given the callback that opens the menu and whether
  /// it is open.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)
  builder;

  /// What a screen reader calls the menu.
  final String? semanticLabel;

  /// Whether the menu's end edge lines up with the trigger's (a trigger at a
  /// bar's end); its start edge otherwise.
  final bool alignEnd;

  /// Its style, over [BrutalThemeData.menuStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) => _overlay(context);

  Widget _overlay(BuildContext context) => RawPopover(
    arrowKeyNavigation: true,
    semanticLabel: semanticLabel,
    placement: RawPopoverPlacement(
      align: alignEnd ? RawPopoverAlign.end : RawPopoverAlign.start,
      gap: BrutalSpacing.small,
      margin: BrutalSpacing.small,
      matchAnchorWidth: false,
    ),
    dampingRatio: BrutalMotion.dampingRatio,
    stiffness: BrutalMotion.overlayStiffness,
    // Down on the trigger opens it too, as on every platform's menu button.
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
      child: _MenuList(items: items, info: info, style: style),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}

// A menu's open list: its rows, with a typed letter going to the next row
// starting with it.
class _MenuList extends StatefulWidget {
  const _MenuList({required this.items, required this.info, this.style});

  final List<BrutalMenuItem> items;
  final RawPopoverInfo info;
  final BrutalStyle? style;

  @override
  State<_MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<_MenuList> {
  late final List<FocusNode> _nodes = [
    for (final item in widget.items) FocusNode(debugLabel: item.label),
  ];

  @override
  void initState() {
    super.initState();
    brutalKeepInView(_nodes);
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final info = widget.info;
    return BrutalTypeAhead(
      labels: [for (final item in items) item.label],
      nodes: [
        for (final (i, item) in items.indexed)
          item.onPressed == null ? null : _nodes[i],
      ],
      child: BrutalMenuPanel(
        maxHeight: info.maxSize.height - BrutalTheme.of(context).shadowOffset,
        style: widget.style,
        children: [
          for (final (i, item) in items.indexed)
            RawButton(
              onPressed: item.onPressed == null
                  ? null
                  : () {
                      info.close();
                      item.onPressed!();
                    },
              focusNode: _nodes[i],
              semanticLabel: item.label,
              excludeSemantics: true,
              builder: (context, states, _) => BrutalMenuRow(
                label: item.label,
                icon: item.icon,
                states: states,
                isDestructiveAction: item.isDestructiveAction,
                trailing: switch (item.shortcutLabel(context)) {
                  final keys? => Text(keys),
                  null => null,
                },
                style: widget.style,
              ),
            ),
        ],
      ),
    );
  }
}
