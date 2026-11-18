/// Appliance's menu rows: [ApplianceMenuRow], the row every open list of
/// actions paints (a split key's menu, a context menu, a menu bar's menus,
/// the command palette).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'material.dart';
import 'select.dart';
import 'theme.dart';

/// One row of an open menu, painted for its [states]: under the pointer or
/// the keys it is lit, a key pressed into the plate; [chosen] lights its
/// lamp at the row's end. A row that does nothing stands greyed.
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
    final lit =
        on &&
        (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed));
    final row = DesignStyleOf([style, theme.menuStyle], states);
    final words =
        row.foreground ??
        (!on
            ? c.printDisabled
            : destructive
            ? c.danger
            : c.print);
    final face = ApplianceFace(
      top: lit ? c.keyDownTop : c.keyDownTop.withValues(alpha: 0),
      bottom: lit ? c.keyDownBottom : c.keyDownBottom.withValues(alpha: 0),
      lift: lit ? -0.6 : 0,
      travel: lit ? 0.6 : 0,
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
                ApplianceLamp(lit: chosen!),
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
