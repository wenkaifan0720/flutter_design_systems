import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/menu_row.dart';
import '../../internal/tip_hold.dart';
import '../../theme.dart';

/// One choice of a [CivicMenu]: its [label] in words, a glyph before it
/// ([icon]), quieter words at its end ([trailing]: a shortcut, a count),
/// the error colour when it destroys something ([isDestructiveAction]),
/// and the [value] the menu answers with. [startsGroup] lays a hairline
/// over it.
///
/// ```dart
/// CivicMenuItem(value: 'print', label: 'Print this page', icon: LucideIcons.printer)
/// ```
@immutable
class CivicMenuItem<T> {
  /// A choice answering [value], worded [label].
  const CivicMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.trailing,
    this.isDestructiveAction = false,
    this.enabled = true,
    this.startsGroup = false,
  });

  /// What [CivicMenu.onSelected] is told when it is chosen.
  final T value;

  /// What it does, in words.
  final String label;

  /// A glyph before [label]; the words always say it.
  final IconData? icon;

  /// Quieter words at its end: a shortcut ("Ctrl P"), a count.
  final String? trailing;

  /// Whether it destroys something (Delete, Withdraw): its words in the
  /// error colour.
  final bool isDestructiveAction;

  /// Whether it can be chosen.
  final bool enabled;

  /// Whether a hairline stands over it, starting a group.
  final bool startsGroup;
}

/// A menu of worded [items] that opens from the control [builder] paints
/// (a [CivicButton.secondary] saying what the menu holds: "Actions",
/// "Download"), on the page's face (by night the raised band) floating on a
/// hairline and the soft shadow, as an open list does: ui_core's [RawPopover] as a
/// menu, Civic's painting.
///
/// A press on the control, Enter or Space opens it. A pointer greys the
/// row it is over; the keys move the yellow plate over the ink bar with Up
/// and Down (Home and End to the ends), so the pointer's row and the keys'
/// never read as one. A choice closes the menu, puts the focus back on the
/// control, then calls [onSelected]. Escape, a press outside it and
/// Android's back close it.
///
/// A menu holds a page's lesser actions; each is also reachable in plain
/// sight elsewhere in the service (a menu is never the only way to do a
/// thing), and the page's one action is a [CivicButton] of its own.
///
/// Reads [CivicStyle]'s fill, edge and corners (or shape) of the panel,
/// foreground, padding and textStyle (the rows), by state: its `style:`, then
/// [CivicThemeData.menuStyle].
///
/// ```dart
/// CivicMenu<String>(
///   semanticLabel: 'Application actions',
///   items: const [
///     CivicMenuItem(value: 'print', label: 'Print this page'),
///     CivicMenuItem(value: 'withdraw', label: 'Withdraw application', isDestructiveAction: true, startsGroup: true),
///   ],
///   onSelected: (action) {},
///   builder: (context, anchor) => CivicButton.secondary(
///     onPressed: anchor.toggle,
///     child: const Text('Actions'),
///   ),
/// )
/// ```
class CivicMenu<T> extends StatelessWidget {
  /// A menu of [items] opened from [builder]'s control.
  const CivicMenu({
    super.key,
    required this.items,
    required this.onSelected,
    required this.builder,
    this.semanticLabel,
    this.controller,
    this.onOpenChanged,
    this.align = RawPopoverAlign.start,
    this.style,
  });

  /// The choices, in order.
  final List<CivicMenuItem<T>> items;

  /// Told the value of the item chosen, once the menu has closed.
  final ValueChanged<T> onSelected;

  /// Paints the control that opens it: call the anchor's `toggle` on its
  /// press.
  final Widget Function(BuildContext context, RawOverlayAnchor anchor) builder;

  /// What a screen reader calls the menu.
  final String? semanticLabel;

  /// Opens and closes it from outside; null: its own.
  final MenuController? controller;

  /// Told when it opens (true) and closes (false).
  final ValueChanged<bool>? onOpenChanged;

  /// Which edge of the control it lines up with: its start by default, its
  /// end for a control at the end of a row.
  final RawPopoverAlign align;

  /// Overrides for this menu's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    controller: controller,
    arrowKeyNavigation: true,
    semanticLabel: semanticLabel,
    onOpenChanged: onOpenChanged,
    dampingRatio: CivicMotion.state.dampingRatio,
    stiffness: CivicMotion.state.stiffness,
    placement: RawPopoverPlacement(
      gap: CivicSpacing.s8,
      align: align,
      preferredExtent: 240,
      matchAnchorWidth: false,
    ),
    // While the menu is open the control's tip stands down: it would stand
    // over the menu's rows.
    anchorBuilder: (context, anchor) =>
        CivicTipHold(held: anchor.isOpen, child: builder(context, anchor)),
    overlayBuilder: (context, info) => civicRise(
      animation: info.animation,
      fromAbove: info.side == RawPopoverSide.below,
      child: CivicMenuPanel(
        style: style,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: info.maxSize.height),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (item.startsGroup && i > 0) const CivicMenuDivider(),
                  RawButton(
                    onPressed: item.enabled
                        ? () {
                            info.close();
                            onSelected(item.value);
                          }
                        : null,
                    semanticLabel: item.label,
                    excludeSemantics: true,
                    mouseCursor: item.enabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    builder: (context, states, _) => CivicMenuRow(
                      label: item.label,
                      states: states,
                      icon: item.icon,
                      glyphColumn: items.any((i) => i.icon != null),
                      trailing: item.trailing,
                      destructive: item.isDestructiveAction,
                      style: style,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<CivicMenuItem<T>>('items', items))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        EnumProperty<RawPopoverAlign>(
          'align',
          align,
          defaultValue: RawPopoverAlign.start,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The hairline between two groups of a menu's rows.
class CivicMenuDivider extends StatelessWidget {
  /// A divider.
  const CivicMenuDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s4),
    child: SizedBox(
      height: 1,
      child: ColoredBox(color: context.civicTheme.rule),
    ),
  );
}
