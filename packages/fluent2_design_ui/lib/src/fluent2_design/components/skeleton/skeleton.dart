import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../theme.dart';

import 'package:ui_core/ui_core.dart';

/// A skeleton's ground, Fluent's `appearance`: [opaque] the stencil grey
/// (the default, on a surface), [translucent] its alpha step (on a tinted
/// or photographic ground).
enum Fluent2SkeletonAppearance {
  /// Opaque bones.
  opaque,

  /// Translucent bones, for a skeleton over a picture or a tinted surface.
  translucent,
}

/// How a skeleton breathes, Fluent's `animation`: [wave] a lighter band
/// sweeping each shape every 3 s (the default), [pulse] the shapes fading
/// to 40% and back every second.
enum Fluent2SkeletonAnimation {
  /// A shimmer that sweeps across.
  wave,

  /// A fade in and out.
  pulse,
}

/// A skeleton shape, Fluent's `SkeletonItem` `shape`: a [rectangle] the
/// parent's width (a line of words, corners 4), a [circle] or a [square]
/// of the item's size (an avatar, a thumbnail).
enum Fluent2SkeletonShape {
  /// A rectangle.
  rectangle,

  /// A circle.
  circle,

  /// A square.
  square,
}

/// Fluent 2's Skeleton: the stand-in for content still loading, holding
/// [Fluent2SkeletonItem]s laid as the content will be (an avatar circle
/// beside two lines of a row), all breathing together by its [animation]
/// in its [appearance] (still under Reduce Motion). Read
/// as one busy node, [label] ("Loading files"), its shapes silent.
///
/// ```dart
/// Fluent2Skeleton(child: Row(children: [Fluent2SkeletonItem(shape: Fluent2SkeletonShape.circle, size: 32), SizedBox(width: 12), Expanded(child: Fluent2SkeletonItem())]))
/// ```
class Fluent2Skeleton extends StatefulWidget {
  /// A skeleton of [child]'s bones while content loads.
  const Fluent2Skeleton({
    required this.child,
    this.appearance = Fluent2SkeletonAppearance.opaque,
    this.animation = Fluent2SkeletonAnimation.wave,
    this.label,
    super.key,
  });

  /// The bones: [Fluent2SkeletonItem]s laid out as the content will be.
  final Widget child;

  /// Fluent's `appearance`: opaque or translucent.
  final Fluent2SkeletonAppearance appearance;

  /// Fluent's `animation`: wave or pulse.
  final Fluent2SkeletonAnimation animation;

  /// What a screen reader says; null is "Loading" in the app's language.
  final String? label;

  @override
  State<Fluent2Skeleton> createState() => _Fluent2SkeletonState();
}

class _Fluent2SkeletonState extends State<Fluent2Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Fluent2Skeleton old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) _sync();
  }

  void _sync() {
    _beat.duration = widget.animation == Fluent2SkeletonAnimation.wave
        ? const Duration(seconds: 3)
        : const Duration(seconds: 1);
    if (Fluent2Motion.on(context)) {
      _beat.repeat();
    } else {
      _beat.stop();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label ?? DesignLocalizations.of(context).loadingLabel,
    role: SemanticsRole.loadingSpinner,
    excludeSemantics: true,
    child: _SkeletonScope(
      beat: _beat,
      appearance: widget.appearance,
      animation: widget.animation,
      moving: Fluent2Motion.on(context),
      child: widget.child,
    ),
  );
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({
    required this.beat,
    required this.appearance,
    required this.animation,
    required this.moving,
    required super.child,
  });

  final Animation<double> beat;
  final Fluent2SkeletonAppearance appearance;
  final Fluent2SkeletonAnimation animation;
  final bool moving;

  @override
  bool updateShouldNotify(_SkeletonScope old) =>
      beat != old.beat ||
      appearance != old.appearance ||
      animation != old.animation ||
      moving != old.moving;
}

/// One shape of a [Fluent2Skeleton]: a [rectangle] as wide as [width] (the
/// parent's by default) and [size] tall, or a [circle] or [square] [size]
/// across (Fluent's sizes 8 to 128; 16 by default). Outside a skeleton it
/// stands still in the opaque stencil.
///
/// ```dart
/// Fluent2SkeletonItem(size: 12, width: 160)
/// ```
class Fluent2SkeletonItem extends StatelessWidget {
  /// One bone of a skeleton.
  const Fluent2SkeletonItem({
    this.shape = Fluent2SkeletonShape.rectangle,
    this.size = 16,
    this.width,
    super.key,
  });

  /// Fluent's `shape`: rectangle, circle or square.
  final Fluent2SkeletonShape shape;

  /// A rectangle's height, a circle's or square's side.
  final double size;

  /// A rectangle's width; null fills the parent.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final scope = context.dependOnInheritedWidgetOfExactType<_SkeletonScope>();
    final translucent =
        scope?.appearance == Fluent2SkeletonAppearance.translucent;
    final pulse = scope?.animation == Fluent2SkeletonAnimation.pulse;
    final c = t.colors;
    final base = translucent ? c.neutralStencil1Alpha : c.neutralStencil1;
    final band = translucent
        ? (const Color(0x00000000), c.neutralStencil1Alpha)
        : (c.neutralStencil1, c.neutralStencil2);
    final radius = switch (shape) {
      Fluent2SkeletonShape.rectangle => Fluent2Radius.medium,
      Fluent2SkeletonShape.circle => size / 2,
      Fluent2SkeletonShape.square => Fluent2Radius.none,
    };
    final w = shape == Fluent2SkeletonShape.rectangle
        ? (width ?? double.infinity)
        : size;
    return SizedBox(
      width: w,
      height: size,
      child: CustomPaint(
        painter: _ItemPainter(
          beat: scope?.beat,
          moving: scope?.moving ?? false,
          pulse: pulse,
          base: base,
          from: band.$1,
          to: band.$2,
          radius: radius,
        ),
      ),
    );
  }
}

class _ItemPainter extends CustomPainter {
  _ItemPainter({
    required this.beat,
    required this.moving,
    required this.pulse,
    required this.base,
    required this.from,
    required this.to,
    required this.radius,
  }) : super(repaint: moving ? beat : null);

  final Animation<double>? beat;
  final bool moving;
  final bool pulse;
  final Color base;
  final Color from;
  final Color to;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final phase = moving ? (beat?.value ?? 0) : 0.0;
    if (pulse) {
      // 1 to 0.4 and back, as Fluent's keyframes run.
      final o = moving ? 1 - 0.6 * (1 - (2 * phase - 1).abs()) : 1.0;
      canvas.drawRRect(
        shape,
        Paint()..color = base.withValues(alpha: base.a * o),
      );
      return;
    }
    canvas.drawRRect(shape, Paint()..color = base);
    if (!moving) return;
    // The band sweeps from one width before the shape to one past it,
    // easing in and out.
    final eased = Curves.easeInOut.transform(phase);
    final x = -size.width + eased * size.width * 2;
    final band = Rect.fromLTWH(x, 0, size.width, size.height);
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [from, to, from],
          stops: const [0, 0.5, 1],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ItemPainter old) =>
      old.moving != moving ||
      old.pulse != pulse ||
      old.base != base ||
      old.from != from ||
      old.to != to ||
      old.radius != radius ||
      old.beat != beat;
}
