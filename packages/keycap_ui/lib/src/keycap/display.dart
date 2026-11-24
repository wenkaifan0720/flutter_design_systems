/// Keycap's display parts: things read, never pressed. [KeycapAvatar] and
/// [KeycapAvatarGroup] (a person as a flat tile of modifier plastic, their
/// initials printed on it), [KeycapBadge] (a count printed on a small
/// accent tab), [KeycapTag] (a word printed in a small well),
/// [KeycapMedia] (a picture set in a well) and [KeycapDescriptionList]
/// (terms and their values).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import 'cap.dart';
import 'feedback.dart';
import 'theme.dart';

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final letters = [for (final w in words.take(2)) w.characters.first];
  return letters.join().toUpperCase();
}

/// A person: a flat tile of modifier plastic, their initials printed on
/// it, or their picture ([slotId]) set in it. Its corners are a quarter of
/// its size, as a key's are of its height.
///
/// ```dart
/// const KeycapAvatar(name: 'Rosa Ines Vidal')
/// ```
class KeycapAvatar extends StatelessWidget {
  /// An avatar for [name].
  const KeycapAvatar({
    super.key,
    required this.name,
    this.slotId,
    this.size = 40,
    this.style,
  });

  /// The person's name: its initials are printed, and a screen reader hears
  /// it.
  final String name;

  /// Their picture's media slot; initials only when null.
  final String? slotId;

  /// Its side.
  final double size;

  /// Overrides, over [KeycapThemeData.avatarStyle]: [RawStyle.fill] the
  /// tile, [RawStyle.foreground] the initials.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.avatarStyle], const {});
    final r = BorderRadius.circular(size / 4);
    final letters = Center(
      child: Text(
        _initials(name),
        maxLines: 1,
        // Printed on the picture at its size: the picture does not grow
        // with text, so neither do they.
        textScaler: TextScaler.noScaling,
        style: theme.textTheme.label.copyWith(
          fontSize: size * 0.38,
          height: 1,
          fontWeight: FontWeight.w600,
          color: layered.foreground ?? c.modifier.legend,
        ),
      ),
    );
    return Semantics(
      label: name,
      image: slotId != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: layered.fill ?? c.modifier.top,
            borderRadius: r,
            border: Border.all(color: c.edge, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: r,
            child: slotId == null
                ? letters
                : MediaSlotImage(slotId: slotId!, fallback: letters),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('name', name))
      ..add(DoubleProperty('size', size));
  }
}

/// A few people at once: their tiles overlapping, each set off from the
/// next by a ring of the case, and a last tile counting the rest. A screen
/// reader hears the names and how many more.
///
/// ```dart
/// const KeycapAvatarGroup(names: ['Rosa Vidal', 'Tomas Berg', 'Ana Lu', 'Kofi Mensah'], max: 3)
/// ```
class KeycapAvatarGroup extends StatelessWidget {
  /// A group of [names].
  const KeycapAvatarGroup({
    super.key,
    required this.names,
    this.max = 4,
    this.size = 32,
  });

  /// The people.
  final List<String> names;

  /// The most tiles shown before the count.
  final int max;

