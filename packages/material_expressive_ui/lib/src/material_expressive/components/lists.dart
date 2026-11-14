/// Lists: the expressive list item (1–3 lines, slots, select, toggle,
/// expand, drag) and the segmented section (corners 4 inner and 16 outer, 16
/// selected), the reorderable list, swipe-to-dismiss and swipe actions, the
/// lazy grid, the accordion (an expandable item), dividers and section
/// headers (CONTRACT §4.1 `list-row`, `list-section`, `grid`, `accordion`,
/// `divider`, `section-header`). Owner: w3-lists.
///
/// Ports of Compose material3 1.5.0-alpha29's `ListItem.kt` (the
/// interactive `ListItem` and `SegmentedListItem` overloads, their
/// `InteractiveListItemMeasurePolicy`, flag
/// `isExpressiveListItemHeightBasedOnTextLinesFixEnabled` on, the jar's
/// default), `ListItemDefaults.kt` (colours, shapes, `segmentedShapes`,
/// `SegmentedGap`, the adaptive vertical alignment), `Divider.kt` and
/// `SwipeToDismissBox.kt`: geometry, colours and shapes from the generated
/// `ListTokens`, `ReorderListTokens`, `ExpandedListTokens`,
/// `RevealListTokens` and `DividerTokens`, springs on the motion keys
/// `ListItemBehavior` and `SwipeToDismissBoxBehavior` carry.
///
/// Row grammar is one component with slots: every row is an
/// [ExpressiveListTile] (headline, overline, supporting, leading, trailing);
/// a section, a reorderable list or an accordion hands its items their
/// position (segment shapes, the section's container colour, dragged) through
/// the tree, so an item never names its place.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/styled_content.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/divider_tokens.g.dart';
import '../internal/tokens/expanded_list_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/list_tokens.g.dart';
import '../internal/tokens/reorder_list_tokens.g.dart';
import '../internal/tokens/reveal_list_tokens.g.dart';
import '../internal/tokens/small_icon_button_tokens.g.dart';
import '../internal/tokens/x_small_icon_button_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Where an item sits
// ---------------------------------------------------------------------------

/// An item's place in a segmented group: Compose's `segmentedShapes(index,
/// count)` inputs, the group's container colour, and a shape a composite
/// (the accordion) imposes on its header.
class _Segment extends InheritedWidget {
  const _Segment({
    required super.child,
    this.index,
    this.count,
    this.containerColor,
    this.corners,
  });

  /// The item's index in its group; null when not segmented.
  final int? index;

  /// The group's size; null when not segmented.
  final int? count;

  /// The group's container colour (Compose's `segmentedColors(
  /// containerColor = …)`); the token colour when null.
  final Color? containerColor;

  /// A resting shape imposed on the item (an expanded accordion's header).
  final ExpressiveCornerBorder? corners;

  bool get segmented => index != null && count != null;

  static _Segment? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Segment>();

  @override
  bool updateShouldNotify(_Segment oldWidget) =>
      index != oldWidget.index ||
      count != oldWidget.count ||
      containerColor != oldWidget.containerColor ||
      corners != oldWidget.corners;
}

/// Marks an item as the one being dragged (a reorderable list's proxy).
class _Dragged extends InheritedWidget {
  const _Dragged({required super.child});

  static bool at(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Dragged>() != null;

  @override
  bool updateShouldNotify(_Dragged oldWidget) => false;
}

/// Compose's `ListItemDefaults.segmentedShapes(index, count)`: the item's
/// base shape (`ItemContainerExpressiveShape`, 4dp) with the group's outer
/// corners (`ListTokens.ContainerShape`, 16dp) on the first item's top, the
/// last item's bottom, or all four for a group of one.
ExpressiveCornerBorder _segmentShape(ExpressiveShapes s, int index, int count) {
  final base = s.of(ListTokens.itemContainerExpressiveShape);
  final outer = s.of(ListTokens.containerShape);
  final first = index == 0;
  final last = index == count - 1;
  return ExpressiveCornerBorder(
    topStart: first ? outer.topStart : base.topStart,
    topEnd: first ? outer.topEnd : base.topEnd,
    bottomEnd: last ? outer.bottomEnd : base.bottomEnd,
    bottomStart: last ? outer.bottomStart : base.bottomStart,
  );
}

/// The shape a row rests in where [context] stands: an imposed shape, its
/// segment's, or the item's base shape.
ExpressiveCornerBorder _restingShape(BuildContext context) {
  final s = context.expressiveTheme.shapes;
  final segment = _Segment.of(context);
  return segment?.corners ??
      (segment != null && segment.segmented
          ? _segmentShape(s, segment.index!, segment.count!)
          : s.of(ListTokens.itemContainerExpressiveShape));
}

// ---------------------------------------------------------------------------
// Colours
// ---------------------------------------------------------------------------

/// One state's colours (Compose's `ListItemColors` resolved for enabled,
/// selected and dragged): what the item springs between on
/// `ListItemBehavior.colorMotion`.
@immutable
class _Palette {
  const _Palette({
    required this.container,
    required this.content,
    required this.leading,
    required this.trailing,
    required this.overline,
    required this.supporting,
  });

