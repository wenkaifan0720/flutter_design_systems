import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';
import '../menu/menu.dart';

// A row's caller may open and shut it from outside.
export 'package:ui_core/ui_core.dart' show RawSwipeActionsController;

/// An action a [CivicSwipeActions] row holds: its words, what it runs, a
/// glyph beside the words, and whether it destroys something.
@immutable
class CivicSwipeAction {
  /// An action worded [label] that [onPressed] runs.
  const CivicSwipeAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
  });

  /// What it does, in words: "Archive", "Withdraw".
  final String label;

  /// Runs it.
  final VoidCallback onPressed;

  /// A glyph over the words on its ground; the words always say it.
  final IconData? icon;

  /// Whether it destroys something: a red ground, and a full swipe slides
  /// the row away first.
  final bool isDestructiveAction;
}

/// A row with actions behind it, a swipe away: [endActions] behind its end
/// edge (a swipe toward the start shows them) and [startActions] behind
/// its start. Each stands on a worded ground (the action colour, slate,
/// or red for one that destroys something), its glyph over its words. A
/// pointer over one deepens its ground; a keyboard focus lays it on the
/// yellow plate over the ink bar.
///
/// Swiping is a shortcut, never the only way: with [inSight] (the
/// default) the row carries a "More actions" button at its end whose menu
/// holds the same actions, for a pointer, the keys and anyone who never
/// thinks to swipe. With the keyboard in the row, the arrow keys open a
/// side and Escape shuts it; a screen reader has them as the row's own
/// actions. ui_core's [RawSwipeActions], Civic's painting.
///
/// Reads [CivicStyle]'s fill (an ordinary action's ground, by state) and
/// foreground (its words): its `style:`, then
/// [CivicThemeData.swipeActionsStyle].
///
/// ```dart
/// CivicSwipeActions(
///   menuLabel: 'Actions for Resident permit',
///   endActions: [
///     CivicSwipeAction(label: 'Archive', onPressed: () {}),
///     CivicSwipeAction(
///       label: 'Withdraw',
///       onPressed: () {},
///       isDestructiveAction: true,
///     ),
///   ],
///   child: CivicListRow(title: Text('Resident permit')),
/// )
/// ```
class CivicSwipeActions extends StatelessWidget {
  /// [child] with actions behind its edges.
  const CivicSwipeActions({
    super.key,
    required this.child,
    required this.menuLabel,
    this.startActions = const [],
    this.endActions = const [],
    this.inSight = true,
    this.fullSwipe = false,
    this.initiallyOpen = false,
    this.onOpenChanged,
    this.controller,
    this.style,
  });

  /// The row.
  final Widget child;

  /// What a screen reader calls the in-sight menu's button: "Actions for
  /// Resident permit".
  final String menuLabel;

  /// The actions a swipe toward the end shows, the first at the edge.
  final List<CivicSwipeAction> startActions;

  /// The actions a swipe toward the start shows, the first at the edge.
  final List<CivicSwipeAction> endActions;

  /// Whether the row carries a "More actions" button holding the same
  /// actions. Turn it off only where the actions are in sight elsewhere on
  /// the page.
  final bool inSight;

  /// Whether a swipe past most of the row runs the edge action.
  final bool fullSwipe;

  /// Whether it starts with a side open, as a one-time hint that the row
  /// swipes.
  final bool initiallyOpen;

  /// Called as a side opens (true) or the row shuts (false).
  final ValueChanged<bool>? onOpenChanged;

  /// Opens and shuts it from outside; the caller's.
  final RawSwipeActionsController? controller;

  /// Overrides for this row's look.
  final CivicStyle? style;

  RawSwipeAction _design(CivicSwipeAction a) => RawSwipeAction(
    label: a.label,
    onPressed: a.onPressed,
    destructive: a.isDestructiveAction,
    data: a,
  );

  @override
  Widget build(BuildContext context) {
    final all = [...endActions, ...startActions];
    final row = !inSight || all.isEmpty
        ? child
        : Row(
            children: [
              Expanded(child: child),
              CivicMenu<CivicSwipeAction>(
                semanticLabel: menuLabel,
                align: RawPopoverAlign.end,
                items: [
                  for (final a in all)
                    CivicMenuItem(
                      value: a,
                      label: a.label,
                      icon: a.icon,
                      isDestructiveAction: a.isDestructiveAction,
                    ),
                ],
                onSelected: (a) => a.onPressed(),
                builder: (context, anchor) => CivicIconButton(
                  icon: LucideIcons.ellipsisVertical,
                  semanticLabel: menuLabel,
                  tooltip: menuLabel,
                  onPressed: anchor.toggle,
                ),
              ),
            ],
          );
    return RawSwipeActions(
      startActions: [for (final a in startActions) _design(a)],
      endActions: [for (final a in endActions) _design(a)],
      actionExtent: 88,
      fullSwipe: fullSwipe,
      initiallyOpen: initiallyOpen,
      onOpenChanged: onOpenChanged,
      controller: controller,
      dampingRatio: CivicMotion.panel.dampingRatio,
      stiffness: CivicMotion.panel.stiffness,
      actionBuilder: (context, action, details) => _Ground(
        action: action.data! as CivicSwipeAction,
        details: details,
        style: style,
      ),
      child: row,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>(
          'startActions',
          startActions.map((a) => a.label),
        ),
      )
      ..add(
        IterableProperty<String>('endActions', endActions.map((a) => a.label)),
      )
      ..add(FlagProperty('inSight', value: inSight, ifFalse: 'not in sight'))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _Ground extends StatelessWidget {
  const _Ground({
    required this.action,
    required this.details,
    required this.style,
  });

  final CivicSwipeAction action;
  final RawSwipeActionDetails details;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final states = details.states;
    final so = RawStyleOf([style, t.swipeActionsStyle], states);
    final danger = action.isDestructiveAction;
    // The edge action on the action colour, the next on slate, one that
    // destroys something on red.
    final (Color ground, Color words) = danger
        ? (t.danger, t.onDanger)
        : details.index.isEven
        ? (so.fill ?? t.action, so.foreground ?? t.onAction)
        : (t.textSecondary, t.background);
    final wash = states.contains(WidgetState.pressed)
        ? 1.0
        : states.contains(WidgetState.hovered) || details.armed
        ? 0.5
        : 0.0;
    final icon = action.icon;
    return CivicSpringValue(
      value: wash,
      spring: CivicMotion.press,
      builder: (context, w, _) => CivicSpringValue(
        value: states.contains(WidgetState.focused) ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) {
          final face = Color.lerp(
            Color.lerp(ground, t.textPrimary, 0.3 * w)!,
            t.focus,
            focus,
          )!;
          final ink = Color.lerp(words, t.onFocus, focus)!;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: face,
              // The focus's thick dark bar along the foot.
              border: Border(
                bottom: BorderSide(
                  color: t.focusBar.withValues(alpha: focus),
                  width: CivicMetrics.bar,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: details.underlap),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CivicSpacing.s8,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: CivicSpacing.s4,
                      children: [
                        if (icon != null) Icon(icon, size: 24, color: ink),
                        Text(
                          action.label,
                          maxLines: 1,
                          style: text.label.copyWith(color: ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
