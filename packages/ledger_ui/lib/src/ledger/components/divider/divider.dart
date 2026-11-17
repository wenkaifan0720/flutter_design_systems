/// The rules a ledger draws between its parts.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';

/// A rule between parts of a page: the hairline between rows, [strong] the
/// ink rule under a head, [total] the accountant's double rule over a sum.
/// With a [label] the rule breaks for it at the reading start, the words in
/// the mono capitals (OCTOBER, EARLIER), and a screen reader hears them as a
/// heading; without, it says nothing. [vertical] stands it upright between
/// columns, as tall as its row.
///
/// ```dart
/// LedgerDivider(label: 'Earlier')
/// ```
class LedgerDivider extends StatelessWidget {
  /// A hairline rule, broken for [label] when given.
  const LedgerDivider({
    this.label,
    this.strong = false,
    this.total = false,
    this.vertical = false,
    super.key,
  }) : assert(!(vertical && label != null));

  /// The words the rule breaks for.
  final String? label;

  /// Whether it is the ink rule.
  final bool strong;

  /// Whether it is the double rule over a sum.
  final bool total;

  /// Whether it stands upright between columns.
  final bool vertical;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('strong', value: strong, ifTrue: 'strong'))
      ..add(FlagProperty('total', value: total, ifTrue: 'total'))
      ..add(FlagProperty('vertical', value: vertical, ifTrue: 'vertical'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final ink = strong || total ? t.headRule : t.hairline;
    if (vertical) {
      return ExcludeSemantics(
        child: SizedBox(width: 1, child: ColoredBox(color: ink)),
      );
    }
    final rule = total
        ? Column(
            mainAxisSize: MainAxisSize.min,
            spacing: LedgerChromeMetrics.focusGap,
            children: [
              for (var i = 0; i < 2; i++)
                SizedBox(
                  height: 1,
                  width: double.infinity,
                  child: ColoredBox(color: ink),
                ),
            ],
          )
        : SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: ink),
          );
    final words = label;
    if (words == null) return ExcludeSemantics(child: rule);
    return Semantics(
      header: true,
      label: words,
      excludeSemantics: true,
      child: Row(
        spacing: LedgerSpacing.s12,
        children: [
          Text(words.toUpperCase(), style: t.meta.colored(t.textSecondary)),
          Expanded(child: rule),
        ],
      ),
    );
  }
}
