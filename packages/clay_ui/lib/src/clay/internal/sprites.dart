// Clay's soft shading, painted from cached masks. A volume's drop shadow, its
// inner light and its inner shade are each a blur; blurring them on every
// frame (a scroll, a press) costs the raster thread on every renderer, and on
// a software one (a headless browser) most of a frame. So each blur is drawn
// once into a small white mask, keyed by its shape and its softness, and every
// frame after draws the mask, tinted, as a nine-slice: the corners as they
// were blurred, the straight runs stretched. A part smaller than a sliced mask
// takes a mask of its own size.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The kinds of soft shading a volume is made of.
enum ClaySpriteKind {
  /// The shadow a volume casts on the ground below it.
  drop,

  /// A soft band inside the shape's top-leading edges (a raised part's light,
  /// a well's shade).
  insetStart,

  /// A soft band inside the shape's bottom-trailing edges (a raised part's
  /// shade, a well's light).
  insetEnd,
}

/// How far along a side a corner of [radius] bends: a rounded superellipse
/// runs its curve a little past the radius.
double clayCornerExtent(double radius, {required bool round}) =>
    round ? radius : radius * 1.75;

/// Whether a part [size] with corners of [radius] is a stadium or a circle
/// (its radius reaches half its shorter side).
bool clayIsRound(Size size, double radius) =>
    radius >= math.min(size.width, size.height) / 2 - 0.01;

/// Adds the outline of a part filling [rect] with corners of [radius] to
/// [path]: a stadium or a circle when [radius] reaches half the shorter
/// side, a rounded superellipse otherwise.
void clayAddShape(Path path, Rect rect, double radius) {
  if (clayIsRound(rect.size, radius)) {
    path.addRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.min(rect.width, rect.height) / 2),
      ),
    );
  } else {
    path.addRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius)),
    );
  }
}

/// Fills the outline of a part filling [rect] with corners of [radius].
void clayDrawShape(Canvas canvas, Rect rect, double radius, Paint paint) {
  if (clayIsRound(rect.size, radius)) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.min(rect.width, rect.height) / 2),
      ),
      paint,
    );
  } else {
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }
}

/// Clips [canvas] to the outline of a part filling [rect].
void clayClipShape(Canvas canvas, Rect rect, double radius) {
  if (clayIsRound(rect.size, radius)) {
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(math.min(rect.width, rect.height) / 2),
      ),
    );
  } else {
    canvas.clipRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius)),
    );
  }
}

double _q(double v, double step) => (v / step).roundToDouble() * step;

@immutable
class _Key {
  const _Key(
    this.kind,
    this.radius,
    this.round,
    this.blur,
    this.offset,
    this.width,
    this.height,
    this.scale,
  );

  final ClaySpriteKind kind;
  final double radius;
  final bool round;
  final double blur;
  final double offset;
  // 0 when sliced along that axis, else the exact size.
  final double width;
  final double height;
  final int scale;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.kind == kind &&
      other.radius == radius &&
      other.round == round &&
      other.blur == blur &&
      other.offset == offset &&
      other.width == width &&
      other.height == height &&
      other.scale == scale;

  @override
  int get hashCode =>
      Object.hash(kind, radius, round, blur, offset, width, height, scale);
}

class _Sprite {
  _Sprite(this.image, this.center, this.pad);

  final ui.Image image;
  // The stretched slice, in the image's pixels.
  final Rect center;
  // How far the mask reaches past the shape, in logical pixels.
  final double pad;
}

/// The masks, most recently used last.
final LinkedHashMap<_Key, _Sprite> _cache = LinkedHashMap();

const int _capacity = 192;

/// How many masks are cached now (for a test).
int get claySpriteCount => _cache.length;

// The volumes of clay in a tree now. The masks live while one does: when the
// last leaves (an app closing its last clay page, a test's tree torn down),
// they are disposed, a microtask later so a part moved within one frame keeps
// them.
int _holders = 0;
bool _releasing = false;

/// A volume of clay entered a tree: the masks are kept.
void claySpritesHold() => _holders++;

/// A volume of clay left its tree: when it was the last, the masks are
/// disposed.
void claySpritesRelease() {
  _holders--;
  if (_holders > 0 || _releasing) return;
  _releasing = true;
  scheduleMicrotask(() {
    _releasing = false;
    if (_holders <= 0) claySpritesClear();
  });
}

/// Disposes every cached mask; the next paint draws them anew.
void claySpritesClear() {
  for (final sprite in _cache.values) {
    sprite.image.dispose();
  }
  _cache.clear();
}

