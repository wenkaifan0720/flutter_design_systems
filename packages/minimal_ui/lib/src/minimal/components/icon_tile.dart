import 'package:flutter/widgets.dart';

import '../internal/styled.dart';
import '../theme.dart';
import 'tag.dart';

/// A glyph in a square — the leading element of a row that names a kind of
/// thing (a settings entry, a category, an integration): 28 px by default,
/// the glyph in the tone's ink. The neutral tone stands on the surface in a
/// 1 px hairline; any other tone fills with its quiet tint and draws no rim,
/// as a toned tag (the tone's ink and fill are its only colours).
/// Decorative: the row beside it says the words.
///
/// ```dart
/// MinimalListTile(title: 'Notifications', leading: MinimalIconTile(LucideIcons.bell))
/// ```
class MinimalIconTile extends StatelessWidget {
  /// [icon] on a tinted square.
  const MinimalIconTile(
    this.icon, {
    super.key,
    this.tone = MinimalTone.neutral,
    this.size = 28,
  });

  /// The glyph.
  final IconData icon;

  /// The tint and the glyph's ink.
  final MinimalTone tone;

  /// The square's side: 24, 28 (the default), 32 or 40. The glyph steps
  /// with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final colors = t.tone(tone);
    final neutral = tone == MinimalTone.neutral;
    final glyph = size >= 40
        ? MinimalIconSize.i20
        : size >= 32
        ? MinimalIconSize.i18
        : size >= 28
        ? MinimalIconSize.i16
        : MinimalIconSize.i14;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: minimalFrame(
        size >= 40 ? t.shapes.small : t.shapes.mark,
        fill: neutral ? t.card : colors.background,
        side: neutral
            ? BorderSide(color: t.border, width: t.hairline)
            : BorderSide.none,
      ),
      child: MinimalIcon(
        icon,
        size: glyph,
        color: neutral ? t.mutedForeground : colors.foreground,
      ),
    );
  }
}
