/// Icon buttons: standard, filled, tonal and outlined; XS–XL; narrow,
/// uniform or wide; round or square; toggle (CONTRACT §4.1 `icon-button`).
/// Owner: w3-iconbuttons, with `test/icon_buttons_test.dart` and the
/// gallery's icon-buttons demo.
///
/// A port of Compose material3 1.5.0-alpha29 (wave decision F1):
///
/// - [ExpressiveIconButton] is `IconButton`, `FilledIconButton`,
///   `FilledTonalIconButton` and `OutlinedIconButton` with
///   `IconButtonDefaults`' size ladder (`extraSmallContainerSize` …
///   `extraLargeContainerSize` by `IconButtonWidthOption`, the size's icon
///   size and its round, square and pressed shapes). The shape springs to
///   the size's pressed shape on `IconButtonBehavior.pressMotion` (an
///   effects spring: the press never bounces).
/// - [ExpressiveIconToggleButton] is `IconToggleButton`,
///   `FilledIconToggleButton`, `FilledTonalIconToggleButton` and
///   `OutlinedIconToggleButton` with `IconButtonDefaults.toggleableShapes`:
///   the checked colours, the checked shape (a round button checks to the
///   size's `selected.container.shape.round`, a square one to its
///   `…square`), and the glyph filling as it checks.
/// - In an `ExpressiveButtonGroup` both join the group's squish, as any
///   child of Compose's `ButtonGroup` does through `Modifier.animateWidth`:
///   the pressed button widens, its neighbours give way, and the glyph
///   stays centred in the width the group fixes.
/// - Colours are `IconButtonDefaults`': the standard and outlined buttons
///   take their content colour from the ambient icon colour (Compose's
///   `LocalContentColor`) unless `vibrant` asks for the tokens'
///   `onSurfaceVariant` (Compose's `*VibrantColors`).
///
/// L and XL icon buttons (96 and 136dp) are hero widgets (CONTRACT §3):
/// they assert an [ExpressiveHeroMoment] above them.
library;

import 'package:flutter/widgets.dart';

import '../color.dart';
import '../component_themes.dart';
import '../icons.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/filled_icon_button_tokens.g.dart';
import '../internal/tokens/filled_tonal_icon_button_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/large_icon_button_tokens.g.dart';
import '../internal/tokens/medium_icon_button_tokens.g.dart';
import '../internal/tokens/outlined_icon_button_tokens.g.dart';
import '../internal/tokens/small_icon_button_tokens.g.dart';
import '../internal/tokens/standard_icon_button_tokens.g.dart';
import '../internal/tokens/x_large_icon_button_tokens.g.dart';
import '../internal/tokens/x_small_icon_button_tokens.g.dart';
import '../internal/width_probe.dart';
import '../states.dart';
import '../internal/styled_content.dart';
import '../theme.dart';
import 'buttons.dart' show ExpressiveButtonGroup;
import 'hero.dart';

/// Material's four icon-button styles.
enum ExpressiveIconButtonKind {
  /// No container: the lowest emphasis (Compose `IconButton`).
  standard,

  /// A `primary` container: the highest emphasis (`FilledIconButton`).
  filled,

  /// A `secondaryContainer` container (`FilledTonalIconButton`).
  filledTonal,

  /// An outline, no fill (`OutlinedIconButton`).
  outlined,
}

/// Material's five icon-button sizes: the container height.
enum ExpressiveIconButtonSize {
  /// 32dp, a 20dp glyph.
  extraSmall,

  /// 40dp, a 24dp glyph: the default.
  small,

  /// 56dp, a 24dp glyph.
  medium,

  /// 96dp, a 32dp glyph: a hero size.
  large,

  /// 136dp, a 40dp glyph: a hero size.
  extraLarge;

  /// Whether the size is a hero moment (L, XL): it asserts an
  /// [ExpressiveHeroMoment] above it.
  bool get isHero =>
      this == ExpressiveIconButtonSize.large ||
      this == ExpressiveIconButtonSize.extraLarge;
}

