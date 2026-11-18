/// Gloss's keys: the jade gel key for the one action a screen is for, the
/// pearl key for the others, letterpressed words for the least, and the
/// round bead for a glyph.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/key_paint.dart';
import 'surface.dart';
import 'theme.dart';

/// A Gloss key with its words: pearl by default, a jade gel key with
/// [GlossButton.filled] for the one action a screen is for, and
/// letterpressed words with [GlossButton.text] for the least. A press sinks
/// the key 1.5 px and dims its shine; it comes back with a little give.
///
/// A null [onPressed] turns it off: the key flattens and its words grey.
///
/// ```dart
/// GlossButton.filled('Plan the week', onPressed: () {})
/// ```
class GlossButton extends StatelessWidget {
  /// A pearl key: any action that is not the screen's one.
  const GlossButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = GlossKeyKind.pearl;

  /// The jade gel key: the one action a screen is for. With
  /// [isDestructiveAction] it is moulded in ruby, for a dialog's confirm.
  const GlossButton.filled(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = GlossKeyKind.gel;

  /// Letterpressed words with no key: the least action, a link-like one,
  /// and a destructive one where it lives. Its words stand on the keyline;
  /// its tap target reaches round them.
  const GlossButton.text(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.onLongPress,
  }) : _kind = GlossKeyKind.text;

  /// The words on the key.
  final String label;

  /// Called on a press; null turns the key off.
  final VoidCallback? onPressed;

  /// Called on a long press.
  final VoidCallback? onLongPress;

  /// A glyph before the words.
  final Widget? icon;

  /// Whether the action destroys something: ruby words, or a ruby gel key
  /// under [GlossButton.filled].
  final bool isDestructiveAction;

  /// This key's own style, over [GlossThemeData]'s part theme for its kind.
  final GlossStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  final GlossKeyKind _kind;

  /// Whether it is words alone ([GlossButton.text]): no face, its words
  /// standing in a slot a finger can reach, so a part that lays it under
  /// words sets it closer.
  bool get isWordsOnly => _kind == GlossKeyKind.text;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    if (_kind == GlossKeyKind.text) return _buildText(context, theme);
    return DesignPressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states, _) => glossKeyPaint(
        context,
        states,
        kind: _kind,
        label: label,
        icon: icon,
        destructive: isDestructiveAction,
        style: style,
      ),
    );
  }

  Widget _buildText(BuildContext context, GlossThemeData theme) {
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.textButtonStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final focused = states.contains(WidgetState.focused);
        final colour =
            layered.foreground ??
            (disabled
                ? c.inkDisabled
                : isDestructiveAction
                ? c.danger
                : c.jadeInk);
        final padding =
            layered.padding(Directionality.of(context)) ?? EdgeInsets.zero;
        final large = MediaQuery.textScalerOf(context).scale(10) >= 15;
        return DesignTapTarget(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: layered.minimumSize?.height ?? theme.controlHeight,
              minWidth: layered.minimumSize?.width ?? 0,
            ),
            child: _Pressed(
              pressed: pressed,
              builder: (depth) => CustomPaint(
                foregroundPainter: focused ? _TextFocusPainter(c.focus) : null,
                child: Padding(
                  padding: padding,
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          IconTheme.merge(
                            data: IconThemeData(
                              size: layered.iconSize ?? 20,
                              color: colour,
                            ),
                            child: icon!,
                          ),
                          const SizedBox(width: GlossSpacing.tight + 2),
                        ],
                        Flexible(
                          child: DefaultTextStyle.merge(
                            maxLines: large ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: glossLetterpress(
                              theme.textTheme.label.copyWith(
                                color: Color.lerp(colour, c.ink, 0.25 * depth),
                              ),
                              c.copyWith(
                                letterpress: c.letterpress.withValues(
                                  alpha: c.letterpress.a * (1 - depth),
                                ),
                              ),
                            ).merge(layered.textStyle),
                            child: DesignCapCenter(
                              capHeightFactor: glossCapHeightFactor,
                              child: Text(label),
                            ),
                          ),
                        ),
                      ],
                    ),
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
      ..add(EnumProperty<GlossKeyKind>('kind', _kind))
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
        DiagnosticsProperty<GlossStyle>('style', style, defaultValue: null),
      );
  }
}

/// A 0 to 1 press depth on Gloss's press spring, for a part that draws its
/// own press (letterpressed words, a row).
class _Pressed extends StatefulWidget {
  const _Pressed({required this.pressed, required this.builder});

  final bool pressed;
  final Widget Function(double depth) builder;

  @override
  State<_Pressed> createState() => _PressedState();
}

