/// Menus: Material 3 Expressive's vertical menus, standard and vibrant,
/// with groups, labels, dividers, submenus, checkable and selectable items,
/// and the menu surface as a popover (CONTRACT §4.1 `menu`, `popover`).
/// Owner: w3-menus, with `test/menus_test.dart` and the gallery's menus
/// demo.
///
/// A port of Compose material3 1.5.0-alpha29's expressive menus
/// (`Menu.kt`, `MenuDefaults.kt`; wave decision F1):
///
/// - The menu is `DropdownMenuPopup`'s content: a column of
///   `DropdownMenuGroup`s as wide as the widest item (112–280dp), 2dp apart
///   (`MenuDefaults.GroupSpacing`). A group is a surface at elevation 2 —
///   `surfaceContainerLow` (standard) or `tertiaryContainer` (vibrant) —
///   whose corners depend on its place (large outside, small between
///   groups) and fall back to small when the mouse leaves it
///   (`inactiveShape`, on the fast spatial spring).
/// - An item is `DropdownMenuItemContent`: a 44dp surface 4dp in from the
///   group's sides (in the 48dp touch target), 12dp padding, a 20dp leading
///   icon 8dp from a `labelLarge` label, trailing content at the end. Its
///   corners depend on its place in the group (medium outside, extra-small
///   between items) and morph to medium when selected; its container
///   springs to `tertiaryContainer` (`tertiary` when vibrant) on the fast
///   effects spring. A checkable item (`CheckableDropdownMenuItem`) grows
///   its check in on the fast spatial spring.
/// - The menu opens below its anchor (`MenuAnchorPosition.Below`), placed by
///   Compose's candidate positions inside 8dp and 48dp window margins, and
///   scales from 0.8 around the point nearest its anchor
///   (`calculateTransformOrigin`) on the fast spatial spring as it fades on
///   the fast effects spring.
///
/// Menus mount on the root navigator and wear the themes of the context
/// that opened them ([InheritedTheme.capture]): a menu keeps the app's
/// theme when the app is not the root.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
// Material's words where ui_core has none: a popup menu's name, which an app
// without Material's localizations goes without.
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/cap_label.dart';
import '../internal/choice_width.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/divider_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/list_tokens.g.dart';
import '../internal/tokens/menu_tokens.g.dart';
import '../internal/tokens/segmented_menu_tokens.g.dart';
import '../internal/tokens/standard_menu_tokens.g.dart';
import '../internal/tokens/vibrant_menu_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../internal/styled_content.dart';
import '../internal/state_face.dart';
import '../theme.dart';
import 'hero.dart';
import 'overlays.dart';
import '../internal/style_layers.dart';
import 'chips.dart' show ExpressiveChip;
import 'progress.dart' show ExpressiveCircularProgressIndicator;
import 'select.dart' show ExpressiveSelectOption;

// ---------------------------------------------------------------------------
// Entries.

/// One line of a menu group: an [ExpressiveMenuItem], an
/// [ExpressiveMenuCheckItem], an [ExpressiveMenuRadioItem], an
/// [ExpressiveMenuSubmenu], an [ExpressiveMenuDivider] or an
/// [ExpressiveMenuNote].
sealed class ExpressiveMenuEntry {
  const ExpressiveMenuEntry({this.style});

  /// Stateful visual overrides for this menu row.
  final ExpressiveComponentThemeData? style;
}

/// An action (Compose's `DropdownMenuItem` with a shape): a tap closes the
/// menu, then runs [onPressed]. Disabled when [onPressed] is null.
class ExpressiveMenuItem extends ExpressiveMenuEntry {
  /// An action labelled [label] that runs [onPressed].
  const ExpressiveMenuItem(
    this.label, {
    super.style,
    this.onPressed,
    this.icon,
    this.supportingText,
    this.trailingText,
    this.trailingIcon,
  });

  /// The label.
  final String label;

  /// What a tap does, after the menu closes.
  final VoidCallback? onPressed;

  /// A leading glyph.
  final IconData? icon;

  /// A second line under the label.
  final String? supportingText;

  /// Trailing text: a keyboard shortcut (`MenuDefaults
  /// .DropdownMenuItemTrailingLabel`).
  final String? trailingText;

  /// A trailing glyph (ignored when [trailingText] is set).
  final IconData? trailingIcon;

  /// Whether it takes input: false when onPressed is null, as in Flutter.
  bool get enabled => onPressed != null;
}

/// An on/off setting (Compose's `CheckableDropdownMenuItem`): a tap flips
/// [checked] through [onChanged]. Checked, it wears the selected container
/// and shape and shows [checkedIcon] (the check, grown in on a spring when
/// there is no [icon]; a given [icon] fills instead). The menu stays open
/// unless [closesMenu].
class ExpressiveMenuCheckItem extends ExpressiveMenuEntry {
  /// A setting labelled [label], on when [value].
  const ExpressiveMenuCheckItem(
    this.label, {
    super.style,
    required this.value,
    required this.onChanged,
    this.icon,
    this.checkedIcon,
    this.supportingText,
    this.trailingText,
    this.closesMenu = false,
  });

  /// The item's label.
  final String label;

  /// Whether the setting is on.
  final bool value;

  /// Told the new value on a tap; disabled when null.
  final ValueChanged<bool>? onChanged;

  /// The leading glyph when unchecked (and, filled, when checked unless
  /// [checkedIcon] is set).
  final IconData? icon;

  /// The leading glyph when checked; the check when neither it nor [icon]
  /// is set.
  final IconData? checkedIcon;

  /// A second line under the label.
  final String? supportingText;

  /// Text at the end of the item, such as a shortcut.
  final String? trailingText;

  /// Whether a tap closes the menu.
  final bool closesMenu;

  /// Whether it takes input: false when onChanged is null, as in Flutter.
  bool get enabled => onChanged != null;
}

/// One of a set of choices (Compose's `SelectableDropdownMenuItem`,
/// announced as a radio button): a tap selects it through [onSelected] and
/// closes the menu unless [closesMenu] is false.
class ExpressiveMenuRadioItem extends ExpressiveMenuEntry {
  /// A choice labelled [label], chosen when [selected].
  const ExpressiveMenuRadioItem(
    this.label, {
    super.style,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.selectedIcon,
    this.supportingText,
    this.trailingText,
    this.closesMenu = true,
    this.check = true,
  });

  /// The item's label.
  final String label;

  /// Whether this is the chosen one.
  final bool selected;

  /// Whether a chosen item with neither [icon] nor [selectedIcon] shows the
  /// check. A select's list marks its choice by the row's fill alone, as
  /// Material's exposed dropdown does, so every option's words keep one
  /// edge, the field's.
  final bool check;

  /// Told when the item is tapped; disabled when null.
  final VoidCallback? onSelected;

  /// The leading glyph (filled when selected unless [selectedIcon] is set).
  final IconData? icon;

  /// The leading glyph when selected; the check when neither it nor [icon]
  /// is set.
  final IconData? selectedIcon;

  /// A second line under the label.
  final String? supportingText;

  /// Text at the end of the item, such as a shortcut.
  final String? trailingText;

  /// Whether a tap closes the menu.
  final bool closesMenu;

  /// Whether it takes input: false when onSelected is null, as in Flutter.
  bool get enabled => onSelected != null;
}

/// An item that opens a cascading menu of [groups] beside it (Compose's
/// `MenuWithCascadingMenusSample`: a second popup at
/// `MenuAnchorPosition.End`). A choice in it closes both menus.
class ExpressiveMenuSubmenu extends ExpressiveMenuEntry {
  /// An item labelled [label] that opens a cascading menu of [groups].
  const ExpressiveMenuSubmenu(
    this.label, {
    super.style,
    required this.groups,
    this.icon,
    this.supportingText,
  });

  /// The item's label.
  final String label;

  /// The cascading menu's groups.
  final List<ExpressiveMenuGroup> groups;

  /// The glyph before the label.
  final IconData? icon;

  /// A second line under the label.
  final String? supportingText;

  /// Whether it takes input: false when groups is null, as in Flutter.
  bool get enabled => groups.isNotEmpty;
}

/// A divider between a group's items (`HorizontalDivider` with
/// `MenuDefaults.HorizontalDividerPadding`).
class ExpressiveMenuDivider extends ExpressiveMenuEntry {
  /// A divider between items.
  const ExpressiveMenuDivider();
}

/// A line the menu says rather than offers: nothing presses or focuses it,
/// and a screen reader hears it as it changes (a live region). It sits where
/// an item would, in the item's supporting type and ink, so [builder] gives
/// only the words (a combobox's "No results").
class ExpressiveMenuNote extends ExpressiveMenuEntry {
  /// A line built by [builder].
  const ExpressiveMenuNote(this.builder, {super.style});

  /// Builds what the line says.
  final WidgetBuilder builder;
}

/// A group of a menu (Compose's `DropdownMenuGroup`): an optional [label]
/// (`MenuDefaults.DropdownMenuGroupLabel`) over its [entries].
@immutable
class ExpressiveMenuGroup {
  /// A group of [entries] under an optional [label].
  const ExpressiveMenuGroup(this.entries, {this.label});

  /// The group's items, in order.
  final List<ExpressiveMenuEntry> entries;

  /// The group's label.
  final String? label;
}

// ---------------------------------------------------------------------------
// The menu surface.

/// A menu laid out: its [groups] as `DropdownMenuPopup` shows them, 2dp
/// apart, as wide as the widest item. [ExpressiveMenu] shows it in a popup;
/// laid out in place it is a menu at rest (a gallery, a screenshot).
/// A bounded height scrolls the entries instead of clipping the last action.
///
/// [vibrant] menus (`MenuDefaults.groupVibrantContainerColor`) are a hero
/// moment: they need an [ExpressiveHeroMoment] ancestor (CONTRACT §3).
class ExpressiveMenuSurface extends StatelessWidget {
  /// A menu surface laying out [groups].
  const ExpressiveMenuSurface({
    required this.groups,
    this.style,
    this.vibrant = false,
    super.key,
  }) : _inPopup = false;

  const ExpressiveMenuSurface._popup({
    required this.groups,
    this.style,
    required this.vibrant,
  }) : _inPopup = true;

  /// Stateful visual overrides for the menu.
  final ExpressiveComponentThemeData? style;

  /// The groups, top to bottom.
  final List<ExpressiveMenuGroup> groups;

  /// Whether the menu wears the vibrant colours (a hero).
  final bool vibrant;

  /// Whether it is in a menu's popup, which checked the hero at its anchor
  /// (the popup is on the root overlay, outside the page's hero).
  final bool _inPopup;

  @override
  Widget build(BuildContext context) {
    if (vibrant && !_inPopup) {
      assert(
        ExpressiveHeroMoment.debugCheck(context, 'ExpressiveMenu (vibrant)'),
      );
    }
    final visible = <ExpressiveMenuGroup>[
      for (final group in groups)
        if (group.entries.isNotEmpty || group.label != null) group,
    ];
    Widget menu = ExpressiveTheme(
      data: context.expressiveTheme.copyWith(
        menuTheme: context.expressiveTheme.menuTheme.layeredUnder(style),
      ),
      child: IntrinsicWidth(
        // One group scrolls its items inside its own padding, its container
        // standing still round them; several scroll together.
        child: visible.length == 1
            ? _MenuGroup(
                group: visible.single,
                shapes: _groupShapes(context, 0, 1),
                vibrant: vibrant,
                scrolls: true,
              )
            : SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: SegmentedMenuTokens.segmentedGap,
                  children: <Widget>[
                    for (var i = 0; i < visible.length; i++)
                      _MenuGroup(
                        group: visible[i],
                        shapes: _groupShapes(context, i, visible.length),
                        vibrant: vibrant,
                      ),
                  ],
                ),
              ),
      ),
    );
    // Laid out on a page: one lit row of its own, the pointer's under the
    // pointer (it takes no focus from the page), else the keys'.
    if (_LeadScope.read(context) == null) {
      menu = _LeadHost(initial: _Lead.keys, followsPointer: false, child: menu);
    }
    return menu;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ExpressiveComponentThemeData?>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(IterableProperty<ExpressiveMenuGroup>('groups', groups))
      ..add(FlagProperty('vibrant', value: vibrant, ifTrue: 'vibrant'));
  }
}

/// `MenuDefaults.groupShape(index, count)`: rest and inactive shapes.
({ExpressiveCornerBorder rest, ExpressiveCornerBorder inactive}) _groupShapes(
  BuildContext context,
  int index,
  int count,
) {
  final shapes = context.expressiveTheme.shapes;
  final inactive = shapes.of(SegmentedMenuTokens.inactiveContainerShape);
  if (count == 1) {
    return (
      rest: shapes.of(SegmentedMenuTokens.containerShape),
      inactive: inactive,
    );
  }
  final outer = shapes.large.topStart;
  final inner = shapes.small.topStart;
  final rest = index == 0
      ? ExpressiveCornerBorder(
          topStart: outer,
          topEnd: outer,
          bottomEnd: inner,
          bottomStart: inner,
        )
      : index == count - 1
      ? ExpressiveCornerBorder(
          topStart: inner,
          topEnd: inner,
          bottomEnd: outer,
          bottomStart: outer,
        )
      : shapes.of(SegmentedMenuTokens.groupShape);
  return (rest: rest, inactive: inactive);
}

