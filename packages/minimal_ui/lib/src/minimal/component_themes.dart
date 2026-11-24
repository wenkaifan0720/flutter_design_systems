/// How one part looks, set on the widget (`style:`) or theme-wide (the
/// component themes on `MinimalThemeData`), as Material's `ButtonStyle` and
/// its themes are.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// How one part looks: ui_core's [RawStyle], under Minimal's name. Every
/// slot resolves for the part's states ([WidgetState.disabled],
/// [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected], [WidgetState.error]).
///
/// A part reads each slot from its own `style:` first, then from its
/// component theme on `MinimalThemeData`, then from the theme-wide knobs
/// (`shapes`, `density`, `typeface`), then from the look's own default. A
/// slot that is null, or resolves to null for the states at hand, falls
/// through to the next.
///
/// | slot | what it sets |
/// |---|---|
/// | `fill` | the face or plate |
/// | `foreground` | the words and icons on it |
/// | `edge` | the rim's colour, at the theme's `t.rim` |
/// | `overlay` | the wash over the face while hovered or pressed |
/// | `side` | the whole rim, colour and width; it wins over `edge` |
/// | `shape` | the outline: any [OutlinedBorder] |
/// | `padding` | the room between the rim and what stands inside |
/// | `minimumSize` | the least the face stands; its tap target stays the floor round it |
/// | `textStyle` | the words' style, merged over the look's (its colour comes from `foreground`) |
/// | `iconSize` | an icon's size |
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
typedef MinimalStyle = RawStyle;

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

  /// `MinimalChip`. A `fill` for `WidgetState.selected` is the tinted pill
  /// Minimal never draws: a selected chip says it in ink and weight.
  final MinimalStyle? chip;

  /// `MinimalCheckbox`.
  final MinimalStyle? checkbox;

  /// The radio in `MinimalRadioGroup`.
  final MinimalStyle? radio;

  /// `MinimalSwitch`.
  final MinimalStyle? switchTheme;

  /// `MinimalSlider`.
  final MinimalStyle? slider;

  /// `MinimalSegmentedButton`. A `fill` for `WidgetState.selected` is the
  /// tinted pill Minimal never draws: the chosen segment says it in ink and
  /// weight on its plate.
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
