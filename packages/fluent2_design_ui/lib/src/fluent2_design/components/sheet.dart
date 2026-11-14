import 'package:material_ui/material_ui.dart'
    show Material, MaterialLocalizations, MaterialType, ModalBottomSheetRoute;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../icons.dart';
import '../styled.dart';
import '../internal/measure.dart';
import '../theme.dart';
import 'button/button.dart';
import 'host.dart';

import 'package:ui_core/ui_core.dart';

/// A sheet's head (Fluent's `DrawerHeaderTitle` and `DialogTitle`): its
/// [title] in subtitle1 and, at its end, the dismiss button ([close]; none
/// for a dialog that closes by its own Cancel), or at its start the way
/// back ([leading]), 8 between, at least 48 tall.
///
/// ```dart
/// Fluent2SheetHead(title: 'Share', close: Fluent2IconButton(Fluent2Icons.dismiss, label: 'Close', onPressed: close))
/// ```
class Fluent2SheetHead extends StatelessWidget {
  /// A sheet's head showing [title].
  const Fluent2SheetHead({
    required this.title,
    this.close,
    this.leading,
    this.actions = const [],
    super.key,
  });

  /// The sheet's title, in subtitle1.
  final String title;

  /// The way back at the head's start; null shows none.
  final Widget? leading;

  /// The dismiss button at the head's end; null shows none.
  final Widget? close;

  /// Further commands before [close].
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: Fluent2ChromeMetrics.sheetHead,
      ),
      child: Row(
        spacing: Fluent2Spacing.s,
        children: [
          ?leading,
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: t.subtitle1),
            ),
          ),
          ...actions,
          ?close,
        ],
      ),
    );
  }
}

