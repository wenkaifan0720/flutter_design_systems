/// The shell's scaffold without a router: Expressive's navigation for an
/// app that keeps its own branches — the flexible navigation bar along the
/// bottom edge on a phone (narrower than 600dp), the accessory docked on it
/// and the floating action button 16dp above them at the end (Compose
/// `Scaffold`'s FAB placement); from 600dp the navigation rail along the
/// leading edge instead, the floating action button in the rail's header
/// (Material's adaptive navigation), the accessory docked at the bottom of
/// the content; from 1200dp the rail stands expanded, its labels beside
/// the icons.
///
/// On a media tab (its `NavTab.ground` is `ChromeGround.media`) the bar,
/// the button and the accessory (or the rail) are drawn in the host's dark
/// theme ([ExpressiveMediaGround]), and the body ends at the bar's top.
///
/// `ExpressiveShell` is this under a go_router `StatefulShellRoute` (the
/// host app's template); an app on a plain `Navigator` stands its branches in
/// [body] itself (an `IndexedStack` of navigators, one per tab), says which
/// is [selectedIndex], and hides the bar with [barVisible] while a page is
/// pushed over a branch root.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../motion.dart';
import 'shell_action.dart';
import 'host.dart';
import 'nav.dart';
import 'shell_insets.dart';

/// The scaffold that owns an app's navigation: [body] (the branches), and
/// one labelled item per [tabs] entry, in branch order, with the [action]
/// and the [accessory].
///
/// The bar stands while [barVisible] (it slides away on a spatial spring,
/// the accessory and the action with it), a tab is chosen through
/// [onDestinationSelected], and every branch root reserves the band the bar
/// stands in through `ShellInsets` — measured, so a taller label (a larger
/// text scale) or accessory is reserved too.
///
/// ```dart
/// ExpressiveShellScaffold(tabs: tabs, selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), body: IndexedStack(index: tab, children: branches))
/// ```
class ExpressiveShellScaffold extends StatefulWidget {
  /// A shell standing [body] under the navigation for [tabs].
  const ExpressiveShellScaffold({
    required this.tabs,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.barVisible = true,
    this.action,
    this.accessory,
    super.key,
  });

  /// One per branch, in branch order.
  final List<NavTab> tabs;

  /// The branch on show.
  final int selectedIndex;

  /// Told the branch a tap on the bar or the rail chose.
  final ValueChanged<int> onDestinationSelected;

  /// The branches: every one kept, the selected one on show.
  final Widget body;

  /// Whether the bar (with the action and the accessory) stands: false
  /// while a page is pushed over a branch root.
  final bool barVisible;

  /// The app-level act reachable from every root: a floating action button.
  final ShellAction? action;

  /// What docks above the bar and yields with it.
  final Widget? accessory;

  @override
  State<ExpressiveShellScaffold> createState() =>
      _ExpressiveShellScaffoldState();
}

class _ExpressiveShellScaffoldState extends State<ExpressiveShellScaffold> {
  /// The measured height of the phone's bottom band (the action and its
  /// gap, the accessory, the bar and the inset under it); null until laid
  /// out.
  double? _band;

  /// The measured height of the rail layout's docked accessory.
  double? _accessory;

  /// The measured height of the phone's navigation bar itself (with the
  /// inset under it): where a media root's body ends.
  double? _bar;

  void _measuredBar(double height) {
    if (height != _bar) setState(() => _bar = height);
  }

  /// Whether a collapsing extended action shows its label: false while
  /// the branch scrolls down, true again when it scrolls up or reaches its
  /// top, and on every change of tab.
  bool _labelShown = true;

  /// Whether the bar (and the action with it) stands, as the last build
  /// saw it: a page pushed over a branch root yields it, and that page's
  /// scrolling is not the root's.
  bool _barShown = true;

  /// The action as the shell draws it: a collapsing extended action with
  /// its label shown or not.
  Widget _action(ShellAction action) => ExpressiveShellAction(
    action: action,
    labelShown: _labelShown || !_collapses,
  );

  bool get _collapses => switch (widget.action) {
    final ExpressiveShellAction action => action.collapseOnScroll,
    _ => false,
  };

  bool _onScroll(ScrollUpdateNotification n) {
    // Only a branch root's own scrollable: not a page pushed over it, and
    // not a scrollable nested inside the root's.
    if (!_collapses ||
        !_barShown ||
        n.depth != 0 ||
        n.metrics.axis != Axis.vertical) {
      return false;
    }
    final delta = n.scrollDelta ?? 0;
    final shown = n.metrics.pixels <= n.metrics.minScrollExtent
        ? true
        : delta > 0
        ? false
        : delta < 0
        ? true
        : _labelShown;
    if (shown != _labelShown) setState(() => _labelShown = shown);
    return false;
  }

