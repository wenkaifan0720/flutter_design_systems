/// Chips: assist, filter, input and suggestion, flat and elevated, and the
/// row they flow in (CONTRACT §4.1 `chip`). Owner: w3-selection.
///
/// A port of Compose material3 1.5.0-alpha29's `Chip.kt`: the private
/// `Chip`/`SelectableChip` (a clickable `Surface` — here the shared
/// [ExpressivePressable] — over `ChipContent`/`AnimatingChipContent`),
/// every colour, border and elevation from `AssistChipTokens`,
/// `FilterChipTokens`, `InputChipTokens` and `SuggestionChipTokens` as each
/// chip's `*Defaults` reads them, the spacing from `ChipBehavior` and
/// `InputChipBehavior`. The morphing shapes of the Expressive overloads
/// (`FilterChipDefaults.shapes()`, `InputChipDefaults.shapes()`: medium at
/// rest, full when selected, small while pressed) are [morph].
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../color.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/cap_label.dart';
import '../internal/tokens/assist_chip_tokens.g.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/chips_tokens.g.dart';
import '../internal/tokens/filter_chip_tokens.g.dart';
import '../internal/tokens/input_chip_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/suggestion_chip_tokens.g.dart';
import '../motion.dart';
import '../spacing.dart';
import '../states.dart';
import '../internal/styled_content.dart';
import '../strings.dart';
import '../theme.dart';

/// Nothing: the fill of a container Compose leaves `Color.Transparent`.
const Color _clear = expressiveTransparent;

enum _ChipKind { assist, filter, input, suggestion }

