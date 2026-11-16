/// What an open surface of ui_core's holds in its route: a system back
/// (Android's button or gesture) closes the surface, innermost first, and the
/// page stays. Inside ui_core; not exported.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A surface's hold on its route's back while it is open: the route refuses
/// to pop, and the back runs [onBack], which closes the surface, instead.
///
/// Every surface held on a route hears a back; only the one held last (a
/// submenu after its menu, a field's list after the popover round it)
/// closes, so each back closes one, and the back after the last pops the
/// page.
class DesignBackHold extends PopEntry<Object?> {
  /// A hold that runs [onBack] on a back while it is held.
  DesignBackHold(this.onBack);

  /// Closes the surface.
  final VoidCallback onBack;

  ModalRoute<Object?>? _route;

  // Every hold, in the order taken.
  static final List<DesignBackHold> _held = [];

  /// Whether a route holds this.
  bool get isHeld => _route != null;

  /// Held by [route] (none releases it); held already, it moves there.
  void hold(ModalRoute<Object?>? route) {
    if (identical(route, _route)) return;
    release();
    if (route == null) return;
    route.registerPopEntry(this);
    _route = route;
    _held.add(this);
  }

  /// No longer held: a back is the page's again.
  void release() {
    _route?.unregisterPopEntry(this);
    _route = null;
    _held.remove(this);
  }

  @override
  ValueListenable<bool> get canPopNotifier => const _Refuses();

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    final route = _route;
    if (didPop || route == null) return;
    final innermost = _held.lastWhere((h) => identical(h._route, route));
    if (!identical(innermost, this)) return;
    // After every hold has heard it: closed at once, the next one in would be
    // taken for the innermost meanwhile, and the route's holds would change
    // while it reads them.
    scheduleMicrotask(() {
      if (identical(_route, route)) onBack();
    });
  }
}

// A route's pop, refused for as long as it is held.
class _Refuses implements ValueListenable<bool> {
  const _Refuses();

  @override
  bool get value => false;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
