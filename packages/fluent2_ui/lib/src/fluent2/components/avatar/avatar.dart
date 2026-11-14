import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// How an avatar is coloured, Fluent's `color`: [neutral] the quiet grey
/// (the default), [brand] the brand's fill, [colorful] one of Fluent's
/// thirty named hues picked by the person's name, the same name the same
/// hue everywhere.
enum Fluent2AvatarColor {
  /// The neutral fill.
  neutral,

  /// The brand fill.
  brand,

  /// A fill from Fluent's avatar palette, picked by the name.
  colorful,
}

/// An avatar's outline, Fluent's `shape`: a [circular] person, a [square]
/// group, team or app (its corners stepping with its size).
enum Fluent2AvatarShape {
  /// A circle.
  circular,

  /// A rounded square, for a group or an app.
  square,
}

/// A person's presence, Fluent's `PresenceBadge` statuses.
enum Fluent2Presence {
  /// Available: a green disc with a check.
  available,

  /// Away: a marigold disc with a clock's hands.
  away,

  /// Busy: a red disc.
  busy,

  /// Do not disturb: a red disc with a bar.
  doNotDisturb,

  /// Offline: a grey ring with a cross.
  offline,

  /// Out of office: a berry ring with a back arrow.
  outOfOffice,

  /// Blocked: a red ring with a slash.
  blocked,

  /// Unknown: a grey ring.
  unknown;

  /// What a screen reader says after the person's name.
  String get spoken => switch (this) {
    available => 'available',
    away => 'away',
    busy => 'busy',
    doNotDisturb => 'do not disturb',
    offline => 'offline',
    outOfOffice => 'out of office',
    blocked => 'blocked',
    unknown => 'status unknown',
  };
}

/// The initials Fluent's `getInitials` takes from [name]: the first
/// letters of its first and last words, upper case; one letter when
/// [single]; empty for a name of no letters.
String fluent2Initials(String name, {bool single = false}) {
  final words = [
    for (final w in name.trim().split(RegExp(r'\s+')))
      if (w.isNotEmpty && RegExp(r'[A-Za-z0-9À-￿]').hasMatch(w[0])) w,
  ];
  if (words.isEmpty) return '';
  final first = words.first.characters.first.toUpperCase();
  if (single || words.length == 1) return first;
  return first + words.last.characters.first.toUpperCase();
}

/// The colourful avatar's fill and ink for [name]: Fluent's thirty named
/// hues (`palette<Name>Background2` under `palette<Name>Foreground2`),
/// chosen by Fluent's own hash of the name.
(Color, Color) fluent2AvatarHue(Fluent2ThemeData t, String name) {
  final s = t.sharedColors;
  final hues = <(Color, Color)>[
    (s.paletteDarkRedBackground2, s.paletteDarkRedForeground2),
    (s.paletteCranberryBackground2, s.paletteCranberryForeground2),
    (s.paletteRedBackground2, s.paletteRedForeground2),
    (s.palettePumpkinBackground2, s.palettePumpkinForeground2),
    (s.palettePeachBackground2, s.palettePeachForeground2),
    (s.paletteMarigoldBackground2, s.paletteMarigoldForeground2),
    (s.paletteGoldBackground2, s.paletteGoldForeground2),
    (s.paletteBrassBackground2, s.paletteBrassForeground2),
    (s.paletteBrownBackground2, s.paletteBrownForeground2),
    (s.paletteForestBackground2, s.paletteForestForeground2),
    (s.paletteSeafoamBackground2, s.paletteSeafoamForeground2),
    (s.paletteDarkGreenBackground2, s.paletteDarkGreenForeground2),
    (s.paletteLightTealBackground2, s.paletteLightTealForeground2),
    (s.paletteTealBackground2, s.paletteTealForeground2),
    (s.paletteSteelBackground2, s.paletteSteelForeground2),
    (s.paletteBlueBackground2, s.paletteBlueForeground2),
    (s.paletteRoyalBlueBackground2, s.paletteRoyalBlueForeground2),
    (s.paletteCornflowerBackground2, s.paletteCornflowerForeground2),
    (s.paletteNavyBackground2, s.paletteNavyForeground2),
    (s.paletteLavenderBackground2, s.paletteLavenderForeground2),
    (s.palettePurpleBackground2, s.palettePurpleForeground2),
    (s.paletteGrapeBackground2, s.paletteGrapeForeground2),
    (s.paletteLilacBackground2, s.paletteLilacForeground2),
    (s.palettePinkBackground2, s.palettePinkForeground2),
    (s.paletteMagentaBackground2, s.paletteMagentaForeground2),
    (s.palettePlumBackground2, s.palettePlumForeground2),
    (s.paletteBeigeBackground2, s.paletteBeigeForeground2),
    (s.paletteMinkBackground2, s.paletteMinkForeground2),
    (s.palettePlatinumBackground2, s.palettePlatinumForeground2),
    (s.paletteAnchorBackground2, s.paletteAnchorForeground2),
  ];
  var hash = 0;
  for (var i = name.length - 1; i >= 0; i--) {
    final ch = name.codeUnitAt(i);
    final shift = i % 8;
    hash ^= ((ch << shift) + (ch >> (8 - shift))) & 0xFFFFFFFF;
  }
  return hues[hash.abs() % hues.length];
}

