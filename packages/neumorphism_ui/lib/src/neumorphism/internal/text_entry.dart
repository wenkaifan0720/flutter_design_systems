// The one way Neumorphism uses Flutter's TextField. The look draws the box (its groove, fill, ring, side air and a
// minimum height, the control's), and the editable inside it is bare: exactly its lines tall, placed by alignment. A
// line then stands where the look put it under any configuration: the platform's density, Material 2 or 3, larger
// text, or an app's own InputDecorationTheme between the look and the field. The bare decoration is each field file's
// own (_bareDecoration), so no Material type stands in the look's API.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// [style] as a field's words and hint both take it: even leading, so a line's box is centred on its glyphs.
TextStyle neumorphicEntryStyle(TextStyle style) =>
    style.copyWith(leadingDistribution: TextLeadingDistribution.even);

/// The height one line of [style] takes at the text scale in [context]: the look's styles set a line height, so a
/// line's box is its scaled size times its height.
double neumorphicLineHeight(BuildContext context, TextStyle style) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
    (style.height ?? 1);

/// A glyph of [size] that stands beside words grows with them, up to half again: at twice the text a button's 18 px
/// glyph stood small and lost beside its words.
double neumorphicGlyphBeside(BuildContext context, double size) =>
    size * (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.5);

/// Where a bare editable [child] sits in the look's box: a band [height] tall (the box's control height) with one
/// line centred in it by alignment, or, for [lines] > 1, the first line standing where one line does, (height -
/// [line]) / 2 from the top. A press anywhere in the band off the text focuses [focusNode], so the target is the
/// band, not the line; the band is also the field's one semantics node, named [label].
class NeumorphicEntrySeat extends StatelessWidget {
  /// Seats [child], which is lines tall, in a band [height] tall.
  const NeumorphicEntrySeat({
    super.key,
    required this.height,
    required this.focusNode,
    required this.child,
    this.line = 0,
    this.lines = 1,
    this.enabled = true,
    this.label,
    this.maxLength,
    this.node = true,
  });

  /// Whether the band is the field's semantics node. A one-line field whose node is its reach round the whole box
  /// (NeumorphicReach) says false.
  final bool node;

  /// The box's control height.
  final double height;

  /// The height of one line of the field's words, for [lines] > 1.
  final double line;

  /// How many lines the editable shows.
  final int lines;

  /// The editable's focus, given on a press off the text.
  final FocusNode focusNode;

  /// Whether a press focuses it.
  final bool enabled;

  /// The field's spoken name.
  final String? label;

  /// The most characters it takes, told to a screen reader.
  final int? maxLength;

  /// The bare editable.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final placed = lines > 1
        ? Padding(
            padding: EdgeInsets.symmetric(
              vertical: math.max(0.0, (height - line) / 2),
            ),
            child: child,
          )
        : ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: child,
            ),
          );
    final band = Stack(
      children: [
        // Behind the editable, so a press on the text is the text's (its caret, its selection) and only a press off
        // it lands here.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: enabled ? focusNode.requestFocus : null,
          ),
        ),
        placed,
      ],
    );
    if (!node) return band;
    return Semantics(
      container: true,
      label: label,
      maxValueLength: maxLength,
      child: band,
    );
  }
}
