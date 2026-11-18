/// A dialog, headless: a modal route that opens and closes on a spring,
/// traps focus and gives it back to whatever held it, closes on Escape and
/// Android's back, and tells a screen reader it is a dialog or an alert; and
/// an alert's layout, its words scrolling under actions that stay put and
/// stack when they don't fit side by side, the safe action focused first.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'adaptive_shell.dart' show DesignWindowSizeClass;
import 'barrier.dart';
import 'internal/painted_barrier.dart';
import 'internal/route_spring.dart';
import 'localizations.dart';
import 'pressable.dart';

/// Builds a dialog route's page: the look's dialog, which [details] lets it
/// move as the route opens and closes.
typedef DesignDialogBuilder = Widget Function(
  BuildContext context,
  DesignDialogDetails details,
);

/// What a [DesignDialogRoute]'s builder paints from.
@immutable
class DesignDialogDetails {
  /// The route's details; the route makes them.
  const DesignDialogDetails({
    required this.animation,
    required this.isAlert,
    required this.close,
  });

  /// The dialog's presence on the route's spring: 0 gone, 1 open, for the
  /// look's own scale or fade. An underdamped token passes 1 before it
  /// rests: clamp it before an `Opacity`, which asserts outside 0 to 1, and
  /// let it overshoot only in a scale or a move. Under Reduce Motion it
  /// stays at 1 and the route fades the whole dialog itself.
  final Animation<double> animation;

  /// Whether the route is an alert ([DesignDialogRoute.isAlert]).
  final bool isAlert;

  /// Closes the dialog through `Navigator.maybePop`, so a `PopScope` in it
  /// may refuse: for a close button.
  final VoidCallback close;
}

/// A modal dialog or alert. Push it with `Navigator.push`; its page is
/// [builder]'s, over a barrier.
///
/// It opens on a spring ([dampingRatio], [stiffness]) and closes on the
/// same one, or on its own ([closeDampingRatio], [closeStiffness]), from
/// wherever it is when it turns; under Reduce Motion it fades instead
/// (`designReduceMotionOf`). As it opens it takes focus and keeps Tab
/// inside it; as it closes, focus goes back to the node that held it when
/// it was pushed (the button that opened it, when the keyboard pressed it).
///
/// Escape, Android's back, a barrier tap (when [barrierDismissible]) and
/// [DesignDialogDetails.close] all close it through `Navigator.maybePop`, so
/// a `PopScope` in it may refuse any of them. Escape closes an alert too,
/// though its barrier does not.
///
/// A screen reader hears a dialog (an alert when [isAlert]) named by
/// [semanticLabel]; with none, a [DesignDialog] inside names it by its
/// title, or by the words for a dialog or an alert.
///
/// An alert that asks whether to delete, pushed with
/// `Navigator.of(context).push(route)`; the push's future answers true:
///
/// ```dart
/// DesignDialogRoute<bool>(
///   isAlert: true,
///   builder: (context, details) => DesignDialog(
///     title: 'Delete the draft?',
///     content: const Text('It cannot be brought back.'),
///     actions: [
///       DesignDialogAction(
///         label: 'Cancel',
///         onPressed: () => Navigator.of(context).pop(false),
///       ),
///       DesignDialogAction(
///         label: 'Delete',
///         isDestructiveAction: true,
///         onPressed: () => Navigator.of(context).pop(true),
///       ),
///     ],
///     actionBuilder: (context, action, details) => Text(action.label),
///   ),
/// )
/// ```
class DesignDialogRoute<T> extends PopupRoute<T> {
  /// A dialog whose page [builder] paints.
  DesignDialogRoute({
    required this.builder,
    this.isAlert = false,
    this.semanticLabel,
    this.dampingRatio = 1,
    this.stiffness = 1400,
    this.closeDampingRatio,
    this.closeStiffness,
    Color barrierColor = const Color(0x66000000),
    this.barrierBuilder,
    String? barrierLabel,
    bool? barrierDismissible,
    this.anchorPoint,
    super.settings,
  }) : assert(dampingRatio > 0 && stiffness > 0),
       assert((closeDampingRatio ?? 1) > 0 && (closeStiffness ?? 1) > 0),
       _scrim = barrierColor,
       _givenBarrierLabel = barrierLabel,
       _dismissOnBarrier = barrierDismissible ?? !isAlert,
       _spring = RouteSpring(
         dampingRatio: dampingRatio,
         stiffness: stiffness,
         closeDampingRatio: closeDampingRatio,
         closeStiffness: closeStiffness,
       );