/// The handle over a phone's bottom sheet: 36 by 4, round, in the
/// accessible stroke, 8 under the sheet's top. Plumbing of the sheets.
class Fluent2SheetHandle extends StatelessWidget {
  /// A bottom sheet's handle.
  const Fluent2SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Fluent2Spacing.xs),
      child: Center(
        child: Container(
          width: Fluent2ChromeMetrics.handleWidth,
          height: Fluent2ChromeMetrics.handleHeight,
          decoration: BoxDecoration(
            color: t.colors.neutralStroke1,
            borderRadius: BorderRadius.circular(
              Fluent2ChromeMetrics.handleHeight / 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A modal sheet's card, drawn in place: on a phone Fluent 2's bottom
/// sheet (the surface rising off the bottom edge, its top corners 8, the
/// handle over the head, in `shadow28`); at desktop width Fluent's dialog
/// surface (centred, at most 600 wide, its corners 8, 24 round its parts,
/// in `shadow64`). The head ([Fluent2SheetHead]: the [title] and the
/// dismiss button), the body's [children] 8 under it, then the [foot] 16
/// under that: the acts at the end, the primary last (on a phone they
/// share the width). The card scrolls once its parts outgrow it. For a
/// sheet composed in place; [Fluent2Sheet.show] presents this same widget.
///
/// ```dart
/// Fluent2SheetShell(title: 'Share file', foot: [Fluent2Button('Cancel', onPressed: close), Fluent2Button('Share', appearance: Fluent2ButtonAppearance.primary, onPressed: share)], children: [people, message])
/// ```
class Fluent2SheetShell extends StatelessWidget {
  /// A sheet titled [title] over [children], its acts in [foot].
  const Fluent2SheetShell({
    required this.title,
    required this.children,
    this.foot = const [],
    this.close = true,
    this.onClose,
    this.closeKey,
    this.safe = false,
    super.key,
  });

  /// The sheet's title, in its head.
  final String title;

  /// The body's parts, in order.
  final List<Widget> children;

  /// The acts at the card's foot, the primary last.
  final List<Widget> foot;

  /// Whether the head carries the dismiss button.
  final bool close;

  /// What the dismiss does; null pops the sheet's route.
  final VoidCallback? onClose;

  /// The dismiss button's key, for tests and tours.
  final Key? closeKey;

  /// Apply the bottom safe-area inset inside the card (a phone's sheet).
  final bool safe;

  /// Whether [context] stands on a sheet's card.
  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_OnCard>() != null;

  /// The room inside a card: 8 above, 16 at the sides and under on a
  /// phone; 24 round on the desktop.
  static EdgeInsets padding(BuildContext context) =>
      Fluent2Layout.isWide(context)
      ? const EdgeInsets.all(Fluent2ChromeMetrics.dialogPadding)
      : const EdgeInsets.fromLTRB(
          Fluent2ChromeMetrics.sheetSide,
          Fluent2ChromeMetrics.sheetTop,
          Fluent2ChromeMetrics.sheetSide,
          Fluent2ChromeMetrics.sheetBottom,
        );

  /// The foot's acts: on a phone each takes an even share of the width;
  /// from 600 they stand at their own widths at the end, 8 apart.
  static Widget footOf(List<Widget> acts) => Builder(
    builder: (context) => fluent2Roomy(context)
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: Fluent2Spacing.s,
            children: acts,
          )
        : Fluent2ActsFill(
            child: Row(
              spacing: Fluent2Spacing.s,
              children: [for (final act in acts) Expanded(child: act)],
            ),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final wide = Fluent2Layout.isWide(context);
    final inset = safe && !wide ? MediaQuery.paddingOf(context).bottom : 0.0;
    final pad = padding(context);
    return Fluent2SheetCard(
      child: SingleChildScrollView(
        padding: pad.copyWith(bottom: pad.bottom + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!wide) const Fluent2SheetHandle(),
            Fluent2SheetHead(
              title: title,
              close: close
                  ? Fluent2IconButton(
                      Fluent2Icons.dismiss,
                      key: closeKey,
                      label: DesignLocalizations.of(context).closeButtonLabel,
                      onPressed:
                          onClose ?? () => Navigator.of(context).maybePop(),
                    )
                  : null,
            ),
            const SizedBox(height: Fluent2ChromeMetrics.sheetBodyGap),
            ...children,
            if (foot.isNotEmpty) ...[
              const SizedBox(height: Fluent2ChromeMetrics.dialogActionsGap),
              footOf(foot),
            ],
          ],
        ),
      ),
    );
  }
}

/// Where a [Fluent2SheetCard] stands.
enum _SheetPlace { bottom, dialog, side }

/// The card a sheet stands on: the surface with its corners (the top two
/// at 8 on a phone's bottom sheet, all four on the desktop's dialog, the
/// start two on a side drawer), its shadow, its content clipped and
/// marked as on a card ([Fluent2SheetShell.around]). The unnamed
/// constructor stands it as a phone's bottom sheet and a desktop's dialog;
/// [Fluent2SheetCard.bottom], [Fluent2SheetCard.dialog] and
/// [Fluent2SheetCard.side] pick one. Plumbing of the sheets; a page never
/// places one.
class Fluent2SheetCard extends StatelessWidget {
  /// A bottom sheet's card on a phone, a dialog's on the desktop.
  const Fluent2SheetCard({required this.child, super.key}) : _place = null;

  /// A bottom sheet's card: its top corners rounded, shadow28.
  const Fluent2SheetCard.bottom({required this.child, super.key})
    : _place = _SheetPlace.bottom;

  /// A centred dialog's card: all four corners rounded, shadow64.
  const Fluent2SheetCard.dialog({required this.child, super.key})
    : _place = _SheetPlace.dialog;

  /// A side drawer's card at the reading end, square against the window.
  const Fluent2SheetCard.side({required this.child, super.key})
    : _place = _SheetPlace.side;

  /// What stands on the card.
  final Widget child;

  final _SheetPlace? _place;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final at =
        _place ??
        (Fluent2Layout.isWide(context)
            ? _SheetPlace.dialog
            : _SheetPlace.bottom);
    // The theme's sheet or dialog style lends its corner to the sheet's free corners; the corners at
    // the window's edge stay square.
    final look = Fluent2StyleOf([
      at == _SheetPlace.dialog ? t.dialogTheme : t.bottomSheetTheme,
    ], const {});
    final r = Radius.circular(
      fluent2CornerOf(
        look.shape,
        2 * Fluent2ChromeMetrics.sheetRadius * 3,
        Fluent2ChromeMetrics.sheetRadius,
      ),
    );
    final radius = switch (at) {
      _SheetPlace.bottom => BorderRadius.vertical(top: r),
      _SheetPlace.dialog => BorderRadius.all(r),
      _SheetPlace.side => BorderRadius.zero,
    };
    final rim = look.side?.color ?? look.edge;
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: look.fill ?? t.colors.neutralBackground1,
          borderRadius: radius,
          border: rim != null || (t.isDark && at == _SheetPlace.dialog)
              ? Border.all(
                  color: rim ?? t.colors.neutralStroke2,
                  width: look.side?.width ?? Fluent2Stroke.thin,
                )
              : null,
          boxShadow: at == _SheetPlace.bottom
              ? t.shadows.shadow28
              : t.shadows.shadow64,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: _OnCard(child: child),
        ),
      ),
    );
  }
}