  /// `ListItemColors.containerColor(enabled, selected, dragged)` and the
  /// rest, from `ListItemDefaults.colors()` / `segmentedColors()` (the two
  /// differ only in their container token, both `surface`).
  factory _Palette.of(
    BuildContext context, {
    required bool enabled,
    required bool selected,
    required bool dragged,
    required bool segmented,
    Color? container,
  }) {
    final c = context.expressiveTheme.colors;
    Color faded(ExpressiveColorRole role, double opacity) =>
        c.role(role).withValues(alpha: opacity);
    final base =
        container ??
        c.role(
          segmented
              ? ListTokens.itemSegmentedContainerColor
              : ListTokens.itemContainerColor,
        );
    if (!enabled) {
      return _Palette(
        container: base,
        content: faded(
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
        overline: faded(
          ListTokens.itemDisabledOverlineColor,
          ListTokens.itemDisabledOverlineOpacity,
        ),
        supporting: faded(
          ListTokens.itemDisabledSupportingTextColor,
          ListTokens.itemDisabledSupportingTextOpacity,
        ),
      );
    }
    if (dragged) {
      return _Palette(
        container: c.role(ReorderListTokens.itemContainerColor),
        content: c.role(ReorderListTokens.itemLabelTextColor),
        leading: c.role(ReorderListTokens.itemLeadingIconColor),
        trailing: c.role(ReorderListTokens.itemTrailingIconColor),
        overline: c.role(ReorderListTokens.itemOverlineColor),
        supporting: c.role(ReorderListTokens.itemSupportingTextColor),
      );
    }
    if (selected) {
      return _Palette(
        container: c.role(ListTokens.itemSelectedContainerColor),
        content: c.role(ListTokens.itemSelectedLabelTextColor),
        leading: c.role(ListTokens.itemSelectedLeadingIconColor),
        trailing: c.role(ListTokens.itemSelectedTrailingIconColor),
        overline: c.role(ListTokens.itemSelectedOverlineColor),
        supporting: c.role(ListTokens.itemSelectedSupportingTextColor),
      );
    }
    return _Palette(
      container: base,
      content: c.role(ListTokens.itemLabelTextColor),
      leading: c.role(ListTokens.itemLeadingIconColor),
      trailing: c.role(ListTokens.itemTrailingIconColor),
      overline: c.role(ListTokens.itemOverlineColor),
      supporting: c.role(ListTokens.itemSupportingTextColor),
    );
  }

  final Color container;
  final Color content;
  final Color leading;
  final Color trailing;
  final Color overline;
  final Color supporting;

  /// This with [theme]'s slots for [states] over it: the content slot
  /// paints every word and icon; the container slot only when [ownContainer]
  /// is false (a row's own `containerColor` wins).
  _Palette themed(
    ExpressiveComponentThemeData theme,
    Set<WidgetState> states, {
    required bool ownContainer,
  }) {
    if (theme.isEmpty) return this;
    Color on(Color fallback) => ExpressiveComponentThemeData.resolve(
      theme.foregroundColor,
      states,
      fallback,
    );
    return _Palette(
      container: ownContainer
          ? container
          : ExpressiveComponentThemeData.resolve(
              theme.backgroundColor,
              states,
              container,
            ),
      content: on(content),
      leading: on(leading),
      trailing: on(trailing),
      overline: on(overline),
      supporting: on(supporting),
    );
  }

  static _Palette lerp(_Palette a, _Palette b, double t) => _Palette(
    container: Color.lerp(a.container, b.container, t)!,
    content: Color.lerp(a.content, b.content, t)!,
    leading: Color.lerp(a.leading, b.leading, t)!,
    trailing: Color.lerp(a.trailing, b.trailing, t)!,
    overline: Color.lerp(a.overline, b.overline, t)!,
    supporting: Color.lerp(a.supporting, b.supporting, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is _Palette &&
      other.container == container &&
      other.content == content &&
      other.leading == leading &&
      other.trailing == trailing &&
      other.overline == overline &&
      other.supporting == supporting;

  @override
  int get hashCode =>
      Object.hash(container, content, leading, trailing, overline, supporting);
}

// ---------------------------------------------------------------------------
// List item
// ---------------------------------------------------------------------------

enum _ItemKind { click, select, toggle }

/// A Material 3 Expressive list item (Compose's interactive `ListItem`, and
/// `SegmentedListItem` inside an [ExpressiveListSection]): a [headline]
/// with an optional [overline] above and [supporting] text below, between
/// [leading] content (an icon, avatar, image or checkbox) and [trailing]
/// content (text, an icon, a switch or a checkbox).
///
/// One line is 56dp tall, two 72dp, three 88dp (overline and supporting
/// both, or supporting that wraps); content centres until the item is
/// taller than the midpoint of two and three lines, then tops. Headline in
/// `bodyLarge`, supporting in `bodyMedium`, overline and trailing text in
/// `labelSmall`, leading text in `titleMedium`; icons 24dp.
///
/// With [onPressed] it is a button: state layers, the ripple, and corners that
/// spring from 4dp to 16dp pressed or focused (12dp hovered). Without it
/// the item is static. [ExpressiveListTile.selectable] is one of a set
/// (radio semantics) and [ExpressiveListTile.toggleable] a check (checkbox
/// semantics): selected, both fill with `secondaryContainer` and round to
/// 16dp. Dragged (in an [ExpressiveReorderableListView], or [dragged]) it lifts
/// to level 4 in `tertiaryContainer`.
///
/// ```dart
/// ExpressiveListTile(title: Text('Wi-Fi'), subtitle: Text('Home network'), leading: Icon(ExpressiveSymbols.wifi), onTap: openWifi)
/// ```
class ExpressiveListTile extends StatefulWidget {
  /// A clickable item (with [onTap] or [onLongPress]) or a static one.
  const ExpressiveListTile({
    required this.title,
    this.style,
    this.overline,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.dragged = false,
    this.expanded,
    this.tileColor,
    this.contentPadding,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _kind = _ItemKind.click,
       selected = false,
       onChanged = null;

  /// One item of a mutually exclusive set (Compose's `ListItem(selected,
  /// onClick)`): selected colours and shape, radio semantics.
  const ExpressiveListTile.selectable({
    required this.title,
    this.style,
    required this.selected,
    required this.onTap,
    this.overline,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onLongPress,
    this.enabled = true,
    this.dragged = false,
    this.tileColor,
    this.contentPadding,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _kind = _ItemKind.select,
       expanded = null,
       onChanged = null;

  /// An item that is checked or not (Compose's `ListItem(checked,
  /// onCheckedChange)`): [onChanged] is told the next value; selected
  /// colours and shape while checked, checkbox semantics.
  const ExpressiveListTile.toggleable({
    required this.title,
    this.style,
    required bool value,
    required this.onChanged,
    this.overline,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onLongPress,
    this.enabled = true,
    this.dragged = false,
    this.tileColor,
    this.contentPadding,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _kind = _ItemKind.toggle,
       selected = value,
       onTap = null,
       expanded = null;

  final _ItemKind _kind;

  /// Stateful visual overrides before the list-tile theme.
  final ExpressiveComponentThemeData? style;

  /// The main line (Compose's `content`): usually a `Text`.
  final Widget title;

  /// A line above the headline.
  final Widget? overline;

  /// Text below the headline; the item grows to three lines when it wraps.
  final Widget? subtitle;

  /// Content before the text: an icon, avatar, image or checkbox.
  final Widget? leading;

  /// Content after the text: supporting text, an icon, a switch.
  final Widget? trailing;

  /// What a tap does; null (and no [onLongPress]) makes a static item.
  final VoidCallback? onTap;

  /// What a long press does.
  final VoidCallback? onLongPress;

  /// A toggleable item's handler: told the next checked value.
  final ValueChanged<bool>? onChanged;

  /// Whether the item is selected (checked, for a toggleable one).
  final bool selected;

  /// Whether the item takes input; disabled colours when false.
  final bool enabled;

  /// Whether the item is being dragged: `tertiaryContainer`, level 4, the
  /// dragged shape. A reorderable list sets it on its own.
  final bool dragged;

  /// For an expandable item (an accordion's header): whether its content is
  /// shown, announced as expanded or collapsed. Null for any other item.
  final bool? expanded;

  /// The container colour at rest (Compose's `colors(containerColor =)`);
  /// the section's, else `surface`, when null.
  final Color? tileColor;

  /// The padding around the content (`ListItemDefaults.ContentPadding`:
  /// 16dp at the sides, 10dp above and below, when null).
  final EdgeInsetsGeometry? contentPadding;

  /// What a screen reader says, over the content's own text.
  final String? semanticLabel;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// Compose's `ListItemDefaults.ContentPadding`.
  static const EdgeInsetsDirectional defaultContentPadding =
      EdgeInsetsDirectional.fromSTEB(
        ListTokens.itemLeadingSpace,
        ListTokens.itemTopSpace,
        ListTokens.itemTrailingSpace,
        ListTokens.itemBottomSpace,
      );

  @override
  State<ExpressiveListTile> createState() => _ExpressiveListTileState();
}

class _ExpressiveListTileState extends State<ExpressiveListTile> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void initState() {
    super.initState();
    _states.addListener(_statesChanged);
  }

  @override
  void dispose() {
    _states.removeListener(_statesChanged);
    _states.dispose();
    super.dispose();
  }

  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  /// Only focus and hover reshape the item here (the pressable settles
  /// pressed and selected itself, and marks disabled while it builds).
  void _statesChanged() {
    final focused = _states.value.contains(WidgetState.focused);
    final hovered = _states.value.contains(WidgetState.hovered);
    final pressed = _states.value.contains(WidgetState.pressed);
    if (!mounted ||
        (focused == _focused && hovered == _hovered && pressed == _pressed)) {
      return;
    }
    setState(() {
      _focused = focused;
      _hovered = hovered;
      _pressed = pressed;
    });
  }

  VoidCallback? get _onPressed => switch (widget._kind) {
    _ItemKind.toggle =>
      widget.onChanged == null
          ? null
          : () => widget.onChanged!(!widget.selected),
    _ => widget.onTap,
  };

  bool get _interactive => _onPressed != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final s = t.shapes;
    final segment = _Segment.of(context);
    final segmented = segment?.segmented ?? false;
    final dragged = widget.dragged || _Dragged.at(context);
    final enabled = widget.enabled;
    final ownContainer = widget.tileColor ?? segment?.containerColor;
    final component = ownContainer == null
        ? t.listTileTheme
        : t.listTileTheme.copyWith(
            // The row supplies its native state palette (including selected and
            // dragged fills); a per-widget style can still override it.
            backgroundColor: const WidgetStatePropertyAll(null),
          );
    final styled = component.merge(widget.style);
    final states = <WidgetState>{
      ...expressiveComponentStates(enabled: enabled, selected: widget.selected),
      if (dragged) WidgetState.dragged,
      if (_focused) WidgetState.focused,
      if (_hovered) WidgetState.hovered,
      if (_pressed) WidgetState.pressed,
    };
    final customShape = styled.shape?.resolve(states);

    final customText = styled.textStyle?.resolve(states);
    final customIconSize = styled.iconSize?.resolve(states);
    final palette = _Palette.of(
      context,
      enabled: enabled,
      selected: widget.selected,
      dragged: dragged,
      segmented: segmented,
      container: ownContainer,
    ).themed(styled, states, ownContainer: false);

    // ListItemShapes.shapeForInteraction: pressed, then dragged, then
    // selected, then focused, then hovered, then the base shape (the
    // pressable resolves pressed and selected; the rest is settled here).
    final base =
        segment?.corners ??
        (segmented
            ? _segmentShape(s, segment!.index!, segment.count!)
            : s.of(ListTokens.itemContainerExpressiveShape));
    final draggedShape = s.of(ReorderListTokens.itemShape);
    final rest = dragged
        ? draggedShape
        : _focused
        ? s.of(ListTokens.itemFocusedContainerExpressiveShape)
        : _hovered
        ? s.of(ListTokens.itemHoveredContainerExpressiveShape)
        : base;
    final shapes = ExpressivePressShapes(
      shape: rest,
      pressed: s.of(ListTokens.itemPressedContainerExpressiveShape),
      selected: dragged
          ? draggedShape
          : s.of(ListTokens.itemSelectedContainerExpressiveShape),
    );
    final outline = styled.outline?.resolve(states);
    final side =
        styled.side?.resolve(states) ??
        BorderSide.none.copyWith(
          color: outline,
          style: outline == null ? null : BorderStyle.solid,
        );
    final inset =
        customShape != null ||
            styled.side?.resolve(states) != null ||
            outline != null
        ? (customShape ??
                  shapes.resolve(pressed: _pressed, selected: widget.selected))
              .copyWith(side: side)
              .dimensions
              .resolve(Directionality.of(context))
        : EdgeInsets.zero;
    const elevation = ExpressiveStateElevation(
      rest: ListTokens.itemContainerElevation,
      dragged: ListTokens.itemDraggedContainerElevation,
    );

    final direction = Directionality.of(context);
    // Density moves the row's height, never where its content starts: the
    // side insets are the list's keyline, shared with its section header,
    // its dividers and the page around it.
    final own = ExpressiveListTile.defaultContentPadding.resolve(direction);
    final padding =
        (styled.padding?.resolve(states)?.resolve(direction) ??
            widget.contentPadding?.resolve(direction) ??
            t.density.padding(own).copyWith(left: own.left, right: own.right)) +
        inset;
    final minimum = styled.minimumSize?.resolve(states);
    final textScaler = MediaQuery.textScalerOf(context);

    Widget content(_Palette p) => ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimum?.width ?? 0,
        minHeight: minimum?.height ?? 0,
      ),
      child: Padding(
        padding: padding,
        child: _ItemLayout(
          verticalPadding: padding.vertical,
          heightAdjustment: t.density.vertical * 4,
          multilineHeight: textScaler.scale(
            ListItemBehavior.supportingMultilineHeight,
          ),
          textDirection: direction,
          leading: widget.leading == null
              ? null
              : _decorate(
                  context,
                  color: p.leading,
                  type: ListTokens.itemLeadingAvatarLabelFont,
                  iconSize: customIconSize ?? ListTokens.itemLeadingIconSize,
                  textStyle: customText,
                  padding: const EdgeInsetsDirectional.only(
                    end: ListTokens.itemBetweenSpace,
                  ),
                  child: widget.leading!,
                ),
          trailing: widget.trailing == null
              ? null
              : _decorate(
                  context,
                  color: p.trailing,
                  type: ListTokens.itemTrailingSupportingTextFont,
                  iconSize: customIconSize ?? ListTokens.itemTrailingIconSize,
                  textStyle: customText,
                  padding: const EdgeInsetsDirectional.only(
                    start: ListTokens.itemBetweenSpace,
                  ),
                  child: widget.trailing!,
                ),
          overline: widget.overline == null
              ? null
              : _text(
                  context,
                  p.overline,
                  ListTokens.itemOverlineFont,
                  widget.overline!,
                  textStyle: customText,
                ),
          // A one-line row's title sits on its face's middle: centred by
          // its capitals. With an overline or a supporting line it is one
          // of a stack, placed, not centred.
          headline: widget.overline == null && widget.subtitle == null
              ? expressiveFaceLabel(
                  _text(
                    context,
                    p.content,
                    ListTokens.itemLabelTextFont,
                    widget.title,
                    textStyle: customText,
                  ),
                )
              : _text(
                  context,
                  p.content,
                  ListTokens.itemLabelTextFont,
                  widget.title,
                  textStyle: customText,
                ),
          supporting: widget.subtitle == null
              ? null
              : _text(
                  context,
                  p.supporting,
                  ListTokens.itemSupportingTextFont,
                  widget.subtitle!,
                  textStyle: customText,
                ),
        ),
      ),
    );

    return ExpressiveSpringTween<_Palette>(
      value: palette,
      motion: ListItemBehavior.colorMotion,
      lerp: _Palette.lerp,
      builder: (context, p, _) {
        if (_interactive) {
          return ExpressivePressable(
            style: widget.style,
            componentStyle: component,
            shapes: shapes,
            motion: ListItemBehavior.shapeMotion,
            // Rows stack flush: the ring stands inside the row, as
            // Material's web list items draw it, where the next row's
            // container cannot cover it.
            focusInward: true,
            color: p.container,
            contentColor: p.content,
            selected: widget.selected,
            dragged: dragged,
            role: switch (widget._kind) {
              _ItemKind.click => ExpressivePressRole.button,
              _ItemKind.select => ExpressivePressRole.radio,
              _ItemKind.toggle => ExpressivePressRole.checkbox,
            },
            elevation: elevation,
            elevationMotion: ListItemBehavior.elevationMotion,
            statesController: _states,
            semanticLabel: widget.semanticLabel,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onPressed: enabled ? _onPressed : null,
            onLongPress: enabled ? widget.onLongPress : null,
            child: Semantics(expanded: widget.expanded, child: content(p)),
          );
        }
        return _StaticItem(
          shape: customShape ?? (dragged ? draggedShape : base),
          side: side,
          overlay: styled.overlayColor?.resolve(states),
          color: p.container,
          contentColor: p.content,
          dragged: dragged,
          elevation: elevation,
          enabled: enabled,
          expanded: widget.expanded,
          semanticLabel: widget.semanticLabel,
          child: content(p),
        );
      },
    );
  }

  /// Compose's `LeadingDecorator`/`TrailingDecorator`: the 12dp between
  /// space, the slot's colour and text style, and touch targets shrunk to
  /// their drawn size (Compose lowers `LocalMinimumInteractiveComponentSize`
  /// by the padding around the slot, 48 − 28 = 20dp, below every control's
  /// drawn size).
  static Widget _decorate(
    BuildContext context, {
    required Color color,
    required ExpressiveTypeKey type,
    required double iconSize,
    TextStyle? textStyle,
    required EdgeInsetsDirectional padding,
    required Widget child,
  }) => Padding(
    padding: padding,
    child: ExpressiveShrinkTapTargets(
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: iconSize),
        child: DefaultTextStyle.merge(
          style: context.expressiveTheme.type
              .of(type)
              .merge(textStyle)
              .copyWith(color: color),
          child: child,
        ),
      ),
    ),
  );

  static Widget _text(
    BuildContext context,
    Color color,
    ExpressiveTypeKey type,
    Widget child, {
    TextStyle? textStyle,
  }) => DefaultTextStyle.merge(
    style: context.expressiveTheme.type
        .of(type)
        .merge(textStyle)
        .copyWith(color: color),
    child: IconTheme.merge(
      data: IconThemeData(color: color),
      child: child,
    ),
  );
}

/// A list item with no click (Compose's `ListItem` without `onClick`): its
/// container and shape, the dragged lift and state layer, merged
/// semantics (a control inside keeps its own), and no touch target.
class _StaticItem extends StatelessWidget {
  const _StaticItem({
    required this.shape,
    required this.side,
    required this.overlay,
    required this.color,
    required this.contentColor,
    required this.dragged,
    required this.elevation,
    required this.enabled,
    required this.expanded,
    required this.semanticLabel,
    required this.child,
  });

  final OutlinedBorder shape;
  final BorderSide side;
  final Color? overlay;
  final Color color;
  final Color contentColor;
  final bool dragged;
  final ExpressiveStateElevation elevation;
  final bool enabled;
  final bool? expanded;
  final String? semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layers = context.expressiveTheme.states;
    final dragLayer = dragged
        ? layers.layerOf(contentColor, const <WidgetState>{WidgetState.dragged})
        : null;
    return ExpressiveSemanticsGroup(
      child: Semantics(
        enabled: enabled ? null : false,
        expanded: expanded,
        label: semanticLabel,
        child: ExpressiveSpringShape(
          value: shape,
          motion: ListItemBehavior.shapeMotion,
          builder: (context, shape, _) => ExpressiveSurface(
            shape: shape,
            side: side,
            color: Color.alphaBlend(overlay ?? expressiveTransparent, color),
            contentColor: contentColor,
            shadowElevation: elevation.resolve(<WidgetState>{
              if (dragged) WidgetState.dragged,
            }),
            elevationMotion: ListItemBehavior.elevationMotion,
            child: dragLayer == null
                ? child
                : Stack(
                    children: <Widget>[
                      child,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(color: dragLayer),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The item's layout: InteractiveListItemMeasurePolicy
// ---------------------------------------------------------------------------

enum _Slot { leading, trailing, overline, headline, supporting }

class _ItemLayout
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _ItemLayout({
    required this.verticalPadding,
    this.heightAdjustment = 0,
    required this.multilineHeight,
    required this.textDirection,
    required this.headline,
    this.leading,
    this.trailing,
    this.overline,
    this.supporting,
  });

  final double verticalPadding;
  final double heightAdjustment;
  final double multilineHeight;
  final TextDirection textDirection;
  final Widget? leading;
  final Widget? trailing;
  final Widget? overline;
  final Widget headline;
  final Widget? supporting;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.leading => leading,
    _Slot.trailing => trailing,
    _Slot.overline => overline,
    _Slot.headline => headline,
    _Slot.supporting => supporting,
  };

  @override
  _RenderItemLayout createRenderObject(BuildContext context) =>
      _RenderItemLayout(
        verticalPadding: verticalPadding,
        heightAdjustment: heightAdjustment,
        multilineHeight: multilineHeight,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderItemLayout renderObject,
  ) {
    renderObject
      ..verticalPadding = verticalPadding
      ..heightAdjustment = heightAdjustment
      ..multilineHeight = multilineHeight
      ..textDirection = textDirection;
  }
}

/// How a measure pass sizes a child: laying it out, or asking its dry size.
typedef _Measure = Size Function(RenderBox child, BoxConstraints constraints);

class _RenderItemLayout extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderItemLayout({
    required this._verticalPadding,
    required this._heightAdjustment,
    required this._multilineHeight,
    required this._textDirection,
  });

  double _heightAdjustment;
  set heightAdjustment(double value) {
    if (value == _heightAdjustment) return;
    _heightAdjustment = value;
    markNeedsLayout();
  }

  double _verticalPadding;
  set verticalPadding(double value) {
    if (value == _verticalPadding) return;
    _verticalPadding = value;
    markNeedsLayout();
  }

  double _multilineHeight;
  set multilineHeight(double value) {
    if (value == _multilineHeight) return;
    _multilineHeight = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _leading => childForSlot(_Slot.leading);
  RenderBox? get _trailing => childForSlot(_Slot.trailing);
  RenderBox? get _overline => childForSlot(_Slot.overline);
  RenderBox? get _headline => childForSlot(_Slot.headline);
  RenderBox? get _supporting => childForSlot(_Slot.supporting);

  @override
  Iterable<RenderBox> get children => <RenderBox?>[
    _leading,
    _trailing,
    _overline,
    _headline,
    _supporting,
  ].whereType<RenderBox>();

  /// `ListItemType`'s minimum container height for the lines present.
  static double _containerHeight(bool overline, bool supporting, bool multi) {
    if ((overline && supporting) || multi) {
      return ListTokens.itemThreeLineContainerHeight;
    }
    if (overline || supporting) return ListTokens.itemTwoLineContainerHeight;
    return ListTokens.itemOneLineContainerHeight;
  }

  /// `InteractiveListVerticalAlignmentBreakpoint`: how tall the content box
  /// must be before content tops instead of centring.
  static double get _breakpoint =>
      (ListTokens.itemThreeLineContainerHeight +
              ListTokens.itemTwoLineContainerHeight) *
          0.5 -
      ListTokens.itemTopSpace -
      ListTokens.itemBottomSpace;

  /// `ListItemDefaults.verticalAlignment()`.
  static double _align(double size, double space) =>
      space < _breakpoint ? (space - size) * 0.5 : 0;

  ({
    Size size,
    Size leading,
    Size trailing,
    Size overline,
    Size headline,
    Size supporting,
  })
  _measure(BoxConstraints constraints, _Measure measure) {
    final loose = BoxConstraints(
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );
    BoxConstraints offset(double x, double y) => BoxConstraints(
      maxWidth: math.max(0, loose.maxWidth - x),
      maxHeight: math.max(0, loose.maxHeight - y),
    );
    Size sized(RenderBox? child, BoxConstraints c) =>
        child == null ? Size.zero : measure(child, c);

    var x = 0.0;
    var y = 0.0;
    final leading = sized(_leading, loose);
    x += leading.width;
    final trailing = sized(_trailing, offset(x, 0));
    x += trailing.width;
    final overline = sized(_overline, offset(x, 0));
    y += overline.height;
    final headline = sized(_headline, offset(x, y));
    y += headline.height;
    final supporting = sized(_supporting, offset(x, y));

    final multi = _supporting != null && supporting.height > _multilineHeight;
    final main = overline.height + headline.height + supporting.height;
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : leading.width +
              math.max(
                headline.width,
                math.max(overline.width, supporting.width),
              ) +
              trailing.width;
    final calculated = math.max(
      leading.height,
      math.max(main, trailing.height),
    );
    final defaultMin = math.max(
      0.0,
      _containerHeight(_overline != null, _supporting != null, multi) +
          _heightAdjustment -
          _verticalPadding,
    );
    final minHeight = constraints.minHeight == 0
        ? math.min(defaultMin, constraints.maxHeight)
        : constraints.minHeight;
    final height = math.min(
      math.max(calculated, minHeight),
      constraints.maxHeight,
    );
    return (
      size: Size(width, height),
      leading: leading,
      trailing: trailing,
      overline: overline,
      headline: headline,
      supporting: supporting,
    );
  }

  static Size _layout(RenderBox child, BoxConstraints c) {
    child.layout(c, parentUsesSize: true);
    return child.size;
  }

  static Size _dry(RenderBox child, BoxConstraints c) => child.getDryLayout(c);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_measure(constraints, _dry).size);

  @override
  void performLayout() {
    final m = _measure(constraints, _layout);
    size = constraints.constrain(m.size);
    final rtl = _textDirection == TextDirection.rtl;
    void place(RenderBox? child, double left, double top) {
      if (child == null) return;
      (child.parentData! as BoxParentData).offset = Offset(
        rtl ? size.width - left - child.size.width : left,
        top,
      );
    }

    place(_leading, 0, _align(m.leading.height, size.height));
    final mainX = m.leading.width;
    final total = m.overline.height + m.headline.height + m.supporting.height;
    var y = _align(total, size.height);
    place(_overline, mainX, y);
    y += m.overline.height;
    place(_headline, mainX, y);
    y += m.headline.height;
    place(_supporting, mainX, y);
    place(
      _trailing,
      size.width - m.trailing.width,
      _align(m.trailing.height, size.height),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth((child) => child.getMaxIntrinsicWidth(height));

  double _intrinsicWidth(double Function(RenderBox) of) {
    double w(RenderBox? child) => child == null ? 0 : of(child);
    return w(_leading) +
        math.max(w(_headline), math.max(w(_overline), w(_supporting))) +
        w(_trailing);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, (child, w) => child.getMaxIntrinsicHeight(w));

  /// Compose's `calculateIntrinsicHeight`.
  double _intrinsicHeight(double width, double Function(RenderBox, double) of) {
    var remaining = width;
    double take(RenderBox? child) {
      if (child == null) return 0;
      final h = of(child, remaining);
      remaining = math.max(
        0,
        remaining - child.getMaxIntrinsicWidth(double.infinity),
      );
      return h;
    }

    final leading = take(_leading);
    final trailing = take(_trailing);
    double h(RenderBox? child) => child == null ? 0 : of(child, remaining);
    final overline = h(_overline);
    final supporting = h(_supporting);
    final headline = h(_headline);
    final multi = supporting > _multilineHeight;
    final main = overline + headline + supporting;
    final min = math.max(
      0.0,
      _containerHeight(overline > 0, supporting > 0, multi) - _verticalPadding,
    );
    return math.max(math.max(leading, math.max(main, trailing)), min);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final headline = _headline;
    if (headline == null) return null;
    final distance = headline.getDistanceToActualBaseline(baseline);
    if (distance == null) return null;
    return distance + (headline.parentData! as BoxParentData).offset.dy;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final parentData = child.parentData! as BoxParentData;
      final hit = result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

/// Where a divider sits between its edges.
enum ExpressiveDividerInset {
  /// Edge to edge.
  none,

  /// Inset at the start by the list's leading space (16dp): under text.
  start,

  /// Inset at both ends (16dp each): the middle inset.
  both,
}

/// A group of list items (Compose's `SegmentedListItem`s spaced
/// `ListItemDefaults.SegmentedGap`, 2dp, apart): each item's corners are
/// 4dp inside the group and 16dp on its outer edges, and a selected,
/// pressed or focused item rounds to 16dp. With [segmented] false it is a
/// plain list: items flush, optionally split by [divider]s.
///
/// Its children are [ExpressiveListTile]s (or accordions, swipe wrappers
/// around items): the section hands each its place, so no item names it.
/// [header] titles the group ([ExpressiveSectionHeader]) and [footer]
/// explains it beneath.
///
/// ```dart
/// ExpressiveListSection(header: 'Network', children: [ExpressiveListTile(title: Text('Wi-Fi'), onTap: openWifi), ExpressiveListTile(title: Text('Bluetooth'), onTap: openBluetooth)])
/// ```
class ExpressiveListSection extends StatelessWidget {
  /// A list section of [children], with an optional [header] and [footer].
  const ExpressiveListSection({
    required this.children,
    this.header,
    this.footer,
    this.segmented = true,
    this.divider,
    this.containerColor,
    super.key,
  });

  /// The items, top to bottom.
  final List<Widget> children;

  /// The group's title, above it.
  final String? header;

  /// A note beneath the group.
  final String? footer;

  /// Whether the items are segments (gapped, cornered) or a plain list.
  final bool segmented;

  /// For a plain list: a divider between items, inset so; none when null.
  final ExpressiveDividerInset? divider;

  /// The items' container colour at rest. Null: a segmented group's items
  /// stand on `surfaceContainer` (Compose's segmented samples), so the
  /// group reads as one tonal container on the page's `surface`; a plain
  /// list's on `surface`, flush with the page.
  final Color? containerColor;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final count = children.length;
    // One keyline region per section: its header, rows and footer share its
    // keylines (ui_core's keyline check reads it; it paints nothing).
    return DesignKeylineRegion(
      label: header ?? 'list section',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (header != null) ExpressiveSectionHeader(header!),
          for (var i = 0; i < count; i++) ...<Widget>[
            if (i > 0 && segmented)
              const SizedBox(height: ListTokens.segmentedGap)
            else if (i > 0 && divider != null)
              ExpressiveDivider(inset: divider!),
            _Segment(
              index: segmented ? i : null,
              count: segmented ? count : null,
              containerColor:
                  containerColor ??
                  (segmented ? t.colors.surfaceContainer : null),
              child: children[i],
            ),
          ],
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                ListTokens.itemLeadingSpace,
                ExpressiveSpacing.s8,
                ListTokens.itemTrailingSpace,
                ExpressiveSpacing.s0,
              ),
              child: Text(
                footer!,
                style: t.type
                    .of(ListTokens.itemSupportingTextFont)
                    .copyWith(
                      color: t.colors.role(ListTokens.itemSupportingTextColor),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A section's title (a list subheader): `titleSmall` in `primary`, set in
/// line with the items' text (the list's 16dp leading space), announced as
/// a heading, with an optional [trailing] action at the end.
///
/// ```dart
/// ExpressiveSectionHeader('Recent')
/// ```
class ExpressiveSectionHeader extends StatelessWidget {
  /// A section header reading [label], with an optional [trailing] action.
  const ExpressiveSectionHeader(this.label, {this.trailing, super.key});

  /// The title.
  final String label;

  /// An action at the end of the line ("See all").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        ListTokens.itemLeadingSpace,
        ExpressiveSpacing.s16,
        ListTokens.itemTrailingSpace,
        ExpressiveSpacing.s8,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: t.type.titleSmall.copyWith(color: t.colors.primary),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A Material divider (Compose's `HorizontalDivider` / `VerticalDivider`):
/// a 1dp `outlineVariant` line, full width or inset by the list's 16dp
/// divider spaces ([inset]).
///
/// ```dart
/// ExpressiveDivider(inset: ExpressiveDividerInset.start)
/// ```
class ExpressiveDivider extends StatelessWidget {
  /// A divider, inset by [inset] and running down when [vertical].
  const ExpressiveDivider({
    this.inset = ExpressiveDividerInset.none,
    this.vertical = false,
    super.key,
  });

  /// Where the line starts and ends.
  final ExpressiveDividerInset inset;

  /// Whether the line runs top to bottom (`VerticalDivider`); [inset] then
  /// applies at the top and bottom.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final color = context.expressiveTheme.colors.role(DividerTokens.color);
    final start = inset == ExpressiveDividerInset.none
        ? ExpressiveSpacing.s0
        : ListTokens.dividerLeadingSpace;
    final end = inset == ExpressiveDividerInset.both
        ? ListTokens.dividerTrailingSpace
        : ExpressiveSpacing.s0;
    final line = ColoredBox(color: color);
    return ExcludeSemantics(
      child: vertical
          ? Padding(
              padding: EdgeInsets.only(top: start, bottom: end),
              child: SizedBox(
                width: DividerTokens.thickness,
                height: double.infinity,
                child: line,
              ),
            )
          : Padding(
              padding: EdgeInsetsDirectional.only(start: start, end: end),
              child: SizedBox(
                width: double.infinity,
                height: DividerTokens.thickness,
                child: line,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reorderable list
// ---------------------------------------------------------------------------

/// A list whose items reorder by drag (Compose's reorderable list item
/// colours: the dragged item lifts to level 4 in `tertiaryContainer` with
/// 16dp corners — `ReorderListTokens`): each item from [itemBuilder] must
/// carry a key, and usually an [ExpressiveReorderHandle] as its trailing
/// content. [onReorder] is told the item's old index and its new one.
/// Segmented like [ExpressiveListSection] unless [segmented] is false. It
/// lays out at its content's height inside a scrolling page.
///
/// ```dart
/// ExpressiveReorderableListView(itemCount: tasks.length, onReorder: move, itemBuilder: (context, i) => ExpressiveListTile(key: ValueKey(tasks[i]), title: Text(tasks[i]), trailing: ExpressiveReorderHandle(index: i)))
/// ```
class ExpressiveReorderableListView extends StatelessWidget {
  /// A reorderable list of [itemCount] items from [itemBuilder] that reports a drag through [onReorder].
  const ExpressiveReorderableListView({
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    this.segmented = true,
    this.containerColor,
    super.key,
  });

  /// How many items.
  final int itemCount;

  /// Builds item [index]; the widget must have a key.
  final IndexedWidgetBuilder itemBuilder;

  /// Told `(from, to)`: the moved item's index before and after.
  final void Function(int from, int to) onReorder;

  /// Whether the items are segments.
  final bool segmented;

  /// The items' container colour at rest.
  final Color? containerColor;

  @override
  Widget build(BuildContext context) => ReorderableList(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    onReorderItem: onReorder,
    proxyDecorator: (child, index, animation) => _Dragged(child: child),
    itemBuilder: (context, index) {
      final item = itemBuilder(context, index);
      assert(item.key != null, 'a reorderable item needs a key');
      return KeyedSubtree(
        key: item.key,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: segmented && index < itemCount - 1
                ? ListTokens.segmentedGap
                : ExpressiveSpacing.s0,
          ),
          child: _Segment(
            index: segmented ? index : null,
            count: segmented ? itemCount : null,
            containerColor: containerColor,
            child: item,
          ),
        ),
      );
    },
  );
}

/// The drag handle of an item in an [ExpressiveReorderableListView]: the
/// `drag_indicator` glyph; a drag starting on it moves item [index].
class ExpressiveReorderHandle extends StatelessWidget {
  /// A drag handle for the item at [index].
  const ExpressiveReorderHandle({
    required this.index,
    this.semanticLabel,
    super.key,
  });

  /// The item's index in its list.
  final int index;

  /// What a screen reader says for the handle (the strings' `reorder` when
  /// null).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => ReorderableDragStartListener(
    index: index,
    child: MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Icon(
        ExpressiveSymbols.dragIndicator,
        semanticLabel:
            semanticLabel ?? ExpressiveLocalizations.of(context).reorder,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Swipe: the anchored drag (Compose's AnchoredDraggable, as SwipeToDismissBox
// uses it)
// ---------------------------------------------------------------------------

/// Which way a swipe travels, in reading order.
enum ExpressiveSwipeDirection {
  /// From the start edge toward the end (rightward in LTR).
  startToEnd,

  /// From the end edge toward the start (leftward in LTR).
  endToStart,
}

/// The anchored horizontal drag both swipe components share: the content
/// follows the finger within its anchors, then springs to the anchor
/// Compose's `AnchoredDraggable` fling behaviour picks — the next anchor in
/// the release's direction at or above 125dp/s, else the next one when the
/// drag travelled 56dp past the resting anchor, else back
/// (`SwipeToDismissBoxBehavior`). Offsets are logical: positive toward the
/// end edge.
mixin _AnchoredSwipe<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController offset = AnimationController.unbounded(
    vsync: this,
  );

  /// The resting anchor the drag started from.
  double settled = 0;

  /// The anchors for a box [width] wide, logical.
  List<double> anchorsFor(double width);

  /// Told when the drag settles on [anchor].
  void onSettled(double anchor, double width);

  bool get swipeEnabled;

  double _width = 0;

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void dispose() {
    offset.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails _) => offset.stop();

  void _onDragUpdate(DragUpdateDetails details) {
    final anchors = anchorsFor(_width);
    final delta = (details.primaryDelta ?? 0) * (_rtl ? -1 : 1);
    offset.value = (offset.value + delta).clamp(
      anchors.reduce(math.min),
      anchors.reduce(math.max),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = (details.primaryVelocity ?? 0) * (_rtl ? -1 : 1);
    springTo(_target(anchorsFor(_width), velocity), velocity: velocity);
  }

  /// Springs to [target] and reports it settled.
  Future<void> springTo(double target, {double velocity = 0}) async {
    final spring = ExpressiveMotion.of(context)
        .spring(ExpressiveMotionKey.defaultSpatial);
    await offset.springTo(target, spring, velocity: velocity);
    if (!mounted || offset.value != target) return;
    settled = target;
    onSettled(target, _width);
  }

  static double _closest(List<double> anchors, double at, bool upwards) {
    final ahead = anchors.where((a) => upwards ? a >= at : a <= at);
    final pool = ahead.isEmpty ? anchors : ahead;
    return pool.reduce((a, b) => (a - at).abs() <= (b - at).abs() ? a : b);
  }

  double _target(List<double> anchors, double velocity) {
    final at = offset.value;
    if (!anchors.contains(settled)) return _closest(anchors, at, true);
    if (at == settled) return settled;
    if (velocity.abs() >= SwipeToDismissBoxBehavior.velocityThreshold) {
      return _closest(anchors, at, velocity > 0);
    }
    final next = _closest(anchors, at, at > settled);
    return (at - settled).abs() >= SwipeToDismissBoxBehavior.positionalThreshold
        ? next
        : settled;
  }

  /// The swipe's box: [background] under [content], which follows the
  /// drag.
  Widget swipeBox({
    required Widget Function(double logical) background,
    required Widget content,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      _width = constraints.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: swipeEnabled ? _onDragStart : null,
        onHorizontalDragUpdate: swipeEnabled ? _onDragUpdate : null,
        onHorizontalDragEnd: swipeEnabled ? _onDragEnd : null,
        child: AnimatedBuilder(
          animation: offset,
          builder: (context, child) {
            final logical = offset.value;
            return Stack(
              children: <Widget>[
                // The band fills the row's slot in the row's resting shape
                // (a segmented section's 16dp and 4dp corners), so mid-swipe
                // its corners and the row's go together.
                if (logical != 0)
                  Positioned.fill(
                    child: ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: _restingShape(context),
                        textDirection: Directionality.of(context),
                      ),
                      child: background(logical),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(_rtl ? -logical : logical, 0),
                  child: child,
                ),
              ],
            );
          },
          child: content,
        ),
      );
    },
  );
}

/// A row that dismisses by a horizontal swipe (Compose's
/// `SwipeToDismissBox`): the content follows the finger over its
/// [background], and a swipe past 56dp or faster than 125dp/s settles off
/// the edge and reports [onDismissed] once; slower and shorter springs
/// back. The list removes the item on [onDismissed].
///
/// Only [directions] dismiss: by default the end-to-start swipe (from the
/// trailing edge), since a swipe from the start edge is back on both
/// platforms. The default background is `errorContainer` with the delete
/// glyph on the side the swipe reveals.
///
/// ```dart
/// ExpressiveSwipeToDismiss(key: ValueKey(mail.id), onDismissed: (_) => archive(mail), child: ExpressiveListTile(title: Text(mail.subject)))
/// ```
class ExpressiveSwipeToDismiss extends StatefulWidget {
  /// A row that reports [onDismissed] when swiped away in [directions].
  const ExpressiveSwipeToDismiss({
    required this.child,
    required this.onDismissed,
    this.directions = const <ExpressiveSwipeDirection>{
      ExpressiveSwipeDirection.endToStart,
    },
    this.background,
    this.dismissLabel,
    super.key,
  });

  /// The row.
  final Widget child;

  /// Told the direction once the row has swiped off.
  final ValueChanged<ExpressiveSwipeDirection> onDismissed;

  /// The directions that dismiss.
  final Set<ExpressiveSwipeDirection> directions;

  /// What shows under the row as it moves, for the direction it moves in.
  final Widget Function(
    BuildContext context,
    ExpressiveSwipeDirection direction,
  )?
  background;

  /// Whether it takes input: false when directions is null, as in Flutter.
  bool get enabled => directions.isNotEmpty;

  /// The dismiss action's name for assistive technology (reached without
  /// swiping).
  final String? dismissLabel;

  @override
  State<ExpressiveSwipeToDismiss> createState() =>
      _ExpressiveSwipeToDismissState();
}

class _ExpressiveSwipeToDismissState extends State<ExpressiveSwipeToDismiss>
    with
        SingleTickerProviderStateMixin,
        _AnchoredSwipe<ExpressiveSwipeToDismiss> {
  bool _dismissed = false;

  @override
  bool get swipeEnabled => widget.enabled && !_dismissed;

  @override
  List<double> anchorsFor(double width) => <double>[
    0,
    if (widget.directions.contains(ExpressiveSwipeDirection.startToEnd)) width,
    if (widget.directions.contains(ExpressiveSwipeDirection.endToStart)) -width,
  ];

  @override
  void onSettled(double anchor, double width) {
    if (anchor == 0 || _dismissed) return;
    setState(() => _dismissed = true);
    widget.onDismissed(
      anchor > 0
          ? ExpressiveSwipeDirection.startToEnd
          : ExpressiveSwipeDirection.endToStart,
    );
  }

  Widget _defaultBackground(ExpressiveSwipeDirection direction) {
    final c = context.expressiveTheme.colors;
    return ColoredBox(
      color: c.errorContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: ListTokens.itemLeadingSpace,
          end: ListTokens.itemTrailingSpace,
        ),
        child: Align(
          alignment: direction == ExpressiveSwipeDirection.endToStart
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Icon(
            ExpressiveSymbols.delete,
            color: c.onErrorContainer,
            size: ListTokens.itemTrailingIconSize,
          ),
        ),
      ),
    );
  }

  void _dismissBy(ExpressiveSwipeDirection direction) {
    springTo(
      direction == ExpressiveSwipeDirection.endToStart ? -_width : _width,
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    customSemanticsActions: swipeEnabled
        ? <CustomSemanticsAction, VoidCallback>{
            CustomSemanticsAction(
              label:
                  widget.dismissLabel ??
                  ExpressiveLocalizations.of(context).delete,
            ): () =>
                _dismissBy(widget.directions.first),
          }
        : null,
    child: swipeBox(
      background: (logical) {
        final direction = logical < 0
            ? ExpressiveSwipeDirection.endToStart
            : ExpressiveSwipeDirection.startToEnd;
        return ExcludeSemantics(
          child:
              widget.background?.call(context, direction) ??
              _defaultBackground(direction),
        );
      },
      content: widget.child,
    ),
  );
}

/// An action a swipe reveals beside a row ([ExpressiveSwipeActions]).
@immutable
class ExpressiveSwipeAction {
  /// A swipe action labelled [label], showing [icon], that runs [onPressed].
  const ExpressiveSwipeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
    this.destructive = false,
    this.style,
  });

  /// Stateful visual overrides for the revealed action.
  final ExpressiveComponentThemeData? style;

  /// What the action is called: its tooltip and screen-reader label.
  final String label;

  /// Its glyph (one of `ExpressiveSymbols`).
  final IconData icon;

  /// What it does; the row closes after.
  final VoidCallback onPressed;

  /// The row's main action: `primary` on a 16dp-cornered container
  /// (`RevealListTokens` action button), not the round `secondaryContainer`
  /// one.
  final bool emphasized;

  /// A destructive action: `error` colours on the emphasized shape.
  final bool destructive;
}

/// A row that reveals actions by a horizontal swipe (Material's reveal
/// list, `RevealListTokens`): [trailing] actions show when the row swipes
/// from its end edge, [leading] ones from its start edge (either side
/// follows the reading direction). The row rests open with its actions
/// shown; tapping one runs it and closes the row. With [allowsFullSwipe], a
/// swipe across the whole row runs the outermost action (each list's
/// first) once. Every action is also a screen-reader action on the row.
///
/// ```dart
/// ExpressiveSwipeActions(trailing: [ExpressiveSwipeAction(label: 'Delete', icon: ExpressiveSymbols.delete, destructive: true, onPressed: delete), ExpressiveSwipeAction(label: 'Archive', icon: ExpressiveSymbols.archive, onPressed: archive)], child: ExpressiveListTile(title: Text('Trip')))
/// ```
class ExpressiveSwipeActions extends StatefulWidget {
  /// A row of [child] that reveals [leading] and [trailing] actions on a swipe.
  const ExpressiveSwipeActions({
    required this.child,
    this.leading = const <ExpressiveSwipeAction>[],
    this.trailing = const <ExpressiveSwipeAction>[],
    this.allowsFullSwipe = false,
    super.key,
  });

  /// The row.
  final Widget child;

  /// Actions at the start edge, outermost first.
  final List<ExpressiveSwipeAction> leading;

  /// Actions at the end edge, outermost first.
  final List<ExpressiveSwipeAction> trailing;

  /// Whether a swipe across the whole row runs the outermost action.
  final bool allowsFullSwipe;

  /// Whether it takes input: false when leading is null, as in Flutter.
  bool get enabled => leading.isNotEmpty || trailing.isNotEmpty;

  @override
  State<ExpressiveSwipeActions> createState() => _ExpressiveSwipeActionsState();
}

class _ExpressiveSwipeActionsState extends State<ExpressiveSwipeActions>
    with
        SingleTickerProviderStateMixin,
        _AnchoredSwipe<ExpressiveSwipeActions> {
  @override
  bool get swipeEnabled => widget.enabled;

  /// A row of [count] actions: 40dp buttons 8dp apart, 16dp from each edge.
  static double _revealWidth(int count) => count == 0
      ? 0
      : ListTokens.itemLeadingSpace +
            count * SmallIconButtonTokens.containerHeight +
            (count - 1) * ExpressiveSpacing.s8 +
            ListTokens.itemTrailingSpace;

  @override
  List<double> anchorsFor(double width) => <double>{
    0,
    if (widget.leading.isNotEmpty) _revealWidth(widget.leading.length),
    if (widget.leading.isNotEmpty && widget.allowsFullSwipe) width,
    if (widget.trailing.isNotEmpty) -_revealWidth(widget.trailing.length),
    if (widget.trailing.isNotEmpty && widget.allowsFullSwipe) -width,
  }.toList();

  @override
  void onSettled(double anchor, double width) {
    setState(() {});
    if (width == 0 || anchor.abs() != width) return;
    final actions = anchor > 0 ? widget.leading : widget.trailing;
    actions.first.onPressed();
    springTo(0);
  }

  void _run(ExpressiveSwipeAction action) {
    action.onPressed();
    springTo(0);
  }

  Widget _actions(List<ExpressiveSwipeAction> actions, bool leading) {
    final ordered = leading ? actions : actions.reversed.toList();
    return Align(
      alignment: leading
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: ListTokens.itemLeadingSpace,
          end: ListTokens.itemTrailingSpace,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: ExpressiveSpacing.s8,
          children: <Widget>[
            for (final action in ordered)
              _RevealButton(action: action, onPressed: () => _run(action)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    customSemanticsActions: widget.enabled
        ? <CustomSemanticsAction, VoidCallback>{
            for (final action in <ExpressiveSwipeAction>[
              ...widget.leading,
              ...widget.trailing,
            ])
              CustomSemanticsAction(label: action.label): action.onPressed,
          }
        : null,
    child: swipeBox(
      background: (logical) => logical > 0
          ? _actions(widget.leading, true)
          : _actions(widget.trailing, false),
      // Open, a tap on the row closes it instead of reaching the row.
      content: settled == 0
          ? widget.child
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => springTo(0),
              child: AbsorbPointer(child: widget.child),
            ),
    ),
  );
}

/// One revealed action: a 40dp button, round in `secondaryContainer` or,
/// emphasized, 16dp-cornered in `primary` (`RevealListTokens`).
class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.action, required this.onPressed});

  final ExpressiveSwipeAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final emphasized = action.emphasized || action.destructive;
    final Color container;
    final Color content;
    if (action.destructive) {
      container = c.error;
      content = c.onError;
    } else if (emphasized) {
      container = c.role(RevealListTokens.itemActionIconButtonContainerColor);
      content = c.role(RevealListTokens.itemActionButtonIconIconColor);
    } else {
      container = c.role(RevealListTokens.itemIconButtonContainerColor);
      content = c.role(RevealListTokens.itemButtonIconIconColor);
    }
    return ExpressivePressable(
      style: action.style,
      componentStyle: t.iconButtonTheme,
      shapes: ExpressivePressShapes.all(
        t.shapes.of(
          emphasized
              ? RevealListTokens.itemIconButtonActionContainerShape
              : RevealListTokens.itemIconButtonContainerShape,
        ),
      ),
      motion: ListItemBehavior.shapeMotion,
      color: container,
      contentColor: content,
      semanticLabel: action.label,
      tooltip: action.label,
      onPressed: onPressed,
      child: ExpressiveStyledContent(
        minimumSize: const Size.square(SmallIconButtonTokens.containerHeight),
        iconSize: SmallIconButtonTokens.iconSize,
        child: Icon(action.icon),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accordion
// ---------------------------------------------------------------------------

/// An expandable list item (Material's expanded list, `ExpandedListTokens`):
/// a header [ExpressiveListTile] whose trailing chevron sits in a round
/// container (`surface` collapsed, `surfaceContainer` expanded) and turns
/// as [child] opens beneath it on the default spatial spring. Expanded, the
/// header and its content become two segments with 16dp outer corners
/// (`ExpandedListTokens.ContainerShape`), 2dp apart.
///
/// Uncontrolled with [initiallyExpanded]; controlled when [expanded] is
/// given (then [onExpansionChanged] must change it).
///
/// ```dart
/// ExpressiveDisclosure(title: Text('Shipping'), child: Text('Ships in two days.'))
/// ```
class ExpressiveDisclosure extends StatefulWidget {
  /// An accordion with the given [title] that opens to show [child].
  const ExpressiveDisclosure({
    required this.title,
    required this.child,
    this.overline,
    this.subtitle,
    this.leading,
    this.expanded,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.enabled = true,
    this.contentPadding,
    this.style,
    super.key,
  });

  /// Stateful visual overrides for the header and expanded panel.
  final ExpressiveComponentThemeData? style;

  /// The header's main line.
  final Widget title;

  /// The header's overline.
  final Widget? overline;

  /// The header's supporting text.
  final Widget? subtitle;

  /// The header's leading content.
  final Widget? leading;

  /// What opens beneath the header.
  final Widget child;

  /// Whether it is open (controlled); null to keep its own state.
  final bool? expanded;

  /// Whether it starts open, uncontrolled.
  final bool initiallyExpanded;

  /// Told the next open state on a tap.
  final ValueChanged<bool>? onExpansionChanged;

  /// Whether the header takes input.
  final bool enabled;

  /// Padding around [child]; the list item's content padding when null.
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<ExpressiveDisclosure> createState() => _ExpressiveDisclosureState();
}

class _ExpressiveDisclosureState extends State<ExpressiveDisclosure> {
  late bool _open = widget.initiallyExpanded;

  bool get _expanded => widget.expanded ?? _open;

  void _toggle() {
    final next = !_expanded;
    if (widget.expanded == null) setState(() => _open = next);
    widget.onExpansionChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final s = t.shapes;
    final segment = _Segment.of(context);
    final expanded = _expanded;
    final outer = s.of(ExpandedListTokens.containerShape);
    final inner = s.of(ListTokens.itemContainerExpressiveShape);
    final header = ExpressiveCornerBorder(
      topStart: outer.topStart,
      topEnd: outer.topEnd,
      bottomEnd: inner.bottomEnd,
      bottomStart: inner.bottomStart,
    );
    final body = ExpressiveCornerBorder(
      topStart: inner.topStart,
      topEnd: inner.topEnd,
      bottomEnd: outer.bottomEnd,
      bottomStart: outer.bottomStart,
    );
    final container =
        segment?.containerColor ??
        t.colors.role(ExpandedListTokens.expandedItemSegmentedContainerColor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Segment(
          index: segment?.index,
          count: segment?.count,
          containerColor: segment?.containerColor,
          corners: expanded ? header : segment?.corners,
          child: ExpressiveListTile(
            style: widget.style,
            title: widget.title,
            overline: widget.overline,
            subtitle: widget.subtitle,
            leading: widget.leading,
            trailing: _ExpandGlyph(expanded: expanded),
            expanded: expanded,
            enabled: widget.enabled,
            onTap: _toggle,
          ),
        ),
        ExpressiveSpringValue(
          value: expanded ? 1 : 0,
          motion: ExpressiveMotionKey.defaultSpatial,
          builder: (context, open, child) => open <= 0
              ? const SizedBox.shrink()
              : ClipRect(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    heightFactor: math.max(0, open),
                    child: child,
                  ),
                ),
          child: Padding(
            padding: const EdgeInsets.only(top: ListTokens.segmentedGap),
            child: ExpressiveSurface(
              style: widget.style,
              componentStyle: t.listTileTheme,
              states: {
                WidgetState.selected,
                if (!widget.enabled) WidgetState.disabled,
              },
              padding:
                  widget.contentPadding ??
                  ExpressiveListTile.defaultContentPadding,
              shape: body,
              color: container,
              contentColor: t.colors.role(ListTokens.itemSupportingTextColor),
              child: DefaultTextStyle.merge(
                style: t.type
                    .of(ListTokens.itemSupportingTextFont)
                    .merge(
                      t.listTileTheme.merge(widget.style).textStyle?.resolve({
                        WidgetState.selected,
                        if (!widget.enabled) WidgetState.disabled,
                      }),
                    ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The accordion's chevron: `expand_more` in a round container that turns
/// a half turn open, its container `surface` → `surfaceContainer`.
class _ExpandGlyph extends StatelessWidget {
  const _ExpandGlyph({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return ExpressiveSpringColor(
      value: c.role(
        expanded
            ? ExpandedListTokens.expandedItemTrailingIconContainerColor
            : ExpandedListTokens.collapsedItemTrailingIconContainerColor,
      ),
      motion: ListItemBehavior.colorMotion,
      builder: (context, fill, _) => DecoratedBox(
        decoration: ShapeDecoration(
          shape: t.shapes.of(ExpandedListTokens.trailingIconShape),
          color: fill,
        ),
        child: SizedBox.square(
          dimension: XSmallIconButtonTokens.containerHeight,
          child: ExpressiveSpringValue(
            value: expanded ? 0.5 : 0,
            motion: ExpressiveMotionKey.defaultSpatial,
            builder: (context, turns, _) => Transform.rotate(
              angle: turns * math.pi * 2,
              child: Icon(
                ExpressiveSymbols.expandMore,
                size: ListTokens.itemTrailingIconExpressiveSize,
                color: c.role(
                  expanded
                      ? ExpandedListTokens.expandedItemTrailingIconIconColor
                      : ExpandedListTokens.collapsedItemTrailingIconIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid
// ---------------------------------------------------------------------------

/// A lazy grid (Compose's `LazyVerticalGrid`): [itemCount] cells from
/// [itemBuilder], built as they scroll into view, in [columns] equal
/// columns or — with [minItemWidth] — as many as fit at that width
/// (`GridCells.Adaptive`), [spacing] apart both ways. Cells are
/// [childAspectRatio] wide per tall unless [itemHeight] fixes them. With
/// [shrinkWrap] it lays out at its content's height inside a scrolling
/// page.
///
/// ```dart
/// ExpressiveGrid(itemCount: photos.length, columns: 3, itemBuilder: (context, i) => photoTile(photos[i]))
/// ```
class ExpressiveGrid extends StatelessWidget {
  /// A lazy grid of [itemCount] cells from [itemBuilder].
  const ExpressiveGrid({
    required this.itemCount,
    required this.itemBuilder,
    this.columns = 2,
    this.minItemWidth,
    this.spacing = ExpressiveSpacing.s8,
    this.childAspectRatio = 1,
    this.itemHeight,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  /// How many cells.
  final int itemCount;

  /// Builds cell [index].
  final IndexedWidgetBuilder itemBuilder;

  /// The column count, when [minItemWidth] is null.
  final int columns;

  /// The narrowest a cell may be: as many columns as fit.
  final double? minItemWidth;

  /// The space between cells, both ways.
  final double spacing;

  /// A cell's width over its height.
  final double childAspectRatio;

  /// A fixed cell height, over [childAspectRatio].
  final double? itemHeight;

  /// Padding around the grid.
  final EdgeInsetsGeometry? padding;

  /// The scroll controller.
  final ScrollController? controller;

  /// Whether the grid sizes to its content (inside another scroll view).
  final bool shrinkWrap;

  /// The scroll physics; not scrollable itself when [shrinkWrap] and null.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => GridView.builder(
    controller: controller,
    padding: padding ?? EdgeInsets.zero,
    shrinkWrap: shrinkWrap,
    physics:
        physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
    itemCount: itemCount,
    itemBuilder: itemBuilder,
    gridDelegate: _GridCells(
      columns: columns,
      minItemWidth: minItemWidth,
      spacing: spacing,
      childAspectRatio: childAspectRatio,
      itemHeight: itemHeight,
    ),
  );
}

/// `GridCells.Fixed` / `GridCells.Adaptive`: equal columns, the adaptive
/// count `max(1, (width + spacing) / (minSize + spacing))` rounded down.
class _GridCells extends SliverGridDelegate {
  const _GridCells({
    required this.columns,
    required this.minItemWidth,
    required this.spacing,
    required this.childAspectRatio,
    required this.itemHeight,
  });

  final int columns;
  final double? minItemWidth;
  final double spacing;
  final double childAspectRatio;
  final double? itemHeight;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width = constraints.crossAxisExtent;
    final count = minItemWidth == null
        ? math.max(1, columns)
        : math.max(1, ((width + spacing) / (minItemWidth! + spacing)).floor());
    final cell = math.max(0.0, (width - spacing * (count - 1)) / count);
    final height = itemHeight ?? cell / childAspectRatio;
    return SliverGridRegularTileLayout(
      crossAxisCount: count,
      mainAxisStride: height + spacing,
      crossAxisStride: cell + spacing,
      childMainAxisExtent: height,
      childCrossAxisExtent: cell,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_GridCells oldDelegate) =>
      columns != oldDelegate.columns ||
      minItemWidth != oldDelegate.minItemWidth ||
      spacing != oldDelegate.spacing ||
      childAspectRatio != oldDelegate.childAspectRatio ||
      itemHeight != oldDelegate.itemHeight;
}