/// How wide an icon button is beside its height (Compose's
/// `IconButtonWidthOption`): the glyph plus the size's narrow, default or
/// wide leading and trailing space.
enum ExpressiveIconButtonWidth {
  /// Narrower than tall.
  narrow,

  /// As wide as tall: the default.
  uniform,

  /// Wider than tall.
  wide,
}

/// An icon button's corners at rest.
enum ExpressiveIconButtonShape {
  /// Fully round: the default.
  round,

  /// The size's square corners.
  square,
}

/// One size's tokens (`XSmallIconButtonTokens` … `XLargeIconButtonTokens`).
@immutable
class _IconMetrics {
  const _IconMetrics({
    required this.height,
    required this.iconSize,
    required this.narrowSpace,
    required this.uniformSpace,
    required this.wideSpace,
    required this.round,
    required this.square,
    required this.pressed,
    required this.selectedRound,
    required this.selectedSquare,
  });

  static _IconMetrics of(ExpressiveIconButtonSize size) => switch (size) {
    ExpressiveIconButtonSize.extraSmall => _xs,
    ExpressiveIconButtonSize.small => _s,
    ExpressiveIconButtonSize.medium => _m,
    ExpressiveIconButtonSize.large => _l,
    ExpressiveIconButtonSize.extraLarge => _xl,
  };

  // `IconButtonWidthOption.Uniform` adds the default leading space twice, as
  // Compose does.
  static const _IconMetrics _xs = _IconMetrics(
    height: XSmallIconButtonTokens.containerHeight,
    iconSize: XSmallIconButtonTokens.iconSize,
    narrowSpace:
        XSmallIconButtonTokens.narrowLeadingSpace +
        XSmallIconButtonTokens.narrowTrailingSpace,
    uniformSpace:
        XSmallIconButtonTokens.defaultLeadingSpace +
        XSmallIconButtonTokens.defaultLeadingSpace,
    wideSpace:
        XSmallIconButtonTokens.wideLeadingSpace +
        XSmallIconButtonTokens.wideTrailingSpace,
    round: XSmallIconButtonTokens.containerShapeRound,
    square: XSmallIconButtonTokens.containerShapeSquare,
    pressed: XSmallIconButtonTokens.pressedContainerShape,
    selectedRound: XSmallIconButtonTokens.selectedContainerShapeRound,
    selectedSquare: XSmallIconButtonTokens.selectedContainerShapeSquare,
  );

  static const _IconMetrics _s = _IconMetrics(
    height: SmallIconButtonTokens.containerHeight,
    iconSize: SmallIconButtonTokens.iconSize,
    narrowSpace:
        SmallIconButtonTokens.narrowLeadingSpace +
        SmallIconButtonTokens.narrowTrailingSpace,
    uniformSpace:
        SmallIconButtonTokens.defaultLeadingSpace +
        SmallIconButtonTokens.defaultLeadingSpace,
    wideSpace:
        SmallIconButtonTokens.wideLeadingSpace +
        SmallIconButtonTokens.wideTrailingSpace,
    round: SmallIconButtonTokens.containerShapeRound,
    square: SmallIconButtonTokens.containerShapeSquare,
    pressed: SmallIconButtonTokens.pressedContainerShape,
    selectedRound: SmallIconButtonTokens.selectedContainerShapeRound,
    selectedSquare: SmallIconButtonTokens.selectedContainerShapeSquare,
  );

