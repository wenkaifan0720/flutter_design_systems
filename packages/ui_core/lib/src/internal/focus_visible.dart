/// Whether a part with the focus paints it, as a browser's `:focus-visible`
/// decides: shown after a key, hidden after a press of a pointer (a mouse, a
/// finger, a pen) or a tap that reaches the app as a semantics action (a
/// click on the web with semantics on, a screen reader's), until the next
/// key. Focus that ui_core or the app moves (a dialog's safe action, a
/// popover's first control, a closed surface giving it back) shows as the
/// last input decides, so a surface a pointer opened shows no focus until a
/// key is pressed, and one the keys opened shows it at once. An app that
/// sets [FocusHighlightStrategy.alwaysTraditional] shows focus whatever the
/// input, as Flutter's own widgets do. Inside ui_core; not exported.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The last input's word on whether focus is shown.
abstract final class DesignFocusVisible {
  // What hears the input now: started by the first part to hold it, gone
  // with the last to let go.
  static DesignFocusHearing? _hearing;
  static FocusManager? _manager;
  static bool _shown = true;
  static final ObserverList<VoidCallback> _listeners =
      ObserverList<VoidCallback>();

  /// Whether focus is shown now: in Flutter's traditional highlight mode
  /// (no touch since the last key), and no pointer pressed since the last
  /// key. Before any input it is shown, as Flutter's highlight mode is.
  /// Always, when the app keeps the traditional mode for good
  /// ([FocusHighlightStrategy.alwaysTraditional]).
  static bool get shown {
    final manager = FocusManager.instance;
    _meet(manager);
    if (manager.highlightStrategy == FocusHighlightStrategy.alwaysTraditional) {
      return true;
    }
    return _shown && manager.highlightMode == FocusHighlightMode.traditional;
  }

  // A new focus manager (each test has its own): the input starts again.
  static void _meet(FocusManager manager) {
    if (identical(manager, _manager)) return;
    _manager = manager;
    _shown = true;
  }

  /// Hears the input until the returned hearing is released. Every part
  /// that paints its focus, or shows something on it, holds one from its
  /// mounting to its disposal, so the press that opens a surface is heard
  /// before the surface takes the focus.
  ///
  /// What it hears by (a global pointer route, a key handler, a semantics
  /// action listener) is its own each time the first part holds it, and is
  /// taken away when the last lets go: nothing is kept for the life of the
  /// bindings. A page drawn with ui_core instantiated afresh over a binding
  /// that lives on (App Preview's) neither meets the last page's
  /// registration nor leaves its own.
  static DesignFocusHearing hold() {
    _meet(FocusManager.instance);
    final hearing = _hearing ??= DesignFocusHearing._().._start();
    hearing._holds++;
    return hearing;
  }

  /// Forgets what it hears with, as ui_core instantiated afresh over the
  /// same bindings does (App Preview drawing a page), leaving what the
  /// mounted parts hold in place: they let go of it as they go.
  @visibleForTesting
  static void debugForget() {
    _hearing = null;
    _manager = null;
    _shown = true;
  }

  /// Calls [listener] when [shown] may have changed.
  static void addListener(VoidCallback listener) => _listeners.add(listener);

  /// Stops calling [listener].
  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);

  // A key shows the focus, but not one pressed with Control, Alt or Meta (a
  // shortcut, or a modifier held for a click), as browsers decide.
  static bool _key(KeyEvent event) {
    if (event is KeyUpEvent) return false;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isAltPressed || keys.isMetaPressed) {
      return false;
    }
    _set(true);
    return false;
  }

  static void _pointer(PointerEvent event) {
    if (event is PointerDownEvent) _set(false);
  }

  // A tap with no key held is a pointer's or a screen reader's: on the web
  // with semantics on, a click reaches the app as a tap, with no press.
  static void _semantics(SemanticsActionEvent event) {
    if (event.type != SemanticsAction.tap &&
        event.type != SemanticsAction.longPress) {
      return;
    }
    if (HardwareKeyboard.instance.logicalKeysPressed.isEmpty) _set(false);
  }

  static void _set(bool shown) {
    if (shown == _shown) return;
    _shown = shown;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }
}

/// What [DesignFocusVisible] hears the input by while parts hold it: its
/// own pointer route, key handler and semantics action listener (each this
/// object's, so equal to no other's), registered as the first part holds it
/// and removed as the last [release]s it.
final class DesignFocusHearing {
  DesignFocusHearing._();

  int _holds = 0;
  late final PointerRouter _router;
  late final HardwareKeyboard _keys;
  late final SemanticsBinding _semantics;

  void _start() {
    _router = GestureBinding.instance.pointerRouter;
    _keys = HardwareKeyboard.instance;
    _semantics = SemanticsBinding.instance;
    _keys.addHandler(_key);
    _router.addGlobalRoute(_pointer);
    _semantics.addSemanticsActionListener(_action);
  }

  /// Lets go of it: the last part to let go takes its registrations away.
  void release() {
    assert(_holds > 0, 'a hearing released more often than held');
    if (_holds == 0 || --_holds > 0) return;
    _keys.removeHandler(_key);
    _router.removeGlobalRoute(_pointer);
    _semantics.removeSemanticsActionListener(_action);
    if (identical(DesignFocusVisible._hearing, this)) {
      DesignFocusVisible._hearing = null;
    }
  }

  bool _key(KeyEvent event) => DesignFocusVisible._key(event);

  void _pointer(PointerEvent event) => DesignFocusVisible._pointer(event);

  void _action(SemanticsActionEvent event) =>
      DesignFocusVisible._semantics(event);
}

/// One part's focus, shown or not: whether the part has the focus Flutter
/// would highlight ([focused]) and [DesignFocusVisible.shown] says focus is
/// shown now. [onChanged] hears each change, a key pressed while the part
/// has the focus included.
class DesignFocusShown {
  /// Tells [onChanged] whether the part shows its focus, hearing the input
  /// until [dispose].
  DesignFocusShown(this.onChanged) : _hearing = DesignFocusVisible.hold();

  /// Hears whether the part shows its focus, as it changes.
  final ValueChanged<bool> onChanged;

  DesignFocusHearing? _hearing;

  bool _focused = false;
  bool _value = false;

  /// Whether the part shows its focus.
  bool get value => _value;

  /// Whether the part has the focus Flutter would highlight: what a
  /// [FocusableActionDetector.onShowFocusHighlight] says, or a focus in the
  /// traditional highlight mode.
  void focused(bool on) {
    if (on != _focused) {
      _focused = on;
      on
          ? DesignFocusVisible.addListener(_update)
          : DesignFocusVisible.removeListener(_update);
    }
    _value = on && DesignFocusVisible.shown;
    onChanged(_value);
  }

  void _update() {
    final value = _focused && DesignFocusVisible.shown;
    if (value == _value) return;
    _value = value;
    onChanged(value);
  }

  /// Stops hearing the input.
  void dispose() {
    DesignFocusVisible.removeListener(_update);
    _hearing?.release();
    _hearing = null;
  }
}
