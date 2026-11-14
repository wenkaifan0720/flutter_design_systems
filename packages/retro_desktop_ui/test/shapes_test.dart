import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/src/retro_desktop/shapes.dart';

void main() {
  const family = [RetroDesktopBorder.square(), RetroDesktopBorder.bevelled()];
  const side = BorderSide(color: Color(0xff123456), width: 2);
  const rect = Rect.fromLTWH(3, 7, 100, 60);
  for (final a in family) {
    for (final b in family) {
      for (final t in [0.0, .5, 1.0]) {
        test('${a.cut} to ${b.cut} at $t', () {
          final shape = ShapeBorder.lerp(a, b, t)! as RetroDesktopBorder;
          expect(shape.cut, a.cut + (b.cut - a.cut) * t);
          expect(shape.getOuterPath(rect).getBounds(), rect);
          expect(
            shape.copyWith(side: side).getInnerPath(rect).getBounds(),
            rect.deflate(2),
          );
          expect(shape, shape.copyWith());
          expect(shape.hashCode, shape.copyWith().hashCode);
          expect(shape.scale(2).cut, shape.cut * 2);
        });
      }
    }
  }
  test('overshooting curves keep corner cuts nonnegative', () {
    for (final a in family) {
      for (final b in family) {
        for (final t in [-.5, 1.5]) {
          final shape = ShapeBorder.lerp(a, b, t)! as RetroDesktopBorder;
          expect(shape.cut, greaterThanOrEqualTo(0));
          expect(shape.getOuterPath(rect).getBounds(), rect);
        }
      }
    }
  });
  test('each appearance draws its own corners: Chisel square everywhere, '
      'Platinum rounding only its buttons', () {
    final chisel = RetroDesktopShapes.of(RetroDesktopAppearance.chisel);
    final platinum = RetroDesktopShapes.of(RetroDesktopAppearance.platinum);
    for (final shapes in [chisel, platinum]) {
      for (final role in [
        shapes.small,
        shapes.medium,
        shapes.large,
        shapes.full,
      ]) {
        expect((role as RetroDesktopBorder).cut, 0);
      }
    }
    expect((chisel.button as RetroDesktopBorder).cut, 0);
    expect(platinum.button, isA<RoundedRectangleBorder>());
  });
  test('the pixel bevel reserves its content safe area', () {
    const shape = RetroDesktopBorder.bevelled(side: BorderSide(width: 2));
    expect(shape.dimensions, const EdgeInsets.all(3));
    final safe = shape.dimensions.resolve(TextDirection.ltr).deflateRect(rect);
    final path = shape.getOuterPath(rect);
    for (final point in [
      safe.topLeft,
      safe.topRight,
      safe.bottomLeft,
      safe.bottomRight,
    ]) {
      expect(path.contains(point), isTrue);
    }
  });
  test('stroke alignment determines the inward layout reservation', () {
    const shape = RetroDesktopBorder.square(
      side: BorderSide(width: 2, strokeAlign: BorderSide.strokeAlignOutside),
    );
    expect(shape.dimensions, EdgeInsets.zero);
    expect(shape.getInnerPath(rect).getBounds(), rect);
  });
  test('a square or one-pixel cut keeps its cut fixed at any width', () {
    for (final (shape, cut) in const [
      (RetroDesktopBorder.square(), 0.0),
      (RetroDesktopBorder.bevelled(), 1.0),
    ]) {
      expect(shape.dimensions, EdgeInsets.all(cut));
      for (final width in [120.0, 240.0, 390.0]) {
        final wide = Rect.fromLTWH(0, 0, width, 24);
        final path = shape.getOuterPath(wide);
        expect(path.contains(Offset(width / 2, 1)), isTrue);
        expect(shape.cut, lessThan(wide.height / 2));
      }
    }
  });
}
