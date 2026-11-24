/// Brutal's overlays: [BrutalDialog] and [showBrutalDialog], a square panel
/// on the hard shadow whose actions are cells across its foot;
/// [showBrutalBottomSheet] and [showBrutalSheet], a [BrutalSheet] from the
/// bottom edge under a heavy rule, and [BrutalSheetPage], a router's page
/// raised as one; and [BrutalToaster] with [showBrutalToast], an ink block
/// that says what just happened.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'internal/focus_ink.dart';
import 'internal/ruled_column.dart';
import 'lists.dart';
import 'surface.dart';
import 'theme.dart';

/// One cell of a [BrutalDialog]'s foot: its words on a cell that fills
/// with ink while pressed; the main one is filled with the signal colour
/// (the danger colour when [isDestructiveAction]).
///
/// ```dart
/// BrutalDialogAction(label: 'Keep it', onPressed: () => Navigator.pop(context))
/// ```
class BrutalDialogAction extends StatelessWidget {
  /// An action reading [label].
  const BrutalDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it says.
  final String label;

  /// Called when pressed; null disables it.
  final VoidCallback? onPressed;

  /// Whether it is the dialog's main action: its cell is filled with the
  /// signal colour (the danger colour when [isDestructiveAction]).
  final bool isDefaultAction;