class _OnCard extends InheritedWidget {
  const _OnCard({required super.child});

  @override
  bool updateShouldNotify(_OnCard oldWidget) => false;
}

/// Present a sheet: [show] raises a transient one from a control (share,
/// move to, confirm) over the whole app; [pageRoute] is the route a
/// declared sheet PAGE rides ([Fluent2SheetPage]), whose bar becomes the
/// sheet's head with its dismiss.
///
/// On a phone both rise off the bottom edge as Fluent 2's bottom sheet
/// over the overlay; at desktop width [show] and a full sheet page stand
/// centred as Fluent's dialog, and a [Fluent2SheetPage.drawer] page slides
/// in at the window's end as Fluent's overlay drawer. A tap on the
/// overlay, the system back or the dismiss closes them.
///
/// The widget itself is the side panel: a [title] with its dismiss, the
/// [child] scrolling under it and the [actions] at its foot, on the card of
/// an end drawer. [showFluent2Sheet] raises one over the app.
///
/// ```dart
/// final picked = await Fluent2Sheet.show<String>(context, title: 'Move to', builder: (context) => folders);
/// ```
class Fluent2Sheet extends StatelessWidget {
  /// A side panel headed [title] holding [child].
  const Fluent2Sheet({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onClose,
  });

  /// What the panel is.
  final String title;

  /// What it holds; it scrolls past the panel's height.
  final Widget child;

  /// The acts at its foot, the primary last.
  final List<Widget> actions;

