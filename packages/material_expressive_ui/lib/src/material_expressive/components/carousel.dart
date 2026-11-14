/// Carousels — multi-browse, uncontained, centred hero and full-screen — and
/// the page indicator (CONTRACT §4.1 `carousel`, `page-indicator`). Owner:
/// w3-cards.
///
/// A port of Compose's `carousel/` package (material3 1.5.0-alpha29):
///
/// - **Keylines** (`Keylines.kt`, `KeylineList.kt`, `Arrangement.kt`): each
///   variant fits large, medium and small item sizes to the carousel's
///   width (`multiBrowseKeylineList`, `uncontainedKeylineList`,
///   `heroKeylineList`), and lays them out as keylines — a size and a
///   centre per slot, with an anchor just outside either edge.
/// - **Strategy** (`Strategy.kt`): the keylines at rest, plus the steps
///   that shift them as the first and last items scroll into place, and the
///   keyline list for any scroll offset.
/// - **Items** (`Carousel.kt`, `Modifier.carouselItem`): every item is laid
///   out at the focal size and placed like a pager page; the keylines it
///   falls between give its mask (the visible part, centred in the item)
///   and a translation that pins masked items edge to edge. The content is
///   drawn at full size under the mask, so an item's picture stays centred
///   as its mask narrows: the parallax Material's carousel shows.
/// - **Snapping** (`KeylineSnapPosition.kt`, `CarouselDefaults`): items
///   snap to their keyline positions, at most one item per fling for the
///   multi-browse, hero and full-screen carousels; the uncontained carousel
///   scrolls freely. The platform's scroll physics owns overscroll (stretch
///   on Android, rubber band on iOS; CONTRACT §5).
///
/// The layout runs in device pixels as Compose's does (its page size,
/// spacing and snap offsets are whole pixels), so geometry lands where the
/// oracle's does. Lengths come from `CarouselBehavior` (Compose's
/// `CarouselDefaults`); the ratios in the strategy maths are Compose's own
/// arithmetic, cited where they appear.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../internal/tokens/behavior.g.dart';
import '../internal/styled_content.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Keylines (KeylineList.kt)
// ---------------------------------------------------------------------------

/// One keyline (Compose's `Keyline`): where an item of [size] sits when its
/// centre reaches [unadjustedOffset] — at [offset], cut off by [cutoff] at
/// an edge. In the layout's own unit (device pixels in a carousel).
@immutable
class ExpressiveCarouselKeyline {
  /// A keyline of [size] at [offset], reached when an item's centre is at [unadjustedOffset].
  const ExpressiveCarouselKeyline({
    required this.size,
    required this.offset,
    required this.unadjustedOffset,
    required this.isFocal,
    required this.isAnchor,
    required this.isPivot,
    required this.cutoff,
  });

  /// The size of an item's mask at this keyline.
  final double size;

  /// The centre of an item's mask at this keyline.
  final double offset;

  /// The centre an item would have if every item were the focal size.
  final double unadjustedOffset;

  /// Whether this is a focal (fully shown, largest) keyline.
  final bool isFocal;

  /// Whether this is an anchor just outside the carousel.
  final bool isAnchor;

  /// Whether the list was laid out from this keyline.
  final bool isPivot;

  /// How much of an item here is cut off by the carousel's edge.
  final double cutoff;

  /// Compose's `lerp(Keyline, Keyline, fraction)`.
  static ExpressiveCarouselKeyline lerp(
    ExpressiveCarouselKeyline a,
    ExpressiveCarouselKeyline b,
    double t,
  ) => ExpressiveCarouselKeyline(
    size: _lerp(a.size, b.size, t),
    offset: _lerp(a.offset, b.offset, t),
    unadjustedOffset: _lerp(a.unadjustedOffset, b.unadjustedOffset, t),
    isFocal: t < 0.5 ? a.isFocal : b.isFocal,
    isAnchor: t < 0.5 ? a.isAnchor : b.isAnchor,
    isPivot: t < 0.5 ? a.isPivot : b.isPivot,
    cutoff: _lerp(a.cutoff, b.cutoff, t),
  );

  ExpressiveCarouselKeyline _withUnadjustedOffset(double value) =>
      ExpressiveCarouselKeyline(
        size: size,
        offset: offset,
        unadjustedOffset: value,
        isFocal: isFocal,
        isAnchor: isAnchor,
        isPivot: isPivot,
        cutoff: cutoff,
      );

  @override
  bool operator ==(Object other) =>
      other is ExpressiveCarouselKeyline &&
      other.size == size &&
      other.offset == offset &&
      other.unadjustedOffset == unadjustedOffset &&
      other.isFocal == isFocal &&
      other.isAnchor == isAnchor &&
      other.isPivot == isPivot &&
      other.cutoff == cutoff;

  @override
  int get hashCode => Object.hash(
    size,
    offset,
    unadjustedOffset,
    isFocal,
    isAnchor,
    isPivot,
    cutoff,
  );

  @override
  String toString() =>
      'Keyline(size: $size, offset: $offset, unadjusted: $unadjustedOffset'
      '${isFocal ? ', focal' : ''}${isAnchor ? ', anchor' : ''}'
      '${isPivot ? ', pivot' : ''}, cutoff: $cutoff)';
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Compose's `lerp(outputMin, outputMax, inputMin, inputMax, value)`.
double _lerpRange(
  double outputMin,
  double outputMax,
  double inputMin,
  double inputMax,
  double value,
) {
  if (value <= inputMin) return outputMin;
  if (value >= inputMax) return outputMax;
  return _lerp(
    outputMin,
    outputMax,
    (value - inputMin) / (inputMax - inputMin),
  );
}

/// An ordered list of keylines (Compose's `KeylineList`).
@immutable
class ExpressiveCarouselKeylines {
  /// A keyline list of [keylines], start to end.
  ExpressiveCarouselKeylines(List<ExpressiveCarouselKeyline> keylines)
    : keylines = List<ExpressiveCarouselKeyline>.unmodifiable(keylines),
      minSize = keylines.fold(
        double.maxFinite,
        (min, k) => k.size < min ? k.size : min,
      ),
      maxSize = keylines.fold(0, (max, k) => k.size > max ? k.size : max),
      pivotIndex = keylines.indexWhere((k) => k.isPivot),
      firstNonAnchorIndex = keylines.indexWhere((k) => !k.isAnchor),
      lastNonAnchorIndex = keylines.lastIndexWhere((k) => !k.isAnchor),
      firstFocalIndex = keylines.indexWhere((k) => k.isFocal),
      lastFocalIndex = keylines.lastIndexWhere((k) => k.isFocal);

  /// No keylines: a carousel with nothing to lay out.
  static final ExpressiveCarouselKeylines empty = ExpressiveCarouselKeylines(
    const <ExpressiveCarouselKeyline>[],
  );

  /// The keylines, start to end.
  final List<ExpressiveCarouselKeyline> keylines;

  /// The smallest keyline size.
  final double minSize;

  /// The largest keyline size.
  final double maxSize;

  /// The index of the pivot keyline, or -1 when there is none.
  final int pivotIndex;

  /// The index of the first keyline that is not an anchor, or -1 when there is none.
  final int firstNonAnchorIndex;

  /// The index of the last keyline that is not an anchor, or -1 when there is none.
  final int lastNonAnchorIndex;

  /// The index of the first focal keyline, or -1 when there is none.
  final int firstFocalIndex;

  /// The index of the last focal keyline, or -1 when there is none.
  final int lastFocalIndex;

  /// The number of keylines.
  int get length => keylines.length;

  /// Whether there are no keylines.
  bool get isEmpty => keylines.isEmpty;

  /// Whether there is at least one keyline.
  bool get isNotEmpty => keylines.isNotEmpty;

  /// The index of the last keyline.
  int get lastIndex => keylines.length - 1;

  /// The keyline at [index].
  ExpressiveCarouselKeyline operator [](int index) => keylines[index];

  /// The first keyline.
  ExpressiveCarouselKeyline get first => keylines.first;

  /// The last keyline.
  ExpressiveCarouselKeyline get last => keylines.last;

  /// The pivot keyline.
  ExpressiveCarouselKeyline get pivot => keylines[pivotIndex];

  /// The first keyline that is not an anchor.
  ExpressiveCarouselKeyline get firstNonAnchor => keylines[firstNonAnchorIndex];

  /// The last keyline that is not an anchor.
  ExpressiveCarouselKeyline get lastNonAnchor => keylines[lastNonAnchorIndex];

  /// The first focal keyline; every non-empty list has one.
  ExpressiveCarouselKeyline get firstFocal {
    if (firstFocalIndex < 0) {
      throw StateError(
        'All keyline lists must have at least one focal keyline',
      );
    }
    return keylines[firstFocalIndex];
  }

  /// The last focal keyline.
  ExpressiveCarouselKeyline get lastFocal {
    if (lastFocalIndex < 0) {
      throw StateError(
        'All keyline lists must have at least one focal keyline',
      );
    }
    return keylines[lastFocalIndex];
  }

  /// How many focal keylines there are.
  int get focalCount => lastFocalIndex - firstFocalIndex + 1;

  bool _isFirstFocalItemAtStartOfContainer() {
    final left = firstFocal.offset - firstFocal.size / 2;
    return left >= 0 && firstFocal == firstNonAnchor;
  }

  bool _isLastFocalItemAtEndOfContainer(double mainAxisSize) {
    final right = lastFocal.offset + lastFocal.size / 2;
    return right <= mainAxisSize && lastFocal == lastNonAnchor;
  }

  int _firstIndexAfterFocalRangeWithSize(double size) {
    for (var i = lastFocalIndex; i <= lastIndex; i++) {
      if (keylines[i].size == size) return i;
    }
    return lastIndex;
  }

  int _lastIndexBeforeFocalRangeWithSize(double size) {
    for (var i = firstFocalIndex - 1; i >= 0; i--) {
      if (keylines[i].size == size) return i;
    }
    return 0;
  }

  /// The last keyline before [unadjustedOffset] (`getKeylineBefore`).
  ExpressiveCarouselKeyline keylineBefore(double unadjustedOffset) {
    for (var i = lastIndex; i >= 0; i--) {
      if (keylines[i].unadjustedOffset < unadjustedOffset) return keylines[i];
    }
    return first;
  }

  /// The first keyline at or after [unadjustedOffset] (`getKeylineAfter`).
  ExpressiveCarouselKeyline keylineAfter(double unadjustedOffset) {
    for (final k in keylines) {
      if (k.unadjustedOffset >= unadjustedOffset) return k;
    }
    return last;
  }

