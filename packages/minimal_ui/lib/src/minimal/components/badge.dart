/// A count, or a dot, on the corner of a glyph or a face.
library;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/styled.dart';
import '../theme.dart';
import 'tag.dart';

/// A count on the corner of what it counts — unread messages on the inbox
/// glyph, a new comment on a face: a 16 px capsule (`shapes.pill`) in the
/// [tone]'s fill with the count in mono, past [max] as "99+"; a neutral
/// count is a neutral tag's, the muted fill in a hairline with the count
/// in the ink. With no [count] it is a 8 px dot: something new, no number
/// (a neutral one in the faint ink). It wears a ring of
/// the ground colour, concentric outside its own edge, so it stays clear
/// of whatever it sits on. Without a [child] it stands alone (a nav row's
/// count).
///
/// [style] dresses one badge, `components.badge` every one: fill,
/// foreground, edge or side (the ring), shape, textStyle and minimumSize.
///
/// ```dart
/// MinimalBadge(count: 3, child: MinimalIcon(LucideIcons.bell))
/// ```
class MinimalBadge extends StatelessWidget {
  /// A count or a dot.
  const MinimalBadge({
    super.key,
    this.count,
    this.child,
    this.max = 99,
    this.tone = MinimalTone.destructive,
    this.label,
    this.style,
  });

  /// The number; null draws a dot.
  final int? count;

  /// What carries the badge on its top-end corner; null stands it alone.
  final Widget? child;

  /// Above this the badge reads "[max]+".
  final int max;

  /// The fill: danger for something to deal with, neutral for a plain
  /// count, a status tone for a status (success for someone online). The
  /// accent belongs to the act to take, so a mark that is none stays off it.
  final MinimalTone tone;

  /// What a screen reader hears ("3 unread"); null says the count.
  final String? label;

  /// This badge's style, over `components.badge`.
  final MinimalStyle? style;

  static const double _height = 16;
  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([style, t.components.badge], const {});
    final n = count;
    final shape =
        so.shape ?? (n == null ? const CircleBorder() : t.shapes.pill);
    final colours = t.tone(tone);
    // A plain count is a neutral tag's: the muted fill in a hairline, the
    // figure in the ink. A mid-grey capsule reads as switched off.
    final plain = n != null && tone == MinimalTone.neutral;
    final fill = so.fill ?? (plain ? t.muted : colours.indicator);
    final ink = so.foreground ?? _on(t, tone);
    // The ring is the ground's colour, drawn outside the edge.
    final ring =
        so.side ??
        BorderSide(
          color: so.edge ?? t.background,
          width: t.focusWidth,
          strokeAlign: BorderSide.strokeAlignOutside,
        );
    final least = so.minimumSize;
    final mark = n == null
        ? Container(
            width: least?.width ?? _dot,
            height: least?.height ?? _dot,
            decoration: minimalFrame(shape, fill: fill, side: ring),
          )
        : Container(
            constraints: BoxConstraints(
              minWidth: least?.width ?? _height,
              minHeight: least?.height ?? _height,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: minimalFrame(shape, fill: fill, side: ring),
            // The plain count's hairline, inside its edge, so it still reads
            // as a capsule where its fill is nearly the ground.
            foregroundDecoration: plain && so.fill == null
                ? minimalFrame(shape, side: t.rule)
                : null,
            // Centred, and hugging: the capsule is as wide as its count,
            // however wide the slot it stands in.
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: minimalCapLabel(
                Text(
                  n > max ? '$max+' : '$n',
                  maxLines: 1,
                  style: so.text(
                    t.mono.copyWith(fontSize: 10.5, height: 1.2).semibold,
                    ink,
                  ),
                ),
              ),
            ),
          );
    final spoken = label ?? (n == null ? null : (n > max ? '$max+' : '$n'));
    final badge = Semantics(
      label: spoken,
      child: ExcludeSemantics(child: mark),
    );
    final host = child;
    // Alone, it keeps its own size in a column that stretches its children.
    if (host == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: badge,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        host,
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: _Corner(
              dot: n == null,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
            child: badge,
          ),
        ),
      ],
    );
  }

  static Color _on(MinimalThemeData t, MinimalTone tone) => switch (tone) {
    MinimalTone.primary => t.primaryForeground,
    MinimalTone.success => t.onSuccess,
    MinimalTone.destructive => t.destructiveForeground,
    // A plain count stands on the muted fill: the ink, about 17:1 by day
    // and 15:1 by night.
    MinimalTone.neutral => t.foreground,
    // Amber takes the dark ink in either mode.
    MinimalTone.warning => t.isLightAppearance ? t.foreground : t.textInverse,
  };
}

/// Where a badge stands on its host's top-end corner. A count's first
/// round end is centred on the corner itself, so it covers no more than
/// that corner of the glyph it counts, at 16 px as at 24, and a longer
/// count ("99+", or any count in large text) grows outward, away from the
/// glyph, rather than across it; a dot overhangs the corner by 1 px.
class _Corner extends SingleChildLayoutDelegate {
  const _Corner({required this.dot, required this.rtl});

  final bool dot;
  final bool rtl;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size child) {
    if (dot) {
      return Offset(rtl ? -1 : size.width + 1 - child.width, -1);
    }
    final cap = child.height / 2;
    return Offset(rtl ? cap - child.width : size.width - cap, -cap);
  }

  @override
  bool shouldRelayout(_Corner old) => old.dot != dot || old.rtl != rtl;
}
