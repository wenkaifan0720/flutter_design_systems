// Moving between views and along a sequence, using moulded tabs and inset marks.
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';
import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'internal/cap_label.dart';
import 'internal/cell_bank.dart';
import 'chrome_metrics.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'knobs.dart' show NeumorphicElevation;
import 'layout.dart' show neumorphicOwnSize;
import 'localizations.dart';
import 'shapes.dart';
import 'tell.dart' show NeumorphicLinearProgressIndicator;
import 'theme.dart';
import 'internal/panel.dart';
import 'internal/out_of_use.dart';

/// View tabs with one Tab stop, logical arrow navigation and a pressed selection.
///
/// ```dart
/// NeumorphicTabBar(tabs: const ['Today', 'Week'], selectedIndex: index, onChanged: select)
/// ```
class NeumorphicTabBar extends StatefulWidget {
  /// Creates a [NeumorphicTabBar].
  const NeumorphicTabBar({
    super.key,
    required this.tabs,
    this.selectedIndex = 0,
    this.onChanged,
    this.label,
    this.style,
  }) : assert(selectedIndex >= 0),
       assert(tabs.length == 0 || selectedIndex < tabs.length);

  /// Tab faces and labels, before segmentedButtonTheme.
  final NeumorphicStyle? style;

  /// The view labels, in display order.
  final List<String> tabs;

  /// The zero-based index of the selected item.
  final int selectedIndex;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<int>? onChanged;

  /// The text identifying this item or control.
  final String? label;
  @override
  State<NeumorphicTabBar> createState() => _NeumorphicTabBarState();
}

class _NeumorphicTabBarState extends State<NeumorphicTabBar> {
  final _nodes = <FocusNode>[];
  void _resize() {
    while (_nodes.length > widget.tabs.length) {
      _nodes.removeLast().dispose();
    }
    while (_nodes.length < widget.tabs.length) {
      _nodes.add(FocusNode());
    }
  }

  @override
  void initState() {
    super.initState();
    _resize();
  }

