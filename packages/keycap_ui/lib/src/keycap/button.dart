/// Keycap's buttons: keys. [KeycapButton] is a light alpha key (a neutral
/// action), [KeycapButton.modifier] a darker one (a secondary action),
/// [KeycapButton.accent] the one coloured key (the screen's main action),
/// [KeycapButton.text] a legend printed on the case with no cap under it.
/// [KeycapIconButton] is a square key with a glyph for a legend.
/// [KeycapLink] is words printed in the accent's ink that go somewhere;
/// [KeycapKbd] a small cap naming a key on the keyboard.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'cap.dart';
import 'internal/spring_value.dart';
import 'theme.dart';

enum _ButtonKind { alpha, modifier, accent, text }

/// A key that does something when pressed: it travels down onto its switch
/// and comes back up. Each kind has its own constructor and its own
/// component theme on [KeycapThemeData], as Material's buttons do.
///
/// [isDestructiveAction] makes it a key that destroys: on a page, the
/// legend reads in the danger colour and the key stays quiet; as
/// [KeycapButton.accent] in a dialog that confirms the loss, the whole key
/// is moulded in the danger plastic.
///
/// ```dart
/// KeycapButton.accent(onPressed: save, child: const Text('Save note'))
/// ```
class KeycapButton extends StatelessWidget {
  /// A light alpha key: a neutral action.
  const KeycapButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : _kind = _ButtonKind.alpha;

  /// A darker modifier key: a secondary action beside the main one.
  const KeycapButton.modifier({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : _kind = _ButtonKind.modifier;

  /// The one coloured key: the screen's main action. With
  /// [isDestructiveAction], the danger key that confirms a loss.
  const KeycapButton.accent({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : _kind = _ButtonKind.accent;

  /// A legend printed on the case, with no cap: the least of a screen's
  /// actions.
  const KeycapButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.onLongPress,
    this.icon,
    this.isDestructiveAction = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : _kind = _ButtonKind.text;

  final _ButtonKind _kind;

  /// Called when the key is pressed; null turns it off.
  final VoidCallback? onPressed;

  /// Called when the key is held.
  final VoidCallback? onLongPress;

  /// The legend: usually a `Text`.
  final Widget child;

  /// A glyph before the legend.
  final Widget? icon;

  /// Whether the action destroys something.
  final bool isDestructiveAction;

  /// Overrides for this key, over its component theme.
  final KeycapStyle? style;

  /// The key's focus node.
  final FocusNode? focusNode;

  /// Whether the key takes focus when it first appears.
  final bool autofocus;

  /// What a screen reader says, when the legend is not enough.
  final String? semanticLabel;

  KeycapStyle? _themed(KeycapThemeData theme) => switch (_kind) {
    _ButtonKind.alpha => theme.buttonStyle,
    _ButtonKind.modifier => theme.modifierButtonStyle,
    _ButtonKind.accent => theme.accentButtonStyle,
    _ButtonKind.text => theme.textButtonStyle,
  };

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final backlit = !MediaQuery.highContrastOf(context);
    return RawButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      builder: (context, states, _) {
        final layered = RawStyleOf([style, _themed(theme)], states);
        final height = layered.minimumSize?.height ?? theme.controlHeight;
        final walls = KeycapMetrics.walls(theme.controlHeight);
        final dir = Directionality.of(context);
        final textStyle = theme.textTheme.label.merge(layered.textStyle);
        if (_kind == _ButtonKind.text) {
          return _PrintedLegend(
            states: states,
            destructive: isDestructiveAction,
            height: height,
            // Its words stand where a cap's of its height do, on the top
            // face over the front wall, so a printed key beside a cap
            // shares its centre line.
            padding:
                (layered.padding(dir) ??
                    EdgeInsets.symmetric(
                      horizontal: 12 + theme.density.paddingDelta / 2,
                    )) +
                EdgeInsets.only(
                  top: KeycapMetrics.walls(height).back,
                  bottom: KeycapMetrics.walls(height).front,
                ),
            foreground: layered.foreground,
            textStyle: textStyle,
            iconSize: layered.iconSize ?? 18,
            icon: icon,
            child: child,
          );
        }
        final kind = switch (_kind) {
          _ButtonKind.accent =>
            isDestructiveAction ? KeycapKind.danger : KeycapKind.accent,
          _ButtonKind.modifier when !isDestructiveAction => KeycapKind.modifier,
          _ => KeycapKind.alpha,
        };
        var face = keycapKeyFace(theme, kind, states, backlit: backlit);
        if (isDestructiveAction &&
            kind == KeycapKind.alpha &&
            !states.contains(WidgetState.disabled)) {
          face = face.copyWith(legend: theme.colors.dangerInk);
        }
        face = layered.on(face);
        final padding =
            layered.padding(dir) ??
            EdgeInsets.symmetric(horizontal: 18 + theme.density.paddingDelta);
        return TapTargetPadding(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height,
              minWidth: layered.minimumSize?.width ?? 64,
            ),
            child: AnimatedKeycapCap(
              face: face,
              walls: walls,
              child: Padding(
                padding: padding,
                child: _Legend(
                  icon: icon,
                  iconSize: layered.iconSize ?? 18,
                  textStyle: textStyle.copyWith(color: face.legend),
                  color: face.legend,
                  child: child,
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
        DiagnosticsProperty<KeycapStyle>('style', style, defaultValue: null),
      );
  }
}

// A glyph and words, centred on the words' capitals.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.icon,
    required this.iconSize,
    required this.textStyle,
    required this.color,
    required this.child,
  });

  final Widget? icon;
  final double iconSize;
  final TextStyle textStyle;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final words = DefaultTextStyle(
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      child: RawCapCenter(capHeightFactor: theme.capHeightFactor, child: child),
    );
    return IconTheme.merge(
      data: IconThemeData(color: color, size: iconSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: KeycapSpacing.small),
          ],
          Flexible(child: words),
        ],
      ),
    );
  }
}

