part of '../alignment.dart';

/// Whether every shadow, glow and rim on a screen shows whole: none is cut
/// flat by a clip round it, and none is square behind a round face.
///
/// A raised face's shadow reaches past its box. A clip above it (a
/// `ClipRect`, a rounded clip, a scroll view's edge, a box round a label and
/// its specimen) cuts the shadow at the clip's edge, a straight line where
/// a soft falloff belongs: the user found Neumorphism's raised parts cut
/// flat at the left by day and at the bottom and right by night. A shadow
/// cast by a square box behind a face with round corners shows as a square
/// corner behind the round one.
///
/// Each box that casts (a decoration with shadows, a physical model with an
/// elevation, a custom paint) is painted alone, with room round it, and
/// read by what it paints past its box: where that reaches past a clip
/// above it by more than [tolerance], and still shows there (its alpha at
/// the clip's edge is at least [visibleAlpha] of 255), it is named, with
/// the clip and how far each reaches. A box partly past the clip itself (a
/// list's row scrolled half out) is the clip check's, [DesignClipCheck].
/// A scroll view's edge along its scroll, with more of its content past
/// it, cuts every row there as it scrolls by: that is scrolling, not a
/// cast with no room. At the end of its content, and across its scroll,
/// the cut still counts: the content has to leave its cast room there.
/// A face with round corners whose shadow reaches as far past the corner's
/// diagonal as a square's would (its shadow's outline turns square behind
/// the curve) is named too.
///
/// It paints and reads pixels, so a test passes its tester's `runAsync`:
///
/// ```dart
/// final report = await const DesignShadowClipCheck(look: 'Comic').check(
///   tester.element(find.byType(SettingsScreen)),
///   runAsync: tester.runAsync,
/// );
/// report.verify();
/// ```
///
/// A press, a hover or a focus changes only its own neighbourhood: a test
/// of one control's moments passes its rect as `near:`, and only the boxes
/// whose cast reaches into it are painted and read, however long the page.
///
/// It reads layout boxes for where a shadow falls and a clip cuts, and the
/// drawn pixels where only they show what a shadow paints, so it takes the
/// tester's `runAsync`.
@immutable
class DesignShadowClipCheck {
  /// A check for [look].
  const DesignShadowClipCheck({
    required this.look,
    this.tolerance = 1,
    this.visibleAlpha = 8,
  });

  /// The look's name, for messages.
  final String look;

  /// How far, in logical pixels, a paint may reach past a clip unseen.
  final double tolerance;

  /// The least alpha, of 255, a shadow's pixel at a clip's edge shows with.
  final int visibleAlpha;

