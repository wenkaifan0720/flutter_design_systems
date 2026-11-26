import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';

/// Lets focus go from the key that just saved the task.
///
/// Call it after a save made from the Save key succeeds. The save leaves the
/// draft clean, and a clean draft disables the key. On the web the browser
/// focuses a key's node as it is pressed (the studies keep semantics on), and
/// Flutter moves focus off a node that can no longer hold it to the node
/// focused before it, as often as not the Assignee or Project combobox,
/// which opens its list again on that focus. A browser lets focus go from a
/// button it disables; so does this, before the key is disabled.
///
/// Focus stays where it is in a text field, and when the save came from
/// the keyboard shortcut (Ctrl or ⌘ held): then the key never had it.
void releaseSaveFocus() {
  final focus = FocusManager.instance.primaryFocus;
  final keys = HardwareKeyboard.instance;
  if (focus == null || keys.isControlPressed || keys.isMetaPressed) return;
  final at = focus.context;
  if (at != null &&
      (at.widget is EditableText ||
          at.findAncestorWidgetOfExactType<EditableText>() != null)) {
    return;
  }
  focus.unfocus();
}
