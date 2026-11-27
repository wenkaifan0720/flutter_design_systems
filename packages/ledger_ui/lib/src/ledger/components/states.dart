import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/leader.dart';
import '../theme.dart';
import 'button/button.dart';
import 'seal/seal.dart';

/// What a page shows while its records come: its [message] in the mono
/// capitals, then a dot leader that draws itself in, dot by dot, like a
/// line waiting for its figure (standing whole when motion is reduced), on
/// its room's start where the first record will stand, as the error's and
/// the empty page's words stand on theirs.
///
/// ```dart
/// LedgerLoadingState(message: 'Loading activity')
/// ```
class LedgerLoadingState extends StatelessWidget {
  /// A wait worded [message].
  const LedgerLoadingState({this.message, super.key});

  /// The words before the leader; null is the shared words' Loading
  /// ([RawWidgetsLocalizations.loadingLabel]).
  final String? message;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final message =
        this.message ?? RawWidgetsLocalizations.of(context).loadingLabel;
    return Semantics(
      label: message,
      liveRegion: true,
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        // The leader stands on the capitals' baseline, as a row's does.
        child: Text.rich(
          TextSpan(
            text: message.toUpperCase(),
            children: const [
              WidgetSpan(
                alignment: PlaceholderAlignment.aboveBaseline,
                baseline: TextBaseline.alphabetic,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: LedgerChromeMetrics.leaderInset,
                  ),
                  child: _Leader(),
                ),
              ),
            ],
          ),
          style: t.meta,
        ),
      ),
    );
  }
}

/// What a page shows when its records could not be had: the blank ledger page
/// with the [title] in the serif, the [message] under it and Try again
/// ([onRetryPressed]): the empty
/// page's paper without its seal, its margin ruled in the vermilion (a state
/// is written).
///
/// ```dart
/// LedgerErrorState(title: 'Activity didn’t load', message: 'Check your connection and try again.', onRetryPressed: reload)
/// ```
class LedgerErrorState extends StatelessWidget {
  /// A failure titled [title], with its [message].
  const LedgerErrorState({
    required this.title,
    this.message,
    this.onRetryPressed,
    super.key,
  });

  /// What went wrong, in the serif.
  final String title;

  /// More of it, under the title.
  final String? message;

  /// Tries again; null draws no act.
  final VoidCallback? onRetryPressed;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(
        ObjectFlagProperty<VoidCallback>.has('onRetryPressed', onRetryPressed),
      );
  }

  @override
  Widget build(BuildContext context) => _BlankPage(
    title: title,
    body: message,
    failed: true,
    act: onRetryPressed == null
        ? null
        : LedgerButton(
            RawWidgetsLocalizations.of(context).retryButtonLabel,
            icon: LucideIcons.rotateCw,
            onPressed: onRetryPressed,
          ),
  );
}

/// What a page shows when it has nothing, as Ledger's empty search
/// draws it: a blank page of ledger paper (ruled every 32, its double green
/// margin rule down its start) stamped with the [seal] at its end, the
/// [title] in the serif at 32 ([titleItalic] after it in the italic), the
/// [body] in the second ink and the one act ([actionLabel], ringed in the
/// ink) that gets the person somewhere. From 1024 the page is the
/// desktop's: padded 36 36 32 56, ruled every 36, its
/// margin rules at 28 and 32, the title at 44 on 46.
///
/// ```dart
/// LedgerEmptyState(title: 'Nothing for', titleItalic: '“sushi”', body: 'Clear the filters to search all of it.', seal: const LedgerSeal(kicker: 'Search', value: 'No\nentries', foot: 'October', tone: LedgerSealTone.plain), actionLabel: 'Clear filters', actionIcon: LucideIcons.x, onActionPressed: clear)
/// ```
class LedgerEmptyState extends StatelessWidget {
  /// An empty page titled [title].
  const LedgerEmptyState({
    required this.title,
    this.titleItalic,
    this.body,
    this.seal,
    this.actionLabel,
    this.actionIcon,
    this.onActionPressed,
    this.actionKey,
    super.key,
  });

