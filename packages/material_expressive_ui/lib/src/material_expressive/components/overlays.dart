/// Overlays: dialogs (basic, with an icon), plain and rich tooltips, and
/// coach marks (CONTRACT §4.1 `dialog`, `tooltip`, `coach-mark`), plus the
/// spring-driven popup route menus and dialogs are raised in. Owner:
/// w3-menus, with `test/overlays_test.dart` and the gallery's overlays demo.
///
/// Ports of Compose material3 1.5.0-alpha29 (wave decision F1):
///
/// - [ExpressiveDialog] is `AlertDialogContent` (`AlertDialog.kt`): a
///   `surfaceContainerHigh` container on the extra-large corner, 24dp
///   padding, the optional `secondary` icon centred over a centred title,
///   the supporting text, and the actions in `AlertDialogFlowRow`, listed
///   as drawn: the confirm action last, ending the row, and on top when they
///   stack. Its actions are
///   Compose's `TextButton`s, drawn on the shared pressable
///   (a text action of their own; the buttons family is not this item's to
///   import, decision F5). [showExpressiveDialog] raises it on the root
///   navigator in an [ExpressivePopupRoute] over the 32 % scrim.
/// - [ExpressivePlainTooltip] and [ExpressiveRichTooltip] are
///   `TooltipScope.PlainTooltip` and `.RichTooltip` (`Tooltip.kt`);
///   [ExpressiveTooltip] is `TooltipBox`: a long press or a hovering mouse
///   shows the tooltip above its anchor (below when there is no room),
///   growing from 0.8 on the fast spatial spring as it fades in on the fast
///   effects spring; a non-persistent one leaves after 1.5 s (or when the
///   mouse leaves), a persistent one when a tap lands outside it.
/// - [ExpressiveCoachMark] is a persistent rich tooltip with a caret
///   (`TooltipDefaults.caretShape`) and an action, shown by the app rather
///   than by a long press. Compose has no coach mark; this is the Material
///   composition the spec's "rich tooltip with an action" names, in a
///   `TooltipBox(focusable = true, hasAction = true)`: Back and Escape
///   dismiss it (the focusable `Popup`'s `dismissOnBackPress`), Tab from
///   its anchor moves keyboard focus onto its action (`BasicTooltip.kt`'s
///   `keyboardBehavior`), and focus is back on the anchor once it goes.
///
/// Every popup mounts on the root overlay and wears the themes of the
/// context that raised it ([InheritedTheme.capture]), so it keeps the app's
/// theme when the app is not the root (App Preview nests every preview in
/// its own app). The coach mark alone mounts on its anchor's nearest
/// overlay: it teaches one screen, so it stays with it (in a pane with a
/// navigator of its own, in a frame with an overlay of its own).
///
/// [ExpressiveBackHandle] is the system back for an overlay a component
/// holds open over its route rather than in a route of its own (a split
/// button's menu, an open FAB menu, a combobox's menu): Compose's
/// `BackHandler(enabled = open)`, which a focusable `Popup`,
/// `ExposedDropdownMenuBox` and the FAB menu's sample each carry. The first
/// back closes the overlay and nothing else.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, clampDouble;
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../elevation.dart';
import '../internal/styled_content.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/button_small_tokens.g.dart';
import '../internal/tokens/dialog_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/plain_tooltip_tokens.g.dart';
import '../internal/tokens/rich_tooltip_tokens.g.dart';
import '../internal/tokens/scrim_tokens.g.dart';
import '../internal/tokens/text_button_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../states.dart';
import '../theme.dart';
import 'buttons.dart';

// ---------------------------------------------------------------------------
// The popup route.

/// How long [spring] takes to carry a 0–1 progress to rest at the kit's
/// [designSpringTolerance]: a spring route's `transitionDuration` (wave decision
/// F11). The spring drives the route's controller; the navigator only reads
/// the figure.
Duration expressiveSettleTime(SpringDescription spring) {
  final simulation = designSpringSimulation(spring, from: 0, to: 1);
  const step = Duration.microsecondsPerMillisecond;
  const limit = Duration.microsecondsPerSecond * 10;
  var elapsed = 0;
  while (elapsed < limit &&
      !simulation.isDone(elapsed / Duration.microsecondsPerSecond)) {
    elapsed += step;
  }
  return Duration(microseconds: elapsed);
}

/// A modal popup route driven by a spring, never a duration (wave decision
/// F11): the push runs the route's controller to 1 on [spring] and the pop
/// runs it back to 0, each from wherever it is — except a pop an overlay
/// held open in the popup takes ([ExpressiveBackHandle]), which leaves it
/// up. Menus, popovers and dialogs are raised in it on the root navigator,
/// wrapped in the [capturedThemes] of the context that raised them.
class ExpressivePopupRoute<T> extends PopupRoute<T>
    with ExpressiveBackHandleRoute<T> {
  /// A popup route that builds [builder] and moves on [spring].
  ExpressivePopupRoute({
    required this.builder,
    required this.spring,
    this.capturedThemes,
    this.transitionBuilder,
    this._barrierColor,
    this.barrierDismissible = true,
    this.barrierLabel,
    super.settings,
  });

  /// Builds the route's content.
  final WidgetBuilder builder;

  /// The spring the route's progress runs on, both ways. Its settle time is
  /// the route's `transitionDuration`.
  final SpringDescription spring;

  /// The themes of the context that raised the route; its content wears
  /// them.
  final CapturedThemes? capturedThemes;

  /// Wraps the content in the route's transition (the route's progress is
  /// the animation); none when null.
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  )?
  transitionBuilder;

  final Color? _barrierColor;

  @override
  Color? get barrierColor => _barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  Duration get transitionDuration => expressiveSettleTime(spring);

  @override
  TickerFuture didPush() {
    super.didPush();
    final controller = this.controller!;
    return controller.animateWith(
      designSpringSimulation(spring, from: controller.value, to: 1),
    );
  }

  @override
  bool didPop(T? result) {
    // False when a local history entry took the pop: the route stays.
    if (!super.didPop(result)) return false;
    final controller = this.controller!;
    controller.animateBackWith(
      designSpringSimulation(spring, from: controller.value, to: 0),
    );
    return true;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final page = Builder(builder: builder);
    return capturedThemes?.wrap(page) ?? page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => transitionBuilder?.call(context, animation, child) ?? child;
}

/// Closes the popup route [context] sits in, if it sits in one (a dialog
/// or a menu laid out in place closes nothing), returning [result].
void _closePopup(BuildContext context, [Object? result]) {
  final route = ModalRoute.of(context);
  if (route is! PopupRoute || !route.isActive) return;
  if (route.isCurrent) {
    Navigator.of(context).pop(result);
  } else {
    Navigator.of(context).removeRoute(route, result);
  }
}

