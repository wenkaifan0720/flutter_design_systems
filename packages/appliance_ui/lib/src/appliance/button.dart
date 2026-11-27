/// Appliance's buttons: [ApplianceButton] (a moulded key; `.filled` the
/// signal-orange key for a screen's main action; `.text` a printed legend
/// with no key round it) and [ApplianceIconButton] (a square key).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/control_light.dart';
import 'material.dart';
import 'theme.dart';

enum _ButtonKind { key, filled, text }

/// A button: a moulded plastic key, lit from the top. A press sinks it into
/// the panel (its legend goes down with it) and it comes back up on its
/// spring when let go.
///
/// The unnamed constructor is the ordinary key; [ApplianceButton.filled] is
/// a screen's one main action, the signal-orange key; [ApplianceButton.text]
/// is a quiet action printed on the panel, with no key round it.
/// [isDestructiveAction] prints any of them in the danger colour (and makes
/// the filled key a danger key, for the dialog that confirms a removal).
///
/// A null [onPressed] disables it: the key stands lower and its legend
/// greys. It takes the width it is given when that is tight (a column that
/// stretches its children) and its content's otherwise.
///
/// Reads [style]'s `fill`, `foreground`, `edge`, `padding`, `minimumSize`,
/// `textStyle` and `iconSize`, then its kind's theme slot
/// ([ApplianceThemeData.buttonStyle], [ApplianceThemeData.filledButtonStyle]
/// or [ApplianceThemeData.textButtonStyle]). The depth, the light and the
/// corners stay the look's.
///
/// ```dart
/// ApplianceButton.filled('Add to basket', onPressed: () => add(item))
/// ```
class ApplianceButton extends StatelessWidget {
  /// An ordinary key.
  const ApplianceButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _ButtonKind.key;

  /// A screen's one main action: the signal-orange key.
  const ApplianceButton.filled(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _ButtonKind.filled;

  /// A quiet action: its legend printed on the panel in the signal's ink,
  /// with no key. Its words stand on the line its neighbours start on.
  const ApplianceButton.text(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _ButtonKind.text;

  /// The legend: one line, cut short with an ellipsis when the key is
  /// narrower than it.
  final String label;

  /// What a press does; null disables the button.
  final VoidCallback? onPressed;

  /// A glyph before the legend, 20 px.
  final Widget? icon;

  /// Whether the action destroys something (removes an item, deletes an
  /// address): printed in the danger colour, as `CupertinoDialogAction`
  /// names it.
  final bool isDestructiveAction;

  /// This button's style, over its kind's theme slot.
  final ApplianceStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  final _ButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final layers = [
      style,
      switch (_kind) {
        _ButtonKind.key => theme.buttonStyle,
        _ButtonKind.filled => theme.filledButtonStyle,
        _ButtonKind.text => theme.textButtonStyle,
      },
    ];
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = RawStyleOf(layers, states);
        final face = layered.on(
          _keyFace(theme, states, _kind, isDestructiveAction),
        );
        final text = _kind == _ButtonKind.text;
        final padding =
            layered.padding(Directionality.of(context)) ??
            (text
                ? EdgeInsets.zero
                // Above and below, room for the words' descenders: at large
                // text the key grows with its words rather than holding them
                // on its foot.
                : EdgeInsets.symmetric(
                    horizontal:
                        ApplianceSpacing.large + theme.density.paddingDelta,
                    vertical: ApplianceSpacing.tight,
                  ));
        final minimum =
            layered.minimumSize ??
            Size(text ? 0 : theme.controlHeight, theme.controlHeight);
        final legend = DefaultTextStyle.merge(
          style: layered.text(
            theme.textTheme.label.copyWith(
              color: face.foreground,
              fontWeight: _kind == _ButtonKind.filled ? FontWeight.w600 : null,
            ),
          ),
          // A key's words are what it does: a second line, centred, reads
          // better than an ellipsis where one line can't hold them.
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          child: RawCapCenter(
            capHeightFactor: theme.capHeightFactor,
            child: Text(label),
          ),
        );
        return TapTargetPadding(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minimum.width,
              minHeight: minimum.height,
            ),
            child: AnimatedApplianceSurface(
              face: face,
              child: Padding(
                padding: padding,
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        // The glyph grows with the legend beside it.
                        IconTheme.merge(
                          data: IconThemeData(
                            size: MediaQuery.textScalerOf(context)
                                .scale(layered.iconSize ?? 20),
                            color: face.foreground,
                          ),
                          child: icon!,
                        ),
                        const SizedBox(width: ApplianceSpacing.small),
                      ],
                      Flexible(child: legend),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<_ButtonKind>('kind', _kind))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      )
      ..add(
        DiagnosticsProperty<ApplianceStyle>('style', style, defaultValue: null),
      );
  }
}

