/// Gloss's feedback: the banner, a level plate glazed in its tone with a
/// sunken sign saying what kind of news it is; the state view (empty, error,
/// loading, done); the spinner, a gel drop running round a groove; and the
/// progress bar, gel filling a groove.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'surface.dart';
import 'theme.dart';

/// What kind of news a [GlossBanner] brings.
enum GlossBannerTone {
  /// Something to know: a smoke sign.
  info,

  /// Something done: a jade sign.
  success,

  /// Something to mind: an amber sign.
  warning,

  /// Something wrong: a ruby sign.
  danger,
}

/// The ink a tone's glyph and rim take, by day and by night.
Color _toneInk(GlossColors c, GlossBannerTone tone) => switch (tone) {
  GlossBannerTone.info => c.inkSecondary,
  GlossBannerTone.success => c.jadeInk,
  GlossBannerTone.warning =>
    c.brightness == Brightness.light
        ? const Color(0xFF8A5A00)
        : const Color(0xFFE9B85A),
  GlossBannerTone.danger => c.danger,
};

/// A sunken socket holding a status glyph: a sign is read, not pressed, so
/// it sinks into the surface (nothing stands up glossy that a finger does
/// not meet); its floor glows faintly in [ink], the glyph in it.
GlossFace _socket(GlossColors c, Color ink, {bool tinted = true}) {
  final well = GlossFace.well(c);
  if (!tinted) return well.copyWith(foreground: ink);
  final t = c.brightness == Brightness.light ? 0.10 : 0.16;
  return well.copyWith(
    top: Color.lerp(well.top, ink, t),
    middle: Color.lerp(well.middle, ink, t),
    bottom: Color.lerp(well.bottom, ink, t * 0.7),
    foreground: ink,
  );
}

GlossFace _toneBead(GlossColors c, GlossBannerTone tone) =>
    _socket(c, _toneInk(c, tone), tinted: tone != GlossBannerTone.info);

IconData _toneGlyph(GlossBannerTone tone) => switch (tone) {
  GlossBannerTone.info => LucideIcons.info,
  GlossBannerTone.success => LucideIcons.check,
  GlossBannerTone.warning => LucideIcons.triangleAlert,
  GlossBannerTone.danger => LucideIcons.circleAlert,
};

/// A banner: news that stays on the page until it is dealt with, on a
/// level porcelain plate glazed in its tone, a socket at its start holding
/// the tone's sign, and keys at its foot. A danger banner is announced as it appears.
///
/// ```dart
/// GlossBanner(title: 'Your week did not sync', message: 'Changes stay on this phone until it does.', tone: GlossBannerTone.danger, actions: [GlossButton('Try again', onPressed: () {})])
/// ```
class GlossBanner extends StatelessWidget {
  // The title's capitals stand level with the middle of the 32 bead beside
  // it: the label's line is 22 tall, so it drops 5.
  static const double _titleDrop = 5;

