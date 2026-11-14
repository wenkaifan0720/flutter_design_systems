// The action rows the shared inventory adds: the floating action button, a button group, a toggle group
// and a split button on the design kit's behaviour, and a keyboard key. Each stands on the look's own parts: the act
// button's face, the segmented control's trough, the menu's raised face.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../glyphs.dart';
import '../internal/track.dart';

import '../press.dart';
import '../raised.dart';
import '../styled.dart';
import '../theme.dart';
import '../internal/cap_label.dart';

/// One action in a [ComicButtonGroup].
@immutable
class ComicButtonGroupItem {
  /// Creates a [ComicButtonGroupItem].
  const ComicButtonGroupItem(
    this.label, {
    this.icon,
    this.onPressed,
    this.iconOnly = false,
  });

  /// Its words, and its name for a screen reader.
  final String label;

  /// An optional glyph before the words.
  final IconData? icon;

  /// Called when pressed; null disables this one.
  final VoidCallback? onPressed;

  /// Shows the glyph alone (give it an [icon]).
  final bool iconOnly;
}

/// Related actions joined in one trough, the segmented control's: each its own press, its wash and ring concentric
/// with the trough, none chosen (for one that stays on, a [ComicToggleGroup]). Each takes its own width.
///
/// ```dart
/// ComicButtonGroup(label: 'Text', items: [ComicButtonGroupItem('Copy', onPressed: copy), ComicButtonGroupItem('Paste', onPressed: paste)])
/// ```
class ComicButtonGroup extends StatelessWidget {
  /// Creates a [ComicButtonGroup].
  const ComicButtonGroup({super.key, required this.items, this.label});

  /// The actions, in reading order.
  final List<ComicButtonGroupItem> items;

