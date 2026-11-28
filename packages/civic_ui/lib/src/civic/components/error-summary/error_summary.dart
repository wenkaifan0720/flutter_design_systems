import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/announce.dart';
import '../../internal/overhang.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../link/link.dart';

/// One problem in a [CivicErrorSummary]: the field's error, word for word,
/// and what takes the reader to the field.
@immutable
class CivicErrorSummaryItem {
  /// A problem saying [text]; [onPressed] focuses its field.
  const CivicErrorSummaryItem({
    required this.text,
    required this.onPressed,
    this.url,
  });

  /// The error, as the field says it.
  final String text;

  /// Takes the reader to the field: request its focus node's focus.
  final VoidCallback onPressed;

  /// The field's place on the page, as a fragment (`Uri(fragment:
  /// 'full-name')`, a public service's `#full-name`): with one, the entry
  /// is read as a link to the field ([CivicLink.url]); without one, as a
  /// button. Either way a press runs [onPressed], which takes the focus to
  /// the field; the browser does not follow the fragment.
  final Uri? url;
}

/// What a page that was sent with problems shows first, at its top: a box
/// in the error colour titled [title] (There is a problem), listing every
/// problem as a link to its field. It takes the focus as it appears, so the
/// keyboard and a screen reader start from it, and a screen reader hears
/// the title and the count at once.
///
/// Each field shows its own error too, in the same words, on the error
/// rule.
///
/// Every send that fails takes the focus back to the summary and brings it
/// into view, as a public service's does, even when its problems are the
/// same as last time: give [submission] a new value for each send (a count
/// of sends, say).
///
/// Reads [CivicStyle]'s fill, edge (the error edge), padding and textStyle
/// (the title): its `style:`, then [CivicThemeData.errorSummaryStyle]. The
/// focus ring is the look's: yellow, outside the error edge, while the
/// keyboard is in use.
///
/// ```dart
/// Column(
///   children: [
///     if (errors.isNotEmpty)
///       CivicErrorSummary(
///         title: 'There is a problem',
///         submission: sends,
///         errors: [
///           CivicErrorSummaryItem(
///             text: 'Enter your full name',
///             onPressed: nameFocus.requestFocus,
///             url: Uri(fragment: 'full-name'),
///           ),
///         ],
///       ),
///   ],
/// )
/// ```
class CivicErrorSummary extends StatefulWidget {
  /// A summary of a page's problems.
  const CivicErrorSummary({
    super.key,
    required this.title,
    required this.errors,
    this.autofocus = true,
    this.submission,
    this.focusNode,
    this.style,
  });

  /// The title: There is a problem, in the reader's language.
  final String title;

  /// The problems, in the order the fields stand.
  final List<CivicErrorSummaryItem> errors;

  /// Whether it takes the focus as it appears, and again on each send
  /// that fails.
  final bool autofocus;

  /// The send this summary answers, such as a count of sends: a new value
  /// takes the focus back to the summary and brings it into view, even when
  /// the problems are the same. A rebuild with the same value (the reader
  /// typing) leaves the focus where it is. Without one, only a change of the
  /// problems' words takes the focus back.
  final Object? submission;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Overrides for this summary's look.
  final CivicStyle? style;