  /// Whether it destroys something.
  final bool isDestructiveAction;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// {@macro design.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final rest = isDefaultAction
        ? (isDestructiveAction ? c.danger : c.signal)
        : c.ink.withValues(alpha: 0);
    final restWords = isDefaultAction
        ? (isDestructiveAction ? c.onDanger : c.onSignal)
        : (isDestructiveAction ? c.danger : c.ink);
    return RawButton(
      onPressed: onPressed,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: label,
      excludeSemantics: true,
      builder: (context, states, _) {
        final pressed = states.contains(WidgetState.pressed);
        final disabled = states.contains(WidgetState.disabled);
        final words = disabled
            ? c.disabled
            : pressed
            ? c.paper
            : restWords;
        return AnimatedBrutalSurface(
          stiffness: BrutalMotion.colorStiffness,
          face: BrutalFace(
            fill: disabled
                ? c.ink.withValues(alpha: 0)
                : (pressed ? c.ink : rest),
            border: c.ink.withValues(alpha: 0),
            foreground: words,
            borderWidth: 0,
          ),
          child: CustomPaint(
            foregroundPainter: states.contains(WidgetState.focused)
                ? BrutalInsetFocusPainter(
                    pressed || isDefaultAction ? words : c.ink,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrutalSpacing.regular,
              ),
              child: Center(
                child: RawCapCenter(
                  capHeightFactor: BrutalTheme.of(context).capHeightFactor,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.label.copyWith(
                      color: words,
                      fontWeight: FontWeight.w700,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(
        FlagProperty(
          'isDefaultAction',
          value: isDefaultAction,
          ifTrue: 'primary',
        ),
      )
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      );
  }
}

/// A square panel in the rule, raised on the hard shadow: an [icon], a
/// [title], a [content], and its [actions] as cells across its foot, on a
/// rule they share, the main one filled with colour; at large text, or
/// where one's words don't fit its cell, the cells stack, the main one on
/// top. Show it with [showBrutalDialog].
///
/// Reads [style]'s `fill` (the panel), `edge` (its rules), `foreground`
/// (its words), `padding` (round the title and content) and `textStyle`
/// (the title), then [BrutalThemeData.dialogStyle]'s. The main action keeps
/// the signal: it is the screen's one main action.
///
/// ```dart
/// BrutalDialog(title: 'Cancel this ticket?', content: const Text('Your seat goes back on sale.'), actions: [BrutalDialogAction(label: 'Keep it', onPressed: () => Navigator.pop(context)), BrutalDialogAction(label: 'Cancel ticket', isDefaultAction: true, isDestructiveAction: true, onPressed: () => Navigator.pop(context, true))])
/// ```
class BrutalDialog extends StatelessWidget {
  /// A dialog titled [title].
  const BrutalDialog({
    super.key,
    required this.title,
    this.icon,
    this.content,
    this.actions = const [],
    this.style,
  });

  /// A glyph over the title, in the words' ink unless it brings its own.
  final Widget? icon;

  /// What it asks or says, in the title type.
  final String title;

  /// What it says under the title.
  final Widget? content;

  /// The foot's cells, in order, the main one last: [BrutalDialogAction]s,
  /// or any widget that fills a cell. Stacked, the main one stands on top.
  final List<Widget> actions;

  /// The widest a dialog stands.
  static const double maxWidth = 440;

  /// Its style, over [BrutalThemeData.dialogStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.dialogStyle], const {});
    final face = layered.on(
      BrutalFace(
        fill: c.surface,
        border: c.ink,
        foreground: c.ink,
        shadow: c.ink,
      ),
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: BrutalSurface(
          face: face,
          child: RawKeylineRegion(
            label: 'Dialog',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      layered.padding(Directionality.of(context)) ??
                      const EdgeInsets.all(BrutalSpacing.large),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(size: 28, color: face.foreground),
                          child: icon!,
                        ),
                        const SizedBox(height: BrutalSpacing.medium),
                      ],
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: layered.text(
                            theme.textTheme.title.copyWith(
                              color: face.foreground,
                            ),
                          ),
                        ),
                      ),
                      if (content != null) ...[
                        const SizedBox(height: BrutalSpacing.medium),
                        DefaultTextStyle.merge(
                          style: theme.textTheme.body.copyWith(
                            color: face.foreground,
                          ),
                          child: content!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  BrutalRule(color: face.border),
                  // ui_core's action bar lays the cells: side by side in
                  // equal shares while every action's words fit its share,
                  // else one above another, full width, the main one on
                  // top. The rules between them are the dialog's ink
                  // showing through the bar's gaps.
                  ColoredBox(
                    color: face.border,
                    child: RawActionBar(
                      expanded: true,
                      spacing: theme.borderWidth,
                      overflowSpacing: theme.borderWidth,
                      children: [
                        for (final action in actions)
                          ColoredBox(
                            color: face.fill,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 56),
                              child: action,
                            ),
                          ),
                      ],
                    ),
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
      ..add(StringProperty('title', title))
      ..add(IntProperty('actions', actions.length));
  }
}

/// Shows [builder]'s dialog (usually a [BrutalDialog]) over a scrim, in the
/// middle of the screen, on ui_core's [RawModalDialogRoute]: it arrives on a
/// spring, sliding up out of its shadow's direction and fading in, quickly
/// (a fade alone under Reduce Motion). Tapping the scrim closes it when
/// [barrierDismissible]; Escape and Back always do, and a `PopScope` in it
/// may refuse them. It keeps Tab inside it and gives the focus back to what
/// opened it as it closes; a screen reader hears a dialog named by its
/// title. It stands clear of the keyboard.
///
/// ```dart
/// final cancel = await showBrutalDialog<bool>(context: context, builder: (context) => const BrutalDialog(title: 'Cancel this ticket?'));
/// ```
Future<T?> showBrutalDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final theme = BrutalTheme.of(context);
  return Navigator.of(context, rootNavigator: true).push<T>(
    RawModalDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: RawWidgetsLocalizations.of(context)
          .modalBarrierDismissLabel,
      barrierColor: theme.colors.scrim,
      dampingRatio: BrutalMotion.dampingRatio,
      stiffness: BrutalMotion.overlayStiffness,
      builder: (context, details) => BrutalTheme(
        data: theme,
        child: _ClearOfKeyboard(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(BrutalSpacing.large),
                child: _Arrive(
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

/// Stands [child] clear of the keyboard: what is under it is padded away,
/// and the child is told there is none.
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

// A curve that holds a spring's overshoot to 0..1, for an opacity.
class _Clamp extends Curve {
  const _Clamp();

  @override
  double transformInternal(double t) => t.clamp(0.0, 1.0);
}

class _Arrive extends StatefulWidget {
  const _Arrive({required this.animation, required this.child, this.from});

  final Animation<double> animation;
  final Widget child;
  final Offset? from;

  @override
  State<_Arrive> createState() => _ArriveState();
}

class _ArriveState extends State<_Arrive> {
  late CurvedAnimation _eased = _curve();
  late CurvedAnimation _solid = _solidCurve();

  CurvedAnimation _curve() => CurvedAnimation(
    parent: widget.animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  // A flat face is never see-through for long: it is solid within the first
  // part of its move in and stays solid until the last part of its move out,
  // so the words beneath never show through it on the way. The spring can
  // pass 1 on its way; the fade holds there.
  CurvedAnimation _solidCurve() => CurvedAnimation(
    parent: widget.animation,
    curve: const Interval(0, 0.3, curve: _Clamp()),
  );

  @override
  void didUpdateWidget(_Arrive old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      _eased.dispose();
      _solid.dispose();
      _eased = _curve();
      _solid = _solidCurve();
    }
  }

  @override
  void dispose() {
    _eased.dispose();
    _solid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = rawReduceMotionOf(context);
    return FadeTransition(
      opacity: _solid,
      child: reduce
          ? widget.child
          : SlideTransition(
              position: Tween<Offset>(
                begin: widget.from ?? const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(_eased),
              child: widget.child,
            ),
    );
  }
}

/// Shows [builder]'s content in a [BrutalSheet] from the bottom edge: a
/// heavy rule over it, a header row of the [title] and a square close cell
/// on a shared rule. On a phone it spans the screen; wider, it stands 560 px
/// wide, framed. Tapping the scrim (when [barrierDismissible]), the close
/// cell or Escape closes it, and so does a drag down: the sheet follows the
/// finger, and let go low enough or flung down it closes (its content,
/// scrolled to its top, hands the drag on). The route is ui_core's
/// ([RawBottomSheetRoute]).
///
/// Its panel reads [style]'s `fill`, `edge` (its rules), `foreground` (its
/// words), `padding` (round the content) and `textStyle` (the title), then
/// [BrutalThemeData.bottomSheetStyle]'s.
///
/// ```dart
/// showBrutalBottomSheet<void>(context: context, title: 'Filter', builder: (context) => const Text('Tonight'))
/// ```
Future<T?> showBrutalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool barrierDismissible = true,
  BrutalStyle? style,
}) => showBrutalSheet<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  builder: (context) => BrutalSheet(
    title: title,
    onClose: () => Navigator.of(context).maybePop(),
    style: style,
    child: Builder(builder: builder),
  ),
);

/// Raises [builder]'s sheet (a [BrutalSheet] of your own: with a footer, a
/// body of slivers, no close) from the bottom edge, as
/// [showBrutalBottomSheet] raises its own, on ui_core's
/// [RawBottomSheetRoute]: it rises on a spring, a drag moves it with the
/// finger, and let go low enough or flung down it closes. Tapping the scrim
/// closes it when [barrierDismissible]; Escape and Back always do. It rises
/// clear of the keyboard, and the focus goes back to what raised it.
///
/// ```dart
/// showBrutalSheet<void>(context: context, builder: (context) => BrutalSheet(title: 'Filter', onClose: () => Navigator.pop(context), footer: [BrutalButton.filled('Show 12', onPressed: apply)], child: const Text('Tonight')))
/// ```
Future<T?> showBrutalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final theme = BrutalTheme.of(context);
  final words = RawWidgetsLocalizations.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    _sheetRoute<T>(
      theme: theme,
      barrierLabel: words.modalBarrierDismissLabel,
      barrierDismissible: barrierDismissible,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Builder(builder: builder),
      ),
    ),
  );
}

// A sheet's route: ui_core's, on the overlays' spring (ζ 1, k 700: the
// 240 ms the sheet rose in before), over the look's scrim. A [BrutalSheet]
// in it takes the route's scroll controller, so its body hands drags over.
RawBottomSheetRoute<T> _sheetRoute<T>({
  required BrutalThemeData theme,
  required String barrierLabel,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  RouteSettings? settings,
}) => RawBottomSheetRoute<T>(
  settings: settings,
  barrierColor: theme.colors.scrim,
  barrierLabel: barrierLabel,
  barrierDismissible: barrierDismissible,
  dampingRatio: BrutalMotion.dampingRatio,
  stiffness: BrutalMotion.overlayStiffness,
  builder: (context, details) => BrutalTheme(
    data: theme,
    child: _SheetScroll(
      controller: details.scrollController,
      child: Builder(builder: builder),
    ),
  ),
);

// The scroll controller of the sheet route a [BrutalSheet] stands in.
class _SheetScroll extends InheritedWidget {
  const _SheetScroll({required this.controller, required super.child});

  final ScrollController controller;

  static ScrollController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_SheetScroll>()?.controller;

  @override
  bool updateShouldNotify(_SheetScroll oldWidget) =>
      controller != oldWidget.controller;
}

/// The router's page for a sheet raised over the shell: from a phone's
/// foot, its width under a heavy rule; from 600 px a framed panel 560 px
/// wide on the hard shadow, laid out as on a phone. It stands 90% of the
/// screen tall, or as tall as its content when [drawer]; [fullScreen]
/// raises a whole page instead. Its screen reads the route as a sheet
/// ([RoutePresentation.sheet]), so the bar's way out is a close. Tapping
/// the scrim, Escape or a drag down closes it (ui_core's
/// [RawBottomSheetRoute]). A go_router route's `pageBuilder` returns
/// it with the route's `state.pageKey`.
///
/// ```dart
/// BrutalSheetPage<void>(key: state.pageKey, child: const AddPage())
/// ```
class BrutalSheetPage<T> extends Page<T> {
  /// A sheet of [child].
  const BrutalSheetPage({
    required this.child,
    this.drawer = false,
    this.fullScreen = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The sheet's screen, usually a `BrutalScreen`.
  final Widget child;

  /// Whether it stands as tall as its content rather than 90% of the
  /// screen.
  final bool drawer;

  /// Whether it is raised as a whole page rather than a sheet.
  final bool fullScreen;

  @override
  Route<T> createRoute(BuildContext context) {
    final theme = BrutalTheme.of(context);
    // The page as it stands now: a router that updates the page in place
    // hands the route the new one.
    Widget current(BuildContext context) {
      final page = ModalRoute.of(context)?.settings;
      return page is BrutalSheetPage ? page.child : child;
    }

    Widget scoped(Widget child) => BrutalTheme(
      data: theme,
      child: RoutePresentationScope(
        presentation: RoutePresentation.sheet,
        child: child,
      ),
    );
    if (fullScreen) {
      return PageRouteBuilder<T>(
        settings: this,
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, _, _) => scoped(
          ColoredBox(color: theme.colors.paper, child: current(context)),
        ),
        transitionsBuilder: (context, animation, _, child) => _Arrive(
          animation: animation,
          from: const Offset(0, 0.25),
          child: child,
        ),
      );
    }
    return _sheetRoute<T>(
      theme: theme,
      settings: this,
      barrierLabel: RawWidgetsLocalizations.of(context)
          .modalBarrierDismissLabel,
      builder: (context) => scoped(
        Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: _SheetFrame(drawer: drawer, child: current(context)),
        ),
      ),
    );
  }
}

/// A sheet page's face round its screen: the sheet's fill under a heavy
/// rule on a phone, framed and raised from 600 px, where the screen inside
/// is told it is phone-wide.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.drawer, required this.child});

  final bool drawer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([theme.bottomSheetStyle], const {});
    final face = layered.on(
      BrutalFace(
        fill: c.surface,
        border: c.ink,
        foreground: c.ink,
        shadow: c.ink,
      ),
    );
    final media = MediaQuery.of(context);
    final framed = media.size.width >= 600;
    final tall = media.size.height * 0.9;
    final width = framed ? 560.0 : media.size.width;
    final screen = MediaQuery(
      data: media.copyWith(
        size: Size(width, media.size.height),
        padding: media.padding.copyWith(
          top: 0,
          left: framed ? 0 : null,
          right: framed ? 0 : null,
          bottom: framed ? 0 : null,
        ),
        viewPadding: media.viewPadding.copyWith(top: 0),
        // The frame stands clear of the keyboard; the screen need not.
        viewInsets: EdgeInsets.zero,
      ),
      child: child,
    );
    final sized = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: tall),
      child: SizedBox(height: drawer ? null : tall, child: screen),
    );
    return Padding(
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom + (framed ? BrutalSpacing.large : 0),
      ),
      child: framed
          ? BrutalSurface(face: face, child: sized)
          : ColoredBox(
              color: face.fill,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 2 * theme.borderWidth,
                    child: ColoredBox(color: face.border),
                  ),
                  Flexible(child: sized),
                ],
              ),
            ),
    );
  }
}