  /// A banner saying [title].
  const GlossBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = GlossBannerTone.info,
    this.icon,
    this.actions = const [],
    this.live,
    this.style,
  });

  /// The news.
  final String title;

  /// More about it.
  final String? message;

  /// What kind of news.
  final GlossBannerTone tone;

  /// The bead's glyph; null: the tone's.
  final Widget? icon;

  /// Keys at its foot.
  final List<Widget> actions;

  /// Whether a screen reader hears it as it appears; null: danger and
  /// warning banners are.
  final bool? live;

  /// Its own style, over [GlossThemeData.bannerStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.bannerStyle], const {});
    // A level porcelain plate (it holds news, it is not an object to lift),
    // glazed faintly in its tone, its rim in the tone too.
    final ink = _toneInk(c, tone);
    final porcelain = GlossFace.porcelain(c, radius: GlossMetrics.cardRadius);
    final glaze = tone == GlossBannerTone.info
        ? 0.0
        : c.brightness == Brightness.light
        ? 0.06
        : 0.07;
    var plate = porcelain.copyWith(
      lift: 0,
      top: Color.lerp(porcelain.top, ink, glaze * 0.6),
      middle: Color.lerp(porcelain.middle, ink, glaze),
      bottom: Color.lerp(porcelain.bottom, ink, glaze),
    );
    if (layered.fill != null) plate = plate.glazed(layered.fill!);
    final bead = _toneBead(c, tone);
    final speaks =
        live ??
        (tone == GlossBannerTone.danger || tone == GlossBannerTone.warning);
    return Semantics(
      container: true,
      liveRegion: speaks,
      child: GlossSurface(
        face: plate.copyWith(
          foreground: c.ink,
          edge: tone == GlossBannerTone.info
              ? null
              : ink.withValues(alpha: 0.4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GlossSpacing.regular),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 32,
                child: GlossSurface(
                  face: bead,
                  child: Center(
                    child: IconTheme.merge(
                      data: IconThemeData(size: 18, color: bead.foreground),
                      child: icon ?? Icon(_toneGlyph(tone)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: GlossSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: _titleDrop),
                      child: Text(
                        title,
                        style: theme.textTheme.label
                            .copyWith(color: c.ink)
                            .merge(layered.textStyle),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: GlossMetrics.lineGap),
                      Text(message!, style: theme.textTheme.secondary),
                    ],
                    if (actions.isNotEmpty) ...[
                      // Words-only actions carry their own room in their
                      // slot: they stand under the message as a line of it.
                      SizedBox(
                        height:
                            actions.every(
                              (a) => a is GlossButton && a.isWordsOnly,
                            )
                            ? 0
                            : GlossSpacing.medium,
                      ),
                      Wrap(
                        spacing: GlossSpacing.small,
                        runSpacing: GlossSpacing.small,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<GlossBannerTone>('tone', tone));
  }
}

/// What a [GlossStateView] says about a place.
enum GlossState {
  /// Nothing here yet.
  empty,

  /// It did not load.
  error,

  /// It is on its way.
  loading,

  /// It is done.
  success,
}

/// A whole place's state, in its middle: a large sunken socket holding its
/// sign (smoke when empty, ruby when wrong, jade when done, a spinner while
/// loading), what it means, and what to do.
///
/// ```dart
/// GlossStateView(state: GlossState.empty, title: 'No recipes yet', message: 'Save one and it lands here.')
/// ```
class GlossStateView extends StatelessWidget {
  /// A view of [state].
  const GlossStateView({
    super.key,
    required this.state,
    required this.title,
    this.message,
    this.icon,
    this.actions = const [],
  });

  /// The state.
  final GlossState state;

  /// What it means.
  final String title;

  /// More about it.
  final String? message;

  /// The bead's glyph; null: the state's.
  final Widget? icon;

  /// What to do: keys, the first the main one.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final bead = switch (state) {
      GlossState.empty => _socket(c, c.inkSecondary, tinted: false),
      GlossState.error => _socket(c, c.danger),
      GlossState.success => _socket(c, c.jadeInk),
      GlossState.loading => GlossFace.well(c),
    };
    final glyph = switch (state) {
      GlossState.empty => LucideIcons.inbox,
      GlossState.error => LucideIcons.cloudOff,
      GlossState.success => LucideIcons.check,
      GlossState.loading => LucideIcons.loader,
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Semantics(
          container: true,
          liveRegion: state == GlossState.error,
          child: Padding(
            padding: const EdgeInsets.all(GlossSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 72,
                  child: state == GlossState.loading
                      ? const Center(child: GlossSpinner(size: 40))
                      : GlossSurface(
                          face: bead,
                          child: Center(
                            child: IconTheme.merge(
                              data: IconThemeData(
                                size: 30,
                                color: bead.foreground,
                              ),
                              child: icon ?? Icon(glyph),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: GlossSpacing.regular),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.title,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: GlossSpacing.tight + 2),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.body.copyWith(color: c.inkSecondary),
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: GlossSpacing.large),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: GlossSpacing.small,
                    runSpacing: GlossSpacing.small,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<GlossState>('state', state))
      ..add(StringProperty('title', title));
  }
}

/// Ticks [builder] round once every [period] while motion is allowed; still
/// under Reduce Motion or when tickers are off.
class _Turning extends StatefulWidget {
  const _Turning({required this.period, required this.builder});

  final Duration period;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Turning> createState() => _TurningState();
}

class _TurningState extends State<_Turning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still || !TickerMode.valuesOf(context).enabled) {
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _turn,
    builder: (context, _) => widget.builder(context, _turn.value),
  );
}

/// A spinner: a jade gel drop running round a ring groove pressed into the
/// page. Under Reduce Motion it rests, a third of the way round.
///
/// ```dart
/// const GlossSpinner()
/// ```
class GlossSpinner extends StatelessWidget {
  /// A spinner [size] across.
  const GlossSpinner({super.key, this.size = 24, this.semanticLabel});

  /// Its width and height.
  final double size;

  /// What a screen reader says; null: the platform's word for loading.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    return Semantics(
      label: semanticLabel ?? RawWidgetsLocalizations.of(context).loadingLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: _Turning(
          period: const Duration(milliseconds: 1100),
          builder: (context, t) =>
              CustomPaint(painter: _RingPainter(c, t == 0 ? 0.33 : t)),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('size', size));
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.c, this.t);

  final GlossColors c;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final groove = math.max(3.0, s * 0.16);
    final centre = size.center(Offset.zero);
    final r = (s - groove) / 2;
    final ring = Rect.fromCircle(center: centre, radius: r);
    final light = c.brightness == Brightness.light;
    // The groove: one dark channel, in the rim's shade at its top and
    // catching the light toward its foot.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = groove
        // By night the channel's foot catches more light than the page,
        // so the ring reads on a dark page too.
        ..shader = ui.Gradient.linear(ring.topCenter, ring.bottomCenter, [
          Color.lerp(c.well, c.wellShade, light ? 0.35 : 0.5)!,
          light
              ? Color.lerp(c.well, c.lip, 0.45)!
              : Color.lerp(c.page, const Color(0xFFFFFFFF), 0.14)!,
        ]),
    );
    // The drop: a jade arc fading in from its tail, its head round and lit.
    // The arc's ends are cut square (a round cap at the tail would fall
    // outside the sweep and paint a bright nub); the head is drawn whole.
    final start = t * math.pi * 2 - math.pi / 2;
    const sweep = math.pi * 0.62;
    // By night the gel's lit top, so the drop stands out of the dark ring.
    final drop = light ? c.jade : c.jadeTop;
    final width = groove * 0.82;
    canvas.drawArc(
      ring,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = SweepGradient(
          endAngle: sweep,
          transform: GradientRotation(start),
          colors: [drop.withValues(alpha: 0), drop, drop],
          stops: const [0, 0.7, 1],
        ).createShader(ring),
    );
    // The head: round, whole, in the drop's own colour (a highlight dot on
    // so small a bead reads as a speck beside it).
    final head =
        centre + Offset(math.cos(start + sweep), math.sin(start + sweep)) * r;
    canvas.drawCircle(head, width / 2, Paint()..color = drop);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t || old.c != c;
}

/// A progress bar: jade gel filling a groove pressed into the page, its
/// sheen along the top. With no [value] a slug of gel slides along it.
///
/// ```dart
/// const GlossProgressBar(value: 0.4)
/// ```
class GlossProgressBar extends StatelessWidget {
  /// A bar at [value] (0 to 1); null: under way, how far unknown.
  const GlossProgressBar({
    super.key,
    this.value,
    this.semanticLabel,
    this.height = 12,
    this.style,
  });

  /// How far, 0 to 1; null: unknown.
  final double? value;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its height.
  final double height;

  /// Its own style, over [GlossThemeData.progressStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.progressStyle], const {});
    var gel = GlossFace.gel(c).copyWith(lift: 0, lens: 0.65);
    if (layered.fill != null) gel = gel.glazed(layered.fill!);
    final known = value?.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel ?? RawWidgetsLocalizations.of(context).loadingLabel,
      value: known == null ? null : '${(known * 100).round()}%',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: GlossSurface(
          face: GlossFace.well(c),
          child: Padding(
            padding: const EdgeInsets.all(GlossMetrics.rimRoom),
            child: known != null
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: known),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => FractionallySizedBox(
                        widthFactor: t,
                        heightFactor: 1,
                        child: t <= 0.001 ? null : GlossSurface(face: gel),
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, box) => _Turning(
                      period: const Duration(milliseconds: 1500),
                      builder: (context, t) {
                        final slug = box.maxWidth * 0.32;
                        final eased = Curves.easeInOutCubic.transform(
                          t == 0 ? 0.35 : t,
                        );
                        final x = -slug + (box.maxWidth + slug) * eased;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(height),
                          child: Stack(
                            children: [
                              PositionedDirectional(
                                start: x,
                                top: 0,
                                bottom: 0,
                                width: slug,
                                child: GlossSurface(face: gel),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('value', value, defaultValue: null));
  }
}
