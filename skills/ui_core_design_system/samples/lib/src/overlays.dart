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
    return RawTooltipPlacement(
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
/// barrier) holding a [RawAlertDialog] (layout, safe focus, stacked actions
/// when they do not fit), drawn in the look's hand.
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
            // The dialog makes each action's press; the look draws its face.
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
