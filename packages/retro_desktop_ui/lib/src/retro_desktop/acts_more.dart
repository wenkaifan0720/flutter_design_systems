// Round 4's actions: a button group, a toggle group and a split button. The toggle group and the split button stand
// on ui_core's behaviour (keys, focus, semantics, the menu); this file only paints them.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'controls.dart' show RetroDesktopTriangleMark;
import 'internal/face.dart';
import 'internal/parts.dart';

import 'layout.dart' show RetroDesktopReach;
import 'press.dart';
import 'theme.dart';
import 'internal/caps.dart';

/// How far a joined strip's frame stands in from its segments' reach, above
/// and below: the strip shows a button's height (beside one, the same top and
/// bottom), while each segment keeps a finger's reach.
double _stripInset(BuildContext context) => math.max(
  0,
  (RetroDesktopReach.least(context) - retroDesktopButtonFaceHeight(context)) /
      2,
);

/// A segment's reach around what it shows: the frame's inset and its rim
/// above and below [shown]. To the shared checks a segment is its band of the
/// frame (rim included), what the eye reads as its top and bottom: the frame
/// is drawn behind the segments, and its outline read from the pixels of one
/// segment's reach moved with what stood around the strip.
Widget _cell(BuildContext context, Widget shown) => Padding(
  padding: EdgeInsets.symmetric(vertical: _stripInset(context)),
  child: DesignKeylineFace(
    child: Padding(
      padding: EdgeInsets.symmetric(
        vertical: retroDesktopFaceRim(RetroDesktopTheme.of(context)),
      ),
      child: shown,
    ),
  ),
);

/// The frame joined segments share: one raised face, a rule between them,
/// a button's height; the segments' reach runs past it above and below.
Widget _joined(BuildContext context, List<Widget> segments) {
  final t = RetroDesktopTheme.of(context);
  final c = t.colors;
  final inset = _stripInset(context);
  final rim = retroDesktopFaceRim(t);
  // In a column too narrow for it, the strip shrinks whole: its segments stay
  // joined, on one line.
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Stack(
      children: [
        Positioned.fill(
          top: inset,
          bottom: inset,
          child: retroDesktopFace(
            states: const {},
            scale: RetroDesktopFaceScale.button,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.platinumLight, c.platinum],
            ),
            component: t.buttonTheme.merge(
              RetroDesktopStyle(
                textStyle: WidgetStatePropertyAll(t.type.chrome),
              ),
            ),
            padding: EdgeInsets.zero,
            child: const SizedBox.expand(),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rim),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < segments.length; i++) ...[
                  if (i > 0)
                    // Outline to outline, as a held segment's well runs: stopped at the bevel, it left a notch of the
                    // frame's light above the rule beside a held one.
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: inset + (t.chisel ? rim : t.strokes.regular),
                      ),
                      child: SizedBox(
                        width: t.strokes.regular == 0 ? 1 : t.strokes.regular,
                        child: ColoredBox(color: c.outline),
                      ),
                    ),
                  segments[i],
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// One segment's words and glyph on its ground: held or chosen, the appearance's
/// press (Platinum's darker grey, Chisel's sunken face).
Widget _segment(
  BuildContext context,
  Set<WidgetState> states, {
  String? label,
  IconData? icon,
  bool chosen = false,
  Widget? trailing,
}) {
  final t = RetroDesktopTheme.of(context);
  final c = t.colors;
  final disabled = states.contains(WidgetState.disabled);
  final ink = disabled ? c.textTertiary : c.text;
  // The segment fills its cell inside the frame (a button's height less the
  // rim), so a held or chosen ground covers the whole cell between the rules.
  final least = RetroDesktopReach.least(context);
  return retroDesktopHeldGround(
    t,
    held: chosen || states.contains(WidgetState.pressed),
    // Over the frame's bevel, to its outline.
    bleed: t.strokes.hairline,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight:
            retroDesktopButtonFaceHeight(context) - 2 * retroDesktopFaceRim(t),
        minWidth: least,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 16, color: ink),
            if (icon != null && label != null) const SizedBox(width: 6),
            if (label != null)
              Flexible(
                child: RetroDesktopCaps(
                  style: t.type.chrome,
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.type.chrome.copyWith(color: ink),
                  ),
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

/// One action of a [RetroDesktopButtonGroup]: words, a glyph, or both.
@immutable
class RetroDesktopButtonGroupItem {
  /// Creates a [RetroDesktopButtonGroupItem].
  const RetroDesktopButtonGroupItem({
    this.label,
    this.icon,
    this.onPressed,
    this.tooltip,
  }) : assert(label != null || icon != null);

  /// The words on the segment.
  final String? label;

  /// The glyph on the segment.
  final IconData? icon;

  /// Called when the segment is pressed; null makes it unavailable.
  final VoidCallback? onPressed;

  /// The accessible name of a glyph-only segment.
  final String? tooltip;
}

/// Actions joined edge to edge in one frame, as the period's toolbars joined
/// back and forward, or bold, italic and underline. Each segment presses on
/// its own; none stays chosen (that is a [RetroDesktopToggleGroup]).
///
/// ```dart
/// RetroDesktopButtonGroup(items: [RetroDesktopButtonGroupItem(icon: RetroDesktopGlyphs.chevronLeft, tooltip: 'Back', onPressed: () {}), RetroDesktopButtonGroupItem(icon: RetroDesktopGlyphs.chevronRight, tooltip: 'Forward', onPressed: () {})])
/// ```
class RetroDesktopButtonGroup extends StatelessWidget {
  /// Creates a [RetroDesktopButtonGroup].
  const RetroDesktopButtonGroup({super.key, required this.items, this.label});

  /// The segments in reading order.
  final List<RetroDesktopButtonGroupItem> items;

  /// The group's accessible name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: _joined(context, [
        for (final item in items)
          RetroDesktopPressable(
            label: item.label ?? item.tooltip,
            onPressed: item.onPressed,
            ringInside: true,
            focusShape: retroDesktopItemShape(t),
            builder: (context, states) => _cell(
              context,
              _segment(context, states, label: item.label, icon: item.icon),
            ),
          ),
      ]),
    );
  }
}

