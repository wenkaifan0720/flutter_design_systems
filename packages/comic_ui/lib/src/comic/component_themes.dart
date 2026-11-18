import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

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
///
/// An alias for [DesignStyle].
typedef ComicStyle = DesignStyle;

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
