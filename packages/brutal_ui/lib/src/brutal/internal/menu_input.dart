/// Whether the last press was a pointer's (a click or a tap) or a key's: a
/// menu a pointer opened lights no row until the pointer moves onto one or a
/// key is pressed, as every desktop's menus do; one a key opened lights the
/// row the keyboard is on.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

bool _pointerLast = false;
bool _routed = false;

/// Whether the last press was a pointer's rather than a key's.
bool get brutalPointerPressedLast => _pointerLast;

/// Watches presses for [brutalPointerPressedLast]. A menu calls it as it
/// builds, before its trigger can be pressed; calling it again is harmless.
void brutalWatchPresses() {
  if (!_routed) {
    _routed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
  }
  // Once, whoever cleared the keyboard's handlers since.
  HardwareKeyboard.instance
    ..removeHandler(_key)
    ..addHandler(_key);
}

void _pointer(PointerEvent event) {
  if (event is PointerDownEvent) _pointerLast = true;
}

bool _key(KeyEvent event) {
  if (event is KeyDownEvent) _pointerLast = false;
  return false;
}
