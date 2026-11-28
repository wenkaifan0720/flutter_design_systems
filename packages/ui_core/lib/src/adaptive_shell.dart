/// An app's frame, headless, adapting to its width: a bar of destinations
/// along the bottom of a phone, a rail at the start edge of a tablet, a
/// sidebar on a desktop (Material's window size classes), or a header
/// across the top of a wide window, the body beside, above or below it. The destinations are one tab stop, the arrows moving along
/// them; F6 moves focus between the navigation and the body. Given each
/// destination's root page ([RawAdaptiveShell.branches]), each keeps its
/// own stack, and back pops the selected one.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'internal/kept_clear.dart';
import 'internal/panes.dart';
import 'internal/roving_focus.dart';
import 'localizations.dart';
import 'motion.dart';
import 'pressable.dart';
import 'toast.dart';

/// Material's window size classes, by width in logical pixels.
enum RawWindowSizeClass {
  /// Under 600: a phone held upright.
  compact,

  /// 600 to 840: a tablet upright, a foldable open.
  medium,

  /// 840 to 1200: a tablet on its side, a small window.
  expanded,

  /// 1200 to 1600: a laptop.
  large,

  /// 1600 and wider: a desktop.
  extraLarge;

  /// The class of a window [width] wide.
  ///
  /// ```dart
  /// RawWindowSizeClass.fromWidth(900)
  /// ```
  static RawWindowSizeClass fromWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : width < 1200
      ? expanded
      : width < 1600
      ? large
      : extraLarge;

  /// The class of the window [context] is in ([MediaQuery]'s size); [context]
  /// builds again when the width changes.
  static RawWindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}

/// How a shell shows its destinations.
enum RawNavigationMode {
  /// A bar along the bottom (compact).
  bar,

  /// A rail at the start edge (medium and expanded).
  rail,

  /// A sidebar at the start edge (large and up).
  sidebar,

  /// A header across the top, the destinations in a row (a masthead's
  /// links, a menu bar's places): no window size class of its own; a look
  /// chooses it for the widths it wants it at
  /// ([RawAdaptiveShell.modeForWidth]).
  top;

  /// The mode for a shell [width] wide: a bar under [rail], a rail from
  /// [rail] and a sidebar from [sidebar]. The defaults are Material's
  /// window size classes (600 and 1200).
  ///
  /// ```dart
  /// RawNavigationMode.fromWidth(900, sidebar: 840)
  /// ```
  static RawNavigationMode fromWidth(
    double width, {
    double rail = 600,
    double sidebar = 1200,
  }) {
    assert(rail <= sidebar, 'a rail comes before a sidebar');
    return width < rail
        ? RawNavigationMode.bar
        : width < sidebar
        ? RawNavigationMode.rail
        : RawNavigationMode.sidebar;
  }

  /// Whether the destinations run in a row: a bar's or a header's, a tab
  /// bar to a screen reader.
  bool get isHorizontal => this == bar || this == top;
}

/// Picks the mode for a shell [width] wide.
typedef RawNavigationModeForWidth = RawNavigationMode Function(double width);

/// A destination: its name and glyphs, as Material's NavigationDestination.
@immutable
class RawNavigationDestination {
  /// A destination named [label].
  const RawNavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.enabled = true,
    this.data,
  });

  /// Its name, and what a screen reader calls it.
  final String label;

  /// Its glyph.
  final IconData icon;

  /// Its glyph while selected; null: [icon].
  final IconData? selectedIcon;

  /// Whether it can be chosen; a disabled destination is skipped by the
  /// arrows.
  final bool enabled;

  /// Anything else the look needs to paint it (a badge count).
  final Object? data;
}

/// What a look paints a destination from.
@immutable
class RawDestinationDetails {
  /// The state; the shell makes it.
  const RawDestinationDetails({
    required this.states,
    required this.mode,
    required this.index,
    required this.count,
  });

  /// Its pressable states; [WidgetState.selected] while it is the
  /// selected destination.
  final Set<WidgetState> states;

  /// Where it shows: a bar, a rail or a sidebar.
  final RawNavigationMode mode;

  /// Its place: 0 first.
  final int index;

  /// How many destinations there are.
  final int count;
}

/// What a look lays the navigation out from.
@immutable
class RawNavigationDetails {
  /// The state; the shell makes it.
  const RawNavigationDetails({
    required this.mode,
    required this.destinations,
    required this.selectedIndex,
    required this.visibility,
    this.pushed = false,
  });

  /// A bar, a rail or a sidebar.
  final RawNavigationMode mode;

  /// The destinations, built: each presses, takes the keys and speaks round
  /// the look's paint. A bar lays them in a row, a rail or a sidebar in a
  /// column.
  final List<Widget> destinations;

  /// The selected destination.
  final int selectedIndex;

  /// How far the bar is shown, on the shell's spring, as
  /// [RawAdaptiveShell.showNavigation] changes and as a page is pushed and
  /// popped ([RawAdaptiveShell.hideBarOnPush]): 1 shown, 0 gone. An
  /// underdamped spring runs past either; clamp it before an opacity.
  final Animation<double> visibility;