// ---------------------------------------------------------------------------
// The system back over an open overlay.

/// The system back for an overlay a component holds open over its route —
/// a split button's menu, an open FAB menu, a combobox's menu — rather than
/// in a route of its own (Compose's `BackHandler(enabled = open) { close }`).
///
/// While held it is a [LocalHistoryEntry] on the route, so the first back
/// closes the overlay and nothing else: the navigator's pop (the back
/// button, a router's back dispatch, a predictive back's commit) takes the
/// entry, not the route, and asks no `PopScope` on the page; the route
/// withholds its back gesture meanwhile ([ModalRoute.popGestureEnabled]),
/// so a predictive back never previews leaving the page; and the app tells
/// the platform it handles back ([NavigationNotification]), so on the first
/// route the back reaches the overlay instead of leaving the app.
///
/// On the kit's own routes ([ExpressiveBackHandleRoute]: pages, sheets, the
/// full-screen dialog, popups, the search view) the entry comes before the
/// page's `PopScope`s too; on another route Flutter asks a `PopScope` that
/// refuses first, as it does for a drawer.
///
/// A component calls [sync] in `build` with whether its overlay is open,
/// [release] the moment the overlay closes (a close followed at once by a
/// pop must pop the route), and [dispose] with its state. [onBack] is told
/// when a back took the entry; if the overlay stays open (a caller holding
/// it open), the component's next build holds the back again.
class ExpressiveBackHandle {
  /// A back handle that runs [onBack] when the system goes back.
  ExpressiveBackHandle({required this.onBack});

  /// Closes the overlay: a back took the entry.
  final VoidCallback onBack;

  ModalRoute<Object?>? _route;
  LocalHistoryEntry? _entry;

  /// Holds the back on [context]'s route while [open], and lets it go
  /// otherwise (or when there is no route).
  void sync(BuildContext context, {required bool open}) {
    final route = open ? ModalRoute.of(context) : null;
    if (route == _route) return;
    release();
    if (route == null) return;
    late final LocalHistoryEntry entry;
    entry = LocalHistoryEntry(
      onRemove: () => _removed(entry),
      impliesAppBarDismissal: false,
    );
    _route = route;
    _entry = entry;
    route.addLocalHistoryEntry(entry);
    _tell(route);
  }

  /// Lets the back go: the overlay has closed.
  void release() {
    final route = _route;
    final entry = _entry;
    _route = null;
    _entry = null;
    if (route == null || entry == null) return;
    entry.remove();
    _tell(route);
  }

  /// Lets the back go for good.
  void dispose() => release();

  void _removed(LocalHistoryEntry entry) {
    // [release] removing its own entry.
    if (!identical(entry, _entry)) return;
    final route = _route!;
    _route = null;
    _entry = null;
    _tell(route);
    onBack();
  }

  /// Tells the platform whether the app handles back now, as the route
  /// itself would were the entry a pop entry: after the frame, never
  /// mid-build.
  static void _tell(ModalRoute<Object?> route) {
    void tell() {
      final context = route.subtreeContext;
      if (context == null || !context.mounted || !route.isCurrent) return;
      NavigationNotification(
        canHandlePop:
            route.willHandlePopInternally ||
            route.popDisposition == RoutePopDisposition.doNotPop,
      ).dispatch(context);
    }

    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      tell();
      return;
    }
    scheduler
      ..addPostFrameCallback(
        (_) => tell(),
        debugLabel: 'ExpressiveBackHandle.tell',
      )
      ..ensureVisualUpdate();
  }
}

/// A route whose open overlays take the back before its `PopScope`s:
/// while an [ExpressiveBackHandle] holds the back on it, the pop is the
/// overlay's, even when a `PopScope` in the route refuses the route's own
/// (Flutter's [ModalRoute] asks the `PopScope`s first, so a page guarding
/// unsaved work would keep an open menu open and ask to be left). The
/// kit's routes mix it in; a route's own pops (`Navigator.pop`) are
/// unchanged.
mixin ExpressiveBackHandleRoute<T> on ModalRoute<T> {
  @override
  RoutePopDisposition get popDisposition =>
      willHandlePopInternally ? RoutePopDisposition.pop : super.popDisposition;
}

// ---------------------------------------------------------------------------
// Dialogs.

/// One action of an [ExpressiveDialog]: a text button, or with
/// [filled] a filled one. A press closes the dialog (its route returns
/// [value]) and then runs [onPressed]; [closesDialog] false keeps the dialog
/// open.
@immutable
class ExpressiveDialogAction {
  /// An action labelled [label] that runs [onPressed].
  const ExpressiveDialogAction(
    this.label, {
    this.onPressed,
    this.value,
    this.closesDialog = true,
    this.enabled = true,
    this.filled = false,
  });

  /// The button's text.
  final String label;

  /// Whether the action is a filled button (Compose's `confirmButton = {
  /// Button(…) }`) rather than a text button: the dialog's one emphatic
  /// confirm, such as a destructive "Empty" or "Delete". At most one action
  /// of a dialog should be.
  final bool filled;

  /// What a press does, after the dialog closes.
  final VoidCallback? onPressed;

  /// What the dialog's route returns when this action closes it.
  final Object? value;

  /// Whether a press closes the dialog.
  final bool closesDialog;

  /// Whether the action can be pressed. It is drawn out of use, too, when
  /// a press would do nothing: no [onPressed] and [closesDialog] false.
  final bool enabled;

  /// Whether a press does anything: [enabled], and it closes the dialog or
  /// runs [onPressed] (rule 1: the action's press is the dismissal, with its
  /// [value]; [onPressed] runs on top of it).
  bool get inUse => enabled && (closesDialog || onPressed != null);
}

/// Compose's `AlertDialog`: an optional [icon] centred over the [title],
/// the supporting [text] (or any [content]), scrolling when it is taller
/// than the dialog may be, and up to three [actions], listed as drawn — the
/// last is the confirm action, ending the row and on top when they stack.
///
/// Raise it with [showExpressiveDialog]; it can also be laid out in place.
class ExpressiveDialog extends StatelessWidget {
  /// A dialog with an optional [title], [text] or [content], and [actions].
  const ExpressiveDialog({
    this.title,
    this.style,
    this.text,
    this.content,
    this.icon,
    this.actions = const <ExpressiveDialogAction>[],
    super.key,
  }) : assert(text == null || content == null, 'text or content, not both');

  /// Stateful visual overrides before the dialog theme.
  final ExpressiveComponentThemeData? style;

  /// The headline.
  final String? title;

  /// The supporting text.
  final String? text;

  /// Custom content in place of [text], in the supporting text's style.
  final Widget? content;

  /// A glyph over the headline (the "with icon" variant): the headline
  /// then centres under it.
  final IconData? icon;