/// Fluent 2's Avatar: a person (or a group, with [Fluent2AvatarShape.square])
/// as their picture ([image]), else the initials of [name] (or [initials])
/// in the size's type, else the person glyph; coloured by [color]; with a
/// [presence] badge at its bottom end, and the brand ring while [active].
/// [size] is one of Fluent's (16 to 128, 32 by default). Read as an image
/// named [name] and its presence; with [onTap] a button.
///
/// ```dart
/// Fluent2Avatar(name: 'Ines Duarte', color: Fluent2AvatarColor.colorful, presence: Fluent2Presence.available)
/// ```
class Fluent2Avatar extends StatelessWidget {
  /// An avatar of [name]: its picture, or its initials.
  const Fluent2Avatar({
    this.name,
    this.initials,
    this.image,
    this.size = 32,
    this.shape = Fluent2AvatarShape.circular,
    this.color = Fluent2AvatarColor.neutral,
    this.presence,
    this.selected = false,
    this.onPressed,
    this.label,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The person's (or the group's) name: spoken, and the initials' source.
  final String? name;

  /// The letters shown; null takes them from [name].
  final String? initials;

  /// The picture; null draws the initials.
  final ImageProvider? image;

  /// The side, in pixels (Fluent's 16, 20, 24, 28, 32, 36, 40, 48, 56, 64,
  /// 72, 96, 120 or 128).
  final double size;

  /// Fluent's `shape`: circular for a person, square for a group or an app.
  final Fluent2AvatarShape shape;

  /// Fluent's `color`: the fill behind the initials.
  final Fluent2AvatarColor color;

  /// The presence badge; null draws none.
  final Fluent2Presence? presence;

  /// The brand ring of a person who is active (speaking, sharing).
  final bool selected;

  /// What a press does (open the profile); null is a picture.
  final VoidCallback? onPressed;

  /// What a screen reader says with [onTap]; null says [name].
  final String? label;

  /// The glyph drawn with neither picture nor initials; null is the
  /// person (or the people, for a square group).
  final IconData? icon;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  /// The initials' type at [size], Fluent's: caption2Strong to 24,
  /// caption1Strong to 28, body1Strong to 40, subtitle2 to 56, subtitle1
  /// to 96, title3 above.
  static TextStyle typeOf(Fluent2ThemeData t, double size) {
    final style = size <= 24
        ? t.caption2Strong
        : size <= 28
        ? t.caption1Strong
        : size <= 40
        ? t.body1Strong
        : size <= 56
        ? t.subtitle2
        : size <= 96
        ? t.subtitle1
        : t.title3;
    // Letters in a disc sit on a line as tall as the type, centred.
    return style.copyWith(height: 1.25);
  }

  /// The badge's diameter at [size], Fluent's `getBadgeSize`: 6 under 28,
  /// 10 to 40, 12 to 56, 16 to 64, 20 to 96, 28 above.
  static double badgeOf(double size) => size >= 96
      ? 28
      : size >= 64
      ? 20
      : size >= 56
      ? 16
      : size >= 40
      ? 12
      : size >= 28
      ? 10
      : 6;

  /// A square avatar's corner at [size], Fluent's: 2 to 24, 4 to 48, 6 to
  /// 72, 8 above.
  static double squareRadius(double size) => size <= 24
      ? Fluent2Radius.small
      : size <= 48
      ? Fluent2Radius.medium
      : size <= 72
      ? Fluent2Radius.large
      : Fluent2Radius.xLarge;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final who = name ?? '';
    final letters = initials ?? fluent2Initials(who, single: size <= 16);
    final (Color fill, Color ink) = switch (color) {
      Fluent2AvatarColor.neutral => (
        t.colors.neutralBackground6,
        t.colors.neutralForeground3,
      ),
      Fluent2AvatarColor.brand => (
        t.colors.brandBackgroundStatic,
        t.colors.neutralForegroundStaticInverted,
      ),
      Fluent2AvatarColor.colorful => fluent2AvatarHue(t, who),
    };
    // The avatar theme's outline, else a circle, draws a circular avatar; a square one keeps Fluent's corner for its size.
    final look = Fluent2StyleOf([t.avatarTheme], const {});
    final outline = shape == Fluent2AvatarShape.circular ? look.shape : null;
    final radius = shape == Fluent2AvatarShape.circular
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(squareRadius(size));
    final img = image;
    Widget face;
    if (img != null) {
      face = Image(
        image: img,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => _letters(t, letters, fill, ink),
      );
    } else {
      face = _letters(t, letters, fill, ink);
    }
    face = outline == null
        ? ClipRRect(
            borderRadius: radius,
            child: SizedBox.square(dimension: size, child: face),
          )
        : ClipPath(
            clipper: ShapeBorderClipper(
              shape: outline,
              textDirection: Directionality.of(context),
            ),
            child: SizedBox.square(dimension: size, child: face),
          );
    if (selected) {
      final ring = size <= 48
          ? 2.0
          : size <= 64
          ? 3.0
          : 4.0;
      final rim = BorderSide(color: t.colors.brandStroke1, width: ring);
      face = Container(
        padding: EdgeInsets.all(ring),
        decoration: outline != null
            ? ShapeDecoration(shape: outline.copyWith(side: rim))
            : BoxDecoration(
                borderRadius: shape == Fluent2AvatarShape.circular
                    ? BorderRadius.circular(size)
                    : BorderRadius.circular(squareRadius(size) + ring * 2),
                border: Border.all(color: rim.color, width: rim.width),
              ),
        child: Padding(padding: EdgeInsets.all(ring / 2), child: face),
      );
    }
    final p = presence;
    if (p != null) {
      face = Stack(
        clipBehavior: Clip.none,
        children: [
          face,
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Fluent2PresenceBadge(p, size: badgeOf(size)),
          ),
        ],
      );
    }
    final spoken = [
      if (who.isNotEmpty) who else if (letters.isNotEmpty) letters,
      if (p != null) p.spoken,
    ].join(', ');
    final tap = onPressed;
    if (tap == null) {
      return Semantics(
        image: true,
        label: spoken.isEmpty ? null : spoken,
        excludeSemantics: true,
        child: face,
      );
    }
    return Fluent2HitSlop(
      child: Fluent2Pressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: tap,
        label: label ?? spoken,
        radius: radius.topLeft.x,
        child: face,
      ),
    );
  }

  Widget _letters(Fluent2ThemeData t, String letters, Color fill, Color ink) =>
      ColoredBox(
        color: fill,
        child: Center(
          child: letters.isEmpty
              ? Icon(
                  icon ??
                      (shape == Fluent2AvatarShape.square
                          ? Fluent2Icons.people
                          : Fluent2Icons.person),
                  size: math.max(12, (size * 0.6).roundToDouble()),
                  color: ink,
                )
              : fluent2CapCentred(
                  Text(
                    letters,
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: typeOf(t, size).c(ink),
                  ),
                ),
        ),
      );
}

