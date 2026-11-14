import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Retro Desktop's outline: square, or cut by one pixel at each corner.
/// The highlight and shade of a bevel are painted by the component inside it.
@immutable
class RetroDesktopBorder extends OutlinedBorder {
  /// Creates a border with square corners.
  const RetroDesktopBorder.square({super.side}) : cut = 0;

  /// Creates a border with clipped, pixel-bevelled corners.
  const RetroDesktopBorder.bevelled({super.side, this.cut = 1})
    : assert(cut >= 0);

  /// The straight corner cut. Zero is square; one is the offered bevelled form.
  final double cut;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset + cut);
  @override
  RetroDesktopBorder copyWith({BorderSide? side, double? cut}) =>
      RetroDesktopBorder.bevelled(
        side: side ?? this.side,
        cut: cut ?? this.cut,
      );
  @override
  RetroDesktopBorder scale(double t) => RetroDesktopBorder.bevelled(
    side: side.scale(t),
    cut: math.max(0, cut * t),
  );
  Path _path(Rect rect, double cut) {
    if (rect.isEmpty) return Path();
    final amount = math.min(cut, rect.shortestSide / 2);
    return Path()..addPolygon([
      Offset(rect.left + amount, rect.top),
      Offset(rect.right - amount, rect.top),
      Offset(rect.right, rect.top + amount),
      Offset(rect.right, rect.bottom - amount),
      Offset(rect.right - amount, rect.bottom),
      Offset(rect.left + amount, rect.bottom),
      Offset(rect.left, rect.bottom - amount),
      Offset(rect.left, rect.top + amount),
    ], true);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect, cut);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(
    rect.deflate(side.strokeInset),
    math.max(0, cut - side.strokeInset),
  );
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    if (side.width == 0) {
      canvas.drawPath(
        _path(rect, cut),
        Paint()
          ..color = side.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0
          ..isAntiAlias = false,
      );
      return;
    }
    final outer = rect.inflate(side.strokeOutset);
    final inner = rect.deflate(side.strokeInset);
    final rim = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(
        // A square stays square outside; a cut's diagonal moves by √2 − 1.
        _path(
          outer,
          cut == 0
              ? 0
              : (cut + side.strokeOutset * (math.sqrt2 - 1)).roundToDouble(),
        ),
        Offset.zero,
      )
      ..addPath(_path(inner, math.max(0, cut - side.strokeInset)), Offset.zero);
    canvas.drawPath(
      rim,
      Paint()
        ..color = side.color
        ..isAntiAlias = false,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is RetroDesktopBorder) {
      return RetroDesktopBorder.bevelled(
        side: BorderSide.lerp(a.side, side, t),
        cut: math.max(0, lerpDouble(a.cut, cut, t)!),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is RetroDesktopBorder) {
      return RetroDesktopBorder.bevelled(
        side: BorderSide.lerp(side, b.side, t),
        cut: math.max(0, lerpDouble(cut, b.cut, t)!),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is RetroDesktopBorder && other.side == side && other.cut == cut;
  @override
  int get hashCode => Object.hash(side, cut);
}

/// Which late-90s desktop the look draws. Every part reads it: its corners,
/// its edge, how it presses and how it shows keyboard focus.
///
/// Pick one with `RetroDesktopThemeData.copyWith(appearance: ...)`; the theme's
/// [RetroDesktopShapes] follow it unless an app supplies its own.
enum RetroDesktopAppearance {
  /// The 95-era PC: square corners everywhere, a hard two-step bevel (light
  /// above and left, dark below and right; fields sunk the other way), a
  /// pressed face that inverts its bevel and moves its label one pixel, a
  /// dotted focus rectangle inside the face, and a solid title bar with the
  /// title at its start and square caption buttons at its end.
  chisel,

  /// The late-90s Mac, the default: a one-pixel dark outline round a soft
  /// one-step bevel, push buttons and popups in a small rounded rectangle,
  /// windows and fields square, a pressed face that darkens without moving,
  /// a two-pixel focus ring outside the part in the accent, and a pinstriped
  /// title bar with the title centred, a close box at its start and zoom and
  /// collapse boxes at its end.
  platinum,
}

/// The outlines each appearance draws, by role, for a part drawn in the
/// look's hand (`RetroDesktopTheme.of(context).shapes`). Not a setting: the
/// corners follow the appearance, and a component theme still sets one
/// part's own shape.
@immutable
class RetroDesktopShapes {
  /// The Platinum appearance (the late-90s Mac): push buttons, popups and the
  /// ends of a segmented row in a 4 px rounded rectangle; fields, checkboxes,
  /// cards, windows and marks square.
  const RetroDesktopShapes._platinum()
    : small = const RetroDesktopBorder.square(),
      medium = const RetroDesktopBorder.square(),
      large = const RetroDesktopBorder.square(),
      full = const RetroDesktopBorder.square(),
      _button = const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      );

  /// The Chisel appearance (the 95-era PC): square everywhere.
  const RetroDesktopShapes._chisel()
    : small = const RetroDesktopBorder.square(),
      medium = const RetroDesktopBorder.square(),
      large = const RetroDesktopBorder.square(),
      full = const RetroDesktopBorder.square(),
      _button = const RetroDesktopBorder.square();

  /// The outlines [appearance] draws.
  static RetroDesktopShapes of(RetroDesktopAppearance appearance) =>
      switch (appearance) {
        RetroDesktopAppearance.chisel => const RetroDesktopShapes._chisel(),
        RetroDesktopAppearance.platinum => const RetroDesktopShapes._platinum(),
      };

  /// Controls, frames, windows and capsules/compact marks respectively.
  final OutlinedBorder small, medium, large, full;

  final OutlinedBorder? _button;

  /// Push buttons, popups, icon buttons, chips and a segmented row's ends:
  /// the parts a desktop drew as buttons. [small] unless given.
  OutlinedBorder get button => _button ?? small;

  /// Exclusive-choice controls are circles in both appearances.
  OutlinedBorder get radio => const CircleBorder();

  /// The radius supported by Flutter's narrow scrollbar track.
  Radius get scrollbarTrackRadius => switch (full) {
    StadiumBorder() || CircleBorder() => const Radius.circular(3),
    RoundedRectangleBorder(:final borderRadius) =>
      borderRadius.resolve(TextDirection.ltr).topLeft,
    RetroDesktopBorder(:final cut) => Radius.circular(cut),
    _ => Radius.zero,
  };

  /// The concentric outline inside [outline], without a second border.
  /// Rounded radii lose exactly the inset; a 45° pixel cut moves by the inset
  /// times (√2 − 1), as its diagonal does, to whole pixels; capsules and circles stay.
  static OutlinedBorder inset(
    OutlinedBorder outline,
    double amount, {
    TextDirection textDirection = TextDirection.ltr,
  }) => _offset(outline, -amount, textDirection);

  /// The concentric outline [amount] outside [outline], without a border:
  /// a focus ring's shape (radius plus the gap) around a part.
  static OutlinedBorder outset(
    OutlinedBorder outline,
    double amount, {
    TextDirection textDirection = TextDirection.ltr,
  }) => _offset(outline, amount, textDirection);

  /// [inner] unless its rounded corners have shrunk below [floor]'s, then
  /// [floor]: a highlight set well inside a rounded surface (a menu item)
  /// keeps the family's control corners rather than going square. Square and
  /// cut families are left as they are: their menus select in square bars.
  static OutlinedBorder atLeast(
    OutlinedBorder inner,
    OutlinedBorder floor, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (inner is! RoundedRectangleBorder || floor is! RoundedRectangleBorder) {
      return inner;
    }
    final have = inner.borderRadius.resolve(textDirection);
    final want = floor.borderRadius.resolve(textDirection);
    Radius most(Radius a, Radius b) =>
        Radius.elliptical(math.max(a.x, b.x), math.max(a.y, b.y));
    return inner.copyWith(
      side: BorderSide.none,
      borderRadius: BorderRadius.only(
        topLeft: most(have.topLeft, want.topLeft),
        topRight: most(have.topRight, want.topRight),
        bottomLeft: most(have.bottomLeft, want.bottomLeft),
        bottomRight: most(have.bottomRight, want.bottomRight),
      ),
    );
  }

  /// [outline] with square bottom corners: a part set on the screen's foot
  /// (a sheet) keeps its family at the top and meets the edge flush.
  static OutlinedBorder topOnly(
    OutlinedBorder outline, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    if (outline is! RoundedRectangleBorder) return outline;
    final r = outline.borderRadius.resolve(textDirection);
    return outline.copyWith(
      borderRadius: BorderRadius.only(topLeft: r.topLeft, topRight: r.topRight),
    );
  }

  static OutlinedBorder _offset(
    OutlinedBorder outline,
    double amount,
    TextDirection textDirection,
  ) {
    if (outline is RoundedRectangleBorder) {
      final radius = outline.borderRadius.resolve(textDirection);
      Radius move(Radius value) => value == Radius.zero
          ? Radius.zero
          : Radius.elliptical(
              math.max(0, value.x + amount),
              math.max(0, value.y + amount),
            );
      return outline.copyWith(
        side: BorderSide.none,
        borderRadius: BorderRadius.only(
          topLeft: move(radius.topLeft),
          topRight: move(radius.topRight),
          bottomLeft: move(radius.bottomLeft),
          bottomRight: move(radius.bottomRight),
        ),
      );
    }
    if (outline is RetroDesktopBorder) {
      return outline.cut == 0
          ? outline.copyWith(side: BorderSide.none)
          : outline.copyWith(
              side: BorderSide.none,
              // Whole pixels: the cut is drawn on the pixel grid.
              cut: math.max(
                0,
                (outline.cut + amount * (math.sqrt2 - 1)).roundToDouble(),
              ),
            );
    }
    return outline.copyWith(side: BorderSide.none);
  }

  @override
  bool operator ==(Object other) =>
      other is RetroDesktopShapes &&
      other.small == small &&
      other.medium == medium &&
      other.large == large &&
      other.full == full &&
      other.button == button;
  @override
  int get hashCode => Object.hash(small, medium, large, full, button);
}
