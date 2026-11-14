import 'package:material_ui/material_ui.dart'
    show Material, MaterialLocalizations, MaterialType, ModalBottomSheetRoute;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../glyphs.dart';

import '../chrome_metrics.dart';
import '../internal/face.dart';
import 'glass.dart';
import '../internal/styled.dart';
import '../internal/grabber.dart';
import '../internal/soft_routes.dart';
import '../theme.dart';
import 'host.dart';
import 'icon-button/round_button.dart';
import 'menu/menu.dart';
import '../internal/cap.dart';
import '../internal/act_row.dart';

export 'package:ui_core/ui_core.dart' show DesignSheetEdge;

/// A sheet's head (`.sheet-h`): its [title] in the sheet's type (the h1
/// set on a line of 24) and, at its end, the small round close ([close];
/// none for a dialog that closes by its own Cancel), or at its start the
/// way back ([leading], a sheet that closes back), 12 between, at least 40
/// tall. The page sheet's top bar draws it, and [FrostedSheetShell] heads
/// its card with it.
///
/// ```dart
/// FrostedSheetHead(title: 'Category', close: FrostedIconButton(FrostedGlyphs.close, label: DesignLocalizations.of(context).closeButtonLabel, size: FrostedIconButtonSize.small, onPressed: close))
/// ```
class FrostedSheetHead extends StatelessWidget {
  /// Creates a [FrostedSheetHead].
  const FrostedSheetHead({
    required this.title,
    this.close,
    this.leading,
    this.actions = const [],
    super.key,
  });

  /// The sheet's name.
  final String title;

  /// The way back before the title; null draws none.
  final Widget? leading;

  /// The close at the head's end; null draws none.
  final Widget? close;

  /// Controls before the close.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: FrostedChromeMetrics.sheetHead,
      ),
      child: Row(
        spacing: FrostedChromeMetrics.sheetHeadGap,
        children: [
          ?leading,
          Expanded(
            child: Semantics(
              header: true,
              child: frostedCapCentred(
                Text(title, style: t.textTheme.headlineSmall.line(24)),
              ),
            ),
          ),
          ...actions,
          ?close,
        ],
      ),
    );
  }
}

/// A modal sheet's card, drawn in place (`.sheet`): on a phone it rises
/// off the bottom edge, its top corners at 22 and no edge along its foot,
/// the grabber over the head; at desktop width it stands centred, 440 wide,
/// every corner at 20 and no grabber. Its face is the source's: white
/// shading to the palest lilac at its foot, a rim of light along its top,
/// its hairline edge and a soft shadow rising over the scrim. The head
/// ([FrostedSheetHead]: the [title] and the close), then the body's
/// [children] 12 under it (a run of [FrostedOption]s with a hairline between
/// each two, as the source's group of choices), then the [foot] 16 under
/// that: one button takes the whole width, two share it. The card scrolls
/// once its parts outgrow 88% of the screen (the window less 64 at desktop
/// width). For a sheet composed in place; [FrostedSheet.show] presents this
/// same widget, so the two never drift apart.
///
/// ```dart
/// FrostedSheetShell(title: 'Add money', foot: [FrostedButton('Add \$250', onPressed: add)], children: [amount, chips, from])
/// ```
class FrostedSheetShell extends StatelessWidget {
  /// Creates a [FrostedSheetShell].
  const FrostedSheetShell({
    required this.title,
    required this.children,
    this.foot = const [],
    this.close = true,
    this.onClose,
    this.closeKey,
    this.safe = false,
    super.key,
  });

  /// The head's title.
  final String title;

  /// The body's parts, in order.
  final List<Widget> children;

  /// The acts at the card's foot: one takes the whole width, two share it.
  final List<Widget> foot;

  /// Whether the head carries the close (a dialog that closes by its own
  /// Cancel leaves it out).
  final bool close;

  /// What the close does; null dismisses the sheet's route.
  final VoidCallback? onClose;

  /// A key for the close button, where a tap lands.
  final Key? closeKey;

