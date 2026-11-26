import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'words.dart';

/// A week chart's day readings, all in one form: each day's
/// [StintWords.duration] when every one fits its slot on one line, else each
/// day's [StintWords.hours] (h:mm), under a caption naming what they count
/// ([StintWords.logged]).
class WeekReadings {
  const WeekReadings._(this.labels, this.compact);

  /// The readings of [minutes] for slots [slot] wide, set in [style] (merged
  /// over the ambient text style) at the reader's text size.
  factory WeekReadings.fit(
    BuildContext context, {
    required StintWords words,
    required List<int> minutes,
    required TextStyle style,
    required double slot,
  }) {
    final full = [for (final m in minutes) words.duration(m)];
    final fits = full.every((s) => textWidth(context, s, style) <= slot);
    return WeekReadings._(
      fits ? full : [for (final m in minutes) words.hours(m)],
      !fits,
    );
  }

  /// One reading a day, Monday first.
  final List<String> labels;

  /// Whether the readings are h:mm ([StintWords.hours]), under a caption.
  final bool compact;
}

/// How wide [text] sets on one line in [style] (merged over the ambient text
/// style) at the reader's text size: the line's own width, which on the web
/// can exceed the paragraph's intrinsic width where a line runs through
/// fallback faces (Japanese in a Latin face).
double textWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    textWidthBasis: TextWidthBasis.longestLine,
    maxLines: 1,
  )..layout();
  try {
    return painter.width;
  } finally {
    painter.dispose();
  }
}

/// Two buttons in equal halves of a row when each fits its half at its own
/// width, else one above the other at the full width: their words are never
/// cut or broken to keep the row, whatever the language or text size.
///
/// Each button's own width is its widest intrinsic width: the width it needs
/// on one line. A button that cannot answer that (one built on a
/// [LayoutBuilder]) comes with [measureFirst] and [measureSecond]: the same
/// buttons at their own width, laid out to measure and never shown, focused,
/// touched or announced.
class StintPair extends MultiChildRenderObjectWidget {
  /// [first] at the row's start (on top when stacked), [second] after it.
  StintPair({
    super.key,
    required Widget first,
    required Widget second,
    Widget? measureFirst,
    Widget? measureSecond,
    this.spacing = 8,
    this.runSpacing,
  }) : assert((measureFirst == null) == (measureSecond == null)),
       super(
         children: [
           first,
           second,
           if (measureFirst != null && measureSecond != null)
             for (final measure in [measureFirst, measureSecond])
               ExcludeFocus(
                 child: ExcludeSemantics(
                   child: IgnorePointer(
                     child: TickerMode(enabled: false, child: measure),
                   ),
                 ),
               ),
         ],
       );

  /// The space between the halves of the row.
  final double spacing;

  @override
  MultiChildRenderObjectElement createElement() => _PairElement(this);

  /// The space between the stacked buttons; null: [spacing].
  final double? runSpacing;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderStintPair(
    spacing: spacing,
    runSpacing: runSpacing ?? spacing,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderStintPair renderObject) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing ?? spacing
      ..textDirection = Directionality.of(context);
  }
}

/// Keeps the measuring copies off stage, as [Offstage] keeps its child:
/// finders and inspectors see the two buttons shown.
class _PairElement extends MultiChildRenderObjectElement {
  _PairElement(StintPair super.widget);

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    var shown = 0;
    visitChildren((child) {
      if (shown++ < 2) visitor(child);
    });
  }
}

class _PairData extends ContainerBoxParentData<RenderBox> {}

