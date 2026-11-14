import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../icon-button/round_button.dart';
import '../move/move.dart';
import '../pressable/pressable.dart';
import '../progress/progress.dart';

// ---------------------------------------------------------------------------
// Scroll area
// ---------------------------------------------------------------------------

/// A scrolling region with the look's own scrollbar (shadcn's ScrollArea,
/// Material's Scrollbar): a slim rounded bar in the quiet ink at the
/// [child]'s edge that shows while it scrolls or a pointer is near and
/// fades after, widening under the pointer to be dragged; a press on the
/// track pages. The area is a Tab stop of its own when [focusable], ringed
/// while the keyboard holds it, and the arrows, Page Up and Down, Home and
/// End scroll it. [child] is a scroll view on [controller]. ui_core's
/// [DesignScrollArea] is the behaviour.
///
/// ```dart
/// FrostedScrollArea(controller: scroll, child: ListView(controller: scroll, children: rows))
/// ```
class FrostedScrollArea extends StatelessWidget {
  /// [child]'s scrolling, with a scrollbar.
  const FrostedScrollArea({
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.alwaysShown = false,
    this.focusable = true,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The controller [child] scrolls on.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// Whether the bar stays shown (else it fades when idle).
  final bool alwaysShown;

  /// Whether the area takes the keyboard's focus.
  final bool focusable;

  /// What a screen reader calls the area.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    return DesignScrollArea(
      controller: controller,
      axis: axis,
      focusable: focusable,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: label,
      visibility: alwaysShown
          ? DesignScrollbarVisibility.always
          : DesignScrollbarVisibility.auto,
      frameBuilder: (context, focused, area) =>
          FrostedFocusRing(shown: focused, radius: 8, child: area),
      trackBuilder: (context, thumb) => AnimatedOpacity(
        opacity:
            thumb.states.contains(WidgetState.hovered) ||
                thumb.states.contains(WidgetState.pressed)
            ? 1
            : 0,
        duration: motion.fast,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(4),
            color: t.glass.wash,
          ),
        ),
      ),
      thumbBuilder: (context, thumb) {
        final held =
            thumb.states.contains(WidgetState.hovered) ||
            thumb.states.contains(WidgetState.pressed);
        final wide = held ? 8.0 : 5.0;
        final vertical = thumb.axis == Axis.vertical;
        return AnimatedOpacity(
          opacity: thumb.visible || held ? 1 : 0,
          duration: motion.base,
          child: Center(
            child: AnimatedContainer(
              duration: motion.fast,
              width: vertical ? wide : null,
              height: vertical ? null : wide,
              decoration: BoxDecoration(
                color: t.colorScheme.textTertiary.withValues(
                  alpha: thumb.states.contains(WidgetState.pressed)
                      ? .7
                      : held
                      ? .55
                      : .38,
                ),
                borderRadius: BorderRadius.circular(wide / 2),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Resizable
// ---------------------------------------------------------------------------

/// Two panes and the hairline between them, dragged to share the room
/// (shadcn's Resizable): the hairline lights in the accent with its grip
/// under the pointer or while dragged; the arrows move it from the
/// keyboard and Return folds the first pane away and back. [minFirst] and
/// [minSecond] keep each pane at least that wide (tall, with
/// [Axis.vertical]). ui_core's [DesignSplitView] is the behaviour.
///
/// ```dart
/// FrostedResizable(first: list, second: detail, initialFraction: .35, minFirst: 240)
/// ```
class FrostedResizable extends StatelessWidget {
  /// [first] and [second] side by side, the divider at [initialFraction].
  const FrostedResizable({
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = .5,
    this.onChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The node that holds the divider's keyboard focus; null keeps one of its
  /// own.
  final FocusNode? focusNode;

  /// Whether the divider takes keyboard focus when first shown.
  final bool autofocus;

  /// The pane before the divider.
  final Widget first;

  /// The pane after it.
  final Widget second;

  /// Side by side ([Axis.horizontal]) or one over the other.
  final Axis axis;

  /// The first pane's share, when the page owns it.
  final double? fraction;

  /// The first pane's share to start with.
  final double initialFraction;

  /// Called with the first pane's share as it moves.
  final ValueChanged<double>? onChanged;

  /// The first pane's least extent.
  final double minFirst;

  /// The second pane's least extent.
  final double minSecond;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      fraction: fraction,
      initialFraction: initialFraction,
      onChanged: onChanged,
      minFirst: minFirst,
      minSecond: minSecond,
      hitExtent: 16,
      focusNode: focusNode,
      autofocus: autofocus,
      // The handle's name: DesignLocalizations.splitViewHandleLabel.
      dividerBuilder: (context, states, axis) {
        final lit =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.focused);
        final across = axis == Axis.horizontal;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: lit ? t.colorScheme.accent : t.colorScheme.border,
              ),
            ),
            if (lit)
              OverflowBox(
                maxWidth: across ? 14 : 28,
                maxHeight: across ? 28 : 14,
                child: FrostedFace(
                  material: FrostedMaterial.paint,
                  radius: BorderRadius.circular(7),
                  color: t.glass.plane,
                  ring: t.colorScheme.accent,
                  child: Icon(
                    across ? FrostedGlyphs.grip : FrostedGlyphs.gripHorizontal,
                    size: 12,
                    color: t.colorScheme.accent,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Carousel
// ---------------------------------------------------------------------------

/// Slides that turn one at a time (Material's CarouselView, shadcn's
/// Carousel): each slide, and the frame whole slides turn in, clipped to
/// the card's corners (a slide keeps them mid-swipe), the glass round
/// steps back and on over its sides (none at an end unless it [loop]s),
/// the page dots under it, and a play and pause button when it turns by
/// itself every [autoplay] (stopping while the pointer or the keyboard is
/// on it, and under Reduce Motion). A swipe, the arrows from the keyboard
/// and a screen reader's own swipe all turn it. ui_core's [DesignCarousel]
/// is the behaviour.
///
/// ```dart
/// FrostedCarouselView(height: 200, children: [for (final p in photos) Image.asset(p)])
/// ```
class FrostedCarouselView extends StatelessWidget {
  /// A carousel of [children].
  const FrostedCarouselView({
    required List<Widget> this.children,
    this.height = 200,
    this.viewportFraction = 1,
    this.loop = false,
    this.autoplay,
    this.onPageChanged,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : itemCount = null,
       itemBuilder = null;

  /// A carousel of [itemCount] slides from [itemBuilder].
  const FrostedCarouselView.builder({
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.height = 200,
    this.viewportFraction = 1,
    this.loop = false,
    this.autoplay,
    this.onPageChanged,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : children = null;

  /// The slides, for the default constructor; null for [FrostedCarouselView.builder].
  final List<Widget>? children;

  /// How many slides.
  final int? itemCount;

  /// Builds slide [index].
  final IndexedWidgetBuilder? itemBuilder;

  /// The slides' height.
  final double height;

  /// How much of the width a slide takes (under 1, the next peeks in).
  final double viewportFraction;

  /// Whether it turns past the last slide back to the first.
  final bool loop;

  /// How often it turns by itself; null never.
  final Duration? autoplay;

  /// Called with the slide turned to.
  final ValueChanged<int>? onPageChanged;

  /// What a screen reader calls it; null says
  /// `DesignLocalizations.carouselLabel` ("Carousel" in English).
  final String? label;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final words = FrostedLocalizations.of(context);
    final shared = DesignLocalizations.of(context);
    final slides = children;
    final count = slides?.length ?? itemCount!;
    final slide = slides == null
        ? itemBuilder!
        : (BuildContext _, int i) => slides[i];
    return DesignCarousel(
      itemCount: count,
      viewportFraction: viewportFraction,
      loop: loop,
      autoplayInterval: autoplay,
      onPageChanged: onPageChanged,
      focusNode: focusNode,
      autofocus: autofocus,
      // Null names: DesignLocalizations' carouselLabel and
      // carouselSlideLabel ("Slide 2 of 5").
      semanticLabel: label,
      duration: FrostedMotion.of(context).base,
      // A peeking slide keeps its own corners. A whole slide is held by the
      // frame alone: with its own corners too, the sliver of a slide coming
      // in was cut at both ends into an almond (self-review round 2).
      itemBuilder: (context, i) => viewportFraction < 1
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FrostedCorners.r18),
                child: slide(context, i),
              ),
            )
          : slide(context, i),
      layoutBuilder: (context, viewport, controls) {
        Widget step(IconData glyph, String name, VoidCallback? go) =>
            FrostedIconButton(
              glyph,
              label: name,
              size: FrostedIconButtonSize.small,
              onPressed: go,
            );
        // A whole slide's frame holds the card's shape: a slide on its way
        // out or in is cut by the frame's round corners, never squared by
        // the viewport's edge. With a peek (a fraction under 1) each slide
        // keeps its own corners and the frame cuts straight: its round
        // corners squeezed a peeking slide into a capsule that grew and
        // shrank as it moved (self-review round 1).
        Widget slides = SizedBox(height: height, child: viewport);
        if (viewportFraction >= 1) {
          slides = ClipRRect(
            borderRadius: BorderRadius.circular(FrostedCorners.r18),
            child: slides,
          );
        }
        slides = FrostedFocusRing(
          shown: controls.focused,
          radius: FrostedCorners.r18,
          child: slides,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                slides,
                if (controls.previous case final back?)
                  PositionedDirectional(
                    start: 8,
                    child: step(
                      FrostedGlyphs.chevronLeft,
                      words.previous,
                      back,
                    ),
                  ),
                if (controls.next case final on?)
                  PositionedDirectional(
                    end: 8,
                    child: step(FrostedGlyphs.forward, words.next, on),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                FrostedPageDots(
                  count: controls.count,
                  selectedIndex: controls.page,
                  position: controls.position,
                  // The dots say where the slides stand ("Slide 1 of 5"; its
                  // index counts from 0), the carousel its [label].
                  label: shared.carouselSlideLabel(
                    controls.page,
                    controls.count,
                  ),
                  onChanged: controls.goToPage,
                ),
                if (controls.togglePlay case final toggle?)
                  step(
                    controls.playing ? FrostedGlyphs.pause : FrostedGlyphs.play,
                    controls.playing ? words.pause : words.play,
                    toggle,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Reorderable list
// ---------------------------------------------------------------------------

/// Rows put in order by dragging (Material's ReorderableListView): each row
/// on the glass with its grip at the end; while it moves it rises as the
/// thicker slab glass in the menu's lift (nearer is thicker); a long press anywhere on a row drags it too. From the
/// keyboard Alt with Up or Down moves the focused row, and a screen reader
/// has Move up and Move down; each move is announced with the row's new
/// place. ui_core's [DesignReorderableList] is the behaviour.
///
/// ```dart
/// FrostedReorderableListView<String>(items: tasks, labelOf: (t) => t, onReorder: (from, to) => setState(() => tasks.insert(to, tasks.removeAt(from))), itemBuilder: (context, t) => Text(t))
/// ```
class FrostedReorderableListView<T extends Object> extends StatelessWidget {
  /// A list of [items] in order.
  const FrostedReorderableListView({
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.labelOf,
    this.keyOf,
    this.shrinkWrap = false,
    this.controller,
    this.padding,
    super.key,
  });

  /// The rows' items, in order.
  final List<T> items;

  /// Called to move the item at `from` to `to` (already adjusted for the
  /// removal).
  final void Function(int from, int to) onReorder;

  /// Builds a row's content (the grip and the glass are the list's).
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// An item's name, as a screen reader says it moved.
  final String Function(T item) labelOf;

  /// An item's identity, when it is not the item itself.
  final Object Function(T item)? keyOf;

  /// Whether the list takes only the height of its rows.
  final bool shrinkWrap;

  /// The list's scroll controller.
  final ScrollController? controller;

  /// The room round the rows.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    return DesignReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      keyOf: keyOf,
      shrinkWrap: shrinkWrap,
      controller: controller,
      padding: padding,
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => _Lifted(
          child: Transform.scale(
            scale: 1 + .02 * animation.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FrostedCorners.r12),
                boxShadow: t.shadows.menu,
              ),
              child: child,
            ),
          ),
        ),
      ),
      itemBuilder: (context, item, reorder) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _LiftedFace(
          material: (lifted) =>
              lifted ? FrostedMaterial.slab : FrostedMaterial.pane,
          radius: BorderRadius.circular(FrostedCorners.r12),
          ring: t.glass.edge,
          padding: const EdgeInsetsDirectional.only(start: 14)
              .resolve(Directionality.of(context)),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: t.textTheme.titleMedium.c(t.colorScheme.textPrimary),
                    child: itemBuilder(context, item),
                  ),
                ),
                reorder.handle(
                  Semantics(
                    label: words.reorder,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        FrostedGlyphs.grip,
                        size: 18,
                        color: t.colorScheme.textTertiary,
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

/// Marks the row being dragged (the reorder list's proxy).
class _Lifted extends InheritedWidget {
  const _Lifted({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Lifted>() != null;

  @override
  bool updateShouldNotify(_Lifted oldWidget) => false;
}

/// A row's face whose glass is chosen by whether the row is lifted.
class _LiftedFace extends StatelessWidget {
  const _LiftedFace({
    required this.material,
    required this.radius,
    required this.ring,
    required this.padding,
    required this.child,
  });

  final FrostedMaterial Function(bool lifted) material;
  final BorderRadius radius;
  final Color ring;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => FrostedFace(
    material: material(_Lifted.of(context)),
    radius: radius,
    ring: ring,
    padding: padding,
    child: child,
  );
}

// ---------------------------------------------------------------------------
// Pull to refresh
// ---------------------------------------------------------------------------

/// A list refreshed by pulling it down past its top (Material's
/// RefreshIndicator): a glass disc follows the pull, its ring filling
/// as the pull nears the mark, turning while [onRefresh] runs; a screen
/// reader has a Refresh action and hears "Refreshing" and then that it is
/// done. ui_core's [DesignPullToRefresh] is the behaviour.
///
/// ```dart
/// FrostedRefreshIndicator(onRefresh: reload, child: ListView(children: rows))
/// ```
class FrostedRefreshIndicator extends StatelessWidget {
  /// [child], refreshed by [onRefresh] when pulled.
  const FrostedRefreshIndicator({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// Refreshes; the disc turns until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // Its words (Refresh, Refreshing): DesignLocalizations'.
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      indicatorBuilder: (context, state) {
        if (state.mode == DesignRefreshMode.inactive) return const SizedBox();
        final turning = state.mode == DesignRefreshMode.refresh;
        return Center(
          child: Opacity(
            opacity: state.progress.clamp(0.0, 1.0),
            child: SizedBox.square(
              dimension: 40,
              child: FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(20),
                color: t.glass.plane,
                ring: t.glass.edge,
                shadows: t.shadows.raised,
                child: Center(
                  child: ExcludeSemantics(
                    child: FrostedCircularProgressIndicator(
                      value: turning || state.mode == DesignRefreshMode.done
                          ? (turning ? null : 1)
                          : state.progress.clamp(0.0, 1.0),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
