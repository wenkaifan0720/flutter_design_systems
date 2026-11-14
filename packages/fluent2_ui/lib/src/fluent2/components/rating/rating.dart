import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/hit_slop.dart';
import '../../internal/key_focus.dart';
import '../../internal/well.dart';
import '../../theme.dart';

/// The ink a rating's stars wear: Fluent's `neutral` (the first ink),
/// `brand`, or `marigold` (a review's gold).
enum Fluent2RatingColor {
  /// Neutral stars.
  neutral,

  /// Stars in the brand colour.
  brand,

  /// Fluent's marigold stars.
  marigold,
}

/// A rating's star size: 12, 16, 20 or 28.
enum Fluent2RatingSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,

  /// The extra-large size.
  extraLarge,
}

double _starOf(Fluent2RatingSize size) => switch (size) {
  Fluent2RatingSize.small => 12,
  Fluent2RatingSize.medium => 16,
  Fluent2RatingSize.large => 20,
  Fluent2RatingSize.extraLarge => 28,
};

/// The colours of one rating: the chosen stars', the others' (outline or
/// filled appearance), and the edge a light marigold star wears where its
/// gold misses 3:1 on the surface.
class _Inks {
  const _Inks(this.selected, this.unselected, this.edge);

  final Color selected;
  final Color unselected;
  final Color? edge;

  static _Inks of(
    Fluent2ThemeData t,
    Fluent2RatingColor color, {
    required bool filled,
    required bool enabled,
  }) {
    final c = t.colors;
    if (!enabled) {
      return _Inks(
        c.neutralForegroundDisabled,
        filled ? fluent2WellDisabled(t) : c.neutralForegroundDisabled,
        null,
      );
    }
    switch (color) {
      case Fluent2RatingColor.neutral:
        // The unfilled stars are the measure's rail, as a progress bar's
        // track: Fluent's grey laid over the ground, so they show on the
        // tinted page as on a card.
        return _Inks(
          c.neutralForeground1,
          filled ? fluent2Rail(t) : c.neutralForeground1,
          null,
        );
      case Fluent2RatingColor.brand:
        return _Inks(
          c.brandForeground1,
          // Fluent's brand tint is the tinted page's own colour, so the
          // unfilled stars stand on the grey rail instead.
          filled ? fluent2Rail(t) : c.brandForeground1,
          null,
        );
      case Fluent2RatingColor.marigold:
        final gold = t.sharedColors.paletteMarigoldBorderActive;
        final edge = Fluent2ThemeData.contrast(gold, t.surface) < 3
            ? t.sharedColors.paletteMarigoldForeground2
            : null;
        return _Inks(gold, filled ? fluent2Rail(t) : (edge ?? gold), edge);
    }
  }
}

/// One star: the unselected glyph, the selected one over it (its start
/// half only when [fill] is a half), the light-marigold edge over both.
class _Star extends StatelessWidget {
  const _Star({
    required this.size,
    required this.fill,
    required this.inks,
    required this.filled,
  });

  final double size;
  final double fill;
  final _Inks inks;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final edge = inks.edge;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Icon(
            filled ? Fluent2Icons.starFilled : Fluent2Icons.star,
            size: size,
            color: inks.unselected,
          ),
          if (fill > 0)
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: fill >= 1 ? 1 : 0.5,
                child: Icon(
                  Fluent2Icons.starFilled,
                  size: size,
                  color: inks.selected,
                ),
              ),
            ),
          if (edge != null && fill > 0)
            Icon(Fluent2Icons.star, size: size, color: edge),
        ],
      ),
    );
  }
}

