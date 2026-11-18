import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/button_paint.dart';
import '../internal/cap_label.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'button.dart';

/// Minimal's confirm dialog — the kit's only modal question: a compact
/// card centred over the scrim, its title in [MinimalThemeData.h3], the
/// [message] in the quiet 13 px ink, and small buttons right-aligned in a
/// footer under a hairline (stacked, the confirm on top, when they do not
/// share a line). [showMinimalDialog] raises it; raised, the confirm
/// answers true and the cancel false (after [onConfirm] or [onCancel], when
/// given), and a tap on the scrim or Escape answers null. Raised, focus
/// opens on the safe answer: the cancel when the confirm is [destructive]
/// (Enter then keeps), else the confirm (Enter confirms). The layout and
/// the focus are ui_core's ([DesignDialog]); Minimal paints them.
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

  /// In place, take the keyboard focus on arrival, so Enter confirms at
  /// once; null leaves the page's focus alone. Raised, the focus opens on
  /// the safe answer whatever this says.
  final bool? autofocus;

  /// Cast [MinimalThemeData.shadowLg], the floating register. Null casts it
  /// when raised: nothing on the page casts a shadow, so a card standing in
  /// place leaves it off.
  final bool? elevated;

  /// This card's style, over `components.dialog`.
  final MinimalStyle? style;

  /// The card's widest measure from [MinimalLayout.compact] up; on a phone
  /// it runs from the page's gutter to the gutter, as a floating surface
  /// starts on the page's margin.
  static const double maxWidth = 340;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final message = this.message;
    final cancelLabel = this.cancelLabel;
    final raised = _RaisedDialog.of(context);
    final elevated = this.elevated ?? raised;
    final autofocus = this.autofocus ?? false;
    // Raised, a button answers the route after its own callback.
    VoidCallback? answer(VoidCallback? callback, bool value) => raised
        ? () {
            callback?.call();
            Navigator.of(context).pop(value);
          }
        : callback;
    final confirm = answer(onConfirm, true);
    final cancel = answer(onCancel, false);
    final confirmWords = confirmLabel ?? MinimalLocalizations.of(context).ok;
    final screen = MediaQuery.sizeOf(context).width;
    final width = screen < MinimalLayout.compact
        ? screen - 2 * MinimalChromeMetrics.gutter
        : math.min(maxWidth, screen - 2 * MinimalChromeMetrics.gutter);

    // The dialog floats over the scrim like a sheet card, so it takes the
    // theme's sheet corner.
    final so = MinimalStyleOf([style, t.components.dialog], const {});
    final shape = so.shape ?? t.shapes.large;
    final rim = so.rim(t.border, t.rim);
    final fill = so.fill ?? t.card;
    // What stands inside the rim: the shape drawn the rim's width in.
    final within = MinimalShapes.inset(shape, rim.width);
    final rounded = within is RoundedRectangleBorder;
    final pad = (so.paddingIn(context) ?? MinimalInsets.all16).resolve(
      Directionality.of(context),
    );
    final heading = Text(title, style: t.h3);
    final words = message == null
        ? null
        : Text(message, style: t.bodySmall.c(t.mutedForeground));
    // The floating action bar's band: small buttons on 10 px of air, their
    // outer edge on the question's own inset (one inner edge), on the
    // card's own ground under a rule: no second, grey ground.
    Widget band(Widget actions) => Container(
      padding: EdgeInsets.fromLTRB(
        pad.left,
        MinimalChromeMetrics.actionBarPad,
        pad.right,
        MinimalChromeMetrics.actionBarPad,
      ),
      decoration: BoxDecoration(
        border: Border(top: t.rule),
        // The band sits inside the card's rim.
        borderRadius: within is RoundedRectangleBorder
            ? _foot(within.borderRadius)
            : null,
      ),
      child: MinimalGroundFill(fill: fill, child: actions),
    );
    Widget card(Widget body) => Container(
      width: width,
      decoration: minimalFrame(
        shape,
        fill: fill,
        side: rim,
        shadows: elevated ? t.shadowLg : null,
      ),
      // A rounded card rounds its band; any other outline clips it.
      child: MinimalGroundFill(
        fill: fill,
        child: rounded ? body : minimalClip(within, child: body),
      ),
    );

    if (raised) {
      // ui_core lays the question out and holds the focus: on the safe
      // answer as it opens, Tab kept inside, Enter or Space pressing the
      // focused answer. The words scroll between the title and the band
      // when they run long.
      MinimalButtonTone toneOf(DesignDialogAction action) =>
          !action.isDefaultAction && !action.isDestructiveAction
          ? MinimalButtonTone.secondary
          : destructive
          ? MinimalButtonTone.destructive
          : MinimalButtonTone.primary;
      return DesignDialog(
        title: title,
        titleBuilder: (context, title) => Padding(
          padding: EdgeInsets.fromLTRB(
            pad.left,
            pad.top,
            pad.right,
            words == null ? pad.bottom : 0,
          ),
          child: heading,
        ),
        content: words == null
            ? null
            : Padding(
                padding: EdgeInsets.fromLTRB(
                  pad.left,
                  MinimalSpacing.s4,
                  pad.right,
                  pad.bottom,
                ),
                child: words,
              ),
        actions: [
          if (cancelLabel != null)
            DesignDialogAction(label: cancelLabel, onPressed: cancel),
          DesignDialogAction(
            label: confirmWords,
            onPressed: confirm,
            isDefaultAction: !destructive,
            isDestructiveAction: destructive,
          ),
        ],
        actionBuilder: (context, action, details) {
          final paint = MinimalButtonPaint.of(
            context,
            tone: toneOf(action),
            scale: MinimalButtonScale.small,
          );
          final states = {
            ...details.states,
            if (!action.enabled) WidgetState.disabled,
          };
          // A button's face, its press wash and its ring as its pressable
          // lays them, in the target a finger reaches.
          return DesignTapTarget(
            child: Opacity(
              opacity: action.enabled ? 1 : 0.45,
              child: paint.face(
                context,
                states,
                foregroundDecoration: minimalStateLayer(
                  t,
                  paint.rest.shape ?? t.shapes.small,
                  states,
                  face: paint.rest.fill ?? paint.bg,
                  faceInk: paint.rest.foreground ?? paint.fg,
                  ground: fill,
                ),
                content: (so, ink) => minimalCapLabel(
                  Text(
                    action.label,
                    style: so.text(paint.type, ink),
                    maxLines: 2,
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
        actionsBuilder: (context, details, actions) => band(actions),
        frameBuilder: (context, details, dialog) => card(dialog),
        // showMinimalDialog stands it on the page's gutter, inside the
        // safe area.
        insetPadding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: width),
        actionSpacing: MinimalSpacing.s8,
        stackedActionSpacing: MinimalSpacing.s8,
      );
    }

    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              if (words != null) ...[
                const MinimalGap(MinimalSpacing.s4),
                words,
              ],
            ],
          ),
        ),
        band(
          Wrap(
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
                confirmWords,
                size: MinimalButtonSize.small,
                variant: destructive
                    ? MinimalButtonVariant.destructive
                    : MinimalButtonVariant.primary,
                onPressed: confirm,
              ),
            ],
          ),
        ),
      ],
    );

    // In place, Enter answers the question when the card itself has the
    // focus (a focused button answers for itself); a card standing in a
    // page is no route of its own.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Focus(
        autofocus: autofocus,
        // Focus rests on the card for Enter's sake, but Tab passes it: a
        // stop there would show nothing.
        skipTraversal: true,
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
        child: card(body),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null))
      ..add(StringProperty('confirmLabel', confirmLabel, defaultValue: null))
      ..add(StringProperty('cancelLabel', cancelLabel, defaultValue: null))
      ..add(
        FlagProperty('destructive', value: destructive, ifTrue: 'destructive'),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onConfirm', onConfirm))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel))
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: null),
      )
      ..add(DiagnosticsProperty<bool>('elevated', elevated, defaultValue: null))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
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
/// fades in without scaling (nothing in Minimal grows), on a spring with no
/// overshoot that settles in about 120 ms, and fades out the same way;
/// under Reduce Motion a short fade. As it opens it takes the focus and
/// keeps Tab inside it; as it closes the focus goes back to what opened it.
/// The route is ui_core's ([DesignDialogRoute]); Minimal paints it.
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
  return navigator.push<T>(
    DesignDialogRoute<T>(
      barrierColor: t.overlay,
      barrierDismissible: barrierDismissible,
      barrierLabel: MinimalLocalizations.of(context).dismiss,
      dampingRatio: MinimalChromeMetrics.routeDamping,
      stiffness: MinimalChromeMetrics.dialogStiffness,
      builder: (dialogContext, details) => themes.wrap(
        AnimatedBuilder(
          animation: details.animation,
          builder: (context, child) => Opacity(
            opacity: details.animation.value.clamp(0.0, 1.0),
            child: child,
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: MinimalInsets.gutter,
                child: _RaisedDialog(child: Builder(builder: builder)),
              ),
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
