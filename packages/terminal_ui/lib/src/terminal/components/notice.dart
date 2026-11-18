/// What a screen says about itself: a banner over its content (the
/// connection dropped, a run failed) and the empty state in place of a
/// list with nothing in it.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../style.dart';
import '../theme.dart';
import 'feedback.dart';

/// A banner: a line in [tone] across the top of what it is about, its
/// glyph and a bar in the tone's ink at the start, [message], and an
/// [action] at the end (a `TermButton`: retry, open). A screen reader
/// hears it as it appears.
///
/// ```dart
/// TermBanner(
///   tone: TermTone.error,
///   message: 'connection lost · showing the runs from 2 min ago',
///   action: TermButton(label: 'retry', onPressed: retry),
/// )
/// ```
class TermBanner extends StatelessWidget {
  /// A banner saying [message].
  const TermBanner({
    super.key,
    required this.message,
    this.tone = TermTone.info,
    this.title,
    this.action,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.bannerStyle]: `fill` (the
  /// ground) and `edge` (the bar at the start).
  final TermStyle? style;

  /// What it says.
  final String message;

  /// How it says it: its glyph and its ink.
  final TermTone tone;

  /// A word before the message, in bold: `offline`, `failed`.
  final String? title;

  /// What can be done about it, at the end of the line.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final ink = tone.colorIn(theme);
    final own = TermStyleOf([style, theme.bannerStyle], const {});
    // Right to left, the title and the message each keep their own
    // direction (U+2068 to U+2069, a first-strong isolate), so a title in
    // Latin letters still stands first, next to its glyph, and not at the
    // far end of a Latin message.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    String apart(String text) => rtl ? '\u2068$text\u2069' : text;
    final words = Text.rich(
      TextSpan(
        children: [
          if (title != null)
            TextSpan(
              text: '${apart(title!)}  ',
              style: theme.boldStyle.copyWith(color: ink),
            ),
          TextSpan(text: apart(message)),
        ],
      ),
    );
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(tone.glyph, style: theme.boldStyle.copyWith(color: ink)),
        ),
        SizedBox(width: cw),
        Expanded(child: words),
      ],
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: CustomPaint(
        painter: _BarPainter(
          ground:
              own.fill ??
              Color.alphaBlend(ink.withValues(alpha: 0.12), theme.background),
          bar: own.edge ?? ink,
          width: cw * 0.5,
          direction: Directionality.of(context),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            cw * 2,
            grid.lineHeight * 0.5,
            cw,
            grid.lineHeight * 0.5,
          ),
          // The action ends the line while the words fit on it whole;
          // when they would wrap, they take the banner's whole width and the
          // action stands under them, at the end.
          child: action == null
              ? line
              : _BesideOrUnder(gap: cw, lead: line, action: action!),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(EnumProperty<TermTone>('tone', tone, defaultValue: TermTone.info))
      ..add(StringProperty('title', title, defaultValue: null));
  }
}

/// What stands in place of a list with nothing in it: a dim [glyph],
/// [title], what to try in [message], and an [action], on the list's own
/// start edge, as a terminal prints it.
///
/// ```dart
/// TermEmptyState(
///   title: 'no runs match "mobile-gatway"',
///   message: 'try fewer letters, or another branch',
///   action: TermButton(label: 'clear search', onPressed: clear),
/// )
/// ```
class TermEmptyState extends StatelessWidget {
  /// An empty state saying [title].
  const TermEmptyState({
    super.key,
    required this.title,
    this.message,
    this.glyph = '∅',
    this.action,
    this.style,
  });

  /// Overrides, over the theme's [TermThemeData.emptyStateStyle]:
  /// `foreground` (the title) and `edge` (the glyph).
  final TermStyle? style;

  /// What is empty.
  final String title;

  /// What to try.
  final String? message;

  /// The dim mark before the title.
  final String glyph;

