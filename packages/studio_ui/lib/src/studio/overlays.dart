/// Studio's overlays: [StudioDialog] raised by [showStudioDialog], a panel
/// module rising toward the light; the drawer [StudioSheet] raised by
/// [showStudioBottomSheet], or by the router's [StudioSheetPage]; and
/// [StudioToaster] with [showStudioToast], a strip of readout glass with
/// its lamp lit. The dialog and the sheets ride ui_core's routes
/// (RawModalDialogRoute, RawBottomSheetRoute); Studio paints them.
library;

import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'internal/curved.dart';
import 'surface.dart';
import 'theme.dart';

/// A critically damped spring of [stiffness] (unit mass) as a curve over a
/// route's duration: the curve reaches 1 where the spring has all but
/// settled. A route's arrival moves as the object would.
class StudioSpringCurve extends Curve {
  /// The spring of [stiffness].
  const StudioSpringCurve(this.stiffness);

  /// The spring's stiffness.
  final double stiffness;

  /// How long the spring takes to come within a thousandth of rest.
  Duration get settle {
    final omega = math.sqrt(stiffness);
    // (1 + ωt)e^(-ωt) = 0.001 at ωt ≈ 9.23.
    return Duration(microseconds: (9.23 / omega * 1e6).round());
  }

  @override
  double transformInternal(double t) {
    final omega = math.sqrt(stiffness);
    final sim = SpringSimulation(
      SpringDescription(mass: 1, stiffness: stiffness, damping: 2 * omega),
      0,
      1,
      0,
    );
    final s = settle.inMicroseconds / 1e6;
    return t >= 1 ? 1 : sim.x(t * s).clamp(0.0, 1.0);
  }
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

/// Raises [builder]'s dialog (a [StudioDialog]) over the page on ui_core's
/// RawModalDialogRoute: the room's lights lower and the module rises toward
/// the light, from 96% of its size to its own, on a spring
/// ([StudioMotion.overlayStiffness]); under Reduce Motion it fades. Focus
/// moves into it and stays there, and goes back to what held it as it
/// closes. Escape and Back close it; tapping the scrim does when
/// [barrierDismissible] (null: unless [isAlert]). A screen reader hears a
/// dialog, or an alert with [isAlert]. It stands clear of the keyboard.
///
/// ```dart
/// showStudioDialog<bool>(context: context, builder: (context) => StudioDialog(title: 'Discard this take?', actions: [StudioButton('Keep', onPressed: () => Navigator.pop(context, false))]))
/// ```
Future<T?> showStudioDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool? barrierDismissible,
  bool isAlert = false,
}) {
  final theme = StudioTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawModalDialogRoute<T>(
      isAlert: isAlert,
      barrierDismissible: barrierDismissible,
      barrierColor: theme.colors.scrim,
      dampingRatio: StudioMotion.dampingRatio,
      stiffness: StudioMotion.overlayStiffness,
      builder: (context, details) => StudioTheme(
        data: theme,
        child: _ClearOfKeyboard(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.large),
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

// The module rising on the route's spring: from 96% of its size, solid
// within the first third of its rise. (Under Reduce Motion the spring
// stands at 1 and the route fades it.)
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
        opacity: (t / 0.35).clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      );
    },
  );
}