  /// What the dismiss does; null pops the panel's route.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Semantics(
    scopesRoute: true,
    namesRoute: true,
    explicitChildNodes: true,
    label: title,
    child: Fluent2SheetCard.side(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Fluent2ChromeMetrics.dialogPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Fluent2SheetHead(
                title: title,
                close: Fluent2IconButton(
                  Fluent2Icons.dismiss,
                  label: DesignLocalizations.of(context).closeButtonLabel,
                  onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: Fluent2ChromeMetrics.sheetBodyGap),
              Expanded(child: SingleChildScrollView(child: child)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: Fluent2ChromeMetrics.dialogActionsGap),
                Fluent2SheetShell.footOf(actions),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  /// The rise and the fall (Fluent's `durationGentle` in, `durationNormal`
  /// out, decelerating and accelerating): none when motion is off
  /// ([Fluent2Motion.on]).
  static AnimationStyle motionOf(BuildContext context) =>
      Fluent2Motion.on(context)
      ? const AnimationStyle(
          duration: Fluent2Motion.gentle,
          curve: Fluent2Motion.decelerateMid,
          reverseDuration: Fluent2Motion.normal,
          reverseCurve: Fluent2Motion.accelerateMid,
        )
      : const AnimationStyle(
          duration: Duration.zero,
          reverseDuration: Duration.zero,
        );

  /// The tallest a sheet stands: 90% of a phone's screen, the window less
  /// 48 at each edge on the desktop.
  static double maxHeight(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).height;
    return Fluent2Layout.isWide(context)
        ? screen - Fluent2ChromeMetrics.dialogMargin * 2
        : screen * Fluent2ChromeMetrics.sheetMaxFraction;
  }

  /// Raises a transient sheet over the whole app (the app's root
  /// navigator, [Fluent2Host.navigatorOf]): a [Fluent2SheetShell] headed by
  /// [title], holding [builder]'s parts and [foot]'s acts. Completes with
  /// the value the sheet pops with: null when it is dismissed.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<Widget> Function(BuildContext context) builder,
    List<Widget> Function(BuildContext context)? foot,
    bool close = true,
  }) {
    final t = context.fluent2Theme;
    final navigator = Fluent2Host.navigatorOf(context);
    final words = MaterialLocalizations.of(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final most = maxHeight(context);
    final motion = motionOf(context);
    Widget shell(BuildContext sheetContext) => RoutePresentationScope(
      presentation: RoutePresentation.sheet,
      child: Fluent2SheetShell(
        title: title,
        close: close,
        safe: true,
        foot: foot?.call(sheetContext) ?? const [],
        children: builder(sheetContext),
      ),
    );
    if (Fluent2Layout.isWide(context)) {
      return navigator.push(
        RawDialogRoute<T>(
          barrierDismissible: true,
          barrierLabel: DesignLocalizations.of(context)
              .modalBarrierDismissLabel,
          barrierColor: t.overlay,
          transitionDuration: motion.duration ?? Duration.zero,
          pageBuilder: (sheetContext, _, _) => themes.wrap(
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Fluent2ChromeMetrics.dialogWidth,
                  maxHeight: most,
                ),
                child: shell(sheetContext),
              ),
            ),
          ),
        ),
      );
    }
    return navigator.push(
      ModalBottomSheetRoute<T>(
        capturedThemes: themes,
        barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
        barrierOnTapHint: words.scrimOnTapHint(words.bottomSheetLabel),
        backgroundColor: const Color(0x00000000),
        modalBarrierColor: t.overlay,
        elevation: 0,
        isScrollControlled: true,
        sheetAnimationStyle: motion,
        constraints: BoxConstraints(maxHeight: most),
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: shell(sheetContext),
        ),
      ),
    );
  }

  /// The modal route a declared sheet page rides: on a phone the bottom
  /// sheet at the tallest a sheet stands, or with [drawer] as tall as its
  /// content; on the desktop the centred dialog, or with [drawer] the
  /// overlay drawer at the window's end.
  static Route<T> pageRoute<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool drawer = false,
  }) {
    final t = context.fluent2Theme;
    final most = maxHeight(context);
    final motion = motionOf(context);
    Widget card(BuildContext sheetContext, _SheetPlace? place) =>
        RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: _PageSheetCard(place: place, child: builder(sheetContext)),
        );
    if (Fluent2Layout.isWide(context)) {
      if (drawer) {
        return RawDialogRoute<T>(
          settings: settings,
          barrierDismissible: true,
          barrierLabel: DesignLocalizations.of(context)
              .modalBarrierDismissLabel,
          barrierColor: t.overlay,
          transitionDuration: motion.duration ?? Duration.zero,
          transitionBuilder: (context, animation, _, child) => SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset(
                    Directionality.of(context) == TextDirection.rtl ? -1 : 1,
                    0,
                  ),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Fluent2Motion.decelerateMid,
                  ),
                ),
            child: child,
          ),
          pageBuilder: (sheetContext, _, _) => Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(
              width: Fluent2ChromeMetrics.drawerWidth,
              height: double.infinity,
              child: card(sheetContext, _SheetPlace.side),
            ),
          ),
        );
      }
      return RawDialogRoute<T>(
        settings: settings,
        barrierDismissible: true,
        barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: t.overlay,
        transitionDuration: motion.duration ?? Duration.zero,
        pageBuilder: (sheetContext, _, _) => Center(
          child: SizedBox(
            width: Fluent2ChromeMetrics.dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: most),
              child: card(sheetContext, _SheetPlace.dialog),
            ),
          ),
        ),
      );
    }
    return ModalBottomSheetRoute<T>(
      settings: settings,
      backgroundColor: const Color(0x00000000),
      modalBarrierColor: t.overlay,
      elevation: 0,
      isScrollControlled: true,
      sheetAnimationStyle: motion,
      constraints: BoxConstraints(maxHeight: most),
      builder: (sheetContext) {
        final keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: drawer
              ? card(sheetContext, _SheetPlace.bottom)
              : SizedBox(
                  height: most - keyboard,
                  child: card(sheetContext, _SheetPlace.bottom),
                ),
        );
      },
    );
  }
}

/// The card a sheet page stands on, the page told it has no status bar
/// above it.
class _PageSheetCard extends StatelessWidget {
  const _PageSheetCard({required this.child, this.place});

  final Widget child;
  final _SheetPlace? place;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final inner = MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(top: 0),
        viewPadding: mq.viewPadding.copyWith(top: 0),
      ),
      child: child,
    );
    return switch (place) {
      null => Fluent2SheetCard(child: inner),
      _SheetPlace.bottom => Fluent2SheetCard.bottom(child: inner),
      _SheetPlace.dialog => Fluent2SheetCard.dialog(child: inner),
      _SheetPlace.side => Fluent2SheetCard.side(child: inner),
    };
  }
}
