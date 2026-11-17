/// How one part looks, set on the widget (`style:`) or theme-wide (the
/// component themes on `LedgerThemeData.components`), as Material's
/// `ButtonStyle` and its themes are.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

export 'package:ui_core/ui_core.dart' show DesignStyle, DesignStyleOf;

/// How one part looks: ui_core's [DesignStyle], under Ledger's name. Every
/// slot resolves for the part's states ([WidgetState.disabled],
/// [WidgetState.hovered], [WidgetState.focused], [WidgetState.pressed],
/// [WidgetState.selected]).
///
/// A part reads each slot from its own `style:` first, then from its
/// component theme on `LedgerThemeData.components`, then from the theme's
/// own roles (its inks, papers, rules and radii). A slot that is null, or
/// resolves to null for the states at hand, falls through to the next.
///
/// | slot | what it sets in Ledger |
/// |---|---|
/// | `fill` | the paper of the face |
/// | `foreground` | the ink of its words and glyphs |
/// | `edge` | the rule round it, at the face's own width |
/// | `overlay` | a wash over the face in the states it names |
/// | `side` | the whole rule, ink and width; it wins over `edge` |
/// | `shape` | the corners: a rounded rectangle's, a stadium or a circle |
/// | `padding` | the room between the rule and what stands inside |
/// | `minimumSize` | the least the face stands; its tap target stays 44 round it |
/// | `textStyle` | the words' style, merged over Ledger's (its ink comes from `foreground`) |
/// | `iconSize` | a glyph's size |
///
/// Each part's doc says which slots it reads.
///
/// ```dart
/// LedgerButton(
///   'Export',
///   onPressed: export,
///   style: LedgerStyle(
///     shape: const WidgetStatePropertyAll(StadiumBorder()),
///     padding: const WidgetStatePropertyAll(
///       EdgeInsets.symmetric(horizontal: 24),
///     ),
///   ),
/// )
/// ```
typedef LedgerStyle = DesignStyle;

/// A part's style layers read at its states: its own `style:`, then its
/// component theme (first wins). ui_core's [DesignStyleOf] under Ledger's
/// name.
///
/// ```dart
/// final look = LedgerStyleOf([style, t.components.chip], states);
/// final paper = look.fill ?? t.surface;
/// ```
typedef LedgerStyleOf = DesignStyleOf;

/// Every component theme in one, as `ThemeData` holds Material's: what
/// `LedgerThemeData.components` carries and lerps. Each is null until an
/// app sets it, and a null one leaves its parts as the book draws them.
///
/// ```dart
/// final theme = LedgerThemeData.light().copyWith(
///   components: const LedgerComponentThemes(
///     chip: LedgerStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
///   ),
/// );
/// ```
@immutable
class LedgerComponentThemes with Diagnosticable {
  /// The named themes; every other null.
  const LedgerComponentThemes({
    this.button,
    this.filledButton,
    this.inkButton,
    this.textButton,
    this.iconButton,
    this.textField,
    this.chip,
    this.checkbox,
    this.switchTheme,
    this.segmentedControl,
    this.toggleGroup,
    this.badge,
    this.banner,
    this.tooltip,
    this.toast,
    this.dialog,
    this.slip,
  });

  /// `LedgerButton`, the ringed act.
  final LedgerStyle? button;

  /// `LedgerButton.filled`, the page's one act.
  final LedgerStyle? filledButton;

  /// `LedgerButton.ink`, the firm act on a raised surface.
  final LedgerStyle? inkButton;

  /// `LedgerButton.text`, words alone.
  final LedgerStyle? textButton;

  /// `LedgerIconButton` and `LedgerBell`.
  final LedgerStyle? iconButton;

  /// Every ruled field line: `LedgerTextField`, `LedgerPasswordField` and `LedgerTextArea`.
  final LedgerStyle? textField;

  /// `LedgerChip`.
  final LedgerStyle? chip;

  /// `LedgerCheckbox`'s box.
  final LedgerStyle? checkbox;

  /// `LedgerSwitch`'s track.
  final LedgerStyle? switchTheme;

  /// `LedgerSegmentedControl`'s chosen face.
  final LedgerStyle? segmentedControl;

  /// Each pill of `LedgerToggleGroup`.
  final LedgerStyle? toggleGroup;

