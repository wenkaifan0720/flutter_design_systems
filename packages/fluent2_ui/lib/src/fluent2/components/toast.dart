import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellInsets;
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../icons.dart';
import '../internal/footer_band.dart';
import '../localizations.dart';
import '../styled.dart';
import '../theme.dart';
import 'host.dart';
import 'pressable/pressable.dart';

/// What a snack bar says it is, Fluent's toast `intent`: each wears its
/// status glyph in its ink.
enum Fluent2ToastIntent {
  /// It worked.
  success,

  /// Something to know.
  info,

  /// Something to watch.
  warning,

  /// It failed.
  error,
}

/// A handle on a raised snack bar: take it down, or wait for it to leave.
abstract interface class Fluent2Raised {
  /// Takes it down, shown or waiting.
  void dismiss();

  /// Completes when it has left.
  Future<void> get closed;
}

class _Queued implements Fluent2Raised {
  _Queued(this.handle);

  final DesignToastHandle handle;

  @override
  void dismiss() => handle.dismiss();

  @override
  Future<void> get closed => handle.closed;
}

class _Overlaid implements Fluent2Raised {
  final Completer<void> _left = Completer();
  VoidCallback? remove;

  @override
  void dismiss() {
    remove?.call();
    remove = null;
    if (!_left.isCompleted) _left.complete();
  }

  @override
  Future<void> get closed => _left.future;
}

_Overlaid? _up;

/// Raises a short notice over the page, Fluent 2's Toast. Under a
/// [Fluent2Toaster] it queues there, after any already showing; with no
/// toaster it stands alone: a new one replaces the one still up, gutter to
/// gutter 16 over the tab bar on a phone, 292 wide at the window's bottom
/// end on the desktop. It stays for [duration] (three seconds, six with
/// its one inline action) and a tap on the action takes it down.
///
/// ```dart
/// showFluent2Toast(context, 'File moved to Archive', actionLabel: 'Undo', onAction: undo)
/// ```
Fluent2Raised showFluent2Toast(
  BuildContext context,
  String message, {
  String? title,
  Fluent2ToastIntent tone = Fluent2ToastIntent.success,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  final stays = duration ?? Duration(seconds: actionLabel == null ? 3 : 6);
  final toaster = DesignToaster.maybeOf(context);
  if (toaster != null) {
    return _Queued(
      toaster.show(
        DesignToast(
          message: message,
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
          duration: stays,
          data: tone,
        ),
      ),
    );
  }
  final moves = Fluent2Motion.on(context);
  final wide = Fluent2Layout.isWide(context);
  final overlay = Fluent2Host.navigatorOf(context).overlay!;
  final double bottom;
  if (wide) {
    bottom = Fluent2ChromeMetrics.toastGap;
  } else {
    final stands = math.max(
      ShellInsets.of(context),
      Fluent2BottomStand.reachOf(
        context,
        overlay.context.findRenderObject()! as RenderBox,
      ),
    );
    bottom = stands > 0
        ? stands + Fluent2ChromeMetrics.toastGap
        : MediaQuery.paddingOf(overlay.context).bottom +
              Fluent2ChromeMetrics.toastGap;
  }
  _up?.dismiss();
  final handle = _Overlaid();
  _up = handle;
  final timer = Timer(stays, handle.dismiss);
  final themes = InheritedTheme.capture(from: context, to: overlay.context);
  final card = Semantics(
    container: true,
    liveRegion: true,
    child: Fluent2Toast(
      message,
      title: title,
      tone: tone,
      actionLabel: actionLabel,
      onAction: actionLabel == null
          ? null
          : () {
              handle.dismiss();
              onAction?.call();
            },
    ),
  );
  final entry = OverlayEntry(
    builder: (_) => PositionedDirectional(
      bottom: bottom,
      start: wide ? null : Fluent2ChromeMetrics.gutter,
      end: wide ? Fluent2ChromeMetrics.toastGap : Fluent2ChromeMetrics.gutter,
      width: wide ? Fluent2ChromeMetrics.toastWidth : null,
      child: themes.wrap(
        IgnorePointer(
          ignoring: actionLabel == null,
          child: !moves
              ? card
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Fluent2Motion.normal,
                  curve: Fluent2Motion.decelerateMid,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, (1 - v) * 16),
                      child: child,
                    ),
                  ),
                  child: card,
                ),
        ),
      ),
    ),
  );
  handle.remove = () {
    timer.cancel();
    entry.remove();
    entry.dispose();
    if (identical(_up, handle)) _up = null;
  };
  overlay.insert(entry);
  return handle;
}

