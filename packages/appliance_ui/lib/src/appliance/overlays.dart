/// Appliance's overlays: [ApplianceDialog] (a lid: a raised faceplate over
/// the dimmed housing), the sheet ([ApplianceSheet], a lid sliding up its
/// track from the screen's foot), the side sheet ([ApplianceSideSheet], a
/// tall lid from the side), the action sheet ([ApplianceActionSheet], a
/// short lid of choices) and the toast ([ApplianceToaster], a small
/// display window of smoked glass with its legend lit).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'material.dart';
import 'menus.dart';
import 'theme.dart';

Color _none(Color c) => c.withValues(alpha: 0);

/// A dialog: a lid of smooth plastic raised over the dimmed housing, its
/// [title], its [content] and its [actions] (keys: [ApplianceButton], the
/// main one [ApplianceButton.filled]) at its foot, the main one last. On a
/// phone the keys share the available width. When they do not fit side by
/// side (long labels, large text), they stack, each as wide as the dialog,
/// the main one on top.
///
/// Reads [style]'s `fill`, `padding` and `textStyle` (the title), then
/// [ApplianceThemeData.dialogStyle]'s.
///
/// ```dart
/// ApplianceDialog(title: 'Remove this item?', content: const Text('It goes back on the shelf.'), actions: [ApplianceButton('Keep', onPressed: () => Navigator.pop(context)), ApplianceButton.filled('Remove', isDestructiveAction: true, onPressed: () => Navigator.pop(context, true))])
/// ```
class ApplianceDialog extends StatelessWidget {
  /// A dialog.
  const ApplianceDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.style,
  });

  /// What it asks or says.
  final String? title;

  /// What it explains.
  final Widget? content;

  /// Its keys, the main one last.
  final List<Widget> actions;

  /// Its style, over [ApplianceThemeData.dialogStyle].
  final ApplianceStyle? style;

  /// The widest a dialog stands.
  static const double maxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.dialogStyle], const {});
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      // The route scopes it (a dialog, or an alert); its title names it,
      // else the word for a dialog.
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        namesRoute: title == null ? true : null,
        label: title == null
            ? RawWidgetsLocalizations.of(context).dialogLabel
            : null,
        child: _Lid(
          fill: layered.fill,
          child: Padding(
            padding:
                layered.padding(Directionality.of(context)) ??
                const EdgeInsets.fromLTRB(
                  ApplianceSpacing.large,
                  ApplianceSpacing.large,
                  ApplianceSpacing.large,
                  ApplianceSpacing.regular + 4,
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
                      style: layered.text(
                        theme.textTheme.title.copyWith(fontSize: 20),
                      ),
                    ),
                  ),
                if (content != null) ...[
                  if (title != null)
                    const SizedBox(height: ApplianceSpacing.small),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.body.copyWith(color: c.printMuted),
                    child: content!,
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: ApplianceSpacing.large),
                  RawActionBar(
                    spacing: ApplianceSpacing.small,
                    overflowSpacing: ApplianceSpacing.small,
                    // A phone spreads the keys over the dialog's width.
                    expanded: narrow,
                    children: actions,
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

/// A lid: a raised plate with a soft, wide shade under it, as a hinged lid
/// stands proud of the housing.
class _Lid extends StatelessWidget {
  const _Lid({required this.child, this.fill, this.top = true});

  final Widget child;
  final Color? fill;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    final night = c.brightness == Brightness.dark;
    final radius = top
        ? BorderRadius.circular(ApplianceMetrics.lidRadius)
        : const BorderRadius.vertical(
            top: Radius.circular(ApplianceMetrics.lidRadius),
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: c.shade.withValues(alpha: night ? 0.5 : 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ApplianceSurface(
        face: ApplianceFace(
          top: fill ?? c.keyTop,
          bottom: fill ?? c.face,
          lift: 1,
          radius: radius,
          foreground: c.print,
        ),
        child: child,
      ),
    );
  }
}

/// Shows [builder]'s dialog (usually an [ApplianceDialog]) over the dimmed
/// housing, in the middle of the screen, on ui_core's [RawModalDialogRoute]:
/// the lid rises a little on its spring ([ApplianceMotion.lid]) and comes
/// to rest (under Reduce Motion it fades). Focus moves into it and stays
/// there, and goes back to what held it as it closes. Escape and Back close
/// it; tapping the scrim does when [barrierDismissible] (null: unless
/// [isAlert]). A screen reader hears a dialog, or an alert with [isAlert].
/// It stands clear of the keyboard.
///
/// ```dart
/// final remove = await showApplianceDialog<bool>(context: context, builder: (context) => const ApplianceDialog(title: 'Remove this item?'));
/// ```
Future<T?> showApplianceDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool? barrierDismissible,
  bool isAlert = false,
}) {
  final theme = ApplianceTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawModalDialogRoute<T>(
      isAlert: isAlert,
      barrierDismissible: barrierDismissible,
      barrierColor: theme.colors.scrim,
      dampingRatio: ApplianceMotion.lid.dampingRatio,
      stiffness: ApplianceMotion.lid.stiffness,
      builder: (context, details) => ApplianceTheme(
        data: theme,
        child: _ClearOfKeyboard(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(ApplianceSpacing.large),
                child: _Rise(
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

// A lid rising on the route's spring: up from 12 px below, from 96% of its
// size, solid within the first third of its rise. (Under Reduce Motion the
// spring stands at 1 and the route fades it.)
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

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
          offset: Offset(0, 12 * (1 - t)),
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
        ),
      );
    },
  );
}