/// Fluent 2's PresenceBadge: the person's [presence] as a disc of [size]
/// (6 to 28) in its colour with its mark (the tick of available, the
/// clock of away, the bar of do not disturb, the ring of offline), on a
/// 1 ring of the surface so it reads over an avatar. Spoken by its
/// status; an avatar carrying one speaks it after the name.
///
/// ```dart
/// Fluent2PresenceBadge(Fluent2Presence.busy, size: 12)
/// ```
class Fluent2PresenceBadge extends StatelessWidget {
  /// A badge showing [presence] at [size].
  const Fluent2PresenceBadge(this.presence, {this.size = 12, super.key});

  /// The presence it shows.
  final Fluent2Presence presence;

  /// Its side, in pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final s = t.sharedColors;
    final ring = size >= 20 ? 2.0 : 1.0;
    final (Color hue, bool hollow) = switch (presence) {
      Fluent2Presence.available => (s.paletteLightGreenForeground3, false),
      Fluent2Presence.away => (s.paletteMarigoldBackground3, false),
      Fluent2Presence.busy => (s.paletteRedBackground3, false),
      Fluent2Presence.doNotDisturb => (s.paletteRedBackground3, false),
      Fluent2Presence.offline => (t.colors.neutralForeground3, true),
      Fluent2Presence.outOfOffice => (s.paletteBerryForeground3, true),
      Fluent2Presence.blocked => (s.paletteRedBackground3, true),
      Fluent2Presence.unknown => (t.colors.neutralForeground3, true),
    };
    return Semantics(
      label: presence.spoken,
      excludeSemantics: true,
      child: Container(
        width: size + ring * 2,
        height: size + ring * 2,
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(
          color: t.colors.neutralBackground1,
          shape: BoxShape.circle,
        ),
        child: CustomPaint(
          size: Size.square(size),
          painter: _PresencePainter(
            presence: presence,
            hue: hue,
            hollow: hollow,
            mark: t.colors.neutralBackground1,
          ),
        ),
      ),
    );
  }
}

