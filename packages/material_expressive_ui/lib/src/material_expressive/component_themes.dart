/// Expressive's component themes, as Material's are: per-part colours an
/// app sets once on [ExpressiveThemeData] (`copyWith(buttonTheme: …)`)
/// instead of at every call. Each slot is a [WidgetStateProperty]: it
/// resolves for the states the part is in ([WidgetState.disabled],
/// [WidgetState.selected], [WidgetState.dragged], [WidgetState.focused] and
/// [WidgetState.error] where the part has them) and falls back to the part's own Compose
/// default when it, or what it resolves to, is null. Hover, focus and press
/// still draw their state layers over what the slots give, as Compose's
/// ripple draws over a component's colours.
///
/// What each slot paints, per part:
///
/// | part | [ExpressiveComponentThemeData.backgroundColor] | [ExpressiveComponentThemeData.foregroundColor] | [ExpressiveComponentThemeData.outline] |
/// |---|---|---|---|
/// | button, toggle button | the container | the label and icon | the outline, where the style draws one |
/// | icon button, icon toggle button | the container | the icon | the outline, where the style draws one |
/// | segmented button | a segment's container | a segment's label and icon | a segment's outline, where the style draws one |
/// | chip | the container | the label and icons | the outline, where the chip draws one |
/// | list tile | the row (a row's own `containerColor` wins) | every word and icon on it | (none) |
/// | app bar | the bar ([WidgetState.scrolledUnder] once content passes under it) | the title, the subtitle and the icons | (none) |
/// | menu | the menu's surface, and a selected item's container (resolved with [WidgetState.selected]) | the group labels, an item's label and icons | (none) |
/// | snackbar | the bar | the message and the close icon (the action keeps `inversePrimary`) | (none) |
/// | alert dialog | the dialog | the title and the body (the hero icon keeps `secondary`) | (none) |
/// | text field | the container (outlined fields have none until given one) | the input, label, placeholder, icons and affixes | the indicator line or the outline (the tonal filled field draws none) |
///
/// A toggle button's own `colors:` wins over its theme, as a Material
/// widget's `style:` wins over its component theme; a danger button keeps
/// its error tones.
///
/// ```dart
/// final data = ExpressiveThemeData.preset('baseline', Brightness.light)
///     .copyWith(
///       chipTheme: ExpressiveComponentThemeData(
///         backgroundColor: WidgetStateProperty.resolveWith(
///           (states) => states.contains(WidgetState.selected)
///               ? const Color(0xFFFFD8E4)
///               : null,
///         ),
///       ),
///     );
/// ```
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A component style with stateful visual slots, resolved before the look's tokens.
///
/// ```dart
/// const style = ExpressiveComponentThemeData(
///   backgroundColor: WidgetStatePropertyAll(Color(0xff6750a4)),
///   shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
/// );
/// ```
@immutable
class ExpressiveComponentThemeData with Diagnosticable {
  /// Unset slots preserve the component's existing appearance.
  const ExpressiveComponentThemeData({
    this.backgroundColor,
    this.foregroundColor,
    this.outline,
    this.overlayColor,
    this.side,
    this.shape,
    this.padding,
    this.minimumSize,
    this.textStyle,
    this.iconSize,
  });

  /// The container colour, as `ButtonStyle.backgroundColor`.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// The content colour (label, icons), as `ButtonStyle.foregroundColor`.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// The outline colour when no explicit side is supplied.
  final WidgetStateProperty<Color?>? outline;

  /// The state layer's colour (hover, focus, press), as
  /// `ButtonStyle.overlayColor`.
  final WidgetStateProperty<Color?>? overlayColor;

  /// The outline stroke.
  final WidgetStateProperty<BorderSide?>? side;

  /// The outline; any Flutter OutlinedBorder is accepted.
  final WidgetStateProperty<OutlinedBorder?>? shape;

  /// The foregroundColor padding before the outline safe inset.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// The minimum visual size; touch targets retain their floor.
  final WidgetStateProperty<Size?>? minimumSize;

  /// The foregroundColor text style.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// The foregroundColor icon size.
  final WidgetStateProperty<double?>? iconSize;

  /// Whether every slot is unset.
  bool get isEmpty =>
      backgroundColor == null &&
      foregroundColor == null &&
      outline == null &&
      overlayColor == null &&
      side == null &&
      shape == null &&
      padding == null &&
      minimumSize == null &&
      textStyle == null &&
      iconSize == null;

  /// A colour slot for the states, falling through when it resolves to null.
  static Color resolve(
    WidgetStateProperty<Color?>? slot,
    Set<WidgetState> states,
    Color fallback,
  ) => slot?.resolve(states) ?? fallback;