  /// Apply the bottom safe-area inset inside the card (a phone's sheet).
  final bool safe;

  /// Whether [context] stands on a sheet's card.
  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_OnCard>() != null;

  /// The room inside a card: 8 above, 16 at the sides and 24 under on a
  /// phone; 20 above, 24 at the sides and under at desktop width.
  static EdgeInsets padding(BuildContext context) =>
      FrostedBreakpoints.isWide(context)
      ? const EdgeInsets.fromLTRB(
          FrostedChromeMetrics.sheetWideSide,
          FrostedChromeMetrics.sheetWideTop,
          FrostedChromeMetrics.sheetWideSide,
          FrostedChromeMetrics.sheetWideBottom,
        )
      : const EdgeInsets.fromLTRB(
          FrostedChromeMetrics.sheetSide,
          FrostedChromeMetrics.sheetTop,
          FrostedChromeMetrics.sheetSide,
          FrostedChromeMetrics.sheetBottom,
        );

  /// The foot's acts laid out as the source's `.btn-row`: each takes an
  /// even share of the width, the gap of the width apart.
  static Widget footOf(List<Widget> acts) => Builder(
    builder: (context) => Row(
      spacing: FrostedBreakpoints.gap(context),
      // One top and one bottom: each act shows the size the largest asks for.
      children: [
        for (final act in FrostedActRow.wrap(acts)) Expanded(child: act),
      ],
    ),
  );

  /// The body's parts in order, a hairline between two consecutive
  /// [FrostedOption]s (`.opt + .opt { border-top }`): drawn on the later
  /// one's top inside its own 52 (the source's border-box), so options
  /// stand 52 apart.
  static Iterable<Widget> _grouped(List<Widget> parts) sync* {
    for (final (i, part) in parts.indexed) {
      yield i > 0 && part is FrostedOption && parts[i - 1] is FrostedOption
          ? _Ruled(child: part)
          : part;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = FrostedBreakpoints.isWide(context);
    final inset = safe && !wide ? MediaQuery.paddingOf(context).bottom : 0.0;
    final pad = padding(context);
    return FrostedSheetCard(
      child: SingleChildScrollView(
        padding: pad.copyWith(bottom: pad.bottom + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!wide) const FrostedGrabber(),
            FrostedSheetHead(
              title: title,
              close: close
                  ? FrostedIconButton(
                      FrostedGlyphs.close,
                      key: closeKey,
                      label: DesignLocalizations.of(context).closeButtonLabel,
                      size: FrostedIconButtonSize.small,
                      onPressed:
                          onClose ?? () => Navigator.of(context).maybePop(),
                    )
                  : null,
            ),
            const SizedBox(height: FrostedChromeMetrics.sheetBodyGap),
            ..._grouped(children),
            // The source's acts stand in its form's body (`.sheet-b--form
            // { gap: 16px }`), 16 under the last part, not the sheet's 12.
            if (foot.isNotEmpty) ...[
              const SizedBox(height: FrostedChromeMetrics.sheetFormFootGap),
              footOf(foot),
            ],
          ],
        ),
      ),
    );
  }
}

/// The card a sheet stands on, as the source draws it: the sheet's face (on
/// a phone open at its foot, at desktop width a whole dialog with its own
/// shadow), its content clipped to its corners and marked as on a card
/// ([FrostedSheetShell.around]). Plumbing of the sheets; a page never places
/// one.
///
/// ```dart
/// FrostedSheetCard(child: FrostedSheetShell(title: 'Category', children: options))
/// ```
class FrostedSheetCard extends StatelessWidget {
  /// Creates a [FrostedSheetCard].
  const FrostedSheetCard({required this.child, super.key});

