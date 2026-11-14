/// A passing confirmation at the screen's foot, painted on ui_core's
/// toaster.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/kit_paint.dart';
import '../internal/page_foot.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'pressable.dart';
import 'shell_frame.dart';

/// Transient bottom notification — a confirmation the page does not have to
/// hold, with one optional inline action (the undo pattern). Minimal
/// draws it as a compact card ([MinimalSnackBar]): the surface on a hairline
/// with a menu's shadow, an optional glyph, 13 px text, the action in the
/// accent's ink. It fades in and rises 4 px, and stands above the shell's
/// bar and the keyboard. One toast stands at a time: a new one replaces the
/// one showing.
///
/// [actionLabel] + [onAction] add ONE inline action — the undo pattern.
/// The card then lingers longer (a reversible action the user cannot
/// reach in time is not reversible) and closes once it runs. Its time
/// stops while a pointer rests on it or the keyboard is in it; F6 takes the
/// keyboard to it and back, Escape or a swipe sideways dismisses it, and a
/// screen reader hears it. The behaviour is ui_core's ([DesignToaster]),
/// installed by [MinimalHost] ([MinimalToaster]); Minimal paints it.
///
/// ```dart
/// showMinimalSnackBar(context, 'Habit archived', actionLabel: 'Undo', onAction: restore);
/// ```
void showMinimalSnackBar(
  BuildContext context,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  MinimalStyle? style,
}) {
  // The shell publishes its bar's height through MinimalShellInsets, read
  // here at the caller: the toaster stands above the navigator, where no
  // shell is in sight. A page's own foot (its Create, its Save) lifts the
  // toast too, so a toast never covers the act that raised it.
  final lift = math.max(
    MinimalShellInsets.of(context),
    MinimalPageFoot.liftOf(context),
  );
  final show =
      context.findAncestorStateOfType<_MinimalToasterState>()?._show ??
      _rootToaster(context);
  show(
    DesignToast(
      message: message,
      actionLabel: actionLabel,
      onAction: actionLabel == null ? null : (onAction ?? () {}),
      duration: actionLabel == null
          ? MinimalChromeMetrics.toast
          : MinimalChromeMetrics.toastWithAction,
      id: _oneAtATime,
      data: _ToastLook(icon, style),
    ),
    lift,
  );
}

/// Every Minimal toast's id: a new one replaces the one showing.
const Object _oneAtATime = #minimalToast;

/// What a toast's card wears beyond its words.
@immutable
class _ToastLook {
  const _ToastLook(this.icon, this.style);

  final IconData? icon;
  final MinimalStyle? style;
}

/// A toaster of the app's root overlay, for a caller with no
/// [MinimalToaster] above it (a page composed without [MinimalHost]).
final Expando<GlobalKey<_MinimalToasterState>> _fallbacks = Expando();

void Function(DesignToast toast, double lift) _rootToaster(
  BuildContext context,
) {
  final overlay = Overlay.of(context, rootOverlay: true);
  var key = _fallbacks[overlay];
  if (key == null) {
    final made = key = GlobalKey<_MinimalToasterState>();
    _fallbacks[overlay] = made;
    final fallback = context.minimalTheme;
    overlay.insert(
      OverlayEntry(
        builder: (context) {
          final toaster = MinimalToaster(
            key: made,
            child: const SizedBox.expand(),
          );
          return MinimalTheme.maybeOf(context) == null
              ? MinimalTheme(data: fallback, child: toaster)
              : toaster;
        },
      ),
    );
  }
  final known = key.currentState;
  if (known != null) return known._show;
  // The entry builds next frame; the first toast waits for it.
  return (toast, lift) => WidgetsBinding.instance.addPostFrameCallback(
    (_) => key?.currentState?._show(toast, lift),
  );
}

