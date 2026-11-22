/// Whether the keys' focus shows: after a key, not after a pointer's press,
/// until the next key, as a browser's `:focus-visible` decides.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether a key, not a pointer's press, came last: whether an option a
/// combobox or a tag input has highlighted draws the keys' ring.
///
/// ui_core's pressable decides it so for Clay's keys, boxes and switches,
/// and a select's list shows it so; a list a press opened marks its chosen
/// option alone (its words in the accent's ink and a check).
abstract final class ClayKeysShown {
  static bool _shown = true;
  static FocusManager? _manager;
  static bool _routed = false;

  /// True after a key, false after a pointer's press; true before either.
  static bool get shown {
    _watch();
    return _shown;
  }

  /// [states] as an option draws them: without the keys' highlight
  /// ([WidgetState.focused]) while a pointer came last.
  static Set<WidgetState> option(Set<WidgetState> states) =>
      shown || !states.contains(WidgetState.focused)
      ? states
      : ({...states}..remove(WidgetState.focused));

  /// Starts listening for keys and pointers, so the press that opens a
  /// list is heard: a field that shows options calls it as it builds.
  static void watch() => _watch();

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

  static void _pointer(PointerEvent event) {
    if (event is PointerDownEvent) _shown = false;
  }

  static bool _key(KeyEvent event) {
    if (event is KeyDownEvent) _shown = true;
    return false;
  }
}