  static const _IconMetrics _m = _IconMetrics(
    height: MediumIconButtonTokens.containerHeight,
    iconSize: MediumIconButtonTokens.iconSize,
    narrowSpace:
        MediumIconButtonTokens.narrowLeadingSpace +
        MediumIconButtonTokens.narrowTrailingSpace,
    uniformSpace:
        MediumIconButtonTokens.defaultLeadingSpace +
        MediumIconButtonTokens.defaultLeadingSpace,
    wideSpace:
        MediumIconButtonTokens.wideLeadingSpace +
        MediumIconButtonTokens.wideTrailingSpace,
    round: MediumIconButtonTokens.containerShapeRound,
    square: MediumIconButtonTokens.containerShapeSquare,
    pressed: MediumIconButtonTokens.pressedContainerShape,
    selectedRound: MediumIconButtonTokens.selectedContainerShapeRound,
    selectedSquare: MediumIconButtonTokens.selectedContainerShapeSquare,
  );

  // The large size names its default space `uniform`.
  static const _IconMetrics _l = _IconMetrics(
    height: LargeIconButtonTokens.containerHeight,
    iconSize: LargeIconButtonTokens.iconSize,
    narrowSpace:
        LargeIconButtonTokens.narrowLeadingSpace +
        LargeIconButtonTokens.narrowTrailingSpace,
    uniformSpace:
        LargeIconButtonTokens.uniformLeadingSpace +
        LargeIconButtonTokens.uniformLeadingSpace,
    wideSpace:
        LargeIconButtonTokens.wideLeadingSpace +
        LargeIconButtonTokens.wideTrailingSpace,
    round: LargeIconButtonTokens.containerShapeRound,
    square: LargeIconButtonTokens.containerShapeSquare,
    pressed: LargeIconButtonTokens.pressedContainerShape,
    selectedRound: LargeIconButtonTokens.selectedContainerShapeRound,
    selectedSquare: LargeIconButtonTokens.selectedContainerShapeSquare,
  );

  static const _IconMetrics _xl = _IconMetrics(
    height: XLargeIconButtonTokens.containerHeight,
    iconSize: XLargeIconButtonTokens.iconSize,
    narrowSpace:
        XLargeIconButtonTokens.narrowLeadingSpace +
        XLargeIconButtonTokens.narrowTrailingSpace,
    uniformSpace:
        XLargeIconButtonTokens.defaultLeadingSpace +
        XLargeIconButtonTokens.defaultLeadingSpace,
    wideSpace:
        XLargeIconButtonTokens.wideLeadingSpace +
        XLargeIconButtonTokens.wideTrailingSpace,
    round: XLargeIconButtonTokens.containerShapeRound,
    square: XLargeIconButtonTokens.containerShapeSquare,
    pressed: XLargeIconButtonTokens.pressedContainerShape,
    selectedRound: XLargeIconButtonTokens.selectedContainerShapeRound,
    selectedSquare: XLargeIconButtonTokens.selectedContainerShapeSquare,
  );

  final double height;
  final double iconSize;
  final double narrowSpace;
  final double uniformSpace;
  final double wideSpace;
  final ExpressiveShapeKey round;
  final ExpressiveShapeKey square;
  final ExpressiveShapeKey pressed;
  final ExpressiveShapeKey selectedRound;
  final ExpressiveShapeKey selectedSquare;

  /// `IconButtonDefaults.*ContainerSize(widthOption)`.
  Size container(ExpressiveIconButtonWidth width) => Size(
    iconSize +
        switch (width) {
          ExpressiveIconButtonWidth.narrow => narrowSpace,
          ExpressiveIconButtonWidth.uniform => uniformSpace,
          ExpressiveIconButtonWidth.wide => wideSpace,
        },
    height,
  );
}

/// What an icon button paints with in one state.
@immutable
class _IconPaint {
  const _IconPaint(this.container, this.content, [this.side = BorderSide.none]);

  final Color container;
  final Color content;
  final BorderSide side;

