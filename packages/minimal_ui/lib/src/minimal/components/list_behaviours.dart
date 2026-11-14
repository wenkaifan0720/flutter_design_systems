/// Lists that do more than show: put in order by a drag, refreshed by a
/// pull, and opened level by level as a tree, painted on ui_core's
/// reorderable list, pull to refresh and tree.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'feedback.dart';
import 'tag.dart';

/// A list the reader puts in order: a playlist, priorities, a checklist's
/// steps. Each row is a 44 px line on a hairline with a grip at its start;
/// a press on the grip drags at once, a long press anywhere drags on touch,
/// and the row under the finger lifts onto the surface with the menu's
/// shadow, its outline `shapes.small`.
///
/// Alt with Up or Down moves the row the keyboard is in (focus stays with
/// it); a screen reader gets Move up, Move down, Move to start and Move to
/// end on each row and hears each move. [itemBuilder] paints a row's
/// content after the grip. The behaviour is ui_core's
/// ([DesignReorderableList]); Minimal paints it.
///
/// ```dart
/// MinimalReorderableListView<String>(items: steps, labelOf: (s) => s, onReorder: move, itemBuilder: (context, s) => Text(s))
/// ```
class MinimalReorderableListView<T extends Object> extends StatelessWidget {
  /// A reorderable list of [items].
  const MinimalReorderableListView({
    super.key,
    required this.items,
    required this.onReorder,
    required this.labelOf,
    required this.itemBuilder,
    this.keyOf,
    this.shrinkWrap = true,
    this.controller,
  });

  /// The items, in order.
  final List<T> items;

  /// Moves the item at `from` to `to` (counted after it left).
  final void Function(int from, int to) onReorder;

  /// What a screen reader calls an item.
  final String Function(T item) labelOf;

  /// Paints a row's content, after the grip.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Tells items apart across moves; the item itself unstated.
  final Object Function(T item)? keyOf;

  /// Whether the list is only as tall as its rows (in a page that scrolls).
  final bool shrinkWrap;

  /// Its scroll position, when it scrolls itself.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    return DesignReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      keyOf: keyOf,
      shrinkWrap: shrinkWrap,
      controller: controller,
      movedMessage: words.movedTo,
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => DecoratedBox(
          decoration: minimalFrame(
            t.shapes.small,
            fill: t.card,
            side: BorderSide(color: t.border, width: t.rim),
            shadows: animation.value > 0 ? t.shadowMd : null,
          ),
          child: child,
        ),
      ),
      itemBuilder: (context, item, r) => Container(
        constraints: const BoxConstraints(minHeight: 44),
        // No ground of its own: the row stands on what holds it, so a
        // card's rounded rim shows whole at its corners. Clear, it still
        // takes a long press anywhere on it.
        color: const Color(0x00000000),
        // Painted over the row's foot: the row's words are centred on the
        // whole row, the rule's pixel with it.
        foregroundDecoration: r.index < r.count - 1
            ? BoxDecoration(border: Border(bottom: t.rule))
            : null,
        child: Row(
          children: [
            r.handle(
              Semantics(
                label: words.reorder,
                child: SizedBox(
                  width: 40,
                  height: 44,
                  child: MinimalIcon(
                    LucideIcons.gripVertical,
                    size: MinimalIconSize.i16,
                    color: t.textTertiary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: DefaultTextStyle(
                style: t.body.c(t.foreground),
                child: itemBuilder(context, item),
              ),
            ),
            const MinimalGap(MinimalSpacing.s12),
          ],
        ),
      ),
    );
  }
}

/// A list refreshed by a pull past its top: an inbox, a feed. While the
/// pull is short a small arrow fades in, bare in the band the pull opens
/// above the list, and turns up once the pull is far enough to refresh;
/// letting go there shows Minimal's spinner in the same place until
/// [onRefresh] completes, then a check as the band closes. Nothing floats:
/// no disc, no shadow, the mark only ever stands in the list's own air.
///
/// [child] is the scroll view. A screen reader gets a Refresh action on the
/// list and hears when it starts and ends. The behaviour is ui_core's
/// ([DesignPullToRefresh]); Minimal paints it.
///
/// ```dart
/// MinimalRefreshIndicator(onRefresh: reload, child: ListView(children: rows))
/// ```
class MinimalRefreshIndicator extends StatelessWidget {
  /// A refresher around [child].
  const MinimalRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Refreshes; the spinner stays until it completes.
  final Future<void> Function() onRefresh;

  /// The scroll view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      refreshLabel: words.refresh,
      refreshingMessage: words.refreshing,
      doneMessage: words.refreshed,
      child: child,
      indicatorBuilder: (context, state) {
        final Widget mark = switch (state.mode) {
          DesignRefreshMode.inactive => const SizedBox.shrink(),
          DesignRefreshMode.drag || DesignRefreshMode.armed => Opacity(
            opacity: state.progress.clamp(0.0, 1.0),
            child: AnimatedRotation(
              turns: state.mode == DesignRefreshMode.armed ? 0.5 : 0,
              duration: context.minimalStill
                  ? Duration.zero
                  : MinimalMotion.base,
              child: MinimalIcon(
                LucideIcons.arrowDown,
                size: MinimalIconSize.i16,
                color: t.mutedForeground,
              ),
            ),
          ),
          DesignRefreshMode.refresh => const MinimalCircularProgressIndicator(
            size: 18,
            tone: MinimalTone.neutral,
          ),
          DesignRefreshMode.done => MinimalIcon(
            LucideIcons.check,
            size: MinimalIconSize.i16,
            color: t.mutedForeground,
          ),
        };
        if (state.mode == DesignRefreshMode.inactive) {
          return const SizedBox.shrink();
        }
        // The bare mark, centred in a 32 px square of the opened band.
        return Center(
          child: SizedBox.square(dimension: 32, child: Center(child: mark)),
        );
      },
    );
  }
}