  /// This style with supplied slots replaced.
  ExpressiveComponentThemeData copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? outline,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<double?>? iconSize,
  }) => ExpressiveComponentThemeData(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    outline: outline ?? this.outline,
    overlayColor: overlayColor ?? this.overlayColor,
    side: side ?? this.side,
    shape: shape ?? this.shape,
    padding: padding ?? this.padding,
    minimumSize: minimumSize ?? this.minimumSize,
    textStyle: textStyle ?? this.textStyle,
    iconSize: iconSize ?? this.iconSize,
  );

  /// [other] has precedence; slots that resolve to null fall through to this style.
  ExpressiveComponentThemeData merge(ExpressiveComponentThemeData? other) {
    if (other == null) return this;
    WidgetStateProperty<T?>? mergeSlot<T>(
      WidgetStateProperty<T?>? base,
      WidgetStateProperty<T?>? top,
    ) => top == null
        ? base
        : base == null
        ? top
        : WidgetStateProperty.resolveWith(
            (states) => top.resolve(states) ?? base.resolve(states),
          );
    return ExpressiveComponentThemeData(
      backgroundColor: mergeSlot(backgroundColor, other.backgroundColor),
      foregroundColor: mergeSlot(foregroundColor, other.foregroundColor),
      outline: mergeSlot(outline, other.outline),
      overlayColor: mergeSlot(overlayColor, other.overlayColor),
      side: mergeSlot(side, other.side),
      shape: mergeSlot(shape, other.shape),
      padding: mergeSlot(padding, other.padding),
      minimumSize: mergeSlot(minimumSize, other.minimumSize),
      textStyle: mergeSlot(textStyle, other.textStyle),
      iconSize: mergeSlot(iconSize, other.iconSize),
    );
  }

  /// Interpolates each stateful slot as Flutter's ButtonStyle does.
  static ExpressiveComponentThemeData lerp(
    ExpressiveComponentThemeData a,
    ExpressiveComponentThemeData b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return ExpressiveComponentThemeData(
      backgroundColor: WidgetStateProperty.lerp<Color?>(
        a.backgroundColor,
        b.backgroundColor,
        t,
        Color.lerp,
      ),
      foregroundColor: WidgetStateProperty.lerp<Color?>(
        a.foregroundColor,
        b.foregroundColor,
        t,
        Color.lerp,
      ),
      outline: WidgetStateProperty.lerp<Color?>(
        a.outline,
        b.outline,
        t,
        Color.lerp,
      ),
      overlayColor: WidgetStateProperty.lerp<Color?>(
        a.overlayColor,
        b.overlayColor,
        t,
        Color.lerp,
      ),
      side: WidgetStateProperty.lerp<BorderSide?>(
        a.side,
        b.side,
        t,
        (a, b, t) => a == null || b == null
            ? (t < .5 ? a : b)
            : BorderSide.lerp(a, b, t),
      ),
      shape: WidgetStateProperty.lerp<OutlinedBorder?>(
        a.shape,
        b.shape,
        t,
        (a, b, t) => ShapeBorder.lerp(a, b, t) as OutlinedBorder?,
      ),
      padding: WidgetStateProperty.lerp<EdgeInsetsGeometry?>(
        a.padding,
        b.padding,
        t,
        EdgeInsetsGeometry.lerp,
      ),
      minimumSize: WidgetStateProperty.lerp<Size?>(
        a.minimumSize,
        b.minimumSize,
        t,
        Size.lerp,
      ),
      textStyle: WidgetStateProperty.lerp<TextStyle?>(
        a.textStyle,
        b.textStyle,
        t,
        TextStyle.lerp,
      ),
      iconSize: WidgetStateProperty.lerp<double?>(
        a.iconSize,
        b.iconSize,
        t,
        lerpDouble,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpressiveComponentThemeData &&
          other.backgroundColor == backgroundColor &&
          other.foregroundColor == foregroundColor &&
          other.outline == outline &&
          other.overlayColor == overlayColor &&
          other.side == side &&
          other.shape == shape &&
          other.padding == padding &&
          other.minimumSize == minimumSize &&
          other.textStyle == textStyle &&
          other.iconSize == iconSize;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    foregroundColor,
    outline,
    overlayColor,
    side,
    shape,
    padding,
    minimumSize,
    textStyle,
    iconSize,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'backgroundColor',
        backgroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'foregroundColor',
        foregroundColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'outline',
        outline,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Color?>>(
        'overlayColor',
        overlayColor,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<BorderSide?>>(
        'side',
        side,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<OutlinedBorder?>>(
        'shape',
        shape,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<EdgeInsetsGeometry?>>(
        'padding',
        padding,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<Size?>>(
        'minimumSize',
        minimumSize,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<TextStyle?>>(
        'textStyle',
        textStyle,
        defaultValue: null,
      ),
    );
    properties.add(
      DiagnosticsProperty<WidgetStateProperty<double?>>(
        'iconSize',
        iconSize,
        defaultValue: null,
      ),
    );
  }
}

/// The states a part is in, for its component theme.
Set<WidgetState> expressiveComponentStates({
  bool enabled = true,
  bool selected = false,
  bool focused = false,
  bool error = false,
}) => <WidgetState>{
  if (!enabled) WidgetState.disabled,
  if (selected) WidgetState.selected,
  if (focused) WidgetState.focused,
  if (error) WidgetState.error,
};