  /// What is not there, in the serif.
  final String title;

  /// Words set in the italic after the [title], a space between.
  final String? titleItalic;

  /// More of it, in the second ink.
  final String? body;

  /// The stamp at the page's top end.
  final LedgerSeal? seal;

  /// The act's words; null draws no act.
  final String? actionLabel;

  /// The act's glyph.
  final IconData? actionIcon;

  /// Called when the act is pressed.
  final VoidCallback? onActionPressed;

  /// The walkthrough key set on the act.
  final Key? actionKey;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('titleItalic', titleItalic, defaultValue: null))
      ..add(StringProperty('body', body, defaultValue: null))
      ..add(DiagnosticsProperty<LedgerSeal>('seal', seal, defaultValue: null))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<IconData>(
          'actionIcon',
          actionIcon,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onActionPressed',
          onActionPressed,
        ),
      )
      ..add(
        DiagnosticsProperty<Key>('actionKey', actionKey, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) => _BlankPage(
    title: title,
    titleItalic: titleItalic,
    body: body,
    seal: seal,
    act: actionLabel == null
        ? null
        : LedgerButton(
            actionLabel!,
            key: actionKey,
            icon: actionIcon,
            onPressed: onActionPressed,
          ),
  );
}

/// The blank ledger page: a slip of raised paper with its
/// double margin rule down its start (in the green rule at 18 and 22, in
/// the vermilion when [failed]) and its head left unruled, as a ledger
/// page's is. The [title] is written in the head, its last line on the
/// page's first rule; the ruling runs from there to the slip's foot, a
/// hairline every 32, and every other word stands on it: each line of the
/// [body] on the next rules, the [act]'s words on a rule clear of them, on
/// its own paper (ink never lies over ink). From 1024 it is the desktop's:
/// ruled every 36, its margin rules at 28 and 32, padded 36 36 32 56, its
/// title 44 on 46.
class _BlankPage extends StatelessWidget {
  const _BlankPage({
    required this.title,
    this.titleItalic,
    this.body,
    this.seal,
    this.act,
    this.failed = false,
  });

  final String title;
  final String? titleItalic;
  final String? body;
  final LedgerSeal? seal;
  final Widget? act;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final pitch = wide ? _linesWide : LedgerChromeMetrics.emptyLines;
    final titleStyle = wide
        ? t.title.sized(_titleWide).line(_titleLineWide)
        : t.title
              .sized(LedgerChromeMetrics.emptyTitle)
              .line(LedgerChromeMetrics.emptyTitleLine);
    // The body's lines the fewest whole rules apart that hold a line of its
    // face at the text size, so a larger size keeps to the ruling too.
    final bodySize = scaler.scale(t.body.fontSize!);
    final face = TextPainter(
      text: TextSpan(
        text: 'Hg',
        style: TextStyle(
          fontFamily: t.body.fontFamily,
          fontFamilyFallback: t.body.fontFamilyFallback,
          fontSize: t.body.fontSize,
        ),
      ),
      textScaler: scaler,
      textDirection: direction,
    )..layout();
    final bodyLine =
        pitch * math.max(1, (face.preferredLineHeight / pitch).ceil());
    face.dispose();
    final pad = wide
        ? const EdgeInsetsDirectional.fromSTEB(
            _startWide,
            _topWide,
            _endWide,
            _footWide,
          )
        : const EdgeInsetsDirectional.fromSTEB(
            LedgerChromeMetrics.emptyStart,
            LedgerChromeMetrics.emptyTop,
            LedgerChromeMetrics.emptyEnd,
            LedgerChromeMetrics.emptyFoot,
          );
    final act = this.act;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.cardRadius),
        boxShadow: t.paperShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.cardRadius),
        child: _RuledPage(
          pitch: pitch,
          rules: wide
              ? const (_ruleWide, _rule2Wide)
              : const (
                  LedgerChromeMetrics.emptyMarginRule,
                  LedgerChromeMetrics.emptyMarginRule2,
                ),
          padding: pad,
          titleLine: scaler.scale(titleStyle.fontSize!) * titleStyle.height!,
          bodyLine: bodyLine,
          lines: t.hairline,
          // One ink where the margin crosses the rules, as a printed
          // margin is: its wash laid on the paper first, never over a rule.
          margin: Color.alphaBlend(failed ? t.danger : t.accentRule, t.surface),
          textDirection: direction,
          seal: seal,
          title: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: title),
                  if (titleItalic != null) ...[
                    const TextSpan(text: ' '),
                    TextSpan(text: titleItalic, style: titleStyle.italic),
                  ],
                ],
              ),
              style: titleStyle,
            ),
          ),
          body: body == null
              ? null
              : Text(
                  body!,
                  style: t.body
                      .copyWith(height: bodyLine / bodySize)
                      .colored(t.textSecondary),
                ),
          // The act's own paper under its face: the rule its words stand
          // on stops at its edge.
          act: act == null
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(t.controlRadius),
                  ),
                  child: act,
                ),
        ),
      ),
    );
  }

  // The desktop's `.empty`: `padding: 36px 36px 32px
  // 56px`, `repeating-linear-gradient(180deg, transparent 0 35px, rule-2
  // 35px 36px)`, the green rules at 28-29 and 32-33; `.empty-t` 44px/46px.
  static const double _topWide = 36;
  static const double _endWide = 36;
  static const double _footWide = 32;
  static const double _startWide = 56;
  static const double _linesWide = 36;
  static const double _ruleWide = 28;
  static const double _rule2Wide = 32;
  static const double _titleWide = 44;
  static const double _titleLineWide = 46;
}