  /// Whether the selected branch has a page over its root
  /// ([RawAdaptiveShell.branches]): a page route covering the one under it,
  /// not a popup; always false over a [RawAdaptiveShell]'s own body.
  final bool pushed;

  /// [destinations], laid out by the look, as one group: in a bar or a
  /// header a screen reader hears it as the tab bar, the destinations its
  /// tabs. A tab bar holds tabs and nothing else (Flutter fails one that
  /// holds anything else), so a look whose bar or header holds more than the
  /// destinations (an action beside them, a compose button, the app's name)
  /// places this round the destinations alone, the rest outside it. Without
  /// it the shell takes the whole bar for the tab bar. In a rail or a sidebar
  /// it adds nothing.
  Widget group(Widget destinations) =>
      _DestinationGroup(bar: mode.isHorizontal, child: destinations);
}

// The navigation's node: a sidebar's named; a bar's or a header's the tab
// bar, unless the look placed a [_DestinationGroup] round its destinations
// in it.
class _NavigationNode extends SingleChildRenderObjectWidget {
  const _NavigationNode({
    required this.bar,
    required this.label,
    required super.child,
  });

  final bool bar;
  final String? label;

  @override
  _RenderNavigationNode createRenderObject(BuildContext context) =>
      _RenderNavigationNode(bar, label, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderNavigationNode renderObject,
  ) {
    renderObject
      ..bar = bar
      ..label = label
      ..textDirection = Directionality.of(context);
  }
}

class _RenderNavigationNode extends RenderProxyBox {
  _RenderNavigationNode(this._bar, this._label, this._textDirection);

  bool get bar => _bar;
  bool _bar;
  set bar(bool value) {
    if (value == _bar) return;
    _bar = value;
    markNeedsSemanticsUpdate();
  }

  String? get label => _label;
  String? _label;
  set label(String? value) {
    if (value == _label) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  // The destination groups the look placed in it.
  int _groups = 0;

  void _grouped(int by) {
    _groups += by;
    if (attached) markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..explicitChildNodes = true;
    if (label case final label?) {
      config
        ..label = label
        ..textDirection = textDirection;
    }
    if (bar && _groups == 0) config.role = SemanticsRole.tabBar;
  }
}

// [RawNavigationDetails.group]: in a bar, the tab bar round the
// destinations alone; it tells the navigation's node it is there.
class _DestinationGroup extends SingleChildRenderObjectWidget {
  const _DestinationGroup({required this.bar, required super.child});

  final bool bar;

  @override
  _RenderDestinationGroup createRenderObject(BuildContext context) =>
      _RenderDestinationGroup(bar);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderDestinationGroup renderObject,
  ) {
    renderObject.bar = bar;
  }
}

class _RenderDestinationGroup extends RenderProxyBox {
  _RenderDestinationGroup(this._bar);

  bool get bar => _bar;
  bool _bar;
  set bar(bool value) {
    if (value == _bar) return;
    _bar = value;
    markNeedsSemanticsUpdate();
  }

  _RenderNavigationNode? _node;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (var up = parent; up != null; up = up.parent) {
      if (up is _RenderNavigationNode) {
        _node = up.._grouped(1);
        break;
      }
    }
  }

  @override
  void detach() {
    _node?._grouped(-1);
    _node = null;
    super.detach();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (!bar) return;
    config
      ..isSemanticBoundary = true
      ..explicitChildNodes = true
      ..role = SemanticsRole.tabBar;
  }
}

/// Paints a destination.
typedef RawDestinationBuilder = Widget Function(
  BuildContext context,
  RawNavigationDestination destination,
  RawDestinationDetails details,
);

/// Lays out and paints the navigation round its destinations.
typedef RawNavigationBuilder = Widget Function(
  BuildContext context,
  RawNavigationDetails details,
);

/// Paints a branch of a [RawAdaptiveShell.branches] as the shell moves
/// between destinations, for a look whose design moves between them, as a
/// page route's transition does: [animation] runs
/// from 0 to 1 as the branch comes in, [secondaryAnimation] from 0 to 1 as it
/// goes out; at rest, the shown branch has 1 and 0. Each runs from where it
/// is, so a change of destination in the middle of one carries on from the
/// frame on screen. [child] is the branch.
///
/// ```dart
/// (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: FadeTransition(opacity: ReverseAnimation(secondaryAnimation), child: child))
/// ```
typedef RawBranchTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
);

/// Where back goes from a branch at its root page.
enum RawBranchBackBehavior {
  /// To the first destination, then out of the app (Material's rule).
  firstDestination,

  /// Back through the destinations chosen before, then out.
  history,

  /// Out of the app.
  none,
}

