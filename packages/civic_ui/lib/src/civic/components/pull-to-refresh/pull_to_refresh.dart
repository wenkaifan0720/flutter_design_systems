import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/spinner_arc.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A list a finger pulls down to fetch again: [child], a scroll view, and
/// over its top a band the pull opens, its ring filling as the pull goes,
/// then "Refresh" once letting go will refresh, then the ring turning and
/// "Refreshing" while [onRefresh] runs, the list moved down under the band
/// so none of it is hidden, then "Refreshed" as the band closes and the
/// list comes back up, both on Civic's panel spring. A screen reader gets a "Refresh" action on the list and hears
/// when it starts and when it is done.
///
/// A pull is a shortcut nobody can see: the page also offers a "Refresh"
/// button (or says when it was last brought up to date and refreshes on
/// its own). The button calls [CivicPullToRefreshState.refresh], through a
/// `GlobalKey<CivicPullToRefreshState>`, so the band says it the same way.
///
/// Reads [CivicStyle]'s fill (the band), foreground (the ring) and
/// textStyle (the words): its `style:`, then
/// [CivicThemeData.pullToRefreshStyle].
///
/// ```dart
/// CivicPullToRefresh(
///   onRefresh: fetchApplications,
///   child: ListView(children: rows),
/// )
/// ```
class CivicPullToRefresh extends StatefulWidget {
  /// A refresher round [child].
  const CivicPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.refreshLabel,
    this.refreshingMessage,
    this.doneMessage,
    this.style,
  });

  /// Fetches again; the band stays until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  /// The words once letting go will refresh, and the screen reader's
  /// action; null: "Refresh" in the reader's language.
  final String? refreshLabel;

  /// The words while it refreshes; null: "Refreshing".
  final String? refreshingMessage;

  /// The words once it is done; null: "Refreshed".
  final String? doneMessage;

  /// Overrides for this refresher's look.
  final CivicStyle? style;

  /// How tall the band stands while it refreshes, at a text size of 1.
  static const double band = 56;

  @override
  State<CivicPullToRefresh> createState() => CivicPullToRefreshState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<Future<void> Function()>.has('onRefresh', onRefresh),
      )
      ..add(StringProperty('refreshLabel', refreshLabel, defaultValue: null))
      ..add(
        StringProperty(
          'refreshingMessage',
          refreshingMessage,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('doneMessage', doneMessage, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// A [CivicPullToRefresh]'s state: [refresh] runs a refresh as a pull
/// would.
class CivicPullToRefreshState extends State<CivicPullToRefresh> {
  final _inner = GlobalKey<RawRefreshIndicatorState>();
  var _refreshing = false;

  // Moves the list down under the band while the refresh runs.
  Future<void> _run() async {
    if (mounted) setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// Opens the band and runs [CivicPullToRefresh.onRefresh], as a pull
  /// let go past the trigger does; completes when it is done.
  Future<void> refresh() async => _inner.currentState?.refresh();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([widget.style, t.pullToRefreshStyle], const {});
    final l = RawWidgetsLocalizations.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final rest = scaler
        .scale(CivicPullToRefresh.band)
        .clamp(CivicPullToRefresh.band, CivicPullToRefresh.band * 2);
    return RawRefreshIndicator(
      key: _inner,
      onRefresh: _run,
      restExtent: rest,
      triggerDistance: rest * 1.4,
      refreshLabel: widget.refreshLabel,
      refreshingMessage: widget.refreshingMessage,
      doneMessage: widget.doneMessage,
      child: CivicSpringValue(
        value: _refreshing ? rest : 0,
        spring: CivicMotion.panel,
        child: widget.child,
        builder: (context, down, list) => Padding(
          padding: EdgeInsets.only(top: down < 0 ? 0 : down),
          child: list,
        ),
      ),
      indicatorBuilder: (context, pull) {
        if (pull.extent <= 0) return const SizedBox.shrink();
        final words = switch (pull.mode) {
          RawRefreshIndicatorMode.inactive ||
          RawRefreshIndicatorMode.drag => null,
          RawRefreshIndicatorMode.armed =>
            widget.refreshLabel ?? l.refreshLabel,
          RawRefreshIndicatorMode.refresh =>
            widget.refreshingMessage ?? l.refreshingMessage,
          RawRefreshIndicatorMode.done =>
            widget.doneMessage ?? l.refreshedMessage,
        };
        final turning = pull.mode == RawRefreshIndicatorMode.refresh;
        // The screen reader hears the refresher's own messages.
        return ExcludeSemantics(
          child: SizedBox(
            height: pull.extent,
            child: ClipRect(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: so.fill ?? t.surface,
                  border: Border(bottom: BorderSide(color: t.rule)),
                ),
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: rest,
                  maxHeight: rest,
                  child: Opacity(
                    opacity: (pull.extent / rest).clamp(0.0, 1.0),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: CivicSpacing.s12,
                        children: [
                          if (pull.mode != RawRefreshIndicatorMode.done)
                            CivicSpinnerArc(
                              size: scaler.scale(20),
                              color: so.foreground ?? t.action,
                              ring: t.rule,
                              filled: turning
                                  ? null
                                  : pull.progress.clamp(0.0, 1.0),
                            ),
                          if (words != null)
                            Flexible(
                              child: Text(
                                words,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.label
                                    .copyWith(color: t.textPrimary)
                                    .merge(so.textStyle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
