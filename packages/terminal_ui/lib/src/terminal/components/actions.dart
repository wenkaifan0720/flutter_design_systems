/// Actions beyond the one button: buttons side by side, toggles in one pair
/// of brackets, a button with a menu of the same action's variants, and a
/// link in running text.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/menu_marks.dart';
import '../internal/type_ahead.dart';
import '../primitives/control.dart';
import '../primitives/menu.dart';
import '../style.dart';
import '../theme.dart';
import 'pane.dart';

/// Buttons on one line, a cell apart, as a program's toolbar prints them:
/// `[ rerun ] [ cancel ] [ logs ]`. Where the line is short they wrap.
///
/// ```dart
/// TermButtonGroup(
///   semanticLabel: 'run actions',
///   children: [
///     TermButton(label: 'rerun', onPressed: () {}),
///     TermButton(label: 'cancel', onPressed: () {}),
///   ],
/// )
/// ```
class TermButtonGroup extends StatelessWidget {
  /// [children] on one line.
  const TermButtonGroup({
    super.key,
    required this.children,
    this.semanticLabel,
  });

  /// The buttons.
  final List<Widget> children;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Wrap(
        spacing: grid.cellWidth,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

/// Toggles in one pair of brackets, `[ list │ tiles │ log ]`, each chosen
/// one in inverse video: one choice ([multiSelectionEnabled] false, a
/// segmented control) or each on its own (a toggle group). The arrows move
/// along it; Space and Return press.
///
/// ```dart
/// TermToggleGroup<String>(
///   options: const ['list', 'tiles'],
///   selected: {view},
///   labelOf: (v) => v,
///   onSelectionChanged: (s) => setState(() => view = s.first),
/// )
/// ```
class TermToggleGroup<T> extends StatelessWidget {
  /// Toggles over [options].
  const TermToggleGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelectionChanged,
    required this.labelOf,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.selectFollowsFocus = false,
    this.isEnabled,
    this.semanticLabel,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.toggleGroupStyle]: `fill`
  /// (the chosen cells), `foreground` (the words) and `edge` (the
  /// brackets).
  final TermStyle? style;

  /// The choices, in order.
  final List<T> options;

  /// The chosen ones.
  final Set<T> selected;

  /// Called with the new choice; null disables the group.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// The words for an option.
  final String Function(T value) labelOf;

  /// Whether each toggles on its own.
  final bool multiSelectionEnabled;

  /// Whether the last chosen one may be pressed off.
  final bool emptySelectionAllowed;

  /// Whether the arrows choose as they move (a segmented control).
  final bool selectFollowsFocus;

  /// Whether an option can be pressed; null: every one.
  final bool Function(T value)? isEnabled;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final floor = grid.ceil(DesignTapTargets.of(context).floorOn());
    return DesignToggleGroup<T>(
      options: options,
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      emptySelectionAllowed: emptySelectionAllowed,
      selectFollowsFocus: selectFollowsFocus,
      isEnabled: isEnabled,
      labelOf: labelOf,
      semanticLabel: semanticLabel,
      minimumSize: Size(grid.cols(3), floor.height),
      itemBuilder: (context, value, states) {
        final own = TermStyleOf([style, theme.toggleGroupStyle], states);
        return TermStateSprings(
          pressed: states.contains(WidgetState.pressed),
          focused: states.contains(WidgetState.focused),
          builder: (context, press, focus) => TermCellFace(
            label: labelOf(value),
            on: states.contains(WidgetState.selected),
            enabled: !states.contains(WidgetState.disabled),
            press: press,
            focus: focus,
            fill: own.fill,
            foreground: own.foreground,
          ),
        );
      },
      layoutBuilder: (context, items) => LayoutBuilder(
        builder: (context, constraints) {
          final edge = TermStyleOf([
            style,
            theme.toggleGroupStyle,
          ], const {}).edge;
          final labels = options.fold<double>(
            0,
            (sum, option) =>
                sum +
                math.max(
                  grid.cols(3),
                  grid.widthOf(labelOf(option)) + grid.cols(2),
                ),
          );
          final width = labels + grid.cols(2 + math.max(0, items.length - 1));
          if (width > constraints.maxWidth) {
            return Wrap(
              spacing: grid.cellWidth,
              children: [
                for (final item in items)
                  TermBracketBand(edge: edge, child: item),
              ],
            );
          }
          return TermBracketBand(
            edge: edge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0)
                    ExcludeSemantics(
                      child: Text(
                        '│',
                        style: theme.textStyle.copyWith(color: theme.rule),
                      ),
                    ),
                  item,
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        FlagProperty(
          'multiSelectionEnabled',
          value: multiSelectionEnabled,
          ifTrue: 'multiple',
        ),
      );
  }
}

/// A button with a menu of the same action's other ways:
/// `[ deploy ][▾]`. The label runs [onPressed]; the arrow opens [actions]
/// under it, revealed in place.
///
/// ```dart
/// TermSplitButton(
///   label: 'deploy',
///   onPressed: deploy,
///   actions: [DesignSplitAction(label: 'deploy without cache', onPressed: fresh)],
/// )
/// ```
class TermSplitButton extends StatelessWidget {
  /// A split button running [onPressed], its menu [actions].
  const TermSplitButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.actions,
    this.filled = false,
    this.menuLabel,
    this.style,
  });