  /// The actions in reading order, as Flutter's `AlertDialog` takes them:
  /// the confirm action last, at the row's trailing end; when they stack on
  /// a narrow dialog, it goes on top (Material's rule).
  final List<ExpressiveDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 3, 'a dialog has at most three actions');
    final t = context.expressiveTheme;
    final c = t.colors;
    final body = text != null ? Text(text!) : content;
    final theme = t.dialogTheme.merge(style);
    Color on(ExpressiveColorRole role) => ExpressiveComponentThemeData.resolve(
      theme.foregroundColor,
      const <WidgetState>{},
      c.role(role),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AlertDialogBehavior.minWidth,
        maxWidth: AlertDialogBehavior.maxWidth,
      ),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: ExpressiveSurface(
          style: style,
          componentStyle: t.dialogTheme,
          padding: const EdgeInsets.all(AlertDialogBehavior.padding),
          shape: t.shapes.of(DialogTokens.containerShape),
          color: ExpressiveComponentThemeData.resolve(
            theme.backgroundColor,
            const <WidgetState>{},
            c.role(DialogTokens.containerColor),
          ),
          // The text shrinks (and scrolls) only where the height is bounded:
          // laid out in place in a scrolling page, the dialog is as tall as
          // its content.
          child: LayoutBuilder(
            builder: (context, constraints) {
              Widget text(Widget child) =>
                  constraints.hasBoundedHeight ? Flexible(child: child) : child;
              return IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (icon != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AlertDialogBehavior.iconPaddingBottom,
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size:
                                theme.iconSize?.resolve(const {}) ??
                                DialogTokens.iconSize,
                            color: c.role(DialogTokens.iconColor),
                          ),
                        ),
                      ),
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AlertDialogBehavior.titlePaddingBottom,
                        ),
                        child: Semantics(
                          header: true,
                          namesRoute: true,
                          child: Text(
                            title!,
                            textAlign: icon == null
                                ? TextAlign.start
                                : TextAlign.center,
                            style: t.type
                                .of(DialogTokens.headlineFont)
                                .merge(theme.textStyle?.resolve(const {}))
                                .copyWith(
                                  color: on(DialogTokens.headlineColor),
                                ),
                          ),
                        ),
                      ),
                    if (body != null)
                      text(
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AlertDialogBehavior.textPaddingBottom,
                          ),
                          child: SingleChildScrollView(
                            child: DefaultTextStyle.merge(
                              style: t.type
                                  .of(DialogTokens.supportingTextFont)
                                  .merge(theme.textStyle?.resolve(const {}))
                                  .copyWith(
                                    color: on(DialogTokens.supportingTextColor),
                                  ),
                              child: body,
                            ),
                          ),
                        ),
                      ),
                    if (actions.isNotEmpty)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _DialogActions(actions: actions),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// `AlertDialogFlowRow`: the actions, last first, flow in the reversed
