import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';
import '../button/button.dart';
import '../empty-state/empty_state.dart';

/// What a page shows while its content is on its way: the word "Loading"
/// in the reader's language (or [label]), said once by a screen reader as
/// it appears. Nothing spins: the words say it, and nothing moves for a
/// reader who asked for less motion.
///
/// ```dart
/// data.when(
///   loading: () => const CivicLoadingState(),
///   error: (error, _) => CivicErrorState(title: 'Sorry, there is a problem', message: '$error'),
///   data: (permits) => Column(
///     children: [for (final permit in permits) Text(permit.registration)],
///   ),
/// )
/// ```
class CivicLoadingState extends StatelessWidget {
  /// The waiting page.
  const CivicLoadingState({super.key, this.label});

  /// The words; null says "Loading" in the reader's language.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final words = label ?? RawWidgetsLocalizations.of(context).loadingLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s24),
        child: Semantics(
          liveRegion: true,
          child: Text(
            words,
            style: context.civicText.headingS.copyWith(color: t.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}

/// What a page shows when its content could not be had: a [title] that
/// says so plainly, the [message] (what happened, what to do), and with
/// [onRetry] a button to try again, said by a screen reader as it appears.
///
/// ```dart
/// CivicErrorState(
///   title: 'Sorry, the service is unavailable',
///   message: 'Check your connection, then try again.',
///   onRetry: retry,
/// )
/// ```
class CivicErrorState extends StatelessWidget {
  /// The failed page.
  const CivicErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
  });

  /// What went wrong, in a sentence.
  final String title;

  /// What it means and what to do.
  final String? message;

  /// Tries again; null shows no button.
  final VoidCallback? onRetry;

  /// The button's words; null says "Try again" in the reader's language.
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final words = message;
    final retry = onRetry;
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s24),
        child: CivicEmptyState(
          title: title,
          announce: true,
          actions: [
            if (retry != null)
              // The page's one way on: its button, not a quiet one.
              CivicButton(
                expand: false,
                onPressed: retry,
                child: Text(
                  retryLabel ??
                      RawWidgetsLocalizations.of(context).retryButtonLabel,
                ),
              ),
          ],
          children: [if (words != null) Text(words)],
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
      ..add(ObjectFlagProperty<VoidCallback>.has('onRetry', onRetry));
  }
}
