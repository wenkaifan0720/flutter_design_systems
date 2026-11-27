/// Clay's keys: a coral volume for the one action a screen is for, white clay
/// for the others, words alone for the least, and a round ball for a glyph.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/corners.dart';
import 'popovers.dart' show ClayTooltip;
import 'surface.dart';
import 'theme.dart';

/// The three kinds of Clay key, for [ClayButtonFace].
enum ClayButtonKind {
  /// White clay: any action that is not the screen's one.
  clay,

  /// The coral accent: the one action a screen is for.
  filled,

  /// Words with no key: the least action.
  text,
}

/// A Clay key with its words: white clay by default, the coral accent with
/// [ClayButton.filled] for the one action a screen is for, and words alone
/// with [ClayButton.text] for the least. A press squashes the key into the
/// ground: it lowers, its shadow tightens and its shade deepens.
///
/// A null [onPressed] turns it off: the key settles flat on the ground and
/// its words grey.
///
/// ```dart
/// ClayButton.filled('Add habit', onPressed: () {})
/// ```
class ClayButton extends StatelessWidget {
  /// A white clay key: any action that is not the screen's one.
  const ClayButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = ClayButtonKind.clay;

  /// The coral key: the one action a screen is for. With
  /// [isDestructiveAction] it is moulded in the danger colour, for a
  /// dialog's confirm.
  const ClayButton.filled(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = ClayButtonKind.filled;

  /// Words with no key: the least action, a link-like one, and a destructive
  /// one where it lives. Its words stand on the keyline; its tap target
  /// reaches round them.
  const ClayButton.text(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = ClayButtonKind.text;

  /// The words on the key.
  final String label;

  /// Called on a press; null turns the key off.
  final VoidCallback? onPressed;

  /// Called on a long press.
  final VoidCallback? onLongPress;

  /// A glyph before the words.
  final Widget? icon;

  /// Whether the action destroys something: danger words, or a danger key
  /// under [ClayButton.filled].
  final bool isDestructiveAction;

  /// This key's own style, over [ClayThemeData]'s part theme for its kind.
  final ClayStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  final ClayButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    return RawButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => ClayButtonFace(
        label: label,
        states: states,
        kind: _kind,
        icon: icon,
        isDestructiveAction: isDestructiveAction,
        style: style,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<ClayButtonKind>('kind', _kind))
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
      ..add(DiagnosticsProperty<ClayStyle>('style', style, defaultValue: null));
  }
}

/// A Clay key's face in [states], with no press handling of its own: for a
/// part whose control is ui_core's (a dialog's keys) or the app's own.
///
/// ```dart
/// const ClayButtonFace(label: 'Save', states: {}, kind: ClayButtonKind.filled)
/// ```
class ClayButtonFace extends StatelessWidget {
  /// The face of a key of [kind] reading [label].
  const ClayButtonFace({
    super.key,
    required this.label,
    required this.states,
    this.kind = ClayButtonKind.clay,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
  });

  /// The words on the key.
  final String label;

  /// The key's states.
  final Set<WidgetState> states;

  /// Its kind.
  final ClayButtonKind kind;

  /// A glyph before the words.
  final Widget? icon;

  /// Whether the action destroys something.
  final bool isDestructiveAction;

  /// The key's own style, over [ClayThemeData]'s part theme for its kind.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    return kind == ClayButtonKind.text
        ? _words(context, theme, states)
        : _key(context, theme, states);
  }

