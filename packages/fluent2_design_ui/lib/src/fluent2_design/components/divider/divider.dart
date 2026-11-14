import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../internal/well.dart';
import '../../theme.dart';

/// A divider's weight, Fluent's `appearance`: [standard] (Fluent's
/// `default`) the second stroke under the second ink, [subtle] the third
/// stroke and ink, [brand] the brand's stroke and ink, [strong] the first.
enum Fluent2DividerAppearance {
  /// The standard rule.
  standard,

  /// A fainter rule.
  subtle,

  /// A rule in the brand colour.
  brand,

  /// A stronger rule.
  strong,
}

/// Where a divider's words stand, Fluent's `alignContent`: [start] 8 from
/// the line's start, [center], [end] 8 from its end.
enum Fluent2DividerAlign {
  /// Its words at the rule's start.
  start,

  /// Its words in the middle.
  center,

  /// Its words at the rule's end.
  end,
}

/// Fluent 2's Divider: a 1 hairline separating content, across
/// ([vertical] false) or down, optionally with [label] in caption1 set in
/// it 12 from the lines either side, at [align]; [inset] keeps 12 off its
/// ends. A vertical one is 20 tall at least (84 with words). A divider is a
/// separator, not an edge a control is read by: its strokes are Fluent's
/// own (`neutralStroke2` by default), its words held at 4.5:1. Read as its
/// words, or as nothing.
///
/// ```dart
/// Fluent2Divider(label: 'Yesterday')
/// ```
class Fluent2Divider extends StatelessWidget {
  /// A divider, with words in its middle when given.
  const Fluent2Divider({
    this.label,
    this.vertical = false,
    this.align = Fluent2DividerAlign.center,
    this.appearance = Fluent2DividerAppearance.standard,
    this.inset = false,
    super.key,
  });

  /// The words in the line (an "or", a day).
  final String? label;

  /// Whether it runs up and down rather than across.
  final bool vertical;

  /// Fluent's `alignContent`: where its words stand along it.
  final Fluent2DividerAlign align;

  /// Fluent's `appearance`: the rule's strength.
  final Fluent2DividerAppearance appearance;

  /// Keeps 12 off the line's two ends.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final (Color stroke, Color ink) = switch (appearance) {
      Fluent2DividerAppearance.standard => (
        c.neutralStroke2,
        c.neutralForeground2,
      ),
      Fluent2DividerAppearance.subtle => (
        c.neutralStroke3,
        c.neutralForeground3,
      ),
      Fluent2DividerAppearance.brand => (c.brandStroke1, c.brandForeground1),
      Fluent2DividerAppearance.strong => (
        c.neutralStroke1,
        c.neutralForeground1,
      ),
    };
    // Fluent's greys as steps over the ground, so the subtle rule shows and
    // the strong one stands darker on the brand-tinted page too.
    final line = ColoredBox(color: fluent2Step(t, stroke));
    final label = this.label;
    const end = 8.0;
    const gap = Fluent2Spacing.m;
    if (!vertical) {
      final rule = SizedBox(height: 1, child: line);
      final Widget body;
      if (label == null) {
        body = rule;
      } else {
        final words = Padding(
          padding: const EdgeInsets.symmetric(horizontal: gap),
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: t.caption1.c(ink),
          ),
        );
        // The words take their own width (at most the row less the two
        // short ends) and the lines share what is left, so a centred label
        // sits in the middle and the lines reach both edges.
        body = LayoutBuilder(
          builder: (context, box) {
            final most = box.maxWidth.isFinite
                ? math.max(0.0, box.maxWidth - 2 * end)
                : double.infinity;
            final held = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: most),
              child: words,
            );
            return Row(
              children: switch (align) {
                Fluent2DividerAlign.start => [
                  SizedBox(width: end, child: rule),
                  held,
                  Expanded(child: rule),
                ],
                Fluent2DividerAlign.center => [
                  Expanded(child: rule),
                  held,
                  Expanded(child: rule),
                ],
                Fluent2DividerAlign.end => [
                  Expanded(child: rule),
                  held,
                  SizedBox(width: end, child: rule),
                ],
              },
            );
          },
        );
      }
      return Semantics(
        container: label != null,
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset ? gap : 0),
          child: body,
        ),
      );
    }
    final rule = SizedBox(width: 1, child: line);
    final Widget body;
    if (label == null) {
      body = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 20),
        child: SizedBox(width: 1, child: line),
      );
    } else {
      final words = Padding(
        padding: const EdgeInsets.symmetric(vertical: gap),
        child: Text(label, maxLines: 1, style: t.caption1.c(ink)),
      );
      body = LayoutBuilder(
        builder: (context, box) {
          // In a bounded column the lines share its height; unbounded,
          // they take Fluent's least (84 with the words).
          Widget long() => box.maxHeight.isFinite
              ? Expanded(child: rule)
              : SizedBox(height: 22, child: rule);
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Column(
              mainAxisSize: box.maxHeight.isFinite
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: switch (align) {
                Fluent2DividerAlign.start => [
                  SizedBox(height: end, child: rule),
                  words,
                  long(),
                ],
                Fluent2DividerAlign.center => [long(), words, long()],
                Fluent2DividerAlign.end => [
                  long(),
                  words,
                  SizedBox(height: end, child: rule),
                ],
              },
            ),
          );
        },
      );
    }
    return Semantics(
      container: label != null,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: inset ? gap : 0),
        child: body,
      ),
    );
  }
}