  /// What to do about it.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final own = TermStyleOf([style, theme.emptyStateStyle], const {});
    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: lh),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                glyph,
                style: theme.boldStyle.copyWith(color: own.edge ?? theme.dim),
              ),
            ),
            SizedBox(width: cw),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.boldStyle.copyWith(color: own.foreground),
                  ),
                  if (message != null) Text(message!, style: theme.dimStyle),
                  if (action != null) ...[SizedBox(height: lh), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(StringProperty('glyph', glyph, defaultValue: '∅'));
  }
}

// The banner's ground, and its bar: [width] of the tone's ink down the
// start edge.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.ground,
    required this.bar,
    required this.width,
    required this.direction,
  });

  final Color ground;
  final Color bar;
  final double width;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final x = direction == TextDirection.ltr ? 0.0 : size.width - width;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, width, size.height),
      Paint()..color = bar,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.ground != ground ||
      old.bar != bar ||
      old.width != width ||
      old.direction != direction;
}

/// A banner's line and its action: the action ends the line, the two
/// centred on each other, while the words fit beside it on one line;
/// otherwise the words take the whole width and the action stands under
/// them at the end.
class _BesideOrUnder extends MultiChildRenderObjectWidget {
  _BesideOrUnder({
    required this.gap,
    required Widget lead,
    required Widget action,
  }) : super(children: [lead, action]);

  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBesideOrUnder(gap, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBesideOrUnder renderObject,
  ) {
    renderObject
      ..gap = gap
      ..textDirection = Directionality.of(context);
  }
}

class _Slot extends ContainerBoxParentData<RenderBox> {}

class _RenderBesideOrUnder extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _Slot>,
        RenderBoxContainerDefaultsMixin<RenderBox, _Slot> {
  _RenderBesideOrUnder(this._gap, this._textDirection);

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _lead => firstChild!;
  RenderBox get _action => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _Slot) child.parentData = _Slot();
  }

  /// Whether the words fit on one line beside an action [action] wide.
  bool _beside(double width, double action) =>
      !width.isFinite ||
      _lead.getMaxIntrinsicWidth(double.infinity) + _gap + action <= width;

  ({Size size, Offset lead, Offset action}) _arrange(
    BoxConstraints constraints,
    ChildLayouter layout,
  ) {
    final width = constraints.maxWidth;
    final action = layout(_action, BoxConstraints(maxWidth: width));
    final rtl = _textDirection == TextDirection.rtl;
    if (_beside(width, action.width)) {
      final leadWidth = width.isFinite
          ? width - _gap - action.width
          : _lead.getMaxIntrinsicWidth(double.infinity);
      final lead = layout(_lead, BoxConstraints.tightFor(width: leadWidth));
      final height = lead.height > action.height ? lead.height : action.height;
      final size = constraints.constrain(
        Size(leadWidth + _gap + action.width, height),
      );
      return (
        size: size,
        lead: Offset(
          rtl ? size.width - lead.width : 0,
          (height - lead.height) / 2,
        ),
        action: Offset(
          rtl ? 0 : size.width - action.width,
          (height - action.height) / 2,
        ),
      );
    }
    final lead = layout(_lead, BoxConstraints.tightFor(width: width));
    final size = constraints.constrain(
      Size(width, lead.height + action.height),
    );
    return (
      size: size,
      lead: Offset(rtl ? size.width - lead.width : 0, 0),
      action: Offset(rtl ? 0 : size.width - action.width, lead.height),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  void performLayout() {
    final laid = _arrange(constraints, ChildLayoutHelper.layoutChild);
    size = laid.size;
    (_lead.parentData! as _Slot).offset = laid.lead;
    (_action.parentData! as _Slot).offset = laid.action;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final lead = _lead.getMinIntrinsicWidth(height);
    final action = _action.getMinIntrinsicWidth(height);
    return lead > action ? lead : action;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _lead.getMaxIntrinsicWidth(height) +
      _gap +
      _action.getMaxIntrinsicWidth(height);

  double _height(double width, double Function(RenderBox, double) of) {
    final action = _action.getMaxIntrinsicWidth(double.infinity);
    if (_beside(width, action)) {
      final lead = of(_lead, width.isFinite ? width - _gap - action : width);
      final own = of(_action, action);
      return lead > own ? lead : own;
    }
    return of(_lead, width) + of(_action, width);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
