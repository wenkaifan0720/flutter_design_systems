// People: initials or a caller-supplied portrait, a compact row and a cast standing in a line.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import 'layout.dart';
import 'theme.dart';

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.width, this.dashed);
  final Color color;
  final double width;
  final bool dashed;
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.shortestSide / 2 - width / 2;
    final c = s.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    if (!dashed) {
      canvas.drawCircle(c, r, p);
      return;
    }
    final n = math.max(8, (2 * math.pi * r / (width * 3)).round());
    final sweep = 2 * math.pi / n;
    final box = Rect.fromCircle(center: c, radius: r);
    for (var i = 0; i < n; i++) {
      canvas.drawArc(box, i * sweep, sweep * .6, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.color != color || o.width != width || o.dashed != dashed;
}

/// A person in a ring: a picture from a media slot if you have one, a portrait widget if you supply one, or else their initials. Any
/// name goes in [label]. [isCurrentUser] is the viewer, marked in the act colour. [out] is someone who isn't coming: a dashed ghost.
/// It keeps its size at its column's start.
/// Use `ComicPerson.seeded('Sam Doe')` to derive the initials from a name.
///
/// ```dart
/// ComicPerson(initials: 'AB', size: 36)
/// ```
class ComicPerson extends StatelessWidget {
  /// Creates a [ComicPerson].
  const ComicPerson({
    super.key,
    this.initials,
    this.portrait,
    this.slotId,
    this.isCurrentUser = false,
    this.out = false,
    this.size = 36,
    this.label,
    this.fillIndex = 0,
  });

  /// Uses the first letters of the name as a monogram.
  factory ComicPerson.seeded(
    String name, {
    Key? key,
    bool isCurrentUser = false,
    bool out = false,
    double size = 36,
  }) => ComicPerson(
    key: key,
    initials: name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join(),
    isCurrentUser: isCurrentUser,
    out: out,
    size: size,
    label: name,
  );

  /// [initials]: letters shown when no portrait is supplied. [slotId]: the host image slot supplying this picture. [label]: the visible or spoken name of the component.
  final String? initials, slotId, label;

  /// An optional caller-supplied portrait widget.
  final Widget? portrait;

  /// [isCurrentUser]: marks content that belongs to the current viewer. [out]: marks a person as unavailable with a dashed ring.
  final bool isCurrentUser, out;

  /// The visual size in logical pixels.
  final double size;

  /// With initials: which of three fills (lamp, shade's tint, you).
  final int fillIndex;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final ring = size <= 30 ? t.rule(2) : t.rim(2.5);
    final fill = isCurrentUser ? c.currentUserHead : c.head;
    final monoFill = switch (fillIndex % 3) {
      0 => c.caption,
      1 => c.monogramSecondary,
      _ => c.monogramTertiary,
    };
    // The letters keep inside the square the round head holds, so large text shrinks them there rather than over
    // the ring.
    final monogram = Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          size * .15,
          size * .15 + 1,
          size * .15,
          size * .15,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            (initials ?? '?').toUpperCase(),
            maxLines: 1,
            style: t.type.letter(
              size * .44,
              lineHeight: 1,
              color: c.onCaption,
              tracking: .04,
            ),
          ),
        ),
      ),
    );
    final Widget inside = slotId != null
        ? MediaSlotImage(
            slotId: slotId!,
            fit: BoxFit.cover,
            fallback: ColoredBox(color: monoFill, child: monogram),
          )
        : portrait != null
        ? ColoredBox(color: fill, child: portrait!)
        : ColoredBox(color: monoFill, child: monogram);
    final ringInk = isCurrentUser ? c.currentUserHeadRing : c.headRing;
    final head = CustomPaint(
      foregroundPainter: _RingPainter(ringInk, ring, out),
      child: ClipOval(child: inside),
    );
    return comicOwnSize(
      width: size,
      height: size,
      child: Semantics(
        image: true,
        label: label ?? initials,
        child: out ? Opacity(opacity: c.dark ? .72 : .55, child: head) : head,
      ),
    );
  }
}