class _PressedState extends State<_Pressed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _depth = AnimationController.unbounded(
    vsync: this,
    value: widget.pressed ? 1 : 0,
  );

  @override
  void didUpdateWidget(_Pressed old) {
    super.didUpdateWidget(old);
    if (old.pressed != widget.pressed) {
      _depth.springTo(
        widget.pressed ? 1 : 0,
        DesignMotionPolicy.of(context)
            .spatial(dampingRatio: 1, stiffness: GlossMotion.pressStiffness),
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

/// A text button's focus: a capsule ring round its words, 4 px clear of them.
class _TextFocusPainter extends CustomPainter {
  _TextFocusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final box = (Offset.zero & size).inflate(6);
    canvas.drawRRect(
      glossOutline(box, null),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GlossMetrics.focusWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TextFocusPainter old) => old.color != color;
}

enum _IconButtonKind { pearl, gel, plain }

/// A round Gloss bead holding a glyph: pearl by default, jade gel with
/// [GlossIconButton.filled], or a bare letterpressed glyph with
/// [GlossIconButton.plain] (on a bar, beside a field). [selected] latches a
/// pearl bead in: it stays sunk and its glyph turns jade.
///
/// ```dart
/// GlossIconButton(onPressed: () {}, icon: const Icon(LucideIcons.heart), tooltip: 'Save')
/// ```
class GlossIconButton extends StatelessWidget {
  /// A pearl bead.
  const GlossIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.selected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _IconButtonKind.pearl;

  /// A jade gel bead: a screen's one action, when it is a glyph.
  const GlossIconButton.filled({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : selected = null,
       _kind = _IconButtonKind.gel;

  /// A bare glyph letterpressed into the surface it stands on.
  const GlossIconButton.plain({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.selected,
    this.style,
    this.focusNode,
    this.autofocus = false,
  }) : _kind = _IconButtonKind.plain;

  /// Called on a press; null turns the bead off.
  final VoidCallback? onPressed;

  /// The glyph.
  final Widget icon;

  /// What the bead does, for a screen reader.
  final String tooltip;

  /// Whether a toggling bead is on (latched in, its glyph jade); null for a
  /// bead that does not toggle, as `IconButton.isSelected`.
  final bool? selected;

  /// This bead's own style, over [GlossThemeData.iconButtonStyle].
  final GlossStyle? style;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  final _IconButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignPressable(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected ?? false,
      toggled: selected,
      semanticLabel: tooltip,
      builder: (context, states, _) {
        final layered = DesignStyleOf([style, theme.iconButtonStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final pressed = states.contains(WidgetState.pressed);
        final on = selected ?? false;
        final focus = glossFocusOf(
          c,
          focused: states.contains(WidgetState.focused),
        );
        final side = layered.minimumSize?.height ?? theme.controlHeight - 8;
        final glyph = layered.iconSize ?? 20;
        if (_kind == _IconButtonKind.plain) {
          final colour =
              layered.foreground ??
              (disabled
                  ? c.inkDisabled
                  : on
                  ? c.jadeInk
                  : c.ink);
          return DesignTapTarget(
            child: SizedBox.square(
              dimension: side,
              child: _Pressed(
                pressed: pressed,
                builder: (depth) => CustomPaint(
                  painter: focus.a > 0 ? _BeadFocusPainter(focus) : null,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, depth),
                      child: IconTheme.merge(
                        data: IconThemeData(
                          size: glyph,
                          color: colour,
                          shadows: [
                            Shadow(
                              color: c.letterpress.withValues(
                                alpha: c.letterpress.a * (1 - depth),
                              ),
                              offset: Offset(0, c.letterpressBelow ? 1 : -1),
                            ),
                          ],
                        ),
                        child: icon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        GlossFace face;
        if (disabled) {
          face = GlossFace.pearlOff(c);
        } else if (_kind == _IconButtonKind.gel) {
          face = GlossFace.gel(c).copyWith(travel: pressed ? 1 : 0);
        } else if (on) {
          // Latched in: sunk into its seat, its glyph lit.
          face = GlossFace.well(c).copyWith(foreground: c.jadeInk, lift: -0.7);
        } else {
          face = GlossFace.pearl(c).copyWith(travel: pressed ? 1 : 0);
        }
        if (layered.fill != null) face = face.glazed(layered.fill!);
        face = face.copyWith(foreground: layered.foreground, focus: focus);
        return DesignTapTarget(
          child: SizedBox.square(
            dimension: side,
            child: AnimatedGlossSurface(
              face: face,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(size: glyph),
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
      ..add(EnumProperty<_IconButtonKind>('kind', _kind))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        DiagnosticsProperty<bool>('selected', selected, defaultValue: null),
      );
  }
}

class _BeadFocusPainter extends CustomPainter {
  _BeadFocusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide / 2 - GlossMetrics.focusWidth / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GlossMetrics.focusWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_BeadFocusPainter old) => old.color != color;
}