  /// Checks every box under [context] that casts a shadow, a glow or a
  /// rim. A test passes its tester's `runAsync` (painting takes real time);
  /// null paints directly, as an app does. With [near] (in global
  /// coordinates: a control's rect), only the boxes whose cast reaches into
  /// it are read.
  Future<DesignAlignmentReport> check(
    BuildContext context, {
    Future<T?> Function<T>(Future<T> Function() work)? runAsync,
    Rect? near,
  }) async {
    final root = context.findRenderObject();
    if (root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final rootRect = _global(root);
    final casters = <_Caster>[];
    void visit(RenderObject node) {
      if (node is RenderBox && node.hasSize && !node.size.isEmpty) {
        final caster = _Caster.of(node, rootRect);
        if (caster != null &&
            (near == null ||
                caster.global.inflate(caster.margin).overlaps(near))) {
          casters.add(caster);
        }
      }
      _visitShown(node, visit);
    }

    visit(root);
    if (casters.isEmpty) return DesignAlignmentReport(look, const []);
    Future<void> paintAll() async {
      // A test draws box shadows hard (flutter_test turns their blur off
      // for stable goldens): each caster is painted as an app paints it.
      final hard = debugDisableShadows;
      debugDisableShadows = false;
      try {
        for (final c in casters) {
          await c.paint();
        }
      } finally {
        debugDisableShadows = hard;
      }
    }

    if (runAsync == null) {
      await paintAll();
    } else {
      await runAsync(paintAll);
    }
    final found = <String>[];
    for (final c in casters) {
      final cut = _cutOf(c, rootRect);
      if (cut != null) found.add(cut);
      found.addAll(_squareCorners(c));
    }
    return DesignAlignmentReport(look, found);
  }

  // Where a clip above [c] cuts what it paints past its box, in words.
  String? _cutOf(_Caster c, Rect screen) {
    final painted = c.paintedPast(visibleAlpha);
    if (painted == null) return null;
    final reach = c.toGlobal(painted);
    if (reach.left >= c.global.left - tolerance &&
        reach.top >= c.global.top - tolerance &&
        reach.right <= c.global.right + tolerance &&
        reach.bottom <= c.global.bottom + tolerance) {
      return null;
    }
    final sides = <String, (double, double, RenderObject)>{};
    // The screen the face is on: its app's overlay (a phone shown small in
    // a preview has its own), else the view's.
    var own = screen;
    for (var up = c.box.parent; up != null; up = up.parent) {
      if (up.runtimeType.toString() == '_RenderTheater' &&
          up is RenderBox &&
          up.hasSize) {
        own = _global(up);
        break;
      }
    }
    RenderObject child = c.box;
    for (var up = c.box.parent; up != null; up = up.parent) {
      // Past the overlay its route stands in, the clips round it are its
      // screen's frame (a phone in a preview), where every page ends.
      if (up.runtimeType.toString() == '_RenderTheater') break;
      final local = _paintClip(up, child);
      child = up;
      if (local == null) continue;
      final clip = MatrixUtils.transformRect(up.getTransformTo(null), local);
      // The face's own shape clip (a rounded or a path clip on its box):
      // what it cuts lies outside the face, where its shape leaves nothing.
      if (_same(clip, c.global) &&
          (up is RenderClipRRect ||
              up is RenderClipRSuperellipse ||
              up is RenderClipPath ||
              up is RenderClipOval)) {
        continue;
      }
      // The screen's own edge (an overlay, a route as large as the
      // screen) is where every page ends, not a cut.
      if (_contains(clip.inflate(1), screen) ||
          _contains(clip.inflate(1), own)) {
        break;
      }
      // The box itself past this clip on a side (scrolled past it, or a
      // dialog taller than its scroll view): that side is the clip
      // check's; the others are still read.
      final scrolled = {
        if (c.global.left < clip.left - tolerance) 'left',
        if (c.global.top < clip.top - tolerance) 'top',
        if (c.global.right > clip.right + tolerance) 'right',
        if (c.global.bottom > clip.bottom + tolerance) 'bottom',
      };
      if (scrolled.length == 4) break;
      for (final (side, past, room) in [
        ('left', clip.left - reach.left, c.global.left - clip.left),
        ('top', clip.top - reach.top, c.global.top - clip.top),
        ('right', reach.right - clip.right, clip.right - c.global.right),
        ('bottom', reach.bottom - clip.bottom, clip.bottom - c.global.bottom),
      ]) {
        if (past <= tolerance || sides.containsKey(side)) continue;
        if (scrolled.contains(side)) continue;
        if (_scrollsOnPast(up, side)) continue;
        // A clip whose side is the screen's own (a full-width sheet in a
        // frame the screen's width) ends the shadow where the screen does.
        final onScreenEdge = switch (side) {
          'left' => (clip.left - own.left).abs() <= tolerance,
          'top' => (clip.top - own.top).abs() <= tolerance,
          'right' => (clip.right - own.right).abs() <= tolerance,
          _ => (clip.bottom - own.bottom).abs() <= tolerance,
        };
        if (onScreenEdge) continue;
        if (!c.showsAt(side, clip, visibleAlpha)) continue;
        // A clip on the face's own edge hides that side's shadow whole, no
        // flat line to see, unless the face is round there: then the
        // shadow shows square behind its round corners.
        if (room <= tolerance && c.roundCornersOn(side).isEmpty) continue;
        sides[side] = (past + room, room, up);
      }
    }
    if (sides.isEmpty) return null;
    final byClip = <RenderObject, List<String>>{};
    for (final MapEntry(key: side, value: (_, _, clip)) in sides.entries) {
      byClip.putIfAbsent(clip, () => []).add(side);
    }
    final parts = [
      for (final MapEntry(key: clip, value: at) in byClip.entries)
        () {
          final (reaches, room, _) = sides[at.first]!;
          if (room <= tolerance) {
            final corners = {for (final side in at) ...c.roundCornersOn(side)};
            return 'cut along its own edge at its ${at.join(' and ')} by '
                '${_clipName(clip)}: behind its round '
                '${corners.join(' and ')} '
                '${corners.length == 1 ? 'corner' : 'corners'} the shadow '
                'shows square';
          }
          return 'cut flat at its ${at.join(' and ')} by ${_clipName(clip)}: '
              'it reaches ${_px(reaches)} pt past the face, the clip stops '
              'it ${_px(room)} pt out';
        }(),
    ];
    return 'the ${c.what} of ${_casterName(c.box)} is ${parts.join('; ')}';
  }

  // Corners of [c]'s face drawn round with a shadow that turns square
  // behind them.
  List<String> _squareCorners(_Caster c) {
    final corners = {
      ...c.squareShadowCorners(visibleAlpha),
      ...c.squareUnderRound(visibleAlpha),
    }.toList();
    if (corners.isEmpty) return const [];
    return [
      'the ${c.what} of ${_casterName(c.box)} is square behind its round '
          '${corners.join(' and ')} '
          '${corners.length == 1 ? 'corner' : 'corners'}: a shadow follows '
          'the face it is cast by',
    ];
  }
}

// A box that casts: what it paints, painted alone with [margin] round it.
class _Caster {
  _Caster._(this.box, this.global, this.margin, this.what, this._draw);

