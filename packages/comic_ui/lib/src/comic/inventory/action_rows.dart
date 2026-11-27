// The action rows the shared inventory adds: the floating action button, a button group, a toggle group
// and a split button on the design kit's behaviour, and a keyboard key. Each stands on the look's own parts: the act
// button's face, the segmented control's trough, the menu's raised face.
import 'package:flutter/foundation.dart';

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
import '../internal/lettering.dart' show comicDisplayFor;
import '../internal/menu_rows.dart';
import '../internal/style_guard.dart';
import '../knobs.dart' show ComicSpace;

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
/// ComicButtonGroup(semanticLabel: 'Text', items: [ComicButtonGroupItem('Copy', onPressed: copy), ComicButtonGroupItem('Paste', onPressed: paste)])
/// ```
class ComicButtonGroup extends StatelessWidget {
  /// Creates a [ComicButtonGroup].
  const ComicButtonGroup({super.key, required this.items, this.semanticLabel});

  /// The actions, in reading order.
  final List<ComicButtonGroupItem> items;

  /// What the group is, for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = comicStyleOf([t.segmentedButtonTheme], const {});
    final rim = comicRim(t, look, c.nightLine);
    final outer = look.shape ?? t.shapes.capsule;
    final inner = ComicTrack.cellShape(outer, rim);
    return Semantics(
      label: semanticLabel,
      container: semanticLabel != null,
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
                semanticLabel: item.label,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ComicButtonGroupItem>('items', items))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

Widget _words(
  ComicThemeData t,
  String label,
  IconData? icon,
  bool iconOnly,
  Color ink,
) {
  final text = comicDisplayFor(label, t.type.button).copyWith(color: ink);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) Icon(icon, size: 18, color: ink),
      if (icon != null && !iconOnly) const SizedBox(width: ComicSpace.close),
      if (!iconOnly || icon == null)
        CapLabel(child: Text(label, maxLines: 1, softWrap: false, style: text)),
    ],
  );
}