  /// The sheet.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    // The theme's sheet style: a phone's sheet is open at its foot, so only
    // the dialog a sheet becomes on the desktop takes its shape.
    final s = FrostedStyleLayers(null, t.components.sheet);
    final (cut, corner) = wide
        ? s.surface(
            FrostedCorners.large,
            FrostedStyleLayers.stockLarge,
            FrostedChromeMetrics.sheetWideRadius,
          )
        : (null, FrostedCorners.r22);
    final radius = wide
        ? BorderRadius.circular(corner)
        : BorderRadius.vertical(top: Radius.circular(corner));
    final fill = s.fill;
    final card = Material(
      // Text defaults for a sheet composed above any Material; paints
      // nothing.
      type: MaterialType.transparency,
      // `.sheet { box-shadow: var(--rim), 0 0 0 1px ..., 0 -18px 48px ... }`:
      // the edge is a ring round the face, taking no room of its own (a
      // face's edge stood the whole sheet 1 in from its sides and 1 under its
      // top: every part 1 right, 1 narrower and 1 low).
      child: FrostedFace(
        material: FrostedMaterial.slab,
        radius: radius,
        shape: cut,
        color: fill,
        sheen: t.glass.rim,
        shadows: [
          ...(wide ? t.shadows.dialog : t.shadows.sheet),
          BoxShadow(
            color: s.edge ?? t.glass.sheetEdge,
            spreadRadius: FrostedStrokes.regular,
          ),
        ],
        clipChild: true,
        child: _OnCard(child: child),
      ),
    );
    if (!wide) return card;
    // On the desktop a sheet is the dialog it becomes, at its width: one
    // composed in place on a wide page stands at that width at the column's
    // start, its foot's acts a sheet's, not a page's.
    return LayoutBuilder(
      builder: (context, box) =>
          box.maxWidth <= FrostedChromeMetrics.sheetWideWidth
          ? card
          : Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: 1,
              child: SizedBox(
                width: FrostedChromeMetrics.sheetWideWidth,
                child: card,
              ),
            ),
    );
  }
}

/// Marks a sheet's card ([FrostedSheetShell.around]).
class _OnCard extends InheritedWidget {
  const _OnCard({required super.child});

  @override
  bool updateShouldNotify(_OnCard oldWidget) => false;
}

/// A sheet, and the ways to present one. As a widget, the panel of a side
/// sheet (shadcn's Sheet): the full height at the screen's [edge], the
/// sheet's face with its rim and drop, its inner corners on the sheet's
/// radius, the head ([FrostedSheetHead]: [title] and the close) over the
/// scrolling [children] and the [foot]'s acts. [showSide] raises one
/// (ui_core's [DesignSideSheetRoute]: a scrim, a drag towards its edge, the
/// system back or Escape close it, focus returning to the control).
///
/// [show] raises a transient sheet from a control (a category, an amount, a
/// confirm) off the bottom edge on a phone and centred as a dialog at
/// desktop width; [pageRoute] is the route a declared sheet PAGE rides,
/// created on the root navigator by the route code ([FrostedSheetPage]):
/// that page is a plain `FrostedScaffold`, whose bar becomes the sheet's
/// head with its close. A tap on the scrim, the system back or the close
/// dismisses them.
///
/// ```dart
/// final picked = await FrostedSheet.show<String>(context, title: 'Category', builder: (context) => [options]);
/// ```
///
/// ```dart
/// FrostedSheet.showSide<void>(context, title: 'Filters', builder: (context) => [FrostedSwitchRow(label: 'Only unread', value: unread, onChanged: setUnread)])
/// ```
class FrostedSheet extends StatelessWidget {
  /// A side sheet's panel at [edge], headed by [title].
  const FrostedSheet({
    required this.title,
    required this.children,
    this.foot = const [],
    this.edge = DesignSheetEdge.end,
    this.onClose,
    super.key,
  });

  /// The head's title.
  final String title;

  /// The body's parts, in order, 12 apart.
  final List<Widget> children;

  /// The acts at the panel's foot: one takes the whole width, two share it.
  final List<Widget> foot;

  /// The screen edge the panel stands at, in reading terms: the end is the
  /// right in English and the left in Arabic. Its corners are rounded on
  /// the other side.
  final DesignSheetEdge edge;

  /// What the close does; null pops the sheet's route.
  final VoidCallback? onClose;

