// One current row in a design-kit menu (a menu bar's, a split button's), as in Comic's own menus: the row with the
// focus is the current one, the pointer moves the focus onto the row it moves over (so the keys go on from the
// pointer's row, and a row under a resting pointer never reads as a second current one), and a menu the pointer opened
// lights no row until the pointer moves over it or a key is pressed. The design kit focuses a menu's first row however
// it opened; the first Down, Home, Enter or Space in a quiet menu lights that row and does nothing else.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Whether the last press was a key's rather than a pointer's: a menu the keys opened lights its first row, one the
/// pointer opened none. A menu's anchor calls [follow] as it builds, before anything can open it.
abstract final class ComicLastInput {
  static bool _routed = false;
  static bool _key = false;

  /// Follows presses from now on. A test's teardown drops keyboard handlers, so the handler is added again each call.
  static void follow() {
    if (!_routed) {
      _routed = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
    }
    HardwareKeyboard.instance
      ..removeHandler(_keyDown)
      ..addHandler(_keyDown);
  }

  static void _pointer(PointerEvent event) {
    if (event is PointerDownEvent) _key = false;
  }

  static bool _keyDown(KeyEvent event) {
    if (event is KeyDownEvent) _key = true;
    return false;
  }

  /// Whether the last press was a key's.
  static bool get wasKey => _key;
}

/// A design-kit menu's surface: quiet while the pointer opened it and nothing has moved since.
class ComicMenuSurface extends StatefulWidget {
  /// Wraps a menu's [child] (its rows).
  const ComicMenuSurface({super.key, required this.child});

  /// The menu's frame and rows.
  final Widget child;

  /// Whether the rows under [context] stand in a quiet menu: none of them is current.
  static bool quiet(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Quiet>()?.quiet ?? false;

  @override
  State<ComicMenuSurface> createState() => _ComicMenuSurfaceState();
}

class _ComicMenuSurfaceState extends State<ComicMenuSurface> {
  late bool _quiet = !ComicLastInput.wasKey;

  void _wake() {
    if (_quiet) setState(() => _quiet = false);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_quiet || event is! KeyDownEvent) return KeyEventResult.ignored;
    _wake();
    final key = event.logicalKey;
    // These light the row the focus waits on; Up, End, Escape and a letter go on as they would.
    return key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.home ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: _key,
    child: MouseRegion(
      onHover: (_) => _wake(),
      child: _Quiet(quiet: _quiet, child: widget.child),
    ),
  );
}

class _Quiet extends InheritedWidget {
  const _Quiet({required this.quiet, required super.child});

  final bool quiet;

  @override
  bool updateShouldNotify(_Quiet old) => quiet != old.quiet;
}

/// A design-kit menu row's face, built by [face] for the states it shows: focused while the row is the current one, and
/// nothing of the pointer's own. The pointer moving over a row moves the focus there, so the keys go on from the
/// pointer's row; the row is current while it holds the focus, shown by the keys' highlight or under the pointer (a
/// browser shows no focus highlight after the pointer alone), and none is while the menu is quiet.
Widget comicMenuRow(
  BuildContext context,
  Set<WidgetState> states,
  Widget Function(Set<WidgetState> states) face,
) {
  final quiet = ComicMenuSurface.quiet(context);
  // The builder's context stands above the row's focus; the face, built below it, finds the row's node.
  return Builder(
    builder: (row) {
      final node = Focus.maybeOf(row);
      final held = node?.hasFocus ?? false;
      final current =
          !quiet &&
          !states.contains(WidgetState.disabled) &&
          (states.contains(WidgetState.focused) ||
              (held && states.contains(WidgetState.hovered)));
      return MouseRegion(
        onHover: (_) {
          if (node != null && !node.hasFocus && node.canRequestFocus) {
            node.requestFocus();
          }
        },
        child: face({
          ...states.difference(const {
            WidgetState.hovered,
            WidgetState.focused,
          }),
          if (current) WidgetState.focused,
        }),
      );
    },
  );
}
