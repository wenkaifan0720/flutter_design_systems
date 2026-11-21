/// Pull to refresh, headless: an overscroll past the top of [child] arms a
/// refresh; letting go past [RawRefreshIndicator.triggerDistance] runs it.
/// The look paints the indicator from its state. A screen reader gets a
/// "Refresh" action on the list and hears when it starts and ends; the
/// keyboard and anything else can call [RawRefreshIndicatorState.refresh].
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'localizations.dart';
import 'motion.dart';

/// Where a pull stands.
enum RawRefreshIndicatorMode {
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
class RawRefreshIndicatorDetails {
  /// The state; the refresher makes it.
  const RawRefreshIndicatorDetails({
    required this.mode,
    required this.progress,
    required this.extent,
  });

  /// Where the pull stands.
  final RawRefreshIndicatorMode mode;

  /// The pull as a share of the trigger distance (1 = armed; it can pass 1).
  final double progress;

  /// How far down the indicator reaches, in pixels.
  final double extent;
}

/// [child], a scroll view, refreshed by [onRefresh] on a pull.
///
/// ```dart
/// RawRefreshIndicator(onRefresh: () async {}, indicatorBuilder: (context, details) => const SizedBox(height: 40), child: ListView())
/// ```
class RawRefreshIndicator extends StatefulWidget {
  /// A refresher around [child].
  const RawRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.indicatorBuilder,
    required this.child,
    this.triggerDistance = 80,
    this.restExtent = 56,
    this.refreshLabel,
    this.refreshingMessage,
    this.doneMessage,
  }) : assert(triggerDistance > 0 && restExtent >= 0);

  /// Refreshes; the indicator stays until it completes.
  final Future<void> Function() onRefresh;

  /// Paints the indicator, at the top, [RawRefreshIndicatorDetails.extent] tall.
  final Widget Function(
    BuildContext context,
    RawRefreshIndicatorDetails details,
  )
  indicatorBuilder;

  /// The scroll view.
  final Widget child;

  /// How far a pull goes before it arms.
  final double triggerDistance;

  /// How tall the indicator stays while it refreshes.
  final double restExtent;

  /// The screen reader's action; null:
  /// [RawWidgetsLocalizations.refreshLabel].
  final String? refreshLabel;

  /// What a screen reader hears when a refresh starts; null:
  /// [RawWidgetsLocalizations.refreshingMessage].
  final String? refreshingMessage;

  /// What a screen reader hears when it ends; null:
  /// [RawWidgetsLocalizations.refreshedMessage].
  final String? doneMessage;

  @override
  State<RawRefreshIndicator> createState() => RawRefreshIndicatorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<Future<void> Function()>.has('onRefresh', onRefresh),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            RawRefreshIndicatorDetails details,
          )
        >.has('indicatorBuilder', indicatorBuilder),
      )
      ..add(
        DoubleProperty('triggerDistance', triggerDistance, defaultValue: 80),
      )
      ..add(DoubleProperty('restExtent', restExtent, defaultValue: 56))
      ..add(StringProperty('refreshLabel', refreshLabel, defaultValue: null))
      ..add(
        StringProperty(
          'refreshingMessage',
          refreshingMessage,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('doneMessage', doneMessage, defaultValue: null));
  }
}

/// The refresher's state: [refresh] runs one (a keyboard shortcut, a
/// menu's "Refresh").
class RawRefreshIndicatorState extends State<RawRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _extent = AnimationController.unbounded(
    vsync: this,
  );
  RawRefreshIndicatorMode _mode = RawRefreshIndicatorMode.inactive;
  double _pull = 0;

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  void _go(double to) {
    if (designReduceMotionOf(context)) {
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
    if (_mode == RawRefreshIndicatorMode.refresh) return;
    setState(() => _mode = RawRefreshIndicatorMode.refresh);
    _go(widget.restExtent);
    designAnnounce(
      context,
      widget.refreshingMessage ??
          RawWidgetsLocalizations.of(context).refreshingMessage,
    );
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _mode = RawRefreshIndicatorMode.done);
        designAnnounce(
          context,
          widget.doneMessage ??
              RawWidgetsLocalizations.of(context).refreshedMessage,
        );
        _go(0);
        Timer(const Duration(milliseconds: 200), () {
          if (mounted && _mode == RawRefreshIndicatorMode.done) {
            setState(() => _mode = RawRefreshIndicatorMode.inactive);
          }
        });
      }
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (_mode == RawRefreshIndicatorMode.refresh ||
        _mode == RawRefreshIndicatorMode.done) {
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
        ? RawRefreshIndicatorMode.inactive
        : _pull >= widget.triggerDistance
        ? RawRefreshIndicatorMode.armed
        : RawRefreshIndicatorMode.drag;
    if (mode != _mode) setState(() => _mode = mode);
  }

  void _release() {
    if (_mode == RawRefreshIndicatorMode.armed) {
      _pull = 0;
      unawaited(refresh());
    } else if (_mode == RawRefreshIndicatorMode.drag) {
      _pull = 0;
      setState(() => _mode = RawRefreshIndicatorMode.inactive);
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
              RawWidgetsLocalizations.of(context).refreshLabel,
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
                if (extent == 0 && _mode == RawRefreshIndicatorMode.inactive) {
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
                      RawRefreshIndicatorDetails(
                        mode: _mode,
                        progress: switch (_mode) {
                          RawRefreshIndicatorMode.refresh ||
                          RawRefreshIndicatorMode.done => 1,
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
