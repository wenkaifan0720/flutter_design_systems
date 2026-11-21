/// Tabs, headless: a controller, a bar of tabs and the pages they show, as
/// Material's TabController, TabBar and TabBarView on the widgets layer. The
/// bar is one tab stop, the arrows moving along it (a tab chosen as focus
/// reaches it, or with Enter and Space); swiping the pages moves the bar's
/// indicator with the finger, and pages, indicator and a scrolling strip
/// settle on a spring. A screen reader hears a tab bar of tabs, each
/// selected or not and its place ("Tab 1 of 3"), each tab controlling its
/// page.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'motion.dart';
import 'pressable.dart';
import 'internal/roving_group.dart';
import 'tap_target.dart';

/// Which tab is selected, and where a swipe or a change has got to: Material's
/// `TabController` without Material. A [RawTabBar] and a [RawTabBarView]
/// given the same one follow each other. The caller makes it, with a
/// [TickerProvider] ([TickerProviderStateMixin]), and disposes it.
///
/// ```dart
/// RawTabController(length: 2, vsync: vsync)
/// ```
class RawTabController extends ChangeNotifier {
  /// [length] tabs, [initialIndex] selected; a change runs on the spring
  /// [dampingRatio] and [stiffness].
  RawTabController({
    required this.length,
    int initialIndex = 0,
    required TickerProvider vsync,
    this.dampingRatio = 1,
    this.stiffness = 700,
  }) : assert(length >= 0),
       assert(initialIndex >= 0 && (length == 0 || initialIndex < length)),
       assert(dampingRatio > 0 && stiffness > 0),
       _index = initialIndex,
       _previousIndex = initialIndex,
       _animation = AnimationController.unbounded(
         value: initialIndex.toDouble(),
         vsync: vsync,
       );

  /// How many tabs there are.
  final int length;

  /// The change's spring damping ratio (ζ). Defaults to 1.
  final double dampingRatio;

  /// The change's spring stiffness (k). Defaults to 700.
  final double stiffness;

  final AnimationController _animation;
  int _index;
  int _previousIndex;
  int _changing = 0;

  // Told by a bar or a view: under Reduce Motion a change runs critically
  // damped.
  bool _reduceMotion = false;

  /// The selected tab. Set, it jumps there; [animateTo] springs.
  int get index => _index;
  set index(int value) => _change(value, animate: false);

  /// The tab selected before [index].
  int get previousIndex => _previousIndex;

  /// Whether [animateTo]'s spring is running.
  bool get indexIsChanging => _changing != 0;

  /// Where the selection stands: [index] at rest, between two tabs while
  /// the pages are swiped or a change runs (1.4: 40% of the way from the
  /// second tab to the third). An underdamped spring runs past its tab.
  Animation<double> get animation => _animation.view;

  /// How far a swipe has moved the pages from [index]: -1 to 1.
  double get offset => _animation.value - _index;

  // A swipe of the pages: the animation moves, the index stays.
  set _offset(double value) {
    if (value == offset) return;
    _animation.value = _index + value;
  }

  /// Selects [value] on the spring, from wherever the selection stands and
  /// at its speed.
  void animateTo(int value) => _change(value, animate: true);

  // A finger takes the pages: the spring stops where it is.
  void _stop() => _animation.stop();

  void _change(int value, {required bool animate}) {
    assert(value >= 0 && (value < length || length == 0));
    if (value == _index || length < 2) return;
    _previousIndex = _index;
    _index = value;
    if (!animate) {
      _changing++;
      _animation.value = value.toDouble();
      _changing--;
      notifyListeners();
      return;
    }
    _changing++;
    notifyListeners();
    _animation
        .animateWith(
          designSpringSimulation(
            DesignMotionPolicy(reduceMotion: _reduceMotion)
                .spatial(dampingRatio: dampingRatio, stiffness: stiffness),
            from: _animation.value,
            to: value.toDouble(),
            velocity: _animation.velocity,
          ),
        )
        .whenCompleteOrCancel(() {
          if (_disposed) return;
          _changing--;
          notifyListeners();
        });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _animation.dispose();
    super.dispose();
  }
}

/// A tab: its name, and what a look paints it with.
@immutable
class RawTab {
  /// A tab named [label].
  const RawTab({
    required this.label,
    this.icon,
    this.enabled = true,
    this.data,
  });

