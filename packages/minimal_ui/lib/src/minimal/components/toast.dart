/// A passing confirmation at the screen's foot, painted on ui_core's
/// toaster.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'pressable.dart';
import 'shell_frame.dart' show MinimalShellInsets;

/// Transient bottom notification — a confirmation the page does not have to
/// hold, with one optional inline action (the undo pattern). Minimal
/// draws it as a compact card ([MinimalSnackBar]): the surface on a hairline
/// with a menu's shadow, an optional glyph, 13 px text, the action in the
/// accent's ink. It fades in and rises 4 px, and stands above the keyboard
/// and any bar along the foot (a [MinimalNavigationBar], a
/// [MinimalScaffold.footer]), following a bar that slides in or away. One
/// toast stands at a time: a new one replaces the
/// one showing.
///
/// [actionLabel] + [onAction] add ONE inline action — the undo pattern.
/// The card then lingers longer (a reversible action the user cannot
/// reach in time is not reversible) and closes once it runs. Its time
/// stops while a pointer rests on it or the keyboard is in it; F6 takes the
/// keyboard to it and back, Escape or a swipe sideways dismisses it, and a
/// screen reader hears it. The behaviour is ui_core's ([RawToaster]),
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
  final toaster = context.findAncestorStateOfType<_MinimalToasterState>();
  // A toaster above the page knows the bars along its foot (they report to it
  // through RawToasterKeepClear). The root overlay's fallback is above no bar,
  // so it stands over the shell's bar as the shell publishes it.
  final show = toaster == null
      ? _rootToaster(context, MinimalShellInsets.of(context))
      : toaster._show;
  show(
    RawToast(
      message: message,
      actionLabel: actionLabel,
      onAction: actionLabel == null ? null : (onAction ?? () {}),
      duration: actionLabel == null
          ? MinimalChromeMetrics.toast
          : MinimalChromeMetrics.toastWithAction,
      id: _oneAtATime,
      data: _ToastLook(icon, style),
    ),
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

void Function(RawToast toast) _rootToaster(BuildContext context, double floor) {
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
  if (known != null) return (toast) => known._show(toast, floor);
  // The entry builds next frame; the first toast waits for it.
  return (toast) => WidgetsBinding.instance.addPostFrameCallback(
    (_) => key?.currentState?._show(toast, floor),
  );
}

/// Hosts Minimal's toasts over [child]: [MinimalHost] installs one above
/// the app's navigator, so a page needs nothing of its own. The toasts
/// stand at the foot, centred, at most 560 px wide, inset by the gutter and
/// lifted over the keyboard and over any bar along the foot that ui_core's
/// `RawToasterKeepClear` marks (Minimal's navigation bar and scaffold
/// footer are marked). The behaviour is ui_core's
/// ([RawToaster]); Minimal paints each toast as a [MinimalSnackBar].
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
  final GlobalKey<RawToasterState> _toaster = GlobalKey();

  // How far the fallback toaster's toasts stand up from the foot: the shell's
  // bar, which reports to no toaster below it.
  double _floor = 0;

  void _show(RawToast toast, [double floor = 0]) {
    if (floor != _floor) setState(() => _floor = floor);
    _toaster.currentState?.show(toast);
  }

  Widget _toast(BuildContext context, RawToastDetails v) {
    final t = context.minimalTheme;
    final data = v.toast.data;
    final look = data is _ToastLook ? data : const _ToastLook(null, null);
    final shape = MinimalStyleOf([
      look.style,
      t.components.snackBar,
    ], const {}).outline(t, RawCorner.medium);
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
    // A bar along the foot (a tab bar, a page's footer) keeps the toasts
    // above it through ui_core's RawToasterKeepClear; the keyboard, less the
    // safe area the toaster keeps, lifts them here.
    final bottom =
        math.max(
          math.max(_floor, media.viewInsets.bottom) - media.padding.bottom,
          0.0,
        ) +
        MinimalChromeMetrics.floatingGap;
    return RawToaster(
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
    final shape = so.outline(t, RawCorner.medium);
    final padding =
        so.paddingIn(context) ??
        const EdgeInsetsDirectional.only(
          start: MinimalSpacing.s12,
          end: MinimalSpacing.s4,
        );
    final direction = Directionality.of(context);
    final edges = padding.resolve(direction);
    final end = direction == TextDirection.ltr ? edges.right : edges.left;
    final row = Row(
      crossAxisAlignment: actionLabel == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[
          Center(
            widthFactor: 1,
            heightFactor: 1,
            child: MinimalIcon(icon, size: MinimalIconSize.i16, color: ink),
          ),
          const MinimalGap(MinimalSpacing.s8),
        ],
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
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
        ),
        if (actionLabel != null)
          MinimalGroundFill(
            fill: so.fill ?? t.card,
            child: MinimalPressable(
              onPressed: onAction ?? () {},
              focusInside: true,
              shape: MinimalShapes.inset(shape, rim.strokeInset + end),
              // Paint inside the action's full-height touch target.
              outset: EdgeInsets.only(
                top: -math.max(0.0, end - edges.top),
                bottom: -math.max(0.0, end - edges.bottom),
              ),
              tapTarget: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: minimalTapFloor(context),
                  minHeight: minimalTapFloor(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinimalSpacing.s8,
                    vertical: MinimalChromeMetrics.toastActionPad,
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: minimalCapLabel(
                      Text(
                        actionLabel,
                        style: t.bodySmall.medium.c(t.primaryInk),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const MinimalGap(MinimalSpacing.s8),
      ],
    );
    return Container(
      constraints: BoxConstraints(
        minHeight: MinimalChromeMetrics.row + 2 * rim.width,
      ),
      padding: padding,
      decoration: minimalFrame(
        shape,
        fill: so.fill ?? t.card,
        side: rim,
        shadows: t.shadowMd,
      ),
      child: actionLabel == null ? row : IntrinsicHeight(child: row),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onAction', onAction))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      );
  }
}
