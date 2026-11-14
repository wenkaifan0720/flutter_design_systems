// How a part looks, slot by slot, and the component themes that carry one
// per part: what `Fluent2ThemeData` holds and lerps, as Material's
// `ThemeData` holds its component themes.
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How one part looks, as Material's `ButtonStyle` is: every slot resolves for the part's states
/// ([WidgetState.disabled], [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its component theme on `Fluent2ThemeData`, then
/// from Fluent's own (moved by the theme's `density`). A slot
/// that is null, or resolves to null for the states at hand, falls through to the next.
///
/// | slot | what it sets |
/// |---|---|
/// | [fill] | the face or plate |
/// | [foreground] | the words and icons on it |
/// | [edge] | the rim's colour, at Fluent's width |
/// | [overlay] | the wash over the face while hovered, focused or pressed |
/// | [side] | the whole rim, colour and width; it wins over [edge] |
/// | [shape] | the outline: a Flutter border on the corner scale, or any [OutlinedBorder] |
/// | [padding] | the room between the rim and what stands inside |
/// | [minimumSize] | the least the face stands; the touch target stays 48 on touch, 44 elsewhere |
/// | [textStyle] | the words' style, merged over Fluent's (its colour comes from [foreground]) |
/// | [iconSize] | an icon's size |
///
/// Each part's doc says which slots it reads. Its shape animates when a state changes it, as a Material 3 button's
/// does.
///
/// ```dart
/// Fluent2Button(
///   'Send',
///   onPressed: () {},
///   style: Fluent2Style(
///     shape: WidgetStateProperty.resolveWith(
///       (states) => states.contains(WidgetState.pressed)
///           ? const StadiumBorder()
///           : const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
///     ),
///     padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
///   ),
/// )
/// ```
@immutable
class Fluent2Style with Diagnosticable {
  /// Every slot null: the next layer's, down to Fluent's own.
  const Fluent2Style({
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

  /// The rim's colour, drawn at Fluent's width.
  final WidgetStateProperty<Color?>? edge;

  /// The wash over the face while hovered, focused or pressed.
  final WidgetStateProperty<Color?>? overlay;

  /// The whole rim, colour and width. Wins over [edge].
  final WidgetStateProperty<BorderSide?>? side;

  /// The outline.
  final WidgetStateProperty<OutlinedBorder?>? shape;

  /// The room between the rim and what stands inside.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// The least size of the face.
  final WidgetStateProperty<Size?>? minimumSize;

  /// The words' style, merged over Fluent's.
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
  /// theme. Null when none does, so the part goes on to its own Fluent default.
  ///
  /// ```dart
  /// final fill = Fluent2Style.first([style, theme.tagTheme], (s) => s.fill, states) ?? theme.surface;
  /// ```
  static T? first<T>(
    Iterable<Fluent2Style?> layers,
    WidgetStateProperty<T?>? Function(Fluent2Style style) slot,
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
  Fluent2Style copyWith({
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
  }) => Fluent2Style(
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
  Fluent2Style merge(Fluent2Style? other) {
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

  /// Between [a] and [b], slot by slot, as `ButtonStyle.lerp`: colours, sides, sizes and type blend, Fluent's
  /// rounded shapes morph into each other, other shapes snap at the middle.
  static Fluent2Style? lerp(Fluent2Style? a, Fluent2Style? b, double t) {
    if (identical(a, b)) return a;
    T? either<T>(T? x, T? y, T Function(T, T) f) =>
        x == null || y == null ? (t < .5 ? x : y) : f(x, y);
    WidgetStateProperty<T?>? l<T>(
      WidgetStateProperty<T?>? x,
      WidgetStateProperty<T?>? y,
      T Function(T, T) f,
    ) => WidgetStateProperty.lerp<T?>(x, y, t, (p, q, t) => either<T>(p, q, f));
    return Fluent2Style(
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
      other is Fluent2Style && listEquals(other._slots, _slots);

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

/// Every component theme in one, as `ThemeData` holds Material's: what
/// `Fluent2ThemeData` carries and lerps. Each is empty by default: the part
/// draws Fluent's own.
@immutable
class Fluent2ComponentThemes with Diagnosticable {
  /// All empty: Fluent's own throughout.
  const Fluent2ComponentThemes({
    this.primaryButton = const Fluent2Style(),
    this.secondaryButton = const Fluent2Style(),
    this.outlineButton = const Fluent2Style(),
    this.subtleButton = const Fluent2Style(),
    this.transparentButton = const Fluent2Style(),
    this.iconButton = const Fluent2Style(),
    this.checkbox = const Fluent2Style(),
    this.radio = const Fluent2Style(),
    this.switchTheme = const Fluent2Style(),
    this.textField = const Fluent2Style(),
    this.tag = const Fluent2Style(),
    this.slider = const Fluent2Style(),
    this.segmentedButton = const Fluent2Style(),
    this.tabList = const Fluent2Style(),
    this.card = const Fluent2Style(),
    this.listItem = const Fluent2Style(),
    this.dialog = const Fluent2Style(),
    this.bottomSheet = const Fluent2Style(),
    this.menu = const Fluent2Style(),
    this.toast = const Fluent2Style(),
    this.tooltip = const Fluent2Style(),
    this.badge = const Fluent2Style(),
    this.avatar = const Fluent2Style(),
  });

  /// A primary button's: the brand fill, the one act of a surface.
  final Fluent2Style primaryButton;

  /// A secondary button's, the default appearance: the neutral fill in its stroke.
  final Fluent2Style secondaryButton;

  /// An outline button's: the stroke on the ground.
  final Fluent2Style outlineButton;

  /// A subtle button's: no fill until hovered.
  final Fluent2Style subtleButton;

  /// A transparent button's: no fill in any state, brand words while hovered.
  final Fluent2Style transparentButton;

  /// An icon button's, read before its appearance's button theme.
  final Fluent2Style iconButton;

  /// A check box's.
  final Fluent2Style checkbox;

  /// A radio's.
  final Fluent2Style radio;

  /// A switch's.
  final Fluent2Style switchTheme;

  /// A field's frame: the text field, text area, search field, select, combobox, number field and the date picker's field.
  final Fluent2Style textField;

  /// A tag's and an interaction tag's.
  final Fluent2Style tag;

  /// A slider's.
  final Fluent2Style slider;

  /// The segmented strip's.
  final Fluent2Style segmentedButton;

  /// A tab bar's tabs.
  final Fluent2Style tabList;

  /// A card's.
  final Fluent2Style card;

  /// A list row's.
  final Fluent2Style listItem;

  /// A dialog's.
  final Fluent2Style dialog;

  /// A bottom sheet's.
  final Fluent2Style bottomSheet;

  /// A menu's and a popover's surface.
  final Fluent2Style menu;

  /// A toast's.
  final Fluent2Style toast;

  /// A tooltip's.
  final Fluent2Style tooltip;

  /// A badge's.
  final Fluent2Style badge;

  /// An avatar's.
  final Fluent2Style avatar;

  static const List<String> _names = [
    'primaryButton',
    'secondaryButton',
    'outlineButton',
    'subtleButton',
    'transparentButton',
    'iconButton',
    'checkbox',
    'radio',
    'switchTheme',
    'textField',
    'tag',
    'slider',
    'segmentedButton',
    'tabList',
    'card',
    'listItem',
    'dialog',
    'bottomSheet',
    'menu',
    'toast',
    'tooltip',
    'badge',
    'avatar',
  ];

  List<Fluent2Style> get _all => [
    primaryButton,
    secondaryButton,
    outlineButton,
    subtleButton,
    transparentButton,
    iconButton,
    checkbox,
    radio,
    switchTheme,
    textField,
    tag,
    slider,
    segmentedButton,
    tabList,
    card,
    listItem,
    dialog,
    bottomSheet,
    menu,
    toast,
    tooltip,
    badge,
    avatar,
  ];

  static Fluent2ComponentThemes _of(List<Fluent2Style> s) =>
      Fluent2ComponentThemes(
        primaryButton: s[0],
        secondaryButton: s[1],
        outlineButton: s[2],
        subtleButton: s[3],
        transparentButton: s[4],
        iconButton: s[5],
        checkbox: s[6],
        radio: s[7],
        switchTheme: s[8],
        textField: s[9],
        tag: s[10],
        slider: s[11],
        segmentedButton: s[12],
        tabList: s[13],
        card: s[14],
        listItem: s[15],
        dialog: s[16],
        bottomSheet: s[17],
        menu: s[18],
        toast: s[19],
        tooltip: s[20],
        badge: s[21],
        avatar: s[22],
      );

  /// True when every theme is empty.
  bool get isEmpty => _all.every((s) => s.isEmpty);

  /// This with the named themes changed.
  Fluent2ComponentThemes copyWith({
    Fluent2Style? primaryButton,
    Fluent2Style? secondaryButton,
    Fluent2Style? outlineButton,
    Fluent2Style? subtleButton,
    Fluent2Style? transparentButton,
    Fluent2Style? iconButton,
    Fluent2Style? checkbox,
    Fluent2Style? radio,
    Fluent2Style? switchTheme,
    Fluent2Style? textField,
    Fluent2Style? tag,
    Fluent2Style? slider,
    Fluent2Style? segmentedButton,
    Fluent2Style? tabList,
    Fluent2Style? card,
    Fluent2Style? listItem,
    Fluent2Style? dialog,
    Fluent2Style? bottomSheet,
    Fluent2Style? menu,
    Fluent2Style? toast,
    Fluent2Style? tooltip,
    Fluent2Style? badge,
    Fluent2Style? avatar,
  }) => Fluent2ComponentThemes(
    primaryButton: primaryButton ?? this.primaryButton,
    secondaryButton: secondaryButton ?? this.secondaryButton,
    outlineButton: outlineButton ?? this.outlineButton,
    subtleButton: subtleButton ?? this.subtleButton,
    transparentButton: transparentButton ?? this.transparentButton,
    iconButton: iconButton ?? this.iconButton,
    checkbox: checkbox ?? this.checkbox,
    radio: radio ?? this.radio,
    switchTheme: switchTheme ?? this.switchTheme,
    textField: textField ?? this.textField,
    tag: tag ?? this.tag,
    slider: slider ?? this.slider,
    segmentedButton: segmentedButton ?? this.segmentedButton,
    tabList: tabList ?? this.tabList,
    card: card ?? this.card,
    listItem: listItem ?? this.listItem,
    dialog: dialog ?? this.dialog,
    bottomSheet: bottomSheet ?? this.bottomSheet,
    menu: menu ?? this.menu,
    toast: toast ?? this.toast,
    tooltip: tooltip ?? this.tooltip,
    badge: badge ?? this.badge,
    avatar: avatar ?? this.avatar,
  );

  /// Between [a] and [b], theme by theme.
  static Fluent2ComponentThemes lerp(
    Fluent2ComponentThemes a,
    Fluent2ComponentThemes b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final x = a._all, y = b._all;
    return _of([
      for (var i = 0; i < x.length; i++) Fluent2Style.lerp(x[i], y[i], t)!,
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fluent2ComponentThemes && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final all = _all;
    for (var i = 0; i < _names.length; i++) {
      properties.add(
        DiagnosticsProperty<Fluent2Style>(
          _names[i],
          all[i],
          defaultValue: const Fluent2Style(),
        ),
      );
    }
  }
}

/// The states a painted part is in, for its style.
///
/// ```dart
/// final states = fluent2States(enabled: onPressed != null, hovered: hovered);
/// ```
Set<WidgetState> fluent2States({
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
