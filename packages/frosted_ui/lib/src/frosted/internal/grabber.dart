import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// The grabber at a phone sheet's top: 36 by 4, centred, 12 over the
/// sheet's head. A desktop dialog drops it. Plumbing of the components;
/// pages never place one.
class FrostedGrabber extends StatelessWidget {
  /// Creates a [FrostedGrabber].
  const FrostedGrabber({super.key});

  // The open hand over its band under a pointer: the sheet drags down by it.
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.grab,
    child: Padding(
      padding: const EdgeInsets.only(bottom: FrostedChromeMetrics.grabberGap),
      child: Center(
        child: ExcludeSemantics(
          child: Container(
            width: FrostedChromeMetrics.grabberWidth,
            height: FrostedChromeMetrics.grabberHeight,
            decoration: BoxDecoration(
              color: context.frostedTheme.glass.grabber,
              borderRadius: BorderRadius.circular(FrostedCorners.r2),
            ),
          ),
        ),
      ),
    ),
  );
}
