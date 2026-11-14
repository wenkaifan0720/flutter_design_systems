/// Feedback — the banner (a card with actions), the tonal skeleton
/// placeholder, and the loading, error and empty screen states (CONTRACT
/// §4.1 `banner`, `skeleton`, `empty-state`; §4.2 loading/error/empty
/// states). Owner: w3-feedback.
///
/// Material 3 has no banner, skeleton or screen-state component in
/// Compose; these are patterns built from the system:
/// - the banner is a filled card (`FilledCardTokens`' container and
///   shape, or a tone's container role) holding an icon, a title and a
///   message, and text buttons (w3-buttons) for its actions;
/// - the skeleton is a tonal placeholder (`surfaceContainerHighest`) on
///   the shape scale that pulses on the slow effects spring, and holds
///   still under Reduce Motion;
/// - the screen states follow Cody v2's `InitialGenLoadingState`,
///   `InitialGenErrorState` and `InitialGenEmptyState` (centred, the
///   loading and error states announced as live regions): the loading
///   state is the contained loading indicator, the error and empty states
///   an icon, text and a tonal button.
library;

import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../internal/tokens/filled_card_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'buttons.dart';
import 'loading.dart';

// ---------------------------------------------------------------------------
// Banner
// ---------------------------------------------------------------------------

/// The tones a banner or a tag is drawn in: the container roles it wears,
/// its content in the matching `on…` role.
enum ExpressiveTone {
  /// `surfaceContainerHighest` under `onSurfaceVariant`: a kind, a status at
  /// rest, a note.
  neutral,

  /// The secondary container, as M3 draws what is chosen or new: news, a
  /// tip.
  primary,

  /// The error container: something failed, is overdue or needs fixing.
  error,

  /// The success container ([ExpressiveThemeData.status]): something passed
  /// or went well.
  success,

  /// The warning container ([ExpressiveThemeData.status]): something is due
  /// soon or needs a look before it fails.
  warning,
}

/// One of a banner's actions: a text button.
@immutable
class ExpressiveBannerAction {
  /// A banner action labelled [label] that runs [onPressed].
  const ExpressiveBannerAction(this.label, {required this.onPressed});

  /// The button's label.
  final String label;

  /// What a tap does.
  final VoidCallback? onPressed;
}

/// A banner: a card with an icon, a message and one or two actions, for a
/// prominent, persistent message the reader acts on or dismisses (offline,
/// a pending verification, an update).
///
/// ```dart
/// ExpressiveBanner(icon: ExpressiveSymbols.wifi, title: 'You are offline', message: 'Changes will sync when you reconnect.', actions: [ExpressiveBannerAction('Retry', onPressed: retry)])
/// ```
class ExpressiveBanner extends StatelessWidget {
  /// A banner showing [message] with the given [actions].
  const ExpressiveBanner({
    required this.message,
    this.title,
    this.icon,
    this.actions = const <ExpressiveBannerAction>[],
    this.tone = ExpressiveTone.neutral,
    this.style,
    super.key,
  });

  /// Stateful visual overrides before the banner theme.
  final ExpressiveComponentThemeData? style;

  /// The message.
  final String message;

  /// A title over the message, or none.
  final String? title;

  /// A leading glyph (one of [ExpressiveSymbols]), or none.
  final IconData? icon;

  /// Its actions, as text buttons along the bottom edge: `primary` on a
  /// neutral banner, the tone's content colour on a toned one.
  final List<ExpressiveBannerAction> actions;

