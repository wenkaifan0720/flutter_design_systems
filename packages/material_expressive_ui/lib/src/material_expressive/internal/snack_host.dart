/// The host's snackbars: ui_core's [RawToaster] in [ExpressiveHost], each
/// toast painted as Compose's `SnackbarHost` paints its snackbar.
/// Internal: the barrel never exports it.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../components/toast.dart';
import '../motion.dart';
import 'tokens/behavior.g.dart';

/// What a snackbar carries to the host beyond its words and its action.
class ExpressiveSnackData {
  /// The parts [showExpressiveSnackBar] was given.
  const ExpressiveSnackData({
    required this.style,
    required this.withDismissAction,
    required this.actionOnNewLine,
    required this.themes,
  });

  /// The snackbar's component style.
  final ExpressiveComponentThemeData? style;

  /// Whether it shows its close button.
  final bool withDismissAction;

  /// Whether its action stands under a long message.
  final bool actionOnNewLine;

  /// The themes where it was raised, to paint it in.
  final CapturedThemes themes;
}

/// Each toaster's snackbars not yet closed, oldest first: the first is the
/// one showing, or the next to show while the last leaves.
final Expando<List<RawToastController>> expressiveSnackBars =
    Expando<List<RawToastController>>('ExpressiveSnackBar');

/// The toaster [ExpressiveHost] mounts over the app: Compose's
/// `SnackbarHostState`, one snackbar at a time, in order, at the bottom
/// centre. The shell's bar and action, a screen's docked footer and the
/// keyboard keep it clear ([RawToasterKeepClear]). Its presence spring is
/// the fade's (`SnackbarHostBehavior.opacityMotion`), so a snackbar leaves
/// its place as its fade ends. Toasts stand in an app: a host with no
/// direction or media above it (outside `WidgetsApp`) mounts none.
class ExpressiveSnackBarHost extends StatelessWidget {
  /// A toaster over [child].
  const ExpressiveSnackBarHost({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Directionality.maybeOf(context) == null ||
        MediaQuery.maybeOf(context) == null) {
      return child;
    }
    final fade = ExpressiveMotion.of(context)
        .tokenOf(SnackbarHostBehavior.opacityMotion);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return RawToaster(
      // Material's `ScaffoldMessenger`: one shown, the rest in order.
      maxVisible: 1,
      padding: EdgeInsets.zero,
      // The snackbar keeps its own width (`containerMaxWidth`) and margin.
      constraints: const BoxConstraints(),
      // Compose's snackbar takes no swipe; neither did 0.4.1's.
      swipeDirection: DismissDirection.none,
      dampingRatio: fade.dampingRatio,
      stiffness: fade.stiffness,
      toastBuilder: _paint,
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          child,
          // The keyboard keeps the snackbar above it, as it did a
          // snackbar's place in 0.4.1.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: keyboard,
            child: const IgnorePointer(
              child: RawToasterKeepClear(child: SizedBox.expand()),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _paint(BuildContext context, RawToastDetails details) {
    final toast = details.toast;
    final data = toast.data! as ExpressiveSnackData;
    return ExpressiveSnackBarTransition(
      // The toaster wraps a leaving toast anew (out of reach of pointer and
      // focus): the key keeps its fade and scale going from where they are.
      key: GlobalObjectKey(toast),
      visible: !details.exiting,
      // `Snackbar(snackbarData)`'s margin, centred as `Scaffold` places
      // the host.
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Padding(
          padding: const EdgeInsets.all(SnackbarBehavior.margin),
          child: data.themes.wrap(
            ExpressiveSnackBar(
              toast.message,
              style: data.style,
              actionLabel: toast.actionLabel,
              onAction: details.runAction,
              withDismissAction: data.withDismissAction,
              onDismiss: details.dismiss,
              actionOnNewLine: data.actionOnNewLine,
            ),
          ),
        ),
      ),
    );
  }
}