/// `MenuDefaults.itemShape(index, count)`: rest and selected shapes.
ExpressivePressShapes _itemShapes(BuildContext context, int index, int count) {
  final shapes = context.expressiveTheme.shapes;
  final selected = shapes.of(SegmentedMenuTokens.itemSelectedShape);
  final outer = shapes.medium.topStart;
  final inner = shapes.extraSmall.topStart;
  final OutlinedBorder rest = count == 1
      ? shapes.of(SegmentedMenuTokens.itemShape)
      : index == 0
      ? ExpressiveCornerBorder(
          topStart: outer,
          topEnd: outer,
          bottomEnd: inner,
          bottomStart: inner,
        )
      : index == count - 1
      ? ExpressiveCornerBorder(
          topStart: inner,
          topEnd: inner,
          bottomEnd: outer,
          bottomStart: outer,
        )
      : shapes.of(SegmentedMenuTokens.itemShape);
  return ExpressivePressShapes(shape: rest, selected: selected);
}

/// A menu group: its surface, whose corners fall back to the inactive shape
/// once the mouse has been over it and left.
class _MenuGroup extends StatefulWidget {
  const _MenuGroup({
    required this.group,
    required this.shapes,
    required this.vibrant,
    this.scrolls = false,
  });

  final ExpressiveMenuGroup group;
  final ({ExpressiveCornerBorder rest, ExpressiveCornerBorder inactive}) shapes;
  final bool vibrant;

  /// Whether its items scroll inside its padding when its height is bounded
  /// (a menu of one group).
  final bool scrolls;

  @override
  State<_MenuGroup> createState() => _MenuGroupState();
}

class _MenuGroupState extends State<_MenuGroup> {
  bool _hovered = false;
  bool _hasBeenHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final container = ExpressiveComponentThemeData.resolve(
      t.menuTheme.backgroundColor,
      const <WidgetState>{},
      c.role(
        widget.vibrant
            ? VibrantMenuTokens.containerColor
            : StandardMenuTokens.containerColor,
      ),
    );
    final entries = widget.group.entries;
    final items = entries.whereType<ExpressiveMenuEntry>().where(
      (entry) =>
          entry is! ExpressiveMenuDivider && entry is! ExpressiveMenuNote,
    );
    final count = items.length;
    var index = 0;
    final label = widget.group.label;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = _hasBeenHovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ExpressiveSpringShape(
        value: _hasBeenHovered && !_hovered
            ? widget.shapes.inactive
            : widget.shapes.rest,
        motion: MenuBehavior.groupShapeMotion,
        builder: (context, shape, _) => ExpressiveSurface(
          componentStyle: t.menuTheme,
          states: {if (_hovered) WidgetState.hovered},
          shape: shape,
          color: container,
          shadowElevation: MenuTokens.containerElevation,
          child: _menuInset(
            scrolls: widget.scrolls,
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (label != null)
                  _GroupLabel(
                    label,
                    vibrant: widget.vibrant,
                    states: {if (_hovered) WidgetState.hovered},
                  ),
                for (final entry in entries)
                  if (entry is ExpressiveMenuDivider)
                    const _MenuDivider()
                  else if (entry is ExpressiveMenuNote)
                    _MenuNote(entry, vibrant: widget.vibrant)
                  else
                    _MenuEntryTile(
                      entry: entry,
                      shapes: _itemShapes(context, index++, count),
                      vibrant: widget.vibrant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A menu's list inside its container: 4dp clear of every edge
/// (`md.comp.menus.group.padding` above and below, the items' own 4dp at the
/// sides), at every density, so no item's fill or ring touches the container
/// and the items' corners stay concentric with its corners. Scrolled
/// ([scrolls]) inside that inset when its height is bounded.
Widget _menuInset(Widget list, {bool scrolls = false}) => Padding(
  padding: const EdgeInsets.symmetric(
    vertical: SegmentedMenuTokens.groupPadding,
  ),
  child: scrolls ? SingleChildScrollView(primary: false, child: list) : list,
);

/// An [ExpressiveMenuNote]: an item's padding and height, its supporting
/// text's type and ink, nothing to press; a live region.
class _MenuNote extends StatelessWidget {
  const _MenuNote(this.note, {required this.vibrant});

  final ExpressiveMenuNote note;
  final bool vibrant;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    const states = <WidgetState>{};
    final style = t.type.bodyMedium
        .merge(t.menuTheme.textStyle?.resolve(states))
        .merge(note.style?.textStyle?.resolve(states))
        .copyWith(
          color:
              note.style?.foregroundColor?.resolve(states) ??
              t.colors.role(
                vibrant
                    ? VibrantMenuTokens.itemSupportingTextColor
                    : StandardMenuTokens.itemSupportingTextColor,
              ),
        );
    return Semantics(
      container: true,
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: MenuBehavior.itemMinWidth,
          maxWidth: MenuBehavior.itemMaxWidth,
          minHeight: SegmentedMenuTokens.item,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal:
                MenuBehavior.itemInset + MenuBehavior.itemHorizontalPadding,
            vertical: MenuBehavior.itemVerticalPadding,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: DefaultTextStyle.merge(
              style: style,
              child: Builder(builder: note.builder),
            ),
          ),
        ),
      ),
    );
  }
}

/// `MenuDefaults.DropdownMenuGroupLabel`.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(
    this.label, {
    required this.vibrant,
    this.states = const {},
  });

  final String label;
  final bool vibrant;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Semantics(
      header: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: MenuBehavior.itemMinWidth,
          maxWidth: MenuBehavior.itemMaxWidth,
          minHeight: MenuBehavior.groupLabelMinHeight,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: MenuBehavior.groupLabelPaddingStart,
            end: MenuBehavior.groupLabelPaddingEnd,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: Text(
              label,
              style: t.type.labelLarge
                  .merge(t.menuTheme.textStyle?.resolve(states))
                  .copyWith(
                    color: ExpressiveComponentThemeData.resolve(
                      t.menuTheme.foregroundColor,
                      states,
                      t.colors.role(
                        vibrant
                            ? VibrantMenuTokens.itemLabelTextColor
                            : StandardMenuTokens.itemLabelTextColor,
                      ),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A group's divider.
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: MenuBehavior.dividerHorizontalPadding,
      vertical: MenuBehavior.dividerVerticalPadding,
    ),
    child: SizedBox(
      height: DividerTokens.thickness,
      child: ColoredBox(
        color: context.expressiveTheme.colors.role(DividerTokens.color),
      ),
    ),
  );
}

/// An item's colours in one state (Compose's `MenuItemColors` /
/// `SelectableMenuItemColors`, resolved).
typedef _ItemColors = ({
  Color container,
  Color text,
  Color leading,
  Color trailing,
});

/// [_tokenItemColors] under the menu theme: the content slot paints the
/// label and icons (resolved with disabled and selected), the container
/// slot a selected item's container (resolved with selected).
_ItemColors _itemColors(
  BuildContext context, {
  required bool selectable,
  required bool vibrant,
  required bool enabled,
  required bool selected,
}) {
  final colors = _tokenItemColors(
    context,
    selectable: selectable,
    vibrant: vibrant,
    enabled: enabled,
    selected: selected,
  );
  final theme = context.expressiveTheme.menuTheme;
  if (theme.isEmpty) return colors;
  final chosen = selectable && selected;
  final states = expressiveComponentStates(enabled: enabled, selected: chosen);
  Color on(Color fallback) => ExpressiveComponentThemeData.resolve(
    theme.foregroundColor,
    states,
    fallback,
  );
  return (
    container: enabled && chosen
        ? ExpressiveComponentThemeData.resolve(
            theme.backgroundColor,
            states,
            colors.container,
          )
        : colors.container,
    text: on(colors.text),
    leading: on(colors.leading),
    trailing: on(colors.trailing),
  );
}

_ItemColors _tokenItemColors(
  BuildContext context, {
  required bool selectable,
  required bool vibrant,
  required bool enabled,
  required bool selected,
}) {
  final c = context.expressiveTheme.colors;
  Color faded(ExpressiveColorRole role, double opacity) =>
      c.role(role).withValues(alpha: opacity);
  if (vibrant) {
    final container = c.role(VibrantMenuTokens.containerColor);
    if (!enabled) {
      return (
        container: container,
        text: faded(
          VibrantMenuTokens.itemDisabledLabelTextColor,
          VibrantMenuTokens.itemDisabledLabelTextOpacity,
        ),
        leading: faded(
          VibrantMenuTokens.itemDisabledLeadingIconColor,
          VibrantMenuTokens.itemDisabledLeadingIconOpacity,
        ),
        trailing: faded(
          VibrantMenuTokens.itemDisabledTrailingIconColor,
          VibrantMenuTokens.itemDisabledTrailingIconOpacity,
        ),
      );
    }
    if (selectable && selected) {
      return (
        container: c.role(VibrantMenuTokens.itemSelectedContainerColor),
        text: c.role(VibrantMenuTokens.itemSelectedLabelTextColor),
        leading: c.role(VibrantMenuTokens.itemSelectedLeadingIconColor),
        trailing: c.role(VibrantMenuTokens.itemSelectedTrailingIconColor),
      );
    }
    return (
      container: container,
      text: c.role(VibrantMenuTokens.itemLabelTextColor),
      leading: c.role(VibrantMenuTokens.itemLeadingIconColor),
      trailing: c.role(VibrantMenuTokens.itemTrailingIconColor),
    );
  }
  if (!selectable) {
    // `defaultMenuItemColors`: the list item's colours on no container.
    final container = c.role(StandardMenuTokens.containerColor);
    if (!enabled) {
      return (
        container: container.withValues(alpha: 0),
        text: faded(
          ListTokens.itemDisabledLabelTextColor,
          ListTokens.itemDisabledLabelTextOpacity,
        ),
        leading: faded(
          ListTokens.itemDisabledLeadingIconColor,
          ListTokens.itemDisabledLeadingIconOpacity,
        ),
        trailing: faded(
          ListTokens.itemDisabledTrailingIconColor,
          ListTokens.itemDisabledTrailingIconOpacity,
        ),
      );
    }
    return (
      container: container.withValues(alpha: 0),
      text: c.role(ListTokens.itemLabelTextColor),
      leading: c.role(ListTokens.itemLeadingIconColor),
      trailing: c.role(ListTokens.itemTrailingIconColor),
    );
  }
  final container = c.role(StandardMenuTokens.containerColor);
  if (!enabled) {
    return (
      container: container,
      text: faded(
        StandardMenuTokens.itemDisabledLabelTextColor,
        StandardMenuTokens.itemDisabledLabelTextOpacity,
      ),
      leading: faded(
        StandardMenuTokens.itemDisabledLeadingIconColor,
        StandardMenuTokens.itemDisabledLeadingIconOpacity,
      ),
      trailing: faded(
        StandardMenuTokens.itemDisabledTrailingIconColor,
        StandardMenuTokens.itemDisabledTrailingIconOpacity,
      ),
    );
  }
  if (selected) {
    return (
      container: c.role(StandardMenuTokens.itemSelectedContainerColor),
      text: c.role(StandardMenuTokens.itemSelectedLabelTextColor),
      leading: c.role(StandardMenuTokens.itemSelectedLeadingIconColor),
      trailing: c.role(StandardMenuTokens.itemSelectedTrailingIconColor),
    );
  }
  return (
    container: container,
    text: c.role(StandardMenuTokens.itemLabelTextColor),
    leading: c.role(StandardMenuTokens.itemLeadingIconColor),
    trailing: c.role(StandardMenuTokens.itemTrailingIconColor),
  );
}

// ---------------------------------------------------------------------------
// One lit row.

/// What last moved an open menu's highlight: the pointer or the keys.
enum _Lead {
  /// The pointer, moving over a row.
  pointer,

  /// A key, or anything else that moved the focus.
  keys,
}

/// How a menu's row is lit.
enum _Light {
  /// Not lit.
  off,

  /// The pointer's: the hover layer.
  plate,

  /// The keys': the focus indicator alone.
  ring,
}

/// One menu's highlight: the one row a person reads as current. The pointer
/// moving over a row lights it on the hover layer (in a popup that holds the
/// focus, the focus moves there too, so the keys go on from it); the keys
/// light the focused row with the focus indicator. Either puts the other's
/// light out, so no frame shows two current rows. A pointer resting where a
/// menu opened lights nothing until it moves.
class _MenuLead extends ValueNotifier<_Lead> {
  _MenuLead(super.value, {required this.followsPointer});

  /// Whether the pointer takes the focus to the row it moves over: a popup
  /// that holds the focus. A menu laid out on a page, or a list whose field
  /// keeps the focus for typing, lights the row under the pointer alone,
  /// and takes the focus there only while one of its rows holds it.
  final bool followsPointer;

  /// The node round the menu's rows, to tell whether one of them holds the
  /// focus.
  FocusNode? rows;

  /// The row the pointer last took the focus to.
  FocusNode? pointerFocus;

  /// The light of a row [focused] and [hovered] as it is.
  _Light lightOf({required bool focused, required bool hovered}) =>
      switch (value) {
        _Lead.pointer =>
          (followsPointer ? focused : hovered) ? _Light.plate : _Light.off,
        _Lead.keys => focused ? _Light.ring : _Light.off,
      };

  /// The pointer moved over an enabled row, [focus] its node: the keys go
  /// on from it whenever they are in the menu.
  void pointerOver(FocusNode? focus) {
    value = _Lead.pointer;
    pointerFocus = focus;
    if ((followsPointer || (rows?.hasFocus ?? false)) &&
        focus != null &&
        focus.canRequestFocus &&
        !focus.hasPrimaryFocus) {
      focus.requestFocus();
    }
  }
}

/// The lit row's light where no menu says ([_LeadScope] absent): the
/// pointer's under the pointer, else the keys'.
_Light _lightAlone({required bool focused, required bool hovered}) => hovered
    ? _Light.plate
    : focused
    ? _Light.ring
    : _Light.off;

/// A menu's [_MenuLead] for the rows under it.
class _LeadScope extends InheritedNotifier<_MenuLead> {
  const _LeadScope({required _MenuLead lead, required super.child})
    : super(notifier: lead);

  /// The lead over [context], rebuilding it as the lead moves.
  static _MenuLead? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LeadScope>()?.notifier;

  /// The lead over [context], read once.
  static _MenuLead? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_LeadScope>()?.notifier;
}

/// The keys that only change another key: they move no highlight.
final Set<LogicalKeyboardKey> _modifierKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
  LogicalKeyboardKey.capsLock,
  LogicalKeyboardKey.fn,
};

