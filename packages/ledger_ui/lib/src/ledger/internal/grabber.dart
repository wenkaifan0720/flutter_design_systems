import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// The grip at the top of a phone sheet (`.grip`): a 36 by 4 bar in the
/// faint ink, 8 under the sheet's top. The desktop's dialog has none.
/// Plumbing of the sheet.
class LedgerGrabber extends StatelessWidget {
  /// The grip at a phone sheet's top.
  const LedgerGrabber({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: LedgerChromeMetrics.gripTop),
    child: Center(
      child: ExcludeSemantics(
        child: Container(
          width: LedgerChromeMetrics.gripWidth,
          height: LedgerChromeMetrics.gripHeight,
          decoration: BoxDecoration(
            color: context.ledgerTheme.textFaint,
            borderRadius: BorderRadius.circular(LedgerCorners.rFull),
          ),
        ),
      ),
    ),
  );
}
