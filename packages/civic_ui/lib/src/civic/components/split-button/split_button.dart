import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/button_face.dart';
import '../../internal/menu_row.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../tooltip/tooltip.dart';

/// One of a [CivicSplitButton]'s other actions: its [label] on a menu row,
/// what it runs ([onPressed]; null disables it), a glyph before it
/// ([icon]), the error colour when it destroys something
/// ([isDestructiveAction]).
///
/// ```dart
/// CivicSplitAction('Save and come back later', onPressed: () {})
/// ```
@immutable
class CivicSplitAction {
  /// An action worded [label] that runs [onPressed].
  const CivicSplitAction(
    this.label, {
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
  });

  /// What it does, in words.
  final String label;

  /// Runs it, once the menu has closed; null disables it.
  final VoidCallback? onPressed;

  /// A glyph before [label].
  final IconData? icon;

  /// Whether it destroys something: its words in the error colour.
  final bool isDestructiveAction;
}

/// An action ([label], [onPressed]) with, joined to it, a narrow face whose
/// chevron opens a menu of the actions like it ([actions]): Send now, and
/// in the menu Send later or Save as a draft. Two buttons in Civic's
/// material, two tap targets and two tab stops: ui_core's
/// [RawSplitButton], Civic's painting.
///
/// The unnamed constructor is the page's one action (solid in the action
/// colour); [CivicSplitButton.secondary] stands beside it in the action's
/// tint. The chevron's face is named for a screen reader and shown as a
/// tooltip ([menuLabel]: "More options" by default; name it where a page
/// has two). Down on either half opens the menu; a pointer greys a row and
/// the keys move the yellow plate; Escape closes it and the focus goes back
/// to the chevron. The chevron turns while the menu is open. The halves
/// share one height however the action's words wrap. Below 600 wide the
/// action spans its column as a phone's does, the chevron at its end; from
/// 600 the pair keeps its words' width at the column's start, and the menu
/// is as wide as its widest row and at least the pair. Disabled
/// ([onPressed] null), both halves are.
///
/// The menu's actions are lesser ones, each also reachable on the page or
/// in the service (a menu is never the only way to do a thing).
///
/// Reads the buttons' styles ([CivicThemeData.primaryButtonStyle],
/// [CivicThemeData.secondaryButtonStyle]) under its `style:` for both
/// halves (their `corners` the pair's outer ones: the seam's stay small),
/// and [CivicThemeData.menuStyle] for the menu.
///
/// ```dart
/// CivicSplitButton(
///   label: 'Send application',
///   onPressed: () {},
///   actions: [
///     CivicSplitAction('Save and come back later', onPressed: () {}),
///     CivicSplitAction('Print your answers', onPressed: () {}),
///   ],
/// )
/// ```
class CivicSplitButton extends StatelessWidget {
  /// The page's action, with [actions] in its menu.
  const CivicSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.expand,
    this.style,
    this.controller,
  }) : _secondary = false;

  /// An action beside the page's one, with [actions] in its menu.
  const CivicSplitButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
    this.expand,
    this.style,
    this.controller,
  }) : _secondary = true;

  final bool _secondary;

  /// The main action's words.
  final String label;

  /// The main action; null disables both halves.
  final VoidCallback? onPressed;

  /// The menu's actions, in order.
  final List<CivicSplitAction> actions;

  /// What a screen reader and the tooltip call the chevron's face; null:
  /// [RawWidgetsLocalizations.splitButtonMenuLabel] ("More options").
  final String? menuLabel;

  /// Whether the action spans its column; null spans it below 600 wide.
  final bool? expand;

  /// Overrides for both halves' look, over the button kind's theme.
  final CivicStyle? style;

  /// Opens and closes the menu from outside; null: its own.
  final MenuController? controller;

  @override
  Widget build(BuildContext context) {
    final kind = _secondary
        ? CivicButtonKind.secondary
        : CivicButtonKind.primary;
    final words =
        menuLabel ?? RawWidgetsLocalizations.of(context).splitButtonMenuLabel;
    final width = MediaQuery.maybeSizeOf(context)?.width ?? 1024;
    final stretch = expand ?? width < CivicLayout.medium;
    final glyphs = actions.any((a) => a.icon != null);
    final split = RawSplitButton(
      label: label,
      onPressed: onPressed,
      menuLabel: words,
      controller: controller,
      highlightFollowsPointer: false,
      minimumSize: const Size.square(CivicMetrics.controlHeight),
      // Under the pair from the action's start: a menu wider than the pair
      // grows toward the column's room, not past its start.
      placement: const RawPopoverPlacement(
        align: RawPopoverAlign.start,
        gap: CivicSpacing.s8,
        preferredExtent: 240,
      ),
      // Disabled, both halves are: a menu of an action that can't be taken
      // stays shut.
      actions: [
        if (onPressed != null)
          for (final a in actions)
            RawSplitAction(label: a.label, onPressed: a.onPressed, data: a),
      ],
      // The two halves share one height, however the action's words wrap.
      layoutBuilder: (context, main, toggle) => IntrinsicHeight(
        child: Row(
          mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // A seam of the page between the two faces: two buttons, joined.
          spacing: 2,
          children: [
            if (stretch) Expanded(child: main) else Flexible(child: main),
            CivicTooltip(
              message: words,
              excludeFromSemantics: true,
              child: toggle,
            ),
          ],
        ),
      ),
      // The pressable centres a face at its own size: each is told to take
      // its slot's height, and spanning, the action its width.
      buttonBuilder: (context, part, states, open) => SizedBox(
        width: stretch && part == RawSplitPart.main ? double.infinity : null,
        height: double.infinity,
        child: switch (part) {
          RawSplitPart.main => CivicButtonFace(
            states: states,
            kind: kind,
            style: style,
            outerEnd: false,
            child: Text(label),
          ),
          RawSplitPart.toggle => CivicButtonFace(
            states: states,
            kind: kind,
            style: style,
            outerStart: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CivicSpacing.s12,
            ),
            child: CivicSpringValue(
              value: open ? 1 : 0,
              spring: CivicMotion.state,
              builder: (context, turn, _) => Transform.rotate(
                angle: turn * math.pi,
                child: const Icon(LucideIcons.chevronDown, size: 24),
              ),
            ),
          ),
        },
      ),
      itemBuilder: (context, action, states) {
        final a = action.data! as CivicSplitAction;
        return CivicMenuRow(
          label: a.label,
          states: states,
          icon: a.icon,
          glyphColumn: glyphs,
          destructive: a.isDestructiveAction,
        );
      },
      surfaceBuilder: (context, info, items) => civicRise(
        animation: info.animation,
        fromAbove: info.side == RawPopoverSide.below,
        child: CivicMenuPanel(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: info.maxSize.height),
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
    // Beside its column's start, its menu measured from the two faces, not
    // from the column.
    return stretch
        ? split
        : Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: split,
          );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(IterableProperty<CivicSplitAction>('actions', actions))
      ..add(StringProperty('menuLabel', menuLabel, defaultValue: null))
      ..add(FlagProperty('secondary', value: _secondary, ifTrue: 'secondary'))
      ..add(DiagnosticsProperty<bool>('expand', expand, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