/// Where snack bars queue, over the whole app: up to [maxVisible] at its
/// foot, the newest nearest; the pointer resting on one, or the focus in
/// it, holds its time, and F6 reaches them from anywhere. Put it once
/// around the app, inside the theme; [showFluent2Toast] finds it from
/// anywhere below.
///
/// ```dart
/// MaterialApp(builder: (context, child) => Fluent2Theme(data: theme, child: Fluent2Toaster(child: child!)))
/// ```
class Fluent2Toaster extends StatelessWidget {
  /// A queue of snack bars over [child].
  const Fluent2Toaster({super.key, required this.child, this.maxVisible = 3});

  /// The app.
  final Widget child;

  /// How many show at once; the rest wait their turn.
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final wide = Fluent2Layout.isWide(context);
    return DesignToaster(
      maxVisible: maxVisible,
      regionLabel: Fluent2Localizations.of(context).notifications,
      alignment: wide
          ? AlignmentDirectional.bottomEnd
          : AlignmentDirectional.bottomCenter,
      constraints: BoxConstraints(
        maxWidth: wide ? Fluent2ChromeMetrics.toastWidth : 560,
      ),
      toastBuilder: (context, v) => AnimatedBuilder(
        animation: v.animation,
        builder: (context, toast) {
          final p = v.animation.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: p,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - p)),
              child: toast,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(top: Fluent2Spacing.s),
          child: Fluent2Toast(
            v.toast.message,
            title: v.toast.title,
            tone: v.toast.data is Fluent2ToastIntent
                ? v.toast.data! as Fluent2ToastIntent
                : Fluent2ToastIntent.success,
            actionLabel: v.toast.actionLabel,
            onAction: v.runAction,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// A snack bar's face, drawn in place: the [tone]'s glyph (16) in its ink,
/// the [title] in body1Strong over the [message] in body1 (the message
/// alone in body1Strong), the one action's link ([actionLabel]) at the end,
/// on the surface card in `shadow8`, its corners 4, 12 round its parts. A
/// page notifies through [showFluent2Toast], never by standing this in
/// its body.
///
/// ```dart
/// Fluent2Toast('File moved to Archive', actionLabel: 'Undo', onAction: undo)
/// ```
class Fluent2Toast extends StatelessWidget {
  /// A snack bar saying [message].
  const Fluent2Toast(
    this.message, {
    super.key,
    this.title,
    this.tone = Fluent2ToastIntent.success,
    this.actionLabel,
    this.onAction,
  });

  /// What it says.
  final String message;

  /// A line over [message], when it has one.
  final String? title;

  /// What it says it is.
  final Fluent2ToastIntent tone;

  /// The one inline action's words.
  final String? actionLabel;

  /// What the action does.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final (IconData glyph, Color ink) = switch (tone) {
      Fluent2ToastIntent.success => (
        Fluent2Icons.checkmarkCircleFilled,
        t.colors.statusSuccessForeground1,
      ),
      Fluent2ToastIntent.info => (
        Fluent2Icons.infoFilled,
        t.colors.neutralForeground2,
      ),
      Fluent2ToastIntent.warning => (
        Fluent2Icons.warningFilled,
        t.colors.statusWarningForeground3,
      ),
      Fluent2ToastIntent.error => (
        Fluent2Icons.errorCircleFilled,
        t.colors.statusDangerForeground1,
      ),
    };
    final head = title;
    final label = actionLabel;
    final look = Fluent2StyleOf([t.toastTheme], const {});
    return Material(
      type: MaterialType.transparency,
      child: Fluent2Plate(
        fill: look.fill ?? t.colors.neutralBackground1,
        side: fluent2Rim(
          t,
          look,
          t.isDark ? t.colors.neutralStroke2 : t.colors.transparentStroke,
        ),
        radius: BorderRadius.circular(Fluent2Radius.medium),
        shape: look.shape,
        shadows: t.shadows.shadow8,
        padding:
            look.padding(Directionality.of(context)) ??
            const EdgeInsets.all(Fluent2ChromeMetrics.toastPadding),
        child: DefaultTextStyle(
          style: t.body1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Fluent2Spacing.s,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  glyph,
                  size: Fluent2ChromeMetrics.toastGlyph,
                  color: ink,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Fluent2Spacing.xs,
                  children: [
                    if (head != null) Text(head, style: t.body1Strong),
                    Text(
                      message,
                      style: head == null ? t.body1Strong : t.body1,
                    ),
                  ],
                ),
              ),
              if (label != null)
                Fluent2Pressable(
                  onPressed: onAction,
                  label: label,
                  radius: Fluent2Radius.small,
                  builder: (context, states) => Text(
                    label,
                    maxLines: 1,
                    style: t.body1Strong.c(
                      states.press.pick(
                        t.colors.brandForegroundLink,
                        t.colors.brandForegroundLinkHover,
                        t.colors.brandForegroundLinkPressed,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
