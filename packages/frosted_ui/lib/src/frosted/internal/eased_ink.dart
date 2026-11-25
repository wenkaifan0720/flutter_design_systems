import 'package:flutter/painting.dart' show Color;
import 'package:ui_core/ui_core.dart';

/// [ink] where it reads [ratio]:1 on every one of [grounds]: itself when it
/// does, else the nearest tone of its hue that does (ui_core's
/// `RawPalette.readableTone`), its chroma easing toward [toward]'s by the
/// share of the way its tone went to [toward]'s, as a tint or a shade of
/// [ink] toward that ink would. Frosted's inks stay soft where they must
/// move: a night's money in is a pale mint, not a neon green. Never past
/// [toward]: where only a tone beyond it reads, [toward] itself (a quiet ink
/// never outshines the one it eases to). Plumbing of the theme.
Color frostedEasedInk(
  Color ink,
  Color toward,
  List<Color> grounds, [
  double ratio = 4.5,
]) {
  final read = RawPalette.readableTone(ink, on: grounds, ratio: ratio);
  if (read == ink) return ink;
  final from = RawHct.fromColor(ink);
  final to = RawHct.fromColor(toward);
  final span = to.tone - from.tone;
  double shareOf(Color c) =>
      span.abs() < 1 ? 1.0 : (RawHct.fromColor(c).tone - from.tone) / span;
  final share = shareOf(read);
  if (share >= 1) return toward;
  final eased = RawHct.fromColor(read)
      .withChroma(
        from.chroma + (to.chroma - from.chroma) * share.clamp(0.0, 1.0),
      )
      .toColor()
      .withValues(alpha: read.a);
  // The same tone reads the same, to the rounding of the colour (and of a
  // translucent ink's blend): walked again, the soft ink holds the ratio.
  final held = RawPalette.readableTone(eased, on: grounds, ratio: ratio);
  return shareOf(held) >= 1 ? toward : held;
}