  /// What the group is, for a screen reader.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = ComicStyleOf([t.segmentedButtonTheme], const {});
    final rim = comicRim(t, look, c.nightLine);
    final outer = look.shape ?? t.shapes.capsule;
    final inner = ComicTrack.cellShape(outer, rim);
    return Semantics(
      label: label,
      container: label != null,
      explicitChildNodes: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: ComicTrack(
          shape: outer,
          rim: rim,
          fill: look.fill ?? (c.dark ? c.card : c.control),
          equal: false,
          cells: [
            for (final item in items)
              ComicPressable(
                label: item.label,
                onPressed: item.onPressed,
                wash: false,
                ring: false,
                sink: false,
                builder: (context, states) => ComicTrackFace(
                  states: states,
                  shape: inner,
                  child: _words(
                    t,
                    item.label,
                    item.icon,
                    item.iconOnly,
                    c.dark ? c.text : c.onPaper,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _words(
  ComicThemeData t,
  String label,
  IconData? icon,
  bool iconOnly,
  Color ink,
) {
  final text = t.type.button.copyWith(color: ink);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) Icon(icon, size: 18, color: ink),
      if (icon != null && !iconOnly) const SizedBox(width: 6),
      if (!iconOnly || icon == null)
        CapLabel(child: Text(label, maxLines: 1, softWrap: false, style: text)),
    ],
  );
}

/// Buttons that stay on: one of them ([multiple] false) or any number. They stand in the segmented control's trough,
/// and each one on wears the selection fill over its whole cell, concentric with the trough, as the segmented
/// control's chosen segment does. The behaviour (roving focus,
/// arrows, Space and Enter, the group's semantics) is the design kit's `DesignToggleGroup`.
///
/// ```dart
/// ComicToggleGroup<String>(label: 'Style', values: const ['Bold', 'Italic'], selected: on, multiple: true, labelOf: (v) => v, onChanged: (next) => setState(() => on = next))
/// ```
class ComicToggleGroup<T> extends StatelessWidget {
  /// Creates a [ComicToggleGroup].
  const ComicToggleGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.iconOf,
    this.iconOnly = false,
    this.multiple = false,
    this.allowEmpty = false,
    this.isEnabled,
    this.label,
  });

  /// Every value, in reading order.
  final List<T> values;

  /// The values that are on.
  final Set<T> selected;

  /// Called with the next set; null disables the group.
  final ValueChanged<Set<T>>? onChanged;

  /// A value's words, and its name for a screen reader.
  final String Function(T value) labelOf;

  /// A value's glyph, if it has one.
  final IconData? Function(T value)? iconOf;

  /// Shows each glyph alone (give every value an icon).
  final bool iconOnly;

  /// Any number can be on; otherwise one at a time.
  final bool multiple;

  /// The last one can be turned off.
  final bool allowEmpty;

  /// Whether a value can be pressed; null: all.
  final bool Function(T value)? isEnabled;

  /// What the group is, for a screen reader.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = ComicStyleOf([t.segmentedButtonTheme], const {});
    final rim = comicRim(t, look, c.nightLine);
    final outer = look.shape ?? t.shapes.capsule;
    final inner = ComicTrack.cellShape(outer, rim);
    final lit = ComicStyleOf(
      [t.segmentedButtonTheme],
      const {WidgetState.selected},
    );
    return DesignToggleGroup<T>(
      options: values,
      selected: selected,
      onSelectionChanged: onChanged,
      multiSelectionEnabled: multiple,
      emptySelectionAllowed: allowEmpty,
      isEnabled: isEnabled,
      labelOf: labelOf,
      semanticLabel: label,
      // The trough sizes each cell (a field's height, its words' width) and the face fills it: the kit's own least
      // size would centre the face loose in the cell, its chosen fill a marker behind the word (11-12).
      minimumSize: Size.zero,
      layoutBuilder: (context, items) => Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: ComicTrack(
          shape: outer,
          rim: rim,
          fill: look.fill ?? (c.dark ? c.card : c.control),
          cells: items,
        ),
      ),
      itemBuilder: (context, value, states) {
        final on = states.contains(WidgetState.selected);
        final ink = on ? c.onCaption : (c.dark ? c.text : c.onPaper);
        final face = ComicTrackFace(
          states: states.difference({WidgetState.selected}),
          shape: inner,
          fill: on ? (lit.fill ?? c.caption) : null,
          child: _words(t, labelOf(value), iconOf?.call(value), iconOnly, ink),
        );
        return states.contains(WidgetState.disabled)
            ? Opacity(opacity: .5, child: face)
            : face;
      },
    );
  }
}

/// One more action behind a [ComicSplitButton]'s arrow.
@immutable
class ComicSplitAction {
  /// Creates a [ComicSplitAction].
  const ComicSplitAction(this.label, {required this.onPressed});

  /// Its words in the menu.
  final String label;

  /// Called when chosen; null disables it.
  final VoidCallback? onPressed;
}

/// The primary action with its arrow beside it: the act button's face cut in two by a rule, the words doing the main
/// thing and the arrow opening the menu's raised face with the [actions] that go with it. The behaviour (the menu's
/// keys, focus return, the two halves' semantics) is the design kit's `DesignSplitButton`.
///
/// ```dart
/// ComicSplitButton('Save', onPressed: save, actions: [ComicSplitAction('Save as copy', onPressed: copy)])
/// ```
class ComicSplitButton extends StatelessWidget {
  /// Creates a [ComicSplitButton].
  const ComicSplitButton(
    this.label, {
    super.key,
    required this.onPressed,
    required this.actions,
    this.menuLabel,
  });

  /// The main action's words.
  final String label;

  /// The main action; null disables that half.
  final VoidCallback? onPressed;

  /// What the arrow offers. With none to take, the arrow is disabled.
  final List<ComicSplitAction> actions;