/// Holds one menu's [_MenuLead] round [child]: a key pressed in it hands
/// the light to the keys.
class _LeadHost extends StatefulWidget {
  const _LeadHost({
    required this.initial,
    required this.followsPointer,
    required this.child,
  });

  /// The lead as the menu appears.
  final _Lead initial;

  /// [_MenuLead.followsPointer].
  final bool followsPointer;

  final Widget child;

  @override
  State<_LeadHost> createState() => _LeadHostState();
}

class _LeadHostState extends State<_LeadHost> {
  final FocusNode _rows = FocusNode(
    debugLabel: 'ExpressiveMenu rows',
    canRequestFocus: false,
    skipTraversal: true,
  );
  late final _MenuLead _lead = _MenuLead(
    widget.initial,
    followsPointer: widget.followsPointer,
  )..rows = _rows;

  @override
  void initState() {
    super.initState();
    // A menu that does not hold the focus itself: the focus coming into it
    // other than by the pointer (Tab, a key that opened it) is the keys'.
    if (!widget.followsPointer) _rows.addListener(_focusMoved);
  }

  void _focusMoved() {
    if (_rows.hasFocus &&
        FocusManager.instance.primaryFocus != _lead.pointerFocus) {
      _lead.value = _Lead.keys;
    }
  }

  @override
  void dispose() {
    _rows.removeListener(_focusMoved);
    _lead.dispose();
    _rows.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _modifierKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    _lead.value = _Lead.keys;
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => _LeadScope(
    lead: _lead,
    child: Focus(
      focusNode: _rows,
      includeSemantics: false,
      onKeyEvent: _onKey,
      child: widget.child,
    ),
  );
}

/// One entry laid out as its item, wired to the popup it is in.
class _MenuEntryTile extends StatefulWidget {
  const _MenuEntryTile({
    required this.entry,
    required this.shapes,
    required this.vibrant,
  });

  final ExpressiveMenuEntry entry;
  final ExpressivePressShapes shapes;
  final bool vibrant;

  @override
  State<_MenuEntryTile> createState() => _MenuEntryTileState();
}

class _MenuEntryTileState extends State<_MenuEntryTile> {
  /// A checkable item's state as the user last set it: shown at once, even
  /// in a menu whose entries were fixed when it opened, until the app's
  /// entry says otherwise.
  bool? _checked;

  bool _submenuOpen = false;

  @override
  void didUpdateWidget(_MenuEntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.entry;
    final entry = widget.entry;
    if (old is ExpressiveMenuCheckItem &&
        entry is ExpressiveMenuCheckItem &&
        old.value != entry.value) {
      _checked = null;
    }
  }

  /// Closes the menu this item is in (every level of a cascade), if it is
  /// in one.
  void _closeMenu() => _closeEnclosingMenu(context, chosen: true);

  Future<void> _openSubmenu(ExpressiveMenuSubmenu submenu) async {
    final route = ModalRoute.of(context);
    setState(() => _submenuOpen = true);
    final chosen = await _showMenuRoute(
      context,
      anchor: null,
      position: ExpressiveMenuPosition.end,
      label: submenu.label,
      listKeys: true,
      focusItem: _openKeyHeld(),
      content: (context) => ExpressiveMenuSurface._popup(
        groups: submenu.groups,
        vibrant: widget.vibrant,
      ),
    );
    if (!mounted) return;
    setState(() => _submenuOpen = false);
    if (chosen != true) return;
    if (route is _MenuRoute && route.isActive) {
      route.close(chosen: true);
    } else if (mounted) {
      _closeEnclosingMenu(context, chosen: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    switch (entry) {
      case ExpressiveMenuItem():
        final enabled = entry.enabled && entry.onPressed != null;
        return _MenuItemTile(
          style: entry.style,
          label: entry.label,
          supportingText: entry.supportingText,
          icon: entry.icon,
          trailing: _trailing(entry.trailingText, entry.trailingIcon),
          shapes: widget.shapes,
          colors: _itemColors(
            context,
            selectable: false,
            vibrant: widget.vibrant,
            enabled: enabled,
            selected: false,
          ),
          role: ExpressivePressRole.button,
          onPressed: enabled
              ? () {
                  _closeMenu();
                  entry.onPressed!();
                }
              : null,
        );
      case ExpressiveMenuCheckItem():
        final enabled = entry.enabled && entry.onChanged != null;
        final checked = _checked ?? entry.value;
        return _MenuItemTile(
          style: entry.style,
          label: entry.label,
          supportingText: entry.supportingText,
          icon: entry.icon,
          selectedIcon:
              entry.checkedIcon ??
              (entry.icon == null ? ExpressiveSymbols.check : null),
          selected: checked,
          trailing: _trailing(entry.trailingText, null),
          shapes: widget.shapes,
          colors: _itemColors(
            context,
            selectable: true,
            vibrant: widget.vibrant,
            enabled: enabled,
            selected: checked,
          ),
          role: ExpressivePressRole.checkbox,
          onPressed: enabled
              ? () {
                  setState(() => _checked = !checked);
                  if (entry.closesMenu) _closeMenu();
                  entry.onChanged!(!checked);
                }
              : null,
        );
      case ExpressiveMenuRadioItem():
        final enabled = entry.enabled && entry.onSelected != null;
        return _MenuItemTile(
          style: entry.style,
          label: entry.label,
          supportingText: entry.supportingText,
          icon: entry.icon,
          selectedIcon:
              entry.selectedIcon ??
              (entry.icon == null && entry.check
                  ? ExpressiveSymbols.check
                  : null),
          selected: entry.selected,
          trailing: _trailing(entry.trailingText, null),
          shapes: widget.shapes,
          colors: _itemColors(
            context,
            selectable: true,
            vibrant: widget.vibrant,
            enabled: enabled,
            selected: entry.selected,
          ),
          role: ExpressivePressRole.radio,
          onPressed: enabled
              ? () {
                  if (entry.closesMenu) _closeMenu();
                  entry.onSelected!();
                }
              : null,
        );
      case ExpressiveMenuSubmenu():
        final enabled = entry.enabled && entry.groups.isNotEmpty;
        final forward = Directionality.of(context) == TextDirection.ltr
            ? ExpressiveSymbols.keyboardArrowRight
            : ExpressiveSymbols.keyboardArrowLeft;
        return Semantics(
          expanded: _submenuOpen,
          child: _MenuItemTile(
            style: entry.style,
            label: entry.label,
            supportingText: entry.supportingText,
            icon: entry.icon,
            selected: _submenuOpen,
            trailing: Icon(forward),
            shapes: widget.shapes,
            colors: _itemColors(
              context,
              selectable: true,
              vibrant: widget.vibrant,
              enabled: enabled,
              selected: _submenuOpen,
            ),
            role: ExpressivePressRole.button,
            onPressed: enabled ? () => _openSubmenu(entry) : null,
          ),
        );
      case ExpressiveMenuDivider():
        return const SizedBox.shrink();
      case ExpressiveMenuNote():
        return _MenuNote(entry, vibrant: widget.vibrant);
    }
  }

  Widget? _trailing(String? text, IconData? icon) {
    if (text != null) {
      // A shortcut's keys on the item's middle, by their capitals, as its
      // label is.
      return expressiveFaceLabel(Text(text));
    }
    if (icon != null) {
      return Icon(icon);
    }
    return null;
  }
}

/// `DropdownMenuItemContent`: the item's surface on the shared pressable,
/// its leading icon (the check growing in), label and trailing content laid
/// out as `MenuArrangement` does.
class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.label,
    this.style,
    required this.shapes,
    required this.colors,
    required this.role,
    required this.onPressed,
    this.supportingText,
    this.icon,
    this.selectedIcon,
    this.selected = false,
    this.trailing,
  });

  final String label;
  final ExpressiveComponentThemeData? style;
  final String? supportingText;
  final IconData? icon;
  final IconData? selectedIcon;
  final bool selected;
  final Widget? trailing;
  final ExpressivePressShapes shapes;
  final _ItemColors colors;
  final ExpressivePressRole role;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final enabled = onPressed != null;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MenuBehavior.itemInset,
        vertical: supportingText == null
            ? 0
            : MenuBehavior.itemInsetVerticalWithSupportingText,
      ),
      child: _LitItem(
        enabled: enabled,
        builder: (focus, states, light) {
          final hover =
              t.menuTheme.overlayColor?.resolve(const {WidgetState.hovered}) ??
              t.states.layerOf(colors.text, const {WidgetState.hovered});
          // The pointer's light is the container's own colour, springing
          // from row to row; the hover and focus layers stay off, so a
          // pointer resting where the menu opened, or a row the keys left,
          // lights nothing. A press keeps its ripple.
          Color lit(Color base) => light == _Light.plate && hover != null
              ? Color.alphaBlend(hover, base)
              : base;
          return ExpressivePressable(
            style: style,
            componentStyle: t.menuTheme.copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                final own = selected && enabled
                    ? t.menuTheme.backgroundColor?.resolve(states)
                    : null;
                return own == null ? null : lit(own);
              }),
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? t.menuTheme.overlayColor?.resolve(states)
                    : const Color(0x00000000),
              ),
            ),
            focusNode: focus,
            statesController: states,
            shapes: shapes,
            motion: MenuBehavior.itemShapeMotion,
            colorMotion: MenuBehavior.itemColorMotion,
            color: lit(colors.container),
            contentColor: colors.text,
            selected: selected,
            role: role,
            onPressed: onPressed,
            // The keys' light is the focus indicator alone, inside the item:
            // the item stands 4dp in from the menu's edges, and a ring 2dp
            // out would lie under its neighbours.
            focusInward: true,
            focusRing: light == _Light.ring,
            child: _itemContent(context),
          );
        },
      ),
    );
  }

  /// The item's icon, words and trailing content, laid out as
  /// `MenuArrangement` does.
  Widget _itemContent(BuildContext context) {
    final t = context.expressiveTheme;
    return Builder(
      builder: (context) {
        final scope = ExpressiveStyleScope.maybeOf(context)!;
        final scoped = scope.style;
        final states = scope.states;
        final hasLeading = icon != null || selectedIcon != null;
        final iconSize =
            scoped.iconSize?.resolve(states) ??
            SegmentedMenuTokens.itemLeadingIconSize;
        // Under a field's list, the words where the field's value starts
        // and an icon under the field's leading icon (centred 28dp
        // before the words); else the item's own padding.
        double start = MenuBehavior.itemHorizontalPadding;
        double gap = MenuBehavior.itemIconSpacing;
        final words = _WordsStart.of(context);
        if (words != null) {
          // Density widens or narrows the padding by this much; the
          // measured field already has it.
          final density = t.density.horizontal * 2;
          final iconStart = words - 28 - iconSize / 2;
          if (!hasLeading) {
            start = math.max(0.0, words - MenuBehavior.itemInset - density);
          } else if (iconStart - MenuBehavior.itemInset - density >= 4) {
            start = iconStart - MenuBehavior.itemInset - density;
            gap = words - iconStart - iconSize;
          }
        }
        final textStyle = t.type.labelLarge.merge(
          scoped.textStyle?.resolve(states),
        );
        final Widget text = supportingText == null
            ? expressiveFaceLabel(Text(label, style: textStyle))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: textStyle),
                  Text(
                    supportingText!,
                    style: t.type.bodyMedium.merge(
                      scoped.textStyle?.resolve(states),
                    ),
                  ),
                ],
              );
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: MenuBehavior.itemMaxWidth,
          ),
          child: ExpressiveStyledContent(
            center: false,
            minimumSize: const Size(
              MenuBehavior.itemMinWidth,
              SegmentedMenuTokens.item,
            ),
            textStyle: textStyle,
            iconSize: SegmentedMenuTokens.itemLeadingIconSize,
            padding: EdgeInsetsDirectional.fromSTEB(
              start,
              MenuBehavior.itemVerticalPadding,
              MenuBehavior.itemHorizontalPadding,
              MenuBehavior.itemVerticalPadding,
            ),
            child: Row(
              children: <Widget>[
                if (hasLeading) ...<Widget>[
                  IconTheme.merge(
                    data: IconThemeData(
                      color:
                          scoped.foregroundColor?.resolve(states) ??
                          colors.leading,
                      size:
                          scoped.iconSize?.resolve(states) ??
                          SegmentedMenuTokens.itemLeadingIconSize,
                    ),
                    child: _Leading(
                      icon: icon,
                      selectedIcon: selectedIcon,
                      selected: selected,
                    ),
                  ),
                  SizedBox(width: gap),
                ],
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color:
                          scoped.foregroundColor?.resolve(states) ??
                          colors.text,
                    ),
                    child: text,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: MenuBehavior.itemIconSpacing),
                  IconTheme.merge(
                    data: IconThemeData(
                      size:
                          scoped.iconSize?.resolve(states) ??
                          SegmentedMenuTokens.itemTrailingIconSize,
                      color:
                          scoped.foregroundColor?.resolve(states) ??
                          colors.trailing,
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color:
                            scoped.foregroundColor?.resolve(states) ??
                            colors.trailing,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: SegmentedMenuTokens.itemTrailingIconSize,
                        ),
                        child: Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: trailing,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Holds a menu item's focus and states, and lights it as its menu's one
/// lit row ([_MenuLead]): the pointer moving over it lights it, and in a
/// popup that holds the focus takes the focus there.
class _LitItem extends StatefulWidget {
  const _LitItem({required this.enabled, required this.builder});

  final bool enabled;

  /// The item for its focus, its states and its light.
  final Widget Function(
    FocusNode focus,
    WidgetStatesController states,
    _Light light,
  )
  builder;

  @override
  State<_LitItem> createState() => _LitItemState();
}

class _LitItemState extends State<_LitItem> {
  final FocusNode _focus = FocusNode(debugLabel: 'ExpressiveMenu item');
  final WidgetStatesController _states = WidgetStatesController();
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
    _states.addListener(_statesChanged);
  }

  void _focusChanged() {
    if (mounted) setState(() {});
  }

  // Only the hover matters here; the pressable sets the rest as it builds.
  void _statesChanged() {
    final hovered = _states.value.contains(WidgetState.hovered);
    if (hovered == _hovered) return;
    _hovered = hovered;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_focusChanged)
      ..dispose();
    _states
      ..removeListener(_statesChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lead = _LeadScope.of(context);
    final focused = _focus.hasPrimaryFocus;
    final light = !widget.enabled
        ? _Light.off
        : lead?.lightOf(focused: focused, hovered: _hovered) ??
              _lightAlone(focused: focused, hovered: _hovered);
    return MouseRegion(
      onHover: widget.enabled && lead != null
          ? (_) => lead.pointerOver(_focus)
          : null,
      child: widget.builder(_focus, _states, light),
    );
  }
}

/// An item's leading slot: the icon, the selected icon in its place when
/// selected, or — with no icon — the selected icon growing in and fading in
/// (`AnimatedVisibility(expandHorizontally + fadeIn)`) on the fast springs.
class _Leading extends StatelessWidget {
  const _Leading({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
  });

  final IconData? icon;
  final IconData? selectedIcon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final selectedIcon = this.selectedIcon;
    // `WrappedLeadingIcon`: the slot's minimum width is inside the
    // animated visibility, so an unchecked check collapses to nothing.
    Widget wrapped(Widget glyph) => ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: SegmentedMenuTokens.itemLeadingIconSize,
      ),
      child: glyph,
    );
    if (icon != null) {
      return wrapped(
        selected && selectedIcon != null
            ? Icon(selectedIcon)
            : ExpressiveIcon(icon, selected: selected),
      );
    }
    final target = selected ? 1.0 : 0.0;
    return ExpressiveSpringValue(
      value: target,
      motion: MenuBehavior.checkIconSizeMotion,
      builder: (context, width, child) => ExpressiveSpringValue(
        value: target,
        motion: MenuBehavior.checkIconFadeMotion,
        builder: (context, alpha, _) => ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: clampDouble(width, 0, 1),
            child: Opacity(opacity: clampDouble(alpha, 0, 1), child: child),
          ),
        ),
      ),
      child: wrapped(Icon(selectedIcon)),
    );
  }
}