  /// Raises a side sheet at [edge] over the whole app (the root navigator,
  /// [FrostedHost.navigatorOf]): a [FrostedSheet] headed by [title],
  /// holding [builder]'s parts and [foot]'s acts, [width] wide. Completes
  /// with the value the sheet pops with: null when it is dismissed.
  static Future<T?> showSide<T>(
    BuildContext context, {
    required String title,
    required List<Widget> Function(BuildContext context) builder,
    List<Widget> Function(BuildContext context)? foot,
    DesignSheetEdge edge = DesignSheetEdge.end,
    double width = FrostedChromeMetrics.sideSheetWidth,
  }) {
    final navigator = FrostedHost.navigatorOf(context);
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final (scrim, soften) = _below(context);
    return navigator.push(
      FrostedSoftSideSheetRoute<T>(
        soften: soften,
        edge: edge,
        width: width,
        barrierColor: scrim,
        barrierLabel: MaterialLocalizations.of(context).scrimLabel,
        semanticLabel: title,
        transitionDuration: motionOf(context).duration ?? Duration.zero,
        builder: (sheetContext, sheet) => themes.wrap(
          RoutePresentationScope(
            presentation: RoutePresentation.sheet,
            child: FrostedSheet(
              title: title,
              edge: edge,
              onClose: sheet.close,
              foot: foot?.call(sheetContext) ?? const [],
              children: builder(sheetContext),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final s = FrostedStyleLayers(null, t.components.sheet);
    final inner = Radius.circular(FrostedCorners.r22);
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final atLeft = (edge == DesignSheetEdge.start) == ltr;
    final radius = BorderRadius.horizontal(
      left: atLeft ? Radius.zero : inner,
      right: atLeft ? inner : Radius.zero,
    );
    final fill = s.fill;
    final safe = MediaQuery.paddingOf(context);
    return Material(
      type: MaterialType.transparency,
      child: FrostedFace(
        material: FrostedMaterial.slab,
        radius: radius,
        color: fill,
        sheen: t.glass.rim,
        shadows: [
          ...t.shadows.sheet,
          BoxShadow(
            color: s.edge ?? t.glass.sheetEdge,
            spreadRadius: FrostedStrokes.regular,
          ),
        ],
        clipChild: true,
        child: _OnCard(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              FrostedChromeMetrics.sheetWideSide + (atLeft ? safe.left : 0),
              FrostedChromeMetrics.sheetWideTop + safe.top,
              FrostedChromeMetrics.sheetWideSide + (atLeft ? 0 : safe.right),
              FrostedChromeMetrics.sheetWideBottom + safe.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrostedSheetHead(
                  title: title,
                  close: FrostedIconButton(
                    FrostedGlyphs.close,
                    label: DesignLocalizations.of(context).closeButtonLabel,
                    size: FrostedIconButtonSize.small,
                    onPressed:
                        onClose ?? () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: FrostedChromeMetrics.sheetBodyGap),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: FrostedChromeMetrics.sheetBodyGap,
                      children: [...FrostedSheetShell._grouped(children)],
                    ),
                  ),
                ),
                if (foot.isNotEmpty) ...[
                  const SizedBox(height: FrostedChromeMetrics.sheetFormFootGap),
                  FrostedSheetShell.footOf(foot),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What a sheet does to the page below it at [context]: the materials'
  /// scrim, and the blur the page softens by (none without transparency).
  static (Color, double) _below(BuildContext context) {
    final m = context.frostedTheme.materials;
    return (m.scrim, frostedOpaqueAt(context) ? 0.0 : m.soften);
  }

  /// The rise and the fall at [context]: none at all under Reduce Motion
  /// ([FrostedMotion.of]).
  static AnimationStyle motionOf(BuildContext context) =>
      FrostedMotion.of(context).moves
      ? const AnimationStyle(
          duration: FrostedChromeMetrics.sheetIn,
          curve: Curves.easeOutCubic,
          reverseDuration: FrostedChromeMetrics.sheetOut,
          reverseCurve: Curves.easeInCubic,
        )
      : const AnimationStyle(
          duration: Duration.zero,
          reverseDuration: Duration.zero,
        );

  /// The tallest a sheet stands on [screen]: 88% of it on a phone, the
  /// window less 64 at desktop width.
  static double maxHeight(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).height;
    return FrostedBreakpoints.isWide(context)
        ? screen - FrostedChromeMetrics.sheetWideMargin
        : screen * FrostedChromeMetrics.sheetMaxFraction;
  }

  /// Raises a transient sheet over the whole app (the app's root navigator,
  /// [FrostedHost.navigatorOf]): an [FrostedSheetShell] headed by [title],
  /// holding [builder]'s parts and [foot]'s acts. Completes with the value
  /// the sheet pops with: null when it is dismissed (the close, a drag
  /// down, the scrim).
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<Widget> Function(BuildContext context) builder,
    List<Widget> Function(BuildContext context)? foot,
    bool close = true,
  }) {
    return raise<T>(
      context,
      (sheetContext) => FrostedSheetShell(
        title: title,
        close: close,
        safe: true,
        foot: foot?.call(sheetContext) ?? const [],
        children: builder(sheetContext),
      ),
    );
  }

  /// Raises [builder]'s card over the whole app (the app's root navigator,
  /// [FrostedHost.navigatorOf]) as a sheet raises one: off the bottom edge
  /// over the scrim on a phone, centred as a dialog at desktop width, the
  /// keyboard riding outside the card. Completes with the value the route
  /// pops with: null when dismissed. [FrostedSheet.show] and
  /// [showFrostedBottomSheet] raise through it.
  static Future<T?> raise<T>(BuildContext context, WidgetBuilder builder) {
    final (scrim, soften) = _below(context);
    final navigator = FrostedHost.navigatorOf(context);
    final words = MaterialLocalizations.of(context);
    // As showModalBottomSheet does: the caller's themes ride along.
    final themes = InheritedTheme.capture(from: context, to: navigator.context);
    final most = maxHeight(context);
    Widget shell(BuildContext sheetContext) => RoutePresentationScope(
      presentation: RoutePresentation.sheet,
      child: builder(sheetContext),
    );
    if (FrostedBreakpoints.isWide(context)) {
      return navigator.push(
        FrostedSoftDialogRoute<T>(
          soften: soften,
          barrierDismissible: true,
          barrierLabel: words.scrimLabel,
          barrierColor: scrim,
          transitionDuration: motionOf(context).duration ?? Duration.zero,
          pageBuilder: (sheetContext, _, _) => themes.wrap(
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: FrostedChromeMetrics.sheetWideWidth,
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
      _FrostedSoftSheetRoute<T>(
        soften: soften,
        capturedThemes: themes,
        barrierLabel: words.scrimLabel,
        barrierOnTapHint: words.scrimOnTapHint(words.bottomSheetLabel),
        backgroundColor: const Color(0x00000000),
        modalBarrierColor: scrim,
        elevation: 0,
        isScrollControlled: true,
        sheetAnimationStyle: motionOf(context),
        constraints: BoxConstraints(maxHeight: most),
        builder: (sheetContext) => Padding(
          // The keyboard rides outside the card: the card keeps its geometry
          // and simply sits higher.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: shell(sheetContext),
        ),
      ),
    );
  }

  /// The modal route a declared sheet page rides: the page stands on the
  /// sheet's card at the tallest a sheet stands, or with [drawer] as tall
  /// as its content (a short task that leaves the page it came from in
  /// view). At desktop width it is the centred dialog.
  static Route<T> pageRoute<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool drawer = false,
  }) {
    final (scrim, soften) = _below(context);
    // Measured on the presenting screen: the modal layer sits above the app's
    // own insets and would report none.
    final most = maxHeight(context);
    Widget card(BuildContext sheetContext) => RoutePresentationScope(
      presentation: RoutePresentation.sheet,
      child: _PageSheetCard(child: builder(sheetContext)),
    );
    if (FrostedBreakpoints.isWide(context)) {
      return FrostedSoftDialogRoute<T>(
        soften: soften,
        settings: settings,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).scrimLabel,
        barrierColor: scrim,
        transitionDuration: motionOf(context).duration ?? Duration.zero,
        pageBuilder: (sheetContext, _, _) => Center(
          child: SizedBox(
            width: FrostedChromeMetrics.sheetWideWidth,
            height: drawer ? null : most,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: most),
              child: card(sheetContext),
            ),
          ),
        ),
      );
    }
    return _FrostedSoftSheetRoute<T>(
      soften: soften,
      settings: settings,
      backgroundColor: const Color(0x00000000),
      modalBarrierColor: scrim,
      elevation: 0,
      isScrollControlled: true,
      sheetAnimationStyle: motionOf(context),
      constraints: BoxConstraints(maxHeight: most),
      builder: (sheetContext) {
        final keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: drawer
              ? card(sheetContext)
              : SizedBox(height: most - keyboard, child: card(sheetContext)),
        );
      },
    );
  }
}

/// The card a sheet page stands on: the sheet's face, and the page told it
/// has no status bar above it.
class _PageSheetCard extends StatelessWidget {
  const _PageSheetCard({required this.child});

  /// The page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return FrostedSheetCard(
      child: MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(top: 0),
          viewPadding: mq.viewPadding.copyWith(top: 0),
        ),
        child: child,
      ),
    );
  }
}

