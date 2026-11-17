/// A list fetched again by a pull from its top, in Ledger's hand, on ui_core's
/// pull to refresh.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';
import '../progress/progress.dart';

/// A list fetched again by a pull from its top (the register's bank feed):
/// as it is pulled, a rule of the ink draws out from the middle in the room
/// opened above the list, reaching the width when a letting go would fetch,
/// and the words under it change from Pull to fetch to Let go to fetch;
/// while [onRefresh] runs the ring turns there with Fetching, then the list
/// settles back. A screen reader offers the fetch as an action and hears
/// when it starts and ends. [child] is the scroll view.
///
/// ```dart
/// LedgerPullToRefresh(onRefresh: () async => fetch(), child: ListView(children: rows))
/// ```
class LedgerPullToRefresh extends StatelessWidget {
  /// [child] fetched again by [onRefresh] on a pull.
  const LedgerPullToRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// Fetches; the indicator stays until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      restExtent: _rest,
      refreshLabel: 'Fetch again',
      refreshingMessage: 'Fetching',
      doneMessage: 'Fetched',
      indicatorBuilder: (context, details) {
        final at = details.progress.clamp(0.0, 1.0);
        final fetching = details.mode == DesignRefreshMode.refresh;
        final armed = details.progress >= 1;
        if (details.extent <= 0) return const SizedBox.shrink();
        return ClipRect(
          child: SizedBox(
            height: details.extent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: LedgerSpacing.s6,
                children: [
                  if (fetching)
                    const LedgerProgressRing(label: 'Fetching', size: 20)
                  else
                    SizedBox(
                      width: _rule * at,
                      height: 2,
                      child: ColoredBox(color: t.textPrimary),
                    ),
                  Text(
                    fetching
                        ? 'FETCHING'
                        : armed
                        ? 'LET GO TO FETCH'
                        : 'PULL TO FETCH',
                    maxLines: 1,
                    style: t.meta.colored(t.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  static const double _rest = 56;
  static const double _rule = 64;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('onRefresh', onRefresh));
  }
}