/// A brushed-metal dialog with a [title], optional [content], and [actions].
///
/// Actions stand in one row while their labels fit: sharing the width
/// equally on a phone, at the trailing edge on a wider screen. When they do
/// not fit, they stack in one column of one width, the main action first
/// and the rest after it in reverse, so a quiet Cancel comes last (ui_core's
/// RawActionBar).
///
/// Reads [style]'s `fill`, `foreground` and `padding`, then
/// [StudioThemeData.dialogStyle].
///
/// ```dart
/// StudioDialog(title: 'Discard this take?', content: const Text('The 4 minutes you recorded will be gone.'), actions: [StudioButton('Keep', onPressed: keep), StudioButton.lit('Discard', isDestructiveAction: true, onPressed: discard)])
/// ```
class StudioDialog extends StatelessWidget {
  /// A dialog titled [title].
  const StudioDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
    this.style,
  });

  /// What it is about.
  final String title;

  /// What it asks or says.
  final Widget? content;

  /// Its keys, the main one last.
  final List<Widget> actions;

  /// Its style, over [StudioThemeData.dialogStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.dialogStyle], const {});
    final narrow = MediaQuery.sizeOf(context).width < StudioMetrics.tablet;
    final night = c.brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StudioRadii.panel),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withValues(alpha: night ? 0.6 : 0.28),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: StudioSurface(
            face: layered.on(c.panelFace),
            child: Padding(
              padding:
                  layered.padding(Directionality.of(context)) ??
                  const EdgeInsets.all(StudioSpacing.large),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      title,
                      style: theme.textTheme.title.copyWith(
                        fontSize: 20,
                        height: 26 / 20,
                        color: layered.foreground ?? c.legend,
                      ),
                    ),
                  ),
                  if (content != null) ...[
                    const SizedBox(height: StudioSpacing.small),
                    DefaultTextStyle(
                      style: theme.textTheme.body.copyWith(
                        color: c.legendMuted,
                        fontSize: 15,
                        height: 22 / 15,
                      ),
                      child: content!,
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: StudioSpacing.large),
                    RawActionBar(
                      expanded: narrow,
                      spacing: StudioSpacing.medium,
                      overflowSpacing: StudioSpacing.small,
                      children: [
                        // At the trailing edge each key is at least a
                        // key's width.
                        for (final action in actions)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: narrow ? 0 : _leastActionWidth,
                            ),
                            child: action,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
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
      ..add(StringProperty('title', title))
      ..add(
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

const double _leastActionWidth = 112;

/// Raises [builder]'s content in a [StudioSheet] from the bottom edge on
/// ui_core's RawBottomSheetRoute: a drawer of metal sliding out on its
/// runners, the room's lights lowering; under Reduce Motion it fades. A drag
/// takes it down with the finger; let go past half way, or flung, it closes.
/// Tapping the scrim (when [barrierDismissible]), Escape or Back close it;
/// its finger slot and its close key are a screen reader's ways out. Focus
/// moves in and back. It rises clear of the keyboard.
///
/// ```dart
/// showStudioBottomSheet<void>(context: context, title: 'Export', builder: (context) => const Text('MP3, 128 kbps'))
/// ```
Future<T?> showStudioBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool barrierDismissible = true,
  StudioStyle? style,
}) {
  final theme = StudioTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawBottomSheetRoute<T>(
      barrierColor: theme.colors.scrim,
      barrierDismissible: barrierDismissible,
      semanticLabel: title,
      dampingRatio: StudioMotion.dampingRatio,
      stiffness: _drawerStiffness,
      builder: (context, details) => StudioTheme(
        data: theme,
        child: _AtTheFoot(
          onTap: barrierDismissible ? details.close : null,
          child: StudioSheet(
            title: title,
            style: style,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

// A drawer's runners: a little softer than a dialog's rise.
const double _drawerStiffness = StudioMotion.overlayStiffness * 0.8;

// A sheet at the foot's middle of a panel the screen's width (ui_core's
// sheet spans the screen): a tap beside it is a tap on the scrim ([onTap],
// null when the scrim does not close).
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

/// The router's page for a route raised as a sheet: its screen (a
/// `StudioScreen`, whose bar then carries the close key) in a [StudioSheet]
/// drawn out from the bottom edge as [showStudioBottomSheet] draws one (on
/// ui_core's RawBottomSheetRoute: a drag takes it down, focus moves in
/// and back), 90% of the screen tall, or as tall as its content when
/// [drawer]; with [fullScreen] it rises as a whole page of metal instead (a
/// page route). Its screen reads [RoutePresentation.sheet]. A go_router
/// route's `pageBuilder` returns it with the route's `state.pageKey`.
///
/// ```dart
/// StudioSheetPage<void>(key: state.pageKey, drawer: true, child: const ExportPage())
/// ```
class StudioSheetPage<T> extends Page<T> {
  /// A sheet of [child].
  const StudioSheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The sheet's screen, usually a `StudioScreen`.
  final Widget child;

  /// Whether it stands as tall as its content rather than 90% of the
  /// screen.
  final bool drawer;

  /// Whether it is raised as a whole page rather than a sheet.
  final bool fullScreen;

  @override
  Route<T> createRoute(BuildContext context) {
    final theme = StudioTheme.of(context);
    const spring = StudioSpringCurve(_drawerStiffness);
    // The page as it stands now: a router that updates the page in place
    // hands the route the new one.
    Widget current(BuildContext context) {
      final page = ModalRoute.of(context)?.settings;
      return page is StudioSheetPage ? page.child : child;
    }

    Widget scoped(Widget child) => StudioTheme(
      data: theme,
      child: RoutePresentationScope(
        presentation: RoutePresentation.sheet,
        child: child,
      ),
    );
    Widget rise(
      BuildContext context,
      Animation<double> animation,
      Animation<double> _,
      Widget child,
    ) {
      final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduce) return FadeTransition(opacity: animation, child: child);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              studioCurved(animation, spring, reverseCurve: Curves.easeInCubic),
            ),
        child: child,
      );
    }

    if (fullScreen) {
      return PageRouteBuilder<T>(
        settings: this,
        fullscreenDialog: true,
        transitionDuration: spring.settle,
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, _, _) => scoped(
          StudioSurface(
            face: theme.colors.panelFace.copyWith(radius: 0),
            child: current(context),
          ),
        ),
        transitionsBuilder: rise,
      );
    }
    return RawBottomSheetRoute<T>(
      settings: this,
      // A drawer rests at its content's height; a sheet at nine tenths of
      // the screen.
      snapSizes: drawer ? null : const [0.9],
      barrierColor: theme.colors.scrim,
      dampingRatio: StudioMotion.dampingRatio,
      stiffness: _drawerStiffness,
      builder: (context, details) => scoped(
        _AtTheFoot(
          onTap: details.close,
          fill: !drawer,
          child: StudioSheet(
            style: const StudioStyle(
              padding: WidgetStatePropertyAll(
                EdgeInsets.only(top: StudioSpacing.small),
              ),
            ),
            child: drawer
                ? Builder(builder: current)
                : SizedBox.expand(child: Builder(builder: current)),
          ),
        ),
      ),
    );
  }
}

/// A sheet: a drawer of metal, its top corners machined, a finger slot cut
/// at its top, an optional [title] printed beside a close key. On a phone
/// it spans the screen; wider it stands 560 px wide.
///
/// Reads [style]'s `fill`, `foreground` and `padding`, then
/// [StudioThemeData.bottomSheetStyle].
///
/// ```dart
/// StudioSheet(title: 'Export', child: const Text('MP3, 128 kbps'))
/// ```
class StudioSheet extends StatelessWidget {
  /// A sheet holding [child].
  const StudioSheet({super.key, required this.child, this.title, this.style});

  /// What it holds.
  final Widget child;

  /// What it is called.
  final String? title;

  /// Its style, over [StudioThemeData.bottomSheetStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.bottomSheetStyle], const {});
    final words = RawWidgetsLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final night = c.brightness == Brightness.dark;
    final side = size.width < StudioMetrics.tablet
        ? StudioSpacing.pageMargin(size.width)
        : StudioSpacing.regular;
    const top = Radius.circular(StudioRadii.panel);
    // On a phone what it holds starts on the page's margin, as the page's
    // own does; wider, the framed panel's own inset.
    final pad =
        layered.padding(Directionality.of(context)) ??
        EdgeInsets.fromLTRB(
          side,
          StudioSpacing.small,
          side,
          StudioSpacing.regular,
        );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: size.width < StudioMetrics.tablet ? size.width : 560,
        maxHeight: size.height * 0.9,
      ),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: top),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withValues(alpha: night ? 0.55 : 0.22),
                blurRadius: 24,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: top),
            child: StudioSurface(
              face: layered.on(c.panelFace.copyWith(radius: 0)),
              child: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    Padding(
                      padding: pad,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The finger slot's room (the slot itself is the
                          // handle over the top, below).
                          const SizedBox(height: _slotHeight),
                          if (title != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: StudioSpacing.small,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        title!,
                                        style: theme.textTheme.title.copyWith(
                                          fontSize: 18,
                                          height: 24 / 18,
                                          color: layered.foreground ?? c.legend,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _CloseKey(
                                    label: words.closeButtonLabel,
                                    onPressed: () =>
                                        Navigator.maybePop(context),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox(height: StudioSpacing.regular),
                          const SizedBox(height: StudioSpacing.small),
                          Flexible(child: child),
                        ],
                      ),
                    ),
                    // The finger slot, where a hand pulls the drawer: ui_core's
                    // drag handle (a press or Down closes a sheet of one size),
                    // its target the tap floor over the sheet's top, never
                    // narrower than the slot.
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      end: 0,
                      child: Center(
                        child: RawBottomSheetDragHandle(
                          builder: (context, states) => SizedBox.square(
                            dimension: math.max(
                              RawTapTargets.of(context).floorOn().shortestSide,
                              _slotWidth,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: pad.top),
                                child: SizedBox(
                                  width: _slotWidth,
                                  height: _slotHeight,
                                  child: AnimatedStudioSurface(
                                    stiffness: StudioMotion.lampStiffness,
                                    face: c.recessFace.copyWith(
                                      radius: _slotHeight / 2,
                                      focus:
                                          states.contains(WidgetState.focused)
                                          ? c.focusRing
                                          : c.focusRing.withValues(alpha: 0),
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
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(
        DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
      );
  }
}

// The finger slot's height.
const double _slotHeight = 6;

// The finger slot's length.
const double _slotWidth = 40;

class _CloseKey extends StatelessWidget {
  const _CloseKey({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, states, _) => SizedBox.square(
        dimension: theme.controlHeight,
        child: AnimatedStudioSurface(
          face: c.keyFace.copyWith(
            travel: states.contains(WidgetState.pressed) ? 1 : 0,
            focus: states.contains(WidgetState.focused)
                ? c.focusRing
                : c.focusRing.withValues(alpha: 0),
          ),
          child: Icon(
            LucideIcons.x,
            size: StudioIconSizes.regular,
            color: c.onKey,
          ),
        ),
      ),
    );
  }
}

/// Hosts toasts over [child]: each a strip of readout glass (pale and lit
/// from behind by day, dark by night) with its lamp lit, its message in the
/// readout's words, its action a lit legend, rising from the foot of the
/// screen. Put it above the app's navigator (`WidgetsApp.builder`)
/// and show one with [showStudioToast].
///
/// Each toast reads [style]'s `fill` (the glass) and `foreground`, then
/// [StudioThemeData.toastStyle].
///
/// ```dart
/// StudioToaster(child: app)
/// ```
class StudioToaster extends StatelessWidget {
  /// Toasts over [child].
  const StudioToaster({super.key, required this.child, this.style});

  /// The app.
  final Widget child;

  /// Every toast's style, over [StudioThemeData.toastStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) => RawToaster(
    dampingRatio: StudioMotion.dampingRatio,
    stiffness: StudioMotion.overlayStiffness,
    constraints: const BoxConstraints(maxWidth: 480),
    toastBuilder: (context, details) => _Toast(details, style),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<StudioStyle>('style', style, defaultValue: null),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast(this.details, this.style);

  final RawToastDetails details;
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final t = details.toast;
    final layered = RawStyleOf([style, theme.toastStyle], const {});
    final ink = layered.foreground ?? c.onReadout;
    final words = RawWidgetsLocalizations.of(context);
    final opacity = details.animation.drive(
      Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
    );
    return FadeTransition(
      opacity: opacity,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StudioRadii.display),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: StudioSurface(
            face: c.readoutFace.copyWith(
              radius: StudioRadii.display,
              fill: layered.fill,
              depth: StudioDepth.level,
              focus: details.focused ? c.focusRing : null,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: StudioSpacing.regular,
                end: StudioSpacing.tight,
                top: StudioSpacing.tight,
                bottom: StudioSpacing.tight,
              ),
              child: Row(
                children: [
                  const StudioLamp(on: true),
                  const SizedBox(width: StudioSpacing.medium),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: StudioSpacing.small,
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
                            style: theme.textTheme.body.copyWith(
                              color: ink,
                              fontSize: 15,
                              height: 20 / 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (t.actionLabel != null && details.runAction != null)
                    _ToastKey(
                      label: t.actionLabel!,
                      onPressed: details.runAction!,
                      child: Text(
                        t.actionLabel!,
                        style: theme.textTheme.label.copyWith(
                          color: c.readoutLit,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _ToastKey(
                    label: words.closeButtonLabel,
                    onPressed: details.dismiss,
                    square: true,
                    child: Icon(
                      LucideIcons.x,
                      size: StudioIconSizes.medium,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastKey extends StatelessWidget {
  const _ToastKey({
    required this.label,
    required this.onPressed,
    required this.child,
    this.square = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;
  final bool square;

  // The key's face: as tall as a key on the bar, over the tap floor.
  static const double _keySide = StudioMetrics.controlHeight;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: _keySide,
          minHeight: _keySide,
          maxWidth: square ? _keySide : double.infinity,
        ),
        child: AnimatedStudioSurface(
          face: StudioFace(
            fill: c.readoutLow,
            fillLow: c.readoutLow,
            depth: StudioDepth.sunk,
            radius: StudioRadii.display - StudioMetrics.recessInset,
            presence:
                states.contains(WidgetState.pressed) ||
                    states.contains(WidgetState.hovered)
                ? 1
                : 0,
            focus: states.contains(WidgetState.focused)
                ? c.focusRing
                : c.focusRing.withValues(alpha: 0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: square ? 0 : StudioSpacing.medium,
            ),
            child: Center(widthFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}

/// Shows a toast saying [message] from the nearest [StudioToaster]: what
/// just happened, with an optional [actionLabel] and [onAction] (Undo).
///
/// ```dart
/// showStudioToast(context, 'Marker added at 12:04', actionLabel: 'Undo', onAction: () {})
/// ```
RawToastController showStudioToast(
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
