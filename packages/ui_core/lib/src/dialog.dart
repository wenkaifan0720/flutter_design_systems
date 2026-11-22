/// A dialog, headless: a modal route that opens and closes on a spring,
/// traps focus and gives it back to whatever held it, closes on Escape and
/// Android's back, and tells a screen reader it is a dialog or an alert; and
/// an alert's layout, its words scrolling under actions that stay put and
/// stack when they don't fit side by side, the safe action focused first.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'action_bar.dart';
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
/// [semanticLabel]; with none, a [RawAlertDialog] inside names it by its
/// title, or by the words for a dialog or an alert.
///
/// An alert that asks whether to delete, pushed with
/// `Navigator.of(context).push(route)`; the push's future answers true:
///
/// ```dart
/// DesignDialogRoute<bool>(
///   isAlert: true,
///   builder: (context, details) => RawAlertDialog(
///     title: 'Delete the draft?',
///     content: const Text('It cannot be brought back.'),
///     actions: [
///       RawDialogAction(
///         label: 'Cancel',
///         onPressed: () => Navigator.of(context).pop(false),
///       ),
///       RawDialogAction(
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

  /// Paints the dialog's page, which fills the screen: a [RawAlertDialog]
  /// places itself in it.
  final DesignDialogBuilder builder;

  /// Whether it is an alert, which asks for an answer: a screen reader hears
  /// an alert (`SemanticsRole.alertDialog`; the web's `alertdialog`) and a
  /// barrier tap does not close it unless [barrierDismissible] says so.
  /// Defaults to false: a dialog.
  final bool isAlert;

  /// What a screen reader calls the dialog, usually its title; null: a
  /// [RawAlertDialog]'s title names it, else
  /// [RawWidgetsLocalizations.dialogLabel] or
  /// [RawWidgetsLocalizations.alertDialogLabel].
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
  /// [RawWidgetsLocalizations.modalBarrierDismissLabel].
  @override
  String? get barrierLabel {
    final context = navigator?.context;
    return _givenBarrierLabel ??
        (context == null
            ? null
            : RawWidgetsLocalizations.of(context).modalBarrierDismissLabel);
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

// What a RawAlertDialog reads of the route round it.
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

/// An action at the foot of a [RawAlertDialog].
@immutable
class RawDialogAction {
  /// An action [label]led, that [onPressed] runs.
  const RawDialogAction({
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

/// What the look paints a [RawDialogAction] from.
@immutable
class RawDialogActionDetails {
  /// The action's details; the dialog makes them.
  const RawDialogActionDetails({
    required this.states,
    required this.stacked,
    required this.index,
    required this.count,
  });

  /// Its pressable states: focused only when the keyboard moved focus to it.
  final Set<WidgetState> states;

  /// Whether the actions are stacked, one to a line and each as wide as the
  /// dialog, because they do not fit side by side ([RawActionBar]).
  final bool stacked;

  /// Its place among the actions, 0 for the first given.
  final int index;

  /// How many actions the dialog has.
  final int count;
}

/// What the look paints a [RawAlertDialog]'s frame and action bar from.
@immutable
class RawAlertDialogFrameDetails {
  /// The layout's details; the dialog makes them.
  const RawAlertDialogFrameDetails({
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

  /// Whether the actions are stacked ([RawDialogActionDetails.stacked]).
  final bool stacked;
}

/// Paints an action of a [RawAlertDialog].
typedef RawDialogActionBuilder = Widget Function(
  BuildContext context,
  RawDialogAction action,
  RawDialogActionDetails details,
);

Widget _actionLabel(
  BuildContext context,
  RawDialogAction action,
  RawDialogActionDetails details,
) => Text(action.label);

/// Wraps a part of a [RawAlertDialog] (its frame or its action bar) in the
/// look's paint.
typedef RawAlertDialogPartBuilder = Widget Function(
  BuildContext context,
  RawAlertDialogFrameDetails details,
  Widget child,
);

/// An alert's or a simple dialog's layout: [title] and [content] scroll
/// together over [actions], which stay put. The actions sit side by side,
/// sharing the row on a compact screen and aligned at the end on a larger
/// screen. When their labels do not fit, including at a large text size,
/// they stack in one column, each as wide as the dialog, the last given (the
/// confirm) on top and the first (the dismissive one) at the bottom, as
/// Material and iOS stack them: a [RawActionBar] lays them out, which a
/// look's own dialog can use as it is.
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
/// RawAlertDialog(
///   title: 'Discard changes?',
///   content: const Text('Your edits to this note will be lost.'),
///   actions: [
///     RawDialogAction(label: 'Keep editing', onPressed: () {}),
///     RawDialogAction(label: 'Discard', isDestructiveAction: true, onPressed: () {}),
///   ],
///   actionBuilder: (context, action, details) => Text(action.label),
///   frameBuilder: (context, details, child) => DecoratedBox(
///     decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
///     child: child,
///   ),
/// )
/// ```
class RawAlertDialog extends StatefulWidget {
  /// A dialog's layout of [title], [content] and [actions].
  const RawAlertDialog({
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
  final List<RawDialogAction> actions;

  /// Complete action controls in reading order, as an alternative to
  /// [actions]. Each keeps its own semantics, focus and activation. Set
  /// autofocus on the safe action when the dialog opens.
  final List<Widget> actionWidgets;

  /// Paints an action from [actions]. Defaults to its label.
  final RawDialogActionBuilder actionBuilder;

  /// Paints the title; null: a plain `Text`.
  final Widget Function(BuildContext context, String title)? titleBuilder;

  /// Wraps the action bar (its padding, a line over it when the words
  /// overflow); null: the bar as it is.
  final RawAlertDialogPartBuilder? actionsBuilder;

  /// Wraps the whole dialog in the look's surface; null: no surface.
  final RawAlertDialogPartBuilder? frameBuilder;

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
  static int? safeActionIndex(List<RawDialogAction> actions) {
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
  State<RawAlertDialog> createState() => _DesignDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(
        ObjectFlagProperty<RawDialogActionBuilder>.has(
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
        ObjectFlagProperty<RawAlertDialogPartBuilder>.has(
          'actionsBuilder',
          actionsBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawAlertDialogPartBuilder>.has(
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
        IterableProperty<RawDialogAction>(
          'actions',
          actions,
          defaultValue: const <RawDialogAction>[],
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

class _DesignDialogState extends State<RawAlertDialog> {
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
    final words = RawWidgetsLocalizations.of(context);
    final names = !(scope?.labelled ?? false);
    final details = RawAlertDialogFrameDetails(
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
    final safe = RawAlertDialog.safeActionIndex(actions);
    Widget? bar;
    if (actions.isNotEmpty || widget.actionWidgets.isNotEmpty) {
      bar = RawActionBar(
        spacing: widget.actionSpacing,
        overflowSpacing: widget.stackedActionSpacing,
        expanded:
            DesignWindowSizeClass.of(context) == DesignWindowSizeClass.compact,
        onStackedChanged: _onStacked,
        children: [
          ...widget.actionWidgets,
          for (final (i, a) in actions.indexed)
            RawButton(
              onPressed: a.onPressed,
              autofocus: i == safe,
              semanticLabel: a.label,
              excludeSemantics: true,
              builder: (context, states, _) => widget.actionBuilder(
                context,
                a,
                RawDialogActionDetails(
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
