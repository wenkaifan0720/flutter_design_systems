// What the chrome's scope carries: the app's name and its places. They live apart from the chrome that draws them, so a
// copied-out top bar or tab bar still reads the places the package's own scope holds.
import 'package:flutter/widgets.dart';

/// The app, as its chrome names it.
class ComicBrand {
  /// Creates a [ComicBrand].
  const ComicBrand({required this.name});

  /// The displayed name of this record or person.
  final String name;
}

/// One application destination, with its labels, glyph and activation callback.
class ComicNavItem {
  /// Creates a [ComicNavItem].
  const ComicNavItem({
    required this.label,
    required this.short,
    required this.icon,
    this.onPressed,
    this.key,
    this.badge,
    this.badgeLabel,
  });

  /// `label` in the masthead; `short` under the icon in the tab bar.
  final String label, short;

  /// The optional glyph beside the words.
  final IconData icon;

  /// {@macro comic.onPressed}
  final VoidCallback? onPressed;

  /// The walkthrough key on its hit target.
  final Key? key;

  /// Printed count or an empty string for a dot; spoken with the destination.
  final String? badge, badgeLabel;
}
