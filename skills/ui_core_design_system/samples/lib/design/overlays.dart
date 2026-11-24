import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'button.dart';
import 'face.dart';
import 'theme.dart';

/// Words that name [child], shown on a pointer's rest, a long press or the
/// keyboard's focus: Flutter's [RawTooltip], with ui_core's
/// [RawTooltipFocusFix] round the child and [RawTooltipPlacement] round the
/// tooltip.
///
/// ```dart
/// TendTooltip(message: 'Archive', child: TendButton('Archive', onPressed: () {}))
/// ```
class TendTooltip extends StatelessWidget {
  /// Names [child] with [message].
  const TendTooltip({super.key, required this.message, required this.child});

  /// The words.
  final String message;

  /// The control they name.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    // One node: the control's, with the tip on it, as Flutter's Tooltip
    // gives it. RawTooltip alone puts the tip on a node of its own.
    return MergeSemantics(
      child: RawTooltipPlacement(
        builder: (context, positionDelegate) => RawTooltip(
          semanticsTooltip: message,
          positionDelegate: positionDelegate,
          hoverDelay: const Duration(milliseconds: 500),
          tooltipBuilder: (context, animation) => FadeTransition(
            opacity: animation,
            child: TendSurface(
              face: TendFace(
                fill: theme.colors.ink,
                rule: theme.colors.ink,
                foreground: theme.colors.surface,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.radius / 2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(message, style: theme.label.copyWith(fontSize: 12)),
              ),
            ),
          ),
          child: RawTooltipFocusFix(child: child),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}

/// Opens an alert or a dialog over the page and completes with what its
/// actions pop: ui_core's [RawModalDialogRoute] (spring, focus, Escape, back,
/// barrier) holding a [RawAlertDialog] (layout, safe focus, and actions in a
/// [RawActionBar]: one row while they fit, else one column of one width
/// with the confirming action on top), drawn in the design's hand.
///
/// ```dart
/// final delete = await showTendDialog<bool>(
///   context,
///   title: 'Delete the draft?',
///   content: const Text('It cannot be brought back.'),
///   actions: (context) => [
///     RawDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
///     RawDialogAction(label: 'Delete', isDestructiveAction: true, onPressed: () => Navigator.pop(context, true)),
///   ],
/// );
/// ```
Future<T?> showTendDialog<T>(
  BuildContext context, {
  required String title,
  Widget? content,
  required List<RawDialogAction> Function(BuildContext context) actions,
  bool isAlert = true,
}) {
  final theme = TendTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  final navigator = Navigator.of(context);
  // The route builds under the navigator, not under the opener: carry the
  // opener's themes (a TendTheme nested in a page) over to it.
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push(
    RawModalDialogRoute<T>(
      isAlert: isAlert,
      barrierLabel: words.modalBarrierDismissLabel,
      barrierColor: theme.colors.ink.withValues(alpha: .32),
      dampingRatio: theme.motion.routeDampingRatio,
      stiffness: theme.motion.routeStiffness,
      builder: (context, details) => themes.wrap(
        FadeTransition(
          opacity: details.animation,
          child: RawAlertDialog(
            title: title,
            content: content,
            actions: actions(context),
            titleBuilder: (context, title) => Text(title, style: theme.title),
            frameBuilder: (context, frame, child) => TendSurface(
              face: TendFace(
                fill: theme.colors.surface,
                rule: theme.colors.rule,
                foreground: theme.colors.ink,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.radius * 1.5),
              ),
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
            // A gap on the grid between the words and the actions, and a
            // rule over the actions while the words scroll under them.
            actionsBuilder: (context, frame, bar) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: frame.overflows
                        ? theme.colors.rule
                        : const Color(0x00000000),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: bar,
              ),
            ),
            // The dialog makes each action's press and lays the actions
            // out; the design draws each face.
            actionBuilder: (context, action, details) => AnimatedTendSurface(
              face: tendButtonFace(
                theme,
                details.states,
                variant: details.index == details.count - 1
                    ? TendButtonVariant.filled
                    : TendButtonVariant.outlined,
                destructive: action.isDestructiveAction,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.radius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RawControlBox(
                  minHeight: theme.controlHeight,
                  child: RawCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(action.label, style: theme.label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Raises a sheet from the foot of the screen with [title], [content] and
/// the design's own buttons as [actions]: ui_core's [RawBottomSheetRoute]
/// (spring, drag, Escape, back, barrier, focus) holding the design's panel,
/// its actions laid out by [RawActionBar] as a dialog's are.
///
/// ```dart
/// showTendSheet<void>(
///   context,
///   title: 'Share the list',
///   actions: (context) => [
///     TendButton('Cancel', variant: TendButtonVariant.outlined, onPressed: () => Navigator.pop(context)),
///     TendButton('Copy link', onPressed: () => Navigator.pop(context)),
///   ],
/// );
/// ```
Future<T?> showTendSheet<T>(
  BuildContext context, {
  required String title,
  Widget? content,
  required List<Widget> Function(BuildContext context) actions,
}) {
  final theme = TendTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  final navigator = Navigator.of(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push(
    RawBottomSheetRoute<T>(
      semanticLabel: title,
      barrierLabel: words.modalBarrierDismissLabel,
      barrierColor: theme.colors.ink.withValues(alpha: .32),
      dampingRatio: theme.motion.routeDampingRatio,
      stiffness: theme.motion.routeStiffness,
      builder: (context, details) => themes.wrap(
        TendSurface(
          face: TendFace(
            fill: theme.colors.surface,
            rule: theme.colors.rule,
            foreground: theme.colors.ink,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(theme.radius * 1.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: theme.title),
                  ),
                  if (content != null) ...[const SizedBox(height: 12), content],
                  const SizedBox(height: 24),
                  // The design's own buttons, laid out as a dialog's.
                  RawActionBar(
                    spacing: 12,
                    overflowSpacing: 12,
                    children: actions(context),
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

/// Raises a panel over the page that is not a dialog (a search over the
/// page, a picture shown large) and completes with what it pops: ui_core's
/// [RawModalRoute] (spring, focus, Escape, back, barrier, Tab kept inside),
/// whose page states no role. A screen reader hears the panel's own words,
/// its heading first, where a [RawModalDialogRoute] would call it a dialog.
///
/// ```dart
/// showTendPanel<void>(
///   context,
///   title: 'Search the notes',
///   builder: (context, close) => TendButton('Done', onPressed: close),
/// );
/// ```
Future<T?> showTendPanel<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, VoidCallback close) builder,
}) {
  final theme = TendTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  final navigator = Navigator.of(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push(
    // A modal page with no role: the route scopes what a reader hears, and
    // the panel's heading names it.
    RawModalRoute<T>(
      barrierLabel: words.modalBarrierDismissLabel,
      barrierColor: theme.colors.ink.withValues(alpha: .32),
      dampingRatio: theme.motion.routeDampingRatio,
      stiffness: theme.motion.routeStiffness,
      builder: (context, details) => themes.wrap(
        FadeTransition(
          opacity: details.animation,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: TendSurface(
                    face: TendFace(
                      fill: theme.colors.surface,
                      rule: theme.colors.rule,
                      foreground: theme.colors.ink,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme.radius * 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The heading names the route, as a page's title
                          // does.
                          Semantics(
                            header: true,
                            namesRoute: true,
                            child: Text(title, style: theme.title),
                          ),
                          const SizedBox(height: 16),
                          builder(context, details.close),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Shows the design's toasts over [child], the app: ui_core's [RawToaster]
/// (the queue, the time, the swipe, F6 and Escape, what a screen reader
/// hears), each toast on the design's dark plate. Put it in the app's
/// builder, under the design's theme and over every route.
///
/// ```dart
/// TendToaster.of(context).show(const RawToast(message: 'Draft saved'));
/// ```
class TendToaster extends StatelessWidget {
  /// Toasts over [child].
  const TendToaster({super.key, required this.child});

  /// The app.
  final Widget child;

  /// The nearest toaster, to show a toast with.
  static RawToasterState of(BuildContext context) => RawToaster.of(context);

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    final c = theme.colors;
    return RawToaster(
      dampingRatio: theme.motion.routeDampingRatio,
      stiffness: theme.motion.routeStiffness,
      toastBuilder: (context, details) => AnimatedBuilder(
        animation: details.animation,
        // The presence spring may pass 1; an opacity stays within 0 and 1.
        builder: (context, toast) => Opacity(
          opacity: details.animation.value.clamp(0.0, 1.0),
          child: toast,
        ),
        child: TendSurface(
          face: TendFace(fill: c.ink, rule: c.ink, foreground: c.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      details.toast.message,
                      style: theme.body.copyWith(color: c.surface),
                    ),
                  ),
                ),
                if (details.runAction case final act?)
                  _ToastAction(
                    label: details.toast.actionLabel!,
                    onPressed: act,
                  ),
              ],
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// A toast's action ("Undo"): its words on the toast's plate, under a rule
/// that shows with the keyboard's focus, as every rule of the design does.
class _ToastAction extends StatelessWidget {
  const _ToastAction({required this.label, required this.onPressed});

  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    final c = theme.colors;
    return TapTargetPadding(
      child: RawButton(
        onPressed: onPressed,
        builder: (context, states, _) => AnimatedTendSurface(
          face: TendFace(
            fill: states.contains(WidgetState.pressed)
                ? Color.alphaBlend(c.surface.withValues(alpha: .16), c.ink)
                : c.ink,
            rule: states.contains(WidgetState.focused) ? c.surface : c.ink,
            ruleWidth: 2,
            foreground: c.surface,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius / 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RawControlBox(
              minHeight: 36,
              child: RawCapCenter(
                capHeightFactor: theme.capHeightFactor,
                child: Text(
                  label,
                  style: theme.label.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bar along the foot of a page (its actions, a composer): the design's
/// surface under a rule. It keeps the design's toasts clear of it
/// ([RawToasterKeepClear]), so a toast never covers what it holds, and
/// takes the screen's bottom inset itself.
///
/// ```dart
/// TendBottomBar(child: TendButton('Send', onPressed: () {}))
/// ```
class TendBottomBar extends StatelessWidget {
  /// A bar holding [child].
  const TendBottomBar({super.key, required this.child});

  /// What the bar holds.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    // The toasts stand above the bar, and follow it as it comes and goes.
    return RawToasterKeepClear(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colors.surface,
          border: Border(top: BorderSide(color: theme.colors.rule)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
