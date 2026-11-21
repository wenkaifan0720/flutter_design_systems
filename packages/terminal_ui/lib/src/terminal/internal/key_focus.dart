/// Whether the keys' focus shows: after a key, not after a pointer's press,
/// until the next key, as a browser's `:focus-visible` decides.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether a key, not a pointer's press, came last: whether a control with
/// the focus draws its cursor.
///
/// ui_core's pressable decides it so for Terminal's buttons, boxes and
/// switches. Flutter's `RawRadio` shows its focus whenever the highlight
/// mode is traditional, after a mouse click too; a radio drawn on it reads
/// this as well, so a click leaves no cursor on a radio either.
abstract final class TermKeyFocus {
  static bool _shown = true;
  static FocusManager? _manager;
  static bool _routed = false;

  /// Called when [shown] changes. A plain set, not a notifier: it lives as
  /// long as the app.
  static final _listeners = <VoidCallback>{};

  /// True after a key, false after a pointer's press; true before either.
  static bool get shown {
    _watch();
    return _shown;
  }

  /// Calls [listener] whenever [shown] changes, until [removeListener].
  static void addListener(VoidCallback listener) {
    _watch();
    _listeners.add(listener);
  }

  /// Stops calling [listener].
  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  static void _watch() {
    final manager = FocusManager.instance;
    if (identical(manager, _manager)) return;
    // A new focus manager (each test has its own): the input starts again.
    _manager = manager;
    _shown = true;
    if (!_routed) {
      _routed = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
    }
    HardwareKeyboard.instance
      ..removeHandler(_key)
      ..addHandler(_key);
  }

  static void _set(bool shown) {
    if (shown == _shown) return;
    _shown = shown;
    for (final listener in _listeners.toList()) {
      listener();
    }
  }

  static void _pointer(PointerEvent event) {
    if (event is PointerDownEvent) _set(false);
  }

  static bool _key(KeyEvent event) {
    if (event is KeyDownEvent) _set(true);
    return false;
  }
}
