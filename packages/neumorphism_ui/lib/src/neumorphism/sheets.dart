// Sheets that rise over a page: the action sheet (a short list of what can be done to one thing, and Cancel) and the
// side sheet (a panel from the window's edge, on ui_core's side-sheet route).
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'glyphs.dart';
import 'internal/panel.dart';
import 'localizations.dart';
import 'raised.dart';
import 'theme.dart';

/// One choice of a [NeumorphicActionSheet]: its [value], its words, a glyph, whether it destroys something.
@immutable
class NeumorphicActionSheetAction<T> {
  /// A choice returning [value], named [label].
  const NeumorphicActionSheetAction(
    this.value,
    this.label, {
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  /// What choosing it returns.
  final T value;

  /// Its words.
  final String label;

  /// A glyph before its words.
  final IconData? icon;

  /// Whether it destroys something: a warning mark after its words, and it stands last before Cancel.
  final bool destructive;

  /// Whether it can be chosen now.
  final bool enabled;
}

/// What can be done to one thing, as a raised panel from the foot of the screen: an optional heading and line, a
/// row per action (pressed in where the pointer or the keyboard is, as the look's menus are), and Cancel on its own
/// slab beneath. Show it with [showNeumorphicActionSheet].
///
/// ```dart
/// NeumorphicActionSheet<String>(title: 'This booking', actions: const [NeumorphicActionSheetAction('move', 'Move it'), NeumorphicActionSheetAction('cancel', 'Cancel it', destructive: true)], onSelected: act)
/// ```
class NeumorphicActionSheet<T> extends StatelessWidget {
  /// An action sheet of [actions].
  const NeumorphicActionSheet({
    super.key,
    required this.actions,
    required this.onSelected,
    this.title,
    this.message,
    this.onCancel,
    this.cancelLabel,
    this.style,
  });

  /// The choices, in order.
  final List<NeumorphicActionSheetAction<T>> actions;

  /// Called with the chosen action's value.
  final ValueChanged<T> onSelected;

  /// A heading: what the actions act on.
  final String? title;

  /// A line more under the heading.
  final String? message;

  /// Called by Cancel; null: no Cancel.
  final VoidCallback? onCancel;

  /// Cancel's words; null: the localized Cancel.
  final String? cancelLabel;

  /// The panels' own style, before the menu theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final words = NeumorphicLocalizations.of(context);
    Widget row(
      String label, {
      required VoidCallback? onPressed,
      IconData? icon,
      bool danger = false,
    }) => DesignPressable(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => NeumorphicPanelRow(
        label: label,
        states: states,
        icon: icon,
        danger: danger,
        style: style,
      ),
    );
    // In place it starts on its column's edge and keeps the width it has raised (560); raised, the route keeps it off
    // the screen's edges.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeumorphicPanel(
                style: style,
                label: title,
                maxHeight: MediaQuery.sizeOf(context).height * .6,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null || message != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                          child: Column(
                            children: [
                              if (title != null)
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title!,
                                    textAlign: TextAlign.center,
                                    style: t.textTheme.caption.copyWith(
                                      color: c.inkSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              if (message != null)
                                Text(
                                  message!,
                                  textAlign: TextAlign.center,
                                  style: t.textTheme.micro.copyWith(
                                    color: c.inkTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      for (final a in actions)
                        row(
                          a.label,
                          icon: a.icon,
                          danger: a.destructive,
                          onPressed: a.enabled
                              ? () => onSelected(a.value)
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 10),
                NeumorphicPanel(
                  style: style,
                  child: row(
                    cancelLabel ?? words.cancel,
                    onPressed: onCancel,
                    icon: NeumorphicGlyphs.close,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Raises a [NeumorphicActionSheet] from the foot of the screen and returns the chosen action's value, or null when
/// it is cancelled or dismissed. Back, Escape and a tap on the scrim cancel it.
///
/// ```dart
/// final choice = await showNeumorphicActionSheet<String>(context, title: 'This booking', actions: actions);
/// ```
Future<T?> showNeumorphicActionSheet<T>(
  BuildContext context, {
  required List<NeumorphicActionSheetAction<T>> actions,
  String? title,
  String? message,
  String? cancelLabel,
  bool useRootNavigator = true,
}) => showNeumorphicBottomSheet<T>(
  context,
  useRootNavigator: useRootNavigator,
  builder: (context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: NeumorphicActionSheet<T>(
      actions: actions,
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      onSelected: (value) => Navigator.of(context).pop(value),
      onCancel: () => Navigator.of(context).pop(),
    ),
  ),
);
