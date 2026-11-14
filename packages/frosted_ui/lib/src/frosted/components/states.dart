import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../glyphs.dart';

import '../chrome_metrics.dart';
import '../internal/css_shadow.dart';
import '../internal/face.dart';
import '../theme.dart';
import 'button/button.dart';
import '../localizations.dart';

import 'package:ui_core/ui_core.dart';

/// What a page shows while its content loads (DERIVED, as the error state:
/// the source draws neither): a thin ring of the faint line with an ink arc
/// turning on it, over [message] in the quiet ink, centred where the
/// content will stand. Announced to a screen reader as a live region. The
/// arc holds still under Reduce Motion (`FrostedMotion.of`).
///
/// ```dart
/// FrostedLoadingState(message: 'Loading your accounts')
/// ```
class FrostedLoadingState extends StatelessWidget {
  /// Creates a [FrostedLoadingState].
  const FrostedLoadingState({this.message, super.key});

  /// The words under the ring.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final message =
        this.message ?? DesignLocalizations.of(context).loadingLabel;
    final t = context.frostedTheme;
    return _Centred(
      mark: const _Ring(),
      title: Text(
        message,
        textAlign: TextAlign.center,
        style: t.textTheme.titleMedium.c(t.colorScheme.textSecondary),
      ),
    );
  }
}

/// What a page shows when its content could not be reached: the over mark
/// on its tint, what went wrong in [title] (the h1 type) and one sentence
/// of help in [message], and the glass Try again when [onRetry] is given.
///
/// ```dart
/// FrostedErrorState(title: "Couldn't load your accounts", message: 'Check your connection, then try again.', onRetry: reload)
/// ```
class FrostedErrorState extends StatelessWidget {
  /// Creates a [FrostedErrorState].
  const FrostedErrorState({
    required this.title,
    this.message,
    this.onRetry,
    super.key,
  });

  /// What went wrong, in a few words.
  final String title;

  /// One sentence of help under it.
  final String? message;

  /// Retries; null draws no button.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    const d = FrostedChromeMetrics.stateMark;
    return _Centred(
      mark: SizedBox.square(
        dimension: d,
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(d / 2),
          color: t.colorScheme.overTint,
          child: Center(
            child: Icon(
              FrostedGlyphs.warning,
              size: FrostedChromeMetrics.stateMarkGlyph,
              color: t.colorScheme.over,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: t.textTheme.headlineSmall,
      ),
      message: message,
      action: onRetry == null
          ? null
          : FrostedButton.glass(
              FrostedLocalizations.of(context).tryAgain,
              icon: FrostedGlyphs.rotateCw,
              onPressed: onRetry,
            ),
    );
  }
}

/// Which of a [FrostedStatusView]'s three states it shows.
enum FrostedStatus {
  /// The content is on its way.
  loading,

  /// The content could not be reached.
  error,

  /// What was asked is done.
  success,
}

/// One view for the three states a page or a panel passes through, centred
/// where its content stands: [FrostedStatusView.loading] (the ring turning
/// over its words, as [FrostedLoadingState]), [FrostedStatusView.error]
/// (the over mark, what went wrong and Try again, as [FrostedErrorState])
/// and [FrostedStatusView.success] (the money-in green's round with a
/// check, what is done, and the next act). Each is announced as it appears.
///
/// ```dart
/// FrostedStatusView.loading(message: 'Loading your files')
/// ```
///
/// ```dart
/// FrostedStatusView.error(title: "Couldn't load your files", message: 'Check your connection, then try again.', onRetry: reload)
/// ```
///
/// ```dart
/// FrostedStatusView.success(title: 'Sent', message: 'Ines will see it in her inbox.', action: FrostedButton('Done', onPressed: close))
/// ```
class FrostedStatusView extends StatelessWidget {
  /// The content on its way: the turning ring over [message] (the
  /// localized "Loading" by default).
  const FrostedStatusView.loading({this.message, super.key})
    : status = FrostedStatus.loading,
      title = null,
      onRetry = null,
      action = null;

  /// The content out of reach: [title], one sentence of help in
  /// [message], and Try again when [onRetry] is given.
  const FrostedStatusView.error({
    required String this.title,
    this.message,
    this.onRetry,
    super.key,
  }) : status = FrostedStatus.error,
       action = null;