/// A sheet's face: a header row of its [title] and, when [onClose] is set, a
/// square close cell on a shared rule; under a heavy rule, its body (a
/// [child] or [slivers], scrolling) and its [footer] at its foot. On a phone
/// it spans its width under a heavy rule; from 600 px it stands 560 px wide,
/// framed and raised. Given a height (a presenter that drags it), the body
/// fills what the header and the footer leave; raised by [showBrutalSheet],
/// it is as tall as its content, at most 85% of the screen.
///
/// Reads [style]'s `fill`, `edge` (its rules), `foreground` (its words),
/// `padding` (round the body) and `textStyle` (the title), then
/// [BrutalThemeData.bottomSheetStyle]'s.
///
/// ```dart
/// BrutalSheet(title: 'Filter', onClose: () => Navigator.pop(context), child: const Text('Tonight'))
/// ```
class BrutalSheet extends StatelessWidget {
  /// A sheet of [child] or of [slivers].
  const BrutalSheet({
    super.key,
    this.title,
    this.onClose,
    this.closeLabel,
    this.controller,
    this.child,
    this.slivers,
    this.footer = const [],
    this.style,
  }) : assert(
         (child == null) != (slivers == null),
         'a sheet takes a child or slivers',
       );

  /// Its title, a header.
  final String? title;

