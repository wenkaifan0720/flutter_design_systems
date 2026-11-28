import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/option.dart';
import '../avatar/avatar.dart';
import '../../internal/paint.dart';
import '../../internal/row_hover.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A row of a list: its [title] in bold ink, a [subtitle] (its meta line)
/// under it, a [leading] glyph before them, a [trailing] status (a
/// [CivicTag]). On a wide row the status stands at the end while the title
/// and the meta line each still fit on one line beside it; on a phone's row
/// (every row of the list alike), or when they would not fit, it stands on a
/// line of its own under the title, so neither breaks for the status.
/// A row that goes somewhere ([onTap]) is pressed whole, at least 56 high,
/// and ends in a chevron in the action colour pointing the way the words
/// read; never an underlined link. A pointer over it greys the row, a press
/// a step deeper; a keyboard focus lays the whole row on the yellow plate
/// over the ink bar.
///
/// Rows stand in a [CivicListGroup], white on the page's ground, hairlines
/// between them; a row on its own stands over a rule ([showRule]). The row
/// whose record stands open beside the list ([selected], a tablet's list and
/// record) is marked as the side navigation's current place is: on the
/// action's tint, the inset rule in the action colour at its start.
///
/// Reads [CivicStyle]'s foreground (the title, by state), padding and
/// textStyle (the title): its `style:`, then [CivicThemeData.listRowStyle].
/// The rule, the chevron and the focus plate are the look's.
///
/// ```dart
/// CivicListGroup(
///   children: [
///     CivicListRow(
///       title: const Text('Resident permit, Zone B'),
///       subtitle: const Text('BRM-4821-K · Sent 3 November'),
///       trailing: const CivicTag(label: 'In review', tone: CivicTone.info),
///       onTap: () => openApplication('BRM-4821-K'),
///     ),
///   ],
/// )
/// ```
class CivicListRow extends StatelessWidget {
  /// A row.
  const CivicListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showRule = true,
    this.showChevron = true,
    this.endIcon,
    this.selected = false,
    this.semanticLabel,
    this.semanticValue,
    this.style,
    this.focusNode,
  });

  /// What it is.
  final Widget title;

  /// What else to know, under the title.
  final Widget? subtitle;

  /// What stands before the words: a glyph, a picture or a monogram (an
  /// [Icon], an [Image], a [CivicAvatar]), or a control (a [CivicCheckbox]).
  ///
  /// A screen reader leaves a glyph, a picture or a monogram out of the
  /// row's name, which it would only repeat: what it means goes in the
  /// [title], or in the [trailing] status. Any other leading is heard. A
  /// control keeps its state, its action and its focus: in a row of words
  /// the row takes them, as a checkbox list tile does, so the row reads
  /// "checked" and a tap on it ticks the box; in a row that goes somewhere
  /// ([onTap]) the control keeps a node of its own beside the row's. Wrap a
  /// leading of your own that only repeats the title in an
  /// [ExcludeSemantics].
  final Widget? leading;

  /// A status at the end, read in the row's name after its words.
  final Widget? trailing;

  /// Called on a press; null leaves it a row of words.
  final VoidCallback? onTap;

  /// Whether a rule stands under it, on its own; in a [CivicListGroup] the
  /// group draws the hairlines.
  final bool showRule;

  /// Whether a row that goes somewhere ends in a chevron.
  final bool showChevron;

  /// The glyph the row ends in in place of the chevron that points the way
  /// the words read: a row that opens something in place (a fold of
  /// filters) ends in a chevron down, or up while it is open.
  final IconData? endIcon;

  /// Whether its record stands open beside the list.
  final bool selected;

  /// What a screen reader says for the whole row; null merges its words.
  final String? semanticLabel;

  /// What a row that goes somewhere holds, read after its name ("Current
  /// step"); null reads nothing more. A row of words reads all its words.
  final String? semanticValue;

  /// Overrides for this row's look.
  final CivicStyle? style;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// The least a row that goes somewhere stands: a finger's row.
  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final acts = onTap != null;
    final grouped = _GroupScope.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final heard = leading != null && !_onlyRepeats(leading!);
    // A row that names itself keeps its own words out of its node; a leading
    // that is heard stays in the tree beside them.
    Widget named(Widget words) => acts && heard && semanticLabel != null
        ? ExcludeSemantics(child: words)
        : words;
    Widget body(Set<WidgetState> states, double focus) {
      final so = RawStyleOf([style, t.listRowStyle], states);
      final titleInk = Color.lerp(
        so.foreground ?? t.textPrimary,
        t.onFocus,
        focus,
      )!;
      final subInk = Color.lerp(t.textSecondary, t.onFocus, focus)!;
      final lead = leading;
      final end = trailing;
      final sub = subtitle;
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: acts ? minHeight : 0),
        child: Padding(
          padding:
              so.padding(Directionality.of(context)) ??
              EdgeInsets.symmetric(
                horizontal: grouped ? CivicSpacing.s16 : 0,
                vertical: CivicSpacing.s16,
              ),
          child: _RowLine(
            gap: CivicSpacing.s12,
            textScale: MediaQuery.textScalerOf(context).scale(16) / 16,
            leading: lead == null
                ? null
                : IconTheme.merge(
                    data: IconThemeData(
                      color: Color.lerp(t.action, t.onFocus, focus),
                      size: 24,
                    ),
                    // Out of the row's name: a glyph or a monogram only
                    // repeats the title; a status goes in [trailing]. A
                    // control is heard.
                    child: heard ? lead : ExcludeSemantics(child: lead),
                  ),
            words: named(
              _Beside(
                gap: CivicSpacing.s12,
                textScale: MediaQuery.textScalerOf(context).scale(16) / 16,
                title: DefaultTextStyle.merge(
                  style: text.label
                      .merge(so.textStyle)
                      .copyWith(color: titleInk),
                  child: title,
                ),
                subtitle: sub == null
                    ? null
                    : DefaultTextStyle(
                        style: text.bodySmall.copyWith(color: subInk),
                        child: sub,
                      ),
                status: end,
              ),
            ),
            end: !(acts && showChevron)
                ? null
                : Transform.flip(
                    flipX: rtl && endIcon == null,
                    child: Icon(
                      endIcon ?? LucideIcons.chevronRight,
                      size: 24,
                      applyTextScaling: true,
                      color: Color.lerp(t.action, t.onFocus, focus),
                    ),
                  ),
          ),
        ),
      );
    }

    final row = !acts
        ? MergeSemantics(child: body(const {}, 0))
        : RawButton(
            onPressed: onTap,
            focusNode: focusNode,
            semanticLabel: semanticLabel,
            semanticValue: semanticValue,
            excludeSemantics: semanticLabel != null && !heard,
            // A control before the words keeps a node of its own, which a
            // screen reader reaches apart; the words still name the row.
            mergeSemantics: !heard,
            link: true,
            button: false,
            semanticSelected: selected ? true : null,
            mouseCursor: SystemMouseCursors.click,
            // A pointer over the row greys it, a press a step deeper, so a
            // finger sees what it took; the keyboard's focus lays it on the
            // yellow plate, past its words when it stands on its own.
            builder: (context, states, _) => CivicSpringValue(
              value: states.contains(WidgetState.pressed)
                  ? 1
                  // In a row of more parts, the row greys under a pointer.
                  : states.contains(WidgetState.hovered) &&
                        !CivicRowHover.inRow(context)
                  ? 0.5
                  : 0,
              spring: CivicMotion.press,
              effects: true,
              builder: (context, touch, _) => CustomPaint(
                foregroundPainter: selected
                    ? _StartMark(
                        color: t.action,
                        direction: Directionality.of(context),
                      )
                    : null,
                child: ColoredBox(
                  color: selected
                      ? Color.lerp(
                          t.secondaryFill,
                          t.secondaryEdge,
                          0.5 * touch.clamp(0.0, 1.0),
                        )!
                      : Color.lerp(
                          t.surface.withValues(alpha: 0),
                          Color.lerp(t.surface, t.rule, 0.6)!,
                          touch.clamp(0.0, 1.0),
                        )!,
                  child: CivicSpringValue(
                    value: states.contains(WidgetState.focused) ? 1 : 0,
                    spring: CivicMotion.focus,
                    effects: true,
                    builder: (context, focus, _) => CustomPaint(
                      painter: CivicFacePainter(
                        fill: t.focus.withValues(alpha: 0),
                        outset: grouped ? 0 : CivicSpacing.s8,
                        edgeColor: t.onFocus,
                        edgeHeight: 0,
                        press: 0,
                        focus: focus,
                        focusColor: t.focus,
                        barColor: t.focusBar,
                      ),
                      child: body(states, focus),
                    ),
                  ),
                ),
              ),
            ),
          );
    if (!showRule || grouped) return row;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.rule)),
      ),
      child: row,
    );
  }

  // A glyph, a picture or a monogram: what it means is in the row's words.
  static bool _onlyRepeats(Widget leading) =>
      leading is Icon ||
      leading is Image ||
      leading is CivicAvatar ||
      leading is CivicAvatarGroup;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(FlagProperty('showRule', value: showRule, ifFalse: 'no rule'))
      ..add(
        FlagProperty('showChevron', value: showChevron, ifFalse: 'no chevron'),
      )
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(StringProperty('semanticValue', semanticValue, defaultValue: null))
      ..add(DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      );
  }
}

