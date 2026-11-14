import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/cut.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../../internal/cap.dart';

/// How large a [FrostedAvatar] stands, and the size of its initials.
enum FrostedAvatarSize {
  /// 40 across, its initials 14: a top bar's.
  regular(FrostedChromeMetrics.avatar, FrostedChromeMetrics.avatarType),

  /// 36 across, 13: the sidebar foot's and a row's.
  small(FrostedChromeMetrics.avatarSmall, FrostedChromeMetrics.avatarTypeSmall),

  /// 52 across, 16: a person in a row of people (`.pearl`).
  large(FrostedChromeMetrics.avatarLarge, FrostedChromeMetrics.avatarTypeLarge),

  /// 80 across, 28: the profile's own ([FrostedProfileHero]).
  extraLarge(
    FrostedChromeMetrics.avatarProfile,
    FrostedChromeMetrics.avatarTypeProfile,
  );

  const FrostedAvatarSize(this.diameter, this.fontSize);

  /// How wide the disc is.
  final double diameter;

  /// The letters' size.
  final double fontSize;
}

/// The owner as their [initials] on a pearl of light, lilac through rose to
/// peach, in the display face, with the rim of light along its top and its
/// hairline edge (`.avatar`); an [image] (a photo) fills the disc instead,
/// the initials showing until it loads or when it fails. With [onPressed]
/// it is a link named [name] (the bar's avatar opening the profile);
/// without, an image of the person. [dimmed] draws one not chosen at the
/// quieter share and [selected] one chosen in a ring of white and ink (a
/// row of people).
///
/// ```dart
/// FrostedAvatar('MH', name: 'Profile and settings', onPressed: () => Navigator.of(context).pushNamed('/profile'))
/// ```
class FrostedAvatar extends StatelessWidget {
  /// Creates a [FrostedAvatar].
  const FrostedAvatar(
    this.initials, {
    this.image,
    this.size = FrostedAvatarSize.regular,
    this.name,
    this.onPressed,
    this.selected = false,
    this.dimmed = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// One or two letters.
  final String initials;

  /// A photo over the initials.
  final ImageProvider? image;

  /// How large it stands.
  final FrostedAvatarSize size;

  /// What a screen reader says; null says the initials.
  final String? name;

  /// Makes the avatar a link.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// A ring of white and ink round it: the person chosen.
  final bool selected;

  /// Drawn at the quieter share: a person not chosen.
  final bool dimmed;

  /// This avatar's own style, over `FrostedThemeData.components.avatar`:
  /// its fill (a flat colour in place of the pearl), the initials' colour
  /// and style, the edge's colour or a whole side, and its shape (a disc by
  /// default), each per state (selected while [selected]).
  ///
  /// ```dart
  /// FrostedAvatar(
  ///   'MS',
  ///   style: const FrostedStyle(
  ///     shape: WidgetStatePropertyAll(
  ///       RoundedRectangleBorder(
  ///         borderRadius: BorderRadius.all(Radius.circular(10)),
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final d = size.diameter;
    final s = FrostedStyleLayers(style, t.components.avatar, {
      if (selected) WidgetState.selected,
    });
    final cut = s.shape;
    final fill = s.fill;
    final (edge, edges) = s.edgeOf(t.glass.edge, FrostedStrokes.regular);
    Widget disc = SizedBox.square(
      dimension: d,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(
          FrostedStyleLayers.radiusOf(cut, d, d / 2),
        ),
        shape: cut,
        color: fill,
        gradients: fill == null ? [t.pearl.avatarGradient] : const <Gradient>[],
        edge: edge,
        edges: edges,
        sheen: t.glass.rim,
        shadows: selected
            ? [
                BoxShadow(
                  color: t.colorScheme.ringInner,
                  spreadRadius: FrostedChromeMetrics.personRingInner,
                ),
                BoxShadow(
                  color: t.colorScheme.ringOuter,
                  spreadRadius: FrostedChromeMetrics.personRingOuter,
                ),
              ]
            : const <BoxShadow>[],
        clipChild: image != null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: frostedCapCentred(
                Text(
                  initials,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: s.words(
                    t.textTheme.monogram
                        .at(size.fontSize)
                        .c(t.pearl.text)
                        .copyWith(height: 1),
                  ),
                ),
              ),
            ),
            if (image case final image?)
              Image(
                image: image,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
    if (dimmed) {
      disc = Opacity(
        opacity: FrostedChromeMetrics.personDimOpacity,
        child: disc,
      );
    }
    if (onPressed == null) {
      return Semantics(
        label: name ?? initials,
        image: true,
        child: ExcludeSemantics(child: disc),
      );
    }
    return FrostedHitSlop(
      child: FrostedPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: name ?? initials,
        role: FrostedPressRole.link,
        radius: FrostedStyleLayers.radiusOf(cut, d, d / 2),
        shape: cut,
        child: disc,
      ),
    );
  }
}

/// A count on the owner's [FrostedProfileHero]: the [count] over its
/// [label] (5 over Accounts).
@immutable
class FrostedProfileCount {
  /// Creates a [FrostedProfileCount].
  const FrostedProfileCount(this.count, this.label);