  /// What its close cell does; null draws no close.
  final VoidCallback? onClose;

  /// The close cell's name; null takes the design kit's ("Close").
  final String? closeLabel;

  /// The body's scroll controller (a presenter's, which a drag on the body
  /// moves); null: the sheet route's, when it stands in one.
  final ScrollController? controller;

  /// The body as one widget; not with [slivers].
  final Widget? child;

  /// The body as slivers; not with [child].
  final List<Widget>? slivers;

  /// What stands at its foot, under the body, one under the other.
  final List<Widget> footer;

  /// Its style, over [BrutalThemeData.bottomSheetStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.bottomSheetStyle], const {});
    final face = layered.on(
      BrutalFace(
        fill: c.surface,
        border: c.ink,
        foreground: c.ink,
        shadow: c.ink,
      ),
    );
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final framed = size.width >= 600;
    final words = RawWidgetsLocalizations.of(context);
    final direction = Directionality.of(context);
    final padding =
        layered.padding(direction) ?? const EdgeInsets.all(BrutalSpacing.large);
    final controller = this.controller ?? _SheetScroll.maybeOf(context);
    final body = DefaultTextStyle.merge(
      style: theme.textTheme.body.copyWith(color: face.foreground),
      child: slivers != null
          ? CustomScrollView(
              controller: controller,
              shrinkWrap: true,
              slivers: [
                SliverPadding(
                  padding: padding,
                  sliver: SliverMainAxisGroup(slivers: slivers!),
                ),
              ],
            )
          : SingleChildScrollView(
              controller: controller,
              padding: padding,
              child: child,
            ),
    );
    final header = title == null && onClose == null
        ? null
        : SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: BrutalSpacing.large,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: title == null
                          ? null
                          : Semantics(
                              header: true,
                              child: Text(
                                title!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: layered.text(
                                  theme.textTheme.title.copyWith(
                                    color: face.foreground,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                if (onClose != null) ...[
                  BrutalRule(vertical: true, color: face.border),
                  SizedBox(
                    width: 56,
                    child: _CloseCell(
                      label: closeLabel ?? words.closeButtonLabel,
                      onPressed: onClose!,
                      words: face.foreground,
                    ),
                  ),
                ],
              ],
            ),
          );
    final panel = LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[header, BrutalRule(color: face.border)],
          Flexible(
            // Given a height, the body takes what the head and foot leave.
            fit: constraints.minHeight > 0 ? FlexFit.tight : FlexFit.loose,
            child: RawKeylineRegion(label: title ?? 'Sheet', child: body),
          ),
          if (footer.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                BrutalSpacing.large,
                0,
                BrutalSpacing.large,
                BrutalSpacing.large + (framed ? 0 : pad.bottom),
              ),
              // A child that draws nothing adds no gap.
              child: BrutalRuledColumn(
                gap: BrutalSpacing.medium,
                children: footer,
              ),
            )
          else if (!framed)
            SizedBox(height: pad.bottom),
        ],
      ),
    );
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: framed ? 560 : double.infinity,
          maxHeight: size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: framed ? BrutalSpacing.large : 0),
          child: framed
              ? BrutalSurface(face: face, child: panel)
              // The heavy rule is its top edge, so a height it is given
              // (a presenter that drags it) reaches its panel whole.
              : Container(
                  decoration: BoxDecoration(
                    color: face.fill,
                    border: Border(
                      top: BorderSide(
                        color: face.border,
                        width: 2 * theme.borderWidth,
                      ),
                    ),
                  ),
                  child: panel,
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
      ..add(FlagProperty('onClose', value: onClose != null, ifTrue: 'closes'))
      ..add(IntProperty('footer', footer.length, defaultValue: 0));
  }
}