/// An app's frame: [destinations] in a bar, a rail, a sidebar or a header
/// by the shell's width ([modeForWidth], or [mode]), and the app's [body]
/// beside it (above a bar, below a header). The look paints each
/// destination ([destinationBuilder]) and the navigation round them
/// ([navigationBuilder]); the shell gives them their keys, their meaning
/// to a screen reader and their place.
///
/// The destinations are one tab stop, on the selected one; the arrows along
/// them move focus (Left and Right in a bar or a header, mirrored right to
/// left; Up and Down in a rail or a sidebar), wrapping, Home and End to the
/// ends, disabled ones skipped; Enter or Space chooses, as switching a
/// destination is heavy. F6 (Shift+F6 back) moves focus between the
/// navigation and the body, and the panes inside it ([RawListDetail]'s list
/// and detail, a shown toaster's toasts). A screen reader hears each
/// destination as a tab, selected or not, and its place ("Tab 1 of 3"); a
/// bar or a header is a tab bar (its destinations alone, when the look
/// places [RawNavigationDetails.group] round them), a sidebar is named
/// "Navigation menu". The body is a semantics node of its own, so a page
/// pushed in it covers the pages under it and never the navigation.
///
/// [body] is the app's: an `IndexedStack` of its own, or go_router's
/// `StatefulNavigationShell`. [RawAdaptiveShell.branches] keeps a stack per
/// destination itself.
///
/// A look builds its app shell (its `<Look>AppShell`) on
/// [RawAdaptiveShell.branches], and paints all of its navigation through it,
/// at every width:
///
/// * [destinationBuilder] paints one destination from its
///   [RawDestinationDetails]: its states ([WidgetState.selected] while it is
///   the selected one, hovered, pressed, focused) and the mode it shows in.
/// * [navigationBuilder] lays the built destinations out for
///   [RawNavigationDetails.mode]: a row in a bar or a header, a column in a
///   rail or a sidebar, with the look's own parts round them (the app's
///   name, an action). Beside anything else in a bar or a header, put
///   [RawNavigationDetails.group] round the destinations alone.
/// * A phone bar built outside the shell is not the shell's: it loses the
///   tab bar, the selected state and the keys. The shell paints the bar too.
/// * [modeForWidth] sets the look's widths:
///   `(width) => RawNavigationMode.fromWidth(width, sidebar: 1024)`, or a
///   header from 600 up:
///   `(width) => width < 600 ? RawNavigationMode.bar : RawNavigationMode.top`.
/// * With [hideBarOnPush] (the default) a page pushed on a branch takes the
///   bar's room as the bar springs away, and the bar comes back as it pops;
///   a rail, a sidebar or a header stays beside the page. A popup on the
///   branch (a dialog, a menu, a select's list, a date picker, a bottom
///   sheet) is no page: the bar and the page's footer stay where they are.
///   Turned off, the bar stays under pushed pages, as Cupertino's tab
///   scaffold keeps its tab bar.
/// * The bar keeps toasts above it, a header below it, and a rail or a
///   sidebar beside it, so they centre on the page ([RawToasterKeepClear]);
///   a popover prefers the side of its anchor clear of the bar.
/// * [navigatorKeys] push onto a branch from outside (a notification
///   opening a detail); a page pushed on the app's own navigator covers the
///   whole shell (a full-screen editor).
///
/// ```dart
/// RawAdaptiveShell(destinations: const [RawNavigationDestination(label: 'Home', icon: IconData(0xe318)), RawNavigationDestination(label: 'Mail', icon: IconData(0xe158))], selectedIndex: 0, onDestinationSelected: (index) {}, destinationBuilder: (context, destination, details) => Text(destination.label), navigationBuilder: (context, details) => Row(children: details.destinations), body: const Text('Home'))
/// ```
class RawAdaptiveShell extends StatefulWidget {
  /// A shell over the app's own [body].
  const RawAdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinationBuilder,
    required this.navigationBuilder,
    required Widget this.body,
    this.mode,
    this.modeForWidth,
    this.showNavigation = true,
    this.dampingRatio = 1,
    this.stiffness = 700,
  }) : branches = null,
       navigatorKeys = null,
       backBehavior = RawBranchBackBehavior.firstDestination,
       hideBarOnPush = false,
       transitionBuilder = null,
       transitionDuration = Duration.zero,
       assert(dampingRatio > 0 && stiffness > 0);

  /// A shell whose body is one [Navigator] per destination, each starting
  /// on its [branches] root page, built when first shown and kept: each
  /// keeps its own stack. Choosing the selected destination again pops it
  /// to its root. Back (Android's, Escape's route pop) pops the selected
  /// branch, then at its root goes where [backBehavior] says, then leaves.
  /// While the selected branch has a page over its root the bar steps away
  /// ([hideBarOnPush]). Tab from a branch's page reaches the navigation, a
  /// page with nothing to focus on it too, and Shift+Tab goes back to it.
  ///
  /// A change of destination switches at once, as Material's
  /// `NavigationBar` over an `IndexedStack` does; a look whose design moves
  /// between destinations gives its [transitionBuilder]. Then both are
  /// painted only while it runs, the one going out taking no pointer, focus
  /// or screen reader, its tickers stopping once it is hidden, and reduced
  /// motion switches at once. Each branch keeps its state. Focus in the
  /// branch going out moves to the one coming in (where it was in it, else
  /// its page); focus on the navigation stays there.
  ///
  /// ```dart
  /// RawAdaptiveShell.branches(destinations: const [RawNavigationDestination(label: 'Home', icon: IconData(0xe318)), RawNavigationDestination(label: 'Mail', icon: IconData(0xe158))], selectedIndex: 0, onDestinationSelected: (index) {}, destinationBuilder: (context, destination, details) => Text(destination.label), navigationBuilder: (context, details) => Row(children: details.destinations), branches: [(context) => const Text('Home'), (context) => const Text('Mail')])
  /// ```
  const RawAdaptiveShell.branches({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinationBuilder,
    required this.navigationBuilder,
    required List<WidgetBuilder> this.branches,
    this.navigatorKeys,
    this.backBehavior = RawBranchBackBehavior.firstDestination,
    this.hideBarOnPush = true,
    this.transitionBuilder,
    this.transitionDuration = const Duration(milliseconds: 250),
    this.mode,
    this.modeForWidth,
    this.showNavigation = true,
    this.dampingRatio = 1,
    this.stiffness = 700,
  }) : body = null,
       assert(dampingRatio > 0 && stiffness > 0);

  /// The destinations.
  final List<RawNavigationDestination> destinations;

  /// The selected destination.
  final int selectedIndex;

  /// Called with a destination chosen (the selected one again included);
  /// null disables them all.
  final ValueChanged<int>? onDestinationSelected;

  /// Paints a destination.
  final RawDestinationBuilder destinationBuilder;

  /// Lays out and paints the navigation round its destinations.
  final RawNavigationBuilder navigationBuilder;

  /// The app's body; null with [branches].
  final Widget? body;

  /// Each destination's root page; null with [body].
  final List<WidgetBuilder>? branches;

  /// The branches' navigators' keys, to push onto a branch from outside;
  /// null: the shell's own.
  final List<GlobalKey<NavigatorState>>? navigatorKeys;

  /// Where back goes from a branch at its root page.
  final RawBranchBackBehavior backBehavior;

  /// Whether the bar steps away while the selected branch has a page over
  /// its root ([RawAdaptiveShell.branches]; a rail, a sidebar or a header
  /// stays): a page route that covers the one under it. A popup route (a
  /// dialog, a menu, a select's list, a bottom sheet) leaves the bar. False
  /// keeps the bar under pushed pages, as Cupertino's tab scaffold does.
  /// Always false over the app's own [body], which says so through
  /// [showNavigation].
  final bool hideBarOnPush;

  /// Paints the branches as the destination changes, for a look whose
  /// design moves between destinations ([RawAdaptiveShell.branches]); null
  /// switches at once.
  final RawBranchTransitionBuilder? transitionBuilder;

  /// How long a [transitionBuilder]'s change of destination takes;
  /// [Duration.zero] switches at once, as reduced motion does.
  final Duration transitionDuration;

  /// How the destinations show at every width; null: by the shell's width
  /// ([modeForWidth]).
  final RawNavigationMode? mode;

  /// The mode for the shell's width, from its own constraints (the window's
  /// width when they are unbounded); null: [RawNavigationMode.fromWidth],
  /// Material's window size classes.
  ///
  /// ```dart
  /// RawAdaptiveShell(modeForWidth: (width) => width < 600 ? RawNavigationMode.bar : RawNavigationMode.top, destinations: const [RawNavigationDestination(label: 'Home', icon: IconData(0xe318)), RawNavigationDestination(label: 'Mail', icon: IconData(0xe158))], selectedIndex: 0, onDestinationSelected: (index) {}, destinationBuilder: (context, destination, details) => Text(destination.label), navigationBuilder: (context, details) => Row(children: details.destinations), body: const Text('Home'))
  /// ```
  final RawNavigationModeForWidth? modeForWidth;

  /// Whether the bar shows: false while a page of the app's own is over a
  /// root, and the bar springs away (a rail, a sidebar or a header stays).
  final bool showNavigation;

  /// The bar's spring damping ratio (ζ). Defaults to 1.
  final double dampingRatio;

  /// The bar's spring stiffness (k). Defaults to 700.
  final double stiffness;

  @override
  State<RawAdaptiveShell> createState() => _RawAdaptiveShellState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        IterableProperty<String>('destinations', [
          for (final d in destinations) d.label,
        ]),
      )
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(
        ObjectFlagProperty<RawDestinationBuilder>.has(
          'destinationBuilder',
          destinationBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawNavigationBuilder>.has(
          'navigationBuilder',
          navigationBuilder,
        ),
      )
      ..add(IntProperty('branches', branches?.length, defaultValue: null))
      ..add(
        IterableProperty<GlobalKey<NavigatorState>>(
          'navigatorKeys',
          navigatorKeys,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<RawBranchBackBehavior>(
          'backBehavior',
          backBehavior,
          defaultValue: RawBranchBackBehavior.firstDestination,
        ),
      )
      ..add(
        FlagProperty(
          'hideBarOnPush',
          value: hideBarOnPush,
          ifTrue: 'bar hidden on push',
        ),
      )
      ..add(
        ObjectFlagProperty<RawBranchTransitionBuilder>.has(
          'transitionBuilder',
          transitionBuilder,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'transitionDuration',
          transitionDuration,
          defaultValue: Duration.zero,
        ),
      )
      ..add(EnumProperty<RawNavigationMode>('mode', mode, defaultValue: null))
      ..add(
        ObjectFlagProperty<RawNavigationModeForWidth>.has(
          'modeForWidth',
          modeForWidth,
        ),
      )
      ..add(
        FlagProperty(
          'showNavigation',
          value: showNavigation,
          ifFalse: 'navigation hidden',
          defaultValue: true,
        ),
      )
      ..add(DoubleProperty('dampingRatio', dampingRatio, defaultValue: 1))
      ..add(DoubleProperty('stiffness', stiffness, defaultValue: 700));
  }
}