// The sheet route's scroll controller, for an [ApplianceSheet]'s content:
// a drag up grows nothing (a sheet has one size) and a drag down with the
// content at its top takes the sheet down with it.
class _SheetScroll extends InheritedWidget {
  const _SheetScroll({required this.controller, required super.child});

  final ScrollController controller;

  static ScrollController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SheetScroll>()?.controller;

  @override
  bool updateShouldNotify(_SheetScroll oldWidget) =>
      controller != oldWidget.controller;
}

// A sheet at the foot's middle of a panel the screen's width: a tap beside
// it is a tap on the scrim ([onTap], null when the scrim does not close).
class _AtTheFoot extends StatelessWidget {
  const _AtTheFoot({required this.child, this.onTap, this.fill = false});

  final Widget child;
  final VoidCallback? onTap;

  // Whether the sheet stands the panel's whole height (a page) rather than
  // its own.
  final bool fill;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    excludeFromSemantics: true,
    onTap: onTap,
    child: Align(
      alignment: Alignment.bottomCenter,
      heightFactor: fill ? null : 1,
      // The sheet keeps its own taps.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap == null ? null : () {},
        child: child,
      ),
    ),
  );
}

/// A sheet: a lid of smooth plastic risen from the screen's foot, a
/// moulded grip at its top, its [title] and a close key, its [child], and
/// [footer] keys at its foot. On a phone it spans the screen; wider, it
/// stands 560 px wide at the foot's middle.
///
/// Reads [style]'s `fill`, `padding` and `textStyle` (the title), then
/// [ApplianceThemeData.dialogStyle]'s.
///
/// ```dart
/// ApplianceSheet(title: 'Filter', onClose: () => Navigator.pop(context), child: const Text('In stock only'))
/// ```
class ApplianceSheet extends StatelessWidget {
  /// A sheet of [child].
  const ApplianceSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.footer = const [],
    this.style,
  });

  /// Its content.
  final Widget child;

  /// Its name.
  final String? title;

  /// Closes it; null: no close key.
  final VoidCallback? onClose;

  /// Keys at its foot, the main one last.
  final List<Widget> footer;

  /// Its style, over [ApplianceThemeData.dialogStyle].
  final ApplianceStyle? style;

  /// The widest a sheet stands.
  static const double maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.dialogStyle], const {});
    final media = MediaQuery.of(context);
    final words = RawWidgetsLocalizations.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: media.size.height * 0.9,
      ),
      // The route scopes and names it.
      child: Semantics(
        explicitChildNodes: true,
        child: _Lid(
          top: false,
          fill: layered.fill,
          child: Padding(
            padding: EdgeInsets.only(bottom: media.padding.bottom),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Room for the grip.
                    const SizedBox(height: ApplianceSpacing.small + 6),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        ApplianceSpacing.large,
                        ApplianceSpacing.small,
                        ApplianceSpacing.regular,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: title == null
                                ? const SizedBox()
                                : Semantics(
                                    header: true,
                                    child: Text(
                                      title!,
                                      style: layered.text(
                                        theme.textTheme.title.copyWith(
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          if (onClose != null)
                            ApplianceIconButton(
                              icon: const Icon(LucideIcons.x),
                              semanticLabel: words.closeButtonLabel,
                              onPressed: onClose,
                              style: const RawStyle(
                                minimumSize: WidgetStatePropertyAll(
                                  Size.square(40),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        controller: _SheetScroll.of(context),
                        padding:
                            layered.padding(Directionality.of(context)) ??
                            const EdgeInsets.fromLTRB(
                              ApplianceSpacing.large,
                              ApplianceSpacing.regular,
                              ApplianceSpacing.large,
                              ApplianceSpacing.large,
                            ),
                        child: child,
                      ),
                    ),
                    if (footer.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ApplianceSpacing.large,
                          0,
                          ApplianceSpacing.large,
                          ApplianceSpacing.large,
                        ),
                        child: RawActionBar(
                          spacing: ApplianceSpacing.small,
                          overflowSpacing: ApplianceSpacing.small,
                          expanded: true,
                          children: footer,
                        ),
                      ),
                  ],
                ),
                // The grip: a short moulded slot, ui_core's handle (a press
                // or Down closes the sheet; it has one size). Its target, the
                // look's floor (48 px for a finger), stands over the title
                // row's middle.
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: Center(
                    child: RawBottomSheetDragHandle(
                      builder: (context, states) => TapTargetPadding(
                        alignment: AlignmentDirectional.topCenter,
                        child: SizedBox.square(
                          dimension: 44,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: ApplianceSpacing.small,
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 6,
                                child: ApplianceSurface(
                                  face:
                                      ApplianceFace.well(
                                        c,
                                        fill: c.trough,
                                        radius: 3,
                                      ).copyWith(
                                        focus:
                                            states.contains(WidgetState.focused)
                                            ? c.focus
                                            : c.focus.withValues(alpha: 0),
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

/// Raises [builder]'s sheet (an [ApplianceSheet]) from the screen's foot on
/// ui_core's [RawBottomSheetRoute], sliding up its track on
/// [ApplianceMotion.slide] (under Reduce Motion it fades). A drag takes it
/// down with the finger (its content hands the drag over at its top); let
/// go past half way, or flung, it closes. Tapping the scrim closes it when
/// [barrierDismissible]; Escape and Back always do; the sheet's grip and
/// close key are a screen reader's ways out. Focus moves in and back. It
/// rises clear of the keyboard. A screen reader calls it [semanticLabel]
/// (null: the words for a bottom sheet).
///
/// ```dart
/// showApplianceSheet<void>(context: context, builder: (context) => ApplianceSheet(title: 'Filter', onClose: () => Navigator.pop(context), child: const Text('In stock only')))
/// ```
Future<T?> showApplianceSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? semanticLabel,
}) {
  final theme = ApplianceTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawBottomSheetRoute<T>(
      barrierColor: theme.colors.scrim,
      barrierDismissible: barrierDismissible,
      semanticLabel: semanticLabel,
      dampingRatio: ApplianceMotion.slide.dampingRatio,
      stiffness: ApplianceMotion.slide.stiffness,
      builder: (context, details) => ApplianceTheme(
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

/// [showApplianceSheet] with an [ApplianceSheet] of [title] round
/// [builder]'s content and a close key.
///
/// ```dart
/// showApplianceBottomSheet<void>(context: context, title: 'Filter', builder: (context) => const Text('In stock only'))
/// ```
Future<T?> showApplianceBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  List<Widget> footer = const [],
  bool barrierDismissible = true,
}) => showApplianceSheet<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  semanticLabel: title,
  builder: (context) => ApplianceSheet(
    title: title,
    footer: footer,
    onClose: () => Navigator.of(context).maybePop(),
    child: Builder(builder: builder),
  ),
);

/// Toasts over [child]: each a small display window, smoked glass in a
/// raised bezel, its lamp lit and its legend glowing, at the foot of the
/// screen. Mount it once over the app (in its `builder:`, inside
/// [ApplianceTheme]).
///
/// Every toast reads [style]'s `fill` (the glass), `foreground` (the
/// legend) and `textStyle`, then [ApplianceThemeData.toastStyle]'s.
///
/// ```dart
/// ApplianceToaster(child: app)
/// ```
class ApplianceToaster extends StatelessWidget {
  /// Toasts over [child].
  const ApplianceToaster({super.key, required this.child, this.style});

  /// The app.
  final Widget child;

  /// Every toast's style, over [ApplianceThemeData.toastStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => RawToaster(
    dampingRatio: ApplianceMotion.lid.dampingRatio,
    stiffness: ApplianceMotion.lid.stiffness,
    constraints: const BoxConstraints(maxWidth: 440),
    toastBuilder: (context, details) => _Toast(details, style),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<ApplianceStyle>('style', style, defaultValue: null),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast(this.details, this.style);

  final RawToastDetails details;
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = details.toast;
    final layered = RawStyleOf([style, theme.toastStyle], const {});
    final glass = layered.fill ?? c.display;
    final legend = layered.foreground ?? c.onDisplay;
    final words = RawWidgetsLocalizations.of(context);
    // The lamp and the action light in the signal: bright on the night's
    // glass, a deep ink on the day's LCD, walked toward the figures' ink
    // until the action's words read at 4.5:1.
    final glow = glass.computeLuminance() > 0.4 ? c.signal : c.signalTop;
    var action = glass.computeLuminance() > 0.4 ? c.signalInk : c.signalTop;
    for (var t = 0.05; t <= 1 && applianceContrast(action, glass) < 4.5;) {
      action = Color.lerp(c.signalInk, legend, t)!;
      t += 0.05;
    }
    const glassRadius =
        ApplianceMetrics.lidRadius - ApplianceMetrics.windowInset;
    const keyInset = ApplianceSpacing.tight;
    Widget key({
      required String label,
      required VoidCallback onPressed,
      required Widget Function(Color ink) child,
    }) => RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) {
        final pressed = states.contains(WidgetState.pressed);
        return AnimatedApplianceSurface(
          face: ApplianceFace(
            top: pressed ? legend.withValues(alpha: 0.12) : _none(legend),
            bottom: pressed ? legend.withValues(alpha: 0.12) : _none(legend),
            radius: BorderRadius.circular(glassRadius - keyInset),
            travel: pressed ? 0.6 : 0,
            foreground: legend,
            focus: states.contains(WidgetState.focused)
                ? c.focus
                : _none(c.focus),
          ),
          child: TapTargetPadding(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ApplianceSpacing.small,
                ),
                child: Center(widthFactor: 1, child: child(legend)),
              ),
            ),
          ),
        );
      },
    );
    final opacity = details.animation.drive(
      Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
    );
    return FadeTransition(
      opacity: opacity,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: _Lid(
          child: Padding(
            padding: const EdgeInsets.all(ApplianceMetrics.windowInset),
            child: ApplianceSurface(
              face: ApplianceFace.well(
                c,
                fill: glass,
                radius: glassRadius,
              ).copyWith(focus: details.focused ? c.focus : _none(c.focus)),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  ApplianceSpacing.medium,
                  keyInset,
                  keyInset,
                  keyInset,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: ApplianceLamp(lit: true, color: glow)),
                      const SizedBox(width: ApplianceSpacing.medium),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.title != null)
                              Text(
                                t.title!,
                                style: theme.textTheme.label.copyWith(
                                  color: legend,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              t.message,
                              style: layered.text(
                                theme.textTheme.body.copyWith(
                                  color: legend,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (t.actionLabel != null && details.runAction != null)
                        key(
                          label: t.actionLabel!,
                          onPressed: details.runAction!,
                          child: (ink) => Text(
                            t.actionLabel!.toUpperCase(),
                            style: theme.textTheme.legend.copyWith(
                              color: action,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      key(
                        label: words.closeButtonLabel,
                        onPressed: details.dismiss,
                        child: (ink) =>
                            Icon(LucideIcons.x, size: 18, color: ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a toast saying [message] from the nearest [ApplianceToaster]: what
/// just happened, with an optional [actionLabel] and [onAction] (Undo).
///
/// ```dart
/// showApplianceToast(context, 'Added to basket', actionLabel: 'Undo', onAction: () {})
/// ```
RawToastController showApplianceToast(
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

/// A side sheet: a tall lid slid in from the screen's side over the dimmed
/// housing, its [title] and a close key at its top, its [child] under them
/// and [footer] keys at its foot. Drag it back toward its edge to close it.
///
/// ```dart
/// ApplianceSideSheet(title: 'Filters', onClose: () => Navigator.pop(context), child: const Text('In stock only'))
/// ```
class ApplianceSideSheet extends StatelessWidget {
  /// A side sheet of [child].
  const ApplianceSideSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.footer = const [],
    this.side = AxisDirection.right,
    this.style,
  });

  /// Its content.
  final Widget child;

  /// Its name.
  final String? title;

  /// Closes it; null: no close key.
  final VoidCallback? onClose;

  /// Keys at its foot, the main one last.
  final List<Widget> footer;

  /// The screen side it stands against; its open side is rounded.
  final AxisDirection side;

  /// Its style, over [ApplianceThemeData.dialogStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.dialogStyle], const {});
    final words = RawWidgetsLocalizations.of(context);
    final media = MediaQuery.of(context);
    const r = Radius.circular(ApplianceMetrics.lidRadius);
    final radius = side == AxisDirection.left
        ? const BorderRadius.horizontal(right: r)
        : const BorderRadius.horizontal(left: r);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: c.shade.withValues(
                alpha: c.brightness == Brightness.dark ? 0.5 : 0.18,
              ),
              blurRadius: 32,
            ),
          ],
        ),
        child: ApplianceSurface(
          face: ApplianceFace(
            top: layered.fill ?? c.keyTop,
            bottom: layered.fill ?? c.face,
            lift: 1,
            radius: radius,
            foreground: c.print,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: media.padding.top,
              bottom: media.padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    ApplianceSpacing.large,
                    ApplianceSpacing.regular,
                    ApplianceSpacing.regular,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: title == null
                            ? const SizedBox()
                            : Semantics(
                                header: true,
                                child: Text(
                                  title!,
                                  style: layered.text(
                                    theme.textTheme.title.copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      if (onClose != null)
                        ApplianceIconButton(
                          icon: const Icon(LucideIcons.x),
                          semanticLabel: words.closeButtonLabel,
                          onPressed: onClose,
                          style: const RawStyle(
                            minimumSize: WidgetStatePropertyAll(
                              Size.square(40),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        layered.padding(Directionality.of(context)) ??
                        const EdgeInsets.all(ApplianceSpacing.large),
                    child: child,
                  ),
                ),
                if (footer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ApplianceSpacing.large,
                      0,
                      ApplianceSpacing.large,
                      ApplianceSpacing.large,
                    ),
                    child: RawActionBar(
                      spacing: ApplianceSpacing.small,
                      overflowSpacing: ApplianceSpacing.small,
                      expanded: true,
                      children: footer,
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
    properties.add(StringProperty('title', title, defaultValue: null));
  }
}

/// Slides an [ApplianceSideSheet] of [title] round [builder]'s content in
/// from the reading end (or start), over the dimmed housing. Tapping the
/// scrim, Escape, Back and the close key close it; so does a drag back.
///
/// ```dart
/// showApplianceSideSheet<void>(context: context, title: 'Filters', builder: (context) => const Text('In stock only'))
/// ```
Future<T?> showApplianceSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  List<Widget> footer = const [],
  RawSheetEdge edge = RawSheetEdge.end,
  double width = 380,
}) {
  final theme = ApplianceTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawSideSheetRoute<T>(
      edge: edge,
      width: width,
      barrierColor: theme.colors.scrim,
      semanticLabel: title,
      dampingRatio: ApplianceMotion.slide.dampingRatio,
      stiffness: ApplianceMotion.slide.stiffness,
      builder: (context, sheet) => ApplianceTheme(
        data: theme,
        child: ApplianceSideSheet(
          title: title,
          footer: footer,
          side: sheet.side,
          onClose: sheet.close,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
}

/// One choice of an [ApplianceActionSheet].
@immutable
class ApplianceSheetAction {
  /// A choice reading [label].
  const ApplianceSheetAction(
    this.label, {
    required this.onPressed,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// Runs it ([showApplianceActionSheet] closes the sheet first).
  final VoidCallback onPressed;

  /// Whether it destroys something: printed in the danger colour.
  final bool isDestructiveAction;
}

/// An action sheet: a short lid risen from the screen's foot with a few
/// choices on it as rows, what they are about over them, and a key apart
/// to cancel.
///
/// ```dart
/// ApplianceActionSheet(title: 'Order 1042', actions: [ApplianceSheetAction('Cancel the order', isDestructiveAction: true, onPressed: () {})], onCancel: () => Navigator.pop(context))
/// ```
class ApplianceActionSheet extends StatelessWidget {
  /// An action sheet of [actions].
  const ApplianceActionSheet({
    super.key,
    required this.actions,
    required this.onCancel,
    this.title,
    this.message,
    this.cancelLabel = 'Cancel',
    this.style,
  });

  /// The choices.
  final List<ApplianceSheetAction> actions;

  /// Closes it without a choice.
  final VoidCallback onCancel;

  /// What they are about.
  final String? title;

  /// A line more on it.
  final String? message;

  /// The cancel key's legend.
  final String cancelLabel;

  /// Its style, over [ApplianceThemeData.dialogStyle]: textStyle (the title).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = RawStyleOf([
      style,
      ApplianceTheme.of(context).dialogStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final media = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: ApplianceSheet.maxWidth),
      // The route scopes and names it.
      child: Semantics(
        explicitChildNodes: true,
        child: _Lid(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ApplianceSpacing.regular,
              ApplianceSpacing.regular,
              ApplianceSpacing.regular,
              ApplianceSpacing.regular + media.padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Semantics(
                    header: true,
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: look.text(t.label).copyWith(color: c.printMuted),
                    ),
                  ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: ApplianceSpacing.tight),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: t.secondary.copyWith(color: c.printMuted),
                    ),
                  ),
                if (title != null || message != null)
                  const SizedBox(height: ApplianceSpacing.small),
                for (final a in actions)
                  RawButton(
                    onPressed: a.onPressed,
                    semanticLabel: a.label,
                    excludeSemantics: true,
                    builder: (context, states, _) => ApplianceMenuRow(
                      label: a.label,
                      states: states,
                      isDestructiveAction: a.isDestructiveAction,
                    ),
                  ),
                const SizedBox(height: ApplianceSpacing.regular),
                ApplianceButton(cancelLabel, onPressed: onCancel),
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

/// Raises an [ApplianceActionSheet] of [actions] from the screen's foot;
/// a choice closes it and then runs.
///
/// ```dart
/// showApplianceActionSheet(context: context, title: 'Order 1042', actions: [ApplianceSheetAction('Cancel the order', isDestructiveAction: true, onPressed: () {})])
/// ```
Future<void> showApplianceActionSheet({
  required BuildContext context,
  required List<ApplianceSheetAction> actions,
  String? title,
  String? message,
  String cancelLabel = 'Cancel',
}) => showApplianceSheet<void>(
  context: context,
  semanticLabel: title,
  builder: (context) => ApplianceActionSheet(
    title: title,
    message: message,
    cancelLabel: cancelLabel,
    actions: [
      for (final a in actions)
        ApplianceSheetAction(
          a.label,
          isDestructiveAction: a.isDestructiveAction,
          onPressed: () {
            Navigator.of(context).pop();
            a.onPressed();
          },
        ),
    ],
    onCancel: () => Navigator.of(context).pop(),
  ),
);

/// How tall an [ApplianceSheetPage] stands.
enum ApplianceSheetSize {
  /// Nine tenths of the screen's height.
  standard,

  /// A drawer: a little over half the screen's height.
  drawer,

  /// The whole screen, its corners square.
  fullScreen,
}

/// The router's page for a sheet, raised on the root navigator over the
/// app's frame: a lid rising from the screen's foot, 560 px wide at its
/// middle on a wider screen, as tall as its [size] says: nine tenths of the
/// screen by default, a drawer a little over half, full screen all of it. The page inside is told it stands as
/// a sheet, so its bar's way out is a close key
/// ([ApplianceAppBar.autoLeading]).
///
/// ```dart
/// Navigator(pages: const [ApplianceSheetPage<void>(key: ValueKey('filter'), size: ApplianceSheetSize.drawer, child: FilterPage())], onDidRemovePage: (page) {})
/// ```
class ApplianceSheetPage<T> extends Page<T> {
  /// A sheet of [child].
  const ApplianceSheetPage({
    required this.child,
    this.size = ApplianceSheetSize.standard,
    super.key,
    super.name,
  });

  /// The page in the sheet.
  final Widget child;

  /// How tall it stands.
  final ApplianceSheetSize size;

  @override
  Route<T> createRoute(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    return RawBottomSheetRoute<T>(
      settings: this,
      snapSizes: [
        switch (size) {
          ApplianceSheetSize.standard => 0.9,
          ApplianceSheetSize.drawer => 0.6,
          ApplianceSheetSize.fullScreen => 1,
        },
      ],
      barrierColor: theme.colors.scrim,
      dampingRatio: ApplianceMotion.slide.dampingRatio,
      stiffness: ApplianceMotion.slide.stiffness,
      builder: (sheetContext, details) {
        // Read as it builds: a page the router replaces, or a window that
        // grows, takes the sheet with it.
        final page = ModalRoute.of(sheetContext)?.settings;
        final current = page is ApplianceSheetPage ? page.child : child;
        final media = MediaQuery.of(sheetContext);
        final width = math.min(media.size.width, ApplianceSheet.maxWidth);
        return ApplianceTheme(
          data: theme,
          child: _AtTheFoot(
            onTap: details.close,
            fill: true,
            child: LayoutBuilder(
              builder: (context, room) => SizedBox(
                width: width,
                height: room.maxHeight,
                child: ClipRRect(
                  borderRadius: size == ApplianceSheetSize.fullScreen
                      ? BorderRadius.zero
                      : const BorderRadius.vertical(
                          top: Radius.circular(ApplianceMetrics.lidRadius),
                        ),
                  child: MediaQuery(
                    data: media.copyWith(
                      size: Size(width, room.maxHeight),
                      padding: size == ApplianceSheetSize.fullScreen
                          ? media.padding
                          : media.padding.copyWith(top: 0),
                    ),
                    child: RoutePresentationScope(
                      presentation: RoutePresentation.sheet,
                      child: Semantics(
                        scopesRoute: true,
                        namesRoute: true,
                        explicitChildNodes: true,
                        child: current,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
