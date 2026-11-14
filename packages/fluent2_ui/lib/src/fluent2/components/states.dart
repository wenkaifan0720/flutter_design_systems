import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../icons.dart';
import '../internal/icon_fill.dart';
import '../internal/well.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button/button.dart';
import 'feedback/spinner.dart';

import 'package:ui_core/ui_core.dart';

/// What a page shows while its content loads: Fluent's medium spinner
/// with its [message] under it, centred in the room it has.
///
/// ```dart
/// Fluent2LoadingState(message: 'Loading files')
/// ```
class Fluent2LoadingState extends StatelessWidget {
  /// A spinner over [message], centred in its space.
  const Fluent2LoadingState({this.message, super.key});

  /// The words under the spinner; null is "Loading" in the app's language.
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Fluent2Spacing.xxl),
      child: Fluent2Spinner(
        label: message ?? DesignLocalizations.of(context).loadingLabel,
      ),
    ),
  );
}

/// The parts of a state, centred: the glyph (48, filled) on its tint's
/// disc (88 across), the title in subtitle1 16 under it, the words in body1 and the second ink 4 under that, the
/// act 20 under them; at most 360 wide. Plumbing of the states.
class _Centred extends StatelessWidget {
  const _Centred({
    required this.glyph,
    required this.glyphColor,
    required this.disc,
    required this.title,
    this.body,
    this.act,
  });

  final IconData glyph;
  final Color glyphColor;
  final Color disc;
  final String title;
  final String? body;
  final Widget? act;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Fluent2Spacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: Fluent2ChromeMetrics.stateWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: _disc,
                  height: _disc,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: disc,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    fluent2Filled(glyph),
                    size: Fluent2ChromeMetrics.stateGlyph,
                    color: glyphColor,
                  ),
                ),
              ),
              const SizedBox(height: Fluent2ChromeMetrics.stateGap),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: t.subtitle1,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: Fluent2Spacing.xs),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: t.body1.c(t.textSecondary),
                ),
              ],
              if (act != null) ...[
                const SizedBox(height: Fluent2Spacing.xl),
                act!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// What a page shows when its content failed to load: the error glyph in
/// the danger ink on the danger tint's disc, the [title], the [message] and, with [onRetry], the
/// Try again button.
///
/// ```dart
/// Fluent2ErrorState(title: "Couldn't load your files", message: 'Check your connection, then try again.', onRetry: reload)
/// ```
class Fluent2ErrorState extends StatelessWidget {
  /// An error state: [title], its [message], and a retry when [onRetry] is set.
  const Fluent2ErrorState({
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  /// What went wrong, in a line.
  final String title;

  /// What to do about it; null shows no line.
  final String? message;

  /// Called by the retry button; null shows none.
  final VoidCallback? onRetry;

  /// The retry's words; null is "Try again" in the app's language.
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final retry = onRetry;
    return _Centred(
      glyph: Fluent2Icons.errorCircle,
      glyphColor: t.danger,
      disc: t.colors.statusDangerBackground1,
      title: title,
      body: message,
      act: retry == null
          ? null
          : Fluent2Button(
              retryLabel ?? Fluent2Localizations.of(context).tryAgain,
              icon: Fluent2Icons.arrowClockwise,
              onPressed: retry,
            ),
    );
  }
}

/// How a [Fluent2StatusView] stands.
enum Fluent2StatusKind {
  /// Still working.
  loading,

  /// It failed.
  error,

  /// It worked.
  success,
}

/// The shared name for a page's loading, error and success states: Fluent's
/// spinner, or the status glyph over the [title], the [message] and one act.
///
/// ```dart
/// Fluent2StatusView.success(title: 'Invitation sent', message: 'Sam will get an email.')
/// ```
class Fluent2StatusView extends StatelessWidget {
  /// A status of [kind].
  const Fluent2StatusView({
    super.key,
    required this.kind,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Still working, saying [message].
  const Fluent2StatusView.loading({super.key, this.message})
    : kind = Fluent2StatusKind.loading,
      title = null,
      actionLabel = null,
      onAction = null;

  /// It failed; [onAction] tries again.
  const Fluent2StatusView.error({
    super.key,
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : kind = Fluent2StatusKind.error;

  /// It worked; [onAction] is what's next.
  const Fluent2StatusView.success({
    super.key,
    required String this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : kind = Fluent2StatusKind.success;

  /// How it stands.
  final Fluent2StatusKind kind;

  /// What happened.
  final String? title;

  /// More about it.
  final String? message;

  /// The act's words; null is the error's "Try again".
  final String? actionLabel;

  /// What the act does; null draws no act.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final words = Fluent2Localizations.of(context);
    final act = onAction;
    switch (kind) {
      case Fluent2StatusKind.loading:
        return Fluent2LoadingState(
          message: message ?? DesignLocalizations.of(context).loadingLabel,
        );
      case Fluent2StatusKind.error:
        return Fluent2ErrorState(
          title: title ?? '',
          message: message,
          onRetry: act,
          retryLabel: actionLabel ?? words.tryAgain,
        );
      case Fluent2StatusKind.success:
        return _Centred(
          glyph: Fluent2Icons.checkmarkCircle,
          glyphColor: t.colors.statusSuccessForeground1,
          disc: t.colors.statusSuccessBackground1,
          title: title ?? '',
          body: message,
          act: act == null || actionLabel == null
              ? null
              : Fluent2Button(actionLabel!, onPressed: act),
        );
    }
  }
}

/// What a page shows when it has nothing to show yet: the glyph of what it
/// holds, filled in the brand's ink on a soft brand disc, as Fluent's apps
/// open an empty view, the [title], the [body] and, with [onAction],
/// one primary act (Upload a file, Clear filters).
///
/// ```dart
/// Fluent2EmptyState(title: 'No files yet', body: 'Files you upload or share appear here.', icon: Fluent2Icons.folder, actionLabel: 'Upload', actionIcon: Fluent2Icons.arrowUpload, onAction: upload)
/// ```
class Fluent2EmptyState extends StatelessWidget {
  /// An empty state: [icon] over [title] and [body], with an act when
  /// [onAction] is set.
  const Fluent2EmptyState({
    required this.title,
    this.body,
    this.icon = Fluent2Icons.documentText,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionKey,
    super.key,
  });

  /// What is empty, in a line.
  final String title;

  /// What would fill it; null shows no line.
  final String? body;

  /// The glyph over [title].
  final IconData icon;

  /// The act's words; null shows no act.
  final String? actionLabel;

  /// The act's glyph; null shows none.
  final IconData? actionIcon;

  /// Called by the act; null shows no act.
  final VoidCallback? onAction;

  /// The act button's key, for tests and tours.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final label = actionLabel;
    return _Centred(
      glyph: icon,
      glyphColor: t.colors.brandForeground2,
      disc: fluent2BrandWell(t),
      title: title,
      body: body,
      act: label == null
          ? null
          : Fluent2Button(
              label,
              key: actionKey,
              icon: actionIcon,
              appearance: Fluent2ButtonAppearance.primary,
              onPressed: onAction,
            ),
    );
  }
}

/// The disc a state's glyph stands on.
const double _disc = 88;