/// A group of toggle buttons with a shared selection track.
/// Set [multiSelectionEnabled] to allow several selections. Arrow keys move focus within
/// the group. Space and Enter toggle the focused button.
///
/// ```dart
/// ComicToggleGroup<String>(semanticLabel: 'Style', values: const ['Bold', 'Italic'], selected: on, multiSelectionEnabled: true, labelOf: (v) => v, onSelectionChanged: (next) => setState(() => on = next))
/// ```
class ComicToggleGroup<T> extends StatelessWidget {
  /// Creates a [ComicToggleGroup].
  const ComicToggleGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelectionChanged,
    required this.labelOf,
    this.iconOf,
    this.iconOnly = false,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.isEnabled,
    this.semanticLabel,
  });

  /// Every value, in reading order.
  final List<T> values;

  /// The values that are on.
  final Set<T> selected;

  /// Called with the next set; null disables the group.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// A value's words, and its name for a screen reader.
  final String Function(T value) labelOf;

  /// A value's glyph, if it has one.
  final IconData? Function(T value)? iconOf;

  /// Shows each glyph alone (give every value an icon).
  final bool iconOnly;

  /// Any number can be on; otherwise one at a time.
  final bool multiSelectionEnabled;

  /// The last one can be turned off.
  final bool emptySelectionAllowed;

  /// Whether a value can be pressed; null: all.
  final bool Function(T value)? isEnabled;

  /// What the group is, for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = comicStyleOf([t.segmentedButtonTheme], const {});
    final rim = comicRim(t, look, c.nightLine);
    final outer = look.shape ?? t.shapes.capsule;
    final inner = ComicTrack.cellShape(outer, rim);
    final lit = comicStyleOf(
      [t.segmentedButtonTheme],
      const {WidgetState.selected},
    );
    return RawSegmentedButton<T>(
      options: values,
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      emptySelectionAllowed: emptySelectionAllowed,
      isEnabled: isEnabled,
      labelOf: labelOf,
      semanticLabel: semanticLabel,
      // The trough sizes each cell (a field's height, its words' width) and the face fills it: the kit's own least
      // size would centre the face loose in the cell, its chosen fill a marker behind the word.
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
        return ComicScreened(
          on: states.contains(WidgetState.disabled),
          child: face,
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
        ObjectFlagProperty<ValueChanged<Set<T>>>.has(
          'onSelectionChanged',
          onSelectionChanged,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(T value)>.has('labelOf', labelOf),
      )
      ..add(
        ObjectFlagProperty<IconData? Function(T value)>.has('iconOf', iconOf),
      )
      ..add(
        FlagProperty(
          'iconOnly',
          value: iconOnly,
          ifTrue: 'iconOnly',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifTrue: 'multiple',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'emptySelectionAllowed',
          value: emptySelectionAllowed,
          ifTrue: 'allowEmpty',
          defaultValue: false,
        ),
      )
      ..add(
        ObjectFlagProperty<bool Function(T value)>.has('isEnabled', isEnabled),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
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

/// A primary action and a menu button in one frame.
/// The label runs the primary action. The arrow opens [actions] and regains
/// focus when the menu closes.
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

  /// The arrow's name for a screen reader; null takes `RawWidgetsLocalizations.splitButtonMenuLabel`.
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = comicStyleOf([t.filledButtonTheme], const {});
    final outer = look.shape ?? t.shapes.small;
    final rim = comicRim(t, look, c.nightLine);
    final inner = comicInsetShape(outer, rim.width + 3);
    final height = t.density.height(48);
    return RawSplitButton(
      label: label,
      onPressed: onPressed,
      menuLabel:
          menuLabel ?? RawWidgetsLocalizations.of(context).splitButtonMenuLabel,
      actions: [
        if (actions.any((a) => a.onPressed != null))
          for (final a in actions)
            RawSplitAction(label: a.label, onPressed: a.onPressed),
      ],
      // The act's two halves stand on one print (law 4), as the act does.
      layoutBuilder: (context, main, toggle) => ComicPlated(
        down: false,
        shape: outer,
        child: DecoratedBox(
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
              // A half pops on the act face, where its words were written.
              ringGap: look.fill ?? c.primary,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: part == RawSplitPart.main ? 13 : 6,
                ),
                child: Center(
                  widthFactor: 1,
                  child: part == RawSplitPart.main
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
        return ComicScreened(
          on: states.contains(WidgetState.disabled),
          child: face,
        );
      },
      itemBuilder: (context, action, states) => comicMenuRow(
        states,
        (states) => ComicMenuRowFace(states: states, label: action.label),
      ),
      surfaceBuilder: (context, info, items) =>
          comicRaisedSurface(context, info.animation, info.maxSize, items),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(IterableProperty<ComicSplitAction>('actions', actions))
      ..add(StringProperty('menuLabel', menuLabel, defaultValue: null));
  }
}

/// The menu's raised face around design-kit rows, fading in on [presence] and scrolling past [maxSize].
Widget comicRaisedSurface(
  BuildContext context,
  Animation<double> presence,
  Size maxSize,
  List<Widget> items, {
  double width = 320,
}) => AnimatedBuilder(
  // Drawn, not faded (law 6): the panel pops in from .92 at full ink and is gone the moment it has closed.
  animation: presence,
  builder: (context, child) => presence.isDismissed
      ? const SizedBox.shrink()
      : Transform.scale(
          scale: .92 + .08 * Curves.easeOutBack.transform(presence.value),
          alignment: Alignment.topCenter,
          child: child,
        ),
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
/// say what it does; a screen reader hears the keys joined by "plus". [ComicKbd.shortcut] takes its keys from a
/// shortcut, as the platform orders them and the reader's language names them.
///
/// ```dart
/// ComicKbd(const ['Ctrl', 'K'])
/// ```
class ComicKbd extends StatelessWidget {
  /// Creates a [ComicKbd] for [keys], pressed together.
  const ComicKbd(this.keys, {super.key}) : shortcut = null;

  /// Creates a [ComicKbd] for the keys of [shortcut]: ui_core's `rawShortcutKeys`, spelled in words on every
  /// platform (Ctrl, Shift, Command, Enter), as Comic's faces draw none of Apple's ⌃ ⌥ ⇧ ⌘ ↵.
  const ComicKbd.shortcut(MenuSerializableShortcut this.shortcut, {super.key})
    : keys = const [];

  /// The keys, in the order they're held; empty for [ComicKbd.shortcut], whose keys come from [shortcut].
  final List<String> keys;

  /// The shortcut the keys come from, for [ComicKbd.shortcut]; null for [keys] as given.
  final MenuSerializableShortcut? shortcut;

  /// [shortcut] as a menu row writes it ("Ctrl+N" here, "Command+N" on a Mac), for a menu entry's or a command's
  /// `shortcut`: ui_core's `rawShortcutLabel`, in the words [ComicKbd.shortcut] uses.
  ///
  /// ```dart
  /// RawMenuEntry(label: 'New', shortcut: ComicKbd.labelOf(context, const SingleActivator(LogicalKeyboardKey.keyN, control: true)))
  /// ```
  static String labelOf(
    BuildContext context,
    MenuSerializableShortcut shortcut,
  ) => _enterInWords(
    context,
    rawShortcutLabel(context, shortcut, appleSymbols: false),
  );

  // Off Apple's platforms ui_core writes Enter as ↵ even with its symbols off; Comic's faces draw no ↵, so Enter is
  // the reader's word there too, as it is on a Mac.
  static String _enterInWords(BuildContext context, String keys) => keys
      .replaceAll('↵', RawWidgetsLocalizations.of(context).keyboardKeyEnter);

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final keys = switch (shortcut) {
      null => this.keys,
      final shortcut => [
        for (final key in rawShortcutKeys(
          context,
          shortcut,
          appleSymbols: false,
        ))
          _enterInWords(context, key),
      ],
    };
    final words = t.type.text(13, 1.1, weight: FontWeight.w700, color: c.text);
    // The cap stands on its edge: the same shape in the line's colour, two pixels taller, drawn under it (the look draws
    // no shadow). The line is the night issue's cream at night, as a field's contour is, so a cap reads on the black
    // ground.
    Widget cap(String key) => DecoratedBox(
      decoration: ShapeDecoration(color: c.nightLine, shape: t.shapes.small),
      child: Padding(
        padding: const EdgeInsets.only(bottom: ComicSpace.fine),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: c.card,
            // The contour every part is drawn with: a 1.5 cap would read thinner than its neighbours.
            shape: t.shapes.small.copyWith(
              side: BorderSide(color: c.nightLine, width: t.rim(2)),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ComicSpace.close,
                vertical: ComicSpace.nib,
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: ComicSpace.tight,
                  ),
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('keys', keys))
      ..add(
        DiagnosticsProperty<MenuSerializableShortcut>(
          'shortcut',
          shortcut,
          defaultValue: null,
        ),
      );
  }
}