/// The hairline over an option after another (`.opt + .opt`): painted
/// over its top pixel, taking no room of its own.
class _Ruled extends StatelessWidget {
  const _Ruled({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: context.frostedTheme.colorScheme.border,
          width: FrostedChromeMetrics.outline,
        ),
      ),
    ),
    child: child,
  );
}

/// A sheet over the page for a short task: the sheet's card (its head with
/// [title] and the close, then [child], then the [actions] at its foot: one
/// takes the whole width, two share it), rising off the bottom edge on a
/// phone and centred as a dialog at desktop width. This is the card;
/// [showFrostedBottomSheet] raises it. [onClose] runs on the close; null
/// dismisses the sheet's route.
///
/// ```dart
/// showFrostedBottomSheet<void>(context, builder: (context) => FrostedBottomSheet(title: 'Share', actions: [FrostedButton('Copy link', onPressed: copy)], child: shareTargets))
/// ```
class FrostedBottomSheet extends StatelessWidget {
  /// A sheet holding [child].
  const FrostedBottomSheet({
    required this.child,
    this.title,
    this.actions = const [],
    this.onClose,
    super.key,
  });

  /// The head's title; null leaves the head the close alone.
  final String? title;

  /// What the sheet holds.
  final Widget child;

  /// The acts at its foot.
  final List<Widget> actions;