  /// How many more there are.
  final int count;

  /// What is counted, in the plural the count needs (accounts, card).
  final String label;
}

/// The owner as the profile leads (`.me-hero`): the [initials] on the
/// profile's [FrostedAvatar], the [name] in the name type 14 under it, the
/// quiet [meta] line 6 under (Member since October 2023), the [contact]
/// lines in the quieter ink, and the [counts] three across over a hairline
/// (DERIVED: the source keeps its counts in a tile below), each figure over
/// its caption; all centred. Read as the name, its heading.
///
/// ```dart
/// FrostedProfileHero(initials: 'MH', name: 'Maren Holt', meta: 'Member since October 2023', contact: const ['maren.holt@example.com', '+1 (415) 555-0142'], counts: const [FrostedProfileCount(5, 'Accounts'), FrostedProfileCount(2, 'Cards'), FrostedProfileCount(3, 'Goals')])
/// ```
class FrostedProfileHero extends StatelessWidget {
  /// Creates a [FrostedProfileHero].
  const FrostedProfileHero({
    required this.initials,
    required this.name,
    this.meta,
    this.contact = const <String>[],
    this.counts = const <FrostedProfileCount>[],
    super.key,
  });

  /// One or two letters, the avatar's face.
  final String initials;

  /// The person's name, under the avatar.
  final String name;

  /// The quiet line under the name.
  final String? meta;

  /// The lines of how to reach the owner (an email, a phone), set left to
  /// right in any language.
  final List<String> contact;

