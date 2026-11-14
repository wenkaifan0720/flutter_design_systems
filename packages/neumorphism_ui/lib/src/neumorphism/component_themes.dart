import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How one part looks, as Material's `ButtonStyle` is: every slot resolves for the part's states
/// ([WidgetState.disabled], [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its component theme on `NeumorphicThemeData`, then
/// from the look's own default. A slot
/// that is null, or resolves to null for the states at hand, falls through to the next.
///
/// | slot | what it sets |
/// |---|---|
/// | [fill] | the face or plate |
/// | [foreground] | the words and icons on it |
/// | [edge] | the rim's colour, at the look's width |
/// | [overlay] | a wash over the face for the states you name; the look draws none (hover changes nothing, a press sinks) |
/// | [side] | the whole rim, colour and width; it wins over [edge] |
/// | [shape] | the outline: Neumorphism's rounded, stadium or circle borders, or any [OutlinedBorder] |
/// | [padding] | the room between the rim and what stands inside |
/// | [minimumSize] | the least the face stands; the touch target stays 48 on every platform |
/// | [textStyle] | the words' style, merged over the look's (its colour comes from [foreground]) |
/// | [iconSize] | an icon's size |
///
/// Each part's doc says which slots it reads. Its shape animates when a state changes it, as a Material 3 button's
/// does.
///
/// ```dart
/// NeumorphicChip(
///   'Jazz',
///   onPressed: () {},
///   style: NeumorphicStyle(
///     shape: WidgetStateProperty.resolveWith(
///       (states) => states.contains(WidgetState.pressed)
///           ? const NeumorphicStadiumBorder()
///           : const NeumorphicRoundedBorder(radius: 12),
///     ),
///     padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
///   ),
/// )
/// ```
@immutable
class NeumorphicStyle with Diagnosticable {
  /// Every slot null: the next layer's, down to the look's own.
  const NeumorphicStyle({
    this.fill,
    this.foreground,
    this.edge,
    this.overlay,
    this.side,
    this.shape,
    this.padding,
    this.minimumSize,
    this.textStyle,
    this.iconSize,
  });

  /// The face or plate.
  final WidgetStateProperty<Color?>? fill;

  /// What stands on the face: the words and icons, a tick, a lever.
  final WidgetStateProperty<Color?>? foreground;

  /// The rim's colour, drawn at the look's width.
  final WidgetStateProperty<Color?>? edge;

  /// A wash over the face, in the face's own outline, for the states it resolves. The look sets none: under the
  /// pointer a part stays as it is, and a press sinks it. Resolve [WidgetState.hovered] here to give hover a style.
  final WidgetStateProperty<Color?>? overlay;

  /// The whole rim, colour and width. Wins over [edge].
  final WidgetStateProperty<BorderSide?>? side;

  /// The outline.
  final WidgetStateProperty<OutlinedBorder?>? shape;

  /// The room between the rim and what stands inside.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// The least size of the face.
  final WidgetStateProperty<Size?>? minimumSize;

  /// The words' style, merged over the look's.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// An icon's size.
  final WidgetStateProperty<double?>? iconSize;

  /// True when every slot is null.
  bool get isEmpty =>
      fill == null &&
      foreground == null &&
      edge == null &&
      overlay == null &&
      side == null &&
      shape == null &&
      padding == null &&
      minimumSize == null &&
      textStyle == null &&
      iconSize == null;

  /// [slot] for [states], or [fallback].
  static Color resolve(
    WidgetStateProperty<Color?>? slot,
    Set<WidgetState> states,
    Color fallback,
  ) => slot?.resolve(states) ?? fallback;

  /// The first of [layers] whose [slot] gives a value for [states]: how a part reads its `style:`, then its component
  /// theme. Null when none does, so the part goes on to the theme-wide knobs and its own default.
  ///
  /// ```dart
  /// final fill = NeumorphicStyle.first([style, theme.chipTheme], (s) => s.fill, states) ?? theme.colors.card;
  /// ```
  static T? first<T>(
    Iterable<NeumorphicStyle?> layers,
    WidgetStateProperty<T?>? Function(NeumorphicStyle style) slot,
    Set<WidgetState> states,
  ) {
    for (final layer in layers) {
      if (layer == null) continue;
      final value = slot(layer)?.resolve(states);
      if (value != null) return value;
    }
    return null;
  }

  /// Combines layers without losing state-specific null fallbacks. Useful when
  /// a variant theme falls back to a shared button theme.
  static NeumorphicStyle cascade(Iterable<NeumorphicStyle?> layers) {
    final list = List<NeumorphicStyle?>.unmodifiable(layers);
    return NeumorphicStyle(
      fill: WidgetStateProperty.resolveWith<Color?>(
        (states) => first(list, (s) => s.fill, states),
      ),
      foreground: WidgetStateProperty.resolveWith<Color?>(
        (states) => first(list, (s) => s.foreground, states),
      ),
      edge: WidgetStateProperty.resolveWith<Color?>(
        (states) => first(list, (s) => s.edge, states),
      ),
      overlay: WidgetStateProperty.resolveWith<Color?>(
        (states) => first(list, (s) => s.overlay, states),
      ),
      side: WidgetStateProperty.resolveWith<BorderSide?>(
        (states) => first(list, (s) => s.side, states),
      ),
      shape: WidgetStateProperty.resolveWith<OutlinedBorder?>(
        (states) => first(list, (s) => s.shape, states),
      ),
      padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry?>(
        (states) => first(list, (s) => s.padding, states),
      ),
      minimumSize: WidgetStateProperty.resolveWith<Size?>(
        (states) => first(list, (s) => s.minimumSize, states),
      ),
      textStyle: WidgetStateProperty.resolveWith<TextStyle?>(
        (states) => first(list, (s) => s.textStyle, states),
      ),
      iconSize: WidgetStateProperty.resolveWith<double?>(
        (states) => first(list, (s) => s.iconSize, states),
      ),
    );
  }