  /// A tile's side.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final shown = names.take(max).toList();
    final rest = names.length - shown.length;
    const ring = 2.0;
    // Overlapped by a fifth: enough to read as one group, little enough
    // that each face's initials stay whole.
    final step = size * 0.8;
    final count = shown.length + (rest > 0 ? 1 : 0);
    Widget ringed(Widget child) => Container(
      padding: const EdgeInsets.all(ring),
      decoration: BoxDecoration(
        color: c.ground,
        borderRadius: BorderRadius.circular(size / 4 + ring),
      ),
      child: child,
    );
    return Semantics(
      label: rest > 0 ? '${shown.join(', ')} and $rest more' : shown.join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: step * math.max(0, count - 1) + size + 2 * ring,
        height: size + 2 * ring,
        child: Stack(
          children: [
            for (final (i, n) in shown.indexed)
              PositionedDirectional(
                start: i * step,
                child: ringed(KeycapAvatar(name: n, size: size)),
              ),
            if (rest > 0)
              PositionedDirectional(
                start: shown.length * step,
                child: ringed(
                  SizedBox.square(
                    dimension: size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.well,
                        borderRadius: BorderRadius.circular(size / 4),
                      ),
                      child: Center(
                        child: Text(
                          '+$rest',
                          // Printed on a face's size, as initials are.
                          textScaler: TextScaler.noScaling,
                          style: theme.textTheme.figure.copyWith(
                            fontSize: size * 0.36,
                            color: c.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<String>('names', names));
  }
}

/// A count printed on a small tab of accent plastic, set at a glyph's
/// corner or a row's end: unread notes, a sync waiting. [KeycapBadge.dot]
/// is the tab alone. Past 99 it reads "99+".
///
/// ```dart
/// const KeycapBadge(count: 3, semanticLabel: '3 unsynced')
/// ```
class KeycapBadge extends StatelessWidget {
  /// A badge reading [count].
  const KeycapBadge({
    super.key,
    required int this.count,
    this.semanticLabel,
    this.style,
  });

  /// A badge with no figure: something new.
  const KeycapBadge.dot({super.key, this.semanticLabel, this.style})
    : count = null;

  /// The figure; none for a dot.
  final int? count;

  /// What a screen reader hears; the figure when null.
  final String? semanticLabel;

  /// Overrides, over [KeycapThemeData.tagStyle]: [RawStyle.fill] the
  /// tab, [RawStyle.foreground] the figure.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.tagStyle], const {});
    final fill = layered.fill ?? c.accent.top;
    final n = count;
    final child = n == null
        ? SizedBox.square(
            dimension: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          )
        : Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.symmetric(
              horizontal: KeycapSpacing.tight,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
            ),
            // Hugs its figure: an alignment here would stretch it across
            // whatever room its parent offers.
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(
                n > 99 ? '99+' : '$n',
                maxLines: 1,
                style: theme.textTheme.figure.copyWith(
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: layered.foreground ?? c.accent.legend,
                ),
              ),
            ),
          );
    return Semantics(
      label: semanticLabel ?? (n == null ? null : '$n'),
      excludeSemantics: true,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count, defaultValue: null));
  }
}

/// A word printed in a small well cut into the case: a note's state
/// ("Draft", "Shared"), a label on a row. Read, never pressed (a word that
/// is pressed is a [KeycapChip]). [tone] sets its ink.
///
/// ```dart
/// const KeycapTag('Draft')
/// ```
class KeycapTag extends StatelessWidget {
  /// A tag reading [label].
  const KeycapTag(this.label, {super.key, this.tone, this.icon, this.style});

  /// Its word.
  final String label;

  /// Its ink; the muted ink when null.
  final KeycapTone? tone;

  /// A glyph before the word.
  final IconData? icon;

  /// Overrides, over [KeycapThemeData.tagStyle]: [RawStyle.foreground]
  /// its ink, [RawStyle.fill] its floor.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.tagStyle], const {});
    final ink =
        layered.foreground ??
        switch (tone) {
          null => c.ink,
          KeycapTone.info => c.accentInk,
          KeycapTone.success => c.success,
          KeycapTone.warning => c.ink,
          KeycapTone.danger => c.dangerInk,
        };
    return SizedBox(
      height: KeycapMetrics.grown(
        context,
        26,
        theme.textTheme.secondary.copyWith(fontSize: 13, height: 1.2),
      ),
      child: KeycapWell(
        radius: BorderRadius.circular(KeycapMetrics.smallKeyRadius),
        floor: layered.fill,
        padding: const EdgeInsets.symmetric(horizontal: KeycapSpacing.small),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: ink),
              const SizedBox(width: KeycapSpacing.tight),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.secondary.copyWith(
                fontSize: 13,
                height: 1.2,
                color: ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(EnumProperty<KeycapTone>('tone', tone, defaultValue: null));
  }
}

/// A picture set in a well: the app's image for [slotId], inset so its
/// corners run concentric with the well's; [placeholder] on the floor
/// until it loads (or when there is none).
///
/// ```dart
/// const KeycapMedia(slotId: 'note.cover', semanticLabel: 'Sketch of the garden beds')
/// ```
class KeycapMedia extends StatelessWidget {
  /// A picture.
  const KeycapMedia({
    super.key,
    required this.slotId,
    required this.semanticLabel,
    this.aspectRatio = 16 / 9,
    this.placeholder,
  });

  /// The media slot.
  final String slotId;

  /// What the picture shows, for a screen reader.
  final String semanticLabel;

  /// Its width over its height.
  final double aspectRatio;

  /// What shows until it loads (a glyph).
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    const inset = KeycapSpacing.tight;
    final floor = Center(
      child: IconTheme.merge(
        data: IconThemeData(size: 32, color: c.inkDisabled),
        child: placeholder ?? const SizedBox.shrink(),
      ),
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: KeycapWell(
            padding: const EdgeInsets.all(inset),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                KeycapMetrics.wellRadius - inset,
              ),
              child: MediaSlotImage(slotId: slotId, fallback: floor),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('slotId', slotId))
      ..add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

/// Terms and their values (a note's details: created, edited, words),
/// each term in the muted ink over its value below 600 wide, beside it
/// from 600, the pairs divided by hairlines. A screen reader hears each
/// pair as one.
///
/// ```dart
/// const KeycapDescriptionList(items: [(term: 'Created', value: '12 March'), (term: 'Words', value: '1,204')])
/// ```
class KeycapDescriptionList extends StatelessWidget {
  /// A list of [items].
  const KeycapDescriptionList({super.key, required this.items, this.style});

  /// The pairs.
  final List<({String term, String value})> items;

  /// Overrides, over [KeycapThemeData.tableStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.tableStyle], const {});
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final termStyle = theme.textTheme.secondary.copyWith(color: c.inkMuted);
    final valueStyle = theme.textTheme.body
        .merge(layered.textStyle)
        .copyWith(color: layered.foreground ?? c.ink);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, it) in items.indexed) ...[
          if (i > 0) SizedBox(height: 1, child: ColoredBox(color: c.hairline)),
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: KeycapSpacing.medium,
              ),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 180,
                          child: Text(it.term, style: termStyle),
                        ),
                        const SizedBox(width: KeycapSpacing.regular),
                        Expanded(child: Text(it.value, style: valueStyle)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.term, style: termStyle),
                        const SizedBox(height: KeycapSpacing.tight / 2),
                        Text(it.value, style: valueStyle),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('items', items.length));
  }
}