  Widget _key(
    BuildContext context,
    ClayThemeData theme,
    Set<WidgetState> states,
  ) {
    final c = theme.colors;
    final filled = kind == ClayButtonKind.filled;
    final layered = RawStyleOf([
      style,
      filled ? theme.filledButtonStyle : theme.buttonStyle,
    ], states);
    final disabled = states.contains(WidgetState.disabled);
    final fill =
        layered.fill ??
        (filled ? (isDestructiveAction ? c.danger : c.accent) : c.clay);
    final words =
        layered.foreground ??
        (disabled
            ? c.inkDisabled
            : filled
            ? c.onColor(fill)
            : isDestructiveAction
            ? c.dangerInk
            : c.ink);
    final radius = clayCornerRadius(theme, layered, RawCorner.medium);
    // A disabled key lies level with the ground: no float, as Material's
    // disabled keys lose their elevation.
    var face = disabled
        ? ClayFace.flat(c, radius: radius).copyWith(shadowOpacity: 0)
        : ClayFace.raised(c, color: fill, radius: radius);
    face = face.copyWith(
      press: states.contains(WidgetState.pressed) ? 1 : 0,
      lift: states.contains(WidgetState.hovered) ? 0.6 : 0,
      focus: states.contains(WidgetState.focused) ? 1 : 0,
    );
    // Room above and below the words as well, so a key grows with large
    // text instead of its words filling it.
    final padding =
        layered.padding(Directionality.of(context)) ??
        theme.density.padding(
          const EdgeInsets.symmetric(
            horizontal: ClaySpacing.large,
            vertical: ClaySpacing.small,
          ),
        );
    return TapTargetPadding(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: layered.minimumSize?.height ?? theme.controlHeight,
          minWidth: layered.minimumSize?.width ?? theme.controlHeight,
        ),
        child: AnimatedClaySurface(
          face: face,
          child: Padding(
            padding: padding,
            child: _content(theme, words, layered),
          ),
        ),
      ),
    );
  }

  Widget _words(
    BuildContext context,
    ClayThemeData theme,
    Set<WidgetState> states,
  ) {
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.textButtonStyle], states);
    final disabled = states.contains(WidgetState.disabled);
    final colour =
        layered.foreground ??
        (disabled
            ? c.inkDisabled
            : isDestructiveAction
            ? c.dangerInk
            : c.accentInk);
    final padding =
        layered.padding(Directionality.of(context)) ?? EdgeInsets.zero;
    return TapTargetPadding(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: layered.minimumSize?.height ?? theme.controlHeight,
          minWidth: layered.minimumSize?.width ?? 0,
        ),
        child: ClayPressDepth(
          pressed: states.contains(WidgetState.pressed),
          builder: (depth) => _FocusUnderline(
            focused: states.contains(WidgetState.focused),
            color: c.focus,
            child: Transform.translate(
              offset: Offset(0, depth),
              child: Padding(
                padding: padding,
                child: _content(
                  theme,
                  Color.lerp(colour, c.ink, 0.3 * depth)!,
                  layered,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(ClayThemeData theme, Color colour, RawStyleOf layered) {
    final weight = FontWeight.w600;
    final text = theme.textTheme.label
        .copyWith(
          color: colour,
          fontWeight: weight,
          fontVariations: clayWeight(weight),
        )
        .merge(layered.textStyle);
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme.merge(
              data: IconThemeData(size: layered.iconSize ?? 20, color: colour),
              child: icon!,
            ),
            const SizedBox(width: ClaySpacing.small),
          ],
          Flexible(
            child: RawCapCenter(
              capHeightFactor: clayCapHeightFactor,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<ClayButtonKind>('kind', kind))
      ..add(IterableProperty<WidgetState>('states', states));
  }
}

/// A 0 to 1 press depth on Clay's press spring, for a part that draws its
/// own press (words, a row).
///
/// ```dart
/// ClayPressDepth(pressed: false, builder: (depth) => Opacity(opacity: 1 - depth / 4, child: const Text('Undo')))
/// ```
class ClayPressDepth extends StatefulWidget {
  /// [builder] at the depth of [pressed].
  const ClayPressDepth({
    super.key,
    required this.pressed,
    required this.builder,
  });

  /// Whether the part is held down.
  final bool pressed;

  /// Builds the part at a press depth, 0 (up) to 1 (all the way in).
  final Widget Function(double depth) builder;

  @override
  State<ClayPressDepth> createState() => _ClayPressDepthState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('pressed', value: pressed, ifTrue: 'pressed'));
  }
}

class _ClayPressDepthState extends State<ClayPressDepth>
    with SingleTickerProviderStateMixin {
  late final AnimationController _depth = AnimationController.unbounded(
    vsync: this,
    value: widget.pressed ? 1 : 0,
  );

  @override
  void didUpdateWidget(ClayPressDepth old) {
    super.didUpdateWidget(old);
    if (old.pressed != widget.pressed) {
      final policy = RawMotionPolicy.of(context);
      _depth.springTo(
        widget.pressed ? 1 : 0,
        policy.spatial(
          dampingRatio: ClayMotion.pressDamping,
          stiffness: ClayMotion.pressStiffness,
        ),
      );
    }
  }

  @override
  void dispose() {
    _depth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _depth,
    builder: (context, _) => widget.builder(_depth.value.clamp(0.0, 1.0)),
  );
}

/// Keyboard focus on words alone: a 2 px rule of the focus colour under
/// them, animated in. Words have no clay of their own to take a rim.
class _FocusUnderline extends StatelessWidget {
  const _FocusUnderline({
    required this.focused,
    required this.color,
    required this.child,
  });

  final bool focused;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: focused ? 1 : 0),
    duration: rawReduceMotionOf(context)
        ? const Duration(milliseconds: 90)
        : const Duration(milliseconds: 140),
    builder: (context, t, child) => CustomPaint(
      foregroundPainter: _Underline(color.withValues(alpha: color.a * t)),
      child: child,
    ),
    child: child,
  );
}

class _Underline extends CustomPainter {
  _Underline(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    final y = size.height / 2 + 13;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, y, size.width, y + 2),
        const Radius.circular(1),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Underline old) => old.color != color;
}