class _PresencePainter extends CustomPainter {
  _PresencePainter({
    required this.presence,
    required this.hue,
    required this.hollow,
    required this.mark,
  });

  final Fluent2Presence presence;
  final Color hue;
  final bool hollow;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final w = math.max(1.0, size.width / 8);
    if (hollow) {
      canvas.drawCircle(
        c,
        r - w / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = hue,
      );
    } else {
      canvas.drawCircle(c, r, Paint()..color = hue);
    }
    if (size.width < 10) return;
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = hollow ? hue : mark;
    final u = size.width;
    switch (presence) {
      case Fluent2Presence.available:
        canvas.drawPath(
          Path()
            ..moveTo(u * 0.3, u * 0.52)
            ..lineTo(u * 0.44, u * 0.66)
            ..lineTo(u * 0.7, u * 0.38),
          ink,
        );
      case Fluent2Presence.away:
        canvas.drawPath(
          Path()
            ..moveTo(u * 0.5, u * 0.28)
            ..lineTo(u * 0.5, u * 0.52)
            ..lineTo(u * 0.66, u * 0.62),
          ink,
        );
      case Fluent2Presence.doNotDisturb:
        canvas.drawLine(Offset(u * 0.3, r), Offset(u * 0.7, r), ink);
      case Fluent2Presence.offline:
        canvas.drawLine(
          Offset(u * 0.36, u * 0.36),
          Offset(u * 0.64, u * 0.64),
          ink,
        );
        canvas.drawLine(
          Offset(u * 0.64, u * 0.36),
          Offset(u * 0.36, u * 0.64),
          ink,
        );
      case Fluent2Presence.outOfOffice:
        canvas.drawPath(
          Path()
            ..moveTo(u * 0.52, u * 0.32)
            ..lineTo(u * 0.34, u * 0.5)
            ..lineTo(u * 0.52, u * 0.68)
            ..moveTo(u * 0.34, u * 0.5)
            ..lineTo(u * 0.68, u * 0.5),
          ink,
        );
      case Fluent2Presence.blocked:
        canvas.drawLine(
          Offset(u * 0.3, u * 0.7),
          Offset(u * 0.7, u * 0.3),
          ink,
        );
      case Fluent2Presence.busy:
      case Fluent2Presence.unknown:
        break;
    }
  }

  @override
  bool shouldRepaint(_PresencePainter old) =>
      old.presence != presence || old.hue != hue || old.mark != mark;
}