/// Toggles joined in one frame: each chosen one stays held in, as a toolbar's
/// bold or a view switch did. One or many ([multiple]); the arrow keys move
/// along it. ui_core's toggle group carries the keys, focus and semantics.
///
/// ```dart
/// RetroDesktopToggleGroup<String>(values: const ['b', 'i', 'u'], selected: const {'b'}, labelOf: (v) => v.toUpperCase(), multiple: true, onChanged: (_) {})
/// ```
class RetroDesktopToggleGroup<T> extends StatelessWidget {
  /// Creates a [RetroDesktopToggleGroup].
  const RetroDesktopToggleGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.iconOf,
    this.showLabels = true,
    this.multiple = false,
    this.allowEmpty = false,
    this.isEnabled,
    this.label,
  });

  /// The values in reading order.
  final List<T> values;

  /// The values held in.
  final Set<T> selected;

  /// Reports the new set; null disables the group.
  final ValueChanged<Set<T>>? onChanged;

  /// Each value's words (its accessible name when [showLabels] is false).
  final String Function(T value) labelOf;

  /// Each value's glyph, if any.
  final IconData? Function(T value)? iconOf;

  /// Whether the words stand on the segments; false shows glyphs alone.
  final bool showLabels;

  /// Whether more than one can be held in at once.
  final bool multiple;

  /// Whether none may be held in.
  final bool allowEmpty;

  /// Whether a value can be toggled; null enables every one.
  final bool Function(T value)? isEnabled;

  /// The group's accessible name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final least = RetroDesktopReach.least(context);
    return DesignToggleGroup<T>(
      options: values,
      selected: selected,
      onSelectionChanged: onChanged,
      multiSelectionEnabled: multiple,
      emptySelectionAllowed: allowEmpty,
      isEnabled: isEnabled,
      labelOf: labelOf,
      semanticLabel: label,
      minimumSize: Size(least, least),
      layoutBuilder: (context, items) => _joined(context, items),
      itemBuilder: (context, value, states) {
        final t = RetroDesktopTheme.of(context);
        final focused = states.contains(WidgetState.focused);
        final face = _segment(
          context,
          states,
          label: showLabels ? labelOf(value) : null,
          icon: iconOf?.call(value),
          chosen: states.contains(WidgetState.selected),
        );
        return _cell(
          context,
          Opacity(
            opacity: states.contains(WidgetState.disabled) ? .5 : 1,
            child: RetroDesktopHighlight(
              shape: retroDesktopItemShape(t),
              focused: focused,
              inside: true,
              child: face,
            ),
          ),
        );
      },
    );
  }
}