  /// Its name, and what a screen reader calls it.
  final String label;

  /// A glyph a look may paint beside or instead of [label].
  final IconData? icon;

  /// Whether it can be chosen; a disabled tab is skipped by the arrows.
  final bool enabled;

  /// Anything else the look needs to paint it (a badge count).
  final Object? data;
}

/// What a look paints a tab from.
@immutable
class RawTabDetails {
  /// The state; the bar makes it.
  const RawTabDetails({
    required this.states,
    required this.index,
    required this.count,
    required this.selection,
  });

  /// Its pressable states; [WidgetState.selected] while it is the
  /// controller's [RawTabController.index].
  final Set<WidgetState> states;

  /// Its place: 0 first.
  final int index;

  /// How many tabs the bar has.
  final int count;

  /// How selected it is: 1 at rest on it, 0 a tab or more away, between as
  /// the pages are swiped or a change runs. A look cross-fades its colour on
  /// it.
  final double selection;
}

/// Where a look paints the indicator, and the selected tab's states.
@immutable
class RawTabIndicatorDetails {
  /// The indicator's place; the bar makes it. [tabRect] is [rect] unless
  /// given.
  const RawTabIndicatorDetails({
    required this.rect,
    required this.direction,
    Rect? tabRect,
    this.states = const <WidgetState>{},
  }) : tabRect = tabRect ?? rect;

  /// The selected tab's face in the bar, moved and resized between tabs as
  /// the selection moves; the indicator is laid out in it. A tab's face is
  /// what a [TapTargetPadding] in it holds, when its target stands larger
  /// than its face (the target the hit area, the face its own size in it);
  /// otherwise the whole tab.
  final Rect rect;

  /// The selected tab's whole box, its hit area, moved and resized as
  /// [rect] is: [rect] itself unless the tab's touch target stands larger
  /// than its face.
  final Rect tabRect;

  /// Which way the tabs run.
  final Axis direction;

  /// The selected tab's states: [WidgetState.hovered],
  /// [WidgetState.pressed] and [WidgetState.focused] as the tab has them
  /// (an indicator painted in the tab's hover and press inks), with
  /// [WidgetState.selected] and, a disabled tab, [WidgetState.disabled].
  final Set<WidgetState> states;

  @override
  bool operator ==(Object other) =>
      other is RawTabIndicatorDetails &&
      other.rect == rect &&
      other.tabRect == tabRect &&
      other.direction == direction &&
      setEquals(other.states, states);

  @override
  int get hashCode =>
      Object.hash(rect, tabRect, direction, Object.hashAllUnordered(states));
}

/// Paints a tab.
typedef RawTabBuilder = Widget Function(
  BuildContext context,
  RawTab tab,
  RawTabDetails details,
);

/// Paints the indicator, laid out in [RawTabIndicatorDetails.rect].
typedef RawTabIndicatorBuilder = Widget Function(
  BuildContext context,
  RawTabIndicatorDetails details,
);

// The semantics identifier of [controller]'s page [index], which its tab
// controls.
String _panelId(RawTabController controller, int index) =>
    'RawTabBarView ${shortHash(controller)} $index';