  /// Done: [title], one sentence in [message], and the next act in
  /// [action] (a [FrostedButton]).
  const FrostedStatusView.success({
    required String this.title,
    this.message,
    this.action,
    super.key,
  }) : status = FrostedStatus.success,
       onRetry = null;

  /// Which state it shows.
  final FrostedStatus status;

  /// What happened, in a few words (error and success).
  final String? title;

  /// One sentence under it; for loading, the words under the ring.
  final String? message;

  /// Retries (error).
  final VoidCallback? onRetry;

  /// The next act (success).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    switch (status) {
      case FrostedStatus.loading:
        return FrostedLoadingState(message: message);
      case FrostedStatus.error:
        return FrostedErrorState(
          title: title!,
          message: message,
          onRetry: onRetry,
        );
      case FrostedStatus.success:
        const d = FrostedChromeMetrics.stateMark;
        return _Centred(
          mark: SizedBox.square(
            dimension: d,
            child: FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(d / 2),
              color: t.colorScheme.moneyInTint,
              child: Center(
                child: Icon(
                  FrostedGlyphs.check,
                  size: FrostedChromeMetrics.stateMarkGlyph,
                  color: t.colorScheme.moneyIn,
                ),
              ),
            ),
          ),
          title: Text(
            title!,
            textAlign: TextAlign.center,
            style: t.textTheme.headlineSmall,
          ),
          message: message,
          action: action,
        );
    }
  }
}

/// What a list shows when nothing is in it, as the source's empty search
/// does (`.tile.glass-tile.empty`): a glass tile with the spectrum along
/// its top edge holding the prism (a beam of ink meeting a glass prism and
/// leaving it as four fans of colour), the [title] in the name type, one
/// [body] sentence in the quiet ink at most 300 wide (420 on the desktop),
/// and the one next act ([actionLabel], the ink button with its
/// [actionIcon]).
///
/// ```dart
/// FrostedEmptyState(title: 'No results for “sushi”', body: 'Only money that came in is searched while Money in is on.', actionLabel: 'Clear filters', actionIcon: FrostedGlyphs.close, onAction: clear)
/// ```
class FrostedEmptyState extends StatelessWidget {
  /// Creates a [FrostedEmptyState].
  const FrostedEmptyState({
    required this.title,
    this.body,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionKey,
    super.key,
  });

  /// The state's head.
  final String title;

  /// One sentence under the title.
  final String? body;

  /// The next act's word, its glyph, and what it does; no button without a
  /// word.
  final String? actionLabel;

  /// The act's glyph.
  final IconData? actionIcon;

  /// What the act does; null leaves no act.
  final VoidCallback? onAction;