/// Hosts Minimal's toasts over [child]: [MinimalHost] installs one above
/// the app's navigator, so a page needs nothing of its own. The toasts
/// stand at the foot, centred, at most 560 px wide, inset by the gutter and
/// lifted over the shell's bar and the keyboard. The behaviour is ui_core's
/// ([DesignToaster]); Minimal paints each toast as a [MinimalSnackBar].
///
/// ```dart
/// MinimalToaster(child: app)
/// ```
class MinimalToaster extends StatefulWidget {
  /// A toaster over [child].
  const MinimalToaster({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  State<MinimalToaster> createState() => _MinimalToasterState();
}

class _MinimalToasterState extends State<MinimalToaster> {
  final GlobalKey<DesignToasterState> _toaster = GlobalKey();
  double _lift = 0;

  void _show(DesignToast toast, double lift) {
    if (lift != _lift) setState(() => _lift = lift);
    _toaster.currentState?.show(toast);
  }

  Widget _toast(BuildContext context, DesignToastDetails v) {
    final t = context.minimalTheme;
    final data = v.toast.data;
    final look = data is _ToastLook ? data : const _ToastLook(null, null);
    final shape =
        MinimalStyleOf([look.style, t.components.snackBar], const {}).shape ??
        t.shapes.medium;
    final still = context.minimalStill;
    return AnimatedBuilder(
      animation: v.animation,
      builder: (context, child) {
        final p = v.animation.value;
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              0,
              still ? 0 : (1 - math.min(p, 1.0)) * MinimalSpacing.s4,
            ),
            child: child,
          ),
        );
      },
      // Toasts stand outside any page Scaffold; the transparent Material
      // supplies the text defaults the card would otherwise lack.
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          foregroundDecoration: v.focused
              ? minimalStateLayer(t, shape, const {
                  WidgetState.focused,
                }, ground: minimalGround(context))
              : null,
          child: MinimalSnackBar(
            v.toast.message,
            icon: look.icon,
            actionLabel: v.toast.actionLabel,
            onAction: v.runAction,
            style: look.style,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // The shell's allowance already spans the device inset, so the lift is
    // a max of it and the keyboard, less the safe area the toaster keeps.
    final bottom =
        math.max(
          math.max(_lift, media.viewInsets.bottom) - media.padding.bottom,
          0.0,
        ) +
        MinimalChromeMetrics.floatingGap;
    return DesignToaster(
      key: _toaster,
      maxVisible: 1,
      padding: EdgeInsets.fromLTRB(
        MinimalChromeMetrics.gutter,
        MinimalChromeMetrics.gutter,
        MinimalChromeMetrics.gutter,
        bottom,
      ),
      constraints: const BoxConstraints(maxWidth: 560),
      regionLabel: MinimalLocalizations.of(context).notifications,
      stiffness: 900,
      toastBuilder: _toast,
      child: widget.child,
    );
  }
}

/// The toast's card on its own — what [showMinimalSnackBar] floats above the
/// page, as a plain widget: the surface on a hairline with the menu shadow,
/// an optional 16 px glyph, the message in 13 px text and, with
/// [actionLabel], one action in the accent's ink. Compose it statically for
/// a specimen or a screenshot; a page confirms through [showMinimalSnackBar].
///
/// [style] dresses one card, `components.snackBar` every one: fill,
/// foreground (the message and glyph), edge or side, shape (else
/// `shapes.medium`), padding and textStyle. The action keeps the accent's
/// ink.
///
/// ```dart
/// MinimalSnackBar('Habit archived', icon: LucideIcons.archive, actionLabel: 'Undo', onAction: restore)
/// ```
class MinimalSnackBar extends StatelessWidget {
  /// A toast saying [message].
  const MinimalSnackBar(
    this.message, {
    super.key,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.style,
  });

  /// What it says.
  final String message;

  /// A glyph before the message.
  final IconData? icon;

  /// The one inline action's label (`Undo`), or null for none.
  final String? actionLabel;

  /// Its action's press.
  final VoidCallback? onAction;

  /// This card's style, over `components.snackBar`.
  final MinimalStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final icon = this.icon;
    final actionLabel = this.actionLabel;
    final so = MinimalStyleOf([style, t.components.snackBar], const {});
    final rim = so.rim(t.border, t.rim);
    final ink = so.foreground;
    return Container(
      // A touch target tall inside its rims, so the card never cuts off the
      // action's padded hit area.
      constraints: BoxConstraints(
        minHeight: MinimalLayout.minHitTarget + 2 * rim.width,
      ),
      padding:
          so.padding ??
          const EdgeInsetsDirectional.only(
            start: MinimalSpacing.s12,
            end: MinimalSpacing.s4,
          ),
      decoration: minimalFrame(
        so.shape ?? t.shapes.medium,
        fill: so.fill ?? t.card,
        side: rim,
        shadows: t.shadowMd,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            MinimalIcon(icon, size: MinimalIconSize.i16, color: ink),
            const MinimalGap(MinimalSpacing.s8),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MinimalChromeMetrics.toastPad,
              ),
              child: Text(
                message,
                style: so.text(t.bodySmall, ink ?? t.bodySmall.color!),
              ),
            ),
          ),
          if (actionLabel != null)
            MinimalGroundFill(
              fill: so.fill ?? t.card,
              child: MinimalPressable(
                onPressed: onAction ?? () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinimalSpacing.s8,
                    vertical: MinimalChromeMetrics.toastActionPad,
                  ),
                  child: minimalCapLabel(
                    Text(
                      actionLabel,
                      style: t.bodySmall.medium.c(t.primaryInk),
                    ),
                  ),
                ),
              ),
            )
          else
            const MinimalGap(MinimalSpacing.s8),
        ],
      ),
    );
  }
}