enum _Part { seal, title, body, act }

/// The blank page's paper, ruled and written: the [seal] at the head's end,
/// the [title]'s last line on the first rule, the [body]'s lines on the
/// rules after it ([bodyLine] apart, a whole number of rules) and the
/// [act]'s words on the first rule that leaves it clear of the words over
/// it. Rules every [pitch] from the first down, a 1 [lines] hairline under
/// each line's words, and the two [margin] rules down its start at [rules]
/// (its right in a right-to-left page).
class _RuledPage extends SlottedMultiChildRenderObjectWidget<_Part, RenderBox> {
  const _RuledPage({
    required this.pitch,
    required this.rules,
    required this.padding,
    required this.titleLine,
    required this.bodyLine,
    required this.lines,
    required this.margin,
    required this.textDirection,
    required this.title,
    this.seal,
    this.body,
    this.act,
  });

  final double pitch;
  final (double, double) rules;
  final EdgeInsetsDirectional padding;
  final double titleLine;
  final double bodyLine;
  final Color lines;
  final Color margin;
  final TextDirection textDirection;
  final Widget title;
  final Widget? seal;
  final Widget? body;
  final Widget? act;

  @override
  Iterable<_Part> get slots => _Part.values;

  @override
  Widget? childForSlot(_Part slot) => switch (slot) {
    _Part.seal => seal,
    _Part.title => title,
    _Part.body => body,
    _Part.act => act,
  };

  @override
  _RenderRuledPage createRenderObject(BuildContext context) =>
      _RenderRuledPage()..configure(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRuledPage renderObject,
  ) => renderObject.configure(this);
}

/// Where each part stands, and where the first rule runs.
typedef _Laid = ({
  Size size,
  double firstRule,
  Map<_Part, Offset> at,
  Map<_Part, BoxConstraints> constraints,
});