  /// What the owner holds, three across at the hero's foot.
  final List<FrostedProfileCount> counts;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: FrostedAvatar(initials, size: FrostedAvatarSize.extraLarge),
        ),
        // `.me-hero .avatar--xl { margin-bottom: 8px }` and the hero's
        // gap 6.
        const SizedBox(
          height:
              FrostedChromeMetrics.profileAvatarGap +
              FrostedChromeMetrics.profileGap,
        ),
        Semantics(
          header: true,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: t.textTheme.headlineLarge.line(31).tracked(-0.025),
          ),
        ),
        if (meta case final line?) ...[
          const SizedBox(height: FrostedChromeMetrics.profileGap),
          Text(
            line,
            textAlign: TextAlign.center,
            style: t.textTheme.bodyMedium,
          ),
        ],
        if (contact.isNotEmpty) ...[
          const SizedBox(height: FrostedChromeMetrics.profileGap),
          // Addresses and numbers read left to right in any language: under
          // a right-to-left page "+1 (415) 555-0142" showed as
          // "555-0142 (415) 1+" (self-review round 3).
          Text(
            contact.join('\n'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: t.textTheme.bodyMedium.c(t.colorScheme.textTertiary),
          ),
        ],
        if (counts.isNotEmpty) ...[
          const SizedBox(height: FrostedChromeMetrics.profileFactsGap),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.colorScheme.border)),
            ),
            padding: const EdgeInsets.only(
              top: FrostedChromeMetrics.profileFactsGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final c in counts)
                  Expanded(
                    child: MergeSemantics(
                      child: Column(
                        spacing: FrostedChromeMetrics.keyValueLineGap,
                        children: [
                          Text('${c.count}', style: t.textTheme.stat),
                          Text(
                            c.label,
                            textAlign: TextAlign.center,
                            style: t.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    return Semantics(
      container: true,
      label: name,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.only(top: FrostedChromeMetrics.profileTop),
        child: SizedBox(width: double.infinity, child: words),
      ),
    );
  }
}

/// Overlapping avatars for the people of a group: each person's initials on
/// a pearl, [size] across, the next covering 28% of the last and each cut
/// clear of the next by a 2 px gap, so the glass under the group shows
/// between them (a gap is cut, never painted in the ground's colour). Past [max] the rest fold into one
/// round of the wash printing `+N`; [total] says how many there are when
/// the page holds only the first few. Read aloud as one image naming who is
/// shown and how many more.
///
/// ```dart
/// FrostedAvatarGroup(const ['Maren Holt', 'Jonas Reyes', 'Ines Park'], total: 7)
/// ```
class FrostedAvatarGroup extends StatelessWidget {
  /// Creates a [FrostedAvatarGroup].
  const FrostedAvatarGroup(
    this.names, {
    this.size = FrostedChromeMetrics.avatarStack,
    this.max = 4,
    this.total,
    super.key,
  });

  /// The people shown, in order.
  final List<String> names;

  /// Each circle's outer size, its ring of ground included.
  final double size;

  /// How many faces show before the rest fold into `+N`.
  final int max;

  /// How many people there are in all, where the page holds only some.
  final int? total;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final shown = names.take(max).toList();
    final more = (total ?? names.length) - shown.length;
    final step = size * (1 - FrostedChromeMetrics.avatarStackOverlap);
    final count = shown.length + (more > 0 ? 1 : 0);
    final inner = size - FrostedChromeMetrics.avatarStackRing * 2;
    const gap = FrostedChromeMetrics.avatarStackRing;
    // The next round's centre, along the reading direction.
    final next = Directionality.of(context) == TextDirection.rtl ? -step : step;
    // Each round but the top one is cut clear of the next, grown by the gap.
    Widget ringed(Widget child, {required bool top}) => Padding(
      padding: const EdgeInsets.all(gap),
      child: top
          ? child
          : ClipPath(
              clipper: FrostedCutClipper(
                (size) =>
                    Path()..addOval((Offset(next, 0) & size).inflate(gap)),
                (next, gap),
              ),
              child: child,
            ),
    );
    return Semantics(
      image: true,
      label: more > 0 ? '${shown.join(', ')} and $more more' : shown.join(', '),
      child: ExcludeSemantics(
        child: SizedBox(
          height: size,
          width: count == 0 ? 0 : size + (count - 1) * step,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (i, name) in shown.indexed)
                PositionedDirectional(
                  start: i * step,
                  child: ringed(
                    top: i == shown.length - 1 && more <= 0,
                    SizedBox.square(
                      dimension: inner,
                      child: FrostedFace(
                        material: FrostedMaterial.paint,
                        radius: BorderRadius.circular(inner / 2),
                        gradients: [t.pearl.avatarGradient],
                        edge: t.glass.edge,
                        child: Center(
                          child: frostedCapCentred(
                            Text(
                              FrostedFormat.initials(name),
                              maxLines: 1,
                              textScaler: TextScaler.noScaling,
                              style: t.textTheme.monogram
                                  .at(inner * 0.36)
                                  .c(t.pearl.text)
                                  .copyWith(height: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (more > 0)
                PositionedDirectional(
                  start: shown.length * step,
                  child: ringed(
                    top: true,
                    SizedBox.square(
                      dimension: inner,
                      child: FrostedFace(
                        material: FrostedMaterial.paint,
                        radius: BorderRadius.circular(inner / 2),
                        color: t.glass.wash,
                        edge: t.glass.edge,
                        child: Center(
                          child: Text(
                            '+$more',
                            maxLines: 1,
                            // "+5" in any language, never "5+".
                            textDirection: TextDirection.ltr,
                            textScaler: TextScaler.noScaling,
                            style: t.textTheme.monoSmall
                                .at(inner * 0.34)
                                .copyWith(height: 1),
                          ),
                        ),
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
}