  /// This with the named slots changed.
  NeumorphicStyle copyWith({
    WidgetStateProperty<Color?>? fill,
    WidgetStateProperty<Color?>? foreground,
    WidgetStateProperty<Color?>? edge,
    WidgetStateProperty<Color?>? overlay,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<double?>? iconSize,
  }) => NeumorphicStyle(
    fill: fill ?? this.fill,
    foreground: foreground ?? this.foreground,
    edge: edge ?? this.edge,
    overlay: overlay ?? this.overlay,
    side: side ?? this.side,
    shape: shape ?? this.shape,
    padding: padding ?? this.padding,
    minimumSize: minimumSize ?? this.minimumSize,
    textStyle: textStyle ?? this.textStyle,
    iconSize: iconSize ?? this.iconSize,
  );

  /// This, with [other]'s slots where this has none, as `ButtonStyle.merge`.
  NeumorphicStyle merge(NeumorphicStyle? other) {
    if (other == null) return this;
    return copyWith(
      fill: fill ?? other.fill,
      foreground: foreground ?? other.foreground,
      edge: edge ?? other.edge,
      overlay: overlay ?? other.overlay,
      side: side ?? other.side,
      shape: shape ?? other.shape,
      padding: padding ?? other.padding,
      minimumSize: minimumSize ?? other.minimumSize,
      textStyle: textStyle ?? other.textStyle,
      iconSize: iconSize ?? other.iconSize,
    );
  }

  /// Between [a] and [b], slot by slot, as `ButtonStyle.lerp`: colours, sides, sizes and type blend, Neumorphism's
  /// shapes morph into each other, other shapes snap at the middle.
  static NeumorphicStyle? lerp(
    NeumorphicStyle? a,
    NeumorphicStyle? b,
    double t,
  ) {
    if (a == b || t == 0) return a;
    if (t == 1) return b;
    T? either<T>(T? x, T? y, T Function(T, T) f) =>
        x == null || y == null ? (t < .5 ? x : y) : f(x, y);
    WidgetStateProperty<T?>? l<T>(
      WidgetStateProperty<T?>? x,
      WidgetStateProperty<T?>? y,
      T Function(T, T) f,
    ) => WidgetStateProperty.lerp<T?>(x, y, t, (p, q, t) => either<T>(p, q, f));
    return NeumorphicStyle(
      fill: l<Color>(a?.fill, b?.fill, (x, y) => Color.lerp(x, y, t)!),
      foreground: l<Color>(
        a?.foreground,
        b?.foreground,
        (x, y) => Color.lerp(x, y, t)!,
      ),
      edge: l<Color>(a?.edge, b?.edge, (x, y) => Color.lerp(x, y, t)!),
      overlay: l<Color>(a?.overlay, b?.overlay, (x, y) => Color.lerp(x, y, t)!),
      side: l<BorderSide>(a?.side, b?.side, (x, y) => BorderSide.lerp(x, y, t)),
      shape: l<OutlinedBorder>(
        a?.shape,
        b?.shape,
        (x, y) => OutlinedBorder.lerp(x, y, t)!,
      ),
      padding: l<EdgeInsetsGeometry>(
        a?.padding,
        b?.padding,
        (x, y) => EdgeInsetsGeometry.lerp(x, y, t)!,
      ),
      minimumSize: l<Size>(
        a?.minimumSize,
        b?.minimumSize,
        (x, y) => Size.lerp(x, y, t)!,
      ),
      textStyle: l<TextStyle>(
        a?.textStyle,
        b?.textStyle,
        (x, y) => TextStyle.lerp(x, y, t)!,
      ),
      iconSize: l<double>(
        a?.iconSize,
        b?.iconSize,
        (x, y) => lerpDouble(x, y, t)!,
      ),
    );
  }

  List<Object?> get _slots => [
    fill,
    foreground,
    edge,
    overlay,
    side,
    shape,
    padding,
    minimumSize,
    textStyle,
    iconSize,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeumorphicStyle && listEquals(other._slots, _slots);

  @override
  int get hashCode => Object.hashAll(_slots);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    void add<T>(String name, WidgetStateProperty<T?>? value) => properties.add(
      DiagnosticsProperty<WidgetStateProperty<T?>>(
        name,
        value,
        defaultValue: null,
      ),
    );
    add('fill', fill);
    add('foreground', foreground);
    add('edge', edge);
    add('overlay', overlay);
    add('side', side);
    add('shape', shape);
    add('padding', padding);
    add('minimumSize', minimumSize);
    add('textStyle', textStyle);
    add('iconSize', iconSize);
  }
}