/// A key's face in [states].
/// The pale lamp-light a filled key's rim glows with when it has the focus.
const Color _litRim = Color(0xFFFFE8BD);

ApplianceFace _keyFace(
  ApplianceThemeData theme,
  Set<WidgetState> states,
  _ButtonKind kind,
  bool destructive,
) {
  final c = theme.colors;
  final disabled = states.contains(WidgetState.disabled);
  final pressed = states.contains(WidgetState.pressed);
  final focus = c.focus.withValues(alpha: applianceControlLight(states));
  final disabledInk = Color.lerp(c.printDisabled, c.print, 0.5)!;
  final legend = disabled
      ? disabledInk
      : destructive
      ? c.danger
      : c.print;
  switch (kind) {
    case _ButtonKind.text:
      return ApplianceFace(
        top: c.face.withValues(alpha: 0),
        bottom: c.face.withValues(alpha: 0),
        radius: BorderRadius.circular(ApplianceMetrics.smallKeyRadius),
        travel: pressed ? 0.7 : 0,
        foreground: disabled
            ? disabledInk
            : destructive
            ? c.danger
            : pressed
            ? c.print
            : c.signalInk,
        focus: focus,
        focusReach: ApplianceSpacing.tight + ApplianceMetrics.focusWidth,
      );
    case _ButtonKind.key:
      if (disabled) {
        return ApplianceFace.key(c)
            .asDisabled(c)
            .copyWith(foreground: legend, focus: focus);
      }
      return (pressed ? ApplianceFace.keyDown(c) : ApplianceFace.key(c))
          .copyWith(foreground: legend, focus: focus);
    case _ButtonKind.filled:
      if (disabled) {
        return ApplianceFace.key(c)
            .asDisabled(c)
            .copyWith(foreground: legend, focus: focus);
      }
      final top = destructive ? c.danger : c.signalTop;
      final bottom = destructive
          ? Color.lerp(c.danger, c.shade, 0.15)!
          : c.signalBottom;
      final words = destructive ? c.onDanger : c.onSignal;
      // Focused, the lit key's rim glows a pale lamp-light from inside, as
      // another key's rim lights: the signal's own colour would not show on
      // it, and a line under the words would read as a link.
      return ApplianceFace(
        top: pressed ? Color.lerp(bottom, c.shade, 0.08)! : top,
        bottom: pressed ? Color.lerp(top, c.shade, 0.04)! : bottom,
        lift: pressed ? -0.5 : 1,
        travel: pressed ? 1 : 0,
        radius: BorderRadius.circular(ApplianceMetrics.keyRadius),
        foreground: words,
        focus: _litRim.withValues(alpha: applianceControlLight(states)),
      );
  }
}

/// A square key holding one glyph: a top bar's way back, a toolbar's
/// action. [selected] latches it down (a toggle: a favourite, a list view)
/// and lights its lamp.
///
/// A null [onPressed] disables it. [semanticLabel] says what it does, as a
/// tooltip would.
///
/// ```dart
/// ApplianceIconButton(icon: const Icon(LucideIcons.search), semanticLabel: 'Search', onPressed: openSearch)
/// ```
class ApplianceIconButton extends StatelessWidget {
  /// A key with [icon].
  const ApplianceIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.selected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The glyph, 20 px.
  final Widget icon;

  /// What it does, for a screen reader.
  final String semanticLabel;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// Whether a toggle key is latched down; null for an ordinary key.
  final bool? selected;

  /// This key's style, over [ApplianceThemeData.iconButtonStyle].
  final ApplianceStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      // A key that latches: a button that is selected while latched, as
      // Flutter's IconButton(isSelected:) reads.
      semanticSelected: selected,
      excludeSemantics: true,
      selected: selected ?? false,
      builder: (context, states, _) {
        final layered = RawStyleOf([style, theme.iconButtonStyle], states);
        final latched = selected ?? false;
        var face = _keyFace(
          theme,
          {...states, if (latched) WidgetState.pressed},
          _ButtonKind.key,
          false,
        );
        face = layered.on(face);
        final side = layered.minimumSize?.height ?? theme.controlHeight;
        return TapTargetPadding(
          child: SizedBox.square(
            dimension: side,
            child: AnimatedApplianceSurface(
              face: face,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                      size: layered.iconSize ?? 20,
                      color: face.foreground,
                    ),
                    child: icon,
                  ),
                  if (selected != null)
                    PositionedDirectional(
                      top: ApplianceSpacing.small - 2,
                      end: ApplianceSpacing.small - 2,
                      child: ApplianceLamp(
                        lit: latched,
                        size: ApplianceMetrics.lampSize - 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        DiagnosticsProperty<bool>('selected', selected, defaultValue: null),
      );
  }
}
