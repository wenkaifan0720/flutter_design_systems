/// Badges: the dot and the count (CONTRACT §4.1 `badge`), ported from
/// Compose material3 1.5.0-alpha29 `Badge.kt`: [ExpressiveBadge] (Compose's
/// `Badge`), which with a `child` stands on the top end corner of it as
/// Compose's `BadgedBox` does — a navigation item's icon, a tab's label, an
/// icon button, anything.
///
/// Geometry, colours and type are `BadgeTokens`; the offsets and the count
/// badge's padding are what `Badge.kt` sets in code (`BadgeBehavior`).
///
/// Deviation from Compose: `BadgedBox` also clamps the badge inside the
/// nearest `badgeBounds()` (a navigation item's, a tab's) through rulers; a
/// Flutter layout cannot read an ancestor's box while it lays out, so the
/// badge stands at its offsets alone. Every navigation item and tab here
/// is wider than its icon plus a badge, so the clamp never binds in them.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../elevation.dart';
import '../icons.dart';
import '../internal/badge_anchor.dart';
import '../internal/cap_label.dart';
import '../internal/tokens/badge_tokens.g.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/chips_tokens.g.dart';
import '../spacing.dart';
import '../theme.dart';
import 'feedback.dart' show ExpressiveTone;

/// A badge (Compose `Badge`): a 6dp error-coloured dot, or with a [label]
/// a 16dp-tall pill of `labelSmall` text in `onError` — a count, "999+",
/// "New".
///
/// Give it a [child] to stand it on the child's top end corner, as
/// Flutter's `Badge` does; a navigation item or a tab takes one as its
/// `badge`.
class ExpressiveBadge extends StatelessWidget {
  /// A dot, or with [label] a count badge.
  const ExpressiveBadge({
    this.label,
    this.semanticLabel,
    this.style,
    this.child,
    super.key,
  });

  /// A count badge: [count], or `"$max+"` above [max] (Material's guidance:
  /// up to four characters, "999+").
  const ExpressiveBadge.count(
    int count, {
    int max = defaultMax,
    this.semanticLabel,
    this.style,
    this.child,
    super.key,
  }) : assert(count >= 0, 'a badge counts from 0'),
       label = count > max ? '$max+' : '$count';

  /// Stateful visual overrides before the badge theme.
  final ExpressiveComponentThemeData? style;

  /// What the badge stands on (Compose's `BadgedBox` anchor): the box is
  /// the child's size; a dot stands 6dp in from the end edge and 6dp down
  /// from the top, a count badge 12dp in and 14dp down from its bottom —
  /// over the edge, as Material draws it. The badge paints over the child
  /// and is not hit-tested; the child keeps the target. Null draws the
  /// badge alone.
  final Widget? child;

  /// The largest count shown as itself: above it, "999+".
  static const int defaultMax = 999;

  /// The count or short label; null draws the dot.
  final String? label;

  /// What a screen reader says for the badge ("3 new messages"); the label
  /// alone when null. Compose's samples set it on the badge's semantics.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    final face = _face(context);
    return child == null
        ? face
        : ExpressiveBadgeAnchor(badge: face, child: child);
  }

  Widget _face(BuildContext context) {
    final t = context.expressiveTheme;
    final label = this.label;
    final resolved = t.badgeTheme.merge(style);
    const states = <WidgetState>{};
    if (label == null) {
      final minimum = resolved.minimumSize?.resolve(states);
      return Semantics(
        label: semanticLabel,
        child: SizedBox(
          width: minimum?.width ?? BadgeTokens.size,
          height: minimum?.height ?? BadgeTokens.size,
          child: ExpressiveSurface(
            style: style,
            componentStyle: t.badgeTheme,
            shape: const CircleBorder(),
            color: t.colors.role(BadgeTokens.color),
            child: const SizedBox(),
          ),
        ),
      );
    }
    // The count's side padding grows with its text, so the full corners
    // (BadgeTokens.LargeShape) still clear a scaled label.
    final side =
        BadgeBehavior.contentHorizontalPadding *
        math.max(1.0, MediaQuery.textScalerOf(context).scale(16) / 16);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: t.density.width(BadgeTokens.largeSize, floor: 0),
          minHeight: t.density.height(BadgeTokens.largeSize, floor: 0),
        ),
        child: ExpressiveSurface(
          style: style,
          // A count's tiny pill already uses the minimum safe side padding;
          // compact density cannot remove it.
          componentStyle: ExpressiveComponentThemeData(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: side),
            ),
          ).merge(t.badgeTheme),
          shape: t.shapes.full,
          color: t.colors.role(BadgeTokens.largeColor),
          contentColor: t.colors.role(BadgeTokens.largeLabelTextColor),
          padding: EdgeInsets.symmetric(horizontal: side),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              expressiveFaceLabel(
                Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: t.type
                      .of(BadgeTokens.largeLabelTextFont)
                      .merge(resolved.textStyle?.resolve(states))
                      .copyWith(
                        color:
                            resolved.foregroundColor?.resolve(states) ??
                            t.colors.role(BadgeTokens.largeLabelTextColor),
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

/// A short label on a thing — New, Fixed, a kind — that does nothing when
/// pressed: a chip's height, corners and type in a tonal container, no
/// outline and no press. Material has no tag; an assist chip that took no
/// action would read as one that is broken, so the tag is its own part.
/// Long words stay on one line with an ellipsis; their full label is spoken.
///
/// ```dart
/// ExpressiveTag('New', tone: ExpressiveTone.primary)
/// ```
class ExpressiveTag extends StatelessWidget {
  /// A tag saying [label].
  const ExpressiveTag(
    this.label, {
    this.tone = ExpressiveTone.neutral,
    this.icon,
    this.style,
    super.key,
  });

  /// Stateful visual overrides before the badge theme.
  final ExpressiveComponentThemeData? style;

  /// The words.
  final String label;

  /// The roles it is drawn in.
  final ExpressiveTone tone;

  /// A glyph before the words (one of `ExpressiveSymbols`); none when null.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final (container, content) = switch (tone) {
      ExpressiveTone.neutral => (c.surfaceContainerHighest, c.onSurfaceVariant),
      ExpressiveTone.primary => (c.secondaryContainer, c.onSecondaryContainer),
      ExpressiveTone.error => (c.errorContainer, c.onErrorContainer),
      ExpressiveTone.success => (
        t.status.success.container,
        t.status.success.onContainer,
      ),
      ExpressiveTone.warning => (
        t.status.warning.container,
        t.status.warning.onContainer,
      ),
    };
    final glyph = icon;
    final resolved = t.badgeTheme.merge(style);
    const states = <WidgetState>{};
    final ink = resolved.foregroundColor?.resolve(states) ?? content;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: t.density.height(ChipsTokens.height),
      ),
      child: ExpressiveSurface(
        style: style,
        componentStyle: t.badgeTheme,
        shape: t.shapes.of(ChipsTokens.pressedShape),
        color: container,
        contentColor: content,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: ExpressiveSpacing.s12,
          vertical: ExpressiveSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              ExcludeSemantics(
                child: ExpressiveIcon(
                  glyph,
                  size:
                      resolved.iconSize?.resolve(states) ??
                      ChipsTokens.leadingIconSize,
                  color: ink,
                ),
              ),
              const SizedBox(width: ExpressiveSpacing.s8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.type
                    .of(ChipsTokens.labelText)
                    .merge(resolved.textStyle?.resolve(states))
                    .copyWith(color: ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
