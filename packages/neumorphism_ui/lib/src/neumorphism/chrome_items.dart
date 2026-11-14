// What the chrome shows of the app: its name and its places. The host's scope carries them to every page and the
// chrome draws them; they stand in a file of their own so a copied chrome.dart and the host share one type.
import 'package:flutter/widgets.dart';

/// The name and optional mark displayed by application chrome.
class NeumorphicBrand {
  /// Creates a [NeumorphicBrand].
  const NeumorphicBrand({required this.name, this.mark});

  /// An app-supplied brand mark; null uses the material's dimple motif.
  final Widget? mark;

  /// The name displayed for this item.
  final String name;
}

/// A navigation destination shared by the bar and drawer.
class NeumorphicNavItem {
  /// Creates a [NeumorphicNavItem].
  const NeumorphicNavItem({
    required this.label,
    required this.icon,
    this.short,
    this.count,
    this.badge,
    this.badgeLabel,
    this.onPressed,
    this.key,
  });

  /// `label` on the pilaster and in the tab bar; [short] if the tab needs less.
  final String label;

  /// An abbreviated label for compact navigation.
  final String? short;

  /// The glyph displayed with the content.
  final IconData icon;

  /// A plain figure at the end of the pilaster's row.
  final String? count;

  /// Something waiting on you: a figure on the pigment, on the pilaster's row and over the tab's glyph.
  final String? badge;

  /// Spoken description of a badge, such as "3 new".
  final String? badgeLabel;

  /// Called when the item is activated.
  final VoidCallback? onPressed;

  /// The walkthrough key on its hit target.
  final Key? key;
}
