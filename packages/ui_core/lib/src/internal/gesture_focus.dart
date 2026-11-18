/// The focus a user gesture takes from a route, given back when it ends.
/// Inside ui_core; not exported.
///
/// While a user gesture runs on a navigator (a sheet's drag, a swipe back),
/// Flutter's [ModalRoute] lets nothing in its scope hold the focus, so the
/// focus inside a route leaves it, for the page under it; when the gesture
/// ends, nothing brings it back. A sheet dragged and let go open would leave
/// Escape and the keys to the page under its barrier, and a page swiped
/// away would leave the page under it without the focus a back button
/// gives it.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'quiet_focus.dart';

/// Holds the focus through the user gestures on a route: once they are
/// over, the navigator's current route has it back (the route itself when
/// it stays, the one under it when it went), on the child that held it
/// there (its scope remembers which).
class GestureFocus {
  NavigatorState? _navigator;
  ValueListenable<bool>? _gestures;

  /// As a gesture on [route] starts, before its navigator is told: if the
  /// route holds the focus, the current route has it back once the
  /// navigator's user gestures are over.
  void hold(ModalRoute<Object?> route) {
    final navigator = route.navigator;
    if (_gestures != null || navigator == null) return;
    if (!(_scopeOf(route)?.hasFocus ?? false)) return;
    _listen(navigator);
  }

  void _listen(NavigatorState navigator) {
    _navigator = navigator;
    _gestures = navigator.userGestureInProgressNotifier..addListener(_changed);
  }

  void _changed() {
    final gestures = _gestures;
    if (gestures == null || gestures.value) return;
    gestures.removeListener(_changed);
    _gestures = null;
    // The routes' scopes take focus again as the navigator rebuilds them,
    // the next frame.
    _giveBack(3);
  }

  void _giveBack(int frames) {
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        final navigator = _navigator;
        if (navigator == null || !navigator.mounted) return;
        // Another gesture began meanwhile: its end gives it back.
        if (navigator.userGestureInProgress) {
          _listen(navigator);
          return;
        }
        final route = _currentOf(navigator);
        final scope = route is ModalRoute<Object?> ? _scopeOf(route) : null;
        if (route is! ModalRoute<Object?> ||
            scope == null ||
            route.animation?.status == AnimationStatus.reverse ||
            scope.hasFocus ||
            !_displaced(navigator)) {
          _navigator = null;
          return;
        }
        if (!scope.canRequestFocus) {
          if (frames > 1) {
            _giveBack(frames - 1);
          } else {
            _navigator = null;
          }
          return;
        }
        _navigator = null;
        DesignQuietFocus.restore(scope);
      }, debugLabel: 'GestureFocus')
      ..ensureVisualUpdate();
  }

  // The navigator's current route: the first popUntil asks about, which
  // pops nothing when told to stop there.
  static Route<Object?>? _currentOf(NavigatorState navigator) {
    Route<Object?>? current;
    navigator.popUntil((route) {
      current = route;
      return true;
    });
    return current;
  }

  // A route's focus scope, round its page (Flutter keeps the node to
  // itself).
  static FocusScopeNode? _scopeOf(ModalRoute<Object?> route) {
    final context = route.subtreeContext;
    return context == null
        ? null
        : FocusScope.of(context, createDependency: false);
  }

  // Whether the focus is where the gesture sent it, somewhere in the
  // navigator (or above it), rather than outside it, where the user put it
  // since.
  static bool _displaced(NavigatorState navigator) {
    final primary = FocusManager.instance.primaryFocus;
    final node = navigator.focusNode;
    return primary == null ||
        identical(primary, node) ||
        primary.ancestors.contains(node) ||
        node.ancestors.contains(primary);
  }
}
