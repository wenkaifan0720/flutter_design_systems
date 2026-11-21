/// Clay's surfaces over a page: a dialog, a sheet, a side sheet and an
/// action sheet that float up as clay over a dimmed ground, and a toast.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'surface.dart';
import 'theme.dart';

/// One key of a [ClayDialog].
@immutable
class ClayDialogAction {
  /// A key reading [label].
  const ClayDialogAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  /// Its words.
  final String label;

  /// Called on a press.
  final VoidCallback? onPressed;

  /// Whether it is the dialog's one action: the coral key.
  final bool primary;

  /// Whether it destroys something: the danger key (with [primary]) or
  /// danger words.
  final bool destructive;
}

/// A Clay dialog: a floating slab of white clay, rounded 32, its [title],
/// its [content] in the secondary ink, and its keys at its foot (stacked
/// full width when they do not fit side by side). The safe key takes the
/// focus as it opens.
///
/// ```dart
/// ClayDialog(title: 'Delete this habit?', content: const Text('Its 42-day streak goes with it.'), actions: [ClayDialogAction(label: 'Keep', onPressed: () {}), ClayDialogAction(label: 'Delete', onPressed: () {}, primary: true, destructive: true)])
/// ```
class ClayDialog extends StatelessWidget {
  /// A dialog titled [title].
  const ClayDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const [],
    this.style,
  });

  /// What the dialog asks or says.
  final String title;

  /// More words under the title.
  final Widget? content;

  /// Its keys, the safe one first.
  final List<ClayDialogAction> actions;

  /// This dialog's own style, over [ClayThemeData.dialogStyle]: `fill` the
  /// slab.
  final ClayStyle? style;

  /// The widest a dialog stands.
  static const double maxWidth = 440;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.dialogStyle], const {});
    final routed = ModalRoute.of(context) is DesignDialogRoute;
    final dialog = RawAlertDialog(
      title: title,
      content: content == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: ClaySpacing.small),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.body.copyWith(color: c.inkSecondary),
                child: content!,
              ),
            ),
      actions: [
        for (final a in actions)
          RawDialogAction(
            label: a.label,
            onPressed: a.onPressed,
            isDefaultAction: a.primary,
            isDestructiveAction: a.destructive,
          ),
      ],
      insetPadding: routed
          ? const EdgeInsets.all(ClaySpacing.large)
          : EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: maxWidth),
      actionSpacing: ClaySpacing.medium,
      stackedActionSpacing: ClaySpacing.medium,
      titleBuilder: (context, title) => Text(
        title,
        style: theme.textTheme.headline.copyWith(
          fontSize: 22,
          height: 28 / 22,
          color: c.ink,
        ),
      ),
      actionsBuilder: (context, details, child) => Padding(
        padding: const EdgeInsets.only(top: ClaySpacing.large),
        child: child,
      ),
      frameBuilder: (context, details, child) => ClaySurface(
        face: ClayFace.floating(
          c,
          color: layered.fill,
          radius: clayRadiusOf(layered.shape, ClayRadius.extraLarge),
        ),
        child: DesignKeylineRegion(
          label: 'Dialog',
          child: Padding(
            padding: const EdgeInsets.all(ClaySpacing.large),
            child: child,
          ),
        ),
      ),
      actionBuilder: (context, action, details) {
        final key = ClayButtonFace(
          label: action.label,
          states: details.states,
          kind: action.isDefaultAction
              ? ClayButtonKind.filled
              : ClayButtonKind.clay,
          isDestructiveAction: action.isDestructiveAction,
        );
        return details.stacked
            ? SizedBox(width: double.infinity, child: key)
            : key;
      },
    );
    if (routed) return dialog;
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: dialog,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(IntProperty('actions', actions.length));
  }
}

/// Clay's scrim: the ground dimmed in the ink's own hue as a surface arrives.
DesignBarrierBuilder _scrim(Color color) =>
    (context, animation) => AnimatedBuilder(
      animation: animation,
      builder: (context, _) => ColoredBox(
        color: color.withValues(
          alpha:
              color.a *
              Curves.easeOut.transform(animation.value.clamp(0.0, 1.0)),
        ),
        child: const SizedBox.expand(),
      ),
    );

