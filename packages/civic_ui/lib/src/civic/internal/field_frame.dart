import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'fit_words.dart';
import 'paint.dart';
import 'spring.dart';

/// Lays out a field's parts the way every Civic field and group stands: the
/// label, its hint, the error in words, then the control; with an error,
/// the whole group stands on the inset rule in the error colour, so the
/// eye finds what to fix down the page's edge.
class CivicFieldFrame extends StatelessWidget {
  /// A field's frame.
  const CivicFieldFrame({
    super.key,
    required this.parts,
    this.isPageHeading = false,
    this.isLegend = false,
    this.labelFocuses = false,
    this.control,
  });

  /// What the field's [DesignField] made.
  final DesignFieldParts parts;

  /// Whether the label is the page's heading: a page that asks one
  /// question asks it in the heading, as large as any page's heading
  /// ([CivicPageBody.title]), and a screen reader hears it as one.
  final bool isPageHeading;

  /// Whether the label is a group's legend (a fieldset's, a radio group's):
  /// it stands a size over the labels of the fields under it.
  final bool isLegend;

  /// Whether a press on the label focuses the control (the field gave its
  /// [DesignField] a focus node): the label then shows the click cursor.
  final bool labelFocuses;

  /// What stands under the words; null takes [DesignFieldParts.control].
  final Widget? control;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final labelText = parts.labelText;
    var label = parts.label;
    if (label != null && labelFocuses && parts.enabled) {
      label = MouseRegion(cursor: SystemMouseCursors.click, child: label);
    }
    if (label != null && isPageHeading && labelText != null) {
      // The page's one heading: the size of every page's heading, grown
      // with the text size as theirs are.
      final words = label;
      label = Semantics(
        header: true,
        label: labelText,
        child: LayoutBuilder(
          builder: (context, constraints) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: CivicFitWords.scalerFor(
                context,
                labelText,
                text.headingXL,
                constraints.maxWidth,
              ),
            ),
            child: words,
          ),
        ),
      );
    }
    final helper = parts.helper;
    final error = parts.error;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          DefaultTextStyle(
            // A field's own label is in the body's weight, as the reference
            // style's are: the question over the fields reads first.
            style: isPageHeading
                ? text.headingXL
                : isLegend
                ? text.headingM
                : text.body,
            child: label,
          ),
        if (helper != null) ...[
          if (label != null)
            SizedBox(
              height: isPageHeading
                  ? CivicSpacing.s12
                  : isLegend
                  ? CivicSpacing.s8
                  : CivicSpacing.s4,
            ),
          DefaultTextStyle(style: text.caption, child: helper),
        ],
        if (error != null) ...[
          if (label != null || helper != null)
            const SizedBox(height: CivicSpacing.s8),
          DefaultTextStyle(
            style: text.label.copyWith(color: t.danger),
            child: error,
          ),
        ],
        if (label != null || helper != null || error != null)
          SizedBox(
            height: isPageHeading
                ? CivicSpacing.s20
                : isLegend
                ? CivicSpacing.s16
                : CivicSpacing.s8,
          ),
        control ?? parts.control,
      ],
    );
    return CivicErrorRule(show: parts.hasError, child: column);
  }
}

/// Stands [child] on the inset rule in the error colour while [show]: the
/// rule grows in from the start edge and the child moves aside for it.
class CivicErrorRule extends StatelessWidget {
  /// An error group's rule.
  const CivicErrorRule({super.key, required this.show, required this.child});

  /// Whether the rule shows.
  final bool show;

  /// What stands on it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return CivicSpringValue(
      value: show ? 1 : 0,
      spring: CivicMotion.state,
      child: child,
      builder: (context, v, child) {
        final rule = CivicMetrics.insetRule * v.clamp(0, 1);
        final gap = CivicSpacing.s16 * v.clamp(0, 1);
        return CustomPaint(
          painter: CivicRulePainter(
            width: rule,
            color: t.danger,
            direction: Directionality.of(context),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: rule + gap),
            child: child,
          ),
        );
      },
    );
  }
}

/// Paints the inset rule down the start edge.
class CivicRulePainter extends CustomPainter {
  /// A rule [width] wide in [color] on the [direction]'s start edge.
  CivicRulePainter({
    required this.width,
    required this.color,
    required this.direction,
  });

  /// The rule's width.
  final double width;

  /// Its colour.
  final Color color;

  /// The reading direction, which says where the start edge is.
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0) return;
    final x = direction == TextDirection.rtl ? size.width - width : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, width, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(CivicRulePainter old) =>
      old.width != width || old.color != color || old.direction != direction;
}