/// The render object of [StintPair].
class RenderStintPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PairData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PairData>,
        RelayoutWhenSystemFontsChangeMixin {
  RenderStintPair({
    required this._spacing,
    required this._runSpacing,
    required this._textDirection,
  });

  double get spacing => _spacing;
  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing(double value) {
    if (value == _runSpacing) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  // Fonts that land after a layout (Japanese on the web, fetched on first
  // use) change the words' widths, and the words then lay out again on their
  // own, below the buttons: the pair lays both buttons out afresh, words and
  // all, and decides again.
  @override
  void systemFontsDidChange() {
    super.systemFontsDidChange();
    void relayout(RenderObject o) {
      o.markNeedsLayout();
      o.visitChildren(relayout);
    }

    visitChildren(relayout);
  }

  /// Whether the last layout set the two side by side.
  bool get sideBySide => _sideBySide;
  bool _sideBySide = true;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PairData) child.parentData = _PairData();
  }

  /// The two buttons shown.
  List<RenderBox> get _shown => getChildrenAsList().take(2).toList();

  /// Their measuring copies, if any.
  List<RenderBox> get _measures => getChildrenAsList().skip(2).toList();

  @override
  double computeMinIntrinsicWidth(double height) => _shown.fold(
    0,
    (w, c) =>
        w > c.getMinIntrinsicWidth(height) ? w : c.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _shown.fold<double>(0, (w, c) => w + c.getMaxIntrinsicWidth(height)) +
      spacing;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _shown.fold<double>(0, (h, c) => h + c.getMinIntrinsicHeight(width)) +
      runSpacing;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _shown.fold<double>(0, (h, c) => h + c.getMaxIntrinsicHeight(width)) +
      runSpacing;

  /// Whether both fit their halves of [width] on one line each. Measuring
  /// copies are laid out, so only during layout.
  bool _fits(double width) {
    if (!width.isFinite) return false;
    final half = (width - spacing) / 2;
    final measures = _measures;
    if (measures.isNotEmpty) {
      return measures.every((c) {
        c.layout(BoxConstraints(maxWidth: width), parentUsesSize: true);
        return c.size.width <= half + 0.5;
      });
    }
    return _shown.every(
      (c) => c.getMaxIntrinsicWidth(double.infinity) <= half + 0.5,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (_measures.isNotEmpty) {
      assert(
        debugCannotComputeDryLayout(
          reason: 'A StintPair with measuring copies lays them out to measure.',
        ),
      );
      return Size.zero;
    }
    final width = constraints.maxWidth;
    if (_fits(width)) {
      final half = BoxConstraints.tightFor(width: (width - spacing) / 2);
      final height = _shown.fold<double>(0, (h, c) {
        final child = c.getDryLayout(half).height;
        return child > h ? child : h;
      });
      return constraints.constrain(Size(width, height));
    }
    final full = width.isFinite ? width : computeMaxIntrinsicWidth(0);
    final whole = BoxConstraints.tightFor(width: full);
    final height = _shown.fold<double>(
      runSpacing,
      (h, c) => h + c.getDryLayout(whole).height,
    );
    return constraints.constrain(Size(full, height));
  }

  /// Whether words in [box] break onto a second line or are cut, as laid
  /// out: each paragraph's words, set on one line, against the width its
  /// parent gave it. The web's intrinsic widths run short for some text
  /// (Japanese in a fallback face), so a half that seemed wide enough can
  /// still break them; a line's own width does not.
  static bool _broken(RenderObject box) {
    var broken = false;
    void visit(RenderObject o) {
      if (broken) return;
      if (o is RenderParagraph && _overflows(o)) {
        broken = true;
        return;
      }
      o.visitChildren(visit);
    }

    visit(box);
    return broken;
  }

  /// Whether [p]'s words, on one line, are wider than [p] may be.
  static bool _overflows(RenderParagraph p) {
    final width = p.constraints.maxWidth;
    if (!width.isFinite) return false;
    var inline = false;
    p.text.visitChildren((span) {
      inline = span is PlaceholderSpan;
      return !inline;
    });
    // Words around inline widgets need their sizes: what the layout says.
    if (inline) return p.didExceedMaxLines;
    final painter = TextPainter(
      text: p.text,
      textDirection: p.textDirection,
      textScaler: p.textScaler,
      locale: p.locale,
      strutStyle: p.strutStyle,
      textHeightBehavior: p.textHeightBehavior,
      textWidthBasis: TextWidthBasis.longestLine,
      maxLines: 1,
    )..layout();
    try {
      return painter.width > width + 0.5;
    } finally {
      painter.dispose();
    }
  }

  @override
  void performLayout() {
    final children = _shown;
    final width = constraints.maxWidth;
    final half = (width - spacing) / 2;
    // The width each needs on one line: a half too narrow for either
    // stacks them, each over the whole width; so do words that break at the
    // half all the same.
    _sideBySide = _fits(width);
    if (_sideBySide) {
      var height = 0.0;
      for (final c in children) {
        c.layout(BoxConstraints.tightFor(width: half), parentUsesSize: true);
        if (c.size.height > height) height = c.size.height;
      }
      _sideBySide = !children.any(_broken);
      if (_sideBySide) {
        for (final (i, c) in children.indexed) {
          // Side by side, the two stand equally tall.
          if (c.size.height < height) {
            c.layout(
              BoxConstraints.tightFor(width: half, height: height),
              parentUsesSize: true,
            );
          }
          final start = i * (half + spacing);
          (c.parentData! as _PairData).offset = Offset(
            textDirection == TextDirection.rtl ? width - start - half : start,
            0,
          );
        }
        size = constraints.constrain(Size(width, height));
        return;
      }
    }
    final full = width.isFinite ? width : computeMaxIntrinsicWidth(0);
    var y = 0.0;
    for (final (i, c) in children.indexed) {
      if (i > 0) y += runSpacing;
      c.layout(BoxConstraints.tightFor(width: full), parentUsesSize: true);
      (c.parentData! as _PairData).offset = Offset(0, y);
      y += c.size.height;
    }
    size = constraints.constrain(Size(full, y));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final c in _shown.reversed) {
      final offset = (c.parentData! as _PairData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            c.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) =>
      _shown.forEach(visitor);

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final c in _shown) {
      context.paintChild(c, (c.parentData! as _PairData).offset + offset);
    }
  }
}
