// Surfaces raised over the page. Routing and overlays are Flutter's; their
// faces, motion, editing and focus treatment belong to Neumorphism.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'controls.dart';
import 'frames.dart';
import 'internal/beside.dart';
import 'internal/veil.dart';
import 'knobs.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'shapes.dart';
import 'glyphs.dart';
import 'localizations.dart';
import 'theme.dart';
import 'internal/reach.dart' show NeumorphicFacePlace, neumorphicAtEnd;
import 'internal/cap_label.dart';
import 'internal/whole_words.dart';
import 'internal/text_entry.dart' show neumorphicLineHeight;
import 'chrome_metrics.dart';
import 'internal/panel.dart';
import 'internal/field_list.dart' show neumorphicFieldListGap;
import 'internal/cell_bank.dart'
    show NeumorphicChosenBand, neumorphicWideControlMax;
import 'internal/moulded.dart';
import 'internal/page_motion.dart' show neumorphicRouteStiffness;

class _WordsDelegate extends LocalizationsDelegate<NeumorphicLocalizations> {
  const _WordsDelegate(this.words);
  final NeumorphicLocalizations words;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<NeumorphicLocalizations> load(Locale locale) =>
      SynchronousFuture(words);
  @override
  bool shouldReload(_WordsDelegate old) => old.words != words;
}

class _Carried {
  _Carried(BuildContext context, BuildContext destination)
    : theme = NeumorphicTheme.of(context),
      direction = Directionality.of(context),
      words = NeumorphicLocalizations.of(context),
      locale = Localizations.maybeLocaleOf(context) ?? const Locale('en'),
      scaler = MediaQuery.textScalerOf(context),
      // MediaQuery's own flag, carried as it is where the surface was opened. Not a reading of Reduce Motion: that is
      // NeumorphicMotion.of's, through designReduceMotionOf, which takes iOS's from the platform wherever it is read.
      disableAnimations = MediaQuery.disableAnimationsOf(context),
      motion = NeumorphicMotion.of(context),
      themes = InheritedTheme.capture(from: context, to: destination);
  final NeumorphicThemeData theme;
  final TextDirection direction;
  final NeumorphicLocalizations words;
  final Locale locale;
  final TextScaler scaler;
  final bool disableAnimations;
  final NeumorphicMotion motion;
  final CapturedThemes themes;

