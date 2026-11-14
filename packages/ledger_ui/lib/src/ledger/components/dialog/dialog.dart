import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/even_acts.dart';
import '../../internal/narrow.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../host.dart';
import '../sheet.dart';

/// What a [LedgerDialog] asks of the person.
enum LedgerDialogType {
  /// A question with two answers: the green act confirms, Cancel declines.
  confirm,

  /// A question whose yes cannot be taken back: the vermilion act confirms.
  destructive,

  /// Nothing to decide: one act that says it was read.
  acknowledge,
}

/// A decision put on a slip of paper, centred over the scrim: the [title] in
/// the serif over the ink rule, the [body] under it (and any [children] after
/// the body: a field, a note), then the acts, two sharing the width or one
/// across it. [type] picks them: a [LedgerDialogType.confirm] has Cancel and
/// the green [confirmLabel], a [LedgerDialogType.destructive] the vermilion one
/// (only for what cannot be undone), an [LedgerDialogType.acknowledge] a lone
/// "Got it". Its card is 360 at most, the raised paper on the dialog's
/// shadow, and it scrolls once its words outgrow the screen. Raise it with
/// [show], which completes with true for the confirm, false for Cancel and
/// null when the scrim or the system back dismisses it. A phone's choice
/// among options is a [LedgerSheet]; a dialog is for one question.
///
/// ```dart
/// final ok = await LedgerDialog.show(context, title: 'Delete this entry?', body: 'It leaves your records for good.', type: LedgerDialogType.destructive, confirmLabel: 'Delete');
/// ```
class LedgerDialog extends StatelessWidget {
  /// A dialog titled [title], its acts picked by [type].
  const LedgerDialog({
    required this.title,
    this.body,
    this.children = const [],
    this.type = LedgerDialogType.confirm,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirmPressed,
    this.onCancelPressed,
    super.key,
  });

  /// The decision, in the serif.
  final String title;

  /// The question's words.
  final String? body;

  /// Parts after the body.
  final List<Widget> children;

  /// What it asks: its acts and the confirm's ink.
  final LedgerDialogType type;

  /// The confirming act's words; null is "Confirm" ("Got it" to
  /// acknowledge, "Delete" to destroy).
  final String? confirmLabel;

  /// The words of the act that dismisses it; null is the shared words'
  /// Cancel ([DesignLocalizations.cancelButtonLabel]).
  final String? cancelLabel;

  /// What the confirming act does; null disables it.
  final VoidCallback? onConfirmPressed;

  /// What Cancel does; null leaves it to the route's pop.
  final VoidCallback? onCancelPressed;

  /// Raises a [LedgerDialog] over the whole app (the app's root navigator,
  /// [LedgerHost.navigatorOf]). Completes with true when the confirming act
  /// is pressed, false for Cancel and null when it is dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? body,
    List<Widget> children = const [],
    LedgerDialogType type = LedgerDialogType.confirm,
    String? confirmLabel,
    String? cancelLabel,
  }) {
    final t = context.ledgerTheme;
    final navigator = LedgerHost.navigatorOf(context);
    final dismiss = DesignLocalizations.of(context).modalBarrierDismissLabel;
    // As showDialog does: the caller's themes ride along.
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push(
      RawDialogRoute<bool>(
        barrierDismissible: true,
        barrierLabel: dismiss,
        barrierColor: t.overlay,
        transitionDuration:
            LedgerSheet.motionOf(context).duration ?? Duration.zero,
        pageBuilder: (dialogContext, _, _) => themes.wrap(
          SafeArea(
            child: Center(
              child: LedgerDialog(
                title: title,
                body: body,
                type: type,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
                onConfirmPressed: () => Navigator.of(dialogContext).pop(true),
                onCancelPressed: () => Navigator.of(dialogContext).pop(false),
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final destructive = type == LedgerDialogType.destructive;
    final acknowledge = type == LedgerDialogType.acknowledge;
    final shared = DesignLocalizations.of(context);
    // "Got it" and "Confirm" stay English in 0.1.0: the shared words have
    // neither.
    final yes =
        confirmLabel ??
        (acknowledge
            ? 'Got it'
            : (destructive ? shared.deleteButtonTooltip : 'Confirm'));
    // Both acts are LedgerButtons, so they share one height at every
    // density (a confirm drawn by hand at 48 stood beside a 40 Cancel at
    // compact).
    final confirm = LedgerButton.filled(
      yes,
      onPressed: onConfirmPressed,
      expand: true,
      isDestructiveAction: destructive,
    );
    final words = body;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _margin),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _width),
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(t.sheetRadius),
                boxShadow: t.dialogShadow,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(_pad, _top, _pad, _pad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LedgerSheetHead(title: title),
                    const SizedBox(height: LedgerChromeMetrics.sheetBodyTop),
                    if (words != null)
                      Text(words, style: t.body.colored(t.textSecondary)),
                    for (final child in children) ...[
                      const SizedBox(height: _partGap),
                      child,
                    ],
                    const SizedBox(height: _actsTop),
                    // The card is the acts' measure: one takes its width,
                    // two share it, at any window.
                    if (acknowledge)
                      LedgerCardActsScope(child: confirm)
                    else
                      LedgerCardActsScope(
                        child: LedgerEvenActs(
                          gap: LedgerChromeMetrics.buttonRowGap,
                          children: [
                            LedgerButton(
                              cancelLabel ?? shared.cancelButtonLabel,
                              expand: true,
                              onPressed:
                                  onCancelPressed ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                            confirm,
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // DERIVED (the source's dialogs are sheets): the card 360 at most, 24 of
  // paper round its words (the head brings 14 of its own above), 16 between
  // the parts and 24 over the acts.
  static const double _width = 360;
  static const double _margin = 24;
  static const double _pad = 24;
  static const double _top = 10;
  static const double _partGap = 16;
  static const double _actsTop = 24;
}
