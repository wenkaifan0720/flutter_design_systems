import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

/// A person, round: their [image] when there is one, else the initials of
/// their [name] in ink on a pale tint. A screen reader hears the name; put
/// the name in words beside it too, where it matters who it is.
///
/// Reads [CivicStyle]'s fill (the tint), foreground (the initials) and
/// textStyle: its `style:`, then [CivicThemeData.avatarStyle].
///
/// ```dart
/// CivicAvatar(name: 'Ana Ruiz')
/// ```
class CivicAvatar extends StatelessWidget {
  /// [name]'s avatar.
  const CivicAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = 40,
    this.style,
  }) : assert(size > 0);

  /// Who it is: "Ana Ruiz". Its first and last words' first letters are
  /// the initials.
  final String name;

  /// Their picture; null, while it loads and when it fails: the initials.
  final ImageProvider? image;

  /// Its width and height.
  final double size;

  /// Overrides for this avatar's look.
  final CivicStyle? style;

  /// [name]'s initials: "Ana Ruiz" is "AR", "Ana" is "A".
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '';
    String first(String w) => String.fromCharCodes(w.runes.take(1));
    final a = first(words.first).toUpperCase();
    return words.length == 1 ? a : a + first(words.last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf([style, t.avatarStyle], const {});
    final initials = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size / 8),
          child: Text(
            initialsOf(name),
            textScaler: TextScaler.noScaling,
            style: context.civicText.label
                .copyWith(fontSize: size * 0.4, height: 1)
                .merge(so.textStyle)
                .copyWith(color: so.foreground ?? t.textPrimary),
          ),
        ),
      ),
    );
    final picture = image;
    return Semantics(
      image: true,
      label: name,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: ColoredBox(
            color: so.fill ?? Color.lerp(t.surface, t.action, 0.14)!,
            child: picture == null
                ? initials
                : Image(
                    image: picture,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    frameBuilder: (context, child, frame, loaded) =>
                        loaded || frame != null ? child : initials,
                    errorBuilder: (context, error, stack) => initials,
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
      ..add(StringProperty('name', name))
      ..add(
        DiagnosticsProperty<ImageProvider>('image', image, defaultValue: null),
      )
      ..add(DoubleProperty('size', size, defaultValue: 40))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// People together, round and overlapping, each ringed in the page's
/// colour: the first [max] of [names], then "+3" for the rest. A screen
/// reader hears them in words: "Ana Ruiz, Ben Okafor and 3 others".
///
/// Reads [CivicThemeData.avatarStyle] as [CivicAvatar] does, and its
/// `style:` for each avatar and the "+3".
///
/// ```dart
/// CivicAvatarGroup(names: ['Ana Ruiz', 'Ben Okafor', 'Chi Lee', 'Dev Rao'])
/// ```
class CivicAvatarGroup extends StatelessWidget {
  /// [names] as a group.
  const CivicAvatarGroup({
    super.key,
    required this.names,
    this.images = const {},
    this.max = 3,
    this.total,
    this.size = 32,
    this.othersLabel,
    this.style,
  }) : assert(max > 0 && size > 0);

  /// Who is in it, in order.
  final List<String> names;

  /// Pictures by name; a name without one shows its initials.
  final Map<String, ImageProvider> images;

  /// How many avatars show before "+3".
  final int max;

  /// How many people there are, when more than [names]; null:
  /// [names]' length.
  final int? total;

  /// Each avatar's width and height.
  final double size;

  /// What a screen reader hears for the shown [names] and [others] more;
  /// null: "Ana Ruiz, Ben Okafor and 3 others".
  final String Function(List<String> shown, int others)? othersLabel;

  /// Overrides for the avatars' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf([style, t.avatarStyle], const {});
    final shown = names.take(max).toList();
    final count = total ?? names.length;
    final others = (count - shown.length).clamp(0, count);
    final words = othersLabel?.call(shown, others) ?? _say(shown, others);
    const ring = 2.0;
    Widget ringed(Widget child) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: t.background, width: ring),
      ),
      child: Padding(padding: const EdgeInsets.all(ring), child: child),
    );
    // An eighth of each round lies under the next, clear of its initials,
    // so every one stays readable.
    final step = size * 0.875;
    final outer = size + 2 * ring;
    final pieces = [
      for (final n in shown)
        ringed(
          CivicAvatar(name: n, image: images[n], size: size, style: style),
        ),
      if (others > 0)
        ringed(
          SizedBox.square(
            dimension: size,
            child: ClipOval(
              child: ColoredBox(
                color: so.fill ?? t.textPrimary,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        '+$others',
                        textScaler: TextScaler.noScaling,
                        style: context.civicText.label.copyWith(
                          fontSize: size * 0.38,
                          height: 1,
                          color: so.foreground ?? t.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    return Semantics(
      label: words,
      excludeSemantics: true,
      child: SizedBox(
        width: pieces.isEmpty ? 0 : outer + step * (pieces.length - 1),
        height: outer,
        child: Stack(
          children: [
            for (final (i, p) in pieces.indexed)
              PositionedDirectional(start: step * i, top: 0, child: p),
          ],
        ),
      ),
    );
  }

  static String _say(List<String> shown, int others) {
    if (others == 0) {
      if (shown.length < 2) return shown.join();
      return '${shown.sublist(0, shown.length - 1).join(', ')} and '
          '${shown.last}';
    }
    final rest = others == 1 ? '1 other' : '$others others';
    return '${shown.join(', ')} and $rest';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('names', names))
      ..add(IntProperty('max', max, defaultValue: 3))
      ..add(IntProperty('total', total, defaultValue: null))
      ..add(DoubleProperty('size', size, defaultValue: 32))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
