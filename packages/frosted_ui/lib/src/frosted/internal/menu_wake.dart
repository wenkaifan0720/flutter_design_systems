import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether the last input was a key or the pointer, and every key pressed
/// since: what a menu ui_core raises reads as it opens, to tell a menu a key
/// opened from one a pointer did. A pointer counts as it moves as well as
/// when it presses: on the web, with semantics on, a click on a control
/// reaches the app as the control's tap, not a press, and the pointer
/// moved there first. Listens from [watch] on, once for the app. Plumbing
/// of the components.
abstract final class FrostedLastInput {
  static bool _keyed = false;
  static bool _watching = false;

  /// Counts the keys pressed since [watch].
  static final ValueNotifier<int> keys = _KeyCount();

  /// Whether the last input was a key (else the pointer, or nothing).
  static bool get keyed => _keyed;

  /// Starts listening: a part that opens a menu calls it as it is built,
  /// before the input that opens the menu comes. The key handler is put
  /// back each time (a test's binding clears the keyboard's handlers), the
  /// pointer's route once.
  static void watch() {
    HardwareKeyboard.instance
      ..removeHandler(_key)
      ..addHandler(_key);
    if (_watching) return;
    _watching = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
  }

  static bool _key(KeyEvent event) {
    if (event is KeyDownEvent) {
      _keyed = true;
      keys.value++;
    }
    return false;
  }

  static void _pointer(PointerEvent event) {
    if (event is PointerDownEvent || event is PointerHoverEvent) {
      _keyed = false;
    }
  }
}

/// The app's key count: it lives as long as the app, so it is never
/// disposed. It is a [ValueNotifier] by its interface, not a
/// [ChangeNotifier] by descent, whose creation a leak-tracked test reports:
/// an app's own tests that open a menu stay leak free.
class _KeyCount implements ValueNotifier<int> {
  final List<VoidCallback> _listeners = [];
  int _value = 0;

  @override
  int get value => _value;

  @override
  set value(int newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  bool get hasListeners => _listeners.isNotEmpty;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  /// Does nothing: the count lives as long as the app.
  @override
  void dispose() {}

  @override
  String toString() => '${describeIdentity(this)}($value)';
}

/// A menu ui_core raises, which gives its first row the focus however it
/// opened: its rows stay unlit until a key is pressed or the pointer moves
/// over the menu, unless a key opened it. So a menu a pointer opened lights
/// no row until the pointer or the keys move, and one a key opened lights
/// the first. After a
/// pointer opened it, the first Down lights the row the menu holds (its
/// first) rather than passing it. Plumbing of the components.
class FrostedMenuWake extends StatefulWidget {
  /// Wakes [child]'s rows.
  const FrostedMenuWake({required this.child, super.key});

  /// The menu's rows.
  final Widget child;

  /// Whether the rows of the menu round [context] may light, or null
  /// outside such a menu.
  static bool? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Awake>()?.awake;

  @override
  State<FrostedMenuWake> createState() => _FrostedMenuWakeState();
}

class _FrostedMenuWakeState extends State<FrostedMenuWake> {
  late bool _awake = FrostedLastInput.keyed;
  // The key count when a key woke the menu: that key lights, not moves.
  int? _wokenBy;

  @override
  void initState() {
    super.initState();
    FrostedLastInput.keys.addListener(_wake);
  }

  @override
  void dispose() {
    FrostedLastInput.keys.removeListener(_wake);
    super.dispose();
  }

  void _wake() {
    if (_awake || !mounted) return;
    _wokenBy = FrostedLastInput.keys.value;
    setState(() => _awake = true);
  }

  void _point() {
    _wokenBy = null;
    _wake();
    _wokenBy = null;
  }

  // Read before ui_core's arrows, which stand above the menu's rows.
  KeyEventResult _key(FocusNode node, KeyEvent event) =>
      event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.arrowDown &&
          _wokenBy == FrostedLastInput.keys.value
      ? KeyEventResult.handled
      : KeyEventResult.ignored;

  // A MouseRegion, not a Listener: the web delivers its hover as surely as
  // a row's own.
  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    onHover: (_) => _point(),
    child: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _key,
      child: _Awake(awake: _awake, child: widget.child),
    ),
  );
}

class _Awake extends InheritedWidget {
  const _Awake({required this.awake, required super.child});

  final bool awake;

  @override
  bool updateShouldNotify(_Awake old) => awake != old.awake;
}
