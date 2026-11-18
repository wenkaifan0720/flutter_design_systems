/// Studio's keys: [StudioButton] (a key, `.lit` for a screen's main action,
/// `.text` for a legend with no cap) and [StudioIconButton].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'surface.dart';
import 'theme.dart';

enum _KeyKind { plain, lit, text }

/// A key. It stands proud of the metal, lit from the top; a press sinks it
/// and its shadow closes, and it springs back when let go.
///
/// The unnamed constructor is the ordinary key; [StudioButton.lit] is a
/// screen's one main action, a brushed graphite key whose legend and lamp
/// are lit in the indicator light (amber means on: the key is not filled
/// with it); [StudioButton.text] is a legend with no cap, whose recess shows
/// only under a press. [isDestructiveAction] lights any of them in the danger
/// colour.
///
/// A null [onPressed] disables it: its legend dims and a lit key's legend
/// and lamp go out.
/// It takes the width it is given when that is tight, and its content's
/// otherwise.
///
/// Reads [style]'s `fill`, `foreground`, `padding`, `minimumSize`,
/// `textStyle` and `iconSize`, then its kind's theme slot
/// ([StudioThemeData.buttonStyle], [StudioThemeData.litButtonStyle] or
/// [StudioThemeData.textButtonStyle]), with
/// [StudioThemeData.destructiveButtonStyle] between them for a destructive
/// one. The light, the depth and the corners stay the look's.
///
/// ```dart
/// StudioButton.lit('Publish', onPressed: () => publish())
/// ```
class StudioButton extends StatelessWidget {
  /// An ordinary key.
  const StudioButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = _KeyKind.plain;

