// The app's one act from every place of a MinimalAppShell, in a file of its
// own so a copy of the shell keeps the package's act.
import 'package:flutter/widgets.dart';

import 'app_shell.dart';

/// The app's one act from every place of a [MinimalAppShell]: its glyph,
/// what it does, and the words a screen reader hears for the icon-only
/// square.
///
/// ```dart
/// MinimalShellAction(icon: LucideIcons.plus, label: 'Add a book', onPressed: (context) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => const BookForm())))
/// ```
@immutable
class MinimalShellAction {
  /// The act beside the shell's places.
  const MinimalShellAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.primary = false,
    this.key,
  });

  /// The glyph it wears.
  final IconData icon;

  /// What it does, given the context it was pressed in.
  final void Function(BuildContext context) onPressed;

  /// What the act does, announced for the icon-only square; null says
  /// the localized "New".
  final String? label;

  /// Accent-fill the square for the app whose act IS its standing
  /// invitation; otherwise it wears the ink.
  final bool primary;

  /// The key of the action button.
  final Key? key;
}
