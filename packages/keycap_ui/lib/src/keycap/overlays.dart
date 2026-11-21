/// What Keycap lays over the keyboard: a dialog (a panel of keycap plastic
/// set down over the keys, the keyboard dimmed under it), a sheet (a panel
/// sliding up from the keyboard's front edge) and a toast (a dark panel at
/// the foot).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'cap.dart';
import 'internal/spring_value.dart';
import 'theme.dart';

/// A dialog: a panel of keycap plastic laid over the keyboard, with a
/// [title], its [content] and its [actions] at the foot. Below 600 wide the
/// actions share the row; wider they stand at its end. When it confirms a
/// loss, its last action is `KeycapButton.accent(isDestructiveAction: true)`.
///
/// ```dart
/// showKeycapDialog(context: context, builder: (context) => KeycapDialog(title: 'Delete note?', actions: [KeycapButton(onPressed: keep, child: const Text('Keep')), KeycapButton.accent(isDestructiveAction: true, onPressed: delete, child: const Text('Delete'))]))
/// ```
class KeycapDialog extends StatelessWidget {
  /// A dialog.
  const KeycapDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.style,
  });

  /// The dialog's question or name.
  final String? title;

  /// What it says.
  final Widget? content;

  /// Its keys, the main one last.
  final List<Widget> actions;

  /// Overrides, over [KeycapThemeData.dialogStyle]: [DesignStyle.fill] the
  /// panel, [DesignStyle.padding] the room inside it.
  final KeycapStyle? style;

  /// The widest a dialog stands.
  static const double maxWidth = 440;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.dialogStyle], const {});
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        namesRoute: title == null ? true : null,
        label: title == null
            ? RawWidgetsLocalizations.of(context).dialogLabel
            : null,
        child: KeycapPanel(
          color: layered.fill,
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.fromLTRB(
                  KeycapSpacing.large,
                  KeycapSpacing.large,
                  KeycapSpacing.large,
                  KeycapSpacing.regular + 4,
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Semantics(
                    header: true,
                    namesRoute: true,
                    child: Text(
                      title!,
                      style: theme.textTheme.title
                          .copyWith(fontSize: 20, height: 26 / 20)
                          .merge(layered.textStyle),
                    ),
                  ),
                if (content != null) ...[
                  if (title != null)
                    const SizedBox(height: KeycapSpacing.small),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.body.copyWith(color: c.inkMuted),
                    child: content!,
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: KeycapSpacing.large),
                  LayoutBuilder(
                    builder: (context, box) {
                      const gap = KeycapSpacing.small;
                      final share = narrow
                          ? math.max(
                              0.0,
                              (box.maxWidth - gap * (actions.length - 1)) /
                                  actions.length,
                            )
                          : 0.0;
                      return OverflowBar(
                        alignment: narrow
                            ? MainAxisAlignment.spaceBetween
                            : MainAxisAlignment.end,
                        overflowAlignment: OverflowBarAlignment.end,
                        spacing: gap,
                        overflowSpacing: gap,
                        children: [
                          for (final action in actions)
                            ConstrainedBox(
                              constraints: BoxConstraints(minWidth: share),
                              child: action,
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(IntProperty('actions', actions.length));
  }
}

/// Lays [builder]'s dialog over the keyboard on the app's root navigator:
/// the keyboard dims, the panel settles down onto it, and Escape or a tap
/// on the dim (unless [barrierDismissible] is false) closes it. [isAlert]
/// marks it an alert for a screen reader.
///
/// ```dart
/// showKeycapDialog<bool>(context: context, builder: (context) => const KeycapDialog(title: 'Delete note?'))
/// ```
Future<T?> showKeycapDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool? barrierDismissible,
  bool isAlert = false,
}) {
  final theme = KeycapTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    DesignDialogRoute<T>(
      isAlert: isAlert,
      barrierDismissible: barrierDismissible,
      barrierColor: theme.colors.scrim,
      dampingRatio: KeycapMotion.panel.dampingRatio,
      stiffness: KeycapMotion.panel.stiffness,
      builder: (context, details) => KeycapTheme(
        data: theme,
        child: _ClearOfKeyboard(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(KeycapSpacing.large),
                child: _SetDown(
                  animation: details.animation,
                  child: Builder(builder: builder),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ClearOfKeyboard extends StatelessWidget {
  const _ClearOfKeyboard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: child,
    ),
  );
}

// A panel set down over the keys on the route's spring: down from 8 px
// above, from 102% of its size (it comes toward the eye, then settles),
// opaque within the first third. Under Reduce Motion the route fades it.
class _SetDown extends StatelessWidget {
  const _SetDown({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final t = animation.value;
      return Opacity(
        opacity: (t / 0.3).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -8 * (1 - t)),
          child: Transform.scale(scale: 1.02 - 0.02 * t, child: child),
        ),
      );
    },
  );
}

class _SheetScroll extends InheritedWidget {
  const _SheetScroll({required this.controller, required super.child});

  final ScrollController controller;

  static ScrollController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetScroll>()?.controller;

  @override
  bool updateShouldNotify(_SheetScroll old) => controller != old.controller;
}

class _AtTheFoot extends StatelessWidget {
  const _AtTheFoot({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    onTap: onTap,
    child: Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap == null ? null : () {},
        child: child,
      ),
    ),
  );
}

/// A sheet: a panel sliding up from the keyboard's front edge, a grip at
/// its top (pressed, or Down on it, closes the sheet), a [title], a close
/// key, its [child] scrolling, and [footer] keys sharing its foot.
///
/// ```dart
/// showKeycapSheet(context: context, builder: (context) => KeycapSheet(title: 'Move to folder', child: folders))
/// ```
class KeycapSheet extends StatelessWidget {
  /// A sheet.
  const KeycapSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.footer = const [],
    this.style,
  });

  /// What the sheet holds.
  final Widget child;

  /// Its name.
  final String? title;

  /// Called by its close key; shows one when given.
  final VoidCallback? onClose;

  /// Keys at its foot, sharing the row.
  final List<Widget> footer;

  /// Overrides, over [KeycapThemeData.dialogStyle].
  final KeycapStyle? style;

  /// The widest a sheet stands.
  static const double maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.dialogStyle], const {});
    final media = MediaQuery.of(context);
    final words = RawWidgetsLocalizations.of(context);
    const top = Radius.circular(KeycapMetrics.panelRadius);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: media.size.height * 0.9,
      ),
      child: Semantics(
        explicitChildNodes: true,
        child: KeycapPanel(
          color: layered.fill,
          radius: const BorderRadius.only(topLeft: top, topRight: top),
          child: Padding(
            padding: EdgeInsets.only(bottom: media.padding.bottom),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: KeycapSpacing.regular),
                    Padding(
                      // The close key ends on the content's edge.
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        KeycapSpacing.large,
                        KeycapSpacing.small,
                        KeycapSpacing.large,
                        0,
                      ),
                      // As high as the close key's finger floor, so the
                      // row never squeezes its target.
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            Expanded(
                              child: title == null
                                  ? const SizedBox()
                                  : Semantics(
                                      header: true,
                                      child: Text(
                                        title!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.title
                                            .copyWith(
                                              fontSize: 20,
                                              height: 26 / 20,
                                            )
                                            .merge(layered.textStyle),
                                      ),
                                    ),
                            ),
                            if (onClose != null)
                              KeycapIconButton(
                                icon: const Icon(LucideIcons.x),
                                semanticLabel: words.closeButtonLabel,
                                onPressed: onClose,
                                // A finger's floor even in the sheet's head.
                                style: const DesignStyle(
                                  minimumSize: WidgetStatePropertyAll(
                                    Size.square(44),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        controller: _SheetScroll.of(context),
                        padding:
                            layered.padding(Directionality.of(context)) ??
                            const EdgeInsets.fromLTRB(
                              KeycapSpacing.large,
                              KeycapSpacing.regular,
                              KeycapSpacing.large,
                              KeycapSpacing.large,
                            ),
                        child: child,
                      ),
                    ),
                    if (footer.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          KeycapSpacing.large,
                          0,
                          KeycapSpacing.large,
                          KeycapSpacing.large,
                        ),
                        child: Row(
                          children: [
                            for (final (i, a) in footer.indexed) ...[
                              if (i > 0)
                                const SizedBox(width: KeycapSpacing.small),
                              Expanded(child: a),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
                // The grip: a short slot cut into the panel, ui_core's
                // handle. Its target, the look's floor, sits over its middle.
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: Center(
                    child: RawBottomSheetDragHandle(
                      builder: (context, states) => TapTargetPadding(
                        alignment: AlignmentDirectional.topCenter,
                        child: SizedBox(
                          width: 48,
                          height: 24,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: KeycapSpacing.small,
                              ),
                              child: SizedBox(
                                width: 36,
                                height: 6,
                                child: KeycapWell(
                                  radius: BorderRadius.circular(3),
                                  floor: Color.lerp(c.panel, c.ground, 0.8),
                                  rim: states.contains(WidgetState.focused)
                                      ? c.focus
                                      : null,
                                  clip: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(IntProperty('footer', footer.length));
  }
}

/// Slides [builder]'s sheet up from the screen's foot on the app's root
/// navigator: the keyboard dims, a tap on the dim (unless
/// [barrierDismissible] is false), Escape or a drag down closes it.
///
/// ```dart
/// showKeycapSheet(context: context, builder: (context) => KeycapSheet(title: 'Move', child: list))
/// ```
Future<T?> showKeycapSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? semanticLabel,
}) {
  final theme = KeycapTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawBottomSheetRoute<T>(
      barrierColor: theme.colors.scrim,
      barrierDismissible: barrierDismissible,
      semanticLabel: semanticLabel,
      dampingRatio: KeycapMotion.sheet.dampingRatio,
      stiffness: KeycapMotion.sheet.stiffness,
      builder: (context, details) => KeycapTheme(
        data: theme,
        child: _SheetScroll(
          controller: details.scrollController,
          child: _AtTheFoot(
            onTap: barrierDismissible ? details.close : null,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

/// [showKeycapSheet] with a [KeycapSheet] round [builder]'s content, named
/// [title], with a close key and [footer] keys.
///
/// ```dart
/// showKeycapBottomSheet(context: context, title: 'Move to folder', builder: (context) => folders)
/// ```
Future<T?> showKeycapBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  List<Widget> footer = const [],
  bool barrierDismissible = true,
}) => showKeycapSheet<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  semanticLabel: title,
  builder: (context) => KeycapSheet(
    title: title,
    footer: footer,
    onClose: () => Navigator.of(context).maybePop(),
    child: Builder(builder: builder),
  ),
);

/// Shows [showKeycapToast]'s toasts over [child]: install it once, under
/// [KeycapTheme] (`KeycapHost` does).
///
/// ```dart
/// KeycapToaster(child: app)
/// ```
class KeycapToaster extends StatelessWidget {
  /// A toaster over [child].
  const KeycapToaster({super.key, required this.child, this.style});

  /// The app.
  final Widget child;

  /// Overrides, over [KeycapThemeData.toastStyle]: [DesignStyle.fill] the
  /// panel, [DesignStyle.foreground] its words.
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) => RawToaster(
    dampingRatio: KeycapMotion.panel.dampingRatio,
    stiffness: KeycapMotion.panel.stiffness,
    constraints: const BoxConstraints(maxWidth: 440),
    toastBuilder: (context, details) => _Toast(details, style),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<KeycapStyle>('style', style, defaultValue: null),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast(this.details, this.style);

  final RawToastDetails details;
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final t = details.toast;
    final layered = DesignStyleOf([style, theme.toastStyle], const {});
    final panel = layered.fill ?? c.toast;
    final ink = layered.foreground ?? c.onToast;
    final words = RawWidgetsLocalizations.of(context);
    // The action in the accent, lightened until it reads on the panel.
    var action = c.accent.top;
    for (var s = 0.05; s <= 1 && keycapContrast(action, panel) < 4.5;) {
      action = Color.lerp(c.accent.top, ink, s)!;
      s += 0.05;
    }
    Widget key({
      required String label,
      required VoidCallback onPressed,
      required Widget child,
    }) => RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => TapTargetPadding(
        child: KeycapSpringColor(
          color: states.contains(WidgetState.pressed)
              ? ink.withValues(alpha: 0.14)
              : ink.withValues(alpha: 0),
          darken: KeycapMotion.press,
          lighten: KeycapMotion.release,
          builder: (context, wash, child) => DecoratedBox(
            decoration: BoxDecoration(
              color: wash,
              borderRadius: BorderRadius.circular(KeycapMetrics.keyRadius),
              border: Border.all(
                color: states.contains(WidgetState.focused)
                    ? c.focus
                    : c.focus.withValues(alpha: 0),
                width: KeycapMetrics.focusWidth,
              ),
            ),
            child: child,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KeycapSpacing.small,
              ),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
    final opacity = details.animation.drive(
      Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
    );
    return FadeTransition(
      opacity: opacity,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: KeycapPanel(
          color: panel,
          radius: BorderRadius.circular(KeycapMetrics.wellRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KeycapMetrics.wellRadius),
              border: Border.all(
                color: details.focused ? c.focus : c.focus.withValues(alpha: 0),
                width: KeycapMetrics.focusWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                KeycapSpacing.regular,
                KeycapSpacing.tight,
                KeycapSpacing.tight,
                KeycapSpacing.tight,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: KeycapSpacing.small,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.title != null)
                              Text(
                                t.title!,
                                style: theme.textTheme.label.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              t.message,
                              style: theme.textTheme.body
                                  .copyWith(
                                    color: ink,
                                    fontSize: 15,
                                    height: 22 / 15,
                                  )
                                  .merge(layered.textStyle),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (t.actionLabel != null && details.runAction != null)
                      key(
                        label: t.actionLabel!,
                        onPressed: details.runAction!,
                        child: Text(
                          t.actionLabel!,
                          style: theme.textTheme.label.copyWith(
                            color: action,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    key(
                      label: words.closeButtonLabel,
                      onPressed: details.dismiss,
                      child: Icon(LucideIcons.x, size: 18, color: ink),
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
}

/// Shows a toast at the foot of the screen: [message] (and a [title]),
/// with an [actionLabel] key calling [onAction]. It leaves after
/// [duration]; null keeps it until it is closed.
///
/// ```dart
/// showKeycapToast(context, 'Note moved to Work', actionLabel: 'Undo', onAction: undo)
/// ```
RawToastController showKeycapToast(
  BuildContext context,
  String message, {
  String? title,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration = const Duration(seconds: 4),
}) => RawToaster.of(context).show(
  RawToast(
    message: message,
    title: title,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  ),
);
