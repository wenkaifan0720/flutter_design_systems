// People on small moulded round caps, with names carried through image failures.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'frames.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'layout.dart';
import 'localizations.dart';
import 'theme.dart';

String _initials(String value) => value.characters.take(3).toString();
double _diameter(BuildContext context, String initials, double size) {
  final painter = TextPainter(
    text: TextSpan(
      text: initials,
      style: NeumorphicTheme.of(context).textTheme.micro
          .copyWith(fontWeight: FontWeight.w700),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final result = math.max(size, math.max(painter.width, painter.height) + 16);
  painter.dispose();
  return result;
}

/// A portrait in a moulded cap, with initials until the image loads or if it fails.
///
/// ```dart
/// NeumorphicAvatar('NW', name: 'Nia Walker', image: NetworkImage(url))
/// ```
class NeumorphicAvatar extends StatelessWidget {
  /// Creates a [NeumorphicAvatar].
  const NeumorphicAvatar(
    this.initials, {
    super.key,
    this.image,
    this.size = 40,
    this.selected = false,
    this.name,
    this.style,
  }) : assert(size > 0);

  /// Portrait frame and fallback words before the avatar theme.
  final NeumorphicStyle? style;

  /// The initials shown when no usable image is available.
  final String initials;

  /// The optional image provider; failed images fall back to initials.
  final ImageProvider? image;

  /// The avatar face diameter in logical pixels.
  final double size;

  /// Whether this item is selected.
  final bool selected;

  /// The full accessible name; null falls back to initials.
  final String? name;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final letters = _initials(initials);
    final states = {if (selected) WidgetState.selected};
    final look = NeumorphicStyleOf([style, t.avatarTheme], states);
    final words = t.textTheme.micro
        .copyWith(fontWeight: FontWeight.w700, color: t.colors.ink)
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    final measure = TextPainter(
      text: TextSpan(text: letters, style: words),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    var diameter = math.max(size, math.max(measure.width, measure.height) + 16);
    diameter = math.max(
      diameter,
      math.max(look.minimumSize?.width ?? 0, look.minimumSize?.height ?? 0),
    );
    var shape = look.shape;
    final padding =
        look.padding(Directionality.of(context)) ??
        EdgeInsets.all(selected ? 4 : 3);
    if (shape is NeumorphicCircleBorder) {
      diameter = math.max(
        diameter,
        math.max(
              measure.width + padding.horizontal,
              measure.height + padding.vertical,
            ) *
            math.sqrt2,
      );
    } else if (shape != null) {
      final inset = shape.dimensions.resolve(Directionality.of(context));
      diameter = math.max(
        diameter,
        math.max(
          measure.width + padding.horizontal + inset.horizontal,
          measure.height + padding.vertical + inset.vertical,
        ),
      );
    }
    measure.dispose();
    if (shape is NeumorphicBorder) shape = shape.fit(Size.square(diameter));
    final fallback = Center(child: Text(letters, maxLines: 1, style: words));
    final portrait = image == null
        ? fallback
        : ClipPath(
            clipper: ShapeBorderClipper(
              shape: shape ?? NeumorphicCircleBorder(diameter: diameter),
            ),
            child: Image(
              image: image!,
              fit: BoxFit.cover,
              width: diameter,
              height: diameter,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              frameBuilder: (context, picture, frame, synchronous) =>
                  frame == null ? fallback : picture,
              errorBuilder: (context, error, stack) => fallback,
            ),
          );
    return Semantics(
      image: true,
      label: name ?? initials,
      selected: selected,
      child: ExcludeSemantics(
        child: neumorphicOwnSize(
          width: diameter,
          height: diameter,
          child: NeumorphicSurface(
            style: style,
            themeStyle: t.avatarTheme,
            shape: shape,
            states: states,
            padding: padding,
            cast: selected
                ? NeumorphicSurfaceLevel.groove
                : NeumorphicSurfaceLevel.part,
            round: true,
            outlined: true,
            child: portrait,
          ),
        ),
      ),
    );
  }
}

/// One person's initials, name and optional picture for a face pile.
@immutable
class NeumorphicFace {
  /// Creates a [NeumorphicFace].
  const NeumorphicFace(this.initials, {this.name, this.image});

  /// The initials shown when no usable image is available.
  final String initials;

  /// The full accessible name; null falls back to initials.
  final String? name;

  /// The optional image provider; failed images fall back to initials.
  final ImageProvider? image;
}

/// A few people as one moulded cluster: their faces are bumps cast in one piece of the plaster, like drops that ran
/// together before they set, joined by a soft neck where neighbours meet, and the number of people beyond them is the
/// cluster's last bump. The first face sits in front: a faint crease runs along its rim. Raised from the wall as one
/// piece, with one light and one shadow; with [onPressed] it is a button, and a press sinks the whole cluster.
///
/// ```dart
/// NeumorphicAvatarGroup(const [NeumorphicFace('NW', name: 'Nia Walker'), NeumorphicFace('AK', name: 'Amir Khan')])
/// ```
class NeumorphicAvatarGroup extends StatelessWidget {
  /// Creates a [NeumorphicAvatarGroup].
  const NeumorphicAvatarGroup(
    this.faces, {
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.most = 4,
    this.total,
    this.size = 36,
    this.label,
    this.onPressed,
    this.style,
  }) : assert(most >= 0),
       assert(size > 0);

  /// The cluster's face and the words of its initials and count, before the avatar theme. The cluster keeps its own
  /// round outline: a shape is for a lone [NeumorphicAvatar].
  final NeumorphicStyle? style;

  /// The available face data, in display order.
  final List<NeumorphicFace> faces;

  /// The maximum number of individual faces displayed.
  final int most;

  /// The complete count when only some portraits have been loaded.
  final int? total;

  /// The diameter of each face in logical pixels.
  final double size;

  /// The text identifying this item or control.
  final String? label;

  /// Opens the people behind the group. Null shows the group without a press.
  final VoidCallback? onPressed;

  /// How far each lobe stands from the one before it, as a share of a face: the lobes overlap a little, joined by
  /// filleted necks into one moulded body, and every face sits whole on its own lobe.
  static const double step = .85;

  /// How far a picture stands in from its lobe's rim and from the neck to the next lobe.
  static const double inset = 3;

  /// An optional focus node for the control; it uses its own when null.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final all = math.max(faces.length, total ?? 0);
    if (all == 0) return const SizedBox.shrink();
    final words = NeumorphicLocalizations.of(context);
    final t = NeumorphicTheme.of(context);
    final look = NeumorphicStyleOf([style, t.avatarTheme], const {});
    final shown = faces.take(most).toList();
    final rest = all - shown.length;
    final count = '+${words.formatNumber(rest, maximumFractionDigits: 0)}';
    final diameter = [
      size,
      for (final face in shown)
        _diameter(context, _initials(face.initials), size),
      if (rest > 0) _diameter(context, count, size),
      look.minimumSize?.width ?? 0,
      look.minimumSize?.height ?? 0,
    ].reduce(math.max);
    final length = shown.length + (rest > 0 ? 1 : 0);
    final cluster = _ClusterBorder(
      count: length,
      diameter: diameter,
      step: diameter * step,
      fillet: diameter / 5,
    );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final letters = t.textTheme.micro
        .copyWith(fontWeight: FontWeight.w700, color: t.colors.ink)
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    final names = [
      for (final f in faces) f.name ?? f.initials,
      if (all > faces.length)
        '+${words.formatNumber(all - faces.length, maximumFractionDigits: 0)}',
    ].join(', ');
    // Each face on its own lobe: a circle in from the rim, clear of the neck to the next lobe.
    final own = length < 2
        ? diameter / 2 - inset
        : math.min(diameter / 2 - inset, cluster.step / 2 - inset / 2);
    Widget bump(int i, String initials, ImageProvider? image) {
      final fallback = Center(
        // The count is a number with its sign: it reads "+3" in either direction.
        child: Text(
          initials,
          maxLines: 1,
          style: letters,
          textDirection: initials.startsWith('+') ? TextDirection.ltr : null,
        ),
      );
      return Positioned(
        left: cluster.centre(i, rtl) - own,
        top: diameter / 2 - own,
        width: 2 * own,
        height: 2 * own,
        child: ClipOval(
          child: image == null
              ? fallback
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                  width: 2 * own,
                  height: 2 * own,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                  frameBuilder: (context, picture, frame, synchronous) =>
                      frame == null ? fallback : picture,
                  errorBuilder: (context, error, stack) => fallback,
                ),
        ),
      );
    }

    Widget group = neumorphicOwnSize(
      width: cluster.width,
      height: diameter,
      child: NeumorphicSurface(
        style: style,
        themeStyle: t.avatarTheme,
        shape: cluster,
        cast: NeumorphicSurfaceLevel.part,
        outlined: true,
        child: CustomPaint(
          painter: _Creases(
            cluster,
            t.colors,
            rtl: rtl,
            flat: NeumorphicFlatScope.of(context),
            edge: t.highContrast,
          ),
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                bump(i, _initials(shown[i].initials), shown[i].image),
              if (rest > 0) bump(shown.length, count, null),
            ],
          ),
        ),
      ),
    );
    group = ExcludeSemantics(child: group);
    if (onPressed != null) {
      return NeumorphicTap(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: label ?? names,
        shape: cluster,
        child: group,
      );
    }
    return Semantics(container: true, label: label ?? names, child: group);
  }
}