/// A Material 3 chip, one of Compose's four:
///
/// - [ExpressiveChip.assist]: a smart action from the content (`AssistChip`,
///   `ElevatedAssistChip`), its icon in `primary`.
/// - [ExpressiveChip.filter]: a toggle among options (`FilterChip`,
///   `ElevatedFilterChip`); selected, it fills with `secondaryContainer`
///   and its leading slot shows the check (the pattern Compose's samples
///   and Material's guidance give), springing open.
/// - [ExpressiveChip.input]: a piece of entered information
///   (`InputChip`), with an avatar or icon and a remove control.
/// - [ExpressiveChip.suggestion]: a dynamically suggested reply or query
///   (`SuggestionChip`, `ElevatedSuggestionChip`).
///
/// [ExpressiveChip.new] picks one the way Material's chips are told apart:
/// with [onDeleted] an input chip, with [selected] a filter chip, else an
/// assist chip. A press is [onPressed] on every kind; a filter chip's
/// handler flips the selection it is given.
///
/// 32dp tall on its token shape, inside Compose's 48dp touch target.
///
/// ```dart
/// ExpressiveChip('Vegetarian', selected: veg, onPressed: () => setState(() => veg = !veg))
/// ```
class ExpressiveChip extends StatelessWidget {
  /// A chip labelled [label]: an input chip with [onDeleted], a filter chip
  /// with [selected], else an assist chip.
  const ExpressiveChip(
    this.label, {
    this.onPressed,
    this.style,
    bool? selected,
    this.onDeleted,
    this.deleteLabel,
    this.icon,
    this.enabled = true,
    super.key,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = onDeleted != null
           ? _ChipKind.input
           : selected != null
           ? _ChipKind.filter
           : _ChipKind.assist,
       selected = selected ?? false,
       trailingIcon = null,
       avatar = null,
       elevated = false,
       morph = false;

  /// An assist chip.
  const ExpressiveChip.assist(
    this.label, {
    this.onPressed,
    this.style,
    this.icon,
    this.trailingIcon,
    this.elevated = false,
    this.enabled = true,
    super.key,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _ChipKind.assist,
       selected = false,
       avatar = null,
       onDeleted = null,
       deleteLabel = null,
       morph = false;

  /// A filter chip: [onPressed] flips [selected].
  const ExpressiveChip.filter(
    this.label, {
    required this.selected,
    this.onPressed,
    this.style,
    this.icon,
    this.trailingIcon,
    this.elevated = false,
    this.morph = false,
    this.enabled = true,
    super.key,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _ChipKind.filter,
       avatar = null,
       onDeleted = null,
       deleteLabel = null;

  /// An input chip.
  const ExpressiveChip.input(
    this.label, {
    this.selected = false,
    this.onPressed,
    this.style,
    this.onDeleted,
    this.deleteLabel,
    this.avatar,
    this.icon,
    this.morph = false,
    this.enabled = true,
    super.key,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _ChipKind.input,
       trailingIcon = null,
       elevated = false;

  /// A suggestion chip.
  const ExpressiveChip.suggestion(
    this.label, {
    this.onPressed,
    this.style,
    this.icon,
    this.elevated = false,
    this.enabled = true,
    super.key,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _ChipKind.suggestion,
       selected = false,
       trailingIcon = null,
       avatar = null,
       onDeleted = null,
       deleteLabel = null,
       morph = false;

  /// Stateful visual overrides before the chip theme.
  final ExpressiveComponentThemeData? style;

  final _ChipKind _kind;

  /// The chip's text, one line.
  final String label;

  /// What a tap does; a filter chip's flips its selection. The chip is out
  /// of use when null.
  final VoidCallback? onPressed;

  /// Whether a filter or input chip is selected.
  final bool selected;

  /// The leading glyph (a filter chip shows the check in its place while
  /// selected).
  final IconData? icon;

  /// The trailing glyph (assist and filter: a dropdown arrow, say).
  final IconData? trailingIcon;

  /// An input chip's avatar, clipped to a 24dp circle; wins over [icon].
  final Widget? avatar;

  /// Removes an input chip: shows the trailing close glyph as its own
  /// target.
  final VoidCallback? onDeleted;

  /// What a screen reader calls the remove target (Material's
  /// `deleteButtonTooltipMessage`); "Remove [label]" when null.
  final String? deleteLabel;

  /// The elevated style (assist, filter, suggestion): a
  /// `surfaceContainerLow` container on a level 1 shadow, no outline.
  final bool elevated;

  /// Whether a filter or input chip morphs its shape (Compose's
  /// `ChipShapes`: medium at rest, full selected, small pressed).
  final bool morph;

  /// Whether the chip takes input; disabled colours when false.
  final bool enabled;

  bool get _selectable => _kind == _ChipKind.filter || _kind == _ChipKind.input;

  VoidCallback? get _action => enabled ? onPressed : null;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final s = _styleOf(c).themed(
      t.chipTheme,
      expressiveComponentStates(
        enabled: enabled,
        selected: _selectable && selected,
      ),
    );
    final shapes = morph && _selectable
        ? ExpressivePressShapes(
            shape: t.shapes.of(ChipsTokens.unselectedShape),
            selected: t.shapes.of(ChipsTokens.selectedShape),
            pressed: t.shapes.of(ChipsTokens.pressedShape),
          )
        : ExpressivePressShapes.all(t.shapes.of(s.shape));

    final content = Builder(
      builder: (context) {
        final scope = ExpressiveStyleScope.maybeOf(context)!;
        final scoped = scope.style;
        final states = scope.states;
        final s = _styleOf(c).themed(scoped, states);
        final Widget? leading;
        if (avatar != null) {
          // 24dp in the 32dp chip, 4dp clear of the outline all round; a
          // denser chip (compact on desktop: 24dp) keeps that 4dp and the
          // avatar gives way, so it never sits on the outline.
          final avatarSize = math.min(
            InputChipTokens.avatarSize,
            math.max(
              0.0,
              t.density.height(ChipsTokens.height, floor: 0) -
                  2 * InputChipBehavior.compactPadding,
            ),
          );
          // Density trims the chip's 4dp start padding too (compact: to 0);
          // the avatar takes back what it lost, so it stays 4dp clear of
          // the outline at its start as well.
          final startLost = scoped.padding?.resolve(states) == null
              ? (-t.density.horizontal * 2)
                    .clamp(0.0, InputChipBehavior.compactPadding)
                    .toDouble()
              : 0.0;
          leading = Padding(
            padding: EdgeInsetsDirectional.only(start: startLost),
            child: Opacity(
              opacity: enabled ? 1 : InputChipTokens.disabledAvatarOpacity,
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: const CircleBorder()),
                child: SizedBox.square(dimension: avatarSize, child: avatar),
              ),
            ),
          );
        } else {
          final glyph = _kind == _ChipKind.filter && selected
              ? ExpressiveSymbols.check
              : icon;
          leading = glyph == null
              ? null
              : Icon(
                  glyph,
                  size: scoped.iconSize?.resolve(states) ?? s.iconSize,
                  color: s.leadingColor,
                );
        }
        Widget? trailing;
        if (_kind == _ChipKind.input && onDeleted != null) {
          trailing = Icon(
            ExpressiveSymbols.close,
            size:
                scoped.iconSize?.resolve(states) ??
                InputChipTokens.trailingIconSize,
            color: s.trailingColor,
          );
        } else if (trailingIcon != null) {
          trailing = Icon(
            trailingIcon,
            size: scoped.iconSize?.resolve(states) ?? s.iconSize,
            color: s.trailingColor,
          );
        }

        final double start;
        final double end;
        if (_kind == _ChipKind.input) {
          // InputChipDefaults.contentPadding(hasAvatar, hasLeadingIcon,
          // hasTrailingIcon).
          start = avatar != null || icon == null
              ? InputChipBehavior.compactPadding
              : InputChipBehavior.iconPadding;
          end = trailing != null
              ? InputChipBehavior.iconPadding
              : InputChipBehavior.compactPadding;
        } else {
          start = ChipBehavior.contentPadding;
          end = ChipBehavior.contentPadding;
        }

        final text = expressiveFaceLabel(
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.type
                .of(s.font)
                .merge(scoped.textStyle?.resolve(states))
                .copyWith(color: s.labelColor),
          ),
        );
        // ChipContent / AnimatingChipContent: leading, label, trailing, always
        // three slots (an empty slot is 0 wide) in a `ChipArrangement`: 8dp
        // apart, except the Expressive (morphing) overloads' compact
        // arrangement (`FilterChipDefaults`/`InputChipDefaults`
        // `.horizontalArrangement(has…)`): 4dp beside a present icon or
        // avatar. `ChipArrangement(lead, trail)` spaces the row by their sum
        // and puts the label `lead` after a present leading slot (`trail`
        // after an empty one); the rest goes before the trailing slot.
        const wide = ChipBehavior.horizontalSpacing;
        const compact = ChipBehavior.compactHorizontalSpacing;
        final hasLead = leading != null;
        final hasTrail = trailing != null;
        final compactArrangement = morph && _selectable;
        final lead = compactArrangement && hasLead ? compact : wide;
        final trail = compactArrangement && hasTrail ? compact : wide;
        final beforeLabel = hasLead ? lead : trail;
        final afterLabel = lead + trail - beforeLabel;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ChipBehavior.maxWidth),
          child: ExpressiveStyledContent(
            minimumSize: const Size(0, ChipsTokens.height),
            padding: EdgeInsetsDirectional.only(start: start, end: end),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_selectable)
                  _ChipSlot(
                    alignment: AlignmentDirectional.centerStart,
                    morph: morph,
                    child: leading,
                  )
                else
                  leading ?? const SizedBox.shrink(),
                SizedBox(width: beforeLabel),
                Flexible(child: text),
                SizedBox(width: afterLabel),
                if (_selectable)
                  _ChipSlot(
                    alignment: AlignmentDirectional.centerEnd,
                    morph: morph,
                    child: trailing,
                  )
                else
                  trailing ?? const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );

    final chip = ExpressivePressable(
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      componentStyle: t.chipTheme,
      shapes: shapes,
      motion: ChipBehavior.shapeMotion,
      color: s.container,
      // The ripple and state layers: Surface's content colour.
      contentColor: c.contentColorFor(s.container) ?? c.onSurface,
      side: s.side,
      elevation: s.elevation,
      role: _selectable
          ? ExpressivePressRole.checkbox
          : ExpressivePressRole.button,
      selected: _selectable && selected,
      onPressed: _action,
      // A live input chip with nothing of its own to do (a multi-select's
      // chip: only its remove glyph acts) shows the cursor of what it sits
      // in, the field's text cursor there, not the arrow over a body a
      // click goes through.
      mouseCursor: _action == null && onDeleted != null && enabled
          ? MouseCursor.defer
          : null,
      child: content,
    );
    if (_kind != _ChipKind.input || onDeleted == null) return chip;
    // The remove glyph is its own target over the chip's ink: the end
    // padding, the glyph and half the gap before it, the chip's full height
    // — and, where touch targets are enforced, at least 48dp wide (as
    // Flutter widens a chip's delete button), over the label's end.
    final glyphTarget =
        InputChipBehavior.iconPadding +
        InputChipTokens.trailingIconSize +
        ChipBehavior.compactHorizontalSpacing;
    return Stack(
      children: <Widget>[
        chip,
        PositionedDirectional(
          top: 0,
          bottom: 0,
          end: 0,
          width: ExpressiveMinimumInteractiveSize.enforcedAt(context)
              ? math.max(
                  glyphTarget,
                  HostBehavior.minimumInteractiveComponentSize,
                )
              : glyphTarget,
          child: _RemoveTarget(
            label: deleteLabel,
            chipLabel: label,
            onDeleted: enabled ? onDeleted : null,
          ),
        ),
      ],
    );
  }

  _ChipStyle _styleOf(ExpressiveColorScheme c) {
    Color faded(ExpressiveColorRole role, double alpha) =>
        c.role(role).withValues(alpha: alpha);
    switch (_kind) {
      case _ChipKind.assist:
        return _ChipStyle(
          shape: AssistChipTokens.containerShape,
          font: AssistChipTokens.labelTextFont,
          iconSize: AssistChipTokens.iconSize,
          container: elevated
              ? enabled
                    ? c.role(AssistChipTokens.elevatedContainerColor)
                    : faded(
                        AssistChipTokens.elevatedDisabledContainerColor,
                        AssistChipTokens.elevatedDisabledContainerOpacity,
                      )
              : _clear,
          labelColor: enabled
              ? c.role(AssistChipTokens.labelTextColor)
              : faded(
                  AssistChipTokens.disabledLabelTextColor,
                  AssistChipTokens.disabledLabelTextOpacity,
                ),
          leadingColor: enabled
              ? c.role(AssistChipTokens.iconColor)
              : faded(
                  AssistChipTokens.disabledIconColor,
                  AssistChipTokens.disabledIconOpacity,
                ),
          trailingColor: enabled
              ? c.role(AssistChipTokens.iconColor)
              : faded(
                  AssistChipTokens.disabledIconColor,
                  AssistChipTokens.disabledIconOpacity,
                ),
          side: elevated
              ? BorderSide.none
              : BorderSide(
                  color: enabled
                      ? c.role(AssistChipTokens.flatOutlineColor)
                      : faded(
                          AssistChipTokens.flatDisabledOutlineColor,
                          AssistChipTokens.flatDisabledOutlineOpacity,
                        ),
                  width: AssistChipTokens.flatOutlineWidth,
                ),
          elevation: elevated
              ? const ExpressiveStateElevation(
                  rest: AssistChipTokens.elevatedContainerElevation,
                  pressed: AssistChipTokens.elevatedPressedContainerElevation,
                  focused: AssistChipTokens.elevatedFocusContainerElevation,
                  hovered: AssistChipTokens.elevatedHoverContainerElevation,
                  dragged: AssistChipTokens.draggedContainerElevation,
                  disabled: AssistChipTokens.elevatedDisabledContainerElevation,
                )
              : const ExpressiveStateElevation(
                  rest: AssistChipTokens.flatContainerElevation,
                  dragged: AssistChipTokens.draggedContainerElevation,
                ),
        );
      case _ChipKind.suggestion:
        return _ChipStyle(
          shape: SuggestionChipTokens.containerShape,
          font: SuggestionChipTokens.labelTextFont,
          iconSize: SuggestionChipTokens.leadingIconSize,
          container: elevated
              ? enabled
                    ? c.role(SuggestionChipTokens.elevatedContainerColor)
                    : faded(
                        SuggestionChipTokens.elevatedDisabledContainerColor,
                        SuggestionChipTokens.elevatedDisabledContainerOpacity,
                      )
              : _clear,
          labelColor: enabled
              ? c.role(SuggestionChipTokens.labelTextColor)
              : faded(
                  SuggestionChipTokens.disabledLabelTextColor,
                  SuggestionChipTokens.disabledLabelTextOpacity,
                ),
          leadingColor: enabled
              ? c.role(SuggestionChipTokens.leadingIconColor)
              : faded(
                  SuggestionChipTokens.disabledLeadingIconColor,
                  SuggestionChipTokens.disabledLeadingIconOpacity,
                ),
          trailingColor: _clear,
          side: elevated
              ? BorderSide.none
              : BorderSide(
                  color: enabled
                      ? c.role(SuggestionChipTokens.flatOutlineColor)
                      : faded(
                          SuggestionChipTokens.flatDisabledOutlineColor,
                          SuggestionChipTokens.flatDisabledOutlineOpacity,
                        ),
                  width: SuggestionChipTokens.flatOutlineWidth,
                ),
          elevation: elevated
              ? const ExpressiveStateElevation(
                  rest: SuggestionChipTokens.elevatedContainerElevation,
                  pressed:
                      SuggestionChipTokens.elevatedPressedContainerElevation,
                  focused: SuggestionChipTokens.elevatedFocusContainerElevation,
                  hovered: SuggestionChipTokens.elevatedHoverContainerElevation,
                  dragged: SuggestionChipTokens.draggedContainerElevation,
                  disabled:
                      SuggestionChipTokens.elevatedDisabledContainerElevation,
                )
              : const ExpressiveStateElevation(
                  rest: SuggestionChipTokens.flatContainerElevation,
                  dragged: SuggestionChipTokens.draggedContainerElevation,
                ),
        );
      case _ChipKind.filter:
        final Color container;
        if (elevated) {
          container = enabled
              ? c.role(
                  selected
                      ? FilterChipTokens.elevatedSelectedContainerColor
                      : FilterChipTokens.elevatedUnselectedContainerColor,
                )
              : faded(
                  FilterChipTokens.elevatedDisabledContainerColor,
                  FilterChipTokens.elevatedDisabledContainerOpacity,
                );
        } else if (!selected) {
          container = _clear;
        } else {
          container = enabled
              ? c.role(FilterChipTokens.flatSelectedContainerColor)
              : faded(
                  FilterChipTokens.flatDisabledSelectedContainerColor,
                  FilterChipTokens.flatDisabledSelectedContainerOpacity,
                );
        }
        return _ChipStyle(
          shape: FilterChipTokens.containerShape,
          font: FilterChipTokens.labelTextFont,
          iconSize: FilterChipTokens.iconSize,
          container: container,
          labelColor: !enabled
              ? faded(
                  FilterChipTokens.disabledLabelTextColor,
                  FilterChipTokens.disabledLabelTextOpacity,
                )
              : c.role(
                  selected
                      ? FilterChipTokens.selectedLabelTextColor
                      : FilterChipTokens.unselectedLabelTextColor,
                ),
          leadingColor: !enabled
              ? faded(
                  FilterChipTokens.disabledLeadingIconColor,
                  FilterChipTokens.disabledLeadingIconOpacity,
                )
              : c.role(
                  selected
                      ? FilterChipTokens.selectedLeadingIconColor
                      : FilterChipTokens.unselectedLeadingIconColor,
                ),
          trailingColor: !enabled
              ? faded(
                  FilterChipTokens.disabledTrailingIconColor,
                  FilterChipTokens.disabledTrailingIconOpacity,
                )
              : c.role(
                  selected
                      ? FilterChipTokens.selectedTrailingIconColor
                      : FilterChipTokens.unselectedTrailingIconColor,
                ),
          side: elevated || selected
              ? BorderSide.none
              : BorderSide(
                  color: enabled
                      ? c.role(FilterChipTokens.flatUnselectedOutlineColor)
                      : faded(
                          FilterChipTokens.flatDisabledUnselectedOutlineColor,
                          FilterChipTokens.flatDisabledUnselectedOutlineOpacity,
                        ),
                  width: FilterChipTokens.flatUnselectedOutlineWidth,
                ),
          elevation: elevated
              ? const ExpressiveStateElevation(
                  rest: FilterChipTokens.elevatedContainerElevation,
                  pressed: FilterChipTokens.elevatedPressedContainerElevation,
                  focused: FilterChipTokens.elevatedFocusContainerElevation,
                  hovered: FilterChipTokens.elevatedHoverContainerElevation,
                  dragged: FilterChipTokens.draggedContainerElevation,
                  disabled: FilterChipTokens.elevatedDisabledContainerElevation,
                )
              : const ExpressiveStateElevation(
                  rest: FilterChipTokens.flatContainerElevation,
                  pressed:
                      FilterChipTokens.flatSelectedPressedContainerElevation,
                  focused: FilterChipTokens.flatSelectedFocusContainerElevation,
                  hovered: FilterChipTokens.flatSelectedHoverContainerElevation,
                  dragged: FilterChipTokens.draggedContainerElevation,
                ),
        );
      case _ChipKind.input:
        final Color container;
        if (!selected) {
          container = _clear;
        } else {
          container = enabled
              ? c.role(InputChipTokens.selectedContainerColor)
              : faded(
                  InputChipTokens.disabledSelectedContainerColor,
                  InputChipTokens.disabledSelectedContainerOpacity,
                );
        }
        return _ChipStyle(
          shape: InputChipTokens.containerShape,
          font: InputChipTokens.labelTextFont,
          iconSize: InputChipTokens.leadingIconSize,
          container: container,
          labelColor: !enabled
              ? faded(
                  InputChipTokens.disabledLabelTextColor,
                  InputChipTokens.disabledLabelTextOpacity,
                )
              : c.role(
                  selected
                      ? InputChipTokens.selectedLabelTextColor
                      : InputChipTokens.unselectedLabelTextColor,
                ),
          leadingColor: !enabled
              ? faded(
                  InputChipTokens.disabledLeadingIconColor,
                  InputChipTokens.disabledLeadingIconOpacity,
                )
              : c.role(
                  selected
                      ? InputChipTokens.selectedLeadingIconColor
                      : InputChipTokens.unselectedLeadingIconColor,
                ),
          trailingColor: !enabled
              ? faded(
                  InputChipTokens.disabledTrailingIconColor,
                  InputChipTokens.disabledTrailingIconOpacity,
                )
              : c.role(
                  selected
                      ? InputChipTokens.selectedTrailingIconColor
                      : InputChipTokens.unselectedTrailingIconColor,
                ),
          side: selected
              ? BorderSide.none
              : BorderSide(
                  color: enabled
                      ? c.role(InputChipTokens.unselectedOutlineColor)
                      : faded(
                          InputChipTokens.disabledUnselectedOutlineColor,
                          InputChipTokens.disabledUnselectedOutlineOpacity,
                        ),
                  width: InputChipTokens.unselectedOutlineWidth,
                ),
          elevation: const ExpressiveStateElevation(
            rest: InputChipTokens.containerElevation,
            dragged: InputChipTokens.draggedContainerElevation,
          ),
        );
    }
  }
}

/// What one chip draws with: its `*Defaults`' colours, border and
/// elevation for its state.
class _ChipStyle {
  const _ChipStyle({
    required this.shape,
    required this.font,
    required this.iconSize,
    required this.container,
    required this.labelColor,
    required this.leadingColor,
    required this.trailingColor,
    required this.side,
    required this.elevation,
  });

  final ExpressiveShapeKey shape;
  final ExpressiveTypeKey font;
  final double iconSize;
  final Color container;
  final Color labelColor;
  final Color leadingColor;
  final Color trailingColor;
  final BorderSide side;
  final ExpressiveStateElevation elevation;

  /// This with [theme]'s slots for [states] over it: the content slot
  /// paints the label and both icons, the outline slot recolours the
  /// outline where there is one.
  _ChipStyle themed(
    ExpressiveComponentThemeData theme,
    Set<WidgetState> states,
  ) {
    if (theme.isEmpty) return this;
    Color content(Color fallback) => ExpressiveComponentThemeData.resolve(
      theme.foregroundColor,
      states,
      fallback,
    );
    return _ChipStyle(
      shape: shape,
      font: font,
      iconSize: iconSize,
      container: ExpressiveComponentThemeData.resolve(
        theme.backgroundColor,
        states,
        container,
      ),
      labelColor: content(labelColor),
      leadingColor: content(leadingColor),
      trailingColor: content(trailingColor),
      side: side.style == BorderStyle.none || side.width <= 0
          ? side
          : side.copyWith(
              color: ExpressiveComponentThemeData.resolve(
                theme.outline,
                states,
                side.color,
              ),
            ),
      elevation: elevation,
    );
  }
}

/// An icon slot of a selectable chip (`AnimatingChipContent`): it springs
/// open from its edge and fades in when it gains content, and closes and
/// fades out when it loses it, keeping the last content while it goes
/// (`rememberRetainedState`). Compose's specs: expand fast spatial, fade in
/// slow effects, shrink default effects, fade out fast effects; the
/// morphing overload fades both ways on default effects and shrinks on
/// fast spatial.
class _ChipSlot extends StatefulWidget {
  const _ChipSlot({
    required this.alignment,
    required this.morph,
    required this.child,
  });

  final AlignmentDirectional alignment;
  final bool morph;
  final Widget? child;

  @override
  State<_ChipSlot> createState() => _ChipSlotState();
}

class _ChipSlotState extends State<_ChipSlot> {
  Widget? _retained;

  @override
  Widget build(BuildContext context) {
    final visible = widget.child != null;
    if (visible) _retained = widget.child;
    final target = visible ? 1.0 : 0.0;
    final sizeMotion = visible || widget.morph
        ? ExpressiveMotionKey.fastSpatial
        : ExpressiveMotionKey.defaultEffects;
    final ExpressiveMotionKey fadeMotion;
    if (widget.morph) {
      fadeMotion = ExpressiveMotionKey.defaultEffects;
    } else {
      fadeMotion = visible
          ? ExpressiveMotionKey.slowEffects
          : ExpressiveMotionKey.fastEffects;
    }
    return ExpressiveSpringValue(
      value: target,
      motion: sizeMotion,
      builder: (context, size, _) => ExpressiveSpringValue(
        value: target,
        motion: fadeMotion,
        builder: (context, alpha, _) {
          final retained = _retained;
          if (retained == null || (!visible && size <= 0)) {
            return const SizedBox.shrink();
          }
          return ClipRect(
            child: Align(
              alignment: widget.alignment,
              widthFactor: size.clamp(0.0, 1.0),
              heightFactor: 1,
              child: Opacity(opacity: alpha.clamp(0.0, 1.0), child: retained),
            ),
          );
        },
      ),
    );
  }
}

/// An input chip's remove target: over its close glyph, announced as
/// removing the chip.
class _RemoveTarget extends StatelessWidget {
  const _RemoveTarget({
    required this.label,
    required this.chipLabel,
    required this.onDeleted,
  });

  final String? label;
  final String chipLabel;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onDeleted != null,
    label: label ?? ExpressiveLocalizations.of(context).removeChip(chipLabel),
    // No layer of its own (Compose's InputChip trailing icon has no
    // indication): a square over the glyph's target would be a box nothing
    // on screen explains. The pointer still says it presses, as the chip's
    // body says it: the adaptive clickable cursor (the hand on the web, the
    // platform's arrow in a desktop app).
    child: MouseRegion(
      cursor: onDeleted == null
          ? MouseCursor.defer
          : WidgetStateMouseCursor.adaptiveClickable,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDeleted,
      ),
    ),
  );
}

/// Chips in a row: flowing onto more lines when they do not fit (Compose's
/// `FlowRow` the chip samples use), or, [scrollable], one line that
/// scrolls sideways. 8dp apart (`ChipBehavior.horizontalSpacing`); lines
/// sit on the chips' 48dp touch targets.
///
/// A scrolling row belongs edge to edge, so the chips cut off at the
/// screen's edge rather than at the page's margin (which reads as
/// truncation): place it outside the page's padding and give that padding
/// to [padding], inside the scroll.
///
/// ```dart
/// ExpressiveChipRow(children: [ExpressiveChip('Open now', selected: open, onPressed: () => setState(() => open = !open))])
/// ```
class ExpressiveChipRow extends StatelessWidget {
  /// A row of chip [children], flowing onto more lines or, when [scrollable], scrolling sideways.
  const ExpressiveChipRow({
    required this.children,
    this.scrollable = false,
    this.padding,
    super.key,
  });

  /// The chips, in reading order.
  final List<Widget> children;

  /// One sideways-scrolling line instead of wrapping.
  final bool scrollable;

  /// Space around the chips inside the scroll ([scrollable] only): the
  /// page's side margin, so the first and last chip line up with the page
  /// at rest and the chips scroll to the screen's edge.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (!scrollable) {
      return Wrap(
        spacing: ChipBehavior.horizontalSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(spacing: ExpressiveSpacing.s8, children: children),
    );
  }
}