  /// What the close does; null dismisses the sheet's route.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => FrostedSheetShell(
    title: title ?? '',
    onClose: onClose,
    safe: true,
    foot: actions,
    children: [child],
  );
}

/// Raises [builder]'s [FrostedBottomSheet] over the whole app, as
/// `showModalBottomSheet` does: off the bottom edge over the scrim on a
/// phone, centred as a dialog at desktop width; a tap on the scrim, the
/// system back, Escape or a drag down dismisses it, and focus returns to
/// what opened it. Completes with the value the sheet pops with: null when
/// dismissed. Rises in [FrostedSheet.motionOf]'s time (a cut under Reduce
/// Motion).
///
/// ```dart
/// final choice = await showFrostedBottomSheet<String>(context, builder: (context) => FrostedBottomSheet(title: 'Sort by', child: options));
/// ```
Future<T?> showFrostedBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => FrostedSheet.raise<T>(context, builder);

/// The phone's sheet route, softening the page below.
class _FrostedSoftSheetRoute<T> extends ModalBottomSheetRoute<T>
    with FrostedSoftensBelow<T> {
  /// A sheet route softening the page below by [soften].
  _FrostedSoftSheetRoute({
    required this.soften,
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.backgroundColor,
    super.modalBarrierColor,
    super.elevation,
    super.constraints,
    super.sheetAnimationStyle,
    super.settings,
  });

  @override
  final double soften;
}
