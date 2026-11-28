import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/corners.dart';
import '../../internal/even_acts.dart';
import '../../internal/narrow.dart';
import '../../internal/pixel_center.dart';
import '../../internal/presence.dart';
import '../../internal/styled.dart';
import '../../style.dart';
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

/// One act of a [LedgerDialog] that takes its [LedgerDialog.actions]: a
/// [label] and what a press does. A slip carries one seal: the
/// [isDefaultAction], filled in the green (the vermilion when it
/// [isDestructiveAction] too), or with no default act a destructive one,
/// filled in the vermilion. Beside the seal a destructive act is ringed in the
/// vermilion, its words in the over ink, and any other act ringed in the ink.
///
/// ```dart
/// LedgerDialogAction('Save changes', value: 'save', isDefaultAction: true)
/// ```
@immutable
class LedgerDialogAction {
  /// An act worded [label].
  const LedgerDialogAction(
    this.label, {
    this.onPressed,
    this.value,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  /// The act's words.
  final String label;

  /// What a press does; null draws it out of use in a dialog standing in a
  /// page. [LedgerDialog.showActions] closes the dialog first, then runs it.
  final VoidCallback? onPressed;

  /// What [LedgerDialog.showActions] completes with when this act closes it.
  final Object? value;

  /// Whether it is the act the dialog is for (Save, Send), in the green.
  final bool isDefaultAction;

  /// Whether it cannot be taken back (Discard, Delete), in the vermilion;
  /// the dialog opens with the focus on an act that is not.
  final bool isDestructiveAction;
}

/// A decision put on a slip of paper, centred over the scrim: the [title] in
/// the serif over the ink rule, the [body] under it (and any [children] after
/// the body: a field, a note), then the acts, sharing the width evenly or,
/// when one's words would not fit its share, stacked across it, the last
/// (the confirm) on top. [type] picks two of them: a [LedgerDialogType.confirm] has Cancel and
/// the green [confirmLabel], a [LedgerDialogType.destructive] the vermilion one
/// (only for what cannot be undone), an [LedgerDialogType.acknowledge] a lone
/// "Got it". A question with more answers (Cancel, Discard, Save changes)
/// gives them as [actions] instead, raised with [showActions]. Its card is
/// 360 at most, the raised paper on the dialog's
/// shadow, and it scrolls once its words outgrow the screen. Raise it with
/// [show], which completes with true for the confirm, false for Cancel and
/// null when the scrim, Escape or the system back dismisses it: ui_core's
/// [RawModalDialogRoute] fades it in on its spring (a short fade under Reduce
/// Motion), keeps Tab inside it, opens with the focus on the safe act
/// (Cancel beside a destructive confirm, the confirm otherwise) and gives
/// the focus back to what opened it. A phone's choice among options is a
/// [LedgerSheet]; a dialog is for one question.
///
/// ```dart
/// final ok = await LedgerDialog.show(context, title: 'Delete this entry?', body: 'It leaves your records for good.', type: LedgerDialogType.destructive, confirmLabel: 'Delete');
/// ```
///
/// ```dart
/// final choice = await LedgerDialog.showActions<String>(context, title: 'Unsaved changes', body: 'Save your changes before leaving?', actions: const [LedgerDialogAction('Cancel'), LedgerDialogAction('Discard', value: 'discard', isDestructiveAction: true), LedgerDialogAction('Save changes', value: 'save', isDefaultAction: true)]);
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
    this.actions,
    this.style,
    super.key,
  }) : assert(
         actions == null ||
             (confirmLabel == null &&
                 cancelLabel == null &&
                 onConfirmPressed == null &&
                 onCancelPressed == null),
         'Give the acts as actions or as the two labels, not both.',
       );

  /// The decision, in the serif.
  final String title;

  /// The card's look, over `components.dialog` (which also dresses every dialog
  /// `LedgerDialog.show` raises). It reads `fill`, `edge`, `side`, `corners`
  /// (or `shape`) and `padding`.
  final LedgerStyle? style;

  /// The question's words.
  final String? body;

  /// Parts after the body.
  final List<Widget> children;

  /// What it asks: its two acts and the confirm's ink. Unused with
  /// [actions].
  final LedgerDialogType type;

  /// The confirming act's words; null is "Confirm" ("Got it" to
  /// acknowledge, "Delete" to destroy).
  final String? confirmLabel;

  /// The words of the act that dismisses it; null is the shared words'
  /// Cancel ([RawWidgetsLocalizations.cancelButtonLabel]).
  final String? cancelLabel;

  /// What the confirming act does; null disables it.
  final VoidCallback? onConfirmPressed;

  /// What Cancel does; null leaves it to the route's pop.
  final VoidCallback? onCancelPressed;

  /// Its acts, in reading order with the confirm last, in place of the two
  /// that [type] picks: they share the width evenly, or stack across it, the
  /// last on top, when one's words would not fit its share.
  final List<LedgerDialogAction>? actions;

  /// Raises a [LedgerDialog] over the whole app (the app's root navigator,
  /// [LedgerHost.navigatorOf]) on ui_core's [RawModalDialogRoute]. Completes
  /// with true when the confirming act is pressed, false for Cancel and null
  /// when it is dismissed.
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
    // As showDialog does: the caller's themes ride along.
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push(
      RawModalDialogRoute<bool>(
        // The scrim closes it, as it did; Escape and the back do too.
        barrierDismissible: true,
        barrierColor: t.overlay,
        semanticLabel: title,
        builder: (dialogContext, details) => themes.wrap(
          FadeTransition(
            opacity: details.animation.drive(ledgerPresence),
            child: SafeArea(
              child: LedgerPixelCenter(
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
      ),
    );
  }

  /// Raises a [LedgerDialog] with [actions] as [show] raises one. A press
  /// closes it with that act's [LedgerDialogAction.value], then runs its
  /// [LedgerDialogAction.onPressed]; it completes with null when the scrim,
  /// Escape or the system back dismisses it.
  static Future<T?> showActions<T>(
    BuildContext context, {
    required String title,
    required List<LedgerDialogAction> actions,
    String? body,
    List<Widget> children = const [],
  }) {
    final t = context.ledgerTheme;
    final navigator = LedgerHost.navigatorOf(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    return navigator.push(
      RawModalDialogRoute<T>(
        barrierDismissible: true,
        barrierColor: t.overlay,
        semanticLabel: title,
        builder: (dialogContext, details) => themes.wrap(
          FadeTransition(
            opacity: details.animation.drive(ledgerPresence),
            child: SafeArea(
              child: LedgerPixelCenter(
                child: LedgerDialog(
                  title: title,
                  body: body,
                  actions: [
                    for (final a in actions)
                      LedgerDialogAction(
                        a.label,
                        value: a.value,
                        isDefaultAction: a.isDefaultAction,
                        isDestructiveAction: a.isDestructiveAction,
                        onPressed: () {
                          Navigator.of(dialogContext).pop(a.value as T?);
                          a.onPressed?.call();
                        },
                      ),
                  ],
                  children: children,
                ),
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
    properties
      ..add(StringProperty('title', title))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      )
      ..add(StringProperty('body', body, defaultValue: null))
      ..add(EnumProperty<LedgerDialogType>('type', type))
      ..add(StringProperty('confirmLabel', confirmLabel, defaultValue: null))
      ..add(StringProperty('cancelLabel', cancelLabel, defaultValue: null))
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onConfirmPressed',
          onConfirmPressed,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onCancelPressed',
          onCancelPressed,
        ),
      )
      ..add(
        IterableProperty<String>(
          'actions',
          actions?.map((a) => a.label),
          defaultValue: null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final destructive = type == LedgerDialogType.destructive;
    final acknowledge = type == LedgerDialogType.acknowledge;
    final shared = RawWidgetsLocalizations.of(context);
    // "Got it" and "Confirm" stay English: the shared words have neither.
    final yes =
        confirmLabel ??
        (acknowledge
            ? 'Got it'
            : (destructive
                  ? shared.deleteButtonTooltip
                  : shared.confirmButtonLabel));
    // Both acts are LedgerButtons, so they share one height at every
    // density (a confirm drawn by hand at 48 stood beside a 40 Cancel at
    // compact).
    final cancel = cancelLabel ?? shared.cancelButtonLabel;
    final onCancel = onCancelPressed ?? () => Navigator.of(context).maybePop();
    // Raised by [show], ui_core's route names it and scopes it; the safe act
    // (ui_core's rule: the act that is not destructive, else the confirm)
    // takes the focus as it opens. Standing in a page, it names itself and
    // takes no focus.
    final raised = ModalRoute.of(context) is RawModalDialogRoute;
    final safe = !raised
        ? null
        : acknowledge
        ? 1
        : RawAlertDialog.safeActionIndex([
            RawDialogAction(label: cancel, onPressed: onCancel),
            RawDialogAction(
              label: yes,
              onPressed: onConfirmPressed,
              isDefaultAction: true,
              isDestructiveAction: destructive,
            ),
          ]);
    final confirm = LedgerButton.filled(
      yes,
      onPressed: onConfirmPressed,
      expand: true,
      isDestructiveAction: destructive,
      autofocus: safe == 1,
    );
    final words = body;
    final so = LedgerStyleOf([style, t.components.dialog], const {});
    final given = actions;
    final Widget acts;
    if (given != null) {
      final first = !raised
          ? null
          : RawAlertDialog.safeActionIndex([
              for (final a in given)
                RawDialogAction(
                  label: a.label,
                  onPressed: a.onPressed,
                  isDefaultAction: a.isDefaultAction,
                  isDestructiveAction: a.isDestructiveAction,
                ),
            ]);
      // One seal on the slip: the default act, or failing one the loss.
      final seal = given.any((a) => a.isDefaultAction)
          ? (LedgerDialogAction a) => a.isDefaultAction
          : (LedgerDialogAction a) => a.isDestructiveAction;
      final buttons = [
        for (final (i, a) in given.indexed)
          seal(a)
              ? LedgerButton.filled(
                  a.label,
                  onPressed: a.onPressed,
                  expand: true,
                  isDestructiveAction: a.isDestructiveAction,
                  autofocus: first == i,
                )
              : LedgerButton(
                  a.label,
                  onPressed: a.onPressed,
                  expand: true,
                  isDestructiveAction: a.isDestructiveAction,
                  autofocus: first == i,
                ),
      ];
      acts = buttons.length == 1
          ? buttons.single
          : LedgerEvenActs(
              gap: LedgerChromeMetrics.buttonRowGap,
              children: buttons,
            );
    } else if (acknowledge) {
      acts = confirm;
    } else {
      acts = LedgerEvenActs(
        gap: LedgerChromeMetrics.buttonRowGap,
        children: [
          LedgerButton(
            cancel,
            expand: true,
            onPressed: onCancel,
            autofocus: safe == 0,
          ),
          confirm,
        ],
      );
    }
    return Semantics(
      scopesRoute: !raised,
      namesRoute: !raised,
      explicitChildNodes: true,
      label: raised ? null : title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _margin),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _width),
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: so.paper(
                BoxDecoration(
                  color: t.surface,
                  borderRadius: ledgerRadius(t, so, RawCorner.large),
                  boxShadow: t.dialogShadow,
                ),
              ),
              child: SingleChildScrollView(
                padding:
                    so.padding(Directionality.of(context)) ??
                    const EdgeInsets.fromLTRB(_pad, _top, _pad, _pad),
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
                    // more share it, at any window.
                    LedgerCardActsScope(child: acts),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // The card 360 at most, 24 of
  // paper round its words (the head brings 14 of its own above), 16 between
  // the parts and 24 over the acts.
  static const double _width = 360;
  static const double _margin = 24;
  static const double _pad = 24;
  static const double _top = 10;
  static const double _partGap = 16;
  static const double _actsTop = 24;
}
