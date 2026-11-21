// Round 4's actions: a button group, a toggle group and a split button. The toggle group and the split button stand
// on ui_core's behaviour (keys, focus, semantics, the menu); this file only paints them.
import 'package:flutter/foundation.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'controls.dart' show RetroDesktopTriangleMark;
import 'internal/face.dart';
import 'internal/parts.dart';
import 'internal/presence.dart';

import 'layout.dart' show RetroDesktopReach;
import 'press.dart';
import 'shapes.dart';
import 'theme.dart';
import 'internal/caps.dart';
import 'tokens.dart';

/// How far a joined strip's frame stands in from its segments' reach, above
/// and below: the strip shows a button's height (beside one, the same top and
/// bottom), while each segment keeps a finger's reach.
double _stripInset(BuildContext context) => math.max(
  0,
  (RetroDesktopReach.least(context) - retroDesktopButtonFaceHeight(context)) /
      2,
);

// The painted face sits inside the segment's pointer target.
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
  // The frame's outline, for the segments at its ends: a held one's well meets
  // it there concentric (Platinum's rounded frame; Chisel's is square).
  final frame =
      RetroDesktopStyle.first<OutlinedBorder>(
        [t.buttonTheme],
        (s) => s.shape,
        const {},
      ) ??
      t.shapes.button;
  final rtl = Directionality.of(context) == TextDirection.rtl;
  Widget placed(int i) {
    final first = i == 0, last = i == segments.length - 1;
    final left = rtl ? last : first, right = rtl ? first : last;
    if (t.chisel || frame is! RoundedRectangleBorder || !(left || right)) {
      return segments[i];
    }
    final r = frame.borderRadius.resolve(TextDirection.ltr);
    return _JoinedEnd(
      outline: RoundedRectangleBorder(
        side: BorderSide(width: t.strokes.regular),
        borderRadius: BorderRadius.only(
          topLeft: left ? r.topLeft : Radius.zero,
          bottomLeft: left ? r.bottomLeft : Radius.zero,
          topRight: right ? r.topRight : Radius.zero,
          bottomRight: right ? r.bottomRight : Radius.zero,
        ),
      ),
      left: left,
      right: right,
      child: segments[i],
    );
  }

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
            component: t.buttonTheme.over(
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
                  placed(i),
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
  final held = chosen || states.contains(WidgetState.pressed);
  final shown = ConstrainedBox(
    constraints: BoxConstraints(
      minHeight:
          retroDesktopButtonFaceHeight(context) - 2 * retroDesktopFaceRim(t),
      minWidth: least,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RetroDesktopSpacing.s10,
        vertical: RetroDesktopSpacing.s4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 16, color: ink),
          if (icon != null && label != null)
            const SizedBox(width: RetroDesktopSpacing.s6),
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
  );
  // Read where the segment stands once it is placed in its strip: at an end,
  // its well runs over the frame's bevel to the outline on that side too, and
  // takes the frame's corner less the outline (concentric, as a cell of a
  // segmented button), not a square corner inside a rounded one.
  return Builder(
    builder: (context) {
      final end = context.dependOnInheritedWidgetOfExactType<_JoinedEnd>();
      final bleed = t.strokes.hairline;
      RetroDesktopHighlightClaim.maybeOf(context)?.claim(context, states);
      final shape = end == null
          ? retroDesktopItemShape(t)
          : RetroDesktopShapes.inset(end.outline, retroDesktopFaceRim(t));
      return RetroDesktopHighlight(
        shape: shape,
        focused: states.contains(WidgetState.focused),
        inside: true,
        child: retroDesktopHeldGround(
          t,
          held: held,
          // Over the frame's bevel, to its outline.
          bleed: bleed,
          outline: end?.outline,
          reach: EdgeInsets.fromLTRB(
            end?.left ?? false ? bleed : 0,
            bleed,
            end?.right ?? false ? bleed : 0,
            bleed,
          ),
          child: shown,
        ),
      );
    },
  );
}