/// direction, so a row reads as they are listed with the confirm action (the
/// last) at its end, and a stack has the confirm action on top.
class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.actions});

  final List<ExpressiveDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final flipped = direction == TextDirection.ltr
        ? TextDirection.rtl
        : TextDirection.ltr;
    // What the minimum touch target already adds around each 40dp action
    // comes off the stacked spacing (`buttonPaddingFromMICS`).
    final touch = ExpressiveMinimumInteractiveSize.enforcedAt(context)
        ? HostBehavior.minimumInteractiveComponentSize -
              ButtonSmallTokens.containerHeight
        : 0.0;
    final runSpacing = clampDouble(
      AlertDialogBehavior.actionRunSpacing - touch,
      0,
      AlertDialogBehavior.actionRunSpacing,
    );
    return Directionality(
      textDirection: flipped,
      child: Wrap(
        spacing: AlertDialogBehavior.actionSpacing,
        runSpacing: runSpacing,
        children: <Widget>[
          for (final action in actions.reversed)
            Directionality(
              textDirection: direction,
              child: _action(context, action),
            ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, ExpressiveDialogAction action) {
    final VoidCallback? press = action.inUse
        ? () {
            if (action.closesDialog) _closePopup(context, action.value);
            action.onPressed?.call();
          }
        : null;
    // A filled confirm: the small (40dp) filled button, the height of the
    // text actions beside it.
    return action.filled
        ? ExpressiveFilledButton(action.label, onPressed: press)
        : _TextAction(label: action.label, onPressed: press);
  }
}

// Compose's `TextButton` as dialogs and rich tooltips hold it: a 40dp
// label in `primary` on no container, 12dp either side (Compose's
// `TextButtonContentPadding`, not the shapes button's 16), at least 58dp
// wide, on the full corner, inside the 48dp touch target. An app's own
// text button is [ExpressiveTextButton].
class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, this.onPressed});

  /// The label.
  final String label;

  /// What a press does; disabled when null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final enabled = onPressed != null;
    final content = enabled
        ? c.role(TextButtonTokens.labelColor)
        : c
              .role(TextButtonTokens.disabledLabelColor)
              .withValues(alpha: TextButtonTokens.disabledLabelOpacity);
    return ExpressivePressable(
      componentStyle: t.buttonTheme,
      shapes: ExpressivePressShapes.all(
        t.shapes.of(ButtonSmallTokens.containerShapeRound),
      ),
      motion: ButtonBehavior.pressMotion,
      color: content.withValues(alpha: 0),
      contentColor: content,
      onPressed: onPressed,
      child: ExpressiveStyledContent(
        minimumSize: const Size(
          AlertDialogBehavior.actionMinWidth,
          ButtonSmallTokens.containerHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AlertDialogBehavior.actionHorizontalPadding,
          vertical: ButtonBehavior.verticalPadding,
        ),
        textStyle: t.type.of(DialogTokens.actionLabelTextFont),
        // Compose's TextButton text wraps: a label wider than the dialog
        // (large text) breaks between its words rather than losing its end.
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Raises the dialog [builder] builds (an [ExpressiveDialog], usually)
/// on the root navigator, centred over the scrim, fading in and out on the
/// default effects spring. Resolves to what the dialog closes with. A tap on
/// the scrim or the system back closes it unless [barrierDismissible] is
/// false.
Future<T?> showExpressiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final colors = context.expressiveTheme.colors;
  return navigator.push<T>(
    ExpressivePopupRoute<T>(
      // Compose's dialog rides the platform window's fade; the default
      // effects spring is Expressive's rendition of it (Compose names no
      // motion key for a dialog).
      spring: ExpressiveMotion.of(context)
          .spring(ExpressiveMotionKey.defaultEffects),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierColor: colors
          .role(ScrimTokens.containerColor)
          .withValues(alpha: ScrimTokens.containerOpacity),
      barrierDismissible: barrierDismissible,
      barrierLabel: Localizations.of<MaterialLocalizations>(
        context,
        MaterialLocalizations,
      )?.modalBarrierDismissLabel,
      transitionBuilder: (context, animation, child) =>
          FadeTransition(opacity: animation, child: child),
      builder: (context) => SafeArea(
        child: Padding(
          padding:
              MediaQuery.viewInsetsOf(context) +
              const EdgeInsets.all(AlertDialogBehavior.padding),
          child: Center(child: builder(context)),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tooltips.

/// Which side of its anchor a tooltip prefers (Compose's
/// `TooltipAnchorPosition.Above` / `.Below`): it takes the other when the
/// preferred one has no room.
enum ExpressiveTooltipPosition {
  /// Above the anchor, centred on it.
  above,

  /// Below the anchor, centred on it.
  below,
}

/// Where a tooltip's caret sits: on its top or bottom edge, [x] from its
/// left edge (or, made with [ExpressiveTooltipCaret.start], from its start
/// edge), pointing at the anchor.
@immutable
class ExpressiveTooltipCaret {
  /// A caret [x] from the tooltip's left edge; [below] says which edge it stands on.
  const ExpressiveTooltipCaret({required this.below, required this.x})
    : fromStart = false;

  /// A caret [start] from the tooltip's start edge (the right in
  /// right-to-left), so a tooltip placed by hand points at the same part of
  /// its anchor in either direction.
  const ExpressiveTooltipCaret.start({
    required this.below,
    required double start,
  }) : x = start,
       fromStart = true;

  /// Whether the tooltip is below its anchor (the caret on its top edge,
  /// pointing up) rather than above it (on its bottom edge, pointing down).
  final bool below;

  /// The caret's centre along the edge, from the tooltip's left (from its
  /// start when [fromStart]); kept clear of the corners.
  final double x;

  /// Whether [x] counts from the start edge rather than the left.
  final bool fromStart;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveTooltipCaret &&
      other.below == below &&
      other.x == x &&
      other.fromStart == fromStart;

  @override
  int get hashCode => Object.hash(below, x, fromStart);
}

/// Compose's `PlainTooltip`: [message] in `bodySmall` on `inverseSurface`,
/// on the extra-small corner, 8 × 4dp padding, 40 × 24dp at least and
/// 200dp wide at most. An [ExpressiveTooltip] shows it; laid out in place
/// it is the bubble alone.
class ExpressivePlainTooltip extends StatelessWidget {
  /// A plain tooltip showing [message].
  const ExpressivePlainTooltip(
    this.message, {
    this.caret,
    this.style,
    super.key,
  });

  /// The text.
  final String message;

  /// A caret pointing at the anchor; none when null (Compose's default).
  final ExpressiveTooltipCaret? caret;

  /// Stateful visual overrides before the tooltip theme.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final scoped = t.tooltipTheme.merge(style);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: TooltipBehavior.minWidth,
        maxWidth: TooltipBehavior.plainMaxWidth,
        minHeight: TooltipBehavior.minHeight,
      ),
      child: ExpressiveSurface(
        style: style,
        componentStyle: t.tooltipTheme,
        shapeDecorator: (shape) => _withCaret(shape, caret),
        shape: _withCaret(
          t.shapes.of(PlainTooltipTokens.containerShape),
          caret,
        ),
        color: t.colors.role(PlainTooltipTokens.containerColor),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(
          horizontal: TooltipBehavior.plainHorizontalPadding,
        ),
        // Above and below the text as Compose pads it, not moved by
        // density: a denser surface would lose it while the least height
        // stays, and the text would ride the top edge.
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: TooltipBehavior.plainVerticalPadding,
          ),
          child: Text(
            message,
            style: t.type
                .of(PlainTooltipTokens.supportingTextFont)
                .merge(scoped.textStyle?.resolve(const {}))
                .copyWith(
                  color:
                      scoped.foregroundColor?.resolve(const {}) ??
                      t.colors.role(PlainTooltipTokens.supportingTextColor),
                ),
          ),
        ),
      ),
    );
  }
}

/// Compose's `RichTooltip`: an optional [title] (`titleSmall`, its first
/// baseline 28dp down), the [text] (`bodyMedium`), and an optional action
/// on `surfaceContainer` at elevation 2, on the medium corner, 16dp either
/// side, 320dp wide at most.
///
/// The action is a text button ([actionLabel] running [onAction]), or a
/// widget of the caller's own ([action], Compose's `action` slot), drawn in
/// the same row; a caller passes one or the other, never both.
class ExpressiveRichTooltip extends StatelessWidget {
  /// A rich tooltip showing [text], with an optional [title] and action.
  const ExpressiveRichTooltip({
    required this.text,
    this.title,
    this.style,
    this.actionLabel,
    this.onAction,
    this.action,
    this.caret,
    super.key,
  }) : assert(
         action == null || (actionLabel == null && onAction == null),
         'A rich tooltip takes its action as a widget (action) or as a text '
         'button (actionLabel, onAction), not both.',
       );

  /// Stateful visual overrides before the tooltip theme.
  final ExpressiveComponentThemeData? style;

  /// The supporting text.
  final String text;

  /// The subhead.
  final String? title;

  /// The text action's label; no text action when null.
  final String? actionLabel;

  /// What the text action does.
  final VoidCallback? onAction;

  /// The action as a widget of the caller's own, in place of the text
  /// action: Compose's `RichTooltip(action = …)` slot. It stands where the
  /// text action stands (at the start of the action row, the row at least
  /// its least height, over its bottom gap) and wears what Compose's slot
  /// provides: the action label's type (`labelLarge`) in its colour
  /// (`primary`) as its default text style and icon colour.
  final Widget? action;

  /// A caret pointing at the anchor; none when null.
  final ExpressiveTooltipCaret? caret;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final scoped = t.tooltipTheme.merge(style);
    Color on(ExpressiveColorRole role) =>
        scoped.foregroundColor?.resolve(const {}) ?? c.role(role);
    final hasTitle = title != null;
    final slot = action;
    final hasAction = slot != null || actionLabel != null;
    final textStyle = t.type
        .of(RichTooltipTokens.supportingTextFont)
        .merge(scoped.textStyle?.resolve(const {}))
        .copyWith(color: on(RichTooltipTokens.supportingTextColor));
    // `Modifier.textVerticalPadding`: from the baseline under a subhead or
    // over an action, else the plain tooltip's padding.
    final Widget body = hasTitle || hasAction
        ? Padding(
            padding: const EdgeInsets.only(
              bottom: TooltipBehavior.textBottomPadding,
            ),
            child: _FromBaseline(
              TooltipBehavior.textBaseline,
              child: Text(text, style: textStyle),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(
              vertical: TooltipBehavior.plainVerticalPadding,
            ),
            child: Text(text, style: textStyle),
          );
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: TooltipBehavior.minWidth,
        maxWidth: TooltipBehavior.richMaxWidth,
        minHeight: TooltipBehavior.minHeight,
      ),
      child: ExpressiveSurface(
        style: style,
        componentStyle: t.tooltipTheme,
        shapeDecorator: (shape) => _withCaret(shape, caret),
        shape: _withCaret(t.shapes.of(RichTooltipTokens.containerShape), caret),
        color: c.role(RichTooltipTokens.containerColor),
        shadowElevation: RichTooltipTokens.containerElevation,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(
          horizontal: TooltipBehavior.richHorizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (hasTitle)
              _FromBaseline(
                TooltipBehavior.titleBaseline,
                child: Text(
                  title!,
                  style: t.type
                      .of(RichTooltipTokens.subheadFont)
                      .merge(scoped.textStyle?.resolve(const {}))
                      .copyWith(color: on(RichTooltipTokens.subheadColor)),
                ),
              ),
            body,
            if (hasAction)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: TooltipBehavior.actionBottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: TooltipBehavior.actionMinHeight,
                  ),
                  child: slot == null
                      ? _TextAction(label: actionLabel!, onPressed: onAction)
                      : _ActionSlot(child: slot),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// What Compose's `RichTooltip` provides its `action` slot
/// (`CompositionLocalProvider(LocalContentColor provides
/// actionContentColor, LocalTextStyle provides actionLabelTextStyle)`): the
/// action label's colour and type as the default text style and the icon
/// colour, the slot at the row's top start as its `Box` places it.
class _ActionSlot extends StatelessWidget {
  const _ActionSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final color = t.colors.role(RichTooltipTokens.actionLabelTextColor);
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: IconTheme.merge(
        data: IconThemeData(color: color),
        child: DefaultTextStyle(
          style: t.type
              .of(RichTooltipTokens.actionLabelTextFont)
              .copyWith(color: color),
          child: child,
        ),
      ),
    );
  }
}

/// Compose's `Modifier.paddingFromBaseline(top:)`: [child] placed so its
/// first baseline is [baseline] below the top, in whole device pixels as
/// Compose lays it out — the padding is `baseline.roundToPx()` less the
/// child's rounded baseline, and the child's height is ceil'd to a pixel
/// (Compose sizes text boxes to whole pixels).
class _FromBaseline extends SingleChildRenderObjectWidget {
  const _FromBaseline(this.baseline, {required Widget super.child});

  final double baseline;

  @override
  _RenderFromBaseline createRenderObject(BuildContext context) =>
      _RenderFromBaseline(baseline, MediaQuery.devicePixelRatioOf(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderFromBaseline renderObject,
  ) {
    renderObject
      ..baseline = baseline
      ..pixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}

class _RenderFromBaseline extends RenderShiftedBox {
  _RenderFromBaseline(this._baseline, this._pixelRatio) : super(null);

  double _baseline;
  set baseline(double value) {
    if (value == _baseline) return;
    _baseline = value;
    markNeedsLayout();
  }

  double _pixelRatio;
  set pixelRatio(double value) {
    if (value == _pixelRatio) return;
    _pixelRatio = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    final r = _pixelRatio;
    final childBaseline =
        child.getDistanceToBaseline(TextBaseline.alphabetic) ??
        child.size.height;
    final top = math.max(
      ((_baseline * r).round() - (childBaseline * r).round()) / r,
      0.0,
    );
    final height = (child.size.height * r - 1e-6).ceil() / r;
    (child.parentData! as BoxParentData).offset = Offset(0, top);
    size = constraints.constrain(Size(child.size.width, top + height));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final child = this.child!;
    final d = child.getDistanceToActualBaseline(baseline);
    return d == null
        ? null
        : d + (child.parentData! as BoxParentData).offset.dy;
  }
}

ShapeBorder _withCaret(OutlinedBorder shape, ExpressiveTooltipCaret? caret) =>
    caret == null ? shape : _CaretBorder(shape, caret);

/// A tooltip's shape with Compose's default caret
/// (`DefaultTooltipCaretShape`): a 16 × 8dp triangle on the edge facing the
/// anchor, its tip pointing at it.
class _CaretBorder extends ShapeBorder {
  const _CaretBorder(this.shape, this.caret);

  final OutlinedBorder shape;
  final ExpressiveTooltipCaret caret;

  @override
  EdgeInsetsGeometry get dimensions => shape.dimensions;

  @override
  ShapeBorder scale(double t) =>
      _CaretBorder(shape.scale(t) as OutlinedBorder, caret);

  Path _caret(Rect rect, TextDirection? textDirection) {
    const half = TooltipBehavior.caretWidth / 2;
    final radii = switch (shape) {
      final ExpressiveCornerBorder corners => corners.radiiOn(rect),
      _ => BorderRadius.zero,
    };
    final inset = caret.below
        ? math.max(radii.topLeft.x, radii.topRight.x)
        : math.max(radii.bottomLeft.x, radii.bottomRight.x);
    final low = rect.left + inset + half;
    final high = rect.right - inset - half;
    final along = caret.fromStart && textDirection == TextDirection.rtl
        ? rect.right - caret.x
        : rect.left + caret.x;
    final x = low > high ? rect.center.dx : clampDouble(along, low, high);
    final edge = caret.below ? rect.top : rect.bottom;
    final tip = caret.below
        ? edge - TooltipBehavior.caretHeight
        : edge + TooltipBehavior.caretHeight;
    return Path()
      ..moveTo(x - half, edge)
      ..lineTo(x, tip)
      ..lineTo(x + half, edge)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path.combine(
    PathOperation.union,
    shape.getOuterPath(rect, textDirection: textDirection),
    _caret(rect, textDirection),
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  bool operator ==(Object other) =>
      other is _CaretBorder && other.shape == shape && other.caret == caret;

  @override
  int get hashCode => Object.hash(shape, caret);
}

/// Shows and hides an [ExpressiveTooltip] from the app (Compose's
/// `TooltipState.show()` / `.dismiss()`).
class ExpressiveTooltipController extends ChangeNotifier {
  bool _visible = false;

  /// Whether the tooltip is up (or going up).
  bool get isVisible => _visible;

  /// Shows the tooltip.
  void show() {
    if (_visible) return;
    _visible = true;
    notifyListeners();
  }

  /// Hides the tooltip.
  void dismiss() {
    if (!_visible) return;
    _visible = false;
    notifyListeners();
  }
}

/// Compose's `TooltipBox`: [child], and a tooltip that a long press or a
/// hovering mouse shows above it (below when there is no room above).
///
/// - [ExpressiveTooltip.plain]: [message] in a plain tooltip, gone after
///   1.5 s (Compose's `TooltipDuration`) or when the mouse leaves.
/// - [ExpressiveTooltip.rich]: a rich tooltip, persistent when it has an
///   action: it stays until a tap lands outside it or the action runs.
///
/// The tooltip scales from 0.8 on the fast spatial spring and fades on the
/// fast effects spring. A [controller] shows and hides it from the app.
class ExpressiveTooltip extends StatefulWidget {
  /// A plain tooltip reading [message].
  const ExpressiveTooltip.plain({
    required String this.message,
    required this.child,
    this.style,
    this.position = ExpressiveTooltipPosition.above,
    this.persistent = false,
    this.controller,
    super.key,
  }) : title = null,
       text = null,
       actionLabel = null,
       onAction = null,
       caret = false;

  /// A rich tooltip: [text] under an optional [title], with an optional
  /// action; persistent, unless told otherwise, when it has an action.
  const ExpressiveTooltip.rich({
    required String this.text,
    required this.child,
    this.style,
    this.title,
    this.actionLabel,
    this.onAction,
    this.position = ExpressiveTooltipPosition.above,
    bool? persistent,
    this.caret = false,
    this.controller,
    super.key,
  }) : message = null,
       persistent = persistent ?? actionLabel != null;

  /// Stateful visual overrides for the tooltip's surface and content.
  final ExpressiveComponentThemeData? style;

  /// The plain tooltip's text.
  final String? message;

  /// The rich tooltip's subhead.
  final String? title;

  /// The rich tooltip's supporting text.
  final String? text;

  /// The rich tooltip's action label.
  final String? actionLabel;

  /// What the rich tooltip's action does (the tooltip closes first).
  final VoidCallback? onAction;

  /// The side the tooltip prefers.
  final ExpressiveTooltipPosition position;

  /// Whether the tooltip stays until dismissed rather than leaving after
  /// 1.5 s or when the mouse leaves.
  final bool persistent;

  /// Whether the tooltip carries a caret pointing at [child].
  final bool caret;

  /// Shows and hides the tooltip from the app.
  final ExpressiveTooltipController? controller;

  /// The anchor.
  final Widget child;

  @override
  State<ExpressiveTooltip> createState() => _ExpressiveTooltipState();
}

class _ExpressiveTooltipState extends State<ExpressiveTooltip> {
  late final _TooltipPresenter _presenter = _TooltipPresenter(
    anchor: context,
    bubble: _bubble,
    position: () => widget.position,
    caret: () => widget.caret,
    persistent: () => widget.persistent,
    onDismissed: () => widget.controller?.dismiss(),
  );

  ExpressiveTooltipController? _listened;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(ExpressiveTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _listen();
    _presenter.markNeedsBuild();
  }

  void _listen() {
    _listened?.removeListener(_follow);
    _listened = widget.controller?..addListener(_follow);
  }

  void _follow() {
    if (widget.controller?.isVisible ?? false) {
      _presenter.show(timeout: false);
    } else {
      _presenter.hide();
    }
  }

  @override
  void dispose() {
    _listened?.removeListener(_follow);
    _presenter.dispose();
    super.dispose();
  }

  Widget _bubble(BuildContext context, ExpressiveTooltipCaret? caret) {
    final message = widget.message;
    if (message != null) {
      return ExpressivePlainTooltip(message, caret: caret, style: widget.style);
    }
    return ExpressiveRichTooltip(
      style: widget.style,
      title: widget.title,
      text: widget.text!,
      actionLabel: widget.actionLabel,
      onAction: widget.actionLabel == null
          ? null
          : () {
              _presenter.hide();
              widget.controller?.dismiss();
              widget.onAction?.call();
            },
      caret: caret,
    );
  }

  void _showByUser() => _presenter.show(timeout: !widget.persistent);

  @override
  Widget build(BuildContext context) => Semantics(
    tooltip: widget.message ?? widget.text,
    onLongPress: _showByUser,
    child: MouseRegion(
      onEnter: (_) => _presenter.show(timeout: false),
      onExit: (_) {
        if (!widget.persistent) _presenter.hide();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onLongPress: _showByUser,
        child: widget.child,
      ),
    ),
  );
}

/// A persistent rich tooltip with a caret and an action that teaches one
/// feature in place: up while [visible], pointing at [child].
///
/// Its action is a text button ([actionLabel], [onAction]: the coach mark
/// closes first, then tells [onDismissed] and runs [onAction]) or a widget
/// of the caller's own ([action], Compose's `RichTooltip` `action` slot),
/// which closes it as the caller decides (it sets [visible] false). A tap
/// outside, Back and Escape close it too, and [onDismissed] tells the app,
/// which stops showing it.
///
/// It is Compose's `TooltipBox(focusable = true, hasAction = true)` as far
/// as Compose goes there (material3 1.5.0-alpha29, compose-ui
/// 1.13.0-alpha01), and no further:
///
/// - Back and Escape dismiss it: the focusable `Popup`'s
///   `PopupProperties.dismissOnBackPress` (default true; the popup answers
///   `KEYCODE_BACK` and `KEYCODE_ESCAPE` with its `onDismissRequest`).
///   Back is held on the anchor's route while it is up
///   ([ExpressiveBackHandle]), so the first back closes it and nothing
///   else; Escape is heard on the anchor (`BasicTooltip.kt`'s
///   `keyboardBehavior`, `isEscape`) and inside the bubble.
/// - Tab (without Shift) on the anchor moves keyboard focus onto the
///   bubble's first control (`keyboardBehavior`: `hasAction && isTab`
///   makes the popup focusable and takes the Tab), where Tab stays, as in
///   a popup window of its own.
/// - When it goes, keyboard focus that was in the bubble is back where it
///   was before (the anchor), as on Compose's window once a focusable
///   popup window closes. Focus is never moved when it shows.
///
/// Not ported: the focusable popup consuming the tap outside (here the tap
/// reaches what lies under it too, as the persistent tooltip's does) and
/// moving a screen reader's focus onto the bubble (Flutter has no way to
/// move it; the bubble is announced as a live region instead).
///
/// Unlike Expressive's other popups it mounts on its anchor's nearest
/// overlay, not the root one: a coach mark teaches one screen and stays
/// with it, so a frame with an overlay of its own (a gallery's specimen)
/// keeps it, and in a pane with its own navigator it stays in the pane.
class ExpressiveCoachMark extends StatefulWidget {
  /// A coach mark showing [text] while [visible], pointing at [child].
  const ExpressiveCoachMark({
    required this.visible,
    required this.text,
    required this.child,
    this.title,
    this.style,
    this.actionLabel,
    this.onAction,
    this.action,
    this.onDismissed,
    this.position = ExpressiveTooltipPosition.below,
    super.key,
  }) : assert(
         action == null || (actionLabel == null && onAction == null),
         'A coach mark takes its action as a widget (action) or as a text '
         'button (actionLabel, onAction), not both.',
       );

  /// Visual overrides for the rich tooltip.
  final ExpressiveComponentThemeData? style;

  /// Whether the coach mark is up.
  final bool visible;

  /// The subhead: the feature's name.
  final String? title;

  /// What the feature does.
  final String text;

  /// The text action's label ("Got it", "Try it").
  final String? actionLabel;

  /// What the text action does (the coach mark closes first).
  final VoidCallback? onAction;

  /// The action as a widget of the caller's own, in place of the text
  /// action ([ExpressiveRichTooltip.action]); it closes the coach mark by
  /// what it does (the caller sets [visible] false).
  final Widget? action;

  /// Told when the coach mark closes by its text action, a tap outside,
  /// Back or Escape.
  final VoidCallback? onDismissed;

  /// The side the coach mark prefers.
  final ExpressiveTooltipPosition position;

  /// The feature the coach mark points at.
  final Widget child;

  @override
  State<ExpressiveCoachMark> createState() => _ExpressiveCoachMarkState();
}

class _ExpressiveCoachMarkState extends State<ExpressiveCoachMark> {
  late final ExpressiveBackHandle _back = ExpressiveBackHandle(
    onBack: _dismiss,
  );
  final FocusScopeNode _bubbleFocus = FocusScopeNode(
    debugLabel: 'ExpressiveCoachMark bubble',
  );
  late final _TooltipPresenter _presenter = _TooltipPresenter(
    anchor: context,
    bubble: (context, caret) => ExpressiveRichTooltip(
      title: widget.title,
      style: widget.style,
      text: widget.text,
      actionLabel: widget.actionLabel,
      onAction: widget.actionLabel == null
          ? null
          : () {
              _close();
              widget.onDismissed?.call();
              widget.onAction?.call();
            },
      action: widget.action,
      caret: caret,
    ),
    position: () => widget.position,
    caret: () => true,
    persistent: () => true,
    onDismissed: () {
      _down();
      widget.onDismissed?.call();
    },
    rootOverlay: false,
    focus: _bubbleFocus,
    onEscape: _dismiss,
  );

  /// Whether the coach mark is up: shown, and not closed since.
  bool _up = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ExpressiveCoachMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _presenter.markNeedsBuild();
    if (oldWidget.visible != widget.visible) _sync();
  }

  void _sync() {
    // After the frame that lays the anchor out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.visible) {
        if (_presenter.show(timeout: false)) _setUp(true);
      } else {
        _close();
      }
    });
  }

  /// Hides it and lets the back go.
  void _close() {
    _presenter.hide();
    _down();
  }

  /// Closed by the person: Back or Escape.
  void _dismiss() {
    if (!_up) return;
    _close();
    widget.onDismissed?.call();
  }

  /// Lets the back go the moment it closes (a close followed at once by a
  /// pop must pop the route).
  void _down() {
    _back.release();
    _setUp(false);
  }

  void _setUp(bool up) {
    if (_up == up || !mounted) return;
    setState(() => _up = up);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_up || event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _dismiss();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab &&
        !HardwareKeyboard.instance.isShiftPressed &&
        _presenter.focusInto()) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _back.dispose();
    _presenter.dispose();
    _bubbleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _back.sync(context, open: _up);
    // Hears Escape and Tab from the anchor's controls; adds no node, takes
    // no focus and draws nothing.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}

/// Puts a tooltip bubble on the root overlay (or, without [rootOverlay],
/// the anchor's nearest) beside [anchor]'s box, and springs it in and out.
///
/// With a [focus] scope (a coach mark), the bubble is a focus scope of its
/// own: [focusInto] moves keyboard focus onto its first control, Escape
/// inside it calls [onEscape], and when it hides, focus that was in it goes
/// back to where it was before at once (not when the bubble has faded).
class _TooltipPresenter {
  _TooltipPresenter({
    required this.anchor,
    required this.bubble,
    required this.position,
    required this.caret,
    required this.persistent,
    required this.onDismissed,
    this.rootOverlay = true,
    this.focus,
    this.onEscape,
  });

  final BuildContext anchor;
  final Widget Function(BuildContext context, ExpressiveTooltipCaret? caret)
  bubble;
  final ExpressiveTooltipPosition Function() position;
  final bool Function() caret;
  final bool Function() persistent;
  final VoidCallback onDismissed;

  /// Whether the bubble goes on the root overlay rather than the anchor's
  /// nearest.
  final bool rootOverlay;

  /// The bubble's focus scope; none for a tooltip.
  final FocusScopeNode? focus;

  /// Escape inside the bubble.
  final VoidCallback? onEscape;

  OverlayEntry? _entry;
  final ValueNotifier<bool> _shown = ValueNotifier<bool>(false);
  Timer? _timer;

  /// Where keyboard focus was when [focusInto] moved it into the bubble.
  FocusNode? _returnTo;

  /// Shows the bubble; false when there is no overlay to show it on.
  bool show({required bool timeout}) {
    _timer?.cancel();
    _timer = timeout
        ? Timer(Duration(milliseconds: TooltipBehavior.showDuration), hide)
        : null;
    if (_entry == null) {
      final overlay = Overlay.maybeOf(anchor, rootOverlay: rootOverlay);
      if (overlay == null) return false;
      final themes = InheritedTheme.capture(from: anchor, to: overlay.context);
      final direction = Directionality.of(anchor);
      final motion = ExpressiveMotion.of(anchor);
      _entry = OverlayEntry(
        builder: (context) => themes.wrap(
          _TooltipLayer(
            textDirection: direction,
            anchor: () => _anchorRect(overlay),
            motion: motion,
            shown: _shown,
            position: position(),
            caret: caret(),
            onOutside: persistent() ? _outside : null,
            onGone: _remove,
            focus: focus,
            onEscape: onEscape,
            bubble: bubble,
          ),
        ),
      );
      overlay.insert(_entry!);
    }
    _shown.value = true;
    return true;
  }

  Rect _anchorRect(OverlayState overlay) {
    final box = anchor.findRenderObject() as RenderBox?;
    final ground = overlay.context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || ground == null) return Rect.zero;
    return MatrixUtils.transformRect(
      box.getTransformTo(ground),
      Offset.zero & box.size,
    );
  }

  /// Moves keyboard focus onto the bubble's first control, remembering
  /// where it was; false when the bubble is down or has no control.
  bool focusInto() {
    final scope = focus;
    final context = scope?.context;
    if (scope == null || context == null || !_shown.value) return false;
    final first = FocusTraversalGroup.of(context)
        .findFirstFocus(scope, ignoreCurrentFocus: true);
    if (first == null || identical(first, scope)) return false;
    _returnTo = FocusManager.instance.primaryFocus;
    first.requestFocus();
    return true;
  }

  /// Takes keyboard focus out of the bubble, back where it was before.
  void _returnFocus() {
    final scope = focus;
    final to = _returnTo;
    _returnTo = null;
    if (scope == null || !scope.hasFocus) return;
    if (to != null && to.context != null && to.canRequestFocus) {
      to.requestFocus();
    } else {
      scope.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild);
    }
  }

  void _outside() {
    hide();
    onDismissed();
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _shown.value = false;
    _returnFocus();
  }

  /// Rebuilds the bubble after the frame: its layer is another subtree,
  /// which a build may not mark.
  void markNeedsBuild() {
    if (_entry == null) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entry?.markNeedsBuild(),
    );
  }

  void _remove() {
    if (_shown.value) return;
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
  }

  void dispose() {
    _timer?.cancel();
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _shown.dispose();
  }
}