/// One moulded cluster's outline: [count] round bumps of [diameter] in a row, each [step] on from the last, and where
/// two meet, a concave fillet of [fillet] instead of a corner, so the join reads as a neck of the same material. The
/// fillet's circle touches both bumps, so the outline turns without a corner anywhere.
class _ClusterBorder extends OutlinedBorder {
  const _ClusterBorder({
    super.side,
    required this.count,
    required this.diameter,
    required this.step,
    required this.fillet,
  });
  final int count;
  final double diameter, step, fillet;

  double get width => diameter + step * (count - 1);

  /// The centre of bump [i] across the cluster, the first at the start.
  double centre(int i, bool rtl) {
    final x = diameter / 2 + step * i;
    return rtl ? width - x : x;
  }

  /// How far above and below the axis each fillet's centre sits.
  double get _lift {
    final reach = diameter / 2 + fillet;
    return math.sqrt(math.max(0, reach * reach - step * step / 4));
  }

  /// The angle off the axis at which a fillet meets its bumps.
  double get meet => math.atan2(_lift, step / 2);

  /// How far the neck between two lobes reaches above and below the axis at its narrowest.
  double get neck => _lift - fillet;

  Path _outline(Rect rect, double into) {
    final r = diameter / 2 - into, f = fillet + into;
    final y = rect.center.dy;
    Rect bump(int i) => Rect.fromCircle(
      center: Offset(rect.left + diameter / 2 + step * i, y),
      radius: r,
    );
    if (count < 2) return Path()..addOval(bump(0));
    Rect neck(int i, double side) => Rect.fromCircle(
      center: Offset(
        rect.left + diameter / 2 + step * (i + .5),
        y + side * _lift,
      ),
      radius: f,
    );
    final a = meet;
    final path = Path()..arcTo(bump(0), a, 2 * math.pi - 2 * a, true);
    for (var i = 0; i < count - 1; i++) {
      path.arcTo(neck(i, -1), math.pi - a, 2 * a - math.pi, false);
      final last = i + 2 == count;
      path.arcTo(
        bump(i + 1),
        a - math.pi,
        last ? 2 * math.pi - 2 * a : math.pi - 2 * a,
        false,
      );
    }
    for (var i = count - 2; i >= 0; i--) {
      path.arcTo(neck(i, 1), -a, 2 * a - math.pi, false);
      if (i > 0) path.arcTo(bump(i), a, math.pi - 2 * a, false);
    }
    return path..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _outline(rect, 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _outline(rect, side.strokeInset);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_outline(rect, side.width / 2), side.toPaint());
  }

