import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/footer_band.dart';
import '../../theme.dart';
import '../button/button.dart';

/// A page's commit strip: what is about to happen on the leading side (a
/// total in the engraved serif, over its line in the mono) and the page's one
/// act on the trailing side, the green button. Stood as a
/// `LedgerScreen(footer:)` it leaves the band's hairline and room to the
/// screen; anywhere else it stands its own band on the paper (a hairline over
/// it, the gutter at its sides, the device's inset under), and with
/// [floating] it is a card of the raised paper that keeps a body's edges.
/// Without a summary the act takes the whole width. At large text, or in a
/// room narrower than [stackBelow], the summary stacks over the act rather
/// than squeezing it. A busy act shows [busyLabel] and takes no press.
///
/// ```dart
/// LedgerActionBar(summary: '\$1,240.00', detail: 'Due Nov 1', label: 'Pay now', onTap: pay)
/// ```
class LedgerActionBar extends StatelessWidget {
  /// A commit strip: what will happen, and the act that does it.
  const LedgerActionBar({
    this.label = '',
    this.summary,
    this.detail,
    this.summaryContent,
    this.action,
    this.onTap,
    this.icon,
    this.busy = false,
    this.busyLabel = 'Working…',
    this.floating = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The act's words.
  final String label;

  /// The figure on the leading side (a total, a count), in the serif.
  final String? summary;

  /// The line under it, in the mono capitals.
  final String? detail;

  /// A composed summary in place of [summary] and [detail].
  final Widget? summaryContent;

  /// A composed act in place of the built-in button.
  final Widget? action;

  /// What the act does; null disables it.
  final VoidCallback? onTap;

  /// The built-in button's focus; null keeps one of its own. The caller
  /// disposes the node it gives.
  final FocusNode? focusNode;

  /// Whether the built-in button takes focus when it first appears.
  final bool autofocus;

  /// A glyph before the act's words.
  final IconData? icon;

  /// Whether the act is working: it shows [busyLabel] and takes no press.
  final bool busy;

  /// The act's words while it is busy.
  final String busyLabel;

  /// Whether it stands as a card of its own rather than a band.
  final bool floating;

  /// The room under which the summary stacks over the act.
  static const double stackBelow = 320;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final summary = summaryContent ?? _summary(context);
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= _bigText ||
        MediaQuery.sizeOf(context).width < stackBelow;
    final button =
        action ??
        LedgerButton.filled(
          busy ? busyLabel : label,
          onPressed: busy ? null : onTap,
          icon: icon,
          focusNode: focusNode,
          autofocus: autofocus,
          expand: summary == null || stacked,
        );
    final row = summary == null
        ? button
        : stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: _gap,
            children: [summary, button],
          )
        : Row(
            spacing: _gap,
            children: [
              Expanded(child: summary),
              button,
            ],
          );
    if (LedgerFooterBand.around(context)) return row;
    final mq = MediaQuery.of(context);
    return LedgerBottomStand(
      child: floating
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(t.cardRadius),
                border: Border.all(color: t.border),
                boxShadow: t.paperShadow,
              ),
              child: Padding(padding: const EdgeInsets.all(_card), child: row),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: t.background,
                border: Border(top: BorderSide(color: t.hairline)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  LedgerChromeMetrics.gutter,
                  LedgerChromeMetrics.footerTop,
                  LedgerChromeMetrics.gutter,
                  math.max(LedgerChromeMetrics.footerFoot, mq.padding.bottom),
                ),
                child: row,
              ),
            ),
    );
  }

  Widget? _summary(BuildContext context) {
    final t = context.ledgerTheme;
    final figure = summary;
    final line = detail;
    if (figure == null && line == null) return null;
    return Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (figure != null)
            Text(
              figure,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.figureSmall.colored(t.textPrimary),
            ),
          if (line != null)
            Text(
              line.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.meta.colored(t.textTertiary),
            ),
        ],
      ),
    );
  }

  // DERIVED (the source stands its acts in the page): the summary and the act
  // 16 apart, a floating card padded 16, the text scale at which it stacks.
  static const double _gap = 16;
  static const double _card = 16;
  static const double _bigText = 1.3;
}