  /// Paints the dialog's page, which fills the screen: a [DesignDialog]
  /// places itself in it.
  final DesignDialogBuilder builder;

  /// Whether it is an alert, which asks for an answer: a screen reader hears
  /// an alert (`SemanticsRole.alertDialog`; the web's `alertdialog`) and a
  /// barrier tap does not close it unless [barrierDismissible] says so.
  /// Defaults to false: a dialog.
  final bool isAlert;

  /// What a screen reader calls the dialog, usually its title; null: a
  /// [DesignDialog]'s title names it, else
  /// [DesignLocalizations.dialogLabel] or
  /// [DesignLocalizations.alertDialogLabel].
  final String? semanticLabel;

  /// The open spring's damping ratio (ζ), and the close spring's unless
  /// [closeDampingRatio] is given. Defaults to 1.
  final double dampingRatio;

  /// The open spring's stiffness (k), and the close spring's unless
  /// [closeStiffness] is given. Defaults to 1400.
  final double stiffness;

  /// The close spring's damping ratio (ζ); null: [dampingRatio]. A look
  /// whose dialog falls away on a spring of its own sets it with
  /// [closeStiffness].
  final double? closeDampingRatio;

  /// The close spring's stiffness (k); null: [stiffness].
  final double? closeStiffness;

  /// Paints the barrier in place of the barrier colour (a look's own
  /// screen); null: the colour.
  final DesignBarrierBuilder? barrierBuilder;

  /// Which half of a folding screen it opens on: the half nearest this
  /// point (`DisplayFeatureSubScreen`); null: the reading start's.
  final Offset? anchorPoint;

  final Color _scrim;
  final String? _givenBarrierLabel;
  final bool _dismissOnBarrier;
  final RouteSpring _spring;
  final RouteFocusReturn _focus = RouteFocusReturn();

  /// What a screen reader calls the barrier; null:
  /// [DesignLocalizations.modalBarrierDismissLabel].
  @override
  String? get barrierLabel {
    final context = navigator?.context;
    return _givenBarrierLabel ??
        (context == null
            ? null
            : DesignLocalizations.of(context).modalBarrierDismissLabel);
  }

  /// The barrier's colour; null while [barrierBuilder] paints it.
  @override
  Color? get barrierColor => barrierBuilder == null ? _scrim : null;

  /// Whether a barrier tap closes it; defaults to true for a dialog and
  /// false for an alert.
  @override
  bool get barrierDismissible => _dismissOnBarrier;

  /// Focus stays inside it: Tab from its last stop goes to its first.
  @override
  TraversalEdgeBehavior get traversalEdgeBehavior =>
      TraversalEdgeBehavior.closedLoop;

