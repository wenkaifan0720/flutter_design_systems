import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How one part of a look looks, as Material's `ButtonStyle` is: every slot
/// resolves for the part's states ([WidgetState.disabled],
/// [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its
/// component theme, then from the theme-wide knobs (shapes, strokes,
/// density, typeface), then from the look's own default. A slot that is
/// null, or resolves to null for the states at hand, falls through to the
/// next. [DesignStyleOf] reads the first two layers for a part.
///
/// | slot | what it sets |
/// |---|---|
/// | [fill] | the face or plate |
/// | [foreground] | the words and icons on it |
/// | [edge] | the rim's colour, at the look's width |
/// | [overlay] | the wash over the face in the states it names |
/// | [side] | the whole rim, colour and width; it wins over [edge] |
/// | [shape] | the outline: the look's own borders, or any [OutlinedBorder] |
/// | [padding] | the room between the rim and what stands inside |
/// | [minimumSize] | the least the face stands; the tap target is the look's floor |
/// | [textStyle] | the words' style, merged over the look's (its colour comes from [foreground]) |
/// | [iconSize] | an icon's size |
///
/// Each part's doc says which slots it reads. A look names this class as its
/// own (`typedef ComicStyle = DesignStyle;`), so every look's parts take the
/// same style, read the same way.
///
/// ```dart
/// final style = DesignStyle(
///   fill: WidgetStateProperty.resolveWith(
///     (states) => states.contains(WidgetState.pressed)
///         ? const Color(0xFF1D4ED8)
///         : const Color(0xFF2563EB),
///   ),
///   padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
/// );
/// ```
///
/// A look that needs a slot of its own (a groove's depth, a glow) leaves the
/// alias for a subclass under the same name, which keeps every call that
/// builds one compiling and passes where a [DesignStyle] is read:
///
/// `class NeumorphicStyle extends DesignStyle { const NeumorphicStyle({super.fill, …, this.depth}); final WidgetStateProperty<double?>? depth; }`
///
/// It then overrides [copyWith], [merge], [lerp] (as a static of its own),
/// `==`, [hashCode] and [debugFillProperties] for the new slot, and reads it
/// with [first].
///
/// See also:
///
///  * [DesignStyleOf], a part's layers read at its states.
///  * `ButtonStyle`, Material's counterpart, which this follows.
@immutable
class DesignStyle with Diagnosticable {
  /// Every slot null: the next layer's, down to the look's own.
  const DesignStyle({
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

  /// [layers] in priority order, as one style: each slot is the first
  /// layer's that resolves to a value for the states at hand. How a
  /// composite part forwards its own style and its component theme to a
  /// part inside it. Unlike [merge], which keeps a whole slot, this falls
  /// through inside a slot, state by state.
  ///
  /// ```dart
  /// final forwarded = DesignStyle.layered([style, themed]);
  /// ```
  factory DesignStyle.layered(List<DesignStyle?> layers) {
    final source = List<DesignStyle>.unmodifiable(
      layers.whereType<DesignStyle>(),
    );
    WidgetStateProperty<T?>? combine<T>(
      WidgetStateProperty<T?>? Function(DesignStyle) slot,
    ) {
      final values = source
          .map(slot)
          .whereType<WidgetStateProperty<T?>>()
          .toList(growable: false);
      if (values.isEmpty) return null;
      if (values.length == 1) return values.single;
      return WidgetStateProperty.resolveWith((states) {
        for (final property in values) {
          final value = property.resolve(states);
          if (value != null) return value;
        }
        return null;
      });
    }

    return DesignStyle(
      fill: combine((s) => s.fill),
      foreground: combine((s) => s.foreground),
      edge: combine((s) => s.edge),
      overlay: combine((s) => s.overlay),
      side: combine((s) => s.side),
      shape: combine((s) => s.shape),
      padding: combine((s) => s.padding),
      minimumSize: combine((s) => s.minimumSize),
      textStyle: combine((s) => s.textStyle),
      iconSize: combine((s) => s.iconSize),
    );
  }

  /// The face or plate.
  final WidgetStateProperty<Color?>? fill;

  /// What stands on the face: the words and icons, a tick, a lever.
  final WidgetStateProperty<Color?>? foreground;

  /// The rim's colour, drawn at the look's width.
  final WidgetStateProperty<Color?>? edge;

  /// The wash over the face in the states it names, drawn in the part's
  /// outline. Each look says which states its own wash covers.
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

  /// Whether every slot is null.
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

  /// The first of [layers] whose [slot] gives a value for [states]: how a
  /// part reads its `style:`, then its component theme. Null when none
  /// does, so the part goes on to the theme-wide knobs and its own default.
  ///
  /// ```dart
  /// final fill =
  ///     DesignStyle.first([style, themed], (s) => s.fill, states) ??
  ///     const Color(0xFFFFFFFF);
  /// ```
  static T? first<T>(
    Iterable<DesignStyle?> layers,
    WidgetStateProperty<T?>? Function(DesignStyle style) slot,
    Set<WidgetState> states,
  ) {
    for (final layer in layers) {
      if (layer == null) continue;
      final value = slot(layer)?.resolve(states);
      if (value != null) return value;
    }
    return null;
  }

  /// This with the named slots changed.
  DesignStyle copyWith({
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
  }) => DesignStyle(
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

  /// This, with [other]'s slots where this has none, as `ButtonStyle.merge`:
  /// a slot is kept whole. [DesignStyle.layered] falls through within one.
  DesignStyle merge(DesignStyle? other) {
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

  /// Between [a] and [b], slot by slot, as `ButtonStyle.lerp`: colours,
  /// sides, insets, sizes and type blend; shapes morph where their borders
  /// can (`OutlinedBorder.lerp`) and snap at the middle where they cannot; a
  /// value on one side only snaps at the middle.
  static DesignStyle? lerp(DesignStyle? a, DesignStyle? b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    T? either<T>(T? x, T? y, T Function(T, T) f) =>
        x == null || y == null ? (t < .5 ? x : y) : f(x, y);
    WidgetStateProperty<T?>? l<T>(
      WidgetStateProperty<T?>? x,
      WidgetStateProperty<T?>? y,
      T Function(T, T) f,
    ) => WidgetStateProperty.lerp<T?>(x, y, t, (p, q, t) => either<T>(p, q, f));
    return DesignStyle(
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
      other.runtimeType == runtimeType &&
          other is DesignStyle &&
          listEquals(other._slots, _slots);

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

/// A part's style layers read at its states: its own `style:`, then its
/// component theme (first wins). Each getter is the first layer's value for
/// [states], or null, so the part goes on to the theme-wide knobs and its own
/// default.
///
/// ```dart
/// final look = DesignStyleOf([style, themed], states);
/// final fill = look.fill ?? const Color(0xFFFFFFFF);
/// ```
@immutable
class DesignStyleOf {
  /// The [layers] read at [states].
  const DesignStyleOf(this.layers, this.states);

  /// The styles, first wins.
  final List<DesignStyle?> layers;

  /// The part's states.
  final Set<WidgetState> states;

  T? _first<T>(WidgetStateProperty<T?>? Function(DesignStyle s) slot) =>
      DesignStyle.first(layers, slot, states);

  /// The face.
  Color? get fill => _first((s) => s.fill);

  /// The words and icons.
  Color? get foreground => _first((s) => s.foreground);

  /// The rim's colour.
  Color? get edge => _first((s) => s.edge);

  /// The whole rim.
  BorderSide? get side => _first((s) => s.side);

  /// The outline.
  OutlinedBorder? get shape => _first((s) => s.shape);

  /// The room inside, resolved for [direction].
  EdgeInsets? padding(TextDirection direction) =>
      _first((s) => s.padding)?.resolve(direction);

  /// The least size of the face.
  Size? get minimumSize => _first((s) => s.minimumSize);

  /// The words' style.
  TextStyle? get textStyle => _first((s) => s.textStyle);

  /// An icon's size.
  double? get iconSize => _first((s) => s.iconSize);

  /// The overlay for any states, as a press reads it for its wash; null
  /// when no layer has one.
  WidgetStateProperty<Color?>? get overlay =>
      layers.any((l) => l?.overlay != null)
      ? WidgetStateProperty.resolveWith(
          (states) => DesignStyle.first(layers, (s) => s.overlay, states),
        )
      : null;

  /// The same layers at other [states].
  DesignStyleOf at(Set<WidgetState> states) => DesignStyleOf(layers, states);

  /// The shape for any states, as a press reads it for its ring and wash;
  /// [fallback] when no layer gives one.
  WidgetStateProperty<OutlinedBorder?> shapes(OutlinedBorder? fallback) =>
      WidgetStateProperty.resolveWith((states) => at(states).shape ?? fallback);

  /// The values resolved at [states], as one style, so a grouped part can
  /// hand its states to a part inside it (a list row's checkbox drawn as the
  /// row is pressed).
  DesignStyle freeze() {
    WidgetStateProperty<T?>? fixed<T>(T? value) =>
        value == null ? null : WidgetStatePropertyAll(value);
    return DesignStyle(
      fill: fixed(fill),
      foreground: fixed(foreground),
      edge: fixed(edge),
      overlay: fixed(_first((s) => s.overlay)),
      side: fixed(side),
      shape: fixed(shape),
      padding: fixed(_first((s) => s.padding)),
      minimumSize: fixed(minimumSize),
      textStyle: fixed(textStyle),
      iconSize: fixed(iconSize),
    );
  }
}
