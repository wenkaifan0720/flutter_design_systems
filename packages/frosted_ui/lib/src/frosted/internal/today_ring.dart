import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'styled.dart';

// How strong the ring is on the chosen day, over its ink disc: half the
// disc's words, as the quiet ink is to the primary one beside it.
const double _quietOnChosen = .5;

/// Today on a month's grid (the calendar's, the date picker's and the range
/// picker's): one mark, a hairline ring round the day's figure, the same by
/// day and by night and on any glass. Beside the chosen day it stands at the
/// day's edge in the quiet ink ([color] when a style sets today's edge); on
/// the chosen day it stands [inset] inside the ink disc in the disc's own
/// words made quiet ([onChosen] half-way to the disc), so today still reads
/// when it is the day chosen and stays as quiet as it is beside it. It is
/// paint on the glass, never a glass of its own, and eases between its two
/// places as the day is chosen (a cut under Reduce Motion).
class FrostedTodayRing extends StatelessWidget {
  /// Rings [child], a day's face of [radius] (or cut to [shape]).
  const FrostedTodayRing({
    required this.chosen,
    required this.radius,
    required this.onChosen,
    required this.child,
    this.shape,
    this.color,
    super.key,
  });

  /// How far inside the chosen day's disc the ring stands.
  static const double inset = 3;

  /// Whether today is the day chosen (a range's end included).
  final bool chosen;

  /// The day's face's corner radius.
  final double radius;

  /// The day's face's outline when a style cuts it to one; null draws
  /// [radius].
  final OutlinedBorder? shape;

  /// The ring's colour beside the chosen day; null takes the quiet ink.
  final Color? color;

  /// The colour of the chosen day's figure: the ring on the chosen day takes
  /// it at half strength over the disc.
  final Color onChosen;

  /// The day's face.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final quiet = color ?? t.colorScheme.textSecondary;
    final quietOnChosen = onChosen.withValues(
      alpha: onChosen.a * _quietOnChosen,
    );
    final motion = FrostedMotion.of(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: chosen ? 1 : 0),
              duration: motion.fast,
              curve: motion.curve,
              builder: (context, k, _) {
                final by = inset * k;
                final side = BorderSide(
                  color: Color.lerp(quiet, quietOnChosen, k)!,
                  width: FrostedStrokes.hairline,
                );
                final cut = FrostedStyleLayers.around(shape, -by);
                return Padding(
                  padding: EdgeInsets.all(by),
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape:
                          cut?.copyWith(side: side) ??
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              radius - by < 0 ? 0 : radius - by,
                            ),
                            side: side,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('chosen', value: chosen, ifTrue: 'chosen'))
      ..add(DoubleProperty('radius', radius))
      ..add(ColorProperty('color', color, defaultValue: null))
      ..add(ColorProperty('onChosen', onChosen));
  }
}
