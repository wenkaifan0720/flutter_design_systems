// A place in Minimal's navigation, in a file of its own so a copy of the bar
// keeps the package's place.
import 'package:flutter/widgets.dart';

import '../ground.dart';
import 'nav_bar.dart';

/// A destination in a [MinimalNavigationBar].
/// The standard constructor shows its icon and text. [MinimalNavItem.iconOnly]
/// uses [semanticLabel] to announce a destination with a hidden label.
@immutable
class MinimalNavItem {
  /// A destination showing [icon] and [label].
  const MinimalNavItem(this.icon, [this.label, this.key])
    : semanticLabel = null,
      ground = MinimalGround.surface,
      assert(
        label != null,
        'A tab needs words: pass its label, or use '
        'MinimalNavItem.iconOnly(icon, semanticLabel: ...).',
      );

  /// A tab that prints only its glyph; a screen reader still hears
  /// [semanticLabel].
  const MinimalNavItem.iconOnly(
    this.icon, {
    required String this.semanticLabel,
    this.key,
    this.ground = MinimalGround.surface,
  }) : label = null;

  /// A tab whose root stands on the media ground: while it is selected the
  /// shell draws its bar in the dark tokens and the root ends at the bar's
  /// top. Its root page stands on media through
  /// `MinimalPage(ground: MinimalGround.media)`.
  ///
  /// ```dart
  /// MinimalNavItem.media(LucideIcons.play, 'Watch')
  /// ```
  const MinimalNavItem.media(this.icon, String this.label, [this.key])
    : semanticLabel = null,
      ground = MinimalGround.media;

  /// Its glyph.
  final IconData icon;

  /// The words printed under the glyph; null only for
  /// [MinimalNavItem.iconOnly].
  final String? label;

  /// A key for its tab, for tests to find it.
  final Key? key;

  /// What a screen reader announces for a glyph-only tab.
  final String? semanticLabel;

  /// The ground this tab's root stands on. It paints the shell's BAR while
  /// the tab is selected; the root page publishes its own.
  final MinimalGround ground;
}