  /// Nominal: the spring decides how long it takes ([createSimulation]).
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    final paint = barrierBuilder;
    return paint == null ? barrier : paintedBarrier(paint, animation!, barrier);
  }

  @override
  void install() {
    _focus.capture();
    super.install();
    _spring.attach(controller!);
  }

  /// The spring from where the dialog is to open or gone.
  @override
  Simulation createSimulation({required bool forward}) =>
      _spring.simulation(navigator!.context, to: forward ? 1 : 0);

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    _focus.giveBack();
    return popped;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final reduced = _spring.reduced;
    final labelled = semanticLabel != null;
    return DisplayFeatureSubScreen(
      anchorPoint: anchorPoint,
      child: escapeCloses(
        context,
        Semantics(
          role: isAlert ? SemanticsRole.alertDialog : SemanticsRole.dialog,
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: labelled ? true : null,
          label: semanticLabel,
          child: _DialogScope(
            isAlert: isAlert,
            labelled: labelled,
            child: Builder(
              builder: (context) => builder(
                context,
                DesignDialogDetails(
                  animation: reduced
                      ? kAlwaysCompleteAnimation
                      : _spring.presence,
                  isAlert: isAlert,
                  close: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _spring.reduced
      ? FadeTransition(opacity: animation, child: child)
      : child;
}

// What a DesignDialog reads of the route round it.
class _DialogScope extends InheritedWidget {
  const _DialogScope({
    required this.isAlert,
    required this.labelled,
    required super.child,
  });

  final bool isAlert;
  final bool labelled;

  static _DialogScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DialogScope>();

  @override
  bool updateShouldNotify(_DialogScope oldWidget) =>
      isAlert != oldWidget.isAlert || labelled != oldWidget.labelled;
}

/// An action at the foot of a [DesignDialog].
@immutable
class DesignDialogAction {
  /// An action [label]led, that [onPressed] runs.
  const DesignDialogAction({
    required this.label,
    required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.data,
  });

  /// Its words, and what a screen reader calls it.
  final String label;

  /// Runs it (usually `Navigator.pop` with an answer); null disables it.
  final VoidCallback? onPressed;

  /// Whether it is the one the dialog is for (Save, Send), which the look
  /// draws first in rank. With no destructive action, it takes focus as
  /// the dialog opens. Defaults to false.
  final bool isDefaultAction;

  /// Whether it destroys or removes something (Delete, Discard), which the
  /// look draws as a warning. While a dialog has one, focus opens on the
  /// first action that is not. Defaults to false.
  final bool isDestructiveAction;

  /// Anything else the look needs to paint it (an icon, a variant).
  final Object? data;

  /// Whether it takes presses.
  bool get enabled => onPressed != null;
}

/// What the look paints a [DesignDialogAction] from.
@immutable
class DesignDialogActionDetails {
  /// The action's details; the dialog makes them.
  const DesignDialogActionDetails({
    required this.states,
    required this.stacked,
    required this.index,
    required this.count,
  });

  /// Its pressable states: focused only when the keyboard moved focus to it.
  final Set<WidgetState> states;

  /// Whether the actions are stacked, one to a line, because they do not fit
  /// side by side: a look usually widens each to the dialog's width.
  final bool stacked;

  /// Its place among the actions, 0 for the first given.
  final int index;

  /// How many actions the dialog has.
  final int count;
}

/// What the look paints a [DesignDialog]'s frame and action bar from.
@immutable
class DesignDialogFrameDetails {
  /// The layout's details; the dialog makes them.
  const DesignDialogFrameDetails({
    required this.scrolled,
    required this.overflows,
    required this.stacked,
  });

  /// Whether the words are scrolled off their top: a look's line under the
  /// top edge.
  final bool scrolled;

  /// Whether the words run past the room they have and scroll: a look's
  /// line over the actions.
  final bool overflows;

  /// Whether the actions are stacked ([DesignDialogActionDetails.stacked]).
  final bool stacked;
}

/// Paints an action of a [DesignDialog].
typedef DesignDialogActionBuilder = Widget Function(
  BuildContext context,
  DesignDialogAction action,
  DesignDialogActionDetails details,
);

Widget _actionLabel(
  BuildContext context,
  DesignDialogAction action,
  DesignDialogActionDetails details,
) => Text(action.label);

/// Wraps a part of a [DesignDialog] (its frame or its action bar) in the
/// look's paint.
typedef DesignDialogPartBuilder = Widget Function(
  BuildContext context,
  DesignDialogFrameDetails details,
  Widget child,
);

/// An alert's or a simple dialog's layout: [title] and [content] scroll
/// together over [actions], which stay put. The actions sit side by side,
/// sharing the row on a compact screen and aligned at the end on a larger
/// screen. When their labels do not fit, including at a large text size,
/// they stack, one to a line, the last given (the confirm) on top and the
/// first (the dismissive one) at the bottom, as Material and iOS stack
/// them.
///
/// As the dialog opens, focus goes to the safe action: while an action is
/// destructive, the first enabled action that is not (Cancel); else the
/// default action; else the first enabled one. Enter or Space presses the
/// focused action; nothing presses one the keyboard has not reached.
///
/// It centres itself in the room the screen's insets, the on-screen
/// keyboard and [insetPadding] leave, between [constraints]' widths, and is
/// as wide as its words and actions need. The look paints the rest:
/// [frameBuilder] the surface round all of it, [actionsBuilder] the bar
/// round the actions, [titleBuilder] the title, [actionBuilder] each action.
///
/// ```dart
/// DesignDialog(
///   title: 'Discard changes?',
///   content: const Text('Your edits to this note will be lost.'),
///   actions: [
///     DesignDialogAction(label: 'Keep editing', onPressed: () {}),
///     DesignDialogAction(label: 'Discard', isDestructiveAction: true, onPressed: () {}),
///   ],
///   actionBuilder: (context, action, details) => Text(action.label),
///   frameBuilder: (context, details, child) => DecoratedBox(
///     decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
///     child: child,
///   ),
/// )
/// ```
class DesignDialog extends StatefulWidget {
  /// A dialog's layout of [title], [content] and [actions].
  const DesignDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.actionWidgets = const [],
    this.actionBuilder = _actionLabel,
    this.titleBuilder,
    this.actionsBuilder,
    this.frameBuilder,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    this.constraints = const BoxConstraints(minWidth: 280, maxWidth: 560),
    this.actionSpacing = 8,
    this.stackedActionSpacing = 8,
    this.scrollController,
  }) : assert(actionSpacing >= 0 && stackedActionSpacing >= 0);

  /// The heading, a screen reader's header; it names the route when the
  /// [DesignDialogRoute] has no `semanticLabel`. Null: none.
  final String? title;

  /// The body, under the title; it scrolls with it when long. Null: none.
  final Widget? content;

  /// The actions at the foot, in reading order (the dismissive one first).
  final List<DesignDialogAction> actions;

  /// Complete action controls in reading order, as an alternative to
  /// [actions]. Each keeps its own semantics, focus and activation. Set
  /// autofocus on the safe action when the dialog opens.
  final List<Widget> actionWidgets;

  /// Paints an action from [actions]. Defaults to its label.
  final DesignDialogActionBuilder actionBuilder;

  /// Paints the title; null: a plain `Text`.
  final Widget Function(BuildContext context, String title)? titleBuilder;

  /// Wraps the action bar (its padding, a line over it when the words
  /// overflow); null: the bar as it is.
  final DesignDialogPartBuilder? actionsBuilder;

  /// Wraps the whole dialog in the look's surface; null: no surface.
  final DesignDialogPartBuilder? frameBuilder;

  /// The least room left round it, inside the screen's insets and the
  /// on-screen keyboard. Defaults to 40 at the sides and 24 above and
  /// below, as Material's.
  final EdgeInsetsGeometry insetPadding;

  /// Its least and most size. Defaults to 280 to 560 wide, as Material's.
  final BoxConstraints constraints;

  /// The gap between actions side by side. Defaults to 8.
  final double actionSpacing;

  /// The gap between stacked actions. Defaults to 8.
  final double stackedActionSpacing;

  /// The controller of the words' scroll view; null: the dialog makes its
  /// own and disposes it. One given is never disposed by the dialog.
  final ScrollController? scrollController;

  /// The index of the action that takes focus as a dialog of [actions]
  /// opens, or null when none can: while one is destructive, the first
  /// enabled action that is not; else the first enabled default action;
  /// else the first enabled one.
  static int? safeActionIndex(List<DesignDialogAction> actions) {
    final enabled = [
      for (final (i, a) in actions.indexed)
        if (a.enabled) i,
    ];
    if (enabled.isEmpty) return null;
    if (actions.any((a) => a.isDestructiveAction)) {
      for (final i in enabled) {
        if (!actions[i].isDestructiveAction) return i;
      }
      return null;
    }
    for (final i in enabled) {
      if (actions[i].isDefaultAction) return i;
    }
    return enabled.first;
  }

  @override
  State<DesignDialog> createState() => _DesignDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(
        ObjectFlagProperty<DesignDialogActionBuilder>.has(
          'actionBuilder',
          actionBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<Widget Function(BuildContext, String)>.has(
          'titleBuilder',
          titleBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<DesignDialogPartBuilder>.has(
          'actionsBuilder',
          actionsBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<DesignDialogPartBuilder>.has(
          'frameBuilder',
          frameBuilder,
        ),
      )
      ..add(
        DiagnosticsProperty<ScrollController>(
          'scrollController',
          scrollController,
          defaultValue: null,
        ),
      )
      ..add(
        IterableProperty<DesignDialogAction>(
          'actions',
          actions,
          defaultValue: const <DesignDialogAction>[],
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>('insetPadding', insetPadding),
      )
      ..add(DiagnosticsProperty<BoxConstraints>('constraints', constraints))
      ..add(DoubleProperty('actionSpacing', actionSpacing, defaultValue: 8))
      ..add(
        DoubleProperty(
          'stackedActionSpacing',
          stackedActionSpacing,
          defaultValue: 8,
        ),
      );
  }
}

class _DesignDialogState extends State<DesignDialog> {
  ScrollController? _own;
  bool _scrolled = false;
  bool _overflows = false;
  bool _stacked = false;

  ScrollController get _scroll =>
      widget.scrollController ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetricsNotification n) {
    _read(n.metrics);
    return false;
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0) _read(n.metrics);
    return false;
  }

  void _read(ScrollMetrics m) {
    final scrolled = m.pixels > m.minScrollExtent;
    final overflows = m.maxScrollExtent > m.minScrollExtent;
    if (scrolled == _scrolled && overflows == _overflows) return;
    setState(() {
      _scrolled = scrolled;
      _overflows = overflows;
    });
  }

  void _onStacked(bool stacked) {
    if (!mounted || stacked == _stacked) return;
    setState(() => _stacked = stacked);
  }

  @override
  Widget build(BuildContext context) {
    final scope = _DialogScope.maybeOf(context);
    final words = DesignLocalizations.of(context);
    final names = !(scope?.labelled ?? false);
    final details = DesignDialogFrameDetails(
      scrolled: _scrolled,
      overflows: _overflows,
      stacked: _stacked,
    );
    final title = widget.title;
    final body = NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: SingleChildScrollView(
          controller: _scroll,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Semantics(
                  header: true,
                  namesRoute: names ? true : null,
                  child:
                      widget.titleBuilder?.call(context, title) ?? Text(title),
                ),
              ?widget.content,
            ],
          ),
        ),
      ),
    );
    final actions = widget.actions;
    assert(
      actions.isEmpty || widget.actionWidgets.isEmpty,
      'Give either actions or actionWidgets.',
    );
    final safe = DesignDialog.safeActionIndex(actions);
    Widget? bar;
    if (actions.isNotEmpty || widget.actionWidgets.isNotEmpty) {
      bar = _ActionBar(
        spacing: widget.actionSpacing,
        stackedSpacing: widget.stackedActionSpacing,
        shareWidth:
            DesignWindowSizeClass.of(context) == DesignWindowSizeClass.compact,
        onStacked: _onStacked,
        children: [
          ...widget.actionWidgets,
          for (final (i, a) in actions.indexed)
            DesignPressable(
              onPressed: a.onPressed,
              autofocus: i == safe,
              semanticLabel: a.label,
              excludeSemantics: true,
              builder: (context, states, _) => widget.actionBuilder(
                context,
                a,
                DesignDialogActionDetails(
                  states: states,
                  stacked: _stacked,
                  index: i,
                  count: actions.length,
                ),
              ),
            ),
        ],
      );
      bar = widget.actionsBuilder?.call(context, details, bar) ?? bar;
    }
    Widget dialog = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(child: body),
          ?bar,
        ],
      ),
    );
    dialog = widget.frameBuilder?.call(context, details, dialog) ?? dialog;
    // With neither the route's label nor a title, the dialog names itself.
    if (title == null && names) {
      dialog = Semantics(
        container: true,
        namesRoute: true,
        label: (scope?.isAlert ?? false)
            ? words.alertDialogLabel
            : words.dialogLabel,
        child: dialog,
      );
    }
    final room =
        widget.insetPadding.resolve(Directionality.of(context)) +
        MediaQuery.paddingOf(context) +
        MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: room,
      child: MediaQuery.removeViewInsets(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
          child: Center(
            child: ConstrainedBox(
              constraints: widget.constraints,
              child: dialog,
            ),
          ),
        ),
      ),
    );
  }
}