/// A surface floating up as clay: it fades in, rises 12 px and inflates
/// from [from] of its size, on its route's presence; no bounce.
class _Inflate extends StatelessWidget {
  const _Inflate({
    required this.animation,
    required this.child,
    this.from = 0.94,
    this.rise = 12,
    this.alignment = Alignment.center,
  });

  final Animation<double> animation;
  final Widget child;
  final double from;
  final double rise;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform((t / 0.6).clamp(0.0, 1.0)),
          child: still
              ? child
              : Transform.translate(
                  offset: Offset(0, (1 - t) * rise),
                  child: Transform.scale(
                    scale: from + (1 - from) * t,
                    alignment: alignment,
                    child: child,
                  ),
                ),
        );
      },
    );
  }
}

/// Shows a [ClayDialog] (or any page [builder] paints) over a dimmed ground:
/// it floats up and inflates into place. [isAlert] makes a screen reader
/// announce it as an alert; [barrierDismissible] lets a tap beside it close
/// it (true unless it is an alert).
///
/// ```dart
/// showClayDialog<bool>(context: context, isAlert: true, builder: (context) => const ClayDialog(title: 'Delete this habit?'))
/// ```
Future<T?> showClayDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isAlert = false,
  bool? barrierDismissible,
}) {
  final theme = ClayTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    DesignDialogRoute<T>(
      isAlert: isAlert,
      barrierDismissible: barrierDismissible,
      barrierLabel: RawWidgetsLocalizations.of(context)
          .modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim),
      dampingRatio: ClayMotion.panelDamping,
      stiffness: ClayMotion.panelStiffness,
      closeDampingRatio: 1,
      closeStiffness: 900,
      builder: (context, details) => ClayTheme(
        data: theme,
        child: _Inflate(
          animation: details.animation,
          child: Builder(builder: builder),
        ),
      ),
    ),
  );
}

/// Shows a Clay sheet: a slab of clay floating up from the foot of the
/// screen (edge to edge on a phone, its top corners rounded 32; a floating
/// card from 600 px), a grip pressed into its top, its [title] and a close
/// ball, [builder]'s content under them and [footerBuilder]'s keys at its
/// foot. A drag down or a tap beside it closes it; Escape and Android's back
/// do too.
///
/// ```dart
/// showClayBottomSheet<void>(context: context, title: 'Reminder time', builder: (context) => const Text('8:00'))
/// ```
Future<T?> showClayBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  WidgetBuilder? footerBuilder,
  ClayStyle? style,
}) {
  final theme = ClayTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SheetRoute<T>(
      barrierLabel: words.modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim),
      semanticLabel: title,
      builder: (context, details) => ClayTheme(
        data: theme,
        child: _TapBeside(
          close: details.close,
          child: _Sheet(
            title: title,
            builder: builder,
            footer: footerBuilder,
            scrollController: details.scrollController,
            style: style,
          ),
        ),
      ),
    ),
  );
}

class _SheetRoute<T> extends RawBottomSheetRoute<T> {
  _SheetRoute({
    super.settings,
    required super.builder,
    required String super.barrierLabel,
    required super.barrierBuilder,
    super.semanticLabel,
    super.snapSizes,
  }) : super(
         dampingRatio: ClayMotion.panelDamping,
         stiffness: ClayMotion.panelStiffness,
         closeDampingRatio: 1,
         closeStiffness: 900,
       );

  @override
  bool get semanticsDismissible => false;
}

class _TapBeside extends StatelessWidget {
  const _TapBeside({required this.close, required this.child});

