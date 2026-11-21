part of '../../alignment.dart';

typedef _Radii = ({double tl, double tr, double bl, double br});

// A box whose outline the check knows: its rect and its corners' radii,
// null until read from its pixels.
class _Shape {
  _Shape(this.box, this.rect, this.radii);

  final RenderBox box;
  final Rect rect;
  final _Radii? radii;

  // Whether [radii] were read from pixels ([_ReadShape]).
  bool get read => false;

  static _Shape? of(RenderBox box) {
    final size = box.size;
    ({double tl, double tr, double bl, double br})? radii;
    ({double tl, double tr, double bl, double br}) fromRadius(
      BorderRadiusGeometry r,
    ) {
      final b = r.resolve(TextDirection.ltr);
      double cap(Radius v) =>
          math.min(math.min(v.x, v.y), size.shortestSide / 2);
      return (
        tl: cap(b.topLeft),
        tr: cap(b.topRight),
        bl: cap(b.bottomLeft),
        br: cap(b.bottomRight),
      );
    }

    ({double tl, double tr, double bl, double br})? fromShape(
      ShapeBorder shape,
    ) => switch (shape) {
      StadiumBorder() || CircleBorder() => (
        tl: size.shortestSide / 2,
        tr: size.shortestSide / 2,
        bl: size.shortestSide / 2,
        br: size.shortestSide / 2,
      ),
      RoundedRectangleBorder(:final borderRadius) ||
      RoundedSuperellipseBorder(:final borderRadius) ||
      ContinuousRectangleBorder(
        :final borderRadius,
      ) => fromRadius(borderRadius),
      _ => null,
    };

    switch (box) {
      // A clip is a shape only where it rounds: a square one cuts, unseen.
      case RenderClipRRect(:final borderRadius)
          when borderRadius != BorderRadius.zero:
        radii = fromRadius(borderRadius);
      case RenderClipRSuperellipse(:final borderRadius)
          when borderRadius != BorderRadius.zero:
        radii = fromRadius(borderRadius);
      case RenderDecoratedBox(:final decoration) when _shows(decoration):
        radii = switch (decoration) {
          BoxDecoration(shape: BoxShape.circle) => fromShape(
            const CircleBorder(),
          ),
          BoxDecoration(:final borderRadius) => fromRadius(
            borderRadius ?? BorderRadius.zero,
          ),
          ShapeDecoration(:final shape) => fromShape(shape),
          _ => null,
        };
      case RenderPhysicalShape(:final clipper?)
          when clipper is ShapeBorderClipper:
        radii = fromShape(clipper.shape);
      case RenderClipPath(:final clipper?) when clipper is ShapeBorderClipper:
        radii = fromShape(clipper.shape);
      default:
        radii = null;
    }
    if (radii == null) return null;
    return _Shape(box, _global(box), radii);
  }
}

bool _same(Rect a, Rect b) =>
    (a.left - b.left).abs() < .5 &&
    (a.top - b.top).abs() < .5 &&
    (a.right - b.right).abs() < .5 &&
    (a.bottom - b.bottom).abs() < .5;