  final RenderBox box;
  final Rect global;
  final double margin;

  // "shadow", "glow"...
  final String what;
  final void Function(Canvas canvas) _draw;

  // The paint, RGBA, row by row, [width] by [height]; null until painted or
  // when painting failed.
  ByteData? _pixels;
  int _width = 0;
  int _height = 0;

  static _Caster? of(RenderBox box, Rect screen) {
    final size = box.size;
    final global = _global(box);
    // A ground behind the whole page (a backdrop) casts nothing a clip
    // could cut.
    if (global.width * global.height > screen.width * screen.height * .5 ||
        size.width > 2400 ||
        size.height > 2400) {
      return null;
    }
    switch (box) {
      case RenderDecoratedBox(:final decoration, :final configuration):
        final shadows = switch (decoration) {
          BoxDecoration(:final boxShadow) => boxShadow,
          ShapeDecoration(:final shadows) => shadows,
          _ => null,
        };
        if (shadows == null || !shadows.any((s) => s.color.a > 0)) return null;
        final reach = shadows.fold<double>(
          0,
          (m, s) => math.max(
            m,
            s.blurRadius * 2 + s.spreadRadius + s.offset.distance,
          ),
        );
        return _Caster._(box, global, reach + 4, 'shadow', (canvas) {
          final painter = decoration.createBoxPainter(() {});
          painter.paint(
            canvas,
            Offset.zero,
            configuration.copyWith(size: size),
          );
          painter.dispose();
        });
      case RenderPhysicalModel(
            :final elevation,
            :final shadowColor,
            :final color,
          )
          when elevation > 0 && shadowColor.a > 0:
        final model = box;
        return _Caster._(box, global, elevation * 3 + 8, 'shadow', (canvas) {
          final rect = Offset.zero & size;
          final path = switch (model.shape) {
            BoxShape.circle => Path()..addOval(rect),
            BoxShape.rectangle =>
              Path()..addRRect(
                (model.borderRadius ?? BorderRadius.zero)
                    .resolve(TextDirection.ltr)
                    .toRRect(rect),
              ),
          };
          canvas.drawShadow(path, shadowColor, elevation, color.a < 1);
          canvas.drawPath(path, Paint()..color = color);
        });
      case RenderPhysicalShape(
            :final elevation,
            :final shadowColor,
            :final color,
            :final clipper,
          )
          when elevation > 0 && shadowColor.a > 0 && clipper != null:
        return _Caster._(box, global, elevation * 3 + 8, 'shadow', (canvas) {
          final path = clipper.getClip(size);
          canvas.drawShadow(path, shadowColor, elevation, color.a < 1);
          canvas.drawPath(path, Paint()..color = color);
        });
      case RenderCustomPaint(:final painter, :final foregroundPainter)
          when painter != null || foregroundPainter != null:
        return _Caster._(
          box,
          global,
          math.min(64, math.max(24, size.shortestSide)),
          'shadow or glow',
          (canvas) {
            painter?.paint(canvas, size);
            foregroundPainter?.paint(canvas, size);
          },
        );
      default:
        return null;
    }
  }