/// How a [Fluent2AvatarGroup] lays its people, Fluent's `layout`: [stack]
/// overlapping, each over a ring of the surface; [spread] side by side
/// with a gap.
enum Fluent2AvatarGroupLayout {
  /// Overlapping, each over the next.
  stack,

  /// Side by side, apart.
  spread,
}

/// One person of a [Fluent2AvatarGroup].
@immutable
class Fluent2AvatarPerson {
  /// A person called [name].
  const Fluent2AvatarPerson(this.name, {this.image, this.initials});

  /// The person's name: spoken, and the initials' source.
  final String name;

  /// The person's picture; null draws the initials.
  final ImageProvider? image;

  /// The letters shown; null takes them from [name].
  final String? initials;
}

/// Fluent 2's AvatarGroup: up to [max] of [people] as colourful avatars of
/// [size], stacked (each overlapping the one before by Fluent's step and
/// ringed in neutralBackground2, as Fluent rings them) or spread, then the
/// overflow "+N" in the neutral disc. Read as one image: the names shown
/// and how many more. With [onTap] (open the list of everyone) a button.
///
/// ```dart
/// Fluent2AvatarGroup(people: [Fluent2AvatarPerson('Ines Duarte'), Fluent2AvatarPerson('Kai Tanaka'), Fluent2AvatarPerson('Mara Okafor')], max: 3)
/// ```
class Fluent2AvatarGroup extends StatelessWidget {
  /// A group of [people]'s avatars.
  const Fluent2AvatarGroup({
    required this.people,
    this.max = 4,
    this.size = 32,
    this.layout = Fluent2AvatarGroupLayout.stack,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The people, in order.
  final List<Fluent2AvatarPerson> people;

  /// The most avatars drawn before the overflow; the overflow takes the
  /// last place when there are more.
  final int max;

  /// Each avatar's side, in pixels.
  final double size;

  /// Stacked or spread.
  final Fluent2AvatarGroupLayout layout;

  /// Called when the group is pressed (to list everyone); null makes it an
  /// image.
  final VoidCallback? onPressed;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  /// The overlap of a stacked group at [size], Fluent's: 2 to 20, 4 to
  /// 32, 8 to 56, 12 to 72, 16 above.
  static double overlapOf(double size) => size <= 20
      ? 2
      : size <= 32
      ? 4
      : size <= 56
      ? 8
      : size <= 72
      ? 12
      : 16;

  /// The gap of a spread group at [size]: 4 to 24, 8 to 56, 12 above.
  static double gapOf(double size) => size <= 24
      ? 4
      : size <= 56
      ? 8
      : 12;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final more = people.length > max;
    final shown = more ? people.take(max - 1).toList() : people;
    final rest = people.length - shown.length;
    final stack = layout == Fluent2AvatarGroupLayout.stack;
    final ring = stack ? (size <= 24 ? 1.0 : 2.0) : 0.0;
    final step = stack ? size - overlapOf(size) : size + gapOf(size);
    final count = shown.length + (more ? 1 : 0);
    final width = count == 0 ? 0.0 : step * (count - 1) + size + ring * 2;
    Widget disc(Widget child) => Container(
      width: size + ring * 2,
      height: size + ring * 2,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        color: stack ? t.colors.neutralBackground2 : null,
        shape: BoxShape.circle,
      ),
      child: child,
    );
    final children = <Widget>[
      for (final (i, p) in shown.indexed)
        PositionedDirectional(
          start: i * step,
          top: 0,
          child: disc(
            Fluent2Avatar(
              name: p.name,
              initials: p.initials,
              image: p.image,
              size: size,
              color: Fluent2AvatarColor.colorful,
            ),
          ),
        ),
      if (more)
        PositionedDirectional(
          start: shown.length * step,
          top: 0,
          child: disc(
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.colors.neutralBackground1,
                shape: BoxShape.circle,
                border: Border.all(color: t.colors.neutralStroke1),
              ),
              child: fluent2CapCentred(
                Text(
                  '+$rest',
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: Fluent2Avatar.typeOf(
                    t,
                    size,
                  ).c(t.colors.neutralForeground1),
                ),
              ),
            ),
          ),
        ),
    ];
    final names = shown.map((p) => p.name).join(', ');
    final spoken = rest > 0 && more ? '$names and $rest more' : names;
    final group = SizedBox(
      width: width,
      height: size + ring * 2,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
    final tap = onPressed;
    if (tap == null) {
      return Semantics(
        image: true,
        label: spoken,
        excludeSemantics: true,
        child: group,
      );
    }
    return Fluent2Pressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: tap,
      label: spoken,
      radius: size / 2,
      child: group,
    );
  }
}

