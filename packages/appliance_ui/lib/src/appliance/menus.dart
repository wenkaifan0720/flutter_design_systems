/// Appliance's menu rows: [ApplianceMenuRow], the row every open list of
/// actions paints (a split key's menu, a context menu, a menu bar's menus,
/// the command palette).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/control_light.dart';
import 'material.dart';
import 'select.dart';
import 'theme.dart';

/// One row of an open menu, painted for its [states]. A command is a key:
/// under the pointer or the keys its legend lights, and it sinks into the
/// plate only while held. A choice (a [chosen] row) the pointer or the keys
/// are on sits down as a pressed key, as a select's lit row does, so every
/// list of options in a form marks its lit row one way.
/// [chosen] lights its lamp at the row's end. A row that does nothing stands
/// greyed.
///
/// It paints; the menu that holds it presses, focuses and closes.
///
/// ```dart
/// ApplianceMenuRow(label: 'Rename', states: const {WidgetState.hovered})
/// ```
class ApplianceMenuRow extends StatelessWidget {
  /// A row reading [label] in [states].
  const ApplianceMenuRow({
    super.key,
    required this.label,
    required this.states,
    this.enabled = true,
    this.chosen,
    this.destructive = false,
    this.leading,
    this.trailing,
    this.style,
  });

  /// The words.
  final String label;

  /// Its states (hovered, focused, pressed, disabled).
  final Set<WidgetState> states;

  /// Whether it does anything.
  final bool enabled;

  /// For a choice: whether it is the one chosen (its lamp lit); null for an
  /// action, which has no lamp.
  final bool? chosen;

  /// Whether the action destroys something: printed in the danger colour.
  final bool destructive;

  /// A glyph before the words.
  final Widget? leading;

  /// What stands at the row's end (a shortcut's key caps).
  final Widget? trailing;

  /// Its style, over [ApplianceThemeData.menuStyle]: fill, foreground, textStyle.
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final on = enabled && !states.contains(WidgetState.disabled);
    final choice = chosen != null;
    final lit =
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.hovered);
    final down =
        on && (states.contains(WidgetState.pressed) || (choice && lit));
    final lamp = on && !choice ? applianceControlLight(states) : 0.0;
    final row = DesignStyleOf([style, theme.menuStyle], states);
    final words =
        row.foreground ??
        (!on
            ? c.printDisabled
            : destructive
            ? c.danger
            : c.print);
    final face = ApplianceFace(
      top: down ? c.keyDownTop : c.keyDownTop.withValues(alpha: 0),
      bottom: down ? c.keyDownBottom : c.keyDownBottom.withValues(alpha: 0),
      lift: down ? -0.6 : 0,
      travel: down ? 0.6 : 0,
      radius: BorderRadius.circular(ApplianceMenuPlate.rowRadius),
      foreground: words,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: theme.controlHeight),
      child: AnimatedApplianceSurface(
        control: false,
        face: row.fill == null ? face : row.on(face),
        child: Padding(
          padding:
              row.padding(Directionality.of(context)) ??
              const EdgeInsets.symmetric(horizontal: ApplianceSpacing.medium),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme.merge(
                  data: IconThemeData(size: 18, color: words),
                  child: leading!,
                ),
                const SizedBox(width: ApplianceSpacing.medium),
              ],
              Expanded(
                child: DesignCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: row.text(
                      theme.textTheme.body.copyWith(
                        color: words,
                        decoration: lamp > 0 ? TextDecoration.underline : null,
                        decorationColor: c.signal.withValues(alpha: lamp),
                        decorationThickness: 1.5,
                        fontWeight: chosen ?? false
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: ApplianceSpacing.medium),
                DefaultTextStyle.merge(
                  style: theme.textTheme.secondary.copyWith(
                    color: on ? c.printMuted : c.printDisabled,
                  ),
                  child: trailing!,
                ),
              ],
              if (chosen != null) ...[
                const SizedBox(width: ApplianceSpacing.medium),
                ApplianceControlLamp(lit: chosen!, states: states),
              ],
            ],
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
      ..add(IterableProperty<WidgetState>('states', states))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(DiagnosticsProperty<bool>('chosen', chosen, defaultValue: null));
  }
}