class _RenderRuledPage extends RenderBox
    with SlottedContainerRenderObjectMixin<_Part, RenderBox> {
  late double _pitch;
  late (double, double) _rules;
  late EdgeInsetsDirectional _padding;
  late double _titleLine;
  late double _bodyLine;
  late Color _lines;
  late Color _margin;
  late TextDirection _textDirection;
  double _firstRule = 0;

  void configure(_RuledPage page) {
    final relayout =
        !_isConfigured ||
        page.pitch != _pitch ||
        page.padding != _padding ||
        page.titleLine != _titleLine ||
        page.bodyLine != _bodyLine ||
        page.textDirection != _textDirection;
    final repaint =
        relayout ||
        page.rules != _rules ||
        page.lines != _lines ||
        page.margin != _margin;
    _isConfigured = true;
    _pitch = page.pitch;
    _rules = page.rules;
    _padding = page.padding;
    _titleLine = page.titleLine;
    _bodyLine = page.bodyLine;
    _lines = page.lines;
    _margin = page.margin;
    _textDirection = page.textDirection;
    if (relayout) {
      markNeedsLayout();
    } else if (repaint) {
      markNeedsPaint();
    }
  }

  bool _isConfigured = false;

  bool get _rtl => _textDirection == TextDirection.rtl;

  // The parts in paint and hit order.
  Iterable<(_Part, RenderBox)> get _parts sync* {
    for (final part in _Part.values) {
      final child = childForSlot(part);
      if (child != null) yield (part, child);
    }
  }

  _Laid _lay(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) layoutChild,
    double? Function(RenderBox, BoxConstraints) baselineOf,
  ) {
    final pad = _padding.resolve(_textDirection);
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : _widest() + pad.horizontal;
    final room = math.max(0.0, width - pad.horizontal);
    final at = <_Part, Offset>{};
    final given = <_Part, BoxConstraints>{};
    double start(double w) => _rtl ? width - pad.right - w : pad.left;
    var y = pad.top;
    var bottom = pad.top;

    final seal = childForSlot(_Part.seal);
    if (seal != null) {
      final c = BoxConstraints(maxWidth: room);
      final s = layoutChild(seal, c);
      given[_Part.seal] = c;
      at[_Part.seal] = Offset(_rtl ? pad.left : width - pad.right - s.width, y);
      y += s.height + LedgerChromeMetrics.emptyTitleTop;
    }

    // The title's last line on the first rule, the rule on a whole pixel.
    final title = childForSlot(_Part.title)!;
    final tc = BoxConstraints(maxWidth: room);
    final ts = layoutChild(title, tc);
    given[_Part.title] = tc;
    final tb = baselineOf(title, tc) ?? ts.height;
    final firstRule = (y + tb + _lastLineDrop(ts.height, _titleLine))
        .roundToDouble();
    at[_Part.title] = Offset(start(ts.width), y);
    bottom = y + ts.height;
    var written = firstRule;

    // Each later part on the first rule past the last words written, its
    // box clear of the box over it.
    void stand(_Part part, double clear, double line) {
      final child = childForSlot(part);
      if (child == null) return;
      final c = BoxConstraints(maxWidth: room);
      final s = layoutChild(child, c);
      given[part] = c;
      final b = baselineOf(child, c) ?? s.height;
      var rule = written + _pitch;
      while (rule - b < bottom + clear) {
        rule += _pitch;
      }
      at[part] = Offset(start(s.width), rule - b);
      bottom = rule - b + s.height;
      written = rule + _lastLineDrop(s.height, line);
    }

    stand(_Part.body, 0, _bodyLine);
    stand(_Part.act, _actClear, double.infinity);

    final tall = bottom + pad.bottom;
    final size = constraints.constrain(
      Size(
        width,
        constraints.hasBoundedHeight
            ? math.max(tall, constraints.maxHeight)
            : tall,
      ),
    );
    return (size: size, firstRule: firstRule, at: at, constraints: given);
  }

  // How far a block's last line stands under its first: its lines [line]
  // apart; a single line (or a part with no lines) none.
  static double _lastLineDrop(double height, double line) {
    if (!line.isFinite || line <= 0) return 0;
    final count = math.max(1, (height / line).round());
    return (count - 1) * line;
  }

  // The room between the act's face and the words over it.
  static const double _actClear = 12;

  double _widest() {
    var most = 0.0;
    for (final (_, child) in _parts) {
      most = math.max(most, child.getMaxIntrinsicWidth(double.infinity));
    }
    return most;
  }

  @override
  void performLayout() {
    final laid = _lay(
      constraints,
      ChildLayoutHelper.layoutChild,
      (child, _) =>
          child.getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true),
    );
    for (final (part, child) in _parts) {
      (child.parentData! as BoxParentData).offset = laid.at[part]!;
    }
    _firstRule = laid.firstRule;
    size = laid.size;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) => _lay(
    constraints,
    ChildLayoutHelper.dryLayoutChild,
    (child, c) => child.getDryBaseline(c, TextBaseline.alphabetic),
  ).size;

  @override
  double computeMinIntrinsicWidth(double height) {
    var most = 0.0;
    for (final (_, child) in _parts) {
      most = math.max(most, child.getMinIntrinsicWidth(double.infinity));
    }
    return most + _padding.horizontal;
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _widest() + _padding.horizontal;

  @override
  double computeMinIntrinsicHeight(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final title = childForSlot(_Part.title)!;
    final distance = title.getDistanceToActualBaseline(baseline);
    if (distance == null) return null;
    return distance + (title.parentData! as BoxParentData).offset.dy;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final rule = Paint()..color = _lines;
    for (var y = _firstRule; y < size.height; y += _pitch) {
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy + y, size.width, 1),
        rule,
      );
    }
    final margin = Paint()..color = _margin;
    for (final x in [_rules.$1, _rules.$2]) {
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + (_rtl ? size.width - x - 1 : x),
          offset.dy,
          1,
          size.height,
        ),
        margin,
      );
    }
    for (final (_, child) in _parts) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final (_, child) in _parts.toList().reversed) {
      final at = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: at,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}