class _RawAdaptiveShellState extends State<RawAdaptiveShell>
    with TickerProviderStateMixin {
  final RovingFocus _focus = RovingFocus('RawAdaptiveShell');

  // The body keeps its state as the mode changes and the frame with it.
  final GlobalKey _body = GlobalKey(debugLabel: 'RawAdaptiveShell body');
  _BranchTraversalPolicy? _traversal;
  FocusTraversalPolicy? _fallbackTraversal;
  late final AnimationController _visibility = AnimationController.unbounded(
    vsync: this,
    value: widget.showNavigation ? 1 : 0,
  );
  // Where the bar's spring is going: shown or not.
  late bool _barShown = widget.showNavigation;

  // The branches built so far, their own navigators' keys, whether each can
  // go back (a page or a popup over its root: Back closes it), and whether
  // each has a page over its root (which takes the bar away; a popup does
  // not).
  final Set<int> _built = {};
  final List<GlobalKey<NavigatorState>> _keys = [];
  final Map<int, bool> _deep = {};
  final Map<int, bool> _paged = {};
  final Map<int, _BranchPages> _pages = {};

  // Each built branch's coming in and going out, and the branches going
  // out now (painted until they are hidden).
  final Map<int, AnimationController> _in = {};
  final Map<int, AnimationController> _out = {};
  final Set<int> _leaving = {};

  // Where the focus was in each branch it left, to come back to.
  final Map<int, WeakReference<FocusNode>> _lastFocus = {};

  AnimationController _inOf(int i) => _in[i] ??= AnimationController(
    vsync: this,
    duration: widget.transitionDuration,
  );

  AnimationController _outOf(int i) => _out[i] ??=
      AnimationController(vsync: this, duration: widget.transitionDuration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _hide(i);
        });

  // A branch gone out is hidden, ready to come in again from the start.
  void _hide(int i) {
    if (!mounted || i == widget.selectedIndex) return;
    _in[i]?.value = 0;
    _out[i]?.value = 0;
    setState(() => _leaving.remove(i));
  }

  // The selected branch changed from [from] to [to].
  void _switchBranch(int from, int to) {
    // Focus in the branch going out goes to the one coming in.
    final focusWasIn =
        _built.contains(from) &&
        (_navigatorKey(from).currentState?.focusNode.hasFocus ?? false);
    final primary = FocusManager.instance.primaryFocus;
    if (focusWasIn && primary != null) {
      _lastFocus[from] = WeakReference(primary);
    }
    // Focus outside the branches (on a destination) stays there, though a
    // branch shown for the first time pushes its first page, which asks for
    // the focus.
    final stay =
        primary != null &&
            primary is! FocusScopeNode &&
            !_built.any(
              (i) => _navigatorKey(i).currentState?.focusNode.hasFocus ?? false,
            )
        ? primary
        : null;
    final instant =
        widget.transitionBuilder == null ||
        widget.transitionDuration == Duration.zero ||
        rawReduceMotionOf(context);
    if (instant) {
      _leaving
        ..remove(from)
        ..remove(to);
      _in[from]?.value = 0;
      _out[from]?.value = 0;
      _out[to]?.value = 0;
      _in[to]?.value = 1;
    } else {
      _leaving
        ..add(from)
        ..remove(to);
      _outOf(from).forward();
      _outOf(to).reverse();
      _inOf(to).forward();
    }
    if (stay != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && stay.context != null && stay.canRequestFocus) {
          stay.requestFocus();
        }
      });
    }
    if (focusWasIn) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.selectedIndex != to) return;
        final branch = _navigatorKey(to).currentState?.focusNode;
        if (branch == null) return;
        final last = _lastFocus[to]?.target;
        if (last != null &&
            last.canRequestFocus &&
            last.ancestors.contains(branch)) {
          last.requestFocus();
        } else {
          branch.requestFocus();
        }
      });
    }
  }

  // The destinations chosen before ([RawBranchBackBehavior.history]).
  final List<int> _history = [];
  bool _goingBack = false;

  // Whether the selected branch has a page over its root: a page route
  // covering the one under it, not a popup (a dialog, a menu, a select's
  // list, a bottom sheet), which a branch's own navigator holds too.
  bool get _pushed =>
      widget.branches != null && (_paged[widget.selectedIndex] ?? false);

  // Springs the bar in or away as [RawAdaptiveShell.showNavigation] and a
  // page pushed on the selected branch say.
  void _syncBar() {
    final shown = widget.showNavigation && !(widget.hideBarOnPush && _pushed);
    if (shown == _barShown) return;
    _barShown = shown;
    _visibility.animateWith(
      rawSpringSimulation(
        RawMotionPolicy.of(context).spatial(
          dampingRatio: widget.dampingRatio,
          stiffness: widget.stiffness,
        ),
        from: _visibility.value,
        to: shown ? 1 : 0,
        velocity: _visibility.velocity,
      ),
    );
  }

  @override
  void didUpdateWidget(RawAdaptiveShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBar();
    if (oldWidget.transitionDuration != widget.transitionDuration) {
      for (final c in [..._in.values, ..._out.values]) {
        c.duration = widget.transitionDuration;
      }
    }
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      if (widget.branches != null) {
        _switchBranch(oldWidget.selectedIndex, widget.selectedIndex);
      }
      if (!_goingBack && widget.backBehavior == RawBranchBackBehavior.history) {
        _history
          ..remove(oldWidget.selectedIndex)
          ..add(oldWidget.selectedIndex);
      }
    }
    _goingBack = false;
  }

  @override
  void dispose() {
    for (final c in [..._in.values, ..._out.values]) {
      c.dispose();
    }
    _focus.dispose();
    _visibility.dispose();
    super.dispose();
  }

  GlobalKey<NavigatorState> _navigatorKey(int i) {
    final given = widget.navigatorKeys;
    if (given != null) return given[i];
    while (_keys.length <= i) {
      _keys.add(
        GlobalKey<NavigatorState>(debugLabel: 'branch ${_keys.length}'),
      );
    }
    return _keys[i];
  }

  bool _enabled(int i) =>
      widget.onDestinationSelected != null && widget.destinations[i].enabled;

  void _choose(int i) {
    if (i == widget.selectedIndex && widget.branches != null) {
      _navigatorKey(i).currentState?.popUntil((route) => route.isFirst);
    }
    widget.onDestinationSelected?.call(i);
  }

  // The tab stop: the selected destination, else the first enabled.
  int? _stop() {
    final n = widget.destinations.length;
    final selected = widget.selectedIndex;
    if (selected >= 0 && selected < n && _enabled(selected)) return selected;
    for (var i = 0; i < n; i++) {
      if (_enabled(i)) return i;
    }
    return null;
  }

  KeyEventResult _key(int i, KeyEvent event, RawNavigationMode mode) {
    final to = RovingFocus.target(
      event,
      from: i,
      count: widget.destinations.length,
      axis: mode.isHorizontal ? Axis.horizontal : Axis.vertical,
      textDirection: Directionality.of(context),
      enabled: _enabled,
    );
    if (to == null) return KeyEventResult.ignored;
    _focus[to].requestFocus();
    return KeyEventResult.handled;
  }

  // Back goes somewhere inside the shell: a page off the selected branch,
  // or another destination.
  bool get _takesBack {
    if (widget.branches == null || widget.onDestinationSelected == null) {
      return false;
    }
    if (_deep[widget.selectedIndex] ?? false) return true;
    return switch (widget.backBehavior) {
      RawBranchBackBehavior.firstDestination => widget.selectedIndex != 0,
      RawBranchBackBehavior.history => _history.isNotEmpty,
      RawBranchBackBehavior.none => false,
    };
  }

  void _back() {
    final selected = widget.selectedIndex;
    if (_deep[selected] ?? false) {
      _navigatorKey(selected).currentState?.maybePop();
      return;
    }
    switch (widget.backBehavior) {
      case RawBranchBackBehavior.firstDestination:
        if (selected != 0) widget.onDestinationSelected?.call(0);
      case RawBranchBackBehavior.history:
        if (_history.isEmpty) return;
        _goingBack = true;
        widget.onDestinationSelected?.call(_history.removeLast());
      case RawBranchBackBehavior.none:
        break;
    }
  }

  void _branchDepth(int i, bool deep) {
    if ((_deep[i] ?? false) == deep) return;
    _afterBuild(() => setState(() => _deep[i] = deep));
  }

  void _branchPaged(int i, bool paged) {
    if ((_paged[i] ?? false) == paged) return;
    _afterBuild(() {
      setState(() => _paged[i] = paged);
      _syncBar();
    });
  }

  // A navigator says so as it builds: the shell hears after the frame.
  void _afterBuild(VoidCallback change) {
    void run() {
      if (mounted) change();
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => run());
    } else {
      run();
    }
  }

  Widget _branches(List<WidgetBuilder> branches) {
    final selected = widget.selectedIndex;
    _built.add(selected);
    final around =
        FocusTraversalGroup.maybeOf(context) ??
        (_fallbackTraversal ??= ReadingOrderTraversalPolicy());
    if (!identical(_traversal?.around, around)) {
      _traversal = _BranchTraversalPolicy(around);
    }
    return PopScope<Object?>(
      canPop: !_takesBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: FocusTraversalGroup(
        policy: _traversal,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The selected branch over those going out.
            for (final i in [
              for (var i = 0; i < branches.length; i++)
                if (_built.contains(i) && i != selected) i,
              selected,
            ])
              KeyedSubtree(key: ValueKey(i), child: _branch(i, selected)),
          ],
        ),
      ),
    );
  }

  // Branch [i]: painted while it is the [selected] one or going out, only
  // the selected one taking pointers, focus and a screen reader.
  Widget _branch(int i, int selected) {
    final shown = i == selected;
    final painted = shown || _leaving.contains(i);
    Widget branch = NotificationListener<NavigationNotification>(
      onNotification: (notification) {
        _branchDepth(i, notification.canHandlePop);
        return true;
      },
      child: Navigator(
        key: _navigatorKey(i),
        observers: [
          _pages[i] ??= _BranchPages((paged) => _branchPaged(i, paged)),
        ],
        onGenerateInitialRoutes: (navigator, name) => [
          PageRouteBuilder<void>(
            settings: RouteSettings(name: name),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (context, _, _) => widget.branches![i](context),
          ),
        ],
      ),
    );
    final transition = widget.transitionBuilder;
    if (transition != null) {
      // A branch first drawn at rest is in; one a change brings in starts
      // from nothing (made then, in [_switchBranch]).
      final comingIn = _in[i] ??= AnimationController(
        vsync: this,
        duration: widget.transitionDuration,
        value: shown ? 1 : 0,
      );
      branch = transition(context, comingIn, _outOf(i), branch);
    }
    return Offstage(
      offstage: !painted,
      child: TickerMode(
        enabled: painted,
        child: ExcludeFocus(
          excluding: !shown,
          child: ExcludeSemantics(
            excluding: !shown,
            child: IgnorePointer(ignoring: !shown, child: branch),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.branches == null ||
          widget.branches!.length == widget.destinations.length,
      'one branch per destination',
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final modeFor = widget.modeForWidth ?? RawNavigationMode.fromWidth;
        return _build(context, widget.mode ?? modeFor(width));
      },
    );
  }

  Widget _build(BuildContext context, RawNavigationMode mode) {
    final n = widget.destinations.length;
    _focus
      ..sync(n)
      ..stopAt(_stop());
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final destinations = [
      for (var i = 0; i < n; i++)
        RawButton(
          focusNode: _focus[i],
          onPressed: _enabled(i) ? () => _choose(i) : null,
          onKeyEvent: (node, event) => _key(i, event, mode),
          selected: i == widget.selectedIndex,
          tab: true,
          builder: (context, states, _) => Semantics(
            label:
                '${widget.destinations[i].label}\n'
                '${words.tabLabel(tabIndex: i + 1, tabCount: n)}',
            child: ExcludeSemantics(
              child: widget.destinationBuilder(
                context,
                widget.destinations[i],
                RawDestinationDetails(
                  states: states,
                  mode: mode,
                  index: i,
                  count: n,
                ),
              ),
            ),
          ),
        ),
    ];
    final bar = mode == RawNavigationMode.bar;
    final top = mode == RawNavigationMode.top;
    final side = !mode.isHorizontal;
    final hidden = bar && !_barShown;
    Widget navigation = widget.navigationBuilder(
      context,
      RawNavigationDetails(
        mode: mode,
        destinations: destinations,
        selectedIndex: widget.selectedIndex,
        visibility: _visibility.view,
        pushed: _pushed,
      ),
    );
    // A bar or a header is a tab bar (or its destinations are, the look's
    // group round them); a sidebar is the navigation menu.
    navigation = _NavigationNode(
      bar: mode.isHorizontal,
      label: mode == RawNavigationMode.sidebar ? words.drawerLabel : null,
      child: navigation,
    );
    navigation = Pane(
      debugLabel: 'RawAdaptiveShell navigation',
      child: ExcludeFocus(
        excluding: hidden,
        child: ExcludeSemantics(
          excluding: hidden,
          child: IgnorePointer(ignoring: hidden, child: navigation),
        ),
      ),
    );
    // A bar keeps the toasts above it, as Material's Scaffold keeps a
    // snackbar above its bottomNavigationBar; a header keeps them below it;
    // a rail or a sidebar beside it, whatever stands above or below it, so
    // they centre on the body. The bar is the one part a sheet opened over
    // the shell stands on; a page's foot kept clear on it is covered.
    navigation = KeptNavigationBar(
      child: RawToasterKeepClear(
        edge: switch (mode) {
          RawNavigationMode.bar => null,
          RawNavigationMode.top => RawKeepClearEdge.top,
          RawNavigationMode.rail ||
          RawNavigationMode.sidebar => RawKeepClearEdge.start,
        },
        child: navigation,
      ),
    );
    final branches = widget.branches;
    Widget body = branches == null ? widget.body! : _branches(branches);
    // A node of its own: a route pushed in the body blocks the nodes painted
    // before it in its container (the pages under it), and the navigation,
    // painted before it beside it or above it, is in another.
    body = Semantics(container: true, explicitChildNodes: true, child: body);
    body = Pane(
      key: _body,
      debugLabel: 'RawAdaptiveShell body',
      child: MediaQuery.removePadding(
        context: context,
        // The navigation takes the safe inset on its side.
        removeBottom: bar && _barShown,
        removeTop: top,
        removeLeft: side && !rtl,
        removeRight: side && rtl,
        child: body,
      ),
    );
    final Widget frame = switch (mode) {
      RawNavigationMode.bar => CustomMultiChildLayout(
        delegate: _BarLayout(_visibility),
        children: [
          LayoutId(id: _BarSlot.body, child: body),
          LayoutId(id: _BarSlot.bar, child: navigation),
        ],
      ),
      RawNavigationMode.top => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          navigation,
          Expanded(child: body),
        ],
      ),
      RawNavigationMode.rail || RawNavigationMode.sidebar => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          navigation,
          Expanded(child: body),
        ],
      ),
    };
    return PaneCycle(child: frame);
  }
}