  /// `LedgerBadge`.
  final LedgerStyle? badge;

  /// `LedgerBanner`.
  final LedgerStyle? banner;

  /// `LedgerTooltip`'s slip.
  final LedgerStyle? tooltip;

  /// `LedgerToastCard`, every toast `LedgerToast.show` raises.
  final LedgerStyle? toast;

  /// `LedgerDialog`'s card.
  final LedgerStyle? dialog;

  /// `LedgerSlip`, the paper slip a page's groups sit on.
  final LedgerStyle? slip;

  List<LedgerStyle?> get _all => [
    button,
    filledButton,
    inkButton,
    textButton,
    iconButton,
    textField,
    chip,
    checkbox,
    switchTheme,
    segmentedControl,
    toggleGroup,
    badge,
    banner,
    tooltip,
    toast,
    dialog,
    slip,
  ];

  static const List<String> _names = [
    'button',
    'filledButton',
    'inkButton',
    'textButton',
    'iconButton',
    'textField',
    'chip',
    'checkbox',
    'switchTheme',
    'segmentedControl',
    'toggleGroup',
    'badge',
    'banner',
    'tooltip',
    'toast',
    'dialog',
    'slip',
  ];

  /// True when no component theme is set.
  bool get isEmpty => _all.every((s) => s == null);

  /// This with the named themes changed.
  LedgerComponentThemes copyWith({
    LedgerStyle? button,
    LedgerStyle? filledButton,
    LedgerStyle? inkButton,
    LedgerStyle? textButton,
    LedgerStyle? iconButton,
    LedgerStyle? textField,
    LedgerStyle? chip,
    LedgerStyle? checkbox,
    LedgerStyle? switchTheme,
    LedgerStyle? segmentedControl,
    LedgerStyle? toggleGroup,
    LedgerStyle? badge,
    LedgerStyle? banner,
    LedgerStyle? tooltip,
    LedgerStyle? toast,
    LedgerStyle? dialog,
    LedgerStyle? slip,
  }) => LedgerComponentThemes(
    button: button ?? this.button,
    filledButton: filledButton ?? this.filledButton,
    inkButton: inkButton ?? this.inkButton,
    textButton: textButton ?? this.textButton,
    iconButton: iconButton ?? this.iconButton,
    textField: textField ?? this.textField,
    chip: chip ?? this.chip,
    checkbox: checkbox ?? this.checkbox,
    switchTheme: switchTheme ?? this.switchTheme,
    segmentedControl: segmentedControl ?? this.segmentedControl,
    toggleGroup: toggleGroup ?? this.toggleGroup,
    badge: badge ?? this.badge,
    banner: banner ?? this.banner,
    tooltip: tooltip ?? this.tooltip,
    toast: toast ?? this.toast,
    dialog: dialog ?? this.dialog,
    slip: slip ?? this.slip,
  );

  /// Between [a] and [b], theme by theme.
  static LedgerComponentThemes lerp(
    LedgerComponentThemes a,
    LedgerComponentThemes b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    LedgerStyle? l(LedgerStyle? x, LedgerStyle? y) => DesignStyle.lerp(x, y, t);
    return LedgerComponentThemes(
      button: l(a.button, b.button),
      filledButton: l(a.filledButton, b.filledButton),
      inkButton: l(a.inkButton, b.inkButton),
      textButton: l(a.textButton, b.textButton),
      iconButton: l(a.iconButton, b.iconButton),
      textField: l(a.textField, b.textField),
      chip: l(a.chip, b.chip),
      checkbox: l(a.checkbox, b.checkbox),
      switchTheme: l(a.switchTheme, b.switchTheme),
      segmentedControl: l(a.segmentedControl, b.segmentedControl),
      toggleGroup: l(a.toggleGroup, b.toggleGroup),
      badge: l(a.badge, b.badge),
      banner: l(a.banner, b.banner),
      tooltip: l(a.tooltip, b.tooltip),
      toast: l(a.toast, b.toast),
      dialog: l(a.dialog, b.dialog),
      slip: l(a.slip, b.slip),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerComponentThemes && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final all = _all;
    for (var i = 0; i < all.length; i++) {
      properties.add(
        DiagnosticsProperty<LedgerStyle>(_names[i], all[i], defaultValue: null),
      );
    }
  }
}