  @override
  void didUpdateWidget(NeumorphicTabBar old) {
    super.didUpdateWidget(old);
    _resize();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (widget.onChanged == null ||
        widget.tabs.isEmpty ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    int? next;
    if (key ==
        (rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)) {
      next = (index + 1) % widget.tabs.length;
    }
    if (key ==
        (rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft)) {
      next = (index - 1 + widget.tabs.length) % widget.tabs.length;
    }
    if (key == LogicalKeyboardKey.home) next = 0;
    if (key == LogicalKeyboardKey.end) next = widget.tabs.length - 1;
    if (next == null) return KeyEventResult.ignored;
    _nodes[next].requestFocus();
    widget.onChanged!(next);
    if (_nodes[next].context != null) {
      Scrollable.ensureVisible(
        _nodes[next].context!,
        duration: NeumorphicMotion.of(context).move,
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final dir = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final padding = t.density.padding(
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    // One weight in both states: a chosen label never reflows or moves.
    TextStyle words(bool selected) => t.textTheme.body.copyWith(
      color: selected ? t.colors.pigmentInkLit : t.colors.ink,
      fontWeight: FontWeight.w600,
    );
    var least = 64.0;
    for (final tab in widget.tabs) {
      final painter = TextPainter(
        text: TextSpan(text: tab, style: words(true)),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout(maxWidth: 240);
      least = math.max(least, painter.width + padding.horizontal + 2);
      painter.dispose();
    }
    final label = widget.label ?? NeumorphicLocalizations.of(context).tabs;
    return NeumorphicCellBank(
      // The tab bar's role sits on the bank inside its scroll, so every tab is its direct child.
      group: (bank) => Semantics(
        role: SemanticsRole.tabBar,
        container: true,
        explicitChildNodes: true,
        label: label,
        // Out of use the whole bar lies flat: its groove and the chosen tab with the words.
        child: NeumorphicOutOfUse(off: widget.onChanged == null, child: bank),
      ),
      selected: widget.selectedIndex,
      minCellWidth: least,
      scroll: true,
      naturalWidth: widget.tabs.length * least,
      contentHeight: (cellWidth) {
        final painter = TextPainter(
          text: TextSpan(text: 'Ag', style: words(true)),
          textDirection: dir,
          textScaler: scaler,
        )..layout();
        final h = painter.height + padding.vertical;
        painter.dispose();
        return h;
      },
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          Builder(
            builder: (context) {
              final selected = i == widget.selectedIndex;
              final cell = NeumorphicCellScope.of(context);
              _nodes[i].skipTraversal = !selected;
              return MergeSemantics(
                child: Semantics(
                  role: SemanticsRole.tab,
                  child: NeumorphicTap(
                    style: widget.style,
                    themeStyle: t.segmentedButtonTheme,
                    shape: cell.border,
                    focusReach: .5,
                    pressRelief: !selected,
                    button: false,
                    label: widget.tabs[i],
                    selected: selected,
                    focusNode: _nodes[i],
                    onKeyEvent: (_, event) => _key(i, event),
                    onPressed: widget.onChanged == null
                        ? null
                        : () => widget.onChanged!(i),
                    child: NeumorphicCellFace(
                      child: Builder(
                        builder: (context) {
                          final look = NeumorphicStyleOf(
                            [widget.style, t.segmentedButtonTheme],
                            {
                              ...NeumorphicStatesScope.of(context),
                              if (selected) WidgetState.selected,
                              if (widget.onChanged == null)
                                WidgetState.disabled,
                            },
                          );
                          Widget face = NeumorphicOutOfUse(
                            off: widget.onChanged == null,
                            child: Padding(
                              padding:
                                  look.padding(Directionality.of(context)) ??
                                  padding,
                              // Centred by its capitals, as every label of the look is.
                              child: Center(
                                child: neumorphicLabel(
                                  Text(
                                    widget.tabs[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: words(selected)
                                        .merge(look.textStyle)
                                        .copyWith(color: look.foreground),
                                  ),
                                ),
                              ),
                            ),
                          );
                          if (look.fill != null) {
                            face = DecoratedBox(
                              decoration: ShapeDecoration(
                                color: look.fill,
                                shape: cell.border,
                              ),
                              child: face,
                            );
                          }
                          return face;
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Where a carousel's slides are, in slides, for the dots under it (ui_core's `controls.position`).
class _DotsFollow extends InheritedWidget {
  const _DotsFollow({required this.position, required super.child});
  final ValueListenable<double> position;

  @override
  bool updateShouldNotify(_DotsFollow old) => old.position != position;
}

/// How near [at] (in pages, wrapping round [count]) is to page [i]: 1 on it, 0 a page or more away.
double _nearness(double at, int i, int count) {
  var d = (at - i).abs();
  if (count > 0) d = math.min(d, count - d);
  return (1 - d).clamp(0.0, 1.0);
}

/// One page mark: a small well in the wall, and on the current page a pill of the pigment pressed into it. Under a
/// carousel ([follow]) the pill follows the slides as the finger moves them.
class _Dot extends StatelessWidget {
  const _Dot({
    super.key,
    required this.page,
    required this.selected,
    required this.count,
    this.follow,
  });
  final int page, count;
  final bool selected;
  final ValueListenable<double>? follow;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final flat = NeumorphicFlatScope.of(context);
    // Its own size in any parent: a stretching row handed a bare sized paint the row's height.
    Widget mark(double near) => neumorphicOwnSize(
      width: 8 + 12 * near,
      height: 8,
      alignment: AlignmentDirectional.center,
      child: CustomPaint(
        painter: _DotWell(near, t.colors, t.elevation, flat, t.highContrast),
      ),
    );
    if (follow case final follow?) {
      return ValueListenableBuilder<double>(
        valueListenable: follow,
        builder: (context, at, _) => mark(_nearness(at, page, count)),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selected ? 1 : 0),
      duration: NeumorphicMotion.of(context).state,
      curve: NeumorphicMotion.of(context).standard,
      builder: (context, near, _) => mark(near),
    );
  }
}

class _DotWell extends CustomPainter {
  const _DotWell(this.near, this.c, this.elevation, this.flat, this.edge);
  final double near;
  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final bool flat, edge;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final well = Path()
      ..addRRect(
        RRect.fromRectAndRadius(box, Radius.circular(size.height / 2)),
      );
    // An idle dot's floor is a little shaded toward the quiet ink: a well of the ground's own colour, this small, all
    // but vanished, by night most of all.
    final floor = Color.lerp(c.ground, c.inkTertiary, .28)!;
    final face = Color.lerp(floor, c.pigment, near)!;
    neumorphicPaintPressed(
      canvas,
      well,
      c,
      light: (const Offset(-1, -1), 1.5),
      dark: (const Offset(1, 1), 1.5),
      face: LinearGradient(colors: [face, face]).createShader(box),
      tone: near > .5 ? c.pigment : null,
      flat: flat,
      elevation: elevation,
    );
    if (edge || flat) {
      canvas.drawPath(
        well,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = edge ? neumorphicEdgeWidth : 1
          ..color = edge ? c.edge : c.quiet,
      );
    }
  }

  @override
  bool shouldRepaint(_DotWell o) =>
      o.near != near ||
      o.c != c ||
      o.elevation != elevation ||
      o.flat != flat ||
      o.edge != edge;
}

/// Page marks with padded targets when they can be pressed. Long runs wrap.
///
/// ```dart
/// NeumorphicPageDots(count: 4, selectedIndex: page, label: 'Introduction', onChanged: jump)
/// ```
class NeumorphicPageDots extends StatelessWidget {
  /// Creates a [NeumorphicPageDots].
  const NeumorphicPageDots({
    super.key,
    required this.count,
    required this.selectedIndex,
    required this.label,
    this.onChanged,
    this.individualTargets = true,
  }) : assert(count >= 0),
       assert(selectedIndex >= 0),
       assert(count == 0 || selectedIndex < count);

  /// The number of pages represented by the dots.
  final int count;

  /// The zero-based index of the selected item.
  final int selectedIndex;

  /// The text identifying this item or control.
  final String label;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<int>? onChanged;

  /// Whether each page has its own target. False presents one compact,
  /// adjustable target: tap either side of the current mark or use arrows.
  final bool individualTargets;
  @override
  Widget build(BuildContext context) {
    if (!individualTargets) return _AdjustablePageDots(dots: this);
    final words = NeumorphicLocalizations.of(context);
    final follow = context
        .dependOnInheritedWidgetOfExactType<_DotsFollow>()
        ?.position;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            NeumorphicTap(
              selected: i == selectedIndex,
              label: '$label, ${words.pageOf(i + 1, count)}',
              round: true,
              focusInset: 9,
              onPressed: onChanged == null ? null : () => onChanged!(i),
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: _Dot(
                    page: i,
                    selected: i == selectedIndex,
                    count: count,
                    follow: follow,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdjustablePageDots extends StatefulWidget {
  const _AdjustablePageDots({required this.dots});
  final NeumorphicPageDots dots;

  @override
  State<_AdjustablePageDots> createState() => _AdjustablePageDotsState();
}

class _AdjustablePageDotsState extends State<_AdjustablePageDots> {
  late List<GlobalKey> _marks;
  NeumorphicPageDots get dots => widget.dots;

  @override
  void initState() {
    super.initState();
    _marks = List.generate(dots.count, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(_AdjustablePageDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dots.count == dots.count) return;
    final previous = _marks;
    _marks = List.generate(
      dots.count,
      (i) => i < previous.length ? previous[i] : GlobalKey(),
    );
  }

  void _move(int delta) {
    final next = dots.selectedIndex + delta;
    if (next >= 0 && next < dots.count) dots.onChanged?.call(next);
  }

  void _tapped(TapUpDetails details) {
    if (dots.count == 0) return;
    final box = _marks[dots.selectedIndex].currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final center = box.localToGlobal(box.size.center(Offset.zero)).dx;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final after = rtl
        ? details.globalPosition.dx < center
        : details.globalPosition.dx > center;
    _move(after ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    if (dots.count == 0) return const SizedBox.shrink();
    final words = NeumorphicLocalizations.of(context);
    final follow = context
        .dependOnInheritedWidgetOfExactType<_DotsFollow>()
        ?.position;
    final enabled = dots.onChanged != null;
    final increase = enabled && dots.selectedIndex + 1 < dots.count;
    final decrease = enabled && dots.selectedIndex > 0;
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        container: true,
        label: dots.label,
        value: words.pageOf(dots.selectedIndex + 1, dots.count),
        onIncrease: increase ? () => _move(1) : null,
        onDecrease: decrease ? () => _move(-1) : null,
        increasedValue: increase
            ? words.pageOf(dots.selectedIndex + 2, dots.count)
            : null,
        decreasedValue: decrease
            ? words.pageOf(dots.selectedIndex, dots.count)
            : null,
        child: ExcludeSemantics(
          child: NeumorphicTap(
            onPressed: enabled ? () => _move(1) : null,
            button: false,
            onKeyEvent: (node, event) {
              if (!enabled || event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              final key = event.logicalKey;
              if (key != LogicalKeyboardKey.arrowLeft &&
                  key != LogicalKeyboardKey.arrowRight) {
                return KeyEventResult.ignored;
              }
              final rtl = Directionality.of(context) == TextDirection.rtl;
              final forward = (key == LogicalKeyboardKey.arrowRight) != rtl;
              _move(forward ? 1 : -1);
              return KeyEventResult.handled;
            },
            child: GestureDetector(
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTapUp: enabled ? _tapped : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < dots.count; i++)
                        _Dot(
                          // Keep each mark's animation state at its page.
                          key: _marks[i],
                          page: i,
                          selected: i == dots.selectedIndex,
                          count: dots.count,
                          follow: follow,
                        ),
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
}

/// A named step and a segmented progress line. The text carries the exact position.
///
/// ```dart
/// NeumorphicStepProgress(count: 4, currentStep: 1, name: 'Choose a space')
/// ```
class NeumorphicStepProgress extends StatelessWidget {
  /// Creates a [NeumorphicStepProgress].
  const NeumorphicStepProgress({
    super.key,
    required this.count,
    required this.currentStep,
    required this.name,
    this.phase,
  }) : assert(count > 0),
       assert(currentStep >= 0 && currentStep <= count);

  /// The total number of steps.
  final int count;

  /// The zero-based index of the current step.
  final int currentStep;

  /// The name displayed for this item.
  final String name;

  /// Optional text naming the current phase.
  final String? phase;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final position = words.stepOf(
      currentStep == count ? count : currentStep + 1,
      count,
    );
    return Semantics(
      container: true,
      label: name,
      value: [position, ?phase].join(', '),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: t.textTheme.title),
            const SizedBox(height: 4),
            Text(phase ?? position, style: t.textTheme.caption),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) {
                final gap = box.hasBoundedWidth
                    ? (box.maxWidth / count / 5).clamp(0.0, 4.0)
                    : 4.0;
                return Row(
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      // Each step is a progress groove, filled with the pigment once reached: ink bars were ink
                      // as a body (law 5).
                      Expanded(
                        child: NeumorphicLinearProgressIndicator(
                          value: i <= currentStep ? 1 : 0,
                          label: name,
                          quiet: true,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The pages a pagination shows in [slots] places: every page when they fit, otherwise the first, the last and the
/// pages around [current], with null for each gap.
List<int?> _pageWindow(int current, int count, int slots) {
  final n = slots.isOdd ? slots : slots - 1;
  if (count <= n) return [for (var i = 0; i < count; i++) i];
  final side = (n - 5) ~/ 2;
  if (current <= n - 4) {
    return [for (var i = 0; i < n - 2; i++) i, null, count - 1];
  }
  if (current >= count - (n - 3)) {
    return [0, null, for (var i = count - (n - 2); i < count; i++) i];
  }
  return [
    0,
    null,
    for (var i = current - side; i <= current + side; i++) i,
    null,
    count - 1,
  ];
}

/// Pages of a long list: moulded page cells between a step back and a step on, the current page pressed in. The
/// first and last page always show; gaps are ellipses. Too narrow for five cells, it reads 'Page 3 of 9' between
/// the steps.
///
/// ```dart
/// NeumorphicPagination(count: 12, page: page, onChanged: (next) => setState(() => page = next))
/// ```
class NeumorphicPagination extends StatelessWidget {
  /// Creates a [NeumorphicPagination].
  const NeumorphicPagination({
    super.key,
    required this.count,
    required this.page,
    this.onChanged,
  }) : assert(count > 0),
       assert(page >= 0 && page < count);

  /// How many pages there are.
  final int count;

  /// The zero-based current page.
  final int page;

  /// Reports the page asked for; update [page] to show it. Null disables every cell.
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final face = t.density.height(40);
    final cell = math.max(face, NeumorphicChromeMetrics.targetSize);
    void go(int to) {
      if (to != page) onChanged?.call(to);
    }

    // The arrows are keys of the numbers' own shape: round keys beside rounded squares were two shapes in one control.
    final keys = NeumorphicStyle(
      shape: WidgetStatePropertyAll(t.shapes.corner(NeumorphicRadii.control)),
    );
    // Back points to the start of the line and on to its end, whichever way the words read.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final back = NeumorphicIconButton(
      rtl ? NeumorphicGlyphs.chevronRight : NeumorphicGlyphs.chevronLeft,
      label: words.previousPage,
      style: keys,
      onPressed: onChanged == null || page == 0 ? null : () => go(page - 1),
    );
    final on = NeumorphicIconButton(
      rtl ? NeumorphicGlyphs.chevronLeft : NeumorphicGlyphs.chevronRight,
      label: words.nextPage,
      style: keys,
      onPressed: onChanged == null || page == count - 1
          ? null
          : () => go(page + 1),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final room = box.hasBoundedWidth
              ? box.maxWidth - 2 * (cell + 8)
              : double.infinity;
          final slots = room.isInfinite ? 9 : (room / cell).floor();
          if (slots < 5) {
            return Row(
              children: [
                back,
                Expanded(
                  child: Text(
                    words.pageOf(page + 1, count),
                    style: t.textTheme.caption.tabular,
                    textAlign: TextAlign.center,
                  ),
                ),
                on,
              ],
            );
          }
          final shown = _pageWindow(page, count, math.min(slots, 9));
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              back,
              const SizedBox(width: 8),
              for (final p in shown)
                if (p == null)
                  SizedBox(
                    width: cell,
                    child: Text(
                      '…',
                      style: t.textTheme.caption,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  _PageCell(
                    number: p + 1,
                    label: words.pageOf(p + 1, count),
                    selected: p == page,
                    face: face,
                    target: cell,
                    onPressed: onChanged == null ? null : () => go(p),
                  ),
              const SizedBox(width: 8),
              on,
            ],
          );
        },
      ),
    );
  }
}

class _PageCell extends StatelessWidget {
  const _PageCell({
    required this.number,
    required this.label,
    required this.selected,
    required this.face,
    required this.target,
    this.onPressed,
  });
  final int number;
  final String label;
  final bool selected;
  final double face, target;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final shape = t.shapes.corner(NeumorphicRadii.control);
    return NeumorphicTap(
      shape: shape,
      onPressed: onPressed,
      label: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      focusSize: Size.square(face),
      child: Builder(
        builder: (context) {
          final states = {
            ...NeumorphicStatesScope.of(context),
            if (selected) WidgetState.selected,
          };
          return SizedBox.square(
            dimension: target,
            child: Center(
              child: NeumorphicSurface(
                cast: selected || states.contains(WidgetState.pressed)
                    ? NeumorphicSurfaceLevel.groove
                    : NeumorphicSurfaceLevel.part,
                shape: shape,
                states: states,
                outlined: true,
                child: SizedBox.square(
                  dimension: face,
                  child: Center(
                    child: Text(
                      '$number',
                      style: t.textTheme.caption.tabular.copyWith(
                        color: selected ? t.colors.ink : t.colors.inkSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One step of a [NeumorphicBreadcrumb] trail.
@immutable
class NeumorphicCrumb {
  /// Creates a [NeumorphicCrumb].
  const NeumorphicCrumb(this.label, {this.onPressed});

  /// The place's name.
  final String label;

  /// Goes to the place; the last crumb, the current place, takes none.
  final VoidCallback? onPressed;
}

/// Where a record sits: its ancestors as underlined links, each followed by a chevron, then the current place in
/// ink, not a link. Long trails wrap.
///
/// ```dart
/// NeumorphicBreadcrumb(crumbs: [NeumorphicCrumb('Home', onPressed: home), NeumorphicCrumb('Rooms', onPressed: rooms), NeumorphicCrumb('Kitchen')])
/// ```
class NeumorphicBreadcrumb extends StatelessWidget {
  /// Creates a [NeumorphicBreadcrumb].
  const NeumorphicBreadcrumb({super.key, required this.crumbs})
    : assert(crumbs.length > 0);

  /// The trail, outermost first; the last is the current place.
  final List<NeumorphicCrumb> crumbs;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: NeumorphicLocalizations.of(context).breadcrumbs,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, crumb) in crumbs.indexed) ...[
            if (i < crumbs.length - 1) ...[
              NeumorphicLink(crumb.label, onPressed: crumb.onPressed),
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    // The trail runs the way the words read.
                    Directionality.of(context) == TextDirection.rtl
                        ? NeumorphicGlyphs.chevronLeft
                        : NeumorphicGlyphs.chevronRight,
                    size: 16,
                    color: t.colors.inkTertiary,
                  ),
                ),
              ),
            ] else
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: NeumorphicChromeMetrics.targetSize,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    crumb.label,
                    style: t.textTheme.caption.copyWith(
                      color: t.colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The carousel's frame: a slide at rest with the room its cast takes all round, in the slab's shape grown by that
/// reach, concentric with the slide.
class _SlideFrame extends CustomClipper<Path> {
  const _SlideFrame(this.shape, this.reach);

  final OutlinedBorder shape;
  final double reach;

  // One shape, not a band with its cast's room added above and below: the band's corners and the cast's met in a step,
  // which cut the slide's shadow square at its lower corner.
  @override
  Path getClip(Size size) =>
      NeumorphicShapes.outset(shape, reach).getOuterPath(Offset.zero & size);

  @override
  bool shouldReclip(_SlideFrame old) =>
      old.shape != shape || old.reach != reach;
}

/// A carousel's step key. Out of use at either end it keeps its footprint, a faint flat disc, so the pair still reads
/// as a pair.
class _StepKey extends StatelessWidget {
  const _StepKey(this.icon, {required this.label, this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = NeumorphicTheme.of(context).colors;
    final key = NeumorphicIconButton(icon, label: label, onPressed: onPressed);
    if (onPressed != null) return key;
    return CustomPaint(painter: _Footprint(c), child: key);
  }
}

class _Footprint extends CustomPainter {
  const _Footprint(this.c);
  final NeumorphicColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) / 2 - 4;
    canvas.drawCircle(
      size.center(Offset.zero),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = c.quiet,
    );
  }

  @override
  bool shouldRepaint(_Footprint o) => o.c != c;
}

/// A paged strip of cards or pictures, one in view at a time with its whole cast, with page dots under it and, at
/// wide widths, a step back and on beside it. Reduced motion jumps instead of sliding.
///
/// ```dart
/// NeumorphicCarouselView(label: 'Rooms', height: 220, children: [for (final room in rooms) NeumorphicPictureCard(title: room)])
/// ```
class NeumorphicCarouselView extends StatefulWidget {
  /// Creates a [NeumorphicCarouselView].
  const NeumorphicCarouselView({
    super.key,
    required this.label,
    required this.children,
    this.height = 220,
    this.initialPage = 0,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
  }) : assert(height > 0);

  /// The item in view when the strip first shows. The current item stands in the middle, so the first one leaves the
  /// strip's start empty; a middle one shows a neighbour on each side.
  final int initialPage;

  /// The strip's keyboard focus; its own when null.
  final FocusNode? focusNode;

  /// Whether the strip takes focus when it first shows.
  final bool autofocus;

  /// The accessible name of the strip and its dots.
  final String label;

  /// The items, one to a page.
  final List<Widget> children;

  /// The items' height.
  final double height;

  /// Reports the item that settled in view.
  final ValueChanged<int>? onChanged;
  @override
  State<NeumorphicCarouselView> createState() => _NeumorphicCarouselState();
}

class _NeumorphicCarouselState extends State<NeumorphicCarouselView> {
  /// How far a slide's relief reaches above and below it: the strip stands that much taller, so its clip never cuts
  /// the cast.
  static const double _reach = 18;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final count = widget.children.length;
    final region = t.shapes.corner(NeumorphicRadii.slab);
    return DesignCarousel(
      itemCount: count,
      // One slide in view at rest, its whole cast inside the frame. Slides beside it showing a share of themselves were
      // cut by the frame, cast and all, and the cut casts drew the frame's outline as a raised tray under the slides
      // (a bump under bumps); the arrows, the dots and a swipe say there are more.
      viewportFraction: 1,
      initialPage: widget.initialPage,
      semanticLabel: widget.label,
      slideLabel: (i, n) => words.pageOf(i + 1, n),
      duration: t.motion.move,
      // The frame below clips in the slab's shape; the viewport adds no square cut of its own.
      clipBehavior: Clip.none,
      onPageChanged: widget.onChanged,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      // Each slide stands in the frame as on a face (NeumorphicSeat): a card casts as a part does, within the reach.
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.all(_reach),
        child: NeumorphicSeat(
          on: NeumorphicDraw.slab,
          child: widget.children[i],
        ),
      ),
      layoutBuilder: (context, viewport, controls) {
        final strip = CustomPaint(
          foregroundPainter: controls.focused
              ? neumorphicFocusLift(t, region)
              : null,
          child: SizedBox(
            height: widget.height - 8 + _reach * 2,
            // The frame holds the slab's shape: a slide passing its edge is cut round, as its own corners are, never
            // square. Its cast above and below keeps the strip's full height.
            child: ClipPath(
              clipper: _SlideFrame(region, _reach),
              child: viewport,
            ),
          ),
        );
        return LayoutBuilder(
          builder: (context, box) {
            final wide = box.hasBoundedWidth && box.maxWidth >= 600;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Row(
                    children: [
                      _StepKey(
                        Directionality.of(context) == TextDirection.rtl
                            ? NeumorphicGlyphs.chevronRight
                            : NeumorphicGlyphs.chevronLeft,
                        label: words.previous,
                        onPressed: controls.previous,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: strip),
                      const SizedBox(width: 8),
                      _StepKey(
                        Directionality.of(context) == TextDirection.rtl
                            ? NeumorphicGlyphs.chevronLeft
                            : NeumorphicGlyphs.chevronRight,
                        label: words.next,
                        onPressed: controls.next,
                      ),
                    ],
                  )
                else
                  // On a phone the slide stands on the page's keylines, as every card does: the room for its cast
                  // reaches into the gutter, where any card's cast falls.
                  SizedBox(
                    height: widget.height - 8 + _reach * 2,
                    child: OverflowBox(
                      minWidth: box.maxWidth + _reach * 2,
                      maxWidth: box.maxWidth + _reach * 2,
                      child: strip,
                    ),
                  ),
                if (count > 1) ...[
                  const SizedBox(height: 4),
                  _DotsFollow(
                    position: controls.position,
                    // Close together, as one adjustable control: the slides themselves are the large target.
                    child: NeumorphicPageDots(
                      count: count,
                      selectedIndex: controls.page,
                      label: widget.label,
                      onChanged: controls.goToPage,
                      individualTargets: false,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
