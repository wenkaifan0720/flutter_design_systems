/// The browser's own context menu, off while a pointer is over a context
/// menu's region or pressed in it, focus is in it, or its menu is open:
/// counted across every region at once, and left alone when the app had
/// turned it off itself. On the web only; elsewhere there is none. Inside
/// ui_core; not exported.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One region's hold on the browser's menu.
class DesignBrowserMenuHold {
  bool _held = false;

  /// Holds the browser's menu off while [on]; lets it go when not.
  void hold(bool on) {
    if (on == _held) return;
    _held = on;
    on ? DesignBrowserMenu._take() : DesignBrowserMenu._give();
  }

  /// Lets it go, for good.
  void dispose() => hold(false);
}

/// The count of holds across regions, and the switches it throws, which a
/// test swaps.
abstract final class DesignBrowserMenu {
  /// Whether the app runs in a browser; a test sets it.
  @visibleForTesting
  static bool onWeb = kIsWeb;

  /// Turns the browser's menu off.
  @visibleForTesting
  static Future<void> Function() disable =
      BrowserContextMenu.disableContextMenu;

  /// Turns the browser's menu back on.
  @visibleForTesting
  static Future<void> Function() enable = BrowserContextMenu.enableContextMenu;

  /// Whether the browser's menu is on now.
  @visibleForTesting
  static bool Function() enabled = _enabled;

  static bool _enabled() => BrowserContextMenu.enabled;

  static int _holds = 0;

  // Whether the menu is off because of the holds (not the app).
  static bool _ours = false;

  /// How many regions hold it now.
  @visibleForTesting
  static int get holds => _holds;

  static void _take() {
    if (_holds++ == 0 && onWeb && enabled()) {
      _ours = true;
      disable().ignore();
    }
  }

  static void _give() {
    if (_holds == 0) return;
    if (--_holds == 0 && _ours) {
      _ours = false;
      enable().ignore();
    }
  }
}