enum _BarSlot { body, bar }

// The body above the bar, the bar along the bottom at its own height; as
// the bar springs away the body grows into its room.
class _BarLayout extends MultiChildLayoutDelegate {
  _BarLayout(this.visibility) : super(relayout: visibility);

  final Animation<double> visibility;

  @override
  void performLayout(Size size) {
    final bar = layoutChild(
      _BarSlot.bar,
      BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: size.height,
      ),
    );
    final shown = visibility.value;
    final room = bar.height * shown.clamp(0.0, 1.0);
    layoutChild(
      _BarSlot.body,
      BoxConstraints.tight(Size(size.width, size.height - room)),
    );
    positionChild(_BarSlot.body, Offset.zero);
    positionChild(_BarSlot.bar, Offset(0, size.height - bar.height * shown));
  }

  @override
  bool shouldRelayout(_BarLayout oldDelegate) =>
      visibility != oldDelegate.visibility;
}

// The branches' traversal, the policy round the shell's otherwise: a page
// with nothing to focus on it is no stop, and keys move on from it.
//
// Each branch's navigator focuses its page's scope, as a route does when it
// is pushed. A scope holding nothing to focus is its own first focus, so Tab
// there found nothing to move to; from it, traversal goes on from where the
// page stands in the scope round it, to the navigation, as from a page that
// holds a field.
class _BranchTraversalPolicy extends FocusTraversalPolicy {
  _BranchTraversalPolicy(this.around)
    : super(requestFocusCallback: around.requestFocusCallback);

