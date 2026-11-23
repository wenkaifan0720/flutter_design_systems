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
/// LookTooltip(message: 'Archive', child: LookButton('Archive', onPressed: () {}))
/// ```
class LookTooltip extends StatelessWidget {
  /// Names [child] with [message].
  const LookTooltip({super.key, required this.message, required this.child});

  /// The words.
  final String message;

  /// The control they name.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
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
            child: LookSurface(
              face: LookFace(
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
/// actions pop: ui_core's [DesignDialogRoute] (spring, focus, Escape, back,
/// barrier) holding a [RawAlertDialog] (layout, safe focus, and actions in a
/// [RawActionBar]: one row while they fit, else one column of one width
/// with the confirming action on top), drawn in the look's hand.
///
/// ```dart
/// final delete = await showLookDialog<bool>(
///   context,
///   title: 'Delete the draft?',
///   content: const Text('It cannot be brought back.'),
///   actions: (context) => [
///     RawDialogAction(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
///     RawDialogAction(label: 'Delete', isDestructiveAction: true, onPressed: () => Navigator.pop(context, true)),
///   ],
/// );
/// ```
Future<T?> showLookDialog<T>(
  BuildContext context, {
  required String title,
  Widget? content,
  required List<RawDialogAction> Function(BuildContext context) actions,
  bool isAlert = true,
}) {
  final theme = LookTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  final navigator = Navigator.of(context);
  // The route builds under the navigator, not under the opener: carry the
  // opener's themes (a LookTheme nested in a page) over to it.
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push(
    DesignDialogRoute<T>(
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
            frameBuilder: (context, frame, child) => LookSurface(
              face: LookFace(
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
            // out; the look draws each face.
            actionBuilder: (context, action, details) => AnimatedLookSurface(
              face: lookButtonFace(
                theme,
                details.states,
                variant: details.index == details.count - 1
                    ? LookButtonVariant.filled
                    : LookButtonVariant.outlined,
                destructive: action.isDestructiveAction,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.radius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DesignControlBox(
                  minHeight: theme.controlHeight,
                  child: DesignCapCenter(
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
/// the look's own buttons as [actions]: ui_core's [RawBottomSheetRoute]
/// (spring, drag, Escape, back, barrier, focus) holding the look's panel,
/// its actions laid out by [RawActionBar] as a dialog's are.
///
/// ```dart
/// showLookSheet<void>(
///   context,
///   title: 'Share the list',
///   actions: (context) => [
///     LookButton('Cancel', variant: LookButtonVariant.outlined, onPressed: () => Navigator.pop(context)),
///     LookButton('Copy link', onPressed: () => Navigator.pop(context)),
///   ],
/// );
/// ```
Future<T?> showLookSheet<T>(
  BuildContext context, {
  required String title,
  Widget? content,
  required List<Widget> Function(BuildContext context) actions,
}) {
  final theme = LookTheme.of(context);
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
        LookSurface(
          face: LookFace(
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
                  // The look's own buttons, given dismissive first and
                  // confirming last. The bar keeps them in one row while
                  // they fit; else it stacks them, each as wide as the
                  // sheet, the confirming one on top.
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
/// its heading first, where a [DesignDialogRoute] would call it a dialog.
///
/// ```dart
/// showLookPanel<void>(
///   context,
///   title: 'Search the notes',
///   builder: (context, close) => LookButton('Done', onPressed: close),
/// );
/// ```
Future<T?> showLookPanel<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, VoidCallback close) builder,
}) {
  final theme = LookTheme.of(context);
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
                  child: LookSurface(
                    face: LookFace(
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

/// Shows the look's toasts over [child], the app: ui_core's [RawToaster]
/// (the queue, the time, the swipe, F6 and Escape, what a screen reader
/// hears), each toast on the look's dark plate. Put it in the app's
/// builder, under the look's theme and over every route.
///
/// ```dart
/// LookToaster.of(context).show(const RawToast(message: 'Draft saved'));
/// ```
class LookToaster extends StatelessWidget {
  /// Toasts over [child].
  const LookToaster({super.key, required this.child});

  /// The app.
  final Widget child;

  /// The nearest toaster, to show a toast with.
  static RawToasterState of(BuildContext context) => RawToaster.of(context);

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
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
        child: LookSurface(
          face: LookFace(fill: c.ink, rule: c.ink, foreground: c.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              details.toast.message,
              style: theme.body.copyWith(color: c.surface),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// A bar along the foot of a page (its actions, a composer): the look's
/// surface under a rule. It keeps the look's toasts clear of it
/// ([RawToasterKeepClear]), so a toast never covers what it holds, and
/// takes the screen's bottom inset itself.
///
/// ```dart
/// LookBottomBar(child: LookButton('Send', onPressed: () {}))
/// ```
class LookBottomBar extends StatelessWidget {
  /// A bar holding [child].
  const LookBottomBar({super.key, required this.child});

  /// What the bar holds.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = LookTheme.of(context);
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