  final VoidCallback close;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: close,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () {},
        child: child,
      ),
    ),
  );
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.title,
    required this.builder,
    required this.scrollController,
    this.footer,
    this.style,
  });

  final String? title;
  final WidgetBuilder builder;
  final WidgetBuilder? footer;
  final ScrollController scrollController;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.sheetStyle], const {});
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final framed = size.width >= 600;
    final side = framed
        ? ClaySpacing.large
        : ClaySpacing.pageMargin(size.width);
    final words = RawWidgetsLocalizations.of(context);
    const radius = ClayRadius.extraLarge;
    final panel = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The grip: a short groove pressed into the slab's top.
        Padding(
          padding: const EdgeInsets.only(
            top: ClaySpacing.small + 2,
            bottom: ClaySpacing.tight,
          ),
          child: Center(
            child: SizedBox(
              width: 44,
              height: 6,
              child: ClaySurface(face: ClayFace.well(c, radius: 3)),
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: side),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      header: true,
                      child: Text(
                        title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.title.copyWith(color: c.ink),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: framed ? ClaySpacing.regular : side,
                ),
                child: ClayIconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: words.closeButtonLabel,
                  icon: const Icon(LucideIcons.x, size: 18),
                  style: const ClayStyle(
                    minimumSize: WidgetStatePropertyAll(Size(36, 36)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              side,
              ClaySpacing.small,
              side,
              footer != null
                  ? ClaySpacing.regular
                  : ClaySpacing.large + (framed ? 0 : pad.bottom),
            ),
            child: DesignKeylineRegion(
              label: title ?? 'Sheet',
              child: DefaultTextStyle.merge(
                style: theme.textTheme.body.copyWith(color: c.ink),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              side,
              ClaySpacing.small,
              side,
              ClaySpacing.large + (framed ? 0 : pad.bottom),
            ),
            child: Builder(builder: footer!),
          ),
      ],
    );
    final sheet = ClaySurface(
      face: ClayFace.floating(c, color: layered.fill, radius: radius),
      child: framed
          ? panel
          : Padding(
              padding: const EdgeInsets.only(bottom: radius),
              child: panel,
            ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: framed ? 560 : double.infinity,
        maxHeight: size.height * 0.88,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: framed ? ClaySpacing.large : 0,
          left: framed ? ClaySpacing.large : 0,
          right: framed ? ClaySpacing.large : 0,
        ),
        child: framed
            ? sheet
            : Transform.translate(
                offset: const Offset(0, radius),
                child: sheet,
              ),
      ),
    );
  }
}

/// The router's page for a route raised as a sheet: its screen on a slab
/// of clay floated up from the foot of the screen, a grip pressed into its
/// top, edge to edge on a phone and a floating card, 560 wide, from 600. It
/// stands at most 88% of the screen tall, or as tall as its content when
/// [drawer]; [fullScreen] raises a whole page instead. Its screen reads the
/// route as a sheet ([RoutePresentation.sheet]), so the bar's way out is a
/// close. A tap beside it, a drag down, Escape or Back closes it. A
/// go_router route's `pageBuilder` returns it with the route's
/// `state.pageKey`.
///
/// ```dart
/// ClaySheetPage<void>(key: state.pageKey, child: const EditHabitPage())
/// ```
class ClaySheetPage<T> extends Page<T> {
  /// A sheet of [child].
  const ClaySheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The sheet's screen, usually a `ClayScreen`.
  final Widget child;

  /// Whether it stands as tall as its content rather than 88% of the
  /// screen.
  final bool drawer;

  /// Whether it is raised as a whole page rather than a sheet.
  final bool fullScreen;

  @override
  Route<T> createRoute(BuildContext context) {
    final theme = ClayTheme.of(context);
    // The page as it stands now: a router that updates the page in place
    // hands the route the new one.
    Widget current(BuildContext context) {
      final page = ModalRoute.of(context)?.settings;
      return page is ClaySheetPage ? page.child : child;
    }

    Widget scoped(Widget child) => ClayTheme(
      data: theme,
      child: RoutePresentationScope(
        presentation: RoutePresentation.sheet,
        child: child,
      ),
    );
    if (fullScreen) {
      // A whole page rising from the foot of the screen on the ground.
      final rise = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return PageRouteBuilder<T>(
        settings: this,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, _, _) => scoped(
          ColoredBox(color: theme.colors.ground, child: current(context)),
        ),
        transitionsBuilder: (context, animation, _, child) =>
            SlideTransition(position: animation.drive(rise), child: child),
      );
    }
    // A drawer stands at its content's height; a sheet rests at 88% of the
    // screen, its screen scrolling in it.
    return _SheetRoute<T>(
      settings: this,
      barrierLabel: RawWidgetsLocalizations.of(context)
          .modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim),
      snapSizes: drawer ? null : const [0.88],
      builder: (context, details) => scoped(
        _TapBeside(
          close: details.close,
          child: _PageSheet(
            drawer: drawer,
            child: Builder(builder: current),
          ),
        ),
      ),
    );
  }
}