  final FocusTraversalPolicy around;

  // A page's scope with nothing to focus in it.
  static bool _empty(FocusNode node) =>
      node is FocusScopeNode && node.traversalDescendants.isEmpty;

  // The scope round an empty page focused, else [node].
  static FocusNode _from(FocusNode node) {
    final outer = node.enclosingScope;
    return _empty(node) && outer != null && outer.focusedChild == node
        ? outer
        : node;
  }

  @override
  bool next(FocusNode currentNode) => around.next(_from(currentNode));

  @override
  bool previous(FocusNode currentNode) => around.previous(_from(currentNode));

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) =>
      around.inDirection(currentNode, direction);

  @override
  FocusNode? findFirstFocus(
    FocusNode currentNode, {
    bool ignoreCurrentFocus = false,
  }) => around.findFirstFocus(
    currentNode,
    ignoreCurrentFocus: ignoreCurrentFocus,
  );

  @override
  FocusNode findLastFocus(
    FocusNode currentNode, {
    bool ignoreCurrentFocus = false,
  }) =>
      around.findLastFocus(currentNode, ignoreCurrentFocus: ignoreCurrentFocus);

  @override
  FocusNode? findFirstFocusInDirection(
    FocusNode currentNode,
    TraversalDirection direction,
  ) => around.findFirstFocusInDirection(currentNode, direction);

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) => around.sortDescendants([
    for (final d in descendants)
      if (identical(d, currentNode) || !_empty(d)) d,
  ], currentNode);

  @override
  void invalidateScopeData(FocusScopeNode node) {
    super.invalidateScopeData(node);
    around.invalidateScopeData(node);
  }

  @override
  void changedScope({FocusNode? node, FocusScopeNode? oldScope}) {
    super.changedScope(node: node, oldScope: oldScope);
    around.changedScope(node: node, oldScope: oldScope);
  }
}

// The routes a branch's navigator holds, for whether a page stands over its
// root: a page route covering the one under it ([PageRoute.opaque]). A popup
// (a dialog, a menu, a select's list, a date picker, a bottom sheet) or a
// page that shows the one under it is no page: the bar stays under it.
class _BranchPages extends NavigatorObserver {
  _BranchPages(this.onChanged);

  final void Function(bool paged) onChanged;
  final List<Route<dynamic>> _routes = [];

  static bool _isPage(Route<dynamic> route) =>
      route is PageRoute && route.opaque;

  void _changed() => onChanged(_routes.where(_isPage).length > 1);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final at = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (newRoute == null) {
      if (at >= 0) _routes.removeAt(at);
    } else if (at >= 0) {
      _routes[at] = newRoute;
    } else {
      _routes.add(newRoute);
    }
    _changed();
  }
}