// The actions: side by side at the end while every one fits at its own
// width, else stacked, the last on top, each at the end of its line. Whether
// they fit is read from their widest content (their max intrinsic widths),
// so an action the look widens once stacked does not keep them stacked.
class _ActionBar extends MultiChildRenderObjectWidget {
  const _ActionBar({
    required this.spacing,
    required this.stackedSpacing,
    required this.shareWidth,
    required this.onStacked,
    required super.children,
  });

  final double spacing;
  final double stackedSpacing;
  final bool shareWidth;
  final ValueChanged<bool> onStacked;

  @override
  _RenderActionBar createRenderObject(BuildContext context) => _RenderActionBar(
    spacing: spacing,
    stackedSpacing: stackedSpacing,
    shareWidth: shareWidth,
    onStacked: onStacked,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderActionBar render) {
    render
      ..spacing = spacing
      ..stackedSpacing = stackedSpacing
      ..shareWidth = shareWidth
      ..onStacked = onStacked
      ..textDirection = Directionality.of(context);
  }
}

class _ActionBarParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderActionBar extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionBarParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionBarParentData> {
  _RenderActionBar({
    required this._spacing,
    required this._stackedSpacing,
    required this._shareWidth,
    required this.onStacked,
    required this._textDirection,
  });

