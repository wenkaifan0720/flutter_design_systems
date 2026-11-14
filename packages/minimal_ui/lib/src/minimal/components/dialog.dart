import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'button.dart';

/// Minimal's confirm dialog — the kit's only modal question: a compact
/// card centred over the scrim, its title in [MinimalThemeData.h3], the
/// [message] in the quiet 13 px ink, and small buttons right-aligned in a
/// footer under a hairline. [showMinimalDialog] raises it; raised, the confirm
/// answers true and the cancel false (after [onConfirm] or [onCancel], when
/// given), a tap on the scrim or Escape answers null, and Enter confirms.
///
/// The widget itself is the card, for a page that shows the question in
/// place (a preview, an inline guard) rather than modally. In place it is
/// border only, like anything else on the page, and its buttons do only what
/// [onConfirm] and [onCancel] say; [elevated] gives it the floating shadow,
/// which a raised card takes by default.
///
/// [style] dresses one card, `components.dialog` every one: fill, edge or
/// side, shape (else `shapes.large`) and padding (round the question). The
/// buttons keep their own styles, as Material's do.
///
/// ```dart
/// final sure = await showMinimalDialog<bool>(context, builder: (context) => const MinimalDialog(title: 'Delete habit?', message: 'Its history goes too.', confirmLabel: 'Delete', cancelLabel: 'Keep', destructive: true));
/// ```
class MinimalDialog extends StatelessWidget {
  /// A dialog asking about [title].
  const MinimalDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.destructive = false,
    this.onConfirm,
    this.onCancel,
    this.autofocus,
    this.elevated,
    this.style,
  });

  /// The question, which names a raised card's route for a screen reader.
  final String title;

  /// One or two sentences on what confirming does; null keeps the title
  /// alone.
  final String? message;

  /// What the confirming button says; null: OK, in the app's language.
  final String? confirmLabel;

  /// The way out without acting; null offers the confirm alone (an
  /// acknowledgement).
  final String? cancelLabel;

  /// The destructive register: the confirm wears the destructive fill.
  final bool destructive;

  /// Called by the confirm. In place, null leaves the confirm out of use; a
  /// raised card's confirm answers true either way.
  final VoidCallback? onConfirm;

  /// Called by the cancel; a raised card's cancel answers false either way.
  final VoidCallback? onCancel;

  /// Take the keyboard focus on arrival, so Enter answers at once. Null takes
  /// it when raised: a card standing in a page leaves the page's focus alone.
  final bool? autofocus;

  /// Cast [MinimalThemeData.shadowLg], the floating register. Null casts it
  /// when raised: nothing on the page casts a shadow, so a card standing in
  /// place leaves it off.
  final bool? elevated;

  /// This card's style, over `components.dialog`.
  final MinimalStyle? style;

  /// The card's widest measure; narrower screens keep a gutter each side.
  static const double maxWidth = 340;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final message = this.message;
    final cancelLabel = this.cancelLabel;
    final raised = _RaisedDialog.of(context);
    final elevated = this.elevated ?? raised;
    final autofocus = this.autofocus ?? raised;
    // Raised, a button answers the route after its own callback.
    VoidCallback? answer(VoidCallback? callback, bool value) => raised
        ? () {
            callback?.call();
            Navigator.of(context).pop(value);
          }
        : callback;
    final confirm = answer(onConfirm, true);
    final cancel = answer(onCancel, false);
    final width = math.min(
      maxWidth,
      MediaQuery.sizeOf(context).width - 2 * MinimalChromeMetrics.gutter,
    );

    // The dialog floats over the scrim like a sheet card, so it takes the
    // theme's sheet corner.
    final so = MinimalStyleOf([style, t.components.dialog], const {});
    final shape = so.shape ?? t.shapes.large;
    final rim = so.rim(t.border, t.rim);
    // What stands inside the rim: the shape drawn the rim's width in.
    final within = MinimalShapes.inset(shape, rim.width);
    final rounded = within is RoundedRectangleBorder;
    final pad = (so.padding ?? MinimalInsets.all16).resolve(
      Directionality.of(context),
    );
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: t.h3),
              if (message != null) ...[
                const MinimalGap(MinimalSpacing.s4),
                Text(message, style: t.bodySmall.c(t.mutedForeground)),
              ],
            ],
          ),
        ),
        Container(
          // The floating action bar's band: small buttons on 10 px of air,
          // their outer edge on the question's own inset (one inner edge).
          padding: EdgeInsets.fromLTRB(
            pad.left,
            MinimalChromeMetrics.actionBarPad,
            pad.right,
            MinimalChromeMetrics.actionBarPad,
          ),
          // On the card's own ground under a rule: no second, grey ground.
          decoration: BoxDecoration(
            border: Border(top: t.rule),
            // The band sits inside the card's rim.
            borderRadius: within is RoundedRectangleBorder
                ? _foot(within.borderRadius)
                : null,
          ),
          child: MinimalGroundFill(
            fill: so.fill ?? t.card,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: MinimalSpacing.s8,
              runSpacing: MinimalSpacing.s8,
              children: [
                if (cancelLabel != null)
                  MinimalButton(
                    cancelLabel,
                    size: MinimalButtonSize.small,
                    variant: MinimalButtonVariant.secondary,
                    onPressed: cancel,
                  ),
                MinimalButton(
                  confirmLabel ?? MinimalLocalizations.of(context).ok,
                  size: MinimalButtonSize.small,
                  variant: destructive
                      ? MinimalButtonVariant.destructive
                      : MinimalButtonVariant.primary,
                  onPressed: confirm,
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final card = Container(
      width: width,
      decoration: minimalFrame(
        shape,
        fill: so.fill ?? t.card,
        side: rim,
        shadows: elevated ? t.shadowLg : null,
      ),
      // A rounded card rounds its band; any other outline clips it.
      child: MinimalGroundFill(
        fill: so.fill ?? t.card,
        child: rounded ? body : minimalClip(within, child: body),
      ),
    );

    // Enter answers the question when nothing inside has focus (a focused
    // button answers for itself); Escape is the route's own dismissal.
    // The raised card is a route of its own, named by its question; a card
    // standing in a page is not.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: raised ? true : null,
      namesRoute: raised ? true : null,
      label: raised ? title : null,
      child: Focus(
        autofocus: autofocus,
        onKeyEvent: (node, event) {
          final enter =
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter;
          if (confirm == null || !enter || !node.hasPrimaryFocus) {
            return KeyEventResult.ignored;
          }
          if (event is KeyDownEvent) confirm();
          return KeyEventResult.handled;
        },
        child: card,
      ),
    );
  }
}

/// The bottom corners of [radius]: the band's.
BorderRadiusGeometry _foot(BorderRadiusGeometry radius) {
  final r = radius.resolve(TextDirection.ltr);
  return BorderRadius.only(
    bottomLeft: r.bottomLeft,
    bottomRight: r.bottomRight,
  );
}

/// Raise the dialog [builder] returns over the whole app and wait for its
/// answer: what the route is popped with, null when the scrim or Escape
/// dismisses it. A [MinimalDialog] in it answers true or false by itself. It
/// fades in without scaling (nothing in Minimal grows), on the peer
/// cross-fade's timings ([MinimalChromeMetrics.fadeIn] and
/// [MinimalChromeMetrics.fadeOut]), none at all when motion is off.
///
/// ```dart
/// final sure = await showMinimalDialog<bool>(context, builder: (context) => const MinimalDialog(title: 'Archive habit?', confirmLabel: 'Archive', cancelLabel: 'Keep')) ?? false;
/// ```
Future<T?> showMinimalDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final t = context.minimalTheme;
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  // The root navigator may stand above the page's own scopes (a preview
  // mounts its host under the navigator), so the tokens travel with it.
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final still = context.minimalStill;
  return navigator.push<T>(
    _DialogRoute<T>(
      reverseTransitionDuration: still
          ? Duration.zero
          : MinimalChromeMetrics.fadeOut,
      barrierColor: t.overlay,
      barrierDismissible: barrierDismissible,
      barrierLabel: MinimalLocalizations.of(context).dismiss,
      transitionDuration: still ? Duration.zero : MinimalChromeMetrics.fadeIn,
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation.drive(CurveTween(curve: MinimalMotion.out)),
        child: child,
      ),
      pageBuilder: (dialogContext, _, _) => themes.wrap(
        SafeArea(
          child: Center(
            child: Padding(
              padding: MinimalInsets.gutter,
              child: _RaisedDialog(child: Builder(builder: builder)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Marks a dialog raised by [showMinimalDialog], so its card answers the
/// route and names it.
class _RaisedDialog extends InheritedWidget {
  const _RaisedDialog({required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RaisedDialog>() != null;

  @override
  bool updateShouldNotify(_RaisedDialog oldWidget) => false;
}

/// The dialog's route: a [RawDialogRoute] that leaves on its own, shorter
/// timing, as the peer cross-fade does.
class _DialogRoute<T> extends RawDialogRoute<T> {
  _DialogRoute({
    required Duration reverseTransitionDuration,
    required super.pageBuilder,
    required super.transitionBuilder,
    required super.transitionDuration,
    super.barrierColor,
    super.barrierDismissible,
    super.barrierLabel,
  }) : _reverse = reverseTransitionDuration;

  final Duration _reverse;

  @override
  Duration get reverseTransitionDuration => _reverse;
}
