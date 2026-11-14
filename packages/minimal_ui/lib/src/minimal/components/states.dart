import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';

/// Minimal's three render states for a page that waits, fails or has
/// nothing to show. They share one centred, announced layout: the bare
/// glyph in its ink, a 15 px title, a quiet line, and at most one action
/// as a small bordered button — a status report in type, not an
/// illustration, with nothing drawn around the glyph.

/// The centred, screen-reader-announced loading state — the loading render
/// state for any page that waits. Its glyph turns while motion runs (still
/// under [MinimalMotionContext.minimalStill], so tests and goldens settle), and
/// as
/// a screen's whole body it stands in the middle of the page.
///
/// ```dart
/// MinimalScaffold(body: MinimalLoadingState(message: 'Loading habits'))
/// ```
class MinimalLoadingState extends StatelessWidget {
  /// A page's loading state, saying [message].
  const MinimalLoadingState({this.message, super.key});

  /// The line under the spinner; null says the localized "Loading".
  final String? message;

  @override
  Widget build(BuildContext context) => _CenteredState(
    icon: LucideIcons.loaderCircle,
    spin: true,
    title: message ?? MinimalLocalizations.of(context).loading,
  );
}

/// The centred, screen-reader-announced error state with an optional retry
/// — the error render state for any page that can fail.
///
/// ```dart
/// MinimalErrorState(title: 'Could not sync', message: 'Check your connection and try again.', onRetry: reload)
/// ```
class MinimalErrorState extends StatelessWidget {
  /// A page's error state, saying [title].
  const MinimalErrorState({
    required this.title,
    this.message,
    this.onRetry,
    super.key,
  });

  /// What went wrong.
  final String title;

  /// What to do about it.
  final String? message;

  /// Tries again: a Retry button; null hides it.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _CenteredState(
    icon: LucideIcons.circleAlert,
    destructive: true,
    title: title,
    message: message,
    action: onRetry == null
        ? null
        : MinimalButton(
            MinimalLocalizations.of(context).tryAgain,
            icon: LucideIcons.rotateCw,
            variant: MinimalButtonVariant.secondary,
            size: MinimalButtonSize.small,
            onPressed: onRetry,
          ),
  );
}

/// The centred empty state with an optional call to action — the empty
/// render state for any page that lists things.
///
/// ```dart
/// MinimalEmptyState(icon: LucideIcons.inbox, title: 'No habits yet', body: 'Habits you add show up here.', actionLabel: 'New habit', onAction: add)
/// ```
class MinimalEmptyState extends StatelessWidget {
  /// A page's empty state, saying [title].
  const MinimalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  /// Its glyph.
  final IconData icon;

  /// What is empty.
  final String title;

  /// What fills it.
  final String? body;

  /// What its button says.
  final String? actionLabel;

  /// Its button's press; null hides the button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _CenteredState(
    icon: icon,
    title: title,
    message: body,
    action: actionLabel == null
        ? null
        : MinimalButton(
            actionLabel!,
            variant: MinimalButtonVariant.secondary,
            size: MinimalButtonSize.small,
            onPressed: onAction,
          ),
  );
}

/// What a [MinimalStatusView] reports.
enum MinimalStatusKind {
  /// Waiting for something.
  loading,

  /// Something failed.
  error,

  /// Something finished.
  success,

  /// Nothing here yet.
  empty,
}

/// One of a page's render states by name — waiting, failed, done or
/// empty — in the shared centred, announced layout: the bare glyph in its
/// ink, a 15 px title, a quiet line and at most one action.
/// The named constructors are the four; [MinimalLoadingState],
/// [MinimalErrorState] and [MinimalEmptyState] are the same views by
/// their older names.
///
/// ```dart
/// MinimalStatusView.success(title: 'Invite sent', message: 'Ana will get an email in a minute.', actionLabel: 'Done', onAction: close)
/// ```
class MinimalStatusView extends StatelessWidget {
  /// The loading state.
  const MinimalStatusView.loading({super.key, this.title})
    : status = MinimalStatusKind.loading,
      message = null,
      icon = null,
      actionLabel = null,
      onAction = null;

  /// The error state.
  const MinimalStatusView.error({
    super.key,
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : status = MinimalStatusKind.error,
       icon = null;

  /// The done state.
  const MinimalStatusView.success({
    super.key,
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : status = MinimalStatusKind.success,
       icon = null;

  /// The empty state.
  const MinimalStatusView.empty({
    super.key,
    required String this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  }) : status = MinimalStatusKind.empty;

  /// Which of the four it is.
  final MinimalStatusKind status;

  /// The title; a loading view's null says the localized "Loading".
  final String? title;

  /// A line under its title.
  final String? message;

  /// An empty view's glyph; null takes an inbox.
  final IconData? icon;

  /// The one action's words; an error's null with [onAction] says "Try
  /// again".
  final String? actionLabel;

  /// Its button's press; null hides the button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l = MinimalLocalizations.of(context);
    final act = onAction;
    final words =
        actionLabel ?? (status == MinimalStatusKind.error ? l.tryAgain : null);
    return _CenteredState(
      icon: switch (status) {
        MinimalStatusKind.loading => LucideIcons.loaderCircle,
        MinimalStatusKind.error => LucideIcons.circleAlert,
        MinimalStatusKind.success => LucideIcons.circleCheck,
        MinimalStatusKind.empty => icon ?? LucideIcons.inbox,
      },
      spin: status == MinimalStatusKind.loading,
      destructive: status == MinimalStatusKind.error,
      success: status == MinimalStatusKind.success,
      title: title ?? l.loading,
      message: message,
      action: act == null || words == null
          ? null
          : MinimalButton(
              words,
              icon: status == MinimalStatusKind.error
                  ? LucideIcons.rotateCw
                  : null,
              variant: MinimalButtonVariant.secondary,
              size: MinimalButtonSize.small,
              onPressed: act,
            ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.destructive = false,
    this.success = false,
    this.spin = false,
  });

  final IconData icon;
  final bool spin;
  final String title;
  final String? message;
  final Widget? action;
  final bool destructive;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final glyph = MinimalIcon(
      icon,
      size: MinimalIconSize.i24,
      color: destructive
          ? t.destructiveInk
          : success
          ? t.successInk
          : t.mutedForeground,
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: MinimalInsets.all24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (spin) _Spin(child: glyph) else glyph,
              const MinimalGap(MinimalSpacing.s12),
              Text(title, textAlign: TextAlign.center, style: t.h3),
              if (message != null) ...<Widget>[
                const MinimalGap(MinimalSpacing.s4),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: MinimalChromeMetrics.stateMeasure,
                  ),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: t.bodySmall.c(t.mutedForeground),
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const MinimalGap(MinimalSpacing.s16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One turn a second, the way a loader glyph is read: a spinner standing
/// still reads as a stuck app. It stands at rest — the frame it starts from —
/// while [MinimalMotionContext.minimalStill] holds (tests, goldens, reduced
/// motion).
class _Spin extends StatefulWidget {
  const _Spin({required this.child});

  final Widget child;

  @override
  State<_Spin> createState() => _SpinState();
}

class _SpinState extends State<_Spin> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.minimalStill) {
      _turn.value = 0;
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
  Widget build(BuildContext context) =>
      RotationTransition(turns: _turn, child: widget.child);
}
