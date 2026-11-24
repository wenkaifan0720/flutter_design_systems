import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// How one part looks: ui_core's [RawStyle] under the look's name, so every look's parts take one style, read the same
/// way. Every slot resolves for the part's states ([WidgetState.disabled], [WidgetState.hovered],
/// [WidgetState.focused], [WidgetState.pressed], [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its component theme on `RetroDesktopThemeData`, then
/// from the theme-wide settings (`appearance`'s outlines, `density`, `typeface`), then from the look's own default. A slot
/// that is null, or resolves to null for the states at hand, falls through to the next.
///
/// | slot | what it sets |
/// |---|---|
/// | `fill` | the face or plate |
/// | `foreground` | the words and icons on it |
/// | `edge` | the rim's colour, at the look's width |
/// | `overlay` | a wash over the face in the states it resolves for (the period drew none on hover) |
/// | `side` | the whole rim, colour and width; it wins over `edge` (the look's widths are 1 and 2) |
/// | `shape` | the outline: by default the appearance's at the part's step (`RetroDesktopShapes`) |
/// | `padding` | the room between the rim and what stands inside |
/// | `minimumSize` | the least the face stands; the tap target stays 48 on touch, 44 high elsewhere |
/// | `textStyle` | the words' style, merged over the look's (its colour comes from `foreground`) |
/// | `iconSize` | an icon's size |
///
/// `merge` keeps a slot whole, as `ButtonStyle.merge` does; [RawStyle.layered] falls through within a slot, state by
/// state.
///
/// The look's bounds: a `shape` is the period's, a `RetroDesktopBorder` on the pixel grid; any other [OutlinedBorder]
/// (a stadium, a large radius) is drawn smooth and off the grid and no longer looks like this look. A `side` wider than
/// 2, a soft shadow or a hover wash leaves it too. Colours are free where the look has one: a face, its words, the
/// highlight.
///
/// ```dart
/// RetroDesktopStyle(fill: WidgetStatePropertyAll(Color(0xFFE0E0E0)))
/// ```
typedef RetroDesktopStyle = RawStyle;

/// A part's style layers (its `style:`, then its component theme) read at its states: ui_core's [RawStyleOf].
///
/// ```dart
/// RetroDesktopStyleOf([style, theme.buttonTheme], states).fill
/// ```
typedef RetroDesktopStyleOf = RawStyleOf;

/// The look's own layering of a component theme over its default for a part.
extension RetroDesktopStyleLayers on RawStyle {
  /// This over [below], slot by slot and state by state: a slot of this that is absent, or resolves to null for the
  /// states at hand, takes [below]'s ([RawStyle.layered]).
  RawStyle over(RawStyle? below) => RawStyle.layered([this, below]);
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