/// The overlay layer a tooltip lives in: the bubble placed beside its
/// anchor, scaling from [TooltipBehavior.closedScale] and fading as [shown]
/// turns.
class _TooltipLayer extends StatefulWidget {
  const _TooltipLayer({
    required this.textDirection,
    required this.anchor,
    required this.motion,
    required this.shown,
    required this.position,
    required this.caret,
    required this.onOutside,
    required this.onGone,
    required this.bubble,
    this.focus,
    this.onEscape,
  });

  /// The reading direction where the tooltip's anchor is.
  final TextDirection textDirection;

  final Rect Function() anchor;

  /// The motion where the tooltip's anchor is (its Reduce Motion, its
  /// Standard pin).
  final ExpressiveMotion motion;

  final ValueListenable<bool> shown;
  final ExpressiveTooltipPosition position;
  final bool caret;
  final VoidCallback? onOutside;
  final VoidCallback onGone;
  final Widget Function(BuildContext context, ExpressiveTooltipCaret? caret)
  bubble;

  /// The bubble's focus scope (a coach mark's): the bubble is then a focus
  /// scope of its own, and Escape in it calls [onEscape].
  final FocusScopeNode? focus;
  final VoidCallback? onEscape;

  @override
  State<_TooltipLayer> createState() => _TooltipLayerState();
}