// ---------------------------------------------------------------------------
// The popup.

/// Where a menu or popover opens against its anchor (Compose's
/// `MenuAnchorPosition`): it takes the next of Compose's candidate
/// positions when the preferred one leaves the window's margins.
enum ExpressiveMenuPosition {
  /// Under the anchor, start edges aligned (`Below`, the default).
  below,

  /// Over the anchor, start edges aligned (`Above`).
  above,

  /// Before the anchor, top edges aligned (`Start`).
  start,

  /// After the anchor, top edges aligned (`End`: cascading menus).
  end,
}

/// How a menu or popover is opened from its [ExpressiveMenu.child]: a tap
/// (an overflow button) or a long press (a context menu, also opened by a
/// secondary click).
enum ExpressiveMenuTrigger {
  /// A tap on the anchor.
  tap,

  /// A long press or secondary click on the anchor.
  longPress,
}

/// Opens and closes an [ExpressiveMenu] or an [ExpressivePopover] from the
/// app: an app bar's overflow button, a split button's trailing half, a
/// select's field.
class ExpressiveMenuController extends ChangeNotifier {
  _MenuAnchorState? _anchor;

  /// Whether the menu is open.
  bool get isOpen => _anchor?._isOpen ?? false;

  /// Opens the menu.
  void open() => _anchor?._open();

  /// Closes the menu.
  void close() => _anchor?._close();

  /// Opens the menu when closed, closes it when open.
  void toggle() => isOpen ? close() : open();

  /// Moves keyboard focus onto the open menu's first item (a select's
  /// field hands the arrow keys over to its menu); nothing when closed.
  void focusFirstItem() => _anchor?._focusFirstItem();

  /// Moves keyboard focus onto the open menu's chosen item (a select's
  /// choice), or its first when none is chosen: what a list opened from the
  /// keyboard starts on. Called as the menu opens, it waits for the menu's
  /// first frame.
  void focusChosenItem() => _anchor?._focusChosenItem();

  void _changed() => notifyListeners();
}

/// Closes the menu a non-modal popup ([ExpressiveMenu.modal] false) holds:
/// its items and [ExpressivePopover.close] find it before any route.
class _MenuCloser extends InheritedWidget {
  const _MenuCloser({required this.close, required super.child});

  final void Function({bool chosen}) close;

  @override
  bool updateShouldNotify(_MenuCloser oldWidget) => close != oldWidget.close;
}

/// Closes the menu or popover [context] is in — a non-modal popup's, else
/// the [_MenuRoute]'s — if it is in one.
void _closeEnclosingMenu(BuildContext context, {bool chosen = false}) {
  final closer = context.getInheritedWidgetOfExactType<_MenuCloser>();
  if (closer != null) {
    closer.close(chosen: chosen);
    return;
  }
  final route = ModalRoute.of(context);
  if (route is _MenuRoute && route.isActive) route.close(chosen: chosen);
}

/// The popup a menu or popover is raised in: an [ExpressivePopupRoute] on
/// the fast effects spring (the fade), whose content scales on the fast
/// spatial spring.
class _MenuRoute extends ExpressivePopupRoute<bool> {
  _MenuRoute({
    required super.builder,
    required super.spring,
    required super.capturedThemes,
    required super.barrierLabel,
  }) : super(
         transitionBuilder: (context, animation, child) =>
             FadeTransition(opacity: animation, child: child),
       );

  /// Told when the route starts to close: the popup scales back.
  VoidCallback? _onClosing;

  @override
  bool didPop(bool? result) {
    // False when an overlay held open in the popup took the pop.
    if (!super.didPop(result)) return false;
    _onClosing?.call();
    return true;
  }

  /// Closes the menu; [chosen] when an item's choice closed it (a
  /// cascade's parents close too).
  void close({bool chosen = false}) {
    final navigator = this.navigator;
    if (navigator == null || !isActive) return;
    if (isCurrent) {
      navigator.pop(chosen);
    } else {
      navigator.removeRoute(this, chosen);
    }
  }
}

/// Raises [content] in a [_MenuRoute] on the root navigator, placed against
/// [anchor] (global coordinates), or against [context]'s own box when null.
/// Resolves to whether a choice closed it.
Future<bool?> _showMenuRoute(
  BuildContext context, {
  required Rect? anchor,
  required ExpressiveMenuPosition position,
  required WidgetBuilder content,
  required String? label,
  ValueChanged<_MenuRoute>? onRoute,
  bool matchAnchorWidth = false,
  double? maxHeight,
  FocusScopeNode? focusScope,
  bool listKeys = false,
  bool focusItem = false,
  VoidCallback? onShown,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final ground = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final Rect local;
  if (anchor != null) {
    local = Rect.fromPoints(
      ground.globalToLocal(anchor.topLeft),
      ground.globalToLocal(anchor.bottomRight),
    );
  } else {
    final box = context.findRenderObject()! as RenderBox;
    local = MatrixUtils.transformRect(
      box.getTransformTo(ground),
      Offset.zero & box.size,
    );
  }
  final motion = ExpressiveMotion.of(context);
  final direction = Directionality.of(context);
  final route = _MenuRoute(
    spring: motion.spring(MenuBehavior.openAlphaMotion),
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
    builder: (context) => _MenuPopup(
      anchor: local,
      position: position,
      label: label,
      spring: motion.spring(MenuBehavior.openScaleMotion),
      textDirection: direction,
      matchAnchorWidth: matchAnchorWidth,
      maxHeight: maxHeight,
      focusScope: focusScope,
      listKeys: listKeys,
      focusItem: focusItem,
      onShown: onShown,
      child: Builder(builder: content),
    ),
  );
  onRoute?.call(route);
  return navigator.push<bool>(route);
}

/// The items of an open menu under [root], top to bottom: each item's own
/// focus node, those that take focus.
List<FocusNode> _menuItems(FocusNode root) {
  final seen = Set<_MenuItemTile>.identity();
  final items = <FocusNode>[];
  for (final node in root.descendants) {
    if (node.context == null || !node.canRequestFocus || node.skipTraversal) {
      continue;
    }
    final tile = _tileOf(node);
    if (tile == null || !seen.add(tile)) continue;
    items.add(node);
  }
  items.sort((a, b) => a.rect.top.compareTo(b.rect.top));
  return items;
}

_MenuItemTile? _tileOf(FocusNode node) =>
    node.context?.findAncestorWidgetOfExactType<_MenuItemTile>();

/// Whether [node] is the chosen item: a select's choice.
bool _isChosen(FocusNode node) {
  final tile = _tileOf(node);
  return tile != null &&
      tile.role == ExpressivePressRole.radio &&
      tile.selected;
}

/// The item a list opened from the keyboard starts on: the chosen one, else
/// the first.
FocusNode? _chosenOrFirst(List<FocusNode> items) => items.isEmpty
    ? null
    : items.firstWhere(_isChosen, orElse: () => items.first);

/// Scrolls the open menu's list the least that shows [node]'s item whole:
/// a long list keeps the keys' item in view.
void _keepInView(FocusNode node) {
  final context = node.context;
  if (context == null || !context.mounted) return;
  for (final policy in const [
    ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    ScrollPositionAlignmentPolicy.keepVisibleAtStart,
  ]) {
    Scrollable.ensureVisible(context, alignmentPolicy: policy);
  }
}

/// Gives [node]'s item the focus and keeps it in view: the keys' move, so
/// the menu's light goes to the keys.
void _focusInView(FocusNode? node) {
  if (node == null) return;
  final context = node.context;
  if (context != null) _LeadScope.read(context)?.value = _Lead.keys;
  node.requestFocus();
  _keepInView(node);
}

/// Whether a key that opens a menu is held: the menu opened from the
/// keyboard.
bool _openKeyHeld() => HardwareKeyboard.instance.logicalKeysPressed.any(
  (key) =>
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.arrowUp,
);

/// The popup's page: the surface placed against the anchor, scaling from
/// [MenuBehavior.closedScale] as the route opens and back as it closes,
/// scrolling when taller than the window's margins allow, and moving focus
/// between items with the keys ([listKeys]).
class _MenuPopup extends StatefulWidget {
  const _MenuPopup({
    required this.anchor,
    required this.position,
    required this.label,
    required this.spring,
    required this.textDirection,
    required this.child,
    this.matchAnchorWidth = false,
    this.maxHeight,
    this.focusScope,
    this.closing,
    this.listKeys = false,
    this.focusItem = false,
    this.onShown,
    this.onEscape,
  });

  final Rect anchor;
  final ExpressiveMenuPosition position;
  final String? label;

  /// Whether the popup is a list from a field: as wide as the anchor
  /// (`exposedDropdownSize(matchAnchorWidth = true)`), wider only as far
  /// as its widest item needs, never past the window's margins.
  final bool matchAnchorWidth;

  /// The tallest the popup grows before it scrolls; the window's margins
  /// bound it too.
  final double? maxHeight;

  /// The focus scope holding the items, for
  /// [ExpressiveMenuController.focusFirstItem]; none when null.
  final FocusScopeNode? focusScope;

  /// Set when a non-modal popup starts to close: the popup scales back
  /// (a route's popup hears it from the route). Null for a route's popup.
  final ValueListenable<bool>? closing;

  /// Whether the popup is a list of items the keys walk, as a listbox's or
  /// a menu's are: Down and Up move at once, wrapping at the ends; Home and
  /// End go to them; a typed letter goes to the next item it starts. A
  /// route's popup takes the keyboard itself as it opens, so the arrows
  /// work right after a pointer opened it: from the chosen item (a
  /// select's choice), else from the ends.
  final bool listKeys;

  /// Whether a key opened the popup: its chosen item takes focus as it
  /// appears, else its first.
  final bool focusItem;

  /// Told after the popup's first frame, its items laid out.
  final VoidCallback? onShown;

  /// Escape with an item focused, for a non-modal popup (a route's own
  /// dismiss closes a route's): it closes, and focus goes back to its field.
  final VoidCallback? onEscape;

  /// The scale's spring, read where the menu was opened (its Reduce Motion,
  /// its Standard pin).
  final SpringDescription spring;

  /// The reading direction where the menu was opened.
  final TextDirection textDirection;

  final Widget child;

  @override
  State<_MenuPopup> createState() => _MenuPopupState();
}

class _MenuPopupState extends State<_MenuPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: MenuBehavior.closedScale,
  );
  _MenuRoute? _route;

  /// The popup's own keyboard: an ancestor of every item, focused while no
  /// item is (a route's popup opened by a pointer).
  final FocusNode _keys = FocusNode(
    debugLabel: 'ExpressiveMenu keys',
    skipTraversal: true,
  );

  /// The letters typed in a row, for [_typeAhead], and when the last came.
  String _typed = '';
  DateTime _typedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _scale.springTo(1, widget.spring);
    widget.closing?.addListener(_closingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revealChosen();
      if (widget.focusItem) _focusInView(_chosenOrFirst(_menuItems(_keys)));
      widget.onShown?.call();
    });
  }

  /// A long list opens on its choice: the chosen item in the list's middle,
  /// as far as the list scrolls (a select's value near its end shows).
  void _revealChosen() {
    final chosen = _menuItems(widget.focusScope ?? _keys).where(_isChosen);
    final context = chosen.isEmpty ? null : chosen.first.context;
    if (context == null) return;
    Scrollable.ensureVisible(context, alignment: 0.5);
  }

  /// The keys of [ExpressiveMenu]'s list ([_MenuPopup.listKeys]), heard
  /// from the item with focus or from the popup itself.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) return KeyEventResult.ignored;
    final items = _menuItems(_keys);
    if (items.isEmpty) return KeyEventResult.ignored;
    final at = items.indexWhere(
      (item) => item == primary || primary.ancestors.contains(item),
    );
    // Focus on something else the popup holds: its own keys.
    if (at < 0 && primary != _keys) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      final escape = widget.onEscape;
      if (escape == null) return KeyEventResult.ignored;
      escape();
      return KeyEventResult.handled;
    }
    final n = items.length;
    // Where the keys count from: the item with focus, else the chosen one.
    final from = at >= 0 ? at : items.indexWhere(_isChosen);
    final int? to;
    if (key == LogicalKeyboardKey.arrowDown) {
      to = from < 0 ? 0 : (from + 1) % n;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      to = from < 0 ? n - 1 : (from - 1 + n) % n;
    } else if (key == LogicalKeyboardKey.home) {
      to = 0;
    } else if (key == LogicalKeyboardKey.end) {
      to = n - 1;
    } else {
      to = _typeAhead(event, items, from);
      if (to == null) return KeyEventResult.ignored;
    }
    _focusInView(items[to]);
    return KeyEventResult.handled;
  }

  /// The item a typed letter goes to: the next one after [from] its label
  /// starts with; letters typed in a row (within 700 ms) narrow it, one
  /// letter pressed again moves on among the items it starts, and a run no
  /// item starts with starts afresh from its last letter.
  int? _typeAhead(KeyEvent event, List<FocusNode> items, int from) {
    final letter = event.character;
    if (letter == null || letter.length != 1 || letter.trim().isEmpty) {
      return null;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return null;
    }
    final now = DateTime.now();
    _typed =
        (now.difference(_typedAt) > const Duration(milliseconds: 700)
            ? ''
            : _typed) +
        letter.toLowerCase();
    _typedAt = now;
    int? find(String query, int start) {
      for (var i = 0; i < items.length; i++) {
        final j = (start + i) % items.length;
        final label = _tileOf(items[j])?.label.toLowerCase() ?? '';
        if (label.startsWith(query)) return j;
      }
      return null;
    }

    final again = _typed.split('').every((c) => c == _typed[0]);
    final found = again
        ? find(_typed[0], from + 1)
        : find(_typed, math.max(from, 0));
    if (found != null || _typed.length == 1) return found;
    // Letters no item starts with: the last one starts afresh.
    _typed = letter.toLowerCase();
    return find(_typed, from + 1);
  }

  void _closingChanged() => _scale.springTo(
    widget.closing!.value ? MenuBehavior.closedScale : 1,
    widget.spring,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is _MenuRoute && route != _route) {
      _route = route
        .._onClosing = () =>
            _scale.springTo(MenuBehavior.closedScale, widget.spring);
    }
  }

  @override
  void dispose() {
    _route?._onClosing = null;
    widget.closing?.removeListener(_closingChanged);
    _scale.dispose();
    _keys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Directionality(
      textDirection: widget.textDirection,
      // A menu's surface scrolls its own list inside its padding, its
      // container standing still; other content scrolls whole.
      child: widget.listKeys
          ? widget.child
          : SingleChildScrollView(child: widget.child),
    );
    if (widget.listKeys) {
      // One lit row: under a route's popup the pointer takes the focus to
      // the row it moves over; a non-modal popup's field keeps it.
      child = _LeadHost(
        initial: _Lead.keys,
        followsPointer: widget.closing == null,
        child: child,
      );
    }
    final scope = widget.focusScope;
    if (scope != null) child = FocusScope(node: scope, child: child);
    if (widget.listKeys) {
      child = Focus(
        focusNode: _keys,
        // A route's popup takes the keyboard as it opens; a non-modal one
        // leaves it on its field.
        autofocus: widget.closing == null,
        onKeyEvent: _onKey,
        child: child,
      );
    }
    return _popupFrame(context, child);
  }

  Widget _popupFrame(BuildContext context, Widget child) => Semantics(
    scopesRoute: widget.closing == null,
    namesRoute: widget.closing == null,
    explicitChildNodes: true,
    label:
        widget.label ??
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.popupMenuLabel,
    child: Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
          TraversalDirection.down,
        ),
        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
          TraversalDirection.up,
        ),
      },
      child: FocusTraversalGroup(
        child: _MenuPlacement(
          anchor: widget.anchor,
          position: widget.position,
          scale: _scale,
          textDirection: widget.textDirection,
          matchAnchorWidth: widget.matchAnchorWidth,
          maxHeight: widget.maxHeight,
          child: child,
        ),
      ),
    ),
  );
}

