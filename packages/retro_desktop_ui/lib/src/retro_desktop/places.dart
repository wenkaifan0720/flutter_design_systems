// The places an app's shell offers and the act beside them: what the shell draws, and what every page under it reads.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A place in the app: a menu in the menu bar, a button in the phone's strip.
class RetroDesktopNavItem {
  /// Creates a [RetroDesktopNavItem].
  const RetroDesktopNavItem({
    required this.label,
    required this.short,
    required this.icon,
    this.onPressed,
    this.key,
    this.badgeLabel,
  });

  /// `label` in the menu bar; `short` under the icon in the strip.
  final String label, short;

  /// An optional count or status announced with the action.
  final String? badgeLabel;

  /// The glyph shown with the content.
  final IconData icon;

  /// {@macro retro_desktop.onPressed}
  final VoidCallback? onPressed;

  /// A key on its hit target, for a test to find and press it.
  final Key? key;
}

/// The app's own act beside its places: a square in the middle of the phone's strip, a glyph at the menu bar's end on a
/// desk.
class RetroDesktopAppAction with Diagnosticable {
  /// An act wearing [icon], called [label].
  const RetroDesktopAppAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accent = false,
    this.key,
  });

  /// Its glyph.
  final IconData icon;

  /// Its name, to a screen reader and in its tooltip.
  final String label;

  /// Called when it is pressed.
  final VoidCallback onPressed;

  /// Whether its glyph wears the highlight (the app's standing invitation).
  final bool accent;

  /// The key on its button.
  final Key? key;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('label', label))
      ..add(FlagProperty('accent', value: accent, ifTrue: 'accent'));
  }
}
