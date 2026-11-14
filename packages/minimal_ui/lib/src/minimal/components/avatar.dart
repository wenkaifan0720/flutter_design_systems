import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'card.dart';
import 'img.dart';
import 'media_slots.dart';

/// A person's circle — 24 in a dense row or a stack, 28 by default, 32
/// beside a heading. With no imagery it draws deterministic initials in
/// ink on a quiet neutral fill whose shade steps by the name, so a person
/// is never a blank silhouette, the same person is always the same shade,
/// and a face never borrows the accent or a status colour: identity is not
/// meaning.
///
/// [media] renders the photograph resolved for a declared plan media slot;
/// a slot that is pending or resolved to nothing falls back to the initials
/// — a face is never a wrong photograph. Announced as an image of [name].
///
/// A disc whatever `shapes` says: a face is round by meaning. [style]
/// dresses one, `components.avatar` every one: fill, foreground (the
/// initials), edge or side, shape (a shaped plate for the initials and the
/// picture alike) and textStyle.
///
/// ```dart
/// MinimalAvatar('Hanna Berg', size: 24)
/// ```
class MinimalAvatar extends StatelessWidget {
  /// [name]'s avatar, [size] across.
  const MinimalAvatar(
    this.name, {
    super.key,
    this.size = 28,
    this.image,
    this.media,
    this.style,
  }) : assert(
         image == null || media == null,
         'an avatar wears one face — a media slot or a placeholder, not both',
       );

  /// Whose it is: its initials and its spoken label.
  final String name;

  /// Its diameter.
  final double size;

  /// A placeholder picture in place of the initials.
  final MinimalPlaceholderImage? image;

  /// The declared media slot id this face resolves from, or null for the
  /// deterministic registers.
  final String? media;

  /// This face's style, over `components.avatar`.
  final MinimalStyle? style;

  /// The initials [name] prints: the first letter of its first two words.
  static String initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
      .join();

  /// The fill and the ink [name]'s initials wear under [t]. A name picks
  /// one of [_steps] shades of the preset's own neutral (its muted fill's
  /// tint, at stepped lightness), so a stack shows distinct faces without a
  /// colour that would read as meaning; the ink is the foreground, which
  /// clears AA on every shade. String.hashCode is not stable across runs,
  /// so the hash is its own arithmetic.
  static ({Color fill, Color ink}) colorsOf(String name, MinimalThemeData t) {
    var hash = 0;
    for (final code in name.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    // Stir the low bits, which a polynomial hash leaves alike for names of
    // one shape, so a few steps spread; every product stays under 2^53, so
    // the web computes the same face as the VM.
    hash ^= hash >> 13;
    hash = (hash * 0x5bd1) & 0x7fffffff;
    hash ^= hash >> 15;
    final step = hash % _steps;
    final dark = !t.isLightAppearance;
    final grey = dark ? 0.16 + step * 0.035 : 0.95 - step * 0.03;
    // The muted fill's tint (each channel's lean from its mean) carried to
    // the stepped grey: a warm preset's faces are warm greys.
    final base = t.muted;
    final mean = (base.r + base.g + base.b) / 3;
    double channel(double c) => (grey + c - mean).clamp(0.0, 1.0);
    return (
      fill: Color.from(
        alpha: 1,
        red: channel(base.r),
        green: channel(base.g),
        blue: channel(base.b),
      ),
      ink: t.foreground,
    );
  }

  /// How many shades a face can wear.
  static const int _steps = 6;

  /// The initials' size: a share of the disc, never under the smallest
  /// legible cap (a 24 px avatar in a dense row).
  static double initialsSizeOf(double size) =>
      math.max(size * 0.38, _initialsFloor);
  static const double _initialsFloor = 10;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([style, t.components.avatar], const {});
    final plate = so.shape;
    final slotId = media;
    final picture = image;
    Widget clip(Widget child) => plate == null
        ? ClipOval(child: child)
        : minimalClip(plate, child: child);
    final Widget face;
    if (slotId != null) {
      face = clip(
        SizedBox.square(
          dimension: size,
          child: MinimalMediaImage(
            slotId: slotId,
            fit: BoxFit.cover,
            fallback: _initials(t, so),
          ),
        ),
      );
    } else if (picture != null) {
      face = clip(MinimalMedia(picture, width: size, height: size, radius: 0));
    } else {
      face = _initials(t, so);
    }
    return Semantics(
      image: true,
      label: name,
      child: ExcludeSemantics(child: face),
    );
  }

