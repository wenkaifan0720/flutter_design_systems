import 'package:material_ui/material_ui.dart';

/// The one way Minimal uses Flutter's `TextField`: the look draws the box
/// (its rim, fill, ring, side air and a minimum height from a control's
/// height), and the editable inside it is bare, exactly one line of text
/// tall, placed by alignment. A line then stands where the look put it under
/// any configuration: the platform's density, Material 2 or 3, larger text,
/// or an app's own `InputDecorationTheme` between the look and the field.
///
/// A collapsed decoration with every field that could size or draw it set
/// here, so no theme default reaches it: no padding, no borders, no fill,
/// standard density (a collapsed decorator nets the density's offset to zero
/// only when it is negative) and no constraints (an unset one takes the
/// theme's). Icons, buttons, add-ons, counters, help and error are the
/// look's own widgets beside or under the box, never the decoration's.
///
/// [hintMaxLines] caps the hint's lines. A one-line box gives 1: Flutter keeps
/// the box at the hint's height once text is typed, so a hint that wraps would
/// hold the box at two lines and leave the typed line at its top.
InputDecoration minimalBareDecoration({
  String? hint,
  TextStyle? hintStyle,
  int? hintMaxLines,
}) => InputDecoration(
  isCollapsed: true,
  isDense: false,
  contentPadding: EdgeInsets.zero,
  hintText: hint,
  hintStyle: hintStyle,
  hintMaxLines: hintMaxLines,
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
  visualDensity: VisualDensity.standard,
  constraints: const BoxConstraints(),
);

/// The height one line of [style] takes at the text scale in [context]: the
/// look's styles set a line height and even leading, so a line's box is its
/// scaled size times its height.
double minimalLineHeight(BuildContext context, TextStyle style) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
    (style.height ?? 1);

/// The air above and below a field's text inside its rims so that a first
/// line of [line] stands where a single line does in a box [height] tall
/// with [rim]s: half of what the line leaves, never under [least]. One line
/// in such a box is centred by alignment; this places the first of several.
double minimalLineAir({
  required double height,
  required double rim,
  required double line,
  double least = 0,
}) {
  final air = (height - line) / 2 - rim;
  return air < least ? least : air;
}
