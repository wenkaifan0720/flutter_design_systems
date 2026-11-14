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
/// the empty page's words stand on theirs. DERIVED: the source draws no
/// wait.
///
/// ```dart
/// LedgerLoadingState(message: 'Loading activity')
/// ```
class LedgerLoadingState extends StatelessWidget {
  /// A wait worded [message].
  const LedgerLoadingState({this.message, super.key});

  /// The words before the leader; null is the shared words' Loading
  /// ([DesignLocalizations.loadingLabel]).
  final String? message;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final message =
        this.message ?? DesignLocalizations.of(context).loadingLabel;
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
/// ([onRetryPressed]). DERIVED: the source draws no failure; it is the empty
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
  Widget build(BuildContext context) => _BlankPage(
    title: title,
    body: message,
    failed: true,
    act: onRetryPressed == null
        ? null
        : LedgerButton(
            'Try again',
            icon: LucideIcons.rotateCw,
            onPressed: onRetryPressed,
          ),
  );
}

/// What a page shows when it has nothing, as the source's empty search
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

/// The blank ledger page (`.empty.sheet`): a slip of raised paper ruled in
/// the hairline every 32, its double margin rule in the green rule at 18
/// and 22, padded clear of it; from 1024 ruled every 36, its rules at 28
/// and 32, padded 36 36 32 56, its title 44 on 46. The ruling breaks round
/// the words, the act and the stamp, each laid on the slip's own paper:
/// ink never lies over ink. A [failed] page rules its margin in the
/// vermilion.
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
    final titleStyle = wide
        ? t.title.sized(_titleWide).line(_titleLineWide)
        : t.title
              .sized(LedgerChromeMetrics.emptyTitle)
              .line(LedgerChromeMetrics.emptyTitleLine);
    Widget clear(Widget child, {BoxShape shape = BoxShape.rectangle}) =>
        DecoratedBox(
          decoration: BoxDecoration(color: t.surface, shape: shape),
          child: child,
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.cardRadius),
        boxShadow: t.paperShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.cardRadius),
        child: CustomPaint(
          painter: _Ruling(
            rtl: Directionality.of(context) == TextDirection.rtl,
            lines: t.hairline,
            margin: failed
                ? t.over.withValues(alpha: t.accentRule.a)
                : t.accentRule,
            pitch: wide ? _linesWide : LedgerChromeMetrics.emptyLines,
            rules: wide
                ? const (_ruleWide, _rule2Wide)
                : const (
                    LedgerChromeMetrics.emptyMarginRule,
                    LedgerChromeMetrics.emptyMarginRule2,
                  ),
          ),
          child: Padding(
            padding: wide
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
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (seal != null)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: clear(seal!, shape: BoxShape.circle),
                  ),
                if (seal != null)
                  const SizedBox(height: LedgerChromeMetrics.emptyTitleTop),
                clear(
                  Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: title),
                          if (titleItalic != null) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: titleItalic,
                              style: titleStyle.italic,
                            ),
                          ],
                        ],
                      ),
                      style: titleStyle,
                    ),
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: LedgerChromeMetrics.emptyBodyTop),
                  clear(
                    Text(
                      body!,
                      style: t.body
                          .line(LedgerChromeMetrics.emptyBodyLine)
                          .colored(t.textSecondary),
                    ),
                  ),
                ],
                if (act != null) ...[
                  const SizedBox(height: LedgerChromeMetrics.emptyActTop),
                  clear(act!),
                ],
              ],
            ),
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

/// The blank page's ruling: a 1 hairline at the foot of every [pitch] (32,
/// 36 on the desktop), and two 1 green [rules] down its start (18 and 22,
/// 28 and 32 on the desktop): its right in a right-to-left page ([rtl]).
class _Ruling extends CustomPainter {
  const _Ruling({
    required this.rtl,
    required this.lines,
    required this.margin,
    required this.pitch,
    required this.rules,
  });

  final bool rtl;
  final Color lines;
  final Color margin;
  final double pitch;
  final (double, double) rules;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()..color = lines;
    for (var y = pitch - 1; y < size.height; y += pitch) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), rule);
    }
    final green = Paint()..color = margin;
    for (final x in [rules.$1, rules.$2]) {
      canvas.drawRect(
        Rect.fromLTWH(rtl ? size.width - x - 1 : x, 0, 1, size.height),
        green,
      );
    }
  }

  @override
  bool shouldRepaint(_Ruling old) =>
      old.rtl != rtl ||
      old.lines != lines ||
      old.margin != margin ||
      old.pitch != pitch ||
      old.rules != rules;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = LedgerMotion.isReduced(context);
    if (still) {
      _draw
        ..stop()
        ..value = 1;
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
