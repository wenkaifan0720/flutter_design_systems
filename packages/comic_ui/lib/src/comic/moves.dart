/// Navigation and progress through views, drawn as the comic's captions.
library;

import 'package:flutter/foundation.dart';
import 'package:ui_core/ui_core.dart';

import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'chrome.dart';
import 'nav.dart';
import 'glyphs.dart';
import 'internal/track.dart';
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';
import 'internal/cap_label.dart';
import 'knobs.dart' show ComicSpace;

/// A permanent side navigation panel for a wide layout.
///
/// ```dart
/// ComicNavigationDrawer(destinations: destinations, selectedIndex: 0, onDestinationSelected: select)
/// ```
class ComicNavigationDrawer extends StatelessWidget {
  /// Creates a drawer. The host chooses when the window is wide enough.
  const ComicNavigationDrawer({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.header,
    this.footer,
    this.label,
  });

  /// Destinations in reading order.
  final List<ComicNavItem> destinations;

  /// Current destination's position.
  final int selectedIndex;

  /// Selects by position, otherwise the destination's own onPressed runs.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional content above the destinations.
  final Widget? header;

  /// Optional content below the destinations.
  final Widget? footer;

  /// Overrides the localized navigation label.
  final String? label;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Semantics(
      label: label ?? ComicLocalizations.of(context).mainNavigation,
      child: ComicStateDecoration(
        decoration: BoxDecoration(
          color: t.colors.card,
          // The app bar's rule, so the two meet as one line at the corner.
          border: BorderDirectional(
            end: BorderSide(color: t.colors.nightLine, width: t.rim(3)),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(ComicSpace.near),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) ...[
                  header!,
                  const SizedBox(height: ComicSpace.gap),
                ],
                // The destinations are a list: a screen reader counts them, and they read as a list's rows.
                Semantics(
                  container: true,
                  role: SemanticsRole.list,
                  explicitChildNodes: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Rows stand apart by more than a print's depth, so the print of the row the keyboard pops
                      // never reaches the next row.
                      for (var i = 0; i < destinations.length; i++) ...[
                        if (i > 0)
                          SizedBox(height: t.focus.gap + t.focus.width),
                        Semantics(
                          container: true,
                          role: SemanticsRole.listItem,
                          child: ComicPressable(
                            key: destinations[i].key,
                            label: destinations[i].label,
                            selected: i == selectedIndex,
                            onPressed: onDestinationSelected == null
                                ? destinations[i].onPressed
                                : () => onDestinationSelected!(i),
                            outline: WidgetStatePropertyAll(t.shapes.small),
                            child: ComicStateDecoration(
                              decoration: ShapeDecoration(
                                color: i == selectedIndex
                                    ? t.colors.caption
                                    : t.colors.card,
                                shape: t.shapes.small,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(ComicSpace.near),
                                child: Row(
                                  children: [
                                    Icon(
                                      destinations[i].icon,
                                      color: i == selectedIndex
                                          ? t.colors.onCaption
                                          : t.colors.text,
                                    ),
                                    const SizedBox(width: ComicSpace.near),
                                    Expanded(
                                      child: CapLabel(
                                        child: Text(
                                          destinations[i].label,
                                          style: t.type.body.copyWith(
                                            color: i == selectedIndex
                                                ? t.colors.onCaption
                                                : t.colors.text,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: ComicSpace.gap),
                  footer!,
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
      ..add(IterableProperty<ComicNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: 0))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// Tabs between views: one trough at the control corner and a field's height, with no dividers, the chosen tab a
/// thumb (the trough's outline moved in by its rim and 2 px) that slides. On a phone every tab takes one width across
/// the bar; from 600 up each keeps to its words and the bar stands at the start. It scrolls sideways when the tabs need
/// more room than the row has.
///
/// ```dart
/// ComicTabBar(tabs: ['All', 'Saved'], selectedIndex: 0, onChanged: select)
/// ```
class ComicTabBar extends StatefulWidget {
  /// Creates a tab bar, distinct from the app's destination navigation.
  const ComicTabBar({
    super.key,
    required this.tabs,
    this.selectedIndex = 0,
    this.onChanged,
    this.label,
  });

  /// Tab labels in reading order.
  final List<String> tabs;

  /// Current tab position.
  final int selectedIndex;

  /// Selects a view; absent means disabled.
  final ValueChanged<int>? onChanged;

  /// Overrides the localized group name.
  final String? label;
  @override
  State<ComicTabBar> createState() => _ComicTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: 0))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

class _ComicTabBarState extends State<ComicTabBar>
    with TickerProviderStateMixin {
  RawTabController? _controller;
  bool _still = false;
  BuildContext? _chosenTab;

  // ui_core's bar brings a tab into view as it is chosen; the tab chosen as the bar first shows is brought inside the
  // rim here, after the frame: a cut, as a page change is. Only the bar's own row moves; the page around it stays.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tab = _chosenTab;
      if (!mounted || tab == null || !tab.mounted) return;
      final row = Scrollable.maybeOf(tab, axis: Axis.horizontal)?.position;
      final box = tab.findRenderObject();
      if (row == null || box == null || !box.attached) return;
      for (final policy in const [
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ]) {
        row.ensureVisible(box, alignmentPolicy: policy);
      }
    });
  }

  int get _chosen => widget.tabs.isEmpty
      ? 0
      : widget.selectedIndex.clamp(0, widget.tabs.length - 1);

  // The thumb slides as Comic's states change: a critically damped spring of about ComicMotion.state's 120 ms, no
  // overshoot. With still motion (Reduce Motion, a still theme) it lands within a frame: a cut, never a slide.
  void _make() {
    final old = _controller;
    _controller = RawTabController(
      length: widget.tabs.length,
      initialIndex: _chosen,
      vsync: this,
      stiffness: _still ? 1e6 : 1600,
    )..addListener(_moved);
    if (old != null) {
      old.removeListener(_moved);
      // The bar lets go of it as it builds with the new one.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = ComicMotion.of(context).state == Duration.zero;
    if (_controller == null || still != _still) {
      _still = still;
      _make();
    }
  }

  @override
  void didUpdateWidget(ComicTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller!;
    if (controller.length != widget.tabs.length) {
      _make();
    } else if (controller.index != _chosen) {
      controller.animateTo(_chosen);
    }
  }

  // A press or a key moved the bar: the app chooses. Where it keeps its tab, the thumb goes back to it.
  void _moved() {
    final controller = _controller!;
    if (controller.index == _chosen) return;
    widget.onChanged?.call(controller.index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller == controller && controller.index != _chosen) {
        controller.animateTo(_chosen);
      }
    });
  }

  @override
  void dispose() {
    _controller!
      ..removeListener(_moved)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    // The segmented control's trough at the control corner: a tab heads the panel under it and shares its corner.
    // One rim, tabs of one width side by side with no dividers, the chosen tab a thumb that slides.
    final rim = BorderSide(color: c.nightLine, width: t.rim(2.5));
    final outer = t.shapes.small;
    final inner = ComicTrack.cellShape(outer, rim);
    final height = ComicTrack.fieldHeight(context);
    // On a phone, across the width it is given, tabs of one width; from 600 up each tab keeps to its words, as a tab
    // bar on a wide screen does (the design kit's checks holds a tab bar to what its tabs take). It scrolls sideways only
    // when they need more.
    final wide = t.width >= 600;
    // A tab's own width: its words at the reader's text size, the face's padding, and the inset each side.
    final scaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final tab in widget.tabs) {
      final words = TextPainter(
        text: TextSpan(text: tab, style: t.type.title),
        textDirection: Directionality.of(context),
        maxLines: 1,
        textScaler: scaler,
      )..layout();
      final own = words.width + 2 * (ComicSpace.gap + ComicTrack.inset);
      words.dispose();
      if (own > widest) widest = own;
    }
    final enabled = widget.onChanged != null;
    return LayoutBuilder(
      builder: (context, box) {
        // Tabs that need more than the row (large text on a phone): the trough's rim holds still at the row's ends and
        // the tabs scroll inside it, each at its own width, so the one past the end shows cut by the rim. From 600 up
        // the trough hugs its tabs at the start.
        final scrolls =
            wide ||
            (box.hasBoundedWidth &&
                widest * widget.tabs.length + 2 * rim.width > box.maxWidth);
        return Align(
          alignment: AlignmentDirectional.centerStart,
          heightFactor: 1,
          child: ComicTrough(
            shape: outer,
            rim: rim,
            fill: c.dark ? c.card : c.control,
            thumb: c.caption,
            clip: scrolls,
            child: RawTabBar(
              controller: _controller!,
              isScrollable: scrolls,
              semanticLabel:
                  widget.label ?? ComicLocalizations.of(context).tabs,
              tabs: [
                for (final tab in widget.tabs)
                  RawTab(label: tab, enabled: enabled),
              ],
              tabBuilder: (context, tab, at) {
                // A fixed strip has no viewport of its own to reveal a tab in.
                if (at.index == _chosen) _chosenTab = scrolls ? context : null;
                // A disabled face is screened back toward its paper, as every Comic press is; the thumb stays.
                return ComicScreened(
                  on: at.states.contains(WidgetState.disabled),
                  child: SizedBox(
                    height: height,
                    child: ComicTrackFace(
                      states: at.states,
                      shape: inner,
                      padding: const EdgeInsets.symmetric(
                        horizontal: ComicSpace.gap,
                      ),
                      child: CapLabel(
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          style: t.type.title.copyWith(
                            color: at.selection > .5
                                ? c.onCaption
                                : c.dark
                                ? c.text
                                : c.onPaper,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              // The thumb: the trough's outline moved in by its rim and 2 px, under the chosen tab, painted as the
              // trough's own thumb is.
              indicatorBuilder: (context, thumb) => CustomPaint(
                painter: _Thumb(
                  inner,
                  c.caption,
                  EdgeInsets.symmetric(
                    horizontal: ComicTrack.inset,
                    vertical: ComicTrack.inset + rim.width,
                  ),
                  Directionality.of(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Page indicators: a small caption mark a page, the current one longer. With [onChanged] the row is one control, as
/// a phone's page control is: a press on a mark goes to its page, the arrow keys step (Home and End to the ends), and
/// a screen reader adjusts it as a slider. One target, the whole row's height, instead of a row of small ones each
/// inside its neighbours' reach.
///
/// ```dart
/// ComicPageDots(count: 4, selectedIndex: 1, label: 'Pages', onChanged: select)
/// ```
class ComicPageDots extends StatelessWidget {
  /// Creates page indicators.
  const ComicPageDots({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.label,
    this.onChanged,
  }) : assert(count >= 0);

  /// Number of pages.
  final int count;

  /// Current page position.
  final int selectedIndex;

  /// The group's accessible label.
  final String label;

  /// Selects a page; absent means display only.
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    // The current page is a longer mark, not only a filled one: it reads by its shape as well as its colour.
    double across(int i) => i == selectedIndex ? 32 : 18;
    // A round mark's antialiased rim leaves fewer whole pixels of ink than a square's: the rim is 3 px, so the
    // marks still stand 3:1 from the ground by their ink, not only by their fill.
    Widget mark(int i) => Container(
      width: across(i),
      height: 18,
      decoration: ShapeDecoration(
        color: i == selectedIndex
            ? c.caption
            : c.dark
            ? c.card
            : c.control,
        shape: t.shapes.full.copyWith(
          side: BorderSide(color: c.nightLine, width: t.rim(3)),
        ),
      ),
    );
    // Each mark keeps its slot between its neighbours; the row's ends are the marks' own, so the first mark starts on
    // the column's edge and a target's reach past an end stands outward.
    EdgeInsetsGeometry slot(int i) => EdgeInsetsDirectional.only(
      start: i == 0 ? 0 : (44 - across(i)) / 2,
      end: i == count - 1 ? 0 : (44 - across(i)) / 2,
      top: 13,
      bottom: 13,
    );
    Widget dot(int i) => Padding(padding: slot(i), child: mark(i));
    final choose = onChanged;
    if (choose != null && count > 0) {
      return _ChoosingDots(
        count: count,
        selectedIndex: selectedIndex,
        label: label,
        onChanged: choose,
        dot: (i, states) => Padding(
          key: ValueKey('page-dot/$i'),
          padding: slot(i),
          child: ComicHighlight(
            states: states,
            shape: t.shapes.full,
            ring: false,
            child: mark(i),
          ),
        ),
      );
    }
    return Semantics(
      label: label,
      value: '${count == 0 ? 0 : selectedIndex + 1} / $count',
      child: ExcludeSemantics(
        child: Wrap(children: [for (var i = 0; i < count; i++) dot(i)]),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged));
  }
}

/// [ComicPageDots] taking presses: one focusable, adjustable row.
class _ChoosingDots extends StatefulWidget {
  const _ChoosingDots({
    required this.count,
    required this.selectedIndex,
    required this.label,
    required this.onChanged,
    required this.dot,
  });

  final int count, selectedIndex;
  final String label;
  final ValueChanged<int> onChanged;
  final Widget Function(int i, Set<WidgetState> states) dot;

  @override
  State<_ChoosingDots> createState() => _ChoosingDotsState();
}

class _Step extends Intent {
  const _Step(this.to);

  /// A page index, or one of the ends: [_first] and [_last]; otherwise a step from the current page.
  final int to;
}

const int _first = -1000, _last = 1000;

class _ChoosingDotsState extends State<_ChoosingDots> {
  late List<GlobalKey> _keys = _make();
  int? _hovered, _down;
  var _focused = false;

  List<GlobalKey> _make() => [
    for (var i = 0; i < widget.count; i++) GlobalKey(),
  ];

  @override
  void didUpdateWidget(_ChoosingDots old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      _keys = _make();
      _hovered = _down = null;
    }
  }

  void _go(int i) {
    final next = i.clamp(0, widget.count - 1);
    if (next != widget.selectedIndex) widget.onChanged(next);
  }

  // The mark nearest [global] along the row: every press lands on a page, the gaps between marks included.
  int? _at(Offset global) {
    int? best;
    var gap = double.infinity;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final centre = box.localToGlobal(box.size.center(Offset.zero));
      final d = (centre.dx - global.dx).abs();
      if (d < gap) {
        gap = d;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final at = widget.selectedIndex, count = widget.count;
    String value(int i) => '${i + 1} / $count';
    return Semantics(
      container: true,
      slider: true,
      label: widget.label,
      value: value(at),
      increasedValue: at + 1 < count ? value(at + 1) : null,
      decreasedValue: at > 0 ? value(at - 1) : null,
      onIncrease: at + 1 < count ? () => _go(at + 1) : null,
      onDecrease: at > 0 ? () => _go(at - 1) : null,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) {
          if (!v) setState(() => _hovered = null);
        },
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): _Step(
            rtl ? 1 : -1,
          ),
          const SingleActivator(LogicalKeyboardKey.arrowRight): _Step(
            rtl ? -1 : 1,
          ),
          const SingleActivator(LogicalKeyboardKey.home): const _Step(_first),
          const SingleActivator(LogicalKeyboardKey.end): const _Step(_last),
        },
        actions: {
          _Step: CallbackAction<_Step>(
            onInvoke: (step) => _go(switch (step.to) {
              _first => 0,
              _last => count - 1,
              final by => at + by,
            }),
          ),
        },
        child: MouseRegion(
          onHover: (e) {
            final i = _at(e.position);
            if (i != _hovered) setState(() => _hovered = i);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // A screen reader adjusts the row; a tap at its middle would land on whichever page stood there.
            excludeFromSemantics: true,
            onTapDown: (d) => setState(() => _down = _at(d.globalPosition)),
            onTapCancel: () => setState(() => _down = null),
            onTapUp: (d) {
              final i = _at(d.globalPosition);
              setState(() => _down = null);
              if (i != null) _go(i);
            },
            child: ComicHighlight(
              states: {if (_focused) WidgetState.focused},
              shape: t.shapes.full,
              wash: false,
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < count; i++)
                      KeyedSubtree(
                        key: _keys[i],
                        child: widget.dot(i, {
                          if (_hovered == i) WidgetState.hovered,
                          if (_down == i) WidgetState.pressed,
                          if (i == at) WidgetState.selected,
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress along a finite sequence; display only, not a row of buttons.
///
/// ```dart
/// ComicStepProgress(count: 3, currentStep: 1, name: 'Your order')
/// ```
class ComicStepProgress extends StatelessWidget {
  /// Creates step progress.
  const ComicStepProgress({
    super.key,
    required this.count,
    required this.currentStep,
    required this.name,
    this.phase,
  }) : assert(count > 0),
       assert(currentStep >= 0),
       assert(currentStep < count);

  /// Total steps.
  final int count;

  /// Current zero-based position.
  final int currentStep;

  /// The sequence's name.
  final String name;

  /// An optional description of the current step.
  final String? phase;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return Semantics(
      label: name,
      value: '${phase == null ? '' : '$phase, '}${currentStep + 1} / $count',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Text(phase ?? name, style: t.type.title)),
          const SizedBox(height: ComicSpace.close),
          ExcludeSemantics(
            child: Wrap(
              spacing: ComicSpace.close,
              runSpacing: ComicSpace.close,
              children: [
                for (var i = 0; i < count; i++)
                  Container(
                    padding: const EdgeInsets.all(ComicSpace.close),
                    decoration: ShapeDecoration(
                      color: i <= currentStep
                          ? t.colors.caption
                          : t.colors.dark
                          ? t.colors.card
                          : t.colors.control,
                      shape: t.shapes.small.copyWith(
                        side: BorderSide(
                          color: t.colors.nightLine,
                          width: t.rim(2),
                        ),
                      ),
                    ),
                    child: CapLabel(
                      child: Text(
                        '${i + 1}',
                        style: t.type.body.copyWith(
                          color: i <= currentStep
                              ? t.colors.onCaption
                              : t.colors.dark
                              ? t.colors.text
                              : t.colors.onPaper,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('currentStep', currentStep))
      ..add(StringProperty('name', name))
      ..add(StringProperty('phase', phase, defaultValue: null));
  }
}

/// A narrow side rail of destinations for a medium or wide window: each an icon in its indicator over its short word,
/// the current one lit as the phone's [ComicNavigationBar] lights it. [leading] (a logo, an act) stands above them and
/// [trailing] below. A phone keeps the bottom bar; a window wide enough for whole labels takes [ComicNavigationDrawer].
///
/// ```dart
/// ComicNavigationRail(destinations: destinations, selectedIndex: 0, onDestinationSelected: select)
/// ```
class ComicNavigationRail extends StatelessWidget {
  /// Creates a rail. The host chooses when the window is wide enough.
  const ComicNavigationRail({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.leading,
    this.trailing,
    this.label,
  });

  /// Destinations in reading order.
  final List<ComicNavItem> destinations;

  /// Current destination's position.
  final int selectedIndex;

  /// Selects by position, otherwise the destination's own onPressed runs.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional content above the destinations.
  final Widget? leading;

  /// Optional content below the destinations.
  final Widget? trailing;

  /// Overrides the localized navigation label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    Widget destination(int i) {
      final on = i == selectedIndex;
      final item = destinations[i];
      return ComicPressable(
        key: item.key,
        label: item.label,
        value: item.badgeLabel,
        selected: on,
        wash: false,
        ring: false,
        onPressed: onDestinationSelected == null
            ? item.onPressed
            : () => onDestinationSelected!(i),
        builder: (context, states) => Padding(
          padding: const EdgeInsets.symmetric(vertical: ComicSpace.close),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The marks sit on the indicator, in its shape.
              ComicHighlight(
                states: states,
                shape: t.shapes.small,
                child: Container(
                  width: 56,
                  height: 34,
                  decoration: ShapeDecoration(
                    color: on ? c.caption : null,
                    shape: t.shapes.small.copyWith(
                      side: on
                          ? BorderSide(color: c.nightLine, width: t.rim(2.5))
                          : BorderSide.none,
                    ),
                  ),
                  child: Center(
                    child: ComicStateLerp<Color?>(
                      value: on ? c.onCaption : c.textSecondary,
                      lerp: Color.lerp,
                      builder: (context, ink, _) =>
                          Icon(item.icon, size: 20, color: ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: ComicSpace.tight),
              SizedBox(
                width: 80,
                child: Text(
                  item.short.toUpperCase(),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: t.type.letter(
                    15,
                    lineHeight: 1,
                    color: on ? c.text : c.textSecondary,
                    tracking: .06,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: label ?? ComicLocalizations.of(context).mainNavigation,
      container: true,
      explicitChildNodes: true,
      child: ComicStateDecoration(
        decoration: BoxDecoration(
          color: c.card,
          // The app bar's rule, as the drawer's edge.
          border: BorderDirectional(
            end: BorderSide(color: c.nightLine, width: t.rim(3)),
          ),
        ),
        child: SizedBox(
          width: 88,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: ComicSpace.near),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(height: ComicSpace.gap),
                ],
                for (var i = 0; i < destinations.length; i++) destination(i),
                if (trailing != null) ...[
                  const SizedBox(height: ComicSpace.gap),
                  trailing!,
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
      ..add(IterableProperty<ComicNavItem>('destinations', destinations))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: 0))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onDestinationSelected',
          onDestinationSelected,
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// One step of a [ComicBreadcrumb] trail: its words and where a press goes. The last step is the current page.
@immutable
class ComicCrumb {
  /// Creates a crumb.
  const ComicCrumb(this.label, {this.onPressed});

  /// The page's name.
  final String label;

  /// Goes to that page. Null: not pressable.
  final VoidCallback? onPressed;
}

/// Where a page sits in a hierarchy: each ancestor a link, the current page last and plain. It wraps on a phone.
///
/// ```dart
/// ComicBreadcrumb([ComicCrumb('Shop', onPressed: shop), ComicCrumb('Comics', onPressed: comics), ComicCrumb('Issue 12')])
/// ```
class ComicBreadcrumb extends StatelessWidget {
  /// Creates a trail.
  const ComicBreadcrumb(this.items, {super.key, this.label});

  /// The steps, the root first and the current page last.
  final List<ComicCrumb> items;

  /// Overrides the localized trail name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final words = t.type.text(14, 1.3, weight: FontWeight.w700);
    // A step's room either side of its words; the first step's words start on the trail's keyline, its room after them.
    const side = EdgeInsets.symmetric(horizontal: ComicSpace.close);
    const lead = EdgeInsetsDirectional.only(end: ComicSpace.close);
    return Semantics(
      label: label ?? ComicLocalizations.of(context).breadcrumbs,
      container: true,
      explicitChildNodes: true,
      // Each step stands at its floor with its side room inside: a tap and a screen reader reach the same box.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 0,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i == items.length - 1 || items[i].onPressed == null)
              Semantics(
                // The current page is said as such; an inert ancestor is plain words.
                selected: i == items.length - 1 ? true : null,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: ComicTapTarget.targetOf(context),
                  ),
                  child: Padding(
                    padding: i == 0 ? lead : side,
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        items[i].label,
                        style: words.copyWith(color: c.text),
                      ),
                    ),
                  ),
                ),
              )
            else
              ComicPressable(
                link: true,
                label: items[i].label,
                outline: WidgetStatePropertyAll(t.shapes.small),
                onPressed: items[i].onPressed,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: ComicTapTarget.target,
                    // The first step's words stand on the keyline; its room after them keeps it at the floor.
                    minWidth: i == 0 ? ComicTapTarget.targetOf(context) : 0,
                  ),
                  child: Padding(
                    padding: i == 0 ? lead : side,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 1,
                      child: Text(
                        items[i].label,
                        style: words.copyWith(
                          color: c.shadeText,
                          decoration: TextDecoration.underline,
                          decorationColor: c.shadeText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (i < items.length - 1)
              ExcludeSemantics(
                child: Icon(
                  rtl ? ComicGlyphs.chevronLeft : ComicGlyphs.chevronRight,
                  size: 16,
                  color: c.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<ComicCrumb>('items', items))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// Pages of a long list: a step back, the page numbers around the current one (the first and last always, a gap
/// marked between), and a step on. Where the numbers don't fit, it says "Page 3 of 12" between the steps. [page] is
/// zero-based.
///
/// ```dart
/// ComicPagination(count: 12, page: 2, onChanged: (i) => setState(() => page = i))
/// ```
class ComicPagination extends StatelessWidget {
  /// Creates a pager.
  const ComicPagination({
    super.key,
    required this.count,
    required this.page,
    this.onChanged,
    this.window = 1,
    this.label,
  }) : assert(count >= 1),
       assert(page >= 0 && page < count);

  /// How many pages there are.
  final int count;

  /// The current page, from zero.
  final int page;

  /// Goes to a page; null disables the pager.
  final ValueChanged<int>? onChanged;

  /// How many numbers stand either side of the current one.
  final int window;

  /// The pager's accessible name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final words = ComicLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The tabs' trough: the arrows and the numbers are cells of one width in it, with no dividers, and the current
    // page is the thumb, moved in by the rim and 2 px from the trough's outline.
    final rim = BorderSide(color: c.nightLine, width: t.rim(2.5));
    final outer = t.shapes.small;
    final inner = ComicTrack.cellShape(outer, rim);
    final ink = c.dark ? c.text : c.onPaper;
    final target = ComicTapTarget.targetOf(context);
    Widget cell({
      required String label,
      required VoidCallback? onPressed,
      required Widget child,
      bool on = false,
    }) => ComicPressable(
      label: label,
      selected: on ? true : null,
      wash: false,
      ring: false,
      sink: false,
      onPressed: onPressed,
      builder: (context, states) => ComicTrackFace(
        states: states,
        shape: inner,
        padding: const EdgeInsets.symmetric(horizontal: ComicSpace.tight),
        // Every cell is at least the platform's target wide: 44, or 48 where a touch reaches it.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: target - 2 * ComicTrack.inset - 8,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
    Widget number(int i) {
      final on = i == page;
      return cell(
        label: words.page(i + 1, count),
        on: on,
        // The current page stays at full ink: a press on it keeps the page where it is.
        onPressed: onChanged == null ? null : () => on ? null : onChanged!(i),
        // Its capitals on the cell's middle, as the arrows' glyphs are (the design kit's checks read them 0.2 px apart).
        child: CapLabel(
          child: Text(
            '${i + 1}',
            style: t.type.text(
              15,
              1.2,
              weight: FontWeight.w700,
              color: on ? c.onCaption : ink,
            ),
          ),
        ),
      );
    }

    Widget step(bool back) => cell(
      label: back
          ? RawWidgetsLocalizations.of(context).previousPageTooltip
          : RawWidgetsLocalizations.of(context).nextPageTooltip,
      onPressed: onChanged == null || (back ? page == 0 : page == count - 1)
          ? null
          : () => onChanged!(page + (back ? -1 : 1)),
      child: Icon(
        back == !rtl ? ComicGlyphs.chevronLeft : ComicGlyphs.chevronRight,
        size: 20,
        color: ink,
      ),
    );
    Widget gap() => ExcludeSemantics(
      child: Center(
        child: Text(
          '…',
          textAlign: TextAlign.center,
          style: t.type.body.copyWith(
            color: c.dark ? c.textSecondary : c.onPaperSecondary,
          ),
        ),
      ),
    );
    return Semantics(
      label: label,
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, box) {
          // The first and last pages, the current one and [window] either side of it; where that row is too wide,
          // fewer neighbours (down to none: 1 … 4 … 8) before the numbers give way to words.
          (List<Widget>, int?) row(int window) {
            final shown = <int>{
              0,
              count - 1,
              for (var i = page - window; i <= page + window; i++)
                if (i >= 0 && i < count) i,
            }.toList()..sort();
            final cells = <Widget>[step(true)];
            int? lit;
            for (var k = 0; k < shown.length; k++) {
              if (k > 0 && shown[k] - shown[k - 1] > 1) cells.add(gap());
              if (shown[k] == page) lit = cells.length;
              cells.add(number(shown[k]));
            }
            cells.add(step(false));
            return (cells, lit);
          }

          for (var w = window; w >= 0; w--) {
            final (cells, lit) = row(w);
            if (box.maxWidth < cells.length * target + 2 * rim.width) continue;
            return Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: ComicTrack(
                shape: outer,
                rim: rim,
                fill: c.dark ? c.card : c.control,
                thumb: c.caption,
                lit: lit,
                cellWidth: target,
                cells: cells,
              ),
            );
          }
          // Too narrow for the numbers: the arrows either side of "Page x of y", which takes what they leave.
          return ComicTrack(
            shape: outer,
            rim: rim,
            fill: c.dark ? c.card : c.control,
            equal: false,
            grow: const {1},
            cells: [
              step(true),
              Semantics(
                liveRegion: true,
                child: Center(
                  child: CapLabel(
                    child: Text(
                      words.page(page + 1, count),
                      textAlign: TextAlign.center,
                      style: t.type.text(
                        15,
                        1.2,
                        weight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                ),
              ),
              step(false),
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('page', page))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(IntProperty('window', window, defaultValue: 1))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

class _Thumb extends CustomPainter {
  const _Thumb(this.shape, this.color, this.inset, this.direction);
  final OutlinedBorder shape;
  final Color color;
  final EdgeInsets inset;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    shape.getOuterPath(
      inset.deflateRect(Offset.zero & size),
      textDirection: direction,
    ),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_Thumb old) =>
      old.shape != shape ||
      old.color != color ||
      old.inset != inset ||
      old.direction != direction;
}