/// A button with its own menu: the main action on its face, the others behind
/// the arrow beside it. ui_core's split button carries the menu, its keys and
/// focus.
///
/// ```dart
/// RetroDesktopSplitButton(label: 'Save', onPressed: () {}, actions: [DesignSplitAction(label: 'Save as…', onPressed: () {})])
/// ```
class RetroDesktopSplitButton extends StatelessWidget {
  /// Creates a [RetroDesktopSplitButton].
  const RetroDesktopSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.icon,
    this.menuLabel,
  });

  /// The main action's words.
  final String label;

  /// The main action; null disables the button.
  final VoidCallback? onPressed;

  /// The other actions, in the menu's order.
  final List<DesignSplitAction> actions;

  /// The main action's glyph.
  final IconData? icon;

  /// The arrow's accessible name.
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final least = RetroDesktopReach.least(context);
    return DesignSplitButton(
      label: label,
      onPressed: onPressed,
      // A disabled button is disabled whole: its arrow doesn't open either.
      actions: onPressed == null ? const [] : actions,
      menuLabel:
          menuLabel ?? DesignLocalizations.of(context).splitButtonMenuLabel,
      minimumSize: Size(least, least),
      layoutBuilder: (context, main, toggle) =>
          _joined(context, [main, toggle]),
      buttonBuilder: (context, part, states, open) {
        final t = RetroDesktopTheme.of(context);
        final face = part == DesignSplitPart.main
            ? _segment(context, states, label: label, icon: icon)
            : _segment(
                context,
                {...states, if (open) WidgetState.pressed},
                trailing: const RetroDesktopTriangleMark(
                  AxisDirection.down,
                  size: 8,
                ),
              );
        return _cell(
          context,
          Opacity(
            opacity: states.contains(WidgetState.disabled) ? .5 : 1,
            child: RetroDesktopHighlight(
              shape: retroDesktopItemShape(t),
              focused: states.contains(WidgetState.focused),
              inside: true,
              child: face,
            ),
          ),
        );
      },
      // The keyboard's row is lit, or the row under the pointer, from rim to rim (see RetroDesktopMenuBar).
      itemBuilder: (context, action, states) => retroDesktopLitRow(
        context,
        lit:
            action.onPressed != null &&
            (states.contains(WidgetState.hovered) ||
                (states.contains(WidgetState.focused) &&
                    RetroDesktopLastInput.byKey)),
        enabled: action.onPressed != null,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: RetroDesktopCaps(Text(action.label)),
      ),
      surfaceBuilder: (context, info, items) =>
          _menuPanel(context, info, items),
    );
  }
}

/// A menu's panel under its anchor, growing from it as the menu opens.
Widget _menuPanel(
  BuildContext context,
  DesignOverlayInfo info,
  List<Widget> items,
) => FadeTransition(
  opacity: info.animation,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: 160,
      maxWidth: info.maxSize.width,
      maxHeight: info.maxSize.height,
    ),
    child: retroDesktopPanel(
      context,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        ),
      ),
    ),
  ),
);
