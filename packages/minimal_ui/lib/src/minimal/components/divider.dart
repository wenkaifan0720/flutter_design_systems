/// A hairline between two runs of content.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A hairline that separates — two groups of fields, a toolbar's halves, a
/// menu's sections: one `t.hairline` in the border colour, across
/// the available width (or down the available height with
/// [MinimalDivider.vertical]), with [indent] and [endIndent] at its ends.
/// With a [label] it breaks in the middle for the words ("or"), quiet and
/// small. Minimal's rows draw their own rules; reach for this between
/// things that are not rows.
///
/// ```dart
/// MinimalDivider(label: 'or')
/// ```
class MinimalDivider extends StatelessWidget {
  /// A hairline.
  const MinimalDivider({
    super.key,
    this.label,
    this.indent = 0,
    this.endIndent = 0,
    this.space = MinimalSpacing.s16,
  }) : vertical = false;

  /// A rule down the available height, for a row of controls.
  const MinimalDivider.vertical({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.space = MinimalSpacing.s16,
  }) : vertical = true,
       label = null;

  /// Words the rule breaks for, in the middle.
  final String? label;

  /// Space before it.
  final double indent;

  /// Space after it.
  final double endIndent;

  /// The extent it takes across its line, the rule in the middle.
  final double space;

  /// Whether it runs top to bottom.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final rule = ColoredBox(color: t.border);
    if (vertical) {
      return Semantics(
        // A rule says nothing to a screen reader.
        excludeSemantics: true,
        child: SizedBox(
          width: space,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: indent, bottom: endIndent),
              // The height it stands in; none where that is unbounded.
              child: LimitedBox(
                maxHeight: 0,
                child: SizedBox(
                  width: t.hairline,
                  height: double.infinity,
                  child: rule,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final words = label;
    final line = SizedBox(height: t.hairline, child: rule);
    if (words == null) {
      return ExcludeSemantics(
        child: SizedBox(
          height: space,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
            child: Row(children: [Expanded(child: line)]),
          ),
        ),
      );
    }
    // The words keep a 24 px stretch of rule on each side; past that (large
    // text, a narrow column) they wrap, and the divider grows to hold them.
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: space),
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                Expanded(child: line),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(
                      0,
                      box.maxWidth - 2 * MinimalSpacing.s24,
                    ),
                  ),
                  child: Padding(
                    padding: MinimalInsets.horizontal12,
                    child: Text(
                      words,
                      textAlign: TextAlign.center,
                      style: t.caption.c(t.textTertiary),
                    ),
                  ),
                ),
                Expanded(child: line),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