/// Where a segment of a joined strip meets the frame's rounded ends: the
/// frame's [outline] on its corners there, square elsewhere, and which sides
/// (in painting order, left to right) are the strip's ends.
class _JoinedEnd extends InheritedWidget {
  const _JoinedEnd({
    required this.outline,
    required this.left,
    required this.right,
    required super.child,
  });
  final OutlinedBorder outline;
  final bool left, right;
  @override
  bool updateShouldNotify(_JoinedEnd old) =>
      old.outline != outline || old.left != left || old.right != right;
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RetroDesktopButtonGroupItem>('items', items))
      ..add(StringProperty('label', label, defaultValue: null));
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
    return RawSegmentedButton<T>(
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
            child: face,
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('values', values))
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        ObjectFlagProperty<ValueChanged<Set<T>>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<String Function(T value)>.has('labelOf', labelOf),
      )
      ..add(
        ObjectFlagProperty<IconData? Function(T value)>.has('iconOf', iconOf),
      )
      ..add(
        FlagProperty(
          'showLabels',
          value: showLabels,
          ifFalse: 'showLabels: false',
        ),
      )
      ..add(FlagProperty('multiple', value: multiple, ifTrue: 'multiple'))
      ..add(FlagProperty('allowEmpty', value: allowEmpty, ifTrue: 'allowEmpty'))
      ..add(
        ObjectFlagProperty<bool Function(T value)>.has('isEnabled', isEnabled),
      )
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// A button with its own menu: the main action on its face, the others behind
/// the arrow beside it. ui_core's split button carries the menu, its keys and
/// focus.
///
/// ```dart
/// RetroDesktopSplitButton(label: 'Save', onPressed: () {}, actions: [RawSplitAction(label: 'Save as…', onPressed: () {})])
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
  final List<RawSplitAction> actions;

  /// The main action's glyph.
  final IconData? icon;

  /// The arrow's accessible name.
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final least = RetroDesktopReach.least(context);
    return RawSplitButton(
      label: label,
      onPressed: onPressed,
      // A disabled button is disabled whole: its arrow doesn't open either.
      actions: onPressed == null ? const [] : actions,
      menuLabel:
          menuLabel ?? RawWidgetsLocalizations.of(context).splitButtonMenuLabel,
      // The look's own highlight (see RetroDesktopMenuBar): only a moving pointer takes the keys.
      highlightFollowsPointer: false,
      minimumSize: Size(least, least),
      layoutBuilder: (context, main, toggle) =>
          _joined(context, [main, toggle]),
      buttonBuilder: (context, part, states, open) {
        final face = part == RawSplitPart.main
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
            child: face,
          ),
        );
      },
      // One row lit from rim to rim, the keyboard's or the pointer's, whichever moved last; the pointer takes the
      // keys' place as it moves (see RetroDesktopMenuBar).
      itemBuilder: (context, action, states) => RetroDesktopPointerFocus(
        enabled: action.onPressed != null,
        child: retroDesktopLitRow(
          context,
          lit: retroDesktopMenuRowLit(
            states,
            enabled: action.onPressed != null,
          ),
          enabled: action.onPressed != null,
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: RetroDesktopSpacing.s16,
            vertical: RetroDesktopSpacing.s10,
          ),
          child: RetroDesktopCaps(Text(action.label)),
        ),
      ),
      surfaceBuilder: (context, info, items) =>
          _menuPanel(context, info, items),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(IterableProperty<RawSplitAction>('actions', actions))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(StringProperty('menuLabel', menuLabel, defaultValue: null));
  }
}

/// A menu's panel under its anchor, there at once as it opens and gone at once
/// as it closes (the motion's raise and leave, zero by default).
Widget _menuPanel(
  BuildContext context,
  RawPopoverInfo info,
  List<Widget> items,
) => RetroDesktopPresence(
  animation: info.animation,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: 160,
      maxWidth: info.maxSize.width,
      maxHeight: info.maxSize.height,
    ),
    child: retroDesktopPanel(
      context,
      padding: const EdgeInsets.symmetric(vertical: RetroDesktopSpacing.s4),
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