/// Paints one soft band of [kind] for the shape filling [rect] (corners of
/// [radius]), tinted [color]: [blur] its softness (a Gaussian sigma) and
/// [offset] how far it is cast (down for a drop shadow, inwards for an inner
/// band). [mirrored] flips it for right to left. [pixelRatio] is the screen's.
void clayPaintSprite(
  Canvas canvas, {
  required ClaySpriteKind kind,
  required Rect rect,
  required double radius,
  required double blur,
  required double offset,
  required Color color,
  required double pixelRatio,
  bool mirrored = false,
}) {
  if (color.a <= 0 || rect.isEmpty) return;
  final round = clayIsRound(rect.size, radius);
  final r = round ? math.min(rect.width, rect.height) / 2 : _q(radius, 0.5);
  final b = math.max(0.5, _q(blur, 0.5));
  final o = _q(offset, 0.5);
  final scale = pixelRatio.round().clamp(1, 3);
  // How far a corner's influence runs along a side.
  final corner =
      (clayCornerExtent(r, round: round) + 3 * b + o.abs()).ceilToDouble() + 1;
  final slice = 2 * corner + 2;
  final sliceX = rect.width >= slice;
  final sliceY = rect.height >= slice;
  final width = sliceX ? 0.0 : _q(rect.width, 1);
  final height = sliceY ? 0.0 : _q(rect.height, 1);
  // A stadium's radius is half its exact side; sliced, the radius is its own.
  final key = _Key(
    kind,
    round && !(sliceX && sliceY) ? 0 : r,
    round,
    b,
    o,
    width,
    height,
    scale,
  );
  var sprite = _cache.remove(key);
  sprite ??= _draw(
    kind,
    r,
    round,
    b,
    o,
    sliceX ? slice : width,
    sliceY ? slice : height,
    sliceX,
    sliceY,
    corner,
    scale,
  );
  _cache[key] = sprite;
  while (_cache.length > _capacity) {
    final oldest = _cache.keys.first;
    _cache.remove(oldest)!.image.dispose();
  }
  final dst = rect.inflate(sprite.pad);
  final paint = Paint()
    ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
    ..filterQuality = FilterQuality.low
    ..isAntiAlias = true;
  canvas.save();
  if (mirrored) {
    canvas
      ..translate(rect.center.dx, 0)
      ..scale(-1, 1)
      ..translate(-rect.center.dx, 0);
  }
  canvas.scale(1 / scale);
  canvas.drawImageNine(
    sprite.image,
    sprite.center,
    Rect.fromLTRB(
      dst.left * scale,
      dst.top * scale,
      dst.right * scale,
      dst.bottom * scale,
    ),
    paint,
  );
  canvas.restore();
}

_Sprite _draw(
  ClaySpriteKind kind,
  double radius,
  bool round,
  double blur,
  double offset,
  double width,
  double height,
  bool sliceX,
  bool sliceY,
  double corner,
  int scale,
) {
  final drop = kind == ClaySpriteKind.drop;
  final pad = drop ? (3 * blur + offset.abs()).ceilToDouble() + 1 : 0.0;
  final w = width + 2 * pad;
  final h = height + 2 * pad;
  final shape = Rect.fromLTWH(pad, pad, width, height);
  final r = round ? math.min(width, height) / 2 : radius;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale.toDouble());
  final paint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  switch (kind) {
    case ClaySpriteKind.drop:
      clayDrawShape(canvas, shape.translate(0, offset), r, paint);
    case ClaySpriteKind.insetStart:
    case ClaySpriteKind.insetEnd:
      // The band is the ground round the shape moved away from that edge,
      // blurred and kept inside the shape.
      final away = kind == ClaySpriteKind.insetStart ? offset : -offset;
      canvas
        ..save()
        ..clipRect(Offset.zero & Size(w, h));
      clayClipShape(canvas, shape, r);
      final band = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(shape.inflate(4 * blur + offset.abs() + 4));
      clayAddShape(band, shape.translate(away, away), r);
      canvas
        ..drawPath(band, paint)
        ..restore();
  }
  final picture = recorder.endRecording();
  final image = picture.toImageSync((w * scale).ceil(), (h * scale).ceil());
  picture.dispose();
  final cx = sliceX ? (pad + corner) * scale : 0.0;
  final cy = sliceY ? (pad + corner) * scale : 0.0;
  final cw = sliceX ? 2.0 * scale : image.width.toDouble();
  final ch = sliceY ? 2.0 * scale : image.height.toDouble();
  return _Sprite(image, Rect.fromLTWH(cx, cy, cw, ch), pad);
}