/// The sheet's square close cell: ink while pressed, the inset focus rule.
class _CloseCell extends StatelessWidget {
  const _CloseCell({
    required this.label,
    required this.onPressed,
    required this.words,
  });

  final String label;
  final VoidCallback onPressed;
  final Color words;

  @override
  Widget build(BuildContext context) {
    final c = BrutalTheme.of(context).colors;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, states, _) {
        final lit = states.contains(WidgetState.pressed);
        return AnimatedBrutalSurface(
          stiffness: BrutalMotion.colorStiffness,
          face: BrutalFace(
            fill: lit ? c.ink : c.ink.withValues(alpha: 0),
            border: c.ink.withValues(alpha: 0),
            foreground: lit ? c.paper : words,
            borderWidth: 0,
          ),
          child: CustomPaint(
            foregroundPainter: states.contains(WidgetState.focused)
                ? BrutalInsetFocusPainter(lit ? c.paper : c.ink)
                : null,
            child: const Center(child: Icon(LucideIcons.x, size: 24)),
          ),
        );
      },
    );
  }
}

/// Hosts toasts over [child], each an ink block in the rule that reads in
/// paper, its action an underlined cell and its close a square cell, both
/// on rules of paper. Put it above the app's navigator
/// (`WidgetsApp.builder`) and show one with [showBrutalToast].
///
/// Each toast reads [style]'s `fill` (the block), `foreground` (its words,
/// rules and cells), `padding` (round the words) and `textStyle` (the
/// message), then [BrutalThemeData.toastStyle]'s.
///
/// ```dart
/// BrutalToaster(child: app)
/// ```
class BrutalToaster extends StatelessWidget {
  /// Toasts over [child].
  const BrutalToaster({super.key, required this.child, this.style});

