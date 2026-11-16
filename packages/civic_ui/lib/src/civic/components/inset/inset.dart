import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/field_frame.dart';
import '../../internal/paint.dart';
import '../../theme.dart';

/// Words set apart on the inset rule: a quotation, an example, a thing to
/// know before going on. No box, no fill: the rule down the start edge (in
/// the secondary words' colour, so it never fades from the page) says "this
/// aside", and the words keep the page's colour.
///
/// Reads [CivicStyle]'s edge (the rule), foreground and textStyle (the
/// words): its `style:`, then [CivicThemeData.insetStyle]. The rule's width
/// is the look's.
///
/// ```dart
/// const CivicInset(child: Text('It can take up to 5 working days to decide.'))
/// ```
class CivicInset extends StatelessWidget {
  /// Words on the inset rule.
  const CivicInset({super.key, required this.child, this.style});

  /// The words.
  final Widget child;

  /// Overrides for this inset's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf([style, t.insetStyle], const {});
    return CustomPaint(
      painter: CivicRulePainter(
        width: CivicMetrics.insetRule,
        color: so.edge ?? t.textSecondary,
        direction: Directionality.of(context),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: CivicMetrics.insetRule + CivicSpacing.s16,
          top: CivicSpacing.s8,
          bottom: CivicSpacing.s8,
        ),
        child: DefaultTextStyle(
          style: context.civicText.body
              .merge(so.textStyle)
              .copyWith(color: so.foreground),
          child: child,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
    );
  }
}

/// A warning: the round mark with its exclamation in ink, the words in
/// bold beside it. For what could cost the reader (a fine, a refused
/// application), said once on a page. The mark is hidden from a screen
/// reader, which hears [assistiveLabel] before the words instead.
///
/// Reads [CivicStyle]'s fill (the mark), foreground and textStyle (the
/// words): its `style:`, then [CivicThemeData.insetStyle].
///
/// ```dart
/// const CivicWarning(
///   assistiveLabel: 'Warning',
///   child: Text('You can be fined up to 80 crowns if you park without a permit.'),
/// )
/// ```
class CivicWarning extends StatelessWidget {
  /// A warning.
  const CivicWarning({
    super.key,
    required this.child,
    required this.assistiveLabel,
    this.style,
  });

  /// The words.
  final Widget child;

  /// What a screen reader hears before the words: Warning.
  final String assistiveLabel;

  /// Overrides for this warning's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.insetStyle], const {});
    final mark = so.fill ?? t.textPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CivicSpacing.s16,
      children: [
        ExcludeSemantics(
          child: Container(
            width: _mark,
            height: _mark,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: mark, shape: BoxShape.circle),
            child: Text(
              '!',
              style: text.headingM.copyWith(
                color:
                    CivicThemeData.contrastRatio(mark, t.background) >=
                        CivicThemeData.contrastRatio(mark, t.textPrimary)
                    ? t.background
                    : t.textPrimary,
                height: 1,
              ),
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            label: assistiveLabel,
            child: DefaultTextStyle(
              style: text.label
                  .merge(so.textStyle)
                  .copyWith(color: so.foreground),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('assistiveLabel', assistiveLabel))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }

  static const double _mark = 36;
}