  /// The arrow's name for a screen reader; null takes `DesignLocalizations.splitButtonMenuLabel`.
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = ComicStyleOf([t.filledButtonTheme], const {});
    final outer = look.shape ?? t.shapes.small;
    final rim = comicRim(t, look, c.nightLine);
    final inner = comicInsetShape(outer, rim.width + 3);
    final height = t.density.height(48);
    return DesignSplitButton(
      label: label,
      onPressed: onPressed,
      menuLabel:
          menuLabel ?? DesignLocalizations.of(context).splitButtonMenuLabel,
      actions: [
        if (actions.any((a) => a.onPressed != null))
          for (final a in actions)
            DesignSplitAction(label: a.label, onPressed: a.onPressed),
      ],
      layoutBuilder: (context, main, toggle) => DecoratedBox(
        decoration: ShapeDecoration(
          color: look.fill ?? c.primary,
          shape: outer.copyWith(side: rim),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              Container(width: rim.width, color: rim.color),
              toggle,
            ],
          ),
        ),
      ),
      buttonBuilder: (context, part, states, open) {
        final ink = look.foreground ?? c.onPrimary;
        final face = ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(height, ComicTapTarget.targetOf(context)),
            minWidth: math.max(height - 4, ComicTapTarget.targetOf(context)),
          ),
          child: Padding(
            padding: EdgeInsets.all(rim.width + 3),
            child: ComicHighlight(
              states: states,
              shape: inner,
              washColor: ink,
              // The ring stands on the act face, not the ground: the ground's colour between keeps it apart.
              ringGap: c.background,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: part == DesignSplitPart.main ? 13 : 6,
                ),
                child: Center(
                  widthFactor: 1,
                  child: part == DesignSplitPart.main
                      ? CapLabel(
                          child: Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            style: t.type.button.copyWith(color: ink),
                          ),
                        )
                      : Icon(
                          open
                              ? ComicGlyphs.chevronUp
                              : ComicGlyphs.chevronDown,
                          size: 20,
                          color: ink,
                        ),
                ),
              ),
            ),
          ),
        );
        return states.contains(WidgetState.disabled)
            ? Opacity(opacity: .5, child: face)
            : face;
      },
      itemBuilder: (context, action, states) =>
          ComicMenuRowFace(states: states, label: action.label),
      surfaceBuilder: (context, info, items) =>
          comicRaisedSurface(context, info.animation, info.maxSize, items),
    );
  }
}

/// The menu's raised face around design-kit rows, fading in on [presence] and scrolling past [maxSize].
Widget comicRaisedSurface(
  BuildContext context,
  Animation<double> presence,
  Size maxSize,
  List<Widget> items, {
  double width = 320,
}) => FadeTransition(
  opacity: presence,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: maxSize.height,
      maxWidth: math.min(width, maxSize.width),
    ),
    child: ComicRaisedFrame(
      child: SingleChildScrollView(
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
);

/// A key on the keyboard, or a run of them, as a small cap standing on its own edge: Ctrl, K, Enter. Words beside it
/// say what it does; a screen reader hears the keys joined by "plus".
///
/// ```dart
/// ComicKbd(const ['Ctrl', 'K'])
/// ```
class ComicKbd extends StatelessWidget {
  /// Creates a [ComicKbd] for [keys], pressed together.
  const ComicKbd(this.keys, {super.key});

  /// The keys, in the order they're held.
  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final words = t.type.text(13, 1.1, weight: FontWeight.w700, color: c.text);
    // The cap stands on its edge: the same shape in the line's colour, two pixels taller, drawn under it (the look draws
    // no shadow). The line is the night issue's cream at night, as a field's contour is, so a cap reads on the black
    // ground.
    Widget cap(String key) => DecoratedBox(
      decoration: ShapeDecoration(color: c.nightLine, shape: t.shapes.small),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.card,
            // The contour every part is drawn with (r4: a 1.5 cap read thinner than its neighbours).
            shape: t.shapes.small.copyWith(
              side: BorderSide(color: c.nightLine, width: t.rim(2)),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: CapLabel(
                  child: Text(key, maxLines: 1, softWrap: false, style: words),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: keys.join(' plus '),
      excludeSemantics: true,
      // A shortcut keeps the order its keys are held in a right-to-left app too: Ctrl + K, never K + Ctrl.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  // In ink, as the caps' letters are.
                  child: Text('+', style: words),
                ),
              cap(keys[i]),
            ],
          ],
        ),
      ),
    );
  }
}