  /// Overrides for both halves, over the theme's
  /// [TermThemeData.splitButtonStyle]: `fill`, `foreground`, `edge` and
  /// `textStyle`, as a [TermButton] reads them. The menu's rows read
  /// [TermThemeData.menuStyle].
  final TermStyle? style;

  /// The main half's words.
  final String label;

  /// What the main half does; null disables it (the menu stays).
  final VoidCallback? onPressed;

  /// The menu's actions.
  final List<DesignSplitAction> actions;

  /// Whether it is the screen's primary action, filled in the accent.
  final bool filled;

  /// What a screen reader calls the arrow.
  final String? menuLabel;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final theme = TermTheme.of(context);
    final floor = grid.ceil(DesignTapTargets.of(context).floorOn());
    // The arrow's half is at least the floor wide (a finger's five cells),
    // its brackets moved out to the target's edges so the face is the
    // target: `[  ▾  ]` under a finger, `[ ▾ ]` under a pointer.
    final arrowPad = math.max(1, grid.colsIn(floor.width) ~/ 2);
    TermMenuMarks.watchInput();
    return DesignSplitButton(
      label: label,
      onPressed: onPressed,
      actions: actions,
      menuLabel: menuLabel,
      minimumSize: Size(grid.cols(3), floor.height),
      buttonBuilder: (context, part, states, open) {
        final own = TermStyleOf([style, theme.splitButtonStyle], states);
        return TermStateSprings(
          pressed: states.contains(WidgetState.pressed) || open,
          focused: states.contains(WidgetState.focused),
          builder: (context, press, focus) => TermBracketFace(
            label: part == DesignSplitPart.main ? label : '▾',
            padCols: part == DesignSplitPart.main ? 2 : arrowPad,
            filled: filled,
            enabled: !states.contains(WidgetState.disabled),
            press: press,
            focus: focus,
            fill: own.fill,
            foreground: own.foreground,
            edge: own.edge,
            textStyle: own.textStyle,
          ),
        );
      },
      itemBuilder: (context, action, states) =>
          TermMenuRow(label: action.label, states: states),
      surfaceBuilder: (context, info, items) => TermMenuReveal(
        info: info,
        child: TermPane(
          raised: true,
          focused: true,
          // A cell inside the frame each side, so a lit row's bar stands
          // clear of the frame's sides as of its top and bottom lines.
          padding: const TermInset(),
          // A letter takes the keys to the next action it starts; one row
          // current, shown once the keys or the pointer move.
          child: TermTypeAhead(
            child: TermMenuMarks(
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
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IntProperty('actions', actions.length));
  }
}

/// A link in running text: its words underlined in the accent, a press in
/// inverse video, the keyboard's focus in inverse accent. A screen reader
/// hears a link.
///
/// ```dart
/// TermLink(label: 'the docs', onPressed: () {})
/// ```
class TermLink extends StatelessWidget {
  /// A link saying [label].
  const TermLink({super.key, required this.label, this.onPressed, this.style});

  /// Overrides, over the theme's [TermThemeData.linkStyle]: `fill` (the
  /// block under focus and a press) and `foreground` (the words).
  final TermStyle? style;

  /// Its words.
  final String label;

  /// Where it goes; null disables it.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    return TermTapTarget(
      child: DesignPressable(
        onPressed: onPressed,
        link: true,
        button: false,
        semanticLabel: label,
        excludeSemantics: true,
        mouseCursor: onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) {
          final on =
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused);
          final own = TermStyleOf([style, theme.linkStyle], states);
          final ink = onPressed == null
              ? theme.rule
              : own.foreground ?? theme.accent;
          return ColoredBox(
            color: on ? own.fill ?? ink : const Color(0x00000000),
            child: Text(
              label,
              style: theme.textStyle.copyWith(
                color: on ? theme.onAccent : ink,
                decoration: TextDecoration.underline,
                decorationColor: on ? theme.onAccent : ink,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      );
  }
}