/// Places its child against the anchor as Compose's
/// `DropdownMenuPositionProvider` does, and paints it at [scale] around the
/// transform origin `calculateTransformOrigin` gives.
class _MenuPlacement extends SingleChildRenderObjectWidget {
  const _MenuPlacement({
    required this.anchor,
    required this.position,
    required this.scale,
    required this.textDirection,
    required this.matchAnchorWidth,
    required this.maxHeight,
    super.child,
  });

  final Rect anchor;
  final ExpressiveMenuPosition position;
  final Animation<double> scale;
  final TextDirection textDirection;
  final bool matchAnchorWidth;
  final double? maxHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMenuPlacement(anchor, position, scale, textDirection)
        .._matchAnchorWidth = matchAnchorWidth
        .._maxHeight = maxHeight;

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMenuPlacement renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..position = position
      ..scale = scale
      ..textDirection = textDirection
      ..matchAnchorWidth = matchAnchorWidth
      ..maxHeight = maxHeight;
  }
}

class _RenderMenuPlacement extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderMenuPlacement(
    this._anchor,
    this._position,
    this._scale,
    this._textDirection,
  );

  Rect _anchor;
  set anchor(Rect value) {
    if (value == _anchor) return;
    _anchor = value;
    markNeedsLayout();
  }

  ExpressiveMenuPosition _position;
  set position(ExpressiveMenuPosition value) {
    if (value == _position) return;
    _position = value;
    markNeedsLayout();
  }

  Animation<double> _scale;
  set scale(Animation<double> value) {
    if (value == _scale) return;
    if (attached) _scale.removeListener(_scaled);
    _scale = value;
    if (attached) _scale.addListener(_scaled);
    markNeedsPaint();
  }

  // The scale moves what a screen reader reads as each item's box as well
  // as its pixels: without a semantics update the items keep the boxes of
  // the first frame the semantics read, small and off their rows.
  void _scaled() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool _matchAnchorWidth = false;
  set matchAnchorWidth(bool value) {
    if (value == _matchAnchorWidth) return;
    _matchAnchorWidth = value;
    markNeedsLayout();
  }

  double? _maxHeight;
  set maxHeight(double? value) {
    if (value == _maxHeight) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  Offset _offset = Offset.zero;
  Offset _origin = Offset.zero;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scale.addListener(_scaled);
  }

  @override
  void detach() {
    _scale.removeListener(_scaled);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) return;
    const h = MenuBehavior.horizontalMargin;
    const v = MenuBehavior.verticalMargin;
    final a = _anchor;
    final maxWidth = math.max(size.width - h - h, 0.0);
    final maxHeight = math.min(
      math.max(size.height - v - v, 0.0),
      _maxHeight ?? double.infinity,
    );
    double? width;
    if (_matchAnchorWidth) {
      // A list from a field: the field's width, wider only as far as its
      // widest item needs (an item stops at MenuBehavior.itemMaxWidth),
      // never past the window's margins; set before the first frame.
      final least = math.min(a.width, maxWidth);
      width = clampDouble(_widest(child, maxHeight) ?? least, least, maxWidth);
    }
    child.layout(
      BoxConstraints(
        minWidth: width ?? 0,
        maxWidth: width ?? maxWidth,
        maxHeight: maxHeight,
      ),
      parentUsesSize: true,
    );
    final menu = child.size;
    final ltr = _textDirection == TextDirection.ltr;
    // The window-edge candidate on the anchor's side of the window.
    final windowX = a.center.dx < size.width / 2
        ? 0.0
        : size.width - menu.width;
    final windowY = a.center.dy < size.height / 2
        ? 0.0
        : size.height - menu.height;
    final startToAnchorStart = ltr ? a.left : a.right - menu.width;
    final endToAnchorEnd = ltr ? a.right - menu.width : a.left;
    final startToAnchorEnd = ltr ? a.right : a.left - menu.width;
    final endToAnchorStart = ltr ? a.left - menu.width : a.right;
    final (xs, ys) = switch (_position) {
      ExpressiveMenuPosition.below => (
        <double>[startToAnchorStart, endToAnchorEnd, windowX],
        <double>[
          a.bottom,
          a.top - menu.height,
          a.top - menu.height / 2,
          windowY,
        ],
      ),
      ExpressiveMenuPosition.above => (
        <double>[startToAnchorStart, endToAnchorEnd, windowX],
        <double>[
          a.top - menu.height,
          a.bottom,
          a.top - menu.height / 2,
          windowY,
        ],
      ),
      ExpressiveMenuPosition.end => (
        <double>[startToAnchorEnd, endToAnchorStart, windowX],
        <double>[a.top, a.bottom - menu.height, windowY],
      ),
      ExpressiveMenuPosition.start => (
        <double>[endToAnchorStart, startToAnchorEnd, windowX],
        <double>[a.top, a.bottom - menu.height, windowY],
      ),
    };
    final x = _pick(xs, menu.width, size.width, h);
    final y = _pick(ys, menu.height, size.height, v);
    _offset = Offset(x, y);
    final placed = _offset & menu;
    _origin = Offset(
      _pivot(a.left, a.right, placed.left, placed.right) * menu.width,
      _pivot(a.top, a.bottom, placed.top, placed.bottom) * menu.height,
    );
  }

  /// The widest [child]'s items need (its intrinsic width), or null when it
  /// can't say before it lays out: a lazy list under it (a viewport answers
  /// its intrinsic width with nothing), or a builder that answers none.
  static double? _widest(RenderBox child, double height) {
    var says = true;
    void visit(RenderObject node) {
      if (!says) return;
      if (node is RenderViewportBase) {
        says = false;
        return;
      }
      node.visitChildren(visit);
    }

    visit(child);
    if (!says) return null;
    try {
      final widest = child.getMaxIntrinsicWidth(height);
      return widest.isFinite ? widest : null;
    } on Object {
      return null;
    }
  }

  /// `DropdownMenuPositionProvider.positioningLogic` on one axis: the first
  /// candidate inside the margins, else the last one clamped into them (or
  /// centred when the menu does not fit between them).
  static double _pick(
    List<double> candidates,
    double extent,
    double space,
    double margin,
  ) {
    for (final candidate in candidates) {
      if (candidate >= margin && candidate + extent <= space - margin) {
        return candidate;
      }
    }
    if (extent >= space - 2 * margin) return (space - extent) / 2;
    return clampDouble(candidates.last, margin, space - margin - extent);
  }

  /// `calculateTransformOrigin` on one axis: the fraction of the menu at
  /// which it meets its anchor.
  static double _pivot(
    double anchorStart,
    double anchorEnd,
    double menuStart,
    double menuEnd,
  ) {
    if (menuStart >= anchorEnd) return 0;
    if (menuEnd <= anchorStart) return 1;
    final extent = menuEnd - menuStart;
    if (extent == 0) return 0;
    final middle =
        (math.max(anchorStart, menuStart) + math.min(anchorEnd, menuEnd)) / 2;
    return (middle - menuStart) / extent;
  }

  Matrix4 get _transform {
    final s = _scale.value;
    return Matrix4.translationValues(
        _offset.dx + _origin.dx,
        _offset.dy + _origin.dy,
        0,
      )
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-_origin.dx, -_origin.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    layer = context.pushTransform(
      needsCompositing,
      offset,
      _transform,
      (context, offset) => context.paintChild(child, offset),
      oldLayer: layer as TransformLayer?,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transform);
  }
}

// ---------------------------------------------------------------------------
// The anchors.

/// A menu anchored to [child] (Compose's `DropdownMenuPopup` with its
/// anchor): a tap on [child] — or a long press or secondary click, with
/// [trigger] `longPress` — opens [groups] (or one group of [entries])
/// below it. With [builder], the app draws the anchor and opens the menu
/// through the controller it is handed (an overflow icon button, a split
/// button's trailing half, a select's field); [controller] opens it from
/// anywhere.
///
/// [vibrant] menus are a hero moment: they need an [ExpressiveHeroMoment]
/// ancestor (CONTRACT §3).
class ExpressiveMenu extends StatefulWidget {
  /// A menu of [groups] or [entries], anchored to [child] or to what [builder] builds.
  const ExpressiveMenu({
    this.groups,
    this.style,
    this.entries,
    this.child,
    this.builder,
    this.trigger = ExpressiveMenuTrigger.tap,
    this.vibrant = false,
    this.position = ExpressiveMenuPosition.below,
    this.label,
    this.controller,
    this.matchAnchorWidth = false,
    this.maxHeight,
    this.wordsStart,
    this.modal = true,
    super.key,
  }) : assert(
         (groups == null) != (entries == null),
         'groups or entries, one of them',
       ),
       assert(
         (child == null) != (builder == null),
         'child or builder, one of them',
       );