  /// [branches] listened to for the action's collapse (always wrapped, so
  /// an action that starts or stops collapsing never remounts a branch).
  Widget _followed(Widget branches) =>
      NotificationListener<ScrollUpdateNotification>(
        onNotification: _onScroll,
        child: branches,
      );

  @override
  void didUpdateWidget(ExpressiveShellScaffold old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && !_labelShown) {
      _labelShown = true;
    }
  }

  void _measuredBand(double height) {
    if (height != _band) setState(() => _band = height);
  }

  void _measuredAccessory(double height) {
    if (height != _accessory) setState(() => _accessory = height);
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.barVisible;
    if (visible != _barShown) {
      // Back at a root from a pushed page: the action returns extended.
      if (visible) _labelShown = true;
      _barShown = visible;
    }
    final destinations = <ExpressiveNavItem>[
      for (final tab in widget.tabs) ExpressiveNavItem.fromTab(tab),
    ];
    final select = widget.onDestinationSelected;
    final rail =
        MediaQuery.sizeOf(context).width >=
        ExpressiveChromeMetrics.railMinWindowWidth;
    final index = widget.selectedIndex;
    final media =
        index < widget.tabs.length &&
        widget.tabs[index].ground == ChromeGround.media;
    return rail
        ? _railLayout(context, destinations, select, visible, media)
        : _barLayout(context, destinations, select, visible, media);
  }

  Widget _barLayout(
    BuildContext context,
    List<ExpressiveNavItem> destinations,
    ValueChanged<int> select,
    bool visible,
    bool media,
  ) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final action = widget.action;
    final accessory = widget.accessory;
    final band =
        _band ??
        ExpressiveShellInsets.allowance(
          systemInset: inset,
          action: action != null,
        );
    // On media the body ends at the bar's top; what rides above the bar
    // (the button, the accessory) still stands over it.
    final grounded = media && visible;
    final bar = _bar ?? ExpressiveChromeMetrics.navBarHeight + inset;
    final allowance = grounded ? math.max(0.0, band - bar) : band;
    final Widget stack = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (action != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                end: ExpressiveChromeMetrics.fabMargin,
                bottom: ExpressiveChromeMetrics.fabMargin,
              ),
              child: _action(action),
            ),
          ),
        ?accessory,
        _ReportHeight(
          onHeight: _measuredBar,
          child: ExpressiveNavigationBar(
            destinations: destinations,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: select,
          ),
        ),
      ],
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: grounded ? bar : 0,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: grounded,
            child: ShellInsets(
              bottomInset: allowance,
              child: _followed(widget.body),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Yield(
            visible: visible,
            child: _ReportHeight(
              onHeight: _measuredBand,
              child: _grounded(media, stack),
            ),
          ),
        ),
      ],
    );
  }

  Widget _railLayout(
    BuildContext context,
    List<ExpressiveNavItem> destinations,
    ValueChanged<int> select,
    bool visible,
    bool media,
  ) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final action = widget.action;
    final accessory = widget.accessory;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final measured = _accessory;
    final allowance = accessory == null ? 0.0 : (measured ?? 0) + inset;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _grounded(
          media,
          ExpressiveNavigationRail(
            destinations: destinations,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: select,
            expanded:
                MediaQuery.sizeOf(context).width >=
                ExpressiveChromeMetrics.expandedRailMinWindowWidth,
            header: action == null
                ? null
                : SizedBox(
                    width: ExpressiveChromeMetrics.railWidth,
                    child: Center(child: _action(action)),
                  ),
          ),
        ),
        Expanded(
          // The rail took the leading system inset.
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: ltr,
            removeRight: !ltr,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ShellInsets(
                  bottomInset: allowance,
                  child: _followed(widget.body),
                ),
                if (accessory != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _Yield(
                      visible: visible,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: inset),
                        child: _ReportHeight(
                          onHeight: _measuredAccessory,
                          child: _grounded(media, accessory),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// [child] on a media ground when [media], else as it is.
Widget _grounded(bool media, Widget child) =>
    media ? ExpressiveMediaGround(child: child) : child;

/// Slides [child] off the bottom edge while not [visible], on the default
/// spatial spring, and back; while it is leaving or gone it takes no
/// pointers, and once gone it is off stage.
class _Yield extends StatelessWidget {
  const _Yield({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => ExpressiveSpringValue(
    value: visible ? 1 : 0,
    motion: ExpressiveMotionKey.defaultSpatial,
    child: child,
    builder: (context, shown, child) => Offstage(
      offstage: !visible && shown <= 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: FractionalTranslation(
          translation: Offset(0, 1 - shown),
          child: child,
        ),
      ),
    ),
  );
}

/// Reports its child's laid-out height to [onHeight] after the frame that
/// changed it (the shell's measured allowance).
class _ReportHeight extends SingleChildRenderObjectWidget {
  const _ReportHeight({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReportHeight renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderReportHeight extends RenderProxyBox {
  _RenderReportHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(height);
    });
  }
}