  /// This with [theme]'s slots for [states] over it; the outline recoloured
  /// where there is one.
  _IconPaint themed(
    ExpressiveComponentThemeData theme,
    Set<WidgetState> states,
  ) {
    if (theme.isEmpty) return this;
    return _IconPaint(
      ExpressiveComponentThemeData.resolve(
        theme.backgroundColor,
        states,
        container,
      ),
      ExpressiveComponentThemeData.resolve(
        theme.foregroundColor,
        states,
        content,
      ),
      side.style == BorderStyle.none || side.width <= 0
          ? side
          : side.copyWith(
              color: ExpressiveComponentThemeData.resolve(
                theme.outline,
                states,
                side.color,
              ),
            ),
    );
  }
}

const Color _transparent = expressiveTransparent;

Color _alpha(
  ExpressiveColorScheme colors,
  ExpressiveColorRole role,
  double alpha,
) => colors.role(role).withValues(alpha: alpha);

/// `IconButtonDefaults.outlinedIconButtonBorder` (the ambient colour) and
/// `outlinedIconButtonVibrantBorder` (`outlineVariant`): the small size's
/// width at every size, as Compose draws it.
BorderSide _outline(
  ExpressiveColorScheme colors,
  Color ambient, {
  required bool vibrant,
  required bool enabled,
}) {
  final color = vibrant
      ? colors.role(OutlinedIconButtonTokens.outlineColor)
      : ambient;
  return BorderSide(
    width: SmallIconButtonTokens.outlinedOutlineWidth,
    color: enabled
        ? color
        : color.withValues(alpha: OutlinedIconButtonTokens.disabledOpacity),
  );
}

/// `IconButtonDefaults.*IconButtonColors` and `*IconToggleButtonColors`,
/// with the outlined border ([toggle] false: a plain icon button, which
/// ignores [checked]).
_IconPaint _iconPaint(
  ExpressiveColorScheme colors,
  ExpressiveIconButtonKind kind, {
  required Color ambient,
  required bool vibrant,
  required bool enabled,
  required bool toggle,
  required bool checked,
}) {
  switch (kind) {
    case ExpressiveIconButtonKind.standard:
      if (!enabled) {
        return _IconPaint(
          _transparent,
          (vibrant
                  ? colors.role(StandardIconButtonTokens.disabledColor)
                  : ambient)
              .withValues(alpha: StandardIconButtonTokens.disabledOpacity),
        );
      }
      if (toggle && checked) {
        return _IconPaint(
          _transparent,
          colors.role(StandardIconButtonTokens.selectedColor),
        );
      }
      return _IconPaint(
        _transparent,
        vibrant
            ? colors.role(
                toggle
                    ? StandardIconButtonTokens.unselectedColor
                    : StandardIconButtonTokens.color,
              )
            : ambient,
      );
    case ExpressiveIconButtonKind.filled:
      if (!enabled) {
        return _IconPaint(
          _alpha(
            colors,
            FilledIconButtonTokens.disabledContainerColor,
            FilledIconButtonTokens.disabledContainerOpacity,
          ),
          _alpha(
            colors,
            FilledIconButtonTokens.disabledColor,
            FilledIconButtonTokens.disabledOpacity,
          ),
        );
      }
      if (!toggle) {
        return _IconPaint(
          colors.role(FilledIconButtonTokens.containerColor),
          colors.role(FilledIconButtonTokens.color),
        );
      }
      return checked
          ? _IconPaint(
              colors.role(FilledIconButtonTokens.selectedContainerColor),
              colors.role(FilledIconButtonTokens.selectedColor),
            )
          : _IconPaint(
              colors.role(FilledIconButtonTokens.unselectedContainerColor),
              colors.role(FilledIconButtonTokens.unselectedColor),
            );
    case ExpressiveIconButtonKind.filledTonal:
      if (!enabled) {
        return _IconPaint(
          _alpha(
            colors,
            FilledTonalIconButtonTokens.disabledContainerColor,
            FilledTonalIconButtonTokens.disabledContainerOpacity,
          ),
          _alpha(
            colors,
            FilledTonalIconButtonTokens.disabledColor,
            FilledTonalIconButtonTokens.disabledOpacity,
          ),
        );
      }
      if (!toggle) {
        return _IconPaint(
          colors.role(FilledTonalIconButtonTokens.containerColor),
          colors.role(FilledTonalIconButtonTokens.color),
        );
      }
      return checked
          ? _IconPaint(
              colors.role(FilledTonalIconButtonTokens.selectedContainerColor),
              colors.role(FilledTonalIconButtonTokens.selectedColor),
            )
          : _IconPaint(
              colors.role(FilledTonalIconButtonTokens.unselectedContainerColor),
              colors.role(FilledTonalIconButtonTokens.unselectedColor),
            );
    case ExpressiveIconButtonKind.outlined:
      // A checked outlined toggle draws no border
      // (`outlinedIconToggleButtonBorder`), enabled or not.
      final side = toggle && checked
          ? BorderSide.none
          : _outline(colors, ambient, vibrant: vibrant, enabled: enabled);
      if (!enabled) {
        return _IconPaint(
          _transparent,
          (vibrant
                  ? colors.role(OutlinedIconButtonTokens.disabledColor)
                  : ambient)
              .withValues(alpha: OutlinedIconButtonTokens.disabledOpacity),
          side,
        );
      }
      if (toggle && checked) {
        final container = colors.role(
          OutlinedIconButtonTokens.selectedContainerColor,
        );
        return _IconPaint(
          container,
          vibrant
              ? colors.role(OutlinedIconButtonTokens.selectedColor)
              : colors.contentColorFor(container) ?? ambient,
        );
      }
      return _IconPaint(
        _transparent,
        vibrant
            ? colors.role(
                toggle
                    ? OutlinedIconButtonTokens.unselectedColor
                    : OutlinedIconButtonTokens.color,
              )
            : ambient,
        side,
      );
  }
}