  /// Stateful visual overrides for the menu.
  final ExpressiveComponentThemeData? style;

  /// The menu's groups.
  final List<ExpressiveMenuGroup>? groups;

  /// The menu's entries, as one group.
  final List<ExpressiveMenuEntry>? entries;

  /// The anchor, opening the menu on [trigger].
  final Widget? child;

  /// Builds an anchor that opens the menu itself.
  final Widget Function(BuildContext context, ExpressiveMenuController menu)?
  builder;

  /// What opens the menu from [child].
  final ExpressiveMenuTrigger trigger;

  /// Whether the menu wears the vibrant colours (a hero).
  final bool vibrant;

  /// Where the menu opens against the anchor.
  final ExpressiveMenuPosition position;

  /// What the anchor and the menu are called to assistive technology.
  final String? label;

  /// Opens and closes the menu from the app.
  final ExpressiveMenuController? controller;

  /// Whether the menu is a list from a field: as wide as its anchor, as an
  /// exposed dropdown's is (`exposedDropdownSize(matchAnchorWidth = true)`),
  /// wider only as far as its widest item needs (an item stops at 280dp),
  /// never past the window's margins, from its first frame; else as wide
  /// as its widest item.
  final bool matchAnchorWidth;

  /// The tallest the menu grows before it scrolls (the window's margins
  /// bound it too); null for no limit of its own.
  final double? maxHeight;

  /// Where every item's words start, from the menu's start edge, and an
  /// item's icon centred 28dp before them, as a text field draws its
  /// leading icon: a select's or a combobox's list puts its options' words
  /// where its field's value starts (Flutter's `DropdownMenu` does). Null
  /// keeps the items' own padding.
  final double? wordsStart;

  /// Whether the menu is a modal popup — over a barrier, taking focus, as
  /// `DropdownMenu` is. False raises it as a non-focusable popup
  /// (`PopupProperties(focusable = false)`, a combobox's): no barrier,
  /// focus and typing stay on the anchor, a tap outside the menu and its
  /// anchor closes it, the system back closes it before it reaches the
  /// page (`ExposedDropdownMenuBox`'s `BackHandler`;
  /// [ExpressiveBackHandle]), and [ExpressiveMenuController.focusFirstItem]
  /// hands the keyboard to the items.
  final bool modal;

  /// The menu's groups, however given.
  List<ExpressiveMenuGroup> get resolvedGroups =>
      groups ?? <ExpressiveMenuGroup>[ExpressiveMenuGroup(entries!)];