/// The loading ring: a hairline circle with a quarter of it in the green,
/// turning (still when animation is off).
/// The loading leader: its dots drawn in one by one across
/// [LedgerChromeMetrics.loadingLeader], then again; whole when still.
class _Leader extends StatefulWidget {
  const _Leader();

  @override
  State<_Leader> createState() => _LeaderState();
}

class _LeaderState extends State<_Leader> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // Run from build: iOS's Reduce Motion comes as a build, never as
  // didChangeDependencies (LedgerMotion.isReduced).
  void _sync() {
    if (LedgerMotion.isReduced(context)) {
      if (_draw.isAnimating || _draw.value != 1) {
        _draw
          ..stop()
          ..value = 1;
      }
    } else if (!_draw.isAnimating) {
      _draw.repeat();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final t = context.ledgerTheme;
    return CustomPaint(
      size: const Size(
        LedgerChromeMetrics.loadingLeader,
        2 * LedgerChromeMetrics.leaderCentre,
      ),
      painter: _DrawnLeader(
        _draw,
        t.textSecondary,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
    );
  }
}

/// The leader's dots up to the [drawn] share of its length, in whole dots,
/// drawn on from the words: from its right in a right-to-left page ([rtl]).
class _DrawnLeader extends CustomPainter {
  _DrawnLeader(this.drawn, this.color, {required this.rtl})
    : super(repaint: drawn);

  final Animation<double> drawn;
  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    const pitch = LedgerChromeMetrics.leaderPitch;
    final dots = (size.width / pitch).floor();
    final shown = drawn.value >= 1 ? dots : (drawn.value * (dots + 1)).floor();
    if (shown <= 0) return;
    canvas.save();
    if (rtl) {
      // The dots stand on the leader's right, flush to the words.
      canvas
        ..translate(size.width - dots * pitch, 0)
        ..clipRect(
          Rect.fromLTWH((dots - shown) * pitch, 0, shown * pitch, size.height),
        );
    } else {
      canvas.clipRect(Rect.fromLTWH(0, 0, shown * pitch, size.height));
    }
    LedgerLeaderPainter(color).paint(canvas, Size(dots * pitch, size.height));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawnLeader old) =>
      old.drawn != drawn || old.color != color || old.rtl != rtl;
}
