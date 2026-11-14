/// Navigation and progress through views, drawn as the comic's captions.
library;

import 'package:ui_core/ui_core.dart';

import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'chrome.dart';
import 'glyphs.dart';
import 'internal/reach.dart';
import 'internal/track.dart';
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';
import 'internal/cap_label.dart';

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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (header != null) ...[header!, const SizedBox(height: 16)],
                // The destinations are a list: a screen reader counts them, and they read as a list's rows.
                Semantics(
                  container: true,
                  role: SemanticsRole.list,
                  explicitChildNodes: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Rows stand the keyboard's ring apart, so the next row's fill never covers the ring of the one
                      // above.
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
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      destinations[i].icon,
                                      color: i == selectedIndex
                                          ? t.colors.onCaption
                                          : t.colors.text,
                                    ),
                                    const SizedBox(width: 12),
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
                if (footer != null) ...[const SizedBox(height: 16), footer!],
              ],
            ),
          ),
        ),
      ),
    );
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
}

class _ComicTabBarState extends State<ComicTabBar> {
  final List<FocusNode> _nodes = [];
  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(ComicTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  void _syncNodes() {
    while (_nodes.length < widget.tabs.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.tabs.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _keys(int index, KeyEvent event) {
    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        widget.onChanged == null ||
        _nodes.isEmpty) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final next = key == LogicalKeyboardKey.home
        ? 0
        : key == LogicalKeyboardKey.end
        ? _nodes.length - 1
        : key == LogicalKeyboardKey.arrowRight
        ? (index + (rtl ? -1 : 1)) % _nodes.length
        : key == LogicalKeyboardKey.arrowLeft
        ? (index + (rtl ? 1 : -1)) % _nodes.length
        : null;
    if (next == null) return KeyEventResult.ignored;
    _nodes[next].requestFocus();
    Scrollable.ensureVisible(
      _nodes[next].context!,
      alignment: .5,
      duration: ComicMotion.of(context).state,
    );
    widget.onChanged!(next);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal =
          i != widget.selectedIndex.clamp(0, _nodes.length - 1);
    }
    // The segmented control's trough at the control corner: a tab heads the panel under it and shares its corner.
    // One rim, tabs of one width side by side with no dividers, the chosen tab a thumb that slides.
    final rim = BorderSide(color: c.nightLine, width: t.rim(2.5));
    final outer = t.shapes.small;
    final inner = ComicTrack.cellShape(outer, rim);
    // On a phone, across the width it is given, tabs of one width; from 600 up each tab keeps to its words, as a tab
    // bar on a wide screen does (the design kit's checks holds a tab bar to what its tabs take). It scrolls sideways only
    // when they need more. Each tab says it is one, inside a bar that says it is a tab bar.
    final wide = t.width >= 600;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: !wide && box.hasBoundedWidth ? box.maxWidth : 0,
          ),
          child: Semantics(
            role: SemanticsRole.tabBar,
            label: widget.label ?? ComicLocalizations.of(context).tabs,
            container: true,
            explicitChildNodes: true,
            child: ComicTrack(
              shape: outer,
              rim: rim,
              fill: c.dark ? c.card : c.control,
              thumb: c.caption,
              equal: !wide,
              lit: widget.tabs.isEmpty
                  ? null
                  : widget.selectedIndex.clamp(0, widget.tabs.length - 1),
              cells: [
                for (var i = 0; i < widget.tabs.length; i++)
                  MergeSemantics(
                    child: Semantics(
                      role: SemanticsRole.tab,
                      child: ComicPressable(
                        label: widget.tabs[i],
                        button: false,
                        selected: i == widget.selectedIndex,
                        focusNode: _nodes[i],
                        wash: false,
                        ring: false,
                        sink: false,
                        keys: (_, event) => _keys(i, event),
                        onPressed: widget.onChanged == null
                            ? null
                            : () => widget.onChanged!(i),
                        builder: (context, states) => ComicTrackFace(
                          states: states,
                          shape: inner,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: CapLabel(
                            child: Text(
                              widget.tabs[i],
                              maxLines: 1,
                              style: t.type.title.copyWith(
                                color: i == widget.selectedIndex
                                    ? c.onCaption
                                    : c.dark
                                    ? c.text
                                    : c.onPaper,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page indicators with a full target around each small caption mark.
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
    if (onChanged == null) {
      return Semantics(
        label: label,
        value: '${count == 0 ? 0 : selectedIndex + 1} / $count',
        child: ExcludeSemantics(
          child: Wrap(children: [for (var i = 0; i < count; i++) dot(i)]),
        ),
      );
    }
    return Wrap(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: slot(i),
            child: ComicPressable(
              label: '$label ${i + 1} / $count',
              selected: i == selectedIndex,
              onPressed: () => onChanged!(i),
              target: true,
              // The wash and the ring are the mark's own outline; the target stands around it.
              outline: WidgetStatePropertyAll(t.shapes.full),
              child: mark(i),
            ),
          ),
      ],
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
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < count; i++)
                  Container(
                    padding: const EdgeInsets.all(10),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
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
              const SizedBox(height: 4),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(height: 16)],
                for (var i = 0; i < destinations.length; i++) destination(i),
                if (trailing != null) ...[
                  const SizedBox(height: 16),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
    return Semantics(
      label: label ?? ComicLocalizations.of(context).breadcrumbs,
      container: true,
      explicitChildNodes: true,
      // A step's side room stands outward from the first, so the trail's words start on the column's edge.
      child: ComicOutward(
        margin: const EdgeInsetsDirectional.only(start: 6),
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
                    constraints: const BoxConstraints(
                      minHeight: ComicTapTarget.target,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
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
                    constraints: const BoxConstraints(
                      minHeight: ComicTapTarget.target,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(
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
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
          ? DesignLocalizations.of(context).previousPageTooltip
          : DesignLocalizations.of(context).nextPageTooltip,
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
}