  double _spacing;
  bool _shareWidth;
  set shareWidth(bool value) {
    if (_shareWidth == value) return;
    _shareWidth = value;
    markNeedsLayout();
  }

  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _stackedSpacing;
  set stackedSpacing(double value) {
    if (value == _stackedSpacing) return;
    _stackedSpacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  ValueChanged<bool> onStacked;
  bool? _reported;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionBarParentData) {
      child.parentData = _ActionBarParentData();
    }
  }

  List<RenderBox> get _children => getChildrenAsList();

  // The width side by side: each action's widest content and the gaps.
  double get _rowWidth {
    final children = _children;
    if (children.isEmpty) return 0;
    var width = 0.0;
    var widest = 0.0;
    for (final c in children) {
      final natural = c.getMaxIntrinsicWidth(double.infinity);
      width += natural;
      if (natural > widest) widest = natural;
    }
    return (_shareWidth ? widest * children.length : width) +
        _spacing * (children.length - 1);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var widest = 0.0;
    for (final c in _children) {
      final w = c.getMinIntrinsicWidth(double.infinity);
      if (w > widest) widest = w;
    }
    return widest;
  }

  @override
  double computeMaxIntrinsicWidth(double height) => _rowWidth;

  @override
  double computeMinIntrinsicHeight(double width) => _height(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _height(width);

  double _height(double width) {
    final children = _children;
    if (children.isEmpty) return 0;
    if (_rowWidth <= width) {
      var tallest = 0.0;
      for (final c in children) {
        final h = c.getMaxIntrinsicHeight(double.infinity);
        if (h > tallest) tallest = h;
      }
      return tallest;
    }
    var total = _stackedSpacing * (children.length - 1);
    for (final c in children) {
      total += c.getMaxIntrinsicHeight(width);
    }
    return total;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() {
    size = _layout(constraints, dry: false);
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final children = _children;
    final room = constraints.maxWidth;
    final row = _rowWidth;
    final stacked = row > room;
    // Side by side, each at its own content's width (an action that fills
    // what it is given stays its size); stacked, each up to the bar's width.
    final share =
        _shareWidth && !stacked && room.isFinite && children.isNotEmpty
        ? (room - _spacing * (children.length - 1)) / children.length
        : null;
    BoxConstraints loose(RenderBox c) => share != null
        ? BoxConstraints.tightFor(width: share)
        : BoxConstraints(
            maxWidth: stacked ? room : c.getMaxIntrinsicWidth(double.infinity),
          );
    Size sizeOf(RenderBox c) => dry
        ? c.getDryLayout(loose(c))
        : (c..layout(loose(c), parentUsesSize: true)).size;
    final sizes = [for (final c in children) sizeOf(c)];
    final width = room.isFinite ? room : constraints.constrainWidth(row);
    final rtl = _textDirection == TextDirection.rtl;
    double height;
    if (!stacked) {
      height = 0;
      for (final s in sizes) {
        if (s.height > height) height = s.height;
      }
      if (!dry) {
        // At the end: the last action against the end edge.
        var used = _spacing * (sizes.length - 1);
        for (final s in sizes) {
          used += s.width;
        }
        var x = rtl ? width - (width - used) : width - used;
        for (final (i, c) in children.indexed) {
          final s = sizes[i];
          final data = c.parentData! as _ActionBarParentData;
          final left = rtl ? x - s.width : x;
          data.offset = Offset(left, (height - s.height) / 2);
          x = rtl ? left - _spacing : left + s.width + _spacing;
        }
      }
    } else {
      height = _stackedSpacing * (sizes.length - 1);
      for (final s in sizes) {
        height += s.height;
      }
      if (!dry) {
        // The last on top, each at its line's end.
        var y = 0.0;
        for (var i = children.length - 1; i >= 0; i--) {
          final s = sizes[i];
          final data = children[i].parentData! as _ActionBarParentData;
          data.offset = Offset(rtl ? 0 : width - s.width, y);
          y += s.height + _stackedSpacing;
        }
      }
    }
    if (!dry && _reported != stacked) {
      _reported = stacked;
      // Told after the frame: the dialog builds its actions again, now
      // knowing.
      WidgetsBinding.instance.addPostFrameCallback((_) => onStacked(stacked));
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