  /// A screen's one main action: a graphite key, its legend and lamp lit.
  const StudioButton.lit(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = _KeyKind.lit;

  /// A quiet action: its legend on the metal with no cap; a press shows the
  /// recess under it. Its words stand on the line its neighbours start on.
  const StudioButton.text(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = _KeyKind.text;

  /// The legend: one line, sentence case, cut short with an ellipsis when
  /// the key is narrower.
  final String label;

  /// What a press does; null disables the key.
  final VoidCallback? onPressed;

  /// What a long press does, when anything.
  final VoidCallback? onLongPress;

  /// A glyph before the legend, 20 px.
  final Widget? icon;

  /// Whether the action destroys something (discards a take, deletes an
  /// episode): lit in the danger colour, as `CupertinoDialogAction` names
  /// it.
  final bool isDestructiveAction;

  /// This key's style, over its kind's theme slot.
  final StudioStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  final _KeyKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    return DesignPressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      // One node named by its words, a glyph beside them or not.
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = DesignStyleOf(_layers(theme), states);
        final face = layered.on(_face(theme, states));
        final text = _kind == _KeyKind.text;
        final lit = _kind == _KeyKind.lit;
        final disabled = states.contains(WidgetState.disabled);
        final padding =
            layered.padding(Directionality.of(context)) ??
            EdgeInsets.symmetric(
              horizontal:
                  (text ? StudioSpacing.small : StudioSpacing.regular + 2) +
                  theme.density.paddingDelta,
            );
        final minimum = layered.minimumSize ?? Size(0, theme.controlHeight);
        final words = DefaultTextStyle.merge(
          style: theme.textTheme.label
              .copyWith(
                color: face.foreground,
                fontWeight: lit ? FontWeight.w600 : FontWeight.w500,
                // A lit legend gives off its light.
                shadows: lit && !disabled
                    ? [
                        Shadow(
                          color: (face.foreground ?? theme.colors.onLitKey)
                              .withValues(alpha: 0.45),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              )
              .merge(layered.textStyle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: DesignCapCenter(
            capHeightFactor: theme.capHeightFactor,
            child: Text(label),
          ),
        );
        return DesignTapTarget(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minimum.width,
              minHeight: minimum.height,
            ),
            child: AnimatedStudioSurface(
              face: face,
              child: Padding(
                padding: padding,
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lit) ...[
                        StudioLamp(
                          on: !disabled,
                          size: 6,
                          color: isDestructiveAction
                              ? theme.colors.danger
                              : null,
                        ),
                        const SizedBox(width: StudioSpacing.small),
                      ],
                      if (icon != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(
                            size: layered.iconSize ?? 20,
                            color: face.foreground,
                          ),
                          child: icon!,
                        ),
                        const SizedBox(width: StudioSpacing.small),
                      ],
                      Flexible(child: words),
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

  List<StudioStyle?> _layers(StudioThemeData theme) => [
    style,
    if (isDestructiveAction) theme.destructiveButtonStyle,
    switch (_kind) {
      _KeyKind.plain => theme.buttonStyle,
      _KeyKind.lit => theme.litButtonStyle,
      _KeyKind.text => theme.textButtonStyle,
    },
  ];

  StudioFace _face(StudioThemeData theme, Set<WidgetState> states) {
    final c = theme.colors;
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final focus = states.contains(WidgetState.focused)
        ? c.focusRing
        : c.focusRing.withValues(alpha: 0);
    switch (_kind) {
      case _KeyKind.text:
        return c.recessFace.copyWith(
          radius: StudioRadii.key,
          presence: pressed ? 1 : 0,
          foreground: disabled
              ? c.disabled
              : isDestructiveAction
              ? c.dangerLegend
              : c.legend,
          focus: focus,
        );
      case _KeyKind.plain:
        return c.keyFace.copyWith(
          travel: pressed ? 1 : 0,
          foreground: disabled
              ? c.disabled
              : isDestructiveAction
              ? c.dangerLegend
              : c.onKey,
          fill: disabled ? Color.lerp(c.key, c.panelLow, 0.5) : null,
          focus: focus,
        );
      case _KeyKind.lit:
        // The graphite key; with no power its legend and lamp are out.
        return c.litKeyFace.copyWith(
          travel: pressed ? 1 : 0,
          foreground: disabled
              ? c.onLitKeyOff
              : isDestructiveAction
              ? c.onLitKeyDanger
              : c.onLitKey,
          focus: focus,
        );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<_KeyKind>('kind', _kind))
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
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

/// A square key with a glyph: the bar's back key, a toolbar's action.
/// [selected] latches it down with its glyph lit, as a key that stays in.
///
/// A null [onPressed] disables it. [tooltip] names it to a screen reader.
///
/// Reads [style]'s `fill`, `foreground`, `minimumSize` (its side) and
/// `iconSize`, then [StudioThemeData.iconButtonStyle].
///
/// ```dart
/// StudioIconButton(icon: const Icon(LucideIcons.chevronLeft), tooltip: 'Back', onPressed: () => Navigator.pop(context))
/// ```
class StudioIconButton extends StatelessWidget {
  /// A key showing [icon].
  const StudioIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.selected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The glyph, 20 px.
  final Widget icon;

  /// What a press does; null disables the key.
  final VoidCallback? onPressed;

  /// What it is called, for a screen reader.
  final String tooltip;

  /// Whether it is latched in; null for a key that does not latch.
  final bool? selected;

  /// This key's style, over [StudioThemeData.iconButtonStyle].
  final StudioStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected ?? false,
      semanticSelected: selected,
      semanticLabel: tooltip,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.iconButtonStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final latched = selected ?? false;
        final face = layered.on(
          c.keyFace
              .copyWith(
                travel: pressed || latched ? 1 : 0,
                fill: disabled ? Color.lerp(c.key, c.panelLow, 0.5) : null,
                foreground: disabled
                    ? c.disabled
                    : latched
                    ? c.litLegend
                    : c.onKey,
                focus: states.contains(WidgetState.focused)
                    ? c.focusRing
                    : c.focusRing.withValues(alpha: 0),
              )
              .backlitIf(c, latched && !disabled),
        );
        final side = layered.minimumSize?.height ?? theme.controlHeight;
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: side,
            child: AnimatedStudioSurface(
              face: face,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: layered.iconSize ?? 20,
                    color: face.foreground,
                  ),
                  child: icon,
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
      ..add(StringProperty('tooltip', tooltip))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        DiagnosticsProperty<bool>('selected', selected, defaultValue: null),
      );
  }
}

/// A transport key: a large round key for play, pause and record. [lit]
/// turns it to the graphite main key with its glyph and lamp lit (playing);
/// [record] gives it a red lamp, lit while [lit] (recording). A press sinks
/// it.
///
/// A null [onPressed] disables it. [tooltip] names it to a screen reader.
///
/// ```dart
/// StudioTransportKey(icon: const Icon(LucideIcons.play), tooltip: 'Play', onPressed: play)
/// ```
class StudioTransportKey extends StatelessWidget {
  /// A round key showing [icon].
  const StudioTransportKey({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.lit = false,
    this.record = false,
    this.size = 64,
    this.focusNode,
    this.autofocus = false,
  });

  /// Its glyph.
  final Widget icon;

  /// What it does, for a screen reader.
  final String tooltip;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// Whether it is lit: playing, or recording.
  final bool lit;

  /// Whether it is the record key, with its red lamp.
  final bool record;

  /// Its diameter.
  final double size;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: tooltip,
      toggled: record ? lit : null,
      builder: (context, states, _) {
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final base = lit && !record ? c.litKeyFace : c.keyFace;
        final face = base.copyWith(
          radius: size / 2,
          travel: pressed ? 1 : 0,
          fill: disabled ? Color.lerp(c.key, c.panelLow, 0.5) : null,
          foreground: disabled
              ? c.disabled
              : lit && !record
              ? c.onLitKey
              : record
              ? c.dangerLegend
              : c.onKey,
          focus: states.contains(WidgetState.focused)
              ? c.focusRing
              : c.focusRing.withValues(alpha: 0),
        );
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedStudioSurface(
              face: face,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(
                      size: size * 0.38,
                      color: face.foreground,
                      shadows: lit && !record && !disabled
                          ? [
                              Shadow(
                                color:
                                    (face.foreground ?? theme.colors.onLitKey)
                                        .withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: icon,
                  ),
                  if (record || lit)
                    Positioned(
                      top: size * 0.14,
                      child: StudioLamp(
                        on: lit && !disabled,
                        color: record ? c.danger : null,
                        size: 7,
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
}