// A legend printed on the case: no cap, in the ink (cobalt is the main key's
// alone; a loss prints in the danger ink). It dims as it is pressed and is
// ringed by the focus band when it holds focus.
class _PrintedLegend extends StatelessWidget {
  const _PrintedLegend({
    required this.states,
    required this.destructive,
    required this.height,
    required this.padding,
    required this.foreground,
    required this.textStyle,
    required this.iconSize,
    required this.icon,
    required this.child,
  });

  final Set<WidgetState> states;
  final bool destructive;
  final double height;
  final EdgeInsets padding;
  final Color? foreground;
  final TextStyle textStyle;
  final double iconSize;
  final Widget? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final rest = disabled
        ? c.inkDisabled
        : foreground ?? (destructive ? c.dangerInk : c.ink);
    final down = disabled || destructive
        ? rest
        : Color.lerp(rest, c.inkMuted, 0.7)!;
    final focused = states.contains(WidgetState.focused);
    return TapTargetPadding(
      child: KeycapSpringValue(
        value: focused ? 1 : 0,
        spring: KeycapMotion.colour,
        spatial: false,
        builder: (context, f, child) => CustomPaint(
          foregroundPainter: _FocusBand(
            c.focus.withValues(alpha: c.focus.a * f.clamp(0.0, 1.0)),
          ),
          child: child,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Padding(
            padding: padding,
            child: KeycapSpringValue(
              value: pressed ? 1 : 0,
              spring: KeycapMotion.colour,
              spatial: false,
              builder: (context, t, _) {
                final color = Color.lerp(rest, down, t.clamp(0.0, 1.0))!;
                return _Legend(
                  icon: icon,
                  iconSize: iconSize,
                  textStyle: textStyle.copyWith(color: color),
                  color: color,
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusBand extends CustomPainter {
  _FocusBand(this.color, {this.radius = KeycapMetrics.keyRadius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    const w = KeycapMetrics.focusWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(w / 2),
        Radius.circular(radius),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FocusBand old) =>
      old.color != color || old.radius != radius;
}

/// A square key with a glyph for its legend: a top bar's back key, a
/// toolbar's formatting keys. With [isSelected] it latches: it stays part way
/// down, in the modifier plastic, until pressed again.
///
/// ```dart
/// KeycapIconButton(icon: const Icon(LucideIcons.bold), semanticLabel: 'Bold', isSelected: bold, onPressed: toggleBold)
/// ```
class KeycapIconButton extends StatelessWidget {
  /// A square key with [icon].
  const KeycapIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.isSelected,
    this.accent = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The glyph.
  final Widget icon;

  /// What the key does, for a screen reader (and its tooltip's words).
  final String semanticLabel;

  /// Called when the key is pressed; null turns it off.
  final VoidCallback? onPressed;

  /// Whether the key is latched down; null for a key that does not latch.
  final bool? isSelected;

  /// Whether this is the screen's main action, moulded in the accent.
  final bool accent;

  /// Overrides for this key, over [KeycapThemeData.iconButtonStyle].
  final KeycapStyle? style;

  /// The key's focus node.
  final FocusNode? focusNode;

  /// Whether the key takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final backlit = !MediaQuery.highContrastOf(context);
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: semanticLabel,
      // A toggle button: a button, selected while on, as Flutter's
      // `IconButton(isSelected:)` says it.
      semanticSelected: isSelected,
      excludeSemantics: true,
      selected: isSelected ?? false,
      builder: (context, states, _) {
        final layered = RawStyleOf([style, theme.iconButtonStyle], states);
        var face = keycapKeyFace(
          theme,
          accent ? KeycapKind.accent : KeycapKind.alpha,
          states,
          latched: isSelected ?? false,
          backlit: backlit,
        );
        face = layered.on(face);
        final side = layered.minimumSize?.height ?? theme.controlHeight;
        return TapTargetPadding(
          child: SizedBox.square(
            dimension: side,
            child: AnimatedKeycapCap(
              face: face,
              walls: KeycapMetrics.walls(theme.controlHeight),
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(
                    size: layered.iconSize ?? 20,
                    color: face.legend,
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
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(
        FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
      )
      ..add(
        DiagnosticsProperty<bool>('isSelected', isSelected, defaultValue: null),
      );
  }
}

/// A tall key with two legends, as a keycap prints a symbol over its
/// letter: a glyph and the [legend] at its top start, a [subLegend] (a
/// count, a shortcut) at its bottom end. A home screen's way into a place.
///
/// ```dart
/// KeycapLegendKey(icon: const Icon(LucideIcons.sprout), legend: 'Garden', subLegend: '2', onPressed: openGarden)
/// ```
class KeycapLegendKey extends StatelessWidget {
  /// A key with two legends.
  const KeycapLegendKey({
    super.key,
    required this.legend,
    required this.onPressed,
    this.icon,
    this.subLegend,
    this.semanticLabel,
    this.modifier = false,
    this.style,
    this.focusNode,
  });

  /// The main legend.
  final String legend;

  /// The second legend, at the bottom end.
  final String? subLegend;

  /// A glyph before the main legend.
  final Widget? icon;

  /// Called when the key is pressed; null turns it off.
  final VoidCallback? onPressed;

  /// What a screen reader says; the legends when null.
  final String? semanticLabel;

  /// Whether it is moulded as a modifier rather than an alpha.
  final bool modifier;

  /// Overrides, over [KeycapThemeData.buttonStyle].
  final KeycapStyle? style;

  /// The key's focus node.
  final FocusNode? focusNode;

  /// The key's height.
  static const double height = 76;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final backlit = !MediaQuery.highContrastOf(context);
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel:
          semanticLabel ?? (subLegend == null ? legend : '$legend, $subLegend'),
      excludeSemantics: true,
      builder: (context, states, _) {
        final layered = RawStyleOf([style, theme.buttonStyle], states);
        var face = keycapKeyFace(
          theme,
          modifier ? KeycapKind.modifier : KeycapKind.alpha,
          states,
          backlit: backlit,
        );
        face = layered.on(face);
        // Two lines of words: the key grows by both as text grows, and by a
        // second line of the legend where one can't hold it.
        final h =
            KeycapMetrics.grown(
              context,
              layered.minimumSize?.height ?? height,
              theme.textTheme.label,
            ) +
            KeycapMetrics.grown(context, 0, theme.textTheme.figure);
        final label = theme.textTheme.label;
        final line =
            MediaQuery.textScalerOf(context).scale(label.fontSize!) *
            (label.height ?? 1);
        return TapTargetPadding(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h),
            child: AnimatedKeycapCap(
              face: face,
              walls: KeycapMetrics.walls(theme.controlHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  KeycapSpacing.medium,
                  KeycapSpacing.small,
                  KeycapSpacing.medium,
                  KeycapSpacing.small,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      // The icon stands on the legend's first line, however
                      // many lines the legend takes.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          SizedBox(
                            height: math.max(18.0, line),
                            child: Center(
                              child: IconTheme.merge(
                                data: IconThemeData(
                                  size: 18,
                                  color: face.legend,
                                ),
                                child: icon!,
                              ),
                            ),
                          ),
                          const SizedBox(width: KeycapSpacing.small),
                        ],
                        Expanded(
                          child: Text(
                            legend,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.label.copyWith(
                              color: face.legend,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subLegend != null) ...[
                      // The value stands clear of the legend, however many
                      // lines the legend takes.
                      const SizedBox(height: KeycapSpacing.small),
                      Text(
                        subLegend!,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        // A quarter of the way to the key's top: quieter than
                        // the legend, and at 4.5:1 on the key by night too.
                        style: theme.textTheme.figure.copyWith(
                          color: Color.lerp(face.legend, face.top, 0.25),
                        ),
                      ),
                    ],
                  ],
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
      ..add(StringProperty('legend', legend))
      ..add(StringProperty('subLegend', subLegend, defaultValue: null));
  }
}

/// A keyboard shortcut printed as the small keys it is pressed on: a
/// settings row's or a menu's. A screen reader hears [semanticLabel].
///
/// ```dart
/// const KeycapShortcut(keys: ['Ctrl', 'N'], semanticLabel: 'Control N')
/// ```
class KeycapShortcut extends StatelessWidget {
  /// The keys of a shortcut.
  const KeycapShortcut({
    super.key,
    required this.keys,
    required this.semanticLabel,
  });

  /// Each key's legend, in the order they are pressed.
  final List<String> keys;

  /// The shortcut in words.
  final String semanticLabel;

  /// A key's height.
  static const double height = 26;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final face = keycapKeyFace(theme, KeycapKind.alpha, const {});
    final tall = KeycapMetrics.grown(context, height, theme.textTheme.legend);
    final walls = KeycapMetrics.walls(tall);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, k) in keys.indexed) ...[
            if (i > 0) const SizedBox(width: KeycapMetrics.keyGap),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: tall),
              child: SizedBox(
                height: tall,
                child: KeycapCap(
                  face: face.copyWith(radius: 5),
                  walls: walls,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KeycapSpacing.small,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        k,
                        maxLines: 1,
                        style: theme.textTheme.legend.copyWith(
                          color: face.legend,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('keys', keys));
  }
}

/// Words that go somewhere: printed on the case in the accent's ink and
/// underlined, with no cap under them (a link is read, then followed). It
/// dims as it is pressed and is ringed by the focus band when it holds
/// focus; a pointer over it changes nothing. A screen reader hears a link.
///
/// ```dart
/// KeycapLink(onPressed: openHelp, child: const Text('How sync works'))
/// ```
class KeycapLink extends StatelessWidget {
  /// A link reading [child].
  const KeycapLink({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.focusNode,
    this.semanticLabel,
  });

  /// Follows the link; null turns it off.
  final VoidCallback? onPressed;

  /// The words: usually a `Text`.
  final Widget child;

  /// Overrides, over [KeycapThemeData.linkStyle].
  final KeycapStyle? style;

  /// The link's focus node.
  final FocusNode? focusNode;

  /// What a screen reader says, when the words are not enough.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      semanticLabel: semanticLabel,
      button: false,
      link: true,
      builder: (context, states, _) {
        final layered = RawStyleOf([style, theme.linkStyle], states);
        final disabled = states.contains(WidgetState.disabled);
        final rest = disabled
            ? c.inkDisabled
            : layered.foreground ?? c.accentInk;
        final down = Color.lerp(rest, c.inkMuted, 0.6)!;
        final focused = states.contains(WidgetState.focused);
        final pressed = states.contains(WidgetState.pressed);
        return TapTargetPadding(
          child: KeycapSpringValue(
            value: focused ? 1 : 0,
            spring: KeycapMotion.colour,
            spatial: false,
            builder: (context, f, child) => CustomPaint(
              foregroundPainter: _FocusBand(
                c.focus.withValues(alpha: c.focus.a * f.clamp(0.0, 1.0)),
                radius: KeycapMetrics.smallKeyRadius,
              ),
              child: child,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KeycapSpacing.tight,
                vertical: KeycapSpacing.tight / 2,
              ),
              child: KeycapSpringValue(
                value: pressed && !disabled ? 1 : 0,
                spring: KeycapMotion.colour,
                spatial: false,
                builder: (context, t, _) {
                  final color = Color.lerp(rest, down, t.clamp(0.0, 1.0))!;
                  return DefaultTextStyle.merge(
                    style: theme.textTheme.body
                        .merge(layered.textStyle)
                        .copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: color.withValues(
                            alpha: color.a * 0.55,
                          ),
                          decorationThickness: 1.5,
                        ),
                    child: IconTheme.merge(
                      data: IconThemeData(color: color, size: 16),
                      child: child,
                    ),
                  );
                },
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
    properties.add(
      FlagProperty('enabled', value: onPressed != null, ifFalse: 'disabled'),
    );
  }
}

/// A small cap naming a key on the keyboard: in running text ("press
/// Esc"), in a menu row, beside a command. [KeycapKbd.shortcut] prints a
/// whole shortcut as the caps it is pressed on, in this platform's words
/// (Cmd on a Mac, Ctrl elsewhere; never a symbol the font may not hold).
///
/// ```dart
/// KeycapKbd.shortcut(const SingleActivator(LogicalKeyboardKey.keyN, control: true))
/// ```
class KeycapKbd extends StatelessWidget {
  /// One key, named [label].
  const KeycapKbd(this.label, {super.key, this.semanticLabel})
    : shortcut = null;

  /// Every key of [shortcut], in the order they are pressed.
  const KeycapKbd.shortcut(this.shortcut, {super.key, this.semanticLabel})
    : label = null;

  /// The one key's legend.
  final String? label;

  /// The shortcut, for [KeycapKbd.shortcut].
  final MenuSerializableShortcut? shortcut;

  /// What a screen reader says; the legends, joined, when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final keys = shortcut == null
        ? [label!]
        : rawShortcutKeys(context, shortcut!, appleSymbols: false);
    final words =
        semanticLabel ??
        (shortcut == null
            ? label!
            : rawShortcutLabel(context, shortcut!, appleSymbols: false));
    return KeycapShortcut(keys: keys, semanticLabel: words);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}