/// A bar of [tabs], [controller] choosing among them; the look paints each
/// tab ([tabBuilder]) and the indicator under them ([indicatorBuilder]), or
/// over them ([indicatorPosition]).
///
/// Tabs share the bar's width (or, [isScrollable], keep their own and the
/// bar scrolls, the selected and the focused tab kept wholly in view);
/// [direction] vertical stacks them (a settings sidebar), each its own
/// height. Across the bar every tab's face stands as tall as the tallest
/// (as wide as the widest, in a column). A tab's face is the whole tab, or
/// what a touch target ([TapTargetPadding]) in it holds when the target
/// stands larger: the target is the tab's hit area, the face keeps its own
/// size in it, and the indicator keeps to the face
/// ([RawTabIndicatorDetails.rect]). A tab whose words grow where it
/// stands (a larger text size, a tab renamed) lays the bar out again.
///
/// The bar is one tab stop, on the selected tab; the arrows along it move
/// focus (mirrored right to left), wrapping, Home and End to the ends,
/// disabled tabs skipped. With [selectionFollowsFocus] the focused tab is
/// chosen as focus reaches it; otherwise Enter or Space chooses it. Each
/// arrow, Home and End is a [RawRovingFocusIntent], which an [Actions]
/// round the bar overrides.
///
/// ```dart
/// RawTabBar(controller: controller, tabs: const [RawTab(label: 'Inbox'), RawTab(label: 'Sent')], tabBuilder: (context, tab, details) => Text(tab.label))
/// ```
class RawTabBar extends StatefulWidget {
  /// A bar of [tabs], one per [controller] tab.
  const RawTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    required this.tabBuilder,
    this.indicatorBuilder,
    this.isScrollable = false,
    this.direction = Axis.horizontal,
    this.selectionFollowsFocus = true,
    this.semanticLabel,
    this.indicatorPosition = DecorationPosition.background,
  });

  /// Which tab is selected; the caller's.
  final RawTabController controller;

  /// The tabs, [RawTabController.length] of them.
  final List<RawTab> tabs;

  /// Paints a tab.
  final RawTabBuilder tabBuilder;

  /// Paints the indicator, under the tabs ([indicatorPosition]); null:
  /// none.
  final RawTabIndicatorBuilder? indicatorBuilder;

  /// Whether the indicator is painted under the tabs
  /// ([DecorationPosition.background], the default) or over them
  /// ([DecorationPosition.foreground]). Under is right for most: a pill or
  /// a fill behind the selected tab's words must not cover them, and a line
  /// under them shows either way. Over suits a line a tab's own fill would
  /// hide (a tab that paints its hover or its selection across its whole
  /// box). It takes no hits either way.
  final DecorationPosition indicatorPosition;

  /// Whether the tabs keep their own widths and the bar scrolls.
  final bool isScrollable;

  /// Which way the tabs run.
  final Axis direction;

  /// Whether a tab is chosen as focus reaches it (automatic activation).
  final bool selectionFollowsFocus;

  /// What a screen reader calls the bar.
  final String? semanticLabel;

  @override
  State<RawTabBar> createState() => _DesignTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawTabController>('controller', controller))
      ..add(IterableProperty<String>('tabs', [for (final t in tabs) t.label]))
      ..add(ObjectFlagProperty<RawTabBuilder>.has('tabBuilder', tabBuilder))
      ..add(
        ObjectFlagProperty<RawTabIndicatorBuilder>.has(
          'indicatorBuilder',
          indicatorBuilder,
        ),
      )
      ..add(
        FlagProperty(
          'isScrollable',
          value: isScrollable,
          ifTrue: 'isScrollable',
        ),
      )
      ..add(
        EnumProperty<Axis>(
          'direction',
          direction,
          defaultValue: Axis.horizontal,
        ),
      )
      ..add(
        FlagProperty(
          'selectionFollowsFocus',
          value: selectionFollowsFocus,
          ifFalse: 'selectionFollowsFocus: false',
          defaultValue: true,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        EnumProperty<DecorationPosition>(
          'indicatorPosition',
          indicatorPosition,
          defaultValue: DecorationPosition.background,
        ),
      );
  }
}