  /// Its colouring.
  final ExpressiveTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final (container, content) = switch (tone) {
      ExpressiveTone.neutral => (
        c.role(FilledCardTokens.containerColor),
        c.onSurface,
      ),
      ExpressiveTone.primary => (c.secondaryContainer, c.onSecondaryContainer),
      ExpressiveTone.error => (c.errorContainer, c.onErrorContainer),
      ExpressiveTone.success => (
        t.status.success.container,
        t.status.success.onContainer,
      ),
      ExpressiveTone.warning => (
        t.status.warning.container,
        t.status.warning.onContainer,
      ),
    };
    final glyph = icon;
    final heading = title;
    final states = <WidgetState>{
      if (tone == ExpressiveTone.error) WidgetState.error,
    };
    final resolved = t.bannerTheme.merge(style);
    final ink = resolved.foregroundColor?.resolve(states) ?? content;
    final textStyle = resolved.textStyle?.resolve(states);
    return Semantics(
      container: true,
      child: ExpressiveSurface(
        style: style,
        componentStyle: t.bannerTheme,
        states: states,
        color: container,
        contentColor: ink,
        shape: t.shapes.of(FilledCardTokens.containerShape),
        padding: const EdgeInsetsDirectional.fromSTEB(
          ExpressiveSpacing.s16,
          ExpressiveSpacing.s16,
          ExpressiveSpacing.s16,
          ExpressiveSpacing.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (glyph != null) ...<Widget>[
                  ExpressiveIcon(
                    glyph,
                    size:
                        resolved.iconSize?.resolve(states) ??
                        ExpressiveSpacing.s24,
                    color: ink,
                  ),
                  const SizedBox(width: ExpressiveSpacing.s16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (heading != null) ...<Widget>[
                        Text(
                          heading,
                          style: t.type.titleMedium
                              .merge(textStyle)
                              .copyWith(color: ink),
                        ),
                        const SizedBox(height: ExpressiveSpacing.s4),
                      ],
                      Text(
                        message,
                        style: t.type.bodyMedium
                            .merge(textStyle)
                            .copyWith(
                              color:
                                  resolved.foregroundColor?.resolve(states) ??
                                  (tone == ExpressiveTone.neutral
                                      ? c.onSurfaceVariant
                                      : content),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actions.isEmpty)
              const SizedBox(height: ExpressiveSpacing.s8)
            else
              Padding(
                padding: const EdgeInsets.only(top: ExpressiveSpacing.s8),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: ExpressiveSpacing.s8,
                  children: <Widget>[
                    // A toned banner's actions are written in its content
                    // colour: `primary` keeps no contrast with the tone's
                    // container.
                    for (final action in actions)
                      ExpressiveTextButton(
                        action.label,
                        onPressed: action.onPressed,
                        child: tone == ExpressiveTone.neutral
                            ? null
                            : Text(action.label, style: TextStyle(color: ink)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton
// ---------------------------------------------------------------------------

/// A skeleton: the tonal shape of content still loading — a block, a
/// circle (an avatar) or lines of text — in the secondary container (the
/// look's tonal ground, not a grey), on Material's shape scale (a block on
/// the large corner, a line fully rounded), pulsing gently on the slow
/// effects spring until the content arrives (still under Reduce Motion). Screen readers skip it; announce
/// the wait with the page's loading state or a label.
///
/// ```dart
/// ExpressiveSkeleton.text(lines: 2)
/// ```
class ExpressiveSkeleton extends StatelessWidget {
  /// A block [width] × [height] (filling the width when [width] is null)
  /// with [corner] corners.
  const ExpressiveSkeleton({
    this.width,
    required this.height,
    this.corner = ExpressiveCorner.large,
    this.style,
    super.key,
  }) : lines = 0,
       circle = false,
       textStyle = null;

  /// A circle [size] across.
  const ExpressiveSkeleton.circle({required double size, this.style, super.key})
    : width = size,
      height = size,
      corner = ExpressiveCorner.full,
      lines = 0,
      circle = true,
      textStyle = null;

  /// [lines] lines of text in [textStyle] (body medium), the last one short.
  const ExpressiveSkeleton.text({
    this.lines = 3,
    this.textStyle,
    this.style,
    super.key,
  }) : assert(lines > 0),
       width = null,
       height = null,
       corner = ExpressiveCorner.full,
       circle = false;

  /// The skeleton's width, or the available width when null.
  final double? width;

  /// The skeleton's height.
  final double? height;

  /// The block's corner step.
  final ExpressiveCorner corner;

  /// How many lines of text; 0 for a block or a circle.
  final int lines;

  /// Whether it is a circle.
  final bool circle;

  /// The text style whose lines it stands in for.
  final TextStyle? textStyle;

  /// Stateful visual overrides for each placeholder shape.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final visual = t.skeletonTheme.merge(style);
    const states = <WidgetState>{};
    final shape =
        visual.shape?.resolve(states) ??
        (circle ? const CircleBorder() : t.shapes.corner(corner));
    Widget bone(double? w, double h) => SizedBox(
      width:
          w?.clamp(
            visual.minimumSize?.resolve(states)?.width ?? 0,
            double.infinity,
          ) ??
          double.infinity,
      height: h.clamp(
        visual.minimumSize?.resolve(states)?.height ?? 0,
        double.infinity,
      ),
      child: ExpressiveSurface(
        componentStyle: visual,
        shape: shape,
        color: t.colors.secondaryContainer,
        child: const SizedBox.expand(),
      ),
    );
    final Widget body;
    if (lines == 0) {
      body = bone(width, height!);
    } else {
      final text = (textStyle ?? t.type.bodyMedium).merge(
        visual.textStyle?.resolve(states),
      );
      final scaler = MediaQuery.textScalerOf(context);
      final size = scaler.scale(text.fontSize ?? ExpressiveSpacing.s14);
      final line = size * (text.height ?? 1);
      // Each bar sits in its line's box, the leading split above and below.
      final leading = (line - size) / 2;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < lines; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: leading),
              child: i == lines - 1 && lines > 1
                  ? FractionallySizedBox(
                      widthFactor: _lastLine,
                      child: bone(null, size),
                    )
                  : bone(null, size),
            ),
        ],
      );
    }
    return ExcludeSemantics(child: _Pulse(child: body));
  }

  /// How much of the width a paragraph's last line takes.
  static const _lastLine = 0.6;
}

/// Fades its child between full and [_dim] opacity and back on the slow
/// effects spring, for as long as it is shown; still under Reduce Motion.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  /// The opacity the pulse dips to.
  static const double _dim = 0.5;

  late final AnimationController _opacity = AnimationController(
    vsync: this,
    value: 1,
  );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = ExpressiveMotion.of(context);
    if (motion.reduceMotion) {
      _running = false;
      _opacity
        ..stop()
        ..value = 1;
    } else if (!_running) {
      _running = true;
      _swing(_dim);
    }
  }

  void _swing(double target) {
    if (!mounted || !_running) return;
    _opacity
        .springTo(target, ExpressiveMotion.of(context).slowEffects)
        .then((_) => _swing(target == 1 ? _dim : 1))
        .ignore();
  }

  @override
  void dispose() {
    _running = false;
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

// ---------------------------------------------------------------------------
// Screen states
// ---------------------------------------------------------------------------

/// The centred layout the screen states share: a glyph or indicator, a
/// title, an optional message and an optional action, 24dp in from the
/// edges; [announce] makes it a live region (loading and error).
class _CentredState extends StatelessWidget {
  const _CentredState({
    this.lead,
    required this.title,
    this.message,
    this.action,
    this.announce = false,
    this.style,
    this.states = const <WidgetState>{},
  });

  /// The glyph or indicator over the title; none when null.
  final Widget? lead;
  final String title;
  final String? message;
  final Widget? action;
  final bool announce;
  final ExpressiveComponentThemeData? style;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final text = message;
    final button = action;
    final visual = t.statusViewTheme.merge(style);
    final ink = visual.foregroundColor?.resolve(states);
    final typography = visual.textStyle?.resolve(states);
    return Semantics(
      container: true,
      liveRegion: announce,
      child: Center(
        child: ExpressiveSurface(
          componentStyle: visual,
          states: states,
          clipBehavior: visual.shape?.resolve(states) == null
              ? Clip.none
              : Clip.antiAlias,
          shape: t.shapes.none,
          color: expressiveTransparent,
          padding: const EdgeInsets.all(ExpressiveSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (lead case final lead?) ...<Widget>[
                lead,
                const SizedBox(height: ExpressiveSpacing.s16),
              ],
              _BalancedText(
                title,
                style: t.type.titleLarge
                    .merge(typography)
                    .copyWith(color: ink ?? t.colors.onSurface),
              ),
              if (text != null) ...<Widget>[
                const SizedBox(height: ExpressiveSpacing.s8),
                _BalancedText(
                  text,
                  style: t.type.bodyMedium
                      .merge(typography)
                      .copyWith(color: ink ?? t.colors.onSurfaceVariant),
                ),
              ],
              if (button != null) ...<Widget>[
                const SizedBox(height: ExpressiveSpacing.s24),
                button,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Centred text whose lines are balanced (CSS `text-wrap: balance`): set at
/// the narrowest width that keeps the line count the full width gives, so a
/// wrapped title or message never leaves one word alone on its last line.
class _BalancedText extends StatelessWidget {
  const _BalancedText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final plain = Text(text, textAlign: TextAlign.center, style: style);
      final full = constraints.maxWidth;
      if (!full.isFinite) return plain;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      );
      int lines(double width) {
        painter.layout(maxWidth: width);
        return painter.computeLineMetrics().length;
      }

      final count = lines(full);
      if (count < 2) {
        painter.dispose();
        return plain;
      }
      // Bisect for the narrowest width that still sets [count] lines.
      var narrow = 0.0;
      var wide = full;
      while (wide - narrow > 1) {
        final mid = (narrow + wide) / 2;
        if (lines(mid) > count) {
          narrow = mid;
        } else {
          wide = mid;
        }
      }
      painter.dispose();
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide.ceilToDouble()),
        child: plain,
      );
    },
  );
}

/// The page's loading state: the contained loading indicator over what is
/// loading, centred and announced — the render state of any page that
/// waits.
///
/// ```dart
/// ExpressiveScaffold(body: ExpressiveLoadingState(message: 'Loading plants'))
/// ```
class ExpressiveLoadingState extends StatelessWidget {
  /// A loading state showing [message] under the indicator, if given.
  const ExpressiveLoadingState({this.message, this.style, super.key});

  /// Stateful visual overrides for the screen-state panel.
  final ExpressiveComponentThemeData? style;

  /// What is loading (the strings' `loading` when null).
  final String? message;

  @override
  Widget build(BuildContext context) {
    final visual = context.expressiveTheme.statusViewTheme.merge(style);
    return _CentredState(
      style: style,
      lead: ExpressiveLoadingIndicator(
        contained: true,
        style: ExpressiveComponentThemeData(
          foregroundColor: visual.foregroundColor,
          iconSize: visual.iconSize,
        ),
      ),
      title: message ?? ExpressiveLocalizations.of(context).loading,
      announce: true,
    );
  }
}

/// The page's error state: an error glyph, what failed and why, and a
/// tonal retry — centred and announced; the render state of any page that
/// can fail. Where the page already shows a mark above it (a hero that
/// stays mounted through the error), [icon] null leaves the glyph out, so
/// the page keeps one focal shape.
///
/// ```dart
/// ExpressiveErrorState(title: 'Could not load', message: 'Check your connection', onRetry: reload)
/// ```
class ExpressiveErrorState extends StatelessWidget {
  /// An error state titled [title], with a retry button when [onRetry] is given.
  const ExpressiveErrorState({
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = ExpressiveSymbols.error,
    this.style,
    super.key,
  });

  /// Stateful visual overrides for the screen-state panel.
  final ExpressiveComponentThemeData? style;

  /// What failed.
  final String title;

  /// Why, or what to do; none when null.
  final String? message;

  /// Retries; no button when null.
  final VoidCallback? onRetry;

  /// The retry button's label.
  final String? retryLabel;

  /// The glyph (one of [ExpressiveSymbols]); none when null.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final retry = onRetry;
    final glyph = icon;
    return _CentredState(
      style: style,
      states: const <WidgetState>{WidgetState.error},
      lead: glyph == null
          ? null
          : ExpressiveIcon(
              glyph,
              size:
                  t.statusViewTheme.merge(style).iconSize?.resolve(
                    const <WidgetState>{WidgetState.error},
                  ) ??
                  ExpressiveSpacing.s48,
              color:
                  t.statusViewTheme.merge(style).foregroundColor?.resolve(
                    const <WidgetState>{WidgetState.error},
                  ) ??
                  t.colors.error,
            ),
      title: title,
      message: message,
      announce: true,
      action: retry == null
          ? null
          : LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ExpressiveFilledButton.tonal(
                  retryLabel ?? ExpressiveLocalizations.of(context).tryAgain,
                  icon:
                      constraints.maxWidth >=
                          ExpressiveSpacing.s72 + ExpressiveSpacing.s48
                      ? ExpressiveSymbols.refresh
                      : null,
                  onPressed: retry,
                ),
              ),
            ),
    );
  }
}

/// The page's empty state: a glyph on a round tonal ground, what is
/// missing, what to do about it and a tonal call to action — the render
/// state of any page that lists things.
///
/// ```dart
/// ExpressiveEmptyState(icon: ExpressiveSymbols.inbox, title: 'Nothing here yet', actionLabel: 'Add one', onAction: add)
/// ```
class ExpressiveEmptyState extends StatelessWidget {
  /// An empty state showing [icon] and [title], with a call to action when [actionLabel] and [onAction] are given.
  const ExpressiveEmptyState({
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.style,
    super.key,
  });

  /// Stateful visual overrides for the screen-state panel.
  final ExpressiveComponentThemeData? style;

  /// The glyph (one of [ExpressiveSymbols]).
  final IconData icon;

  /// What is missing.
  final String title;

  /// What to do about it; none when null.
  final String? body;

  /// The call to action's label; no button when null.
  final String? actionLabel;

  /// What the call to action does.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final label = actionLabel;
    return _CentredState(
      style: style,
      lead: SizedBox(
        width: ExpressiveSpacing.s72,
        height: ExpressiveSpacing.s72,
        child: ExpressiveSurface(
          color: t.colors.surfaceContainerHighest,
          shape: t.shapes.full,
          child: Center(
            child: ExpressiveIcon(
              icon,
              size:
                  t.statusViewTheme
                      .merge(style)
                      .iconSize
                      ?.resolve(const <WidgetState>{}) ??
                  ExpressiveSpacing.s32,
              color:
                  t.statusViewTheme
                      .merge(style)
                      .foregroundColor
                      ?.resolve(const <WidgetState>{}) ??
                  t.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: title,
      message: body,
      action: label == null
          ? null
          : ExpressiveFilledButton.tonal(label, onPressed: onAction),
    );
  }
}

/// The page's success state: a check on a round primary ground, what is
/// done, what follows from it and a tonal next step — centred and announced;
/// the render state a task ends on (a booking made, a payment sent). The
/// ground is `primaryContainer`, the theme's own: Expressive keeps no
/// success colour (CONTRACT §7).
///
/// ```dart
/// ExpressiveSuccessState(title: 'Table booked', message: 'We sent the details to your inbox.', actionLabel: 'Done', onAction: close)
/// ```
class ExpressiveSuccessState extends StatelessWidget {
  /// A success state saying [title].
  const ExpressiveSuccessState({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.icon = ExpressiveSymbols.check,
    this.style,
    super.key,
  });

  /// Stateful visual overrides for the screen-state panel.
  final ExpressiveComponentThemeData? style;

  /// What is done.
  final String title;

  /// What follows from it; none when null.
  final String? message;

  /// The next step's label; no button when null.
  final String? actionLabel;

  /// What the next step does.
  final VoidCallback? onAction;

  /// The glyph (one of [ExpressiveSymbols]).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final label = actionLabel;
    return _CentredState(
      style: style,
      lead: SizedBox(
        width: ExpressiveSpacing.s72,
        height: ExpressiveSpacing.s72,
        child: ExpressiveSurface(
          color: t.colors.primaryContainer,
          shape: t.shapes.full,
          child: Center(
            child: ExpressiveIcon(
              icon,
              size:
                  t.statusViewTheme
                      .merge(style)
                      .iconSize
                      ?.resolve(const <WidgetState>{}) ??
                  ExpressiveSpacing.s32,
              color:
                  t.statusViewTheme
                      .merge(style)
                      .foregroundColor
                      ?.resolve(const <WidgetState>{}) ??
                  t.colors.onPrimaryContainer,
            ),
          ),
        ),
      ),
      title: title,
      message: message,
      announce: true,
      action: label == null
          ? null
          : ExpressiveFilledButton.tonal(label, onPressed: onAction),
    );
  }
}

/// Which state an [ExpressiveStatusView] shows.
enum ExpressiveStatus {
  /// The content is on its way.
  loading,

  /// The content could not be had.
  error,

  /// What was asked is done.
  success,
}

/// One view for the three states a page passes through, centred where its
/// content stands and announced as it appears:
/// [ExpressiveStatusView.loading] (the contained loading indicator over
/// what is loading, as [ExpressiveLoadingState]),
/// [ExpressiveStatusView.error] (an error glyph, what failed and why, and a
/// tonal retry, as [ExpressiveErrorState]) and
/// [ExpressiveStatusView.success] (a check on a round `primaryContainer`
/// ground, what is done and a tonal next step, as [ExpressiveSuccessState]).
///
/// ```dart
/// ExpressiveStatusView.error(title: 'Could not load', message: 'Check your connection', onRetry: reload)
/// ```
class ExpressiveStatusView extends StatelessWidget {
  /// Loading: the indicator over [message] (the localized "Loading" when
  /// null).
  const ExpressiveStatusView.loading({this.message, this.style, super.key})
    : status = ExpressiveStatus.loading,
      title = null,
      onRetry = null,
      retryLabel = null,
      actionLabel = null,
      onAction = null,
      icon = null;

  /// Failed: [title], why in [message], and a retry when [onRetry] is set.
  /// [icon] null leaves the glyph out (a page whose hero stays mounted).
  const ExpressiveStatusView.error({
    required String this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = ExpressiveSymbols.error,
    this.style,
    super.key,
  }) : status = ExpressiveStatus.error,
       actionLabel = null,
       onAction = null;

  /// Done: [title], what follows in [message], and the next step when
  /// [actionLabel] and [onAction] are set.
  const ExpressiveStatusView.success({
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    IconData this.icon = ExpressiveSymbols.check,
    this.style,
    super.key,
  }) : status = ExpressiveStatus.success,
       onRetry = null,
       retryLabel = null;

  /// Which state it shows.
  final ExpressiveStatus status;

  /// What failed or what is done (error and success).
  final String? title;

  /// One sentence under the title; for loading, what is loading.
  final String? message;

  /// Retries (error).
  final VoidCallback? onRetry;

  /// The retry's label; the localized "Try again" when null (error).
  final String? retryLabel;

  /// The next step's label (success).
  final String? actionLabel;

  /// Takes the next step (success).
  final VoidCallback? onAction;

  /// The glyph (error and success).
  final IconData? icon;

  /// Overrides of the screen states' theme.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) => switch (status) {
    ExpressiveStatus.loading => ExpressiveLoadingState(
      message: message,
      style: style,
    ),
    ExpressiveStatus.error => ExpressiveErrorState(
      title: title!,
      message: message,
      onRetry: onRetry,
      retryLabel: retryLabel,
      icon: icon,
      style: style,
    ),
    ExpressiveStatus.success => ExpressiveSuccessState(
      title: title!,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon!,
      style: style,
    ),
  };
}
