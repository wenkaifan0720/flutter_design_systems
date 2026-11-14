import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How one part looks, as Material's `ButtonStyle` is: every slot resolves for the part's states
/// ([WidgetState.disabled], [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its component theme on `RetroDesktopThemeData`, then
/// from the theme-wide settings (`appearance`'s outlines, `density`, `typeface`), then from the look's own default. A slot
/// that is null, or resolves to null for the states at hand, falls through to the next.
///
/// | slot | what it sets |
/// |---|---|
/// | [fill] | the face or plate |
/// | [foreground] | the words and icons on it |
/// | [edge] | the rim's colour, at the look's width |
/// | [overlay] | the wash over the face while hovered, focused or pressed |
/// | [side] | the whole rim, colour and width; it wins over [edge] |
/// | [shape] | the outline: by default the appearance's at the part's step (`RetroDesktopShapes`), or any [OutlinedBorder] |
/// | [padding] | the room between the rim and what stands inside |
/// | [minimumSize] | the least the face stands; the touch target stays 48 on touch, 44 elsewhere |
/// | [textStyle] | the words' style, merged over the look's (its colour comes from [foreground]) |
/// | [iconSize] | an icon's size |
///
/// Parts consume the slots that apply to their visual role. Layout and data encodings keep their own geometry;
/// an outlined face animates a changed shape using the theme's motion policy.
///
/// ```dart
/// RetroDesktopStyle(fill: WidgetStatePropertyAll(Color(0xFFE0E0E0)))
/// ```
@immutable
class RetroDesktopStyle with Diagnosticable {
  /// Every slot null: the next layer's, down to the look's own.
  const RetroDesktopStyle({
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

  /// The rim's colour, drawn at the look's width (or the theme's `strokes.regular`).
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
  /// final fill = RetroDesktopStyle.first([style, theme.chipTheme], (s) => s.fill, states) ?? theme.colors.platinum;
  /// ```
  static T? first<T>(
    Iterable<RetroDesktopStyle?> layers,
    WidgetStateProperty<T?>? Function(RetroDesktopStyle style) slot,
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
  RetroDesktopStyle copyWith({
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
  }) => RetroDesktopStyle(
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

  /// This, with [other] as fallback when a slot is absent or resolves to null.
  RetroDesktopStyle merge(RetroDesktopStyle? other) {
    if (other == null) return this;
    WidgetStateProperty<T?>? fallback<T>(
      WidgetStateProperty<T?>? own,
      WidgetStateProperty<T?>? next,
    ) {
      if (own == null) return next;
      if (next == null) return own;
      return _FallbackProperty(own, next);
    }

    return copyWith(
      fill: fallback(fill, other.fill),
      foreground: fallback(foreground, other.foreground),
      edge: fallback(edge, other.edge),
      overlay: fallback(overlay, other.overlay),
      side: fallback(side, other.side),
      shape: fallback(shape, other.shape),
      padding: fallback(padding, other.padding),
      minimumSize: fallback(minimumSize, other.minimumSize),
      textStyle: fallback(textStyle, other.textStyle),
      iconSize: fallback(iconSize, other.iconSize),
    );
  }

  /// Between [a] and [b], slot by slot, as `ButtonStyle.lerp`: colours, sides, sizes and type blend, Retro Desktop's
  /// shapes morph into each other, other shapes snap at the middle.
  static RetroDesktopStyle? lerp(
    RetroDesktopStyle? a,
    RetroDesktopStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    T? either<T>(T? x, T? y, T Function(T, T) f) =>
        x == null || y == null ? (t < .5 ? x : y) : f(x, y);
    WidgetStateProperty<T?>? l<T>(
      WidgetStateProperty<T?>? x,
      WidgetStateProperty<T?>? y,
      T Function(T, T) f,
    ) => WidgetStateProperty.lerp<T?>(x, y, t, (p, q, t) => either<T>(p, q, f));
    return RetroDesktopStyle(
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
      other is RetroDesktopStyle && listEquals(other._slots, _slots);

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

class _FallbackProperty<T> implements WidgetStateProperty<T?> {
  const _FallbackProperty(this.own, this.next);
  final WidgetStateProperty<T?> own, next;
  @override
  T? resolve(Set<WidgetState> states) =>
      own.resolve(states) ?? next.resolve(states);
  @override
  bool operator ==(Object other) =>
      other is _FallbackProperty<T> && own == other.own && next == other.next;
  @override
  int get hashCode => Object.hash(own, next);
}

/// Every component theme in one, as `ThemeData` holds Material's: what `RetroDesktopThemeData` carries and lerps.
@immutable
class RetroDesktopComponentThemes with Diagnosticable {
  /// All empty: the look's own throughout.
  const RetroDesktopComponentThemes({
    this.defaultButton = const RetroDesktopStyle(),
    this.button = const RetroDesktopStyle(),
    this.textButton = const RetroDesktopStyle(),
    this.iconButton = const RetroDesktopStyle(),
    this.checkbox = const RetroDesktopStyle(),
    this.radio = const RetroDesktopStyle(),
    this.switchTheme = const RetroDesktopStyle(),
    this.textField = const RetroDesktopStyle(),
    this.chip = const RetroDesktopStyle(),
    this.slider = const RetroDesktopStyle(),
    this.segmentedButton = const RetroDesktopStyle(),
    this.card = const RetroDesktopStyle(),
    this.dialog = const RetroDesktopStyle(),
    this.sheet = const RetroDesktopStyle(),
    this.menu = const RetroDesktopStyle(),
    this.snackBar = const RetroDesktopStyle(),
    this.tooltip = const RetroDesktopStyle(),
    this.badge = const RetroDesktopStyle(),
    this.avatar = const RetroDesktopStyle(),
    this.option = const RetroDesktopStyle(),
    this.stepper = const RetroDesktopStyle(),
    this.datePicker = const RetroDesktopStyle(),
    this.timePicker = const RetroDesktopStyle(),
    this.appBar = const RetroDesktopStyle(),
    this.navigationBar = const RetroDesktopStyle(),
    this.tabBar = const RetroDesktopStyle(),
    this.listTile = const RetroDesktopStyle(),
    this.disclosure = const RetroDesktopStyle(),
    this.progress = const RetroDesktopStyle(),
    this.notice = const RetroDesktopStyle(),
    this.divider = const RetroDesktopStyle(),
    this.chart = const RetroDesktopStyle(),
    this.toolbar = const RetroDesktopStyle(),
    this.well = const RetroDesktopStyle(),
    this.window = const RetroDesktopStyle(),
  });

  /// The act button's.
  final RetroDesktopStyle defaultButton;

  /// The line button's.
  final RetroDesktopStyle button;

  /// The quiet button's.
  final RetroDesktopStyle textButton;

  /// The icon button's.
  final RetroDesktopStyle iconButton;

  /// A tick box's.
  final RetroDesktopStyle checkbox;

  /// The radio's.
  final RetroDesktopStyle radio;

  /// The switch's.
  final RetroDesktopStyle switchTheme;

  /// A field's.
  final RetroDesktopStyle textField;

  /// A chip's.
  final RetroDesktopStyle chip;

  /// The slider's.
  final RetroDesktopStyle slider;

  /// The segmented strip's.
  final RetroDesktopStyle segmentedButton;

  /// A card's.
  final RetroDesktopStyle card;

  /// A dialog's.
  final RetroDesktopStyle dialog;

  /// A bottom sheet's.
  final RetroDesktopStyle sheet;

  /// A menu's.
  final RetroDesktopStyle menu;

  /// The snack bar's.
  final RetroDesktopStyle snackBar;

  /// The tooltip's.
  final RetroDesktopStyle tooltip;

  /// The badge's.
  final RetroDesktopStyle badge;

  /// The avatar's.
  final RetroDesktopStyle avatar;

  /// An option's, and a time slot's.
  final RetroDesktopStyle option;

  /// The number stepper's.
  final RetroDesktopStyle stepper;

  /// The date picker's.
  final RetroDesktopStyle datePicker;

  /// The time picker's.
  final RetroDesktopStyle timePicker;

  /// The appBar appearance.
  final RetroDesktopStyle appBar;

  /// The navigationBar appearance.
  final RetroDesktopStyle navigationBar;

  /// The tabBar appearance.
  final RetroDesktopStyle tabBar;

  /// The listTile appearance.
  final RetroDesktopStyle listTile;

  /// The disclosure appearance.
  final RetroDesktopStyle disclosure;

  /// The progress appearance.
  final RetroDesktopStyle progress;

  /// The notice appearance.
  final RetroDesktopStyle notice;

  /// The divider appearance.
  final RetroDesktopStyle divider;

  /// The chart appearance.
  final RetroDesktopStyle chart;

  /// The window appearance.
  final RetroDesktopStyle window;

  /// The well appearance.
  final RetroDesktopStyle well;

  /// The toolbar appearance.
  final RetroDesktopStyle toolbar;

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
    'appBar',
    'navigationBar',
    'tabBar',
    'listTile',
    'disclosure',
    'progress',
    'notice',
    'divider',
    'chart',
    'toolbar',
    'well',
    'window',
  ];

  List<RetroDesktopStyle> get _all => [
    defaultButton,
    button,
    textButton,
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
    appBar,
    navigationBar,
    tabBar,
    listTile,
    disclosure,
    progress,
    notice,
    divider,
    chart,
    toolbar,
    well,
    window,
  ];

  static RetroDesktopComponentThemes _of(List<RetroDesktopStyle> s) =>
      RetroDesktopComponentThemes(
        defaultButton: s[0],
        button: s[1],
        textButton: s[2],
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
        appBar: s[23],
        navigationBar: s[24],
        tabBar: s[25],
        listTile: s[26],
        disclosure: s[27],
        progress: s[28],
        notice: s[29],
        divider: s[30],
        chart: s[31],
        window: s[34],
        well: s[33],
        toolbar: s[32],
      );

  /// This with the named themes changed.
  RetroDesktopComponentThemes copyWith({
    RetroDesktopStyle? defaultButton,
    RetroDesktopStyle? button,
    RetroDesktopStyle? textButton,
    RetroDesktopStyle? iconButton,
    RetroDesktopStyle? checkbox,
    RetroDesktopStyle? radio,
    RetroDesktopStyle? switchTheme,
    RetroDesktopStyle? textField,
    RetroDesktopStyle? chip,
    RetroDesktopStyle? slider,
    RetroDesktopStyle? segmentedButton,
    RetroDesktopStyle? card,
    RetroDesktopStyle? dialog,
    RetroDesktopStyle? sheet,
    RetroDesktopStyle? menu,
    RetroDesktopStyle? snackBar,
    RetroDesktopStyle? tooltip,
    RetroDesktopStyle? badge,
    RetroDesktopStyle? avatar,
    RetroDesktopStyle? option,
    RetroDesktopStyle? stepper,
    RetroDesktopStyle? datePicker,
    RetroDesktopStyle? timePicker,
    RetroDesktopStyle? appBar,
    RetroDesktopStyle? navigationBar,
    RetroDesktopStyle? tabBar,
    RetroDesktopStyle? listTile,
    RetroDesktopStyle? disclosure,
    RetroDesktopStyle? progress,
    RetroDesktopStyle? notice,
    RetroDesktopStyle? divider,
    RetroDesktopStyle? chart,
    RetroDesktopStyle? toolbar,
    RetroDesktopStyle? well,
    RetroDesktopStyle? window,
  }) => RetroDesktopComponentThemes(
    defaultButton: defaultButton ?? this.defaultButton,
    button: button ?? this.button,
    textButton: textButton ?? this.textButton,
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
    appBar: appBar ?? this.appBar,
    navigationBar: navigationBar ?? this.navigationBar,
    tabBar: tabBar ?? this.tabBar,
    listTile: listTile ?? this.listTile,
    disclosure: disclosure ?? this.disclosure,
    progress: progress ?? this.progress,
    notice: notice ?? this.notice,
    divider: divider ?? this.divider,
    chart: chart ?? this.chart,
    toolbar: toolbar ?? this.toolbar,
    well: well ?? this.well,
    window: window ?? this.window,
  );

  /// Between [a] and [b], theme by theme.
  static RetroDesktopComponentThemes lerp(
    RetroDesktopComponentThemes a,
    RetroDesktopComponentThemes b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final x = a._all, y = b._all;
    return _of([
      for (var i = 0; i < x.length; i++) RetroDesktopStyle.lerp(x[i], y[i], t)!,
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetroDesktopComponentThemes && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final all = _all;
    for (var i = 0; i < _names.length; i++) {
      properties.add(
        DiagnosticsProperty<RetroDesktopStyle>(
          _names[i],
          all[i],
          defaultValue: const RetroDesktopStyle(),
        ),
      );
    }
  }
}

/// The states a painted control is in, for its style.
Set<WidgetState> retroDesktopStates({
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