/// A [ClaySheetPage]'s slab: the grip and the screen under it, framed as
/// [showClayBottomSheet]'s.
class _PageSheet extends StatelessWidget {
  const _PageSheet({required this.drawer, required this.child});

  final bool drawer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final size = MediaQuery.sizeOf(context);
    final framed = size.width >= ClayMetrics.railBreakpoint;
    const radius = ClayRadius.extraLarge;
    final panel = Column(
      mainAxisSize: drawer ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The grip: a short groove pressed into the slab's top. The whole
        // slab drags (the route's); the screen's bar closes it for keys and
        // screen readers.
        Padding(
          padding: const EdgeInsets.only(
            top: ClaySpacing.small,
            bottom: ClaySpacing.tight,
          ),
          child: Center(
            child: SizedBox(
              width: 44,
              height: 6,
              child: ClaySurface(face: ClayFace.well(c, radius: 3)),
            ),
          ),
        ),
        if (drawer) Flexible(child: child) else Expanded(child: child),
      ],
    );
    // A phone's slab runs a corner's height past the screen's foot, so only
    // its top corners show.
    final sheet = ClaySurface(
      face: ClayFace.floating(
        c,
        color: DesignStyleOf([theme.sheetStyle], const {}).fill,
        radius: radius,
      ),
      child: framed
          ? panel
          : Padding(
              padding: const EdgeInsets.only(bottom: radius),
              child: panel,
            ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: framed ? 560 : double.infinity,
        maxHeight: size.height * 0.88,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: framed ? ClaySpacing.large : 0,
          left: framed ? ClaySpacing.large : 0,
          right: framed ? ClaySpacing.large : 0,
        ),
        child: framed
            ? sheet
            : Transform.translate(
                offset: const Offset(0, radius),
                child: sheet,
              ),
      ),
    );
  }
}

/// Shows a Clay side sheet: a tall slab of clay floating in from the
/// window's [edge] (its end by default), its [title] and a close ball at its
/// top, [builder]'s content under them and [footerBuilder]'s keys at its
/// foot. A tap beside it, a drag toward its edge, Escape and Android's back
/// close it.
///
/// ```dart
/// showClaySideSheet<void>(context: context, title: 'Filters', builder: (context) => const Text('Every habit'))
/// ```
Future<T?> showClaySideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  WidgetBuilder? footerBuilder,
  RawSheetEdge edge = RawSheetEdge.end,
  double width = 400,
  ClayStyle? style,
}) {
  final theme = ClayTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  // Over the whole window (a sidebar included), as a sheet and a dialog are.
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SideSheetRoute<T>(
      edge: edge,
      width: width,
      barrierBuilder: _scrim(theme.colors.scrim),
      barrierLabel: words.modalBarrierDismissLabel,
      semanticLabel: title,
      builder: (context, sheet) => ClayTheme(
        data: theme,
        child: _SidePanel(
          info: sheet,
          title: title,
          builder: builder,
          footer: footerBuilder,
          style: style,
        ),
      ),
    ),
  );
}

class _SideSheetRoute<T> extends RawSideSheetRoute<T> {
  _SideSheetRoute({
    required super.builder,
    super.edge,
    super.width,
    super.barrierBuilder,
    super.barrierLabel,
    super.semanticLabel,
  }) : super(
         dampingRatio: ClayMotion.panelDamping,
         stiffness: ClayMotion.panelStiffness,
         closeDampingRatio: 1,
         closeStiffness: 900,
       );