  Widget _initials(MinimalThemeData t, MinimalStyleOf so) {
    final colors = colorsOf(name, t);
    final fill = so.fill ?? colors.fill;
    final ink = so.foreground ?? colors.ink;
    // A faint ring in the face's own ink, so a quiet fill still reads as a
    // disc on the page ground.
    final ring = so.rim(colors.ink.withValues(alpha: 0.18), t.hairline);
    final plate = so.shape;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: plate == null
          ? BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: ring == BorderSide.none
                  ? null
                  : Border.fromBorderSide(ring),
            )
          : minimalFrame(plate, fill: fill, side: ring),
      child: Text(
        initialsOf(name),
        maxLines: 1,
        // The initials are sized to the disc, not to the reader's text
        // scale: the disc does not grow, so its letters must not.
        textScaler: TextScaler.noScaling,
        style: so.text(
          t.caption.semibold.copyWith(
            fontSize: initialsSizeOf(size),
            height: 1,
          ),
          ink,
        ),
      ),
    );
  }
}

/// An overlapping row of avatars with a `+N` overflow disc — the members of
/// a project, the people on a thread. Each circle stands in a ring of the
/// ground the stack stands on — the page, or the card around it — and that
/// ring alone cuts neighbours apart: in a stack a face's own faint rim
/// takes the ground's colour too, so no grey line runs between two faces.
/// The first face stands at the start edge and each next one toward the
/// end, so right to left the stack reads from the right, as its names do.
/// Announced as one image listing the names.
///
/// ```dart
/// MinimalAvatarGroup(['Hanna Berg', 'Oskar Lind', 'Ines Duarte'], max: 3)
/// ```
class MinimalAvatarGroup extends StatelessWidget {
  /// The avatars of [names], overlapping.
  const MinimalAvatarGroup(
    this.names, {
    super.key,
    this.size = 24,
    this.max = 4,
  });

  /// Whose they are, in order.
  final List<String> names;

  /// Each circle's outer size, its ring included.
  final double size;

  /// How many faces show before the rest fold into `+N`.
  final int max;

  /// How much of each circle the next one covers at most: enough to read
  /// as a stack, and less where two initials would be bitten (build).
  static const double _overlapRatio = 0.2;

  /// The ring of ground round each face; the face's own rim, in the ground
  /// too, widens the cut between neighbours by a hairline.
  static const double _ring = 1.5;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final ground = MinimalCard.groundOf(context) ?? t.background;
    final shown = names.take(max).toList();
    final overflow = names.length - shown.length;
    // A small stack's initials stop at their legible floor while the disc
    // shrinks, so the overlap also stops where the next face's ring would
    // reach the covered face's initials (two capitals, about 1.5 em wide,
    // centred on the disc).
    final initials = MinimalAvatar.initialsSizeOf(size - _ring * 2);
    final step = math.max(
      size * (1 - _overlapRatio),
      size / 2 + initials * 0.75 + _ring,
    );
    final count = shown.length + (overflow > 0 ? 1 : 0);
    final spoken = overflow > 0
        ? '${shown.join(', ')} and $overflow more'
        : shown.join(', ');
    // A face's rim in the ground: the ring round it is the only cut.
    final rim = BorderSide(color: ground, width: t.hairline);
    final face = MinimalStyle(side: WidgetStatePropertyAll(rim));
    return Semantics(
      image: true,
      label: spoken,
      child: ExcludeSemantics(
        child: SizedBox(
          height: size,
          width: count == 0 ? 0 : size + (count - 1) * step,
          child: Stack(
            // Overlapping chrome must never rect-clip: a tight parent would
            // slice the last circle at a hard edge.
            clipBehavior: Clip.none,
            children: [
              for (final (i, name) in shown.indexed)
                PositionedDirectional(
                  start: i * step,
                  child: _ringed(
                    ground,
                    MinimalAvatar(name, size: size - _ring * 2, style: face),
                  ),
                ),
              if (overflow > 0)
                PositionedDirectional(
                  start: shown.length * step,
                  child: _ringed(
                    ground,
                    Container(
                      width: size - _ring * 2,
                      height: size - _ring * 2,
                      alignment: Alignment.center,
                      // The muted disc in the border's hairline, as a
                      // neutral count is: the bare muted fill all but
                      // vanished on the ground.
                      decoration: BoxDecoration(
                        color: t.muted,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: t.border, width: t.hairline),
                        ),
                      ),
                      // In the ink, as a face's initials are: the quiet
                      // ink on the pale disc only just clears AA and, this
                      // small, all but disappears.
                      child: Text(
                        '+$overflow',
                        maxLines: 1,
                        textScaler: TextScaler.noScaling,
                        style: t.mono.medium
                            .c(t.foreground)
                            .copyWith(fontSize: size * 0.36, height: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ringed(Color ground, Widget child) => Container(
    padding: const EdgeInsets.all(_ring),
    decoration: BoxDecoration(color: ground, shape: BoxShape.circle),
    child: child,
  );
}