  @override
  State<CivicErrorSummary> createState() => _CivicErrorSummaryState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IntProperty('errors', errors.length))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<Object>(
          'submission',
          submission,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicErrorSummaryState extends State<CivicErrorSummary> {
  FocusNode? _own;
  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'CivicErrorSummary'));
  bool _focused = false;
  // Whether the keyboard is in use: only then does the focus ring show.
  bool _keys =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  void _onHighlight(FocusHighlightMode mode) {
    final keys = mode == FocusHighlightMode.traditional;
    if (keys != _keys) setState(() => _keys = keys);
  }

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlight);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _node.requestFocus();
        _announce();
        _reveal();
      });
    }
  }

  @override
  void didUpdateWidget(CivicErrorSummary old) {
    super.didUpdateWidget(old);
    final sentAgain =
        widget.submission != old.submission ||
        !listEquals(
          [for (final e in old.errors) e.text],
          [for (final e in widget.errors) e.text],
        );
    if (widget.autofocus && sentAgain) {
      // Another send with problems: the summary takes the focus again and
      // comes back into view, wherever the send was made from.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _node.requestFocus();
        _announce();
        _reveal();
      });
    }
  }

  /// Brings the summary into view with what stands over it. Where the whole
  /// of it shows from the page's start, the page goes back to its start, so
  /// the page's heading over it shows whole and the summary stands where the
  /// page sets it (a page that opens with it keeps its back link), even when
  /// the summary was already in view: a page scrolled a little left its
  /// heading cut by the app's bar. Else, when the summary is above the view
  /// (the page was sent from its foot), it stands [CivicSpacing.s16] under
  /// the view's top edge, never flush under the bar.
  void _reveal() {
    final box = context.findRenderObject();
    final scrollable = Scrollable.maybeOf(context);
    if (box == null || scrollable == null) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final position = scrollable.position;
    final top = viewport.getOffsetToReveal(box, 0).offset;
    final height = box is RenderBox ? box.size.height : 0.0;
    final fromStart =
        top + height <= position.minScrollExtent + position.viewportDimension;
    if (fromStart) {
      if (position.pixels > position.minScrollExtent) {
        position.jumpTo(position.minScrollExtent);
      }
      return;
    }
    if (position.pixels <= top - CivicSpacing.s16) return;
    position.jumpTo(math.max(position.minScrollExtent, top - CivicSpacing.s16));
  }

  void _announce() {
    civicAnnounce(
      context,
      [widget.title, for (final e in widget.errors) e.text].join('. '),
    );
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlight);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf(
      [widget.style, t.errorSummaryStyle],
      {if (_focused) WidgetState.focused},
    );
    final edge = so.edge ?? t.danger;
    final scaler = MediaQuery.textScalerOf(context);
    final grown = scaler.scale(1) - 1;
    // The links stand a little apart however tall their targets: a
    // finger's target leaves the room itself, a pointer's shorter one not.
    final line =
        scaler.scale(text.label.fontSize ?? 19) * (text.label.height ?? 1.25);
    final floor = RawTapTargets.of(context).floorOn().height;
    final gap = math.max(
      math.max(0.0, CivicSpacing.s8 - (floor - line)),
      CivicSpacing.s12 * grown.clamp(0.0, 1.0),
    );
    // A finger's target is taller than a one-line link's words: every link
    // keeps that room round its words, a wrapped one too, so the words stand
    // evenly apart; the last link's room under them comes out of the box's
    // padding ([under]), so the box is as full under its words as over them
    // and the target is laid out whole, a tap anywhere on it landing.
    final spare = math.max(0.0, (floor - line - CivicMetrics.bar) / 2);
    final pad =
        so.padding(Directionality.of(context)) ??
        const EdgeInsets.all(CivicSpacing.s20);
    final under = math.min(spare, pad.bottom);
    final wordStyle = text.body.merge(text.label);
    final direction = Directionality.of(context);
    double wordsAt(String words, double width) {
      final painter = TextPainter(
        text: TextSpan(text: words, style: wordStyle),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: width);
      final height = painter.height + CivicMetrics.bar;
      painter.dispose();
      return height;
    }

    return Focus(
      focusNode: _node,
      onFocusChange: (v) => setState(() => _focused = v),
      child: CivicSpringValue(
        // The box keeps its error edge with the focus; the yellow ring
        // stands outside it while the keyboard is in use (a pointer or a
        // finger that sent the page sees the box itself).
        value: _focused && _keys ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, child) => CustomPaint(
          foregroundPainter: _Ring(focus: focus, color: t.focus),
          child: child,
        ),
        child: Semantics(
          container: true,
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: so.fill ?? t.background,
              border: Border.all(color: edge, width: CivicMetrics.bar),
            ),
            child: Padding(
              padding: pad.copyWith(bottom: pad.bottom - under),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      style: text.headingM.merge(so.textStyle),
                    ),
                  ),
                  // The title stands off its links further than they stand
                  // apart, so it reads as theirs and not as one of them.
                  const SizedBox(height: CivicSpacing.s16),
                  for (final (i, e) in widget.errors.indexed)
                    // At a large text size a link that wraps fills its tap
                    // height, so the links take room between them.
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == widget.errors.length - 1 ? 0 : gap,
                      ),
                      child: CivicOverhang(
                        // Only what the box's padding could not give.
                        bottom: i == widget.errors.length - 1
                            ? spare - under
                            : 0,
                        child: _EvenRoom(
                          room: spare,
                          words: (width) => wordsAt(e.text, width),
                          child: CivicLink(
                            onPressed: e.onPressed,
                            url: e.url,
                            textStyle: text.label.copyWith(color: t.danger),
                            child: Text(e.text),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A link that keeps [room] round its words whatever its height: a one-line
/// link's tap target already leaves it, a link that wraps fills its target,
/// so it takes the room outside it.
class _EvenRoom extends SingleChildRenderObjectWidget {
  const _EvenRoom({
    required this.room,
    required this.words,
    required Widget super.child,
  });

  final double room;

  /// The height of the link's words at a width.
  final double Function(double width) words;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEvenRoom(room, words);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderEvenRoom)
      ..room = room
      ..words = words;
  }
}

class _RenderEvenRoom extends RenderProxyBox {
  _RenderEvenRoom(this._room, this._words);

  double _room;
  set room(double value) {
    if (value == _room) return;
    _room = value;
    markNeedsLayout();
  }

  double Function(double width) _words;
  set words(double Function(double width) value) {
    _words = value;
    markNeedsLayout();
  }

  double _padFor(double height, double width) =>
      math.max(0, _room - (height - _words(width)) / 2);

  double _pad = 0;

  @override
  void performLayout() {
    final c = child!;
    c.layout(
      constraints.loosen().copyWith(maxHeight: double.infinity),
      parentUsesSize: true,
    );
    _pad = _padFor(c.size.height, constraints.maxWidth);
    size = constraints.constrain(Size(c.size.width, c.size.height + 2 * _pad));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child!.getDryLayout(
      constraints.loosen().copyWith(maxHeight: double.infinity),
    );
    return constraints.constrain(
      Size(c.width, c.height + 2 * _padFor(c.height, constraints.maxWidth)),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final h = super.computeMinIntrinsicHeight(width);
    return h + 2 * _padFor(h, width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final h = super.computeMaxIntrinsicHeight(width);
    return h + 2 * _padFor(h, width);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final b = child!.getDistanceToActualBaseline(baseline);
    return b == null ? null : b + _pad;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.paintChild(child!, offset + Offset(0, _pad));
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, _pad, 0, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: Offset(0, _pad),
        position: position,
        hitTest: (result, transformed) =>
            child!.hitTest(result, position: transformed),
      );
}

/// The focus on the summary: the yellow ring stands outside its error edge,
/// a 2 pt gap of the page between them, so by night the light error edge
/// and the yellow never run together into one band.
class _Ring extends CustomPainter {
  _Ring({required this.focus, required this.color});

  final double focus;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final f = focus.clamp(0.0, 1.0);
    if (f <= 0) return;
    final w = CivicMetrics.focusRing * f;
    canvas.drawRect(
      (Offset.zero & size).inflate(CivicMetrics.edge * f + w / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Ring old) => old.focus != focus || old.color != color;
}