  @override
  bool get semanticsDismissible => false;
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.info,
    required this.title,
    required this.builder,
    required this.footer,
    required this.style,
  });

  final RawSideSheetDetails info;
  final String? title;
  final WidgetBuilder builder;
  final WidgetBuilder? footer;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.sheetStyle], const {});
    final words = RawWidgetsLocalizations.of(context);
    final pad = MediaQuery.paddingOf(context);
    // It floats a little in from the window's edges, as every Clay slab
    // floats over its ground, so its corners round whole.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClaySpacing.small,
        ClaySpacing.small + pad.top,
        ClaySpacing.small,
        ClaySpacing.small + pad.bottom,
      ),
      child: ClaySurface(
        face: ClayFace.floating(
          c,
          color: layered.fill,
          radius: ClayRadius.extraLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 72,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: ClaySpacing.large,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Semantics(
                          header: true,
                          child: Text(
                            title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.title.copyWith(color: c.ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: ClaySpacing.regular,
                    ),
                    child: ClayIconButton(
                      onPressed: info.close,
                      tooltip: words.closeButtonLabel,
                      icon: const Icon(LucideIcons.x, size: 18),
                      style: const ClayStyle(
                        minimumSize: WidgetStatePropertyAll(Size(36, 36)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClaySpacing.large,
                  ClaySpacing.tight,
                  ClaySpacing.large,
                  ClaySpacing.large,
                ),
                child: DesignKeylineRegion(
                  label: title ?? 'Side sheet',
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.body.copyWith(color: c.ink),
                    child: Builder(builder: builder),
                  ),
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClaySpacing.large,
                  ClaySpacing.small,
                  ClaySpacing.large,
                  ClaySpacing.large,
                ),
                child: Builder(builder: footer!),
              ),
          ],
        ),
      ),
    );
  }
}

/// One choice of a Clay action sheet.
@immutable
class ClaySheetAction<T> {
  /// A choice named [label] that gives [value].
  const ClaySheetAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructiveAction = false,
    this.enabled = true,
  });

  /// Its words.
  final String label;

  /// What choosing it gives back.
  final T value;

  /// Its glyph, before the words.
  final IconData? icon;

  /// Whether it destroys something: its words in the danger ink.
  final bool isDestructiveAction;

  /// Whether it can be chosen.
  final bool enabled;
}

/// Shows a Clay action sheet: a slab floating up from the foot of the
/// screen with its [title], [message] and a key per action, and a second
/// slab under it holding Cancel. Gives back the chosen action's value, or
/// null.
///
/// ```dart
/// showClayActionSheet<String>(context: context, title: 'Drink water', actions: const [ClaySheetAction(label: 'Pause', value: 'pause'), ClaySheetAction(label: 'Delete', value: 'delete', isDestructiveAction: true)])
/// ```
Future<T?> showClayActionSheet<T>({
  required BuildContext context,
  required List<ClaySheetAction<T>> actions,
  String? title,
  String? message,
  String? cancelLabel,
}) {
  final theme = ClayTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    _SheetRoute<T>(
      barrierLabel: words.modalBarrierDismissLabel,
      barrierBuilder: _scrim(theme.colors.scrim),
      semanticLabel: title,
      builder: (context, details) => ClayTheme(
        data: theme,
        child: _TapBeside(
          close: details.close,
          child: _ActionSheet<T>(
            title: title,
            message: message,
            actions: actions,
            cancelLabel: cancelLabel ?? words.cancelButtonLabel,
          ),
        ),
      ),
    ),
  );
}

class _ActionSheet<T> extends StatelessWidget {
  const _ActionSheet({
    required this.title,
    required this.message,
    required this.actions,
    required this.cancelLabel,
  });

