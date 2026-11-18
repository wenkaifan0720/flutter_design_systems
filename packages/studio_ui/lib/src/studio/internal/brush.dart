// The brushed grain of Studio's metal: fine horizontal streaks, painted once
// per device pixel ratio into an image and cached, then laid over a panel as
// a repeating shader. Nothing is drawn per frame but one shaded rectangle.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

final Map<double, ui.ImageShader?> _shaders = {};

const double _tileWidth = 480;
const double _tileHeight = 96;

/// The grain shader for [devicePixelRatio], drawn at device pixels so a
/// streak is one device pixel tall at any scale; null where the platform
/// cannot make an image without waiting.
ui.ImageShader? studioBrushShader(double devicePixelRatio) {
  final ratio = (devicePixelRatio * 4).roundToDouble() / 4;
  return _shaders.putIfAbsent(ratio, () {
    try {
      final w = (_tileWidth * ratio).round();
      final h = (_tileHeight * ratio).round();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final random = math.Random(1115);
      final paint = ui.Paint();
      for (var y = 0; y < h; y++) {
        // Fine streaks along each device row, of random length and a faint
        // weight, light and dark in turn: the grain a brush leaves. Faint on
        // purpose: at a page's size it reads as a sheen, never as noise.
        var x = -random.nextDouble() * w;
        final end = x + w;
        while (x < end) {
          final length = 24 + random.nextDouble() * w * 0.5;
          final a = random.nextDouble();
          final lit = random.nextBool();
          paint.color =
              (lit ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
                  .withValues(alpha: (lit ? 0.022 : 0.018) + a * 0.03);
          final rect = ui.Rect.fromLTWH(x, y.toDouble(), length, 1);
          // The tile repeats across, so a streak is drawn where it lies and
          // again a tile over, whichever edge it crosses: no seam.
          for (final shift in const [-1.0, 0.0, 1.0]) {
            final r = rect.shift(Offset(shift * w, 0));
            if (r.right > 0 && r.left < w) canvas.drawRect(r, paint);
          }
          x += length + random.nextDouble() * 24;
        }
      }
      final picture = recorder.endRecording();
      final image = picture.toImageSync(w, h);
      picture.dispose();
      final scale = Float64List(16)
        ..[0] = 1 / ratio
        ..[5] = 1 / ratio
        ..[10] = 1
        ..[15] = 1;
      final shader = ui.ImageShader(
        image,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        scale,
      );
      // The shader holds the pixels from here; the image's own handle goes.
      image.dispose();
      return shader;
    } on Object {
      return null;
    }
  });
}
