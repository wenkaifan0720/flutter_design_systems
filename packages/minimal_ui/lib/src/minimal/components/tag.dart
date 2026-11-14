/// Static status labels and the tone palette they share: the palette is
/// here because status, badge and KPI components speak in it too.
library;

import 'package:flutter/widgets.dart';

import '../internal/cap_label.dart';
import '../internal/styled.dart';
import '../theme.dart';

/// The semantic tones a status, badge, tag or KPI delta speaks in — the
/// same five Cody names, so a transferred page keeps its meaning.
enum MinimalTone {
  /// Plain: no meaning beyond the words.
  neutral,

  /// The primary: new, current, chosen.
  primary,

  /// Done or healthy.
  success,

  /// Needs a look.
  warning,

  /// Failed or destructive.
  destructive,
}

/// The colours one [MinimalTone] resolves to in the active theme.
@immutable
class MinimalToneColors {
  /// Creates the resolved colours of a tone.
  const MinimalToneColors({
    required this.foreground,
    required this.background,
    required this.indicator,
  });

  /// Text and thin-glyph colour: the tone's ink role (`successInk`, ...),
  /// which clears AA on the page ground and on [background].
  final Color foreground;

  /// The quiet fill behind a tinted label or row.
  final Color background;

  /// The status dot, bars and small solid marks: the tone's fill colour.
  final Color indicator;
}

/// Resolves a [MinimalTone] against the theme: `t.tone(MinimalTone.warning).indicator`.
extension MinimalToneTheme on MinimalThemeData {
  /// The colours [tone] resolves to in this theme.
  MinimalToneColors tone(MinimalTone tone) => switch (tone) {
    // The neutral dot is the quiet ink, as its words are: the placeholder
    // ink (textTertiary) read as disabled, and by night all but sank.
    MinimalTone.neutral => MinimalToneColors(
      foreground: mutedForeground,
      background: muted,
      indicator: mutedForeground,
    ),
    MinimalTone.primary => MinimalToneColors(
      foreground: primaryInk,
      background: primarySubtle,
      indicator: primary,
    ),
    MinimalTone.success => MinimalToneColors(
      foreground: successInk,
      background: successSubtle,
      indicator: success,
    ),
    MinimalTone.warning => MinimalToneColors(
      foreground: warningInk,
      background: warningSubtle,
      indicator: warning,
    ),
    MinimalTone.destructive => MinimalToneColors(
      foreground: destructiveInk,
      background: destructiveSubtle,
      indicator: destructive,
    ),
  };
}

/// A small static label ("Paid", "New", "Overdue", "v2.4"): 20 px tall on
/// the small radius, its tone's quiet fill behind the tone's ink in the
/// caption register. A tag says what a record IS; it is never a control —
/// a filter is a chip, a status with a dot is a badge.
///
/// The neutral tone carries a hairline so it still reads as an object on
/// the page ground, where its fill is nearly the ground itself.
///
/// [dot] is the LABEL register — a record's category (`Bug`, `Design`)
/// rather than its state: every label draws the same neutral pill, its
/// words in the ink, and only a 6 px dot in the named tone tells them
/// apart. A column of labels then reads as one thing; tinted fills stay
/// for states that need the eye.
///
/// ```dart
/// MinimalTag('Overdue', tone: MinimalTone.destructive)
/// ```
///
/// ```dart
/// MinimalTag('Bug', dot: MinimalTone.destructive)
/// ```
class MinimalTag extends StatelessWidget {
  /// A tag saying [label].
  const MinimalTag(
    this.label, {
    super.key,
    this.tone = MinimalTone.neutral,
    this.icon,
    this.dot,
  });

  /// What it says.
  final String label;

  /// Its tint.
  final MinimalTone tone;

  /// Draw the label register: a neutral pill led by a dot in this tone
  /// ([tone] is then ignored).
  final MinimalTone? dot;

  /// A 12 px glyph before the label, in the tone's ink.
  final IconData? icon;

  /// The tag's height at the default text scale.
  static const double height = 20;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final mark = dot;
    final neutral = mark != null || tone == MinimalTone.neutral;
    final colors = t.tone(mark == null ? tone : MinimalTone.neutral);
    final ink = mark == null ? colors.foreground : t.foreground;
    final glyph = icon;
    return Container(
      constraints: const BoxConstraints(minHeight: height),
      padding: const EdgeInsets.symmetric(
        horizontal: _padX,
        vertical: MinimalSpacing.s2,
      ),
      decoration: minimalFrame(
        t.shapes.mark,
        fill: colors.background,
        side: neutral
            ? BorderSide(color: t.border, width: t.hairline)
            : BorderSide.none,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null) ...[
            Container(
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                color: t.tone(mark).indicator,
                shape: BoxShape.circle,
              ),
            ),
            const MinimalGap(MinimalSpacing.s4 + 1),
          ] else if (glyph != null) ...[
            MinimalIcon(glyph, size: _glyph, color: ink),
            const MinimalGap(MinimalSpacing.s4),
          ],
          Flexible(
            child: minimalCapLabel(
              Text(
                label,
                style: t.caption.medium.c(ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A tag's glyph: a step under the 14 px pill glyph.
  static const double _glyph = 12;

  /// The label register's dot: a badge's.
  static const double _dot = 6;

  /// The air either side of the label.
  static const double _padX = 6;
}
