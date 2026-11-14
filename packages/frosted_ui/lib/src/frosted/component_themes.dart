// The per-part style, as Material's ButtonStyle has it, and the component
// themes that carry one per part. Every slot is a WidgetStateProperty and
// null means "the look's own", so a theme that sets none draws Frosted as
// it was designed.
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How one part is drawn, slot by slot, as Material's `ButtonStyle` does:
/// each slot a [WidgetStateProperty] resolved against the part's states
/// (hovered, focused, pressed, selected, disabled, error), and each null
/// slot the look's own. Set one theme-wide in [FrostedComponentThemes]
/// (`FrostedThemeData.components`) or on one widget through its `style:`;
/// the widget's wins, then the theme's, then the theme's knobs, then the
/// look.
///
/// ```dart
/// FrostedButton(
///   'Save',
///   onPressed: save,
///   style: FrostedStyle(
///     fill: WidgetStatePropertyAll(Color(0xFF1F6FEB)),
///     shape: WidgetStatePropertyAll(StadiumBorder()),
///   ),
/// )
/// ```
@immutable
class FrostedStyle with Diagnosticable {
  /// A style from its slots; every slot is optional.
  const FrostedStyle({
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

  /// The first non-null value of each slot across [layers], in order.
  factory FrostedStyle.layered(List<FrostedStyle?> layers) {
    final source = List<FrostedStyle>.unmodifiable(
      layers.whereType<FrostedStyle>(),
    );
    WidgetStateProperty<T?>? combine<T>(
      WidgetStateProperty<T?>? Function(FrostedStyle) slot,
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

    return FrostedStyle(
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

  /// The part's face: the glass, the act or the chosen thumb.
  final WidgetStateProperty<Color?>? fill;

  /// The part's words and glyphs, or its mark (a tick, a dot, a knob).
  final WidgetStateProperty<Color?>? foreground;

  /// The colour of the part's edge, at the look's stroke width.
  final WidgetStateProperty<Color?>? edge;

  /// A wash laid over the face in a state; null lays none (the look shows
  /// a press by its face, and nothing on hover).
  final WidgetStateProperty<Color?>? overlay;

  /// The whole edge, colour and width; wins over [edge].
  final WidgetStateProperty<BorderSide?>? side;

  /// The part's outline; nested parts (a thumb, a ring) follow it.
  final WidgetStateProperty<OutlinedBorder?>? shape;

  /// The room inside the face round its content.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// The face's least size; the touch target stays 44, or 48 on touch.
  final WidgetStateProperty<Size?>? minimumSize;

  /// The words' style.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// The glyphs' size.
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

  /// The first value of [slot] across [layers] at [states], or null.
  static T? first<T>(
    Iterable<FrostedStyle?> layers,
    WidgetStateProperty<T?>? Function(FrostedStyle style) slot,
    Set<WidgetState> states,
  ) {
    for (final layer in layers) {
      if (layer == null) continue;
      final value = slot(layer)?.resolve(states);
      if (value != null) return value;
    }
    return null;
  }

  /// This with the named slots replaced.
  FrostedStyle copyWith({
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
  }) => FrostedStyle(
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

  /// This, with [other]'s slots where this has none.
  FrostedStyle merge(FrostedStyle? other) {
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

  /// Between [a] and [b], slot by slot.
  static FrostedStyle? lerp(FrostedStyle? a, FrostedStyle? b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    T? either<T>(T? x, T? y, T Function(T, T) f) =>
        x == null || y == null ? (t < .5 ? x : y) : f(x, y);
    WidgetStateProperty<T?>? l<T>(
      WidgetStateProperty<T?>? x,
      WidgetStateProperty<T?>? y,
      T Function(T, T) f,
    ) => WidgetStateProperty.lerp<T?>(x, y, t, (p, q, t) => either<T>(p, q, f));
    return FrostedStyle(
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
      other is FrostedStyle && listEquals(other._slots, _slots);

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

/// One [FrostedStyle] per part, theme-wide, as Material's component themes
/// are: `FrostedThemeData.components`. A widget's own `style:` wins over its
/// theme's.
///
/// ```dart
/// final theme = FrostedThemeData.opal().copyWith(
///   components: const FrostedComponentThemes(
///     card: FrostedStyle(padding: WidgetStatePropertyAll(EdgeInsets.all(24))),
///   ),
/// );
/// ```
@immutable
class FrostedComponentThemes with Diagnosticable {
  /// The themes, each empty unless named.
  const FrostedComponentThemes({
    this.button = const FrostedStyle(),
    this.iconButton = const FrostedStyle(),
    this.textField = const FrostedStyle(),
    this.checkbox = const FrostedStyle(),
    this.radio = const FrostedStyle(),
    this.switchTheme = const FrostedStyle(),
    this.slider = const FrostedStyle(),
    this.chip = const FrostedStyle(),
    this.segmentedButton = const FrostedStyle(),
    this.tabBar = const FrostedStyle(),
    this.listTile = const FrostedStyle(),
    this.card = const FrostedStyle(),
    this.dialog = const FrostedStyle(),
    this.sheet = const FrostedStyle(),
    this.menu = const FrostedStyle(),
    this.snackBar = const FrostedStyle(),
    this.tooltip = const FrostedStyle(),
    this.navigationBar = const FrostedStyle(),
    this.badge = const FrostedStyle(),
    this.avatar = const FrostedStyle(),
    this.option = const FrostedStyle(),
    this.numberField = const FrostedStyle(),
    this.datePicker = const FrostedStyle(),
    this.timePicker = const FrostedStyle(),
  });

  /// Buttons: every variant's face, its words and glyph.
  final FrostedStyle button;

  /// Icon buttons: the round of glass and its glyph.
  final FrostedStyle iconButton;

  /// Fields and wells: text fields, the search pill, selects and the number field's well.
  final FrostedStyle textField;

  /// Checkboxes: the box and its tick.
  final FrostedStyle checkbox;

  /// Radios: the ring and its dot.
  final FrostedStyle radio;

  /// Switches: the track (fill), the knob (foreground).
  final FrostedStyle switchTheme;

  /// Sliders: the tube (fill up to the value), the knob (foreground).
  final FrostedStyle slider;

  /// Chips and tags.
  final FrostedStyle chip;

  /// Segmented buttons: the trough (side, shape) and the chosen thumb (fill, foreground).
  final FrostedStyle segmentedButton;

  /// Tab bars: the trough and the chosen tab.
  final FrostedStyle tabBar;

  /// List tiles: a row's fill, padding and its pressed state.
  final FrostedStyle listTile;

  /// Cards: the frosted tile.
  final FrostedStyle card;

  /// Dialogs.
  final FrostedStyle dialog;

  /// Bottom and side sheets.
  final FrostedStyle sheet;

  /// Menus and popovers.
  final FrostedStyle menu;

  /// Snack bars (toasts).
  final FrostedStyle snackBar;

  /// Tooltips.
  final FrostedStyle tooltip;

  /// The navigation bar, rail and drawer.
  final FrostedStyle navigationBar;

  /// Badges: the count's pill.
  final FrostedStyle badge;

  /// Avatars: the pearl the initials stand on.
  final FrostedStyle avatar;

  /// Options a person picks from: a sheet's options, quick amounts, icon choices, picker cells.
  final FrostedStyle option;

  /// The number field's minus and plus rounds.
  final FrostedStyle numberField;

  /// A date picker's day cells.
  final FrostedStyle datePicker;

  /// A time picker's cells.
  final FrostedStyle timePicker;

  static const List<String> _names = [
    'button',
    'iconButton',
    'textField',
    'checkbox',
    'radio',
    'switchTheme',
    'slider',
    'chip',
    'segmentedButton',
    'tabBar',
    'listTile',
    'card',
    'dialog',
    'sheet',
    'menu',
    'snackBar',
    'tooltip',
    'navigationBar',
    'badge',
    'avatar',
    'option',
    'numberField',
    'datePicker',
    'timePicker',
  ];

  List<FrostedStyle> get _all => [
    button,
    iconButton,
    textField,
    checkbox,
    radio,
    switchTheme,
    slider,
    chip,
    segmentedButton,
    tabBar,
    listTile,
    card,
    dialog,
    sheet,
    menu,
    snackBar,
    tooltip,
    navigationBar,
    badge,
    avatar,
    option,
    numberField,
    datePicker,
    timePicker,
  ];

  /// This with the named themes replaced.
  FrostedComponentThemes copyWith({
    FrostedStyle? button,
    FrostedStyle? iconButton,
    FrostedStyle? textField,
    FrostedStyle? checkbox,
    FrostedStyle? radio,
    FrostedStyle? switchTheme,
    FrostedStyle? slider,
    FrostedStyle? chip,
    FrostedStyle? segmentedButton,
    FrostedStyle? tabBar,
    FrostedStyle? listTile,
    FrostedStyle? card,
    FrostedStyle? dialog,
    FrostedStyle? sheet,
    FrostedStyle? menu,
    FrostedStyle? snackBar,
    FrostedStyle? tooltip,
    FrostedStyle? navigationBar,
    FrostedStyle? badge,
    FrostedStyle? avatar,
    FrostedStyle? option,
    FrostedStyle? numberField,
    FrostedStyle? datePicker,
    FrostedStyle? timePicker,
  }) => FrostedComponentThemes(
    button: button ?? this.button,
    iconButton: iconButton ?? this.iconButton,
    textField: textField ?? this.textField,
    checkbox: checkbox ?? this.checkbox,
    radio: radio ?? this.radio,
    switchTheme: switchTheme ?? this.switchTheme,
    slider: slider ?? this.slider,
    chip: chip ?? this.chip,
    segmentedButton: segmentedButton ?? this.segmentedButton,
    tabBar: tabBar ?? this.tabBar,
    listTile: listTile ?? this.listTile,
    card: card ?? this.card,
    dialog: dialog ?? this.dialog,
    sheet: sheet ?? this.sheet,
    menu: menu ?? this.menu,
    snackBar: snackBar ?? this.snackBar,
    tooltip: tooltip ?? this.tooltip,
    navigationBar: navigationBar ?? this.navigationBar,
    badge: badge ?? this.badge,
    avatar: avatar ?? this.avatar,
    option: option ?? this.option,
    numberField: numberField ?? this.numberField,
    datePicker: datePicker ?? this.datePicker,
    timePicker: timePicker ?? this.timePicker,
  );

  /// Between [a] and [b], part by part.
  static FrostedComponentThemes lerp(
    FrostedComponentThemes a,
    FrostedComponentThemes b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    FrostedStyle l(FrostedStyle x, FrostedStyle y) =>
        FrostedStyle.lerp(x, y, t) ?? const FrostedStyle();
    return FrostedComponentThemes(
      button: l(a.button, b.button),
      iconButton: l(a.iconButton, b.iconButton),
      textField: l(a.textField, b.textField),
      checkbox: l(a.checkbox, b.checkbox),
      radio: l(a.radio, b.radio),
      switchTheme: l(a.switchTheme, b.switchTheme),
      slider: l(a.slider, b.slider),
      chip: l(a.chip, b.chip),
      segmentedButton: l(a.segmentedButton, b.segmentedButton),
      tabBar: l(a.tabBar, b.tabBar),
      listTile: l(a.listTile, b.listTile),
      card: l(a.card, b.card),
      dialog: l(a.dialog, b.dialog),
      sheet: l(a.sheet, b.sheet),
      menu: l(a.menu, b.menu),
      snackBar: l(a.snackBar, b.snackBar),
      tooltip: l(a.tooltip, b.tooltip),
      navigationBar: l(a.navigationBar, b.navigationBar),
      badge: l(a.badge, b.badge),
      avatar: l(a.avatar, b.avatar),
      option: l(a.option, b.option),
      numberField: l(a.numberField, b.numberField),
      datePicker: l(a.datePicker, b.datePicker),
      timePicker: l(a.timePicker, b.timePicker),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedComponentThemes && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final all = _all;
    for (var i = 0; i < all.length; i++) {
      properties.add(
        DiagnosticsProperty<FrostedStyle>(
          _names[i],
          all[i],
          defaultValue: const FrostedStyle(),
        ),
      );
    }
  }
}