  final String? title;
  final String? message;
  final List<ClaySheetAction<T>> actions;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final pad = MediaQuery.paddingOf(context);
    final navigator = Navigator.of(context);
    final face = ClayFace.floating(c, radius: ClayRadius.extraLarge);
    // The route names it for a screen reader (its title).
    return Semantics(
      explicitChildNodes: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ClaySpacing.small,
            0,
            ClaySpacing.small,
            ClaySpacing.small + pad.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClaySurface(
                face: face,
                child: Padding(
                  padding: const EdgeInsets.all(ClaySpacing.regular),
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
                            style: theme.textTheme.label.copyWith(
                              color: c.inkSecondary,
                            ),
                          ),
                        ),
                      if (message != null) ...[
                        const SizedBox(height: ClaySpacing.tight),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.secondary,
                        ),
                      ],
                      if (title != null || message != null)
                        const SizedBox(height: ClaySpacing.regular),
                      for (final (i, a) in actions.indexed) ...[
                        if (i > 0) const SizedBox(height: ClaySpacing.small),
                        ClayButton(
                          a.label,
                          icon: a.icon == null ? null : Icon(a.icon),
                          isDestructiveAction: a.isDestructiveAction,
                          onPressed: a.enabled
                              ? () => navigator.pop<T>(a.value)
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ClaySpacing.small),
              ClaySurface(
                face: face,
                child: Padding(
                  padding: const EdgeInsets.all(ClaySpacing.small),
                  child: ClayButton.text(
                    cancelLabel,
                    onPressed: () => navigator.pop(),
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

/// Puts Clay's toasts over [child]: short notes floating up from the foot of
/// the screen as small slabs of white clay, an action and a close ball at
/// their end. Wrap an app's pages in it (a `MaterialApp`'s builder) and show
/// one with [showClayToast].
///
/// ```dart
/// ClayToaster(child: child)
/// ```
class ClayToaster extends StatelessWidget {
  /// Toasts over [child].
  const ClayToaster({super.key, required this.child, this.style});

  /// The app.
  final Widget child;

  /// The toasts' own style, over [ClayThemeData.toastStyle]: `fill` the
  /// slab.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) => RawToaster(
    dampingRatio: ClayMotion.panelDamping,
    stiffness: ClayMotion.panelStiffness,
    constraints: const BoxConstraints(maxWidth: 480),
    padding: const EdgeInsets.fromLTRB(
      ClaySpacing.regular,
      ClaySpacing.regular,
      ClaySpacing.regular,
      ClaySpacing.large,
    ),
    toastBuilder: (context, details) => _Toast(details, style),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClayStyle>('style', style));
  }
}

class _Toast extends StatelessWidget {
  const _Toast(this.details, this.style);

  final RawToastDetails details;
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final t = details.toast;
    final words = RawWidgetsLocalizations.of(context);
    final layered = DesignStyleOf([style, theme.toastStyle], const {});
    final face = ClayFace.floating(
      c,
      color: layered.fill,
      radius: ClayRadius.large,
    ).copyWith(focus: details.focused ? 1 : 0);
    return _Inflate(
      animation: details.animation,
      from: 0.96,
      rise: 16,
      alignment: Alignment.bottomCenter,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: ClaySurface(
          face: face,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: ClaySpacing.roomy,
                end: ClaySpacing.small,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: ClaySpacing.medium,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (t.title != null)
                            Text(
                              t.title!,
                              style: theme.textTheme.label.copyWith(
                                color: c.ink,
                              ),
                            ),
                          Text(
                            t.message,
                            style: theme.textTheme.body.copyWith(
                              fontSize: 15,
                              height: 20 / 15,
                              color: c.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (t.actionLabel != null && details.runAction != null) ...[
                    const SizedBox(width: ClaySpacing.small),
                    ClayButton.text(
                      t.actionLabel!,
                      onPressed: details.runAction,
                    ),
                    const SizedBox(width: ClaySpacing.small),
                  ],
                  ClayIconButton.plain(
                    onPressed: details.dismiss,
                    tooltip: words.closeButtonLabel,
                    icon: const Icon(LucideIcons.x, size: 18),
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

/// Shows a toast reading [message] under the nearest [ClayToaster], with an
/// action ([actionLabel], [onAction]) when given; it goes after [duration]
/// (never while the pointer or the focus rests on it), or stays with null.
///
/// ```dart
/// showClayToast(context, 'Habit archived', actionLabel: 'Undo')
/// ```
RawToastController showClayToast(
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