  Widget wrap(Widget child) => themes.wrap(
    Builder(
      builder: (context) => Localizations.override(
        context: context,
        locale: locale,
        delegates: [_WordsDelegate(words)],
        child: Directionality(
          textDirection: direction,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: scaler,
              disableAnimations: disableAnimations,
            ),
            child: NeumorphicTheme(
              data: theme,
              child: DefaultTextStyle(
                style: theme.textTheme.body,
                child: IconTheme(
                  data: IconThemeData(color: theme.colors.ink, size: 20),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// Consume Escape before focused widgets and the route's DismissIntent see it.
// One ordered stack closes only the topmost raised surface, including overlays
// which keep focus in the route beneath them.
class _EscapeLayer {
  _EscapeLayer(this.active, this.close);
  final bool Function() active;
  final VoidCallback close;
}

final _escapeLayers = <_EscapeLayer>[];
KeyEventResult _escapeKey(KeyEvent event) {
  if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.escape) {
    return KeyEventResult.ignored;
  }
  for (final layer in _escapeLayers.reversed) {
    if (layer.active()) {
      layer.close();
      return KeyEventResult.handled;
    }
  }
  return KeyEventResult.ignored;
}

void _registerEscape(_EscapeLayer layer) {
  if (_escapeLayers.isEmpty) {
    FocusManager.instance.addEarlyKeyEventHandler(_escapeKey);
  }
  _escapeLayers.add(layer);
}

void _removeEscape(_EscapeLayer layer) {
  _escapeLayers.remove(layer);
  if (_escapeLayers.isEmpty) {
    FocusManager.instance.removeEarlyKeyEventHandler(_escapeKey);
  }
}

mixin _EscapeCloses<T> on PopupRoute<T> {
  late final _escape = _EscapeLayer(() => isCurrent, () {
    navigator?.maybePop();
  });
  @override
  void install() {
    super.install();
    _registerEscape(_escape);
  }

  @override
  void dispose() {
    _removeEscape(_escape);
    super.dispose();
  }
}

enum _RaisedKind { sheet, menu }

class _RaisedRoute<T> extends PopupRoute<T> with _EscapeCloses<T> {
  _RaisedRoute({
    required this.carried,
    required this.builder,
    required this.kind,
    required this.dismissible,
    required this.closeLabel,
  }) : super(
         requestFocus: true,
         traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
       );
  final _Carried carried;
  final WidgetBuilder builder;
  final _RaisedKind kind;
  final bool dismissible;
  final String closeLabel;
  CurvedAnimation? _curve;

  /// How much of the barrier the sheet covers, so a screen reader outlines the barrier where a tap reaches it: above
  /// a phone's sheet, as Material's bottom sheet does.
  final _covered = ValueNotifier<EdgeInsets>(EdgeInsets.zero);

  @override
  void dispose() {
    _curve?.dispose();
    _covered.dispose();
    super.dispose();
  }

  @override
  Widget buildModalBarrier() {
    if (kind != _RaisedKind.sheet) return super.buildModalBarrier();
    final veil = barrierColor;
    if (veil == null || veil.a == 0 || offstage) {
      return ModalBarrier(
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
        clipDetailsNotifier: _covered,
      );
    }
    return AnimatedModalBarrier(
      color: animation!.drive(
        ColorTween(
          begin: veil.withValues(alpha: 0),
          end: veil,
        ).chain(CurveTween(curve: barrierCurve)),
      ),
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
      clipDetailsNotifier: _covered,
    );
  }

  @override
  bool get barrierDismissible => dismissible;
  @override
  String get barrierLabel => closeLabel;
  @override
  Color? get barrierColor =>
      kind == _RaisedKind.menu ? null : neumorphicVeil(carried.theme.colors);
  @override
  Duration get transitionDuration =>
      kind == _RaisedKind.menu ? carried.motion.state : carried.motion.raise;
  @override
  Duration get reverseTransitionDuration => carried.motion.leave;
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => carried.wrap(
    kind == _RaisedKind.sheet
        ? _SheetHost(
            route: this,
            child: Builder(builder: builder),
          )
        : Builder(builder: builder),
  );
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = _curve ??= CurvedAnimation(
      parent: animation,
      curve: carried.motion.enter,
      reverseCurve: carried.motion.exit,
    );
    if (kind == _RaisedKind.menu) {
      return FadeTransition(opacity: curve, child: child);
    }
    final sheet =
        kind == _RaisedKind.sheet && MediaQuery.sizeOf(context).width < 840;
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0, sheet ? .2 : .025),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  void drag(double delta, double height) {
    if (height > 0 && controller != null) controller!.value -= delta / height;
  }

  void release(double velocity) {
    if (controller == null) return;
    if (velocity > 500 || controller!.value < .7) {
      navigator?.pop();
    } else {
      controller!.forward();
    }
  }
}

Future<T?> _push<T>(
  BuildContext context,
  PopupRoute<T> route,
  bool root,
) async {
  final focus = FocusManager.instance.primaryFocus;
  final result = await Navigator.of(
    context,
    rootNavigator: root,
  ).push<T>(route);
  final owner = focus?.context;
  if (owner != null &&
      owner.mounted &&
      focus!.canRequestFocus &&
      (ModalRoute.of(owner)?.isCurrent ?? true)) {
    focus.requestFocus();
  }
  return result;
}

/// Raises a soft dialog on ui_core's dialog route ([DesignDialogRoute]): it rises and fades in on a spring as long as
/// the theme's raise, Escape, back or its dismissible scrim close it, Tab stays inside it, the focus goes back to its
/// opener, and a screen reader hears a dialog named by [NeumorphicDialog]'s title. Under Reduce Motion it only fades.
/// The future returns the value passed to pop.
///
/// ```dart
/// showNeumorphicDialog<bool>(context, builder: (context) => NeumorphicDialog(title: 'Keep this?', actions: [NeumorphicButton.filled('Keep', onPressed: () => Navigator.pop(context, true))]))
/// ```
Future<T?> showNeumorphicDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  String? closeLabel,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final carried = _Carried(context, navigator.context);
  return navigator.push(
    _NeumorphicDialogRoute<T>(
      barrierColor: neumorphicVeil(carried.theme.colors),
      barrierLabel: closeLabel ?? NeumorphicLocalizations.of(context).close,
      barrierDismissible: barrierDismissible,
      stiffness: neumorphicRouteStiffness(carried.theme.motion.raise),
      builder: (context, details) => carried.wrap(
        // The slab fades in as it rises a step (2.5% of the screen) to its place.
        FadeTransition(
          opacity: details.animation,
          child: SlideTransition(
            position: details.animation.drive(
              Tween(begin: const Offset(0, .025), end: Offset.zero),
            ),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

// ui_core's dialog route in the look's Escape order: the newest raised surface takes Escape first, so a dialog opened
// over a notice closes before the notice does.
class _NeumorphicDialogRoute<T> extends DesignDialogRoute<T>
    with _EscapeCloses<T> {
  _NeumorphicDialogRoute({
    required super.builder,
    required super.barrierColor,
    super.barrierLabel,
    super.barrierDismissible,
    super.stiffness,
  });
}

/// A raised slab for a question or a decision. Content and actions scroll together
/// when a small window or large text leaves too little height. Opened with [showNeumorphicDialog], it moves the focus
/// to its safe action, the first of its [actions] in reading order (the dismissive one, as ui_core's dialog), unless
/// its content took it, so the keys land inside it and Escape and Enter work at once; the focus shows as the input
/// that opened it decides (after the keys, not after a pointer or a touch).
///
/// ```dart
/// NeumorphicDialog(title: 'Save changes?', message: 'Your changes will be kept.', actions: [NeumorphicButton.filled('Save', onPressed: save)])
/// ```
class NeumorphicDialog extends StatelessWidget {
  /// Creates a [NeumorphicDialog].
  const NeumorphicDialog({
    super.key,
    required this.title,
    this.message,
    this.content = const [],
    this.actions = const [],
    this.mark,
    this.style,
  });

  /// Face, outline and spacing before the component theme.
  final NeumorphicStyle? style;

  /// The primary heading.
  final String title;

  /// The explanatory message.
  final String? message;

  /// The message-body widgets, in reading order.
  final List<Widget> content;

  /// The actions presented below the content.
  final List<Widget> actions;

  /// Optional artwork or an icon above the message.
  final Widget? mark;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + media.viewInsets.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              child: Semantics(
                // On ui_core's dialog route the route is the dialog (its role and scope) and the title names it;
                // elsewhere (a specimen on a page) the slab scopes its own.
                scopesRoute: ModalRoute.of(context) is DesignDialogRoute
                    ? null
                    : true,
                explicitChildNodes: true,
                child: NeumorphicSurface(
                  cast: NeumorphicSurfaceLevel.slab,
                  style: style,
                  themeStyle: t.dialogTheme,
                  outlined: true,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (mark != null) ...[
                        ExcludeSemantics(child: Center(child: mark)),
                        const SizedBox(height: 16),
                      ],
                      Semantics(
                        namesRoute: true,
                        header: true,
                        // Its words whole at the reader's text size (internal/whole_words.dart).
                        child: LayoutBuilder(
                          builder: (context, box) => neumorphicLabel(
                            Text(
                              title,
                              style: _titleStyle(t),
                              textScaler: neumorphicWholeWordScaler(
                                context,
                                title,
                                _titleStyle(t),
                                box.maxWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 12),
                        Text(message!, style: t.textTheme.body),
                      ],
                      if (content.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ...content,
                      ],
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        ModalRoute.of(context) is DesignDialogRoute
                            ? _SafeFocus(child: _Actions(children: actions))
                            : _Actions(children: actions),
                      ],
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title))
      ..add(StringProperty('message', message, defaultValue: null));
  }
}

// As a dialog opens, the focus goes to its first action unless something inside it already took it.
class _SafeFocus extends StatefulWidget {
  const _SafeFocus({required this.child});
  final Widget child;
  @override
  State<_SafeFocus> createState() => _SafeFocusState();
}

class _SafeFocusState extends State<_SafeFocus> {
  final _bar = FocusNode(
    debugLabel: 'dialog actions',
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = FocusScope.of(context);
      final primary = FocusManager.instance.primaryFocus;
      final inside =
          primary != null &&
          primary != scope &&
          primary.ancestors.contains(scope);
      if (inside) return;
      for (final node in _bar.traversalDescendants) {
        if (node.canRequestFocus) {
          node.requestFocus();
          return;
        }
      }
    });
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _bar, includeSemantics: false, child: widget.child);
}

class _Actions extends StatelessWidget {
  const _Actions({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => OverflowBar(
    alignment: MainAxisAlignment.end,
    spacing: 12,
    overflowSpacing: 8,
    overflowAlignment: OverflowBarAlignment.end,
    overflowDirection: VerticalDirection.up,
    children: children,
  );
}

class _SheetDrag extends InheritedWidget {
  const _SheetDrag({
    required this.route,
    required this.floating,
    required super.child,
  });
  final _RaisedRoute<dynamic> route;

  /// Whether the sheet floats in the middle of a wide window rather than standing on the window's foot: a handle
  /// says "drag me down" and means nothing there, so it is left off (its close key stays).
  final bool floating;
  @override
  bool updateShouldNotify(_SheetDrag old) =>
      old.route != route || old.floating != floating;
}

class _SheetHost extends StatelessWidget {
  const _SheetHost({required this.route, required this.child});
  final _RaisedRoute<dynamic> route;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final desk = media.size.width >= 840;
    final height = math.max(
      0.0,
      media.size.height - media.viewInsets.bottom - media.padding.top - 16,
    );
    return SafeArea(
      bottom: desk,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Align(
          alignment: desk ? Alignment.center : Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: math.min(height, media.size.height * .9),
            ),
            // A phone's sheet tells its barrier what it covers; a desk's panel floats in the middle of it.
            child: _SizeReport(
              onSize: (size) => route._covered.value = desk
                  ? EdgeInsets.zero
                  : EdgeInsets.only(
                      bottom: size.height + media.viewInsets.bottom,
                    ),
              child: _SheetDrag(route: route, floating: desk, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reports its child's size after each layout.
class _SizeReport extends SingleChildRenderObjectWidget {
  const _SizeReport({required this.onSize, super.child});
  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReport(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReport report) =>
      report.onSize = onSize;
}

class _RenderSizeReport extends RenderProxyBox {
  _RenderSizeReport(this.onSize);
  ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    onSize(size);
  }
}

/// Raises a sheet from a phone's foot, or as a centered panel on a wide window.
/// Its grip, back, Escape and dismissible scrim close it and return focus.
///
/// ```dart
/// showNeumorphicBottomSheet<void>(context, builder: (context) => NeumorphicBottomSheet(title: 'Filters', child: filters))
/// ```
Future<T?> showNeumorphicBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  String? closeLabel,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return _push(
    context,
    _RaisedRoute<T>(
      carried: _Carried(context, navigator.context),
      builder: builder,
      kind: _RaisedKind.sheet,
      dismissible: barrierDismissible,
      closeLabel: closeLabel ?? NeumorphicLocalizations.of(context).close,
    ),
    useRootNavigator,
  );
}

/// A soft panel with a grip, a heading, scrolling content and fixed actions.
///
/// ```dart
/// NeumorphicBottomSheet(title: 'Filters', actions: [NeumorphicButton.filled('Apply', onPressed: apply)], child: filters)
/// ```
class NeumorphicBottomSheet extends StatelessWidget {
  /// Creates a [NeumorphicBottomSheet].
  const NeumorphicBottomSheet({
    super.key,
    this.title,
    this.child,
    this.slivers,
    this.controller,
    this.actions = const [],
    this.onClose,
    this.closeLabel,
    this.showClose = true,
    this.inPlace = false,
    this.style,
  }) : assert(child == null || slivers == null);

  /// Face, outline and spacing before the component theme.
  final NeumorphicStyle? style;

  /// The primary heading.
  final String? title;

  /// The content placed inside this component.
  final Widget? child;

  /// Scroll slivers used instead of a single child.
  final List<Widget>? slivers;

  /// An optional externally owned sheet scroll controller.
  final ScrollController? controller;

  /// The actions presented in the sheet footer.
  final List<Widget> actions;

  /// Called when the close action is activated.
  final VoidCallback? onClose;

  /// The accessible label for the close action; null uses localizations.
  final String? closeLabel;

  /// Whether to show the close action.
  final bool showClose;

  /// An external presenter owns height, safe insets and dragging.
  /// The supplied controller is used only by the body; the footer stays at the foot.
  final bool inPlace;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final drag = inPlace
        ? null
        : context.dependOnInheritedWidgetOfExactType<_SheetDrag>();
    final close =
        onClose ??
        (drag == null ? null : () => Navigator.of(context).maybePop());
    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (drag?.floating ?? false)
          const SizedBox(height: 16)
        else
          ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: drag == null
                  ? null
                  : (d) => drag.route.drag(
                      d.delta.dy,
                      MediaQuery.sizeOf(context).height,
                    ),
              onVerticalDragEnd: drag == null
                  ? null
                  : (d) => drag.route.release(d.velocity.pixelsPerSecond.dy),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.colors.quiet,
                      borderRadius: BorderRadius.circular(
                        t.shapes.corner(2).radius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (title != null || showClose)
          Padding(
            // The close key's face ends on the body's keyline, 20 in, as the title starts on it (a dialog's does): at
            // 12 it stood 8 px past the body's end and crowded the sheet's edge.
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    namesRoute: !inPlace,
                    // Its words whole at the reader's text size (internal/whole_words.dart).
                    child: LayoutBuilder(
                      builder: (context, box) => neumorphicLabel(
                        Text(
                          title ?? '',
                          style: _titleStyle(t),
                          textScaler: neumorphicWholeWordScaler(
                            context,
                            title ?? '',
                            _titleStyle(t),
                            box.maxWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showClose)
                  neumorphicAtEnd(
                    NeumorphicRoundButton(
                      NeumorphicGlyphs.close,
                      label:
                          closeLabel ??
                          NeumorphicLocalizations.of(context).close,
                      onPressed: close,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
    Widget body({bool nested = false}) => slivers == null
        ? SingleChildScrollView(
            controller: nested ? null : controller,
            physics: nested ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child ?? const SizedBox.shrink(),
          )
        : CustomScrollView(
            controller: nested ? null : controller,
            physics: nested ? const NeverScrollableScrollPhysics() : null,
            shrinkWrap: true,
            slivers: slivers!,
          );
    final footer = actions.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.all(20),
            child: _Actions(children: actions),
          )
        : const SizedBox(height: 20);
    return Semantics(
      scopesRoute: !inPlace,
      explicitChildNodes: true,
      child: NeumorphicSurface(
        cast: NeumorphicSurfaceLevel.slab,
        style: style,
        themeStyle: t.sheetTheme,
        outlined: true,
        child: SafeArea(
          top: false,
          bottom: !inPlace,
          left: !inPlace,
          right: !inPlace,
          child: LayoutBuilder(
            builder: (context, box) {
              final scrollAll =
                  !inPlace &&
                  (box.maxHeight < 400 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3);
              if (scrollAll) {
                return SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [header, body(nested: true), footer],
                  ),
                );
              }
              return Column(
                mainAxisSize: inPlace ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Flexible(
                    fit: inPlace ? FlexFit.tight : FlexFit.loose,
                    child: body(),
                  ),
                  footer,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(IterableProperty<Widget>('slivers', slivers, defaultValue: null))
      ..add(
        DiagnosticsProperty<ScrollController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onClose', onClose))
      ..add(StringProperty('closeLabel', closeLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<bool>('showClose', showClose, defaultValue: true),
      )
      ..add(DiagnosticsProperty<bool>('inPlace', inPlace, defaultValue: false));
  }
}

/// One menu choice, or a divider between choices.
@immutable
class NeumorphicMenuItem<T> {
  /// Creates a [NeumorphicMenuItem].
  const NeumorphicMenuItem(
    T this.value,
    String this.label, {
    this.icon,
    this.note,
    this.enabled = true,
    this.selected = false,
    this.danger = false,
  }) : divider = false;

  /// Creates a [NeumorphicMenuItem.divider].
  const NeumorphicMenuItem.divider()
    : value = null,
      label = null,
      icon = null,
      note = null,
      enabled = false,
      selected = false,
      danger = false,
      divider = true;

  /// The value returned when this entry is selected.
  final T? value;

  /// The text identifying this item or control.
  final String? label;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// Whether the control accepts user interaction.
  final bool enabled;

  /// Whether this item is selected.
  final bool selected;

  /// Whether this entry represents a destructive action.
  final bool danger;

  /// Whether this entry is a noninteractive separator.
  final bool divider;
}

/// A soft menu with arrow-key, Home, End and type-ahead navigation.
///
/// ```dart
/// NeumorphicMenu<String>(items: const [NeumorphicMenuItem('copy', 'Copy')], onSelected: choose)
/// ```
class NeumorphicMenu<T> extends StatefulWidget {
  /// Creates a [NeumorphicMenu].
  const NeumorphicMenu({
    super.key,
    required this.items,
    this.onSelected,
    this.width,
    this.label,
    this.autofocus = true,
    this.style,
    this.fieldWords,
  }) : assert((width ?? 1) > 0);

  /// Face, outline and spacing before the component theme.
  final NeumorphicStyle? style;

  /// Where the field it opens from (a select) starts its value: its options' words start there too, and the chosen
  /// one carries its check at its end. Null for a menu, whose check and glyphs keep a column before the words.
  final double? fieldWords;

  /// The menu entries, in display order.
  final List<NeumorphicMenuItem<T>> items;

  /// Reports the value of the activated entry.
  final ValueChanged<T>? onSelected;

  /// The preferred width in logical pixels.
  final double? width;

  /// The text identifying this item or control.
  final String? label;

  /// Whether to request focus when first attached.
  final bool autofocus;
  @override
  State<NeumorphicMenu<T>> createState() => _NeumorphicMenuState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('fieldWords', fieldWords, defaultValue: null))
      ..add(IterableProperty<NeumorphicMenuItem<T>>('items', items))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(DoubleProperty('width', width, defaultValue: null))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: true),
      );
  }
}

class _NeumorphicMenuState<T> extends State<NeumorphicMenu<T>> {
  final List<FocusNode> _nodes = [];
  String _search = '';
  Timer? _resetSearch;
  bool _keyboardFocus = false;

  /// The list's inset round its rows, from the last build: a row the keys reach comes into view with it.
  double _inset = neumorphicMenuInset;
  void _resizeNodes() {
    while (_nodes.length > widget.items.length) {
      _nodes.removeLast().dispose();
    }
    while (_nodes.length < widget.items.length) {
      _nodes.add(FocusNode());
    }
  }

  @override
  void initState() {
    super.initState();
    _resizeNodes();
    _keyboardFocus = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) =>
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowUp,
    );
    HardwareKeyboard.instance.addHandler(_keys);
  }

  /// Any key pressed while the menu is open means the keys move through it, Tab from outside included: an item that
  /// takes focus then lifts. The menu never claims the key.
  bool _keys(KeyEvent event) {
    if (event is KeyDownEvent && !_keyboardFocus && mounted) {
      setState(() => _keyboardFocus = true);
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant NeumorphicMenu<T> old) {
    super.didUpdateWidget(old);
    _resizeNodes();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keys);
    _resetSearch?.cancel();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_keyboardFocus) setState(() => _keyboardFocus = true);
    final enabled = [
      for (var i = 0; i < widget.items.length; i++)
        if (!widget.items[i].divider && widget.items[i].enabled) i,
    ];
    if (enabled.isEmpty) return KeyEventResult.ignored;
    final at = enabled.indexOf(index);
    final key = event.logicalKey;
    int? target;
    if (key == LogicalKeyboardKey.arrowDown) {
      target = enabled[(at + 1) % enabled.length];
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      target = enabled[(at - 1 + enabled.length) % enabled.length];
    }
    if (key == LogicalKeyboardKey.home) target = enabled.first;
    if (key == LogicalKeyboardKey.end) target = enabled.last;
    if (target == null &&
        event.character != null &&
        event.character!.trim().isNotEmpty &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      _search += event.character!.toLowerCase();
      _resetSearch?.cancel();
      _resetSearch = Timer(
        const Duration(milliseconds: 700),
        () => _search = '',
      );
      for (var offset = 1; offset <= enabled.length; offset++) {
        final candidate = enabled[(at + offset) % enabled.length];
        if (widget.items[candidate].label!.toLowerCase().startsWith(_search)) {
          target = candidate;
          break;
        }
      }
    }
    if (target == null) return KeyEventResult.ignored;
    _nodes[target].requestFocus();
    final context = _nodes[target].context;
    final row = context?.findRenderObject();
    if (context != null && row is RenderBox && row.attached) {
      // The row comes into view with the list's inset round it, so its lift is never cut by the list's edge.
      row.showOnScreen(
        rect: (Offset.zero & row.size).inflate(_inset),
        duration: NeumorphicMotion.of(context).move,
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final menuLook = neumorphicStyleOf([widget.style, t.menuTheme], const {});
    final outer = menuLook.shape ?? t.shapes.corner(NeumorphicRadii.slab);
    // A field's list whose options carry no glyph starts their words on the field's value.
    final field =
        widget.fieldWords == null ||
            widget.items.any((item) => item.icon != null)
        ? null
        : neumorphicFieldListInsets(
            widget.fieldWords!,
            frame:
                menuLook.shape?.dimensions
                    .resolve(Directionality.of(context))
                    .left ??
                0,
          );
    final inset = field?.panel ?? neumorphicMenuInset;
    _inset = inset;
    final rowBorder = NeumorphicShapes.inset(
      outer,
      inset +
          (menuLook.shape?.dimensions
                  .resolve(Directionality.of(context))
                  .left ??
              0),
    );
    var first = widget.items.indexWhere(
      (item) => item.enabled && !item.divider && item.selected,
    );
    if (first < 0) {
      first = widget.items.indexWhere((item) => item.enabled && !item.divider);
    }
    final menu = Listener(
      onPointerDown: (_) {
        if (_keyboardFocus) setState(() => _keyboardFocus = false);
      },
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.label,
        child: NeumorphicSurface(
          cast: NeumorphicSurfaceLevel.part,
          style: widget.style,
          themeStyle: t.menuTheme,
          radius: NeumorphicRadii.slab,
          outlined: true,
          child: _MenuWidth(
            width: widget.width ?? 280,
            // A field's list starts at the field's width and widens to fit its widest entry, the chosen one in bold
            // with its check: an option's words never break onto a second line.
            least: widget.fieldWords != null && widget.width != null,
            inset: inset,
            child: SingleChildScrollView(
              // Room round the list so nearby recessed field edges do not peek through the popup's short cast
              // shadow as a second slab. It is inside the scroll, so a lit row's lift at the list's edge has the
              // inset to cast into rather than being cut by the scroll's edge.
              padding: EdgeInsets.all(inset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    if (widget.items[i].divider)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: SizedBox(
                          height: neumorphicRuleWidth,
                          child: ColoredBox(color: t.colors.quiet),
                        ),
                      )
                    else
                      // The pointer's moves take the keys' place, as in a native menu: one place in the list, never
                      // a lifted row and a raised one at once. A move, not a row scrolled under a resting pointer:
                      // the pointer's row stands up, and the keys go on from it.
                      MouseRegion(
                        onHover: (_) {
                          if (_keyboardFocus) {
                            setState(() => _keyboardFocus = false);
                          }
                          if (widget.items[i].enabled && !_nodes[i].hasFocus) {
                            _nodes[i].requestFocus();
                          }
                        },
                        child: NeumorphicTap(
                          label: widget.items[i].label,
                          shape: rowBorder,
                          selected: widget.items[i].selected,
                          onPressed:
                              !widget.items[i].enabled ||
                                  widget.onSelected == null
                              ? null
                              : () => widget.onSelected!(
                                  widget.items[i].value as T,
                                ),
                          focusNode: _nodes[i],
                          // The row draws the keys' place itself, as the one quiet
                          // sink the pointer's row has (below).
                          showFocus: false,
                          autofocus: widget.autofocus && i == first,
                          onKeyEvent: (_, event) => _key(i, event),
                          child: Builder(
                            builder: (context) {
                              final states = NeumorphicStatesScope.of(context);
                              final look = neumorphicStyleOf([
                                widget.style,
                                t.menuTheme,
                              ], states);
                              // The chosen row alone is pressed in at rest, under the pigment's wash; a row
                              // held under a finger presses in deeper while it is held; the pointer's row sinks a
                              // little into the panel, and the keys' place sinks the same a little deeper, only
                              // once the keys moved to it (autofocus alone is not keyboard input). The pointer's row
                              // sinks only while the pointer moved last: once the keys move, theirs is the one row,
                              // wherever the pointer rests.
                              final chosen = widget.items[i].selected;
                              final held =
                                  !chosen &&
                                  states.contains(WidgetState.pressed);
                              final over =
                                  !chosen &&
                                  !held &&
                                  !_keyboardFocus &&
                                  states.contains(WidgetState.hovered);
                              final keys =
                                  _keyboardFocus &&
                                  !held &&
                                  states.contains(WidgetState.focused);
                              final row = CustomPaint(
                                painter: held || (chosen && look.fill != null)
                                    ? _MenuRowRelief(
                                        t.colors,
                                        t.elevation,
                                        look.fill ?? t.colors.ground,
                                        rowBorder,
                                      )
                                    : over || (keys && !chosen)
                                    ? NeumorphicPanelRowRaise(
                                        t.colors,
                                        t.elevation,
                                        rowBorder,
                                        focus: keys,
                                      )
                                    : null,
                                foregroundPainter: keys && chosen
                                    ? NeumorphicPanelRowRaise(
                                        t.colors,
                                        t.elevation,
                                        rowBorder,
                                        rim: true,
                                      )
                                    : null,
                                // Keep the face 48px tall on pointer platforms too;
                                // a shorter row can expose a field edge below the popup.
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: field?.row ?? 10,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      if (field == null) ...[
                                        SizedBox(
                                          width: math.max(
                                            20,
                                            look.iconSize ?? 20,
                                          ),
                                          child: widget.items[i].selected
                                              ? Icon(
                                                  NeumorphicGlyphs.check,
                                                  color:
                                                      look.foreground ??
                                                      t.colors.pigmentInkLit,
                                                  size: look.iconSize,
                                                )
                                              // A row that destroys says so at its start: its own glyph, or the
                                              // warning mark where it has none (at the row's far end it read as
                                              // stray, apart from the words it qualifies).
                                              : widget.items[i].icon == null
                                              ? (widget.items[i].danger
                                                    ? Icon(
                                                        NeumorphicGlyphs
                                                            .triangleAlert,
                                                        color: look.foreground,
                                                        size: look.iconSize,
                                                      )
                                                    : null)
                                              : Icon(
                                                  widget.items[i].icon,
                                                  color: look.foreground,
                                                  size: look.iconSize,
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: neumorphicLabel(
                                          Text(
                                            widget.items[i].label!,
                                            style: t.textTheme.body
                                                .copyWith(
                                                  color: widget.items[i].enabled
                                                      ? t.colors.ink
                                                      : t.colors.inkTertiary,
                                                  fontWeight:
                                                      widget.items[i].selected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                )
                                                .merge(look.textStyle)
                                                .copyWith(
                                                  color: look.foreground,
                                                ),
                                          ),
                                        ),
                                      ),
                                      if (widget.items[i].danger &&
                                          field != null) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          NeumorphicGlyphs.triangleAlert,
                                          size: 16,
                                        ),
                                      ],
                                      if (widget.items[i].note != null) ...[
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            widget.items[i].note!,
                                            style: t.textTheme.micro
                                                .merge(look.textStyle)
                                                .copyWith(
                                                  color: look.foreground,
                                                ),
                                          ),
                                        ),
                                      ],
                                      if (field != null &&
                                          widget.items[i].selected) ...[
                                        const SizedBox(width: 10),
                                        Icon(
                                          NeumorphicGlyphs.check,
                                          color:
                                              look.foreground ??
                                              t.colors.pigmentInkLit,
                                          size: look.iconSize,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                              return NeumorphicChosenBand(
                                chosen: chosen && look.fill == null,
                                border: rowBorder,
                                child: row,
                              );
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // A field's list takes the field's width; any other menu, shown in place, keeps its raised width.
    return field != null
        ? menu
        : _keepsRaisedWidth(menu, least: 180, most: 320);
  }
}

class _MenuRowRelief extends CustomPainter {
  const _MenuRowRelief(this.colors, this.elevation, this.fill, this.border);
  final OutlinedBorder border;
  final NeumorphicColors colors;
  final NeumorphicElevation elevation;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final shape = border.getOuterPath(box);
    final tint =
        fill ??
        Color.alphaBlend(colors.pigment.withValues(alpha: .08), colors.ground);
    neumorphicPaintPressed(
      canvas,
      shape,
      colors,
      light: (const Offset(-1, -1), 3),
      dark: (const Offset(1, 1), 3),
      face: LinearGradient(colors: [tint, tint]).createShader(box),
      tone: neumorphicIsColourFace(fill, colors) ? fill : null,
      elevation: elevation,
    );
  }

  @override
  bool shouldRepaint(_MenuRowRelief old) =>
      old.colors != colors ||
      old.elevation != elevation ||
      old.fill != fill ||
      old.border != border;
}

/// A menu's list width: [width] exactly, or, for a field's list ([least]), the field's width at the least and as wide
/// as its widest entry needs.
class _MenuWidth extends StatelessWidget {
  const _MenuWidth({
    required this.width,
    required this.least,
    required this.inset,
    required this.child,
  });
  final double width;
  final bool least;
  final double inset;
  final Widget child;

  // [child] carries the [inset] round its rows: a field's list is [width] wide at least, a menu [width] plus it.
  @override
  Widget build(BuildContext context) => least
      ? ConstrainedBox(
          constraints: BoxConstraints(minWidth: math.max(0, width)),
          child: IntrinsicWidth(child: child),
        )
      : SizedBox(width: width + 2 * inset, child: child);
}

class _AnchorLayout extends SingleChildLayoutDelegate {
  const _AnchorLayout(
    this.anchor,
    this.direction,
    this.padding, {
    this.width,
    this.tooltip = false,
    this.widens = false,
    this.gap = 4,
  });
  final Rect anchor;
  final TextDirection direction;
  final EdgeInsets padding;
  final double? width;
  final bool tooltip;

  /// A field's list: [width] is its least, and it may widen to a control's most to fit its widest entry.
  final bool widens;

  /// How far it stands from [anchor].
  final double gap;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final available = math.max(
      0.0,
      constraints.maxWidth - padding.horizontal - 16,
    );
    final w = math.min(
      widens
          ? math.max(width ?? 0, neumorphicWideControlMax)
          : width ?? (tooltip ? 280 : 320),
      available,
    );
    return BoxConstraints(
      maxWidth: w,
      minWidth: tooltip ? 0 : math.min(width ?? 180, w),
      maxHeight: math.max(0, constraints.maxHeight - padding.vertical - 16),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    final below = size.height - padding.bottom - anchor.bottom - 4 - gap;
    final above = anchor.top - padding.top - 4 - gap;
    final preferBelow = tooltip
        ? above < child.height
        : below >= child.height || below >= above;
    final x = tooltip
        ? anchor.center.dx - child.width / 2
        : direction == TextDirection.rtl
        ? anchor.right - child.width
        : anchor.left;
    final y = preferBelow
        ? anchor.bottom + gap
        : anchor.top - child.height - gap;
    final left = padding.left + 8, top = padding.top + 8;
    return Offset(
      x.clamp(
        left,
        math.max(left, size.width - padding.right - child.width - 8),
      ),
      y.clamp(
        top,
        math.max(top, size.height - padding.bottom - child.height - 8),
      ),
    );
  }

  @override
  bool shouldRelayout(_AnchorLayout old) =>
      old.anchor != anchor ||
      old.direction != direction ||
      old.padding != padding ||
      old.width != width ||
      old.tooltip != tooltip ||
      old.widens != widens ||
      old.gap != gap;
}

/// Opens a menu beside a screen-coordinate anchor and returns the selected value.
/// Its position respects RTL, safe areas and the keyboard.
///
/// ```dart
/// showNeumorphicMenu<String>(context, anchor: rect, items: const [NeumorphicMenuItem('copy', 'Copy')])
/// ```
Future<T?> showNeumorphicMenu<T>(
  BuildContext context, {
  required Rect anchor,
  required List<NeumorphicMenuItem<T>> items,
  double? width,
  bool matchWidth = false,
  bool useRootNavigator = true,
  String? label,
  String? closeLabel,
  NeumorphicStyle? style,
  double? fieldWords,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final box = navigator.context.findRenderObject() as RenderBox;
  final local = anchor.shift(-box.localToGlobal(Offset.zero));
  final carried = _Carried(context, navigator.context);
  return _push(
    context,
    _RaisedRoute<T>(
      carried: carried,
      kind: _RaisedKind.menu,
      dismissible: true,
      closeLabel: closeLabel ?? carried.words.close,
      builder: (context) {
        final media = MediaQuery.of(context);
        return CustomSingleChildLayout(
          delegate: _AnchorLayout(
            local,
            carried.direction,
            media.padding + EdgeInsets.only(bottom: media.viewInsets.bottom),
            width: matchWidth ? anchor.width : width,
            widens: matchWidth && fieldWords != null,
            // A field's list stands clear of its field, as every field's list does.
            gap: fieldWords != null ? neumorphicFieldListGap : 4,
          ),
          child: NeumorphicMenu<T>(
            style: style,
            fieldWords: fieldWords,
            items: items,
            width: matchWidth ? anchor.width : width,
            label: label,
            onSelected: (value) => Navigator.of(context).pop(value),
          ),
        );
      },
    ),
    useRootNavigator,
  );
}

/// A handle for a tooltip or snack bar raised without a route.
abstract class NeumorphicRaised {
  /// Dismisses the raised surface; repeated calls have no effect.
  void dismiss();

  /// Completes after the raised surface has been removed.
  Future<void> get closed;
}

class _Overlaid implements NeumorphicRaised {
  _Overlaid(this.overlay);
  final OverlayState overlay;
  OverlayEntry? entry;
  VoidCallback? leave, beforeDismiss;
  FocusScopeNode? focusScope;
  final _closed = Completer<void>();
  bool _going = false;
  @override
  Future<void> get closed => _closed.future;
  @override
  void dismiss() {
    if (_going) return;
    _going = true;
    beforeDismiss?.call();
    if (leave == null) {
      remove();
    } else {
      leave!();
    }
  }

  void remove() {
    if (entry == null) return;
    final old = entry!;
    entry = null;
    old.remove();
    old.dispose();
    complete();
  }

  void complete() {
    _going = true;
    if (!_closed.isCompleted) _closed.complete();
  }
}

class _OverlayMotion extends StatefulWidget {
  const _OverlayMotion({
    required this.handle,
    required this.motion,
    required this.child,
    this.rise = 0,
  });
  final _Overlaid handle;
  final NeumorphicMotion motion;
  final Widget child;
  final double rise;
  @override
  State<_OverlayMotion> createState() => _OverlayMotionState();
}

class _OverlayMotionState extends State<_OverlayMotion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.motion.move,
    reverseDuration: widget.motion.leave,
  );
  @override
  void initState() {
    super.initState();
    widget.handle.leave = () =>
        _controller.reverse().then((_) => widget.handle.remove());
    _controller.forward();
  }

  @override
  void dispose() {
    widget.handle.leave = null;
    widget.handle.remove();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final value = widget.motion.enter.transform(_controller.value);
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, widget.rise * (1 - value)),
          child: child,
        ),
      );
    },
  );
}

/// The small soft panel drawn by a tooltip.
///
/// ```dart
/// NeumorphicTooltipFace(message: 'Share this view')
/// ```
class NeumorphicTooltipFace extends StatelessWidget {
  /// Creates a [NeumorphicTooltipFace].
  const NeumorphicTooltipFace({super.key, required this.message, this.style});

  /// Face, outline and spacing before the component theme.
  final NeumorphicStyle? style;

  /// The explanatory message.
  final String message;
  @override
  Widget build(BuildContext context) => _keepsRaisedWidth(
    most: 280,
    NeumorphicSurface(
      cast: NeumorphicSurfaceLevel.part,
      style: style,
      themeStyle: NeumorphicTheme.of(context).tooltipTheme,
      radius: NeumorphicRadii.chip,
      outlined: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: _Balanced(
        message,
        style: NeumorphicTheme.of(context).textTheme.caption
            .merge(
              neumorphicStyleOf([
                style,
                NeumorphicTheme.of(context).tooltipTheme,
              ], const {}).textStyle,
            )
            // The tooltip's one message is read, in the ink: in the caption's quiet ink it stood about 3:1 by night.
            .copyWith(
              color:
                  neumorphicStyleOf([
                    style,
                    NeumorphicTheme.of(context).tooltipTheme,
                  ], const {}).foreground ??
                  NeumorphicTheme.of(context).colors.ink,
            ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('message', message));
  }
}

/// Centred words as narrow as their line count allows, so a wrapped tooltip ends with no word alone ('A tooltip says
/// one / thing'); the face shrinks round them.
class _Balanced extends StatelessWidget {
  const _Balanced(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: c.maxWidth);
      final lines = tp.computeLineMetrics().length;
      var width = tp.width;
      if (lines > 1) {
        var lo = 0.0, hi = c.maxWidth;
        for (var i = 0; i < 12 && hi - lo > 1; i++) {
          final mid = (lo + hi) / 2;
          tp.layout(maxWidth: mid);
          if (tp.computeLineMetrics().length > lines) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        width = hi;
      }
      tp.dispose();
      return SizedBox(
        width: math.min(width.ceilToDouble() + 1, c.maxWidth),
        child: Text(text, style: style, textAlign: TextAlign.center),
      );
    },
  );
}

/// A raised face shown in place (a menu, a tooltip, a toast in a page's column) keeps the width it takes raised, from
/// [least] to [most], at the start of its column: never the column's whole width, so the same face looks the same
/// inline and raised. Raised, its route already gives it no more than [most], so this changes nothing there.
Widget _keepsRaisedWidth(
  Widget face, {
  double least = 0,
  required double most,
}) => Align(
  alignment: AlignmentDirectional.centerStart,
  widthFactor: 1,
  heightFactor: 1,
  child: ConstrainedBox(
    constraints: BoxConstraints(minWidth: least, maxWidth: most),
    child: face,
  ),
);

void _escapeOverlay(_Overlaid handle) {
  final layer = _EscapeLayer(() => !handle._closed.isCompleted, handle.dismiss);
  _registerEscape(layer);
  handle.closed.whenComplete(() => _removeEscape(layer));
}

/// Raises a tooltip by a screen-coordinate anchor without taking focus.
/// Dismiss its handle when its owner leaves; Escape also closes it.
///
/// ```dart
/// final tip = showNeumorphicTooltip(context, message: 'Share', anchor: rect);
/// ```
NeumorphicRaised showNeumorphicTooltip(
  BuildContext context, {
  required String message,
  required Rect anchor,
  NeumorphicStyle? style,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final box = overlay.context.findRenderObject() as RenderBox;
  final local = anchor.shift(-box.localToGlobal(Offset.zero));
  final carried = _Carried(context, overlay.context);
  final handle = _Overlaid(overlay);
  _escapeOverlay(handle);
  handle.entry = OverlayEntry(
    builder: (context) => carried.wrap(
      IgnorePointer(
        child: ExcludeSemantics(
          child: _OverlayMotion(
            handle: handle,
            motion: carried.motion,
            child: CustomSingleChildLayout(
              delegate: _AnchorLayout(
                local,
                carried.direction,
                MediaQuery.paddingOf(context),
                tooltip: true,
              ),
              child: NeumorphicTooltipFace(message: message, style: style),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(handle.entry!);
  return handle;
}

/// Shows help on pointer hover, keyboard focus or a long press, on Flutter's [RawTooltip]: the pointer may move onto
/// the tip and it stays, Escape hides it, and a screen reader hears the message as the control's tooltip. The tip is
/// the look's raised face, faded in above the control (below where there is no room), its tail never drawn.
///
/// ```dart
/// NeumorphicTooltip(message: 'Share', child: NeumorphicRoundButton(NeumorphicGlyphs.info, label: 'Share', onPressed: share))
/// ```
class NeumorphicTooltip extends StatelessWidget {
  /// Creates a [NeumorphicTooltip].
  const NeumorphicTooltip({
    super.key,
    required this.message,
    required this.child,
    this.wait = const Duration(milliseconds: 400),
    this.style,
  });

  /// State-resolved face styling passed to the raised tooltip.
  final NeumorphicStyle? style;

  /// The explanatory message.
  final String message;

  /// The content placed inside this component.
  final Widget child;

  /// The hover delay before showing the tooltip.
  final Duration wait;
  @override
  Widget build(BuildContext context) => MergeSemantics(
    // ui_core's placement: above the control, centred on it, below where there is no room.
    child: RawTooltipPlacement(
      builder: (context, positionDelegate) => RawTooltip(
        semanticsTooltip: message,
        hoverDelay: wait,
        positionDelegate: positionDelegate,
        // The tip fades on its own spring (_NeumorphicTipFade), from the way this animation runs; the tip stays in
        // the overlay until the spring has faded it out.
        animationStyle: _NeumorphicTipFade.life,
        tooltipBuilder: (context, animation) => ExcludeSemantics(
          child: _NeumorphicTipFade(
            showing: animation,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: NeumorphicTooltipFace(message: message, style: style),
            ),
          ),
        ),
        // Shows the tip while the control has the keys' focus, as a hover does.
        child: RawTooltipFocusFix(
          // The tip points at the child's middle: a round key under it stands its face there, not at its target's
          // start.
          child: NeumorphicFacePlace(
            alignment: AlignmentDirectional.center,
            child: child,
          ),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<Duration>(
          'wait',
          wait,
          defaultValue: const Duration(milliseconds: 400),
        ),
      );
  }
}

/// A tooltip's tip fading in and out on ui_core's effects spring (critically damped, k 1600; under Reduce Motion a
/// short fade), driven by the way [showing], the [RawTooltip]'s animation, runs: forward fades it in, reverse out.
class _NeumorphicTipFade extends StatefulWidget {
  const _NeumorphicTipFade({required this.showing, required this.child});

  /// How long the [RawTooltip] keeps a hidden tip in the overlay: longer than the spring takes to fade it out
  /// (about 230 ms).
  static const AnimationStyle life = AnimationStyle(
    duration: Duration(milliseconds: 150),
    reverseDuration: Duration(milliseconds: 300),
  );

  final Animation<double> showing;
  final Widget child;

  @override
  State<_NeumorphicTipFade> createState() => _NeumorphicTipFadeState();
}

class _NeumorphicTipFadeState extends State<_NeumorphicTipFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opacity = AnimationController(vsync: this);
  bool? _shown;

  @override
  void initState() {
    super.initState();
    widget.showing.addStatusListener(_follow);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow(widget.showing.status);
  }

  @override
  void didUpdateWidget(_NeumorphicTipFade old) {
    super.didUpdateWidget(old);
    if (old.showing != widget.showing) {
      old.showing.removeStatusListener(_follow);
      widget.showing.addStatusListener(_follow);
      _follow(widget.showing.status);
    }
  }

  @override
  void dispose() {
    widget.showing.removeStatusListener(_follow);
    _opacity.dispose();
    super.dispose();
  }

  void _follow(AnimationStatus status) {
    final shown = status.isForwardOrCompleted;
    if (shown == _shown) return;
    _shown = shown;
    _opacity.springTo(
      shown ? 1 : 0,
      DesignMotionPolicy.of(context).effects(dampingRatio: 1, stiffness: 1600),
    );
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

/// A soft notice with a tone glyph, an optional action and a dismiss button.
///
/// ```dart
/// NeumorphicSnackBar('Saved', tone: NeumorphicTone.success, actionLabel: 'Undo', onAction: undo)
/// ```
class NeumorphicSnackBar extends StatelessWidget {
  /// Creates a [NeumorphicSnackBar].
  const NeumorphicSnackBar(
    this.message, {
    super.key,
    this.title,
    this.tone = NeumorphicTone.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.dismissLabel,
    this.style,
    this.live = true,
  });

  /// Whether it announces itself when it appears; the toaster announces its own.
  final bool live;

  /// Face, outline and spacing before the component theme.
  final NeumorphicStyle? style;

  /// The explanatory message.
  final String message;

  /// The primary heading.
  final String? title;

  /// The label of the optional action.
  final String? actionLabel;

  /// The accessible label for dismissal; null uses localizations.
  final String? dismissLabel;

  /// The semantic tone used for the indicator and its colours.
  final NeumorphicTone tone;

  /// Called when the optional action is activated.
  final VoidCallback? onAction;

  /// Called when the dismiss action is activated.
  final VoidCallback? onDismiss;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final look = neumorphicStyleOf([style, t.snackBarTheme], const {});
    final icon = switch (tone) {
      NeumorphicTone.info => NeumorphicGlyphs.info,
      NeumorphicTone.success => NeumorphicGlyphs.circleCheck,
      NeumorphicTone.warning => NeumorphicGlyphs.triangleAlert,
      NeumorphicTone.danger => NeumorphicGlyphs.circleAlert,
    };
    final titleStyle = t.textTheme.title
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    final messageStyle = t.textTheme.body
        .merge(look.textStyle)
        .copyWith(color: look.foreground);
    // The first line stands on the line of the keys beside it, the middle of their targets: from the top of the row
    // it sat a line above 'Undo' and the dismiss key. With no key it stays at the top.
    final firstLine = neumorphicLineHeight(
      context,
      title != null ? titleStyle : messageStyle,
    );
    final lead = actionLabel != null || onDismiss != null
        ? math.max(0.0, (NeumorphicChromeMetrics.targetSize - firstLine) / 2)
        : 0.0;
    final glyph = look.iconSize ?? 22;
    final words = Padding(
      padding: EdgeInsets.only(top: lead),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) Text(title!, style: titleStyle),
          Text(message, style: messageStyle),
        ],
      ),
    );
    return Semantics(
      liveRegion: live,
      container: true,
      child: _keepsRaisedWidth(
        most: 560,
        NeumorphicSurface(
          cast: NeumorphicSurfaceLevel.slab,
          style: style,
          themeStyle: t.snackBarTheme,
          radius: NeumorphicRadii.well,
          outlined: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: lead + math.max(0.0, (firstLine - glyph) / 2),
                    ),
                    child: Icon(icon, size: glyph, color: look.foreground),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // The act stands at the words' end, its target level with them (on a line of its own under them
                    // its 48 target left a tall empty band in the toast), while that costs the words no line: at
                    // twice the text it held the end and broke the message one word to a line.
                    child: actionLabel == null
                        ? words
                        : BesideOrUnder(
                            need: 0,
                            centre: false,
                            mark: 0,
                            children: [
                              words,
                              NeumorphicLink(actionLabel!, onPressed: onAction),
                            ],
                          ),
                  ),
                  if (onDismiss != null) ...[
                    const SizedBox(width: 8),
                    neumorphicAtEnd(
                      NeumorphicRoundButton(
                        NeumorphicGlyphs.close,
                        label:
                            dismissLabel ??
                            NeumorphicLocalizations.of(context).dismiss,
                        onPressed: onDismiss,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('live', live, defaultValue: true))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('message', message))
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(StringProperty('dismissLabel', dismissLabel, defaultValue: null))
      ..add(
        EnumProperty<NeumorphicTone>(
          'tone',
          tone,
          defaultValue: NeumorphicTone.info,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onAction', onAction))
      ..add(ObjectFlagProperty<VoidCallback>.has('onDismiss', onDismiss));
  }
}

final _snackBars = Expando<_Overlaid>();

/// Shows one snack bar per overlay. Hover or focus pauses its timeout; with an
/// action, accessible navigation leaves it up until dismissed. Escape closes it.
///
/// ```dart
/// showNeumorphicSnackBar(context, message: 'Saved', actionLabel: 'Undo', onAction: undo)
/// ```
NeumorphicRaised showNeumorphicSnackBar(
  BuildContext context, {
  required String message,
  String? title,
  NeumorphicTone tone = NeumorphicTone.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  double bottom = 0,
  String? dismissLabel,
  NeumorphicStyle? style,
}) {
  // Under a toaster it queues there, where snack bars stack and wait their turn; a call that sets its own placement or
  // style stands on its own in the overlay.
  final toaster = bottom == 0 && dismissLabel == null && style == null
      ? RawToaster.maybeOf(context)
      : null;
  if (toaster != null) {
    return _Toasted(
      toaster.show(
        RawToast(
          message: message,
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
          duration: duration,
          data: tone,
        ),
      ),
    );
  }
  final overlay = Overlay.of(context, rootOverlay: true);
  final carried = _Carried(context, overlay.context);
  final focus = FocusManager.instance.primaryFocus;
  _snackBars[overlay]?.dismiss();
  final handle = _Overlaid(overlay);
  _snackBars[overlay] = handle;
  _escapeOverlay(handle);
  handle.closed.whenComplete(() {
    if (identical(_snackBars[overlay], handle)) _snackBars[overlay] = null;
  });
  handle.beforeDismiss = () {
    final owner = focus?.context;
    if ((handle.focusScope?.hasFocus ?? false) &&
        owner != null &&
        owner.mounted &&
        focus!.canRequestFocus &&
        (ModalRoute.of(owner)?.isCurrent ?? true)) {
      focus.requestFocus();
    }
  };
  void close() => handle.dismiss();
  handle.entry = OverlayEntry(
    builder: (context) => carried.wrap(
      _SnackHost(
        handle: handle,
        motion: carried.motion,
        duration: duration,
        bottom: bottom,
        onClose: close,
        hasAction: onAction != null,
        child: NeumorphicSnackBar(
          message,
          style: style,
          title: title,
          tone: tone,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  onAction();
                  close();
                },
          onDismiss: close,
          dismissLabel: dismissLabel,
        ),
      ),
    ),
  );
  overlay.insert(handle.entry!);
  return handle;
}

class _Toasted implements NeumorphicRaised {
  _Toasted(this.handle);
  final RawToastController handle;

  @override
  void dismiss() => handle.dismiss();

  @override
  Future<void> get closed => handle.closed;
}

class _SnackHost extends StatefulWidget {
  const _SnackHost({
    required this.handle,
    required this.motion,
    required this.duration,
    required this.bottom,
    required this.hasAction,
    required this.onClose,
    required this.child,
  });
  final _Overlaid handle;
  final NeumorphicMotion motion;
  final Duration duration;
  final double bottom;
  final bool hasAction;
  final VoidCallback onClose;
  final Widget child;
  @override
  State<_SnackHost> createState() => _SnackHostState();
}

class _SnackHostState extends State<_SnackHost> {
  final _focus = FocusScopeNode();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    widget.handle.focusScope = _focus;
  }

  bool _hovered = false, _focused = false;
  void _wait() {
    _timer?.cancel();
    if (_hovered ||
        _focused ||
        (widget.hasAction && MediaQuery.accessibleNavigationOf(context))) {
      return;
    }
    _timer = Timer(widget.duration, widget.onClose);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wait();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.handle.focusScope = null;
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + widget.bottom + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _OverlayMotion(
            handle: widget.handle,
            motion: widget.motion,
            rise: 12,
            child: FocusScope(
              node: _focus,
              includeSemantics: false,
              onFocusChange: (value) {
                _focused = value;
                _wait();
              },
              child: MouseRegion(
                onEnter: (_) {
                  _hovered = true;
                  _wait();
                },
                onExit: (_) {
                  _hovered = false;
                  _wait();
                },
                child: Dismissible(
                  key: ObjectKey(widget.handle),
                  direction: DismissDirection.down,
                  movementDuration: widget.motion.leave,
                  resizeDuration: null,
                  onDismissed: (_) => widget.onClose(),
                  child: SingleChildScrollView(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A dialog's and a sheet's title.
TextStyle _titleStyle(NeumorphicThemeData t) =>
    t.textTheme.text(24, 30, weight: FontWeight.w600);
