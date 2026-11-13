/// Pull to refresh, headless: an overscroll past the top of [child] arms a
/// refresh; letting go past [DesignPullToRefresh.triggerDistance] runs it.
/// The look paints the indicator from its state. A screen reader gets a
/// "Refresh" action on the list and hears when it starts and ends; the
/// keyboard and anything else can call [DesignPullToRefreshState.refresh].
library;

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'localizations.dart';

/// Where a pull stands.
enum DesignRefreshMode {
  /// Nothing pulled.
  inactive,

  /// Pulled, not yet far enough.
  drag,

  /// Pulled far enough: letting go refreshes.
  armed,

  /// Refreshing.
  refresh,

  /// Done, the indicator on its way out.
  done,
}

/// What the look paints the indicator from.
@immutable
class DesignRefreshDetails {
  /// The state; the refresher makes it.
  const DesignRefreshDetails({
    required this.mode,
    required this.progress,
    required this.extent,
  });

  /// Where the pull stands.
  final DesignRefreshMode mode;

  /// The pull as a share of the trigger distance (1 = armed; it can pass 1).
  final double progress;

  /// How far down the indicator reaches, in pixels.
  final double extent;
}

/// [child], a scroll view, refreshed by [onRefresh] on a pull.
///
/// ```dart
/// DesignPullToRefresh(onRefresh: () async {}, indicatorBuilder: (context, details) => const SizedBox(height: 40), child: ListView())
/// ```
class DesignPullToRefresh extends StatefulWidget {
  /// A refresher around [child].
  const DesignPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.indicatorBuilder,
    required this.child,
    this.triggerDistance = 80,
    this.restExtent = 56,
    this.refreshLabel,
    this.refreshingMessage,
    this.doneMessage,
  });

  /// Refreshes; the indicator stays until it completes.
  final Future<void> Function() onRefresh;

  /// Paints the indicator, at the top, [DesignRefreshDetails.extent] tall.
  final Widget Function(BuildContext context, DesignRefreshDetails details)
  indicatorBuilder;

  /// The scroll view.
  final Widget child;

  /// How far a pull goes before it arms.
  final double triggerDistance;

  /// How tall the indicator stays while it refreshes.
  final double restExtent;

  /// The screen reader's action; null:
  /// [DesignLocalizations.refreshLabel].
  final String? refreshLabel;

  /// What a screen reader hears when a refresh starts; null:
  /// [DesignLocalizations.refreshingMessage].
  final String? refreshingMessage;

  /// What a screen reader hears when it ends; null:
  /// [DesignLocalizations.refreshedMessage].
  final String? doneMessage;

  @override
  State<DesignPullToRefresh> createState() => DesignPullToRefreshState();
}

/// The refresher's state: [refresh] runs one (a keyboard shortcut, a
/// menu's "Refresh").
class DesignPullToRefreshState extends State<DesignPullToRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _extent = AnimationController.unbounded(
    vsync: this,
  );
  DesignRefreshMode _mode = DesignRefreshMode.inactive;
  double _pull = 0;

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  void _go(double to) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _extent.value = to;
    } else {
      _extent.animateTo(
        to,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Runs a refresh, showing the indicator until it completes.
  Future<void> refresh() async {
    if (_mode == DesignRefreshMode.refresh) return;
    setState(() => _mode = DesignRefreshMode.refresh);
    _go(widget.restExtent);
    designAnnounce(
      context,
      widget.refreshingMessage ??
          DesignLocalizations.of(context).refreshingMessage,
    );
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _mode = DesignRefreshMode.done);
        designAnnounce(
          context,
          widget.doneMessage ??
              DesignLocalizations.of(context).refreshedMessage,
        );
        _go(0);
        Timer(const Duration(milliseconds: 200), () {
          if (mounted && _mode == DesignRefreshMode.done) {
            setState(() => _mode = DesignRefreshMode.inactive);
          }
        });
      }
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (_mode == DesignRefreshMode.refresh || _mode == DesignRefreshMode.done) {
      return false;
    }
    final atTop = n.metrics.pixels <= n.metrics.minScrollExtent;
    if (n is ScrollStartNotification) {
      _pull = 0;
    } else if (n is OverscrollNotification && n.dragDetails != null) {
      // A clamping list: the overscroll is the pull.
      if (n.overscroll < 0 && atTop) _pullBy(-n.overscroll);
    } else if (n is ScrollUpdateNotification && n.dragDetails != null) {
      if (n.metrics.pixels < n.metrics.minScrollExtent) {
        // A bouncing list: how far past the top it is.
        _pullTo(n.metrics.minScrollExtent - n.metrics.pixels);
      } else if (_pull > 0 && (n.scrollDelta ?? 0) > 0) {
        _pullBy(-(n.scrollDelta ?? 0));
      }
    } else if (n is ScrollEndNotification ||
        (n is ScrollUpdateNotification && n.dragDetails == null)) {
      _release();
    }
    return false;
  }

  void _pullBy(double delta) => _pullTo(_pull + delta);

  void _pullTo(double pull) {
    _pull = pull < 0 ? 0 : pull;
    // The indicator follows the finger at half its speed.
    _extent.value = _pull / 2;
    final mode = _pull == 0
        ? DesignRefreshMode.inactive
        : _pull >= widget.triggerDistance
        ? DesignRefreshMode.armed
        : DesignRefreshMode.drag;
    if (mode != _mode) setState(() => _mode = mode);
  }

  void _release() {
    if (_mode == DesignRefreshMode.armed) {
      _pull = 0;
      unawaited(refresh());
    } else if (_mode == DesignRefreshMode.drag) {
      _pull = 0;
      setState(() => _mode = DesignRefreshMode.inactive);
      _go(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A node of its own around the list: the action sits there, not on
    // whatever node is above it.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      customSemanticsActions: {
        CustomSemanticsAction(
          label:
              widget.refreshLabel ??
              DesignLocalizations.of(context).refreshLabel,
        ): () =>
            unawaited(refresh()),
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(
          children: [
            widget.child,
            AnimatedBuilder(
              animation: _extent,
              builder: (context, _) {
                final extent = _extent.value < 0 ? 0.0 : _extent.value;
                if (extent == 0 && _mode == DesignRefreshMode.inactive) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: extent,
                  child: ClipRect(
                    child: widget.indicatorBuilder(
                      context,
                      DesignRefreshDetails(
                        mode: _mode,
                        progress: switch (_mode) {
                          DesignRefreshMode.refresh ||
                          DesignRefreshMode.done => 1,
                          _ => _pull / widget.triggerDistance,
                        },
                        extent: extent,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