/// A row of people, tightly. Past [max] it counts the rest as a small "+3". An empty list draws nothing. [overlap] is the
/// group's stack. It stays on one line, at its column's start.
///
/// ```dart
/// ComicPeople(const [ComicPerson(initials: 'AB', size: 28), ComicPerson(initials: 'CD', size: 28)])
/// ```
class ComicPeople extends StatelessWidget {
  /// Creates a [ComicPeople].
  const ComicPeople(
    this.people, {
    super.key,
    this.max = 5,
    this.overlap = false,
  });

  /// People displayed beside this content.
  final List<ComicPerson> people;

  /// The greatest number of people shown before a remaining-count label.
  final int max;

  /// Overlaps neighboring portraits.
  final bool overlap;
  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final shown = people.take(max).toList();
    final more = people.length - shown.length;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown.length; i++)
            overlap && i > 0
                ? Align(
                    widthFactor: .75,
                    alignment: AlignmentDirectional.centerEnd,
                    child: shown[i],
                  )
                : Padding(
                    padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 3),
                    child: shown[i],
                  ),
          if (more > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 5),
              child: Text(
                '+$more',
                style: t.type.text(
                  12,
                  1,
                  weight: FontWeight.w800,
                  tracking: .04,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One of a lineup: a name, a portrait widget, or a picture from a media slot, and whether it's you.
class ComicCast {
  /// Creates a [ComicCast].
  const ComicCast(
    this.name, {
    this.portrait,
    this.slotId,
    this.isCurrentUser = false,
  });

  /// The displayed name of this record or person.
  final String name;

  /// An optional caller-supplied portrait widget.
  final Widget? portrait;

  /// The host image slot supplying this picture.
  final String? slotId;

  /// Marks content that belongs to the current viewer.
  final bool isCurrentUser;
}

class _Figure extends StatelessWidget {
  const _Figure(this.who);
  final ComicCast who;
  @override
  Widget build(BuildContext context) {
    if (who.slotId != null) {
      final c = ComicTheme.of(context).colors;
      return MediaSlotImage(
        slotId: who.slotId!,
        fit: BoxFit.cover,
        fallback: ColoredBox(color: c.head),
      );
    }
    return who.portrait ??
        Center(
          child: ComicPerson.seeded(
            who.name,
            size: 64,
            isCurrentUser: who.isCurrentUser,
          ),
        );
  }
}

/// A cast standing in a line, shoulder to shoulder, each over a name plate. On a phone their shoulders overlap a little, as a
/// cover's do. An empty list draws nothing. Names scale down to their plate rather than wrap.
///
/// ```dart
/// ComicLineup(const [ComicCast('Sam', isCurrentUser: true), ComicCast('Alex')])
/// ```
class ComicLineup extends StatelessWidget {
  /// Creates a [ComicLineup].
  const ComicLineup(this.cast, {super.key});

  /// The people shown in the lineup, in order.
  final List<ComicCast> cast;
  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final c = t.colors;
    final sized = t.desk ? 20.0 : 16.0;
    final over = t.desk ? 1.0 : 1.16;
    return ComicEqualRow(
      flex: List.filled(cast.length, 1),
      children: [
        for (var i = 0; i < cast.length; i++)
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final who = cast[i];
              return ComicColumn(
                children: [
                  ComicGrow(child: const SizedBox.shrink()),
                  comicOwnSize(
                    width: w,
                    height: w * over,
                    child: OverflowBox(
                      maxWidth: w * over,
                      maxHeight: w * over,
                      child: _Figure(who),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: who.isCurrentUser ? c.primary : c.paper,
                      border: BorderDirectional(
                        top: BorderSide(color: c.outline, width: t.rim(3)),
                        start: i == 0
                            ? BorderSide.none
                            : BorderSide(color: c.outline, width: t.rule(1.5)),
                        end: i == cast.length - 1
                            ? BorderSide.none
                            : BorderSide(color: c.outline, width: t.rule(1.5)),
                      ),
                    ),
                    child: Padding(
                      padding: t.desk
                          ? const EdgeInsets.fromLTRB(2, 10, 2, 5)
                          : const EdgeInsets.fromLTRB(2, 8, 2, 3),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          who.name.toUpperCase(),
                          maxLines: 1,
                          style: t.type.letter(
                            sized,
                            lineHeight: 1,
                            color: who.isCurrentUser ? c.onPrimary : c.onPaper,
                            tracking: .06,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