  @override
  State<ExpressiveMenu> createState() => _ExpressiveMenuState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ExpressiveComponentThemeData?>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<ExpressiveMenuGroup>(
          'groups',
          groups,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<ExpressiveMenuEntry>(
          'entries',
          entries,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<ExpressiveMenuTrigger>(
          'trigger',
          trigger,
          defaultValue: ExpressiveMenuTrigger.tap,
        ),
      )
      ..add(FlagProperty('vibrant', value: vibrant, ifTrue: 'vibrant'))
      ..add(
        EnumProperty<ExpressiveMenuPosition>(
          'position',
          position,
          defaultValue: ExpressiveMenuPosition.below,
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<ExpressiveMenuController?>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'matchAnchorWidth',
          value: matchAnchorWidth,
          ifTrue: 'matchAnchorWidth',
        ),
      )
      ..add(DoubleProperty('maxHeight', maxHeight, defaultValue: null))
      ..add(DoubleProperty('wordsStart', wordsStart, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('modal', modal, defaultValue: true));
  }
}

/// What a menu and a popover share: the anchor that opens and closes the
/// popup, and the controller.
abstract class _MenuAnchorState<W extends StatefulWidget> extends State<W>
    with SingleTickerProviderStateMixin {
  _MenuRoute? _route;
  ExpressiveMenuController? _ownController;

  /// The items' focus scope, for [ExpressiveMenuController.focusFirstItem].
  final FocusScopeNode _itemsScope = FocusScopeNode(
    debugLabel: 'ExpressiveMenu items',
  );

  // The non-modal popup: shown through the root overlay, faded by
  // [_alpha], scaled back when [_closing] is set.
  final OverlayPortalController _portal = OverlayPortalController();
  late final AnimationController _alpha = AnimationController.unbounded(
    vsync: this,
  );
  final ValueNotifier<bool> _closing = ValueNotifier<bool>(false);
  bool _portalOpen = false;
  // A non-modal popup closes on a back, and under a route pushed over its
  // anchor's (or the focus leaving that route).
  late final ExpressiveBackHandle _back = ExpressiveBackHandle(
    onBack: _close,
    closeWhenCovered: true,
  );

  ExpressiveMenuController? get widgetController;
  ExpressiveMenuTrigger get trigger;
  ExpressiveMenuPosition get position;
  String? get label;
  bool get canOpen;
  Widget? get anchorChild;
  Widget Function(BuildContext, ExpressiveMenuController)? get anchorBuilder;
  WidgetBuilder get popupContent;
  bool get vibrant => false;
  bool get matchAnchorWidth => false;
  double? get maxHeight => null;
  bool get modal => true;

  ExpressiveMenuController get _controller =>
      widgetController ?? (_ownController ??= ExpressiveMenuController());

  @override
  void initState() {
    super.initState();
    _controller._anchor = this;
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller._anchor = this;
  }

  @override
  void dispose() {
    _route?.close();
    _portalOpen = false;
    _back.dispose();
    if (_controller._anchor == this) _controller._anchor = null;
    _ownController?.dispose();
    _itemsScope.dispose();
    _alpha.dispose();
    _closing.dispose();
    super.dispose();
  }

  bool get _isOpen => _route != null || _portalOpen;

  void _focusFirstItem() {
    if (!_isOpen) return;
    final context = _itemsScope.context;
    if (context == null) return;
    FocusTraversalGroup.of(context).findFirstFocus(_itemsScope)?.requestFocus();
  }

  /// Whether the popup's chosen item (else its first) takes focus when it
  /// appears: a key opened it, or [ExpressiveMenuController.focusChosenItem]
  /// came before its first frame.
  bool _wantsItem = false;

  /// What had focus as the popup opened: a non-modal popup's field, where
  /// Escape returns it.
  FocusNode? _opener;

  /// Whether the popup is a list the keys walk ([_MenuPopup.listKeys]).
  bool get listKeys => false;

  void _focusChosenItem() {
    final items = _isOpen ? _menuItems(_itemsScope) : const <FocusNode>[];
    if (items.isEmpty) {
      // Not open yet, or not laid out: on its first frame.
      _wantsItem = true;
      return;
    }
    _wantsItem = false;
    _focusInView(_chosenOrFirst(items));
  }

  void _shown() {
    if (_wantsItem) _focusChosenItem();
  }

  /// Escape in a non-modal popup: it closes, and focus goes back to the
  /// field that held it.
  void _escape() {
    final opener = _opener;
    _close();
    if (opener != null && opener.context != null && opener.canRequestFocus) {
      opener.requestFocus();
    }
  }

  Future<void> _open() async {
    if (_isOpen || !canOpen || !mounted) return;
    if (listKeys && _openKeyHeld()) _wantsItem = true;
    _opener = FocusManager.instance.primaryFocus;
    if (vibrant) {
      assert(
        ExpressiveHeroMoment.debugCheck(context, 'ExpressiveMenu (vibrant)'),
      );
    }
    if (!modal) {
      _portalOpen = true;
      _closing.value = false;
      _portal.show();
      unawaited(
        _alpha.springTo(
          1,
          ExpressiveMotion.of(context).spring(MenuBehavior.openAlphaMotion),
        ),
      );
      _controller._changed();
      setState(() {});
      return;
    }
    final done = _showMenuRoute(
      context,
      anchor: null,
      position: position,
      label: label,
      content: popupContent,
      matchAnchorWidth: matchAnchorWidth,
      maxHeight: maxHeight,
      focusScope: _itemsScope,
      listKeys: listKeys,
      onShown: _shown,
      onRoute: (route) => _route = route,
    );
    _controller._changed();
    if (mounted) setState(() {});
    await done;
    _route = null;
    if (!mounted) return;
    _controller._changed();
    setState(() {});
  }

  void _close({bool chosen = false}) {
    _wantsItem = false;
    _route?.close(chosen: chosen);
    if (!_portalOpen) return;
    _portalOpen = false;
    _back.release();
    _closing.value = true;
    final spring = ExpressiveMotion.of(context)
        .spring(MenuBehavior.openAlphaMotion);
    _alpha.springTo(0, spring).whenCompleteOrCancel(() {
      if (!_portalOpen && mounted) _portal.hide();
    });
    _controller._changed();
    setState(() {});
  }

  /// The non-modal popup, placed against the anchor's box in the root
  /// overlay.
  Widget _portalPopup(BuildContext overlayContext) {
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()!
            as RenderBox;
    final box = context.findRenderObject()! as RenderBox;
    final anchor = MatrixUtils.transformRect(
      box.getTransformTo(overlay),
      Offset.zero & box.size,
    );
    return _MenuCloser(
      close: _close,
      child: AnimatedBuilder(
        animation: _alpha,
        builder: (context, child) => Opacity(
          opacity: clampDouble(_alpha.value, 0, 1),
          child: IgnorePointer(ignoring: !_portalOpen, child: child),
        ),
        child: _MenuPopup(
          anchor: anchor,
          position: position,
          label: label,
          spring: ExpressiveMotion.of(context)
              .spring(MenuBehavior.openScaleMotion),
          textDirection: Directionality.of(context),
          matchAnchorWidth: matchAnchorWidth,
          maxHeight: maxHeight,
          focusScope: _itemsScope,
          closing: _closing,
          listKeys: listKeys,
          onShown: _shown,
          onEscape: _escape,
          child: TapRegion(
            groupId: this,
            onTapOutside: (_) => _close(),
            child: Builder(builder: popupContent),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anchor = _buildAnchor(context);
    _back.sync(context, open: !modal && _portalOpen);
    if (modal) return anchor;
    return OverlayPortal(
      overlayLocation: OverlayChildLocation.rootOverlay,
      controller: _portal,
      overlayChildBuilder: _portalPopup,
      child: TapRegion(groupId: this, child: anchor),
    );
  }

  Widget _buildAnchor(BuildContext context) {
    final builder = anchorBuilder;
    if (builder != null) return builder(context, _controller);
    final child = anchorChild!;
    final open = _isOpen;
    if (trigger == ExpressiveMenuTrigger.longPress) {
      // A context menu: a long press opens it, a tap does not, so it says no
      // collapsed state (a screen reader would offer a tap that opens
      // nothing); it says a long press shows a menu.
      final showMenu = Localizations.of<MaterialLocalizations>(
        context,
        MaterialLocalizations,
      )?.showMenuTooltip;
      return Semantics(
        label: label,
        onLongPress: canOpen ? _open : null,
        onLongPressHint: canOpen ? showMenu : null,
        child: GestureDetector(
          excludeFromSemantics: true,
          onLongPress: canOpen ? _open : null,
          onSecondaryTap: canOpen ? _open : null,
          child: child,
        ),
      );
    }
    return Semantics(
      button: true,
      enabled: canOpen,
      expanded: open,
      label: label,
      onTap: canOpen ? _open : null,
      child: FocusableActionDetector(
        enabled: canOpen,
        mouseCursor: canOpen ? SystemMouseCursors.click : MouseCursor.defer,
        // Enter and Space: a browser maps Enter to a button's press alone
        // (ButtonActivateIntent), as ui_core's pressable takes it.
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _open(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => _open(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: canOpen ? _open : null,
          child: child,
        ),
      ),
    );
  }
}

class _ExpressiveMenuState extends _MenuAnchorState<ExpressiveMenu> {
  /// The groups the open popup shows: updated as the app rebuilds the menu.
  late final ValueNotifier<List<ExpressiveMenuGroup>> _groups =
      ValueNotifier<List<ExpressiveMenuGroup>>(widget.resolvedGroups);

  @override
  void didUpdateWidget(ExpressiveMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The open popup is another route's subtree: it follows after the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _groups.value = widget.resolvedGroups;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _groups.dispose();
  }

  @override
  ExpressiveMenuController? get widgetController => widget.controller;

  @override
  bool get listKeys => true;

  @override
  ExpressiveMenuTrigger get trigger => widget.trigger;

  @override
  ExpressiveMenuPosition get position => widget.position;

  @override
  String? get label => widget.label;

  @override
  bool get canOpen =>
      widget.resolvedGroups.any((group) => group.entries.isNotEmpty);

  @override
  bool get vibrant => widget.vibrant;

  @override
  bool get matchAnchorWidth => widget.matchAnchorWidth;

  @override
  double? get maxHeight => widget.maxHeight;

  @override
  bool get modal => widget.modal;

  @override
  Widget? get anchorChild => widget.child;

  @override
  Widget Function(BuildContext, ExpressiveMenuController)? get anchorBuilder =>
      widget.builder;

  @override
  WidgetBuilder get popupContent =>
      (context) => _WordsStart(
        start: widget.wordsStart,
        child: _LiveGroups(
          groups: _groups,
          vibrant: widget.vibrant,
          style: widget.style,
        ),
      );
}

/// [ExpressiveMenu.wordsStart], for the items under it.
class _WordsStart extends InheritedWidget {
  const _WordsStart({required this.start, required super.child});

  final double? start;

  static double? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WordsStart>()?.start;

  @override
  bool updateShouldNotify(_WordsStart oldWidget) => start != oldWidget.start;
}

class _LiveGroups extends StatelessWidget {
  const _LiveGroups({required this.groups, required this.vibrant, this.style});

  final ValueListenable<List<ExpressiveMenuGroup>> groups;
  final bool vibrant;
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<ExpressiveMenuGroup>>(
        valueListenable: groups,
        builder: (context, groups, _) => ExpressiveMenuSurface._popup(
          groups: groups,
          vibrant: vibrant,
          style: style,
        ),
      );
}

// ---------------------------------------------------------------------------
// Popovers.

/// The menu surface holding arbitrary content: a standalone menu group's
/// container (`surfaceContainerLow` on the large corner, elevation 2) with
/// [padding] around [child]. [ExpressivePopover] shows it in a popup; laid
/// out in place it is the surface alone.
class ExpressivePopoverSurface extends StatelessWidget {
  /// A popover surface holding [child] with [padding] around it.
  const ExpressivePopoverSurface({
    required this.child,
    this.style,
    this.padding = const EdgeInsets.all(ExpressiveSpacing.s16),
    super.key,
  });

  /// Stateful visual overrides before the popover theme.
  final ExpressiveComponentThemeData? style;

  /// The content.
  final Widget child;

  /// The padding around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ExpressiveSurface(
      style: style,
      componentStyle: t.popoverTheme,
      padding: padding,
      shape: t.shapes.of(SegmentedMenuTokens.containerShape),
      color: t.colors.role(StandardMenuTokens.containerColor),
      contentColor: t.colors.role(StandardMenuTokens.itemLabelTextColor),
      shadowElevation: MenuTokens.containerElevation,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ExpressiveComponentThemeData?>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsets.all(ExpressiveSpacing.s16),
        ),
      );
  }
}

/// A popover anchored to [child]: [content] on the menu surface
/// ([ExpressivePopoverSurface]), opened and placed the way a menu is — a
/// tap (or, with [trigger] `longPress`, a long press) on [child], or the
/// [builder]'s controller, opens it; a tap outside or the system back
/// closes it, and so does [ExpressivePopover.close] from inside it.
class ExpressivePopover extends StatefulWidget {
  /// A popover showing [content], anchored to [child] or to what [builder] builds.
  const ExpressivePopover({
    required this.content,
    this.style,
    this.child,
    this.builder,
    this.trigger = ExpressiveMenuTrigger.tap,
    this.position = ExpressiveMenuPosition.below,
    this.padding = const EdgeInsets.all(ExpressiveSpacing.s16),
    this.label,
    this.controller,
    super.key,
  }) : assert(
         (child == null) != (builder == null),
         'child or builder, one of them',
       );

  /// Stateful visual overrides for the popover.
  final ExpressiveComponentThemeData? style;

  /// Builds the popover's content.
  final WidgetBuilder content;

  /// The anchor, opening the popover on [trigger].
  final Widget? child;

  /// Builds an anchor that opens the popover itself.
  final Widget Function(BuildContext context, ExpressiveMenuController popover)?
  builder;

  /// How the popover is opened from its anchor.
  final ExpressiveMenuTrigger trigger;

  /// Where the popover opens against its anchor.
  final ExpressiveMenuPosition position;

  /// The padding around the content on the surface.
  final EdgeInsetsGeometry padding;

  /// What the anchor and the popover are called to assistive technology.
  final String? label;

  /// Opens and closes the popover from outside, if given.
  final ExpressiveMenuController? controller;

  /// Closes the popover (or menu) [context] is in, if it is in one.
  static void close(BuildContext context) {
    _closeEnclosingMenu(context);
  }

  @override
  State<ExpressivePopover> createState() => _ExpressivePopoverState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ExpressiveComponentThemeData?>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(ObjectFlagProperty<WidgetBuilder>.has('content', content))
      ..add(
        EnumProperty<ExpressiveMenuTrigger>(
          'trigger',
          trigger,
          defaultValue: ExpressiveMenuTrigger.tap,
        ),
      )
      ..add(
        EnumProperty<ExpressiveMenuPosition>(
          'position',
          position,
          defaultValue: ExpressiveMenuPosition.below,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: const EdgeInsets.all(ExpressiveSpacing.s16),
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<ExpressiveMenuController?>(
          'controller',
          controller,
          defaultValue: null,
        ),
      );
  }
}

/// Opens a popover of [builder]'s content against [anchor], a rectangle in
/// global coordinates, or against [context]'s own box. Resolves when it
/// closes.
///
/// ```dart
/// showExpressivePopover(context, builder: (context) => const Text('Saved to your library'))
/// ```
Future<void> showExpressivePopover(
  BuildContext context, {
  required WidgetBuilder builder,
  ExpressiveComponentThemeData? style,
  Rect? anchor,
  ExpressiveMenuPosition position = ExpressiveMenuPosition.below,
  EdgeInsetsGeometry padding = const EdgeInsets.all(ExpressiveSpacing.s16),
  String? label,
}) async {
  await _showMenuRoute(
    context,
    anchor: anchor,
    position: position,
    label: label,
    content: (context) => ExpressivePopoverSurface(
      padding: padding,
      style: style,
      child: builder(context),
    ),
  );
}

class _ExpressivePopoverState extends _MenuAnchorState<ExpressivePopover> {
  @override
  ExpressiveMenuController? get widgetController => widget.controller;

  @override
  ExpressiveMenuTrigger get trigger => widget.trigger;

  @override
  ExpressiveMenuPosition get position => widget.position;

  @override
  String? get label => widget.label;

  @override
  bool get canOpen => true;

  @override
  Widget? get anchorChild => widget.child;

  @override
  Widget Function(BuildContext, ExpressiveMenuController)? get anchorBuilder =>
      widget.builder;

  @override
  WidgetBuilder get popupContent =>
      (context) => ExpressivePopoverSurface(
        style: widget.style,
        padding: widget.padding,
        child: Builder(builder: widget.content),
      );
}

/// Opens a menu of [groups] (or one group of [entries]) against [anchor], a
/// rectangle in global coordinates, or against [context]'s own box
/// (Material's `showMenu`, Compose's `DropdownMenu`); resolves when it
/// closes. Closed with nothing chosen (Escape, a tap outside, Back), it
/// gives the focus back to what opened it under [context], even a button
/// the pointer pressed, so Enter opens it again.
///
/// ```dart
/// showExpressiveMenu(context, entries: [ExpressiveMenuItem('Rename', onPressed: rename)])
/// ```
Future<void> showExpressiveMenu(
  BuildContext context, {
  Rect? anchor,
  List<ExpressiveMenuGroup>? groups,
  List<ExpressiveMenuEntry>? entries,
  bool vibrant = false,
  ExpressiveComponentThemeData? style,
  ExpressiveMenuPosition position = ExpressiveMenuPosition.below,
  String? label,
  bool matchAnchorWidth = false,
  double? maxHeight,
}) async {
  assert((groups == null) != (entries == null));
  if (vibrant) {
    assert(
      ExpressiveHeroMoment.debugCheck(context, 'ExpressiveMenu (vibrant)'),
    );
  }
  final resolved =
      groups ?? <ExpressiveMenuGroup>[ExpressiveMenuGroup(entries!)];
  final opener = _openerUnder(context);
  final chosen = await _showMenuRoute(
    context,
    anchor: anchor,
    position: position,
    label: label,
    matchAnchorWidth: matchAnchorWidth,
    maxHeight: maxHeight,
    listKeys: true,
    focusItem: _openKeyHeld(),
    content: (context) => ExpressiveMenuSurface._popup(
      groups: resolved,
      vibrant: vibrant,
      style: style,
    ),
  );
  if (chosen == true || opener == null || !context.mounted) return;
  if (!(ModalRoute.isCurrentOf(context) ?? true)) return;
  if (opener.context?.mounted == true && opener.canRequestFocus) {
    opener.requestFocus();
  }
}

/// What opened a menu from [context]: the focus at or under it, else the
/// first node under it that takes the focus (the button a pointer pressed,
/// which a press leaves unfocused).
FocusNode? _openerUnder(BuildContext context) {
  bool under(FocusNode node) {
    final at = node.context;
    if (at == null) return false;
    if (identical(at, context)) return true;
    var found = false;
    at.visitAncestorElements((element) {
      found = identical(element, context);
      return !found;
    });
    return found;
  }

  final primary = FocusManager.instance.primaryFocus;
  if (primary != null && under(primary)) return primary;
  final around =
      Focus.maybeOf(context, createDependency: false) ??
      FocusManager.instance.rootScope;
  for (final node in around.descendants) {
    if (node.canRequestFocus && !node.skipTraversal && under(node)) {
      return node;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// ui_core's lists, painted as menus: the option face and the panel every
// behaviour row here shares (the multi-select's suggestions, the command
// palette's results, the menu bar's menus).
// ---------------------------------------------------------------------------

/// ui_core marks the highlighted option [WidgetState.focused] however it
/// got there: the arrow keys, the pointer passing over it, or simply being
/// first. The ring is the keyboard's alone (Material's focus indicator).
/// Under the pointer, on a touch screen, or while the field that drives the
/// list is not focused ([keyboard] false), the highlight is the hover layer.
Set<WidgetState> _highlightStates(
  Set<WidgetState> states, {
  bool keyboard = true,
}) {
  if (!states.contains(WidgetState.focused)) return states;
  final ring =
      keyboard &&
      !states.contains(WidgetState.hovered) &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
  if (ring) return states;
  return <WidgetState>{...states}
    ..remove(WidgetState.focused)
    ..add(WidgetState.hovered);
}

/// One option on a menu's panel for ui_core's [states] (as they are when
/// [resolved], the menu's one lit row already worked out): a standard menu
/// item (48dp, `labelLarge`, 4dp in from the panel's sides), the state layer
/// in its own shape, the selected item rounded out on
/// `secondaryContainer`, the keyboard's highlight ([WidgetState.focused])
/// ringed inside its edge, the pointer's on the hover layer
/// ([_highlightStates]).
Widget _optionFace(
  BuildContext context, {
  required Set<WidgetState> states,
  required String label,
  String? supporting,
  IconData? icon,
  Widget? trailing,
  bool selectable = true,
  bool keyboard = true,
  bool resolved = false,
}) {
  final shown = resolved
      ? states
      : _highlightStates(states, keyboard: keyboard);
  final t = context.expressiveTheme;
  final enabled = !shown.contains(WidgetState.disabled);
  final selected = shown.contains(WidgetState.selected);
  final colors = _itemColors(
    context,
    selectable: selectable,
    vibrant: false,
    enabled: enabled,
    selected: selected,
  );
  final shape = selectable && selected
      ? t.shapes.of(SegmentedMenuTokens.itemSelectedShape)
      : t.shapes.of(SegmentedMenuTokens.itemShape);
  final glyph =
      icon ?? (selectable && selected ? ExpressiveSymbols.check : null);
  final text = Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: t.type.labelLarge.copyWith(color: colors.text),
  );
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: MenuBehavior.itemInset),
    child: ExpressiveStateFace(
      states: shown,
      shape: shape,
      color: colors.container,
      contentColor: colors.text,
      motion: MenuBehavior.itemShapeMotion,
      // The keys' place is the focus indicator alone, so it never reads as
      // the pointer's fill.
      focusInward: true,
      focusLayer: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ExpressiveSpacing.s48),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ExpressiveSpacing.s12,
          ),
          child: Row(
            children: <Widget>[
              if (glyph != null) ...<Widget>[
                Icon(glyph, size: ExpressiveSpacing.s20, color: colors.leading),
                const SizedBox(width: ExpressiveSpacing.s12),
              ],
              Expanded(
                child: supporting == null
                    ? text
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          text,
                          Text(
                            supporting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.type.bodyMedium.copyWith(
                              color: colors.trailing,
                            ),
                          ),
                        ],
                      ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: ExpressiveSpacing.s12),
                IconTheme.merge(
                  data: IconThemeData(color: colors.trailing),
                  child: DefaultTextStyle.merge(
                    style: t.type.labelLarge.copyWith(color: colors.trailing),
                    child: trailing,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// A menu's panel around [child]: the popover surface (the standard menu
/// container, the large corner, elevation 2), its list 4dp clear of every
/// edge at every density ([_menuInset]). Marked as a face
/// ([DesignKeylineFace]): the kit's surface paints itself, and the checks
/// read the list's width from the panel, not from the overlay box an
/// autocomplete lays it out in.
Widget _panel(Widget child) => DesignKeylineFace(
  child: ExpressivePopoverSurface(
    padding: EdgeInsets.zero,
    child: _menuInset(child),
  ),
);

/// A panel springing in from its anchor: opacity and scale from
/// [presence], the way a menu enters.
Widget _entering(Animation<double> presence, Widget child) => AnimatedBuilder(
  animation: presence,
  child: child,
  builder: (context, child) {
    final value = presence.value.clamp(0.0, 1.0);
    return Opacity(
      opacity: value,
      child: Transform.scale(
        scale: 0.92 + 0.08 * value,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  },
);

// ---------------------------------------------------------------------------
// The multi-select
// ---------------------------------------------------------------------------

/// Several of [options] chosen as input chips in a field that suggests the
/// rest as you type (shadcn's multi-select; ui_core's `DesignTagInput`):
/// the outlined text field's container (2dp `primary` while anything in it
/// has focus), each chosen value an input chip with its remove glyph, the
/// keyboard's chip ringed, and the matching options on a menu's panel under
/// it. The arrows (round past the ends, over a disabled option, which is
/// offered dimmed), Enter and Escape work the suggestions; Backspace on an
/// empty field, or Left at its start, steps onto the chips, and Backspace
/// or Delete removes one. With [onCreate] the typed words make a value of
/// their own.
///
/// With [search] the suggestions are found for what is typed (a server's,
/// say) in place of filtering [options], once typing rests for
/// [debounceDuration]: the panel says it is loading (a menu row with a
/// spinner) while the search runs, and, when it fails, says so with a
/// "Try again" row the arrows reach. [options] still name the chosen values
/// a search has not found.
///
/// ```dart
/// ExpressiveMultiSelect<String>(label: 'Tags', options: const [ExpressiveSelectOption('red', 'Red'), ExpressiveSelectOption('blue', 'Blue')], values: tags, onChanged: setTags)
/// ```
class ExpressiveMultiSelect<T extends Object> extends StatefulWidget {
  /// A multi-select of [options] with [values] chosen.
  const ExpressiveMultiSelect({
    required this.options,
    required this.values,
    required this.onChanged,
    this.label,
    this.hintText,
    this.maxValues,
    this.onCreate,
    this.isError = false,
    this.focusNode,
    this.autofocus = false,
    this.search,
    this.debounceDuration,
    super.key,
  }) : assert(
         maxValues == null || maxValues > 0,
         'maxValues allows at least one value',
       );

  /// What can be chosen (with [search], what names the chosen values).
  final List<ExpressiveSelectOption<T>> options;

  /// Finds the suggestions for what is typed, in place of filtering
  /// [options] (ui_core's `DesignTagInput.search`).
  final FutureOr<Iterable<ExpressiveSelectOption<T>>> Function(String query)?
  search;

  /// How long typing rests before [search] runs; null runs it at every
  /// change.
  final Duration? debounceDuration;

  /// The focus node of the field's text; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the field takes focus when first built.
  final bool autofocus;

  /// What is chosen, in order.
  final List<T> values;

  /// Told the new list; out of use when null.
  final ValueChanged<List<T>>? onChanged;

  /// What the field is called to assistive technology.
  final String? label;

  /// Shown in the field while it is empty.
  final String? hintText;

  /// At most this many values.
  final int? maxValues;

  /// Makes a value of typed words; none can be made when null.
  final T? Function(String text)? onCreate;

  /// Whether the choice is wrong: the error outline.
  final bool isError;

  @override
  State<ExpressiveMultiSelect<T>> createState() =>
      _ExpressiveMultiSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ExpressiveSelectOption<T>>('options', options))
      ..add(
        DiagnosticsProperty<FocusNode?>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>?>.has('onChanged', onChanged),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(IntProperty('maxValues', maxValues, defaultValue: null))
      ..add(
        ObjectFlagProperty<T? Function(String text)?>.has('onCreate', onCreate),
      )
      ..add(FlagProperty('isError', value: isError, ifTrue: 'isError'))
      ..add(
        ObjectFlagProperty<
          FutureOr<Iterable<ExpressiveSelectOption<T>>> Function(String)?
        >.has('search', search),
      )
      ..add(
        DiagnosticsProperty<Duration?>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      );
  }
}

class _ExpressiveMultiSelectState<T extends Object>
    extends State<ExpressiveMultiSelect<T>> {
  FocusNode? _ownNode;

  /// The handed node, else one of its own (disposed with the state; a
  /// handed one is the caller's).
  FocusNode get _node =>
      widget.focusNode ??
      (_ownNode ??= FocusNode(debugLabel: 'ExpressiveMultiSelect'));

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _node.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  /// The options [ExpressiveMultiSelect.search] found, by value: their
  /// labels name the suggestions, and the chips chosen from them.
  final Map<T, ExpressiveSelectOption<T>> _found =
      <T, ExpressiveSelectOption<T>>{};

  ExpressiveSelectOption<T>? _option(T value) {
    for (final option in widget.options) {
      if (option.value == value) return option;
    }
    return _found[value];
  }

  String _label(T value) => _option(value)?.label ?? value.toString();

  /// Whether [value]'s option can be chosen: a disabled one is offered
  /// dimmed, as a select offers it, and passed over.
  bool _enabled(T value) => _option(value)?.enabled ?? true;

  /// [ExpressiveMultiSelect.search] as ui_core's tag input asks it: the
  /// values found, their options kept for their labels.
  FutureOr<Iterable<T>> _search(String query) {
    Iterable<T> keep(Iterable<ExpressiveSelectOption<T>> found) {
      final list = found.toList();
      for (final option in list) {
        _found[option.value] = option;
      }
      return <T>[for (final option in list) option.value];
    }

    final found = widget.search!(query);
    return found is Future<Iterable<ExpressiveSelectOption<T>>>
        ? found.then(keep)
        : keep(found);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final onChanged = widget.onChanged;
    final enabled = onChanged != null;
    // A choice as a select is: from [ExpressiveSelect.wideFrom], at most
    // [ExpressiveSelect.wideMaxWidth] at its column's start.
    return expressiveChoiceWidth(
      context,
      DesignInputGroup(
        focusNode: _node,
        enabled: enabled,
        isError: widget.isError,
        builder: (context, states, child) => ExpressiveFieldFrame(
          states: states,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: ExpressiveSpacing.s8,
            vertical: ExpressiveSpacing.s8,
          ),
          child: child,
        ),
        child: DesignTagInput<T>(
          values: widget.values,
          onChanged: onChanged ?? (_) {},
          focusNode: _node,
          options: <T>[for (final option in widget.options) option.value],
          search: widget.search == null ? null : _search,
          debounceDuration: widget.debounceDuration,
          // The search's states as menu rows on the same panel: a spinner
          // while it runs, and a failure the arrows can reach to try again.
          loadingBuilder: (context) => _optionFace(
            context,
            states: const <WidgetState>{},
            label: DesignLocalizations.of(context).loadingLabel,
            selectable: false,
            trailing: const SizedBox.square(
              dimension: ExpressiveSpacing.s20,
              child: FittedBox(child: ExpressiveCircularProgressIndicator()),
            ),
          ),
          // Pressed as the options above it are (ui_core's pressable), and
          // lit when the arrows reach it.
          errorBuilder: (context, error) => DesignPressable(
            onPressed: error.retry,
            builder: (context, states, _) => _optionFace(
              context,
              states: <WidgetState>{
                ...states,
                if (error.focused) WidgetState.focused,
              },
              // What to do, over what went wrong: a two-line row, wrapping
              // as a narrow panel needs.
              label: DesignLocalizations.of(context).retryButtonLabel,
              supporting: DesignLocalizations.of(context).searchFailedMessage,
              icon: ExpressiveSymbols.refresh,
              selectable: false,
            ),
          ),
          isOptionEnabled: _enabled,
          // One place: the pointer moves ui_core's highlight. After a pointer
          // opens the list, the highlight draws as the hover layer
          // ([_highlightStates]), so a second, the pointer's own, would read
          // as two current options.
          highlightFollowsPointer: true,
          displayStringForOption: _label,
          onCreate: widget.onCreate,
          maxTags: widget.maxValues,
          semanticLabel: widget.label,
          deleteLabel: ExpressiveLocalizations.of(context).removeTag,
          // Its own width (what is typed, or the placeholder), at least
          // 120dp: beside the chips while it fits, under them only when it
          // does not. A field that fills the row always sat on a line of its
          // own, an empty line under the chips.
          fieldBuilder: (context, field) => IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: ExpressiveBareField(
                controller: field.controller,
                focusNode: field.focusNode,
                enabled: enabled,
                hintText: widget.values.isEmpty ? widget.hintText : null,
                semanticLabel: widget.label,
                // Enter adds a value and the field keeps the focus for the
                // next: onEditingComplete, never onSubmitted, whose restart
                // of the text input a browser types into no more.
                onEditingComplete: field.submit,
              ),
            ),
          ),
          layoutBuilder: (context, tags, field) => Wrap(
            spacing: ExpressiveSpacing.s8,
            runSpacing: ExpressiveSpacing.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[...tags, field],
          ),
          tagBuilder: (context, value, tag) => ExpressiveFocusRingBox(
            focused: tag.focused,
            shape: t.shapes.small,
            // A disabled chip keeps its remove glyph, dimmed and inert (M3's
            // disabled input chip): the field keeps its size.
            child: ExpressiveChip(
              _label(value),
              onDeleted: tag.onDeleted,
              enabled: enabled,
            ),
          ),
          optionBuilder: (context, option, states) =>
              _optionFace(context, states: states, label: _label(option)),
          surfaceBuilder: (context, list) => _panel(list),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The hover card
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// The command palette
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// The menu bar
// ---------------------------------------------------------------------------

/// One entry of an [ExpressiveMenuBar]: a menu on the bar (its
/// [children]), an item in a menu, a submenu, or a divider.
@immutable
class ExpressiveMenuBarEntry {
  /// An entry labelled [label].
  const ExpressiveMenuBarEntry(
    this.label, {
    this.onPressed,
    this.children,
    this.shortcut,
    this.checked,
  }) : _divider = false;

  /// A hairline between groups of items.
  const ExpressiveMenuBarEntry.divider()
    : label = '',
      onPressed = null,
      children = null,
      shortcut = null,
      checked = null,
      _divider = true;

  /// What it says.
  final String label;

  /// What choosing it does.
  final VoidCallback? onPressed;

  /// Its menu's entries: a menu on the bar, or a submenu.
  final List<ExpressiveMenuBarEntry>? children;

  /// Its shortcut, after it (`Ctrl S`).
  final String? shortcut;

  /// A check item's state; null for a plain item.
  final bool? checked;

  /// Whether it can be chosen: it has [onPressed] or [children], as a
  /// Flutter menu item without a handler is disabled.
  bool get enabled => !_divider && (onPressed != null || children != null);

  final bool _divider;

  DesignMenuEntry _design() => _divider
      ? const DesignMenuEntry.divider()
      : DesignMenuEntry(
          label: label,
          onPressed: onPressed,
          children: children == null
              ? null
              : <DesignMenuEntry>[
                  for (final child in children!) child._design(),
                ],
          shortcut: shortcut,
          checked: checked,
        );
}

/// A row of menus, a desktop app's File, Edit and View (shadcn's
/// `Menubar`; ui_core's `DesignMenuBar`): each menu's title a text button
/// in `labelLarge` on the full corner (40dp, in a 48dp target), its open
/// menu's title on `secondaryContainer`; each menu a menu's panel of items with their
/// shortcuts, check items checked by a leading check, submenus marked by
/// an arrow. The arrows move along the bar and through a menu, Escape
/// closes it, and a pointer moving along an open bar opens each menu in
/// turn. Material has no menu bar; this is its menus on a bar.
///
/// ```dart
/// ExpressiveMenuBar(menus: [ExpressiveMenuBarEntry('File', children: [ExpressiveMenuBarEntry('New', onPressed: create, shortcut: 'Ctrl N')])])
/// ```
class ExpressiveMenuBar extends StatelessWidget {
  /// A menu bar of [menus].
  const ExpressiveMenuBar({required this.menus, super.key});

  /// The menus, start to end.
  final List<ExpressiveMenuBarEntry> menus;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return DesignMenuBar(
      menus: <DesignMenuEntry>[for (final menu in menus) menu._design()],
      semanticLabel: DesignLocalizations.of(context).menuBarLabel,
      // The titles stand on a bar of their own: the menus' container tone
      // on the full corner, so the row reads as one control.
      barBuilder: (context, items) => ExpressiveSurface(
        color: t.colors.role(MenuTokens.containerColor),
        shape: t.shapes.full,
        padding: const EdgeInsets.all(ExpressiveSpacing.s4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: ExpressiveSpacing.s4,
          children: items,
        ),
      ),
      dividerBuilder: (context) => const _MenuDivider(),
      // One lit row per menu, ui_core's (highlightFollowsPointer): a menu
      // the pointer opened lights none until a key or the pointer moves, a
      // key-opened one its first row.
      surfaceBuilder: (context, info, items) => _entering(
        info.animation,
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MenuBehavior.itemMinWidth,
            maxWidth: MenuBehavior.itemMaxWidth,
            maxHeight: info.maxSize.height,
          ),
          child: _panel(
            SingleChildScrollView(
              primary: false,
              child: IntrinsicWidth(
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
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.bar) {
          final open = states.contains(WidgetState.selected);
          final enabled = !states.contains(WidgetState.disabled);
          final content = !enabled
              ? t.colors.onSurface.withValues(alpha: 0.38)
              : open
              ? t.colors.onSecondaryContainer
              : t.colors.onSurfaceVariant;
          // A text button's 40dp in its 48dp target.
          return ExpressiveMinimumInteractiveSize(
            child: ExpressiveStateFace(
              states: states,
              shape: t.shapes.full,
              color: open
                  ? t.colors.secondaryContainer
                  : t.colors.secondaryContainer.withValues(alpha: 0),
              contentColor: content,
              child: SizedBox(
                height: ExpressiveSpacing.s40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ExpressiveSpacing.s12,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      entry.label,
                      style: t.type.labelLarge.copyWith(color: content),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        final shortcut = entry.shortcut;
        return _optionFace(
          context,
          // A check item's check is its own glyph; an open submenu wears
          // the selected item's container.
          states: <WidgetState>{
            ...states,
            if (entry.checked ?? false) WidgetState.selected,
          },
          resolved: true,
          label: entry.label,
          selectable: entry.checked != null || entry.isSubmenu,
          icon: entry.checked == null
              ? null
              : entry.checked!
              ? ExpressiveSymbols.check
              : null,
          trailing: entry.isSubmenu
              ? Icon(
                  Directionality.of(context) == TextDirection.ltr
                      ? ExpressiveSymbols.chevronRight
                      : ExpressiveSymbols.chevronLeft,
                  size: ExpressiveSpacing.s20,
                )
              : shortcut == null
              ? null
              : expressiveFaceLabel(
                  // Its keys on the row's middle, by their capitals, in the
                  // order they are pressed in either direction: right to
                  // left, "⌘ N" would otherwise read "N ⌘".
                  Text(
                    shortcut,
                    style: t.type.labelMedium,
                    textDirection: TextDirection.ltr,
                  ),
                ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<ExpressiveMenuBarEntry>('menus', menus));
  }
}