/// The ambient content colour (Compose's `LocalContentColor`): the icon
/// colour the surface above sets, or `onSurfaceVariant` where none does.
Color _ambient(BuildContext context, ExpressiveColorScheme colors) =>
    IconTheme.of(context).color ?? colors.onSurfaceVariant;

/// An icon button: a Material Symbols glyph on a pressable of the kind's
/// colours, sized by [size] and [width], its corners springing to the
/// size's pressed shape while pressed.
///
/// Disabled when [onPressed] and [onLongPress] are null. Give it a
/// [semanticLabel]: an icon has no words of its own.
class ExpressiveIconButton extends StatelessWidget {
  /// A standard icon button (Compose `IconButton`): no container, the
  /// lowest emphasis.
  const ExpressiveIconButton(
    this.icon, {
    required this.onPressed,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.vibrant = false,
    this.semanticLabel,
    this.tooltip,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.standard;

  /// A filled icon button: `primary`.
  const ExpressiveIconButton.filled(
    this.icon, {
    required this.onPressed,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.semanticLabel,
    this.tooltip,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.filled,
       vibrant = false;

  /// A tonal icon button (`FilledTonalIconButton`, Flutter's
  /// `IconButton.filledTonal`): `secondaryContainer`.
  const ExpressiveIconButton.filledTonal(
    this.icon, {
    required this.onPressed,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.semanticLabel,
    this.tooltip,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.filledTonal,
       vibrant = false;

  /// An outlined icon button.
  const ExpressiveIconButton.outlined(
    this.icon, {
    required this.onPressed,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.vibrant = false,
    this.semanticLabel,
    this.tooltip,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.outlined;

  /// The glyph: one of [ExpressiveSymbols].
  final IconData icon;

  /// What a tap does; with [onLongPress] null too, the button is disabled.
  final VoidCallback? onPressed;

  /// What a long press does.
  final VoidCallback? onLongPress;

  /// The style its constructor names.
  final ExpressiveIconButtonKind kind;

  /// Stateful visual overrides before the icon-button theme.
  final ExpressiveComponentThemeData? style;

  /// The size: XS–XL. L and XL are hero sizes.
  final ExpressiveIconButtonSize size;

  /// Narrow, uniform or wide.
  final ExpressiveIconButtonWidth width;

  /// Round or square corners at rest.
  final ExpressiveIconButtonShape shape;

  /// Standard and outlined only: the tokens' `onSurfaceVariant` content
  /// (and `outlineVariant` outline) instead of the ambient icon colour
  /// (Compose's `iconButtonVibrantColors`).
  final bool vibrant;

  /// What a screen reader says.
  final String? semanticLabel;

  /// A tooltip message, announced as the button's hint.
  final String? tooltip;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  /// The container an icon button of [size] and [width] draws (Compose's
  /// `IconButtonDefaults.*ContainerSize`), without its 48dp touch target.
  static Size containerSize(
    ExpressiveIconButtonSize size, [
    ExpressiveIconButtonWidth width = ExpressiveIconButtonWidth.uniform,
  ]) => _IconMetrics.of(size).container(width);

  /// The glyph size of [size] (`IconButtonDefaults.*IconSize`).
  static double iconSizeOf(ExpressiveIconButtonSize size) =>
      _IconMetrics.of(size).iconSize;

  @override
  Widget build(BuildContext context) => _IconButtonBody(
    icon: icon,
    kind: kind,
    style: style,
    size: size,
    width: width,
    shape: shape,
    vibrant: vibrant,
    toggle: false,
    checked: false,
    onTap: onPressed,
    onLongPress: onLongPress,
    semanticLabel: semanticLabel,
    tooltip: tooltip,
    focusNode: focusNode,
    autofocus: autofocus,
    debugName: 'ExpressiveIconButton',
  );
}

/// An icon toggle button: on or off, in the kind's checked colours, its
/// corners springing to the size's checked shape and its glyph filling
/// when [value].
///
/// Disabled when [onChanged] is null.
class ExpressiveIconToggleButton extends StatelessWidget {
  /// A standard icon toggle button (`IconToggleButton`) showing [icon], on
  /// when [value].
  const ExpressiveIconToggleButton(
    this.icon, {
    required this.value,
    required this.onChanged,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.vibrant = true,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.standard;

  /// A filled icon toggle button (`FilledIconToggleButton`).
  const ExpressiveIconToggleButton.filled(
    this.icon, {
    required this.value,
    required this.onChanged,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.vibrant = true,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.filled;

  /// A tonal icon toggle button (`FilledTonalIconToggleButton`).
  const ExpressiveIconToggleButton.filledTonal(
    this.icon, {
    required this.value,
    required this.onChanged,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.vibrant = true,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.filledTonal;

  /// An outlined icon toggle button (`OutlinedIconToggleButton`).
  const ExpressiveIconToggleButton.outlined(
    this.icon, {
    required this.value,
    required this.onChanged,
    this.style,
    this.size = ExpressiveIconButtonSize.small,
    this.width = ExpressiveIconButtonWidth.uniform,
    this.shape = ExpressiveIconButtonShape.round,
    this.vibrant = true,
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : kind = ExpressiveIconButtonKind.outlined;

  /// The glyph: one of [ExpressiveSymbols]; drawn filled when [value].
  final IconData icon;

  /// Whether the button is on.
  final bool value;

  /// Told the new value on a tap; null disables the button.
  final ValueChanged<bool>? onChanged;

  /// The style its constructor names.
  final ExpressiveIconButtonKind kind;

  /// Stateful visual overrides before the icon-button theme.
  final ExpressiveComponentThemeData? style;

  /// The size: XS–XL. L and XL are hero sizes.
  final ExpressiveIconButtonSize size;

  /// Narrow, uniform or wide.
  final ExpressiveIconButtonWidth width;

  /// Round or square corners at rest; each checks to the size's selected
  /// shape for it.
  final ExpressiveIconButtonShape shape;

  /// Standard and outlined only: the tokens' colours (Compose's
  /// `iconToggleButtonVibrantColors`, which its toggles' `shapes`
  /// overloads default to) or, false, the ambient icon colour.
  final bool vibrant;

  /// What a screen reader says.
  final String? semanticLabel;

  /// A tooltip message, announced as the button's hint.
  final String? tooltip;

  /// The focus node; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return _IconButtonBody(
      icon: icon,
      kind: kind,
      style: style,
      size: size,
      width: width,
      shape: shape,
      vibrant: vibrant,
      toggle: true,
      checked: value,
      onTap: onChanged == null ? null : () => onChanged(!value),
      onLongPress: null,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      focusNode: focusNode,
      autofocus: autofocus,
      debugName: 'ExpressiveIconToggleButton',
    );
  }
}

/// The one body both icon buttons build (Compose's `IconButtonImpl`,
/// `SurfaceIconButton` and their toggle forms): the pressable, the
/// container size, the glyph centred in it.
class _IconButtonBody extends StatelessWidget {
  const _IconButtonBody({
    required this.icon,
    required this.kind,
    required this.style,
    required this.size,
    required this.width,
    required this.shape,
    required this.vibrant,
    required this.toggle,
    required this.checked,
    required this.onTap,
    required this.onLongPress,
    required this.semanticLabel,
    required this.tooltip,
    required this.focusNode,
    required this.autofocus,
    required this.debugName,
  });

  final IconData icon;
  final ExpressiveIconButtonKind kind;

  /// Stateful visual overrides before the icon-button theme.
  final ExpressiveComponentThemeData? style;
  final ExpressiveIconButtonSize size;
  final ExpressiveIconButtonWidth width;
  final ExpressiveIconButtonShape shape;
  final bool vibrant;
  final bool toggle;
  final bool checked;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;
  final String debugName;

  @override
  Widget build(BuildContext context) {
    if (size.isHero) {
      assert(
        ExpressiveHeroMoment.debugCheck(
          context,
          '$debugName (${size.name.toUpperCase()})',
        ),
      );
    }
    final theme = context.expressiveTheme;
    final metrics = _IconMetrics.of(size);
    final enabled = onTap != null || onLongPress != null;
    final paint =
        _iconPaint(
          theme.colors,
          kind,
          ambient: _ambient(context, theme.colors),
          vibrant: vibrant,
          enabled: enabled,
          toggle: toggle,
          checked: checked,
        ).themed(
          theme.iconButtonTheme,
          expressiveComponentStates(
            enabled: enabled,
            selected: toggle && checked,
          ),
        );
    final round = shape == ExpressiveIconButtonShape.round;
    final shapes = theme.shapes;
    // In a button group the button joins the squish (Compose's ButtonGroup
    // animates any child through `Modifier.animateWidth`, `IconButton`
    // included), and the glyph stays centred in the width the group fixes
    // (the pressable's width probe).
    return ExpressivePressable(
      style: style,
      componentStyle: theme.iconButtonTheme,
      shapes: ExpressivePressShapes(
        shape: shapes.of(round ? metrics.round : metrics.square),
        pressed: shapes.of(metrics.pressed),
        selected: toggle
            ? shapes.of(round ? metrics.selectedRound : metrics.selectedSquare)
            : null,
      ),
      motion: IconButtonBehavior.pressMotion,
      color: paint.container,
      contentColor: paint.content,
      side: paint.side,
      selected: toggle && checked,
      role: toggle ? ExpressivePressRole.toggle : ExpressivePressRole.button,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      onPressed: onTap,
      onLongPress: onLongPress,
      onPressedChanged: ExpressiveButtonGroup.pressedHandlerOf(context),
      focusNode: focusNode,
      autofocus: autofocus,
      child: ExpressiveFillProbedWidth(
        child: ExpressiveStyledContent(
          minimumSize: metrics.container(width),
          iconSize: metrics.iconSize,
          child: ExpressiveIcon(icon, selected: toggle && checked),
        ),
      ),
    );
  }
}