  @override
  _ClusterBorder copyWith({BorderSide? side}) => _ClusterBorder(
    side: side ?? this.side,
    count: count,
    diameter: diameter,
    step: step,
    fillet: fillet,
  );

  @override
  _ClusterBorder scale(double t) => _ClusterBorder(
    side: side.scale(t),
    count: count,
    diameter: diameter * t,
    step: step * t,
    fillet: fillet * t,
  );

  @override
  bool operator ==(Object other) =>
      other is _ClusterBorder &&
      other.side == side &&
      other.count == count &&
      other.diameter == diameter &&
      other.step == step &&
      other.fillet == fillet;

  @override
  int get hashCode => Object.hash(side, count, diameter, step, fillet);
}

/// The creases: one faint line across each neck, where two lobes of the one body meet. The body keeps one light and
/// one shadow; the crease only says where one face ends. A flat cluster has none; high contrast prints the join.
class _Creases extends CustomPainter {
  _Creases(
    this.cluster,
    this.c, {
    required this.rtl,
    required this.flat,
    required this.edge,
  });
  final _ClusterBorder cluster;
  final NeumorphicColors c;
  final bool rtl, flat, edge;

  @override
  void paint(Canvas canvas, Size size) {
    if (cluster.count < 2 || (flat && !edge)) return;
    final y = size.height / 2;
    // The neck's half height: from the axis to where the fillet comes closest.
    final reach = math.max(0.0, cluster.neck);
    final line = Paint()..style = PaintingStyle.stroke;
    if (edge) {
      line
        ..strokeWidth = neumorphicEdgeWidth
        ..color = c.edge;
    } else {
      line
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c.shadowInset.withValues(alpha: 0),
            c.shadowInset.withValues(alpha: c.shadowInset.a * .45),
            c.shadowInset.withValues(alpha: c.shadowInset.a * .45),
            c.shadowInset.withValues(alpha: 0),
          ],
          stops: const [0, .3, .7, 1],
        ).createShader(Rect.fromLTRB(0, y - reach, size.width, y + reach));
    }
    for (var i = 0; i < cluster.count - 1; i++) {
      final x = (cluster.centre(i, rtl) + cluster.centre(i + 1, rtl)) / 2;
      canvas.drawLine(Offset(x, y - reach), Offset(x, y + reach), line);
    }
  }

  @override
  bool shouldRepaint(_Creases old) =>
      old.cluster != cluster ||
      old.c != c ||
      old.rtl != rtl ||
      old.flat != flat ||
      old.edge != edge;
}