String _figure(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Fluent 2's Rating: a row of [max] stars (28 by default, Fluent's
/// extra-large; 12, 16 and 20 too) to give a score: the chosen stars
/// filled in the [color]'s ink, the rest outlined in it; with
/// [allowHalf] a star's start half chooses the half step. The pointer
/// previews the score it passes over, a press or a drag across the row
/// sets it; arrows step it, Home and End take the least and the most.
/// Null [onChanged] draws it disabled. Read as an adjustable named
/// [label] saying "3 of 5".
///
/// ```dart
/// Fluent2Rating(label: 'Rate this meeting', value: score, onChanged: (v) => setState(() => score = v))
/// ```
class Fluent2Rating extends StatefulWidget {
  /// A rating the user sets, [value] of [max] stars.
  const Fluent2Rating({
    required this.value,
    required this.onChanged,
    required this.label,
    this.max = 5,
    this.allowHalf = false,
    this.color = Fluent2RatingColor.neutral,
    this.size = Fluent2RatingSize.extraLarge,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The score, 0 (none chosen) to [max].
  final double value;

  /// Called with the rating the user picks; null puts it out of use.
  final ValueChanged<double>? onChanged;

  /// What a screen reader calls the rating.
  final String label;

  /// How many stars it has.
  final int max;

  /// Whether half stars can be picked.
  final bool allowHalf;

  /// Fluent's `color`: the stars' colour.
  final Fluent2RatingColor color;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2RatingSize size;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  State<Fluent2Rating> createState() => _Fluent2RatingState();
}

class _Fluent2RatingState extends State<Fluent2Rating> {
  double? _hover;

  double get _step => widget.allowHalf ? 0.5 : 1;

  double _clamp(double v) => v.clamp(_step, widget.max.toDouble());

  void _set(double v) {
    final next = _clamp(v);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  double _at(Offset local, double width) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final star = width / widget.max;
    final x = (rtl ? width - local.dx : local.dx).clamp(0.0, width - 0.01);
    final whole = (x / star).floor();
    final part = x - whole * star;
    final half = widget.allowHalf && part < star / 2;
    return _clamp(whole + (half ? 0.5 : 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final live = widget.onChanged != null;
    final inks = _Inks.of(t, widget.color, filled: false, enabled: live);
    final size = _starOf(widget.size);
    final shown = _hover ?? widget.value;
    final width = size * widget.max;
    final step = _step;
    String words(double v) => '${_figure(v)} of ${widget.max}';
    final row = SizedBox(
      width: width,
      height: size,
      child: Row(
        children: [
          for (var i = 0; i < widget.max; i++)
            _Star(
              size: size,
              fill: (shown - i).clamp(0.0, 1.0),
              inks: inks,
              filled: false,
            ),
        ],
      ),
    );
    final value = widget.value;
    final rating = Semantics(
      container: true,
      label: widget.label,
      value: words(value),
      enabled: live,
      increasedValue: live && value < widget.max
          ? words(_clamp(value + step))
          : null,
      decreasedValue: live && value > step ? words(_clamp(value - step)) : null,
      onIncrease: live && value < widget.max ? () => _set(value + step) : null,
      onDecrease: live && value > step ? () => _set(value - step) : null,
      child: ExcludeSemantics(
        child: Fluent2HitSlop(
          child: Fluent2KeyFocus(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            enabled: live,
            radius: Fluent2Radius.medium,
            keys: !live
                ? const {}
                : {
                    LogicalKeyboardKey.arrowRight: () => _set(value + step),
                    LogicalKeyboardKey.arrowUp: () => _set(value + step),
                    LogicalKeyboardKey.arrowLeft: () => _set(value - step),
                    LogicalKeyboardKey.arrowDown: () => _set(value - step),
                    LogicalKeyboardKey.home: () => _set(step),
                    LogicalKeyboardKey.end: () => _set(widget.max.toDouble()),
                  },
            child: !live
                ? row
                : MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onHover: (e) =>
                        setState(() => _hover = _at(e.localPosition, width)),
                    onExit: (_) => setState(() => _hover = null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _set(_at(d.localPosition, width)),
                      onHorizontalDragUpdate: (d) =>
                          _set(_at(d.localPosition, width)),
                      child: row,
                    ),
                  ),
          ),
        ),
      ),
    );
    // Its own width even where the row is tight, so a press past the last
    // star chooses nothing.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: rating,
    );
  }
}

/// Fluent 2's RatingDisplay: a score shown, not given: [max] stars (16
/// by default) with the score's filled in the [color]'s ink over the
/// others filled in Fluent's grey (laid over the ground, so they show on a
/// tinted page as on a card), rounded to the half; then the
/// [value] in caption1 strong and the [count] after a middle dot ("4.5
/// · 1,160"), body1 at large and body2 at extra-large. [compact] draws
/// one filled star and the words. Read as one image: "Rated 4.5 out of
/// 5, 1,160 ratings".
///
/// ```dart
/// Fluent2RatingDisplay(value: 4.5, count: 1160, color: Fluent2RatingColor.marigold)
/// ```
class Fluent2RatingDisplay extends StatelessWidget {
  /// A read-only rating: [value] of [max] stars.
  const Fluent2RatingDisplay({
    required this.value,
    this.count,
    this.max = 5,
    this.color = Fluent2RatingColor.neutral,
    this.size = Fluent2RatingSize.medium,
    this.compact = false,
    this.showValue = true,
    super.key,
  });

  /// The rating shown.
  final double value;

  /// How many scores the [value] is made of.
  final int? count;

  /// How many stars it has.
  final int max;

  /// Fluent's `color`: the stars' colour.
  final Fluent2RatingColor color;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2RatingSize size;

  /// One star and the words, for a row with no room.
  final bool compact;

  /// Whether the score's figure follows the stars.
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final inks = _Inks.of(t, color, filled: true, enabled: true);
    final star = _starOf(size);
    final shown = (value * 2).round() / 2;
    final (TextStyle type, double gap) = switch (size) {
      Fluent2RatingSize.small ||
      Fluent2RatingSize.medium => (t.caption1, Fluent2Spacing.xs),
      Fluent2RatingSize.large => (t.body1, Fluent2Spacing.sNudge),
      Fluent2RatingSize.extraLarge => (t.body2, Fluent2Spacing.s),
    };
    final n = count;
    final counted = n == null
        ? null
        : MaterialLocalizations.of(context).formatDecimal(n);
    final words = <String>[if (showValue || compact) _figure(value), ?counted];
    return Semantics(
      container: true,
      image: true,
      label: [
        'Rated ${_figure(value)} out of $max',
        if (counted != null) '$counted ${n == 1 ? 'rating' : 'ratings'}',
      ].join(', '),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (compact)
              _Star(size: star, fill: 1, inks: inks, filled: true)
            else
              for (var i = 0; i < max; i++)
                _Star(
                  size: star,
                  fill: (shown - i).clamp(0.0, 1.0),
                  inks: inks,
                  filled: true,
                ),
            if (words.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: gap),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (showValue || compact)
                          TextSpan(text: _figure(value), style: type.strong),
                        if (counted != null)
                          TextSpan(
                            text: (showValue || compact)
                                ? ' · $counted'
                                : counted,
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: type.c(c.neutralForeground1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
