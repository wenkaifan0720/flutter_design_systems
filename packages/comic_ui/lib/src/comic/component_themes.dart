import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How one part looks, as Material's `ButtonStyle` is: every slot resolves for the part's states
/// ([WidgetState.disabled], [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its component theme on `ComicThemeData`, then
/// from the theme-wide knobs (`shapes`, `strokes`, `density`, `typeface`), then from the look's own default. A slot
/// that is null, or resolves to null for the states at hand, falls through to the next.
///
/// | slot | what it sets |
/// |---|---|
/// | [fill] | the face or plate |
/// | [foreground] | the words and icons on it |
/// | [edge] | the rim's colour, at the look's width |
/// | [overlay] | the wash over the face in the states it names; the look draws one only under a press, so give one for [WidgetState.hovered] to style hover |
/// | [side] | the whole rim, colour and width; it wins over [edge] |
/// | [shape] | the outline: Comic's panel, balloon or burst borders, or any [OutlinedBorder] |
/// | [padding] | the room between the rim and what stands inside |
/// | [minimumSize] | the least the face stands; the touch target stays 48 on touch, 44 elsewhere |
/// | [textStyle] | the words' style, merged over the look's (its colour comes from [foreground]) |
/// | [iconSize] | an icon's size |
///
/// Each part's doc says which slots it reads. Its shape animates when a state changes it, as a Material 3 button's
/// does.
///
/// ```dart
/// ComicChip(
///   'Jazz',
///   onPressed: () {},
///   style: ComicStyle(
///     shape: WidgetStateProperty.resolveWith(
///       (states) => states.contains(WidgetState.pressed)
///           ? const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))
///           : const RoundedRectangleBorder(),
///     ),
///     padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
///   ),
/// )
/// ```
@immutable
class ComicStyle with Diagnosticable {
  /// Every slot null: the next layer's, down to the look's own.
  const ComicStyle({
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

  /// Keeps [layers] in priority order when a composite part forwards its style.
  /// Each slot falls through when its value resolves to null for the current
  /// states. Unlike [merge], this preserves fall-through inside a state property.
  ///
  /// ```dart
  /// final forwarded = ComicStyle.layered([style, theme.timePickerTheme]);
  /// ```
  factory ComicStyle.layered(List<ComicStyle?> layers) {
    final source = List<ComicStyle>.unmodifiable(
      layers.whereType<ComicStyle>(),
    );
    WidgetStateProperty<T?>? combine<T>(
      WidgetStateProperty<T?>? Function(ComicStyle) slot,
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

    return ComicStyle(
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

  /// The rim's colour, drawn at the look's width (or the theme's `strokes.regular`).
  final WidgetStateProperty<Color?>? edge;

  /// The wash over the face in the states it names, drawn in the part's outline. The look's own is 10% ink under a
  /// press and nothing under the pointer: resolve [WidgetState.hovered] here to give hover a style.
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
  /// final fill = ComicStyle.first([style, theme.chipTheme], (s) => s.fill, states) ?? theme.colors.card;
  /// ```
  static T? first<T>(
    Iterable<ComicStyle?> layers,
    WidgetStateProperty<T?>? Function(ComicStyle style) slot,
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
  ComicStyle copyWith({
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
  }) => ComicStyle(
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
  ComicStyle merge(ComicStyle? other) {
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

  /// Between [a] and [b], slot by slot, as `ButtonStyle.lerp`: colours, sides, sizes and type blend, Comic's
  /// shapes morph into each other, other shapes snap at the middle.
  static ComicStyle? lerp(ComicStyle? a, ComicStyle? b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    T? either<T>(T? x, T? y, T Function(T, T) f) =>
        x == null || y == null ? (t < .5 ? x : y) : f(x, y);
    WidgetStateProperty<T?>? l<T>(
      WidgetStateProperty<T?>? x,
      WidgetStateProperty<T?>? y,
      T Function(T, T) f,
    ) => WidgetStateProperty.lerp<T?>(x, y, t, (p, q, t) => either<T>(p, q, f));
    return ComicStyle(
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
      other is ComicStyle && listEquals(other._slots, _slots);

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

/// Every component theme in one, as `ThemeData` holds Material's: what `ComicThemeData` carries and lerps.
@immutable
class ComicComponentThemes with Diagnosticable {
  /// All empty: the look's own throughout.
  const ComicComponentThemes({
    this.actButton = const ComicStyle(),
    this.lineButton = const ComicStyle(),
    this.quietButton = const ComicStyle(),
    this.iconButton = const ComicStyle(),
    this.checkbox = const ComicStyle(),
    this.radio = const ComicStyle(),
    this.switchTheme = const ComicStyle(),
    this.textField = const ComicStyle(),
    this.chip = const ComicStyle(),
    this.slider = const ComicStyle(),
    this.segmentedButton = const ComicStyle(),
    this.card = const ComicStyle(),
    this.dialog = const ComicStyle(),
    this.sheet = const ComicStyle(),
    this.menu = const ComicStyle(),
    this.snackBar = const ComicStyle(),
    this.tooltip = const ComicStyle(),
    this.badge = const ComicStyle(),
    this.avatar = const ComicStyle(),
    this.option = const ComicStyle(),
    this.stepper = const ComicStyle(),
    this.datePicker = const ComicStyle(),
    this.timePicker = const ComicStyle(),
  });

  /// The act button's.
  final ComicStyle actButton;

  /// The line button's.
  final ComicStyle lineButton;

  /// The quiet button's.
  final ComicStyle quietButton;

  /// The icon button's.
  final ComicStyle iconButton;

  /// A tick box's.
  final ComicStyle checkbox;

  /// The radio's.
  final ComicStyle radio;

  /// The switch's.
  final ComicStyle switchTheme;

  /// A field's.
  final ComicStyle textField;

  /// A chip's.
  final ComicStyle chip;

  /// The slider's.
  final ComicStyle slider;

  /// The segmented strip's.
  final ComicStyle segmentedButton;

  /// A card's.
  final ComicStyle card;

  /// A dialog's.
  final ComicStyle dialog;

  /// A bottom sheet's.
  final ComicStyle sheet;

  /// A menu's.
  final ComicStyle menu;

  /// The snack bar's.
  final ComicStyle snackBar;

  /// The tooltip's.
  final ComicStyle tooltip;

  /// The badge's.
  final ComicStyle badge;

  /// The avatar's.
  final ComicStyle avatar;

  /// An option's, and a time slot's.
  final ComicStyle option;

  /// The number stepper's.
  final ComicStyle stepper;

  /// The date picker's.
  final ComicStyle datePicker;

  /// The time picker's.
  final ComicStyle timePicker;

  static const List<String> _names = [
    'actButton',
    'lineButton',
    'quietButton',
    'iconButton',
    'checkbox',
    'radio',
    'switchTheme',
    'textField',
    'chip',
    'slider',
    'segmentedButton',
    'card',
    'dialog',
    'sheet',
    'menu',
    'snackBar',
    'tooltip',
    'badge',
    'avatar',
    'option',
    'stepper',
    'datePicker',
    'timePicker',
  ];

  List<ComicStyle> get _all => [
    actButton,
    lineButton,
    quietButton,
    iconButton,
    checkbox,
    radio,
    switchTheme,
    textField,
    chip,
    slider,
    segmentedButton,
    card,
    dialog,
    sheet,
    menu,
    snackBar,
    tooltip,
    badge,
    avatar,
    option,
    stepper,
    datePicker,
    timePicker,
  ];

  static ComicComponentThemes _of(List<ComicStyle> s) => ComicComponentThemes(
    actButton: s[0],
    lineButton: s[1],
    quietButton: s[2],
    iconButton: s[3],
    checkbox: s[4],
    radio: s[5],
    switchTheme: s[6],
    textField: s[7],
    chip: s[8],
    slider: s[9],
    segmentedButton: s[10],
    card: s[11],
    dialog: s[12],
    sheet: s[13],
    menu: s[14],
    snackBar: s[15],
    tooltip: s[16],
    badge: s[17],
    avatar: s[18],
    option: s[19],
    stepper: s[20],
    datePicker: s[21],
    timePicker: s[22],
  );

  /// This with the named themes changed.
  ComicComponentThemes copyWith({
    ComicStyle? actButton,
    ComicStyle? lineButton,
    ComicStyle? quietButton,
    ComicStyle? iconButton,
    ComicStyle? checkbox,
    ComicStyle? radio,
    ComicStyle? switchTheme,
    ComicStyle? textField,
    ComicStyle? chip,
    ComicStyle? slider,
    ComicStyle? segmentedButton,
    ComicStyle? card,
    ComicStyle? dialog,
    ComicStyle? sheet,
    ComicStyle? menu,
    ComicStyle? snackBar,
    ComicStyle? tooltip,
    ComicStyle? badge,
    ComicStyle? avatar,
    ComicStyle? option,
    ComicStyle? stepper,
    ComicStyle? datePicker,
    ComicStyle? timePicker,
  }) => ComicComponentThemes(
    actButton: actButton ?? this.actButton,
    lineButton: lineButton ?? this.lineButton,
    quietButton: quietButton ?? this.quietButton,
    iconButton: iconButton ?? this.iconButton,
    checkbox: checkbox ?? this.checkbox,
    radio: radio ?? this.radio,
    switchTheme: switchTheme ?? this.switchTheme,
    textField: textField ?? this.textField,
    chip: chip ?? this.chip,
    slider: slider ?? this.slider,
    segmentedButton: segmentedButton ?? this.segmentedButton,
    card: card ?? this.card,
    dialog: dialog ?? this.dialog,
    sheet: sheet ?? this.sheet,
    menu: menu ?? this.menu,
    snackBar: snackBar ?? this.snackBar,
    tooltip: tooltip ?? this.tooltip,
    badge: badge ?? this.badge,
    avatar: avatar ?? this.avatar,
    option: option ?? this.option,
    stepper: stepper ?? this.stepper,
    datePicker: datePicker ?? this.datePicker,
    timePicker: timePicker ?? this.timePicker,
  );

  /// Between [a] and [b], theme by theme.
  static ComicComponentThemes lerp(
    ComicComponentThemes a,
    ComicComponentThemes b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    final x = a._all, y = b._all;
    return _of([
      for (var i = 0; i < x.length; i++) ComicStyle.lerp(x[i], y[i], t)!,
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicComponentThemes && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final all = _all;
    for (var i = 0; i < _names.length; i++) {
      properties.add(
        DiagnosticsProperty<ComicStyle>(
          _names[i],
          all[i],
          defaultValue: const ComicStyle(),
        ),
      );
    }
  }
}

/// The states a painted control is in, for its style.
Set<WidgetState> comicStates({
  bool enabled = true,
  bool hovered = false,
  bool focused = false,
  bool pressed = false,
  bool selected = false,
  bool error = false,
}) => {
  if (!enabled) WidgetState.disabled,
  if (hovered) WidgetState.hovered,
  if (focused) WidgetState.focused,
  if (pressed) WidgetState.pressed,
  if (selected) WidgetState.selected,
  if (error) WidgetState.error,
};