  /// Compose's `lerp(KeylineList, KeylineList, fraction)`.
  static ExpressiveCarouselKeylines lerp(
    ExpressiveCarouselKeylines from,
    ExpressiveCarouselKeylines to,
    double t,
  ) => ExpressiveCarouselKeylines(<ExpressiveCarouselKeyline>[
    for (var i = 0; i < from.length; i++)
      ExpressiveCarouselKeyline.lerp(from[i], to[i], t),
  ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExpressiveCarouselKeylines || other.length != length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (keylines[i] != other[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(keylines);

  @override
  String toString() => 'ExpressiveCarouselKeylines($keylines)';

  // --- Construction (KeylineListScopeImpl) --------------------------------

  /// A left-aligned (`CarouselAlignment.Start`) list of [sizes].
  static ExpressiveCarouselKeylines _aligned(
    double mainAxisSize,
    double spacing,
    _Alignment alignment,
    void Function(_KeylineBuilder add) build,
  ) {
    final builder = _KeylineBuilder();
    build(builder);
    return builder.withAlignment(mainAxisSize, spacing, alignment);
  }

  static ExpressiveCarouselKeylines _pivoted(
    double mainAxisSize,
    double spacing,
    int pivotIndex,
    double pivotOffset,
    void Function(_KeylineBuilder add) build,
  ) {
    final builder = _KeylineBuilder();
    build(builder);
    return builder.withPivot(mainAxisSize, spacing, pivotIndex, pivotOffset);
  }
}

/// Compose's `CarouselAlignment`.
enum _Alignment { start, center, end }

/// Compose's `KeylineListScopeImpl`.
class _KeylineBuilder {
  final List<(double, bool)> _tmp = <(double, bool)>[];
  int _firstFocalIndex = -1;
  double _focalItemSize = 0;

  void add(double size, {bool isAnchor = false}) {
    _tmp.add((size, isAnchor));
    if (!isAnchor && size > _focalItemSize) {
      _firstFocalIndex = _tmp.length - 1;
      _focalItemSize = size;
    }
  }

  int _lastFocalIndex() {
    if (_firstFocalIndex < 0) return -1;
    var last = _firstFocalIndex;
    while (last < _tmp.length - 1 && _tmp[last + 1].$1 == _focalItemSize) {
      last++;
    }
    return last;
  }

  ExpressiveCarouselKeylines withPivot(
    double mainAxisSize,
    double spacing,
    int pivotIndex,
    double pivotOffset,
  ) => ExpressiveCarouselKeylines(
    _create(
      pivotIndex,
      pivotOffset,
      _firstFocalIndex,
      _lastFocalIndex(),
      _focalItemSize,
      mainAxisSize,
      spacing,
    ),
  );

  ExpressiveCarouselKeylines withAlignment(
    double mainAxisSize,
    double spacing,
    _Alignment alignment,
  ) {
    final lastFocalIndex = _lastFocalIndex();
    // Compose counts the focal range's gaps here, not its items.
    final focalItemCount = lastFocalIndex - _firstFocalIndex;
    final pivotIndex = _firstFocalIndex;
    final double pivotOffset;
    switch (alignment) {
      case _Alignment.center:
        final split = spacing == 0 || focalItemCount % 2 == 0
            ? 0.0
            : spacing / 2;
        final spaceCounts = (focalItemCount ~/ 2) * spacing;
        pivotOffset =
            mainAxisSize / 2 -
            (_focalItemSize / 2) * focalItemCount -
            split -
            spaceCounts;
      case _Alignment.end:
        pivotOffset = mainAxisSize - _focalItemSize / 2;
      case _Alignment.start:
        pivotOffset = _focalItemSize / 2;
    }
    return ExpressiveCarouselKeylines(
      _create(
        pivotIndex,
        pivotOffset,
        _firstFocalIndex,
        lastFocalIndex,
        _focalItemSize,
        mainAxisSize,
        spacing,
      ),
    );
  }

  List<ExpressiveCarouselKeyline> _create(
    int pivotIndex,
    double pivotOffset,
    int firstFocalIndex,
    int lastFocalIndex,
    double itemSize,
    double mainAxisSize,
    double spacing,
  ) {
    if (_tmp.isEmpty || pivotIndex < 0 || pivotIndex >= _tmp.length) {
      return const <ExpressiveCarouselKeyline>[];
    }
    bool cutoffLeft(double size, double offset) =>
        offset - size / 2 < 0 && offset + size / 2 > 0;
    bool cutoffRight(double size, double offset) =>
        offset - size / 2 < mainAxisSize && offset + size / 2 > mainAxisSize;
    bool focal(int i) => i >= firstFocalIndex && i <= lastFocalIndex;

    final (pivotSize, pivotAnchor) = _tmp[pivotIndex];
    final keylines = <ExpressiveCarouselKeyline>[
      ExpressiveCarouselKeyline(
        size: pivotSize,
        offset: pivotOffset,
        unadjustedOffset: pivotOffset,
        isFocal: focal(pivotIndex),
        isAnchor: pivotAnchor,
        isPivot: true,
        cutoff: cutoffLeft(pivotSize, pivotOffset)
            ? pivotOffset - pivotSize / 2
            : cutoffRight(pivotSize, pivotOffset)
            ? pivotOffset + pivotSize / 2 - mainAxisSize
            : 0,
      ),
    ];

    var offset = pivotOffset - itemSize / 2 - spacing;
    var unadjusted = pivotOffset - itemSize / 2 - spacing;
    for (var i = pivotIndex - 1; i >= 0; i--) {
      final (size, anchor) = _tmp[i];
      final at = offset - size / 2;
      keylines.insert(
        0,
        ExpressiveCarouselKeyline(
          size: size,
          offset: at,
          unadjustedOffset: unadjusted - itemSize / 2,
          isFocal: focal(i),
          isAnchor: anchor,
          isPivot: false,
          cutoff: cutoffLeft(size, at) ? (at - size / 2).abs() : 0,
        ),
      );
      offset -= size + spacing;
      unadjusted -= itemSize + spacing;
    }

    offset = pivotOffset + itemSize / 2 + spacing;
    unadjusted = pivotOffset + itemSize / 2 + spacing;
    for (var i = pivotIndex + 1; i < _tmp.length; i++) {
      final (size, anchor) = _tmp[i];
      final at = offset + size / 2;
      keylines.add(
        ExpressiveCarouselKeyline(
          size: size,
          offset: at,
          unadjustedOffset: unadjusted + itemSize / 2,
          isFocal: focal(i),
          isAnchor: anchor,
          isPivot: false,
          cutoff: cutoffRight(size, at) ? at + size / 2 - mainAxisSize : 0,
        ),
      );
      offset += size + spacing;
      unadjusted += itemSize + spacing;
    }
    return keylines;
  }
}

// ---------------------------------------------------------------------------
// Arrangements (Arrangement.kt) and the three keyline strategies (Keylines.kt)
// ---------------------------------------------------------------------------

/// Compose's `Arrangement`: how many small, medium and large items, at
/// which sizes.
class _Arrangement {
  const _Arrangement(
    this.priority,
    this.smallSize,
    this.smallCount,
    this.mediumSize,
    this.mediumCount,
    this.largeSize,
    this.largeCount,
  );

  /// `Arrangement.MediumItemFlexPercentage`: how much a medium item may
  /// flex to bring the large items to their target size.
  static const double _mediumItemFlexPercentage = .1;

  final int priority;
  final double smallSize;
  final int smallCount;
  final double mediumSize;
  final int mediumCount;
  final double largeSize;
  final int largeCount;

  int get itemCount => largeCount + mediumCount + smallCount;

  bool get _isValid {
    if (largeCount > 0 && smallCount > 0 && mediumCount > 0) {
      return largeSize > mediumSize && mediumSize > smallSize;
    } else if (largeCount > 0 && smallCount > 0) {
      return largeSize > smallSize;
    }
    return true;
  }

  double _cost(double targetLargeSize) => _isValid
      ? (targetLargeSize - largeSize).abs() * priority
      : double.maxFinite;

  static _Arrangement? findLowestCost({
    required double availableSpace,
    required double itemSpacing,
    required double targetSmallSize,
    required double minSmallSize,
    required double maxSmallSize,
    required List<int> smallCounts,
    required double targetMediumSize,
    required List<int> mediumCounts,
    required double targetLargeSize,
    required List<int> largeCounts,
  }) {
    _Arrangement? lowest;
    var priority = 1;
    for (final largeCount in largeCounts) {
      for (final mediumCount in mediumCounts) {
        for (final smallCount in smallCounts) {
          final arrangement = _fit(
            priority: priority,
            availableSpace: availableSpace,
            itemSpacing: itemSpacing,
            smallCount: smallCount,
            smallSize: targetSmallSize,
            minSmallSize: minSmallSize,
            maxSmallSize: maxSmallSize,
            mediumCount: mediumCount,
            mediumSize: targetMediumSize,
            largeCount: largeCount,
            largeSize: targetLargeSize,
          );
          if (lowest == null ||
              arrangement._cost(targetLargeSize) <
                  lowest._cost(targetLargeSize)) {
            lowest = arrangement;
            if (lowest._cost(targetLargeSize) == 0) return lowest;
          }
          priority++;
        }
      }
    }
    return lowest;
  }

  static _Arrangement _fit({
    required int priority,
    required double availableSpace,
    required double itemSpacing,
    required int smallCount,
    required double smallSize,
    required double minSmallSize,
    required double maxSmallSize,
    required int mediumCount,
    required double mediumSize,
    required int largeCount,
    required double largeSize,
  }) {
    final total = largeCount + mediumCount + smallCount;
    final space = availableSpace - (total - 1) * itemSpacing;
    var small = smallSize.clamp(minSmallSize, maxSmallSize);
    var medium = mediumSize;
    var large = largeSize;
    final taken =
        large * largeCount + medium * mediumCount + small * smallCount;
    final delta = space - taken;
    if (smallCount > 0 && delta > 0) {
      small += math.min(delta / smallCount, maxSmallSize - small);
    } else if (smallCount > 0 && delta < 0) {
      small += math.max(delta / smallCount, minSmallSize - small);
    }
    small = smallCount > 0 ? small : 0;
    large =
        (space - (smallCount + mediumCount / 2) * small) /
        (largeCount + mediumCount / 2);
    medium = (large + small) / 2;
    if (mediumCount > 0 && large != largeSize) {
      final targetAdjustment = (largeSize - large) * largeCount;
      final flex = medium * _mediumItemFlexPercentage * mediumCount;
      final distribute = math.min(targetAdjustment.abs(), flex);
      if (targetAdjustment > 0) {
        medium -= distribute / mediumCount;
        large += distribute / largeCount;
      } else {
        medium += distribute / mediumCount;
        large -= distribute / largeCount;
      }
    }
    return _Arrangement(
      priority,
      small,
      smallCount,
      medium,
      mediumCount,
      large,
      largeCount,
    );
  }
}

List<int> _descending(int max, int min) => <int>[
  for (var count = max; count >= min; count--) count,
];

ExpressiveCarouselKeylines _leftAligned(
  double mainAxisSize,
  double spacing,
  double leftAnchor,
  double rightAnchor,
  _Arrangement a,
) => ExpressiveCarouselKeylines._aligned(
  mainAxisSize,
  spacing,
  _Alignment.start,
  (add) {
    add.add(leftAnchor, isAnchor: true);
    for (var i = 0; i < a.largeCount; i++) {
      add.add(a.largeSize);
    }
    for (var i = 0; i < a.mediumCount; i++) {
      add.add(a.mediumSize);
    }
    for (var i = 0; i < a.smallCount; i++) {
      add.add(a.smallSize);
    }
    add.add(rightAnchor, isAnchor: true);
  },
);

ExpressiveCarouselKeylines _centerAligned(
  double mainAxisSize,
  double spacing,
  double leftAnchor,
  double rightAnchor,
  _Arrangement a,
) => ExpressiveCarouselKeylines._aligned(
  mainAxisSize,
  spacing,
  _Alignment.center,
  (add) {
    add.add(leftAnchor, isAnchor: true);
    for (var i = 0; i < a.smallCount ~/ 2; i++) {
      add.add(a.smallSize);
    }
    for (var i = 0; i < a.mediumCount ~/ 2; i++) {
      add.add(a.mediumSize);
    }
    for (var i = 0; i < a.largeCount; i++) {
      add.add(a.largeSize);
    }
    for (var i = 0; i < a.mediumCount ~/ 2; i++) {
      add.add(a.mediumSize);
    }
    for (var i = 0; i < a.smallCount ~/ 2; i++) {
      add.add(a.smallSize);
    }
    add.add(rightAnchor, isAnchor: true);
  },
);

/// Compose's `multiBrowseKeylineList`: as many large items of
/// [preferredItemSize] as fit, then one medium and one small item peeking.
/// Every length in the same unit (device pixels in a carousel).
ExpressiveCarouselKeylines expressiveMultiBrowseKeylines({
  required double mainAxisSize,
  required double preferredItemSize,
  required double itemSpacing,
  required int itemCount,
  required double minSmallItemSize,
  required double maxSmallItemSize,
  required double anchorSize,
}) {
  if (mainAxisSize == 0 || preferredItemSize == 0) {
    return ExpressiveCarouselKeylines.empty;
  }
  var smallCounts = <int>[1];
  const mediumCounts = <int>[1, 0];
  final targetLarge = math.min(preferredItemSize, mainAxisSize);
  // A small item is a third of a large one, within its bounds (Compose).
  final targetSmall = (targetLarge / 3).clamp(
    minSmallItemSize,
    maxSmallItemSize,
  );
  final targetMedium = (targetLarge + targetSmall) / 2;
  if (mainAxisSize < minSmallItemSize * 2) smallCounts = <int>[0];
  final minLargeSpace =
      mainAxisSize -
      targetMedium * mediumCounts.reduce(math.max) -
      maxSmallItemSize * smallCounts.reduce(math.max);
  final minLargeCount = math.max(1, (minLargeSpace / targetLarge).floor());
  final maxLargeCount = (mainAxisSize / targetLarge).ceil();
  final largeCounts = _descending(maxLargeCount, minLargeCount);
  var arrangement = _Arrangement.findLowestCost(
    availableSpace: mainAxisSize,
    itemSpacing: itemSpacing,
    targetSmallSize: targetSmall,
    minSmallSize: minSmallItemSize,
    maxSmallSize: maxSmallItemSize,
    smallCounts: smallCounts,
    targetMediumSize: targetMedium,
    mediumCounts: mediumCounts,
    targetLargeSize: targetLarge,
    largeCounts: largeCounts,
  );
  if (arrangement != null && arrangement.itemCount > itemCount) {
    var surplus = arrangement.itemCount - itemCount;
    var smallCount = arrangement.smallCount;
    var mediumCount = arrangement.mediumCount;
    while (surplus > 0) {
      if (smallCount > 0) {
        smallCount -= 1;
      } else if (mediumCount > 1) {
        mediumCount -= 1;
      }
      surplus -= 1;
    }
    arrangement = _Arrangement.findLowestCost(
      availableSpace: mainAxisSize,
      itemSpacing: itemSpacing,
      targetSmallSize: targetSmall,
      minSmallSize: minSmallItemSize,
      maxSmallSize: maxSmallItemSize,
      smallCounts: <int>[smallCount],
      targetMediumSize: targetMedium,
      mediumCounts: <int>[mediumCount],
      targetLargeSize: targetLarge,
      largeCounts: largeCounts,
    );
  }
  if (arrangement == null) return ExpressiveCarouselKeylines.empty;
  return _leftAligned(
    mainAxisSize,
    itemSpacing,
    anchorSize,
    anchorSize,
    arrangement,
  );
}

/// Compose's `uncontainedKeylineList`: items of [itemSize] from the start,
/// the last one cut off at the end.
ExpressiveCarouselKeylines expressiveUncontainedKeylines({
  required double mainAxisSize,
  required double itemSize,
  required double itemSpacing,
  required double anchorSize,
  double mediumLargeItemDiffThreshold =
      CarouselBehavior.mediumLargeItemDiffThreshold,
}) {
  if (mainAxisSize == 0 || itemSize == 0) {
    return ExpressiveCarouselKeylines.empty;
  }
  final largeSize = math.min(itemSize + itemSpacing, mainAxisSize);
  final largeCount = math.max(1, (mainAxisSize / largeSize).floor());
  final remaining = mainAxisSize - largeCount * largeSize;
  final mediumCount = remaining > 0 ? 1 : 0;
  // calculateMediumChildSize: the cut-off item shows a third of itself
  // cut off, or a fifth once that would near the large size (Compose).
  var mediumSize = math.max(remaining * 1.5, anchorSize);
  final threshold = largeSize * mediumLargeItemDiffThreshold;
  if (mediumSize > threshold) {
    mediumSize = math.min(math.max(threshold, remaining * 1.2), largeSize);
  }
  final arrangement = _Arrangement(
    0,
    0,
    0,
    mediumSize,
    mediumCount,
    largeSize,
    largeCount,
  );
  final xSmall = math.min(anchorSize, itemSize);
  final leftAnchor = math.max(xSmall, mediumSize * 0.5);
  return _leftAligned(
    mainAxisSize,
    itemSpacing,
    leftAnchor,
    anchorSize,
    arrangement,
  );
}

/// Compose's `heroKeylineList`: one large item (up to [maxItemSize]) with a
/// small item peeking — both sides when [centered] and there are three or
/// more items.
ExpressiveCarouselKeylines expressiveHeroKeylines({
  required double mainAxisSize,
  required double? maxItemSize,
  required double itemSpacing,
  required int itemCount,
  required bool centered,
  required double minSmallItemSize,
  required double maxSmallItemSize,
  required double anchorSize,
}) {
  if (mainAxisSize == 0) return ExpressiveCarouselKeylines.empty;
  final shouldCenter = centered && itemCount >= 3;
  var smallCounts = itemCount <= 1
      ? <int>[0]
      : shouldCenter
      ? <int>[2]
      : <int>[1];
  final targetLarge = math.min(maxItemSize ?? mainAxisSize, mainAxisSize);
  final targetSmall = (targetLarge / 3).clamp(
    minSmallItemSize,
    maxSmallItemSize,
  );
  // Below room for the small items and a quarter more, go full-screen.
  final fullscreenThreshold =
      minSmallItemSize * smallCounts.reduce(math.max) + minSmallItemSize * 1.25;
  if (mainAxisSize < fullscreenThreshold) smallCounts = <int>[0];
  final minLargeSpace =
      mainAxisSize - minSmallItemSize * smallCounts.reduce(math.max);
  final minLargeCount = math.max(1, (minLargeSpace / targetLarge).floor());
  final maxLargeCount = (mainAxisSize / targetLarge).ceil();
  final arrangement = _Arrangement.findLowestCost(
    availableSpace: mainAxisSize,
    itemSpacing: itemSpacing,
    targetSmallSize: targetSmall,
    minSmallSize: minSmallItemSize,
    maxSmallSize: maxSmallItemSize,
    smallCounts: smallCounts,
    targetMediumSize: 0,
    mediumCounts: const <int>[0],
    targetLargeSize: targetLarge,
    largeCounts: _descending(maxLargeCount, minLargeCount),
  );
  if (arrangement == null) return ExpressiveCarouselKeylines.empty;
  return shouldCenter && itemCount >= arrangement.itemCount
      ? _centerAligned(
          mainAxisSize,
          itemSpacing,
          anchorSize,
          anchorSize,
          arrangement,
        )
      : _leftAligned(
          mainAxisSize,
          itemSpacing,
          anchorSize,
          anchorSize,
          arrangement,
        );
}

/// The full-screen carousel's keylines: one item the carousel's whole
/// length, and the anchors ([expressiveHeroKeylines] with no small items).
ExpressiveCarouselKeylines expressiveFullScreenKeylines({
  required double mainAxisSize,
  required double itemSpacing,
  required double anchorSize,
}) {
  if (mainAxisSize == 0) return ExpressiveCarouselKeylines.empty;
  return _leftAligned(
    mainAxisSize,
    itemSpacing,
    anchorSize,
    anchorSize,
    _Arrangement(1, 0, 0, 0, 0, mainAxisSize, 1),
  );
}

// ---------------------------------------------------------------------------
// Strategy (Strategy.kt, KeylineSnapPosition.kt)
// ---------------------------------------------------------------------------

/// Compose's `Strategy`: the keylines at rest and the steps that shift
/// them at either end of the scroll, for a carousel [availableSpace] long.
class ExpressiveCarouselStrategy {
  ExpressiveCarouselStrategy._({
    required this.defaultKeylines,
    required this.startKeylineSteps,
    required this.endKeylineSteps,
    required this.availableSpace,
    required this.itemSpacing,
    required this.beforeContentPadding,
    required this.afterContentPadding,
  }) {
    var min = defaultKeylines.minSize;
    var max = defaultKeylines.maxSize;
    for (final step in <ExpressiveCarouselKeylines>[
      ...startKeylineSteps,
      ...endKeylineSteps,
    ]) {
      if (step.minSize < min) min = step.minSize;
      if (step.maxSize > max) max = step.maxSize;
    }
    minItemSize = min;
    maxItemSize = max;
    _startShiftDistance = startKeylineSteps.isEmpty
        ? 0
        : math.max(
            startKeylineSteps.last.first.unadjustedOffset -
                startKeylineSteps.first.first.unadjustedOffset,
            beforeContentPadding,
          );
    _endShiftDistance = endKeylineSteps.isEmpty
        ? 0
        : math.max(
            endKeylineSteps.first.last.unadjustedOffset -
                endKeylineSteps.last.last.unadjustedOffset,
            afterContentPadding,
          );
    _startShiftPoints = _stepPoints(
      _startShiftDistance,
      startKeylineSteps,
      shiftingLeft: true,
    );
    _endShiftPoints = _stepPoints(
      _endShiftDistance,
      endKeylineSteps,
      shiftingLeft: false,
    );
  }

  /// The strategy for [keylines] in a carousel [availableSpace] long, its
  /// items [itemSpacing] apart, with content padding before and after.
  factory ExpressiveCarouselStrategy(
    ExpressiveCarouselKeylines keylines, {
    required double availableSpace,
    double itemSpacing = 0,
    double beforeContentPadding = 0,
    double afterContentPadding = 0,
  }) => ExpressiveCarouselStrategy._(
    defaultKeylines: keylines,
    startKeylineSteps: _startSteps(
      keylines,
      availableSpace,
      itemSpacing,
      beforeContentPadding,
    ),
    endKeylineSteps: _endSteps(
      keylines,
      availableSpace,
      itemSpacing,
      afterContentPadding,
    ),
    availableSpace: availableSpace,
    itemSpacing: itemSpacing,
    beforeContentPadding: beforeContentPadding,
    afterContentPadding: afterContentPadding,
  );

  /// No strategy: nothing is laid out.
  static final ExpressiveCarouselStrategy empty = ExpressiveCarouselStrategy._(
    defaultKeylines: ExpressiveCarouselKeylines.empty,
    startKeylineSteps: const <ExpressiveCarouselKeylines>[],
    endKeylineSteps: const <ExpressiveCarouselKeylines>[],
    availableSpace: 0,
    itemSpacing: 0,
    beforeContentPadding: 0,
    afterContentPadding: 0,
  );

  /// The keylines at rest.
  final ExpressiveCarouselKeylines defaultKeylines;

  /// The keyline lists the start of the scroll steps through.
  final List<ExpressiveCarouselKeylines> startKeylineSteps;

  /// The keyline lists the end of the scroll steps through.
  final List<ExpressiveCarouselKeylines> endKeylineSteps;

  /// The length of the carousel along its main axis.
  final double availableSpace;

  /// The gap between items.
  final double itemSpacing;

  /// The padding before the first item.
  final double beforeContentPadding;

  /// The padding after the last item.
  final double afterContentPadding;

  /// The smallest and largest an item's mask gets.
  late final double minItemSize;

  /// The largest an item's mask gets.
  late final double maxItemSize;

  late final double _startShiftDistance;
  late final double _endShiftDistance;
  late final List<double> _startShiftPoints;
  late final List<double> _endShiftPoints;

  /// Whether there is anything to lay out.
  bool get isValid =>
      defaultKeylines.isNotEmpty &&
      availableSpace != 0 &&
      itemMainAxisSize != 0;

  /// Every item's size along the main axis: the focal size.
  double get itemMainAxisSize =>
      defaultKeylines.isEmpty ? 0 : defaultKeylines.firstFocal.size;

  List<ExpressiveCarouselKeylines>? _lastStartAndEndSteps;

  /// The keylines at [scrollOffset] of [maxScrollOffset]
  /// (`getKeylineListForScrollOffset`).
  ExpressiveCarouselKeylines keylinesFor(
    double scrollOffset,
    double maxScrollOffset, {
    bool roundToNearestStep = false,
  }) {
    final positive = math.max(0.0, scrollOffset);
    final startShift = _startShiftDistance;
    final endShift = math.max(0.0, maxScrollOffset - _endShiftDistance);
    if (positive >= startShift && positive <= endShift) return defaultKeylines;

    var interpolation = _lerpRange(1, 0, 0, startShift, positive);
    var shiftPoints = _startShiftPoints;
    var steps = startKeylineSteps;
    if (positive > endShift) {
      interpolation = _lerpRange(0, 1, endShift, maxScrollOffset, positive);
      shiftPoints = _endShiftPoints;
      steps = endKeylineSteps;
      if (endShift < 0.01 &&
          startKeylineSteps.length == 2 &&
          endKeylineSteps.length == 2) {
        steps = _lastStartAndEndSteps ??= <ExpressiveCarouselKeylines>[
          startKeylineSteps.last,
          endKeylineSteps.last,
        ];
      }
    }
    var from = 0;
    var to = 0;
    var stepped = 0.0;
    var lower = shiftPoints[0];
    for (var i = 1; i < steps.length; i++) {
      final upper = shiftPoints[i];
      if (interpolation <= upper) {
        from = i - 1;
        to = i;
        stepped = _lerpRange(0, 1, lower, upper, interpolation);
        break;
      }
      lower = upper;
    }
    if (roundToNearestStep) return steps[stepped.round() == 0 ? from : to];
    return ExpressiveCarouselKeylines.lerp(steps[from], steps[to], stepped);
  }

  /// Where item [index] of [itemCount] sits when snapped, as an offset from
  /// the carousel's start (`getSnapPositionOffset`, rounded like Compose's
  /// integer pixels).
  int snapPositionOffset(int index, int itemCount) {
    if (!isValid) return 0;
    var offset =
        (defaultKeylines.firstFocal.unadjustedOffset - itemMainAxisSize / 2)
            .round();
    if (index <= startKeylineSteps.length - 1) {
      final step = (startKeylineSteps.length - 1 - index).clamp(
        0,
        startKeylineSteps.length - 1,
      );
      offset =
          (startKeylineSteps[step].firstFocal.unadjustedOffset -
                  itemMainAxisSize / 2)
              .round();
    }
    final lastItem = itemCount - 1;
    if (index >= lastItem - (endKeylineSteps.length - 1) &&
        itemCount > defaultKeylines.focalCount) {
      final step = (endKeylineSteps.length - 1 - (lastItem - index)).clamp(
        0,
        endKeylineSteps.length - 1,
      );
      offset =
          (endKeylineSteps[step].lastFocal.unadjustedOffset -
                  itemMainAxisSize / 2)
              .round();
    }
    return offset;
  }

  /// The furthest [itemCount] items scroll (`calculateMaxScrollOffset`).
  double maxScrollOffset(int itemCount) => math.max(
    0,
    itemMainAxisSize * itemCount +
        itemSpacing * (itemCount - 1) -
        availableSpace,
  );

  static List<double> _stepPoints(
    double total,
    List<ExpressiveCarouselKeylines> steps, {
    required bool shiftingLeft,
  }) {
    final points = <double>[0];
    if (total == 0 || steps.isEmpty) return points;
    for (var i = 1; i < steps.length; i++) {
      final previous = steps[i - 1];
      final current = steps[i];
      final shifted = shiftingLeft
          ? current.first.unadjustedOffset - previous.first.unadjustedOffset
          : previous.last.unadjustedOffset - current.last.unadjustedOffset;
      points.add(i == steps.length - 1 ? 1 : points[i - 1] + shifted / total);
    }
    return points;
  }

  static List<ExpressiveCarouselKeylines> _startSteps(
    ExpressiveCarouselKeylines keylines,
    double size,
    double spacing,
    double padding,
  ) {
    if (keylines.isEmpty) return const <ExpressiveCarouselKeylines>[];
    final steps = <ExpressiveCarouselKeylines>[keylines];
    if (keylines._isFirstFocalItemAtStartOfContainer()) {
      if (padding != 0) {
        steps.add(
          _shiftedForPadding(
            keylines,
            size,
            spacing,
            padding,
            keylines.firstFocal,
            keylines.firstFocalIndex,
          ),
        );
      }
      return steps;
    }
    final start = keylines.firstNonAnchorIndex;
    final end = keylines.firstFocalIndex;
    final count = end - start;
    if (count <= 0 && keylines.firstFocal.cutoff > 0) {
      steps.add(_moveKeyline(keylines, 0, 0, size, spacing));
      return steps;
    }
    for (var i = 0; i < count; i++) {
      final previous = steps.last;
      final original = start + i;
      var dst = keylines.lastIndex;
      if (original > 0) {
        final neighbour = keylines[original - 1].size;
        dst = previous._firstIndexAfterFocalRangeWithSize(neighbour) - 1;
      }
      steps.add(
        _moveKeyline(
          previous,
          keylines.firstNonAnchorIndex,
          dst,
          size,
          spacing,
        ),
      );
    }
    if (padding != 0) {
      steps[steps.length - 1] = _shiftedForPadding(
        steps.last,
        size,
        spacing,
        padding,
        steps.last.firstFocal,
        steps.last.firstFocalIndex,
      );
    }
    return steps;
  }

  static List<ExpressiveCarouselKeylines> _endSteps(
    ExpressiveCarouselKeylines keylines,
    double size,
    double spacing,
    double padding,
  ) {
    if (keylines.isEmpty) return const <ExpressiveCarouselKeylines>[];
    final steps = <ExpressiveCarouselKeylines>[keylines];
    if (keylines._isLastFocalItemAtEndOfContainer(size)) {
      if (padding != 0) {
        steps.add(
          _shiftedForPadding(
            keylines,
            size,
            spacing,
            -padding,
            keylines.lastFocal,
            keylines.lastFocalIndex,
          ),
        );
      }
      return steps;
    }
    final start = keylines.lastFocalIndex;
    final end = keylines.lastNonAnchorIndex;
    final count = end - start;
    if (count <= 0 && keylines.lastFocal.cutoff > 0) {
      steps.add(_moveKeyline(keylines, 0, 0, size, spacing));
      return steps;
    }
    for (var i = 0; i < count; i++) {
      final previous = steps.last;
      final original = end - i;
      var dst = 0;
      if (original < keylines.lastIndex) {
        final neighbour = keylines[original + 1].size;
        dst = previous._lastIndexBeforeFocalRangeWithSize(neighbour) + 1;
      }
      steps.add(
        _moveKeyline(previous, keylines.lastNonAnchorIndex, dst, size, spacing),
      );
    }
    if (padding != 0) {
      steps[steps.length - 1] = _shiftedForPadding(
        steps.last,
        size,
        spacing,
        -padding,
        steps.last.lastFocal,
        steps.last.lastFocalIndex,
      );
    }
    return steps;
  }

  static ExpressiveCarouselKeylines _shiftedForPadding(
    ExpressiveCarouselKeylines from,
    double size,
    double spacing,
    double padding,
    ExpressiveCarouselKeyline pivot,
    int pivotIndex,
  ) {
    final nonAnchors = from.keylines.where((k) => !k.isAnchor).length;
    final reduction = padding / nonAnchors;
    final shifted = ExpressiveCarouselKeylines._pivoted(
      size,
      spacing,
      pivotIndex,
      pivot.offset - reduction / 2 + padding,
      (add) {
        for (final k in from.keylines) {
          add.add(k.size - reduction.abs(), isAnchor: k.isAnchor);
        }
      },
    );
    return ExpressiveCarouselKeylines(<ExpressiveCarouselKeyline>[
      for (var i = 0; i < shifted.length; i++)
        shifted[i]._withUnadjustedOffset(from[i].unadjustedOffset),
    ]);
  }

  static ExpressiveCarouselKeylines _moveKeyline(
    ExpressiveCarouselKeylines from,
    int src,
    int dst,
    double size,
    double spacing,
  ) {
    final direction = src > dst ? 1 : -1;
    final delta = (from[src].size - from[src].cutoff + spacing) * direction;
    final moved = List<ExpressiveCarouselKeyline>.of(from.keylines);
    moved.insert(dst, moved.removeAt(src));
    return ExpressiveCarouselKeylines._pivoted(
      size,
      spacing,
      from.pivotIndex + direction,
      from.pivot.offset + delta,
      (add) {
        for (final k in moved) {
          add.add(k.size, isAnchor: k.isAnchor);
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Item placement (Carousel.kt: Modifier.carouselItem)
// ---------------------------------------------------------------------------

/// Where one item goes at one scroll offset, in the layout's unit: its
/// start along the main axis, its mask (from the item's own start), and its
/// paint order.
@immutable
class ExpressiveCarouselItemPlacement {
  /// A placement with the item's [start], mask ([maskStart] to [maskEnd]), [size] and [zIndex].
  const ExpressiveCarouselItemPlacement({
    required this.start,
    required this.maskStart,
    required this.maskEnd,
    required this.size,
    required this.zIndex,
  });

  /// The item's start along the main axis, from the carousel's start.
  final double start;

  /// The mask's start along the main axis, from the item's start.
  final double maskStart;

  /// The mask's end along the main axis, from the item's start.
  final double maskEnd;

  /// The mask's length (the interpolated keyline's size).
  final double size;

  /// The paint order: the current item on top, its neighbours below
  /// (`1 / (1 + distance)`).
  final double zIndex;
}

/// Compose's carousel layout at one scroll offset, in device pixels: the
/// pager's pages (whole-pixel page size and spacing, placed from the snap
/// position) and each item's keyline mask and translation.
class ExpressiveCarouselLayout {
  /// A layout of [itemCount] items on [strategy], [pageSpacing] apart.
  ExpressiveCarouselLayout({
    required this.strategy,
    required this.itemCount,
    required this.pageSpacing,
  }) : pageSize = strategy.itemMainAxisSize.roundToDouble(),
       maxScrollOffset = strategy.maxScrollOffset(itemCount),
       _snapOffsets = <double>[
         for (var i = 0; i < itemCount; i++)
           strategy.snapPositionOffset(i, itemCount).toDouble(),
       ];

  /// The strategy the layout follows.
  final ExpressiveCarouselStrategy strategy;

  /// How many items there are.
  final int itemCount;

  /// The pager's page spacing (whole pixels).
  final double pageSpacing;

  /// The pager's page size: the focal size rounded to a whole pixel.
  final double pageSize;

  /// The furthest the carousel scrolls.
  final double maxScrollOffset;

  final List<double> _snapOffsets;

  double get _itemSizeWithSpacing =>
      strategy.itemMainAxisSize + strategy.itemSpacing;

  /// The scroll offset at which item [index] is snapped
  /// (`calculateCurrentScrollOffset` at that page, offset fraction 0).
  double snapScrollOffset(int index) =>
      (index * _itemSizeWithSpacing - _snapOffsets[index]).clamp(
        0,
        maxScrollOffset,
      );

  /// The pager's page position at [scrollOffset]: its current page and the
  /// fraction it is scrolled past it (`currentPage` +
  /// `currentPageOffsetFraction`).
  double pagePosition(double scrollOffset) {
    if (itemCount == 0 || _itemSizeWithSpacing <= 0) return 0;
    var best = 0.0;
    var bestDistance = double.infinity;
    for (var page = 0; page < itemCount; page++) {
      final position =
          (scrollOffset + _snapOffsets[page]) / _itemSizeWithSpacing;
      final distance = (position - page).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = position;
      }
    }
    return best;
  }

  /// The item nearest its snap position at [scrollOffset] (the pager's
  /// `currentPage`).
  int currentItem(double scrollOffset) => itemCount == 0
      ? 0
      : pagePosition(scrollOffset).round().clamp(0, itemCount - 1).toInt();

  /// Item [index]'s placement at [scrollOffset].
  ExpressiveCarouselItemPlacement place(int index, double scrollOffset) {
    final position = pagePosition(scrollOffset);
    final current = position
        .round()
        .clamp(0, math.max(0, itemCount - 1))
        .toInt();
    // The pager places whole-pixel pages from the current page's snap
    // position.
    final pageStart = _snapOffsets.isEmpty
        ? 0.0
        : _snapOffsets[current] + (index - position) * (pageSize + pageSpacing);
    final keylines = strategy.keylinesFor(scrollOffset, maxScrollOffset);
    final size = strategy.itemMainAxisSize;
    final center = index * _itemSizeWithSpacing + size / 2 - scrollOffset;
    final before = keylines.keylineBefore(center);
    final after = keylines.keylineAfter(center);
    final progress = before == after
        ? 1.0
        : (center - before.unadjustedOffset) /
              (after.unadjustedOffset - before.unadjustedOffset);
    final keyline = ExpressiveCarouselKeyline.lerp(before, after, progress);
    var translation = keyline.offset - center;
    if (before == after) {
      translation += (center - keyline.unadjustedOffset) / keyline.size;
    }
    return ExpressiveCarouselItemPlacement(
      start: pageStart + translation,
      maskStart: size / 2 - keyline.size / 2,
      maskEnd: size / 2 + keyline.size / 2,
      size: keyline.size,
      zIndex: 1 / (1 + (index - current).abs()),
    );
  }
}

// ---------------------------------------------------------------------------
// Controller, snapping, widget
// ---------------------------------------------------------------------------

/// Snap targets and the pending programmatic target, shared by a carousel,
/// its physics and its controller.
class _CarouselSnap {
  ExpressiveCarouselLayout? layout;
  double devicePixelRatio = 1;
  bool snaps = true;
  SpringDescription spring = const SpringDescription(
    mass: 1,
    stiffness: 1,
    damping: 1,
  );
  int? pendingItem;

  /// The item a user drag started on: a fling settles at most one item
  /// from it (`PagerSnapDistance.atMost(1)`).
  int? dragStartItem;

  /// The snap points, in logical pixels, ascending and distinct.
  List<double> get points {
    final l = layout;
    if (l == null) return const <double>[];
    final points = <double>[];
    for (var i = 0; i < l.itemCount; i++) {
      final point = l.snapScrollOffset(i) / devicePixelRatio;
      if (points.isEmpty || point > points.last) points.add(point);
    }
    return points;
  }

  double offsetOf(int item) {
    final l = layout;
    if (l == null || l.itemCount == 0) return 0;
    return l.snapScrollOffset(item.clamp(0, l.itemCount - 1)) /
        devicePixelRatio;
  }

  int itemAt(double pixels) =>
      layout?.currentItem(pixels * devicePixelRatio) ?? 0;

  /// Where a fling at [velocity] from [pixels] settles: the nearest snap
  /// point, or the next one in the fling's direction — at most one item
  /// (`CarouselDefaults.singleAdvanceFlingBehavior`).
  double target(double pixels, double velocity, double minFlingVelocity) {
    final all = points;
    if (all.isEmpty) return pixels;
    var lower = all.first;
    var upper = all.last;
    for (final point in all) {
      if (point <= pixels) lower = point;
      if (point >= pixels) {
        upper = point;
        break;
      }
    }
    if (velocity > minFlingVelocity) {
      if (upper == pixels) {
        final next = all.indexOf(upper) + 1;
        return next < all.length ? all[next] : upper;
      }
      return upper;
    }
    if (velocity < -minFlingVelocity) {
      if (lower == pixels) {
        final previous = all.indexOf(lower) - 1;
        return previous >= 0 ? all[previous] : lower;
      }
      return lower;
    }
    return pixels - lower <= upper - pixels ? lower : upper;
  }

  /// [target], at most one item from where the drag started.
  double limited(double target) {
    final start = dragStartItem;
    if (start == null) return target;
    return target.clamp(offsetOf(start - 1), offsetOf(start + 1));
  }
}

/// A carousel's scroll physics: snapping to the keyline positions over the
/// platform's physics (which owns overscroll).
class _CarouselPhysics extends ScrollPhysics {
  const _CarouselPhysics(this.snap, {super.parent});

  final _CarouselSnap snap;

  @override
  _CarouselPhysics applyTo(ScrollPhysics? ancestor) =>
      _CarouselPhysics(snap, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    final pending = snap.pendingItem;
    if (pending != null) {
      snap.pendingItem = null;
      final target = snap
          .offsetOf(pending)
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((target - position.pixels).abs() < tolerance.distance) return null;
      return ScrollSpringSimulation(
        snap.spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    if (!snap.snaps ||
        (velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent) ||
        position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = snap.limited(
      snap.target(position.pixels, velocity, tolerance.velocity),
    );
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      snap.spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// Drives a carousel and reports its current item (Compose's
/// `CarouselState`): a [ScrollController] whose offset is the carousel's
/// scroll, starting at [initialItem]. Listeners hear every scroll; read
/// [currentItem] in them.
class ExpressiveCarouselController extends ScrollController {
  /// A controller that starts at [initialItem].
  ExpressiveCarouselController({this.initialItem = 0});

  /// The item the carousel starts on.
  final int initialItem;

  _CarouselSnap? _snap;

  @override
  double get initialScrollOffset => _snap?.offsetOf(initialItem) ?? 0;

  /// The item nearest its snapped position (Compose's `currentItem`).
  int get currentItem {
    final snap = _snap;
    if (snap == null || !hasClients) return initialItem;
    return snap.itemAt(position.pixels);
  }

  /// Moves to [item] at once.
  void jumpToItem(int item) {
    final snap = _snap;
    if (snap == null || !hasClients) return;
    jumpTo(snap.offsetOf(item));
  }

  /// Springs to [item] on the carousel's snap spring (Compose's
  /// `animateScrollToItem`).
  void animateToItem(int item) {
    final snap = _snap;
    if (snap == null || !hasClients) return;
    final scroll = position;
    if (scroll is ScrollPositionWithSingleContext) {
      snap.pendingItem = item;
      scroll.goBallistic(0);
    } else {
      jumpTo(snap.offsetOf(item));
    }
  }
}

/// What an item's content may read about its mask (Compose's
/// `CarouselItemDrawInfo`): `ExpressiveCarouselItemInfo.of(context)`.
@immutable
class ExpressiveCarouselItemInfo {
  /// Info for the item at [index], whose mask is [maskRect].
  const ExpressiveCarouselItemInfo({
    required this.index,
    required this.size,
    required this.minSize,
    required this.maxSize,
    required this.maskRect,
    this._contentRect,
  });

  /// The item's index.
  final int index;

  /// The mask's length along the main axis now.
  final double size;

  /// The smallest the mask gets in this carousel.
  final double minSize;

  /// The largest the mask gets in this carousel (the focal size).
  final double maxSize;

  /// The visible part of the item, in its own coordinates.
  final Rect maskRect;

  final Rect? _contentRect;

  /// The visible area reserved for labels, after shape and style padding.
  /// Pictures may fill [maskRect]; captions belong inside this rectangle.
  Rect get contentRect => _contentRect ?? maskRect;

  /// How open the mask is: 0 at its smallest, 1 at the focal size. Fade a
  /// label in by it.
  double get openness => maxSize <= minSize
      ? 1
      : ((size - minSize) / (maxSize - minSize)).clamp(0, 1);

  /// The info of the carousel item around [context].
  static ExpressiveCarouselItemInfo of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_CarouselItemScope>();
    assert(scope != null, 'ExpressiveCarouselItemInfo.of outside a carousel');
    return scope!.info;
  }

  /// The info of the carousel item around [context], if any.
  static ExpressiveCarouselItemInfo? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CarouselItemScope>()?.info;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveCarouselItemInfo &&
      other.index == index &&
      other.size == size &&
      other.minSize == minSize &&
      other.maxSize == maxSize &&
      other.maskRect == maskRect &&
      other.contentRect == contentRect;

  @override
  int get hashCode =>
      Object.hash(index, size, minSize, maxSize, maskRect, contentRect);
}

class _CarouselItemScope extends InheritedWidget {
  const _CarouselItemScope({required this.info, required super.child});

  final ExpressiveCarouselItemInfo info;

  @override
  bool updateShouldNotify(_CarouselItemScope oldWidget) =>
      info != oldWidget.info;
}

/// The carousel's layouts.
enum ExpressiveCarouselVariant {
  /// Large, medium and small items side by side (Compose's
  /// `HorizontalMultiBrowseCarousel`): browsing many items at once.
  multiBrowse,

  /// Items of one size from the start, the last cut off at the edge
  /// (`HorizontalUncontainedCarousel`): free scrolling, no snapping.
  uncontained,

  /// One large item centred between two small ones
  /// (`HorizontalCenteredHeroCarousel`): spotlighting one item at a time.
  hero,

  /// One item filling the carousel, paged vertically: immersive browsing,
  /// one item per swipe (Material's full-screen carousel).
  fullScreen,
}

/// A carousel: a scrolling row of items whose masks grow and shrink by the
/// keyline strategy of its [variant] (see the library doc), each item's
/// content drawn at full size under its mask — pictures from media slots
/// ([ExpressiveMedia]) are what it is for — masked by [itemCorner] (Material
/// rounds carousel items at `corner.extraLarge`).
///
/// It is [height] tall ([ExpressiveCarouselView.fullScreen] fills its box and
/// pages vertically); items are [itemSpacing] apart and [padding] insets
/// the first and last item. Drive it, and hear its current item, with a
/// [controller]; pair it with an [ExpressivePageDots] for a hero or
/// full-screen carousel. Content that wants its mask reads
/// [ExpressiveCarouselItemInfo.of].
///
/// ```dart
/// ExpressiveCarouselView.multiBrowse(itemCount: trips.length, height: 220, itemBuilder: (context, i) => ExpressiveMedia(slotId: trips[i].slot))
/// ```
class ExpressiveCarouselView extends StatefulWidget {
  /// Compose's `HorizontalMultiBrowseCarousel`: large items of about
  /// [preferredItemWidth] (half the carousel when null) as fit, then a
  /// medium and a small one.
  const ExpressiveCarouselView.multiBrowse({
    required this.itemCount,
    required this.itemBuilder,
    double? preferredItemWidth,
    this.height,
    this.itemSpacing = 0,
    this.padding = EdgeInsets.zero,
    this.itemCorner = ExpressiveCorner.extraLarge,
    this.controller,
    this.onItemTap,
    this.style,
    this.semanticLabel,
    this.minSmallItemWidth = CarouselBehavior.minSmallItemSize,
    this.maxSmallItemWidth = CarouselBehavior.maxSmallItemSize,
    super.key,
  }) : variant = ExpressiveCarouselVariant.multiBrowse,
       itemExtent = preferredItemWidth;

  /// Compose's `HorizontalUncontainedCarousel`: items [itemWidth] wide
  /// (half the carousel when null), scrolling freely.
  const ExpressiveCarouselView.uncontained({
    required this.itemCount,
    required this.itemBuilder,
    double? itemWidth,
    this.height,
    this.itemSpacing = 0,
    this.padding = EdgeInsets.zero,
    this.itemCorner = ExpressiveCorner.extraLarge,
    this.controller,
    this.onItemTap,
    this.style,
    this.semanticLabel,
    super.key,
  }) : variant = ExpressiveCarouselVariant.uncontained,
       itemExtent = itemWidth,
       minSmallItemWidth = CarouselBehavior.minSmallItemSize,
       maxSmallItemWidth = CarouselBehavior.maxSmallItemSize;

  /// Compose's `HorizontalCenteredHeroCarousel`: one large item (at most
  /// [maxItemWidth]; the whole carousel less the small items when null)
  /// between two small ones.
  const ExpressiveCarouselView.hero({
    required this.itemCount,
    required this.itemBuilder,
    double? maxItemWidth,
    this.height,
    this.itemSpacing = 0,
    this.padding = EdgeInsets.zero,
    this.itemCorner = ExpressiveCorner.extraLarge,
    this.controller,
    this.onItemTap,
    this.style,
    this.semanticLabel,
    this.minSmallItemWidth = CarouselBehavior.minSmallItemSize,
    this.maxSmallItemWidth = CarouselBehavior.maxSmallItemSize,
    super.key,
  }) : variant = ExpressiveCarouselVariant.hero,
       itemExtent = maxItemWidth;

  /// Material's full-screen carousel: one item filling the box, paged
  /// vertically one item per swipe (Compose's carousel on its vertical
  /// path, with the hero strategy's single large item).
  const ExpressiveCarouselView.fullScreen({
    required this.itemCount,
    required this.itemBuilder,
    this.itemSpacing = 0,
    this.itemCorner = ExpressiveCorner.none,
    this.controller,
    this.onItemTap,
    this.style,
    this.semanticLabel,
    super.key,
  }) : variant = ExpressiveCarouselVariant.fullScreen,
       itemExtent = null,
       height = null,
       padding = EdgeInsets.zero,
       minSmallItemWidth = CarouselBehavior.minSmallItemSize,
       maxSmallItemWidth = CarouselBehavior.maxSmallItemSize;

  /// Stateful item frames and content. Padding insets each item's content;
  /// [ExpressiveCarouselItemInfo.contentRect] reserves its visible caption area.
  final ExpressiveComponentThemeData? style;

  /// The layout.
  final ExpressiveCarouselVariant variant;

  /// How many items there are.
  final int itemCount;

  /// Builds item [index]'s content, laid out at the focal size and masked.
  final IndexedWidgetBuilder itemBuilder;

  /// The variant's item length: multi-browse's preferred width,
  /// uncontained's width, hero's maximum width.
  final double? itemExtent;

  /// The carousel's height; the incoming height when null (the focal
  /// width, square items, when that is unbounded).
  final double? height;

  /// The gap between items.
  final double itemSpacing;

  /// Insets before the first and after the last item (main axis), and
  /// above and below the items (cross axis).
  final EdgeInsetsGeometry padding;

  /// The corner every item's mask is rounded by.
  final ExpressiveCorner itemCorner;

  /// Drives the carousel and reports its current item.
  final ExpressiveCarouselController? controller;

  /// What a tap on item [index] does; items take no taps when null (their
  /// content may).
  final ValueChanged<int>? onItemTap;

  /// What a screen reader calls the carousel.
  final String? semanticLabel;

  /// The smallest a small item may be (Compose's `MinSmallItemSize`).
  final double minSmallItemWidth;

  /// The largest a small item may be (Compose's `MaxSmallItemSize`).
  final double maxSmallItemWidth;

  /// Whether the carousel scrolls vertically.
  bool get vertical => variant == ExpressiveCarouselVariant.fullScreen;

  @override
  State<ExpressiveCarouselView> createState() => _ExpressiveCarouselState();
}

class _ExpressiveCarouselState extends State<ExpressiveCarouselView> {
  final _CarouselSnap _snap = _CarouselSnap();
  ExpressiveCarouselController? _ownController;
  _LayoutKey? _layoutKey;

  ExpressiveCarouselController get _controller =>
      widget.controller ?? (_ownController ??= ExpressiveCarouselController());

  @override
  void initState() {
    super.initState();
    _controller._snap = _snap;
  }

  @override
  void didUpdateWidget(ExpressiveCarouselView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (widget.controller != null) {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller._snap = _snap;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  ExpressiveCarouselLayout _layoutFor(_LayoutKey key) {
    if (_layoutKey == key && _snap.layout != null) return _snap.layout!;
    final px = key.dpr;
    final main = key.mainExtent;
    final spacing = key.spacing;
    final anchor = CarouselBehavior.anchorSize * px;
    final minSmall = widget.minSmallItemWidth * px;
    final maxSmall = widget.maxSmallItemWidth * px;
    final desired = widget.itemExtent;
    final minMain = widget.vertical ? key.minimum?.height : key.minimum?.width;
    final extent = minMain == null
        ? desired
        : math.max(desired ?? key.logicalMain * 0.5, minMain);
    final keylines = switch (widget.variant) {
      ExpressiveCarouselVariant.multiBrowse => expressiveMultiBrowseKeylines(
        mainAxisSize: main,
        preferredItemSize: (extent ?? key.logicalMain * 0.5) * px,
        itemSpacing: spacing,
        itemCount: widget.itemCount,
        minSmallItemSize: minSmall,
        maxSmallItemSize: maxSmall,
        anchorSize: anchor,
      ),
      ExpressiveCarouselVariant.uncontained => expressiveUncontainedKeylines(
        mainAxisSize: main,
        itemSize: (extent ?? key.logicalMain * 0.5) * px,
        itemSpacing: spacing,
        anchorSize: anchor,
      ),
      ExpressiveCarouselVariant.hero => expressiveHeroKeylines(
        mainAxisSize: main,
        maxItemSize: extent == null ? null : extent * px,
        itemSpacing: spacing,
        itemCount: widget.itemCount,
        centered: true,
        minSmallItemSize: minSmall,
        maxSmallItemSize: maxSmall,
        anchorSize: anchor,
      ),
      ExpressiveCarouselVariant.fullScreen => expressiveFullScreenKeylines(
        mainAxisSize: main,
        itemSpacing: spacing,
        anchorSize: anchor,
      ),
    };
    final strategy = ExpressiveCarouselStrategy(
      keylines,
      availableSpace: main,
      itemSpacing: spacing,
      beforeContentPadding: key.before,
      afterContentPadding: key.after,
    );
    _layoutKey = key;
    return _snap.layout = ExpressiveCarouselLayout(
      strategy: strategy,
      itemCount: widget.itemCount,
      pageSpacing: spacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final visual = theme.carouselTheme.merge(widget.style);
    final minimum = visual.minimumSize?.resolve(const <WidgetState>{});
    final padding = theme.density.padding(widget.padding.resolve(direction));
    final vertical = widget.vertical;
    // A carousel snaps on the scheme's default spatial spring, pinned to
    // Standard: a scroll never bounces past its item.
    _snap
      ..devicePixelRatio = dpr
      ..snaps = widget.variant != ExpressiveCarouselVariant.uncontained
      ..spring = ExpressiveMotion(
        scheme: ExpressiveMotionScheme.standard,
        reduceMotion: context.expressiveMotion.reduceMotion,
      ).spring(ExpressiveMotionKey.defaultSpatial);

    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalMain = vertical
            ? constraints.maxHeight
            : constraints.maxWidth;
        assert(
          logicalMain.isFinite,
          'An ExpressiveCarouselView needs a bounded ${vertical ? 'height' : 'width'}.',
        );
        final key = _LayoutKey(
          dpr: dpr,
          logicalMain: logicalMain,
          mainExtent: (logicalMain * dpr).roundToDouble(),
          spacing:
              (theme.density.padding(EdgeInsets.all(widget.itemSpacing)).left *
                      dpr)
                  .roundToDouble(),
          minimum: minimum,
          before: (vertical ? padding.top : padding.left) * dpr,
          after: (vertical ? padding.bottom : padding.right) * dpr,
          count: widget.itemCount,
        );
        final layout = _layoutFor(key);
        final focal = layout.strategy.itemMainAxisSize / dpr;
        final double cross;
        if (vertical) {
          cross = constraints.maxWidth.isFinite ? constraints.maxWidth : focal;
        } else {
          cross = math.min(
            constraints.maxHeight,
            math.max(
              minimum?.height ?? 0,
              widget.height ??
                  (constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : focal),
            ),
          );
        }
        final Widget scrollable = Scrollable(
          controller: _controller,
          axisDirection: vertical
              ? AxisDirection.down
              : textDirectionToAxisDirection(direction),
          physics: _CarouselPhysics(_snap),
          semanticChildCount: widget.itemCount,
          viewportBuilder: (context, offset) => _CarouselViewport(
            offset: offset,
            mainExtent: logicalMain,
            maxScrollExtent: layout.maxScrollOffset / dpr,
            child: ListenableBuilder(
              listenable: offset,
              builder: (context, _) => _items(
                context,
                theme,
                layout,
                offset.pixels,
                dpr,
                logicalMain,
                cross,
                padding,
                direction,
              ),
            ),
          ),
        );
        final tracked = NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0) return false;
            if (notification is ScrollStartNotification) {
              _snap.dragStartItem = notification.dragDetails == null
                  ? null
                  : _snap.itemAt(notification.metrics.pixels);
            } else if (notification is ScrollEndNotification) {
              _snap.dragStartItem = null;
            }
            return false;
          },
          child: scrollable,
        );
        return Semantics(
          container: true,
          label: widget.semanticLabel,
          child: SizedBox(
            width: vertical ? cross : logicalMain,
            height: vertical ? logicalMain : cross,
            child: ClipRect(child: tracked),
          ),
        );
      },
    );
  }

  Widget _items(
    BuildContext context,
    ExpressiveThemeData theme,
    ExpressiveCarouselLayout layout,
    double pixels,
    double dpr,
    double logicalMain,
    double cross,
    EdgeInsets padding,
    TextDirection direction,
  ) {
    final strategy = layout.strategy;
    if (!strategy.isValid || widget.itemCount == 0) {
      return const SizedBox.expand();
    }
    final vertical = widget.vertical;
    final rtl = !vertical && direction == TextDirection.rtl;
    final scroll = pixels * dpr;
    final itemMain = layout.pageSize / dpr;
    final crossStart = vertical ? padding.left : padding.top;
    final crossExtent =
        cross - (vertical ? padding.horizontal : padding.vertical);
    final shape = theme.shapes.corner(widget.itemCorner);
    final placed = <(int, ExpressiveCarouselItemPlacement)>[];
    for (var i = 0; i < widget.itemCount; i++) {
      final p = layout.place(i, scroll);
      final start = (p.start + p.maskStart) / dpr;
      final end = (p.start + p.maskEnd) / dpr;
      // Only items whose mask reaches into the carousel are built.
      if (end <= 0 || start >= logicalMain || p.size <= 0) continue;
      placed.add((i, p));
    }
    placed.sort((a, b) {
      final byZ = a.$2.zIndex.compareTo(b.$2.zIndex);
      return byZ != 0 ? byZ : a.$1.compareTo(b.$1);
    });
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final (index, p) in placed)
          _positioned(
            index,
            p,
            strategy,
            dpr,
            logicalMain,
            itemMain,
            crossStart,
            crossExtent,
            shape,
            rtl,
          ),
      ],
    );
  }

  Widget _positioned(
    int index,
    ExpressiveCarouselItemPlacement p,
    ExpressiveCarouselStrategy strategy,
    double dpr,
    double logicalMain,
    double itemMain,
    double crossStart,
    double crossExtent,
    OutlinedBorder shape,
    bool rtl,
  ) {
    final vertical = widget.vertical;
    var start = p.start / dpr;
    var maskStart = p.maskStart / dpr;
    var maskEnd = p.maskEnd / dpr;
    if (rtl) {
      start = logicalMain - start - itemMain;
      final flippedStart = itemMain - maskEnd;
      maskEnd = itemMain - maskStart;
      maskStart = flippedStart;
    }
    final mask = vertical
        ? Rect.fromLTRB(0, maskStart, crossExtent, maskEnd)
        : Rect.fromLTRB(maskStart, 0, maskEnd, crossExtent);
    // What of the mask the frame shows: an item crossing the frame's edge
    // mid-swipe is drawn to that edge in its own shape (its corners there,
    // rounded no more than its visible part allows), never cut square.
    final shownStart = math.max(maskStart, -start);
    final shownEnd = math.min(maskEnd, logicalMain - start);
    final shown = shownEnd <= shownStart
        ? mask
        : vertical
        ? Rect.fromLTRB(0, shownStart, crossExtent, shownEnd)
        : Rect.fromLTRB(shownStart, 0, shownEnd, crossExtent);
    final theme = context.expressiveTheme;
    final visual = theme.carouselTheme.merge(widget.style);
    final nativeShape = shape;
    final selected = index == _controller.currentItem;
    final adapted = visual.copyWith(
      shape: WidgetStateProperty.resolveWith(
        (states) =>
            _MaskedBorder(shown, visual.shape?.resolve(states) ?? nativeShape),
      ),
    );
    Widget content(BuildContext context, Set<WidgetState> states) {
      final outline = visual.shape?.resolve(states);
      final side =
          visual.side?.resolve(states) ??
          BorderSide.none.copyWith(
            color: visual.outline?.resolve(states),
            style: visual.outline?.resolve(states) == null
                ? null
                : BorderStyle.solid,
          );
      final inset = (outline ?? nativeShape)
          .copyWith(side: side)
          .dimensions
          .resolve(Directionality.of(context));
      final padding =
          visual.padding
              ?.resolve(states)
              ?.resolve(Directionality.of(context)) ??
          EdgeInsets.zero;
      final space = inset + padding;
      final shifted = mask.shift(-Offset(space.left, space.top));
      final safe = Rect.fromLTRB(
        shifted.left + space.left,
        shifted.top + space.top,
        math.max(shifted.left + space.left, shifted.right - space.right),
        math.max(shifted.top + space.top, shifted.bottom - space.bottom),
      );
      return _CarouselItemScope(
        info: ExpressiveCarouselItemInfo(
          index: index,
          size: p.size / dpr,
          minSize: strategy.minItemSize / dpr,
          maxSize: strategy.maxItemSize / dpr,
          maskRect: shifted,
          contentRect: safe,
        ),
        child: Builder(
          builder: (context) => widget.itemBuilder(context, index),
        ),
      );
    }

    final tap = widget.onItemTap;
    final Widget item;
    if (tap != null) {
      item = ExpressivePressable(
        shapes: ExpressivePressShapes.all(_MaskedBorder(shown, nativeShape)),
        style: adapted,
        selected: selected,
        motion: ExpressiveMotionKey.fastSpatial,
        color: expressiveTransparent,
        contentColor: theme.colors.onSurface,
        minimumInteractiveSize: false,
        onPressed: () => tap(index),
        child: Builder(
          builder: (context) => ExpressiveStyledContent(
            center: false,
            child: content(
              context,
              ExpressiveStyleScope.maybeOf(context)!.states,
            ),
          ),
        ),
      );
    } else {
      final states = <WidgetState>{if (selected) WidgetState.selected};
      item = ExpressiveSurface(
        shape: _MaskedBorder(shown, nativeShape),
        style: adapted,
        states: states,
        padding: EdgeInsets.zero,
        color: expressiveTransparent,
        contentColor: theme.colors.onSurface,
        child: content(context, states),
      );
    }
    return Positioned(
      key: ValueKey<int>(index),
      left: vertical ? crossStart : start,
      top: vertical ? start : crossStart,
      width: vertical ? crossExtent : itemMain,
      height: vertical ? itemMain : crossExtent,
      child: item,
    );
  }
}

@immutable
class _LayoutKey {
  const _LayoutKey({
    required this.dpr,
    required this.logicalMain,
    required this.mainExtent,
    required this.spacing,
    required this.before,
    required this.after,
    required this.count,
    required this.minimum,
  });

  final double dpr;
  final double logicalMain;
  final double mainExtent;
  final double spacing;
  final double before;
  final double after;
  final int count;
  final Size? minimum;

  @override
  bool operator ==(Object other) =>
      other is _LayoutKey &&
      other.dpr == dpr &&
      other.logicalMain == logicalMain &&
      other.mainExtent == mainExtent &&
      other.spacing == spacing &&
      other.before == before &&
      other.after == after &&
      other.count == count &&
      other.minimum == minimum;

  @override
  int get hashCode => Object.hash(
    dpr,
    logicalMain,
    mainExtent,
    spacing,
    before,
    after,
    count,
    minimum,
  );
}

/// Paints and clips the outline at the visible mask, not the focal item box.
class _MaskedBorder extends OutlinedBorder {
  const _MaskedBorder(this.mask, this.outline, {super.side});

  final Rect mask;
  final OutlinedBorder outline;

  Rect _rect(Rect rect) => mask.shift(rect.topLeft).intersect(rect);

  @override
  EdgeInsetsGeometry get dimensions => outline.copyWith(side: side).dimensions;

  @override
  _MaskedBorder copyWith({BorderSide? side}) =>
      _MaskedBorder(mask, outline, side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => _MaskedBorder(
    mask,
    outline.scale(t) as OutlinedBorder,
    side: side.scale(t),
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      outline.getOuterPath(_rect(rect), textDirection: textDirection);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => outline
      .copyWith(side: side)
      .getInnerPath(_rect(rect), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      outline
          .copyWith(side: side)
          .paint(canvas, _rect(rect), textDirection: textDirection);

  // Keyline masks follow the scroll position immediately; only the outline
  // morphs, otherwise the clip would trail a dragging item's placement.
  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is _MaskedBorder
      ? _MaskedBorder(
          mask,
          ShapeBorder.lerp(a.outline, outline, t)! as OutlinedBorder,
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is _MaskedBorder
      ? _MaskedBorder(
          b.mask,
          ShapeBorder.lerp(outline, b.outline, t)! as OutlinedBorder,
          side: BorderSide.lerp(side, b.side, t),
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is _MaskedBorder &&
      other.mask == mask &&
      other.outline == outline &&
      other.side == side;

  @override
  int get hashCode => Object.hash(mask, outline, side);
}

/// The carousel's viewport: tells the scroll position the carousel's length
/// and how far it scrolls.
class _CarouselViewport extends SingleChildRenderObjectWidget {
  const _CarouselViewport({
    required this.offset,
    required this.mainExtent,
    required this.maxScrollExtent,
    required super.child,
  });

  final ViewportOffset offset;
  final double mainExtent;
  final double maxScrollExtent;

  @override
  _RenderCarouselViewport createRenderObject(BuildContext context) =>
      _RenderCarouselViewport(offset, mainExtent, maxScrollExtent);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCarouselViewport renderObject,
  ) {
    renderObject
      ..offset = offset
      ..mainExtent = mainExtent
      ..maxScrollExtent = maxScrollExtent;
  }
}

class _RenderCarouselViewport extends RenderProxyBox {
  _RenderCarouselViewport(
    this._offset,
    this._mainExtent,
    this._maxScrollExtent,
  );

  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    if (value == _offset) return;
    _offset = value;
    markNeedsLayout();
  }

  double _mainExtent;
  set mainExtent(double value) {
    if (value == _mainExtent) return;
    _mainExtent = value;
    markNeedsLayout();
  }

  double _maxScrollExtent;
  set maxScrollExtent(double value) {
    if (value == _maxScrollExtent) return;
    _maxScrollExtent = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    _offset.applyViewportDimension(_mainExtent);
    _offset.applyContentDimensions(0, _maxScrollExtent);
  }
}

// ---------------------------------------------------------------------------
// Page indicator
// ---------------------------------------------------------------------------

/// A page indicator: a dot per page, the current one stretched into a pill
/// (M3 has no page indicator; this one is drawn from the foundations: the
/// spacing scale's 8dp dot, its 24dp pill, `corner.full`, `primary` for the
/// current page and `outline` for the rest — a control's 3:1 against the
/// page, where `outlineVariant` is decoration and reads too faint —
/// springing between pages on the fast spatial and effects springs).
///
/// A tap on a dot, or an increase or decrease from a screen reader, calls
/// [onChanged] with that page; the indicator is display-only when it is
/// null. Pressable, it stands as tall as Compose's minimum interactive size
/// (48dp, its dots centred as before), so a finger finds a dot; display-only,
/// it is [touchHeight]. Announced as "Page n of count" (or [semanticLabel]).
///
/// ```dart
/// ExpressivePageDots(count: 5, selectedIndex: controller.currentItem, onChanged: controller.animateToItem)
/// ```
class ExpressivePageDots extends StatelessWidget {
  /// A page indicator of [count] dots with [selectedIndex] current.
  const ExpressivePageDots({
    required this.count,
    required this.selectedIndex,
    this.onChanged,
    this.semanticLabel,
    this.style,
    super.key,
  }) : assert(count >= 0),
       assert(count == 0 || (selectedIndex >= 0 && selectedIndex < count));

  /// Stateful mark fill, outline and shape. Padding and minimumSize apply
  /// to the indicator; iconSize sets the dot diameter and three-dot pill length.
  final ExpressiveComponentThemeData? style;

  /// How many pages there are.
  final int count;

  /// The current page.
  final int selectedIndex;

  /// What choosing page `i` does; display-only when null.
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls the indicator ("Page n of count" follows).
  final String? semanticLabel;

  /// A dot's diameter, and the pill's height.
  static const double dotSize = ExpressiveSpacing.s8;

  /// The current page's pill length.
  static const double pillLength = ExpressiveSpacing.s24;

  /// The gap between dots.
  static const double gap = ExpressiveSpacing.s8;

  /// The display-only indicator's height; a pressable one stands at the
  /// minimum interactive size.
  static const double touchHeight = ExpressiveSpacing.s24;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final visual = theme.pageDotsTheme.merge(style);
    final dot = visual.iconSize?.resolve(const <WidgetState>{}) ?? dotSize;
    final pill = dot * (pillLength / dotSize);
    final spacing = theme.density.padding(const EdgeInsets.all(gap)).left;
    final shape = theme.shapes.corner(ExpressiveCorner.full);
    OutlinedBorder outline(int i) {
      final states = <WidgetState>{
        if (i == selectedIndex) WidgetState.selected,
      };
      final border = visual.shape?.resolve(states) ?? shape;
      final ink = visual.outline?.resolve(states);
      return border.copyWith(
        side:
            visual.side?.resolve(states) ??
            BorderSide(
              color: ink ?? expressiveTransparent,
              width: 1,
              style: ink == null ? BorderStyle.none : BorderStyle.solid,
            ),
      );
    }

    Color fill(int i) {
      final states = <WidgetState>{
        if (i == selectedIndex) WidgetState.selected,
      };
      return Color.alphaBlend(
        visual.overlayColor?.resolve(states) ?? expressiveTransparent,
        visual.backgroundColor?.resolve(states) ??
            visual.foregroundColor?.resolve(states) ??
            (i == selectedIndex ? colors.primary : colors.outline),
      );
    }

    final select = onChanged;
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: <Widget>[
        for (var i = 0; i < count; i++)
          ExpressiveSpringValue(
            value: i == selectedIndex ? pill : dot,
            motion: ExpressiveMotionKey.fastSpatial,
            builder: (context, length, _) => ExpressiveSpringColor(
              value: fill(i),
              motion: ExpressiveMotionKey.fastEffects,
              builder: (context, color, _) => SizedBox(
                width: math.max(dot, length),
                height: dot,
                child: DecoratedBox(
                  decoration: ShapeDecoration(color: color, shape: outline(i)),
                ),
              ),
            ),
          ),
      ],
    );
    final pressable =
        select != null && ExpressiveMinimumInteractiveSize.enforcedAt(context);
    const target = HostBehavior.minimumInteractiveComponentSize;
    final Widget row = ConstrainedBox(
      constraints: pressable
          ? const BoxConstraints(
              minWidth: target,
              minHeight: target,
              maxHeight: target,
            )
          : BoxConstraints.tightFor(
              height: math.max(dot, theme.density.height(touchHeight)),
            ),
      child: Center(widthFactor: 1, child: dots),
    );
    late BuildContext rowContext;
    final scrolling = Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Builder(
          builder: (context) {
            rowContext = context;
            return row;
          },
        ),
      ),
    );
    // A dot takes a tap: the pointer says so, as a button's does (the
    // adaptive clickable cursor: the hand on the web, the platform's arrow
    // in a desktop app).
    final Widget indicator = select == null
        ? scrolling
        : MouseRegion(
            cursor: WidgetStateMouseCursor.adaptiveClickable,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final box = rowContext.findRenderObject()! as RenderBox;
                select(
                  _pageAt(
                    rowContext,
                    box.globalToLocal(details.globalPosition),
                    dot,
                    pill,
                    spacing,
                  ),
                );
              },
              child: scrolling,
            ),
          );
    final label = semanticLabel;
    final value = ExpressiveLocalizations.of(context)
        .carouselPage(selectedIndex + 1, count);
    return Semantics(
      container: true,
      label: label,
      value: value,
      increasedValue: select != null && selectedIndex + 1 < count
          ? 'Page ${selectedIndex + 2} of $count'
          : null,
      decreasedValue: select != null && selectedIndex > 0
          ? 'Page $selectedIndex of $count'
          : null,
      onIncrease: select != null && selectedIndex + 1 < count
          ? () => select(selectedIndex + 1)
          : null,
      onDecrease: select != null && selectedIndex > 0
          ? () => select(selectedIndex - 1)
          : null,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth:
                visual.minimumSize?.resolve(const <WidgetState>{})?.width ?? 0,
            minHeight:
                visual.minimumSize?.resolve(const <WidgetState>{})?.height ?? 0,
          ),
          child: Padding(
            padding:
                visual.padding?.resolve(const <WidgetState>{}) ??
                EdgeInsets.zero,
            child: indicator,
          ),
        ),
      ),
    );
  }

  /// The page whose dot is nearest [position] along the row.
  int _pageAt(
    BuildContext context,
    Offset position,
    double dot,
    double pill,
    double spacing,
  ) {
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final total = dot * (count - 1) + pill + spacing * (count - 1);
    final origin = (width - total) / 2;
    var x = position.dx - origin;
    if (rtl) x = total - x;
    var best = 0;
    var bestDistance = double.infinity;
    var cursor = 0.0;
    for (var i = 0; i < count; i++) {
      final length = i == selectedIndex ? pill : dot;
      final distance = (x - (cursor + length / 2)).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
      cursor += length + spacing;
    }
    return best;
  }
}