  /// The app.
  final Widget child;

  /// Every toast's style, over [BrutalThemeData.toastStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) => RawToaster(
    dampingRatio: BrutalMotion.dampingRatio,
    stiffness: BrutalMotion.overlayStiffness,
    constraints: const BoxConstraints(maxWidth: 480),
    toastBuilder: (context, details) => _Toast(details, style),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast(this.details, this.style);

  final RawToastDetails details;
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = details.toast;
    final layered = RawStyleOf([style, theme.toastStyle], const {});
    // A raised Brutal surface, as a dialog, a menu and a list are: the
    // surface in the ink rule, on the hard ink shadow.
    final block = layered.fill ?? c.surface;
    final ink =
        layered.foreground ?? (block == c.surface ? c.ink : c.onColor(block));
    final words = RawWidgetsLocalizations.of(context);
    Widget cell({
      required String label,
      required VoidCallback onPressed,
      required Widget Function(Color words) child,
      double? width,
    }) => SizedBox(
      width: width,
      child: RawButton(
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, states, _) {
          final lit = states.contains(WidgetState.pressed);
          final fg = lit ? block : ink;
          return AnimatedBrutalSurface(
            stiffness: BrutalMotion.colorStiffness,
            face: BrutalFace(
              fill: lit ? ink : ink.withValues(alpha: 0),
              border: ink.withValues(alpha: 0),
              foreground: fg,
              borderWidth: 0,
            ),
            child: CustomPaint(
              foregroundPainter: states.contains(WidgetState.focused)
                  ? BrutalInsetFocusPainter(fg)
                  : null,
              child: Center(child: child(fg)),
            ),
          );
        },
      ),
    );
    final rule = BrutalRule(vertical: true, color: ink);
    final opacity = details.animation.drive(
      Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
    );
    return FadeTransition(
      opacity: opacity,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: BrutalSurface(
          face: BrutalFace(
            fill: block,
            border: layered.side?.color ?? layered.edge ?? ink,
            foreground: ink,
            shadow: c.ink,
            focus: details.focused
                ? brutalFocusInk(c, c.ink)
                : c.ink.withValues(alpha: 0),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        layered.padding(Directionality.of(context)) ??
                        const EdgeInsets.symmetric(
                          horizontal: BrutalSpacing.regular,
                          vertical: BrutalSpacing.medium,
                        ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.title != null)
                          Text(
                            t.title!,
                            style: theme.textTheme.label.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Text(
                          t.message,
                          style: layered.text(
                            theme.textTheme.body.copyWith(color: ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (t.actionLabel != null && details.runAction != null) ...[
                  rule,
                  cell(
                    label: t.actionLabel!,
                    onPressed: details.runAction!,
                    child: (fg) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrutalSpacing.regular,
                      ),
                      child: Text(
                        t.actionLabel!,
                        style: theme.textTheme.label.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: fg,
                          decorationThickness: theme.borderWidth,
                        ),
                      ),
                    ),
                  ),
                ],
                rule,
                cell(
                  label: words.closeButtonLabel,
                  onPressed: details.dismiss,
                  width: 52,
                  child: (fg) => Icon(LucideIcons.x, size: 20, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a toast saying [message] from the nearest [BrutalToaster]: what
/// just happened, with an optional [actionLabel] and [onAction] (Undo).
///
/// ```dart
/// showBrutalToast(context, 'Ticket cancelled', actionLabel: 'Undo', onAction: () {})
/// ```
RawToastController showBrutalToast(
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