class _DesignTabBarState extends State<RawTabBar>
    with SingleTickerProviderStateMixin {
  // One node per tab, the bar's own.
  final List<FocusNode> _nodes = [];
  // Each tab's states, which the indicator reads from the selected tab's.
  final List<WidgetStatesController> _states = [];
  final ScrollController _scroll = ScrollController();
  late final AnimationController _strip = AnimationController.unbounded(
    vsync: this,
  )..addListener(_stripMoved);
  // The index the bar last brought into view.
  int _shown = 0;

  RawTabController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _shown = _controller.index;
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(RawTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _changed();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    for (final node in _nodes) {
      node.dispose();
    }
    _scroll.dispose();
    _strip.dispose();
    for (final states in _states) {
      states.dispose();
    }
    super.dispose();
  }

  // One states controller per tab: those of tabs gone are let go once their
  // tabs have let go of them, after the frame.
  void _syncStates(int n) {
    while (_states.length < n) {
      _states.add(WidgetStatesController());
    }
    if (_states.length == n) return;
    final gone = _states.sublist(n);
    _states.length = n;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final states in gone) {
        states.dispose();
      }
    });
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    if (_controller.index == _shown) return;
    _shown = _controller.index;
    // Once laid out, the newly selected tab is brought wholly into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal(_controller.index);
    });
  }

  // A key moved the focus to tab [i].
  void _movedTo(int i) {
    if (widget.selectionFollowsFocus) _controller.animateTo(i);
    _reveal(i);
  }

  // Scrolls the strip, on the controller's spring, the least way that shows
  // tab [i] whole.
  void _reveal(int i) {
    if (!widget.isScrollable || !_scroll.hasClients) return;
    if (i >= widget.tabs.length) return;
    final tab = _nodes[i].context?.findRenderObject();
    if (tab == null || !tab.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(tab);
    if (viewport == null) return;
    final position = _scroll.position;
    final start = viewport.getOffsetToReveal(tab, 0).offset;
    final end = viewport.getOffsetToReveal(tab, 1).offset;
    final to = position.pixels
        .clamp(math.min(start, end), math.max(start, end))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((to - position.pixels).abs() < .5) return;
    _strip
      ..value = position.pixels
      ..animateWith(
        designSpringSimulation(
          DesignMotionPolicy.of(context).spatial(
            dampingRatio: _controller.dampingRatio,
            stiffness: _controller.stiffness,
          ),
          from: position.pixels,
          to: to,
        ),
      );
  }

  void _stripMoved() {
    if (_scroll.hasClients && _scroll.position.pixels != _strip.value) {
      _scroll.position.jumpTo(_strip.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.tabs.length == _controller.length,
      'a RawTabBar has one tab per controller tab',
    );
    _controller._reduceMotion = designReduceMotionOf(context);
    final n = widget.tabs.length;
    while (_nodes.length < n) {
      _nodes.add(FocusNode(debugLabel: 'RawTabBar ${_nodes.length}'));
    }
    while (_nodes.length > n) {
      _nodes.removeLast().dispose();
    }
    _syncStates(n);
    final words = RawWidgetsLocalizations.of(context);
    final indicator = widget.indicatorBuilder;
    final selected = _controller.index;
    Widget bar = _TabStrip(
      direction: widget.direction,
      fill: !widget.isScrollable,
      hasIndicator: indicator != null,
      indicatorAbove: widget.indicatorPosition == DecorationPosition.foreground,
      children: [
        for (var i = 0; i < n; i++) _tab(i, words),
        if (indicator != null)
          _IndicatorLayer(
            animation: _controller.animation,
            direction: widget.direction,
            states: selected < n ? _states[selected] : null,
            builder: (context, details) =>
                ExcludeSemantics(child: indicator(context, details)),
          ),
      ],
    );
    bar = Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: RovingGroup(orientation: widget.direction, child: bar),
    );
    if (widget.isScrollable) {
      bar = SingleChildScrollView(
        scrollDirection: widget.direction,
        controller: _scroll,
        child: bar,
      );
    }
    return bar;
  }

  Widget _tab(int i, RawWidgetsLocalizations words) {
    final tab = widget.tabs[i];
    final controller = _controller;
    return RovingItem(
      focusNode: _nodes[i],
      enabled: tab.enabled,
      selected: i == controller.index,
      order: i,
      onMovedTo: () => _movedTo(i),
      child: _pressable(i, words),
    );
  }

  Widget _pressable(int i, RawWidgetsLocalizations words) {
    final tab = widget.tabs[i];
    final n = widget.tabs.length;
    final controller = _controller;
    return RawButton(
      focusNode: _nodes[i],
      statesController: _states[i],
      onPressed: tab.enabled ? () => controller.animateTo(i) : null,
      selected: i == controller.index,
      tab: true,
      builder: (context, states, _) => Semantics(
        // As Material's TabBar: its name, then its place.
        label: '${tab.label}\n${words.tabLabel(tabIndex: i + 1, tabCount: n)}',
        controlsNodes: {_panelId(controller, i)},
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: controller.animation,
            builder: (context, _) => widget.tabBuilder(
              context,
              tab,
              RawTabDetails(
                states: states,
                index: i,
                count: n,
                selection: (1 - (controller.animation.value - i).abs()).clamp(
                  0.0,
                  1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// The tabs in a row (or a column), then the indicator: tabs share a bounded
// row's width when [fill], else keep their own; every face as tall as the
// tallest (as wide as the widest, in a column), a touch target larger than
// its face the hit area round it. No tab is held at a size, so a tab that
// grows (its words larger, or renamed) lays the strip out again.
class _TabStrip extends MultiChildRenderObjectWidget {
  const _TabStrip({
    required this.direction,
    required this.fill,
    required this.hasIndicator,
    required this.indicatorAbove,
    required super.children,
  });

  final Axis direction;
  final bool fill;
  final bool hasIndicator;
  final bool indicatorAbove;

  @override
  _RenderTabStrip createRenderObject(BuildContext context) => _RenderTabStrip(
    direction: direction,
    fill: fill,
    hasIndicator: hasIndicator,
    indicatorAbove: indicatorAbove,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderTabStrip renderObject) {
    renderObject
      ..direction = direction
      ..fill = fill
      ..hasIndicator = hasIndicator
      ..indicatorAbove = indicatorAbove
      ..textDirection = Directionality.of(context);
  }
}

class _StripParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderTabStrip extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StripParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StripParentData> {
  _RenderTabStrip({
    required this._direction,
    required this._fill,
    required this._hasIndicator,
    required this._indicatorAbove,
    required this._textDirection,
  });

  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  bool get fill => _fill;
  bool _fill;
  set fill(bool value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsLayout();
  }

  bool get hasIndicator => _hasIndicator;
  bool _hasIndicator;
  set hasIndicator(bool value) {
    if (value == _hasIndicator) return;
    _hasIndicator = value;
    markNeedsLayout();
  }

  bool get indicatorAbove => _indicatorAbove;
  bool _indicatorAbove;
  set indicatorAbove(bool value) {
    if (value == _indicatorAbove) return;
    _indicatorAbove = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StripParentData) {
      child.parentData = _StripParentData();
    }
  }

  RenderBox? get _indicator => hasIndicator ? lastChild : null;

  List<RenderBox> get _tabs => [
    for (RenderBox? c = firstChild; c != null; c = childAfter(c))
      if (c != _indicator) c,
  ];

  // Each tab's box, in [constraints], and the strip's size: [layout] lays
  // each out at it, else they are measured dry. A tab is measured along the
  // run (its share of a filled row, else its own extent), then laid out so
  // again with every face at least as broad across the run as the broadest
  // face: never tight unless the strip's constraints are, so its growing
  // reaches the strip, and a touch target larger than its face stretches
  // no face. A tab narrower across than the strip stands in its middle.
  (List<Rect>, Size) _place(BoxConstraints constraints, {required bool dry}) {
    final tabs = _tabs;
    final n = tabs.length;
    final horizontal = direction == Axis.horizontal;
    Size measure(RenderBox tab, BoxConstraints c) {
      if (dry) return tab.getDryLayout(c);
      tab.layout(c, parentUsesSize: true);
      return tab.size;
    }

    double across(Size size) => horizontal ? size.height : size.width;
    double most(Iterable<double> v) => v.fold(0.0, math.max);
    final each = horizontal && fill && constraints.hasBoundedWidth && n > 0
        ? constraints.maxWidth / n
        : null;
    final run = horizontal
        ? BoxConstraints(
            minWidth: each ?? 0,
            maxWidth: each ?? double.infinity,
            maxHeight: constraints.maxHeight,
          )
        : BoxConstraints(maxWidth: constraints.maxWidth);
    final measured = [for (final t in tabs) measure(t, run)];
    // Dry, a tab's face is taken for the whole tab.
    final faces = dry
        ? [for (final size in measured) Offset.zero & size]
        : _faces(tabs);
    final broadest = most([for (final f in faces) across(f.size)]);
    final fit = horizontal
        ? run.copyWith(minHeight: constraints.constrainHeight(broadest))
        : run.copyWith(minWidth: constraints.constrainWidth(broadest));
    final sizes = [for (final t in tabs) measure(t, fit)];
    final breadth = most([for (final s in sizes) across(s)]);
    final rects = <Rect>[];
    var at = 0.0;
    if (horizontal) {
      final height = constraints.constrainHeight(breadth);
      final width = constraints.constrainWidth(
        sizes.fold(0.0, (a, s) => a + s.width),
      );
      for (final size in sizes) {
        final left = textDirection == TextDirection.rtl
            ? width - at - size.width
            : at;
        rects.add(Offset(left, (height - size.height) / 2) & size);
        at += size.width;
      }
      return (rects, Size(width, height));
    }
    final width = constraints.constrainWidth(breadth);
    for (final size in sizes) {
      rects.add(Offset((width - size.width) / 2, at) & size);
      at += size.height;
    }
    return (rects, Size(width, constraints.constrainHeight(at)));
  }

  // Each tab's face, in the tab's own space, read in a layout
  // callback: the strip reads its tabs' insides, laid out just now.
  List<Rect> _faces(List<RenderBox> tabs) {
    var faces = const <Rect>[];
    invokeLayoutCallback<BoxConstraints>((_) {
      faces = [for (final t in tabs) RenderTapTargetPadding.faceRectOf(t)];
    });
    return faces;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _place(constraints, dry: true).$2;

  @override
  void performLayout() {
    final (rects, size) = _place(constraints, dry: false);
    this.size = size;
    final tabs = _tabs;
    final faces = _faces(tabs);
    for (var i = 0; i < tabs.length; i++) {
      (tabs[i].parentData! as _StripParentData).offset = rects[i].topLeft;
    }
    final indicator = _indicator;
    if (indicator != null) {
      indicator.layout(
        _IndicatorConstraints(size, rects, [
          for (var i = 0; i < tabs.length; i++)
            faces[i].shift(rects[i].topLeft),
        ]),
      );
      (indicator.parentData! as _StripParentData).offset = Offset.zero;
    }
  }

  double _sum(double Function(RenderBox) f) =>
      _tabs.fold(0.0, (a, t) => a + f(t));

  double _most(double Function(RenderBox) f) =>
      _tabs.fold(0.0, (a, t) => math.max(a, f(t)));

  @override
  double computeMinIntrinsicWidth(double height) => direction == Axis.horizontal
      ? _sum((t) => t.getMinIntrinsicWidth(height))
      : _most((t) => t.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) => direction == Axis.horizontal
      ? (fill
            ? _most((t) => t.getMaxIntrinsicWidth(height)) * _tabs.length
            : _sum((t) => t.getMaxIntrinsicWidth(height)))
      : _most((t) => t.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) => direction == Axis.horizontal
      ? _most((t) => t.getMinIntrinsicHeight(double.infinity))
      : _sum((t) => t.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) => direction == Axis.horizontal
      ? _most((t) => t.getMaxIntrinsicHeight(double.infinity))
      : _sum((t) => t.getMaxIntrinsicHeight(width));

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final tab in _tabs.reversed) {
      final offset = (tab.parentData! as _StripParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            tab.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // The indicator under the tabs, or over them.
    final indicator = _indicator;
    if (indicator != null && !indicatorAbove) {
      context.paintChild(indicator, offset);
    }
    for (final tab in _tabs) {
      context.paintChild(
        tab,
        offset + (tab.parentData! as _StripParentData).offset,
      );
    }
    if (indicator != null && indicatorAbove) {
      context.paintChild(indicator, offset);
    }
  }
}

// The strip's size, its tabs' boxes and their faces: an indicator lays out
// again when any changes.
class _IndicatorConstraints extends BoxConstraints {
  _IndicatorConstraints(super.size, this.tabs, this.faces) : super.tight();

  final List<Rect> tabs;
  final List<Rect> faces;

  @override
  bool operator ==(Object other) =>
      other is _IndicatorConstraints &&
      super == other &&
      listEquals(tabs, other.tabs) &&
      listEquals(faces, other.faces);

  @override
  int get hashCode =>
      Object.hash(super.hashCode, Object.hashAll(tabs), Object.hashAll(faces));
}

// The box the selection stands in: between two tabs' boxes, past the last
// (or before the first) as an underdamped spring runs on.
Rect _between(List<Rect> rects, double at) {
  if (rects.isEmpty) return Rect.zero;
  if (rects.length == 1) return rects.single;
  final low = at.floor().clamp(0, rects.length - 2);
  return Rect.lerp(rects[low], rects[low + 1], at - low)!;
}

// The indicator, built as the strip lays out, from where the selection
// stands among the tabs' faces and the selected tab's [states]; it alone
// lays out again as the selection moves or those states change.
class _IndicatorLayer extends AbstractLayoutBuilder<RawTabIndicatorDetails> {
  const _IndicatorLayer({
    required this.animation,
    required this.direction,
    required this.states,
    required this.builder,
  });

  final Animation<double> animation;
  final Axis direction;
  final WidgetStatesController? states;

  @override
  final Widget Function(BuildContext, RawTabIndicatorDetails) builder;

  @override
  _RenderIndicatorLayer createRenderObject(BuildContext context) =>
      _RenderIndicatorLayer(animation, direction, states);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderIndicatorLayer renderObject,
  ) {
    renderObject
      ..animation = animation
      ..direction = direction
      ..states = states;
  }
}

class _RenderIndicatorLayer extends RenderBox
    with
        RenderObjectWithChildMixin<RenderBox>,
        RenderObjectWithLayoutCallbackMixin,
        RenderAbstractLayoutBuilderMixin<RawTabIndicatorDetails, RenderBox> {
  _RenderIndicatorLayer(this._animation, this._direction, this._states);

  Animation<double> get animation => _animation;
  Animation<double> _animation;
  set animation(Animation<double> value) {
    if (value == _animation) return;
    if (attached) {
      _animation.removeListener(markNeedsLayout);
      value.addListener(markNeedsLayout);
    }
    _animation = value;
    markNeedsLayout();
  }

  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  WidgetStatesController? get states => _states;
  WidgetStatesController? _states;
  set states(WidgetStatesController? value) {
    if (identical(value, _states)) return;
    if (attached) {
      _states?.removeListener(markNeedsLayout);
      value?.addListener(markNeedsLayout);
    }
    _states = value;
    markNeedsLayout();
  }

  Offset _at = Offset.zero;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(markNeedsLayout);
    _states?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _animation.removeListener(markNeedsLayout);
    _states?.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  RawTabIndicatorDetails get layoutInfo {
    final strip = constraints as _IndicatorConstraints;
    final at = _animation.value;
    return RawTabIndicatorDetails(
      rect: _between(strip.faces, at),
      tabRect: _between(strip.tabs, at),
      direction: _direction,
      states: Set<WidgetState>.unmodifiable(
        _states?.value ?? const <WidgetState>{},
      ),
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() {
    runLayoutCallback();
    size = constraints.biggest;
    final rect = layoutInfo.rect;
    _at = rect.topLeft;
    child?.layout(
      BoxConstraints.tight(
        Size(math.max(0, rect.width), math.max(0, rect.height)),
      ),
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset + _at);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(_at.dx, _at.dy, 0, 1);
  }
}

/// The pages of [controller]'s tabs, one per tab, swiped between: Material's
/// `TabBarView` without Material. Swiping moves the controller's
/// [RawTabController.animation], so a bar's indicator follows the finger;
/// let go, the pages spring to the nearer page (or the next, flung) on the
/// controller's spring. A change from the bar springs the pages the same
/// way. Each page is its tab's panel to a screen reader; pages off screen
/// are not built, unless a page keeps itself alive.
///
/// ```dart
/// RawTabBarView(controller: controller, children: const [Text('Inbox'), Text('Sent')])
/// ```
class RawTabBarView extends StatefulWidget {
  /// One page of [children] per [controller] tab.
  const RawTabBarView({
    super.key,
    required this.controller,
    required this.children,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
  });

  /// Which tab is selected; the caller's.
  final RawTabController controller;

  /// The pages, [RawTabController.length] of them.
  final List<Widget> children;

  /// How the pages respond to a swipe, under the paging;
  /// [NeverScrollableScrollPhysics] stops swiping, as on `TabBarView`.
  /// Null: clamped at the ends.
  final ScrollPhysics? physics;

  /// Where a swipe starts: where it was recognised (the default), or where
  /// the finger went down.
  final DragStartBehavior dragStartBehavior;

  @override
  State<RawTabBarView> createState() => _DesignTabViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<RawTabController>('controller', controller))
      ..add(
        DiagnosticsProperty<ScrollPhysics>(
          'physics',
          physics,
          defaultValue: null,
        ),
      )
      ..add(
        EnumProperty<DragStartBehavior>(
          'dragStartBehavior',
          dragStartBehavior,
          defaultValue: DragStartBehavior.start,
        ),
      );
  }
}

class _DesignTabViewState extends State<RawTabBarView> {
  late final PageController _pages = PageController(
    initialPage: widget.controller.index,
  );

  // The view moving its pages itself: its own scroll notifications are not
  // a swipe.
  int _driving = 0;

  // A swipe moving the controller: its moves are not a change to follow.
  bool _swiping = false;

  // A finger holds the pages: a change does not move them.
  bool _held = false;

  _Follow? _follow;

  RawTabController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _listen(_controller);
  }

  void _listen(RawTabController controller) {
    controller.addListener(_changed);
    controller.animation.addListener(_moved);
  }

  void _unlisten(RawTabController controller) {
    controller.removeListener(_changed);
    controller.animation.removeListener(_moved);
  }

  @override
  void didUpdateWidget(RawTabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _unlisten(oldWidget.controller);
      _listen(widget.controller);
      _moved();
    }
  }

  @override
  void dispose() {
    _unlisten(_controller);
    _follow = null;
    _pages.dispose();
    super.dispose();
  }

  // The controller's change ended (or jumped): the pages stop following it,
  // on its page.
  void _changed() {
    if (_swiping || _controller.indexIsChanging) return;
    final follow = _follow;
    if (follow == null || !_pages.hasClients) return;
    _follow = null;
    _driving++;
    _pages.position.jumpTo(
      _controller.animation.value * _pages.position.viewportDimension,
    );
    _driving--;
  }

  // The selection moved: unless the pages moved it, they follow it.
  void _moved() {
    if (_swiping || _held || !_pages.hasClients) return;
    final position = _pages.position;
    if (!position.hasViewportDimension || !position.hasContentDimensions) {
      return;
    }
    final to = _controller.animation.value * position.viewportDimension;
    _driving++;
    try {
      if (_controller.indexIsChanging) {
        // The spring moves the pages, as a scroll they can be grabbed from.
        var follow = _follow;
        if (follow == null) {
          follow = _follow = _Follow(
            position as ScrollPositionWithSingleContext,
            _followEnded,
          );
          position.beginActivity(follow);
        }
        (position as ScrollActivityDelegate).setPixels(to);
      } else if (position.pixels != to) {
        position.jumpTo(to);
      }
    } finally {
      _driving--;
    }
  }

  // Something else took the pages from the spring: a finger did.
  void _followEnded(_Follow follow) {
    if (!identical(follow, _follow)) return;
    _follow = null;
    _held = true;
    _controller._stop();
  }

  bool _scrolled(ScrollNotification notification) {
    if (_driving > 0 || notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _held = true;
      _controller._stop();
    }
    if (notification is ScrollEndNotification) _held = false;
    final page = _pages.hasClients ? _pages.page : null;
    if (page == null || _controller.indexIsChanging) return false;
    _swiping = true;
    try {
      if (notification is ScrollUpdateNotification) {
        if ((page - _controller.index).abs() > 1) {
          _controller.index = page.round();
        }
        _controller._offset = (page - _controller.index).clamp(-1.0, 1.0);
      } else if (notification is ScrollEndNotification) {
        _controller.index = page.round();
        _controller._offset = (page - _controller.index).clamp(-1.0, 1.0);
      }
    } finally {
      _swiping = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.children.length == _controller.length,
      'a RawTabBarView has one page per controller tab',
    );
    final reduceMotion = designReduceMotionOf(context);
    _controller._reduceMotion = reduceMotion;
    final spring = DesignMotionPolicy(reduceMotion: reduceMotion).spatial(
      dampingRatio: _controller.dampingRatio,
      stiffness: _controller.stiffness,
    );
    return NotificationListener<ScrollNotification>(
      onNotification: _scrolled,
      child: PageView(
        controller: _pages,
        physics: _SpringPages(spring)
            .applyTo(widget.physics ?? const ClampingScrollPhysics()),
        dragStartBehavior: widget.dragStartBehavior,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            Semantics(
              container: true,
              role: SemanticsRole.tabPanel,
              identifier: _panelId(_controller, i),
              child: widget.children[i],
            ),
        ],
      ),
    );
  }
}

// Pages that settle on the controller's spring.
class _SpringPages extends PageScrollPhysics {
  const _SpringPages(this._spring, {super.parent});

  final SpringDescription _spring;

  @override
  SpringDescription get spring => _spring;

  @override
  _SpringPages applyTo(ScrollPhysics? ancestor) =>
      _SpringPages(_spring, parent: buildParent(ancestor));
}

// The pages following the controller's spring: a scroll in progress, which
// a finger may take over.
class _Follow extends ScrollActivity {
  _Follow(super.delegate, this._ended);

  final void Function(_Follow follow) _ended;

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => 0;

  @override
  void dispose() {
    _ended(this);
    super.dispose();
  }
}
