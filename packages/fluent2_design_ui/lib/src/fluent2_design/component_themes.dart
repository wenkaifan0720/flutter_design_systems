// How a part looks, slot by slot, and the component themes that carry one
// per part: what `Fluent2ThemeData` holds and lerps, as Material's
// `ThemeData` holds its component themes.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

export 'package:ui_core/ui_core.dart' show RawStyle, RawStyleOf;

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
/// does. It is ui_core's [RawStyle], so every look's parts take the same
/// style, read the same way: build one as `Fluent2Style(...)` or
/// `RawStyle(...)`.
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
typedef Fluent2Style = RawStyle;

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
