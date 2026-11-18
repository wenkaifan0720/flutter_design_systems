import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/option.dart';
import '../../internal/paint.dart';
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
    this.style,
    this.focusNode,
  });

  /// What it is.
  final Widget title;

  /// What else to know, under the title.
  final Widget? subtitle;

  /// A glyph before the words.
  final Widget? leading;

  /// A status at the end.
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
    Widget body(Set<WidgetState> states, double focus) {
      final so = DesignStyleOf([style, t.listRowStyle], states);
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
          child: Row(
            spacing: CivicSpacing.s12,
            children: [
              if (lead != null)
                IconTheme.merge(
                  data: IconThemeData(
                    color: Color.lerp(t.action, t.onFocus, focus),
                    size: 24,
                  ),
                  child: lead,
                ),
              Expanded(
                child: _Beside(
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
              if (acts && showChevron)
                Transform.flip(
                  flipX: rtl && endIcon == null,
                  child: Icon(
                    endIcon ?? LucideIcons.chevronRight,
                    size: 24,
                    applyTextScaling: true,
                    color: Color.lerp(t.action, t.onFocus, focus),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final row = !acts
        ? MergeSemantics(child: body(const {}, 0))
        : DesignPressable(
            onPressed: onTap,
            focusNode: focusNode,
            semanticLabel: semanticLabel,
            excludeSemantics: semanticLabel != null,
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
                  : states.contains(WidgetState.hovered)
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
/// rows from their words' start; a [title] over it, outside the card, says
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
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
      child: ColoredBox(
        color: t.background,
        child: _GroupScope(
          child: CivicCardScope(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: CivicSpacing.s16,
                      ),
                      child: SizedBox(
                        height: 1,
                        child: ColoredBox(color: t.hairline),
                      ),
                    ),
                  child,
                ],
              ],
            ),
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

/// Says to the rows under it that they stand in a [CivicListGroup].
class _GroupScope extends InheritedWidget {
  const _GroupScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GroupScope>() != null;

  @override
  bool updateShouldNotify(_GroupScope oldWidget) => false;
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