  // Paints the box alone and reads it back.
  Future<void> paint() async {
    final size = box.size;
    _width = (size.width + margin * 2).ceil();
    _height = (size.height + margin * 2).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.translate(margin, margin);
    try {
      _draw(canvas);
    } on Object {
      // A painter that needs its own pipeline (an image not yet decoded)
      // is not read.
      recorder.endRecording().dispose();
      return;
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(_width, _height);
    picture.dispose();
    try {
      _pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } finally {
      image.dispose();
    }
  }

  int _alpha(int x, int y) {
    if (x < 0 || y < 0 || x >= _width || y >= _height) return 0;
    return _pixels!.getUint8((y * _width + x) * 4 + 3);
  }

  // What it paints at [visible] alpha or more, in its own coordinates;
  // null when nothing reaches past its box.
  Rect? paintedPast(int visible) {
    if (_pixels == null) return null;
    var left = _width, top = _height, right = -1, bottom = -1;
    for (var y = 0; y < _height; y++) {
      for (var x = 0; x < _width; x++) {
        if (_alpha(x, y) < visible) continue;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
    if (right < 0) return null;
    return Rect.fromLTRB(
      left - margin,
      top - margin,
      right + 1 - margin,
      bottom + 1 - margin,
    );
  }

  Rect toGlobal(Rect local) =>
      MatrixUtils.transformRect(box.getTransformTo(null), local);

  // Whether what it paints still shows (at [visible] alpha) where [clip]'s
  // [side] edge crosses it: a hard edge, not a falloff spent before it.
  bool showsAt(String side, Rect clip, int visible) {
    if (_pixels == null) return false;
    final toLocal = Matrix4.tryInvert(box.getTransformTo(null));
    if (toLocal == null) return false;
    final local = MatrixUtils.transformRect(toLocal, clip);
    final scale = box.size.width == 0 ? 1.0 : global.width / box.size.width;
    // A pixel inside the clip, a step from its edge.
    final step = 1 / math.max(scale, .01);
    bool any(Iterable<(int, int)> spots) =>
        spots.any((s) => _alpha(s.$1, s.$2) >= visible);
    final xs = [for (var x = 0; x < _width; x++) x];
    final ys = [for (var y = 0; y < _height; y++) y];
    return switch (side) {
      'left' => any([
        for (final y in ys) ((local.left + step + margin).floor(), y),
      ]),
      'right' => any([
        for (final y in ys) ((local.right - step + margin).floor(), y),
      ]),
      'top' => any([
        for (final x in xs) (x, (local.top + step + margin).floor()),
      ]),
      _ => any([
        for (final x in xs) (x, (local.bottom - step + margin).floor()),
      ]),
    };
  }

  // The corners where a face drawn over the box (its own child, as large
  // as it) is round while the box casts its shadow square, and the shadow
  // shows in the corner the round face leaves: a ClipRRect or a rounded
  // face inside a square box's shadow.
  List<String> squareUnderRound(int visible) {
    if (_pixels == null) return const [];
    final own = _Shape.of(box)?.radii;
    if (what != 'shadow') return const [];
    var over = (tl: 0.0, tr: 0.0, bl: 0.0, br: 0.0);
    void visit(RenderObject n) {
      if (n is RenderBox && n.hasSize && !identical(n, box)) {
        final r = _global(n);
        if (!_same(r, global)) return;
        if (_Shape.of(n)?.radii case final s?) {
          over = (
            tl: math.max(over.tl, s.tl),
            tr: math.max(over.tr, s.tr),
            bl: math.max(over.bl, s.bl),
            br: math.max(over.br, s.br),
          );
        }
      }
      _visitShown(n, visit);
    }

    visit(box);
    final level = math.max(visible * 2, 20);
    final w = box.size.width;
    final h = box.size.height;
    final found = <String>[];
    for (final (name, mine, round, x, y) in [
      ('top left', own?.tl ?? 0, over.tl, 1.0, 1.0),
      ('top right', own?.tr ?? 0, over.tr, w - 1, 1.0),
      ('bottom left', own?.bl ?? 0, over.bl, 1.0, h - 1),
      ('bottom right', own?.br ?? 0, over.br, w - 1, h - 1),
    ]) {
      if (round - mine < 3) continue;
      // The shadow in the corner the round face leaves bare.
      if (_alpha((x + margin).floor(), (y + margin).floor()) >= level) {
        found.add(name);
      }
    }
    return found;
  }

  // The corners of an opaque face drawn round whose shadow turns square
  // behind them, by name ("bottom right").
  // The corners of the face it paints (what it paints opaque) drawn round,
  // on [side], by name ("top left").
  List<String> roundCornersOn(String side) {
    if (_pixels == null) return const [];
    var left = _width, top = _height, right = -1, bottom = -1;
    for (var y = 0; y < _height; y++) {
      for (var x = 0; x < _width; x++) {
        if (_alpha(x, y) < 245) continue;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
    if (right - left < 8 || bottom - top < 8) return const [];
    final found = <String>[];
    for (final (name, cx, cy, ux, uy) in [
      ('top left', left, top, 1, 1),
      ('top right', right, top, -1, 1),
      ('bottom left', left, bottom, 1, -1),
      ('bottom right', right, bottom, -1, -1),
    ]) {
      if (!name.contains(side)) continue;
      // Round where the face starts a few pixels in along the diagonal.
      var inset = 0;
      while (inset < 6 && _alpha(cx + ux * inset, cy + uy * inset) < 245) {
        inset++;
      }
      if (inset >= 2) found.add(name);
    }
    return found;
  }

  List<String> squareShadowCorners(int visible) {
    if (_pixels == null) return const [];
    // Under 32 pt across, a shadow's blur spans the whole corner: what it
    // casts reads as round to the eye however its pixels lean (a knob, a
    // thin relief strip).
    if (box.size.shortestSide < 32) return const [];
    // The face: what it paints opaque.
    var left = _width, top = _height, right = -1, bottom = -1;
    for (var y = 0; y < _height; y++) {
      for (var x = 0; x < _width; x++) {
        if (_alpha(x, y) < 245) continue;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
    if (right - left < 16 || bottom - top < 16) return const [];
    final level = math.max(visible * 2, 20);
    final found = <String>[];
    for (final (name, cx, cy, ux, uy) in [
      ('top left', left, top, 1, 1),
      ('top right', right, top, -1, 1),
      ('bottom left', left, bottom, 1, -1),
      ('bottom right', right, bottom, -1, -1),
    ]) {
      // How far in along the diagonal the face starts: its corner's round.
      var inset = 0;
      final most = math.min(right - left, bottom - top) ~/ 2;
      while (inset < most && _alpha(cx + ux * inset, cy + uy * inset) < 245) {
        inset++;
      }
      if (inset < 3) continue;
      // [inset] diagonal steps, each √2 long, are the corner's R(√2 - 1).
      final across = inset * math.sqrt2;
      final radius = across / (math.sqrt2 - 1);
      // The shadow's reach out from a straight stretch of each edge near
      // the corner, and out from the curve along the diagonal.
      int out(int x, int y, int dx, int dy) {
        var d = 0;
        while (d < margin &&
            _alpha(x + dx * (d + 1), y + dy * (d + 1)) >= level) {
          d++;
        }
        return d;
      }

      final along = (radius + 3).round();
      final edgeX = out(cx + ux * along, cy, 0, -uy);
      final edgeY = out(cx, cy + uy * along, -ux, 0);
      final edge = math.min(edgeX, edgeY);
      if (edge < 2) continue;
      final ax = cx + ux * inset;
      final ay = cy + uy * inset;
      var diagonal = 0;
      while (diagonal < margin * 2 &&
          _alpha(ax - ux * (diagonal + 1), ay - uy * (diagonal + 1)) >= level) {
        diagonal++;
      }
      // Out from the curve a round shadow reaches about as far as from an
      // edge (an offset towards the corner adds √2 - 1 of it); a square one
      // reaches on to the square's corner, [across] further.
      final reach = diagonal * math.sqrt2;
      if (reach > edge * 1.42 + math.max(2.0, across * .5)) found.add(name);
    }
    return found;
  }
}

// [clip] (a box that clips what it paints), in words.
String _clipName(RenderObject clip) {
  final kind = switch (clip) {
    RenderClipRect() => 'a clip (ClipRect)',
    RenderClipRRect() => 'a rounded clip (ClipRRect)',
    RenderClipRSuperellipse() => 'a rounded clip (ClipRSuperellipse)',
    RenderClipOval() => 'an oval clip',
    RenderClipPath() => 'a clip path',
    RenderPhysicalModel() || RenderPhysicalShape() => 'the surface it is in',
    RenderAbstractViewport() => "a scroll view's edge",
    RenderStack() || RenderFlex() => 'a box that clips what overflows it',
    _ => 'a clip (${clip.runtimeType})',
  };
  if (clip is! RenderBox || !clip.hasSize) return kind;
  return '$kind ${_size(clip.size)}${_holding(clip)}';
}

// [box] (a box that casts), in words: the control it is part of, else the
// surface and the words it holds.
String _casterName(RenderBox box) {
  for (RenderObject? up = box; up != null; up = up.parent) {
    if (up is RenderBox && _isControl(up)) {
      final c = _global(up);
      final b = _global(box);
      // The control is this face, not a page holding it.
      if (c.width <= b.width * 2 + 48 && c.height <= b.height * 2 + 48) {
        return _partName(up);
      }
      break;
    }
  }
  return 'a ${_size(box.size)} face${_holding(box)}';
}

// Where [up] clips [child]'s paint: a custom clipper's own clip, not the
// approximate rect it reports (CustomClipper's default is the whole box,
// which would read as a cut on every side of a clip that cuts on one axis),
// else the approximate clip [up] describes.
// Whether [clip] is a scroll view with more of its content past its [side],
// along its scroll: what it cuts there is scrolling by.
bool _scrollsOnPast(RenderObject clip, String side) {
  const slack = .5;
  if (clip is RenderViewportBase) {
    final offset = clip.offset;
    if (offset is! ScrollPosition ||
        !offset.hasPixels ||
        !offset.hasContentDimensions) {
      return false;
    }
    final (leading, trailing) = switch (clip.axisDirection) {
      AxisDirection.down => ('top', 'bottom'),
      AxisDirection.up => ('bottom', 'top'),
      AxisDirection.right => ('left', 'right'),
      AxisDirection.left => ('right', 'left'),
    };
    if (side == trailing) {
      return offset.pixels < offset.maxScrollExtent - slack;
    }
    if (side == leading) {
      return offset.pixels > offset.minScrollExtent + slack;
    }
    return false;
  }
  // A viewport round one box (a SingleChildScrollView's): its content
  // reaches past the side it scrolls on, and fills it across.
  if (clip is! RenderBox || clip is! RenderAbstractViewport || !clip.hasSize) {
    return false;
  }
  RenderBox? content;
  clip.visitChildren((child) {
    if (child is RenderBox && child.hasSize) content = child;
  });
  final inside = content;
  if (inside == null) return false;
  final at = MatrixUtils.transformRect(
    inside.getTransformTo(clip),
    Offset.zero & inside.size,
  );
  final box = Offset.zero & clip.size;
  return switch (side) {
    'left' => at.left < box.left - slack,
    'top' => at.top < box.top - slack,
    'right' => at.right > box.right + slack,
    _ => at.bottom > box.bottom + slack,
  };
}

Rect? _paintClip(RenderObject up, RenderObject child) {
  final approximate = up.describeApproximatePaintClip(child);
  if (approximate == null) return null;
  return switch (up) {
    RenderClipRect(:final clipper?) => clipper.getClip(up.size),
    RenderClipRRect(:final clipper?) => clipper.getClip(up.size).outerRect,
    RenderClipRSuperellipse(:final clipper?) =>
      clipper.getClip(up.size).outerRect,
    RenderClipOval(:final clipper?) => clipper.getClip(up.size),
    RenderClipPath(:final clipper?) => clipper.getClip(up.size).getBounds(),
    _ => approximate,
  };
}
