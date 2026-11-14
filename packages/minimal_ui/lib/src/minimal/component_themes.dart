/// How one part looks, set on the widget (`style:`) or theme-wide (the
/// component themes on `MinimalThemeData`), as Material's `ButtonStyle` and
/// its themes are.
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How one part looks, as Material's `ButtonStyle` is: every slot resolves
/// for the part's states ([WidgetState.disabled], [WidgetState.hovered],
/// [WidgetState.focused], [WidgetState.pressed], [WidgetState.selected],
/// [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its
/// component theme on `MinimalThemeData`, then from the theme-wide knobs
/// (`shapes`, `density`, `typeface`), then from the look's own
/// default. A slot that is null, or resolves to null for the states at
/// hand, falls through to the next.
///
/// | slot | what it sets |
/// |---|---|
/// | [fill] | the face or plate |
/// | [foreground] | the words and icons on it |
/// | [edge] | the rim's colour, at the theme's `t.rim` |
/// | [overlay] | the wash over the face while hovered or pressed |
/// | [side] | the whole rim, colour and width; it wins over [edge] |
/// | [shape] | the outline: any [OutlinedBorder] |
/// | [padding] | the room between the rim and what stands inside |
/// | [minimumSize] | the least the face stands; the touch target stays 48 on touch, 44 elsewhere |
/// | [textStyle] | the words' style, merged over the look's (its colour comes from [foreground]) |
/// | [iconSize] | an icon's size |
///
/// Each part's doc says which slots it reads.
///
/// ```dart
/// MinimalButton(
///   'Save',
///   onPressed: save,
///   style: MinimalStyle(
///     shape: const WidgetStatePropertyAll(StadiumBorder()),
///     padding: const WidgetStatePropertyAll(
///       EdgeInsets.symmetric(horizontal: 20),
///     ),
///   ),
/// )
/// ```
@immutable
class MinimalStyle with Diagnosticable {
  /// Every slot null: the next layer's, down to the look's own.
  const MinimalStyle({
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

  /// What stands on the face: the words and icons, a tick, a knob.
  final WidgetStateProperty<Color?>? foreground;

  /// The rim's colour, drawn at the theme's `t.rim`.
  final WidgetStateProperty<Color?>? edge;

  /// The wash over the face while hovered or pressed.
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

  /// The first of [layers] whose [slot] gives a value for [states]: how a
  /// part reads its `style:`, then its component theme. Null when none
  /// does, so the part goes on to the theme-wide knobs and its own default.
  ///
  /// ```dart
  /// final fill = MinimalStyle.first(
  ///       [style, theme.components.chip],
  ///       (s) => s.fill,
  ///       states,
  ///     ) ??
  ///     theme.card;
  /// ```
  static T? first<T>(
    Iterable<MinimalStyle?> layers,
    WidgetStateProperty<T?>? Function(MinimalStyle style) slot,
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
  MinimalStyle copyWith({
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
  }) => MinimalStyle(
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
  MinimalStyle merge(MinimalStyle? other) {
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
  /// sides, sizes and type blend; shapes blend through Flutter's own border
  /// interpolation, and kinds it cannot blend meet at the middle.
  static MinimalStyle? lerp(MinimalStyle? a, MinimalStyle? b, double t) {
    if (identical(a, b)) return a;
    T? either<T>(T? x, T? y, T Function(T, T) f) =>
        x == null || y == null ? (t < .5 ? x : y) : f(x, y);
    WidgetStateProperty<T?>? l<T>(
      WidgetStateProperty<T?>? x,
      WidgetStateProperty<T?>? y,
      T Function(T, T) f,
    ) => WidgetStateProperty.lerp<T?>(x, y, t, (p, q, t) => either<T>(p, q, f));
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return MinimalStyle(
      fill: l<Color>(a?.fill, b?.fill, c),
      foreground: l<Color>(a?.foreground, b?.foreground, c),
      edge: l<Color>(a?.edge, b?.edge, c),
      overlay: l<Color>(a?.overlay, b?.overlay, c),
      side: l<BorderSide>(a?.side, b?.side, (x, y) => BorderSide.lerp(x, y, t)),
      shape: l<OutlinedBorder>(
        a?.shape,
        b?.shape,
        (x, y) => OutlinedBorder.lerp(x, y, t) ?? (t < .5 ? x : y),
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
      other is MinimalStyle && listEquals(other._slots, _slots);

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
/// `MinimalThemeData.components` carries and lerps. Each is null until an
/// app sets it, and a null one leaves its parts as the look draws them.
///
/// ```dart
/// final theme = MinimalThemeData.standard().copyWith(
///   components: const MinimalComponentThemes(
///     chip: MinimalStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
///   ),
/// );
/// ```
@immutable
class MinimalComponentThemes with Diagnosticable {
  /// The named themes; every other null.
  const MinimalComponentThemes({
    this.primaryButton,
    this.secondaryButton,
    this.ghostButton,
    this.destructiveButton,
    this.iconButton,
    this.textField,
    this.chip,
    this.checkbox,
    this.radio,
    this.switchTheme,
    this.slider,
    this.segmentedButton,
    this.card,
    this.listSection,
    this.dialog,
    this.bottomSheet,
    this.menu,
    this.snackBar,
    this.command,
    this.avatar,
    this.badge,
    this.tooltip,
    this.banner,
  });

  /// `MinimalButton(variant: MinimalButtonVariant.primary)`, the default.
  final MinimalStyle? primaryButton;

  /// `MinimalButton(variant: MinimalButtonVariant.secondary)`.
  final MinimalStyle? secondaryButton;

  /// `MinimalButton(variant: MinimalButtonVariant.ghost)`.
  final MinimalStyle? ghostButton;

  /// `MinimalButton(variant: MinimalButtonVariant.destructive)`.
  final MinimalStyle? destructiveButton;

  /// `MinimalIconButton`.
  final MinimalStyle? iconButton;

  /// Every field box: text, search, select and number fields.
  final MinimalStyle? textField;

  /// `MinimalChip`.
  final MinimalStyle? chip;

  /// `MinimalCheckbox`.
  final MinimalStyle? checkbox;

  /// The radio in `MinimalRadioGroup`.
  final MinimalStyle? radio;

  /// `MinimalSwitch`.
  final MinimalStyle? switchTheme;

  /// `MinimalSlider`.
  final MinimalStyle? slider;

  /// `MinimalSegmentedButton`.
  final MinimalStyle? segmentedButton;

  /// `MinimalCard`.
  final MinimalStyle? card;

  /// `MinimalListSection`'s grouped frame.
  final MinimalStyle? listSection;

  /// `MinimalDialog`.
  final MinimalStyle? dialog;

  /// `MinimalBottomSheet`.
  final MinimalStyle? bottomSheet;

  /// `MinimalMenu`'s panel.
  final MinimalStyle? menu;

  /// `MinimalSnackBar`.
  final MinimalStyle? snackBar;

  /// `MinimalCommand`'s palette.
  final MinimalStyle? command;

  /// `MinimalAvatar`.
  final MinimalStyle? avatar;

  /// `MinimalBadge`.
  final MinimalStyle? badge;

  /// `MinimalTooltip`.
  final MinimalStyle? tooltip;

  /// `MinimalBanner`.
  final MinimalStyle? banner;

  List<MinimalStyle?> get _all => [
    primaryButton,
    secondaryButton,
    ghostButton,
    destructiveButton,
    iconButton,
    textField,
    chip,
    checkbox,
    radio,
    switchTheme,
    slider,
    segmentedButton,
    card,
    listSection,
    dialog,
    bottomSheet,
    menu,
    snackBar,
    command,
    avatar,
    badge,
    tooltip,
    banner,
  ];

  static const List<String> _names = [
    'primaryButton',
    'secondaryButton',
    'ghostButton',
    'destructiveButton',
    'iconButton',
    'textField',
    'chip',
    'checkbox',
    'radio',
    'switchTheme',
    'slider',
    'segmentedButton',
    'card',
    'listSection',
    'dialog',
    'bottomSheet',
    'menu',
    'snackBar',
    'command',
    'avatar',
    'badge',
    'tooltip',
    'banner',
  ];

  /// True when no component theme is set.
  bool get isEmpty => _all.every((s) => s == null);

  /// This with the named themes changed.
  MinimalComponentThemes copyWith({
    MinimalStyle? primaryButton,
    MinimalStyle? secondaryButton,
    MinimalStyle? ghostButton,
    MinimalStyle? destructiveButton,
    MinimalStyle? iconButton,
    MinimalStyle? textField,
    MinimalStyle? chip,
    MinimalStyle? checkbox,
    MinimalStyle? radio,
    MinimalStyle? switchTheme,
    MinimalStyle? slider,
    MinimalStyle? segmentedButton,
    MinimalStyle? card,
    MinimalStyle? listSection,
    MinimalStyle? dialog,
    MinimalStyle? bottomSheet,
    MinimalStyle? menu,
    MinimalStyle? snackBar,
    MinimalStyle? command,
    MinimalStyle? avatar,
    MinimalStyle? badge,
    MinimalStyle? tooltip,
    MinimalStyle? banner,
  }) => MinimalComponentThemes(
    primaryButton: primaryButton ?? this.primaryButton,
    secondaryButton: secondaryButton ?? this.secondaryButton,
    ghostButton: ghostButton ?? this.ghostButton,
    destructiveButton: destructiveButton ?? this.destructiveButton,
    iconButton: iconButton ?? this.iconButton,
    textField: textField ?? this.textField,
    chip: chip ?? this.chip,
    checkbox: checkbox ?? this.checkbox,
    radio: radio ?? this.radio,
    switchTheme: switchTheme ?? this.switchTheme,
    slider: slider ?? this.slider,
    segmentedButton: segmentedButton ?? this.segmentedButton,
    card: card ?? this.card,
    listSection: listSection ?? this.listSection,
    dialog: dialog ?? this.dialog,
    bottomSheet: bottomSheet ?? this.bottomSheet,
    menu: menu ?? this.menu,
    snackBar: snackBar ?? this.snackBar,
    command: command ?? this.command,
    avatar: avatar ?? this.avatar,
    badge: badge ?? this.badge,
    tooltip: tooltip ?? this.tooltip,
    banner: banner ?? this.banner,
  );

  /// Between [a] and [b], theme by theme.
  static MinimalComponentThemes lerp(
    MinimalComponentThemes a,
    MinimalComponentThemes b,
    double t,
  ) {
    if (identical(a, b)) return a;
    MinimalStyle? l(MinimalStyle? x, MinimalStyle? y) =>
        MinimalStyle.lerp(x, y, t);
    return MinimalComponentThemes(
      primaryButton: l(a.primaryButton, b.primaryButton),
      secondaryButton: l(a.secondaryButton, b.secondaryButton),
      ghostButton: l(a.ghostButton, b.ghostButton),
      destructiveButton: l(a.destructiveButton, b.destructiveButton),
      iconButton: l(a.iconButton, b.iconButton),
      textField: l(a.textField, b.textField),
      chip: l(a.chip, b.chip),
      checkbox: l(a.checkbox, b.checkbox),
      radio: l(a.radio, b.radio),
      switchTheme: l(a.switchTheme, b.switchTheme),
      slider: l(a.slider, b.slider),
      segmentedButton: l(a.segmentedButton, b.segmentedButton),
      card: l(a.card, b.card),
      listSection: l(a.listSection, b.listSection),
      dialog: l(a.dialog, b.dialog),
      bottomSheet: l(a.bottomSheet, b.bottomSheet),
      menu: l(a.menu, b.menu),
      snackBar: l(a.snackBar, b.snackBar),
      command: l(a.command, b.command),
      avatar: l(a.avatar, b.avatar),
      badge: l(a.badge, b.badge),
      tooltip: l(a.tooltip, b.tooltip),
      banner: l(a.banner, b.banner),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinimalComponentThemes && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final all = _all;
    for (var i = 0; i < all.length; i++) {
      properties.add(
        DiagnosticsProperty<MinimalStyle>(
          _names[i],
          all[i],
          defaultValue: null,
        ),
      );
    }
  }
}