/// Nested things opened level by level: folders and files, a project's
/// areas, a document's outline. Each row is 32 px: indented 16 px a level,
/// a chevron that turns as its node opens, a 16 px glyph ([iconOf]) and
/// the words. The selected row is said in type alone, as the sidebar's
/// current page is: its glyph and words in the full ink, the words at
/// medium weight, the rest in the muted ink; nothing behind it. Until a
/// row is selected every row stands in the ink, as a list's rows do.
///
/// One tab stop: Up and Down move, Right opens a node or steps into it,
/// Left closes it or steps out (mirrored right to left), Home and End go to
/// the ends, Enter activates ([onActivate]), Space selects, `*` opens every
/// sibling; a screen reader hears each row's level and whether it is open.
/// The behaviour is ui_core's ([DesignTree]); Minimal paints it.
///
/// ```dart
/// MinimalTreeView<String>(roots: const ['lib', 'test'], childrenOf: (path) => folders[path] ?? const <String>[], labelOf: (path) => path, onActivate: open)
/// ```
class MinimalTreeView<T extends Object> extends StatefulWidget {
  /// A tree from [roots].
  const MinimalTreeView({
    super.key,
    required this.roots,
    required this.childrenOf,
    required this.labelOf,
    this.iconOf,
    this.initiallyExpanded = const [],
    this.onSelected,
    this.onActivate,
    this.label,
  });

  /// The top nodes.
  final List<T> roots;

  /// A node's children (empty: a leaf).
  final List<T> Function(T node) childrenOf;

  /// A node's words.
  final String Function(T node) labelOf;

  /// A node's glyph, given whether it is open; null draws none.
  final IconData? Function(T node, bool expanded)? iconOf;

  /// The nodes open at first.
  final List<T> initiallyExpanded;

  /// Called with the node selected (a press, or Space).
  final ValueChanged<T>? onSelected;

  /// A node's Enter, or a press on a leaf.
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls the tree.
  final String? label;

  @override
  State<MinimalTreeView<T>> createState() => _MinimalTreeViewState<T>();
}

class _MinimalTreeViewState<T extends Object>
    extends State<MinimalTreeView<T>> {
  late final DesignTreeController<T> _tree = DesignTreeController<T>(
    roots: widget.roots,
    childrenOf: widget.childrenOf,
    expanded: widget.initiallyExpanded,
  )..addListener(_changed);
  Set<T> _chosen = const {};

  void _changed() {
    final now = _tree.selected;
    if (now.length == 1 && !_chosen.contains(now.single)) {
      widget.onSelected?.call(now.single);
    }
    _chosen = now;
  }

  @override
  void didUpdateWidget(MinimalTreeView<T> old) {
    super.didUpdateWidget(old);
    if (!identical(old.roots, widget.roots)) _tree.roots = widget.roots;
  }

  @override
  void dispose() {
    _tree.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DesignTree<T>(
      controller: _tree,
      labelOf: widget.labelOf,
      onActivate: widget.onActivate,
      semanticLabel: widget.label,
      levelHint: words.treeLevel,
      rowBuilder: (context, item) {
        final node = item.row.node;
        final shape = t.shapes.small;
        final glyph = widget.iconOf?.call(node, item.expanded);
        // With nothing selected no row is "the rest": all stand in the ink.
        final ink = item.selected || _tree.selected.isEmpty
            ? t.foreground
            : t.mutedForeground;
        return Container(
          height: 32,
          padding: EdgeInsetsDirectional.only(
            start: MinimalSpacing.s4 + 16.0 * item.row.depth,
            end: MinimalSpacing.s8,
          ),
          foregroundDecoration: minimalStateLayer(
            t,
            shape,
            item.states,
            inside: true,
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: item.hasChildren
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        excludeFromSemantics: true,
                        onTap: item.toggle,
                        child: AnimatedRotation(
                          turns: item.expanded ? (rtl ? -0.25 : 0.25) : 0,
                          duration: context.minimalStill
                              ? Duration.zero
                              : MinimalMotion.base,
                          child: MinimalIcon(
                            rtl
                                ? LucideIcons.chevronLeft
                                : LucideIcons.chevronRight,
                            size: MinimalIconSize.i14,
                            color: t.textTertiary,
                          ),
                        ),
                      )
                    : null,
              ),
              const MinimalGap(MinimalSpacing.s4),
              if (glyph != null) ...[
                MinimalIcon(glyph, size: MinimalIconSize.i16, color: ink),
                const MinimalGap(MinimalSpacing.s8),
              ],
              Expanded(
                child: Text(
                  widget.labelOf(node),
                  style: (item.selected ? t.bodySmall.medium : t.bodySmall).c(
                    ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