class _TooltipLayerState extends State<_TooltipLayer>
    with TickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: TooltipBehavior.closedScale,
  );
  late final AnimationController _alpha = AnimationController(vsync: this);
  final _TooltipGeometry _geometry = _TooltipGeometry();

  @override
  void initState() {
    super.initState();
    widget.shown.addListener(_turn);
    _alpha.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !widget.shown.value) {
        widget.onGone();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _turn();
    });
  }

  void _turn() {
    final motion = widget.motion;
    final shown = widget.shown.value;
    _scale.springTo(
      shown ? 1 : TooltipBehavior.closedScale,
      motion.spring(TooltipBehavior.scaleMotion),
    );
    final effects = motion.spring(TooltipBehavior.alphaMotion);
    if (shown) {
      _alpha.animateWith(
        designSpringSimulation(effects, from: _alpha.value, to: 1),
      );
    } else {
      _alpha.animateBackWith(
        designSpringSimulation(effects, from: _alpha.value, to: 0),
      );
    }
  }

  @override
  void dispose() {
    widget.shown.removeListener(_turn);
    _scale.dispose();
    _alpha.dispose();
    _geometry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget bubble = ListenableBuilder(
      listenable: _geometry,
      builder: (context, _) => widget.bubble(
        context,
        widget.caret && _geometry.anchorX != null
            ? ExpressiveTooltipCaret(
                below: _geometry.below,
                x: _geometry.anchorX!,
              )
            : null,
      ),
    );
    if (widget.onOutside != null) {
      bubble = TapRegion(
        onTapOutside: (_) => widget.onOutside!(),
        child: bubble,
      );
    }
    final focus = widget.focus;
    if (focus != null) {
      bubble = FocusScope(
        node: focus,
        // No node of its own: the bubble's live node holds its words.
        includeSemantics: false,
        onKeyEvent: (node, event) {
          final escape = widget.onEscape;
          if (escape == null ||
              event is! KeyDownEvent ||
              event.logicalKey != LogicalKeyboardKey.escape) {
            return KeyEventResult.ignored;
          }
          escape();
          return KeyEventResult.handled;
        },
        child: bubble,
      );
    }
    return CustomSingleChildLayout(
      delegate: _TooltipPlacement(
        // Read as the layer builds: a layout may not read another box's size.
        anchor: widget.anchor(),
        position: widget.position,
        spacing: widget.caret
            ? TooltipBehavior.anchorSpacing + TooltipBehavior.caretHeight
            : TooltipBehavior.anchorSpacing,
        geometry: _geometry,
      ),
      child: FadeTransition(
        opacity: _alpha,
        child: ScaleTransition(
          scale: _scale,
          child: Directionality(
            textDirection: widget.textDirection,
            child: Semantics(liveRegion: true, child: bubble),
          ),
        ),
      ),
    );
  }
}