/// The inset rule at the start of the row whose record stands open.
class _StartMark extends CustomPainter {
  _StartMark({required this.color, required this.direction});

  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    const w = CivicMetrics.insetRule;
    final x = direction == TextDirection.rtl ? size.width - w : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, w, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StartMark old) =>
      old.color != color || old.direction != direction;
}

/// A group of rows on a card: white (by night, slate) on the page's ground,
/// its corners a little rounded, no stroke round it, hairlines between its
/// rows from their words' start (a child that draws nothing, a row left
/// out, takes no hairline); a [title] over it, outside the card, says
/// what they are. A list of things (applications, tasks, settings, search
/// results) stands in one, as an app's lists do.
///
/// ```dart
/// CivicListGroup(
///   title: 'Your applications',
///   children: [
///     CivicListRow(
///       title: const Text('Visitor permits, 10 days'),
///       onTap: () => openApplication('BRM-3307-A'),
///     ),
///   ],
/// )
/// ```
class CivicListGroup extends StatelessWidget {
  /// A group of [children], most often [CivicListRow]s.
  const CivicListGroup({super.key, required this.children, this.title});

  /// The rows.
  final List<Widget> children;

  /// What the rows are, over the card.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final head = title;
    final card = ClipPath.shape(
      shape: t.shapeScheme.corners.border(RawCorner.medium),
      child: ColoredBox(
        color: t.background,
        child: _GroupScope(
          child: CivicCardScope(
            child: _Ruled(color: t.hairline, children: children),
          ),
        ),
      ),
    );
    if (head == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(header: true, child: Text(head, style: text.headingS)),
        const SizedBox(height: CivicSpacing.s12),
        card,
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(IntProperty('children', children.length));
  }
}