enum _IconKind { clay, filled, plain }

/// A round Clay ball holding a glyph: white clay by default, coral with
/// [ClayIconButton.filled], or a bare glyph with [ClayIconButton.plain] (on
/// a bar, beside a field). [isSelected] holds a toggling ball on: it warms
/// toward the accent. Its [tooltip] stands over it on a hover, a long press
/// or the focus, as `IconButton.tooltip` does, and names it to a screen
/// reader and to `find.byTooltip`.
///
/// ```dart
/// ClayIconButton(onPressed: () {}, icon: const Icon(IconData(0x41)), tooltip: 'Edit')
/// ```
class ClayIconButton extends StatelessWidget {
  /// A white clay ball.
  const ClayIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.isSelected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _IconKind.clay;

  /// A coral ball: a screen's one action, when it is a glyph.
  const ClayIconButton.filled({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : isSelected = null,
       _kind = _IconKind.filled;

  /// A bare glyph: on a top bar, at a field's end.
  const ClayIconButton.plain({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.isSelected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _IconKind.plain;

  /// Called on a press; null turns the ball off.
  final VoidCallback? onPressed;

  /// The glyph.
  final Widget icon;

  /// What the ball does: shown in a [ClayTooltip] over it, and its name to
  /// a screen reader.
  final String tooltip;

  /// Whether a toggling ball is on (warmed toward the accent); null for a
  /// ball that does not toggle, as `IconButton.isSelected`.
  final bool? isSelected;

  /// This ball's own style, over [ClayThemeData.iconButtonStyle].
  final ClayStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  final _IconKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    // The tip names the ball, once: the button takes no label of its own,
    // as Material's IconButton under its Tooltip.
    return ClayTooltip(
      message: tooltip,
      child: RawButton(
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        selected: isSelected ?? false,
        semanticSelected: isSelected,
        excludeSemantics: true,
        builder: (context, states, _) {
          final layered = RawStyleOf([style, theme.iconButtonStyle], states);
          final disabled = states.contains(WidgetState.disabled);
          final pressed = states.contains(WidgetState.pressed);
          final focused = states.contains(WidgetState.focused);
          final on = isSelected ?? false;
          final side = layered.minimumSize?.height ?? theme.controlHeight - 4;
          final glyph = layered.iconSize ?? 20;
          if (_kind == _IconKind.plain) {
            final colour =
                layered.foreground ??
                (disabled
                    ? c.inkDisabled
                    : on
                    ? c.accentInk
                    : c.ink);
            return TapTargetPadding(
              child: SizedBox.square(
                dimension: side,
                child: AnimatedClaySurface(
                  // A bare glyph shows its press and its focus as a small well
                  // opening under it.
                  face: ClayFace.well(c, radius: side / 2).copyWith(
                    lightOpacity: pressed || focused ? null : 0,
                    shadeOpacity: pressed || focused ? null : 0,
                    color: pressed || focused
                        ? null
                        : c.well.withValues(alpha: 0),
                    focus: focused ? 1 : 0,
                  ),
                  child: Center(
                    child: IconTheme.merge(
                      data: IconThemeData(size: glyph, color: colour),
                      child: icon,
                    ),
                  ),
                ),
              ),
            );
          }
          final filled = _kind == _IconKind.filled;
          final fill = layered.fill ?? (filled ? c.accent : c.clay);
          ClayFace face;
          if (disabled) {
            face = ClayFace.flat(
              c,
              radius: side / 2,
            ).copyWith(shadowOpacity: 0);
          } else if (on) {
            // Held on, the ball warms toward the accent (or takes its style's
            // fill): what is chosen takes colour and stands up.
            face = ClayFace.raised(
              c,
              color: layered.fill ?? clayChosenFill(c),
              radius: side / 2,
            );
          } else {
            face = ClayFace.raised(c, color: fill, radius: side / 2);
          }
          face = face.copyWith(
            press: pressed ? 1 : 0,
            lift: states.contains(WidgetState.hovered) ? 0.6 : 0,
            focus: focused ? 1 : 0,
          );
          final colour =
              layered.foreground ??
              (disabled
                  ? c.inkDisabled
                  : on
                  ? c.onColor(layered.fill ?? clayChosenFill(c))
                  : filled
                  ? c.onColor(fill)
                  : c.ink);
          return TapTargetPadding(
            child: SizedBox.square(
              dimension: side,
              child: AnimatedClaySurface(
                face: face,
                child: Center(
                  child: IconTheme.merge(
                    data: IconThemeData(size: glyph, color: colour),
                    child: icon,
                  ),
                ),
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
      ..add(StringProperty('tooltip', tooltip))
      ..add(EnumProperty<_IconKind>('kind', _kind))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        DiagnosticsProperty<bool>('isSelected', isSelected, defaultValue: null),
      );
  }
}