/// Where the placement put the tooltip, for its caret: set in layout, read
/// by the next frame's bubble.
class _TooltipGeometry extends ChangeNotifier {
  bool below = false;
  double? anchorX;
  bool _disposed = false;

  void place({required bool below, required double anchorX}) {
    if (below == this.below && anchorX == this.anchorX) return;
    this.below = below;
    this.anchorX = anchorX;
    // Layout is no place to rebuild: the caret follows at the frame's end.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Compose's `TooltipPositionProviderImpl`, above and below: centred on the
/// anchor, kept inside the window, on the preferred side when it fits and
/// on the other when it does not.
class _TooltipPlacement extends SingleChildLayoutDelegate {
  _TooltipPlacement({
    required this.anchor,
    required this.position,
    required this.spacing,
    required this.geometry,
  });

  final Rect anchor;
  final ExpressiveTooltipPosition position;
  final double spacing;
  final _TooltipGeometry geometry;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final a = anchor;
    final x = clampDouble(
      a.left + (a.width - childSize.width) / 2,
      0,
      math.max(0, size.width - childSize.width),
    );
    final above = a.top - childSize.height - spacing;
    final below = a.bottom + spacing;
    final preferred = position == ExpressiveTooltipPosition.above
        ? (above < 0 ? below : above)
        : (below + childSize.height > size.height ? above : below);
    final y = clampDouble(
      preferred,
      0,
      math.max(0, size.height - childSize.height),
    );
    geometry.place(below: y >= a.center.dy, anchorX: a.center.dx - x);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TooltipPlacement oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.position != position ||
      oldDelegate.spacing != spacing;
}