/// A group's rows, full width, a hairline from the words' start between
/// each two that draw something.
class _Ruled extends MultiChildRenderObjectWidget {
  const _Ruled({required this.color, required super.children});

  final Color color;

  @override
  _RenderRuled createRenderObject(BuildContext context) =>
      _RenderRuled(color, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderRuled renderObject) =>
      renderObject
        ..color = color
        ..textDirection = Directionality.of(context);
}

class _RuledParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderRuled extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RuledParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RuledParentData> {
  _RenderRuled(this._color, this._textDirection);

  static const double _hairline = 1;

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  // Where each hairline is drawn, from the top.
  final List<double> _lines = [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RuledParentData) {
      child.parentData = _RuledParentData();
    }
  }

  Iterable<RenderBox> get _rows sync* {
    var child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  // The heights stacked, a hairline between the ones that draw something.
  double _stack(Iterable<double> heights) {
    var total = 0.0;
    var any = false;
    for (final height in heights) {
      if (height <= 0) continue;
      if (any) total += _hairline;
      total += height;
      any = true;
    }
    return total;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _rows.fold(
    0,
    (widest, row) => math.max(widest, row.getMinIntrinsicWidth(height)),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => _rows.fold(
    0,
    (widest, row) => math.max(widest, row.getMaxIntrinsicWidth(height)),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _stack(_rows.map((row) => row.getMinIntrinsicHeight(width)));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _stack(_rows.map((row) => row.getMaxIntrinsicHeight(width)));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final each = BoxConstraints.tightFor(width: constraints.maxWidth);
    return constraints.constrain(
      Size(
        constraints.maxWidth,
        _stack(_rows.map((row) => row.getDryLayout(each).height)),
      ),
    );
  }

  @override
  void performLayout() {
    final each = BoxConstraints.tightFor(width: constraints.maxWidth);
    _lines.clear();
    var y = 0.0;
    var any = false;
    for (final row in _rows) {
      row.layout(each, parentUsesSize: true);
      if (row.size.height > 0) {
        if (any) {
          _lines.add(y);
          y += _hairline;
        }
        any = true;
      }
      (row.parentData! as _RuledParentData).offset = Offset(0, y);
      y += row.size.height;
    }
    size = constraints.constrain(Size(constraints.maxWidth, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paint = Paint()..color = _color;
    final ltr = _textDirection == TextDirection.ltr;
    final width = size.width - CivicSpacing.s16;
    for (final line in _lines) {
      context.canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + (ltr ? CivicSpacing.s16 : 0),
          offset.dy + line,
          width,
          _hairline,
        ),
        paint,
      );
    }
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Says to the rows under it that they stand in a [CivicListGroup].
class _GroupScope extends InheritedWidget {
  const _GroupScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupScope>() != null;

  @override
  bool updateShouldNotify(_GroupScope oldWidget) => false;
}

/// A row's line: its leading glyph, its words and its chevron side by side;
/// in a row narrower than [_RenderRowLine._glyphsBeside] at the body's own
/// size (a phone at a large text size), the glyphs on a line of their own
/// over the words, the leading one at the start and the chevron at the end,
/// so the words take the row's whole width and keep a long word whole. The
/// same in every row of a list, whatever its words.
class _RowLine extends MultiChildRenderObjectWidget {
  _RowLine({
    required this.gap,
    required this.textScale,
    required Widget words,
    Widget? leading,
    Widget? end,
  }) : hasLeading = leading != null,
       hasEnd = end != null,
       super(children: [?leading, words, ?end]);

  final double gap;
  final double textScale;
  final bool hasLeading;
  final bool hasEnd;

  @override
  _RenderRowLine createRenderObject(BuildContext context) => _RenderRowLine(
    gap,
    textScale,
    Directionality.of(context),
    hasLeading,
    hasEnd,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderRowLine renderObject) {
    renderObject
      ..gap = gap
      ..textScale = textScale
      ..textDirection = Directionality.of(context)
      ..hasLeading = hasLeading
      ..hasEnd = hasEnd;
  }
}

class _RowLineData extends ContainerBoxParentData<RenderBox> {}

class _RenderRowLine extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowLineData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowLineData> {
  _RenderRowLine(
    this._gap,
    this._textScale,
    this._textDirection,
    this._hasLeading,
    this._hasEnd,
  );

  /// The narrowest row, in points at the body's own size, that keeps its
  /// glyphs beside its words: a phone's row at about 1.7 times the text and
  /// more stands them over the words.
  static const double _glyphsBeside = 200;

  /// Between the glyphs' line and the words under it.
  static const double _lines = CivicSpacing.s8;

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _textScale;
  set textScale(double value) {
    if (value == _textScale) return;
    _textScale = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool _hasLeading;
  set hasLeading(bool value) {
    if (value == _hasLeading) return;
    _hasLeading = value;
    markNeedsLayout();
  }

  bool _hasEnd;
  set hasEnd(bool value) {
    if (value == _hasEnd) return;
    _hasEnd = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _RowLineData) child.parentData = _RowLineData();
  }

  RenderBox? get _leading => _hasLeading ? firstChild : null;
  RenderBox get _words => _hasLeading ? childAfter(firstChild!)! : firstChild!;
  RenderBox? get _end => _hasEnd ? lastChild : null;

  /// Whether the glyphs stand over the words in a row [width] wide.
  bool _over(double width) =>
      (_hasLeading || _hasEnd) &&
      width.isFinite &&
      width / _textScale < _glyphsBeside;

  double _beside(double Function(RenderBox) of) {
    final lead = _leading, end = _end;
    return (lead == null ? 0 : of(lead) + _gap) +
        (end == null ? 0 : of(end) + _gap);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _beside((c) => c.getMaxIntrinsicWidth(height)) +
      _words.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _beside((c) => c.getMaxIntrinsicWidth(height)) +
      _words.getMaxIntrinsicWidth(height);

  double _height(double width, double Function(RenderBox, double) of) {
    final lead = _leading, end = _end;
    final glyphs = math.max(
      lead == null ? 0.0 : of(lead, double.infinity),
      end == null ? 0.0 : of(end, double.infinity),
    );
    if (_over(width)) return glyphs + _lines + of(_words, width);
    final room = math.max(
      0.0,
      width - _beside((c) => c.getMaxIntrinsicWidth(double.infinity)),
    );
    return math.max(glyphs, of(_words, room));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    Size lay(RenderBox child, BoxConstraints c) {
      if (dry) return child.getDryLayout(c);
      child.layout(c, parentUsesSize: true);
      return child.size;
    }

    final rtl = _textDirection == TextDirection.rtl;
    final lead = _leading, end = _end, words = _words;
    final loose = BoxConstraints(maxHeight: constraints.maxHeight);
    final leadSize = lead == null ? Size.zero : lay(lead, loose);
    final endSize = end == null ? Size.zero : lay(end, loose);
    final besides =
        (lead == null ? 0.0 : leadSize.width + _gap) +
        (end == null ? 0.0 : endSize.width + _gap);
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : besides + words.getMaxIntrinsicWidth(double.infinity);
    // Places [child], [w] wide, [x] from the row's start and [y] down.
    void place(RenderBox? child, double x, double y, double w) {
      if (dry || child == null) return;
      (child.parentData! as _RowLineData).offset = Offset(
        rtl ? width - x - w : x,
        y,
      );
    }

    if (_over(width)) {
      final line = math.max(leadSize.height, endSize.height);
      final wordsSize = lay(words, BoxConstraints.tightFor(width: width));
      final size = constraints.constrain(
        Size(width, line + _lines + wordsSize.height),
      );
      place(lead, 0, (line - leadSize.height) / 2, leadSize.width);
      place(
        end,
        width - endSize.width,
        (line - endSize.height) / 2,
        endSize.width,
      );
      place(words, 0, line + _lines, wordsSize.width);
      return size;
    }
    final room = math.max(0.0, width - besides);
    final wordsSize = lay(words, BoxConstraints.tightFor(width: room));
    final size = constraints.constrain(
      Size(
        width,
        math.max(wordsSize.height, math.max(leadSize.height, endSize.height)),
      ),
    );
    // Each stands on the line's middle, as a row's children do.
    double middle(Size s) => (size.height - s.height) / 2;
    place(lead, 0, middle(leadSize), leadSize.width);
    place(
      words,
      lead == null ? 0 : leadSize.width + _gap,
      middle(wordsSize),
      room,
    );
    place(end, width - endSize.width, middle(endSize), endSize.width);
    return size;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final words = _words;
    final b = words.getDistanceToActualBaseline(baseline);
    return b == null ? null : b + (words.parentData! as _RowLineData).offset.dy;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A row's title, its meta line and its status. Side by side (the title over
/// the meta line, the status at the end) only on a wide row where each line
/// of words fits beside the status on one line; otherwise the status stands on
/// its own line under the title, at the start, and the meta line under it, so
/// neither the title nor the meta line breaks for the status. A phone's rows
/// (narrower than [_RenderBeside._narrowest] at the text size) always stack,
/// every row of a list alike.
class _Beside extends MultiChildRenderObjectWidget {
  _Beside({
    required this.gap,
    required this.textScale,
    required Widget title,
    Widget? subtitle,
    Widget? status,
  }) : hasSubtitle = subtitle != null,
       hasStatus = status != null,
       super(children: [title, ?subtitle, ?status]);

  final double gap;
  final double textScale;
  final bool hasSubtitle;
  final bool hasStatus;

  @override
  _RenderBeside createRenderObject(BuildContext context) => _RenderBeside(
    gap,
    textScale,
    Directionality.of(context),
    hasSubtitle,
    hasStatus,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderBeside renderObject) {
    renderObject
      ..gap = gap
      ..textScale = textScale
      ..textDirection = Directionality.of(context)
      ..hasSubtitle = hasSubtitle
      ..hasStatus = hasStatus;
  }
}

class _BesideData extends ContainerBoxParentData<RenderBox> {}

class _RenderBeside extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BesideData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BesideData> {
  _RenderBeside(
    this._gap,
    this._textScale,
    this._textDirection,
    this._hasSubtitle,
    this._hasStatus,
  );

  /// The most of the row's width the status takes beside the words.
  static const double _share = 0.4;

  /// The narrowest row, in points at the body's own size, that stands its
  /// status beside the words: below it (a phone, a list pane) the status
  /// stands under the title, the same in every row of a list.
  static const double _narrowest = 440;

  /// Between the title and the meta line.
  static const double _lines = CivicSpacing.s4;

  /// Round the status when it stands under the title.
  static const double _round = CivicSpacing.s8;

  double _textScale;
  set textScale(double value) {
    if (value == _textScale) return;
    _textScale = value;
    markNeedsLayout();
  }

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

  bool _hasSubtitle;
  set hasSubtitle(bool value) {
    if (value == _hasSubtitle) return;
    _hasSubtitle = value;
    markNeedsLayout();
  }

  bool _hasStatus;
  set hasStatus(bool value) {
    if (value == _hasStatus) return;
    _hasStatus = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BesideData) child.parentData = _BesideData();
  }

  RenderBox get _title => firstChild!;
  RenderBox? get _sub => _hasSubtitle ? childAfter(firstChild!) : null;
  RenderBox? get _status => _hasStatus ? lastChild : null;

  double get _statusWidth =>
      _status?.getMaxIntrinsicWidth(double.infinity) ?? 0;

  /// Whether the status stands under the title in a row [width] wide.
  bool _stacks(double width) {
    if (_status == null || !width.isFinite) return false;
    if (width / _textScale < _narrowest) return true;
    final status = _statusWidth;
    if (status > width * _share) return true;
    final room = width - status - _gap;
    final sub = _sub;
    return _title.getMaxIntrinsicWidth(double.infinity) > room ||
        (sub != null && sub.getMaxIntrinsicWidth(double.infinity) > room);
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    math.max(
      _title.getMinIntrinsicWidth(height),
      _sub?.getMinIntrinsicWidth(height) ?? 0,
    ),
    _status?.getMinIntrinsicWidth(height) ?? 0,
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final words = math.max(
      _title.getMaxIntrinsicWidth(height),
      _sub?.getMaxIntrinsicWidth(height) ?? 0,
    );
    final status = _status;
    return words +
        (status == null ? 0 : _gap + status.getMaxIntrinsicWidth(height));
  }

  double _height(double width, double Function(RenderBox, double) of) {
    final sub = _sub;
    final status = _status;
    double words(double w) =>
        of(_title, w) + (sub == null ? 0 : _lines + of(sub, w));
    if (status == null) return words(width);
    if (!width.isFinite) return math.max(words(width), of(status, width));
    if (_stacks(width)) {
      return of(_title, width) +
          _round +
          of(status, width) +
          (sub == null ? 0 : _round + of(sub, width));
    }
    final beside = _statusWidth;
    return math.max(
      words(math.max(0, width - beside - _gap)),
      of(status, beside),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMaxIntrinsicHeight(w));

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    Size lay(RenderBox child, BoxConstraints c) {
      if (dry) return child.getDryLayout(c);
      child.layout(c, parentUsesSize: true);
      return child.size;
    }

    final rtl = _textDirection == TextDirection.rtl;
    // Places a child at [x] from the words' start, [y] down, in a box
    // [extent] wide.
    void place(RenderBox child, double x, double y, double w, double extent) {
      if (!dry) {
        (child.parentData! as _BesideData).offset = Offset(
          rtl ? extent - x - w : x,
          y,
        );
      }
    }

    final sub = _sub;
    final status = _status;
    final width = constraints.maxWidth;

    // The words (the title over the meta line), [room] wide, from [x];
    // returns their height.
    double words(double room, double x, double extent) {
      final title = lay(_title, BoxConstraints.tightFor(width: room));
      place(_title, x, 0, room, extent);
      if (sub == null) return title.height;
      final line = lay(sub, BoxConstraints.tightFor(width: room));
      place(sub, x, title.height + _lines, room, extent);
      return title.height + _lines + line.height;
    }

    if (status == null) {
      final room = width.isFinite
          ? width
          : math.max(
              _title.getMaxIntrinsicWidth(double.infinity),
              sub?.getMaxIntrinsicWidth(double.infinity) ?? 0,
            );
      return constraints.constrain(Size(room, words(room, 0, room)));
    }
    if (_stacks(width)) {
      final title = lay(_title, BoxConstraints.tightFor(width: width));
      place(_title, 0, 0, width, width);
      var y = title.height + _round;
      final end = lay(status, BoxConstraints(maxWidth: width));
      place(status, 0, y, end.width, width);
      y += end.height;
      if (sub != null) {
        y += _round;
        final line = lay(sub, BoxConstraints.tightFor(width: width));
        place(sub, 0, y, width, width);
        y += line.height;
      }
      return constraints.constrain(Size(width, y));
    }
    final end = lay(
      status,
      BoxConstraints(maxWidth: width.isFinite ? width * _share : _statusWidth),
    );
    final room = width.isFinite
        ? math.max(0.0, width - end.width - _gap)
        : math.max(
            _title.getMaxIntrinsicWidth(double.infinity),
            sub?.getMaxIntrinsicWidth(double.infinity) ?? 0,
          );
    final total = room + _gap + end.width;
    final high = words(room, 0, total);
    place(status, total - end.width, 0, end.width, total);
    return constraints.constrain(Size(total, math.max(high, end.height)));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