  /// A key for the act, where a tap lands: an app's walk names it by it.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final radius = BorderRadius.circular(
      FrostedBreakpoints.tileRadius(context),
    );
    return Semantics(
      container: true,
      label: DesignLocalizations.of(context).noResultsLabel,
      explicitChildNodes: true,
      // .glass-tile { box-shadow: var(--edge), var(--lift) }: the edge a
      // ring just outside the glass, as a tile's, taking no room (a face's
      // edge stood the tile 2 taller, its words 1 low).
      child: FrostedFace(
        material: FrostedMaterial.pane,
        radius: radius,
        shadows: [
          frostedShadow(
            color: t.glass.edge,
            spread: FrostedChromeMetrics.outline,
          ),
          ...t.shadows.tile,
        ],
        clipChild: true,
        child: Stack(
          // The column takes the tile's width, so its parts stand centred
          // in it (`.empty { text-align: center }`), not at its start.
          fit: StackFit.passthrough,
          children: [
            // The spectrum along the tile's top edge (`.glass-tile`).
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: FrostedChromeMetrics.heroRim,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: t.glass.spectrumRim),
                ),
              ),
            ),
            Padding(
              padding: wide
                  ? FrostedChromeMetrics.emptyInsetWide
                  : FrostedChromeMetrics.emptyInset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FrostedSpectrumArt(wide: wide),
                  SizedBox(
                    height: wide
                        ? FrostedChromeMetrics.emptyGapWide +
                              FrostedChromeMetrics.emptyArtGapWide
                        : FrostedChromeMetrics.emptyGap +
                              FrostedChromeMetrics.emptyArtGap,
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: t.textTheme.headlineMedium.tracked(-0.025),
                  ),
                  if (body != null) ...[
                    SizedBox(
                      height: wide
                          ? FrostedChromeMetrics.emptyGapWide
                          : FrostedChromeMetrics.emptyGap,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wide
                            ? FrostedChromeMetrics.emptyWordsWidthWide
                            : FrostedChromeMetrics.emptyWordsWidth,
                      ),
                      child: Text(
                        body!,
                        textAlign: TextAlign.center,
                        style: t.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  if (actionLabel != null) ...[
                    SizedBox(
                      height:
                          (wide
                              ? FrostedChromeMetrics.emptyGapWide
                              : FrostedChromeMetrics.emptyGap) +
                          FrostedChromeMetrics.emptyWordsGap,
                    ),
                    FrostedButton(
                      actionLabel!,
                      key: actionKey,
                      icon: actionIcon,
                      onPressed: onAction,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty state's art, as the source draws it (`.empty-art`): a beam
/// of the ink from the left meeting a prism of glass edged in the
/// spectrum, and leaving it to the right as four fans of lilac, rose,
/// peach and mint on a wash of white; 220 by 120 on a phone, 330 by 180 at
/// desktop width ([wide] pins one), scaled down to the width it is given.
/// Decoration: it says nothing.
///
/// ```dart
/// FrostedSpectrumArt()
/// ```
class FrostedSpectrumArt extends StatelessWidget {
  /// Creates a [FrostedSpectrumArt].
  const FrostedSpectrumArt({this.wide, super.key});

  /// Pins the desktop's size (true) or the phone's (false); null follows
  /// the window.
  final bool? wide;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final field = (wide ?? FrostedBreakpoints.isWide(context))
        ? FrostedChromeMetrics.emptyArtWide
        : FrostedChromeMetrics.emptyArt;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = math.min(field.width, box.maxWidth);
          return SizedBox(
            width: w,
            height: field.height * w / field.width,
            child: CustomPaint(
              painter: _FrostedPainter(
                ink: t.colorScheme.textPrimary,
                glassFrom: t.isDark ? t.glass.plane : const Color(0xFFFFFFFF),
                glassTo: t.isDark
                    ? t.colorScheme.surfaceAlt
                    : const Color(0xFFEEEDF8),
                fan: t.isDark ? t.colorScheme.surface : const Color(0xFFFFFFFF),
                spectrum: t.glass.spectrumStops,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The source's drawing, in its 220 by 120 box.
class _FrostedPainter extends CustomPainter {
  const _FrostedPainter({
    required this.ink,
    required this.glassFrom,
    required this.glassTo,
    required this.fan,
    required this.spectrum,
  });

  final Color ink;
  final Color glassFrom;
  final Color glassTo;
  final Color fan;

  /// The rim's stops: the edge's four colours are its second to fifth.
  final List<Color> spectrum;

  static const double _w = 220;
  static const double _h = 120;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _w, size.height / _h);
    final lilac = spectrum[1];
    final rose = spectrum[2];
    final peach = spectrum[3];
    final mint = spectrum[4];
    // The beam: the ink from nothing at the left to a fifth at the prism.
    canvas.drawLine(
      const Offset(0, 66),
      const Offset(96, 62),
      Paint()
        ..shader = LinearGradient(
          colors: [ink.withValues(alpha: 0), ink.withValues(alpha: 0.22)],
        ).createShader(const Rect.fromLTWH(0, 0, 86, 1))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    // A fade that eases out, (1 - s)², with no slope where it ends: a
    // straight ramp to 0 leaves a line where it stops, and the rays and the
    // wash under them stopping on one line read as a cut (self-review
    // rounds 2, 4 and 5).
    List<Color> eased(Color c, double a) => [
      for (final m in const [1.0, .5625, .25, .0625, 0.0])
        c.withValues(alpha: a * m),
    ];
    // The four fans leaving the prism, gone before the art's edge.
    void tri(Color c, double a, List<Offset> p) => canvas.drawPath(
      Path()
        ..moveTo(p[0].dx, p[0].dy)
        ..lineTo(p[1].dx, p[1].dy)
        ..lineTo(p[2].dx, p[2].dy)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: eased(c, a),
          stops: const [0.15, 0.3, 0.45, 0.6, 0.75],
        ).createShader(const Rect.fromLTRB(132, 0, 220, 1)),
    );
    tri(lilac, 0.22, const [Offset(132, 58), Offset(220, 34), Offset(220, 52)]);
    tri(rose, 0.2, const [Offset(133, 62), Offset(220, 54), Offset(220, 70)]);
    tri(peach, 0.2, const [Offset(133, 66), Offset(220, 72), Offset(220, 88)]);
    tri(mint, 0.2, const [Offset(132, 70), Offset(220, 90), Offset(220, 106)]);
    // The wash of white the fans stand on.
    canvas.drawPath(
      Path()
        ..moveTo(128, 40)
        ..lineTo(220, 30)
        ..lineTo(220, 110)
        ..lineTo(128, 92)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          // Gone before the art's edge, and past the rays' end: by night
          // the wash (the surface, lighter than the night glass) ran out on
          // the edge, then on the rays' own line (self-review rounds 4, 5).
          colors: eased(fan, 0.9 * 0.6),
          stops: const [0, 0.22, 0.44, 0.66, 0.88],
        ).createShader(const Rect.fromLTWH(128, 0, 92, 1)),
    );
    // The prism: glass with its corners softened, edged in the spectrum.
    final prism = Path()
      ..moveTo(110, 14)
      ..lineTo(150, 102)
      ..quadraticBezierTo(151, 106, 147, 106)
      ..lineTo(73, 106)
      ..quadraticBezierTo(69, 106, 70, 102)
      ..close();
    canvas.drawPath(
      prism,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glassFrom.withValues(alpha: 0.95),
            glassTo.withValues(alpha: 0.7),
          ],
        ).createShader(const Rect.fromLTRB(80, 14, 150, 106)),
    );
    canvas.drawPath(
      prism,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lilac, rose, peach, mint],
          stops: const [0, 0.4, 0.7, 1],
        ).createShader(const Rect.fromLTRB(76, 16, 152, 104)),
    );
    // The highlight down its left face.
    canvas.drawLine(
      const Offset(110, 22),
      const Offset(118, 40),
      Paint()
        ..color = fan.withValues(alpha: 0.9)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrostedPainter old) =>
      old.ink != ink ||
      old.glassFrom != glassFrom ||
      old.glassTo != glassTo ||
      old.fan != fan ||
      old.spectrum != spectrum;
}

/// A state's mark over its words and its act, centred where the content
/// will stand.
class _Centred extends StatelessWidget {
  const _Centred({
    required this.mark,
    required this.title,
    this.message,
    this.action,
  });

  final Widget mark;
  final Widget title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: FrostedChromeMetrics.emptyInset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              mark,
              const SizedBox(height: FrostedSpacing.s16),
              title,
              if (message != null) ...<Widget>[
                const SizedBox(height: FrostedChromeMetrics.emptyGap),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: FrostedChromeMetrics.emptyWordsWidth,
                  ),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: t.textTheme.bodyMedium,
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(
                  height:
                      FrostedChromeMetrics.emptyGap +
                      FrostedChromeMetrics.emptyWordsGap,
                ),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin ring with an ink arc turning on it, once a second; still when
/// animation is off.
class _Ring extends StatefulWidget {
  const _Ring();

  @override
  State<_Ring> createState() => _RingState();
}

class _RingState extends State<_Ring> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!FrostedMotion.of(context).moves) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return RotationTransition(
      turns: _turn,
      child: CustomPaint(
        size: const Size.square(FrostedChromeMetrics.loadingRing),
        painter: _RingPainter(
          track: t.colorScheme.borderStrong,
          arc: t.colorScheme.textPrimary,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.track, required this.arc});

  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const w = FrostedChromeMetrics.loadingStroke;
    final rect = Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..color = arc
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.track != track || old.arc != arc;
}