/// Fluent 2's Persona: an avatar of [size] with its [presence], beside the
/// person's [name] (body1, or the size's larger type) over a [secondary]
/// line and a [tertiary] one in the quieter inks. Read as one: the name,
/// the presence and the lines.
///
/// ```dart
/// Fluent2Persona(name: 'Ines Duarte', secondary: 'Design lead', presence: Fluent2Presence.available)
/// ```
class Fluent2Persona extends StatelessWidget {
  /// A persona for [name]: an avatar beside their name and its lines.
  const Fluent2Persona({
    required this.name,
    this.secondary,
    this.tertiary,
    this.image,
    this.presence,
    this.size = 40,
    this.color = Fluent2AvatarColor.colorful,
    super.key,
  });

  /// The person's name, the first line.
  final String name;

  /// The second line (a role, an email); null shows none.
  final String? secondary;

  /// The third line (a status); null shows none.
  final String? tertiary;

  /// The person's picture; null draws the initials.
  final ImageProvider? image;

  /// The presence badge; null draws none.
  final Fluent2Presence? presence;

  /// The avatar's side: 20 to 32 sets one line, 40 and 56 two or three.
  final double size;

  /// Fluent's `color`: the avatar's fill behind the initials.
  final Fluent2AvatarColor color;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final big = size >= 56;
    final first = big ? t.subtitle2 : t.body1;
    final firstLine = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: first,
    );
    final firstHeight = first.fontSize! * first.height!;
    final lines = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fluent's secondary line stands 2 up into the name's line box
        // (`margin-top: -2px`): the name keeps 2 less of the column.
        if (secondary != null)
          Align(
            alignment: AlignmentDirectional.topStart,
            widthFactor: 1,
            heightFactor: (firstHeight - Fluent2Spacing.xxs) / firstHeight,
            child: firstLine,
          )
        else
          firstLine,
        if (secondary != null)
          Text(
            secondary!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption1.c(t.colors.neutralForeground2),
          ),
        if (tertiary != null)
          Text(
            tertiary!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.caption1.c(t.colors.neutralForeground3),
          ),
      ],
    );
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: size <= 32 ? Fluent2Spacing.s : Fluent2Spacing.m,
        children: [
          Fluent2Avatar(
            name: name,
            image: image,
            size: size,
            color: color,
            presence: presence,
          ),
          Flexible(child: lines),
        ],
      ),
    );
  }
}
